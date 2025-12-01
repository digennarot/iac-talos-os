# Contributing Guide

Thank you for your interest in contributing to this project! This guide will help you get started.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)
- [Release Process](#release-process)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors.

### Our Standards

**Positive behaviors:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behaviors:**
- Harassment, trolling, or insulting comments
- Public or private harassment
- Publishing others' private information
- Other conduct which could reasonably be considered inappropriate

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Development Environment**:
   - Linux workstation (Debian/Ubuntu recommended)
   - Git installed and configured
   - All tools installed (see main README)

2. **Access**:
   - GitHub account
   - Fork of this repository
   - Proxmox test environment (for testing infrastructure changes)

3. **Knowledge**:
   - Basic understanding of Kubernetes
   - Familiarity with Infrastructure as Code concepts
   - Understanding of the project architecture

### Setting Up Your Development Environment

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/iac-talos-os.git
cd iac-talos-os

# Add upstream remote
git remote add upstream https://github.com/digennarot/iac-talos-os.git

# Create a development branch
git checkout -b feature/your-feature-name
```

---

## Development Workflow

### 1. Choose an Issue

- Check existing issues on GitHub
- Comment on the issue to claim it
- If no issue exists, create one first
- Discuss your approach before starting major work

### 2. Create a Branch

Branch naming conventions:

```bash
# Features
git checkout -b feature/add-new-component

# Bug fixes
git checkout -b fix/resolve-network-issue

# Documentation
git checkout -b docs/update-readme

# Refactoring
git checkout -b refactor/improve-module-structure
```

### 3. Make Changes

- Make small, focused commits
- Write clear commit messages
- Test your changes thoroughly
- Update documentation as needed

### 4. Keep Your Branch Updated

```bash
# Fetch upstream changes
git fetch upstream

# Rebase your branch
git rebase upstream/main

# Resolve conflicts if any
# Then continue
git rebase --continue
```

### 5. Push Changes

```bash
# Push to your fork
git push origin feature/your-feature-name
```

### 6. Create Pull Request

- Go to GitHub and create a pull request
- Fill out the PR template completely
- Link related issues
- Request review from maintainers

---

## Coding Standards

### General Principles

1. **Clarity over Cleverness**: Write code that is easy to understand
2. **Consistency**: Follow existing patterns in the codebase
3. **Documentation**: Comment complex logic, document all modules
4. **Testing**: Test all changes before submitting
5. **Security**: Never commit secrets or credentials

### Terraform/OpenTofu

```hcl
# Use consistent formatting
terraform fmt -recursive

# Use meaningful variable names
variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

# Add validation where appropriate
variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  
  validation {
    condition     = var.node_count > 0 && var.node_count < 100
    error_message = "Node count must be between 1 and 99"
  }
}

# Use locals for computed values
locals {
  cluster_fqdn = "${var.cluster_name}.${var.domain}"
}

# Comment complex logic
# Calculate the number of control plane nodes needed for quorum
# Must be odd number (3, 5, 7) for etcd
locals {
  control_plane_count = var.ha_enabled ? 3 : 1
}
```

### YAML (Talos, Kubernetes)

```yaml
# Use 2-space indentation
# Use consistent key ordering
# Add comments for non-obvious configuration

# Good
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: default
  labels:
    app: my-app
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080

# Bad - inconsistent indentation, no comments
apiVersion: v1
kind: Service
metadata:
    name: my-service
spec:
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: my-app
```

### Shell Scripts

```bash
#!/usr/bin/env bash
# Script description here

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Use functions for reusability
function check_prerequisites() {
  if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl not found"
    exit 1
  fi
}

# Use meaningful variable names
CLUSTER_NAME="${1:-default}"
NAMESPACE="${2:-kube-system}"

# Add error handling
if [[ -z "$CLUSTER_NAME" ]]; then
  echo "Usage: $0 <cluster-name> [namespace]"
  exit 1
fi

# Use logging
echo "Processing cluster: $CLUSTER_NAME"

# Clean up on exit
trap cleanup EXIT
function cleanup() {
  echo "Cleaning up..."
}
```

### Documentation

```markdown
# Use clear, descriptive headings

## Follow consistent formatting

### Use code blocks with language specification

```bash
# This is a bash command
kubectl get pods
```

### Use tables for structured data

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |

### Add links to related documentation

See [Architecture](./ARCHITECTURE.md) for more details.
```

---

## Testing

### Before Submitting

Test your changes thoroughly:

#### 1. Syntax Validation

```bash
# Terraform/OpenTofu
cd tofu
tofu fmt -check -recursive
tofu validate

# Packer
cd packer
packer validate -var-file="vars/local.pkrvars.hcl" main.pkr.hcl

# Talos
cd talos
talhelper validate --config talconfig-*.yaml

# YAML
yamllint .
```

#### 2. Functional Testing

```bash
# Test in a development environment
# Create a test cluster
cd tofu
tofu apply -var-file="test.tfvars"

# Verify cluster works
kubectl get nodes
cilium status

