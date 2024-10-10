function printFunctions()
    print("Defined functions in script:")
    for name, value in pairs(_G) do
        if type(value) == "function" then
            print(name)
        end
    end
end

function fun4()
    if ios then
        ios.nslog("lua -- enter fun4")
    else
        print("Error: 'ios' is nil in fun4.")
    end
    
    local str = fun3() -- 确保 fun3 也存在并返回一个有效值
    if str then
        local length = ios.foundation_nsstring_length(str)
        print("lua -- The length of NSString object is "..tostring(length))
        
        if TestLuaOperation.testfunc3 then
            print("lua -- app extension - "..tostring(TestLuaOperation.testfunc3()))
        else
            print("lua -- TestLuaOperation.testfunc3 is nil")
        end
        return length
    else
        print("Error: fun3 returned nil.")
        return nil
    end
end
function fun5()
    if ios then
        ios.nslog("dingyuelua --- nslog -- 进入lua脚本方法 fun5 \n")
    else
        print("Error: 'ios' is nil in fun5.")
    end

    if TestLuaOperation.testfunc3 then
        -- 调用 testfunc3，并收集所有返回值
        local result1, result2, result3 = TestLuaOperation.testfunc3()
        
        -- 打印所有返回值
        print("dingyuelua --- app 扩展方法 - ", result1, result2, result3)
    else
        print("dingyuelua --- TestLuaOperation.testfunc3 is nil")
    end
    
    if DYLuaModule.dingyueFunc then
        print("dingyuelua --- dingyue 扩展方法 - "..tostring(DYLuaModule.dingyueFunc()))
    else
        print("dingyuelua --- DYLuaModule.dingyueFunc is nil")
    end
end
