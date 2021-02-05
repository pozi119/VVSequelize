//
//  CipherTests.m
//  VVSequelize_Tests
//
//  Created by Valo on 2020/9/3.
//  Copyright © 2020 Valo. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <VVSequelize/VVSequelize.h>

@interface CipherTests : XCTestCase
@property (nonatomic, copy) NSString *plaindb;
@property (nonatomic, copy) NSString *encryptdb;
@end

@implementation CipherTests

- (void)setUp {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    _plaindb = [path stringByAppendingPathComponent:@"0-plain.db"];
    _encryptdb = [path stringByAppendingPathComponent:@"0-encrypt.db"];
    NSLog(@"dir: %@", path);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testResetFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *sourcePath = [[NSBundle mainBundle] pathForResource:@"mobiles.sqlite" ofType:nil];
    [fm removeItemAtPath:_plaindb error:nil];
    [fm removeItemAtPath:_encryptdb error:nil];
    [fm copyItemAtPath:sourcePath toPath:_plaindb error:nil];
}

- (void)testEncrypt {
    XCTAssert([VVDBCipher encrypt:self.plaindb target:self.encryptdb key:@"123456" options:nil]);
}

- (void)testDecrypt {
    [[NSFileManager defaultManager] removeItemAtPath:_plaindb error:nil];
    XCTAssert([VVDBCipher decrypt:self.encryptdb target:self.plaindb key:@"123456" options:nil]);
}


- (void)testEncryptWithOptions {
    NSArray *options = @[
        @"PRAGMA cipher_plaintext_header_size = 32;",
        @"PRAGMA cipher_salt = \"x'01010101010101010101010101010101'\";",
    ];
    XCTAssert([VVDBCipher encrypt:self.plaindb target:self.encryptdb key:@"123456" options:options]);
}

- (void)testDecryptWithOptions {
    NSArray *options = @[
        @"PRAGMA cipher_plaintext_header_size = 32;",
        @"PRAGMA cipher_salt = \"x'01010101010101010101010101010101'\";",
    ];
    [[NSFileManager defaultManager] removeItemAtPath:_plaindb error:nil];
    XCTAssert([VVDBCipher decrypt:self.encryptdb target:self.plaindb key:@"123456" options:options]);
}

- (void)testChangeKey{
    NSArray *srcOpts = @[
        @"pragma cipher_plaintext_header_size = 0;",
        @"pragma cipher_page_size = 4096;",
        @"pragma kdf_iter = 64000;",
        @"pragma cipher_hmac_algorithm = HMAC_SHA1;",
        @"pragma cipher_kdf_algorithm = PBKDF2_HMAC_SHA1;",
    ];
    NSArray *tarOpts = @[
        @"PRAGMA cipher_plaintext_header_size = 32;",
        @"PRAGMA cipher_salt = \"x'01010101010101010101010101010101'\";",
    ];
    [VVDBCipher encrypt:_plaindb target:_encryptdb key:@"123456" options:srcOpts];
    [[NSFileManager defaultManager] removeItemAtPath:_plaindb error:nil];
    [VVDBCipher change:_encryptdb srcKey:@"123456" srcOpts:srcOpts tarKey:@"654321" tarOpts:tarOpts];
    [VVDBCipher decrypt:_encryptdb target:_plaindb key:@"654321" options:tarOpts];
}

@end
