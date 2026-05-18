# PR-348 vs `svm-fresh-start` — Non-SVM File-by-File Comparison

> **Scope:** PR-348 (Akanksha) targets xe v7.0→6.6 **build-time API compat only**. SVM mm-API patches and `drm_gpusvm_helper` enablement that live exclusively on `svm-fresh-start` are **out of scope here** and not compared.
>
> **Base commit:** `b298eddc1` (tag `xeb_v6.17.13.54_260409.5`)
> **Important context:** When `pr-348 + pr-396` were combined, **SVM tests hung on the DUT**. That regression is documented in §11 below — at least one of the PR-348 design choices is implicated as a likely root cause.

---

## TL;DR Decision Matrix

All paths are relative to repo root `/home/varungup/varun_svm_backport/temp_svm_rebased/xekmd-backports/`.

| # | Topic | File path(s) | Keep | Why |
|---|---|---|---|---|
| 1 | xe.m4 probe registration | `autotools/m4/xe.m4` | **Ours** (with PR-348 naming cleanup) | Functionally same; PR-348 includes 4 extra probes for symbols we never reference |
| 2 | slab.h allocator macros | `backport/backport-include/linux/slab.h` | **PR-348** (the `__alloc_objs` helper) | Single helper; we have 6 hand-rolled variadic picks |
| 3 | pci.h rebar helpers | `backport/backport-include/linux/pci.h` + `backport/compat/pci-rebar.c` | **PR-348** (decls only) + her `compat/pci-rebar.c` | Out-of-line avoids multi-TU duplicate-symbol risk |
| 4 | drm_mode_size_dumb | `backport/compat/drm_dumb_buffers.c` (hers) vs `patches/0018-drm-xe-bo-guard-drm_mode_size_dumb.patch` (ours) | **Ours** (inline guard) | Hers is a 147-line full-color-mode shim — overkill for the single dumb-create call |
| 5 | dma_fence_check_and_signal_locked | `backport/compat/dma-fence.c` + `backport/backport-include/linux/dma-fence.h` | **PR-348** if path activates | Not used in our build; her shim is correct |
| 6 | dev_coredumpv patch | `patches/0004-drm-xe-use-dev_coredumpv-without-dev_coredump_put.patch` | **Ours** | PR-348 deleted it entirely; our updated `put_pm:` fix is needed on v7.0.1.2 |
| 7 | vfio get_region_info_caps | hers: `patches/0001-Add-get_region_info_caps-compatibility.patch` vs ours: `patches/0008-vfio-xe-guard-get_region_info_caps.patch` | **Ours** (inline guard) | Hers patches kernel header; ours is local to xe-vfio-pci |
| 8 | huge_mnt field | hers patches `include/drm/drm_gem.h` vs ours: `patches/0007-drm-gem-stub-huge_mnt-for-older-kernels.patch` | **Ours** (stub patch) | Hers modifies shared DRM header; ours stays in xe scope |
| 9 | configfs.is_visible | xe configfs site (in-tree); both gate via `#ifdef` | **Ours** (inline guard) | Same rationale — narrower blast radius |
| 10 | ACQUIRE() macro | hers: `patches/...ACQUIRE-fallback...patch` touching `drivers/gpu/drm/xe/xe_device.c` | **PR-348** | We never wrote a fallback; if her path ever triggers we need it |
| 11 | __assign_str | hers patches `include/trace/stages/stage6_event_callback.h` | **PR-348** | Affects trace events; we got away without it but it’s correct |
| 12 | kconf/zconf.y fix | `backport/kconf/zconf.y` (PR-348 commit `20b32be11`) | **PR-348** | Genuine gentree bug |
| 13 | Vestigial DKMS scripts | `backport/scripts/backport-mkdrmdkmsconf`, `backport/scripts/backport-mkdrmdkmsspec` | Either (delete) | Vestigial; safe to delete |
| 14 | m4 file organization | `autotools/m4/*.m4` (whole dir) | **PR-348** | Domain-named files vs our flat per-symbol layout |
| 15 | BPM_*_PRESENT + BPM_*_NOT_PRESENT dual define | All `autotools/m4/*.m4` probe files | **PR-348** | Symmetric `#ifdef` style |
| 11′ | SVM hang root cause (`migrate_device_pfns`) | PR-396: `patches/0001-drm-pagemap-guard-v7-mm-APIs-for-older-kernels.patch` vs ours: `patches/0015-drm-pagemap-folio_free-migrate_device_pfns-compat.patch` | **Ours** | PR-396 calls `migrate_device_pfns()` unconditionally → shrinker hang on 6.6; ours short-circuits to `-EOPNOTSUPP` |

