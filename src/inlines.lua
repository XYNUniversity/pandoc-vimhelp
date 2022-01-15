local proc = ...

local function surroundwith(inner, ch)
    inner[1] = ch .. inner[1] .. ch
    table.insert(inner, 2, strwidth(ch))
    table.insert(inner, strwidth(ch))
    return inner
end

function proc.Space() return { "", "space" } end
function proc.SoftBreak() return { "", "space" } end
function proc.LineBreak() return { "", "nl" } end

function proc.Str(s)
    local res = { s.text }
    for word in (s.text .. '-'):gmatch("([^%p]-[%p])") do
        table.insert(res, word:len())
    end
    res[#res] = res[#res] - 1
    return res
end

function proc.Code(s, attr)
    return { s.text, s.text:len() }
end

function proc.Span(s)
    return walkinline(s.content)
end

function proc.RawInline(s) return proc.Str(s) end

function proc.Emph(s) return surroundwith(walkinline(s.content), "*") end
function proc.Strong(s) return surroundwith(walkinline(s.content), "*") end
function proc.SingleQuoted(s) return surroundwith(walkinline(s.content), "'") end
function proc.DoubleQuoted(s) return surroundwith(walkinline(s.content), '"') end

function proc.Subscript(s)
    echomsg(msgtype.unsupported, "Subscript")
    return proc.Span(s)
end
function proc.Superscript(s)
    echomsg(msgtype.unsupported, "Superscript")
    return proc.Span(s)
end
function proc.SmallCaps(s)
    echomsg(msgtype.unsupported, "SmallCaps")
    return proc.Span(s)
end
function proc.Strikeout(s)
    echomsg(msgtype.unsupported, "Strikeout")
    return proc.Span(s)
end
function proc.InlineMath(s)
    echomsg(msgtype.unsupported, "InlineMath")
    return proc.Str(s)
end
function proc.DisplayMath(s)
    echomsg(msgtype.unsupported, "DisplayMath")
    return proc.Str(s)
end

function proc.Link(s)
    local tgt = s.target
    if tgt ~= '' then
        if tgt:find('^#') then tgt = tgt:sub(2, -1) end
        tgt = string.gsub(tgt, "%%([0-9a-fA-F][0-9a-fA-F])",
            function (c) return string.char(tonumber("0x" .. c)) end)
        local function surrounded(pat)
            local patlen = pat:len()
            return patlen * 2 <= tgt:len() and tgt:sub(1, patlen) == pat and
                tgt:sub(-patlen, -1) == pat
        end
        if surrounded("'") or surrounded("`") or surrounded("|") or tgt:find("^https?://") then
        else
            tgt = '|' .. tgt .. '|'
        end
        local res = walkinline(s.content)
        if res[1] ~= '' then
            res[1] = res[1] .. "(" .. tgt .. ")"
            table.move({ 1, tgt:len(), 1 }, 1, 3, #res + 1, res)
            return res
        else
            return { tgt, tgt:len() }
        end
    else
        return walkinline(s.content)
    end
end

function proc.Image(s, src, tit, attr)
    echomsg(msgtype.unsupported, "image")
    if s ~= '' then return proc.Str(s) end
    if tit ~= '' then return proc.Str(tit) end
    return proc.Str(src)
end

function proc.Note(s)
    return proc.Str(s)
end

function proc.Cite(s, cs)
    echomsg(msgtype.unsupported, "cite")
    return proc.Str(s)
end

