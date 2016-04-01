//
//  TankAddressBookInfo.m
//  Zebra
//
//  Created by yanwb on 15/12/28.
//  Copyright © 2015年 JINMARONG. All rights reserved.
//

#import "TankAddressBookInfo.h"

#import <AddressBook/AddressBook.h>
#import "EaseChineseToPinyin.h"
#import <Contacts/Contacts.h>

// 操作系统版本
#define IOS9_OR_LATER ([[[UIDevice currentDevice] systemVersion] compare:@"9.0"] != NSOrderedAscending)

@implementation TankAddressBookInfo


+(void)checkAddressBookAuthorization:(void (^)(bool))block
{
    if (IOS9_OR_LATER) {
        CNContactStore *contackStore = [[CNContactStore alloc] init];
        CNAuthorizationStatus authoreizationStatus = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        if (authoreizationStatus != CNAuthorizationStatusAuthorized) {
            
            [contackStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if (error) {
                    block(NO);
                } else if (!granted) {
                    block(NO);
                } else {
                    block(YES);
                }
            }];
        };
    } else {
        ABAddressBookRef  addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAuthorizationStatus authorizationStatus = ABAddressBookGetAuthorizationStatus();
        if (authorizationStatus != kABAuthorizationStatusAuthorized)
        {
            ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        block(NO);
                    } else if (!granted) {
                        block(NO);
                    } else {
                        block(YES);
                    }
                });
                
            });
        }
        
    }
    
    
}

+(NSArray *)featchPersonalAddressBook
{
    NSMutableArray *dataSource = [[NSMutableArray alloc] init];
    
    if (IOS9_OR_LATER) {
        
        CNContactStore *contactStore = [[CNContactStore alloc] init];
        CNContactStore * stroe = [[CNContactStore alloc]init];
        //检索条件，检索所有名字中有zhang的联系人
        NSPredicate * predicate = [CNContact predicateForContactsMatchingName:@""];
        //提取数据
        NSError *error;
        NSArray * contacts = [stroe unifiedContactsMatchingPredicate:nil keysToFetch:@[CNContactGivenNameKey,CNContactFamilyNameKey,CNContactPhoneNumbersKey,CNContactPostalAddressesKey] error:&error];
        if (error) {
            NSLog(@"获取失败");
        } else {
            NSLog(@"%@",contacts);
            
            for (int i = 0; i < contacts.count; i++) {
                //新建一个addressBook model类
                AddressBookPersonalInfo *addressBook = [[AddressBookPersonalInfo alloc] init];
                CNContact *contact = contacts[i];
                addressBook.name = [NSString stringWithFormat:@"%@%@",contact.givenName,contact.familyName];
                if (contact.phoneNumbers>0) {
                    NSMutableArray *phoneArray = [NSMutableArray array];
                    for (int j= 0; j<contact.phoneNumbers.count; j++) {
                        
                        [phoneArray addObject:[contact.phoneNumbers[j] value]];
                    }
                    addressBook.phoneArray = phoneArray;
                }
                // 地址 邮箱 等不在罗列
            }
        }
    } else {
        //新建一个通讯录类
        ABAddressBookRef addressBooks = nil;
        //判断是否在ios6.0版本以上
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0){
            addressBooks =  ABAddressBookCreateWithOptions(NULL, NULL);
            //获取通讯录权限
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            ABAddressBookRequestAccessWithCompletion(addressBooks, ^(bool granted, CFErrorRef error){dispatch_semaphore_signal(sema);});
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }else{
            CFErrorRef* error=nil;
            addressBooks = ABAddressBookCreateWithOptions(NULL, error);
        }
        
        //获取通讯录中的所有人
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBooks);
        //通讯录中人数
        CFIndex nPeople = ABAddressBookGetPersonCount(addressBooks);
        
        //循环，获取每个人的个人信息
        for (NSInteger i = 0; i < nPeople; i++)
        {
            //新建一个addressBook model类
            AddressBookPersonalInfo *addressBook = [[AddressBookPersonalInfo alloc] init];
            //获取个人
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
            //获取个人名字
            CFTypeRef abName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
            CFTypeRef abLastName = ABRecordCopyValue(person, kABPersonLastNameProperty);
            
            CFStringRef abFullName = ABRecordCopyCompositeName(person);
            NSString *nameString = (__bridge NSString *)abName;
            NSString *lastNameString = (__bridge NSString *)abLastName;
            
            //获取当前联系人头像图片
            addressBook.userImage=(__bridge NSData*)(ABPersonCopyImageData(person));
            ABMultiValueRef address = ABRecordCopyValue(person, kABPersonAddressProperty);
            NSDictionary *temDic = (__bridge NSDictionary *)(ABMultiValueCopyValueAtIndex(address, 0));
            NSString *addressStr = [NSString stringWithFormat:@"国家:%@\n省:%@\n市:%@\n街道:%@\n邮编:%@",[temDic valueForKey:(NSString*)kABPersonAddressCountryKey],[temDic valueForKey:(NSString*)kABPersonAddressStateKey],[temDic valueForKey:(NSString*)kABPersonAddressCityKey],[temDic valueForKey:(NSString*)kABPersonAddressStreetKey],[temDic valueForKey:(NSString*)kABPersonAddressZIPKey]];
            addressBook.address = addressStr;
            //        }
            
            if ((__bridge id)abFullName != nil) {
                nameString = (__bridge NSString *)abFullName;
            }else {
                if ((__bridge id)abLastName != nil){
                    nameString = [NSString stringWithFormat:@"%@ %@", nameString, lastNameString];
                }
            }
            addressBook.name = nameString;
            //        addressBook.recordID = (int)ABRecordGetRecordID(person);
            
            ABPropertyID multiProperties[] = {
                kABPersonPhoneProperty,
                kABPersonEmailProperty
            };
            NSInteger multiPropertiesTotal = sizeof(multiProperties) / sizeof(ABPropertyID);
            NSMutableArray *phoneArray = [NSMutableArray array];
            NSMutableArray *emailArray = [NSMutableArray array];
            for (NSInteger j = 0; j < multiPropertiesTotal; j++) {
                ABPropertyID property = multiProperties[j];
                ABMultiValueRef valuesRef = ABRecordCopyValue(person, property);
                NSInteger valuesCount = 0;
                if (valuesRef != nil) valuesCount = ABMultiValueGetCount(valuesRef);
                
                if (valuesCount == 0) {
                    CFRelease(valuesRef);
                    continue;
                }
                //获取电话号码和email
                for (NSInteger k = 0; k < valuesCount; k++) {
                    CFTypeRef value = ABMultiValueCopyValueAtIndex(valuesRef, k);
                    switch (j) {
                        case 0: {// Phone number
                            NSString  *tel = (__bridge NSString*)value;
                            [phoneArray addObject:tel];
                            break;
                        }
                        case 1: {// Email
                            NSString *email = (__bridge NSString*)value;
                            [emailArray addObject:email];
                            break;
                        }
                    }
                    CFRelease(value);
                }
                CFRelease(valuesRef);
            }
            addressBook.phoneArray = phoneArray;
            addressBook.emails = emailArray;
            //将个人信息添加到数组中，循环完成后addressBookTemp中包含所有联系人的信息
            [dataSource addObject:addressBook];
            
            if (abName) CFRelease(abName);
            if (abLastName) CFRelease(abLastName);
            if (abFullName) CFRelease(abFullName);
            
            
        }
    }
    return  dataSource;
}


