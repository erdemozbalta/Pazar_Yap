class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String iosBaseUrl = 'http://localhost:3000/api';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String adminLogin = '/auth/admin/login';
  static const String employeeLogin = '/auth/employee/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String sendVerification = '/auth/verification/send';
  static const String verifyCode = '/auth/verification/verify';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  static const String profile = '/users/profile';
  static const String addresses = '/users/addresses';

  static const String markets = '/markets';

  static const String products = '/products';
  static const String categories = '/products/categories';
  static const String vendors = '/products/vendors';
  static const String vendorProducts = '/products/vendor-products';
  static const String favorites = '/products/favorites';

  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  static const String orders = '/orders';
  static const String orderPay = '/orders/pay';
  static const String orderRate = '/orders/rate';
  static const String courierPending = '/orders/courier/pending';

  static const String courierProfile = '/couriers/profile';
  static const String courierAvailability = '/couriers/availability';
  static const String courierPricing = '/couriers/pricing';
  static const String courierEarnings = '/couriers/earnings';

  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminStaff = '/admin/staff';
  static const String adminAssignments = '/admin/assignments';
  static const String adminOrders = '/admin/orders';
  static const String adminPayments = '/admin/payments';

  static const String notifications = '/notifications';
}

