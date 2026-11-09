/// Global save-state provider for persisting playback progress before exit.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SaveStateNotifier extends Notifier<Future<void> Function()?> {
  @override
  Future<void> Function()? build() => null;

  void setCallback(Future<void> Function()? callback) => state = callback;
}

final saveStateProvider =
    NotifierProvider<SaveStateNotifier, Future<void> Function()?>(
        SaveStateNotifier.new);

