import 'package:flutter/material.dart';

const pairFlex = [1, 1]; // section kiri : kanan (layar lebar)

class PairRow extends StatelessWidget {
  const PairRow({
    super.key,
    required this.isWide,
    required this.gap,
    required this.left,
    required this.right,
  });

  final bool isWide;
  final double gap;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        children: [
          left,
          SizedBox(height: gap),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: pairFlex[0], child: left),
        SizedBox(width: gap),
        Expanded(flex: pairFlex[1], child: right),
      ],
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class HintText extends StatelessWidget {
  const HintText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(fontStyle: FontStyle.italic),
    );
  }
}
