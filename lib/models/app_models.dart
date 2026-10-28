class UserProfile {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? designation;
  final String? phone;
  final String? joiningDate;
  final String status;
  final String? avatar;
  final double basicSalary;
  final double hra;
  final double specialAllowance;
  final double deductions;
  final double netSalary;

  // Registration & Onboarding Details (Employees & Interns)
  final String? candidateType;
  final String? dob;
  final String? gender;
  final String? college;
  final String? degree;
  final String? gradYear;
  final String? currentSem;
  final String? cgpa;
  final String? prevCompany;
  final String? experience;
  final String? skills;
  final String? reportingManager;
  final String? workMode;
  final String? resumeFileName;
  final String? companyEmail;
  final String? personalEmail;

  UserProfile({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.designation,
    this.phone,
    this.joiningDate,
    this.status = 'ACTIVE',
    this.avatar,
    this.basicSalary = 14000.0,
    this.hra = 6000.0,
    this.specialAllowance = 0.0,
    this.deductions = 0.0,
    this.netSalary = 20000.0,
    this.candidateType,
    this.dob,
    this.gender,
    this.college,
    this.degree,
    this.gradYear,
    this.currentSem,
    this.cgpa,
    this.prevCompany,
    this.experience,
    this.skills,
    this.reportingManager,
    this.workMode,
    this.resumeFileName,
    this.companyEmail,
    this.personalEmail,
  });

  /// Whether a custom corporate mailbox is assigned to this user (e.g. '@enterprise-crm.com' or distinct custom mailbox)
  bool get hasCustomCompanyEmail {
    final assigned = companyEmail?.trim().toLowerCase();
    final primary = email.trim().toLowerCase();
    final personal = personalEmail?.trim().toLowerCase();

    // Explicit custom company email assigned that differs from personal/google email
    if (assigned != null && assigned.isNotEmpty) {
      if (personal != null && personal.isNotEmpty && assigned != personal) return true;
      if (!assigned.endsWith('@gmail.com') && !assigned.endsWith('@googlemail.com')) return true;
    }

    // Primary email is a corporate enterprise domain
    if (primary.endsWith('@enterprise-crm.com')) return true;
    if (!primary.endsWith('@gmail.com') && !primary.endsWith('@googlemail.com') && primary.contains('@')) {
      return true;
    }

    return false;
  }

  /// Whether the employee/intern's email and company email match the exact same.
  bool get isCompanyAndEmployeeEmailSame {
    if (hasCustomCompanyEmail) return false;
    final assigned = companyEmail?.trim().toLowerCase() ?? email.trim().toLowerCase();
    final personal = personalEmail?.trim().toLowerCase() ?? email.trim().toLowerCase();
    return assigned == personal && assigned.isNotEmpty;
  }

  UserProfile copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? email,
    String? role,
    String? department,
    String? designation,
    String? phone,
    String? joiningDate,
    String? status,
    String? avatar,
    double? basicSalary,
    double? hra,
    double? specialAllowance,
    double? deductions,
    double? netSalary,
    String? candidateType,
    String? dob,
    String? gender,
    String? college,
    String? degree,
    String? gradYear,
    String? currentSem,
    String? cgpa,
    String? prevCompany,
    String? experience,
    String? skills,
    String? reportingManager,
    String? workMode,
    String? resumeFileName,
    String? companyEmail,
    String? personalEmail,
  }) {
    return UserProfile(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      phone: phone ?? this.phone,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      basicSalary: basicSalary ?? this.basicSalary,
      hra: hra ?? this.hra,
      specialAllowance: specialAllowance ?? this.specialAllowance,
      deductions: deductions ?? this.deductions,
      netSalary: netSalary ?? this.netSalary,
      candidateType: candidateType ?? this.candidateType,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      college: college ?? this.college,
      degree: degree ?? this.degree,
      gradYear: gradYear ?? this.gradYear,
      currentSem: currentSem ?? this.currentSem,
      cgpa: cgpa ?? this.cgpa,
      prevCompany: prevCompany ?? this.prevCompany,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      reportingManager: reportingManager ?? this.reportingManager,
      workMode: workMode ?? this.workMode,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      companyEmail: companyEmail ?? this.companyEmail,
      personalEmail: personalEmail ?? this.personalEmail,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employeeId': employeeId,
    'name': name,
    'email': email,
    'role': role,
    'department': department,
    'designation': designation,
    'phone': phone,
    'joiningDate': joiningDate,
    'status': status,
    'avatar': avatar,
    'basicSalary': basicSalary,
    'hra': hra,
    'specialAllowance': specialAllowance,
    'deductions': deductions,
    'netSalary': netSalary,
    'candidateType': candidateType,
    'dob': dob,
    'gender': gender,
    'college': college,
    'degree': degree,
    'gradYear': gradYear,
    'currentSem': currentSem,
    'cgpa': cgpa,
    'prevCompany': prevCompany,
    'experience': experience,
    'skills': skills,
    'reportingManager': reportingManager,
    'workMode': workMode,
    'resumeFileName': resumeFileName,
    'companyEmail': companyEmail,
    'personalEmail': personalEmail,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final basic = double.tryParse(json['basicSalary']?.toString() ?? '14000') ?? 14000.0;
    final hraVal = double.tryParse(json['hra']?.toString() ?? '6000') ?? 6000.0;
    final spec = double.tryParse(json['specialAllowance']?.toString() ?? json['allowances']?.toString() ?? '0') ?? 0.0;
    final ded = double.tryParse(json['deductions']?.toString() ?? '0') ?? 0.0;
    final net = double.tryParse(json['netSalary']?.toString() ?? '20000') ?? (basic + hraVal + spec - ded);

    return UserProfile(
      id: json['id']?.toString() ?? 'USR-1002',
      employeeId:
          json['employeeId']?.toString() ??
          json['id']?.toString() ??
          'IN-9002',
      name:
          json['name']?.toString() ??
          json['fullName']?.toString() ??
          'User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'EMPLOYEE',
      department: json['department']?.toString() ?? 'Computer Science',
      designation:
          json['designation']?.toString() ??
          json['position']?.toString() ??
          'Mobile App Developer',
      phone: json['phone']?.toString() ?? '+91 95001 23456',
      joiningDate: json['joiningDate']?.toString() ?? 'September 22, 2026',
      status: json['status']?.toString() ?? 'ACTIVE',
      avatar: json['profilePic']?.toString() ?? json['avatar']?.toString(),
      basicSalary: basic,
      hra: hraVal,
      specialAllowance: spec,
      deductions: ded,
      netSalary: net,
      candidateType: json['candidateType']?.toString(),
      dob: json['dob']?.toString(),
      gender: json['gender']?.toString(),
      college: json['college']?.toString() ?? json['university']?.toString(),
      degree: json['degree']?.toString() ?? json['course']?.toString(),
      gradYear: json['gradYear']?.toString() ?? json['graduationYear']?.toString(),
      currentSem: json['currentSem']?.toString() ?? json['semester']?.toString(),
      cgpa: json['cgpa']?.toString(),
      prevCompany: json['prevCompany']?.toString() ?? json['previousCompany']?.toString(),
      experience: json['experience']?.toString(),
      skills: json['skills']?.toString(),
      reportingManager: json['reportingManager']?.toString() ?? json['manager']?.toString(),
      workMode: json['workMode']?.toString(),
      resumeFileName: json['resumeFileName']?.toString() ?? json['resume']?.toString(),
      companyEmail: json['companyEmail']?.toString(),
      personalEmail: json['personalEmail']?.toString(),
    );
  }
}

