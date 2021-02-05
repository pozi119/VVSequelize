//
//  VVOrm.m
//  VVSequelize
//
//  Created by Valo on 2018/6/6.
//

#import "VVOrm.h"
#import "NSObject+VVOrm.h"

#define VV_NO_WARNING(exp) if (exp) {}

@interface VVOrm ()
@property (nonatomic, assign) BOOL created;
@property (nonatomic, copy) NSString *content_table;
@property (nonatomic, copy) NSString *content_rowid;
@property (nonatomic, strong) NSArray<NSString *> *existingIndexes;
@end

@implementation VVOrm

//MARK: - Public
+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
{
    return [self ormWithConfig:config name:nil database:nil];
}

+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                                  name:(nullable NSString *)name
                              database:(nullable VVDatabase *)vvdb
{
    return [self ormWithConfig:config name:name database:vvdb setup:VVOrmSetupCreate];
}

+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                                  name:(nullable NSString *)name
                              database:(nullable VVDatabase *)vvdb
                                 setup:(VVOrmSetup)setup
{
    VVOrm *orm = [vvdb.orms objectForKey:name];
    if (orm) return orm;

    orm = [[VVOrm alloc] initWithConfig:config name:name database:vvdb];
    if (setup == VVOrmSetupCreate) [orm createTableAndIndexes];
    else if (setup == VVOrmSetupRebuild) [orm rebuildTableAndIndexes];
    [vvdb.orms setObject:orm forKey:name];
    return orm;
}

+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                                  name:(nullable NSString *)name
                              database:(nullable VVDatabase *)vvdb
                         content_table:(nullable NSString *)content_table
                         content_rowid:(nullable NSString *)content_rowid
                                 setup:(VVOrmSetup)setup
{
    VVOrm *orm = [vvdb.orms objectForKey:name];
    if (orm) return orm;

    orm = [[VVOrm alloc] initWithConfig:config name:name database:vvdb];
    orm.content_table = content_table;
    orm.content_rowid = content_rowid;
    if (setup == VVOrmSetupCreate) [orm createTableAndIndexes];
    else if (setup == VVOrmSetupRebuild) [orm rebuildTableAndIndexes];
    [vvdb.orms setObject:orm forKey:name];
    return orm;
}

+ (nullable instancetype)ormWithConfig:(VVOrmConfig *)config
                              relative:(VVOrm *)relativeORM
                         content_rowid:(nullable NSString *)content_rowid
{
    NSString *fts_table = [NSString stringWithFormat:@"fts_%@", relativeORM.name];
    VVOrm *orm = [relativeORM.vvdb.orms objectForKey:fts_table];
    if (orm) return orm;

    config.blackList = config.blackList ? [config.blackList arrayByAddingObject:content_rowid] : @[content_rowid];
    [config treate];
    VVOrmConfig *cfg = relativeORM.config;
    NSSet *cfgColsSet = [NSSet setWithArray:cfg.columns];
    NSSet *colsSet = [NSSet setWithArray:config.columns];
    BOOL valid = (config.fts && !cfg.fts) &&
        ((cfg.primaries.count == 1 && [cfg.primaries.firstObject isEqualToString:content_rowid]) ||
         [cfg.uniques containsObject:content_rowid]) &&
        [colsSet isSubsetOfSet:cfgColsSet] &&
        [cfg.columns containsObject:content_rowid];
    if (!valid) {
        NSAssert(NO, @"The following conditions must be met:\n"
                 "1. The relative ORM is the universal ORM\n"
                 "2. The relative ORM has uniqueness constraints\n"
                 "3. The relative ORM contains all fields of this ORM\n"
                 "4. The relative ORM contains the content_rowid\n");
    }

    orm = [[VVOrm alloc] initWithConfig:config name:fts_table database:relativeORM.vvdb];
    orm.content_table = relativeORM.name;
    orm.content_rowid = content_rowid;

    if (!relativeORM.created) [relativeORM rebuildTableAndIndexes];
    [orm rebuildTableAndIndexes];

    NSArray * (^ map)(NSArray<NSString *> *, NSString *) = ^(NSArray<NSString *> *array, NSString *prefix) {
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:array.count];
        for (NSString *string in array) {
            [results addObject:[NSString stringWithFormat:@"%@.%@", prefix, string]];
        }
        return results.copy;
    };

    NSString *ins_rows = [[@[@"rowid"] arrayByAddingObjectsFromArray:config.columns] componentsJoinedByString:@","];
    NSString *ins_vals = [map([@[content_rowid] arrayByAddingObjectsFromArray:config.columns], @"new") componentsJoinedByString:@","];
    NSString *del_rows = [[@[fts_table, @"rowid"] arrayByAddingObjectsFromArray:config.columns] componentsJoinedByString:@","];
    NSString *del_vals = [[@[@"'delete'"] arrayByAddingObjectsFromArray:map([@[content_rowid] arrayByAddingObjectsFromArray:config.columns], @"old")] componentsJoinedByString:@","];

    NSString *ins_tri_name = [fts_table stringByAppendingString:@"_insert"];
    NSString *del_tri_name = [fts_table stringByAppendingString:@"_delete"];
    NSString *upd_tri_name = [fts_table stringByAppendingString:@"_update"];

    NSString *ins_trigger = [NSString stringWithFormat:@""
                             "CREATE TRIGGER IF NOT EXISTS %@ AFTER INSERT ON %@ BEGIN \n"
                             "INSERT INTO %@ (%@) VALUES (%@); \n"
                             "END;",
                             ins_tri_name, relativeORM.name,
                             fts_table, ins_rows, ins_vals];
    NSString *del_trigger = [NSString stringWithFormat:@""
                             "CREATE TRIGGER IF NOT EXISTS %@ AFTER DELETE ON %@ BEGIN \n"
                             "INSERT INTO %@ (%@) VALUES (%@); \n"
                             "END;",
                             del_tri_name, relativeORM.name,
                             fts_table, del_rows, del_vals];
    NSString *upd_trigger = [NSString stringWithFormat:@""
                             "CREATE TRIGGER IF NOT EXISTS %@ AFTER UPDATE ON %@ BEGIN \n"
                             "INSERT INTO %@ (%@) VALUES (%@); \n"
                             "INSERT INTO %@ (%@) VALUES (%@); \n"
                             "END;",
                             upd_tri_name, relativeORM.name,
                             fts_table, del_rows, del_vals,
                             fts_table, ins_rows, ins_vals];

    [relativeORM.vvdb run:ins_trigger];
    [relativeORM.vvdb run:del_trigger];
    [relativeORM.vvdb run:upd_trigger];

    [relativeORM.vvdb.orms setObject:orm forKey:fts_table];
    return orm;
}

