//
//  VVDBCipher.h
//  VVSequelize
//
//  Created by Valo on 2018/6/19.
//

#ifdef SQLITE_HAS_CODEC

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VVDBCipher : NSObject

/// encrypt database
/// @param path database file path
/// @param key encrypt key
/// @param options cipher options, such as `pragma cipher_plaintext_header_size = 32;`
+ (BOOL)encrypt:(NSString *)path
            key:(NSString *)key
        options:(nullable NSArray<NSString *> *)options;

/// decrypt database
+ (BOOL)decrypt:(NSString *)path
            key:(NSString *)key
        options:(nullable NSArray<NSString *> *)options;

/// encrypt database
+ (BOOL)encrypt:(NSString *)source
         target:(NSString *)target
            key:(NSString *)key
        options:(nullable NSArray<NSString *> *)options;

/// decrypt databse
+ (BOOL)decrypt:(NSString *)source
         target:(NSString *)target
            key:(NSString *)key
        options:(nullable NSArray<NSString *> *)options;

/// change databse encrypt key
+ (BOOL)change:(NSString *)source
        srcKey:(nullable NSString *)srcKey
       srcOpts:(nullable NSArray<NSString *> *)srcOpts
        tarKey:(nullable NSString *)tarKey
       tarOpts:(nullable NSArray<NSString *> *)tarOpts;

/// change databse encrypt key
+ (BOOL)change:(NSString *)source
        target:(NSString *)target
        srcKey:(nullable NSString *)srcKey
       srcOpts:(nullable NSArray<NSString *> *)srcOpts
        tarKey:(nullable NSString *)tarKey
       tarOpts:(nullable NSArray<NSString *> *)tarOpts;

+ (void)removeDatabaseFile:(NSString *)path;

+ (void)moveDatabaseFile:(NSString *)srcPath
                  toPath:(NSString *)dstPath
                   force:(BOOL)force;

+ (void)copyDatabaseFile:(NSString *)srcPath
                  toPath:(NSString *)dstPath
                   force:(BOOL)force;

@end

NS_ASSUME_NONNULL_END

#endif
