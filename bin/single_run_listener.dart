import 'package:declarative_reactivity_workshop/log.dart';
import 'package:declarative_reactivity_workshop/src/atom.dart';

final a = Atom((_) => 'A');
final b = Atom((_) => 'B');
final c = Atom((context) => '${context.get(a)}/${context.get(b)}');
final d = Atom((context) => context.get(c));
final e = Atom((context) => '${context.get(b)}/${context.get(d)}');

void main() {
  final container = AtomContainer() //
    ..onDispose(() => log('on-dispose-container', 0));

  container.listen(e, (previous, value) {
    log('listen-e', (previous, value));
  });

  container.mutate(b, (value) => '$value+');

  container.dispose();
}
