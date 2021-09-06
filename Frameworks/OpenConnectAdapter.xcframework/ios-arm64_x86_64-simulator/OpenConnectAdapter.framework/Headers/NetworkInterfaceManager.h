//
//  NetworkInterfaceManager.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


extern NSString * const NetworkInterfaceManagerInterfaceDidChange;


@interface NetworkInterfaceManager : NSObject

@property (nonatomic, readonly) BOOL WWANValid;
@property (nonatomic, readonly) BOOL WiFiValid;

- (void)updateInterfaceInfo;
- (void)monitorInterfaceChange;

@property (nonatomic, readonly) BOOL monitoring;

+ (instancetype)sharedInstance;

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end


NS_ASSUME_NONNULL_END
