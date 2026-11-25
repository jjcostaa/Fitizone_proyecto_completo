import 'package:flutter_test/flutter_test.dart';
import 'package:fitzone_mobile/config/api_config.dart';

void main() {
  test('ApiConfig provides valid default base URL', () {
    expect(ApiConfig.defaultBaseUrl.startsWith('http'), isTrue);
  });
}