+ (NSArray *)sortPersonalAddressBook
{
    
    NSArray *dataSource = [self featchPersonalAddressBook];
    NSMutableArray *userSource = [[NSMutableArray alloc] init];
    for (char i = 'A'; i<='Z'; i++)
    {
        NSMutableArray *numarr = [[NSMutableArray alloc] init];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        AddressBookPersonalInfo *personalInfo = [[AddressBookPersonalInfo alloc] init];
        for (int j=0; j<dataSource.count; j++)
        {
            AddressBookPersonalInfo *model = [dataSource objectAtIndex:j];
            //获取姓名首位
            NSString *string = [model.name substringWithRange:NSMakeRange(0, 1)];
            //将姓名首位转换成NSData类型
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            //data的长度大于等于3说明姓名首位是汉字
            if (data.length >=3)
            {
                //将汉字首字母拿出
                char a = pinyinFirstLet([model.name characterAtIndex:0]);
                
                //将小写字母转成大写字母
                char b = a-32;
                if (b == i)
                {
                    //                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    //                    [array addObject:model.name];
                    //                    if (model.phoneArray != nil)
                    //                    {
                    //                        [array addObjectsFromArray:model.phoneArray];
                    //                    }
                    //
                    //                    [numarr addObject:array];
                    [numarr addObject:model];
                    [dic setObject:numarr forKey:[NSNumber numberWithChar:i]];
                }
                
            }
            else
            {
                //data的长度等于1说明姓名首位是字母或者数字
                if (data.length == 1)
                {
                    //判断姓名首位是否位小写字母
                    NSString * regex = @"^[a-z]$";
                    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                    BOOL isMatch = [pred evaluateWithObject:string];
                    if (isMatch == YES)
                    {
                        //NSLog(@"这是小写字母");
                        
                        //把大写字母转换成小写字母
                        char j = i+32;
                        //数据封装成NSNumber类型
                        NSNumber *num = [NSNumber numberWithChar:j];
                        //给a开空间，并且强转成char类型
                        char *a = (char *)malloc(2);
                        //将num里面的数据取出放进a里面
                        sprintf(a, "%c", [num charValue]);
                        //把c的字符串转换成oc字符串类型
                        NSString *str = [[NSString alloc]initWithUTF8String:a];
                        if ([string isEqualToString:str])
                        {
                            //                            NSMutableArray *array = [[NSMutableArray alloc] init];
                            //                            [array addObject:model.name];
                            //                            if (model.phoneArray != nil)
                            //                            {
                            //                                [array addObjectsFromArray:model.phoneArray];
                            //                            }
                            //
                            //                            [numarr addObject:array];
                            [numarr addObject:model];
                            [dic setObject:numarr forKey:[NSNumber numberWithChar:i]];
                        }
                        
                    }
                    else
                    {
                        //判断姓名首位是否为大写字母
                        NSString * regexA = @"^[A-Z]$";
                        NSPredicate *predA = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexA];
                        BOOL isMatchA = [predA evaluateWithObject:string];
                        if (isMatchA == YES)
                        {
                            //NSLog(@"这是大写字母");
                            //
                            NSNumber *num = [NSNumber numberWithChar:i];
                            //给a开空间，并且强转成char类型
                            char *a = (char *)malloc(2);
                            //将num里面的数据取出放进a里面
                            sprintf(a, "%c", [num charValue]);
                            //把c的字符串转换成oc字符串类型
                            NSString *str = [[NSString alloc]initWithUTF8String:a];
                            if ([string isEqualToString:str])
                            {
                                
                                //                                NSMutableArray *array = [[NSMutableArray alloc] init];
                                //                                [array addObject:model.name];
                                //                                if (model.phoneArray != nil)
                                //                                {
                                //                                    [array addObjectsFromArray:model.phoneArray];
                                //                                }
                                //
                                //                                [numarr addObject:array];
                                [numarr addObject:model];
                                [dic setObject:numarr forKey:[NSNumber numberWithChar:i]];
                            }
                        }
                    }
                }
            }
        }
        if (dic.count != 0)
        {
            [userSource addObject:dic];
            //            [userSource addObject:personalInfo];
        }
    }
    
    char n = '#';
    int cont = 0;
    
    NSMutableDictionary *dic1;
    NSMutableArray *numarr1;
    for (int j=0; j<dataSource.count; j++)
    {
        AddressBookPersonalInfo *model = [dataSource objectAtIndex:j];
        //获取姓名的首位
        NSString *string = [model.name substringWithRange:NSMakeRange(0, 1)];
        //将姓名首位转化成NSData类型
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        //判断data的长度是否小于3
        if (data.length < 3)
        {
            if (cont == 0)
            {
                dic1 = [[NSMutableDictionary alloc] init];
                numarr1 = [[NSMutableArray alloc] init];
                cont++;
            }
            if (data.length == 1)
            {
                //判断首位是否为数字
                NSString * regexs = @"^[0-9]$";
                NSPredicate *preds = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regexs];
                BOOL isMatch = [preds evaluateWithObject:string];
                if (isMatch == YES)
                {
                    //如果姓名为数字
                    //                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    //                    [array addObject:model.name];
                    //                    if (model.phoneArray != nil)
                    //                    {
                    //                        [array addObjectsFromArray:model.phoneArray];
                    //                    }
                    //
                    //                    [numarr1 addObject:array];
                    [numarr1 addObject:model];
                    [dic1 setObject:numarr1 forKey:[NSNumber numberWithChar:n]];
                }
            }
            else
            {
                //如果姓名为空
                NSMutableArray *array = [[NSMutableArray alloc] init];
                model.name = @"无";
                [array addObject:model.name];
                if (model.phoneArray != nil)
                {
                    //                    [array addObjectsFromArray:model.phoneArray];
                    //                    [numarr1 addObject:array];
                    [numarr1 addObject:model];
                    [dic1 setObject:numarr1 forKey:[NSNumber numberWithChar:n]];
                }
            }
        }
    }
    
    if (dic1.count != 0)
    {
        [userSource addObject:dic1];
    }
    return userSource;
}
@end
