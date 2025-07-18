class Subject {
  final String subject;
  final int marksObtained;
  final int maxMarks;
  final String remarks;

  Subject({
    required this.subject,
    required this.marksObtained,
    required this.maxMarks,
    required this.remarks,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      subject: json['subject']?.toString() ?? '',
      marksObtained: (json['marksObtained'] is num) ? (json['marksObtained'] as num).toInt() : 0,
      maxMarks: (json['maxMarks'] is num) ? (json['maxMarks'] as num).toInt() : 100,
      remarks: json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'remarks': remarks,
    };
  }
}

class ReportCard {
  final String id;
  final String reportId;
  final String examType;
  final String examDate;
  final List<Subject> subjects;
  final int totalMarks;
  final double average;
  final String grade;

  ReportCard({
    required this.id,
    required this.reportId,
    required this.examType,
    required this.examDate,
    required this.subjects,
    required this.totalMarks,
    required this.average,
    required this.grade,
  });

  factory ReportCard.fromJson(Map<String, dynamic> json) {
    return ReportCard(
      id: json['id']?.toString() ?? '',
      reportId: json['reportId']?.toString() ?? '',
      examType: json['examType']?.toString() ?? 'Unknown Exam',
      examDate: json['examDate']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      subjects: (json['subjects'] as List<dynamic>?)?.map((subjectJson) => Subject.fromJson(subjectJson)).toList() ?? [],
      totalMarks: (json['totalMarks'] is num) ? (json['totalMarks'] as num).toInt() : 0,
      average: (json['average'] is num) ? (json['average'] as num).toDouble() : 0.0,
      grade: json['grade']?.toString() ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'examType': examType,
      'examDate': examDate,
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
      'totalMarks': totalMarks,
      'average': average,
      'grade': grade,
    };
  }
}

class ConsolidatedSubject {
  final String subject;
  Map<String, int>? quarterly;
  Map<String, int>? halfYearly;
  Map<String, int>? finalExam;
  int total;
  int maxTotal;
  double percentage;
  String grade;

  ConsolidatedSubject({
    required this.subject,
    this.quarterly,
    this.halfYearly,
    this.finalExam,
    required this.total,
    required this.maxTotal,
    required this.percentage,
    required this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'quarterly': quarterly,
      'halfYearly': halfYearly,
      'finalExam': finalExam,
      'total': total,
      'maxTotal': maxTotal,
      'percentage': percentage,
      'grade': grade,
    };
  }
}

class ConsolidatedReport {
  final List<ConsolidatedSubject> subjects;
  final int totalMarks;
  final int totalMaxMarks;
  final double overallPercentage;
  final String overallGrade;
  final Map<String, String> examDates;

  ConsolidatedReport({
    required this.subjects,
    required this.totalMarks,
    required this.totalMaxMarks,
    required this.overallPercentage,
    required this.overallGrade,
    required this.examDates,
  });

  Map<String, dynamic> toJson() {
    return {
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
      'totalMarks': totalMarks,
      'totalMaxMarks': totalMaxMarks,
      'overallPercentage': overallPercentage,
      'overallGrade': overallGrade,
      'examDates': examDates,
    };
  }
}
