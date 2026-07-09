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

  final List<MenuPermission> menuList;
  final List<TemplateType> templateType;
  final ReportDate reportDate;
  final List<ModuleItem> moduleList;

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
    this.menuList = const [],
    this.templateType = const [],
    this.moduleList = const [],
    ReportDate? reportDate,
  }) : reportDate = reportDate ?? ReportDate();

  factory LoginUser.fromJson(Map<String, dynamic> json) {
    final list = json['menuList'] ?? [];
    final templateTypeList = json['templateType'] ?? [];
    final moduleListJson = json['moduleList'] ?? [];

    return LoginUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      employeeCode: json['employeeCode'] ?? '',
      email: json['email'] ?? '',
      location: json['location'] ?? '',
      locationCode: json['locationCode'] ?? '',
      city: json['city'] ?? '',
      department: json['department'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      role: json['role'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      profileDescription: json['profileDescription'] ?? '',
      profileId: json['profileId'] ?? '',
      menuList: List<MenuPermission>.from(
        list.map((m) => MenuPermission.fromJson(m)),
      ),
      templateType: List<TemplateType>.from(
        templateTypeList.map((t) => TemplateType.fromJson(t)),
      ),
      moduleList: List<ModuleItem>.from(
        moduleListJson.map((m) => ModuleItem.fromJson(m)),
      ),
      reportDate: ReportDate.fromJson(json['reportDate'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'employeeCode': employeeCode,
      'email': email,
      'location': location,
      'locationCode': locationCode,
      'city': city,
      'department': department,
      'contactNumber': contactNumber,
      'role': role,
      'ipAddress': ipAddress,
      'profileDescription': profileDescription,
      'profileId': profileId,
      'menuList': menuList.map((m) => m.toJson()).toList(),
      'templateType': templateType.map((t) => t.toJson()).toList(),
      'moduleList': moduleList.map((m) => m.toJson()).toList(),
      'reportDate': reportDate.toJson(),
    };
  }
}

class MenuPermission {
  final int id;
  final String menuName;
  final String profileId;
  final String isActive;

  MenuPermission({
    required this.id,
    required this.menuName,
    required this.profileId,
    required this.isActive,
  });

  factory MenuPermission.fromJson(Map<String, dynamic> json) {
    return MenuPermission(
      id: json['id'] ?? 0,
      menuName: json['menuName'] ?? '',
      profileId: json['profileId'] ?? '',
      isActive: json['isActive'] ?? 'N',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menuName': menuName,
      'profileId': profileId,
      'isActive': isActive,
    };
  }

  bool get isEnabled => isActive.toUpperCase() == "Y";
}

class ModuleItem {
  final int id;
  final String name;
  final String profileID;
  final String spflag;

  ModuleItem({
    required this.id,
    required this.name,
    required this.profileID,
    required this.spflag,
  });

  factory ModuleItem.fromJson(Map<String, dynamic> json) {
    return ModuleItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profileID: json['profileID'] ?? '',
      spflag: json['spflag'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'profileID': profileID, 'spflag': spflag};
  }
}

class TemplateType {
  final String name;
  final int id;

  TemplateType({required this.name, required this.id});

  factory TemplateType.fromJson(Map<String, dynamic> json) {
    return TemplateType(name: json['name'] ?? '', id: json['id'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'id': id};
  }
}

class ReportDate {
  final int daycount;

  ReportDate({this.daycount = 0});

  factory ReportDate.fromJson(Map<String, dynamic> json) {
    return ReportDate(daycount: json['daycount'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'daycount': daycount};
  }
}

class LoginResponse {
  final String token;
  final String refreshToken;
  final LoginUser user;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: LoginUser.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }
}
//TODO