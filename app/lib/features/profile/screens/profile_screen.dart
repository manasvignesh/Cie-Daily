import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../feed/models/post_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _gridView = true;

  // Dynamic stats
  final int _followersCount = 0;
  final int _followingCount = 0;

  // Mock highlights
  final List<Map<String, dynamic>> _highlights = [
    {'label': 'Campus', 'color': const Color(0xFFFF5A1F)},
    {'label': 'Events', 'color': const Color(0xFF5856D6)},
    {'label': 'Sports', 'color': const Color(0xFF34C759)},
    {'label': 'Art', 'color': const Color(0xFFFF2D55)},
    {'label': 'Tech', 'color': const Color(0xFF007AFF)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final userPostsAsync = ref.watch(userPostsProvider);
    final bookmarkedPostsAsync = ref.watch(bookmarkedPostsProvider);
    final screenSize = MediaQuery.of(context).size;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))),
      );
    }

    return userProfileAsync.when(
      data: (profileData) {
        final rawName = profileData?['name'] as String? ?? user.displayName ?? '';
        final emailPrefix = (user.email ?? '').split('@').first;
        final displayName = rawName.isNotEmpty ? rawName : (emailPrefix.isNotEmpty ? emailPrefix : 'Student');
        final handle = '@${displayName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';
        
        final bio = profileData?['bio'] as String? ?? 'Sharing campus life, one drop at a time ✨';
        final department = profileData?['department'] as String? ?? 'CS';
        final yearOfStudy = profileData?['yearOfStudy']?.toString() ?? '1';
        
        final photoUrl = profileData?['photoUrl'] as String? ?? user.photoURL;
        final email = user.email ?? '';
        final postsCount = userPostsAsync.value?.length ?? 0;
        
        final List<dynamic> rawHighlights = profileData?['highlights'] as List<dynamic>? ?? [
          {'label': 'Campus', 'color': '0xFFFF5A1F'},
          {'label': 'Events', 'color': '0xFF5856D6'},
          {'label': 'Sports', 'color': '0xFF34C759'},
          {'label': 'Art', 'color': '0xFFFF2D55'},
          {'label': 'Tech', 'color': '0xFF007AFF'},
        ];
        
        final highlights = rawHighlights.map((h) => Map<String, dynamic>.from(h as Map)).toList();

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.black,
            extendBodyBehindAppBar: true,
            appBar: _buildAppBar(
              context,
              displayName: displayName,
              bio: bio,
              department: department,
              yearOfStudy: yearOfStudy,
              photoUrl: photoUrl,
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── BANNER + AVATAR ────────────────────────────────────
                      _buildBannerSection(context, photoUrl, displayName, screenSize),

                      // ── BIO SECTION ────────────────────────────────────────
                      _buildBioSection(
                        context,
                        displayName: displayName,
                        handle: handle,
                        email: email,
                        bio: bio,
                        department: department,
                        yearOfStudy: yearOfStudy,
                      ),

                      // ── STATS ROW ──────────────────────────────────────────
                      _buildStatsRow(context, postsCount),

                      // ── ACTION BUTTONS ─────────────────────────────────────
                      _buildActionButtons(
                        context,
                        name: displayName,
                        bio: bio,
                        department: department,
                        yearOfStudy: yearOfStudy,
                        photoUrl: photoUrl,
                        highlights: highlights,
                      ),

                      // ── HIGHLIGHTS ─────────────────────────────────────────
                      _buildHighlights(context, highlights),

                      const SizedBox(height: 4),
                      const Divider(color: Color(0xFF222222), height: 1),
                    ],
                  ),
                ),
                // ── TABS ──────────────────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(tabController: _tabController, gridView: _gridView, onToggleGrid: (v) => setState(() => _gridView = v)),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // User's actual posts grid
                  userPostsAsync.when(
                    data: (posts) => _buildPostsGrid(context, posts),
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
                  ),
                  // Saved Bookmarked Posts grid
                  bookmarkedPostsAsync.when(
                    data: (posts) => _buildPostsGrid(context, posts),
                    loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
                    error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F)))),
      error: (e, _) => Scaffold(backgroundColor: Colors.black, body: Center(child: Text('Error loading profile: $e', style: const TextStyle(color: Colors.white54)))),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required String displayName,
    required String bio,
    required String department,
    required String yearOfStudy,
    required String? photoUrl,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: const SizedBox.shrink(),
      title: Text(
        displayName,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 26),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          onPressed: () => _showSettingsSheet(
            context,
            name: displayName,
            bio: bio,
            department: department,
            yearOfStudy: yearOfStudy,
            photoUrl: photoUrl,
          ),
        ),
      ],
    );
  }

  Widget _buildBannerSection(BuildContext context, String? photoUrl, String displayName, Size screenSize) {
    return SizedBox(
      height: 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred banner
          if (photoUrl != null)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Image.network(photoUrl, fit: BoxFit.cover),
            ),
          if (photoUrl == null)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.55)),
          // Bottom fade to black
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                ),
              ),
            ),
          ),
          // Avatar
          Positioned(
            bottom: 0,
            left: 20,
            child: _buildProfileAvatar(photoUrl, displayName),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(String? photoUrl, String displayName) {
    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFBAA3B), Color(0xFFE1306C), Color(0xFF833AB4)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
        child: CircleAvatar(
          radius: 46,
          backgroundColor: const Color(0xFF1C1C1E),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          child: photoUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBioSection(
    BuildContext context, {
    required String displayName,
    required String handle,
    required String email,
    required String bio,
    required String department,
    required String yearOfStudy,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              const Icon(Icons.verified_rounded, color: Color(0xFF007AFF), size: 18),
            ],
          ),
          const SizedBox(height: 3),
          Text(handle, style: const TextStyle(color: Color(0xFF888888), fontSize: 14, fontWeight: FontWeight.w400)),
          const SizedBox(height: 10),
          Text(
            'Year $yearOfStudy · $department Department 📚\n$bio',
            style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13.5, height: 1.5),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.mail_outline_rounded, color: Color(0xFF888888), size: 14),
                const SizedBox(width: 5),
                Text(email, style: const TextStyle(color: Color(0xFF888888), fontSize: 12.5)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int postsCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatBox(count: postsCount, label: 'Posts'),
          _buildStatDivider(),
          _StatBox(count: _followersCount, label: 'Followers'),
          _buildStatDivider(),
          _StatBox(count: _followingCount, label: 'Following'),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFF2C2C2E));
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required String name,
    required String bio,
    required String department,
    required String yearOfStudy,
    required String? photoUrl,
    required List<Map<String, dynamic>> highlights,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _ProfileActionBtn(
              label: 'Edit Profile',
              onTap: () => _showEditProfileSheet(
                context,
                name: name,
                bio: bio,
                department: department,
                yearOfStudy: yearOfStudy,
                photoUrl: photoUrl,
              ),
              filled: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ProfileActionBtn(
              label: 'Share Profile',
              onTap: () => _shareProfile(context, name),
              filled: false,
            ),
          ),
          const SizedBox(width: 8),
          _ProfileIconBtn(icon: Icons.person_add_alt_1_rounded, onTap: () {}),
        ],
      ),
    );
  }

  void _shareProfile(BuildContext context, String displayName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    Clipboard.setData(ClipboardData(
      text: 'Check out $displayName on CIE Connect! Email: ${user.email}'
    ));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile details copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditProfileSheet(
    BuildContext context, {
    required String name,
    required String bio,
    required String department,
    required String yearOfStudy,
    required String? photoUrl,
  }) {
    final nameCtrl = TextEditingController(text: name);
    final bioCtrl = TextEditingController(text: bio);
    final deptCtrl = TextEditingController(text: department);
    final yearCtrl = TextEditingController(text: yearOfStudy);
    final photoCtrl = TextEditingController(text: photoUrl ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Bio',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Department',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Year of Study (1-4)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: photoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Profile Photo URL',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final n = nameCtrl.text.trim();
                  final b = bioCtrl.text.trim();
                  final d = deptCtrl.text.trim();
                  final y = int.tryParse(yearCtrl.text.trim()) ?? 1;
                  final p = photoCtrl.text.trim();

                  if (n.isEmpty) return;

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  Navigator.pop(ctx);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
                  );

                  try {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'name': n,
                      'bio': b,
                      'department': d,
                      'yearOfStudy': y,
                      'photoUrl': p.isNotEmpty ? p : null,
                    });
                    
                    await user.updateDisplayName(n);
                    if (p.isNotEmpty) {
                      await user.updatePhotoURL(p);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                    }
                  } finally {
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlights(BuildContext context, List<Map<String, dynamic>> highlights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text('Highlights', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: highlights.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) return _buildAddHighlightBtn(context, highlights);
              final h = highlights[i - 1];
              final colorHex = h['color'] as String? ?? '0xFFFF5A1F';
              final color = Color(int.parse(colorHex));
              return _buildHighlightCircle(h['label'] as String? ?? '', color);
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildAddHighlightBtn(BuildContext context, List<Map<String, dynamic>> currentHighlights) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showAddHighlightSheet(context, currentHighlights),
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF333333), width: 1.5),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: 6),
          const Text('New', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
        ],
      ),
    );
  }

  void _showAddHighlightSheet(BuildContext context, List<Map<String, dynamic>> currentHighlights) {
    final labelCtrl = TextEditingController();
    final colors = [
      '0xFFFF5A1F',
      '0xFF5856D6',
      '0xFF34C759',
      '0xFFFF2D55',
      '0xFF007AFF',
      '0xFFFFCC00',
    ];
    String selectedColor = colors.first;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const Text('Create Highlight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: labelCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Highlight Name (e.g. Projects)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Select Theme Color', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  itemBuilder: (_, index) {
                    final colorHex = colors[index];
                    final color = Color(int.parse(colorHex));
                    final isSelected = colorHex == selectedColor;
                    return GestureDetector(
                      onTap: () => setStateSheet(() => selectedColor = colorHex),
                      child: Container(
                        width: 38, height: 38,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)] : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final label = labelCtrl.text.trim();
                  if (label.isEmpty) return;

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  Navigator.pop(ctx);

                  final updatedHighlights = List<Map<String, dynamic>>.from(currentHighlights);
                  updatedHighlights.add({
                    'label': label,
                    'color': selectedColor,
                  });

                  try {
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'highlights': updatedHighlights,
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Highlight', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCircle(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 10, spreadRadius: 1)],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPostsGrid(BuildContext context, List<PostModel> posts) {
    if (posts.isEmpty) {
      return _buildEmptyTab(context, Icons.bookmark_border_rounded, 'No saved posts yet');
    }
    if (!_gridView) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildListCard(context, posts[i]),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (_, i) => _buildGridCell(context, posts[i]),
    );
  }

  Widget _buildGridCell(BuildContext context, PostModel post) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    final hue = (post.id.hashCode % 360).abs().toDouble();

    return GestureDetector(
      onTap: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          if (hasImage)
            Image.network(
              post.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildGradientPlaceholder(hue),
            )
          else
            _buildGradientPlaceholder(hue),

          // Video indicator
          if (hasVideo && !hasImage)
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
            )
          else if (hasVideo)
            const Positioned(
              top: 6, right: 6,
              child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 22,
                shadows: [Shadow(color: Colors.black, blurRadius: 6)]),
            ),

          // Title overlay at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                ),
              ),
              child: Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600, height: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientPlaceholder(double hue) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HSLColor.fromAHSL(1, hue, 0.45, 0.22).toColor(),
            HSLColor.fromAHSL(1, (hue + 40) % 360, 0.55, 0.14).toColor(),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, PostModel post) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: SizedBox(
              width: 90, height: 90,
              child: post.imageUrl != null
                  ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                  : Container(color: const Color(0xFF1C1C2E), child: const Icon(Icons.article_rounded, color: Colors.white30, size: 32)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 6),
                  Text('By ${post.authorName}', style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(BuildContext context, IconData icon, String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white24, size: 56),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
        ],
      ),
    );
  }

  void _showSettingsSheet(
    BuildContext context, {
    required String name,
    required String bio,
    required String department,
    required String yearOfStudy,
    required String? photoUrl,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Align(alignment: Alignment.centerLeft, child: Text('Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700))),
              ),
              _SettingsTile(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                onTap: () {
                  Navigator.pop(context);
                  _showEditProfileSheet(context, name: name, bio: bio, department: department, yearOfStudy: yearOfStudy, photoUrl: photoUrl);
                },
              ),
              _SettingsTile(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => Navigator.pop(context)),
              _SettingsTile(icon: Icons.lock_outline_rounded, label: 'Privacy', onTap: () => Navigator.pop(context)),
              _SettingsTile(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () => Navigator.pop(context)),
              const Divider(color: Color(0xFF2C2C2E), height: 1),
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Log Out',
                color: Colors.redAccent,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool gridView;
  final ValueChanged<bool> onToggleGrid;

  const _TabBarDelegate({required this.tabController, required this.gridView, required this.onToggleGrid});

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              icon: tabController.index == 0 ? Icons.grid_on_rounded : Icons.grid_3x3_rounded,
              isActive: tabController.index == 0,
              onTap: () => tabController.animateTo(0),
            ),
          ),
          Expanded(
            child: _TabItem(
              icon: tabController.index == 1 ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              isActive: tabController.index == 1,
              onTap: () => tabController.animateTo(1),
            ),
          ),
          if (tabController.index == 0)
            IconButton(
              icon: Icon(gridView ? Icons.view_list_rounded : Icons.grid_on_rounded, color: Colors.white70, size: 22),
              onPressed: () => onToggleGrid(!gridView),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController ||
      oldDelegate.gridView != gridView;
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 46,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white38, size: 24),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 1.5,
              width: isActive ? 24 : 0,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final int count;
  final String label;
  const _StatBox({required this.count, required this.label});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(_fmt(count), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 12.5, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }
}

class _ProfileActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ProfileActionBtn({required this.label, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5A1F) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : Colors.white,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProfileIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF333333), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label, style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: color == null ? const Icon(Icons.chevron_right_rounded, color: Color(0xFF444444)) : null,
      onTap: onTap,
    );
  }
}
