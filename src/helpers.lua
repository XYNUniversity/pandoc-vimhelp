local proc = ...
local share = proc.share
local conf = share.conf
local state = share.state

share.msgtype = {
    unsupported = "Unsupported feature in vim help: %s",
    duptitle = "Title header duplicated",
}
-- Pring warning and error messages
function share.echomsg(kind, ...)
    io.stderr:write('[Warning] ' .. kind:format(...) .. '\n')
end

-- Calculate the displayed width of s in vim
function share.strwidth(s)
    local res = 0
    for _, c in utf8.codes(s) do
        -- TODO: recognize East Asian chars to multiply its width
        res = res + 1
    end
    return res
end

-- Add line (may include other lines) into state buffer
function share.addline(s)
    if state.seplevel > 1 then
        table.insert(state.buf, "")
    end
    table.insert(state.buf, s)
end
-- Add some lines into state buffer
function share.addlist(ls)
    share.addline(ls[1])
    table.move(ls, 2, #ls, #state.buf + 1, state.buf)
end

-- Walk a list of blocks and append result into buf
function share.walkblock(bl)
    for _, v in ipairs(bl) do
        proc[v.tag](v)
    end
end
-- Collect a list of inlines into a string and some delims
function share.walkinline(bl)
    local buf, delim = {}, {}
    for _, v in ipairs(bl) do
        local cur = proc[v.tag](v)
        table.insert(buf, cur[1])
        table.move(cur, 2, #cur, #delim + 1, delim)
    end
    return { table.concat(buf, ""), table.unpack(delim) }
end

-- Justify the block into textwidth, adding indent, respect
function share.justify(bl)
    local text, delim = bl[1], {table.unpack(bl, 2)}
    local prev, prevlen = state.prevtext, state.prevtext:len()
    local last, spaced = 1, false
    local buffer = {}
    local function pushprev(cur)
        table.insert(buffer, prev)
        prev = state.indent .. cur
        prevlen = state.indent:len() + cur:len()
    end
    for _, len in ipairs(delim) do
        if len == "space" then
            spaced = true
        elseif len == "nl" then
            pushprev("")
            spaced = false
        else
            local cur = text:sub(last, last + len - 1)
            last = last + len
            if spaced then len = len + 1 end
            if prevlen + len > conf.textwidth then
                pushprev(cur)
            else
                prev = prev .. (spaced and " " or "") .. cur
                prevlen = prevlen + len
            end
            spaced = false
        end
    end
    if prev ~= state.indent then pushprev("") end
    return buffer
end

-- Add right aligned text into the line
function share.rightalign(origin, text)
    if origin:len() + text:len() > conf.textwidth then
        return origin .. "\n" .. string.rep(" ", conf.textwidth - text:len()) .. text
    else
        return origin .. string.rep(" ", conf.textwidth - text:len() - origin:len()) .. text
    end
end

-- Debug helper
function share.printblock(bl, indent)
    if not indent then indent = 0 end
    print("{")
    indent = indent + 1
    if bl.tag then
        print(string.rep("  ", indent) .. "tag=" .. bl.tag)
    end
    for k, v in pairs(bl) do
        io.stdout:write(string.rep("  ", indent) .. k .. "=")
        if type(v) == type({}) then
            printblock(v)
        else
            print(v)
        end
    end
    indent = indent - 1
    print(string.rep("  ", indent) .. "}")
end

