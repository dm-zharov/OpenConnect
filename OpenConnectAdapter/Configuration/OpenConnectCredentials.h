//
//  OpenConnectCredentials.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface OpenConnectCredentials : NSObject

/**
 Клиентский username
 */
@property (nonatomic, nullable) NSString *username;

/**
 Клиентский password
 */
@property (nonatomic, nullable) NSString *password;

@property (nonatomic, nullable) NSURL *certificateUrl;
@property (nonatomic, nullable) NSURL *privateKeyUrl;

@end


NS_ASSUME_NONNULL_END
