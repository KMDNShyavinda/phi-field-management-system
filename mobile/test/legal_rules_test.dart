import 'package:flutter_test/flutter_test.dart';

import 'package:phi_mobile/core/legal_rules.dart';

void main() {
  test('cold storage fail suggests a 14-day improvement notice', () {
    final notice = suggestNotice('COLD_STORAGE');
    expect(notice.days, 14);
    expect(notice.noticeType, 'improvement_notice');
    expect(notice.provision.contains('Food Act'), isTrue);
  });
}
