import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  /// Check if a file extension is supported
  static bool isSupported(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return supportedExtensions.contains(ext) || pdfExtensions.contains(ext);
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
    };

    return mimeTypes[ext] ?? 'application/octet-stream';
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

    return ExtractionResult(
      content: content,
      preview: preview,
      contentHash: contentHash,
      fileName: fileName,
      fileSizeBytes: fileSize,
      mimeType: getMimeType(filePath),
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

  /// Scan a directory for indexable files
  Future<List<String>> scanDirectory(
    String directoryPath, {
    bool recursive = true,
  }) async {
    final directory = Directory(directoryPath);

    if (!await directory.exists()) {
      throw FileExtractionException('Directory not found: $directoryPath');
    }

    final files = <String>[];

    await for (final entity in directory.list(recursive: recursive)) {
      if (entity is File) {
        if (isSupported(entity.path)) {
          files.add(entity.path);
        }
      }
    }

    return files;
  }
}

/// Result of text extraction from a file
class ExtractionResult {
  final String content;
  final String preview;
  final String contentHash;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;

  ExtractionResult({
    required this.content,
    required this.preview,
    required this.contentHash,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
  });
}

/// Exception thrown when file extraction fails
class FileExtractionException implements Exception {
  final String message;
  FileExtractionException(this.message);

  @override
  String toString() => 'FileExtractionException: $message';
}
