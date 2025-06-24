// tools/compliance/audit_scheduler.dart
import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Automated compliance audit scheduler for security, licensing, and policy checks
/// Usage: dart tools/compliance/audit_scheduler.dart [--daily] [--critical] [--email]
void main(List<String> arguments) async {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  final logger = Logger('ComplianceAudit');
  final argParser = ArgParser()
    ..addFlag('daily', abbr: 'd', help: 'Run daily audit checks')
    ..addFlag('critical', abbr: 'c', help: 'Only run critical checks')
    ..addFlag('email', abbr: 'e', help: 'Send email report')
    ..addOption('config', abbr: 'f', help: 'Config file path', defaultsTo: 'compliance_config.yaml');
  
  try {
    final args = argParser.parse(arguments);
    final config = await _loadConfig(args['config']);
    
    final auditor = ComplianceAuditor(
      dailyMode: args['daily'],
      criticalOnly: args['critical'],
      sendEmail: args['email'],
      config: config,
    );
    
    await auditor.runAudit();
    
    if (auditor.hasCriticalIssues) {
      logger.severe('CRITICAL COMPLIANCE ISSUES FOUND!');
      exit(1);
    }
    
    logger.info('Compliance audit completed successfully');
  } on FileSystemException catch (e) {
    logger.severe('Config file error: ${e.message}');
    exit(2);
  } catch (e) {
    logger.severe('Audit failed: $e');
    exit(3);
  }
}

class ComplianceAuditor {
  final bool dailyMode;
  final bool criticalOnly;
  final bool sendEmail;
  final Map<String, dynamic> config;
  final Logger _logger = Logger('ComplianceAuditor');
  final List<ComplianceIssue> _issues = [];
  final List<ComplianceCheck> _checks = [];
  
  bool get hasCriticalIssues => _issues.any((issue) => issue.level == IssueLevel.critical);
  
  ComplianceAuditor({
    required this.dailyMode,
    required this.criticalOnly,
    required this.sendEmail,
    required this.config,
  }) {
    // Initialize checks based on config
    _initializeChecks();
  }
  
  void _initializeChecks() {
    // Security checks
    _checks.add(SecurityCheck(
      name: 'Dependency Vulnerabilities',
      description: 'Scan for known vulnerabilities in dependencies',
      critical: true,
      command: ['dart', 'pub', 'audit'],
      failurePattern: r'found \d+ vulnerability',
    ));
    
    _checks.add(SecurityCheck(
      name: 'Secrets Exposure',
      description: 'Check for exposed API keys or credentials',
      critical: true,
      command: ['grep', '-r', r'API_KEY|SECRET|PASSWORD', 'lib/'],
      failurePattern: r'.+',
      expectedExitCode: 1, // Grep should find nothing (exit 1)
    ));
    
    // Licensing checks
    _checks.add(LicenseCheck(
      name: 'License Compliance',
      description: 'Verify open-source license compatibility',
      critical: true,
      command: ['dart', 'pub', 'license'],
      allowedLicenses: ['MIT', 'Apache-2.0', 'BSD-3-Clause'],
    ));
    
    // Privacy checks
    _checks.add(PrivacyCheck(
      name: 'PII Handling',
      description: 'Check for proper personal data handling',
      critical: true,
      gdprKeywords: ['email', 'phone', 'address', 'location'],
    ));
    
    // Code quality checks
    if (!criticalOnly) {
      _checks.add(CodeQualityCheck(
        name: 'Code Standards',
        description: 'Verify code style and best practices',
        critical: false,
        command: ['dart', 'analyze'],
        failurePattern: r'found \d+ issue',
      ));
    }
  }
  
  Future<void> runAudit() async {
    _logger.info('Starting compliance audit...');
    final stopwatch = Stopwatch()..start();
    
    // Run all registered checks
    for (final check in _checks) {
      if (criticalOnly && !check.critical) continue;
      
      _logger.info('Running ${check.name}...');
      final issues = await check.execute();
      _issues.addAll(issues);
    }
    
    // Generate report
    final report = await _generateReport();
    
    // Send notifications
    if (sendEmail) {
      await _sendEmailReport(report);
    }
    
    if (dailyMode) {
      await _archiveReport(report);
    }
    
    _logger.info('Audit completed in ${stopwatch.elapsed}');
    _logSummary();
    
    if (hasCriticalIssues) {
      _logger.severe('CRITICAL ISSUES FOUND!');
    }
  }
  
