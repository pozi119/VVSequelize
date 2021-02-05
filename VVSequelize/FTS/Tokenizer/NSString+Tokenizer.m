//
//  NSString+Tokenizer.m
//  VVSequelize
//
//  Created by Valo on 2019/3/22.
//

#import "NSString+Tokenizer.h"
#import "NSObject+VVOrm.h"
#import "VVPinYinSegmentor.h"

static NSString *const kVVPinYinResourceBundle = @"VVPinYin.bundle";
static NSString *const kVVPinYinResourceFile = @"pinyin.plist";
static NSString *const kVVPinYinHanzi2PinyinFile = @"hanzi2pinyin.plist";
static NSString *const kVVPinYinTransformFile = @"transform.txt";
static NSString *const kVVPinYinSyllablesFile = @"syllables.txt";

@interface VVPinYin ()
@property (nonatomic, strong) NSCache *cache;
@property (nonatomic, strong) NSDictionary *hanzi2pinyins;
@property (nonatomic, strong) NSDictionary *pinyins;
@property (nonatomic, strong) NSDictionary *gb2big5Map;
@property (nonatomic, strong) NSDictionary *big52gbMap;
@property (nonatomic, strong) NSCharacterSet *trimmingSet;
@property (nonatomic, strong) NSCharacterSet *cleanSet;
@property (nonatomic, strong) NSCharacterSet *symbolSet;
@property (nonatomic, strong) NSDictionary *syllables;
@property (nonatomic, strong) NSNumberFormatter *numberFormatter;
@end

@implementation VVPinYin

+ (instancetype)shared
{
    static VVPinYin *_shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[VVPinYin alloc] init];
    });
    return _shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _cache.totalCostLimit = 10 * 1024;
    }
    return self;
}

+ (NSString *)pathWithResource:(NSString *)resource
{
    NSBundle *parentBundle = [NSBundle bundleForClass:self];
    NSString *bundlePath = [parentBundle pathForResource:kVVPinYinResourceBundle ofType:nil];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *path = [bundle pathForResource:resource ofType:nil];
    return path;
}

- (void)setupTransformMap
{
    NSString *path = [[self class] pathWithResource:kVVPinYinTransformFile];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    NSArray<NSString *> *array = [text componentsSeparatedByString:@"\n"];
    NSAssert(array.count >= 2 && array[0].length == array[1].length && array[0].length > 0, @"Invalid transform file");
    NSString *simplified = array[0];
    NSString *traditional = array[1];
    NSMutableDictionary *gb2big5Map = [NSMutableDictionary dictionary];
    NSMutableDictionary *big52gbMap = [NSMutableDictionary dictionary];
    for (NSUInteger i = 0; i < simplified.length; i++) {
        NSString *simp = [simplified substringWithRange:NSMakeRange(i, 1)];
        NSString *trad = [traditional substringWithRange:NSMakeRange(i, 1)];
        unichar simpch = [simp characterAtIndex:0];
        unichar tradch = [trad characterAtIndex:0];
        gb2big5Map[@(simpch)] = @(tradch);
        big52gbMap[@(tradch)] = @(simpch);
    }
    _gb2big5Map = gb2big5Map;
    _big52gbMap = big52gbMap;
}

- (NSDictionary *)pinyins
{
    if (!_pinyins) {
        NSString *path = [[self class] pathWithResource:kVVPinYinResourceFile];
        _pinyins = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return _pinyins;
}

- (NSDictionary *)hanzi2pinyins
{
    if (!_hanzi2pinyins) {
        NSString *path = [[self class] pathWithResource:kVVPinYinHanzi2PinyinFile];
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:path];
        NSMutableDictionary<NSNumber *, id> *hanzi2pinyins = [NSMutableDictionary dictionaryWithCapacity:dic.count];
        [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            unichar ch = (unichar)strtol(key.UTF8String, NULL, 16);
            hanzi2pinyins[@(ch)] = obj;
        }];
        _hanzi2pinyins = hanzi2pinyins;
    }
    return _hanzi2pinyins;
}

