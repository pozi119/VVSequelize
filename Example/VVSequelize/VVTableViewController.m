//
//  TableViewController.m
//  VVSequelize
//
//  Created by Valo on 2019/3/1.
//  Copyright © 2019 valo. All rights reserved.
//

#import <VVSequelize/VVSequelize.h>
#import "VVTableViewController.h"
#import "VVItem.h"
#import "VVMessage.h"

#define kTblName    @"message"
#define kFtsTblName @"ftsMessage"

@interface VVTableViewController ()
@property (weak, nonatomic) IBOutlet UILabel *v100kLabel;
@property (weak, nonatomic) IBOutlet UILabel *v1mLabel;
@property (weak, nonatomic) IBOutlet UILabel *v10mLabel;
@property (weak, nonatomic) IBOutlet UILabel *v100mLabel;

@property (weak, nonatomic) IBOutlet UIButton *generateButton;
@property (weak, nonatomic) IBOutlet UILabel *generateResultLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *generateProgressView;
@property (weak, nonatomic) IBOutlet UILabel *generateProgressLabel;

@property (weak, nonatomic) IBOutlet UITextField *keywordTextField;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *searchFtsButton;
@property (weak, nonatomic) IBOutlet UILabel *searchStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *searchResultLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searchIndicator;

@property (weak, nonatomic) IBOutlet UITextView *logTextView;

@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSString *logFilePath;
@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, strong) NSArray *messageInfos;

@end

@implementation VVTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupLog];
    [self setup];
    [self loadAllDetails];
}

//MARK: -
- (void)setupLog
{
    // logger
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *docDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    self.logFilePath = [docDir stringByAppendingPathComponent:@"sequelize.log"];
    if (![fm fileExistsAtPath:self.logFilePath]) {
        [[NSData data] writeToFile:self.logFilePath atomically:NO];
    }
}

- (void)setup
{
    // default select million
    self.selectedIndex = 0;

    [NSString preloadingForPinyin];
    NSString *cipherkey = @"123456";
    NSArray *cipherOptions = @[
        @"pragma cipher_page_size = 4096;",
        @"pragma kdf_iter = 64000;",
        @"pragma cipher_hmac_algorithm = HMAC_SHA1;",
        @"pragma cipher_kdf_algorithm = PBKDF2_HMAC_SHA1;",
    ];
    //db
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:4];

    NSString *tableName = @"message";
    NSArray *configs = @[@[@"100k.db", @"f-100k.db", self.v100kLabel, @(100000)],
                         @[@"1m.db",   @"f-1m.db",   self.v1mLabel,   @(1000000)],
                         @[@"10m.db",  @"f-10m.db",  self.v10mLabel,  @(10000000)],
                         @[@"100m.db", @"f-100m.db", self.v100mLabel, @(100000000)]];

    for (NSArray *sub in configs) {
        NSString *normal = sub[0];
        NSString *fts = sub[1];
        UILabel *label = sub[2];
        unsigned long long maxCount = [sub[3] unsignedLongLongValue];

        VVItem *item = [VVItem new];
        item.tableName = tableName;
        item.label = label;
        item.maxCount = maxCount;

        item.dbName = normal;
        item.dbPath = [dir stringByAppendingPathComponent:item.dbName];
        item.db = [VVDatabase databaseWithPath:item.dbPath flags:0 encrypt:cipherkey];
        item.db.cipherOptions = cipherOptions;
        item.orm = [VVOrm ormWithClass:VVMessage.class name:item.tableName database:item.db setup:VVOrmSetupRebuild];

        item.ftsDbName = fts;
        item.ftsDbPath = [dir stringByAppendingPathComponent:item.ftsDbName];
        item.ftsDb = [VVDatabase databaseWithPath:item.ftsDbPath flags:0 encrypt:cipherkey];
        item.ftsDb.cipherOptions = cipherOptions;
        [item.ftsDb registerEnumerator:VVTokenSequelizeEnumerator.class forTokenizer:VVTokenTokenizerSequelize];
        [item.ftsDb registerEnumerator:VVTokenAppleEnumerator.class forTokenizer:VVTokenTokenizerApple];
        [item.ftsDb registerEnumerator:VVTokenNatualEnumerator.class forTokenizer:VVTokenTokenizerNatual];
        [item.db setTraceHook:^int (unsigned mask, void *stmt, void *sql) {
            return 0;
        }];

        item.ftsOrm = [VVOrm ormWithFtsClass:VVMessage.class name:item.tableName database:item.ftsDb];

        [items addObject:item];
    }
    self.items = items;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedIndex inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

