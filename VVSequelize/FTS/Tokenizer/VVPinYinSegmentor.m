//
//  VVPinyinSegmentor.m
//  VVSequelize
//
//  Created by Valo on 2020/4/3.
//

#import "VVPinYinSegmentor.h"
#import "NSString+Tokenizer.h"

typedef struct CG_BOXABLE VVPinYinTrie {
    long freq;
    bool next;
    char ch;
    struct VVPinYinTrie *childs[26];
} VVPinYinTrie;

@interface VVPinYinPhone : NSObject
@property (nonatomic, copy) NSString *pinyin;
@property (nonatomic, assign) long frequency;
@end

@implementation VVPinYinPhone
@end

@implementation VVPinYinSegmentor

//MARK: - Trie
+ (VVPinYinTrie *)rootPinYinTrie
{
    static dispatch_once_t onceToken;
    static VVPinYinTrie *_trie = nil;
    dispatch_once(&onceToken, ^{
        _trie = [self newTrieNode];
        NSDictionary *syllables = VVPinYin.shared.syllables;
        [syllables enumerateKeysAndObjectsUsingBlock:^(NSString *pinyin, NSNumber *freq, BOOL *stop) {
            [self addPinyin:pinyin.UTF8String frequency:freq.longValue root:_trie];
        }];
    });
    return _trie;
}

+ (VVPinYinTrie *)newTrieNode
{
    size_t size = sizeof(VVPinYinTrie);
    VVPinYinTrie *node = (VVPinYinTrie *)malloc(size);
    memset(node, 0x0, size);
    return node;
}

+ (void)addChar:(char)ch to:(VVPinYinTrie *)node frequency:(long)frequency
{
    if (ch < 'a' || ch > 'z') return;
    int idx = ch - 97;
    node->next = true;
    VVPinYinTrie *child = node->childs[idx];
    if (!child) {
        child = [self newTrieNode];
        node->childs[idx] = child;
    }
    child->ch = ch;
    if (frequency > child->freq) child->freq = frequency;
}

+ (void)addPinyin:(const char *)pinyin frequency:(long)frequency root:(VVPinYinTrie *)root
{
    int i = 0;
    int len = (int)strlen(pinyin);
    char ch = pinyin[i];
    VVPinYinTrie *node = root;
    while (ch) {
        if (ch < 'a' || ch > 'z') continue;
        [[self class] addChar:ch to:node frequency:i < len - 1 ? 0 : frequency];
        node = node->childs[ch - 97];
        ch = pinyin[++i];
    }
}

+ (NSArray<VVPinYinPhone *> *)retrieve:(const char *)pinyin
{
    NSMutableArray<VVPinYinPhone *> *results = [NSMutableArray array];
    VVPinYinTrie *root = [self rootPinYinTrie];
    VVPinYinTrie *node = root;
    u_long len = strlen(pinyin);
    u_long last = len - 1;
    for (u_long i = 0; i < len; i++) {
        char ch = pinyin[i];
        if (ch < 'a' || ch > 'z') break;
        VVPinYinTrie *child = node->childs[ch - 97];
        if (!child) break;
        if (child->freq > 0 || i == last) {
            VVPinYinPhone *phone = [VVPinYinPhone new];
            phone.pinyin = [[NSString alloc] initWithBytes:pinyin length:i + 1 encoding:NSASCIIStringEncoding];
            phone.frequency = i == last ? 65535 : child->freq;
            [results addObject:phone];
        }
        node = child;
    }
    [results sortUsingComparator:^NSComparisonResult (VVPinYinPhone *phone1, VVPinYinPhone *phone2) {
        return phone1.frequency > phone2.frequency ? NSOrderedAscending : NSOrderedDescending;
    }];
    return results;
}

+ (NSArray<NSString *> *)split:(const char *)pinyin
{
    NSArray *fronts = [self retrieve:pinyin];
    u_long len = strlen(pinyin);
    for (VVPinYinPhone *item in fronts) {
        u_long iLen = item.pinyin.length;
        if (iLen == len) {
            return @[item.pinyin];
        } else {
            NSArray *temp = [self retrieve:(pinyin + iLen)];
            if (temp.count > 0) {
                NSArray *rights = [self split:(pinyin + iLen)];
                return [@[item.pinyin] arrayByAddingObjectsFromArray:rights];
            }
        }
    }
    return @[];
}

//MARK: public
+ (NSArray<NSString *> *)segment:(NSString *)pinyinString
{
    return [self split:pinyinString.lowercaseString.UTF8String];
}

//MARK: - recursion
+ (NSArray<NSString *> *)firstPinyinsOf:(NSString *)pinyinString
{
    const char *str = pinyinString.UTF8String;
    u_long length = strlen(str);
    if (length <= 0) return @[];

    NSString *firstLetter = [pinyinString substringToIndex:1];
    NSArray *array = [[VVPinYin shared].pinyins objectForKey:firstLetter];

    NSMutableArray *results = [NSMutableArray array];
    for (NSString *pinyin in array) {
        const char *py = pinyin.cLangString;
        u_long len = strlen(py);
        if (len < length && strncmp(py, str, len) == 0) {
            [results addObject:pinyin];
        }
    }
    return results;
}

+ (NSArray<NSArray<NSString *> *> *)recursionSplit:(NSString *)pinyinString
{
    NSMutableArray<NSArray<NSString *> *> *results = [NSMutableArray array];
    @autoreleasepool {
        NSArray<NSString *> *array = [self firstPinyinsOf:pinyinString];
        if (array.count == 0) return @[@[self]];
        for (NSString *first in array) {
            NSString *tail = [pinyinString substringFromIndex:first.length];
            NSArray<NSArray<NSString *> *> *components = [self recursionSplit:tail];
            for (NSArray<NSString *> *pinyins in components) {
                NSArray<NSString *> *result = [@[first] arrayByAddingObjectsFromArray:pinyins];
                [results addObject:result];
            }
        }
    }
    return results;
}

//MARK: public
+ (NSArray<NSArray<NSString *> *> *)recursionSegment:(NSString *)pinyinString
{
    return [self recursionSplit:pinyinString.lowercaseString];
}

@end
