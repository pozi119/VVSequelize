//
//  VVDatabase.h
//  VVSequelize
//
//  Created by Valo on 2019/3/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct sqlite3 sqlite3;

///memory database path
FOUNDATION_EXPORT NSString *const VVDBPathInMemory;
/// temporary database path
FOUNDATION_EXPORT NSString *const VVDBPathTemporary;
/// SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
FOUNDATION_EXPORT int VVDBEssentialFlags;

/// sqlite3 transaction type
///
/// VVDBTransactionDeferred: `BEGIN DEFERRED`
/// VVDBTransactionImmediate: `BEGIN IMMEDIATE`
/// VVDBTransactionExclusive: `BEGIN EXCLUSIVE`
typedef NS_ENUM (NSUInteger, VVDBTransaction) {
    VVDBTransactionDeferred,
    VVDBTransactionImmediate,
    VVDBTransactionExclusive,
};

/// retry handler
/// @param times retry times
/// @return 0 stop retry; >0 retry.
typedef int (^VVDBBusyHandler)(int times);

/// trace sql
/// @param mask SQLITE_TRACE_STMT, SQLITE_TRACE_PROFILE, SQLITE_TRACE_ROW, SQLITE_TRACE_CLOSE
/// @param stmt  sqlite3_stmt structure
/// @return SQLITE_OK,SQLITE_DONE, etc..
typedef int (^VVDBTraceHook)(unsigned mask, void *stmt, void *sql);

/// hook update
/// @param op type: such as SQLITE_INSERT, SQLITE_DELETE, SQLITE_UPDATE
/// @param db sqlite3_db structure
typedef void (^VVDBUpdateHook)(int op, char const *db, char const *table, int64_t rowid);

/// hook transaction
/// @return 0-commit, else - rollback
typedef int (^VVDBCommitHook)(void);

///hook rollback
typedef void (^VVDBRollbackHook)(void);

/// trace error
typedef void (^VVDBTraceError)(int rc, NSString *sql, NSString *errmsg);

@class VVDBStatement;

/**
 Sequelize database
 */
@interface VVDatabase : NSObject

/// db file full path
@property (nonatomic, copy, readonly) NSString *path;

///encrypt key, nil means no encryption
@property (nonatomic, copy, nullable) NSString *encryptKey;

///third parameter of sqlite3_open_v2(), (flags | VVDBEssentialFlags)
@property (nonatomic, assign) int flags;

/// execute between sqlite3_open_v2() and sqlite3_key()
///
/// example:
///
/// "pragma cipher_default_plaintext_header_size = 32;"
///
@property (nonatomic, strong) NSArray<NSString *> *cipherDefaultOptions;

/// execute after sqlite3_key_v2()
///
/// example: open 3.x ciphered database
///
/// "pragma kdf_iter = 64000;"
///
/// "pragma cipher_hmac_algorithm = HMAC_SHA1;"
///
/// "pragma cipher_kdf_algorithm = PBKDF2_HMAC_SHA1;"
///
@property (nonatomic, strong) NSArray<NSString *> *cipherOptions;

/// execute after cipherOptions
///
/// example:
///
/// "PRAGMA synchronous = NORMAL"
///
/// "PRAGMA journal_mode = WAL"
///
@property (nonatomic, strong) NSArray<NSString *> *normalOptions;

/// remove file when SQLITE_NOTADB, default is NO
@property (nonatomic, assign) BOOL removeWhenNotADB;

///serial write queue
@property (nonatomic, strong, readonly) dispatch_queue_t writeQueue;

///concurrent read queue
@property (nonatomic, strong, readonly) dispatch_queue_t readQueue;

///db is open or not
@property (nonatomic, assign, readonly) BOOL isOpen;

///last changes  for sqlite3_exec()
@property (nonatomic, assign, readonly) int changes;

///total changes after db open
@property (nonatomic, assign, readonly) int totalChanges;

///last insert rowid
@property (nonatomic, assign, readonly) int64_t lastInsertRowid;

+ (instancetype)new __attribute__((unavailable("use initWithPath: instead.")));
- (instancetype)init __attribute__((unavailable("use initWithPath: instead.")));

/// open/create db
/// @param path db file full path
- (instancetype)initWithPath:(nullable NSString *)path;

/// open/create db,  no encryption, use `VVDBEssentialFlags` by default
/// @param path db file full path
+ (instancetype)databaseWithPath:(nullable NSString *)path;

/// open/create db,  no encryption
/// @param path db file full path
/// @param flags third parameter of sqlite3_open_v2,  (flags | VVDBEssentialFlags)
+ (instancetype)databaseWithPath:(nullable NSString *)path flags:(BOOL)flags;

/// open/create db
/// @param path db file full path
/// @param flags third parameter of sqlite3_open_v2,  (flags | VVDBEssentialFlags)
/// @param key encrypt key
+ (instancetype)databaseWithPath:(nullable NSString *)path flags:(int)flags encrypt:(nullable NSString *)key;

//MARK: - open and close
/// open db
/// @note add lazy loading, can no longer be executed
- (BOOL)open;

