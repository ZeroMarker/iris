Class DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods Extends %Library.RegisteredObject [ ClassType = "", ProcedureBlock ]
{

// w ##class(DHCDoc.Interface.Outside.TAZXYY.DHCDocVISService.MainMethods).SendDocInfo("13923","146","172.101.39.11","1")

/// /"13923","146","172.101.39.11","1"
ClassMethod SendDocInfo(UserID As %String, LocID As %String, IPAddress As %String, LoginFlag As %String) As %String
{
	s $ZTrap = "SendDocInfoET"
	s ^temp("SendDocInfo")=$lb(UserID, LocID, IPAddress , LoginFlag)
	s BorDr="",RoomDr="",BorName="",BorCode=""
	&sql(SELECT RoomcRoomDr into :RoomDr From SQLUser.DHCRoomComp where RoomcIp=:IPAddress)
	s QueRoomDr=RoomDr
	&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)
	//q:BorDr="" "诊室诊区未作对照,请联系信息科"
	if (BorDr'=""){
		s BorName=$List(^User.DHCExaBoroughD(BorDr),5)
		s BorCode=$List(^User.DHCExaBoroughD(BorDr),2)
	}
	s CTLocName=$P(^CTLOC(LocID),"^",2)
	s CTLocCode=$P(^CTLOC(LocID),"^",1)
	s SSUSRCTPCPDR=$p(^SSU("SSUSR",UserID),"^",14)
	s DoctorName=$P(^CTPCP(SSUSRCTPCPDR,1),"^",2)
	s DoctorCode=$P(^CTPCP(SSUSRCTPCPDR,1),"^",1)
	s CTPCPCarPrvTpDR=$p(^CTPCP(SSUSRCTPCPDR,1),"^",4)
	s ASSessionTypeDesc=""
	s:CTPCPCarPrvTpDR'="" ASSessionTypeDesc=$p(^CT("CPT",CTPCPCarPrvTpDR),"^",2)
	s BorDesc=""
	s ID=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
	if (ID'=""){
		s BorDesc=$p(^DHCVISClient(ID),"^",3)
	}
	s doctorcode=DoctorCode
	s doctorname=DoctorName   ///医生
	s id=+$h_$p($h,",",2)_ID
		
	s CallInfo=id_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_CTLocCode_"^"_CTLocName_"^"_""_"^"_BorDesc_"^"_doctorcode_"^"_doctorname_"^"_""_"^"_""_"^"_""_"^^"_ASSessionTypeDesc_"^"_""_"#"_""

	s Flag=##class(web.DHCENS.BLL.Call.Method.CallInfo).SendAdmCallInfo(CallInfo,LoginFlag)
	if (Flag'="Call Success"){
		q Flag
	}
	
	q 0
	
SendDocInfoET
     q "-1^叫号异常:"_$ze
}

