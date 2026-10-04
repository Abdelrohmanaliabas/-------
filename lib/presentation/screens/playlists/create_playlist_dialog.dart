import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/core/constants/app_colors.dart';
import 'package:mazikty/core/constants/app_typography.dart';
import 'package:mazikty/presentation/providers/playlists_provider.dart';

void showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('إنشاء قائمة تشغيل جديدة', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'اسم قائمة التشغيل (مثال: طربي المفضل)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: AppTypography.bodyMedium,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'وصف مختصر (اختياري)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('إلغاء', style: AppTypography.labelMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                await ref.read(playlistsProvider.notifier).createPlaylist(
                      name,
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                    );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              }
            },
            child: Text('إنشاء', style: AppTypography.labelLarge.copyWith(color: Colors.black)),
          ),
        ],
      );
    },
  );
}

void showRenamePlaylistDialog(BuildContext context, WidgetRef ref, String playlistId, String currentName) {
  final nameController = TextEditingController(text: currentName);

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('إعادة تسمية قائمة التشغيل', style: AppTypography.titleMedium),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: AppTypography.bodyLarge,
          decoration: const InputDecoration(
            hintText: 'الاسم الجديد',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('إلغاء', style: AppTypography.labelMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                await ref.read(playlistsProvider.notifier).renamePlaylist(playlistId, newName);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                }
              }
            },
            child: Text('حفظ', style: AppTypography.labelLarge.copyWith(color: Colors.black)),
          ),
        ],
      );
    },
  );
}
