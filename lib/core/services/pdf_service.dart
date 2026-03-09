import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
    final pdf = pw.Document();
    final isRtl = locale.languageCode == 'ar';

    // Choose fonts based on locale
    final font = isRtl
        ? await PdfGoogleFonts.almaraiRegular()
        : await PdfGoogleFonts.plusJakartaSansRegular();
    final mediumFont = isRtl
        ? await PdfGoogleFonts.almaraiRegular()
        : await PdfGoogleFonts.plusJakartaSansMedium();
    final boldFont = isRtl
        ? await PdfGoogleFonts.almaraiBold()
        : await PdfGoogleFonts.plusJakartaSansBold();

    final logoData = await rootBundle.load('assets/brand/foreground_icon.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    final completedTasks = tasks
        .where((t) => t.status == TaskStatus.completed)
        .length;
    final totalTasks = tasks.length;
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
    final contributorsCount = project.assignedUserIds.length;
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    final projectDeadline = tasks.isEmpty
        ? project.createdAt.add(const Duration(days: 30))
        : tasks.map((t) => t.deadline).reduce((a, b) => a.isAfter(b) ? a : b);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: font)
            .copyWith(
              defaultTextStyle: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
        build: (context) => [
          pw.Directionality(
            textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildCoolHeader(mediumFont, logoImage, locale),
                pw.SizedBox(height: 30),
                _buildCoolHero(
                  project,
                  completionRate,
                  users,
                  mediumFont,
                  projectDeadline,
                  locale,
                ),
                pw.SizedBox(height: 30),
                _buildCoolStatsRow(
                  tasks: tasks,
                  completed: completedTasks,
                  highPriority: highPriorityTasks,
                  overdue: overdueTasks,
                  contributors: contributorsCount,
                  mediumFont: mediumFont,
                ),
                pw.SizedBox(height: 30),
                _buildDetailedInsights(
                  inProgress: inProgressTasks,
                  pending: pendingTasks,
                  mediumFont: mediumFont,
                ),
                pw.SizedBox(height: 40),
                _buildCoolTasksSection(tasks, users, mediumFont, locale),
                if (requests.isNotEmpty) ...[
                  pw.SizedBox(height: 40),
                  _buildCoolRequestsSection(
                    requests,
                    users,
                    mediumFont,
                    locale,
                  ),
                ],
              ],
            ),
          ),
        ],
        footer: (context) => _buildCoolFooter(context, mediumFont),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'HUED_${project.title}_Report${shouldPrint ? "" : ".pdf"}',
      usePrinterSettings: shouldPrint,
    );
  }

  static pw.Widget _buildCoolHeader(
    pw.Font mediumFont,
    pw.ImageProvider logo,
    Locale locale,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(logo, height: 45),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              LangKeys.huedDigitalSolutions.tr(),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red700,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              DateFormat.yMMMMd(locale.toString()).format(DateTime.now()),
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
                font: mediumFont,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildCoolHero(
    ProjectEntity project,
    double rate,
    Map<String, UserEntity> users,
    pw.Font mediumFont,
    DateTime projectDeadline,
    Locale locale,
  ) {
    final creator = users[project.creatorId]?.name ?? 'System';
    final dateFormat = DateFormat.yMMMMd(locale.toString());

    return pw.Container(
      padding: const pw.EdgeInsets.all(25),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                LangKeys.projectOverview.tr(),
                style: pw.TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.2,
                  color: PdfColors.grey500,
                  font: mediumFont,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  _getProjectStatusLabel(project.status).toUpperCase(),
                  style: pw.TextStyle(
                    color: _getProjectStatusColor(project.status),
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            project.title,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      LangKeys.description.tr(),
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey500,
                        font: mediumFont,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      project.description,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    LangKeys.projectCompletion.tr().toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey500,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.Text(
                    '${(rate * 100).toInt()}%',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 25),
          pw.Divider(color: PdfColors.grey200, thickness: 0.5),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _coolSummaryItem(
                LangKeys.projectDirector.tr(),
                creator,
                mediumFont,
              ),
              _coolSummaryItem(
                LangKeys.deadlineLabel.tr(),
                dateFormat.format(projectDeadline),
                mediumFont,
              ),
              _coolSummaryItem(
                LangKeys.reportIdentifier.tr(),
                project.id.substring(0, 8).toUpperCase(),
                mediumFont,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _coolSummaryItem(
    String label,
    String value,
    pw.Font mediumFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 5,
            letterSpacing: 1,
            color: PdfColors.grey400,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8,
            font: mediumFont,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCoolStatsRow({
    required List<TaskEntity> tasks,
    required int completed,
    required int highPriority,
    required int overdue,
    required int contributors,
    required pw.Font mediumFont,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _coolStatBox(
          LangKeys.tasks.tr(),
          tasks.length.toString(),
          PdfColors.blue700,
          mediumFont,
        ),
        _coolStatBox(
          LangKeys.completed.tr(),
          completed.toString(),
          PdfColors.green700,
          mediumFont,
        ),
        _coolStatBox(
          LangKeys.priority.tr(),
          highPriority.toString(),
          PdfColors.orange700,
          mediumFont,
        ),
        _coolStatBox(
          LangKeys.overdue.tr(),
          overdue.toString(),
          PdfColors.red700,
          mediumFont,
        ),
      ],
    );
  }

  static pw.Widget _coolStatBox(
    String label,
    String value,
    PdfColor color,
    pw.Font mediumFont,
  ) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 6,
              color: PdfColors.grey500,
              font: mediumFont,
              letterSpacing: 0.5,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailedInsights({
    required int inProgress,
    required int pending,
    required pw.Font mediumFont,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  LangKeys.projectInsightsHeader.tr().toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  LangKeys.projectInsightsDescription.tr(
                    args: [inProgress.toString(), pending.toString()],
                  ),
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.blue900,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCoolTasksSection(
    List<TaskEntity> tasks,
    Map<String, UserEntity> users,
    pw.Font mediumFont,
    Locale locale,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          LangKeys.taskBreakdownHeader.tr().toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            letterSpacing: 1.2,
            font: mediumFont,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableHeader(LangKeys.taskTitle.tr(), mediumFont),
                _tableHeader(LangKeys.navUsers.tr(), mediumFont),
                _tableHeader(LangKeys.priority.tr(), mediumFont),
                _tableHeader(LangKeys.taskStatus.tr(), mediumFont),
                _tableHeader(LangKeys.timelineStatus.tr(), mediumFont),
              ],
            ),
            ...tasks.asMap().entries.map((entry) {
              final task = entry.value;
              final index = entry.key;
              final isEven = index % 2 == 0;

              String timelineStatus;
              PdfColor timelineColor = PdfColors.grey600;

              final diff = task.deadline.difference(
                task.completedAt ?? DateTime.now(),
              );
              final daysDiff = diff.inDays;

              if (task.status == TaskStatus.completed) {
                if (task.completedAt != null &&
                    task.completedAt!.isBefore(task.deadline)) {
                  timelineStatus = LangKeys.early.tr();
                  timelineColor = PdfColors.green700;
                } else {
                  timelineStatus = LangKeys.late.tr();
                  timelineColor = PdfColors.red700;
                }
              } else {
                if (task.deadline.isBefore(DateTime.now())) {
                  timelineStatus = LangKeys.overdue.tr();
                  timelineColor = PdfColors.red700;
                } else if (daysDiff == 0) {
                  timelineStatus = LangKeys.dueToday.tr();
                  timelineColor = PdfColors.blue700;
                } else {
                  timelineStatus = LangKeys.daysLeft.tr(
                    args: [daysDiff.abs().toString()],
                  );
                  timelineColor = PdfColors.green700;
                }
              }

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColors.grey50,
                  border: const pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
                  ),
                ),
                children: [
                  _coolTableCell(task.title),
                  _coolTableCell(
                    task.assignedWorkerIds
                        .map((id) => users[id]?.name ?? '-')
                        .join(', '),
                  ),
                  _coolTableCell(
                    _getPriorityLabel(task.priority).toUpperCase(),
                    font: mediumFont,
                    color: _getPriorityColor(task.priority),
                  ),
                  _coolTableCell(
                    _getTaskStatusLabel(task.status).toUpperCase(),
                    font: mediumFont,
                    color: _getStatusColor(task.status),
                  ),
                  _coolTableCell(
                    timelineStatus,
                    font: mediumFont,
                    color: timelineColor,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static PdfColor _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return PdfColors.grey600;
      case TaskPriority.medium:
        return PdfColors.blue700;
      case TaskPriority.high:
        return PdfColors.orange700;
      case TaskPriority.urgent:
        return PdfColors.red700;
    }
  }

  static pw.Widget _tableHeader(String text, pw.Font mediumFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6,
          color: PdfColors.grey400,
          font: mediumFont,
        ),
      ),
    );
  }

  static pw.Widget _coolTableCell(
    String text, {
    PdfColor? color,
    pw.Font? font,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 14),
      child: pw.Row(
        children: [
          if (color != null) ...[
            pw.Container(
              width: 5,
              height: 5,
              decoration: pw.BoxDecoration(
                color: color,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 8),
          ],
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey800,
                font: font,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCoolRequestsSection(
    List<RequestEntity> requests,
    Map<String, UserEntity> users,
    pw.Font mediumFont,
    Locale locale,
  ) {
    if (requests.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          LangKeys.approvalRequestsStatus.tr().toUpperCase(),
          style: pw.TextStyle(
            fontSize: 8,
            letterSpacing: 1.2,
            font: mediumFont,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableHeader(LangKeys.type.tr(), mediumFont),
                _tableHeader(LangKeys.requestedBy.tr(), mediumFont),
                _tableHeader(LangKeys.currentStatus.tr(), mediumFont),
                _tableHeader(LangKeys.createdLabel.tr(), mediumFont),
              ],
            ),
            ...requests.asMap().entries.map((entry) {
              final request = entry.value;
              final index = entry.key;
              final isEven = index % 2 == 0;
              final requestedBy = users[request.initiatorId]?.name ?? '-';

              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: isEven ? PdfColors.white : PdfColors.grey50,
                  border: const pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
                  ),
                ),
                children: [
                  _coolTableCell(
                    _getRequestTypeLabel(request.type).toUpperCase(),
                  ),
                  _coolTableCell(requestedBy),
                  _coolTableCell(
                    _getRequestStatusLabel(request.status).toUpperCase(),
                    font: mediumFont,
                    color: _getRequestStatusColor(request.status),
                  ),
                  _coolTableCell(
                    DateFormat.MMMd(
                      locale.toString(),
                    ).format(request.createdAt),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static PdfColor _getRequestStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return PdfColors.orange700;
      case RequestStatus.approved:
        return PdfColors.green700;
      case RequestStatus.rejected:
        return PdfColors.red700;
    }
  }

  static pw.Widget _buildCoolFooter(pw.Context context, pw.Font mediumFont) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 30),
      padding: const pw.EdgeInsets.only(top: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            LangKeys.huedDigitalSolutions.tr(),
            style: pw.TextStyle(
              color: PdfColors.grey400,
              fontSize: 6,
              letterSpacing: 1,
            ),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(color: PdfColors.grey400, fontSize: 7),
          ),
        ],
      ),
    );
  }

  static PdfColor _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return PdfColor.fromInt(0xFF2ECC71);
      case TaskStatus.inProgress:
        return PdfColor.fromInt(0xFF3498DB);
      case TaskStatus.cancelled:
        return PdfColor.fromInt(0xFFE74C3C);
      case TaskStatus.pending:
        return PdfColor.fromInt(0xFFF39C12);
    }
  }

  static PdfColor _getProjectStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.finished:
        return PdfColor.fromInt(0xFF2ECC71);
      case ProjectStatus.inProgress:
        return PdfColor.fromInt(0xFF3498DB);
      case ProjectStatus.canceled:
        return PdfColor.fromInt(0xFFE74C3C);
      case ProjectStatus.archived:
        return PdfColors.grey500;
    }
  }

  static String _getPriorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return LangKeys.low.tr();
      case TaskPriority.medium:
        return LangKeys.medium.tr();
      case TaskPriority.high:
        return LangKeys.high.tr();
      case TaskPriority.urgent:
        return LangKeys.urgent.tr();
    }
  }

  static String _getTaskStatusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return LangKeys.taskStatusPending.tr();
      case TaskStatus.inProgress:
        return LangKeys.taskStatusInProgress.tr();
      case TaskStatus.completed:
        return LangKeys.taskStatusCompleted.tr();
      case TaskStatus.cancelled:
        return LangKeys.taskStatusCancelled.tr();
    }
  }

  static String _getRequestTypeLabel(RequestType type) {
    switch (type) {
      case RequestType.taskStatus:
        return LangKeys.taskStatus.tr();
      case RequestType.projectStatus:
        return LangKeys.projectStatus.tr();
      case RequestType.taskDeadline:
        return LangKeys.taskDeadline.tr();
    }
  }

  static String _getRequestStatusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return LangKeys.pending.tr();
      case RequestStatus.approved:
        return LangKeys.approved.tr();
      case RequestStatus.rejected:
        return LangKeys.rejected.tr();
    }
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
