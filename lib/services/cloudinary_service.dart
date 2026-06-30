import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  static final String cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String uploadPreset =
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  /// Upload une image vers Cloudinary depuis un [Uint8List]
  static Future<String> uploadImage(
    Uint8List imageBytes,
    String fileName, {
    String folder = 'menu', // dossier Cloudinary (optionnel)
  }) async {
    if (cloudName.isEmpty || uploadPreset.isEmpty) {
      throw Exception('Cloudinary non configuré (variables d\'env manquantes)');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload'),
    );

    request.fields['upload_preset'] = uploadPreset;
    if (folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final json = jsonDecode(responseBody);
      return json['secure_url']; // URL HTTPS de l'image
    } else {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Erreur Cloudinary: $errorBody');
    }
  }
}
