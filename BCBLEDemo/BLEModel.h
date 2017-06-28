//
//  BLEModel.h
//  BCBLEDemo
//
//  Created by holtek on 2016/10/26.
//  Copyright © 2016年 holtek. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEModel : NSObject

@property (copy, nonatomic) NSString *name;

@property (copy, nonatomic) NSString *bleName;

@property (copy, nonatomic) NSString *macAddr;

@property (assign, nonatomic) NSInteger signal;

@property (assign, nonatomic) BOOL fConnect;

//根据连接的BLE UUID，查询保存的历史记录，如果有记录，返回YES
- (BOOL )renameInHistoryBLEs:(NSArray<NSDictionary *> *)historyDics;

//将本地保存的数据中有mac地址的记录替换为新改的名称并保存
- (void)replaceForMacAddrInLocalBLEs:(NSMutableArray<NSDictionary *> *)historyDics;

//根据连接的BLE UUID，查询保存的历史记录，如果有记录，返回记录所在的位置，否则返回-1
- (NSInteger)indexInHistoryBLEs:(NSArray<NSDictionary *> *)historyDics;


@end
