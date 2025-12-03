#include <windows.h>
#include <stdio.h>

int main() {
    // 1. Architecture check
    BOOL isWow64 = FALSE;
    IsWow64Process(GetCurrentProcess(), &isWow64);
    printf("🧠 IsWow64: %s\n", isWow64 ? "Yes (32-bit Wine on 64-bit)" : "No (native 64-bit)");

    SYSTEM_INFO sysInfo;
    GetNativeSystemInfo(&sysInfo);
    printf("🧬 Processor architecture: ");
    switch (sysInfo.wProcessorArchitecture) {
        case PROCESSOR_ARCHITECTURE_AMD64: printf("AMD64 (x64)\n"); break;
        case PROCESSOR_ARCHITECTURE_INTEL: printf("x86 (32-bit)\n"); break;
        case PROCESSOR_ARCHITECTURE_ARM64: printf("ARM64\n"); break;
        default: printf("Other (%u)\n", sysInfo.wProcessorArchitecture);
    }

    printf("📏 sizeof(void*) = %lu\n\n", sizeof(void*));

    // 2. VirtualAlloc test (6GB)
    SIZE_T size = 6ULL * 1024 * 1024 * 1024;
    void* mem = VirtualAlloc(NULL, size, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (mem == NULL) {
        DWORD err = GetLastError();
        printf("❌ VirtualAlloc of 6GB failed (error code %lu)\n", err);
        return 1;
    } else {
        printf("✅ VirtualAlloc of 6GB succeeded\n");
        return 0;
    }
}