
#import "NSObject+VVOrm.h"
#import <objc/runtime.h>

@interface NSNumber (VVOrm)

@end

@implementation NSObject (VVOrm)

- (NSString *)sqlWhere
{
    return @"";
}

- (NSString *)sqlJoin
{
    return @"";
}

- (NSString *)sqlValue
{
    return [[NSString stringWithFormat:@"%@", self] quote:@"\""];
}

@end

@implementation NSDictionary (VVOrm)
- (NSString *)sqlWhere
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    for (NSString *key in self) {
        [array addObject:key.quoted.eq(self[key])];
    }
    return [array componentsJoinedByString:@" AND "];
}

- (NSDictionary *)vv_removeObjectsForKeys:(NSArray *)keys
{
    NSMutableDictionary *dic = [self mutableCopy];
    [dic removeObjectsForKeys:keys];
    return dic;
}

@end

@implementation NSArray (VVOrm)
- (NSString *)sqlWhere
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:0];
    for (id val in self) {
        NSString *str = [val sqlWhere];
        if (str.length > 0) {
            [array addObject:str];
        }
    }
    return [array componentsJoinedByString:@" OR "];
}

- (NSString *)asc
{
    return [[self sqlJoin] stringByAppendingString:@" ASC"];
}

- (NSString *)desc
{
    return [[self sqlJoin] stringByAppendingString:@" DESC"];
}

- (NSString *)sqlJoin
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (NSObject *obj in self) {
        [array addObject:obj.sqlValue];
    }
    return [array componentsJoinedByString:@","];
}

- (NSArray *)vv_distinctUnionOfObjects
{
    return [self valueForKeyPath:@"@distinctUnionOfObjects.self"];
}

- (NSArray *)vv_removeObjectsInArray:(NSArray *)otherArray
{
    NSMutableArray *array = [self mutableCopy];
    [array removeObjectsInArray:otherArray];
    return array;
}

@end

@implementation NSNumber (VVOrm)

- (NSString *)sqlValue
{
    return self.stringValue;
}

@end

@implementation NSString (VVOrm)

- (NSString *)sqlValue
{
    return self.quoted;
}

// MARK: - where
- (NSString *(^)(id))and
{
    return ^(id value) { return self.length == 0 ? [value sqlWhere] : [NSString stringWithFormat:@"%@ AND %@", self, [value sqlWhere]]; };
}

- (NSString *(^)(id))or
{
    return ^(id value) { return self.length == 0 ? [value sqlWhere] : [NSString stringWithFormat:@"(%@) OR (%@)", self, [value sqlWhere]]; };
}

- (NSString *(^)(id))on
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ ON %@", self, [value sqlWhere]]; };
}

- (NSString *(^)(id))eq
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ = %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))ne
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ != %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))gt
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ > %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))gte
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ >= %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))lt
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ < %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))lte
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ <= %@", self, [value sqlValue]]; };
}

- (NSString *(^)(void))isNull
{
    return ^() { return [NSString stringWithFormat:@"%@ IS NULL", self]; };
}

- (NSString *(^)(void))isNotNull
{
    return ^() { return [NSString stringWithFormat:@"%@ IS NOT NULL", self]; };
}

- (NSString *(^)(id, id))between
{
    return ^(id value1, id value2) { return [NSString stringWithFormat:@"%@ BETWEEN %@ AND %@", self, [value1 sqlValue], [value2 sqlValue]]; };
}

- (NSString *(^)(id, id))notBetween
{
    return ^(id value1, id value2) { return [NSString stringWithFormat:@"%@ NOT BETWEEN %@ AND %@", self, [value1 sqlValue], [value2 sqlValue]]; };
}

- (NSString *(^)(NSArray *))in
{
    return ^(NSArray *array) { return [NSString stringWithFormat:@"%@ IN (%@)", self, [array sqlJoin]]; };
}

- (NSString *(^)(NSArray *))notIn
{
    return ^(NSArray *array) { return [NSString stringWithFormat:@"%@ NOT IN (%@)", self, [array sqlJoin]]; };
}

