class UserModel {
  final String fullName;
  final String phone;
  final String email;
  final String username;
  final String password;
  final String token;

  UserModel({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.username,
    required this.password,
    required this.token,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'username': username,
        'password': password,
        'token': token,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        fullName: json['fullName'],
        phone: json['phone'],
        email: json['email'],
        username: json['username'],
        password: json['password'],
        token: json['token'],
      );
}