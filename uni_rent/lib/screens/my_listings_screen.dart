import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/item_model.dart';
import '../services/session_service.dart';
import '../theme.dart';
import '../widgets/item_image.dart';
import 'item_detail_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  List<ItemModel> _items = [];
  bool _loading = true;
  final _currency = NumberFormat.currency(symbol: 'RM', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = await SessionService.getUserId();
    if (userId != null) {
      final items = await DatabaseHelper.instance.getItemsByOwner(userId);
      setState(() => _items = items);
    }
    setState(() => _loading = false);
  }

  Future<void> _deleteItem(ItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove listing'),
        content: Text('Remove "${item.title}" from your listings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseHelper.instance.deleteItem(item.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.title}" removed'),
          backgroundColor: AppTheme.error,
        ),
      );
      _load();
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
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : _items.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 64, color: AppTheme.textSecondary),
                        SizedBox(height: 16),
                        Text('No listings yet',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary)),
                        SizedBox(height: 8),
                        Text('Tap the + tab to list your first item',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textHint)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(item: item)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              // Thumbnail
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12)),
                                child: SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: ItemImage(imagePath: item.imagePath),
                                ),
                              ),
                              // Info
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_currency.format(item.pricePerDay)}/day',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.primary),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: item.available
                                              ? const Color(0xFFE8F5E9)
                                              : const Color(0xFFF5F5F5),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.available
                                              ? 'Available'
                                              : 'Unavailable',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: item.available
                                                  ? Colors.green[700]
                                                  : AppTheme.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Actions
                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      item.available
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppTheme.textSecondary,
                                    ),
                                    tooltip: item.available
                                        ? 'Mark unavailable'
                                        : 'Mark available',
                                    onPressed: () =>
                                        _toggleAvailability(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: AppTheme.error),
                                    tooltip: 'Remove listing',
                                    onPressed: () => _deleteItem(item),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
