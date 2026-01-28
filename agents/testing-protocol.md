# AIDA Testing Protocol v3.0 - ZERO COMPROMISE

**"100% COVERAGE. NO MOCKS. NO BUGS. NO EXCUSES."**

This document defines the MANDATORY testing requirements for all AIDA-generated projects.
AI has unlimited patience. There is NO excuse for incomplete testing.
Violation of these requirements = **IMMEDIATE FAILURE**.

---

## PHILOSOPHY: TDD IS NON-NEGOTIABLE

```
TDD is not optional.
TDD is not "nice to have".
TDD is the ONLY way to write code in AIDA.

Every. Single. Line. Of. Code. Starts. With. A. Failing. Test.
```

### The Sacred TDD Cycle

```
┌─────────────────────────────────────────────────────────────┐
│  1. RED    → Write a failing test FIRST                     │
│             → Run test → MUST FAIL                          │
│             → Screenshot/log the failure as PROOF           │
│                                                             │
│  2. GREEN  → Write MINIMAL code to pass                     │
│             → No extra features. No "improvements".         │
│             → Run test → MUST PASS                          │
│             → Screenshot/log the success as PROOF           │
│                                                             │
│  3. REFACTOR → Clean up code                                │
│              → Run test → MUST STILL PASS                   │
│              → If test fails, you broke something. Fix it.  │
└─────────────────────────────────────────────────────────────┘
```

**IF YOU WRITE CODE BEFORE A FAILING TEST, YOU HAVE FAILED.**

### TDD Evidence Recording (MANDATORY for Gate 20)

Record every TDD cycle using `tdd-logger.sh`:

```bash
# 1. Start the cycle
./scripts/tdd-logger.sh start user-auth

# 2. RED - Record failing test
./scripts/tdd-logger.sh red auth_test.go

# 3. GREEN - Record passing test
./scripts/tdd-logger.sh green auth_test.go

# 4. REFACTOR - Record improvements
./scripts/tdd-logger.sh refactor "Extracted helper"

# 5. Complete the cycle
./scripts/tdd-logger.sh complete
```

Evidence saved to `.aida/tdd-evidence/`. **Gate 20 requires 10+ evidence files.**

---

## MANDATORY TEST COUNTS (MINIMUM REQUIREMENTS)

### Backend (Go) - MINIMUM 80 TESTS

| Component | Min Files | Min Tests | Test Types Required |
|-----------|-----------|-----------|---------------------|
| Handler | 8 | 30 | Unit, Integration, Edge cases |
| Service | 5 | 20 | Unit, Mock, Business logic |
| Repository | 4 | 15 | Unit, Database, Empty results |
| Middleware | 3 | 10 | Auth, CORS, Error handling |
| Model | 2 | 5 | Validation, Serialization |
| **TOTAL** | **22+** | **80+** | |

### Frontend (React) - MINIMUM 100 TESTS

| Component | Min Files | Min Tests | Test Types Required |
|-----------|-----------|-----------|---------------------|
| Pages | 8 | 35 | Render, Interaction, Navigation |
| Components | 10 | 40 | Render, Props, Events, States |
| Context/Hooks | 3 | 15 | State changes, Side effects |
| API Client | 2 | 10 | Success, Error, Edge cases |
| **TOTAL** | **23+** | **100+** | |

### E2E (Playwright) - MINIMUM 20 TESTS

| Category | Min Tests | Scenarios |
|----------|-----------|-----------|
| Auth flows | 6 | Register, Login, Logout, Invalid, Session |
| CRUD operations | 8 | Create, Read, Update, Delete, Validation |
| Navigation | 4 | Routes, Protected, Redirect, 404 |
| Error handling | 2 | Network, Server errors |
| **TOTAL** | **20+** | |

---

## COVERAGE REQUIREMENTS (ZERO COMPROMISE)

| Type | Required Coverage | Acceptable |
|------|-------------------|------------|
| Backend Line Coverage | **100%** | Nothing less |
| Backend Function Coverage | **100%** | Nothing less |
| Backend Branch Coverage | **100%** | Nothing less |
| Frontend Line Coverage | **100%** | Nothing less |
| Frontend Function Coverage | **100%** | Nothing less |
| Frontend Branch Coverage | **100%** | Nothing less |
| E2E Path Coverage | **100%** | Nothing less |

