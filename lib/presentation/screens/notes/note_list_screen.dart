import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/note_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_loading.dart';
import 'note_form_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  String _searchQuery = '';
  String _filterPriority = 'All'; // All, low, medium, high

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        context.read<NotesProvider>().updateUserId(authProvider.user!.id);
      }
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Text('Apakah Anda yakin ingin keluar?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 0, offset: Offset(0, 4)),
              ],
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final notesProvider = context.watch<NotesProvider>();

    final filteredNotes = notesProvider.notes.where((note) {
      final matchKeyword = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           note.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchPriority = _filterPriority == 'All' || note.priority == _filterPriority;
      return matchKeyword && matchPriority;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.background),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, 👋', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                            Text(
                              authProvider.user?.displayName ?? 'User',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 0, offset: Offset(4, 4)),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.logout_rounded, color: AppColors.accent),
                          onPressed: _handleLogout,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 0, offset: Offset(4, 4)),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Cari catatan...',
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'low', 'medium', 'high'].map((p) {
                        final isSelected = _filterPriority == p;
                        Color color;
                        switch(p) {
                          case 'high': color = Colors.red; break;
                          case 'medium': color = Colors.orange; break;
                          case 'low': color = Colors.green; break;
                          default: color = AppColors.primary;
                        }
                        
                        return GestureDetector(
                          onTap: () => setState(() => _filterPriority = p),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? color : AppColors.primary.withOpacity(0.2),
                                width: 2
                              ),
                            ),
                            child: Text(
                              p.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            
            // Notes List
            Expanded(
              child: notesProvider.isLoading
                  ? ShimmerLoading()
                  : filteredNotes.isEmpty
                      ? EmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = filteredNotes[index];
                            return NoteCard(
                              note: note,
                              onTap: () => _navigateToEditNote(note),
                              onDelete: () => _handleDelete(note.id),
                            ).animate().fadeIn(
                              delay: (100 * index).ms,
                              duration: 400.ms,
                            ).slideX(begin: -0.2, end: 0);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 16, right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 0, offset: Offset(0, 6)),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddNote(),
          backgroundColor: AppColors.accent,
          elevation: 0,
          icon: Icon(Icons.add_rounded, size: 28),
          label: Text(
            'Buat Catatan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ),
      ).animate().scale(delay: 600.ms, curve: Curves.elasticOut),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _navigateToAddNote() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteFormScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToEditNote(NoteEntity note) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => NoteFormScreen(note: note),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic)),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _handleDelete(String noteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Catatan', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
          Container(
            decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
            child: TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus', style: TextStyle(color: Colors.white))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<NotesProvider>().deleteNote(noteId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.successNoteDeleted),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppConstants.errorGeneric), backgroundColor: AppColors.accent),
          );
        }
      }
    }
  }
}