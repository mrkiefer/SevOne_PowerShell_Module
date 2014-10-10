#requires -version 3.0
$Global:SevOne = $null

# Indicators, Objects

# Group > Device > object > indicator

# Device Groups and Object Groups

# Group membership can be explicit or rule based

# for object group the device group is required



function __TestSevOneConnection__ {
  Write-Debug 'Begin test'
  try {[bool]$Global:SevOne.returnthis(1)} catch {$false}
}

Function __fromUNIXTime__ {
Param
  (
    [Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true)]
    [int]$inputobject
  )
Process
  {
    [datetime]$origin = '1970-01-01 00:00:00'
    $origin.AddSeconds($inputobject)
  }
}

filter __DeviceObject__ {
  $base = $_
  $obj = [pscustomobject]@{
        ID = $base.id
        Name = $base.name
        AlternateName = $base.alternateName
        Description = $base.description
        IPAddress = $base.ip
        SNMPCapable = $base.snmpCapable -as [bool]
        SNMPPort = $base.snmpPort
        SNMPVersion = $base.snmpVersion
        SNMPROCommunity = $base.snmpRoCommunity
        snmpRwCommunity = $base.snmpRwCommunity
        synchronizeInterfaces = $base.synchronizeInterfaces
        synchronizeObjectsAdminStatus = $base.synchronizeObjectsAdminStatus
        synchronizeObjectsOperStatus = $base.synchronizeObjectsOperStatus
        peer = $base.peer
        pollFrequency = $base.pollFrequency
        elementCount = $base.elementCount
        discoverStatus = $base.discoverStatus
        discoverPriority = $base.discoverPriority
        brokenStatus = $base.brokenStatus -as [bool]
        isNew = $base.isNew -as [bool]
        isDeleted = $base.isDeleted -as [bool]
        allowAutomaticDiscovery = $base.allowAutomaticDiscovery -as [bool]
        allowManualDiscovery = $base.allowManualDiscovery -as [bool]
        osId = $base.osId
        lastDiscovery = $base.lastDiscovery -as [datetime]
        snmpStatus = $base.snmpStatus
        icmpStatus = $base.icmpStatus
        disableDiscovery = $base.disableDiscovery -as [bool]
        disableThresholding = $base.disableThresholding -as [bool]
        disablePolling = $base.disablePolling -as [bool]
      }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Device.DeviceInfo')
  $obj
}
 
