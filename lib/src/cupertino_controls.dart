import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flt_chewie_player/src/animated_play_pause.dart';
import 'package:flt_chewie_player/src/chewie_player.dart';
import 'package:flt_chewie_player/src/chewie_progress_colors.dart';
import 'package:flt_chewie_player/src/cupertino_progress_bar.dart';
import 'package:flt_chewie_player/src/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CupertinoControls extends StatefulWidget {
  const CupertinoControls({
    required this.backgroundColor,
    required this.iconColor,
  });

  final Color backgroundColor;
  final Color iconColor;

  @override
  State<StatefulWidget> createState() {
    return _CupertinoControlsState();
  }
}

class _CupertinoControlsState extends State<CupertinoControls> {
  VideoPlayerValue? _latestValue;
  double _latestVolume = 0.5;
  bool _hideStuff = true;
  Timer? _hideTimer;
  final marginSize = 5.0;
  Timer? _expandCollapseTimer;
  Timer? _initTimer;

  VideoPlayerController? controller;
  ChewieController? chewieController;

  double _width = 0;
  double _height = 0;
  bool _isZoomInCanShowControllers = true;

  @override
  Widget build(BuildContext context) {
    chewieController = ChewieController.of(context);
    if (chewieController == null || controller == null) {
      return Container();
    }
    if (_latestValue?.hasError == true) {
      return chewieController!.errorBuilder != null
          ? chewieController!.errorBuilder!(
              context,
              chewieController!.videoPlayerController.value.errorDescription ??
                  '',
            )
          : const Center(
              child: Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    Future.delayed(Duration(milliseconds: 0), () {
      _width = context.size?.width ?? 0;
      _height = context.size?.height ?? 0;
      // print('_width = $_width _height = $_height');
    });
    if (_width < 105 ||
        _height < 85 ||
        (_isZoomInCanShowControllers == false &&
            chewieController?.isFullScreen != true)) {
      if (_width != 0 && _height != 0) {
        _isZoomInCanShowControllers = false;
      }
      return Container();
    }

    final backgroundColor = widget.backgroundColor;
    final iconColor = widget.iconColor;
    chewieController = ChewieController.of(context);
    controller = chewieController?.videoPlayerController;
    final orientation = MediaQuery.of(context).orientation;
    final barHeight = orientation == Orientation.portrait ? 30.0 : 47.0;
    final buttonPadding = orientation == Orientation.portrait ? 16.0 : 24.0;

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () {
          _cancelAndRestartTimer();
        },
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              _buildTopBar(
                  backgroundColor, iconColor, barHeight, buttonPadding),
              _buildHitArea(),
              _buildBottomBar(backgroundColor, iconColor, barHeight),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller?.removeListener(_updateState);
    _hideTimer?.cancel();
    _expandCollapseTimer?.cancel();
    _initTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController?.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  AnimatedOpacity _buildBottomBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
  ) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.all(marginSize),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              height: barHeight,
              color: backgroundColor,
              child: chewieController!.isLive
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _buildPlayPause(controller!, iconColor, barHeight),
                        _buildLive(iconColor),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        _buildSkipBack(iconColor, barHeight),
                        _buildPlayPause(controller!, iconColor, barHeight),
                        _buildSkipForward(iconColor, barHeight),
                        _buildPosition(iconColor),
                        _buildProgressBar(),
                        _buildRemaining(iconColor)
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLive(Color iconColor) {
    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: Text(
        'LIVE',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildExpandButton(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: buttonPadding,
                right: buttonPadding,
              ),
              color: backgroundColor,
              child: Center(
                child: Icon(
                  chewieController!.isFullScreen
                      ? CupertinoIcons.arrow_down_right_arrow_up_left
                      : CupertinoIcons.arrow_up_left_arrow_down_right,
                  color: iconColor,
                  size: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: _latestValue != null && _latestValue?.isPlaying == true
            ? _cancelAndRestartTimer
            : () {
                _hideTimer?.cancel();

                setState(() {
                  _hideStuff = false;
                });
              },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue?.volume == 0) {
          controller.setVolume(_latestVolume);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10.0),
            child: Container(
              color: backgroundColor,
              child: Container(
                height: barHeight,
                padding: EdgeInsets.only(
                  left: buttonPadding,
                  right: buttonPadding,
                ),
                child: Icon(
                  (_latestValue != null && (_latestValue?.volume ?? 0) > 0)
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: iconColor,
                  size: 16.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(
    VideoPlayerController controller,
    Color iconColor,
    double barHeight,
  ) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: AnimatedPlayPause(
          color: widget.iconColor,
          playing: controller.value.isPlaying,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue?.position ?? Duration(seconds: 0);

    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: Text(
        formatDuration(position),
        style: TextStyle(
          color: iconColor,
          fontSize: 12.0,
        ),
      ),
    );
  }

  Widget _buildRemaining(Color iconColor) {
    final position = _latestValue?.duration != null
        ? _latestValue!.duration - _latestValue!.position
        : Duration(seconds: 0);

    return Padding(
      padding: EdgeInsets.only(right: 12.0),
      child: Text(
        '-${formatDuration(position)}',
        style: TextStyle(color: iconColor, fontSize: 12.0),
      ),
    );
  }

  GestureDetector _buildSkipBack(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipBack,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 10.0),
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 6.0,
        ),
        child: Icon(
          CupertinoIcons.gobackward_15,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  GestureDetector _buildSkipForward(Color iconColor, double barHeight) {
    return GestureDetector(
      onTap: _skipForward,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 6.0,
          right: 8.0,
        ),
        margin: const EdgeInsets.only(
          right: 8.0,
        ),
        child: Icon(
          CupertinoIcons.goforward_15,
          color: iconColor,
          size: 18.0,
        ),
      ),
    );
  }

  Widget _buildTopBar(
    Color backgroundColor,
    Color iconColor,
    double barHeight,
    double buttonPadding,
  ) {
    return Container(
      height: barHeight,
      margin: EdgeInsets.only(
        top: marginSize,
        right: marginSize,
        left: marginSize,
      ),
      child: Row(
        children: <Widget>[
          if (chewieController!.allowFullScreen)
            _buildExpandButton(
                backgroundColor, iconColor, barHeight, buttonPadding),
          const Spacer(),
          if (chewieController!.allowMuting)
            _buildMuteButton(controller!, backgroundColor, iconColor, barHeight,
                buttonPadding),
        ],
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();

    setState(() {
      _hideStuff = false;

      _startHideTimer();
    });
  }

  Future<Null> _initialize() async {
    controller?.addListener(_updateState);

    _updateState();

    if (controller?.value.isPlaying == true ||
        chewieController?.autoPlay == true) {
      _startHideTimer();
    }

    if (chewieController?.showControlsOnInitialize == true) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      chewieController?.toggleFullScreen(context);
      _expandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 12.0),
        child: CupertinoVideoProgressBar(
          controller!,
          onDragStart: () {
            _hideTimer?.cancel();
          },
          onDragEnd: () {
            _startHideTimer();
          },
          colors: chewieController!.cupertinoProgressColors ??
              ChewieProgressColors(
                playedColor: Color.fromARGB(
                  120,
                  255,
                  255,
                  255,
                ),
                handleColor: Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ),
                bufferedColor: Color.fromARGB(
                  60,
                  255,
                  255,
                  255,
                ),
                backgroundColor: Color.fromARGB(
                  20,
                  255,
                  255,
                  255,
                ),
              ),
        ),
      ),
    );
  }

  void _playPause() {
    bool isFinished = _latestValue == null
        ? false
        : _latestValue!.position >= _latestValue!.duration;

    setState(() {
      if (controller?.value.isPlaying == true) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller?.pause();
      } else {
        _cancelAndRestartTimer();

        if (controller?.value.isInitialized == false) {
          controller?.initialize().then((_) {
            controller?.play();
          });
        } else {
          if (isFinished) {
            controller?.seekTo(Duration(seconds: 0));
          }
          controller?.play();
        }
      }
    });
  }

  void _skipBack() {
    _cancelAndRestartTimer();
    final beginning = Duration(seconds: 0).inMilliseconds;
    final skip =
        (_latestValue!.position - Duration(seconds: 15)).inMilliseconds;
    controller!.seekTo(Duration(milliseconds: math.max(skip, beginning)));
  }

  void _skipForward() {
    _cancelAndRestartTimer();
    final end = _latestValue!.duration.inMilliseconds;
    final skip =
        (_latestValue!.position + Duration(seconds: 15)).inMilliseconds;
    controller!.seekTo(Duration(milliseconds: math.min(skip, end)));
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller?.value;
    });
  }
}