- (nullable instancetype)initWithConfig:(VVOrmConfig *)config
                                   name:(nullable NSString *)name
                               database:(nullable VVDatabase *)vvdb
{
    BOOL valid = config && config.cls && config.columns.count > 0;
    NSAssert(valid, @"Invalid orm config.");
    if (!valid) return nil;
    self = [super init];
    if (self) {
        NSString *tblName = name.length > 0 ? name : NSStringFromClass(config.cls);
        VVDatabase *db = vvdb ? vvdb : [VVDatabase databaseWithPath:nil];
        _config = config;
        _name = tblName;
        _vvdb = db;
    }
    return self;
}

- (BOOL)createTableAndIndexes
{
    if (_created) return YES;
    [_config treate];
    BOOL ret = [self createTable];
    if (ret) _created = YES;
    if (!ret || _config.fts || _config.indexes.count == 0) return ret;
    NSString *indexName = [NSString stringWithFormat:@"vvdb_index_%@", _name];
    BOOL exist = [self.existingIndexes containsObject:indexName];
    if (!exist) {
        ret = [self createIndexes];
    }
    return ret;
}

- (BOOL)createTable
{
    if ([self.vvdb isExist:_name]) {
        return YES;
    }
    NSString *sql = nil;
    // create fts table
    if (_config.fts) {
        sql = [_config createFtsSQLWith:_name content_table:_content_table content_rowid:_content_rowid];
    }
    // create nomarl table
    else {
        sql = [_config createSQLWith:_name];
    }
    // execute create sql
    BOOL ret = [self.vvdb run:sql];
    //NSAssert1(ret, @"Failure to create a table: %@", _name);
    return ret;
}

- (BOOL)createIndexes
{
    _existingIndexes = nil;

    /// fts table do not need this indexes
    if (_config.fts || _config.indexes.count == 0) return YES;

    // create new indexes
    NSString *ascIdx = [NSString stringWithFormat:@"vvdb_asc_idx_%@", _name];
    NSString *descIdx = [NSString stringWithFormat:@"vvdb_desc_idx_%@", _name];

    NSMutableArray *descs = [NSMutableArray arrayWithCapacity:_config.indexes.count];
    for (NSString *col in _config.indexes) {
        [descs addObject:[col stringByAppendingString:@" DESC"]];
    }
    NSString *ascCols = [_config.indexes componentsJoinedByString:@","];
    NSString *descCols = [descs componentsJoinedByString:@","];
    
    NSString *ascIdxSQL = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS %@ on %@ (%@);", ascIdx.quoted, _name.quoted, ascCols];
    NSString *descIdxSQL = [NSString stringWithFormat:@"CREATE INDEX IF NOT EXISTS %@ on %@ (%@);", descIdx.quoted, _name.quoted, descCols];

    BOOL ret1 = [self.vvdb run:ascIdxSQL];
    BOOL ret2 = [self.vvdb run:descIdxSQL];
    BOOL ret = ret1 && ret2;
    if (!ret) {
#if DEBUG
        printf("[VVDB][WARN] Failed create index for table (%s)!", self.name.UTF8String);
#endif
    }
    return ret;
}

- (nullable NSDictionary *)uniqueConditionForObject:(id)object
{
    if (_config.primaries.count > 0) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:0];
        for (NSString *key in _config.primaries) {
            id val = [object valueForKey:key];
            dic[key] = val;
        }
        if (dic.count == _config.primaries.count) {
            return dic;
        }
    }
    for (NSString *key in _config.uniques) {
        id val = [object valueForKey:key];
        if (val) return @{ key: val };
    }
    return nil;
}

