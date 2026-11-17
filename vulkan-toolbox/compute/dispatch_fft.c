/*
 * ============================================================================
 * DISPATCH_FFT — host skeleton for the staged butterfly transform
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   A skeleton is not a ruin; it is a frame that stands plumb and
 *   says exactly which walls are not yet hung. This file carries the
 *   full Vulkan road — instance, device, buffer, pipeline — and the
 *   stage loop that drives fft_butterfly.comp, and it verifies the
 *   one case whose answer is known before the machine speaks: the
 *   transform of a unit impulse is a flat line of ones. What it does
 *   not yet carry is named in the doctrine below, in the open.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM — the road:
 *   1. The host fills the buffer with the test signal (a unit impulse
 *      at index 0) and performs the bit-reversal permutation on the
 *      CPU — the shader's doctrine assigns the permutation to the
 *      host, once, so the stages can be pure butterflies.
 *   2. For stage s = 0 .. log2(n)-1, one command buffer pushes
 *      { n, s, direction } and dispatches ceil(n/2 / 256) workgroups;
 *      a vkCmdPipelineBarrier between stages makes each stage's
 *      writes visible to the next — in-place transforms live or die
 *      on that barrier, so it is written here, not assumed.
 *   3. Readback checks every sample against (1, 0) within 1e-3 and
 *      prints the largest error it found, pass or fail.
 *
 * DOCTRINE — what "skeleton" honestly means here:
 *   Present: device selection is "first compute queue" (as in the
 *   sum dispatch), error handling is the shared VKC discipline, and
 *   the stage loop is complete for power-of-two n.
 *   Absent, and named: a real-signal packing (two real FFTs in one
 *   complex pass), a subgroup-shuffle stage for the small spans, any
 *   non-power-of-two length, and timing instrumentation. Each is a
 *   wall to hang later; none is load-bearing for the verification
 *   this skeleton performs. Device-gated at run time, host-compiled
 *   by the toolbox tests.
 *
 * Usage: dispatch_fft [shader.spv] [n]   (n a power of two, >= 2)
 * ============================================================================
 */

#include <vulkan/vulkan.h>

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void die(const char *what, VkResult vr) {
    fprintf(stderr, "DISPATCH HALT: %s (VkResult %d)\n", what, vr);
    exit(2);
}

#define VKC(call) do { VkResult _r = (call); if (_r != VK_SUCCESS) die(#call, _r); } while (0)

struct Push {
    uint32_t n;
    uint32_t stage;
    int32_t  direction;
};

static uint32_t bit_reverse(uint32_t x, uint32_t bits) {
    uint32_t r = 0;
    for (uint32_t i = 0; i < bits; i++) {
        r = (r << 1) | (x & 1u);
        x >>= 1;
    }
    return r;
}

