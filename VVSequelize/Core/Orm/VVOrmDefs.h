//
//  VVOrmDefs.h
//  VVSequelize
//
//  Created by Valo on 2019/4/2.
//

#import <Foundation/Foundation.h>

#ifndef $
#define $(field) NSStringFromSelector(@selector(field))
#endif

/// query expression, where/having sub statement
/// 1.NSString:  native sql, all subsequent statements after `where`;
/// 2.NSDictionary: key and value are connected with '=', different key values are connected with 'and';
/// 3.NSArray: [dictionary], Each dictionary is connected with 'or'
typedef NSObject   VVExpr;

// specify the fields
// NSString: `"field1","field2",...`, `count(*) as count`, ...
// NSArray: ["field1","field2",...]
typedef NSObject   VVFields;

// sort expression
// NSString: "field1 asc", "field1,field2 desc", "field1 asc,field2,field3 desc", ...
// NSArray:  ["field1 asc","field2,field3 desc",...]
typedef NSObject   VVOrderBy;

// group expression
// NSString: "field1","field2",...
// NSArray:  ["field1","field2",...]
typedef NSObject   VVGroupBy;
