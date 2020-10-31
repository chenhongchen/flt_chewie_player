import 'dart:async';
import 'dart:io';

import 'package:flt_chewie_player/flt_chewie_player.dart';
import 'package:flt_common_views/views/alter.dart';
import 'package:flt_hc_hub/hud/hc_activity_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flt_chewie_player/chewie.dart';
import 'package:connectivity/connectivity.dart';
import 'package:event_bus/event_bus.dart';

var defPlayerEventBus = EventBus();

class DefPlayerEventBusEvent {
  bool stopAllDefPlayer;
  DefPlayerEventBusEvent({this.stopAllDefPlayer});
}

enum DefPlayerUrlType {
  file,
  network,
}

enum ZoomInWidgetTap {
  none,
  play,
  fullScreenPlay,
}

enum InitializeStatus {
  start,
  complete,
}

class DefPlayerController {
  final String url;
  final DefPlayerUrlType urlType;
  final bool looping;
  final bool autoPlay;
  final bool initMute;
  final Function(VideoPlayerValue value) onValueChanged;
  final Function(InitializeStatus status) onInitializeChanged;
  DefPlayerController.file(
    this.url, {
    this.looping = true,
    this.autoPlay = false,
    this.initMute = false,
    this.onValueChanged,
    this.onInitializeChanged,
  }) : urlType = DefPlayerUrlType.file;
  DefPlayerController.network(
    this.url, {
    this.looping = true,
    this.autoPlay = false,
    this.initMute = false,
    this.onValueChanged,
    this.onInitializeChanged,
  }) : urlType = DefPlayerUrlType.network;

  DefPlayerState _defPlayerState;

  dispose() {
    _defPlayerState = null;
  }

  fullScreenPlay() {
    _defPlayerState?._fullScreenPlay();
  }

  play() {
    _defPlayerState?._play();
  }

  pause() {
    _defPlayerState?._pause();
  }

  setVolume(double volume) {
    _defPlayerState?._setVolume(volume);
  }
}

class DefPlayer extends StatefulWidget {
  final DefPlayerController controller;
  final double width;
  final double height;
  final Widget zoomInWidget;
  final bool zoominWidgetAnimation;
  final Widget playerIcon;
  final TextStyle errorTextStyle;
  final bool smallPlayBtn;
  final bool showPlayerWhenZoomIn;
  final bool blurBackground;
  final ZoomInWidgetTap zoomInWidgetTap;
  final Color loadColor;
  final bool snapshot;
  DefPlayer({
    Key key,
    this.controller,
    this.width,
    this.height,
    this.zoomInWidget,
    this.zoominWidgetAnimation = true,
    this.playerIcon,
    this.errorTextStyle,
    this.smallPlayBtn = false,
    this.showPlayerWhenZoomIn = false,
    this.blurBackground = false,
    this.zoomInWidgetTap = ZoomInWidgetTap.fullScreenPlay,
    this.loadColor = CupertinoColors.inactiveGray,
    this.snapshot = true,
  })  : assert(controller != null, 'You must provide a DefPlayerController'),
        super(key: key);
  @override
  State<StatefulWidget> createState() {
    return DefPlayerState();
  }
}

