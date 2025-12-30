import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/note_entity.dart';

class NoteCard extends StatefulWidget {
  final NoteEntity note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- LOGIC BUKA KUNCI ---
  void _handleTap() {
    if (widget.note.isLocked) {
      _showUnlockDialog();
    } else {
      widget.onTap();
    }
  }

  void _showUnlockDialog() {
    String inputPin = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.red),
            SizedBox(width: 8),
            Text('Terkunci', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Masukkan PIN',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (val) => inputPin = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              final inputHash = sha256.convert(utf8.encode(inputPin)).toString();
              if (inputHash == widget.note.pinHash) {
                Navigator.pop(ctx);
                widget.onTap(); // Buka catatan jika PIN benar
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PIN Salah!')),
                );
              }
            },
            child: Text('Buka', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
  // ------------------------

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Kemarin ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  String _formatReminder(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Color _getCardColor(int index) {
    final colors = [
      Colors.white,
      AppColors.primary.withOpacity(0.05),
      AppColors.accent.withOpacity(0.05),
    ];
    return colors[index % colors.length];
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(widget.note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 0,
              offset: Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              content: Text('Catatan yang dihapus tidak dapat dikembalikan.', style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                Container(
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      widget.onDelete();
                    },
                    child: Text('Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          _handleTap(); // Panggil logic tap custom
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _getCardColor(widget.note.id.hashCode),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(8),
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(24),
              ),
              border: Border.all(color: AppColors.primary.withOpacity(0.15), width: 2),
              boxShadow: [
                BoxShadow(
                  color: _isPressed ? AppColors.primary.withOpacity(0.05) : AppColors.primary.withOpacity(0.1),
                  blurRadius: 0,
                  offset: _isPressed ? Offset(4, 4) : Offset(8, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative Circle
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.05)),
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Priority Dot & Category
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(widget.note.priority).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getPriorityColor(widget.note.priority), width: 1)
                            ),
                            child: Text(
                              widget.note.priority.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                color: _getPriorityColor(widget.note.priority)
                              ),
                            ),
                          ),
                          Text(
                            widget.note.category,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Title with Icon
                      Row(
                        children: [
                          if (widget.note.isLocked)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.lock, size: 16, color: Colors.red),
                            ),
                          Expanded(
                            child: Text(
                              widget.note.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Content Preview (Blur jika Locked)
                      if (widget.note.content.isNotEmpty)
                        widget.note.isLocked 
                        ? Text(
                            '🔒 Konten Terkunci',
                            style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                          )
                        : Text(
                            widget.note.content,
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                      
                      SizedBox(height: 16),
                      
                      // Footer with Date & Reminder Icon
                      Row(
                        children: [
                          if (widget.note.reminderAt != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.notifications_active, size: 14, color: AppColors.accent),
                            ),
                            Text(
                              _formatReminder(widget.note.reminderAt!),
                              style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w700),
                            ),
                          ] else ...[
                            Text(
                              _formatDate(widget.note.updatedAt),
                              style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                          ],
                          Spacer(),
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.accent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
