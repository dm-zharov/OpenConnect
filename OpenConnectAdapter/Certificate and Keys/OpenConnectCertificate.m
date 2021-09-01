//
//  OpenConnectCertificate.m
//  OpenConnect Adapter
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import <openssl/pkcs12.h>
#import <openssl/pem.h>
#import <openssl/x509.h>
#import <openssl/err.h>
#import <openssl/bio.h>

#import "NSError+Message.h"
#import "OpenConnectError.h"
#import "OpenConnectCertificate.h"


@interface OpenConnectCertificate ()

@property (nonatomic, assign) X509 *crt;
@property (nonatomic, assign) BIO *bio;

@end


@implementation OpenConnectCertificate

- (instancetype)init {
    self = [super init];
    if (self) {
		_bio = BIO_new(BIO_s_mem());
    }
    return self;
}

+ (OpenConnectCertificate *)certificateWithDER:(NSData *)derData error:(out NSError **)error {
    OpenConnectCertificate *certificate = [OpenConnectCertificate new];
	const unsigned char *data = derData.bytes;
    certificate.crt = d2i_X509(NULL, &data, derData.length);
    if (!certificate.crt) {
        if (error) {
            NSString *reason = [NSError oc_reasonFromResult:ERR_get_error()];
            *error = [NSError errorWithDomain:OpenConnectIdentityErrorDomain code:ERR_get_error() userInfo:@{
                NSLocalizedDescriptionKey: @"Failed to read DER data.",
                NSLocalizedFailureReasonErrorKey: reason
            }];
        }
		
        return nil;
    }
    
    return certificate;
}

- (NSData *)pemData:(out NSError **)error {
	BIO *bio = BIO_new(BIO_s_mem());
	if (!bio) {
		
	}
	
	if (!PEM_write_bio_X509(bio, self.crt)) {
		BIO_free(bio);
		
	}
	
	char *pem = NULL;
	pem = (char *) malloc(bio->num_write);
	if (NULL == pem) {
		BIO_free(bio);
		return NULL;
	}
	
	memset(pem, 0, bio->num_write);
	BIO_read(bio, pem, (int) bio->num_write);
	
	NSData *pemData = [[NSData alloc] initWithBytes:pem length:bio->num_write];
	free(pem);
    BIO_free(bio);
	if (!pemData) {
		if (error) {
			NSString *reason = [NSError oc_reasonFromResult:ERR_get_error()];
			*error = [NSError errorWithDomain:OpenConnectIdentityErrorDomain code:ERR_get_error() userInfo:@{
				NSLocalizedDescriptionKey: @"Failed to write PEM data.",
				NSLocalizedFailureReasonErrorKey: reason
			}];
		}
		
		return nil;
	}
    return pemData;
}

- (void)dealloc {
    BIO_free(_bio);
	X509_free(_crt);
}

@end
