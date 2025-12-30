import 'dart:convert';
import 'package:crypto/crypto.dart'; // Pastikan sudah 'flutter pub add crypto'
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/note_entity.dart';
import '../../providers/notes_provider.dart';

class NoteFormScreen extends StatefulWidget {
  final NoteEntity? note;

  const NoteFormScreen({super.key, this.note});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;
  late AnimationController _fabController;

  // New Fields
  String _priority = 'low';
  String _category = 'Umum';
  DateTime? _reminderDate;
  bool _isLocked = false;
  String? _pinHash;

  final List<String> _categories = ['Umum', 'Kuliah', 'Pribadi', 'Ide', 'Kerjaan'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    
    // Init existing values if edit
    if (widget.note != null) {
      _priority = widget.note!.priority;
      _category = widget.note!.category;
      _reminderDate = widget.note!.reminderAt;
      _isLocked = widget.note!.isLocked;
      _pinHash = widget.note!.pinHash;
    }

    _fabController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _fabController.forward();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  // Logic Hashing PIN
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<void> _showPinDialog() async {
    String inputPin = '';
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set Keamanan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Masukkan 4 digit PIN untuk mengunci catatan ini.'),
            SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => inputPin = val,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (inputPin.length == 4) {
                setState(() {
                  _isLocked = true;
                  _pinHash = _hashPin(inputPin);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Catatan dikunci!')),
                );
              }
            },
            child: Text('Kunci', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _reminderDate = DateTime(
            date.year, date.month, date.day, time.hour, time.minute
          );
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final notesProvider = context.read<NotesProvider>();

    // Buat objek NoteEntity baru
    final newNote = NoteEntity(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), // ID sementara jika baru
      userId: widget.note?.userId ?? '', // Akan diisi di Provider/Repo
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      // Field Baru
      priority: _priority,
      category: _category,
      reminderAt: _reminderDate,
      isLocked: _isLocked,
      pinHash: _pinHash,
    );

    try {
      if (widget.note == null) {
        // Create new note
        await notesProvider.addNote(newNote);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.successNoteCreated),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        // Update existing note
        await notesProvider.updateNote(newNote);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppConstants.successNoteUpdated),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConstants.errorGeneric),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 0,
                          offset: Offset(4, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Catatan' : 'Catatan Baru',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          isEdit ? 'Perbarui catatan Anda' : 'Tulis ide Anda',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TITLE FIELD
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(20),
                          ),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 0,
                              offset: Offset(8, 8),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _titleController,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Judul catatan...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.5),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(20),
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(16),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.title_rounded, color: AppColors.accent, size: 20),
                              ),
                            ),
                          ),
                          validator: Validators.validateTitle,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
                      
                      SizedBox(height: 20),

                      // METADATA SECTION (Kategori, Priority, Tools)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Kategori Dropdown
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _category,
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                  onChanged: (val) => setState(() => _category = val!),
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                                  icon: Icon(Icons.category_rounded, color: AppColors.primary),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),

                            // Reminder Button
                            GestureDetector(
                              onTap: _pickDateTime,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _reminderDate != null ? AppColors.accent.withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _reminderDate != null ? AppColors.accent : AppColors.primary.withOpacity(0.2), 
                                    width: 2
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_rounded, 
                                      color: _reminderDate != null ? AppColors.accent : AppColors.primary, 
                                      size: 20
                                    ),
                                    if (_reminderDate != null) ...[
                                      SizedBox(width: 6),
                                      Text(
                                        DateFormat('dd/MM HH:mm').format(_reminderDate!),
                                        style: TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),

                            // Lock Button
                            GestureDetector(
                              onTap: _isLocked 
                                ? () => setState(() { _isLocked = false; _pinHash = null; }) 
                                : _showPinDialog,
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isLocked ? Colors.red.withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isLocked ? Colors.red : AppColors.primary.withOpacity(0.2), 
                                    width: 2
                                  ),
                                ),
                                child: Icon(
                                  _isLocked ? Icons.lock : Icons.lock_open_rounded,
                                  color: _isLocked ? Colors.red : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms),

                      SizedBox(height: 16),

                      // Priority Chips
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: ['low', 'medium', 'high'].map((p) {
                            final isSelected = _priority == p;
                            Color activeColor;
                            switch(p) {
                              case 'high': activeColor = Colors.red; break;
                              case 'medium': activeColor = Colors.orange; break;
                              default: activeColor = Colors.green;
                            }

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _priority = p),
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  margin: EdgeInsets.symmetric(horizontal: 4),
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? activeColor : Colors.transparent,
                                      width: 2
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      p.toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected ? activeColor : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      SizedBox(height: 20),
                      
                      // CONTENT FIELD
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 0,
                              offset: Offset(8, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary.withOpacity(0.03),
                                ),
                              ),
                            ),
                            TextFormField(
                              controller: _contentController,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                                height: 1.8,
                              ),
                              maxLines: 15,
                              decoration: InputDecoration(
                                hintText: 'Tulis catatan Anda di sini...\n\nCeritakan apa yang ada di pikiran Anda.',
                                hintStyle: TextStyle(
                                  color: AppColors.textSecondary.withOpacity(0.5),
                                  height: 1.8,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(24),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),
                      
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabController,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 0,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _isSaving ? null : _handleSave,
            backgroundColor: AppColors.accent,
            elevation: 0,
            icon: _isSaving 
              ? SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Icon(Icons.check_rounded, size: 28),
            label: Text(
              _isSaving ? 'Menyimpan...' : 'Simpan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}