class DefPlayerState extends State<DefPlayer> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  bool _isSetChewieControllering = false;

  static ChewieController zoomOutPlaychewieController;
  static DefPlayerState zoomOutDefPlayer;

  // 网络监听器
  var _subscription;
  ConnectivityResult _connectivityResult;
  static bool _allowMobilePlay = false;

  InitializeStatus _initializeStatus;

  static String _needFullScreenPlayUrl;
  static set needFullScreenPlayUrl(newValue) {
    _needFullScreenPlayUrl = newValue;
    defPlayerEventBus.fire(DefPlayerEventBusEvent());
  }

  @override
  void initState() {
    super.initState();
    widget.controller._defPlayerState = this;
    if (widget.snapshot == true ||
        (widget.controller.autoPlay == true &&
            widget.showPlayerWhenZoomIn == true) ||
        (zoomOutPlaychewieController != null &&
            zoomOutPlaychewieController.videoPlayerController?.dataSource
                .toLowerCase()
                .contains(widget.controller.url.toLowerCase()))) {
      _setChewieController();
    }
    _initConnectivity();

    defPlayerEventBus
        .on<DefPlayerEventBusEvent>()
        .listen((DefPlayerEventBusEvent data) {
      if (data.stopAllDefPlayer == true) {
        _delayDisposeController();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _videoPlayerController?.removeListener(_videoPlayerControllerListener);
    if (zoomOutPlaychewieController != null &&
        zoomOutPlaychewieController.videoPlayerController?.dataSource
            .toLowerCase()
            .contains(widget.controller.url.toLowerCase())) {
      zoomOutDefPlayer = null;
      if (zoomOutPlaychewieController.isFullScreen == true) {
        return;
      }
      zoomOutPlaychewieController = null;
    }

    _disposeController();
  }

  _disposeController() {
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _chewieController?.dispose();
    _chewieController = null;
    _isSetChewieControllering == false;
    if (_needFullScreenPlayUrl == widget.controller?.url) {
      needFullScreenPlayUrl = null;
    }
    _initializeStatus = null;
  }

  _delayDisposeController() {
    var chewieController = _chewieController;
    var videoPlayerController = _videoPlayerController;
    chewieController?.pause();
    _chewieController = null;
    _videoPlayerController = null;
    _isSetChewieControllering == false;
    if (_needFullScreenPlayUrl == widget.controller?.url) {
      needFullScreenPlayUrl = null;
    }
    _initializeStatus = null;
    Future.delayed(Duration(seconds: 3), (() {
      videoPlayerController?.dispose();
      chewieController?.dispose();
    }));
  }

  @override
  void didUpdateWidget(DefPlayer oldWidget) {
    if (oldWidget?.controller != widget?.controller) {
      widget?.controller?._defPlayerState = this;
    }
    if (oldWidget?.controller?.url != widget?.controller?.url) {
      _delayDisposeController();
      _setChewieController();
    }
    super.didUpdateWidget(oldWidget);
  }

  _videoPlayerControllerListener() {
    if (widget.controller.onValueChanged != null &&
        _videoPlayerController != null) {
      widget.controller.onValueChanged(_videoPlayerController?.value);
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
          if (_videoPlayerController?.value?.isPlaying == true) {
            _play();
          }
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
              if (widget.snapshot == true) {
                _chewieController.seekTo(Duration(seconds: 0));
                _chewieController.play();
                Future.delayed(Duration(milliseconds: 100), (() {
                  if (widget.showPlayerWhenZoomIn == false) {
                    _chewieController?.pause();
                  }
                  zoomOutPlaychewieController = null;
                  zoomOutDefPlayer = null;
                }));
              } else {
                zoomOutPlaychewieController = null;
                zoomOutDefPlayer = null;
                _delayDisposeController();
                setState(() {});
              }
            } else {
              Future.delayed(Duration(milliseconds: 100), (() {
                zoomOutPlaychewieController = null;
                zoomOutDefPlayer = null;
              }));
            }
          } else {
            zoomOutPlaychewieController = _chewieController;
            zoomOutDefPlayer = this;
          }
        });
  }

  _buildZoomInWidget() {
    return GestureDetector(
      onTap: (widget.zoomInWidgetTap == null ||
              widget.zoomInWidgetTap == ZoomInWidgetTap.none)
          ? null
          : () {
              if (widget.zoomInWidgetTap == ZoomInWidgetTap.fullScreenPlay) {
                _fullScreenPlay();
              } else if (widget.zoomInWidgetTap == ZoomInWidgetTap.play) {
                _play();
              }
            },
      child: Stack(
        children: <Widget>[
          widget.zoomInWidget ??
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
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: widget.playerIcon == null ||
                    _needFullScreenPlayUrl == widget.controller.url ||
                    (widget.showPlayerWhenZoomIn && _initializeStatus != null)
                ? Container()
                : widget.playerIcon,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              child: Center(
                child: _needFullScreenPlayUrl == widget.controller.url ||
                        (widget.showPlayerWhenZoomIn &&
                            _initializeStatus == InitializeStatus.start)
                    ? HCActivityIndicator(
                        color: widget.loadColor,
                      )
                    : Container(),
              ),
            ),
          )
        ],
      ),
    );
  }

  _setChewieController() async {
    if (_isSetChewieControllering == true) {
      return;
    }
    _isSetChewieControllering = true;
    if (zoomOutPlaychewieController != null &&
        zoomOutPlaychewieController.videoPlayerController?.dataSource
            .toLowerCase()
            .contains(widget.controller.url.toLowerCase())) {
      zoomOutDefPlayer = this;
      _videoPlayerController =
          zoomOutPlaychewieController.videoPlayerController;
      _chewieController = zoomOutPlaychewieController;
    } else {
      if (_videoPlayerController == null) {
        await _getVideoPlayerController();
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

      if (_needFullScreenPlayUrl == widget.controller.url) {
        needFullScreenPlayUrl = null;
        _fullScreenPlay();
      }
    }
    _videoPlayerController?.addListener(_videoPlayerControllerListener);
    setState(() {});

    _isSetChewieControllering = false;
  }

  _getVideoPlayerController() async {
    VideoPlayerController videoPlayerController;
    // 网络视频
    if (widget.controller.urlType == DefPlayerUrlType.network) {
      _connectivityResult = await (Connectivity().checkConnectivity());
      if (_allowMobilePlay != true &&
          _connectivityResult == ConnectivityResult.mobile) {
        _videoPlayerController == null;
        return;
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

    _videoPlayerController = videoPlayerController;

    _initializeStatus = InitializeStatus.start;
    if (widget.controller.onInitializeChanged != null) {
      widget.controller.onInitializeChanged(_initializeStatus);
    }
    setState(() {});
    await videoPlayerController.initialize().then((_) {
      _initializeStatus = InitializeStatus.complete;
      if (widget.controller?.onInitializeChanged != null) {
        widget.controller?.onInitializeChanged(_initializeStatus);
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  _fullScreenPlay() async {
    if (_needFullScreenPlayUrl == widget.controller.url) {
      return;
    }
    if (widget.controller?.urlType == DefPlayerUrlType.network &&
        _allowMobilePlay != true &&
        _connectivityResult == ConnectivityResult.mobile) {
      showAlert(context, '正处于移动数据网络，是否继续播放？', '', '取消', '继续播放', rightOnTap: () {
        _allowMobilePlay = true;
        if (_chewieController == null) {
          _setChewieController();
          needFullScreenPlayUrl = widget.controller.url;
          return;
        }
        _startPlay();
        Future.delayed(Duration(milliseconds: 100), () {
          _chewieController.enterFullScreen();
        });
      });
    } else {
      if (_chewieController == null) {
        _setChewieController();
        needFullScreenPlayUrl = widget.controller.url;
        return;
      }
      _startPlay();
      Future.delayed(Duration(milliseconds: 100), () {
        _chewieController.enterFullScreen();
      });
    }
  }

  _play() async {
    if (widget.controller?.urlType == DefPlayerUrlType.network &&
        _allowMobilePlay != true &&
        _connectivityResult == ConnectivityResult.mobile) {
      showAlert(context, '正处于移动数据网络，是否继续播放？', '', '取消', '继续播放', rightOnTap: () {
        _allowMobilePlay = true;
        _startPlay();
      });
    } else {
      _startPlay();
    }
  }

  _startPlay() async {
    if (_videoPlayerController == null) {
      await _setChewieController();
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
