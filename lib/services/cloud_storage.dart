import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CloudStorageService {
  final FirebaseStorage _storage;

  CloudStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadFile(
    String filePath,
    String storagePath, {
    Function(double)? onProgress,
  }) async {
    try {
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(File(filePath));
      
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        onProgress?.call(progress);
      });

      final taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: ${e.toString()}');
    }
  }

  Future<String> uploadXFile(
    XFile file,
    String storagePath, {
    Function(double)? onProgress,
  }) async {
    return uploadFile(file.path, storagePath, onProgress: onProgress);
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: ${e.toString()}');
    }
  }

  Future<List<String>> listFiles(String path) async {
    try {
      final result = await _storage.ref(path).listAll();
      final urls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()),
      );
      return urls;
    } catch (e) {
      throw Exception('Failed to list files: ${e.toString()}');
    }
  }
}