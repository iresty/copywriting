local copywriting = require "copywriting"
local run = copywriting.run

-- http://lua-users.org/wiki/SplitJoin
local function split(text, separator)
   local parts = {}
   local start = 1
   local split_start, split_end = text:find(separator, start)
   while split_start do
      table.insert(parts, text:sub(start, split_start-1))
      start = split_end + 1
      split_start, split_end = text:find(separator, start)
   end
   if text:sub(start)~="" then
      table.insert(parts, text:sub(start) )
   end
   return parts
end

describe('format file', function()
    it('ignore code block', function()
        local expected = split(
[[# 针对中英文混合的 markdown 文档的格式化工具

```
code block不做处理
```

顺带一提的是，并不是所有的 C 标准函数都能满足我们的需求，那么如何使用 *第三方库函数* 或 *自定义的函数* 呢，这会稍微麻烦一点，不用担心，你可以很快学会。: )
首先创建一个 `myffi.c`，其内容是：

 ```c
 ```

语句块中的 `inline
 code也不做处理`
> quote不做处理
]], '\n')
        local actual = split(run('fixture.md'), '\n')
        for i, line in ipairs(actual) do
            assert.are.same(expected[i], line)
        end
    end)
end)

describe('format line', function()
    it('add space between Chinese and English', function()
        assert.are.same('OpenResty 中特定 body 的准入控制',
            copywriting.format('OpenResty中特定body的准入控制'))
        assert.are.same('当你的 API Server 接口服务比较多',
            copywriting.format('当你的API Server接口服务比较多'))
        assert.are.same('在 C 语言中', copywriting.format('在C语言中'))
    end)

    it('add space between Chinese and number', function()
        assert.are.same('2014 年，', copywriting.format('2014年，'))
        assert.are.same('奇虎 360 公司的第 1024', copywriting.format('奇虎360公司的第1024'))
        assert.are.same('2014 年 9 月 12 日', copywriting.format('2014年9月12日'))
    end)

    it('add space after some punctuations if there is no space', function()
        assert.are.same('Moreover, OpenResty support', copywriting.format('Moreover,OpenResty support'))
        assert.are.same('Moreover, OpenResty support', copywriting.format('Moreover, OpenResty support'))
        assert.are.same('50% 的酒精', copywriting.format('50%的酒精'))
        assert.are.same('从 40-60 中', copywriting.format('从 40-60 中'))
        -- 点号后面如果是标点符号、小写字母、数字，不加空格
        assert.are.same([[ffi.\*API]], copywriting.format([[ffi.\*API]]))
        assert.are.same('1.2', copywriting.format('1.2'))
        assert.are.same('fixture.md', copywriting.format('fixture.md'))
    end)

    it('add space around asterisks if there is no space', function()
        assert.are.same('注意 **不要** 修改', copywriting.format('注意 **不要**修改'))
        assert.are.same('注意 *不要* 修改', copywriting.format('注意*不要* 修改'))
        assert.are.same('注意 **不要**', copywriting.format('注意**不要**'))
        assert.are.same('*不要* 修改', copywriting.format('*不要*修改'))
        assert.are.same('**不要** 修改 *这里*', copywriting.format('**不要**修改*这里*'))
    end)

    it('add space around waves if there is no space', function()
        assert.are.same('~~不要~~ 修改', copywriting.format('~~不要~~修改'))
        assert.are.same('注意 ~~不要~~ 修改', copywriting.format('注意~~不要~~修改'))
        assert.are.same('注意 ~~不要~~', copywriting.format('注意~~不要~~'))
        assert.are.same('~~不要~~ 修改', copywriting.format('~~不要~~ 修改'))
        assert.are.same('~~不要~~ 修改 ~~这里~~', copywriting.format('~~不要~~修改~~这里~~'))
    end)

    it('remove extra space before Chinese punctuation', function()
        assert.are.same(
            '加了一些空格，你可以很快学会。: )',
            copywriting.format('加了一些空格 ，你可以很快学会。: )'))
    end)

    it('remove extra space after Chinese punctuation', function()
        assert.are.same(
            '使用 *第三方库函数* 或 *自定义的函数* 呢，你可以很快学会。: )',
            copywriting.format('使用 *第三方库函数* 或 *自定义的函数* 呢，你可以很快学会。 : )'))
    end)

    it('do not add space if there is one', function()
        assert.are.same('特定 body 的准入控制', copywriting.format('特定 body 的准入控制'))
    end)

    it('do not add space before Chinese punctuation', function()
        assert.are.same('OpenResty，是一个 Web 平台', copywriting.format('OpenResty，是一个Web平台'))
        assert.are.same('提供的 GET、POST、PUT 和 DELETE 方法',
            copywriting.format('提供的GET、POST、PUT和DELETE方法'))
    end)

    it('ignore special line-start mark', function()
        assert.are.same('*无序列表', copywriting.format("*无序列表"))
        assert.are.same('+无序列表', copywriting.format("+无序列表"))
        assert.are.same('-无序列表', copywriting.format("-无序列表"))
        assert.are.same('9.有序列表', copywriting.format("9.有序列表"))
        assert.are.same('#标题', copywriting.format("#标题"))
        assert.are.same('>引用', copywriting.format(">引用"))
    end)

    it('ignore inline code', function()
        assert.are.same('支持内联代码片段 `^_^颜文字233`',
            copywriting.format('支持内联代码片段`^_^颜文字233`'))
    end)

    it('trim trailing whitespace', function()
        assert.are.same('HTTP 方法包括以下几种：',
            copywriting.format('HTTP方法包括以下几种：  '))
    end)

    it('keyword replacing', function()
        assert.are.same('Nginx 是一个高性能 Web 服务器，而 OpenResty 不仅仅是 Nginx + Lua',
            copywriting.format('nginx是一个高性能web服务器，而Openresty不仅仅是nginx+lua'))
    end)

    it('ignore links', function()
        assert.are.same('[openresty](指向openresty.org)',
            copywriting.format('[openresty](指向openresty.org)'))
        assert.are.same('![openresty](指向openresty.org)',
            copywriting.format('![openresty](指向openresty.org)'))
    end)

    it('ignore inline code, but add space around them', function()
        assert.are.same('名空间 `ffi.C` 通过', copywriting.format('名空间`ffi.C`通过'))
        assert.are.same('名空间 `ffi.C` 通过', copywriting.format('名空间 `ffi.C`通过'))
        assert.are.same('名空间 `ffi.C` 通过', copywriting.format('名空间`ffi.C` 通过'))
        assert.are.same('名空间 `ffi.C` 通过', copywriting.format('名空间 `ffi.C` 通过'))
        assert.are.same('尤其需要指出的是，`metatable` 与',
            copywriting.format('尤其需要指出的是， `metatable`与'))
        assert.are.same('`cdata` 类型用来将', copywriting.format('`cdata`类型用来将'))
        assert.are.same('元方法 `__index`', copywriting.format('元方法`__index`'))
        assert.are.same('`string` 函数……实际长度将会在 `buflen` 这个数组中返回。',
            copywriting.format("`string`函数……实际长度将会在`buflen`这个数组中返回。"))
    end)

    it('handle partial markdown notation', function()
        assert.are.same('这是*星号', copywriting.format('这是*星号'))
        assert.are.same('哈哈~~哈哈', copywriting.format('哈哈~~哈哈'))
    end)
end)
