local proc = ...

function proc.HorizontalRule()
    addline("")
    state.indent = ""
    state.seplevel = -1
end

function proc.Para(s)
    if state.prevtext == "" then state.prevtext = state.indent end
    addlist(justify(walkinline(s.content)))
    state.prevtext = ""
    state.seplevel = 2
end
function proc.Plain(s) proc.Para(s) end
function proc.RawBlock(s) proc.Para(s) end
function proc.Div(s) proc.Para(s) end
function proc.BlockQuote(s) proc.Para(s) end
function proc.LineBlock(ls)
    proc.Para(ls.content:concat('\n'))
end

function proc.CodeBlock(s)
    local pre = state.indent .. string.rep(" ", conf.shiftwidth)
    if state.seplevel == 3 or state.seplevel == 1 or
        state.prevtext ~= "" or #state.buf == 0 then
        state.seplevel = -1  -- The ">" itself is separator
        if state.prevtext == "" then state.prevtext = pre:sub(conf.shiftwidth + 1) end
        addline(state.prevtext .. ">")
        state.prevtext = ""
    else
        state.buf[#state.buf] = state.buf[#state.buf] .. " >"
    end
    state.seplevel = -1
    for ln in (s.text .. "\n"):gmatch("(.-)\n") do
        addline(ln == '' and ln or pre .. ln)
    end
    addline("<")
end

function proc.Header(s)
    if s.level == conf.title_lv then
        s.level = conf.title_lv + 1
        echomsg(msgtype.duptitle)
    end
    assert(state.prevtext == "", "There shouldn't be any text before the title")
    state.indent = ""  -- Headers divide sections and thus clear the indent state
    local origin = walkinline(s.content)
    local text = justify(origin)
    if s.level <= conf.title_lv + 2 then
        addline(string.rep(s.level == conf.title_lv + 1 and "=" or "-",
            conf.textwidth))
        state.seplevel = 0
        table.insert(state.titles, { s.level, origin, s.attr.identifier })
        text[#text] = rightalign(text[#text], "*" .. s.identifier .. "*")
        addlist(text)
        state.seplevel = 3
    elseif s.level == conf.title_lv + 3 then
        text[#text] = text[#text] .. " ~"
        addlist(text)
        state.seplevel = 1
    else  -- May be special
        local id = s.attr.identifier
        repeat
            if #text > 1 then break end
            local line = text[1]
            local name = select(3, line:find("^(:%w+)"))
            if name then
                id = name
                state.indent = string.rep(" ", conf.shiftwidth)
                break
            end
            local name = select(3, line:find("^(%w+)%(.*%)$"))
            if name then
                id = name .. "()"
                state.indent = string.rep(" ", conf.shiftwidth)
                break
            end
        until true
        text[#text] = rightalign(text[#text], "*" .. id .. "*")
        addlist(text)
        state.seplevel = 1
    end
end

function proc.BulletList(s)
    local pre = state.indent .. "* "
    state.indent = state.indent .. "  "
    for _, item in ipairs(s.content) do
        state.prevtext = pre
        walkblock(item)
        if state.seplevel > 0 then state.seplevel = 0 end
    end
    if state.seplevel >= 0 then state.seplevel = 3 end
    state.indent = pre:sub(1, -3)
end

function proc.OrderedList(s)
    local pre = state.indent
    state.indent = state.indent .. string.rep(" ", #s.content + 2)
    for i, item in ipairs(s.content) do
        state.prevtext = pre .. i .. ". "
        walkblock(item)
        if state.seplevel > 0 then state.seplevel = 0 end
    end
    if state.seplevel >= 0 then state.seplevel = 3 end
    state.indent = pre
end

function proc.DefinitionList(s)
    local terms, maxlen = {}, 0
    for _, v in ipairs(s.content) do
        local text = walkinline(v[1])[1]
        table.insert(terms, text)
        if text:len() > maxlen then maxlen = text:len() end
    end
    local pre = state.indent
    state.indent = state.indent .. string.rep(" ", maxlen + 2)
    for i, v in ipairs(s.content) do
        state.prevtext = pre .. terms[i] .. ": "
        for _, item in ipairs(v[2]) do
            walkblock(item)
        end
        if state.seplevel > 0 then state.seplevel = 0 end
    end
    if state.seplevel >= 0 then state.seplevel = 3 end
    state.indent = pre
end

function proc.CaptionedImage(src, tit, caption, attr)
    return caption .. "(" .. src .. ")"
end

function proc.Table(caption, aligns, widths, headers, rows)
    -- TODO: Implement this
    return caption
end

