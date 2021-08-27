//
//  OpenConnectTunnelSettings.m
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import "OpenConnectTunnelSettings.h"


@implementation OpenConnectTunnelSettings

- (instancetype)init {
	self = [super init];
	if (self) {
		_initialized = NO;
		
		_localAddresses = [NSMutableArray new];
		_prefixLengths = [NSMutableArray new];
		
		_includedRoutes = [NSMutableArray new];
		_excludedRoutes = [NSMutableArray new];
		
		_dnsAddresses = [NSMutableArray new];
	}
	return self;
}

@end
