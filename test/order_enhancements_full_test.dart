import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raigon_art/core/models/status.dart';
import 'package:raigon_art/core/network/auth_token_manager.dart';
import 'package:raigon_art/core/provider/customer_and_order_provider.dart';
import 'package:raigon_art/core/utils/helper.dart';
import 'package:raigon_art/features/customers/models/customer_model.dart';
import 'package:raigon_art/features/customers/models/frame_spec.dart';
import 'package:raigon_art/features/customers/presentation/widgets/add_customer_dialog.dart';
import 'package:raigon_art/features/customers/presentation/widgets/customer_view_dialog.dart';
import 'package:raigon_art/features/customers/repository/customer_repository.dart';
import 'package:raigon_art/features/frame_sizes/providers/frame_size_provider.dart';
import 'package:raigon_art/features/orders/presentation/widgets/order_progress_timeline.dart';
import 'package:raigon_art/features/reminders/models/reminder_model.dart';
import 'package:raigon_art/features/reminders/services/reminder_audio_service.dart';

class _FakeCustomerRepository implements CustomerRepository {
  List<Customer> list = [];

  @override
  Future<List<Customer>> getAll({
    String? search,
    String? status,
    String? paymentStatus,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async => list;

  @override
  Future<TrashResult> getTrash() async => TrashResult.empty();

  @override
  Future<bool> restoreTrashItem(String type, String id) async => true;

  @override
  Future<bool> permanentlyDeleteTrashItem(String type, String id) async => true;

  @override
  Future<bool> emptyTrash() async => true;

  @override
  Future<Customer> create(Customer customer) async {
    list.add(customer);
    return customer;
  }

  @override
  Future<Customer> update(Customer customer) async {
    final idx = list.indexWhere((c) => c.id == customer.id);
    if (idx != -1) {
      list[idx] = customer;
    } else {
      list.add(customer);
    }
    return customer;
  }

  @override
  Future<void> upsert(Customer customer) async => await update(customer);

  @override
  Future<void> delete(String id) async => list.removeWhere((c) => c.id == id);

  @override
  Future<void> deletePhoto(String id, String photoId) async {}

  @override
  Future<Customer> getById(String id) async =>
      list.firstWhere((c) => c.id == id);

  @override
  String getExportCsvUrl() => '';

  @override
  String getInvoiceUrl(String id) => '';

  @override
  Future<String> getNextId() async => 'RA-2001';

  @override
  String getPhotosZipUrl(String id) => '';

  @override
  Future<void> updatePayment(
    String id,
    int advance,
    String paymentStatus,
  ) async {}

  @override
  Future<void> updateStatus(String id, Status status) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthTokenManager.instance.saveSession(
      token: 'test_token',
      user: const AuthUser(
        id: 'usr_admin',
        name: 'Master Artisan',
        email: 'artisan@raigon.in',
        phone: '9876543210',
        role: 'admin',
      ),
    );
  });

  group('1. Expected Date Feature Tests', () {
    test('Helper.formatExpectedDate outputs exact DD MMMM YYYY format', () {
      final date = DateTime(2026, 11, 5);
      expect(Helper.formatExpectedDate(date), '05 November 2026');

      final date2 = DateTime(2026, 1, 9);
      expect(Helper.formatExpectedDate(date2), '09 January 2026');
    });

    test(
      'Customer.expectedDateLabel returns formatted Expected Date or fallback',
      () {
        final c1 = Customer(
          id: 'RA-101',
          name: 'Anita Roy',
          city: 'Kochi',
          phone: '9988776655',
          address: 'Fort Kochi',
          photoCount: 1,
          frameSize: '12 × 18 in',
          frameType: 'Wood',
          qty: 1,
          total: 3000,
          advance: 1000,
          status: Status.confirmed,
          orderDate: DateTime(2026, 10, 1),
          expectedDelivery: DateTime(2026, 11, 5),
        );
        expect(c1.expectedDateLabel, '05 November 2026');

        final c2 = Customer(
          id: 'RA-102',
          name: 'Bina Das',
          city: 'Kochi',
          phone: '9988776644',
          address: 'MG Road',
          photoCount: 1,
          frameSize: '10 × 12 in',
          frameType: 'Wood',
          qty: 1,
          total: 2000,
          advance: 500,
          status: Status.pending,
          orderDate: DateTime(2026, 10, 1),
        );
        expect(c2.expectedDateLabel, 'Not set');
      },
    );
  });

