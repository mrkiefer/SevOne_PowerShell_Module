enum plugins {
  COC
  CALLMANAGER
  CALLMANAGERCDR
  DEFERRED
  DNS
  HTTP
  ICMP
  IPSLA
  JMX
  MYSQLDB
  NBAR
  ORACLEDB
  PORTSHAKER
  PROCESS
  PROXYPING
  SNMP
  CALLD
  VMWARE
  WEBSTATUS
  WMI
  BULKDATA
}

class SevOne { 

}

class device : SevOne {
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
  device () {}

  device (
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

class object : SevOne {
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
  object ( ) { }

  object ($obj) {
    $this.id = $obj.id
    $this.deviceID = $obj.deviceId
    $this.pluginString = $obj.pluginString
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

class plugin : SevOne {
  #Properties
  [string]$name
  [int]$id
  [string]$type

  #Constructors
  plugin ( ) { }

  plugin ($raw) {
    $this.name = $raw.name
    $this.id = $raw.id
    $this.type = $raw.objectString
  }

}

class threshold : SevOne {
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
  threshold ( ) { }

  threshold ($raw) {
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

class alert : SevOne {
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
  alert ( ) { }

  alert ($raw) {
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

class objectClass : SevOne {
  #Properties
  [string]$name
  [int]$id 

  #Constructors
  objectClass () {}

  objectClass ($raw) {
    $this.name = $raw.name
    $this.id = $raw.id
  }

}

class deviceGroup : SevOne {
  #Properties
  [int]$id
  [int]$parentid
  [string]$name

  #Constructors
  deviceGroup () {}

  deviceGroup ($raw) {
    $this.id = $raw.id
    $this.parentid = $raw.parentid
    $this.name = $raw.name
  }
}

class objectGroup : SevOne {
  #Properties
  [int]$id
  [int]$parentid
  [string]$name

  #Constructors
  objectGroup () {}

  objectGroup ($raw) {
    $this.id = $raw.id
    $this.parentid = $raw.parentid
    $this.name = $raw.name
  }
}

class peer : SevOne {
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
  peer () {}
  
  peer ($raw) {
    $this.serverId = $_.serverId 
    $this.name = $_.name 
    $this.ip = $_.ip
    $this.is64bit = [int]($_.is64bit) -as [bool]
    $this.memory = $_.memory
    $this.isMaster = $_.isMaster 
    $this.username = $_.username 
    $this.password = $_.password 
    $this.capacity = $_.capacity
    $this.serverLoad = $_.serverLoad
    $this.flowLoad = $_.flowLoad 
    $this.model = $_.model
  }

}

class user : SevOne {
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
  user () {}

  user ($raw) {
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

  # Methods

}

class userRole : SevOne {
  #Properties
  [int]$id
  [int]$parentid
  [string]$name

  #Constructors
  userRole () {}

  userRole ($raw) {
    $this.id = $raw.id
    $this.parentid = $raw.parentid
    $this.name = $raw.name
  }

}

class objectType : SevOne {
  #Properties
  [int]$id
  [int]$parentid
  [string]$name
  [int[]]$deviceTypeIds

  #Constructors
  objectType () {}

  objectType ($raw) {
    $this.id = $raw.id
    $this.parentid = $raw.parentid
    $this.name = $raw.name
    $this.deviceTypeIds = $raw.deviceTypeIds
  }

}

class wmiProxy : SevOne {
  #Properties
  [int]$id
  [string]$ip
  [string]$name
  [int]$port

  #Constructors
  wmiProxy () {}

  wmiProxy ($raw) {
    $this.id = $raw.id
    $this.ip = $raw.ip
    $this.name = $raw.name
    $this.port = $raw.port
  }

}

class indicator : SevOne {
  #Properties
  [int]$id
  [string]$indicatorType
  [string]$objectName
  [int]$deviceId
  [int]$indicatorTypeId
  [int]$maxValue
  [int]$systemMaxValue
  [int]$overrideMaxValue
  [string]$datatableColumn

  #Constructors
  indicator () {}

  indicator ($raw) {
    $this.id = $raw.id
    $this.objectName = $raw.objectName
    $this.deviceId = $raw.deviceId
    $this.indicatorType = $raw.indicatorType
    $this.indicatorTypeId = $raw.indicatorTypeId
    $this.maxValue = $raw.maxValue
    $this.systemMaxValue = $raw.systemMaxValue
    $this.overrideMaxValue = $raw.overrideMaxValue
    $this.datatableColumn = $raw.datatableColumn
  }

}



#Classes remaining:
# Report
# Graph


