import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import '../models/attachment.dart';

final FileService fileService = FileService();

class FileService {
  Future<String?> uploadFile(PlatformFile file) async {
    try {
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + file.name;
      final storageRef =
          FirebaseStorage.instance.ref().child('attachments/$fileName');
      final uploadTask = storageRef.putFile(File(file.path!));
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
}
