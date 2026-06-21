import 'dart:async';

import 'package:flutter/material.dart';

import '../../member/models/member_model.dart';

class AnimatedNameSelector extends StatefulWidget {
  const AnimatedNameSelector({
    required this.members,
    required this.winner,
    required this.onFinished,
    super.key,
  });

  final List<MemberModel> members;
  final MemberModel winner;
  final VoidCallback onFinished;

  @override
  State<AnimatedNameSelector> createState() => _AnimatedNameSelectorState();
}

class _AnimatedNameSelectorState extends State<AnimatedNameSelector> {
  late String _name = widget.members.first.fullName;
  int _ticks = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _name = widget.members[_ticks % widget.members.length].fullName;
        _ticks++;
      });
      if (_ticks > 24) {
        timer.cancel();
        setState(() => _name = widget.winner.fullName);
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: Text(
            _name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
