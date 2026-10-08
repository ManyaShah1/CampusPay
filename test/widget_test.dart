import 'package:flutter_test/flutter_test.dart';
import 'package:campuspay/core/crypto/ecdsa_service.dart';
import 'package:campuspay/core/utils/upi_qr_parser.dart';
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

    test('UPI QR Parser correctly parses UPI URIs, VPAs, and UPI numbers', () {
      // 1. Standard NPCI UPI URI
      final standardUpi = UpiQrData.parse(
        'upi://pay?pa=canteen@icici&pn=DBIT%20Canteen&am=150.00&cu=INR&tn=Lunch',
      );
      expect(standardUpi.isValid, isTrue);
      expect(standardUpi.upiId, 'canteen@icici');
      expect(standardUpi.payeeName, 'DBIT Canteen');
      expect(standardUpi.amount, 150.0);
      expect(standardUpi.transactionNote, 'Lunch');

      // 2. Direct VPA format
      final directVpa = UpiQrData.parse('student@okaxis');
      expect(directVpa.isValid, isTrue);
      expect(directVpa.upiId, 'student@okaxis');
      expect(directVpa.payeeName, 'student');

      // 3. 10-digit Indian UPI / Mobile number
      final upiNumber = UpiQrData.parse('9876543210');
      expect(upiNumber.isValid, isTrue);
      expect(upiNumber.upiNumber, '9876543210');
      expect(upiNumber.upiId, '9876543210@upi');

      // 4. Mobile number with +91 country code
      final countryCodeNum = UpiQrData.parse('+919876543210');
      expect(countryCodeNum.isValid, isTrue);
      expect(countryCodeNum.upiNumber, '9876543210');

      // 5. CampusPay vendor code
      final vendorQr = UpiQrData.parse('CPV001:Campus Café:120');
      expect(vendorQr.isValid, isTrue);
      expect(vendorQr.upiId, 'CPV001@campuspay');
      expect(vendorQr.payeeName, 'Campus Café');
      expect(vendorQr.amount, 120.0);
    });

    testWidgets('CampusPayApp launches and renders primary UI', (WidgetTester tester) async {
      await tester.pumpWidget(const CampusPayApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CampusPay'), findsWidgets);
      expect(find.text('Campus Wallet'), findsWidgets);
    });
  });
}
