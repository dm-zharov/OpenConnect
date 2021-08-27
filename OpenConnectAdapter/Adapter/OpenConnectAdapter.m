//
//  OpenConnectAdapter.m
//
//  Created by Dmitriy Zharov on 06.05.2020.
//

#import "OpenConnectAdapter.h"
#import "OpenConnectAdapterDelegate.h"
#import "OpenConnectAdapterPacketFlow.h"
#import "NetworkInterfaceManager.h"
#import "OpenConnectConfiguration.h"

#import <NetworkExtension/NetworkExtension.h>

#include <netinet/ip.h>

#import <OpenConnect/openconnect-internal.h>
#import "OpenConnectError.h"


static OpenConnectAdapter *staticSelf; /**< Используется для повышения производительности при обработке низкоуровневых пакетов. */

static NSMutableArray <NSData *> *_packetsCache;
static NSMutableArray <NSNumber *> *_protocolsCache;
static dispatch_semaphore_t s;


@interface OpenConnectAdapter ()

@property (nonatomic, strong) NSMutableArray<NSData *> *packetsOutCache;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *protocolsOutCache;

@property (nonatomic, nullable, weak) id <OpenConnectAdapterPacketFlow> packetFlow;

@end


@implementation OpenConnectAdapter {
	struct openconnect_info *vpninfo;
	const struct oc_ip_info *ip_info;
	const char *compr;
	CFSocketRef _tunSocket;
	CFSocketRef _vpnSocket;
	dispatch_queue_t _dispatchQueue;
}

@synthesize delegate = _delegate;

static void socketCallback(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	NSLog(@"");
}

static void __attribute__ ((format(printf, 3, 4))) write_progress(void *_vpninfo, int level, const char *fmt, ...) {
//	@autoreleasepool {
//        __weak id<OpenConnectAdapterDelegate> delegate = staticSelf.delegate;
//		NSCAssert(delegate != nil, @"delegate property should not be nil");
//		if ([delegate respondsToSelector:@selector(handleLog:)]) {
//            NSString *aString = [NSString stringWithCString:fmt encoding:NSUTF8StringEncoding];
//
//			dispatch_async(dispatch_get_main_queue(), ^{
//                [delegate handleLog:aString];
//			});
//		}
//	}
}

static int validate_peer_cert(void *_vpninfo, const char *reason) {
	return 0;
}

static void setup_tun_vfn_handler(void *privdata) {
	struct openconnect_info *vpninfo = privdata;
	os_setup_tun(vpninfo);
}

static void os_setup_tun_vfn_handler(void *privdata) {
	NSLog(@"");
}

static int os_read_tun_vfn_handler(struct pkt *pkt, void *privdata) {
	int prefix_size = 0;
	int len = 0;
	
	if (_packetsCache.count > 0) {
		@synchronized(_packetsCache) {
			memcpy(pkt->data - prefix_size, _packetsCache.firstObject.bytes, _packetsCache.firstObject.length);
			len = (int) _packetsCache.firstObject.length;
			[_packetsCache removeObjectAtIndex:0];
			[_protocolsCache removeObjectAtIndex:0];
		}
	}
	
	if (len <= prefix_size) {
		return -1;
	}
	
	pkt->len = len - prefix_size;
	return 0;
}

static int os_write_tun_vfn_handler(struct pkt *pkt, void *privdata) {
	struct ip *iph = (void *) pkt->data;
	
	if (!staticSelf.packetsOutCache) {
		staticSelf.packetsOutCache = [NSMutableArray array];
		staticSelf.protocolsOutCache = [NSMutableArray array];
	}
	[staticSelf.packetsOutCache addObject:[NSData dataWithBytes:pkt->data length:pkt->len]];
	[staticSelf.protocolsOutCache addObject:@([staticSelf protocolFamilyForVersion:iph->ip_v])];
	
	if (pkt->next) {
		return 0;
	}
	
	int res = [staticSelf.packetFlow writePackets:staticSelf->_packetsOutCache withProtocols:staticSelf->_protocolsOutCache] ? 0 : -1;
	staticSelf.packetsOutCache = nil;
	staticSelf.protocolsOutCache = nil;
	return res;
}


#pragma mark - Lifecycle

