
#import "VVTokenEnumerator.h"
#import "NSString+Tokenizer.h"
#import <NaturalLanguage/NaturalLanguage.h>

#define VVTokenMaxOCLength 4096

static inline int unicode2utf8(uint32_t ch, uint8_t *utf8)
{
    assert(utf8 != NULL);
    int len = 0;
    if (ch < 0x80) {
        utf8[0] = (ch & 0x7F);
        len = 1;
    } else if (ch < 0x800) {
        utf8[0] = ((ch >> 6) & 0x1F) | 0xC0;
        utf8[1] = (ch & 0x3F) | 0x80;
        len = 2;
    } else if (ch < 0x10000) {
        utf8[0] = ((ch >> 12) & 0xF) | 0xE0;
        utf8[1] = ((ch >> 6) & 0x3F) | 0x80;
        utf8[2] = (ch & 0x3F) | 0x80;
        len = 3;
    } else if (ch < 0x200000) {
        utf8[0] = ((ch >> 18) & 0x7) | 0xF0;
        utf8[1] = ((ch >> 12) & 0x3F) | 0x80;
        utf8[2] = ((ch >> 6) & 0x3F) | 0x80;
        utf8[3] = (ch & 0x3F) | 0x80;
        len = 4;
    } else if (ch < 0x4000000) {
        utf8[0] = ((ch >> 24) & 0x3) | 0xF8;
        utf8[1] = ((ch >> 18) & 0x3F) | 0x80;
        utf8[2] = ((ch >> 12) & 0x3F) | 0x80;
        utf8[3] = ((ch >> 6) & 0x3F) | 0x80;
        utf8[4] = (ch & 0x3F) | 0x80;
        len = 5;
    } else {
        utf8[0] = ((ch >> 30) & 0x1) | 0xFC;
        utf8[1] = ((ch >> 24) & 0x3F) | 0x80;
        utf8[2] = ((ch >> 18) & 0x3F) | 0x80;
        utf8[3] = ((ch >> 12) & 0x3F) | 0x80;
        utf8[4] = ((ch >> 6) & 0x3F) | 0x80;
        utf8[5] = (ch & 0x3F) | 0x80;
        len = 6;
    }
    return len;
}

static inline uint32_t utf82unicode(const uint8_t *utf8, int len)
{
    uint32_t ch = 0;
    switch (len) {
        case 1:
            ch = (uint32_t)(utf8[0] & 0x7F);
            break;

        case 2:
            ch = ((uint32_t)(utf8[0] & 0x1F) << 6) | (uint32_t)(utf8[1] & 0x3F);
            break;

        case 3:
            ch = ((uint32_t)(utf8[0] & 0xF) << 12) | ((uint32_t)(utf8[1] & 0x3F) << 6) | (uint32_t)(utf8[2] & 0x3F);
            break;

        case 4:
            ch = ((uint32_t)(utf8[0] & 0x7) << 18) | ((uint32_t)(utf8[1] & 0x3F) << 12) | ((uint32_t)(utf8[2] & 0x3F) << 6) | (uint32_t)(utf8[3] & 0x3F);
            break;

        case 5:
            ch = ((uint32_t)(utf8[0] & 0x3) << 24) | ((uint32_t)(utf8[1] & 0x3F) << 18) | ((uint32_t)(utf8[2] & 0x3F) << 12) | ((uint32_t)(utf8[3] & 0x3F) << 6) | (uint32_t)(utf8[4] & 0x3F);
            break;

        case 6:
            ch = ((uint32_t)(utf8[0] & 0x1) << 30) | ((uint32_t)(utf8[1] & 0x3F) << 24) | ((uint32_t)(utf8[2] & 0x3F) << 18) | ((uint32_t)(utf8[3] & 0x3F) << 12) | ((uint32_t)(utf8[4] & 0x3F) << 6) | (uint32_t)(utf8[5] & 0x3F);
            break;

        default:
            break;
    }
    return ch;
}

//MARK: - VVTokenizerName
VVTokenizerName const VVTokenTokenizerSequelize = @"sequelize";
VVTokenizerName const VVTokenTokenizerApple = @"apple";
VVTokenizerName const VVTokenTokenizerNatual = @"natual";

//MARK: - Token
@implementation VVToken
@synthesize token = _token;
+ (instancetype)token:(const char *)word len:(int)len start:(int)start end:(int)end
{
    VVToken *tk = [VVToken new];
    char *temp = (char *)malloc(len + 1);
    memcpy(temp, word, len);
    temp[len] = '\0';
    tk.word = temp;
    tk.start = start;
    tk.len = len;
    tk.end = end;
    return tk;
}

- (NSString *)token
{
    if (!_token) {
        _token = _word ? [NSString stringWithUTF8String:_word] : nil;
    }
    return _token;
}

- (BOOL)isEqual:(id)object
{
    return object != nil && [object isKindOfClass:VVToken.class] && [(VVToken *)object hash] == self.hash;
}

