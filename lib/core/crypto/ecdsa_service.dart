import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:pointycastle/export.dart' as pc;
import 'package:uuid/uuid.dart';

/// Elliptic Curve Cryptography service using secp256k1 and SHA-256
class EcdsaService {
  static final EcdsaService _instance = EcdsaService._internal();
  factory EcdsaService() => _instance;

  final pc.ECDomainParameters _domainParams = pc.ECDomainParameters('secp256k1');
  late final pc.AsymmetricKeyPair<pc.ECPublicKey, pc.ECPrivateKey> _deviceKeyPair;
  late final pc.AsymmetricKeyPair<pc.ECPublicKey, pc.ECPrivateKey> _serverAuthorityKeyPair;

  final Set<String> _seenNonces = {};

  EcdsaService._internal() {
    _deviceKeyPair = _generateKeyPair();
    _serverAuthorityKeyPair = _generateKeyPair();
  }

  pc.ECPublicKey get devicePublicKey => _deviceKeyPair.publicKey;
  pc.ECPrivateKey get devicePrivateKey => _deviceKeyPair.privateKey;
  pc.ECPublicKey get serverPublicKey => _serverAuthorityKeyPair.publicKey;

  /// Deterministic key generation using Fortuna PRNG
  pc.AsymmetricKeyPair<pc.ECPublicKey, pc.ECPrivateKey> _generateKeyPair() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));

    final keyParams = pc.ECKeyGeneratorParameters(_domainParams);
    final generator = pc.ECKeyGenerator();
    generator.init(pc.ParametersWithRandom(keyParams, secureRandom));

    final pair = generator.generateKeyPair();
    return pc.AsymmetricKeyPair<pc.ECPublicKey, pc.ECPrivateKey>(
      pair.publicKey as pc.ECPublicKey,
      pair.privateKey as pc.ECPrivateKey,
    );
  }

  /// Generate a unique UUID v4 nonce
  String generateNonce() {
    return const Uuid().v4();
  }

  /// Sign payload data using SHA-256 + ECDSA (secp256k1)
  String signPayload({
    required String tokenId,
    required String merchantId,
    required double amount,
    required int timestamp,
    required String nonce,
    pc.ECPrivateKey? privateKey,
  }) {
    final dataToSign = '$tokenId|$merchantId|${amount.toStringAsFixed(2)}|$timestamp|$nonce';
    final hash = crypto.sha256.convert(utf8.encode(dataToSign)).bytes;

    final signer = pc.ECDSASigner(null, pc.HMac(pc.SHA256Digest(), 64));
    final key = privateKey ?? _deviceKeyPair.privateKey;
    signer.init(true, pc.PrivateKeyParameter(key));

    final sig = signer.generateSignature(Uint8List.fromList(hash)) as pc.ECSignature;
    return '${sig.r.toRadixString(16)}:${sig.s.toRadixString(16)}';
  }

  /// Sign a server token batch
  String signTokenByServer({
    required String tokenId,
    required String walletId,
    required double maxAmount,
    required int expiry,
  }) {
    final data = '$tokenId|$walletId|${maxAmount.toStringAsFixed(2)}|$expiry';
    final hash = crypto.sha256.convert(utf8.encode(data)).bytes;

    final signer = pc.ECDSASigner(null, pc.HMac(pc.SHA256Digest(), 64));
    signer.init(true, pc.PrivateKeyParameter(_serverAuthorityKeyPair.privateKey));

    final sig = signer.generateSignature(Uint8List.fromList(hash)) as pc.ECSignature;
    return '${sig.r.toRadixString(16)}:${sig.s.toRadixString(16)}';
  }

  /// Verification result with detailed audit reason
  VerificationResult verifyPayload({
    required String tokenId,
    required String merchantId,
    required double amount,
    required int timestamp,
    required String nonce,
    required String signature,
    required int tokenExpiry,
    pc.ECPublicKey? publicKey,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Check Nonce (Anti-replay)
    if (_seenNonces.contains(nonce)) {
      return VerificationResult(
        isValid: false,
        reason: 'REPLAY_ATTACK_DETECTED: Nonce $nonce already used',
      );
    }

    // 2. Check Token Expiry
    if (now > tokenExpiry) {
      return VerificationResult(
        isValid: false,
        reason: 'TOKEN_EXPIRED: 48hr window elapsed',
      );
    }

    // 3. Check Timestamp freshness (±5 minutes window)
    const allowedSkewMs = 5 * 60 * 1000;
    if ((now - timestamp).abs() > allowedSkewMs) {
      return VerificationResult(
        isValid: false,
        reason: 'CLOCK_SKEW_EXCEEDED: Timestamp exceeds ±5min threshold',
      );
    }

    // 4. Verify ECDSA signature
    try {
      final parts = signature.split(':');
      if (parts.length != 2) {
        return VerificationResult(isValid: false, reason: 'MALFORMED_SIGNATURE');
      }

      final r = BigInt.parse(parts[0], radix: 16);
      final s = BigInt.parse(parts[1], radix: 16);
      final ecSig = pc.ECSignature(r, s);

      final dataToVerify = '$tokenId|$merchantId|${amount.toStringAsFixed(2)}|$timestamp|$nonce';
      final hash = crypto.sha256.convert(utf8.encode(dataToVerify)).bytes;

      final verifier = pc.ECDSASigner(null, pc.HMac(pc.SHA256Digest(), 64));
      final key = publicKey ?? _deviceKeyPair.publicKey;
      verifier.init(false, pc.PublicKeyParameter(key));

      final isValid = verifier.verifySignature(Uint8List.fromList(hash), ecSig);
      if (!isValid) {
        return VerificationResult(
          isValid: false,
          reason: 'INVALID_SIGNATURE: Payer key mismatch',
        );
      }

      // Mark nonce as consumed
      _seenNonces.add(nonce);
      return VerificationResult(
        isValid: true,
        reason: 'VERIFIED_OK: Quad-check passed (sig, timestamp, nonce, expiry)',
      );
    } catch (e) {
      return VerificationResult(
        isValid: false,
        reason: 'VERIFICATION_EXCEPTION: ${e.toString()}',
      );
    }
  }

  /// Convert public key to concise hex representation
  String getDevicePublicKeyHex() {
    final q = _deviceKeyPair.publicKey.Q;
    if (q == null) return '00';
    return '${q.x?.toBigInteger()?.toRadixString(16).substring(0, 8)}...${q.y?.toBigInteger()?.toRadixString(16).substring(0, 8)}';
  }
}

class VerificationResult {
  final bool isValid;
  final String reason;

  VerificationResult({required this.isValid, required this.reason});
}
