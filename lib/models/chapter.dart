class Chapter {
  final String id;
  final String number;
  final String date;

  Chapter({
    required this.id,
    required this.number,
    this.date = 'Unknown Date',
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      number: json['number'] as String,
      date: (json['date'] as String?) ?? 'Unknown Date',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'date': date,
  };
}
