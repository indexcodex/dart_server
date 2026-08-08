/// determine the upload status
enum UploadStatus {
  /// if the upload succeeds
  success,

  /// if the request is not multipart/form-data
  invalidRequestType,

  /// if the file uploaded is unsupported
  unsupportedFileType,

  /// if the form data exceeds allowed size
  fieldTooLarge,

  /// if the file uploaded exceeds allowed size
  fileTooLarge,

  /// if the request exceeds allowed size
  requestTooLarge,

  /// if the files uploaded exceeds allowed count
  exceedAllowedFileCount,

  /// if the error doesn't fall on any defined exceptions
  genericFailed,
}
