import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../feed/models/post_model.dart';
import '../../../core/utils/role_utils.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../../core/widgets/data_display/app_avatar.dart';
import '../../chat/providers/chat_providers.dart';
import '../../user/data/firebase_user_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/breakpoint_logo.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/errors/error_mapper.dart';

String _profileString(
  Map<String, dynamic>? data,
  String key, {
  String fallback = '',
}) {
  final value = data?[key];
  if (value is! String) return fallback;
  final normalized = value.trim();
  return normalized.isEmpty ? fallback : normalized;
}

int _profileCount(
  Map<String, dynamic>? data, {
  required String countKey,
  required String listKey,
}) {
  final count = data?[countKey];
  if (count is num && count.isFinite) return count.toInt().clamp(0, 1 << 31);
  final list = data?[listKey];
  return list is List ? list.length : 0;
}

List<String> _parseInterests(Map<String, dynamic>? profileData) {
  const defaults = <String>[
    'Campus',
    'Events',
    'Sports',
    'Art',
    'Tech',
  ];
  if (profileData == null) return defaults;

  if (profileData.containsKey('interests')) {
    final raw = profileData['interests'];
    if (raw is Iterable) {
      final result = <String>[];
      for (final item in raw) {
        if (item is String && item.trim().isNotEmpty) {
          final val = item.trim();
          if (!result.contains(val)) result.add(val);
        }
      }
      return result;
    }
  }

  if (profileData.containsKey('highlights')) {
    final raw = profileData['highlights'];
    if (raw is Iterable) {
      final result = <String>[];
      for (final item in raw) {
        if (item is Map) {
          final label = item['label'];
          if (label is String && label.trim().isNotEmpty) {
            final val = label.trim();
            if (!result.contains(val)) result.add(val);
          }
        } else if (item is String && item.trim().isNotEmpty) {
          final val = item.trim();
          if (!result.contains(val)) result.add(val);
        }
      }
      if (result.isNotEmpty) return result;
    }
  }

  return defaults;
}

class ProfileScreen extends ConsumerStatefulWidget {
  final String? targetUserId;

