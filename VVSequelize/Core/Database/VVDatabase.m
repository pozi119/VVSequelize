//
//  VVDatabase.m
//  VVSequelize
//
//  Created by Valo on 2019/3/19.
//

#import "VVDatabase.h"
#import "VVOrm.h"
#import "VVDBStatement.h"
#import "NSObject+VVOrm.h"
#import "NSObject+VVKeyValue.h"
#import "VVDatabase+Additions.h"

#ifdef SQLITE_HAS_CODEC
#import "sqlite3.h"
#else
#import <sqlite3.h>
#endif

#ifdef VVSEQUELIZE_FTS
#import "VVDatabase+FTS.h"
#endif

NSString *const VVDBPathInMemory = @":memory:";
NSString *const VVDBPathTemporary = @"";
NSString *const VVDBErrorDomain = @"com.sequelize.db";

int VVDBEssentialFlags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE;
static const char *const VVDBSpecificKey = "com.sequelize.db.specific";

// MARK: - sqlite callbacks
static int vvdb_busy_callback(void *pCtx, int times)
{
    VVDatabase *vvdb = (__bridge VVDatabase *)pCtx;
    return !vvdb.busyHandler ? 0 : vvdb.busyHandler(times);
}

static int vvdb_trace_callback(unsigned mask, void *pCtx, void *p, void *x)
{
    VVDatabase *vvdb = (__bridge VVDatabase *)pCtx;
    return !vvdb.traceHook ? 0 : vvdb.traceHook(mask, p, x);
}

static void vvdb_update_hook(void *pCtx, int op, char const *db, char const *table, int64_t rowid)
{
    VVDatabase *vvdb = (__bridge VVDatabase *)pCtx;
    if (vvdb.updateHook) vvdb.updateHook(op, db, table, rowid);
}

static int vvdb_commit_hook(void *pCtx)
{
    VVDatabase *vvdb = (__bridge VVDatabase *)pCtx;
    return !vvdb.commitHook ? 0 : vvdb.commitHook();
}

static void vvdb_rollback_hook(void *pCtx)
{
    VVDatabase *vvdb = (__bridge VVDatabase *)pCtx;
    if (vvdb.rollbackHook) vvdb.rollbackHook();
}

static dispatch_queue_t dispatch_create_db_queue(NSString *_Nullable tag, NSString *type, dispatch_queue_attr_t _Nullable attr)
{
    static NSUInteger i = 0;
    NSString *label = [NSString stringWithFormat:@"com.sequelize.db.%@.%@.%@", tag ? : @"temp", type, @(i++)];
    dispatch_queue_t queue = dispatch_queue_create(label.UTF8String, attr);
    dispatch_queue_set_specific(queue, VVDBSpecificKey, (__bridge void *)queue, NULL);
    return queue;
}

// MARK: -
@interface VVDatabase ()
@property (nonatomic, copy) NSString *path;
@property (nonatomic, assign) sqlite3 *db;
@property (nonatomic, strong) NSMapTable *orms;
@property (nonatomic, assign) BOOL inTransaction;
@end

@implementation VVDatabase
@synthesize readQueue = _readQueue;
@synthesize writeQueue = _writeQueue;

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        _path = path;
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

+ (instancetype)databaseWithPath:(nullable NSString *)path
{
    return [VVDatabase databaseWithPath:path flags:0 encrypt:nil];
}

+ (instancetype)databaseWithPath:(nullable NSString *)path flags:(BOOL)flags
{
    return [VVDatabase databaseWithPath:path flags:flags encrypt:nil];
}

+ (instancetype)databaseWithPath:(nullable NSString *)path flags:(int)flags encrypt:(nullable NSString *)key
{
    VVDatabase *vvdb = [[VVDatabase alloc] initWithPath:path];
    vvdb.path = path;
    vvdb.flags = flags;
    vvdb.encryptKey = key;
    return vvdb;
}

