//
//  VVFtsable.h
//  VVSequelize
//
//  Created by Valo on 2020/7/29.
//

#import <Foundation/Foundation.h>
#import "VVOrm.h"

NS_ASSUME_NONNULL_BEGIN

@protocol VVFtsable <NSObject>
@optional
+ (NSArray<NSString *> *)fts_whites;
+ (NSArray<NSString *> *)fts_blacks;
+ (NSArray<NSString *> *)fts_indexes;
+ (NSString *)fts_module;
+ (NSString *)fts_tokenizer;
@end

@interface VVOrmConfig (VVFtsable)

+ (instancetype)configWithFtsable:(Class<VVFtsable>)cls;

@end

@interface VVOrm (VVFtsable)
/// Initialize orm, auto create/modify defalut table, use temporary db.
/// @param clazz class confirm to VVFtsable
+ (nullable instancetype)ormWithFtsClass:(Class<VVFtsable>)clazz;

/// Initialize orm, auto create/modify table and indexes, check and create table immediately
/// @param clazz class confirm to VVFtsable
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
+ (nullable instancetype)ormWithFtsClass:(Class<VVFtsable>)clazz
                                    name:(nullable NSString *)name
                                database:(nullable VVDatabase *)vvdb;

/// Initialize orm, auto create/modify table and indexes
/// @param clazz class confirm to VVFtsable
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
/// @param setup check and create table or not
+ (nullable instancetype)ormWithFtsClass:(Class<VVFtsable>)clazz
                                    name:(nullable NSString *)name
                                database:(nullable VVDatabase *)vvdb
                                   setup:(VVOrmSetup)setup;

@end

NS_ASSUME_NONNULL_END
