import 'package:flutter/foundation.dart';

class Jonotifier extends ChangeNotifier {
  call() => notifyChange();
  notifyChange() => notifyListeners();
}

class BSValueMethod<T> extends ValueNotifier<T> {
  BSValueMethod(value) : super(value);
  call(value) => this.value = value;
}
