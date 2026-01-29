import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../utils/error_sanitizer.dart';
import '../utils/cross_platform_paths.dart';

/// Service for executing shell commands securely
///
/// This service provides controlled access to the host OS shell
/// with safety measures including:
/// - Command whitelisting
/// - Path restrictions
/// - Timeout limits
/// - Output truncation
class TerminalService {
  // Maximum output size in bytes (10KB)
  static const int maxOutputSize = 10 * 1024;

  // Default command timeout
  static const Duration defaultTimeout = Duration(seconds: 30);

  // Allowed commands (whitelist for safety)
  // These are read-only, safe commands
  static const List<String> allowedCommands = [
    // Windows commands
    'dir', 'type', 'findstr', 'where', 'tree', 'more',
    'find', 'echo', 'set', 'vol', 'wmic', 'fsutil',
    // Unix/Linux commands
    'ls', 'cat', 'grep', 'find', 'head', 'tail', 'less',
    'pwd', 'which', 'file', 'wc', 'df', 'du',
    // Cross-platform
    'cd', 'whoami', 'hostname',
  ];

  // Protected paths that cannot be accessed
  static const List<String> protectedPaths = [
    // Windows system directories
    r'C:\Windows\System32',
    r'C:\Windows\SysWOW64',
    r'C:\Program Files\Windows',
    // Unix system directories
    '/etc/passwd',
    '/etc/shadow',
    '/bin',
    '/sbin',
    '/usr/bin',
    '/usr/sbin',
  ];

  // Dangerous command patterns to block
  static const List<String> blockedPatterns = [
    'rm -rf',
    'del /f',
    'format',
    'mkfs',
    'shutdown',
    'reboot',
    'init',
    '> /dev',
    'dd if=',
    'chmod 777',
    'curl',
    'wget',
    'powershell',
    'pwsh', // PowerShell Core
    'cmd /c',
    'cmd.exe', // Direct cmd.exe invocation
    'cmd /k', // cmd with keep-open flag
    'wscript', // Windows Script Host
    'cscript', // Console-based script host
    'mshta', // HTML Application Host (can run scripts)
    'rundll32', // Can execute arbitrary code
    'regsvr32', // Can download and execute scripts
  ];

  /// Check if the platform is Windows
  bool get isWindows => Platform.isWindows;

  /// Check if the platform is macOS
  bool get isMacOS => Platform.isMacOS;

  /// Check if the platform is Linux
  bool get isLinux => Platform.isLinux;

  /// Check if the platform is Unix (macOS or Linux)
  bool get isUnix => !Platform.isWindows;

  /// Get the appropriate shell for the current platform
  String get shell => isWindows ? 'cmd.exe' : '/bin/bash';

  /// Get the shell name for logging
  String get shellName => isWindows ? 'cmd.exe' : '/bin/bash';

  /// Get shell arguments for command execution
  List<String> shellArgs(String command) =>
      isWindows ? ['/c', command] : ['-c', command];

  /// Execute a shell command with safety checks
  ///
  /// Returns a [CommandResult] with the output, error, and exit code.
  /// Throws [TerminalSecurityException] if the command is blocked.
  Future<CommandResult> execute(
    String command, {
    String? workingDirectory,
    Duration? timeout,
    bool allowPowerShellSearch = false,
  }) async {
    final allowSafePowerShellSearch =
        allowPowerShellSearch && _isSafePowerShellSearchCommand(command);
    if (!allowSafePowerShellSearch) {
      // Validate the command
      _validateCommand(command);

      // Check for protected paths in the command
      _validatePaths(command);
    }

    final effectiveTimeout = timeout ?? defaultTimeout;

    try {
      final process = await Process.start(
        shell,
        shellArgs(command),
        workingDirectory: workingDirectory,
        runInShell: false,
      );

      // Collect output with size limit
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      var totalSize = 0;
      var truncated = false;

      // Stream stdout
      final stdoutFuture = process.stdout
          .transform(const SystemEncoding().decoder)
          .forEach((chunk) {
            if (totalSize < maxOutputSize) {
              final remaining = maxOutputSize - totalSize;
              if (chunk.length <= remaining) {
                stdoutBuffer.write(chunk);
                totalSize += chunk.length;
              } else {
                stdoutBuffer.write(chunk.substring(0, remaining));
                totalSize = maxOutputSize;
                truncated = true;
              }
            }
          });

      // Stream stderr
      final stderrFuture = process.stderr
          .transform(const SystemEncoding().decoder)
          .forEach((chunk) {
            if (stderrBuffer.length < maxOutputSize) {
              stderrBuffer.write(chunk);
            }
          });

      // Wait for completion with timeout
      final exitCode = await process.exitCode.timeout(
        effectiveTimeout,
        onTimeout: () {
          process.kill(ProcessSignal.sigterm);
          throw TimeoutException(
            'Command timed out after ${effectiveTimeout.inSeconds} seconds',
          );
        },
      );

      await stdoutFuture;
      await stderrFuture;

      var finalExitCode = exitCode;
      var finalStderr = stderrBuffer.toString();

      // Special case for Windows 'dir' and 'findstr': exit code 1 often means
      // "no items found", which should be treated as success with empty output.
      if (isWindows && exitCode == 1) {
        final lowerCommand = command.toLowerCase();
        if (lowerCommand.startsWith('dir') ||
            lowerCommand.startsWith('findstr')) {
          finalExitCode = 0;
          // Only clear stderr if it's a "File Not Found" style message
          if (finalStderr.toLowerCase().contains('file not found')) {
            finalStderr = '';
          }
        }
      }

      return CommandResult(
        command: command,
        stdout: stdoutBuffer.toString(),
        stderr: ErrorSanitizer.sanitizeMessage(finalStderr),
        exitCode: finalExitCode,
        truncated: truncated,
        workingDirectory: workingDirectory,
      );
    } on TimeoutException catch (e) {
      return CommandResult(
        command: command,
        stdout: '',
        stderr: ErrorSanitizer.sanitizeException(e),
        exitCode: -1,
        truncated: false,
        timedOut: true,
        workingDirectory: workingDirectory,
      );
    } catch (e) {
      return CommandResult(
        command: command,
        stdout: '',
        stderr: ErrorSanitizer.sanitizeException(e),
        exitCode: -1,
        truncated: false,
        workingDirectory: workingDirectory,
      );
    }
  }

