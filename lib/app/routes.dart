import 'package:flutter/material.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/home/screens/main_layout.dart';
import '../features/kameti/screens/add_members_placeholder_screen.dart';
import '../features/kameti/screens/create_kameti_screen.dart';
import '../features/kameti/screens/kameti_details_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/onboarding/screens/splash_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const main = '/main';
  static const createKameti = '/create-kameti';
  static const kametiDetails = '/kameti-details';
  static const addMembers = '/add-members';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        switch (settings.name) {
          case splash:
            return const SplashScreen();
          case onboarding:
            return const OnboardingScreen();
          case login:
            return const LoginScreen();
          case signup:
            return const SignupScreen();
          case forgotPassword:
            return const ForgotPasswordScreen();
          case main:
            final initialTab = settings.arguments is int ? settings.arguments as int : 0;
            return MainLayout(initialTab: initialTab);
          case createKameti:
            return const CreateKametiScreen();
          case kametiDetails:
            return KametiDetailsScreen(kametiId: settings.arguments! as String);
          case addMembers:
            return const AddMembersPlaceholderScreen();
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
