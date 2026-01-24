import 'package:flutter/material.dart';

/// Helper class for file-related UI display logic
class FileDisplayHelper {
  /// Get appropriate icon for a file based on its extension
  static IconData getIconForFile(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
      case 'rtf':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'svg':
      case 'webp':
        return Icons.image_outlined;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.video_library_outlined;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'm4a':
        return Icons.audio_file_outlined;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return Icons.folder_zip_outlined;
      case 'exe':
      case 'msi':
      case 'app':
      case 'dmg':
        return Icons.settings_applications_outlined;
      case 'dart':
      case 'js':
      case 'ts':
      case 'py':
      case 'java':
      case 'c':
      case 'cpp':
      case 'html':
      case 'css':
      case 'json':
      case 'yaml':
        return Icons.code_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Format file size in bytes to a human-readable string
  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
  }
}
