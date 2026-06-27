import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

typedef PaymentSuccessCallback = void Function(PaymentSuccessResponse response);
typedef PaymentFailureCallback = void Function(PaymentFailureResponse response);
typedef ExternalWalletCallback = void Function(ExternalWalletResponse response);

class RazorpayService {
  late Razorpay _razorpay;
  PaymentSuccessCallback? onSuccessCallback;
  PaymentFailureCallback? onFailureCallback;
  ExternalWalletCallback? onWalletCallback;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Trigger payment using the checkout SDK
  void openCheckout({
    required String apiKey,
    required String orderId,
    required int amountCents,
    required String name,
    required String email,
    required String phone,
    required String description,
    required Map<String, dynamic> themeColors,
  }) {
    var options = {
      'key': apiKey,
      'amount': amountCents, // Amount in currency subunits (e.g., paise)
      'name': 'Lumina Platform',
      'order_id': orderId,
      'description': description,
      'timeout': 300, // Timeout in seconds
      'prefill': {
        'contact': phone,
        'email': email,
      },
      'theme': {
        'color': '#4F46E5', // Lumina Electric Indigo primary hex
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (kDebugMode) {
        print("Error launching Razorpay checkout: $e");
      }
    }
  }

  void dispose() {
    _razorpay.clear(); // Clear all listeners
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    onSuccessCallback?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    onFailureCallback?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onWalletCallback?.call(response);
  }
}
