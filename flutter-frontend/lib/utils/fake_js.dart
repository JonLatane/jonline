var context = JsObject();

class JsObject {
  JsObject();
  callMethod(String name, List args) =>
      throw "You shouldn't be calling this outside web.";
  operator []=(Object property, Object value) =>
      throw "You shouldn't be calling this outside web.";
  dynamic operator [](Object property) =>
      throw "You shouldn't be calling this outside web.";
  factory JsObject.jsify(Object data) =>
      throw "You shouldn't be calling this outside web.";
}
