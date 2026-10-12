# PowerShell Cheat Sheet

## Basic Commands

```Get-Help <Command>```
: Displays help for a command.
`Get-Command`: Lists available commands.
`Get-Process`: Lists running processes.
`Stop-Process -Id <PID>`: Stops a process by its ID.
`Get-Service`: Lists services.
`Start-Service <ServiceName>`: Starts a service.
`Stop-Service <ServiceName>`: Stops a service.
`Restart-Service <ServiceName>`: Restarts a service.
`Get-ChildItem (or dir, ls)`: Lists files and directories.
`New-Item <Path> -ItemType <Type>`: Creates a new item (file or directory).
`Remove-Item <Path>`: Removes an item.
`Rename-Item <Path> -NewName <NewName>`: Renames an item.
`Copy-Item <Source> <Destination>`: Copies an item.
`Move-Item <Source> <Destination>`: Moves an item.
`Clear-Host (or cls)`: Clears the console.
`Exit`: Exits PowerShell.
`Write-Host <Message>`: Writes a message to the console.
`Read-Host <Prompt>`: Reads input from the console.

## Variables

`$<VariableName> = <Value>`: Assigns a value to a variable.
`$<VariableName>`: Accesses the value of a variable.
`$env:<EnvironmentVariable>`: Accesses an environment variable.
`$PSVersionTable`: Displays PowerShell version information.
`$PROFILE`: Path to the current user's PowerShell profile.

## Operators

`-eq`: Equal to.
`-ne`: Not equal to.
`-gt`: Greater than.
`-lt`: Less than.
`-ge`: Greater than or equal to.
`-le`: Less than or equal to.
`-like`: Wildcard matching.
`-notlike`: Negated wildcard matching.
`-match`: Regular expression matching.
`-notmatch`: Negated regular expression matching.
`-contains`: Checks if a collection contains a value.
`-notcontains`: Checks if a collection does not contain a value.
`-and`: Logical AND.
`-or`: Logical OR.
`-not`: Logical NOT.

## Conditional Statements and Loops

`if (<Condition>) { <Statements> } elseif (<Condition>) { <Statements> } else { <Statements> }`: If-elseif-else statement.
`foreach ($<item> in <collection>) { <Statements> }`: Foreach loop.
`for ($<i> = 0; $<i> -lt 10; $<i>++) { <Statements> }`: For loop.
`while (<Condition>) { <Statements> }`: While loop.
`do { <Statements> } while (<Condition>)`: Do-while loop.
`do { <Statements> } until (<Condition>)`: Do-until loop.
`switch (<Variable>) { <Value1> { <Statements> } <Value2> { <Statements> } default { <Statements> } }`: Switch statement.

## Functions

`function <FunctionName> { <Parameters> <Statements> }`: Defines a function.
`param($<Parameter1>, $<Parameter2>)`: Defines function parameters.
`return <Value>`: Returns a value from a function.

## Pipelines

`<Command1> | <Command2>`: Pipes the output of Command1 to Command2.
`| Where-Object { $_.<Property> -eq <Value> } (or | where {$_.<Property> -eq <Value>})`: Filters objects.
`| Select-Object <Property1>, <Property2> (or | select <Property1>, <Property2>})`: Selects specific properties.
`| Sort-Object <Property>`: Sorts objects.
`| Group-Object <Property>`: Groups objects.
`| Format-Table (or ft)`: Formats output as a table.
`| Format-List (or fl)`: Formats output as a list.
`| Out-File <Path>`: Sends output to a file.
`| ConvertTo-Json`: Converts output to JSON.

## Common Cmdlets

`Get-Content <Path>`: Reads the content of a file.
`Set-Content <Path> -Value <Content>`: Writes content to a file.
`Add-Content <Path> -Value <Content>`: Appends content to a file.
`Invoke-WebRequest <URL>`: Downloads content from a URL.
`Invoke-RestMethod <URL>`: Downloads and parses content from a REST API.
`ConvertTo-Csv`: Converts objects to CSV format.
`Import-Csv`: Imports data from a CSV file.
`ConvertTo-Xml`: Converts objects to XML format.
`Import-Module <ModuleName>`: Imports a PowerShell module.
`Get-Module`: Lists imported modules.
`Test-Path <Path>`: Checks if a path exists.
`Get-Credential`: Prompts for user credentials.
`Start-Transcript -Path <Path>`: Starts a transcript of the PowerShell session.
`Stop-Transcript`: Stops the transcript.

## Error Handling

`try { <Statements> } catch { <Statements> } finally { <Statements> }`: Try-catch-finally block.
`throw <Exception>`: Throws an exception.
`Write-Error <Message>`: Writes an error message to the error stream.
`$Error`: Contains the error records.

## Remoting

`Enter-PSSession <ComputerName>`: Starts an interactive remote session.
`Invoke-Command -ComputerName <ComputerName> { <ScriptBlock> }`: Executes a command on a remote computer.
`New-PSSession <ComputerName>`: Creates a persistent remote session.
`Remove-PSSession <Session>`: Closes a remote session.

## Notes

`$_` or `$PSItem` represents the current object in a pipeline.
Tab completion is very useful.
PowerShell is case-insensitive for commands and parameters, but case-sensitive for variables and strings by default.
Use `Get-Alias` to see aliases for common commands.
Use `Get-Member` to see the properties and methods of an object.