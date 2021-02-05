//
//  VVOrm+Update.h
//  VVSequelize
//
//  Created by Valo on 2018/9/12.
//

#import "VVOrm.h"
NS_ASSUME_NONNULL_BEGIN

@interface VVOrm (Update)

/// update records by condition
/// @param condition update condtiion.
/// 1.NSString:  native sql, all subsequent statements after `where`;
/// 2.NSDictionary: key and value are connected with '=', different key values are connected with 'and';
/// 3.NSArray: [dictionary], Each dictionary is connected with 'or'
/// @param keyValues {field1:value1, field2:value2,...}
- (BOOL)update:(nullable VVExpr *)condition keyValues:(NSDictionary<NSString *, id> *)keyValues;

/// updat a record, failure will not insert new record
- (BOOL)updateOne:(nonnull id)object;

/// updat a record, failure will not insert new record,limit update fields
- (BOOL)updateOne:(nonnull id)object fields:(nullable NSArray<NSString *> *)fields;

/// updat many records, failure will not insert new record,limit update fields, use transaction
- (NSUInteger)updateMulti:(nullable NSArray *)objects fields:(nullable NSArray<NSString *> *)fields;

/// updat many records, failure will not insert new record, use transaction
- (NSUInteger)updateMulti:(nullable NSArray *)objects;

/// Add a value to a field
- (BOOL)increase:(nullable VVExpr *)condition
           field:(nonnull NSString *)field
           value:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
