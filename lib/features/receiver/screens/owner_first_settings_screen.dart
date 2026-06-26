import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';

class OwnerFirstSettingsScreen extends ConsumerWidget {
  const OwnerFirstSettingsScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), kametiId);
    if (kameti == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Owner First Settings')),
          body: const Center(child: Text('Kameti not found')));
    }
    var ownerFirst = kameti.ownerReceivesFirstCycle;
    var requirePayment = kameti.requirePaymentBeforeReceiving;
    var mode = kameti.afterOwnerAllocationMode;
    return StatefulBuilder(
      builder: (context, setState) => Scaffold(
        appBar: AppBar(title: const Text('Owner First Settings')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                value: ownerFirst,
                onChanged: (value) => setState(() => ownerFirst = value),
                title: const Text('Owner receives first cycle'),
              ),
              SwitchListTile(
                value: requirePayment,
                onChanged: (value) => setState(() => requirePayment = value),
                title: const Text('Require payment before receiving'),
              ),
              DropdownButtonFormField<AfterOwnerAllocationMode>(
                initialValue: mode,
                decoration: const InputDecoration(
                    labelText: 'After owner allocation mode'),
                items: AfterOwnerAllocationMode.values
                    .map((item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)))
                    .toList(),
                onChanged: (value) => setState(() => mode = value ?? mode),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Settings',
                icon: Icons.save_outlined,
                onPressed: () {
                  ref
                      .read(kametiControllerProvider.notifier)
                      .updateReceiverSettings(
                        id: kameti.id,
                        ownerReceivesFirstCycle: ownerFirst,
                        requirePaymentBeforeReceiving: requirePayment,
                        afterOwnerAllocationMode: mode,
                      );
                  SnackbarHelper.showSuccess(
                      context, 'Owner first settings saved.');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }
}
