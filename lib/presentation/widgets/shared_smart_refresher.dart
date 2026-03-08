import 'package:flutter/material.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class SharedSmartRefresher extends StatelessWidget {
  final RefreshController controller;
  final Future<void> Function() onRefresh;
  final Future<void> Function()? onLoading;
  final bool enablePullUp;
  final Widget child;

  const SharedSmartRefresher({
    super.key,
    required this.controller,
    required this.onRefresh,
    this.onLoading,
    this.enablePullUp = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: controller,
      enablePullUp: enablePullUp,
      onRefresh: onRefresh,
      onLoading: onLoading,
      header: ClassicHeader(
        refreshingIcon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        spacing: 16,
        height: 60,
        releaseText: '',
        refreshingText: '',
        completeText: '',
        idleText: '',
      ),
      footer: CustomFooter(
        builder: (BuildContext context, LoadStatus? mode) {
          Widget body;
          if (mode == LoadStatus.idle) {
            body = const Text("");
          } else if (mode == LoadStatus.loading) {
            body = const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          } else if (mode == LoadStatus.failed) {
            body = const Text("Load Failed! Click retry!");
          } else if (mode == LoadStatus.canLoading) {
            body = const Text("Release to load more");
          } else {
            body = SizedBox();
          }
          return SizedBox(height: 55.0, child: Center(child: body));
        },
      ),
      child: child,
    );
  }
}
