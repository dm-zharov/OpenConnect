/*
 * OpenConnect (SSL + DTLS) VPN client
 *
 * Copyright © 2008-2015 Intel Corporation.
 *
 * Author: David Woodhouse <dwmw2@infradead.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 */

#include <config.h>

#include "openconnect-internal.h"

/*
 * If an if_tun.h include file was found anywhere (by the Makefile), it's
 * included. Else, we end up assuming that we have BSD-style devices such
 * as /dev/tun0 etc.
 */
#ifdef IF_TUN_HDR
#include IF_TUN_HDR
#endif

/*
 * The OS X tun/tap driver doesn't provide a header file; you're expected
 * to define this for yourself.
 */
#ifdef __APPLE__
#define TUNSIFHEAD  _IOW('t', 96, int)
#endif

#if defined(__OpenBSD__) || defined(TUNSIFHEAD)
#define TUN_HAS_AF_PREFIX 1
#endif

intptr_t os_setup_tun(struct openconnect_info *vpninfo)
{
	if (vpninfo->os_setup_tun) {
		vpninfo->os_setup_tun(vpninfo->cbdata);
			return 1;
	}
	return -1;
}

int openconnect_setup_tun_fd(struct openconnect_info *vpninfo, int tun_fd)
{
	vpninfo->tun_fd = 1;
	return 0;
}

int openconnect_setup_tun_script(struct openconnect_info *vpninfo,
				 const char *tun_script)
{
	return -1;
}

int os_read_tun(struct openconnect_info *vpninfo, struct pkt *pkt)
{
	if (vpninfo->os_read_tun) {
		int res = vpninfo->os_read_tun(pkt, vpninfo->cbdata);
		vpn_progress(vpninfo, PRG_TRACE, _("Received TUN packet (len %d)\n"), pkt->len);
		return res;
	}
	return 0;
}

int os_write_tun(struct openconnect_info *vpninfo, struct pkt *pkt)
{
	if (vpninfo->os_write_tun) {
		vpn_progress(vpninfo, PRG_TRACE, _("Writing TUN packet (len %d)\n"), pkt->len);
		return vpninfo->os_write_tun(pkt, vpninfo->cbdata);
	}
	return 0;

}

void os_shutdown_tun(struct openconnect_info *vpninfo)
{
//	vpninfo->tun_fd = -1;
}
