import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/permissions.pbenum.dart';
import '../../models/jonline_account.dart';
import '../../models/jonline_server.dart';

// import 'package:jonline/db.dart';

class GroupChooser extends StatefulWidget {
  const GroupChooser({
    Key? key,
  }) : super(key: key);

  @override
  GroupChooserState createState() => GroupChooserState();
}

class GroupChooserState extends State<GroupChooser> {
  late AppState appState;
  TextTheme get textTheme => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    appState = context.findRootAncestorStateOfType<AppState>()!;
    appState.accounts.addListener(onAccountsChanged);
  }

  @override
  dispose() {
    appState.accounts.removeListener(onAccountsChanged);
    super.dispose();
  }

  onAccountsChanged() async {
    setState(() {});
  }

  int currentGroupNameIndex = 0;
  List<String> groupNames = ['', ''];
  String get currentGroupName => groupNames[currentGroupNameIndex];
  set currentGroupName(String name) {
    currentGroupNameIndex = (currentGroupNameIndex + 1) % 2;
    groupNames[currentGroupNameIndex] = name;
  }

  @override
  Widget build(BuildContext context) {
    double width = appState.selectedGroup.value == null ? 40 : 72;
    if (appState.selectedGroup.value != null &&
        appState.selectedGroup.value!.name != currentGroupName) {
      currentGroupName = appState.selectedGroup.value!.name;
    }
    print("width: $width");
    return AnimatedContainer(
      duration: animationDuration,
      width: width * MediaQuery.of(context).textScaleFactor,
      child: TextButton(
        style: ButtonStyle(
            padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
            foregroundColor:
                MaterialStateProperty.all(Colors.white.withAlpha(255)),
            overlayColor:
                MaterialStateProperty.all(Colors.white.withAlpha(100)),
            splashFactory: InkSparkle.splashFactory),
        onPressed: () {
          // HapticFeedback.lightImpact();
          final RenderBox button = context.findRenderObject() as RenderBox;
          final RenderBox? overlay =
              Overlay.of(context)?.context.findRenderObject() as RenderBox?;
          final RelativeRect position = RelativeRect.fromRect(
            Rect.fromPoints(
              button.localToGlobal(Offset.zero, ancestor: overlay),
              button.localToGlobal(button.size.bottomRight(Offset.zero),
                  ancestor: overlay),
            ),
            Offset.zero & (overlay?.size ?? Size.zero),
          );
          showGroupsMenu(context, position);
          // context.router.pop();
        },
        child: Stack(
          children: [
            AnimatedOpacity(
                opacity: appState.selectedGroup.value == null ? 1 : 0.5,
                duration: animationDuration,
                child: const Center(child: Icon(Icons.group_work_outlined))),
            ...groupNames.map(
              (name) => AnimatedOpacity(
                opacity: appState.selectedGroup.value?.name == name ? 1 : 0,
                duration: animationDuration,
                child: Center(
                    child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                )),
              ),
            )
          ],
        ),
      ),
    );
  }
}

Future<Object> showGroupsMenu(
    BuildContext context, RelativeRect position) async {
  ThemeData theme = Theme.of(context);
  TextTheme textTheme = theme.textTheme;
  ThemeData darkTheme = theme;
  final groups = context.findRootAncestorStateOfType<AppState>()!.groups.value;
  return showMenu(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // color: (musicBackgroundColor.luminance < 0.5
      //         ? subBackgroundColor
      //         : musicBackgroundColor)
      //     .withOpacity(0.95),
      items: [
        // PopupMenuItem(
        //   padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
        //   mouseCursor: SystemMouseCursors.basic,
        //   value: null,
        //   enabled: false,
        //   child: Text(
        //     'Accounts',
        //     style: darkTheme.textTheme.titleLarge,
        //   ),
        // ),
        PopupMenuItem(
          padding: EdgeInsets.zero,
          mouseCursor: SystemMouseCursors.basic,
          value: null,
          enabled: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    groups.isEmpty ? 'No Groups on ' : 'Groups on ',
                    style: groups.isEmpty
                        ? darkTheme.textTheme.titleMedium
                        : darkTheme.textTheme.titleLarge,
                  ),
                  Text(
                    "${JonlineServer.selectedServer.server}/",
                    style: darkTheme.textTheme.caption,
                  ),
                ],
              ),
            ),
            ...groups.map((a) => _groupItem(a, context)),
          ]),
        ),
      ]);
}

Widget _groupItem(Group g, BuildContext context) {
  ThemeData darkTheme = Theme.of(context);
  ThemeData lightTheme = ThemeData.light();
  bool selected = g.id ==
      context.findRootAncestorStateOfType<AppState>()!.selectedGroup.value?.id;
  ThemeData theme = selected ? lightTheme : darkTheme;
  TextTheme textTheme = theme.textTheme;
  return Theme(
    data: theme,
    child: Material(
      // color: backgroundColor,
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
          mouseCursor: SystemMouseCursors.basic,
          onTap: () {
            Navigator.pop(context);
            AppState appState =
                context.findRootAncestorStateOfType<AppState>()!;
            if (selected) {
              appState.selectedGroup.value = null;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "Viewing all groups on ${JonlineServer.selectedServer.server}.")),
              );
            } else {
              appState.selectedGroup.value = g;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        "Viewing ${g.name} on ${JonlineServer.selectedServer.server}.")),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Column(
                  children: const [Icon(Icons.group_work)],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("${JonlineServer.selectedServer.server}/",
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.caption),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(g.name,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.subtitle1),
                      ),
                    ],
                  ),
                ),
                if (g.currentUserMembership.permissions
                    .contains(Permission.ADMIN))
                  const Icon(Icons.admin_panel_settings_outlined, size: 16)
              ],
            ),
          )),
    ),
  );
}
