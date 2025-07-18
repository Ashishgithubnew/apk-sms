class FamilyDetails {
  final String stdoFatherName;
  final String stdoMotherName;
  final String stdoPrimaryContact;
  final String stdoSecondaryContact;
  final String stdoAddress;
  final String stdoCity;
  final String stdoState;
  final String stdoEmail;

  FamilyDetails({
    required this.stdoFatherName,
    required this.stdoMotherName,
    required this.stdoPrimaryContact,
    required this.stdoSecondaryContact,
    required this.stdoAddress,
    required this.stdoCity,
    required this.stdoState,
    required this.stdoEmail,
  });

  factory FamilyDetails.fromJson(Map<String, dynamic> json) {
    return FamilyDetails(
      stdoFatherName: json['stdo_FatherName'] ?? '',
      stdoMotherName: json['stdo_MotherName'] ?? '',
      stdoPrimaryContact: json['stdo_primaryContact'] ?? '',
      stdoSecondaryContact: json['stdo_secondaryContact'] ?? '',
      stdoAddress: json['stdo_address'] ?? '',
      stdoCity: json['stdo_city'] ?? '',
      stdoState: json['stdo_state'] ?? '',
      stdoEmail: json['stdo_email'] ?? '',
    );
  }
}

class Student {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final FamilyDetails familyDetails;
  final String contact;
  final String gender;
  final String dob;
  final String email;
  final String cls;
  final String department;
  final String category;
  final String studentCode;
  final String status;

  Student({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.familyDetails,
    required this.contact,
    required this.gender,
    required this.dob,
    required this.email,
    required this.cls,
    required this.department,
    required this.category,
    required this.studentCode,
    required this.status,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      familyDetails: FamilyDetails.fromJson(json['familyDetails'] ?? {}),
      contact: json['contact'] ?? '',
      gender: json['gender'] ?? '',
      dob: json['dob'] ?? '',
      email: json['email'] ?? '',
      cls: json['cls'] ?? '',
      department: json['department'] ?? '',
      category: json['category'] ?? '',
      studentCode: json['studentCode'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class TCPayload {
  final String tcNo;
  final String admissionNo;
  final String studentName;
  final String fatherName;
  final String motherName;
  final String caste;
  final String dobFigures;
  final String dobWords;
  final String nationality;
  final String lastClass;
  final String promotedTo;
  final String admissionDate;
  final String leavingDate;
  final String reason;
  final String conduct;
  final String remarks;
  final String date;
  final String principalName;

  TCPayload({
    required this.tcNo,
    required this.admissionNo,
    required this.studentName,
    required this.fatherName,
    required this.motherName,
    required this.caste,
    required this.dobFigures,
    required this.dobWords,
    required this.nationality,
    required this.lastClass,
    required this.promotedTo,
    required this.admissionDate,
    required this.leavingDate,
    required this.reason,
    required this.conduct,
    required this.remarks,
    required this.date,
    required this.principalName,
  });

  Map<String, dynamic> toJson() {
    return {
      'tcNo': tcNo,
      'admissionNo': admissionNo,
      'studentName': studentName,
      'fatherName': fatherName,
      'motherName': motherName,
      'caste': caste,
      'dobFigures': dobFigures,
      'dobWords': dobWords,
      'nationality': nationality,
      'lastClass': lastClass,
      'promotedTo': promotedTo,
      'admissionDate': admissionDate,
      'leavingDate': leavingDate,
      'reason': reason,
      'conduct': conduct,
      'remarks': remarks,
      'date': date,
      'principalName': principalName,
    };
  }
}
