//
//  CTBLEView.h
//  CTBLE
//
//  Created by cheetah on 15-8-22.
//  Copyright (c) 2015年 cheetah. All rights reserved.
//
//====================== 蓝牙 =============================//

//IOS提供了四个框架用于实现蓝牙连接
//GameKit.framework(只能用于IOS设备之间的连接,且只能用于同一个应用程序之间的连接,发送的数据量不大,IOS7开始过期)
//MultipeerConnectivity.framework(只能用于IOS设备之间的连接,IOS7引入,主要用于沙盒中文件共享)
//ExternalAccessory.framework(可用于第三方蓝牙设备交互,但需经过苹果MFI认证)
//CoreBluetooth.framework(时下热门,可用于第三方蓝牙设备交互,但须支持蓝牙4.0,硬件至少是4s,系统至少是IOS6)

//************* 使用CoreBluetooth.framework **************//

//A\如何让ios模拟器也能测试蓝牙4.0程序?
//1\电脑需有蓝牙4.0适配器,若没有,买一个CSR,插在Mac上,在终端输入sudo nvram bluetoothHostControllerSwitchBehavior="never",重启Mac
//2\用Xcode4.6调式代码,将程序跑在IOS6.1的模拟器上(苹果把ios7.0模拟器对BLE的支持移除掉了)

//B\CoreBluetooth的基本常识
//1\每个蓝牙4.0设备都是通过服务(Service)和特征(Characteristic)来展示自己
//2\一个设备必然包含一个或多个服务,每个服务下面又包含若干个特征
//3\特征是与外界交互的最小单位,如用特征A描述自己的出厂信息,特征B用来传输数据
//4\服务和特征都是用UUID来唯一标识,
//5\设备里各个服务和特征的功能,由蓝牙设备硬件厂商提供

#import <UIKit/UIKit.h>
//导入CoreBluetooth框架
#import <CoreBluetooth/CoreBluetooth.h>

@protocol CTBLEManagerDelegate < NSObject >

@optional

//蓝牙状态改变
- (void)bleStateChanged:(CBManagerState )state;

//搜索到新BLE设备时，返回BLE模组名称
-(void)didDiscoverPeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)RSSI;

//已连上设备
-(void)didConnectedPeripheral:(CBPeripheral *)peripheral;

//断开连接
-(void)disConnectedPeripheral:(CBPeripheral *)peripheral;

//搜索到服务
-(void)didDiscoverServiceForPeripheral:(CBPeripheral *)peripheral;

//搜索到特征
-(void)didDiscoverCharacterForService:(CBService *)service;

//接收到数据
-(void)didReceiveDataForCharacter:(CBCharacteristic *)characteristic;

//数据发送完成
-(void)didSendDataForCharacter:(CBCharacteristic *)characteristic;

//连接超时
-(void)connectTimeOut:(NSString *)bleName;

@end

@interface CTBLEManager : NSObject

@property (nonatomic,weak) id<CTBLEManagerDelegate> delegate;
@property (nonatomic,assign) CGFloat maxConnectTime;
@property (nonatomic,strong) NSMutableArray *peripherals;    //保存扫描到的设备
@property (nonatomic,strong) CBPeripheral   *selPeripheral;     //保存选中的设备
@property (nonatomic,assign) BOOL  isEnabled;      //BLE是否已打开
@property (nonatomic,assign) BOOL  isBLEConnected; //BLE是否已连接设备
@property (nonatomic,assign) BOOL  isHandleDisconnect; //BLE是否已连接设备
+(CTBLEManager *)shareBLEManager;

//启动扫描
-(BOOL)startScan;

//停止扫描
-(void)stopScan;

//根据ble模块名称连接BLE，开始扫描后需等待一段时间
//-(CBPeripheral *)connectWithBLEName:(NSString *)bleStr;
-(CBPeripheral *)connectWithBLEUUID:(NSString *)bleUUID;

-(NSString *)disConnect;

//监听特征以获取设备发送的数据
-(void)readMonitorFor:(CBCharacteristic *)characteristic;

-(void)sendWithBytes:(Byte *)byteData length:(NSInteger)length forCharacter:(CBCharacteristic *)charactier;

-(void)sendWithData:(NSData *)data forCharacter:(CBCharacteristic *)charactier;


@end
