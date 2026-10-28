import 'dart:convert';

class ProjectWorkflowStage {
  final String id;
  final String name;
  final int order;
  final bool requiresApproval;
  final bool isFinalCompletedStage;
  final String colorHex;
  final String status; // 'PENDING', 'ACTIVE', 'AWAITING_APPROVAL', 'APPROVED', 'REJECTED_REDO'
  final String? rejectionReason;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? submittedAt;
  final String? submittedBy;

  const ProjectWorkflowStage({
    required this.id,
    required this.name,
    required this.order,
    this.requiresApproval = false,
    this.isFinalCompletedStage = false,
    this.colorHex = '#3B82F6',
    this.status = 'PENDING',
    this.rejectionReason,
    this.rejectedBy,
    this.rejectedAt,
    this.approvedBy,
    this.approvedAt,
    this.submittedAt,
    this.submittedBy,
  });

  ProjectWorkflowStage copyWith({
    String? id,
    String? name,
    int? order,
    bool? requiresApproval,
    bool? isFinalCompletedStage,
    String? colorHex,
    String? status,
    String? rejectionReason,
    String? rejectedBy,
    DateTime? rejectedAt,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? submittedAt,
    String? submittedBy,
  }) {
    return ProjectWorkflowStage(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      isFinalCompletedStage: isFinalCompletedStage ?? this.isFinalCompletedStage,
      colorHex: colorHex ?? this.colorHex,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'requiresApproval': requiresApproval,
      'isFinalCompletedStage': isFinalCompletedStage,
      'colorHex': colorHex,
      'status': status,
      'rejectionReason': rejectionReason,
      'rejectedBy': rejectedBy,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'submittedAt': submittedAt?.toIso8601String(),
      'submittedBy': submittedBy,
    };
  }

  factory ProjectWorkflowStage.fromJson(Map<String, dynamic> json) {
    return ProjectWorkflowStage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      order: (json['order'] as num?)?.toInt() ?? 1,
      requiresApproval: json['requiresApproval'] == true,
      isFinalCompletedStage: json['isFinalCompletedStage'] == true,
      colorHex: json['colorHex']?.toString() ?? '#3B82F6',
      status: json['status']?.toString() ?? 'PENDING',
      rejectionReason: json['rejectionReason']?.toString(),
      rejectedBy: json['rejectedBy']?.toString(),
      rejectedAt: json['rejectedAt'] != null ? DateTime.tryParse(json['rejectedAt'].toString()) : null,
      approvedBy: json['approvedBy']?.toString(),
      approvedAt: json['approvedAt'] != null ? DateTime.tryParse(json['approvedAt'].toString()) : null,
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      submittedBy: json['submittedBy']?.toString(),
    );
  }
}

class EnterpriseProject {
  final String id;
  final String code;
  final String name;
  final String description;
  final String projectType; // 'Client Project', 'Internal Project', 'Research & Development', 'Maintenance'
  final String priority; // 'Low', 'Medium', 'High', 'Critical'
  final String status; // 'Active', 'Overdue', 'Draft', 'Scheduled', 'On Hold', 'Completed', 'Archived'
  final DateTime startDate;
  final DateTime endDate;
  final String? projectLeaderId;
  final String? projectLeaderName;
  final String? assignedTeam;
  final List<String> memberIds;
  final List<String> memberNames;
  final List<ProjectWorkflowStage> workflowStages;
  final int currentStageIndex;
  final bool requiresAdminApproval;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EnterpriseProject({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    this.projectType = 'Client Project',
    this.priority = 'Medium',
    this.status = 'Active',
    required this.startDate,
    required this.endDate,
    this.projectLeaderId,
    this.projectLeaderName,
    this.assignedTeam,
    this.memberIds = const [],
    this.memberNames = const [],
    required this.workflowStages,
    this.currentStageIndex = 0,
    this.requiresAdminApproval = true,
    required this.createdAt,
    required this.updatedAt,
  });

  ProjectWorkflowStage get currentStage {
    if (workflowStages.isEmpty) {
      return const ProjectWorkflowStage(id: 's0', name: 'To Do', order: 1);
    }
    final idx = currentStageIndex.clamp(0, workflowStages.length - 1);
    return workflowStages[idx];
  }

