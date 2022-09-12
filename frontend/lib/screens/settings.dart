import 'package:auto_route/auto_route.dart';
import 'package:jonline/router/router.gr.dart';
import 'package:flutter/material.dart';

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
  var queryUpdateCont = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.tab),
            Text(widget.query),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    queryUpdateCont++;
                  });
                  context.navigateTo(SettingsTab(
                    tab: 'Updated Path param $queryUpdateCont',
                    query: 'updated Query $queryUpdateCont',
                  ));
                },
                child: Text('Update Query $queryUpdateCont')),
            ElevatedButton(
                onPressed: () {
                  context.navigateTo(PostsTab(
                    children: [PostDetailsRoute(id: "some id")],
                  ));
                },
                child: const Text('Navigate to book details/1'))
          ],
        ),
      ),
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
