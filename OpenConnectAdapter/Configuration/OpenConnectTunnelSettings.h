//
//  OpenConnectTunnelSettings.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface OpenConnectTunnelSettings : NSObject

@property (nonatomic) BOOL initialized;

@property (nonatomic, strong, readonly) NSMutableArray *localAddresses;
@property (nonatomic, strong, readonly) NSMutableArray *prefixLengths;

@property (nonatomic, strong, readonly) NSMutableArray *includedRoutes;
@property (nonatomic, strong, readonly) NSMutableArray *excludedRoutes;

@property (nonatomic, strong, readonly) NSMutableArray *dnsAddresses;

@end


NS_ASSUME_NONNULL_END
