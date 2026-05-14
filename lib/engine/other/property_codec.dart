// Codec for a simple key value format: "key=value;key2=value2;..."
final class PropertyCodec {
  static Map<String, String> decode(String formattedData) {
    final Map<String, String> properties = {};

    int start = 0;
    while (start < formattedData.length) {
      final int eq = formattedData.indexOf('=', start);
      if (eq == -1) break;

      final int end = formattedData.indexOf(';', eq);
      if (end == -1) break;
      
      if (eq == start || eq == end - 1) {
        throw Exception('Error parsing parameters');
      }

      final String key = formattedData.substring(start, eq);
      final String value = formattedData.substring(eq + 1, end);
      properties[key] = value;

      start = end + 1;
    }
    return properties;
  }

  static String encode(Map<String, String> properties) {
    final StringBuffer buffer = StringBuffer();
    properties.forEach((key, value) {
      if (key.isEmpty || value.isEmpty) {
        throw Exception('Error writing parameters');
      }
      buffer.write('$key=$value;');
    });
    return buffer.toString();
  }
}