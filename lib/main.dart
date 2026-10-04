import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/constants/app_urls.dart';
import 'core/services/api_service.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/dashboard/screens/entrepreneur_dashboard_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/financeur/screens/financeur_dashboard_screen.dart';
import 'features/mentor/screens/mentor_dashboard_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await ApiService.isLoggedIn();
  String? userRole;

  if (isLoggedIn) {
    final response = await ApiService.get(AppUrls.me);
    if (response['success']) {
      userRole = response['data']['role'];
    }
  }

  runApp(EDALaunchApp(isLoggedIn: isLoggedIn, userRole: userRole));
}

class EDALaunchApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? userRole;

  const EDALaunchApp({
    super.key,
    required this.isLoggedIn,
    this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    Widget homeScreen;

    if (!isLoggedIn) {
      homeScreen = const RoleSelectionScreen();
    } else {
      switch (userRole) {
        case 'admin':
          homeScreen = const AdminDashboardScreen();
          break;
        case 'financeur':
          homeScreen = const FinanceurDashboardScreen();
          break;
        case 'mentor':
          homeScreen = MentorDashboardScreen();
          break;  
        case 'entrepreneur':
          homeScreen = const EntrepreneurDashboardScreen();
          break;
        default:
          homeScreen = const RoleSelectionScreen();
          break;
      }
    }

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      home: homeScreen,
    );
  }
}

void redirectToLogin() {
  navigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    (route) => false,
  );
}