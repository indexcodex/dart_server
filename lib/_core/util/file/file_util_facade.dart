import 'dart:io';
import 'package:shelf_server/_core/core.dart';

// --------------
// USAGE
// --------------
//
// move 'tmp/staging/temp_file.upload' to 'public/uploads/final_file.png'
//
// await Core.util.file.moveFileToDirectory(
//   sourcePath: 'tmp/staging/temp_file.upload',
//   destinationDir: 'public/uploads',
//   customFilename: 'final_file.png',
// );

/// File related utilities
class FileUtilFacade {
  /// Safely moves a file from [sourcePath] to a [destinationDir] with an optional [customFilename].
  ///
  /// If the move operation fails due to being on different physical disk partitions,
  /// it automatically falls back to an atomic-emulated copy-and-delete sequence.
  ///
  /// Returns the [File] object at its new permanent location, or throws an [Exception]
  /// if the operation fails entirely.
  Future<File> moveFileToDirectory({
    required String sourcePath,
    required String destinationDir,
    String? customFilename,
  }) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    // Ensure the destination directory exists
    final destDir = Directory(destinationDir);
    await destDir.create(recursive: true);

    // Determine final target filename
    final filename = customFilename ?? sourceFile.uri.pathSegments.last;
    final finalPath = '${destDir.path}/$filename';
    final targetFile = File(finalPath);

    try {
      // 1. Try an atomic OS-level move (Fastest, safest pointer-swap)
      return await sourceFile.rename(finalPath);
    } on FileSystemException {
      // 2. Fallback if partitions/volumes differ (e.g., Docker mount boundaries)
      Core.util.log.devPrint(
        'Cross-device link detected. Falling back to copy-and-delete for: $sourcePath',
      );

      try {
        // Perform the copy stream
        await sourceFile.copy(finalPath);

        // Only delete the original if the copy completes with zero errors
        await sourceFile.delete();

        return targetFile;
      } catch (e) {
        // 3. Rollback partial/corrupt data if the copy streams failed or crashed midway
        if (await targetFile.exists()) {
          // ignore: body_might_complete_normally_catch_error
          await targetFile.delete().catchError((err, _) {
            Core.util.log.devPrint(
              'Failed to clean up corrupt target file during rollback: $err',
            );
          });
        }

        rethrow; // Propagate the original error upwards
      }
    }
  }
}
