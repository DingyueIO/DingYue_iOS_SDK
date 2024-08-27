//
//  TestLuaOperation.m
//  DingYue_iOS_SDK_Example
//
//  Created by 王勇 on 2024/8/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

#import "TestLuaOperation.h"



static int testfunc3(lua_State* L) {
    lua_pushstring(L, "testfunc3 aa");
    lua_pushstring(L, "testfunc3 bb");
    lua_pushstring(L, "testfunc3 cc");
    return 3;
}

static luaL_Reg my_functions[] = {
        {"testfunc3", testfunc3},
        {NULL, NULL}
};


@implementation TestLuaOperation

static TestLuaOperation *sharedInstance = nil;
// 单例访问方法
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}
// 使用alloc的自定义实现来确保无法创建其他实例
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}
// 重写copy方法来防止复制单例
- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)initLua {
    // 初始化 Lua 环境，并注册 C 函数
    self.llua = [[[DYLuaExtension alloc] init] initLuaExtensionsWithDYLuaModule:"TestLuaOperation" function_def:my_functions];
    
    // 检查 Lua 状态
    if (self.llua == NULL) {
        NSLog(@"dingyuelua --- initLua - failed to create Lua state");
        return;
    }
    
    // 确认脚本路径
    NSString *scriptFilePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"lua"];
    if (scriptFilePath == nil) {
        NSLog(@"dingyuelua --- Lua script file not found");
        return;
    }
    NSLog(@"dingyuelua --- Lua script file path: %@", scriptFilePath);
    
    // 加载 Lua 脚本
    self.result = load_lua_script_from_file(self.llua, scriptFilePath);
    if (self.result != LUA_OK) {
        NSLog(@"dingyuelua --- initLua - load lua script failed with error: %d", self.result);
        return;
    }
    
    NSLog(@"dingyuelua --- initLua - load lua script ok");
    
    // 调用 Lua 函数来打印函数名
    lua_getglobal(self.llua, "printFunctions");
    if (lua_isfunction(self.llua, -1)) {
        if (lua_pcall(self.llua, 0, 0, 0) != LUA_OK) {
            NSLog(@"dingyuelua --- Error calling printFunctions: %s", lua_tostring(self.llua, -1));
        }
    } else {
        NSLog(@"dingyuelua --- printFunctions is not a function");
    }
}
- (void)callLuaFunction:(const char *)functionName withParams:(NSArray *)params withReturnCount:(int)count withKeepEnv:(BOOL)keepEnv withErrorHandler:(void(^)(NSError *))errorHandler {
    
    if (self.result != LUA_OK) {
        NSLog(@"dingyuelua --- load lua script failed with error: %d", self.result);
        if (errorHandler) {
            NSError *error = [NSError errorWithDomain:@"LuaErrorDomain" code:self.result userInfo:@{NSLocalizedDescriptionKey: @"Failed to load Lua script"}];
            errorHandler(error);
        }
        return;
    }
    
    // 确认 Lua 环境中的函数
    lua_getglobal(self.llua, functionName);
    if (!lua_isfunction(self.llua, -1)) {
        NSLog(@"dingyuelua --- %s is not a function", functionName);
        lua_pop(self.llua, 1);
        if (errorHandler) {
            NSError *error = [NSError errorWithDomain:@"LuaErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%s is not a function", functionName]}];
            errorHandler(error);
        }
        return;
    }
    lua_pop(self.llua, 1);
    
    // 调用 Lua 脚本方法
    NSLog(@"dingyuelua --- 调用 lua 脚本方法: %s with params: %@ and return count: %d", functionName, params, count);
    NSArray* result1 = call_lua_function(self.llua, functionName, params, count, keepEnv, nil);
    if (result1 == nil) {
        NSLog(@"dingyuelua --- call lua function %s failed", functionName);
        if (errorHandler) {
            NSError *error = [NSError errorWithDomain:@"LuaErrorDomain" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to call Lua function"}];
            errorHandler(error);
        }
        return;
    }
    
    NSLog(@"dingyuelua --- 调用 lua 脚本方法: %s 结果: %@", functionName, result1);
}
@end

