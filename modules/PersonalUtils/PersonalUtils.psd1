@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'PersonalUtils.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # ID used to uniquely identify this module
    GUID = 'b2c3d4e5-f6a7-8901-bcde-f23456789012'

    # Author of this module
    Author = 'Joey Maffiola'

    # Description of the functionality provided by this module
    Description = 'Personal utility functions and helpers'

    # Functions to export from this module
    FunctionsToExport = @(
        'Get-SystemInfo',
        'Start-ElevatedProcess',
        'Test-Port'
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