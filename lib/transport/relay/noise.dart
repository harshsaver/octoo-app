import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

/// Noise_XX_25519_ChaChaPoly_BLAKE2b, byte-compatible with October's
/// relay channel (october-desktop `src/shared/remoteChannel.ts`, the
/// `noise-handshake` library). Checked against `remoteChannel.vectors.ts`.
///
/// - Prologue: `"october-remote/1" ‖ hostId (16) ‖ bind (16) ‖ connectionId u64 BE`.
/// - The phone is the initiator; all handshake payloads are empty.
/// - ChaCha20-Poly1305 (IETF), nonce = 4 zero bytes ‖ LE64(n).
/// - HKDF over HMAC-BLAKE2b with a 128-byte block (written here: the
///   package's Blake2b reports a 64-byte block, which would be wrong).
/// - At most 2^31 messages per direction; no rekey.

const _protocolName = 'Noise_XX_25519_ChaChaPoly_BLAKE2b';
const _hashLen = 64;
const _blockLen = 128;
const _keyLen = 32;
const channelMessageLimit = 1 << 31;

final _blake2b = DartBlake2b();
final _x25519 = DartX25519();
final _aead = DartChacha20.poly1305Aead();

class NoiseException implements Exception {
  const NoiseException(this.message, {this.authentication = false});

  final String message;

  /// Decryption or a pinned-key check failed.
  final bool authentication;

  @override
  String toString() => 'NoiseException($message)';
}

/// An X25519 key pair as raw bytes.
class NoiseKeyPair {
  NoiseKeyPair({required this.publicKey, required this.privateKey}) {
    if (publicKey.length != _keyLen || privateKey.length != _keyLen) {
      throw const NoiseException('Noise keys must be 32 bytes');
    }
  }

  final Uint8List publicKey;
  final Uint8List privateKey;

  static Future<NoiseKeyPair> generate() async {
    final pair = await _x25519.newKeyPair();
    return NoiseKeyPair(
      publicKey: Uint8List.fromList((await pair.extractPublicKey()).bytes),
      privateKey: Uint8List.fromList(await pair.extractPrivateKeyBytes()),
    );
  }

  /// libsodium `crypto_kx_seed_keypair`: sk = BLAKE2b-256(seed), pk = X25519(sk).
  static Future<NoiseKeyPair> fromSeed(List<int> seed) async {
    final sk = (await DartBlake2b(hashLengthInBytes: 32).hash(seed)).bytes;
    return fromPrivateKey(sk);
  }

  static Future<NoiseKeyPair> fromPrivateKey(List<int> privateKey) async {
    final pair = await _x25519.newKeyPairFromSeed(privateKey);
    return NoiseKeyPair(
      publicKey: Uint8List.fromList((await pair.extractPublicKey()).bytes),
      privateKey: Uint8List.fromList(privateKey),
    );
  }

  Future<Uint8List> dh(List<int> remotePublic) async {
    final shared = await _x25519.sharedSecretKey(
      keyPair: SimpleKeyPairData(privateKey, publicKey: SimplePublicKey(publicKey, type: KeyPairType.x25519), type: KeyPairType.x25519),
      remotePublicKey: SimplePublicKey(remotePublic, type: KeyPairType.x25519),
    );
    final bytes = Uint8List.fromList(await shared.extractBytes());
    // A low-order public key gives an all-zero secret; libsodium refuses
    // it, and so does this.
    if (bytes.every((b) => b == 0)) throw const NoiseException('invalid public key', authentication: true);
    return bytes;
  }
}

final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

Uint8List uuidBytes(String value) {
  if (!_uuid.hasMatch(value)) throw const NoiseException('expected a canonical lowercase UUID');
  final hex = value.replaceAll('-', '');
  return Uint8List.fromList([for (var i = 0; i < 32; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)]);
}

/// The channel's binding prologue.
Uint8List channelPrologue(String hostId, String bind, int connectionId) {
  final out = BytesBuilder()
    ..add(ascii.encode('october-remote/1'))
    ..add(uuidBytes(hostId))
    ..add(uuidBytes(bind));
  final id = ByteData(8)..setUint64(0, connectionId);
  out.add(id.buffer.asUint8List());
  return out.toBytes();
}

/// The 6-digit code both screens show: u32 BE of the handshake hash mod 10^6.
String pairingCode(Uint8List handshakeHash) {
  if (handshakeHash.length < 4) throw const NoiseException('handshake hash too short');
  final value = ByteData.sublistView(handshakeHash).getUint32(0);
  return (value % 1000000).toString().padLeft(6, '0');
}

