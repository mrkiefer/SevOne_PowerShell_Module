class SevOne { 

}

class Device : SevOne {
  #Properties
  [int]$id
  [string]$name
  [string]$alternateName
  [string]$description
  [string]$ipAddress
  [bool]$snmpCapable
  [int]$snmpVersion
  [string]$snmpRoCommunity
  [string]$snmpRwCommunity
  [int]$snmpPort
  [string]$synchronizeInterfaces
  [string]$synchronizeObjectsAdminStatus
  [string]$synchronizeObjectsOperStatus
  [int]$peerId
  [int]$pollFrequency
  [int]$elementCount
  [int]$discoverStatus
  [string]$discoverPriority
  [bool]$brokenStatus
  [bool]$isNew
  [bool]$isDeleted
  [bool]$allowAutomaticDiscovery
  [bool]$allowManualDiscovery
  [int]$osId
  [datetime]$lastDiscovery
  [string]$snmpStatus
  [string]$icmpStatus
  [bool]$disableDiscovery
  [bool]$disableThresholding
  [bool]$disablePolling
  [string]$timezone

  #Constructors
  Device (
      $base
    )
  {
    $this.id = $base.id
    $this.name = $base.name
    $this.alternateName = $base.alternateName
    $this.description = $base.description
    $this.ipAddress = $base.ip
    $this.snmpCapable = [int]($base.snmpCapable) -as [bool]
    $this.snmpPort = [int]($base.snmpPort)
    $this.snmpVersion = [int]($base.snmpVersion)
    $this.snmpRoCommunity = $base.snmpRoCommunity
    $this.snmpRwCommunity = $base.snmpRwCommunity
    $this.synchronizeInterfaces = $base.synchronizeInterfaces
    $this.synchronizeObjectsAdminStatus = $base.synchronizeObjectsAdminStatus
    $this.synchronizeObjectsOperStatus = $base.synchronizeObjectsOperStatus
    $this.peerID = $base.peer
    $this.pollFrequency = [int]($base.pollFrequency)
    $this.elementCount = [int]($base.elementCount)
    $this.discoverStatus = [int]($base.discoverStatus)
    $this.discoverPriority = $base.discoverPriority
    $this.brokenStatus = [int]($base.brokenStatus) -as [bool]
    $this.isNew = [int]($base.isNew) -as [bool]
    $this.isDeleted = [int]($base.isDeleted) -as [bool]
    $this.allowAutomaticDiscovery = [int]($base.allowAutomaticDiscovery) -as [bool]
    $this.allowManualDiscovery = [int]($base.allowManualDiscovery) -as [bool]
    $this.osId = $base.osId
    $this.lastDiscovery = $base.lastDiscovery -as [datetime]
    $this.snmpStatus = $base.snmpStatus
    $this.icmpStatus = $base.icmpStatus
    $this.disableDiscovery = [int]($base.disableDiscovery) -as [bool]
    $this.disableThresholding = [int]($base.disableThresholding) -as [bool]
    $this.disablePolling = [int]($base.disablePolling) -as [bool]
    $this.timezone = $Base.timezone
  }
  
  #Methods
}

class Object : SevOne {
  #Properties
  [int]$id
  [int]$deviceId
  [string]$pluginString
  [string]$name
  [string]$system_description
  [string]$description
  [int]$objectType
  [int]$subtype
  [int]$enabledStatus
  [int]$hiddenStatus
  [datetime]$recordDate
  [datetime]$lastSeen
  [bool]$deletedStatus

  #Constructors
  Object ( ) { }

  Object ($obj) {
    $this.id = $obj.id
    $this.deviceID = $obj.deviceId
    $this.plugin = $obj.pluginString
    $this.name = $obj.name
    $this.system_description = $obj.system_description
    $this.description = $obj.description
    $this.objectType = $obj.objectType
    $this.subtype = $obj.subtype
    $this.enabledStatus = $obj.enabledStatus 
    $this.hiddenStatus = $obj.hiddenStatus
    $this.recordDate = $obj.recordDate
    $this.lastSeen = (convertfrom-Unixtime $obj.lastSeen)
    $this.deletedStatus = $obj.deletedStatus
  }

}

class Plugin : SevOne {
  #Properties
  [string]$name
  [int]$id
  [string]$type

  #Constructors
  Plugin ( ) { }

  Plugin ($raw) {
    $this.name = $raw.name
    $this.id = $raw.id
    $this.type = $raw.objectString
  }

}

class Threshold : SevOne {
  #Properties
  [int]$id
  [string]$name
  [string]$description
  [int]$deviceId
  [int]$policyId
  [int]$severity
  [int]$groupId
  [int]$isDeviceGroup
  [string]$triggerExpression
  [string]$clearExpression
  [bool]$userEnabled
  [bool]$policyEnabled
  [bool]$timeEnabled
  [string]$mailTo
  [bool]$mailOnce
  [int]$mailPeriod
  [datetime]$lastUpdated
  [bool]$useDefaultTraps
  [bool]$useDeviceTraps
  [bool]$useCustomTraps
  [string]$triggerMessage
  [string]$clearMessage
  [int]$appendConditionMessages

  #Constructors
  Threshold ( ) { }

