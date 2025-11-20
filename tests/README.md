# Testing Framework

This directory contains automated tests for the Automation Alchemy project.

## Test Categories

### 1. Code Quality Tests (`code-quality.sh`)

Runs static analysis on code:
- **ESLint**: Checks JavaScript code quality
- **ShellCheck**: Validates bash script syntax and best practices

**Usage:**
```bash
./tests/code-quality.sh
```

**Requirements:**
- `eslint` (npm install -g eslint)
- `shellcheck` (apt install shellcheck / brew install shellcheck)

---

### 2. Security Tests (`security-scan.sh`)

Scans for security vulnerabilities:
- **Trivy**: Container and filesystem scanning

**Usage:**
```bash
# Scan Dockerfile
./tests/security-scan.sh

# Scan Docker image
DOCKER_IMAGE=your-image:tag ./tests/security-scan.sh
```

**Requirements:**
- `trivy` (see [Trivy installation](https://aquasecurity.github.io/trivy/latest/getting-started/installation/))

---

### 3. Performance Tests (`performance-test.sh`)

Load testing and performance validation:
- Uses Apache Bench (ab) or curl fallback
- Tests response times and request success rates

**Usage:**
```bash
TARGET_URL=http://localhost:8080 \
REQUESTS=100 \
CONCURRENCY=10 \
MAX_RESPONSE_TIME=1000 \
./tests/performance-test.sh
```

**Requirements:**
- `ab` (Apache Bench) - optional, falls back to curl
- `curl`
- `bc` (for calculations)

---

### 4. Integration Tests (`integration-test.sh`)

End-to-end API and service tests:
- Tests all API endpoints
- Validates load balancer distribution
- Checks health endpoints

**Usage:**
```bash
BASE_URL=http://localhost:8080 \
VM_IP=your-vm-ip \
./tests/integration-test.sh
```

**Requirements:**
- `curl`

---

## Running All Tests Locally

```bash
# Make scripts executable (Linux/Mac)
chmod +x tests/*.sh

# Run all tests
./tests/code-quality.sh
./tests/security-scan.sh
./tests/integration-test.sh
./tests/performance-test.sh
```

---

## CI/CD Integration

All tests are integrated into the GitLab CI pipeline:

1. **Code Quality** - Runs in `test` stage (before build)
2. **Security Scan** - Runs in `security` stage (after build)
3. **Integration Tests** - Runs in `integration` stage (after deploy, manual)
4. **Performance Tests** - Runs in `integration` stage (after deploy, manual)

See `.gitlab-ci.yml` for full pipeline configuration.

---

## Test Results

- ✅ **Green**: Test passed
- ⚠️ **Yellow**: Warning (non-blocking)
- ❌ **Red**: Test failed (blocking)

---

## Troubleshooting

### ESLint not found
```bash
npm install -g eslint
```

### ShellCheck not found
```bash
# Ubuntu/Debian
apt install shellcheck

# macOS
brew install shellcheck

# Alpine
apk add shellcheck
```

### Trivy not found
```bash
# See: https://aquasecurity.github.io/trivy/latest/getting-started/installation/
```

### Apache Bench not found
```bash
# Ubuntu/Debian
apt install apache2-utils

# macOS
# Already included or: brew install httpd
```

---

## Adding New Tests

1. Create a new test script in `tests/`
2. Make it executable: `chmod +x tests/your-test.sh`
3. Add it to `.gitlab-ci.yml` in the appropriate stage
4. Update this README

