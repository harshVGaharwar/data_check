/// Request model for HDFC DataLake Login API
/// POST /DataLake_API/api/account/Login
class LoginRequest {
  final int id;
  final String name;
  final String employeeCode;
  final String email;
  final String password;
  final String location;
  final String locationCode;
  final String city;
  final String department;
  final String contactNumber;
  final String role;
  final String ipAddress;
  final String profileDescription;
  final String profileId;

  // Static employee code until dynamic resolution is implemented
  static const String _staticEmployeeCode = 'n23649';

  LoginRequest({
    required this.name,
    required this.password,
    this.id = 0,
    this.employeeCode = _staticEmployeeCode,
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

  Map<String, dynamic> toJson() => {
    'Id': id,
    'Name': name,
    'EmployeeCode': employeeCode,
    'Email': email,
    'password': password,
    'Location': location,
    'LOCATIONCODE': locationCode,
    'City': city,
    'Department': department,
    'ContactNumber': contactNumber,
    'Role': role,
    'IPAddress': ipAddress,
    'ProfileDescription': profileDescription,
    'ProfileId': profileId,
  };
}
