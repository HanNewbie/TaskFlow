import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../data/datasources/firebase_notes_datasource.dart'; // Import ini jika main.dart mewajibkannya
import '../../core/services/notification_service.dart';

class NotesProvider extends ChangeNotifier {
  final NotesRepository notesRepository;
  
  // Tambahkan ini agar kompatibel dengan main.dart kamu yang mengirim notesDataSource
  final FirebaseNotesDataSource? notesDataSource; 
  final NotificationService _notificationService = NotificationService.instance;

  NotesProvider({
    required this.notesRepository,
    this.notesDataSource,
  });

  List<NoteEntity> _notes = [];
  List<NoteEntity> get notes => _notes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<NoteEntity>>? _notesSubscription;
  String? _userId;

  // Dipanggil saat user login/logout atau aplikasi mulai
  void updateUserId(String? userId) {
    _userId = userId;
    _notesSubscription?.cancel();

    if (_userId != null) {
      _isLoading = true;
      notifyListeners();

      // Mendengarkan perubahan data realtime dari Firestore
      _notesSubscription = notesRepository.getNotes(_userId!).listen(
        (updatedNotes) {
          _notes = updatedNotes;
          // Opsional: Urutkan berdasarkan updated terbaru
          _notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          print("Error stream notes: $error");
          _isLoading = false;
          notifyListeners();
        },
      );
    } else {
      _notes = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambah Catatan Baru
  Future<void> addNote(NoteEntity note) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Pastikan userId terisi
      final noteWithUser = NoteEntity(
        id: note.id,
        userId: _userId ?? '',
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        priority: note.priority,
        category: note.category,
        reminderAt: note.reminderAt,
        isLocked: note.isLocked,
        pinHash: note.pinHash,
      );

      await notesRepository.addNote(noteWithUser);
      await _scheduleReminderSafe(noteWithUser);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update Catatan
  Future<void> updateNote(NoteEntity note) async {
    try {
      _isLoading = true;
      notifyListeners();

      final noteWithUser = NoteEntity(
        id: note.id,
        userId: _userId ?? note.userId,
        title: note.title,
        content: note.content,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(), // Selalu update waktu edit
        priority: note.priority,
        category: note.category,
        reminderAt: note.reminderAt,
        isLocked: note.isLocked,
        pinHash: note.pinHash,
      );

      await notesRepository.updateNote(noteWithUser);
      await _cancelReminderSafe(noteWithUser.id);
      await _scheduleReminderSafe(noteWithUser);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hapus Catatan
  Future<void> deleteNote(String noteId) async {
    try {
      await notesRepository.deleteNote(noteId);
      await _cancelReminderSafe(noteId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _scheduleReminderSafe(NoteEntity note) async {
    if (note.reminderAt == null) return;
    try {
      await _notificationService.scheduleReminder(note);
    } catch (e) {
      debugPrint('Failed to schedule reminder: $e');
    }
  }

  Future<void> _cancelReminderSafe(String noteId) async {
    try {
      await _notificationService.cancelReminder(noteId);
    } catch (e) {
      debugPrint('Failed to cancel reminder: $e');
    }
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    super.dispose();
  }
}
