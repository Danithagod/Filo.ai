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
    'cmd /c',
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

      return CommandResult(
        command: command,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
        exitCode: exitCode,
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

    // Check if command is in whitelist
    if (!allowedCommands.contains(commandName)) {
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
      final parts = line.trim().split(RegExp(r'\s{2,}'));
      if (parts.isNotEmpty && parts.first.contains(':')) {
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
  Future<CommandResult> findFiles(
    String pattern, {
    String? directory,
    bool recursive = true,
  }) async {
    final searchDir = directory ?? (isWindows ? 'C:\\' : '/');

    if (isWindows) {
      final recurseFlag = recursive ? '/S' : '';
      return execute('where $recurseFlag /R "$searchDir" "$pattern"');
    } else {
      final depthFlag = recursive ? '' : '-maxdepth 1';
      return execute('find "$searchDir" $depthFlag -name "$pattern"');
    }
  }

  /// Search file contents for a pattern (grep-like)
  Future<CommandResult> grepSearch(
    String pattern,
    String path, {
    bool recursive = true,
    bool ignoreCase = true,
  }) async {
    if (isWindows) {
      final recurseFlag = recursive ? '/S' : '';
      final caseFlag = ignoreCase ? '/I' : '';
      return execute('findstr $recurseFlag $caseFlag "$pattern" "$path"');
    } else {
      final recurseFlag = recursive ? '-r' : '';
      final caseFlag = ignoreCase ? '-i' : '';
      return execute('grep $recurseFlag $caseFlag "$pattern" "$path"');
    }
  }

  /// Read file contents
  Future<CommandResult> readFile(String path) async {
    if (isWindows) {
      return execute('type "$path"');
    } else {
      return execute('cat "$path"');
    }
  }

  /// List directory contents
  Future<CommandResult> listDirectory(
    String path, {
    bool detailed = true,
  }) async {
    if (isWindows) {
      return execute('dir ${detailed ? '' : '/B'} "$path"');
    } else {
      return execute('ls ${detailed ? '-la' : ''} "$path"');
    }
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
