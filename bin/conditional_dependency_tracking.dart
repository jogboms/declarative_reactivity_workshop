import 'dart:async';

import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';
import 'package:declarative_reactivity_workshop/state.dart';

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(maybeTrackAge, (previous, value) {
    log('listen-maybe-track-age', (previous, value));
  });

  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (timer.tick % 3 == 0) {
      container.mutate(shouldTrackAge, (value) => !value);
    }

    container.mutate(age, (value) => value + 1);
  });

  Future.delayed(const Duration(seconds: 10), container.dispose);
}
