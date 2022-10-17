import 'package:flutter/foundation.dart';

import '../models/jonline_account_operations.dart';
import '../screens/accounts/server_configuration_page.dart';
import '../screens/login_page.dart';
import 'db.dart';
import 'generated/server_configuration.pb.dart';
import 'generated/groups.pb.dart';
import 'generated/posts.pb.dart';
import 'generated/users.pb.dart';
import 'generated/users.pb.dart' as u;
import 'jonotifier.dart';
import 'main.dart';
import 'models/jonline_account.dart';
import 'models/jonline_operations.dart';
import 'models/jonline_server.dart';
import 'models/settings.dart';
import 'my_platform.dart';
import 'router/auth_guard.dart';
import 'router/router.gr.dart';

abstract class DataCache<ListingType, DataKeyType, ResultType>
    implements Listenable {
  final ValueNotifier<ListingType> listingTypeNotifier;
  ListingType get listingType => listingTypeNotifier.value;
  set listingType(ListingType value) => listingTypeNotifier.value = value;

  final ValueJonotifier<Map<DataKeyType, ResultType>> _data =
      ValueJonotifier(<DataKeyType, ResultType>{});

  DataKeyType Function()? getCurrentKey;
  Future<ResultType?> Function()? getCurrentData;

  ResultType get value {
    if (getCurrentKey == null) {
      Future.microtask(update);
      return emptyResult;
    }
    final key = getCurrentKey!();
    _data.value[key] ??= emptyResult;
    return _data.value[key]!;
  }

  set value(ResultType value) {
    if (getCurrentKey == null) {
      return;
    }
    final key = getCurrentKey!();
    _data.value[key] = value;
    _data.notify();
  }

  final ValueNotifier<bool> _updatingNotifier = ValueNotifier(true);
  bool get updating => _updatingNotifier.value;
  final ValueNotifier<bool> _errorUpdatingNotifier = ValueNotifier(false);
  bool get errorUpdating => _errorUpdatingNotifier.value;
  final ValueNotifier<bool> _didUpdateNotifier = ValueNotifier(false);
  bool get didUpdate => _didUpdateNotifier.value;

  hardReset() {
    _updatingNotifier.value = true;
    _data.value = <DataKeyType, ResultType>{};

    update();
  }

  reset() {
    _updatingNotifier.value = true;
    value = emptyResult;

    update();
  }

  Future<void> update({Function(String)? showMessage}) async {
    if (getCurrentData == null) return;

    _updatingNotifier.value = true;
    final ResultType? result = await getCurrentData!();
    if (result == null) {
      _errorUpdatingNotifier.value = true;
      _updatingNotifier.value = false;
      return;
    }

    _didUpdateNotifier.value = true;
    // await animationDelay;

    _updatingNotifier.value = false;
    value = result;
    _didUpdateNotifier.value = false;
    // await communicationDelay;
    // showMessage?.call("Posts updated! 🎉");
  }

  ResultType get mainValue;

  DataCache(this.listingTypeNotifier) {
    _updatingNotifier.addListener(() {
      if (_updatingNotifier.value) _errorUpdatingNotifier.value = false;
    });
  }

  ResultType get emptyResult;
  @override
  void addListener(VoidCallback listener) {
    _data.addListener(listener);
    listingTypeNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _data.removeListener(listener);
    listingTypeNotifier.removeListener(listener);
  }

  void addStatusListener(VoidCallback listener) {
    _data.addListener(listener);
    _updatingNotifier.addListener(listener);
    _errorUpdatingNotifier.addListener(listener);
    _didUpdateNotifier.addListener(listener);
  }

  void removeStatusListener(VoidCallback listener) {
    _data.removeListener(listener);
    _updatingNotifier.removeListener(listener);
    _errorUpdatingNotifier.removeListener(listener);
    _didUpdateNotifier.removeListener(listener);
  }
}

class PostDataKey {
  final String? groupId;
  final PostListingType postListingType;
  PostDataKey(this.groupId, this.postListingType);
  @override
  int get hashCode => groupId.hashCode + postListingType.hashCode;
  @override
  bool operator ==(other) =>
      other is PostDataKey &&
      other.groupId == groupId &&
      other.postListingType == postListingType;
}

class PostCache
    extends DataCache<PostListingType, PostDataKey, GetPostsResponse> {
  PostCache() : super(ValueNotifier(PostListingType.PUBLIC_POSTS));

  @override
  GetPostsResponse get emptyResult => GetPostsResponse();

  @override
  GetPostsResponse get mainValue =>
      _data.value[PostDataKey(null, PostListingType.PUBLIC_POSTS)] ??
      emptyResult;
}
