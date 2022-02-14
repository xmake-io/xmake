import("net.fasturl")

function mirror(url)
    local configs = {}
    local proxyurls = {"hub.fastgit.xyz"}
    fasturl.add(proxyurls)
    proxyurls = fasturl.sort(proxyurls)
    if #proxyurls > 0 then
        return url:replace("/github.com/", "/" .. proxyurls[1] .. "/", {plain = true})
    end
end

