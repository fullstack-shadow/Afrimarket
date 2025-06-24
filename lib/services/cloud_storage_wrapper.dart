import 'package:afrimarket/services/cloud_storage.dart' as impl;
import 'dart:io';

class CloudStorage {
  final impl.CloudStorageService _storageService;

  CloudStorage() : _storageService = impl.CloudStorageService();

  Future<String> uploadImage(File image) async {
    try {
      final path = 'chat_images/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      return await _storageService.uploadFile(image.path, path);
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
