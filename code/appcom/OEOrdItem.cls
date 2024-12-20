/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  用于医嘱处理的公共服务类
/// -100 医嘱不存在
/// -209 状态不符合
/// -205 更新医嘱状态失败
/// -206 更新停止信息失败
/// -207 护士已经扫过条码,请撤销后再处理医嘱
/// -202 更新预停信息失败
/// -203 已经执行的医嘱不能停止
/// -201 已经停止的医嘱不用再停
/// -202 已经计费的医嘱不允许作废
Class appcom.OEOrdItem Extends DHCDoc.Util.RegisteredObject [ ClassType = "", ProcedureBlock ]
{

/// Creator:      周志强
/// CreatDate:    2012.03.27
/// Description:  医生撤销执行医嘱,用于医技科室取消执行
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).Verifye("178||109",687) 
ClassMethod Verify(OrdItmRowId As %String, UserRowId As %String, ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	set obj=##class(User.OEOrdItem).%OpenId(OrdItmRowId)
	if '$IsObject(obj) {
		s ErrMsg=..%GetErrCodeMsg("-100000")
		Quit "-100000"	// -100医嘱不存在
	}

	set OEORIItemStatDR=obj.OEORIItemStatDR
	set OEORIItemStateCode=$s($IsObject(OEORIItemStatDR):OEORIItemStatDR.OSTATCode,1:"")
	d obj.%Close()
	s obj=""
	if (OEORIItemStateCode'="E") {
		s ErrMsg=..%GetErrCodeMsg("-100011")
		Quit "-100011"   		//-211 执行状态的医嘱才能变为核实
	}

	s StatusRowId=$O(^OEC("OSTAT",0,"Code","V",0))
	TS
	s err=..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId)
	if err {
		Tro  
		s ErrMsg=..%GetErrCodeMsg("-100005")
		Q "-100005"            // -205 更新医嘱状态及变化表
	}
	
	//检验医嘱撤销清空字段
	&SQL(Update SQLUser.OE_ORDITEM 
			Set OEORI_LabTestSetRow="",OEORI_LabEpisodeSetup=NULL,
				OEORI_LabReceiveDate=NULL, OEORI_LabReceiveTime=NULL
    where OEORI_RowId=:OrdItmRowId)
	if SQLCODE {
		Tro
		s ErrMsg=..%GetErrCodeMsg("-100005")
		Q "-100005" 
		//s ErrMsg=##Class(web.DHCDocInPatPortalCommon).GetMsg("-205") 
		//Q "-205" 
	}
	
	s err=##class(appcom.OEOrdExec).VerifyAll(OrdItmRowId,UserRowId)
	if err {
		Tro  
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err  
	} 
	;处理检查申请单及执行记录的执行状态 
	s err=..SetAllPartExecExt(OrdItmRowId,UserRowId,"V","",.ErrMsg)
	if err {
		Tro  
		Q err 
	}	
	s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
	While (Sub'="") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		s SubStatusCode=..GetStatusCode(SubRowId)
		if (SubStatusCode'="E"){
			s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
			continue
		}
		s err=..UpdateStatus(SubRowId,UserRowId,StatusRowId)
		if err {
			s err="-100005" //-205
			Quit
		}
		//检验医嘱撤销清空字段
		&SQL(Update SQLUser.OE_ORDITEM  
				Set OEORI_LabTestSetRow="",OEORI_LabEpisodeSetup=NULL,
					OEORI_LabReceiveDate=NULL, OEORI_LabReceiveTime=NULL
	    where OEORI_RowId=:SubRowId)
		if SQLCODE Quit
		s err=##class(appcom.OEOrdExec).VerifyAll(SubRowId,UserRowId)
		if err Quit
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
	}
	i err {
		TRo 
		s ErrMsg=..%GetErrCodeMsg(err) 
		Q err
	}
	TC
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.27
/// Description:  医生执行医嘱
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// 			  ExpStr:执行时间^执行科室
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).Execute("110||68",108) 
ClassMethod Execute(OrdItmRowId As %String, UserRowId As %String, ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	//执行时间,仅是执行记录执行时间，医嘱执行时间因需与账单计费时间保持一致，影响计费点、计费价格等因数，统一按照当前时间处理。
	s ExecuteDateStr=$P(ExpStr,"^",1)
	//执行科室
	s ExecCTLocDr=$P(ExpStr,"^",2)
	i (ExecuteDateStr="")||($P(ExecuteDateStr," ")="") s ExecuteDateStr=..%ZD(..%SysDate())_" "_..%ZT(..%SysTime())
	set obj=##class(User.OEOrdItem).%OpenId(OrdItmRowId)
	if '$IsObject(obj) {
		s ErrMsg=..%GetErrCodeMsg("-100000")
		Quit "-100000"					// -100医嘱不存在
	}

	set OEORIItemStatDR=obj.OEORIItemStatDR
	set OEORIItemStateCode=$s($IsObject(OEORIItemStatDR):OEORIItemStatDR.OSTATCode,1:"")
	d obj.%Close()
	s obj=""
	if (OEORIItemStateCode'="V") {
		s ErrMsg=..%GetErrCodeMsg("-100009")
		Quit "-100009"   		// -209 非核实状态的医嘱不能执行
	}

	s StatusRowId=$O(^OEC("OSTAT",0,"Code","E",0))
	s Adm=$p(^OEORD(+OrdItmRowId),"^",1)
	TS
	s PartExpStr=ExecuteDateStr_"^"_ExecCTLocDr
	;处理检查申请单及执行记录的执行状态 -需放在医嘱状态改变之前 
	s err=..SetAllPartExecExt(OrdItmRowId,UserRowId,"E",PartExpStr,.ErrMsg)
	if err {
		Tro
		Q err
	}
	
	s err=..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId,"","")
	if err {
		Tro  
		s ErrMsg=..%GetErrCodeMsg("-100005")
		Quit "-100005"  // -205更新医嘱状态及变化表
	}
	;标版放开控制
	;屏蔽,如果检验,检查执行记录也变为执行,没有流程业务可以撤销.对于计费已经判断了医嘱的执行状态
	s err=##class(appcom.OEOrdExec).ExecuteAll(OrdItmRowId,UserRowId)
	if err {
		Tro  
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err
	} 
	s BillOrdStr=OrdItmRowId
	;s rtn=##Class(web.UDHCJFBILL).BILLN(Adm,UserRowId,OrdItmRowId)	;马上帐单
	s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
	While (Sub'="") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		s SubStatusCode=..GetStatusCode(SubRowId)
		if (SubStatusCode'="V"){
			s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
			continue
		}
		s err=..SetAllPartExecExt(OrdItmRowId,UserRowId,"E",PartExpStr,.ErrMsg)
		if err {
			Quit
		}
		s err=..UpdateStatus(SubRowId,UserRowId,StatusRowId)
		if err {
			s err="-100005" //-205
			Quit
		}
		s BillOrdStr=BillOrdStr_"^"_SubRowId
		;s rtn=##Class(web.UDHCJFBILL).BILLN(Adm,UserRowId,SubRowId)	;马上帐单
		;s err=##class(appcom.OEOrdExec).ExecuteAll(SubRowId,UserRowId)
		;if err Quit
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
	}
	i err {
		TRo
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	TC
	d ##class(DHCDoc.Util.Process).RunJobMethod("web.UDHCJFBILL","BILLN",Adm,UserRowId,BillOrdStr)
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  撤销单条医嘱,长期医嘱或临时医嘱开立后因为某种原因不再有效而失效,
///               但需要在医嘱单上记录。实际上该状态可以用"停止"状态代替，
///               是否需要这个状态要按医院的实际需求决定
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).Cancel("52||17",600) 
ClassMethod Cancel(OrdItmRowId As %String, UserRowId As %String, ReasonDr As %String = "", ReasonDesc As %String = "", IsBillN As %String = "Y", ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	s EpisodeID=$P(^OEORD(+OrdItmRowId),"^",1)
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s (ItemPartID,ExpendOrdCancelDate,ExpendOrdCancelTime,LocID)=""
	if (ExpStr'="") {
		s ItemPartID=$p(ExpStr,"^",1)
		s ExpendOrdCancelDate=$p(ExpStr,"^",2)
		s ExpendOrdCancelTime=$p(ExpStr,"^",3)
		s LocID=$p(ExpStr,"^",4)
	}
	s EpisodeID = $p(^OEORD(+OrdItmRowId),"^",1)
	s PAADMType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s StopAllExecFlag=0
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","C",0))
	
	s DoctorRowId=##class(web.SSUser).GetDefaultCareProvider(UserRowId)
	s practice=##class(web.DHCOEOrdItem).practice(DoctorRowId)
	if practice{
		s ret=..UpdateExtIfPractice(OrdItmRowId,UserRowId,StatusRowId,$p($h,",",1),"",..%SysTime(),ReasonDr,ReasonDesc)
		if ret'=0 {
			s ErrMsg=..%GetErrCodeMsg(ret)
		}
		Q ret
	}
	TS
	s err=..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId,ReasonDr,ReasonDesc)
	if err {
		Tro 
		s ErrMsg=..%GetErrCodeMsg("-100005")
		Q "-100005"       // -205 更新医嘱状态及变化表
	}
	;临时医嘱作废或者撤销可以直接停止执行记录,撤销和作废自动停止所有执行记录
	s StopFlag=1
	/*
	s PriorRowId= $p($g(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),1)),"^",8)
	if ##class(appcom.OEOrdItem).ISShortOrderPrior(PriorRowId) {
		s StopFlag=1
	}
	*/
	;调用医技接口位置放在医嘱状态改变之后，执行记录改变之前
    ;调用服务总线接口(调用平台组接口、调用检查申请取消接口、pacs工作站停医嘱接口、调用医政接口改变临床路径医嘱状态)
	s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(OrdItmRowId,UserRowId,"2",ItemPartID,LocID)
	s err=##Class(appcom.OEOrdExec).DiscontinueAll(OrdItmRowId,UserRowId,StopFlag,IsBillN,StopAllExecFlag,ExpStr)    //停止所有执行记录
	if err  {
		Tro  
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	;如果没有停医嘱人(护士办理出院结算自动停医嘱),则取下医嘱人
	if UserRowId="" s UserRowId=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),7)),"^",1)
	&SQL(Select SSUSR_CareProv_DR into :DoctorRowId from SQLUser.SS_User where SSUSR_RowId=:UserRowId )
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	if ($g(ExpendOrdCancelDate)'="") s CurrDate=ExpendOrdCancelDate
	if ($g(ExpendOrdCancelTime)'="") s CurrTime=ExpendOrdCancelTime
	s CareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(UserRowId)
    ;获取出院日期和时间
    if CareProvType="DOCTOR"{
        s DischargeDateTime=##class(web.DHCDocOrderCommon).GetMidDischargedDateTime(EpisodeID)   
    }else{
        s DischargeDateTime=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.GetDischargeDateTime",EpisodeID)
    }
    s DischargeDate=..%ZDH($p(DischargeDateTime,"^",1))
    s DischargeTime=..%ZTH($p(DischargeDateTime,"^",2))
	//患者已出院,取出院时间前一秒
	if ((DischargeDate'="")&&(DischargeDate<CurrDate))||((DischargeDate=CurrDate)&&(DischargeTime<CurrTime)){
		s CurrTime=DischargeTime-1
		if CurrTime<0 {
			s CurrTime=..%ZTH("23:59:59")
			s CurrDate=CurrDate-1
		}
	}
	s CFOPStopPaidItemCat=..%GetConfig("OPStopPaidItemCat")
	if CFOPStopPaidItemCat'="" s CFOPStopPaidItemCat="^"_CFOPStopPaidItemCat_"^"
	
	if PAADMType="I" {
		if $g(DoctorRowId)="" {  
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime where OEORI_rowid=:OrdItmRowId)
		}else{
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId where OEORI_rowid=:OrdItmRowId)
		}
	}else{
		if $g(DoctorRowId)="" {  
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_Billed='I' where OEORI_rowid=:OrdItmRowId)
		}else{
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId,OEORI_Billed='I' where OEORI_rowid=:OrdItmRowId)
		}
	}
	if SQLCODE {
		TRo  
		s ErrMsg=..%GetErrCodeMsg("-100006")
		Q "-100006" //-206
	}
	;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费)
	s err=..CancelOrdDocInterface(OrdItmRowId,UserRowId,.ErrMsg)
	if +err'=0  {
		Tro  
		Q err
	}		
	s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
	While (Sub'="") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		s SubStatusCode=..GetStatusCode(SubRowId)
		if (SubStatusCode="D")||(SubStatusCode="U")||(SubStatusCode="C") {
			s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
			continue
		}
		s err=..UpdateStatus(SubRowId,UserRowId,StatusRowId,ReasonDr,ReasonDesc)
		if err {
			s err="-100005" //-205
			Quit
		}	
		if PAADMType="I" {
			if DoctorRowId="" { 
				&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime where OEORI_rowid=:SubRowId)
			}else{
				&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId where OEORI_rowid=:SubRowId)
			}
		}else{
			if DoctorRowId="" { 
				&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_Billed='I' where OEORI_rowid=:SubRowId)
			}else{
				&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId,OEORI_Billed='I' where OEORI_rowid=:SubRowId)
			}
		}
		if SQLCODE {
			s err="-100006" //-206
			Quit
		}
		;调用医技接口位置放在医嘱状态改变之后，执行记录改变之前
		;调用服务总线接口(调用平台组接口、调用检查申请取消接口、pacs工作站停医嘱接口、调用医政接口改变临床路径医嘱状态)
		s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(SubRowId,UserRowId,"2","",LocID)
		
		s err=##Class(appcom.OEOrdExec).DiscontinueAll(SubRowId,UserRowId,StopFlag,IsBillN,StopAllExecFlag,ExpStr)
		if err Quit
		
		;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费)
		s err=..CancelOrdDocInterface(SubRowId,UserRowId,.ErrMsg)
	    if +err'=0 Quit
		
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
	}
	i err {
		TRo  
		s:ErrMsg="" ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	TC
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  作废单条医嘱,长期医嘱或临时医嘱开立后因为某种原因不再有效而失效,
///               而且不需要在医嘱单上记录
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).UnUse("77075||1",127) 
ClassMethod UnUse(OrdItmRowId As %String, UserRowId As %String, ReasonDr As %String = "", ReasonDesc As %String = "", IsBillN As %String = "Y", ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	;ForceMode="FORCE",则强制作废，不判断是否本人医嘱
	s ForceMode=$p(ExpStr,"^",1)
	s ExpendOrdUnUseDate=$p(ExpStr,"^",2)
	s ExpendOrdUnUseTime=$p(ExpStr,"^",3)
	s LocID=$p(ExpStr,"^",4)
	s EpisodeID=$P(^OEORD(+OrdItmRowId),"^",1)
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	
	s StopAllExecFlag=0
	;如果没有停医嘱人(护士办理出院结算自动停医嘱),则取下医嘱人
	if UserRowId="" s UserRowId=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),7)),"^",1)
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","U",0))
	s DoctorRowId=##class(web.SSUser).GetDefaultCareProvider(UserRowId)
	s practice=##class(web.DHCOEOrdItem).practice(DoctorRowId)
	if practice{
		s ret=..UpdateExtIfPractice(OrdItmRowId,UserRowId,StatusRowId,$p($h,",",1),"",..%SysTime(),ReasonDr,ReasonDesc)
		if ret'=0 {
			s ErrMsg=..%GetErrCodeMsg(ret)
		}
		Q ret
	}
	TS
	s err=..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId,ReasonDr,ReasonDesc)
	if err {
		Tro  
		s ErrMsg=..%GetErrCodeMsg("-100005")
		Q "-100005"        //-205更新医嘱状态及变化表
	}
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	if (ExpendOrdUnUseDate'="") s CurrDate=ExpendOrdUnUseDate
	if (ExpendOrdUnUseTime'="") s CurrTime=ExpendOrdUnUseTime
		
	if DoctorRowId="" { 
		&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime where OEORI_rowid=:OrdItmRowId)
	}else{
		&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId where OEORI_rowid=:OrdItmRowId)
	}
	if SQLCODE {
		TRo 
		s ErrMsg=..%GetErrCodeMsg("-100006")
		Q "-100006" //-206
	}
	;作废医嘱直接停止执行记录
	s err=##Class(appcom.OEOrdExec).DiscontinueAll(OrdItmRowId,UserRowId,1,IsBillN,StopAllExecFlag,ExpStr)    	//停止所有执行记录
	if err  {
		Tro  
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	;调用服务总线接口(调用平台组接口、调用检查申请取消接口、pacs工作站停医嘱接口、调用医政接口改变临床路径医嘱状态)
	s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(OrdItmRowId,UserRowId,"3","",LocID)
	
	;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费)
	s err=..CancelOrdDocInterface(OrdItmRowId,UserRowId,.ErrMsg)
	if +err'=0  {
		Tro  
		Q err
	}
	s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
	While (Sub'="") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		s SubStatusCode=..GetStatusCode(SubRowId)
		if SubStatusCode="U"{
			s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
			continue
		}
		s err=..UpdateStatus(SubRowId,UserRowId,StatusRowId,ReasonDr,ReasonDesc)
		if err {
			s err="-100005" //-205
			Quit
		}
		
		if DoctorRowId="" { 
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime where OEORI_rowid=:SubRowId)
		}else{
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId where OEORI_rowid=:SubRowId)
		}
		
		s err=##Class(appcom.OEOrdExec).DiscontinueAll(SubRowId,UserRowId,1,IsBillN,StopAllExecFlag,ExpStr)
		if err {
			Quit
		}
		;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费)
		s err=..CancelOrdDocInterface(SubRowId,UserRowId,.ErrMsg)
		if +err'=0  {
			Quit
		}
	    ;调用服务总线接口(调用平台组接口、调用检查申请取消接口、pacs工作站停医嘱接口、调用医政接口改变临床路径医嘱状态)
	    s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(SubRowId,UserRowId,"3","",LocID)
		
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
	}
	i err {
		TRo  
		s:ErrMsg="" ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	
	TCommit
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.27
/// Description:  得到医嘱状态代码
/// Table:        OE_OrdItem,OEC_OrderStatus
/// Input:        OrdItmRowId:医嘱Rowid,
/// Return: 	  0:成功
/// OutPut:		  医嘱状态的代码
/// Others:       w ##class(appcom.OEOrdItem).GetStatusCode("77071||59") 
ClassMethod GetStatusCode(OrdItmRowId As %String) As %String
{
	s OEORIItemStatDR=$p(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),1),"^",13)
	if OEORIItemStatDR="" Quit ""
	s OEORIItemStateCode=$p(^OEC("OSTAT",OEORIItemStatDR),"^",1)
	Quit OEORIItemStateCode
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  停止医嘱,将"未执行"的执行记录的医嘱状态上置"停止"，
/// 			  根据医院流程决定是否修改计费状态"B"变为"I","TB"变为"R"（调用计费设置）
///               ExpStr 
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 	  0:成功
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).Stop("77078||44",127,"","75600") 
/// 
ClassMethod Stop(OrdItmRowId As %String, UserRowId As %String, ExpectEndDate As %Date, ExpectEndTime As %Time, StopAllExecFlag As %String = "", IsBillN As %String = "Y", ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	;s ^tempscl("Stop")=OrdItmRowId_","_UserRowId_","_ExpectEndDate_","_ExpectEndTime_","_StopAllExecFlag_","_IsBillN_","_ExpStr
	s DealWithStoppedOrdFlag=0,ItemPartID="",XExecDateStr="",LocID=""
	if (ExpStr'=""){
		s DealWithStoppedOrdFlag=$p(ExpStr,"^",1) //已停止长期是否需要再次停止
		s ItemPartID=$p(ExpStr,"^",2)
		s XExecDateStr=$p(ExpStr,"^",3)					;关联停止执行记录的开始处理时间节点，如果为空，则默认按照停医嘱时间为节点，处理后续执行记录
		s LocID=$p(ExpStr,"^",4)	
	}
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	s OEORIItemStateCode=##class(appcom.OEOrdItem).GetStatusCode(OrdItmRowId)
	;如果没有停医嘱人(护士办理出院结算自动停医嘱),则取下医嘱人
	if UserRowId="" s UserRowId=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),7)),"^",1)
	s err=0
	s StatusRowId=$O(^OEC("OSTAT",0,"Code","D",0))
	s DoctorRowId=##class(web.SSUser).GetDefaultCareProvider(UserRowId)
	s practice=##class(web.DHCOEOrdItem).practice(DoctorRowId)
	if practice{
		s ret=..UpdateExtIfPractice(OrdItmRowId,UserRowId,StatusRowId,$s(ExpectEndDate="":CurrDate,1:ExpectEndDate),"",$s(ExpectEndTime="":CurrTime,1:ExpectEndTime))
		if (ret'=0) {
			s ErrMsg=..%GetErrCodeMsg(ret)
		}
		Q ret
	}
	TS
	if $g(ExpectEndDate)'="" {
		if ExpectEndTime="" s ExpectEndTime=CurrTime
		//预停时间大于本日则只更新预停时间
		if ExpectEndDate>CurrDate {
			&SQL(Update SQLUser.OE_OrdItem Set OEORI_EndDate=:ExpectEndDate,OEORI_EndTime=:ExpectEndTime,OEORI_UserUpdate=:UserRowId where OEORI_Rowid=:OrdItmRowId)
			if SQLCODE Tro  Q SQLCODE
			///增加预停时间日志
			&SQL(Insert into SQLUser.DHC_DocOrderPreStopLogin (DHCPreStop_Order,DHCPreStop_Date,DHCPreStop_Time,
			DHCPreStop_UpdateDate,DHCPreStop_UpdateTime,DHCPreStop_UpdateUser)Values (:OrdItmRowId,:ExpectEndDate,:ExpectEndTime
			,:CurrDate,:CurrTime,:UserRowId))
			if SQLCODE {
				Tro  
				s err="-100004"      // -204 更新时间
				Quit 
			}
			s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
			While (Sub'="") {
				s SubRowId=+OrdItmRowId_"||"_Sub
				;已经停止的医嘱不用再处理
				s SubStatusCode=..GetStatusCode(SubRowId) //||(SubStatusCode="U")
				//
				if (SubStatusCode="D")||(SubStatusCode="C")||(SubStatusCode="U") {
					s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
					continue
				}
	        	&SQL(Update SQLUser.OE_OrdItem Set OEORI_EndDate=:ExpectEndDate,OEORI_EndTime=:ExpectEndTime,OEORI_UserUpdate=:UserRowId where OEORI_Rowid=:SubRowId)
	        	if SQLCODE {
					s err="-100040"      // -2010 更新预停时间
					Quit
				}
				///增加预停时间日志
				&SQL(Insert into SQLUser.DHC_DocOrderPreStopLogin (DHCPreStop_Order,DHCPreStop_Date,DHCPreStop_Time,
				DHCPreStop_UpdateDate,DHCPreStop_UpdateTime,DHCPreStop_UpdateUser)Values (:SubRowId,:ExpectEndDate,:ExpectEndTime
				,:CurrDate,:CurrTime,:UserRowId))
				if SQLCODE  {
					s err="-100004"      // -204 更新时间
					Quit
				}
				s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
			}
			i err {
				TRo  
				s ErrMsg=..%GetErrCodeMsg(err)
				Q err
			}
			TC
			Quit 0
		}else{
			;如果传入的日期小于当前日期,会导致停止日期和需停长期医嘱的医嘱开始日期不一致
			;例如,当日开出院医嘱医嘱,将开始日期修改为昨天
			///增加预停时间日志
			&SQL(Insert into SQLUser.DHC_DocOrderPreStopLogin (DHCPreStop_Order,DHCPreStop_Date,DHCPreStop_Time,
			DHCPreStop_UpdateDate,DHCPreStop_UpdateTime,DHCPreStop_UpdateUser)Values (:OrdItmRowId,:ExpectEndDate,
			:ExpectEndTime,:CurrDate,:CurrTime,:UserRowId))
		}
			
	}
	if ExpectEndTime'="" s CurrTime=ExpectEndTime
	if ExpectEndDate'="" s CurrDate=ExpectEndDate
	/*小时医嘱停止提前到0点,退费会有问题,改到appcom.OEOrdExec.DiscontinueByXTime处理
	if (CurrTime=0)&&(##class(appcom.OEOrdItem).IsHourOrderItem(OrdItmRowId)) {
		s CurrTime=1
	}
	*/
	if ((OEORIItemStateCode="D")&&(DealWithStoppedOrdFlag="1"))||(OEORIItemStateCode'="D") {
		s StatusRowId=$O(^OEC("OSTAT",0,"Code","D",0))
		s err=..UpdateStatus(OrdItmRowId,UserRowId,StatusRowId)
		if err {
			Tro  
			s ErrMsg=..%GetErrCodeMsg("-100005")
			Q "-100005"  //-205
		}
		if DoctorRowId="" { 
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime where OEORI_rowid=:OrdItmRowId)
		}else{
			&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId where OEORI_rowid=:OrdItmRowId)
		}
		if SQLCODE {
			TRo 
			s ErrMsg=..%GetErrCodeMsg("-100006")
			Q "-100006" //-206
		}
		s err=##Class(appcom.OEOrdExec).DiscontinueByXTime(OrdItmRowId,UserRowId,StopAllExecFlag,IsBillN,XExecDateStr)
		if err {
			TRo  
			s ErrMsg=##Class(web.DHCDocInPatPortalCommon).GetMsg(err)
			Q err
		}
		;调用服务总线接口
		s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(OrdItmRowId,UserRowId,"1",ItemPartID,LocID)
		;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费)
		s err=..CancelOrdDocInterface(OrdItmRowId,UserRowId,.ErrMsg)
		if +err'=0  {
			Tro  
			Q err
		}
		s MasterCTCPTInternalType=""
		s MasterDoctorDr=$P($G(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),1)),"^",11)
		if (MasterDoctorDr'="") {
			s CTPCPCarPrvTpDR = $p(^CTPCP(MasterDoctorDr,1),"^",4)
			s MasterCTCPTInternalType = $p(^CT("CPT",CTPCPCarPrvTpDR),"^",4)
		}
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
		While (Sub'="") {
			s SubRowId=+OrdItmRowId_"||"_Sub
			;已经停止的医嘱不用再处理
			s SubStatusCode=..GetStatusCode(SubRowId)
			/*
				已作废的子医嘱是否停止按照以下逻辑处理:
				1、护士开立的关联医嘱护士执行作废后操作停医嘱需同时停止
				2、护士作废医生开立的成组子医嘱，医生停该成组医嘱不更新护士作废的那条子医嘱
				3、医生开立的成组医嘱医生作废后操作停医嘱需全部停止
			*/
			s xCTCPTInternalType="",UnuseOrdIsStop=0
			if (SubStatusCode="U") {
				s OEORIXCTCPDR=$p($g(^OEORD(+OrdItmRowId,"I",Sub,3)),"^",29)
				if (OEORIXCTCPDR'="") {
					s XCTPCPCarPrvTpDR = $p(^CTPCP(OEORIXCTCPDR,1),"^",4)
					s xCTCPTInternalType = $p(^CT("CPT",XCTPCPCarPrvTpDR),"^",4)
				}
				if (MasterCTCPTInternalType="NURSE") s UnuseOrdIsStop=1
				if (MasterCTCPTInternalType="DOCTOR")&&(xCTCPTInternalType="DOCTOR") s UnuseOrdIsStop=1
			}
			if ((SubStatusCode="D")&&(DealWithStoppedOrdFlag'="1"))||(SubStatusCode="C")||((SubStatusCode="U")&&(UnuseOrdIsStop=0)) {
				s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
				continue
			}
			s err=..UpdateStatus(SubRowId,UserRowId,StatusRowId)
			if err {
				s err="-100005" //-205
				Quit
			}
			if $g(DoctorRowId)="" { 
				&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime where OEORI_rowid=:SubRowId)
			}else{
				&SQL(Update SQLUser.OE_OrdItem set OEORI_Xdate=:CurrDate,OEORI_Xtime=:CurrTime,OEORI_XCTCP_DR=:DoctorRowId where OEORI_rowid=:SubRowId)
			}
			if SQLCODE {
				s err="-100006" //-206
				Quit
			}
			s err=##Class(appcom.OEOrdExec).DiscontinueByXTime(SubRowId,UserRowId,StopAllExecFlag,IsBillN,XExecDateStr)
			if err {
				Quit
			}
			;调用服务总线接口
			s rtn=##class(DHCDoc.Interface.Inside.Invoke).CancelOrdInterface(SubRowId,UserRowId,"1","",LocID)
			;撤销医嘱外部接口(撤销医疗结算、治疗申请单、会诊等申请;调用药房追踪接口;药理项目取消免费)
			s err=..CancelOrdDocInterface(SubRowId,UserRowId,.ErrMsg)
			if +err'=0  {
				Quit
			}
			s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
		}
		i err {
			TRo
			s ErrMsg=..%GetErrCodeMsg(err)  
			Q err
		}
		
	}	
	i err {
		TRo  
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	TC
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  更新医嘱状态,并插入医嘱状态变化表
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).UpdateStatus("531546||1",590) 
ClassMethod UpdateStatus(OrdItmRowId As %String, UserRowId As %String, StatusRowId As %String, ReasonDr As %String = "", ReasonDesc As %String = "") As %String
{

	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	TS
	&sql(Update SQLUser.OE_OrdItem set OEORI_ItemStat_DR=:StatusRowId where OEORI_RowId=:OrdItmRowId)
	if SQLCODE TRollback  q SQLCODE
	
	&sql(insert into SQLUser.OE_OrdStatus (ST_ParRef,ST_Date,ST_Time,ST_Status_DR,ST_User_DR)
	values (:OrdItmRowId,:CurrDate,:CurrTime,:StatusRowId,:UserRowId))
	if SQLCODE TRollback  q SQLCODE
	//更新撤下/作废原因
	s STRowId=$p(%ROWID,$c(1))
	s objstatus=##class(User.OEOrdStatus).%OpenId(STRowId)
	if (ReasonDr'="") d objstatus.STReasonDRSetObjectId(ReasonDr)
	e  i ReasonDesc'="" s objstatus.STReasonComtent=ReasonDesc
	s sc=objstatus.%Save()
	If $$$ISERR(sc) Tro  Quit "-100044" //-3077
    d objstatus.%Close()
    s objstatus=""
    
	TC
	Q SQLCODE
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  停止医嘱处理
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针,PWFlag:是否密码验证,PinNum:明文密码
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).StopMulti("531546||1",590,"") 
ClassMethod StopMulti(OrdList As %String = "", UserID As %String = "", PinNum As %String, PWFlag As %String = "Y", ExpStr As %String = "", ByRef ErrMsg As %String = "")
{
	s ^TEMP("Debug","StopMulti")="w ##class(appcom.OEOrdItem).StopMulti("""_OrdList_""","""_UserID_""","""_PinNum_""","""_PWFlag_""")"
	s adm=$$GetAdmByOrdList(OrdList)
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(adm)
	s PAADMType=$p($g(^PAADM(adm)),"^",2)
	if PAADMType'="I" {
		s OrdList=$tr(OrdList,"!","&")
		Q ##class(web.UDHCStopOrderLook).StopOrder("","",OrdList,UserID,PinNum,PWFlag,ExpStr,.ErrMsg)
	}
	
	;密码验证
	s err=0
 	if PWFlag="Y" s err=##Class(web.DHCOEOrdItem).PinNumberValid(UserID,PinNum)
	if (err'=0) {
		 s ErrMsg=..%GetErrCodeMsg("-100029")
		 Q "-100029" //err
	}
	
 	s OrdListStr=..GetMulOrdGroup(OrdList,UserID,"S")
	s OrdListStr=##Class(web.UDHCStopOrderLook).GetAppenOrdInfo(OrdListStr)
	s locid=$P(ExpStr,"^",4)
	s groupid=$P(ExpStr,"^",5)
	s SessionStr=..%SessionStr()
	s:locid="" locid=$P(SessionStr,"^",3)
	s:groupid="" groupid=$P(SessionStr,"^",2)
	s date=$p($p(OrdList,"^"),"!",2)
	s time=$p($p(OrdList,"^"),"!",3)
	;暂时只开启传入了科室和安全组
	if (locid'="")&&(groupid'="")&&'##class(web.DHCDocMain).CheckStopOrder(OrdListStr,UserID,locid,groupid,date,time,.ErrMsg){
		Q ErrMsg
	}
	s adm=""
 	s err=0
 	s OrdList=OrdListStr
 	s len=$l(OrdList,"^")
	TS
	for i=1:1:len {
		s OrderItemStr=$p(OrdList,"^",i)
		s oeitm=$p(OrderItemStr,"!",1)
		s EndDate=$p(OrderItemStr,"!",2)
		s EndTime=$p(OrderItemStr,"!",3)
		s EndDate=..%ZDH(EndDate)
		s:EndDate="" EndDate=..%SysDate()
		s EndTime=..%ZTH(EndTime)
		s:EndTime="" EndTime=..%SysTime()
		s SttDate=$p($G(^OEORD(+oeitm,"I",$p(oeitm,"||",2),1)),"^",9)
		//当天执行记录强制停止子类
		s itemrowid=$p($g(^OEORD(+oeitm,"I",$p(oeitm,"||",2),1)),"^",2)
		s ItemCatRowId=+$p($g(^ARCIM(+$g(itemrowid),1,1)),"^",10)
		s StopAllExecItemCat=..%GetConfig("StopAllExecItemCat",AdmHospDr) //$g(^DHCDocConfig("StopAllExecItemCat"))
		s StopAllExecFlag=0
		i ("^"_StopAllExecItemCat_"^")[("^"_ItemCatRowId_"^") s StopAllExecFlag=1
		s OrdPriorityDR=$p(^OEORD(+oeitm,"I",$p(oeitm,"||",2),1),"^",8)
		if (##class(appcom.OEOrdItem).ISLongOrderPrior(OrdPriorityDR)){
			;此处参数 IsBillN 传入Y,屏蔽下方根据就诊调用,后续在异步方法内部根据执行记录调用,避免影响数据一致性
			s err=..Stop(oeitm,UserID,EndDate,EndTime,StopAllExecFlag,"Y",ExpStr,.ErrMsg)
		}else{
			// 护士绑定得临时医嘱如果和长期医嘱得停止时间一致时，才自动撤销
			if (SttDate<=EndDate){
				s CancelExpStr=$P(ExpStr,"^",2)
				s err=..Cancel(oeitm,UserID,"","","N",CancelExpStr,.ErrMsg)
			}
		}
		Q:err'=0
		s adm=$p(^OEORD(+oeitm),"^",1)
	 }
	 if err'=0{
		TRO
		Q err
	 }
	 TC
	 s rtn=##Class(DHCAnt.KSS.Combined).StopAntOrder(adm,OrdList)
	 //s rtn=##Class(web.UDHCJFBILL).BILLN(adm,UserID,"")
	 /*集成平台接口
	 Set OrdList=##class(DHCIntergration.Common.Method.Base).ReplaceStr(OrdList,"&&","^")
	 d ##class(web.DHCBL.CI.ServiceBuilder).OPOEORIService("OPCRefund",OrdList)
	 */
	 q err
GetAdmByOrdList(OrdListStr)
	s adm=""
	s len=$l(OrdListStr,"^")
	for i=1:1:len {
		s OrderItemStr=$p(OrdListStr,"^",i)
		s oeitm=$p(OrderItemStr,"!",1)
		continue:oeitm=""
		s adm=$p(^OEORD(+oeitm),"^",1)
		quit
	 }
	 Q adm
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  撤销医嘱处理
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).CancelMulti("77078||17",127,"N","N") 
ClassMethod CancelMulti(OrdList As %String, UserID As %String, PinNum As %String, PWFlag As %String = "Y", ReasonDr As %String = "", ReasonDesc As %String = "", ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	;s ^Wqy("CancelMulti")=$LB(OrdList, UserID, PinNum, PWFlag, ReasonDr, ReasonDesc, ExpStr )
	Q:($g(OrdList)="")||($g(UserID)="") -100
	
	s err=0
	;密码验证
 	if PWFlag="Y" s err=##Class(web.DHCOEOrdItem).PinNumberValid(UserID,PinNum)
	if (err'=0) {
		s ErrMsg=..%GetErrCodeMsg("-100029")
		Q "-100029" //err
	}
    s OrdListStr=..GetMulOrdGroup(OrdList,UserID,"C")
	s OrdListStr=##Class(web.UDHCStopOrderLook).GetAppenOrdInfo(OrdListStr)
	//多科会诊申请产生的多条医嘱  不需要同时撤销/作废
	s AppendOrdListStr="" //..GetCstRelOeori(OrdListStr)
	if (AppendOrdListStr'=""){
		s OrdListStr=OrdListStr_"^"_AppendOrdListStr
	}
	s locid=$P(ExpStr,"^",4)
	s groupid=$P(ExpStr,"^",5)
	s IsBillN=$P(ExpStr,"^",6)
	s:IsBillN="" IsBillN="Y"
	s SessionStr=..%SessionStr()
	s:locid="" locid=$P(SessionStr,"^",3)
	s:groupid="" groupid=$P(SessionStr,"^",2)
	;暂时只开启传入了科室和安全组
	if (locid'="")&&(groupid'="")&&'##class(web.DHCDocMain).CheckCancelOrder(OrdListStr,UserID,locid,groupid,.ErrMsg,ExpStr){
		Q ErrMsg
	}
	s adm=""
 	s err=0
 	s OrdList=OrdListStr
 	k TempCancelMulOEItem($j)
 	s len=$l(OrdList,"^")
	TS
	for i=1:1:len {
		s OrderItemStr=$p(OrdList,"^",i)
		s oeitm=$p(OrderItemStr,"!",1)
		continue:$d(TempCancelMulOEItem($j,oeitm))
		;此处参数 IsBillN 传入Y,屏蔽下方根据就诊调用,后续在异步方法内部根据执行记录调用,避免影响数据一致性
		s err=..Cancel(oeitm,UserID,ReasonDr,ReasonDesc,IsBillN,ExpStr,.ErrMsg)
		Q:err'=0
		s adm=$p(^OEORD(+oeitm),"^",1)
		s TempCancelMulOEItem($j,oeitm)=1
	 }
	 k TempCancelMulOEItem($j)
	if err'=0{
		TRO
		Q err
	}
	TC
	i adm'="" {
		//Set rtn=##Class(web.UDHCJFBILL).BILLN(adm,UserID,"")
		;抗生素联用撤销医嘱
		s antrtn=##class(DHCAnt.KSS.Combined).StopAntOrder(adm,OrdList)  
	}
	Quit err
}

/// Others: w ##class(appcom.OEOrdItem).GetMulOrdGroup("50015494||40^50015494||41^50015494||42",25814)
ClassMethod GetMulOrdGroup(OrdList As %String, UserID As %String, OperateType As %String) As %String
{
	s adm=$p(^OEORD(+OrdList),"^",1)
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(adm)
 	;重新组织停医嘱串,根据配置停主医嘱 停子医嘱同时停主医嘱
 	s StopGroupOrder=..%GetConfig("StopGroupOrder",AdmHospDr)
	s CTCPTInternalType=##class(web.DHCDocMain).GetCarePrvTpByUserID(UserID)	;传入用户医护类型
	k OrdListStrArr
	s len=$l(OrdList,"^")
	for i=1:1:len {
		s OrderItemStr=$p(OrdList,"^",i)
		i OrderItemStr[$C(1) s oeitm=$p(OrderItemStr,$C(1),1)
		e  s oeitm=$p(OrderItemStr,"!",1)
		if oeitm="" continue
		s OrdLinkRowId=$p($g(^OEORD(+oeitm,"I",$p(oeitm,"||",2),11)),"^",39)
		i OrdLinkRowId="" s OrdListArr(oeitm)=OrderItemStr
		e  s OrdListArr(OrdLinkRowId,oeitm)=OrderItemStr
    }
 	s OrdListStr=""
	s MastOrdItemID="" for{
		s MastOrdItemID=$O(OrdListArr(MastOrdItemID)) Q:MastOrdItemID=""
		s MastOrdItemStr=$G(OrdListArr(MastOrdItemID))
		s AddOrdInternalType=##class(web.DHCDocMain).GetOrdUserCareProvTp(MastOrdItemID)	;开单用户医护类型
		//如果配置为停子医嘱,同时停主医嘱,主医嘱用户类型一致
		if (MastOrdItemStr="")&&(StopGroupOrder=1)&&(AddOrdInternalType=CTCPTInternalType){
			s FindDocOrd=1
			if CTCPTInternalType="DOCTOR"{	//如果医生只选择了护士绑定医嘱,需特殊处理
				s FindDocOrd=0
				s OrdItemID="" for{	
					s OrdItemID=$O(OrdListArr(MastOrdItemID,OrdItemID)) Q:OrdItemID=""
					s SubAddOrdInternalType=##class(web.DHCDocMain).GetOrdUserCareProvTp(OrdItemID)
					if SubAddOrdInternalType="DOCTOR"{
						s FindDocOrd=1
						Q
					}
				}
			}
			if FindDocOrd{
				s OrdItemID=$O(OrdListArr(MastOrdItemID,""))
				s MastOrdItemStr=OrdListArr(MastOrdItemID,OrdItemID)
				i MastOrdItemStr[$C(1) s $p(MastOrdItemStr,$C(1),1)=MastOrdItemID
				e  s $p(MastOrdItemStr,"!",1)=MastOrdItemID
			}
		}
		;传入了主医嘱,那么子医嘱就不用处理
		if MastOrdItemStr'=""{
			i OrdListStr="" s OrdListStr=MastOrdItemStr
			e  s OrdListStr=OrdListStr_"^"_MastOrdItemStr
			s MastLongOrdFlag=##class(DHCDoc.Order.Filter).IsLongOrdItem(MastOrdItemID)
			////长期医生医嘱绑定的临时护嘱/治疗医嘱的绑定医嘱，子医嘱也要对应的停止、撤销、作废
			s Sub=0 for{
				s Sub=$o(^OEORDi(0,"SERORD",MastOrdItemID,+MastOrdItemID,Sub)) Q:Sub=""
				s SubRowId=+MastOrdItemID_"||"_Sub
				s SubOrdLinkRowId=$p($g(^OEORD(+SubRowId,"I",Sub,11)),"^",39)
				continue:SubOrdLinkRowId=MastOrdItemID	;本身就是子医嘱  不用获取
				s BindSource=$p($g(^OEORD(+SubRowId,"I",$P(SubRowId,"||",2),"DHC")),"^",41)
				continue:BindSource="CA" ;治疗站也绑定了成组关系
				s StatusCode=##class(DHCDoc.Order.Common).GetOrdStatusCode(SubRowId)
				continue:"CU"[StatusCode
				;停长期的时候 临时不返回
				continue:MastLongOrdFlag&&(OperateType="S")&&'##class(DHCDoc.Order.Filter).IsLongOrdItem(SubRowId)
				i OrdListStr="" s OrdListStr=SubRowId
				e  s OrdListStr=OrdListStr_"^"_SubRowId
			}
			continue
		}
		s OrdItemID="" for{
			s OrdItemID=$O(OrdListArr(MastOrdItemID,OrdItemID)) Q:OrdItemID=""
			s OrderItemStr=OrdListArr(MastOrdItemID,OrdItemID)
			i OrdListStr="" s OrdListStr=OrderItemStr
			e  s OrdListStr=OrdListStr_"^"_OrderItemStr
		}
	}
    Q OrdListStr
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  作废医嘱处理
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).UnUseMulti("147||27",4634,"1","Y") 
ClassMethod UnUseMulti(OrdList As %String, UserID As %String, PinNum As %String, PWFlag As %String = "Y", ReasonDr As %String = "", ReasonDesc As %String = "", ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	s ^TEMP("Debug","UnUseMulti")="w ##class(appcom.OEOrdItem).UnUseMulti("""_OrdList_""","""_UserID_""","""_PinNum_""","""_PWFlag_""")"
	if ($g(OrdList)="")||($g(UserID)="") {
		s ErrMsg=..%GetErrCodeMsg("-100000")
		Q "-100000" //-100
	}
	
	s err=0
	;密码验证
 	if PWFlag="Y" s err=##Class(web.DHCOEOrdItem).PinNumberValid(UserID,PinNum)
	if err'=0 {
		s ErrMsg=..%GetErrCodeMsg("-100029")
		Q "-100029" //err
	}
	
 	s OrdListStr=..GetMulOrdGroup(OrdList,UserID,"U")
	s OrdListStr=##Class(web.UDHCStopOrderLook).GetAppenOrdInfo(OrdListStr)
	
	//多科会诊申请产生的多条医嘱  不需要同时撤销/作废
	s AppendOrdListStr="" //..GetCstRelOeori(OrdListStr)
	if (AppendOrdListStr'=""){
		s OrdListStr=OrdListStr_"^"_AppendOrdListStr
	}
	s locid=$P(ExpStr,"^",4)
	s groupid=$P(ExpStr,"^",5)
	s SessionStr=..%SessionStr()
	s:locid="" locid=$P(SessionStr,"^",3)
	s:groupid="" groupid=$P(SessionStr,"^",2)
	;暂时只开启传入了科室和安全组
	if (locid'="")&&(groupid'="")&&'##class(web.DHCDocMain).CheckUnuseOrder(OrdListStr,UserID,locid,groupid,.ErrMsg,ExpStr){
		Q ErrMsg
	}
	
	s adm=""
 	s err=0
 	s OrdList=OrdListStr
 	s len=$l(OrdList,"^")
 	k TempUnUserMulOEItem($j)
	TS
	for i=1:1:len {
		s OrderItemStr=$p(OrdList,"^",i)
		s oeitm=$p(OrderItemStr,"!",1)
		continue:$d(TempUnUserMulOEItem($j,oeitm))
		;此处参数 IsBillN 传入Y,屏蔽下方根据就诊调用,后续在异步方法内部根据执行记录调用,避免影响数据一致性
		s err=..UnUse(oeitm,UserID,ReasonDr,ReasonDesc,"Y",ExpStr,.ErrMsg)
		Q:err'=0
		s adm=$p(^OEORD(+oeitm),"^",1)
		s TempUnUserMulOEItem($j,oeitm)=1
	 }
	 k TempUnUserMulOEItem($j)
	 if err'=0{
		TRO
		Q err
	 }
	 TC
	 //s rtn=##Class(web.UDHCJFBILL).BILLN(adm,UserID,"")
	 ;抗生素联用作废医嘱
	 s antrtn=##class(DHCAnt.KSS.Combined).CancleAntOrder(adm,OrdList)   
	 Q err
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  判断是否为小时类医嘱,这类医嘱执行记录里一天只插入一条
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).IsHourOrderItem("77067||9") 
ClassMethod IsHourOrderItem(OrderItemRowId As %String) As %String
{
	;s ArcimRowId=$p(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),1),"^",2)
	;s BillUomRowId=$p($g(^ARCIM(+ArcimRowId,$p(ArcimRowId,"||",2),8)),"^",14)
	s BillUomRowId=##Class(web.DHCDocOrderCommon).GetOrdPackUOMDR(OrderItemRowId) 
	s BillUomCode=""
	s:+BillUomRowId'=0 BillUomCode=$p($g(^CT("UOM",BillUomRowId)),"^")
	s BillUomCode=$zcvt($g(BillUomCode),"U")
	Q:BillUomCode="HOUR" 1
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.19
/// Description:  判断是否为长期医嘱类型
/// Table:        OEC_OrderPriority
/// Input:        PriorRowId:医嘱类型指针
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).ISLongOrderPrior("77067||9") 
ClassMethod ISLongOrderPrior(PriorRowId As %String)
{
	q:PriorRowId="" 0
	s PriorCode=$p($g(^OECPR(PriorRowId)),"^")
	if (PriorCode="S")||(PriorCode="OMST")||(PriorCode="OMCQZT") {
		Q 1
	}
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.19
/// Description:  判断是否为不发药医嘱
/// Table:        OEC_OrderPriority
/// Input:        PriorRowId:医嘱类型指针
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).ISUnDspOrderPrior("1") 
ClassMethod ISUnDspOrderPrior(PriorRowId As %String)
{
	i PriorRowId="" Q 0
	s PriorCode=$p($g(^OECPR(PriorRowId)),"^",1)
	if (PriorCode="OM")||(PriorCode="OMST") Q 1
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.19
/// Description:  判断是否为临时类医嘱
/// Table:        OEC_OrderPriority
/// Input:        PriorRowId:医嘱类型指针
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).ISShortOrderPrior("1") 
ClassMethod ISShortOrderPrior(PriorRowId As %String, OrderPriorType As %String = "")
{
	i PriorRowId="" Q 0
	s PriorCode=$p($g(^OECPR(PriorRowId)),"^",1)
	;Q '..ISLongOrderPrior(PriorCode)
	//if (PriorCode="OM")||(PriorCode="NORM")||(PriorCode="STAT")||(PriorCode="OUT")||(PriorCode="ONE")||(PriorCode="OMLSZT") Q 1
	if (OrderPriorType="OutOrderPrior"){
		if (PriorCode="OUT") Q 1
		Q 0
	}elseif(OrderPriorType="ShortOrderPrior"){
		if (PriorCode="OM")||(PriorCode="NORM")||(PriorCode="STAT")||(PriorCode="ONE")||(PriorCode="OMLSZT") Q 1
		Q 0
	}else{
		if (PriorCode="OM")||(PriorCode="NORM")||(PriorCode="STAT")||(PriorCode="OUT")||(PriorCode="ONE")||(PriorCode="OMLSZT") Q 1
	}
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.19
/// Description:  判断是否为PRN医嘱(长期)
/// Table:        OEC_OrderPriority
/// Input:        PriorRowId:医嘱类型指针
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).ISPRNOrder("77067||9") 
ClassMethod ISPRNOrder(OrdItmRowId As %String) As %String
{
	s PHFreqDr = $p($g(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),2)),"^",4)	;频次 OEORI_PHFreq_DR
	s PHFreqCode=$s(PHFreqDr'="":$p(^PHCFR(PHFreqDr),"^",1),1:"")
	i $ZCVT(PHFreqCode,"U")="PRN" Q 1
	Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.19
/// Description:  判断是否此医嘱的执行记录是否已执行过收费
/// Table:        OEC_OrderPriority
/// Input:        PriorRowId:医嘱类型指针
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).Executed("1") 
ClassMethod Executed(OrdItmRowId As %String) As %String
{
	&SQL(Select count(*) into :execsum from SQLUser.OE_OrdExec 
		  Where OEORE_OEORI_PARREF=:OrdItmRowId and 
				(OEORE_Order_Status_DR->STAT_Code='F' or OEORE_Billed='P') )
	if execsum>0 {
		Quit 1
	}
	Q 0
}

/// creator:	郭荣勇
/// date:		2015-11-24
/// desc:		判断就诊在某日期和时间之后是否有已经执行的执行记录
/// Table:      OE_OrdItem,OE_OrdExec
/// Input:      OEORIRowId:执行记录指针
/// Return: 
/// OutPut:	
/// w ##class(appcom.OEOrdItem).CheckIsExistExecByDateT("285||49","2018-11-07","15:00")
ClassMethod CheckIsExistExecByDateT(OEORIRowId As %String, CheckDate As %String, CheckTime As %String) As %String
{
	s ret=1,stopMsg="",firstExecId=""
	Q:(OEORIRowId="")||(CheckDate="") ret_"^"_stopMsg_"^"_firstExecId
	s EpisodeID=$P(^OEORD(+OEORIRowId),"^",1)
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s oeori=$p(OEORIRowId,"||",1)
	s oeorisub=$p(OEORIRowId,"||",2)
	s ArcimRowid=$P($G(^OEORD(oeori,"I",oeorisub,1)),"^",2)
	s ItemCatDR=$p(^ARCIM(+ArcimRowid,$p(ArcimRowid,"||",2),1),"^",10)
	s OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
	//当天执行记录强制停止子类,不进行是否执行的判断
	s itemrowid=$p($g(^OEORD(+oeori,"I",oeorisub,1)),"^",2)
	s ItemCatRowId=+$p($g(^ARCIM(+$g(itemrowid),1,1)),"^",10)
	s StopAllExecItemCat=..%GetConfig("StopAllExecItemCat",AdmHospDr) //$g(^DHCDocConfig("StopAllExecItemCat"))
	s StopAllExecFlag=0
	i ("^"_StopAllExecItemCat_"^")[("^"_ItemCatRowId_"^") s StopAllExecFlag=1
	Q:StopAllExecFlag=1 ret_"^"_stopMsg_"^"_firstExecId
	i $l(CheckDate,"/")=3 s CheckDate = $zdh(CheckDate,4)
	i $l(CheckDate,"-")=3 s CheckDate = $zdh(CheckDate,3)
	i CheckTime[":" s CheckTime=..%ZTH(CheckTime)
	s StopExecByExecTime=..%GetConfig("StopExecByExecTime",AdmHospDr)	;增加配置:停医嘱时按照要求执行时间判断是否可停止
	;ExpectEndDate之后有执行记录已执行，不允许停止
	s maxExDate = $o(^OEORDi(0,"OrdItem",oeori,oeorisub,""),-1)
	for tmpdate = CheckDate:1:maxExDate {
		set xSub=0 
		for  {
			set xSub = $o(^OEORDi(0,"OrdItem",oeori,oeorisub,tmpdate,xSub)) 
			Quit:xSub=""
			s ExecId=oeori_"||"_oeorisub_"||"_xSub
			s str = $g(^OEORD(oeori,"I",oeorisub,"X",xSub))
			s ExecStateDR = $p(str,"^",16)
			continue:ExecStateDR=""
			s ExecStateCode = $p(^OEC("STAT",ExecStateDR),"^",1)
			continue:ExecStateCode'="F"
			if StopExecByExecTime=1{
				s CompareDate=$P(^OEORD(oeori,"I",oeorisub,"X",xSub),"^",19)
				s CompareTime=$P(^OEORD(oeori,"I",oeorisub,"X",xSub),"^",20)
			}else{
				s CompareDate=$P(^OEORD(oeori,"I",oeorisub,"X",xSub),"^",1)
				s CompareTime=$P(^OEORD(oeori,"I",oeorisub,"X",xSub),"^",2)
			}
			if (CompareDate>CheckDate)||((CompareDate=CheckDate)&&(CompareTime>CheckTime)){
				set ret=0,stopMsg="-15305",firstExecId=ExecId
			}elseif ##class(PHA.FACE.OUT.Method).IsOeoreDrawing(ExecId)=1{
				s ret=0,stopMsg="-15309",firstExecId=ExecId
			}
			Quit:ret=0
		}
		Quit:ret=0
	}
	Q ret_"^"_stopMsg_"^"_firstExecId
}

/// 已经弃用 走医生站设置目录-停医嘱设置-护士操作医生权限
/// Creator:      周志强
/// CreatDate:    2012.03.19
/// Description:  判断是否此医嘱是否可以单独停止医生开出的非医嘱单医嘱,护士可以停止护士开出的子医嘱
/// Table:        OEC_OrderPriority
/// Input:        OrderItemRowId:医嘱指针,UserRowId:登录用户指针
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).CheckSingleStop("38||2","127") 
ClassMethod CheckSingleStop(OrderItemRowId As %String, UserRowId As %String, OperateType As %String) As %Boolean
{
	s EpisodeID=$P(^OEORD(+OrderItemRowId),"^",1)
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s OEOrdPrintSetDefHospId=##class(DHCDoc.Common.Hospital).GetDefHospIdByTableName("Nur_IP_DHCOEOrdPrintSet",AdmHospDr)
	
	s DoctorDr=$P(^SSU("SSUSR",UserRowId),"^",14)	
	Q:DoctorDr="" 0
	
	s CTPCPCarPrvTpDR = $p(^CTPCP(DoctorDr,1),"^",4)
	s CTCPTInternalType = $p(^CT("CPT",CTPCPCarPrvTpDR),"^",4)
	
	s NurseLinkOrderRowId=$p($g(^OEORD(+OrderItemRowId,"I",$p(OrderItemRowId,"||",2),"DHC")),"^",54)
	i (+NurseLinkOrderRowId'="0")&&(CTCPTInternalType="NURSE") { 
	  ;长期医嘱补录的临时护嘱,可单独取消/作废
	  Q 1
	}
	;批量补录的子医嘱可单独取消/作废
	s OEORINurseBatchAdd=$p($g(^OEORD(+OrderItemRowId,"I",$p(OrderItemRowId,"||",2),"DHC")),"^",60)
	if (OEORINurseBatchAdd="Y") {
		Q 1
	}
	s OrdLinkRowId=$p($g(^OEORD(+OrderItemRowId,"I",$p(OrderItemRowId,"||",2),11)),"^",39)
	if OrdLinkRowId="" Q 0
	
	s MasterDoctorDr=$P($G(^OEORD(+OrdLinkRowId,"I",$P(OrdLinkRowId,"||",2),1)),"^",11)	
	Q:MasterDoctorDr="" 0
	
	s CTPCPCarPrvTpDR = $p(^CTPCP(MasterDoctorDr,1),"^",4)
	s MasterCTCPTInternalType = $p(^CT("CPT",CTPCPCarPrvTpDR),"^",4)
	;拿下医嘱医护人员的类型 ;
	Set OrdInternalType=""
	Set OrdDoctorDr = $p(^OEORD(+OrderItemRowId,"I",$p(OrderItemRowId,"||",2),1),"^",11)
	if OrdDoctorDr {
		Set OrdCTPCPCarPrvTpDR = $p(^CTPCP(OrdDoctorDr,1),"^",4)
		If OrdCTPCPCarPrvTpDR>0 {
			Set OrdInternalType = $p(^CT("CPT",OrdCTPCPCarPrvTpDR),"^",4)
		}
	}
	//如果是护士录入绑定的子医嘱，护士停止时需停止整组医嘱
	s OrdBindSource=$p($g(^OEORD(+OrderItemRowId,"I",$p(OrderItemRowId,"||",2),"DHC")),"^",41)
	if (OrdBindSource'="")&&(MasterCTCPTInternalType="NURSE") Q 0
	//草药的煎药费可以单独停止
	if ((OrdBindSource="CMPTAM")||(OrdBindSource="CMCMAO")||(OrdBindSource="CMPTCMA")||(OrdBindSource="CMPTAOF"))  Q 1
    if (MasterCTCPTInternalType="DOCTOR")&&(CTCPTInternalType="NURSE"){
	    if (OrdInternalType="NURSE") Q 1
	    s DefOEOrdPrintSetHospId=##class(web.DHCDocMain).GetDefOEOrdPrintSetHospId(EpisodeID)
		s ItmMastDR = $p($g(^OEORD(+OrderItemRowId,"I",$p(OrderItemRowId,"||",2),1)),"^",2)
		s mastItemCat = $p(^ARCIM(+ItmMastDR,$p(ItmMastDR,"||",2),1),"^",10)					
		s arcicOrdCatDR = $p(^ARC("IC",mastItemCat),"^",8)
		s OperatAuthResult=##class(DHCDoc.DHCDocConfig.StopConfig).CheckOperatAuth(OrderItemRowId,OperateType,"")
		if (+OperatAuthResult=1){
			q 1
		}
		/*		
		//应先判断大类
		s NotOrdCat=##class(Nur.NIS.Service.OrderSheet.Sheet).getShieldSetting(DefOEOrdPrintSetHospId, 0)	;护士站配置 大类
		if ("^"_NotOrdCat_"^")[("^"_arcicOrdCatDR_"^") q 1
		s NotSordCat=##class(Nur.NIS.Service.OrderSheet.Sheet).getShieldSetting(DefOEOrdPrintSetHospId, 1)	;护士站配置 子类
		if ("^"_NotSordCat_"^")[("^"_mastItemCat_"^") q 1
		*/
    }
    // 2019-07-19 若是护士开立的关联医嘱则同时取消/作废
    if (MasterCTCPTInternalType="NURSE")&&(CTCPTInternalType="NURSE") q 0
    Q 0
}

/// Creator:      周志强
/// CreatDate:    2012.03.19
/// Description:  判断是否此医嘱是否可以停止
/// Table:        OEC_OrderPriority
/// Input:        OrderItemRowId:医嘱指针,UserRowId:登录用户指针,LocID:登录科室,GroupID:登录安全组
/// Return: 
/// OutPut:		  1:是,0:否
/// Others:       w ##class(appcom.OEOrdItem).CheckStopPermission("1") 
ClassMethod CheckStopPermission(OrderItemRowId As %String, UserRowId As %String, LocID As %String, GroupID As %String = "") As %String
{
	s ^TEMP("Debug","CheckStopPermission")="w ##class(appcom.OEOrdItem).CheckStopPermission("""_OrderItemRowId_""","""_UserRowId_""","""_LocID_""","""_GroupID_""")"

	s EpisodeID=$P(^OEORD(+OrderItemRowId),"^",1)
	s AdmHospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s OEOrdPrintSetDefHospId=##class(DHCDoc.Common.Hospital).GetDefHospIdByTableName("Nur_IP_DHCOEOrdPrintSet",AdmHospDr)
	;s AddUserRowId=$P($G(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),7)),"^",1)
	;s DoctorDr=$P(^SSU("SSUSR",AddUserRowId),"^",14)
	;Q:DoctorDr="" 0
	s DoctorDr=$P($G(^OEORD(+OrderItemRowId,"I",$P(OrderItemRowId,"||",2),1)),"^",11)	
	Q:DoctorDr="" 1
	
	if $d(^RB("RES",0,"CTPCP",DoctorDr,LocID)) s ret=1 q ret
	s ret=0,isNurse=0
	s ctpcprowid=$P(^SSU("SSUSR",UserRowId),"^",14)
	s CTPCPCarPrvTpDR = $p(^CTPCP(ctpcprowid,1),"^",4)
	s CTCPTInternalType = $p(^CT("CPT",CTPCPCarPrvTpDR),"^",4)
	s:CTCPTInternalType="NURSE" isNurse=1
	s oeori = ++OrderItemRowId
	s oeorisub = $P(OrderItemRowId,"||",2)
	
	if isNurse=1 d
	.;if $d(^RB("RES",0,"CTPCP",DoctorDr,LocID)) s ret=1 q
	.;else  d
	.;护士可以单独停医生开出的绑定其他医嘱的非医嘱单医嘱
	.s currLocId=","_LocID_","
	.s id=0 f  s id=$o(^CTLOC(id)) q:id=""  d
	..i $d(^CTLOC(id,"LINK",0,"Loc",LocID))=10 s currLocId=currLocId_id_","
	.s ordDept = $p($g(^OEORD(oeori,"I",oeorisub,7)),"^",2)	;OEORI_UserDepartment_DR
	.q:currLocId'[ordDept		;转科医嘱不能停
	.q:'$d(^OEORD(oeori,"I",oeorisub,11))
	.s oriOriDr=$p(^OEORD(oeori,"I",oeorisub,11),"^",39)
	.q:oriOriDr=""				;非子嘱不能停
	.s str1 = ^OEORD(oeori,"I",oeorisub,1)
	.s ItmMastDR = $p(str1,"^",2)
	.s mastItemCat = $p(^ARCIM(+ItmMastDR,$p(ItmMastDR,"||",2),1),"^",10)			;护士站配置 子类		
	.s:$g(^DHCOEOrdPrintSet("NotSordCat",OEOrdPrintSetDefHospId))[("^"_mastItemCat_"^") ret=1	q
	.s arcicOrdCatDR = $p(^ARC("IC",mastItemCat),"^",8)								;护士站配置 大类
	.s:$g(^DHCOEOrdPrintSet("NotOrdCat",OEOrdPrintSetDefHospId))[("^"_arcicOrdCatDR_"^") ret=1 q

	q ret
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  插入多条医嘱处理
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        Adm:就诊指针,OrdItemStr:医嘱信息串,User:用户指针,Loc:录入科室,Doc:医嘱所属医护人员
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).InsertMulti() 
/// 				  OrdItemStr描述:
/// 				医嘱项指针 ^医嘱项类型^ 医嘱类型指针 ^ 开始日期 ^ 开始时间 ^整包装数^自定义价格^ 接收科室指针
/// 				费别指针^剂型指针^备注^ 剂量 ^ 剂量单位指针 ^总剂量^ 频次指针 ^疗程指针^用法指针^处方类型^主医嘱序号^ 医嘱序号
/// 				皮试标志^草药用法^医保内标志^皮试液类型^医嘱套指针^结束日期^结束时间^执行日期串^紧急标志
/// 				诊断分类指针^长嘱首日次数^症状^输液流速^麻醉申请单ID^检验号^ 关联医嘱指针 ^营养药标志^材料条码
/// 				临床路径项目指针^医保审批类型
ClassMethod InsertMulti(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String, Doc As %String) As %Status
{
	s ^TEMP("Debug","InsertMultiple1")="w $$InsertMultiple^DHCDocOrderCommonNew("_Adm_","""_OrdItemStr_""","_User_","_Loc_","_Doc_",""LABDATA"")"

	Set Config=##Class(websys.Configuration).%OpenId(1)
	Set MEDDATA=Config.DataNamespace
	Set LABDATA=Config.LabDataNamespace
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	if PAADMType="I" {
		Set Ret=$$InsertMultiple^DHCDocOrderCommonNew(Adm,OrdItemStr,User,Loc,Doc,LABDATA)
	}else{
		Set CurrentNS=$ZNSPACE
		ZN MEDDATA		
		Set Ret=$$InsertMultiple^DHCDocOrderCommon(Adm,OrdItemStr,User,Loc,Doc,LABDATA)
		ZN CurrentNS
	}
	
	s $ZT="BIllERROR"
	If (Ret'=0)&&(Ret'=100){
		//如果设置了押金控制,需要做帐单
        d ##class(web.DHCOEOrdItem).InvokeBill(Adm,User,Ret)
		//插入医嘱时自动插入临床路径实施记录
		Do ##class(web.DHCCPW.MR.Interface).InsertDHCCPWImp(Adm,Ret,User,Doc)
	}
	
	///调用RIS接口, 把医嘱信息发送给RIS  add by gongping 2010-12-28
	///s ret=##class(RISService.InvokeRISService).SendIPOrditemInfoToRIS(Ret)
	
	///调用平台接口，把医嘱信息插入平台医嘱中间表 yiwenjun 2012-02-15
	///d ##class(DHCENS.NURSE.SOAPSfInfoService).GetOrderRowId(Ret)

	QUIT Ret
BIllERROR
	Quit -1_"^"_Ret
}

/// Creator:      周志强
/// CreatDate:    2012.03.06
/// Description:  插入单条条医嘱处理
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        par:医嘱主表执行,udf:验证参数,PLIST:医嘱信息数组,同User.OEOrdItem的字段ColumnNumber
/// Return: 
/// OutPut:		  0:成功
/// Others:       w ##class(appcom.OEOrdItem).Insert() 
ClassMethod Insert(par As %String, udf As %String, ByRef PLIST) As %String
{
	;call UDF for validation
	s udf=$g(udf)
	s udf1=$p(udf,"^"),udf2=$p(udf,"^",2),ExecuteDateStr=$p(udf,"^",3),OrderNeedPIVAFlag=$p(udf,"^",4)
	s udf=udf1
	s PLIST(0)=par
	i udf["Y" s err=$$valid^MVBSSVAL("PreUpdate Check","ORDER","Add","")
	i udf["Y",err q err

	;adjust unit cost
	i '$g(PLIST(46)) s PLIST(46)=""
	;f jj=1:1:$g(PLIST) i $g(PLIST(jj))="" k PLIST(jj)
	s par=$g(par) 
	;n rowid,itemcat,calc,calcfl,phartype
	k PLIST(1),PLIST(2) s PLIST(0)=par
	;k PLIST(28),
	k PLIST(81),PLIST(84),PLIST(90),PLIST(76),PLIST(135)
	s calcfl=$$calcfl^DHCOEOrdItem($g(PLIST(4)))
	s phartype=$$phartype^DHCOEOrdItem($g(PLIST(4)))
	i calcfl["Y",phartype'["X" s:'$g(PLIST(85)) PLIST(85)=1 s PLIST(29)=$$CO29^at122($g(PLIST(85)),$g(PLIST(25)),$g(PLIST(35)),$g(PLIST(23)),$g(PLIST(17)),$g(PLIST(159))) ;k PLIST(29)
	i calcfl["Y",phartype["X" s PLIST(29)=$$CO29^at122(1,$g(PLIST(112)),$g(PLIST(113)),$g(PLIST(23)))
	i calcfl'["Y" s PLIST(29)=+$g(PLIST(29)) s:'PLIST(29) PLIST(29)=1
	s PLIST(76)=$$DEF76^DHCOEOrdItem($g(PLIST(0)),$g(PLIST(4)))
	s:PLIST(76)="Ignore" PLIST(76)="I"
	s:PLIST(76)="To Bill" PLIST(76)="TB"
	s CFEntryOrdBillPad=##class(web.PilotProject.DHCDocPPGroupSeting).GetConfigNode("EntryOrdBillPad")
	s tmpAdm=$p(^OEORD(par),"^",1)
	s AdmType=$p(^PAADM(tmpAdm),"^",2)
	if ($g(PLIST("DHC",12))'="")&&(CFEntryOrdBillPad="1"){
		if AdmType'="I" {
			s PLIST(76)="P"
		}else{
			s PLIST(76)="B"
		}
	}
	;if discontinued order then ignore 
	i $p($g(^OEC("OSTAT",+$g(PLIST(10)))),"^")="D" s PLIST(76)="I"
	i $p($g(^OEC("OSTAT",+$g(PLIST(10)))),"^")="DI" s PLIST(76)="I"
	;if executed  order then "TB"
	i $p($g(^OEC("OSTAT",+$g(PLIST(10)))),"^")="E" s PLIST(76)="TB"
	;if priority PRN then Ignore
	i $$admtype^DHCOEOrdItem(par)["I",$p($g(^OECPR(+$g(PLIST(23)))),"^")="PRN" s PLIST(76)="I"
	i $g(PLIST(111))="" s PLIST(111)="A"
	;if result status N, status should be executed
	i PLIST(111)="N" s PLIST(10)=$o(^OEC("OSTAT",0,"Code","E",""))
	;default value for field 54-insur billing conditions
	s:'$g(PLIST(54)) PLIST(54)=$$def1^DHCOEOrdItem(+$g(^OEORD(+par)),$g(PLIST(4)),$g(PLIST(17)))
	;i $d(PLIST) ;m ^zleon=PLIST
	;get default operation category
	s PLIST(64)=$$opercat^DHCOEOrdItem($g(PLIST(4)))
	i '$g(PLIST(161)) s PLIST(161)=$$admloc^DHCOEOrdItem(par)
	;clear user_read and assistant_dr fields
	;s PLIST(153)=""
	;s PLIST(157)=""
	;
	d pre
	;
	; piece 77 is the sequence number, sometimes in the vb stuff
	; this gets set to a string value e.g. 08 which then fails
	; validation. This next line ensures this doesn't happen.
	;s PLIST(77)=+$g(PLIST(77))
	i $g(PLIST(77))="" s PLIST(77)=0,err=$$seq^DHCOEOrdItem($g(PLIST(120)),"Cache")
	;fix some number fields
	;
	; they sometimes put in some strange data into these fields
	; so they should be converted to numeric, but only if they
	; exist otherwise it always puts a zero in the database for
	; every order which is wrong
	i $g(PLIST(59))'="" s PLIST(59)=+PLIST(59)
	i $g(PLIST(74))'="" s PLIST(74)=+PLIST(74)
	
	;获取病人当前出院状态,调用护理组接口
 	s CurrentDischargeStatus=##class(web.DHCDischargeHistory).GetCurrentDischargeStatus($p(^OEORD(par),"^",1))
 	;获取出院日期和时间
 	s DischargeDate="",DischargeTime=""
 	i CurrentDischargeStatus="B" {
		s DischargeDateTime=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.GetDischargeDateTime",$p(^OEORD(par),"^",1))
		s DischargeDate=$p(DischargeDateTime,"^",1)
		s DischargeTime=$p(DischargeDateTime,"^",2)
		if (DischargeDate'="")&&(((PLIST(17)=DischargeDate)&&(PLIST(18)>(DischargeTime-1)))||(PLIST(17)>DischargeDate)) {
			Set PLIST(17)=DischargeDate
			if (DischargeTime'="") {
				Set PLIST(18)=DischargeTime-1
			} 
		}
		if ($g(PLIST(81))="") {
			Set PLIST(81)=DischargeDate
			Set PLIST(90)=DischargeTime-1
		}
		s PLIST("DHC",127)=CurrentDischargeStatus
 	}
	;固定存储被调用堆栈记录OEORI_Comment3
	s PLIST(322)=$$getStack()
	;医嘱处理类型,默认为未处理U
	i $g(PLIST("DHC",69))="" s PLIST("DHC",69)="U"
	s LocHospDr=$p($g(^CTLOC(PLIST(121))),"^",22)
	s OrderDHCAADr=$g(PLIST("DHC",114))
	k PLISTExt
	m PLISTExt=PLIST("DHC")
	KILL PLIST("DHC")
	;
	;s $ZT="ERROR^SSERR"
	s $ZT="ERROR"
	s rowid=""
	TS
	&sql( INSERT INTO SQLUser.OE_OrdItem VALUES :PLIST())
	s SQLflag=SQLCODE
	i 'SQLflag {
		s rowid=$p(%ROWID,$c(1))
		&sql(UPDATE SQLUser.OE_OrdItemExt VALUES :PLISTExt() WHERE OEORI_RowId=:rowid)
		if (SQLCODE'=0){
			TRO
			///部分项目反映子表插入失败
			s count=$o(^DHCSYSERROR($ZN,+$h,""),-1)+1
			s ^DHCSYSERROR($ZN,+$h, count)="100^<ERROR>"_rowid_"---"_$ZERROR_"  "_$H_" "_$G(%msg)
			m ^DHCSYSERROR($ZN,+$h, count,"PLISTExt")=PLISTExt
			q "-101^"_rowid
		}else {
			///插入同频次不同剂量扩展表
			d ##class(web.DHCOEOrdItemDoseQty).InsertDoseQty(rowid)
		}
	}
	//保存处方信息
	d ##Class(web.DHCDocPrescript).CreatPAQue(rowid)
	if $G(OrderDHCAADr)'=""{
		;医嘱审核成功后将医嘱ID更新至治疗申请单
		d ##class(DHCDoc.DHCDocCure.ApplyTree).CureApplyRelateOrder(OrderDHCAADr,rowid)
	}
	TC
	;B ;1111
	;m ^tmpPLIST(%ROWID)=PLIST
	;m ^tmpPLISTExt(%ROWID)=PLISTExt
	
	; Now retrieve everything back to return to client
	; %ROWID is returned from INSERT
	
	i 'SQLflag { 
		s GenSttDate=$p($G(^OEORD(+rowid,"I",$p(rowid,"||",2),1)),"^",9)
		s GenEndDate=GenSttDate
		if ##class(appcom.OEOrdItem).ISLongOrderPrior(+$g(PLIST(23))) {
			s LinkOrdItemID=$p($G(^OEORD(+rowid,"I",$p(rowid,"||",2),11)),"^",39)
			i LinkOrdItemID="" d
			.s OrderType=##class(DHCDoc.Order.Common).GetOrdItemType(rowid)
			.s ItemCatRowid=##class(DHCDoc.Order.Common).GetOrdSubCat(rowid)
			e  d
			.s OrderType=##class(DHCDoc.Order.Common).GetOrdItemType(LinkOrdItemID)
			.s ItemCatRowid=##class(DHCDoc.Order.Common).GetOrdSubCat(LinkOrdItemID)
			;生成第二天执行记录的非药品子类
			s AutoGenNextExecCatStr="^"_##class(web.DHCDocConfig).GetConfigNode("AutoGenNextExecCat",LocHospDr)_"^"
			s GenEndDate=$SELECT(GenSttDate<=+$H:+$H,1:GenSttDate)
			if ((OrderType="R")||(AutoGenNextExecCatStr[("^"_ItemCatRowid_"^")))&&(GenEndDate<=+$H){	
				s GenEndDate=GenEndDate+1
			}
		}
		for GenDate=GenSttDate:1:GenEndDate{
			d ##class(DHCDoc.Order.Exec).Generate(rowid,GenDate)
		}
	}
	;insert over
	Quit SQLflag_"^"_rowid
ERROR 
	S VALUE=$ZE
	;
	TROLLBACK
	;
	s myDate=..%SysDate()
	s count=$o(^DHCSYSERROR($ZN,myDate,""),-1)+1
	s ^DHCSYSERROR($ZN,myDate, count)="100^<ERROR>"_VALUE_"---"_$ZERROR_"  "_$H
	; Force the error to show in VB still
	q "100^<ERROR>"_VALUE
pre ;
	;将字符串转换为List类型
	f ind=42,53 d
	.k TEMP
	.S CNT=$L($g(PLIST(ind)),"|")
	.F J=1:1:CNT S $LIST(TEMP,J)=$P($g(PLIST(ind)),"|",J)
	.S PLIST(ind)=TEMP
	.;F J=1:1:CNT S TEMP(J)=$P($g(PLIST(ind)),"|",J)
	.;K PLIST(ind) M PLIST(ind)=TEMP S PLIST(ind)=$O(PLIST(ind,""),-1)
	q
getStack()
	;add by gry V8.4
	s PLACE="",MCODE=""
	kill tmpStackAry
	s levelDeep=$STACK(-1)
	FOR loop=0:1:levelDeep { 
		s tp=$STACK(loop)
		continue:(tp="")||(tp="XECUTE")
		s cp=$STACK(loop,"PLACE")
		continue:(cp="")||(cp["%SYS")||(cp["%CSP")
		s stackCls=$p($p(cp,"^",2)," ",1)
		continue:$p($p(cp,"^",2)," ",1)=$zn
		;s cs=$STACK(loop,"MCODE")
		i stackCls'="" {
			continue:$d(tmpStackAry(stackCls))
			s tmpStackAry(stackCls)=""
		}
		;调用的标准插医嘱程序,则后续不记录
		s stackMthName=$p(cp,"+",1)
		i ((stackMthName="zInsertOrderItem")||(stackMthName="zSaveOrderItems"))&&(cp["web.DHCOEOrdItem") {
			s cp="标准"_stackMthName
			i PLACE="" s PLACE=$tr(cp,"^",",")
			e  s PLACE=PLACE_"!!"_$tr(cp,"^",",")
			quit
		}else{
			i PLACE="" s PLACE=$tr(cp,"^",",")
			e  s PLACE=PLACE_"!!"_$tr(cp,"^",",")
		}
		;s ^tmpgry("stack",+$h,$i(^tmpgry))=tp_","_cp ;_","_cs
    }
    ;只获取600长度的堆栈信息
    s PlaceLen=$l(PLACE)
    i PlaceLen>600 s PLACE=$e(PLACE,1,600)
	q PLACE
}

/// Creator:      周志强
/// CreatDate:    2012.05.31
/// Description:  根据传入的医嘱指针串产生合并标本号,用于护士重新并管用
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItemList:医嘱指针串,以”^"分割
/// Return: 
/// OutPut:		  医嘱指针!标本号
/// Others:       w ##class(appcom.OEOrdItem).GenLabEpisodeNo() 
ClassMethod GenLabEpisodeNo(OrdItemList As %String) As %String
{
	s ret=""
	s count=0
	Set rset=##class(%ResultSet).%New("web.DHCLISEpisode:GenerateEpisode")
	do rset.Execute(OrdItemList,"L")
	Set columns = rset.GetColumnCount()
	While (rset.Next()) {
		s OrdItemId=rset.GetDataByName("OrdItemId")
		s Flag=rset.GetDataByName("Flag")
		s LabEpisodeNo=rset.GetDataByName("EpisodeNo")
		continue:Flag'=0
		s obj=##class(User.OEOrdItem).%OpenId(OrdItemId)
		if $IsObject(obj) {
			s obj.OEORILabEpisodeNo=LabEpisodeNo
			d obj.%Save()
			d obj.%Close()
			s obj=""
			s count=count+1
			s single=OrdItemId_"!"_LabEpisodeNo
			if count=1 s ret=single
			e  s ret=ret_"^"_single
		}
	}
	d rset.Close()

	Q ret
}

/// Creator:      周志强
/// CreatDate:    2012.11.26
/// Description:  用于将门诊医嘱的执行记录,按医嘱计费模式转为按住院执行计费的模式,便于住院计入门诊发生的费用
/// 				  只处理医嘱相关第一条的执行记录和配药记录
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱表指针
/// Return: 
/// OutPut:		  0:成功 100:失败
/// Others:       w ##class(appcom.OEOrdItem).MigrateOPExec("88||5") 
ClassMethod MigrateOPExec(OrdItmRowId As %String) As %String
{
	s child=$O(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",0))
	if (child="") {
		s Date=$p(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),1),"^",9)
		s Time=$p(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),1),"^",10)
		s:'Time Time=..%SysTime()
		s ExecQty=+$p(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),1),"^",12) ;OEORI_PhQtyOrd
		s AdminQty=$$calcbillqty^DHCOEOrdExec(OrdItmRowId)
		;因为调用的住院产生执行记录的方法会自动插入执行和配药记录(门急诊,有整包装数的不会再插入打包记录)
		/*
		s ret=0
		s DSPRowId=0 for  {
			s DSPRowId=$O(^DHCOEDISQTY(0,"OEORI",OrdItmRowId,DSPRowId))
			Q:DSPRowId=""
			
			&SQL(Update SQLUser.DHC_OEDispensing Set DSP_TotalQty=0,DSP_Qty=0,DSP_ConfirmQty=0 Where DSP_RowId=:DSPRowId)
			if SQLCODE'=0 {
				Set ret=1
				Quit
			}
		}
		*/
		s ret=$$InsOEORE^DHCOEOrdExec(OrdItmRowId,Date,Time,ExecQty,"",AdminQty,1)
		Q ret
	}
	s OEORERowId=OrdItmRowId_"||"_child
	s PackQty=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),9)),"^",4)
	s PriceDate=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),9)),"^",15)    //OEORI_BillPriceDate
	s PriceTime=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),9)),"^",16)    //OEORI_BillPriceTime
	s ARCIMrow=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),1)),"^",2)
	s arcgrp=$p(^ARCIM(+ARCIMrow,$p(ARCIMrow,"||",2),1),"^",10)
 	s cattype=$p(^ARC("IC",arcgrp),"^",7)
	s AdminQty=$$getAdminQty^DHCOEOrdExec(OrdItmRowId)
	//2017-03-06 Lid 获取部分退费数量
	//s RefundQty=##class(web.UDHCJFBILL).GetApplyRefundQty(OrdItmRowId, "")
	//+2023-03-28 ZhYW 改为实际已退费数量
	s RefundQty=##class(BILL.Interface.Inside.Service).IGetOrdRefundQtyO(OrdItmRowId, "")
	s AdminQty=AdminQty-RefundQty
	
	s BillType=$p(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),11),"^",18)
	//s Billed=$p(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),3),"^",5)
	s Billed="TB"   //2019-07-26 ZhYW
	s ItemStatus=$p(^OEORD(+OEORERowId,"I",$P(OEORERowId,"||",2),1),"^",13)
	s err=0
	TS
	//主要是处理门诊静配关联的执行记录问题
	if (PackQty="")&&(cattype="R"){
		s AdminQty=$p($g(^OEORD(+OEORERowId,"I",+$p(OEORERowId,"||",2),"X",+$p(OEORERowId,"||",3))),"^",5)
		s AdminQty=AdminQty-RefundQty 
		if (AdminQty<0){
			s AdminQty=0
			s RefundQty=$ZABS(AdminQty-RefundQty)
		}
	}
	&SQL(Update SQLUser.OE_OrdExec Set OEORE_Billed=:Billed,OEORE_QtyAdmin=:AdminQty,OEORE_BillPriceDate=:PriceDate,OEORE_BillPriceTime=:PriceTime Where OEORE_RowId=:OEORERowId)
	s err=err+SQLCODE
	//OEORE_OrderStatus_DR=:ItemStatus,   //2019-07-26 ZhYW 不更新执行记录状态
	&SQL(Update SQLUser.OE_OrdExecExt Set OEORE_BillType=:BillType Where OEORE_RowId=:OEORERowId)
	s err=err+SQLCODE

	s DSPRowId=$O(^DHCOEDISQTY(0,"OEORI",OrdItmRowId,0))
	if (DSPRowId'=""){
		&SQL(Update SQLUser.DHC_OEDispensing Set DSP_OEORE_DR=:OEORERowId Where DSP_RowId=:DSPRowId)
		s err=err+SQLCODE
	}
	;如果有多条执行记录,则将除第一条以外的都将执行数量更新成0
	s childAfter=child
	for {
		s childAfter=$O(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),"X",childAfter)) q:childAfter=""
		s OEOREAfterRowId=OrdItmRowId_"||"_childAfter
		if (PackQty="")&&(cattype="R"){
			s AdminQty=$p($g(^OEORD(+OEOREAfterRowId,"I",+$p(OEOREAfterRowId,"||",2),"X",+$p(OEOREAfterRowId,"||",3))),"^",5)
			s AdminQty=AdminQty-RefundQty
			if (AdminQty<0){
				s AdminQty=0
				s RefundQty=$ZABS(AdminQty-RefundQty)
			}
		}else{
			s AdminQty=0
		}
		&SQL(Update SQLUser.OE_OrdExec Set OEORE_Billed=:Billed,OEORE_QtyAdmin=:AdminQty,OEORE_BillPriceDate=:PriceDate,OEORE_BillPriceTime=:PriceTime Where OEORE_RowId=:OEOREAfterRowId)
		s err=err+SQLCODE
		s DSPRowId=$O(^DHCOEDISQTY(0,"OEORI",OrdItmRowId,DSPRowId))
		if (DSPRowId'=""){
			&SQL(Update SQLUser.DHC_OEDispensing Set DSP_OEORE_DR=:OEOREAfterRowId Where DSP_RowId=:DSPRowId)
			s err=err+SQLCODE
		}
	}
	//剩余的找不到对照执行记录的打包表数据，统一绑定在第一条执行记录上
	for  {
		s DSPRowId=$O(^DHCOEDISQTY(0,"OEORI",OrdItmRowId,DSPRowId))
		Q:DSPRowId=""
		&SQL(Update SQLUser.DHC_OEDispensing Set DSP_OEORE_DR=:OEORERowId Where DSP_RowId=:DSPRowId)
		s err=err+SQLCODE
		
	}
	if err'=0 Tro  Quit 100
	
	TC
	Q 0
}

/// 退材料库存调用材料组接口(住院按执行,门诊按医嘱)
ClassMethod ReturnMaterial(oeid As %String, NameSp As %String = "") As %String
{
	s $zt="ReturnMaterialErr"
	s MaterialBarCode=$p($G(^OEORD(+oeid,"I",$p(oeid,"||",2),"DHC")),"^",14)
	Q ##class(web.DHCSTMHUI.PCHCOLLSM).Return(oeid,MaterialBarCode)
ReturnMaterialErr
	i $g(NameSp)'="" zn NameSp
	Q "-1"
}

/// 减材料库存调用材料组接口(住院按执行,门诊按医嘱)
/// 门诊会在medsrc下调用,所以使用第二个参数传入调用时的命名空间,以防报错不能正常切回原命名空间下
ClassMethod DispMaterial(oeid As %String, NameSp As %String = "") As %String
{
	s $zt="DispMaterialErr"
	;如果使用HRP接口进行物资管理,则屏蔽此处;否则可能会造成事务层级混乱,进而导致滚执行记录任务异常
	s OpenHRPList=##class(DHCDoc.Interface.Outside.HRPService).GetOpenHRPList(oeid)
	Q:(OpenHRPList.%Size()>0) 0
	s MaterialBarCode=$p($G(^OEORD(+oeid,"I",$p(oeid,"||",2),"DHC")),"^",14)
	Q ##class(web.DHCSTMHUI.PCHCOLLSM).Disp(oeid,MaterialBarCode,"ORDER") //web.DHCSTM.PCHCOLLSM
DispMaterialErr
	i $g(NameSp)'="" zn NameSp
	Q "-1"
}

// ##class(appcom.OEOrdItem).CancelDoctorDischarge(episodId)

ClassMethod CancelDoctorDischarge(OrdItmRowId As %String, UserRowId As %String) As %String
{
	s err=0
	q:(OrdItmRowId="")||(UserRowId="") err
	s adm=$p(^OEORD(+OrdItmRowId),"^",1)
	;判断是否是将当前就诊置出院状态的出院医嘱
	s DischgOrderId=$p($g(^PAADM(adm,"DHC")),"^",28)
	q:DischgOrderId'=OrdItmRowId err
	s HospID=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(adm)

	s ArcimRowId1=$p($G(^OEORD(+OrdItmRowId,"I",$P(OrdItmRowId,"||",2),1)),"^",2)
	s DischargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(ArcimRowId1,HospID)
	if (DischargeOrdFlag'=0) d
	.s err=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.CancelDoctorDischarge",adm,UserRowId)
	.d ##class(Nur.InService.Interface).orderCancelReleaseBed(adm, UserRowId)
	q err
}

ClassMethod CheckOrdIsDis(OrdList As %String) As %String
{
	s Adm=$P(^OEORD(+OrdList),"^",1)
	s HospID=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(Adm)
	s ret=0
    for i=1:1:$l(OrdList,"^") {
		set OrderItemStr=$p(OrdList,"^",i)
		set oeitm=$p(OrderItemStr,"!",1)
		if oeitm="" Continue
		s ArcimRowId=$p($G(^OEORD(+oeitm,"I",$P(oeitm,"||",2),1)),"^",2)
		s DischargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(ArcimRowId,HospID)
		i (DischargeOrdFlag=0) continue
		s ret=1
	}
	q ret
}

/// 停止或者作废医嘱的时候，判断是否需要刷新左侧的患者列表
/// retunr Y 刷新 N不刷新
ClassMethod RefresPatList(OrdList As %String) As %String
{
	s RefresArcimStr="12110||1"
	s ret="N"
    for i=1:1:$l(OrdList,"^") {
		set OrderItemStr=$p(OrdList,"^",i)
		set oeitm=$p(OrderItemStr,"!",1)
		if oeitm="" Continue
		s ArcimRowId=$p($G(^OEORD(+oeitm,"I",$P(oeitm,"||",2),1)),"^",2)
		i ("^"_RefresArcimStr_"^")'[("^"_ArcimRowId_"^") continue
		s ret="Y"
	}
	q ret
}

/// Description:TypeCode为空时为实习医师停止、作废、撤销医嘱；TypeCode为1时为上级医师审核
/// 
ClassMethod UpdateExtIfPractice(oeitm, UserRowID, StatusRowId As %String, ExpectEndDate As %String = "", TypeCode As %String = "", ExpectEndTime As %String = "", ReasonDr As %String = "", ReasonDesc As %String = "")
{
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	if TypeCode="1"{
		TS
		&SQL(Update SQLUser.OE_OrdItemExt set OEORI_PracticeConfirmStopDate=:CurrDate,OEORI_PracticeConfirmStopTime=:CurrTime,OEORI_PracticeConfirmStopUser_DR=:UserRowID where OEORI_rowid=:oeitm)	
		if 'SQLCODE {
			s Link=0
			for  {
				 s Link=$O(^OEORDi(0,"OEORI",+oeitm,oeitm,Link)) Q:Link="" 
				 s LikOrdID=+oeitm_"||"_Link
				 s SubStatusCode=..GetStatusCode(LikOrdID)
				 if (SubStatusCode'="I")&&(SubStatusCode'="V"){
					 &SQL(Update SQLUser.OE_OrdItemExt set OEORI_PracticeConfirmStopDate=:CurrDate,OEORI_PracticeConfirmStopTime=:CurrTime,OEORI_PracticeConfirmStopUser_DR=:UserRowID where OEORI_rowid=:LikOrdID)	
					 if SQLCODE Q
				 }
			}
		}
		if SQLCODE TRO
		else  TC
		Q SQLCODE
	}
	
	if UserRowID="" s UserRowID=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),7)),"^",1)
	s DoctorRowId=##class(web.SSUser).GetDefaultCareProvider(UserRowID)
	s practice=##class(web.DHCOEOrdItem).practice(DoctorRowId)
	if practice=1{
		if ($g(ExpectEndDate)'="")&&(ExpectEndDate>CurrDate){
			Q "-100042"	
		}
		TS
		&SQL(Update SQLUser.OE_OrdItemExt set OEORI_PracticeStopDate=:ExpectEndDate,OEORI_PracticeStopTime=:ExpectEndTime,OEORI_PracticeStopReason_DR=:ReasonDr,OEORI_PracticeStopReasonComtent=:ReasonDesc,OEORI_PracticeConfirmStopStatus=:StatusRowId,OEORI_PracticeStopUser_DR=:UserRowID where OEORI_rowid=:oeitm)
		if 'SQLCODE {
				s Link=0
				for  {
					s Link=$O(^OEORDi(0,"OEORI",+oeitm,oeitm,Link)) Q:Link="" 
					s LikOrdID=+oeitm_"||"_Link
					s SubStatusCode=..GetStatusCode(LikOrdID)
					if (SubStatusCode="V"){
						&SQL(Update SQLUser.OE_OrdItemExt set OEORI_PracticeStopDate=:ExpectEndDate,OEORI_PracticeStopTime=:ExpectEndTime,OEORI_PracticeStopReason_DR=:ReasonDr,OEORI_PracticeStopReasonComtent=:ReasonDesc,OEORI_PracticeConfirmStopStatus=:StatusRowId,OEORI_PracticeStopUser_DR=:UserRowID where OEORI_rowid=:LikOrdID)
						if SQLCODE Q
					}
				}
		}
		if SQLCODE{
			TRO
			Q "-100043"	
		}
		TC
		Q 0
	}	
	Q 100
}

/// Creator:      宋春莉
/// CreatDate:    2018.10.26
/// Description:  撤销预停
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针,PWFlag:是否密码验证,PinNum:明文密码
/// Return: 
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).StopMulti("531546||1",590,"") 
ClassMethod CancelPreStopMulti(OrdList As %String = "", UserID As %String = "", PinNum As %String, ExpStr As %String, PWFlag As %String = "Y", ByRef ErrMsg As %String = "")
{
	s ^TEMP("Debug","CancelPreStopMulti")="w ##class(appcom.OEOrdItem).CancelPreStopMulti("""_OrdList_""","""_UserID_""","""_PinNum_""","""_PWFlag_""")"
	s user=$p(ExpStr,"^",1)
	s locid=$p(ExpStr,"^",2)
	s groupid=$p(ExpStr,"^",3)
	;密码验证
	s err=0
 	if PWFlag="Y" s err=##Class(web.DHCOEOrdItem).PinNumberValid(UserID,PinNum)
	if (err'=0){
		s ErrMsg=..%GetErrCodeMsg("-100029")
		Q "-100029" //err
	}
 	;重新组织停医嘱串,根据配置停主医嘱
 	s StopGroupOrder=..%GetConfig("StopGroupOrder")
 	s OrdListStr=""
 	s Len=$l(OrdList,"^")
 	for i=1:1:Len {
		s OrderItemStr=$p(OrdList,"^",i)
		s oeitm=$p(OrderItemStr,"!",1)    //不能改医嘱ID为第一位的位置
		;不必从界面取的关联医嘱RowId   zhouzq 2010.07.21
		s OrdLinkRowId=$p($g(^OEORD(+oeitm,"I",$p(oeitm,"||",2),11)),"^",39)
		if (StopGroupOrder=1){
			;如果确认成组停止,子医嘱RowId不需要传了
			if (OrdLinkRowId'="") {
				s flag = ##class(web.DHCDocMain).CheckStopOrder(OrdLinkRowId,user,locid,groupid,"","")
				if (+flag'=1){
					continue
				}
				if (OrdListStr'[(OrdLinkRowId_"!")){
						s OrderItemStr=OrdLinkRowId
				}else{
					continue
				}
			}else{
				if (OrdListStr[(oeitm_"!")){
					continue
				}
			}
		}else{
			;如果已经选择了子医嘱,子医嘱RowId不需要传了
			if (OrdLinkRowId'="")&&(OrdListStr[(OrdLinkRowId_"!")) continue
		}
		if OrdListStr="" s OrdListStr=OrderItemStr
		else  s OrdListStr=OrdListStr_"^"_OrderItemStr
	}
	s adm=""
 	s err=0
 	s OrdList=OrdListStr
 	s len=$l(OrdList,"^")
	for i=1:1:len {
		s OrderItemStr=$p(OrdList,"^",i)
		s oeitm=$p(OrderItemStr,"!",1)
		s err=..CancelPreStop(oeitm,UserID,.ErrMsg)
		s adm=$p(^OEORD(+oeitm),"^",1)
	 }
	 Q:err'=0 err
	 q err
}

/// Creator:      宋春莉
/// CreatDate:    2018.10.26
/// Description:  撤销预停 修改预停时间为空
/// Table:        OE_OrdItem,OE_OrdExec
/// Input:        OrdItmRowId:医嘱Rowid,UserRowId:用户指针
/// Return: 	  0:成功
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).CancelPreStop("77078||44",127) 
ClassMethod CancelPreStop(OrdItmRowId As %String, UserRowId As %String, ByRef ErrMsg As %String = "") As %String
{
	set obj=##class(User.OEOrdItem).%OpenId(OrdItmRowId)
	if '$IsObject(obj) {
		s ErrMsg=..%GetErrCodeMsg("-100000")
		Quit "-100000"			   //-100 医嘱不存在
	}
	s err=0
	TS
	&SQL(Update SQLUser.OE_OrdItem Set OEORI_EndDate=null,OEORI_EndTime=null,OEORI_UserUpdate=:UserRowId where OEORI_Rowid=:OrdItmRowId)
	if SQLCODE Tro  Q SQLCODE
	s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
	While (Sub'="") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		;已经停止的医嘱不用再处理
		s SubStatusCode=..GetStatusCode(SubRowId) 
		if (SubStatusCode="D")||(SubStatusCode="C")||(SubStatusCode="U") {
			s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
			continue
		}
    	&SQL(Update SQLUser.OE_OrdItem Set OEORI_EndDate=null,OEORI_EndTime=null,OEORI_UserUpdate=:UserRowId where OEORI_Rowid=:SubRowId)
    	if SQLCODE {
			s err="-100002"      //-202 更新预停时间
			Quit
		}
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
	}
	i err {
		TRo  
		s ErrMsg=..%GetErrCodeMsg(err)
		Q err
	}
	TC
	Quit 0
}

ClassMethod CancelOrdDocInterface(OrdItmRowId As %String, UserRowId As %String, ByRef ErrMsg As %String = "") As %String
{
	s Adm=$P(^OEORD(+OrdItmRowId),"^",1)
	s PAADMType=$p($g(^PAADM(Adm)),"^",2)
	s OrdPriorityDR=$p(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),1),"^",8)
	s ISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(OrdPriorityDR)
	s OrderPrescNo=$P($G(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),1)),"^",14)
	if ((PAADMType="I")||(PAADMType="E")){
		//撤销医疗结算
		s err=..CancelDoctorDischarge(OrdItmRowId,UserRowId)
		if +err'=0 {
			s ErrMsg=..%GetErrCodeMsg("-100037")_err
			Q err
		}
	}
	;自动撤消治疗申请单
	s CureErrMsg=""
	s err=##class(DHCDoc.DHCDocCure.Service).CancelCureApplyByStopOrd(OrdItmRowId,UserRowId,.CureErrMsg)
	if +err'=0 {
		if CureErrMsg=""{
			s CureErrMsg=err	
		}
		s ErrMsg=..%GetErrCodeMsg("-100030")_CureErrMsg //##Class(web.DHCDocInPatPortalCommon).GetMsg(err)
		Q err
	}
	;自动撤销会诊申请
	s err=##Class(web.DHCEMConsInterface).CanCstNo(UserRowId,OrdItmRowId)
	i +err=100 s err=0
	if +err'=0 {
		s ErrMsg=..%GetErrCodeMsg("-100031")_$p(err,"^",2)
		Q "-911"
	}
	
	;自动撤销手术申请
	s err=##class(web.DHCANAdaptor).CancelOperByOeordId(OrdItmRowId)
	i +err=100 s err=0
	if +err'=0 {
		s ErrMsg=..%GetErrCodeMsg("-100032")_$p(err,"^",2)
		Q $P(err,"^",2)
	}
	;;药房追踪草药状态接口
	//if $d(^PHAPRESTRACKi("MOEORI",OrdItmRowId)) {
	if (##class(PHA.COM.Order).PrescCYQueId(OrderPrescNo)){
		s TrackLoc=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),7)),"^",2)
		d ##class(web.DHCINPHA.HMPresTrack.SqlDbPresTrack).HandlePresTrackDB(OrdItmRowId_"^"_""_"^"_""_"^"_"A2"_"^"_TrackLoc_"^"_UserRowId)
	}
	;撤销药师审核或接受药师审核结果(药房反馈不用了)
	;d ##class(PHA.FACE.OUT.Com).AcceptOnUnUseOrder(OrdItmRowId, UserRowId)

	;非药理子类的检验检查药理项目需要撤销免费
	s PPRowID=$p($G(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),"DHC")),"^",10)
	if (PPRowID'=""){
		s err=##class(web.PilotProject.DHCDocPilotProject).CancelPPAOrdFree(PPRowID,OrdItmRowId,UserRowId)
		if err  {
			s ErrMsg=..%GetErrCodeMsg("-100033")_err
			Q err
		}
	}
	;调用计费组接口撤销划扣
	;停止MDT会诊医嘱时，取消申请
	if (PAADMType'="I"){
		s err=##class(BILL.PKG.SRV.Interface).IDeductCancel(OrdItmRowId,UserRowId)
		if +err'=0  {
			s ErrMsg=..%GetErrCodeMsg("-100035")_err
			Q err
		}
		s err=##Class(web.DHCMDTInterface).CancelCsREQ(OrdItmRowId,UserRowId)
		if +err'=0  {
			s ErrMsg=..%GetErrCodeMsg("-100034")_err
			Q err
		}
	}
	;撤销皮试结果
	;是否皮试医嘱
	s ifSkin=##class(Nur.NIS.Service.Base.OrderHandle).ifSkinTestOrdNew(OrdItmRowId)
	if (ifSkin="Y")&&(ISLongOrderPrior=0) {
		//撤销皮试结果
		s err=..CancelSkinTestResult(OrdItmRowId)
		if +err'=0  {
			s ErrMsg=..%GetErrCodeMsg("-100036")
			//s ErrMsg="撤销皮试结果失败!"
			Q err
		}
	}
	;计费重复收费接口取消
	s StatusCode=##class(DHCDoc.Order.Common).GetOrdStatusCode(OrdItmRowId)
	s OperateType=$CASE(StatusCode,"D":"S",:StatusCode)
	s HospID=##class(DHCDoc.Common.Hospital).GetOrdItemHospitalId(OrdItmRowId)
	if PAADMType="I"{
		s ExecIDs=##class(web.DHCDocMain).GetStopOrdInfoForBill(OrdItmRowId, OperateType)
		for i=1:1:$L(ExecIDs,"^"){
			s ExecID=$P(ExecIDs,"^",i)
			continue:ExecID=""
			s err=##class(BILL.REPEATED.COM.Interface).CancelRepeatOrd("",ExecID,UserRowId,HospID)
			Q:err
		}
	}else{
		s err=##class(BILL.REPEATED.COM.Interface).CancelRepeatOrd(OrdItmRowId,"",UserRowId,HospID)
	}
	if (+err'=0) {
		s ErrMsg=..%GetErrCodeMsg("-100049")
		Q err
	}
	q 0
}

ClassMethod CancelSkinTestResult(oeoriId)
{
	s OEOrdItemObj=##class(User.OEOrdItem).%OpenId(oeoriId)
	s OEOrdItemObj.OEORIAbnormal=""
	d OEOrdItemObj.%Save()
	s Sub=0  f {
		s Sub=$O(^OEORD(+oeoriId,"I",$P(oeoriId,"||",2),"X",Sub))
		Q:Sub=""
		s OEOrdItemExecExtObj=##class(User.OEOrdExecExt).%OpenId(oeoriId_"||"_Sub)
		s OEOrdItemExecExtObj.OEORESkinTestCTCPDR=""
		s OEOrdItemExecExtObj.OEORESkinTestDate=""
		s OEOrdItemExecExtObj.OEORESkinTestTime=""
		s OEOrdItemExecExtObj.OEORESkinTestAuditCTCPDR=""
		s OEOrdItemExecExtObj.OEORESkinTestAuditDate=""
		s OEOrdItemExecExtObj.OEORESkinTestAuditTime=""
		s OEOrdItemExecExtObj.OEORESkinBatch=""
		d OEOrdItemExecExtObj.%Save()
	}
	q 0
}

ClassMethod GetCstRelOeori(OrdList As %String) As %String
{
	s Ord=+OrdList
	s EpisodeID=$P(^OEORD(Ord),"^",1)
	s AdmType=$p(^PAADM(EpisodeID),"^",2)
	if (AdmType="I"){
		s Seq="!"
	}else{
		s Seq="&"
	}
	s OrdListStr=""
	s len=$l(OrdList,"^")
	for i=1:1:len {
		s TotString=$p(OrdList,"^",i)
		s oeitm=$p(TotString,Seq,1)
		//多科会诊申请产生的其他申请医嘱串
		s CstRelOeoriStr=##Class(web.DHCEMConsInterface).GetCstRelOeori(oeitm)
		continue:CstRelOeoriStr=""
		for j=1:1:$l(CstRelOeoriStr,"^"){
			s oneCstRelOeori=$p(CstRelOeoriStr,"^",j)
			if ("^"_OrdList_"^")'[("^"_oneCstRelOeori_"^"){
				if (OrdListStr="") s OrdListStr=oneCstRelOeori
				else  s OrdListStr=OrdListStr_"^"_oneCstRelOeori
			}
		}
	}
	q OrdListStr
}

/// Description:撤销 实习医师停止、作废、撤销医嘱
/// 
ClassMethod CancleExtIfPractice(oeitm, UserRowID)
{
	s CurrDate=..%SysDate()
	s CurrTime=..%SysTime()
	if UserRowID="" s UserRowID=$p($g(^OEORD(+oeitm,"I",+$p(oeitm,"||",2),7)),"^",1)
	&SQL(Update SQLUser.OE_OrdItemExt set OEORI_PracticeConfirmStopStatus=NULL,OEORI_PracticeConfirmStopDate=NULL,OEORI_PracticeConfirmStopTime=NULL,OEORI_PracticeConfirmStopUser_DR=:UserRowID where OEORI_rowid=:oeitm)	
	b ;093232
	if 'SQLCODE {
		s Link=0
		for  {
			 s Link=$O(^OEORDi(0,"OEORI",+oeitm,oeitm,Link)) Q:Link="" 
			 s LikOrdID=+oeitm_"||"_Link
			 s SubStatusCode=..GetStatusCode(LikOrdID)
			 if (SubStatusCode="V"){
				 &SQL(Update SQLUser.OE_OrdItemExt set OEORI_PracticeConfirmStopDate=NULL,OEORI_PracticeConfirmStopStatus=NULL,OEORI_PracticeConfirmStopTime=NULL,OEORI_PracticeConfirmStopUser_DR=:UserRowID where OEORI_rowid=:LikOrdID)	
				 if SQLCODE Q
			 }
		}
	}
	Q SQLCODE
}

/// Creator:      郭荣勇
/// CreatDate:    2020.05.19
/// Description:  在满足可调整医嘱剂量的条件下,调整医嘱剂量,先停止医嘱再插入医嘱,返回新医嘱Rowid
/// Table:        OE_OrdItem,OE_OrdExec,DHC_OEDispensing,OE_OrdExecExt
/// Input:        OrdItmRowId:医嘱Rowid,DoseQty:修改剂量(原剂量单位下),Loc：登陆科室,UserRowId:用户指针
/// Return: 	  0:成功标识^该医嘱修改后新医嘱RowId^该医嘱子医嘱RowId!该医嘱子医嘱修改后新医嘱RowId,该医嘱子医嘱RowId!该医嘱子医嘱修改后新医嘱RowId
/// OutPut:		  Err:程序执行返回值代码,标识成功与否
/// Others:       w ##class(appcom.OEOrdItem).AdjustOrdDose("257||11",1,95,10209) 
ClassMethod AdjustOrdDose(OrdItmRowId As %String, DoseQty As %String, Loc As %String, UserRowId As %String) As %String
{
	s err=0
	s ord=$p(OrdItmRowId,"||",1)
	s chl=$p(OrdItmRowId,"||",2)
	s ArcimRowid=$p(^OEORD(ord,"I",chl,1),"^",2)
	s QtyPackUOM=$p(^OEORD(ord,"I",chl,9),"^",4)
	s PriorId=$p(^OEORD(ord,"I",chl,1),"^",8)
	
	;仅处理药品
	s OrderType=##class(web.DHCDocOrderCommon).GetOrderType(ArcimRowid)
	q:OrderType'="R" "-1^非药品不能处理"
	q:..Executed(OrdItmRowId) "-2^医嘱已经执行,不能处理"
	q:'##class(appcom.OEOrdItem).ISShortOrderPrior(PriorId) "-3^非临时医嘱,不能处理"
	
	TS
	;按原医嘱插入新医嘱,需在撤销原医嘱前,否则会复制出撤销医嘱的信息
	s MasterOrderRowid=$p($g(^OEORD(ord,"I",chl,11)),"^",39)
	s RtnStr=$$InsertOrd(MasterOrderRowid,OrdItmRowId,DoseQty,Loc,UserRowId)
	s err=$P(RtnStr,"^",1)
	s oeitm=$P(RtnStr,"^",2)
	i err {
		TRO
		Q "-202^插入新医嘱失败,错误代码:"_err
	}
	;如果插入的新医嘱是成组医嘱并且是主医嘱,则需同步插入子医嘱
	s newMasterOrdRowId=oeitm
	s subNewOeitmStr=""
	s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,0))
	While (Sub'="") {
		s SubRowId=+OrdItmRowId_"||"_Sub
		s SubDoseQty=$p(^OEORD(+OrdItmRowId,"I",Sub,2),"^",1)
		s subRtnStr=$$InsertOrd(newMasterOrdRowId,SubRowId,SubDoseQty,Loc,UserRowId)
		s err=$P(subRtnStr,"^",1)
		s subOeitm=$P(subRtnStr,"^",2)
		i err quit
		i subNewOeitmStr="" s subNewOeitmStr=SubRowId_"!"_subOeitm
		e  s subNewOeitmStr=subNewOeitmStr_","_SubRowId_"!"_subOeitm
		b ;11
		s Sub=$O(^OEORDi(0,"OEORI",+OrdItmRowId,OrdItmRowId,Sub))
	}
	i err {
		TRO
		Q "-203^插入新医嘱下的子医嘱失败,失败："_errCount_"条,对应原医嘱:"_SubRowId
	}
	
	;撤销原医嘱
	s err=..Cancel(OrdItmRowId,UserRowId)
	i err {
		TRO
		Q "-201^撤销原医嘱失败,错误代码:"_err
	}
	TC

	
	Quit 0_"^"_oeitm_"^"_subNewOeitmStr
	
InsertOrd(MasterOrderRowid,OrdItmRowId,DoseQty,Loc,UserRowId)
	s ord=+OrdItmRowId
	s chl=$p(OrdItmRowId,"||",2)
	
	s Adm=$p(^OEORD(ord),"^",1)
	s ARCIMRowid=$p(^OEORD(ord,"I",chl,1),"^",2)
	s QtyPackUOM=$p(^OEORD(ord,"I",chl,9),"^",4)
	s FreqRowid=$p(^OEORD(ord,"I",chl,2),"^",4)
	s PriorRowid=$p(^OEORD(ord,"I",chl,1),"^",8)
	s DurRowid=$p(^OEORD(ord,"I",chl,2),"^",6)
	s DoseUOMRowid=$p(^OEORD(ord,"I",chl,2),"^",3)
	
	Set admloc=$p(^PAADM(Adm),"^",4)
	s EpLoc=admloc
	s admType=$P($g(^PAADM(Adm)),"^",2)
	if admType="I" {
		;s EpLoc=$P($g(^PAADM(Adm)),"^",70)
		s EpLoc=$P(^PAWARD($P($g(^PAADM(Adm)),"^",70)),"^",5)
	}
	s OrderType=##class(web.DHCDocOrderCommon).GetOrderType(ARCIMRowid)
	Set OrderDocRowid=$p(^SSU("SSUSR",UserRowId),"^",14)
	Set StatusRowid=$o(^OEC("OSTAT",0,"Code","V",""))
	If StatusRowid="" Set StatusRowid=$o(^OEC("OSTAT",0))
	/*
	Set AdmReason=$p($g(^OEORD(ord,"I",chl,11)),"^",18)
	Set PilotPatAdmReason=$g(^DHCDocPilotSeting("PilotPatAdmReason"))
	Set PilotProRowId=$p($g(^OEORD(ord,"I",chl,"DHC")),"^",10)
	if (PilotProRowId'="")&&(PilotPatAdmReason'="") {
		s AdmReason=PilotPatAdmReason
	}
	Set InsuFlag=$$GetInsurFlag^DHCDocOrderCommonNew(AdmReason)
	i InsuFlag'=1,AdmReason="" Set AdmReason=$P(^PAADM(Adm,1),"^",7)
	*/
	s SttDate=$p(^OEORD(ord,"I",chl,1),"^",9)
	if $g(MasterOrderRowid)'="" {
		 s OrderSeqNo=$$GetSeqNoid^DHCDocOrderCommonNew(MasterOrderRowid)
	}else{
		Set OrderSeqNo=$o(^OEORDi(0,"StDtSeqNo",ord,SttDate,""),-1)
		Set OrderSeqNo=+OrderSeqNo+1
	}
	;得到基本单位总数量
	s DrgformRowid=##class(web.DHCDocOrderEntry).GetDrgForm(ARCIMRowid)
	i DrgformRowid'="" {
		s PHCDRowid=$P(DrgformRowid,"||",1)
		s ChildSub=$P(DrgformRowid,"||",2)
		s FormDoseQty=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,2)),"^",5) ;Pharmacy base UOM
		s FormDoseUOMRowid=$p($g(^PHCD(PHCDRowid,"DF",ChildSub,2)),"^",4)

		s DoseQtySum=##class(web.DHCDocOrderEntry).CalDose(FormDoseUOMRowid,DrgformRowid,+DoseQty)
		
		;获取整包装数量
		s PackQty=##class(web.DHCDocOrderEntry).GetPackqty(ARCIMRowid,DrgformRowid,FreqRowid,PriorRowid,DurRowid,+DoseQty,DoseUOMRowid)
	
	}else{
		s DoseQtySum=+DoseQty
		s PackQty=+DoseQty
	}
	i QtyPackUOM="" s PackQty=""
	
	KILL PLIST
	&sql(select * INTO :PLIST() FROM SQLUser.OE_OrdItem where OEORI_RowId=:OrdItmRowId)
	KILL PLIST(0),PLIST(1),PLIST(2)
	;list类型字段的处理
		
	s RemarkIndex=$O(^OEORD(ord,"I",chl,"REM",""),-1)
	Set PLIST(42)=$g(^OEORD(ord,"I",chl,"REM",+RemarkIndex))
	s NoteIndex=$O(^OEORD(ord,"I",chl,"DEP",""),-1)
	Set PLIST(53)=$g(^OEORD(ord,"I",chl,"DEP",+NoteIndex))
	
	Set PLIST(6)=admloc		 	         ;OEORI_OrdDept_DR
	Set PLIST(10)=StatusRowid	         ;OEORI_ItemStat_DR
	Set PLIST(14)=OrderDocRowid  		 ;OEORI_Doctor_DR
	;Set PLIST(17)=SttDate		         ;SttDate
	;Set PLIST(18)=SttTime   	         ;SttTime
	Set PLIST(77)=OrderSeqNo
	Set PLIST(82)=""                     ;NoOrdersLink
	Set PLIST(85)=+DoseQty                ;DoseQty
	;Set PLIST(86)=ARCOSRowid             ;ARCOS
	Set PLIST(87)=""                     ;LinkNo
	;Set PLIST(88)=LabEpisodeNo           ;LabEpisodeNo

	Set PLIST(120)=$g(UserRowId)	 	         ;User Add
	Set PLIST(121)=$g(Loc) 	 	         ;User Dept
	Set PLIST(141)=$g(UserRowId)	             ;User Update
 
	Set PLIST(161)=EpLoc		         ;OEORI_AdmLoc_Dr
	Set PLIST(154)=$number(PackQty)		 ;PackingUom Qty
	
	Set PLIST(192)=..%SysDate()		     ;Update Date
	Set PLIST(193)=..%SysTime()          ;Update Time
	
	if (OrderType="P"){
		Set PLIST(45)=""    			 ;OEORI_BillDesc
		Set oeprice=PLIST(79)			 ;OEORI_Price
		Set PLIST(46)=oeprice*PackQty	 ;OEORI_UnitCost
		Set PLIST(151)=""
		Set PLIST(154)=""
	}
	;Set PLIST(81)=OrderDate
	;Set PLIST(90)=OrderTime
	;Set PLIST(125)=OrderFlowRateUnit
	if $g(MasterOrderRowid)'="" s PLIST(230)=MasterOrderRowid
	
	;---------------------------------------
	KILL PLISTExt
	&sql(select * INTO :PLISTExt() FROM SQLUser.OE_OrdItemExt where OEORI_RowId=:OrdItmRowId)
	KILL PLISTExt(1),PLISTExt(2)
	;医嘱扩展表属性字段值
	m PLIST("DHC")=PLISTExt
	
 	Set EMStayFlag=##class(web.DHCADMVisitStat).GetStayStatus(Adm)
 	if " 1 2 "[(" "_EMStayFlag_" ") s OEORIEMStayFlag=1 
 	else  s OEORIEMStayFlag=0
 	Set PLIST("DHC",19)=OEORIEMStayFlag				;OrderLocalInfusionQty
 	
 	Set udf="Y^^"
	s RtnStr=##class(appcom.OEOrdItem).Insert(ord,udf,.PLIST)
	
	q RtnStr
}

/// ExpStr:执行时间^执行科室
ClassMethod SetAllPartExecExt(OrdItmRowId As %String, UserRowId As %String, ExStatCode As %String, ExpStr As %String = "", ByRef ErrMsg As %String = "") As %String
{
	s AppReportDR=$p($g(^OEORD(+OrdItmRowId,"I",+$p(OrdItmRowId,"||",2),"DHC")),"^",42)
	//pb by tanjishan 2023年6月25日 关联执行由子类配置进行判断，不再强校验一定是申请单
	//Q:AppReportDR="" 0
	s err=0
	;DHC_AppRepTarItm 多部位检查申请单
	if $d(^DHCAPREPTA(0,"OrdItem",OrdItmRowId)) {
		s UserCode=$p(^SSU("SSUSR",UserRowId),"^",1)
		if ($d(^DHCAPREPTA(0,"OrdItem",OrdItmRowId))) {
			k AppRepPartIDList,ARTIRowIdList,NeedToExceList
			s ARTIRowId=0
			for {
				s ARTIRowId=$o(^DHCAPREPTA(0,"OrdItem",OrdItmRowId,ARTIRowId)) Q:ARTIRowId=""
				s AppPartID=$p(^DHCAPREPTA(ARTIRowId),"^",1)
				continue:(AppPartID'="")&&($d(AppRepPartIDList(AppPartID)))
				continue:(AppPartID="")&&($d(ARTIRowIdList(ARTIRowId)))
				s ARTIType=$p(^DHCAPREPTA(ARTIRowId),"^",3)
				if (ARTIType'="P") s NeedToExceList(ARTIRowId)=1
				continue:ARTIType'="P"
				;已撤销的部位不再处理
				s arPartID=##Class(web.DHCAPPInterface).GetExaReqPartID(OrdItmRowId,AppPartID)
				if (arPartID'="") {
					s PartExeStatus=$p($g(^DHCAPREP(+arPartID,"AR",$p(arPartID,"||",2),"PA",$p(arPartID,"||",3))),"^",2)
					if PartExeStatus="D" continue
				}
				s err=##Class(web.DHCAPPInterface).SetExaReqExeStatus(OrdItmRowId,AppPartID,ExStatCode,UserCode,ExpStr)
				i err {
					s ErrMsg=..%GetErrCodeMsg("-100038")_err
					Q
				}
				s AppRepPartIDList(AppPartID)=1
				s ARTIRowIdList(ARTIRowId)=1
			}
			s ARTIRowId=0
			for{
				s ARTIRowId=$O(NeedToExceList(ARTIRowId)) q:ARTIRowId=""
				s OrdExecID=$p(^DHCAPREPTA(ARTIRowId),"^",10)
				s err=##Class(web.DHCAPPInterface).SetExecExtStat(OrdExecID,ExStatCode,UserRowId,ExpStr)
				i err {
					s ErrMsg=..%GetErrCodeMsg("-100038")_err
					Q
				}
				}
		}else{
			s err=##Class(web.DHCAPPInterface).SetExaReqExeStatus(OrdItmRowId,"",ExStatCode,UserCode,ExpStr)
			i err {
				s ErrMsg=..%GetErrCodeMsg("-100038")_err
				Q
			}
		}
	}else{
		if (ExStatCode="E") s NewExecStatCode="F"
		e  s NewExecStatCode="C"
		;医生站设置-医嘱子类扩展设置-医嘱执行/撤销执行(接口),同步更新护士执行数据
		if (..GetOrdStausChangeAutoUpdateExecFlag(OrdItmRowId)=1) {
			s err=##class(appcom.OEOrdExec).DelaWithExecAll(OrdItmRowId,UserRowId,NewExecStatCode,ExpStr)
			if err {
				s ErrMsg=..%GetErrCodeMsg(err)
				Q err
			}
		}
	}
	Q err
}

/// ;医生站设置-医嘱子类扩展设置-医嘱执行/撤销执行(接口),同步更新护士执行数据
ClassMethod GetOrdStausChangeAutoUpdateExecFlag(OrdItmRowId As %String) As %String
{
	s EpisodeID=$p(^OEORD(+OrdItmRowId),"^",1)
	s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s HospRowId=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(AdmHospitalId)
	s itemrowid=$p($g(^OEORD(+OrdItmRowId,"I",$p(OrdItmRowId,"||",2),1)),"^",2)
	s ItemCatRowId=+$p($g(^ARCIM(+$g(itemrowid),1,1)),"^",10)
	s OrdStausChangeAutoUpdateExecItemCat=..%GetConfig("OrdStausChangeAutoUpdateExecItemCat",HospRowId)
	i ("^"_OrdStausChangeAutoUpdateExecItemCat_"^")[("^"_ItemCatRowId_"^"){
		q 1
	}
	Q 0
}

}