- (instancetype)init {
	self = [super init];
	if (self) {
		staticSelf = self;
		
		_dispatchQueue = dispatch_queue_create("manager", NULL);
		openconnect_init_ssl();
		vpninfo = openconnect_vpninfo_new("OpenConnect VPN Agent for iOS", validate_peer_cert, NULL, NULL, write_progress, NULL);
		vpninfo->progress = write_progress;
		openconnect_set_reported_os(vpninfo, "apple-ios");
		openconnect_set_system_trust(vpninfo, 0);
		
		openconnect_set_setup_tun_handler(vpninfo, setup_tun_vfn_handler);
		openconnect_set_os_setup_tun_handler(vpninfo, os_setup_tun_vfn_handler);
		openconnect_set_os_read_tun_handler(vpninfo, os_read_tun_vfn_handler);
		openconnect_set_os_write_tun_handler(vpninfo, os_write_tun_vfn_handler);
		
		openconnect_set_loglevel(vpninfo, PRG_TRACE);
	}
	return self;
}

- (void)connect {
	dispatch_async(dispatch_get_main_queue(), ^{
		[staticSelf.delegate handleEvent:OpenConnectAdapterEventConnecting message:nil];
	});
	
	if (!vpninfo->cookie && openconnect_obtain_cookie(vpninfo) != 0) {
		if (vpninfo->csd_scriptname) {
			unlink(vpninfo->csd_scriptname);
			vpninfo->csd_scriptname = NULL;
		}
		NSString *errorReason = [self reasonForError:OpenConnectAdapterErrorUnknown];
		NSError *error = [NSError errorWithDomain:OpenConnectAdapterErrorDomain code:OpenConnectAdapterErrorUnknown userInfo:@{
				NSLocalizedDescriptionKey       : @"Failed to establish connection with OpenConnect server.",
				NSLocalizedFailureReasonErrorKey: errorReason,
				OpenConnectAdapterErrorFatalKey : @YES
		}];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate handleError:error];
		});
		return;
	}
	
	if (openconnect_make_cstp_connection(vpninfo) != 0) {
		NSString *errorReason = [self reasonForError:OpenConnectAdapterErrorTCPConnectError];
		NSError *error = [NSError errorWithDomain:OpenConnectAdapterErrorDomain code:OpenConnectAdapterErrorTCPConnectError userInfo:@{
				NSLocalizedDescriptionKey       : @"Failed to establish connection with OpenConnect server.",
				NSLocalizedFailureReasonErrorKey: errorReason,
				OpenConnectAdapterErrorFatalKey : @YES
		}];
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.delegate handleError:error];
		});
		return;
	}

    if (vpninfo->dtls_state != DTLS_DISABLED ) {
        openconnect_setup_dtls(vpninfo, 60);
    }
	
	openconnect_get_ip_info(vpninfo, &ip_info, NULL, NULL);
	
	if (vpninfo->dtls_state != DTLS_CONNECTED) {
		if (vpninfo->cstp_compr == COMPR_DEFLATE) {
			compr = " + deflate";
		} else if (vpninfo->cstp_compr == COMPR_LZS) {
			compr = " + lzs";
		} else if (vpninfo->cstp_compr == COMPR_LZ4) {
			compr = " + lz4";
		}
	} else {
		if (vpninfo->dtls_compr == COMPR_DEFLATE) {
			compr = " + deflate";
		} else if (vpninfo->dtls_compr == COMPR_LZS) {
			compr = " + lzs";
		} else if (vpninfo->dtls_compr == COMPR_LZ4) {
			compr = " + lz4";
		}
	}
	vpn_progress(vpninfo, PRG_INFO, _("Connected %s as %s%s%s, using %s%s\n"),
				 openconnect_get_ifname(vpninfo),
				 ip_info->addr ?: "",
				 (ip_info->netmask6 && ip_info->addr) ? " + " : "",
				 ip_info->netmask6 ?: "",
				 (vpninfo->dtls_state != DTLS_CONNECTED) ? "SSL" : "DTLS", compr);
	
	NEPacketTunnelNetworkSettings *networkSettings = [self prepareTunnelNetworkSettings];
	
    __weak typeof(self)weakSelf = self;
	[self.delegate configureTunnelWithSettings:networkSettings callback:^(id<OpenConnectAdapterPacketFlow> _Nullable flow) {
        __strong typeof(self)strongSelf = weakSelf;
		if (!flow) {
			return;
		}
		
        strongSelf.packetFlow = flow;
		
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
			[strongSelf readTUNMainloop];
		});
		
		dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
			openconnect_setup_tun_fd(strongSelf->vpninfo, CFSocketGetNative(strongSelf->_tunSocket));
			dispatch_async(dispatch_get_main_queue(), ^{
				[staticSelf.delegate handleEvent:OpenConnectAdapterEventConnected message:nil];
			});
			
			[strongSelf runOpenConnectMainloop];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[staticSelf.delegate handleEvent:OpenConnectAdapterEventDisconnected message:nil];
			});
		});
	}];
}

