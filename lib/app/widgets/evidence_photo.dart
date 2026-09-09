import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vamos_ops_mobile/app/core/config/app_config.dart';
import 'package:vamos_ops_mobile/app/core/storage/session_store.dart';

class EvidencePhoto extends StatefulWidget {
  const EvidencePhoto({super.key, required this.id, this.fit = BoxFit.cover});
  final String id;
  final BoxFit fit;
  @override
  State<EvidencePhoto> createState() => _EvidencePhotoState();
}

class _EvidencePhotoState extends State<EvidencePhoto> {
  int attempt = 0;
  @override
  Widget build(BuildContext context) {
    final token = Get.isRegistered<SessionStoreContract>()
        ? Get.find<SessionStoreContract>().token
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        '${AppConfig.apiBaseUrl}/media/${widget.id}?retry=$attempt',
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
        fit: widget.fit,
        width: double.infinity,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, error, stack) => Center(
          child: TextButton.icon(
            onPressed: () => setState(() => attempt++),
            icon: const Icon(Icons.refresh),
            label: const Text('Foto gagal dimuat · coba lagi'),
          ),
        ),
      ),
    );
  }
}
