import 'package:flt_chewie_player/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChewieFullScreenVideo extends StatefulWidget {
  final ChewieControllerProvider controllerProvider;
  ChewieFullScreenVideo({Key key, @required this.controllerProvider})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _ChewieFullScreenVideoState();
  }
}

class _ChewieFullScreenVideoState extends State<ChewieFullScreenVideo>
    with TickerProviderStateMixin {
  //动画控制器
  AnimationController _controller;
  Animation<Offset> _animation;
  bool _showTip = true;
  final String _showTipKey = 'kCloseVideoFullScreenGestureTip';
  double _opacityLevel = 0.0;
  int _showTipTime = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //将动画重置到开始前的状态
        _controller.reset();
        //开始执行
        _controller.forward();
      }
    });
    _animation =
        Tween(begin: Offset(0, 0), end: Offset(0, 1)).animate(_controller);
    _getTipInfo();
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Stack(
        children: <Widget>[
          _buildVideo(),
          _buildCloseGesture(),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    double lastDownY;
    bool hasExit = false;
    return Listener(
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
          widget.controllerProvider.controller.exitFullScreen(context);
          hasExit = true;
        }
      },
      child: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: widget.controllerProvider,
      ),
    );
  }

  _buildCloseGesture() {
    double lastDownY;
    return Positioned(
      top: 0,
      left: 0,
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: () async {
          if (_showTip != true) {
            return;
          }
          int time = DateTime.now().millisecondsSinceEpoch;
          if (_showTipTime == 0 || (time - _showTipTime <= 1000)) {
            return;
          }
          _controller.stop();
          SharedPreferences sp = await SharedPreferences.getInstance();
          sp.setString(_showTipKey, '1');
          _opacityLevel = 0.0;
          setState(() {});
          Future.delayed(Duration(milliseconds: 300), () {
            _showTip = false;
            setState(() {});
          });
        },
        onVerticalDragDown: (DragDownDetails details) {
          lastDownY = details.localPosition.dy;
        },
        onVerticalDragUpdate: (DragUpdateDetails details) async {
          if (_showTip != true) {
            return;
          }
          var position = details.localPosition.dy;
          var detal = position - lastDownY;
          if (detal > 50) {
            int time = DateTime.now().millisecondsSinceEpoch;
            if (_showTipTime == 0 || (time - _showTipTime <= 1000)) {
              return;
            }
            _controller.stop();
            SharedPreferences sp = await SharedPreferences.getInstance();
            sp.setString(_showTipKey, '1');
            _opacityLevel = 0.0;
            setState(() {});
            Future.delayed(Duration(milliseconds: 300), () {
              _showTip = false;
              setState(() {});
            });
          }
        },
        child: _showTip != true
            ? Container()
            : Stack(
                children: <Widget>[
                  AnimatedOpacity(
                    opacity: _opacityLevel, //设置透明度
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      color: Colors.black,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _opacityLevel > 0 ? 1 : 0, //设置透明度
                    duration: Duration(milliseconds: 300),
                    child: Container(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '下滑快速关闭视频',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            SlideTransition(
                              position: _animation,
                              child: Center(
                                child: Image.asset(
                                  'images/pic_gesture.png',
                                  package: 'flt_chewie_player',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      color: Colors.transparent,
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                    ),
                  )
                ],
              ),
      ),
    );
  }

  _getTipInfo() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    _showTip = sp.getString(_showTipKey) == '1' ? false : true;
    await Future.delayed(Duration(milliseconds: 300), () async {
      setState(() {});
      if (_showTip == true) {
        _opacityLevel = 0.4;
        _showTipTime = DateTime.now().millisecondsSinceEpoch;
        await Future.delayed(Duration(milliseconds: 500), () {
          _controller.forward();
          setState(() {});
        });
      }
    });
  }
}