---

## File-by-File Diffs

### 1. `autotools/m4/xe.m4` (probe registration)

**PR-348 adds 24 probes:**
```
AC_KMALLOC_OBJ_NOT_PRESENT          AC_KMALLOC_OBJS_NOT_PRESENT
AC_KZALLOC_OBJ_NOT_PRESENT          AC_KZALLOC_OBJS_NOT_PRESENT
AC_KVZALLOC_OBJS_NOT_PRESENT        AC_KVMALLOC_OBJS_NOT_PRESENT
AC_KZALLOC_FLEX_NOT_PRESENT         AC_VMA_FLAGS_T_NOT_PRESENT
AC_DRM_DEVICE_HUGE_MNT_NOT_PRESENT  AC_SYSTEM_PERCPU_WQ_NOT_PRESENT
AC_VFIO_GET_REGION_INFO_CAPS_NOT_PRESENT
AC_ACQUIRE_MACRO_NOT_PRESENT
AC_DEFINE_GUARD_COND_4_ARGS_NOT_PRESENT
AC_INIT_LLIST_NODE_NOT_PRESENT
AC_DMA_FENCE_CHECK_AND_SIGNAL_LOCKED_NOT_PRESENT
AC_PCI_RESIZE_RESOURCE_ARG4_NOT_PRESENT
AC_PCI_REBAR_SIZE_SUPPORTED_NOT_PRESENT
AC_PCI_REBAR_SIZE_TO_BYTES_NOT_PRESENT
AC_PCI_REBAR_GET_MAX_SIZE_NOT_PRESENT
AC_CONFIGFS_GROUP_OPS_IS_VISIBLE_NOT_PRESENT
AC_DRM_MODE_SIZE_DUMB_NOT_PRESENT
AC_DRM_PAGEMAP_PUT_NOT_PRESENT
AC_DRM_GPUVM_BO_OBTAIN_LOCKED_NOT_PRESENT
AC_DRM_GPUVM_MADVISE_OPS_CREATE_NOT_PRESENT
```

**Ours adds 23 probes (with slightly different names):**
```
AC_KZALLOC_OBJ_NOT_PRESENT          AC_KMALLOC_OBJS_NOT_PRESENT
AC_KZALLOC_OBJS_NOT_PRESENT         AC_KVZALLOC_OBJS_NOT_PRESENT
AC_KZALLOC_FLEX_NOT_PRESENT         AC_DRM_GEM_HUGE_MNT_NOT_PRESENT
AC_CLEANUP_ACQUIRE_NOT_PRESENT      AC_SYSTEM_PERCPU_WQ_NOT_PRESENT
AC_EMPTY_VMA_FLAGS_NOT_PRESENT      AC_VFIO_GET_REGION_INFO_CAPS_NOT_PRESENT
AC_FOR_EACH_IF_NOT_PRESENT          AC_INIT_LLIST_NODE_NOT_PRESENT
AC_POLL_TIMEOUT_US_NOT_PRESENT      AC_DMA_FENCE_CHECK_AND_SIGNAL_NOT_PRESENT
AC_PAGE_PGMAP_NOT_PRESENT (SVM)     AC_DEV_PAGEMAP_OPS_FOLIO_FREE_NOT_PRESENT (SVM)
AC_VMA_ALLOC_FOLIO_4ARGS_NOT_PRESENT (SVM)
AC_ZONE_DEVICE_PAGE_INIT_3ARGS_NOT_PRESENT (SVM)
AC_PCI_REBAR_SIZE_SUPPORTED_NOT_PRESENT
AC_CONFIGFS_IS_VISIBLE_NOT_PRESENT
AC_SHRINKER_ALLOC_NOT_PRESENT (SVM)
AC_MIGRATE_DEVICE_PFNS_NOT_PRESENT (SVM)
AC_DRM_MODE_SIZE_DUMB_NOT_PRESENT
```

