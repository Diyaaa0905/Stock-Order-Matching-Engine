import 'dart:convert';
import 'dart:typed_data';

/// Pure Dart SHA-256 implementation with zero external package dependencies.
/// Meets FIPS 180-4 standard specification.
class CryptoHelper {
  static final List<int> _k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
  ];

  static int _rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xFFFFFFFF;
  static int _ch(int x, int y, int z) => ((x & y) ^ ((~x) & z)) & 0xFFFFFFFF;
  static int _maj(int x, int y, int z) => ((x & y) ^ (x & z) ^ (y & z)) & 0xFFFFFFFF;
  static int _sigma0(int x) => (_rotr(x, 2) ^ _rotr(x, 13) ^ _rotr(x, 22)) & 0xFFFFFFFF;
  static int _sigma1(int x) => (_rotr(x, 6) ^ _rotr(x, 11) ^ _rotr(x, 25)) & 0xFFFFFFFF;
  static int _gamma0(int x) => (_rotr(x, 7) ^ _rotr(x, 18) ^ (x >> 3)) & 0xFFFFFFFF;
  static int _gamma1(int x) => (_rotr(x, 17) ^ _rotr(x, 19) ^ (x >> 10)) & 0xFFFFFFFF;

  static String sha256Hash(String input) {
    final List<int> bytes = utf8.encode(input);
    final int bitLength = bytes.length * 8;

    // Pre-processing (Padding)
    final int newLength = ((bytes.length + 8) ~/ 64 + 1) * 64;
    final Uint8List padded = Uint8List(newLength);
    padded.setRange(0, bytes.length, bytes);
    padded[bytes.length] = 0x80;

    final ByteData bd = ByteData.view(padded.buffer);
    bd.setUint64(newLength - 8, bitLength, Endian.big);

    // Initial Hash Values
    int h0 = 0x6a09e667;
    int h1 = 0xbb67ae85;
    int h2 = 0x3c6ef372;
    int h3 = 0xa54ff53a;
    int h4 = 0x510e527f;
    int h5 = 0x9b05688c;
    int h6 = 0x1f83d9ab;
    int h7 = 0x5be0cd19;

    final Uint32List w = Uint32List(64);

    for (int chunk = 0; chunk < newLength; chunk += 64) {
      for (int i = 0; i < 16; i++) {
        w[i] = bd.getUint32(chunk + (i * 4), Endian.big);
      }
      for (int i = 16; i < 64; i++) {
        final int s0 = _gamma0(w[i - 15]);
        final int s1 = _gamma1(w[i - 2]);
        w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xFFFFFFFF;
      }

      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;
      int f = h5;
      int g = h6;
      int h = h7;

      for (int i = 0; i < 64; i++) {
        final int s1 = _sigma1(e);
        final int ch = _ch(e, f, g);
        final int temp1 = (h + s1 + ch + _k[i] + w[i]) & 0xFFFFFFFF;
        final int s0 = _sigma0(a);
        final int maj = _maj(a, b, c);
        final int temp2 = (s0 + maj) & 0xFFFFFFFF;

        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xFFFFFFFF;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xFFFFFFFF;
      }

      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
      h5 = (h5 + f) & 0xFFFFFFFF;
      h6 = (h6 + g) & 0xFFFFFFFF;
      h7 = (h7 + h) & 0xFFFFFFFF;
    }

    final StringBuffer sb = StringBuffer();
    for (final int h in <int>[h0, h1, h2, h3, h4, h5, h6, h7]) {
      sb.write(h.toRadixString(16).padLeft(8, '0'));
    }
    return sb.toString();
  }
}
