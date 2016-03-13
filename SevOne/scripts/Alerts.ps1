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

