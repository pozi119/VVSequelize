//
//  VVTestClasses.h
//  VVSequelize_Tests
//
//  Created by Valo on 2018/6/12.
//  Copyright © 2018年 Valo Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <VVSequelize/VVSequelize.h>

@interface VVTestMobile : NSObject
@property (nonatomic, copy) NSString *mobile;
@property (nonatomic, copy) NSString *province;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *carrier;
@property (nonatomic, copy) NSString *industry;
@property (nonatomic, assign) CGFloat relative;
@property (nonatomic, assign) NSInteger times;
@property (nonatomic, assign) NSInteger frequency;
@end

@interface VVTestPerson : NSObject
@property (nonatomic, copy) NSString *idcard;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) NSDate *birth;
@property (nonatomic, copy) NSString *mobile;
@property (nonatomic, strong) NSData *data;

/*
@property (nonatomic, assign) BOOL male;
@property (nonatomic, strong) NSDictionary *dic;
@property (nonatomic, strong) NSMutableSet *mdic;
@property (nonatomic, strong) NSArray *arr;
@property (nonatomic, strong) NSMutableArray *marr;
@property (nonatomic, copy  ) NSMutableString *mstr;
@property (nonatomic, strong) NSSet *set;
@property (nonatomic, strong) NSMutableSet *mset;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSMutableData *mdata;
*/

@end

@interface VVTestOne : NSObject
@property (nonatomic, assign) NSInteger oneId;      ///< id
@property (nonatomic, strong) VVTestPerson *person; ///< person
@property (nonatomic, strong) NSArray *mobiles;     ///< mobile
@property (nonatomic, strong) NSSet *friends;       ///< friends
@property (nonatomic, copy) NSString *flag;         ///< flag
@property (nonatomic, strong) NSDictionary *dic;    ///< flag
@property (nonatomic, strong) NSArray *arr;         ///< flag

@end

typedef union TestUnion {
    uint32_t num;
    char ch;
} VVTestUnion;

typedef struct TestStruct {
    uint8_t num;
    char ch;
} VVTestStruct;

@interface VVTestMix : NSObject
@property (nonatomic, assign) NSInteger cnum;
@property (nonatomic, strong) NSValue *val;
@property (nonatomic, strong) NSNumber *num;
@property (nonatomic, strong) NSDecimalNumber *decNum;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint point;
@property (nonatomic, assign) VVTestUnion un;
@property (nonatomic, assign) VVTestStruct stru;
@property (nonatomic, assign) char *str;
@property (nonatomic, assign) void *unknown;
@property (nonatomic, assign) char sa;
@property (nonatomic, strong) NSData *data;

@end

@interface VVTestEnumerator : NSObject<VVTokenEnumerator>

@end
