//
//  VVDatabase+Additions.h
//  VVSequelize
//
//  Created by Valo on 2019/3/27.
//

#import "VVDatabase.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVDatabase (Additions)
// MARK: - pool

/// open / create db
/// @param path db file full path
/// @note get from db poll first
+ (instancetype)databaseInPoolWithPath:(nullable NSString *)path;

/// open / create db
/// @param path db file full path
/// @param flags third parameter of sqlite3_open_v2,  (flags | VVDBEssentialFlags)
/// @note get from db poll first
+ (instancetype)databaseInPoolWithPath:(nullable NSString *)path
                                 flags:(int)flags;

/// open / create db
/// @param path db file full path
/// @param flags third parameter of sqlite3_open_v2,  (flags | VVDBEssentialFlags)
/// @param key encrypt key
/// @note get from db poll first
+ (instancetype)databaseInPoolWithPath:(nullable NSString *)path
                                 flags:(int)flags
                               encrypt:(nullable NSString *)key;

@end

NS_ASSUME_NONNULL_END
