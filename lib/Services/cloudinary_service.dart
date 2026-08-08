import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'dafmwwruo';
  static const String _uploadPreset = 'coffee_products';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload any [File] to Cloudinary and return the secure URL.
  /// Returns null if upload fails.
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        return json['secure_url'] as String?;
      } else {
        final body = await response.stream.bytesToString();
        print('[Cloudinary] Upload failed (${response.statusCode}): $body');
        return null;
      }
    } catch (e) {
      print('[Cloudinary] Exception: $e');
      return null;
    }
  }

  /// Upload raw bytes (e.g. from base64 decoded data) to Cloudinary.
  /// Returns null if upload fails.
  static Future<String?> uploadBytes(List<int> bytes,
      {String filename = 'upload.jpg'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        return json['secure_url'] as String?;
      } else {
        final body = await response.stream.bytesToString();
        print('[Cloudinary] Upload failed (${response.statusCode}): $body');
        return null;
      }
    } catch (e) {
      print('[Cloudinary] Exception: $e');
      return null;
    }
  }

  /// Returns true if the given [url] is a Cloudinary or any http/https URL.
  static bool isNetworkUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