- (NSDictionary *)gb2big5Map {
    if (!_gb2big5Map) {
        [self setupTransformMap];
    }
    return _gb2big5Map;
}

- (NSDictionary *)big52gbMap {
    if (!_big52gbMap) {
        [self setupTransformMap];
    }
    return _big52gbMap;
}

- (NSCharacterSet *)trimmingSet
{
    if (!_trimmingSet) {
        NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
        [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        _trimmingSet = set;
    }
    return _trimmingSet;
}

- (NSCharacterSet *)cleanSet
{
    if (!_cleanSet) {
        NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
        [set formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];
        _cleanSet = set;
    }
    return _cleanSet;
}

- (NSCharacterSet *)symbolSet
{
    if (!_symbolSet) {
        NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
        [set formUnionWithCharacterSet:[NSCharacterSet controlCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet nonBaseCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
        [set formUnionWithCharacterSet:[NSCharacterSet illegalCharacterSet]];
        _symbolSet = set;
    }
    return _symbolSet;
}

- (NSDictionary *)syllables
{
    if (!_syllables) {
        NSString *path = [[self class] pathWithResource:kVVPinYinSyllablesFile];
        NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        NSArray<NSString *> *array = [text componentsSeparatedByString:@"\n"];
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:array.count];
        for (NSString *line in array) {
            NSArray<NSString *> *kv = [line componentsSeparatedByString:@","];
            if (kv.count < 2) continue;
            dic[kv[0]] = @([kv[1] longLongValue]);
        }
        _syllables = dic;
    }
    return _syllables;
}

- (NSNumberFormatter *)numberFormatter
{
    if (!_numberFormatter) {
        _numberFormatter = [[NSNumberFormatter alloc] init];
        _numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    }
    return _numberFormatter;
}

@end

@interface VVRegEx : NSObject
@property (nonatomic, strong) NSRegularExpression *transformRegex;
@property (nonatomic, strong) NSRegularExpression *singleLineRegex;
@property (nonatomic, strong) NSRegularExpression *patternRegex;
+ (instancetype)shared;

@end

@implementation VVRegEx

+ (instancetype)shared
{
    static id _shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[self alloc] init];
    });
    return _shared;
}

- (NSRegularExpression *)transformRegex
{
    if (!_transformRegex) {
        NSString *pattern = @"[\u4e00-\u9fa5]+";
        _transformRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    }
    return _transformRegex;
}

- (NSRegularExpression *)singleLineRegex
{
    if (!_singleLineRegex) {
        NSString *pattern = @"\\s| ";
        _singleLineRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    }
    return _singleLineRegex;
}

- (NSRegularExpression *)patternRegex
{
    if (!_patternRegex) {
        NSString *pattern = @"\\.|\\^|\\$|\\\\|\\[|\\]|\\(|\\)|\\||\\{|\\}|\\*|\\+|\\?";
        _patternRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    }
    return _patternRegex;
}

@end

@implementation NSString (Tokenizer)

+ (void)preloadingForPinyin
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [VVPinYin.shared hanzi2pinyins];
        [VVPinYin.shared pinyins];
        [VVPinYin.shared syllables];
    });
}

+ (instancetype)ocStringWithCString:(const char *)cString
{
    NSString *str = [NSString stringWithUTF8String:cString];
    if (str) return str;
    str = [NSString stringWithCString:cString encoding:NSASCIIStringEncoding];
    if (str) return str;
    return @"";
}

- (const char *)cLangString
{
    const char *str = self.UTF8String;
    if (str) return str;
    str = [self cStringUsingEncoding:NSASCIIStringEncoding];
    if (str) return str;
    return "";
}

- (NSString *)simplifiedChineseString
{
    return [self transformStringWith:[VVPinYin shared].big52gbMap];
}

- (NSString *)traditionalChineseString
{
    return [self transformStringWith:[VVPinYin shared].gb2big5Map];
}

