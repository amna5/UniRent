class ConversationModel {
  final int? id;
  final int itemId;
  final int ownerId;
  final int renterId;
  final String? lastMessage;
  final String? lastMessageAt;
  final String createdAt;

  // Populated via JOIN queries
  final String? itemTitle;
  final String? otherUserName;

  ConversationModel({
    this.id,
    required this.itemId,
    required this.ownerId,
    required this.renterId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.itemTitle,
    this.otherUserName,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) =>
      ConversationModel(
        id: map['id'] as int?,
        itemId: map['item_id'] as int,
        ownerId: map['owner_id'] as int,
        renterId: map['renter_id'] as int,
        lastMessage: map['last_message'] as String?,
        lastMessageAt: map['last_message_at'] as String?,
        createdAt: map['created_at'] as String,
        itemTitle: map['item_title'] as String?,
        otherUserName: map['other_user_name'] as String?,
      );

  Map<String, dynamic> toMap() => {
    'item_id': itemId,
    'owner_id': ownerId,
    'renter_id': renterId,
    'last_message': lastMessage,
    'last_message_at': lastMessageAt,
    'created_at': createdAt,
  };
}
