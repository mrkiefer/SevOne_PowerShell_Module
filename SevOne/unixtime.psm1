Function ConvertFrom-UNIXTime {
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

Function ConvertTo-UNIXTime {
Param
  (
    [Parameter(Mandatory=$true,
    Position=0,
    ValueFromPipeline=$true)]
    [datetime]$DateTime
  )
Process
  {
    [datetime]$origin = '1970-01-01 00:00:00'
    ($DateTime - $origin).totalseconds 
  }
}