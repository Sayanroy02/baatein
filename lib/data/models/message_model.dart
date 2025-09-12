import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file }

enum MessageStatus { sent, delivered, read }

class MessageModel extends Equatable {
  final String id;
  final String senderId;
  final String content;
  final String? encryptedContent;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToId;
  final bool isDeleted;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.encryptedContent,
    required this.type,
    required this.status,
    required this.timestamp,
    this.replyToId,
    required this.isDeleted,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      encryptedContent: data['encryptedContent'],
      type: MessageType.values[data['type'] ?? 0],
      status: MessageStatus.values[data['status'] ?? 0],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      replyToId: data['replyToId'],
      isDeleted: data['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'content': content,
      'encryptedContent': encryptedContent,
      'type': type.index,
      'status': status.index,
      'timestamp': Timestamp.fromDate(timestamp),
      'replyToId': replyToId,
      'isDeleted': isDeleted,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    String? encryptedContent,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyToId,
    bool? isDeleted,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      encryptedContent: encryptedContent ?? this.encryptedContent,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyToId: replyToId ?? this.replyToId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    content,
    encryptedContent,
    type,
    status,
    timestamp,
    replyToId,
    isDeleted,
  ];
}
