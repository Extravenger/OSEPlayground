using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Threading.Tasks;
using System.Linq;
using System.IO;
using System.Net.NetworkInformation;
using System.Threading;

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

    // Semaphore for controlling concurrency (adjust the max concurrency)
    static SemaphoreSlim semaphore = new SemaphoreSlim(50); // Max 50 concurrent tasks

    // Method to test if a port is open
    static async Task<bool> TestPort(string host, int port, int timeout = 2000)
    {
        try
        {
            using (var tcpClient = new TcpClient())
            {
                var connectTask = tcpClient.ConnectAsync(host, port);
                var timeoutTask = Task.Delay(timeout);

                var completedTask = await Task.WhenAny(connectTask, timeoutTask);

                return completedTask == connectTask && tcpClient.Connected;
            }
        }
        catch
        {
            return false;
        }
    }

    // Method to scan ports on a single host
    static async Task ScanPorts(string host, List<int> ports, List<(string, List<int>, string, string)> results)
    {
        List<int> openPorts = new List<int>();

        // First, check if the host is alive
        string os = await GetOperatingSystem(host);
        if (os == "Host Unreachable") return;

        // Parallelize port checking
        var tasks = ports.Select(async port =>
        {
            await semaphore.WaitAsync(); // Control concurrency
            try
            {
                bool isOpen = await TestPort(host, port);
                if (isOpen)
                    openPorts.Add(port);
            }
            finally
            {
                semaphore.Release();
            }
        });

        await Task.WhenAll(tasks);

        if (openPorts.Any())
        {
            string resolvedHost = await ResolveHostname(host);

            // If the OS is Linux, filter out Windows-specific ports
            if (os == "Linux")
            {
                openPorts = openPorts.Where(port => !knownWindowsPorts.Contains(port)).ToList();
            }

            if (openPorts.Any())
            {
                results.Add((host, openPorts, resolvedHost, os));
            }
        }
    }

    // Method to scan a subnet (CIDR)
    static async Task ScanSubnet(string subnet, List<int> ports, List<(string, List<int>, string, string)> results)
    {
        var tasks = new List<Task>();
        List<string> ipList = new List<string>();

        // Collect each IP in the subnet (in range 1-254 for /24)
        for (int i = 1; i <= 254; i++)
        {
            string ip = $"{subnet.Substring(0, subnet.LastIndexOf('.') + 1)}{i}"; // Subnet prefix (e.g., 192.168.1) + host (e.g., 1)
            ipList.Add(ip);
        }

        // Sort IP addresses in ascending order
        ipList = ipList.OrderBy(ip => ip).ToList();

        // Now scan the sorted IPs
        foreach (var ip in ipList)
        {
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
            int ipAddressWidth = 20;
            int hostnameWidth = 30;
            int osWidth = 20;
            int openPortsWidth = 40;

            await writer.WriteLineAsync(
                "IP Address".PadRight(ipAddressWidth) +
                "Hostname".PadRight(hostnameWidth) +
                "Operating System".PadRight(osWidth) +
                "Open Ports".PadRight(openPortsWidth)
            );

            // Add a line break after the header
            await writer.WriteLineAsync();

            foreach (var result in results)
            {
                string ipAddress = result.Item1.PadRight(ipAddressWidth);
                string hostname = result.Item3.PadRight(hostnameWidth);
                string os = result.Item4.PadRight(osWidth);
                string openPorts = string.Join(", ", result.Item2).PadRight(openPortsWidth);

                await writer.WriteLineAsync($"{ipAddress}{hostname}{os}{openPorts}");
            }
        }

        Console.WriteLine($"Results saved to {filePath}");
    }

    // Method to resolve IP to Hostname (if possible)
    static async Task<string> ResolveHostname(string ip)
    {
        try
        {
            var hostEntry = await Dns.GetHostEntryAsync(ip);
            return hostEntry.HostName;
        }
        catch
        {
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
                int ttl = reply.Options?.Ttl ?? 0;

                // TTL <= 64 means likely Linux
                if (ttl <= 64)
                {
                    return "Linux";
                }
                // TTL between 100 and 128 means likely Windows
                else if (ttl >= 100 && ttl <= 128)
                {
                    return "Windows";
                }
                else
                {
                    return $"Unknown (TTL: {ttl})";
                }
            }
            else
            {
                return "Host Unreachable";
            }
        }
        catch
        {
            return "Host Unreachable";
        }
    }

    // Method to parse ports from input
    static List<int> ParsePorts(string portInput)
    {
        List<int> ports = new List<int>();

        if (predefinedPorts.ContainsKey(portInput.ToLower()))
        {
            ports = predefinedPorts[portInput.ToLower()];
        }
        else
        {
            string[] portStrings = portInput.Split(',');

            foreach (var portString in portStrings)
            {
                if (portString.Contains('-'))
                {
                    string[] range = portString.Split('-');
                    if (range.Length == 2 && int.TryParse(range[0], out int start) && int.TryParse(range[1], out int end))
                    {
                        for (int i = start; i <= end; i++) ports.Add(i);
                    }
                }
                else if (int.TryParse(portString, out int port))
                {
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
            var groupName = predefinedPorts.FirstOrDefault(p => p.Value.SequenceEqual(ports)).Key;
            fileName += groupName + "ports.txt";
        }
        else if (ports.Count > 0)
        {
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
        Console.WriteLine("\nPlease choose an option:\n");
        Console.WriteLine("\t1. Host Discovery");
        Console.WriteLine("\t2. Port Scanning");
        Console.Write("\nEnter the number: ");
        string choice = Console.ReadLine();

        if (choice == "1")
        {
            // Host Discovery Mode
            Console.Write("Subnet to scan for live hosts (e.g., 192.168.1.0/24): ");
            string target = Console.ReadLine();

            if (string.IsNullOrEmpty(target))
            {
                Console.WriteLine("Invalid input. Please provide a valid subnet.");
                return;
            }

            Console.WriteLine($"\nPerforming host discovery on {target}...");

            List<(string, List<int>, string, string)> results = new List<(string, List<int>, string, string)>();
            if (target.Contains("/"))
            {
                await ScanSubnetForHostDiscovery(target, results);
            }
            else
            {
                await ScanHostForHostDiscovery(target, results);
            }

            string fileName = "host-discovery.txt";
            await ExportToTextFile(results, fileName);
        }
        else if (choice == "2")
        {
            // Port Scanning Mode
            Console.Write("Subnet to scan (e.g., 192.168.1.0/24): ");
            string target = Console.ReadLine();

            Console.WriteLine("Choose the port set to scan:\n");
            Console.WriteLine("\t1. Web (Ports: 21, 23, 25, 80, 443, 8080)");
            Console.WriteLine("\t2. Admin (Ports: 135, 139, 445, 3389, 5985, 5986)");
            Console.WriteLine("\t3. Top 20 (Common ports: 21, 22, 23, 25, 53, 80, 110, 111, 135, 139, 143, 443, 445, 993, 995, 1723, 3306, 3389, 5900, 8080)");
            Console.WriteLine("\t4. Custom (Enter a list or range, e.g., 80,443,8080 or 1000-2000)\n");
            Console.Write("Enter your choice (1-4): ");
            string portChoice = Console.ReadLine();

            List<int> ports = new List<int>();
            switch (portChoice)
            {
                case "1":
                    ports = predefinedPorts["web"];
                    break;
                case "2":
                    ports = predefinedPorts["admin"];
                    break;
                case "3":
                    ports = predefinedPorts["top20"];
                    break;
                case "4":
                    Console.Write("Enter your custom ports (e.g., 80,443,8080 or 1000-2000): ");
                    string customPorts = Console.ReadLine();
                    ports = ParsePorts(customPorts);
                    break;
                default:
                    Console.WriteLine("Invalid choice.");
                    return;
            }

            if (string.IsNullOrEmpty(target) || ports.Count == 0)
            {
                Console.WriteLine("Invalid input. Please make sure to provide a valid subnet and ports.");
                return;
            }

            Console.WriteLine($"\nPerforming port scanning on {target}...");

            List<(string, List<int>, string, string)> results = new List<(string, List<int>, string, string)>();

            if (target.Contains("."))
            {
                if (target.Contains("/"))
                {
                    Console.WriteLine($"Scanning subnet {target}. Please wait...");
                    await ScanSubnet(target, ports, results);
                }
                else
                {
                    Console.WriteLine($"Scanning host {target}. Please wait...");
                    await ScanPorts(target, ports, results);
                }

                string fileName = GenerateFileName(ports);
                await ExportToTextFile(results, fileName);
            }
            else
            {
                Console.WriteLine("Invalid target format. Please provide a valid IP or subnet.");
            }
        }
        else
        {
            Console.WriteLine("Invalid choice. Please restart and choose either 1 or 2.");
        }
    }

    // Host Discovery Mode: Scan a single host for IP and Hostname
    static async Task ScanHostForHostDiscovery(string host, List<(string, List<int>, string, string)> results)
    {
        string os = await GetOperatingSystem(host);
        if (os != "Host Unreachable")
        {
            string resolvedHost = await ResolveHostname(host);
            results.Add((host, new List<int>(), resolvedHost, os));
        }
    }

    // Host Discovery Mode: Scan a subnet for IPs and Hostnames
    static async Task ScanSubnetForHostDiscovery(string subnet, List<(string, List<int>, string, string)> results)
    {
        var tasks = new List<Task>();
        List<string> ipList = new List<string>();

        // Collect each IP in the subnet (in range 1-254 for /24)
        for (int i = 1; i <= 254; i++)
        {
            string ip = $"{subnet.Substring(0, subnet.LastIndexOf('.') + 1)}{i}"; // Subnet prefix (e.g., 192.168.1) + host (e.g., 1)
            ipList.Add(ip);
        }

        // Sort IP addresses in ascending order
        ipList = ipList.OrderBy(ip => ip).ToList();

        // Now scan the sorted IPs
        foreach (var ip in ipList)
        {
            tasks.Add(Task.Run(async () =>
            {
                await ScanHostForHostDiscovery(ip, results);
            }));
        }

        await Task.WhenAll(tasks);
    }
}
