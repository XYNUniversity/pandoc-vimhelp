-- {{{1 Helpers
local pipe = pandoc.pipe
local stringify = (require "pandoc.utils").stringify
local selfdir = string.match(PANDOC_SCRIPT_FILE, "^(.+)/[^/]+$")
dofile(selfdir .. "/src/inline-writer.lua")

local meta, blocks = PANDOC_DOCUMENT.meta, PANDOC_DOCUMENT.blocks
local filename = meta.filename or (PANDOC_STATE.output_file or ''):match("[^/]+$")
local title_lv = meta.title and 0 or 1
local textwidth = meta.textwidth or 78
local ambiwidth = meta.ambiwidth
local rtl = meta.rtl
local indentstr = meta.indentstr or '    '

msgtype = {
    unsupported = "Unsupported feature in vim help: %s",
    duplicate = "Duplicate %s",
    latetitle = "Document title after content",
}
-- Pring warning and error messages
function echomsg(kind, ...)
    io.stderr:write('[Warning] ' .. kind:format(...) .. '\n')
end

local blockstate = loadfile(selfdir .. "/src/filter.lua")(title_lv, PANDOC_DOCUMENT.blocks)
local stateid = 0

-- Calculate the displayed width of s in vim
local function strwidth(s)
    local res = 0
    for _, c in utf8.codes(s) do
        -- TODO: recognize East Asian chars to multiply its width
        res = res + 1
    end
    return res
end

-- Add indent according to nesting level and break lines
local function justify(s)
    local buffer = {}
    if s:sub(-1) ~= "\n" then s = s .. "\n" end
    local pre = indentstr:rep(blockstate[stateid].indent)
    local prelen = pre:len()
    for line in s:gmatch("(.-)\n") do
        local curbuf = { pre }
        local len = prelen
        line = line .. " "
        for word in line:gmatch("(.-[-%s%p]+)") do
            local curlen = word:len()
            if len + curlen > textwidth then
                table.insert(buffer, table.concat(curbuf, ""))
                curbuf = { pre, word }
                len = curlen + prelen
            else
                table.insert(curbuf, word)
                len = len + curlen
            end
        end
        if #curbuf > 0 then
            table.insert(buffer, table.concat(curbuf, ""))
        end
    end
    s = table.concat(buffer, "\n")
    if blockstate[stateid].firstchild then s = s:sub(prelen + 1) end
    return s
end

-- Local states
local titles = {}

-- {{{1 Whole document
local function collecttoc()
    local buffer = {}
    local lv, sublv = 0, 0
    for _, title in ipairs(titles) do
        local dep, text, href = table.unpack(title)
        local line = ''
        if dep == title_lv + 1 then
            lv = lv + 1
            sublv = 0
            line = line .. tostring(lv) .. ". "
        else
            sublv = sublv + 1
            line = line .. indentstr .. tostring(lv) .. "." .. tostring(sublv) .. ". "
        end
        line = line .. text
        line = line .. string.rep(' ', textwidth - strwidth(line) - strwidth(href) - 2) .. "|" .. href .. "|"
        table.insert(buffer, line)
    end
    return table.concat(buffer, '\n')
end

local function genmodeline()
    local res = " vim:ft=help:" .. "tw=" .. textwidth .. ":"
    if rtl ~= nil then
        res = res .. (rtl and "" or "no") .. "rl:"
    end
    if ambiwidth ~= nil then
        res = res .. "ambiwidth=" .. ambiwidth .. ":"
    end
    return res
end

local function procintro(body, headerid)
    if title_lv == 0 and (not blocks[1] or blocks[1].tag == "Header" and blocks[1].level == 1)
        or title_lv == 1 and (not blocks[1] or not blocks[2]
            or blocks[2].tag == "Header" and blocks[1].level == 2)
        then
        return body
    end
    body = Header(title_lv + 1, "Intro", { id = headerid }) .. Blocksep() .. body
    local totlen = #titles
    table.insert(titles, 1, titles[totlen])
    table.remove(titles, totlen + 1)
    return body
end

function Doc(body, metadata, variables)
    local buffer = {}
    local function add(s)
        table.insert(buffer, s)
    end
    local headerid = pandoc.read('# ' .. pandoc.utils.stringify(meta.title)).
        blocks[1].attr.identifier
    body = procintro(body, headerid)
    if meta.raw then
        add(body)
    else
        add(string.format("*%s* %s", filename or (headerid .. ".txt"),
            metadata.description or variables.description or ''))
        add("")
        add(string.format("CONTENTS%s*%s-contents*",
            string.rep(' ', textwidth - string.len("CONTENTS*-contents*") - strwidth(headerid)),
        headerid))
        add("")
        add(collecttoc())
        add("")
        add(body)
        add("")
        add("")
        add(genmodeline())
    end
    return table.concat(buffer,'\n') .. '\n'
end

-- {{{1 Block elements
function Blocksep()
    return "\n\n"
end

function Para(s)
    stateid = stateid + 1
    return justify(s)
end
function Plain(s) return Para(s) end
function RawBlock(format, str) return Para(str) end
function Div(s, attr) return Para(s) end
function BlockQuote(s) return Para(s) end
function LineBlock(ls)
    return Para(ls:concat('\n'))
end

function HorizontalRule()
    return ""
end

function CodeBlock(s, attr)
    stateid = stateid + 1
    local pre = indentstr:rep(blockstate[stateid].indent + 1)
    local buffer = {}
    s = s .. "\n"
    for ln in s:gmatch("(.-)\n") do
        table.insert(buffer, ln == '' and ln or pre .. ln)
    end
    return indentstr:rep(blockstate[stateid].indent) .. ">\n" ..
        table.concat(buffer, '\n') .. "\n<"
end

-- lev is an integer, the header level.
function Header(lv, s, attr)
    stateid = stateid + 1
    local res = ''
    -- Title itself
    if lv == title_lv then
        if meta.title then
            echomsg(msgtype.duplicate, "titles")
        else
            meta.title = s
        end
        return ''
    elseif lv <= title_lv + 2 then
        res = res .. (lv == title_lv + 1 and '=' or '-'):rep(textwidth) .. '\n' .. s
    elseif lv == title_lv + 3 then
        res = res .. s .. " ~"
    else
        res = res .. s
    end
    -- Process the title link
    local id = attr.id
    if lv > title_lv + 3 then
        id = blockstate[stateid].target or attr.id
    elseif lv <= title_lv + 2 and lv ~= title_lv then
        table.insert(titles, { lv, s, id })
    end
    -- Calculate the length and concat the id
    if lv ~= title_lv and lv ~= title_lv + 3 then
        res = res .. string.rep(' ', textwidth - strwidth(id) - strwidth(s) - 2) ..
            "*" .. id .. "*"
    end
    return res
end

local function do_lists(items, fn)
    stateid = stateid + 1
    local pre = indentstr:rep(blockstate[stateid].indent)
    local buffer = {}
    for i, item in ipairs(items) do
        table.insert(buffer, pre .. fn(item, i))
    end
    return table.concat(buffer, "\n")
end
function BulletList(items)
    return do_lists(items, function(item) return "* " .. item end)
end
function OrderedList(items)
    return do_lists(items, function(item, i) return i .. ". " .. item end)
end
function DefinitionList(items)
    return do_lists(items, function(item)
        local k, v = next(item)
        return k .. ": " .. table.concat(v, '\n')
    end)
end

function CaptionedImage(src, tit, caption, attr)
    return caption .. "(" .. src .. ")"
end

function Table(caption, aligns, widths, headers, rows)
    -- TODO: Implement this
    return caption
end

-- {{{1 Check if writer is vaild
local meta = {}
meta.__index = function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
    return function() return "" end
end
setmetatable(_G, meta)
-- vim: fdm=marker
