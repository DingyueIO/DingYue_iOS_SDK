//
//  DYLuaExtension.m
//  DingYue_iOS_SDK
//
//  Created by apple on 2024/4/28.
//

#import "DYLuaExtension.h"

static int dingyueFunc(lua_State* L) {
    lua_pushstring(L, "dingyue sdk 中的扩展方法");
    return 1;
}

static luaL_Reg dingyue_functions[] = {
        {"dingyueFunc", dingyueFunc},
        {NULL, NULL}
};

@implementation DYLuaExtension

//- (void)initDYLuaExtensionsMethod {
//    self.luaState = lua_init("DYLuaModule", dingyue_functions);
//    NSLog(@"dingyuelua --- 执行dingyue 中的lua 扩展的init");
////    NSString *scriptFilePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"lua"];//这里需要从dingyuesdk获得
////    int result = load_lua_script_from_file(self.luaState, scriptFilePath);
//    
////    NSString *test = @"function fun2()\n"
////                     "local b = DYMobileLua.testfunc1()\n"
////                     "return b\n"
////                     "end";
////    int result = load_lua_script(self.luaState, test);
////    if (result != LUA_OK) {
////        NSLog(@"load lua script failed");
////    } else {
////        //调用lua脚本方法
////        NSArray* result1 = call_lua_function(self.luaState, "fun2", @[], 1, true, nil);
////        NSLog(@"lua fun1 result: %@", result1);
////    }
//}

- (lua_State *)initLuaExtensionsWithDYLuaModule:(const char*)module_name function_def:(luaL_Reg*)function_def {
    
    int module_count = 2;
    const char *module_names[] = {module_name, "DYLuaModule"};
    luaL_Reg *module_function_defs[] = {function_def, dingyue_functions};
    return lua_init_multiple(module_count, module_names, module_function_defs);
}
@end
