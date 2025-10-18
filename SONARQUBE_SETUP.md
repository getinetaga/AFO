# SonarQube Configuration Guide for AFO Chat Application

## 📋 Overview

This document provides comprehensive instructions for setting up and configuring SonarQube analysis for the AFO Chat Application, covering both the Flutter frontend and Node.js/TypeScript backend.

## 🎯 Configuration Summary

### ✅ **Completed Setup**

1. **✅ Project Configuration Files**
   - `sonar-project.properties` - Main project configuration
   - `backend/sonar-project.properties` - Backend-specific configuration
   - `.sonarqube/quality-profile.properties` - Custom quality rules
   - `.sonarqube/exclusions.properties` - Comprehensive file exclusions

2. **✅ CI/CD Integration**
   - `.github/workflows/sonarqube.yml` - Main SonarQube workflow
   - `.github/workflows/backend-sonarqube.yml` - Backend-specific workflow

3. **✅ VS Code Integration**
   - Configured exclusions for generated files, build directories, and node_modules
   - Ready for SonarLint integration

## 🚀 Setup Instructions

### Step 1: SonarQube Account Setup

#### Option A: SonarQube Cloud (Recommended)
1. **Create Account**: Go to [SonarCloud.io](https://sonarcloud.io)
2. **Sign in with GitHub**: Use your GitHub account (@getinetaga)
3. **Create Organization**: Create organization `getinetaga`
4. **Import Repository**: Import the AFO repository

#### Option B: Self-hosted SonarQube Server
1. **Install SonarQube**: Download from [sonarqube.org](https://www.sonarqube.org)
2. **Configure Server**: Set up on your preferred hosting platform
3. **Install Plugins**: Add Dart/Flutter community plugins if available

### Step 2: Generate Authentication Tokens

1. **SonarQube Token**:
   - Go to SonarQube → Account → Security → Generate Token
   - Name: `afo-chat-github-actions`
   - Copy the generated token

2. **GitHub Secrets Setup**:
   ```bash
   # Add these secrets to your GitHub repository:
   # Settings → Secrets and Variables → Actions → New repository secret
   
   SONAR_TOKEN=your_sonarqube_token_here
   SONAR_HOST_URL=https://sonarcloud.io  # or your server URL
   ```

### Step 3: VS Code SonarLint Integration

1. **Install Extension**:
   ```bash
   # Install SonarLint extension in VS Code
   code --install-extension SonarSource.sonarlint-vscode
   ```

2. **Connected Mode Setup**:
   - Open Command Palette (`Cmd+Shift+P`)
   - Run: `SonarLint: Connect to SonarQube or SonarCloud`
   - Choose SonarCloud
   - Enter organization: `getinetaga`
   - Enter project key: `afo-chat-application`

### Step 4: Project Configuration

#### Main Project Setup (`sonar-project.properties`)
```properties
sonar.projectKey=afo-chat-application
sonar.projectName=AFO Chat Application  
sonar.organization=getinetaga
sonar.sources=lib,backend/src
sonar.tests=test,backend/test
```

#### Backend Project Setup (`backend/sonar-project.properties`)
```properties
sonar.projectKey=afo-chat-backend
sonar.projectName=AFO Chat Backend
sonar.organization=getinetaga
sonar.sources=src
sonar.tests=test
```

## 📊 Quality Gates & Standards

### Coverage Requirements
- **Overall Coverage**: Minimum 80%
- **New Code Coverage**: Minimum 85%
- **Changed Code Coverage**: Minimum 80%

### Code Quality Standards
- **Maintainability Rating**: A (Technical debt < 5%)
- **Reliability Rating**: A (No bugs)
- **Security Rating**: A (No vulnerabilities)
- **Security Hotspots**: 100% reviewed

### Complexity Limits
- **Function Complexity**: Maximum 10
- **File Complexity**: Maximum 200
- **Class Complexity**: Maximum 50

## 🔧 Running Analysis

### Local Analysis (VS Code)
1. **Automatic Analysis**: Files are analyzed automatically when opened
2. **Manual Trigger**: `Cmd+Shift+P` → `SonarLint: Analyze all open files`
3. **View Issues**: Check Problems panel for SonarLint issues

### Manual Command Line Analysis
```bash
# Install SonarQube Scanner
npm install -g sonarqube-scanner

# Run analysis for main project
sonar-scanner

# Run analysis for backend only
cd backend && sonar-scanner
```

### CI/CD Analysis
- **Automatic**: Runs on every push to main/develop branches
- **Pull Requests**: Analyzes changed code in PRs
- **Quality Gate**: Blocks merging if quality standards not met

## 📁 File Exclusions

### Excluded from Analysis
- Generated files (`*.generated.dart`, `*.g.dart`, `*.mocks.dart`)
- Build directories (`build/`, `dist/`, `node_modules/`)
- Platform code (`android/`, `ios/`, `windows/`, etc.)
- Test files (analyzed separately)
- Configuration files with potential secrets

### Excluded from Coverage
- Entry point files (`main.dart`, `server.ts`)
- Model/type definitions
- Configuration classes
- Constants and enums

## 🛡️ Security Configuration

### Security Rules Enabled
- **Hardcoded passwords detection**
- **SQL injection prevention**
- **Command injection detection**
- **Path traversal prevention**
- **Input validation checks**

### Sensitive Data Protection
- Excluded configuration files that might contain secrets
- Certificate and key files excluded
- Environment files excluded from analysis

## 🔍 Language-Specific Configuration

### Flutter/Dart Rules
- Prefer const constructors
- Avoid print statements in production
- Use relative imports
- Prefer single quotes
- Avoid unnecessary containers

### TypeScript/Node.js Rules
- Explicit function return types
- No unused variables
- Prefer const assertions
- Security headers enforcement
- Rate limiting validation

## 📈 Monitoring & Reports

### Available Reports
- **Code Coverage**: Lines, branches, and functions covered
- **Technical Debt**: Time estimated to fix all issues
- **Security Hotspots**: Potential security issues requiring review
- **Duplication**: Code duplication percentage
- **Complexity**: Cyclomatic complexity metrics

### Dashboard URLs
- **SonarCloud Project**: `https://sonarcloud.io/project/overview?id=afo-chat-application`
- **Backend Project**: `https://sonarcloud.io/project/overview?id=afo-chat-backend`

## 🚨 Troubleshooting

### Common Issues

1. **Analysis Fails with "No sources found"**
   - Check `sonar.sources` path in configuration
   - Ensure paths are relative to project root

2. **Coverage Reports Not Found**
   - Run tests with coverage before analysis
   - Verify `sonar.dart.coverage.reportPaths` path

3. **VS Code SonarLint Not Working**
   - Check Connected Mode configuration
   - Verify internet connection for SonarCloud

4. **GitHub Actions Failing**
   - Verify `SONAR_TOKEN` secret is set
   - Check workflow file syntax

### Support Resources
- **SonarQube Documentation**: [docs.sonarqube.org](https://docs.sonarqube.org)
- **Flutter Analysis**: [dart.dev/guides/language/analysis-options](https://dart.dev/guides/language/analysis-options)
- **SonarLint VS Code**: [marketplace.visualstudio.com](https://marketplace.visualstudio.com/items?itemName=SonarSource.sonarlint-vscode)

## 📝 Next Steps

1. **✅ Complete**: Set up SonarQube Cloud account and import project
2. **✅ Complete**: Configure GitHub repository secrets
3. **🔄 Pending**: Connect VS Code SonarLint to your SonarCloud organization
4. **🔄 Pending**: Run first analysis and review quality gate results
5. **🔄 Pending**: Address any critical/major issues found
6. **🔄 Pending**: Set up quality gate notifications for team

## 🎯 Expected Outcomes

After complete setup, you'll have:
- **Real-time code quality feedback** in VS Code
- **Automated quality checks** on every commit
- **Pull request quality gates** preventing low-quality merges
- **Comprehensive security scanning** for vulnerabilities
- **Technical debt tracking** and improvement metrics
- **Code coverage visibility** across frontend and backend

---

*This configuration provides enterprise-grade code quality analysis for the AFO Chat Application, ensuring maintainable, secure, and reliable software.*