---
layout: post
title: mongo 聚合教程及工作应用
description: mongo 聚合难就难在 对于初学者, 很容易迷失方向, 不知道有什么东西可以用, 以及该如何用。
categories:
- 技术
tags:
- go
---


聚合的基础教程请看 官方文档: https://docs.mongodb.com/manual/aggregation 基本上都能看懂, 但 mongo 聚合难就难在 对于初学者, 很容易迷失方向, 不知道有什么东西可以用, 以及该如何用。

下面给出例子以及详细解释。

 数据已经过我处理脱敏, 背景也做了更改:
 - `leftPDSuc`, 以及 `rightPDSuc`, left 和 right 为 true 代表此人是左脚还是右脚患病, 空为不患病；
 - 但只要有一只脚患病, 我们就认为此人是患病了；
 - `PD` 为具体某一种病, 同理 `CR`, `Celery` 也是两种病；

 但因为业务原因, success 相关字段不能用 1 和 0代替, 而只能用 true 和 false, 这给数据查询统计带来了极大的麻烦. 刚开始时, 我被这个问题困扰了很久, 因为1和0就可以简单的用 sum 函数统计起来了..

1、在给出的时间区间内（`createdAt`字段）查一下各个疾病为true的数量，以及数据的总数; 如果用户并没有传入时间区间，就默认全部的数据。

```
db.molly.aggregate([
    { $match: { birth: {
        $gt: new ISODate("2012-05-25T02:30:58.937Z"), $lt: new ISODate("2019-05-25T02:30:58.937Z") }
    } },
    {
        $project: {
            PDSuc: { $cond: {
            if: { $or: [ {
                $eq: [true, "$leftPDSuc"]}, {$eq: [true, "$rightPDSuc"]}
            ] }, then: 1, else: 0 } },
            CRSuc: { $cond: {
            if: { $or: [ { $eq: [true, "$leftCRSuc"]}, {$eq: [true, "$rightCRSuc"]} ] },
                then: 1, else: 0 } },
            CelerySuc: { $cond: {
            if: { $or: [ {
                $eq: [true, "$leftCelerySuc"]}, {$eq: [true, "$rightCelerySuc"]}
            ] }, then: 1, else: 0 } },
        },
    },
    { $group: { _id: null,
        all_PDSuc: { $sum: "$PDSuc" }, all_CRSuc: { $sum: "$CRSuc"},
        all_CelerySuc: { $sum: "$CelerySuc" },
    }
    },
] )
```

幸好, 我们有`$project`, 可以把 旧字段挑选出来, 或者重新新增一个字段, 给下一个 aggregate 的 pipeline 处理。

注意上面, 我把 `leftPDSuc` 与 `rightPDSuc` 判断是否存在有一个为 true, 是的话, 就赋值1给新字段PDSuc, 否就是0. 借此, 我们就可以知道这个人是否患有这个病了.
然后通过 `$group` 与 `$sum`, 就可以把 总数算出来了。

 为什么`_id` 为 null 呢?

> null to calculate accumulated values for all the input documents as a whole.

 null 用来把全部文档当做整体来运算, 所以就可以用 `$sum`


2、根据前端给出的性别字段（三大类：男、女、未知），查一下各个性别下 各个疾病的数量，以及数据的总数
```
db.molly.aggregate([
    {
        $project: {
            PDSuc: { $cond: {
                if: { $or: [ {
                    $eq: [true, "$leftPDSuc"]}, {$eq: [true, "$rightPDSuc"]}
                ] }, then: 1, else: 0 } },
            CRSuc: { $cond: {
                if: { $or: [ { $eq: [true, "$leftCRSuc"]}, {$eq: [true, "$rightCRSuc"]} ] },
                then: 1, else: 0 } },
            CelerySuc: { $cond: {
                if: { $or: [ {
                    $eq: [true, "$leftCelerySuc"]}, {$eq: [true, "$rightCelerySuc"]}
                ] }, then: 1, else: 0 } },
            gender: "$gender",
        },
    },
    { $group: { _id: {
        $cond: [
            {$eq: ["$gender", ""] }, "",
            { $cond: [
                {$eq: ["$gender", "男"] }, "男", "女"
            ]}
        ],
    },
        all_PDSuc: { $sum: "$PDSuc" }, all_CRSuc: { $sum: "$CRSuc"},
        all_CelerySuc: { $sum: "$CelerySuc" },
    }
    },
])
```

男女的分类逻辑也差不多, 重点在 `$group` 上。
`$group` 里的 `_id` 根据 `$project` 传过来的`$gender` 字段, 分出"男" 与 "女" 两个 `_id` 来group


3、根据前端给出的各个年龄段（五大段：童年（0-6）、少年（7-17）、青年（18-40）、中年（41-65）、老年（66以上））查一下各个年龄段下 各个疾病的数量，以及数据的总数

```
db.molly.aggregate([
    {
        $project: {
            PDSuc: { $cond: {
            if: { $or: [ {
                $eq: [true, "$leftPDSuc"]}, {$eq: [true, "$rightPDSuc"]}
            ] }, then: 1, else: 0 } },
            CRSuc: { $cond: {
            if: { $or: [ { $eq: [true, "$leftCRSuc"]}, {$eq: [true, "$rightCRSuc"]} ] },
                then: 1, else: 0 } },
            CelerySuc: { $cond: {
            if: { $or: [ {
                $eq: [true, "$leftCelerySuc"]}, {$eq: [true, "$rightCelerySuc"]}
            ] }, then: 1, else: 0 } },
            gender: "$gender",
            birth: "$birth",
            age: {$floor: {$divide: [{ $subtract: [ new Date(), "$birth" ] },
                    (365 * 24*60*60*1000)]} }
        },
    },
    {$group: { _id: {
                $cond: [
                    { $lte: ["$age", NumberInt(6)] }, "0-6",
                    { $cond: [
                        { $lte: ["$age", NumberInt(17)] }, "7-17",
                        {$cond: [
                            { $lte: ["$age", NumberInt(40)] }, "18-40",
                            {$cond: [
                                { $lte: ["$age", NumberInt(65)] }, "41-65",
                                "66-..."
                            ]},
                        ]},
                    ]},
                ],
            },
        all_PDSuc: { $sum: "$PDSuc" }, all_CRSuc: { $sum: "$CRSuc"},
        all_CelerySuc: { $sum: "$CelerySuc" },
        }
    },
])
```

同理,这里的逻辑跟男女分类一样, 不过这里需要根据出生日期, 在 `$project` 的时候来算出 age(年龄)

`new Date()` 得到当前日期, `$subtract` 减去出生日期 得到时间戳(ms), 再 `$divide` 除以 `(365 * 24*60*60*1000)`  得到年, `$floor` 向下取整, 毕竟23.6岁的人, 我们还是当成23岁吧?

然后就在`$group`里根据 `$age` 做范围判断分类即可~