- (void)disconnect {
	vpninfo->got_cancel_cmd = 1;
	dispatch_async(dispatch_get_main_queue(), ^{
		[staticSelf.delegate handleEvent:OpenConnectAdapterEventDisconnected message:nil];
	});
}

- (void)applyConfiguration:(nonnull OpenConnectConfiguration *)configuration error:(out NSError **)error {
	dispatch_async(dispatch_get_main_queue(), ^{
		[staticSelf.delegate handleEvent:OpenConnectAdapterEventGetConfig message:nil];
	});
	char *urlpath = NULL;
	
	if (config_lookup_host(vpninfo, configuration.server.UTF8String)) {
		NSString *errorReason = [self reasonForError:OpenConnectAdapterErrorConfigurationFailure];
		if (error) {
			*error = [NSError errorWithDomain:OpenConnectAdapterErrorDomain code:OpenConnectAdapterErrorConfigurationFailure userInfo:@{
					NSLocalizedDescriptionKey       : @"Failed to apply OpenConnect configuration.",
					NSLocalizedFailureReasonErrorKey: errorReason,
					OpenConnectAdapterErrorFatalKey : @YES
			}];
		}
		return;
	}
	
	if (!vpninfo->hostname) {
		char *url = strdup(configuration.server.UTF8String);
		
		if (openconnect_parse_url(vpninfo, url)) {
			NSString *errorReason = [self reasonForError:OpenConnectAdapterErrorConfigurationFailure];
			if (error) {
				*error = [NSError errorWithDomain:OpenConnectAdapterErrorDomain code:OpenConnectAdapterErrorConfigurationFailure userInfo:@{
						NSLocalizedDescriptionKey       : @"Failed to apply OpenConnect configuration.",
						NSLocalizedFailureReasonErrorKey: errorReason,
						OpenConnectAdapterErrorFatalKey : @YES
				}];
			}
			return;
		}
		
		free(url);
	}
	
	if (urlpath && !vpninfo->urlpath) {
		vpninfo->urlpath = urlpath;
		urlpath = NULL;
	}
	free(urlpath);
	
	if (openconnect_set_cafile(vpninfo,  configuration.settings[@"ca"].UTF8String) != 0) {
		NSString *errorReason = [self reasonForError:OpenConnectAdapterErrorConfigurationFailure];
		if (error) {
			*error = [NSError errorWithDomain:OpenConnectAdapterErrorDomain code:OpenConnectAdapterErrorConfigurationFailure userInfo:@{
					NSLocalizedDescriptionKey       : @"Failed to apply OpenConnect configuration.",
					NSLocalizedFailureReasonErrorKey: errorReason,
					OpenConnectAdapterErrorFatalKey : @YES
			}];
		}
	}
	
	if (openconnect_set_client_cert(vpninfo, configuration.settings[@"cert"].UTF8String, configuration.settings[@"key"].UTF8String) != 0) {
		NSString *errorReason = [self reasonForError:OpenConnectAdapterErrorConfigurationFailure];
		if (error) {
			*error = [NSError errorWithDomain:OpenConnectAdapterErrorDomain code:OpenConnectAdapterErrorConfigurationFailure userInfo:@{
					NSLocalizedDescriptionKey       : @"Failed to apply OpenConnect configuration.",
					NSLocalizedFailureReasonErrorKey: errorReason,
					OpenConnectAdapterErrorFatalKey : @YES
			}];
		}
		return;
	}
	
	[self configureSockets];
}

