export 'package:video_player/video_player.dart';
export 'package:chewie/chewie.dart';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
    this.showPlayerWhenZoomIn = false,
    this.snapshot = false,
    this.snapshotMode = SnapshotMode.scaleAspectFit,
    this.onZoomChange,
  })  : assert(controller != null || zoomInWidget != null,
            'You must provide a chewie controller or zoomInWidget'),
        super(key: key);

  /// The [ChewieController]
  final double width;
  final double height;
  final ChewieController controller;
  final Widget zoomInWidget;
  final bool snapshot;
  final SnapshotMode snapshotMode;
  final bool showPlayerWhenZoomIn;
  final Function(FltChewiePlayerZoom zoom) onZoomChange;

  @override
  _FltChewiePlayerState createState() {
    return _FltChewiePlayerState();
  }
}

class _FltChewiePlayerState extends State<FltChewiePlayer> {
  bool _isFullScreen = false;
  bool _videoPlayerControllerAddListener = false;
  bool _videoPlayerControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller.removeListener(_chewieControllerListener);
      widget.controller.videoPlayerController
          .removeListener(_videoPlayerControllerListener);
    }
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
              child: Container(
                child: Center(
                  child: widget.zoomInWidget,
                ),
              ),
            ),
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

  _buildChewie() {
    return Chewie(
      controller: widget.controller,
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
