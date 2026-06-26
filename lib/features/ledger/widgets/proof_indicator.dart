import 'package:flutter/material.dart';

class ProofIndicator extends StatelessWidget {
  const ProofIndicator({required this.proofPath, super.key});
  final String proofPath;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
            proofPath.isEmpty
                ? Icons.attachment_outlined
                : Icons.verified_outlined,
            size: 16),
        const SizedBox(width: 4),
        Text(proofPath.isEmpty ? 'No proof' : 'Proof attached'),
      ],
    );
  }
}