/// Throws unless [remote] is the expected (pinned) host key. Constant-time.
void pinnedOrThrow(Uint8List? remote, Uint8List expected) {
  bool zero(Uint8List b) => b.every((x) => x == 0);
  if (remote == null || remote.length != _keyLen || expected.length != _keyLen || zero(remote) || zero(expected)) {
    throw const NoiseException('pinned key mismatch', authentication: true);
  }
  var diff = 0;
  for (var i = 0; i < _keyLen; i++) {
    diff |= remote[i] ^ expected[i];
  }
  if (diff != 0) throw const NoiseException('pinned key mismatch', authentication: true);
}

Future<Uint8List> _hash(List<int> data) async => Uint8List.fromList((await _blake2b.hash(data)).bytes);

Future<Uint8List> _hmac(List<int> key, List<int> data) async {
  var k = key.length > _blockLen ? await _hash(key) : Uint8List.fromList(key);
  if (k.length < _blockLen) k = Uint8List(_blockLen)..setAll(0, k);
  final inner = Uint8List(_blockLen + data.length);
  final outer = Uint8List(_blockLen + _hashLen);
  for (var i = 0; i < _blockLen; i++) {
    inner[i] = k[i] ^ 0x36;
    outer[i] = k[i] ^ 0x5c;
  }
  inner.setAll(_blockLen, data);
  outer.setAll(_blockLen, await _hash(inner));
  return _hash(outer);
}

/// Noise HKDF: two (or three) HASHLEN outputs.
Future<List<Uint8List>> _hkdf(List<int> chainingKey, List<int> ikm, int outputs) async {
  final temp = await _hmac(chainingKey, ikm);
  final o1 = await _hmac(temp, [1]);
  final o2 = await _hmac(temp, [...o1, 2]);
  if (outputs == 2) return [o1, o2];
  final o3 = await _hmac(temp, [...o2, 3]);
  return [o1, o2, o3];
}

List<int> _nonce(int n) {
  final b = ByteData(12)..setUint64(4, n, Endian.little);
  return b.buffer.asUint8List();
}

/// One direction of an established channel.
class NoiseCipher {
  /// [counter] is where the nonce starts (tests of the message cap).
  NoiseCipher(List<int> key, {int counter = 0})
    : _key = SecretKeyData(Uint8List.fromList(key.sublist(0, _keyLen))),
      _n = counter;

  final SecretKeyData _key;
  int _n;

  int get count => _n;

  Future<Uint8List> encrypt(List<int> plaintext, {List<int> ad = const []}) async {
    if (_n >= channelMessageLimit) throw const NoiseException('channel message limit reached');
    // The nonce is taken before the await, so overlapping calls never share
    // one; callers still send in call order.
    final n = _n++;
    final box = await _aead.encrypt(plaintext, secretKey: _key, nonce: _nonce(n), aad: ad);
    return Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
  }

  Future<Uint8List> decrypt(List<int> ciphertext, {List<int> ad = const []}) async {
    if (_n >= channelMessageLimit) throw const NoiseException('channel message limit reached');
    if (ciphertext.length < 16) throw const NoiseException('ciphertext too short', authentication: true);
    final n = _n++;
    try {
      final clear = await _aead.decrypt(
        SecretBox(
          ciphertext.sublist(0, ciphertext.length - 16),
          nonce: _nonce(n),
          mac: Mac(ciphertext.sublist(ciphertext.length - 16)),
        ),
        secretKey: _key,
        aad: ad,
      );
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const NoiseException('authentication failed', authentication: true);
    }
  }
}

/// Both directions after the handshake.
class NoiseChannel {
  NoiseChannel(this.send, this.receive, this.handshakeHash, this.remoteStatic);

  final NoiseCipher send;
  final NoiseCipher receive;
  final Uint8List handshakeHash;
  final Uint8List remoteStatic;
}

/// The XX handshake for one side. Messages: → e; ← e, ee, s, es; → s, se.
class NoiseHandshake {
  NoiseHandshake._(this.initiator, this._s, this._ephemeral);

  /// [ephemeral] is for test vectors only; normally a fresh key per handshake.
  static Future<NoiseHandshake> start({
    required bool initiator,
    required NoiseKeyPair staticKey,
    required List<int> prologue,
    NoiseKeyPair? ephemeral,
  }) async {
    final hs = NoiseHandshake._(initiator, staticKey, ephemeral);
    final name = ascii.encode(_protocolName);
    hs._h = Uint8List(_hashLen)..setAll(0, name);
    hs._ck = Uint8List.fromList(hs._h);
    await hs._mixHash(prologue);
    return hs;
  }

  final bool initiator;
  final NoiseKeyPair _s;
  NoiseKeyPair? _ephemeral;
  late Uint8List _h;
  late Uint8List _ck;
  Uint8List? _k;
  int _n = 0;
  NoiseKeyPair? _e;
  Uint8List? _re;
  Uint8List? _rs;
  int _step = 0;
  NoiseChannel? _channel;

