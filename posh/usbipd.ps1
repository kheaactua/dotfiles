# PowerShell parameter completion shim for usbipd-win
Register-ArgumentCompleter -Native -CommandName usbipd -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
    usbipd [suggest:$cursorPosition] "$wordToComplete" | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}