import 'dart:async';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'openrouter_client.dart';
import '../config/ai_models.dart';
import 'circuit_breaker.dart';
import 'smart_rate_limiter.dart';

/// Enhanced query correction service with AI-powered suggestions
class QueryCorrectionService {
  final OpenRouterClient _client;
  final CircuitBreaker _circuitBreaker;

  QueryCorrectionService({
    required OpenRouterClient client,
  }) : _client = client,
       _circuitBreaker = CircuitBreakerRegistry.instance.getBreaker(
         'query_correction',
       );

  /// Get corrected query using AI or fallback to trigram similarity
  Future<String?> getCorrectedQuery(
    Session session,
    String query, {
    String? sessionId,
  }) async {
    // Check rate limit
    if (!SmartRateLimiter.instance.check(
      'query_correction',
      clientId: sessionId ?? 'system',
    )) {
      return await _getBasicCorrection(session, query);
    }

    // First try AI-powered correction
    try {
      final aiCorrection = await _getAICorrection(query);
      if (aiCorrection != null &&
          aiCorrection.toLowerCase() != query.toLowerCase()) {
        session.log(
          'AI query correction: "$query" -> "$aiCorrection"',
          level: LogLevel.debug,
        );
        return aiCorrection;
      }
    } catch (e) {
      session.log(
        'AI query correction failed: $e',
        level: LogLevel.debug,
      );
    }

    // Fall back to basic correction
    return await _getBasicCorrection(session, query);
  }

  /// Get AI-powered query correction
  Future<String?> _getAICorrection(String query) async {
    if (query.length < 5 || !_mightContainTypos(query)) {
      return null;
    }

    final messages = <ChatMessage>[
      ChatMessage.system('''
You are a search query assistant. The user will type a search query that may contain typos or unclear terms.

Your task:
1. Correct obvious typos (e.g., "doucment" -> "document", "recieve" -> "receive")
2. Expand abbreviations if helpful (e.g., "doc" -> "document", "img" -> "image")
3. Keep the original meaning and structure
4. Keep technical terms, file names, and specific patterns unchanged
5. Return ONLY the corrected query, no explanation

Examples:
- "find my recent doucments" -> "find my recent documents"
- "pdf fils from last wek" -> "pdf files from last week"
- "*.jpg files" -> "*.jpg files"
- "C drive folder" -> "C drive folder"
- "recipt from amazon" -> "receipt from amazon"
'''),
      ChatMessage.user(query),
    ];

    final response = await _circuitBreaker.execute(
      () => _client.chatCompletion(
        model: AIModels.chatGeminiFlash,
        messages: messages,
        temperature: 0.1,
        maxTokens: 50,
      ),
    );

    String corrected = response.content.trim();

    // Remove quotes if AI added them
    if (corrected.startsWith('"') && corrected.endsWith('"')) {
      corrected = corrected.substring(1, corrected.length - 1);
    }

    // Remove common explanatory prefixes
    corrected = corrected.replaceFirst(
      RegExp(r'^(Corrected:|The correct query is:?)\s*', caseSensitive: false),
      '',
    );

    return corrected.isEmpty ? null : corrected;
  }

  /// Basic query correction using trigram similarity
  Future<String?> _getBasicCorrection(Session session, String query) async {
    final terms = query.split(RegExp(r'\s+'));
    final correctedTerms = <String>[];
    bool changed = false;

    final preservePatterns = [
      RegExp(r'^\*+\.\w+$'),
      RegExp(r'^[a-zA-Z]:\\'),
      RegExp(r'^[a-zA-Z0-9_\-\.]+\.[a-zA-Z0-9]+$'),
    ];

    for (final term in terms) {
      final shouldPreserve = preservePatterns.any((p) => p.hasMatch(term));
      if (shouldPreserve || term.length < 4) {
        correctedTerms.add(term);
        continue;
      }

      final suggestion = await _findSimilarTerm(session, term);
      if (suggestion != null &&
          suggestion.toLowerCase() != term.toLowerCase()) {
        correctedTerms.add(suggestion);
        changed = true;
      } else {
        correctedTerms.add(term);
      }
    }

    return changed ? correctedTerms.join(' ') : null;
  }

