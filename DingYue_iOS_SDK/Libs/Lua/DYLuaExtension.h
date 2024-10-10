//
//  DYLuaExtension.h
//  DingYue_iOS_SDK
//
//  Created by apple on 2024/4/28.
//

#import <Foundation/Foundation.h>
#import <DinYueLua/dingyue_extensions.h>
NS_ASSUME_NONNULL_BEGIN

@interface DYLuaExtension : NSObject
@property (nonatomic) lua_State* luaState;
- (lua_State *)initLuaExtensionsWithDYLuaModule:(const char*)module_name function_def:(luaL_Reg*)function_def;

//在两个不同的地方（swift框架和app工程）初始化了Lua环境并且注册了两个不同的模块。然而，每次调用`lua_init`函数，都会创建一个新的Lua状态机，这两个状态机是完全独立的，他们不能共享数据或者函数。
//在app工程中使用`callLuaFunction`调用`fun5`函数时，这个函数运行在app工程初始化的Lua环境中。在这个环境中，只有`TestLuaOperation`模块是可用的，因为这个模块在这个环境中被注册了。然而，`DYLuaModule`模块并没有在这个环境中被注册，所以在`fun5`函数中无法访问到`DYLuaModule`模块的函数。
//如果想在`fun5`函数中同时使用`TestLuaOperation`模块和`DYLuaModule`模块，你需要在同一个Lua环境中同时注册这两个模块。你可以在调用`lua_init`函数时，传入一个包含这两个模块所有函数的函数定义数组，然后在Lua脚本中分别使用不同的前缀来调用这两个模块的函数。

//`lua_State` 是 Lua 语言中的一个重要结构。它在 Lua 的 C API 中代表了一个独立的运行环境，也就是说，每个 `lua_State` 就是一个独立的 Lua 虚拟机实例。
//在 Lua 的 C API 中，几乎所有的函数都需要一个 `lua_State *` 类型的参数，这是因为这些函数需要通过这个参数来访问虚拟机的状态。
//你可以通过调用 `luaL_newstate` 函数来创建一个新的 `lua_State`，也可以通过 `lua_close` 函数来销毁一个 `lua_State`。同时，Lua 的垃圾收集器也会自动管理 `lua_State` 的生命周期。
//总的来说，`lua_State` 对于 Lua 的 C API 来说非常重要，因为它代表了 Lua 虚拟机的运行环境。


//- (lua_State *)initLuaExtensionsWithDYModule:(const char *_Nonnull*_Nonnull)module_names function_defs:(luaL_Reg *_Nonnull*_Nonnull)function_defs;
@end

NS_ASSUME_NONNULL_END
