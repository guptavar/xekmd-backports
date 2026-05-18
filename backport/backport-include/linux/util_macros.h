/* SPDX-License-Identifier: GPL-2.0 */
#ifndef __BACKPORT_LINUX_UTIL_MACROS_H
#define __BACKPORT_LINUX_UTIL_MACROS_H

#include_next <linux/util_macros.h>

#ifdef BPM_FOR_EACH_IF_NOT_PRESENT
/*
 * for_each_if moved from drm/drm_util.h to linux/util_macros.h in v7.0.
 * The backported gpu_scheduler.h expects it here.
 */
#define for_each_if(condition) if (!(condition)) {} else
#endif

#endif /* __BACKPORT_LINUX_UTIL_MACROS_H */
