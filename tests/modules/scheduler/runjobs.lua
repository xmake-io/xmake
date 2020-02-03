import("private.async.runjobs")

function _jobfunc(index)
end

function main()
    runjobs(_jobfunc, 100, 4)
end

