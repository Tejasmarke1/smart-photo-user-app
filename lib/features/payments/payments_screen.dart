import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/services/razorpay_service.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  late RazorpayService _razorpayService;
  bool _isLoading = false;
  
  // Static pricing plan configuration
  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'plan_basic',
      'name': 'Event Guest Starter',
      'price_cents': 9900, // 99 INR in paise
      'price_label': '₹99',
      'description': 'Unlock all watermarked photos in high-resolution downloads for a single event.',
      'features': [
        'High-resolution downloads',
        'Remove watermarks',
        'Access to full selfie vector match',
      ],
    },
    {
      'id': 'plan_pro',
      'name': 'Premium All Access',
      'price_cents': 29900, // 299 INR in paise
      'price_label': '₹299',
      'description': 'Enjoy lifetime unlimited watermark-free downloads across all matching events.',
      'features': [
        'Lifetime unlimited downloads',
        'AI face recognition matching alerts',
        'Zero advertisements',
        'Priority downloads',
      ],
    }
  ];

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService();
    _razorpayService.onSuccessCallback = _handlePaymentSuccess;
    _razorpayService.onFailureCallback = _handlePaymentFailure;
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment(Map<String, dynamic> plan) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      
      // Step 1: Request order_id from our backend payment creation endpoint
      // POST /payments/orders/create
      final response = await dio.post(
        "http://10.0.2.2:8000/api/v1/payments/orders/create",
        data: {
          'plan_id': plan['id'],
          'amount_cents': plan['price_cents'],
          'currency': 'INR',
        },
      );

      final orderData = response.data;
      final orderId = orderData['order_id'];
      final keyId = orderData['key_id'];

      // Step 2: Launch Native Razorpay Checkout SDK
      _razorpayService.openCheckout(
        apiKey: keyId,
        orderId: orderId,
        amountCents: plan['price_cents'],
        name: authState.userName ?? "Guest User",
        email: authState.userEmail ?? "guest@lumina.com",
        phone: "+919999999999",
        description: plan['name'],
        themeColors: {'color': '#4F46E5'},
      );

    } catch (e) {
      _showSnackBar("Failed to initialize transaction", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePaymentSuccess(dynamic successResponse) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));

      // Step 3: Verify the transaction signature on our backend
      // POST /payments/verify
      final response = await dio.post(
        "http://10.0.2.2:8000/api/v1/payments/verify",
        data: {
          'razorpay_order_id': successResponse.orderId,
          'razorpay_payment_id': successResponse.paymentId,
          'razorpay_signature': successResponse.signature,
        },
      );

      if (response.data['status'] == 'completed') {
        _showSnackBar("Payment successful! Album access unlocked.", isError: false);
        if (mounted) context.pop(); // Go back to event album
      } else {
        _showSnackBar("Payment verification pending", isError: true);
      }
    } catch (_) {
      _showSnackBar("Verification failed. Please contact support.", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handlePaymentFailure(dynamic failureResponse) {
    _showSnackBar("Payment cancelled or failed. Reason: ${failureResponse.message}", isError: true);
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? LuminaTokens.error : LuminaTokens.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Choose an Access Plan", style: GoogleFonts.outfit(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LuminaTokens.primaryLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(LuminaTokens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Unlock Full Experience",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: LuminaTokens.spacingXs),
                  Text(
                    "High-resolution clean downloads are locked behind a photographer plan.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: LuminaTokens.spacingXl),

                  // Plans cards
                  ..._plans.map((plan) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: LuminaTokens.spacingLg),
                      child: Padding(
                        padding: const EdgeInsets.all(LuminaTokens.spacingLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan['name'],
                                  style: GoogleFonts.outfit(
                                    fontSize: LuminaTokens.textLg,
                                    fontWeight: LuminaTokens.fontWeightBold,
                                    color: LuminaTokens.darkText,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LuminaTokens.primaryGradient,
                                    borderRadius: LuminaTokens.borderRadiusSm,
                                  ),
                                  child: Text(
                                    plan['price_label'],
                                    style: GoogleFonts.outfit(
                                      fontWeight: LuminaTokens.fontWeightBold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: LuminaTokens.spacingSm),
                            Text(
                              plan['description'],
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: LuminaTokens.spacingLg),
                            
                            // Features
                            ...List.generate(plan['features'].length, (idx) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: LuminaTokens.successLight, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      plan['features'][idx],
                                      style: GoogleFonts.inter(fontSize: LuminaTokens.textSm, color: LuminaTokens.darkTextMuted),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            
                            const SizedBox(height: LuminaTokens.spacingLg),
                            
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () => _initiatePayment(plan),
                                child: const Text("Purchase Access"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
