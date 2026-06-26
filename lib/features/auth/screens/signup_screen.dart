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
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();
  bool _showPassword = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      SnackbarHelper.showError(
          context, 'Please accept the privacy and record-keeping terms.');
      return;
    }
    final success = await ref.read(authControllerProvider.notifier).signup(
          fullName: _nameController.text,
          username: _usernameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
          password: _passwordController.text,
          city: _cityController.text,
        );
    if (!mounted) return;
    if (!success) {
      SnackbarHelper.showError(
          context, ref.read(authControllerProvider).errorMessage);
      return;
    }
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
                Text('Create your KametiBook account',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('Har kameti ka complete hisaab.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.black54)),
                const SizedBox(height: 22),
                if (auth.errorMessage.isNotEmpty) ...[
                  Card(
                    color: Colors.red.withValues(alpha: 0.08),
                    child: ListTile(
                        leading:
                            const Icon(Icons.error_outline, color: Colors.red),
                        title: Text(auth.errorMessage)),
                  ),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) => Validators.required(value, 'Name'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _usernameController,
                  label: 'Username',
                  prefixIcon: Icons.alternate_email_outlined,
                  validator: Validators.username,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '03XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _cityController,
                  label: 'City',
                  prefixIcon: Icons.location_city_outlined,
                  validator: (value) => Validators.required(value, 'City'),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: !_showPassword,
                  prefixIcon: Icons.lock_outline,
                  validator: Validators.password,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(_showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  obscureText: !_showPassword,
                  prefixIcon: Icons.lock_reset_outlined,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return Validators.password(value);
                  },
                ),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) =>
                      setState(() => _acceptedTerms = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                      'I understand KametiBook is a record-keeping tool and my account data must be accurate.'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                AppButton(
                    label: 'Signup',
                    isLoading: auth.isLoading,
                    onPressed: _signup),
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
