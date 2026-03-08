import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hued/domain/entities/entities.dart';
import 'package:hued/presentation/widgets/custom_loading.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/theme_ext.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_state.dart';
import '../widgets/shared_app_bar.dart';
import '../widgets/shared_app_logo.dart';
import '../widgets/glass_container.dart';
import '../widgets/shared_smart_refresher.dart';
import '../widgets/premium_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int completed = 0;
  int inProgress = 0;
  int cancelled = 0;

  int admins = 0;
  int superivsors = 0;
  int managers = 0;
  int clients = 0;

  DateTimeRange? _selectedDateRange;

  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh(UserEntity user) async {
    await getStatistics();
    _refreshController.refreshCompleted();
  }

  @override
  void initState() {
    super.initState();
    getStatistics();
  }

  Future<void> getStatistics() async {
    final projectsCollection = FirebaseFirestore.instance.collection(
      'projects',
    );
    final usersCollection = FirebaseFirestore.instance.collection('users');

    Query projectsQuery = projectsCollection;
    if (_selectedDateRange != null) {
      projectsQuery = projectsQuery
          .where('createdAt', isGreaterThanOrEqualTo: _selectedDateRange!.start)
          .where('createdAt', isLessThanOrEqualTo: _selectedDateRange!.end);
    }

    final results = await Future.wait([
      projectsQuery
          .where('status', isEqualTo: ProjectStatus.finished.name)
          .count()
          .get(),
      projectsQuery
          .where('status', isEqualTo: ProjectStatus.inProgress.name)
          .count()
          .get(),
      projectsQuery
          .where('status', isEqualTo: ProjectStatus.canceled.name)
          .count()
          .get(),
      usersCollection
          .where('role', isEqualTo: UserRole.admin.name)
          .count()
          .get(),
      usersCollection
          .where('role', isEqualTo: UserRole.supervisor.name)
          .count()
          .get(),
      usersCollection
          .where('role', isEqualTo: UserRole.projectManager.name)
          .count()
          .get(),
      usersCollection
          .where('role', isEqualTo: UserRole.client.name)
          .count()
          .get(),
    ]);

    completed = results[0].count ?? 0;
    inProgress = results[1].count ?? 0;
    cancelled = results[2].count ?? 0;

    admins = results[3].count ?? 0;
    superivsors = results[4].count ?? 0;
    managers = results[5].count ?? 0;
    clients = results[6].count ?? 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return Scaffold(
            backgroundColor: context.background,
            appBar: SharedAppBar(
              title: 'Analytics',
              showBackButton: false,
              leading: const Padding(
                padding: EdgeInsets.all(12.0),
                child: SharedAppLogo(height: 30),
              ),
            ),
            body: _buildScaffold(context, state),
          );
        }
        return const Scaffold(body: CustomLoading());
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Authenticated state) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(color: context.background),
      child: SharedSmartRefresher(
        controller: _refreshController,
        onRefresh: () async {
          final authState = context.read<AuthBloc>().state;
          if (authState is Authenticated) {
            await _onRefresh(authState.user);
          } else {
            _refreshController.refreshCompleted();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 40,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateFilter(context),
                    const SizedBox(height: 24),
                    _buildPerformanceSection(context, isMobile),
                    const SizedBox(height: 32),
                    _buildChartsSection(context, isMobile),
                    const SizedBox(height: 32),
                    _buildInsightsSection(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Core Metrics'),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildMetricCard(
              context,
              'Completed',
              '$completed',
              context.mintGreen,
              Ionicons.checkmark_done_circle_outline,
              0,
            ),
            _buildMetricCard(
              context,
              'In Progress',
              '$inProgress',
              context.primary,
              Ionicons.sync_circle_outline,
              1,
            ),

            _buildMetricCard(
              context,
              'Cancelled',
              '$cancelled',
              context.error,
              Ionicons.close_circle_outline,
              3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightsSection(BuildContext context) {
    final totalProjectsCount = completed + inProgress + cancelled;
    final projectCompletion = totalProjectsCount > 0
        ? ((completed / totalProjectsCount) * 100).toInt()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Core Insights'),
        const SizedBox(height: 7),
        GlassContainer(
          borderRadius: 32,
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              _buildInsightRow(
                context,
                'Project Completion',
                '$projectCompletion%',
                context.primary,
              ),

              _buildInsightRow(
                context,
                'Active Projects',
                '${totalProjectsCount - completed - cancelled}',
                context.purple,
              ),
              SizedBox(height: 5),
              _buildDivider(context),
              SizedBox(height: 5),
              _buildInsightRow(context, 'Admins', '$admins', context.primary),
              _buildInsightRow(
                context,
                'Supervisors',
                '$superivsors',
                context.primary,
              ),
              _buildInsightRow(
                context,
                'Project Managers',
                '$managers',
                context.primary,
              ),
              _buildInsightRow(context, 'Clients', '$clients', context.primary),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          color: context.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
    int index,
  ) {
    return GlassContainer(
          borderRadius: 32,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: context.onSurface,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: context.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 100).ms)
        .scale(curve: Curves.easeOutBack, begin: const Offset(0.9, 0.9));
  }

  Widget _buildDateFilter(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: context.colorScheme.copyWith(
                  primary: context.primary,
                  onPrimary: context.surface,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _selectedDateRange = picked);
          getStatistics();
        }
      },
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Ionicons.calendar_outline, size: 18, color: context.primary),
            const SizedBox(width: 12),
            Text(
              _selectedDateRange == null
                  ? 'All Time'
                  : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Ionicons.chevron_down,
              size: 14,
              color: context.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildChartsSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Visual Analytics'),
        const SizedBox(height: 16),
        if (isMobile) ...[
          _buildStatusPieChart(context),
          const SizedBox(height: 24),
          _buildUserRolesBarChart(context),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStatusPieChart(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildUserRolesBarChart(context)),
            ],
          ),
      ],
    );
  }

  Widget _buildStatusPieChart(BuildContext context) {
    final total = completed + inProgress + cancelled;
    return PremiumCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Project Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: total == 0
                ? Center(
                    child: Text(
                      'No data',
                      style: TextStyle(
                        color: context.onSurface.withOpacity(0.3),
                      ),
                    ),
                  )
                : PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: completed.toDouble(),
                          color: context.mintGreen,
                          title: '$completed',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: inProgress.toDouble(),
                          color: context.primary,
                          title: '$inProgress',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: cancelled.toDouble(),
                          color: context.error,
                          title: '$cancelled',
                          radius: 50,
                          titleStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          _buildChartLegend(context),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildChartLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _legendItem(context, 'Done', context.mintGreen),
        _legendItem(context, 'Active', context.primary),
        _legendItem(context, 'Canceled', context.error),
      ],
    );
  }

  Widget _legendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRolesBarChart(BuildContext context) {
    final maxVal =
        [
          admins,
          superivsors,
          managers,
          clients,
        ].reduce((a, b) => a > b ? a : b).toDouble() +
        1;

    return PremiumCard(
      borderRadius: 32,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'User Roles Distribution',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        );
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Adm';
                            break;
                          case 1:
                            text = 'Sup';
                            break;
                          case 2:
                            text = 'PM';
                            break;
                          case 3:
                            text = 'Cli';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(text, style: style),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(0, admins.toDouble(), context.primary),
                  _makeBarGroup(1, superivsors.toDouble(), context.purple),
                  _makeBarGroup(2, managers.toDouble(), Colors.indigo),
                  _makeBarGroup(3, clients.toDouble(), context.mintGreen),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 0,
            color: color.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, color: context.onSurface.withOpacity(0.03));
  }
}
