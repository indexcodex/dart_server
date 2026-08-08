import 'package:shelf_plus/shelf_plus.dart';
import 'package:shelf_server/_core/core.dart';
import 'package:shelf_server/_core/engine/upload_engine/enum/upload_status.dart';

/// upload many, all or nothing
///
/// deletes all uploaded files if the request fails
void uploadManyAON(RouterPlus app) {
  app.post('/upload-many-aon', (Request request) async {
    String userId = 'sample_user';
    String tempDir = 'tmp/user/$userId';
    String destDir = 'public/user/$userId';

    Response? response;

    await Core.engine.upload.interactive(
      request: request,
      stagingDir: tempDir,
      onSuccess: (validatedUploads, fields) async {
        Core.util.log.devPrintList([
          'onSuccess fields: $fields',
          '________________________________________',
        ]);

        for (var data in validatedUploads) {
          Core.util.log.devPrintList([
            'onSuccess extension: ${data.extension}',
            'onSuccess field: ${data.field}',
            'onSuccess mimeType: ${data.mimeType}',
            'onSuccess originalFilename: ${data.originalFilename}',
            'onSuccess size: ${data.size}',
            'onSuccess tempPath: ${data.tempPath}',
            '________________________________________',
          ]);

          // move the file to live directory
          await Core.util.file.moveFileToDirectory(
            sourcePath: data.tempPath,
            destinationDir: destDir,
            customFilename: '${DateTime.now().microsecondsSinceEpoch}.png',
          );
        }

        // return success response here
        response = Core.util.response.success({"success": true});
      },
      onFailed: (status, {error, stackTrace}) async {
        Core.util.log.devPrintList([
          'onFailed status: $status',
          'onFailed error: $error',
          'onFailed stackTrace: $stackTrace',
        ]);

        switch (status) {
          case UploadStatus.unsupportedFileType:
            // MPDRVE: Multipart Data Request Validation Error
            response = Core.util.response.error(400, errorCode: 'MPDRVE');
            break;
          case UploadStatus.requestTooLarge:
            // UHREAS: Upload Handler Request Exceeds Allowed Size
            response = Core.util.response.error(413, errorCode: 'UHREAS');
            break;
          case UploadStatus.invalidRequestType:
            // MPDRVE: Multipart Data Request Validation Error
            response = Core.util.response.error(400, errorCode: 'MPDRVE');
            break;
          case UploadStatus.genericFailed:
            // UHFUPE: Upload Handler File Upload Processing Error
            response = Core.util.response.error(500, errorCode: 'UHFUPE');
            break;
          case UploadStatus.fileTooLarge:
            // UHFEAS: Upload Handler File Exceeds Allowed Size
            response = Core.util.response.error(413, errorCode: 'UHFEAS');
            break;
          case UploadStatus.fieldTooLarge:
            // UHRFEAS: Upload Handler Request Field Exceeds Allowed Size
            response = Core.util.response.error(413, errorCode: 'UHRFEAS');
            break;
          case UploadStatus.exceedAllowedFileCount:
            response = Core.util.response.error(400, errorCode: '');
            // UHMFA: Upload Handler Multiple Files Attempted
            response = Core.util.response.error(400, errorCode: 'UHMFA');
            break;
          case UploadStatus.success:
            response = Core.util.response.success();
            break;
        }
      },
    );

    return response ?? Core.util.response.error(500, errorCode: 'uhr');
  });
}
