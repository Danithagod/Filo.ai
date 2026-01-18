import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service for detecting naming convention issues in indexed files
///
/// Analyzes file names for:
/// - Mixed naming conventions (camelCase, snake_case, kebab-case, PascalCase)
/// - Spaces in filenames
/// - Invalid/reserved characters
/// - Inconsistent patterns within the same directory
class NamingAnalyzer {
  // Regex patterns for different naming conventions
  static final _camelCasePattern = RegExp(r'^[a-z][a-zA-Z0-9]*$');
  static final _snakeCasePattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static final _kebabCasePattern = RegExp(r'^[a-z][a-z0-9-]*$');
  static final _pascalCasePattern = RegExp(r'^[A-Z][a-zA-Z0-9]*$');
  static final _reservedCharsPattern = RegExp(r'[<>:"|?*]');

  /// Detect naming issues in indexed files
  ///
  /// Returns a list of naming issues with affected files and suggested fixes.
  ///
  /// [rootPath] - Optional root path to filter files
  Future<List<NamingIssue>> detectIssues(
    Session session, {
    String? rootPath,
  }) async {
    // Get all indexed files
    List<FileIndex> files;

    if (rootPath != null) {
      files = await FileIndex.db.find(
        session,
        where: (t) => t.status.equals('indexed') & t.path.like('$rootPath%'),
      );
    } else {
      files = await FileIndex.db.find(
        session,
        where: (t) => t.status.equals('indexed'),
      );
    }

    final issues = <NamingIssue>[];

    // Analyze naming conventions
    final conventionIssue = _detectConventionMixing(files);
    if (conventionIssue != null) {
      issues.add(conventionIssue);
    }

    // Detect spaces in names
    final spacingIssue = _detectSpacesInNames(files);
    if (spacingIssue != null) {
      issues.add(spacingIssue);
    }

    // Detect invalid characters
    final invalidCharsIssue = _detectInvalidCharacters(files);
    if (invalidCharsIssue != null) {
      issues.add(invalidCharsIssue);
    }

    // Detect very long names
    final longNameIssue = _detectLongNames(files);
    if (longNameIssue != null) {
      issues.add(longNameIssue);
    }

    return issues;
  }

  /// Detect mixed naming conventions
  NamingIssue? _detectConventionMixing(List<FileIndex> files) {
    // Only analyze files that look like they follow a naming convention
    // (ignore files with extensions that have mixed case like .tsx, .jsx)
    final categorized = <String, List<String>>{
      'camelCase': [],
      'snake_case': [],
      'kebab-case': [],
      'PascalCase': [],
    };

    for (final file in files) {
      // Get base name without extension
      final name = file.fileName;
      final dotIndex = name.lastIndexOf('.');
      final baseName = dotIndex > 0 ? name.substring(0, dotIndex) : name;

      // Skip short names (1-2 chars) as they're usually not following conventions
      if (baseName.length <= 2) continue;

      // Categorize the name
      if (_camelCasePattern.hasMatch(baseName)) {
        categorized['camelCase']!.add(file.path);
      } else if (_snakeCasePattern.hasMatch(baseName)) {
        categorized['snake_case']!.add(file.path);
      } else if (_kebabCasePattern.hasMatch(baseName)) {
        categorized['kebab-case']!.add(file.path);
      } else if (_pascalCasePattern.hasMatch(baseName)) {
        categorized['PascalCase']!.add(file.path);
      }
    }

    // Check for multiple conventions in use
    final usedConventions = categorized.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => e.key)
        .toList();

    if (usedConventions.length > 1) {
      final allAffectedFiles = <String>[];
      for (final convention in usedConventions) {
        allAffectedFiles.addAll(categorized[convention]!);
      }

      // Determine the dominant convention
      String? dominantConvention;
      int maxCount = 0;
      for (final entry in categorized.entries) {
        if (entry.value.length > maxCount) {
          maxCount = entry.value.length;
          dominantConvention = entry.key;
        }
      }

      return NamingIssue(
        issueType: 'inconsistent_case',
        description:
            'Mixed naming conventions detected: ${usedConventions.join(", ")}',
        severity: 'warning',
        affectedFiles: allAffectedFiles.take(50).toList(), // Limit to 50
        affectedCount: allAffectedFiles.length,
        suggestedFix:
            'Standardize on $dominantConvention (most common convention)',
      );
    }

    return null;
  }

  /// Detect files with spaces in names
  NamingIssue? _detectSpacesInNames(List<FileIndex> files) {
    final filesWithSpaces = files
        .where((f) => f.fileName.contains(' '))
        .map((f) => f.path)
        .toList();

    // Only report if it's a consistent issue (more than 10% of files)
    if (filesWithSpaces.isEmpty) return null;

    final spaceRatio = filesWithSpaces.length / files.length;
    if (spaceRatio < 0.1 && filesWithSpaces.length < 5) {
      return null; // Not significant enough to report
    }

    return NamingIssue(
      issueType: 'spaces_in_name',
      description:
          '${filesWithSpaces.length} files (${(spaceRatio * 100).toStringAsFixed(1)}%) contain spaces',
      severity: spaceRatio > 0.3 ? 'warning' : 'info',
      affectedFiles: filesWithSpaces.take(50).toList(),
      affectedCount: filesWithSpaces.length,
      suggestedFix: 'Replace spaces with underscores (_) or hyphens (-)',
    );
  }

  /// Detect files with invalid/reserved characters
  NamingIssue? _detectInvalidCharacters(List<FileIndex> files) {
    final filesWithInvalidChars = files
        .where((f) => _reservedCharsPattern.hasMatch(f.fileName))
        .map((f) => f.path)
        .toList();

    if (filesWithInvalidChars.isEmpty) return null;

    return NamingIssue(
      issueType: 'invalid_characters',
      description:
          '${filesWithInvalidChars.length} files contain reserved characters (<>:"|?*)',
      severity: 'error',
      affectedFiles: filesWithInvalidChars.take(50).toList(),
      affectedCount: filesWithInvalidChars.length,
      suggestedFix: 'Remove or replace reserved characters: < > : " | ? *',
    );
  }

  /// Detect very long file names (>200 chars)
  NamingIssue? _detectLongNames(List<FileIndex> files) {
    const maxRecommendedLength = 200;

    final longNames = files
        .where((f) => f.fileName.length > maxRecommendedLength)
        .map((f) => f.path)
        .toList();

    if (longNames.isEmpty) return null;

    return NamingIssue(
      issueType: 'long_filename',
      description:
          '${longNames.length} files have names longer than $maxRecommendedLength characters',
      severity: 'info',
      affectedFiles: longNames.take(50).toList(),
      affectedCount: longNames.length,
      suggestedFix: 'Shorten file names for better compatibility',
    );
  }
}
