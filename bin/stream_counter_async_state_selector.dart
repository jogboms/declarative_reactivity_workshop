import 'package:declarative_reactivity_workshop/async_state.dart';
import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/async_atom.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';

void main() async {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(
    delayedStreamCounter.selectAsync(
      (value) => value % 5 == 0,
    ),
    (_, value) {
      log('listen-delayed-stream-counter-selector', (
        container.get(delayedStreamCounter),
        value,
      ));
    },
  );

  Future.delayed(const Duration(seconds: 15), container.dispose);
}
