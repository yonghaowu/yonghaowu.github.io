---
layout: post
title:  写不写注释? Elixir 给出另外一个答案
description: 我们也许曾经在写注释与不写之间摇晃不已, 不写是因为代码容易变化而注释往往被忽略掉了,这时注释反而有害; 但又因为就算一个有意义的名字 也难以信达雅的传递程序的意义.
categories:
- 技术
tags:
- elixir
---

  # To be or not to be #

  我们也许曾经在写注释与不写之间摇晃不已, 不写是因为代码容易变化而注释往往被忽略掉了,这时注释反而有害; 但又因为就算一个有意义的名字 也难以信达雅的传递程序的意义.
  Elixir 给出了它的答案.
  >But the problem with comments is that they just don’t get maintained. The code changes, the comment gets stale, and it becomes useless. Fortunately, ExUnit has doctest, a tool that extracts the iex sessions from your code’s @doc strings, runs it, and checks that the output agrees with the comment.

  Elixir 提倡写注释, 写注释时要按照基本法, 给出该函数的使用例子:
  ```
@doc """
Return a format string that hard codes the widths of a set of columns. We put `" | "` between each column.
## Example
    iex> widths = [5,6,99]
    iex> Issues.TableFormatter.format_for(widths)
    "~-5s | ~-6s | ~-99s~n"
"""
def format_for(column_widths) do
map_join(column_widths, " | ", fn width -> "~-#{width}s" end) <> "~n"
end
  ```

  而 Elixir 则提供了 `doctest` 工具, 自动执行你在里面写的用例, doc 的测试还会集成到整个项目的测试中.
  所以通过这个保证, 大大减少了注释没有更新的情况. 结合优雅的命名, 应该是对这个问题的银弹. 当然, 没有银弹.
