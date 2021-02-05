
#import <Foundation/Foundation.h>
#import "VVOrmDefs.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (VVOrm)

/// where clause
- (NSString *)sqlWhere;

/// array -> "item1","item2",...
/// string: no change
- (NSString *)sqlJoin;

@end

@interface NSDictionary (VVOrm)

/// remove some keys
- (NSDictionary *)vv_removeObjectsForKeys:(NSArray *)keys;

@end

/// generate sql clause
@interface NSArray (VVOrm)

/// order by clause, exluding `order by`
/// array -> item1,item2,... asc
- (NSString *)asc;

/// order by clause, exluding `order by`
/// array -> item1,item2,... desc
- (NSString *)desc;

/// array -> "item1","item2",...
- (NSString *)sqlJoin;

/// clear duplicate items
- (NSArray *)vv_distinctUnionOfObjects;

/// remove some items
- (NSArray *)vv_removeObjectsInArray:(NSArray *)otherArray;

@end

/// generate sql clause
@interface NSString (VVOrm)

// MARK: - where
/// self AND value,
/// @note self: field1 = val1
/// @note value: field2 = val2
/// @return (field1 = val1) AND (field2 = val2)
- (NSString *(^)(id value))and;

/// self OR value,
/// @note self: field1 = val1
/// @note value: field2 = val2
/// @return (field1 = val1) OR (field2 = val2)
- (NSString *(^)(id value))or;

/// self ON value
/// @note self: table1 INNER JOIN table2
/// @note value: table1.field == table2.field
/// @return table1 INNER JOIN table2 ON table1.field == table2.field
- (NSString *(^)(id value))on;

/// self = value
- (NSString *(^)(id value))eq;

/// self != value
- (NSString *(^)(id value))ne;

/// self > value
- (NSString *(^)(id value))gt;

/// self >= value
- (NSString *(^)(id value))gte;

/// self < value
- (NSString *(^)(id value))lt;

/// self <= value
- (NSString *(^)(id value))lte;

/// IS NULL
- (NSString *(^)(void))isNull;

/// IS NOT NULL
- (NSString *(^)(void))isNotNull;

/// self BETWEEN value1,value2
- (NSString *(^)(id value, id value2))between;

/// self NOT BETWEEN value1,value2
- (NSString *(^)(id value1, id value2))notBetween;

/// self IN (val1,val2,...)
- (NSString *(^)(NSArray *array))in;

/// self NOT IN (val1,val2,...)
- (NSString *(^)(NSArray *array))notIn;

/// self LIKE value
/// @note value support % and _
- (NSString *(^)(id value))like;

/// self NOT LIKE value
/// @note value support % and _
- (NSString *(^)(id value))notLike;

/// self GLOB value
/// @note value support * and ?
- (NSString *(^)(id value))glob;

/// self NOT GLOB value
/// @note value support * and ?
- (NSString *(^)(id value))notGlob;

/// self MATCH value, such as: tableName match "value"
- (NSString *(^)(id value))match;

/// self JOIN right
- (NSString *(^)(NSString *right))innerJoin;

/// self LEFT OUTER  JOIN right
- (NSString *(^)(NSString *right))outerJoin;

/// self CROSS JOIN right
- (NSString *(^)(NSString *right))crossJoin;

/// self.cloumn
- (NSString *(^)(NSString *column))column;

/// A.concat(@"=", B) -> A = B
- (NSString *(^)(NSString *concat, id value))concat;

/// self ASC
- (NSString *)asc;

/// self DESC
- (NSString *)desc;

// MARK: - other
/// quote " : self -> "self", quote ' : self -> 'self'
- (NSString *)quote:(NSString *)quote;

/// self -> "self"
- (NSString *)quoted;

/// self -> 'self'
- (NSString *)singleQuoted;

/// remove quote
- (NSString *)removeQuote;

/// remove spaces and returns at the beginning and end of a string
- (NSString *)vv_trim;

/// remove duplicate spaces
- (NSString *)vv_strip;

/// match regular expression or not
- (BOOL)isMatch:(NSString *)regex;

/// pemove extra spaces, quotes, prepare for sql statement
- (NSString *)prepareForParseSQL;

/// generate html tag `<span></span>`, use for offset() in fts3, highlight() in fts5
+ (NSString *)leftSpanForAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes;

/// generate css code, use for offset() in fts3, highlight() in fts5
+ (NSString *)cssForAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes;

@end

NS_ASSUME_NONNULL_END