- (NSString *)transformStringWith:(NSDictionary *)map
{
    NSMutableString *string = [NSMutableString stringWithString:self];
    NSRegularExpression *regex = VVRegEx.shared.transformRegex;
    [regex enumerateMatchesInString:self options:NSMatchingReportCompletion range:NSMakeRange(0, self.length) usingBlock:^(NSTextCheckingResult *_Nullable result, NSMatchingFlags flags, BOOL *_Nonnull stop) {
        if (result.resultType != NSTextCheckingTypeRegularExpression) { return; }
        NSString *subString = [self substringWithRange:result.range];
        NSMutableString *fragment = [NSMutableString stringWithCapacity:result.range.length];
        for (NSUInteger i = 0; i < subString.length; i++) {
            unichar ch = [[subString substringWithRange:NSMakeRange(i, 1)] characterAtIndex:0];
            unichar trans = (unichar)[(map[@(ch)] ? : @(ch)) unsignedShortValue];
            [fragment appendString:[NSString stringWithCharacters:&trans length:1]];
        }
        [string replaceCharactersInRange:result.range withString:fragment];
    }];
    return string;
}

- (BOOL)hasChinese
{
    NSString *regex = @".*[\u4e00-\u9fa5].*";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    return [predicate evaluateWithObject:self];
}

- (NSString *)pinyin
{
    NSMutableString *string = [NSMutableString stringWithString:self];
    CFStringTransform((__bridge CFMutableStringRef)string, NULL, kCFStringTransformToLatin, false);
    NSString *result = [string stringByFoldingWithOptions:NSDiacriticInsensitiveSearch locale:[NSLocale currentLocale]];
    return [result stringByReplacingOccurrencesOfString:@"'" withString:@""];
}

- (NSString *)numberWithoutSeparator
{
    NSNumberFormatter *formatter = [VVPinYin shared].numberFormatter;
    return [[formatter numberFromString:self] stringValue];
}

- (NSString *)cleanString
{
    NSArray *array = [self componentsSeparatedByCharactersInSet:[VVPinYin shared].cleanSet];
    return [array componentsJoinedByString:@""];
}

- (NSString *)singleLine
{
    NSRegularExpression *regex = VVRegEx.shared.singleLineRegex;
    return [regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@" "];
}

- (NSString *)matchingPattern
{
    NSMutableString *string = [NSMutableString stringWithString:self.lowercaseString];
    CFStringTransform((__bridge CFMutableStringRef)string, NULL, kCFStringTransformFullwidthHalfwidth, false);
    return string.singleLine;
}

- (NSString *)regexPattern
{
    NSMutableString *result = self.matchingPattern.mutableCopy;
    NSRegularExpression *regex = VVRegEx.shared.patternRegex;
    NSArray<NSTextCheckingResult *> *array = [regex matchesInString:result options:0 range:NSMakeRange(0, result.length)];
    NSArray<NSTextCheckingResult *> *reversed = array.reverseObjectEnumerator.allObjects;
    for (NSTextCheckingResult *r in reversed) {
        [result insertString:@"\\" atIndex:r.range.location];
    }
    [result replaceOccurrencesOfString:@" +" withString:@" +" options:NSRegularExpressionSearch range:NSMakeRange(0, result.length)];
    return result.copy;
}

- (NSString *)fts5MatchPattern
{
    NSArray<NSArray<NSString *> *> *allPinyins = self.pinyinSegmentation;
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:allPinyins.count + 1];
    [results addObject:self.fullWidthPattern.quoted];
    for (NSArray<NSString *> *pinyins in allPinyins) {
        NSString *pattern = [pinyins componentsJoinedByString:@" "];
        pattern = [NSString stringWithFormat:@" %@", pattern].quoted;
        [results addObject:[NSString stringWithFormat:@"%@ * ", pattern]];
    }
    return [results componentsJoinedByString:@" OR "];
}

- (NSString *)halfWidthPattern
{
    NSMutableString *result = [NSMutableString stringWithCapacity:self.length];
    for (NSUInteger i = 0; i < self.length; i++) {
        unichar ch = [self characterAtIndex:i];
        if (ch >= 0xFF01 && ch <= 0xFF5E) {
            ch -= 0xFEE0;
        } else {
            switch (ch) {
                case 0xFFE0: ch = 0xa2; break;
                case 0xFFE1: ch = 0xa3; break;
                case 0xFFE2: ch = 0xac; break;
                case 0xFFE3: ch = 0xaf; break;
                case 0xFFE4: ch = 0xa6; break;
                case 0xFFE5: ch = 0xa5; break;
                default: break;
            }
        }
        NSString *s = [NSString stringWithCharacters:&ch length:1];
        [result appendString:s];
    }
    return result.copy;
}

