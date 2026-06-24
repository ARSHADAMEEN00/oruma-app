import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:oruma_app/models/patient.dart';
import 'package:oruma_app/models/patient_details.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a comprehensive multi-page patient report PDF.
class PatientPdfGenerator {
  const PatientPdfGenerator._();

  // Page canvas dimensions (A4 @ 150 dpi equivalent)
  static const double _pw = 1240.0;
  static const double _ph = 1754.0;

  // Content margins
  static const double _marginL = 56.0;
  static const double _marginR = 56.0;
  static double get _contentW => _pw - _marginL - _marginR;

  // Brand colours
  static const Color _primary = Color(0xFF185FA5);
  static const Color _primaryLight = Color(0xFFE6F1FB);
  static const Color _ink = Color(0xFF1A2233);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFD1DFF0);
  static const Color _headerBg = Color(0xFF185FA5);
  static const Color _altRow = Color(0xFFF0F6FC);

  // Org constants (mirrors login screen)
  static const String _orgName = 'Team Oruma';
  static const String _orgSub = 'Kodur, Malappuram';
  static const String _phone1 = 'Office: 9495006193';
  static const String _phone2 = 'Home care: 9495006192';
  static const String _pageFooter =
      'Kodur Palliative Care Centre — Confidential Patient Report';

  // ─── Public API ───────────────────────────────────────────────────────────

  static Future<Uint8List> generate(PatientDetails details) async {
    final logoBytes = await _loadLogo();
    ui.Image? logoImage;
    if (logoBytes != null) {
      logoImage = await _decodeImage(logoBytes);
    }

    final pages = <Uint8List>[
      await _renderPage((c) => _paintPage1(c, details, logoImage)),
      await _renderPage((c) => _paintPage2(c, details, logoImage)),
      await _renderPage((c) => _paintPage3(c, details, logoImage)),
    ];

    logoImage?.dispose();

    final doc = pw.Document();
    for (final pageBytes in pages) {
      final img = pw.MemoryImage(pageBytes);
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Image(img, fit: pw.BoxFit.fill),
        ),
      ));
    }
    return doc.save();
  }

  static String fileName(Patient patient) {
    final name = (patient.name)
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final id = patient.registerId?.trim().replaceAll('/', '-') ?? 'pt';
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'patient_report_${name.isEmpty ? id : name.toLowerCase()}_$date.pdf';
  }

  // ─── Page renderers ───────────────────────────────────────────────────────

  /// Page 1: Header + Patient banner + A (Personal) + B (Location) + C (Medical) + D (Record)
  static void _paintPage1(Canvas c, PatientDetails d, ui.Image? logo) {
    final p = d.patient;

    _paintPageHeader(c, logo, 1, 3);

    double y = _headerBottom + 32;

    // Patient banner
    y = _paintPatientBanner(c, p, y);
    y += 28;

    // Section A — Personal Information
    y = _paintSectionTitle(c, 'A', 'Personal Information', y);
    y += 14;
    final personalRows = <_Row>[
      _Row('Register ID', _v(p.registerId)),
      _Row('Full Name', _displayName(p.name)),
      _Row('Phone', _v(p.phone)),
      _Row('Caregiver / Relation', _v(p.relation)),
      _Row('Caregiver Phone', _v(p.phone2)),
      _Row('Gender', _v(p.gender)),
      _Row('Age', '${p.age} years'),
    ];
    y = _paintInfoGrid(c, personalRows, y);
    y += 24;

    // Section B — Location & Address
    y = _paintSectionTitle(c, 'B', 'Location & Address', y);
    y += 14;
    final locationRows = <_Row>[
      _Row('Address', _v(p.address), height: 80), // taller for multi-line
      _Row('Place', _v(p.place)),
      _Row('Village', _v(p.village)),
      _Row('Ward Number', _v(p.ward)),
    ];
    y = _paintInfoGrid(c, locationRows, y);
    y += 24;

    // Section C — Medical Details
    y = _paintSectionTitle(c, 'C', 'Medical Details', y);
    y += 14;
    final conditions =
        p.disease.isEmpty ? 'No conditions recorded' : p.disease.join(', ');
    final medRows = <_Row>[
      _Row('Conditions', conditions),
      _Row('Care Plan', _v(p.plan)),
    ];
    y = _paintInfoGrid(c, medRows, y);
    y += 24;

    // Section D — Record Information
    y = _paintSectionTitle(c, 'D', 'Record Information', y);
    y += 14;
    final recordRows = <_Row>[
      _Row('Registration Date', _fmtDate(p.registrationDate)),
      if (p.isDead) _Row('Date of Death', _fmtDate(p.dateOfDeath)),
      _Row('Last Updated', _fmtDateTime(p.updatedAt)),
    ];
    _paintInfoGrid(c, recordRows, y);

    _paintPageFooter(c);
  }

  /// Page 2: Header + E (Home Visits table)
  static void _paintPage2(Canvas c, PatientDetails d, ui.Image? logo) {
    _paintPageHeader(c, logo, 2, 3);

    double y = _headerBottom + 32;

    // Section E — Home Visits Table
    y = _paintSectionTitle(c, 'E', 'Home Visits (${d.homeVisits.length})', y);
    y += 14;

    if (d.homeVisits.isEmpty) {
      _paintEmptyState(c, 'No home visits recorded', y);
    } else {
      // Columns scaled to fill full content width (_contentW = 1128)
      // Raw ratio widths → scaled to 1128 total
      const hvCols = <String>['#', 'Date', 'Type', 'Team', 'Address', 'Notes', 'Recorded By'];
      final hvWidths = _scaleWidths([44, 130, 100, 170, 230, 230, 200]);
      y = _paintTableHeader(c, hvCols, hvWidths, y);
      for (var i = 0; i < d.homeVisits.length; i++) {
        final v = d.homeVisits[i];
        final cells = [
          '${i + 1}',
          _fmtVisitDate(v.visitDate),
          _visitModeLabel(v.visitMode),
          _v(v.team),
          _v(v.address),
          _v(v.notes),
          _v(v.createdBy),
        ];
        y = _paintTableRow(c, cells, hvWidths, y, alt: i.isOdd);
        if (y > _ph - 120) break;
      }
      _paintTableBorderStored(c, y);
    }

    _paintPageFooter(c);
  }

  /// Page 3: Header + F (Equipment) + G (Medicine)
  static void _paintPage3(Canvas c, PatientDetails d, ui.Image? logo) {
    _paintPageHeader(c, logo, 3, 3);

    double y = _headerBottom + 32;

    // Section F — Equipment Distributed
    y = _paintSectionTitle(
        c, 'F', 'Equipment Distributed (${d.equipmentSupplies.length})', y);
    y += 14;

    if (d.equipmentSupplies.isEmpty) {
      y = _paintEmptyState(c, 'No equipment distributed', y);
    } else {
      const eqCols = <String>[
        '#', 'Equipment', 'ID', 'Distributed', 'Exp. Return', 'Returned', 'Receiver', 'Status'
      ];
      final eqWidths = _scaleWidths([40, 210, 140, 115, 115, 115, 200, 120]);
      y = _paintTableHeader(c, eqCols, eqWidths, y);
      for (var i = 0; i < d.equipmentSupplies.length; i++) {
        final s = d.equipmentSupplies[i];
        final cells = [
          '${i + 1}',
          _v(s.equipmentName),
          _v(s.equipmentUniqueId),
          _fmtDate(s.supplyDate),
          s.returnDate != null ? _fmtDate(s.returnDate) : '—',
          s.actualReturnDate != null ? _fmtDate(s.actualReturnDate) : '—',
          s.receiverName != null
              ? '${_v(s.receiverName)}\n${_v(s.receiverPhone)}'
              : _v(s.careOf),
          _equipStatusLabel(s.status),
        ];
        y = _paintTableRow(c, cells, eqWidths, y,
            alt: i.isOdd, statusColIndex: 7, statusValue: s.status);
        if (y > _ph - 300) break;
      }
      _paintTableBorderStored(c, y);
    }

    y += 28;

    // Section G — Medicine Supply List
    y = _paintSectionTitle(
        c, 'G', 'Medicine Supply List (${d.medicineSupplies.length})', y);
    y += 14;

    if (d.medicineSupplies.isEmpty) {
      _paintEmptyState(c, 'No medicine supplies recorded', y);
    } else {
      const medCols = <String>[
        '#', 'Medicine', 'Qty', 'Date Given', 'Staff', 'Days', 'Prescribed By', 'Status'
      ];
      final medWidths = _scaleWidths([40, 230, 65, 130, 185, 65, 210, 120]);
      y = _paintTableHeader(c, medCols, medWidths, y);
      for (var i = 0; i < d.medicineSupplies.length; i++) {
        final s = d.medicineSupplies[i];
        final cells = [
          '${i + 1}',
          s.medicineName,
          '${s.qtyGiven}',
          _fmtDate(s.givenAt),
          s.staffName,
          s.supplyDays != null ? '${s.supplyDays}d' : '—',
          _v(s.prescribedBy),
          _medStatusLabel(s.status),
        ];
        y = _paintTableRow(c, cells, medWidths, y,
            alt: i.isOdd, statusColIndex: 7, statusValue: s.status ?? 'given');
        if (y > _ph - 120) break;
      }
      _paintTableBorderStored(c, y);
    }

    _paintPageFooter(c);
  }

  // ─── Painting helpers ─────────────────────────────────────────────────────

  static const double _headerBottom = 190.0;

  static void _paintPageHeader(Canvas c, ui.Image? logo, int page, int total) {
    c.drawRect(
      const Rect.fromLTWH(0, 0, _pw, _headerBottom),
      Paint()..color = _headerBg,
    );

    const logoSize = 84.0;
    const logoX = _marginL;
    const logoY = (_headerBottom - logoSize) / 2;
    if (logo != null) {
      c.save();
      c.clipPath(Path()
        ..addOval(const Rect.fromLTWH(logoX, logoY, logoSize, logoSize)));
      c.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        const Rect.fromLTWH(logoX, logoY, logoSize, logoSize),
        Paint(),
      );
      c.restore();
      c.drawCircle(
        const Offset(logoX + logoSize / 2, logoY + logoSize / 2),
        logoSize / 2,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    _text(c, _orgName, const Rect.fromLTWH(160, 38, 600, 52),
        size: 40, weight: FontWeight.w800, color: Colors.white);
    _text(c, _orgSub, const Rect.fromLTWH(160, 92, 500, 30),
        size: 22, color: Colors.white.withValues(alpha: 0.82));
    _text(c, '$_phone1   |   $_phone2',
        const Rect.fromLTWH(160, 126, 700, 28),
        size: 19, color: Colors.white.withValues(alpha: 0.72));

    _text(c, 'PATIENT REPORT', const Rect.fromLTWH(860, 38, 330, 42),
        size: 28,
        weight: FontWeight.w900,
        color: Colors.white,
        align: TextAlign.right);
    _text(
        c,
        'Generated: ${DateFormat('dd MMM yyyy, h:mm a').format(DateTime.now())}',
        const Rect.fromLTWH(760, 86, 430, 26),
        size: 17,
        color: Colors.white.withValues(alpha: 0.72),
        align: TextAlign.right);
    _text(c, 'Page $page of $total',
        const Rect.fromLTWH(760, 116, 430, 26),
        size: 18,
        weight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.85),
        align: TextAlign.right);
  }

  static double _paintPatientBanner(Canvas c, Patient p, double y) {
    const bannerH = 134.0;
    final bannerRect = Rect.fromLTWH(_marginL, y, _contentW, bannerH);
    c.drawRRect(
      RRect.fromRectAndRadius(bannerRect, const Radius.circular(18)),
      Paint()..color = _primaryLight,
    );
    // left accent bar
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_marginL, y, 8, bannerH),
        const Radius.circular(18),
      ),
      Paint()..color = _primary,
    );

    // Avatar circle — centered on left
    const avatarR = 48.0;
    final avatarCx = _marginL + 38.0; // push inside the banner from the accent bar
    final avatarCy = y + bannerH / 2;
    c.drawCircle(Offset(avatarCx, avatarCy), avatarR, Paint()..color = _primary);

    // Fix 1: vertically center initial letter inside the circle
    final initial =
        p.name.trim().isEmpty ? '?' : p.name.trim()[0].toUpperCase();
    _centeredText(
      c,
      initial,
      Rect.fromLTWH(avatarCx - avatarR, avatarCy - avatarR, avatarR * 2, avatarR * 2),
      size: 38,
      weight: FontWeight.w900,
      color: Colors.white,
    );

    // Patient name
    _text(c, _displayName(p.name),
        Rect.fromLTWH(avatarCx + avatarR + 16, y + 16, 680, 46),
        size: 34, weight: FontWeight.w800, color: _ink);

    // Secondary info
    final secondary = <String>[
      if (p.registerId?.isNotEmpty == true) 'ID ${p.registerId}',
      if (p.gender.isNotEmpty) p.gender,
      '${p.age} years',
    ].join('   •   ');
    _text(c, secondary,
        Rect.fromLTWH(avatarCx + avatarR + 16, y + 62, 680, 28),
        size: 20, color: _muted);

    // Conditions
    if (p.disease.isNotEmpty) {
      final conditions = p.disease.take(5).join('   ');
      _text(c, conditions,
          Rect.fromLTWH(avatarCx + avatarR + 16, y + 96, 680, 26),
          size: 18, weight: FontWeight.w700, color: _primary);
    }

    // Fix 3: status pill with vertically centered text
    final statusLabel = p.isDead ? 'Passed Away' : 'Active';
    final statusColor =
        p.isDead ? Colors.red.shade700 : Colors.green.shade700;
    const pillW = 150.0;
    const pillH = 40.0;
    final pillRect = Rect.fromLTWH(
        _marginL + _contentW - pillW - 16, y + (bannerH - pillH) / 2, pillW, pillH);
    c.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(99)),
      Paint()..color = statusColor.withValues(alpha: 0.12),
    );
    _centeredText(c, statusLabel, pillRect,
        size: 18, weight: FontWeight.w800, color: statusColor);

    return y + bannerH;
  }

  static double _paintSectionTitle(Canvas c, String letter, String title, double y) {
    const badgeSize = 38.0;
    // Fix 1: blue badge with vertically centered letter
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_marginL, y, badgeSize, badgeSize),
        const Radius.circular(10),
      ),
      Paint()..color = _primary,
    );
    _centeredText(
      c,
      letter,
      Rect.fromLTWH(_marginL, y, badgeSize, badgeSize),
      size: 22,
      weight: FontWeight.w900,
      color: Colors.white,
    );

    _text(c, title,
        Rect.fromLTWH(_marginL + badgeSize + 12, y + 5, 800, 30),
        size: 26, weight: FontWeight.w800, color: _primary);

    // Divider
    c.drawLine(
      Offset(_marginL + badgeSize + 12, y + badgeSize),
      Offset(_pw - _marginR, y + badgeSize),
      Paint()..color = _border..strokeWidth = 1.5,
    );
    return y + badgeSize;
  }

  /// Fix 2 & 3: info grid with per-row heights and vertically centered text.
  static double _paintInfoGrid(Canvas c, List<_Row> rows, double y) {
    const labelW = 250.0;
    const valueX = _marginL + labelW + 20;
    const defaultRowH = 54.0;

    var curY = y;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowH = row.height ?? defaultRowH;

      if (i.isOdd) {
        c.drawRect(
          Rect.fromLTWH(_marginL, curY, _contentW, rowH),
          Paint()..color = _altRow,
        );
      }

      // Vertically center both label and value within the row
      _centeredText(
        c,
        row.label,
        Rect.fromLTWH(_marginL + 16, curY, labelW - 16, rowH),
        size: 18,
        weight: FontWeight.w600,
        color: _muted,
        align: TextAlign.left,
      );
      _centeredText(
        c,
        row.value,
        Rect.fromLTWH(valueX, curY, _pw - valueX - _marginR, rowH),
        size: 18,
        weight: FontWeight.w700,
        color: _ink,
        align: TextAlign.left,
      );

      curY += rowH;
    }

    // Bottom border
    c.drawLine(
      Offset(_marginL, curY),
      Offset(_pw - _marginR, curY),
      Paint()..color = _border..strokeWidth = 1.2,
    );
    return curY;
  }

  static double _paintEmptyState(Canvas c, String message, double y) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_marginL, y, _contentW, 68),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFF3F4F6),
    );
    _text(c, message,
        Rect.fromLTWH(_marginL, y + 18, _contentW, 36),
        size: 20, color: _muted, align: TextAlign.center);
    return y + 80;
  }

  // ─── Table helpers ────────────────────────────────────────────────────────

  static const double _tableRowH = 54.0;
  static const double _tableHeaderH = 50.0;

  // Track current table geometry for border drawing
  static double _tableLeft = _marginL;
  static double? _tableTopY;
  static double _tableStoredW = _contentW;

  /// Scale raw widths proportionally so they sum to exactly _contentW.
  static List<double> _scaleWidths(List<double> raw) {
    final sum = raw.fold<double>(0, (s, w) => s + w);
    final scale = _contentW / sum;
    return raw.map((w) => w * scale).toList();
  }

  static double _paintTableHeader(
      Canvas c, List<String> cols, List<double> widths, double y) {
    _tableTopY = y;
    _tableLeft = _marginL;
    _tableStoredW = widths.fold(0, (s, w) => s + w);

    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(_tableLeft, y, _tableStoredW, _tableHeaderH),
        const Radius.circular(10),
      ),
      Paint()..color = _primary,
    );

    var x = _tableLeft;
    for (var i = 0; i < cols.length; i++) {
      // Fix: vertically center header text
      _centeredText(
        c,
        cols[i],
        Rect.fromLTWH(x + 4, y, widths[i] - 8, _tableHeaderH),
        size: 16,
        weight: FontWeight.w800,
        color: Colors.white,
      );
      x += widths[i];
    }
    return y + _tableHeaderH;
  }

  static double _paintTableRow(
    Canvas c,
    List<String> cells,
    List<double> widths,
    double y, {
    bool alt = false,
    int? statusColIndex,
    String? statusValue,
  }) {
    if (alt) {
      c.drawRect(
        Rect.fromLTWH(_tableLeft, y, _tableStoredW, _tableRowH),
        Paint()..color = _altRow,
      );
    }

    var x = _tableLeft;
    for (var i = 0; i < cells.length; i++) {
      if (i == statusColIndex && statusValue != null) {
        // Fix 3 & 5: status pill centered both axes inside the cell
        final pillH = 32.0;
        final pillW = widths[i] - 20;
        final pillRect = Rect.fromLTWH(
            x + 10, y + (_tableRowH - pillH) / 2, pillW, pillH);
        _paintStatusPill(c, cells[i], statusValue, pillRect);
      } else {
        // Vertically center cell text
        _centeredText(
          c,
          cells[i],
          Rect.fromLTWH(x + 8, y, widths[i] - 16, _tableRowH),
          size: 15,
          color: _ink,
          align: TextAlign.left,
        );
      }
      // Column separator
      if (i < cells.length - 1) {
        c.drawLine(
          Offset(x + widths[i], y),
          Offset(x + widths[i], y + _tableRowH),
          Paint()..color = _border..strokeWidth = 1.0,
        );
      }
      x += widths[i];
    }
    // Row bottom line
    c.drawLine(
      Offset(_tableLeft, y + _tableRowH),
      Offset(_tableLeft + _tableStoredW, y + _tableRowH),
      Paint()..color = _border..strokeWidth = 0.8,
    );
    return y + _tableRowH;
  }

  /// Fix 5: uses stored width for border (no empty-list bug).
  static void _paintTableBorderStored(Canvas c, double bottomY) {
    if (_tableTopY == null) return;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            _tableLeft, _tableTopY!, _tableStoredW, bottomY - _tableTopY!),
        const Radius.circular(10),
      ),
      Paint()
        ..color = _border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Fix 3 & 5: status pill with fully centered text.
  static void _paintStatusPill(Canvas c, String label, String status, Rect rect) {
    final color = _statusColor(status);
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(99)),
      Paint()..color = color.withValues(alpha: 0.12),
    );
    _centeredText(c, label, rect,
        size: 14, weight: FontWeight.w800, color: color);
  }

  static void _paintPageFooter(Canvas c) {
    const footerY = _ph - 60.0;
    c.drawLine(
      const Offset(_marginL, footerY),
      const Offset(_pw - _marginR, footerY),
      Paint()..color = _border..strokeWidth = 1.2,
    );
    _text(c, _pageFooter,
        Rect.fromLTWH(_marginL, footerY + 10, _contentW, 28),
        size: 16, color: _muted, align: TextAlign.center);
  }

  // ─── Canvas text utilities ────────────────────────────────────────────────

  /// Draws text aligned to the left (or specified alignment) from the top of [rect].
  static void _text(
    Canvas c,
    String text,
    Rect rect, {
    double size = 18,
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    TextAlign align = TextAlign.left,
    double lineHeight = 1.2,
    double letterSpacing = 0,
  }) {
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: align,
        maxLines: 3,
        ellipsis: '\u2026',
      ),
    )
      ..pushStyle(ui.TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: lineHeight,
        letterSpacing: letterSpacing,
      ))
      ..addText(text.isEmpty ? ' ' : text);
    final para = pb.build()
      ..layout(ui.ParagraphConstraints(width: rect.width));
    c.drawParagraph(para, rect.topLeft);
  }

  /// Fix 1, 3: Draws text VERTICALLY CENTERED within [rect].
  /// For single-line use (badges, pills, table headers, status chips).
  static void _centeredText(
    Canvas c,
    String text,
    Rect rect, {
    double size = 18,
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    TextAlign align = TextAlign.center,
  }) {
    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: align,
        maxLines: 2,
        ellipsis: '\u2026',
      ),
    )
      ..pushStyle(ui.TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.15,
      ))
      ..addText(text.isEmpty ? ' ' : text);
    final para = pb.build()
      ..layout(ui.ParagraphConstraints(width: rect.width));
    // Vertically center: offset by (containerH - textH) / 2
    final offsetY = ((rect.height - para.height) / 2).clamp(0.0, rect.height);
    c.drawParagraph(para, Offset(rect.left, rect.top + offsetY));
  }



  static Future<Uint8List> _renderPage(void Function(Canvas) painter) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, _pw, _ph),
    );
    canvas.drawColor(Colors.white, BlendMode.src);
    painter(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(_pw.toInt(), _ph.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return byteData!.buffer.asUint8List();
  }

  // ─── Asset loading ────────────────────────────────────────────────────────

  static Future<Uint8List?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/logo/logo.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  // ─── Value helpers ────────────────────────────────────────────────────────

  static String _v(String? value) {
    if (value == null || value.trim().isEmpty) return 'Not recorded';
    return value.trim();
  }

  static String _displayName(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s*,\s*'), ', ');
    return normalized
        .split(RegExp(r'\s+'))
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy').format(d.toLocal());
  }

  static String _fmtDateTime(DateTime? d) {
    if (d == null) return '—';
    return DateFormat('dd MMM yyyy, h:mm a').format(d.toLocal());
  }

  static String _fmtVisitDate(String value) {
    final d = DateTime.tryParse(value);
    return d == null ? _v(value) : _fmtDate(d);
  }

  static String _visitModeLabel(String mode) {
    switch (mode) {
      case 'new':
        return 'New';
      case 'monthly':
        return 'Monthly';
      case 'emergency':
        return 'Emergency';
      case 'dhc_visit':
        return 'DHC';
      case 'vhc_visit':
        return 'VHC';
      default:
        return mode.replaceAll('_', ' ').toUpperCase();
    }
  }

  static String _equipStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'returned':
        return 'Returned';
      case 'lost':
        return 'Lost';
      default:
        return status;
    }
  }

  static String _medStatusLabel(String? status) {
    return switch (status) {
      'partially_given' => 'Partial',
      'returned' => 'Returned',
      'cancelled' => 'Cancelled',
      _ => 'Given',
    };
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'active':
      case 'given':
        return Colors.green.shade700;
      case 'returned':
        return Colors.blueGrey.shade700;
      case 'lost':
      case 'cancelled':
        return Colors.red.shade700;
      case 'partially_given':
        return Colors.orange.shade700;
      case 'emergency':
        return Colors.red;
      case 'monthly':
        return Colors.blue;
      default:
        return Colors.grey.shade700;
    }
  }
}

/// Label-value pair for the info grid. [height] overrides the default row height.
class _Row {
  final String label;
  final String value;
  final double? height;
  const _Row(this.label, this.value, {this.height});
}
