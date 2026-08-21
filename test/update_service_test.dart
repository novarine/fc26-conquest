import 'package:flutter_test/flutter_test.dart';
import 'package:fc26_conquest/services/update_service.dart';

void main() {
  group('UpdateService', () {
    test('detects a newer release version', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.1.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test('supports patch and build number comparisons', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.1+2'), isFalse);
    });

    test('extracts version and installer url from a manifest payload', () {
      const manifest = {
        'version': '1.2.0',
        'installerUrl': 'https://example.com/releases/fc26-conquest-setup.exe',
      };

      expect(UpdateService.extractVersionFromManifest(manifest), '1.2.0');
      expect(
        UpdateService.extractDownloadUrlFromManifest(manifest),
        'https://example.com/releases/fc26-conquest-setup.exe',
      );
    });

    test('accepts common alternate manifest field names', () {
      const manifest = {
        'latestVersion': '2.0.0',
        'downloadUrl': 'https://example.com/download/latest.exe',
      };

      expect(UpdateService.extractVersionFromManifest(manifest), '2.0.0');
      expect(
        UpdateService.extractDownloadUrlFromManifest(manifest),
        'https://example.com/download/latest.exe',
      );
    });

    test('extracts release notes from the manifest', () {
      const manifest = {
        'version': '1.3.0',
        'installerUrl': 'https://example.com/releases/fc26-conquest-setup.exe',
        'releaseNotes':
            '- fixed missing club logos\n- improved Windows installer flow',
      };

      expect(UpdateService.extractReleaseNotesFromManifest(manifest),
          '- fixed missing club logos\n- improved Windows installer flow');
    });
  });
}
