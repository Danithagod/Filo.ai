import 'dart:convert';
import 'dart:io';

/// Utility for detecting and handling text file encodings across platforms
///
/// Supports:
/// - UTF-8 (with and without BOM)
/// - UTF-16 LE/BE (with and without BOM)
/// - UTF-32 LE/BE (with and without BOM)
/// - Latin-1 (ISO-8859-1) fallback
/// - Windows-1252 fallback
/// - ASCII detection
class EncodingDetector {
  EncodingDetector._();

  static final Encoding utf16Le =
      Encoding.getByName('utf-16le') ??
      utf8; // Fallback to utf8 if not found (unlikely)
  static final Encoding utf16Be = Encoding.getByName('utf-16be') ?? utf8;

  /// Maximum bytes to read for encoding detection
  static const int _detectionBytes = 8192;

  /// Detect the encoding of a file from its bytes
  ///
  /// Returns the detected encoding and the offset to start reading from
  /// (to skip BOM if present)
  static EncodingDetection detectEncoding(List<int> bytes) {
    if (bytes.isEmpty) {
      return EncodingDetection(encoding: utf8, bomOffset: 0);
    }

    // Check for BOM markers
    final bomDetection = _detectBom(bytes);
    if (bomDetection != null) {
      return bomDetection;
    }

    // Analyze content to determine encoding
    return _analyzeContent(bytes);
  }

  /// Detect BOM (Byte Order Mark) and return encoding
  static EncodingDetection? _detectBom(List<int> bytes) {
    // UTF-8 BOM: EF BB BF
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return EncodingDetection(encoding: utf8, bomOffset: 3, hasBom: true);
    }

