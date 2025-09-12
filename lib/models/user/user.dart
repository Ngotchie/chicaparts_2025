class User {
  final int id;
  final String name;
  final String email;
  final dynamic thirdParty;

  User(this.id, this.name, this.email, this.thirdParty);

  // Méthode pour convertir un JSON en User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      json['id'] is int
          ? json['id']
          : int.parse(json['id'].toString()), // Convertit ID en int
      json['name'],
      json['email'],
      json['thirdParty'], // Peut être null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'thirdParty': thirdParty,
    };
  }

  bool get isEmpty => email.isEmpty;
}
