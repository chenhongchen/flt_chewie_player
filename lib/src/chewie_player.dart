import 'dart:async';

import 'package:flt_chewie_player/def_player.dart';
import 'package:flt_chewie_player/flt_chewie_player.dart';
import 'package:flt_chewie_player/src/chewie_progress_colors.dart';
import 'package:flt_chewie_player/src/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

typedef Widget ChewieRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    _ChewieControllerProvider controllerProvider);

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class Chewie extends StatefulWidget {
  Chewie({
    Key key,
    this.controller,
  })  : assert(controller != null, 'You must provide a chewie controller'),
        super(key: key);

  /// The [ChewieController]
  final ChewieController controller;

  @override
  ChewieState createState() {
    return ChewieState();
  }
}

class ChewieState extends State<Chewie> {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(Chewie oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  void listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      _isFullScreen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ChewieControllerProvider(
      controller: widget.controller,
      child: PlayerWithControls(),
    );
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      _ChewieControllerProvider controllerProvider) {
    double lastDownY;
    bool hasExit = false;
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Listener(
        onPointerDown: (dowPointEvent) {
          lastDownY = dowPointEvent.position.dy;
        },
        onPointerMove: (movePointEvent) {
          if (hasExit == true) {
            return;
          }
          var position = movePointEvent.position.dy;
          var detal = position - lastDownY;
          if (detal > 50) {
            controllerProvider.controller.exitFullScreen(context);
            hasExit = true;
          }
        },
        child: Container(
          alignment: Alignment.center,
          color: Colors.black,
          child: controllerProvider,
        ),
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      _ChewieControllerProvider controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var controllerProvider = _ChewieControllerProvider(
      controller: widget.controller,
      child: PlayerWithControls(),
    );

    if (widget.controller.routePageBuilder == null) {
      return Hero(
        tag: 'hero_chewie',
        child: _defaultRoutePageBuilder(
            context, animation, secondaryAnimation, controllerProvider),
      );
      // return FadeTransition(
      //   // 从0开始到1
      //   opacity: Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      //     // 传入设置的动画
      //     parent: animation,
      //     // 设置效果，快进漫出   这里有很多内置的效果
      //     curve: Curves.fastOutSlowIn,
      //   )),
      //   child: _defaultRoutePageBuilder(
      //       context, animation, secondaryAnimation, controllerProvider),
      // );
      // return ScaleTransition(
      //   scale: Tween(begin: 0.0, end: 1.0).animate(
      //       CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn)),
      //   child: _defaultRoutePageBuilder(
      //       context, animation, secondaryAnimation, controllerProvider),
      // );
      // return _defaultRoutePageBuilder(
      //     context, animation, secondaryAnimation, controllerProvider);
    }
    return widget.controller.routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
      ]);
    }

    // chc 改 注释
    // if (!widget.controller.allowedScreenSleep) {
    //   Wakelock.enable();
    // }

    await Navigator.of(context, rootNavigator: true).push(route);
    _isFullScreen = false;
    // chc 改 （注释）
    // widget.controller.exitFullScreen();

    // The wakelock plugins checks whether it needs to perform an action internally,
    // so we do not need to check Wakelock.isEnabled.
    // Wakelock.disable();

    SystemChrome.setEnabledSystemUIOverlays(
        widget.controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsAfterFullScreen);
  }
}

/// The ChewieController is used to configure and drive the Chewie Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the ChewieController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
class ChewieController extends ChangeNotifier {
  ChewieController({
    this.videoPlayerController,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showControls = true,
    this.customControls,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.routePageBuilder = null,
  }) : assert(videoPlayerController != null,
            'You must provide a controller to play a video') {
    _initialize();
  }

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Start video at a certain position
  final Duration startAt;

  /// Whether or not the video should loop
  final bool looping;

  /// Weather or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Whether or not to show the controls at all
  final bool showControls;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget customControls;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage) errorBuilder;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// The colors to use for controls on iOS. By default, the iOS player uses
  /// colors sampled from the original iOS 11 designs.
  final ChewieProgressColors cupertinoProgressColors;

  /// The colors to use for the Material Progress Bar. By default, the Material
  /// player uses the colors from your Theme.
  final ChewieProgressColors materialProgressColors;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// A widget which is placed between the video and the controls
  final Widget overlay;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final ChewieRoutePageBuilder routePageBuilder;

  static ChewieController of(BuildContext context) {
    final chewieControllerProvider =
        context.inheritFromWidgetOfExactType(_ChewieControllerProvider)
            as _ChewieControllerProvider;

    return chewieControllerProvider.controller;
  }

  bool _isFullScreen = false;

  bool get isFullScreen => _isFullScreen;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.initialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  void _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen(BuildContext context) {
    _isFullScreen = false;
    // notifyListeners();
    _podFullScreen(context);
  }

  void toggleFullScreen(BuildContext context) async {
    _isFullScreen = !_isFullScreen;
    // chc 改
    if (_isFullScreen != true) {
      _podFullScreen(context);
    } else {
      notifyListeners();
    }
  }

  _podFullScreen(BuildContext context) async {
    bool isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    int time = 0;
    if (isIOS == true) {
      Map map = await FltChewiePlayerState.zoomIn();
      String orientation = map['orientation'];
      time = 300;
      if (orientation == 'portraitUp') {
        time = 0;
      }
    }
    if (time > 0) {
      Future.delayed(Duration(milliseconds: time), () {
        _pod(context);
      });
    } else {
      _pod(context);
    }
  }

  _pod(BuildContext context) {
    Navigator.of(context, rootNavigator: false).pop();
    Future.delayed(Duration(milliseconds: 700), () {
      if (DefPlayerState.zoomOutDefPlayer == null) {
        DefPlayerState.zoomOutPlaychewieController?.pause();
        DefPlayerState.zoomOutPlaychewieController?.videoPlayerController
            ?.dispose();
        DefPlayerState.zoomOutPlaychewieController?.dispose();
        DefPlayerState.zoomOutPlaychewieController = null;
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }
}

class _ChewieControllerProvider extends InheritedWidget {
  const _ChewieControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final ChewieController controller;

  @override
  bool updateShouldNotify(_ChewieControllerProvider old) =>
      controller != old.controller;
}
