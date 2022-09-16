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
                  const Expanded(child: Text("Prefer Server Previews")),
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
              Row(
                children: [
                  const Expanded(child: Text("Power User Mode")),
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
                children: [
                  const Expanded(child: Text("Developer Mode")),
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
      // Center(
      //   child: Column(
      //     mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Text(widget.tab),
      //       Text(widget.query),
      //       ElevatedButton(
      //           onPressed: () {
      //             setState(() {
      //               queryUpdateCont++;
      //             });
      //             context.navigateTo(SettingsTab(
      //               tab: 'Updated Path param $queryUpdateCont',
      //               query: 'updated Query $queryUpdateCont',
      //             ));
      //           },
      //           child: Text('Update Query $queryUpdateCont')),
      //       ElevatedButton(
      //           onPressed: () {
      //             context.navigateTo(PostsTab(
      //               children: [PostDetailsRoute(id: "some id")],
      //             ));
      //           },
      //           child: const Text('Navigate to book details/1'))
      //     ],
      //   ),
      // ),
    );
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    print('init tab route from ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    print('did change tab route from ${previousRoute.name}');
  }
}
