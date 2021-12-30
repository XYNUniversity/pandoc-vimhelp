--[[
Things to do:
- [ ] Collect and mark the indents
- [ ] Recognize headers and their indents
- [ ] Mark the blocks followed by a code block
]]--

local proc = {}
local title_lv, blocks = ...
local blockstate = {}
local indent = 0
local firstchild = false

local pindent = 0
local function printblock(bl)
    print('{')
    pindent = pindent + 1
    if bl.tag then
        print(string.rep('  ', pindent) .. "tag=" .. bl.tag)
    end
    for k, v in pairs(bl) do
        io.stdout:write(string.rep('  ', pindent) .. k .. '=')
        if type(v) == type({}) then
            printblock(v)
        else
            print(v)
        end
    end
    pindent = pindent - 1
    print(string.rep('  ', pindent) .. '}')
end

local function walkblock(blocks)
    for _, bl in ipairs(blocks) do
        local fn = proc[bl.tag]
        if not fn then error("No walk function for block: " .. bl.tag) end
        fn(bl)
        firstchild = false
    end
end

local function addstate(stat)
    table.insert(blockstate, stat)
end

function proc.Blocksep() end
function proc.CaptionedImage() end
function proc.Table() end

function proc.HorizontalRule()
    indent = 0
end

function proc.Para()
    addstate {
        indent = indent,
        firstchild = firstchild,
    }
end
proc.Plain, proc.RawBlock, proc.Div, proc.BlockQuote, proc.LineBlock, proc.CodeBlock =
    proc.Para, proc.Para, proc.Para, proc.Para, proc.Para, proc.Para

function proc.BulletList(list)
    local self_first, self_indent = firstchild, indent
    indent = indent + 1
    for _, item in ipairs(list.content) do
        firstchild = true
        walkblock(item)
    end
    if indent > 0 then indent = indent - 1 end
    addstate {
        firstchild = self_first and true or false,
        indent = self_indent,
    }
end
proc.OrderedList = proc.BulletList
function proc.DefinitionList(list)
    -- TODO: Clarify the weird structure of the definition list ><
    local self_first, self_indent = firstchild, indent
    indent = indent + 1
    for _, item in ipairs(list.content) do
        for _, term in ipairs(item[2]) do
            firstchild = true
            walkblock(term)
        end
    end
    if indent > 0 then indent = indent - 1 end
    addstate {
        firstchild = self_first and true or false,
        indent = self_indent,
    }
end

function proc.Header(head)
    if head.level <= title_lv + 3 then
        indent = 0
        addstate {}
        return
    end
    local buffer = {}
    for _, it in ipairs(head.content) do
        -- TODO: do the dispatch
        table.insert(buffer, _G[it.tag](it.text))
    end
    local content = table.concat(buffer, '')
    local target = nil
    local name = select(3, content:find("^(:%w+)"))
    if name then target = name end
    local name = select(3, content:find("^(%w+)%(.*%)$"))
    if name then target = name .. "()" end
    indent = target and 1 or 0
    addstate {
        target = target,
    }
end

walkblock(blocks)

return blockstate

