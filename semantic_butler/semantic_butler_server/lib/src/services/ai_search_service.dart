import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../config/ai_models.dart';
import 'openrouter_client.dart';
import 'terminal_service.dart' as terminal;

/// Service for AI-powered file search
///
/// Combines semantic index search with terminal-based file discovery
/// using AI to orchestrate the best search strategy.
class AISearchService {
  final OpenRouterClient _client;
  final terminal.TerminalService _terminal;

  AISearchService({
    required OpenRouterClient client,
    terminal.TerminalService? terminalService,
  }) : _client = client,
       _terminal = terminalService ?? terminal.TerminalService();

  // ==========================================================================
  // QUERY PARSING
  // ==========================================================================

  /// Analyze query to determine search intent and strategy
  Future<SearchIntent> parseQuery(String query) async {
    // Use AI to understand the query intent
    final messages = <ChatMessage>[
      ChatMessage.system('''
You are a query analyzer for a file search system.
Analyze the user's search query and determine:
1. The search intent (what type of thing they're looking for)
2. The best search strategy to use
3. Key terms to search for

Respond with valid JSON only:
{
  "intent": "specific_file|file_type|semantic_content|location|mixed",
  "strategy": "semantic_first|ai_only|hybrid",
  "search_terms": ["term1", "term2"],
  "file_patterns": ["*.pdf", "*.py"],
  "is_folder_search": true|false,
  "reasoning": "Brief explanation"
}

Intent types:
- specific_file: Looking for a specific file/folder by name (e.g., "where is the gemma folder")
- file_type: Looking for files of a certain type (e.g., "find all PDF files")
- semantic_content: Looking for files about a topic (e.g., "documents about machine learning")
- location: Asking about folder locations (e.g., "where are my downloads")
- mixed: Combination of above

Strategy types:
- semantic_first: Try semantic index first, fall back to AI terminal search if not found
- ai_only: Skip index entirely, use terminal commands (best for specific file/folder searches)
- hybrid: Run both in parallel, merge results
'''),
      ChatMessage.user(query),
    ];

    try {
      final response = await _client.chatCompletion(
        model: AIModels.chatGeminiFlash,
        messages: messages,
        temperature: 0.2,
      );

      String jsonStr = response.content.trim();
      // Remove markdown if present
      if (jsonStr.startsWith('```')) {
        final start = jsonStr.indexOf('{');
        final end = jsonStr.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          jsonStr = jsonStr.substring(start, end + 1);
        }
      }

      final parsed = _parseJson(jsonStr);
      return SearchIntent(
        intent: parsed['intent'] as String? ?? 'mixed',
        strategy: parsed['strategy'] as String? ?? 'hybrid',
        searchTerms: _parseStringList(parsed['search_terms']),
        filePatterns: _parseStringList(parsed['file_patterns']),
        isFolderSearch: parsed['is_folder_search'] as bool? ?? false,
        reasoning: parsed['reasoning'] as String?,
      );
    } catch (e) {
      // Fallback to simple heuristics
      return _parseQueryHeuristically(query);
    }
  }

  /// Simple heuristic-based query parsing (fallback)
  SearchIntent _parseQueryHeuristically(String query) {
    final lowerQuery = query.toLowerCase();

    // Check for folder-related queries
    final isFolderSearch =
        lowerQuery.contains('folder') ||
        lowerQuery.contains('directory') ||
        lowerQuery.contains('where is') ||
        lowerQuery.contains('locate');

    // Check for file type patterns
    final fileTypePattern = RegExp(r'\*\.(\w+)');
    final fileTypeMatches = fileTypePattern.allMatches(query);
    final filePatterns = fileTypeMatches.map((m) => m.group(0)!).toList();

    // Determine intent
    String intent;
    String strategy;

    if (lowerQuery.contains('where') ||
        lowerQuery.contains('find') ||
        lowerQuery.contains('locate')) {
      intent = 'specific_file';
      strategy = 'ai_only';
    } else if (filePatterns.isNotEmpty) {
      intent = 'file_type';
      strategy = 'ai_only';
    } else {
      intent = 'semantic_content';
      strategy = 'semantic_first';
    }

    // Extract search terms (remove common words)
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

    final terms = query
        .split(RegExp(r'\s+'))
        .where((w) => !stopWords.contains(w.toLowerCase()))
        .where((w) => w.length > 2)
        .toList();

    return SearchIntent(
      intent: intent,
      strategy: strategy,
      searchTerms: terms,
      filePatterns: filePatterns,
      isFolderSearch: isFolderSearch,
    );
  }

  // ==========================================================================
  // SEARCH EXECUTION
  // ==========================================================================

  /// Execute AI-powered search with streaming progress
  Stream<AISearchProgress> executeSearch(
    Session session,
    String query, {
    SearchStrategy strategy = SearchStrategy.hybrid,
    int maxResults = 20,
    SearchFilters? filters,
  }) async* {
    // Step 1: Parse query intent
    yield AISearchProgress(
      type: 'thinking',
      message: 'Analyzing your search query...',
      progress: 0.05,
    );

    final intent = await parseQuery(query);

    yield AISearchProgress(
      type: 'thinking',
      message: 'Strategy: ${intent.reasoning ?? intent.strategy}',
      progress: 0.1,
    );

    // Determine effective strategy
    final effectiveStrategy = _determineStrategy(strategy, intent);

    // Step 2: Execute search based on strategy
    final allResults = <AISearchResult>[];

    if (effectiveStrategy == SearchStrategy.semanticFirst ||
        effectiveStrategy == SearchStrategy.hybrid) {
      // Try semantic search first
      yield AISearchProgress(
        type: 'searching',
        message: 'Searching indexed documents...',
        source: 'semantic',
        progress: 0.2,
      );

      try {
        final semanticResults = await _searchIndex(
          session,
          query,
          maxResults,
          threshold: 0.3,
          filters: filters,
        );
        allResults.addAll(semanticResults);

        if (semanticResults.isNotEmpty) {
          yield AISearchProgress(
            type: 'found',
            message: 'Found ${semanticResults.length} results in index',
            source: 'semantic',
            results: semanticResults,
            progress: 0.4,
          );
        }
      } catch (e) {
        session.log('Semantic search failed: $e', level: LogLevel.warning);
      }
    }

    // If no results or strategy is ai_only/hybrid, do terminal search
    if (allResults.isEmpty ||
        effectiveStrategy == SearchStrategy.aiOnly ||
        effectiveStrategy == SearchStrategy.hybrid) {
      yield* _executeTerminalSearch(
        session,
        intent,
        allResults,
        maxResults,
        startProgress: allResults.isEmpty ? 0.2 : 0.5,
      );

      // Proactive Step: If still few results, use AI to suggest targeted search locations/patterns
      if (allResults.length < 5) {
        yield* _executeProactiveDiscovery(
          session,
          query,
          intent,
          allResults,
          maxResults,
        );
      }
    }

    // Step 3: Aggregate and rank results
    yield AISearchProgress(
      type: 'thinking',
      message: 'Ranking results...',
      progress: 0.95,
    );

    final rankedResults = _rankResults(allResults, query);

    // Step 4: Return final results
    yield AISearchProgress(
      type: 'complete',
      message: 'Search complete',
      results: rankedResults.take(maxResults).toList(),
      progress: 1.0,
    );
  }

  /// Execute terminal-based search across drives
  Stream<AISearchProgress> _executeTerminalSearch(
    Session session,
    SearchIntent intent,
    List<AISearchResult> existingResults,
    int maxResults, {
    double startProgress = 0.2,
  }) async* {
    // Get available drives
    yield AISearchProgress(
      type: 'searching',
      message: 'Discovering available drives...',
      source: 'terminal',
      progress: startProgress,
    );

    List<terminal.DriveInfo> drives;
    try {
      drives = await _terminal.listDrives();
    } catch (e) {
      yield AISearchProgress(
        type: 'error',
        message: 'Failed to list drives: $e',
        error: e.toString(),
      );
      return;
    }

    // Calculate progress per drive
    final progressPerDrive = (0.9 - startProgress) / drives.length;
    var currentProgress = startProgress;

    // Search each drive
    for (final drive in drives) {
      yield AISearchProgress(
        type: 'searching',
        message:
            'Searching ${drive.description.isNotEmpty ? drive.description : drive.path}...',
        source: 'terminal',
        drive: drive.path,
        progress: currentProgress,
      );

      try {
        // Try search terms and file patterns
        final patternsToTry = <String>{
          ...intent.searchTerms,
          ...intent.filePatterns,
        };

        for (final pattern in patternsToTry) {
          final results = await _terminal.deepSearch(
            pattern,
            directory: drive.path,
            foldersOnly: intent.isFolderSearch,
          );

          if (results.success) {
            final files = results.stdout
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .toList();

            for (final path in files) {
              if (!existingResults.any((r) => r.path == path)) {
                final fileName = path.split(RegExp(r'[/\\]')).last;
                existingResults.add(
                  AISearchResult(
                    path: path,
                    fileName: fileName,
                    isDirectory: intent.isFolderSearch,
                    source: 'terminal',
                    foundVia: 'deep_search',
                    matchReason:
                        'Matched pattern "$pattern" on drive ${drive.path}',
                  ),
                );
              }
            }

            if (files.isNotEmpty) {
              yield AISearchProgress(
                type: 'found',
                message:
                    'Found ${files.length} matches for "$pattern" in ${drive.description.isNotEmpty ? drive.description : drive.path}',
                source: 'terminal',
                drive: drive.path,
                results: existingResults,
                progress: currentProgress + progressPerDrive * 0.5,
              );
            }
          }
        }
      } catch (e) {
        session.log(
          'Search failed for ${drive.path}: $e',
          level: LogLevel.warning,
        );
      }

      currentProgress += progressPerDrive;

      // Early exit if we have enough results
      if (existingResults.length >= maxResults * 2) {
        yield AISearchProgress(
          type: 'thinking',
          message: 'Found enough results, stopping search',
          progress: 0.9,
        );
        break;
      }
    }
  }

  /// Use AI to suggest targeted terminal commands for difficult-to-find files
  Stream<AISearchProgress> _executeProactiveDiscovery(
    Session session,
    String query,
    SearchIntent intent,
    List<AISearchResult> currentResults,
    int maxResults,
  ) async* {
    yield AISearchProgress(
      type: 'thinking',
      message:
          'Initial search yielded few results. Thinking of other places to look...',
      progress: 0.85,
    );

    final messages = <ChatMessage>[
      ChatMessage.system('''
You are a file discovery expert. The initial search for "$query" didn't find much.
Suggest exactly 3 targeted PowerShell search patterns or locations that might contain what the user wants.
Focus on common Windows paths if not specified, or patterns related to the topic.

Respond with JSON only:
{
  "suggestions": [
    {"pattern": "*pattern*", "reason": "why", "path": "specific path or null"},
    ...
  ]
}
'''),
      ChatMessage.user(query),
    ];

    try {
      final response = await _client.chatCompletion(
        model: AIModels.chatGeminiFlash,
        messages: messages,
        temperature: 0.4,
      );

      final parsed = _parseJson(response.content.trim());
      final suggestions = parsed['suggestions'] as List? ?? [];

      for (final suggestion in suggestions) {
        final pattern = suggestion['pattern'] as String?;
        final path = suggestion['path'] as String?;
        if (pattern == null) continue;

        yield AISearchProgress(
          type: 'searching',
          message: 'Trying deeper match: $pattern...',
          source: 'terminal',
          progress: 0.9,
        );

        final results = await _terminal.deepSearch(
          pattern,
          directory: path, // Will use default if null
        );

        if (results.success) {
          final files = results.stdout
              .split('\n')
              .where((l) => l.trim().isNotEmpty)
              .toList();

          for (final fPath in files) {
            if (!currentResults.any((r) => r.path == fPath)) {
              currentResults.add(
                AISearchResult(
                  path: fPath,
                  fileName: fPath.split(RegExp(r'[/\\]')).last,
                  isDirectory: false,
                  source: 'terminal',
                  foundVia: 'proactive_discovery',
                  matchReason:
                      'Found via AI suggestion: ${suggestion['reason']}',
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      session.log('Proactive discovery failed: $e', level: LogLevel.debug);
    }
  }

  // ==========================================================================
  // INDEX SEARCH
  // ==========================================================================

  /// Search the semantic index using vector similarity
  Future<List<AISearchResult>> _searchIndex(
    Session session,
    String query,
    int limit, {
    double threshold = 0.3,
    SearchFilters? filters,
  }) async {
    final results = <AISearchResult>[];

    try {
      // 1. Generate embedding for the query
      final embeddingResponse = await _client.createEmbeddings(
        model: AIModels.embeddingGemini,
        input: [query],
      );
      final queryEmbedding = embeddingResponse.firstEmbedding;
      final queryEmbeddingJson = jsonEncode(queryEmbedding);

      // 2. Perform vector search using pgvector
      // Build dynamic WHERE clause for filters
      final whereConditions = <String>[
        '1 - (dvs.embedding_vector <=> \$1::vector) > \$2',
      ];
      final parameters = <dynamic>[queryEmbeddingJson, threshold];
      int paramIndex = 3;

      if (filters != null) {
        // Date Range
        if (filters.dateFrom != null) {
          whereConditions.add('fi."indexedAt" >= \$$paramIndex');
          parameters.add(filters.dateFrom);
          paramIndex++;
        }
        if (filters.dateTo != null) {
          whereConditions.add('fi."indexedAt" <= \$$paramIndex');
          parameters.add(filters.dateTo);
          paramIndex++;
        }

        // File Size
        if (filters.minSize != null) {
          whereConditions.add('fi."fileSizeBytes" >= \$$paramIndex');
          parameters.add(filters.minSize);
          paramIndex++;
        }
        if (filters.maxSize != null) {
          whereConditions.add('fi."fileSizeBytes" <= \$$paramIndex');
          parameters.add(filters.maxSize);
          paramIndex++;
        }

        // File Types
        if (filters.fileTypes != null && filters.fileTypes!.isNotEmpty) {
          final typeConditions = <String>[];
          for (final type in filters.fileTypes!) {
            if (type == 'pdf') {
              typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
              parameters.add('%pdf%');
              paramIndex++;
            } else if (type == 'image') {
              typeConditions.add('fi."mimeType" ILIKE \$$paramIndex');
              parameters.add('image/%');
              paramIndex++;
            } else if (type == 'doc') {
              typeConditions.add(
                '(fi."mimeType" ILIKE \$$paramIndex OR fi."fileName" ILIKE \$$paramIndex)',
              );
              parameters.add('%word%');
              paramIndex++;
            } else {
              typeConditions.add('fi."fileName" ILIKE \$$paramIndex');
              parameters.add('%.$type%');
              paramIndex++;
            }
          }
          if (typeConditions.isNotEmpty) {
            whereConditions.add('(${typeConditions.join(" OR ")})');
          }
        }

        // Tags
        if (filters.tags != null && filters.tags!.isNotEmpty) {
          for (final tag in filters.tags!) {
            whereConditions.add('fi."tagsJson" ILIKE \$$paramIndex');
            parameters.add('%"$tag"%');
            paramIndex++;
          }
        }
      }

      final limitParamIndex = paramIndex;
      parameters.add(limit);

      final searchQuery =
          '''
        SELECT
          de."fileIndexId",
          1 - (dvs.embedding_vector <=> \$1::vector) as similarity,
          fi.id, fi.path, fi."fileName", fi."contentPreview",
          fi."tagsJson", fi."indexedAt", fi."fileSizeBytes", fi."mimeType"
        FROM document_embedding de
        JOIN document_vector_store dvs ON de.id = dvs.id
        JOIN file_index fi ON de."fileIndexId" = fi.id
        WHERE ${whereConditions.join(" AND ")}
        ORDER BY dvs.embedding_vector <=> \$1::vector
        LIMIT \$$limitParamIndex
      ''';

      final rows = await session.db.unsafeQuery(
        searchQuery,
        parameters: QueryParameters.positional(parameters),
      );

      for (final row in rows) {
        final similarity = row[1] as double;
        results.add(
          AISearchResult(
            path: row[3] as String,
            fileName: row[4] as String,
            isDirectory: false,
            source: 'index',
            relevanceScore: similarity,
            contentPreview: row[5] as String?,
            foundVia: 'semantic',
            matchReason:
                'Highly relevant semantic match (${(similarity * 100).toStringAsFixed(0)}%)',
            fileSizeBytes: (row[8] as int?) ?? 0,
            mimeType: row[9] as String?,
            tags: _parseTags(row[6] as String?),
            indexedAt: row[7] as DateTime?,
          ),
        );
      }
    } catch (e) {
      session.log(
        'pgvector search failed in AISearchService: $e',
        level: LogLevel.warning,
      );
      // Fallback to text search if pgvector/embeddings fail
      return _fallbackSearch(session, query, limit, filters);
    }

    return results;
  }

  /// Fallback search using basic keyword matching
  Future<List<AISearchResult>> _fallbackSearch(
    Session session,
    String query,
    int limit,
    SearchFilters? filters,
  ) async {
    final results = <AISearchResult>[];

    final indexed = await FileIndex.db.find(
      session,
      where: (t) {
        var condition =
            t.fileName.ilike('%${query.replaceAll(' ', '%')}%') |
            t.contentPreview.ilike('%${query.replaceAll(' ', '%')}%');

        if (filters != null) {
          if (filters.dateFrom != null) {
            condition &= (t.indexedAt >= filters.dateFrom!);
          }
          if (filters.dateTo != null) {
            condition &= (t.indexedAt <= filters.dateTo!);
          }
          if (filters.minSize != null) {
            condition &= (t.fileSizeBytes >= filters.minSize!);
          }
          if (filters.maxSize != null) {
            condition &= (t.fileSizeBytes <= filters.maxSize!);
          }
          // Tags and types are harder with the basic 'where' builder on strings without more logic
          // but we'll stick to basic implementation for fallback
        }
        return condition;
      },
      limit: limit,
    );

    for (final doc in indexed) {
      results.add(
        AISearchResult(
          path: doc.path,
          fileName: doc.fileName,
          isDirectory: false,
          source: 'index',
          relevanceScore: 0.5,
          contentPreview: doc.contentPreview,
          foundVia: 'keyword_fallback',
          matchReason: 'Matched keyword search',
          fileSizeBytes: doc.fileSizeBytes,
          mimeType: doc.mimeType,
          tags: _parseTags(doc.tagsJson),
          indexedAt: doc.indexedAt,
        ),
      );
    }
    return results;
  }

  List<String> _parseTags(String? tagsJson) {
    if (tagsJson == null || tagsJson.isEmpty) return [];
    try {
      // It might be a comma-separated string or a JSON array
      if (tagsJson.startsWith('[')) {
        return List<String>.from(jsonDecode(tagsJson) as List);
      }
      return tagsJson.split(',').where((t) => t.isNotEmpty).toList();
    } catch (_) {
      return tagsJson.split(',').where((t) => t.isNotEmpty).toList();
    }
  }

  // ==========================================================================
  // RESULT RANKING
  // ==========================================================================

  /// Rank and deduplicate results
  List<AISearchResult> _rankResults(
    List<AISearchResult> results,
    String query,
  ) {
    // Remove duplicates by path
    final seen = <String>{};
    final unique = <AISearchResult>[];

    for (final result in results) {
      final normalizedPath = result.path.toLowerCase();
      if (!seen.contains(normalizedPath)) {
        seen.add(normalizedPath);
        unique.add(result);
      }
    }

    // Score and sort results
    final queryTerms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2);

    unique.sort((a, b) {
      // Prefer results found in both sources
      final aScore = _scoreResult(a, queryTerms);
      final bScore = _scoreResult(b, queryTerms);
      return bScore.compareTo(aScore);
    });

    return unique;
  }

  /// Score a single result for ranking
  double _scoreResult(AISearchResult result, Iterable<String> queryTerms) {
    var score = 0.0;

    // 1. Base score from relevance (if available from semantic search)
    // Semantic relevance is usually 0.0-1.0
    score += (result.relevanceScore ?? 0.3) * 1.5;

    // 2. Source Weighting
    if (result.source == 'index') {
      score += 0.2; // Prefer indexed (likely more relevant/processed)
    } else if (result.source == 'terminal') {
      score += 0.1;
    }

    // 3. Keyword Exactness (Lexical)
    final fileName = result.fileName.toLowerCase();
    for (final term in queryTerms) {
      final termLower = term.toLowerCase();
      if (fileName == termLower) {
        score += 1.0; // Exact match
      } else if (fileName.startsWith(termLower)) {
        score += 0.5; // Prefix match
      } else if (fileName.contains(termLower)) {
        score += 0.3; // Contains
      }
    }

    // 4. File Type Relevance (Bonus if it matches a pattern the AI extracted)
    // Note: We don't have the full intent here, but we can check common patterns
    if (result.mimeType != null) {
      // Small bonus for common document types if query looks like document search
      if (result.mimeType!.contains('pdf') ||
          result.mimeType!.contains('word')) {
        score += 0.05;
      }
    }

    // 5. Freshness Bonus (if indexedAt available)
    if (result.indexedAt != null) {
      final daysOld = DateTime.now().difference(result.indexedAt!).inDays;
      if (daysOld < 7) {
        score += 0.1; // Bonus for files indexed in the last week
      }
    }

    return score;
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  SearchStrategy _determineStrategy(
    SearchStrategy requested,
    SearchIntent intent,
  ) {
    // If explicit strategy requested, use it
    if (requested != SearchStrategy.hybrid) {
      return requested;
    }

    // Otherwise, use intent-based strategy
    switch (intent.strategy) {
      case 'ai_only':
        return SearchStrategy.aiOnly;
      case 'semantic_first':
        return SearchStrategy.semanticFirst;
      default:
        return SearchStrategy.hybrid;
    }
  }

  Map<String, dynamic> _parseJson(String jsonStr) {
    try {
      return Map<String, dynamic>.from(
        (jsonStr.isEmpty ? {} : _jsonDecode(jsonStr)) as Map,
      );
    } catch (e) {
      return {};
    }
  }

  dynamic _jsonDecode(String source) {
    return jsonDecode(source);
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

// =============================================================================
// SUPPORTING TYPES
// =============================================================================

/// Search intent parsed from user query
class SearchIntent {
  final String intent;
  final String strategy;
  final List<String> searchTerms;
  final List<String> filePatterns;
  final bool isFolderSearch;
  final String? reasoning;

  SearchIntent({
    required this.intent,
    required this.strategy,
    required this.searchTerms,
    required this.filePatterns,
    required this.isFolderSearch,
    this.reasoning,
  });
}

/// Search strategy enum
enum SearchStrategy {
  /// Try semantic index first, fall back to AI terminal search
  semanticFirst,

  /// Skip index, use terminal commands only
  aiOnly,

  /// Run both in parallel, merge results
  hybrid,
}
