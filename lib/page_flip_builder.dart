import 'dart:math';

import 'package:flutter/material.dart';

class PageFlipBuilder extends StatefulWidget {
  const PageFlipBuilder({
    Key? key,
    required this.frontBuilder,
    required this.backBuilder,
  }) : super(key: key);
  final WidgetBuilder frontBuilder;
  final WidgetBuilder backBuilder;

  @override
  PageFlipBuilderState createState() => PageFlipBuilderState();
}

class PageFlipBuilderState extends State<PageFlipBuilder>
    with SingleTickerProviderStateMixin {
  bool _showFrontSide = true;

  late final AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      lowerBound: -1.0,
      upperBound: 1.0,
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _controller.value = 0.0;

    _controller.addStatusListener(_updateStatus);
    _controller.addListener(() {
      print(_controller.value);
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_updateStatus);
    _controller.dispose();
    super.dispose();
  }

  void _updateStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _controller.value = 0.0;
      setState(() => _showFrontSide = !_showFrontSide);
    }
  }

  void flip() {
    if (_showFrontSide) {
      _controller.forward();
    } else {
      _controller.forward();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    _controller.value += details.primaryDelta! / screenWidth;
  }

  void _handleDragEnd(DragEndDetails details) {
    // If the controller is currently animating or has already completed, do nothing
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed ||
        _controller.status == AnimationStatus.dismissed) return;

    // calculate the currentVelocity based on the drag velocity and screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final currentVelocity = details.velocity.pixelsPerSecond.dx / screenWidth;

    // if value and velocity are 0.0, the gesture was a tap so we return early
    if (_controller.value == 0.0 && currentVelocity == 0.0) {
      return;
    }

    const flingVelocity = 2.0;
    if (_controller.value > 0.5 ||
        _controller.value > 0.0 && currentVelocity > flingVelocity) {
      _controller.fling(velocity: flingVelocity);
    } else if (_controller.value < -0.5 ||
        _controller.value < 0.0 && currentVelocity < -flingVelocity) {
      _controller.fling(velocity: -flingVelocity);
    } else if (_controller.value > 0.0 ||
        _controller.value > 0.5 && currentVelocity < -flingVelocity) {
      // controller can't fling to 0.0 because the lowerBound is -1.0
      // so we decrement the value by 1.0 and toggle the state to get the same effect
      _controller.value -= 1.0;
      setState(() => _showFrontSide = !_showFrontSide);
      _controller.fling(velocity: -currentVelocity);
    } else if (_controller.value > -0.5 ||
        _controller.value < -0.5 && currentVelocity > flingVelocity) {
      // controller can't fling to 0.0 because the upperBound is 1.0
      // so we increment the value by 1.0 and toggle the state to get the same effect
      _controller.value += 1.0;
      setState(() => _showFrontSide = !_showFrontSide);
      _controller.fling(velocity: flingVelocity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedPageFlipBuilder(
        animation: _controller,
        showFrontSide: _showFrontSide,
        frontBuilder: widget.frontBuilder,
        backBuilder: widget.backBuilder,
      ),
    );
  }
}

class AnimatedPageFlipBuilder extends StatelessWidget {
  final Animation<double> animation;
  final bool showFrontSide;
  final WidgetBuilder frontBuilder;
  final WidgetBuilder backBuilder;
  const AnimatedPageFlipBuilder({
    Key? key,
    required this.animation,
    required this.showFrontSide,
    required this.frontBuilder,
    required this.backBuilder,
  }) : super(key: key);

  bool get _isAnimationFirstHalf => animation.value.abs() < 0.5;

  double _getTilt() {
    var tilt = (animation.value - 0.5).abs() - 0.5;
    if (animation.value < -0.5) {
      tilt = 1.0 + animation.value;
    }
    return tilt * (_isAnimationFirstHalf ? -0.003 : 0.003);
  }

  double _rotationAngle() {
    final rotationValue = animation.value * pi;
    if (animation.value > 0.5) {
      return pi - rotationValue; // input from 0.5 to 1.0
    } else if (animation.value > -0.5) {
      return rotationValue; // input from -0.5 to 0.5
    } else {
      return -pi - rotationValue; // input from -1.0 to -0.5
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final child = _isAnimationFirstHalf ^ showFrontSide
            ? backBuilder(context)
            : frontBuilder(context);

        return Transform(
          transform: Matrix4.rotationY(_rotationAngle())
            ..setEntry(3, 0, _getTilt()),
          child: child,
          alignment: Alignment.center,
        );
      },
    );
  }
}
