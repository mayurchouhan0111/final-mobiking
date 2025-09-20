class Scan {
  final String activity;
  final String date;
  final String location;
  final String srStatus;
  final String srStatusLabel;
  final String status;

  Scan({
    required this.activity,
    required this.date,
    required this.location,
    required this.srStatus,
    required this.srStatusLabel,
    required this.status,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      activity: json['activity']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      srStatus: json['sr-status']?.toString() ?? '',
      srStatusLabel: json['sr-status-label']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity': activity,
      'date': date,
      'location': location,
      'sr-status': srStatus,
      'sr-status-label': srStatusLabel,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'Scan(activity: $activity, date: $date, location: $location, status: $status)';
  }
}