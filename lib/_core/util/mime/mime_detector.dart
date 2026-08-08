/// Detects the MIME type from the file's binary signature (magic bytes).
///
/// Used by the upload handler to strengthen file validation by ignoring
/// client-supplied filenames and MIME types. This helps prevent simple
/// file type spoofing (for example, renaming an executable to `.png` or
/// `.pdf`) by validating the file's actual contents instead.
class MimeDetector {
  String? detect(List<int> bytes) {
    // JPEG
    if (_startsWith(bytes, [0xFF, 0xD8, 0xFF])) {
      return 'image/jpeg';
    }

    // PNG
    if (_startsWith(bytes, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return 'image/png';
    }

    // GIF
    if (_startsWith(bytes, 'GIF87a'.codeUnits) ||
        _startsWith(bytes, 'GIF89a'.codeUnits)) {
      return 'image/gif';
    }

    // PDF
    if (_startsWith(bytes, '%PDF-'.codeUnits)) {
      return 'application/pdf';
    }

    // ZIP
    if (_startsWith(bytes, [0x50, 0x4B, 0x03, 0x04]) ||
        _startsWith(bytes, [0x50, 0x4B, 0x05, 0x06]) ||
        _startsWith(bytes, [0x50, 0x4B, 0x07, 0x08])) {
      return 'application/zip';
    }

    // WAV
    if (_startsWith(bytes, 'RIFF'.codeUnits) &&
        bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(8, 12)) == 'WAVE') {
      return 'audio/wav';
    }

    // MP3 (ID3)
    if (_startsWith(bytes, 'ID3'.codeUnits)) {
      return 'audio/mpeg';
    }

    // MP3 (raw MPEG frame)
    if (bytes.length >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'audio/mpeg';
    }

    // MP4
    if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp') {
      final brand = String.fromCharCodes(bytes.sublist(8, 12));

      const allowedBrands = {'isom', 'iso2', 'mp41', 'mp42', 'M4V ', 'MSNV'};

      if (allowedBrands.contains(brand)) {
        return 'video/mp4';
      }
    }

    return null;
  }

  bool _startsWith(List<int> bytes, List<int> signature) {
    if (bytes.length < signature.length) {
      return false;
    }

    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) {
        return false;
      }
    }

    return true;
  }

  String getExtension(String? mime) {
    switch (mime) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'application/pdf':
        return 'pdf';
      case 'application/zip':
        return 'zip';
      case 'audio/wav':
        return 'wav';
      case 'audio/mpeg':
        return 'mp3';
      case 'video/mp4':
        return 'mp4';
      default:
        throw ArgumentError('Unsupported MIME type: $mime');
    }
  }
}