  /// Validate that the command uses only allowed commands
  void _validateCommand(String command) {
    // Check for encoded characters that could bypass validation
    // Hex encoding (0x41), URL encoding (%41), Unicode encoding (%u0041)
    if (RegExp(r'0x[0-9a-fA-F]{2}').hasMatch(command) ||
        RegExp(r'%[0-9a-fA-F]{2}').hasMatch(command) ||
        RegExp(r'%u[0-9a-fA-F]{4}').hasMatch(command)) {
      throw TerminalSecurityException(
        'Encoded characters not allowed in commands',
      );
    }

    // Check for Unicode homoglyph bypasses (characters that look like ASCII but aren't)
    // Only allow basic ASCII printable characters and common whitespace
    if (!RegExp(r'^[\x20-\x7E\t\n\r]*$').hasMatch(command)) {
      throw TerminalSecurityException(
        'Command contains non-ASCII characters that may be used for bypasses',
      );
    }

    // Check for blocked patterns
    final lowerCommand = command.toLowerCase();
    for (final pattern in blockedPatterns) {
      if (lowerCommand.contains(pattern.toLowerCase())) {
        throw TerminalSecurityException(
          'Blocked command pattern detected: $pattern',
        );
      }
    }

    // Extract the base command (first word)
    final parts = command.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      throw TerminalSecurityException('Empty command');
    }

    final baseCommand = parts.first.toLowerCase();
    // Remove path prefix if present (e.g., /usr/bin/ls -> ls)
    final commandName = baseCommand.split(RegExp(r'[/\\]')).last;

    // Also check for extension bypass (e.g., powershell.exe, cmd.com)
    final commandWithoutExt = commandName.replaceAll(
      RegExp(r'\.(exe|com|bat|cmd|ps1|vbs|js)$'),
      '',
    );

