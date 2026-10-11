import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/upi_qr_parser.dart';
import 'enter_amount_screen.dart';

class ScanAndPayScreen extends StatefulWidget {
  const ScanAndPayScreen({super.key});

  @override
  State<ScanAndPayScreen> createState() => _ScanAndPayScreenState();
}

class _ScanAndPayScreenState extends State<ScanAndPayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  late MobileScannerController _cameraController;
  bool _isTorchOn = false;
  bool _isProcessingScan = false;
  UpiQrData? _lastScannedPayee;
  int _selectedRouteIndex = 1; // 0: Online UPI, 1: Offline SoundBox, 2: USSD

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    try {
      await _cameraController.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraController.switchCamera();
    } catch (_) {}
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessingScan) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _processScannedCode(raw.trim());
        break;
      }
    }
  }

  void _processScannedCode(String rawCode) {
    if (_isProcessingScan) return;
    _isProcessingScan = true;
    HapticFeedback.heavyImpact();

    final upiData = UpiQrData.parse(rawCode);

    setState(() {
      _lastScannedPayee = upiData;
    });

    final displayName = upiData.payeeName ?? upiData.displayIdentifier;
    final displayId = upiData.upiId ?? upiData.upiNumber ?? 'UPI-PAY';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.electricYellow, width: 1.2),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.electricYellow,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanned: $displayName',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'UPI: $displayId',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.electricYellow,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    _navigateToEnterAmount(
      merchantName: displayName,
      counter: upiData.upiId != null ? 'UPI Terminal' : 'Counter 1',
      vendorId: displayId,
      defaultAmount: upiData.amount ?? 120.0,
      upiId: upiData.upiId,
      upiNumber: upiData.upiNumber,
      transactionNote: upiData.transactionNote,
    );
  }

  Future<void> _navigateToEnterAmount({
    String merchantName = 'Campus Café',
    String counter = 'Counter 3',
    String vendorId = 'CPV001',
    double defaultAmount = 120.0,
    String? upiId,
    String? upiNumber,
    String? transactionNote,
  }) async {
    _isProcessingScan = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnterAmountScreen(
          merchantName: merchantName,
          counter: counter,
          vendorId: vendorId,
          initialAmount: defaultAmount,
          upiId: upiId,
          upiNumber: upiNumber,
          transactionNote: transactionNote,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _isProcessingScan = false;
        _lastScannedPayee = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildHeader(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Title & Acoustic Sensors Pill ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan & Pay',
                          style: GoogleFonts.bodoniModa(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Scan any campus merchant QR or vendor SoundBox',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderStroke),
                    ),
                    child: const Icon(
                      Icons.sensors_rounded,
                      color: AppColors.electricYellow,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // ── Offline Ready Banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.successGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'OFFLINE READY • 10 TOKENS ACTIVE',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.electricYellow,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            'Mesh V2',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.onElectricYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'SoundBox audio frequency & BLE listening enabled. Zero internet required.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Camera Viewfinder Card with Laser Animation ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 340),
                  height: 340,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderStroke, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Live MobileScanner Camera Feed
                        Positioned.fill(
                          child: MobileScanner(
                            controller: _cameraController,
                            fit: BoxFit.cover,
                            onDetect: _onBarcodeDetected,
                            errorBuilder: (context, error) {
                              return _buildCameraFallback(error);
                            },
                          ),
                        ),

                        // Dimmed Vignette Overlay surrounding scanning square
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.25),
                            ),
                          ),
                        ),

                        // Viewfinder Reticle Frame
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Neon Corner Brackets
                              ..._buildCornerBrackets(),

                              // Animated Laser Scanning Line
                              AnimatedBuilder(
                                animation: _laserAnimation,
                                builder: (context, child) {
                                  return Positioned(
                                    top: 230 * _laserAnimation.value,
                                    left: 12,
                                    right: 12,
                                    child: Container(
                                      height: 2.5,
                                      decoration: BoxDecoration(
                                        color: AppColors.electricYellow,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.electricYellow
                                                .withValues(alpha: 0.8),
                                            blurRadius: 14,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Scanning / Detected status pill
                              Positioned(
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(9999),
                                    border: Border.all(
                                      color: _lastScannedPayee != null
                                          ? AppColors.successGreen
                                          : AppColors.borderStroke,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _lastScannedPayee != null
                                              ? AppColors.successGreen
                                              : AppColors.electricYellow,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _lastScannedPayee != null
                                            ? 'UPI DETECTED'
                                            : 'SCANNING UPI QR',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top Controls (Flashlight & Camera Flip)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleTorch,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _isTorchOn
                                        ? AppColors.electricYellow
                                        : Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.borderStroke,
                                    ),
                                  ),
                                  child: Icon(
                                    _isTorchOn
                                        ? Icons.flashlight_on_rounded
                                        : Icons.flashlight_off_rounded,
                                    size: 18,
                                    color: _isTorchOn
                                        ? AppColors.onElectricYellow
                                        : AppColors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _switchCamera,
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.borderStroke,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.flip_camera_android_rounded,
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom alignment instructions
                        Positioned(
                          bottom: 14,
                          left: 16,
                          right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ALIGN UPI QR CODE INSIDE FRAME',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.white,
                                  letterSpacing: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.graphic_eq_rounded,
                                    size: 13,
                                    color: AppColors.electricYellow,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Acoustic Ultrasound sync listening (18.4 kHz)...',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppColors.electricYellow,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Fallback Route Priority Chips ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FALLBACK ROUTE PRIORITY',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 13,
                            color: AppColors.lightPurple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Adaptive',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightPurple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRouteChip(0, 'Online UPI', AppColors.successGreen),
                        const SizedBox(width: 8),
                        _buildRouteChip(
                          1,
                          'Offline SoundBox (Auto Selected)',
                          AppColors.electricYellow,
                          isPulsing: true,
                        ),
                        const SizedBox(width: 8),
                        _buildRouteChip(2, 'USSD Fallback', AppColors.lightPurple),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Recent Campus Spots (Mesh Discovered) ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hub_rounded,
                              size: 18,
                              color: AppColors.electricYellow,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Recent Campus Spots',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          'Mesh Discovered',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMerchantSpotTile(
                    title: 'Canteen Counter 1',
                    subtitle: 'SoundBox Audio 18.4kHz • 0.8m away',
                    icon: Icons.restaurant_rounded,
                    iconBg: AppColors.electricYellow.withValues(alpha: 0.15),
                    iconColor: AppColors.electricYellow,
                    tagIcon: Icons.graphic_eq_rounded,
                    tagColor: AppColors.lightPurple,
                    onPay: () => _navigateToEnterAmount(
                      merchantName: 'Canteen Counter 1',
                      counter: 'Counter 1',
                      vendorId: 'CPV001',
                      defaultAmount: 120.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMerchantSpotTile(
                    title: 'Nescafe Kiosk',
                    subtitle: 'BLE Mesh Signal Strong • 3m away',
                    icon: Icons.coffee_rounded,
                    iconBg: AppColors.deepPurple.withValues(alpha: 0.3),
                    iconColor: AppColors.lightPurple,
                    tagIcon: Icons.bluetooth_searching_rounded,
                    tagColor: AppColors.successGreen,
                    onPay: () => _navigateToEnterAmount(
                      merchantName: 'Nescafe Kiosk',
                      counter: 'Main Quad',
                      vendorId: 'CPV002',
                      defaultAmount: 80.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMerchantSpotTile(
                    title: 'Gym Juice Bar',
                    subtitle: 'Offline Token Cached • Tap ready',
                    icon: Icons.fitness_center_rounded,
                    iconBg: AppColors.surfaceContainerHigh,
                    iconColor: AppColors.white,
                    tagIcon: Icons.offline_pin_rounded,
                    tagColor: AppColors.onSurfaceVariant,
                    onPay: () => _navigateToEnterAmount(
                      merchantName: 'Gym Juice Bar',
                      counter: 'Sports Complex',
                      vendorId: 'CPV003',
                      defaultAmount: 60.0,
                    ),
                  ),
                ],
              ),
            ),

            // ── Manual Input & Bottom Reassurance ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _showManualUpiEntryModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.borderStroke),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.keyboard_rounded,
                        color: AppColors.electricYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Enter Vendor ID or Student UPI ID',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.offline_bolt_rounded,
                        size: 14,
                        color: AppColors.electricYellow,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Signal? Optional. Transactions settle when back online.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.onSurface),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.electricYellow,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              'DBIT',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.onElectricYellow,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Scan And Pay',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppColors.borderStroke),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'UPI 128-bit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.deepPurple,
            border: Border.all(color: AppColors.electricYellow, width: 1.5),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/profile_avatar.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  'M',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteChip(
    int index,
    String label,
    Color dotColor, {
    bool isPulsing = false,
  }) {
    final isSelected = _selectedRouteIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedRouteIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.surfaceContainerHigh
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected ? AppColors.electricYellow : AppColors.borderStroke,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.electricYellow : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMerchantSpotTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required IconData tagIcon,
    required Color tagColor,
    required VoidCallback onPay,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderStroke),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(tagIcon, size: 14, color: tagColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onPay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricYellow,
              foregroundColor: AppColors.onElectricYellow,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              minimumSize: const Size(60, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
              elevation: 0,
            ),
            child: Text(
              'Pay',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const double size = 26;
    const double thickness = 4;
    const Color color = AppColors.electricYellow;

    return [
      // Top-Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
      // Top-Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(topRight: Radius.circular(12)),
          ),
        ),
      ),
      // Bottom-Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              left: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12)),
          ),
        ),
      ),
      // Bottom-Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: thickness),
              right: BorderSide(color: color, width: thickness),
            ),
            borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
          ),
        ),
      ),
    ];
  }

  Widget _buildCameraFallback(MobileScannerException error) {
    final isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermission
                  ? Icons.videocam_off_rounded
                  : Icons.camera_alt_outlined,
              size: 42,
              color: AppColors.electricYellow,
            ),
            const SizedBox(height: 12),
            Text(
              isPermission
                  ? 'Camera Permission Required'
                  : 'Camera Initializing or Unavailable',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPermission
                  ? 'Please grant camera access in settings to scan UPI QR codes.'
                  : 'Point camera at any UPI or campus QR code to pay.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (isPermission)
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings_rounded, size: 14),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricYellow,
                  foregroundColor: AppColors.onElectricYellow,
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _processScannedCode(
                  'upi://pay?pa=campuscafe@icici&pn=Campus%20Caf%C3%A9&am=120&cu=INR',
                ),
                icon: const Icon(
                  Icons.qr_code_rounded,
                  size: 14,
                  color: AppColors.electricYellow,
                ),
                label: Text(
                  'Test UPI QR Scan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.electricYellow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.electricYellow),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showManualUpiEntryModal() {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
                MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.alternate_email_rounded,
                      color: AppColors.electricYellow,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter UPI ID or Number',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        'Supports VPA (e.g. alex@upi) or 10-digit mobile',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.jetBrainsMono(
                  color: AppColors.onSurface,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 9876543210 or student@okaxis',
                  hintStyle: GoogleFonts.jetBrainsMono(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  prefixIcon: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.lightPurple,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.borderStroke),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.borderStroke),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.electricYellow,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickPill('canteen@dbit', textController),
                  _buildQuickPill('9876543210', textController),
                  _buildQuickPill('nescafe@upi', textController),
                  _buildQuickPill('xerox@campus', textController),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final text = textController.text.trim();
                    if (text.isEmpty) return;
                    Navigator.pop(bottomSheetContext);
                    _processScannedCode(text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricYellow,
                    foregroundColor: AppColors.onElectricYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Proceed to Pay',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickPill(
    String value,
    TextEditingController controller,
  ) {
    return GestureDetector(
      onTap: () {
        controller.text = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderStroke),
        ),
        child: Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: AppColors.lightPurple,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
