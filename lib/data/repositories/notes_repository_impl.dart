import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/notes_repository.dart';
import '../datasources/firebase_notes_datasource.dart';
import '../models/note_model.dart';

class NotesRepositoryImpl implements NotesRepository {
  final FirebaseNotesDataSource notesDataSource;
  // Kita butuh akses Firestore langsung untuk versioning sub-collection
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  NotesRepositoryImpl({required this.notesDataSource});

  @override
  Stream<List<NoteEntity>> getNotes(String userId) {
    return notesDataSource.getNotes(userId).map(
      (models) => models.map((model) => model as NoteEntity).toList(),
    );
  }

  @override
  Future<NoteEntity?> getNote(String id) async {
    final noteModel = await notesDataSource.getNote(id);
    return noteModel;
  }

  @override
  Future<void> addNote(NoteEntity note) async {
    final noteModel = NoteModel.fromEntity(note);
    return await notesDataSource.createNote(noteModel);
  }

  @override
  Future<void> updateNote(NoteEntity note) async {
    // --- FITUR VERSIONING (BACKUP DATA LAMA) ---
    try {
      final docRef = _firestore.collection('notes').doc(note.id);
      final snapshot = await docRef.get();
      
      if (snapshot.exists) {
        // Coba simpan data lama ke sub-collection 'versions'
        // Jika Security Rules memblokir, ini akan masuk ke catch
        await docRef.collection('versions').add({
          ...snapshot.data()!,
          'archivedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Jika gagal backup (misal karena permission denied), 
      // kita log error-nya tapi JANGAN stop proses update utama.
      print("⚠️ Warning: Gagal membuat backup versi (Permission/Error): $e");
    }

    // --- UPDATE DATA UTAMA ---
    // Proses ini tetap berjalan agar user bisa menyimpan perubahan
    final noteModel = NoteModel.fromEntity(note);
    return await notesDataSource.updateNote(noteModel);
  }

  @override
  Future<void> deleteNote(String noteId) async {
    return await notesDataSource.deleteNote(noteId);
  }
}
