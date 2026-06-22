import 'package:flutter/material.dart';

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({this.message = 'Loading...', super.key});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({required this.icon, required this.title, this.message, this.action, super.key});
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(radius: 42, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), child: Icon(icon, size: 38)),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
          ],
          if (action != null) ...[const SizedBox(height: 18), action!],
        ]),
      ),
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({required this.message, this.onRetry, super.key});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: message,
      action: onRetry == null ? null : FilledButton(onPressed: onRetry, child: const Text('Try Again')),
    );
  }
}

class AppSuccessState extends StatelessWidget {
  const AppSuccessState({required this.title, this.message, super.key});
  final String title;
  final String? message;
  @override
  Widget build(BuildContext context) => AppEmptyState(icon: Icons.check_circle_outline, title: title, message: message);
}

class AppPermissionDeniedView extends StatelessWidget {
  const AppPermissionDeniedView({
    this.title = 'Permission denied',
    this.message = 'You do not have permission to view this information.',
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.lock_outline,
      title: title,
      message: message,
    );
  }
}

class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Colors.orange.withValues(alpha: 0.14),
      child: const Text('Offline changes will sync when internet is available.', textAlign: TextAlign.center),
    );
  }
}
