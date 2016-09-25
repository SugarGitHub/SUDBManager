# SUDBManager
FMDB封装,利用runtime获得字段映射，KVC赋值。直接传Model就可以进行CRUD操作
<br />
插入更新:
<br/>
-(BOOL)insertOrUpdateModelToDatabase:(id)model;
<br />
-(void)insertOrUpdateManysModelToDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock;
<br />

删除:
<br />
-(BOOL)deleteModelInDatabase:(id)model;
<br />
-(void)deleteManysModelInDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock;
<br />
-(BOOL)deleteModelInDatabase:(id)model withPredicate:(NSString *)predicate;
<br />
-(BOOL)deleteModelTableInDatabase:(id)model;
<br />

获取：
<br />
-(NSMutableArray *)selectAllModelInDatabase:(Class)model;
-(NSMutableArray *)selectModelInDatabase:(Class)model withPredicate:(NSString *)predicate;

