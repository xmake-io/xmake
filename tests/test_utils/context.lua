import("test_build")
import("test_skip")
import("test_assert")

function main(filename)

    local context = { filename = filename }
    table.join2(context, test_build())
    table.join2(context, test_skip())
    table.join2(context, test_assert())

    return context
end