- (NSString *(^)(id))like
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ LIKE %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))notLike
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ NOT LIKE %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))glob
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ GLOB %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))notGlob
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ NOT GLOB %@", self, [value sqlValue]]; };
}

- (NSString *(^)(id))match
{
    return ^(id value) { return [NSString stringWithFormat:@"%@ MATCH %@", self, [value description].singleQuoted]; };
}

- (NSString *(^)(NSString *))innerJoin
{
    return ^(NSString *right) { return [NSString stringWithFormat:@"%@ JOIN %@", self, right]; };
}

- (NSString *(^)(NSString *))outerJoin
{
    return ^(NSString *right) { return [NSString stringWithFormat:@"%@ LEFT OUTER JOIN %@", self, right]; };
}

- (NSString *(^)(NSString *))crossJoin
{
    return ^(NSString *right) { return [NSString stringWithFormat:@"%@ CROSS JOIN %@", self, right]; };
}

- (NSString *(^)(NSString *))column
{
    return ^(NSString *column) { return [NSString stringWithFormat:@"%@.%@", self, column]; };
}

- (NSString *(^)(NSString *, id))concat
{
    return ^(NSString *concat, id value) { return [NSString stringWithFormat:@"%@ %@ %@", self, concat, value]; };
}

- (NSString *)asc
{
    return [self stringByAppendingString:@" ASC"];
}

- (NSString *)desc
{
    return [self stringByAppendingString:@" DESC"];
}

- (NSString *)sqlWhere
{
    return self;
}

- (NSString *)sqlJoin
{
    return self;
}

// MARK: - other
- (NSString *)quote:(NSString *)quote
{
    if (quote.length == 0) return self;
    NSString *lquote = [self hasPrefix:quote] ? @"" : quote;
    NSString *rquote = [self hasSuffix:quote] ? @"" : quote;
    return [NSString stringWithFormat:@"%@%@%@", lquote, self, rquote];
}

- (NSString *)quoted
{
    return [self quote:@"\""];
}

- (NSString *)singleQuoted
{
    return [self quote:@"'"];
}

- (NSString *)removeQuote
{
    NSMutableString *result = [self mutableCopy];
    [result replaceOccurrencesOfString:@"\"" withString:@"" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"'" withString:@"" options:0 range:NSMakeRange(0, result.length)];
    return result;
}

- (NSString *)vv_trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)vv_strip
{
    static NSRegularExpression *_regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _regex = [NSRegularExpression regularExpressionWithPattern:@" +" options:0 error:nil];
    });
    return [_regex stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@" "];
}

- (BOOL)isMatch:(NSString *)regex
{
    NSStringCompareOptions options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    NSRange range = [self rangeOfString:regex options:options];
    return range.location != NSNotFound;
}

- (NSString *)prepareForParseSQL
{
    NSString *tmp = self.vv_trim.vv_strip;
    tmp = [tmp stringByReplacingOccurrencesOfString:@"'|\"" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, tmp.length)];
    return tmp;
}

+ (NSString *)leftSpanForAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
{
    NSString *css = [NSString cssForAttributes:attributes];
    return [NSString stringWithFormat:@"<span style=%@>", css.quoted];
}

+ (NSString *)cssForAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
{
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:@"X" attributes:attributes];
    NSDictionary *documentAttributes = @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType };
    NSData *htmlData = [attrText dataFromRange:NSMakeRange(0, attrText.length) documentAttributes:documentAttributes error:NULL];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    NSStringCompareOptions options = NSRegularExpressionSearch | NSCaseInsensitiveSearch;
    NSRange range = [htmlString rangeOfString:@"span\\.s1 *\\{.*\\}" options:options];
    if (range.location == NSNotFound) {
        return @"";
    }
    NSString *css = [htmlString substringWithRange:range];
    css = [css stringByReplacingOccurrencesOfString:@"span\\.s1 *\\{" withString:@"" options:options range:NSMakeRange(0, css.length)];
    css = [css stringByReplacingOccurrencesOfString:@"\\}.*" withString:@"" options:options range:NSMakeRange(0, css.length)];
    css = [css stringByReplacingOccurrencesOfString:@"'" withString:@""];
    return css;
}

@end
