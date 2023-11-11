import 'dart:async';

import 'log.dart';
import 'src/atom.dart';

final firstname = Atom((_) => 'First');
final lastname = Atom((_) => 'Last');
final age = Atom((_) => 0);

final doubleAge = Atom((context) => context.get(age) * 2.0);
final result = Atom((context) => '${context.get(firstname)} ${context.get(lastname)} (${context.get(age)})');

final passThrough = Atom.family((_, int value) => value);

final personState = Atom(
  (context) => (
    id: context.get(passThrough(1)),
    fullname: '${context.get(firstname)} ${context.get(lastname)}',
    canDrive: context.get(age) > 4,
  ),
);

final counter = Atom((AtomContext<int> context) {
  final timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
    final value = context.mutateSelf((value) => (value ?? 0) + 1);

    if (value == 10) {
      context.invalidateSelf();
    }
  });

  context.onDispose(() {
    timer.cancel();
  });

  return 0;
});

final shouldTrackAge = Atom((_) => true);
final maybeTrackAge = Atom((context) {
  log('rebuild', 'maybe-track-age');
  if (context.get(shouldTrackAge)) {
    return context.get(age);
  }
  return -1;
});
