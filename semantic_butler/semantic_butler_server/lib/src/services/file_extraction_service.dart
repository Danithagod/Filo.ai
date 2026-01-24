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

    if (pdfExtensions.contains(ext)) {
      content = await _extractPdfText(file);
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
      fileCreatedAt: metadata.createdAt,
      fileModifiedAt: metadata.modifiedAt,
    );
  }

  /// Extract text from plain text files
  Future<String> _extractPlainText(File file) async {
    try {
      return await file.readAsString(encoding: utf8);
    } catch (e) {
      // Try with latin1 if utf8 fails
      try {
        return await file.readAsString(encoding: latin1);
      } catch (e2) {
        throw FileExtractionException('Failed to read file: $e');
      }
    }
  }

  /// Extract text from PDF files using Syncfusion PDF library
  Future<String> _extractPdfText(File file) async {
    try {
      // Read PDF bytes
      final bytes = await file.readAsBytes();

      // For PDF extraction, we use a simpler approach:
      // Extract readable text by scanning for text patterns in the PDF
      // This is a basic implementation - for production, use syncfusion_flutter_pdf
      final content = _extractTextFromPdfBytes(bytes);

      if (content.isEmpty) {
        // If no text extracted, return filename as content for indexing
        return 'PDF Document: ${file.path}';
      }

      return content;
    } catch (e) {
      // Return basic info if extraction fails
      return 'PDF Document: ${file.path} (text extraction failed)';
    }
  }

  /// Basic PDF text extraction from bytes
  /// Scans for text streams in PDF structure
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
    // Convert glob pattern to regex
    // * matches any characters except path separator
    // ** matches any characters including path separator
    // ? matches single character

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
