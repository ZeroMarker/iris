w ##class(appcom.OEOrdExec).DiscontinueExec("531546||1",590)
if (StopAllExecFlag'=1)&&
	((XDate=ExeDate)&&(XTime>=ExeTime)&&(XTime'=0)) {
	//XTime如果是0，则认为当天所有的执行记录都需要停止，包括要求执行时间为0的；等同于||((XDate>ExeDate)&&(XTime=0))
	Continue	;CurrDate换XDate
}
if XDate=ExeDate,XTime>ExeTime,StopAllExecFlag'=1 Continue	;CurrDate换XDate