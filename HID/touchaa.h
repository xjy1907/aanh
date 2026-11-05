#ifndef TOUCHAA_H
#define TOUCHAA_H

#include "IOHIDEvent.h"
#include "IOHIDEventData.h"
#include "IOHIDEventTypes.h"
#include "IOHIDEventSystemClient.h"
#include "IOHIDEventSystem.h"
#include "IOHIDService.h"
#include "IOKitLib.h"

#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <os/log.h>
#import <objc/runtime.h>
#include <mach/mach_time.h>
#include <stdlib.h>

#if __cplusplus
extern "C" {
#endif

extern NSArray *globalTouchList;
const int TOUCH_DATA_LEN = 13;

NSArray *getGlobalTouchList(void);
void performTouchFromRawData(NSMutableArray *touchList);

NSArray *getSenderIDs(void);

void initSenderId(void);
void initTouchGetScreenSize(float width, float height);
void huoqu(uint64_t aaa);

void touchBegin(int index, float x, float y);
void touchMove(int index, float x, float y);
void touchEnd(int index, float x, float y);

#ifdef __cplusplus
}
#endif

#endif /* TOUCHAA_H */