  bool get complete => _channel != null;

  NoiseChannel get channel => _channel ?? (throw const NoiseException('handshake not complete'));

  Future<void> _mixHash(List<int> data) async => _h = await _hash([..._h, ...data]);

  Future<void> _mixKey(List<int> ikm) async {
    final out = await _hkdf(_ck, ikm, 2);
    _ck = out[0];
    _k = out[1].sublist(0, _keyLen);
    _n = 0;
  }

  Future<Uint8List> _encryptAndHash(List<int> plaintext) async {
    final Uint8List out;
    if (_k == null) {
      out = Uint8List.fromList(plaintext);
    } else {
      final box = await _aead.encrypt(plaintext, secretKey: SecretKeyData(_k!), nonce: _nonce(_n++), aad: _h);
      out = Uint8List.fromList([...box.cipherText, ...box.mac.bytes]);
    }
    await _mixHash(out);
    return out;
  }

  Future<Uint8List> _decryptAndHash(List<int> ciphertext) async {
    final Uint8List out;
    if (_k == null) {
      out = Uint8List.fromList(ciphertext);
    } else {
      if (ciphertext.length < 16) throw const NoiseException('handshake message too short', authentication: true);
      try {
        out = Uint8List.fromList(await _aead.decrypt(
          SecretBox(
            ciphertext.sublist(0, ciphertext.length - 16),
            nonce: _nonce(_n),
            mac: Mac(ciphertext.sublist(ciphertext.length - 16)),
          ),
          secretKey: SecretKeyData(_k!),
          aad: _h,
        ));
        _n++;
      } on SecretBoxAuthenticationError {
        throw const NoiseException('handshake authentication failed', authentication: true);
      }
    }
    await _mixHash(ciphertext);
    return out;
  }

  Future<NoiseKeyPair> _newEphemeral() async {
    final e = _ephemeral ?? await NoiseKeyPair.generate();
    _ephemeral = null;
    return e;
  }

  Future<void> _split() async {
    final out = await _hkdf(_ck, const [], 2);
    final c1 = NoiseCipher(out[0]);
    final c2 = NoiseCipher(out[1]);
    _channel = initiator
        ? NoiseChannel(c1, c2, Uint8List.fromList(_h), _rs!)
        : NoiseChannel(c2, c1, Uint8List.fromList(_h), _rs!);
  }

  /// Writes the next handshake message (empty payload).
  Future<Uint8List> writeMessage() async {
    final out = BytesBuilder();
    switch ((initiator, _step)) {
      case (true, 0): // → e
        _e = await _newEphemeral();
        out.add(_e!.publicKey);
        await _mixHash(_e!.publicKey);
        out.add(await _encryptAndHash(const []));
      case (false, 1): // ← e, ee, s, es
        _e = await _newEphemeral();
        out.add(_e!.publicKey);
        await _mixHash(_e!.publicKey);
        await _mixKey(await _e!.dh(_re!));
        out.add(await _encryptAndHash(_s.publicKey));
        await _mixKey(await _s.dh(_re!));
        out.add(await _encryptAndHash(const []));
      case (true, 2): // → s, se
        out.add(await _encryptAndHash(_s.publicKey));
        await _mixKey(await _s.dh(_re!));
        out.add(await _encryptAndHash(const []));
        await _split();
      default:
        throw const NoiseException('unexpected handshake write');
    }
    _step++;
    return out.toBytes();
  }

  /// Reads the next handshake message; returns its (empty) payload.
  Future<Uint8List> readMessage(List<int> message) async {
    Uint8List payload;
    switch ((initiator, _step)) {
      case (false, 0): // → e
        if (message.length < 32) throw const NoiseException('handshake message 1 too short');
        _re = Uint8List.fromList(message.sublist(0, 32));
        await _mixHash(_re!);
        payload = await _decryptAndHash(message.sublist(32));
      case (true, 1): // ← e, ee, s, es
        if (message.length < 32 + 48) throw const NoiseException('handshake message 2 too short');
        _re = Uint8List.fromList(message.sublist(0, 32));
        await _mixHash(_re!);
        await _mixKey(await _e!.dh(_re!));
        _rs = await _decryptAndHash(message.sublist(32, 80));
        await _mixKey(await _e!.dh(_rs!));
        payload = await _decryptAndHash(message.sublist(80));
      case (false, 2): // → s, se
        if (message.length < 48) throw const NoiseException('handshake message 3 too short');
        _rs = await _decryptAndHash(message.sublist(0, 48));
        await _mixKey(await _e!.dh(_rs!));
        payload = await _decryptAndHash(message.sublist(48));
        await _split();
      default:
        throw const NoiseException('unexpected handshake read');
    }
    _step++;
    return payload;
  }
}