- (void)rebuildTableAndIndexes {
    _created = NO;
    VVOrmConfig *tableConfig = [VVOrmConfig configFromTable:_name database:self.vvdb];
    if (!tableConfig) {
        [self createTableAndIndexes];
        return;
    }

    BOOL ret = YES;
    #define checkRollback() { if (!ret) { [self.vvdb rollback]; return; } }

    // add columns
    if (!_config.fts && ![_config isEqualToConfig:tableConfig]) {
        // add columns
        NSMutableOrderedSet *added = [NSMutableOrderedSet orderedSetWithArray:_config.columns];
        [added removeObjectsInArray:tableConfig.columns];

        NSArray *addedColumns = added.array;
        if (addedColumns.count > 0) {
            [self.vvdb begin:VVDBTransactionImmediate];
            for (NSString *column in addedColumns) {
                NSString *alertSQL = [_config alertSQLOfColumn:column table:_name];
                ret = [self.vvdb run:alertSQL];
                if (!ret) break;
                id dflt_val = _config.defaultValues[column];
                if (dflt_val) {
                    NSString *updateSQL = [NSString stringWithFormat:@"UPDATE %@ SET %@ = ?", _name.quoted, column.quoted];
                    [self.vvdb run:updateSQL bind:@[dflt_val]];
                }
            }
            checkRollback();
            [self.vvdb commit];
        }

        tableConfig = [VVOrmConfig configFromTable:_name database:self.vvdb];
        NSMutableOrderedSet *removed = [NSMutableOrderedSet orderedSetWithArray:tableConfig.columns];
        [removed removeObjectsInArray:_config.columns];
        if (removed.count > 0) {
            NSMutableArray *final = [NSMutableArray arrayWithArray:tableConfig.columns];
            [final removeObjectsInArray:removed.array];
            tableConfig.columns = final;
        }
    }

    if (![_config isEqualToConfig:tableConfig]) {
        // modify columns
        [self.vvdb begin:VVDBTransactionImmediate];
        NSString *tempTableName = [NSString stringWithFormat:@"%@_%@", _name, @((NSUInteger)[[NSDate date] timeIntervalSince1970])];
        ret = [self renameToTempTable:tempTableName];
        checkRollback();

        ret =  [self createTableAndIndexes];
        checkRollback();

        NSMutableOrderedSet *columnset = [NSMutableOrderedSet orderedSetWithArray:_config.columns];
        [columnset intersectSet:[NSSet setWithArray:tableConfig.columns]];
        ret = [self.vvdb migrating:columnset.array from:tempTableName to:_name drop:YES];
        checkRollback();

        [self.vvdb commit];
    } else {
        _created = YES;
        // rebuild indexes
        if (![_config isInedexesEqual:tableConfig]) {
            [self.vvdb begin:VVDBTransactionImmediate];
            [self rebuildIndexes];
            checkRollback();
            [self.vvdb commit];
        }
    }
}

- (void)markTableDropped
{
    _created = NO;
}

//MARK: - getter

- (NSArray<NSString *> *)existingIndexes
{
    if (!_existingIndexes) {
        NSString *sql = [NSString stringWithFormat:@"PRAGMA index_list = %@;", _name];
        NSArray *indexes =  [self.vvdb query:sql];
        NSMutableArray *results = [NSMutableArray arrayWithCapacity:indexes.count];
        for (NSDictionary *dic in indexes) {
            NSString *index = dic[@"name"];
            if (index) [results addObject:index];
        }
        _existingIndexes = results;
    }
    return _existingIndexes;
}

//MARK: - Private
- (BOOL)renameToTempTable:(NSString *)tempTableName
{
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@", _name.quoted, tempTableName.quoted];
    BOOL ret = [self.vvdb run:sql];
    //NSAssert1(ret, @"Failure to create a temporary table: %@", tempTableName);
    return ret;
}

- (BOOL)dropOldIndexes {
    if (self.existingIndexes.count == 0) return YES;

    NSMutableString *dropIdxSQL = [NSMutableString stringWithCapacity:0];
    for (NSString *idxName in self.existingIndexes) {
        if ([idxName hasPrefix:@"sqlite_autoindex_"]) continue;
        [dropIdxSQL appendFormat:@"DROP INDEX IF EXISTS %@;", idxName.quoted];
    }
    BOOL ret = [self.vvdb run:dropIdxSQL];
    return ret;
}

- (BOOL)rebuildIndexes
{
    /// fts table do not need this indexes
    if (_config.fts || _config.indexes.count == 0) return YES;

    /// drop old indexes
    BOOL ret = [self dropOldIndexes];
    if (!ret) {
#if DEBUG
        printf("[VVDB][WARN] Failed create index for table (%s)!", self.name.UTF8String);
#endif
        return ret;
    }

    ret = [self createIndexes];
    if (ret) _existingIndexes = nil;

    if (!ret) {
#if DEBUG
        printf("[VVDB][WARN] Failed create index for table (%s)!", self.name.UTF8String);
#endif
    }
    return ret;
}

@end
