import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_connection_interface.dart';

ClientChannelBase createJonlineChannel(
    String server, ChannelCredentials credentials) {
  return ClientChannel(
    "jonline.$server",
    port: 27707,
    options: ChannelOptions(credentials: credentials),
  );
}
