//
//  OpenConnectCertificate.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface OpenConnectCertificate : NSObject

+ (nullable OpenConnectCertificate *)certificateWithDER:(nonnull NSData *)derData
                                              error:(out NSError * __nullable * __nullable)error;

- (nullable NSData *)pemData:(out NSError * __nullable * __nullable)error;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
