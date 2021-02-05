//
//  VVDatabase+Additions.m
//  VVSequelize
//
//  Created by Valo on 2019/3/27.
//

#import "VVDatabase+Additions.h"

@implementation VVDatabase (Additions)
// MARK: - pool
+ (instancetype)databaseInPoolWithPath:(nullable NSString *)path
{
    return [self databaseInPoolWithPath:path flags:0 encrypt:nil];
}

+ (instancetype)databaseInPoolWithPath:(nullable NSString *)path
                                 flags:(int)flags
{
    return [self databaseInPoolWithPath:path flags:flags encrypt:nil];
}

+ (instancetype)databaseInPoolWithPath:(nullable NSString *)path
                                 flags:(int)flags
                               encrypt:(nullable NSString *)key
{
    static NSMapTable *_pool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _pool = [NSMapTable strongToWeakObjectsMapTable];
    });
    NSString *udid = [self udidWithPath:path flags:flags encryptKey:key];
    VVDatabase *db = [_pool objectForKey:udid];
    if (!db) {
        db = [self databaseWithPath:path flags:flags encrypt:key];
        [_pool setObject:db forKey:udid];
    }
    return db;
}

+ (NSString *)udidWithPath:(NSString *)path flags:(int)flags encryptKey:(NSString *)key
{
    NSString *aPath = path ? : VVDBPathTemporary;
    int aFlags = flags | VVDBEssentialFlags;
    NSString *aKey = key ? : @"";
    return [NSString stringWithFormat:@"%@|%@|%@", aPath, @(aFlags), aKey];
}

@end
