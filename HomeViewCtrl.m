//
//  HomeViewCtrl.m
//  BCBLEDemo
//
//  Created by holtek on 2016/10/26.
//  Copyright © 2016年 holtek. All rights reserved.
//

#import "HomeViewCtrl.h"
#import "CTBLEManager.h"
#import "BLETabCell.h"
#import "BLEModel.h"


//需要的service的UUID字符串
#define         UUID_SERVICE @"FFF0"
//读特征的UUID字符串
#define         UUID_WRITE_CHARACTER @"FFF2"


//需要的service的UUID字符串
//#define         UUID_READ_SERVICE            @"1000"
//写特征的UUID字符串
#define         UUID_READ_CHARACTER @"FFF1"

@interface HomeViewCtrl ()<CTBLEManagerDelegate,UITableViewDelegate,UITableViewDataSource>{
    NSInteger reSendCount ;
    Byte serialNumber;
    Byte sendKeyStatus;
    BOOL fFindWriteCharacter;
    BOOL fFindReadCharacter;
}

@property (nonatomic,strong) CTBLEManager *bleDefault;

@property (weak, nonatomic) IBOutlet UILabel *bleName;

@property (weak, nonatomic) IBOutlet UITextField *bleNameTF;

@property (weak, nonatomic) IBOutlet UIButton *bleBtn;

@property (weak, nonatomic) IBOutlet UIButton *disconectBtn;

@property (weak, nonatomic) IBOutlet UIButton *button1;
@property (weak, nonatomic) IBOutlet UIButton *button2;
@property (weak, nonatomic) IBOutlet UIButton *button3;


@property (nonatomic,strong) NSMutableArray *blesListArr;

@property (nonatomic,strong) NSMutableArray<NSDictionary *> *historyBLENameArr;

@property (weak, nonatomic) IBOutlet UITableView *devicesTabView;

@property (nonatomic,strong) CBCharacteristic *readCharacteristic;//保存读特征
@property (nonatomic,strong) CBCharacteristic *writeCharacteristic;//保存写特征

@property (nonatomic,strong) NSTimer *timer;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyLeadingConstra;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lampLeadingConstra;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *key12DistanceConstra;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *key23DistanceConstra;



//tag从20开始

- (IBAction)btnAction:(UIButton *)sender;


- (IBAction)btnDownAction:(UIButton *)sender;
- (IBAction)btn2DownAction:(UIButton *)sender;
- (IBAction)btn3DownAction:(UIButton *)sender;


@end

@implementation HomeViewCtrl

//懒加载
- (NSMutableArray *)blesListArr{
    if (!_blesListArr) {
        _blesListArr = [NSMutableArray new];
    }
    return _blesListArr;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //开始扫描
    self.bleDefault          = [CTBLEManager shareBLEManager];
    self.bleDefault.delegate = self;
    
    serialNumber = 0;
    //未连接蓝牙是disconectBtn点击无效
    [self.disconectBtn setUserInteractionEnabled:NO];
    //加载本地保存的已连接BLE名称
    NSArray *historyArr = [[NSUserDefaults standardUserDefaults] valueForKey:@"HistoryBLENames"];
    if(historyArr == nil){
        _historyBLENameArr = [NSMutableArray new];
    }else{
        _historyBLENameArr = [historyArr mutableCopy];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone){
        //iPad，更改标题大小
        self.bleName.font = [UIFont systemFontOfSize:35];
        self.bleNameTF.font = [UIFont systemFontOfSize:35];
        for(NSInteger i=21; i<24; i++){
            UIButton *btn = (UIButton *)[self.view viewWithTag:i];
            btn.titleLabel.font = [UIFont systemFontOfSize:32];
        }
    }
    
    //标题添加手势
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(titleAction:)];
    [self.bleName addGestureRecognizer:tapGes];
    
    //注册tableView cell
    self.devicesTabView.tableFooterView = [UIView new];
    [self.devicesTabView registerNib:[UINib nibWithNibName:@"BLETabCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"BLETabCell"];
    [self.devicesTabView reloadData];
    
    //重复发送定时器, 200ms重发
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(timeOut:) userInfo:nil repeats:YES];
    [_timer setFireDate:[NSDate distantFuture]];
    
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    self.keyLeadingConstra.constant = self.view.bounds.size.width/6.0;
    self.lampLeadingConstra.constant = self.view.bounds.size.width/6.0;
    self.key12DistanceConstra.constant = self.view.bounds.size.height/8.5;
    self.key23DistanceConstra.constant = self.view.bounds.size.height/8.5;
}

