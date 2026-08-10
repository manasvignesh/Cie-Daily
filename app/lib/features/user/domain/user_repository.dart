abstract interface class UserRepository {
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String fullName,
    required String department,
    required int yearOfStudy,
  });

  Future<Map<String, dynamic>?> getUserProfile(String uid);
}
