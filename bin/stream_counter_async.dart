import 'dart:async';

import 'package:declarative_reactivity_workshop/async_state.dart';
import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(delayedStreamCounter, (previous, next) {
    log('listen-delayed-stream-counter', (previous, next));
  });

  Future.delayed(const Duration(seconds: 10), container.dispose);
}
