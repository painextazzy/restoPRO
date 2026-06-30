class User {
  final int id;
  final String nom;
  final String email;
  final String? imageUrl;

  User({
    required this.id,
    required this.nom,
    required this.email,
    this.imageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'image_url': imageUrl,
    };
  }

  User copyWith({
    int? id,
    String? nom,
    String? email,
    String? imageUrl,
  }) {
    return User(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
