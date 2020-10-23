import 'package:flutter/material.dart';
import 'package:flt_chewie_player/flt_chewie_player.dart';
import 'def_player_example.dart';

void main() {
  runApp(MaterialApp(home: MyApp(), routes: <String, WidgetBuilder>{
    "PlayerExample": (BuildContext context) => new PlayerExample(),
    "DefPlayerExample": (BuildContext context) => new DefPlayerExample(),
  }));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed("PlayerExample");
              },
              child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Text('跳转PlayerExample页面',
                    style: TextStyle(
                      color: Colors.black,
                    )),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed("DefPlayerExample");
              },
              child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                height: 50,
                child: Text('跳转DefPlayerExample页面',
                    style: TextStyle(
                      color: Colors.black,
                    )),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PlayerExample extends StatefulWidget {
  @override
  _PlayerExampleState createState() => _PlayerExampleState();
}

class _PlayerExampleState extends State<PlayerExample> {
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  bool _showPlayerWhenZoomIn = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = width * 3 / 4;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayerExample'),
      ),
      body: Center(
        child: FltChewiePlayer(
          width: width,
          height: height,
          snapshotMode: SnapshotMode.scaleAspectFill,
          snapshot: true,
          zoomInWidget: _buildZoomInWidget(),
          controller: _chewieController,
          showPlayerWhenZoomIn: _showPlayerWhenZoomIn,
          blurBackground: true,
          onZoomChange: (value) async {
            if (value == FltChewiePlayerZoom.zoomIn &&
                _showPlayerWhenZoomIn == false) {
              _chewieController.seekTo(Duration(seconds: 0));
            }
          },
        ),
      ),
    );
  }

  _buildZoomInWidget() {
    double width = MediaQuery.of(context).size.width;
    double height = width * 3 / 4;
    double btnH = height / 3.0;
    return Stack(
      children: <Widget>[
        Container(
          width: width,
          height: height,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: btnH,
          child: GestureDetector(
            onTap: () {
              _showPlayerWhenZoomIn = false;
              _startPlay();
            },
            child: Container(
              color: Colors.red.withOpacity(0.5),
              alignment: Alignment.center,
              child: Text('无最小窗口全屏播放'),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: btnH,
          height: btnH,
          child: GestureDetector(
            onTap: () {
              _showPlayerWhenZoomIn = true;
              _startPlay();
            },
            child: Container(
              color: Colors.orange.withOpacity(0.5),
              alignment: Alignment.center,
              child: Text('有小窗口，初始全屏播放'),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: btnH * 2,
          height: btnH,
          child: GestureDetector(
            onTap: () {
              _showPlayerWhenZoomIn = true;
              _startPlay(defFullScreen: false);
            },
            child: Container(
              color: Colors.blue.withOpacity(0.5),
              alignment: Alignment.center,
              child: Text('有小窗口，初始小窗播放'),
            ),
          ),
        ),
      ],
    );
  }

  _startPlay({bool defFullScreen = true}) async {
    if (_videoPlayerController == null) {
      _videoPlayerController = VideoPlayerController.network(
          'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
      await _videoPlayerController.initialize();
    }
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      autoPlay: true,
      looping: true,
    );
    setState(() {});

    if (defFullScreen == true) {
      Future.delayed(Duration(milliseconds: 100), () {
        _chewieController.enterFullScreen();
      });
    }
  }

  _disposePlayer() {
    if (_videoPlayerController != null) {
      _videoPlayerController.pause();
      _videoPlayerController.dispose();
      _videoPlayerController = null;
    }
    if (_chewieController != null) {
      _chewieController.dispose();
      _chewieController = null;
    }
  }
}
