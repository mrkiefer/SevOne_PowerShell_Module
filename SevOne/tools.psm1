function __TestReturn__ {
param (
    #
    [parameter(Mandatory,
    ParameterSetName='Default',
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    $return      
    )
switch ($return)
    {
    0 { throw 'Failed operation'}
    1 {Write-Verbose 'Successfully completed set operation'}
    default {throw "Unexpected return code: $return"}
    }
}

############ Probably delete all these
filter __Object__ {
$obj = [pscustomobject]@{
      id = $_.id
      deviceID = $_.deviceId
      plugin = $_.pluginString
      name = $_.name
      system_description = $_.system_description
      description = $_.description
      objectType = $_.objectType
      subtype = $_.subtype
      enabledStatus = $_.enabledStatus 
      hiddenStatus = $_.hiddenStatus
      recordDate = $_.recordDate
      lastSeen = $_.lastSeen
      deletedStatus = $_.deletedStatus
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Object.Object')
  $obj
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

function __SevOneType__ {
<#
This is a point of concern, we need to get real object classes in the near future
#>
[cmdletbinding()]
param(
    [parameter(Mandatory,
    ValueFromPipeline,
    ValueFromPipelineByPropertyName)]
    [ValidateNotNullorEmpty()]
    [psobject]$InputObject
  )
process {
    Write-Verbose "`$InputObject contains $(($InputObject | measure ).count) items"
    Write-Debug 'Begin typename test'
    switch ($InputObject.psobject.TypeNames[0])
      {
        'SevOne.Device.DeviceInfo' {'device';continue}
        'SevOne.Threshold.ThresholdInfo' {'threshold';continue}
        'SevOne.Class.DeviceClass' {'DeviceClass';continue}
        'SevOne.Class.ObjectClass' {'ObjectClass';continue}
        'SevOne.Group.DeviceGroup' {'DeviceGroup';continue}
        'SevOne.Group.ObjectGroup' {'ObjectGroup';continue}
        'SevOne.Object.ObjectType' {'Object';continue}
        'SevOne.Peer.PeerObject' {'Peer';continue}
        default {throw 'No type defined'} 
      }
  }
}

filter __PluginObject__ {
    $obj = [pscustomobject]@{
      Name = $_.name
      Id = [int]($_.id)
      Type = $_.objectString
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Plugin.PluginClass')
  $obj
  }
 
filter __ThresholdObject__ {
  $obj = [pscustomobject]@{
      id = [int]($_.id  )
      name = $_.name
      description = $_.description 
      deviceId = [int]($_.deviceId)
      policyId = [int]($_.policyId)
      severity = $_.severity
      groupId  = [int]($_.groupId)
      isDeviceGroup = $_.isDeviceGroup
      triggerExpression = $_.triggerExpression
      clearExpression = $_.clearExpression
      userEnabled = [int]($_.userEnabled) -as [bool]
      policyEnabled = [int]($_.policyEnabled) -as [bool]
      timeEnabled = [int]($_.timeEnabled) -as [bool]
      mailTo = $_.mailTo 
      mailOnce = $_.mailOnce 
      mailPeriod = $_.mailPeriod 
      lastUpdated = $_.lastUpdated -as [datetime] 
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
      id = [int]($_.id)
      severity = $_.severity
      isCleared = [int]($_.isCleared) -as [bool]
      origin = $_.origin 
      deviceId = [int]($_.deviceId)
      pluginName = $_. pluginName
      objectId = [int]($_.objectId) 
      pollId = [int]($_.pollId)
      thresholdId = [int]($_.thresholdId)
      startTime = $_.Starttime | __fromUNIXTime__
      endTime = $_.endTime | __fromUNIXTime__
      message = $_.message 
      assignedTo = $_.assignedTo
      comments = $_.comments
      clearMessage = $_.clearMessage 
      acknowledgedBy = $_.acknowledgedBy
      number = $_.number
      automaticallyProcessed = [int]($_.automaticallyProcessed) -as [bool]
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Alert.AlertInfo')
  $obj
}

filter __ObjectClass__ {
  $obj = [pscustomobject]@{
      Name = $_.name
      Id = [int]($_.id)
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Class.ObjectClass')
  $obj
}

filter __DeviceGroupObject__ {
  $base = $_ 
  $obj = [pscustomobject]@{
      ID = [int]($base.id)
      ParentGroupID = [int]($base.parentid)
      Name = $base.name
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Group.DeviceGroup')
  $obj
}

filter __ObjectGroupObject__ {
  $base = $_ 
  $obj = [pscustomobject]@{
      ID = [int]($base.id)
      ParentGroupID = [int]($base.parentid)
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
      is64bit = [int]($_.is64bit) -as [bool]
      memory = $_.memory
      isMaster = $_.isMaster 
      username = $_.username 
      password = $_.password 
      capacity = $_.capacity
      serverLoad = $_.serverLoad
      flowLoad = $_.flowLoad 
      model = $_.model
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Peer.PeerObject')
  $obj
}

filter __userRole__ {
$obj = [pscustomobject]@{
    id = $_.id
    name = $_.name 
  }
$obj.PSObject.TypeNames.Insert(0,'SevOne.User.userRole')
$obj
}

filter __user__ {
$obj = [pscustomobject]@{
    id = $_.id
    userName = $_.username
    email = $_.email
  }
$obj.PSObject.TypeNames.Insert(0,'SevOne.User.user')
$obj
}

filter __ObjectType__ {
$obj = [pscustomobject]@{
      id = $_.id
      deviceId = $_.deviceId
      pluginString = $_.pluginString
      name = $_.name 
      system_description = $_.system_description
      description = $_.description
      objectType = $_.objectType
      subtype = $_.subtype
      enabledStatus = $_.enabledStatus
      hiddenStatus = $_.hiddenStatus
      recordDate = $_.recordDate
      lastSeen = $_.lastSeen
      deletedStatus = $_.deletedStatus
    }
  $obj.PSObject.TypeNames.Insert(0,'SevOne.Object.ObjectType')
  $obj
}
