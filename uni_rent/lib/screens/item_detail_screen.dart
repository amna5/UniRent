import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/conversation_model.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';
import '../theme.dart';
import '../widgets/item_image.dart';
import 'booking_screen.dart';
import 'chat_screen.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.arrow_back, color: AppTheme.primary, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ItemImage(
                imagePath: item.imagePath,
                placeholder: _imagePlaceholder(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      // Show "Your Listing" badge if owner, else category badge
                      if (_isOwner)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Your Listing',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM${item.pricePerDay.toStringAsFixed(2)}/day',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        item.location,
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: _currentUserId == null
            // Still loading session — show nothing yet
            ? const SizedBox.shrink()
            : _isOwner
                // Owner view — can't rent your own item
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline,
                            size: 18, color: AppTheme.textSecondary),
                        SizedBox(width: 8),
                        Text(
                          'You cannot rent your own listing',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                // Renter view — show Book Now + Message Owner
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookingScreen(item: item)),
                        ),
                        icon: const Icon(Icons.calendar_month_rounded, size: 18),
                        label: const Text('Book Now'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _messageOwner,
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Message Owner'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppTheme.cardBg,
        child: const Center(
          child: Icon(Icons.inventory_2_rounded,
              size: 80, color: AppTheme.textSecondary),
        ),
      );
}
