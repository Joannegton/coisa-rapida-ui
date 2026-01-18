import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../shared/providers/shared_preference_provider.dart';

part 'theme_provider.g.dart';

@riverpod
class Theme extends _$Theme {
  static const String _key = 'theme_preference';

  @override
  ThemeMode build() {
    final prefs = ref.read(sharedPrefsProvider);
    final temaIndex = prefs.getInt(_key);

    if (temaIndex == null) {
      return ThemeMode.system;
    }

    return ThemeMode.values[temaIndex];
  }

  Future<void> alterarTema(ThemeMode novoTema) async {
    state = novoTema;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setInt(_key, novoTema.index);
  }

  Future<void> resetarParaSistema() async {
    state = ThemeMode.system;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(_key);
  }
}
