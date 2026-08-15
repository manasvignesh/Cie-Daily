import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../feed/models/post_model.dart';
import '../../../core/utils/role_utils.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/widgets/data_display/app_avatar.dart';
import '../../chat/providers/chat_providers.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final likedPostsAsync = ref.watch(likedPostsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final screenSize = MediaQuery.of(context).size;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))),
      );
    }

    final userRole = getUserRole(user.email);
    final isStudent = userRole == UserRole.STUDENT;
    final isCreatorOrAdmin = canCreateContent(user.email);

    return userProfileAsync.when(
      data: (profileData) {
        final rawName = profileData?['name'] as String? ?? user.displayName ?? '';
        final emailPrefix = (user.email ?? '').split('@').first;
        final displayName = rawName.isNotEmpty ? rawName : (emailPrefix.isNotEmpty ? emailPrefix : 'Student');
        final handle = '@${displayName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';
        
        final bio = profileData?['bio'] as String? ?? (isStudent ? 'Learning, exploring & connecting on campus ✨' : 'Sharing campus life, one drop at a time ✨');
        final department = profileData?['department'] as String? ?? 'CS';
        final yearOfStudy = profileData?['yearOfStudy']?.toString() ?? '1';
        
        final photoUrl = profileData?['photoUrl'] as String? ?? user.photoURL;
        final email = user.email ?? '';
        final postsCount = userPostsAsync.value?.length ?? 0;
        final savedCount = bookmarkedPostsAsync.value?.length ?? 0;
        final likedCount = likedPostsAsync.value?.length ?? 0;
        final connectionsCount = conversationsAsync.value?.length ?? 0;
        
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
              isCreatorOrAdmin: isCreatorOrAdmin,
            ),
            body: NestedScrollView(
              physics: const ClampingScrollPhysics(),
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
                        connectionCode: profileData?['connectionCode'] as String? ?? '',
                        isCreatorOrAdmin: isCreatorOrAdmin,
                      ),

                      // ── STATS ROW ──────────────────────────────────────────
                      _buildStatsRow(
                        context,
                        isStudent: isStudent,
                        postsCount: postsCount,
                        savedCount: savedCount,
                        likedCount: likedCount,
                        connectionsCount: connectionsCount,
                      ),

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
                // ── TABS HEADER ──────────────────────────────────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    tabController: _tabController,
                    isStudent: isStudent,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(),
                children: isStudent
                    ? [
                        // STUDENT TAB 1: Saved Drops (Bookmarks)
                        bookmarkedPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Saved Drops Yet',
                            emptyMessage: 'Bookmark articles and reels in your feed to read or watch later!',
                            emptyIcon: Icons.bookmark_border_rounded,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
                        ),
                        // STUDENT TAB 2: Connections List
                        _buildConnectionsTab(context, profileData?['connectionCode'] as String? ?? ''),
                        // STUDENT TAB 3: Upvoted / Liked Drops
                        likedPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Upvoted Drops Yet',
                            emptyMessage: 'Upvote reels and articles in your feed to save them here!',
                            emptyIcon: Icons.favorite_border_rounded,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
                        ),
                      ]
                    : [
                        // CREATOR / ADMIN TAB 1: Published Drops
                        userPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Published Drops Yet',
                            emptyMessage: 'Create your first campus reel or article drop!',
                            emptyIcon: Icons.camera_alt_outlined,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
                        ),
                        // CREATOR / ADMIN TAB 2: Saved Drops
                        bookmarkedPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Saved Posts Yet',
                            emptyMessage: 'Bookmark posts to save them for later.',
                            emptyIcon: Icons.bookmark_border_rounded,
                          ),
                          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
                        ),
                        // CREATOR / ADMIN TAB 3: Upvoted Drops
                        likedPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Liked Posts Yet',
                            emptyMessage: 'Liked posts will appear here.',
                            emptyIcon: Icons.favorite_border_rounded,
                          ),
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
    required bool isCreatorOrAdmin,
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
        if (isCreatorOrAdmin)
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white, size: 26),
            tooltip: 'Create Post',
            onPressed: () {
              context.push('/create_article_post');
            },
          ),
        IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
          tooltip: 'Menu',
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
    required String connectionCode,
    required bool isCreatorOrAdmin,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              if (isCreatorOrAdmin) ...[
                const SizedBox(width: 6),
                const VerifiedBadge(size: 18),
              ],
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
          if (connectionCode.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: connectionCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connection code copied to clipboard!'), duration: Duration(seconds: 2)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A1F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF5A1F).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_rounded, color: Color(0xFFFF5A1F), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Connection Code: $connectionCode',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, color: Colors.white70, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context, {
    required bool isStudent,
    required int postsCount,
    required int savedCount,
    required int likedCount,
    required int connectionsCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: isStudent
            ? [
                _StatBox(count: savedCount, label: 'Saved Drops'),
                _buildStatDivider(),
                _StatBox(count: connectionsCount, label: 'Connections'),
                _buildStatDivider(),
                _StatBox(count: likedCount, label: 'Upvoted'),
              ]
            : [
                _StatBox(count: postsCount, label: 'Published'),
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

  Widget _buildHighlights(BuildContext context, List<Map<String, dynamic>> highlights) {
    return Container(
      height: 95,
      margin: const EdgeInsets.only(top: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: highlights.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildAddHighlightCircle(context, highlights);
          }
          final item = highlights[index - 1];
          final colorVal = int.tryParse(item['color'] as String? ?? '') ?? 0xFFFF5A1F;
          return _buildHighlightCircle(item['label'] as String? ?? 'Spotlight', Color(colorVal));
        },
      ),
    );
  }

  Widget _buildAddHighlightCircle(BuildContext context, List<Map<String, dynamic>> currentHighlights) {
    return GestureDetector(
      onTap: () => _showAddHighlightSheet(context, currentHighlights),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF333333), width: 1.5),
                color: const Color(0xFF111111),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            const Text('New', style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
          ],
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

  Widget _buildPostsGrid(
    BuildContext context,
    List<PostModel> posts, {
    required String emptyTitle,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (posts.isEmpty) {
      return _buildEmptyTab(context, emptyIcon, emptyTitle, emptyMessage);
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

  Widget _buildConnectionsTab(BuildContext context, String connectionCode) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUser = FirebaseAuth.instance.currentUser;

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 54, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  const Text(
                    'No Campus Connections Yet',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Share your Connection Code with peers in CIE Chat to link accounts and share drops!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (connectionCode.isNotEmpty)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A1F),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: connectionCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connection Code copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text('Copy Code: $connectionCode'),
                    ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: conversations.length,
          separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
          itemBuilder: (context, index) {
            final conv = conversations[index];
            final partnerId = conv.participants.firstWhere(
              (id) => id != currentUser?.uid,
              orElse: () => '',
            );
            final details = conv.participantDetails[partnerId] as Map<String, dynamic>?;
            final partnerName = details?['name'] as String? ?? 'Student';
            final partnerAvatar = details?['photoUrl'] as String?;

            return ListTile(
              leading: AppAvatar(
                imageUrl: partnerAvatar,
                fallbackText: partnerName,
                radius: 20,
              ),
              title: Text(
                partnerName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              subtitle: const Text(
                'Connected Peer',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFFF5A1F)),
                onPressed: () {
                  context.push('/chat/conversation/${conv.id}', extra: {
                    'partnerUid': partnerId,
                    'partnerName': partnerName,
                    'partnerPhotoUrl': partnerAvatar,
                  });
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white54))),
    );
  }

  Widget _buildEmptyTab(BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCell(BuildContext context, PostModel post) {
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;
    final hasVideo = post.videoUrl != null && post.videoUrl!.isNotEmpty;
    final hue = (post.id.hashCode % 360).abs().toDouble();

    return GestureDetector(
      onTap: () {
        if (post.category.toLowerCase() == 'reel' || post.videoUrl != null) {
          context.push('/reel/${post.id}');
        } else {
          context.push('/discover/article', extra: post);
        }
      },
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

  void _showAddHighlightSheet(BuildContext context, List<Map<String, dynamic>> currentHighlights) {
    final labelCtrl = TextEditingController();
    Color selectedColor = const Color(0xFFFF5A1F);

    final colors = [
      const Color(0xFFFF5A1F),
      const Color(0xFF5856D6),
      const Color(0xFF34C759),
      const Color(0xFFFF2D55),
      const Color(0xFF007AFF),
      const Color(0xFFFFCC00),
      const Color(0xFFAF52DE),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          margin: const EdgeInsets.all(12),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 16, left: 20, right: 20),
          decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('New Highlight', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Highlight Title',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Theme Color', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colors.map((c) {
                  final isSel = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedColor = c),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final txt = labelCtrl.text.trim();
                  if (txt.isEmpty) return;

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final updated = List<Map<String, dynamic>>.from(currentHighlights);
                  updated.add({
                    'label': txt,
                    'color': '0x${selectedColor.value.toRadixString(16).toUpperCase()}',
                  });

                  Navigator.pop(ctx);

                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                    'highlights': updated,
                  });
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 16, left: 20, right: 20),
        decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
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
                maxLines: 2,
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
              Consumer(
                builder: (ctx, ref, _) {
                  final userProfile = ref.watch(userProfileProvider).value;
                  final autoAccept = userProfile?['autoAcceptRequests'] as bool? ?? false;
                  return SwitchListTile(
                    secondary: const Icon(Icons.handshake_outlined, color: Colors.white),
                    title: const Text('Auto-Accept Connection Requests', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(autoAccept ? 'Automatically accept incoming requests' : 'Manually review incoming requests', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    value: autoAccept,
                    activeColor: const Color(0xFFFF5A1F),
                    onChanged: (val) async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({'autoAcceptRequests': val});
                      }
                    },
                  );
                },
              ),
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
  final bool isStudent;

  const _TabBarDelegate({required this.tabController, required this.isStudent});

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: Row(
        children: isStudent
            ? [
                Expanded(
                  child: _TabItem(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Saved',
                    isActive: tabController.index == 0,
                    onTap: () => tabController.animateTo(0),
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.people_outline_rounded,
                    label: 'Connections',
                    isActive: tabController.index == 1,
                    onTap: () => tabController.animateTo(1),
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Upvoted',
                    isActive: tabController.index == 2,
                    onTap: () => tabController.animateTo(2),
                  ),
                ),
              ]
            : [
                Expanded(
                  child: _TabItem(
                    icon: Icons.grid_on_rounded,
                    label: 'Published',
                    isActive: tabController.index == 0,
                    onTap: () => tabController.animateTo(0),
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.bookmark_border_rounded,
                    label: 'Saved',
                    isActive: tabController.index == 1,
                    onTap: () => tabController.animateTo(1),
                  ),
                ),
                Expanded(
                  child: _TabItem(
                    icon: Icons.favorite_border_rounded,
                    label: 'Upvoted',
                    isActive: tabController.index == 2,
                    onTap: () => tabController.animateTo(2),
                  ),
                ),
              ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabController != tabController ||
      oldDelegate.isStudent != isStudent;
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? Colors.white : Colors.white38, size: 20),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white38,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 40 : 0,
              decoration: BoxDecoration(color: const Color(0xFFFF5A1F), borderRadius: BorderRadius.circular(1)),
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
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmt(count),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _ProfileActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ProfileActionBtn({required this.label, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFFF5A1F) : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: filled ? null : Border.all(color: const Color(0xFF333333)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.5,
            fontWeight: filled ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
