import 'package:declarative_reactivity_workshop/async_state.dart';
import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/async_atom.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';

void main() async {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(delayedStreamByTen, (previous, next) {
    log('listen-delayed-stream-by-ten', (previous, next));
  });

  log('await-delayed-stream-by-ten', await container.async(delayedStreamByTen));
  log('await-delayed-stream', await container.async(delayedStream));

  container.invalidate(delayed);

  log('await-delayed-stream-by-ten', await container.async(delayedStreamByTen));
  log('await-delayed-stream', await container.async(delayedStream));
  log('await-delayed', await container.async(delayed));

  container.dispose();
}