/// /desc:推送叫号患者信息
/// w ##class(DHCDoc.Interface.Outside.SYDEFY.DHCDocVISService.MainMethods).SendAdmCallInfo("","186","20342","192.168.62.220","",3,"")
ClassMethod SendAdmCallInfo(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", IPAddress As %String = "", WaitEpisodeID As %String = "", LoginFlag As %String = "", GHList As %String = "") As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	s ^Temp("SendAdmCallInfo")=$lb(EpisodeID, LocID, UserID, IPAddress, WaitEpisodeID,LoginFlag,GHList,$h)
	i IPAddress="172.16.92.166" s ^DHCDocVisLog("SendAdmCallInfo1")=$lb(EpisodeID, LocID, UserID, IPAddress, WaitEpisodeID,LoginFlag,GHList,$h)
	;s IPAddress="192.168.10.90"
	;s IPAddress="192.168.62.126"
	q:IPAddress="" "-1^IP不可为空"
	q:'$d(^DHCVISClienti(0,"ClientIP",IPAddress)) "-1^IP: "_IPAddress_"未配置"
	if (EpisodeID'=""){
		s RegistDr=$o(^User.DHCRegistrationFeeI("ADM",EpisodeID,""),-1)
		s ^tempchen("SendAdmCall")= EpisodeID
		q:RegistDr="" "-1^挂号流水表为空"
		s RBASDr=$List(^User.DHCRegistrationFeeD(RegistDr),18)
		s ASSessionTypeDesc=""
		s ASSessionTypeDR=$p(^RBAS(+RBASDr,$p(RBASDr,"||",2),"DHC"),"^",6)
		s:ASSessionTypeDR'="" ASSessionTypeDesc=$p(^RBC("SESS",ASSessionTypeDR),"^",2)
		s BorDr="",RoomDr=""
		//&sql(SELECT ExabDr into :BorDr From SQLUser.DHCExaBoroughFilePath where ExabSubWaitFilePath=:IPAddress)
		//q:BorDr=""
		s QueRoomDr=""
		s QueRowid=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""),-1)
		s:QueRowid'="" QueRoomDr=$List(^User.DHCQueueD(QueRowid),13)
		i QueRoomDr="" s QueRoomDr=$List(^User.DHCRegistrationFeeD(RegistDr),20)
		&sql(SELECT RoomcRoomDr into :RoomDr From SQLUser.DHCRoomComp where RoomcIp=:IPAddress)
		i QueRoomDr="" s QueRoomDr=RoomDr
		q:QueRoomDr="" "诊室计算机IP未对照,请联系信息科,IP:"_IPAddress
		&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)
		q:BorDr="" "诊室诊区未作对照,请联系信息科"
		s BorName=$List(^User.DHCExaBoroughD(BorDr),5)
		s BorCode=$List(^User.DHCExaBoroughD(BorDr),2)
		s RoomName=$P(^CTLOC(QueRoomDr),"^",2)
		s RoomCode=$P(^CTLOC(QueRoomDr),"^",1)
		s CTPCPDr=$P(^RB("RES",+RBASDr),"^",2)
		s CTPCPName=$P(^CTPCP(CTPCPDr,1),"^",2)
		s CTPCPCode=$P(^CTPCP(CTPCPDr,1),"^",1)
		s SessionTypeDR=$P(^RBAS(+RBASDr,$P(RBASDr,"||",2)),"^",14)
	    s SessionTypeDesc=""
		i SessionTypeDR'="" s SessionTypeDesc=$P(^RBC("SESS",SessionTypeDR),"^",2)
		s CTLocName=$P(^CTLOC(LocID),"^",2)
		s UserInitials=$p(^SSU("SSUSR",UserID),"^",1)
		s UserDesc=$p(^SSU("SSUSR",UserID),"^",2)
		s SSUSRCTPCPDR=$p(^SSU("SSUSR",UserID),"^",14)
		s CTLocName=$P(^CTLOC(LocID),"^",2)
		s CTLocCode=$P(^CTLOC(LocID),"^",1)
		s PAAdmType=$p(^PAADM(EpisodeID),"^",2)
		if (PAAdmType="E"){s Kind="急诊"}else{s Kind="普通"}
		s PatientID=$P(^PAADM(EpisodeID),"^",1)
		s PAPMIName=$P(^PAPER(PatientID,"ALL"),"^",1)
		s Sex=""
		s SexDr=$P(^PAPER(PatientID,"ALL"),"^",7)
		s:SexDr'="" Sex=$p(^CT("SEX",SexDr),"^",2)
		set (doctorid,doctorcode,doctorname)=""
		//set doctorid=$P($G(^PAADM(EpisodeID)),"^",9)
		//set:doctorid'="" doctorcode=$p($g(^SSU("SSUSR",doctorid)),"^",1)
		//set:doctorid'="" doctorname=$p($g(^SSU("SSUSR",doctorid)),"^",2)
		//s doctorcode=CTPCPCode
		//s doctorname=CTPCPName   ///号别 不取号别 取医生
		s QueRowid=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""),-1)
		s CallNo=$LIST(^User.DHCQueueD(QueRowid),10)
		s DoctorId=$lg(^User.DHCQueueD(QueRowid),5)
		s CTTitleDR=""
		if (DoctorId'=""){
			s DoctorName=$P(^CTPCP(DoctorId,1),"^",2)
			s DoctorCode=$P(^CTPCP(DoctorId,1),"^",1)
			s CTPCPCarPrvTpDR=$p(^CTPCP(DoctorId,1),"^",4)
			s CTTitleDR=$p(^CTPCP(SSUSRCTPCPDR,3),"^",34)
		}else{
			s DoctorName=$P(^CTPCP(SSUSRCTPCPDR,1),"^",2)
			s DoctorCode=$P(^CTPCP(SSUSRCTPCPDR,1),"^",1)
			s CTPCPCarPrvTpDR=$p(^CTPCP(SSUSRCTPCPDR,1),"^",4)
			s CTTitleDR=$p(^CTPCP(SSUSRCTPCPDR,3),"^",34)
		}
		S QueStateDr = $LG(^User.DHCQueueD(QueRowid),14)	;队列状态
		s PersName = $LG(^User.DHCPerStateD(QueStateDr),4)
		b ;;;llkk
		if (PersName="过号") {
			s description=""
		}elseif (PersName="复诊") {
			s description="1"
		}else{
			s description=""
		}
		s doctorcode=DoctorCode
		s doctorname=DoctorName   ///医生
		i ASSessionTypeDesc="" {
		   //s:CTPCPCarPrvTpDR'="" ASSessionTypeDesc=$p(^CT("CPT",CTPCPCarPrvTpDR),"^",2)
		}
		s:CTTitleDR'="" ASSessionTypeDesc=$p(^CT("TTL",CTTitleDR),"^",2)
		//s ^tempgyt("DoctorId")=$lb(DoctorId,doctorname)
		s Type=0  ////文档0标识呼叫患者  1标识呼叫等候患者
		s WaitPatientStr=""
		s Len=$l(WaitEpisodeID,",")
		for m=1:1:Len{
			s OneWEpisodeInfo=$P(WaitEpisodeID,",",m)
			continue:OneWEpisodeInfo=""
			s WQueRowid=$P(OneWEpisodeInfo,"*",1)
			s OneWEpisodeID=$LIST(^User.DHCQueueD(WQueRowid),11)
			s WPatientID=$P(^PAADM(OneWEpisodeID),"^",1)
			s WPAPMIName=$P(^PAPER(WPatientID,"ALL"),"^",1)
			s WCallNo=$LIST(^User.DHCQueueD(WQueRowid),10)
			s WPAAdmType=$p(^PAADM(OneWEpisodeID),"^",2)
			
			S WQueStateDr = $LG(^User.DHCQueueD(WQueRowid),14)	;队列状态
			s WPersName = $LG(^User.DHCPerStateD(WQueStateDr),4)
			continue:WPersName="过号"
			if (WPersName="过号") {
				s Waitdescription=""
			}elseif (WPersName="复诊") {
				s Waitdescription="1"
			}else{
				s Waitdescription=""
			}
			i WaitPatientStr=""{
				s WaitPatientStr=WCallNo_"^"_WPAPMIName_"^"_Waitdescription
			}else{
				s WaitPatientStr=WaitPatientStr_"$"_WCallNo_"^"_WPAPMIName_"^"_Waitdescription
			}
		}
		
		///增加过号
		s GHPatientStr=""
		s GhLen=$l(GHList,"^")
       for n=1:1:GhLen{
			s OneWEpisodeInfo=$P(GHList,",",n)
			continue:OneWEpisodeInfo=""
			s WQueRowid=$P(OneWEpisodeInfo,"*",1)
			s OneWEpisodeID=$LIST(^User.DHCQueueD(WQueRowid),11)
			s WPatientID=$P(^PAADM(OneWEpisodeID),"^",1)
			s WPAPMIName=$P(^PAPER(WPatientID,"ALL"),"^",1)
			s WCallNo=$LIST(^User.DHCQueueD(WQueRowid),10)
			s WPAAdmType=$p(^PAADM(OneWEpisodeID),"^",2)
			
			S WQueStateDr = $LG(^User.DHCQueueD(WQueRowid),14)	;队列状态
			s WPersName = $LG(^User.DHCPerStateD(WQueStateDr),4)
			if (WPersName="过号") {
				s Waitdescription=""
			}elseif (WPersName="复诊") {
				s Waitdescription="1"
			}else{
				s Waitdescription=""
			}
			i GHPatientStr=""{
				s GHPatientStr=WCallNo_"^"_WPAPMIName_"^"_Waitdescription
			}else{
				s GHPatientStr=GHPatientStr_"$"_WCallNo_"^"_WPAPMIName_"^"_Waitdescription
			}
		}
		
		s BorDesc=""
		s ID=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
		if (ID'=""){
			s BorDesc=$p(^DHCVISClient(ID),"^",3)
		}
		
		///取专业组
		s LSGInfo=##class(DHCDoc.Interface.Inside.ServiceOPAdm).GetLSCGInfo(LocID) 
		s LSGCode=$p(LSGInfo,"^",1)
		s LSGDesc=$p(LSGInfo,"^",2)
		//i LSGCode'="" s CTLocCode=LSGCode
		//i LSGDesc'="" s CTLocName=LSGDesc
		i LSGCode="" s LSGCode=CTLocCode
		i LSGDesc="" s LSGDesc=CTLocName
		
		s LSGCode = LocID
		s CTPCPCode = CTPCPDr
		s RoomCode = QueRoomDr
		///登录科室 取对应的专业组 
		s CallInfo=EpisodeID_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_LSGCode_"^"_LSGDesc_"^"_CTPCPCode_"^"_BorDesc_"^"_doctorcode_"^"_doctorname
		s CallInfo=CallInfo_"^"_CallNo_"^"_PAPMIName_"^"_Type_"^^"_ASSessionTypeDesc_"^"_Sex_"^"_description_"^^"_CTLocCode_"^"_CTLocName_"^"_RoomCode_"^"_RoomName_"#"_WaitPatientStr_"#"_GHPatientStr
	}else{
		s BorDr="",RoomDr="",BorName="",BorCode=""
		&sql(SELECT RoomcRoomDr into :RoomDr From SQLUser.DHCRoomComp where RoomcIp=:IPAddress)
		s QueRoomDr=RoomDr
		q:QueRoomDr="" "诊室计算机IP未对照,请联系信息科,IP:"_IPAddress
		&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)
		//q:BorDr="" "诊室诊区未作对照,请联系信息科"
		if (BorDr'=""){
			s BorName=$List(^User.DHCExaBoroughD(BorDr),5)
			s BorCode=$List(^User.DHCExaBoroughD(BorDr),2)
		}
		s RoomName=$P(^CTLOC(QueRoomDr),"^",2)
		s RoomCode=$P(^CTLOC(QueRoomDr),"^",1)
		s CTLocName=$P(^CTLOC(LocID),"^",2)
		s CTLocCode=$P(^CTLOC(LocID),"^",1)
		
		b ///只是推送门急诊科室  科室分类 不是门诊急诊的不推送
		q:($d(^PAC("ADMLOC",0,"AdmType","O",LocID))=0)&&($d(^PAC("ADMLOC",0,"AdmType","E",LocID))=0) ""
		
		s SSUSRCTPCPDR=$p(^SSU("SSUSR",UserID),"^",14)
		s DoctorName=$P(^CTPCP(SSUSRCTPCPDR,1),"^",2)
		s DoctorCode=$P(^CTPCP(SSUSRCTPCPDR,1),"^",1)
		s CTPCPCarPrvTpDR=$p(^CTPCP(SSUSRCTPCPDR,1),"^",4)
		
		///查找当天的有效排班　　如果有取排班上的维护的职称　存在高职称低聘用的情况
		///^RB("RES",0,"CTPCP",{RES_CTPCP_DR},{RES_CTLOC_DR},{RES_RowId})
		s ASSessionTypeDesc=""
		s ResRowId=$O(^RB("RES",0,"CTPCP",SSUSRCTPCPDR,LocID,""))
		
		i ResRowId'=""{
			///^RBAS({RB_Resource.RES_RowId},0,"DateSTime",{AS_Date},{AS_SessStartTime},{AS_ChildSub})
			/*s StTime=0
			for{
				s StTime=$O(^RBAS(ResRowId,0,"DateSTime",+$h,StTime))
				q:StTime=""
				s ASSub=0
				for{
					s ASSub=$O(^RBAS(ResRowId,0,"DateSTime",+$h,StTime,ASSub))
					q:ASSub=""
					s ASSessionTypeDR=$p(^RBAS(ResRowId,ASSub,"DHC"),"^",6)
		            s:ASSessionTypeDR'="" ASSessionTypeDesc=$p(^RBC("SESS",ASSessionTypeDR),"^",2)
				}
			}*/
			
			//保留以上代码吧
			s SessionTypeID=$p($g(^RB("RES",ResRowId,"DHC")),"^",1)
			i SessionTypeID'="" s ASSessionTypeDesc=$P($G(^RBC("SESS",SessionTypeID)),"^",2)
			
			
			//s CTPCPCarPrvTpDR=SessionTypeID
		}
		i ASSessionTypeDesc=""{
		   s:CTPCPCarPrvTpDR'="" ASSessionTypeDesc=$p(^CT("CPT",CTPCPCarPrvTpDR),"^",2)
		}
		
		s CTTitleDR=$p(^CTPCP(SSUSRCTPCPDR,3),"^",34)
		s:CTTitleDR'="" ASSessionTypeDesc=$p(^CT("TTL",CTTitleDR),"^",2)
		
		s BorDesc=""
		s ID=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
		if (ID'=""){
			s BorDesc=$p(^DHCVISClient(ID),"^",3)
		}
		s doctorcode=DoctorCode
		s doctorname=DoctorName   ///医生
		s id=+$h_$p($h,",",2)_ID
		
		///取专业组
		s LSGInfo=##class(DHCDoc.Interface.Inside.ServiceOPAdm).GetLSCGInfo(LocID) 
		s LSGCode=$p(LSGInfo,"^",1)
		s LSGDesc=$p(LSGInfo,"^",2)
		/*i LSGCode'="" s CTLocCode=LSGCode
		i LSGDesc'="" s CTLocName=LSGDesc*/
		i LSGCode="" s LSGCode=CTLocCode
		i LSGDesc="" s LSGDesc=CTLocName
		
		///登录科室 取对应的专业组 
		/*s CallInfo=EpisodeID_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_LSGCode_"^"_LSGDesc_"^"_CTPCPCode_"^"_BorDesc_"^"_doctorcode_"^"_doctorname
		s CallInfo=CallInfo_"^"_CallNo_"^"_PAPMIName_"^"_Type_"^^"_ASSessionTypeDesc_"^"_Sex_"^"_description_"^^"_CTLocCode_"^"_CTLocName_"#"_WaitPatientStr_"#"_GHPatientStr*/
		
		;s CallInfo=id_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_CTLocCode_"^"_CTLocName_"^"_""_"^"_BorDesc_"^"_doctorcode_"^"_doctorname_"^"_""_"^"_""_"^"_""_"^^"_ASSessionTypeDesc_"^^^"_""_"#"_""
		s CallInfo=id_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_LSGCode_"^"_LSGDesc_"^"_""_"^"_BorDesc_"^"_doctorcode_"^"_doctorname_"^"_""_"^"_""_"^"_""_"^^"_ASSessionTypeDesc_"^^^^"_CTLocCode_"^"_CTLocName_"^"_RoomCode_"^"_RoomName_"#"_""
	}
	b ;xz--001
	s rtn = ..SendDeptScreenInfo(QueRowid,BorDr)
	s Flag=##class(web.DHCENS.BLL.Call.Method.CallInfo).SendAdmCallInfo(CallInfo,LoginFlag)
	
	;w ##class(web.DHCENS.BLL.Call.Method.CallInfo).SendAdmCallInfo($lg(^tempchen("call"),1),$lg(^tempchen("call"),2))
	if (Flag'["Call Success"){
		q Flag
	}
	q 0
	
