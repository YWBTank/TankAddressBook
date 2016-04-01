//
//  AddressBookPersonalInfo.h
//  Zebra
//
//  Created by yanwb on 15/12/28.
//  Copyright © 2015年 JINMARONG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddressBookPersonalInfo : NSObject
//@property (nonatomic, copy) NSString *firstName; //名
//@property (nonatomic, copy) NSString *lastName; //姓
//@property (nonatomic, copy) NSString *middleName;//中间名
//@property (nonatomic, copy) NSString *prefix; //名字前缀
//@property (nonatomic, copy) NSString *suffix;// 名字后缀
//@property (nonatomic, copy) NSString *nickName;//当前联系人得昵称
//@property (nonatomic, copy) NSString *firstNamePhoneic;//当前联系人得名字拼音
//@property (nonatomic, copy) NSString *lastNamePhoneic;//姓氏拼音
//@property (nonatomic, copy) NSString *middleNamePhoneic;//中间名拼音
//@property (nonatomic, copy) NSString *organization;//联系人公司
//@property (nonatomic, copy) NSString *job;//联系人职务
//@property (nonatomic, copy) NSString *department;//联系人的部门
//@property (nonatomic, copy) NSString *birthday;//联系人生日
@property (nonatomic, strong) NSArray *emails;//联系人邮箱
//@property (nonatomic, copy) NSString *notes;//联系人备注
@property (nonatomic, strong) NSArray *phoneArray;//联系电话
@property (nonatomic, copy) NSString *address;//联系人地址
@property (nonatomic, strong) NSData *userImage;//联系人头像
@property (nonatomic, copy) NSString *name;
@end
