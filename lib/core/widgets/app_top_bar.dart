import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/theme/theme_controller.dart';
import 'package:raigon_art/core/widgets/shell_scope.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.notificationCount,
    required this.onBellTap,
  });

  final int notificationCount;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: p.card(radius: 16),
      child: Row(
        children: [
          Icon(Icons.search, size: 24, color: p.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              cursorColor: p.textPrimary,
              style: TextStyle(fontSize: 15.5, color: p.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Quick search customers, orders, photos...',
                hintStyle: TextStyle(fontSize: 15.5, color: p.textMuted),
              ),
            ),
          ),
          IconButton(
            tooltip: p.isDark ? 'Light mode' : 'Dark mode',
            onPressed: ThemeController.toggle,
            icon: Icon(
              p.isDark ? Icons.wb_sunny : Icons.dark_mode,
              size: 22,
              color: p.isDark ? const Color(0xFFF5B301) : p.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onBellTap,
                icon: Icon(Icons.notifications, size: 24, color: p.textPrimary),
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 2,
                  top: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5484D),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$notificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          Tooltip(
            message: 'Business Profile',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  ShellScope.of(context).goTo(NavDestination.profile);
                },
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.avatarBg,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Text(
                    'RA',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
