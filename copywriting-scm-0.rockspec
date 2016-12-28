package = "copywriting"
version = "scm-0"
source = {
    url = "git://github.com/iresty/copywriting",
    branch = "master",
}
description = {
    summary = "针对中英文混合的 markdown 文档的格式化工具",
    detailed = "针对中英文混合的 markdown 文档的格式化工具",
    homepage = "https://github.com/iresty/copywriting",
    license = "MIT"
}
dependencies = {
    "lua >= 5.1",
}
build = {
   type = "builtin",
   modules = {
      ['copywriting'] = "lib/copywriting.lua",
      ['copywriting/dict'] = "lib/copywriting/dict.lua",
   },
   install = {
      bin = {
         ["copywriting"] = "bin/copywriting",
      }
   },
}
