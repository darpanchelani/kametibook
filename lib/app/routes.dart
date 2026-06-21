import 'package:flutter/material.dart';

import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/home/screens/main_layout.dart';
import '../features/kameti/screens/create_kameti_screen.dart';
import '../features/kameti/screens/kameti_details_screen.dart';
import '../features/member/screens/add_member_screen.dart';
import '../features/member/screens/edit_member_screen.dart';
import '../features/member/screens/member_details_screen.dart';
import '../features/member/screens/members_list_screen.dart';
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
  static const members = '/members';
  static const addMember = '/add-member';
  static const editMember = '/edit-member';
  static const memberDetails = '/member-details';

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
          case members:
            return MembersListScreen(kametiId: settings.arguments! as String);
          case addMember:
            return AddMemberScreen(kametiId: settings.arguments! as String);
          case editMember:
            final args = settings.arguments! as Map<String, String>;
            return EditMemberScreen(kametiId: args['kametiId']!, memberId: args['memberId']!);
          case memberDetails:
            return MemberDetailsScreen(memberId: settings.arguments! as String);
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
