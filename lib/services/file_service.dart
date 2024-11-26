import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../models/attachment.dart';

final FileService fileService = FileService();

class FileService {
  Future<String> updateAvatar(XFile image, String fileName) async{
    final storageRef = FirebaseStorage.instance.ref().child('avatars/$fileName');
    UploadTask uploadTask = storageRef.putData(await image.readAsBytes());

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<String?> uploadFile(PlatformFile file) async {
    try {
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + file.name;
      final storageRef =
          FirebaseStorage.instance.ref().child('attachments/$fileName');
      UploadTask uploadTask;
      if (kIsWeb && file.bytes != null) {
        uploadTask = storageRef.putData(file.bytes!);
      } else if (file.path != null) {
        uploadTask = storageRef.putFile(File(file.path!));
      } else {
        throw Exception("File path or bytes are required for upload.");
      }
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("File upload failed: $e");
      return null;
    }
  }

  Future<List<Attachment>> mapFilesToAttachments(
      List<PlatformFile> fileCached) async {
    List<Attachment> attachments = [];

    for (var file in fileCached) {
      final downloadUrl = await uploadFile(file);

      if (downloadUrl != null) {
        attachments.add(Attachment(
            url: downloadUrl,
            size: file.size,
            extension: file.extension,
            fileName: file.name));
      }
    }

    return attachments;
  }

  String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) {
      return '$sizeInBytes B';
    } else if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
    } else if (sizeInBytes < 1024 * 1024 * 1024) {
      return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(sizeInBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
