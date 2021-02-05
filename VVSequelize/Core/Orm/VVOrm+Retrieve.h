//
//  VVOrm+Retrieve.h
//  VVSequelize
//
//  Created by Valo on 2018/9/12.
//

#import "VVOrm.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVOrm (Retrieve)

/// query a record
/// @return object
- (nullable id)findOne:(nullable VVExpr *)condition;

/// query a record, sorted
- (nullable id)findOne:(nullable VVExpr *)condition
               orderBy:(nullable VVOrderBy *)orderBy;

/// query records by condition
/// @return [object]
- (NSArray *)findAll:(nullable VVExpr *)condition;

/// query records by condition, sorted
- (NSArray *)findAll:(nullable VVExpr *)condition
             orderBy:(nullable VVOrderBy *)orderBy;

/// query records by condition, sorted, in a range
- (NSArray *)findAll:(nullable VVExpr *)condition
             orderBy:(nullable VVOrderBy *)orderBy
               limit:(NSUInteger)limit
              offset:(NSUInteger)offset;

/// query grouped records
- (NSArray *)findAll:(nullable VVExpr *)condition
             groupBy:(nullable VVGroupBy *)groupBy;

/// query grouped records, in a range
- (NSArray *)findAll:(nullable VVExpr *)condition
             groupBy:(nullable VVGroupBy *)groupBy
               limit:(NSUInteger)limit
              offset:(NSUInteger)offset;

/// query records by condition,
/// @param condition query condtiion.
/// 1.NSString:  native sql, all subsequent statements after `where`;
/// 2.NSDictionary: key and value are connected with '=', different key values are connected with 'and';
/// 3.NSArray: [dictionary], Each dictionary is connected with 'or'
/// @param distinct clear duplicate records or not
/// @param fields specifies the query fields
/// 1. string: `"field1","field2",...`, `count(*) as count`, ...
/// 2. array: ["field1","field2",...]
/// @param groupBy group method
/// 1. string: "field1","field2",...
/// 2. array: ["field1","field2",...]
/// @param having filter group, same as condition
/// @param orderBy sort method
/// 1. string: "field1 asc","field1,field2 desc","field1 asc,field2,field3 desc",...
/// 2. array: ["field1 asc","field2,field3 desc",...]
/// @param limit limit of results, 0 without limit
/// @param offset start position
/// @return [object] or [dictionary]
- (NSArray *)findAll:(nullable VVExpr *)condition
            distinct:(BOOL)distinct
              fields:(nullable VVFields *)fields
             groupBy:(nullable VVGroupBy *)groupBy
              having:(nullable VVExpr *)having
             orderBy:(nullable VVOrderBy *)orderBy
               limit:(NSUInteger)limit
              offset:(NSUInteger)offset;

/// records number by condition
- (NSInteger)count:(nullable VVExpr *)condition;

/// chech if object exists
- (BOOL)isExist:(nonnull id)object;

/// query records by condition
/// @return {"count":100,list:[object]}
- (NSDictionary *)findAndCount:(nullable VVExpr *)condition
                       orderBy:(nullable VVOrderBy *)orderBy
                         limit:(NSUInteger)limit
                        offset:(NSUInteger)offset;

/// query `max(rowid)`
/// @discussion `max(rowid)` is uniqued, use `max(rowid) + 1` as the primary key of the next record.
- (NSUInteger)maxRowid;

/// get the maximum value of a field
- (id)max:(nonnull NSString *)field condition:(nullable VVExpr *)condition;

/// get the minimum value of a field
- (id)min:(nonnull NSString *)field condition:(nullable VVExpr *)condition;

/// get the summary value of a field
- (id)sum:(nonnull NSString *)field condition:(nullable VVExpr *)condition;

@end

NS_ASSUME_NONNULL_END