    // UTF-16 LE BOM: FF FE
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      // Check for UTF-32 LE BOM: FF FE 00 00
      if (bytes.length >= 4 && bytes[2] == 0x00 && bytes[3] == 0x00) {
        return EncodingDetection(
          encoding: Encoding.getByName('utf-32le') ?? utf8,
          bomOffset: 4,
          hasBom: true,
        );
      }
      return EncodingDetection(encoding: utf16Le, bomOffset: 2, hasBom: true);
    }

    // UTF-16 BE BOM: FE FF
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      // Check for UTF-32 BE BOM: 00 00 FE FF
      if (bytes.length >= 4 && bytes[2] == 0x00 && bytes[3] == 0xFF) {
        return EncodingDetection(
          encoding: Encoding.getByName('utf-32be') ?? utf8,
          bomOffset: 4,
          hasBom: true,
        );
      }
      return EncodingDetection(encoding: utf16Be, bomOffset: 2, hasBom: true);
    }

    // UTF-32 LE BOM (without matching UTF-16 pattern): FF FE 00 00
    if (bytes.length >= 4 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xFE &&
        bytes[2] == 0x00 &&
        bytes[3] == 0x00) {
      return EncodingDetection(
        encoding: Encoding.getByName('utf-32le') ?? utf8,
        bomOffset: 4,
        hasBom: true,
      );
    }

    // UTF-32 BE BOM (without matching UTF-16 pattern): 00 00 FE FF
    if (bytes.length >= 4 &&
        bytes[0] == 0x00 &&
        bytes[1] == 0x00 &&
        bytes[2] == 0xFE &&
        bytes[3] == 0xFF) {
      return EncodingDetection(
        encoding: Encoding.getByName('utf-32be') ?? utf8,
        bomOffset: 4,
        hasBom: true,
      );
    }

    return null;
  }

  /// Analyze content to determine likely encoding
  static EncodingDetection _analyzeContent(List<int> bytes) {
    final sampleSize = bytes.length < _detectionBytes
        ? bytes.length
        : _detectionBytes;
    final sample = bytes.sublist(0, sampleSize);

    // Check for UTF-16 LE pattern (lots of zeros in even positions)
    if (_looksLikeUtf16Le(sample)) {
      return EncodingDetection(encoding: utf16Le, bomOffset: 0);
    }

    // Check for UTF-16 BE pattern (lots of zeros in odd positions)
    if (_looksLikeUtf16Be(sample)) {
      return EncodingDetection(encoding: utf16Be, bomOffset: 0);
    }

    // Check for ASCII/UTF-8 validity
    final isAscii = _isAscii(sample);
    if (isAscii) {
      return EncodingDetection(encoding: ascii, bomOffset: 0, isAscii: true);
    }

    // Check for valid UTF-8
    if (_isValidUtf8(sample)) {
      return EncodingDetection(encoding: utf8, bomOffset: 0);
    }

    // Check for Windows-1252 / Latin-1 patterns
    // If we have bytes in the 0x80-0x9F range that are valid Windows-1252
    // but not valid UTF-8, it's likely Windows-1252
    if (_looksLikeWindows1252(sample)) {
      return EncodingDetection(
        encoding: Encoding.getByName('windows-1252') ?? latin1,
        bomOffset: 0,
      );
    }

    // Fallback to Latin-1 (which never fails)
    return EncodingDetection(encoding: latin1, bomOffset: 0);
  }

  /// Check if data looks like UTF-16 LE
  static bool _looksLikeUtf16Le(List<int> bytes) {
    if (bytes.length < 4) return false;

    int nullBytesInOddPosition = 0;
    int totalChecked = 0;

    for (int i = 0; i < bytes.length - 1; i += 2) {
      final even = bytes[i];
      final odd = bytes[i + 1];

      // In UTF-16 LE, odd positions (high bytes) should often be 0 for ASCII text
      if (odd == 0 && even != 0) {
        nullBytesInOddPosition++;
      }
      if (odd == 0 && even != 0) {
        nullBytesInOddPosition++;
      }
      totalChecked++;
    }

    // If more than 30% of pairs have the pattern of ASCII in UTF-16 LE
    return (nullBytesInOddPosition / totalChecked) > 0.3;
  }

  /// Check if data looks like UTF-16 BE
  static bool _looksLikeUtf16Be(List<int> bytes) {
    if (bytes.length < 4) return false;

    int nullBytesInEvenPosition = 0;
    int totalChecked = 0;

    for (int i = 0; i < bytes.length - 1; i += 2) {
      final even = bytes[i];
      final odd = bytes[i + 1];

      // In UTF-16 BE, even positions (high bytes) should often be 0 for ASCII text
      if (even == 0 && odd != 0) {
        nullBytesInEvenPosition++;
      }
      totalChecked++;
    }

    // If more than 30% of pairs have the pattern of ASCII in UTF-16 BE
    return (nullBytesInEvenPosition / totalChecked) > 0.3;
  }

  /// Check if data is pure ASCII (all bytes < 128)
  static bool _isAscii(List<int> bytes) {
    for (final byte in bytes) {
      if (byte >= 0x80) return false;
    }
    return true;
  }

  /// Check if data is valid UTF-8
  static bool _isValidUtf8(List<int> bytes) {
    int i = 0;
    while (i < bytes.length) {
      final byte = bytes[i];

      if (byte < 0x80) {
        // Single byte character (ASCII)
        i++;
      } else if ((byte & 0xE0) == 0xC0) {
        // 2-byte sequence
        if (i + 1 >= bytes.length) return false;
        final next = bytes[i + 1];
        if ((next & 0xC0) != 0x80) return false;
        i += 2;
      } else if ((byte & 0xF0) == 0xE0) {
        // 3-byte sequence
        if (i + 2 >= bytes.length) return false;
        final next1 = bytes[i + 1];
        final next2 = bytes[i + 2];
        if ((next1 & 0xC0) != 0x80) return false;
        if ((next2 & 0xC0) != 0x80) return false;
        // Check for overlong encoding
        if (byte == 0xE0 && next1 < 0xA0) return false;
        i += 3;
      } else if ((byte & 0xF8) == 0xF0) {
        // 4-byte sequence
        if (i + 3 >= bytes.length) return false;
        final next1 = bytes[i + 1];
        final next2 = bytes[i + 2];
        final next3 = bytes[i + 3];
        if ((next1 & 0xC0) != 0x80) return false;
        if ((next2 & 0xC0) != 0x80) return false;
        if ((next3 & 0xC0) != 0x80) return false;
        // Check for overlong encoding
        if (byte == 0xF0 && next1 < 0x90) return false;
        i += 4;
      } else {
        return false;
      }
    }
    return true;
  }

  /// Check if data looks like Windows-1252
  /// Windows-1252 uses bytes 0x80-0x9F for special characters
  static bool _looksLikeWindows1252(List<int> bytes) {
    int windows1252Chars = 0;
    int invalidUtf8Sequences = 0;

    int i = 0;
    while (i < bytes.length) {
      final byte = bytes[i];

      if (byte >= 0x80 && byte <= 0x9F) {
        windows1252Chars++;
      }

      // Check for invalid UTF-8 sequences starting with this byte
      if (byte >= 0x80) {
        if ((byte & 0xE0) == 0xC0) {
          if (i + 1 >= bytes.length || (bytes[i + 1] & 0xC0) != 0x80) {
            invalidUtf8Sequences++;
          }
          i += 2;
        } else if ((byte & 0xF0) == 0xE0) {
          if (i + 2 >= bytes.length ||
              (bytes[i + 1] & 0xC0) != 0x80 ||
              (bytes[i + 2] & 0xC0) != 0x80) {
            invalidUtf8Sequences++;
          }
          i += 3;
        } else if ((byte & 0xF8) == 0xF0) {
          if (i + 3 >= bytes.length ||
              (bytes[i + 1] & 0xC0) != 0x80 ||
              (bytes[i + 2] & 0xC0) != 0x80 ||
              (bytes[i + 3] & 0xC0) != 0x80) {
            invalidUtf8Sequences++;
          }
          i += 4;
        } else if (byte < 0x80) {
          i++;
        } else {
          // Invalid UTF-8 start byte
          invalidUtf8Sequences++;
          i++;
        }
      } else {
        i++;
      }
    }

    // If we have Windows-1252 specific characters and invalid UTF-8
    return windows1252Chars > 0 && invalidUtf8Sequences > 0;
  }

  /// Read a file with automatic encoding detection
  ///
  /// Returns the decoded string content. Throws an exception if the file
  /// cannot be read or decoded.
  static String readFile(String path) {
    final file = File(path);
    final bytes = file.readAsBytesSync();

    if (bytes.isEmpty) {
      return '';
    }

    final detection = detectEncoding(bytes);
    final contentBytes = detection.bomOffset > 0
        ? bytes.sublist(detection.bomOffset)
        : bytes;

    try {
      return detection.encoding.decode(contentBytes);
    } catch (e) {
      // Fallback: try Latin-1 which never fails
      return latin1.decode(contentBytes);
    }
  }

  /// Read a file with automatic encoding detection, limiting to N lines
  ///
  /// Returns the decoded string content with at most the specified number
  /// of lines.
  static String readFileLines(String path, {int maxLines = 100}) {
    final file = File(path);

    // Read full file
    final bytes = file.readAsBytesSync();

    if (bytes.isEmpty) {
      return '';
    }

    final detection = detectEncoding(bytes);
    final contentBytes = detection.bomOffset > 0
        ? bytes.sublist(detection.bomOffset)
        : bytes;

    try {
      final content = detection.encoding.decode(contentBytes);
      final lines = content.split(RegExp(r'\r?\n'));
      return lines.take(maxLines).join('\n');
    } catch (e) {
      // Fallback: try Latin-1
      final content = latin1.decode(contentBytes);
      final lines = content.split(RegExp(r'\r?\n'));
      return lines.take(maxLines).join('\n');
    }
  }

  /// Read a file asynchronously with encoding detection
  static Future<String> readFileAsync(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    if (bytes.isEmpty) {
      return '';
    }

    final detection = detectEncoding(bytes);
    final contentBytes = detection.bomOffset > 0
        ? bytes.sublist(detection.bomOffset)
        : bytes;

    try {
      return detection.encoding.decode(contentBytes);
    } catch (e) {
      return latin1.decode(contentBytes);
    }
  }

  /// Read a file asynchronously with encoding detection, limiting to N lines
  static Future<String> readFileLinesAsync(
    String path, {
    int maxLines = 100,
  }) async {
    final file = File(path);

    // Read first N bytes for detection
    final stream = file.openRead(0, _detectionBytes);
    final bytes = await stream.toList();
    final byteList = bytes.expand((b) => b).toList();

    if (byteList.isEmpty) {
      return '';
    }

    final detection = detectEncoding(byteList);

    // Read full file with detected encoding
    final fullBytes = await file.readAsBytes();
    final contentBytes = detection.bomOffset > 0
        ? fullBytes.sublist(detection.bomOffset)
        : fullBytes;

    try {
      final content = detection.encoding.decode(contentBytes);
      final lines = content.split(RegExp(r'\r?\n'));
      return lines.take(maxLines).join('\n');
    } catch (e) {
      final content = latin1.decode(contentBytes);
      final lines = content.split(RegExp(r'\r?\n'));
      return lines.take(maxLines).join('\n');
    }
  }

  /// Detect if a file is likely binary (not text)
  ///
  /// Uses a heuristic: if more than 5% of bytes are null bytes or
  /// other control characters, it's likely binary.
  static bool isBinary(String path) {
    final file = File(path);
    if (!file.existsSync()) return false;

    try {
      final bytes = file.readAsBytesSync();
      final sampleSize = bytes.length > 4096 ? 4096 : bytes.length;
      final sample = bytes.sublist(0, sampleSize);

      if (sample.isEmpty) return false;

      int controlChars = 0;
      for (final byte in sample) {
        // Check for null bytes and other binary indicators
        if (byte == 0 ||
            (byte < 0x20 && byte != 0x09 && byte != 0x0A && byte != 0x0D)) {
          controlChars++;
        }
      }

      // If more than 5% are control characters (excluding tab, LF, CR), likely binary
      return (controlChars / sample.length) > 0.05;
    } catch (_) {
      return false;
    }
  }
}

