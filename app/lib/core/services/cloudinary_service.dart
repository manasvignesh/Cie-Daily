import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';

class CloudinaryService {
  static const String _cloudName = 'esz1cz8a';
  static const String _uploadPreset = 'ety57u4p';
  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const int _maxVideoBytes = 100 * 1024 * 1024;
  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const _videoExtensions = {'mp4', 'mov', 'm4v', 'webm'};

  static Future<String?> uploadVideo(
    File file, {
    void Function(double progress)? onProgress,
  }) =>
      _uploadFile(file, 'video', onProgress: onProgress);
  static Future<String?> uploadImage(
    File file, {
    void Function(double progress)? onProgress,
  }) =>
      _uploadFile(file, 'image', onProgress: onProgress);

  static Future<String?> _uploadFile(
    File file,
    String resourceType, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      if (!await file.exists()) {
        throw const AppException(
          code: AppErrorCode.validation,
          userMessage: 'The selected file is no longer available.',
        );
      }
      final length = await file.length();
      final extension = file.path.split('.').last.toLowerCase();
      final allowed =
          resourceType == 'video' ? _videoExtensions : _imageExtensions;
      final maxBytes =
          resourceType == 'video' ? _maxVideoBytes : _maxImageBytes;
      if (length <= 0 || !allowed.contains(extension)) {
        throw AppException(
          code: AppErrorCode.validation,
          userMessage: resourceType == 'video'
              ? 'Choose a supported MP4, MOV, M4V, or WebM video.'
              : 'Choose a supported JPG, PNG, or WebP image.',
        );
      }
      if (length > maxBytes) {
        throw AppException(
          code: AppErrorCode.validation,
          userMessage: resourceType == 'video'
              ? 'Choose a video smaller than 100 MB.'
              : 'Choose an image smaller than 10 MB.',
        );
      }

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
      );
      var uploadedBytes = 0;
      final progressStream = file.openRead().transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
          handleData: (chunk, sink) {
            uploadedBytes += chunk.length;
            onProgress?.call((uploadedBytes / length).clamp(0, 1));
            sink.add(chunk);
          },
        ),
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'cie-daily/$resourceType'
        ..files.add(http.MultipartFile(
          'file',
          http.ByteStream(progressStream),
          length,
          filename: file.uri.pathSegments.last,
        ));
      final response =
          await request.send().timeout(const Duration(seconds: 90));
      final responseData = await response.stream.bytesToString();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const AppException(
          code: AppErrorCode.uploadFailed,
          userMessage: "We couldn't upload that file. Please try again.",
          retryable: true,
        );
      }
      final data = jsonDecode(responseData);
      final url =
          data is Map<String, dynamic> ? data['secure_url'] as String? : null;
      if (url == null || url.isEmpty) {
        throw const AppException(
          code: AppErrorCode.uploadFailed,
          userMessage: "We couldn't upload that file. Please try again.",
          retryable: true,
        );
      }
      onProgress?.call(1);
      return url;
    } catch (error, stackTrace) {
      throw ErrorMapper.normalize(
        error,
        stackTrace: stackTrace,
        fallbackMessage: "We couldn't upload that file. Please try again.",
      );
    }
  }
}
