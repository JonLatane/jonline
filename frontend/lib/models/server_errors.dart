import 'package:grpc/grpc.dart';

final grpcErrorConversions = {
  RegExp(r'^([\w]+)_too_short_min_?([\d]+)$'): (matches) =>
      "${_capitalize(matches[1])} must be at least ${matches[2]} character${_sIfPlural(matches[2])}.",
  RegExp(r'^([\w]+)_too_long_max_?([\d]+)$'): (matches) =>
      "${_capitalize(matches[1])} must be less than ${matches[2]} character${_sIfPlural(matches[2])}.",
  RegExp(r'^[\w]+$'): (matches) =>
      "${_capitalize(matches[0]).replaceAll('_', ' ')}.",
  RegExp(r'^global_public_users_require_PUBLISH_USERS_GLOBALLY_permission$'):
      (matches) =>
          '"Global Public" user visibility requires "Globally Publish Profile" permission.',
};

String formatServerError(Object e) {
  if (e is GrpcError) {
    return formatGrpcError(e);
  }
  return "An unknown error occurred.";
}

String formatGrpcError(GrpcError e) {
  if (e.message == null) {
    return "No message was included in the error.";
  }
  final message = e.message!;
  String? formattedMessage;
  grpcErrorConversions.forEach((expression, handler) {
    if (formattedMessage == null && expression.hasMatch(message)) {
      final match = expression.firstMatch(message)!;
      final groups = List<int>.generate(match.groupCount + 1, (i) => i);
      formattedMessage = handler(match.groups(groups));
    }
  });
  return formattedMessage ?? "Error message: $message";
}

_sIfPlural(s, {suffix = 's'}) => s == '1' ? '' : suffix;
_capitalize(String s) => s[0].toUpperCase() + s.substring(1);
