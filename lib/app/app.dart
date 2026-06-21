import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme.dart';

class KametiBookApp extends StatelessWidget {
  const KametiBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KametiBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
