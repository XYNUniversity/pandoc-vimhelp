-- {{{1 Global imports, conf and state
local stringify = (require "pandoc.utils").stringify
local selfdir = string.match(PANDOC_SCRIPT_FILE, "^(.+)/[^/]+$")
selfdir = selfdir and selfdir .. '/' or ''
local meta, blocks = PANDOC_DOCUMENT.meta, PANDOC_DOCUMENT.blocks

local proc = { share = {} }

-- Default value of the configuration
local conf = {
    filename = (PANDOC_STATE.output_file or ''):match("[^/]+$"),
    introtitle = "Intro",
    description = nil,
    textwidth = 78,
    shiftwidth = 4,
    ambiwidth = nil,
    rtl = nil,
}
proc.share.conf = conf

-- States
local state = {
    titles = {},
    buf = {},
    indent = "",
    prevtext = "",
    -- -1: Absolutely not needed: there is separator already
    -- 0: no need, generally
    -- 1: no need, but don't add any elimination after the line
    -- 2: need, but it can be eliminated if there's alternative
    -- 3: there must be a separator
    seplevel = 0,
}
proc.share.state = state

-- Load the actual writers
do
    loadfile(selfdir .. "src/helpers.lua")(proc)
    local shared = {}
    for k, v in pairs(_ENV) do shared[k] = v end
    for k, v in pairs(proc.share) do shared[k] = v end
    loadfile(selfdir .. "src/inlines.lua", "bt", shared)(proc)
    loadfile(selfdir .. "src/blocks.lua", "bt", shared)(proc)
end

-- {{{1 Whole document
local function collecttoc()
    local strwidth = proc.share.strwidth
    local buffer = {}
    -- Collect the max level
    local lv = 0
    for _, title in ipairs(state.titles) do
        if title[1] == conf.title_lv + 1 then lv = lv + 1 end
    end
    local titlelen = tostring(lv):len()
    -- Make the TOC
    local lv, sublv = 0, 0
    for _, title in ipairs(state.titles) do
        local dep, text, href = table.unpack(title)
        if dep == conf.title_lv + 1 then
            lv = lv + 1
            sublv = 0
            state.prevtext = tostring(lv) .. ". "
        else
            sublv = sublv + 1
            state.prevtext = string.rep(" ", titlelen + 2) ..
                tostring(lv) .. "." .. tostring(sublv) .. ". "
        end
        state.indent = string.rep(" ", state.prevtext:len())
        text = proc.share.justify(text)
        text[#text] = proc.share.rightalign(text[#text], "|" .. href .. "|")
        table.insert(buffer, table.concat(text, "\n"))
    end
    return table.concat(buffer, '\n')
end

-- Proc the whole document
function Doc(_, metadata, variables)
    -- Resolve the conf
    for _, item in ipairs({
            "filename", "introtitle", "description", "textwidth", "shiftwidth",
            "ambiwidth", "rtl",
        }) do
        if meta[item] then
            conf[item] = table.concat(proc.share.justify(proc.share.walkinline(meta[item])), " ")
            if item == "textwidth" or item == "shiftwidth" then
                conf[item] = tonumber(conf[item])
            end
        elseif variables[item] then
            conf[item] = variables[item]
        end
    end
    conf.title_lv = meta.title and 0 or 1

    -- Process the intro section
    local headerid
    local first_elem = blocks[conf.title_lv + 1]
    -- Has intro section
    if not first_elem or first_elem.tag ~= "Header" or first_elem.level ~= conf.title_lv + 1 then
        local titletext
        if conf.title_lv == 0 then  -- In metadata, need to parse it manually >_<
            -- TODO: change to pandoc.write(...markdown) when it's available
            headerid = pandoc.read("# " .. pandoc.utils.stringify(meta.title, "markdown")).
                blocks[1].attr.identifier
            item = pandoc.Header(1, {pandoc.Str(conf.introtitle)})
            item.attr.identifier = headerid
            table.insert(blocks, 1, item)
        else
            assert(blocks[1].tag == "Header" and blocks[1].level == 1,
                "The first element must be title")
            headerid = blocks[1].attr.identifier
            blocks[1].level = 2
            blocks[1].content = {pandoc.Str(conf.introtitle)}
        end
    end

    proc.share.walkblock(blocks)
    if not meta.raw then
        local modeline = " vim:ft=help:" .. "tw=" .. conf.textwidth .. ":"
        if conf.rtl ~= nil then
            modeline = modeline .. (conf.rtl and "" or "no") .. "rl:"
        end
        if conf.ambiwidth ~= nil then
            modeline = modeline .. "ambiwidth=" .. conf.ambiwidth .. ":"
        end
        state.buf = {
            string.format("*%s* %s", conf.filename or (headerid .. ".txt"),
                conf.description or ""),
            "",
            proc.share.rightalign("CONTENTS", "*" .. headerid .. "-contents*"),
            "",
            collecttoc(),
            "",
            table.concat(state.buf, "\n"),
            "",
            "",
            modeline,
        }
    end
    return table.concat(state.buf, "\n") .. "\n"
end

-- Provide interface and check for undefined items
setmetatable(_G, {
    __index = function(self, key)
        if not proc[key] and key ~= "Blocksep" then
            io.stderr:write(string.format("WARNING: Undefined function '%s'\n",key))
            io.stderr:write(debug.traceback() .. "\n")
        end
        self[key] = function() return "" end
        return self[key]
    end,
})
-- vim: fdm=marker
