//
//  ViewController.m
//  IAPTest
//
//  Created by Chuanxun on 15/12/18.
//  Copyright © 2015年 Chuanxun. All rights reserved.
//

#import "ViewController.h"
#import <StoreKit/StoreKit.h>
#import <CommonCrypto/CommonCrypto.h>

#define PRODUCT_VIP             @"com.shipxy.leon.vip2"
#define PRODUCT_NO_AUTO_RENEW   @"com.shipxy.leon.noautorenew"

@interface ViewController () <SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property (weak, nonatomic) IBOutlet UITextField *userNameField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    [self validReceipt];
}
- (IBAction)vip:(id)sender {
    if ([SKPaymentQueue canMakePayments]) {
        SKProductsRequest *req = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:PRODUCT_NO_AUTO_RENEW]];
        req.delegate = self;
        
        [req start];
    }
}

-(void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"--------------收到产品反馈消息---------------------");
    NSArray *product = response.products;
    if([product count] == 0){
        NSLog(@"--------------没有商品------------------");
        return;
    }
    
    NSLog(@"InvalidProductID:%@", response.invalidProductIdentifiers);
    NSLog(@"产品购买数量:%zd",[product count]);
    
    SKProduct *p = nil;
    for (SKProduct *pro in product) {
//        NSLog(@"%@", [pro description]);
//        NSLog(@"%@", [pro localizedTitle]);
//        NSLog(@"%@", [pro localizedDescription]);
//        NSLog(@"%@", [pro price]);
//        NSLog(@"%@", [pro productIdentifier]);
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        [numberFormatter setLocale:pro.priceLocale];
        NSString *formattedPrice = [numberFormatter stringFromNumber:pro.price];
        NSLog(@"%@:%@",pro.productIdentifier,formattedPrice);
        if([pro.productIdentifier isEqualToString:PRODUCT_NO_AUTO_RENEW]){
            p = pro;
            NSLog(@"找到PRODUCT");
        }
    }
    
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:p];
    payment.quantity = 1;
    if (self.userNameField.text.length > 0) {
        payment.applicationUsername = [self hashedValueForAccountName:self.userNameField.text];
    }
    NSLog(@"发送购买请求");
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

