final class ValidatedUpload {
  const ValidatedUpload({
    required this.tempPath,
    required this.originalFilename,
    required this.mimeType,
    required this.extension,
    required this.size,
    required this.field,
  });

  /// Absolute or relative path to the validated temporary file.
  ///
  /// Ownership of this file is transferred to the caller. The caller is
  /// responsible for moving, copying, uploading, or deleting it.
  final String tempPath;

  /// Original filename supplied by the client during upload.
  ///
  /// This value is intended for display purposes and should not be trusted
  /// for determining the file type or storage path.
  final String originalFilename;

  /// MIME type detected from the file's contents (magic bytes).
  ///
  /// This value is determined by server-side validation rather than the
  /// client-provided filename or extension.
  final String mimeType;

  /// Recommended file extension for the detected MIME type.
  ///
  /// This value is derived from [mimeType] and is suitable when generating
  /// a permanent filename.
  final String extension;

  /// Size of the uploaded file in bytes.
  final int size;

  /// Name of the multipart form field that contained this file.
  ///
  /// For example: `"avatar"` or `"attachments"`.
  final String field;
}
