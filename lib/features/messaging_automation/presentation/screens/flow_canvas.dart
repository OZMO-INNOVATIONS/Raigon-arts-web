import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raigon_art/features/messaging_automation/presentation/screens/automation_ui.dart';
import 'package:raigon_art/features/messaging_automation/providers/messaging_automation_provider.dart';

const double _nodeW = 220;
const double _nodeH = 92;
const double _canvasW = 1100;
const double _canvasH = 460;

/// Drag nodes, tap a node to edit, tap an output port (right) then an
/// input port (left) to connect. Tap a connection's midpoint dot to remove it.
class FlowCanvas extends StatelessWidget {
  const FlowCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MessagingAutomationProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AutoButton(
              label: 'Condition',
              icon: Icons.add,
              filled: false,
              onPressed: () => p.addNode(NodeType.condition),
            ),
            AutoButton(
              label: 'Send message',
              icon: Icons.add,
              filled: false,
              onPressed: () => p.addNode(NodeType.message),
            ),
            AutoButton(label: 'Reset', filled: false, onPressed: p.resetFlow),
            AutoButton(
              label: 'Save flow',
              icon: Icons.save_outlined,
              onPressed: () {
                p.saveFlow();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flow saved locally')),
                );
              },
            ),
            if (p.pendingFrom != null)
              Text('Now tap an input port (left dot) to connect',
                  style: TextStyle(color: AutoInk.purple, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: _canvasH,
          decoration: BoxDecoration(
            color: AutoInk.panel(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AutoInk.line(context)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _canvasW,
              height: _canvasH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter(AutoInk.line(context))),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _EdgePainter(p.nodes, p.edges),
                    ),
                  ),
                  // edge delete handles
                  for (final e in p.edges) _edgeHandle(p, e),
                  for (final n in p.nodes) _node(context, p, n),
                ],
              ),
            ),
          ),
        ),
        if (p.flowSavedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Last saved ${TimeOfDay.fromDateTime(p.flowSavedAt!).format(context)}',
                style: TextStyle(color: AutoInk.muted(context), fontSize: 12)),
          ),
      ],
    );
  }

  Widget _edgeHandle(MessagingAutomationProvider p, FlowEdge e) {
    final a = p.nodeById(e.from);
    final b = p.nodeById(e.to);
    if (a == null || b == null) return const SizedBox.shrink();
    final start = a.position + const Offset(_nodeW, _nodeH / 2);
    final end = b.position + const Offset(0, _nodeH / 2);
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    return Positioned(
      left: mid.dx - 10,
      top: mid.dy - 10,
      child: GestureDetector(
        onTap: () => p.removeEdge(e),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(Icons.close, size: 12, color: AutoInk.purple),
        ),
      ),
    );
  }

  Widget _node(BuildContext context, MessagingAutomationProvider p, FlowNode n) {
    final (color, icon) = switch (n.type) {
      NodeType.trigger => (AutoInk.blue, Icons.bolt),
      NodeType.condition => (const Color(0xFFE59A12), Icons.call_split),
      NodeType.message => (AutoInk.purple, Icons.chat_bubble_outline),
    };
    final pending = p.pendingFrom == n.id;

    return Positioned(
      left: n.position.dx,
      top: n.position.dy,
      child: SizedBox(
        width: _nodeW,
        height: _nodeH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (d) => p.moveNode(n.id, d.delta),
                onTap: () => _editDialog(context, p, n),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AutoInk.card(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color, width: pending ? 2.5 : 1.4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: AutoInk.text(context),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(n.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: AutoInk.muted(context), fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (n.type != NodeType.trigger)
              Positioned(
                left: -12,
                top: _nodeH / 2 - 12,
                child: _port(() => p.tapInput(n.id), color, false),
              ),
            Positioned(
              right: -12,
              top: _nodeH / 2 - 12,
              child: _port(() => p.tapOutput(n.id), color, pending),
            ),
          ],
        ),
      ),
    );
  }

  Widget _port(VoidCallback onTap, Color color, bool active) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 24,
          height: 24,
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: active ? color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
              ),
            ),
          ),
        ),
      );

  Future<void> _editDialog(
      BuildContext context, MessagingAutomationProvider p, FlowNode n) async {
    final title = TextEditingController(text: n.title);
    final sub = TextEditingController(text: n.subtitle);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit node'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(
              controller: sub,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
          ],
        ),
        actions: [
          if (n.type != NodeType.trigger)
            TextButton(
              onPressed: () {
                p.removeNode(n.id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              p.editNode(n.id, title.text.trim(), sub.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    title.dispose();
    sub.dispose();
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double x = 12; x < size.width; x += 24) {
      for (double y = 12; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.nodes, this.edges);
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;

  FlowNode? _find(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AutoInk.purple
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = AutoInk.purple;

    for (final e in edges) {
      final a = _find(e.from);
      final b = _find(e.to);
      if (a == null || b == null) continue;
      final s = a.position + const Offset(_nodeW, _nodeH / 2);
      final t = b.position + const Offset(0, _nodeH / 2);
      final dx = (t.dx - s.dx).abs().clamp(60.0, 200.0) / 2;
      final path = Path()
        ..moveTo(s.dx, s.dy)
        ..cubicTo(s.dx + dx, s.dy, t.dx - dx, t.dy, t.dx, t.dy);
      canvas.drawPath(path, line);
      canvas.drawCircle(t, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) => true;
}
