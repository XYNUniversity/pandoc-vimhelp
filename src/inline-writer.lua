function Space()
    return " "
end

function SoftBreak()
    return " "
end

function LineBreak()
    return "\n"
end

function Str(s) return s end
function Code(s, attr) return s end
function RawInline(fmt, s) return s end
function Span(s) return s end

function Subscript(s)
    echomsg(msgtype.unsupported, "Subscript")
    return s
end
function Superscript(s)
    echomsg(msgtype.unsupported, "Superscript")
    return s
end
function SmallCaps(s)
    echomsg(msgtype.unsupported, "SmallCaps")
    return s
end
function Strikeout(s)
    echomsg(msgtype.unsupported, "Strikeout")
    return s
end
function InlineMath(s)
    echomsg(msgtype.unsupported, "InlineMath")
    return s
end
function DisplayMath(s)
    echomsg(msgtype.unsupported, "DisplayMath")
    return s
end

function Emph(s)
    return "*" .. s .. "*"
end
Strong = Emph

function SingleQuoted(s)
    return "'" .. s .. "'"
end

function DoubleQuoted(s)
    return '"' .. s .. '"'
end

function Link(s, tgt, tit, attr)
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
        if s ~= '' then
            return s .. '(' .. tgt .. ')'
        else
            return tgt
        end
    else
        return s
    end
end

function Image(s, src, tit, attr)
    echomsg(msgtype.unsupported, "image")
    if s ~= '' then return s end
    if tit ~= '' then return tit end
    return src
end

function Note(s)
    return s
end

function Cite(s, cs)
    echomsg(msgtype.unsupported, "cite")
    return s
end

return _G
