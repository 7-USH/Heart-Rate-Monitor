// ignore_for_file: avoid_print, unused_local_variable
import 'package:http/http.dart' as http;

class HeartRateApi {
  static Future getData({required String imageurl}) async {
    String endpoint = 'https://heart-rate-07.herokuapp.com/api?query=$imageurl';
    Uri.encodeFull(endpoint);
    http.Response response = await http.get(Uri.parse(endpoint));

    if (response.statusCode == 200) {
      String content = response.body.toString();
      return content;
    } else {
      return response.body;
    }
  }
}
