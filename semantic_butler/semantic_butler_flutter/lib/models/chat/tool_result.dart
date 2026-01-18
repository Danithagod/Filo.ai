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
}
