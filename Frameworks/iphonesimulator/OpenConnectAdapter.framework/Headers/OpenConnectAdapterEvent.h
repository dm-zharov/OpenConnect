//
//  OpenConnectAdapterEvent.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <Foundation/Foundation.h>

/**
 Коды событий OpenConnect
 */
typedef NS_ENUM(NSInteger, OpenConnectAdapterEvent) {
	OpenConnectAdapterEventDisconnected,
	OpenConnectAdapterEventConnected,
	OpenConnectAdapterEventReconnecting,
	OpenConnectAdapterEventResolve,
	OpenConnectAdapterEventWait,
	OpenConnectAdapterEventWaitProxy,
	OpenConnectAdapterEventConnecting,
	OpenConnectAdapterEventGetConfig,
	OpenConnectAdapterEventAssignIP,
	OpenConnectAdapterEventAddRoutes,
	OpenConnectAdapterEventEcho,
	OpenConnectAdapterEventInfo,
	OpenConnectAdapterEventPause,
	OpenConnectAdapterEventResume,
	OpenConnectAdapterEventRelay,
	OpenConnectAdapterEventUnknown
};
