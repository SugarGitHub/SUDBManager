//
//  SUDBManager.m
//  SUDBManager
//
//  Created by suhengxian on 16/2/1.
//  Copyright © 2016年 Sugar. All rights reserved.
//

#import "SUDBManager.h"
#import <objc/runtime.h>
#import "FMDatabaseQueue.h"

#define KCLASS_NAME(model) NSStringFromClass([model class])
#define KCLASS_NAMEWITHCLASS(class) NSStringFromClass(class)
#define KMODEL_PROPERTYS(model) [self getAllProperties:model]
#define KMODEL_PROPERTYS_COUNT(model) [[self getAllProperties:model] count]
static SUDBManager * manager = nil;


@implementation SUDBManager{
    FMDatabaseQueue *_dbQueue;
}

#pragma mark --创建数据库
+ (SUDBManager *)sharedInstace{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[SUDBManager alloc]init];
    });
    return manager;
}

- (void)creatDatabase:(NSString *)databaseName{
    NSArray *filePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [filePath firstObject];
    SUDBNSLog(@"%@数据库路径 %@",databaseName,filePath);
    NSString *dbFilePath = [documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite",databaseName]];
    _dbQueue = [[FMDatabaseQueue alloc]initWithPath:dbFilePath];

}

- (void)createDataQueue{
    if (!_dbQueue) {
        [self creatDatabase:myDBName];
    }
}


#pragma mark --创建表
- (void)creatTable:(id)model{
    [self createDataQueue];
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        [self creatTable:model with:db];
    }];
    [_dbQueue close];
}


- (void)creatTable:(id)model with:(FMDatabase *)db{
    [db setShouldCacheStatements:YES];
    NSString *creatTableStrOne = [NSString stringWithFormat:@"create table %@ ",KCLASS_NAME(model)];
    NSMutableString *creatTableStrTwo = [NSMutableString string];
    for (NSInteger i=0;i< [KMODEL_PROPERTYS(model) count];i++){
        if (i==0) {
            if ([KMODEL_PROPERTYS(model)[i] isKindOfClass:[NSData class]]) {
                [creatTableStrTwo appendFormat:@"(%@ blob primary key",KMODEL_PROPERTYS(model)[i]];
            }else{
                [creatTableStrTwo appendFormat:@"(%@ text primary key",KMODEL_PROPERTYS(model)[i]];
            }
        }else{
            if ([KMODEL_PROPERTYS(model)[i] isKindOfClass:[NSData class]]) {
                [creatTableStrTwo appendFormat:@",%@ blob",KMODEL_PROPERTYS(model)[i]];
            }else{
                [creatTableStrTwo appendFormat:@",%@ text",KMODEL_PROPERTYS(model)[i]];
            }
        }
    }
    NSString *creatTableStr = [NSString stringWithFormat:@"%@%@)",creatTableStrOne,creatTableStrTwo];
    
    if ([db executeUpdate:creatTableStr]) {
         SUDBNSLog(@"%@ 表已在 %@数据库中创建完成",KCLASS_NAME(model),myDBName);
    }
}


#pragma mark --数据库插入或更新实体

-(BOOL)insertOrUpdateModelToDatabase:(id)model{
    __block  BOOL suc=NO;
    if (!model) {
        SUDBNSLog(@"数据库%@----不能插入空值",myDBName);
        return suc;
    }
    [self createDataQueue];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if ([self insertOrUpdateModelToDatabase:model with:db]) {
            suc=YES;
        }
    }];
    [_dbQueue close];
    return suc;
}

- (void)insertOrUpdateManysModelToDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock{
    if (!arr) {
        SUDBNSLog(@"数据库%@----不能插入空值",myDBName);
        return;
    }
    
    [self createDataQueue];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
       
            for (id model in arr) {
                [self insertOrUpdateModelToDatabase:model with:db];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (*rollback) {
                    SUDBNSLog(@"批量插入或更新失败");
                }else{
                    SUDBNSLog(@"批量插入或更新成功");
                }
                if (isSucBLock) {
                    isSucBLock(!*rollback);
                }
               
            });
        }];
        [_dbQueue close];
    });
}



