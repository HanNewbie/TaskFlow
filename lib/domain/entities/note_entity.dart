import 'package:equatable/equatable.dart';

class NoteEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Field Baru
  final String priority; // 'low', 'medium', 'high'
  final String category;
  final DateTime? reminderAt;
  final bool isLocked;
  final String? pinHash;

  const NoteEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.priority = 'low',
    this.category = 'Umum',
    this.reminderAt,
    this.isLocked = false,
    this.pinHash,
  });

  @override
  List<Object?> get props => [
    id, 
    userId, 
    title, 
    content, 
    createdAt, 
    updatedAt, 
    priority, 
    category, 
    reminderAt, 
    isLocked, 
    pinHash
  ];
}