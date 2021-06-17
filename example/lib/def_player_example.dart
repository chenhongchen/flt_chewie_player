import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flt_chewie_player/def_player.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class DefPlayerExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DefPlayerExampleState();
  }
}

class _DefPlayerExampleState extends State<DefPlayerExample> {
  late DefPlayerController _controller;
  bool _showPlayerWhenZoomIn = true;
  @override
  void initState() {
    SchedulerBinding.instance?.addPostFrameCallback((_) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
    _controller = DefPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      autoPlay: true,
      initMute: false,
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = width * 3 / 4;
    return Scaffold(
      appBar: AppBar(
        title: const Text('DefPlayerExample'),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            width: width,
            height: height,
            color: Colors.purple,
          ),
          SizedBox(height: 15),
          Container(
            width: width,
            height: height,
            color: Colors.deepOrangeAccent,
          ),
          SizedBox(height: 15),
          Container(
            width: width,
            height: height,
            color: Colors.brown,
          ),
          SizedBox(height: 15),
          DefPlayer(
            width: width,
            height: height,
            controller: _controller,
            showPlayerWhenZoomIn: _showPlayerWhenZoomIn,
            zoominWidgetAnimation: true,
            blurBackground: true,
            snapshot: false,
            zoomInWidget: GestureDetector(
              onTap: _onTapPlayer,
              child: Container(
                color: Colors.red,
              ),
            ),
            playerIcon: GestureDetector(
              onTap: _onTapPlayer,
              child: Center(
                child: Image.asset('images/play.png'),
              ),
            ),
          ),
          SizedBox(height: 15),
          DefPlayer(
            width: width,
            height: height,
            controller: DefPlayerController.network(
              'https://qzasset.jinriaozhou.com/quanzi/2020/20201110/c4eb8d392e1c25a55c5e3daf04dbd32f_960x720.mp4',
              autoPlay: false,
              initMute: false,
            ),
            showPlayerWhenZoomIn: false,
            zoominWidgetAnimation: true,
            blurBackground: true,
            snapshot: false,
            zoomInWidget: Container(
              color: Colors.blueGrey,
            ),
            playerIcon: GestureDetector(
              onTap: _onTapPlayer,
              child: Center(
                child: Image.asset('images/play.png'),
              ),
            ),
          ),
          SizedBox(height: 15),
          DefPlayer(
            width: width,
            height: height,
            controller: DefPlayerController.network(
              'https://qzasset.jinriaozhou.com/quanzi/2020/20201126/1e4549e8803c4684a6acd44cca96072d_446x960.mp4',
              autoPlay: false,
              initMute: false,
            ),
            showPlayerWhenZoomIn: false,
            zoominWidgetAnimation: true,
            blurBackground: true,
            snapshot: false,
            zoomInWidget: Container(
              color: Colors.purple,
            ),
            playerIcon: GestureDetector(
              onTap: _onTapPlayer,
              child: Center(
                child: Image.asset('images/play.png'),
              ),
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: <Widget>[
              DefPlayer(
                width: 60,
                height: 60,
                controller: DefPlayerController.network(
                  'https://qzasset.jinriaozhou.com/quanzi/2020/20201110/699197592db8b2f3f4d39fa512756fca_540x960.mp4',
                  autoPlay: false,
                  initMute: false,
                ),
                showPlayerWhenZoomIn: false,
                zoominWidgetAnimation: true,
                blurBackground: true,
                snapshot: false,
                showControlsOnInitialize: false,
                zoomInWidget: Container(
                  color: Colors.grey,
                ),
                playerIcon: GestureDetector(
                  onTap: _onTapPlayer,
                  child: Center(
                    child: Image.asset('images/play.png'),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 80,
                  color: Colors.lightGreenAccent,
                ),
              )
            ],
          ),
          SizedBox(height: 15),
          Container(
            width: width,
            height: height,
            color: Colors.blue,
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }

  _onTapPlayer() {
    // _showPlayerWhenZoomIn = true;
    _controller.fullScreenPlay();
    setState(() {});
  }
}
