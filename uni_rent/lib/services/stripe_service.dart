import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

/// Stripe Payment Integration — Sandbox/Test Mode
///
/// SETUP (5 minutes, instant access):
/// 1. Go to https://dashboard.stripe.com and create a free account
/// 2. Make sure you're in TEST MODE (toggle in top left of dashboard)
/// 3. Go to Developers → API Keys
/// 4. Copy your "Publishable key" (starts with pk_test_...)
/// 5. Copy your "Secret key" (starts with sk_test_...)
/// 6. Paste both below
///
/// TEST CARD: 4242 4242 4242 4242  |  Any future date  |  Any 3-digit CVC

class StripeService {
  // ─── PASTE YOUR STRIPE TEST KEYS HERE ────────────────────────
  static const String _publishableKey =
      'pk_test_51TYpRXQ9u9JgiQIUvZOrRfLqqrXMjQkKgWkmxBYfNsyhAHbLfeLGDruhgLNsouBRNxHLEo97qZmmTjbRt65f8ZTY0033mrmwNo';
  static const String _secretKey =
      'sk_test_51TYpRXQ9u9JgiQIULZc0E1EpqOXSeSMd1DViN9cWCDHooSgneU3ycsJkAmMlNbt9RyLPUkPl8TEJ0Kl3oPim4AIl00IIe3idyq';
  // ─────────────────────────────────────────────────────────────

  /// Call this once in main.dart before runApp()
  static void init() {
    Stripe.publishableKey = _publishableKey;
  }

  /// Creates a Stripe PaymentIntent on the server side (simulated here
  /// using the secret key directly — fine for sandbox/assignment use).
  ///
  /// In a real production app you would call your own backend server
  /// instead of calling Stripe directly with the secret key.
  static Future<StripeResult> createPaymentIntent({
    required double amount,
    String currency = 'myr',
  }) async {
    // Stripe expects amount in the smallest currency unit (sen for MYR)
    final amountInSen = (amount * 100).round().toString();

    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amountInSen,
          'currency': currency,
          'payment_method_types[]': 'card',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientSecret = data['client_secret'] as String?;
        final paymentIntentId = data['id'] as String?;

        if (clientSecret != null) {
          return StripeResult.success(
            clientSecret: clientSecret,
            paymentIntentId: paymentIntentId ?? '',
          );
        }
        return StripeResult.failure('No client secret returned');
      }

      final err = jsonDecode(response.body);
      return StripeResult.failure(
        err['error']?['message'] ?? 'Stripe error ${response.statusCode}',
      );
    } catch (e) {
      return StripeResult.failure('Network error: $e');
    }
  }

  /// Opens Stripe's built-in payment sheet inside the app.
  /// The user enters their card details and taps Pay.
  /// Returns true if payment was completed successfully.
  /// Returns true on success, null on user cancel, throws on error.
  static Future<bool?> presentPaymentSheet({
    required String clientSecret,
    required String merchantName,
  }) async {
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: merchantName,
        returnURL: 'stripeunirent://stripe-redirect',
        style: ThemeMode.light,
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF5C2E0E),
          ),
          shapes: PaymentSheetShape(borderRadius: 12),
        ),
      ),
    );

    await Stripe.instance.presentPaymentSheet();
    return true;
  }
}

class StripeResult {
  final bool success;
  final String? clientSecret;
  final String? paymentIntentId;
  final String? errorMessage;

  StripeResult._({
    required this.success,
    this.clientSecret,
    this.paymentIntentId,
    this.errorMessage,
  });

  factory StripeResult.success({
    required String clientSecret,
    required String paymentIntentId,
  }) => StripeResult._(
    success: true,
    clientSecret: clientSecret,
    paymentIntentId: paymentIntentId,
  );

  factory StripeResult.failure(String message) =>
      StripeResult._(success: false, errorMessage: message);
}
