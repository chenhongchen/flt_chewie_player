#import "FltChewiePlayerPlugin.h"
#import "AppDelegate+VP.h"

@implementation FltChewiePlayerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flt_chewie_player"
            binaryMessenger:[registrar messenger]];
    FltChewiePlayerPlugin* instance = [[FltChewiePlayerPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"zoomOut" isEqualToString:call.method]) {
        [UIResponder setUseAppRotationMethod:YES allowRotationOrientationMask:UIInterfaceOrientationMaskAllButUpsideDown];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FltChewiePlayerZoomOut" object:nil userInfo:nil];
        result(@{});
    }
    else if ([@"zoomIn" isEqualToString:call.method]) {
        NSString *orientation = [self getOrientation];
        [UIResponder setUseAppRotationMethod:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FltChewiePlayerZoomIn" object:nil userInfo:nil];
        result(@{@"orientation" : orientation});
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (NSString *)getOrientation
{
    UIInterfaceOrientation curOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    NSString *orientation = @"portraitUp";
    if (curOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        orientation = @"portraitDown";
    }
    else if (curOrientation == UIInterfaceOrientationLandscapeLeft) {
        orientation = @"landscapeLeft";
    }
    else if (curOrientation == UIInterfaceOrientationLandscapeRight) {
        orientation = @"landscapeRight";
    }
    return orientation;
}

@end
