/*
 * ============================================================================
 * DISPATCH_PARALLEL_SUM — the host half of the fan-in
 * ----------------------------------------------------------------------------
 * "Do what thou wilt shall be the whole of the Law."
 *   The shader folds; the host must carry the folded result home and
 *   swear to it. This program builds the smallest complete Vulkan
 *   compute road — instance, device, buffers, pipeline, dispatch,
 *   readback — and then checks the GPU's arithmetic against the
 *   answer it already knows: a million ones sum to a million, or
 *   something on the road is lying and the program says so.
 *
 * Authorship attributed exclusively to Johnathan "Qasparr" Monroe
 * (Greek, -ARR, All Rights Reserved, Without Prejudice).
 * XVI day of November, Dies Lunae, Sol in Scorpio, Anno V:xii e.n.
 * (2026 e.v.). Method of Science, Aim of Religion. 93.
 *
 * MECHANISM — the road, in order:
 *   1. Instance at the highest of {1.0, 1.1} the loader offers
 *      (the same discipline as caps-probe).
 *   2. The first physical device with a COMPUTE queue family is
 *      taken. Not the "best" — the first that can do the work; a
 *      bench tool that shops for hardware is a benchmark, and this
 *      is not one.
 *   3. Two device buffers — input (count floats) and partials (one
 *      float per workgroup) — each backed by HOST_VISIBLE |
 *      HOST_COHERENT memory, so no staging dance stands between the
 *      test and the truth. On the Mali's unified memory this is also
 *      the honest shape of the hardware.
 *   4. The SPIR-V module is loaded from a file named on the command
 *      line (default: parallel_sum.spv beside the working directory)
 *      — compiled shaders are build products, never embedded blobs,
 *      so the artifact under test is the artifact that ships.
 *   5. One dispatch: workgroups = ceil(count / 256), the count rides
 *      as a push constant, a fence waits, the partials are mapped
 *      and summed on the host in double precision.
 *   6. THE VERDICT. The input is all ones, so every partial is an
 *      integer no larger than 256 — exact in fp32 — and the host's
 *      double sum is exact. Total == count is therefore a fair test,
 *      not a hope: PASS prints and exit is 0; anything else prints
 *      both numbers and exits 4.
 *
 * DOCTRINE — device-gated at run time, like the probe: compiled on
 * the host by the toolbox tests, run on the A16 (or any Vulkan
 * device) by the operator. Nothing here is emulated or mocked; a
 * road that has not been driven is labelled a road, not a journey.
 *
 * Usage: dispatch_parallel_sum [shader.spv] [count]
 * ============================================================================
 */

#include <vulkan/vulkan.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define WORKGROUP 256u

static void die(const char *what, VkResult vr) {
    fprintf(stderr, "DISPATCH HALT: %s (VkResult %d)\n", what, vr);
    exit(2);
}

#define VKC(call) do { VkResult _r = (call); if (_r != VK_SUCCESS) die(#call, _r); } while (0)

static uint32_t find_memory_type(VkPhysicalDevice dev, uint32_t type_bits,
                                 VkMemoryPropertyFlags wanted) {
    VkPhysicalDeviceMemoryProperties mem;
    vkGetPhysicalDeviceMemoryProperties(dev, &mem);
    for (uint32_t i = 0; i < mem.memoryTypeCount; i++) {
        if ((type_bits & (1u << i)) &&
            (mem.memoryTypes[i].propertyFlags & wanted) == wanted) {
            return i;
        }
    }
    fprintf(stderr, "DISPATCH HALT: no memory type with the wanted flags\n");
    exit(2);
}

