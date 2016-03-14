$SevOne = $null

function __TestSevOneConnection__ { # Needs to be here until I figure out how to share the API var between files
  #Write-Verbose 'testing API connection by calling the returnthis() method'
  #Write-Debug 'Begin test'
  try {[bool]$SevOne.returnthis(1)} catch {$false}
}

function __userFactory__ {
$SevOne.factory_User()
}

#$TimeZones = Get-Content -Path $PSScriptRoot\timezones.txt
# Indicators, Objects

# Group > Device > object > indicator

# Device Groups and Object Groups

# Group membership can be explicit or rule based

# for object group the device group is required

#region Connection
function Connect-SevOne {
<#
  .SYNOPSIS
     Create a connection to a SevOne Instance 
  .DESCRIPTION
     Creates a SOAP API connection to the specified SevOne Management instance.

     Only one sevone connection is available at any time.  Creating a new connection will overwrite the existing connection.
  .EXAMPLE
     Connect-SevOne -ComputerName 192.168.0.10 -credential (get-credential)

     Establishes a new connection to the SevOne Management server at 192.168.0.10

  .EXAMPLE
    $Cred = get-credential

    # Stores credentials inside the Variable Cred

    $SevOneName = 'MySevOneAppliance'

    # Stores the hostname

    Connect-SevOne $SevOneName $Cred

    # Connects to the SevOne Appliance MySevOneAppliance.  In this example the parameters are called positionally.

    # if you're unsure about your credentials you can check the username and password with the following commands:
    $Cred.UserName
    $Cred.GetNetworkCredential().password
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
    [switch]$UseSSL,

    # Set this option if you would like to expose the SevOne SOAP API Object
    [Parameter(ParameterSetName='Default')]
    [switch]$ExposeAPI
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
    $Script:SevOne = $Client
    if ($ExposeAPI) {$Client}
    Write-Verbose 'Successfully connected to SevOne Appliance'
}
#endregion Connection

#region Users
function Get-SevOneUser {
<#
  .SYNOPSIS
    Gets a SevOne user object

  .DESCRIPTION
    Can grab all users or a user by id

  .EXAMPLE
    Get-SevOneUser

    ---------------------
    Gathers all the users for a given SevOne instance

  .NOTES
#>
[cmdletbinding(DefaultParameterSetName='none')]
param (
    [parameter(Mandatory,
    ParameterSetName='id')]
    [int]$Id
  )
begin {
  if (-not (__TestSevOneConnection__)) {
    throw 'Not connected to a SevOne instance'
  }
}
process {
  $return = @()
  switch ($PSCmdlet.ParameterSetName)
  {
    'none' {$return = $SevOne.user_getUsers()}
    'Id' {$return = $SevOne.user_getUserById($Id)}
  }
  $return.foreach{[User]$_}
}
}

#Still need to add a class for this
function Get-SevOneUserRole {
<#
  .SYNOPSIS
    Gets the available SevOne User Roles

  .DESCRIPTION
    Use this function to either gather a single user role or all available roles

  .EXAMPLE
    Get-SevOneUserRole

    -------------------------

    Returns all available user roles

  .NOTES
#>
[cmdletbinding(DefaultParameterSetName='none')]
param (
  [Parameter(Mandatory,
  ParameterSetName='Id')]
  $Id
)
begin {
  if (-not (__TestSevOneConnection__)) {
    throw 'Not connected to a SevOne instance'
  }
}
process {
  $return = @()
  switch ($PSCmdlet.ParameterSetName)
  {
    'none' {$return = $SevOne.user_getRoles()}
    'id' {$return = $SevOne.user_getRoleById($Id)}
  }
  $return.foreach{[userRole]$_}
}
}

function New-SevOneUser {
<#
  .SYNOPSIS
    Creates a new SevOne user

  .DESCRIPTION
    Use this function to create a new SevOne User

  .EXAMPLE
    $role = Get-SevOneUserRole -id 2

    New-SevOneUser -UserCredential (get-Credential User1) -EmailAddress user@contoso.com -Role $role -FirstName user -LastName 1 -Authentication SevOne -Passthrough

    ------------------------------------

  
  .NOTES
#>
[cmdletbinding()]
param (
    [parameter(Mandatory)]
    [pscredential]$UserCredential,
    [parameter(Mandatory)]
    [string]$EmailAddress,
    [parameter(Mandatory)]
    [userRole]$Role,
    [parameter(Mandatory)]
    [string]$FirstName,
    [parameter(Mandatory)]
    [string]$LastName,
    [parameter(Mandatory)]
    [validateset('SevOne','LDAP','TACACS','RADIUS')]
    [string]$Authentication,
    [switch]$Passthrough
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    $user = __userFactory__
    $user.firstName = $FirstName
    $user.lastName = $LastName
    $user.email = $EmailAddress
    $user.username = $UserCredential.UserName
    $user.Authentication = $Authentication
    Write-Debug "User loaded for $($UserCredential.UserName), ready to createuser()"
    $return = $SevOne.user_createUser($user,$Role.id,$UserCredential.GetNetworkCredential().Password)
    if ($Passthrough) {
        Get-SevOneUser -Id $return
      }
  }
}

#endregion Users

#region Groups

