import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../core/services/cloudinary_service.dart';
import '../models/post_model.dart';
import '../data/firebase_feed_repository.dart';
import '../providers/feed_provider.dart';

class CreateVideoPostScreen extends ConsumerStatefulWidget {
  const CreateVideoPostScreen({super.key});

  @override
  ConsumerState<CreateVideoPostScreen> createState() => _CreateVideoPostScreenState();
}

class _CreateVideoPostScreenState extends ConsumerState<CreateVideoPostScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isUploading = false;

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    
    if (video != null) {
      final file = File(video.path);
      setState(() {
        _selectedVideo = file;
      });
      _initializeVideo(file);
    }
  }
  
  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 60),
    );
    
    if (video != null) {
      final file = File(video.path);
      setState(() {
        _selectedVideo = file;
      });
      _initializeVideo(file);
    }
  }

  void _initializeVideo(File file) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play();
      });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _selectedRatio = '9:16'; // Options: 9:16, 1:1, 4:5, 16:9

  final List<Map<String, dynamic>> _ratioOptions = [
    {'label': '9:16 Reel', 'value': '9:16', 'icon': Icons.stay_current_portrait},
    {'label': '1:1 Square', 'value': '1:1', 'icon': Icons.crop_square},
    {'label': '4:5 Portrait', 'value': '4:5', 'icon': Icons.crop_5_4},
    {'label': '16:9 Wide', 'value': '16:9', 'icon': Icons.crop_16_9},
  ];

  double _getRatioValue(String ratioStr) {
    switch (ratioStr) {
      case '1:1':
        return 1.0;
      case '4:5':
        return 4 / 5;
      case '16:9':
        return 16 / 9;
      case '9:16':
      default:
        return 9 / 16;
    }
  }

  Future<void> _uploadAndPost() async {
    if (_selectedVideo == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final videoUrl = await CloudinaryService.uploadVideo(_selectedVideo!);
      
      if (videoUrl == null) {
        throw Exception('Failed to upload video');
      }
      
      final post = PostModel(
        id: '', // Firestore will generate this
        title: _titleController.text.trim().isEmpty ? 'New Reel' : _titleController.text.trim(),
        blocks: [],
        estimatedReadTime: 1,
        category: 'Reel',
        likesCount: 0,
        commentsCount: 0,
        isTodaysDrop: true,
        createdAt: DateTime.now(),
        authorName: '', // Handled by repository
        videoUrl: videoUrl,
        aspectRatio: _selectedRatio,
      );
      
      await ref.read(feedRepositoryProvider).createPost(post);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published successfully!')));
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reel'),
        actions: [
          if (_selectedVideo != null)
            TextButton(
              onPressed: _isUploading ? null : _uploadAndPost,
              child: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _selectedVideo == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_library, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Select or record a video up to 60s', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        onPressed: _recordVideo,
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        onPressed: _pickVideo,
                      ),
                    ],
                  )
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // Video Preview formatted according to selected ratio
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_selectedRatio == '9:16' ? 0 : 16),
                    child: AspectRatio(
                      aspectRatio: _getRatioValue(_selectedRatio),
                      child: Container(
                        color: Colors.black,
                        child: _videoController != null && _videoController!.value.isInitialized
                            ? VideoPlayer(_videoController!)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              hintText: 'Add a title to your post...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            maxLength: 80,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Aspect Ratio:',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _ratioOptions.map((opt) {
                                final isSelected = _selectedRatio == opt['value'];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    selected: isSelected,
                                    showCheckmark: false,
                                    avatar: Icon(
                                      opt['icon'] as IconData,
                                      size: 16,
                                      color: isSelected ? Colors.black : Colors.white,
                                    ),
                                    label: Text(
                                      opt['label'] as String,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: Colors.black54,
                                    selectedColor: Colors.white,
                                    side: BorderSide(
                                      color: isSelected ? Colors.white : Colors.white24,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() {
                                          _selectedRatio = opt['value'] as String;
                                        });
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isUploading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Uploading...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isUploading)
                        FloatingActionButton(
                          heroTag: 'retake',
                          onPressed: () {
                            setState(() {
                              _selectedVideo = null;
                              _videoController?.dispose();
                              _videoController = null;
                            });
                          },
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.close, color: Colors.black),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
