local copywriting = require "copywriting"

describe('format file', function()
    it('ignore code block', function()
        assert.are.same(
[[# 针对中英文混合的 markdown 文档的格式化工具

```
code block不做处理
```


语句块中的 `inline
 code也不做处理`
> quote不做处理]], copywriting.run('fixture.md'))
    end)
end)

describe('format line', function()
    it('add space between Chinese and English', function()
        assert.are.same('OpenResty 中特定 body 的准入控制',
            copywriting.format('OpenResty中特定body的准入控制'))
        assert.are.same('当你的 API Server 接口服务比较多',
            copywriting.format('当你的API Server接口服务比较多'))
    end)

    it('add space between Chinese and number', function()
        assert.are.same('2014 年，', copywriting.format('2014年，'))
        assert.are.same('奇虎 360 公司的第 1024', copywriting.format('奇虎360公司的第1024'))
    end)

    it('add space after some punctuations if there is no space', function()
        assert.are.same('Moreover, OpenResty support', copywriting.format('Moreover,OpenResty support'))
        assert.are.same('Moreover, OpenResty support', copywriting.format('Moreover, OpenResty support'))
        assert.are.same('50% 的酒精', copywriting.format('50%的酒精'))
        assert.are.same('注意 **不要** 修改', copywriting.format('注意 **不要**修改'))
        assert.are.same('注意 *不要* 修改', copywriting.format('注意*不要* 修改'))
        assert.are.same('注意 ~~不要~~ 修改', copywriting.format('注意~~不要~~修改'))
        assert.are.same('注意 ~~不要~~', copywriting.format('注意~~不要~~'))
        assert.are.same('从 40-60 中', copywriting.format('从 40-60 中'))
        -- 点号后面是数字或小写字符串，不加空格
        assert.are.same('1.2', copywriting.format('1.2'))
        assert.are.same('fixture.md', copywriting.format('fixture.md'))
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
        assert.are.same('支持内联代码片段`^_^颜文字233`',
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

    it('handle partial markdown notation', function()
        assert.are.same('这是*星号', copywriting.format('这是*星号'))
        assert.are.same('哈哈~~哈哈', copywriting.format('哈哈~~哈哈'))
    end)
end)
