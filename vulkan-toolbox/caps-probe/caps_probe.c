/*
 * ============================================================================
 * CAPS-PROBE — the Vulkan dossier of the Exynos 1330's Mali-G68
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   A specification sheet is a claim; a readout is a witness. This probe
 *   does not recite what the Mali-G68 is supposed to be — it asks the
 *   driver, on the device, what the driver exposes, and prints the
 *   answer whole: the version, the name, the limits, the queues, the
 *   extensions. Where the public sheets disagree with each other (and
 *   on this GPU's Vulkan version, they do), the readout is the court.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM — what this program does, in order:
 *   1. Asks the loader for the instance version it speaks
 *      (vkEnumerateInstanceVersion; on a Vulkan 1.0 loader the call is
 *      absent and the version is 1.0 by definition).
 *   2. Creates a bare instance — no layers, no extensions — requesting
 *      Vulkan 1.1 when the loader offers it, else 1.0. 1.1 is the
 *      floor this toolbox designs against: storage buffers and push
 *      constants are 1.0 core, but subgroup properties (printed below)
 *      arrive through the 1.1 properties chain.
 *   3. For every physical device, prints a DOSSIER:
 *        - identity: device name, vendor ID (with the courtesy decode
 *          for the common vendors; the number is the fact, the name is
 *          the gloss), device ID, device type, API version, driver
 *          version (raw, and decoded per the vendor's own scheme where
 *          the scheme is public: Khronos vendors pack it as
 *          major<<22 | minor<<12 | patch);
 *        - subgroup size and stages, when the 1.1 chain answers;
 *        - the compute-relevant limits, named one by one;
 *        - memory heaps (size, DEVICE_LOCAL or not) and memory types
 *          (property flags decoded);
 *        - queue families (flags decoded: GRAPHICS / COMPUTE /
 *          TRANSFER / SPARSE_BINDING / PROTECTED), with queue counts;
 *        - every device extension the driver offers, by name.
 *   4. Exits 0 when at least one device was dossiered. Exit 2 when the
 *      instance cannot be created (no Vulkan on the target), exit 3
 *      when the instance lives but no physical device answers. The
 *      codes are distinct so a script can tell "no Vulkan" from
 *      "Vulkan, but no GPU" without parsing prose.
 *
 * DOCTRINE — where this runs, and where it cannot:
 *   This is an Android NDK program. It links the NDK's libvulkan stub
 *   and runs as a standalone executable under `adb shell` (or inside
 *   any app's native library path). It is compiled on the host —
 *   build.sh beside this file does that, and the toolbox test suite
 *   proves the compilation — but it can only be RUN on the device.
 *   This host has no Vulkan loader and no Mali; a host run is not
 *   faked, it is simply not claimed. DEVICE-GATED at run time,
 *   host-proven at build time: that is the honest shape of it.
 * ============================================================================
 */

#include <vulkan/vulkan.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ------------------------------------------------------------------ */
/* Small printers. The dossier is prose-shaped on purpose: it is      */
/* meant to be pasted into a record and read by a person.             */
/* ------------------------------------------------------------------ */

static void print_api_version(const char *label, uint32_t v) {
    printf("%s%u.%u.%u (raw 0x%08x)\n", label,
           VK_API_VERSION_MAJOR(v), VK_API_VERSION_MINOR(v),
           VK_API_VERSION_PATCH(v), v);
}

static const char *device_type_name(VkPhysicalDeviceType t) {
    switch (t) {
        case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:  return "INTEGRATED_GPU";
        case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:    return "DISCRETE_GPU";
        case VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU:     return "VIRTUAL_GPU";
        case VK_PHYSICAL_DEVICE_TYPE_CPU:             return "CPU";
        case VK_PHYSICAL_DEVICE_TYPE_OTHER:           return "OTHER";
        default:                                      return "UNKNOWN";
    }
}

static const char *vendor_gloss(uint32_t vendor_id) {
    switch (vendor_id) {
        case 0x13B5: return "ARM";
        case 0x5143: return "Qualcomm";
        case 0x1010: return "Imagination Technologies";
        case 0x1002: return "AMD";
        case 0x10DE: return "NVIDIA";
        case 0x8086: return "Intel";
        default:     return "undecoded — the number is the fact";
    }
}

static void print_memory_flags(VkMemoryPropertyFlags f) {
    int first = 1;
    printf("[");
    if (f & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT)        { printf("%sDEVICE_LOCAL", first ? "" : " | ");        first = 0; }
    if (f & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)        { printf("%sHOST_VISIBLE", first ? "" : " | ");        first = 0; }
    if (f & VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)       { printf("%sHOST_COHERENT", first ? "" : " | ");       first = 0; }
    if (f & VK_MEMORY_PROPERTY_HOST_CACHED_BIT)         { printf("%sHOST_CACHED", first ? "" : " | ");         first = 0; }
    if (f & VK_MEMORY_PROPERTY_LAZILY_ALLOCATED_BIT)    { printf("%sLAZILY_ALLOCATED", first ? "" : " | ");    first = 0; }
    if (f & VK_MEMORY_PROPERTY_PROTECTED_BIT)           { printf("%sPROTECTED", first ? "" : " | ");           first = 0; }
    if (first) printf("none");
    printf("]");
}

