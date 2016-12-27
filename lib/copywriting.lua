local dict = require "copywriting.dict"
local _M = {}

-- General Punctuation: E2 80 80 - E2 81 AF for example, “”
-- CJK Symbols: E3 80 80 - E3 80 BF
-- Halfwidth and Fullwidth: EF BC 80 - EF BF AF
local function is_chinese_punctuation(word)
    if word == nil or #word ~= 3 then
        return false
    end
    if word:byte(1) == 0xE2 then
        local byte = word:byte(2) * 0x100 + word:byte(3)
        return 0x8080 <= byte and byte <= 0x81AF
    elseif word:byte(1) == 0xE3 and word:byte(2) == 0x80 then
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
        local before_letter = text:sub(before-1, before-1)
        if before_letter:find('^[^%s%p]') and
                not is_chinese_punctuation(text:sub(before-3, before-1)) then
            match = ' '..match
        end

        local after_letter = text:sub(after, after)
        if after_letter:find('^[^%s%p]') and
                not is_chinese_punctuation(text:sub(after, after+2)) then
            match = match..' '
        end
        return match
    end
end

local function add_space(text)
    -- 不支持用 _xx_ 表示斜体。容易跟代码混淆。
    text = text:gsub('()(*+.-*+)()', wrap_space(text))
    text = text:gsub('()(~~.-~~)()', wrap_space(text))
    text = text:gsub('()(".-")()', wrap_space(text))
    text = text:gsub("()('.-')()", wrap_space(text))

    -- 需要在前面加空格的特殊符号
    text = text:gsub('()([$])', function(before, punctuation)
        if before == 1 or text:sub(before-1, before-1):find('^%s') then
            return punctuation
        end
        return ' '..punctuation
    end)

    -- 断句标点
    text = text:gsub('([^%p])([.,?!;%%]+)([^%p%s])', function(before, punctuation, after)
        if punctuation:sub(-1) == '.' and after:find('^[%d%l%p]') then
            return before .. punctuation .. after
        end
        return before .. punctuation .. ' ' .. after
    end)

    -- 对称操作符
    text = text:gsub('([^%p%s])(%+)([^%p%s])', '%1 %2 %3')
    -- 专门针对 C++ 这个词的规则（C++ 后面插入个空格)
    text = text:gsub('(%w)(%++)([^%p%s])', '%1%2 %3')

    local word_pattern = '%w+'
    text = text:gsub('()('..word_pattern..')()', wrap_space(text))

    return text
end

local function replace_word(text)
    return text:gsub('[%w_%-%.]+', function(match)
        return dict[match:lower()] or match
    end)
end

local function format(text)
    -- 格式化时，跳过文本中的超链接
    -- 只支持 http 链接。链接中不支持中文，以免跟链接后面的中文混淆
    local placeholder = {}
    for i = 1, 32 do
        placeholder[i] = string.char(math.random(97, 122))
    end
    placeholder = table.concat(placeholder)

    local links = {}
    local i = 1
    text = text:gsub("https?://[%w%-%%&?$_,.+!*'()/#]+", function(match)
        links[i] = match
        i = i + 1
        return placeholder
    end)

    text = replace_word(add_space(text))

    i = 0
    text = text:gsub(placeholder, function()
        i = i + 1
        return links[i]
    end)
    return text
end

local function trim_right(line)
    return line:gsub('%s+$', '', 1)
end

function _M.format(line)
    -- 避免格式化成有序列表
    local from, to = line:find('^%d%.%s*')
    if from then
        return line:sub(from, to) .. _M.format(line:sub(to+1))
    end
    local links = {}
    local i = 1
    -- 保护链接文本
    line = line:gsub('%[(.-)%]%((.-)%)', function(title, link)
        links[i] = title
        links[i+1] = link
        i = i + 2
        return  '[]()'
    end)

    -- 保护内联代码
    local t = {}
    local pattern = "(.-)`"
    local last_part = 1
    local cap
    from, to, cap = line:find(pattern, 1)
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
        t[#t+1] = format(cap)
    else
        t[#t+1] = ''
    end

    line = table.concat(t, '`')
    -- 给内联代码围上空白
    line = line:gsub('()(`.-`)()', wrap_space(line))

    -- 恢复链接文本
    i = 1
    line = line:gsub('(%[%]%()%)', function()
        local title = format(links[i])
        local link = links[i+1]
        i = i + 2
        return '[' .. title .. '](' ..link .. ')'
    end)

    -- 移除中文标点前的空格
    line = line:gsub('()( +)(...)', function(left_pos, ws, match)
        if not is_chinese_punctuation(match) then
            return ws .. match
        end
        -- 防止移除空格后，破坏无序列表的格式
        local left_neighbor = line:sub(left_pos-1, left_pos-1)
        if left_pos == 2 and left_neighbor:find('^[+%-*]') then
            return ' ' .. match
        end
        return match
    end)
     -- 移除中文标点后的多个空格
    line = line:gsub('(...)( +)', function(match, ws)
        return is_chinese_punctuation(match) and match or (match..ws)
    end)

    return trim_right(line)
end

function _M.run(filename)
    local output = {}

    local in_code_block = false
    local in_table_head = false
    local in_table_body = false
    local sentences_block = {}
    local action
    for line in io.lines(filename) do
        if line:sub(1, 3) == '```' then
            in_code_block = not in_code_block
        end

        -- ignore table
        --[[
        First Header | Second Header <- in_table_head
        ------------ | ------------- <- in_table_body
        cell 1 | cell 2              <- in_table_body
        first column | second column <- in_table_body
        --]]
        if not line:find('.+|') then
            in_table_body = false
        elseif not (in_table_body or next(sentences_block)) then
            in_table_head = true
        end
        if in_table_head and line:find('--.*|') then
            in_table_body = true
            in_table_head = false
        end

        if in_code_block or in_table_head or in_table_body or
                line == '' or line:sub(1, 4) == '    ' or
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
