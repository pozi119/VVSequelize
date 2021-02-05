//
//  VVExtraClasses.h
//  VVSequelize_Tests
//
//  Created by Valo on 2020/12/28.
//  Copyright © 2020 Valo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VVSequelize/VVSequelize.h>

NS_ASSUME_NONNULL_BEGIN

@interface VVTestClass : NSObject <VVOrmable>
@property (nonatomic, assign) uint64_t cid;
@property (nonatomic, copy) NSString *name;

@end

@interface VVTestStudent : NSObject <VVOrmable>
@property (nonatomic, assign) uint64_t sid;
@property (nonatomic, assign) uint64_t cid;
@property (nonatomic, copy) NSString *sno;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSUInteger age;
@end

NS_ASSUME_NONNULL_END
