import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';
import 'package:declarative_reactivity_workshop/state.dart';

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(counter, (previous, value) {
    log('listen-counter', (previous, value));
  });

  Future.delayed(const Duration(seconds: 10), container.dispose);
}
