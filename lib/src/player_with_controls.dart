import 'dart:ui';

import 'package:flt_chewie_player/src/chewie_player.dart';
import 'package:flt_chewie_player/src/cupertino_controls.dart';
import 'package:flt_chewie_player/src/material_controls.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  PlayerWithControls({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: AspectRatio(
          aspectRatio:
              chewieController.aspectRatio ?? _calculateAspectRatio(context),
          child: _buildPlayerWithControls(chewieController, context),
        ),
      ),
    );
  }

  Container _buildPlayerWithControls(
      ChewieController chewieController, BuildContext context) {
    bool tbSafe = false;
    bool lrSafe = false;
    if (chewieController.isFullScreen == true) {
      double sw = MediaQuery.of(context).size.width ?? 0;
      double sh = MediaQuery.of(context).size.height ?? 0;
      if (sw > sh) {
        tbSafe = true;
        lrSafe = true;
      } else {
        if (sw > 0 && sh > 0) {
          double ratio = sw / sh;
          double ratio1 = chewieController.aspectRatio;
          if (ratio > ratio1) {
            tbSafe = true;
          }
        }
      }
    }
    return Container(
      child: Stack(
        children: <Widget>[
          chewieController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: chewieController.aspectRatio ??
                  _calculateAspectRatio(context),
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          chewieController.overlay ?? Container(),
          SafeArea(
            left: lrSafe,
            right: lrSafe,
            top: tbSafe,
            bottom: tbSafe,
            child: _buildControls(context, chewieController),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ChewieController chewieController,
  ) {
    return chewieController.showControls
        ? chewieController.customControls != null
            ? chewieController.customControls
            : Theme.of(context).platform == TargetPlatform.android
                ? MaterialControls()
                : CupertinoControls(
                    backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
                    iconColor: Color.fromARGB(255, 200, 200, 200),
                  )
        : Container();
  }

  double _calculateAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return width > height ? width / height : height / width;
  }
}
