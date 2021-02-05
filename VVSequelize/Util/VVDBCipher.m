//
//  VVDBCipher.m
//  VVSequelize
//
//  Created by Valo on 2018/6/19.
//

#ifdef SQLITE_HAS_CODEC

#import "VVDBCipher.h"
#import "sqlite3.h"

@implementation VVDBCipher

+ (BOOL)encrypt:(NSString *)path
            key:(NSString *)key
        options:(NSArray<NSString *> *)options
{
    NSString *target = [NSString stringWithFormat:@"%@-tmpcipher", path];
    if ([self encrypt:path target:target key:key options:options]) {
        [self removeDatabaseFile:path];
        [self moveDatabaseFile:target toPath:path force:YES];
        return YES;
    }
    return NO;
}

+ (BOOL)decrypt:(NSString *)path
            key:(NSString *)key
        options:(NSArray<NSString *> *)options
{
    NSString *target = [NSString stringWithFormat:@"%@-tmpcipher", path];
    if ([self decrypt:path target:target key:key options:options]) {
        [self removeDatabaseFile:path];
        [self moveDatabaseFile:target toPath:path force:YES];
        return YES;
    }
    return NO;
}

+ (BOOL)encrypt:(NSString *)source
         target:(NSString *)target
            key:(NSString *)key
        options:(NSArray<NSString *> *)options
{
    return [self change:source target:target srcKey:nil srcOpts:nil tarKey:key tarOpts:options];
}

+ (BOOL)decrypt:(NSString *)source
         target:(NSString *)target
            key:(NSString *)key
        options:(NSArray<NSString *> *)options
{
    return [self change:source target:target srcKey:key srcOpts:options tarKey:nil tarOpts:nil];
}

+ (BOOL)change:(NSString *)source
        srcKey:(nullable NSString *)srcKey
       srcOpts:(nullable NSArray<NSString *> *)srcOpts
        tarKey:(nullable NSString *)tarKey
       tarOpts:(nullable NSArray<NSString *> *)tarOpts
{
    NSString *target = [NSString stringWithFormat:@"%@-tmpcipher", source];
    if ([self change:source target:target srcKey:srcKey srcOpts:srcOpts tarKey:tarKey tarOpts:tarOpts]) {
        [self removeDatabaseFile:source];
        [self moveDatabaseFile:target toPath:source force:YES];
        return YES;
    }
    return NO;
}

+ (BOOL)change:(NSString *)source
        target:(NSString *)target
        srcKey:(NSString *)srcKey
       srcOpts:(NSArray<NSString *> *)srcOpts
        tarKey:(NSString *)tarKey
       tarOpts:(NSArray<NSString *> *)tarOpts
{
    sqlite3 *db;
    int rc = sqlite3_open(source.UTF8String, &db);
    if (rc != SQLITE_OK) return NO;

    if (srcKey.length > 0) {
        const char *xKey = srcKey.UTF8String ? : "";
        int nKey = (int)strlen(xKey);
        if (nKey == 0) return NO;
        rc = sqlite3_key(db, xKey, nKey);
        if (rc != SQLITE_OK) return NO;
    }
    NSString *attach = [NSString stringWithFormat:@"ATTACH DATABASE '%@' AS tardb KEY '%@';", target, tarKey.length > 0 ? tarKey : @""];
    NSString *export = @"BEGIN IMMEDIATE;SELECT sqlcipher_export('tardb');COMMIT;";
    NSString *detach = @"DETACH DATABASE tardb;";
    NSArray *xSrcOpts = srcKey.length > 0 ? [self pretreat:srcOpts db:@"main"] : @[];
    NSArray *xTarOpts = tarKey.length > 0 ? [self pretreat:tarOpts db:@"tardb"] : @[];

    NSMutableArray *array = [NSMutableArray array];
    [array addObjectsFromArray:xSrcOpts];
    [array addObject:attach];
    [array addObjectsFromArray:xTarOpts];
    [array addObject:export];
    [array addObject:detach];

    for (NSString *sql in array) {
        int rc = sqlite3_exec(db, sql.UTF8String, NULL, NULL, NULL);
#if DEBUG
        if (rc != SQLITE_OK) {
            printf("[VVDBCipher][ERROR] code: %i, error: %s, sql: %s\n", rc, sqlite3_errmsg(db), sql.UTF8String);
        } else {
            printf("[VVDBCipher][DEBUG] code: %i, sql: %s\n", rc, sql.UTF8String);
        }
#endif
        if (rc != SQLITE_OK) break;
    }
    sqlite3_close(db);
    return rc == SQLITE_OK;
}

