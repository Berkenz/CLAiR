import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kTutorialCompleted = 'tutorial_completed';

class TutorialState {
  final bool show;
  final int step;
  final int totalSteps;

  const TutorialState({
    this.show = false,
    this.step = 0,
    this.totalSteps = 5,
  });

  bool get isFirst => step == 0;
  bool get isLast => step >= totalSteps - 1;

  TutorialState copyWith({bool? show, int? step}) => TutorialState(
        show: show ?? this.show,
        step: step ?? this.step,
        totalSteps: totalSteps,
      );
}

class TutorialNotifier extends StateNotifier<TutorialState> {
  TutorialNotifier() : super(const TutorialState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_kTutorialCompleted) ?? false;
    if (!completed) {
      state = state.copyWith(show: true, step: 0);
    }
  }

  void next() {
    if (state.isLast) {
      finish();
    } else {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void back() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  Future<void> finish() async {
    state = state.copyWith(show: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTutorialCompleted, true);
  }

  Future<void> skip() => finish();

  /// Re-enable tutorial (e.g. from settings).
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTutorialCompleted);
    state = state.copyWith(show: true, step: 0);
  }
}

final tutorialProvider =
    StateNotifierProvider<TutorialNotifier, TutorialState>(
  (_) => TutorialNotifier(),
);