- (NSUInteger)hash
{
    return self.token.hash ^ @(_start).hash ^ @(_len).hash ^ @(_end).hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%2i-%2i|%2i|%i|0x%09lx]: %@ ", _start, _end, _len, (int)_colocated, (unsigned long)self.hash, self.token];
}

- (void)dealloc
{
    free(_word);
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    VVToken *token = [[[self class] allocWithZone:zone] init];
    char *temp = (char *)malloc(_len + 1);
    memcpy(temp, _word, _len);
    temp[_len] = '\0';
    token.word = temp;
    token.start = _start;
    token.end = _end;
    token.len = _len;
    return token;
}

+ (NSArray<VVToken *> *)sortedTokens:(NSArray<VVToken *> *)tokens
{
    return [tokens sortedArrayUsingComparator:^NSComparisonResult (VVToken *tk1, VVToken *tk2) {
        uint64_t h1 = ((uint64_t)tk1.start) << 32 | ((uint64_t)tk1.end) | ((uint64_t)tk1.len);
        uint64_t h2 = ((uint64_t)tk2.start) << 32 | ((uint64_t)tk2.end) | ((uint64_t)tk2.len);
        return h1 == h2 ? strcmp(tk1.word, tk2.word) : (h1 < h2 ? NSOrderedAscending : NSOrderedDescending);
    }];
}

@end

//MARK: - Enumerator -
@implementation VVTokenAppleEnumerator

+ (nonnull NSArray<VVToken *> *)enumerate:(nonnull const char *)cSource mask:(VVTokenMask)mask {
    NSString *source = [NSString stringWithUTF8String:cSource];
    NSMutableArray *results = [NSMutableArray array];

    CFRange range = CFRangeMake(0, source.length);
    CFLocaleRef locale = CFLocaleCopyCurrent(); //need CFRelease!

    // create tokenizer
    CFStringTokenizerRef tokenizer = CFStringTokenizerCreate(kCFAllocatorDefault, (CFStringRef)source, range, kCFStringTokenizerUnitWordBoundary, locale);

    //token status
    CFStringTokenizerTokenType tokenType = CFStringTokenizerGoToTokenAtIndex(tokenizer, 0);

    while (tokenType != kCFStringTokenizerTokenNone) {
        @autoreleasepool {
            // get current range
            range = CFStringTokenizerGetCurrentTokenRange(tokenizer);
            NSString *sub = [source substringWithRange:NSMakeRange(range.location, range.length)];
            const char *pre = [source substringWithRange:NSMakeRange(0, range.location)].cLangString;
            const char *token = sub.cLangString;
            int start = (int)strlen(pre);
            int len = (int)strlen(token);
            int end = start + len;

            if (len > 0 && (unsigned char)token[0] >= 0xFC) {
                int hzlen = 3;
                for (int i = 0; i < len; i += 3) {
                    NSString *hz = [[NSString alloc] initWithBytes:token + i length:hzlen encoding:NSUTF8StringEncoding];
                    if (!hz) continue;
                    VVToken *tk = [VVToken token:hz.UTF8String len:hzlen start:(int)(start + i) end:(int)(start + i + hzlen)];
                    [results addObject:tk];
                }
            } else {
                [results addObject:[VVToken token:sub.UTF8String len:len start:start end:end]];
            }
            // get next token
            tokenType = CFStringTokenizerAdvanceToNextToken(tokenizer);
        }
    }

    // release
    if (locale != NULL) CFRelease(locale);
    if (tokenizer) CFRelease(tokenizer);

    return results;
}

@end

@implementation VVTokenNatualEnumerator

+ (nonnull NSArray<VVToken *> *)enumerate:(nonnull const char *)cSource mask:(VVTokenMask)mask {
    __block NSMutableArray *results = [NSMutableArray array];
    if (@available(iOS 12.0, *)) {
        NSString *source = [NSString stringWithUTF8String:cSource];
        NLTokenizer *tokenizer = [[NLTokenizer alloc] initWithUnit:NLTokenUnitWord];
        tokenizer.string = source;

        NSRange range = NSMakeRange(0, tokenizer.string.length);
        [tokenizer enumerateTokensInRange:range usingBlock:^(NSRange tokenRange, NLTokenizerAttributes flags, BOOL *stop) {
            @autoreleasepool {
                NSString *tk = [tokenizer.string substringWithRange:tokenRange];
                const char *pre = [tokenizer.string substringToIndex:tokenRange.location].cLangString;
                const char *token = tk.cLangString;
                int start = (int)strlen(pre);
                int len   = (int)strlen(token);
                int end   = (int)(start + len);
                [results addObject:[VVToken token:tk.UTF8String len:len start:start end:end]];
                if (*stop) return;
            }
        }];
    }

    return results;
}

@end

@implementation VVTokenSequelizeEnumerator