//MARK: - open and close
- (BOOL)open
{
    if (_db) return YES;
    int rc = sqlite3_open_v2(self.path.UTF8String, &_db, self.flags, NULL);
    BOOL ret = [self check:rc sql:@"sqlite3_open_v2()"];
    //NSAssert1(ret, @"failed to open sqlite3: %@", self.path);
    if (!ret) return NO;

    // hook
    if (_updateHook) sqlite3_update_hook(_db, vvdb_update_hook, (__bridge void *)self);
    if (_commitHook) sqlite3_commit_hook(_db, vvdb_commit_hook, (__bridge void *)self);
    if (_timeout > 0) sqlite3_busy_timeout(_db, (int32_t)(_timeout * 1000));
    if (_busyHandler) sqlite3_busy_handler(_db, vvdb_busy_callback, (__bridge void *)self);
    if (_traceHook) sqlite3_trace_v2(_db, SQLITE_TRACE_STMT, vvdb_trace_callback, (__bridge void *)self);
    if (_rollbackHook) sqlite3_rollback_hook(_db, vvdb_rollback_hook, (__bridge void *)self);

#ifdef SQLITE_HAS_CODEC
    for (NSString *sql in self.cipherDefaultOptions) {
        rc = sqlite3_exec(_db, sql.UTF8String, nil, nil, nil);
        [self check:rc sql:sql];
    }
    if (self.encryptKey.length > 0) {
        const char *key = self.encryptKey.UTF8String;
        int klen = (int)strlen(key);
        rc = sqlite3_key(_db, key, klen);
        [self check:rc sql:@"sqlite3_key()"];
    }
    for (NSString *sql in self.cipherOptions) {
        rc = sqlite3_exec(_db, sql.UTF8String, nil, nil, nil);
        [self check:rc sql:sql];
    }
#endif
    for (NSString *sql in self.normalOptions) {
        rc = sqlite3_exec(_db, sql.UTF8String, nil, nil, nil);
        [self check:rc sql:sql];
    }

#ifdef VVSEQUELIZE_FTS
    [self registerEnumerators:_db];
#endif
    return ret;
}

- (BOOL)close
{
    __block BOOL ret = YES;
    [self sync:^{
        if (self->_db != NULL) {
            ret = [self check:sqlite3_close_v2(self->_db) sql:@"sqlite3_close_v2()"];
            if (ret) self->_db = NULL;
        }
    }];
    return ret;
}

//MARK: - lazy loading
- (sqlite3 *)db
{
    [self sync:^{
        if (!self->_db) [self open];
    }];
    return _db;
}

#ifdef VVSEQUELIZE_FTS

- (NSMutableDictionary *)enumerators {
    if (!_enumerators) {
        _enumerators = [NSMutableDictionary dictionary];
    }
    return _enumerators;
}

#endif

- (int)flags
{
    if ((_flags & VVDBEssentialFlags) != VVDBEssentialFlags) {
        _flags |= VVDBEssentialFlags;
    }
    return _flags;
}

- (NSString *)path
{
    if (!_path) {
        _path = VVDBPathTemporary;
    }
    return _path;
}

- (NSMapTable *)orms {
    if (!_orms) {
        _orms = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsWeakMemory];
    }
    return _orms;
}

- (NSArray<NSString *> *)normalOptions
{
    if (!_normalOptions) {
        _normalOptions = @[@"pragma synchronous = normal;",
                           @"pragma journal_mode = wal;"];
    }
    return _normalOptions;
}

- (dispatch_queue_t)writeQueue
{
    if (!_writeQueue) {
        NSString *tag = self.path.lastPathComponent;
        _writeQueue = dispatch_create_db_queue(tag, @"w", DISPATCH_QUEUE_SERIAL);
    }
    return _writeQueue;
}

- (dispatch_queue_t)readQueue
{
    if (!_readQueue) {
        NSString *tag = self.path.lastPathComponent;
        _readQueue = dispatch_create_db_queue(tag, @"r", DISPATCH_QUEUE_CONCURRENT);
    }
    return _readQueue;
}