class TaskItem {
  final String id;
  final String title;
  final String description;
  final String category;
  String status; // 'In Progress', 'Pending', 'In Review', 'Completed'
  final String priority; // 'High', 'Urgent', 'Medium', 'Normal'
  final double progress;
  final String dueDate;

  TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.priority,
    required this.progress,
    required this.dueDate,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    String rawStatus = json['status']?.toString() ?? 'IN_PROGRESS';
    String displayStatus = 'In Progress';
    if (rawStatus == 'COMPLETED' || rawStatus == 'APPROVED') {
      displayStatus = 'Completed';
    } else if (rawStatus == 'PENDING') {
      displayStatus = 'Pending';
    } else if (rawStatus == 'WAITING_FOR_REVIEW' || rawStatus == 'IN_REVIEW') {
      displayStatus = 'In Review';
    }

    String rawPriority = json['priority']?.toString() ?? 'HIGH';
    String displayPriority = 'High';
    if (rawPriority == 'URGENT' || rawPriority == 'CRITICAL') {
      displayPriority = 'Urgent';
    } else if (rawPriority == 'MEDIUM') {
      displayPriority = 'Medium';
    } else if (rawPriority == 'LOW') {
      displayPriority = 'Normal';
    }

    double prog = 0.5;
    if (json['progress'] != null) {
      prog = (double.tryParse(json['progress'].toString()) ?? 50.0) / 100.0;
    } else if (displayStatus == 'Completed') {
      prog = 1.0;
    }