function Get-SevOneDeviceGroup { # 
<#
  .SYNOPSIS
    returns device groups

  .DESCRIPTION
    This function will return one or more device groups

  .EXAMPLE
    Get-SevOneDeviceGroup

  .NOTES
    not failing when group doesn't exist, we can probably copy the functionality out of the Device function.

    It's likely that we can combine this with the Object Group function

    Additionally it looks like the API uses Device Group and Device Class interchangeably.  We may be able to eliminate the DeviceClass functions.
#>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    #
    [Parameter(Mandatory,
    ParameterSetName='Name')]
    [string]$Name,

    # Specify the name of the Parent Group
    [Parameter(
    ParameterSetName='Name')]
    [string]$ParentGroup = $null,
     
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
    $return = @()
    switch ($PSCmdlet.ParameterSetName)
      {
        'Default' {
            Write-Debug 'in Default block'
            $return = $SevOne.group_getDeviceGroups()
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
        'Name' {
            Write-Debug 'in Name block'
            $return = $SevOne.group_getDeviceGroupById($SevOne.group_getDeviceGroupIdByName($ParentGroup ,$Name)) # only returning one result
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
        'ID' {
            Write-Debug 'in ID block'
            $return = $SevOne.group_getDeviceGroupById($ID)
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
      }
    Write-Debug 'Sending $return to object creation'
    $return.foreach{[deviceGroup]$_}
  }
end {}
}

function Set-SevOneDeviceGroup {}

function New-SevOneDeviceGroup {
<#
  .SYNOPSIS
    Create a new SevOne Device group
  .DESCRIPTION
    This function will create a new SevOne Device group, the new ID will be generated by the system.  The Parent group and Name are required.
#>
[cmdletBinding(DefaultParameterSetName='group')]
param (
    # ID of the parent group
    [Parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='id')]
    [int]$ParentID,

    # Group object for parent group
    [Parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    $ParentGroup,
    
    # The name for the new group
    [Parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    [Parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='id')]
    [string]$Name,

    # Set if you would like the new group to be output to the pipeline
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='id')]
    [switch]$PassThrough
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
        'group' {
            $return = $SevOne.group_createDeviceGroup($Name,$ParentGroup.ID)
            Write-Debug 'Finished generating $return'
          }
        'id' {
             $return = $SevOne.group_createDeviceGroup($Name,$ParentID)
             Write-Debug 'Finished generating $return'
          }
      }
    switch ($return)
      {
        -1 {Write-Error "Could not create group: $Name" ; continue}
        default {
            Write-Verbose "Successfully created group $Name" 
            if ($PassThrough) {Get-SevoneDeviceGroup -ID $return}
            continue
          }
      }
  }
end {}
}

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
            $return = $SevOne.group_getObjectGroups()
            Write-Debug "`$return has $($return.Count) members"
            continue
          }
        'ID' {
            Write-Debug 'in ID block'
            $return = $SevOne.group_getObjectGroupById($ID)
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
<#

#>
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
            $return = $SevOne.group_getObjectClasses()
            continue
          }
        'Name' {
            $return = $SevOne.group_getObjectClassByName($Name)
            continue
          }
        'ID' {
            $return = $SevOne.group_getObjectClassById($ID)
            continue
          }
      }
    $return | __ObjectClass__
  }
} 

function Add-SevOneDeviceToGroup {
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [PSObject]$Device,
    [parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [PSObject]$Group,
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='ID')]
    [int]$DeviceID,
    [parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='ID')]
    [int]$GroupID
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
            $return = $SevOne.group_addDeviceToGroup($Device.ID,$Group.ID)
          }
        'ID' {
            $return = $SevOne.group_addDeviceToGroup($DeviceID,$GroupID)
          }
      }
    switch ($return)
      {
        0 {Write-Error 'Could not add device to group' ; continue}
        default {
            Write-Verbose 'Successfully created added device to group'
            continue
          }
      }
  }
end {}
}

function Add-SevOneObjectToGroup {
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    #
    [parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [PSObject]$Group,
    #
    [parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [PSObject]$Object,
    #
    [parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [PSObject]$Plugin
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
            $return = $SevOne.group_addObjectToGroup($Object.deviceid,$Object.id,$Group.id,$Plugin.id)
          }
      }
    switch ($return)
      {
        0 {Write-Error "Could not add object, $($Object.name) to group" ; continue}
        default {
            Write-Verbose 'Successfully created added device to group'
            continue
          }
      }
  }
end {}
}

#endregion Groups