static void print_queue_flags(VkQueueFlags f) {
    int first = 1;
    printf("[");
    if (f & VK_QUEUE_GRAPHICS_BIT)        { printf("%sGRAPHICS", first ? "" : " | ");        first = 0; }
    if (f & VK_QUEUE_COMPUTE_BIT)         { printf("%sCOMPUTE", first ? "" : " | ");         first = 0; }
    if (f & VK_QUEUE_TRANSFER_BIT)        { printf("%sTRANSFER", first ? "" : " | ");        first = 0; }
    if (f & VK_QUEUE_SPARSE_BINDING_BIT)  { printf("%sSPARSE_BINDING", first ? "" : " | ");  first = 0; }
    if (f & VK_QUEUE_PROTECTED_BIT)       { printf("%sPROTECTED", first ? "" : " | ");       first = 0; }
    if (first) printf("none");
    printf("]");
}

/* ------------------------------------------------------------------ */
/* The dossier for one physical device.                               */
/* ------------------------------------------------------------------ */

static void dossier(VkPhysicalDevice dev, uint32_t index) {
    VkPhysicalDeviceProperties props;
    vkGetPhysicalDeviceProperties(dev, &props);

    printf("\n================================================================\n");
    printf("PHYSICAL DEVICE %u — DOSSIER\n", index);
    printf("================================================================\n");
    printf("deviceName        : %s\n", props.deviceName);
    printf("vendorID          : 0x%04x (%s)\n", props.vendorID,
           vendor_gloss(props.vendorID));
    printf("deviceID          : 0x%04x\n", props.deviceID);
    printf("deviceType        : %s\n", device_type_name(props.deviceType));
    print_api_version("apiVersion        : ", props.apiVersion);
    printf("driverVersion     : raw 0x%08x (Khronos packing: %u.%u.%u)\n",
           props.driverVersion,
           props.driverVersion >> 22,
           (props.driverVersion >> 12) & 0x3FF,
           props.driverVersion & 0xFFF);
    printf("pipelineCacheUUID : ");
    for (uint32_t i = 0; i < VK_UUID_SIZE; i++) printf("%02x", props.pipelineCacheUUID[i]);
    printf("\n");

    /* Subgroup properties ride the 1.1 properties chain. On a 1.0-only
     * device the chain call is skipped and the dossier says so —
     * an absent answer is printed as absent, never as zero. */
    if (props.apiVersion >= VK_API_VERSION_1_1) {
        VkPhysicalDeviceSubgroupProperties subgroup;
        memset(&subgroup, 0, sizeof(subgroup));
        subgroup.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SUBGROUP_PROPERTIES;

        VkPhysicalDeviceProperties2 props2;
        memset(&props2, 0, sizeof(props2));
        props2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2;
        props2.pNext = &subgroup;

        vkGetPhysicalDeviceProperties2(dev, &props2);
        printf("subgroupSize      : %u\n", subgroup.subgroupSize);
        printf("subgroupStages    : 0x%08x\n", subgroup.supportedStages);
        printf("subgroupOps       : 0x%08x\n", subgroup.supportedOperations);
        printf("subgroupQuadAllRanks : %s\n",
               subgroup.quadOperationsInAllStages ? "true" : "false");
    } else {
        printf("subgroup          : not queried (device API < 1.1)\n");
    }

    const VkPhysicalDeviceLimits *lim = &props.limits;
    printf("\n-- limits (the compute-relevant seats) --\n");
    printf("maxComputeWorkGroupCount       : %u x %u x %u\n",
           lim->maxComputeWorkGroupCount[0], lim->maxComputeWorkGroupCount[1],
           lim->maxComputeWorkGroupCount[2]);
    printf("maxComputeWorkGroupSize        : %u x %u x %u\n",
           lim->maxComputeWorkGroupSize[0], lim->maxComputeWorkGroupSize[1],
           lim->maxComputeWorkGroupSize[2]);
    printf("maxComputeWorkGroupInvocations : %u\n", lim->maxComputeWorkGroupInvocations);
    printf("maxComputeSharedMemorySize     : %u bytes\n", lim->maxComputeSharedMemorySize);
    printf("maxPushConstantsSize           : %u bytes\n", lim->maxPushConstantsSize);
    printf("maxBoundDescriptorSets         : %u\n", lim->maxBoundDescriptorSets);
    printf("maxStorageBufferRange          : %llu bytes\n",
           (unsigned long long)lim->maxStorageBufferRange);
    printf("maxMemoryAllocationCount       : %u\n", lim->maxMemoryAllocationCount);
    printf("maxSamplerAllocationCount      : %u\n", lim->maxSamplerAllocationCount);
    printf("timestampPeriod (ns per tick)  : %f\n", lim->timestampPeriod);

    VkPhysicalDeviceMemoryProperties mem;
    vkGetPhysicalDeviceMemoryProperties(dev, &mem);
    printf("\n-- memory --\n");
    for (uint32_t i = 0; i < mem.memoryHeapCount; i++) {
        printf("heap %u : %llu bytes %s\n", i,
               (unsigned long long)mem.memoryHeaps[i].size,
               (mem.memoryHeaps[i].flags & VK_MEMORY_HEAP_DEVICE_LOCAL_BIT)
                   ? "[DEVICE_LOCAL]" : "[host-side]");
    }
    for (uint32_t i = 0; i < mem.memoryTypeCount; i++) {
        printf("type %u : heap %u ", i, mem.memoryTypes[i].heapIndex);
        print_memory_flags(mem.memoryTypes[i].propertyFlags);
        printf("\n");
    }

    uint32_t qcount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(dev, &qcount, NULL);
    VkQueueFamilyProperties *queues =
        (VkQueueFamilyProperties *)malloc(sizeof(VkQueueFamilyProperties) * (qcount ? qcount : 1));
    vkGetPhysicalDeviceQueueFamilyProperties(dev, &qcount, queues);
    printf("\n-- queue families (%u) --\n", qcount);
    for (uint32_t i = 0; i < qcount; i++) {
        printf("family %u : %u queues ", i, queues[i].queueCount);
        print_queue_flags(queues[i].queueFlags);
        printf(" timestampValidBits=%u\n", queues[i].timestampValidBits);
    }
    free(queues);

    uint32_t ecount = 0;
    vkEnumerateDeviceExtensionProperties(dev, NULL, &ecount, NULL);
    VkExtensionProperties *exts =
        (VkExtensionProperties *)malloc(sizeof(VkExtensionProperties) * (ecount ? ecount : 1));
    vkEnumerateDeviceExtensionProperties(dev, NULL, &ecount, exts);
    printf("\n-- device extensions (%u) --\n", ecount);
    for (uint32_t i = 0; i < ecount; i++) {
        printf("  %s (spec %u)\n", exts[i].extensionName, exts[i].specVersion);
    }
    free(exts);
}