    return TaskItem(
      id: json['id']?.toString() ?? 'TSK-101',
      title: json['title']?.toString() ?? 'Task Item',
      description:
          json['description']?.toString() ?? 'Task description details',
      category:
          json['category']?.toString() ??
          json['project']?['name']?.toString() ??
          'Mobile App Redesign',
      status: displayStatus,
      priority: displayPriority,
      progress: prog,
      dueDate: json['dueDate']?.toString() ?? 'Today, 5:00 PM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'status': status == 'Completed'
          ? 'COMPLETED'
          : status == 'Pending'
          ? 'PENDING'
          : status == 'In Review'
          ? 'WAITING_FOR_REVIEW'
          : 'IN_PROGRESS',
      'priority': priority.toUpperCase(),
      'dueDate': dueDate,
    };
  }
}

class LeaveBalance {
  final String type;
  final int totalDays;
  final int usedDays;

  LeaveBalance({
    required this.type,
    required this.totalDays,
    required this.usedDays,
  });

  int get daysLeft => totalDays - usedDays;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    String typeName = '';
    if (json['leaveType'] != null && json['leaveType'] is Map) {
      final lt = json['leaveType'];
      typeName = (lt['code'] ?? lt['name'] ?? lt['type'])?.toString() ?? '';
    } else if (json['code'] != null && json['code'].toString().isNotEmpty) {
      typeName = json['code'].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      typeName = json['name'].toString();
    } else if (json['type'] != null && json['type'].toString().isNotEmpty) {
      typeName = json['type'].toString();
    }
    if (typeName.isEmpty) {
      typeName = 'Leave';
    }
    // Normalize WFH variations
    if (typeName.toUpperCase() == 'WORK FROM HOME') {
      typeName = 'WFH';
    }

    int total = int.tryParse(
      json['annualDays']?.toString() ??
      json['allocated']?.toString() ??
      json['totalDays']?.toString() ??
      json['quota']?.toString() ?? '12'
    ) ?? 12;

    int used = int.tryParse(
      json['used']?.toString() ??
      json['usedDays']?.toString() ??
      json['taken']?.toString() ?? '0'
    ) ?? 0;

    return LeaveBalance(
      type: typeName,
      totalDays: total,
      usedDays: used,
    );
  }
}

class LeaveRequest {
  final String id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final int daysCount;
  final double? days;
  String status; // 'Approved', 'Pending', 'Rejected'
  final String reason;
  final String applicantName;
  final String? employeeId;
  final String? role;
  final String? department;
  bool isRead;

  LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    this.days,
    required this.status,
    required this.reason,
    this.applicantName = 'Employee',
    this.employeeId,
    this.role,
    this.department,
    this.isRead = false,
  });

  double get displayDays => days ?? daysCount.toDouble();

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    String rawStatus = json['status']?.toString() ?? 'PENDING';
    String displayStatus = 'Pending';
    if (rawStatus == 'APPROVED') displayStatus = 'Approved';
    if (rawStatus == 'REJECTED') displayStatus = 'Rejected';

    String typeStr = 'Casual Leave';
    if (json['leaveType'] != null && json['leaveType'] is Map) {
      typeStr = json['leaveType']['name']?.toString() ?? json['leaveType']['code']?.toString() ?? 'Casual Leave';
    } else if (json['leaveType'] != null) {
      typeStr = json['leaveType'].toString();
    }

    String start = json['startDate']?.toString() ?? json['from']?.toString() ?? 'Today';
    String end = json['endDate']?.toString() ?? json['to']?.toString() ?? 'Today';
    if (start.contains('T')) start = start.split('T')[0];
    if (end.contains('T')) end = end.split('T')[0];

    String appName = 'Employee';
    if (json['user'] != null && json['user'] is Map && json['user']['name'] != null) {
      appName = json['user']['name'].toString();
    } else if (json['userName'] != null) {
      appName = json['userName'].toString();
    }

    final parsedDays = double.tryParse(json['days']?.toString() ?? json['daysCount']?.toString() ?? '1') ?? 1.0;

    return LeaveRequest(
      id: json['id']?.toString() ?? 'LR-901',
      leaveType: typeStr,
      startDate: start,
      endDate: end,
      daysCount: parsedDays.round(),
      days: parsedDays,
      status: displayStatus,
      reason: json['reason']?.toString() ?? 'Leave application',
      applicantName: appName,
      employeeId: json['employeeId']?.toString() ?? (json['user'] is Map ? json['user']['employeeId']?.toString() : null),
      role: json['role']?.toString() ?? (json['user'] is Map ? json['user']['role']?.toString() : null),
      department: json['department']?.toString() ?? (json['user'] is Map ? json['user']['department']?.toString() : null),
      isRead: json['isRead'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaveType': leaveType,
      'startDate': startDate,
      'endDate': endDate,
      'daysCount': daysCount,
      'days': displayDays,
      'reason': reason,
      'applicantName': applicantName,
      'employeeId': employeeId,
      'role': role,
      'department': department,
      'status': status,
      'isRead': isRead,
    };
  }
}

class ITTicket {
  final String id;
  final String title;
  final String category;
  final String priority;
  String status; // 'Open', 'In Progress', 'Resolved'
  final String createdAt;

