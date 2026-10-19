import 'package:flutter/material.dart';
import 'package:raigon_art/core/constants/asset_constants.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/shell_scope.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.collapsed,
    required this.current,
    required this.onToggle,
    required this.onSelect,
    required this.onLogout,
    required this.isAdmin,
  });

  static const double expandedWidth = 300;
  static const double collapsedWidth = 76;

  final bool collapsed;
  final NavDestination current;
  final VoidCallback onToggle;
  final ValueChanged<NavDestination> onSelect;
  final VoidCallback onLogout;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: collapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: p.sidebarBg,
        border: Border(right: BorderSide(color: p.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showLabels = constraints.maxWidth > 170;
          return Column(
            children: [
              _header(p, showLabels),
              Divider(height: 1, color: p.border),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    for (final destination in NavDestination.values.where(
                      (destination) => destination.canAccess(isAdmin: isAdmin),
                    ))
                      _item(
                        p: p,
                        label: destination.label,
                        icon: destination.icon,
                        active: destination == current,
                        showLabels: showLabels,
                        onTap: () => onSelect(destination),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: p.border),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _item(
                  p: p,
                  label: 'Logout',
                  icon: Icons.power_settings_new,
                  active: false,
                  showLabels: showLabels,
                  color: AppPalette.red,
                  onTap: onLogout,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _logoTile(AppPalette p) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: p.avatarBg,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Image.asset(AssetConstants.raigonLogo, fit: BoxFit.cover),
  );

  Widget _header(AppPalette p, bool showLabels) {
    return SizedBox(
      height: 80,
      child: showLabels
          ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Row(
                children: [
                  _logoTile(p),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RAIGON ARTS',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: p.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'PHOTO FRAMES',
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.4,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggle,
                    icon: Icon(Icons.menu, color: p.textPrimary, size: 22),
                  ),
                ],
              ),
            )
          : Center(
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(12),
                child: _logoTile(p),
              ),
            ),
    );
  }

  Widget _item({
    required AppPalette p,
    required String label,
    required IconData icon,
    required bool active,
    required bool showLabels,
    required VoidCallback onTap,
    Color? color,
  }) {
    final fg = active ? Colors.white : (color ?? p.navText);
    final tile = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: active
            ? BoxDecoration(
                gradient: AppColors.darkGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 50,
            child: showLabels
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(icon, size: 22, color: fg),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w500,
                              color: fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(child: Icon(icon, size: 22, color: fg)),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: showLabels ? tile : Tooltip(message: label, child: tile),
    );
  }
}
