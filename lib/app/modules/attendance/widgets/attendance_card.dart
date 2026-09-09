import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';
import 'package:vamos_ops_mobile/app/core/utils/date_time_labels.dart';

class AttendanceCard extends StatelessWidget {
  const AttendanceCard({
    super.key,
    required this.onDuty,
    required this.checkInAt,
    required this.checkOutAt,
    required this.completed,
    required this.total,
    required this.onStart,
    required this.isBusy,
  });
  final bool onDuty;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int completed;
  final int total;
  final VoidCallback onStart;
  final bool isBusy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.onSurface,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 25,
          offset: Offset(0, 13),
        ),
      ],
    ),
    child: checkOutAt != null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CLOCK OUT SELESAI',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppText.sm,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Absensi hari ini lengkap',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontFamily: AppText.displayFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Clock In ${clockLabel(checkInAt)}  ·  Clock Out ${clockLabel(checkOutAt)}',
                style: const TextStyle(
                  color: AppColors.onInverseMuted,
                  fontSize: AppText.base,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Task dikunci setelah Clock Out.',
                style: TextStyle(
                  color: AppColors.onInverseMuted,
                  fontSize: AppText.sm,
                ),
              ),
            ],
          )
        : onDuty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.primary, blurRadius: 8),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ON DUTY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: AppText.base,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Clock In ${clockLabel(checkInAt)}',
                    style: const TextStyle(
                      color: AppColors.onInverseMuted,
                      fontSize: AppText.sm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 23),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$completed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppText.heroLg,
                      fontFamily: AppText.displayFamily,
                      height: 0.9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ' / $total task selesai',
                    style: const TextStyle(
                      color: AppColors.onInverseMuted,
                      fontSize: AppText.base,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${total == 0 ? 0 : (completed / total * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: AppText.lg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : completed / total,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceInverseRaised,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: AppColors.onInverseSubtle,
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Di dalam geofence · akurasi 8 m',
                    style: TextStyle(
                      color: AppColors.onInverseSubtle,
                      fontSize: AppText.xs,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CLOCK IN HARI INI',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppText.sm,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Siap mulai bekerja?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontFamily: AppText.displayFamily,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Lokasi Anda terdeteksi di Vamos Arena Fit.',
                style: TextStyle(
                  color: AppColors.onInverseMuted,
                  fontSize: AppText.base,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: isBusy ? null : onStart,
                icon: isBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(isBusy ? 'MEMPROSES…' : 'CLOCK IN'),
              ),
            ],
          ),
  );
}
