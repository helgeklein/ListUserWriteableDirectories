# ListUserWriteableDirectories: Scan the Filesystem for Directories That Are User-Writeable

This PowerShell script uses [SetACL.exe](https://helgeklein.com/setacl/) to scan the filesystem for directories that are user-writeable.

## Features

- Scans directories regardless of permissions (bypasses existing NTFS permissions using backup privileges)
- Supports very long paths (longer than MAX_PATH, up to the maximum supported by NTFS)
- Lists every kind of write access (full, change, write, set owner, etc.)
- Configurable list of directories to exclude
- Configurable list of users/groups to exclude
- Configurable list of permissions to include
- Inherited permissions can be included or excluded in the analysis

## Output

For every directory that matches the configured criteria, the following properties are listed:

- Path
- User/group
- Permissions
- Permission inheritance

The script prints one line of text for every matching access control entry (ACE). This means that more than one line may be generated per directory.

The script's output is CSV-formatted. Sample output:

    "C:\Windows\System32\Microsoft\Crypto\RSA\MachineKeys","Everyone",write+read,no_inheritance
    "C:\Windows\System32\spool\SERVERS","BUILTIN\Users",FILE_ADD_FILE+FILE_ADD_SUBDIRECTORY+FILE_READ_EA+FILE_READ_ATTRIBUTES,container_inherit
    "C:\Windows\System32\Tasks","NT AUTHORITY\Authenticated Users",write+READ_CONTROL,container_inherit

## How to Use

### Elevation (admin rights)

Run the script as elevated user. More specifically: as a user with backup privileges. It works without elevation, too, but in that case is limited to those parts of the filesystem the user running it has access to.

### Inherited permissions

The parameter `IncludeInherited` controls whether inherited permissions are included in the analysis. By default, inherited permissions are *not* included. This lets you focus on the directories where insecure permissions are configured. For a complete scan including inherited permissions, add the parameter `IncludeInherited` to the command-line.

## Examples

Scan the entire `C:\` drive, do not include inherited permissions:

    .\ListUserWriteableDirectories.ps1 -SetACLPath 'D:\Tools\SetACL\SetACL.exe' -ScanDirectory C:\

Scan `C:\Program Files`, including inherited permissions:

    .\ListUserWriteableDirectories.ps1 -SetACLPath 'D:\Tools\SetACL\SetACL.exe' -ScanDirectory 'C:\Program Files' -IncludeInherited

(Adjust the path to `SetACL.exe` as needed)
