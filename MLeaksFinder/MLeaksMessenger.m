/**
 * Tencent is pleased to support the open source community by making MLeaksFinder available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import "MLeaksMessenger.h"

static __weak UIAlertController *currentAlert;

static UIViewController *MLeaksMessengerTopViewController(UIViewController *vc) {
    if (!vc) {
        return nil;
    }
    if (vc.presentedViewController) {
        return MLeaksMessengerTopViewController(vc.presentedViewController);
    }
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return MLeaksMessengerTopViewController([(UINavigationController *)vc visibleViewController]);
    }
    if ([vc isKindOfClass:[UITabBarController class]]) {
        return MLeaksMessengerTopViewController([(UITabBarController *)vc selectedViewController]);
    }
    return vc;
}

static UIViewController *MLeaksMessengerPresenterViewController(void) {
    if (@available(iOS 13.0, *)) {
        NSSet<UIScene *> *scenes = [UIApplication sharedApplication].connectedScenes;
        for (UIScene *scene in scenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) {
                continue;
            }
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    UIViewController *top = MLeaksMessengerTopViewController(window.rootViewController);
                    if (top) {
                        return top;
                    }
                }
            }
        }
        for (UIScene *scene in scenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    UIViewController *top = MLeaksMessengerTopViewController(window.rootViewController);
                    if (top) {
                        return top;
                    }
                }
            }
        }
        for (UIScene *scene in scenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.windowLevel == UIWindowLevelNormal && window.rootViewController) {
                    return MLeaksMessengerTopViewController(window.rootViewController);
                }
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
    return MLeaksMessengerTopViewController(keyWindow.rootViewController);
}

@implementation MLeaksMessenger

+ (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    [self alertWithTitle:title message:message additionalButtonTitle:nil additionalButtonHandler:nil];
}

+ (void)alertWithTitle:(NSString *)title
               message:(NSString *)message
 additionalButtonTitle:(NSString *)additionalButtonTitle
 additionalButtonHandler:(void (^)(void))handler {
    void (^presentNew)(void) = ^{
        UIViewController *presenter = MLeaksMessengerPresenterViewController();
        if (!presenter) {
            NSLog(@"%@: %@ (no presenter; alert not shown)", title, message);
            return;
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        if (additionalButtonTitle.length) {
            [alert addAction:[UIAlertAction actionWithTitle:additionalButtonTitle
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                if (handler) {
                    handler();
                }
            }]];
        }
        [presenter presentViewController:alert animated:YES completion:nil];
        currentAlert = alert;
        NSLog(@"%@: %@", title, message);
    };
    void (^run)(void) = ^{
        UIAlertController *previous = currentAlert;
        if (previous.presentingViewController) {
            [previous dismissViewControllerAnimated:NO completion:presentNew];
        } else {
            presentNew();
        }
    };
    if ([NSThread isMainThread]) {
        run();
    } else {
        dispatch_async(dispatch_get_main_queue(), run);
    }
}

@end