  Future<String> _generateReport() async {
    _logger.info('Generating compliance report...');
    final buffer = StringBuffer()
      ..writeln('Compliance Audit Report')
      ..writeln('=======================')
      ..writeln('Date: ${DateTime.now().toIso8601String()}')
      ..writeln('Mode: ${dailyMode ? 'Daily' : 'On-demand'}')
      ..writeln('Critical Only: $criticalOnly')
      ..writeln('\nSummary:')
      ..writeln('  Critical Issues: ${_issues.where((i) => i.level == IssueLevel.critical).length}')
      ..writeln('  Warnings: ${_issues.where((i) => i.level == IssueLevel.warning).length}')
      ..writeln('  Informational: ${_issues.where((i) => i.level == IssueLevel.info).length}')
      ..writeln('\nDetails:');
    
    for (final issue in _issues) {
      buffer.writeln('\n[${issue.level.name.toUpperCase()}] ${issue.title}');
      buffer.writeln('Category: ${issue.category}');
      buffer.writeln('Description: ${issue.description}');
      buffer.writeln('Remediation: ${issue.remediation}');
      if (issue.extraInfo != null) {
        buffer.writeln('Additional Info: ${issue.extraInfo}');
      }
    }
    
    return buffer.toString();
  }
  
  Future<void> _sendEmailReport(String report) async {
    _logger.info('Sending email report...');
    try {
      final emailConfig = config['email'] as Map<String, dynamic>;
      final smtpServer = SmtpServer(
        emailConfig['smtp_host'],
        username: emailConfig['username'],
        password: emailConfig['password'],
        port: emailConfig['port'] ?? 587,
      );
      
      final recipients = (emailConfig['recipients'] as List).cast<String>();
      final subject = hasCriticalIssues
          ? '[CRITICAL] Compliance Issues Found'
          : 'Compliance Audit Report';
      
      final message = Message()
        ..from = Address(emailConfig['sender'], 'Compliance Bot')
        ..recipients.addAll(recipients)
        ..subject = subject
        ..text = report;
      
      final sendReport = await send(message, smtpServer);
      _logger.info('Email sent: ${sendReport.toString()}');
    } catch (e) {
      _logger.severe('Failed to send email: $e');
    }
  }
  
  Future<void> _archiveReport(String report) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final file = File('compliance_reports/$dateStr.txt');
    await file.create(recursive: true);
    await file.writeAsString(report);
    _logger.info('Report archived at ${file.path}');
  }
  
  void _logSummary() {
    _logger.info('===== AUDIT SUMMARY =====');
    _logger.info('Critical issues: ${_issues.where((i) => i.level == IssueLevel.critical).length}');
    _logger.info('Warnings: ${_issues.where((i) => i.level == IssueLevel.warning).length}');
    _logger.info('Informational: ${_issues.where((i) => i.level == IssueLevel.info).length}');
    _logger.info('=========================');
  }
}

abstract class ComplianceCheck {
  final String name;
  final String description;
  final bool critical;
  
  ComplianceCheck({
    required this.name,
    required this.description,
    required this.critical,
  });
  
  Future<List<ComplianceIssue>> execute();
}

class SecurityCheck extends ComplianceCheck {
  final List<String> command;
  final String failurePattern;
  final int? expectedExitCode;
  
  SecurityCheck({
    required super.name,
    required super.description,
    required super.critical,
    required this.command,
    required this.failurePattern,
    this.expectedExitCode = 0,
  });
  
  @override
  Future<List<ComplianceIssue>> execute() async {
    final issues = <ComplianceIssue>[];
    final result = await Process.run(command[0], command.sublist(1));
    
    if (result.exitCode != expectedExitCode) {
      issues.add(ComplianceIssue(
        category: 'Security',
        title: name,
        description: description,
        level: critical ? IssueLevel.critical : IssueLevel.warning,
        remediation: 'Review command output: ${command.join(' ')}',
        extraInfo: result.stdout.toString(),
      ));
    }
    
    return issues;
  }
}