**Differences (non-SVM only):**
- PR-348 has `AC_DRM_PAGEMAP_PUT_NOT_PRESENT`, `AC_DRM_GPUVM_BO_OBTAIN_LOCKED_NOT_PRESENT`, `AC_DRM_GPUVM_MADVISE_OPS_CREATE_NOT_PRESENT` — we don’t. Investigate if these paths are exercised.
- PR-348 has `AC_PCI_RESIZE_RESOURCE_ARG4_NOT_PRESENT`, `AC_PCI_REBAR_SIZE_TO_BYTES_NOT_PRESENT`, `AC_PCI_REBAR_GET_MAX_SIZE_NOT_PRESENT` — finer granularity than our single `AC_PCI_REBAR_SIZE_SUPPORTED_NOT_PRESENT`.
- Naming: ours uses `AC_CLEANUP_ACQUIRE_NOT_PRESENT` vs hers `AC_ACQUIRE_MACRO_NOT_PRESENT`. Hers also has the `DEFINE_GUARD_COND` probe (we don’t).
- Indentation: ours uses 8-space; PR-348 uses tabs (matches surrounding `xe.m4`). 🔸 Fix.

**Verdict:** Adopt PR-348’s probe names and the missing pci_rebar granularity. Our SVM probes stay (out of scope, but listed for completeness).

---

### 2. `backport/backport-include/linux/slab.h` (allocator macros)

#### PR-348 design — single `__alloc_objs` helper
```c
#define __alloc_objs(KMALLOC, GFP, TYPE, COUNT)                         \
({                                                                      \
    const size_t __obj_size = size_mul(sizeof(TYPE), COUNT);            \
    (TYPE *)KMALLOC(__obj_size, GFP);                                   \
})

#ifdef BPM_KMALLOC_OBJ_NOT_PRESENT
#define kmalloc_obj(VAR_OR_TYPE, ...) \
    __alloc_objs(kmalloc, default_gfp(__VA_ARGS__), typeof(VAR_OR_TYPE), 1)
#endif

#ifdef BPM_KMALLOC_OBJS_NOT_PRESENT
#define kmalloc_objs(VAR_OR_TYPE, COUNT, ...) \
    __alloc_objs(kmalloc, default_gfp(__VA_ARGS__), typeof(VAR_OR_TYPE), COUNT)
#endif
/* … kzalloc_obj, kzalloc_objs, kvzalloc_objs, kvmalloc_objs follow the same pattern */
```

#### Our design — per-variant variadic picks
```c
#ifdef BPM_KZALLOC_OBJ_NOT_PRESENT
#define __kzalloc_obj_1(obj)      kzalloc(sizeof(obj), GFP_KERNEL)
#define __kzalloc_obj_2(obj, gfp) kzalloc(sizeof(obj), gfp)
#define __kzalloc_obj_pick(_1, _2, NAME, ...) NAME
#define kzalloc_obj(...) \
    __kzalloc_obj_pick(__VA_ARGS__, __kzalloc_obj_2, __kzalloc_obj_1)(__VA_ARGS__)
/* … same scaffolding repeated 6 more times for kmalloc_obj, kmalloc_objs,
   kzalloc_objs, kvzalloc_objs, kvmalloc_objs … */
```

**Implications:**
- PR-348: ~80 lines, semantically cleaner. Uses `size_mul()` (overflow-safe); ours uses raw `sizeof(*ptr) * n`.
- Ours: ~60 lines per allocator × 6 variants = visually noisy; **integer-overflow risk** because we don’t use `size_mul`.

**Verdict:** **Adopt PR-348’s slab.h.** It is strictly better — fewer LOC, safer arithmetic, and matches the upstream v7.0 API’s overflow semantics.

---

### 3. `backport/backport-include/linux/pci.h` (rebar)

#### PR-348 — declarations only; implementations in `compat/pci-rebar.c`
```c
#ifdef BPM_PCI_REBAR_SIZE_SUPPORTED_NOT_PRESENT
#define SZ_128T          (1ULL << 47)
#define PCI_REBAR_MIN_SIZE  ((resource_size_t)SZ_1M)
bool pci_rebar_size_supported(struct pci_dev *pdev, int bar, int size);
#endif
#ifdef BPM_PCI_REBAR_SIZE_TO_BYTES_NOT_PRESENT
resource_size_t pci_rebar_size_to_bytes(int size);
#endif
#ifdef BPM_PCI_REBAR_GET_MAX_SIZE_NOT_PRESENT
int pci_rebar_get_max_size(struct pci_dev *pdev, int bar);
#endif
```
The actual code lives in `backport/compat/pci-rebar.c`, exported via `EXPORT_SYMBOL_GPL`.