/*
 
 2016-03-02 15:38:43.712 IAPTest[310:82733] {
	"signature" = "AhQ0rZ9a3TD/vT//aUYagKUwwPx+2a/AImfSr/Kf2qzODCc7icGW8pbcAZ9cqj5UHKApgF0nYLxPUNk2MsShF20GYdxGNr5IB4iQb4Dc4Zaxo9F8s/6wuO9pyKeBGx/vlmuydRZq0EUy8SsaOG7+XHmVMVpGdpBWArVyilJVsNugAAADVzCCA1MwggI7oAMCAQICCBup4+PAhm/LMA0GCSqGSIb3DQEBBQUAMH8xCzAJBgNVBAYTAlVTMRMwEQYDVQQKDApBcHBsZSBJbmMuMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTEzMDEGA1UEAwwqQXBwbGUgaVR1bmVzIFN0b3JlIENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTE0MDYwNzAwMDIyMVoXDTE2MDUxODE4MzEzMFowZDEjMCEGA1UEAwwaUHVyY2hhc2VSZWNlaXB0Q2VydGlmaWNhdGUxGzAZBgNVBAsMEkFwcGxlIGlUdW5lcyBTdG9yZTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAMmTEuLgjimLwRJxy1oEf0esUNDVEIe6wDsnnal14hNBt1v195X6n93YO7gi3orPSux9D554SkMp+Sayg84lTc362UtmYLpWnb34nqyGx9KBVTy5OGV4ljE1OwC+oTnRM+QLRCmeNxMbPZhS47T+eZtDEhVB9usk3+JM2Cogfwo7AgMBAAGjcjBwMB0GA1UdDgQWBBSJaEeNuq9Df6ZfN68Fe+I2u22ssDAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFDYd6OKdgtIBGLUyaw7XQwuRWEM6MA4GA1UdDwEB/wQEAwIHgDAQBgoqhkiG92NkBgUBBAIFADANBgkqhkiG9w0BAQUFAAOCAQEAeaJV2U51rxfcqAAe5C2/fEW8KUl4iO4lMuta7N6XzP1pZIz1NkkCtIIweyNj5URYHK+HjRKSU9RLguNl0nkfxqObiMckwRudKSq69NInrZyCD66R4K77nb9lMTABSSYlsKt8oNtlhgR/1kjSSRQcHktsDcSiQGKMdkSlp4AyXf7vnHPBe4yCwYV2PpSN04kboiJ3pBlxsGwV/ZlL26M2ueYHKYCuXhdqFwxVgm52h3oeJOOt/vY4EcQq7eqHm6m03Z9b7PRzYM2KGXHDmOMk7vDpeMVlLDPSGYz1+U3sDxJzebSpbaJmT7imzUKfggEY7xxf4czfH0yj5wNzSGTOvQ==";
	"purchase-info" = "ewoJIm9yaWdpbmFsLXB1cmNoYXNlLWRhdGUtcHN0IiA9ICIyMDE2LTAzLTAxIDIzOjM4OjQzIEFtZXJpY2EvTG9zX0FuZ2VsZXMiOwoJInVuaXF1ZS1pZGVudGlmaWVyIiA9ICI3MWQ1MGZkMDYxMTE4ZDZkZDZiM2UzNjlkOWVjZmZkODI5MzgwMWUyIjsKCSJvcmlnaW5hbC10cmFuc2FjdGlvbi1pZCIgPSAiMTAwMDAwMDE5NzAwNDk3MSI7CgkiYnZycyIgPSAiMSI7CgkidHJhbnNhY3Rpb24taWQiID0gIjEwMDAwMDAxOTcwMDQ5NzEiOwoJInF1YW50aXR5IiA9ICIxIjsKCSJvcmlnaW5hbC1wdXJjaGFzZS1kYXRlLW1zIiA9ICIxNDU2OTA0MzIzNDAyIjsKCSJ1bmlxdWUtdmVuZG9yLWlkZW50aWZpZXIiID0gIjBGNTNDMzlCLTAxRDQtNEUxRi05NDM4LTg4NzZFRUM5Q0U5NiI7CgkicHJvZHVjdC1pZCIgPSAiY29tLnNoaXB4eS5sZW9uLm5vYXV0b3JlbmV3MSI7CgkiaXRlbS1pZCIgPSAiMTA4OTQ1NDgxNCI7CgkiYmlkIiA9ICJjb20uc2hpcHh5LmluQXBwUHVyY2hhc2VzVGVzdCI7CgkicHVyY2hhc2UtZGF0ZS1tcyIgPSAiMTQ1NjkwNDMyMzQwMiI7CgkicHVyY2hhc2UtZGF0ZSIgPSAiMjAxNi0wMy0wMiAwNzozODo0MyBFdGMvR01UIjsKCSJwdXJjaGFzZS1kYXRlLXBzdCIgPSAiMjAxNi0wMy0wMSAyMzozODo0MyBBbWVyaWNhL0xvc19BbmdlbGVzIjsKCSJvcmlnaW5hbC1wdXJjaGFzZS1kYXRlIiA9ICIyMDE2LTAzLTAyIDA3OjM4OjQzIEV0Yy9HTVQiOwp9";
	"environment" = "Sandbox";
	"pod" = "100";
	"signing-status" = "0";
 }
 
 */
-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    NSString *receipt;
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                receipt = [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
                NSLog(@"%@",receipt);
                NSLog(@"SKPaymentTransactionStatePurchased");
                NSLog(@"transationDate=%@",transaction.transactionDate);
                [self validReceipt];
                break;
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"SKPaymentTransactionStateFailed");
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                receipt = [[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding];
                //NSLog(@"%@",receipt);
                NSLog(@"%@ %@ SKPaymentTransactionStateRestored",transaction.payment.productIdentifier,transaction.payment.applicationUsername);
                //[self validReceipt];
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"SKPaymentTransactionStateDeferred");
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"SKPaymentTransactionStatePurchasing");
                break;
            default:
                break;
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"restoreCompletedTransactionsFailedWithError %@",error.description);
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
}

/*
 产品类型
 
 消耗型产品：不能restore (通过restoreCompletedTransactions方法)
 非消耗型产品：系统帮你restore（在同一个appID的所有设备上，该产品可用）restoreCompletedTransactions
 自动续订订阅产品：系统帮你restore(restoreCompletedTransactions)
 非自动续订订阅产品：系统不帮你restore(restoreCompletedTransactions)，由app自己实现restore
 免费订阅：
 
 
 */


//没一个payment会产生一个相应的transaction

//如果一个transaction没有被设置为finished，那么程序每次启动，都会调用观察者的updatedTransactions方法



