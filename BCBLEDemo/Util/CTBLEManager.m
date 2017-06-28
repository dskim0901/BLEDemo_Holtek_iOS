//
//  CTBLEView.m
//  CTBLE
//
//  Created by cheetah on 15-8-22.
//  Copyright (c) 2015年 cheetah. All rights reserved.
//

#import "CTBLEManager.h"

@interface CTBLEManager()<CBCentralManagerDelegate,CBPeripheralDelegate>

//CoreBluetooth框架
//@property (nonatomic,strong)CBPeripheralManager *bmgr; //周边管理者
@property (nonatomic,strong)CBCentralManager *bmgr; //中央管理者

@property (nonatomic,strong)NSTimer *connectTimer;      //连接计时

@end


@implementation CTBLEManager

//单例
static CTBLEManager *bleManager = nil;
+(CTBLEManager *)shareBLEManager{
    
    //类似线程锁，保证block中的代码在整个程序运行当中只执行一次
    static dispatch_once_t oneToToken;
    //oneToToken: 检查后面的代码块是否被调用
    dispatch_once(&oneToToken, ^{
        if(!bleManager){
            bleManager = [CTBLEManager new];
        }
    });
    return bleManager;
}

- (CBCentralManager *)bmgr{
    if (!_bmgr) {
        _bmgr = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    return _bmgr;
}

- (NSMutableArray *)peripherals{
    if (!_peripherals) {
        _peripherals = [NSMutableArray new];
    }
    return _peripherals;
}

//初始化
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bmgr = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
        self.maxConnectTime = 5.0f;
    }
    return self;
}

#pragma mark- CoreBluetooth框架下蓝牙代理方法

//状态发生改变时会执行该方法(蓝牙4.0没有打开变成打开时调用)
-(void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:{
            NSLog(@"Central manager did power on");
            self.isEnabled = YES;
        }break;
            
        default: {
            NSLog(@"Central manager did not power on");
            self.isEnabled = NO;
            self.isBLEConnected = NO;
        }break;
    }
    //代理返回该外围设备
    if([self.delegate respondsToSelector:@selector(bleStateChanged:)]){
        [self.delegate bleStateChanged:central.state];
    }
}

//当发现外围设备时,会调用该方法
//参数一: 发现的外围设备
//参数二: 外围设备发出信号
//参数三: 信号强度
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    if(peripheral == nil){
        NSLog(@"Find nil device!");
        return ;
    }
    //是否已经包含了该外围设备
    if (![self.peripherals containsObject:peripheral]) {
        //可以将设备当成数据源显示在UITableView上
        [self.peripherals addObject:peripheral];
        //代理返回该外围设备
        if([self.delegate respondsToSelector:@selector(didDiscoverPeripheral:RSSI:)]){
            [self.delegate didDiscoverPeripheral:peripheral RSSI:RSSI];
        }
    }
}

//连接上外围设备的时候会调用该方法
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    [self.connectTimer invalidate];
    self.connectTimer = nil;
    //保存设备
    self.isBLEConnected = YES;  //已连接设备
    self.selPeripheral = peripheral;
    if([_delegate respondsToSelector:@selector(didConnectedPeripheral:)]){
        [_delegate didConnectedPeripheral:peripheral];
    }
    //停止扫描
//    [self stopScan];
    //扫描设备所有的服务,可以指定扫描该外围设备的哪些服务
    [peripheral discoverServices:nil];
//    [peripheral discoverServices:@[[CBUUID UUIDWithString:self.uuidWriteService],[CBUUID UUIDWithString:self.uuidReadService]]];
    //设置代理
    peripheral.delegate = self;
}


#pragma mark-CBPeripheral的代理方法

//发现外围设备的服务会调用该方法(扫描到服务之后直接添加到peripheral的services)
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    if (error){
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didDiscoverServiceForPeripheral:)]) {
        [_delegate didDiscoverServiceForPeripheral:peripheral];
    }
    
    for(CBService *service in peripheral.services){
        
            NSLog(@"Service found with UUID:%@",service.UUID);
            //可以指定要扫描的特征,传nil为扫描所有特征
            [peripheral discoverCharacteristics:nil forService:service];
    }
    
}

//当扫描到某一个服务的特征时会调用该方法
//service: 在哪一个服务里的特征
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    if (error){
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    if ([self.delegate respondsToSelector:@selector(didDiscoverCharacterForService:)]) {
        [_delegate didDiscoverCharacterForService:service];
    }
}

#pragma mark- 数据交互


