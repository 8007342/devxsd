final Map<String, String> _memory = {};
String? read(String key) => _memory[key];
void write(String key, String value) => _memory[key] = value;
Future<String> request(String mode, String? payload) =>
    Future.error(UnsupportedError('Shared board requires the web preview.'));
