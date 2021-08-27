//
//  OpenConnectPacketFlow.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 07.05.2020.
//

#import "OpenConnectAdapterEvent.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OpenConnectAdapterPacketFlow <NSObject>

- (void)readPacketsWithCompletionHandler:(void (^)(NSArray<NSData *> *_Nonnull packets, NSArray<NSNumber *> *_Nonnull protocols))completionHandler;
- (BOOL)writePackets:(NSArray<NSData *> *)packets withProtocols:(NSArray<NSNumber *> *)protocols;

@end

NS_ASSUME_NONNULL_END
