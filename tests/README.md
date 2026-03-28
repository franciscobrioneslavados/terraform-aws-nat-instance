# Terratest - Module Validation Tests

This directory contains Terratest validation tests for the NAT Instance module.

## Purpose

These tests validate that the Terraform module:
- Has all required files
- Is syntactically correct
- Contains all required outputs
- Examples are valid

**Note:** These are **validation tests**, not deployment tests. They don't create actual AWS resources.

## Running Tests

### Local

```bash
cd tests
go mod download
go test -v -timeout 30m
```

### CI/CD

Tests run automatically in GitHub Actions CI workflow.

## Test Structure

| Test | Description |
|------|-------------|
| `TestModuleStructure` | Validates module can initialize and validate |
| `TestModuleFilesExist` | Checks all required files exist |
| `TestModuleVariables` | Validates all outputs are defined |
| `TestBasicExample` | Validates basic example |
| `TestMultiRTExample` | Validates multi-route-table example |

## Notes

- Tests use `terraform init` and `terraform validate` only
- No actual AWS resources are created
- For destructive tests, see Terratest documentation
