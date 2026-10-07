import 'package:flutter/material.dart';

enum FuturisticSkeletonSection { viewer, videos, news }

/// Keeps the feed's layout visible while data is loading.
class FuturisticContentSkeleton extends StatefulWidget {
  const FuturisticContentSkeleton({super.key, required this.section});
  final FuturisticSkeletonSection section;
  @override
  State<FuturisticContentSkeleton> createState() =>
      _FuturisticContentSkeletonState();
}

class _FuturisticContentSkeletonState extends State<FuturisticContentSkeleton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400));
  late final _opacity = Tween<double>(begin: .45, end: .9)
      .chain(CurveTween(curve: Curves.easeInOutSine))
      .animate(_pulse);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _pulse.value = .5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _block({double? width, double? height, double radius = 12}) =>
      Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              color: const Color(0x26B6DDDB),
              borderRadius: BorderRadius.circular(radius)));

  Widget _video() => SizedBox(
      width: 220,
      height: 180,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _block(width: 220, height: 118, radius: 23),
        const SizedBox(height: 12),
        _block(width: 188, height: 12),
        const SizedBox(height: 8),
        _block(width: 132, height: 12),
      ]));

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: IgnorePointer(
          child: FadeTransition(
              opacity: _opacity,
              child: RepaintBoundary(
                  child: switch (widget.section) {
                FuturisticSkeletonSection.viewer => _block(radius: 24),
                FuturisticSkeletonSection.videos => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: List.generate(
                            3,
                            (_) => Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: _video())))),
                FuturisticSkeletonSection.news => Column(
                    children: List.generate(
                        3,
                        (_) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white12),
                                    borderRadius: BorderRadius.circular(24)),
                                child: Row(children: [
                                  _block(width: 28, height: 28, radius: 8),
                                  const SizedBox(width: 16),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        _block(
                                            width: double.infinity, height: 14),
                                        const SizedBox(height: 10),
                                        FractionallySizedBox(
                                            widthFactor: .55,
                                            child: _block(height: 12)),
                                      ])),
                                ]))))),
              }))));
}