**AI HAS UNLIMITED TIME. THERE IS NO EXCUSE FOR < 100% COVERAGE.**

### Why 100%?

- AI doesn't get tired
- AI doesn't have deadlines
- AI can generate tests faster than humans
- Every uncovered line is a potential bug
- Every uncovered branch is a security risk
- "Good enough" is not good enough for AI

**IF COVERAGE IS BELOW 100%, IMPLEMENTATION IS INCOMPLETE.**

---

## NO MOCKS POLICY (ZERO COMPROMISE)

**MOCKS ARE LIES. LIES HIDE BUGS. BUGS HURT USERS.**

### Forbidden Practices

| Practice | Why It's Forbidden | Alternative |
|----------|-------------------|-------------|
| Mock databases | Hides query bugs, schema mismatches | Use testcontainers or in-memory DB |
| Mock HTTP clients | Hides timeout, retry, parsing issues | Use httptest server |
| Mock file systems | Hides permission, path issues | Use temp directories |
| Mock time | Hides timezone, DST, leap year bugs | Use clock interface with real time in tests |
| Spy/Stub functions | Hides integration issues | Test real integrations |

### What To Use Instead

```go
// BAD: Mock database
mockRepo := &MockUserRepository{}
mockRepo.On("FindByEmail", "test@example.com").Return(user, nil)

// GOOD: Real database (testcontainers)
container, _ := postgres.RunContainer(ctx)
db := connectToContainer(container)
repo := NewUserRepository(db)
// Insert real test data
db.Exec("INSERT INTO users (email, ...) VALUES ('test@example.com', ...)")
// Test with real queries
user, err := repo.FindByEmail("test@example.com")
```

```typescript
// BAD: Mock API client
jest.mock('./api', () => ({ fetchUser: jest.fn() }))

// GOOD: Real HTTP server
const server = setupServer(
  rest.get('/api/users/:id', (req, res, ctx) => {
    return res(ctx.json({ id: req.params.id, name: 'Test User' }))
  })
)
// Test with real HTTP requests
const user = await fetchUser('123')
```

### Exceptions (RARE - Requires Justification)

Only allowed when:
1. External API has rate limits (document the mock behavior)
2. External service is paid per request (document cost avoidance)
3. External service is unreliable (document flakiness mitigation)

**Even then, have at least ONE integration test against the real service.**

---

## SECURITY TESTING REQUIREMENTS (MANDATORY)

Every AIDA project MUST have tests for:

### Input Validation

```go
// REQUIRED: SQL injection tests
func TestSQLInjection(t *testing.T) {
    maliciousInputs := []string{
        "'; DROP TABLE users; --",
        "1 OR 1=1",
        "admin'--",
        "1; SELECT * FROM users",
    }
    for _, input := range maliciousInputs {
        // Verify input is safely handled
    }
}
```

### Authentication/Authorization

```go
// REQUIRED: Auth bypass tests
func TestAuthBypass(t *testing.T) {
    // Test accessing protected resources without auth
    // Test accessing other users' resources
    // Test privilege escalation
    // Test expired/invalid tokens
}
```

### Data Protection

```go
// REQUIRED: Sensitive data exposure tests
func TestNoSensitiveDataExposure(t *testing.T) {
    // Verify passwords not in responses
    // Verify tokens not logged
    // Verify PII is properly masked
}
```

---

## TDD EVIDENCE REQUIREMENTS

For EACH feature implementation, you MUST provide:

### 1. RED Phase Evidence

```
Feature: User Registration
Test File: internal/handler/auth_handler_test.go

=== RED PHASE ===
Test: TestRegisterHandler_ValidInput
Running: go test -v -run TestRegisterHandler_ValidInput

--- FAIL: TestRegisterHandler_ValidInput (0.00s)
    auth_handler_test.go:45: handler not implemented
    Expected status 201, got 404

FAILURE CAPTURED ✓
```

### 2. GREEN Phase Evidence

