import 'package:flutter/material.dart';
import 'package:semantic_butler_client/semantic_butler_client.dart';
import 'package:path/path.dart' as p;

class ResolveDuplicatesDialog extends StatefulWidget {
  final DuplicateGroup group;

  const ResolveDuplicatesDialog({super.key, required this.group});

  @override
  State<ResolveDuplicatesDialog> createState() =>
      _ResolveDuplicatesDialogState();
}

class _ResolveDuplicatesDialogState extends State<ResolveDuplicatesDialog> {
  late String _selectedToKeep;

  @override
  void initState() {
    super.initState();
    // Default to keeping the one with the shortest path or first one
    _selectedToKeep = widget.group.files.first.path;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolve Duplicates'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select the file you want to KEEP. All other copies will be moved to trash.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.group.files.length,
                itemBuilder: (context, index) {
                  final file = widget.group.files[index];
                  return RadioListTile<String>(
                    title: Text(p.basename(file.path)),
                    subtitle: Text(
                      file.path,
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: file.path,
                    // ignore: deprecated_member_use
                    groupValue: _selectedToKeep,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedToKeep = value);
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Potential savings: ${_formatSize(widget.group.potentialSavingsBytes)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final deletePaths = widget.group.files
                .where((f) => f.path != _selectedToKeep)
                .map((f) => f.path)
                .toList();
            Navigator.pop(context, {
              'keep': _selectedToKeep,
              'delete': deletePaths,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Resolve Now'),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class FixNamingDialog extends StatelessWidget {
  final List<NamingIssue> issues;

  const FixNamingDialog({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    // Flatten all affected files across issues
    final allFiles = issues.expand((i) => i.affectedFiles).toList();

    return AlertDialog(
      title: Text('Fix Naming Issues (${allFiles.length} files)'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following files will be renamed to follow naming conventions:',
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allFiles.length.clamp(0, 10), // Show first 10
                itemBuilder: (context, index) {
                  final path = allFiles[index];
                  final oldName = p.basename(path);
                  // Find which issue this file belongs to to get strategy
                  final issue = issues.firstWhere(
                    (i) => i.affectedFiles.contains(path),
                  );
                  final newName = _suggestNewName(oldName, issue.issueType);

                  return ListTile(
                    dense: true,
                    title: Text(
                      oldName,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward, size: 16),
                    subtitle: Text(
                      newName,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (allFiles.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '...and ${allFiles.length - 10} more files',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Apply All Fixes'),
        ),
      ],
    );
  }

  String _suggestNewName(String name, String issueType) {
    switch (issueType) {
      case 'spaces_in_name':
        return name.replaceAll(' ', '_');
      case 'invalid_characters':
        return name.replaceAll(RegExp(r'[<>:"|?*]'), '');
      case 'inconsistent_case':
        // Fallback or generic suggestion
        return name.toLowerCase().replaceAll(' ', '_');
      default:
        return name;
    }
  }
}

class OrganizeSimilarDialog extends StatefulWidget {
  final SimilarContentGroup group;

  const OrganizeSimilarDialog({super.key, required this.group});

  @override
  State<OrganizeSimilarDialog> createState() => _OrganizeSimilarDialogState();
}

class _OrganizeSimilarDialogState extends State<OrganizeSimilarDialog> {
  final TextEditingController _folderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default suggestion based on reason or similarity
    final reason = widget.group.similarityReason;
    _folderController.text = (reason != null && reason.split(' ').isNotEmpty)
        ? reason.split(' ').first
        : 'Related Files';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Organize Similar Files'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group ${widget.group.files.length} related files into a new folder.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _folderController,
              decoration: const InputDecoration(
                labelText: 'Target Folder Name',
                hintText: 'e.g. Project Specs, Invoices, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Files to be moved:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.group.files.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final file = widget.group.files[index];
                  return Text(
                    '• ${p.basename(file.path)}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),
            if (widget.group.files.length > 5)
              Text(
                '• ...and ${widget.group.files.length - 5} more',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_folderController.text.trim().isNotEmpty) {
              Navigator.pop(context, _folderController.text.trim());
            }
          },
          child: const Text('Organize'),
        ),
      ],
    );
  }
}
