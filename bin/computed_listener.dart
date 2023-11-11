import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';
import 'package:declarative_reactivity_workshop/state.dart';

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(doubleAge, (previous, value) {
    log('listen-double-age', (previous, value));
  });

  container.mutate(age, (value) => value + 1);

  container.dispose();
}
