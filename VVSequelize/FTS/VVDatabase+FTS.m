//
//  VVDatabase+FTS.m
//  VVSequelize
//
//  Created by Valo on 2019/3/20.
//

#import "VVDatabase+FTS.h"
#import "NSString+Tokenizer.h"

#ifdef SQLITE_HAS_CODEC
#import "sqlite3.h"
#else
#import <sqlite3.h>
#endif

//MARK: - FTS5

static fts5_api * fts5_api_from_db(sqlite3 *db)
{
    fts5_api *pRet = 0;
    sqlite3_stmt *pStmt = 0;

    if (SQLITE_OK == sqlite3_prepare(db, "SELECT fts5(?1)", -1, &pStmt, 0) ) {
#ifdef SQLITE_HAS_CODEC
        sqlite3_bind_pointer(pStmt, 1, (void *)&pRet, "fts5_api_ptr", NULL);
        sqlite3_step(pStmt);
#else
        if (@available(iOS 12.0, *)) {
            sqlite3_bind_pointer(pStmt, 1, (void *)&pRet, "fts5_api_ptr", NULL);
            sqlite3_step(pStmt);
        }
#endif
    }
    sqlite3_finalize(pStmt);
    return pRet;
}

typedef struct Fts5VVTokenizer Fts5VVTokenizer;
struct Fts5VVTokenizer {
    char locale[16];
    uint64_t mask;
    void *clazz;
};

static void vv_fts5_xDelete(Fts5Tokenizer *p)
{
    sqlite3_free(p);
}

static int vv_fts5_xCreate(
    void *pUnused,
    const char **azArg, int nArg,
    Fts5Tokenizer **ppOut
    )
{
    Fts5VVTokenizer *tok = sqlite3_malloc(sizeof(Fts5VVTokenizer));
    if (!tok) return SQLITE_NOMEM;

    memset(tok->locale, 0x0, 16);
    tok->mask = 0;

    for (int i = 0; i < MIN(2, nArg); i++) {
        const char *arg = azArg[i];
        uint32_t mask = (uint32_t)atoll(arg);
        if (mask > 0) {
            tok->mask = mask;
        } else {
            strncpy(tok->locale, arg, 15);
        }
    }

    tok->clazz = pUnused;
    *ppOut = (Fts5Tokenizer *)tok;
    return SQLITE_OK;
}

static int vv_fts5_xTokenize(
    Fts5Tokenizer *pTokenizer,
    void *pCtx,
    int iUnused,
    const char *pText, int nText,
    int (*xToken)(void *, int, const char *, int nToken, int iStart, int iEnd)
    )
{
    UNUSED_PARAM(iUnused);
    UNUSED_PARAM(pText);
    if (pText == 0) return SQLITE_OK;

    int rc = SQLITE_OK;
    Fts5VVTokenizer *tok = (Fts5VVTokenizer *)pTokenizer;
    Class<VVTokenEnumerator> clazz = (__bridge Class)(tok->clazz);
    if (!clazz || ![clazz conformsToProtocol:@protocol(VVTokenEnumerator)]) {
        return SQLITE_ERROR;
    }
    uint64_t mask = tok->mask;
    if (iUnused & FTS5_TOKENIZE_QUERY) {
        mask = mask | VVTokenMaskQuery;
    } else if (iUnused & FTS5_TOKENIZE_DOCUMENT) {
        mask = mask & ~VVTokenMaskQuery;
    }
    NSArray *array = [clazz enumerate:pText mask:(VVTokenMask)mask];

    for (VVToken *tk in array) {
        rc = xToken(pCtx, tk.colocated, tk.word, tk.len, tk.start, tk.end);
        if (rc != SQLITE_OK) break;
    }

    if (rc == SQLITE_DONE) rc = SQLITE_OK;
    return rc;
}

@implementation VVDatabase (FTS)

- (void)registerEnumerator:(Class<VVTokenEnumerator>)enumerator forTokenizer:(NSString *)name
{
    [self.enumerators setObject:enumerator forKey:name];
    if (self.isOpen) [self registerEnumerators:self.db];
}

- (Class<VVTokenEnumerator>)enumeratorForTokenizer:(NSString *)name
{
    return [self.enumerators objectForKey:name];
}

- (void)registerEnumerators:(sqlite3 *)db
{
    if (self.enumerators.count == 0) return;
    fts5_api *pApi = fts5_api_from_db(db);
    if (!pApi) {
#if DEBUG
        printf("[VVDB][DEBUG] fts5 is not supported\n");
#endif
        return;
    }

    [self.enumerators enumerateKeysAndObjectsUsingBlock:^(NSString *name, Class<VVTokenEnumerator> enumerator, BOOL *stop) {
        fts5_tokenizer *tokenizer;
        tokenizer = (fts5_tokenizer *)sqlite3_malloc(sizeof(*tokenizer));
        tokenizer->xCreate = vv_fts5_xCreate;
        tokenizer->xDelete = vv_fts5_xDelete;
        tokenizer->xTokenize = vv_fts5_xTokenize;

        int rc = pApi->xCreateTokenizer(pApi, name.cLangString, (__bridge void *)enumerator, tokenizer, NULL);
        NSString *errorsql = [NSString stringWithFormat:@"register tokenizer: %@", name];
        [self check:rc sql:errorsql];
    }];
}

@end
