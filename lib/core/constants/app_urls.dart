class AppUrls {
  // ==============================
  // URL DE BASE
  // ==============================
  // En développement → localhost
  // En production → URL AWS
  //static const String baseUrl = 'http://35.180.121.83/api'; // Production
//static const String baseUrl = 'http://10.0.2.2:3000/api'; // Développement
static const String baseUrl = 'https://edalaunch.com/api';


  // ==============================
  // AUTH
  // ==============================
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String resendOtp = '$baseUrl/auth/resend-otp';
  static const String forgotPassword = '$baseUrl/auth/forgot-password';
  static const String resetPassword = '$baseUrl/auth/reset-password';
  static const String me = '$baseUrl/auth/me';
  static const String logout = '$baseUrl/auth/logout';

  // ==============================
  // PROJETS
  // ==============================
  static const String projects = '$baseUrl/projects';
  static String projectById(String id) => '$baseUrl/projects/$id';
  static String projectStatus(String id) => '$baseUrl/projects/$id/status';
  static String projectDocuments(String id) => '$baseUrl/projects/$id/documents';

  // ==============================
  // SCORING
  // ==============================
  static const String questionnaire = '$baseUrl/scoring/questionnaire';
  static String createDiagnostic(String projectId) => '$baseUrl/scoring/$projectId';
  static String getDiagnostic(String projectId) => '$baseUrl/scoring/$projectId';
  static String diagnosticHistory(String projectId) => '$baseUrl/scoring/$projectId/history';

  // ==============================
  // FORMATIONS
  // ==============================
  static const String formations = '$baseUrl/formations';
  static const String myFormations = '$baseUrl/formations/my/enrolled';
  static String formationById(String id) => '$baseUrl/formations/$id';
  static String formationModules(String id) => '$baseUrl/formations/$id/modules';
  static String enrollFormation(String id) => '$baseUrl/formations/$id/enroll';
  static String updateProgress(String id) => '$baseUrl/formations/$id/progress';
  static String moduleQuizzes(String id) => '$baseUrl/formations/$id/quizzes';
  static String submitQuiz(String id) => '$baseUrl/formations/$id/quizzes/submit';

  // ==============================
  // FINANCEMENT
  // ==============================
  static const String financing = '$baseUrl/financing';
  static const String myRequests = '$baseUrl/financing/my/requests';
  static String matchingFinancers(String projectId) => '$baseUrl/financing/matching/$projectId';
  static String financingById(String id) => '$baseUrl/financing/$id';
  static String financingStatus(String id) => '$baseUrl/financing/$id/status';
  static String financingDocuments(String id) => '$baseUrl/financing/$id/documents';

  // ==============================
  // NOTIFICATIONS
  // ==============================
  static const String notifications = '$baseUrl/notifications';
  static const String unreadCount = '$baseUrl/notifications/unread-count';
  static const String markAllRead = '$baseUrl/notifications/read-all';
  static String markAsRead(String id) => '$baseUrl/notifications/$id/read';
  static String deleteNotification(String id) => '$baseUrl/notifications/$id';

  // ==============================
  // REPORTING
  // ==============================
  static const String reporting = '$baseUrl/reporting';
  static const String reportingAlerts = '$baseUrl/reporting/alerts';
  static String reportById(String id) => '$baseUrl/reporting/$id';
  static String reportProofs(String id) => '$baseUrl/reporting/$id/proofs';

  // ==============================
  // DASHBOARD
  // ==============================
  static const String dashboardEntrepreneur = '$baseUrl/dashboard/entrepreneur';
  static const String dashboardAdmin = '$baseUrl/dashboard/admin';
  static const String dashboardFinanceur = '$baseUrl/dashboard/financeur';
  static const String dashboardMentor = '$baseUrl/dashboard/mentor';

  // ==============================
// BUSINESS PLAN
// ==============================
static String generateBusinessPlan(String projectId) => 
    '$baseUrl/business-plan/$projectId/generate';
static String getBusinessPlan(String projectId) => 
    '$baseUrl/business-plan/$projectId';

static const String analyzeImage = '$baseUrl/reporting/analyze-image';    

// Assignation
static String assignFinancer(String requestId) => 
    '$baseUrl/financing/$requestId/assign';
static String assignMentor(String projectId) => 
    '$baseUrl/projects/$projectId/assign-mentor';

// ==============================
// RENDEZ-VOUS
// ==============================
static const String appointments = '$baseUrl/appointments';
static const String availabilities = '$baseUrl/appointments/availabilities';
static String updateAppointment(String id) => '$baseUrl/appointments/$id';

static String projectReports(String projectId) =>
    '$baseUrl/reporting/project/$projectId';

static String coachingNotes(String projectId) =>
    '$baseUrl/reporting/$projectId/coaching';

static String entrepreneurAlerts(String projectId) =>
    '$baseUrl/reporting/alerts/$projectId';
static String entrepreneurFormations(String entrepreneurId) =>
    '$baseUrl/reporting/formations/$entrepreneurId';

static String messageToMentor(String projectId) =>
    '$baseUrl/reporting/message/$projectId';

static String userProfile(String userId) =>
    '$baseUrl/auth/users/$userId/profile';

// Upload S3
static const String uploadProfilePhoto = '$baseUrl/upload/profile-photo';
static const String uploadCV = '$baseUrl/upload/cv';
static String uploadProjectPhoto(String projectId) => '$baseUrl/upload/project-photo/$projectId';
static String uploadModule(String formationId) => '$baseUrl/upload/module/$formationId';
    }