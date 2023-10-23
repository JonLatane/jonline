import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';

ClientChannelBase createJonlineChannel(
    String server, ChannelCredentials credentials, int port) {
  return ClientChannel(
    server,
    port: port,
    options: ChannelOptions(credentials: credentials),
  );
}
