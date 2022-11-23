import 'dart:math';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

String generateRandomString(int len) {
  var r = Random();
  return List.generate(len, (index) => _chars[r.nextInt(_chars.length)]).join();
}
