--!A cross-platform build utility based on Lua
--
-- priority queue implemented as a binary heap.
-- written by Cosmin Apreutesei. Public Domain.
--
-- @see https://github.com/luapower/heap
--
-- modified by  ruki
-- @file        heap.lua
--

-- define module: heap
local heap  = heap or {}

local ffi --init on demand so that the module can be used without luajit
local assert, floor = assert, math.floor

-- heap algorithm working over abstract API that counts from one.
function heap._make(add, remove, swap, length, cmp)

    local function moveup(child)
        local parent = floor(child / 2)
        while child > 1 and cmp(child, parent) do
            swap(child, parent)
            child = parent
            parent = floor(child / 2)
        end
        return child
    end

    local function movedown(parent)
        local last = length()
        local child = parent * 2
        while child <= last do
            if child + 1 <= last and cmp(child + 1, child) then
                child = child + 1 -- sibling is smaller
            end
            if not cmp(child, parent) then break end
            swap(parent, child)
            parent = child
            child = parent * 2
        end
        return parent
    end

    local function push(...)
        add(...)
        return moveup(length())
    end

    local function pop(i)
        swap(i, length())
        remove()
        movedown(i)
    end

    local function rebalance(i)
        if moveup(i) == i then
            movedown(i)
        end
    end
    return push, pop, rebalance
end

-- cdata heap working over a cdata array
function heap.cdataheap(h)
    ffi = ffi or require("ffi")
    assert(h and h.size, "size expected")
    assert(h.size >= 2, "size too small")
    assert(h.ctype, "ctype expected")
    local ctype = ffi.typeof(h.ctype)
    h.data = h.data or ffi.new(ffi.typeof("$[?]", ctype), h.size)
    local t, n, maxn = h.data, h.length or 0, h.size - 1
    local function add(v) n = n + 1; t[n] = v end
    local function rem() n = n - 1 end
    local function swap(i, j) t[0] = t[i]; t[i] = t[j]; t[j] = t[0] end
    local function length() return n end
    local cmp = h.cmp and
        function(i, j) return h.cmp(t[i], t[j]) end or
        function(i, j) return t[i] < t[j] end
    local push, pop, rebalance = heap._make(add, rem, swap, length, cmp)

    local function get(i, box)
        assert(i >= 1 and i <= n, "invalid index")
        if box then
            box[0] = t[i]
        else
            return ffi.new(ctype, t[i])
        end
    end
    function h:push(v)
        assert(n < maxn, "buffer overflow")
        push(v)
    end
    function h:pop(i, box)
        assert(n > 0, "buffer underflow")
        local v = get(i or 1, box)
        pop(i or 1)
        return v
    end
    function h:peek(i, box)
        return get(i or 1, box)
    end
    function h:replace(i, v)
        assert(i >= 1 and i <= n, "invalid index")
        t[i] = v
        rebalance(i)
    end
    h.length = length
    return h
end

-- value heap working over a Lua table
function heap.valueheap(h)
    h = h or {}
    local t, n = h, #h
    local function add(v) n = n + 1; t[n] = v end
    local function rem() t[n] = nil; n = n - 1 end
    local function swap(i, j) t[i], t[j] = t[j], t[i] end
    local function length() return n end
    local cmp = h.cmp and
        function(i, j) return h.cmp(t[i], t[j]) end or
        function(i, j) return t[i] < t[j] end
    local push, pop, rebalance = heap._make(add, rem, swap, length, cmp)

    local function get(i)
        assert(i >= 1 and i <= n, "invalid index")
        return t[i]
    end
    function h:push(v)
        assert(v ~= nil, "invalid value")
        push(v)
    end
    function h:pop(i)
        assert(n > 0, "buffer underflow")
        local v = get(i or 1)
        pop(i or 1)
        return v
    end
    function h:peek(i)
        return get(i or 1)
    end
    function h:replace(i, v)
        assert(i >= 1 and i <= n, "invalid index")
        t[i] = v
        rebalance(i)
    end
    h.length = length
    return h
end

-- return module: heap
return heap