- (NSArray *)messageInfos
{
    if (!_messageInfos) {
        @autoreleasepool {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"神话纪元" ofType:@"txt"];
            NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
            [set formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [set formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
            NSMutableArray *array = [[text componentsSeparatedByCharactersInSet:set] mutableCopy];
            [array removeObject:@""];
            _messageInfos = [array copy];
        }
    }
    return _messageInfos;
}

- (NSString *)stringForFileSize:(unsigned long long)size
{
    unsigned long long gb = 1 << 30;
    unsigned long long mb = 1 << 20;
    unsigned long long kb = 1 << 10;
    NSString *string = nil;
    if (size > gb) {
        string = [NSString stringWithFormat:@"%.2f GB", size * 1.0 / gb];
    } else if (size > mb) {
        string = [NSString stringWithFormat:@"%.2f MB", size * 1.0 / mb];
    } else {
        string = [NSString stringWithFormat:@"%.2f KB", size * 1.0 / kb];
    }
    return string;
}

- (void)loadDetailsForRow:(NSUInteger)row
{
    if (row >= self.items.count) return;
    self.generateButton.enabled = NO;
    VVItem *item = self.items[row];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *suffixes = @[@"", @"-shm", @"-wal"];
        unsigned long long fileSize = 0;
        unsigned long long ftsFileSize = 0;
        for (NSString *suffix in suffixes) {
            NSString *path = [item.dbPath stringByAppendingString:suffix];
            NSString *ftsPath = [item.ftsDbPath stringByAppendingString:suffix];
            unsigned long long size = [[manager attributesOfItemAtPath:path error:nil] fileSize];
            unsigned long long ftsSize = [[manager attributesOfItemAtPath:ftsPath error:nil] fileSize];
            fileSize += size;
            ftsFileSize += ftsSize;
        }

        item.fileSize = fileSize;
        item.ftsFileSize = ftsFileSize;
        item.count = [item.orm count:nil];
        NSString *size = [self stringForFileSize:item.fileSize];
        NSString *ftsSize = [self stringForFileSize:item.ftsFileSize];
        dispatch_async(dispatch_get_main_queue(), ^{
            item.label.text = [NSString stringWithFormat:@"[R] %@, [N] %@, [FTS] %@", @(item.count), size, ftsSize];
            if (row == self.selectedIndex) {
                CGFloat percent = item.maxCount > item.count ? (item.count * 1.0 / item.maxCount) : 1.0;
                self.generateProgressLabel.text = [NSString stringWithFormat:@"%.2f%%", percent * 100.0];
                self.generateButton.enabled = item.count < item.maxCount;
            }
        });
    });
}

- (void)loadAllDetails
{
    for (NSInteger i = 0; i < self.items.count; i++) {
        [self loadDetailsForRow:i];
    }
    self.logTextView.text = [NSString stringWithContentsOfFile:self.logFilePath encoding:NSUTF8StringEncoding error:nil];
}

//MARK: - Actions
- (IBAction)reset:(id)sender
{
    NSFileManager *fm = [NSFileManager defaultManager];
    for (VVItem *item in self.items) {
        [item.db close];
        [item.ftsDb close];
    }
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    [fm removeItemAtPath:dir error:nil];
    [fm createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    [fm removeItemAtPath:self.logFilePath error:nil];
    [[NSData data] writeToFile:self.logFilePath atomically:NO];
    self.logTextView.text = @"";
    [self setup];
    [self loadAllDetails];
}

- (IBAction)generateMessages:(id)sender
{
    if (self.selectedIndex >= self.items.count) return;
    VVItem *item = self.items[self.selectedIndex];

    [self updateUIWithAction:NO isSearch:NO logString:@""];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CFAbsoluteTime mockTime = 0;
        CFAbsoluteTime normalTime = 0;
        CFAbsoluteTime ftsTime = 0;

        CGFloat thousands = pow(10, self.selectedIndex) * 100;
        unsigned long long startId = item.count;
        thousands -= startId / 1000;

        for (long long i = 0; i < thousands; i++) {
            @autoreleasepool {
                CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
                NSArray *messages = [VVMessage mockThousandModels:self.messageInfos start:startId];
                CFAbsoluteTime step1 = CFAbsoluteTimeGetCurrent();
                [item.orm insertMulti:messages];
                CFAbsoluteTime step2 = CFAbsoluteTimeGetCurrent();
                [item.ftsOrm insertMulti:messages];
                CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();

                CFAbsoluteTime mock = step1 - begin;
                CFAbsoluteTime normal = step2 - step1;
                CFAbsoluteTime fts = end - step2;

                mockTime += mock;
                normalTime += normal;
                ftsTime += fts;
                startId += 1000;

                CGFloat progress = MIN(1.0, (startId * 1.0) / item.maxCount);
                NSLog(@"[%6llu-%6llu]:%6.2f%%,mock: %.6f,normal:%.6f,fts:%.6f",
                             startId - 1000, startId, progress * 100.0, mock, normal, fts);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.generateProgressView.progress = progress;
                    self.generateProgressLabel.text = [NSString stringWithFormat:@"%.2f%%", progress * 100.0];
                });
            }
        }
        NSString *string = [NSString stringWithFormat:@"[insert]: %@, mock:%.6f, normal:%.6f, fts:%.6f",
                            @(thousands * 1000), mockTime, normalTime, ftsTime];
        NSLog(@"%@", string);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadDetailsForRow:self.selectedIndex];
            [self updateUIWithAction:YES isSearch:NO logString:string];
        });
    });
}

