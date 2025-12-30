import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BlobBackground extends StatelessWidget {
  final AnimationController controller;

  const BlobBackground({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Blob 1 - Top Right
        Positioned(
          top: -size.height * 0.15,
          right: -size.width * 0.2,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: controller.value * 2 * pi,
                child: Transform.scale(
                  scale: 1 + sin(controller.value * 2 * pi) * 0.1,
                  child: Container(
                    width: size.width * 0.8,
                    height: size.width * 0.8,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(size.width * 0.3),
                        topRight: Radius.circular(size.width * 0.1),
                        bottomLeft: Radius.circular(size.width * 0.2),
                        bottomRight: Radius.circular(size.width * 0.4),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Blob 2 - Bottom Left
        Positioned(
          bottom: -size.height * 0.1,
          left: -size.width * 0.25,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: -controller.value * 2 * pi,
                child: Transform.scale(
                  scale: 1 + cos(controller.value * 2 * pi) * 0.08,
                  child: Container(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withOpacity(0.12),
                          AppColors.accent.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(size.width * 0.4),
                        topRight: Radius.circular(size.width * 0.15),
                        bottomLeft: Radius.circular(size.width * 0.1),
                        bottomRight: Radius.circular(size.width * 0.35),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Blob 3 - Middle
        Positioned(
          top: size.height * 0.4,
          right: size.width * 0.1,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + sin(controller.value * 4 * pi) * 0.05,
                child: Container(
                  width: size.width * 0.3,
                  height: size.width * 0.3,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}