```
=== GREEN PHASE ===
Implementation: internal/handler/auth_handler.go (lines 15-45)
Running: go test -v -run TestRegisterHandler_ValidInput

--- PASS: TestRegisterHandler_ValidInput (0.02s)

SUCCESS CAPTURED ✓
```

### 3. REFACTOR Phase Evidence

```
=== REFACTOR PHASE ===
Changes: Extracted validation to separate function
Running: go test -v ./...

PASS
ok      twitter-clone/internal/handler    0.156s

ALL TESTS STILL PASS ✓
```

---

## BACKEND TESTING REQUIREMENTS (GO)

### Handler Tests (30+ tests)

EVERY handler must have tests for:

```go
// auth_handler_test.go - MINIMUM 8 tests per handler

func TestRegisterHandler(t *testing.T) {
    tests := []struct {
        name           string
        body           string
        expectedStatus int
        expectedBody   string
    }{
        // Happy path
        {"valid registration", `{"email":"test@example.com","password":"pass123","username":"user1"}`, 201, ""},

        // Validation errors (400)
        {"empty body", ``, 400, "invalid request"},
        {"invalid json", `{invalid}`, 400, "invalid json"},
        {"missing email", `{"password":"pass123","username":"user1"}`, 400, "email required"},
        {"missing password", `{"email":"test@example.com","username":"user1"}`, 400, "password required"},
        {"missing username", `{"email":"test@example.com","password":"pass123"}`, 400, "username required"},
        {"invalid email format", `{"email":"not-an-email","password":"pass123","username":"user1"}`, 400, "invalid email"},
        {"password too short", `{"email":"test@example.com","password":"123","username":"user1"}`, 400, "password too short"},
        {"username too short", `{"email":"test@example.com","password":"pass123","username":"ab"}`, 400, "username too short"},
        {"username too long", `{"email":"test@example.com","password":"pass123","username":"` + strings.Repeat("a", 50) + `"}`, 400, "username too long"},

        // Conflict errors (409)
        {"duplicate email", `{"email":"existing@example.com","password":"pass123","username":"user2"}`, 409, "email exists"},
        {"duplicate username", `{"email":"new@example.com","password":"pass123","username":"existinguser"}`, 409, "username exists"},

        // Server errors (500) - handled by mocking service failure
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // ... test implementation
        })
    }
}

func TestLoginHandler(t *testing.T) {
    // MINIMUM 6 tests
    // - valid login
    // - empty body
    // - invalid json
    // - wrong email
    // - wrong password
    // - account locked (if applicable)
}

func TestLogoutHandler(t *testing.T) {
    // MINIMUM 3 tests
    // - valid logout
    // - no token
    // - invalid token
}

func TestGetCurrentUserHandler(t *testing.T) {
    // MINIMUM 4 tests
    // - valid token
    // - no token
    // - expired token
    // - invalid token
}
```

### Service Tests (20+ tests)

```go
// auth_service_test.go

func TestAuthService_Register(t *testing.T) {
    tests := []struct {
        name        string
        input       RegisterInput
        mockSetup   func(*MockRepo)
        expectErr   bool
        expectToken bool
    }{
        {"success", validInput, noConflict, false, true},
        {"email exists", existingEmail, emailConflict, true, false},
        {"username exists", existingUser, usernameConflict, true, false},
        {"db error", validInput, dbError, true, false},
        {"hash error", validInput, hashError, true, false},
    }
}

func TestAuthService_Login(t *testing.T) {
    // MINIMUM 5 tests
}

func TestAuthService_ValidateToken(t *testing.T) {
    // MINIMUM 5 tests
    // - valid token
    // - expired token
    // - invalid signature
    // - malformed token
    // - token for deleted user
}
```

### Repository Tests (15+ tests)

