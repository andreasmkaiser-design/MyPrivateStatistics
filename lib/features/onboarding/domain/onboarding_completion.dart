import 'package:flutter/foundation.dart';

/// The user's choice on onboarding Screen 3.
enum SeedChoice {
  /// Seed the database with pre-built Sleep and Sport category trees.
  exampleCategories,

  /// Start with an empty category list.
  empty,
}

/// Minimal shared state produced by the onboarding wizard.
///
/// Only state that must survive wizard completion is held here.
/// Per-screen transient state (e.g. HC permission result) lives in the
/// individual screen widgets.
@immutable
class OnboardingCompletion {
  /// Creates an [OnboardingCompletion].
  const OnboardingCompletion({this.seedChoice, this.isDone = false});

  /// The choice the user made on Screen 3; `null` until they choose or skip.
  final SeedChoice? seedChoice;

  /// Whether the wizard has been completed or skipped.
  final bool isDone;

  /// Returns a copy with the given fields replaced.
  OnboardingCompletion copyWith({SeedChoice? seedChoice, bool? isDone}) =>
      OnboardingCompletion(
        seedChoice: seedChoice ?? this.seedChoice,
        isDone: isDone ?? this.isDone,
      );
}
