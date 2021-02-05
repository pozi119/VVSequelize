//
//  VVDBStatement.m
//  VVSequelize
//
//  Created by Valo on 2019/3/19.
//

#import "VVDBStatement.h"
#import "VVDatabase.h"
#import "VVOrm.h"

#ifdef SQLITE_HAS_CODEC
#import "sqlite3.h"
#else
#import <sqlite3.h>
#endif

@interface VVDBStatement ()
@property (nonatomic, weak) VVDatabase *vvdb;
@property (nonatomic, copy) NSString *sql;
@property (nonatomic, strong) NSArray *values;
@property (nonatomic, assign) sqlite3_stmt *stmt;
@property (nonatomic, assign) int columnCount;
@property (nonatomic, strong) NSArray<NSString *> *columnNames;
@property (nonatomic, strong) VVDBCursor *cursor;
@end

@implementation VVDBStatement

+ (instancetype)statementWithDatabase:(VVDatabase *)vvdb sql:(NSString *)sql
{
    return [[VVDBStatement alloc] initWithDatabase:vvdb sql:sql];
}

- (instancetype)initWithDatabase:(VVDatabase *)vvdb sql:(NSString *)sql
{
    self = [super init];
    if (self) {
        _vvdb = vvdb;
        _sql = sql;
        int rc = sqlite3_prepare_v2(vvdb.db, sql.UTF8String, -1, &_stmt, nil);
        BOOL ret = [self.vvdb check:rc sql:sql];
        //NSAssert(ret && _stmt != NULL, @"prepare sqlite3_stmt failure: %@, vvdb : %@", sql, vvdb);
        if (!ret) return nil;
    }
    return self;
}

- (void)dealloc
{
    sqlite3_finalize(_stmt);
    _stmt = NULL;
}

//MARK: -
- (int)columnCount
{
    if (!_columnCount) {
        _columnCount = sqlite3_column_count(_stmt);
    }
    return _columnCount;
}

- (NSArray<NSString *> *)columnNames
{
    if (!_columnNames) {
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.columnCount];
        for (int i = 0; i < self.columnCount; i++) {
            const char *col = sqlite3_column_name(_stmt, i);
            [array addObject:[NSString stringWithUTF8String:col]];
        }
        _columnNames = [array copy];
    }
    return _columnNames;
}

- (VVDBCursor *)cursor
{
    if (!_cursor) {
        _cursor = [[VVDBCursor alloc] initWithStatement:self];
    }
    return _cursor;
}

- (VVDBStatement *)bind:(nullable NSArray *)values
{
    int count = (int)values.count;
    if (count == 0) return self;
    _values = values;
    sqlite3_reset(_stmt);
    sqlite3_clear_bindings(_stmt);
    int paramsCount = sqlite3_bind_parameter_count(_stmt);
    NSAssert(count == paramsCount, @"%d values expected, %d passed", paramsCount, count);
    for (int i = 0; i < paramsCount; i++) {
        self.cursor[i] = values[i];
    }
    return self;
}

- (id)scalar:(nullable NSArray *)values
{
    [[self bind:values] step];
    return self.cursor[0];
}

- (BOOL)run
{
    sqlite3_reset(_stmt);
    __block int rc;
    do {
        [self.vvdb sync:^{
            rc = sqlite3_step(self.stmt);
        }];
    } while (rc == SQLITE_ROW);
    return [self.vvdb check:rc sql:_sql];
}

- (NSArray<NSDictionary *> *)query
{
    int columnCount = self.columnCount;
    if (columnCount == 0) return @[];

    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    BOOL rc;
    do {
        rc = [self step];
        if (rc) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:columnCount];
            for (int i = 0; i < columnCount; i++) {
                dic[self.columnNames[i]] = self.cursor[i];
            }
            [array addObject:dic];
        }
    } while (rc);
    return array;
}

- (BOOL)step
{
    return sqlite3_step(_stmt) == SQLITE_ROW;
}

- (void)reset
{
    sqlite3_reset(_stmt);
}

- (void)resetAndClear
{
    sqlite3_reset(_stmt);
    sqlite3_clear_bindings(_stmt);
}

@end

//MARK: -
@interface VVDBCursor ()
@property (nonatomic, assign) sqlite3_stmt *stmt;
@property (nonatomic, assign) int columnCount;
@end

@implementation VVDBCursor

- (instancetype)initWithStatement:(VVDBStatement *)statement
{
    self = [super init];
    if (self) {
        self.stmt = statement.stmt;
        self.columnCount = statement.columnCount;
    }
    return self;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx
{
    int index = (int)idx;
    int type = sqlite3_column_type(_stmt, index);
    switch (type) {
        case SQLITE_INTEGER: {
            return @(sqlite3_column_int64(_stmt, index));
        }
        case SQLITE_FLOAT: {
            return @(sqlite3_column_double(_stmt, index));
        }
        case SQLITE_TEXT: {
            const unsigned char *bytes = sqlite3_column_text(_stmt, index);
            NSString *text = [NSString stringWithUTF8String:(const char *)bytes ? : ""];
            return text;
        }
        case SQLITE_BLOB: {
            const unsigned char *bytes = sqlite3_column_blob(_stmt, index);
            int64_t len = sqlite3_column_bytes(_stmt, index);
            NSData *data = [NSData dataWithBytes:bytes length:(NSUInteger)len];
            return data;
        }
        case SQLITE_NULL: {
            return [NSNull null];
        }
        default: {
            NSAssert(NO, @"unsupported column type: %d", type);
            return [NSNull null];
        }
    }
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
    int index = (int)idx + 1;
    if (obj == nil || [obj isKindOfClass:[NSNull class]]) {
        sqlite3_bind_null(_stmt, index);
    } else if ([obj isKindOfClass:[NSData class]]) {
        NSData *data = (NSData *)obj;
        if (data.length > INT_MAX) {
            sqlite3_bind_blob64(_stmt, index, data.bytes, data.length, SQLITE_TRANSIENT);
        } else {
            sqlite3_bind_blob(_stmt, index, data.bytes, (int)data.length, SQLITE_TRANSIENT);
        }
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)obj;
        switch (number.objCType[0]) {
            case 'B':
                sqlite3_bind_int(_stmt, index, number.boolValue);
                break;

            case 'c':
            case 'C':
            case 's':
            case 'S':
            case 'i':
            case 'I':
                sqlite3_bind_int(_stmt, index, number.intValue);
                break;

            case 'l':
            case 'L':
            case 'q':
            case 'Q':
                sqlite3_bind_int64(_stmt, index, number.longValue);
                break;

            case 'f':
                sqlite3_bind_double(_stmt, index, number.floatValue);
                break;

            case 'd':
            case 'D':
                sqlite3_bind_double(_stmt, index, number.doubleValue);
                break;

            default:
                break;
        }
    } else if ([obj isKindOfClass:[NSString class]]) {
        const char *string = [(NSString *)obj UTF8String];
        sqlite3_bind_text(_stmt, index, string, -1, SQLITE_TRANSIENT);
    } else {
        NSAssert(NO, @"tried to bind unexpected value %@", obj);
    }
}

- (id)objectForKeyedSubscript:(NSString *)key
{
    int idx = sqlite3_bind_parameter_index(_stmt, key.UTF8String);
    return self[idx];
}

- (void)setObject:(id)obj forKeyedSubscript:(NSString *)key
{
    int idx = sqlite3_bind_parameter_index(_stmt, key.UTF8String);
    self[idx] = obj;
}

@end