  const ProfileScreen({super.key, this.targetUserId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final viewedUid =
        (widget.targetUserId != null && widget.targetUserId!.isNotEmpty)
            ? widget.targetUserId!
            : user?.uid;
    final isSelf = user != null && (viewedUid == user.uid);

    final userProfileAsync = viewedUid != null && !isSelf
        ? ref.watch(userProfileStreamProvider(viewedUid))
        : ref.watch(userProfileProvider);

    final isFollowing = (viewedUid != null && !isSelf)
        ? ref.watch(isFollowingProvider(viewedUid))
        : false;

    final userPostsAsync = ref.watch(userPostsProvider);
    final bookmarkedPostsAsync = ref.watch(bookmarkedPostsProvider);
    final likedPostsAsync = ref.watch(likedPostsProvider);
    final conversationsAsync = ref.watch(conversationsProvider);
    final selfConnectionCodeAsync =
        isSelf ? ref.watch(connectionCodeProvider) : null;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(color: AppTheme.primaryTextColor(context)),
          ),
        ),
      );
    }

    final userRole = getUserRole(user.email);
    final isStudent = userRole == UserRole.student;

    return userProfileAsync.when(
      data: (profileData) {
        final rawName = _profileString(
          profileData,
          'name',
          fallback: isSelf ? (user.displayName ?? '') : 'Campus Member',
        );
        final profileEmail = _profileString(
          profileData,
          'email',
          fallback: isSelf ? (user.email ?? '') : '',
        );
        final emailPrefix = profileEmail.split('@').first;
        final displayName = rawName.isNotEmpty
            ? rawName
            : (emailPrefix.isNotEmpty ? emailPrefix : 'Student');
        final handle =
            '@${displayName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';
        final isCreatorOrAdmin = canCreateContent(profileEmail);

        final bio = _profileString(
          profileData,
          'bio',
          fallback: isStudent
              ? 'Learning, exploring & connecting on campus ✨'
              : 'Sharing campus life, one drop at a time ✨',
        );
        final department =
            _profileString(profileData, 'department', fallback: 'CS');
        final yearOfStudy = profileData?['yearOfStudy']?.toString() ?? '1';

        final storedPhotoUrl = _profileString(profileData, 'photoUrl');
        final photoUrl = storedPhotoUrl.isNotEmpty
            ? storedPhotoUrl
            : (isSelf ? user.photoURL : null);
        final postsCount = userPostsAsync.value?.length ?? 0;
        final savedCount = bookmarkedPostsAsync.value?.length ?? 0;
        final likedCount = likedPostsAsync.value?.length ?? 0;
        final connectionsCount = conversationsAsync.value?.length ?? 0;
        final interests = _parseInterests(profileData);
        final connectionCode = selfConnectionCodeAsync?.valueOrNull ??
            _profileString(profileData, 'connectionCode');

        final isDark = AppTheme.isDark(context);
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value:
              isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor(context),
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
                      // ── 1. HERO CARD ───────────────────────────────────────
                      _buildProfileHeaderCard(
                        context,
                        photoUrl: photoUrl,
                        displayName: displayName,
                        handle: handle,
                        bio: bio,
                        department: department,
                        yearOfStudy: yearOfStudy,
                        isCreatorOrAdmin: isCreatorOrAdmin,
                      ),

                      // ── 2. STATS ROW ───────────────────────────────────────
                      _buildStatsRow(
                        context,
                        isStudent: isStudent,
                        postsCount: postsCount,
                        savedCount: savedCount,
                        likedCount: likedCount,
                        connectionsCount: connectionsCount,
                        followersCount: _profileCount(
                          profileData,
                          countKey: 'followersCount',
                          listKey: 'followers',
                        ),
                        followingCount: _profileCount(
                          profileData,
                          countKey: 'followingCount',
                          listKey: 'following',
                        ),
                      ),

                      // ── 3. PRIMARY ACTION BUTTONS ──────────────────────────
                      _buildActionButtons(
                        context,
                        name: displayName,
                        bio: bio,
                        department: department,
                        yearOfStudy: yearOfStudy,
                        photoUrl: photoUrl,
                        isSelf: isSelf,
                        viewedUid: viewedUid,
                        isFollowing: isFollowing,
                      ),

                      // ── 4. CONNECTION CODE CARD ────────────────────────────
                      if (isSelf)
                        _buildConnectionCodeCard(context, connectionCode),

                      // ── 5. INTERESTS & FOCUS AREAS CARD ───────────────────
                      _buildInterestsCard(
                        context,
                        interests: interests,
                        isSelf: isSelf,
                      ),
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
                            emptyMessage:
                                'Bookmark articles and reels in your feed to read or watch later!',
                            emptyIcon: Icons.bookmark_border_rounded,
                          ),
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFFF5A1F))),
                          error: (e, _) => _buildTabError(context, e),
                        ),
                        // STUDENT TAB 2: Connections List
                        _buildConnectionsTab(context, connectionCode),
                        // STUDENT TAB 3: Upvoted / Liked Drops
                        likedPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Upvoted Drops Yet',
                            emptyMessage:
                                'Upvote reels and articles in your feed to save them here!',
                            emptyIcon: Icons.favorite_border_rounded,
                          ),
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFFF5A1F))),
                          error: (e, _) => _buildTabError(context, e),
                        ),
                      ]
                    : [
                        // CREATOR / ADMIN TAB 1: Published Drops
                        userPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Published Drops Yet',
                            emptyMessage:
                                'Create your first campus reel or article drop!',
                            emptyIcon: Icons.camera_alt_outlined,
                          ),
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFFF5A1F))),
                          error: (e, _) => _buildTabError(context, e),
                        ),
                        // CREATOR / ADMIN TAB 2: Saved Drops
                        bookmarkedPostsAsync.when(
                          data: (posts) => _buildPostsGrid(
                            context,
                            posts,
                            emptyTitle: 'No Saved Posts Yet',
                            emptyMessage:
                                'Bookmark posts to save them for later.',
                            emptyIcon: Icons.bookmark_border_rounded,
                          ),
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFFF5A1F))),
                          error: (e, _) => _buildTabError(context, e),
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
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFFF5A1F))),
                          error: (e, _) => _buildTabError(context, e),
                        ),
                      ],
              ),
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "We couldn't load this profile. Please try again.",
                style: TextStyle(color: AppTheme.secondaryTextColor(context)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  if (viewedUid != null && !isSelf) {
                    ref.invalidate(userProfileStreamProvider(viewedUid));
                  } else {
                    ref.invalidate(userProfileProvider);
                  }
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "We couldn't load this section. Please try again.",
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.secondaryTextColor(context)),
        ),
      ),
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
    final iconColor = AppTheme.primaryTextColor(context);
    return AppBar(
      backgroundColor: AppTheme.backgroundColor(context),
      elevation: 0,
      systemOverlayStyle: AppTheme.isDark(context)
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: const SizedBox.shrink(),
      title: Row(
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: iconColor,
              fontFamily: 'Outfit',
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          const BreakpointDotMarker(size: 8),
        ],
      ),
      centerTitle: false,
      actions: [
        if (isCreatorOrAdmin)
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: iconColor, size: 26),
            tooltip: 'Create Post',
            onPressed: () {
              context.push('/create_article_post');
            },
          ),
        IconButton(
          icon: Icon(Icons.menu_rounded, color: iconColor, size: 26),
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

  Widget _buildProfileHeaderCard(
    BuildContext context, {
    required String? photoUrl,
    required String displayName,
    required String handle,
    required String bio,
    required String department,
    required String yearOfStudy,
    required bool isCreatorOrAdmin,
  }) {
    final primaryColor = AppTheme.primaryTextColor(context);
    final secondaryColor = AppTheme.secondaryTextColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar + Name + Handle + Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileAvatar(context, photoUrl, displayName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Outfit',
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCreatorOrAdmin) ...[
                          const SizedBox(width: 6),
                          const VerifiedBadge(size: 18),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      handle,
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Micro Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Year $yearOfStudy · $department Dept 📚',
                        style: const TextStyle(
                          color: AppTheme.primaryOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bio Text
          Text(
            bio,
            style: TextStyle(
              color: primaryColor.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.45,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionCodeCard(
    BuildContext context,
    String connectionCode,
  ) {
    if (connectionCode.isEmpty) return const SizedBox.shrink();

    final primaryColor = AppTheme.primaryTextColor(context);
    final secondaryColor = AppTheme.secondaryTextColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_rounded,
              color: AppTheme.primaryOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connection Code',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connectionCode,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit',
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Clipboard.setData(ClipboardData(text: connectionCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connection code copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.copy_rounded,
                  color: AppTheme.primaryOrange,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(
      BuildContext context, String? photoUrl, String displayName) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryOrange, width: 2.0),
      ),
      child: CircleAvatar(
        radius: 40,
        backgroundColor: AppTheme.inputFillColor(context),
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null
            ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: TextStyle(
                    fontSize: 28,
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Outfit'),
              )
            : null,
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
    required int followersCount,
    required int followingCount,
  }) {
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: isStudent
            ? [
                _StatBox(count: savedCount, label: 'Saved Drops'),
                _buildStatDivider(context),
                _StatBox(count: connectionsCount, label: 'Connections'),
                _buildStatDivider(context),
                _StatBox(count: likedCount, label: 'Upvoted'),
              ]
            : [
                _StatBox(count: postsCount, label: 'Published'),
                _buildStatDivider(context),
                _StatBox(count: followersCount, label: 'Followers'),
                _buildStatDivider(context),
                _StatBox(count: followingCount, label: 'Following'),
              ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
        width: 1, height: 28, color: AppTheme.cardBorderColor(context));
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required String name,
    required String bio,
    required String department,
    required String yearOfStudy,
    required String? photoUrl,
    required bool isSelf,
    required String? viewedUid,
    required bool isFollowing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: isSelf
          ? Row(
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
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileActionBtn(
                    label: 'Share Profile',
                    onTap: () => _shareProfile(context, name),
                    filled: false,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null && viewedUid != null) {
                        ref.read(userRepositoryProvider).toggleFollowUser(
                              currentUserId: currentUser.uid,
                              targetUserId: viewedUid,
                              follow: !isFollowing,
                            );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing
                          ? AppTheme.surfaceMutedColor(context)
                          : AppTheme.primaryOrange,
                      foregroundColor: isFollowing
                          ? AppTheme.primaryTextColor(context)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isFollowing
                              ? AppTheme.cardBorderColor(context)
                              : AppTheme.primaryOrange,
                        ),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
        text: 'Check out $displayName on Breakpoint! Email: ${user.email}'));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile details copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInterestsCard(
    BuildContext context, {
    required List<String> interests,
    required bool isSelf,
  }) {
    final primaryText = AppTheme.primaryTextColor(context);
    final cardColor = AppTheme.cardColor(context);
    final borderColor = AppTheme.cardBorderColor(context);
    final isDark = AppTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interests & Focus Areas',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: primaryText,
                  fontFamily: 'Outfit',
                ),
              ),
              if (isSelf)
                Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showEditInterestsSheet(
                      context,
                      currentInterests: interests,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        interests.isEmpty ? '+ Add interests' : 'Edit',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: borderColor),
          const SizedBox(height: 12),
          if (interests.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((label) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMutedColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                );
              }).toList(),
            )
          else if (isSelf)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showEditInterestsSheet(
                  context,
                  currentInterests: interests,
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.inputFillColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 16, color: AppTheme.primaryOrange),
                      SizedBox(width: 6),
                      Text(
                        'Add interests',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryOrange),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Text(
              'No interests added yet',
              style: TextStyle(
                color: AppTheme.secondaryTextColor(context),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _showEditInterestsSheet(
    BuildContext context, {
    required List<String> currentInterests,
  }) {
    const defaultTopics = <String>[
      'Tech',
      'AI & ML',
      'Startups',
      'Coding',
      'Engineering',
      'Design',
      'Campus',
      'Events',
      'Sports',
      'Art',
      'Science',
      'New Tools',
      'Product',
      'Open Source',
    ];

    final customCtrl = TextEditingController();
    final selectedInterests = Set<String>.from(currentInterests);
    final availableTopics = List<String>.from(defaultTopics);
    for (final interest in currentInterests) {
      if (!availableTopics.contains(interest)) {
        availableTopics.add(interest);
      }
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = AppTheme.isDark(context);
          final primaryText = AppTheme.primaryTextColor(context);
          final secondaryText = AppTheme.secondaryTextColor(context);
          final cardBg = AppTheme.cardColor(context);
          final borderColor = AppTheme.cardBorderColor(context);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            margin: const EdgeInsets.all(12),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.tertiaryTextColor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Interests & Focus Areas',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Select topics you care about or add custom focus areas.',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableTopics.map((topic) {
                            final isSelected =
                                selectedInterests.contains(topic);
                            return Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: isSaving
                                    ? null
                                    : () {
                                        setSheetState(() {
                                          if (isSelected) {
                                            selectedInterests.remove(topic);
                                          } else {
                                            selectedInterests.add(topic);
                                          }
                                        });
                                      },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryOrange
                                        : AppTheme.surfaceMutedColor(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryOrange
                                          : borderColor,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected) ...[
                                        const Icon(
                                          Icons.check_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                      ],
                                      Text(
                                        topic,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : primaryText,
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: customCtrl,
                                enabled: !isSaving,
                                style: TextStyle(
                                  color: primaryText,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Add custom topic...',
                                  hintStyle: TextStyle(
                                    color: secondaryText,
                                    fontSize: 13,
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: AppTheme.inputFillColor(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                onSubmitted: (val) {
                                  final trimmed = val.trim();
                                  if (trimmed.isNotEmpty) {
                                    setSheetState(() {
                                      if (!availableTopics.contains(trimmed)) {
                                        availableTopics.add(trimmed);
                                      }
                                      selectedInterests.add(trimmed);
                                      customCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              onPressed: isSaving
                                  ? null
                                  : () {
                                      final trimmed = customCtrl.text.trim();
                                      if (trimmed.isNotEmpty) {
                                        setSheetState(() {
                                          if (!availableTopics
                                              .contains(trimmed)) {
                                            availableTopics.add(trimmed);
                                          }
                                          selectedInterests.add(trimmed);
                                          customCtrl.clear();
                                        });
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            isSaving ? null : () => Navigator.pop(sheetContext),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryText,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  Navigator.pop(sheetContext);
                                  return;
                                }

                                setSheetState(() => isSaving = true);
                                final updatedList = selectedInterests.toList();
                                final updatedHighlights = updatedList
                                    .map((item) => {
                                          'label': item,
                                          'color': '0xFFFF5A1F',
                                        })
                                    .toList();

                                try {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .set({
                                    'interests': updatedList,
                                    'highlights': updatedHighlights,
                                  }, SetOptions(merge: true));

                                  if (context.mounted) {
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Interests updated successfully'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    setSheetState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text(ErrorMapper.userMessage(e)),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
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
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        112 + MediaQuery.paddingOf(context).bottom,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = 112 + MediaQuery.paddingOf(context).bottom;
              final minContentHeight = constraints.maxHeight > bottomInset
                  ? constraints.maxHeight - bottomInset
                  : 0.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minContentHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 54, color: AppTheme.tertiaryTextColor(context)),
                      const SizedBox(height: 12),
                      Text(
                        'No Campus Connections Yet',
                        style: TextStyle(
                            color: AppTheme.primaryTextColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Share your Connection Code with peers in Breakpoint Chat to link accounts and share drops!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppTheme.secondaryTextColor(context),
                            fontSize: 13,
                            height: 1.45),
                      ),
                      const SizedBox(height: 16),
                      if (connectionCode.isNotEmpty)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5A1F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: connectionCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Connection Code copied!')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: Text('Copy Code: $connectionCode'),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            112 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: conversations.length,
          separatorBuilder: (_, __) =>
              Divider(color: AppTheme.cardBorderColor(context), height: 1),
          itemBuilder: (context, index) {
            final conv = conversations[index];
            final partnerId = conv.participants.firstWhere(
              (id) => id != currentUser?.uid,
              orElse: () => '',
            );
            final rawDetails = conv.participantDetails[partnerId];
            final details = rawDetails is Map
                ? rawDetails.map(
                    (key, value) => MapEntry(key.toString(), value),
                  )
                : const <String, dynamic>{};
            final partnerName = details['name']?.toString() ?? 'Student';
            final partnerAvatar = details['photoUrl']?.toString();

            return ListTile(
              leading: AppAvatar(
                imageUrl: partnerAvatar,
                fallbackText: partnerName,
                radius: 20,
              ),
              title: Text(
                partnerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
              subtitle: Text(
                'Connected Peer',
                style: TextStyle(
                    color: AppTheme.secondaryTextColor(context), fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Color(0xFFFF5A1F)),
                onPressed: () {
                  context.push('/chat/${conv.id}', extra: {
                    'partnerUid': partnerId,
                    'partnerName': partnerName,
                    'partnerPhoto': partnerAvatar,
                  });
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF5A1F))),
      error: (e, _) => _buildTabError(context, e),
    );
  }

  Widget _buildEmptyTab(
      BuildContext context, IconData icon, String title, String subtitle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bottomInset = 112 + MediaQuery.paddingOf(context).bottom;
        final minContentHeight = constraints.maxHeight > bottomInset
            ? constraints.maxHeight - bottomInset
            : 0.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 48, color: AppTheme.tertiaryTextColor(context)),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.secondaryTextColor(context),
                      fontSize: 13,
                      height: 1.45),
                ),
              ],
            ),
          ),
        );
      },
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.cardBorderColor(context), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
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
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 28),
                  ),
                )
              else if (hasVideo)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: Icon(Icons.play_circle_filled_rounded,
                      color: Colors.white,
                      size: 22,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)]),
                ),

              // Title overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75)
                      ],
                    ),
                  ),
                  child: Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.2),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  // ignore: unused_element
  void _showAddHighlightSheet(
      BuildContext context, List<Map<String, dynamic>> currentHighlights) {
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
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 16,
              left: 20,
              right: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cardBorderColor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.tertiaryTextColor(context),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('New Highlight',
                  style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: labelCtrl,
                style: TextStyle(color: AppTheme.primaryTextColor(context)),
                decoration: InputDecoration(
                  labelText: 'Highlight Title',
                  labelStyle:
                      TextStyle(color: AppTheme.secondaryTextColor(context)),
                  filled: true,
                  fillColor: AppTheme.inputFillColor(context),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Text('Theme Color',
                  style: TextStyle(
                      color: AppTheme.secondaryTextColor(context),
                      fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: colors.map((c) {
                  final isSel = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setSheetState(() => selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSel
                            ? Border.all(
                                color: AppTheme.primaryTextColor(context),
                                width: 3)
                            : null,
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

                  final updated =
                      List<Map<String, dynamic>>.from(currentHighlights);
                  updated.add({
                    'label': txt,
                    'color':
                        '0x${selectedColor.toARGB32().toRadixString(16).toUpperCase()}',
                  });

                  Navigator.pop(ctx);

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({
                    'highlights': updated,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A1F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Add Highlight',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
    File? selectedPhoto;
    bool removePhoto = false;

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Container(
          margin: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.90,
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom +
                  MediaQuery.paddingOf(sheetContext).bottom +
                  20,
              top: 16,
              left: 20,
              right: 20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(sheetContext),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cardBorderColor(sheetContext)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppTheme.tertiaryTextColor(sheetContext),
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Edit Profile',
                    style: TextStyle(
                        color: AppTheme.primaryTextColor(sheetContext),
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style:
                      TextStyle(color: AppTheme.primaryTextColor(sheetContext)),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(
                        color: AppTheme.secondaryTextColor(sheetContext)),
                    filled: true,
                    fillColor: AppTheme.inputFillColor(sheetContext),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioCtrl,
                  maxLines: 2,
                  style:
                      TextStyle(color: AppTheme.primaryTextColor(sheetContext)),
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(
                        color: AppTheme.secondaryTextColor(sheetContext)),
                    filled: true,
                    fillColor: AppTheme.inputFillColor(sheetContext),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deptCtrl,
                  style:
                      TextStyle(color: AppTheme.primaryTextColor(sheetContext)),
                  decoration: InputDecoration(
                    labelText: 'Department',
                    labelStyle: TextStyle(
                        color: AppTheme.secondaryTextColor(sheetContext)),
                    filled: true,
                    fillColor: AppTheme.inputFillColor(sheetContext),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  style:
                      TextStyle(color: AppTheme.primaryTextColor(sheetContext)),
                  decoration: InputDecoration(
                    labelText: 'Year of Study (1-4)',
                    labelStyle: TextStyle(
                        color: AppTheme.secondaryTextColor(sheetContext)),
                    filled: true,
                    fillColor: AppTheme.inputFillColor(sheetContext),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMutedColor(sheetContext),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.cardBorderColor(sheetContext)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.cardColor(sheetContext),
                        backgroundImage: selectedPhoto != null
                            ? FileImage(selectedPhoto!)
                            : (!removePhoto && photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null) as ImageProvider<Object>?,
                        child: selectedPhoto == null &&
                                (removePhoto || photoUrl == null)
                            ? Icon(Icons.person_rounded,
                                color:
                                    AppTheme.secondaryTextColor(sheetContext))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile photo',
                              style: TextStyle(
                                color: AppTheme.primaryTextColor(sheetContext),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Choose a clear photo from your gallery.',
                              style: TextStyle(
                                color:
                                    AppTheme.secondaryTextColor(sheetContext),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final picked =
                                        await ImagePicker().pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 88,
                                      maxWidth: 1200,
                                    );
                                    if (picked != null) {
                                      setSheetState(() {
                                        selectedPhoto = File(picked.path);
                                        removePhoto = false;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library_outlined,
                                      size: 17),
                                  label: const Text('Choose photo'),
                                ),
                                if (photoUrl != null || selectedPhoto != null)
                                  TextButton(
                                    onPressed: () => setSheetState(() {
                                      selectedPhoto = null;
                                      removePhoto = true;
                                    }),
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(
                                          color: Theme.of(sheetContext)
                                              .colorScheme
                                              .error),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final n = nameCtrl.text.trim();
                          final b = bioCtrl.text.trim();
                          final d = deptCtrl.text.trim();
                          final y = int.tryParse(yearCtrl.text.trim()) ?? 1;

                          if (n.isEmpty) return;

                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          setSheetState(() {
                            isSaving = true;
                          });

                          try {
                            String? nextPhotoUrl =
                                removePhoto ? null : photoUrl;
                            if (selectedPhoto != null) {
                              nextPhotoUrl =
                                  await CloudinaryService.uploadImage(
                                      selectedPhoto!);
                              if (nextPhotoUrl == null) {
                                throw Exception(
                                    'Could not upload profile photo');
                              }
                            }

                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .set({
                              'name': n,
                              'bio': b,
                              'department': d,
                              'yearOfStudy': y,
                              'photoUrl': nextPhotoUrl,
                            }, SetOptions(merge: true));

                            await user.updateDisplayName(n);
                            await user.updatePhotoURL(nextPhotoUrl);

                            ref.invalidate(userProfileProvider);

                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Profile updated successfully!'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            setSheetState(() {
                              isSaving = false;
                            });
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "We couldn't update your profile. Please try again.")),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A1F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.90,
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.cardBorderColor(context)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: AppTheme.secondaryTextColor(context)
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Settings',
                          style: TextStyle(
                              color: AppTheme.primaryTextColor(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700))),
                ),
                _SettingsTile(
                  icon: Icons.edit_rounded,
                  label: 'Edit Profile',
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _showEditProfileSheet(context,
                        name: name,
                        bio: bio,
                        department: department,
                        yearOfStudy: yearOfStudy,
                        photoUrl: photoUrl);
                  },
                ),

                // ── APPEARANCE / THEME SELECTOR ─────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Appearance',
                        style: TextStyle(
                            color: AppTheme.accentColor(context),
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                Consumer(
                  builder: (ctx, ref, _) {
                    final appearance = ref.watch(appearanceProvider);
                    final primaryText = AppTheme.primaryTextColor(ctx);
                    final secondaryText = AppTheme.secondaryTextColor(ctx);
                    return RadioGroup<AppearanceMode>(
                      groupValue: appearance.mode,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(appearanceProvider.notifier)
                              .setAppearance(value);
                        }
                      },
                      child: Column(
                        children: [
                          RadioListTile<AppearanceMode>(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text('Automatic',
                                style: TextStyle(
                                    color: primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            subtitle: Text('Follow the time of day',
                                style: TextStyle(
                                    color: secondaryText, fontSize: 12)),
                            value: AppearanceMode.automatic,
                            activeColor: AppTheme.accentColor(ctx),
                          ),
                          RadioListTile<AppearanceMode>(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text('Sunlight',
                                style: TextStyle(
                                    color: primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            subtitle: Text('Warm orange atmosphere',
                                style: TextStyle(
                                    color: secondaryText, fontSize: 12)),
                            value: AppearanceMode.sunlight,
                            activeColor: AppTheme.accentColor(ctx),
                          ),
                          RadioListTile<AppearanceMode>(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            title: Text('Moonlight',
                                style: TextStyle(
                                    color: primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                            subtitle: Text('Cool sky-blue atmosphere',
                                style: TextStyle(
                                    color: secondaryText, fontSize: 12)),
                            value: AppearanceMode.moonlight,
                            activeColor: AppTheme.accentColor(ctx),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Divider(color: AppTheme.cardBorderColor(context), height: 1),

                _SettingsTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).pop()),
                _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    label: 'Privacy',
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).pop()),
                Consumer(
                  builder: (ctx, ref, _) {
                    final userProfile = ref.watch(userProfileProvider).value;
                    final autoAccept =
                        userProfile?['autoAcceptRequests'] as bool? ?? false;
                    return SwitchListTile(
                      secondary: Icon(Icons.handshake_outlined,
                          color: AppTheme.primaryTextColor(ctx)),
                      title: Text('Auto-Accept Connection Requests',
                          style: TextStyle(
                              color: AppTheme.primaryTextColor(ctx),
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          autoAccept
                              ? 'Automatically accept incoming requests'
                              : 'Manually review incoming requests',
                          style: TextStyle(
                              color: AppTheme.secondaryTextColor(ctx),
                              fontSize: 12)),
                      value: autoAccept,
                      activeThumbColor: AppTheme.primaryOrange,
                      onChanged: (val) async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({'autoAcceptRequests': val});
                        }
                      },
                    );
                  },
                ),
                _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    label: 'Help & Support',
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).pop()),
                Divider(color: AppTheme.cardBorderColor(context), height: 1),
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(authControllerProvider.notifier).logout();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevatedColor(context),
        border: Border(
          bottom: BorderSide(color: AppTheme.cardBorderColor(context)),
        ),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                      alpha: AppTheme.isDark(context) ? 0.24 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
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
  bool shouldRebuild(_TabBarDelegate oldDelegate) => true;
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
                Icon(
                  icon,
                  color: isActive
                      ? AppTheme.primaryTextColor(context)
                      : AppTheme.secondaryTextColor(context),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryTextColor(context)
                        : AppTheme.secondaryTextColor(context),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 3,
              width: isActive ? 28 : 0,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(1.5),
              ),
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
          style: TextStyle(
              color: AppTheme.primaryTextColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
              color: AppTheme.secondaryTextColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class _ProfileActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ProfileActionBtn(
      {required this.label, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: filled ? AppTheme.primaryOrange : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: filled
              ? null
              : Border.all(color: AppTheme.cardBorderColor(context)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : AppTheme.primaryTextColor(context),
            fontSize: 14,
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
  final Color? color;

  const _SettingsTile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryTextColor(context);
    return ListTile(
      leading: Icon(icon, color: effectiveColor),
      title: Text(label,
          style: TextStyle(
              color: effectiveColor,
              fontSize: 15,
              fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
