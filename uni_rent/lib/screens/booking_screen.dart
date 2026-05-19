import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
import '../../../db/database_helper.dart';
import '../../../models/item_model.dart';
import '../../../models/booking_model.dart';
import '../../../services/stripe_service.dart';
import '../../../services/session_service.dart';
import '../../../theme.dart';

class BookingScreen extends StatefulWidget {
  final ItemModel item;

  const BookingScreen({super.key, required this.item});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPayment = 'Credit / Debit Card';
  bool _isProcessing = false;

  // ─── Calculation constants ────────────────────────────────────
  static const double _serviceFeeRate = 0.03; // 3%
  final _currencyFormat = NumberFormat.currency(symbol: 'RM', decimalDigits: 2);

  // ─── Derived calculations ─────────────────────────────────────
  int get _days {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  double get _rentalFee => _days * widget.item.pricePerDay;
  double get _serviceFee => _rentalFee * _serviceFeeRate;
  double get _total => _rentalFee + _serviceFee;

  final _payments = [
    {
      'name': 'Credit / Debit Card',
      'sub': 'Visa, Mastercard, Amex — powered by Stripe',
      'icon': Icons.credit_card,
    },
  ];

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (now)
          : (_startDate?.add(const Duration(days: 1)) ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        // Reset end date if it's before the new start
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
        }
      } else {
        if (_startDate != null && !picked.isAfter(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End date must be after start date'),
              backgroundColor: AppTheme.error,
            ),
          );
          return;
        }
        _endDate = picked;
      }
    });
  }

  Future<void> _confirmAndPay() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select rental period'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_days < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum rental period is 1 day'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final userId = await SessionService.getUserId();

    if (userId == null) {
      setState(() => _isProcessing = false);
      return;
    }

    // Save booking to SQLite first (status: pending)
    final booking = BookingModel(
      itemId: widget.item.id!,
      renterId: userId,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      days: _days,
      rentalFee: _rentalFee,
      serviceFee: _serviceFee,
      totalAmount: _total,
      paymentMethod: _selectedPayment,
      paymentStatus: 'pending',
      bookingStatus: 'active',
      createdAt: DateTime.now().toIso8601String(),
    );

    final bookingId = await DatabaseHelper.instance.insertBooking(booking);

    // Step 1 — Create PaymentIntent with Stripe
    final stripeResult = await StripeService.createPaymentIntent(
      amount: _total,
    );

    if (!stripeResult.success || stripeResult.clientSecret == null) {
      await DatabaseHelper.instance.updateBookingPaymentStatus(
        bookingId,
        'pending',
        null,
      );
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: ${stripeResult.errorMessage}'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Save PaymentIntent ID to booking
    await DatabaseHelper.instance.updateBookingPaymentStatus(
      bookingId,
      'pending',
      stripeResult.paymentIntentId,
    );

    setState(() => _isProcessing = false);

    // Step 2 — Show Stripe payment sheet
    try {
      final paid = await StripeService.presentPaymentSheet(
        clientSecret: stripeResult.clientSecret!,
        merchantName: 'UniRent',
      );

      if (paid == true) {
        // Step 3 — Mark booking as paid in SQLite
        await DatabaseHelper.instance.updateBookingPaymentStatus(
          bookingId,
          'paid',
          stripeResult.paymentIntentId,
        );
        if (!mounted) return;
        _showBookingConfirmed(bookingId);
      }
    } on StripeException catch (e) {
      if (!mounted) return;
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled. Booking saved as pending.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.error.localizedMessage}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showBookingConfirmed(int bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking #$bookingId has been created and payment confirmed.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // back to item detail
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Booking'),
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Item summary card ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currencyFormat.format(widget.item.pricePerDay)}/day',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Rental period ────────────────────────────────
            const Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Rental Period',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickDate(isStart: true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _startDate != null
                                      ? dateFormat.format(_startDate!)
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _startDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textHint,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Date',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _pickDate(isStart: false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppTheme.divider),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _endDate != null
                                      ? dateFormat.format(_endDate!)
                                      : 'dd/mm/yyyy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _endDate != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textHint,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Duration pill (shows after both dates selected) ───
            if (_days > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    '$_days ${_days == 1 ? "day" : "days"} selected',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Payment method ───────────────────────────────
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ..._payments.map((p) {
              final name = p['name'] as String;
              final isSelected = _selectedPayment == name;
              return GestureDetector(
                onTap: () => setState(() => _selectedPayment = name),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        p['icon'] as IconData,
                        size: 22,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              p['sub'] as String,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: name,
                        groupValue: _selectedPayment,
                        onChanged: (v) => setState(() => _selectedPayment = v!),
                        activeColor: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // ── Payment summary (calculation) ────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Rental fee row
                  _summaryRow(
                    label: _days > 0
                        ? 'Rental Fee ($_days day${_days > 1 ? "s" : ""} × ${_currencyFormat.format(widget.item.pricePerDay)})'
                        : 'Rental Fee',
                    value: _currencyFormat.format(_rentalFee),
                    isHighlighted: false,
                  ),
                  const SizedBox(height: 8),

                  // Service fee row (3%)
                  _summaryRow(
                    label: 'Service Fee (3%)',
                    value: _currencyFormat.format(_serviceFee),
                    isHighlighted: false,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: AppTheme.divider, thickness: 1),
                  ),

                  // Total row
                  _summaryRow(
                    label: 'Total',
                    value: _currencyFormat.format(_total),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),

      // ── Bottom confirm button ──────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: _isProcessing
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              )
            : ElevatedButton.icon(
                onPressed: _confirmAndPay,
                icon: const Icon(Icons.lock_rounded, size: 18),
                label: Text(
                  _days > 0
                      ? 'Confirm & Pay ${_currencyFormat.format(_total)}'
                      : 'Select dates to continue',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _days > 0
                      ? AppTheme.primary
                      : AppTheme.textHint,
                ),
              ),
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    required bool isHighlighted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlighted ? 15 : 13,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            color: isHighlighted
                ? AppTheme.textPrimary
                : AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 16 : 13,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted ? AppTheme.accent : AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
