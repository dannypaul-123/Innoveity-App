import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class AppDropdownMenu extends StatelessWidget {
  final AppState state;

  const AppDropdownMenu({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = state.isDarkMode;

    return Builder(
      builder: (scaffoldContext) {
        return InkWell(
          onTap: () {
            Scaffold.of(scaffoldContext).openDrawer();
          },
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primaryPine.withValues(alpha: 0.25)
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? AppColors.vibrantEmerald.withValues(alpha: 0.4)
                      : AppColors.borderEmerald,
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.menu_rounded,
                size: 20,
                color: isDark ? AppColors.vibrantEmerald : AppColors.primaryPine,
              ),
            ),
          ),
        );
      },
    );
  }
}
