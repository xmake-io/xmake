import("core.base.graph")

function test_topo_sort(t)
    local edges = {
        {0, 5},
        {0, 2},
        {0, 1},
        {3, 6},
        {3, 5},
        {3, 4},
        {5, 4},
        {6, 4},
        {6, 0},
        {3, 2},
        {1, 4},
    }
    local dag = graph.new(true)
    for _, e in ipairs(edges) do
        dag:add_edge(e[1], e[2])
    end
    local order_path = dag:topo_sort()
    local orders = {}
    for i, v in ipairs(order_path) do
        orders[v] = i
    end
    for _, e in ipairs(edges) do
        t:require(orders[e[1]] < orders[e[2]])
    end

    dag = dag:reverse()
    order_path = dag:topo_sort()
    orders = {}
    for i, v in ipairs(order_path) do
        orders[v] = i
    end
    for _, e in ipairs(edges) do
        t:require(orders[e[1]] > orders[e[2]])
    end
end

function test_paritail_topo_sort(t)
    local function partiail_topo_sort(dag)
        dag:partial_topo_sort_reset()

        local node, has_cycle
        local order_vertices = {}
        while true do
            node, has_cycle = dag:partial_topo_sort_next()
            if node == nil or has_cycle then
                break
            end
            table.insert(order_vertices, node)
            if node then
                dag:partial_topo_sort_remove(node)
            end
        end

        return order_vertices, has_cycle
    end

    local edges = {
        {0, 5},
        {0, 2},
        {0, 1},
        {3, 6},
        {3, 5},
        {3, 4},
        {5, 4},
        {6, 4},
        {6, 0},
        {3, 2},
        {1, 4},
    }
    local dag = graph.new(true)
    for _, e in ipairs(edges) do
        dag:add_edge(e[1], e[2])
    end
    local order_path = partiail_topo_sort(dag)
    local orders = {}
    for i, v in ipairs(order_path) do
        orders[v] = i
    end
    for _, e in ipairs(edges) do
        t:require(orders[e[1]] < orders[e[2]])
    end

    dag = dag:reverse()
    order_path = partiail_topo_sort(dag)
    orders = {}
    for i, v in ipairs(order_path) do
        orders[v] = i
    end
    for _, e in ipairs(edges) do
        t:require(orders[e[1]] > orders[e[2]])
    end
end


function test_find_cycle(t)
    local edges = {
        {9, 1},
        {1, 6},
        {6, 0},
        {0, 1},
        {4, 5}
    }
    local dag = graph.new(true)
    for _, e in ipairs(edges) do
        dag:add_edge(e[1], e[2])
    end
    local cycle = dag:find_cycle()
    t:are_equal(cycle, {1, 6, 0})

    local _, has_cycle = dag:topo_sort()
    t:require(has_cycle)
end

