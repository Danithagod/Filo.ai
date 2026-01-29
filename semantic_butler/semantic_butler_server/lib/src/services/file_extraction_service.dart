import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Document categories for classification
enum DocumentCategory {
  code,
  document,
  config,
  data,
  mediaMetadata,
}

/// Service for extracting text content from various file formats
class FileExtractionService {
  /// Supported file extensions for text extraction
  static const Set<String> supportedExtensions = {
    // Documents
    '.txt', '.md', '.markdown', '.rtf',
    // Code files
    '.dart', '.js', '.ts', '.jsx', '.tsx', '.py', '.java', '.kt', '.swift',
    '.go', '.rs', '.cpp', '.c', '.h', '.hpp', '.cs', '.rb', '.php',
    '.html', '.css', '.scss', '.sass', '.less', '.json', '.yaml', '.yml',
    '.xml', '.sql', '.sh', '.bash', '.zsh', '.ps1', '.bat', '.cmd',
    // Config files
    '.env', '.gitignore', '.dockerignore', '.editorconfig',
    '.toml', '.ini', '.cfg', '.conf',
  };

  /// PDF extensions (require special handling)
  static const Set<String> pdfExtensions = {'.pdf'};

  /// Media file extensions (images, videos, audio) - metadata only indexing
  static const Set<String> _mediaExtensions = {
    // Images
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp', '.svg', '.ico',
    '.heic', '.heif', '.raw', '.cr2', '.nef', '.arw',
    // Videos
    '.mp4',
    '.avi',
    '.mov',
    '.mkv',
    '.wmv',
    '.flv',
    '.webm',
    '.m4v',
    '.mpg',
    '.mpeg',
    '.3gp', '.ogv', '.ts', '.m2ts',
    // Audio
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.wma',
    '.m4a',
    '.opus',
    '.aiff',
    '.aif',
    '.amr', '.ac3',
  };

  /// Archive and binary file extensions
  static const Set<String> _archiveExtensions = {
    '.zip',
    '.tar',
    '.gz',
    '.rar',
    '.7z',
    '.xz',
    '.bz2',
    '.tar.gz',
    '.tgz',
    '.exe',
    '.dll',
    '.so',
    '.dylib',
    '.app',
    '.dmg',
    '.iso',
    '.img',
  };

  /// Code file extensions
  static const Set<String> _codeExtensions = {
    '.dart',
    '.js',
    '.ts',
    '.jsx',
    '.tsx',
    '.py',
    '.java',
    '.kt',
    '.swift',
    '.go',
    '.rs',
    '.cpp',
    '.c',
    '.h',
    '.hpp',
    '.cs',
    '.rb',
    '.php',
    '.sql',
    '.sh',
    '.bash',
    '.zsh',
    '.ps1',
    '.bat',
    '.cmd',
    '.html',
    '.css',
    '.scss',
    '.sass',
    '.less',
  };

  /// Config file extensions
  static const Set<String> _configExtensions = {
    '.env',
    '.gitignore',
    '.dockerignore',
    '.editorconfig',
    '.toml',
    '.ini',
    '.cfg',
    '.conf',
    '.yaml',
    '.yml',
  };

  /// Data file extensions
  static const Set<String> _dataExtensions = {
    '.json',
    '.xml',
    '.csv',
  };

  /// Check if a file extension is supported for text extraction
  static bool isSupported(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(ext) || pdfExtensions.contains(ext);
  }

  /// Check if a file can have its text content extracted
  static bool canExtractText(String filePath) {
    return isSupported(filePath);
  }

  /// Get document category based on file extension
  static DocumentCategory getDocumentCategory(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    final fileName = path.basename(filePath).toLowerCase();

    if (_codeExtensions.contains(ext) || _codeExtensions.contains(fileName)) {
      return DocumentCategory.code;
    } else if (_configExtensions.contains(ext) ||
        _configExtensions.contains(fileName)) {
      return DocumentCategory.config;
    } else if (_dataExtensions.contains(ext) ||
        _dataExtensions.contains(fileName)) {
      return DocumentCategory.data;
    } else if (pdfExtensions.contains(ext) ||
        ext == '.txt' ||
        ext == '.md' ||
        ext == '.markdown' ||
        ext == '.rtf') {
      return DocumentCategory.document;
    } else if (_mediaExtensions.contains(ext)) {
      return DocumentCategory.mediaMetadata;
    } else if (_archiveExtensions.contains(ext)) {
      return DocumentCategory.mediaMetadata;
    }

    return DocumentCategory.document; // Default
  }