SendAdmCallInfoET
     q "-1^叫号异常:"_$ze
}

/// /desc:推送诊区患者信息
/// w ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo("429",7)
ClassMethod SendDeptScreenInfo(QueRowId As %String = "", BorId As %String = "") As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	s ^Temp("SendAdmCallInfo")=$lb(QueRowId,BorId,UserID)
	q:BorId="" ""
	s Exab = 0
	s Mark = 0
	s queid = 0
	s Date = +$h
	s Obj = {}
	s Obj.deptKey = $lg(^User.DHCExaBoroughD(BorId),2)
	s Obj.owner = "HIS"
	s Obj.type = 0
	s Obj.screenInfo = []
	s Obj.overPatientInfo = []
	
	for {
		s Mark = $o(^User.DHCQueueI("QueMarkDrIndex",Date,Mark))
		q:Mark=""
		set screenInfoItem = {}
		set screenInfoItem.waitPatientInfo = []
		if QueRowId '= "" {
			if Mark = $lg($g(^User.DHCQueueD(QueRowId)),8) {
				set waitPatientInfo = {}
				set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(QueRowId)),10)
				set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(QueRowId)),9)
				set waitPatientInfo.sort=0 ;$lg($g(^User.DHCQueueD(QueRowId)),10) - 1
				do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
			}
		}
		set Que = 0
		for {
			s Que = $o(^User.DHCQueueI("QueMarkDrIndex",Date,Mark,Que))
			q:Que=""
			continue:Que=QueRowId
			set dept = $lg($g(^User.DHCQueueD(Que)),4)

			set bor = 0
			set bor = $o(^User.DHCExaBorDepI("BordDepDrIndex",dept,bor))
			set:bor'="" bor = $lg($g(^User.DHCExaBorDepD(bor)),6)
			s flag = 0
			if bor'=BorId {
				s flag = 1
				continue
			}
			set state = $lg($g(^User.DHCQueueD(Que)),14)
			;等候
			if ((state = 2)||(state = 1)) {
				;s opList = ##class(DHCDoc.OPDoc.PatientList).FindLocDocCurrentAdm()
				set rs=##class(%ResultSet).%New()
				set rs.ClassName="web.DHCDocOutPatientList"
				set rs.QueryName="FindLocDocCurrentAdm"
				/// w ##class(DHCDoc.OPDoc.PatientList).FindLocDocCurrentAdm(215,21333,"","","","","","","","","","","RegQue")
				s User = $o(^SSU("SSUSR",0,"CTPCP",Mark,""))
				set sc=rs.Execute(dept,User,"","","","","","","","","","","RegQue")
				s count = 0
				while rs.Next(.sc) {
					if $$$ISERR(sc) q
					s QueId = rs.Data("QueRowId")
					s count=count+1
					if Que = QueId {
						s sort = count	
					}
				}
				set waitPatientInfo = {}
				set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				if state = 1 {
					set waitPatientInfo.patientName="(复)"_$lg($g(^User.DHCQueueD(Que)),9)
				}
				else {
					set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				}
				set waitPatientInfo.sort=$g(sort)
				do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
			}
			
			;过号
			if state = 3 {
				set overPatientInfo = {}
				set overPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				set overPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				set overPatientInfo.sort=$lg($g(^User.DHCQueueD(Que)),10)
				do Obj.overPatientInfo.%Push(overPatientInfo)	
			}
		}
		set screenInfoItem.doctorKey = $p($g(^CTPCP(Mark,1)),"^",1)
		set screenInfoItem.doctorName = $p($g(^CTPCP(Mark,1)),"^",2)
		;set dept = $lg($g(^User.DHCExaBoroughD(Mark)),5)
		set screenInfoItem.deptName = $p($g(^CTLOC(dept)),"^",2)
		set screenInfoItem.consultName = 0 ;$lg($g(^User.DHCExaBoroughD(bor)),5)
		set screenInfoItem.shiftOut = 0
		
		if flag = 0 {
			do Obj.screenInfo.%Push(screenInfoItem)
		}
	}	
	s json = Obj.%ToJSON()
	b ;;;ss
	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	
  	set obj.Timeout=5
  	s className=obj.HIPMessageShow(json).Read()
	
	s json = {}.%FromJSON(className)
  	s status = json.status
  	q status
