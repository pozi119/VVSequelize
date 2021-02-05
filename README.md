# VVSequelize

[![Version](https://img.shields.io/cocoapods/v/VVSequelize.svg?style=flat)](https://cocoapods.org/pods/VVSequelize)
[![License](https://img.shields.io/cocoapods/l/VVSequelize.svg?style=flat)](https://cocoapods.org/pods/VVSequelize)
[![Platform](https://img.shields.io/cocoapods/p/VVSequelize.svg?style=flat)](https://cocoapods.org/pods/VVSequelize)

## 改动(0.4.7)
1. 移除accessible. 不建议访问appgroup中的数据库, 所以去掉此功能.
2. 移除cache. 因为`sqlite3_update_hook()`不能完全hook所有delete, drop操作, cache将不能被有效更新,会导致查询到错误数据, 所以去掉此功能, 由用户自行管理缓存.

## 功能
* [x] 根据Class生成数据表
* [x] 增删改查,insert,update,upsert,delele,drop...
* [x] Where语句生成,可满足大部分常规场景
* [x] 数据库加解密(SQLCipher)
* [x] 原生SQL语句支持
* [x] 常规查询函数支持,max(),min(),sum(),count()...
* [x] 支持主键,可多主键,单主键可自增.
* [x] 支持唯一性约束
* [x] Transaction支持
* [x] Object直接处理
* [x] 数据存储,OC类型支持: NSData, NSURL, NSSelector, NSValue, NSDate, NSArray, NSDictionary, NSSet,...
* [x] 数据存储,C类型支持: char *, struct, union
* [x] 子对象存储为Json字符串
* [x] OrmModel查询缓存
* [x] FTS5全文搜索(不支持FTS3/4)
* [x] 自定义FTS分词器
* [x] 支持拼音分词,简繁互搜
* [x] 支持外键,约束
* [x] 支持View

## 结构
![](VVSequelize.png)

## 安装
```ruby
pod 'VVSequelize', '~> 0.4.7'
```
使用测试版本:
```ruby
    pod 'VVSequelize', :git => 'https://github.com/pozi119/VVSequelize.git'
```
## 注意
1. 子对象会保存成为Json字符串,子对象内的NSData也会保存为16进制字符串.
2. 含有子对象时,请确保不会循环引用,否则`Dictionary/Object`互转会死循环,请将相应的循环引用加入互转黑名单. 
3. VVKeyValue仅用于本工具,不适用常规的Json转对象.

## 用法
此处主要列出一些基本用法,详细用法请阅读代码注释.

### 打开/创建数据库文件
```objc
    self.vvdb = [[VVDatabase alloc] initWithPath:dbPath];
```

### 定义ORM配置
1. 手动创建`VVOrmConfig`.
2. 普通表适配协议`VVOrmable`, fts表适配协议`VVFtsable`

**注意:** 已移除fts3/4的支持,仅使用fts5

### 定义ORM模型 
可自定义表名和存放的数据库文件.
生成的模型将不在保存在ModelPool中,防止表过多导致内存占用大,需要请自行实现.

示例如下:

```objc
item.orm = [VVOrm ormWithClass:VVMessage.class name:item.tableName database:item.db];
        
item.ftsOrm = [VVOrm ormWithFtsClass:VVMessage.class name:item.tableName database:item.ftsDb];
```

### 增删改查
使用ORM模型进行增删改查等操作.

示例如下:

```objc
    NSInteger count = [self.mobileModel count:nil];
    
    BOOL ret = [self.mobileModel increase:nil field:@"times" value:-1];
    
    NSArray *array = [self.mobileModel findAll:nil orderBy:nil limit:10 offset:0];
    
...
```

### 生成SQL子句
现在仅支持非套嵌的字典或字典数组,转换方式如下:
```
//where/having :
{field1:val1,field2:val2} --> field1 = "val1" AND field2 = "val2"
[{field1:val1,field2:val2},{field3:val3}] --> (field1 = "val1" AND field2 = "val2") OR (field3 = "val3")
//group by:
[filed1,field2] --> "field1","field2"
//order by
[filed1,field2] --> "field1","field2" ASC
[filed1,field2].desc --> "field1","field2" DESC
```
示例: 
```objc
- (void)testClause
  {
    VVSelect *select =  [VVSelect new];
    select.table(@"mobiles");
    select.where(@"relative".lt(@(0.3))
                 .and(@"mobile".gte(@(1600000000)))
                 .and(@"times".gte(@(0))));
    NSLog(@"%@", select.sql);
    select.where(@{ @"city": @"西安", @"relative": @(0.3) });
    NSLog(@"%@", select.sql);
    select.where(@[@{ @"city": @"西安", @"relative": @(0.3) }, @{ @"relative": @(0.7) }]);
    NSLog(@"%@", select.sql);
    select.where(@"relative".lt(@(0.3)));
    NSLog(@"%@", select.sql);
    select.where(@"     where relative < 0.3");
    NSLog(@"%@", select.sql);
    select.groupBy(@"city");
    NSLog(@"%@", select.sql);
    select.groupBy(@[@"city", @"carrier"]);
    NSLog(@"%@", select.sql);
    select.groupBy(@" group by city carrier");
    NSLog(@"%@", select.sql);
    select.having(@"relative".lt(@(0.2)));
    NSLog(@"%@", select.sql);
    select.groupBy(nil);
    NSLog(@"%@", select.sql);
    select.orderBy(@[@"city", @"carrier"]);
    NSLog(@"%@", select.sql);
    select.orderBy(@" order by relative");
    NSLog(@"%@", select.sql);
    select.limit(10);
    NSLog(@"%@", select.sql);
    select.distinct(YES);
    NSLog(@"%@", select.sql);
}
```
### 原生语句查询
```
- (NSArray<NSDictionary *> *)query:(NSString *)sql;

- (NSArray *)query:(NSString *)sql clazz:(Class)clazz;
```

## 加密数据数据转换(sqlcipher 3.x->4.x)
```objc
    VVDatabase *database = [VVDatabase databaseWithPath:path flags:0 encrypt:@"XXXXX"];
    database.cipherOptions = @[
        @"pragma cipher_page_size = 4096;", ///<3.x的cipher_page_size,默认为1024
        @"pragma kdf_iter = 64000;",
        @"pragma cipher_hmac_algorithm = HMAC_SHA1;",
        @"pragma cipher_kdf_algorithm = PBKDF2_HMAC_SHA1;"
    ];
```

## Author

Valo Lee, pozi119@163.com

## License

VVSequelize is available under the MIT license. See the LICENSE file for more info.