  group('2. Frame Measurements Multi-Unit Conversion Tests', () {
    test('FrameUnit enum correctly identifies inches, cm, and feet', () {
      expect(FrameUnit.fromString('Inches'), FrameUnit.inches);
      expect(FrameUnit.fromString('in'), FrameUnit.inches);
      expect(FrameUnit.fromString('Centimetres'), FrameUnit.centimetres);
      expect(FrameUnit.fromString('cm'), FrameUnit.centimetres);
      expect(FrameUnit.fromString('Feet'), FrameUnit.feet);
      expect(FrameUnit.fromString('ft'), FrameUnit.feet);
    });

    test('FrameMeasurementHelper conversions preserve physical dimensions', () {
      // 12 inches to feet = 1 ft
      final feet = FrameMeasurementHelper.convert(
        value: 12.0,
        from: FrameUnit.inches,
        to: FrameUnit.feet,
      );
      expect(feet, 1.0);

      // 1 ft to inches = 12 in
      final inches = FrameMeasurementHelper.convert(
        value: 1.0,
        from: FrameUnit.feet,
        to: FrameUnit.inches,
      );
      expect(inches, 12.0);

      // 1 inch to cm = 2.54 cm
      final cm = FrameMeasurementHelper.convert(
        value: 1.0,
        from: FrameUnit.inches,
        to: FrameUnit.centimetres,
      );
      expect(cm, 2.54);

      // 2 ft to cm = 2 * 12 * 2.54 = 60.96 cm
      final cmFromFt = FrameMeasurementHelper.convert(
        value: 2.0,
        from: FrameUnit.feet,
        to: FrameUnit.centimetres,
      );
      expect(cmFromFt, closeTo(60.96, 0.01));
    });

    test('FrameMeasurementHelper.convertString formats clean values', () {
      expect(
        FrameMeasurementHelper.convertString(
          valueStr: '24',
          from: FrameUnit.inches,
          to: FrameUnit.feet,
        ),
        '2',
      );
      expect(
        FrameMeasurementHelper.convertString(
          valueStr: '3',
          from: FrameUnit.feet,
          to: FrameUnit.inches,
        ),
        '36',
      );
    });

    test(
      'FrameSpec formattedDimensions displays unit and dimensions clearly',
      () {
        const spec = FrameSpec(
          size: '2x3 ft',
          unit: 'Feet',
          customWidth: '2',
          customHeight: '3',
          frameType: 'Gold Leaf',
          material: 'Teak',
          finish: 'Matte',
          orientation: 'Portrait',
          qty: 1,
        );

        expect(
          spec.formattedDimensions,
          'Width: 2 ft, Height: 3 ft (Unit: Feet)',
        );
        expect(spec.sizeLabel, '2 × 3 ft');
      },
    );
  });