-(BOOL)insertOrUpdateModelToDatabase:(id)model with:(FMDatabase *)db{
    if(![db tableExists:KCLASS_NAME(model)]){
        [self creatTable:model with:db];
    }
    [db setShouldCacheStatements:YES];
    
    NSString *selectStr = [NSString stringWithFormat:@"select * from %@ where %@ = ?",KCLASS_NAME(model),[KMODEL_PROPERTYS(model) firstObject]];
    
    FMResultSet * resultSet = [db executeQuery:selectStr,[model valueForKey:[KMODEL_PROPERTYS(model) firstObject]]];
    if ([resultSet next]) {
        NSString *updateStrOne = [NSString stringWithFormat:@"update %@ set ",KCLASS_NAME(model)];
        NSMutableString *updateStrTwo = [NSMutableString string];
        for (int i = 0;i< KMODEL_PROPERTYS_COUNT(model);i++) {
            [updateStrTwo appendFormat:@"%@ = ?",[KMODEL_PROPERTYS(model) objectAtIndex:i]];
            if (i != KMODEL_PROPERTYS_COUNT(model) -1) {
                [updateStrTwo appendFormat:@","];
            }
        }
        NSString *updateStrThree = [NSString stringWithFormat:@" where %@ = '%@'",[KMODEL_PROPERTYS(model) firstObject], [model valueForKey:[KMODEL_PROPERTYS(model) firstObject]]];
        
        NSString *updateStr = [NSString stringWithFormat:@"%@%@%@",updateStrOne,updateStrTwo,updateStrThree];
        NSMutableArray *propertyValue = [NSMutableArray array];
        for (NSString *property in KMODEL_PROPERTYS(model)) {
            if (![model valueForKey:property]) {
                [propertyValue addObject:@""];
            }else{
                [propertyValue addObject:[model valueForKey:property]];
            }
            
        }
        [db closeOpenResultSets];
        
        if([db executeUpdate:updateStr withArgumentsInArray:propertyValue])
        {
            SUDBNSLog(@"%@-------%@=%@ 已更新到 %@数据中",KCLASS_NAME(model),[KMODEL_PROPERTYS(model) firstObject],[model valueForKey:[KMODEL_PROPERTYS(model) firstObject]],myDBName);
            return YES;
        }
    }
    else
    {
        NSString *insertStrOne = [NSString stringWithFormat:@"insert into %@ (",KCLASS_NAME(model)];
        NSMutableString *insertStrTwo =[NSMutableString string];
        for (int i =0; i<KMODEL_PROPERTYS_COUNT(model); i++) {
            [insertStrTwo appendFormat:@"%@",[KMODEL_PROPERTYS(model) objectAtIndex:i]];
            if (i!=KMODEL_PROPERTYS_COUNT(model) -1) {
                [insertStrTwo appendFormat:@","];
            }
        }
        NSString *insertStrThree =[NSString stringWithFormat:@") values ("];
        NSMutableString *insertStrFour =[NSMutableString string];
        for (int i =0; i<KMODEL_PROPERTYS_COUNT(model); i++) {
            [insertStrFour appendFormat:@"?"];
            if (i!=KMODEL_PROPERTYS_COUNT(model) -1) {
                [insertStrFour appendFormat:@","];
            }
        }
        NSString *insertStr = [NSString stringWithFormat:@"%@%@%@%@)",insertStrOne,insertStrTwo,insertStrThree,insertStrFour];
        NSMutableArray *propertyValue = [NSMutableArray array];
        for (NSString *property in KMODEL_PROPERTYS(model)) {
            if (![model valueForKey:property]) {
                [propertyValue addObject:@""];
            }else{
                [propertyValue addObject:[model valueForKey:property]];
            }
        }
        if([db executeUpdate:insertStr withArgumentsInArray:propertyValue])
        {
            SUDBNSLog(@"%@-------%@=%@ 已插入到 %@数据库中",KCLASS_NAME(model),[KMODEL_PROPERTYS(model) firstObject],[model valueForKey:[KMODEL_PROPERTYS(model) firstObject]],myDBName);
            return YES;
            
        }
    }
    return NO;
}


#pragma mark --数据库删除实体
- (BOOL)deleteModelInDatabase:(id)model{
    __block  BOOL suc=NO;
    if (!model) {
        SUDBNSLog(@"数据库%@----不能删除空值",myDBName);
        return suc;
    }
    
    [self createDataQueue];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if ([self deleteModelInDatabase:model with:db with:nil with:NO]) {
            suc=YES;
        }
    }];
    [_dbQueue close];
    return suc;
}


- (void)deleteManysModelInDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock{
    if (!arr) {
        SUDBNSLog(@"数据库%@----不能删除空值",myDBName);
        return;
    }
    
    [self createDataQueue];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            for (id model in arr) {
                [self deleteModelInDatabase:model with:db with:nil with:NO];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (*rollback) {
                    SUDBNSLog(@"批量删除失败");
                }else{
                    SUDBNSLog(@"批量删除成功");
                }
                if (isSucBLock) {
                    isSucBLock(!*rollback);
                }
            });
        }];
        [_dbQueue close];
    });

}


