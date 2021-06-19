# Scans the filesystem for directories that are user-writeable

This PowerShell script uses [SetACL.exe](https://helgeklein.com/setacl/) to scan the filesystem for directories that are user-writeable.

## Features

- Scans directories regardless of permissions (bypasses existing NTFS permissions using backup privileges)
- Supports very long paths (longer than MAX_PATH, up to the maximum supported by NTFS)
- Lists every kind of write access (full, change, write, set owner, etc.)
- Configurable list of directories to exclude
- Configurable list of users/groups to exclude
- Configurable list of permissions to include

## Output

For every directory that matches the configured criteria, the following properties are listed:

- Path
- User/group
- Permissions
- Permission inheritance

The script's output is CSV-formatted. Sample output:

    C:\Windows\System32\Microsoft\Crypto\RSA\MachineKeys,Everyone,write+read,no_inheritance
    C:\Windows\System32\spool\SERVERS,BUILTIN\Users,FILE_ADD_FILE+FILE_ADD_SUBDIRECTORY+FILE_READ_EA+FILE_READ_ATTRIBUTES,container_inherit
    C:\Windows\System32\Tasks,NT AUTHORITY\Authenticated Users,write+READ_CONTROL,container_inherit

## Examples

### Command-line

Scan the entire `C:\` drive (adjust the path to `SetACL.exe` as needed):

    .\ListUserWriteableDirectories.ps1 -SetACLPath 'D:\Tools\SetACL\SetACL.exe' -ScanDirectory C:\
