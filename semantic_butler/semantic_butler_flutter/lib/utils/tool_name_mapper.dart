/// Utility class for mapping tool names to user-friendly display names
class ToolNameMapper {
  /// Get user-friendly name for a tool
  static String getFriendlyToolName(String toolName) {
    switch (toolName) {
      case 'search_files':
        return 'Searching documents';
      case 'grep_search':
        return 'Looking for specific text';
      case 'find_files':
        return 'Locating files';
      case 'read_file_contents':
        return 'Reading file';
      case 'get_drives':
        return 'Checking drives';
      case 'list_directory':
        return 'Scanning folder';
      case 'create_folder':
        return 'Creating folder';
      case 'rename_file':
      case 'rename_folder':
        return 'Renaming item';
      case 'move_file':
        return 'Moving item';
      case 'copy_file':
        return 'Copying item';
      case 'delete_file':
        return 'Eliminating item';
      case 'move_to_trash':
        return 'Moving to trash';
      case 'summarize_document':
        return 'Analyzing content';
      case 'get_document_details':
        return 'Getting info';
      case 'find_related':
        return 'Finding similar files';
      case 'get_indexing_status':
        return 'Checking index';
      case 'batch_operations':
        return 'Running multiple actions';
      default:
        return 'Working';
    }
  }
}
