dnl dma_fence_check_and_signal.m4
AC_DEFUN([AC_DMA_FENCE_CHECK_AND_SIGNAL_NOT_PRESENT], [
AC_KERNEL_DO_BACKGROUND([
AC_KERNEL_TRY_COMPILE([
#include <linux/dma-fence.h>
], [
bool (*fn)(struct dma_fence *) = dma_fence_check_and_signal_locked;
(void)fn;
], [
AC_MSG_RESULT(yes)
], [
AC_DEFINE(BPM_DMA_FENCE_CHECK_AND_SIGNAL_NOT_PRESENT, 1,
[dma_fence_check_and_signal_locked is not available])
AC_MSG_RESULT(no)
])
])
])
