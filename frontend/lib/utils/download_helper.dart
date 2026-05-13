import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/master_data_service.dart';
import '../theme/app_theme.dart';
import 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_web.dart';

/// Downloads a checker file and shows progress/error snackbars.
/// Captures [ScaffoldMessenger] and [MasterDataService] before the async gap
/// so it is safe to call from a widget whose state may unmount during the await.
Future<void> downloadCheckerFile({
  required BuildContext context,
  required String filename,
  required String templateId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final service = context.read<MasterDataService>();

  messenger.showSnackBar(
    SnackBar(
      content: Text('Downloading $filename…'),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    ),
  );

  final result = await service.downloadCheckerFile(
    filename: filename,
    templateId: templateId,
  );

  if (result.success) {
    await triggerFileDownload(filename, result.bytes);
  } else {
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
