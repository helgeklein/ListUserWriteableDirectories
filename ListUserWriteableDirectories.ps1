#
# Scans the filesystem for directories that are user-writeable
#
# Prerequisites:
#
# - SetACL.exe (https://helgeklein.com/setacl/)
#

Param(
   [Parameter(Mandatory, HelpMessage="Path to SetACL.exe")][string] $SetACLPath,
   [Parameter(Mandatory, HelpMessage="The directory to scan (recursively)")][string] $ScanDirectory,
   [Parameter(HelpMessage="Include inherited permissions in the analysis?")][switch] $IncludeInherited = $false
)

###################################
#
# Variables: adjust as required
#
###################################

# Paths to ignore (case-insensitive, wildcards allowed)
$pathDenylist = @("C:\Users\*")

# Permissions to include (case-insensitive)
# Format: SetACL (https://helgeklein.com/setacl/documentation/command-line-version-setacl-exe/#valid-standard-permissions)
$permissionsAllowlist = @("full", "change", "write", "write_owner", "write_dacl", "write_ea", "write_attr", "add_file")

# User/groups to ignore (case-insensitive)
$trusteeDenylist = @(
                     "NT AUTHORITY\SYSTEM",
                     "NT AUTHORITY\SERVICE",
                     "NT AUTHORITY\LOCAL SERVICE",
                     "NT AUTHORITY\NETWORK SERVICE",
                     "NT AUTHORITY\USER MODE DRIVERS",
                     "NT AUTHORITY\WRITE RESTRICTED",
                     "BUILTIN\Administrators",
                     "BUILTIN\Network Configuration Operators",
                     "BUILTIN\Backup Operators",
                     "BUILTIN\Performance Log Users",
                     "NT SERVICE\*",
                     "APPLICATION PACKAGE AUTHORITY\*",
                     "CREATOR OWNER",
                     "NT VIRTUAL MACHINE\Virtual Machines"
                    )

###################################
#
# Script start
#
###################################

# Check parameters
if (-Not (Test-Path $SetACLPath -PathType Leaf))
{
   Write-Error "Could not find SetACL.exe: <$SetACLPath>"
   exit
}
if (-Not (Test-Path $ScanDirectory))
{
   Write-Error "Could not find scan directory: <$ScanDirectory>"
   exit
}
if ($IncludeInherited)
{
   $inherited = "y"
}
else
{
   $inherited = "n"
}

# Run SetACL, the output is written to a temporary file
$tempFile = [System.IO.Path]::GetTempFileName()
& "$SetACLPath" -on "$ScanDirectory" -ot file -actn list -lst "f:csv;i:$inherited" -rec cont -ignoreerr -bckp "$tempFile" -silent

# Open SetACL's output file
$reader = [System.IO.File]::OpenText($tempFile)

try
{
   for()
   {
      # Read the output line by line
      $line = $reader.ReadLine()
      if ($line -eq $null) { break }
   
      # Convert SetACL's output to an object
      $directory = ConvertFrom-Csv -InputObject $line -Header 'Path', 'Type', 'DACL'

      # Beautify the path
      $directory.Path = $directory.Path.Replace("\\?\", "")

      # Check if the directory should be excluded
      $found = $false
      foreach ($path in $pathDenylist)
      {
         if ($directory.Path -like $path)
         {
            $found = $true
            break
         }
      }
      if ($found -eq $true)
      {
         continue
      }

      # Ignore messages from SetACL
      if (!$directory.DACL)
      {
         continue
      }

      # Process the ACEs (they're colon-separated), ignoring the first line ("DACL(protected+auto_inherited):")
      [array] $ACEStrings = $directory.DACL -split ":"
      for ($i = 1; $i -lt $ACEStrings.Count; $i++)
      {
         # Convert the ACE to an object
         $ACE = ConvertFrom-Csv -InputObject $ACEStrings[$i] -Header 'Trustee', 'Permissions', 'AccessMode', 'Inheritance'

         # Ignore anything but access allowed
         if ($ACE.AccessMode -ne "allow")
         {
            continue
         }

         # Ignore ACEs that are applied to subdirectories only
         if ($ACE.Inheritance -like "*inherit_only*")
         {
            continue
         }

         # Check if the ACE's permissions should be included
         $found = $false
         foreach ($permission in $permissionsAllowlist)
         {
            if ($ACE.Permissions -like "*$permission*")
            {
               $found = $true
               break
            }
         }
         if ($found -eq $false)
         {
            continue
         }

         # Check if the ACE's trustee (user/group) should be ignored
         $found = $false
         foreach ($trustee in $trusteeDenylist)
         {
            if ($ACE.Trustee -like $trustee)
            {
               $found = $true
               break
            }
         }
         if ($found -eq $true)
         {
            continue
         }

         # We found a relevant directory
         "`"" + $directory.Path + "`",`"" + $ACE.Trustee + "`"," + $ACE.Permissions + "," + $ACE.Inheritance
      }
   }
}
finally
{
   $reader.Close()
}

# Delete the SetACL output file
Remove-Item -Path $tempFile