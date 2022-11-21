---
layout: post
title:  你们仍未掌握那天所学的 git 知识
description: 绝大多数人对于 git的认识只停留在`git status`, `git add`, `git push`, `git pull`, 好一点会知道`git merge`, 那就是全部了。不信？ 试试你能回答出以下问题不
categories:
- 技术
tags:
- elixir
---

## 工作中必备 git 技能详解

绝大多数人对于 git的认识只停留在`git status`, `git add`, `git push`, `git pull`, 好一点会知道`git merge`, 那就是全部了。

#### 不信？

试试你能回答出以下问题不：

- `git push origin master`命令中，origin 代表的是什么，整个命令是什么意思，origin 可以修改不
- `git fetch origin; git rebase origin/master` 这些命令知道吗？跟 merge 有什么区别？
- git如何合并两个补丁，对第三个补丁进行修改？（这个很重要，因为你不会才导致 git commit 的信息没有意义，commit 不够小和多）



又或者，你试过合并commit 吗？commit message 写的不好时如何修改？如何改变 commit 的顺序？

如果以上有不清楚的话，那么我希望以下的文章对你有帮助。

---


#### 你所不知道的 github 初始化

初始创建一个 github 仓库时，github 会给一些命令你去创建 git本地项目，`git init`就不用说了，`  git remote add origin git@github.com:YongHaoWu/test.git` 你知道这里的 origin 是什么吗？

是的，就仅仅是一个名字，对`git@github.com:YongHaoWu/test.git` 这个 ssh 地址的命名，你可以把 `origin`命名为 `gakki` —— `git remote add gakki git@github.com:YongHaoWu/test.git`, 以后就可以用`git push gakki master`了。

另外，你还可以`add`好几个名字，比如：你在 github 跟coding 同样都有仓库放代码的情况。



`git push -u origin master` , 这里就是把 master（默认 git 分支）推送到 origin， `-u`也就是`--set-upstream`, 代表的是更新默认推送的地方，这里就是默认以后`git pull`和`git push`时，都是推送和拉自`origin`。

---

#### 令 commit 更漂亮

对于 git 工作流，我认为 commit 数要多而有意义，branch 也要多而有意义——也就是，一个小功能就要开一个分支，一个分支里要有一些有意义的 commit。 好处就是冲突会很少，review 代码速度加快，commit 都是有意义的，而且利于回退。

要做到这些，离不开掌握`git rebase`



##### 永远使用 rebase

```
git rebase

Reapply commits from one branch on top of another branch.
Commonly used to "move" an entire branch to another base, creating copies of the commits in the new location.
```

相信你可以理解以上的英文：把 A 分支rebase 到 B 分支，也就是把 A 的 commit 与 B 的合并，并且保留 B 独特的 commit。

还是很抽象，对吧？

看一个例子：`git pull gakki feat-add-listener` 这里就是把 `gakki` 仓库拉到 `feat-add-listerner`  分支。实际上，所做的东西等价于：

```
git fetch gakki          //把 gakki 仓库的东西都拉下来本地
git merge gakki/master feat-add-lister //把 gakki 的 master 分支 merge 到 feat-add-lister
```

因为 pull 的时候， 当出现冲突而你解决掉后，会有多余的`merge`信息（commit message），所以我是推荐在自己的分支开发时，使用`git fetch gakki`  以及 `git rebase gakki/master feat-add-lister` （不会出现多余信息，处理冲突更加自由） 这两条命令的合并版就是: `git pull -r gakki/master feat-add-lister`, `-r` 意思是在 pull 的时候,使用 rebase.

---

##### 合并你的 commits

```
Author: YongHao Hu <hyh@vincross.com>
Date:   Fri Dec 23 17:55:49 2016 +0800

    install skill: Fix skill pkg relative path.

commit 37f37e46a2570c0989a46f39169bba510ebdabd8
Author: YongHao Hu <hyh@vincross.com>
Date:   Fri Dec 23 10:51:09 2016 +0800

    mind: Add comments for understanding.

commit 4eb9b9743d2bdc301a0e97f73d652f67adc82b32
Author: YongHao Hu <hyh@vincross.com>
Date:   Thu Dec 22 15:00:02 2016 +0800

    skill-third-party: Add default include library.
```

