//
//  OpenConnectDelegate.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 07.05.2020.
//

#import "OpenConnectAdapterPacketFlow.h"


@class NEPacketTunnelNetworkSettings;


NS_ASSUME_NONNULL_BEGIN

@protocol OpenConnectAdapterDelegate <NSObject>

- (void)configureTunnelWithSettings:(NEPacketTunnelNetworkSettings *)settings
						   callback:(void (^)(id<OpenConnectAdapterPacketFlow> _Nullable flow))callback NS_SWIFT_NAME(configureTunnel(settings:callback:));

- (void)handleEvent:(OpenConnectAdapterEvent)event
			message:(nullable NSString *)message
NS_SWIFT_NAME(handle(event:message:));

- (void)handleError:(NSError *)error NS_SWIFT_NAME(handle(error:));
 
 @optional

/**
 Используйте данный метод делегата для логгирования всех событий подключения.
 */
- (void)handleLog:(NSString *)logMessage NS_SWIFT_NAME(handle(logMessage:));
- (void)tick;

@end

NS_ASSUME_NONNULL_END
