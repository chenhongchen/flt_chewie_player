#import "FltChewiePlayerPlugin.h"
#import "UIResponder+Orientations.h"

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
        [UIResponder setUseAppRotationMethod:YES];
        result(@{});
    }
    else if ([@"zoomIn" isEqualToString:call.method]) {
        [UIResponder setUseAppRotationMethod:NO];
        result(@{});
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

@end
