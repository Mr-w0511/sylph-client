import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

import '../../data/models/models.dart';
import '../../data/repositories/misc_repositories.dart';
import '../storage/secure_store.dart';

/// 缺少可解密的私钥（对端换了设备 / 本机未生成对应一次性私钥）。
class E2eeKeyMissing implements Exception {
  const E2eeKeyMissing();
}

class E2eeCryptoResult {
  /// base64(nonce(12) || gcmTag(16) || ciphertext) —— 作为消息 content。
  final String content;

  /// 随消息携带的解密辅助信息（放入 mediaMeta JSON）：
  /// ik=发送方身份公钥, otk=使用的对端一次性公钥(空=回退 signedPreKey),
  /// dev=对端设备 id。
  final String metaJson;

  const E2eeCryptoResult(this.content, this.metaJson);
}

/// 端到端加密（演示级 Signal 风格），v2 协议（2026-06 起）：
/// - 密钥交换 X25519（32 字节 raw 公钥 base64），签名 Ed25519（独立长期签名密钥）；
///   两者均使用 cryptography 包内置的纯 Dart 实现（DartX25519/DartEd25519），
///   全平台（含 Android/Windows/Linux）可用——旧版 P-256 的 DartEcdsa/DartEcdh
///   在非 Apple/Android 平台是抛 UnimplementedError 的存根，故整体迁移。
/// - 共享密钥经 HKDF-SHA256（salt='SYLPH-E2EE-v1'，info=x25519-otk/x25519-spk）
///   派生 256bit AES-GCM 密钥（纯 Dart DartAesGcm）；
/// - 发送前 claim 对端公钥束：优先一次性公钥，耗尽回退 signedPreKey；
/// - 私钥材料仅保存在本设备（web 为 localStorage，见 SecureStore）。
/// 局限：同账号多设备时仅加密给 claim 返回的第一台设备。
class E2eeService {
  // v2 存储键：与旧 P-256 材料物理隔离（旧协议从未成功上线，无需迁移）。
  static const _kIdentity = 'e2ee.identity.v2'; // X25519 长期身份
  static const _kSigning = 'e2ee.signing.v2'; // Ed25519 长期签名
  static const _kSpk = 'e2ee.spk.v2'; // X25519 签名预签公钥
  static const _kOtkMap = 'e2ee.otks.v2'; // 全部一次性私钥（含已消耗，供解密）
  static const _kOtkPending = 'e2ee.otks.pending.v2'; // 估计仍在服务端的公钥序列
  static const _kRegId = 'e2ee.regid';
  static const int otkPoolSize = 20;
  static const int otkReplenishThreshold = 5;

  final SecureStore _store;
  final E2eeRepository _repo;
  final _rng = Random.secure();

  // 全部使用纯 Dart 实现，杜绝平台通道存根抛 UnimplementedError。
  final _x25519 = const DartX25519();
  final _ed25519 = DartEd25519();
  final _hkdf = const DartHkdf(
      hmac: DartHmac(DartSha256()), outputLength: 32);
  final _aes = DartAesGcm.with256bits();

  E2eeService(this._store, this._repo);

  // ---------- 本端密钥束 ----------

  /// 确保本设备已上传与本地一致的公钥束，并保证服务端一次性公钥充足。
  /// 幂等且自愈：404/身份不匹配/池将耗尽都会触发（增量）重传。
  Future<void> ensureBundleUploaded() async {
    final identity = await _loadOrCreateIdentity();
    await _loadOrCreateSigning();
    final spk = await _loadOrCreateSignedPreKey();
    var pending = await _readPending();

    try {
      final mine = await _repo.myBundle();
      if (mine['identityKey'] != identity.pubB64) {
        // 服务端束缺失或身份不一致（重装/换密钥）→ 整束重传。
      } else {
        final remaining =
            (mine['remainingOneTimeKeys'] as num?)?.toInt() ?? 0;
        // claim 为 FIFO 弹出，服务端剩余的即本地 pending 尾部 N 个。
        if (remaining < pending.length) {
          pending = pending.sublist(pending.length - remaining);
          await _writePending(pending);
        }
        if (remaining >= otkReplenishThreshold) {
          return; // 束一致且一次性公钥充足，无需任何上传。
        }
      }
    } catch (_) {
      // 404（从未上传）或网络异常：尝试整束上传；上传失败则把异常抛给调用方。
    }

    // 补足到池子大小（仅在增量补充时生成新密钥；整束重传复用 pending）。
    if (pending.length < otkPoolSize) {
      final fresh = await _generateOneTimeKeys(otkPoolSize - pending.length);
      pending = [...pending, ...fresh];
      await _writePending(pending);
    }

    await _repo.uploadBundle(
      registrationId: await _registrationId(),
      identityKey: identity.pubB64,
      signedPreKey: spk.pubB64,
      signature: spk.sigB64,
      oneTimeKeys: pending,
    );
  }