filter __ThresholdObject__ {
  $obj = [pscustomobject]@{
      id = $_.id  
      name = $_.name
      description = $_.description 
      deviceId = $_.deviceId 
      policyId = $_.policyId 
      severity = $_.severity
      groupId  = $_.groupId 
      isDeviceGroup = $_.isDeviceGroup
      triggerExpression = $_.triggerExpression
      clearExpression = $_.clearExpression
      userEnabled = $_.userEnabled -as [bool]
      policyEnabled = $_.policyEnabled -as [bool]
      timeEnabled = $_.timeEnabled -as [bool]
      mailTo = $_.mailTo 
      mailOnce = $_.mailOnce 
      mailPeriod = $_.mailPeriod 
      lastUpdated = $_.lastUpdated 
      useDefaultTraps = $_.useDefaultTraps
      useDeviceTraps = $_.useDeviceTraps
      useCustomTraps = $_.useCustomTraps
      triggerMessage = $_.triggerMessage
      clearMessage = $_.clearMessage
      appendConditionMessages = $_.appendConditionMessages
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Threshold.ThresholdInfo')
  $obj
}

filter __AlertObject__ {
  $obj = [pscustomobject]@{
      id = $_.id 
      severity = $_.severity
      isCleared = $_.isCleared -as [bool]
      origin = $_.origin 
      deviceId = $_.deviceId
      pluginName = $_. pluginName
      objectId = $_.objectId 
      pollId = $_.pollId
      thresholdId = $_.thresholdId
      startTime = $_.Starttime | __fromUNIXTime__
      endTime = $_.endTime | __fromUNIXTime__
      message = $_.message 
      assignedTo = $_.assignedTo
      comments = $_.comments
      clearMessage = $_.clearMessage 
      acknowledgedBy = $_.acknowledgedBy
      number = $_.number
      automaticallyProcessed = $_.automaticallyProcessed
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Alert.AlertInfo')
  $obj
}

filter __DeviceClass__ {
  $obj = [pscustomobject]@{
      Name = $_.name
      Id = $_.id
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Class.DeviceClass')
  $obj
}

filter __ObjectClass__ {
  $obj = [pscustomobject]@{
      Name = $_.name
      Id = $_.id
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Class.ObjectClass')
  $obj
}

filter __DeviceGroupObject__ {
  $base = $_ 
  $obj = [pscustomobject]@{
      ID = $base.id
      ParentGroupID = $base.parentid
      Name = $base.name
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Group.DeviceGroup')
  $obj
}

filter __ObjectGroupObject__ {
  $base = $_ 
  $obj = [pscustomobject]@{
      ID = $base.id
      ParentGroupID = $base.parentid
      Name = $base.name
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Group.ObjectGroup')
  $obj
}

filter __PeerObject__ {
  $obj = [pscustomobject]@{
      serverId = $_.ServerId 
      name = $_.name 
      ip = $_.ip
      is64bit = $_.is64bit
      memory = $_.memory
      isMaster = $_.isMaster 
      username = $_.username 
      password = $_.password 
      capacity = $_.capacity
      serverLoad = $_.serverLoad
      flowLoad = $_.flowLoad 
      model = $_.model
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Group.ObjectGroup')
  $obj
}

function Connect-SevOne {
<#
  .Synopsis
     Create a connection to a SevOne Instance 
  .DESCRIPTION
     Creates a SOAP API connection to the specified SevOne Management instance.

     Only one sevone connection is available at any time.  Creating a new connection will overwrite the existing connection.
  .EXAMPLE
     Connect-SevOne -ComputerName 192.168.0.10 -credential (get-credential)

     Establishes a new connection to the SevOne Management server at 192.168.0.10
#>
  [CmdletBinding()]
  param
  (
    # Set the Computername or IP address of the SevOneinstance you wish to connect to
    [Parameter(Mandatory,
    Position=0,
    ParameterSetName='Default')]
    [string]
    $ComputerName,
    
    # Specify the Credentials for the SevOne Connection
    [Parameter(Mandatory,
    Position=1,
    ParameterSetName='Default')]
    [PSCredential]
    $Credential,

    # Set this option if you are connecting via SSL
    [Parameter(ParameterSetName='Default')]
    [switch]$UseSSL
  )
Write-Debug 'starting connection process'
Write-Debug "`$UseSSL is $UseSSL"
if ($UseSSL) { $SoapUrl = "https://$ComputerName/soap3/api.wsdl" }
else { $SoapUrl = "http://$ComputerName/soap3/api.wsdl" }
Write-Debug 'URL is complete and stored in $SoapURL'
Write-Verbose "Beginning connection to $SoapUrl"
$Client = try {New-WebServiceProxy -Uri $SoapUrl -ErrorAction Stop} 
catch {throw "unable to reach the SevOne Appliance @ $SoapUrl"}
Write-Debug 'WebConnection stored in $Client'
Write-Verbose 'Creating cookie container'
try {$Client.CookieContainer = New-Object System.Net.CookieContainer}
catch {
    Write-Debug 'Failed to build system.net.cookiecontainer for $Client'
    throw 'unable to build cookie container'
  }
try {
    $return = $Client.authenticate($Credential.UserName, $Credential.GetNetworkCredential().Password)
    if ($return -lt 1)
      {
        throw 'Authentication failure'
      }
  } 
catch {
    Write-Warning $_.exception.message
    Write-Debug 'In failure block for $client.authenticate()'
    Throw 'Unable to authenticate with the SevOne Appliance'
  }
    $Global:SevOne = $Client
    Write-Verbose 'Successfully connected to SevOne Appliance'
}

function Get-SevOnePeer {
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    #
    [Parameter(Mandatory,
    ParameterSetName='ID')]
    [int]$ID
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    switch ($PSCmdlet.ParameterSetName)
      {
        'default' {
            $return = $Global:SevOne.core_getPeers()
            continue
          }
        'id' {
            $return = $Global:SevOne.core_getPeerById($id)
            continue
          }
      }
    $return | __PeerObject__
  }
}

function Get-SevOneDevice # issue, device by ID is failing with the ID property
{
<#
  .SYNOPSIS
    Gathers SevOne devices

  .DESCRIPTION
    Gather one or more SevOne devices from the SevOne API

  .EXAMPLE
    Get-SevOneDevice

    Gathers all SevOne devices

  .EXAMPLE
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
    [IPAddress]$IPAddress
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    switch ($PSCmdlet.ParameterSetName)
      {
        'default' { 
            $return = $Global:SevOne.core_getDevices()
            continue
          }
        'Name' { 
            $return =  $Global:SevOne.core_getDeviceByName($Name)
            continue
          }
        'ID' { 
            $return = $Global:SevOne.core_getDeviceById($ID)
            continue
          }
        'IPAddress' { 
          $return =  $Global:SevOne.core_getDeviceById(($Global:SevOne.core_getDeviceIdByIp($IPAddress.IPAddressToString)))
          continue
        }
      }
    $return | __DeviceObject__
  }
}

function Get-SevOneAlert # only gets active alerts, may want to change this in the future
{
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param
  (
    # The Device that will be associated with Alarms pulled
    [parameter(Mandatory,
    Position=0,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Device')]
    [PSObject]$Device,

    # The time to start pulling alerts
    [parameter(ParameterSetName='Device')]
    [parameter(ParameterSetName='Default')]    
    [datetime]$StartTime
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process 
  {
    switch ($PSCmdlet.ParameterSetName)
      {
        'default' {
            $return = $Global:SevOne.alert_getAlerts(0)
          }
        'device' {
            $return = $Global:SevOne.alert_getAlertsByDeviceId($Device.id,0)
          }
      }
    foreach ($a in ($return | __AlertObject__))
      {
        if ($StartTime)
          {
            if ($a.startTime -ge $StartTime)
              {$a}
          }
        else {$a}
      }
  }
end {}
}

function Close-SevOneAlert {
<##>
[cmdletbinding()]
param 
  (
    [Parameter(Mandatory,
    position=0,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Alert,
    [string]$Message = 'Closed via API'
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process{
    try {
        $return = $Global:SevOne.alert_clearByAlertId($Alert.ID,$Message) 
      }
    catch {}
  }
end {}
}
 
function Get-SevOneDeviceGroup {
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    #
    [Parameter(Mandatory,
    ParameterSetName='Name')]
    [string]$Name,

    #
    [Parameter(Mandatory,
    ParameterSetName='ID')]
    [int]$ID
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    Write-Debug 'opened process block'
    switch ($PSCmdlet.ParameterSetName)
      {
        'Default' {
            Write-Debug "in Default block"
            $return = $Global:SevOne.group_getDeviceGroups()
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
        'Name' {
            Write-Debug 'in Name block'
            $return = $Global:SevOne.group_getDeviceGroupIdByName($Name)
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
        'ID' {
            Write-Debug 'in ID block'
            $return = $Global:SevOne.group_getDeviceGroupById($ID)
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
      }
    Write-Debug 'Sending $return to object creation'
    $return | __DeviceGroupObject__
  }
end {}
}

function Set-SevOneDeviceGroup {}

function New-SevOneDeviceGroup {}

function Remove-SevOneGroup {
<##>
[cmdletbinding(SupportsShouldProcess=$true,DefaultParameterSetName='default',ConfirmImpact='high')]
param (
    #
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    $Group
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    Write-Verbose "Opening process block for $($Group.name)"
    if ($PSCmdlet.ShouldProcess("$($Group.name)","Remove SevOne Group"))
      {
        switch ($Group.PSObject.TypeNames[0])
          {
            'sevone.group.deviceGroup' {
                $return = $Global:SevOne.group_deleteDeviceGroup($Group.id)
                if ($return -ne 1) {
                    Write-Error "failed to delete $($Group.name)"
                  }
                continue
              }
            'SevOne.Group.ObjectGroup' {
                $return = $Global:SevOne.group_deleteObjectGroup($Group.id)
                if ($return -ne 1) {
                    Write-Error "failed to delete $($Group.name)"
                  }
                continue
              }
          }
      }
  }
}

function Remove-SevOneClass {
<##>
[cmdletbinding(SupportsShouldProcess=$true,DefaultParameterSetName='default',ConfirmImpact='high')]
param (
    #
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    $Class
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    Write-Verbose "Opening process block for $($Class.name)"
    if ($PSCmdlet.ShouldProcess("$($Class.name)","Remove SevOne Group"))
      {
        switch ($Class.PSObject.TypeNames[0])
          {
            'SevOne.Class.deviceClass' {
                $return = $Global:SevOne.group_deleteDeviceClass($Class.id)
                if ($return -ne 1) {
                    Write-Error "failed to delete $($Class.name)"
                  }
                continue
              }
            'SevOne.Class.ObjectClass' {
                $return = $Global:SevOne.group_deleteObjectClass($Class.id)
                if ($return -ne 1) {
                    Write-Error "failed to delete $($Class.name)"
                  }
                continue
              }
          }
      }
  }
}

function New-SevOneDevice {}

function Set-SevOneDevice {}

function Remove-SevOneDevice {
<##>
[cmdletbinding(SupportsShouldProcess=$true,DefaultParameterSetName='default',ConfirmImpact='high')]
param (
    #
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    $Device
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    Write-Verbose "Opening process block for $($Device.name)"
    if ($PSCmdlet.ShouldProcess("$($Device.name)","Remove SevOne Device"))
      {
        $return = $Global:SevOne.core_deleteDevice($Device.id)
        if ($return -ne 1) {
            Write-Error "failed to delete $($Device.name)"
          }
        continue
      }
  }
}

function Get-SevOneThreshold {
<##>
[cmdletbinding(DefaultParameterSetName='device')]
param (
    #
    [Parameter(Mandatory,
    ParameterSetName='Name')]
    [string]$Name,

    #
    [Parameter(Mandatory,
    ParameterSetName='Name')]
    [Parameter(Mandatory,
    ParameterSetName='ID')]
    [Parameter(Mandatory,
    ParameterSetName='Device',
    ValueFromPipeline,
    ValueFromPipelinebyPropertyName)]
    $Device,

    #
    [Parameter(ParameterSetName='Device')]
    $Object,

    #
    [Parameter(ParameterSetName='Device')]
    $Pluggin,

    #
    [Parameter(ParameterSetName='Device')]
    $Indicator,

    #
    [Parameter(Mandatory,
    ParameterSetName='ID')]
    [int]$ID
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    switch ($PSCmdlet.ParameterSetName)
      {
        'Name' {
            $return = $Global:SevOne.threshold_getThresholdByName($Device.id,$Name)
            continue
          }
        'Device' {
            $return = $Global:SevOne.threshold_getThresholdsByDevice($Device.id,$Pluggin.id,$Object.id,$Indicator.id)
            continue
          }
        'ID' {
            $return = $Global:SevOne.threshold_getThresholdById($Device.id,$ID)
            continue
          }
      }
    $return | __ThresholdObject__
  }
}

function New-SevOneThreshold {}

function Set-SevOneThreshold {}

function Remove-SevOneThreshold {}

function Get-SevOneObjectGroup {
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    #
    [Parameter(Mandatory,
    ParameterSetName='ID')]
    [int]$ID
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    Write-Debug 'opened process block'
    switch ($PSCmdlet.ParameterSetName)
      {
        'Default' {
            Write-Debug 'in Default block'
            $return = $Global:SevOne.group_getObjectGroups()
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
        'ID' {
            Write-Debug 'in ID block'
            $return = $Global:SevOne.group_getObjectGroupById($ID)
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
      }
    Write-Debug 'Sending $return to object creation'
    $return | __ObjectGroupObject__
  }
end {}
}

function Get-SevOneObjectClass {
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    #
    [Parameter(Mandatory,
    ParameterSetName='Name')]
    [string]$Name,

    #
    [Parameter(Mandatory,
    ParameterSetName='ID')]
    [int]$ID
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    switch ($PSCmdlet.ParameterSetName)
      {
        'Default' {
            $return = $Global:SevOne.group_getObjectClasses()
            continue
          }
        'Name' {
            $return = $Global:SevOne.group_getObjectClassByName($Name)
            continue
          }
        'ID' {
            $return = $Global:SevOne.group_getObjectClassById($ID)
            continue
          }
      }
    $return | __ObjectClass__
  }
}  


function Get-SevOneDeviceClass {
<##>
[cmdletbinding(DefaultParameterSetName='device')]
param (
    #
    [Parameter(Mandatory,
    ParameterSetName='Name')]
    [string]$Name,

    #
    [Parameter(Mandatory,
    ParameterSetName='ID')]
    [int]$ID
  )
begin {
    Write-Verbose 'Starting operation'
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    Write-Verbose 'Connection verified'
    Write-Debug 'finished begin block'
  }
process {
    switch ($PSCmdlet.ParameterSetName)
      {
        'Default' {
            $return = $Global:SevOne.group_getDeviceClasses()
            continue
          }
        'Name' {
            $return = $Global:SevOne.group_getDeviceClassByName($Name)
            continue
          }
        'ID' {
            $return = $Global:SevOne.group_getDeviceClassById($ID)
            continue
          }
      }
    $return | __DeviceClass__
  }
}

Export-ModuleMember -Function *-* 