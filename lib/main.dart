import 'package:flutter/material.dart';

import 'async_state.dart';
import 'log.dart';
import 'src/async_atom.dart';
import 'src/atom.dart';
import 'src/atom_flutter.dart';
import 'state.dart';

void main() {
  runApp(const AtomScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    log('rebuild', 'app');

    const fontSize = 24.0;
    final theme = ThemeData.light(useMaterial3: true);
    final textTheme = theme.textTheme;

    return MaterialApp(
      theme: theme.copyWith(
        textTheme: textTheme.copyWith(
          bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: fontSize),
          bodyLarge: textTheme.bodyLarge?.copyWith(fontSize: fontSize),
          labelLarge: textTheme.labelLarge?.copyWith(fontSize: fontSize),
        ),
      ),
      home: const Page(),
    );
  }
}

class Page extends StatefulWidget {
  const Page({super.key});

  @override
  State<Page> createState() => _PageState();
}

class _PageState extends State<Page> {
  AtomSubscription<double>? _doubleAgeSub;
  bool _showSelectors = false;

  @override
  void initState() {
    _doubleAgeSub = context.listenManual(doubleAge, (previous, next) {
      log('listen-double-age', (previous, next));
    });
    super.initState();
  }

  @override
  void dispose() {
    _doubleAgeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.listen(age, (previous, next) {
      log('listen-age', (previous, next));
    });

    log('rebuild', 'page');

    const spacing = SizedBox(height: 8);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Row(
            children: [
              Expanded(
                child: AtomScope(
                  child: AtomBuilder(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Age: ${context.get(age)}'),
                        spacing,
                        TextButton(
                          onPressed: () => context.mutate(age, (value) => value + 10),
                          child: const Text('mutate age += 10'),
                        ),
                        spacing,
                        TextButton(
                          onPressed: () => context.invalidate(age),
                          child: const Text('invalidate age'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AtomBuilder(
                      builder: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('DoubleAge: ${context.get(doubleAge)}'),
                          spacing,
                          Text('Result: ${context.get(result)}'),
                          spacing,
                          Text('PassThrough: ${context.get(passThrough(1))}'),
                        ],
                      ),
                    ),
                    spacing,
                    AtomBuilder(
                      builder: (context) => Text('Counter: ${context.get(counter)}'),
                    ),
                    if (_showSelectors) ...[
                      spacing,
                      AtomBuilder(
                        builder: (context) {
                          log('rebuild', 'id-selector');
                          return Text(
                            'PersonState (id): ${context.get(personState.select((state) => state.id))}',
                          );
                        },
                      ),
                      spacing,
                      AtomBuilder(
                        builder: (context) {
                          log('rebuild', 'can-drive-selector');
                          return Text(
                            'PersonState (canDrive): ${context.get(personState.select((state) => state.canDrive))}',
                          );
                        },
                      ),
                      spacing,
                      AtomBuilder(
                        builder: (context) {
                          log('rebuild', 'fullname-selector');
                          return Text(
                            'PersonState (fullname): ${context.get(personState.select((state) => state.fullname))}',
                          );
                        },
                      ),
                    ],
                    spacing,
                    AtomBuilder(
                      builder: (context) => context.get(delayed).when(
                            loading: () => const Text('Delayed: Loading..'),
                            refreshing: (data) => Text('Delayed: Refreshing... ($data)'),
                            data: (data) => Text('Delayed: $data'),
                            error: (error, _) => Text('Delayed: Error: $error'),
                          ),
                    ),
                    spacing,
                    AtomBuilder(
                      builder: (context) => context.get(delayedByTen).when(
                            loading: () => const Text('DelayedByTen: Loading..'),
                            refreshing: (data) => Text('DelayedByTen: Refreshing... ($data)'),
                            data: (data) => Text('DelayedByTen: $data'),
                            error: (error, _) => Text('DelayedByTen: Error: $error'),
                          ),
                    ),
                    spacing,
                    AtomBuilder(
                      builder: (context) => context.get(delayedStream).when(
                            loading: () => const Text('DelayedStream: Loading..'),
                            refreshing: (data) => Text('DelayedStream: Refreshing... ($data)'),
                            data: (data) => Text('DelayedStream: $data'),
                            error: (error, _) => Text('DelayedStream: Error: $error'),
                          ),
                    ),
                    spacing,
                    AtomBuilder(
                      builder: (context) => context.get(delayedStreamByTen).when(
                            loading: () => const Text('DelayedStreamByTen: Loading..'),
                            refreshing: (data) => Text('DelayedStreamByTen: Refreshing... ($data)'),
                            data: (data) => Text('DelayedStreamByTen: $data'),
                            error: (error, _) => Text('DelayedStreamByTen: Error: $error'),
                          ),
                    ),
                    spacing,
                    AtomBuilder(
                      builder: (context) => context.get(delayedStreamCounter).when(
                            loading: () => const Text('DelayedStreamCounter: Loading..'),
                            refreshing: (data) => Text('DelayedStreamCounter: Refreshing... ($data)'),
                            data: (data) => Text('DelayedStreamCounter: $data'),
                            error: (error, _) => Text('DelayedStreamCounter: Error: $error'),
                          ),
                    ),
                    spacing,
                    AtomBuilder(
                      builder: (context) {
                        log('rebuild', 'delayed-stream-counter-modulo-selector');
                        return context.get(delayedStreamCounter.selectAsync((value) => value % 5 == 0)).when(
                              loading: () => const Text('DelayedStreamCounter % 5 == 0: Loading..'),
                              refreshing: (data) => Text('DelayedStreamCounter % 5 == 0: Refreshing... ($data)'),
                              data: (data) => Text('DelayedStreamCounter % 5 == 0: $data'),
                              error: (error, _) => Text('DelayedStreamCounter % 5 == 0: Error: $error'),
                            );
                      },
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.mutate(age, (value) => value + 1),
                    child: const Text('mutate age += 1'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.mutate(lastname, (value) => 'v. $value'),
                    child: const Text('mutate lastname'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context
                      ..invalidate(age)
                      ..invalidate(lastname),
                    child: const Text('invalidate age + lastname'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.mutate(passThrough(1), (value) => value + 1),
                    child: const Text('mutate passThrough += 1'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.invalidate(passThrough(1)),
                    child: const Text('invalidate passThrough'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.invalidate(counter),
                    child: const Text('invalidate counter'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.invalidate(delayed),
                    child: const Text('invalidate delayed'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.invalidate(delayedByTen),
                    child: const Text('invalidate delayedByTen'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.invalidate(delayedStream),
                    child: const Text('invalidate delayedStream'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.invalidate(delayedStreamByTen),
                    child: const Text('invalidate delayedStreamByTen'),
                  ),
                  spacing,
                  TextButton(
                    onPressed: () => context.invalidate(delayedStreamCounter),
                    child: const Text('invalidate delayedStreamCounter'),
                  ),
                  spacing,
                  const Divider(),
                  spacing,
                  SizedBox(
                    width: 300,
                    child: CheckboxListTile.adaptive(
                      value: _showSelectors,
                      title: const Text('Show Selectors?'),
                      onChanged: (value) => setState(() => _showSelectors = value == true),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
