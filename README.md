# copywriting

[![Build Status](https://travis-ci.org/iresty/copywriting.svg?branch=master)](https://travis-ci.org/iresty/copywriting)
[![Coverage Status](https://coveralls.io/repos/github/iresty/copywriting/badge.svg?branch=master)](https://coveralls.io/github/iresty/copywriting?branch=master)

针对中英文混合的 markdown 文档的格式化工具

该工具已用于或将用于 iresty 名下的多个 OpenResty 相关的文档项目。当然你也可以用在自己的项目里，比如本人的博客在发布之前都会用这个工具过一遍。

格式化规则：
https://github.com/iresty/copywriting/wiki/copywriting-%E6%A0%BC%E5%BC%8F%E5%8C%96%E8%A7%84%E5%88%99

安装方式：
```
git clone https://github.com/iresty/copywriting --depth=1
cd copywriting && luarocks make copywriting-scm-0.rockspec
```

使用方式：
```
￥ copywriting -h
Usage:
    filename                   : print formated result to stdout
    -h                         : print this help message
    -w filename1 filename2 ... : overwrite input filenames with formated result (support multiple files)
```