//按键释放时响应
- (IBAction)btnAction:(UIButton *)sender {
    if(!self.bleDefault.isEnabled){
        [self showMsg:@"Please open bluetooth first!"];
        return ;
    }
    if(sender.tag == 21 || sender.tag == 22 || sender.tag == 23){
        if(!self.bleDefault.isBLEConnected){
            [self showMsg:@"Please connect device first!"];
            return ;
        }
    }
    switch (sender.tag-20){
        case 0:{    //下拉
            if((!self.bleDefault.isHandleDisconnect)&&(self.bleDefault.selPeripheral != nil)&&(!self.bleDefault.isBLEConnected))
            {
                [self.bleDefault startScan];
            }
            self.devicesTabView.hidden = !self.devicesTabView.hidden;
            self.bleBtn.selected = !self.bleBtn.selected;
            if(!self.devicesTabView.hidden){
               // sender.selected = YES;
                //清空数组
                [self.blesListArr removeAllObjects];
                //刷新
                [self.devicesTabView reloadData];
                //显示tabview时扫描ble
                [self.bleDefault startScan];
            }
//            else {
              //  sender.selected = NO;
                //隐藏时停止扫描
//                [self.bleDefault stopScan];
//            }
            return ;
        }break;
        case 1:{
            [self.button1 setSelected:NO];
            sendKeyStatus = 0b00010000 | (sendKeyStatus&0b00001110);
        }break;
        case 2:{
            [self.button2 setSelected:NO];
            sendKeyStatus = 0b00100000 | (sendKeyStatus&0b00001101);
        }break;
        case 3:{
            [self.button3 setSelected:NO];
            sendKeyStatus = 0b01000000 | (sendKeyStatus&0b00001011);
        }break;
        case 4:{    //更新名称OK
            //记录名称
            BLEModel *model = [BLEModel new];
            model.name = self.bleNameTF.text;
            model.macAddr = self.bleDefault.selPeripheral.identifier.UUIDString;
            [model replaceForMacAddrInLocalBLEs:self.historyBLENameArr];
            //重新隐藏
            self.bleNameTF.hidden = YES;
            UIButton *okBtn = (UIButton*)[self.view viewWithTag:24];
            okBtn.hidden = YES;
            //
            self.bleName.text = _bleNameTF.text;
            self.bleName.hidden = NO;
            
        }break;
        case 5:{
            if(sender.selected){
            //如果BLE已连接，先断开
                [self.bleDefault disConnect];
                [self.blesListArr removeAllObjects];
                self.bleDefault.isHandleDisconnect = YES;
                break;
            }
        }
        default:{
            return ;
        }break;
    }
    [self sendData:sendKeyStatus ifReSend:NO];
}



