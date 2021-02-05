//
//  VVPinyinSegmentor.h
//  VVSequelize
//
//  Created by Valo on 2020/4/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VVPinYinSegmentor : NSObject

+ (NSArray<NSString *> *)segment:(NSString *)pinyinString;

+ (NSArray<NSArray<NSString *> *> *)recursionSegment:(NSString *)pinyinString;

@end

NS_ASSUME_NONNULL_END
