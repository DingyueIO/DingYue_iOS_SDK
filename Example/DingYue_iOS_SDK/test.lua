-- 打印所有定义的函数名
function printFunctions()
    print("Defined functions in script:")
    for name, value in pairs(_G) do
        if type(value) == "function" then
            print(name)
        end
    end
end

function fun4()
    ios.nslog("lua -- enter fun4")
    local str = fun3()
    local length = ios.foundation_nsstring_length(str)
    print("lua -- The length of NSString object is "..tostring(length))
    
    if TestLuaOperation.testfunc3 then
        print("lua -- app extension - "..tostring(TestLuaOperation.testfunc3()))
    else
        print("lua -- TestLuaOperation.testfunc3 is nil")
    end
    return length
end

function fun5()
    ios.nslog("dingyuelua --- nslog -- 进入lua脚本方法 fun5 \n")
    
    if TestLuaOperation.testfunc3 then
        print("dingyuelua --- app 扩展方法 - "..tostring(TestLuaOperation.testfunc3().."  \n"))
    else
        print("dingyuelua --- TestLuaOperation.testfunc3 is nil")
    end
    
    if DYLuaModule.dingyueFunc then
        print("dingyuelua --- dingyue 扩展方法 - "..tostring(DYLuaModule.dingyueFunc()))
    else
        print("dingyuelua --- DYLuaModule.dingyueFunc is nil")
    end
end


