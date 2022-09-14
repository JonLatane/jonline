import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:grpc/grpc_web.dart';

ClientChannelBase createJonlineChannel(
    String server, ChannelCredentials credentials) {
  return GrpcWebClientChannel.xhr(Uri.parse(
      "http${credentials.isSecure ? 's' : ''}://jonline.$server:27707"));
}
