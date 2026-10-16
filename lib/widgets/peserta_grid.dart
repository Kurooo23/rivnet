import 'package:flutter/material.dart';

class PesertaGrid extends StatelessWidget {
  final int columns;
  final double gap;
  final List<TextEditingController> controllers;

  const PesertaGrid({
    super.key,
    required this.columns,
    required this.gap,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (var rowStart = 0; rowStart < controllers.length; rowStart += columns) {
      final rowFields = <Widget>[];
      for (var column = 0; column < columns; column++) {
        final fieldIndex = rowStart + column;
        if (column > 0) rowFields.add(SizedBox(width: gap));
        rowFields.add(
          Expanded(
            child: fieldIndex < controllers.length
                ? _PesertaField(
                    index: fieldIndex,
                    controller: controllers[fieldIndex],
                  )
                : const SizedBox.shrink(),
          ),
        );
      }
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rowFields,
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _PesertaField extends StatelessWidget {
  final int index;
  final TextEditingController controller;

  const _PesertaField({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    final number = index + 1;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Nama Tim / Pemain $number',
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
