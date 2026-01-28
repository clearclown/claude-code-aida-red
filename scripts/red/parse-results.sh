#!/bin/bash
# AIDA-RED: Parse security scan results into unified findings format
# Usage: ./parse-results.sh --tool <tool> --input <file> [--severity-min <level>]
#
# Outputs JSON findings array on stdout.

set -euo pipefail

TOOL=""
INPUT_FILE=""
SEVERITY_MIN="info"  # info, low, medium, high, critical

while [[ $# -gt 0 ]]; do
    case $1 in
        --tool) TOOL="$2"; shift 2 ;;
        --input) INPUT_FILE="$2"; shift 2 ;;
        --severity-min) SEVERITY_MIN="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [[ -z "$TOOL" || -z "$INPUT_FILE" ]]; then
    echo '{"error":"--tool and --input are required"}'
    exit 1
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo '{"error":"Input file not found","file":"'"$INPUT_FILE"'"}'
    exit 1
fi

# Severity ordering for filtering
severity_level() {
    case "$1" in
        info)     echo 0 ;;
        low)      echo 1 ;;
        medium)   echo 2 ;;
        high)     echo 3 ;;
        critical) echo 4 ;;
        *)        echo 0 ;;
    esac
}

MIN_LEVEL=$(severity_level "$SEVERITY_MIN")

# Parse based on tool
case "$TOOL" in
    nuclei)
        # Nuclei JSONL format: one JSON object per line
        jq -s --argjson min "$MIN_LEVEL" '
            [.[] | {
                id: (.info.name // .templateID // "unknown"),
                tool: "nuclei",
                severity: (.info.severity // "info"),
                type: (.info.tags[0] // .type // "unknown"),
                matched_at: (.matched // .host // ""),
                description: (.info.description // .info.name // ""),
                reference: (.info.reference // []),
                cwe: (.info.classification.cwe_id // []),
                cvss: (.info.classification.cvss_score // null),
                curl_command: (.curl_command // null),
                template: (.template // ""),
                timestamp: (.timestamp // now | todate)
            }]
            | map(select(
                (if .severity == "critical" then 4
                 elif .severity == "high" then 3
                 elif .severity == "medium" then 2
                 elif .severity == "low" then 1
                 else 0 end) >= $min
            ))
        ' "$INPUT_FILE" 2>/dev/null || echo '[]'
        ;;

    nikto)
        # Nikto JSON format
        jq '
            [.vulnerabilities // [] | .[] | {
                id: ("NIKTO-" + (.id | tostring)),
                tool: "nikto",
                severity: (if .OSVDB != "0" then "medium" else "low" end),
                type: "web-server",
                matched_at: (.url // .msg // ""),
                description: (.msg // ""),
                reference: [("https://osvdb.org/" + (.OSVDB // "0"))],
                osvdb: (.OSVDB // "0"),
                method: (.method // "GET"),
                timestamp: (now | todate)
            }]
        ' "$INPUT_FILE" 2>/dev/null || echo '[]'
        ;;

    nmap)
        # Nmap XML → simplified JSON (basic extraction)
        python3 -c "
import xml.etree.ElementTree as ET
import json, sys

try:
    tree = ET.parse('$INPUT_FILE')
    root = tree.getroot()
    findings = []
    for host in root.findall('host'):
        addr = host.find('address')
        ip = addr.get('addr', '') if addr is not None else ''
        for port in host.findall('.//port'):
            portid = port.get('portid', '')
            protocol = port.get('protocol', '')
            state_el = port.find('state')
            state = state_el.get('state', '') if state_el is not None else ''
            service_el = port.find('service')
            service = service_el.get('name', '') if service_el is not None else ''
            product = service_el.get('product', '') if service_el is not None else ''
            version = service_el.get('version', '') if service_el is not None else ''
            for script in port.findall('script'):
                findings.append({
                    'id': f'NMAP-{portid}-{script.get(\"id\", \"\")}',
                    'tool': 'nmap',
                    'severity': 'medium',
                    'type': 'network',
                    'matched_at': f'{ip}:{portid}',
                    'description': script.get('output', ''),
                    'port': int(portid),
                    'protocol': protocol,
                    'service': service,
                    'product': f'{product} {version}'.strip()
                })
            if state == 'open':
                findings.append({
                    'id': f'NMAP-{portid}-open',
                    'tool': 'nmap',
                    'severity': 'info',
                    'type': 'port-discovery',
                    'matched_at': f'{ip}:{portid}',
                    'description': f'Open port {portid}/{protocol}: {service} {product} {version}'.strip(),
                    'port': int(portid),
                    'service': service
                })
    print(json.dumps(findings, indent=2))
except Exception as e:
    print(json.dumps([]), file=sys.stdout)
    print(f'Parse error: {e}', file=sys.stderr)
" 2>/dev/null || echo '[]'
        ;;

    ffuf)
        # ffuf JSON format
        jq '
            [.results // [] | .[] | {
                id: ("FFUF-" + (.status | tostring) + "-" + .input.FUZZ),
                tool: "ffuf",
                severity: (
                    if .status == 200 then "low"
                    elif .status == 301 or .status == 302 then "info"
                    elif .status == 403 then "low"
                    else "info" end
                ),
                type: "directory-discovery",
                matched_at: .url,
                description: ("Found: " + .url + " (HTTP " + (.status | tostring) + ", " + (.length | tostring) + " bytes)"),
                http_status: .status,
                content_length: .length,
                word_count: .words,
                line_count: .lines
            }]
        ' "$INPUT_FILE" 2>/dev/null || echo '[]'
        ;;

    sslscan)
        # sslscan JSON format
        jq '
            . as $root |
            [
                (if .tlsv1_0 == true then [{
                    id: "SSL-TLS10",
                    tool: "sslscan",
                    severity: "high",
                    type: "ssl-tls",
                    description: "TLS 1.0 is enabled (deprecated, vulnerable)"
                }] else [] end),
                (if .sslv3 == true then [{
                    id: "SSL-SSLV3",
                    tool: "sslscan",
                    severity: "critical",
                    type: "ssl-tls",
                    description: "SSLv3 is enabled (vulnerable to POODLE)"
                }] else [] end)
            ] | flatten
        ' "$INPUT_FILE" 2>/dev/null || echo '[]'
        ;;

    *)
        echo '[]'
        ;;
esac
