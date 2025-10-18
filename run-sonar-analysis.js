const scanner = require('sonarqube-scanner').default;

scanner(
  {
    serverUrl: 'https://sonarcloud.io',
    token: process.env.SONAR_TOKEN || 'demo-token-for-local-analysis',
    options: {
      'sonar.projectKey': 'afo-chat-application',
      'sonar.projectName': 'AFO Chat Application',
      'sonar.projectVersion': '1.0.0',
      'sonar.organization': 'getinetaga',
      'sonar.sources': 'lib',
      'sonar.tests': 'test',
      'sonar.sourceEncoding': 'UTF-8',
      'sonar.exclusions': [
        '**/*.generated.dart',
        '**/*.freezed.dart', 
        '**/*.g.dart',
        '**/*.mocks.dart',
        '**/build/**',
        '**/coverage/**',
        '**/.dart_tool/**',
        '**/flutter_assets/**',
        '**/android/**',
        '**/ios/**',
        '**/windows/**',
        '**/linux/**',
        '**/macos/**',
        '**/web/flutter_service_worker.js',
        '**/web/main.dart.js'
      ].join(','),
      'sonar.test.exclusions': [
        '**/*.test.dart',
        '**/test/**',
        '**/*test.dart',
        '**/*_test.dart'
      ].join(','),
      'sonar.coverage.exclusions': [
        '**/*.generated.dart',
        '**/*.freezed.dart',
        '**/*.g.dart', 
        '**/*.mocks.dart',
        '**/main.dart',
        'lib/models/**',
        'lib/constants/**'
      ].join(','),
      'sonar.verbose': false,
      'sonar.analysis.mode': 'publish'
    }
  },
  () => {
    console.log('✅ SonarQube analysis completed successfully!');
    process.exit(0);
  }
);