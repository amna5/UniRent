import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'models.dart';
import 'theme.dart';
import 'chat_screens.dart';
import 'item_detail_screen.dart';

class MyItemsScreen extends StatefulWidget {
  final int initialTab;
  const MyItemsScreen({super.key, this.initialTab = 0});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ItemModel> _listings = [];
  List<BookingModel> _bookings = [];
  Map<int, ItemModel> _itemsMap = {};
  bool _loading = true;
  int? _userId;
  final _currency = NumberFormat.currency(symbol: 'RM', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _userId = await SessionService.getUserId();
    if (_userId != null) {
      final listings = await DatabaseHelper.instance.getItemsByOwner(_userId!);
      final bookings = await DatabaseHelper.instance.getBookingsByRenter(
        _userId!,
      );

      final itemIds = bookings.map((b) => b.itemId).toSet();
      final Map<int, ItemModel> itemsMap = {};
      for (final itemId in itemIds) {
        final item = await DatabaseHelper.instance.getItemById(itemId);
        if (item != null) itemsMap[itemId] = item;
      }

      setState(() {
        _listings = listings;
        _bookings = bookings;
        _itemsMap = itemsMap;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _deleteItem(ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove listing'),
        content: Text('Remove "${item.title}"?'),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteItem(item.id!);
      _loadData();
    }
  }

  Future<void> _toggleAvailability(ItemModel item) async {
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

  Future<void> _contactOwner(BookingModel booking) async {
    final item = _itemsMap[booking.itemId];
    if (item == null || _userId == null) return;

    final results = await Future.wait([
      DatabaseHelper.instance.getOrCreateConversation(
        itemId: item.id!,
        ownerId: item.ownerId,
        renterId: _userId!,
      ),
      DatabaseHelper.instance.getUserById(item.ownerId),
    ]);

    if (!mounted) return;
    final conv = results[0] as ConversationModel;
    final owner = results[1] as UserModel?;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv.id!,
          currentUserId: _userId!,
          otherUserId: conv.renterId,
          otherUserName: owner?.name ?? 'Owner',
          itemTitle: item.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals & Listings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'My Rentals'),
            Tab(text: 'My Listings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildRentalsTab(), _buildListingsTab()],
            ),
    );
  }

  Widget _buildRentalsTab() {
    if (_bookings.isEmpty) {
      return const Center(child: Text('No rentals yet.'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _bookings.length,
        itemBuilder: (_, i) {
          final b = _bookings[i];
          final item = _itemsMap[b.itemId];
          final isActive = b.bookingStatus == 'active';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item?.title ?? 'Item #${b.itemId}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        isActive ? 'Active' : 'Completed',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${b.startDate} to ${b.endDate}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _currency.format(b.totalAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      if (isActive)
                        ElevatedButton(
                          onPressed: () => _contactOwner(b),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(120, 36),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text(
                            'Contact Owner',
                            style: TextStyle(fontSize: 12),
                          ),
                        )
                      else
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Review feature coming soon!'),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(120, 36),
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                          ),
                          child: const Text(
                            'Leave Review',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListingsTab() {
    if (_listings.isEmpty) {
      return const Center(child: Text('No listings yet.'));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _listings.length,
        itemBuilder: (_, i) {
          final item = _listings[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ItemImage(imagePath: item.imagePath),
                ),
              ),
              title: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${_currency.format(item.pricePerDay)}/day • ${item.available ? "Available" : "Unavailable"}',
                style: TextStyle(
                  color: item.available ? Colors.green : Colors.grey,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      item.available ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: () => _toggleAvailability(item),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: AppTheme.error,
                      size: 20,
                    ),
                    onPressed: () => _deleteItem(item),
                  ),
                ],
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item)),
              ),
            ),
          );
        },
      ),
    );
  }
}
