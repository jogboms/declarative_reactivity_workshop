import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';
import 'package:declarative_reactivity_workshop/state.dart';

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  log('pass-through', container.get(passThrough(1)));

  container.mutate(passThrough(1), (value) => value + 1);

  log('pass-through', container.get(passThrough(1)));

  container.dispose();
}
