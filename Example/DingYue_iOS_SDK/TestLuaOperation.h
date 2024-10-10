//
//  TestLuaOperation.h
//  DingYue_iOS_SDK_Example
//
//  Created by 王勇 on 2024/8/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DingYue_iOS_SDK/DYLuaExtension.h>
@import DingYue_iOS_SDK;
NS_ASSUME_NONNULL_BEGIN

@interface TestLuaOperation : NSObject
@property (nonatomic) lua_State* llua;
@property (nonatomic) int result;

+ (instancetype)sharedInstance;
- (void)initLua;
- (void)callLuaFunction:(const char *)functionName withParams:(NSArray *)params withReturnCount:(int) count withKeepEnv:(BOOL) keepEnv withErrorHandler:(void(^)(NSError *)) errorHandler;
@end

NS_ASSUME_NONNULL_END
