//
//  ExtraTests.m
//  VVSequelize_Tests
//
//  Created by Valo on 2020/12/28.
//  Copyright © 2020 Valo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VVSequelize/VVSequelize.h>
#import "VVExtraClasses.h"

@interface ExtraTests : XCTestCase
@property (nonatomic, strong) VVDatabase *vvdb;
@end

@implementation ExtraTests

- (void)setUp {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dbPath = [path stringByAppendingPathComponent:@"extra.sqlite"];
    NSLog(@"[VVDB][DEBUG] db path: %@", dbPath);
    self.vvdb = [[VVDatabase alloc] initWithPath:dbPath];
    [self.vvdb setTraceHook:^int (unsigned int mask, void *_Nonnull stmt, void *_Nonnull sql) {
        NSLog(@"[VVDB][DEBUG] sql: %s", (char *)sql);
        return 0;
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    VVOrm *classOrm = [VVOrm ormWithClass:VVTestClass.class name:@"classes" database:self.vvdb setup:VVOrmSetupRebuild];
    VVOrm *studentOrm = [VVOrm ormWithClass:VVTestStudent.class name:@"students" database:self.vvdb setup:VVOrmSetupRebuild];
    if (classOrm && studentOrm) { }
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
