import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kameti_model.dart';

class KametiController extends StateNotifier<List<KametiModel>> {
  KametiController() : super(const []);

  void createKameti(KametiModel kameti) {
    state = [kameti, ...state];
  }

  KametiModel? byId(String id) {
    for (final kameti in state) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }

  void updateStatus(String id, KametiStatus status) {
    state = [
      for (final kameti in state)
        if (kameti.id == id) kameti.copyWith(status: status) else kameti,
    ];
  }
}

final kametiControllerProvider =
    StateNotifierProvider<KametiController, List<KametiModel>>((ref) {
  return KametiController();
});
