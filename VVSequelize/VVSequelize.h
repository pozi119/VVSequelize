#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#ifdef VVSEQUELIZE_CORE
#import "NSObject+VVKeyValue.h"
#import "NSObject+VVOrm.h"
#import "VVClassInfo.h"
#import "VVDatabase.h"
#import "VVDBStatement.h"
#import "VVDatabase+Additions.h"
#import "VVForeignKey.h"
#import "VVSelect.h"
#import "VVOrm.h"
#import "VVOrmable.h"
#import "VVOrmConfig.h"
#import "VVOrmDefs.h"
#import "VVOrmView.h"
#import "VVOrm+Create.h"
#import "VVOrm+Delete.h"
#import "VVOrm+Retrieve.h"
#import "VVOrm+Update.h"
#endif

#ifdef VVSEQUELIZE_FTS
#import "NSString+Tokenizer.h"
#import "VVResultMatch.h"
#import "VVTokenEnumerator.h"
#import "VVPinYinSegmentor.h"
#import "VVFtsable.h"
#import "VVDatabase+FTS.h"
#import "VVOrm+FTS.h"
#endif

#ifdef VVSEQUELIZE_UTIL
#import "VVDBCipher.h"
#import "VVDBUpgrader.h"
#import "VVOrmRoute.h"
#endif

FOUNDATION_EXPORT double VVSequelizeVersionNumber;
FOUNDATION_EXPORT const unsigned char VVSequelizeVersionString[];
