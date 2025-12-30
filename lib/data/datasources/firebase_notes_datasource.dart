import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class FirebaseNotesDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notes';

  Stream<List<NoteModel>> getNotes(String userId) {
    try {
      return _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NoteModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('ƒ?O Error getting notes stream: $e');
      throw Exception('Gagal mengambil catatan: $e');
    }
  }

  Future<void> createNote(NoteModel note) async {
    try {
      final collection = _firestore.collection(_collection);
      final docRef = note.id.isNotEmpty
          ? collection.doc(note.id)
          : collection.doc();
      await docRef.set(note.toFirestore());
      print('ƒo. Note created successfully');
    } catch (e) {
      print('ƒ?O Error creating note: $e');
      throw Exception('Gagal menambah catatan: $e');
    }
  }

  Future<void> updateNote(NoteModel note) async {
    try {
      if (note.id.isEmpty) {
        throw Exception('Note ID is empty');
      }
      await _firestore
          .collection(_collection)
          .doc(note.id)
          .update(note.toFirestore());
      print('ƒo. Note updated successfully');
    } catch (e) {
      print('ƒ?O Error updating note: $e');
      throw Exception('Gagal memperbarui catatan: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      if (noteId.isEmpty) {
        throw Exception('Note ID is empty');
      }
      await _firestore.collection(_collection).doc(noteId).delete();
      print('ƒo. Note deleted successfully');
    } catch (e) {
      print('ƒ?O Error deleting note: $e');
      throw Exception('Gagal menghapus catatan: $e');
    }
  }

  Future<NoteModel?> getNote(String noteId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(noteId).get();
      if (doc.exists) {
        return NoteModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('ƒ?O Error getting note: $e');
      throw Exception('Gagal mengambil catatan: $e');
    }
  }
}