class LicenseCheck extends ComplianceCheck {
  final List<String> command;
  final List<String> allowedLicenses;
  
  LicenseCheck({
    required super.name,
    required super.description,
    required super.critical,
    this.command = const ['dart', 'pub', 'license'],
    required this.allowedLicenses,
  });
  
  @override
  Future<List<ComplianceIssue>> execute() async {
    final issues = <ComplianceIssue>[];
    final result = await Process.run(command[0], command.sublist(1));
    final output = result.stdout.toString();
    
    for (final line in output.split('\n')) {
      final match = RegExp(r'(\w+-\d+\.\d+|\w+):').firstMatch(line);
      if (match != null) {
        final license = match.group(1)!;
        if (!allowedLicenses.contains(license)) {
          issues.add(ComplianceIssue(
            category: 'Legal',
            title: 'Restricted License: $license',
            description: 'Package uses $license license: ${line.trim()}',
            level: IssueLevel.critical,
            remediation: 'Replace or review package with $license license',
          ));
        }
      }
    }
    
    return issues;
  }
}

class PrivacyCheck extends ComplianceCheck {
  final List<String> gdprKeywords;
  
  PrivacyCheck({
    required super.name,
    required super.description,
    required super.critical,
    this.gdprKeywords = const ['email', 'phone', 'address'],
  });
  
  @override
  Future<List<ComplianceIssue>> execute() async {
    final issues = <ComplianceIssue>[];
    
    for (final keyword in gdprKeywords) {
      final result = await Process.run('grep', ['-r', keyword, 'lib/']);
      if (result.stdout.toString().isNotEmpty) {
        issues.add(ComplianceIssue(
          category: 'Privacy',
          title: 'Potential PII Exposure: $keyword',
          description: 'Sensitive keyword "$keyword" found in codebase',
          level: IssueLevel.critical,
          remediation: 'Review found instances and ensure proper data handling',
          extraInfo: 'Found in:\n${result.stdout}',
        ));
      }
    }
    
    return issues;
  }
}

class CodeQualityCheck extends ComplianceCheck {
  final List<String> command;
  final String failurePattern;
  
  CodeQualityCheck({
    required super.name,
    required super.description,
    required super.critical,
    required this.command,
    required this.failurePattern,
  });
  
  @override
  Future<List<ComplianceIssue>> execute() async {
    final issues = <ComplianceIssue>[];
    final result = await Process.run(command[0], command.sublist(1));
    
    if (result.exitCode != 0) {
      issues.add(ComplianceIssue(
        category: 'Code Quality',
        title: name,
        description: description,
        level: IssueLevel.warning,
        remediation: 'Address issues found by ${command.join(' ')}',
        extraInfo: result.stdout.toString(),
      ));
    }
    
    return issues;
  }
}

class ComplianceIssue {
  final String category;
  final String title;
  final String description;
  final IssueLevel level;
  final String remediation;
  final String? extraInfo;
  
  ComplianceIssue({
    required this.category,
    required this.title,
    required this.description,
    required this.level,
    required this.remediation,
    this.extraInfo,
  });
}

enum IssueLevel { critical, warning, info }

Future<Map<String, dynamic>> _loadConfig(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    throw FileSystemException('Config file not found', path);
  }
  
  final content = await file.readAsString();
  final yaml = loadYaml(content) as YamlMap;
  
  return {
    'email': {
      'smtp_host': yaml['email']?['smtp_host'] ?? 'smtp.example.com',
      'username': yaml['email']?['username'] ?? 'audit@example.com',
      'password': yaml['email']?['password'] ?? '',
      'port': yaml['email']?['port'] ?? 587,
      'sender': yaml['email']?['sender'] ?? 'noreply@example.com',
      'recipients': (yaml['email']?['recipients'] as YamlList?)?.map((e) => e.toString()).toList() ?? [],
    },
    'allowed_licenses': (yaml['allowed_licenses'] as YamlList?)?.map((e) => e.toString()).toList() ?? 
      ['MIT', 'Apache-2.0', 'BSD-3-Clause'],
    'gdpr_keywords': (yaml['gdpr_keywords'] as YamlList?)?.map((e) => e.toString()).toList() ?? 
      ['email', 'phone', 'address', 'location'],
  };
}