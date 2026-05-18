dnl drm_mode_size_dumb.m4 - check for drm_mode_size_dumb
AC_DEFUN([AC_DRM_MODE_SIZE_DUMB_NOT_PRESENT], [
AC_KERNEL_DO_BACKGROUND([
AC_KERNEL_TRY_COMPILE([
#include <drm/drm_dumb_buffers.h>
], [
int (*fn)(struct drm_device *, struct drm_mode_create_dumb *,
  unsigned long, unsigned long) = drm_mode_size_dumb;
(void)fn;
], [
AC_MSG_RESULT(yes)
], [
AC_DEFINE(BPM_DRM_MODE_SIZE_DUMB_NOT_PRESENT, 1,
[drm_mode_size_dumb not available])
AC_MSG_RESULT(no)
])
])
])
