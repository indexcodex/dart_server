import 'package:uuid/uuid.dart';

class UuidFacade {
  /// create a uuid instance to avoid repeat generation
  final _uuid = const Uuid();

  /// validates the input if its a valid uuid v4
  bool isValidUuidV4(String input) {
    try {
      Uuid.parse(input);
      return true;
    } catch (_) {
      return false;
    }
  }

  String get generateUuidV4 {
    return _uuid.v4();
  }
}
