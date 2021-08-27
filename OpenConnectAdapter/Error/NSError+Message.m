//
//  NSError+Message.m
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 07.05.2020.
//

#import "NSError+Message.h"


#import <openssl/err.h>


@implementation NSError (Message)

+ (NSString *)oc_reasonFromResult:(NSInteger)result {
    size_t length = 1024;
    char *buffer = malloc(length);
    
    ERR_error_string_n(result, buffer, length);
    
    NSString *reason = [NSString stringWithUTF8String:buffer];
    
    free(buffer);
    
    return reason;
}

@end
