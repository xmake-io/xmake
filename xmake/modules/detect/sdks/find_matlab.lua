
function _find_matlab()
    local _ret = {}
    local matlabkey = "HKEY_LOCAL_MACHINE\\SOFTWARE\\MathWorks\\MATLAB"
    local valuekeys = winos.registry_keys(matlabkey)
    if #valuekeys == 0 then
        return {}
    end
    local itemkey = valuekeys[1] .. ";MATLABROOT"
    local itemvalue
    try{
        function ()
            itemvalue = winos.registry_query(itemkey)
        end,
        catch{
            function (errors)
                return {}
            end
        }
    }

    _ret.Matlab_FOUND = true
    _ret.Matlab_ROOT_DIR = itemvalue
    _ret.Matlab_INCLUDE_DIRS = path.join(itemvalue,"extern","include")
    -- find lib dirs
    for _,value in ipairs(os.dirs(path.join(itemvalue,"extern","lib","**"))) do
        local dirbasename = path.basename(value)
        if not dirbasename:startswith("win") then
            _ret.MATLAB_LIB_DIRS = _ret.MATLAB_LIB_DIRS or {}
            _ret.MATLAB_LIB_DIRS[dirbasename] = value
        end
    end
    -- find lib
    for _,value in pairs(_ret.MATLAB_LIB_DIRS) do
        _ret.Matlab_LIBRARIES = _ret.Matlab_LIBRARIES or {}
        local dirbasename = path.basename(value)
        _ret.Matlab_LIBRARIES[dirbasename] = {}
        for _,name in ipairs(os.files(value .. "/*.lib")) do
            table.join2(_ret.Matlab_LIBRARIES[dirbasename],path.basename(name))
        end
    end
    return _ret
end

function main(opt)
    local ret = {}
    if os.host() == "windows" then
        ret = _find_matlab()
    end
    return ret
end