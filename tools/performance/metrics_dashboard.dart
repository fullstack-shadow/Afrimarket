// tools/performance/metrics_dashboard.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'package:console_menu/console_menu.dart';
import 'package:http/http.dart' as http;
import 'package:pluto_grid/pluto_grid.dart';
import 'package:pluto_grid_export/pluto_grid_export.dart' as export;
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:logging/logging.dart';

/// Real-time performance metrics dashboard with visualization capabilities
/// Usage: dart tools/performance/metrics_dashboard.dart [--live] [--export=format] [--duration=seconds]
void main(List<String> arguments) async {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  final logger = Logger('MetricsDashboard');
  final argParser = ArgParser()
    ..addFlag('live', abbr: 'l', help: 'Enable live monitoring mode')
    ..addOption('export', abbr: 'e', help: 'Export format (csv, excel, json)')
    ..addOption('duration', abbr: 'd', help: 'Monitoring duration in seconds', defaultsTo: '30')
    ..addOption('server', abbr: 's', help: 'Send metrics to server endpoint');
  
  try {
    final args = argParser.parse(arguments);
    final dashboard = MetricsDashboard(
      liveMode: args['live'],
      exportFormat: args['export'],
      duration: int.parse(args['duration']),
      serverEndpoint: args['server'],
    );
    
    await dashboard.start();
  } catch (e) {
    logger.severe('Dashboard failed: $e');
    exit(1);
  }
}

class MetricsDashboard {
  final bool liveMode;
  final String? exportFormat;
  final int duration;
  final String? serverEndpoint;
  final Logger _logger = Logger('MetricsDashboard');
  final List<PerformanceMetric> _metrics = [];
  Timer? _collectionTimer;
  Timer? _displayTimer;
  final Random _random = Random();
  
  static const _collectionInterval = Duration(seconds: 1);
  static const _displayInterval = Duration(milliseconds: 500);
  
  MetricsDashboard({
    required this.liveMode,
    required this.exportFormat,
    required this.duration,
    this.serverEndpoint,
  });
  
  Future<void> start() async {
    _logger.info('Starting performance dashboard...');
    _logger.info('Mode: ${liveMode ? 'LIVE' : 'SNAPSHOT'} | Duration: ${duration}s');
    
    if (liveMode) {
      _startLiveMonitoring();
    } else {
      await _collectMetrics();
      _displayReport();
      await _exportData();
      await _sendToServer();
    }
  }
  
  void _startLiveMonitoring() {
    // Setup periodic collection
    _collectionTimer = Timer.periodic(_collectionInterval, (timer) {
      _collectSingleMetric();
    });
    
    // Setup periodic display
    _displayTimer = Timer.periodic(_displayInterval, (timer) {
      _displayLiveDashboard();
    });
    
    // Schedule shutdown
    Timer(Duration(seconds: duration), () {
      _collectionTimer?.cancel();
      _displayTimer?.cancel();
      _logger.info('Live monitoring completed');
      _displayReport();
      _exportData();
      _sendToServer();
      exit(0);
    });
  }
  
  void _collectSingleMetric() {
    final metric = PerformanceMetric(
      timestamp: DateTime.now(),
      memoryUsage: _getCurrentMemory(),
      cpuUsage: _getCurrentCpu(),
      frameRate: _getCurrentFps(),
      networkLatency: _getNetworkLatency(),
    );
    
    _metrics.add(metric);
    
    if (serverEndpoint != null) {
      _sendMetricToServer(metric);
    }
  }
  
  Future<void> _collectMetrics() async {
    _logger.info('Collecting metrics for $duration seconds...');
    for (int i = 0; i < duration; i++) {
      _collectSingleMetric();
      await Future.delayed(Duration(seconds: 1));
    }
  }
  
  void _displayLiveDashboard() {
    // Clear console
    print('\x1B[2J\x1B[0;0H');
    
    if (_metrics.isEmpty) return;
    
    final current = _metrics.last;
    final avgFps = _metrics.map((m) => m.frameRate).reduce((a, b) => a + b) / _metrics.length;
    final maxMemory = _metrics.map((m) => m.memoryUsage).reduce(max);
    
    // Display live metrics
    print('''
╔══════════════════════════════════════════╗
║       PERFORMANCE DASHBOARD (LIVE)       ║
╠══════════════════════════════════════════╣
║ Frame Rate: ${current.frameRate.toStringAsFixed(1).padLeft(5)} FPS  (Avg: ${avgFps.toStringAsFixed(1).padLeft(5)}) ║
║ Memory    : ${(current.memoryUsage / 1024).toStringAsFixed(1).padLeft(5)} MB  (Peak: ${(maxMemory / 1024).toStringAsFixed(1).padLeft(5)}) ║
║ CPU Usage : ${current.cpuUsage.toStringAsFixed(1).padLeft(5)}%    Network: ${current.networkLatency.toStringAsFixed(1).padLeft(5)}ms ║
╚══════════════════════════════════════════╝
''');
    
    // Simple sparkline for frame rate
    final sparkline = _generateSparkline(_metrics.map((m) => m.frameRate).toList());
    print('Frame Rate Trend: $sparkline');
  }
  
