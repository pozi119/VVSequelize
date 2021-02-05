//
//  VVDataBase+FTS.h
//  VVSequelize
//
//  Created by Valo on 2019/3/20.
//

#import "VVDatabase.h"
#import "VVTokenEnumerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface VVDatabase (FTS)

/// register tokenizer, only fts5 is supported
- (void)registerEnumerator:(Class<VVTokenEnumerator>)enumerator forTokenizer:(NSString *)name;

- (nullable Class<VVTokenEnumerator>)enumeratorForTokenizer:(NSString *)name;

- (void)registerEnumerators:(sqlite3 *)db;

@end

NS_ASSUME_NONNULL_END
