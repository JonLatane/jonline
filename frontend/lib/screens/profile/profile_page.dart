import 'package:auto_route/auto_route.dart';
import 'package:jonline/screens/home_page.dart';
import 'package:flutter/material.dart';

import '../../router/router.gr.dart';
import '../user-data/data_collector.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  UserData? userData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Accounts Created',
              style: Theme.of(context).textTheme.headline5,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.navigateNamedTo('/login');
              },
              child: const Text('Login to a server...'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.navigateNamedTo('/profile/activity');
                // context.router.push(MyBooksRoute());
              },
              child: const Text('My Activity'),
            ),

            if (context
                    .findRootAncestorStateOfType<HomePageState>()
                    ?.showSettingsTab ==
                false)
              Column(children: [
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      context
                          .findRootAncestorStateOfType<HomePageState>()
                          ?.showSettingsTab = true;
                    });
                    context.navigateNamedTo('settings/main');
                  },
                  child: const Text('Open Settings'),
                )
              ]),
            if (context
                    .findRootAncestorStateOfType<HomePageState>()
                    ?.showSettingsTab ==
                true)
              Column(children: [
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      context
                          .findRootAncestorStateOfType<HomePageState>()
                          ?.showSettingsTab = false;
                    });
                  },
                  child: const Text('Close Settings'),
                )
              ]),
            // const SizedBox(height: 32),
            // ElevatedButton(
            //   onPressed: () {
            //     context.navigateBack();
            //   },
            //   child: const Text('Navigate Back'),
            // ),
            const SizedBox(height: 32),
            userData == null
                ? ElevatedButton(
                    onPressed: () {
                      context.pushRoute(
                        UserDataCollectorRoute(onResult: (data) {
                          setState(() {
                            userData = data;
                          });
                        }),
                      );
                    },
                    child: const Text('Collect user data'),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Your Data is complete'),
                      const SizedBox(height: 24),
                      Text('Name: ${userData!.name}'),
                      const SizedBox(height: 24),
                      Text('Favorite book: ${userData!.favoriteBook}'),
                    ],
                  )
          ],
        ),
      ),
    );
  }
}
