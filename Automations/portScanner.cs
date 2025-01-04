using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Threading.Tasks;
using System.Linq;
using System.IO;
using System.Net.NetworkInformation;

class Program
{
    // Predefined port sets
    static Dictionary<string, List<int>> predefinedPorts = new Dictionary<string, List<int>>()
    {
        { "admin", new List<int> { 135, 139, 445, 3389, 5985, 5986 } },
        { "web", new List<int> { 21, 23, 25, 80, 443, 8080 } },
        { "top20", new List<int> { 21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445, 993, 995, 1723, 3306, 3389, 5900, 8080 } }
    };

    // Known Windows ports to filter out for Linux
    static List<int> knownWindowsPorts = new List<int> { 135, 139, 445, 3389, 5985, 5986 };

    // Method to test if a port is open
    static async Task<bool> TestPort(string host, int port, int timeout = 2000)
    {
        try
        {
            using (var tcpClient = new TcpClient())
            {
                var connectTask = tcpClient.ConnectAsync(host, port);
                var timeoutTask = Task.Delay(timeout);

                // Wait for the connection or timeout
                var completedTask = await Task.WhenAny(connectTask, timeoutTask);

                if (completedTask == connectTask && tcpClient.Connected)
                {
                    // Connection established (port is open)
                    return true;
                }
                else
                {
                    // Timeout or failure to connect, port is closed
                    return false;
                }
            }
        }
        catch
        {
            // Connection failure or any other exception, port is closed
            return false;
        }
    }

    // Method to scan ports on a single host
    static async Task ScanPorts(string host, List<int> ports, List<(string, List<int>, string, string)> results)
    {
        List<int> openPorts = new List<int>();

        foreach (int port in ports)
        {
            bool isOpen = await TestPort(host, port);
            if (isOpen)
            {
                openPorts.Add(port);
            }
        }

        // If there are open ports, store the result (including hostname if possible)
        if (openPorts.Any())
        {
            string resolvedHost = await ResolveHostname(host);
            string os = await GetOperatingSystem(host);

            // If the OS is Linux, filter out Windows-specific ports
            if (os == "Linux")
            {
                openPorts = openPorts.Where(port => !knownWindowsPorts.Contains(port)).ToList();
            }

            // Only add the result if there are still open ports
            if (openPorts.Any())
            {
                results.Add((host, openPorts, resolvedHost, os));
            }
        }
    }

    // Method to scan a subnet (CIDR)
    static async Task ScanSubnet(string subnet, List<int> ports, List<(string, List<int>, string, string)> results)
    {
        List<Task> tasks = new List<Task>();

        // Scan each IP in the subnet
        for (int i = 1; i <= 254; i++)
        {
            string ip = $"{subnet}.{i}";
            tasks.Add(Task.Run(async () =>
            {
                await ScanPorts(ip, ports, results);
            }));
        }

        await Task.WhenAll(tasks);
    }

    // Method to export scan results to a text file
    static async Task ExportToTextFile(List<(string, List<int>, string, string)> results, string filePath)
    {
        using (var writer = new StreamWriter(filePath))
        {
            // Write header
            await writer.WriteLineAsync("Port Scan Results");
            await writer.WriteLineAsync("IP Address/Hostname\tOperating System\tOpen Ports");

            // Write each result
            foreach (var result in results)
            {
                string openPorts = string.Join(", ", result.Item2);
                await writer.WriteLineAsync($"{result.Item1} ({result.Item3})\t{result.Item4}\t{openPorts}");
            }
        }

        Console.WriteLine($"Results saved to {filePath}");
    }

    // Method to resolve IP to Hostname (if possible)
    static async Task<string> ResolveHostname(string ip)
    {
        try
        {
            // Attempt to resolve the IP address to a hostname
            var hostEntry = await Dns.GetHostEntryAsync(ip);
            return hostEntry.HostName;
        }
        catch
        {
            // If resolution fails, return the IP itself
            return ip;
        }
    }