  bool get isAwaitingApproval => currentStage.status == 'AWAITING_APPROVAL';

  bool get isStageRejected => currentStage.status == 'REJECTED_REDO';

  bool get isCompleted =>
      status == 'Completed' ||
      (currentStageIndex == workflowStages.length - 1 &&
          (currentStage.status == 'APPROVED' || currentStage.isFinalCompletedStage));

  double get progressRatio {
    if (workflowStages.isEmpty) return 0.0;
    if (isCompleted) return 1.0;
    return (currentStageIndex / workflowStages.length).clamp(0.0, 1.0);
  }

  int get progressPercent => (progressRatio * 100).round();

  bool isMember(String? emailOrId) {
    if (emailOrId == null || emailOrId.isEmpty) return false;
    final clean = emailOrId.toLowerCase().trim();
    if (projectLeaderId?.toLowerCase().trim() == clean) return true;
    return memberIds.any((m) => m.toLowerCase().trim() == clean);
  }

  EnterpriseProject copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    String? projectType,
    String? priority,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? projectLeaderId,
    String? projectLeaderName,
    String? assignedTeam,
    List<String>? memberIds,
    List<String>? memberNames,
    List<ProjectWorkflowStage>? workflowStages,
    int? currentStageIndex,
    bool? requiresAdminApproval,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnterpriseProject(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      projectType: projectType ?? this.projectType,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      projectLeaderId: projectLeaderId ?? this.projectLeaderId,
      projectLeaderName: projectLeaderName ?? this.projectLeaderName,
      assignedTeam: assignedTeam ?? this.assignedTeam,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      workflowStages: workflowStages ?? this.workflowStages,
      currentStageIndex: currentStageIndex ?? this.currentStageIndex,
      requiresAdminApproval: requiresAdminApproval ?? this.requiresAdminApproval,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'projectType': projectType,
      'priority': priority,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'projectLeaderId': projectLeaderId,
      'projectLeaderName': projectLeaderName,
      'assignedTeam': assignedTeam,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'workflowStages': workflowStages.map((s) => s.toJson()).toList(),
      'currentStageIndex': currentStageIndex,
      'requiresAdminApproval': requiresAdminApproval,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EnterpriseProject.fromJson(Map<String, dynamic> json) {
    var rawStages = json['workflowStages'] as List?;
    List<ProjectWorkflowStage> stages = [];
    if (rawStages != null) {
      stages = rawStages
          .map((s) => ProjectWorkflowStage.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    }
    if (stages.isEmpty) {
      stages = [
        const ProjectWorkflowStage(id: 'stg-1', name: 'To Do', order: 1, colorHex: '#64748B'),
        const ProjectWorkflowStage(id: 'stg-2', name: 'In Progress', order: 2, colorHex: '#F59E0B'),
        const ProjectWorkflowStage(id: 'stg-3', name: 'In Review', order: 3, requiresApproval: true, colorHex: '#8B5CF6'),
        const ProjectWorkflowStage(id: 'stg-4', name: 'Done', order: 4, isFinalCompletedStage: true, colorHex: '#10B981'),
      ];
    }

    return EnterpriseProject(
      id: json['id']?.toString() ?? 'PRJ-${DateTime.now().millisecondsSinceEpoch % 10000}',
      code: json['code']?.toString() ?? 'PRJ-101',
      name: json['name']?.toString() ?? 'Untitled Project',
      description: json['description']?.toString() ?? '',
      projectType: json['projectType']?.toString() ?? 'Client Project',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Active',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      projectLeaderId: json['projectLeaderId']?.toString(),
      projectLeaderName: json['projectLeaderName']?.toString(),
      assignedTeam: json['assignedTeam']?.toString(),
      memberIds: (json['memberIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      memberNames: (json['memberNames'] as List?)?.map((e) => e.toString()).toList() ?? [],
      workflowStages: stages,
      currentStageIndex: (json['currentStageIndex'] as num?)?.toInt() ?? 0,
      requiresAdminApproval: json['requiresAdminApproval'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