#### Ours — `static inline` definitions inside the header
```c
#ifdef BPM_PCI_REBAR_SIZE_SUPPORTED_NOT_PRESENT
static inline u64 pci_rebar_size_to_bytes(int size)         { return (u64)1 << (size + 20); }
static inline bool pci_rebar_size_supported(...)            { ... }
static inline int pci_rebar_get_max_size(...)               { ... }
#endif
```

**Implications:**
- Ours: works **only** because the helpers are pulled into a single TU today. Any new file `#include`ing `<linux/pci.h>` while building inside the backport tree gets its own copy — wastes text/icache but doesn’t break.
- PR-348: out-of-line exported symbol → one copy, available to every module in the tree. Safer if `xe-vfio-pci.ko` or future modules need it.

**Verdict:** **Adopt PR-348’s split.** Move our definitions into `backport/compat/pci-rebar.c`, keep only declarations in pci.h.

---

### 4. `drm_mode_size_dumb` handling

#### PR-348 — `backport/compat/drm_dumb_buffers.c` (147-line full shim)
Reimplements:
- `drm_driver_color_mode_format()`
- `drm_mode_size_dumb()`
- color-mode pixel-format helpers

Then adds a patch that says “use my shim where xe_bo.c calls it.”

#### Ours — `patches/0018-drm-xe-bo-guard-drm_mode_size_dumb.patch`
```c
#ifdef BPM_DRM_MODE_SIZE_DUMB_NOT_PRESENT
    {
        int cpp = DIV_ROUND_UP(args->bpp, 8);
        args->pitch = ALIGN(args->width * cpp, 64);
        args->size = ALIGN(mul_u32_u32(args->pitch, args->height), page_size);
    }
#else
    err = drm_mode_size_dumb(dev, args, SZ_64, page_size);
    if (err) return err;
#endif
```

**Implications:**
- PR-348’s shim duplicates 147 lines of upstream `drm_dumb_buffers.c` that we’ll have to update every time upstream changes — maintenance liability.
- The xe driver is the **only** caller in our tree. The 6-line inline calc is equivalent.

**Verdict:** **Keep ours.** Only revisit if another consumer of `drm_mode_size_dumb()` appears.

---

### 5. `dma_fence_check_and_signal_locked`

PR-348 has `backport/compat/dma-fence.c` (15 lines) + `backport/backport-include/linux/dma-fence.h` (17 lines, declaration only). Ours doesn’t define it — **we never hit a build error referencing it**, which means our v7.0.1.2 source tree doesn’t use that symbol on the build paths we enable.

**Verdict:** Skip until needed. If a future bump exposes it, pull her shim verbatim.

---

### 6. `0004-drm-xe-use-dev_coredumpv-without-dev_coredump_put.patch`

PR-348 **deletes the patch entirely** (commit removes 110 lines). Ours **keeps it** and additionally fixed stale `put_pm:` label references.

**Implications:** PR-348’s removal suggests Akanksha believed `dev_coredump_put` was now provided by the base kernel (perhaps via her separate header shim). Our build needed the patch — without it, `xe_devcoredump_register()` fails to compile. The patch is **required** on v7.0.1.2 against 6.6.137.

**Verdict:** **Keep ours.** PR-348’s deletion is wrong for our base.

---

### 7. `vfio get_region_info_caps`

PR-348 patch `0001-Add-get_region_info_caps-compatibility…`:
```c
static const struct vfio_device_ops xe_vfio_pci_ops = {
    .open_device = xe_vfio_pci_open_device,
    .close_device = xe_vfio_pci_close_device,
    .ioctl = vfio_pci_core_ioctl,
+#ifndef BPM_VFIO_GET_REGION_INFO_CAPS_NOT_PRESENT
    .get_region_info_caps = vfio_pci_ioctl_get_region_info,
```

Ours: same idea, different file location (`patches/0008-vfio-xe-guard-get_region_info_caps.patch`). Functionally identical.

