import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class DataPopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> populateDatabase() async {
    debugPrint("=== STARTING DATABASE POPULATION ===");

    // 1. Populate Technologies
    final techDocs = {
      'tech_flutter': {'name': 'Flutter', 'parentTechnologyId': null, 'description': 'Cross-platform mobile framework by Google.'},
      'tech_android': {'name': 'Android', 'parentTechnologyId': null, 'description': 'Native Android development.'},
      'tech_web': {'name': 'Web Development', 'parentTechnologyId': null, 'description': 'Frontend and backend web technologies.'},
      'tech_ai': {'name': 'AI', 'parentTechnologyId': null, 'description': 'Artificial Intelligence and deep learning.'},
      'tech_ml': {'name': 'Machine Learning', 'parentTechnologyId': 'tech_ai', 'description': 'Algorithms and statistical models.'},
      'tech_cybersec': {'name': 'Cybersecurity', 'parentTechnologyId': null, 'description': 'Information security and ethical hacking.'},
      'tech_cloud': {'name': 'Cloud Computing', 'parentTechnologyId': null, 'description': 'AWS, Azure, GCP and cloud architecture.'},
      'tech_iot': {'name': 'IoT', 'parentTechnologyId': null, 'description': 'Internet of Things.'},
      'tech_robotics': {'name': 'Robotics', 'parentTechnologyId': null, 'description': 'Hardware and software robotics.'},
      'tech_devops': {'name': 'DevOps', 'parentTechnologyId': null, 'description': 'CI/CD, Docker, Kubernetes.'},
      'tech_blockchain': {'name': 'Blockchain', 'parentTechnologyId': null, 'description': 'Web3, smart contracts, crypto.'},
      'tech_uiux': {'name': 'UI/UX Design', 'parentTechnologyId': null, 'description': 'User interface and experience design.'},
    };

    final batch = _firestore.batch();

    for (var entry in techDocs.entries) {
      final docRef = _firestore.collection('technologies').doc(entry.key);
      batch.set(docRef, {
        'technologyId': entry.key,
        'name': entry.value['name'],
        'parentTechnologyId': entry.value['parentTechnologyId'],
        'description': entry.value['description'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // 2. Populate Sample Users
    final users = [
      {'uid': 'user_1', 'name': 'Alice Engineer', 'role': 'moderator', 'bio': 'Flutter enthusiast.'},
      {'uid': 'user_2', 'name': 'Bob Hacker', 'role': 'student', 'bio': 'Cybersecurity researcher.'},
      {'uid': 'user_3', 'name': 'Charlie Cloud', 'role': 'platform_admin', 'bio': 'Cloud architect.'},
      {'uid': 'user_4', 'name': 'Diana AI', 'role': 'student', 'bio': 'Machine learning researcher.'},
      {'uid': 'user_5', 'name': 'Eve Designer', 'role': 'student', 'bio': 'UI/UX specialist.'},
    ];

    for (var user in users) {
      final docRef = _firestore.collection('users').doc(user['uid']);
      batch.set(docRef, {
        'uid': user['uid'],
        'email': '${user['uid']}@cie.edu',
        'name': user['name'],
        'college': 'CIE',
        'branch': 'Computer Science',
        'yearOfStudy': 3,
        'bio': user['bio'],
        'photoUrl': 'https://i.pravatar.cc/150?u=${user['uid']}',
        'role': user['role'],
        'skills': ['Dart', 'Python', 'Figma'],
        'joinedSpaceIds': [],
        'savedPostIds': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // 3. Populate Spaces
    final spaces = {
      'space_flutter': {'techId': 'tech_flutter', 'name': 'Flutter Development', 'desc': 'Learn cross-platform mobile development.'},
      'space_ai': {'techId': 'tech_ai', 'name': 'Artificial Intelligence', 'desc': 'Discuss AI news, papers, and models.'},
      'space_web': {'techId': 'tech_web', 'name': 'Web Wizards', 'desc': 'React, Vue, and all things web.'},
      'space_cyber': {'techId': 'tech_cybersec', 'name': 'Cybersecurity Hub', 'desc': 'Ethical hacking and security research.'},
      'space_cloud': {'techId': 'tech_cloud', 'name': 'Cloud Engineers', 'desc': 'AWS, GCP, Azure infrastructure.'},
    };

    for (var entry in spaces.entries) {
      final docRef = _firestore.collection('spaces').doc(entry.key);
      batch.set(docRef, {
        'spaceId': entry.key,
        'technologyId': entry.value['techId'],
        'name': entry.value['name'],
        'description': entry.value['desc'],
        'coverImageUrl': 'https://picsum.photos/seed/${entry.key}/800/400',
        'iconUrl': 'https://picsum.photos/seed/${entry.key}_icon/150/150',
        'memberCount': Random().nextInt(500) + 10,
        'moderatorIds': ['user_1'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    debugPrint("=== BATCH 1 COMMITTED (Tech, Users, Spaces) ===");

    // 4. Populate 50+ Posts
    debugPrint("=== STARTING BATCH 2 (Posts) ===");
    final postBatch = _firestore.batch();
    final categories = ['Tutorial', 'Question', 'Project Showcase', 'Resource', 'Event', 'Internship', 'Hackathon', 'Discussion', 'News'];
    
    final postTemplates = [
      "Understanding async/await",
      "Best practices for secure APIs",
      "Deploying to AWS EC2",
      "Building a custom UI widget",
      "Introduction to Neural Networks",
      "Top 10 VSCode Extensions",
      "How to prep for a hackathon",
      "Looking for team members",
      "My first Open Source contribution",
      "New release of our framework"
    ];

    for (int i = 0; i < 60; i++) {
      final spaceKey = spaces.keys.elementAt(Random().nextInt(spaces.length));
      final spaceData = spaces[spaceKey]!;
      final userKey = users[Random().nextInt(users.length)]['uid'];
      final template = postTemplates[Random().nextInt(postTemplates.length)];
      
      final docRef = _firestore.collection('posts').doc('post_$i');
      postBatch.set(docRef, {
        'postId': 'post_$i',
        'authorId': userKey,
        'primarySpaceId': spaceKey,
        'relatedSpaceIds': [],
        'technologyIds': [spaceData['techId']],
        'category': categories[Random().nextInt(categories.length)],
        'status': 'approved',
        'title': '$template ${i + 1}',
        'description': 'This is an autogenerated post description containing valuable educational content for students. #learning',
        'mediaUrls': Random().nextBool() ? ['https://picsum.photos/seed/post$i/600/400'] : [],
        'externalLinks': [],
        'likesCount': Random().nextInt(100),
        'commentsCount': Random().nextInt(20),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await postBatch.commit();
    debugPrint("=== DATABASE POPULATION COMPLETE ===");
  }
}