  Threshold ($raw) {
    $this.id = $raw.id
    $this.name = $raw.name
    $this.description = $raw.description 
    $this.deviceId = $raw.deviceId
    $this.policyId = $raw.policyId
    $this.severity = $raw.severity
    $this.groupId  = $raw.groupId
    $this.isDeviceGroup = $raw.isDeviceGroup
    $this.triggerExpression = $raw.triggerExpression
    $this.clearExpression = $raw.clearExpression
    $this.userEnabled = $raw.userEnabled
    $this.policyEnabled = $raw.policyEnabled
    $this.timeEnabled = $raw.timeEnabled
    $this.mailTo = $raw.mailTo 
    $this.mailOnce = $raw.mailOnce 
    $this.mailPeriod = $raw.mailPeriod 
    $this.lastUpdated = (convertfrom-Unixtime $raw.lastUpdated)
    $this.useDefaultTraps = $raw.useDefaultTraps
    $this.useDeviceTraps = $raw.useDeviceTraps
    $this.useCustomTraps = $raw.useCustomTraps
    $this.triggerMessage = $raw.triggerMessage
    $this.clearMessage = $raw.clearMessage
    $this.appendConditionMessages = $raw.appendConditionMessages
  }

}

class Alert : SevOne {
  #Properties
  [int]$id
  [int]$severity
  [bool]$isCleared
  [string]$origin
  [int]$deviceId
  [string]$pluginName
  [int]$objectId
  [int]$pollId
  [int]$thresholdId
  [datetime]$startTime
  [datetime]$endTime
  [string]$message
  [string]$assignedTo
  [string]$comments
  [string]$clearMessage
  [string]$acknowledgedBy
  [int]$number
  [bool]$automaticallyProcessed

  #Constructors
  Alert ( ) { }

  Alert ($raw) {
    $this.id = $raw.id
    $this.severity = $raw.severity
    $this.isCleared = $raw.isCleared
    $this.origin = $raw.origin 
    $this.deviceId = $raw.deviceId
    $this.pluginName = $raw.pluginName
    $this.objectId = $raw.objectId
    $this.pollId = $raw.pollId
    $this.thresholdId = $raw.thresholdId
    $this.startTime = (convertfrom-Unixtime $raw.Starttime)
    $this.endTime = (convertfrom-Unixtime $raw.endTime)
    $this.message = $raw.message 
    $this.assignedTo = $raw.assignedTo
    $this.comments = $raw.comments
    $this.clearMessage = $raw.clearMessage 
    $this.acknowledgedBy = $raw.acknowledgedBy
    $this.number = $raw.number
    $this.automaticallyProcessed = $raw.automaticallyProcessed
  }

}

class ObjectClass : SevOne {
  #Properties
  [string]$name
  [int]$id 

  #Constructors
  ObjectClass () {}

  ObjectClass ($raw) {
    $this.name = $raw.name
    $this.id = $raw.id
  }

}

class DeviceGroup : SevOne {
  #Properties
  [int]$id
  [int]$parentid
  [string]$name

  #Constructors
  DeviceGroup () {}

  DeviceGroup ($raw) {
    $this.id = $raw.id
    $this.parentid = $raw.parentid
    $this.name = $raw.name
  }
}

class ObjectGroup : SevOne {
  #Properties
  [int]$id
  [int]$parentid
  [string]$name

  #Constructors
  ObjectGroup () {}

  ObjectGroup ($raw) {
    $this.id = $raw.id
    $this.parentid = $raw.parentid
    $this.name = $raw.name
  }
}

class Peer : SevOne {
  #Properties
  [int]$serverId
  [string]$name
  [string]$ip
  [bool]$is64bit
  [int]$memory
  [bool]$isMaster 
  [string]$username 
  [string]$password 
  [int]$capacity
  [int]$serverLoad
  [int]$flowLoad 
  [string]$model

  #Constructors
  Peer () {}
  Peer ($raw) {
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

}

class User : SevOne {
  #Properties
  [int]$id
  [string]$username
  [string]$email
  [string]$firstName
  [string]$lastName
  [string]$authentication
  [bool]$forcePasswordChange
  [bool]$passwordNeverExpires
  [int]$timeout
  [int]$timeoutType
  [bool]$active
  [int]$dashboardReportId
  [string]$disableReason
  [int]$tzCheck
  [string]$timezone
  [int]$isSynced

  #Constructors
  User () {}

  User ($raw) {
    $this.id = $raw.id
    $this.username = $raw.username
    $this.email = $raw.email
    $this.firstName = $raw.firstName
    $this.lastName = $raw.lastName
    $this.authentication = $raw.authentication
    $this.forcePasswordChange = $raw.forcePasswordChange
    $this.passwordNeverExpires = $raw.passwordNeverExpires
    $this.timeout = $raw.timeout
    $this.timeoutType = $raw.timeoutType
    $this.active = $raw.active
    $this.dashboardReportId = $raw.dashboardReportId
    $this.disableReason = $raw.disableReason
    $this.tzCheck = $raw.tzCheck
    $this.timezone = $raw.timezone
    $this.isSynced = $raw.isSynced
  }
}

#Classes remaining:
# ObjectType
# WMIProxy
# Indicator
# Report
# Graph