/* ------------------------------------------------------------------ */

int main(void) {
    printf("CAPS-PROBE — Vulkan dossier\n");
    printf("=============================================================\n");

    /* Step 1 — the loader's own version. vkEnumerateInstanceVersion
     * exists on Vulkan 1.1+ loaders; the NDK stub exports the symbol,
     * and on a 1.0 target the call itself reports what it can. If it
     * fails, the loader speaks 1.0 and the probe proceeds on that. */
    uint32_t instance_version = VK_API_VERSION_1_0;
    VkResult vr = vkEnumerateInstanceVersion(&instance_version);
    if (vr != VK_SUCCESS) {
        instance_version = VK_API_VERSION_1_0;
        printf("instance version query failed (VkResult %d); assuming 1.0\n", vr);
    }
    print_api_version("loader instance version : ", instance_version);

    /* Step 2 — a bare instance, requesting the highest of {1.0, 1.1}
     * the loader already offered. Requesting more than the loader
     * speaks makes vkCreateInstance fail, and a probe that fails on
     * old iron teaches nothing. */
    uint32_t requested = (instance_version >= VK_API_VERSION_1_1)
                             ? VK_API_VERSION_1_1
                             : VK_API_VERSION_1_0;

    VkApplicationInfo app;
    memset(&app, 0, sizeof(app));
    app.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app.pApplicationName = "caps-probe";
    app.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    app.pEngineName = "qasparr-vulkan-toolbox";
    app.engineVersion = VK_MAKE_VERSION(1, 0, 0);
    app.apiVersion = requested;

    VkInstanceCreateInfo ci;
    memset(&ci, 0, sizeof(ci));
    ci.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ci.pApplicationInfo = &app;

    VkInstance instance = VK_NULL_HANDLE;
    vr = vkCreateInstance(&ci, NULL, &instance);
    if (vr != VK_SUCCESS) {
        printf("vkCreateInstance failed (VkResult %d) — no Vulkan here.\n", vr);
        return 2;
    }

    /* Step 3 — every physical device gets its dossier. */
    uint32_t dcount = 0;
    vr = vkEnumeratePhysicalDevices(instance, &dcount, NULL);
    if (vr != VK_SUCCESS || dcount == 0) {
        printf("no physical devices answered (VkResult %d, count %u).\n", vr, dcount);
        vkDestroyInstance(instance, NULL);
        return 3;
    }
    VkPhysicalDevice *devices =
        (VkPhysicalDevice *)malloc(sizeof(VkPhysicalDevice) * dcount);
    vkEnumeratePhysicalDevices(instance, &dcount, devices);
    printf("physical devices answering : %u\n", dcount);
    for (uint32_t i = 0; i < dcount; i++) {
        dossier(devices[i], i);
    }
    free(devices);

    vkDestroyInstance(instance, NULL);
    printf("\nCAPS-PROBE complete — the driver has spoken for itself.\n");
    return 0;
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
