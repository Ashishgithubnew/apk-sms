class Syllabus {
  final String id;
  final String title;
  final String cls;
  final String subject;
  final String name;
  final bool publish;

  Syllabus({
    required this.id,
    required this.title,
    required this.cls,
    required this.subject,
    required this.name,
    required this.publish,
  });

  factory Syllabus.fromJson(Map<String, dynamic> json) {
    return Syllabus(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      cls: json['cls'] ?? '',
      subject: json['subject'] ?? '',
      name: json['name'] ?? '',
      publish: json['publish'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'cls': cls,
      'subject': subject,
      'name': name,
      'publish': publish,
    };
  }

  // Create a copy with updated fields
  Syllabus copyWith({
    String? id,
    String? title,
    String? cls,
    String? subject,
    String? name,
    bool? publish,
  }) {
    return Syllabus(
      id: id ?? this.id,
      title: title ?? this.title,
      cls: cls ?? this.cls,
      subject: subject ?? this.subject,
      name: name ?? this.name,
      publish: publish ?? this.publish,
    );
  }
}
