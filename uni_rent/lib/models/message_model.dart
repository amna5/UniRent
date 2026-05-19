class MessageModel {
  final int? id;
  final int conversationId;
  final int senderId;
  final String content;
  final String createdAt;
  final bool isRead;

  MessageModel({
    this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
    id: map['id'] as int?,
    conversationId: map['conversation_id'] as int,
    senderId: map['sender_id'] as int,
    content: map['content'] as String,
    createdAt: map['created_at'] as String,
    isRead: (map['is_read'] as int? ?? 0) == 1,
  );

  Map<String, dynamic> toMap() => {
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'created_at': createdAt,
    'is_read': isRead ? 1 : 0,
  };
}
