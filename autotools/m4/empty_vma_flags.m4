dnl #
dnl # v7.0 - EMPTY_VMA_FLAGS type-safe VMA flags
dnl #
AC_DEFUN([AC_EMPTY_VMA_FLAGS_NOT_PRESENT], [
        AC_KERNEL_DO_BACKGROUND([
                AC_KERNEL_TRY_COMPILE([
                        #include <linux/mm_types.h>
                ],[
                        vma_flags_t f = EMPTY_VMA_FLAGS;
                        (void)f;
                ],[
                ],[
                        AC_DEFINE(BPM_EMPTY_VMA_FLAGS_NOT_PRESENT, 1,
                                [EMPTY_VMA_FLAGS / vma_flags_t not available])
                ])
        ])
])