**Verdict:** Either works. Keep ours for series-cohesion.

---

### 8. `huge_mnt` field

PR-348 patches `include/drm/drm_gem.h` directly:
```c
-#ifdef CONFIG_TRANSPARENT_HUGEPAGE
+#if defined(CONFIG_TRANSPARENT_HUGEPAGE) && !defined(BPM_DRM_DEVICE_HUGE_MNT_NOT_PRESENT)
```
Ours stubs at xe scope via `patches/0007-drm-gem-stub-huge_mnt-for-older-kernels.patch`.

**Implications:** Hers modifies a shared DRM header, affecting any consumer included from drm_gem.h. Ours is local.

**Verdict:** **Keep ours.** Narrower blast radius.

---

### 9. `configfs.is_visible`

Similar pattern. Both gate the `.is_visible` assignment. Equivalent.

**Verdict:** Either works.

---

### 10. `ACQUIRE()` / `ACQUIRE_ERR()` (cleanup.h)

PR-348 patch adds explicit fallback to `xe_drm_ioctl()`:
```c
#ifdef BPM_ACQUIRE_MACRO_NOT_PRESENT
    ret = xe_pm_runtime_get_ioctl(xe);
    if (ret >= 0) {
        xe_eudebug_discovery_lock(xe, cmd);
        ret = drm_ioctl(file, cmd, arg);
        xe_eudebug_discovery_unlock(xe, cmd);
        ...
    }
#else
    /* v7.0+ uses ACQUIRE() scope guard */
#endif
```

We **never wrote this patch**, yet our build succeeded. Likely because xe v7.0.1.2 `xe_device.c` doesn’t emit the `ACQUIRE()`-style scope guard on this path (different ordering vs the branch she targeted).

🔸 **Action item:** verify `xe_drm_ioctl()` in our generated source actually compiles correctly without her patch. If it does — great. If a future xe bump pulls in the scope guard, we need her fallback.

---

### 11. `__assign_str` macro

PR-348 patches `include/trace/stages/stage6_event_callback.h` to make `__assign_str` portable across kernels that take 1 vs 2 arguments. Our build didn’t hit this — likely tracer disabled or compiler accepted the legacy form. Defensive: keep her patch ready.

---

### 12. `backport/kconf/zconf.y`

PR-348 commit `20b32be11`:
> kconf: fix kconf_id_lookup forward declaration and include placement

Genuine gentree-time fix. **Adopt.**

---

### 13. Vestigial DKMS scripts

PR-348 deletes:
- `backport/scripts/backport-mkdrmdkmsconf` (84 lines)
- `backport/scripts/backport-mkdrmdkmsspec` (163 lines)

These were used by an older DKMS workflow. Neither tree uses them today.

**Verdict:** Delete from both branches.

---

### 14. m4 file organization

| Topic | PR-348 file | Ours |
|---|---|---|
| Cleanup / guards | `autotools/m4/cleanup.m4` | `cleanup_guard_cond.m4` (split) |
| Configfs is_visible | `configfs.m4` | `configfs_is_visible.m4` |
| dma-fence | `dma_fence_check_and_signal_locked.m4` | `dma_fence_check_and_signal.m4` |
| drm_device.huge_mnt | `drm_device_huge_mnt.m4` | `huge_mnt.m4` |
| drm_dumb_buffers | `drm_dumb_buffers.m4` | `drm_mode_size_dumb.m4` |
| drm_pagemap_put | `drm_pagemap.m4` | (in our other files) |
| drm_gpuvm.* | `drm_gpuvm.m4` | (not probed) |
| linux/slab.h | `linux_slab.m4` | `linux_slab.m4` |
| llist | `llist.m4` | `init_llist_node.m4` |
| mm_types vma_flags_t | `mm_types.m4` | `empty_vma_flags.m4` |
| pci rebar | `pci_rebar.m4` | `pci_rebar.m4` |
| vfio | `vfio.m4` | `vfio_get_region_info_caps.m4` |
| workqueue | `workqueue.m4` | `system_percpu_wq.m4` |

**Verdict:** **Adopt PR-348’s grouping.** Domain-named files scale better than per-symbol.

---

### 15. Dual `BPM_*_PRESENT` and `BPM_*_NOT_PRESENT` defines

