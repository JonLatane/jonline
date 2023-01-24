import 'package:flutter/foundation.dart';

class Jonotifier extends ChangeNotifier {
  call() => notifyChange();
  notifyChange() => notifyListeners();
}

class ValueJonotifier<T> extends ValueNotifier<T> {
  ValueJonotifier(value) : super(value);
  notify() => notifyListeners();
}
