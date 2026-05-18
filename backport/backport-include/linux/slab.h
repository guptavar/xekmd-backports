#ifndef __BACKPORT_LINUX_SLAB_H
#define __BACKPORT_LINUX_SLAB_H

#include_next <linux/slab.h>

/*
 * v7.0 introduced kzalloc_obj/kmalloc_objs/kvzalloc_objs/kzalloc_objs helpers.
 * Fallback to traditional allocators with sizeof.
 *
 * Variadic macros to handle optional gfp argument:
 *   kzalloc_obj(*ptr)              -> kzalloc(sizeof(*ptr), GFP_KERNEL)
 *   kzalloc_obj(*ptr, gfp)         -> kzalloc(sizeof(*ptr), gfp)
 *   kmalloc_objs(*ptr, n)          -> kmalloc_array(n, sizeof(*ptr), GFP_KERNEL)
 *   kmalloc_objs(*ptr, n, gfp)     -> kmalloc_array(n, sizeof(*ptr), gfp)
 *   kzalloc_objs(*ptr, n)          -> kcalloc(n, sizeof(*ptr), GFP_KERNEL)
 *   kvzalloc_objs(*ptr, n)         -> kvcalloc(n, sizeof(*ptr), GFP_KERNEL)
 */

#ifdef BPM_KZALLOC_OBJ_NOT_PRESENT
#define __kzalloc_obj_1(obj)      kzalloc(sizeof(obj), GFP_KERNEL)
#define __kzalloc_obj_2(obj, gfp) kzalloc(sizeof(obj), gfp)
#define __kzalloc_obj_pick(_1, _2, NAME, ...) NAME
#define kzalloc_obj(...) \
	__kzalloc_obj_pick(__VA_ARGS__, __kzalloc_obj_2, __kzalloc_obj_1)(__VA_ARGS__)

#define __kmalloc_obj_1(obj)      kmalloc(sizeof(obj), GFP_KERNEL)
#define __kmalloc_obj_2(obj, gfp) kmalloc(sizeof(obj), gfp)
#define __kmalloc_obj_pick(_1, _2, NAME, ...) NAME
#define kmalloc_obj(...) \
	__kmalloc_obj_pick(__VA_ARGS__, __kmalloc_obj_2, __kmalloc_obj_1)(__VA_ARGS__)
#endif

#ifdef BPM_KMALLOC_OBJS_NOT_PRESENT
#define __kmalloc_objs_2(obj, n)      kmalloc_array((n), sizeof(obj), GFP_KERNEL)
#define __kmalloc_objs_3(obj, n, gfp) kmalloc_array((n), sizeof(obj), gfp)
#define __kmalloc_objs_pick(_1, _2, _3, NAME, ...) NAME
#define kmalloc_objs(...) \
	__kmalloc_objs_pick(__VA_ARGS__, __kmalloc_objs_3, __kmalloc_objs_2)(__VA_ARGS__)
#endif

#ifdef BPM_KZALLOC_OBJS_NOT_PRESENT
#define __kzalloc_objs_2(obj, n)      kcalloc((n), sizeof(obj), GFP_KERNEL)
#define __kzalloc_objs_3(obj, n, gfp) kcalloc((n), sizeof(obj), gfp)
#define __kzalloc_objs_pick(_1, _2, _3, NAME, ...) NAME
#define kzalloc_objs(...) \
	__kzalloc_objs_pick(__VA_ARGS__, __kzalloc_objs_3, __kzalloc_objs_2)(__VA_ARGS__)
#endif

#ifdef BPM_KVZALLOC_OBJS_NOT_PRESENT
#define __kvzalloc_objs_2(obj, n)      kvcalloc((n), sizeof(obj), GFP_KERNEL)
#define __kvzalloc_objs_3(obj, n, gfp) kvcalloc((n), sizeof(obj), gfp)
#define __kvzalloc_objs_pick(_1, _2, _3, NAME, ...) NAME
#define kvzalloc_objs(...) \
	__kvzalloc_objs_pick(__VA_ARGS__, __kvzalloc_objs_3, __kvzalloc_objs_2)(__VA_ARGS__)

#define __kvmalloc_objs_2(obj, n)      kvmalloc_array((n), sizeof(obj), GFP_KERNEL)
#define __kvmalloc_objs_3(obj, n, gfp) kvmalloc_array((n), sizeof(obj), gfp)
#define __kvmalloc_objs_pick(_1, _2, _3, NAME, ...) NAME
#define kvmalloc_objs(...) \
	__kvmalloc_objs_pick(__VA_ARGS__, __kvmalloc_objs_3, __kvmalloc_objs_2)(__VA_ARGS__)
#endif

#ifdef BPM_KZALLOC_FLEX_NOT_PRESENT
#define __backport_alloc_flex(ALLOCATOR, TYPE, FAM, COUNT)		\
({									\
	const size_t __count = (COUNT);					\
	const size_t __sz = struct_size_t(TYPE, FAM, __count);		\
	(TYPE *)ALLOCATOR(__sz, GFP_KERNEL);				\
})
#define kmalloc_flex(P, FAM, COUNT, ...)				\
	__backport_alloc_flex(kmalloc, typeof(P), FAM, COUNT)
#define kzalloc_flex(P, FAM, COUNT, ...)				\
	__backport_alloc_flex(kzalloc, typeof(P), FAM, COUNT)
#define kvmalloc_flex(P, FAM, COUNT, ...)				\
	__backport_alloc_flex(kvmalloc, typeof(P), FAM, COUNT)
#define kvzalloc_flex(P, FAM, COUNT, ...)				\
	__backport_alloc_flex(kvzalloc, typeof(P), FAM, COUNT)
#endif

#endif /* __BACKPORT_LINUX_SLAB_H */
