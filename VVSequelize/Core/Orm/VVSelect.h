//
//  VVSelect.h
//  VVSequelize
//
//  Created by Valo on 2018/9/14.
//

#import "VVOrm.h"

@interface VVSelect : NSObject
/// generate sql statement
@property (nonatomic, copy, readonly) NSString *sql;

/// query results
/// @note must set orm
- (NSArray *)allObjects;

/// query results
/// @note must set orm
- (NSArray *)allKeyValues;

/// query the specified column
/// @note must set orm
- (NSArray *)allValues:(NSString *)field;

//MARK: - chain
/// create chain
+ (instancetype)makeSelect:(void (^)(VVSelect *make))block;

/// select.orm == select.vvdb(orm.vvdb).table(orm.table).clazz(orm.metaClass ? : orm.config.cls)
- (VVSelect *(^)(VVOrm *orm))orm;

- (VVSelect *(^)(VVDatabase *vvdb))vvdb;

- (VVSelect *(^)(NSString *table))table;

- (VVSelect *(^)(Class clazz))clazz;

- (VVSelect *(^)(BOOL distinct))distinct;

- (VVSelect *(^)(VVFields *fields))fields;

- (VVSelect *(^)(VVExpr *where))where;

- (VVSelect *(^)(VVOrderBy *orderBy))orderBy;

- (VVSelect *(^)(VVGroupBy *groupBy))groupBy;

- (VVSelect *(^)(VVExpr *having))having;

- (VVSelect *(^)(NSUInteger offset))offset;

- (VVSelect *(^)(NSUInteger limit))limit;

- (VVSelect *(^)(NSArray *values))values;

@end
