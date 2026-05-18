dnl configfs_is_visible.m4 - check for configfs_group_operations.is_visible
AC_DEFUN([AC_CONFIGFS_IS_VISIBLE_NOT_PRESENT], [
AC_KERNEL_DO_BACKGROUND([
AC_KERNEL_TRY_COMPILE([
#include <linux/configfs.h>
], [
struct configfs_group_operations ops;
ops.is_visible = NULL;
(void)ops;
], [
AC_MSG_RESULT(yes)
], [
AC_DEFINE(BPM_CONFIGFS_IS_VISIBLE_NOT_PRESENT, 1,
[configfs_group_operations.is_visible not available])
AC_MSG_RESULT(no)
])
])
])
