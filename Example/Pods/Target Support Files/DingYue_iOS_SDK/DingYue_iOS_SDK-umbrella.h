#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DYLuaExtension.h"

FOUNDATION_EXPORT double DingYue_iOS_SDKVersionNumber;
FOUNDATION_EXPORT const unsigned char DingYue_iOS_SDKVersionString[];

