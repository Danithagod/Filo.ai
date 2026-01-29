/// Tool result size limiter for security
/// 
/// Prevents memory exhaustion and DoS attacks by limiting
/// the size of tool outputs.
class ToolResultLimiter {
  /// Maximum size for string results (1MB)
  static const int maxResultSize = 1024 * 1024;
  
  /// Maximum number of items in list results
  static const int maxResultCount = 1000;
  
  /// Maximum size for file content (500KB)
  static const int maxFileContentSize = 512 * 1024;
  
  /// Maximum number of search results
  static const int maxSearchResults = 500;

  /// Limit string output size
  static String limitString(String input, {int? maxSize}) {
    final limit = maxSize ?? maxResultSize;
    if (input.length > limit) {
      return input.substring(0, limit) + '\n[TRUNCATED - exceeded $limit characters]';
    }
    return input;
  }

  /// Limit list size
  static List<T> limitList<T>(List<T> input, {int? maxCount}) {
    final limit = maxCount ?? maxResultCount;
    if (input.length > limit) {
      return input.take(limit).toList();
    }
    return input;
  }

  /// Limit file content size
  static String limitFileContent(String content) {
    return limitString(content, maxSize: maxFileContentSize);
  }

  /// Limit search results
  static List<T> limitSearchResults<T>(List<T> results) {
    return limitList(results, maxCount: maxSearchResults);
  }

  /// Check if string exceeds limit
  static bool exceedsLimit(String input, {int? maxSize}) {
    final limit = maxSize ?? maxResultSize;
    return input.length > limit;
  }

  /// Check if list exceeds limit
  static bool listExceedsLimit<T>(List<T> input, {int? maxCount}) {
    final limit = maxCount ?? maxResultCount;
    return input.length > limit;
  }

  /// Get truncation message
  static String getTruncationMessage(int originalSize, int limit) {
    return '[TRUNCATED: Original size $originalSize, limited to $limit]';
  }
}
