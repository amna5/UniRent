import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/booking_model.dart';
import '../../models/item_model.dart';
import '../../models/user_model.dart';
import '../../services/session_service.dart';
import '../../theme.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currency = NumberFormat.currency(symbol: 'RM', decimalDigits: 2);

  List<BookingModel> _bookings = [];
  List<ItemModel> _items = [];
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final bookings = await DatabaseHelper.instance.getAllBookings();
    final items = await DatabaseHelper.instance.getAllItems();
    final users = await DatabaseHelper.instance.getAllUsers();
    setState(() {
      _bookings = bookings;
      _items = items;
      _users = users;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (confirm == true) {
      await SessionService.clearSession();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  // ── Delete item ─────────────────────────────────────────────
  Future<void> _deleteItem(ItemModel item) async {
    final confirm = await _confirmDelete('item', item.title);
    if (confirm) {
      await DatabaseHelper.instance.deleteItem(item.id!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"${item.title}" deleted'),
        backgroundColor: AppTheme.error,
      ));
      _loadData();
    }
  }

  // ── Delete user ─────────────────────────────────────────────
  Future<void> _deleteUser(UserModel user) async {
    final confirm = await _confirmDelete('user', user.name);
    if (confirm) {
      await DatabaseHelper.instance.deleteUser(user.id!);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('User "${user.name}" removed'),
        backgroundColor: AppTheme.error,
      ));
      _loadData();
    }
  }

  // ── Delete booking ───────────────────────────────────────────
  Future<void> _deleteBooking(BookingModel booking) async {
    final confirm = await _confirmDelete('booking', '#${booking.id}');
    if (confirm) {
      await DatabaseHelper.instance.deleteBooking(booking.id!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Booking deleted'),
        backgroundColor: AppTheme.error,
      ));
      _loadData();
    }
  }

  // ── Update item availability ─────────────────────────────────
  Future<void> _toggleItemAvailability(ItemModel item) async {
    final updated = ItemModel(
      id: item.id,
      ownerId: item.ownerId,
      title: item.title,
      category: item.category,
      description: item.description,
      pricePerDay: item.pricePerDay,
      location: item.location,
      imagePath: item.imagePath,
      isAvailable: item.isAvailable == 1 ? 0 : 1,
      createdAt: item.createdAt,
    );
    await DatabaseHelper.instance.updateItem(updated);
    _loadData();
  }

  // ── Update booking status ────────────────────────────────────
  Future<void> _updateBookingStatus(
      BookingModel booking, String newStatus) async {
    final updated = BookingModel(
      id: booking.id,
      itemId: booking.itemId,
      renterId: booking.renterId,
      startDate: booking.startDate,
      endDate: booking.endDate,
      days: booking.days,
      rentalFee: booking.rentalFee,
      serviceFee: booking.serviceFee,
      totalAmount: booking.totalAmount,
      paymentMethod: booking.paymentMethod,
      paymentStatus: newStatus == 'paid' ? 'paid' : booking.paymentStatus,
      toyyibpayBillCode: booking.toyyibpayBillCode,
      bookingStatus: newStatus,
      createdAt: booking.createdAt,
    );
    await DatabaseHelper.instance.updateBooking(updated);
    _loadData();
  }

  Future<bool> _confirmDelete(String type, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete $type'),
        content: Text(
            'Are you sure you want to delete "$name"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Panel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('UniRent Management',
                style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: 'Bookings (${_bookings.length})'),
            Tab(text: 'Items (${_items.length})'),
            Tab(text: 'Users (${_users.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _BookingsTab(
                  bookings: _bookings,
                  currency: _currency,
                  onDelete: _deleteBooking,
                  onUpdateStatus: _updateBookingStatus,
                ),
                _ItemsTab(
                  items: _items,
                  currency: _currency,
                  onDelete: _deleteItem,
                  onToggleAvailability: _toggleItemAvailability,
                ),
                _UsersTab(
                  users: _users,
                  onDelete: _deleteUser,
                ),
              ],
            ),
    );
  }
}

// ─── Bookings Tab ────────────────────────────────────────────────────────────
class _BookingsTab extends StatelessWidget {
  final List<BookingModel> bookings;
  final NumberFormat currency;
  final Function(BookingModel) onDelete;
  final Function(BookingModel, String) onUpdateStatus;

  const _BookingsTab({
    required this.bookings,
    required this.currency,
    required this.onDelete,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final b = bookings[i];
        final statusColor = _statusColor(b.bookingStatus);
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
                  Text('Booking #${b.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  _StatusBadge(label: b.bookingStatus, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              _infoRow('Item ID', '#${b.itemId}'),
              _infoRow('Renter ID', '#${b.renterId}'),
              _infoRow('Period', '${b.startDate} → ${b.endDate} (${b.days}d)'),
              _infoRow('Rental Fee', currency.format(b.rentalFee)),
              _infoRow('Service Fee (3%)', currency.format(b.serviceFee)),
              _infoRow('Total', currency.format(b.totalAmount)),
              _infoRow('Payment', '${b.paymentMethod} · ${b.paymentStatus}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Update status dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: b.bookingStatus,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        isDense: true,
                      ),
                      items: ['active', 'completed', 'cancelled']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => v != null ? onUpdateStatus(b, v) : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon:
                        const Icon(Icons.delete_rounded, color: AppTheme.error),
                    onPressed: () => onDelete(b),
                    tooltip: 'Delete booking',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}

// ─── Items Tab ───────────────────────────────────────────────────────────────
class _ItemsTab extends StatelessWidget {
  final List<ItemModel> items;
  final NumberFormat currency;
  final Function(ItemModel) onDelete;
  final Function(ItemModel) onToggleAvailability;

  const _ItemsTab({
    required this.items,
    required this.currency,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No items listed yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final item = items[i];
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
                  Expanded(
                    child: Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary)),
                  ),
                  _StatusBadge(
                    label: item.available ? 'Available' : 'Unavailable',
                    color: item.available ? Colors.green : Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                  '${item.category} · ${currency.format(item.pricePerDay)}/day',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary)),
              Text(item.location,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onToggleAvailability(item),
                      icon: Icon(
                        item.available
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 16,
                      ),
                      label: Text(
                          item.available
                              ? 'Mark Unavailable'
                              : 'Mark Available',
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon:
                        const Icon(Icons.delete_rounded, color: AppTheme.error),
                    onPressed: () => onDelete(item),
                    tooltip: 'Delete item',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Users Tab ───────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  final List<UserModel> users;
  final Function(UserModel) onDelete;

  const _UsersTab({required this.users, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No users registered yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final user = users[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary,
                radius: 22,
                child: Text(user.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.textPrimary)),
                    Text(user.email,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text('${user.university} · ⭐ ${user.rating}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text(
                      '${user.itemsListed} listings · ${user.rentalCount} rentals',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: AppTheme.error),
                onPressed: () => onDelete(user),
                tooltip: 'Remove user',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Shared status badge widget ───────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      );
}