- (IBAction)searchMessages:(id)sender
{
    if (self.selectedIndex >= self.items.count) return;
    VVItem *item = self.items[self.selectedIndex];
    NSString *text = self.keywordTextField.text;
    NSString *keyword = [NSString stringWithFormat:@"%%%@%%", text];
    if (keyword.length == 0) return;
    [self updateUIWithAction:NO isSearch:YES logString:@""];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
        NSArray *messages = [item.orm findAll:@"info".like(keyword)];
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSString *string = [NSString stringWithFormat:@"[query] normal: \"%@\", hit: %@, consumed: %@",
                            text, @(messages.count), @(end - begin)];
        NSLog(@"%@", string);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUIWithAction:YES isSearch:YES logString:string];
        });
    });
}

- (IBAction)searchFtsMessages:(id)sender
{
    if (self.selectedIndex >= self.items.count) return;
    VVItem *item = self.items[self.selectedIndex];
    NSString *text = self.keywordTextField.text;
    NSString *keyword = text;
    if (keyword.length == 0) return;
    [self updateUIWithAction:NO isSearch:YES logString:@""];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
        NSArray *messages = [item.ftsOrm match:@"info".match(keyword.fts5MatchPattern)
                                     highlight:@[@"info"]
                                       orderBy:nil limit:100 offset:0];
        CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
        NSString *string = [NSString stringWithFormat:@"[query] fts: \"%@\", hit: %@, consumed: %@",
                            text, @(messages.count), @(end - begin)];
        NSLog(@"%@", string);
        NSDictionary *attributes = @{NSForegroundColorAttributeName: UIColor.redColor};
        NSMutableArray *highlights = [NSMutableArray arrayWithCapacity:messages.count];
        for (VVMessage *message in messages) {
            NSAttributedString *attributedString = [NSAttributedString attributedStringWithHighlightString:message.info attributes:attributes];
            [highlights addObject:attributedString];
        }
        if (highlights) {
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateUIWithAction:YES isSearch:YES logString:string];
        });
    });
}

- (void)updateUIWithAction:(BOOL)done isSearch:(BOOL)isSearch logString:(NSString *)logString
{
    if (isSearch) {
        if (done) {
            [self.searchIndicator stopAnimating];
        } else {
            [self.searchIndicator startAnimating];
        }
        self.searchStatusLabel.text = done ? @"搜索结果:" : @"搜索中...";
        self.searchResultLabel.hidden = !done;
        self.searchResultLabel.text = logString;
    } else {
        self.generateProgressView.progress = done ? 1.0 : 0.0;
        self.generateProgressLabel.text = done ? @"100%" : @"";
        self.generateProgressView.hidden = done;
        self.generateProgressLabel.hidden = done;
        self.generateResultLabel.text = logString;
    }
    self.searchButton.enabled = done;
    self.searchFtsButton.enabled = done;
    self.generateResultLabel.hidden = !done;
    if (done) {
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
        [fh seekToEndOfFile];
        [fh writeData:[[logString stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [fh closeFile];
        self.logTextView.text = [NSString stringWithContentsOfFile:self.logFilePath encoding:NSUTF8StringEncoding error:nil];
        if (self.selectedIndex < self.items.count) {
            VVItem *item = self.items[self.selectedIndex];
            self.generateButton.enabled = item.count < item.maxCount;
        }
    } else {
        self.generateButton.enabled = NO;
    }
}

//MARK: - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != 0) return;
    [self loadDetailsForRow:indexPath.row];

    self.selectedIndex = indexPath.row;
    NSUInteger rows = [tableView numberOfRowsInSection:indexPath.section];
    for (NSUInteger row = 0; row < rows; row++) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
        cell.accessoryType = (row == self.selectedIndex) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
}

@end
