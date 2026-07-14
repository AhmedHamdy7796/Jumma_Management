import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:gomaa_management/core/errors/app_exception.dart';
import 'package:gomaa_management/core/logging/app_logger.dart';

/// Manages copy/delete/resolve operations for files in app storage.
class ImageStorageService {
  static const _tag = 'ImageStorageService';
  static const _uuid = Uuid();

  /// Copies a source file to internal appData storage under /images/[subfolder]
  /// and returns the relative path for database storage.
  Future<String> saveImage(File source, String subfolder) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final imagesDir = Directory(join(dir.path, 'images', subfolder));
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }

      final extensionName = extension(source.path);
      final uniqueName = '${_uuid.v4()}$extensionName';
      final destinationFile = File(join(imagesDir.path, uniqueName));

      await source.copy(destinationFile.path);
      AppLogger.instance.info('Image saved to: ${destinationFile.path}', tag: _tag);

      // Return database relative path
      return join('images', subfolder, uniqueName);
    } catch (e) {
      AppLogger.instance.error('Failed to copy image', tag: _tag, exception: e);
      throw ImageStorageException(technicalDetail: e.toString());
    }
  }

  /// Resolves database relative path to absolute [File].
  Future<File?> resolveImage(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      final absolutePath = join(dir.path, relativePath);
      final file = File(absolutePath);
      return file.existsSync() ? file : null;
    } catch (e) {
      AppLogger.instance.error('Failed to resolve image path: $relativePath', tag: _tag, exception: e);
      return null;
    }
  }

  /// Deletes a file in app storage using its database relative path.
  Future<void> deleteImage(String relativePath) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final absolutePath = join(dir.path, relativePath);
      final file = File(absolutePath);
      if (file.existsSync()) {
        await file.delete();
        AppLogger.instance.info('Image deleted: $absolutePath', tag: _tag);
      }
    } catch (e) {
      AppLogger.instance.error('Failed to delete image: $relativePath', tag: _tag, exception: e);
      throw ImageStorageException(technicalDetail: e.toString());
    }
  }
}
