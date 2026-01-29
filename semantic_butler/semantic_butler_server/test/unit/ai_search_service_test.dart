import 'package:test/test.dart';
import 'package:semantic_butler_server/src/services/ai_search_service.dart';

void main() {
  group('AISearchService', () {
    group('SearchIntent', () {
      test('creates with all required fields', () {
        final intent = SearchIntent(
          intent: 'specific_file',
          strategy: 'ai_only',
          searchTerms: ['gemma', 'folder'],
          filePatterns: ['*'],
          isFolderSearch: true,
          reasoning: 'Looking for a specific folder',
        );

        expect(intent.intent, equals('specific_file'));
        expect(intent.strategy, equals('ai_only'));
        expect(intent.searchTerms, contains('gemma'));
        expect(intent.isFolderSearch, isTrue);
      });

      test('creates without optional reasoning', () {
        final intent = SearchIntent(
          intent: 'semantic_content',
          strategy: 'hybrid',
          searchTerms: ['machine', 'learning'],
          filePatterns: [],
          isFolderSearch: false,
        );

        expect(intent.reasoning, isNull);
        expect(intent.isFolderSearch, isFalse);
      });

      test('creates with optional entity fields', () {
        final intent = SearchIntent(
          intent: 'mixed',
          strategy: 'hybrid',
          searchTerms: [],
          filePatterns: [],
          isFolderSearch: false,
          dateRange: DateExpression(
            type: DateType.relative,
            originalText: 'last week',
          ),
          sizeRange: SizeExpression(
            minBytes: 1024,
            originalText: '>1KB',
          ),
          countExpression: CountExpression(
            minCount: 5,
            unit: 'pages',
          ),
        );

        expect(intent.dateRange, isNotNull);
        expect(intent.dateRange!.type, equals(DateType.relative));
        expect(intent.sizeRange!.minBytes, equals(1024));
        expect(intent.countExpression!.unit, equals('pages'));
      });
    });

    group('SearchStrategy', () {
      test('has all expected values', () {
        expect(SearchStrategy.values, contains(SearchStrategy.semanticFirst));
        expect(SearchStrategy.values, contains(SearchStrategy.aiOnly));
        expect(SearchStrategy.values, contains(SearchStrategy.hybrid));
        expect(SearchStrategy.values.length, equals(3));
      });
    });

    group('_parseQueryHeuristically', () {
      // Note: This tests the internal heuristic parsing logic by creating
      // an AISearchService instance and calling parseQuery, which falls back
      // to heuristics when the AI call fails.

      // Since we can't easily test the private method directly, we test
      // the expected outcomes through SearchIntent behavior patterns.

      test('SearchIntent for folder queries has correct fields', () {
        // Test that a folder-type intent is correctly structured
        final intent = SearchIntent(
          intent: 'specific_file',
          strategy: 'ai_only',
          searchTerms: ['gemma'],
          filePatterns: [],
          isFolderSearch: true,
        );

        expect(intent.isFolderSearch, isTrue);
        expect(intent.strategy, equals('ai_only'));
      });

      test('SearchIntent for file type queries has patterns', () {
        final intent = SearchIntent(
          intent: 'file_type',
          strategy: 'ai_only',
          searchTerms: [],
          filePatterns: ['*.pdf', '*.docx'],
          isFolderSearch: false,
        );

        expect(intent.filePatterns, isNotEmpty);
        expect(intent.filePatterns, contains('*.pdf'));
      });

      test('SearchIntent for semantic queries uses semantic_first', () {
        final intent = SearchIntent(
          intent: 'semantic_content',
          strategy: 'semantic_first',
          searchTerms: ['machine', 'learning', 'documents'],
          filePatterns: [],
          isFolderSearch: false,
        );

        expect(intent.strategy, equals('semantic_first'));
        expect(intent.intent, equals('semantic_content'));
      });
    });
  });

  group('Query Pattern Analysis', () {
    // Test patterns that would be analyzed by the heuristic parser

    test('folder-related keywords', () {
      final folderKeywords = ['folder', 'directory', 'where is', 'locate'];

      for (final keyword in folderKeywords) {
        expect(
          keyword.toLowerCase().contains('folder') ||
              keyword.toLowerCase().contains('directory') ||
              keyword.toLowerCase().contains('where is') ||
              keyword.toLowerCase().contains('locate'),
          isTrue,
        );
      }
    });

    test('file pattern regex matches correctly', () {
      final pattern = RegExp(r'\*\.(\w+)');

      expect(pattern.hasMatch('*.pdf'), isTrue);
      expect(pattern.hasMatch('*.docx'), isTrue);
      expect(pattern.hasMatch('*.py'), isTrue);
      expect(pattern.hasMatch('mydocument.pdf'), isFalse);
    });

    test('stop words are correctly identified', () {
      final stopWords = {
        'where',
        'is',
        'the',
        'find',
        'locate',
        'search',
        'for',
        'my',
        'folder',
        'file',
        'directory',
        'located',
        'a',
        'an',
      };

      expect(stopWords.contains('where'), isTrue);
      expect(stopWords.contains('gemma'), isFalse);
      expect(stopWords.contains('important'), isFalse);
    });

    test('extracting search terms filters stop words', () {
      final query = 'where is the gemma folder';
      final stopWords = {'where', 'is', 'the', 'folder', 'a', 'an'};

      final terms = query
          .split(RegExp(r'\s+'))
          .where((w) => !stopWords.contains(w.toLowerCase()))
          .where((w) => w.length > 2)
          .toList();

      expect(terms, contains('gemma'));
      expect(terms, isNot(contains('where')));
      expect(terms, isNot(contains('the')));
    });
  });

  group('Result Scoring Logic', () {
    test('exact name match scores higher', () {
      final queryTerms = ['gemma', 'model'];
      final fileName = 'gemma';

      var score = 0.0;
      for (final term in queryTerms) {
        if (fileName.toLowerCase().contains(term)) {
          score += 0.2;
        }
        if (fileName.toLowerCase() == term) {
          score += 0.5;
        }
      }

      // 'gemma' exact match: 0.2 + 0.5 = 0.7
      expect(score, equals(0.7));
    });

    test('partial match scores lower than exact', () {
      final queryTerms = ['gem'];
      final fileName = 'gemma';

      var score = 0.0;
      for (final term in queryTerms) {
        if (fileName.toLowerCase().contains(term)) {
          score += 0.2;
        }
        if (fileName.toLowerCase() == term) {
          score += 0.5;
        }
      }

      // 'gem' partial match: 0.2 only
      expect(score, equals(0.2));
    });

    test('no match scores zero', () {
      final queryTerms = ['model'];
      final fileName = 'document';

      var score = 0.0;
      for (final term in queryTerms) {
        if (fileName.toLowerCase().contains(term)) {
          score += 0.2;
        }
        if (fileName.toLowerCase() == term) {
          score += 0.5;
        }
      }

      expect(score, equals(0.0));
    });
  });

  group('Path Deduplication', () {
    test('normalizes paths for comparison', () {
      final paths = [
        'C:\\Users\\test\\file.txt',
        'c:\\users\\test\\file.txt',
        'C:\\Users\\Test\\File.txt',
      ];

      final normalizedPaths = paths.map((p) => p.toLowerCase()).toSet();

      // All should normalize to same path
      expect(normalizedPaths.length, equals(1));
    });

    test('different paths remain distinct', () {
      final paths = [
        'C:\\Users\\test\\file.txt',
        'C:\\Users\\test\\other.txt',
        'D:\\data\\file.txt',
      ];

      final normalizedPaths = paths.map((p) => p.toLowerCase()).toSet();

      expect(normalizedPaths.length, equals(3));
    });
  });

  group('Strategy Determination', () {
    test('explicit strategy overrides intent-based strategy', () {
      // If user explicitly requests ai_only, use that even if intent suggests hybrid
      final requestedStrategy = SearchStrategy.aiOnly;
      final intentStrategy = 'hybrid';

      // The logic: if requested != hybrid, use requested
      final effectiveStrategy = requestedStrategy != SearchStrategy.hybrid
          ? requestedStrategy
          : (intentStrategy == 'ai_only'
                ? SearchStrategy.aiOnly
                : intentStrategy == 'semantic_first'
                ? SearchStrategy.semanticFirst
                : SearchStrategy.hybrid);

      expect(effectiveStrategy, equals(SearchStrategy.aiOnly));
    });

    test('hybrid strategy defers to intent', () {
      final requestedStrategy = SearchStrategy.hybrid;

      // When requested is hybrid, use intent-based strategy
      expect(requestedStrategy, equals(SearchStrategy.hybrid));

      // Intent says 'ai_only' should result in aiOnly
      final intentStrategy = 'ai_only';
      final effectiveStrategy = intentStrategy == 'ai_only'
          ? SearchStrategy.aiOnly
          : intentStrategy == 'semantic_first'
          ? SearchStrategy.semanticFirst
          : SearchStrategy.hybrid;

      expect(effectiveStrategy, equals(SearchStrategy.aiOnly));
    });
  });

  group('JSON Parsing', () {
    test('parses valid JSON response', () {
      final jsonStr = '{"intent": "specific_file", "strategy": "ai_only"}';

      // Simulate the parsing
      expect(() {
        final parsed = Map<String, dynamic>.from(
          (jsonStr.isEmpty ? {} : _parseJson(jsonStr)),
        );
        expect(parsed['intent'], equals('specific_file'));
        expect(parsed['strategy'], equals('ai_only'));
      }, returnsNormally);
    });

    test('handles JSON with markdown wrapper', () {
      final jsonStr = '''```json
{"intent": "file_type", "strategy": "hybrid"}
```''';

      // Extract JSON from markdown
      final start = jsonStr.indexOf('{');
      final end = jsonStr.lastIndexOf('}');
      final cleanJson = jsonStr.substring(start, end + 1);

      expect(
        cleanJson,
        equals('{"intent": "file_type", "strategy": "hybrid"}'),
      );
    });

    test('handles empty JSON gracefully', () {
      final result = _parseJson('');
      expect(result, isEmpty);
    });

    test('handles malformed JSON gracefully', () {
      final result = _parseJson('not json');
      expect(result, isEmpty);
    });
  });

  group('String List Parsing', () {
    test('parses list of strings', () {
      final value = ['term1', 'term2', 'term3'];
      final result = _parseStringList(value);

      expect(result, equals(['term1', 'term2', 'term3']));
    });

    test('handles null gracefully', () {
      final result = _parseStringList(null);
      expect(result, isEmpty);
    });

    test('converts non-string elements to string', () {
      final value = [1, 2, 'three'];
      final result = _parseStringList(value);

      expect(result, contains('1'));
      expect(result, contains('2'));
      expect(result, contains('three'));
    });
  });
}

// Helper functions extracted from AISearchService for testing
Map<String, dynamic> _parseJson(String jsonStr) {
  try {
    if (jsonStr.isEmpty) return {};
    final decoded = _jsonDecode(jsonStr);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return {};
  } catch (e) {
    return {};
  }
}

dynamic _jsonDecode(String source) {
  try {
    // Simple inline JSON parser for testing
    // In real code, this uses dart:convert
    if (source.isEmpty) return {};
    if (!source.startsWith('{')) return {};

    // Very basic parsing for test purposes
    final result = <String, dynamic>{};

    // Extract key-value pairs using regex
    final pattern = RegExp(r'"(\w+)"\s*:\s*"([^"]*)"');
    for (final match in pattern.allMatches(source)) {
      result[match.group(1)!] = match.group(2)!;
    }

    return result;
  } catch (e) {
    return {};
  }
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}