// MARK: - getter
- (BOOL)isOpen
{
    return _db != NULL;
}

- (BOOL)readonly
{
    return sqlite3_db_readonly(self.db, nil) == 1;
}

- (int)changes
{
    return (int)sqlite3_changes(self.db);
}

- (int)totalChanges
{
    return (int)sqlite3_total_changes(self.db);
}

- (int64_t)lastInsertRowid
{
    return sqlite3_last_insert_rowid(self.db);
}

// MARK: - queue
- (void)sync:(void (^)(void))block
{
    if (dispatch_get_specific(VVDBSpecificKey) == (__bridge void *)self.writeQueue) {
        block();
    } else {
        dispatch_sync(self.writeQueue, block);
    }
}

// MARK: - Execute
- (BOOL)execute:(NSString *)sql
{
    __block int rc = 0;
    [self sync:^{
        rc = sqlite3_exec(self.db, sql.UTF8String, nil, nil, nil);
    }];
    return [self check:rc sql:sql];
}

// MARK: - Prepare
- (VVDBStatement *)prepare:(NSString *)sql
{
    return [VVDBStatement statementWithDatabase:self sql:sql];
}

- (VVDBStatement *)prepare:(NSString *)sql bind:(NSArray *)values
{
    VVDBStatement *statement = [VVDBStatement statementWithDatabase:self sql:sql];
    return [statement bind:values];
}

// MARK: - Run
- (NSArray<NSDictionary *> *)query:(NSString *)sql
{
    return [[self prepare:sql] query];
}

- (NSArray<NSDictionary *> *)query:(NSString *)sql bind:(NSArray *)values
{
    return [[self prepare:sql bind:values] query];
}

- (NSArray *)query:(NSString *)sql clazz:(Class)clazz
{
    NSArray *array = [self query:sql];
    return [clazz vv_objectsWithKeyValuesArray:array];
}

- (NSArray *)query:(NSString *)sql bind:(NSArray *)values clazz:(Class)clazz
{
    NSArray *array = [self query:sql bind:values];
    return [clazz vv_objectsWithKeyValuesArray:array];
}

- (BOOL)isExist:(NSString *)table
{
    NSString *sql = [NSString stringWithFormat:@"SELECT 1 FROM %@ LIMIT 0", table.singleQuoted];
    sqlite3_stmt *pStmt;
    int rc = sqlite3_prepare_v2(self.db, sql.UTF8String, -1, &pStmt, nil);
    if (rc == SQLITE_OK) {
        rc = sqlite3_step(pStmt);
        sqlite3_finalize(pStmt);
        if (rc == SQLITE_DONE) rc = SQLITE_OK;
    }
    return rc == SQLITE_OK;
}

- (BOOL)run:(NSString *)sql
{
    return [[self prepare:sql] run];
}

- (BOOL)run:(NSString *)sql bind:(NSArray *)values
{
    return [[self prepare:sql bind:values] run];
}

// MARK: - Scalar
- (id)scalar:(NSString *)sql bind:(nullable NSArray *)values
{
    VVDBStatement *statement = [VVDBStatement statementWithDatabase:self sql:sql];
    return [statement scalar:values];
}

// MARK: - Transactions
- (BOOL)begin:(VVDBTransaction)mode
{
    if (_inTransaction) return YES;
    NSString *sql = nil;
    switch (mode) {
        case VVDBTransactionImmediate:
            sql = @"BEGIN IMMEDIATE";
            break;
        case VVDBTransactionExclusive:
            sql = @"BEGIN EXCLUSIVE";
            break;
        default:
            sql = @"BEGIN DEFERRED";
            break;
    }
    BOOL ret = [[self prepare:sql] run];
    if (ret) _inTransaction = YES;
    return ret;
}

- (BOOL)commit
{
    if (!_inTransaction) return YES;
    BOOL ret = [[self prepare:@"COMMIT"] run];
    if (ret) _inTransaction = NO;
    return ret;
}

