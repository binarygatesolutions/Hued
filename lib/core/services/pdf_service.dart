import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/entities.dart';

class PdfService {
  static Future<void> generateProjectReport({
    required ProjectEntity project,
    required List<TaskEntity> tasks,
    required Map<String, UserEntity> users,
    bool shouldPrint = false,
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.interRegular();
    final mediumFont = await PdfGoogleFonts.interMedium();
    final boldFont = await PdfGoogleFonts.interBold();

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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(45),
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, italic: font),
        build: (context) => [
          _buildCoolHeader(mediumFont, logoImage),
          _buildCoolHero(project, completionRate, users, mediumFont),
          _buildCoolStatsRow(
            tasks: tasks,
            completed: completedTasks,
            highPriority: highPriorityTasks,
            overdue: overdueTasks,
            contributors: contributorsCount,
            mediumFont: mediumFont,
          ),
          pw.SizedBox(height: 10),
          _buildDetailedInsights(
            inProgress: inProgressTasks,
            pending: pendingTasks,
            mediumFont: mediumFont,
          ),
          pw.SizedBox(height: 45),
          ..._buildCoolTasksSection(tasks, users, mediumFont),
        ],
        footer: (context) => _buildCoolFooter(context),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'HUED_${project.title}_Report${shouldPrint ? "" : ".pdf"}',
      usePrinterSettings: shouldPrint,
    );
  }

  static pw.Widget _buildCoolHeader(pw.Font mediumFont, pw.ImageProvider logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 25),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(logo, width: 70),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'PROJECT INSIGHTS',
                style: pw.TextStyle(
                  fontSize: 7,
                  letterSpacing: 2,
                  color: PdfColors.grey500,
                  font: mediumFont,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                style: pw.TextStyle(fontSize: 7, color: PdfColors.grey400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCoolHero(
    ProjectEntity project,
    double rate,
    Map<String, UserEntity> users,
    pw.Font mediumFont,
  ) {
    final creator = users[project.creatorId]?.name ?? 'System';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    project.title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: _getProjectStatusColor(project.status),
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        project.status.name.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 7,
                          letterSpacing: 1.2,
                          color: PdfColors.grey600,
                          font: mediumFont,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 60),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '${(rate * 100).toInt()}%',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: _getProjectStatusColor(project.status),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'COMPLETION',
                  style: pw.TextStyle(
                    fontSize: 6,
                    letterSpacing: 1,
                    color: PdfColors.grey400,
                    font: mediumFont,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          project.description,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey800,
            height: 1.6,
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 20),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
            ),
          ),
          child: pw.Row(
            children: [
              _coolSummaryItem('DIRECTOR', creator, mediumFont),
              pw.SizedBox(width: 60),
              _coolSummaryItem(
                'REPORT ID',
                '#HUED-${project.id.substring(0, 6).toUpperCase()}',
                mediumFont,
              ),
              pw.Spacer(),
              _coolSummaryItem(
                'GENERATED',
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                mediumFont,
              ),
            ],
          ),
        ),
      ],
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
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _coolStatBox('TOTAL TASKS', tasks.length.toString(), mediumFont),
          _statColorBox(
            'COMPLETED',
            completed.toString(),
            mediumFont,
            PdfColor.fromInt(0xFF2ECC71),
          ),
          _statColorBox(
            'HIGH PRIORITY',
            highPriority.toString(),
            mediumFont,
            PdfColor.fromInt(0xFFE74C3C),
          ),
          _statColorBox(
            'OVERDUE',
            overdue.toString(),
            mediumFont,
            PdfColor.fromInt(0xFFF39C12),
          ),
          _coolStatBox('CONTRIBUTORS', contributors.toString(), mediumFont),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailedInsights({
    required int inProgress,
    required int pending,
    required pw.Font mediumFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PROJECT INSIGHTS',
          style: pw.TextStyle(
            fontSize: 7,
            letterSpacing: 1.2,
            font: mediumFont,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          children: [
            _coolInsightCard(
              'In Progress',
              inProgress.toString(),
              PdfColor.fromInt(0xFF3498DB),
              mediumFont,
            ),
            pw.SizedBox(width: 20),
            _coolInsightCard(
              'Pending Review',
              pending.toString(),
              PdfColor.fromInt(0xFF9B59B6),
              mediumFont,
            ),
            pw.SizedBox(width: 20),
            _coolInsightCard(
              'Efficiency',
              'High',
              PdfColor.fromInt(0xFF2C3E50),
              mediumFont,
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _coolInsightCard(
    String label,
    String value,
    PdfColor color,
    pw.Font mediumFont,
  ) {
    return pw.Expanded(
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
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(width: 20, height: 1.5, color: color),
        ],
      ),
    );
  }

  static pw.Widget _coolStatBox(
    String label,
    String value,
    pw.Font mediumFont,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 6,
            letterSpacing: 1.5,
            color: PdfColors.grey400,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey900,
          ),
        ),
      ],
    );
  }

  static pw.Widget _statColorBox(
    String label,
    String value,
    pw.Font mediumFont,
    PdfColor color,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 6,
            letterSpacing: 1.5,
            color: PdfColors.grey400,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildCoolTasksSection(
    List<TaskEntity> tasks,
    Map<String, UserEntity> users,
    pw.Font mediumFont,
  ) {
    return [
      pw.Text(
        'TASK BREAKDOWN',
        style: pw.TextStyle(fontSize: 9, font: mediumFont, letterSpacing: 1),
      ),
      pw.SizedBox(height: 12),
      pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FixedColumnWidth(80),
          2: const pw.FixedColumnWidth(80),
          3: const pw.FlexColumnWidth(1.5),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
            ),
            children: [
              _coolTableHeader('TASK', mediumFont),
              _coolTableHeader('STATUS', mediumFont),
              _coolTableHeader('DEADLINE', mediumFont),
              _coolTableHeader('CREATOR', mediumFont),
            ],
          ),
          ...tasks.map((task) {
            final creator = users[task.creatorId]?.name ?? '-';
            return pw.TableRow(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey100, width: 0.3),
                ),
              ),
              children: [
                _coolTableCell(task.title),
                _coolTableCell(
                  task.status.name.toUpperCase(),
                  color: _getStatusColor(task.status),
                  font: mediumFont,
                ),
                _coolTableCell(DateFormat('MMM dd, yy').format(task.deadline)),
                _coolTableCell(creator),
              ],
            );
          }),
        ],
      ),
    ];
  }

  static pw.Widget _coolTableHeader(String text, pw.Font mediumFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 6,
          color: PdfColors.grey400,
          font: mediumFont,
          letterSpacing: 0.5,
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

  static pw.Widget _buildCoolFooter(pw.Context context) {
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
            'HUED DIGITAL SOLUTIONS',
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
    }
  }
}
