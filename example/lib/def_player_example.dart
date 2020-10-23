import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flt_chewie_player/def_player.dart';

class DefPlayerExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DefPlayerExampleState();
  }
}

class _DefPlayerExampleState extends State<DefPlayerExample> {
  DefPlayerController _controller;
  bool _showPlayerWhenZoomIn = false;
  @override
  void initState() {
    _controller = DefPlayerController.network(
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      autoPlay: false,
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
      body: Center(
        child: DefPlayer(
          width: width,
          height: height,
          controller: _controller,
          showPlayerWhenZoomIn: _showPlayerWhenZoomIn,
          zoominWidgetAnimation: true,
          blurBackground: true,
          zoomInWidget: GestureDetector(
            onTap: () {
              _showPlayerWhenZoomIn = true;
              _controller.play();
              setState(() {});
            },
            child: Container(
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