- (NSString *)fullWidthPattern
{
    NSMutableString *result = [NSMutableString stringWithCapacity:self.length];
    for (NSUInteger i = 0; i < self.length; i++) {
        unichar ch = [self characterAtIndex:i];
        if (ch >= 0x21 && ch <= 0x7E) {
            ch += 0xFEE0;
        } else {
            switch (ch) {
                case 0xa2: ch = 0xFFE0; break;
                case 0xa3: ch = 0xFFE1; break;
                case 0xac: ch = 0xFFE2; break;
                case 0xaf: ch = 0xFFE3; break;
                case 0xa6: ch = 0xFFE4; break;
                case 0xa5: ch = 0xFFE5; break;
                default: break;
            }
        }
        NSString *s = [NSString stringWithCharacters:&ch length:1];
        [result appendString:s];
    }
    return result.copy;
}

+ (NSString *)fts5HighlightOfFields:(NSArray<NSString *> *)fields
                          tableName:(NSString *)tableName
                       tableColumns:(NSArray<NSString *> *)tableColumns
                      resultColumns:(NSArray<NSString *> *)resultColumns
{
    return [self fts5HighlightOfFields:fields tableName:tableName tableColumns:tableColumns resultColumns:resultColumns leftMark:@"<b>" rightMark:@"</b>"];
}

+ (NSString *)fts5HighlightOfFields:(NSArray<NSString *> *)fields
                          tableName:(NSString *)tableName
                       tableColumns:(NSArray<NSString *> *)tableColumns
                      resultColumns:(NSArray<NSString *> *)resultColumns
                           leftMark:(NSString *)leftMark
                          rightMark:(NSString *)rightMark
{
    NSArray *resultCols = resultColumns.count > 0 ? resultColumns : tableColumns;
    if (fields.count == 0) return [resultCols componentsJoinedByString:@","];

    NSUInteger count = tableColumns.count;
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:count];

    for (NSString *col in resultCols) {
        if (![tableColumns containsObject:col]) continue;
        NSString *highlight = nil;
        if ([fields containsObject:col]) {
            NSUInteger idx = [tableColumns indexOfObject:col];
            if (idx < count) highlight = [NSString stringWithFormat:@"highlight(%@, %@,'%@','%@') AS %@", tableName, @(idx), leftMark, rightMark, col];
        }
        [results addObject:highlight ? : col ];
    }
    return [results componentsJoinedByString:@","];
}

//MARK: - pinyin
- (NSArray<NSString *> *)fastPinyinSegmentation
{
    return [VVPinYinSegmentor segment:self];
}

//MARK: all pinyin segmentation

- (NSArray<NSArray<NSString *> *> *)pinyinSegmentation
{
    return [self.lowercaseString _pinyinSegmentation];
}

- (NSArray<NSArray<NSString *> *> *)_pinyinSegmentation
{
    NSMutableArray<NSArray<NSString *> *> *results = [NSMutableArray array];
    @autoreleasepool {
        NSArray<NSString *> *array = [self legalFirstPinyins];
        if (array.count == 0) return @[];
        for (NSString *first in array) {
            if (first.length == self.length) {
                [results addObject:@[self]];
                continue;
            }
            NSString *tail = [self substringFromIndex:first.length];
            NSArray<NSArray<NSString *> *> *components = [tail _pinyinSegmentation];
            for (NSArray<NSString *> *pinyins in components) {
                NSArray<NSString *> *result = [@[first] arrayByAddingObjectsFromArray:pinyins];
                [results addObject:result];
            }
        }
    }
    return results;
}