SendAdmCallInfoET
    q "-1^叫号异常:"_$ze
}

/// desc:推送全院患者信息
/// w ##class(DHCDoc.Interface.Outside.SYDEFY.DHCDocVISService.MainMethods).SendAllScreenInfo()
ClassMethod SendAllScreenInfo() As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	s Bor = 0
	for {
		s Bor = $o(^User.DHCExaBoroughD(Bor))
		s status = ..SendDeptScreenInfo("",Bor)	
	}
	q 0
SendAdmCallInfoET
     q "-1^叫号异常:"_$ze
}

/// 推送当天出诊的医生信息
/// w ##class(DHCDoc.Interface.Outside.TAZXYY.DHCDocVISService.MainMethods).SendScheduleDocInfo("2021-11-16")
ClassMethod SendScheduleDocInfo(ASDate As %String) As %String
{
	;s $ZTrap = "SendScheduleDocInfoET"
	k ^DHCDocSendInfo($j)
	s ASDate=$zdh(ASDate,3)
	s Date=ASDate
	s RBRowId=0
	for{
		s RBRowId=$O(^RBAS(0,"Date",Date,RBRowId))
		q:RBRowId=""
		s ASChildSub=0
		for{
			s ASChildSub=$O(^RBAS(0,"Date",Date,RBRowId,ASChildSub))
			q:ASChildSub=""
			continue:$d(^DHCDocSendInfo($j,RBRowId))'=0
			s status=$P($G(^RBAS(RBRowId,ASChildSub,"DHC")),"^",10)
	        i status'="" s status=$P(^DHCRBCASStatus(status),"^",1)
	        ///状态不正常的不推送
	        continue:(status="TR")!(status="S")!(status="PS")!(status="F")
	        s LocDesc=""
			s LocRowid=$p(^RB("RES",RBRowId),"^",1)
			s:LocRowid'="" LocDesc=$p(^CTLOC(LocRowid),"^",2)
			s DocDesc=""
			s:RBRowId DocDesc=$p(^RB("RES",RBRowId),"^",17)
			s ctcareprov=$p(^RB("RES",RBRowId),"^",2)
			s (doctorcode,doctorname)=""
			s:ctcareprov doctorcode=$p(^CTPCP(ctcareprov,1),"^",1)
			s:ctcareprov doctorname=$p(^CTPCP(ctcareprov,1),"^",2)
			s RoomDesc=""
			s RoomId=$P($G(^RBAS(RBRowId,ASChildSub,"DHC")),"^",5)
			continue:RoomId=""
			
			s BorDr=""
			&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:RoomId)
			;b ;hfl
			s BorCode=$list(^User.DHCExaBoroughD(BorDr),2)
			s BorName=$list(^User.DHCExaBoroughD(BorDr),5)
            s:RoomId'="" RoomDesc=$p(^CTLOC(RoomId),"^",2)
            s SessionTypeDesc=""
            s SessionTypeId=$P($G(^RBAS(RBRowId,ASChildSub,"DHC")),"^",6)
            s:SessionTypeId'="" SessionTypeDesc=$P($g(^RBC("SESS",SessionTypeId)),"^",2)
            s IPAddress=""
            &sql(SELECT RoomcIp into :IPAddress From SQLUser.DHCRoomComp where RoomcRoomDr=:RoomId )
            s ^DHCDocSendInfo($j,RBRowId)=""
            w LocDesc_" "_DocDesc_" "_RoomDesc_" "_SessionTypeDesc_" "_IPAddress ,!
            i doctorname="史宝海" d
            .s doctorname="姚国"
            .s doctorcode="A1020"
            q:doctorname'="王国军"
	        i doctorname="王国军" s doctorcode="A1004"
            ;s CallInfo=EpisodeID_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_CTLocCode_"^"_CTLocName_"^"_CTPCPCode_"^"_CTPCPName_"^"_doctorcode_"^"_doctorname_"^"_CallNo_"^"_PAPMIName_"^"_Type_"#"_WaitPatientStr
	        s CallInfo=114_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_LocDesc_"^"_LocDesc_"^"_RoomDesc_"^"_RoomDesc_"^"_doctorcode_"^"_doctorname_"^"_2_"^"_"测试"_"^"_0_"^"_SessionTypeDesc_"#"_"3^马莉$4^王蒙"
	        ;s CallInfo=114_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_LocDesc_"^"_LocDesc_"^"_RoomDesc_"^"_RoomDesc_"^"_doctorcode_"^"_doctorname ;_"^"_2_"^"_"测试"_"^"_0_"^"_SessionTypeDesc_"#"_"3^马莉$4^王蒙"
	        ;i doctorname="肖宝荣" b ;hfl ;b ;xz-11111
	        
	        s Flag=##class(web.DHCENS.BLL.Call.Method.CallInfo).SendAdmCallInfo(CallInfo)
			}
		
		}
	
  q 0	
	
	
