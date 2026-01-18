import 'dart:io';

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

  /// Get the appropriate shell for the current platform
  String get shell => isWindows ? 'cmd.exe' : '/bin/sh';

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
  }) async {
    // Validate the command
    _validateCommand(command);

    // Check for protected paths in the command
    _validatePaths(command);

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
        stderr: finalStderr,
        exitCode: finalExitCode,
        truncated: truncated,
        workingDirectory: workingDirectory,
      );
    } on TimeoutException catch (e) {
      return CommandResult(
        command: command,
        stdout: '',
        stderr: 'Command timed out: ${e.message}',
        exitCode: -1,
        truncated: false,
        timedOut: true,
        workingDirectory: workingDirectory,
      );
    } catch (e) {
      return CommandResult(
        command: command,
        stdout: '',
        stderr: 'Failed to execute command: $e',
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

  /// List available drives on the system
  Future<List<DriveInfo>> listDrives() async {
    if (isWindows) {
      final result = await execute(
        'wmic logicaldisk get caption,description,freespace,size',
      );
      return _parseWindowsDrives(result.stdout);
    } else {
      final result = await execute('df -h');
      return _parseUnixDrives(result.stdout);
    }
  }

  List<DriveInfo> _parseWindowsDrives(String output) {
    final drives = <DriveInfo>[];
    final lines = output.split('\n').skip(1); // Skip header

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.trim().split(RegExp(r'\s{2,}'));
      if (parts.isNotEmpty &&
          (parts.first.contains(':') || parts.first.startsWith('/'))) {
        drives.add(
          DriveInfo(
            path: parts.first,
            description: parts.length > 1 ? parts[1] : '',
            freeSpace: parts.length > 2 ? int.tryParse(parts[2]) : null,
            totalSpace: parts.length > 3 ? int.tryParse(parts[3]) : null,
          ),
        );
      }
    }

    return drives;
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

    // Sanitize inputs
    var sanitizedPattern = _sanitizeArgument(pattern);
    final searchDir = directory != null ? _sanitizeArgument(directory) : 'C:\\';

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

    // Build PowerShell command that tries all patterns
    final itemType = foldersOnly ? '-Directory' : '';

    // Create a PowerShell script that tries each pattern
    final psCommand =
        '''
\$results = @()
foreach (\$filter in @(${patterns.map((p) => '"$p"').join(', ')})) {
  \$results += Get-ChildItem -Path "$searchDir" -Filter \$filter $itemType -Recurse -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}
\$results | Select-Object -First 50 -Unique
''';

    try {
      final process = await Process.start(
        'powershell.exe',
        ['-NoProfile', '-NonInteractive', '-Command', psCommand],
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
      return execute('dir ${detailed ? '' : '/B'} "$sanitizedPath"');
    } else {
      return execute('ls ${detailed ? '-la' : ''} "$sanitizedPath"');
    }
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
