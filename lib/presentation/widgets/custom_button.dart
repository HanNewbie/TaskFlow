import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool outlined;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.outlined = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.outlined 
      ? Colors.transparent 
      : (widget.backgroundColor ?? AppColors.accent);
    final fgColor = widget.outlined
      ? (widget.textColor ?? AppColors.accent)
      : (widget.textColor ?? Colors.white);

    return GestureDetector(
      onTapDown: widget.onPressed != null && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            }
          : null,
      onTapUp: widget.onPressed != null && !widget.isLoading
          ? (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.outlined ? Colors.transparent : bgColor,
            borderRadius: BorderRadius.circular(16),
            border: widget.outlined
                ? Border.all(
                    color: widget.backgroundColor ?? AppColors.accent,
                    width: 2,
                  )
                : null,
            boxShadow: !widget.outlined
                ? [
                    BoxShadow(
                      color: bgColor.withOpacity(0.4),
                      blurRadius: 0,
                      offset: _isPressed ? Offset(0, 3) : Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed != null && !widget.isLoading 
                ? widget.onPressed 
                : null,
              borderRadius: BorderRadius.circular(16),
              splashColor: fgColor.withOpacity(0.1),
              highlightColor: fgColor.withOpacity(0.05),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: widget.isLoading
                    ? Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: fgColor,
                              size: 22,
                            ),
                            SizedBox(width: 12),
                          ],
                          Text(
                            widget.text,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: fgColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}