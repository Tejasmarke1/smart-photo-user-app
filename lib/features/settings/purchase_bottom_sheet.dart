import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/razorpay_service.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class PurchaseBottomSheet extends ConsumerStatefulWidget {
  final String planName;
  final String billingFrequency;
  final int validityDays;
  final int basePriceCents; // Price in paise (smallest unit)
  final String? planId;

  const PurchaseBottomSheet({
    super.key,
    required this.planName,
    required this.billingFrequency,
    required this.validityDays,
    required this.basePriceCents,
    this.planId,
  });

  @override
  ConsumerState<PurchaseBottomSheet> createState() => _PurchaseBottomSheetState();
}

class _PurchaseBottomSheetState extends ConsumerState<PurchaseBottomSheet> {
  bool _isLoading = false;
  late RazorpayService _razorpayService;
  late TextEditingController _couponController;
  bool _isCouponLoading = false;
  ApplyCouponResponse? _appliedCoupon;
  String? _couponError;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.onSuccessCallback = _handlePaymentSuccess;
    _razorpayService.onFailureCallback = _handlePaymentFailure;
    _couponController = TextEditingController();
    _couponController.addListener(() {
      setState(() {}); // Rebuild to update button states when typing
    });
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    _couponController.dispose();
    super.dispose();
  }

  int get _baseCents => widget.basePriceCents;
  int get _discountCents => _appliedCoupon?.discountCents ?? 0;
  int get _subtotalCents => _baseCents - _discountCents;
  int get _gstCents => (_subtotalCents * 0.18).round();
  int get _totalCents => _subtotalCents + _gstCents;

  double get _baseAmount => _baseCents / 100.0;
  double get _discountAmount => _discountCents / 100.0;

  double get _gstAmount => _gstCents / 100.0;
  double get _totalAmount => _totalCents / 100.0;

  String _formatCurrency(double amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return '₹${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Future<void> _handlePaymentSuccess(dynamic successResponse) async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.verifyPayment(
        VerifyPaymentRequest(
          razorpayOrderId: successResponse.orderId as String,
          razorpayPaymentId: successResponse.paymentId as String,
          razorpaySignature: successResponse.signature as String,
        ),
      );

      if (response.status == 'completed') {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscription activated! Enjoy ${widget.planName}.'),
              backgroundColor: LuminaTokens.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification failed. Contact support.'),
            backgroundColor: LuminaTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handlePaymentFailure(dynamic failureResponse) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${failureResponse.message}'),
          backgroundColor: LuminaTokens.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _initiatePayment() async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final client = ref.read(apiClientProvider);
      final response = await client.createOrder(
        CreateOrderRequest(
          amountCents: _totalCents,
          currency: 'INR',
          paymentType: 'subscription',
          referenceType: 'subscription',
          referenceId: widget.planId,
          couponCode: _appliedCoupon?.valid == true ? _couponController.text.trim() : null,
        ),
      );

      _razorpayService.openCheckout(
        apiKey: response.razorpayKeyId ?? 'rzp_test_1DP5mmOlF5G5ag',
        orderId: response.razorpayOrderId,
        amountCents: response.amountCents,
        name: authState.userName ?? 'Guest User',
        email: authState.userEmail ?? 'guest@lumina.com',
        phone: '+919999999999',
        description: '${widget.planName} ${widget.billingFrequency} Plan',
        themeColors: {'color': '#1E6091'},
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize transaction'),
            backgroundColor: LuminaTokens.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _validateCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isCouponLoading = true;
      _couponError = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.applyCoupon(
        ApplyCouponRequest(
          code: code,
          planId: widget.planId ?? '',
        ),
      );

      if (mounted) {
        setState(() {
          if (response.valid) {
            _appliedCoupon = response;
            _couponError = null;
          } else {
            _appliedCoupon = null;
            _couponError = response.message ?? 'Invalid coupon code';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appliedCoupon = null;
          _couponError = 'Failed to validate coupon';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCouponLoading = false;
        });
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponController.clear();
      _couponError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LuminaTokens.spacingLg,
            LuminaTokens.spacingMd,
            LuminaTokens.spacingLg,
            LuminaTokens.spacingLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: LuminaTokens.spacingMd),

              // Close button and title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 36),
                  Text(
                    'New Plan Purchase',
                    style: GoogleFonts.outfit(
                      fontSize: LuminaTokens.textXl,
                      fontWeight: LuminaTokens.fontWeightBold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuminaTokens.spacingLg),

              // Plan summary row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E6091).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF1E6091), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.planName,
                    style: GoogleFonts.outfit(
                      fontSize: LuminaTokens.textLg,
                      fontWeight: LuminaTokens.fontWeightSemibold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.billingFrequency,
                    style: GoogleFonts.inter(
                      fontSize: LuminaTokens.textSm,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuminaTokens.spacingLg),

              // Validity row
              _buildDetailRow('Validity', '${widget.validityDays} days'),
              const SizedBox(height: LuminaTokens.spacingSm),

              // Base Price row
              _buildDetailRow('Base Price', _formatCurrency(_baseAmount)),
              const SizedBox(height: LuminaTokens.spacingSm),

              if (_discountCents > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Coupon Discount',
                      style: GoogleFonts.inter(
                        fontSize: LuminaTokens.textSm,
                        color: LuminaTokens.success,
                      ),
                    ),
                    Text(
                      '- ${_formatCurrency(_discountAmount)}',
                      style: GoogleFonts.inter(
                        fontSize: LuminaTokens.textSm,
                        fontWeight: LuminaTokens.fontWeightMedium,
                        color: LuminaTokens.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LuminaTokens.spacingSm),
              ],

              // GST row
              _buildDetailRow('GST (18%)', _formatCurrency(_gstAmount)),
              const SizedBox(height: LuminaTokens.spacingLg),

              // Coupon section
              _buildCouponSection(),
              const SizedBox(height: LuminaTokens.spacingMd),

              const Divider(),
              const SizedBox(height: LuminaTokens.spacingSm),

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: GoogleFonts.outfit(
                      fontSize: LuminaTokens.textMd,
                      fontWeight: LuminaTokens.fontWeightBold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _formatCurrency(_totalAmount),
                    style: GoogleFonts.outfit(
                      fontSize: LuminaTokens.textLg,
                      fontWeight: LuminaTokens.fontWeightBold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: LuminaTokens.spacingLg),

              // Proceed to Pay button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _initiatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E6091),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Proceed to Pay',
                          style: GoogleFonts.outfit(
                            fontSize: LuminaTokens.textMd,
                            fontWeight: LuminaTokens.fontWeightSemibold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: LuminaTokens.spacingMd),

              // OR divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: LuminaTokens.spacingSm),

              // Share payment link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Get payment link via',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 12),
                  _buildShareChip(Icons.chat_rounded, const Color(0xFF25D366)),
                  const SizedBox(width: 10),
                  _buildShareChip(Icons.email_rounded, const Color(0xFFEA4335)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _couponError != null
                        ? LuminaTokens.error
                        : (_appliedCoupon != null ? LuminaTokens.success : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.local_offer_outlined, color: Colors.grey, size: 20),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        enabled: _appliedCoupon == null && !_isCouponLoading,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'PROMO CODE',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400, letterSpacing: 0.5),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (_appliedCoupon != null)
                      GestureDetector(
                        onTap: _removeCoupon,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.cancel_rounded, color: Colors.grey, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: (_isCouponLoading || _couponController.text.trim().isEmpty)
                    ? null
                    : (_appliedCoupon != null ? null : _validateCoupon),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _appliedCoupon != null ? Colors.grey : const Color(0xFF1E6091),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isCouponLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _appliedCoupon != null ? 'Applied' : 'Apply',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: LuminaTokens.fontWeightSemibold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        if (_couponError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _couponError!,
              style: GoogleFonts.inter(fontSize: 12, color: LuminaTokens.error),
            ),
          ),
        ],
        if (_appliedCoupon != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _appliedCoupon!.message ?? 'Coupon applied successfully!',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: LuminaTokens.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: LuminaTokens.textSm,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: LuminaTokens.textSm,
            fontWeight: LuminaTokens.fontWeightMedium,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildShareChip(IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement share link generation
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}
