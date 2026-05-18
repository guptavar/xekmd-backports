dnl #
dnl # v7.0 - vfio_device_ops gained get_region_info_caps member
dnl #
AC_DEFUN([AC_VFIO_GET_REGION_INFO_CAPS_NOT_PRESENT], [
        AC_KERNEL_DO_BACKGROUND([
                AC_KERNEL_TRY_COMPILE([
                        #include <linux/vfio.h>
                ],[
                        struct vfio_device_ops ops;
                        (void)ops.get_region_info_caps;
                ],[
                ],[
                        AC_DEFINE(BPM_VFIO_GET_REGION_INFO_CAPS_NOT_PRESENT, 1,
                                [vfio_device_ops.get_region_info_caps not available])
                ])
        ])
])
