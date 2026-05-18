dnl init_llist_node.m4 - check for init_llist_node()
AC_DEFUN([AC_INIT_LLIST_NODE_NOT_PRESENT], [
AC_KERNEL_DO_BACKGROUND([
AC_KERNEL_TRY_COMPILE([
#include <linux/llist.h>
], [
struct llist_node n;
init_llist_node(&n);
], [
AC_MSG_RESULT(yes)
], [
AC_DEFINE(BPM_INIT_LLIST_NODE_NOT_PRESENT, 1,
[init_llist_node is not available])
AC_MSG_RESULT(no)
])
])
])
