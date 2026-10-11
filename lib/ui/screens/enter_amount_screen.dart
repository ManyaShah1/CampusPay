import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/wallet_viewmodel.dart';
import 'offline_payment_screen.dart';

class EnterAmountScreen extends StatefulWidget {
  final String merchantName;
  final String counter;
  final String vendorId;
  final double initialAmount;
  final String? upiId;
  final String? upiNumber;
  final String? transactionNote;

  const EnterAmountScreen({
    super.key,
    this.merchantName = 'Campus Café',
    this.counter = 'Counter 3',
    this.vendorId = 'CPV001',
    this.initialAmount = 120.0,
    this.upiId,
    this.upiNumber,
    this.transactionNote,
  });

  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen>
    with SingleTickerProviderStateMixin {
  late String _amountStr;
  int _selectedMethod = 1; // 0: Campus Wallet, 1: Offline Wallet (Ultrasonic)
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _amountStr = widget.initialAmount > 0
        ? widget.initialAmount.toInt().toString()
        : '120';
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'backspace') {
        if (_amountStr.isNotEmpty) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) {
          _amountStr += _amountStr.isEmpty ? '0.' : '.';
        }
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else if (_amountStr.length < 7) {
          _amountStr += key;
        }
      }
    });
  }

  void _addQuickPreset(int addValue) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = double.tryParse(_amountStr) ?? 0.0;
      final newAmt = current + addValue;
      _amountStr = newAmt == newAmt.roundToDouble()
          ? newAmt.toInt().toString()
          : newAmt.toStringAsFixed(2);
    });
  }

  void _proceedToOfflinePayment() {
    HapticFeedback.mediumImpact();
    final amount = double.tryParse(_amountStr) ?? 120.0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfflinePaymentScreen(
          merchantName: widget.merchantName,
          counter: widget.counter,
          vendorId: widget.vendorId,
          amount: amount > 0 ? amount : 120.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletVM = context.watch<WalletViewModel>();
    final displayAmount = _amountStr.isEmpty ? '0' : _amountStr;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      appBar: _buildHeader(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // ── Merchant Identification Card ─────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderStroke),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_cafe_rounded,
                            color: AppColors.lightPurple,
                            size: 24,
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: AppColors.electricYellow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: AppColors.onElectricYellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.merchantName,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.lightPurple,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              Text(
                                (widget.upiId != null || widget.upiNumber != null)
                                    ? 'NPCI Verified UPI Payee'
                                    : 'Verified Campus Merchant',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.lightPurple,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.upiId ??
                                      (widget.upiNumber != null
                                          ? 'UPI: ${widget.upiNumber}'
                                          : widget.vendorId),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.transactionNote != null &&
                              widget.transactionNote!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Note: ${widget.transactionNote}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: AppColors.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderStroke),
                      ),
                      child: const Icon(
                        Icons.sensors_rounded,
                        color: AppColors.electricYellow,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Massive Amount Entry Zone with Blinking Cursor ────────────
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹',
                        style: GoogleFonts.bodoniModa(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        displayAmount,
                        style: GoogleFonts.bodoniModa(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _cursorController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _cursorController.value > 0.5 ? 1.0 : 0.0,
                            child: Container(
                              margin: const EdgeInsets.only(left: 4),
                              width: 3.5,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.electricYellow,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.electricYellow
                                        .withValues(alpha: 0.9),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Instant merchant settlement',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.electricYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        'Zero Surcharge',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.electricYellow,
                        ),
                      ),
                    ],
                  ),

                  // Quick preset chips
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildPresetChip('+₹50', 50),
                      const SizedBox(width: 8),
                      _buildPresetChip('+₹100', 100),
                      const SizedBox(width: 8),
                      _buildPresetChip('+₹200', 200),
                      const SizedBox(width: 8),
                      _buildPresetChip('+₹500', 500),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Payment Source Architecture Cards ─────────────────────────
              _buildPaymentMethodCard(
                index: 0,
                icon: Icons.account_balance_wallet_rounded,
                iconBg: AppColors.deepPurple.withValues(alpha: 0.4),
                iconColor: AppColors.lightPurple,
                title: 'Campus Wallet',
                subtitle: 'Available: ₹${walletVM.balance.toStringAsFixed(2)}',
                badgeText: 'Default',
              ),
              const SizedBox(height: 10),
              _buildPaymentMethodCard(
                index: 1,
                icon: Icons.bolt_rounded,
                iconBg: AppColors.electricYellow,
                iconColor: AppColors.onElectricYellow,
                title: 'Offline Wallet',
                subtitle: 'Acoustic Ultrasonic chirp armed',
                badgeText: '10 Tokens',
                trailingText: 'Ready',
              ),

              const SizedBox(height: 18),

              // ── Tactical Interactive Numeric Pinpad ───────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildKeypadBtn('1'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn('2'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn('3'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKeypadBtn('4'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn('5'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn('6'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKeypadBtn('7'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn('8'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn('9'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildKeypadBtn('.'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn('0'),
                        const SizedBox(width: 8),
                        _buildKeypadBtn(
                          'backspace',
                          icon: Icons.backspace_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Conversion Action Button & Security Guarantee ─────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToOfflinePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricYellow,
                    foregroundColor: AppColors.onElectricYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                    shadowColor: AppColors.electricYellow.withValues(alpha: 0.6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.onElectricYellow,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pay ₹$displayAmount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change Payment Method',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightPurple,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.lightPurple,
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 15,
                    color: AppColors.lightPurple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Offline Zero-PIN • ECDSA signed',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
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
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildPresetChip(String label, int value) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _addQuickPreset(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(color: AppColors.borderStroke),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required int index,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    String? trailingText,
  }) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.electricYellow : AppColors.borderStroke,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.lightPurple
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.electricYellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trailingText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightPurple,
                      ),
                    ),
                  ],
                ),
              )
            else if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.lightPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadBtn(String value, {IconData? icon}) {
    return Expanded(
      child: InkWell(
        onTap: () => _onKeyPress(value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderStroke),
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: AppColors.onSurface, size: 20)
              : Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
