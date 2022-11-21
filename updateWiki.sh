#!/bin/bash
cp  ~/Downloads/wiki/tiddly_wiki.html /Users/yonghao.hu/mycode/YongHaoWu.github.io/wiki/index.html ; 
cd /Users/yonghao.hu/mycode/YongHaoWu.github.io/ || return; git add -u ; git cmm "new wiki" ; git pull  origin master -r && git push origin master
