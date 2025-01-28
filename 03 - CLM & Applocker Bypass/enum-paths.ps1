Param(
[parameter(Mandatory=$false)]
[String[]] $Exclusions = @(),

[parameter(Mandatory=$false)]
[String[]] $Paths = @(
  "C:\Windows",
  "C:\Program Files",
  "C:\Program Files (x86)"
),

[parameter(Mandatory=$false)]
[String] $OutFile
)

$FSR = [System.Security.AccessControl.FileSystemRights]

$GenericRights = @{
  GENERIC_READ    = [int]0x80000000;
  GENERIC_WRITE   = [int]0x40000000;
  GENERIC_EXECUTE = [int]0x20000000;
  GENERIC_ALL     = [int]0x10000000;
  FILTER_GENERIC  = [int]0x0FFFFFFF;
}

$MappedGenericRights = @{
  FILE_GENERIC_READ    = $FSR::ReadAttributes -bor $FSR::ReadData -bor $FSR::ReadExtendedAttributes -bor $FSR::ReadPermissions -bor $FSR::Synchronize
  FILE_GENERIC_WRITE   = $FSR::AppendData -bor $FSR::WriteAttributes -bor $FSR::WriteData -bor $FSR::WriteExtendedAttributes -bor $FSR::ReadPermissions -bor $FSR::Synchronize
  FILE_GENERIC_EXECUTE = $FSR::ExecuteFile -bor $FSR::ReadPermissions -bor $FSR::ReadAttributes -bor $FSR::Synchronize
  FILE_GENERIC_ALL     = $FSR::FullControl
}

Function Map-GenericRightsToFileSystemRights([System.Security.AccessControl.FileSystemRights]$Rights) {  
  $MappedRights = New-Object -TypeName $FSR

  If ($Rights -band $GenericRights.GENERIC_EXECUTE) {
    $MappedRights = $MappedRights -bor $MappedGenericRights.FILE_GENERIC_EXECUTE
  }

  If ($Rights -band $GenericRights.GENERIC_READ) {
   $MappedRights = $MappedRights -bor $MappedGenericRights.FILE_GENERIC_READ
  }

  If ($Rights -band $GenericRights.GENERIC_WRITE) {
    $MappedRights = $MappedRights -bor $MappedGenericRights.FILE_GENERIC_WRITE
  }

  If ($Rights -band $GenericRights.GENERIC_ALL) {
    $MappedRights = $MappedRights -bor $MappedGenericRights.FILE_GENERIC_ALL
  }

  return (($Rights -band $GenericRights.FILTER_GENERIC) -bor $MappedRights) -as $FSR
}

$WriteRights = @("WriteData", "CreateFiles", "CreateDirectories", "WriteExtendedAttributes", "WriteAttributes", "Write", "ModIfy", "FullControl")

Function NotLike($String, $Patterns) {  
  ForEach ($Pattern in $Patterns) { If ($String -like $Pattern) { return $False } }
  return $True
}

function Scan($Path, $OutputFile) {
  If ($OutFile) { New-Item -Force -ItemType File -Path $OutputFile | Out-Null }
  $Cache = @()
  gci $Path -Recurse -Exclude $Exclusions -Force -ea silentlycontinue |
  ? {(NotLike $_.fullname $Exclusions)} | %{
    trap { continue }
    $File = $_.fullname
    (get-acl $File -ea silentlycontinue).access |
    ? {$_.identityreference -Match ".*USERS|EVERYONE"} | %{
      (map-genericrightstofilesystemrights $_.filesystemrights).tostring().split(",") | %{
        If ($WriteRights -Contains $_.trim()) {
		  If ($Cache -NotContains $File) {
		    Write-Host $File
		    If ($OutputFile) { $File | Out-File -Append -Force -FilePath $OutFile }
			$Cache += $File
		  }
        }
      }
    }
  }
  return $Cache
}

$Paths | %{ scan $_ $OutFile }
