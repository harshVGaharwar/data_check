/// User object returned inside the login response
class LoginUser {
  final int id;
  final String name;
  final String employeeCode;
  final String email;
  final String location;
  final String locationCode;
  final String city;
  final String department;
  final String contactNumber;
  final String role;
  final String ipAddress;
  final String profileDescription;
  final String profileId;

  LoginUser({
    this.id = 0,
    this.name = '',
    this.employeeCode = '',
    this.email = '',
    this.location = '',
    this.locationCode = '',
    this.city = '',
    this.department = '',
    this.contactNumber = '',
    this.role = '',
    this.ipAddress = '',
    this.profileDescription = '',
    this.profileId = '',
  });

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    return LoginUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      employeeCode: json['employeeCode'] as String? ?? '',
      email: json['email'] as String? ?? '',
      location: json['location'] as String? ?? '',
      locationCode: json['locationcode'] as String? ?? '',
      city: json['city'] as String? ?? '',
      department: json['department'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      role: json['role'] as String? ?? '',
      ipAddress: json['ipAddress'] as String? ?? '',
      profileDescription: json['profileDescription'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
    );
  }
}

/// Single entry in the applist
class AppItem {
  final String appname;
  final String dbVault;
  final List<String> sValues;
  final int itgrcCode;

  AppItem({
    this.appname = '',
    this.dbVault = '',
    this.sValues = const [],
    this.itgrcCode = 0,
  });

  factory AppItem.fromJson(Map<String, dynamic> json) {
    return AppItem(
      appname: json['appname'] as String? ?? '',
      dbVault: json['dbVault'] as String? ?? '',
      sValues: (json['sValues'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      itgrcCode: json['itgrcCode'] as int? ?? 0,
    );
  }
}

/// Full response model for HDFC DataLake Login API
class LoginResponse {
  final String token;
  final String refreshToken;
  final LoginUser user;
  final List<AppItem> applist;

  LoginResponse({
    this.token = '',
    this.refreshToken = '',
    required this.user,
    this.applist = const [],
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final applistJson = json['applist'] as List<dynamic>? ?? [];
    return LoginResponse(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: LoginUser.fromJson(userJson),
      applist: applistJson
          .map((e) => AppItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