+ (void)removeDatabaseFile:(NSString *)path
{
    if (path.length == 0) return;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *shm = [path stringByAppendingString:@"-shm"];
    NSString *wal = [path stringByAppendingString:@"-wal"];
    [fm removeItemAtPath:path error:nil];
    [fm removeItemAtPath:shm error:nil];
    [fm removeItemAtPath:wal error:nil];
}

+ (void)moveDatabaseFile:(NSString *)srcPath
                  toPath:(NSString *)dstPath
                   force:(BOOL)force
{
    if (srcPath.length == 0 || dstPath.length == 0 || [srcPath isEqualToString:dstPath]) return;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dstdir = [dstPath stringByDeletingLastPathComponent];
    BOOL isdir = NO;
    BOOL exist = [fm fileExistsAtPath:dstdir isDirectory:&isdir];
    if (!exist || !isdir) {
        [fm createDirectoryAtPath:dstdir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *shm = [srcPath stringByAppendingString:@"-shm"];
    NSString *wal = [srcPath stringByAppendingString:@"-wal"];
    NSString *dstshm = [dstPath stringByAppendingString:@"-shm"];
    NSString *dstwal = [dstPath stringByAppendingString:@"-wal"];
    if (force) {
        [fm removeItemAtPath:dstPath error:nil];
        [fm removeItemAtPath:dstshm error:nil];
        [fm removeItemAtPath:dstwal error:nil];
    }
    [fm moveItemAtPath:srcPath toPath:dstPath error:nil];
    [fm moveItemAtPath:shm toPath:dstshm error:nil];
    [fm moveItemAtPath:wal toPath:dstwal error:nil];
}

+ (void)copyDatabaseFile:(NSString *)srcPath
                  toPath:(NSString *)dstPath
                   force:(BOOL)force
{
    if (srcPath.length == 0 || dstPath.length == 0 || [srcPath isEqualToString:dstPath]) return;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *dstdir = [dstPath stringByDeletingLastPathComponent];
    BOOL isdir = NO;
    BOOL exist = [fm fileExistsAtPath:dstdir isDirectory:&isdir];
    if (!exist || !isdir) {
        [fm createDirectoryAtPath:dstdir withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSString *shm = [srcPath stringByAppendingString:@"-shm"];
    NSString *wal = [srcPath stringByAppendingString:@"-wal"];
    NSString *dstshm = [dstPath stringByAppendingString:@"-shm"];
    NSString *dstwal = [dstPath stringByAppendingString:@"-wal"];
    if (force) {
        [fm removeItemAtPath:dstPath error:nil];
        [fm removeItemAtPath:dstshm error:nil];
        [fm removeItemAtPath:dstshm error:nil];
    }
    [fm copyItemAtPath:srcPath toPath:dstPath error:nil];
    [fm copyItemAtPath:shm toPath:dstshm error:nil];
    [fm copyItemAtPath:wal toPath:dstwal error:nil];
}

+ (NSArray<NSString *> *)pretreat:(NSArray<NSString *> *)options db:(NSString *)db
{
    if (db.length == 0) return options ? : @[];

    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:@"[a-z]|[A-Z]" options:0 error:nil];
    NSString *dbPrefix = [db stringByAppendingString:@"."];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:options.count];
    for (NSString *option in options) {
        NSArray<NSString *> *subOptions = [option componentsSeparatedByString:@";"];
        for (NSString *pragma in subOptions) {
            NSRange r = [pragma.lowercaseString rangeOfString:@"pragma "];
            if (r.location == NSNotFound) {
#if DEBUG
                NSRange range = [pragma rangeOfString:@" *" options:NSRegularExpressionSearch];
                if (range.location == NSNotFound) printf("[VVDBCipher][DEBUG] invalid option: %s\n", pragma.UTF8String);
#endif
                continue;
            }
            NSUInteger loc = NSMaxRange(r);
            NSTextCheckingResult *first = [exp firstMatchInString:pragma options:0 range:NSMakeRange(loc, pragma.length - loc)];
            if (!first) continue;
            NSMutableString *string = [pragma mutableCopy];
            [string insertString:dbPrefix atIndex:first.range.location];
            [string appendString:@";"];
            [results addObject:string];
        }
    }
    return results;
}

@end

#endif