static void make_buffer(VkDevice device, VkPhysicalDevice phys, VkDeviceSize size,
                        VkBuffer *out_buffer, VkDeviceMemory *out_memory) {
    VkBufferCreateInfo bci;
    memset(&bci, 0, sizeof(bci));
    bci.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bci.size = size;
    bci.usage = VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
    bci.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    VKC(vkCreateBuffer(device, &bci, NULL, out_buffer));

    VkMemoryRequirements req;
    vkGetBufferMemoryRequirements(device, *out_buffer, &req);

    VkMemoryAllocateInfo mai;
    memset(&mai, 0, sizeof(mai));
    mai.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    mai.allocationSize = req.size;
    mai.memoryTypeIndex = find_memory_type(
        phys, req.memoryTypeBits,
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    VKC(vkAllocateMemory(device, &mai, NULL, out_memory));
    VKC(vkBindBufferMemory(device, *out_buffer, *out_memory, 0));
}

int main(int argc, char **argv) {
    const char *spv_path = (argc > 1) ? argv[1] : "parallel_sum.spv";
    uint32_t count = (argc > 2) ? (uint32_t)strtoul(argv[2], NULL, 0)
                                : (1u << 20);
    if (count == 0) {
        fprintf(stderr, "DISPATCH HALT: count must be positive\n");
        return 2;
    }
    uint32_t workgroups = (count + WORKGROUP - 1) / WORKGROUP;

    /* --- the SPIR-V, read whole from its file --- */
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

    /* --- instance --- */
    uint32_t instance_version = VK_API_VERSION_1_0;
    if (vkEnumerateInstanceVersion(&instance_version) != VK_SUCCESS) {
        instance_version = VK_API_VERSION_1_0;
    }
    uint32_t requested = (instance_version >= VK_API_VERSION_1_1)
                             ? VK_API_VERSION_1_1 : VK_API_VERSION_1_0;

    VkApplicationInfo app;
    memset(&app, 0, sizeof(app));
    app.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    app.pApplicationName = "dispatch-parallel-sum";
    app.apiVersion = requested;

    VkInstanceCreateInfo ici;
    memset(&ici, 0, sizeof(ici));
    ici.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    ici.pApplicationInfo = &app;

    VkInstance instance;
    VKC(vkCreateInstance(&ici, NULL, &instance));

    /* --- first device with a compute queue --- */
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
        VkQueueFamilyProperties *qf =
            (VkQueueFamilyProperties *)malloc(sizeof(VkQueueFamilyProperties) * (qcount ? qcount : 1));
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
    printf("count       : %u elements, %u workgroups of %u\n",
           count, workgroups, WORKGROUP);

    /* --- logical device --- */
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

    /* --- buffers, filled and zeroed --- */
    VkBuffer in_buffer, part_buffer;
    VkDeviceMemory in_memory, part_memory;
    make_buffer(device, phys, sizeof(float) * count, &in_buffer, &in_memory);
    make_buffer(device, phys, sizeof(float) * workgroups, &part_buffer, &part_memory);

    void *mapped = NULL;
    VKC(vkMapMemory(device, in_memory, 0, sizeof(float) * count, 0, &mapped));
    float *input = (float *)mapped;
    for (uint32_t i = 0; i < count; i++) input[i] = 1.0f;
    vkUnmapMemory(device, in_memory);

    VKC(vkMapMemory(device, part_memory, 0, sizeof(float) * workgroups, 0, &mapped));
    memset(mapped, 0, sizeof(float) * workgroups);
    vkUnmapMemory(device, part_memory);

    /* --- descriptor set: binding 0 = input, binding 1 = partials --- */
    VkDescriptorSetLayoutBinding bindings[2];
    memset(bindings, 0, sizeof(bindings));
    for (int i = 0; i < 2; i++) {
        bindings[i].binding = (uint32_t)i;
        bindings[i].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
        bindings[i].descriptorCount = 1;
        bindings[i].stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
    }
    VkDescriptorSetLayoutCreateInfo lci;
    memset(&lci, 0, sizeof(lci));
    lci.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
    lci.bindingCount = 2;
    lci.pBindings = bindings;
    VkDescriptorSetLayout set_layout;
    VKC(vkCreateDescriptorSetLayout(device, &lci, NULL, &set_layout));

    VkDescriptorPoolSize pool_size;
    memset(&pool_size, 0, sizeof(pool_size));
    pool_size.type = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
    pool_size.descriptorCount = 2;
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

    VkDescriptorBufferInfo infos[2];
    memset(infos, 0, sizeof(infos));
    infos[0].buffer = in_buffer;
    infos[0].range = VK_WHOLE_SIZE;
    infos[1].buffer = part_buffer;
    infos[1].range = VK_WHOLE_SIZE;
    VkWriteDescriptorSet writes[2];
    memset(writes, 0, sizeof(writes));
    for (int i = 0; i < 2; i++) {
        writes[i].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
        writes[i].dstSet = set;
        writes[i].dstBinding = (uint32_t)i;
        writes[i].descriptorCount = 1;
        writes[i].descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_BUFFER;
        writes[i].pBufferInfo = &infos[i];
    }
    vkUpdateDescriptorSets(device, 2, writes, 0, NULL);

    /* --- pipeline: push constant carries the count --- */
    VkPushConstantRange pcr;
    memset(&pcr, 0, sizeof(pcr));
    pcr.stageFlags = VK_SHADER_STAGE_COMPUTE_BIT;
    pcr.offset = 0;
    pcr.size = sizeof(uint32_t);

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

    /* --- command buffer: bind, push, dispatch --- */
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
    vkCmdPushConstants(cmd, pipeline_layout, VK_SHADER_STAGE_COMPUTE_BIT,
                       0, sizeof(uint32_t), &count);
    vkCmdDispatch(cmd, workgroups, 1, 1);
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

    /* --- readback and the verdict --- */
    VKC(vkMapMemory(device, part_memory, 0, sizeof(float) * workgroups, 0, &mapped));
    float *partials = (float *)mapped;
    double total = 0.0;
    for (uint32_t i = 0; i < workgroups; i++) total += (double)partials[i];
    printf("partial[0]  : %f\n", partials[0]);
    printf("total       : %f\n", total);
    printf("expected    : %u\n", count);
    int pass = (total == (double)count);
    printf("VERDICT     : %s\n", pass ? "PASS — the fan-in is true" : "FAIL");
    vkUnmapMemory(device, part_memory);

    /* --- teardown, in reverse order of birth --- */
    vkDestroyFence(device, fence, NULL);
    vkDestroyCommandPool(device, cmd_pool, NULL);
    vkDestroyPipeline(device, pipeline, NULL);
    vkDestroyShaderModule(device, shader, NULL);
    vkDestroyPipelineLayout(device, pipeline_layout, NULL);
    vkDestroyDescriptorPool(device, pool, NULL);
    vkDestroyDescriptorSetLayout(device, set_layout, NULL);
    vkDestroyBuffer(device, in_buffer, NULL);
    vkDestroyBuffer(device, part_buffer, NULL);
    vkFreeMemory(device, in_memory, NULL);
    vkFreeMemory(device, part_memory, NULL);
    vkDestroyDevice(device, NULL);
    vkDestroyInstance(instance, NULL);
    return pass ? 0 : 4;
}

/*
 * ============================================================================
 * 93 — Live, Love, and let Love, Live.
 * ============================================================================
 */
