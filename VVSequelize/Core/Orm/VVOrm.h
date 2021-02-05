//
//  VVOrm.h
//  VVSequelize
//
//  Created by Valo on 2018/6/6.
//

#import <Foundation/Foundation.h>
#import "VVOrmDefs.h"
#import "VVDatabase.h"
#import "VVOrmConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSUInteger, VVOrmSetup) {
    VVOrmSetupNoCreation = 0,
    VVOrmSetupCreate,
    VVOrmSetupRebuild,
};

/// Object Relational Mapping
@interface VVOrm : NSObject
/// orm configration
@property (nonatomic, strong, readonly) VVOrmConfig *config;
/// databse
@property (nonatomic, strong, readonly) VVDatabase *vvdb;
/// table name in VVOrm , view name in VVOrmView
@property (nonatomic, copy, readonly) NSString *name;
/// the table has been created
@property (nonatomic, assign, readonly) BOOL created;
/// class of queried objects
@property (nonatomic, strong) Class metaClass;

- (instancetype)init __attribute__((unavailable("use initWithConfig:name:database: instead.")));
+ (instancetype)new __attribute__((unavailable("use initWithConfig:name:database: instead.")));

/// Initialize orm, auto create/modify defalut table, use temporary db.
/// @param config orm configuration
+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config;

/// Initialize orm, auto create/modify table and indexes, check and create table immediately
/// @param config orm configuration
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                                  name:(nullable NSString *)name
                              database:(nullable VVDatabase *)vvdb;

/// Initialize orm, auto create/modify table and indexes
/// @param config orm configuration
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
/// @param setup check and create table or not
+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                                  name:(nullable NSString *)name
                              database:(nullable VVDatabase *)vvdb
                                 setup:(VVOrmSetup)setup;

/// Initialize fts orm
/// @param config orm configuration
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
/// @param content_table extenal content table
/// @param content_rowid relative content_rowid
/// @param setup check and create table or not
+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                                  name:(nullable NSString *)name
                              database:(nullable VVDatabase *)vvdb
                         content_table:(nullable NSString *)content_table
                         content_rowid:(nullable NSString *)content_rowid
                                 setup:(VVOrmSetup)setup;

/// Initialize fts orm
/// @param config orm configuration
/// @param relativeORM  relative universal orm
/// @param content_rowid relative content_rowid
+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                              relative:(VVOrm *)relativeORM
                         content_rowid:(nullable NSString *)content_rowid;

/// Initialize orm, do not create/modify table and indexes
/// @param config orm configuration
/// @param name table name, nil means to use class name
/// @param vvdb db, nil means to use temporary db
/// @attention call `inspectExistingTable` and `setupTableWith:` in turns to create/modify table and indexes.
- (nullable instancetype)initWithConfig:(VVOrmConfig *)config
                                   name:(nullable NSString *)name
                               database:(nullable VVDatabase *)vvdb NS_DESIGNATED_INITIALIZER;

/// create table manually
- (BOOL)createTableAndIndexes;

///compare and update table structures
- (void)rebuildTableAndIndexes;

/// rebuild indexes
- (BOOL)rebuildIndexes;

/// mark this table has been dropped
- (void)markTableDropped;

/// get unique condition, use to update/delete
- (nullable NSDictionary *)uniqueConditionForObject:(id)object;
@end

NS_ASSUME_NONNULL_END
