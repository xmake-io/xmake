local test_skip = { _is_skipped_tag = {true} }

function test_skip:skip(reason)
    return { is_skipped = self._is_skipped_tag, reason = reason, context = self }
end

function test_skip:is_skipped(result)
    return result and result.context and result.context._is_skipped_tag == result.is_skipped
end

function main()
    return test_skip
end