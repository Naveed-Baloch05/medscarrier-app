import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeLight()) {
    on<ThemeLoaded>(_onLoaded);
    on<ThemeToggled>(_onToggled);
  }

  static const String _key = 'theme_mode';

  Future<void> _onLoaded(
    ThemeLoaded event,
    Emitter<ThemeState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;

    emit(isDark ? ThemeDark() : ThemeLight());
  }

  Future<void> _onToggled(
    ThemeToggled event,
    Emitter<ThemeState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state is ThemeDark;

    await prefs.setBool(_key, !isDark);

    emit(isDark ? ThemeLight() : ThemeDark());
  }
}
