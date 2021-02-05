//
//  VVResultMatch.m
//  VVSequelize
//
//  Created by Valo on 2019/8/20.
//

#import "VVResultMatch.h"
#import "VVDatabase+FTS.h"
#import "NSString+Tokenizer.h"

@interface VVResultMatch ()
@property (nonatomic, assign) VVMatchLV1 lv1;
@property (nonatomic, assign) VVMatchLV2 lv2;
@property (nonatomic, assign) VVMatchLV3 lv3;
@property (nonatomic, strong) NSArray *ranges;
@end

@implementation VVResultMatch
@synthesize lowerWeight = _lowerWeight;
@synthesize upperWeight = _upperWeight;
@synthesize weight = _weight;

+ (instancetype)matchWithAttributedString:(NSAttributedString *)attrText
                               attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
                                  keyword:(NSString *)keyword
{
    NSString *source = attrText.string.lowercaseString;
    NSString *lowerkw = keyword.lowercaseString;
    NSMutableArray *ranges = [NSMutableArray array];
    __block NSString *firstString = nil;
    __block NSRange firstRange = NSMakeRange(NSNotFound, 0);
    [attrText enumerateAttributesInRange:NSMakeRange(0, attrText.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey, id> *attrs, NSRange range, BOOL *stop) {
        if ([attrs isEqualToDictionary:attributes]) {
            [ranges addObject:[NSValue valueWithRange:range]];
            if (!firstString) {
                firstString = [source substringWithRange:range];
                firstRange = range;
            }
        }
    }];
    VVResultMatch *match = [VVResultMatch new];
    match.source = source;
    match.attrText = attrText;
    match.ranges = ranges;

    if (ranges.count == 0) return match;

    unichar rch = [firstString characterAtIndex:0];
    unichar kch = [lowerkw characterAtIndex:0];

    // lv1
    if (rch == kch) {
        match.lv1 = VVMatchLV1_Origin;
    } else if (rch >= 0x3000 && kch >= 0x3000) {
        NSDictionary *map = VVPinYin.shared.big52gbMap;
        unichar runi = (unichar)[(map[@(rch)] ? : @(rch)) unsignedShortValue];
        unichar kuni = (unichar)[(map[@(kch)] ? : @(kch)) unsignedShortValue];
        match.lv1 = runi == kuni ? VVMatchLV1_Origin : VVMatchLV1_Fuzzy;
    } else if (rch >= 0x3000 && kch < 0xC0) {
        if (lowerkw.length == firstString.length) {
            match.lv1 = VVMatchLV1_Firsts;
        } else {
            NSDictionary *map = VVPinYin.shared.big52gbMap;
            unichar runi = (unichar)[(map[@(rch)] ? : @(rch)) unsignedShortValue];
            NSArray *pinyins = VVPinYin.shared.hanzi2pinyins[@(runi)];
            BOOL isfull = NO;
            for (NSString *pinyin in pinyins) {
                if ((lowerkw.length >= pinyin.length && [lowerkw hasPrefix:pinyin])
                    || (lowerkw.length < pinyin.length && [pinyin hasPrefix:lowerkw])) {
                    isfull = YES;
                    break;
                }
            }
            match.lv1 = isfull ? VVMatchLV1_Fulls : VVMatchLV1_Firsts;
        }
    }

    //lv2
    VVMatchLV2 lv2 = firstRange.location > 0 ? VVMatchLV2_NonPrefix : (firstRange.length == attrText.length ? VVMatchLV2_Full : VVMatchLV2_Prefix);
    if (lv2 == VVMatchLV2_Full && match.lv1 == VVMatchLV1_Fulls && rch >= 0x3000 && kch < 0xC0) {
        unichar ech = [firstString characterAtIndex:firstString.length - 1];
        NSDictionary *map = VVPinYin.shared.big52gbMap;
        unichar euni = (unichar)[(map[@(ech)] ? : @(ech)) unsignedShortValue];
        NSArray *pinyins = VVPinYin.shared.hanzi2pinyins[@(euni)];
        NSString *lastkw = [lowerkw substringFromIndex:lowerkw.length - 1];
        lv2 = VVMatchLV2_Prefix;
        for (NSString *pinyin in pinyins) {
            if ((lowerkw.length >= pinyin.length && [lowerkw hasSuffix:pinyin]) || [pinyin hasPrefix:lastkw]) {
                lv2 = VVMatchLV2_Full;
                break;
            }
        }
    }
    match.lv2 = lv2;

    //lv3
    match.lv3 = match.lv1 == VVMatchLV1_Origin ? VVMatchLV3_High : match.lv1 == VVMatchLV1_Fulls ? VVMatchLV3_Medium : VVMatchLV3_Low;
    return match;
}

- (UInt64)upperWeight
{
    if (_upperWeight == 0 && _ranges.count > 0) {
        _upperWeight = (UInt64)(_lv1 & 0xF) << 28 | (UInt64)(_lv2 & 0xF) << 24 | (UInt64)(_lv3 & 0xF) << 20;
    }
    return _upperWeight;
}

- (UInt64)lowerWeight
{
    if (_upperWeight == 0 && _ranges.count > 0) {
        NSRange range = [_ranges.firstObject rangeValue];
        UInt64 loc = ~range.location & 0xFFFF;
        UInt64 rate = ((UInt64)range.length << 32) / _source.length;
        _lowerWeight = (UInt64)(loc & 0xFFFF) << 16 | (UInt64)(rate & 0xFFFF) << 0;
    }
    return _upperWeight;
}

- (UInt64)weight
{
    if (_weight == 0 && _ranges.count > 0) {
        _weight = self.upperWeight << 32 | self.lowerWeight;
    }
    return _weight;
}

- (NSComparisonResult)compare:(VVResultMatch *)other
{
    return self.weight == other.weight ? NSOrderedSame : self.weight > other.weight ? NSOrderedAscending : NSOrderedDescending;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"[%@|%@|%@|%@|0x%llx]: %@", @(_lv1), @(_lv2), @(_lv3), _ranges.firstObject, self.weight, [_attrText.description stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
}

@end
