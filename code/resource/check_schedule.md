```objectscript
ClassMethod CheckSchedule(ResRowID As %String, ScheduleDate As %String, RoomID As %String, SessionStartTime As %String, RBASRowId As %String = "") As %String
{
	s ^zhou("CheckSchedule")=ResRowID_","_ScheduleDate_","_RoomID_","_SessionStartTime_","_RBASRowId
	;w ##class(web.DHCRBResourceRule).CheckSchedule(559,61986,"",46800,"")
	//同一个资源在同一天同一诊不能同时在两个诊室
	set count=0,TRRowId=""
	;如果是全天和上下午这种有重叠时段诊区排诊这样单纯的判断一个，或者取排班数据就是错误的.
	;SessionStartTime如果传入的是一个时段的开始时间点，恰好是另一个时段的结束时间点那么通过时间点取值就会错误。所以+1确保是在时段时间内。
	if RBASRowId'="" d
	.s TRRowId=$p($g(^RBAS($p(RBASRowId,"||",1),$p(RBASRowId,"||",2),"DHC")),"^",17)
	.s TRRowId=##class(web.DHCRBApptSchedule).GetTimeRangeStrByRange(TRRowId)
	else   d
	.s TRRowId=0  f  s TRRowId=$O(^DHCTimeRange(TRRowId)) Q:(TRRowId="")  d
	..s StartTime=$P(^DHCTimeRange(TRRowId),"^",3)
	..s EndTime=$P(^DHCTimeRange(TRRowId),"^",4)
	..s UseStDate=$P(^DHCTimeRange(TRRowId),"^",7)
	..Q:(UseStDate>+$H)&&(UseStDate'="")
	..s UseEndDate=$P(^DHCTimeRange(TRRowId),"^",8)
	..Q:(UseEndDate<+$H)&&(UseEndDate'="")
	..if StartTime=SessionStartTime  d
	...s Sub=(EndTime-StartTime)
	...s TempTimRang(Sub)=TRRowId
	.i $d(TempTimRang) d
	..s TRRowIdSub=$O(TempTimRang(0))
	..s TRRowId=$G(TempTimRang(TRRowIdSub))
	..s TRRowId=##class(web.DHCRBApptSchedule).GetTimeRangeStrByRange(TRRowId)
	
	.;s TRRowIdSub=$O(TempTimRang(0))
	.;s TRRowId=$G(TempTimRang(TRRowIdSub))
	.;s TRRowId=##class(web.DHCRBApptSchedule).GetTimeRangeStrByRange(TRRowId)
	if TRRowId=""  d
	.s TRRowId=##class(web.DHCRBResSession).GetTimeRangeByTime(SessionStartTime)
	.s TRRowId=##class(web.DHCRBApptSchedule).GetTimeRangeStrByRange(TRRowId)

	s DulASRowId=""
	s DocDr=$p(^RB("RES",ResRowID),"^",2)
	Set LocDr=0 f  Set LocDr=$O(^RB("RES",0,"CTPCP",DocDr,LocDr)) Quit:LocDr=""  d
	.Set RowId=0 f  Set RowId=$O(^RB("RES",0,"CTPCP",DocDr,LocDr,RowId)) Quit:RowId=""  d
	..s SessTime=0  f  s SessTime=$O(^RBAS(RowId,0,"DateSTime",ScheduleDate,SessTime)) Q:SessTime=""  d
	...;s SessTRRowId=##Class(web.DHCRBResSession).GetTimeRangeByTime(SessTime)
	...;
	...s Child=0  f  s Child=$Order(^RBAS(RowId,0,"DateSTime",ScheduleDate,SessTime,Child)) Q:(Child="")  d
	....Q:(RBASRowId'="")&&(RBASRowId=(ResRowID_"||"_Child))
	....s SessTRRowId=$P($G(^RBAS(RowId,Child,"DHC")),"^",17)
	....Q:("!"_TRRowId_"!")'[("!"_SessTRRowId_"!") //&&("!"_SessTRRowId_"!")'[("!"_TRRowId_"!")
	....s status=$P($G(^RBAS(RowId,Child,"DHC")),"^",10)
	....i status'="" s status=$P(^DHCRBCASStatus(status),"^",1)
	....;过滤停诊和替诊
	....Q:(status="S")!(status="TR")
	....s count=count+1
	....;b
	....s DulASRowId=RowId_"||"_Child
	if (count>0) quit "-201"_"^"_DulASRowId
	
	//同一个诊室在同一天同一诊不能同时被安排两次
	s find=0
	s ResRowId=0  f  s ResRowId=$O(^RB("RES",ResRowId)) Q:(ResRowId="")||(find=1)  d
	.s SessTime=0  f  s SessTime=$Order(^RBAS(ResRowId,0,"DateSTime",ScheduleDate,SessTime)) Q:(SessTime="")||(find=1)  d
	..;s SessTRRowId=##Class(web.DHCRBResSession).GetTimeRangeByTime(SessTime)
	..;Q:TRRowId'=SessTRRowId
	..s Child=0  f  s Child=$Order(^RBAS(ResRowId,0,"DateSTime",ScheduleDate,SessTime,Child)) Q:(Child="")||(find=1)  d
	...s RoomDr=$P($G(^RBAS(ResRowId,Child,"DHC")),"^",5)
	...s SessTRRowId=$P($G(^RBAS(ResRowId,Child,"DHC")),"^",17)
	...Q:("!"_TRRowId_"!")'[("!"_SessTRRowId_"!")
	...Q:(RBASRowId'="")&&(RBASRowId=(ResRowID_"||"_Child))
	...s status=$P($G(^RBAS(ResRowId,Child,"DHC")),"^",10)
	...i status'="" s status=$P(^DHCRBCASStatus(status),"^",1)
	...;过滤停诊和替诊
	...Q:(status="S")!(status="TR")
	...Q:RoomDr=""    ;排班不录诊室
	...i RoomDr=RoomID d
	....s find=1
	....s DulASRowId=ResRowId_"||"_Child
	...Q:find=1
	i find=1 Quit "-202"_"^"_DulASRowId

	quit 0
}

同一医生不同科室出诊
w ##class(web.DHCRBApptSchedule).CreateResOneDaySchedule("2||1||1",61100,1)
InsertOneSchedule()
set ret=##class(web.DHCRBResourceRule).CheckSchedule(ResRowID,ScheduleDate,RoomID, SessStartTime,"")
.s TRRowId=##class(web.DHCRBApptSchedule).GetTimeRangeStrByTime(SessionStartTime)
/*.s TRRowId=0  f  s TRRowId=$O(^DHCTimeRange(TRRowId)) Q:(TRRowId="")  d
..s StartTime=$P(^DHCTimeRange(TRRowId),"^",3)
..s EndTime=$P(^DHCTimeRange(TRRowId),"^",4)
..s UseStDate=$P(^DHCTimeRange(TRRowId),"^",7)
..Q:(UseStDate>+$H)&&(UseStDate'="")
..s UseEndDate=$P(^DHCTimeRange(TRRowId),"^",8)
..Q:(UseEndDate<+$H)&&(UseEndDate'="")
..if StartTime=SessionStartTime  d
...s Sub=(EndTime-StartTime)
...s TempTimRang(Sub)=TRRowId
.i $d(TempTimRang) d
..s TRRowIdSub=$O(TempTimRang(0))
..s TRRowId=$G(TempTimRang(TRRowIdSub))
..s TRRowId=##class(web.DHCRBApptSchedule).GetTimeRangeStrByRange(TRRowId)*/

RoomID = ""
OPAdm/ScheduleAdjust.hui.js
DHCRBRes.Session.bak.js
var InsertData=""+"^"+SessDOW+"^"+SessTimeStart+"^"+SessTimeEnd+"^"+SessSlotLength+"^"+SessLoad+"^"+SessNoSlots+"^"+SessNoApptSlot;
InsertData=InsertData+"^"+SessNumberOfWeeks+"^"+SessNoOverbookAll+"^"+SessRoom+"^"+SessType+"^"+SessClinicGroup+"^"+SessPatientType+"^"+SessNo+"^"+SessScheduleGenerFlag;
InsertData=InsertData+"^"+TRFlag+"^"+TRStartTime+"^"+TREndTime+"^"+TRLength+"^"+TRRegNum+"^"+TRRegNumStr+"^"+TRRegInfoStr
var encmeth=DHCC_GetElementData('InsertMethod');
var ret=cspRunServerMethod(encmeth,ResDateRowid,InsertData);
```