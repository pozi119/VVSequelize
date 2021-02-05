//
//  VVOrm+Create.h
//  VVSequelize
//
//  Created by Valo on 2018/9/12.
//

#import "VVOrm.h"

@interface VVOrm (Create)
/// insert a record
/// @param object object or dictionary
- (BOOL)insertOne:(nonnull id)object;

/// insert many records
/// @param objects objects/dictionaries/mixed
/// @note execute in transaction
- (NSUInteger)insertMulti:(nullable NSArray *)objects;

/// insert or replace a record
/// @param object object or dictionary
/// @note will update vv_createAt
- (BOOL)upsertOne:(nonnull id)object;

/// insert or replace many records
/// @param objects objects/dictionaries/mixed
/// @note execute in transaction, will update vv_createAt
- (NSUInteger)upsertMulti:(nullable NSArray *)objects;

@end
