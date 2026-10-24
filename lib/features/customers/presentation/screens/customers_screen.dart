import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/core/provider/pagination_provider.dart';
import 'package:raigon_art/core/theme/app_colors.dart';
import 'package:raigon_art/core/theme/app_palette.dart';
import 'package:raigon_art/core/widgets/app_pagination_footer.dart';
import 'package:raigon_art/core/widgets/app_primary_button.dart';
import 'package:raigon_art/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:raigon_art/features/customers/presentation/widgets/customer_delete_dialog.dart';
import 'package:raigon_art/features/customers/presentation/widgets/customer_view_dialog.dart';
import 'package:raigon_art/core/utils/csv_export.dart';
import 'package:raigon_art/core/widgets/app_dropdown.dart';
import 'package:raigon_art/core/widgets/app_snackbar.dart';
import 'package:raigon_art/core/network/api_exception.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/presentation/widgets/customers_table.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/widgets/shell_scope.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/features/customers/provider/customers_screen_provider.dart';
import 'package:raigon_art/features/customers/service/customer_whatsapp_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  Status? _status;
  final SortOption _sort = SortOption.newest;

  Future<void> _edit(Customer c) => showEditCustomerDialog(context, c);

  Future<void> _delete(Customer customer) async {
    final ok = await showDeleteCustomerDialog(context, customer);

    if (!ok || !mounted) return;

    try {
      await context.read<CustomerAndOrderProvider>().remove(customer.id);

      if (mounted) {
        AppSnackBar.success(context, 'Customer deleted successfully.');
      }
    } catch (error) {
      if (mounted) {
        final msg = error is ApiException
            ? error.userFriendlyMessage
            : 'Could not delete customer. Try again.';
        AppSnackBar.error(context, msg);
      }
    }
  }

  Future<void> _sendWhatsApp(Customer customer) async {
    try {
      final opened = await CustomerWhatsAppService.openOrderConfirmation(
        customer,
      );

      if (!mounted) return;

      if (opened) {
        AppSnackBar.success(
          context,
          'WhatsApp opened with the order confirmation.',
        );
      } else {
        AppSnackBar.error(
          context,
          'Could not open WhatsApp. Please try again.',
        );
      }
    } catch (error) {
      if (!mounted) return;

      AppSnackBar.error(
        context,
        'Could not open WhatsApp. Check the customer mobile number.',
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Customer> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    final provider = context.read<CustomerAndOrderProvider>();

    final list = provider.customers.where((c) {
      final statusOk = _status == null || c.status == _status;

      final searchOk =
          q.isEmpty ||
          [
            c.id,
            c.name,
            c.phone,
            c.city,
            c.address,
          ].any((value) => value.toLowerCase().contains(q));

      return statusOk && searchOk;
    }).toList();

    switch (_sort) {
      case SortOption.newest:
        list.sort((a, b) => b.orderDate.compareTo(a.orderDate));
      case SortOption.oldest:
        list.sort((a, b) => a.orderDate.compareTo(b.orderDate));
      case SortOption.name:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case SortOption.amount:
        list.sort((a, b) => b.total.compareTo(a.total));
    }

    return list;
  }

  Future<void> _exportCsv() async {
    final list = _filtered;
    if (list.isEmpty) {
      AppSnackBar.error(context, 'No customers to export.');
      return;
    }
    try {
      final provider = context.read<CustomerAndOrderProvider>();
      await downloadCsv(
        provider.csvFileName(),
        provider.buildCustomersCsv(list),
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'Customer data exported successfully.');
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Could not export CSV. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CustomerAndOrderProvider>();
    final p = AppPalette.of(context);
    final screenProvider = context.watch<CustomersScreenProvider>();
    final customerProvider = context.watch<CustomerAndOrderProvider>();
    final pagination = context.watch<PaginationProvider>();
    final all = screenProvider.filteredCustomers(customerProvider.customers);
    final pageItems = pagination.paginate(all);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(p, wide),

              const SizedBox(height: 24),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: p.card(),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Search, filter and sort toolbar.
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: _toolbar(p, wide),
                      ),

                      if (customerProvider.error != null && customerProvider.customers.isEmpty)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Failed to load customers',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: p.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    customerProvider.error is ApiException
                                        ? (customerProvider.error as ApiException).userFriendlyMessage
                                        : 'Please check your connection to the server.',
                                    style: TextStyle(fontSize: 14, color: p.textMuted),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      customerProvider.refresh().then((_) {
                                        if (context.mounted) {
                                          AppSnackBar.success(context, 'Customers loaded successfully.');
                                        }
                                      }).catchError((e) {
                                        if (context.mounted) {
                                          final msg = e is ApiException ? e.userFriendlyMessage : 'Retry failed.';
                                          AppSnackBar.error(context, msg);
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else ...[
                        CustomersTable(
                          customers: pageItems,
                          onView: (c) => showViewCustomerDialog(context, c),
                          onWhatsApp: _sendWhatsApp,
                          onEdit: _edit,
                          onDelete: _delete,
                        ),

                        AppPaginationFooter(
                          totalItems: all.length,
                          page: pagination.page,
                          pageSize: pagination.pageSize,
                          itemLabel: 'customers',
                          onPageChanged: (newPage) {
                            pagination.setPage(newPage, all.length);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(AppPalette p, bool wide) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customers',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage customer details and photo frame orders',
                style: TextStyle(fontSize: 15.5, color: p.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: _exportCsv,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 20 : 14,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: p.chipFill,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: p.isDark ? p.border : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.fileExport,
                  size: 17,
                  color: p.textPrimary,
                ),
                if (wide) ...[
                  const SizedBox(width: 10),
                  Text(
                    'Export CSV',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: p.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        AppPrimaryButton(
          label: 'Add New Customer',
          icon: Icons.person_add,
          onPressed: () => ShellScope.of(context).openAddCustomer(),
        ),
      ],
    );
  }

  Widget _searchField(AppPalette p) {
    OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: w),
    );
    return SizedBox(
      width: 270,
      height: 46,
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) {
          context.read<CustomersScreenProvider>().setSearchQuery(value);
          context.read<PaginationProvider>().resetPage();
        },
        cursorColor: p.textPrimary,
        style: TextStyle(fontSize: 15, color: p.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search customer, phone, ID...',
          hintStyle: TextStyle(fontSize: 15, color: p.textMuted),
          prefixIcon: Icon(Icons.search, size: 21, color: p.textMuted),
          filled: true,
          fillColor: p.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          enabledBorder: border(p.border),
          focusedBorder: border(AppColors.gold, 1.4),
        ),
      ),
    );
  }

  Widget _toolbar(AppPalette p, bool wide) {
    final status = AppDropdown<Status?>(
      value: context.watch<CustomersScreenProvider>().status,
      items: [null, ...Status.values],
      labelOf: (status) => status?.label ?? 'All Statuses',
      width: 175,
      onChanged: (value) {
        context.read<CustomersScreenProvider>().setStatus(value);
        context.read<PaginationProvider>().resetPage();
      },
    );
    final sort = AppDropdown<SortOption>(
      value: context.watch<CustomersScreenProvider>().sort,
      items: SortOption.values,
      labelOf: (s) => s.label,
      width: 200,
      onChanged: (value) {
        context.read<CustomersScreenProvider>().setSort(value);
        context.read<PaginationProvider>().resetPage();
      },
    );
    if (wide) {
      return Row(
        children: [
          _searchField(p),
          const SizedBox(width: 14),
          status,
          const Spacer(),
          sort,
        ],
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [_searchField(p), status, sort],
    );
  }
}
