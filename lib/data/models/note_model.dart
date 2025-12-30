import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/note_entity.dart';

class NoteModel extends NoteEntity {
  const NoteModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.content,
    required super.createdAt,
    required super.updatedAt,
    required super.priority,
    required super.category,
    super.reminderAt,
    required super.isLocked,
    super.pinHash,
  });

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      priority: data['priority'] ?? 'low',
      category: data['category'] ?? 'Umum',
      reminderAt: data['reminderAt'] != null 
          ? (data['reminderAt'] as Timestamp).toDate() 
          : null,
      isLocked: data['isLocked'] ?? false,
      pinHash: data['pinHash'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'priority': priority,
      'category': category,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'isLocked': isLocked,
      'pinHash': pinHash,
    };
  }

  factory NoteModel.fromEntity(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      priority: entity.priority,
      category: entity.category,
      reminderAt: entity.reminderAt,
      isLocked: entity.isLocked,
      pinHash: entity.pinHash,
    );
  }
}