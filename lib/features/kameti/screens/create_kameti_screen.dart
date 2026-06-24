import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../auth/providers/auth_controller.dart';
import '../../member/providers/member_controller.dart';
import '../models/kameti_model.dart';
import '../providers/kameti_controller.dart';

class CreateKametiScreen extends ConsumerStatefulWidget {
  const CreateKametiScreen({super.key});

  @override
  ConsumerState<CreateKametiScreen> createState() => _CreateKametiScreenState();
}

class _CreateKametiScreenState extends ConsumerState<CreateKametiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _monthlyAmountController = TextEditingController();
  final _totalMembersController = TextEditingController();
  final _durationController = TextEditingController();
  final _organizerController = TextEditingController();
  final _descriptionController = TextEditingController();

  KametiType _type = KametiType.ownerFirst;
  DateTime? _startDate;
  int? _dueDay;
  bool _durationManuallyEdited = false;
  bool _isSubmitting = false;

  double get _monthlyAmount =>
      double.tryParse(
          _monthlyAmountController.text.replaceAll(',', '').trim()) ??
      0;
  int get _totalMembers =>
      int.tryParse(_totalMembersController.text.trim()) ?? 0;
  int get _duration => int.tryParse(_durationController.text.trim()) ?? 0;
  double get _totalPool => _monthlyAmount * _totalMembers;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _organizerController.text = user?.fullName ?? '';
    _totalMembersController.addListener(_syncDurationWithMembers);
  }

  void _syncDurationWithMembers() {
    // Phase 1 default: one payout cycle per member. Users can still edit duration after auto-fill.
    if (!_durationManuallyEdited) {
      _durationController.text = _totalMembersController.text;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _totalMembersController.removeListener(_syncDurationWithMembers);
    _nameController.dispose();
    _monthlyAmountController.dispose();
    _totalMembersController.dispose();
    _durationController.dispose();
    _organizerController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _startDate ?? now,
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      SnackbarHelper.showError(
          context, 'Please login before creating a kameti.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      SnackbarHelper.showError(context, 'Start date is required');
      return;
    }
    if (_dueDay == null) {
      SnackbarHelper.showError(context, 'Due day is required');
      return;
    }

    final kameti = KametiModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      type: _type,
      monthlyAmount: _monthlyAmount,
      totalMembers: _totalMembers,
      durationMonths: _duration,
      startDate: _startDate!,
      dueDay: _dueDay!,
      organizerName: _organizerController.text.trim(),
      description: _descriptionController.text.trim(),
      totalPoolAmount: _totalPool,
      status: KametiStatus.draft,
      createdAt: DateTime.now(),
      ownerUserId: user.id,
      memberUserIds: [user.id],
    );

    setState(() => _isSubmitting = true);
    try {
      await ref.read(kametiControllerProvider.notifier).createKameti(kameti);
      ref.read(memberControllerProvider.notifier).ensureOrganizerMember(
            kameti: kameti,
            currentUser: user,
          );
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Kameti created successfully.');
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.main, (_) => false, arguments: 1);
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(
          context, 'Kameti could not be saved. Please try again.');
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Kameti')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppTextField(
                controller: _nameController,
                label: 'Kameti Name',
                hint: 'Friends 10 Month Kameti',
                prefixIcon: Icons.edit_note_outlined,
                validator: (value) => Validators.required(value, 'Kameti name'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<KametiType>(
                initialValue: _type,
                decoration: const InputDecoration(
                    labelText: 'Kameti Type',
                    prefixIcon: Icon(Icons.category_outlined)),
                items: KametiType.values
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _type = value ?? KametiType.ownerFirst),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _monthlyAmountController,
                label: 'Monthly Contribution Amount',
                hint: '20000',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
                validator: (value) =>
                    Validators.positiveNumber(value, 'Monthly amount'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _totalMembersController,
                label: 'Total Members',
                hint: '10',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.group_outlined,
                validator: Validators.members,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _durationController,
                label: 'Duration in Months',
                hint: '10',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.calendar_view_month_outlined,
                validator: (value) =>
                    Validators.positiveNumber(value, 'Duration'),
                onChanged: (_) =>
                    setState(() => _durationManuallyEdited = true),
              ),
              const SizedBox(height: 14),
              _PickerTile(
                icon: Icons.event_outlined,
                label: 'Start Date',
                value: _startDate == null
                    ? 'Select start date'
                    : DateFormatter.display(_startDate!),
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _dueDay,
                decoration: const InputDecoration(
                    labelText: 'Monthly Due Day',
                    prefixIcon: Icon(Icons.today_outlined)),
                items: List.generate(28, (index) => index + 1)
                    .map((day) =>
                        DropdownMenuItem(value: day, child: Text('Day $day')))
                    .toList(),
                validator: (value) =>
                    value == null ? 'Due day is required' : null,
                onChanged: (value) => setState(() => _dueDay = value),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _organizerController,
                label: 'Organizer Name',
                prefixIcon: Icons.person_pin_outlined,
                validator: (value) =>
                    Validators.required(value, 'Organizer name'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _descriptionController,
                label: 'Description / Rules',
                hint: 'Optional',
                maxLines: 3,
                prefixIcon: Icons.notes_outlined,
              ),
              const SizedBox(height: 16),
              _CalculationCard(
                monthlyAmount: _monthlyAmount,
                members: _totalMembers,
                totalPool: _totalPool,
                duration: _duration,
              ),
              const SizedBox(height: 22),
              AppButton(
                label: 'Create Kameti',
                icon: Icons.check,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Text(value),
      ),
    );
  }
}

class _CalculationCard extends StatelessWidget {
  const _CalculationCard({
    required this.monthlyAmount,
    required this.members,
    required this.totalPool,
    required this.duration,
  });

  final double monthlyAmount;
  final int members;
  final double totalPool;
  final int duration;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _SummaryLine(
                label: 'Monthly Amount',
                value: CurrencyFormatter.pkr(monthlyAmount)),
            _SummaryLine(label: 'Members', value: '$members'),
            _SummaryLine(
                label: 'Total Pool', value: CurrencyFormatter.pkr(totalPool)),
            _SummaryLine(label: 'Duration', value: '$duration months'),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
