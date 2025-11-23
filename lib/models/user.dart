class UserModel {
  final String id;
  final String name;
  final String role;
  final String last_name;
  final String rut;
  final String mail;
  final String? photo_url;

  UserModel({
    required this.id,
    required this.name,
    required this.last_name,
    required this.rut,
    required this.mail,
    required this.role,
    this.photo_url,
  });

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      last_name: data['last_name'] ?? '',
      rut: data['rut'] ?? '',
      mail: data['mail'] ?? '',
      role: data['role'] ?? 'student',
      photo_url: data['photo_url'],
    );
  }
}
