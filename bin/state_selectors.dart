import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';
import 'package:declarative_reactivity_workshop/state.dart';

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(personState.select((state) => state.id), (previous, value) {
    log('listen-person-state-id', (previous, value));
  });
  container.listen(personState.select((state) => state.canDrive), (previous, value) {
    log('listen-person-state-canDrive', (previous, value));
  });
  container.listen(personState.select((state) => state.fullname), (previous, value) {
    log('listen-person-state-fullname', (previous, value));
  });

  for (var i = 0; i < 10; i++) {
    container.mutate(passThrough(1), (value) => 2);
    container.mutate(lastname, (value) => 'v. Last');
    container.mutate(age, (_) => 5);
  }

  container.dispose();
}