//写数据
-(void)sendWithBytes:(Byte *)byteData length:(NSInteger)length forCharacter:(CBCharacteristic *)characteristic{
    if(characteristic == nil){
        NSLog(@"write character nil");
        return ;
    }
    // NSLog(@"write character:%@",charactier);
    NSData *sendData = [[NSData alloc]initWithBytes:byteData length:length];
  //  [self.selPeripheral writeValue:sendData forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    if((characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) == CBCharacteristicPropertyWriteWithoutResponse)
    {
        [self.selPeripheral writeValue:sendData forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    }else
    {
        [self.selPeripheral writeValue:sendData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}


//写数据
-(void)sendWithData:(NSData *)data forCharacter:(CBCharacteristic *)charactier{
    //发送时会缓存，等上一笔发送完成了，再将缓存的数据发送出去，看起来像是延迟
    [self.selPeripheral writeValue:data forCharacteristic:charactier type:CBCharacteristicWriteWithResponse];
}

//这时还会触发一个代理事件
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSLog(@"characteristic:%@,send error:%@",characteristic,error);
    if([self.delegate respondsToSelector:@selector(didSendDataForCharacter:)]){
        [self.delegate didSendDataForCharacter:characteristic];
    }
}

//读数据
//数据的读分为两种，一种是直接读(reading directly),另外一种是订阅(subscribe)
//实际使用中具体用一种要看具体的应用场景以及特征本身的属性。特征本身的属性是指什么呢？特征有个properties字段(characteristic.properties),它是一个整型值,有如下几个定义:
//enum {
//    CBCharacteristicPropertyBroadcast = 0x01,
//    CBCharacteristicPropertyRead = 0x02,
//    CBCharacteristicPropertyWriteWithoutResponse = 0x04,
//    CBCharacteristicPropertyWrite = 0x08,
//    CBCharacteristicPropertyNotify = 0x10,
//    CBCharacteristicPropertyIndicate = 0x20,
//    CBCharacteristicPropertyAuthenticatedSignedWrites = 0x40,
//    CBCharacteristicPropertyExtendedProperties = 0x80,
//};
//如要交互的特征，它的properties的值是0x10,表示只能用订阅的方式来接收数据：
//监听设备
-(void)readMonitorFor:(CBCharacteristic *)characteristic{
    if(characteristic == nil){
        NSLog(@"read character nil");
        return ;
    }
    NSLog(@"Add subscribe for characteristic:%@",characteristic.UUID.UUIDString);
    [self.selPeripheral setNotifyValue:YES forCharacteristic:characteristic];
}
//当设备有数据返回时，同样是通过一个系统回调通知
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    if (error){
        NSLog(@"Error updating value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    if([self.delegate respondsToSelector:@selector(didReceiveDataForCharacter:)]){
        [_delegate didReceiveDataForCharacter:characteristic];
    }
}

//断开连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    NSLog(@"Disconnect！");
    self.isBLEConnected = NO;
    if([self.delegate respondsToSelector:@selector(disConnectedPeripheral:)]){
        [_delegate disConnectedPeripheral:peripheral];
    }
}


#pragma mark-自定义方法

//返回：BLE是否已打开
-(BOOL)startScan{
    
    if([self.bmgr state] == CBCentralManagerStatePoweredOn){
        [self.peripherals removeAllObjects];
        //断开已连接的设备
        //[self disConnect];
        //扫描所有外围设备
        //参数一: serviceUUIDs: 可以将需要扫描的服务的外围设备传入(没有该服务的设备不扫描,若传nil,扫描所有)
        [self.bmgr scanForPeripheralsWithServices:nil options:nil];
        return YES;
    }else{
        return NO;
    }
}

-(void)stopScan{
    //停止扫描
    [self.bmgr stopScan];
}

//根据ble模块名称连接BLE，开始扫描后需等待一段时间

//-(CBPeripheral *)connectWithBLEName:(NSString *)bleStr{
//    //开一个定时器，用来实现连接超时
//    if(self.isHandleDisconnect)
//    {
//        self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:self.maxConnectTime target:self selector:@selector(connectTimeOut:) userInfo:@{@"deviceBLEName":bleStr} repeats:NO];
//    }
//    for(CBPeripheral *peripheral in self.peripherals){
//        if([peripheral.name isEqualToString:bleStr]){
//            //连接BLE
//            [self connect:peripheral];
//            return peripheral;
//        }
//    }
//    return nil;
//}

-(CBPeripheral *)connectWithBLEUUID:(NSString *)bleUUID{
    //开一个定时器，用来实现连接超时
    if(self.isHandleDisconnect)
    {
        self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:self.maxConnectTime target:self selector:@selector(connectTimeOut:) userInfo:@{@"deviceBLEUUID":bleUUID} repeats:NO];
    }
    for(CBPeripheral *peripheral in self.peripherals){
        if([peripheral.identifier.UUIDString isEqualToString:bleUUID]){
            //连接BLE
            [self connect:peripheral];
            return peripheral;
        }
    }
    return nil;
}

//自定义方法
//连接设备,可以通过点击TableView中的cell来触发
-(void)connect:(CBPeripheral *)peripheral{
    //停止扫描
    [self.bmgr stopScan];
    //断开已连接的设备
    [self disConnect];
    NSLog(@"connect %@",peripheral);
    //连接外围设备
    [self.bmgr connectPeripheral:peripheral options:nil];
}

//连接超时
-(void)connectTimeOut:(NSTimer *)timer{
    //回调
    if([_delegate respondsToSelector:@selector(connectTimeOut:)]){
        [_delegate connectTimeOut:[[timer userInfo] objectForKey:@"deviceBLEName"]];
    }
    [timer invalidate];
    self.connectTimer = nil;
    self.isBLEConnected = NO;
}

//主动断开设备
-(NSString *)disConnect{
    NSString *disConnectName = nil;
    if (self.selPeripheral != nil)
    {
        disConnectName = self.selPeripheral.name;
        NSLog(@"DisConnect %@!",self.selPeripheral);
        [self.bmgr cancelPeripheralConnection:self.selPeripheral];
      //  self.selPeripheral = nil;
    }
    return disConnectName;
}



@end
