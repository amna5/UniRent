import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/booking_model.dart';
import '../models/conversation_model.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'item_detail_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});
  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<BookingModel> _bookings = [];
  Map<int, ItemModel> _itemsMap = {};
  int? _currentUserId;
  final _currency = NumberFormat.currency(symbol: 'RM', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = await SessionService.getUserId();
    if (id == null) return;
    final bookings = await DatabaseHelper.instance.getBookingsByRenter(id);

    // Fetch the ItemModel for every unique item in the bookings list
    final itemIds = bookings.map((b) => b.itemId).toSet();
    final Map<int, ItemModel> itemsMap = {};
    for (final itemId in itemIds) {
      final item = await DatabaseHelper.instance.getItemById(itemId);
      if (item != null) itemsMap[itemId] = item;
    }

    if (mounted) {
      setState(() {
        _bookings = bookings;
        _itemsMap = itemsMap;
        _currentUserId = id;
      });
    }
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
          _BookingList(
            bookings: _renting,
            itemsMap: _itemsMap,
            currentUserId: _currentUserId,
            currency: _currency,
          ),
          _BookingList(
            bookings: _completed,
            itemsMap: _itemsMap,
            currentUserId: _currentUserId,
            currency: _currency,
          ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final Map<int, ItemModel> itemsMap;
  final int? currentUserId;
  final NumberFormat currency;

  const _BookingList({
    required this.bookings,
    required this.itemsMap,
    required this.currentUserId,
    required this.currency,
  });

  Future<void> _contactOwner(BuildContext context, BookingModel booking) async {
    final item = itemsMap[booking.itemId];
    if (item == null || currentUserId == null) return;

    final results = await Future.wait([
      DatabaseHelper.instance.getOrCreateConversation(
        itemId: item.id!,
        ownerId: item.ownerId,
        renterId: currentUserId!,
      ),
      DatabaseHelper.instance.getUserById(item.ownerId),
    ]);

    if (!context.mounted) return;
    final conv = results[0] as ConversationModel;
    final owner = results[1] as UserModel?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv.id!,
          currentUserId: currentUserId!,
          otherUserName: owner?.name ?? 'Owner',
          itemTitle: item.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings here yet'));
    }
    return RefreshIndicator(
      onRefresh: () async {},
      color: AppTheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final b = bookings[i];
          final item = itemsMap[b.itemId];
          final isActive = b.bookingStatus == 'active';

          return GestureDetector(
            onTap: item != null
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(item: item)),
                    )
                : null,
            child: Container(
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
                      Expanded(
                        child: Text(
                          item?.title ?? 'Item #${b.itemId}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
                  if (item != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.location,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
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
                      onPressed: isActive
                          ? () => _contactOwner(context, b)
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Review feature coming soon')),
                              );
                            },
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
            ),
          );
        },
      ),
    );
  }
}
