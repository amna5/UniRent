import 'dart:convert';
import 'package:http/http.dart' as http;

/// ToyyibPay API integration
/// Sandbox docs: https://toyyibpay.com/apireference/
///
/// HOW TO SETUP:
/// 1. Register at https://dev.toyyibpay.com (sandbox) or https://toyyibpay.com (production)
/// 2. Create a category (product/service) and get the category code
/// 3. Get your user secret key from dashboard
/// 4. Replace the values below with your actual credentials
/// 5. For production, change BASE_URL to 'https://toyyibpay.com'

class ToyyibPayService {
  // ─── REPLACE THESE WITH YOUR TOYYIBPAY CREDENTIALS ───────────
  static const String _userSecretKey = 'YOUR_USER_SECRET_KEY';
  static const String _categoryCode = 'YOUR_CATEGORY_CODE';

  // Sandbox URL for testing — change to 'https://toyyibpay.com' for production
  static const String _baseUrl = 'https://dev.toyyibpay.com';

  // Your app's return URL after payment (use a deep link or webpage)
  static const String _returnUrl = 'https://unirent.my/payment/return';
  static const String _callbackUrl = 'https://unirent.my/payment/callback';
  // ─────────────────────────────────────────────────────────────

  /// Creates a ToyyibPay bill and returns the bill code.
  /// The bill code is used to redirect the user to the payment page.
  ///
  /// [bookingId]   - your internal booking ID (used as bill external reference)
  /// [amount]      - total amount in RM (e.g. 12.36)
  /// [description] - shown on the payment page
  /// [payerName]   - renter's full name
  /// [payerEmail]  - renter's email
  /// [payerPhone]  - renter's phone (required by ToyyibPay, use '0123456789' for testing)
  static Future<ToyyibPayResult> createBill({
    required int bookingId,
    required double amount,
    required String description,
    required String payerName,
    required String payerEmail,
    String payerPhone = '0123456789',
  }) async {
    // ToyyibPay expects amount in cents (sen), as a whole number string
    final amountInSen = (amount * 100).round().toString();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/index.php/api/createBill'),
        body: {
          'userSecretKey': _userSecretKey,
          'categoryCode': _categoryCode,
          'billName': 'UniRent Booking #$bookingId',
          'billDescription': description,
          'billPriceSetting': '1',      // 1 = fixed price
          'billPayorInfo': '1',         // 1 = collect payer info
          'billAmount': amountInSen,
          'billReturnUrl': _returnUrl,
          'billCallbackUrl': _callbackUrl,
          'billExternalReferenceNo': 'UNIRENT-$bookingId',
          'billTo': payerName,
          'billEmail': payerEmail,
          'billPhone': payerPhone,
          'billSplitPayment': '0',
          'billSplitPaymentArgs': '',
          'billPaymentChannel': '0',    // 0 = all channels (FPX, TNG, DuitNow)
          'billContentEmail': 'Thank you for using UniRent! Your booking #$bookingId is confirmed.',
          'billChargeToCustomer': '1',  // 1 = charge service fee to customer
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['BillCode'] != null) {
          final billCode = data[0]['BillCode'] as String;
          final paymentUrl = '$_baseUrl/$billCode';
          return ToyyibPayResult.success(billCode: billCode, paymentUrl: paymentUrl);
        }
        return ToyyibPayResult.failure('Invalid response from ToyyibPay');
      }

      return ToyyibPayResult.failure('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      return ToyyibPayResult.failure('Network error: $e');
    }
  }

  /// Checks payment status of a bill.
  /// Returns 'paid', 'pending', or 'failed'.
  static Future<String> checkBillStatus(String billCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/index.php/api/getBillTransactions'),
        body: {
          'userSecretKey': _userSecretKey,
          'billCode': billCode,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // billpaymentstatus: 1 = paid, 2 = pending, 3 = failed
          final status = data[0]['billpaymentstatus'];
          if (status == '1') return 'paid';
          if (status == '3') return 'failed';
        }
      }
    } catch (_) {}
    return 'pending';
  }

  /// Builds the full payment URL from a bill code.
  static String getPaymentUrl(String billCode) => '$_baseUrl/$billCode';
}

class ToyyibPayResult {
  final bool success;
  final String? billCode;
  final String? paymentUrl;
  final String? errorMessage;

  ToyyibPayResult._({
    required this.success,
    this.billCode,
    this.paymentUrl,
    this.errorMessage,
  });

  factory ToyyibPayResult.success({
    required String billCode,
    required String paymentUrl,
  }) =>
      ToyyibPayResult._(
          success: true, billCode: billCode, paymentUrl: paymentUrl);

  factory ToyyibPayResult.failure(String message) =>
      ToyyibPayResult._(success: false, errorMessage: message);
}
