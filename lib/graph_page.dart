import 'dart:math';

import 'package:flutter/material.dart';
import 'package:force_directed_graphview/force_directed_graphview.dart';

import 'src/atom.dart';
import 'src/atom_flutter.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final _controller = GraphController<Node<AtomGraphNode>, Edge<Node<AtomGraphNode>, int>>();

  @override
  void initState() {
    super.initState();

    _controller.mutate((mutator) {
      final graph = AtomWidgetMixin.of(context).container.graph();
      for (final entry in graph.entries) {
        final node = Node(
          data: entry.key,
          size: entry.value.length.toDouble(),
        );
        if (!_controller.nodes.contains(node)) {
          mutator.addNode(node);
        }

        for (final element in entry.value) {
          final other = Node(
            data: element,
            size: graph[element]?.length.toDouble() ?? 0.0,
          );
          if (!_controller.nodes.contains(other)) {
            mutator.addNode(other);
          }

          mutator.addEdge(
            Edge(
              source: node,
              destination: other,
              data: 0,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GraphView<Node<AtomGraphNode>, Edge<Node<AtomGraphNode>, int>>(
        controller: _controller,
        canvasSize: const GraphCanvasSize.fixed(Size.square(1600)),
        edgePainter: const _CustomEdgePainter(),
        layoutAlgorithm: const FruchtermanReingoldAlgorithm(
          iterations: 500,
          showIterations: true,
        ),
        nodeBuilder: (_, node) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 4),
          ),
        ),
        labelBuilder: BottomLabelBuilder(
          builder: (context, node) => Center(
            child: InkWell(
              onTap: () {
                if (node.data.data case final data?) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${node.data.id} = $data'),
                      showCloseIcon: true,
                    ),
                  );
                }
              },
              child: Ink(
                color: node.data.data == null
                    ? Colors.lightBlue.shade700
                    : node.data.source
                        ? Colors.lightGreen.shade700
                        : Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Text(
                  node.data.id,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          labelSize: const Size(240, 24),
        ),
        canvasBackgroundBuilder: (_) => const GridPaper(),
      ),
    );
  }
}

class _CustomEdgePainter implements EdgePainter<Node<AtomGraphNode>, Edge<Node<AtomGraphNode>, int>> {
  const _CustomEdgePainter();

  static const double _arrowSize = 10.0;
  static const _defaultAngle = pi / 6;

  @override
  void paint(
    Canvas canvas,
    Edge<Node<AtomGraphNode>, int> edge,
    Offset sourcePosition,
    Offset destinationPosition,
  ) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;
    canvas.drawLine(sourcePosition, destinationPosition, paint);

    final double midX = (sourcePosition.dx + destinationPosition.dx) / 2;
    final double midY = (sourcePosition.dy + destinationPosition.dy) / 2;

    final double arrowAngle = atan2(
      sourcePosition.dy - destinationPosition.dy,
      sourcePosition.dx - destinationPosition.dx,
    );

    final double x1 = midX - _arrowSize * cos(arrowAngle + _defaultAngle);
    final double y1 = midY - _arrowSize * sin(arrowAngle + _defaultAngle);
    final double x2 = midX - _arrowSize * cos(arrowAngle - _defaultAngle);
    final double y2 = midY - _arrowSize * sin(arrowAngle - _defaultAngle);

    canvas.drawPath(
      Path()
        ..moveTo(midX, midY)
        ..lineTo(x1, y1)
        ..lineTo(x2, y2)
        ..close(),
      paint,
    );
  }
}
