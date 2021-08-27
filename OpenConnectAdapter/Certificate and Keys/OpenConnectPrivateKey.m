//
//  OpenConnectPrivateKey.m
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#include <openssl/pem.h>
#include <openssl/err.h>

#import "NSError+Message.h"
#import "OpenConnectPrivateKey.h"
#import "OpenConnectError.h"


@interface OpenConnectPrivateKey ()

@property (nonatomic, assign) BIO *bio;
@property (nonatomic, assign) RSA *rsa;

@end


@implementation OpenConnectPrivateKey

+ (nullable OpenConnectPrivateKey *)keyWithDER:(NSData *)derData error:(out NSError **)error {
    OpenConnectPrivateKey *key = [OpenConnectPrivateKey new];
	const unsigned char *data = derData.bytes;
	EVP_PKEY *pkey = d2i_AutoPrivateKey(NULL, &data, derData.length);
    if (!pkey) {
        if (error) {
            NSString *reason = [NSError oc_reasonFromResult:ERR_get_error()];
            *error = [NSError errorWithDomain:OpenConnectIdentityErrorDomain code:ERR_get_error() userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to read DER data.",
                NSLocalizedFailureReasonErrorKey: reason
            }];
        }
        return nil;
    }
	
	key.rsa = EVP_PKEY_get1_RSA(pkey);
	EVP_PKEY_free(pkey);
	
    return key;
}

- (NSData *)pemData:(out NSError **)error {
	int keylen;
	char *pem_key;
	
	/* To get the C-string PEM form: */
	BIO *bio = BIO_new(BIO_s_mem());
	PEM_write_bio_RSAPrivateKey(bio, self.rsa, NULL, NULL, 0, NULL, NULL);
	
	keylen = BIO_pending(bio);
	pem_key = calloc(keylen+1, 1); /* Null-terminate */
	BIO_read(bio, pem_key, keylen);
	
	BIO_free_all(bio);
	NSData * data = [NSData dataWithBytes:pem_key length:keylen];
	free(pem_key);
	return data;
}

- (void)dealloc {
	BIO_free(_bio);
	RSA_free(_rsa);
}

@end
