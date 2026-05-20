import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'models.dart';
import 'theme.dart';
import 'chat_screens.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final id = await SessionService.getUserId();
    if (mounted) setState(() => _currentUserId = id);
  }

  bool get _isOwner =>
      _currentUserId != null && _currentUserId == widget.item.ownerId;

  Future<void> _messageOwner() async {
    if (_currentUserId == null) return;
    final results = await Future.wait([
      DatabaseHelper.instance.getOrCreateConversation(
        itemId: widget.item.id!,
        ownerId: widget.item.ownerId,
        renterId: _currentUserId!,
      ),
      DatabaseHelper.instance.getUserById(widget.item.ownerId),
    ]);
    if (!mounted) return;
    final conv = results[0] as ConversationModel;
    final owner = results[1] as UserModel?;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv.id!,
          currentUserId: _currentUserId!,
          otherUserName: owner?.name ?? 'Owner',
          itemTitle: widget.item.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: ItemImage(imagePath: item.imagePath),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Chip(
                        label: Text(_isOwner ? 'Your Listing' : item.category),
                        backgroundColor: _isOwner
                            ? Colors.orange
                            : AppTheme.primary,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM${item.pricePerDay.toStringAsFixed(2)}/day',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(item.description, style: const TextStyle(height: 1.5)),
                  const SizedBox(height: 30),
                  if (_currentUserId != null)
                    _isOwner
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'You cannot rent your own listing.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BookingScreen(item: item),
                                  ),
                                ),
                                child: const Text('Book Now'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: _messageOwner,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(
                                    color: AppTheme.primary,
                                  ),
                                ),
                                child: const Text('Message Owner'),
                              ),
                            ],
                          ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingScreen extends StatefulWidget {
  final ItemModel item;
  const BookingScreen({super.key, required this.item});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPayment = 'Dummy Credit Card';
  bool _isProcessing = false;

  int get _days {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  double get _rentalFee => _days * widget.item.pricePerDay;
  double get _serviceFee => _rentalFee * 0.03;
  double get _total => _rentalFee + _serviceFee;

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? now
          : (_startDate?.add(const Duration(days: 1)) ?? now),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
        }
      } else {
        if (_startDate != null && !picked.isAfter(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End date must be after start date')),
          );
          return;
        }
        _endDate = picked;
      }
    });
  }

  Future<void> _confirmAndPay() async {
    if (_startDate == null || _endDate == null || _days < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid rental period')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    final userId = await SessionService.getUserId();
    if (userId == null) {
      setState(() => _isProcessing = false);
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1000));
    final txId = 'dummy_${DateTime.now().millisecondsSinceEpoch}';

    await DatabaseHelper.instance.insertBooking(
      BookingModel(
        itemId: widget.item.id!,
        renterId: userId,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        days: _days,
        rentalFee: _rentalFee,
        serviceFee: _serviceFee,
        totalAmount: _total,
        paymentMethod: _selectedPayment,
        paymentStatus: _selectedPayment.contains('Card') ? 'paid' : 'pending',
        transactionId: txId,
        bookingStatus: 'active',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    setState(() => _isProcessing = false);
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Booking Confirmed!'),
        content: const Text('Your booking has been created successfully.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to detail
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currency = NumberFormat.currency(symbol: 'RM', decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: ListTile(
                title: Text(
                  widget.item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'RM${widget.item.pricePerDay.toStringAsFixed(2)}/day • ${widget.item.location}',
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rental Dates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: Text(
                _startDate == null
                    ? 'Select Start Date'
                    : 'Starts: ${dateFormat.format(_startDate!)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: true),
            ),
            ListTile(
              title: Text(
                _endDate == null
                    ? 'Select End Date'
                    : 'Ends: ${dateFormat.format(_endDate!)}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioListTile<String>(
              title: const Text('Dummy Credit Card'),
              subtitle: const Text('Simulated card checkout (no real charge)'),
              value: 'Dummy Credit Card',
              groupValue: _selectedPayment,
              onChanged: (v) => setState(() => _selectedPayment = v!),
            ),
            RadioListTile<String>(
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay the owner directly upon pickup'),
              value: 'Cash on Delivery',
              groupValue: _selectedPayment,
              onChanged: (v) => setState(() => _selectedPayment = v!),
            ),
            const SizedBox(height: 16),
            if (_days > 0) ...[
              Card(
                color: AppTheme.cardBg,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Rental fee ($_days days)'),
                          Text(currency.format(_rentalFee)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Service fee (3%)'),
                          Text(currency.format(_serviceFee)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            currency.format(_total),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _isProcessing
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : ElevatedButton(
                    onPressed: _days > 0 ? _confirmAndPay : null,
                    child: Text(
                      _days > 0 ? 'Confirm & Book' : 'Select dates to continue',
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
