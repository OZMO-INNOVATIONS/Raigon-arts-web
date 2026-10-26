import 'channel.dart';
import 'trigger_type.dart';

class Automation {
  Automation({
    required this.id,
    required this.name,
    required this.channel,
    required this.trigger,
    required this.keywords,
    required this.message,
    this.linkLabel = '',
    this.linkUrl = '',
    this.live = true,
    this.runs = 0,
  });

  String id, name, message, linkLabel, linkUrl; 
  Channel channel;
  TriggerType trigger;
  List<String> keywords;
  bool live;
  int runs;

  bool matches(String text) {
    final t = text.toLowerCase();
    switch (trigger) {
      case TriggerType.anyMessage:
      case TriggerType.storyReply:
        return true;
      case TriggerType.postComment:
        return keywords.isEmpty || keywords.any((k) => t.contains(k.toLowerCase()));
      case TriggerType.keyword:
        return keywords.any((k) => t.contains(k.toLowerCase()));
    }
  }

  String get summary {
    final k = keywords.isEmpty ? '' : ' “${keywords.join(', ')}”';
    return switch (trigger) {
      TriggerType.keyword => 'When someone messages$k',
      TriggerType.anyMessage => 'When someone sends any message',
      TriggerType.postComment => 'When someone comments${k.isEmpty ? '' : ' with$k'}',
      TriggerType.storyReply => 'When someone replies to your story',
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'channel': channel.name,
        'trigger': trigger.name,
        'keywords': keywords,
        'message': message,
        'linkLabel': linkLabel,
        'linkUrl': linkUrl,
        'live': live,
        'runs': runs,
      };

  factory Automation.fromJson(Map<String, dynamic> j) => Automation(
        id: j['id'],
        name: j['name'],
        channel: Channel.values.byName(j['channel']),
        trigger: TriggerType.values.byName(j['trigger']),
        keywords: List<String>.from(j['keywords'] ?? []),
        message: j['message'] ?? '',
        linkLabel: j['linkLabel'] ?? '',
        linkUrl: j['linkUrl'] ?? '',
        live: j['live'] ?? true,
        runs: j['runs'] ?? 0,
      );
}
