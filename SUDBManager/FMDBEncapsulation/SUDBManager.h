//
//  SUDBManager.h
//  SUDBManager
//
//  Created by suhengxian on 16/2/1.
//  Copyright © 2016年 Sugar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#define SUDB [SUDBManager sharedInstace]
#define myDBName @"SUDATABASE"

#define PRINTLOG  1  //0不打印日志  1打印
#if PRINTLOG
#define SUDBNSLog(...)  NSLog(@"%@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define SUDBNSLog(...)
#endif

@interface SUDBManager : NSObject
+ (SUDBManager *)sharedInstace;
-(BOOL)insertOrUpdateModelToDatabase:(id)model;
- (void)insertOrUpdateManysModelToDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock;
- (BOOL)deleteModelInDatabase:(id)model;
- (void)deleteManysModelInDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock;
- (BOOL)deleteModelInDatabase:(id)model withPredicate:(NSString *)predicate;
- (BOOL)deleteModelTableInDatabase:(id)model;
- (NSMutableArray *)selectAllModelInDatabase:(Class)model;
- (NSMutableArray *)selectModelInDatabase:(Class)model withPredicate:(NSString *)predicate;
@end