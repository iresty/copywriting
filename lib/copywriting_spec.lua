local copywriting = require "copywriting"
local run = copywriting.run
local format = copywriting.format
local function eq(expected, actual)
    assert.are.same(expected, actual)
end

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

- [x] GitHub Flavored Markdown is supported.
- [ ] Support Gitbook's ?

如何处理table  |
--  |
忽略table中的内容 |
| int p |

语句块中的 `inline
 code也不做处理`
> quote不做处理

“PHP 是最好的语言”

pull request : [点击查看](https://gitHub.com/openresty/lua-nginx-module/pull/531)
commit detail: [点击查看](https://github.com/membphis/lua-nginx-module/commit/9d991677c090e1f86fa5840b19e02e56a4a17f86)
]], '\n')
        local actual = split(run('fixture.md'), '\n')
        for i, line in ipairs(actual) do
            eq(expected[i], line)
        end
    end)
end)

describe('format line', function()
    it('add space between Chinese and English', function()
        eq('OpenResty 中特定 body 的准入控制',
            format('OpenResty中特定body的准入控制'))
        eq('当你的 API Server 接口服务比较多',
            format('当你的API Server接口服务比较多'))
        eq('在 C 语言中', format('在C语言中'))
    end)

    it('add space between Chinese and number', function()
        eq('2014 年，', format('2014年，'))
        eq('奇虎 360 公司的第 1024', format('奇虎360公司的第1024'))
        eq('2014 年 9 月 12 日', format('2014年9月12日'))
    end)

    it('but do not add space between Chinese punctuations and number/English', function()
        eq('“1”', format('“1”'))
        eq('“consume”', format('“consume”'))
        eq('（1）', format('（1）'))
        eq('apple、', format('apple、'))
    end)

    it('add space after some punctuations if there is no space', function()
        eq('Moreover, OpenResty support', format('Moreover,OpenResty support'))
        eq('Moreover, OpenResty support', format('Moreover, OpenResty support'))
        eq('50% 的酒精', format('50%的酒精'))
        eq('从 40-60 中', format('从 40-60 中'))
        eq('互联网+ 的新闻', format('互联网+ 的新闻'))
        -- 点号后面如果是标点符号、小写字母、数字，不加空格
        eq([[ffi.\*API]], format([[ffi.\*API]]))
        eq('1.2', format('1.2'))
        eq('fixture.md', format('fixture.md'))
    end)

    it('add space before some punctuations if there is no space', function()
        eq('我们不再尝试使用 if 来判断 $uri 是否存在', format('我们不再尝试使用 if 来判断$uri 是否存在'))
        eq('我们不再尝试使用 if 来判断 $uri 是否存在', format('我们不再尝试使用 if 来判断 $uri 是否存在'))
    end)

    it('do not add space between punctuations', function()
        eq('pos,,', format('pos,,'))
        eq('86.36%(19.0 / (19 + 3))', format('86.36%(19.0 / (19 + 3))'))
    end)

    it('add space around some punctuations pair', function()
        eq('"q" 参数用在 Drupal, Joomla, WordPress', format('"q"参数用在 Drupal, Joomla, WordPress'))
        eq('两个 "light threads" 必须', format('两个"light threads"必须'))
        eq("两个 'light threads' 必须", format("两个'light threads'必须"))
    end)

    it('do not add space around multiple plus punctuations', function()
        eq([[静态语言 C\C++ 和]], format([[静态语言C\C++和]]))
    end)

    it('add space around asterisks if there is no space', function()
        eq('注意 **不要** 修改', format('注意 **不要**修改'))
        eq('注意 *不要* 修改', format('注意*不要* 修改'))
        eq('注意 **不要**', format('注意**不要**'))
        eq('*不要* 修改', format('*不要*修改'))
        eq('**不要** 修改 *这里*', format('**不要**修改*这里*'))
    end)

    it('add space around waves if there is no space', function()
        eq('~~不要~~ 修改', format('~~不要~~修改'))
        eq('注意 ~~不要~~ 修改', format('注意~~不要~~修改'))
        eq('注意 ~~不要~~', format('注意~~不要~~'))
        eq('~~不要~~ 修改', format('~~不要~~ 修改'))
        eq('~~不要~~ 修改 ~~这里~~', format('~~不要~~修改~~这里~~'))
    end)

    it('remove extra space before Chinese punctuation', function()
        eq(
            '加了一些空格，你可以很快学会。: )',
            format('加了一些空格 ，你可以很快学会。: )'))
        eq('“wb”', format('  “wb”'))
    end)

    it('but keep space after special line-start mark', function()
        eq('- “wb”', format('- “wb”'))
        eq('+ “wb”', format('+ “wb”'))
        eq('* “wb”', format('* “wb”'))
    end)

    it('remove extra space after Chinese punctuation', function()
        eq(
            '使用 *第三方库函数* 或 *自定义的函数* 呢，你可以很快学会。: )',
            format('使用 *第三方库函数* 或 *自定义的函数* 呢，你可以很快学会。 : )'))
    end)

    it('do not add space if there is one', function()
        eq('特定 body 的准入控制', format('特定 body 的准入控制'))
    end)

    it('do not add space before Chinese punctuation', function()
        eq('OpenResty，是一个 Web 平台', format('OpenResty，是一个Web平台'))
        eq('提供的 GET、POST、PUT 和 DELETE 方法',
            format('提供的GET、POST、PUT和DELETE方法'))
    end)

    it('ignore special line-start mark', function()
        eq('*无序列表', format("*无序列表"))
        eq('+无序列表', format("+无序列表"))
        eq('-无序列表', format("-无序列表"))
        eq('9.有序列表', format("9.有序列表"))
        eq('#标题', format("#标题"))
        eq('>引用', format(">引用"))
    end)

    it('ignore inline code', function()
        eq('支持内联代码片段 `^_^颜文字233`',
            format('支持内联代码片段`^_^颜文字233`'))
    end)

    it('trim trailing whitespace', function()
        eq('HTTP 方法包括以下几种：',
            format('HTTP方法包括以下几种：  '))
    end)

    it('keyword replacing', function()
        eq('自己的 loader 里可能并不能调用 ngx_lua 那些涉及',
            format('自己的loader里可能并不能调用ngx_lua那些涉及'))
        -- 像这种类型的，手工替换 ngx-lua 成 ngx_lua 吧
        eq('尽量使用 ngx-lua 提供的官方库', format('尽量使用 ngx-lua 提供的官方库'))
        eq('Nginx 是一个高性能 web 服务器，而 OpenResty 不仅仅是 Nginx + Lua',
            format('nginx是一个高性能web服务器，而Openresty不仅仅是nginx+lua'))
        eq('让我们打开 nginx.conf', format('让我们打开 nginx.conf'))
    end)

    it('ignore links but parse link title', function()
        eq('[OpenResty](指向openresty.org)',
            format('[openresty](指向openresty.org)'))
        eq('![OpenResty](指向openresty.org)',
            format('![openresty](指向openresty.org)'))
        eq('![](../images/nginx.png)', format('![](../images/nginx.png)'))
        eq('请看下面的状态转换图（图片来自[「The TCP/IP Guide」](http://www.tcpipguide.com/)）',
            format('请看下面的状态转换图（图片来自[「The TCP/IP Guide」](http://www.tcpipguide.com/)）'))
        eq('[引自 OpenResty 讨论组](https://groups.google.com/forum/#!searchin/openresty/package.loaded/openresty/-MZ9AzXaaG8/TeXTyLCuoYUJ)', format('[引自OpenResty讨论组](https://groups.google.com/forum/#!searchin/openresty/package.loaded/openresty/-MZ9AzXaaG8/TeXTyLCuoYUJ)'))
    end)

    it('ignore inline code, but add space around them', function()
        eq('名空间 `ffi.C` 通过', format('名空间`ffi.C`通过'))
        eq('名空间 `ffi.C` 通过', format('名空间 `ffi.C`通过'))
        eq('名空间 `ffi.C` 通过', format('名空间`ffi.C` 通过'))
        eq('名空间 `ffi.C` 通过', format('名空间 `ffi.C` 通过'))
        eq('尤其需要指出的是，`metatable` 与',
            format('尤其需要指出的是， `metatable`与'))
        eq('`cdata` 类型用来将', format('`cdata`类型用来将'))
        eq('元方法 `__index`', format('元方法`__index`'))
        eq('`string` 函数……实际长度将会在 `buflen` 这个数组中返回。',
            format("`string`函数……实际长度将会在`buflen`这个数组中返回。"))
    end)

    it('handle partial markdown notation', function()
        eq('这是*星号', format('这是*星号'))
        eq('哈哈~~哈哈', format('哈哈~~哈哈'))
    end)

    it('ignore text in a link', function()
        local sample = {
            '[https://github.com/openresty/lua-nginx-module](https://github.com/openresty/lua-nginx-module)',
            'https://github.com/openresty/lua-nginx-module/commit/f0b45946d',
            'https://github.com/openresty/lua-nginx-module/issues/872#issuecomment-250988928',
            'https://github.com/openresty/lua-nginx-module#lua-variable-scope 文档链接',
            '[http://github.com/openresty/lua-nginx-module](https://github.com/openresty/lua-nginx-module)',
            'http://github.com/openresty/lua-nginx-module/commit/f0b45946d',
            '文档链接: http://github.com/openresty/lua-nginx-module#lua-variable-scope',
        }
        for i = 1, #sample do
            eq(sample[i], format(sample[i]))
        end
    end)
end)