  /// 一次性公钥池将耗尽时补充（PUT 为整束覆盖）。失败静默，不阻塞消息发送。
  Future<void> replenishIfLow() async {
    try {
      await ensureBundleUploaded();
    } catch (_) {
      // 查看/上传失败不阻塞发送；下次发送或登录预热时自愈。
    }
  }

  Future<_RawKey> _loadOrCreateIdentity() async {
    final key = await _loadOrCreateX25519(_kIdentity);
    return key;
  }

  Future<_RawKey> _loadOrCreateSigning() =>
      _loadOrCreateEd25519(_kSigning);

  Future<_RawKey> _loadOrCreateX25519(String storeKey) async {
    final raw = await _store.read(storeKey);
    if (raw != null) {
      return _RawKey.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    final kp = await _x25519.newKeyPair();
    final data = await kp.extract();
    final pub = await kp.extractPublicKey();
    final key = _RawKey(Uint8List.fromList(data.bytes),
        Uint8List.fromList(pub.bytes));
    await _store.write(storeKey, jsonEncode(key.toJson()));
    return key;
  }

  Future<_RawKey> _loadOrCreateEd25519(String storeKey) async {
    final raw = await _store.read(storeKey);
    if (raw != null) {
      return _RawKey.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    final kp = await _ed25519.newKeyPair();
    final data = await kp.extract();
    final pub = await kp.extractPublicKey();
    final key = _RawKey(Uint8List.fromList(data.bytes),
        Uint8List.fromList(pub.bytes));
    await _store.write(storeKey, jsonEncode(key.toJson()));
    return key;
  }

  Future<_SignedKey> _loadOrCreateSignedPreKey() async {
    final raw = await _store.read(_kSpk);
    if (raw != null) {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return _SignedKey(
          _RawKey.fromJson(m['key'] as Map<String, dynamic>),
          m['sig'] as String);
    }
    final kp = await _x25519.newKeyPair();
    final data = await kp.extract();
    final pub = await kp.extractPublicKey();
    final key = _RawKey(Uint8List.fromList(data.bytes),
        Uint8List.fromList(pub.bytes));
    final signing = await _loadOrCreateSigning();
    final sig = await _ed25519.sign(key.pub,
        keyPair: signing.asEd25519KeyPair());
    final signed = _SignedKey(key, base64Encode(sig.bytes));
    await _store.write(_kSpk, jsonEncode({
      'key': key.toJson(),
      'sig': signed.sigB64,
    }));
    return signed;
  }

  /// 生成 [count] 个新一次性 X25519 密钥：私钥（种子）入全量映射表，
  /// 返回公钥列表（调用方负责并入 pending 并上传）。
  Future<List<String>> _generateOneTimeKeys(int count) async {
    if (count <= 0) return const [];
    final mapJson = await _store.read(_kOtkMap);
    final map = mapJson == null
        ? <String, String>{}
        : Map<String, dynamic>.from(jsonDecode(mapJson) as Map)
            .map((k, v) => MapEntry(k, v as String));
    final pubs = <String>[];
    for (var i = 0; i < count; i++) {
      final kp = await _x25519.newKeyPair();
      final data = await kp.extract();
      final pub = await kp.extractPublicKey();
      final key = _RawKey(Uint8List.fromList(data.bytes),
          Uint8List.fromList(pub.bytes));
      map[key.pubB64] = base64Encode(key.seed);
      pubs.add(key.pubB64);
    }
    await _store.write(_kOtkMap, jsonEncode(map));
    return pubs;
  }

  Future<List<String>> _readPending() async {
    final raw = await _store.read(_kOtkPending);
    if (raw == null) return const [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => e as String).toList();
  }

  Future<void> _writePending(List<String> pending) =>
      _store.write(_kOtkPending, jsonEncode(pending));

  Future<int> _registrationId() async {
    final raw = await _store.read(_kRegId);
    if (raw != null) return int.parse(raw);
    final id = 1 + _rng.nextInt(0x3fffff);
    await _store.write(_kRegId, '$id');
    return id;
  }

  // ---------- 发送 / 接收 ----------

  /// 向对端加密一条明文。调用前应已 claim 到 [bundle]。
  Future<E2eeCryptoResult> encrypt(
      String plaintext, E2eeBundle bundle) async {
    final identity = await _loadOrCreateIdentity();
    final useOtk = bundle.oneTimeKey != null && bundle.oneTimeKey!.isNotEmpty;
    final remotePub = base64Decode(useOtk ? bundle.oneTimeKey! : bundle.signedPreKey);
    if (remotePub.length != 32) {
      throw StateError('e2ee-invalid-remote-key: len=${remotePub.length}');
    }

    final raw = await _x25519.sharedSecretKey(
      keyPair: identity.asX25519KeyPair(),
      remotePublicKey:
          SimplePublicKey(remotePub, type: KeyPairType.x25519),
    );
    final key = await _hkdf.deriveKey(
      secretKey: raw,
      nonce: utf8.encode('SYLPH-E2EE-v1'),
      info: utf8.encode(useOtk ? 'x25519-otk' : 'x25519-spk'),
    );

    final nonce = _randomNonce();
    final box = await _aes.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    final combined = Uint8List(12 + box.mac.bytes.length + box.cipherText.length);
    combined.setRange(0, 12, nonce);
    combined.setRange(12, 12 + box.mac.bytes.length, box.mac.bytes);
    combined.setRange(
        12 + box.mac.bytes.length, combined.length, box.cipherText);

    final meta = jsonEncode({
      'nonce': base64Encode(nonce),
      'ik': identity.pubB64,
      'otk': useOtk ? bundle.oneTimeKey : '',
      'dev': bundle.deviceId,
    });
    return E2eeCryptoResult(base64Encode(combined), meta);
  }

  /// 解密一条密文；mediaMeta 由 [metaJson] 给出。
  Future<String> decrypt(String contentB64, String? metaJson) async {
    if (metaJson == null || metaJson.isEmpty) throw const E2eeKeyMissing();
    final meta = jsonDecode(metaJson) as Map<String, dynamic>;
    final ik = meta['ik'] as String?;
    if (ik == null) throw const E2eeKeyMissing();
    final senderPub = base64Decode(ik);
    if (senderPub.length != 32) throw const E2eeKeyMissing();

    // 找到对应私钥：一次性优先，否则 signedPreKey 回退。
    final otkPub = (meta['otk'] as String?) ?? '';
    _RawKey? myKey;
    var useOtk = false;
    if (otkPub.isNotEmpty) {
      final mapRaw = await _store.read(_kOtkMap);
      if (mapRaw != null) {
        final map = Map<String, dynamic>.from(jsonDecode(mapRaw) as Map);
        final seedB64 = map[otkPub] as String?;
        if (seedB64 != null) {
          myKey = _RawKey(base64Decode(seedB64), base64Decode(otkPub));
          useOtk = true;
        }
      }
    }
    if (myKey == null) {
      final spkRaw = await _store.read(_kSpk);
      if (spkRaw == null) throw const E2eeKeyMissing();
      myKey = _RawKey.fromJson(
          (jsonDecode(spkRaw) as Map<String, dynamic>)['key']
              as Map<String, dynamic>);
    }

    final raw = await _x25519.sharedSecretKey(
      keyPair: myKey.asX25519KeyPair(),
      remotePublicKey:
          SimplePublicKey(senderPub, type: KeyPairType.x25519),
    );
    final key = await _hkdf.deriveKey(
      secretKey: raw,
      nonce: utf8.encode('SYLPH-E2EE-v1'),
      info: utf8.encode(useOtk ? 'x25519-otk' : 'x25519-spk'),
    );

    final combined = base64Decode(contentB64);
    if (combined.length < 28) throw const E2eeKeyMissing();
    final nonce = combined.sublist(0, 12);
    final mac = combined.sublist(12, 28);
    final cipherText = combined.sublist(28);
    final box = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final clear = await _aes.decrypt(box, secretKey: key);
    return utf8.decode(clear);
  }

  // ---------- 编解码工具 ----------

  Uint8List _randomNonce() {
    final n = Uint8List(12);
    for (var i = 0; i < 12; i++) {
      n[i] = _rng.nextInt(256);
    }
    return n;
  }
}

/// 25519 系列原始密钥对：seed=32 字节私钥种子，pub=32 字节公钥。
class _RawKey {
  final Uint8List seed;
  final Uint8List pub;

  _RawKey(this.seed, this.pub);

  factory _RawKey.fromJson(Map<String, dynamic> j) => _RawKey(
        base64Decode(j['d'] as String),
        base64Decode(j['x'] as String),
      );

  Map<String, dynamic> toJson() => {
        'd': base64Encode(seed),
        'x': base64Encode(pub),
      };

  String get pubB64 => base64Encode(pub);

  SimpleKeyPairData asX25519KeyPair() => SimpleKeyPairData(
        seed,
        publicKey: SimplePublicKey(pub, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );

  SimpleKeyPairData asEd25519KeyPair() => SimpleKeyPairData(
        seed,
        publicKey: SimplePublicKey(pub, type: KeyPairType.ed25519),
        type: KeyPairType.ed25519,
      );
}

class _SignedKey {
  final _RawKey key;
  final String sigB64;
  _SignedKey(this.key, this.sigB64);

  String get pubB64 => key.pubB64;
}