SendScheduleDocInfoET
     q "-1^获取数据异常:"_$ze
}

///  钦泽报到机获取科室列表接口
/// w ##class(DHCDoc.Interface.Outside.TAZXYY.DHCDocVISService.MainMethods).GetArriveLoc("<Request><CardNo>371321198308265822</CardNo><Clinic></Clinic></Request>")
/// 返回 <Response><Code></Code><content></content><Msg></Msg></Response>
ClassMethod GetArriveLoc(XML As %Library.String)
{
	s $ZTrap="GetArriveLocET"
	s Obj=##class(DHCDoc.Util.XMLParse).XMLToObj(XML,"Request")
	s ReturnObj=##class(DHCDoc.Interface.Outside.TAZXYY.DHCDocQZArrive.Arrive).%New()
	s ReturnObj.Code="0"
	s ReturnObj.Msg=""
	s ReturnObj.CTLocList=""
	s ReturnObj.Count=0
	
	s CardNo=Obj.CardNo
	s Clinic=Obj.Clinic
	if Clinic="妇科诊区" s Clinic="妇产科诊区"
	s CardTypeId=""
	s CardNoLen=$l(CardNo)
	if (CardNoLen=10){
		s CardTypeId=1
	}elseif (CardNoLen=19){
		s CardTypeId=2
	}elseif (CardNoLen=9){
		s CardTypeId=26
	}
	elseif (CardNoLen=18){
		s CardTypeId=24
	}
	elseif (CardNoLen>19){
		s CardTypeId=25
	}
	if ('$d(^DHCCARDi("CF",0,"CardTypeNo",CardTypeId,CardNo)))&&(CardNoLen'=10){
		s ReturnObj.Code="-1"
		s ReturnObj.Msg="没有找到患者档案信息！"
		d ReturnObj.XMLExportToStream(.xml)
    	q xml
	}
	if ((CardNoLen=10)){
		s PatientId=$o(^PAPERi("PAPMI_PatNo",$$ALPHAUP^SSUTIL4(CardNo),""))
	}	
	else {	
		s CardId=$O(^DHCCARDi("CF",0,"CardTypeNo",CardTypeId,CardNo,""))
		s PatientId=$p(^DHCCARD("CF",CardId),"^",4)
	}
	s AdmTypeStr="O^E"
	s PAAdmType="",Count=0
	for k=1:1:$l(AdmTypeStr,"^"){
		s PAAdmType=$p(AdmTypeStr,"^",k)
		s EpisodeID=""
		for{
			s EpisodeID=$O(^PAPERdr(PatientId,"ADM",PAAdmType,EpisodeID))
			q:EpisodeID=""
			s CTLocInfoObj=##class(DHCDoc.Interface.Outside.TAZXYY.DHCDocQZArrive.CTLocInfo).%New()
			s QueID=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
			Continue:(QueID="")
			s QueDate=$List(^User.DHCQueueD(QueID),3)
			Continue:QueDate'=+$h
			s CTLoc=$p(^PAADM(EpisodeID),"^",4)
			s CTLocDesc=$p(^CTLOC(CTLoc),"^",2)
			Continue:CTLocDesc["核酸检测"         ;add by hfl 20220419  报到过滤核酸检测
			s ExaBorID=$O(^User.DHCExaBorDepI("BordDepDrIndex",CTLoc,""))
			s:ExaBorID'="" BorDr=$lg(^User.DHCExaBorDepD(ExaBorID),6)
			Continue:BorDr=""
			s BorName=$List(^User.DHCExaBoroughD(BorDr),5)			
			Continue:((Clinic'="")&&(Clinic'=BorName))
			s QueStateDr=$List(^User.DHCQueueD(QueID),14)
			s status=$List(^User.DHCPerStateD(QueStateDr),4)
			if ((status="到达")||(status="报到")||(status="复诊")||(status="等候")||(status="过号")){
				s CTLocInfoObj.CTLocId=CTLoc
				s CTLocInfoObj.CTLocDesc=CTLocDesc
				if (status="到达"){
					s statusDesc="复诊"
				}elseif (status="报到"){
					s statusDesc="初诊"
				}else{
					s statusDesc="查询"
				}
				s CTLocInfoObj.statusDesc=statusDesc
				d ReturnObj.CTLocList.Insert(CTLocInfoObj)
				s Count=Count+1	
			}					   
		}
	}

	s ReturnObj.Count=Count
	if (Count=0){
		s ReturnObj.Code="-1"
		s ReturnObj.Msg="请到分诊台核实是否有本诊区未报到挂号记录！"
	}
	d ReturnObj.XMLExportToStream(.xml)
	b ;3333
    q xml
GetArriveLocET
	s ReturnObj.Code="-1"
	s ReturnObj.Msg="查询失败，请到分诊台咨询:"_$ze
	s ReturnObj.CTLocList=""
	s ReturnObj.Count=0
	d ReturnObj.XMLExportToStream(.xml)
    q xml
}

///  钦泽报到机接口
/// w ##class(DHCDoc.Interface.Outside.TAZXYY.DHCDocVISService.MainMethods).PatArrive("<Request><CardNo>371321198308265822</CardNo><Clinic></Clinic><CTLocId>149</CTLocId></Request>")
/// 返回 <Response><Code></Code><content></content><Msg></Msg></Response>
ClassMethod PatArrive(XML As %Library.String)
{
	s $ZTrap="PatArriveET"
	s Obj=##class(DHCDoc.Util.XMLParse).XMLToObj(XML,"Request")
	s ReturnObj={}
	s ReturnObj.Code="0"
	s ReturnObj.content=""
	s ReturnObj.Msg=""
	s ReturnObj.ReportsMsg=""
	
	s CardNo=Obj.CardNo
	s Clinic=Obj.Clinic
	//s ReturnVisit=Obj.ReturnVisit
	s CTLocId=Obj.CTLocId
	if Clinic="妇科诊区" s Clinic="妇产科诊区"
	s CardNoLen=$l(CardNo)
	if (CardNoLen=10){
		s CardTypeId=1
	}elseif (CardNoLen=19){
		s CardTypeId=2
	}elseif (CardNoLen=9){
		s CardTypeId=26
	}
	elseif (CardNoLen=18){
		s CardTypeId=24
	}
	elseif (CardNoLen>19){
		s CardTypeId=25
	}
	if $d(^DHCCARDi("CF",0,"IDCardNo",$zcvt(CardNo,"U"))){
		
		
		}
	;if ('$d(^DHCCARDi("CF",0,"CardTypeNo",CardTypeId,CardNo)))&&(CardNoLen'=10){
	if ('$d(^DHCCARDi("CF",0,"CardNo",CardNo)))&&(CardNoLen'=10)&&('$d(^DHCCARDi("CF",0,"IDCardNo",$zcvt(CardNo,"U")))){	
		s ReturnObj.Code="-1"
		s ReturnObj.Msg="没有找到患者档案信息！"
		s Rtn=##class(DHCDoc.Util.XMLParse).ObjToXML(ReturnObj,"Response",.NodeList)
        q Rtn
	}
	if ((CardNoLen=10)){
		s PatientId=$o(^PAPERi("PAPMI_PatNo",$$ALPHAUP^SSUTIL4(CardNo),""))
	}	
	else {	
	    s CardId=$o(^DHCCARDi("CF",0,"IDCardNo",$zcvt(CardNo,"U"),""))
		;s CardId=$O(^DHCCARDi("CF",0,"CardTypeNo",CardTypeId,CardNo,""))
		
		if CardId="" s CardId=$o(^DHCCARDi("CF",0,"CardNo",CardNo,""))
		s PatientId=$p(^DHCCARD("CF",CardId),"^",4)
	}
	s papname=$p(^PAPER(PatientId,"ALL"),"^",1)   ;add by hfl 20220110 增加姓名
	if (Clinic="检验科"){
		s ReturnObj.Code="0"
		s ReturnObj.content=papname
		s Rtn=##class(DHCDoc.Util.XMLParse).ObjToXML(ReturnObj,"Response",.NodeList)
        q Rtn
	}
	ts
	s AdmTypeStr="O^E"
	s PAAdmType="",MSGStr="",ReportsMsg=""
	for k=1:1:$l(AdmTypeStr,"^"){
		s PAAdmType=$p(AdmTypeStr,"^",k)
		s EpisodeID=""
		for{
			s EpisodeID=$O(^PAPERdr(PatientId,"ADM",PAAdmType,EpisodeID))
			q:EpisodeID=""
			s QueID=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
			Continue:(QueID="")
			s QueDate=$List(^User.DHCQueueD(QueID),3)
			Continue:QueDate'=+$h

			s RegistDr=$o(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,""),-1)
			s BorDr=""
			/*s QueRoomDr=$List(^User.DHCQueueD(QueID),13)
			i QueRoomDr="" s QueRoomDr=$List(^User.DHCRegistrationFeeD(RegistDr),20)
			&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)*/
			s CTLoc=$p(^PAADM(EpisodeID),"^",4)
			s CTLocDesc=$p(^CTLOC(CTLoc),"^",2)
			s ExaBorID=$O(^User.DHCExaBorDepI("BordDepDrIndex",CTLoc,""))
			s:ExaBorID'="" BorDr=$lg(^User.DHCExaBorDepD(ExaBorID),6)
			Continue:BorDr=""
			s BorName=$List(^User.DHCExaBoroughD(BorDr),5)			
			Continue:((Clinic'="")&&(Clinic'=BorName))
			s QueStateDr=$List(^User.DHCQueueD(QueID),14)
			s status=$List(^User.DHCPerStateD(QueStateDr),4)
			if ((status="等候")||(status="复诊")){
				s patIndex=0
				s CTCareProId=$lg(^User.DHCQueueD(QueID),8)
				s CTCareProDesc=$p(^CTPCP(CTCareProId,1),"^",2)
				if ((CTCareProDesc'["普通号")&&(CTCareProDesc'["急诊号")){
					s DoctorUserId=$O(^SSU("SSUSR",0,"CTPCP",CTCareProId,""))
					s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdm")
					i rs.QueryIsValid() {
						//s waitPersons=waitPersons-1
						Set Status=rs.Execute(CTLoc,DoctorUserId,"","","","","","","","","","","")
						Set columns = rs.GetColumnCount()
						If 'Status Quit
						While rs.Next() {
							s patIndex=patIndex+1
							s ListEpisodeID=rs.GetDataByName("EpisodeID")
							q:ListEpisodeID=EpisodeID
						}
					}
					if (ReportsMsg=""){
						s ReportsMsg="科室:"_CTLocDesc_" 医生:"_CTCareProDesc_" 排队序列号："_patIndex
					}else{
						s ReportsMsg=ReportsMsg_"-"_"科室:"_CTLocDesc_" 医生:"_CTCareProDesc_" 排队序列号："_patIndex
					}
				}else{
					s ReportsMsg="已报到成功，请等候叫号。"
				}
			}
			
			s ReturnObj.Msg="请到分诊台核实是否有本诊区未报到挂号记录！"
			if ((status="报到")||((status="到达")||(status="过号")))	{
				b ;78888
				Continue:((CTLocId'="")&&(CTLocId'=CTLoc))		
				s Type="A"
				if status="过号" s Type="C"
				s UserID=12177  //%session.Get("LOGON.USERID")
				s CurDate=+$h
				s CurTime=$p($h,",",2)
				s desc=0
				s RetrunPersDr="",StateID=""
				&sql(select ID into :RetrunPersDr from  SQLUser.DHCPerState where PersName='退号')
				s desc=desc+SQLCODE
				if (status="到达"){
					&sql(select ID into :StateID from SQLUser.DHCPerState where PersName='复诊')
				}else{
					&sql(select ID into :StateID from SQLUser.DHCPerState where PersName='等候')
				}
				s desc=desc+SQLCODE
				&sql(update SQLUser.DHCQueue set questatedr=:StateID,QueStateDate=:CurDate,QueStateTime=:CurTime,Operuserid=:UserID
				 where Id=:QueID and QueStateDr<>:RetrunPersDr)
				s desc=desc+SQLCODE
				if (desc=0){
					s AdmId=$lg(^User.DHCQueueD(QueID),11)
					s rtnstr=##class(web.DHCDocOutPatientList).InsertNewQueueNo(AdmId,Type)
				}
				if (desc'=0){
					s ReturnObj.Code="-1"
					s ReturnObj.Msg="报道失败！"
				}
				
				s CTlocDesc=""
				s CTLocRowId=$p(^PAADM(EpisodeID),"^",4)
				s:CTLocRowId'="" CTlocDesc=$p(^CTLOC(CTLocRowId),"^",2)
				s QueNo=$List(^User.DHCQueueD(QueID),10)
				if (MSGStr=""){
					s MSGStr=CTlocDesc_"~("_QueNo_")"
				}else{
					s MSGStr=MSGStr_","_CTlocDesc_"~("_QueNo_")"
				}
			}
		}
		if (ReturnObj.Code'=0){
			 tro
			 q
		}
	}
	b ;3333
	tc
	s ReturnObj.ReportsMsg=ReportsMsg
	if (ReturnObj.Msg="请到分诊台核实是否有本诊区未报到挂号记录！")&&(ReportsMsg'=""){
		s ReturnObj.Msg=""
	}
	if ((MSGStr'="")&&(ReturnObj.Code'="-1")){
		s ReturnObj.Msg=MSGStr
	}
	s Rtn=##class(DHCDoc.Util.XMLParse).ObjToXML(ReturnObj,"Response",.NodeList)
	b ;444444
    q Rtn
PatArriveET
	s ReturnObj.Code="-1"
	s ReturnObj.Msg="报到失败，请到分诊台咨询:"_$ze
	s Rtn=##class(DHCDoc.Util.XMLParse).ObjToXML(ReturnObj,"Response",.NodeList)
    q Rtn
}

/// /desc:推送叫号患者信息
/// w ##class(DHCDoc.Interface.Outside.TAZXYY.DHCDocVISService.MainMethods).SendAdmCallInfo("5291","236",14114,"172.101.3.9","","1")
ClassMethod SendAdmWorkCallInfo(EpisodeID As %String = "", LocID As %String = "", UserID As %String = "", IPAddress As %String = "", WaitEpisodeID As %String = "", LoginFlag As %String = "", locSeqNo As %String = "") As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	s ^Temp("SendAdmCallInfo")=$lb(EpisodeID, LocID, UserID, IPAddress, WaitEpisodeID,LoginFlag)
	if (EpisodeID'=""){
		//s RegistDr=$o(^User.DHCRegistrationFeeI("ADM"," "_EpisodeID,""),-1)
		//q:RegistDr="" "-1^挂号流水表为空"
		//s RBASDr=$List(^User.DHCRegistrationFeeD(RegistDr),18)
		s ASSessionTypeDesc=""
		//s ASSessionTypeDR=$p(^RBAS(+RBASDr,$p(RBASDr,"||",2),"DHC"),"^",6)
		//s:ASSessionTypeDR'="" ASSessionTypeDesc=$p(^RBC("SESS",ASSessionTypeDR),"^",2)
		s BorDr="",RoomDr=""
		//&sql(SELECT ExabDr into :BorDr From SQLUser.DHCExaBoroughFilePath where ExabSubWaitFilePath=:IPAddress)
		//q:BorDr=""
		//s QueRoomDr=$List(^User.DHCQueueD(RegistDr),13)
		//i QueRoomDr="" s QueRoomDr=$List(^User.DHCRegistrationFeeD(RegistDr),20)
		&sql(SELECT RoomcRoomDr into :RoomDr From SQLUser.DHCRoomComp where RoomcIp=:IPAddress)
		s QueRoomDr=RoomDr
		&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)
		b ;33333
		q:BorDr="" "诊室诊区未作对照,请联系信息科"
		s BorName=$List(^User.DHCExaBoroughD(BorDr),5)
		s BorCode=$List(^User.DHCExaBoroughD(BorDr),2)
		s RoomName=$P(^CTLOC(QueRoomDr),"^",2)
		s RoomCode=$P(^CTLOC(QueRoomDr),"^",1)
		/*s CTPCPDr=$P(^RB("RES",+RBASDr),"^",2)
		s CTPCPName=$P(^CTPCP(CTPCPDr,1),"^",2)
		s CTPCPCode=$P(^CTPCP(CTPCPDr,1),"^",1)
		s SessionTypeDR=$P(^RBAS(+RBASDr,$P(RBASDr,"||",2)),"^",14)
	    s SessionTypeDesc=""
		i SessionTypeDR'="" s SessionTypeDesc=$P(^RBC("SESS",SessionTypeDR),"^",2)*/
		s CTLocName=$P(^CTLOC(LocID),"^",2)
		s UserInitials=$p(^SSU("SSUSR",UserID),"^",1)
		s UserDesc=$p(^SSU("SSUSR",UserID),"^",2)
		s SSUSRCTPCPDR=$p(^SSU("SSUSR",UserID),"^",14)
		s CTLocName=$P(^CTLOC(LocID),"^",2)
		s CTLocCode=$P(^CTLOC(LocID),"^",1)
		s PAAdmType=$p(^PAADM(EpisodeID),"^",2)
		if (PAAdmType="E"){s Kind="急诊"}else{s Kind="普通"}
		s PatientID=$P(^PAADM(EpisodeID),"^",1)
		s PAPMIName=$P(^PAPER(PatientID,"ALL"),"^",1)
		b ;1222
		s Sex=""
		s SexDr=$P(^PAPER(PatientID,"ALL"),"^",7)
		s:SexDr'="" Sex=$p(^CT("SEX",SexDr),"^",2)
		set (doctorid,doctorcode,doctorname)=""
		//set doctorid=$P($G(^PAADM(EpisodeID)),"^",9)
		//set:doctorid'="" doctorcode=$p($g(^SSU("SSUSR",doctorid)),"^",1)
		//set:doctorid'="" doctorname=$p($g(^SSU("SSUSR",doctorid)),"^",2)
		//s doctorcode=CTPCPCode
		//s doctorname=CTPCPName   ///号别 不取号别 取医生
		//s QueRowid=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""),-1)
		//s CallNo=$LIST(^User.DHCQueueD(QueRowid),10)
		s DoctorId=""  //$lg(^User.DHCQueueD(QueRowid),5)
		if (DoctorId'=""){
			s DoctorName=$P(^CTPCP(DoctorId,1),"^",2)
			s DoctorCode=$P(^CTPCP(DoctorId,1),"^",1)
			s CTPCPCarPrvTpDR=$p(^CTPCP(DoctorId,1),"^",4)
		}else{
			s DoctorName=$P(^CTPCP(SSUSRCTPCPDR,1),"^",2)
			s DoctorCode=$P(^CTPCP(SSUSRCTPCPDR,1),"^",1)
			s CTPCPCarPrvTpDR=$p(^CTPCP(SSUSRCTPCPDR,1),"^",4)
		}
		s CTPCPCode=DoctorCode
		s doctorcode=DoctorCode
		s doctorname=DoctorName   ///医生
		s:CTPCPCarPrvTpDR'="" ASSessionTypeDesc=$p(^CT("CPT",CTPCPCarPrvTpDR),"^",2)
		//s ^tempgyt("DoctorId")=$lb(DoctorId,doctorname)
		s Type=0  ////文档0标识呼叫患者  1标识呼叫等候患者
		s WaitPatientStr=""
		s Len=$l(WaitEpisodeID,",")
		for m=1:1:Len{
			s OneWEpisodeInfo=$P(WaitEpisodeID,",",m)
			continue:OneWEpisodeInfo=""
			s OneRegFeeId=$P(OneWEpisodeInfo,"*",1)
			s OneWEpisodeID=$List(^User.DHCRegistrationFeeD(OneRegFeeId),2)
			s WPatientID=$P(^PAADM(OneWEpisodeID),"^",1)
			s WPAPMIName=$P(^PAPER(WPatientID,"ALL"),"^",1)
			s WQueRowid=$O(^User.DHCQueueI("QuePaadmDrIndex",OneWEpisodeID,""),-1)
			s WCallNo=$LIST(^User.DHCQueueD(WQueRowid),10)
			s WPAAdmType=$p(^PAADM(OneWEpisodeID),"^",2)
			i WaitPatientStr=""{
				s WaitPatientStr=WCallNo_"^"_WPAPMIName
			}else{
				s WaitPatientStr=WaitPatientStr_"$"_WCallNo_"^"_WPAPMIName	
			}
		}
		s BorDesc=""
		s ID=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
		if (ID'=""){
			s BorDesc=$p(^DHCVISClient(ID),"^",3)
		}
		s CallNo=locSeqNo
		s CallInfo=EpisodeID_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_CTLocCode_"^"_CTLocName_"^"_CTPCPCode_"^"_BorDesc_"^"_doctorcode_"^"_doctorname_"^"_CallNo_"^"_PAPMIName_"^"_Type_"^^"_ASSessionTypeDesc_"^"_Sex_"#"_WaitPatientStr
	}else{
		s BorDr="",RoomDr="",BorName="",BorCode=""
		&sql(SELECT RoomcRoomDr into :RoomDr From SQLUser.DHCRoomComp where RoomcIp=:IPAddress)
		s QueRoomDr=RoomDr
		&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)
		//q:BorDr="" "诊室诊区未作对照,请联系信息科"
		if (BorDr'=""){
			s BorName=$List(^User.DHCExaBoroughD(BorDr),5)
			s BorCode=$List(^User.DHCExaBoroughD(BorDr),2)
		}
		s CTLocName=$P(^CTLOC(LocID),"^",2)
		s CTLocCode=$P(^CTLOC(LocID),"^",1)
		s SSUSRCTPCPDR=$p(^SSU("SSUSR",UserID),"^",14)
		s DoctorName=$P(^CTPCP(SSUSRCTPCPDR,1),"^",2)
		s DoctorCode=$P(^CTPCP(SSUSRCTPCPDR,1),"^",1)
		s CTPCPCarPrvTpDR=$p(^CTPCP(SSUSRCTPCPDR,1),"^",4)
		s ASSessionTypeDesc=""
		s:CTPCPCarPrvTpDR'="" ASSessionTypeDesc=$p(^CT("CPT",CTPCPCarPrvTpDR),"^",2)
		s BorDesc=""
		s ID=$O(^DHCVISClienti(0,"ClientIP",IPAddress,""))
		if (ID'=""){
			s BorDesc=$p(^DHCVISClient(ID),"^",3)
		}
		s doctorcode=DoctorCode
		s doctorname=DoctorName   ///医生
		s id=+$h_$p($h,",",2)_ID
		
		s CallInfo=id_"^"_IPAddress_"^"_BorCode_"^"_BorName_"^"_CTLocCode_"^"_CTLocName_"^"_""_"^"_BorDesc_"^"_doctorcode_"^"_doctorname_"^"_""_"^"_""_"^"_""_"^^"_ASSessionTypeDesc_"^"_""_"#"_""
	}
	
	b ;xz-11111
	s Flag=##class(web.DHCENS.BLL.Call.Method.CallInfo).SendAdmCallInfo(CallInfo,LoginFlag)
	if (Flag'="Call Success"){
		q Flag
	}
	
	q 0
	
	
