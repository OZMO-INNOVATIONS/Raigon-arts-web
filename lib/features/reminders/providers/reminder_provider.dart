import 'package:flutter/foundation.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';
import 'package:raigon_art/features/reminders/services/reminder_service.dart';

class ReminderProvider extends ChangeNotifier {
  ReminderProvider({ReminderService? service})
      : _service = service ?? ReminderService.instance;

  final ReminderService _service;

  List<CustomerReminder> _reminders = [];
  bool _isLoading = false;
  bool _initialized = false;
  String _searchQuery = '';
  ReminderFilter _currentFilter = ReminderFilter.all;

  List<CustomerReminder> get allReminders => List.unmodifiable(_reminders);
  List<CustomerReminder> get reminderList => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String get searchQuery => _searchQuery;
  ReminderFilter get currentFilter => _currentFilter;

  /// Reminders that are active and either due today or overdue.
  int get dueCount => _reminders.where((r) => r.isDueOrOverdue).length;

  /// All uncompleted (active/available) reminders.
  int get activeCount => _reminders.where((r) => !r.isCompleted).length;

  int get todayCount => _reminders.where((r) => r.isDueToday).length;

  int get upcomingCount => _reminders.where((r) => r.isUpcoming).length;

  int get overdueCount => _reminders.where((r) => r.isOverdue).length;

  int get completedCount => _reminders.where((r) => r.isCompleted).length;

  int get allCount => _reminders.length;

  Future<void> init() async {
    if (_initialized || _isLoading) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reminders = await _service.getReminders();
      _initialized = true;
    } catch (e) {
      debugPrint('[ReminderProvider] Load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(ReminderFilter filter) {
    if (_currentFilter == filter) return;
    _currentFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  List<CustomerReminder> get filteredReminders {
    final q = _searchQuery.trim().toLowerCase();

    final byFilter = _reminders.where((r) {
      return switch (_currentFilter) {
        ReminderFilter.all => true,
        ReminderFilter.today => r.isDueToday,
        ReminderFilter.upcoming => r.isUpcoming,
        ReminderFilter.overdue => r.isOverdue,
        ReminderFilter.completed => r.isCompleted,
      };
    }).toList();

    final result = byFilter.where((r) {
      if (q.isEmpty) return true;
      return r.title.toLowerCase().contains(q) ||
          r.customerName.toLowerCase().contains(q) ||
          r.customerId.toLowerCase().contains(q) ||
          r.orderId.toLowerCase().contains(q) ||
          r.assignedStaff.toLowerCase().contains(q) ||
          r.phone.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
    }).toList();

    // Sort: Overdue/Today first, then upcoming, then completed; within tier by date
    result.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1;
      }
      if (a.isDueToday != b.isDueToday) {
        return a.isDueToday ? -1 : 1;
      }
      return a.reminderDate.compareTo(b.reminderDate);
    });

    return result;
  }

  Future<void> createReminder({
    required String title,
    required String customerName,
    String customerId = '',
    String orderId = '',
    String description = '',
    required DateTime reminderDate,
    String reminderTime = '10:00 AM',
    String assignedStaff = 'Admin',
    ReminderPriority priority = ReminderPriority.medium,
    required String createdBy,
    String phone = '',
    String region = '',
  }) async {
    final id = 'REM-${DateTime.now().millisecondsSinceEpoch}';
    final reminder = CustomerReminder(
      id: id,
      title: title.trim(),
      customerName: customerName.trim(),
      customerId: customerId.trim(),
      orderId: orderId.trim(),
      description: description.trim(),
      reminderDate: reminderDate,
      reminderTime: reminderTime.trim(),
      assignedStaff: assignedStaff.trim(),
      priority: priority,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      phone: phone.trim(),
      region: region.trim(),
    );

    _reminders.insert(0, reminder);
    notifyListeners();

    await _service.saveReminder(reminder);
  }

  Future<void> updateReminder(CustomerReminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      _reminders[index] = reminder;
      notifyListeners();
    }
    await _service.saveReminder(reminder);
  }

  Future<void> completeReminder(String id, {required String completedBy}) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _reminders[index] = _reminders[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
        completedBy: completedBy,
      );
      notifyListeners();
    }
    await _service.completeReminder(id, completedBy: completedBy);
  }

  Future<void> reopenReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _reminders[index] = _reminders[index].copyWith(
        isCompleted: false,
        completedAt: null,
        completedBy: null,
      );
      notifyListeners();
    }
    await _service.reopenReminder(id);
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _service.deleteReminder(id);
  }
}
