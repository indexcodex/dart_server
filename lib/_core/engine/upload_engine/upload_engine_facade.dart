import 'package:shelf_plus/shelf_plus.dart';

import 'enum/upload_status.dart';
import 'model/validated_upload.dart';
import 'module/upload_handler.dart';
import 'module/upload_handler_interactive.dart';

/// Upload engine.
///
/// Provides two upload workflows:
/// - [uploadBasic] for the built-in all-in-one upload process.
/// - [uploadCallback] for custom upload pipelines with full control
///   over validated temporary files.
class UploadEngineFacade {
  /// Handles a multipart upload using the built-in workflow.
  ///
  /// Every uploaded file is validated before being moved from
  /// [stagingDir] to [destinationDir]. If any validation fails,
  /// all temporary files are removed and an error response is returned.
  ///
  /// This method is intended for the common case where the framework
  /// manages the entire upload lifecycle.
  ///
  /// Returns:
  /// - a success [Response] containing uploaded file metadata
  /// - or an error [Response] if validation or processing fails.
  Future<Response> basic({
    required Request request,
    int uploadMaxFileCount = 8,
    String stagingDir = 'tmp/staging',
    String destinationDir = 'tmp/uploads',
  }) async {
    return await uploadHandler(
      request: request,
      stagingDir: stagingDir,
      destinationDir: destinationDir,
      uploadMaxFileCount: uploadMaxFileCount,
    );
  }

  /// Handles a multipart upload using a callback-driven workflow.
  ///
  /// All uploaded files are first validated and written to [stagingDir].
  /// After every file has been successfully validated, ownership of the
  /// temporary files is transferred to [onSuccess].
  ///
  /// Inside [onSuccess], the caller is responsible for deciding what
  /// happens to the validated files, such as:
  /// - moving them to permanent storage,
  /// - copying them,
  /// - uploading them to cloud storage,
  /// - or deleting them.
  ///
  /// If validation fails before [onSuccess] is reached,
  /// every temporary file is cleaned up automatically and
  /// [onFailed] is invoked.
  ///
  /// This method is intended for advanced workflows where the application
  /// needs full control over how validated uploads are processed.
  Future<void> interactive({
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
    await uploadHandlerInteractive(
      request: request,
      onFailed: onFailed,
      onSuccess: onSuccess,
      stagingDir: stagingDir,
      uploadMaxFileCount: uploadMaxFileCount,
    );
  }
}