    // Check if command is in whitelist
    if (!allowedCommands.contains(commandName) &&
        !allowedCommands.contains(commandWithoutExt)) {
      throw TerminalSecurityException(
        'Command not allowed: $commandName. '
        'Allowed commands: ${allowedCommands.join(", ")}',
      );
    }
  }

  /// Validate that the command doesn't access protected paths
  void _validatePaths(String command) {
    final lowerCommand = command.toLowerCase();
    for (final protectedPath in protectedPaths) {
      if (lowerCommand.contains(protectedPath.toLowerCase())) {
        throw TerminalSecurityException(
          'Access to protected path denied: $protectedPath',
        );
      }
    }
  }

  bool _isSafePowerShellSearchCommand(String command) {
    if (!isWindows) return false;

    final normalized = command.trim();
    final lowerCommand = normalized.toLowerCase();

    if (!(lowerCommand.startsWith('powershell ') ||
        lowerCommand.startsWith('powershell.exe '))) {
      return false;
    }

    if (!lowerCommand.contains('-noprofile') ||
        !lowerCommand.contains('-noninteractive') ||
        !lowerCommand.contains('-command')) {
      return false;
    }

    if (!lowerCommand.contains('get-childitem') ||
        !lowerCommand.contains('-recurse')) {
      return false;
    }

    if (!lowerCommand.contains('select-object') ||
        !lowerCommand.contains('expandproperty fullname')) {
      return false;
    }

    if (RegExp(r'[;&]').hasMatch(command)) {
      return false;
    }

    if (command.contains('`') || command.contains(r'$')) {
      return false;
    }

    if ('|'.allMatches(command).length > 1) {
      return false;
    }

    const forbiddenTokens = [
      'invoke-expression',
      'iex',
      'start-process',
      'remove-item',
      'set-item',
      'add-type',
      'new-object',
      'invoke-webrequest',
      'curl',
      'wget',
      'iwr',
      'irm',
      'rm ',
      'del ',
      'cmd.exe',
      'cmd /c',
      '-encodedcommand',
    ];

    for (final token in forbiddenTokens) {
      if (lowerCommand.contains(token)) {
        return false;
      }
    }

    return true;
  }

  /// List available drives on the system
  Future<List<DriveInfo>> listDrives() async {
    if (isWindows) {
      // Use PowerShell for safer, more reliable drive listing on modern Windows
      final result = await _runCommand(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          'Get-PSDrive -PSProvider FileSystem | Select-Object Name,DisplayRoot,Free,Used | ConvertTo-Json',
        ],
        timeout: const Duration(seconds: 10),
      );

      final parsed =
          result.success ? _parseWindowsDrivesPs(result.stdout) : <DriveInfo>[];
      if (parsed.isNotEmpty) return parsed;

      final rootPaths = await CrossPlatformPaths.getRootPaths();
      return rootPaths
          .map(
            (path) => DriveInfo(
              path: path,
              description: path.isNotEmpty
                  ? 'Local Disk (${path[0].toUpperCase()}:)'
                  : 'Local Disk',
              freeSpace: null,
              totalSpace: null,
            ),
          )
          .toList();
    } else {
      // Use cross-platform root paths
      final rootPaths = CrossPlatformPaths.rootPaths;
      final drives = <DriveInfo>[];

      for (final path in rootPaths) {
        drives.add(
          DriveInfo(
            path: path,
            description: path == '/' ? 'Root' : 'Mount: $path',
            freeSpace: null,
            totalSpace: null,
          ),
        );
      }

      // Try to get more info from df if available
      try {
        final result = await execute('df -h');
        if (result.success) {
          final dfDrives = _parseUnixDrives(result.stdout);
          // Merge information
          for (final dfDrive in dfDrives) {
            final existing = drives.indexWhere((d) => d.path == dfDrive.path);
            if (existing >= 0) {
              drives[existing] = dfDrive;
            } else {
              drives.add(dfDrive);
            }
          }
        }
      } catch (_) {}

      return drives;
    }
  }

  List<DriveInfo> _parseWindowsDrivesPs(String output) {
    final drives = <DriveInfo>[];
    if (output.trim().isEmpty) return drives;

    try {
      final decoded = jsonDecode(output);
      if (decoded is List) {
        for (final item in decoded) {
          _addDriveFromJson(drives, item);
        }
      } else if (decoded is Map) {
        _addDriveFromJson(drives, decoded);
      }
    } catch (e) {
      // Fallback for non-JSON or malformed output
      final lines = output.split(RegExp(r'\r\n|\r|\n'));
      for (final line in lines) {
        if (line.contains(':')) {
          final driveLetter = line.trim().split(':').first;
          drives.add(
            DriveInfo(
              path: '$driveLetter:\\',
              description: 'Local Disk ($driveLetter:)',
              freeSpace: null,
              totalSpace: null,
            ),
          );
        }
      }
    }

    return drives;
  }

  void _addDriveFromJson(List<DriveInfo> drives, dynamic item) {
    if (item is! Map) return;
    final name = item['Name']?.toString();
    if (name == null) return;

    final path = '$name:\\';
    final free = item['Free'] is num ? (item['Free'] as num).toInt() : null;
    final used = item['Used'] is num ? (item['Used'] as num).toInt() : null;
    final total = (free != null && used != null) ? free + used : null;

    drives.add(
      DriveInfo(
        path: path,
        description: 'Local Disk ($name:)',
        freeSpace: free,
        totalSpace: total,
      ),
    );
  }

  List<DriveInfo> _parseUnixDrives(String output) {
    final drives = <DriveInfo>[];
    final lines = output.split('\n').skip(1); // Skip header

    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 6) {
        drives.add(
          DriveInfo(
            path: parts.last,
            description: parts.first,
            freeSpace: null, // Would need parsing
            totalSpace: null,
          ),
        );
      }
    }

    return drives;
  }

  /// Find files matching a pattern
  ///
  /// SECURITY: Pattern and directory are sanitized to prevent command injection.
  Future<CommandResult> findFiles(
    String pattern, {
    String? directory,
    bool recursive = true,
  }) async {
    // Sanitize inputs to prevent command injection
    var sanitizedPattern = _sanitizeArgument(pattern);
    final searchDir = directory != null
        ? _sanitizeArgument(directory)
        : (isWindows ? 'C:\\' : '/');

    if (isWindows) {
      // Auto-wildcard if no wildcards are present to make search more intuitive
      if (!sanitizedPattern.contains('*') && !sanitizedPattern.contains('?')) {
        sanitizedPattern = '*$sanitizedPattern*';
      }
      final recurseFlag = recursive ? '/S' : '';
      return execute('dir /B $recurseFlag "$searchDir\\$sanitizedPattern"');
    } else {
      final depthFlag = recursive ? '' : '-maxdepth 1';
      return execute('find "$searchDir" $depthFlag -name "$sanitizedPattern"');
    }
  }

  /// Deep search using PowerShell for better recursive search
  ///
  /// This method bypasses the normal command validation because it uses
  /// a fully controlled PowerShell command with sanitized inputs.
  /// It has a longer timeout (2 minutes) for deep directory searches.
  Future<CommandResult> deepSearch(
    String pattern, {
    String? directory,
    bool foldersOnly = false,
  }) async {
    if (!isWindows) {
      // Fall back to regular find on non-Windows
      return findFiles(pattern, directory: directory, recursive: true);
    }

    // Validate and sanitize inputs with additional checks for PowerShell
    _validatePowerShellInput(pattern);
    final searchDir = directory != null
        ? _validatePowerShellPath(directory)
        : 'C:\\';

    // Sanitize pattern by removing ALL special characters that could be used in injection
    // Only keep alphanumeric, spaces, hyphens, underscores, dots, and wildcards
    var sanitizedPattern = pattern.replaceAll(RegExp(r'[^\w\s\-\.\*\?]'), '');

    // Handle whitespace: create multiple search patterns
    // "Gemma 2" -> try "gemma2", "gemma*2", "gemma 2"
    final patterns = <String>[];

    // Original pattern (with wildcards)
    if (!sanitizedPattern.contains('*') && !sanitizedPattern.contains('?')) {
      patterns.add('*$sanitizedPattern*');
    } else {
      patterns.add(sanitizedPattern);
    }

    // Remove spaces version
    final noSpaces = sanitizedPattern.replaceAll(' ', '');
    if (noSpaces != sanitizedPattern && !noSpaces.contains('*')) {
      patterns.add('*$noSpaces*');
    }

    // Replace spaces with wildcards version
    final spacesToWildcards = sanitizedPattern.replaceAll(' ', '*');
    if (spacesToWildcards != sanitizedPattern &&
        !patterns.contains('*$spacesToWildcards*')) {
      patterns.add('*$spacesToWildcards*');
    }

    // Build PowerShell command using encoded arguments instead of string interpolation
    final itemType = foldersOnly ? '-Directory' : '';

    // Use argument list approach instead of inline script for better security
    // Build filters as separate arguments
    final args = <String>[
      '-NoProfile',
      '-NonInteractive',
    ];

    // Build the script with pattern literals instead of variables
    final patternLiterals = patterns
        .map((p) => "'${_escapePowerShellArgument(p)}'")
        .join(', ');

    final psCommand =
        '''
\$filters = @($patternLiterals)
\$results = @()
foreach (\$f in \$filters) {
  \$results += Get-ChildItem -Path '$searchDir' -Filter \$f $itemType -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}
\$results | Select-Object -First 50 -Unique
''';

    args.add('-Command');
    args.add(psCommand);

    try {
      final process = await Process.start(
        'powershell.exe',
        args,
        runInShell: false,
      );

      // Collect output with size limit
      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      var totalSize = 0;
      var truncated = false;

      // Stream stdout
      final stdoutFuture = process.stdout
          .transform(const SystemEncoding().decoder)
          .forEach((chunk) {
            if (totalSize < maxOutputSize) {
              final remaining = maxOutputSize - totalSize;
              if (chunk.length <= remaining) {
                stdoutBuffer.write(chunk);
                totalSize += chunk.length;
              } else {
                stdoutBuffer.write(chunk.substring(0, remaining));
                totalSize = maxOutputSize;
                truncated = true;
              }
            }
          });

      // Stream stderr
      final stderrFuture = process.stderr
          .transform(const SystemEncoding().decoder)
          .forEach((chunk) {
            if (stderrBuffer.length < maxOutputSize) {
              stderrBuffer.write(chunk);
            }
          });

      // Wait for completion with 2-minute timeout for deep searches
      final exitCode = await process.exitCode.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          process.kill(ProcessSignal.sigterm);
          throw TimeoutException('Deep search timed out after 2 minutes');
        },
      );

      await stdoutFuture;
      await stderrFuture;

      return CommandResult(
        command: 'deep_search: $pattern in $searchDir',
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        exitCode: exitCode,
        truncated: truncated,
      );
    } on TimeoutException catch (e) {
      return CommandResult(
        command: 'deep_search: $pattern in $searchDir',
        stdout: '',
        stderr: 'Timeout: ${e.message}',
        exitCode: -1,
        truncated: false,
        timedOut: true,
      );
    } catch (e) {
      return CommandResult(
        command: 'deep_search: $pattern in $searchDir',
        stdout: '',
        stderr: 'Error: $e',
        exitCode: -1,
        truncated: false,
      );
    }
  }

  // ==========================================================================
  // CROSS-PLATFORM SEARCH METHODS
  // ==========================================================================

  /// Cross-platform deep search that works on Windows, macOS, and Linux
  ///
  /// Uses platform-specific optimizations:
  /// - Windows: PowerShell with Get-ChildItem
  /// - macOS: mdfind (Spotlight) with fallback to find
  /// - Linux: locate with fallback to find
  Future<CommandResult> crossPlatformSearch(
    String pattern, {
    String? directory,
    bool foldersOnly = false,
    int maxResults = 1000,
    int timeoutSeconds = 60,
  }) async {
    final searchDir = directory ?? CrossPlatformPaths.rootPath;
    final expandedDir = CrossPlatformPaths.expand(searchDir);

    // Verify directory exists
    if (!Directory(expandedDir).existsSync()) {
      return CommandResult(
        command: 'search: $pattern in $searchDir',
        stdout: '',
        stderr: 'Directory does not exist: $expandedDir',
        exitCode: 1,
        truncated: false,
      );
    }

    if (isWindows) {
      return _searchWindowsCrossPlatform(
        pattern,
        expandedDir,
        foldersOnly,
        maxResults,
        timeoutSeconds,
      );
    } else if (isMacOS) {
      return _searchMacOSCrossPlatform(
        pattern,
        expandedDir,
        foldersOnly,
        maxResults,
        timeoutSeconds,
      );
    } else {
      return _searchLinuxCrossPlatform(
        pattern,
        expandedDir,
        foldersOnly,
        maxResults,
        timeoutSeconds,
      );
    }
  }

  /// Windows file search using PowerShell
  Future<CommandResult> _searchWindowsCrossPlatform(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    try {
      final patterns = _buildSearchPatterns(pattern);

      // Build PowerShell command
      final escapedDir = directory
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"');
      final itemType = foldersOnly ? 'Directory' : 'File';
      final patternLiterals = patterns
          .map((p) => "'${_escapePowerShellArgument(p)}'")
          .join(', ');

      final attempts = <int>[15, 30];
      CommandResult? lastResult;

      for (final depth in attempts) {
        final psScript =
            '''
\$filters = @($patternLiterals)
\$results = @()
foreach (\$f in \$filters) {
  \$results += Get-ChildItem -Path "$escapedDir" -Filter \$f -$itemType -Recurse -Force -ErrorAction SilentlyContinue -Depth $depth |
    Select-Object -First $maxResults -ExpandProperty FullName
}
\$results | Select-Object -First $maxResults -Unique |
  ForEach-Object { Write-Output \$_.Replace("\$env:USERPROFILE", "~") }
''';

        lastResult = await _withRetries(
          () => _executePowerShell(
            psScript,
            Duration(seconds: timeoutSeconds),
          ),
          maxAttempts: 2,
        );

        if (lastResult.success && lastResult.stdout.trim().isNotEmpty) {
          return lastResult;
        }
      }

      final fallbackScript =
          '''
\$filters = @($patternLiterals)
\$results = @()
foreach (\$f in \$filters) {
  \$results += Get-ChildItem -LiteralPath "$escapedDir" -$itemType -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { \$_.Name -like \$f } |
    Select-Object -First $maxResults -ExpandProperty FullName
}
\$results | Select-Object -First $maxResults -Unique |
  ForEach-Object { Write-Output \$_.Replace("\$env:USERPROFILE", "~") }
''';

      lastResult = await _withRetries(
        () => _executePowerShell(
          fallbackScript,
          Duration(seconds: timeoutSeconds),
        ),
        maxAttempts: 2,
      );

      if (lastResult.success && lastResult.stdout.trim().isNotEmpty) {
        return lastResult;
      }

      return lastResult;
    } catch (e) {
      return CommandResult(
        command: 'search_windows: $pattern in $directory',
        stdout: '',
        stderr: 'Search failed: $e',
        exitCode: -1,
        truncated: false,
      );
    }
  }

  /// macOS file search using mdfind (Spotlight) or find
  Future<CommandResult> _searchMacOSCrossPlatform(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    // First try mdfind (Spotlight) for faster results
    try {
      final mdfindPattern = foldersOnly
          ? 'kMDItemContentType == "public.folder" && name == "$pattern"c'
          : 'name == "$pattern"c';

      final result = await _runCommand(
        'mdfind',
        ['-onlyin', directory, mdfindPattern],
        timeout: Duration(seconds: timeoutSeconds ~/ 2),
      );

      if (result.success && result.stdout.trim().isNotEmpty) {
        // Limit results
        final lines = result.stdout
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .take(maxResults)
            .toList();
        return CommandResult(
          command: 'search_macos: $pattern in $directory',
          stdout: lines.join('\n'),
          stderr: '',
          exitCode: 0,
          truncated: false,
        );
      }
    } catch (_) {
      // Fall through to find command
    }

    // Fallback to find command
    return _searchUnixFindCrossPlatform(
      pattern,
      directory,
      foldersOnly,
      maxResults,
      timeoutSeconds,
    );
  }

  /// Linux file search using find or locate
  Future<CommandResult> _searchLinuxCrossPlatform(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    // First try locate for fast results
    try {
      final result = await _runCommand(
        'locate',
        ['-i', '-l', '$maxResults', pattern],
        timeout: Duration(seconds: timeoutSeconds ~/ 3),
      );

      if (result.success && result.stdout.trim().isNotEmpty) {
        // Filter to directory if specified
        final lines = result.stdout
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .where((l) => l.startsWith(directory))
            .take(maxResults)
            .toList();

        if (lines.isNotEmpty) {
          return CommandResult(
            command: 'search_linux: $pattern in $directory',
            stdout: lines.join('\n'),
            stderr: '',
            exitCode: 0,
            truncated: false,
          );
        }
      }
    } catch (_) {
      // Fall through to find
    }

    return _searchUnixFindCrossPlatform(
      pattern,
      directory,
      foldersOnly,
      maxResults,
      timeoutSeconds,
    );
  }

  /// Common Unix find command
  Future<CommandResult> _searchUnixFindCrossPlatform(
    String pattern,
    String directory,
    bool foldersOnly,
    int maxResults,
    int timeoutSeconds,
  ) async {
    try {
      final typeArg = foldersOnly ? '-type d' : '-type f';
      final command =
          'find "$directory" $typeArg -iname "$pattern" -mount 2>/dev/null | head -n $maxResults';

      return await execute(command, timeout: Duration(seconds: timeoutSeconds));
    } catch (e) {
      return CommandResult(
        command: 'search_unix: $pattern in $directory',
        stdout: '',
        stderr: 'Search failed: $e',
        exitCode: -1,
        truncated: false,
      );
    }
  }

  /// Execute PowerShell command with proper error handling
  Future<CommandResult> _executePowerShell(
    String script,
    Duration timeout,
  ) async {
    try {
      final process = await Process.start(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-Command', script],
        runInShell: false,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();
      var totalSize = 0;
      var truncated = false;

      final stdoutFuture = process.stdout
          .transform(const SystemEncoding().decoder)
          .forEach((chunk) {
            if (totalSize < maxOutputSize) {
              final remaining = maxOutputSize - totalSize;
              if (chunk.length <= remaining) {
                stdoutBuffer.write(chunk);
                totalSize += chunk.length;
              } else {
                stdoutBuffer.write(chunk.substring(0, remaining));
                totalSize = maxOutputSize;
                truncated = true;
              }
            }
          });

      final stderrFuture = process.stderr
          .transform(const SystemEncoding().decoder)
          .forEach((chunk) {
            if (stderrBuffer.length < maxOutputSize) {
              stderrBuffer.write(chunk);
            }
          });

      final exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill(ProcessSignal.sigterm);
          throw TimeoutException('PowerShell command timed out');
        },
      );

      await stdoutFuture;
      await stderrFuture;

      return CommandResult(
        command: 'powershell',
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        exitCode: exitCode,
        truncated: truncated,
      );
    } on TimeoutException catch (e) {
      return CommandResult(
        command: 'powershell',
        stdout: '',
        stderr: 'Timeout: ${e.message}',
        exitCode: -1,
        truncated: false,
        timedOut: true,
      );
    } catch (e) {
      return CommandResult(
        command: 'powershell',
        stdout: '',
        stderr: 'Error: $e',
        exitCode: -1,
        truncated: false,
      );
    }
  }

  /// Run a command directly (bypassing shell validation for trusted commands)
  Future<CommandResult> _runCommand(
    String command,
    List<String> args, {
    Duration? timeout,
  }) async {
    final process = await Process.start(
      command,
      args,
      runInShell: false,
    );

    final stdout = <String>[];
    final stderr = <String>[];

    final effectiveTimeout = timeout ?? const Duration(seconds: 30);
    var timedOut = false;

    // Watch for timeout
    final timer = Timer(effectiveTimeout, () {
      timedOut = true;
      process.kill();
    });

    // Stream subscriptions
    final sub1 = process.stdout.transform(utf8.decoder).listen(stdout.add);
    final sub2 = process.stderr.transform(utf8.decoder).listen(stderr.add);

    // Wait for process to complete
    final exitCode = await process.exitCode;

    timer.cancel();
    await sub1.cancel();
    await sub2.cancel();

    if (timedOut) {
      return CommandResult(
        command: command,
        stdout: stdout.join(),
        stderr: 'Command timed out after ${effectiveTimeout.inSeconds} seconds',
        exitCode: -1,
        truncated: false,
        timedOut: true,
      );
    }

    return CommandResult(
      command: command,
      stdout: stdout.join(),
      stderr: stderr.join(),
      exitCode: exitCode,
      truncated: false,
    );
  }

  /// Get platform-specific special folder paths
  Map<String, String> getSpecialFolders() {
    return CrossPlatformPaths.specialFolders;
  }

  /// Get a specific special folder by name
  String? getSpecialFolder(String name) {
    return CrossPlatformPaths.getSpecialFolder(name);
  }

  /// Check if a path refers to a hidden file/folder
  bool isHiddenPath(String path) {
    return CrossPlatformPaths.isHidden(path);
  }

  /// Resolve a symlink to its target
  Future<String?> resolveSymlink(String path) async {
    final expandedPath = CrossPlatformPaths.expand(path);
    try {
      final link = Link(expandedPath);
      if (link.existsSync()) {
        return await link.target();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// List hidden files in a directory
  Future<List<String>> listHiddenFiles(
    String path, {
    bool includeSystem = false,
  }) async {
    final expandedPath = CrossPlatformPaths.expand(path);
    final dir = Directory(expandedPath);

    if (!dir.existsSync()) {
      return [];
    }

    try {
      final entities = dir.listSync();
      final hiddenFiles = <String>[];

      for (final entity in entities) {
        final name = entity.path.split(RegExp(r'[\\/]')).last;

        // Skip system files unless requested
        if (!includeSystem) {
          if (isWindows) {
            if (name.toLowerCase() == 'system volume information' ||
                name.toLowerCase().startsWith(r'$')) {
              continue;
            }
          } else {
            if (name == '.' || name == '..') {
              continue;
            }
          }
        }

        if (CrossPlatformPaths.isHidden(entity.path)) {
          hiddenFiles.add(entity.path);
        }
      }

      return hiddenFiles.take(100).toList();
    } catch (_) {
      return [];
    }
  }

  /// Search file contents for a pattern (grep-like)
  ///
  /// SECURITY: Pattern and path are sanitized to prevent command injection.
  Future<CommandResult> grepSearch(
    String pattern,
    String path, {
    bool recursive = true,
    bool ignoreCase = true,
  }) async {
    // Sanitize inputs to prevent command injection
    final sanitizedPattern = _sanitizeArgument(pattern);
    final sanitizedPath = _sanitizeArgument(path);

    if (isWindows) {
      final recurseFlag = recursive ? '/S' : '';
      final caseFlag = ignoreCase ? '/I' : '';
      return execute(
        'findstr $recurseFlag $caseFlag "$sanitizedPattern" "$sanitizedPath"',
      );
    } else {
      final recurseFlag = recursive ? '-r' : '';
      final caseFlag = ignoreCase ? '-i' : '';
      return execute(
        'grep $recurseFlag $caseFlag "$sanitizedPattern" "$sanitizedPath"',
      );
    }
  }

  /// Read file contents
  Future<CommandResult> readFile(String path) async {
    final sanitizedPath = _sanitizeArgument(path);
    if (isWindows) {
      return execute('type "$sanitizedPath"');
    } else {
      return execute('cat "$sanitizedPath"');
    }
  }

  /// List directory contents
  Future<CommandResult> listDirectory(
    String path, {
    bool detailed = true,
  }) async {
    final sanitizedPath = _sanitizeArgument(path);
    if (isWindows) {
      return _withRetries(
        () => execute('dir /A ${detailed ? '' : '/B'} "$sanitizedPath"'),
      );
    } else {
      final flags = detailed ? '-la' : '-a';
      return _withRetries(
        () => execute('ls $flags "$sanitizedPath"'),
      );
    }
  }

  /// Validate PowerShell-specific input for dangerous patterns
  void _validatePowerShellInput(String input) {
    // Check for PowerShell-specific injection patterns
    final dangerousPatterns = [
      r'$', // Variable expansion
      r'`', // Escape character
      r'\$', // Command substitution
      r'@\(', // Array subexpression
      r'\$\{', // Script block start
      r'\|', // Pipe
      r';', // Command separator
      r'&', // Call operator
      r'>', // Redirect
      r'<', // Redirect
      r'\.\.', // Parent path (double-dot)
    ];

    for (final pattern in dangerousPatterns) {
      if (input.contains(RegExp(pattern))) {
        throw TerminalSecurityException(
          'PowerShell input contains dangerous pattern: $pattern',
        );
      }
    }

    // Only allow alphanumeric, spaces, hyphens, underscores, dots, and wildcards
    if (!RegExp(r'^[\w\s\-\.\*\?]*$').hasMatch(input)) {
      throw TerminalSecurityException(
        'PowerShell input contains invalid characters',
      );
    }
  }

  /// Validate and sanitize a PowerShell path
  String _validatePowerShellPath(String path) {
    // Remove any null bytes
    var sanitized = path.replaceAll('\x00', '');

    // Only allow valid Windows path characters
    // Allow: letters, numbers, spaces, hyphens, underscores, dots, colons, backslashes, forward slashes
    if (!RegExp(r'^[a-zA-Z]:\\[\w\s\-\./\\]*$').hasMatch(sanitized) &&
        !RegExp(r'^[\w\s\-\./\\]+$').hasMatch(sanitized)) {
      throw TerminalSecurityException(
        'Invalid path format: $path',
      );
    }

    // Check for path traversal
    if (sanitized.contains('..')) {
      throw TerminalSecurityException(
        'Path traversal not allowed',
      );
    }

    return sanitized;
  }

  /// Escape a PowerShell argument for safe use in single-quoted strings
  String _escapePowerShellArgument(String arg) {
    // In PowerShell single-quoted strings, only single quotes need escaping (by doubling)
    // Remove any other potentially dangerous characters first
    final cleaned = arg.replaceAll(RegExp(r"[^\w\s\-\.\*\?\[\]]"), '');
    return cleaned.replaceAll("'", "''");
  }

  /// Sanitize a command argument to prevent injection attacks
  ///
  /// Removes or escapes special shell characters that could be used for injection:
  /// - Semicolons, pipes, backticks, $(), etc.
  /// - Null bytes
  /// - Control characters
  static String _sanitizeArgument(String arg) {
    // Remove null bytes
    var sanitized = arg.replaceAll('\x00', '');

    // Remove control characters except newline and tab
    sanitized = sanitized.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'),
      '',
    );

    // Remove or escape dangerous shell characters
    // These could be used for command chaining/injection
    const dangerousChars = [
      ';', // Command separator
      '|', // Pipe
      '&', // Background/AND
      '`', // Command substitution
      '\$', // Variable expansion
      '<', // Redirect
      '>', // Redirect
      '"', // Double quote (prevents shell breakout)
      '\n', // Newline (command separator)
      '\r', // Carriage return
    ];

    for (final char in dangerousChars) {
      sanitized = sanitized.replaceAll(char, '');
    }

    // Remove command substitution patterns
    sanitized = sanitized.replaceAll(RegExp(r'\$\([^)]*\)'), '');
    sanitized = sanitized.replaceAll(RegExp(r'\$\{[^}]*\}'), '');

    // Limit length to prevent buffer issues
    if (sanitized.length > 4096) {
      sanitized = sanitized.substring(0, 4096);
    }

    return sanitized;
  }

  List<String> _buildSearchPatterns(String pattern) {
    var sanitizedPattern = pattern.replaceAll(RegExp(r'[^\w\s\-\.\*\?]'), '');
    if (sanitizedPattern.isEmpty) sanitizedPattern = '*';

    final patterns = <String>{};
    patterns.add(sanitizedPattern);

    if (!sanitizedPattern.contains('*') && !sanitizedPattern.contains('?')) {
      patterns.add('*$sanitizedPattern*');
    }

    final noSpaces = sanitizedPattern.replaceAll(' ', '');
    if (noSpaces != sanitizedPattern && !noSpaces.contains('*')) {
      patterns.add('*$noSpaces*');
    }

    final spacesToWildcards = sanitizedPattern.replaceAll(' ', '*');
    if (spacesToWildcards != sanitizedPattern) {
      patterns.add(spacesToWildcards);
    }

    return patterns.toList();
  }

  Future<CommandResult> _withRetries(
    Future<CommandResult> Function() action, {
    int maxAttempts = 2,
    Duration delay = const Duration(milliseconds: 350),
  }) async {
    CommandResult? lastResult;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      lastResult = await action();

      if (lastResult.success) {
        return lastResult;
      }

      if (!lastResult.timedOut && lastResult.exitCode != -1) {
        return lastResult;
      }

      if (attempt < maxAttempts) {
        await Future.delayed(delay * attempt);
      }
    }

    return lastResult!;
  }
}

