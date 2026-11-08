//
//  UITouch-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.
//

#import "UITouch-KIFAdditions.h"
#import <objc/runtime.h>

@implementation UITouch (KIFAdditions)

- (instancetype)initAtPoint:(CGPoint)point
                   inWindow:(UIWindow *)window
                     onView:(UIView *)view;
{
  self = [super init];
  if (self == nil)
    return nil;

  // Create a fake tap touch
  [self setWindow:window];  // Wipes out some values. Needs to be first.
  [self _setLocationInWindow:point resetPrevious:YES];

  UIView *hitTestView = view;

  [self setView:hitTestView];
  [self setPhase:UITouchPhaseBegan];
  if (![[NSProcessInfo processInfo] isiOSAppOnMac] &&
      ![[NSProcessInfo processInfo] isMacCatalystApp])
  {
    [self _setIsTapToClick:NO];
  }
  else
  {
    [self _setIsFirstTouchForView:YES];
    [self setIsTap:NO];
  }

  [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
  
  if ([self respondsToSelector:@selector(setGestureView:)])
    [self setGestureView:hitTestView];

  [self kif_setHidEvent];
  return self;
}

- (instancetype)initTouch;
{
  self = [super init];
  if (self == nil)
    return nil;

  // 对齐 qwer：Books 非 Scene 应用，冷启动 connectedScenes 为空。
  // 旧代码 objectAtIndex:0 会在 iPadOS15.3 上 NSRangeException → 黑屏秒退。
  UIWindow *window = [[[UIApplication sharedApplication] windows] firstObject];
  if (!window) {
    window = [[UIWindow alloc] initWithFrame:CGRectZero];
  }
  CGPoint point = CGPointMake(0, 0);
  
  [self setWindow:window];  // Wipes out some values.  Needs to be first.
  [self _setLocationInWindow:point resetPrevious:YES];

  UIView *hitTestView = [window hitTest:point withEvent:nil];

  [self setView:hitTestView];
  [self setPhase:UITouchPhaseEnded];

  if (![[NSProcessInfo processInfo] isiOSAppOnMac] &&
      ![[NSProcessInfo processInfo] isMacCatalystApp])
  {
    [self _setIsTapToClick:NO];
  }
  else
  {
    [self _setIsFirstTouchForView:YES];
    [self setIsTap:NO];
  }

  [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];

  if ([self respondsToSelector:@selector(setGestureView:)])
    [self setGestureView:hitTestView];

  [self kif_setHidEvent];
  return self;
}

- (void)setLocationInWindow:(CGPoint)location
{
  [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
  [self _setLocationInWindow:location resetPrevious:NO];
}

- (void)setPhaseAndUpdateTimestamp:(UITouchPhase)phase
{
  [self setTimestamp:[[NSProcessInfo processInfo] systemUptime]];
  [self setPhase:phase];
}

- (void)kif_setHidEvent
{
  IOHIDEventRef event = kif_IOHIDEventWithTouches(@[ self ]);
  [self _setHidEvent:event];
  CFRelease(event);
}

@end
