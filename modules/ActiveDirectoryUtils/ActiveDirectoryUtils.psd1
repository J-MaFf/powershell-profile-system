@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'ActiveDirectoryUtils.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'Joey Maffiola'

    # Description of the functionality provided by this module
    Description = 'Active Directory utilities and helper functions'

    # Functions to export from this module
    FunctionsToExport = @(
        'Get-ADUserInfo',
        'Get-ADGroupMembers',
        'Test-ADConnection'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
}