  ITTicket({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory ITTicket.fromJson(Map<String, dynamic> json) {
    String rawStatus = json['status']?.toString() ?? 'OPEN';
    String displayStatus = 'Open';
    if (rawStatus == 'IN_PROGRESS' || rawStatus == 'ASSIGNED') {
      displayStatus = 'In Progress';
    }
    if (rawStatus == 'RESOLVED' || rawStatus == 'CLOSED') {
      displayStatus = 'Resolved';
    }

    return ITTicket(
      id: json['id']?.toString() ?? 'INC-4091',
      title: json['title']?.toString() ?? 'Support Request',
      category: json['category']?.toString() ?? 'Hardware',
      priority: json['priority']?.toString() ?? 'High',
      status: displayStatus,
      createdAt: json['createdAt']?.toString() ?? 'Just now',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'category': category, 'priority': priority};
  }
}

class AssetItem {
  final String id;
  final String name;
  final String model;
  final String serialNumber;
  final String condition;
  final String assignedDate;

  AssetItem({
    required this.id,
    required this.name,
    required this.model,
    required this.serialNumber,
    required this.condition,
    required this.assignedDate,
  });

  factory AssetItem.fromJson(Map<String, dynamic> json) {
    return AssetItem(
      id: json['id']?.toString() ?? 'AST-882',
      name:
          json['name']?.toString() ??
          json['assetName']?.toString() ??
          'MacBook Pro 16" M3 Max',
      model: json['model']?.toString() ?? 'Apple Silicon 36GB / 1TB',
      serialNumber: json['serialNumber']?.toString() ?? 'C02GX910Q16X',
      condition: json['condition']?.toString() ?? 'Excellent',
      assignedDate: json['assignedDate']?.toString() ?? 'Jan 15, 2024',
    );
  }
}

class SystemAsset {
  final String id;
  String name;
  String location;
  String category; // 'NETWORK', 'PRINTER', 'MOBILE', 'DESKTOP', 'LAPTOP', 'PERIPHERAL', 'ACCESSORY', 'FURNITURE'
  String serialNumber;
  String assignedTo; // 'Unassigned' or employee name
  String status; // 'AVAILABLE', 'ASSIGNED', 'MAINTENANCE'
  double cost;
  DateTime purchaseDate;
  String invoiceNumber;
  String warrantyPeriod;

  SystemAsset({
    required this.id,
    required this.name,
    this.location = 'Office',
    required this.category,
    this.serialNumber = 'N/A',
    this.assignedTo = 'Unassigned',
    this.status = 'AVAILABLE',
    this.cost = 15000.0,
    DateTime? purchaseDate,
    this.invoiceNumber = 'INV-2025-081',
    this.warrantyPeriod = '3 Years Standard',
  }) : purchaseDate = purchaseDate ?? DateTime(2025, 3, 15);

  AssetItem toAssetItem() {
    return AssetItem(
      id: id,
      name: name,
      model: category,
      serialNumber: serialNumber,
      condition: status == 'MAINTENANCE' ? 'Maintenance' : 'Good',
      assignedDate: 'Jan 15, 2024',
    );
  }
}

class AttendanceLog {
  final String date;
  final String checkIn;
  final String checkOut;
  final double workingHours;
  final String status;
  final String employeeName;
  final String department;
  final String workLocation;
  final String? totalWorkedStr;

  AttendanceLog({
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.workingHours,
    required this.status,
    this.employeeName = 'Employee',
    this.department = 'Engineering & App',
    this.workLocation = 'Office',
    this.totalWorkedStr,
  });

  String get displayTotalWorked {
    if (totalWorkedStr != null && totalWorkedStr!.isNotEmpty) return totalWorkedStr!;
    final s = status.toUpperCase();
    if (s == 'HOLIDAY' || s == 'LEAVE' || s == 'ON LEAVE' || s == 'ABSENT') return '—';
    if (checkOut.toLowerCase().contains('active')) return '—';
    if (workingHours <= 0) return '—';
    final totalMinutes = (workingHours * 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  factory AttendanceLog.fromJson(Map<String, dynamic> json) {
    String dt = json['date']?.toString() ?? 'Today';
    if (dt.contains('T')) dt = dt.split('T')[0];

    String inTime = json['clockIn']?.toString() ?? json['checkIn']?.toString() ?? '09:00 AM';
    String outTime = json['clockOut']?.toString() ?? json['checkOut']?.toString() ?? '06:00 PM';
    if (inTime.contains('T')) inTime = inTime.split('T')[1].substring(0, 5);
    if (outTime.contains('T')) outTime = outTime.split('T')[1].substring(0, 5);

    String name = 'Employee';
    if (json['user'] != null && json['user'] is Map && json['user']['name'] != null) {
      name = json['user']['name'].toString();
    } else if (json['employeeName'] != null) {
      name = json['employeeName'].toString();
    }

    String dept = 'Engineering & App';
    if (json['user'] != null && json['user'] is Map && json['user']['department'] != null) {
      dept = json['user']['department'].toString();
    } else if (json['department'] != null) {
      dept = json['department'].toString();
    }

    String loc = json['workLocation']?.toString() ??
        (json['status']?.toString().toUpperCase().contains('WFH') == true ||
                json['status']?.toString().toUpperCase().contains('HOME') == true
            ? 'Home'
            : (json['status']?.toString().toUpperCase() == 'HOLIDAY' ? '—' : 'Office'));

    return AttendanceLog(
      date: dt,
      checkIn: inTime,
      checkOut: outTime,
      workingHours:
          double.tryParse(json['totalHours']?.toString() ?? json['workingHours']?.toString() ?? '8.0') ?? 8.0,
      status: json['status']?.toString() ?? 'Present',
      employeeName: name,
      department: dept,
      workLocation: loc,
      totalWorkedStr: json['totalWorked']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'checkIn': checkIn,
    'checkOut': checkOut,
    'workingHours': workingHours,
    'status': status,
    'employeeName': employeeName,
    'department': department,
    'workLocation': workLocation,
    'totalWorkedStr': totalWorkedStr,
  };
}

class EmployeeAttendanceRecord {
  final String email;
  final String employeeId;
  final String employeeName;
  final bool isClockedIn;
  final String date; // YYYY-MM-DD
  final String? clockInIso;
  final String? clockInDisplay;
  final String? clockOutIso;
  final String? clockOutDisplay;
  final int clockedSeconds;
  final double distanceMeters;
  final double? userLat;
  final double? userLng;
  final String statusText;
  final String workLocation;

  EmployeeAttendanceRecord({
    required this.email,
    required this.employeeId,
    required this.employeeName,
    required this.isClockedIn,
    required this.date,
    this.clockInIso,
    this.clockInDisplay,
    this.clockOutIso,
    this.clockOutDisplay,
    this.clockedSeconds = 0,
    this.distanceMeters = 0.0,
    this.userLat,
    this.userLng,
    this.statusText = 'Present',
    this.workLocation = 'Office',
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'employeeId': employeeId,
    'employeeName': employeeName,
    'isClockedIn': isClockedIn,
    'date': date,
    'clockInIso': clockInIso,
    'clockInDisplay': clockInDisplay,
    'clockOutIso': clockOutIso,
    'clockOutDisplay': clockOutDisplay,
    'clockedSeconds': clockedSeconds,
    'distanceMeters': distanceMeters,
    'userLat': userLat,
    'userLng': userLng,
    'statusText': statusText,
    'workLocation': workLocation,
  };

  factory EmployeeAttendanceRecord.fromJson(Map<String, dynamic> json) {
    return EmployeeAttendanceRecord(
      email: json['email']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      employeeName: json['employeeName']?.toString() ?? '',
      isClockedIn: json['isClockedIn'] == true,
      date: json['date']?.toString() ?? '',
      clockInIso: json['clockInIso']?.toString(),
      clockInDisplay: json['clockInDisplay']?.toString(),
      clockOutIso: json['clockOutIso']?.toString(),
      clockOutDisplay: json['clockOutDisplay']?.toString(),
      clockedSeconds: (json['clockedSeconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      userLat: (json['userLat'] as num?)?.toDouble(),
      userLng: (json['userLng'] as num?)?.toDouble(),
      statusText: json['statusText']?.toString() ?? 'Present',
      workLocation: json['workLocation']?.toString() ?? 'Office',
    );
  }

  int get currentElapsedSeconds {
    if (!isClockedIn) return clockedSeconds;
    if (clockInIso != null) {
      final dt = DateTime.tryParse(clockInIso!);
      if (dt != null) {
        return DateTime.now().difference(dt).inSeconds.clamp(0, 86400);
      }
    }
    return clockedSeconds;
  }

  String get formattedCurrentTimer {
    final s = currentElapsedSeconds;
    final hours = (s ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (s % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}


class WorkLogEntry {
  final String id;
  final String date;
  final String projectTask;
  final String description;
  final double hours;
  String status; // 'APPROVED', 'PENDING', 'REJECTED', 'DRAFT'
  final String attachmentName;
  final String submittedTime;
  final String? startTime;
  final String? endTime;
  final String? projectName;
  final String? taskTitle;
  final List<String> attachments;

  WorkLogEntry({
    required this.id,
    required this.date,
    required this.projectTask,
    required this.description,
    required this.hours,
    required this.status,
    this.attachmentName = 'None',
    required this.submittedTime,
    this.startTime,
    this.endTime,
    this.projectName,
    this.taskTitle,
    this.attachments = const [],
  });

  String get formattedHours {
    final h = hours.toInt();
    final m = ((hours - h) * 60).round();
    if (m > 0) return '${h}h ${m}m';
    return '$h hrs';
  }

  factory WorkLogEntry.fromJson(Map<String, dynamic> json) {
    return WorkLogEntry(
      id: json['id']?.toString() ?? 'WL-${DateTime.now().millisecondsSinceEpoch}',
      date: json['workDate']?.toString() ?? json['date']?.toString() ?? 'Today',
      projectTask: json['projectTask']?.toString() ?? json['project']?.toString() ?? 'Mobile App Development',
      description: json['description']?.toString() ?? 'Daily task activities completed.',
      hours: double.tryParse(json['hoursWorked']?.toString() ?? json['hours']?.toString() ?? '7.8') ?? 7.8,
      status: (json['status']?.toString() ?? 'APPROVED').toUpperCase(),
      attachmentName: json['attachmentName']?.toString() ?? 'None',
      submittedTime: json['submittedAt']?.toString() ?? json['submittedTime']?.toString() ?? 'Today, 12:30 PM',
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      projectName: json['projectName']?.toString(),
      taskTitle: json['taskTitle']?.toString(),
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workDate': date,
      'projectTask': projectTask,
      'description': description,
      'hoursWorked': hours,
      'status': status,
      'attachmentName': attachmentName,
      'submittedAt': submittedTime,
      'startTime': startTime,
      'endTime': endTime,
      'projectName': projectName,
      'taskTitle': taskTitle,
      'attachments': attachments,
    };
  }
}

class AnnouncementItem {
  final String id;
  String title;
  String message;
  String targetAudience; // 'All Company', 'Software Engineering', 'Operations', 'Finance & HR'
  String priority; // 'General', 'Urgent', 'Policy', 'Celebration'
  DateTime timestamp;
  String author;
  bool isRead;
  bool isPinned;

  AnnouncementItem({
    required this.id,
    required this.title,
    required this.message,
    this.targetAudience = 'All Company',
    this.priority = 'General',
    required this.timestamp,
    this.author = 'System Admin',
    this.isRead = false,
    this.isPinned = false,
  });

  String get formattedDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${timestamp.day.toString().padLeft(2, '0')} ${months[timestamp.month - 1]} ${timestamp.year}';
  }

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id']?.toString() ?? 'ANN-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Announcement',
      message: json['message']?.toString() ?? json['content']?.toString() ?? '',
      targetAudience: json['targetAudience']?.toString() ?? json['audience']?.toString() ?? 'All Company',
      priority: json['priority']?.toString() ?? 'General',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      author: json['author']?.toString() ?? 'System Admin',
      isRead: json['isRead'] == true,
      isPinned: json['isPinned'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'targetAudience': targetAudience,
      'priority': priority,
      'timestamp': timestamp.toIso8601String(),
      'author': author,
      'isRead': isRead,
      'isPinned': isPinned,
    };
  }
}

class SalaryTemplate {
  String id;
  String name;
  String role;
  String description;
  double basicSalary;
  double hra;
  double da;
  double specialAllowance;
  double bonus;
  double pfPercentage;
  double taxPercentage;
  double deductions;
  int assignedUsersCount;

  SalaryTemplate({
    required this.id,
    required this.name,
    this.role = 'EMPLOYEE',
    this.description = '-',
    this.basicSalary = 20000.0,
    this.hra = 0.0,
    this.da = 0.0,
    this.specialAllowance = 0.0,
    this.bonus = 0.0,
    this.pfPercentage = 0.0,
    this.taxPercentage = 0.0,
    this.deductions = 0.0,
    this.assignedUsersCount = 0,
  });

  double get estimatedNetPay {
    final earnings = basicSalary + hra + da + specialAllowance + bonus;
    final pfAmount = basicSalary * (pfPercentage / 100);
    final taxAmount = basicSalary * (taxPercentage / 100);
    return (earnings - deductions - pfAmount - taxAmount).clamp(0, double.infinity);
  }

  factory SalaryTemplate.fromJson(Map<String, dynamic> json) {
    return SalaryTemplate(
      id: json['id']?.toString() ?? 'ST-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Developer',
      role: json['role']?.toString() ?? 'EMPLOYEE',
      description: json['description']?.toString() ?? '-',
      basicSalary: double.tryParse(json['basicSalary']?.toString() ?? '20000') ?? 20000.0,
      hra: double.tryParse(json['hra']?.toString() ?? '0') ?? 0.0,
      da: double.tryParse(json['da']?.toString() ?? '0') ?? 0.0,
      specialAllowance: double.tryParse(json['specialAllowance']?.toString() ?? '0') ?? 0.0,
      bonus: double.tryParse(json['bonus']?.toString() ?? '0') ?? 0.0,
      pfPercentage: double.tryParse(json['pfPercentage']?.toString() ?? '0') ?? 0.0,
      taxPercentage: double.tryParse(json['taxPercentage']?.toString() ?? '0') ?? 0.0,
      deductions: double.tryParse(json['deductions']?.toString() ?? '0') ?? 0.0,
      assignedUsersCount: int.tryParse(json['assignedUsersCount']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'description': description,
      'basicSalary': basicSalary,
      'hra': hra,
      'da': da,
      'specialAllowance': specialAllowance,
      'bonus': bonus,
      'pfPercentage': pfPercentage,
      'taxPercentage': taxPercentage,
      'deductions': deductions,
      'assignedUsersCount': assignedUsersCount,
    };
  }

  SalaryTemplate copyWith({
    String? id,
    String? name,
    String? role,
    String? description,
    double? basicSalary,
    double? hra,
    double? da,
    double? specialAllowance,
    double? bonus,
    double? pfPercentage,
    double? taxPercentage,
    double? deductions,
    int? assignedUsersCount,
  }) {
    return SalaryTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      basicSalary: basicSalary ?? this.basicSalary,
      hra: hra ?? this.hra,
      da: da ?? this.da,
      specialAllowance: specialAllowance ?? this.specialAllowance,
      bonus: bonus ?? this.bonus,
      pfPercentage: pfPercentage ?? this.pfPercentage,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      deductions: deductions ?? this.deductions,
      assignedUsersCount: assignedUsersCount ?? this.assignedUsersCount,
    );
  }
}

class GeofenceLocationProfile {
  final String id;
  String name;
  double latitude;
  double longitude;
  double radiusMeters;
  String? address;
  bool isActive;

  GeofenceLocationProfile({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200.0,
    this.address,
    this.isActive = true,
  });

  GeofenceLocationProfile copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? address,
    bool? isActive,
  }) {
    return GeofenceLocationProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'radiusMeters': radiusMeters,
    'address': address,
    'isActive': isActive,
  };

  factory GeofenceLocationProfile.fromJson(Map<String, dynamic> json) {
    return GeofenceLocationProfile(
      id: json['id']?.toString() ?? 'loc-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Office Location',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 12.920466,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 80.121639,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 200.0,
      address: json['address']?.toString(),
      isActive: json['isActive'] != false,
    );
  }
}
