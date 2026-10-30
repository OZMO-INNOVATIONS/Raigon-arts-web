import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/notification_model.dart';
import 'package:raigon_art/features/customers/service/customer_whatsapp_service.dart';

enum _Filter { all, completed, dues }

class NotificationPanel extends StatefulWidget {
  const NotificationPanel({
    super.key,
    required this.onClose,
    required this.onViewDetails,
    required this.onViewAll,
    this.onSelectNotification,
    this.notifications = const [],
  });

  final VoidCallback onClose;
  final VoidCallback onViewDetails;
  final VoidCallback onViewAll;
  final void Function(NotificationItem item)? onSelectNotification;
  final List<NotificationItem> notifications;

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  _Filter _filter = _Filter.all;

  int _count(NotificationType t) =>
      widget.notifications.where((n) => n.type == t).length;

  List<NotificationItem> get _items => switch (_filter) {
    _Filter.all => widget.notifications,
    _Filter.completed =>
      widget.notifications
          .where((n) => n.type == NotificationType.completed)
          .toList(),
    _Filter.dues =>
      widget.notifications
          .where((n) => n.type == NotificationType.due)
          .toList(),
  };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final width = MediaQuery.of(context).size.width;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width < 420 ? width - 32 : 390,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: p.isDark ? 0.45 : 0.14),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Action Notifications',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: p.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.notifications.length} Active',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.statusGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: widget.onClose,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: p.border),
                          ),
                          child: Icon(
                            RemixIcons.close_line,
                            size: 17,
                            color: p.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _chip(
                        p,
                        _Filter.all,
                        'All (${widget.notifications.length})',
                        null,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        p,
                        _Filter.completed,
                        'Completed (${_count(NotificationType.completed)})',
                        RemixIcons.checkbox_circle_line,
                      ),
                      const SizedBox(width: 8),
                      _chip(
                        p,
                        _Filter.dues,
                        'Dues (${_count(NotificationType.due)})',
                        RemixIcons.error_warning_line,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: (MediaQuery.of(context).size.height - 280).clamp(
                  160,
                  400,
                ),
              ),
              child: _items.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            RemixIcons.notification_line,
                            size: 40,
                            color: p.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: p.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All order actions and dues are up to date.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: p.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _itemCard(p, _items[i]),
                    ),
            ),
            InkWell(
              onTap: widget.onViewAll,
              child: Container(
                width: double.infinity,
                color: p.panelFooterBg,
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View All Workshop Orders',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      RemixIcons.arrow_right_line,
                      size: 18,
                      color: p.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(AppPalette p, _Filter f, String label, IconData? icon) {
    final selected = _filter == f;
    final fg = selected ? Colors.white : p.textPrimary;
    return InkWell(
      onTap: () => setState(() => _filter = f),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.darkGradient : null,
          color: selected ? null : p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.black : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(AppPalette p, NotificationItem n) {
    final isDue = n.type == NotificationType.due;
    final accent = isDue ? AppPalette.orange : AppColors.green;
    final cardBorder = isDue
        ? AppPalette.orange.withValues(alpha: p.isDark ? 0.35 : 0.45)
        : AppColors.green.withValues(alpha: p.isDark ? 0.35 : 0.45);
    final cardBg = isDue
        ? (p.isDark ? const Color(0xFF332626) : const Color(0xFFFFF9F5))
        : (p.isDark ? const Color(0xFF223328) : const Color(0xFFF6FCF7));

    void handleView() {
      if (widget.onSelectNotification != null) {
        widget.onSelectNotification!(n);
      } else {
        widget.onViewDetails();
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: handleView,
          borderRadius: BorderRadius.circular(16),
          hoverColor: accent.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    isDue
                        ? RemixIcons.error_warning_fill
                        : RemixIcons.checkbox_circle_fill,
                    size: 24,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              n.tag,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.message,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: p.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            RemixIcons.time_line,
                            size: 13,
                            color: p.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              n.meta,
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          InkWell(
                            onTap: handleView,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.darkGradient,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    RemixIcons.eye_line,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'View Full Profile',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (n.phone.isNotEmpty)
                            InkWell(
                              onTap: () async {
                                if (n.customer != null) {
                                  if (isDue) {
                                    await CustomerWhatsAppService.openPaymentReminder(
                                      n.customer!,
                                    );
                                  } else {
                                    await CustomerWhatsAppService.openOrderConfirmation(
                                      n.customer!,
                                    );
                                  }
                                } else {
                                  CustomerWhatsAppService.openDirectChat(
                                    n.phone,
                                    'Hello! Regarding your RAIGON ART framing order: ${n.message}',
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.green.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      RemixIcons.whatsapp_fill,
                                      size: 15,
                                      color: AppColors.green,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isDue ? 'Remind' : 'WhatsApp',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
