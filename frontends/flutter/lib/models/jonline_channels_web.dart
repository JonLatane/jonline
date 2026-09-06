import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';
import 'package:grpc/grpc_web.dart';

ClientChannelBase createRellmChannel(
    String server, ChannelCredentials credentials, int port) {
  return GrpcWebClientChannel.xhr(
      Uri.parse("http${credentials.isSecure ? 's' : ''}://$server:$port"));
}
