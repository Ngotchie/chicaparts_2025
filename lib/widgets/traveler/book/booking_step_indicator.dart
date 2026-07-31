import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BookingStepIndicator extends StatelessWidget {
  final int currentStep;

  const BookingStepIndicator({
    super.key,
    required this.currentStep,
  }) : assert(currentStep >= 1 && currentStep <= 4);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lang = context.read<LanguageProvider>();
    final labels = [
      lang.t('booking_step_dates'),
      lang.t('booking_step_details'),
      lang.t('booking_step_summary'),
      lang.t('booking_step_payment'),
    ];

    return Semantics(
      label: '${lang.t('booking_progress')} $currentStep/4',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: List.generate(labels.length, (index) {
            final step = index + 1;
            final completed = step < currentStep;
            final active = step == currentStep;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: active ? 28 : 24,
                          height: active ? 28 : 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: completed || active
                                ? colors.primary
                                : colors.surfaceContainerHighest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: completed || active
                                  ? colors.primary
                                  : colors.outlineVariant,
                            ),
                          ),
                          child: completed
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: colors.onPrimary,
                                )
                              : Text(
                                  '$step',
                                  style: TextStyle(
                                    color: active
                                        ? colors.onPrimary
                                        : colors.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          labels[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < labels.length - 1)
                    Container(
                      width: 10,
                      height: 2,
                      color: completed ? colors.primary : colors.outlineVariant,
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
