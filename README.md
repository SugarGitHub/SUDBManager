# SUDBManager
FMDB封装,利用runtime获得字段映射，KVC赋值。直接传Model就可以进行CRUD操作
<br />
插入更新:
-(BOOL)insertOrUpdateModelToDatabase:(id)model;
- (void)insertOrUpdateManysModelToDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock;

<br />
删除:
- (BOOL)deleteModelInDatabase:(id)model;
- (void)deleteManysModelInDatabase:(NSArray *)arr isSuc:(void(^)(BOOL isSuc))isSucBLock;
- (BOOL)deleteModelInDatabase:(id)model withPredicate:(NSString *)predicate;
- (BOOL)deleteModelTableInDatabase:(id)model;

<br />
获取：
- (NSMutableArray *)selectAllModelInDatabase:(Class)model;
- (NSMutableArray *)selectModelInDatabase:(Class)model withPredicate:(NSString *)predicate;

