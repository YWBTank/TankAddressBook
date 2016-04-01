//
//  TankAddressBookInfo.h
//  Zebra
//
//  Created by yanwb on 15/12/28.
//  Copyright © 2015年 JINMARONG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AddressBookPersonalInfo.h"

@interface TankAddressBookInfo : NSObject

// 判断用户是否开启授权
+ (void)checkAddressBookAuthorization:(void (^)(bool isAuthorized))block;

//获取通讯录
+(NSArray *)featchPersonalAddressBook;

// 排列后的通讯录
+(NSMutableArray *)sortPersonalAddressBook;
@end