/// Result of a command execution
class CommandResult {
  final String command;
  final String stdout;
  final String stderr;
  final int exitCode;
  final bool truncated;
  final bool timedOut;
  final String? workingDirectory;

  CommandResult({
    required this.command,
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    this.truncated = false,
    this.timedOut = false,
    this.workingDirectory,
  });

  bool get success => exitCode == 0;

  /// Get combined output (stdout + stderr if error)
  String get output {
    if (success) return truncated ? '$stdout\n[Output truncated]' : stdout;
    return stderr.isNotEmpty ? stderr : stdout;
  }

  Map<String, dynamic> toJson() => {
    'command': command,
    'stdout': stdout,
    'stderr': stderr,
    'exitCode': exitCode,
    'success': success,
    'truncated': truncated,
    'timedOut': timedOut,
    'workingDirectory': workingDirectory,
  };
}

/// Information about a drive/filesystem
class DriveInfo {
  final String path;
  final String description;
  final int? freeSpace;
  final int? totalSpace;

  DriveInfo({
    required this.path,
    required this.description,
    this.freeSpace,
    this.totalSpace,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'description': description,
    'freeSpace': freeSpace,
    'totalSpace': totalSpace,
  };
}

/// Exception for security violations
class TerminalSecurityException implements Exception {
  final String message;

  TerminalSecurityException(this.message);

  @override
  String toString() => 'TerminalSecurityException: $message';
}

/// Timeout exception for commands
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
