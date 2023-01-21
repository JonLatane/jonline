import 'package:protobuf/protobuf.dart';

import 'fake_js.dart' if (dart.library.js) 'dart:js';

extension ProtoUtils<T extends GeneratedMessage> on T {
  dynamic protoJsify() => JsObject.jsify(jonCopy().toProto3Json()!);
  T jonCopy() {
    return deepCopy();
  }

  T jonRebuild(Function(T) updates) {
    return (deepCopy()..freeze()).rebuild((t) => updates(t)).deepCopy();
  }

  String get logString => "\n  ${toString().replaceAll("\n", "\n  ")}";
}