- (uint8_t)protocolFamilyForVersion:(uint32_t)version {
	switch (version) {
		case 4:
			return PF_INET;
		case 6:
			return PF_INET6;
		default:
			return PF_UNSPEC;
	}
}

- (NEPacketTunnelNetworkSettings *)prepareTunnelNetworkSettings {
	NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@(ip_info->gateway_addr)];
	settings.IPv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@(ip_info->addr)] subnetMasks:@[@(ip_info->netmask)]];
	[self setupRoutes:settings.IPv4Settings];
	
	NSMutableArray *includedRoutes = [settings.IPv4Settings.includedRoutes mutableCopy];
	NSMutableArray *excludedRoutes = [settings.IPv4Settings.excludedRoutes mutableCopy];
	
	[includedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@(ip_info->dns[0]) subnetMask:@"255.255.255.255"]];
	[includedRoutes addObject:[[NEIPv4Route alloc] initWithDestinationAddress:@(ip_info->dns[1]) subnetMask:@"255.255.255.255"]];
	
	settings.IPv4Settings.includedRoutes = includedRoutes;
	settings.IPv4Settings.excludedRoutes = excludedRoutes;
	
	settings.DNSSettings = [[NEDNSSettings alloc] initWithServers:@[@(ip_info->dns[0]), @(ip_info->dns[1])]];
	settings.DNSSettings.domainName = @(ip_info->domain);
	settings.DNSSettings.matchDomains = @[@""];
	settings.MTU = @(ip_info->mtu);
	
	return settings;
}

- (void)setupRoutes:(NEIPv4Settings *)settings {
	NSMutableArray *excludedRoutes = [NSMutableArray array];
	NSMutableArray *includedRoutes = [NSMutableArray array];
	
	int i;
	struct oc_split_include *entry;
	for (entry = ip_info->split_includes, i = 0; entry; entry = entry->next) {
		NSArray *comps = [@(entry->route) componentsSeparatedByString:@"/"];
		NEIPv4Route *route = [[NEIPv4Route alloc] initWithDestinationAddress:comps[0] subnetMask:comps[1]];
		[includedRoutes addObject:route];
		i++;
	}
	for (entry = ip_info->split_excludes, i = 0; entry; entry = entry->next) {
		NSArray *comps = [@(entry->route) componentsSeparatedByString:@"/"];
		NEIPv4Route *route = [[NEIPv4Route alloc] initWithDestinationAddress:comps[0] subnetMask:comps[1]];
		[includedRoutes addObject:route];
		i++;
	}
	
	settings.excludedRoutes = excludedRoutes;
	settings.includedRoutes = includedRoutes;
}

- (void)runOpenConnectMainloop {
	int ret;
	while (1) {
		ret = openconnect_mainloop(vpninfo, 300, RECONNECT_INTERVAL_MIN);
		if (ret) {
			break;
		}
		
		vpn_progress(vpninfo, PRG_INFO, _("User requested reconnect\n"));
	}
}

- (BOOL)configureSockets {
	int sockets[2];
	if (socketpair(PF_LOCAL, SOCK_DGRAM, IPPROTO_IP, sockets) == -1) {
		NSLog(@"Failed to create a pair of connected sockets: %@", [NSString stringWithUTF8String:strerror(errno)]);
		return NO;
	}
	
	if (![self configureBufferSizeForSocket:sockets[0]] || ![self configureBufferSizeForSocket:sockets[1]]) {
		NSLog(@"Failed to configure buffer size of the sockets");
		return NO;
	}
	
	CFSocketContext socketCtxt = {0, (__bridge void *) self, NULL, NULL, NULL};
	
	_vpnSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[0], kCFSocketDataCallBack, &socketCallback, &socketCtxt);
	_tunSocket = CFSocketCreateWithNative(kCFAllocatorDefault, sockets[1], kCFSocketNoCallBack, NULL, NULL);
	
	if (!_vpnSocket || !_tunSocket) {
		NSLog(@"Failed to create core foundation sockets from native sockets");
		return NO;
	}
	
	CFRunLoopSourceRef tunSocketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _vpnSocket, 0);
	CFRunLoopAddSource(CFRunLoopGetMain(), tunSocketSource, kCFRunLoopDefaultMode);
	
	CFRelease(tunSocketSource);
	
	return YES;
}


