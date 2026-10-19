class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://raigon-arts-api-1a3z.onrender.com/api/v1',
  );

  static const String serverHost = String.fromEnvironment(
    'API_SERVER_HOST',
    defaultValue: 'https://raigon-arts-api-1a3z.onrender.com',
  );

  // Module 1: Auth
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';

  // Module 2: Customers & Orders
  static const String customers = '/customers';
  static const String nextCustomerId = '/customers/next-id';
  static String customer(String id) => '/customers/$id';
  static String customerStatus(String id) => '/customers/$id/status';
  static String customerPayment(String id) => '/customers/$id/payment';
  static String customerPhoto(String id, String photoId) =>
      '/customers/$id/photos/$photoId';
  static String customerPhotosZip(String id) =>
      '/customers/$id/photos/download-zip';
  static String customerInvoice(String id) => '/customers/$id/invoice';
  static const String exportCustomersCsv = '/customers/export/csv';

  // Module 3: Storage
  static const String uploadStorage = '/storage/upload';

  // Module 4: Frame Sizes Master
  static const String frameSizes = '/frame-sizes';
  static String frameSize(String code) => '/frame-sizes/$code';

  // Module 5: Dashboard
  static const String dashboardStats = '/dashboard/stats';

  // Module 6: Reports
  static const String reportsSummary = '/reports/summary';

  // Module 7: WhatsApp
  static const String whatsappSendConfirmation =
      '/whatsapp/send-order-confirmation';
  static const String whatsappSendStatus = '/whatsapp/send-status-update';

  // Module 8: Workshop Settings
  static const String workshopProfile = '/settings/profile';
  static const String retentionPolicy = '/settings/retention';
  static const String cleanupTrigger = '/settings/cleanup/trigger';
}
