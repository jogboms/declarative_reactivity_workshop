import 'package:declarative_reactivity_workshop/async_state.dart';
import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/async_atom.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';

void main() async {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(delayedByTen, (previous, next) {
    log('listen-delayed-by-ten', (previous, next));
  });

  log('await-delayed-by-ten', await container.async(delayedByTen));

  container.invalidate(delayed);

  log('await-delayed-by-ten', await container.async(delayedByTen));
  log('await-delayed', await container.async(delayed));

  container.dispose();
}
