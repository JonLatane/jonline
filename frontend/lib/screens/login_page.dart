import 'package:jonline/router/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final void Function(bool isLoggedIn)? onLoginResult;
  final bool showBackButton;
  const LoginPage({Key? key, this.onLoginResult, this.showBackButton = true})
      : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FocusNode serverFocus = FocusNode();
  final TextEditingController serverController = TextEditingController();
  final FocusNode usernameFocus = FocusNode();
  final TextEditingController usernameController = TextEditingController();
  final FocusNode passwordFocus = FocusNode();
  final TextEditingController passwordController = TextEditingController();

  @override
  dispose() {
    serverFocus.dispose();
    serverController.dispose();
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
              TextField(
                focusNode: serverFocus,
                controller: serverController,
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
                    hintText: "Server (default: jonline.io)",
                    isDense: true),
                onChanged: (value) {
                  // widget.melody.name = value;
                  //                          BeatScratchPlugin.updateMelody(widget.melody);
                  // BeatScratchPlugin.onSynthesizerStatusChange();
                },
              ),
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
              ElevatedButton(
                onPressed: () {
                  context.read<AuthService>().isAuthenticated = true;
                  widget.onLoginResult?.call(true);
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
