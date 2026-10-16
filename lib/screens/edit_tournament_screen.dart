import 'package:flutter/material.dart';
import 'package:rivnet/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:rivnet/database/database_helper.dart';
import 'package:rivnet/models/tournament.dart';
import 'package:rivnet/widgets/page_layout.dart';
import 'package:rivnet/widgets/section_card.dart';

const _statusOptions = ['Akan Datang', 'Berlangsung', 'Selesai'];

class EditTournamentScreen extends StatefulWidget {
  final Tournament tournament;

  const EditTournamentScreen({super.key, required this.tournament});

  @override
  State<EditTournamentScreen> createState() => _EditTournamentScreenState();
}

class _EditTournamentScreenState extends State<EditTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _namaController = TextEditingController(
    text: widget.tournament.name,
  );
  late final _deskripsiController = TextEditingController(
    text: widget.tournament.deskripsi ?? '',
  );
  late final String _gameType = widget.tournament.game;
  late String _selectedStatus = widget.tournament.status;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final deskripsiText = _deskripsiController.text.trim();
      final deskripsi = deskripsiText.isEmpty ? null : deskripsiText;

      await DatabaseHelper.instance.updateTournament(
        id: widget.tournament.id!,
        name: _namaController.text.trim(),
        deskripsi: deskripsi,
        game: _gameType,
        status: _selectedStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Turnamen berhasil diperbarui!'),
          backgroundColor: AppColors.success,
        ),
      );
      Get.back(result: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui turnamen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'Selesai' => AppColors.success,
      'Berlangsung' => AppColors.warning,
      _ => AppColors.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final layout = PageLayout.of(context);
    final sectionGap = layout.isShort ? 14.0 : 20.0;

    final infoSection = SectionCard(
      icon: Icons.info_outline_rounded,
      title: 'Informasi Turnamen',
      children: [
        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: 'Nama Turnamen',
            hintText: 'Masukkan nama turnamen',
            prefixIcon: Icon(Icons.emoji_events_rounded),
          ),
          validator: (val) => val == null || val.trim().isEmpty
              ? 'Nama turnamen wajib diisi'
              : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _deskripsiController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Deskripsi (Opsional)',
            hintText: 'Tuliskan catatan atau aturan turnamen...',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
      ],
    );

    final settingSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          icon: Icons.sports_soccer_rounded,
          title: 'Tipe Game / Cabang Olahraga',
          children: [
            Chip(
              avatar: const Icon(Icons.sports_soccer_rounded, size: 18),
              label: Text(_gameType),
            ),
          ],
        ),
        SizedBox(height: sectionGap),
        SectionCard(
          icon: Icons.toggle_on_rounded,
          title: 'Status Turnamen',
          children: [
            const Text(
              'Ubah Status Turnamen:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _statusOptions)
                  ChoiceChip(
                    label: Text(option),
                    selected: _selectedStatus == option,
                    selectedColor: _statusColor(option).withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: _selectedStatus == option
                          ? _statusColor(option)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() {
                      _selectedStatus = option;
                    }),
                  ),
              ],
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Turnamen'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: layout.sidePadding,
              vertical: sectionGap,
            ),
            children: [
              PairRow(
                isWide: layout.isWide,
                gap: layout.gap,
                left: infoSection,
                right: settingSection,
              ),
              SizedBox(height: sectionGap + 8),
              FilledButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
