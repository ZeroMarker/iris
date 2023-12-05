Class web.DHCOPAdmReg Extends %RegisteredObject
{
/// 三日内是否有非零元挂号费
/// create by ChHL
/// input: PatientId, CTLoc
/// output: flag
/// 			Y 三日内有非零元挂号费
/// w ##class(web.DHCOPAdmReg).GetRegFeeThreeDayFlag(575, 24)
ClassMethod GetRegFeeThreeDayFlag(PatientId, Dept)
{
	q:PatientId=""
	q:Dept=""
	s PatientId = +PatientId
	s RegfeeDepDr = Dept
	;s RegfeeDepDr = $o(^CTLOC(0,"Desc",Dept,RegfeeDepDr))
	s flag = "N"
	s RegfeeDate = ..%SysDate()
	s RegfeeTime = ..%SysTime()
	
	&sql(DECLARE mycursor CURSOR FOR
		select Regfeetemp1 into Regfeetemp1
		from SQLUser.DHCRegistrationFee
		where RegfeeAdmDr in (
			select PAADM_RowID
			from SQLUser.PA_Adm
			where PAADM_PAPMI_DR =:PatientId
				and PAADM_VisitStatus = "A"
		) 
		and RegfeeDepDr = :RegfeeDepDr
		and RegfeeDate + 3 >= :RegfeeDate  
		and RegfeeArcPrice > 0
	)
	&sql(OPEN mycursor)
	
	for {
		&sql(FETCH mycursor)
    	QUIT:SQLCODE'=0
    	;发票ID
    	;s status = $p(^PAADM(adm),"^",20)
    	if (Regfeetemp1 '= "") {
	    	s flag = "Y"
	    }
	}
	&sql(CLOSE mycursor)
	/*
	s EpisodeId = 0
	for {
		s EpisodeId = $o(^PAPERdr(PatientId,"ADM","O",EpisodeId))
		q:EpisodeId=""
		s status=$p(^PAADM(EpisodeId),"^",20)
		continue:status'="A"
		s dept=$p(^PAADM(EpisodeId),"^",4)
		continue:dept'=Dept
		s date=$p(^PAADM(EpisodeId),"^",6)
		continue:date+3>RegfeeDate
		;s regCon=$p(^PAADM(EpisodeId,"DHC"),"^",25)
		s regfeeId = ^User.DHCRegistrationFeeI("ADM",EpisodeId)
		s temp1 = $lg(^User.DHCRegistrationFeeI,11)	;发票
		continue:temp1=""
		s price = $lg(^User.DHCRegistrationFeeI,4)
		s:price>0 flag="Y"
	}
	*/
	q flag
}
}