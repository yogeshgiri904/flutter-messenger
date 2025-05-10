class ProfileUser {
  final String id;
  final String name;
  final String email;
  final String gender;

  ProfileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.gender,

  });

  factory ProfileUser.fromMap(String id, Map<String, dynamic> map) {
    return ProfileUser(
      id: id,
      name: map['name'] ?? 'No name',
      email: map['email'] ?? 'No email',
      gender: map['gender'] ?? 'No gender',
    );
  }
}