SendAdmCallInfoET
     q "-1^叫号异常:"_$ze
}

ClassMethod ReCall(QueId, IPAddress)
{
	s RoomDr = ""
    s QueRowid = QueId
    s:QueRowid'="" QueRoomDr=$List(^User.DHCQueueD(QueRowid),13)
	;i QueRoomDr="" s QueRoomDr=$List(^User.DHCRegistrationFeeD(RegistDr),20)
	&sql(SELECT RoomcRoomDr into :RoomDr From SQLUser.DHCRoomComp where RoomcIp=:IPAddress)
	i QueRoomDr="" s QueRoomDr=RoomDr
	q:QueRoomDr="" "诊室计算机IP未对照,请联系信息科,IP:"_IPAddress
	&sql(SELECT BorDr into :BorDr From SQLUser.DHCBorExaRoom where BorExaRoomDr=:QueRoomDr)
	q:BorDr="" "诊室诊区未作对照,请联系信息科"
	s BorName=$List(^User.DHCExaBoroughD(BorDr),5)
	s BorCode=$List(^User.DHCExaBoroughD(BorDr),2)
	s RoomName=$P(^CTLOC(QueRoomDr),"^",2)
	s RoomCode=$P(^CTLOC(QueRoomDr),"^",1)
    s QueObj = ##class(User.DHCQueue).%OpenId(QueId)
    d QueObj.QueRoomDrSetObjectId(RoomDr)
    s rtn = QueObj.%Save()
	s deptKey = BorCode
	s consultKey = ""
	s voiceText = "请"_QueObj.QueName_"到"_RoomName_"就诊"
	s owner = "HIS"
	s OutputObj = {}
	s OutputObj.deptKey = deptKey
	s OutputObj.consultKey = consultKey
	s OutputObj.voiceText = voiceText
	s OutputObj.owner = owner
	s json = OutputObj.%ToJSON()
	s rtn = ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo(QueId,BorDr)
  	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	set obj.Timeout=5
  	s className=obj.HIPMessageServer(json).Read()
  	s json = {}.%FromJSON(className)
  	s status = json.status
	q status
}

}
