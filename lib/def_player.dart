import 'dart:io';

import 'package:flt_chewie_player/flt_chewie_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

enum DefPlayerUrlType {
  asset,
  network,
}

class DefPlayerController {
  final String url;
  final DefPlayerUrlType urlType;
  DefPlayerController.asset(this.url) : urlType = DefPlayerUrlType.asset;
  DefPlayerController.network(this.url) : urlType = DefPlayerUrlType.network;

  _DefPlayerState _circlePlayerState;

  dispose() {
    _circlePlayerState = null;
  }

  play() {
    _circlePlayerState._startPlay();
  }
}

class DefPlayer extends StatefulWidget {
  final DefPlayerController controller;
  final double width;
  final double height;
  final Widget zoomInWidget;
  final TextStyle errorTextStyle;
  final bool smallPlayBtn;
  DefPlayer({
    Key key,
    this.controller,
    this.width,
    this.height,
    this.zoomInWidget,
    this.errorTextStyle,
    this.smallPlayBtn = false,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _DefPlayerState();
  }
}

class _DefPlayerState extends State<DefPlayer> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    widget.controller._circlePlayerState = this;
    _setChewieController();
  }

  @override
  void dispose() {
    super.dispose();
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
  }

  @override
  void didUpdateWidget(DefPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller._circlePlayerState = this;
      _chewieController = null;
      _videoPlayerController = null;
      _setChewieController();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return FltChewiePlayer(
      width: widget.width,
      height: widget.height,
      snapshot: true,
      snapshotMode: SnapshotMode.scaleAspectFill,
      zoomInWidget: _buildZoomInWidget(),
      controller: _chewieController,
      showPlayerWhenZoomIn: false,
      onZoomChange: (value) async {
        if (value == FltChewiePlayerZoom.zoomIn) {
          _chewieController.seekTo(Duration(seconds: 0));
          _chewieController.play();
          Future.delayed(Duration(milliseconds: 100), (() {
            _chewieController.pause();
          }));
        }
      },
    );
  }

  _buildZoomInWidget() {
    return GestureDetector(
      onTap: () {
        _startPlay();
      },
      child: widget.zoomInWidget ??
          Stack(
            children: <Widget>[
              Container(
                color: Colors.transparent,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: Container(
                  child: Center(
                    child: Container(
                      child: Image.asset(
                        widget.smallPlayBtn
                            ? 'images/small_play.png'
                            : 'images/play.png',
                        package: 'flt_chewie_player',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  _setChewieController() async {
    if (_videoPlayerController == null) {
      _videoPlayerController = await _getVideoPlayerController();
    }
    var aspectRatio = _videoPlayerController.value.aspectRatio;
    TextStyle errorTextStyle =
        widget.errorTextStyle ?? TextStyle(color: Color(0xFF333333));
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: aspectRatio,
      autoPlay: false,
      looping: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: errorTextStyle,
          ),
        );
      },
    );
    setState(() {});
  }

  Future<VideoPlayerController> _getVideoPlayerController() async {
    VideoPlayerController videoPlayerController;
    // 网络视频
    if (widget.controller.urlType == DefPlayerUrlType.network) {
      videoPlayerController = VideoPlayerController.network(
        widget.controller.url,
      );
    }
    // 本地资源视频
    else {
      File file = File(widget.controller.url);
      videoPlayerController = VideoPlayerController.file(file);
    }

    await videoPlayerController.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
    return videoPlayerController;
  }

  _startPlay() async {
    if (_chewieController == null) {
      await _setChewieController();
    }
    _chewieController.play();
    Future.delayed(Duration(milliseconds: 100), () {
      _chewieController.enterFullScreen();
    });
  }
}
