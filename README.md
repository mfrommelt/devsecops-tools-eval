# CSB DevSecOps Test Repository

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Security Testing](https://img.shields.io/badge/Security-Testing-red.svg)](https://github.com/csb/devsecops-test/security)
[![DevSecOps](https://img.shields.io/badge/DevSecOps-Pipeline-blue.svg)](https://github.com/csb/devsecops-test)

> ⚠️ **WARNING**: This repository contains **intentional security vulnerabilities** for testing purposes. **DO NOT** deploy to production environments.

## 🎯 Purpose

This repository serves as a comprehensive testing ground for CSB's DevSecOps pipeline, security tools, and CI/CD processes. It contains sample applications across our entire technology stack with intentional security vulnerabilities to validate our security scanning capabilities.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    CSB Technology Stack                         │
├─────────────────────────────────────────────────────────────────┤
│  Frontend: React + Angular (TypeScript)                        │
│  Backend: Python + Java + C# + Node.js + PHP                  │
│  Databases: PostgreSQL + MySQL + Oracle                        │
│  Infrastructure: Azure + AWS + Kubernetes                      │
│  Security: Multi-tool scanning pipeline                        │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
csb-devsecops-test/
├── 🖥️  frontend/                    # Frontend Applications
│   ├── react-app/                   # React + TypeScript
│   └── angular-app/                 # Angular + TypeScript
├── ⚙️  backend/                     # Backend Applications  
│   ├── python-django/               # Django Web Framework
│   ├── python-flask/                # Flask API
│   ├── java-springboot/             # Spring Boot API
│   ├── java-mulesoft/               # MuleSoft Integration & DataWeave
│   ├── csharp-webapi/               # .NET Core Web API
│   ├── csharp-etl/                  # C# ETL Automation Tools
│   ├── node-express/                # Node.js Express API
│   └── php-drupal/                  # Drupal 9/10 Application
├── 🗄️  databases/                   # Database Configurations
│   ├── postgresql/                  # PostgreSQL schemas & migrations
│   ├── mysql/                       # MySQL schemas & migrations
│   └── oracle/                      # Oracle procedures & schemas
├── 🏗️  infrastructure/              # Infrastructure as Code
│   ├── terraform/                   # Terraform (Azure, AWS, MuleSoft)
│   ├── docker/                      # Docker configurations
│   └── pantheon/                    # Pantheon hosting configs
├── 🔒 security/                     # Security Configurations
│   ├── policies/                    # Network & API security policies
│   ├── zap/                         # OWASP ZAP DAST configs
│   ├── sbom/                        # Software Bill of Materials
│   ├── compliance/                  # SOX, PCI-DSS frameworks
│   ├── mulesoft/                    # MuleSoft security configs
│   └── drupal/                      # Drupal security configurations
├── 🚀 .github/workflows/            # CI/CD Pipelines
│   ├── ci.yml                       # Main CI workflow
│   ├── security.yml                 # Security scanning
│   ├── cd.yml                       # Deployment pipeline
│   ├── infrastructure.yml           # Infrastructure deployment
│   ├── mulesoft.yml                 # MuleSoft/DataWeave pipeline
│   └── drupal.yml                   # Drupal security pipeline
├── 📝 .semgrep/                     # Custom Security Rules
│   ├── csb-custom-rules.yml         # Custom security rules
│   ├── java-rules.yml               # Java-specific rules
│   ├── typescript-rules.yml         # Frontend security rules
│   ├── dataweave-rules.yml          # DataWeave security rules
│   └── drupal-rules.yml             # Drupal security rules
├── 🛠️  scripts/                     # Automation Scripts
│   ├── setup/                       # Environment setup scripts
│   ├── security/                    # Security scanning scripts
│   ├── deployment/                  # Deployment automation
│   └── mulesoft/                    # MuleSoft-specific scripts
├── 🐳 docker-compose.yml            # Local Development Setup
├── 🐳 docker-compose.mulesoft.yml   # MuleSoft Services
├── 🐳 docker-compose.drupal.yml     # Drupal with Security Tools
├── 🔧 .devcontainer/                # GitHub Codespaces Config
├── 🔍 .pre-commit-config.yaml       # Pre-commit Security Hooks
└── 📚 docs/                         # Documentation
    ├── SECURITY.md                  # Security guidelines
    ├── MULESOFT_SECURITY.md         # MuleSoft security guide
    ├── DRUPAL_SECURITY.md           # Drupal security guide
    ├── ARCHITECTURE.md              # System architecture
    └── DEPLOYMENT.md                # Deployment guide
```

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/)
- [Node.js](https://nodejs.org/) (v16+)
- [Python](https://www.python.org/) (3.9+)
- [Git](https://git-scm.com/)

### Option 1: GitHub Codespaces (Recommended) ☁️

**GitHub Codespaces provides a pre-configured cloud development environment with all tools installed.**

#### 🚀 Launch Codespaces

1. **Open in Codespaces:**
   ```bash
   # From GitHub repository page, click:
   # Code → Codespaces → Create codespace on main
   ```
   Or use the direct link: [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/csb/devsecops-test)

2. **Wait for Environment Setup:**
   The codespace will automatically:
   - ✅ Install all required tools (Docker, Node.js, Python, security tools)
   - ✅ Configure pre-commit hooks
   - ✅ Set up development environment
   - ✅ Install security scanning tools

#### 🔧 Codespaces Configuration

The repository includes a `.devcontainer/devcontainer.json` configuration:

```json
{
  "name": "CSB DevSecOps Test Environment",
  "image": "mcr.microsoft.com/devcontainers/universal:2",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {},
    "ghcr.io/devcontainers/features/node:1": {"version": "18"},
    "ghcr.io/devcontainers/features/python:1": {"version": "3.9"}
  },
  "postCreateCommand": ".devcontainer/setup.sh",
  "forwardPorts": [3000, 3001, 4200, 5000, 8000, 8080, 8081, 8090, 8888],
  "portsAttributes": {
    "3000": {"label": "React App", "onAutoForward": "notify"},
    "4200": {"label": "Angular App", "onAutoForward": "notify"},
    "8000": {"label": "Django API", "onAutoForward": "notify"},
    "8080": {"label": "Spring Boot API", "onAutoForward": "notify"}
  }
}
```

#### 🏃‍♂️ Running Tests in Codespaces

Once your codespace is ready:

```bash
# 1. Start all services
chmod +x ./start-with-dependencies.sh
./start-with-dependencies.sh

# 2. Wait for services to be ready (about 60 seconds)
sleep 60

# 3. Run comprehensive security scans
./scripts/security/run-security-scans.sh

# 4. View individual application logs
docker-compose logs spring-boot-api
docker-compose logs django-app

# 5. Access applications through forwarded ports
# Codespaces will automatically forward and provide URLs for:
# - React App (port 3000)
# - Angular App (port 4200) 
# - Django API (port 8000)
# - Spring Boot API (port 8080)
# - All other services...
```

#### 🔒 Security Testing in Codespaces

**Pre-installed Security Tools:**
```bash
# Verify security tools are available
semgrep --version
snyk --version  
trufflehog --version
docker run --rm owasp/zap2docker-stable --version

# Run individual security scans
semgrep --config=p/security-audit .
snyk test --all-projects
trufflehog git file://. --only-verified
```

**Manual Testing Commands:**
```bash
# Test specific vulnerabilities
curl "http://localhost:8080/api/users/1'; DROP TABLE users; --"  # SQL injection test
curl -X POST -H "Content-Type: application/json" \
  -d '{"username":"<script>alert(1)</script>"}' \
  http://localhost:8080/api/login  # XSS test

# Check for sensitive data exposure
curl http://localhost:8080/api/users/1 | grep -i "password\|ssn\|credit"
```

#### 📊 View Security Reports in Codespaces

```bash
# Generate comprehensive security report
./scripts/security/run-security-scans.sh

# View reports in VS Code
code security-reports/security-summary.md

# Open security reports in browser
python3 -m http.server 8000 --directory security-reports
# Then access via forwarded port 8000
```

#### 💡 Codespaces Benefits for Security Testing

✅ **Isolated Environment:** No risk to your local machine  
✅ **Pre-configured Tools:** All security tools pre-installed  
✅ **Consistent Environment:** Same setup for all team members  
✅ **Port Forwarding:** Easy access to all applications  
✅ **VS Code Integration:** Full IDE experience in browser  
✅ **Git Integration:** Seamless GitHub integration  
✅ **Secrets Management:** GitHub secrets available in codespace  

#### 🛠️ Codespaces Troubleshooting

<details>
<summary>🐛 Services not starting in Codespaces</summary>

```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker if needed
sudo systemctl restart docker

# Check available resources
df -h
free -h

# Restart services with more memory
docker-compose down
docker-compose up -d --memory=2g
```
</details>

<details>
<summary>🔧 Security tools not working</summary>

```bash
# Reinstall security tools
pip install --upgrade semgrep
npm install -g snyk

# Re-run setup script
.devcontainer/setup.sh

# Check PATH
echo $PATH
which semgrep snyk trufflehog
```
</details>

### Option 2: Local Development

#### 1. Clone & Setup

```bash
# Clone the repository
git clone https://github.com/csb/devsecops-test.git
cd devsecops-test

# Run automated setup
chmod +x scripts/setup/setup-dev-environment.sh
./scripts/setup/setup-dev-environment.sh
```

### 2. Configure GitHub Secrets

In your GitHub repository settings, add these secrets:

```bash
SEMGREP_APP_TOKEN=your_semgrep_token_here
SNYK_TOKEN=your_snyk_token_here
```

**For Codespaces:** These secrets are automatically available in your codespace environment.

**For Local Development:** You'll need to export these as environment variables:
```bash
export SEMGREP_APP_TOKEN=your_semgrep_token_here  
export SNYK_TOKEN=your_snyk_token_here
```

### 3. Start the Application Stack

```bash
# Start all services
docker-compose up -d

# Verify services are running
docker-compose ps
```

### 4. Access Applications

| Service | URL | Description |
|---------|-----|-------------|
| **React App** | http://localhost:3000 | Frontend React application |
| **Angular App** | http://localhost:4200 | Frontend Angular application |
| **Django API** | http://localhost:8000 | Python Django backend |
| **Flask API** | http://localhost:5000 | Python Flask API |
| **Spring Boot** | http://localhost:8080 | Java Spring Boot API |
| **.NET Core** | http://localhost:8090 | C# .NET Core Web API |
| **Node.js API** | http://localhost:3001 | Node.js Express API |
| **PHP/Drupal** | http://localhost:8888 | PHP Drupal application |
| **Adminer** | http://localhost:8081 | Database administration |

## 🔒 Security Testing

### Automated Security Pipeline

Our CI/CD pipeline includes comprehensive security scanning:

```
Code Commit → Pre-commit Hooks → Secret Scanning → SAST Analysis 
     ↓              ↓                    ↓              ↓
Dependency Scan → Container Scan → DAST Testing → Compliance Check
     ↓              ↓                    ↓              ↓
   Security Report Generated → Findings Published → Action Required
```

### Security Tools Integration

| Tool | Purpose | Coverage |
|------|---------|----------|
| **GitHub Advanced Security** | SAST, Secrets, Dependencies | Native GitHub integration |
| **Semgrep** | Custom SAST rules | All languages + custom CSB rules |
| **Snyk** | Dependency vulnerabilities | All package managers |
| **OWASP ZAP** | Dynamic security testing | All web applications |
| **Trivy** | Container vulnerability scanning | All Docker images |
| **tfsec** | Terraform security analysis | Infrastructure as Code |
| **Checkov** | Infrastructure security | Multi-cloud policies |
| **TruffleHog** | Advanced secret detection | Git history + custom patterns |

### Manual Security Scans

```bash
# Run comprehensive security analysis
./scripts/security/run-security-scans.sh

# View security reports
ls -la security-reports/

# Generate compliance report
./scripts/security/compliance-check.sh
```

## 🧪 Intentional Vulnerabilities

This repository contains **intentional security vulnerabilities** for testing purposes:

### 🔴 Critical Findings (Expected: 20+)
- **Hardcoded Secrets**: Database passwords, API keys, AWS credentials
- **SQL Injection**: Dynamic query construction in all backend languages  
- **Command Injection**: Unsafe system command execution
- **Path Traversal**: Unvalidated file path operations

### 🟡 High Findings (Expected: 30+)
- **Weak Cryptography**: MD5 hashing, weak random number generation
- **Cross-Site Scripting (XSS)**: Unsafe HTML rendering
- **Insecure Direct Object References**: Unvalidated user input
- **Security Misconfiguration**: Debug mode, overly permissive settings

### 🟠 Medium Findings (Expected: 50+)
- **Vulnerable Dependencies**: Outdated packages with known CVEs
- **Information Disclosure**: Logging of sensitive data
- **Insufficient Input Validation**: Missing sanitization
- **Insecure Communication**: HTTP instead of HTTPS

## 📊 Expected Security Scan Results

When you run the complete security pipeline, expect these findings:

```
🔍 Security Scan Summary
├── 📊 Total Findings: 100+
├── 🔴 Critical: 20+ findings
├── 🟡 High: 30+ findings  
├── 🟠 Medium: 50+ findings
└── 🟢 Low: 25+ findings

🛠️ Tools Results:
├── CodeQL: 25+ code quality & security issues
├── Semgrep: 40+ SAST findings (custom rules)
├── Snyk: 30+ dependency vulnerabilities
├── Trivy: 20+ container vulnerabilities
├── OWASP ZAP: 15+ web application issues
├── tfsec: 10+ infrastructure misconfigurations
└── TruffleHog: 15+ hardcoded secrets
```

## 🏛️ Compliance Testing

### Banking Regulations Covered

- **SOX (Sarbanes-Oxley)**: Audit trails, financial data protection
- **PCI DSS**: Credit card data security requirements  
- **SOC 2 Type II**: Security and availability controls
- **NIST Cybersecurity Framework**: Comprehensive security controls

### Compliance Validation

```bash
# Run compliance checks
./scripts/security/compliance-check.sh

# Generate compliance reports
cat security-reports/compliance-report.md
```

## 🏗️ Infrastructure Testing

### Cloud Platforms
- **Azure**: Primary cloud with AKS, App Service, Key Vault
- **AWS**: Secondary cloud with EKS, RDS, Secrets Manager

### Infrastructure as Code
- **Terraform**: Multi-cloud infrastructure provisioning
- **Kubernetes**: Container orchestration with security policies

### Security Policies
- Network security groups and policies
- Pod security policies and standards
- RBAC and identity management
- Secrets management and rotation

## 🚀 CI/CD Pipeline

### GitHub Actions Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| **ci.yml** | Push, PR | Comprehensive security testing |
| **security.yml** | Daily | Scheduled security scans |
| **cd.yml** | Main branch | Deployment pipeline |
| **infrastructure.yml** | IaC changes | Infrastructure security |

### Pipeline Stages

1. **Pre-commit Security Gates**
   - Secret scanning with TruffleHog
   - Basic SAST with Semgrep
   - Code formatting and linting

2. **Build & Security Analysis**
   - Multi-language compilation
   - Comprehensive SAST scanning
   - Dependency vulnerability analysis
   - Container security scanning

3. **Dynamic Security Testing**
   - OWASP ZAP web application scanning
   - API security testing
   - Integration security tests

4. **Compliance & Reporting**
   - Regulatory compliance validation
   - Security report generation
   - Artifact publication

## 🛠️ Development Workflow

### Local Development

```bash
# Install pre-commit hooks
pre-commit install

# Start development environment
docker-compose up -d

# Run tests for specific application
cd backend/java-springboot
./mvnw test

# Run security scans locally
semgrep --config=p/security-audit --config=.semgrep/csb-custom-rules.yml
```

### Contributing Security Tests

1. **Add New Vulnerabilities**:
   ```bash
   # Add new intentional vulnerability
   # Update corresponding test cases
   # Document the vulnerability type
   ```

2. **Create Custom Security Rules**:
   ```yaml
   # .semgrep/new-rules.yml
   rules:
     - id: custom-vulnerability-pattern
       pattern: |
         dangerous_function($VAR)
       message: "Custom security issue detected"
       severity: ERROR
   ```

3. **Update Test Cases**:
   ```bash
   # Add tests that verify security scanners detect new vulnerabilities
   # Update expected findings count
   # Document new compliance requirements
   ```

## 📈 Monitoring & Metrics

### Security Metrics Dashboard

Track the effectiveness of your security pipeline:

- **Vulnerability Detection Rate**: % of vulnerabilities caught by scanning
- **False Positive Rate**: Quality of security tool configurations  
- **Time to Detection**: How quickly new vulnerabilities are found
- **Time to Remediation**: Speed of vulnerability fixes
- **Pipeline Performance**: Impact of security scanning on build times

### Key Performance Indicators

```bash
# Security Pipeline KPIs
├── 🎯 Vulnerability Detection: 95%+ 
├── 📊 False Positive Rate: <10%
├── ⏱️ Scan Duration: <15 minutes
├── 🔄 Pipeline Success Rate: >95%
└── 📋 Compliance Score: 100%
```

## 🆘 Troubleshooting

### Common Issues

<details>
<summary>🐛 Services not starting properly</summary>

```bash
# Check service logs
docker-compose logs [service-name]

# Restart specific service
docker-compose restart [service-name]

# Rebuild containers
docker-compose up --build -d
```
</details>

<details>
<summary>🔒 Security scans failing</summary>

```bash
# Check tool installations
semgrep --version
snyk --version
trufflehog --version

# Verify GitHub secrets are set
# Check API token permissions
# Review scan configurations
```
</details>

<details>
<summary>💾 Database connection issues</summary>

```bash
# Check database containers
docker-compose ps postgres mysql oracle

# Verify database initialization
docker-compose logs postgres

# Connect manually to test
docker-compose exec postgres psql -U postgres -d csbdb
```
</details>

### Getting Help

- 📖 **Documentation**: Check the `/docs` folder for detailed guides
- 🎫 **Issues**: Create GitHub issues for bugs or feature requests  
- 💬 **Slack**: #devops-support for real-time assistance
- 📧 **Email**: devops@csb.com for security-related questions

## 📚 Additional Resources

### Documentation
- [Security Testing Guide](docs/SECURITY.md)
- [API Documentation](docs/API_DOCUMENTATION.md)
- [Architecture Overview](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

### External Resources
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [DevSecOps Best Practices](https://www.devsecops.org/)
- [Banking Security Regulations](https://www.ffiec.gov/cyberresources.htm)

## 🤝 Contributing

We welcome contributions to improve our security testing capabilities:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/new-security-test`)
3. **Add** your security tests or improvements
4. **Commit** your changes (`git commit -am 'Add new security test'`)
5. **Push** to the branch (`git push origin feature/new-security-test`)
6. **Create** a Pull Request

### Contribution Guidelines

- ✅ Add intentional vulnerabilities with clear documentation
- ✅ Include corresponding test cases
- ✅ Update security scan expectations
- ✅ Follow existing code style and patterns
- ✅ Include appropriate security warnings

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Security Disclaimer

**IMPORTANT**: This repository contains intentional security vulnerabilities for testing purposes only. These vulnerabilities include:

- Hardcoded secrets and credentials
- SQL injection vulnerabilities  
- Cross-site scripting (XSS) issues
- Path traversal vulnerabilities
- Weak cryptographic implementations
- Command injection opportunities

**DO NOT**:
- Deploy this code to production environments
- Use these patterns in real applications
- Expose these services to the public internet
- Use the hardcoded credentials for actual systems

**USE ONLY** for:
- Security tool testing and validation
- DevSecOps pipeline development
- Security training and education
- Compliance testing in isolated environments

## 📞 Support

For questions, issues, or support:

- **Security Issues**: security@cambridgesavings.com
- **DevOps Support**: mfrommelt@csb.com  
- **General Questions**: Create a GitHub issue

---

**Happy Security Testing! 🔒🚀**

*Built with ❤️ by the CSB DevSecOps Team*