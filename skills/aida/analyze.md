---
name: aida:analyze
description: |
  Analyze any project's structure, tech stack, and quality state.
  Supports Go, Rust, Python, Node.js, Java, Ruby, and more.
  Auto-detects project type, testing frameworks, and infrastructure.
tools: Read, Bash, Glob, Grep, Task
---

# AIDA Analyze

Analyze any existing project to collect AIDA management information.

## Usage

```
/aida:analyze /path/to/project
```

---

## MANDATORY EXECUTION PROTOCOL

### Step 1: Validate Project Path

```bash
# Verify the path exists and is a directory
if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "Error: Project path does not exist: $PROJECT_PATH"
  exit 1
fi
```

### Step 2: Create Output Directories

```bash
mkdir -p .aida/analysis .aida/state
```

### Step 3: Run Analysis Script

```bash
./scripts/analyze-project.sh "$PROJECT_PATH"
```

### Step 4: Report Results

After analysis completes:
1. Read `.aida/analysis/<PROJECT>-analysis.json`
2. Display summary to user
3. Show recommendations

---

## Auto-Detection Items

### 1. Language & Framework Detection

| Target | Detection Method |
|--------|-----------------|
| Go | go.mod, *.go files |
| Rust | Cargo.toml |
| Python | pyproject.toml, requirements.txt, setup.py |
| Node.js | package.json |
| TypeScript | tsconfig.json, *.ts files |
| Java | pom.xml, build.gradle |
| Ruby | Gemfile |
| C# | *.csproj, *.sln |
| PHP | composer.json |

### 2. Project Structure Patterns

| Pattern | Detection Condition |
|---------|-------------------|
| Monolith | Single root with main entry |
| Monorepo | packages/, apps/, libs/, workspaces in package.json |
| Microservices | Multiple service directories with separate configs |
| Fullstack | backend/ + frontend/ directories |
| Library | lib/, src/ with setup.py/package.json/Cargo.toml |

### 3. Test & Quality Tools

| Tool | Detection |
|------|-----------|
| Jest/Vitest | jest.config.*, vitest.config.* |
| Go test | *_test.go |
| Pytest | pytest.ini, conftest.py, pyproject.toml [pytest] |
| RSpec | spec/, .rspec |
| JUnit | src/test/java/ |
| ESLint | .eslintrc*, eslint.config.* |
| Prettier | .prettierrc*, prettier.config.* |
| Biome | biome.json |

### 4. Infrastructure Detection

| Target | Detection Files |
|--------|-----------------|
| Docker | Dockerfile, docker-compose.yml, compose.yaml |
| Kubernetes | k8s/, kubernetes/, *.yaml with apiVersion |
| Terraform | *.tf, terraform/ |
| GitHub Actions | .github/workflows/*.yml |
| GitLab CI | .gitlab-ci.yml |
| CircleCI | .circleci/config.yml |

---

## Output Format

`.aida/analysis/<PROJECT>-analysis.json`:

```json
{
  "analyzed_at": "ISO8601",
  "project_path": "/absolute/path/to/project",
  "project_name": "derived-name",
  "detected_type": "fullstack|backend|frontend|library|monorepo|microservices",
  "components": [
    {
      "name": "backend",
      "path": "backend/",
      "lang": "go",
      "lang_version": "1.23",
      "framework": "gin",
      "test_framework": "go test",
      "test_files": 15,
      "test_count": 87,
      "coverage": "75.2%",
      "build_command": "go build ./...",
      "test_command": "go test ./...",
      "lint_command": "golangci-lint run"
    },
    {
      "name": "frontend",
      "path": "frontend/",
      "lang": "typescript",
      "lang_version": "5.3",
      "framework": "react",
      "test_framework": "vitest",
      "test_files": 24,
      "test_count": 136,
      "coverage": "68.5%",
      "build_command": "pnpm build",
      "test_command": "pnpm test",
      "lint_command": "pnpm lint"
    }
  ],
  "infrastructure": {
    "docker": true,
    "docker_compose": true,
    "kubernetes": false,
    "ci_cd": "GitHub Actions",
    "ci_cd_files": [".github/workflows/ci.yml"]
  },
  "dependencies": {
    "package_managers": ["go mod", "pnpm"],
    "external_services": ["PostgreSQL", "Redis"],
    "detected_from": ["docker-compose.yml", "go.mod"]
  },
  "quality_baseline": {
    "total_tests": 223,
    "total_coverage": "71.8%",
    "lint_passing": true,
    "build_passing": true
  },
  "recommendations": [
    "Add E2E tests (currently 0)",
    "Increase frontend coverage to 70%+",
    "Add security scanning to CI"
  ],
  "aida_compatibility": {
    "supported": true,
    "notes": ["All languages supported", "Docker available"]
  }
}
```

---

## Analysis Report Format

After analysis, display:

```
AIDA Project Analysis Complete

Project: my-project
Path: /home/user/projects/my-project
Type: fullstack

Components:
  Backend (Go/Gin):
    - Tests: 87 (15 files)
    - Coverage: 75.2%
    - Build: PASS

  Frontend (TypeScript/React):
    - Tests: 136 (24 files)
    - Coverage: 68.5%
    - Build: PASS

Infrastructure:
  - Docker: Yes (docker-compose.yml)
  - CI/CD: GitHub Actions

Quality Baseline:
  - Total Tests: 223
  - Average Coverage: 71.8%
  - Lint: PASS

Recommendations:
  1. Add E2E tests (currently 0)
  2. Increase frontend coverage to 70%+

AIDA Compatibility: SUPPORTED
Use `/aida:enhance` to extend this project
Use `/aida:maintain` for maintenance tasks
```

---

## Error Handling

### Unknown Language
```json
{
  "components": [{
    "name": "unknown",
    "lang": "unknown",
    "message": "Could not detect language. Please specify manually."
  }],
  "aida_compatibility": {
    "supported": false,
    "notes": ["Manual configuration required"]
  }
}
```

### Empty Project
```json
{
  "error": "No source files detected",
  "recommendations": ["Verify project path", "Initialize project first"]
}
```

---

## Related Commands

| Command | Description |
|---------|-------------|
| `/aida:import` | Import and analyze external project |
| `/aida:enhance` | Extend project based on specs |
| `/aida:maintain` | Maintenance mode |
