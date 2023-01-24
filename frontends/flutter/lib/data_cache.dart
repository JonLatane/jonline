import 'package:flutter/foundation.dart';

import 'jonotifier.dart';

abstract class DataCache<ListingType, DataKeyType, ResultType>
    implements Listenable {
  final ValueNotifier<ListingType> listingTypeNotifier;
  ListingType get listingType => listingTypeNotifier.value;
  set listingType(ListingType value) => listingTypeNotifier.value = value;

  final ValueJonotifier<Map<DataKeyType, ResultType>> _data =
      ValueJonotifier(<DataKeyType, ResultType>{});

  DataKeyType Function()? getCurrentKey;

  ResultType get value {
    if (getCurrentKey == null) {
      Future.microtask(update);
      return emptyResult;
    }
    final key = getCurrentKey!();
    var result = _data.value[key];
    if (result == null) {
      result = emptyResult!;
      _data.value[key] = result;
      Future.microtask(update);
    }
    return result;
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
    _updatingNotifier.value = true;
    final ResultType? result = await getCurrentData();
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

  ResultType get mainValue => _data.value[mainKey] ?? emptyResult;
  DataKeyType get mainKey;
  Future<ResultType?> getCurrentData();

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
