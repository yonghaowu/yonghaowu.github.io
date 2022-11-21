---
layout: post
title: golang根据代码自动更新数据库scheme
description: 当数据库需要频繁更新结构时,代码与数据库难以保持一致是烦人的问题.而golang的gorm库,有Auto Migration功能,可以根据go里的struct tag自动更新数据库结构, 非常方便.
categories:
- 技术
tags:
- go
---

最近在写测试, 很明显每一个单元测试最好就在运行时自动清空数据库. gorm的[Auto Migration](http://jinzhu.me/gorm/database.html#migration)功能就可以满足此功能.

```
Auto Migration

Automatically migrate your schema, to keep your schema update to date.

WARNING: AutoMigrate will ONLY create tables, missing columns and missing indexes, and WON'T change existing column's type or delete unused columns to protect your data.
```

最重要的是, 索引(index), 约束(constrants), 类型(type)还有默认值(default)都可以设置,但是文档并没有详细的介绍,经过我的搜索与测试,终于摸清所有的关系.

AutoMigration只会根据struct tag建立新表, 没有的列以及索引, 不会改变已经存在的列的类型或者删除没有用到的列. 所以需要动态更新的话,还是需要在auto migration前```DROP TABLE```删除整个表再重建. 如:

```
func clearDatebase() {
	db := GetTestClient().NewConn()
	db.Exec("DROP TABLE books")
	db.AutoMigrate(&mystructtag.books{})
	db.Exec("DROP TABLE book_users")
	db.AutoMigrate(&mystructtag.book_users{})
}
```

gorm:

* primary_key 设置主键
* not null 非空约束
* size:64 类型大小,通常是指varchar

以上主要就是size和not null并没有在文档上出现, 其他都可以从例子找到, 自己意会啦.

```
type User struct {
    gorm.Model
    Birthday     time.Time
    Age          int
    Name         string  `gorm:"size:255"` // Default size for string is 255, reset it with this tag
    Num          int     `gorm:"AUTO_INCREMENT"`

    CreditCard        CreditCard      // One-To-One relationship (has one - use CreditCard's UserID as foreign key)
    Emails            []Email         // One-To-Many relationship (has many - use Email's UserID as foreign key)

    BillingAddress    Address         // One-To-One relationship (belongs to - use BillingAddressID as foreign key)
    BillingAddressID  sql.NullInt64

    ShippingAddress   Address         // One-To-One relationship (belongs to - use ShippingAddressID as foreign key)
    ShippingAddressID int

    IgnoreMe          int `gorm:"-"`   // Ignore this field
    Languages         []Language `gorm:"many2many:user_languages;"` // Many-To-Many relationship, 'user_languages' is join table
}
```