+ (NSArray<VVToken *> *)enumerate:(const char *)cSource mask:(VVTokenMask)mask
{
    UNUSED_PARAM(mask);
    if (cSource == NULL) return @[];
    u_long nText = strlen(cSource);
    if (nText == 0) return @[];

    NSArray *syllables = @[];
    BOOL isquery = mask & VVTokenMaskQuery;
    if (isquery) {
        NSString *source = [NSString ocStringWithCString:cSource];
        if ([source hasPrefix:@" "]) {
            source = [source substringFromIndex:1];
            NSArray *strings = [source componentsSeparatedByString:@" "];
            NSMutableArray *results = [NSMutableArray arrayWithCapacity:strings.count];
            int loc = 0;
            for (NSString *string in strings) {
                int len = (int)string.length;
                VVToken *token = [VVToken token:string.UTF8String len:len start:loc end:loc + len];
                [results addObject:token];
                loc += len;
            }
            return results;
        }
    }

    uint8_t *buff = (uint8_t *)malloc(nText);
    memcpy(buff, cSource, nText);

    NSMutableArray *results = [NSMutableArray arrayWithCapacity:nText];

    BOOL usepinyin = !isquery && (mask & VVTokenMaskPinyin);
    BOOL useabbr = !isquery && (mask & VVTokenMaskAbbreviation);

    int idx = 0;
    int length = 0;
    while (idx < nText) {
        if (buff[idx] < 0xC0) {
            length = 1;
        } else if (buff[idx] < 0xE0) {
            length = 2;
        } else if (buff[idx] < 0xF0) {
            length = 3;
        } else if (buff[idx] < 0xF8) {
            length = 4;
        } else if (buff[idx] < 0xFC) {
            length = 5;
        } else {
            //length = 6;
            NSAssert(NO, @"wrong utf-8 text");
            break;
        }

        uint8_t *word = (uint8_t *)malloc(6);
        memcpy(word, buff + idx, length);
        int wordlen = length;

        // full width to half width
        if (length == 3 && word[0] == 0xEF) {
            unichar uni = ((unichar)(word[0] & 0xF) << 12) | ((unichar)(word[1] & 0x3F) << 6) | (unichar)(word[2] & 0x3F);
            if (uni >= 0xFF01 && uni <= 0xFF5E) {
                word[0] = uni - 0xFEE0;
                word[1] = '\0';
                wordlen = 1;
            } else if (uni >= 0xFFE0 && uni <= 0xFFE5) {
                switch (uni) {
                    case 0xFFE0: word[1] = 0xa2; break;
                    case 0xFFE1: word[1] = 0xa3; break;
                    case 0xFFE2: word[1] = 0xac; break;
                    case 0xFFE3: word[1] = 0xaf; break;
                    case 0xFFE4: word[1] = 0xa6; break;
                    case 0xFFE5: word[1] = 0xa5; break;
                    default: break;
                }
                word[0] = 0xc2;
                word[2] = '\0';
                wordlen = 2;
            } else if (uni == 0x3000) {
                word[0] = 0x20;
                word[1] = '\0';
                wordlen = 1;
            }
        }

        NSMutableArray *synonyms = [NSMutableArray array];
        if (wordlen >= 3) {
            uint32_t uni = utf82unicode(word, wordlen);
            if (uni > 0) {
                NSNumber *num = VVPinYin.shared.big52gbMap[@(uni)];
                unichar simp = num != nil ? (unichar)num.unsignedShortValue : uni;

                // trad -> simp
                wordlen = unicode2utf8(simp, word);

                if (usepinyin) {
                    NSArray<NSString *> *pinyins = VVPinYin.shared.hanzi2pinyins[@(simp)];
                    NSMutableSet<NSString *> *fulls = [NSMutableSet setWithCapacity:pinyins.count];
                    NSMutableSet<NSString *> *abbrs = [NSMutableSet setWithCapacity:pinyins.count];
                    for (NSString *pinyin in pinyins) {
                        [fulls addObject:pinyin];
                        [abbrs addObject:[pinyin substringToIndex:1]];
                    }
                    for (NSString *full in fulls) {
                        VVToken *token = [VVToken token:full.UTF8String len:(int)full.length start:idx end:idx + length];
                        token.colocated = 1;
                        [synonyms addObject:token];
                    }
                    if (useabbr) {
                        for (NSString *abbr in abbrs) {
                            VVToken *token = [VVToken token:abbr.UTF8String len:(int)abbr.length start:idx end:idx + length];
                            token.colocated = 1;
                            [synonyms addObject:token];
                        }
                    }
                }
            }
        }

        // upper case to lower case
        if (wordlen == 1 && word[0] > 64 && word[0] < 91) {
            word[0] += 32;
        }

        VVToken *token = [VVToken token:(char *)word len:wordlen start:idx end:idx + length];
        [results addObject:token];
        [results addObjectsFromArray:synonyms];
        idx += length;
        free(word);
    }
    free(buff);
    [results addObjectsFromArray:syllables];
    return results;
}

@end
