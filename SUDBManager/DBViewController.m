//
//  DBViewController.m
//  SUDBManager
//
//  Created by suhengxian on 16/2/1.
//  Copyright © 2016年 Sugar. All rights reserved.
//

#import "DBViewController.h"
#import "SUDBManager.h"
#import "UserModel.h"
@interface DBViewController ()

@end

@implementation DBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}





#pragma mark --初始化UI
- (void)initUI{
    
    
    UIButton *insertBtn=[self createBtnWithFrame:CGRectMake(50, 100, 100, 50) backGroudColor:[UIColor whiteColor] title:@"插入或更新" titleColor:[UIColor blueColor] titleFont:[UIFont systemFontOfSize:15]];
    [insertBtn addTarget:self action:@selector(insertModel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:insertBtn];
    
    
    
    UIButton *deletBtn=[self createBtnWithFrame:CGRectMake(200, 100, 100, 50) backGroudColor:[UIColor whiteColor] title:@"删除" titleColor:[UIColor blueColor] titleFont:[UIFont systemFontOfSize:15]];
    [deletBtn addTarget:self action:@selector(deleteModel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deletBtn];
    
    UIButton *selectBtn=[self createBtnWithFrame:CGRectMake(50, 200, 100, 50) backGroudColor:[UIColor whiteColor] title:@"取出" titleColor:[UIColor blueColor] titleFont:[UIFont systemFontOfSize:15]];
    [selectBtn addTarget:self action:@selector(selectModel) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectBtn];
}


- (UIButton *)createBtnWithFrame:(CGRect)frame backGroudColor:(UIColor *)bgColor title:(NSString *)title titleColor:(UIColor *)titleColor titleFont:(UIFont *)titleFont{
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:titleColor forState:UIControlStateNormal];
    [btn.titleLabel setFont:titleFont];
    [btn setBackgroundColor:bgColor];
    return btn;
}


#pragma mark --增删查改
- (void)insertModel{
    NSMutableArray *arrM=[NSMutableArray array];
    NSInteger count=5000;
    for (int i=0; i<count; i++) {
        UserModel *model=[[UserModel alloc] init];
        model.name=[NSString stringWithFormat:@"%zi",i];
        model.age=@"9";
        model.sex=@"2";
        model.address=@"2";
        model.tel=@"2";
        [arrM addObject:model];
    }
    [SUDB insertOrUpdateManysModelToDatabase:arrM isSuc:nil];
}

- (void)deleteModel{
    NSMutableArray *arrM=[NSMutableArray array];
    NSInteger count=5000;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i=0; i<count; i++) {
            UserModel *model=[[UserModel alloc] init];
            model.name=[NSString stringWithFormat:@"%zi",i];;
            model.age=@"9";
            model.sex=@"2";
            model.address=@"2";
            model.tel=@"2";
            [arrM addObject:model];
        }
        
        [SUDB deleteManysModelInDatabase:arrM isSuc:nil];
        
    });
}

- (void)selectModel{
    NSArray *arr=[SUDB selectAllModelInDatabase:[UserModel class]];
    NSLog(@"%zi %@",arr.count,arr);
}


@end