- (BOOL)deleteModelInDatabase:(id)model withPredicate:(NSString *)predicate{
    __block  BOOL suc=NO;
    if (!model) {
        SUDBNSLog(@"数据库%@----不能删除空值",myDBName);
        return suc;
    }
    [self createDataQueue];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if ([self deleteModelInDatabase:model with:db with:predicate with:NO]) {
            suc=YES;
        }
    }];
    [_dbQueue close];
    return suc;
}

- (BOOL)deleteModelTableInDatabase:(id)model
{
    __block  BOOL suc=NO;
    if (!model) {
        SUDBNSLog(@"数据库%@----不能删除空值",myDBName);
        return suc;
    }
    
    [self createDataQueue];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if ([self deleteModelInDatabase:model with:db with:nil with:YES]) {
            suc=YES;
        }
    }];
    [_dbQueue close];
    return suc;
}


- (BOOL)deleteModelInDatabase:(id)model with:(FMDatabase *)db with:(NSString *)predicate with:(BOOL)deleteTable{
    if(![db tableExists:KCLASS_NAME(model)])
    {
        SUDBNSLog(@"%@数据库中不存在:%@表",myDBName,KCLASS_NAME(model));
        return NO;
    }
    
    NSString *deleteStr =nil;
    if (deleteTable) {
         deleteStr=[NSString stringWithFormat:@"delete from %@",KCLASS_NAME(model)];
    }else{
        if (predicate==nil) {
            deleteStr=[NSString stringWithFormat:@"delete from %@ where %@ = ?",KCLASS_NAME(model),[KMODEL_PROPERTYS(model) firstObject]];
        }else{
            deleteStr=[NSString stringWithFormat:@"delete from %@  %@",KCLASS_NAME(model),predicate];
        }
    }
    
    if([db executeUpdate:deleteStr,[model valueForKey:[KMODEL_PROPERTYS(model) firstObject]]]){
        if (deleteTable) {
           SUDBNSLog(@"%@表-------%@数据库中已删除",KCLASS_NAME(model),myDBName);
        }else{
           SUDBNSLog(@"%@-------%@=%@ 已在 %@数据库中删除",KCLASS_NAME(model),[KMODEL_PROPERTYS(model) firstObject],[model valueForKey:[KMODEL_PROPERTYS(model) firstObject]],myDBName);
        }
     
        return YES;
    }
    
    return NO;
}


#pragma mark --数据库查询实体
- (NSMutableArray *)selectAllModelInDatabase:(Class)model
{
    [self createDataQueue];
    __block NSMutableArray *arrM=nil;
     
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        arrM=[self selectModelInDatabase:model withDB:db withPredicate:nil];
    }];
    [_dbQueue close];
    return arrM;
}


- (NSMutableArray *)selectModelInDatabase:(Class)model withPredicate:(NSString *)predicate
{
    [self createDataQueue];
    __block NSMutableArray *arrM=nil;
    [_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        arrM=[self selectModelInDatabase:model withDB:db withPredicate:predicate];
    }];
    return arrM;
}


- (NSMutableArray *)selectModelInDatabase:(Class)model withDB:(FMDatabase *)db withPredicate:(NSString *)predicate{
    if(![db tableExists:KCLASS_NAMEWITHCLASS(model)]) return nil;
    [db setShouldCacheStatements:YES];
    NSMutableArray *modelArray = [NSMutableArray array];
    NSString * selectStr = nil;
    if (predicate==nil) {
        selectStr=[NSString stringWithFormat:@"select * from %@",KCLASS_NAMEWITHCLASS(model)];
    }else{
        selectStr=[NSString stringWithFormat:@"select * from %@ %@",KCLASS_NAMEWITHCLASS(model),predicate];
    }
   
    FMResultSet *resultSet = [db executeQuery:selectStr];
    while([resultSet next]) {
        id selectModel = [[[model class] alloc]init];
        for (int i =0; i< KMODEL_PROPERTYS_COUNT(model); i++) {
            ;
            [selectModel setValue:[resultSet stringForColumn:[KMODEL_PROPERTYS(model) objectAtIndex:i]] forKey:[KMODEL_PROPERTYS(model) objectAtIndex:i]];
        }
        [modelArray addObject:selectModel];
    }
  
    return modelArray;
}

#pragma mark --获得实体属性
- (NSMutableArray *)getAllProperties:(id)model{
    u_int count;
    objc_property_t *properties  = class_copyPropertyList([model class], &count);
    NSMutableArray *propertiesArray = [NSMutableArray array];
    for (int i = 0; i < count ; i++){
        const char* propertyName = property_getName(properties[i]);
        [propertiesArray addObject: [NSString stringWithUTF8String: propertyName]];
    }
    free(properties);
    return propertiesArray;
}



@end
