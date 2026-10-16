import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'section_card.dart';

class KuotaSection extends StatelessWidget {
  const KuotaSection({
    super.key,
    required this.kuota,
    required this.format,
    required this.isElimination,
    required this.options,
    required this.onChanged,
    required this.onCustom,
  });

  final int kuota;
  final String format;
  final bool isElimination;
  final List<int> options;
  final ValueChanged<int> onChanged;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final hint = switch (format) {
      'Single Elimination' => 'Single Elimination wajib pangkat 2 (min. 2):',
      _ => 'Pilih preset atau tentukan sendiri, minimal 2 peserta:',
    };
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jumlah Kuota Peserta',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$kuota Peserta',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            HintText(hint),
            const SizedBox(height: 10),
            if (!isElimination) ...[
              Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Kurangi 1',
                    onPressed: kuota > 2 ? () => onChanged(kuota - 1) : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '$kuota',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Tambah 1',
                    onPressed: () => onChanged(kuota + 1),
                    icon: const Icon(Icons.add_rounded),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCustom,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text(
                        'Input Angka Lain',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in options)
                  ChoiceChip(
                    label: Text('$option'),
                    selected: kuota == option,
                    onSelected: (_) => onChanged(option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class KuotaDialog extends StatefulWidget {
  const KuotaDialog({super.key, required this.initial});

  final int initial;

  @override
  State<KuotaDialog> createState() => _KuotaDialogState();
}

class _KuotaDialogState extends State<KuotaDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 2) {
      setState(() => _error = 'Minimal 2 peserta');
      return;
    }
    Get.back(result: value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Jumlah Kuota Peserta'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'cth: 7',
          suffixText: 'Peserta',
          errorText: _error,
        ),
        onSubmitted: (_) => _apply(),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        FilledButton(onPressed: _apply, child: const Text('Terapkan')),
      ],
    );
  }
}