//按键按下时响应
- (IBAction)btnDownAction:(UIButton *)sender {
    if(self.bleDefault.isEnabled&&self.bleDefault.isBLEConnected){
    [self.button1 setSelected:YES];
    [self.button1 setBackgroundImage:[UIImage imageNamed:@"button_pressed.png"] forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    [self btnDown:sender.tag-20];
}

- (IBAction)btn2DownAction:(UIButton *)sender {
    if(self.bleDefault.isEnabled&&self.bleDefault.isBLEConnected){
        [self.button2 setSelected:YES];
        [self.button2 setBackgroundImage:[UIImage imageNamed:@"button_pressed.png"] forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    [self btnDown:sender.tag-20];
}

- (IBAction)btn3DownAction:(UIButton *)sender {
    if(self.bleDefault.isEnabled&&self.bleDefault.isBLEConnected){
        [self.button3 setSelected:YES];
        [self.button3 setBackgroundImage:[UIImage imageNamed:@"button_pressed.png"] forState:UIControlStateSelected | UIControlStateHighlighted];
    }
    [self btnDown:sender.tag-20];
}

- (void)btnDown:(NSInteger)sender{
    if(!self.bleDefault.isEnabled){
        [self showMsg:@"Please open bluetooth first!"];
        return ;
    }
    if(!self.bleDefault.isBLEConnected){
        [self showMsg:@"Please connect device first!"];
        return ;
    }
    sendKeyStatus &= 0x0f;
    switch (sender){
        case 1:{
            sendKeyStatus = 0b00010000 | (sendKeyStatus|0b00000001);
        }break;
        case 2:{
            sendKeyStatus = 0b00100000 | (sendKeyStatus|0b00000010);
        }break;
        case 3:{
            sendKeyStatus = 0b01000000 | (sendKeyStatus|0b00000100);
        }break;
        default:{
            return ;
        }break;
    }
    [self sendData:sendKeyStatus ifReSend:NO];
}

//点击蓝牙名称时，需连上蓝牙后才有效
- (void)titleAction:(UITapGestureRecognizer *)tapGes{
   // [self showMsg:@"rename"];
    self.bleNameTF.hidden = NO;
    self.bleNameTF.text = self.bleName.text;
    self.bleName.hidden = YES;
    UIButton *okBtn = (UIButton*)[self.view viewWithTag:24];
    okBtn.hidden = NO;
}

//
- (void)timeOut:(NSTimer *)timer{
    if(self.bleDefault.isBLEConnected){
        if(reSendCount < 5){
            reSendCount ++;
            NSLog(@"re send");
            //[self sendData:action ifReSend:NO];

        }
    }
}

//
- (void)showMsg:(NSString *)msg{
    UIAlertView *msgView = [[UIAlertView alloc]initWithTitle:@"Waring" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [msgView show];
}

//
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:YES];
}


#pragma mark - UITableView代理

//section
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

//row
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.blesListArr.count;
}

//
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    BLETabCell *tabCell = [tableView dequeueReusableCellWithIdentifier:@"BLETabCell" forIndexPath:indexPath];
    BLEModel *model = self.blesListArr[indexPath.row];
    tabCell.nameLabel.text = model.name;
    tabCell.addrLabel.text = model.macAddr;
    tabCell.signalLabel.text = [NSString stringWithFormat:@"%lddb",model.signal];
//    [self loadImage:model.fConnect?@"btn_ble_on":@"btn_ble_off" imageView:tabCell.connectImage];
    /*
    //求出信号强度比例，-5~-90
    CGFloat radio = 0;
    if(model.signal*(-1) < 5){
        radio = 0.1;
    }else if(model.signal*(-1) > 90){
        radio = 1;
    }else {
        radio = (model.signal*(-1)-5.0)/(90.0-5.0);
    }
    radio = 0.1;
    //NSLog(@"%@, width:%.1f",tabCell.contentView,tabCell.contentView.bounds.size.width*2/3.0*radio);
    tabCell.signalWidthRadio.constant = 0.1*2/3.0;//radio*2/3.0;      //设置完后没法刷新
//    CGRect imageFrame = tabCell.signalImage.frame;
//    tabCell.signalImage.frame = CGRectMake(imageFrame.origin.x, imageFrame.origin.y, tabCell.contentView.bounds.size.width*2/3.0*radio, imageFrame.size.height);
    //[tabCell.signalImage layoutIfNeeded];
    //[tabCell.contentView layoutSubviews];
     */
        return tabCell;
}

//cell height
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}


//选中某一行，是否显示高亮
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return YES;
}

//选中某一行
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.bleDefault.isHandleDisconnect = YES;
    //选中某个设备时，开始连接
    BLEModel *model = self.blesListArr[indexPath.row];
    [self.bleDefault connectWithBLEUUID:model.macAddr];
    //隐藏tabbleview
    self.devicesTabView.hidden = YES;
    self.bleBtn.selected = !self.bleBtn.selected;
    self.bleName.text = @"CONNECTING...";
}