int main(int argc, char **argv) {
    const char *spv_path = (argc > 1) ? argv[1] : "fft_butterfly.spv";
    uint32_t n = (argc > 2) ? (uint32_t)strtoul(argv[2], NULL, 0) : 1024u;
    if (n < 2 || (n & (n - 1)) != 0) {
        fprintf(stderr, "DISPATCH HALT: n must be a power of two >= 2\n");
        return 2;
    }
    uint32_t stages = 0;
    while ((1u << stages) < n) stages++;

    /* --- SPIR-V from its file (build product, never an embedded blob) --- */
    FILE *f = fopen(spv_path, "rb");
    if (!f) {
        fprintf(stderr, "DISPATCH HALT: cannot open shader %s\n", spv_path);
        return 2;
    }
    fseek(f, 0, SEEK_END);
    long spv_size = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (spv_size <= 0 || (spv_size % 4) != 0) {
        fprintf(stderr, "DISPATCH HALT: shader %s has a bad size (%ld)\n",
                spv_path, spv_size);
        fclose(f);
        return 2;
    }
    uint32_t *spv = (uint32_t *)malloc((size_t)spv_size);
    if (fread(spv, 1, (size_t)spv_size, f) != (size_t)spv_size) {
        fprintf(stderr, "DISPATCH HALT: short read on %s\n", spv_path);
        fclose(f);
        return 2;
    }
    fclose(f);

    /* --- instance and first compute device (the house pattern) --- */
    uint32_t instance_version = VK_API_VERSION_1_0;
    if (vkEnumerateInstanceVersion(&instance_version) != VK_SUCCESS) {
        instance_version = VK_API_VERSION_1_0;
    }
    VkApplicationInfo app;
    memset(&app, 0, sizeof(app));
    app.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app.pApplicationName = "dispatch-fft";
    app.apiVersion = (instance_version >= VK_API_VERSION_1_1)
                         ? VK_API_VERSION_1_1 : VK_API_VERSION_1_0;
    VkInstanceCreateInfo ici;
    memset(&ici, 0, sizeof(ici));
    ici.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ici.pApplicationInfo = &app;
    VkInstance instance;
    VKC(vkCreateInstance(&ici, NULL, &instance));

    uint32_t dcount = 0;
    VKC(vkEnumeratePhysicalDevices(instance, &dcount, NULL));
    if (dcount == 0) {
        fprintf(stderr, "DISPATCH HALT: no physical devices\n");
        return 3;
    }
    VkPhysicalDevice *devices =
        (VkPhysicalDevice *)malloc(sizeof(VkPhysicalDevice) * dcount);
    VKC(vkEnumeratePhysicalDevices(instance, &dcount, devices));
    VkPhysicalDevice phys = VK_NULL_HANDLE;
    uint32_t queue_family = 0;
    VkPhysicalDeviceProperties chosen_props;
    memset(&chosen_props, 0, sizeof(chosen_props));
    for (uint32_t i = 0; i < dcount && phys == VK_NULL_HANDLE; i++) {
        uint32_t qcount = 0;
        vkGetPhysicalDeviceQueueFamilyProperties(devices[i], &qcount, NULL);
        VkQueueFamilyProperties *qf = (VkQueueFamilyProperties *)malloc(
            sizeof(VkQueueFamilyProperties) * (qcount ? qcount : 1));
        vkGetPhysicalDeviceQueueFamilyProperties(devices[i], &qcount, qf);
        for (uint32_t q = 0; q < qcount; q++) {
            if (qf[q].queueFlags & VK_QUEUE_COMPUTE_BIT) {
                phys = devices[i];
                queue_family = q;
                vkGetPhysicalDeviceProperties(devices[i], &chosen_props);
                break;
            }
        }
        free(qf);
    }
    free(devices);
    if (phys == VK_NULL_HANDLE) {
        fprintf(stderr, "DISPATCH HALT: no device with a compute queue\n");
        return 3;
    }
    printf("device      : %s\n", chosen_props.deviceName);
    printf("n           : %u samples, %u stages\n", n, stages);

    float priority = 1.0f;
    VkDeviceQueueCreateInfo qci;
    memset(&qci, 0, sizeof(qci));
    qci.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    qci.queueFamilyIndex = queue_family;
    qci.queueCount = 1;
    qci.pQueuePriorities = &priority;
    VkDeviceCreateInfo dci;
    memset(&dci, 0, sizeof(dci));
    dci.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    dci.queueCreateInfoCount = 1;
    dci.pQueueCreateInfos = &qci;
    VkDevice device;
    VKC(vkCreateDevice(phys, &dci, NULL, &device));
    VkQueue queue;
    vkGetDeviceQueue(device, queue_family, 0, &queue);

    /* --- the one data buffer: n complex samples, host-visible --- */
    VkDeviceSize buf_size = sizeof(float) * 2u * n;
    VkBufferCreateInfo bci;
    memset(&bci, 0, sizeof(bci));
    bci.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bci.size = buf_size;
    bci.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
    bci.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    VkBuffer buffer;
    VKC(vkCreateBuffer(device, &bci, NULL, &buffer));
    VkMemoryRequirements req;
    vkGetBufferMemoryRequirements(device, buffer, &req);
    VkPhysicalDeviceMemoryProperties memprops;
    vkGetPhysicalDeviceMemoryProperties(phys, &memprops);
    uint32_t mem_type = UINT32_MAX;
    for (uint32_t i = 0; i < memprops.memoryTypeCount; i++) {
        if ((req.memoryTypeBits & (1u << i)) &&
            (memprops.memoryTypes[i].propertyFlags &
             (VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
              VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)) ==
                (VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
                 VK_MEMORY_PROPERTY_HOST_COHERENT_BIT)) {
            mem_type = i;
            break;
        }
    }
    if (mem_type == UINT32_MAX) {
        fprintf(stderr, "DISPATCH HALT: no host-visible coherent memory\n");
        return 2;
    }
    VkMemoryAllocateInfo mai;
    memset(&mai, 0, sizeof(mai));
    mai.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    mai.allocationSize = req.size;
    mai.memoryTypeIndex = mem_type;
    VkDeviceMemory memory;
    VKC(vkAllocateMemory(device, &mai, NULL, &memory));
    VKC(vkBindBufferMemory(device, buffer, memory, 0));

    /* Fill: unit impulse at index 0, then the host's bit-reversal. */
    void *mapped = NULL;
    VKC(vkMapMemory(device, memory, 0, buf_size, 0, &mapped));
    float *data = (float *)mapped;
    memset(data, 0, (size_t)buf_size);
    data[0] = 1.0f; /* sample 0 = (1, 0); all others (0, 0) */
    for (uint32_t i = 0; i < n; i++) {
        uint32_t j = bit_reverse(i, stages);
        if (j > i) {
            float xr = data[2 * i], xi = data[2 * i + 1];
            data[2 * i]     = data[2 * j];
            data[2 * i + 1] = data[2 * j + 1];
            data[2 * j]     = xr;
            data[2 * j + 1] = xi;
        }
    }
    vkUnmapMemory(device, memory);

    /* --- descriptors, layout, pipeline (one binding, read-write) --- */
    VkDescriptorSetLayoutBinding binding;
    memset(&binding, 0, sizeof(binding));
    binding.binding = 0;
    binding.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    binding.descriptorCount = 1;
    binding.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
    VkDescriptorSetLayoutCreateInfo lci;
    memset(&lci, 0, sizeof(lci));
    lci.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    lci.bindingCount = 1;
    lci.pBindings = &binding;
    VkDescriptorSetLayout set_layout;
    VKC(vkCreateDescriptorSetLayout(device, &lci, NULL, &set_layout));

    VkDescriptorPoolSize pool_size;
    memset(&pool_size, 0, sizeof(pool_size));
    pool_size.type = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    pool_size.descriptorCount = 1;
    VkDescriptorPoolCreateInfo pci;
    memset(&pci, 0, sizeof(pci));
    pci.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
    pci.maxSets = 1;
    pci.poolSizeCount = 1;
    pci.pPoolSizes = &pool_size;
    VkDescriptorPool pool;
    VKC(vkCreateDescriptorPool(device, &pci, NULL, &pool));

    VkDescriptorSetAllocateInfo sai;
    memset(&sai, 0, sizeof(sai));
    sai.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
    sai.descriptorPool = pool;
    sai.descriptorSetCount = 1;
    sai.pSetLayouts = &set_layout;
    VkDescriptorSet set;
    VKC(vkAllocateDescriptorSets(device, &sai, &set));

    VkDescriptorBufferInfo info;
    memset(&info, 0, sizeof(info));
    info.buffer = buffer;
    info.range = VK_WHOLE_SIZE;
    VkWriteDescriptorSet write;
    memset(&write, 0, sizeof(write));
    write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    write.dstSet = set;
    write.dstBinding = 0;
    write.descriptorCount = 1;
    write.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    write.pBufferInfo = &info;
    vkUpdateDescriptorSets(device, 1, &write, 0, NULL);

    VkPushConstantRange pcr;
    memset(&pcr, 0, sizeof(pcr));
    pcr.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
    pcr.offset = 0;
    pcr.size = sizeof(struct Push);
    VkPipelineLayoutCreateInfo plci;
    memset(&plci, 0, sizeof(plci));
    plci.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
    plci.setLayoutCount = 1;
    plci.pSetLayouts = &set_layout;
    plci.pushConstantRangeCount = 1;
    plci.pPushConstantRanges = &pcr;
    VkPipelineLayout pipeline_layout;
    VKC(vkCreatePipelineLayout(device, &plci, NULL, &pipeline_layout));

    VkShaderModuleCreateInfo smci;
    memset(&smci, 0, sizeof(smci));
    smci.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
    smci.codeSize = (size_t)spv_size;
    smci.pCode = spv;
    VkShaderModule shader;
    VKC(vkCreateShaderModule(device, &smci, NULL, &shader));
    free(spv);

    VkComputePipelineCreateInfo cpci;
    memset(&cpci, 0, sizeof(cpci));
    cpci.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
    cpci.stage.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
    cpci.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
    cpci.stage.module = shader;
    cpci.stage.pName = "main";
    cpci.layout = pipeline_layout;
    VkPipeline pipeline;
    VKC(vkCreateComputePipelines(device, VK_NULL_HANDLE, 1, &cpci, NULL, &pipeline));

    /* --- one command buffer, all stages, barriers between them --- */
    VkCommandPoolCreateInfo cpi;
    memset(&cpi, 0, sizeof(cpi));
    cpi.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
    cpi.queueFamilyIndex = queue_family;
    VkCommandPool cmd_pool;
    VKC(vkCreateCommandPool(device, &cpi, NULL, &cmd_pool));
    VkCommandBufferAllocateInfo cbai;
    memset(&cbai, 0, sizeof(cbai));
    cbai.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    cbai.commandPool = cmd_pool;
    cbai.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    cbai.commandBufferCount = 1;
    VkCommandBuffer cmd;
    VKC(vkAllocateCommandBuffers(device, &cbai, &cmd));

    VkCommandBufferBeginInfo begin;
    memset(&begin, 0, sizeof(begin));
    begin.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
    begin.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;
    VKC(vkBeginCommandBuffer(cmd, &begin));
    vkCmdBindPipeline(cmd, VK_PIPELINE_BIND_POINT_COMPUTE, pipeline);
    vkCmdBindDescriptorSets(cmd, VK_PIPELINE_BIND_POINT_COMPUTE,
                            pipeline_layout, 0, 1, &set, 0, NULL);
    uint32_t groups = (n / 2 + 255) / 256;
    for (uint32_t s = 0; s < stages; s++) {
        struct Push push;
        push.n = n;
        push.stage = s;
        push.direction = -1; /* forward */
        vkCmdPushConstants(cmd, pipeline_layout, VK_SHADER_STAGE_COMPUTE_BIT,
                           0, sizeof(push), &push);
        vkCmdDispatch(cmd, groups, 1, 1);
        if (s + 1 < stages) {
            VkMemoryBarrier barrier;
            memset(&barrier, 0, sizeof(barrier));
            barrier.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER;
            barrier.srcAccessMask = VK_ACCESS_SHADER_WRITE_BIT;
            barrier.dstAccessMask = VK_ACCESS_SHADER_READ_BIT |
                                    VK_ACCESS_SHADER_WRITE_BIT;
            vkCmdPipelineBarrier(cmd,
                                 VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
                                 VK_PIPELINE_STAGE_COMPUTE_SHADER_BIT,
                                 0, 1, &barrier, 0, NULL, 0, NULL);
        }
    }
    VKC(vkEndCommandBuffer(cmd));

    VkFenceCreateInfo fci;
    memset(&fci, 0, sizeof(fci));
    fci.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
    VkFence fence;
    VKC(vkCreateFence(device, &fci, NULL, &fence));
    VkSubmitInfo submit;
    memset(&submit, 0, sizeof(submit));
    submit.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
    submit.commandBufferCount = 1;
    submit.pCommandBuffers = &cmd;
    VKC(vkQueueSubmit(queue, 1, &submit, fence));
    VKC(vkWaitForFences(device, 1, &fence, VK_TRUE, UINT64_MAX));

    /* --- verdict: the impulse's transform is a flat line of ones --- */
    VKC(vkMapMemory(device, memory, 0, buf_size, 0, &mapped));
    data = (float *)mapped;
    double worst = 0.0;
    for (uint32_t i = 0; i < n; i++) {
        double er = fabs((double)data[2 * i] - 1.0);
        double ei = fabs((double)data[2 * i + 1]);
        if (er > worst) worst = er;
        if (ei > worst) worst = ei;
    }
    printf("worst error : %g (tolerance 1e-3)\n", worst);
    int pass = (worst <= 1e-3);
    printf("VERDICT     : %s\n", pass ? "PASS — the stages compose true" : "FAIL");
    vkUnmapMemory(device, memory);

    vkDestroyFence(device, fence, NULL);
    vkDestroyCommandPool(device, cmd_pool, NULL);
    vkDestroyPipeline(device, pipeline, NULL);
    vkDestroyShaderModule(device, shader, NULL);
    vkDestroyPipelineLayout(device, pipeline_layout, NULL);
    vkDestroyDescriptorPool(device, pool, NULL);
    vkDestroyDescriptorSetLayout(device, set_layout, NULL);
    vkDestroyBuffer(device, buffer, NULL);
    vkFreeMemory(device, memory, NULL);
    vkDestroyDevice(device, NULL);
    vkDestroyInstance(instance, NULL);
    return pass ? 0 : 4;
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
