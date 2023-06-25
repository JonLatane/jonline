import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:username_gen/username_gen.dart';

import '../../app_state.dart';
import '../../generated/groups.pb.dart';
import '../../generated/jonline.pbgrpc.dart';
import '../../generated/permissions.pbenum.dart';
import '../../generated/users.pb.dart';
import '../../my_platform.dart';
import '../jonline_account.dart';
import '../jonline_account_operations.dart';
import '../jonline_clients.dart';
import 'demo_groups.dart';

Future<List<JonlineAccount>> generateSideAccounts(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    int count) async {
  final List<int> range = [for (var i = 0; i < count; i += 1) i];
  final List<Uint8List> avatars = [];
  final httpClient = http.Client();

  var lastMessageTime = DateTime.now();
  while (avatars.length < range.length) {
    http.Response response = await httpClient
        .get(Uri.parse('https://100k-faces.glitch.me/random-image'), headers: {
      if (!MyPlatform.isWeb) "User-Agent": "Jonline Flutter Client",
      // if (!MyPlatform.isWeb) "Host": "thispersondoesnotexist.com"
    });
    avatars.add(response.bodyBytes);
  }

  showSnackBar("Loaded ${avatars.length} avatars.");

  Iterable<Future<JonlineAccount?>> futures = range.map((i) async {
    JonlineAccount? sideAccount;
    String fakeAccountName = generateRandomName();
    int retryCount = 0;
    int sideAccountsLoaded = 0;
    lastMessageTime = DateTime.now();
    while (retryCount < 15) {
      try {
        final JonlineAccount? sideAccount = await JonlineAccount.createAccount(
            account.server, fakeAccountName, getRandomString(15), (m) {
          // if (!m.contains("insecurely") &&
          //     !m.contains("already exists") &&
          //     !m.contains("Failed to create account")) {
          //   showSnackBar(m);
          // }
        }, allowInsecure: account.allowInsecure, selectAccount: false);
        if (sideAccount != null) {
          final User? user = await sideAccount.updateUserData();
          if (user != null) {
            user.permissions.add(Permission.RUN_BOTS);
            if (avatars.length > i) {
              final avatar = avatars[i];
              // final compressedAvatar = encodeJpg(avatar);
              final uploadResult = await http
                  .post(
                    Uri.parse("https://${account.server}/media"),
                    headers: {
                      "Content-Type": "image/jpeg",
                      "Filename": "avatar.jpeg",
                      // Can be handy to use main account access token as well here...
                      "Authorization": sideAccount.accessToken
                    },
                    body: avatar,
                  )
                  .onError((error, stackTrace) => http.post(
                        Uri.parse("http://${account.server}/media"),
                        headers: {
                          "Content-Type": "image/jpeg",
                          "Filename": "avatar.jpeg",
                          "Authorization": sideAccount.accessToken
                        },
                        body: avatar,
                      ))
                  .onError((error, stackTrace) =>
                      showSnackBar("Failed to upload avatar: $error"));
              if (uploadResult.statusCode == 200) {
                user.avatarMediaId = uploadResult.body;
              }
              // client.get
              // JonlineServer? server = account.server;
              // await client.updateUser(user,
              //     options: account.authenticatedCallOptions);

              // user.avatar = encodeJpg(avatar);
            }
            await client.updateUser(user,
                options: account.authenticatedCallOptions);
            await sideAccount.updateUserData();
          }
          appState.updateAccountList();
          sideAccountsLoaded++;
          if (shouldNotify(lastMessageTime)) {
            showSnackBar("Created $sideAccountsLoaded/$count side accounts...");
            lastMessageTime = DateTime.now();
          }
          return sideAccount;
        }
      } catch (e) {
        fakeAccountName = generateRandomName();
        retryCount++;
      }
    }
    return sideAccount;
  });

  List<JonlineAccount> sideAccounts =
      (await Future.wait(futures.toList())).whereNotNull().toList();
  showSnackBar("Created ${sideAccounts.length} side accounts.");

  return sideAccounts;
}

Future<int> generateFollowRelationships(
    JonlineClient client,
    JonlineAccount account,
    Function(String) showSnackBar,
    AppState appState,
    List<JonlineAccount> sideAccounts) async {
  //Generate follow relationships between side accounts and originating account
  int relationshipsCreated = 0;

  final originalAccountDupes = sideAccounts.length * 2;
  final targetAccounts = [
    ...List.filled(originalAccountDupes, account),
    ...sideAccounts
  ];
  var lastMessageTime = DateTime.now();
  for (final sideAccount in sideAccounts) {
    // showSnackBar("Creating relationships for ${sideAccount.username}.");
    final followedAccounts = [sideAccount];
    final maxFollows = targetAccounts.length - originalAccountDupes;
    final totalFollows = 3 + Random().nextInt(max(0, maxFollows - 3));
    try {
      for (int i = 0; i < totalFollows; i++) {
        final followableAccounts = List.of(targetAccounts)
          ..removeWhere((a) => followedAccounts.contains(a));
        final targetAccount =
            followableAccounts[_random.nextInt(followableAccounts.length)];
        followedAccounts.add(targetAccount);
        await client.createFollow(
            Follow()
              ..userId = sideAccount.userId
              ..targetUserId = targetAccount.userId,
            options: sideAccount.authenticatedCallOptions);
        relationshipsCreated += 1;

        if (shouldNotify(lastMessageTime)) {
          showSnackBar("Created $relationshipsCreated follow relationships.");
          lastMessageTime = DateTime.now();
        }
      }
    } catch (e) {
      showSnackBar("Error following side account: $e");
    }
  }
  return relationshipsCreated;
}

Future<int> generateGroupMemberships(
    JonlineClient client,
    JonlineAccount account,
    Map<DemoGroup, Group> demoGroups,
    Function(String) showSnackBar,
    AppState appState,
    List<JonlineAccount> sideAccounts) async {
  int membershipsCreated = 0;
  var lastMessageTime = DateTime.now();

  for (final sideAccount in sideAccounts) {
    // showSnackBar("Creating relationships for ${sideAccount.username}.");
    final targetGroups = List.of(demoGroups.values);
    final maxJoins = targetGroups.length;
    final totalJoins = 2 + Random().nextInt(max(0, maxJoins - 2));
    try {
      for (int i = 0; i < totalJoins; i++) {
        final group = targetGroups[_random.nextInt(targetGroups.length)];
        await client.createMembership(
            Membership()
              ..userId = sideAccount.userId
              ..groupId = group.id,
            options: sideAccount.authenticatedCallOptions);
        targetGroups.remove(group);
        membershipsCreated += 1;

        if (shouldNotify(lastMessageTime)) {
          showSnackBar("Created $membershipsCreated group memberships.");
          lastMessageTime = DateTime.now();
        }
      }
    } catch (e) {
      showSnackBar("Error following side account: $e");
    }
  }
  return membershipsCreated;
}

String generateRandomName() => UsernameGen().generate();
shouldNotify(DateTime lastMessageTime) =>
    DateTime.now().difference(lastMessageTime) > const Duration(seconds: 5);
final _random = Random();
const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))));
