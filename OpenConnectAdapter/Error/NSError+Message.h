//
//  NSError+Message.h
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 07.05.2020.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (Message)

+ (NSString *)oc_reasonFromResult:(NSInteger)result;

@end

NS_ASSUME_NONNULL_END
