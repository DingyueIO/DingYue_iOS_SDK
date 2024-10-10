//
//  fartech_extensions.h
//  lua
//
//  Created by Alex on 23/4/24.
//

#ifndef fartech_extensions_h
#define fartech_extensions_h

#include <DingYueLua/lua.h>
#include <DingYueLua/lualib.h>
#include <DingYueLua/lauxlib.h>
#include <DingYueLua/luaconf.h>

NSArray* call_lua_function(
        lua_State *L,
        const char *func,
        NSArray *args,
        int count_of_returns,
        bool keep_env,
        void(^error_handler)(NSError *)
);

lua_State* lua_init(const char* user_module_name, luaL_Reg* user_module_function_defs);
lua_State *lua_init_multiple(int module_count, const char **module_names, luaL_Reg **module_function_defs);

int load_lua_script_from_file(lua_State* L, NSString* scriptFilename);

int load_lua_script(lua_State* L, NSString* script);

void free_obj_env(void);

#endif /* fartech_extensions_h */
