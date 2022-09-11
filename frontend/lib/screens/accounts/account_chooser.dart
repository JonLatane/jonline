import 'package:flutter/material.dart';
import 'package:jonline/app_state.dart';
import 'package:jonline/models/jonline_account.dart';

// import 'package:jonline/db.dart';

class AccountChooser extends StatefulWidget {
  const AccountChooser({
    Key? key,
  }) : super(key: key);

  @override
  AccountChooserState createState() => AccountChooserState();
}

class AccountChooserState extends State<AccountChooser> {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: TextButton(
        style: ButtonStyle(
            padding: MaterialStateProperty.all(const EdgeInsets.all(0)),
            foregroundColor:
                MaterialStateProperty.all(Colors.white.withAlpha(100)),
            overlayColor:
                MaterialStateProperty.all(Colors.white.withAlpha(100)),
            splashFactory: InkSparkle.splashFactory),
        onPressed: () {
          // context.router.pop();
        },
        child: Column(
          children: [
            const Expanded(child: SizedBox()),
            Text('${JonlineAccount.selectedServer}/',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.caption),
            Text(JonlineAccount.selectedAccount?.username ?? 'no one',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.subtitle2),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    );
  }
}
