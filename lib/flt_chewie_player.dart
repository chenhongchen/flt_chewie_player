import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
export 'package:video_player/video_player.dart';
export 'package:flt_chewie_player/chewie.dart';

import 'package:flt_chewie_player/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flt_chewie_player/def_player.dart';

enum FltChewiePlayerZoom {
  zoomIn,
  zoomOut,
}

enum SnapshotMode {
  scaleAspectFit,
  scaleAspectFill,
}

class FltChewiePlayer extends StatefulWidget {
  FltChewiePlayer({
    Key? key,
    this.controller,
    this.width,
    this.height,
    this.zoomInWidget,
    this.zoominWidgetAnimation = true,
    this.showPlayerWhenZoomIn = false,
    this.snapshot = false,
    this.snapshotMode = SnapshotMode.scaleAspectFit,
    this.blurBackground = false,
    this.onZoomChange,
  })  : assert(controller != null || zoomInWidget != null,
            'You must provide a chewie controller or zoomInWidget'),
        super(key: key);

  /// The [ChewieController]
  final double? width;
  final double? height;
  final ChewieController? controller;
  final Widget? zoomInWidget;
  final bool zoominWidgetAnimation;
  final bool showPlayerWhenZoomIn;
  final bool snapshot;
  final SnapshotMode snapshotMode;
  final bool blurBackground;
  final Function(FltChewiePlayerZoom zoom)? onZoomChange;

  @override
  FltChewiePlayerState createState() {
    return FltChewiePlayerState();
  }
}

class FltChewiePlayerState extends State<FltChewiePlayer>
    with SingleTickerProviderStateMixin {
  bool _isFullScreen = false;
  bool _videoPlayerControllerAddListener = false;
  bool _videoPlayerControllerInitialized = false;

  //动画控制器
  late AnimationController _animationController =
      AnimationController(vsync: this, duration: Duration(milliseconds: 333));
  late Animation<double> _animation =
      Tween(begin: 1.0, end: 0.0).animate(_animationController)
        ..addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
  bool? _hiddenZoomInWidget;

  static const MethodChannel _channel =
      const MethodChannel('flt_chewie_player');

  static Future<dynamic> zoomOut({bool sendZoomNotice = true}) async {
    return await _channel
        .invokeMethod('zoomOut', {'sendZoomNotice': sendZoomNotice});
  }

  static Future<dynamic> zoomIn({bool sendZoomNotice = true}) async {
    return await _channel
        .invokeMethod('zoomIn', {'sendZoomNotice': sendZoomNotice});
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller?.removeListener(_chewieControllerListener);
      widget.controller?.videoPlayerController
          .removeListener(_videoPlayerControllerListener);
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FltChewiePlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _init();
    }
    super.didUpdateWidget(oldWidget);
  }

  _init() {
    if (widget.controller != null) {
      widget.controller?.addListener(_chewieControllerListener);
      if (widget.controller == DefPlayerState.zoomOutPlaychewieController) {
        _isFullScreen = true;
      }
      _videoPlayerControllerInitialized =
          widget.controller!.videoPlayerController.value.isInitialized;
      if (_videoPlayerControllerInitialized == false &&
          widget.snapshot == true) {
        widget.controller!.videoPlayerController.initialize();
      }
    }
  }

  void _chewieControllerListener() async {
    if (widget.controller?.isFullScreen == true && !_isFullScreen) {
      _isFullScreen = true;
      if (widget.onZoomChange != null) {
        widget.onZoomChange!(FltChewiePlayerZoom.zoomOut);
        zoomOut(sendZoomNotice: widget.controller?.sendZoomNotice ?? true);
      }
    } else if (widget.controller?.isFullScreen == false && _isFullScreen) {
      _isFullScreen = false;
      if ((widget.snapshot || widget.zoomInWidget != null) &&
          widget.controller != null &&
          widget.showPlayerWhenZoomIn == false) {
        widget.controller?.pause();
      }
      if (widget.onZoomChange != null) {
        Future.delayed(Duration(milliseconds: 500), () {
          widget.onZoomChange!(FltChewiePlayerZoom.zoomIn);
        });
        // zoomIn();
      }
    }
  }

  _videoPlayerControllerListener() {
    if (_videoPlayerControllerInitialized == false &&
        widget.controller?.videoPlayerController.value.isInitialized == true) {
      _videoPlayerControllerInitialized = true;
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller != null &&
        _videoPlayerControllerAddListener == false) {
      widget.controller!.videoPlayerController
          .addListener(_videoPlayerControllerListener);
      _videoPlayerControllerAddListener = true;
    }
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.black,
      child: _buildContent(),
    );
  }

  _buildContent() {
    Widget child = Container();
    if (widget.controller != null) {
      if (widget.snapshot || widget.zoomInWidget != null) {
        child = Stack(
          children: <Widget>[
            _buildSnapshot(),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
              child: Offstage(
                offstage: !(widget.showPlayerWhenZoomIn),
                child: _buildChewie(),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
              child: _buildZoominWidget(),
            ),
          ],
        );
      } else {
        child = _buildChewie();
      }
    } else if (widget.zoomInWidget != null) {
      child = widget.zoomInWidget!;
    }
    return child;
  }

  _buildZoominWidget() {
    bool hiddenZoomInWidget = false;
    if (widget.showPlayerWhenZoomIn &&
        widget.controller?.videoPlayerController.value.isInitialized == true) {
      hiddenZoomInWidget = true;
    }

    if (_hiddenZoomInWidget != hiddenZoomInWidget) {
      _hiddenZoomInWidget = hiddenZoomInWidget;
      if (widget.zoominWidgetAnimation == true) {
        if (hiddenZoomInWidget == true) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    }

    return widget.zoominWidgetAnimation == true && _animation.value > 0
        ? Opacity(
            opacity: _animation.value,
            child: Container(
              child: Center(
                child: widget.zoomInWidget,
              ),
            ))
        : Offstage(
            offstage: hiddenZoomInWidget,
            child: Container(
              child: Center(
                child: widget.zoomInWidget,
              ),
            ),
          );
  }

  _buildChewie() {
    if (widget.controller == null) {
      return Container();
    }
    return widget.blurBackground == true
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 30,
                sigmaY: 30,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: Hero(
                  tag: widget.controller!.hero,
                  child: Chewie(
                    controller: widget.controller!,
                  ),
                ),
              ),
            ),
          )
        : Container(
            color: Colors.black,
            child: Hero(
              tag: widget.controller!.hero,
              child: Chewie(
                controller: widget.controller!,
              ),
            ),
          );
  }

  _buildSnapshot() {
    var videoPlayerController = widget.controller!.videoPlayerController;
    bool initialized = videoPlayerController.value.isInitialized;
    if (widget.snapshot != true || initialized == false) {
      return Container(
        color: Colors.black,
      );
    }

    double aspectRatio = videoPlayerController.value.aspectRatio;
    Widget botWidget = Container(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          color: Colors.black,
        ),
      ),
    );
    double left = 0;
    double right = 0;
    double bottom = 0;
    double top = 0;
    double w = widget.width ?? 0;
    double h = widget.height ?? 0;
    if (widget.snapshotMode == SnapshotMode.scaleAspectFill && w > 0 && h > 0) {
      botWidget = Container();
      if (aspectRatio > w / h) {
        left = -h * aspectRatio * 0.5;
        right = left;
      } else {
        top = -w / aspectRatio * 0.5;
        bottom = top;
      }
    }
    return Center(
      child: Stack(
        children: <Widget>[
          botWidget,
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: Container(
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(videoPlayerController),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
