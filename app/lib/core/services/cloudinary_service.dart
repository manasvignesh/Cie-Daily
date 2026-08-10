import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  static const String _cloudName = 'esz1cz8a';
  static const String _uploadPreset = 'ety57u4p';

  static Future<String?> uploadVideo(File file) async {
    return _uploadFile(file, 'video');
  }

  static Future<String?> uploadImage(File file) async {
    return _uploadFile(file, 'image');
  }

  static Future<String?> _uploadFile(File file, String resourceType) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;

      final extension = p.extension(file.path).replaceAll('.', '');
      final fileBytes = await file.readAsBytes();

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: p.basename(file.path),
        contentType: MediaType(resourceType, extension.isNotEmpty ? extension : (resourceType == 'video' ? 'mp4' : 'jpeg')),
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = json.decode(responseData);
        return data['secure_url'] as String;
      } else {
        print('Cloudinary upload failed: $responseData');
        return null;
      }
    } catch (e) {
      print('Exception during Cloudinary upload: $e');
      return null;
    }
  }
}
