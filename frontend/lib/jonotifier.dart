import 'package:flutter/foundation.dart';

class Jonotifier extends ChangeNotifier {
  call() => notifyChange();
  notifyChange() => notifyListeners();
}

class ValueJonotifer<T> extends ValueNotifier<T> {
  ValueJonotifer(value) : super(value);
  notify() => notifyListeners();
}
