import 'package:grpc/grpc.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/generated/google/protobuf/empty.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/models/server_errors.dart';

extension JonlineClientOperations on JonlineAccount {}
