// ignore_for_file: non_constant_identifier_names

class Bpm {
  List<dynamic> r_avg;
  List<dynamic> g_avg;
  List<dynamic> b_avg;
  double r_bpm;
  double g_bpm;
  double b_bpm;
  double avg_bpm;

  Bpm(
      {required this.r_avg,
      required this.g_avg,
      required this.b_avg,
      required this.r_bpm,
      required this.g_bpm,
      required this.b_bpm,
      required this.avg_bpm});

  Bpm.fromJson(Map<String, dynamic> json)
      : r_avg = json['r_avg'],
        g_avg = json['g_avg'],
        b_avg = json['b_avg'],
        r_bpm = json['r_bpm'],
        g_bpm = json['g_bpm'],
        b_bpm = json['b_bpm'],
        avg_bpm = json['avg_bpm'];
}


