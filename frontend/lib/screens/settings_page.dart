import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/settings.dart';

class SettingsPage extends StatefulWidget {
  final String tab;
  final String query;

  const SettingsPage({
    Key? key,
    @pathParam required this.tab,
    @queryParam this.query = 'none',
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutoRouteAwareStateMixin<SettingsPage> {
  TextTheme get textTheme => Theme.of(context).textTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
            child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text("Prefer Server Previews",
                          style: textTheme.labelLarge)),
                  Switch(
                      value: Settings.preferServerPreviews,
                      onChanged: (v) {
                        setState(() => Settings.preferServerPreviews = v);
                        context.findRootAncestorStateOfType<AppState>()!
                          ..updatePosts()
                          ..updateAccountDependents();
                      }),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                      child: Text("Reply Layers to Load",
                          style: textTheme.labelLarge)),
                  if (MediaQuery.of(context).size.width > 450)
                    Slider(
                        min: 1,
                        max: 5,
                        divisions: 4,
                        value: Settings.replyLayersToLoad.toDouble(),
                        onChanged: (v) {
                          setState(
                              () => Settings.replyLayersToLoad = v.toInt());
                        }),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 16.0),
                      child: Text(
                        Settings.replyLayersToLoad.toString(),
                        style: textTheme.labelLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5)
                ],
              ),
              if (MediaQuery.of(context).size.width <= 450)
                Row(
                  children: [
                    const Expanded(child: SizedBox()),
                    Slider(
                        min: 1,
                        max: 5,
                        divisions: 4,
                        value: Settings.replyLayersToLoad.toDouble(),
                        onChanged: (v) {
                          setState(
                              () => Settings.replyLayersToLoad = v.toInt());
                        }),
                  ],
                ),
              Row(
                key: const Key('powerUserModeSetting'),
                children: [
                  Expanded(
                      child:
                          Text("Power User Mode", style: textTheme.labelLarge)),
                  Switch(
                      value: Settings.powerUserMode,
                      onChanged: (v) {
                        setState(() => Settings.powerUserMode = v);
                        context
                            .findRootAncestorStateOfType<AppState>()!
                            .updateAccountDependents();
                      }),
                ],
              ),
              Row(
                key: const Key('devModeSetting'),
                children: [
                  Expanded(
                      child:
                          Text("Developer Mode", style: textTheme.labelLarge)),
                  Switch(
                      value: Settings.developerMode,
                      onChanged: (v) {
                        setState(() => Settings.developerMode = v);
                        context
                            .findRootAncestorStateOfType<AppState>()!
                            .updateAccountDependents();
                      }),
                ],
              ),
            ],
          ),
        )),
      )),
    );
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    // print('init tab route from ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    // print('did change tab route from ${previousRoute.name}');
  }
}
