dnl #
dnl # Test for kzalloc_obj/kmalloc_objs/kvzalloc_objs/kzalloc_objs helpers (v7.0+)
dnl #

AC_DEFUN([AC_KZALLOC_OBJ_NOT_PRESENT], [
	AC_KERNEL_DO_BACKGROUND([
		AC_KERNEL_TRY_COMPILE([
			#include <linux/slab.h>
		],[
			int *p;
			p = kzalloc_obj(*p);
			(void)p;
		],[
		],[
			AC_DEFINE(BPM_KZALLOC_OBJ_NOT_PRESENT, 1,
				[kzalloc_obj() macro is not available])
		])
	])
])

AC_DEFUN([AC_KMALLOC_OBJS_NOT_PRESENT], [
	AC_KERNEL_DO_BACKGROUND([
		AC_KERNEL_TRY_COMPILE([
			#include <linux/slab.h>
		],[
			int *p;
			p = kmalloc_objs(*p, 4);
			(void)p;
		],[
		],[
			AC_DEFINE(BPM_KMALLOC_OBJS_NOT_PRESENT, 1,
				[kmalloc_objs() macro is not available])
		])
	])
])

AC_DEFUN([AC_KZALLOC_OBJS_NOT_PRESENT], [
	AC_KERNEL_DO_BACKGROUND([
		AC_KERNEL_TRY_COMPILE([
			#include <linux/slab.h>
		],[
			int *p;
			p = kzalloc_objs(*p, 4);
			(void)p;
		],[
		],[
			AC_DEFINE(BPM_KZALLOC_OBJS_NOT_PRESENT, 1,
				[kzalloc_objs() macro is not available])
		])
	])
])

AC_DEFUN([AC_KVZALLOC_OBJS_NOT_PRESENT], [
	AC_KERNEL_DO_BACKGROUND([
		AC_KERNEL_TRY_COMPILE([
			#include <linux/slab.h>
		],[
			int *p;
			p = kvzalloc_objs(*p, 4);
			(void)p;
		],[
		],[
			AC_DEFINE(BPM_KVZALLOC_OBJS_NOT_PRESENT, 1,
				[kvzalloc_objs() macro is not available])
		])
	])
])
