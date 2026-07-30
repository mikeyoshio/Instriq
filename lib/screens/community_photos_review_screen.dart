import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/catalog_community_photo.dart';
import '../services/catalog_community_photo_service.dart';

/// Panel mínimo de moderación global para admins: lista de fotos de la
/// comunidad pendientes de revisión, con Aprobar/Rechazar. No hay todavía una
/// sección "admin de catálogo global" propia (ver schema_v15/v16), así que se
/// llega aquí desde un icono en el AppBar de CatalogScreen, visible solo si
/// ProfileService.instance.isAdmin.
class CommunityPhotosReviewScreen extends StatefulWidget {
  const CommunityPhotosReviewScreen({super.key});

  @override
  State<CommunityPhotosReviewScreen> createState() => _CommunityPhotosReviewScreenState();
}

class _CommunityPhotosReviewScreenState extends State<CommunityPhotosReviewScreen> {
  bool _loading = true;
  String? _loadError;
  List<CatalogCommunityPhoto> _photos = [];
  Map<String, String?> _submitterNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final photos = await CatalogCommunityPhotoService.instance.fetchPendingForAdmin();
      final submitterIds = photos.map((p) => p.submittedBy).whereType<String>().toSet().toList();
      var names = <String, String?>{};
      if (submitterIds.isNotEmpty) {
        try {
          final rows = await Supabase.instance.client
              .from('profiles')
              .select('id, display_name')
              .inFilter('id', submitterIds);
          names = {
            for (final r in (rows as List<dynamic>))
              (r as Map<String, dynamic>)['id'] as String: r['display_name'] as String?,
          };
        } catch (_) {
          // RLS puede impedir ver perfiles de otro hospital: se muestra sin
          // nombre, no bloquea la moderación.
        }
      }
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _submitterNames = names;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approve(CatalogCommunityPhoto photo) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await CatalogCommunityPhotoService.instance.reviewPhoto(photoId: photo.id, approve: true);
      if (!mounted) return;
      setState(() => _photos.removeWhere((p) => p.id == photo.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.communityPhotoReviewActionError(e.toString()))));
    }
  }

  Future<void> _reject(CatalogCommunityPhoto photo) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityPhotoReviewRejectDialogTitle),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: l10n.communityPhotoReviewRejectHint),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.communityPhotoReviewReject),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await CatalogCommunityPhotoService.instance.reviewPhoto(
        photoId: photo.id,
        approve: false,
        rejectionReason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _photos.removeWhere((p) => p.id == photo.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.communityPhotoReviewActionError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.communityPhotoReviewScreenTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(l10n.communityPhotoReviewLoadError(_loadError!)))
              : _photos.isEmpty
                  ? Center(child: Text(l10n.communityPhotoReviewEmptyState))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _photos.length,
                        itemBuilder: (context, index) {
                          final photo = _photos[index];
                          final submitterName = photo.submittedBy != null ? _submitterNames[photo.submittedBy] : null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      CatalogCommunityPhotoService.instance.getPublicUrl(photo.photoPath),
                                      height: 160,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) =>
                                          const SizedBox(height: 160, child: Icon(Icons.broken_image_outlined)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${photo.instrumentRefType} · ${photo.instrumentRefId}',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  if (submitterName != null && submitterName.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.communityPhotoReviewSubmittedBy(submitterName),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.close),
                                          label: Text(l10n.communityPhotoReviewReject),
                                          onPressed: () => _reject(photo),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: FilledButton.icon(
                                          icon: const Icon(Icons.check),
                                          label: Text(l10n.communityPhotoReviewApprove),
                                          onPressed: () => _approve(photo),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
