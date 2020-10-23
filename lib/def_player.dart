import 'dart:io';

import 'package:flt_chewie_player/flt_chewie_player.dart';
import 'package:flt_common_views/views/alter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:connectivity/connectivity.dart';

enum DefPlayerUrlType {
  file,
  network,
}

enum ZoomInWidgetTap {
  none,
  play,
  fullScreenPlay,
}

class DefPlayerController {
  final String url;
  final DefPlayerUrlType urlType;
  final bool looping;
  final bool autoPlay;
  final bool initMute;
  final Function(VideoPlayerValue value) onValueChange;
  final VoidCallback onInitialized;
  DefPlayerController.file(
    this.url, {
    this.looping = true,
    this.autoPlay = false,
    this.initMute = false,
    this.onValueChange,
    this.onInitialized,
  }) : urlType = DefPlayerUrlType.file;
  DefPlayerController.network(
    this.url, {
    this.looping = true,
    this.autoPlay = false,
    this.initMute = false,
    this.onValueChange,
    this.onInitialized,
  }) : urlType = DefPlayerUrlType.network;

  _DefPlayerState _circlePlayerState;

  dispose() {
    _circlePlayerState = null;
  }

  fullScreenPlay() {
    _circlePlayerState._fullScreenPlay();
  }

  play() {
    _circlePlayerState._play();
  }

  pause() {
    _circlePlayerState._pause();
  }

  setVolume(double volume) {
    _circlePlayerState._setVolume(volume);
  }
}

class DefPlayer extends StatefulWidget {
  final DefPlayerController controller;
  final double width;
  final double height;
  final Widget zoomInWidget;
  final bool zoominWidgetAnimation;
  final TextStyle errorTextStyle;
  final bool smallPlayBtn;
  final bool showPlayerWhenZoomIn;
  final bool blurBackground;
  final ZoomInWidgetTap zoomInWidgetTap;
  DefPlayer({
    Key key,
    this.controller,
    this.width,
    this.height,
    this.zoomInWidget,
    this.zoominWidgetAnimation = true,
    this.errorTextStyle,
    this.smallPlayBtn = false,
    this.showPlayerWhenZoomIn = false,
    this.blurBackground = false,
    this.zoomInWidgetTap = ZoomInWidgetTap.fullScreenPlay,
  })  : assert(controller != null, 'You must provide a DefPlayerController'),
        super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _DefPlayerState();
  }
}

