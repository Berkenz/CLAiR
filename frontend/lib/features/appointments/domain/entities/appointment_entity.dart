class AppointmentEntity {
  const AppointmentEntity({
    required this.id,
    required this.lawyerProfileId,
    required this.clientName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.appointmentType,
    required this.status,
    required this.createdAt,
    this.lawyerDisplayName,
    this.attachedConversationId,
    this.caseTitle,
    this.description,
    this.rejectionReason,
    this.updatedAt,
  });

  final String id;
  final String lawyerProfileId;
  final String? lawyerDisplayName;
  final String? attachedConversationId;
  final String clientName;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String appointmentType;
  final String? caseTitle;
  final String? description;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  bool get canStartLawyerChat => status == 'confirmed';

  String get displayCaseTitle {
    final title = caseTitle?.trim();
    if (title == null || title.isEmpty) return appointmentType;
    return title;
  }

  String get displayLawyerName {
    final value = lawyerDisplayName?.trim();
    if (value == null || value.isEmpty) return 'Lawyer';
    return value;
  }

  String get statusLabel {
    return switch (status) {
      'pending' => 'Pending',
      'confirmed' => 'Accepted',
      'cancelled' => 'Rejected',
      _ => status,
    };
  }

  factory AppointmentEntity.fromJson(Map<String, dynamic> json) {
    final id = '${json['id'] ?? ''}'.trim();
    if (id.isEmpty) {
      throw const FormatException('Appointment missing id');
    }

    final lawyerProfileId = '${json['lawyer_profile_id'] ?? ''}'.trim();
    if (lawyerProfileId.isEmpty) {
      throw const FormatException('Appointment missing lawyer_profile_id');
    }

    final dateRaw = '${json['appointment_date'] ?? ''}'.trim();
    final timeRaw = '${json['appointment_time'] ?? ''}'.trim();
    if (dateRaw.isEmpty || timeRaw.isEmpty) {
      throw const FormatException('Appointment missing date/time');
    }

    final createdRaw = '${json['created_at'] ?? ''}'.trim();
    if (createdRaw.isEmpty) {
      throw const FormatException('Appointment missing created_at');
    }

    final status = '${json['status'] ?? ''}'.trim();
    if (status.isEmpty) {
      throw const FormatException('Appointment missing status');
    }

    return AppointmentEntity(
      id: id,
      lawyerProfileId: lawyerProfileId,
      lawyerDisplayName: json['lawyer_display_name'] as String?,
      attachedConversationId: json['attached_conversation_id'] as String?,
      clientName: '${json['client_name'] ?? ''}',
      appointmentDate: DateTime.parse(dateRaw),
      appointmentTime: timeRaw,
      appointmentType: '${json['appointment_type'] ?? ''}',
      caseTitle: json['case_title'] as String?,
      description: json['description'] as String?,
      status: status,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(createdRaw),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse('${json['updated_at']}')
          : null,
    );
  }
}
