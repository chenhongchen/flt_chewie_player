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
    Key key,
    this.width,
    this.height,
    this.controller,
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
  final double width;
  final double height;
  final ChewieController controller;
  final Widget zoomInWidget;
  final bool zoominWidgetAnimation;
  final bool showPlayerWhenZoomIn;
  final bool snapshot;
  final SnapshotMode snapshotMode;
  final bool blurBackground;
  final Function(FltChewiePlayerZoom zoom) onZoomChange;

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
  AnimationController _animationController;
  Animation<double> _animation;
  bool _hiddenZoomInWidget;

  static const MethodChannel _channel =
      const MethodChannel('flt_chewie_player');

  static zoomOut() async {
    await _channel.invokeMethod('zoomOut');
  }

  static zoomIn() async {
    await _channel.invokeMethod('zoomIn');
  }

  @override
  void initState() {
    super.initState();
    _init();
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 333));
    _animation = Tween(begin: 1.0, end: 0.0).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller.removeListener(_chewieControllerListener);
      widget.controller.videoPlayerController
          .removeListener(_videoPlayerControllerListener);
    }
    _animationController?.dispose();
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
      widget.controller.addListener(_chewieControllerListener);
      if (widget.controller == DefPlayerState.zoomOutPlaychewieController) {
        _isFullScreen = true;
      }
      _videoPlayerControllerInitialized =
          widget.controller?.videoPlayerController?.value?.initialized ?? false;
      if (_videoPlayerControllerInitialized == false &&
          widget.snapshot == true) {
        widget.controller?.videoPlayerController?.initialize();
      }
    }
  }

  void _chewieControllerListener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      if (widget.onZoomChange != null) {
        widget.onZoomChange(FltChewiePlayerZoom.zoomOut);
        zoomOut();
      }
    } else if (!widget.controller.isFullScreen && _isFullScreen) {
      _isFullScreen = false;
      if ((widget.snapshot || widget.zoomInWidget != null) &&
          widget.controller != null &&
          widget.showPlayerWhenZoomIn == false) {
        widget.controller.pause();
      }
      if (widget.onZoomChange != null) {
        widget.onZoomChange(FltChewiePlayerZoom.zoomIn);
        // zoomIn();
      }
    }
  }

  _videoPlayerControllerListener() {
    if (_videoPlayerControllerInitialized == false &&
        (widget.controller?.videoPlayerController?.value?.initialized ??
                false) ==
            true) {
      _videoPlayerControllerInitialized = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller != null &&
        _videoPlayerControllerAddListener == false) {
      widget.controller.videoPlayerController
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
                offstage: !(widget.showPlayerWhenZoomIn ?? false),
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
      child = widget.zoomInWidget;
    }
    return child;
  }

  _buildZoominWidget() {
    bool hiddenZoomInWidget = false;
    if (widget.showPlayerWhenZoomIn &&
        widget.controller?.videoPlayerController?.value?.initialized == true) {
      hiddenZoomInWidget = true;
    }

    if (_hiddenZoomInWidget != hiddenZoomInWidget) {
      _hiddenZoomInWidget = hiddenZoomInWidget;
      if (widget.zoominWidgetAnimation == true) {
        if (hiddenZoomInWidget == true) {
          _animationController.forward();
        } else {
          _animationController?.reverse();
        }
      }
    }

    return widget.zoominWidgetAnimation == true && (_animation?.value ?? 0) > 0
        ? Opacity(
            opacity: _animation?.value,
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
                child: Chewie(
                  controller: widget.controller,
                ),
              ),
            ),
          )
        : Container(
            color: Colors.black,
            child: Chewie(
              controller: widget.controller,
            ),
          );
  }

  _buildSnapshot() {
    var videoPlayerController = widget?.controller?.videoPlayerController;
    bool initialized = videoPlayerController?.value?.initialized ?? false;
    if (widget.snapshot != true || initialized == false) {
      return Container(
        color: Colors.black,
      );
    }

    double aspectRatio = videoPlayerController?.value?.aspectRatio ?? 1;
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
    if (widget.snapshotMode == SnapshotMode.scaleAspectFill &&
        (widget.width ?? 0) > 0 &&
        (widget.height ?? 0) > 0) {
      botWidget = Container();
      if (aspectRatio > widget.width / widget.height) {
        left = -widget.height * aspectRatio * 0.5;
        right = left;
      } else {
        top = -widget.width / aspectRatio * 0.5;
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
            child: videoPlayerController == null
                ? Container()
                : Container(
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
