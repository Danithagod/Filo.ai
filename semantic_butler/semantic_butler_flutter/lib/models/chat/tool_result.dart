/// Result from a tool execution
class ToolResult {
  final String tool;
  final String result;
  final bool success;
  final DateTime timestamp;

  ToolResult({
    required this.tool,
    required this.result,
    this.success = true,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'tool': tool,
      'result': result,
      'success': success,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ToolResult.fromJson(Map<String, dynamic> json) {
    return ToolResult(
      tool: json['tool'],
      result: json['result'],
      success: _parseBool(json['success'], defaultValue: true),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// Helper to safely parse boolean values from JSON that might be stored as
  /// double (0.0/1.0), int (0/1), or bool.
  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true';
    return defaultValue;
  }
}
