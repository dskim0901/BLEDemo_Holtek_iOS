//
//  BLEModel.m
//  BCBLEDemo
//
//  Created by holtek on 2016/10/26.
//  Copyright © 2016年 holtek. All rights reserved.
//

#import "BLEModel.h"

@implementation BLEModel


- (BOOL)renameInHistoryBLEs:(NSArray<NSDictionary *> *)historyDics{
    NSString *bleName = nil;
    for(NSDictionary *localBLE in historyDics){
        bleName = localBLE[_macAddr];
        if(bleName){
            self.name = bleName;    //之前有保存过，使用之前保存的名称
            return YES;
        }
    }
    return NO;
}

//将本地保存的数据中有mac地址的记录替换为新改的名称并保存
- (void)replaceForMacAddrInLocalBLEs:(NSMutableArray<NSDictionary *> *)historyDics{
    NSDictionary *newDic = @{self.macAddr: self.name};
    NSInteger index = [self indexInHistoryBLEs:historyDics];
    if(index == -1){
        //数组中未保存该mac地址的名称,新增一个字典
        [historyDics addObject:newDic];
    }else {
        [historyDics replaceObjectAtIndex:index withObject:newDic];
    }
    //保存到本地
    [[NSUserDefaults standardUserDefaults] setObject:historyDics forKey:@"HistoryBLENames"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//返回保存的位置，以先删除再添加
- (NSInteger)indexInHistoryBLEs:(NSArray<NSDictionary *> *)historyDics{
    NSInteger index = -1;
    for(NSDictionary *localBLE in historyDics){
        NSString *bleName = localBLE[_macAddr];
        if(bleName){
            index = [historyDics indexOfObject:localBLE];
            break;
        }
    }
    return index;
}




@end
