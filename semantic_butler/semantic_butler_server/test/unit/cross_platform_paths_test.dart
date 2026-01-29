import 'dart:io';
import 'package:test/test.dart';

import 'package:semantic_butler_server/src/utils/cross_platform_paths.dart';

void main() {
  group('CrossPlatformPaths', () {
    group('separator', () {
      test('returns backslash on Windows', () {
        // This test will only pass on Windows
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.separator, '\\');
        }
      });

      test('returns forward slash on Unix', () {
        if (!Platform.isWindows) {
          expect(CrossPlatformPaths.separator, '/');
        }
      });
    });

    group('join', () {
      test('joins two path parts with correct separator', () {
        final result = CrossPlatformPaths.join('foo', 'bar');
        if (Platform.isWindows) {
          expect(result, 'foo\\bar');
        } else {
          expect(result, 'foo/bar');
        }
      });

      test('removes trailing separator from base', () {
        final result = CrossPlatformPaths.join('foo/', 'bar');
        if (Platform.isWindows) {
          expect(result, 'foo\\bar');
        } else {
          expect(result, 'foo/bar');
        }
      });

      test('removes leading separator from part', () {
        final result = CrossPlatformPaths.join('foo', '/bar');
        if (Platform.isWindows) {
          expect(result, 'foo\\bar');
        } else {
          expect(result, 'foo/bar');
        }
      });
    });

    group('joinAll', () {
      test('joins multiple path parts', () {
        final result = CrossPlatformPaths.joinAll(['foo', 'bar', 'baz']);
        if (Platform.isWindows) {
          expect(result, 'foo\\bar\\baz');
        } else {
          expect(result, 'foo/bar/baz');
        }
      });

      test('returns empty string for empty list', () {
        expect(CrossPlatformPaths.joinAll([]), '');
      });

      test('returns single element for list with one item', () {
        expect(CrossPlatformPaths.joinAll(['foo']), 'foo');
      });
    });

    group('normalize', () {
      test('converts forward slashes to backslashes on Windows', () {
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.normalize('foo/bar/baz'), r'foo\bar\baz');
        }
      });

      test('converts backslashes to forward slashes on Unix', () {
        if (!Platform.isWindows) {
          expect(CrossPlatformPaths.normalize(r'foo\bar\baz'), 'foo/bar/baz');
        }
      });

      test('preserves drive letters on Windows', () {
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.normalize('C:/foo/bar'), r'C:\foo\bar');
        }
      });

      test('handles UNC paths on Windows', () {
        if (Platform.isWindows) {
          expect(
            CrossPlatformPaths.normalize('//server/share/path'),
            r'\\server\share\path',
          );
        }
      });
    });

    group('homeDirectory', () {
      test('returns a non-empty path', () {
        expect(CrossPlatformPaths.homeDirectory, isNotEmpty);
      });

      test('path exists on filesystem', () {
        expect(Directory(CrossPlatformPaths.homeDirectory).existsSync(), true);
      });
    });

    group('specialFolders', () {
      test('returns non-empty map', () {
        expect(CrossPlatformPaths.specialFolders, isNotEmpty);
      });

      test('contains common folders', () {
        final folders = CrossPlatformPaths.specialFolders;
        expect(folders, contains('desktop'));
        expect(folders, contains('documents'));
        expect(folders, contains('downloads'));
      });

      test('desktop folder exists', () {
        final desktop = CrossPlatformPaths.specialFolders['desktop'];
        expect(desktop, isNotNull);
        expect(Directory(desktop!).existsSync(), true);
      });

      test('documents folder exists', () {
        final documents = CrossPlatformPaths.specialFolders['documents'];
        expect(documents, isNotNull);
        expect(Directory(documents!).existsSync(), true);
      });
    });

    group('getSpecialFolder', () {
      test('returns folder for known types', () {
        expect(CrossPlatformPaths.getSpecialFolder('desktop'), isNotNull);
        expect(CrossPlatformPaths.getSpecialFolder('documents'), isNotNull);
        expect(CrossPlatformPaths.getSpecialFolder('downloads'), isNotNull);
      });

      test('returns null for unknown types', () {
        expect(CrossPlatformPaths.getSpecialFolder('unknown_folder'), isNull);
      });

      test('handles aliases', () {
        expect(CrossPlatformPaths.getSpecialFolder('docs'), isNotNull);
        expect(CrossPlatformPaths.getSpecialFolder('pics'), isNotNull);
      });
    });

    group('isAbsolute', () {
      test('returns true for absolute Windows paths', () {
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.isAbsolute(r'C:\'), true);
          expect(CrossPlatformPaths.isAbsolute(r'C:\foo'), true);
        }
      });

      test('returns true for absolute Unix paths', () {
        if (!Platform.isWindows) {
          expect(CrossPlatformPaths.isAbsolute('/'), true);
          expect(CrossPlatformPaths.isAbsolute('/foo'), true);
        }
      });

      test('returns false for relative paths', () {
        expect(CrossPlatformPaths.isAbsolute('foo'), false);
        expect(CrossPlatformPaths.isAbsolute('./bar'), false);
      });
    });

    group('rootPath', () {
      test('returns valid root path', () {
        expect(CrossPlatformPaths.rootPath, isNotEmpty);
      });

      test('root path exists on Windows', () {
        if (Platform.isWindows) {
          expect(Directory(CrossPlatformPaths.rootPath).existsSync(), true);
        }
      });
    });

    group('rootPaths', () {
      test('returns non-empty list', () {
        expect(CrossPlatformPaths.rootPaths, isNotEmpty);
      });
    });

    group('isHidden', () {
      test('returns true for dotfiles on Unix', () {
        if (!Platform.isWindows) {
          expect(CrossPlatformPaths.isHidden('.gitignore'), true);
          expect(CrossPlatformPaths.isHidden('.env'), true);
        }
      });

      test('returns false for regular files', () {
        expect(CrossPlatformPaths.isHidden('regular.txt'), false);
      });
    });

    group('expand', () {
      test('expands ~ to home directory', () {
        final home = CrossPlatformPaths.homeDirectory;
        final result = CrossPlatformPaths.expand('~/Documents');
        expect(result, startsWith(home));
      });

      test('expands environment variables on Windows', () {
        if (Platform.isWindows) {
          final user = Platform.environment['USERNAME'];
          if (user != null) {
            final result = CrossPlatformPaths.expand('%USERNAME%');
            expect(result, contains(user));
          }
        }
      });

      test('expands \$VAR on Unix', () {
        if (!Platform.isWindows) {
          final home = Platform.environment['HOME'];
          if (home != null) {
            final result = CrossPlatformPaths.expand('\$HOME');
            expect(result, home);
          }
        }
      });
    });

    group('relative', () {
      test('computes relative path from home', () {
        final home = CrossPlatformPaths.homeDirectory;
        final fullPath = CrossPlatformPaths.join(home, 'Documents', 'file.txt');
        final result = CrossPlatformPaths.relative(home, fullPath);
        expect(result, contains('Documents'));
      });

      test('returns full path when different drives on Windows', () {
        if (Platform.isWindows) {
          final result = CrossPlatformPaths.relative('C:\\', 'D:\\file.txt');
          expect(result, 'D:\\file.txt');
        }
      });
    });

    group('matchesPattern', () {
      test('matches * wildcard', () {
        expect(CrossPlatformPaths.matchesPattern('file.txt', '*.txt'), true);
        expect(CrossPlatformPaths.matchesPattern('file.txt', '*.md'), false);
      });

      test('matches ? wildcard', () {
        expect(CrossPlatformPaths.matchesPattern('file.txt', 'file.?'), false);
        expect(CrossPlatformPaths.matchesPattern('file.t', 'file.?'), true);
      });

      test('matches multiple wildcards', () {
        expect(CrossPlatformPaths.matchesPattern('test_file.dart', 'test_*.dart'), true);
        expect(CrossPlatformPaths.matchesPattern('my_file.dart', '*_*.dart'), true);
      });

      test('is case-insensitive on Windows', () {
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.matchesPattern('FILE.TXT', '*.txt'), true);
          expect(CrossPlatformPaths.matchesPattern('File.Txt', '*.TXT'), true);
        }
      });

      test('is case-sensitive on Unix', () {
        if (!Platform.isWindows) {
          expect(CrossPlatformPaths.matchesPattern('FILE.TXT', '*.txt'), false);
          expect(CrossPlatformPaths.matchesPattern('file.txt', '*.txt'), true);
        }
      });
    });

    group('matchesPatternCaseSensitive', () {
      test('can force case-insensitive matching', () {
        expect(
          CrossPlatformPaths.matchesPatternCaseSensitive(
            'FILE.TXT',
            '*.txt',
            caseSensitive: false,
          ),
          true,
        );
      });

      test('can force case-sensitive matching', () {
        expect(
          CrossPlatformPaths.matchesPatternCaseSensitive(
            'FILE.TXT',
            '*.txt',
            caseSensitive: true,
          ),
          false,
        );
      });
    });

    group('pathsEqual', () {
      test('compares paths correctly', () {
        expect(
          CrossPlatformPaths.pathsEqual('foo/bar', 'foo/bar'),
          true,
        );
      });

      test('is case-insensitive on Windows', () {
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.pathsEqual('FOO/BAR', 'foo/bar'), true);
          expect(CrossPlatformPaths.pathsEqual('Foo/Bar', 'foo/bar'), true);
        }
      });

      test('is case-sensitive on Unix', () {
        if (!Platform.isWindows) {
          expect(CrossPlatformPaths.pathsEqual('FOO/BAR', 'foo/bar'), false);
          expect(CrossPlatformPaths.pathsEqual('foo/bar', 'foo/bar'), true);
        }
      });
    });

    group('pathStartsWith', () {
      test('checks prefix correctly', () {
        expect(CrossPlatformPaths.pathStartsWith('foo/bar/baz', 'foo/bar'), true);
        expect(CrossPlatformPaths.pathStartsWith('foo/bar/baz', 'baz'), false);
      });

      test('is case-insensitive on Windows', () {
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.pathStartsWith('FOO/bar/baz', 'foo'), true);
          expect(CrossPlatformPaths.pathStartsWith('Foo/Bar', 'foo/'), false);
        }
      });
    });

    group('pathContains', () {
      test('checks substring correctly', () {
        expect(CrossPlatformPaths.pathContains('foo/bar/baz', 'bar'), true);
        expect(CrossPlatformPaths.pathContains('foo/bar/baz', 'qux'), false);
      });

      test('is case-insensitive on Windows', () {
        if (Platform.isWindows) {
          expect(CrossPlatformPaths.pathContains('FOO/bar/baz', 'foo'), true);
          expect(CrossPlatformPaths.pathContains('foo/Bar/baz', 'bar'), true);
        }
      });
    });

    group('platform detection', () {
      test('isWindows is correct', () {
        expect(CrossPlatformPaths.isWindows, Platform.isWindows);
      });

      test('isMacOS is correct', () {
        expect(CrossPlatformPaths.isMacOS, Platform.isMacOS);
      });

      test('isLinux is correct', () {
        expect(CrossPlatformPaths.isLinux, Platform.isLinux);
      });

      test('isUnix is opposite of isWindows', () {
        expect(CrossPlatformPaths.isUnix, !Platform.isWindows);
      });

      test('platformName returns valid value', () {
        expect(CrossPlatformPaths.platformName, isNotEmpty);
      });
    });
  });
}
