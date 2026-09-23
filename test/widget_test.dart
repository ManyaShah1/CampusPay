import 'package:flutter_test/flutter_test.dart';
import 'package:campuspay/core/crypto/ecdsa_service.dart';
import 'package:campuspay/main.dart';

void main() {
  group('CampusPay Cryptographic & Offline Engine Tests', () {
    test('ECDSA secp256k1 signs and verifies offline payment payload', () {
      final ecdsa = EcdsaService();
      final nonce = ecdsa.generateNonce();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiry48h = now + (48 * 60 * 60 * 1000);

      // 1. Sign transaction payload
      final signature = ecdsa.signPayload(
        tokenId: 'TK-DBIT-TEST-01',
        merchantId: 'MCH-CANTEEN-01',
        amount: 80.0,
        timestamp: now,
        nonce: nonce,
      );

      expect(signature, contains(':'));

      // 2. Verify signature using SoundBox verifier
      final result = ecdsa.verifyPayload(
        tokenId: 'TK-DBIT-TEST-01',
        merchantId: 'MCH-CANTEEN-01',
        amount: 80.0,
        timestamp: now,
        nonce: nonce,
        signature: signature,
        tokenExpiry: expiry48h,
      );

      expect(result.isValid, isTrue);
      expect(result.reason, contains('VERIFIED_OK'));
    });

    test('ECDSA verifier detects and blocks replay attacks on duplicate nonce', () {
      final ecdsa = EcdsaService();
      final nonce = ecdsa.generateNonce();
      final now = DateTime.now().millisecondsSinceEpoch;
      final expiry48h = now + 100000;

      final signature = ecdsa.signPayload(
        tokenId: 'TK-DBIT-TEST-02',
        merchantId: 'MCH-CANTEEN-01',
        amount: 50.0,
        timestamp: now,
        nonce: nonce,
      );

      // First verification passes
      final firstCheck = ecdsa.verifyPayload(
        tokenId: 'TK-DBIT-TEST-02',
        merchantId: 'MCH-CANTEEN-01',
        amount: 50.0,
        timestamp: now,
        nonce: nonce,
        signature: signature,
        tokenExpiry: expiry48h,
      );
      expect(firstCheck.isValid, isTrue);

      // Replay attack with same nonce MUST fail
      final secondCheck = ecdsa.verifyPayload(
        tokenId: 'TK-DBIT-TEST-02',
        merchantId: 'MCH-CANTEEN-01',
        amount: 50.0,
        timestamp: now,
        nonce: nonce,
        signature: signature,
        tokenExpiry: expiry48h,
      );
      expect(secondCheck.isValid, isFalse);
      expect(secondCheck.reason, contains('REPLAY_ATTACK_DETECTED'));
    });

    testWidgets('CampusPayApp launches and renders primary UI', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusPayApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CAMPUSPAY'), findsOneWidget);
      expect(find.text('CAMPUS WALLET (AES-256)'), findsOneWidget);
    });
  });
}
