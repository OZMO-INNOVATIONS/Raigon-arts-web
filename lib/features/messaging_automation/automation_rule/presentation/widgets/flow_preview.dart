import 'package:flutter/material.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/features/messaging_automation/automation_rule/presentation/widgets/flow_node_tile.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';

/// Read-only Trigger → Condition → Reply diagram.
class FlowPreview extends StatelessWidget {
  const FlowPreview({
    super.key,
    required this.channel,
    required this.trigger,
    required this.keywords,
    this.hasLink = false,
  });

  final AutomationChannel channel;
  final AutomationTrigger trigger;
  final List<String> keywords;
  final bool hasLink;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final noun = channel.messageNoun;

    final nodes = [
      FlowNodeTile(
        icon: Icons.bolt_rounded,
        title: 'Trigger',
        subtitle: switch (trigger) {
          AutomationTrigger.commentLink => 'Comment on a post',
          AutomationTrigger.dmKeyword => '$noun received',
          AutomationTrigger.welcome => 'First message',
        },
        tint: p.tileNeutral,
      ),
      FlowNodeTile(
        icon: Icons.call_split_rounded,
        title: 'Condition',
        subtitle: trigger == AutomationTrigger.welcome
            ? 'Always'
            : (keywords.isEmpty ? 'Keyword matches' : keywords.take(3).join(', ')),
        tint: p.tileOrange,
      ),
      FlowNodeTile(
        icon: Icons.send_rounded,
        title: 'Reply',
        subtitle: hasLink ? '$noun with link' : 'Send $noun',
        tint: p.tileGreen,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final horizontal = c.maxWidth >= 520;
        final arrow = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal ? 6 : 0,
            vertical: horizontal ? 0 : 4,
          ),
          child: Icon(
            horizontal ? Icons.arrow_forward_rounded : Icons.arrow_downward_rounded,
            size: 18,
            color: AppColors.gold,
          ),
        );

        if (horizontal) {
          return Row(
            children: [
              Expanded(child: nodes[0]),
              arrow,
              Expanded(child: nodes[1]),
              arrow,
              Expanded(child: nodes[2]),
            ],
          );
        }
        return Column(
          children: [nodes[0], arrow, nodes[1], arrow, nodes[2]],
        );
      },
    );
  }
}
