export 'package:video_player/video_player.dart';
export 'package:chewie/chewie.dart';
import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum FltChewiePlayerZoom {
  zoomIn,
  zoomOut,
}

class FltChewiePlayer extends StatefulWidget {
  FltChewiePlayer({
    Key key,
    this.controller,
    this.zoomInWidget,
    this.showPlayerWhenZoomIn = false,
    this.onZoomChange,
  })  : assert(controller != null || zoomInWidget != null,
            'You must provide a chewie controller or zoomInWidget'),
        super(key: key);

  /// The [ChewieController]
  final ChewieController controller;
  final Widget zoomInWidget;
  final bool showPlayerWhenZoomIn;
  final Function(FltChewiePlayerZoom zoom) onZoomChange;

  @override
  _FltChewiePlayerState createState() {
    return _FltChewiePlayerState();
  }
}

class _FltChewiePlayerState extends State<FltChewiePlayer> {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      widget.controller.addListener(listener);
    }
  }

  @override
  void dispose() {
    if (widget.controller != null) {
      widget.controller.removeListener(listener);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(FltChewiePlayer oldWidget) {
    if (oldWidget.controller != widget.controller &&
        widget.controller != null) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  void listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      if (widget.onZoomChange != null) {
        widget.onZoomChange(FltChewiePlayerZoom.zoomOut);
      }
    } else if (!widget.controller.isFullScreen && _isFullScreen) {
      _isFullScreen = false;
      if (widget.zoomInWidget != null &&
          widget.controller != null &&
          widget.showPlayerWhenZoomIn == false) {
        widget.controller.pause();
      }
      if (widget.onZoomChange != null) {
        widget.onZoomChange(FltChewiePlayerZoom.zoomIn);
      }
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.zoomInWidget != null && widget.controller != null) {
      return Stack(
        children: <Widget>[
          widget.zoomInWidget,
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
    } else if (widget.zoomInWidget != null) {
      return widget.zoomInWidget;
    } else {
      return _buildChewie();
    }
  }

  _buildChewie() {
    return Container(
      color: Colors.black,
      child: Chewie(
        controller: widget.controller,
      ),
    );
  }
}