  group('3. Order Status Management & 9-Status Workflow Tests', () {
    test('Standard statuses include all required 9 stages', () {
      final statuses = Status.standardStatuses;
      expect(statuses.length, 9);
      expect(statuses, [
        Status.pending,
        Status.confirmed,
        Status.onHold,
        Status.cancelled,
        Status.editingProgress,
        Status.dispatchForPrinting,
        Status.printReceived,
        Status.framingProcess,
        Status.completed,
      ]);
    });

    test('Customer.parseStatus parses various naming formats and synonyms', () {
      expect(Customer.parseStatus('Pending'), Status.pending);
      expect(Customer.parseStatus('Confirmed'), Status.confirmed);
      expect(Customer.parseStatus('On Hold'), Status.onHold);
      expect(Customer.parseStatus('on_hold'), Status.onHold);
      expect(Customer.parseStatus('Cancelled'), Status.cancelled);
      expect(Customer.parseStatus('Editing Progress'), Status.editingProgress);
      expect(Customer.parseStatus('editing_progress'), Status.editingProgress);
      expect(
        Customer.parseStatus('Dispatch for Printing'),
        Status.dispatchForPrinting,
      );
      expect(Customer.parseStatus('Print Received'), Status.printReceived);
      expect(Customer.parseStatus('Framing Process'), Status.framingProcess);
      expect(Customer.parseStatus('Completed'), Status.completed);
      // Legacy backward compatibility
      expect(Customer.parseStatus('in_progress'), Status.inProgress);
    });

    test('OrderStatusHistoryItem serializes and deserializes properly', () {
      final item = OrderStatusHistoryItem(
        previousStatus: Status.pending,
        newStatus: Status.confirmed,
        updatedAt: DateTime(2026, 10, 31, 14, 30),
        updatedBy: 'Master Artisan',
        notes: 'Deposit received.',
      );

      final json = item.toJson();
      expect(json['previousStatus'], 'pending');
      expect(json['newStatus'], 'confirmed');
      expect(json['updatedBy'], 'Master Artisan');

      final parsed = OrderStatusHistoryItem.fromJson(json);
      expect(parsed.previousStatus, Status.pending);
      expect(parsed.newStatus, Status.confirmed);
      expect(parsed.updatedBy, 'Master Artisan');
      expect(parsed.notes, 'Deposit received.');
    });
  });