```go
// user_repo_test.go

func TestUserRepository_Create(t *testing.T) {
    // 3+ tests
}

func TestUserRepository_GetByEmail(t *testing.T) {
    // 3+ tests: found, not found, db error
}

func TestUserRepository_GetByUsername(t *testing.T) {
    // 3+ tests
}

func TestUserRepository_GetAll_EmptyResult(t *testing.T) {
    // CRITICAL: Must return [] not null
    db := setupEmptyTestDB(t)
    repo := NewUserRepository(db)

    users, err := repo.GetAll()

    assert.NoError(t, err)
    assert.NotNil(t, users)        // MUST NOT be nil
    assert.Len(t, users, 0)        // Empty slice

    // Verify JSON serialization
    jsonBytes, _ := json.Marshal(users)
    assert.Equal(t, "[]", string(jsonBytes)) // NOT "null"
}
```

### Middleware Tests (10+ tests)

```go
// auth_middleware_test.go

func TestAuthMiddleware(t *testing.T) {
    tests := []struct {
        name           string
        authHeader     string
        expectedStatus int
    }{
        {"no header", "", 401},
        {"empty bearer", "Bearer ", 401},
        {"invalid bearer format", "NotBearer token", 401},
        {"expired token", "Bearer " + expiredToken, 401},
        {"invalid signature", "Bearer " + invalidSignature, 401},
        {"valid token", "Bearer " + validToken, 200},
    }
}

// cors_middleware_test.go
func TestCORSMiddleware(t *testing.T) {
    // 4+ tests
}
```

---

## FRONTEND TESTING REQUIREMENTS (REACT)

### Page Tests (35+ tests)

```tsx
// LoginPage.test.tsx - MINIMUM 8 tests

describe('LoginPage', () => {
  // Rendering tests
  it('renders email input')
  it('renders password input')
  it('renders submit button')
  it('renders link to register page')

  // Validation tests
  it('shows error for empty email')
  it('shows error for invalid email format')
  it('shows error for empty password')
  it('disables submit button while loading')

  // Interaction tests
  it('updates email value on input')
  it('updates password value on input')
  it('submits form on button click')
  it('submits form on enter key')

  // API response tests
  it('shows success and redirects on valid login')
  it('shows error message on 401')
  it('shows error message on 500')
  it('shows network error message on fetch failure')

  // State tests
  it('clears error when user types')
  it('persists form values on error')
})

// RegisterPage.test.tsx - MINIMUM 10 tests
// HomePage.test.tsx - MINIMUM 8 tests
// ProfilePage.test.tsx - MINIMUM 6 tests
// PostDetailPage.test.tsx - MINIMUM 5 tests
```

### Component Tests (40+ tests)

```tsx
// PostCard.test.tsx - MINIMUM 10 tests

describe('PostCard', () => {
  // Rendering
  it('renders author name')
  it('renders post content')
  it('renders timestamp')
  it('renders like count')
  it('renders like button')
  it('renders delete button for owner')
  it('hides delete button for non-owner')

  // Interactions
  it('calls onLike when like button clicked')
  it('calls onDelete when delete button clicked')
  it('shows confirmation before delete')

  // State
  it('shows filled heart when liked')
  it('shows empty heart when not liked')
  it('disables like button while loading')

  // Edge cases
  it('handles very long content')
  it('handles empty content')
  it('handles missing author')
})

// PostForm.test.tsx - MINIMUM 8 tests
// PostList.test.tsx - MINIMUM 6 tests
// UserCard.test.tsx - MINIMUM 5 tests
// Button.test.tsx - MINIMUM 4 tests
// Input.test.tsx - MINIMUM 4 tests
// Modal.test.tsx - MINIMUM 5 tests
// LoadingSpinner.test.tsx - MINIMUM 2 tests
// ErrorMessage.test.tsx - MINIMUM 3 tests
// EmptyState.test.tsx - MINIMUM 3 tests
```

### Context/Hook Tests (15+ tests)

```tsx
// AuthContext.test.tsx - MINIMUM 8 tests

describe('AuthContext', () => {
  it('provides null user when not authenticated')
  it('provides user when authenticated')
  it('login updates user state')
  it('login stores token in localStorage')
  it('logout clears user state')
  it('logout removes token from localStorage')
  it('register creates user and stores token')
  it('refreshes token before expiry')
  it('redirects to login on token expiry')
})

// useApi.test.tsx - MINIMUM 5 tests
// usePosts.test.tsx - MINIMUM 5 tests
```

