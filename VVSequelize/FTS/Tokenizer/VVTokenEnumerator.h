
#import <Foundation/Foundation.h>

//MARK: - defines
#ifndef   UNUSED_PARAM
#define   UNUSED_PARAM(v) (void)(v)
#endif

#ifndef TOKEN_PINYIN_MAX_LENGTH
#define TOKEN_PINYIN_MAX_LENGTH 15
#endif

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS (NSUInteger, VVTokenMask) {
    VVTokenMaskPinyin       = 1 << 0, ///< placeholder, it will be executed without setting
    VVTokenMaskAbbreviation = 1 << 1, ///< pinyin abbreviation. not recommended, many invalid results will be found

    VVTokenMaskAll          = 0xFFFFFF,
    VVTokenMaskQuery        = 1 << 24, ///< FTS5_TOKENIZE_QUERY, only for query
};

//MARK: - VVTokenizerName
typedef NSString *VVTokenizerName NS_EXTENSIBLE_STRING_ENUM;

FOUNDATION_EXPORT VVTokenizerName const VVTokenTokenizerSequelize;
FOUNDATION_EXPORT VVTokenizerName const VVTokenTokenizerApple;
FOUNDATION_EXPORT VVTokenizerName const VVTokenTokenizerNatual;

//MARK: - VVToken

@interface VVToken : NSObject <NSCopying>
@property (nonatomic, assign) char *word;
@property (nonatomic, assign) int len;
@property (nonatomic, assign) int start;
@property (nonatomic, assign) int end;
@property (nonatomic, assign) int colocated; ///< -1:full width, 0:original, 1:full pinyin, 2:abbreviation, 3:syllable

@property (nonatomic, copy, readonly) NSString *token;

+ (instancetype)token:(const char *)word len:(int)len start:(int)start end:(int)end;

+ (NSArray<VVToken *> *)sortedTokens:(NSArray<VVToken *> *)tokens;
@end

@protocol VVTokenEnumerator <NSObject>

+ (NSArray<VVToken *> *)enumerate:(const char *)input mask:(VVTokenMask)mask;

@end

@interface VVTokenAppleEnumerator : NSObject <VVTokenEnumerator>

@end

@interface VVTokenNatualEnumerator : NSObject <VVTokenEnumerator>

@end

@interface VVTokenSequelizeEnumerator : NSObject <VVTokenEnumerator>

@end

NS_ASSUME_NONNULL_END
