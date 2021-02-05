//
//  VVOrm+Delete.h
//  VVSequelize
//
//  Created by Valo on 2018/9/12.
//

#import "VVOrm.h"

@interface VVOrm (Delete)
/// delete table
/// @warning Must set orm to nil after delete. Generally, please do not delete the table!!!
- (BOOL)drop;

/// delete a record
- (BOOL)deleteOne:(nonnull id)object;

/// delete many records
- (NSUInteger)deleteMulti:(nullable NSArray *)objects;

/// Delete records according to conditions
/// @param condition support native sql, dictionary, array
/// @note native sql:  all subsequent statements after `where`
- (BOOL)deleteWhere:(nullable VVExpr *)condition;

@end
