// lib/services/api_config.dart
class ApiConfig {
  // ─── SERVICE PORTS ───
  static const String identityService = 'http://localhost:5103';
  static const String tenantService   = 'http://localhost:5104';
  static const String visitorService  = 'http://localhost:5105';
  static const String billingService  = 'http://localhost:5107';
  static const String helpdeskService = 'http://localhost:5108';
  static const String noticeService   = 'http://localhost:5109';
  static const String amenityService  = 'http://localhost:5110';
  static const String dailyHelpService= 'http://localhost:5111';
  static const String vehicleService  = 'http://localhost:5112';
  static const String directoryService= 'http://localhost:5113';
  //static const String emergencyGateway= 'http://localhost:5114';

    static const String emergencyService = 'http://localhost:5114'; 
  static const String emergencyGateway = 'http://localhost:5116'; // MOVED TO 5116

  // ─── IDENTITY & CONTEXT SWITCH ───
  static String get selectContextUrl => '$identityService/api/auth/select-context';
    static String get loginUrl => '$identityService/api/auth/verify-otp';
  static String get requestOtpUrl => '$identityService/api/auth/request-otp';
  static String get registerUrl => '$identityService/api/auth/register';
  
 // ─── TENANT ───
  static String get mySocietiesUrl => '$tenantService/api/societies/my-societies';
  static String get societiesBaseUrl => '$tenantService/api/Societies';

  // ─── VISITORS ───
  static String get visitorsBaseUrl => '$visitorService/api/visitors';
  
  // ─── BILLING ───
  static String get billingBaseUrl => '$billingService/api/Invoices'; // CHANGED from api/Billing

  // ─── HELPDESK ───
  static String get helpdeskBaseUrl => '$helpdeskService/api/tickets';

  // ─── AMENITY ───
  static String get amenityBaseUrl => '$amenityService/api/Amenities';
  static String get bookingsBaseUrl => '$amenityService/api/Bookings';

  // ─── DAILY HELP ───
  static String get dailyHelpBaseUrl => '$dailyHelpService';

  // ─── VEHICLES ───
  static String get vehiclesBaseUrl => '$vehicleService/api/Vehicles';

  // ─── DIRECTORY ───
  static String get directoryBaseUrl => '$directoryService/api/Directory';
}