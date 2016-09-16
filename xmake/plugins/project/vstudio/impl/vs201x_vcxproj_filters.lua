-- importes
import("core.tool.compiler")
import("vsfile")

-- make header
function _make_header(filtersfile, vsinfo, target)
	
	-- the versions
    local versions = 
    {
        vs2010 = '10'
    ,   vs2012 = '11'
    ,   vs2013 = '12'
    ,   vs2015 = '14'
    }

    -- make header
    filtersfile:print("<?xml version=\"1.0\" encoding=\"utf-8\"?>")
    filtersfile:enter("<Project ToolsVersion=\"%s.0\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">", assert(versions["vs" .. vsinfo.vstudio_version]))
end

-- make tailer
function _make_tailer(filtersfile, vsinfo, target)
	filtersfile:leave("</Project>")
end

local include_list = {}
local sources_list = {}
local filters_list = {}

-- add to file list
function _add_to_list(source, list, vcxprojdir)
	table.insert(list, source)
	_add_to_filter(source, vcxprojdir)
end

-- make filters
function _add_to_filter(source, vcxprojdir)

	local filter = path.relative(path.directory(source), "Sources")

	if filters_list[filter] == nil then
		filters_list[filter] = true
	end
end

-- make source list
function _make_source_list(filtersfile, vsinfo, target, vcxprojdir)
	
	for _, includefile in ipairs(target:headerfiles()) do
		_add_to_list(includefile, include_list, vcxprojdir)
	end
	for _, sourcefile in ipairs(target:sourcefiles()) do
		_add_to_list(sourcefile, include_list, vcxprojdir)
	end

	-- and includes
	filtersfile:enter("<ItemGroup>")
		for _, includeFile in ipairs(include_list) do
			filtersfile:enter("<ClInclude Include=\"%s\">", path.relative(includeFile, vcxprojdir))
			filtersfile:print("<Filter>%s</Filter>", path.relative(path.directory(includeFile), "Sources"))
			filtersfile:leave("</ClInclude>")
		end
	filtersfile:leave("</ItemGroup>")

	-- and sources
	filtersfile:enter("<ItemGroup>")
		for _, sourceFile in ipairs(sources_list) do
			filtersfile:enter("<ClCompile Include=\"%s\">", path.relative(sourceFile, vcxprojdir))
			filtersfile:print("<Filter>%s</Filter>", path.relative(path.directory(sourceFile), "Sources"))
			filtersfile:leave("</ClCompile>")
		end
	filtersfile:leave("</ItemGroup>")

	-- add filters
	filtersfile:enter("<ItemGroup>")
		for sourceFile, _ in pairs(filters_list) do
			filtersfile:enter("<Filter Include=\"%s\">", sourceFile)
			filtersfile:print("<UniqueIdentifier>{%s}</UniqueIdentifier>", os.uuid())
			filtersfile:leave("</Filter>")
		end
	filtersfile:leave("</ItemGroup>")
end

-- main filters
function make(vsinfo, target)

	-- the target name
	local targetname = target:name()

	-- the vcxproj directory
	local vcxprojdir = path.join(vsinfo.solution_dir, targetname)

	-- open vcxproj file
	local filtersfile = vsfile.open(path.join(vcxprojdir, targetname .. ".vcxproj.filters"), "w")

	-- init indent character
	vsfile.indentchar('  ')

	-- make header
	_make_header(filtersfile, vsinfo, target)

	-- make source list
	_make_source_list(filtersfile, vsinfo, target, vcxprojdir)

	-- make tailer
	_make_tailer(filtersfile, vsinfo, target)

	-- exit solution file
    filtersfile:close()
end
