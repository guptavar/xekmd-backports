dnl #
dnl # v6.12 - system_percpu_wq workqueue
dnl #
AC_DEFUN([AC_SYSTEM_PERCPU_WQ_NOT_PRESENT], [
        AC_KERNEL_DO_BACKGROUND([
                AC_KERNEL_TRY_COMPILE([
                        #include <linux/workqueue.h>
                ],[
                        struct workqueue_struct *wq = system_percpu_wq;
                        (void)wq;
                ],[
                ],[
                        AC_DEFINE(BPM_SYSTEM_PERCPU_WQ_NOT_PRESENT, 1,
                                [system_percpu_wq is not available])
                ])
        ])
])
