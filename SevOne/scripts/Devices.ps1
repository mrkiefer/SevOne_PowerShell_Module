function Get-SevOneDevice {
<#
  .SYNOPSIS
    Gathers SevOne devices

  .DESCRIPTION
    Gather one or more SevOne devices from the SevOne API

  .EXAMPLE
    Get-SevOneDevice

    Gathers all SevOne devices

  .EXAMPLE
    Get-SevOneDevice -Name MyServer

    Returns a device object for the device named MyServer

  .EXAMPLE
    Get-SevOne -IPAddress 192.168.0.100

    Returns a device object for the device with an IP of 192.168.0.100

  .NOTES
    At this point there is no support for wildcards.
#>
[cmdletbinding(DefaultParameterSetName='default')]
param
  (
    #
    [parameter(Mandatory,
    ParameterSetName='Name',
    ValueFromPipelineByPropertyName)]
    [string]$Name,
    
    #
    [parameter(Mandatory,
    ParameterSetName='ID',
    ValueFromPipelineByPropertyName)]
    [int]$ID,
    
    #
    [parameter(Mandatory,
    ParameterSetName='IPAddress',
    ValueFromPipelineByPropertyName)]
    [IPAddress]$IPAddress,

    #
    [parameter(Mandatory,
    ParameterSetName='Group')]
    $Group
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    switch ($PSCmdlet.ParameterSetName)
      {
        'Group' {
            $return = $SevOne.group_getDevicesByGroupId($Group.id)
            #$return
          }
        'default' { 
            Write-Debug 'in default block'
            try {$return = $SevOne.core_getDevices()} catch {
                $return = $null
                Write-Error $_.exception.message
              }
            continue
          }
        'Name' { 
            Write-Debug 'in name block'
            try {
                $return =  $SevOne.core_getDeviceByName($Name)
                Write-Debug 'Test $return to ensure object is not blank'
                if (-not $return.id)
                  {throw "Empty object returned for $Name"}
              } 
            catch {
                $return = $null
                Write-Error "No device found with name: $Name"
                Write-Error $_.exception.message
              }
            continue
          }
        'ID' { 
            Write-Debug 'in id block'
            try {$return = $SevOne.core_getDeviceById($ID)} catch {
                $return = $null
                Write-Error "No device found with id: $id"
                Write-Error $_.exception.message
              }
            continue
          }
        'IPAddress' { 
            Write-Debug 'in IPAddress block'
            try {
                $return = $SevOne.core_getDeviceById(($SevOne.core_getDeviceIdByIp($IPAddress.IPAddressToString)))
              } 
            catch {
                $return = $null
                Write-Error "No device found with IPAddress: $($IPAddress.IPAddressToString)"
                Write-Error $_.exception.message
              }
            continue
        }
      }
    if ($return)
      {
        [device]$return
      }
  }
}