- (NSArray<NSString *> *)legalFirstPinyins
{
    const char *str = self.cLangString;
    u_long length = strlen(str);
    if (length <= 0) return @[];

    NSString *firstLetter = [self substringToIndex:1];
    NSArray *array = [[VVPinYin shared].pinyins objectForKey:firstLetter];

    NSMutableSet *results = [NSMutableSet set];
    BOOL spare = NO;
    for (NSString *pinyin in array) {
        const char *py = pinyin.cLangString;
        u_long pylen = strlen(py);
        if (pylen <= length) {
            if (strncmp(py, str, pylen) == 0) [results addObject:pinyin];
        } else {
            if (strncmp(py, str, length) == 0) spare = YES;
        }
    }
    if (spare) {
        [results addObject:self];
    }
    return results.allObjects;
}

@end

@implementation NSAttributedString (Highlighter)

- (NSAttributedString *)attributedStringByTrimmingToLength:(NSUInteger)maxLen withAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
{
    __block NSRange first = NSMakeRange(NSNotFound, 0);
    [self enumerateAttributesInRange:NSMakeRange(0, self.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange range, BOOL *stop) {
        if ([attrs isEqualToDictionary:attributes]) {
            first = range;
            *stop = YES;
        }
    }];
    return [self attributedStringByTrimmingToLength:maxLen withFirstHighlightRange:first];
}

- (NSAttributedString *)attributedStringByTrimmingToLength:(NSUInteger)maxLen withFirstHighlightRange:(NSRange)range
{
    NSUInteger upper = NSMaxRange(range);
    NSUInteger length = self.length;
    if (length < maxLen || upper > length) return self;
    
    if (range.location == NSNotFound) return self;
    
    NSMutableAttributedString *attrText = [self mutableCopy];
    NSUInteger lower = range.location;
    NSUInteger len = range.length;
    if (upper > maxLen && lower > 2) {
        NSInteger rlen = (2 + len > maxLen) ? (lower - 2) : (upper - maxLen);
        unichar ch = [attrText.string characterAtIndex:rlen - 1];
        unichar ce = [attrText.string characterAtIndex:rlen];
        if ((0xd800 <= ch && ch <= 0xdbff) || ce == 0xfe0f) rlen++; //emoji
        [attrText deleteCharactersInRange:NSMakeRange(0, rlen)];
        NSAttributedString *ellipsis = [[NSAttributedString alloc] initWithString:@"..."];
        [attrText insertAttributedString:ellipsis atIndex:0];
    }
    
    return attrText;
}

+ (NSAttributedString *)attributedStringWithHighlightString:(NSString *)string
                                                 attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
{
    return [self attributedStringWithHighlightString:string attributes:attributes leftMark:@"<b>" rightMark:@"</b>"];
}

+ (NSAttributedString *)attributedStringWithHighlightString:(NSString *)string
                                                 attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
                                                   leftMark:(NSString *)leftMark
                                                  rightMark:(NSString *)rightMark
{
    NSUInteger lplen = leftMark.length;
    NSUInteger rplen = rightMark.length;
    if (lplen == 0 || rplen == 0 || string.length == 0) {
        return [[NSAttributedString alloc] initWithString:string ? : @""];
    }

    NSUInteger loc = 0;
    NSMutableString *mutableString = [NSMutableString stringWithString:string];
    NSMutableArray *ranges = [NSMutableArray array];
    while (1) {
        NSRange range = [mutableString rangeOfString:leftMark];
        if (range.location == NSNotFound) break;
        [mutableString deleteCharactersInRange:range];
        loc = range.location;

        NSRange rightSearchRange = NSMakeRange(loc, mutableString.length - loc);
        range = [mutableString rangeOfString:rightMark options:0 range:rightSearchRange];
        if (range.location == NSNotFound) {
            [mutableString insertString:leftMark atIndex:loc];
            break;
        }
        [mutableString deleteCharactersInRange:range];

        NSRange hlrange = NSMakeRange(loc, range.location - loc);
        [ranges addObject:[NSValue valueWithRange:hlrange]];
    }

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:mutableString];
    for (NSValue *value in ranges) {
        [attributedString addAttributes:attributes range:value.rangeValue];
    }
    return attributedString;
}

@end
