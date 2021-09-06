//
//  OpenConnectPrivateKey.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface OpenConnectPrivateKey : NSObject

+ (nullable OpenConnectPrivateKey *)keyWithDER:(NSData *)derData
										 error:(out NSError * __nullable * __nullable)error;

@property (nonatomic, readonly) NSInteger size;

- (nullable NSData *)pemData:(out NSError * __nullable * __nullable)error;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
