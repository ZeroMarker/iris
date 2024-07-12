```objectscript
d ##class(web.DHCDocMain).CancelRegAll(ScheduleID)
	;所有分诊护士 普通通知
	set schedule=##class(User.RBApptSchedule).%OpenId(ScheduleID)
	s doc = ##class(web.DHCDocMain).Comm("value","RB",17,"RES",+ScheduleID)
	s TimeRange = ##class(web.DHCDocMain).Comm("value","RBAS",17,+ScheduleID,$p(ScheduleID,"||",2),"DHC")
	s TRDesc = ##class(web.DHCDocMain).Comm("value","DHCTimeRange",2,TimeRange)
	s msg = doc_"("_TRDesc_")"_"已停诊"
	s users = ##class(web.DHCDocMain).GetAllocUser()
	s ^test4rb = $lb(msg,2000,AuditUserID,"","",users)
	d ##class(websys.DHCMessageInterface).Send(msg,2000,AuditUserID,"","",users)
/// debug: w ##class(web.DHCDocMain).CancelRegAll("493||29")
ClassMethod CancelRegAll(rbas)
{
	q:rbas="" ""
	s ^test4cancel = $lb(rbas)
	s UserId = 18973
	s GroupId = 238
	s Loc = 167
	s ReturnMR = "N"
	s ReturnReason = 54
	s RegFee = 0
	for {
		s RegFee = ##class(web.DHCDocMain).Comm("order","User.DHCRegistrationFeeI",1,"RBASDr"," "_rbas,RegFee)
		q:RegFee=""
		s rtn = ##class(web.DHCOPAdmReg).CancelOPRegist(RegFee,UserId,GroupId,Loc,"","N",ReturnReason,"","")
	}
	q 0
}
```

