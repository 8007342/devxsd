import 'dart:js_interop';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString url, _RequestInit options);
@JS('localStorage')
external _Storage get _storage;

extension type _RequestInit._(JSObject _) implements JSObject {
  external factory _RequestInit({
    JSString method,
    JSString body,
    JSObject headers,
  });
}

extension type _Response._(JSObject _) implements JSObject {
  external bool get ok;
  external JSPromise<JSString> text();
}

extension type _Storage._(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);
  external void setItem(JSString key, JSString value);
}

String? read(String key) {
  try {
    return _storage.getItem(key.toJS)?.toDart ?? _memory[key];
  } catch (_) {
    return _memory[key];
  }
}

final Map<String, String> _memory = {};
void write(String key, String value) {
  _memory[key] = value;
  try {
    _storage.setItem(key.toJS, value.toJS);
  } catch (_) {
    /* Private browsing may disallow storage. */
  }
}

Future<String> request(String mode, String? payload) async {
  final options = payload == null
      ? _RequestInit(method: 'GET'.toJS)
      : _RequestInit(
          method: 'POST'.toJS,
          body: payload.toJS,
          headers: {'Content-Type': 'application/json'}.jsify() as JSObject,
        );
  final response = await _fetch(
    '/api/leaderboard?mode=$mode'.toJS,
    options,
  ).toDart.timeout(const Duration(seconds: 4));
  if (!response.ok) throw StateError('Shared leaderboard unavailable');
  return (await response.text().toDart).toDart;
}
