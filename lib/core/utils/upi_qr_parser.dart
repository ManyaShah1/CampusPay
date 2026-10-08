class UpiQrData {
  final String? upiId; // pa: Payee Address / VPA (e.g., merchant@okhdfcbank)
  final String? payeeName; // pn: Payee Name (e.g., Campus Café)
  final String? upiNumber; // 10-digit mobile number or UPI number
  final double? amount; // am: Preset transaction amount if any
  final String? transactionNote; // tn: Transaction note
  final String? transactionRef; // tr: Transaction reference ID
  final String? merchantCode; // mc: Merchant category code
  final String raw;

  const UpiQrData({
    this.upiId,
    this.payeeName,
    this.upiNumber,
    this.amount,
    this.transactionNote,
    this.transactionRef,
    this.merchantCode,
    required this.raw,
  });

  bool get isValid =>
      (upiId != null && upiId!.isNotEmpty) ||
      (upiNumber != null && upiNumber!.isNotEmpty);

  /// Formatted display string for the target payee
  String get displayIdentifier {
    if (upiId != null && upiId!.isNotEmpty) return upiId!;
    if (upiNumber != null && upiNumber!.isNotEmpty) return upiNumber!;
    return 'Unknown UPI Payee';
  }

  /// Parses a raw scanned string (QR code or manual input) into UpiQrData
  static UpiQrData parse(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return UpiQrData(raw: rawInput);
    }

    // 1. Check for standard upi://pay? URI format
    if (trimmed.toLowerCase().startsWith('upi://') ||
        trimmed.toLowerCase().startsWith('upi:')) {
      try {
        final uri = Uri.parse(
          trimmed.startsWith('upi://')
              ? trimmed
              : trimmed.replaceFirst('upi:', 'upi://'),
        );
        final params = uri.queryParameters;

        final pa = params['pa']?.trim();
        final pn = params['pn']?.replaceAll('+', ' ').trim();
        final amStr = params['am'];
        final amount = amStr != null ? double.tryParse(amStr) : null;
        final tn = params['tn']?.replaceAll('+', ' ').trim();
        final tr = params['tr']?.trim();
        final mc = params['mc']?.trim();

        String? upiNum;
        if (pa != null) {
          // If the prefix of @ in VPA is a 10-digit number
          final parts = pa.split('@');
          if (parts.isNotEmpty && RegExp(r'^[6-9]\d{9}$').hasMatch(parts[0])) {
            upiNum = parts[0];
          }
        }

        return UpiQrData(
          upiId: pa,
          payeeName: pn?.isNotEmpty == true ? pn : null,
          upiNumber: upiNum,
          amount: amount,
          transactionNote: tn,
          transactionRef: tr,
          merchantCode: mc,
          raw: rawInput,
        );
      } catch (_) {
        // Fallback to manual parsing below
      }
    }

    // 2. Check for VPA format (e.g., student@okaxis, canteen@upi, 9876543210@paytm)
    final vpaRegex = RegExp(
      r'^[a-zA-Z0-9.\-_]{2,64}@[a-zA-Z0-9.\-_]{2,32}$',
    );
    if (vpaRegex.hasMatch(trimmed)) {
      final parts = trimmed.split('@');
      String? upiNum;
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(parts[0])) {
        upiNum = parts[0];
      }
      return UpiQrData(
        upiId: trimmed,
        payeeName: parts[0],
        upiNumber: upiNum,
        raw: rawInput,
      );
    }

    // 3. Check for 10-digit Indian Mobile / UPI Number
    final numericOnly = trimmed.replaceAll(RegExp(r'[\s\-\+]'), '');
    final tenDigitMatch = RegExp(r'(?:91)?([6-9]\d{9})$').firstMatch(numericOnly);
    if (tenDigitMatch != null) {
      final number = tenDigitMatch.group(1)!;
      return UpiQrData(
        upiId: '$number@upi',
        payeeName: 'UPI Contact',
        upiNumber: number,
        raw: rawInput,
      );
    }

    // 4. Check for CampusPay internal vendor format: "CPV001:Campus Café:120"
    if (trimmed.contains(':') && trimmed.startsWith('CPV')) {
      final parts = trimmed.split(':');
      final vendorId = parts[0];
      final name = parts.length > 1 ? parts[1] : vendorId;
      final amt = parts.length > 2 ? double.tryParse(parts[2]) : null;
      return UpiQrData(
        upiId: '$vendorId@campuspay',
        payeeName: name,
        amount: amt,
        raw: rawInput,
      );
    }

    // Default fallback
    return UpiQrData(
      upiId: trimmed,
      payeeName: trimmed,
      raw: rawInput,
    );
  }
}
