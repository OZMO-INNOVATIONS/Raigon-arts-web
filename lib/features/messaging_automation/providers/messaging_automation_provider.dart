import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

enum AutomationChannel { instagram, whatsapp }

extension AutomationChannelX on AutomationChannel {
  String get label =>
      this == AutomationChannel.instagram ? 'Instagram' : 'WhatsApp';
}

enum AutomationStage { channelSelect, connect, firstMove, builder, dashboard }

enum AutomationTrigger { dmKeyword, commentLink, welcome }

enum DashboardTab { automations, inbox, flow, activity }

enum DraftOption { followUp, askEmail, businessHours, humanHandover }

enum NodeType { trigger, condition, message }

class AutomationFlow {
  AutomationFlow({
    required this.id,
    required this.name,
    required this.channel,
    required this.trigger,
    required this.keywords,
    required this.message,
    this.linkLabel,
    this.linkUrl,
    this.active = true,
    this.runs = 0,
  });

  final String id;
  final String name;
  final AutomationChannel channel;
  final AutomationTrigger trigger;
  final List<String> keywords;
  final String message;
  final String? linkLabel;
  final String? linkUrl;
  bool active;
  int runs;
}

class ActivityLog {
  ActivityLog({
    required this.flowName,
    required this.contact,
    required this.detail,
    this.success = true,
    this.isTest = false,
  }) : time = DateTime.now();

  final DateTime time;
  final String flowName;
  final String contact;
  final String detail;
  final bool success;
  final bool isTest;
}

class InboxThread {
  const InboxThread(this.name, this.incoming, this.reply, this.age);
  final String name;
  final String incoming;
  final String reply;
  final String age;
}

class FlowNode {
  FlowNode({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.position,
  });

  final String id;
  final NodeType type;
  String title;
  String subtitle;
  Offset position;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'subtitle': subtitle,
    'x': position.dx,
    'y': position.dy,
  };
}

class FlowEdge {
  const FlowEdge(this.from, this.to);
  final String from;
  final String to;
  Map<String, dynamic> toJson() => {'from': from, 'to': to};
}

class MessagingAutomationProvider extends ChangeNotifier {
  // ───────────── navigation ─────────────
  AutomationStage stage = AutomationStage.channelSelect;
  AutomationChannel channel = AutomationChannel.instagram;
  DashboardTab tab = DashboardTab.automations;

  // ───────────── channel connection ─────────────
  bool connecting = false;
  bool connected = false;
  String accountName = 'raigonart';

  void selectChannel(AutomationChannel c) {
    channel = c;
    connected = false;
    stage = AutomationStage.connect;
    notifyListeners();
  }

  void backToChannels() {
    stage = AutomationStage.channelSelect;
    notifyListeners();
  }

