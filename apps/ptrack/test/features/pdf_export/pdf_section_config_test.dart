import 'package:flutter_test/flutter_test.dart';

import 'package:luma/features/pdf_export/pdf_section_config.dart';

void main() {
  group('PdfExportPreset sections', () {
    test('summary enables overview only', () {
      expect(
        sectionsForPreset(PdfExportPreset.summary),
        {PdfSection.overviewStats},
      );
    });

    test('standard enables overview, cycle history, day table', () {
      expect(
        sectionsForPreset(PdfExportPreset.standard),
        {
          PdfSection.overviewStats,
          PdfSection.cycleHistory,
          PdfSection.daySummaryTable,
        },
      );
    });

    test('full enables all sections', () {
      expect(
        sectionsForPreset(PdfExportPreset.full),
        PdfSection.values.toSet(),
      );
    });
  });

  group('PdfSectionConfig.fromPreset', () {
    test('full preset uses all sections', () {
      final c = PdfSectionConfig.fromPreset(
        PdfExportPreset.full,
        rangeStart: DateTime.utc(2025, 1, 1),
        rangeEnd: DateTime.utc(2025, 12, 31),
      );
      expect(c.enabledSections, PdfSection.values.toSet());
      expect(c.rangeStart, DateTime.utc(2025, 1, 1));
      expect(c.rangeEnd, DateTime.utc(2025, 12, 31));
    });
  });
}
