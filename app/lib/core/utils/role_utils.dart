enum UserRole {
  MAIN_ADMIN,
  CREATOR,
  STUDENT,
}

const String mainAdminEmail = 'manasvig43@gmail.com';

const Set<String> creatorAllowlist = {
  '23r21a05m8@mlrit.ac.in',
  '23r21a6721@mlrit.ac.in',
  '23r21a1285@mlrit.ac.in',
  '24r21a05hg@mlrit.ac.in',
  '24r21a05gw@mlrit.ac.in',
  '24r21a05jn@mlrit.ac.in',
  '24r21a6779@mlrit.ac.in',
  '24r21a6778@mlrit.ac.in',
  '24r21a6771@mlrit.ac.in',
  '24r21a67d2@mlrit.ac.in',
  '24r21a6619@mlrit.ac.in',
  '24r21a04a4@mlrit.ac.in',
  '24r21a0314@mlrit.ac.in',
  '25a21a0589@mlrit.ac.in',
  '25r21a05bh@mlrit.ac.in',
  '25r21a05lg@mlrit.ac.in',
  '25r21a6763@mlrit.ac.in',
  '25r21a67b3@mlrit.ac.in',
  '25r21a67g9@mlrit.ac.in',
  '25r21a6620@mlrit.ac.in',
  '25r21a6644@mlrit.ac.in',
  '25r21a0426@mlrit.ac.in',
  '25r21a0488@mlrit.ac.in',
  '25r21a0498@mlrit.ac.in',
  '25r21a04a4@mlrit.ac.in',
  '23r21a05u2@mlrit.ac.in',
  '23r21a6759@mlrit.ac.in',
  '23r21a67j5@mlrit.ac.in',
  '23r21a6667@mlrit.ac.in',
  '24r21a0503@mlrit.ac.in',
  '24r21a0545@mlrit.ac.in',
  '24r21a05k8@mlrit.ac.in',
  '24r21a67e9@mlrit.ac.in',
  '24r21a0431@mlrit.ac.in',
  '25r21a0571@mlrit.ac.in',
  '25r21a05b7@mlrit.ac.in',
  '25r21a05g6@mlrit.ac.in',
  '25r21a6607@mlrit.ac.in',
  '25r21a0429@mlrit.ac.in',
  '23r21a05g5@mlrit.ac.in',
  '23r21a05z4@mlrit.ac.in',
  '23r21a05be@mlrit.ac.in',
  '23r21a12q5@mlrit.ac.in',
  '24r21a0502@mlrit.ac.in',
  '24r21a05aw@mlrit.ac.in',
  '24r21a05ad@mlrit.ac.in',
  '24r21a05cv@mlrit.ac.in',
  '24r21a05fa@mlrit.ac.in',
  '24r21a67j0@mlrit.ac.in',
  '24r21a6670@mlrit.ac.in',
  '25r21a05eu@mlrit.ac.in',
  '25r21a05g5@mlrit.ac.in',
  '25r21a05ll@mlrit.ac.in',
  '25r21a6624@mlrit.ac.in',
  '25r21a66k0@mlrit.ac.in',
  '25r21a0202@mlrit.ac.in',
  '23r21a05k9@mlrit.ac.in',
  '23r21a6661@mlrit.ac.in',
  '24r21a0505@mlrit.ac.in',
  '24r21a0596@mlrit.ac.in',
  '24r21a05gm@mlrit.ac.in',
  '25r21a05be@mlrit.ac.in',
  '25r21a05g9@mlrit.ac.in',
  '25r21a04c0@mlrit.ac.in',
  '25r21a2131@mlrit.ac.in',
  '25r21a0332@mlrit.ac.in',
  '23r21a05bn@mlrit.ac.in',
  '23r21a6731@mlrit.ac.in',
  '23r21a67d3@mlrit.ac.in',
  '23r21a67k2@mlrit.ac.in',
  '24r21a0537@mlrit.ac.in',
  '24r21a0587@mlrit.ac.in',
  '24r21a05ew@mlrit.ac.in',
  '24r21a05h4@mlrit.ac.in',
  '24r21a6773@mlrit.ac.in',
  '24r21a0489@mlrit.ac.in',
  '25r21a05c5@mlrit.ac.in',
  '25r21a05f5@mlrit.ac.in',
  '25r21a05gt@mlrit.ac.in',
  '25r21a05le@mlrit.ac.in',
  '25r21a6640@mlrit.ac.in',
  '23r21a6757@mlrit.ac.in',
  '23r21a6611@mlrit.ac.in',
  '24r21a05d6@mlrit.ac.in',
  '24r21a6725@mlrit.ac.in',
  '24r21a6714@mlrit.ac.in',
  '24r21a0487@mlrit.ac.in',
  '25r21a0511@mlrit.ac.in',
  '25r21a6707@mlrit.ac.in',
  '25r21a6787@mlrit.ac.in',
  '25r21a66b6@mlrit.ac.in',
  '25r21a0485@mlrit.ac.in',
  '23r21a0562@mlrit.ac.in',
  '23r21a0565@mlrit.ac.in',
  '23r21a6636@mlrit.ac.in',
  '24r21a0513@mlrit.ac.in',
  '24r21a0579@mlrit.ac.in',
  '24r21a0592@mlrit.ac.in',
  '24r21a05bt@mlrit.ac.in',
  '24r21a05db@mlrit.ac.in',
  '25r21a0558@mlrit.ac.in',
  '25r21a6798@mlrit.ac.in',
  '25r21a0418@mlrit.ac.in',
  '25r21a0442@mlrit.ac.in',
};

UserRole getUserRole(String? rawEmail) {
  if (rawEmail == null || rawEmail.trim().isEmpty) return UserRole.STUDENT;
  final email = rawEmail.toLowerCase().trim();
  if (email == mainAdminEmail) return UserRole.MAIN_ADMIN;
  if (creatorAllowlist.contains(email)) return UserRole.CREATOR;
  return UserRole.STUDENT;
}

bool isVerifiedUser(String? rawEmail) {
  final role = getUserRole(rawEmail);
  return role == UserRole.MAIN_ADMIN || role == UserRole.CREATOR;
}

bool canCreateContent(String? rawEmail) {
  final role = getUserRole(rawEmail);
  return role == UserRole.MAIN_ADMIN || role == UserRole.CREATOR;
}

bool canManageAnyContent(String? rawEmail) {
  return getUserRole(rawEmail) == UserRole.MAIN_ADMIN;
}

bool canHostLiveSpace(String? rawEmail) {
  final role = getUserRole(rawEmail);
  return role == UserRole.MAIN_ADMIN || role == UserRole.CREATOR;
}