/*
 交付产品：
 持久化产品
 
 当购买完商品之后，你的app需要持久化存储商品信息。你的app可以在程序启动时，使用这个记录来使商品可用。也可以用这个记录来restore purchases。你的持久化策略依赖与产品类型和ios版本：
    1、对于ios 7之后的非消耗型产品和自动续订产品，使用｀app receipt｀作为记录
    2、对于ios 7之前的非消耗型产品和自动续订产品，使用偏好设置和iCloud去保存记录
    3、对于非自动续订产品，使用iCloud或者你们的服务器去保存记录
    4、对于消耗型产品，你的app更新自身内部状态来交付商品，没有必要去持久化，因为消耗型产品不能被restored和synced across devices。
 
 
 */

/*
 
 当使用偏好设置去保存记录时，你可以保存一个bool值，也可以保存一份receipt的副本。
 //保存记录
 NSData *newReceipt = transaction.transactionReceipt;
 NSArray *savedReceipts = [storage arrayForKey:@"receipts"];
 if (!savedReceipts) {
 // Storing the first receipt
 [storage setObject:@[newReceipt] forKey:@"receipts"];
 } else {
 // Adding another receipt
 NSArray *updatedReceipts = [savedReceipts arrayByAddingObject:newReceipt];
 [storage setObject:updatedReceipts forKey:@"receipts"];
 }
 
 [storage synchronize];
 
 //查询
 NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
 NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
 
 // Custom method to work with receipts
 BOOL rocketCarEnabled = [self receipt:receiptData
 includesProductID:@"com.example.rocketCar"];
 
 */


/*
对于已经购买的商品，用户可以申请回退。
 你可以验证receipt中的｀Cancellation Date field ｀，如果有值，说明用户已经回退商品。
 
 */

/*
 测试环境sandbox，一个产品，一天可以重新订阅6次。
 并且订阅周期会压缩，1周压缩为3分钟
 
 */

- (IBAction)restore:(id)sender {
    /*
    每次都创建一个新的transaction，并且会调用updatedTransactions方法
    
    新的transaction中包含一个originalTransaction对象，新的receipt中包含一个originalTransactionIdentifier字段
     
     如果只payment中设置了applicationUsername，那么请使用restoreCompletedTransactionsWithApplicationUsername: 方法
     
     
     */
    if (self.userNameField.text.length > 0)
    {
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:[self hashedValueForAccountName:self.userNameField.text]];
    }else {
        
        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }
}


// Custom method to calculate the SHA-256 hash using Common Crypto
- (NSString *)hashedValueForAccountName:(NSString*)userAccountName
{
    const int HASH_SIZE = 32;
    unsigned char hashedChars[HASH_SIZE];
    const char *accountName = [userAccountName UTF8String];
    size_t accountNameLen = strlen(accountName);
    
    // Confirm that the length of the user name is small enough
    // to be recast when calling the hash function.
    if (accountNameLen > UINT32_MAX) {
        NSLog(@"Account name too long to hash: %@", userAccountName);
        return nil;
    }
    CC_SHA256(accountName, (CC_LONG)accountNameLen, hashedChars);
    
    // Convert the array of bytes into a string showing its hex representation.
    NSMutableString *userAccountHash = [[NSMutableString alloc] init];
    for (int i = 0; i < HASH_SIZE; i++) {
        // Add a dash every four bytes, for readability.
        if (i != 0 && i%4 == 0) {
            [userAccountHash appendString:@"-"];
        }
        [userAccountHash appendFormat:@"%02x", hashedChars[i]];
    }
    
    return userAccountHash;
}

- (IBAction)refreshReceipt
{
    SKReceiptRefreshRequest *request = [[SKReceiptRefreshRequest alloc] init];
    request.delegate = self;
    [request start];
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}


- (void)validReceipt{
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];//每个AppleID都对应一个Receipt
    
    if (receiptData) {
        
        NSError *error;
        NSDictionary *requestDict = @{@"receipt-data":[receiptData base64EncodedStringWithOptions:0],
                                      @"password":@"830ea51d44784470a97b8e0cd5b32b7f"};
        NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&error];
        
        if (!requestData) {
            NSLog(@"no data");
            return;
        }
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        
        //https://buy.itunes.apple.com/verifyReceipt
        NSURL *storeURL = [NSURL URLWithString:@"https://sandbox.itunes.apple.com/verifyReceipt"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:storeURL];
        request.HTTPMethod = @"POST";
        request.HTTPBody = requestData;
        
        [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (!error) {
                NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
                //NSLog(@"%@",jsonResponse);
                int status = [[jsonResponse valueForKey:@"status"] intValue];
                if (status == 0) {
                    NSDictionary *receipt = [jsonResponse valueForKey:@"receipt"];
                    NSLog(@"receipt=%@",receipt);
                }else {
                    NSLog(@"status = %d",status);
                }
            }else {
                NSLog(@"receiptValidError:%@",error.description);
            }
        }] resume];
        
    }
    
}

@end
