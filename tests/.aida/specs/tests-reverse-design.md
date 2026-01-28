# Reverse-Engineered Design: tests

Generated at: 2026-01-24T09:45:29Z
Language: unknown

## Overview

This document describes the existing codebase structure, patterns, and conventions.
**Any enhancement MUST follow these existing patterns.**

---

## Directory Structure

[0;34mDetecting directory structure...[0m

---

## API Endpoints

Total: 0
0 endpoints

```

```



---

## Data Models

Total: 0
0 models

```

```



---

## Coding Patterns

[0;34mDetecting coding patterns...[0m

---

## Pattern Guidelines for Enhancement

When adding new code, follow these conventions:

### Naming Conventions
- **Files**: snake_case or camelCase
- **Functions**: Check existing functions for naming style
- **Variables**: Check existing code for naming style

### Error Handling
- Follow existing error handling patterns
- Use same error types/classes

### Testing
- Follow existing test file naming (*_test.go, *.test.ts, etc.)
- Follow existing test structure (describe/it, t.Run, etc.)
- Maintain or exceed current test coverage

### Code Organization
- Place new handlers in existing handler directories
- Place new models in existing model directories
- Place new services in existing service directories

---

## Critical Files

These files are central to the project architecture:




---

## Enhancement Checklist

Before implementing any enhancement:

- [ ] Read 2-3 existing handler files to understand patterns
- [ ] Read 2-3 existing test files to understand test structure
- [ ] Identify where new code will integrate (router, services, etc.)
- [ ] Plan minimal changes to existing files
- [ ] All new code follows existing naming conventions
- [ ] All new code has tests following existing patterns
