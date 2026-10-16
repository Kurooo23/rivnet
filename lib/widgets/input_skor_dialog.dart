import 'package:flutter/material.dart';
import 'package:rivnet/theme/app_colors.dart';
import 'package:get/get.dart';
import 'package:rivnet/models/match.dart';

class InputSkorDialog extends StatefulWidget {
  final Pertandingan match;
  final Map<String, String> pesertaMap;
  final bool isKnockout;
  final bool isTwoLeg;
  final int? previousLegScore1;
  final int? previousLegScore2;
  final Future<void> Function(
    Pertandingan match,
    int skor1,
    int skor2,
    int? penalti1,
    int? penalti2,
  )
  onSaved;

  const InputSkorDialog({
    super.key,
    required this.match,
    required this.pesertaMap,
    this.isKnockout = false,
    this.isTwoLeg = false,
    this.previousLegScore1,
    this.previousLegScore2,
    required this.onSaved,
  });

  @override
  State<InputSkorDialog> createState() => _InputSkorDialogState();
}

class _InputSkorDialogState extends State<InputSkorDialog> {
  late int _score1 = widget.match.skor1;
  late int _score2 = widget.match.skor2;
  late String _status = widget.match.status == 'Belum Mulai'
      ? 'Berlangsung'
      : widget.match.status;
  bool _isSaving = false;

  late final _penalty1Controller = TextEditingController(
    text: widget.match.penalti1 != null ? '${widget.match.penalti1}' : '',
  );
  late final _penalty2Controller = TextEditingController(
    text: widget.match.penalti2 != null ? '${widget.match.penalti2}' : '',
  );

  @override
  void dispose() {
    _penalty1Controller.dispose();
    _penalty2Controller.dispose();
    super.dispose();
  }

  // Adu penalti hanya berlaku untuk hasil imbang pada babak gugur.
  bool get _needsPenaltyShootout {
    if (!widget.isKnockout || _status != 'Selesai') return false;

    if (!widget.isTwoLeg) return _score1 == _score2;

    if (!widget.match.babak.startsWith('Leg 2 - ')) return false;

    final prev1 = widget.previousLegScore1 ?? 0;
    final prev2 = widget.previousLegScore2 ?? 0;

    final aggregate1 = _score1 + prev1;
    final aggregate2 = _score2 + prev2;

    return aggregate1 == aggregate2;
  }

  Future<void> _submit() async {
    int? penaltyScore1;
    int? penaltyScore2;

    if (_needsPenaltyShootout) {
      penaltyScore1 = int.tryParse(_penalty1Controller.text.trim());
      penaltyScore2 = int.tryParse(_penalty2Controller.text.trim());

      if (penaltyScore1 == null || penaltyScore2 == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Skor imbang pada babak gugur wajib diisi adu penalti.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (penaltyScore1 == penaltyScore2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adu penalti tidak boleh imbang.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });
    try {
      await widget.onSaved(
        widget.match,
        _score1,
        _score2,
        penaltyScore1,
        penaltyScore2,
      );
      if (!mounted) return;
      Get.back();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan skor: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _statusOption(String status) {
    final selected = _status == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _status = status;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.white10,
            ),
          ),
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final scoreFontSize = (screen.width * 0.08).clamp(24.0, 36.0);

    final firstParticipantName = widget.match.idPeserta1 != null
        ? (widget.pesertaMap[widget.match.idPeserta1] ?? 'TBD')
        : 'TBD';
    final secondParticipantName = widget.match.idPeserta2 != null
        ? (widget.pesertaMap[widget.match.idPeserta2] ?? 'TBD')
        : 'TBD';

    bool isP1Leading = false;
    bool isP2Leading = false;

    if (_status == 'Selesai') {
      if (widget.isTwoLeg && widget.match.babak.startsWith('Leg 2 - ')) {
        final prev1 = widget.previousLegScore1 ?? 0;
        final prev2 = widget.previousLegScore2 ?? 0;
        final aggregate1 = _score1 + prev1;
        final aggregate2 = _score2 + prev2;
        isP1Leading = aggregate1 > aggregate2;
        isP2Leading = aggregate2 > aggregate1;
      } else {
        isP1Leading = _score1 > _score2;
        isP2Leading = _score2 > _score1;
      }
    }

    final card1 = _ScoreCard(
      name: firstParticipantName,
      score: '$_score1',
      scoreFontSize: scoreFontSize,
      isLeading: isP1Leading,
      onIncrement: () => setState(() {
        _score1++;
      }),
      onDecrement: () {
        if (_score1 > 0) {
          setState(() {
            _score1--;
          });
        }
      },
    );

    final card2 = _ScoreCard(
      name: secondParticipantName,
      score: '$_score2',
      scoreFontSize: scoreFontSize,
      isLeading: isP2Leading,
      onIncrement: () => setState(() {
        _score2++;
      }),
      onDecrement: () {
        if (_score2 > 0) {
          setState(() {
            _score2--;
          });
        }
      },
    );

    return Dialog(
      backgroundColor: AppColors.backgroundAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.05,
        vertical: screen.height * 0.04,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: EdgeInsets.all((screen.width * 0.05).clamp(14.0, 22.0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sports_score_rounded,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Input Skor - ${widget.match.babak}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: screen.width < 360 ? 15 : 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    tooltip: 'Tutup',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 20),

              if (screen.width < 330)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [card1, const _VsLabel(vertical: true), card2],
                )
              else
                Row(
                  children: [
                    Expanded(child: card1),
                    const _VsLabel(vertical: false),
                    Expanded(child: card2),
                  ],
                ),
              const SizedBox(height: 20),

              const Text(
                'Status Pertandingan',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statusOption('Berlangsung'),
                  const SizedBox(width: 10),
                  _statusOption('Selesai'),
                ],
              ),

              if (_needsPenaltyShootout) ...[
                const SizedBox(height: 16),
                const Text(
                  'Agregat Seri — Skor Adu Penalti Wajib Diisi:',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PenaltyField(
                        controller: _penalty1Controller,
                        label: firstParticipantName,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '–',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _PenaltyField(
                        controller: _penalty2Controller,
                        label: secondParticipantName,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Hasil',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VsLabel extends StatelessWidget {
  final bool vertical;

  const _VsLabel({required this.vertical});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: vertical
          ? const EdgeInsets.symmetric(vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 10),
      child: const Text(
        'VS',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String name;
  final String score;
  final double scoreFontSize;
  final bool isLeading;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ScoreCard({
    required this.name,
    required this.score,
    required this.scoreFontSize,
    required this.isLeading,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLeading ? AppColors.success : Colors.white10,
          width: isLeading ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLeading ? AppColors.success : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            score,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: scoreFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: IconButton(
                  onPressed: onDecrement,
                  tooltip: 'Kurangi gol',
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.textMuted,
                  ),
                  iconSize: 26,
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: onIncrement,
                  tooltip: 'Tambah gol',
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.secondary,
                  ),
                  iconSize: 26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PenaltyField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PenaltyField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintText: 'Penalti',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}