- (void)loadImage:(NSString *)imageName imageView:(UIImageView *)imageView{
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:imageName ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:resourcePath];
    imageView.image = image;
}

#pragma mark - CTBLEManager代理

//蓝牙状态改变
- (void)bleStateChanged:(CBManagerState)state{
    switch (state) {
        case CBManagerStatePoweredOn:{
            
        }break;
            
        default: {
         //   self.bleBtn.selected = NO;
            self.disconectBtn.selected = NO;
        }break;
    }
}


//搜索到新BLE设备时，返回BLE模组名称
-(void)didDiscoverPeripheral:(CBPeripheral *)peripheral RSSI:(NSNumber *)RSSI{
    NSLog(@"搜索到BLE: %@, UUID:%@",peripheral.name, peripheral.identifier.UUIDString);
    if(peripheral.name == nil){
        
        return ;
    }
    BLEModel *model = [BLEModel new];
    model.macAddr = peripheral.identifier.UUIDString;
    model.name = peripheral.name;
    model.bleName = peripheral.name;
    //该UUID是否有重命名过，有则使用新名称
    [model renameInHistoryBLEs:self.historyBLENameArr];
    model.signal = [RSSI integerValue];
    model.fConnect = NO;
    [self.blesListArr addObject:model];
    [self.devicesTabView reloadData];
    if((!self.bleDefault.isHandleDisconnect)&&(self.bleDefault.selPeripheral != nil)&&(!self.bleDefault.isBLEConnected))
    {
        if([self.bleDefault.selPeripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString])
            [self.bleDefault connectWithBLEUUID:self.bleDefault.selPeripheral.identifier.UUIDString];
    }
}

//
- (void)didConnectedPeripheral:(CBPeripheral *)peripheral{
    //已连上BLE
    NSLog(@"已连接");
   // self.bleBtn.selected = YES;
    //停止扫描
    [self.bleDefault stopScan];
    NSString *displayName = nil;
    if(!self.bleDefault.isHandleDisconnect)
    {
        displayName = self.bleDefault.selPeripheral.name;
    }
    for(BLEModel *model in self.blesListArr){
        if([model.macAddr isEqualToString:peripheral.identifier.UUIDString]){
            model.fConnect = YES;
            displayName = model.name;
        }else{
            model.fConnect = NO;
        }
    }
    self.disconectBtn.selected = YES;
    [self.disconectBtn setUserInteractionEnabled:YES];
    //显示连接的名称
    self.bleName.userInteractionEnabled = YES;
    self.bleName.text = [NSString stringWithFormat:@"%@",displayName];
    self.bleDefault.isHandleDisconnect = NO;
    self.devicesTabView.hidden = YES;
}

//
- (void)disConnectedPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"连接已断开");
   // self.bleBtn.selected = NO;
    self.bleName.text = @"DISCONNECT";
    self.bleName.userInteractionEnabled = NO;
    for(BLEModel *model in self.blesListArr){
        if([model.bleName isEqualToString:peripheral.name]){
            model.fConnect = NO;
        }
    }
    self.disconectBtn.selected = NO;
    [self.disconectBtn setUserInteractionEnabled:NO];
    //断开时将灯都熄灭
    for(NSInteger i=30; i<33; i++){
        [self loadImage:0xf0 withStatus:0 tag:i];
    }
    //清按键状态，因断开连接后，按键即失效
    sendKeyStatus = 0;
    if((!self.bleDefault.isHandleDisconnect)&&(self.bleDefault.selPeripheral != nil)&&(!self.bleDefault.isBLEConnected))
    {
        [self.bleDefault startScan];
        [self.blesListArr removeAllObjects];
    }
}

//
- (void)connectTimeOut:(NSString *)bleName{
    //
    NSLog(@"连接超时");
   // self.bleBtn.selected = NO;
    self.bleName.text = @"CONNECT TIMEOUT";
    self.bleName.userInteractionEnabled = NO;
    
}

