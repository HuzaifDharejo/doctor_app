/// App-wide string constants for consistent text
library;

/// Screen titles and headers
abstract class AppStrings {
  // App
  static const String appName = 'Doctor App';
  
  // Navigation
  static const String home = 'Home';
  static const String navHome = 'Home';
  static const String navPatients = 'Patients';
  static const String navAppointments = 'Appts';
  static const String navPrescriptions = 'Rx';
  static const String navBilling = 'Billing';
  static const String patients = 'Patients';
  static const String appointments = 'Appointments';
  static const String appointmentsShort = 'Appts';
  static const String prescriptions = 'Prescriptions';
  static const String prescriptionsShort = 'Rx';
  static const String billing = 'Billing';
  static const String settings = 'Settings';
  
  // Headers
  static const String dashboard = 'Dashboard';
  static const String managePatients = 'Manage your patient records';
  static const String manageAppointments = 'Schedule and track appointments';
  static const String managePrescriptions = 'Create and manage prescriptions';
  static const String manageBilling = 'Track payments and invoices';
  static const String manageSettings = 'Manage your preferences';
  
  // Actions
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String seeAll = 'See All';
  static const String viewAll = 'View All';
  static const String back = 'Back';
  static const String close = 'Close';
  static const String done = 'Done';
  static const String submit = 'Submit';
  static const String clear = 'Clear';
  static const String refresh = 'Refresh';
  static const String retry = 'Retry';
  
  // Patient
  static const String addPatient = 'Add Patient';
  static const String editPatient = 'Edit Patient';
  static const String patientDetails = 'Patient Details';
  static const String patientName = 'Patient Name';
  static const String searchPatients = 'Search patients...';
  static const String noPatients = 'No patients found';
  static const String noPatientsYet = 'No patients yet';
  static const String addFirstPatient = 'Add your first patient to get started';
  static const String recentPatients = 'Recent Patients';
  
  // Appointment
  static const String addAppointment = 'Add Appointment';
  static const String editAppointment = 'Edit Appointment';
  static const String appointmentDetails = 'Appointment Details';
  static const String todayAppointments = "Today's Appointments";
  static const String upcomingAppointments = 'Upcoming Appointments';
  static const String noAppointments = 'No appointments found';
  static const String noAppointmentsToday = 'No appointments today';
  
  // Prescription
  static const String addPrescription = 'Add Prescription';
  static const String editPrescription = 'Edit Prescription';
  static const String prescriptionDetails = 'Prescription Details';
  static const String noPrescriptions = 'No prescriptions found';
  
  // Invoice
  static const String addInvoice = 'Add Invoice';
  static const String createInvoice = 'Create Invoice';
  static const String editInvoice = 'Edit Invoice';
  static const String invoiceDetails = 'Invoice Details';
  static const String noInvoices = 'No invoices found';
  
  // Status
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Info';
  
  // Error messages
  static const String somethingWentWrong = 'Something went wrong';
  static const String tryAgain = 'Please try again';
  static const String noInternet = 'No internet connection';
  static const String sessionExpired = 'Session expired';
  
  // Drawer items
  static const String doctorProfile = 'Doctor Profile';
  static const String psychiatricAssessment = 'Psychiatric Assessment';
  static const String notifications = 'Notifications';
  static const String backupSync = 'Backup & Sync';
  static const String helpSupport = 'Help & Support';
  static const String logout = 'Logout';
  static const String quickAccess = 'QUICK ACCESS';
  static const String setupProfile = 'Set up profile';
  
  // Filters
  static const String all = 'All';
  static const String today = 'Today';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  
  // Risk levels
  static const String lowRisk = 'Low Risk';
  static const String mediumRisk = 'Medium Risk';
  static const String highRisk = 'High Risk';
  
  // Status labels
  static const String pending = 'Pending';
  static const String scheduled = 'Scheduled';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String paid = 'Paid';
  static const String unpaid = 'Unpaid';
  static const String partial = 'Partial';
}