#region Objects
function Get-SevOneObject {
<##>
[cmdletbinding(DefaultParameterSetName='device')]
param (
    # The Device that will be associated with Alarms pulled
    [parameter(Mandatory,
    Position=0,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Device')]
    [parameter(Mandatory,
    Position=0,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Plugin')]
    [PSObject]$Device,

    #
    [parameter(Mandatory,
    Position=1,
    ParameterSetName='Plugin')]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    $return = @()
    switch ($PSCmdlet.ParameterSetName)
      {
        'device' {$return = $SevOne.core_getObjectsByDeviceID($device.id)}
        'plugin' {$return = $SevOne.core_getObjectsByDeviceIDAndPlugin($device.id,$Plugin)}
      }
    $return.foreach{[Object]$_}
  }
}

function New-SevOneObject { 
<##>
[cmdletbinding(DefaultParameterSetName='device')]
param (
    #
    [parameter(Mandatory,
    Position=0,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Plugin')]
    $Name,
    
    #
    [parameter(Mandatory,
    Position=1,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Plugin')]
    $ObjectType,

    # The Device that will be associated with Alarms pulled
    [parameter(Mandatory,
    Position=2,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Plugin')]
    [PSObject]$Device,

    #
    [parameter(Mandatory,
    Position=3,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Plugin')]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin
  )
begin {
  if (-not (__TestSevOneConnection__)) {
      throw 'Not connected to a SevOne instance'
    }
  Write-Verbose "creating object $name of type $($ObjectType.name)"
  Write-Debug 'Ready to create object'
  $method = "plugin_$plugin`_getObjectTypes"
  $types = $SevOne.$method()
  if ($ObjectType.name -notin $types.name)
    {throw 'no such type exists'}
  $objectTypeID = $types.where{$_.name -match $ObjectType.name}.id
}
process {
  switch ($PSCmdlet.ParameterSetName)
  {
    'plugin' {
      $method = "plugin_$Plugin`_createobject"
      $return = $SevOne.$method($Device.id,$objectTypeID,$Name)
      if ($return -eq 0)
        {Write-Error "failed to create object : $Name"}
    }
  }
}
}

function Get-SevOneObjectType {
[cmdletbinding(DefaultParameterSetName='all')]
param (
    #Set the Plugin Name
    [parameter(Mandatory,
    Position=0,
    ParameterSetName='OS')]
    [parameter(Mandatory,
    Position=0,
    ParameterSetName='All')]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin,

    # Specify a SevOne OSid must be an integer
    [parameter(Mandatory,
    Position=1,
    ParameterSetName='OS')]
    [alias('OSid')]
    [int]$DeviceClass
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    switch ($PSCmdlet.ParameterSetName)
      {
        All {
            $method = "plugin_$Plugin`_getobjecttypes"
            $return = $SevOne.$method()
            $return | __ObjectType__
          }
        OS {
            $method = "plugin_$Plugin`_getobjecttypes"
            $return = $SevOne.$method($DeviceClass)
            $return | __ObjectType__
          }
      }
  }
}

function New-SevOneObjectType {
param (
    #Set the Plugin Name
    [parameter(Mandatory,
    Position=0)]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin,

    # Specify a SevOne OSid must be an integer
    [parameter(
    Position=2)]
    [alias('OSid')]
    [int]$DeviceClass = 0,

    #
    [Parameter(Mandatory,
    Position = 1)]
    [string]$Name
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    $method = "plugin_$Plugin`_createObjectType"
    $return = $SevOne.$method(0,$Name,$null)
    if ($return -eq 0) {Write-Error "failed to create object $name"}
  }
}

#endregion Objects

#region Peers

function Get-SevOnePeer {
<#
  .SYNOPSIS
    Gathers one or more SevOne Peers.

  .DESCRIPTION
    This function will gather Peer objects for one or more peers in the SevOne environment. By default it will return a peer object for every peer connected.  if you specify the -ID parameter only the Peer with the corresponding ID will be returned.

  .EXAMPLE
    Get-SevOnePeer

    returns all Sevone Peers in the connected environment

  .EXAMPLE 
    Get-SevOnePeer -ID 26

    returns the SevOne peer with an ID of 26

  .NOTES

#>
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
    $return = @()
    switch ($PSCmdlet.ParameterSetName)
      {
        'default' {
            $return = $SevOne.core_getPeers()
            continue
          }
        'id' {
            $return = $SevOne.core_getPeerById($id)
            continue
          }
      }
    $return.foreach{[Peer]$_}
  }
}

#endregion Peers

#region Plugins

Function Enable-SevOnePlugin {
param (
    # Specify SevOne Device to be modified
    [Parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device,

    # specify plugin to be enabled
    [parameter(Mandatory,
    Position=1)]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    $method = "plugin_$plugin`_enablepluginfordevice"
    $return = $SevOne.$method($Device.id,1)
    $return | __TestReturn__
}
}

Function Disable-SevOnePlugin {
param (
    # Specify SevOne Device to be modified
    [Parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device,

    # specify plugin to be disabled
    [parameter(Mandatory,
    Position=1)]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    $method = "plugin_$plugin`_enablepluginfordevice"
    $return = $SevOne.$method($Device.id,0)
    $return | __TestReturn__
}
}

function Test-SevOnePlugin {
param (
    # Specify SevOne Device to be tested
    [Parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device,

    # specify plugin to be tested
    [parameter(Mandatory,
    Position=1)]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin,

    # Set to return only a boolean
    [switch]$Quiet
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    $return = $SevOne.core_getEnabledPluginsByDeviceId($Device.id)
    if ($Plugin -in $return) {
        switch ($Quiet)
          {
            $true {$true}
            $false {
                [pscustomobject]@{
                    ComputerName = $Device.Name
                    Enabled = $true
                  }
              }
          }
      }
    else {
        switch ($Quiet)
          {
            $true {$false}
            $false {
                [pscustomobject]@{
                    ComputerName = $Device.Name
                    Enabled = $false
                  }
              }
          }
      }
  }
}

function Get-SevOnePlugin {
<#
  .SYNOPSIS
    Gather SevOne plugins
  .DESCRIPTION
    This function will gather all SevOne plugin objects
  .NOTES
#>
[cmdletBinding(DefaultParameterSetName='default')]
param (
    [parameter(
    Mandatory,
    ParameterSetName='Name')]
    $Name
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
    $return = @()
    switch ($PSCmdlet.ParameterSetName)
      {
        'default' {
          $return = $SevOne.core_getPlugins()
        }
        'name' {
          $return = $SevOne.core_getPlugins().where{$_.name -match $name}
          if ($return.count -eq 0) {
            Write-Warning "No plugin found for $name"
          }
        }
      }
    $return.foreach{[Plugin]$_}
  }
end {}
  }

function Set-SevOneSNMPPlugin {
[cmdletbinding()]
param (
    [Parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    $Device,
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [Bool]$SNMPCapable = $true,

    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [int]$SNMPVersion = 2,

    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [string]$SNMPROCommunity = '',

    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [string]$SNMPRwCommunity = '',

    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [int]$SNMPPort = 161
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
    Write-Debug ''
    $return = $SevOne.core_setDeviceSnmpInformation($Device.id,[int]($SNMPCapable),$SNMPPort,$SNMPVersion,$SNMPROCommunity,$SNMPRwCommunity,-1,-1)
    $return | __TestReturn__
  }
}

function Set-SevOneWMIPlugin {
<#
  .SYNOPSIS

  .DESCRIPTION

  .EXAMPLE
    
  .EXAMPLE
    
  .EXAMPLE
    
  .NOTES
    
#>
[cmdletbinding(DefaultParameterSetName='default')]
param
  (
    #
    [parameter(Mandatory,
    ParameterSetName='ProxyOnly',
    ValueFromPipelineByPropertyName)]
    [switch]$ProxyOnly,

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [bool]$Enabled, 

    #
    [parameter(Mandatory,
    ParameterSetName='ProxyOnly',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    $Device,

    #
    [parameter(
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [parameter(Mandatory,
    ParameterSetName='ProxyOnly',
    ValueFromPipelineByPropertyName)]
    $Proxy,

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [bool]$UseNTLM,

    # Be sure to omit domain info
    [parameter(
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [pscredential]$Credential,

    #
    [parameter(
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [string]$Domain,

    #
    [parameter(
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [validateSet('Default','None','Connect','Call','Packet','PacketIntegrity','PacketPrivacy','Unchanged')]
    [string]$AuthenticationLevel = 'default',

    #
    [parameter(
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [validateSet('Default','Anonymous','Delegate','Identify','Impersonate')]
    [string]$ImpersonationLevel = 'default'
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
            $UserName = $Credential.UserName
            if ($UserName -like '*\*')
              {
                $UserName = $UserName.Split('\')[-1]
              }
            switch ($Enabled) { 
                $true {Set-SevOneWMIProxy -Enabled $true -Device $Device}
                $false {Set-SevOneWMIProxy -Enabled $true -Device $Device}
              }
            if ($Proxy) { 
                $return = $SevOne.plugin_wmi_setProxy($Device.id,$Proxy.id)
                $return | __TestReturn__
              }
            if ($UseNTLM)
              {
              $PSCmdlet.PagingParameters # this is wrong, not sure how it got there.
              }
            $return = $SevOne.plugin_wmi_setUseNTLM($Device.id,([int]$UseNTLM).ToString())
            $return | __TestReturn__
            $return = $SevOne.plugin_wmi_setWorkgroup($device.id, $Domain)
            $return | __TestReturn__
            $return = $SevOne.plugin_wmi_setUsername($Device.id, $UserName)
            $return | __TestReturn__
            $return = $SevOne.plugin_wmi_setPassword($Device.id, $Credential.GetNetworkCredential().Password)
            $return | __TestReturn__
            $return = $SevOne.plugin_wmi_setAuthenticationLevel($Device.id, $AuthenticationLevel)
            $return | __TestReturn__
            $return = $SevOne.plugin_wmi_setImpersonationLevel($Device.id, $ImpersonationLevel)
            $return | __TestReturn__
          }
        'ProxyOnly' {
            $return = $SevOne.plugin_wmi_setProxy($Device.id,$Proxy.id)
            $return | __TestReturn__
          }
      }
    
  }
}

function Set-SevOneICMPPlugin {
param (
    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [bool]$Enabled, 

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
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
    $return = $Sevone.plugin_ICMP_enablepluginfordevice($Device.id,[int]$Enabled)
    $return | __TestReturn__
  }
}

function Get-SevOneEnabledPlugin {
param (
    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
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
    $return = $SevOne.core_getEnabledPluginsByDeviceId($device.id)
    $return | foreach {
        Get-SevOnePlugin -Name $_
      }
  }
}

# Not implemented

function Set-SevOneCUCMPoller {
param (
    $Device,
    [bool]$Enabled
  )

#mtheods
# plugin_calld_enablePluginForDevice
# plugin_callmanager_enablePluginForDevice
}

#endregion Plugins

#region WMIProxy

function Get-SevOneWMIProxy {
<#
  .SYNOPSIS

  .DESCRIPTION

  .EXAMPLE
    

  .EXAMPLE
    

  .EXAMPLE
    

  .NOTES
    At this point there is no support for wildcards.
#>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    [Parameter(Mandatory,
    ParameterSetName='filter')]
    $filter,

    [Parameter(Mandatory,
    ParameterSetName='id')]
    [alias('Proxyid')]
    $ID,

    [Parameter(Mandatory,
    ParameterSetName='device',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    Write-Verbose 'Opening process block'
    Write-Debug "Switch on parameter set name, current value: $($PSCmdlet.ParameterSetName)"
    switch ($PSCmdlet.ParameterSetName)
      {
        id { $SevOne.plugin_wmi_getProxyById($id) ; continue }
        device { $return =  $SevOne.plugin_wmi_getWmiDevicesById($device.ID) 
            $return | Add-Member -MemberType NoteProperty -Name Proxy -Value (Get-SevOneWMIProxy -id $return.proxyid).name -PassThru
          }
        'filter' {
            Write-Debug 'in filter block'
            $SevOne.plugin_wmi_findProxy($filter)
            Write-Debug 'finished finding proxies'
            #filter = ,@('Name',$name),@('ip',$ip)         
          }
        'default' { $SevOne.plugin_wmi_findProxy('') ; continue}
      }
  }
}

function New-SevOneWMIProxy {
<#
  .SYNOPSIS

  .DESCRIPTION

  .EXAMPLE
    
  .EXAMPLE
    
  .EXAMPLE
    
  .NOTES
    
#>
[cmdletbinding(DefaultParameterSetName='default')]
param
  (
    #
    [parameter(Mandatory,
    ParameterSetName='default',
    ValueFromPipelineByPropertyName)]
    [string]$Name,
    
    #
    [parameter(Mandatory,
    ParameterSetName='default',
    ValueFromPipelineByPropertyName)]
    [int]$Port,
    
    #
    [parameter(Mandatory,
    ParameterSetName='default',
    ValueFromPipelineByPropertyName)]
    [IPAddress]$IPAddress
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    Write-Verbose 'begin process block'
    switch ($PSCmdlet.ParameterSetName)
      {
        'default' {$return = $SevOne.plugin_wmi_createProxy($Name,$IPAddress.IPAddressToString,$Port.ToString()) }
      }
    switch ($return)
      {
        0 {Write-Error "Failed to create Proxy $Name"}
        default {Write-Verbose "Successfully created proxy: $Name"}
      }
  }
}

function Set-SevOneWMIProxy {
<#
  .SYNOPSIS

  .DESCRIPTION

  .EXAMPLE
    
  .EXAMPLE
    
  .EXAMPLE
    
  .NOTES
    
#>
[cmdletbinding(DefaultParameterSetName='default')]
param
  (
    #
    [parameter(Mandatory,
    position = 0,
    ParameterSetName='default',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device,

    #
    [parameter(Mandatory,
    position = 1,
    ParameterSetName='default',
    ValueFromPipelineByPropertyName)]
    [bool]$Enabled 
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
  }
process {
    $return = $SevOne.plugin_wmi_enablePluginForDevice($Device.id, [int]$Enabled)
    switch ($return)
      {
        0 {Write-Error "Failed to set WMI plugin on $($Device.name)" ; continue}
        1 {Write-Verbose "Successfully set plugin on $($Device.name)" ; continue}
        default {throw "unexpected return code: $return" }
      }
  }
}

function Add-SevOneWMIProxytoDevice {
<#
  .SYNOPSIS

  .DESCRIPTION

  .EXAMPLE
    
  .EXAMPLE
    
  .EXAMPLE
    
  .NOTES
    
#>
[cmdletbinding(DefaultParameterSetName='default')]
param
  (
    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    $Device,

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    $Proxy,

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [bool]$UseNTLM,

    # Be sure to omit domain info
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [pscredential]$Credential,

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [string]$Domain,

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [validateSet('Default','None','Connect','Call','Packet','PacketIntegrity','PacketPrivacy','Unchanged')]
    [string]$AuthenticationLevel = 'default',

    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipelineByPropertyName)]
    [validateSet('Default','Anonymous','Delegate','Identify','Impersonate')]
    [string]$ImpersonationLevel = 'default'
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
    $UserName = $Credential.UserName
    if ($UserName -like '*\*')
      {
        $UserName = $UserName.Split('\')[-1]
      }
    Set-SevOneWMIProxy -Enabled $true -Device $Device
    $return = $SevOne.plugin_wmi_setProxy($Device.id,$Proxy.id)
    $return | __TestReturn__
    $return = $SevOne.plugin_wmi_setUseNTLM($Device.id,([int]$UseNTLM).ToString())
    $return | __TestReturn__
    $return = $SevOne.plugin_wmi_setWorkgroup($device.id, $Domain)
    $return | __TestReturn__
    $return = $SevOne.plugin_wmi_setUsername($Device.id, $UserName)
    $return | __TestReturn__
    $return = $SevOne.plugin_wmi_setPassword($Device.id, $Credential.GetNetworkCredential().Password)
    $return | __TestReturn__
    $return = $SevOne.plugin_wmi_setAuthenticationLevel($Device.id, $AuthenticationLevel)
    $return | __TestReturn__
    $return = $SevOne.plugin_wmi_setImpersonationLevel($Device.id, $ImpersonationLevel)
    $return | __TestReturn__
  }
}

function Optimize-SevOneWMIProxy {
    [cmdletbinding()]
    param ($device,
        $WMIProxy
    )
    $max = $WMIProxy.count
    Write-Debug "`$max = $max"
    Write-Debug "`$Device.count $($device.count)"
    $i = 0
    foreach ($d in $device)
    {
        Write-Verbose 'in foreach block'
        Write-Verbose "Device: $($d.name)"
        Set-SevOneWMIPlugin -Proxy $WMIProxy[$i] -Device $d -ProxyOnly
        Write-Debug "set proxy on $($d.name)"
        $i++
        Write-Verbose "`$i = $i"
        if ($i -eq $max) {$i = 0}
        Write-Debug "finished foreach loop for $($d.name)"
    }    
}

#endregion WMIProxy

#region Discovery

function Enable-SevOneDiscovery {
param (
    #
    [parameter(Mandatory,
    ParameterSetName='default',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device,

    #
    [parameter()]
    [validateSet('automatic','manual','both')]
    $Type = 'Automatic'
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
    switch ($Type) {
        'automatic' {
            $return = $SevOne.core_setDeviceDiscovery($Device.id,'1')
          }
        'manual' {
            $return = $SevOne.core_setDeviceManualDiscovery($Device.id,'1')
          }
        'both' {
            $return = $SevOne.core_setDeviceDiscovery($Device.id,'1')
            $return | __TestReturn__
            $return = $SevOne.core_setDeviceManualDiscovery($Device.id,'1')
          }
      }
    $return | __TestReturn__
  }
}

function Disable-SevOneDiscovery {
param (
    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device,
    [parameter(ParameterSetName='default')]
    [validateset('automatic','manual','all')]
    [string]$Type
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
    switch ($Type) {
        'automatic' {
            $return = $SevOne.core_setDeviceDiscovery($Device.id,'0')
          }
        'manual' {
            $return = $SevOne.core_setDeviceManualDiscovery($Device.id,'0')
          }
        'both' {
            $return = $SevOne.core_setDeviceDiscovery($Device.id,'0')
            $return | __TestReturn__
            $return = $SevOne.core_setDeviceManualDiscovery($Device.id,'0')
          }
      }
    $return | __TestReturn__
  }
}

function Start-SevOneDiscovery {
param (
    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $Device,

    [Parameter(ParameterSetName='Default')]
    [switch]$Wait
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
  $return = $SevOne.core_rediscoverDevice($Device.id)
  $return | __TestReturn__
  if ($wait) {
    do {$dev = Get-SevOneDevice -ID $Device.id ; Write-warning "Waiting for discovery to finish on $($device.name)"; Start-Sleep -Seconds 10} until (
      $dev.discoverStatus -eq 0 -and (! $dev.discoverPriority)
    )
  } 
}
}

#endregion Discovery

#region Alerts

function Get-SevOneTrap {
<#
  .SYNOPSIS

  .DESCRIPTION

  .EXAMPLE

  .NOTES
#>
param (
    [string]$OID,
    [datetime]$Starttime,
    [datetime]$Endtime,
    [parameter(Mandatory)]
    [psobject]$Peer,
    [bool]$IsLogged,
    [int]$PageSize,
    [int]$PageNumber,
    [timespan]$timeout
  )
begin {} #Add test connection block
process {
    $keys = @()
    $null = $keys += $SevOne.factory_KeyValue('peerId',$Peer.serverid)
    if ($Starttime ) {$null = $keys += $SevOne.factory_KeyValue('startTime',($Starttime | Convertto-UNIXTime)) }
    if ($Endtime ) {$null = $keys += $SevOne.factory_KeyValue('endTime',($Endtime | Convertto-UNIXTime)) } 
    if ($OID) {$null =  $keys += $SevOne.factory_KeyValue('oid',$OID)}
    if ($IsLogged -ne $null) {$null = $keys += $SevOne.factory_KeyValue('isLogged',[int]$IsLogged)}
    if ($PageSize) {$null = $keys += $SevOne.factory_KeyValue('pageSize',$PageSize)}
    if ($PageNumber) {$null = $keys += $SevOne.factory_KeyValue('pageNumber',$PageNumber)}
    if ($timeout) {
        $old = $SevOne.Timeout
        $SevOne.Timeout = $timeout.Milliseconds
      }
    Write-Debug 'Finished Creating $keys'
    $SevOne.trap_get($keys)
    if ($old) {
        $SevOne.Timeout = $old
      }
  }
}

function Get-SevOneAlert {
<#
  .SYNOPSIS
    Gather open alerts in the SevOne environment.

  .DESCRIPTION
    This function is able to gather alerts generally or on a by device basis.  You can also use -StartTime to filter return data by starttime.  Only open alerts are gathered with this function.

  .EXAMPLE
    Get-SevOneAlert

    returns all active alerts

  .EXAMPLE
    Get-SevOneDevice -Name MyServer | Get-SevOneAlert

    returns all active alerts for the device, MyServer

  .NOTES
    Only gathers open alerts
    Starttime filters on the client side and not the Server side

#>
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
    [datetime]$StartTime # not sure I'm happy with the way this parameter is implemented. The filtering occurs on the client side which is pretty wasteful.  Need to explore the API's filtering capabilities.
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
            $return = $SevOne.alert_getAlerts(0)
          }
        'device' {
            $return = $SevOne.alert_getAlertsByDeviceId($Device.id,0)
          }
      }
    foreach ($a in ($return))
      {
        [alert]$a = $a
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
<#
  .SYNOPSIS
    Closes a SevOne Alert 

  .DESCRIPTION
    This function will close one or more SevOne Alerts

  .EXAMPLE
    Get-SevOneAlert | Close-SevOneAlert -message "clearing all alerts"

    Closes all open alerts and appends a message saying, "clearing all alerts"

  .EXAMPLE
    $Device = Get-SevOneDevice -Name MyServer

    $Alert = Get-SevOneAlert -Device $Device

    Close-SevOneAlert -Alert $Alert

  .NOTES
    This one is working really well, the default message may change over time.
#>
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
        $return = $SevOne.alert_clearByAlertId($Alert.ID,$Message)
        $return | __TestReturn__
      }
    catch {}
  }
end {}
}

#endregion Alerts

#regions Devices

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
    $return = @()
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
        $return.foreach{[device]$_}
      }
  }
}

function New-SevOneDevice {
<##>
[cmdletBinding(DefaultParameterSetName='group')]
param (    
    #
    [Parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    [string]$Name,
    
    #
    [Parameter(Mandatory,
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    [ipaddress]$IPAddress,
    
    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    $Peer = (Get-SevOnePeer)[0], # this is actually pretty hokey, will need to find a better way to do this.
    
    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    $Group = (Get-SevOneDeviceGroup -Name 'All Device Groups'),

    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    [ValidateLength(1,255)]
    [string]$Description = '',

    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='group')]
    [switch]$PassThrough
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
        'group' {
            Write-Debug 'In group block'
            $return = $SevOne.core_createDeviceInGroup($Name,$IPAddress.IPAddressToString,$Peer.id,$Description,$Group.id)
            Write-Verbose 'finished create operation, testing $return'
            Write-Debug "`$return = $return"
            switch ($return)
              {
                -1 {Write-Error "Could not add device: $Name" ; continue}
                -2 {Write-Error "Could not find peer: $($Peer.Name)" ; continue}
                -3 {Write-Error "$($Peer.Name) does not support adding devices" ; continue}
                0 {Write-Error "failed creating device $name" ; continue}
                default {
                    Write-Verbose "Successfully created device $Name"
                    if ($PassThrough) {Get-SevOneDevice -ID $return}
                  }
              }
          }
      }
  }
end {}
}

function Set-SevOneDevice { # currently a pretty sad function, we can change the polling interval and the timezone.
<##>
[cmdletBinding(DefaultParameterSetName='default')]
param ( 
    #
    [Parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    $Device,
       
    
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [string]$Name,

    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [string]$AlternateName,

    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [ipaddress]$IPAddress,

    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [validatelength(0,255)]
    [string]$Description = '',

    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    #[validateSet({$TimeZones})] # try and imporve this to support tab completion
    [string]$TimeZone,

    #
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [timespan]$PollingInterval,

    
    [Parameter(
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    [bool]$Polling

    
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
    Write-Verbose "Opening Process block for $($Device.name)"
    
    $xml = $SevOne.core_getDeviceById($device.id)
    Write-Debug 'loaded $xml'
    #region SetValues
    if ($Name) {$xml.name = $Name}
    if ($AlternateName) {$xml.alternateName = $AlternateName}
    if ($IPAddress) {$xml.ip = $IPAddress.IPAddressToString}
    if ($Description) {$xml.description = $Description}
    if ($TimeZone) {$xml.timezone = $TimeZone}
    if ($PollingInterval) {$xml.pollFrequency = $PollingInterval.TotalSeconds}
    #if ($PollingConcurrency) {$xml.p}
    if ($Polling) {$xml.disablePolling = [int](-not $Polling) }
    #if ($DiscoveryLevel) {$xml.discoverPriority = }
    if ($SNMPVersion) {$xml.snmpVersion = $SNMPVersion}
    if ($SNMPROCommunity) {$xml.snmpRoCommunity = $SNMPROCommunity}
    if ($SNMPRwCommunity) {$xml.snmpRwCommunity = $SNMPRwCommunity}
    Write-Debug 'Finished modifying XML'
    #endregion SetValues
    $return = $SevOne.core_setDeviceInformation($xml)
    Write-Debug 'Finished setting device, $return is about to be tested'
    $return | __TestReturn__
    <#if ($TimeZone) {
        $return = $SevOne.core_setDeviceTimezone($device.id, $TimeZone)
        $return | __TestReturn__
      }
    if ($PollingInterval) {
        $return = $SevOne.core_setDevicePollingFrequency($device.id, $PollingInterval.TotalSeconds)
        $return | __TestReturn__
      }#>
    Write-Verbose "Succesfully modified $($device.name)"
  }
}

#endregion Devices

#region Reports

function Get-SevOneReport {
<##>
[cmdletbinding(DefaultParameterSetName='default')]
param (
    [parameter(Mandatory,
    parameterSetName='ID')]
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
    Switch ($PSCmdlet.ParameterSetName)
      {
        'default' {$SevOne.report_getReports()}
        'id' {$SevOne.report_getReportById($ID) }
      }
    
  }
end {}
}

function Get-SevOneReportAttachment {
<##>
[cmdletbinding(DefaultParameterSetName='id')]
param (
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelinebyPropertyName,
    parameterSetName='id')]
    [Alias('ReportID')]
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
    Switch ($PSCmdlet.ParameterSetName)
      {
        'id' {$SevOne.report_getReportAttachmentsByReportId($ID) }
      }
  }
end {}
}

function Get-SevOneGraph {
<##>
[cmdletbinding(DefaultParameterSetName='id')]
param (
    [parameter(Mandatory,
    parameterSetName='id')]
    $Attachment
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
    Switch ($PSCmdlet.ParameterSetName)
      {
        'id' {$SevOne.report_getGraphAttachment($Attachment) }
      }
  }
end {}
}

function New-SevOneGraphDataSource {
param (
    [parameter(Mandatory,
    ValueFromPipeline,
    ValuefromPipelinebyPropertyName)]
    $Indicator,
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin
  )
begin {}
Process {
    $GraphDataSource = $SevOne.factory_GraphDataSource()
    $GraphDataSource.plugin = $Plugin
    $GraphDataSource.objectName = $Indicator.objectName
    $GraphDataSource.indicator = $Indicator.indicatorType
    $GraphDataSource.deviceId = $Indicator.deviceId
    $GraphDataSource
  }
}

function New-SevOneGraph {
param (
    [parameter()]
    [validateset(
        'graph_line',
        'graph_stack',
        'graph_pie',
        'graph_csv',
        'graph_csv_readable'
      )]
    [string]$Type,
    [psobject[]]$Source,
    [bool]$Scaled, #must convert to int
    [validateset('bits','bytes')]
    [string]$DataType,
    [validateset('total','rate')]
    [string]$DisplayType,
    [int]$Percentile, # limit values from 0-100, if set set percentEnabled to 1
    [validateset('small','medium','large')]
    [string]$Size
  )
process {
    $graph = $SevOne.factory_Graph()
    $graph.dataSources = $Source
    if ($Size) {
        switch ($Size)
          {
            'small' {$val = 1}
            'medium' {$val = 2}
            'large' {$val = 3}
          }
        $graph.size = $val
      }
    $graph
  }
}

function New-SevOneTimespan {
param (
    [parameter(Mandatory,
    ParameterSetName='specific')]
    [datetime]$Starttime,
    [parameter(Mandatory,
    ParameterSetName='specific')]
    [datetime]$Endtime,
    [parameter(Mandatory,
    ParameterSetName='general')]
    [validateset(
        'past 4 hours',
        'past 8 hours',
        'today', 
        'yesterday', 
        'past 24 hours', 
        'this week', 
        'last week', 
        'past week', 
        'this month', 
        'last month', 
        'past month',
        'past 4 weeks', 
        'this quarter', 
        'last quarter', 
        'past quarter'
      )]
    $SimpleTimespan
  )
  $base = Get-Date
  $Timespan = $sevOne.factory_Timespan()
  switch ($PSCmdlet.ParameterSetName)
    {
      'specific' {
          $Timespan.startTime = $Starttime | Convertto-UNIXTime
          $Timespan.endTime = $Endtime | Convertto-UNIXTime
        }
      'general' {
          $Timespan.startTime = $base | Convertto-UNIXTime
          $Timespan.endTime = $base | Convertto-UNIXTime          
          $Timespan.simpleTimespan  = $SimpleTimespan
        }  
    }
  $Timespan
}

function New-SevOneTrend {
param ()
$trend = $sevOne.factory_Trend()
$trend.type = 'none'
$trend
}

function Add-SevOneGraphtoReport {
param (
    [parameter(Mandatory)]
    $Report,
    [parameter(Mandatory)]
    $Graph,
    [parameter(Mandatory)]
    [string]$Name,
    [parameter()]
    $Timespan = (New-SevOneTimespan -SimpleTimespan 'past 8 hours'),
    [parameter()]
    $Trend = (New-SevOneTrend)
  )
process {
    $return = $SevOne.report_attachGraphToReport($report.id,$Name,$Graph,$timespan,$trend)

  }
}

function New-SevOneReport {
param (
    [parameter(Mandatory)]
    [string]$Name,

    [switch]$PassThrough
  )
process {
    $return = $SevOne.report_createReport($Name)
    if ($PassThrough) {
        $SevOne.report_getReportById($return)
      }
  }
}

#endregion Reports

function Out-SevOneDeferredData {
<#
  .SYNOPSIS
    Tool to load data into SevOne via the Deferred data api.

  .DESCRIPTION
    This function will take any object you provide and load it into The SevOne PAS Appliance you've previously connected to via the deferred data API. 
    Input objects must have a Typename if a PSObject and all objects must have a Name property.

  .EXAMPLE

  .EXAMPLE

  .NOTES
#>
[cmdletbinding()]
param (
  # Set the object to be added to the SevOne Instance
  [Parameter(Mandatory,
  ValueFromPipeline,
  ValueFromPipelineByPropertyName)]
  $InputObject,
  # Enter the target SevOne Device
  [Parameter(Mandatory)]
  $Device 
)
begin {
  Write-Verbose 'testing connection to SevOne Server'
  if (-not (__TestSevOneConnection__)) {
    throw 'Not connected to a SevOne instance'
  }
  Write-Verbose 'Testing that the Deferred data plugin is enabled on the device'
  if (! (Test-SevOnePlugin -Device $Device -Plugin DEFERRED).enabled) {
    Write-Debug "Enabling deferred data plugin on $($Device.deviceName)"
    Enable-SevOnePlugin -Device $Device -Plugin DEFERRED
  }
}
process {
  Write-Verbose 'Testing object type'
  if (! $InputObject.Name) {
    throw 'InputObject must have a Name property to be processed by Deferred Data'
  }
  $props = ($InputObject | Get-Member -MemberType Property | Where-Object {$_.definition -match 'int'}).Name 
  $objectTypes = Get-SevOneObjectType -Plugin DEFERRED
  $objects = Get-SevOneObject -Device $Device -Plugin DEFERRED
  
  switch ($InputObject.GetType().FullName)
  {
    System.Management.Automation.PSCustomObject {
      $name = $InputObject.psobject.TypeNames[0]
      if ($name -match 'System.Management.Automation.PSCustomObject') {
        throw 'Custom objects must have a valid typename to be inserted via the deferred data plugin.'
      }
    }
    default {
      $name = $InputObject.GetType().FullName
    }
  } 
  if ($name -in $objectTypes.name) { #Existing object Type
    #store Object Type
    $type = $objectTypes | Where-Object {$_.name -match $name}
    # Check for existing object
    $object = $objects | Where-Object {$_.name -match $InputObject.name}
    if (! $object) {
      #Create Object if required
      New-SevOneObject -Name $InputObject.name -ObjectType $type -Device $Device -Plugin DEFERRED
      $device | Start-SevOneDiscovery -Wait
      ############ Add somethign to start then wait for discovery to complete ##############

      $object = Get-SevOneObject -Device $Device -Plugin DEFERRED | Where-Object {$_.name -match $InputObject.name}
      if (! $object) {
        throw "unable to retrieve object for $($Device.Name)"
      }  
    }
    $Indicators = @()
    $Indicators += $SevOne.plugin_deferred_getIndicatorsByObject($device.id,$object.name)
    if ($indicators.count -eq 0) {
      Write-Warning 'no indicators present, wait for discovery to complete on new object then try again'
      continue
    }     
    # Test Indicators
    foreach ($p in $props) {
      if (! ($p -in $Indicators.indicatorType)) {
        # Print warning for unmatched indicator
        Write-Warning "Property $($p) is not on the object type $($type.name). It will be ignored during this run"
      }
    }
  }
  else {
    New-SevOneObjectType -Plugin DEFERRED -Name $name
    $type = Get-SevOneObjectType -Plugin DEFERRED | Where-Object {$_.name -match $name}
    #Create Indicators
    foreach ($p in $props) {
      Write-Verbose "about to create indicator $p on object type $($type.name)"
      $Null = $SevOne.plugin_deferred_createIndicatorType($type.id,$p)
      Write-Debug "finished created indicator $p"
    }
    $Indicators = $SevOne.plugin_deferred_getIndicatorsByObject($device.id,$object.name)
  }
  # Create Dictionary
  Write-Debug 'creating dictionary'
  $hash = @{}
  foreach ($i in $Indicators)
  {
    $value = $InputObject.$($i.indicatorType) # wrong vars
    if (! $value) {$value = 0}
    $hash.Add($i.id,$value)
  }
  $keys = $hash.keys
  $values = $Keys | ForEach-Object {$hash.$_}

  #Create Key Array $IndicatorID

  # Create matching value Array $value
  Write-Debug 'About to load data'
  $return = $SevOne.plugin_deferred_insertDataRow($Device.ID,$keys,$values)
  $return | __TestReturn__
}
}

function Get-SevOneIndicator {
<##>
[cmdletbinding(DefaultParameterSetName='device')]
param (
    # The Device that will be associated with Alarms pulled
    [parameter(Mandatory,
    Position=0,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='device')]
    [PSObject]$Device,

    # Set the plugin for pulling the objects
    [parameter(Mandatory,
    Position=1,
    ParameterSetName='device')]
    [parameter(
    Position=1,
    ValueFromPipelineByPropertyName,
    ParameterSetName='Object')]
    [ValidateSet(
      'COC',
      'CALLMANAGER',
      'CALLMANAGERCDR',
      'DEFERRED',
      'DNS',
      'HTTP',
      'ICMP',
      'IPSLA',
      'JMX',
      'MYSQLDB',
      'NBAR',
      'ORACLEDB',
      'PORTSHAKER',
      'PROCESS',
      'PROXYPING',
      'SNMP',
      'CALLD',
      'VMWARE',
      'WEBSTATUS',
      'WMI',
      'BULKDATA'
    )]
    [string]$Plugin,

    # The Device that will be associated with Alarms pulled
    [parameter(Mandatory,
    Position=0,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='Object')]
    [PSObject]$Object,

    [parameter(Mandatory,
    Position=0,
    ValueFromPipelineByPropertyName,
    ValueFromPipeline,
    ParameterSetName='objectType')]
    [PSObject]$ObjectType
  )
begin {
    if (-not (__TestSevOneConnection__)) {
        throw 'Not connected to a SevOne instance'
      }
    $i = 0
  }
process {
    $i ++
    Write-Verbose "Starting process block: $i"
    switch ($PSCmdlet.ParameterSetName)
      {
        'device' {
          Write-Verbose 'in device block'
          $method = "plugin_$plugin`_getIndicatorsByDeviceId"
          Write-Debug '$Method set, ready to draw indicators'
          $return = $SevOne.$method($Device.id)
        }
        'object' {
          $Plugin = $Object.pluginString
          Write-Verbose 'in Object Block'
          $method = "plugin_$plugin`_getIndicatorsByObject"
          Write-Debug '$Method set, ready to draw indicators'
          $return = $SevOne.$method($Object.deviceid,$Object.name)
        }
        'objectType' {
        
        }
      }
    $return
  }
}

function Remove-SevOneItem { # need to support removing Objects and ObjectTypes, Users and UserRoles
<#
  .SYNOPSIS
    Deletes a SevOne Item
  .DESCRIPTION
    This function will remove any SevOne item specified to the target parameter.  Works against all SevOne types.
  .EXAMPLE
    Get-SevOneDevice 'OldDevice' | Remove-SevOneItem

    Deletes the device named OldDevice
  .EXAMPLE
    Get-SevOneThreshold StaleThreshold | Remove-SevOneItem

    Deletes the Threshold named StaleThreshold
  .NOTES
    Deleted items are actually just marked for deletion by the API.  Items are removed later when the SevOne appliance goes through it's deletion process.
#>
[cmdletbinding(SupportsShouldProcess=$true,DefaultParameterSetName='default',ConfirmImpact='high')]
param (
    #
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName,
    ParameterSetName='default')]
    $Target
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
    Write-Verbose "Opening process block for $($Target.name)"
    if ($PSCmdlet.ShouldProcess("$($Target.name)","Remove SevOne Item"))
      {
        Write-Debug 'Passed confirm point, about to test object type'
        switch ($Target | __SevOneType__)
          {
            'deviceGroup' {
                $return = $SevOne.group_deleteDeviceGroup($Target.id)
                Write-Debug 'finished generating $return'
                if ($return -ne 1) {
                    Write-Debug 'in failure block'
                    Write-Error "failed to delete $($Target.name)"
                  }
                continue
              }
            'ObjectGroup' {
                $return = $SevOne.group_deleteObjectGroup($Target.id)
                Write-Debug 'finished generating $return'
                if ($return -ne 1) {
                    Write-Debug 'in failure block'
                    Write-Error "failed to delete $($Target.name)"
                  }
                continue
              }
            'deviceClass' {
                $return = $SevOne.group_deleteDeviceClass($target.id)
                if ($return -ne 1) {
                    Write-Error "failed to delete $($Target.name)"
                  }
                continue
              }
            'ObjectClass' {
                $return = $SevOne.group_deleteObjectClass($Target.id)
                Write-Debug 'finished generating $return'
                if ($return -ne 1) {
                    Write-Debug 'in failure block'
                    Write-Error "failed to delete $($Target.name)"
                  }
                continue
              }
            'device' {
                $return = $SevOne.core_deleteDevice($Target.id)
                Write-Debug 'finished generating $return'
                if ($return -ne 1) {
                    Write-Debug 'in failure block'
                    Write-Error "failed to delete $($Target.name)"
                  }
                continue
              }
            'object' {
                $Method = "plugin_$($Target.pluginString)_deleteObject"
                $return = $SevOne.$Method($Target.deviceId,$Target.id)
                Write-Debug 'finished generating $return'
                if ($return -ne 1) {
                    Write-Debug 'in failure block'
                    Write-Error "failed to delete $($Target.name)"
                  }
                continue
              }
            default {throw 'Deletion activities not defined'}
          }
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
            $return = $SevOne.threshold_getThresholdByName($Device.id,$Name)
            continue
          }
        'Device' {
            $return = $SevOne.threshold_getThresholdsByDevice($Device.id,$Pluggin.id,$Object.id,$Indicator.id)
            continue
          }
        'ID' {
            $return = $SevOne.threshold_getThresholdById($Device.id,$ID)
            continue
          }
      }
    $return | __ThresholdObject__
  }
}

function New-SevOneThreshold {}

function Set-SevOneThreshold {}

New-Alias -Name Balance-SevOneWMIProxy -Value Optimize-SevOneWMIProxy