  void _displayReport() {
    if (_metrics.isEmpty) return;
    
    final menu = ConsoleMenu(
      title: 'PERFORMANCE REPORT',
      items: [
        'View Summary',
        'Show Charts',
        'Export Data',
        if (serverEndpoint != null) 'Send to Server',
        'Exit'
      ],
    );
    
    menu.display();
    final choice = menu.getChoice();
    
    switch (choice.index) {
      case 0:
        _displaySummary();
        break;
      case 1:
        _displayCharts();
        break;
      case 2:
        _exportData();
        break;
      case 3:
        _sendToServer();
        break;
      default:
        exit(0);
    }
  }
  
  void _displaySummary() {
    final table = PlutoGrid(
      columns: [
        PlutoColumn(title: 'Metric', field: 'metric', type: PlutoColumnType.text()),
        PlutoColumn(title: 'Min', field: 'min', type: PlutoColumnType.number()),
        PlutoColumn(title: 'Avg', field: 'avg', type: PlutoColumnType.number()),
        PlutoColumn(title: 'Max', field: 'max', type: PlutoColumnType.number()),
      ],
      rows: [
        PlutoRow(cells: {
          'metric': PlutoCell(value: 'Frame Rate (FPS)'),
          'min': PlutoCell(value: _metrics.map((m) => m.frameRate).reduce(min)),
          'avg': PlutoCell(value: _metrics.map((m) => m.frameRate).reduce((a, b) => a + b) / _metrics.length),
          'max': PlutoCell(value: _metrics.map((m) => m.frameRate).reduce(max)),
        }),
        PlutoRow(cells: {
          'metric': PlutoCell(value: 'Memory (MB)'),
          'min': PlutoCell(value: _metrics.map((m) => m.memoryUsage / 1024).reduce(min)),
          'avg': PlutoCell(value: _metrics.map((m) => m.memoryUsage / 1024).reduce((a, b) => a + b) / _metrics.length),
          'max': PlutoCell(value: _metrics.map((m) => m.memoryUsage / 1024).reduce(max)),
        }),
        PlutoRow(cells: {
          'metric': PlutoCell(value: 'CPU (%)'),
          'min': PlutoCell(value: _metrics.map((m) => m.cpuUsage).reduce(min)),
          'avg': PlutoCell(value: _metrics.map((m) => m.cpuUsage).reduce((a, b) => a + b) / _metrics.length),
          'max': PlutoCell(value: _metrics.map((m) => m.cpuUsage).reduce(max)),
        }),
        PlutoRow(cells: {
          'metric': PlutoCell(value: 'Network (ms)'),
          'min': PlutoCell(value: _metrics.map((m) => m.networkLatency).reduce(min)),
          'avg': PlutoCell(value: _metrics.map((m) => m.networkLatency).reduce((a, b) => a + b) / _metrics.length),
          'max': PlutoCell(value: _metrics.map((m) => m.networkLatency).reduce(max)),
        }),
      ],
    );
    
    print('Performance Summary:');
    print(table);
  }
  
  void _displayCharts() {
    _logger.info('Generating performance charts...');
    
    // Frame rate chart
    final frameRateSeries = charts.Series<PerformanceMetric, DateTime>(
      id: 'FrameRate',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (metric, _) => metric.timestamp,
      measureFn: (metric, _) => metric.frameRate,
      data: _metrics,
    );
    
    // Memory usage chart
    final memorySeries = charts.Series<PerformanceMetric, DateTime>(
      id: 'Memory',
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      domainFn: (metric, _) => metric.timestamp,
      measureFn: (metric, _) => metric.memoryUsage / 1024,
      data: _metrics,
    );
    
    // TODO: Render charts using charts_flutter
    // This would require a Flutter app context for full rendering
    // For CLI, we'll show a simplified version
    
    print('\nFrame Rate Trend:');
    final fpsValues = _metrics.map((m) => m.frameRate.toInt()).toList();
    print(_generateSparkline(fpsValues));
    
    print('\nMemory Usage Trend:');
    final memValues = _metrics.map((m) => (m.memoryUsage / 1024).toInt()).toList();
    print(_generateSparkline(memValues));
  }
  
  Future<void> _exportData() async {
    if (exportFormat == null) return;
    
    _logger.info('Exporting metrics in $exportFormat format...');
    
    switch (exportFormat) {
      case 'csv':
        await _exportToCsv();
        break;
      case 'excel':
        await _exportToExcel();
        break;
      case 'json':
        await _exportToJson();
        break;
      default:
        _logger.warning('Unsupported export format: $exportFormat');
    }
  }
  
