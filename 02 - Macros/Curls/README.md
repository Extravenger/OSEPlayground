### Why?
1. The main purpose of the VBA is to determine if the process we target for injection is x64 or x86 bit.
2. Save time of targeting the wrong arch and wonder why the heck we don't get callback!

There are two implementations: using curl and using powershell, choose what ever you like, the HTTP response in your nc listener should contatin the outcome.

- Before executing the VBA, make sure you set up the NC listener: `nc -lvnp 80`