### API Client Tests (10+ tests)

```tsx
// api.test.ts - MINIMUM 10 tests

describe('API Client', () => {
  // Request tests
  it('adds auth header when token exists')
  it('does not add auth header when no token')
  it('sends correct content-type')

  // Response tests
  it('parses JSON response')
  it('handles empty response')
  it('handles null response as empty array')

  // Error tests
  it('throws on 400 with error message')
  it('throws on 401 and clears token')
  it('throws on 404')
  it('throws on 500')
  it('throws on network error')

  // Retry tests
  it('retries on 503')
  it('does not retry on 400')
})
```

---

## E2E TESTS (PLAYWRIGHT) - MINIMUM 20 TESTS

### e2e/auth.spec.ts (6 tests)

```typescript
test('user can register with valid data')
test('registration fails with existing email')
test('registration validates required fields')
test('user can login after registration')
test('login fails with wrong password')
test('user can logout and session is cleared')
```

### e2e/posts.spec.ts (8 tests)

```typescript
test('can create a new post')
test('post appears in timeline immediately')
test('can delete own post')
test('cannot delete others post')
test('can like a post')
test('can unlike a post')
test('shows empty state when no posts')
test('validates post length limit')
```

### e2e/navigation.spec.ts (4 tests)

```typescript
test('redirects to login when not authenticated')
test('can navigate to profile page')
test('can navigate back to home')
test('shows 404 for unknown routes')
```

### e2e/error.spec.ts (2 tests)

```typescript
test('handles server error gracefully')
test('handles network failure gracefully')
```

---

## E2E TEST EXECUTION PROTOCOL (MANDATORY)

E2Eテストは**実際に実行**されなければなりません。テストファイルの存在だけでは不十分です。

### 前提条件

E2Eテストを実行する前に以下が必要:

- [ ] Docker/Podmanが利用可能
- [ ] Backend/Frontendの実装が完了
- [ ] ユニットテストが全てPASS
- [ ] Playwright がインストール済み

### 実行環境

```
┌─────────────────────────────────────────┐
│  Docker/Podman 環境                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │Postgres │→ │ Backend │→ │Frontend │ │
│  │  :5432  │  │  :8080  │  │  :5173  │ │
│  └─────────┘  └─────────┘  └─────────┘ │
└─────────────────────────────────────────┘
         ↑
    Playwright ブラウザテスト
```

### Playwright設定の必須項目

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  retries: 2,
  reporter: [['list'], ['json', { outputFile: 'test-results/results.json' }]],
  use: {
    // Docker環境では localhost を使用
    baseURL: process.env.E2E_BASE_URL || 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  // 開発時はwebServerを使用、Docker環境では不要
  webServer: process.env.CI || process.env.E2E_BASE_URL ? undefined : {
    command: 'pnpm run dev',
    url: 'http://localhost:5173',
    reuseExistingServer: true,
    timeout: 120000,
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
```

### E2Eテスト実行コマンド

```bash
# Step 1: Docker環境を起動
cd {{PROJECT_DIR}}/{{PROJECT}}
podman-compose up -d --build  # または docker compose up -d --build
sleep 30  # サービス起動待ち

# Step 2: ヘルスチェック
curl -sf http://localhost:8080/health || exit 1
curl -sf http://localhost:5173/ || exit 1

# Step 3: Playwright ブラウザをインストール
cd frontend
pnpm exec playwright install chromium --with-deps

# Step 4: E2Eテスト実行
E2E_BASE_URL=http://localhost:5173 pnpm test:e2e

# Step 5: 結果確認
# 全テストがPASSしたらOK

# Step 6: クリーンアップ
cd ..
podman-compose down
```

### package.json スクリプト設定

```json
{
  "scripts": {
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:e2e:debug": "playwright test --debug"
  }
}
```

### Quality Gate 19 との連携

`scripts/quality-gates.sh` の Gate 19 は以下のフローで実行:

```
Gate 6: Docker Run
  ↓
Gate 7: Health Check
  ↓
Gate 19: E2E Test Execution
  ├── Playwright browsers install
  ├── E2E_BASE_URL=http://localhost:5173
  ├── pnpm test:e2e --reporter=list
  └── 全テストPASS → Gate 19 PASS
  ↓
cleanup_docker
```

### E2Eテスト失敗時の対応

1. **エラーログを確認**
   ```bash
   cat test-results/results.json | jq '.suites[].specs[] | select(.ok == false)'
   ```

2. **スクリーンショットを確認**
   ```bash
   ls -la test-results/
   ```

3. **テストを修正**
   - セレクタの更新
   - 待機時間の調整
   - APIレスポンスのモック修正

4. **再実行**
   ```bash
   E2E_BASE_URL=http://localhost:5173 pnpm test:e2e
   ```

### E2E Test Evidence (必須)

E2Eテスト実行後、以下のファイルが生成されること:

```
frontend/
├── test-results/
│   ├── results.json       # テスト結果JSON
│   └── *.png              # 失敗時のスクリーンショット
└── playwright-report/
    └── index.html         # HTMLレポート
```

**E2Eテストを実際に実行せずに完了宣言することは禁止**

---

## VITEST CONFIGURATION (MANDATORY)

```typescript
// vitest.config.ts

import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    include: ['src/**/*.{test,spec}.{js,ts,jsx,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/index.ts',
      ],
      thresholds: {
        lines: 70,
        functions: 75,
        branches: 60,
        statements: 70,
      },
    },
    // FAIL if any test takes more than 10 seconds
    testTimeout: 10000,
    // FAIL if coverage thresholds not met
    passWithNoTests: false,
  },
})
```

---

## QUALITY GATE VERIFICATION

### Gate Script Updates

```bash
#!/bin/bash
# scripts/quality-gates.sh

