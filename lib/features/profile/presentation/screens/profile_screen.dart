import 'package:flutter/material.dart';
import 'package:raigon_art/core/constants/asset_constants.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/features/profile/services/workshop_settings_service.dart';
import 'package:remixicon/remixicon.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _businessName = 'RAIGON ART';
  String _tagline = 'Photo Frames & Custom Framing';
  String _businessPhone = '97470 99559';
  String _businessEmail = 'theraigonart@gmail.com';
  String _workshopAddress =
      'VP 302-A, R J Building, Kollamkonam Junction, Vilappilsala, Thiruvananthapuram, Kerala 695573';
  String _gstin = '32AAAAA0000A1Z5';
  int _retentionDays = 45;
  bool _autoCleanup = true;

  static const String _businessType = 'Photo Frames & Framing Workshop';
  static const String _specialization = 'Custom & Ready-made Frames';
  static const String _materials = 'Wood, Metal, Acrylic, Glass';
  static const String _orderTypes = 'Walk-in & Custom Orders';

  static const List<String> _tags = [
    'Custom Framing',
    'Ready-made Frames',
    'Wall Décor',
  ];

  static const List<_Service> _services = [
    _Service(
      icon: RemixIcons.aspect_ratio_line,
      title: 'Custom Photo Framing',
      desc: 'Frames made to your photo size, style and finish.',
    ),
    _Service(
      icon: RemixIcons.crop_line,
      title: 'Ready-made Frames',
      desc: 'Standard sizes available for instant pickup.',
    ),
    _Service(
      icon: RemixIcons.palette_line,
      title: 'Canvas & Wall Art',
      desc: 'Canvas stretching, art framing and wall décor pieces.',
    ),
    _Service(
      icon: RemixIcons.medal_line,
      title: 'Certificate Framing',
      desc: 'Certificates, documents and awards framed neatly.',
    ),
    _Service(
      icon: RemixIcons.printer_line,
      title: 'Photo Printing',
      desc: 'Photo prints and enlargements ready for framing.',
    ),
    _Service(
      icon: RemixIcons.tools_line,
      title: 'Repair & Restoration',
      desc: 'Frame repair, glass replacement and re-mounting.',
    ),
  ];

  static const List<_Hours> _hours = [
    _Hours(1, 'Monday', '9:30 AM – 8:00 PM'),
    _Hours(2, 'Tuesday', '9:30 AM – 8:00 PM'),
    _Hours(3, 'Wednesday', '9:30 AM – 8:00 PM'),
    _Hours(4, 'Thursday', '9:30 AM – 8:00 PM'),
    _Hours(5, 'Friday', '9:30 AM – 8:00 PM'),
    _Hours(6, 'Saturday', '9:30 AM – 8:00 PM'),
    _Hours(7, 'Sunday', 'Closed', closed: true),
  ];

  static const List<_Step> _steps = [
    _Step('Choose', 'Pick frame style, colour and glass type.'),
    _Step('Measure', 'Photo size and mount are confirmed.'),
    _Step('Craft', 'Frame is cut, assembled and finished.'),
    _Step('Deliver', 'Ready for pickup or delivery.'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final service = WorkshopSettingsService();
      final results = await Future.wait([
        service.getProfile().catchError(
          (_) => const WorkshopProfile(
            businessName: 'RAIGON ART',
            tagline: 'Photo Frames & Custom Framing',
            businessPhone: '97470 99559',
            businessEmail: 'theraigonart@gmail.com',
            workshopAddress:
                'VP 302-A, R J Building, Kollamkonam Junction, Vilappilsala, Thiruvananthapuram, Kerala 695573',
            gstin: '',
            businessHours: [],
          ),
        ),
        service.getRetentionPolicy().catchError(
          (_) => const RetentionPolicy(
            retentionDays: 45,
            autoCleanupEnabled: true,
            retentionTarget: 'all',
          ),
        ),
      ]);

      if (mounted) {
        final profile = results[0] as WorkshopProfile;
        final retention = results[1] as RetentionPolicy;
        setState(() {
          _businessName = profile.businessName;
          _tagline = profile.tagline;
          _businessPhone = profile.businessPhone;
          _businessEmail = profile.businessEmail;
          if (profile.workshopAddress.isNotEmpty) {
            _workshopAddress = profile.workshopAddress;
          }
          _gstin = profile.gstin.isNotEmpty ? profile.gstin : 'Not registered';
          _retentionDays = retention.retentionDays;
          _autoCleanup = retention.autoCleanupEnabled;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(p),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: p.card(radius: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _heroCard(p),
                          const SizedBox(height: 20),
                          _twoColumn(
                            _infoCard(
                              p,
                              title: 'CONTACT',
                              rows: [
                                _InfoItem(
                                  icon: RemixIcons.phone_line,
                                  label: 'Phone',
                                  value: _businessPhone,
                                ),
                                _InfoItem(
                                  icon: RemixIcons.mail_line,
                                  label: 'Email',
                                  value: _businessEmail,
                                ),
                              ],
                            ),
                            _infoCard(
                              p,
                              title: 'LOCATION',
                              rows: [
                                _InfoItem(
                                  icon: RemixIcons.map_pin_line,
                                  label: 'Workshop Address',
                                  value: _workshopAddress,
                                ),
                                const _InfoItem(
                                  icon: RemixIcons.building_line,
                                  label: 'City & State',
                                  value: 'Thiruvananthapuram, Kerala',
                                ),
                                const _InfoItem(
                                  icon: RemixIcons.mail_send_line,
                                  label: 'PIN Code',
                                  value: '695573',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _servicesCard(p),
                          const SizedBox(height: 20),
                          _twoColumn(
                            _hoursCard(p),
                            _infoCard(
                              p,
                              title: 'BUSINESS DETAILS',
                              rows: [
                                const _InfoItem(
                                  icon: RemixIcons.store_2_line,
                                  label: 'Business Type',
                                  value: _businessType,
                                ),
                                const _InfoItem(
                                  icon: RemixIcons.star_line,
                                  label: 'Specialization',
                                  value: _specialization,
                                ),
                                const _InfoItem(
                                  icon: RemixIcons.stack_line,
                                  label: 'Frame Materials',
                                  value: _materials,
                                ),
                                const _InfoItem(
                                  icon: RemixIcons.shopping_bag_line,
                                  label: 'Order Types',
                                  value: _orderTypes,
                                ),
                                _InfoItem(
                                  icon: RemixIcons.bill_line,
                                  label: 'GSTIN',
                                  value: _gstin,
                                ),
                                _InfoItem(
                                  icon: RemixIcons.cloud_line,
                                  label: 'Photo Vault Retention',
                                  value:
                                      '$_retentionDays Days (${_autoCleanup ? "Auto Cleanup" : "Manual"})',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _processCard(p),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: p.border, height: 1),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          RemixIcons.magic_line,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Powered by RAIGON ART',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _twoColumn(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 20), right],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: 20),
              Expanded(child: right),
            ],
          ),
        );
      },
    );
  }

  Widget _grid(
    double maxWidth,
    int columns,
    List<Widget> children, {
    double gap = 14,
  }) {
    final w = (maxWidth - gap * (columns - 1)) / columns;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [for (final c in children) SizedBox(width: w, child: c)],
    );
  }

  Widget _cardShell(AppPalette p, String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: p.card(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _iconBox(AppPalette p, IconData icon, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: p.isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: size / 2, color: AppColors.gold),
    );
  }

  Widget _title(AppPalette p) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Business Profile',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your shop details as shown on orders and receipts',
                style: TextStyle(fontSize: 14.5, color: p.textMuted),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold,
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: _openEditProfileDialog,
          icon: const Icon(RemixIcons.edit_line, size: 16),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.black,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dialogInputDec(AppPalette p, String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 13, color: p.textMuted),
      hintStyle: TextStyle(fontSize: 13, color: p.textMuted.withValues(alpha: 0.6)),
      filled: true,
      fillColor: p.isDark ? const Color(0xFF26283C) : const Color(0xFFF7F6F2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
      ),
    );
  }

  Future<void> _openEditProfileDialog() async {
    final p = AppPalette.of(context);
    final nameCtrl = TextEditingController(text: _businessName);
    final taglineCtrl = TextEditingController(text: _tagline);
    final phoneCtrl = TextEditingController(text: _businessPhone);
    final emailCtrl = TextEditingController(text: _businessEmail);
    final addressCtrl = TextEditingController(text: _workshopAddress);
    final gstinCtrl = TextEditingController(
      text: _gstin == 'Not registered' ? '' : _gstin,
    );
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogContentCtx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              RemixIcons.store_2_line,
                              color: AppColors.gold,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Business Profile',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: p.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Update workshop contact info and settings in API',
                                  style: TextStyle(fontSize: 12, color: p.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: p.textMuted,
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(height: 1, color: p.border),
                      const SizedBox(height: 18),

                      // Business Name & Tagline
                      TextFormField(
                        controller: nameCtrl,
                        style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                        decoration: _dialogInputDec(p, 'Business Name', hint: 'e.g. RAIGON ART'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: taglineCtrl,
                        style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                        decoration: _dialogInputDec(p, 'Tagline', hint: 'e.g. Photo Frames & Custom Framing'),
                      ),
                      const SizedBox(height: 14),

                      // Phone & Email
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: phoneCtrl,
                              style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                              decoration: _dialogInputDec(p, 'Business Phone', hint: 'e.g. 97470 99559'),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: emailCtrl,
                              style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                              decoration: _dialogInputDec(p, 'Business Email', hint: 'e.g. theraigonart@gmail.com'),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (!v.contains('@')) return 'Enter valid email';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Workshop Address
                      TextFormField(
                        controller: addressCtrl,
                        maxLines: 2,
                        style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                        decoration: _dialogInputDec(p, 'Workshop Address', hint: 'Full workshop street address'),
                      ),
                      const SizedBox(height: 14),

                      // GSTIN
                      TextFormField(
                        controller: gstinCtrl,
                        style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                        decoration: _dialogInputDec(p, 'GSTIN / Tax ID (Optional)', hint: 'e.g. 32AAAAA0000A1Z5'),
                      ),
                      const SizedBox(height: 22),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                side: BorderSide(color: p.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: p.textMuted, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDialogState(() => isSaving = true);
                                      try {
                                        final service = WorkshopSettingsService();
                                        final updated = await service.updateProfile({
                                          'businessName': nameCtrl.text.trim(),
                                          'tagline': taglineCtrl.text.trim(),
                                          'businessPhone': phoneCtrl.text.trim(),
                                          'businessEmail': emailCtrl.text.trim(),
                                          'workshopAddress': addressCtrl.text.trim(),
                                          'gstin': gstinCtrl.text.trim(),
                                        });

                                        if (!mounted) return;
                                        setState(() {
                                          _businessName = updated.businessName;
                                          _tagline = updated.tagline;
                                          _businessPhone = updated.businessPhone;
                                          _businessEmail = updated.businessEmail;
                                          if (updated.workshopAddress.isNotEmpty) {
                                            _workshopAddress = updated.workshopAddress;
                                          }
                                          _gstin = updated.gstin.isNotEmpty ? updated.gstin : 'Not registered';
                                        });

                                        if (dialogCtx.mounted) {
                                          Navigator.of(dialogCtx).pop();
                                        }

                                        if (!mounted) return;
                                        AppSnackBar.success(
                                          context,
                                          'Business profile updated in API.',
                                        );
                                      } catch (e) {
                                        if (dialogContentCtx.mounted) {
                                          setDialogState(() => isSaving = false);
                                        }
                                        if (!mounted) return;
                                        AppSnackBar.error(
                                          context,
                                          'Failed to update profile: $e',
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.black,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.black,
                                      ),
                                    )
                                  : const Text(
                                      'Save Changes',
                                      style: TextStyle(fontWeight: FontWeight.w800),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroCard(AppPalette p) {
    final chipFg = p.isDark ? AppColors.gold : AppPalette.statusGold;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: p.card(radius: 16),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: p.avatarBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(AssetConstants.raigonLogo, fit: BoxFit.cover),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _businessName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tagline,
                  style: TextStyle(fontSize: 14.5, color: p.textMuted),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(
                            alpha: p.isDark ? 0.25 : 0.14,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: chipFg,
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
    );
  }

  Widget _infoCard(
    AppPalette p, {
    required String title,
    required List<_InfoItem> rows,
  }) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(Divider(color: p.border, height: 28));
      }
      children.add(_infoRow(p, rows[i]));
    }

    return _cardShell(
      p,
      title,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoRow(AppPalette p, _InfoItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _iconBox(p, item.icon),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: TextStyle(fontSize: 12.5, color: p.textMuted),
              ),
              const SizedBox(height: 3),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _servicesCard(AppPalette p) {
    return _cardShell(
      p,
      'SERVICES WE OFFER',
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth < 560 ? 1 : (c.maxWidth < 960 ? 2 : 3);
          return _grid(c.maxWidth, cols, [
            for (final s in _services) _serviceTile(p, s),
          ]);
        },
      ),
    );
  }

  Widget _serviceTile(AppPalette p, _Service s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.isDark ? p.surface.withValues(alpha: 0.45) : p.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBox(p, s.icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.desc,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hoursCard(AppPalette p) {
    final today = DateTime.now().weekday;
    final rows = <Widget>[];

    for (var i = 0; i < _hours.length; i++) {
      final h = _hours[i];
      final isToday = h.weekday == today;

      if (i > 0) rows.add(const SizedBox(height: 6));

      rows.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.gold.withValues(alpha: p.isDark ? 0.2 : 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                h.day,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: p.textPrimary,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 8),
                Text(
                  'TODAY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: p.isDark ? AppColors.gold : AppPalette.statusGold,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                h.time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: h.closed ? const Color(0xFFE5484D) : p.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _cardShell(
      p,
      'BUSINESS HOURS',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );
  }

  Widget _processCard(AppPalette p) {
    return _cardShell(
      p,
      'HOW A FRAMING ORDER WORKS',
      LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth < 560 ? 1 : (c.maxWidth < 900 ? 2 : 4);
          return _grid(c.maxWidth, cols, [
            for (var i = 0; i < _steps.length; i++)
              _stepTile(p, i + 1, _steps[i]),
          ]);
        },
      ),
    );
  }

  Widget _stepTile(AppPalette p, int number, _Step s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                s.desc,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: p.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _Service {
  const _Service({required this.icon, required this.title, required this.desc});

  final IconData icon;
  final String title;
  final String desc;
}

class _Hours {
  const _Hours(this.weekday, this.day, this.time, {this.closed = false});

  final int weekday;
  final String day;
  final String time;
  final bool closed;
}

class _Step {
  const _Step(this.title, this.desc);

  final String title;
  final String desc;
}