/// Result of encoding detection
class EncodingDetection {
  /// The detected encoding
  final Encoding encoding;

  /// Offset to skip BOM (if present)
  final int bomOffset;

  /// Whether a BOM was detected
  final bool hasBom;

  /// Whether the content appears to be pure ASCII
  final bool isAscii;

  EncodingDetection({
    required this.encoding,
    required this.bomOffset,
    this.hasBom = false,
    this.isAscii = false,
  });

  /// Get a human-readable name for the encoding
  String get encodingName {
    if (encoding == utf8) return 'UTF-8';
    if (encoding == EncodingDetector.utf16Le) return 'UTF-16 LE';
    if (encoding == EncodingDetector.utf16Be) return 'UTF-16 BE';
    if (encoding == ascii) return 'ASCII';
    if (encoding == latin1) return 'Latin-1 (ISO-8859-1)';
    final name = encoding.name;
    if (name.contains('windows')) return 'Windows-1252';
    if (name.contains('utf-32le')) return 'UTF-32 LE';
    if (name.contains('utf-32be')) return 'UTF-32 BE';
    return name;
  }

  @override
  String toString() =>
      'EncodingDetection(encoding: $encodingName, bomOffset: $bomOffset, hasBom: $hasBom, isAscii: $isAscii)';
}
