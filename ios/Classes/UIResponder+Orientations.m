//
//  UIResponder+Orientations.m
//  flt_chewie_player
//
//  Created by chc on 2020/10/21.
//

#import "UIResponder+Orientations.h"
#import <objc/runtime.h>

BOOL g_fcp_allowRotation;
UIInterfaceOrientationMask g_fcp_orientationMask;
@implementation UIResponder (Orientations)
+ (void)initialize
{
    if (self != objc_getClass([@"AppDelegate" UTF8String])) {
        return;
    }
    
    SEL method = @selector(application:supportedInterfaceOrientationsForWindow:);
    if (!class_addMethod([self class], method, (IMP)application_supportedInterfaceOrientationsForWindow, "I@:@c")) { // 创建失败则表示已存在该方法，则采用交换方法的方式
        Class class = objc_getClass([@"AppDelegate" UTF8String]);
        SEL method = @selector(application:supportedInterfaceOrientationsForWindow:);
        SEL newMethod = @selector(applicationNew_fcp:supportedInterfaceOrientationsForWindow:);
        Method originalMethod = class_getInstanceMethod(class, method);
        Method swizzledMethod = class_getInstanceMethod(class, newMethod);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (UIInterfaceOrientationMask)applicationNew_fcp:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (g_fcp_allowRotation) {
        return UIInterfaceOrientationMaskAll;
    }
    g_fcp_orientationMask = [self applicationNew_fcp:application supportedInterfaceOrientationsForWindow:window];
    return g_fcp_orientationMask;
}

u_long application_supportedInterfaceOrientationsForWindow(id self, SEL cmd, UIApplication *application, UIWindow *window)
{
    if (g_fcp_allowRotation) {
        return UIInterfaceOrientationMaskAll;
    }
    g_fcp_orientationMask = [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:window];
    return g_fcp_orientationMask;
}

+ (void)setPortraitOrientation
{
    [self setOrientation:UIInterfaceOrientationPortrait];
}

+ (void)setOrientation:(UIInterfaceOrientation)orientation
{
    //    if(ScreenWidth > ScreenHeight) {
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[UIDevice currentDevice]];
    int val = orientation;
    // 从2开始是因为0 1 两个参数已经被selector和target占用
    [invocation setArgument:&val atIndex:2];
    [invocation invoke];
    //    }
}

#pragma mark - 外部方法
+ (void)setUseAppRotationMethod:(BOOL)isUse
{
    g_fcp_allowRotation = isUse;
    if (isUse == false) {
        UIInterfaceOrientation curOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (g_fcp_orientationMask == UIInterfaceOrientationMaskPortrait) {
            [self setOrientation:UIInterfaceOrientationPortrait];
        }
        if (g_fcp_orientationMask == UIInterfaceOrientationMaskLandscapeLeft) {
            [self setOrientation:UIInterfaceOrientationLandscapeLeft];
        }
        else if(g_fcp_orientationMask == UIInterfaceOrientationMaskLandscapeRight) {
            [self setOrientation:UIInterfaceOrientationLandscapeRight];
        }
        else if (g_fcp_orientationMask == UIInterfaceOrientationMaskPortraitUpsideDown){
            [self setOrientation:UIInterfaceOrientationPortraitUpsideDown];
        }
        else if(g_fcp_orientationMask == UIInterfaceOrientationMaskLandscape) {
            if (curOrientation == UIInterfaceOrientationUnknown || curOrientation == UIInterfaceOrientationPortrait || curOrientation == UIInterfaceOrientationPortraitUpsideDown ) {
                [self setOrientation:UIInterfaceOrientationLandscapeLeft];
            }
        }
        else if (g_fcp_orientationMask == UIInterfaceOrientationMaskAll) {
        }
        else if (g_fcp_orientationMask == UIInterfaceOrientationMaskAllButUpsideDown) {
            if (curOrientation == UIInterfaceOrientationUnknown || curOrientation == UIInterfaceOrientationPortraitUpsideDown ) {
                [self setOrientation:UIInterfaceOrientationPortrait];
            }
        }
    }
}

@end
