//
//  VVForeignKey.m
//  VVSequelize
//
//  Created by Valo on 2020/12/25.
//

#import "VVForeignKey.h"

@implementation VVForeignKey

+ (instancetype)foreignKeyWithTable:(NSString *)table
                               from:(NSString *)from
                                 to:(NSString *)to
                          on_update:(VVForeignKeyAction)on_update
                          on_delete:(VVForeignKeyAction)on_delete
{
    VVForeignKey *foreignKey = [[VVForeignKey alloc] init];
    foreignKey.table = table;
    foreignKey.from = from;
    foreignKey.to = to;
    foreignKey.on_update = on_update;
    foreignKey.on_delete = on_delete;
    return foreignKey;
}

- (NSString *)table
{
    NSAssert(_table.length > 0, @"please set reference table first!");
    return _table;
}

- (NSString *)from
{
    NSAssert(_from.length > 0, @"please set local fields first!");
    return _from;
}

- (NSString *)to
{
    NSAssert(_to.length > 0, @"please set reference fields first!");
    return _to;
}

- (BOOL)isEqual:(VVForeignKey *)other
{
    if (other == self) {
        return YES;
    } else {
        return [self.table isEqualToString:other.table]
        && [self.from isEqualToString:other.from]
        && [self.to isEqualToString:other.to]
        && self.on_update == other.on_update
        && self.on_delete == other.on_delete;
    }
}

- (NSUInteger)hash
{
    return self.table.hash ^ self.from.hash ^self.to.hash ^ @(self.on_update).hash ^ @(self.on_delete).hash;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%p: table: %@, from: %@, to: %@, on_update: %@, on_delete: %@", self, self.table, self.from, self.to, @(self.on_update), @(self.on_delete)];
}

@end