class _DefPlayerState extends State<DefPlayer> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  bool _isSetChewieControllering = false;

  static ChewieController _zoomOutPlaychewieController;

  // 网络监听器
  var _subscription;
  ConnectivityResult _connectivityResult;
  static bool _allowMobilePlay = false;

  @override
  void initState() {
    super.initState();
    widget.controller._circlePlayerState = this;
    _setChewieController();
    _initConnectivity();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _videoPlayerController?.removeListener(_videoPlayerControllerListener);
    if (_zoomOutPlaychewieController != null &&
        _zoomOutPlaychewieController.videoPlayerController?.dataSource ==
            widget.controller.url) {
      return;
    }
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
  }

  @override
  void didUpdateWidget(DefPlayer oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller._circlePlayerState = this;
    }
    if (oldWidget.controller.url != widget.controller.url) {
      _chewieController = null;
      _videoPlayerController = null;
      _setChewieController();
    }
    super.didUpdateWidget(oldWidget);
  }

  _videoPlayerControllerListener() {
    if (widget.controller.onValueChange != null &&
        _videoPlayerController != null) {
      widget.controller.onValueChange(_videoPlayerController?.value);
    }
  }

  _initConnectivity() async {
    // 网络状态监听
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      _connectivityResult = result;
      if (_allowMobilePlay != true && result == ConnectivityResult.mobile) {
        if (_videoPlayerController.value.initialized) {
          _pause();
          _play();
        }
      } else if (result == ConnectivityResult.wifi) {}
    });

    _connectivityResult = await (Connectivity().checkConnectivity());
  }

  @override
  Widget build(BuildContext context) {
    return FltChewiePlayer(
      width: widget.width,
      height: widget.height,
      snapshot: true,
      blurBackground: widget.blurBackground,
      snapshotMode: SnapshotMode.scaleAspectFill,
      zoomInWidget: _buildZoomInWidget(),
      zoominWidgetAnimation: widget.zoominWidgetAnimation,
      controller: _chewieController,
      showPlayerWhenZoomIn: widget.showPlayerWhenZoomIn,
      onZoomChange: (value) async {
        if (value == FltChewiePlayerZoom.zoomIn) {
          if (widget.showPlayerWhenZoomIn == false) {
            _chewieController.seekTo(Duration(seconds: 0));
            _chewieController.play();
            Future.delayed(Duration(milliseconds: 100), (() {
              if (widget.showPlayerWhenZoomIn == false) {
                _chewieController.pause();
              }
              _zoomOutPlaychewieController = null;
            }));
          } else {
            Future.delayed(Duration(milliseconds: 100), (() {
              _zoomOutPlaychewieController = null;
            }));
          }
        } else {
          _zoomOutPlaychewieController = _chewieController;
        }
      },
    );
  }

  _buildZoomInWidget() {
    return GestureDetector(
      onTap: () {
        if (widget.zoomInWidgetTap == ZoomInWidgetTap.fullScreenPlay) {
          _fullScreenPlay();
        } else if (widget.zoomInWidgetTap == ZoomInWidgetTap.play) {
          _play();
        }
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
    if (_isSetChewieControllering == true) {
      return;
    }
    _isSetChewieControllering = true;
    if (_zoomOutPlaychewieController != null &&
        _zoomOutPlaychewieController.videoPlayerController?.dataSource
            .toLowerCase()
            .contains(widget.controller.url.toLowerCase())) {
      _videoPlayerController =
          _zoomOutPlaychewieController.videoPlayerController;
      _chewieController = _zoomOutPlaychewieController;
    } else {
      if (_videoPlayerController == null) {
        _videoPlayerController = await _getVideoPlayerController();
      }
      if (_videoPlayerController == null) {
        _isSetChewieControllering = false;
        return;
      }
      var aspectRatio = _videoPlayerController.value.aspectRatio;
      TextStyle errorTextStyle =
          widget.errorTextStyle ?? TextStyle(color: Color(0xFF333333));
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        aspectRatio: aspectRatio,
        autoPlay: widget.controller.autoPlay == true,
        looping: widget.controller.looping,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: errorTextStyle,
            ),
          );
        },
      );
      if (widget.controller.initMute == true) {
        _chewieController.setVolume(0);
      }
    }
    _videoPlayerController?.addListener(_videoPlayerControllerListener);
    setState(() {});
    _isSetChewieControllering = false;
  }

  Future<VideoPlayerController> _getVideoPlayerController() async {
    VideoPlayerController videoPlayerController;
    // 网络视频
    if (widget.controller.urlType == DefPlayerUrlType.network) {
      _connectivityResult = await (Connectivity().checkConnectivity());
      if (_allowMobilePlay != true &&
          _connectivityResult == ConnectivityResult.mobile) {
        return null;
      }
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
      if (widget.controller?.onInitialized != null) {
        widget.controller?.onInitialized();
      }
      if (mounted) {
        setState(() {});
      }
    });
    return videoPlayerController;
  }

  _fullScreenPlay() async {
    if (_allowMobilePlay != true &&
        _connectivityResult == ConnectivityResult.mobile) {
      showAlert(context, '正处于移动数据网络，是否继续播放？', '', '取消', '继续播放', rightOnTap: () {
        _allowMobilePlay = true;
        _startPlay();
        Future.delayed(Duration(milliseconds: 100), () {
          _chewieController.enterFullScreen();
        });
      });
    } else {
      _startPlay();
      Future.delayed(Duration(milliseconds: 100), () {
        _chewieController.enterFullScreen();
      });
    }
  }

  _play() async {
    if (_allowMobilePlay != true &&
        _connectivityResult == ConnectivityResult.mobile) {
      showAlert(context, '正处于移动数据网络，是否继续播放？', '', '取消', '继续播放', rightOnTap: () {
        _allowMobilePlay = true;
        _startPlay();
      });
    } else {
      _startPlay();
    }
  }

  _startPlay() {
    if (_videoPlayerController == null) {
      _setChewieController();
    }
    _chewieController?.play();
  }

  _pause() async {
    _chewieController?.pause();
  }

  _setVolume(double volume) async {
    _chewieController?.setVolume(volume);
  }
}