    // Method to get the operating system based on TTL
    static async Task<string> GetOperatingSystem(string host)
    {
        try
        {
            Ping ping = new Ping();
            PingReply reply = await ping.SendPingAsync(host, 1000); // 1-second timeout

            if (reply.Status == IPStatus.Success)
            {
                // Check TTL to infer OS
                if (reply.Options != null)
                {
                    int ttl = reply.Options.Ttl;

                    if (ttl == 128)
                    {
                        return "Windows"; // Common TTL for Windows
                    }
                    else if (ttl == 64)
                    {
                        return "Linux"; // Common TTL for Linux
                    }
                    else
                    {
                        return "Unknown (TTL: " + ttl + ")";
                    }
                }
                else
                {
                    return "Unknown";
                }
            }
            else
            {
                return "Host Unreachable";
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting OS for {host}: {ex.Message}");
            return "Error";
        }
    }

    // Method to parse ports from input (including ranges and predefined groups)
    static List<int> ParsePorts(string portInput)
    {
        List<int> ports = new List<int>();

        if (predefinedPorts.ContainsKey(portInput.ToLower()))
        {
            // Use predefined port list
            ports = predefinedPorts[portInput.ToLower()];
        }
        else
        {
            // If not a predefined group, parse individual ports or ranges
            string[] portStrings = portInput.Split(',');

            foreach (var portString in portStrings)
            {
                if (portString.Contains('-'))
                {
                    // Handle port range (e.g., 1-10000)
                    string[] range = portString.Split('-');
                    if (range.Length == 2 && int.TryParse(range[0], out int start) && int.TryParse(range[1], out int end))
                    {
                        if (start <= end)
                        {
                            for (int i = start; i <= end; i++)
                            {
                                ports.Add(i);
                            }
                        }
                        else
                        {
                            Console.WriteLine($"Invalid port range: {portString}. Start port must be less than or equal to end port.");
                        }
                    }
                }
                else if (int.TryParse(portString, out int port))
                {
                    // Handle single port (e.g., 80, 443)
                    ports.Add(port);
                }
                else
                {
                    Console.WriteLine($"Invalid port: {portString}");
                }
            }
        }

        return ports;
    }

    // Method to generate a file name based on ports
    static string GenerateFileName(List<int> ports)
    {
        string fileName = "open-";

        if (predefinedPorts.Values.Any(p => p.SequenceEqual(ports)))
        {
            // Match predefined port groups
            var groupName = predefinedPorts.FirstOrDefault(p => p.Value.SequenceEqual(ports)).Key;
            fileName += groupName + "ports.txt";
        }
        else if (ports.Count > 0)
        {
            // Handle custom port ranges
            int minPort = ports.Min();
            int maxPort = ports.Max();
            fileName += $"ports-{minPort}-{maxPort}.txt";
        }
        else
        {
            fileName = "open-unknownports.txt";
        }

        return fileName;
    }

    // Main method that orchestrates the port scanning based on user input
    static async Task Main(string[] args)
    {
        // Ask user for the subnet to scan
        Console.WriteLine("Subnet to scan (e.g., 192.168.1.0/24 or 192.168.1.1): ");
        string target = Console.ReadLine();

        // Ask user for the ports to scan
        Console.WriteLine("Ports to scan (e.g., web, admin, or a custom list like 80,443,8080, or range like 1-10000): ");
        string portInput = Console.ReadLine();

        List<int> ports = ParsePorts(portInput);

        if (string.IsNullOrEmpty(target) || ports.Count == 0)
        {
            Console.WriteLine("Invalid input. Please make sure to provide a valid subnet and ports.");
            return;
        }

        Console.WriteLine("Go bring coffee or something that might take some time.");

        List<(string, List<int>, string, string)> results = new List<(string, List<int>, string, string)>();

        if (target.Contains("."))
        {
            if (target.Contains("/"))
            {
                // Subnet scanning (target is a subnet in CIDR format)
                string subnet = target.Substring(0, target.LastIndexOf("."));
                Console.WriteLine($"Scanning subnet {subnet}. Please wait...");
                await ScanSubnet(subnet, ports, results);
            }
            else
            {
                // Single host scanning
                Console.WriteLine($"Scanning host {target}. Please wait...");
                await ScanPorts(target, ports, results);
            }

            // Generate a filename based on the ports and export the results
            string fileName = GenerateFileName(ports);
            await ExportToTextFile(results, fileName);
        }
        else
        {
            Console.WriteLine("Invalid target format. Please provide a valid IP or subnet.");
        }
    }
}
