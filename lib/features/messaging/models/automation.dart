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

    // Creator and updater details
    this.createdBy,
    this.createdByRole,
    this.updatedBy,
    this.updatedByRole,
    this.createdAt,
    this.updatedAt,
  });

  String id, name, message, linkLabel, linkUrl;
  Channel channel;
  TriggerType trigger;
  List<String> keywords;
  bool live;
  int runs;

  // Creator and updater details
  String? createdBy;
  String? createdByRole;
  String? updatedBy;
  String? updatedByRole;
  DateTime? createdAt;
  DateTime? updatedAt;

  bool matches(String text) {
    final t = text.toLowerCase();

    switch (trigger) {
      case TriggerType.anyMessage:
      case TriggerType.storyReply:
        return true;
      case TriggerType.postComment:
        return keywords.isEmpty ||
            keywords.any((k) => t.contains(k.toLowerCase()));
      case TriggerType.keyword:
        return keywords.any((k) => t.contains(k.toLowerCase()));
    }
  }

  String get summary {
    final k = keywords.isEmpty ? '' : ' “${keywords.join(', ')}”';

    return switch (trigger) {
      TriggerType.keyword => 'When someone messages$k',
      TriggerType.anyMessage => 'When someone sends any message',
      TriggerType.postComment =>
        'When someone comments${k.isEmpty ? '' : ' with$k'}',
      TriggerType.storyReply => 'When someone replies to your story',
    };
  }

  // Existing local JSON serialization - unchanged
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

  // Supabase database serialization
  Map<String, dynamic> toDatabaseJson() => {
    'id': id,
    'name': name,
    'channel': channel.name,
    'trigger_type': _databaseTrigger,
    'keywords': keywords,
    'reply_message': message,
    'is_active': live,
    'created_by': createdBy,
    'created_by_role': createdByRole,
    'updated_by': updatedBy,
    'updated_by_role': updatedByRole,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  String get _databaseTrigger => switch (trigger) {
    TriggerType.keyword => 'keyword',
    TriggerType.anyMessage => 'anyMessage',
    TriggerType.postComment => 'postComment',
    TriggerType.storyReply => 'storyReply',
  };

  factory Automation.fromDatabaseJson(Map<String, dynamic> j) {
    final triggerValue = j['trigger_type'] as String? ?? 'keyword';

    return Automation(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      channel: Channel.values.byName(j['channel']?.toString() ?? 'instagram'),
      trigger: TriggerType.values.byName(triggerValue),
      keywords: List<String>.from(j['keywords'] ?? []),
      message: j['reply_message']?.toString() ?? '',
      live: j['is_active'] == true,

      createdBy: j['created_by']?.toString(),
      createdByRole: j['created_by_role']?.toString(),
      updatedBy: j['updated_by']?.toString(),
      updatedByRole: j['updated_by_role']?.toString(),

      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'].toString())
          : null,
    );
  }

  String get createdByLabel {
    final role = createdByRole?.trim().toLowerCase();

    if (role == 'admin') return 'Admin';
    if (role == 'staff') return 'Staff';

    return 'Unknown';
  }

  String get updatedByLabel {
    final role = updatedByRole?.trim().toLowerCase();

    if (role == 'admin') return 'Admin';
    if (role == 'staff') return 'Staff';

    return 'Unknown';
  }
}