  Future<void> _exportToCsv() async {
    final file = File('performance_metrics.csv');
    final csv = export.PlutoGridExport.exportCSV(
      columns: [
        PlutoColumn(title: 'Timestamp', field: 'timestamp'),
        PlutoColumn(title: 'FrameRate', field: 'frameRate'),
        PlutoColumn(title: 'MemoryUsage', field: 'memoryUsage'),
        PlutoColumn(title: 'CpuUsage', field: 'cpuUsage'),
        PlutoColumn(title: 'NetworkLatency', field: 'networkLatency'),
      ],
      rows: _metrics.map((metric) => PlutoRow(
        cells: {
          'timestamp': PlutoCell(value: metric.timestamp.toIso8601String()),
          'frameRate': PlutoCell(value: metric.frameRate),
          'memoryUsage': PlutoCell(value: metric.memoryUsage),
          'cpuUsage': PlutoCell(value: metric.cpuUsage),
          'networkLatency': PlutoCell(value: metric.networkLatency),
        },
      )).toList(),
    );
    
    await file.writeAsString(csv);
    _logger.info('CSV report saved to ${file.path}');
  }
  
  Future<void> _exportToExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets.add('Performance');
    
    // Add headers
    sheet.getRangeByIndex(1, 1).setText('Timestamp');
    sheet.getRangeByIndex(1, 2).setText('Frame Rate (FPS)');
    sheet.getRangeByIndex(1, 3).setText('Memory (KB)');
    sheet.getRangeByIndex(1, 4).setText('CPU (%)');
    sheet.getRangeByIndex(1, 5).setText('Network (ms)');
    
    // Add data
    for (int i = 0; i < _metrics.length; i++) {
      final metric = _metrics[i];
      sheet.getRangeByIndex(i + 2, 1).setText(metric.timestamp.toIso8601String());
      sheet.getRangeByIndex(i + 2, 2).setNumber(metric.frameRate);
      sheet.getRangeByIndex(i + 2, 3).setNumber(metric.memoryUsage);
      sheet.getRangeByIndex(i + 2, 4).setNumber(metric.cpuUsage);
      sheet.getRangeByIndex(i + 2, 5).setNumber(metric.networkLatency);
    }
    
    // Save file
    final file = File('performance_metrics.xlsx');
    final bytes = workbook.saveAsStream();
    await file.writeAsBytes(bytes);
    workbook.dispose();
    
    _logger.info('Excel report saved to ${file.path}');
  }
  
  Future<void> _exportToJson() async {
    final file = File('performance_metrics.json');
    final jsonData = {
      'metrics': _metrics.map((m) => m.toJson()).toList(),
      'summary': {
        'duration': duration,
        'averageFrameRate': _metrics.map((m) => m.frameRate).average,
        'peakMemory': _metrics.map((m) => m.memoryUsage).max,
      }
    };
    
    await file.writeAsString(json.encode(jsonData));
    _logger.info('JSON report saved to ${file.path}');
  }
  
  Future<void> _sendToServer() async {
    if (serverEndpoint == null) return;
    
    _logger.info('Sending metrics to $serverEndpoint...');
    try {
      final response = await http.post(
        Uri.parse(serverEndpoint!),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'metrics': _metrics.map((m) => m.toJson()).toList(),
          'app': 'SocialCommerceApp',
          'platform': Platform.operatingSystem,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      if (response.statusCode == 200) {
        _logger.info('Metrics successfully sent to server');
      } else {
        _logger.warning('Server responded with ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Failed to send metrics: $e');
    }
  }
  
  Future<void> _sendMetricToServer(PerformanceMetric metric) async {
    if (serverEndpoint == null) return;
    
    try {
      await http.post(
        Uri.parse(serverEndpoint!),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(metric.toJson()),
      );
    } catch (e) {
      _logger.warning('Failed to send real-time metric: $e');
    }
  }
  
  // Simplified metric collection - in real apps use actual measurement APIs
  double _getCurrentMemory() => 100000 + _random.nextDouble() * 50000; // 100-150 MB
  double _getCurrentCpu() => 10 + _random.nextDouble() * 40; // 10-50%
  double _getCurrentFps() => 50 + _random.nextDouble() * 10; // 50-60 FPS
  double _getNetworkLatency() => 50 + _random.nextDouble() * 100; // 50-150ms
  
  String _generateSparkline(List<num> values) {
    const bars = '▁▂▃▄▅▆▇';
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final range = maxVal - minVal;
    
    return values.map((v) {
      if (range == 0) return bars[0];
      final index = ((v - minVal) / range * (bars.length - 1)).round();
      return bars[index];
    }).join();
  }
}

class PerformanceMetric {
  final DateTime timestamp;
  final double frameRate;
  final double memoryUsage; // in KB
  final double cpuUsage; // percentage
  final double networkLatency; // milliseconds
  
  PerformanceMetric({
    required this.timestamp,
    required this.frameRate,
    required this.memoryUsage,
    required this.cpuUsage,
    required this.networkLatency,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'frameRate': frameRate,
    'memoryUsage': memoryUsage,
    'cpuUsage': cpuUsage,
    'networkLatency': networkLatency,
  };
}

extension on List<num> {
  double get average => isEmpty ? 0 : reduce((a, b) => a + b) / length;
  double get max => isEmpty ? 0 : reduce((a, b) => a > b ? a : b);
}