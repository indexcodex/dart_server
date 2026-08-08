import 'dart:io';
import 'dart:convert';

import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:shelf_server/_core/engine/upload_engine/enum/upload_status.dart';
import 'package:uuid/uuid.dart';

import '../model/validated_upload.dart';

/// Successfully validated files are passed to [onSuccess].
///
/// Ownership of the temporary files is transferred to the caller.
///
/// The caller is responsible for either:
/// - moving the file,
/// - copying the file,
/// - uploading it elsewhere,
/// - or deleting it.
///
/// If validation fails before [onSuccess] is called,
/// temporary files are cleaned up automatically.
Future<void> uploadHandlerInteractive({
  required Request request,
  required Future<void> Function(
    UploadStatus status, {
    Object? error,
    StackTrace? stackTrace,
  })
  onFailed,
  required Future<void> Function(
    List<ValidatedUpload> validatedUploads,
    Map<String, String> fields,
  )
  onSuccess,
  int uploadMaxFileCount = 8,
  String stagingDir = 'tmp/staging',
}) async {
  // triggers cleanup if upload failes
  bool isUploadSuccess = false;

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

  // Metadata for successfully validated files.
  final validatedUploads = <ValidatedUpload>[];

  try {
    // Validate that the request is multipart/form-data.
    final form = request.formData();

    if (form == null) {
      throw const _InvalidRequestTypeException();
    }

    // Ensure the upload directory exists.
    final uploadDir = Directory(stagingDir);
    await uploadDir.create(recursive: true);

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

      // Files are streamed into a temporary file first.
      // The file is renamed only after it has been fully validated.
      final tempFilename = uuid.v4();
      final tempPath = '${uploadDir.path}/$tempFilename.upload';

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

        throw const _UnsupportedFileTypeException();
      }

      validatedUploads.add(
        ValidatedUpload(
          extension: Core.util.mime.getExtension(mime),
          field: formData.name,
          mimeType: mime,
          originalFilename: originalFilename,
          size: totalBytes,
          tempPath: tempPath,
        ),
      );
    }

    await onSuccess.call(List.unmodifiable(validatedUploads), fields);
    isUploadSuccess = true;
  } on _FieldTooLargeException {
    await onFailed.call(UploadStatus.fieldTooLarge);
  } on _FileTooLargeException {
    await onFailed.call(UploadStatus.fileTooLarge);
  } on _RequestTooLargeException {
    await onFailed.call(UploadStatus.requestTooLarge);
  } on _MultipleFilesException {
    await onFailed.call(UploadStatus.exceedAllowedFileCount);
  } on _InvalidRequestTypeException {
    await onFailed.call(UploadStatus.invalidRequestType);
  } on _UnsupportedFileTypeException {
    await onFailed.call(UploadStatus.unsupportedFileType);
  } catch (e, stackTrace) {
    Core.util.log.devPrint('upload exception e: $e');
    Core.util.log.devPrint(
      'upload exception stacktrace: ${stackTrace.toString()}',
    );

    await onFailed.call(
      UploadStatus.genericFailed,
      error: e,
      stackTrace: stackTrace,
    );
  } finally {
    if (!isUploadSuccess) {
      await cleanupTemporaryFiles(
        validatedUploads.map((e) => e.tempPath).toList(),
      );
    }
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
Future<void> cleanupTemporaryFiles(List<String> tempPaths) async {
  for (final path in tempPaths) {
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

class _InvalidRequestTypeException implements Exception {
  const _InvalidRequestTypeException();
}

class _UnsupportedFileTypeException implements Exception {
  const _UnsupportedFileTypeException();
}
