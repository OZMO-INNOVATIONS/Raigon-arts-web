import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:raigon_art/features/messaging_automation/connection/services/connection_service.dart';
import 'package:raigon_art/features/messaging_automation/models/automation_enums.dart';
import 'package:raigon_art/features/messaging_automation/shared/utils/formatters.dart';

enum ConnectionStep { channelSelect, connect }

class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider({ConnectionService? service})
      : _service = service ?? ConnectionService();

  final ConnectionService _service;

  ConnectionStep step = ConnectionStep.channelSelect;
  AutomationChannel channel = AutomationChannel.instagram;

  bool connected = false;
  bool connecting = false;
  bool restoring = false;

  /// "Look around first" – dashboard without a connected account.
  bool exploring = false;

  /// User asked to change channel while already inside the dashboard.
  bool switching = false;

  String accountName = 'raigonart';
  String? error;

  bool get showAutomation => (connected || exploring) && !switching;

  // ───────────── navigation ─────────────
  void selectChannel(AutomationChannel c) {
    if (c == channel && connected) {
      switching = false;
      notifyListeners();
      return;
    }
    if (c != channel) connected = false;
    channel = c;
    exploring = false;
    error = null;
    step = ConnectionStep.connect;
    notifyListeners();
  }

  void backToChannels() {
    step = ConnectionStep.channelSelect;
    error = null;
    notifyListeners();
  }

  void openChannelPicker() {
    switching = true;
    step = ConnectionStep.channelSelect;
    notifyListeners();
  }

  void beginConnect() {
    switching = true;
    step = ConnectionStep.connect;
    error = null;
    notifyListeners();
  }

  void cancelSwitching() {
    switching = false;
    notifyListeners();
  }

  void exploreFirst() {
    exploring = true;
    switching = false;
    notifyListeners();
  }

  // ───────────── connection ─────────────
  void _markConnected(String username) {
    accountName = username.isNotEmpty ? username : channel.label;
    connected = true;
    exploring = false;
    switching = false;
    error = null;
  }

  /// Called after the OAuth redirect returns to the app.
  void handleInstagramConnected(String username) {
    channel = AutomationChannel.instagram;
    _markConnected(username.isNotEmpty ? username : 'Instagram');
    notifyListeners();
  }

  Future<void> restoreInstagramConnection() async {
    if (restoring || connecting) return;
    restoring = true;
    notifyListeners();
    try {
      final username = await _service.instagramStatus();
      if (username != null) {
        channel = AutomationChannel.instagram;
        _markConnected(username);
      }
    } catch (e) {
      debugPrint('Could not restore Instagram connection: $e');
    } finally {
      restoring = false;
      notifyListeners();
    }
  }

  Future<void> connect() async {
    if (connecting) return;
    connecting = true;
    error = null;
    notifyListeners();

    try {
      if (channel == AutomationChannel.whatsapp) {
        // Simulated until the WhatsApp Cloud API flow is available.
        await Future.delayed(const Duration(seconds: 1));
        _markConnected('Raigon Art');
      } else {
        final existing = await _service.instagramStatus();
        if (existing != null) {
          _markConnected(existing);
        } else {
          final uri = await _service.instagramAuthUri();
          final opened = await launchUrl(uri, webOnlyWindowName: '_self');
          if (!opened) throw Exception('Could not open Instagram authorization.');
        }
      }
    } catch (e) {
      error = cleanError(e);
      debugPrint('Connect failed: $e');
    } finally {
      connecting = false;
      notifyListeners();
    }
  }
}
