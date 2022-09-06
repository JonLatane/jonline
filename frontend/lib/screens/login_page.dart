import 'package:another_flushbar/flushbar.dart';
import 'package:grpc/grpc.dart';
import 'package:jonline/generated/authentication.pb.dart';
import 'package:jonline/generated/jonline.pbgrpc.dart';
import 'package:jonline/models/jonline_account.dart';
import 'package:jonline/router/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:overlay_support/overlay_support.dart';

import '../generated/google/protobuf/empty.pb.dart';

class LoginPage extends StatefulWidget {
  final void Function(bool isLoggedIn)? onLoginResult;
  final bool showBackButton;
  const LoginPage({Key? key, this.onLoginResult, this.showBackButton = true})
      : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final FocusNode serverFocus = FocusNode();
  // final TextEditingController serverController = TextEditingController();
  final FocusNode usernameFocus = FocusNode();
  final TextEditingController usernameController = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  final TextEditingController passwordController = TextEditingController();

  String get serverAndUser => usernameController.value.text;
  String get server =>
      serverAndUser.contains('/') ? serverAndUser.split('/')[0] : 'jonline.io';
  String get username =>
      serverAndUser.contains('/') ? serverAndUser.split('/')[1] : serverAndUser;
  String get password => passwordController.value.text;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    usernameController.addListener(() {
      setState(() {});
    });
  }

  @override
  dispose() {
    // serverFocus.dispose();
    // serverController.dispose();
    usernameFocus.dispose();
    usernameController.dispose();
    passwordFocus.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          // automaticallyImplyLeading: showBackButton,
          // title: Text('Login to continue'),
          ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Column(
            children: [
              const Expanded(
                child: SizedBox(),
              ),
              // TextField(
              //   focusNode: serverFocus,
              //   controller: serverController,
              //   enableSuggestions: false,
              //   autocorrect: false,
              //   maxLines: 1,
              //   cursorColor: Colors.white,
              //   style: const TextStyle(
              //       color: Colors.white,
              //       fontWeight: FontWeight.w400,
              //       fontSize: 14),
              //   enabled: true,
              //   decoration: const InputDecoration(
              //       border: InputBorder.none,
              //       hintText: "Server (default: jonline.io)",
              //       isDense: true),
              //   onChanged: (value) {
              //     // widget.melody.name = value;
              //     //                          BeatScratchPlugin.updateMelody(widget.melody);
              //     // BeatScratchPlugin.onSynthesizerStatusChange();
              //   },
              // ),
              TextField(
                focusNode: usernameFocus,
                controller: usernameController,
                enableSuggestions: false,
                autocorrect: false,
                maxLines: 1,
                cursorColor: Colors.white,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 14),
                enabled: true,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Username",
                    isDense: true),
                onChanged: (value) {
                  // widget.melody.name = value;
                  //                          BeatScratchPlugin.updateMelody(widget.melody);
                  // BeatScratchPlugin.onSynthesizerStatusChange();
                },
              ),
              // Row(
              //   children: [
              //     const Expanded(child: SizedBox()),
              Text(
                "Specify a custom server with \"/\". e.g. jonline.io/jon, bobline.io/jon, ${server == 'jonline.io' || server == 'bobline.io' ? '' : "$server/bob, "}etc.",
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 11),
              ),
              //   ],
              // ),
              // Row(
              //   children: [
              //     const Expanded(child: SizedBox()),
              Text(
                "This user should exist on $server.",
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 11),
              ),
              //   ],
              // ),
              const SizedBox(height: 16),
              TextField(
                focusNode: passwordFocus,
                controller: passwordController,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                maxLines: 1,
                cursorColor: Colors.white,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 14),
                enabled: true,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Password",
                    isDense: true),
                onChanged: (value) {
                  // widget.melody.name = value;
                  //                          BeatScratchPlugin.updateMelody(widget.melody);
                  // BeatScratchPlugin.onSynthesizerStatusChange();
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final account = await JonlineAccount.loginToAccount(
                      server, username, password, context, showSnackBar);
                  if (!mounted) return;
                  if (account != null) {
                    context.navigateBack();
                  }
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  final account = await JonlineAccount.createAccount(
                      server, username, password, context, showSnackBar);
                  if (!mounted) return;
                  if (account != null) {
                    context.navigateBack();
                  }
                },
                child: const Text('Create Account'),
              ),
              const Expanded(
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  showSnackBar(String message) {
    showSimpleNotification(
        Text(message, style: const TextStyle(color: Colors.white)),
        position: NotificationPosition.bottom,
        background: Colors.black);

    // MultiSnackBarInterface.setMaxListLength(maxLength: 4);
    // MultiSnackBarInterface.show(
    //     context: context,
    //     snackBar: SnackBar(
    //       content: Text(message),
    //     ));
    // Flushbar(
    //   // title:  "Hey Ninja",
    //   message: message,
    //   isDismissible: false,
    //   duration: const Duration(seconds: 3),
    // ).show(context);
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //   content: Text(message),
    // ));
  }
}