  Future<void> restoreInstagramConnection() async {
    if (connecting) return;

    connecting = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      if (session == null) {
        connected = false;
        stage = AutomationStage.channelSelect;
        return;
      }

      final response = await supabase.functions.invoke(
        'instagram-oauth',
        method: HttpMethod.get,
        queryParameters: {'action': 'status'},
      );

      final data = response.data;

      if (response.status < 200 || response.status >= 300 || data is! Map) {
        throw Exception('Could not restore Instagram connection.');
      }

      final accounts = data['accounts'];

      if (data['connected'] == true &&
          accounts is List &&
          accounts.isNotEmpty &&
          accounts.first is Map) {
        final account = accounts.first as Map;

        channel = AutomationChannel.instagram;
        accountName = account['username']?.toString() ?? 'Instagram';
        connected = true;
        tab = DashboardTab.automations;
        stage = AutomationStage.dashboard;
      } else {
        connected = false;
        stage = AutomationStage.channelSelect;
      }
    } catch (error) {
      debugPrint('Could not restore Instagram connection: $error');
      connected = false;
      stage = AutomationStage.channelSelect;
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  /// Simulated connect. Replace body with real OAuth / Cloud API call later.
  Future<void> connect() async {
    if (connecting) return;

    // Keep the existing WhatsApp behavior unchanged for now.
    if (channel == AutomationChannel.whatsapp) {
      connecting = true;
      notifyListeners();

      try {
        await Future.delayed(const Duration(seconds: 1));
        connected = true;
        stage = AutomationStage.firstMove;
      } finally {
        connecting = false;
        notifyListeners();
      }
      return;
    }

    connecting = true;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;

      if (supabase.auth.currentSession == null) {
        throw Exception('Please sign in before connecting Instagram.');
      }

      final response = await supabase.functions.invoke(
        'instagram-oauth',
        body: {'action': 'start'},
      );

      final data = response.data;
      debugPrint('Instagram OAuth response: ${response.data}');

      if (response.status < 200 ||
          response.status >= 300 ||
          data is! Map ||
          data['authorization_url'] is! String) {
        throw Exception(
          data is Map
              ? '${data['error'] ?? 'Could not start Instagram authorization.'}'
              : 'Invalid response from Instagram OAuth.',
        );
      }

      final uri = Uri.tryParse(data['authorization_url'] as String);

      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'www.instagram.com') {
        throw Exception('The Instagram authorization URL is invalid.');
      }

      final opened = await launchUrl(uri, webOnlyWindowName: '_self');

      if (!opened) {
        throw Exception('Could not open Instagram authorization.');
      }
    } catch (_) {
      rethrow;
    } finally {
      connecting = false;
      notifyListeners();
    }
  }

  void skipToDashboard() {
    stage = AutomationStage.dashboard;
    notifyListeners();
  }

  void setTab(DashboardTab t) {
    tab = t;
    notifyListeners();
  }

  void handleInstagramConnected(String username) {
    channel = AutomationChannel.instagram;
    accountName = username.isNotEmpty ? username : 'Instagram';
    connected = true;
    stage = AutomationStage.dashboard;
    tab = DashboardTab.automations;
    notifyListeners();
  }

  // ───────────── draft automation ─────────────
  AutomationTrigger draftTrigger = AutomationTrigger.dmKeyword;
  String draftKeywords = '';
  String draftMessage = '';
  String? draftLinkLabel;
  String? draftLinkUrl;
  bool draftAnyPost = true;
  final Set<DraftOption> draftOptions = {};

  List<String> get draftKeywordList => draftKeywords
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool get canGoLive =>
      draftMessage.trim().isNotEmpty &&
      (draftTrigger == AutomationTrigger.welcome ||
          draftKeywordList.isNotEmpty);

  void _resetDraft(AutomationTrigger t) {
    draftTrigger = t;
    draftKeywords = '';
    draftMessage = '';
    draftLinkLabel = null;
    draftLinkUrl = null;
    draftAnyPost = true;
    draftOptions.clear();
  }

  void startBuilder(AutomationTrigger t) {
    _resetDraft(t);
    stage = AutomationStage.builder;
    notifyListeners();
  }

  void closeBuilder() {
    stage = AutomationStage.dashboard;
    notifyListeners();
  }

  void setKeywords(String v) {
    draftKeywords = v;
    notifyListeners();
  }

  void setMessage(String v) {
    draftMessage = v;
    notifyListeners();
  }

  void setLink(String? label, String? url) {
    draftLinkLabel = label;
    draftLinkUrl = url;
    notifyListeners();
  }

  void setAnyPost(bool v) {
    draftAnyPost = v;
    notifyListeners();
  }

  void toggleOption(DraftOption o, bool on) {
    on ? draftOptions.add(o) : draftOptions.remove(o);
    notifyListeners();
  }

  void goLive() {
    if (!canGoLive) return;
    final kws = draftKeywordList;
    final name = switch (draftTrigger) {
      AutomationTrigger.welcome => 'Welcome message',
      AutomationTrigger.commentLink => 'Comment → "${kws.first}"',
      AutomationTrigger.dmKeyword => 'DM → "${kws.first}"',
    };
    flows.insert(
      0,
      AutomationFlow(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        channel: channel,
        trigger: draftTrigger,
        keywords: kws,
        message: draftMessage.trim(),
        linkLabel: draftLinkLabel,
        linkUrl: draftLinkUrl,
      ),
    );
    logs.insert(
      0,
      ActivityLog(
        flowName: name,
        contact: 'You',
        detail: 'Automation went live',
      ),
    );
    tab = DashboardTab.automations;
    stage = AutomationStage.dashboard;
    notifyListeners();
  }

  // ───────────── flows & activity ─────────────
  final List<AutomationFlow> flows = [];
  final List<ActivityLog> logs = [];

  int get totalRuns => flows.fold(0, (a, f) => a + f.runs);
  int get activeCount => flows.where((f) => f.active).length;
  double get successRate {
    final real = logs.where((l) => !l.isTest && l.contact != 'You').toList();
    if (real.isEmpty) return 100;
    return real.where((l) => l.success).length / real.length * 100;
  }

  void toggleFlow(AutomationFlow f, bool on) {
    f.active = on;
    logs.insert(
      0,
      ActivityLog(
        flowName: f.name,
        contact: 'You',
        detail: on ? 'Resumed' : 'Paused',
      ),
    );
    notifyListeners();
  }

  void deleteFlow(AutomationFlow f) {
    flows.remove(f);
    notifyListeners();
  }

  void testFlow(AutomationFlow f) {
    f.runs++;
    logs.insert(
      0,
      ActivityLog(
        flowName: f.name,
        contact: 'Test contact',
        detail: 'Reply sent: ${f.message}',
        isTest: true,
      ),
    );
    notifyListeners();
  }

  // ───────────── inbox ─────────────
  final List<InboxThread> threads = [];
  InboxThread? selectedThread;

  void selectThread(InboxThread? t) {
    selectedThread = t;
    notifyListeners();
  }

  // ───────────── visual flow builder ─────────────
  late List<FlowNode> nodes = _defaultNodes();
  late List<FlowEdge> edges = _defaultEdges();
  String? pendingFrom;
  DateTime? flowSavedAt;

  List<FlowNode> _defaultNodes() => [
    FlowNode(
      id: 'n1',
      type: NodeType.trigger,
      title: 'Trigger',
      subtitle: 'DM received',
      position: const Offset(40, 170),
    ),
    FlowNode(
      id: 'n2',
      type: NodeType.condition,
      title: 'Condition',
      subtitle: 'Keyword matches',
      position: const Offset(360, 170),
    ),
    FlowNode(
      id: 'n3',
      type: NodeType.message,
      title: 'Send message',
      subtitle: 'Reply with link',
      position: const Offset(680, 170),
    ),
  ];

  List<FlowEdge> _defaultEdges() => const [
    FlowEdge('n1', 'n2'),
    FlowEdge('n2', 'n3'),
  ];

  FlowNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  void moveNode(String id, Offset delta) {
    final n = nodeById(id);
    if (n == null) return;
    n.position = Offset(
      (n.position.dx + delta.dx).clamp(0.0, 1000.0),
      (n.position.dy + delta.dy).clamp(0.0, 360.0),
    );
    notifyListeners();
  }

  void addNode(NodeType t) {
    final i = nodes.length;
    nodes.add(
      FlowNode(
        id: 'n${DateTime.now().microsecondsSinceEpoch}',
        type: t,
        title: t == NodeType.condition ? 'Condition' : 'Send message',
        subtitle: t == NodeType.condition ? 'Add a rule' : 'Write a reply',
        position: Offset(60.0 + (i % 4) * 40, 40.0 + (i % 3) * 30),
      ),
    );
    notifyListeners();
  }

  void removeNode(String id) {
    nodes.removeWhere((n) => n.id == id);
    edges = edges.where((e) => e.from != id && e.to != id).toList();
    notifyListeners();
  }

  void editNode(String id, String title, String subtitle) {
    final n = nodeById(id);
    if (n == null) return;
    n.title = title;
    n.subtitle = subtitle;
    notifyListeners();
  }

  /// Tap an output port, then an input port to connect.
  void tapOutput(String id) {
    pendingFrom = pendingFrom == id ? null : id;
    notifyListeners();
  }

  void tapInput(String id) {
    final from = pendingFrom;
    if (from == null || from == id) return;
    if (!edges.any((e) => e.from == from && e.to == id)) {
      edges = [...edges, FlowEdge(from, id)];
    }
    pendingFrom = null;
    notifyListeners();
  }

  void removeEdge(FlowEdge e) {
    edges = edges.where((x) => x != e).toList();
    notifyListeners();
  }

  void resetFlow() {
    nodes = _defaultNodes();
    edges = _defaultEdges();
    pendingFrom = null;
    notifyListeners();
  }

  /// In-memory for now. Persist `flowJson` with shared_preferences / Hive next.
  Map<String, dynamic> get flowJson => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };

  void saveFlow() {
    flowSavedAt = DateTime.now();
    notifyListeners();
  }
}
