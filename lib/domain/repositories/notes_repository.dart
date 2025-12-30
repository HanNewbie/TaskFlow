import '../entities/note_entity.dart';

abstract class NotesRepository {
  Stream<List<NoteEntity>> getNotes(String userId);
  Future<NoteEntity?> getNote(String id);
  Future<void> addNote(NoteEntity note);
  Future<void> updateNote(NoteEntity note);
  Future<void> deleteNote(String id);
}