/// close db
- (BOOL)close;

// MARK: - queue
/// synchronous operation,  in writeQueue
/// @param block operation
- (void)sync:(void (^)(void))block;

// MARK: - Execute

/// use sqlite3_exec() execute native sql statement
/// @param sql native sql
- (BOOL)execute:(NSString *)sql;

// MARK: - Prepare
- (VVDBStatement *)prepare:(NSString *)sql;

- (VVDBStatement *)prepare:(NSString *)sql bind:(nullable NSArray *)values;

// MARK: - Run

/// execute native sql query
/// @param sql native sql
/// @return query results
/// @attention cache results.  clear cache after update/insert/delete/commit.
- (NSArray<NSDictionary *> *)query:(NSString *)sql;

/// execute native sql query
/// @param values corresponding to `?` In sql
- (NSArray<NSDictionary *> *)query:(NSString *)sql bind:(NSArray *)values;

/// execute native sql query
/// @param sql native sqls
/// @param clazz results class
/// @return query results
/// @attention cache results.  clear cache after update/insert/delete/commit.
- (NSArray *)query:(NSString *)sql clazz:(Class)clazz;

/// execute native sql query
/// @param values corresponding to `?` In sql
- (NSArray *)query:(NSString *)sql bind:(NSArray *)values clazz:(Class)clazz;

/// check if table exists
/// @param table name
- (BOOL)isExist:(NSString *)table;

/// use sqlite3_step() execute native sql statement
/// @param sql native sql
- (BOOL)run:(NSString *)sql;

/// use sqlite3_step() execute native sql statement
/// @param sql native sql
/// @param values bind values
- (BOOL)run:(NSString *)sql bind:(nullable NSArray *)values;

// MARK: - Scalar
- (id)scalar:(NSString *)sql bind:(nullable NSArray *)values;

// MARK: - Transactions

/// begin transaction
/// @param mode transaction mode
- (BOOL)begin:(VVDBTransaction)mode;

/// commit transaction
- (BOOL)commit;

/// rollback transaction
- (BOOL)rollback;

/// save point, use to rollback some transaction.such as:
/// 1.set savepoint a
/// 2.rollback to a or rollback all
/// @note commit will delete all save point
/// @param name save point name
/// @param block operation
- (BOOL)savepoint:(NSString *)name block:(BOOL (^)(void))block;

/// immediate transaction
- (BOOL)transaction:(BOOL (^)(void))block;

/// transaction
/// @param mode transaction mode
/// @param block operation
- (BOOL)transaction:(VVDBTransaction)mode block:(BOOL (^)(void))block;

/// interrupt some operation manually
- (void)interrupt;

// MARK: - Handlers
///db busy time out
@property (nonatomic, assign) NSTimeInterval timeout;

///callback when timeout
@property (nonatomic, copy) VVDBBusyHandler busyHandler;

///trace sql
@property (nonatomic, copy) VVDBTraceHook traceHook;

///hook update
@property (nonatomic, copy) VVDBUpdateHook updateHook;

///hook commit
@property (nonatomic, copy) VVDBCommitHook commitHook;

///hook rollback
@property (nonatomic, copy) VVDBRollbackHook rollbackHook;

///error handler
@property (nonatomic, copy) VVDBTraceError traceError;

// MARK: - Error Handling
/// check sqlite3 return value
/// @param resultCode sqlite3 return value
/// @param sql success or not
- (BOOL)check:(int)resultCode sql:(NSString *)sql;

/// last error code
- (int)lastErrorCode;

/// last error infomation
- (NSError *)lastError;

// MARK: - Utils

/// migrating data to a new table
/// @param columns columns to migrate
/// @param drop drop source table
- (BOOL)migrating:(NSArray<NSString *> *)columns
             from:(NSString *)fromTable
               to:(NSString *)toTable
             drop:(BOOL)drop;

- (void)metadata:(nullable NSString *)dbname
           table:(NSString *)table
          column:(NSString *)column
        dataType:(NSString *_Nullable *_Nullable)dataType
         notnull:(nullable int *)notnull
              pk:(nullable int *)pk
       pkAutoInc:(nullable int *)pkAutoInc;

// MARK: - cipher
#ifdef SQLITE_HAS_CODEC
/// sqlite3 cipher verision
@property (nonatomic, copy) NSString *cipherVersion;

/// set encrypt key for db
/// @param key encrypt key
- (BOOL)key:(NSString *)key db:(nullable NSString *)db;

/// modify encrypt key
/// @param key encrypt key
- (BOOL)rekey:(NSString *)key db:(nullable NSString *)db;

/// check for encryption, usually called when the database is opened but the encryption key is not se
- (BOOL)cipherKeyCheck;
#endif

//MARK: - private
/// sqlite3 structure
@property (nonatomic, assign, readonly) sqlite3 *db;

/// orm cache
@property (nonatomic, strong, readonly) NSMapTable *orms;

#ifdef VVSEQUELIZE_FTS
@property (nonatomic, strong) NSMutableDictionary *enumerators;
#endif

@end

NS_ASSUME_NONNULL_END