#pragma mark TUN -> OpenConnect

- (void)readTUNMainloop {
	[self.packetFlow readPacketsWithCompletionHandler:^(NSArray<NSData *> *_Nonnull packets, NSArray<NSNumber *> *_Nonnull protocols) {
		[self writeVPNPackets:packets protocols:protocols];
		[self readTUNMainloop];
	}];
}

- (void)writeVPNPackets:(NSArray<NSData *> *)packets protocols:(NSArray<NSNumber *> *)protocols {
	if (!_packetsCache) {
		_packetsCache = [NSMutableArray array];
		_protocolsCache = [NSMutableArray array];
	}
	@synchronized(_packetsCache) {
		[_packetsCache addObjectsFromArray:packets];
		[_protocolsCache addObjectsFromArray:protocols];
	}
}

- (BOOL)configureBufferSizeForSocket:(int)socket {
	int buf_value = 65536;
	socklen_t buf_len = sizeof(buf_value);
	
	if (setsockopt(socket, SOL_SOCKET, SO_RCVBUF, &buf_value, buf_len) == -1) {
		NSLog(@"Failed to setup buffer size for input: %@", [NSString stringWithUTF8String:strerror(errno)]);
		return NO;
	}
	
	if (setsockopt(socket, SOL_SOCKET, SO_SNDBUF, &buf_value, buf_len) == -1) {
		NSLog(@"Failed to setup buffer size for output: %@", [NSString stringWithUTF8String:strerror(errno)]);
		return NO;
	}
	
	return YES;
}