假设你又以上三个 commit，如何合并，修改呢？
`git rebase -i HEAD~4` 对前四个补丁就行修改，就会进入以下界面：

```
pick 0194373 skill-third-party: Change PKG_CONFIG_PATH and LD_LIBRARY_PATH.
pick 4eb9b97 skill-third-party: Add default include library.
pick 37f37e4 mind: Add comments for understanding.
pick 84c413a install skill: Fix skill pkg relative path.

# Rebase 986e234..84c413a onto 986e234 (4 commands)
#
# Commands:
# p, pick = use commit
# r, reword = use commit, but edit the commit message
# e, edit = use commit, but stop for amending
# s, squash = use commit, but meld into previous commit
# f, fixup = like "squash", but discard this commit's log message
# x, exec = run command (the rest of the line) using shell
# d, drop = remove commit
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
```

有以下常用操作：

- 默认pick， 不做更改
- reword：改 commit message
-  squash：当前补丁跟上一个补丁合并
- fixup: 跟 squash 作用一样，但是会丢弃当前 commit 信息，使用上一个的；squash 则是可以让你重新写

需要修改时，把上面四个补丁最前面的 pick 改成对应操作（如 reword，fixup），然后保存退出即可。

---

## 不用担心的回退

回退大家应该都知道`git reset --hard commitID`, 把整个 git 回退到这个 commitID 里；

其实除了`--hard`, 还有 `soft`. 

`hard`是把改动全部都丢弃，而`soft`则柔软一些，仅仅是把所做的 commit 丢掉，而改动都保留在本地——通常用来修改，再重新 commit 一遍。



做了胡乱的更改，导致 `git log`都不正常，找不回那个 commit 了怎么办？

不用担心， 还有 `git reflog` — `Reference logs, or "reflogs", record when the tips of branches and other references were updated in the local repository.`

用它可以看到你对当前项目所做过的所有 git 操作，所有 git 操作的 id 号——意味着你可以回退到任意的时刻。

所以，只要你没有把改动没有做 commit 就丢失，又或者用`git push -f`把 github 仓库覆盖了，你就可以恢复任意时刻的东西。

---

## git stash 暂存更改

时刻要注意，当前修改没有 commit 的时候，不能 checkout 切换分支。

此时不想 commit，便需要 `git stash` 暂存更改；顾名思义，stash 使用 stack（栈）实现，所以可以 `git stash`存多次，然后切换分支后， `git stash pop` 撤出来

## 比 grep 更好用的 git grep

相比于 `grep -R keyword ./` , 我是更喜欢用 `git grep keyword`, 差不多是一样的，不过`git grep`只是会找当前的 目录中git 有 track（跟踪）的文件【也就是变动时，git status 会检测到变化的文件】

---

## 超级进阶：分割commit

```
 commit 03bb9a14f5ea00d51d2edc14587b37b1ab9ccf5d
Author: YongHao Hu christopherwuy@gmail.com
Date: Fri Jul 10 17:23:02 2015 +0800

msvcp110: Add tr2_sys__Unlink implementation and test.

commit 24137cd93c783ced61ca152cb4384287e6859ba4
Author: YongHao Hu christopherwuy@gmail.com
Date: Tue Jul 7 11:04:25 2015 +0800

msvcp110: Add tr2_sys__Symlink implementation and test.

commit 51702048d9ecd1dc3887a63c057761a8547ce5f6
Author: YongHao Hu christopherwuy@gmail.com
Date: Thu Jul 2 23:23:51 2015 +0800

msvcp110: Add tr2_sys__Link implementation and test.

```

假设我们想要分割 msvcp110: Add tr2_sys__Unlink implementation and test. 这个 commit，可以直接使用
git rebase -i HEAD~7（数字随意，反正在 Unlink 这个 commit 前就可以了），选择 Unlink 这个 commit，
改成 edit。
一般情况下，就是这样修改 commit 的，修改后再 git rebase –continue.

但是，我们需要的是分割补丁：
选择 git rebase HEAD^, 撤销这次 commit，再把想改动的文件 git add, 再 git commit, 这样就可以分割很多补丁。

最后，git rebase –continue 就可以了。

---
