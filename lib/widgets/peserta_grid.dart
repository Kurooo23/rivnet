import 'package:flutter/material.dart';

class PesertaGrid extends StatelessWidget {
  const PesertaGrid({
    super.key,
    required this.columns,
    required this.gap,
    required this.controllers,
  });

  final int columns;
  final double gap;
  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var i = 0; i < controllers.length; i += columns) {
      final cells = <Widget>[];
      for (var c = 0; c < columns; c++) {
        final index = i + c;
        if (c > 0) cells.add(SizedBox(width: gap));
        cells.add(
          Expanded(
            flex: 1,
            child: index < controllers.length
                ? _PesertaField(index: index, controller: controllers[index])
                : const SizedBox.shrink(),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cells,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _PesertaField extends StatelessWidget {
  const _PesertaField({required this.index, required this.controller});

  final int index;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final number = index + 1;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Nama Tim / Pemain $number',
        border: const OutlineInputBorder(),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: CircleAvatar(
            radius: 12,
            child: Text('$number', style: const TextStyle(fontSize: 11)),
          ),
        ),
      ),
      validator: (v) => v == null || v.trim().isEmpty
          ? 'Nama peserta $number tidak boleh kosong'
          : null,
    );
  }
}
