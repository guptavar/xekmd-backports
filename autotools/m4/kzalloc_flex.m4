dnl kzalloc_flex.m4 - check for kzalloc_flex macro
AC_DEFUN([AC_KZALLOC_FLEX_NOT_PRESENT], [
AC_KERNEL_DO_BACKGROUND([
AC_KERNEL_TRY_COMPILE([
#include <linux/slab.h>
], [
struct { int x; int arr[]; } *p;
p = kzalloc_flex(*p, arr, 10);
], [
AC_MSG_RESULT(yes)
], [
AC_DEFINE(BPM_KZALLOC_FLEX_NOT_PRESENT, 1,
[kzalloc_flex is not available])
AC_MSG_RESULT(no)
])
])
])