PROJECT=$1
BACKEND_DIR="{{PROJECT_DIR}}/$PROJECT/backend"
FRONTEND_DIR="{{PROJECT_DIR}}/$PROJECT/frontend"

echo "=== QUALITY GATES ==="
echo ""

# Gate 1: Backend Build
echo "Gate 1: Backend Build"
cd "$BACKEND_DIR"
if go build ./... 2>&1; then
    echo "  ✅ PASS"
else
    echo "  ❌ FAIL"
    exit 1
fi

# Gate 2: Backend Tests (80+ required)
echo "Gate 2: Backend Tests"
TEST_OUTPUT=$(go test ./... -v 2>&1)
TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -c "--- PASS:")
echo "  Test count: $TEST_COUNT"
if [ "$TEST_COUNT" -ge 80 ]; then
    echo "  ✅ PASS ($TEST_COUNT >= 80)"
else
    echo "  ❌ FAIL ($TEST_COUNT < 80 required)"
    exit 1
fi

# Gate 3: Backend Coverage (75%+ required)
echo "Gate 3: Backend Coverage"
COVERAGE=$(go test ./... -cover 2>&1 | grep -oP 'coverage: \K[0-9.]+' | head -1)
echo "  Coverage: $COVERAGE%"
if (( $(echo "$COVERAGE >= 75" | bc -l) )); then
    echo "  ✅ PASS ($COVERAGE% >= 75%)"
else
    echo "  ❌ FAIL ($COVERAGE% < 75% required)"
    exit 1
fi

# Gate 4: Frontend Build
echo "Gate 4: Frontend Build"
cd "$FRONTEND_DIR"
if npm run build 2>&1; then
    echo "  ✅ PASS"
else
    echo "  ❌ FAIL"
    exit 1
fi

# Gate 5: Frontend Tests (100+ required)
echo "Gate 5: Frontend Tests"
TEST_OUTPUT=$(npm test -- --run 2>&1)
TEST_COUNT=$(echo "$TEST_OUTPUT" | grep -oP 'Tests\s+\K\d+(?=\s+passed)')
echo "  Test count: $TEST_COUNT"
if [ "$TEST_COUNT" -ge 100 ]; then
    echo "  ✅ PASS ($TEST_COUNT >= 100)"
else
    echo "  ❌ FAIL ($TEST_COUNT < 100 required)"
    exit 1
fi

