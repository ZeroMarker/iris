s find = $listfind($lb(28,104,149,242),GroupID)

28	门诊医师
104	急诊医师
149	门诊医师(主任)
242	急诊医师(主任)



s QueId=%ROWID
s ^test4reg($zdt($h,3)) = $lb($g(RegfeeAPPRangeTime),$g(StartTime),$g(TimeRangeStr),$g(TRRegSTTime),$g(TRRegEndTime),$g(RegfeeTimeRangeDr))
	s:($g(StartTime)="")&&(RegfeeTimeRangeDr'="") StartTime = $p($g(^DHCTimeRange(RegfeeTimeRangeDr)),"^",3)
	s StartTime = ..%ZTH($g(StartTime))
	if (StartTime - ..%SysTime() <= 7200) {
		;s result = ##class(web.DHCAlloc).PatArrive("","",QueId,"",238)
		;s ^test4que($zdt($h,3)) = $lb(StartTime,QueId,rtn)
	}

    &javascript<#(retval)#>