//发送完成
- (void)didSendDataForCharacter:(CBCharacteristic *)characteristic{
    
}

//接收到数据
- (void)didReceiveDataForCharacter:(CBCharacteristic *)characteristic{
    
    NSLog(@"character:%@: %@",characteristic.UUID.UUIDString,characteristic.value);
    Byte *dataBytes = (Byte *)[characteristic.value bytes];
    //数据解析
    Byte checksum   = 0;
    for(NSInteger i = 0; i<3; i++){
        checksum ^= dataBytes[i];
    }
    if(dataBytes[0] != 0xb1 || dataBytes[3] != checksum){
        NSLog(@"命令码错误或校验失败");
        return;
    }
    Byte keyStatus = dataBytes[1];
    //第一个灯
    [self loadImage:0b00000001 withStatus:keyStatus tag:30];
    //第二个灯
    [self loadImage:0b00000010 withStatus:keyStatus tag:31];
    //第三个灯
    [self loadImage:0b00000100 withStatus:keyStatus tag:32];
}

//
- (void)loadImage:(Byte)bitMap withStatus:(Byte)keyStatus tag:(NSInteger)tag{
    NSString *nameStr = nil;
    //第n个灯
    if((keyStatus&bitMap) == bitMap){
        //点亮
        nameStr = @"lamp_on";
    }else{
        //熄灭
        nameStr = @"lamp_off";
    }
    [self loadImage:nameStr imageView:(UIImageView*)[self.view viewWithTag:tag]];
}

//发送数据
- (void)sendData:(Byte)keyStatus ifReSend:(BOOL)reSend{
    Byte length = 4;
    Byte sendData[length+2];
    sendData[0] = 0xb0;
    sendData[1] = keyStatus;
    sendData[2] = serialNumber++;
    sendData[3] = sendData[0] ^ sendData[1] ^ sendData[2];
    [self.bleDefault sendWithBytes:sendData length:4 forCharacter:self.writeCharacteristic];
    NSLog(@"KeyStatus:%xH",keyStatus);
    if(reSend){
        reSendCount = 0;
        //开启定时发送
        [_timer setFireDate:[NSDate distantPast]];
    }
    
    
    /*
    //数据解析
    Byte checksum   = 0;
    for(NSInteger i = 0; i<3; i++){
        checksum ^= sendData[i];
    }
    if(sendData[0] != 0xb0 || sendData[3] != checksum){
        NSLog(@"命令码错误或校验失败");
        return;
    }
    Byte keyStatus1 = sendData[1];
    //第一个灯
    [self loadImage:0b00000001 withStatus:keyStatus1 tag:30];
    //第二个灯
    [self loadImage:0b00000010 withStatus:keyStatus1 tag:31];
    //第三个灯
    [self loadImage:0b00000100 withStatus:keyStatus1 tag:32];
    */
    
}

//发现特征
- (void)didDiscoverCharacterForService:(CBService *)service{
    if([service.UUID.UUIDString isEqualToString:UUID_SERVICE]){
        //遍历查询 写 特征
        for(CBCharacteristic *characteristic in service.characteristics){
            NSLog(@"Discovered characteristics:%@ for service:%@",characteristic.UUID, service.UUID);
            if ([characteristic.UUID.UUIDString isEqualToString:UUID_WRITE_CHARACTER]) {
                //保存写的特征
                self.writeCharacteristic = characteristic;
                fFindWriteCharacter = YES;
            }
            if ([characteristic.UUID.UUIDString isEqualToString:UUID_READ_CHARACTER]) {
                //保存读的特征
                self.readCharacteristic = characteristic;
                [self.bleDefault readMonitorFor:characteristic];
                fFindReadCharacter = YES;
            }
        }
    }
    if(fFindWriteCharacter && fFindReadCharacter){
        //找到设备后，发送一次状态
        [self sendData:sendKeyStatus ifReSend:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/



@end
