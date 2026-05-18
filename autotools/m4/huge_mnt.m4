dnl #
dnl # v7.0 - struct drm_device gained huge_mnt member
dnl #
AC_DEFUN([AC_DRM_GEM_HUGE_MNT_NOT_PRESENT], [
        AC_KERNEL_DO_BACKGROUND([
                AC_KERNEL_TRY_COMPILE([
                        #include <drm/drm_device.h>
                ],[
                        struct drm_device *dev = NULL;
                        (void)dev->huge_mnt;
                ],[
                ],[
                        AC_DEFINE(BPM_DRM_GEM_HUGE_MNT_NOT_PRESENT, 1,
                                [struct drm_device does not have huge_mnt member])
                ])
        ])
])