# Clean up
tofu destroy -var-file="test.tfvars"
```

#### 3. Documentation Testing

```bash
# Test all commands in documentation
# Ensure examples work
# Check for broken links
```

### Test Checklist

- [ ] Code passes syntax validation
- [ ] Changes tested in development environment
- [ ] Documentation updated
- [ ] Examples work as documented
- [ ] No secrets or credentials committed
- [ ] Backward compatibility maintained (or breaking changes documented)

---

## Documentation

### When to Update Documentation

Update documentation when you:

- Add new features
- Change existing functionality
- Fix bugs that affect usage
- Add new configuration options
- Change deployment procedures

### Documentation Structure

```
docs/
├── README.md              # Main documentation
├── WORKFLOWS.md           # Step-by-step procedures
├── ARCHITECTURE.md        # System architecture
├── CONFIGURATION.md       # Configuration reference
├── TROUBLESHOOTING.md     # Common issues
├── QUICK_REFERENCE.md     # Quick commands
└── CONTRIBUTING.md        # This file
```

### Documentation Standards

1. **Clear and Concise**: Use simple language
2. **Examples**: Provide working examples
3. **Complete**: Cover all aspects of the feature
4. **Accurate**: Test all commands and examples
5. **Updated**: Keep in sync with code changes

### Example Documentation

```markdown
## Adding a New Feature

### Overview
Brief description of what the feature does.

### Prerequisites
- Requirement 1
- Requirement 2

### Configuration

```yaml
# Example configuration
feature:
  enabled: true
  option: value
```

### Usage

```bash
# Example command
command --option value
```

### Troubleshooting

Common issues and solutions.
```

---

## Submitting Changes

### Commit Messages

Follow conventional commit format:

```
type(scope): subject

body

footer
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**

```
feat(tofu): add support for multiple clusters

Add ability to define multiple clusters in a single
configuration file. Each cluster can have different
network settings and node configurations.

Closes #123
```

```
fix(talos): correct VIP configuration

The VIP was not being properly configured on all
control plane nodes. This fix ensures all nodes
receive the VIP configuration.

Fixes #456
```

```
docs(workflows): update deployment procedure

Add missing steps for Cilium installation and
improve clarity of bootstrap process.
```

### Pull Request Process

1. **Create PR**:
   - Use descriptive title
   - Fill out PR template completely
   - Link related issues
   - Add labels (feature, bug, documentation, etc.)

2. **PR Template**:
   ```markdown
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Refactoring
   
   ## Testing
   - [ ] Tested in development environment
   - [ ] Documentation updated
   - [ ] Examples verified
   
   ## Related Issues
   Closes #123
   
   ## Screenshots (if applicable)
   
   ## Additional Notes
   ```

3. **Review Process**:
   - Address review comments
   - Make requested changes
   - Re-request review after changes
   - Be patient and respectful

4. **Merging**:
   - Maintainers will merge approved PRs
   - Squash commits if requested
   - Delete branch after merge

---

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Release Checklist

1. **Prepare Release**:
   - Update version numbers
   - Update CHANGELOG.md
   - Update documentation
   - Test thoroughly

2. **Create Release**:
   - Tag release: `git tag -a v1.2.3 -m "Release v1.2.3"`
   - Push tag: `git push origin v1.2.3`
   - Create GitHub release
   - Add release notes

3. **Post-Release**:
   - Announce release
   - Update documentation site
   - Monitor for issues

---

## Getting Help

### Resources

- **Documentation**: Check the [docs/](../docs/) directory
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub Discussions for questions

### Asking Questions

When asking for help:

1. **Search First**: Check if question already answered
2. **Be Specific**: Provide details about your issue
3. **Include Context**: Share relevant configuration and logs
4. **Be Patient**: Maintainers are volunteers

### Reporting Bugs

Use the bug report template:

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: Ubuntu 22.04
- Talos Version: v1.10.3
- Kubernetes Version: v1.33.1

## Logs
Relevant logs and error messages

## Additional Context
Any other relevant information
```

---

## Project Structure

### Repository Organization

```
iac-talos-os/
├── docs/                  # Documentation
├── packer/               # Packer templates
├── proxmox-ansible/      # Ansible playbooks
├── proxmox-autoinstall/  # Proxmox auto-install
├── talos/                # Talos configurations
├── tofu/                 # OpenTofu/Terraform
├── .gitignore           # Git ignore rules
└── README.md            # Main README
```

### Adding New Components

When adding new components:

1. Create appropriate directory structure
2. Add README.md in component directory
3. Update main documentation
4. Add examples
5. Update .gitignore if needed

---

## Code Review Guidelines

### For Contributors

- Be open to feedback
- Respond to comments promptly
- Make requested changes
- Ask questions if unclear
- Be respectful and professional

### For Reviewers

- Be constructive and helpful
- Explain reasoning for requested changes
- Approve when ready
- Be timely with reviews
- Be respectful and encouraging

---

## Recognition

Contributors will be:

- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in documentation

Thank you for contributing! 🎉

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

## Questions?

If you have questions about contributing, please:

1. Check this guide
2. Search existing issues and discussions
3. Create a new discussion
4. Reach out to maintainers

We're here to help! 🚀
