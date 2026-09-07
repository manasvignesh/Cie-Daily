import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../models/post_model.dart';
import '../data/firebase_feed_repository.dart';
import '../../discover/providers/discover_provider.dart';

class CreateArticlePostScreen extends ConsumerStatefulWidget {
  const CreateArticlePostScreen({super.key});

  @override
  ConsumerState<CreateArticlePostScreen> createState() =>
      _CreateArticlePostScreenState();
}

class _CreateArticlePostScreenState
    extends ConsumerState<CreateArticlePostScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _uploadAndPost() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Title and content cannot be empty')));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(
          _selectedImage!,
          onProgress: (progress) {
            if (mounted) setState(() => _uploadProgress = progress);
          },
        );
        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      final post = PostModel(
        id: '', // Firestore will generate this
        title: title,
        blocks: [
          {'type': 'text', 'content': content}
        ],
        estimatedReadTime: (content.split(' ').length / 200)
            .ceil(), // Roughly 200 words per minute
        category: 'Article',
        likesCount: 0,
        commentsCount: 0,
        isTodaysDrop: false,
        createdAt: DateTime.now(),
        authorName: '', // Handled by repository
        imageUrl: imageUrl,
      );

      await ref.read(feedRepositoryProvider).createPost(post);

      ref.invalidate(discoverArticlesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Article posted successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text("We couldn't publish this article. Please try again.")));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Article'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadAndPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: _isUploading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(_selectedImage == null
                            ? 'Saving…'
                            : '${(_uploadProgress * 100).round()}%'),
                      ],
                    )
                  : const Text('Post',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C28),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 1.5),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text('Add Header Image',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _titleController,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Article Title',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C28),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _contentController,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Write your article content here...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                maxLines: null,
                minLines: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
