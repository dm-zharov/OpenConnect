//
//  OpenConnectAdapter.h
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import "OpenConnectAdapterDelegate.h"


@class OpenConnectConfiguration;


NS_ASSUME_NONNULL_BEGIN


@interface OpenConnectAdapter : NSObject

@property (nonatomic, nullable, weak) id <OpenConnectAdapterDelegate> delegate;

- (void)connect;
- (void)disconnect;

- (void)applyConfiguration:(OpenConnectConfiguration *)configuration
					 error:(out NSError * __nullable * __nullable)error NS_SWIFT_NAME(apply(configuration:error:));

@end


NS_ASSUME_NONNULL_END