# Gate 6: Frontend Coverage (70%+ required)
echo "Gate 6: Frontend Coverage"
npm test -- --run --coverage 2>&1
COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
echo "  Coverage: $COVERAGE%"
if (( $(echo "$COVERAGE >= 70" | bc -l) )); then
    echo "  ✅ PASS ($COVERAGE% >= 70%)"
else
    echo "  ❌ FAIL ($COVERAGE% < 70% required)"
    exit 1
fi

# Gate 7-9: Docker
echo "Gate 7: Docker Build"
cd "{{PROJECT_DIR}}/$PROJECT"
docker compose build 2>&1 && echo "  ✅ PASS" || { echo "  ❌ FAIL"; exit 1; }

echo "Gate 8: Docker Run"
docker compose up -d 2>&1 && sleep 15 && echo "  ✅ PASS" || { echo "  ❌ FAIL"; exit 1; }

echo "Gate 9: Health Check"
curl -sf http://localhost:8080/health && echo "  ✅ PASS" || { echo "  ❌ FAIL"; exit 1; }

# Gate 10: E2E Tests (20+ required)
echo "Gate 10: E2E Tests"
cd "$FRONTEND_DIR"
E2E_OUTPUT=$(npx playwright test 2>&1)
E2E_COUNT=$(echo "$E2E_OUTPUT" | grep -oP '\d+(?=\s+passed)')
echo "  E2E count: $E2E_COUNT"
if [ "$E2E_COUNT" -ge 20 ]; then
    echo "  ✅ PASS ($E2E_COUNT >= 20)"
else
    echo "  ❌ FAIL ($E2E_COUNT < 20 required)"
    exit 1
fi

echo ""
echo "=== ALL GATES PASSED ==="
echo "Backend: $BACKEND_TEST_COUNT tests, $BACKEND_COVERAGE% coverage"
echo "Frontend: $FRONTEND_TEST_COUNT tests, $FRONTEND_COVERAGE% coverage"
echo "E2E: $E2E_COUNT tests"
```

---

## TDD EVIDENCE FILE (MANDATORY)

Every implementation MUST create `.aida/results/tdd-evidence-{component}.json`:

```json
{
  "component": "auth-handler",
  "cycles": [
    {
      "feature": "user registration",
      "test_file": "internal/handler/auth_handler_test.go",
      "red": {
        "timestamp": "2025-01-10T10:00:00Z",
        "test_name": "TestRegisterHandler_ValidInput",
        "output": "FAIL: handler not found"
      },
      "green": {
        "timestamp": "2025-01-10T10:05:00Z",
        "implementation_file": "internal/handler/auth_handler.go",
        "lines_added": 45,
        "output": "PASS"
      },
      "refactor": {
        "timestamp": "2025-01-10T10:10:00Z",
        "changes": "Extracted validation to validateRegisterInput()",
        "all_tests_pass": true
      }
    }
  ],
  "total_cycles": 15,
  "tests_written_first": 15,
  "tests_written_after": 0
}
```

---

## FORBIDDEN ACTIONS

```
❌ Writing code before writing a failing test
❌ Writing multiple features before running tests
❌ Skipping refactor phase
❌ Claiming TDD without evidence
❌ Test count below minimum
❌ Coverage below threshold
❌ Empty arrays returning null
❌ Untested error handling
❌ Mocking everything (some integration tests required)
```

---

## COMPLETION CHECKLIST

Before marking implementation complete:

- [ ] Backend has 80+ passing tests
- [ ] Backend has 75%+ line coverage
- [ ] Frontend has 100+ passing tests
- [ ] Frontend has 70%+ line coverage
- [ ] E2E has 20+ passing tests
- [ ] TDD evidence file exists for each component
- [ ] All quality gates pass
- [ ] Empty arrays return `[]` not `null`
- [ ] All error cases have tests
- [ ] All edge cases have tests

**NO EXCEPTIONS. NO SHORTCUTS. NO EXCUSES.**

---

## MOTIVATIONAL REMINDER

```
Tests are not extra work.
Tests are the ONLY way to prove your code works.

Every bug you ship is a test you didn't write.
Every crash is a scenario you didn't consider.
Every angry user is a test case you skipped.

Write. The. Tests. First.
```