- (BOOL)rollback
{
    if (!_inTransaction) return YES;
    BOOL ret = [[self prepare:@"ROLLBACK"] run];
    if (ret) _inTransaction = NO;
    return ret;
}

- (BOOL)savepoint:(NSString *)name block:(BOOL (^)(void))block
{
    NSString *savepoint = [NSString stringWithFormat:@"SAVEPOINT %@", name.quoted];
    NSString *commit = [NSString stringWithFormat:@"RELEASE %@", savepoint];
    NSString *rollback = [NSString stringWithFormat:@"ROLLBACK TO %@", savepoint];
    return [self transaction:savepoint commit:commit rollback:rollback block:block];
}

- (BOOL)transaction:(BOOL (^)(void))block
{
    return [self transaction:VVDBTransactionImmediate block:block];
}

- (BOOL)transaction:(VVDBTransaction)mode block:(BOOL (^)(void))block
{
    NSString *begin = nil;
    switch (mode) {
        case VVDBTransactionImmediate:
            begin = @"BEGIN IMMEDIATE";
            break;
        case VVDBTransactionExclusive:
            begin = @"BEGIN EXCLUSIVE";
            break;
        default:
            begin = @"BEGIN DEFERRED";
            break;
    }
    NSString *commit = @"COMMIT";
    NSString *rollback = @"ROLLBACK";
    return [self transaction:begin commit:commit rollback:rollback block:block];
}

- (BOOL)transaction:(NSString *)begin
             commit:(NSString *)commit
           rollback:(NSString *)rollback
              block:(BOOL (^)(void))block
{
    if (!block) {
        return YES;
    }
    if (_inTransaction) {
        return block();
    }
    BOOL ret = [[self prepare:begin] run];
    if (!ret) {
        return block();
    }
    _inTransaction = YES;
    ret = block();
    if (ret) {
        ret = [[self prepare:commit] run];
    } else {
        [[self prepare:rollback] run];
    }
    _inTransaction = NO;
    return ret;
}

- (void)interrupt
{
    sqlite3_interrupt(self.db);
}

// MARK: - handlers
- (void)setUpdateHook:(VVDBUpdateHook)updateHook
{
    _updateHook = updateHook;
    if (!_db) return;
    if (!updateHook) {
        sqlite3_update_hook(_db, NULL, NULL);
    } else {
        sqlite3_update_hook(_db, vvdb_update_hook, (__bridge void *)self);
    }
}

- (void)setCommitHook:(VVDBCommitHook)commitHook
{
    _commitHook = commitHook;
    if (!_db) return;
    if (!commitHook) {
        sqlite3_commit_hook(_db, NULL, NULL);
    } else {
        sqlite3_commit_hook(_db, vvdb_commit_hook, (__bridge void *)self);
    }
}

- (void)setTimeout:(NSTimeInterval)timeout
{
    _timeout = timeout;
    if (!_db) return;
    sqlite3_busy_timeout(_db, (int32_t)(timeout * 1000));
}

- (void)setbusyHandler:(VVDBBusyHandler)busyHandler
{
    _busyHandler = busyHandler;
    if (!_db) return;
    if (!busyHandler) {
        sqlite3_busy_handler(_db, NULL, NULL);
    } else {
        sqlite3_busy_handler(_db, vvdb_busy_callback, (__bridge void *)self);
    }
}

- (void)setTraceHook:(VVDBTraceHook)traceHook
{
    _traceHook = traceHook;
    if (!_db) return;
    if (!traceHook) {
        sqlite3_trace_v2(_db, 0, NULL, NULL);
    } else {
        sqlite3_trace_v2(_db, SQLITE_TRACE_STMT, vvdb_trace_callback, (__bridge void *)self);
    }
}

- (void)setRollbackHook:(VVDBRollbackHook)rollbackHook
{
    _rollbackHook = rollbackHook;
    if (!_db) return;
    if (!rollbackHook) {
        sqlite3_rollback_hook(_db, NULL, NULL);
    } else {
        sqlite3_rollback_hook(_db, vvdb_rollback_hook, (__bridge void *)self);
    }
}

