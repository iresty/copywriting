local _M = {}

local function add_space(text)
    local in_asterisk = false
    local in_wave = false
    -- 不支持用 _xx_ 表示斜体。容易跟代码混淆。
    text = text:gsub('([^%p])(*+)(.?)', function(before, punctuation, after)
        in_asterisk = not in_asterisk
        if in_asterisk then
            before = before:find('%s') and before or (before .. ' ')
            return before .. punctuation .. after
        end
        if #after > 0 and not after:find('%s') then
            after = ' ' .. after
        end
        return before .. punctuation .. after
    end)
    text = text:gsub('([^%p])(~~)(.?)', function(before, punctuation, after)
        in_wave = not in_wave
        if in_wave then
            before = before:find('%s') and before or (before .. ' ')
            return before .. punctuation .. after
        end
        if #after > 0 and not after:find('%s') then
            after = ' ' .. after
        end
        return before .. punctuation .. after
    end)
    text = text:gsub('([^%p])([.,?!;%%+/]+)(%S)', function(before, punctuation, after)
        if punctuation:sub(-1) == '.' and after:find('[%d%l]') then
            return before .. punctuation .. after
        end

        if punctuation:sub(1, 1) == '*' then
            in_asterisk = not in_asterisk
            if in_asterisk then
                before = before:find('%s') and before or (before .. ' ')
                return before .. punctuation .. after
            end
        end
        if punctuation:sub(1, 2) == '~~' then
            in_wave = not in_wave
            if in_wave then
                before = before:find('%s') and before or (before .. ' ')
                return before .. punctuation .. after
            end
        end
        return before .. punctuation .. ' ' .. after
    end)

    local word_pattern = '%w+%s?%w+'
    -- TODO lua正则不支持unicode range，如果想用码表，需要用string.byte获取大小并判断
    local chinese_punctuation = '。，！？；……（）“”'
    text = text:gsub('^('..word_pattern..')([^%s%w%p'..chinese_punctuation..'])', '%1 %2')
    text = text:gsub('([^%s%w%p])('..word_pattern..')$', '%1 %2')
    return text:gsub('([^%s%w%p])('..word_pattern..')([^%s%w%p])', '%1 %2 %3')
end

function _M.format(line)
    -- 避免格式化成有序列表
    if line:find('^%d%.') then
        return line:sub(1, 2) .. _M.format(line:sub(3))
    end

    local t = {}
    local pattern = "(.-)`"
    local last_part = 1
    local from, to, cap = line:find(pattern, 1)
    local in_inline_code = false
    while from do
        cap = in_inline_code and cap or add_space(cap)
        t[#t + 1] = cap
        in_inline_code = not in_inline_code
        last_part = to + 1
        from, to, cap = line:find(pattern, last_part)
    end
    if last_part <= #line then
        cap = line:sub(last_part)
        t[#t + 1] = add_space(cap)
    else
        t[#t + 1] = ''
    end
    return table.concat(t, '`')
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

        if in_code_block or #line == 0 or line:sub(1, 4) == '    ' or line:sub(1, 1) == '\t' then
            action = 'ignore'
        elseif line:find('^%s*[*+%d#=->!\\[]') then
            -- 支持跨行的内联代码
            action = 'append'
        else
            action = 'format'
        end

        if action ~= 'append' then
            if #sentences_block > 0 then
                output[#output + 1] = _M.format(table.concat(sentences_block, '\n'))
                sentences_block = {}
            end
            if action == 'format' then
                output[#output + 1] = _M.format(line)
            else
                output[#output + 1] = line
            end
        else
            sentences_block[#sentences_block + 1] = line
        end
    end
    if #sentences_block > 0 then
        output[#output + 1] = _M.format(table.concat(sentences_block, '\n'))
    end

    return table.concat(output, '\n')
end

return _M
