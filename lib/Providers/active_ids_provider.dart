// lib/providers/active_ids_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _ActiveIds extends StateNotifier<Set<String>> {
  _ActiveIds() : super({});

  void add(String id) => state = {...state, id};
  void remove(String id) => state = state.where((e) => e != id).toSet();
}

final activeDispatchIdsProvider =
    StateNotifierProvider<_ActiveIds, Set<String>>((_) => _ActiveIds());
