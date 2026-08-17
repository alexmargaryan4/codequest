import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/rewards_constants.dart';
import '../../../core/providers/pet_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/pet_companion.dart';

class PetScreen extends ConsumerWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PetCompanion> petAsync = ref.watch(petProvider);
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Питомец'),
        actions: <Widget>[
          petAsync.maybeWhen(
            data: (PetCompanion pet) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showRenameSheet(context, ref, pet),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, StackTrace st) => Center(child: Text('Ошибка загрузки: $e')),
          data: (PetCompanion pet) {
            final int? xpToNext = pet.xpToNextStage;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                Center(
                  child: Text(
                    pet.species.emoji,
                    style: const TextStyle(fontSize: 120),
                  ).animate(onPlay: (AnimationController c) => c.repeat(reverse: true)).moveY(
                        begin: 0,
                        end: -10,
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      ),
                ),
                const SizedBox(height: 12),
                Center(child: Text(pet.name, style: text.headlineSmall)),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    pet.stageLabel,
                    style: text.bodyMedium?.copyWith(color: semantic.textMuted),
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: pet.stageProgressRatio,
                    minHeight: 10,
                    backgroundColor: semantic.surfaceRaised,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pet.isMaxStage
                      ? 'Питомец достиг максимальной стадии!'
                      : 'До следующей стадии: $xpToNext XP',
                  style: text.bodySmall?.copyWith(color: semantic.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _SpeciesPicker(current: pet.species),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: semantic.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: semantic.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.info_outline_rounded, color: semantic.textMuted, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Питомец растёт сам, когда ты зарабатываешь XP — ничего специально делать не нужно.',
                          style: text.bodySmall?.copyWith(color: semantic.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRenameSheet(BuildContext context, WidgetRef ref, PetCompanion pet) {
    final TextEditingController controller = TextEditingController(text: pet.name);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Имя питомца', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: controller, autofocus: true, maxLength: 20),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final String name = controller.text.trim();
                    if (name.isNotEmpty) {
                      await ref.read(petProvider.notifier).rename(name);
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeciesPicker extends ConsumerWidget {
  const _SpeciesPicker({required this.current});
  final PetSpecies current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppSemanticColors semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Выбрать вид', style: text.titleSmall),
        const SizedBox(height: 10),
        Row(
          children: PetSpecies.values.map((PetSpecies species) {
            final bool selected = species == current;
            return Expanded(
              child: GestureDetector(
                onTap: () => ref.read(petProvider.notifier).chooseSpecies(species),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accentIndigo.withValues(alpha: 0.14)
                        : semantic.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: selected ? AppColors.accentIndigo : semantic.border,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(species.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Text(species.label, style: text.labelSmall),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
