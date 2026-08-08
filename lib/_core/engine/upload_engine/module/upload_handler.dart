import 'dart:io';
import 'dart:convert';

import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:uuid/uuid.dart';

import '../model/validated_upload.dart';

Future<Response> uploadHandler({
  required Request request,
  int uploadMaxFileCount = 8,
  String stagingDir = 'tmp/staging',
  String destinationDir = 'tmp/uploads',
}) async {
  // Maximum allowed upload size.
  final maxFileSize = Core.config.uploadMaxFileSize;

  // Maximum allowed upload size for the entire request.
  final maxRequestSize = Core.config.uploadMaxRequestSize;

  // Maximum allowed field size.
  final maxFieldSize = Core.config.uploadMaxFieldSize;

  // Number of uploaded files encountered.
  var fileCount = 0;

  // Total bytes processed across the entire multipart request.
  var totalRequestBytes = 0;

  // UUID generator used for temporary and final filenames.
  const uuid = Uuid();

  // Parsed text form fields.
  final fields = <String, String>{};

  // Metadata for successfully uploaded files.
  final uploadedFiles = <Map<String, dynamic>>[];

  // Temporary uploads that have passed validation but have not yet
  // been committed to their final filenames.
  //
  // Files remain in their temporary ".upload" form until every upload
  // in the request has been successfully validated. This guarantees
  // all-or-nothing behavior.
  final stagedUploads = <ValidatedUpload>[];

  try {
    // Validate that the request is multipart/form-data.
    final form = request.formData();

    if (form == null) {
      // MPDRVE: Multipart Data Request Validation Error
      return Core.util.response.error(400, errorCode: 'MPDRVE');
    }

    // Ensure both staging and destination folders exist.
    final stageDirectory = Directory(stagingDir);
    await stageDirectory.create(recursive: true);

    final destDirectory = Directory(destinationDir);
    await destDirectory.create(recursive: true);

    // Process every multipart section (text fields and files).
    await for (final formData in form.formData) {
      // Regular form field.
      if (!formData.isFile) {
        fields[formData.name] = await readFormField(
          formData.part,
          maxFieldSize: maxFieldSize,
          onChunk: (chunkSize) {
            totalRequestBytes += chunkSize;

            if (totalRequestBytes > maxRequestSize) {
              throw const _RequestTooLargeException();
            }
          },
        );

        // jump to the next iteration of the loop
        continue;
      }

      fileCount++;

      if (fileCount > uploadMaxFileCount) {
        throw const _MultipleFilesException();
      }

      // Strip any directory information from the client filename.
      // This prevents path traversal attacks such as "../../secret.txt".
      final originalFilename = File(formData.filename!).uri.pathSegments.last;

      // Files are streamed into a temporary file inside stagingDir first.
      // The file is renamed only after it has been fully validated.
      final tempFilename = uuid.v4();
      final tempPath = '${stageDirectory.path}/$tempFilename.upload';

      final outputFile = File(tempPath);
      final sink = outputFile.openWrite();

      // Store the first few KB for MIME detection.
      final headerBytes = <int>[];

      // Track uploaded size while streaming.
      var totalBytes = 0;

      try {
        try {
          // Stream the upload directly to disk to avoid buffering
          // the entire file into memory.
          await for (final chunk in formData.part) {
            totalBytes += chunk.length;
            totalRequestBytes += chunk.length;

            // Reject files larger than the configured per-file limit.
            if (totalBytes > maxFileSize) {
              throw const _FileTooLargeException();
            }

            // Reject requests larger than the configured total limit.
            if (totalRequestBytes > maxRequestSize) {
              throw const _RequestTooLargeException();
            }

            // Keep only the first 8 KB of the file.
            //
            // These bytes contain the file signature (magic bytes) used to
            // determine the actual file type. This prevents trusting the
            // client-provided filename or extension (for example,
            // "virus.exe" renamed to "image.pdf").
            //
            // Note: This is the file header, not the HTTP request header.
            if (headerBytes.length < 8192) {
              final remaining = 8192 - headerBytes.length;

              if (chunk.length <= remaining) {
                headerBytes.addAll(chunk);
              } else {
                headerBytes.addAll(chunk.take(remaining));
              }
            }

            sink.add(chunk);
          }
        } finally {
          // Always close the sink, even if streaming fails.
          await sink.close();
        }
      } catch (_) {
        // Remove the partially written temporary upload before
        // propagating the failure.
        // ignore: body_might_complete_normally_catch_error
        await outputFile.delete().catchError((e, _) {
          Core.util.log.devPrint('Failed to delete temporary upload: $e');
        });
        rethrow;
      }

      // Determine the actual MIME type from the file's magic bytes.
      // The client-provided filename and extension are not trusted.
      final String? mime = Core.util.mime.detect(headerBytes);

      // Reject unsupported file types.
      if (mime == null) {
        // ignore: body_might_complete_normally_catch_error
        await outputFile.delete().catchError((e, _) {
          Core.util.log.devPrint('Failed to delete temporary upload: $e');
        });

        await deleteStagedUploads(
          stagedUploads.map((e) => e.tempPath).toList(),
        );

        // UHUFT: Upload Handler Unsupported File Type
        return Core.util.response.error(415, errorCode: 'UHUFT');
      }

      // temporary uploaded files
      stagedUploads.add(
        ValidatedUpload(
          tempPath: tempPath,
          originalFilename: originalFilename,
          mimeType: mime,
          extension: Core.util.mime.getExtension(mime),
          size: totalBytes,
          field: formData.name,
        ),
      );
    }

    // Commit every staged upload to the destinationDir.
    //
    // Only after all files have been validated are they renamed to their
    // permanent filenames, providing all-or-nothing semantics.
    final committedPaths = <String>[];

    try {
      for (final upload in stagedUploads) {
        final finalFilename = upload.extension.isEmpty
            ? uuid.v4()
            : '${uuid.v4()}.${upload.extension}';
        final finalPath = '${destDirectory.path}/$finalFilename';

        final tempFile = File(upload.tempPath);

        // Move the staged upload into its final location.
        //
        // If the source and destination reside on different filesystems,
        // rename() may fail. Fall back to copy/delete.
        try {
          await tempFile.rename(finalPath);
        } on FileSystemException {
          await tempFile.copy(finalPath);
          await tempFile.delete();
        }

        // Record committed files so they can be rolled back if
        // a later commit fails.
        committedPaths.add(finalPath);

        uploadedFiles.add({
          'field': upload.field,
          'filename': finalFilename,
          'originalFilename': upload.originalFilename,
          'mimeType': upload.mimeType,
          'size': upload.size,
          'path': finalPath,
        });
      }
    } catch (_) {
      // Remove every file that was already committed before
      // propagating the failure.
      for (final path in committedPaths) {
        try {
          await File(path).delete();
        } catch (e) {
          Core.util.log.devPrint('Failed to perform rollback: $e');
        }
      }

      uploadedFiles.clear();

      rethrow;
    }

    return Core.util.response.success({
      'success': true,
      'fields': fields,
      'files': uploadedFiles,
    });
  } on _FieldTooLargeException {
    await deleteStagedUploads(stagedUploads.map((e) => e.tempPath).toList());

    // UHRFEAS: Upload Handler Request Field Exceeds Allowed Size
    return Core.util.response.error(413, errorCode: 'UHRFEAS');
  } on _FileTooLargeException {
    await deleteStagedUploads(stagedUploads.map((e) => e.tempPath).toList());

    // UHFEAS: Upload Handler File Exceeds Allowed Size
    return Core.util.response.error(413, errorCode: 'UHFEAS');
  } on _RequestTooLargeException {
    await deleteStagedUploads(stagedUploads.map((e) => e.tempPath).toList());

    // UHREAS: Upload Handler Request Exceeds Allowed Size
    return Core.util.response.error(413, errorCode: 'UHREAS');
  } on _MultipleFilesException {
    await deleteStagedUploads(stagedUploads.map((e) => e.tempPath).toList());

    // UHMFA: Upload Handler Multiple Files Attempted
    return Core.util.response.error(400, errorCode: 'UHMFA');
  } catch (e, stackTrace) {
    Core.util.log.devPrint('upload exception e: $e');
    Core.util.log.devPrint(
      'upload exception stacktrace: ${stackTrace.toString()}',
    );

    await deleteStagedUploads(stagedUploads.map((e) => e.tempPath).toList());

    // UHFUPE: Upload Handler File Upload Processing Error
    return Core.util.response.error(500, errorCode: 'UHFUPE');
  }
}

