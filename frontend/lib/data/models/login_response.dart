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
      id: _toInt(json['id']),
      name: _str(json['name'] ?? json['Name']),
      employeeCode: _str(
        json['employeeCode'] ??
            json['EmployeeCode'] ??
            json['employee_code'] ??
            json['empCode'] ??
            json['EmpCode'],
      ),
      email: _str(json['email'] ?? json['Email']),
      location: _str(json['location'] ?? json['Location']),
      locationCode: _str(json['locationcode'] ?? json['locationCode'] ?? json['LocationCode']),
      city: _str(json['city'] ?? json['City']),
      department: _str(json['department'] ?? json['Department']),
      contactNumber: _str(json['contactNumber'] ?? json['ContactNumber']),
      role: _str(json['role'] ?? json['Role']),
      ipAddress: _str(json['ipAddress'] ?? json['IpAddress'] ?? json['IPAddress']),
      profileDescription: _str(json['profileDescription'] ?? json['ProfileDescription']),
      profileId: _str(json['profileId'] ?? json['ProfileId'] ?? json['profileID']),
    );
  }

  static String _str(dynamic v) => v?.toString() ?? '';
  static int _toInt(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;
}

/// Full response model for HDFC DataLake Login API
class LoginResponse {
  final String token;
  final String refreshToken;
  final LoginUser user;

  LoginResponse({
    this.token = '',
    this.refreshToken = '',
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    return LoginResponse(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      user: LoginUser.fromJson(userJson),
    );
  }
}