// MARK: - Error Handling
- (BOOL)check:(int)resultCode sql:(NSString *)sql
{
    switch (resultCode) {
        case SQLITE_OK:
        case SQLITE_ROW:
        case SQLITE_DONE:
            return YES;

        default: {
            const char *errmsg = sqlite3_errmsg(self.db);
            NSString *msg = [NSString stringWithUTF8String:errmsg];
            if (_traceError) {
                _traceError(resultCode, sql, msg);
            } else {
#if DEBUG
                printf("[VVDB][ERROR] code: %i, error: %s, sql: %s\n", resultCode, errmsg, sql.UTF8String);
#endif
            }
            if (resultCode == SQLITE_NOTADB && _removeWhenNotADB) {
                [self close];
                [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
            }
            return NO;
        }
    }
}

- (int)lastErrorCode
{
    return sqlite3_errcode(self.db);
}

- (NSError *)lastError
{
    int code = sqlite3_errcode(self.db);
    const char *errmsg = sqlite3_errstr(code);
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    userInfo[NSLocalizedFailureReasonErrorKey] = [NSString stringWithUTF8String:errmsg];
    NSError *error = [NSError errorWithDomain:VVDBErrorDomain code:code userInfo:userInfo];
    return error;
}

// MARK: - Utils
- (BOOL)migrating:(NSArray<NSString *> *)columns
             from:(NSString *)fromTable
               to:(NSString *)toTable
             drop:(BOOL)drop
{
    if (columns.count == 0) return YES;

    NSString *allFields = [columns sqlJoin];
    NSString *sql = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@) SELECT %@ FROM %@", toTable.quoted, allFields, allFields, fromTable.quoted];
    BOOL ret = YES;
    ret = [self run:sql];
    if (!ret) {
#if DEBUG
        printf("[VVDB][WARN] migration data from table (%s) to table (%s) failed!", fromTable.UTF8String, toTable.UTF8String);
#endif
        return ret;
    }

    if (ret && drop) {
        sql = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@", fromTable.quoted];
        ret = [self run:sql];
    }

    return ret;
}

- (void)metadata:(NSString *)dbname
           table:(NSString *)table
          column:(NSString *)column
        dataType:(NSString **)dataType
         notnull:(int *)notnull
              pk:(int *)pk
       pkAutoInc:(int *)pkAutoInc
{
    const char *pDataSype = nil;
    sqlite3_table_column_metadata(_db, dbname.UTF8String, table.UTF8String, column.UTF8String, &pDataSype, nil, notnull, pk, pkAutoInc);
    if (dataType) *dataType = [NSString stringWithUTF8String:pDataSype];
}

// MARK: - cipher
#ifdef SQLITE_HAS_CODEC
- (NSString *)cipherVersion
{
    if (!_cipherVersion) {
        _cipherVersion = [self scalar:@"PRAGMA cipher_version" bind:nil];
    }
    return _cipherVersion;
}

- (BOOL)key:(NSString *)key db:(NSString *)db
{
    const char *dbname = db ? db.UTF8String : "main";
    NSData *data = [key dataUsingEncoding:NSUTF8StringEncoding];
    int rc = sqlite3_key_v2(self.db, dbname, data.bytes, (int)data.length);
    return [self check:rc sql:@"sqlite3_key_v2()"];
}

- (BOOL)rekey:(NSString *)key db:(NSString *)db
{
    const char *dbname = db ? db.UTF8String : "main";
    NSData *data = [key dataUsingEncoding:NSUTF8StringEncoding];
    int rc = sqlite3_rekey_v2(self.db, dbname, data.bytes, (int)data.length);
    return [self check:rc sql:@"sqlite3_rekey_v2()"];
}

- (BOOL)cipherKeyCheck
{
    id ret = [self scalar:@"SELECT count(*) FROM sqlite_master;" bind:nil];
    return ret != nil;
}

#endif

@end
