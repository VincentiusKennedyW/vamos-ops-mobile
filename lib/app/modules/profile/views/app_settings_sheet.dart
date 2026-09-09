import 'package:flutter/material.dart';
import 'package:vamos_ops_mobile/app/core/theme/app_tokens.dart';

void showAppSettingsSheet(BuildContext context, bool isOnline) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan aplikasi',
              style: TextStyle(
                fontSize: 21,
                fontFamily: AppText.displayFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: isOnline ? AppColors.primary : AppColors.warning,
              ),
              title: const Text('Koneksi VAMOS API'),
              subtitle: Text(isOnline ? 'Terhubung' : 'Tidak terhubung'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock_outline_rounded),
              title: Text('Akun demo'),
              subtitle: Text('Penggantian akun tersedia setelah auth aktif.'),
            ),
          ],
        ),
      ),
    ),
  );
}
