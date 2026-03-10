import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart' as el;
import '../../domain/entities/entities.dart';
import '../localization/lang_keys.dart';

class PdfService {
  static Future<void> generateProjectReport({
    required ProjectEntity project,
    required List<TaskEntity> tasks,
    required Map<String, UserEntity> users,
    required List<RequestEntity> requests,
    required Locale locale,
    bool shouldPrint = false,
  }) async {
    final pdf = pdfWidgets.Document();
    // Use Arabic layout if either the app locale is Arabic OR the project content is Arabic
    final bool projectIsArabic =
        _isArabic(project.title) || _isArabic(project.description);
    final isRtl = locale.languageCode == 'ar' || projectIsArabic;

    // Load both font sets for dynamic selection
    final arabicFont = pdfWidgets.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
    );
    final arabicMediumFont = pdfWidgets.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Medium.ttf'),
    );
    final arabicBoldFont = pdfWidgets.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
    );

    final englishFont = pdfWidgets.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
    );
    final englishMediumFont = pdfWidgets.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Medium.ttf'),
    );
    final englishBoldFont = pdfWidgets.Font.ttf(
      await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf'),
    );

    // Base fonts for the document theme
    // We use Arabic as base if the project content is Arabic to ensure fallback works better
    final font = (isRtl) ? arabicFont : englishFont;
    final mediumFont = (isRtl) ? arabicMediumFont : englishMediumFont;
    final boldFont = (isRtl) ? arabicBoldFont : englishBoldFont;

    final logoData = await rootBundle.load('assets/brand/foreground_icon.png');
    final logoImage = pdfWidgets.MemoryImage(logoData.buffer.asUint8List());

    final completedTasks = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final totalTasks = tasks.length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final inProgressTasks = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final pendingTasks = tasks
        .where((t) => t.status == TaskStatus.pending)
        .length;
    final highPriorityTasks = tasks
        .where(
          (t) =>
              t.priority == TaskPriority.high ||
              t.priority == TaskPriority.urgent,
        )
        .length;
    final overdueTasks = tasks
        .where(
          (t) =>
              t.status != TaskStatus.completed &&
              t.deadline.isBefore(DateTime.now()),
        )
        .length;
    final projectDeadline = tasks.isEmpty
        ? project.createdAt.add(const Duration(days: 30))
        : tasks.map((t) => t.deadline).reduce((a, b) => a.isAfter(b) ? a : b);

    pdf.addPage(
      pdfWidgets.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pdfWidgets.EdgeInsets.all(40),
        theme:
            pdfWidgets.ThemeData.withFont(
              base: font,
              bold: boldFont,
              italic: font,
            ).copyWith(
              defaultTextStyle: pdfWidgets.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
        header: (context) => pdfWidgets.Container(
          height: 100,
          child: _buildEliteHeader(mediumFont, logoImage, locale),
        ),
        build: (context) => [
          pdfWidgets.Directionality(
            textDirection: locale.languageCode == 'ar'
                ? pdfWidgets.TextDirection.rtl
                : pdfWidgets.TextDirection.ltr,
            child: pdfWidgets.Column(
              children: [
                _buildEliteHero(
                  project: project,
                  rate: completionRate,
                  users: users,
                  mediumFont: mediumFont,
                  arabicFont: arabicFont,
                  arabicMediumFont: arabicMediumFont,
                  arabicBoldFont: arabicBoldFont,
                  englishFont: englishFont,
                  englishMediumFont: englishMediumFont,
                  englishBoldFont: englishBoldFont,
                  projectDeadline: projectDeadline,
                  locale: locale,
                ),
                pdfWidgets.SizedBox(height: 20),
                _buildEliteStatsRibbon(
                  tasks: tasks,
                  completed: completedTasks,
                  highPriority: highPriorityTasks,
                  overdue: overdueTasks,
                  mediumFont: mediumFont,
                ),
                pdfWidgets.SizedBox(height: 15),
                _buildEliteVisualStats(
                  tasks: tasks,
                  completed: completedTasks,
                  inProgress: inProgressTasks,
                  pending: pendingTasks,
                  mediumFont: mediumFont,
                  locale: locale,
                ),
                pdfWidgets.SizedBox(height: 15),
                _buildEliteTeamSection(
                  users: users,
                  mediumFont: mediumFont,
                  arabicFont: arabicFont,
                  englishFont: englishFont,
                  locale: locale,
                ),
              ],
            ),
          ),
        ],
        footer: (context) => _buildCoolFooter(
          context,
          mediumFont: mediumFont,
          arabicFont: arabicFont,
          englishFont: englishFont,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'HUED_${project.title}_Report${shouldPrint ? "" : ".pdf"}',
      usePrinterSettings: shouldPrint,
    );
  }

  static pdfWidgets.Widget _buildEliteHeader(
    pdfWidgets.Font mediumFont,
    pdfWidgets.ImageProvider logo,
    Locale locale,
  ) {
    return pdfWidgets.Row(
      mainAxisAlignment: pdfWidgets.MainAxisAlignment.spaceBetween,
      children: [
        pdfWidgets.Column(
          crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
          mainAxisAlignment: pdfWidgets.MainAxisAlignment.center,
          children: [
            pdfWidgets.Image(logo, height: 45),
            pdfWidgets.SizedBox(height: 8),
            pdfWidgets.Container(
              width: 80,
              height: 0.5,
              color: PdfColors.red600,
            ),
          ],
        ),
        pdfWidgets.Column(
          crossAxisAlignment: pdfWidgets.CrossAxisAlignment.end,
          mainAxisAlignment: pdfWidgets.MainAxisAlignment.center,
          children: [
            _buildEliteText(
              LangKeys.leadingConsultancyFirm.tr(),
              fontSize: 6.5,
              color: PdfColors.grey900,
              mediumFont: mediumFont,
              isHeader: true,
            ),
            pdfWidgets.SizedBox(height: 4),
            pdfWidgets.SizedBox(height: 8),
            _buildEliteText(
              DateFormat.yMMMMd(locale.toString()).format(DateTime.now()),
              fontSize: 8,
              color: PdfColors.grey700,
              mediumFont: mediumFont,
            ),
          ],
        ),
      ],
    );
  }

  static pdfWidgets.Widget _buildEliteHero({
    required ProjectEntity project,
    required double rate,
    required Map<String, UserEntity> users,
    required pdfWidgets.Font mediumFont,
    required pdfWidgets.Font arabicFont,
    required pdfWidgets.Font arabicMediumFont,
    required pdfWidgets.Font arabicBoldFont,
    required pdfWidgets.Font englishFont,
    required pdfWidgets.Font englishMediumFont,
    required pdfWidgets.Font englishBoldFont,
    required DateTime projectDeadline,
    required Locale locale,
  }) {
    final creator = users[project.creatorId]?.name ?? 'System';
    final dateFormat = DateFormat.yMMMMd(locale.toString());

    return pdfWidgets.Container(
      child: pdfWidgets.Column(
        crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
        children: [
          pdfWidgets.Row(
            crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
            children: [
              pdfWidgets.Expanded(
                flex: 3,
                child: pdfWidgets.Column(
                  crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
                  children: [
                    _buildEliteText(
                      _getProjectStatusLabel(project.status),
                      fontSize: 7,
                      color: _getProjectStatusColor(project.status),
                      mediumFont: mediumFont,
                      isHeader: true,
                    ),
                    pdfWidgets.SizedBox(height: 8),
                    pdfWidgets.Directionality(
                      textDirection: _isArabic(project.title)
                          ? pdfWidgets.TextDirection.rtl
                          : pdfWidgets.TextDirection.ltr,
                      child: pdfWidgets.Text(
                        project.title,
                        style: pdfWidgets.TextStyle(
                          fontSize: 24,
                          color: PdfColors.black,
                          font: _getFontForText(
                            project.title,
                            arabicFont: arabicBoldFont,
                            englishFont: englishBoldFont,
                          ),
                        ),
                      ),
                    ),
                    pdfWidgets.SizedBox(height: 20),
                    pdfWidgets.Container(
                      width: 20,
                      height: 0.5,
                      color: PdfColors.grey300,
                    ),
                    pdfWidgets.SizedBox(height: 20),
                    pdfWidgets.Directionality(
                      textDirection: _isArabic(project.description)
                          ? pdfWidgets.TextDirection.rtl
                          : pdfWidgets.TextDirection.ltr,
                      child: pdfWidgets.Text(
                        project.description,
                        style: pdfWidgets.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                          lineSpacing: 6,
                          font: _getFontForText(
                            project.description,
                            arabicFont: arabicFont,
                            englishFont: englishFont,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pdfWidgets.SizedBox(width: 40),
              pdfWidgets.Expanded(
                flex: 1,
                child: pdfWidgets.Column(
                  crossAxisAlignment: pdfWidgets.CrossAxisAlignment.end,
                  children: [
                    pdfWidgets.Text(
                      '${(rate * 100).toInt()}%',
                      style: pdfWidgets.TextStyle(
                        fontSize: 48,
                        fontWeight: pdfWidgets.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                    ),
                    _buildEliteText(
                      'COMPLETION RATE',
                      fontSize: 6,
                      color: PdfColors.grey500,
                      mediumFont: mediumFont,
                      isHeader: true,
                    ),
                    pdfWidgets.SizedBox(height: 15),
                    _eliteDetailItem(
                      LangKeys.projectDirector.tr(),
                      creator,
                      mediumFont,
                      arabicFont,
                      englishFont,
                    ),
                    pdfWidgets.SizedBox(height: 15),
                    _eliteDetailItem(
                      LangKeys.deadlineLabel.tr(),
                      dateFormat.format(projectDeadline),
                      mediumFont,
                      arabicFont,
                      englishFont,
                    ),
                    pdfWidgets.SizedBox(height: 15),
                    _eliteDetailItem(
                      LangKeys.reportIdentifier.tr(),
                      project.id.substring(0, 8).toUpperCase(),
                      mediumFont,
                      arabicFont,
                      englishFont,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pdfWidgets.Widget _eliteDetailItem(
    String label,
    String value,
    pdfWidgets.Font mediumFont,
    pdfWidgets.Font arabicFont,
    pdfWidgets.Font englishFont,
  ) {
    return pdfWidgets.Column(
      crossAxisAlignment: pdfWidgets.CrossAxisAlignment.end,
      children: [
        _buildEliteText(
          label,
          fontSize: 5,
          color: PdfColors.grey400,
          mediumFont: mediumFont,
          isHeader: true,
        ),
        pdfWidgets.SizedBox(height: 2),
        pdfWidgets.Directionality(
          textDirection: _isArabic(value)
              ? pdfWidgets.TextDirection.rtl
              : pdfWidgets.TextDirection.ltr,
          child: pdfWidgets.Text(
            value,
            style: pdfWidgets.TextStyle(
              fontSize: 9,
              color: PdfColors.grey900,
              fontWeight: pdfWidgets.FontWeight.bold,
              font: _getFontForText(
                value,
                arabicFont: arabicFont,
                englishFont: englishFont,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static pdfWidgets.Widget _buildEliteStatsRibbon({
    required List<TaskEntity> tasks,
    required int completed,
    required int highPriority,
    required int overdue,
    required pdfWidgets.Font mediumFont,
  }) {
    return pdfWidgets.Container(
      padding: const pdfWidgets.EdgeInsets.symmetric(vertical: 20),
      decoration: const pdfWidgets.BoxDecoration(
        border: pdfWidgets.Border(
          top: pdfWidgets.BorderSide(color: PdfColors.grey100, width: 0.2),
          bottom: pdfWidgets.BorderSide(color: PdfColors.grey100, width: 0.2),
        ),
      ),
      child: pdfWidgets.Row(
        mainAxisAlignment: pdfWidgets.MainAxisAlignment.spaceAround,
        children: [
          _ribbonItem(LangKeys.tasks.tr(), tasks.length.toString(), mediumFont),
          _ribbonDivider(),
          _ribbonItem(
            LangKeys.completed.tr(),
            completed.toString(),
            mediumFont,
          ),
          _ribbonDivider(),
          _ribbonItem(
            LangKeys.priority.tr(),
            highPriority.toString(),
            mediumFont,
          ),
          _ribbonDivider(),
          _ribbonItem(
            LangKeys.overdue.tr(),
            overdue.toString(),
            mediumFont,
            color: overdue > 0 ? PdfColors.red700 : null,
          ),
        ],
      ),
    );
  }

  static pdfWidgets.Widget _ribbonItem(
    String label,
    String value,
    pdfWidgets.Font mediumFont, {
    PdfColor? color,
  }) {
    return pdfWidgets.Column(
      children: [
        pdfWidgets.Text(
          value,
          style: pdfWidgets.TextStyle(
            fontSize: 16,
            color: color ?? PdfColors.black,
            font: mediumFont,
          ),
        ),
        pdfWidgets.SizedBox(height: 4),
        _buildEliteText(
          label,
          fontSize: 6,
          color: PdfColors.grey500,
          mediumFont: mediumFont,
          isHeader: true,
        ),
      ],
    );
  }

  static pdfWidgets.Widget _ribbonDivider() {
    return pdfWidgets.Container(
      width: 0.2,
      height: 25,
      color: PdfColors.grey200,
    );
  }

  static pdfWidgets.Widget _buildEliteVisualStats({
    required List<TaskEntity> tasks,
    required int completed,
    required int inProgress,
    required int pending,
    required pdfWidgets.Font mediumFont,
    required Locale locale,
  }) {
    final total = tasks.length;
    if (total == 0) return pdfWidgets.SizedBox();
    return pdfWidgets.Column(
      crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
      children: [
        _buildEliteText(
          LangKeys.projectHealthOrientation.tr(),
          fontSize: 7,
          color: PdfColors.grey400,
          mediumFont: mediumFont,
          isHeader: true,
        ),
        pdfWidgets.SizedBox(height: 20),
        pdfWidgets.Row(
          crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
          children: [
            pdfWidgets.Expanded(
              flex: 2,
              child: pdfWidgets.Column(
                children: [
                  _buildEliteProgressBar(
                    label: LangKeys.taskStatusDistribution.tr(),
                    segments: [
                      _StatSegment(completed / total, PdfColors.black),
                      _StatSegment(inProgress / total, PdfColors.grey600),
                      _StatSegment(pending / total, PdfColors.grey300),
                    ],
                    mediumFont: mediumFont,
                  ),
                  pdfWidgets.SizedBox(height: 25),
                  _buildElitePriorityIntensity(tasks, mediumFont),
                ],
              ),
            ),
            pdfWidgets.SizedBox(width: 40),
            pdfWidgets.Expanded(
              flex: 1,
              child: pdfWidgets.Column(
                crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
                children: [
                  pdfWidgets.SizedBox(height: 15),
                  _statLegendItem(
                    LangKeys.completed.tr(),
                    completed,
                    PdfColors.black,
                    mediumFont,
                  ),
                  pdfWidgets.SizedBox(height: 8),
                  _statLegendItem(
                    LangKeys.inProgress.tr(),
                    inProgress,
                    PdfColors.grey600,
                    mediumFont,
                  ),
                  pdfWidgets.SizedBox(height: 8),
                  _statLegendItem(
                    LangKeys.pending.tr(),
                    pending,
                    PdfColors.grey300,
                    mediumFont,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pdfWidgets.Widget _buildElitePriorityIntensity(
    List<TaskEntity> tasks,
    pdfWidgets.Font mediumFont,
  ) {
    final urgent = tasks.where((t) => t.priority == TaskPriority.urgent).length;
    final high = tasks.where((t) => t.priority == TaskPriority.high).length;
    final medium = tasks.where((t) => t.priority == TaskPriority.medium).length;
    final low = tasks.where((t) => t.priority == TaskPriority.low).length;
    final total = tasks.length;

    return _buildEliteProgressBar(
      label: LangKeys.priorityIntensity.tr(),
      segments: [
        _StatSegment(urgent / total, PdfColors.red900),
        _StatSegment(high / total, PdfColors.red600),
        _StatSegment(medium / total, PdfColors.grey400),
        _StatSegment(low / total, PdfColors.grey100),
      ],
      mediumFont: mediumFont,
    );
  }

  static pdfWidgets.Widget _buildEliteProgressBar({
    required String label,
    required List<_StatSegment> segments,
    required pdfWidgets.Font mediumFont,
  }) {
    return pdfWidgets.Column(
      crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
      children: [
        _buildEliteText(
          label,
          fontSize: 5,
          color: PdfColors.grey500,
          mediumFont: mediumFont,
          isHeader: true,
        ),
        pdfWidgets.SizedBox(height: 6),
        pdfWidgets.ClipRRect(
          horizontalRadius: 1,
          verticalRadius: 1,
          child: pdfWidgets.Container(
            height: 6,
            child: pdfWidgets.Row(
              children: segments
                  .where((s) => s.ratio > 0)
                  .map(
                    (s) => pdfWidgets.Expanded(
                      flex: (s.ratio * 1000).toInt(),
                      child: pdfWidgets.Container(color: s.color),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  static pdfWidgets.Widget _statLegendItem(
    String label,
    int value,
    PdfColor color,
    pdfWidgets.Font mediumFont,
  ) {
    final bool isAr = _isArabic(label);
    return pdfWidgets.Row(
      mainAxisAlignment: isAr
          ? pdfWidgets.MainAxisAlignment.end
          : pdfWidgets.MainAxisAlignment.start,
      children: [
        if (isAr) ...[
          pdfWidgets.SizedBox(width: 8),
          _buildEliteText(
            '$value $label',
            fontSize: 8,
            color: PdfColors.grey800,
            mediumFont: mediumFont,
          ),
          pdfWidgets.SizedBox(width: 8),
          pdfWidgets.Container(width: 8, height: 8, color: color),
        ] else ...[
          pdfWidgets.Container(width: 8, height: 8, color: color),
          pdfWidgets.SizedBox(width: 8),
          _buildEliteText(
            '$value $label',
            fontSize: 8,
            color: PdfColors.grey800,
            mediumFont: mediumFont,
          ),
        ],
      ],
    );
  }

  static pdfWidgets.Widget _buildEliteText(
    String text, {
    required double fontSize,
    required pdfWidgets.Font mediumFont,
    PdfColor? color,
    bool isHeader = false,
  }) {
    final bool isAr = _isArabic(text);
    return pdfWidgets.Directionality(
      textDirection: isAr
          ? pdfWidgets.TextDirection.rtl
          : pdfWidgets.TextDirection.ltr,
      child: pdfWidgets.Text(
        isAr || !isHeader ? text : text.toUpperCase(),
        style: pdfWidgets.TextStyle(
          fontSize: fontSize,
          color: color ?? PdfColors.black,
          font: mediumFont,
          letterSpacing: isAr ? 0 : (isHeader ? 1.2 : 0),
        ),
      ),
    );
  }

  static pdfWidgets.Widget _buildCoolFooter(
    pdfWidgets.Context context, {
    required pdfWidgets.Font mediumFont,
    required pdfWidgets.Font arabicFont,
    required pdfWidgets.Font englishFont,
  }) {
    return pdfWidgets.Container(
      margin: const pdfWidgets.EdgeInsets.only(top: 40),
      padding: const pdfWidgets.EdgeInsets.only(top: 20),
      decoration: const pdfWidgets.BoxDecoration(
        border: pdfWidgets.Border(
          top: pdfWidgets.BorderSide(color: PdfColors.grey100, width: 1),
        ),
      ),
      child: pdfWidgets.Row(
        mainAxisAlignment: pdfWidgets.MainAxisAlignment.spaceBetween,
        children: [
          pdfWidgets.Column(
            crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
            children: [
              _buildEliteText(
                'HUED DIGITAL SOLUTIONS',
                fontSize: 7,
                color: PdfColors.grey600,
                mediumFont: englishFont,
                isHeader: true,
              ),
              pdfWidgets.SizedBox(height: 4),
              pdfWidgets.Text(
                LangKeys.confidentialProjectReport.tr(),
                style: pdfWidgets.TextStyle(
                  color: PdfColors.grey400,
                  fontSize: 6,
                  font: englishFont,
                ),
              ),
            ],
          ),
          pdfWidgets.Container(
            padding: const pdfWidgets.EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: pdfWidgets.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pdfWidgets.BorderRadius.circular(5),
            ),
            child: pdfWidgets.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: pdfWidgets.TextStyle(
                color: PdfColors.grey700,
                fontSize: 8,
                font: mediumFont,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _getProjectStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.finished:
        return PdfColors.green600;
      case ProjectStatus.inProgress:
        return PdfColors.blue600;
      case ProjectStatus.canceled:
        return PdfColors.red600;
      case ProjectStatus.archived:
        return PdfColors.grey600;
    }
  }

  static pdfWidgets.Widget _buildEliteTeamSection({
    required Map<String, UserEntity> users,
    required pdfWidgets.Font mediumFont,
    required pdfWidgets.Font arabicFont,
    required pdfWidgets.Font englishFont,
    required Locale locale,
  }) {
    if (users.isEmpty) return pdfWidgets.SizedBox();

    final userList = users.values.toList();
    return pdfWidgets.Column(
      crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
      children: [
        _buildEliteText(
          LangKeys.navUsers.tr(),
          fontSize: 7,
          color: PdfColors.grey400,
          mediumFont: mediumFont,
          isHeader: true,
        ),
        pdfWidgets.SizedBox(height: 10),
        pdfWidgets.Wrap(
          spacing: 15,
          runSpacing: 8,
          children: userList.map((user) {
            return pdfWidgets.Container(
              padding: const pdfWidgets.EdgeInsets.all(5),
              decoration: pdfWidgets.BoxDecoration(
                border: pdfWidgets.Border.all(
                  color: PdfColors.grey100,
                  width: 0.2,
                ),
                borderRadius: const pdfWidgets.BorderRadius.all(
                  pdfWidgets.Radius.circular(2),
                ),
              ),
              child: pdfWidgets.Row(
                mainAxisSize: pdfWidgets.MainAxisSize.min,
                children: [
                  pdfWidgets.Container(
                    width: 4,
                    height: 4,
                    decoration: const pdfWidgets.BoxDecoration(
                      color: PdfColors.red600,
                      shape: pdfWidgets.BoxShape.circle,
                    ),
                  ),
                  pdfWidgets.SizedBox(width: 5),
                  pdfWidgets.Text(
                    user.name,
                    style: pdfWidgets.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey900,
                      font: _getFontForText(
                        user.name,
                        arabicFont: arabicFont,
                        englishFont: englishFont,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static bool _isArabic(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');
    return arabicRegex.hasMatch(text);
  }

  static pdfWidgets.Font _getFontForText(
    String text, {
    required pdfWidgets.Font arabicFont,
    required pdfWidgets.Font englishFont,
  }) {
    return _isArabic(text) ? arabicFont : englishFont;
  }

  static String _getProjectStatusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.finished:
        return LangKeys.finished.tr();
      case ProjectStatus.inProgress:
        return LangKeys.active.tr();
      case ProjectStatus.archived:
        return LangKeys.archived.tr();
      case ProjectStatus.canceled:
        return LangKeys.canceled.tr();
    }
  }
}

class _StatSegment {
  final double ratio;
  final PdfColor color;
  _StatSegment(this.ratio, this.color);
}
