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
  ConsumerState<CreateArticlePostScreen> createState() => _CreateArticlePostScreenState();
}

class _CreateArticlePostScreenState extends ConsumerState<CreateArticlePostScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and content cannot be empty')));
      return;
    }
    
    setState(() => _isUploading = true);
    
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await CloudinaryService.uploadImage(_selectedImage!);
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
        estimatedReadTime: (content.split(' ').length / 200).ceil(), // Roughly 200 words per minute
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Article posted successfully!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextButton(
            onPressed: _isUploading ? null : _uploadAndPost,
            child: _isUploading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Add Header Image', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Article Title',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
            const Divider(),
            TextField(
              controller: _contentController,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'Write your article content here...',
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 10,
            ),
          ],
        ),
      ),
    );
  }
}
