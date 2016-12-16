local dict = require "copywriting.dict"
local _M = {}

-- CJK Symbols: E3 80 80 - E3 80 BF
-- Halfwidth and Fullwidth: EF BC 80 - EF BF AF
local function is_chinese_punctuation(word)
    if word:byte(1) == 0xE3 and word:byte(2) == 0x80 then
        local byte = word:byte(3)
        return  0x80 <= byte and byte <= 0xBF
    elseif word:byte(1) == 0xEF then
        local byte = word:byte(2) * 0x100 + word:byte(3)
        return 0xBC80 <= byte and byte <= 0xBFAF
    end
    return false
end

local function wrap_space(text)
    return function(before, match, after)
        before = text:sub(before-1, before-1)
        if before:find('^[^%s%p]') then
            match = ' '..match
        end

        after = text:sub(after, after)
        if after:find('^[^%s%p]') then
            match = match..' '
        end
        return match
    end
end

local function add_space(text)
    -- 不支持用 _xx_ 表示斜体。容易跟代码混淆。
    text = text:gsub('()(*+.-*+)()', wrap_space(text))
    text = text:gsub('()(~~.-~~)()', wrap_space(text))

    -- 断句标点
    text = text:gsub('([^%p])([.,?!;%%]+)(%S)', function(before, punctuation, after)
        if punctuation:sub(-1) == '.' and after:find('^[%d%l%p]') then
            return before .. punctuation .. after
        end
        return before .. punctuation .. ' ' .. after
    end)
    -- 对称操作符
    text = text:gsub('([^%p])(%+)(%S)', '%1 %2 %3')

    local word_pattern = '%w+'
    text = text:gsub('()('..word_pattern..')()', wrap_space(text))

    return text
end

local function replace_word(text)
    return text:gsub('%w+', function(match)
        return dict[match:lower()] or match
    end)
end

local function format(text)
    return replace_word(
           add_space(text))
end

local function trim_right(line)
    return line:gsub('%s+$', '', 1)
end

function _M.format(line)
    -- 避免格式化成有序列表
    if line:find('^%d%.') then
        return line:sub(1, 2) .. _M.format(line:sub(3))
    end
    local links = {}
    line = line:gsub('%[(.+)%]%((.+)%)', function(title, link)
        links[#links + 1] = title
        links[#links + 1] = link
        return  '[]()'
    end)

    local t = {}
    local pattern = "(.-)`"
    local last_part = 1
    local from, to, cap = line:find(pattern, 1)
    local in_inline_code = false
    while from do
        cap = in_inline_code and cap or format(cap)
        t[#t + 1] = cap
        in_inline_code = not in_inline_code
        last_part = to + 1
        from, to, cap = line:find(pattern, last_part)
    end
    if last_part <= #line then
        cap = line:sub(last_part)
        t[#t + 1] = format(cap)
    else
        t[#t + 1] = ''
    end

    line = table.concat(t, '`')
    line = line:gsub('()(`.-`)()', wrap_space(line))

    -- 移除中文标点前的空格
    line = line:gsub('( +)(...)', function(ws, match)
        return is_chinese_punctuation(match) and match or (ws..match)
    end)
     -- 移除中文标点后的多个空格
    line = line:gsub('(...)( +)', function(match, ws)
        return is_chinese_punctuation(match) and match or (match..ws)
    end)

    local i = 1
    line = line:gsub('(%[%]%()%)', function()
        local title = links[i]
        local link = links[i+1]
        i = i + 2
        return '[' .. title .. '](' ..link .. ')'
    end)
    return trim_right(line)
end

function _M.run(filename)
    local output = {}

    local in_code_block = false
    local sentences_block = {}
    local action
    for line in io.lines(filename) do
        if line:sub(1, 3) == '```' then
            in_code_block = not in_code_block
        end

        if in_code_block or line == '' or line:sub(1, 4) == '    ' or
                line:find('^[>\t]') or line:find('^```') then
            action = 'ignore'
        elseif line:find('^%s*[*+%d#=%-!\\[]') then
            action = 'format'
        else
            -- 支持跨行的内联代码
            action = 'append'
        end

        if action ~= 'append' then
            if next(sentences_block) then
                output[#output + 1] = _M.format(table.concat(sentences_block, '\n'))
                sentences_block = {}
            end
            if action == 'format' then
                output[#output + 1] = _M.format(line)
            else
                output[#output + 1] = trim_right(line)
            end
        else
            sentences_block[#sentences_block + 1] = trim_right(line)
        end
    end
    if next(sentences_block) then
        output[#output + 1] = _M.format(table.concat(sentences_block, '\n'))
    end

    return table.concat(output, '\n') .. '\n'
end

return _M
