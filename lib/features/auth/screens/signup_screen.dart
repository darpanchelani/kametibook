import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../providers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signup(
          fullName: _nameController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          city: _cityController.text,
        );
    if (!mounted) return;
    SnackbarHelper.showSuccess(context, 'Account created successfully.');
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start with your basic details.',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 22),
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => Validators.required(value, 'Name'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '03XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _cityController,
                  label: 'City',
                  prefixIcon: Icons.location_city_outlined,
                  validator: (value) => Validators.required(value, 'City'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: true,
                  prefixIcon: Icons.lock_reset_outlined,
                  validator: (value) {
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return Validators.password(value);
                  },
                ),
                const SizedBox(height: 24),
                AppButton(label: 'Signup', isLoading: auth.isLoading, onPressed: _signup),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
