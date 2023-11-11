import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';
import 'package:declarative_reactivity_workshop/state.dart';

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  log('result', container.get(result));

  container.mutate(age, (value) => value + 1);

  log('result', container.get(result));

  container.invalidate(age);

  log('result', container.get(result));

  container.mutate(age, (value) => value + 2);

  log('result', container.get(result));

  container.mutate(lastname, (value) => 'v. $value');

  log('result', container.get(result));

  container.dispose();
}