/// Scan the form field included in the multipart
/// to check if it exceeds the given limit
Future<String> readFormField(
  Stream<List<int>> stream, {
  required int maxFieldSize,
  void Function(int chunkSize)? onChunk,
}) async {
  final bytes = <int>[];
  var fieldSize = 0;

  await for (final chunk in stream) {
    fieldSize += chunk.length;

    if (fieldSize > maxFieldSize) {
      throw const _FieldTooLargeException();
    }

    onChunk?.call(chunk.length);

    bytes.addAll(chunk);
  }

  return utf8.decode(bytes);
}

/// Deletes every staged temporary upload.
///
/// Used whenever the request fails before the commit phase completes.
Future<void> deleteStagedUploads(List<String> stagedUploads) async {
  for (final path in stagedUploads) {
    try {
      await File(path).delete();
    } catch (e) {
      Core.util.log.devPrint('Rollback failed: $e');
    }
  }
}

extension _FormDataExtensions on FormData {
  String? get filename {
    final disposition = part.headers['content-disposition'];
    if (disposition == null) return null;

    final utf8 = RegExp(
      r'''filename\*=UTF-8''([^;]+)''',
      caseSensitive: false,
    ).firstMatch(disposition);

    if (utf8 != null) {
      return Uri.decodeComponent(utf8.group(1)!);
    }

    final normal = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(disposition);

    return normal?.group(1);
  }

  bool get isFile => filename != null;
}

class _FileTooLargeException implements Exception {
  const _FileTooLargeException();
}

class _RequestTooLargeException implements Exception {
  const _RequestTooLargeException();
}

class _FieldTooLargeException implements Exception {
  const _FieldTooLargeException();
}

class _MultipleFilesException implements Exception {
  const _MultipleFilesException();
}