  group('4. Reminder Voice Message Support Tests', () {
    test('CustomerReminder handles voice properties and serialization', () {
      final reminder = CustomerReminder(
        id: 'REM-100',
        title: 'Customer Voice Note',
        customerName: 'Kiran Kurian',
        reminderDate: DateTime(2026, 11, 2),
        createdAt: DateTime(2026, 10, 31),
        voiceUrl: 'https://raigon.in/storage/v1/voice_100.opus',
        voiceDurationSeconds: 45,
      );

      expect(reminder.hasVoice, isTrue);
      expect(reminder.voiceDurationSeconds, 45);

      final supabaseMap = reminder.toSupabaseMap();
      expect(
        supabaseMap['voice_url'],
        'https://raigon.in/storage/v1/voice_100.opus',
      );
      expect(supabaseMap['voice_duration_seconds'], 45);

      final fromMap = CustomerReminder.fromJson(supabaseMap);
      expect(fromMap.voiceUrl, 'https://raigon.in/storage/v1/voice_100.opus');
      expect(fromMap.voiceDurationSeconds, 45);
      expect(fromMap.hasVoice, isTrue);
    });

    test('ReminderAudioService handles safe disposal without throwing', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('com.llfbandit.record/messages'), (call) async => null);

      final audioService = ReminderAudioService();
      expect(audioService.isDisposed, isFalse);

      audioService.dispose();
      expect(audioService.isDisposed, isTrue);

      expect(() => audioService.dispose(), returnsNormally);
      expect(() => audioService.pause(), returnsNormally);
      expect(() => audioService.resume(), returnsNormally);
      expect(() => audioService.stop(), returnsNormally);
      expect(() => audioService.cancelRecording(), returnsNormally);
    });
  });

  group('5. OrderProgressTimeline Widget Tests', () {
    testWidgets('Renders all 7 production stages and highlights active stage', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OrderProgressTimeline(status: Status.editingProgress),
            ),
          ),
        ),
      );

      expect(find.text('CURRENT STATUS: EDITING PROGRESS'), findsOneWidget);
      expect(
        find.text('Artwork & photo retouching in progress.'),
        findsOneWidget,
      );
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Editing Progress'), findsOneWidget);
      expect(find.text('Dispatch for Printing'), findsOneWidget);
      expect(find.text('Print Received'), findsOneWidget);
      expect(find.text('Framing Process'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets(
      'Renders prominent alert and Resume Order button when On Hold',
      (tester) async {
        bool resumed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OrderProgressTimeline(
                status: Status.onHold,
                onResumeOrder: () {
                  resumed = true;
                },
              ),
            ),
          ),
        );

        expect(find.text('Order is On Hold'), findsOneWidget);
        expect(
          find.text(
            'Workshop production is paused. Resume to continue the workflow.',
          ),
          findsOneWidget,
        );
        expect(find.text('Resume Order'), findsOneWidget);

        await tester.tap(find.text('Resume Order'));
        await tester.pumpAndSettle();

        expect(resumed, isTrue);
      },
    );

    testWidgets('Renders prominent alert when Cancelled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OrderProgressTimeline(status: Status.cancelled)),
        ),
      );

      expect(find.text('Order Cancelled'), findsOneWidget);
      expect(
        find.text(
          'This order was cancelled and is excluded from active production.',
        ),
        findsOneWidget,
      );
    });
  });

  group('6. CustomerViewDialog Expected Date & Frame Unit Integration', () {
    testWidgets(
      'ViewCustomerDialog displays Expected Date and Frame Dimensions with Unit',
      (tester) async {
        final customer = Customer(
          id: 'RA-999',
          name: 'George Varghese',
          city: 'Ernakulam',
          phone: '9847123456',
          address: 'Marine Drive, Kochi',
          photoCount: 0,
          frameSize: '24 × 36 in',
          frameType: 'Premium Teak',
          qty: 1,
          total: 8000,
          advance: 3000,
          status: Status.framingProcess,
          orderDate: DateTime(2026, 10, 10),
          expectedDelivery: DateTime(2026, 11, 5),
          frames: const [
            FrameSpec(
              size: '2x3 ft',
              unit: 'Feet',
              customWidth: '2',
              customHeight: '3',
              frameType: 'Teak',
              material: 'Wood',
              finish: 'Natural',
              orientation: 'Portrait',
              qty: 1,
            ),
          ],
        );

        final fakeRepo = _FakeCustomerRepository()..list = [customer];
        final customerProvider = CustomerAndOrderProvider(repository: fakeRepo);
        final sizeProvider = FrameSizeProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: customerProvider),
              ChangeNotifierProvider.value(value: sizeProvider),
            ],
            child: MaterialApp(
              home: Scaffold(body: ViewCustomerDialog(customer: customer)),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check Expected Date is rendered with proper heading
        expect(find.text('Expected Date: 05 November 2026'), findsOneWidget);

        // Check Frame dimensions with unit
        expect(
          find.text('Width: 2 ft, Height: 3 ft (Unit: Feet)'),
          findsOneWidget,
        );

        // Check timeline status
        expect(find.text('CURRENT STATUS: FRAMING PROCESS'), findsOneWidget);
      },
    );
  });

  group('7. AddCustomerDialog Keyboard Responsiveness & Scrollability', () {
    testWidgets(
      'AddCustomerDialog contains a scrollable view handling keyboard insets',
      (tester) async {
        final fakeRepo = _FakeCustomerRepository();
        final customerProvider = CustomerAndOrderProvider(repository: fakeRepo);
        final sizeProvider = FrameSizeProvider();

        // Simulate a small screen with active keyboard (bottom inset = 280)
        tester.view.physicalSize = const Size(375, 667);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: customerProvider),
              ChangeNotifierProvider.value(value: sizeProvider),
            ],
            child: const MediaQuery(
              data: MediaQueryData(
                size: Size(375, 667),
                viewInsets: EdgeInsets.only(bottom: 280),
              ),
              child: MaterialApp(home: Scaffold(body: AddCustomerDialog())),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scrollable view exists
        expect(find.byType(SingleChildScrollView), findsWidgets);

        // Header exists
        expect(find.text('Add Customer & Order'), findsOneWidget);
        expect(find.text('Expected Date'), findsOneWidget);

        // Scroll down to verify fields remain accessible when keyboard is open
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -600),
        );
        await tester.pumpAndSettle();

        // Frame unit selector and inputs become visible and accessible
        expect(find.textContaining('Inches'), findsWidgets);
        expect(find.text('Measurement Unit'), findsOneWidget);
        expect(find.text('Save Order'), findsOneWidget);
      },
    );
  });
}
