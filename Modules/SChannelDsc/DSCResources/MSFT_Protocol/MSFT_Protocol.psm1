# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData -StringData @'
        ItemTest                       = Testing {0} {1}
        ItemEnable                     = Enabling {0} {1}
        ItemDisable                    = Disabling {0} {1}
        ItemDefault                    = Defaulting {0} {1}
        ItemNotCompliant               = {0} {1} not compliant.
        ItemCompliant                  = {0} {1} compliant.
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Multi-Protocol Unified Hello","PCT 1.0","SSL 2.0","SSL 3.0","TLS 1.0","TLS 1.1","TLS 1.2")]
        [System.String]
        $Protocol,

        [Parameter()]
        [System.Boolean]
        $IncludeClientSide,

        [Parameter()]
        [ValidateSet('Enabled','Disabled','Default')]
        [System.String]
        $State = 'Default'
    )

    Write-Verbose -Message "Getting configuration for protocol $Protocol"

    $itemRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
    $itemKey = $itemRoot + "\" + $Protocol

    $serverItemKey = $itemKey + '\Server'
    $serverEnabledResult = Get-SChannelItem -ItemKey $serverItemKey
    $serverDisabledByDefaultResult = Get-SChannelItem -ItemKey $serverItemKey `
                                                      -ItemValue 'DisabledByDefault'

    $serverResult = $null
    if ($serverEnabledResult -eq $serverDisabledByDefaultResult)
    {
        $serverResult = $serverEnabledResult
    }

    $clientItemKey = $itemKey + '\Client'
    $clientEnabledResult = Get-SChannelItem -ItemKey $clientItemKey
    $clientDisabledByDefaultResult = Get-SChannelItem -ItemKey $clientItemKey `
                                                      -ItemValue 'DisabledByDefault'

    $clientResult = $null
    if ($clientEnabledResult -eq $clientDisabledByDefaultResult)
    {
        $clientResult = $clientEnabledResult
    }

    $clientside = $true
    if ($serverResult -eq $clientResult)
    {
        $clientside = $true
    }

    $returnValue = @{
        Protocol          = $Protocol
        IncludeClientSide = $clientside
        State             = $serverResult
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Multi-Protocol Unified Hello","PCT 1.0","SSL 2.0","SSL 3.0","TLS 1.0","TLS 1.1","TLS 1.2")]
        [System.String]
        $Protocol,

        [Parameter()]
        [System.Boolean]
        $IncludeClientSide,

        [Parameter()]
        [ValidateSet('Enabled','Disabled','Default')]
        [System.String]
        $State = 'Default'
    )

    Write-Verbose -Message "Setting configuration for protocol $Protocol"

    $itemRoot = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'

    if ($IncludeClientSide -eq $true)
    {
        Write-Verbose -Message ($LocalizedData.SetClientProtocol -f $Protocol, $State)
        $clientItemKey = $Protocol + '\Client'

        switch ($State)
        {
            'Default'  {
                Write-Verbose -Message ($LocalizedData.ItemDefault -f 'Protocol', $Protocol)
            }
            'Disabled' {
                Write-Verbose -Message ($LocalizedData.ItemDisable -f 'Protocol', $Protocol)
            }
            'Enabled'  {
                Write-Verbose -Message ($LocalizedData.ItemEnable -f 'Protocol', $Protocol)
            }
        }
        Set-SChannelItem -ItemKey $itemRoot -ItemSubKey $clientItemKey -State $State -ItemValue 'Enabled'
        Set-SChannelItem -ItemKey $itemRoot -ItemSubKey $clientItemKey -State $State -ItemValue 'DisabledByDefault'
    }

    Write-Verbose -Message ($LocalizedData.SetServerProtocol -f $Protocol, $State)
    $serverItemKey = $Protocol + '\Server'

    switch ($State)
    {
        'Default'  {
            Write-Verbose -Message ($LocalizedData.ItemDefault -f 'Protocol', $Protocol)
        }
        'Disabled' {
            Write-Verbose -Message ($LocalizedData.ItemDisable -f 'Protocol', $Protocol)
        }
        'Enabled'  {
            Write-Verbose -Message ($LocalizedData.ItemEnable -f 'Protocol', $Protocol)
        }
    }
    Set-SChannelItem -ItemKey $itemRoot -ItemSubKey $serverItemKey -State $State -ItemValue 'Enabled'
    Set-SChannelItem -ItemKey $itemRoot -ItemSubKey $serverItemKey -State $State -ItemValue 'DisabledByDefault'
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Multi-Protocol Unified Hello","PCT 1.0","SSL 2.0","SSL 3.0","TLS 1.0","TLS 1.1","TLS 1.2")]
        [System.String]
        $Protocol,

        [Parameter()]
        [System.Boolean]
        $IncludeClientSide,

        [Parameter()]
        [ValidateSet('Enabled','Disabled','Default')]
        [System.String]
        $State = 'Default'
    )

    Write-Verbose -Message "Testing configuration for protocol $Protocol"

    $CurrentValues = Get-TargetResource -Protocol $Protocol
    $Compliant = $false

    Write-Verbose -Message "Current Values: $(Convert-SCDscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-SCDscHashtableToString -Hashtable $PSBoundParameters)"

    $ErrorActionPreference = "SilentlyContinue"

    if ($CurrentValues.State -eq $State)
    {
        if ($PSBoundParameters.ContainsKey("IncludeClientSide") -eq $true)
        {
            if ($CurrentValues.IncludeClientSide -eq $IncludeClientSide)
            {
                $Compliant = $true
            }
        }
        else
        {
            $Compliant = $true
        }
    }

    if ($Compliant -eq $true)
    {
        Write-Verbose -Message ($LocalizedData.ItemCompliant -f 'Protocol', $Protocol)
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.ItemNotCompliant -f 'Protocol', $Protocol)
    }

    return $Compliant
}

Export-ModuleMember -Function *-TargetResource
