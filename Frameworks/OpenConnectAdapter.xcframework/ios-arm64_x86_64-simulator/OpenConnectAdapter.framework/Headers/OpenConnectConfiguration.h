//
//  OpenConnectConfiguration.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface OpenConnectConfiguration : NSObject

@property (nonatomic, nullable) NSString *server;

@property (nonatomic, nullable) NSDictionary<NSString *, NSString *> *settings;

@property (nonatomic, assign) NSInteger sslDebugLevel;

@end


NS_ASSUME_NONNULL_END