  /// Find a similar term using trigram similarity
  Future<String?> _findSimilarTerm(Session session, String term) async {
    // Common typos dictionary (fast path)
    final commonTypos = _getCommonTypos();
    if (commonTypos.containsKey(term.toLowerCase())) {
      return commonTypos[term.toLowerCase()];
    }

    if (term.startsWith('.') || term.contains('.')) {
      return null;
    }

    // Search for similar terms in the index
    // Using unsafeQuery for trigram similarity
    final result = await session.db.unsafeQuery(
      '''
      SELECT "fileName", word_similarity(\$1, "fileName") as similarity
      FROM "file_index"
      WHERE "fileName" % \$1
      ORDER BY similarity DESC
      LIMIT 1
      ''',
      parameters: QueryParameters.positional([term.toLowerCase()]),
    );

    if (result.isNotEmpty) {
      final row = result.first;
      final similarity = row[1] as double? ?? 0.0;
      if (similarity > 0.6) {
        final fileName = row[0] as String? ?? '';
        final words = fileName.split(RegExp(r'[\s_\-\.]+'));
        for (final word in words) {
          if (word.length > 3 &&
              word.toLowerCase().contains(
                term.substring(0, min(3, term.length)),
              )) {
            return word;
          }
        }
        return fileName;
      }
    }

    return null;
  }

  /// Check if query might contain typos worth correcting
  bool _mightContainTypos(String query) {
    final lowerQuery = query.toLowerCase();

    final typoPatterns = [
      RegExp(r'(\w)\1{2,}'),
      RegExp(r'cie'),
      RegExp(r'ei'),
      RegExp(r'[^a-zA-Z0-9\s\*\.\:\\\/_\-]'),
    ];

    for (final pattern in typoPatterns) {
      if (pattern.hasMatch(lowerQuery)) {
        return true;
      }
    }

    return false;
  }

  /// Common typo corrections dictionary
  Map<String, String> _getCommonTypos() {
    return {
      'doucment': 'document',
      'docuemnt': 'document',
      'docment': 'document',
      'documents': 'document',
      'fil': 'file',
      'flie': 'file',
      'fiels': 'files',
      'fils': 'files',
      'recieve': 'receive',
      'receieve': 'receive',
      'recipt': 'receipt',
      'reciept': 'receipt',
      'pdfs': 'pdf',
      'pdf file': 'pdf',
      'jpg': 'jpeg',
      'jpeg': 'jpg',
      'pic': 'picture',
      'picutre': 'picture',
      'imag': 'image',
      'img': 'image',
      'vedio': 'video',
      'vidoe': 'video',
      'musci': 'music',
      'dowload': 'download',
      'donwload': 'download',
      'donwloads': 'downloads',
      'folderes': 'folders',
      'foldr': 'folder',
      'direcotry': 'directory',
      'directoy': 'directory',
      'recnt': 'recent',
      'recnet': 'recent',
      'yestrday': 'yesterday',
      'todya': 'today',
      'tommorrow': 'tomorrow',
      'acces': 'access',
      'acess': 'access',
      'avialable': 'available',
      'availible': 'available',
      'chnage': 'change',
      'chagne': 'change',
      'lenght': 'length',
      'lengh': 'length',
      'widht': 'width',
      'hieght': 'height',
      'heigth': 'height',
      'occured': 'occurred',
      'occurence': 'occurrence',
      'untill': 'until',
      'usally': 'usually',
      'sucess': 'success',
      'succes': 'success',
      'fomrat': 'format',
      'formta': 'format',
      'conection': 'connection',
      'seperate': 'separate',
      'seprate': 'separate',
      'definately': 'definitely',
      'definatly': 'definitely',
      'necesary': 'necessary',
      'neccesary': 'necessary',
      'goverment': 'government',
      'gvernment': 'government',
      'enviroment': 'environment',
      'enviornment': 'environment',
      'privilege': 'privilege',
      'privelege': 'privilege',
      'recomend': 'recommend',
      'reccomend': 'recommend',
      'embarass': 'embarrass',
      'embaras': 'embarrass',
      'maintainance': 'maintenance',
      'maintenence': 'maintenance',
      'acheive': 'achieve',
      'refering': 'referring',
      'reffering': 'referring',
      'begining': 'beginning',
      'beleive': 'believe',
      'belive': 'believe',
      'occuring': 'occurring',
      'wich': 'which',
      'whihc': 'which',
      'thier': 'their',
      'ther': 'there',
      'teh': 'the',
      'taht': 'that',
      'thta': 'that',
      'waht': 'what',
      'whta': 'what',
      'becuase': 'because',
      'becase': 'because',
      'useing': 'using',
      'uesing': 'using',
      'sesonal': 'seasonal',
      'seaonal': 'seasonal',
    };
  }
}
