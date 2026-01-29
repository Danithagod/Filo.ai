import 'openrouter_client.dart';

/// Tools available for the AI search agent
class SearchTools {
  // Tool Names
  static const String searchIndex = 'search_index';
  static const String searchTerminal = 'search_terminal';
  static const String readFile = 'read_file';
  static const String getFileInfo = 'get_file_info';
  static const String listDirectory = 'list_directory';
  static const String getSpecialPaths = 'get_special_paths';
  static const String listHiddenFiles = 'list_hidden_files';
  static const String resolveSymlink = 'resolve_symlink';
  static const String getDrives = 'get_drives';
  static const String deepSearch = 'deep_search';
  static const String runCommand = 'run_command';

  // Parameter definitions
  static List<Tool> get allTools => [
    Tool(
      function: ToolFunction(
        name: searchIndex,
        description:
            'Search the semantic document index for files matching an embedding or keywords.',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {'type': 'string', 'description': 'Search query text'},
            'limit': {
              'type': 'integer',
              'description': 'Max results (default 10)',
            },
            'filters': {
              'type': 'object',
              'description': 'Optional filters like date, size, type',
              'properties': {
                'min_size': {'type': 'integer'},
                'max_size': {'type': 'integer'},
                'extensions': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
                'date_from': {'type': 'string'},
                'date_to': {'type': 'string'},
              },
            },
          },
          'required': ['query'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: getDrives,
        description: 'List available drives on the system.',
        parameters: {
          'type': 'object',
          'properties': {},
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: deepSearch,
        description:
            'Deep search for files/folders using the native OS search (PowerShell on Windows).',
        parameters: {
          'type': 'object',
          'properties': {
            'pattern': {
              'type': 'string',
              'description': 'File or folder name/pattern',
            },
            'directory': {
              'type': 'string',
              'description': 'Directory to search in (defaults to root)',
            },
            'folders_only': {
              'type': 'boolean',
              'description': 'Search for folders only',
            },
          },
          'required': ['pattern'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: runCommand,
        description:
            'Execute a read-only shell command on the host system (dir, ls, find, grep, etc.).',
        parameters: {
          'type': 'object',
          'properties': {
            'command': {
              'type': 'string',
              'description': 'The shell command to execute',
            },
            'working_directory': {
              'type': 'string',
              'description': 'Optional working directory for the command',
            },
          },
          'required': ['command'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: searchTerminal,
        description:
            'Search for files in the filesystem using patterns or commands.',
        parameters: {
          'type': 'object',
          'properties': {
            'pattern': {
              'type': 'string',
              'description': 'File pattern (e.g. *.pdf) or search term',
            },
            'path': {
              'type': 'string',
              'description':
                  'Directory path to search in (defaults to finding drives)',
            },
            'recursive': {
              'type': 'boolean',
              'description': 'Whether to search recursively',
            },
            'folders_only': {
              'type': 'boolean',
              'description': 'Search for folders only',
            },
          },
          'required': ['pattern'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: readFile,
        description: 'Read the contents of a text file (first N lines).',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Absolute path to the file',
            },
            'lines': {
              'type': 'integer',
              'description': 'Number of lines to read (default 100)',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: getFileInfo,
        description: 'Get metadata (size, dates) for a file.',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Absolute path to the file',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: 'list_directory',
        description: 'List the contents of a directory.',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Absolute path to the directory',
            },
          },
          'required': ['path'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: getSpecialPaths,
        description: '''
Get platform-specific special folder paths like Documents, Downloads, AppData, etc.
Returns paths appropriate for the current operating system (Windows, macOS, Linux).
Supports folder types: desktop, documents, downloads, pictures, videos, music,
appdata, localappdata, roaming, temp, application_support, library, config, cache.
''',
        parameters: {
          'type': 'object',
          'properties': {
            'folderType': {
              'type': 'string',
              'description': 'Type of special folder to retrieve',
              'enum': [
                'desktop',
                'documents',
                'downloads',
                'pictures',
                'videos',
                'music',
                'appdata',
                'localappdata',
                'roaming',
                'temp',
                'application_support',
                'library',
                'config',
                'cache',
              ],
            },
          },
          'required': ['folderType'],
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: listHiddenFiles,
        description: '''
List hidden files and folders in a directory.
On Unix systems, hidden files start with a dot (.).
On Windows, checks for files starting with dot (.) as hidden.
''',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Directory path to search (defaults to current directory)',
            },
            'includeSystem': {
              'type': 'boolean',
              'description': 'Include system/protected files and folders',
            },
          },
        },
      ),
    ),
    Tool(
      function: ToolFunction(
        name: resolveSymlink,
        description: '''
Resolve symbolic links to their target paths.
Returns the actual file or directory that a symlink points to.
''',
        parameters: {
          'type': 'object',
          'properties': {
            'path': {
              'type': 'string',
              'description': 'Path to check for symbolic link',
            },
          },
          'required': ['path'],
        },
      ),
    ),
  ];
}
