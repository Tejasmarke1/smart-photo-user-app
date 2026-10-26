import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/photo/photo_viewer_screen.dart';

void main() {
  test('download names are reduced to a safe basename', () {
    expect(safeDownloadName('Beach Day.png'), 'Beach Day.png');
    expect(safeDownloadName('../../../sdcard/evil.png'), 'evil.png');
    expect(safeDownloadName(r'..\..\boot.ini'), 'boot.ini');
    expect(safeDownloadName('.hidden'), 'hidden');
    expect(safeDownloadName('a\nb.jpg'), 'ab.jpg');
    expect(safeDownloadName('../'), 'download');
  });
}
