//
//  VVOrmable.h
//  VVSequelize
//
//  Created by Valo on 2020/7/29.
//

#import <Foundation/Foundation.h>
#import "VVOrm.h"

NS_ASSUME_NONNULL_BEGIN

@class VVForeignKey;
@protocol VVOrmable <NSObject>
@optional
+ (NSArray<NSString *> *)primaries;
+ (NSArray<NSString *> *)whites;
+ (NSArray<NSString *> *)blacks;
+ (NSArray<NSString *> *)indexes;
+ (NSArray<NSString *> *)notnulls;
+ (NSArray<NSString *> *)uniques;
+ (BOOL)logAt;
+ (BOOL)pkAutoInc;

/// {field: value}: value can be NSString,NSNumber,NSData
+ (NSDictionary<NSString *, id> *)defaultValues;

#ifdef VVSEQUELIZE_CONSTRAINTS
/// foreign keys
+ (NSArray<VVForeignKey *> *)foreignKeys;

/// [expression]: expression is similar to `field > 0`
+ (NSArray<NSString *> *)checks;
#endif

@end

@interface VVOrmConfig (VVOrmable)

+ (instancetype)configWithOrmable:(Class<VVOrmable>)cls;

@end

@interface VVOrm (VVOrmable)
/// Initialize orm, auto create/modify defalut table, use temporary db.
/// @param clazz class confirm to VVOrmable
+ (nullable instancetype)ormWithClass:(Class<VVOrmable>)clazz;

/// Initialize orm, auto create/modify table and indexes, check and create table immediately
/// @param clazz class confirm to VVOrmable
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
+ (nullable instancetype)ormWithClass:(Class<VVOrmable>)clazz
                                 name:(nullable NSString *)name
                             database:(nullable VVDatabase *)vvdb;

/// Initialize orm, auto create/modify table and indexes
/// @param clazz class confirm to VVOrmable
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
/// @param setup check and create table or not
+ (nullable instancetype)ormWithClass:(Class<VVOrmable>)clazz
                                 name:(nullable NSString *)name
                             database:(nullable VVDatabase *)vvdb
                                setup:(VVOrmSetup)setup;

@end

NS_ASSUME_NONNULL_END
