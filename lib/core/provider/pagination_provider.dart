import 'package:flutter/foundation.dart';

class PaginationProvider extends ChangeNotifier {
  PaginationProvider({this.pageSize = 10});
  final int pageSize;

  int _page = 1;
  int get page => _page;
  int totalPages(int totalItems) {
    return totalItems == 0 ? 1 : (totalItems / pageSize).ceil();
  }

  int getStartIndex(int totalItems) {
    if (totalItems == 0) return 0;
    return (_page - 1) * pageSize;
  }

  List<T> paginate<T>(List<T> items) {
    final pages = totalPages(items.length);
    final safePage = _page.clamp(1, pages);
    final start = (safePage - 1) * pageSize;

    return items.skip(start).take(pageSize).toList();
  }

  void setPage(int newPage, int totalItems) {
    final safePage = newPage.clamp(1, totalPages(totalItems));

    if (_page == safePage) return;

    _page = safePage;
    notifyListeners();
  }

  void resetPage() {
    if (_page == 1) return;

    _page = 1;
    notifyListeners();
  }
}
