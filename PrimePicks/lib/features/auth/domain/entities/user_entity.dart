class UserEntity {
  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String role;
  final String referralCode;
  final int loyaltyPoints;
  final bool isActive;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.avatarUrl,
    required this.role,
    required this.referralCode,
    required this.loyaltyPoints,
    required this.isActive,
    required this.createdAt,
  });

  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';
  bool get isPremium => role == 'AFFILIATE' || isAdmin;

  String get displayName => fullName ?? email?.split('@').first ?? 'Utilisateur';
  String get initials {
    final parts = (fullName ?? email ?? 'U').split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
