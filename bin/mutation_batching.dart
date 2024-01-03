import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';
import 'package:declarative_reactivity_workshop/state.dart';

void main() async {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(age, (previous, value) {
    log('listen-age', (previous, value));
  });

  container.mutate(age, (_) => 2);

  container.batch((context) {
    context
      ..mutate(age, (value) => value + 1)
      ..mutate(age, (value) => value + 1)
      ..mutate(age, (value) => value + 1);

    log('batch-double-age', context.get(doubleAge));
  });

  container.batch((context) {
    throw StateError('maybe?');
  });

  await container.batch((context) async {
    context.invalidate(age);

    await Future.delayed(const Duration(seconds: 1));

    context.mutate(age, (value) => value + 1);
  });

  container.mutate(age, (value) => value + 1);

  log('age', container.get(age));
  log('double-age', container.get(doubleAge));

  log(
    'batch-result',
    container.batch(
      (context) => context.mutate(
        age,
        (value) => value * 10,
      ),
    ),
  );

  container.dispose();
}