PR-348 example:
```c
],[
    AC_DEFINE(BPM_DRM_MODE_SIZE_DUMB_PRESENT, 1, [is available])
],[
    AC_DEFINE(BPM_DRM_MODE_SIZE_DUMB_NOT_PRESENT, 1, [is not available])
])
```
Ours only defines the `_NOT_PRESENT` half.

**Verdict:** **Adopt.** Cleaner code (`#ifdef X_PRESENT` reads better than `#ifndef X_NOT_PRESENT` in some sites).

---

## 11. Why `PR-348 + PR-396` Hung on the DUT (Hypotheses)

When the team tried merging Akanksha’s PR-348 (build compat) **plus** PR-396 (SVM mm-API probes by Varun), **SVM IGT tests hung**. Our `svm-fresh-start` rewrites those same SVM patches differently and **doesn’t hang**.

Comparing the SVM patch in PR-396 vs our `0015-drm-pagemap-folio_free-migrate_device_pfns-compat.patch`, the **critical difference** is in `drm_pagemap_evict_to_ram()`:

**PR-396 (hung):** does **not** guard `migrate_device_pfns()`. The call goes through unconditionally → on 6.6, the function doesn’t exist as a per-PFN migrator (only `migrate_device_pages()` taking a full `migrate_vma`). If the symbol was satisfied by a stub or by accident through a different path, the shrinker eviction would loop or stall.

**Ours (works):**
```c
#ifdef BPM_MIGRATE_DEVICE_PFNS_NOT_PRESENT
    err = -EOPNOTSUPP;
    goto err_free;
#else
    err = migrate_device_pfns(src, npages);
    if (err) goto err_free;
#endif
```
We **explicitly fail** the shrinker eviction path on 6.6 → shrinker leaves the allocation in place → SVM page-fault migration path (which uses `migrate_vma_setup`/`_pages`/`_finalize`) continues to work and **never recurses into a non-existent helper**.

**Other suspicious PR-396 paths:**
- `drm_pagemap_page_free()` vs `drm_pagemap_folio_free()` — PR-396 has it; ours too, equivalent.
- `vma_alloc_folio` 4→5 args — both branches handle.
- `zone_device_page_init` 1→3 args — both handle.

But `migrate_device_pfns` is the **only place** where PR-396 silently assumes the symbol exists. On 6.6 the symbol must come from either a kernel patch (`mm/migrate_device.c` export) or a stub. If the host kernel doesn’t export it, modpost would have caught it — so the hang is more likely a **runtime semantics mismatch**: the host’s `migrate_device_pages()` (called with a fully-populated `migrate_vma`) doesn’t do what the v7.0 caller expects, leading to a stall in the shrinker.

🔸 **Recommendation:** keep our `-EOPNOTSUPP` short-circuit. Do **not** adopt PR-396’s SVM mm patch verbatim.

---

## 12. Final Recommended Action Plan

### Stage A — Cherry-pick from PR-348
1. Adopt `__alloc_objs` slab.h (item 2).
2. Move pci_rebar to `compat/pci-rebar.c` (item 3).
3. Pull her m4 reorganization (item 14).
4. Dual `_PRESENT`/`_NOT_PRESENT` defines (item 15).
5. kconf/zconf.y fix (item 12).
6. Delete vestigial DKMS scripts (item 13).
7. Adopt her `ACQUIRE()` fallback patch **conditionally** — only after auditing our `xe_drm_ioctl()` (item 10).
8. Adopt her `__assign_str` patch defensively (item 11).

### Stage B — Reject from PR-348
- Do **not** delete `0004-drm-xe-use-dev_coredumpv…` (item 6).
- Do **not** adopt her `huge_mnt` / `is_visible` / `get_region_info_caps` *kernel-header* patches; keep our local xe-scope guards (items 7–9).
- Do **not** adopt her 147-line `drm_dumb_buffers.c` shim; keep our inline calc (item 4).

### Stage C — Reject from PR-396
- Do **not** adopt her unconditional `migrate_device_pfns()` call. Keep our `-EOPNOTSUPP` shrinker short-circuit (item 11 in §11).

### Stage D — Validate after each merge
Run gentree + compile, then on DUT: `xe_exec_system_allocator --run-subtest once-malloc`. If it fails or hangs, bisect.