  /// Get category string from DocumentCategory enum
  static String getCategoryString(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.code:
        return 'code';
      case DocumentCategory.document:
        return 'document';
      case DocumentCategory.config:
        return 'config';
      case DocumentCategory.data:
        return 'data';
      case DocumentCategory.mediaMetadata:
        return 'media_metadata';
    }
  }

  /// Count words in text
  static int countWords(String text) {
    if (text.trim().isEmpty) return 0;
    // Split on whitespace and filter out empty strings
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  /// Get MIME type for a file
  static String getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();

    final mimeTypes = <String, String>{
      '.txt': 'text/plain',
      '.md': 'text/markdown',
      '.markdown': 'text/markdown',
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.ts': 'application/typescript',
      '.json': 'application/json',
      '.xml': 'application/xml',
      '.yaml': 'application/yaml',
      '.yml': 'application/yaml',
      '.pdf': 'application/pdf',
      '.dart': 'application/dart',
      '.py': 'text/x-python',
      '.java': 'text/x-java',
      '.cpp': 'text/x-c++src',
      '.c': 'text/x-csrc',
      '.go': 'text/x-go',
      '.rs': 'text/x-rust',
      '.rb': 'text/x-ruby',
      '.php': 'text/x-php',
      '.sql': 'application/sql',
      // Images
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.webp': 'image/webp',
      '.svg': 'image/svg+xml',
      // Videos
      '.mp4': 'video/mp4',
      '.avi': 'video/x-msvideo',
      '.mov': 'video/quicktime',
      '.mkv': 'video/x-matroska',
      '.webm': 'video/webm',
      // Audio
      '.mp3': 'audio/mpeg',
      '.wav': 'audio/wav',
      '.ogg': 'audio/ogg',
      '.m4a': 'audio/mp4',
      // Archives
      '.zip': 'application/zip',
      '.tar': 'application/x-tar',
      '.gz': 'application/gzip',
      '.rar': 'application/x-rar-compressed',
      '.7z': 'application/x-7z-compressed',
    };

    return mimeTypes[ext] ?? 'application/octet-stream';
  }

  /// Get file metadata (creation and modification dates)
  Future<FileMetadata> getFileMetadata(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();

    return FileMetadata(
      createdAt: stat.changed, // Windows: creation time, Unix: last change
      modifiedAt: stat.modified,
    );
  }

  /// Extract metadata only for non-text files
  Future<ExtractionResult> extractMetadataOnly(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileExtractionException('File not found: $filePath');
    }

    final fileName = path.basename(filePath);
    final fileSize = await file.length();
    final metadata = await getFileMetadata(filePath);
    final category = getDocumentCategory(filePath);

    // Use filename as preview for searchability
    final preview = '[Media File] $fileName';

    return ExtractionResult(
      content: '',
      preview: preview,
      contentHash: _calculateMetadataHash(fileSize, metadata.modifiedAt),
      fileName: fileName,
      fileSizeBytes: fileSize,
      mimeType: getMimeType(filePath),
      documentCategory: getCategoryString(category),
      wordCount: 0,
      pageCount: null,
      fileCreatedAt: metadata.createdAt,
      fileModifiedAt: metadata.modifiedAt,
    );
  }

  String _calculateMetadataHash(int fileSize, DateTime modifiedAt) {
    final metadataString = '${fileSize}_${modifiedAt.millisecondsSinceEpoch}';
    final bytes = utf8.encode(metadataString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Extract content or metadata depending on file type
  Future<ExtractionResult> extract(String filePath) async {
    if (canExtractText(filePath)) {
      return extractText(filePath);
    } else {
      return extractMetadataOnly(filePath);
    }
  }

  /// Extract text content from a file
  Future<ExtractionResult> extractText(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileExtractionException('File not found: $filePath');
    }

    final ext = path.extension(filePath).toLowerCase();
    final fileName = path.basename(filePath);
    final fileSize = await file.length();

    // Get file metadata
    final metadata = await getFileMetadata(filePath);
    final category = getDocumentCategory(filePath);

    String content;
    int? pageCount;

    if (pdfExtensions.contains(ext)) {
      final pdfData = await _extractPdfWithMetadata(file);
      content = pdfData['content'] as String;
      pageCount = pdfData['pageCount'] as int?;
    } else if (supportedExtensions.contains(ext)) {
      content = await _extractPlainText(file);
    } else {
      throw FileExtractionException('Unsupported file format: $ext');
    }

    // Calculate content hash
    final contentHash = _calculateHash(content);

    // Generate preview (first 500 characters)
    final preview = content.length > 500 ? content.substring(0, 500) : content;

    // Count words
    final wordCount = countWords(content);

    return ExtractionResult(
      content: content,
      preview: preview,
      contentHash: contentHash,
      fileName: fileName,
      fileSizeBytes: fileSize,
      mimeType: getMimeType(filePath),
      documentCategory: getCategoryString(category),
      wordCount: wordCount,
      pageCount: pageCount,
      fileCreatedAt: metadata.createdAt,
      fileModifiedAt: metadata.modifiedAt,
    );
  }

  /// Extract text from plain text files with Unicode support
  Future<String> _extractPlainText(File file) async {
    final bytes = await file.readAsBytes();

    // Try to detect BOM (Byte Order Mark) for encoding detection
    final encoding = _detectEncoding(bytes);

    try {
      return encoding.decode(bytes);
    } catch (e) {
      // Fallback chain: UTF-8 → Latin1 → ASCII with replacement
      try {
        return utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        try {
          return latin1.decode(bytes);
        } catch (_) {
          // Last resort: decode as ASCII, replacing invalid chars
          return String.fromCharCodes(
            bytes.map((b) => b < 128 ? b : 0x3F), // Replace non-ASCII with '?'
          );
        }
      }
    }
  }

  /// Detect encoding from BOM or content analysis
  Encoding _detectEncoding(List<int> bytes) {
    if (bytes.length < 2) return utf8;

    // Check for BOM (Byte Order Mark)
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8; // UTF-8 BOM
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      // UTF-16 LE BOM - decode manually since Dart doesn't have built-in UTF-16
      return utf8; // Will use fallback
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      // UTF-16 BE BOM
      return utf8; // Will use fallback
    }

    // Heuristic: check if content looks like valid UTF-8
    if (_isLikelyUtf8(bytes)) {
      return utf8;
    }

    // Default to Latin1 for legacy files
    return latin1;
  }

  /// Check if bytes look like valid UTF-8
  bool _isLikelyUtf8(List<int> bytes) {
    int i = 0;
    int invalidCount = 0;
    final sampleSize = bytes.length > 1000 ? 1000 : bytes.length;

    while (i < sampleSize) {
      final b = bytes[i];
      if (b < 0x80) {
        // ASCII
        i++;
      } else if ((b & 0xE0) == 0xC0) {
        // 2-byte sequence
        if (i + 1 >= bytes.length || (bytes[i + 1] & 0xC0) != 0x80) {
          invalidCount++;
        }
        i += 2;
      } else if ((b & 0xF0) == 0xE0) {
        // 3-byte sequence
        if (i + 2 >= bytes.length ||
            (bytes[i + 1] & 0xC0) != 0x80 ||
            (bytes[i + 2] & 0xC0) != 0x80) {
          invalidCount++;
        }
        i += 3;
      } else if ((b & 0xF8) == 0xF0) {
        // 4-byte sequence
        if (i + 3 >= bytes.length ||
            (bytes[i + 1] & 0xC0) != 0x80 ||
            (bytes[i + 2] & 0xC0) != 0x80 ||
            (bytes[i + 3] & 0xC0) != 0x80) {
          invalidCount++;
        }
        i += 4;
      } else {
        // Invalid UTF-8 start byte
        invalidCount++;
        i++;
      }
    }

    // If less than 5% invalid sequences, assume UTF-8
    return invalidCount < (sampleSize * 0.05);
  }

  /// Extract text and metadata from PDF files
  Future<Map<String, dynamic>> _extractPdfWithMetadata(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final content = _extractTextFromPdfBytes(bytes);

      // Basic page count heuristic: count "/Type /Page" or "/Type/Page"
      final pdfSource = String.fromCharCodes(bytes);
      final pageCountMatch = RegExp(
        r'/Type\s*/Page\b',
      ).allMatches(pdfSource).length;

      return {
        'content': content,
        'pageCount': pageCountMatch > 0 ? pageCountMatch : null,
      };
    } catch (e) {
      return {
        'content': 'PDF Document: ${file.path} (extraction failed)',
        'pageCount': null,
      };
    }
  }

  /// Basic PDF text extraction from bytes
  String _extractTextFromPdfBytes(List<int> bytes) {
    try {
      final content = String.fromCharCodes(bytes, 0, bytes.length);
      final textBuffer = StringBuffer();

      // Look for text between BT (begin text) and ET (end text) markers
      final btPattern = RegExp(r'\(([^)]+)\)');
      final matches = btPattern.allMatches(content);

      for (final match in matches) {
        final text = match.group(1);
        if (text != null && text.length > 2) {
          // Filter out non-printable or binary-looking content
          final cleaned = text.replaceAll(RegExp(r'[^\x20-\x7E\s]'), '');
          if (cleaned.length > 2) {
            textBuffer.write(cleaned);
            textBuffer.write(' ');
          }
        }
      }

      return textBuffer.toString().trim();
    } catch (e) {
      return '';
    }
  }

  /// Calculate SHA-256 hash of content
  String _calculateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if a path matches any of the ignore patterns
  static bool matchesIgnorePattern(
    String filePath,
    List<String> ignorePatterns,
  ) {
    if (ignorePatterns.isEmpty) return false;

    for (final pattern in ignorePatterns) {
      // Simple glob matching
      if (_matchesGlob(filePath, pattern)) {
        return true;
      }
    }
    return false;
  }

  /// Simple glob pattern matching
  static bool _matchesGlob(String filePath, String pattern) {
    // Normalize path separators
    final normalizedPath = filePath.replaceAll('\\', '/').toLowerCase();
    final normalizedPattern = pattern.replaceAll('\\', '/').toLowerCase();

    // Handle directory patterns (ending with /)
    if (normalizedPattern.endsWith('/')) {
      final dirPattern = normalizedPattern.substring(
        0,
        normalizedPattern.length - 1,
      );
      return normalizedPath.contains('/$dirPattern/') ||
          normalizedPath.startsWith('$dirPattern/');
    }

    // Handle ** for directory matching
    if (normalizedPattern.contains('**')) {
      final parts = normalizedPattern.split('**');
      if (parts.length == 2) {
        final prefix = parts[0];
        final suffix = parts[1];
        if (prefix.isEmpty) {
          return normalizedPath.endsWith(suffix) ||
              normalizedPath.contains(suffix);
        }
        return normalizedPath.startsWith(prefix) &&
            normalizedPath.endsWith(suffix);
      }
    }

    // Handle simple wildcard patterns like *.log
    if (normalizedPattern.startsWith('*.')) {
      final ext = normalizedPattern.substring(1); // .log
      return normalizedPath.endsWith(ext);
    }

    // Handle exact path match
    return normalizedPath.endsWith(normalizedPattern) ||
        normalizedPath.contains('/$normalizedPattern');
  }

  /// Scan a directory for indexable files
  Future<List<String>> scanDirectory(
    String directoryPath, {
    bool recursive = true,
    List<String> ignorePatterns = const [],
  }) async {
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      throw FileExtractionException('Directory not found: $directoryPath');
    }

    final files = <String>[];

    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is File) {
        // Check ignore patterns first
        if (matchesIgnorePattern(entity.path, ignorePatterns)) {
          continue;
        }

        // Include all files that aren't ignored
        files.add(entity.path);
      }
    }

    return files;
  }
}

/// File metadata from filesystem
class FileMetadata {
  final DateTime createdAt;
  final DateTime modifiedAt;

  FileMetadata({
    required this.createdAt,
    required this.modifiedAt,
  });
}

/// Result of text extraction from a file
class ExtractionResult {
  final String content;
  final String preview;
  final String contentHash;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String documentCategory;
  final int wordCount;
  final int? pageCount;
  final DateTime fileCreatedAt;
  final DateTime fileModifiedAt;

  ExtractionResult({
    required this.content,
    required this.preview,
    required this.contentHash,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.documentCategory,
    required this.wordCount,
    this.pageCount,
    required this.fileCreatedAt,
    required this.fileModifiedAt,
  });
}

/// Exception thrown when file extraction fails
class FileExtractionException implements Exception {
  final String message;
  FileExtractionException(this.message);

  @override
  String toString() => 'FileExtractionException: $message';
}
