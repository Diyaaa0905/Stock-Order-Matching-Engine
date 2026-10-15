class UserModel {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final double balance;
  final double realizedPnL;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.balance,
    this.realizedPnL = 0.0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      realizedPnL: (json['realizedPnL'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'balance': balance,
      'realizedPnL': realizedPnL,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    double? balance,
    double? realizedPnL,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      balance: balance ?? this.balance,
      realizedPnL: realizedPnL ?? this.realizedPnL,
    );
  }
}
