import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Autoplay pertence a este State e para antes da desativação da árvore.
class LifecycleCarousel extends StatefulWidget {
  final CarouselSliderController controller;
  final CarouselOptions options;
  final List<Widget> items;
  const LifecycleCarousel(
      {super.key,
      required this.controller,
      required this.options,
      required this.items});
  @override
  State<LifecycleCarousel> createState() => _LifecycleCarouselState();
}

class _LifecycleCarouselState extends State<LifecycleCarousel> {
  Timer? _timer;
  ModalRoute<dynamic>? _route;
  bool _active = true;
  bool _moving = false;
  bool _touching = false;

  void _restart() {
    _timer?.cancel();
    _timer = null;
    if (!_active || !widget.options.autoPlay || widget.items.length < 2) return;
    _timer = Timer.periodic(widget.options.autoPlayInterval, (_) async {
      if (!mounted ||
          !_active ||
          _moving ||
          _touching ||
          _route?.isCurrent == false ||
          !widget.controller.ready) {
        return;
      }
      _moving = true;
      try {
        await widget.controller.nextPage(
            duration: widget.options.autoPlayAnimationDuration,
            curve: widget.options.autoPlayCurve);
      } finally {
        _moving = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    _restart();
  }

  @override
  void didUpdateWidget(LifecycleCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.autoPlay != widget.options.autoPlay ||
        oldWidget.options.autoPlayInterval != widget.options.autoPlayInterval ||
        oldWidget.items.length != widget.items.length ||
        oldWidget.controller != widget.controller) {
      _restart();
    }
  }

  @override
  void deactivate() {
    _active = false;
    _timer?.cancel();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _touching = true,
        onPointerUp: (_) => _touching = false,
        onPointerCancel: (_) => _touching = false,
        child: CarouselSlider(
          carouselController: widget.controller,
          options: widget.options.copyWith(autoPlay: false),
          items: widget.items,
        ),
      );
}
