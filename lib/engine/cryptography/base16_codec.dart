import 'dart:convert';
import 'dart:typed_data';

const Base16Codec base16 = Base16Codec();

String base16Encode(final Uint8List input) => base16.encode(input);

Uint8List base16Decode(final String encoded) => base16.decode(encoded);

class Base16Codec extends Codec<Uint8List, String>{
  const Base16Codec();

  @override
  final Converter<String, Uint8List> decoder = const Base16Decoder();

  @override
  final Converter<Uint8List, String> encoder = const Base16Encoder();
}

class Base16Encoder extends Converter<Uint8List, String>{
  const Base16Encoder();

  @override
  String convert(final Uint8List input) => input.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}

class Base16Decoder extends Converter<String, Uint8List>{
  const Base16Decoder();

  @override
  Uint8List convert(final String input) {
    List<int> result = [];
    for(int i=0; i<input.length; i+=2) {
      result.add(int.parse(input.substring(i, i+2), radix: 16));
    }
    return Uint8List.fromList(result);
  }
}