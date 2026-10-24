import 'package:flutter/material.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/providers/rule_builder_provider.dart';
import 'package:raigon_art/features/messaging_automation/shared/widgets/auto_text_field.dart';

Future<void> showLinkDialog(BuildContext context, RuleBuilderProvider b) async {
  final label = TextEditingController(text: b.linkLabel ?? '');
  final url = TextEditingController(text: b.linkUrl ?? 'https://');
  String? error;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Add a link'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoTextField(
                controller: label,
                label: 'Button label',
                hint: 'e.g. Shop frames',
                prefixIcon: Icons.label_outline_rounded,
              ),
              const SizedBox(height: 12),
              AutoTextField(
                controller: url,
                label: 'URL',
                prefixIcon: Icons.link_rounded,
                keyboardType: TextInputType.url,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final l = label.text.trim();
              final u = url.text.trim();
              if (l.isEmpty) {
                setState(() => error = 'Give the button a label.');
              } else if (!(u.startsWith('http://') || u.startsWith('https://')) ||
                  u.length < 12) {
                setState(() => error = 'Enter a valid http(s) URL.');
              } else {
                b.setLink(l, u);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );

  label.dispose();
  url.dispose();
}