- (NSString *)reasonForError:(OpenConnectAdapterError)error {
	// TODO: Добавить недостающие описания ошибок
	switch (error) {
		case OpenConnectAdapterErrorConfigurationFailure:
			return @"See OpenConnect error message for more details.";
		case OpenConnectAdapterErrorCredentialsFailure:
			return @"See OpenConnect error message for more details.";
		case OpenConnectAdapterErrorNetworkRecvError:
			return @"Errors receiving on network socket.";
		case OpenConnectAdapterErrorNetworkEOFError:
			return @"EOF received on TCP network socket.";
		case OpenConnectAdapterErrorNetworkSendError:
			return @"Errors sending on network socket";
		case OpenConnectAdapterErrorNetworkUnavailable:
			return @"Network unavailable.";
		case OpenConnectAdapterErrorDecryptError:
			return @"Data channel encrypt/decrypt error.";
		case OpenConnectAdapterErrorHMACError:
			return @"HMAC verification failure.";
		case OpenConnectAdapterErrorReplayError:
			return @"Error from PacketIDReceive.";
		case OpenConnectAdapterErrorBufferError:
			return @"Exception thrown in Buffer methods.";
		case OpenConnectAdapterErrorCCError:
			return @"General control channel errors.";
		case OpenConnectAdapterErrorBadSrcAddr:
			return @"Packet from unknown source address.";
		case OpenConnectAdapterErrorCompressError:
			return @"Compress/Decompress errors on data channel.";
		case OpenConnectAdapterErrorResolveError:
			return @"DNS resolution error.";
		case OpenConnectAdapterErrorSocketProtectError:
			return @"Error calling protect() method on socket.";
		case OpenConnectAdapterErrorTUNReadError:
			return @"Read errors on TUN/TAP interface.";
		case OpenConnectAdapterErrorTUNWriteError:
			return @"Write errors on TUN/TAP interface.";
		case OpenConnectAdapterErrorTUNFramingError:
			return @"Error with tun PF_INET/PF_INET6 prefix.";
		case OpenConnectAdapterErrorTUNSetupFailed:
			return @"Error setting up TUN/TAP interface.";
		case OpenConnectAdapterErrorTUNIfaceCreate:
			return @"Error creating TUN/TAP interface.";
		case OpenConnectAdapterErrorTUNIfaceDisabled:
			return @"TUN/TAP interface is disabled.";
		case OpenConnectAdapterErrorTUNError:
			return @"General tun error.";
		case OpenConnectAdapterErrorTAPNotSupported:
			return @"Dev TAP is present in profile but not supported.";
		case OpenConnectAdapterErrorRerouteGatewayNoDns:
			return @"redirect-gateway specified without alt DNS servers.";
		case OpenConnectAdapterErrorTransportError:
			return @"General transport error";
		case OpenConnectAdapterErrorTCPOverflow:
			return @"TCP output queue overflow.";
		case OpenConnectAdapterErrorTCPSizeError:
			return @"Bad embedded uint16_t TCP packet size.";
		case OpenConnectAdapterErrorTCPConnectError:
			return @"Client error on TCP connect.";
		case OpenConnectAdapterErrorUDPConnectError:
			return @"Client error on UDP connect.";
		case OpenConnectAdapterErrorSSLError:
			return @"Errors resulting from read/write on SSL object.";
		case OpenConnectAdapterErrorSSLPartialWrite:
			return @"SSL object did not process all written cleartext.";
		case OpenConnectAdapterErrorEncapsulationError:
			return @"Exceptions thrown during packet encapsulation.";
		case OpenConnectAdapterErrorEPKICertError:
			return @"Error obtaining certificate from External PKI provider.";
		case OpenConnectAdapterErrorEPKISignError:
			return @"Error obtaining RSA signature from External PKI provider.";
		case OpenConnectAdapterErrorHandshakeTimeout:
			return @"Handshake failed to complete within given time frame.";
		case OpenConnectAdapterErrorKeepaliveTimeout:
			return @"Lost contact with peer.";
		case OpenConnectAdapterErrorInactiveTimeout:
			return @"Disconnected due to inactive timer.";
		case OpenConnectAdapterErrorConnectionTimeout:
			return @"Connection failed to establish within given time.";
		case OpenConnectAdapterErrorPrimaryExpire:
			return @"Primary key context expired.";
		case OpenConnectAdapterErrorTLSVersionMin:
			return @"Peer cannot handshake at our minimum required TLS version.";
		case OpenConnectAdapterErrorTLSAuthFail:
			return @"tls-auth HMAC verification failed.";
		case OpenConnectAdapterErrorCertVerifyFail:
			return @"Peer certificate verification failure.";
		case OpenConnectAdapterErrorPEMPasswordFail:
			return @"Incorrect or missing PEM private key decryption password.";
		case OpenConnectAdapterErrorAuthFailed:
			return @"General authentication failure";
		case OpenConnectAdapterErrorClientHalt:
			return @"HALT message from server received.";
		case OpenConnectAdapterErrorClientRestart:
			return @"RESTART message from server received.";
		case OpenConnectAdapterErrorRelay:
			return @"RELAY message from server received.";
		case OpenConnectAdapterErrorRelayError:
			return @"RELAY error.";
		case OpenConnectAdapterErrorPauseNumber:
			return @"";
		case OpenConnectAdapterErrorReconnectNumber:
			return @"";
		case OpenConnectAdapterErrorKeyLimitRenegNumber:
			return @"";
		case OpenConnectAdapterErrorKeyStateError:
			return @"Received packet didn't match expected key state.";
		case OpenConnectAdapterErrorProxyError:
			return @"HTTP proxy error.";
		case OpenConnectAdapterErrorProxyNeedCreds:
			return @"HTTP proxy needs credentials.";
		case OpenConnectAdapterErrorKevNegotiateError:
			return @"";
		case OpenConnectAdapterErrorKevPendingError:
			return @"";
		case OpenConnectAdapterErrorKevExpireNumber:
			return @"";
		case OpenConnectAdapterErrorPKTIDInvalid:
			return @"";
		case OpenConnectAdapterErrorPKTIDBacktrack:
			return @"";
		case OpenConnectAdapterErrorPKTIDExpire:
			return @"";
		case OpenConnectAdapterErrorPKTIDReplay:
			return @"";
		case OpenConnectAdapterErrorPKTIDTimeBacktrack:
			return @"";
		case OpenConnectAdapterErrorDynamicChallenge:
			return @"";
		case OpenConnectAdapterErrorEPKIError:
			return @"";
		case OpenConnectAdapterErrorEPKIInvalidAlias:
			return @"";
		case OpenConnectAdapterErrorUnknown:
			return @"Unknown error.";
	}
}

@end
