// my_rentals_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/booking_model.dart';
import '../services/session_service.dart';
import '../theme.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});
  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<BookingModel> _bookings = [];
  final _currency = NumberFormat.currency(symbol: 'RM', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final id = await SessionService.getUserId();
    if (id == null) return;
    final bookings = await DatabaseHelper.instance.getBookingsByRenter(id);
    setState(() => _bookings = bookings);
  }

  List<BookingModel> get _renting =>
      _bookings.where((b) => b.bookingStatus == 'active').toList();
  List<BookingModel> get _completed =>
      _bookings.where((b) => b.bookingStatus == 'completed').toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Rentals'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Renting (${_renting.length})'),
            Tab(text: 'Completed (${_completed.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BookingList(bookings: _renting, currency: _currency),
          _BookingList(bookings: _completed, currency: _currency),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final NumberFormat currency;
  const _BookingList({required this.bookings, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings here yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final b = bookings[i];
        final isActive = b.bookingStatus == 'active';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Item #${b.itemId}',
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Completed',
                      style: TextStyle(
                          fontSize: 11,
                          color: isActive ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 13, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${b.startDate} → ${b.endDate}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const Spacer(),
                  Text(currency.format(b.totalAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(isActive ? 'Contact Owner' : 'Leave Review',
                      style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
