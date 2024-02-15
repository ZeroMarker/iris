Class web.DHCDocDiagnosEntryV8 Extends DHCDoc.Util.RegisteredObject [ ClassType = "", Not ProcedureBlock ]
{

/// 获取患者本次就诊诊断列表
/// d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","DiagnosList",190)
Query DiagnosList(MRADMID As %String = "", ICDType As %String = "", DiagnosTypeCode As %String = "", LogonCTLocRowId As %String = "", HospId As %String = "") As %Query(ROWSPEC = "MRCIDRowId:%String,MRDIARowId:%String,DiagnosCat:%String,DiagnosType:%String,DiagnosLeavel:%String,DiagnosICDDesc:%String,MainDiagFlag:%String,DiagnosNotes:%String,MRCIDCode:%String,DiagnosStatus:%String,id:%String,DiagnosOnsetDate:%String,DiagnosDate:%String,SyndromeDesc:%String,MRDIAMRDIADR:%String,DiagnosStatusRowId:%String,DiagnosTypeRowId:%String,DiagnosDoctor:%String,DiagnosBodyPart:%String,DiagnosBodyPartRowId:%String,LongDiagnosFlagRowId:%String,LongDiagnosFlag:%String,DiagnosPrefix:%String,DiagnosNumber:%String,MRDIAAddLocDr:%String,DiagnosDoctorCode:%String,DiagnosTime:%String,SDSInfo:%String,SDSDesc:%String,DiagInsuCode:%String,DiagInsuName:%String,TCMTreatmentID:%String,TCMTreatment:%String,DiagnosCatRowId:%String,AddUserDr:%String,DiagnosUserDr:%String")
{
}

ClassMethod DiagnosListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DiagnosListExecute ]
{
	Set repid=$LIST(qHandle,2)
	 Kill ^CacheTemp(repid)
	 Quit $$$OK
}

ClassMethod DiagnosListExecute(ByRef qHandle As %Binary, MRADMID As %String = "", ICDType As %String = "", DiagnosTypeCode As %String = "", LogonCTLocRowId As %String = "", HospId As %String = "") As %Status
{
	;d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","DiagnosList","634",,,63)
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	if MRADMID="" {  
	    d ResetVariables1
		Set qHandle=$lb(0,repid,0)
		Quit $$$OK
	}
	s HospId=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospId)
	Set langid=..%LanguageID()
	Set RetStr="",NO=1
	k TempArr("FindDiagnos",$J)
	
	s defaultDiagnosTypeID=""
	if DiagnosTypeCode'="" {
		s defaultDiagnosTypeID=$O(^MRC("DTYP",0,"Code",DiagnosTypeCode,0))
	}
	s EpisodeID=$p($G(^MR(MRADMID,"PRO",1)),"^",9)
	s ADMNo=$p(^PAADM(EpisodeID),"^",81)
	s Id=0
	Set obj=##class(%ResultSet).%New("web.DHCDocDiagnosNew:Find")
	d obj.Execute(MRADMID)
	For  Quit:'obj.Next()  Do
	.s Desc=obj.Data("MRDIAICDCodeDRDesc")
	.if Desc'="" s Desc=##class(User.MRCICDDx).GetTranByDesc("MRCIDDesc",Desc,langid)
	.s Rowid=obj.Data("ID")
	.s MRDiagnosTypeDesc=""
	.s MRDiagnosTypeDr=""
	.S MRdiagnosNoteDr=""
	.S MRdiagnosNoteDesc=""
	.s MRdiagnosNoteSubRowid=""
	.S SubRowid=$G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),"TYP",0))
	.if SubRowid'="" s MRDiagnosTypeDr=$G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),"TYP",SubRowid))
	.Q:(defaultDiagnosTypeID'="")&&(MRDiagnosTypeDr'=defaultDiagnosTypeID)
	.I MRDiagnosTypeDr'="" d
	..Set MRDiagnosTypeDesc=$P($G(^MRC("DTYP",MRDiagnosTypeDr)),"^",2)
	..Set MRDiagnosTypeDesc= ##class(User.MRCDiagnosType).GetTranByDesc("DTYPDesc",MRDiagnosTypeDesc,langid)
	.S MRdiagnosNoteSubRowid=$G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),"DES",0))
	.I MRdiagnosNoteSubRowid'="" Set MRdiagnosNoteDesc=$G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),"DES",MRdiagnosNoteSubRowid))
	.s MRdiagnosNoteDesc=##class(ext.util.String).EvalJSON(MRdiagnosNoteDesc)
	.s CodeRowid=obj.Data("MRDIAICDCodeDR")
	.s MRCIDCode=obj.Data("MRDIAICDCodeDRCode")
	.S MRDiagnosDate=obj.Data("MRDIADate")
	.s MRdiagnosTime=obj.Data("MRDIATime")
	.s MRAddLocDr=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",20)
	.s MRDIAMRDIADR=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2))),"^",15)
	.I MRDiagnosDate'="" Set MRDiagnosDate=..%ZD(MRDiagnosDate) //$zd(MRDiagnosDate,3)
	.I MRdiagnosTime'="" Set MRdiagnosTime=..%ZT(MRdiagnosTime)
	.s DiagnosCatRowId=##class(DHCDoc.Diagnos.Common).GetDiagnosCatID(Rowid)-1	;输出与目前界面界面保持一致 0,1,2
	.Q:(ICDType="1")&&(DiagnosCatRowId'=0)
	.Q:(ICDType="2")&&(BillFlag3=0)
	.s DiagnosCat=##class(DHCDoc.Diagnos.Common).GetDiagnosCat(Rowid)
	.s MainDiagFlag=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",20)
	.i MainDiagFlag="Y" s MainDiagFlag="是"
	.e  s MainDiagFlag="否"
	.s MainDiagFlag=..%Translate("diagnosentry.v8.csp",MainDiagFlag)
	.s MRDesc=obj.Data("MRDIADesc")
	.if (MRDesc'="")&&($$$ISOK($LV(MRDesc))) s MRDesc=$LIST(MRDesc,1)
	.s DiagStat=""
	.s DiagStatDr=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2))),"^",9)
	.s DiagnosLeavel=$P($G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),"EPR")),"^",1) //取诊断级别
	.s DiagnosNumber=$P($G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),"EPR")),"^",2) //取顺序号
	.s DIAOnsetDate=$P($G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2))),"^",35) //取发病日期
	.s:DIAOnsetDate'="" DIAOnsetDate=..%ZD(DIAOnsetDate) //$zd(DIAOnsetDate,3) //取发病日期
	.if DiagStatDr'="" d
	..s DiagStat=$p($g(^MRC("DSTAT",DiagStatDr)),"^",2)
	..s DiagStat =##class(User.MRCDiagnosStatus).GetTranByDesc("DSTATDesc",DiagStat,langid)
	.if DiagnosNumber="" s DiagnosNumber=9999 //$g(^MR(3,"DIA",0))+1
	.;tanjishan 慢病
	.s NCDCode=$p($G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),"DHC")),"^",10)
	.s NCDDesc="" //..GetNCDDesc(NCDCode)
	.;end
	.;描述有反斜杠会影响前台
	.s MRDesc=$replace(MRDesc,"\","")
	.s banlkSpace="" f i=1:1:(+DiagnosLeavel-1) s banlkSpace=banlkSpace_"&nbsp;&nbsp;&nbsp;&nbsp;" ;根椐级别加空格
    .s Desc=banlkSpace_Desc
    .s SyndromeDesc=##class(web.DHCDocDiagnosNew).GetDiaSyndDesc(Rowid)
    .i SyndromeDesc'="" s SyndromeDesc=$tr(SyndromeDesc,","," ")
	.//i MainDiagFlag'="" s Desc=Desc_MainDiagFlag
	
	.;这里的下诊断医生会作为医保登记数据进行上传，不可修改为录入人
	.s AddUserDr=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",18)
	.if (AddUserDr'="") d
	..;s DoctorDr=$p(^SSU("SSUSR",+AddUserDr),"^",14)
	.s DiagnosDoctor="",DiagnosDoctorCode="",DiagnosUserDr=""
	.s DoctorDr=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2))),"^",4)
    .i DoctorDr'="" s DiagnosDoctor=$P($G(^CTPCP(DoctorDr,1)),"^",2)
    .i DoctorDr'="" s DiagnosDoctorCode=$p($g(^CTPCP(DoctorDr,1)),"^",1) ;诊断医生编码
	.i DoctorDr'="" s DiagnosUserDr=$O(^SSU("SSUSR",0,"CTPCP",DoctorDr,""),-1)
    .Set DiagnosDoctor= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",DiagnosDoctor,langid)
	.s BodyPartDesc=""
    .s BodyPartDr=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",21)
    .i BodyPartDr'="" s BodyPartDesc=$List(^DHCEMRM.DicDiagnosPositionD(BodyPartDr),3)
    .s LongDiagnosFlagRowId=$P($G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",23)
    .s DiagnosPrefix=$P($G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",26)
    .s MRDIAAddLocDr=$p($g(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",25) ;诊断科室
    .;结构化诊断信息返回
    .s SDSInfo=##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).GetStructDiagnos(ADMNo,Rowid)
    .s SDSRowId=$P(SDSInfo,"^",1)
    .s SDSTermDR=$P(SDSInfo,"^",2)
    .s SDSDisplayIDStr=$P(SDSInfo,"^",3)
    .s SDSDesc=$P(SDSInfo,"^",4)
    .s SDSWordID=$P(SDSInfo,"^",8)
    .s Supplement=$P(SDSInfo,"^",9)
    .s AdmReason=""
    .if (EpisodeID'="") s AdmReason=$p($G(^PAADM(EpisodeID,1)),"^",7)
    .s NowDate=..%ZD(+$H)
    .s ExpStr=""
    .s DiagInsuInfo=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.diag.GetInsuInfo",CodeRowid,HospId,AdmReason,NowDate,ExpStr)
    .s DiagInsuCode=$P(DiagInsuInfo,"^",1)
    .s DiagInsuName=$P(DiagInsuInfo,"^",2)
	.s TCMTreatmentID=$P($G(^MR($P(Rowid,"||",1),"DIA",$P(Rowid,"||",2),1)),"^",29)
	.s TCMTreatment=$P($G(^MRC("TCMT",+TCMTreatmentID)),"^",2)
	.s:TCMTreatment'="" TCMTreatment=##class(User.MRCTCMTreatment).GetTranByDesc("TCMTDesc",TCMTreatment,langid)
	.s TempArr("FindDiagnos",$j,DiagnosNumber,$P(Rowid,"||",2))=Desc_"^"_Rowid_"^"_CodeRowid_"^"_MRDesc_"^"_MRCIDCode_"^"_MRDiagnosTypeDesc_"^"_MRdiagnosNoteDesc_"^"_MRDiagnosDate_"^"_MRdiagnosTime_"^"_DiagStat_"^"_DiagnosLeavel_"^"_DiagnosNumber_"^"_DIAOnsetDate_"^"_DiagnosCat_"^"_MRDIAMRDIADR_"^"_NCDCode_"^"_NCDDesc_"^"_MainDiagFlag_"^"_SyndromeDesc_"^"_DiagStatDr_"^"_MRDiagnosTypeDr_"^"_DiagnosDoctor_"^"_BodyPartDesc_"^"_BodyPartDr_"^"_LongDiagnosFlagRowId_"^"_DiagnosPrefix_"^"_DiagnosDoctorCode_"^"_MRDIAAddLocDr_"^"_SDSRowId_"^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_Supplement_"^"_SDSDesc_"^"_DiagInsuCode_"^"_DiagInsuName_"^"_TCMTreatmentID_"^"_TCMTreatment_"^"_DiagnosCatRowId_"^"_AddUserDr_"^"_DiagnosUserDr
	d obj.Close()
	
	//按顺序输出设置
	s TempDia=""
	s DiagnosNumber=0  f  {
		s DiagnosNumber=$O(TempArr("FindDiagnos",$j,DiagnosNumber)) 
		Q:DiagnosNumber=""  d
		s Temprowid=0 f {
			s Temprowid=$O(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid))
			q:Temprowid=""
			s DiagnosDesc=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",1)
			s DiagnosValue=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",2)
			s DiagnosCodeRowid=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",3)
			s DiagnosMRDesc=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",4)
			s DiagnosICDCode=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",5)
			s DiagnosType=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",6)
			s DiagnosNote=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",7)
			s DiagnosDate=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",8)
			s DiagnosTime=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",9)
			s DiagnosNumber=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",12)
			
			s DiagnosOnsetDate=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",13)
			s DiagnosLeavel=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",11)
			s DiagStat=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",10)
			s DiagnosCat=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",14)
			s MRDIAMRDIADR=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",15)
			
			s NCDCode=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",16)
			s NCDDesc=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",17)
			s MainDiagFlag=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",18)
			s SyndromeDesc=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",19)
			
			s DiagStatDr=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",20)
			s MRDiagnosTypeDr=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",21)
			s DiagnosDoctor=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",22)
			s BodyPartDesc=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",23)
			s BodyPartDr=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",24)
			s LongDiagnosFlagRowId=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",25)
			s LongDiagnosFlag=$case(LongDiagnosFlagRowId,"L":..%Translate("diagnosentry.v8.csp","本科"),"H":..%Translate("diagnosentry.v8.csp","全院"),:"")
			s DiagnosPrefix=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",26)
			s DiagnosDoctorCode=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",27)
			s MRDIAAddLocDr=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",28)
			s SDSRowId=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",29)
			s SDSTermDR=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",30)
			s SDSDisplayIDStr=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",31)
			s SDSWordID=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",32)
			s Supplement=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",33)
			s SDSInfo=$CASE(SDSTermDR,"":"",:SDSRowId_"^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_Supplement)
			s SDSDesc=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",34)
			s DiagInsuCode=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",35)
			s DiagInsuName=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",36)
			s TCMTreatmentID=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",37)
			s TCMTreatment=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",38)
			s DiagnosCatRowId=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",39)
			s AddUserDr=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",40)
			s DiagnosUserDr=$p(TempArr("FindDiagnos",$j,DiagnosNumber,Temprowid),"^",41)
			s Id=Id+1
			Do OutputRow1
		}
	}
	k TempArr("FindDiagnos",$j)
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow1
     set Data=$lb(DiagnosCodeRowid,DiagnosValue,DiagnosCat,DiagnosType,DiagnosLeavel,DiagnosDesc,MainDiagFlag,DiagnosMRDesc,DiagnosICDCode,DiagStat,Id,DiagnosOnsetDate,DiagnosDate,SyndromeDesc,MRDIAMRDIADR,DiagStatDr,MRDiagnosTypeDr,DiagnosDoctor,BodyPartDesc,BodyPartDr,LongDiagnosFlagRowId,LongDiagnosFlag,DiagnosPrefix,DiagnosNumber,MRDIAAddLocDr,DiagnosDoctorCode,DiagnosTime,SDSInfo,SDSDesc,DiagInsuCode,DiagInsuName,TCMTreatmentID,TCMTreatment,DiagnosCatRowId,AddUserDr,DiagnosUserDr)
	 Set ^CacheTemp(repid,ind)=Data
	 Set ind=ind+1
	quit
ResetVariables1
	set (DiagnosDesc,DiagnosValue,DiagnosCodeRowid,DiagnosMRDesc,DiagnosICDCode,DiagnosType,DiagnosNote,DiagnosDate,DiagnosOnsetDate,DiagStat,DiagnosLeavel,DiagnosCat,MRDIAMRDIADR,NCDCode,NCDDesc,Id,DiagnosOnsetDate,SyndromeDesc,MRDIAMRDIADR,BodyPartDesc,BodyPartDr,DiagnosDoctor,LongDiagnosFlagRowId,LongDiagnosFlag,DiagnosPrefix,DiagnosNumber,MRDIAAddLocDr,DiagnosDoctorCode,DiagnosTime,SDSInfo,SDSDesc,DiagInsuCode,DiagInsuName,TCMTreatmentID,TCMTreatment,DiagnosCatRowId,AddUserDr,DiagnosUserDr)=""
	quit
}

ClassMethod DiagnosListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DiagnosListExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 删除诊断
/// w ##class(web.DHCDocDiagnosEntryV8).DeleteMRDiagnos("2064||14^2064||15",10209,6)
ClassMethod DeleteMRDiagnos(MRDiagnosRowidStr As %String, UserRowid As %String = "", LocRowid As %String = "") As %String
{
	n (MRDiagnosRowidStr,UserRowid,LocRowid,%session)
	s Checkret=##class(web.DHCMRDiagnos).CheckDelete(MRDiagnosRowidStr,UserRowid,LocRowid)
 	Q:Checkret'="" Checkret
	s DelMRDiagnosRowidStr=""
	s mradmrowid=$p($p(MRDiagnosRowidStr,"^",1),"||",1)
	i mradmrowid'="" s adm=$p($g(^MR(mradmrowid,"PRO",1)),"^",9)
	s ADMNo=$p(^PAADM(adm),"^",81)
	for m=1:1:$l(MRDiagnosRowidStr,"^") {
		s oneMRDiagnosRowid=$p(MRDiagnosRowidStr,"^",m)
		continue:oneMRDiagnosRowid=""
		if ($D(^MR(+oneMRDiagnosRowid,"DIA",0,"Link",oneMRDiagnosRowid))){
			////判断是否有子诊断
			s StopRowidStr=##class(web.DHCMRDiagnos).GetGroupMRDia(oneMRDiagnosRowid)
		}else{
			s StopRowidStr=oneMRDiagnosRowid
		}
		for i=1:1:$Length(StopRowidStr,"^") {
			s oneRowid=$P(StopRowidStr,"^",i)
			continue:(+oneRowid=0)||('$d(^MR(+oneRowid,"DIA",$P(oneRowid,"||",2))))
			s DiagNotes=$G(^MR(+oneRowid,"DIA",$P(oneRowid,"||",2),"DES",1))
			s ^MRDelLog(+oneRowid,"Sub",$p(oneRowid,"||",2))=UserRowid_"^"_..%ZD(+$H)_"^"_..%ZT(..%SysTime())_"^"_DiagNotes
			m ^MRDelLog(+oneRowid,"Sub",$p(oneRowid,"||",2),"Data")=^MR(+oneRowid,"DIA",$P(oneRowid,"||",2))
			s ^MRDelLog(+oneRowid,"Sub",$p(oneRowid,"||",2),"Data","SDS")=##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).GetStructDiagnos(ADMNo,oneRowid)
			set OldDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_oneRowid)
			&SQL(Delete From SQLUser.MR_Diagnos Where MRDIA_Rowid=:oneRowid)
			i SQLCODE=100 s SQLCODE=0
			if (DelMRDiagnosRowidStr="") s DelMRDiagnosRowidStr=oneRowid
			else  s DelMRDiagnosRowidStr=DelMRDiagnosRowidStr_"$"_oneRowid
			set ret=##class(web.DHCDocDataChangeLog).SaveLog("MR_Diagnos","User.MRDiagnos","诊断信息","User.MRDiagnos_"_oneRowid,oneRowid,"D","",OldDataJson,UserRowid)
		}
	}
	if (SQLCODE=0)&&(DelMRDiagnosRowidStr'="") {
		//作废医生已经开立且未打印的诊断证明书
		d ##class(web.DHCDocDiagnosCertificate).UnuseDiagnosCertificate(adm,DelMRDiagnosRowidStr)
		;作废结构化诊断
		s ADMNo=$p(^PAADM(adm),"^",81)
		d ##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).DeleteStructDiagnos(ADMNo,$replace(DelMRDiagnosRowidStr,"$","^"))
		;调用平台接口
		s PatientID=$p(^PAADM(adm),"^",1)
		s PatientNo=$p(^PAPER(PatientID,"PAT",1),"^",1)
		s InputDiagStr=$REPLACE(DelMRDiagnosRowidStr,"$","@")
		d ##class(web.DHCENS.EnsHISService).DHCHisInterface("S00000055",PatientNo_"^"_adm_"^"_InputDiagStr)
	}
 	Q SQLCODE_"^"_DelMRDiagnosRowidStr
}

/// w ##class(web.DHCDocDiagnosEntryV8).UpdateMRDiagnosNote("79||94","测试修改",5,"Y",1,"02/11/2017")
ClassMethod UpdateMRDiagnosNote(MRDIARowId As %String, MRDIADesc As %String, DiagnosTypeRowId As %String, MainDiagFlag As %String, DiagnosStatusRowId As %String, DiagnosOnsetDate As %String, BodyPartRowId As %String, DiagnosDate As %String, LongDiagnosFlagRowId As %String, LogDepRowid As %String, UserRowId As %String, MainPALongRowId As %String = "", DiagnosPrefix As %String = "", ICDCodeRowid As %String = "", SDSTermDR As %String = "", SDSDisplayIDStr As %String = "", SDSWordID As %String = "", SDSNote As %String = "", SyndromeCICDStr As %String = "", SyndromeDescStr As %String = "", TCMTreatmentID As %String = "", DiagnosLeavel = "") As %String
{
   n (MRDIARowId,MRDIADesc,DiagnosTypeRowId,MainDiagFlag,DiagnosStatusRowId,DiagnosOnsetDate,BodyPartRowId,DiagnosDate,LongDiagnosFlagRowId,UserRowId,LogDepRowid,MainPALongRowId,DiagnosPrefix,ICDCodeRowid,SDSTermDR,SDSDisplayIDStr,SDSWordID,SDSNote,SyndromeCICDStr, SyndromeDescStr,TCMTreatmentID,DiagnosLeavel,%session)
   s ^tempscl("dd")=MRDIARowId_","_MRDIADesc_","_DiagnosTypeRowId_","_MainDiagFlag_","_DiagnosStatusRowId_","_DiagnosOnsetDate_","_BodyPartRowId_","_DiagnosPrefix
   i DiagnosOnsetDate'="" s DiagnosOnsetDate=..%ZDH(DiagnosOnsetDate)
   i DiagnosOnsetDate="" s DiagnosOnsetDate=..%SysDate()
   s HosRowid=##Class(web.CTLoc).GetHospital(LogDepRowid) 
   set OldDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_MRDIARowId)
   TS
   Set object = ##class(User.MRDiagnos).%OpenId(MRDIARowId)
   s object.MRDIAOnsetDate=DiagnosOnsetDate
   Do object.MRDIADesc.Clear()
   ////非标准诊断类型0:西医，1：中医，2症性
	if MRDIADesc'="" {
		s DescType=$P(MRDIADesc,"#",2)
		s MRDIADesc=$P(MRDIADesc,"#",1)
		d object.MRDIADesc.Insert($replace(MRDIADesc,"\",""))
		if (DescType'="") s object.MRDIAQuestionnaire=DescType
	}
   Do object.MRDIADiagStatDRSetObjectId($g(DiagnosStatusRowId))
   Do object.MRDIAUpdateLocDrSetObjectId(LogDepRowid)
   s object.MRDIAMainDiagFlag=MainDiagFlag
   if $D(^DHCEMRM.DicDiagnosPositionD(+BodyPartRowId)){
   		s object.MRDIABodyPart=BodyPartRowId
   }
   s object.MRDIADate=DiagnosDate //$p($h,",",1)
   s object.MRDIATime=..%SysTime()
   Do object.MRDIAUpdateUserDRSetObjectId(UserRowId)
   Do object.MRDIAUpdateHospitalDRSetObjectId(HosRowid)
   s object.MRDIAUpdateDate=..%SysDate()
   s object.MRDIAUpdateTime=..%SysTime()
   s object.MRDIALongDiagnosFlag=LongDiagnosFlagRowId
   s object.MRDIADiagnosPrefix=DiagnosPrefix
   Do object.MRDIAICDCodeDRSetObjectId(ICDCodeRowid)
   d object.MRDIATCMTreatDRSetObjectId(TCMTreatmentID)	//中医治法
   s:+DiagnosLeavel=0 DiagnosLeavel=1
   s object.MRDIALevel=DiagnosLeavel
   Set sc = object.%Save()
	 If $$$ISERR(sc) {
		 b ;Do $System.Status.DisplayError()
		 TRO
		 Quit "-201^更新诊断表失败,错误信息:"_$ZE
   }
   Do object.%Close()
   s object=""
   s MainMRDIADR=$p($g(^MR(+MRDIARowId,"DIA",$p(MRDIARowId,"||",2))),"^",15) 
   //长效诊断表
   s MRDIAICDCodeDR=$p($g(^MR(+MRDIARowId,"DIA",$p(MRDIARowId,"||",2))),"^",1) 
   s Adm=$p(^MR(+MRDIARowId,"PRO",1),"^",9)
   s PatientID=$p(^PAADM(Adm),"^",1)
   if (LongDiagnosFlagRowId'="")&&(MRDIAICDCodeDR'=""){
	 s ICDInfo=##Class(web.DHCDocDiagnosEntryV8).GetICDInfoByICDDr(MRDIAICDCodeDR)
	 s LinkPALongRowId=MainPALongRowId
	 if ($p(ICDInfo,"^",4)'="证型"){
		 s LinkPALongRowId=""
	 }
	 s SDSInfo="^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_SDSNote
	 s rtn=..SavePAlongICD(PatientID,MRDIAICDCodeDR,LongDiagnosFlagRowId,UserRowId,LinkPALongRowId,LogDepRowid,SDSInfo)
	 s err=$p(rtn,"^",1)
	 if ($p(ICDInfo,"^",4)="中医"){
		 s:MainPALongRowId="" MainPALongRowId=$p(rtn,"^",2)
	 }
	 if (err'=0){
		 TRO
	 	 Quit "-207^插入长效诊断表失败,错误信息:"_$ZE
	 }
   }
   &SQL(update  SQLUser.MR_Diagtype set typ_mrcdiagtyp=:DiagnosTypeRowId where typ_parref=:MRDIARowId)
   i SQLCODE'=0 {
		 TRO
		 Quit "-204^更新诊断子表诊断类型表失败,请重新选择诊断类型,错误信息SQLCODE:"_SQLCODE
   }else{
   		//保存结构化诊断
	   if (SDSTermDR'="") {
			 s EpisodeID=$P($g(^MR(+MRDIARowId,"PRO",1)),"^",9)
			 s PatientID=$p(^PAADM(EpisodeID),"^",1)
			 s PatNo=$p(^PAPER(PatientID,"PAT",1),"^",1)
			 s ADMNo=$p(^PAADM(EpisodeID),"^",81)
			 s DiagnosDate=+$H
			 if (DiagnosTypeRowId'="") s MRDiagTypeDesc=$p($g(^MRC("DTYP",DiagnosTypeRowId)),"^",2)
			 if (DiagnosStatusRowId'="") s DiagnosStatusDesc=$p(^MRC("DSTAT",DiagnosStatusRowId),"^",2)
			 s retJson=##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).SaveStructDiagnos(MRDIARowId,PatNo,ADMNo,SDSTermDR,SDSDisplayIDStr,$replace(SDSNote,"\",""),"",MainDiagFlag,$g(MRDiagTypeDesc),$g(DiagnosStatusDesc),DiagnosLeavel,$p(MRDIARowId,"||",2),DiagnosDate,DiagnosOnsetDate,SDSWordID)
			 s retObj={}.%FromJSON(retJson)
			 if retObj.success'="true"{
				TRO
				Quit "-206^保存结构化诊断失败:"_retObj.errorinfo
			 }
		}
		;医生站业务数据修改日志
		set NewDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_MRDIARowId)
		set ret=##class(web.DHCDocDataChangeLog).SaveLog("MR_Diagnos","User.MRDiagnos","诊断信息","User.MRDiagnos_"_MRDIARowId,MRDIARowId,"U",NewDataJson,OldDataJson)
		If ret'=0 {
			Trollback
			Quit 100
		}
		///证型新增与更新
		if ((SyndromeCICDStr'="")||(SyndromeDescStr'="")){
			s SyndromeDiagnosLevel=DiagnosLeavel+1
			s rtn=0
			for i=1:1:$L(SyndromeCICDStr,"^"){
				s SyndromeCICDRowidStr=$P(SyndromeCICDStr,"^",i)
				s SyndromeCICDRowid=$p(SyndromeCICDRowidStr,$C(2),1)
				s MRDiagTypeId=$p(SyndromeCICDRowidStr,$C(2),2)
				s MainDiaType=$p(SyndromeCICDRowidStr,$C(2),3)
				s DiagnosStatus=$p(SyndromeCICDRowidStr,$C(2),4)
				s SynDiagnosOnsetDate=$p(SyndromeCICDRowidStr,$C(2),5)
				i SynDiagnosOnsetDate'="" s SynDiagnosOnsetDate=..%ZDH(SynDiagnosOnsetDate)
				e  s SynDiagnosOnsetDate=..%SysDate()
				s SynDiagnosDiagnosDate=$p(SyndromeCICDRowidStr,$C(2),6)
				i SynDiagnosDiagnosDate'="" s SynDiagnosDiagnosDate=..%ZDH(SynDiagnosDiagnosDate)
				e  s SynDiagnosDiagnosDate=..%SysDate()
				s LongDiagnosFlagRowId=$p(SyndromeCICDRowidStr,$C(2),7)
				s SynDiagnosPrefix=$p(SyndromeCICDRowidStr,$C(2),8)
				s TCMTreatmentID=$p(SyndromeCICDRowidStr,$C(2),9)
				s SyndromeRowid=$p(SyndromeCICDRowidStr,$C(2),10)
				s SyndromeDesc=$P(SyndromeDescStr,"^",i)
				continue:(SyndromeCICDRowid="")&&((SyndromeDesc="#3")||(SyndromeDesc=""))
				if SyndromeRowid=""{
					s rtn=..InsertOneMRDiagnos(LogDepRowid,+MRDIARowId,SyndromeCICDRowid,UserRowId,SyndromeDesc,MRDiagTypeId,"","","","","",DiagnosStatus,SyndromeDiagnosLevel,UserRowId,MainDiaType,"","","",SynDiagnosOnsetDate,"",SynDiagnosDiagnosDate,LongDiagnosFlagRowId,MainPALongRowId,SynDiagnosPrefix,"","","","",TCMTreatmentID)	
					s SyndromeRowid=$P(rtn,"^",2)
					if ((+rtn=0)&&(SyndromeRowid'="")){
						s ret=##Class(web.DHCDocDiagnosNew).UpdateMRDiagnos(SyndromeRowid,"2")
						Set object = ##class(User.MRDiagnos).%OpenId(SyndromeRowid)
						d object.MRDIAMRDIADRSetObjectId($P(Rowid,"^",1))
						Set sc = object.%Save()
						Do object.%Close()
			
					}
				}else{
					s rtn=..UpdateMRDiagnosNote(SyndromeRowid,SyndromeDesc,MRDiagTypeId,MainDiaType,DiagnosStatus,SynDiagnosOnsetDate,"",SynDiagnosDiagnosDate,LongDiagnosFlagRowId,LogDepRowid,UserRowId,MainPALongRowId,SynDiagnosPrefix,SyndromeCICDRowid,"","","","","","",TCMTreatmentID,SyndromeDiagnosLevel)
				}
				Q:+rtn'=0
			}
			if +rtn'=0{
				TRO
				Quit "-207^证型更新失败:"_rtn
			}
		}
	   	TC
   	}
   	Q 0_"^"_MainPALongRowId
}

/// w ##class(web.DHCDocDiagnosEntryV8).InsertMRDiagnos($LG(^tmpscl("InsertMRDiagnos"),1),$LG(^tmpscl("InsertMRDiagnos"),2),$LG(^tmpscl("InsertMRDiagnos"),3),$LG(^tmpscl("InsertMRDiagnos"),4),$LG(^tmpscl("InsertMRDiagnos"),5))
ClassMethod InsertMRDiagnos(mradm As %String, DiagItemStr As %String, AdmPara As %String, CTLocRowId As %String, UserRowId As %String) As %String
{
	s:mradm=7586 ^tmpscl("InsertMRDiagnos")=$LB(mradm,DiagItemStr,AdmPara,CTLocRowId,UserRowId)
	s err=0,DiagRowIdStr="",rtn="",MainPALongRowId=""
	s Adm=$p(^MR(mradm,"PRO",1),"^",9)
	for i=1:1:$l(DiagItemStr,$c(1)) d
	.s OneAddDiagItem=$p(DiagItemStr,$c(1),i)
	.q:OneAddDiagItem=""
	.s MRDIARowId=$p(OneAddDiagItem,"^",1)
	.i MRDIARowId'="" d //已审核诊断
	..s MRDIADesc=$p(OneAddDiagItem,"^",2)
	..//DiagnosTypeRowId+"^"+MainDiagFlag+"^"+DiagnosStatusRowId+"^"+DiagnosOnsetDate
	..s DiagnosTypeRowId=$p(OneAddDiagItem,"^",3)
	..s MainDiagFlag=$p(OneAddDiagItem,"^",4)
	..s DiagnosStatusRowId=$p(OneAddDiagItem,"^",5)
	..s DiagnosOnsetDate=$p(OneAddDiagItem,"^",6)
	..s BodyPartRowId=$p(OneAddDiagItem,"^",7)
	..s DiagnosDate=$p(OneAddDiagItem,"^",8)
	..s LongDiagnosFlagRowId=$p(OneAddDiagItem,"^",9)
	..s DiagnosPrefix=$p(OneAddDiagItem,"^",10)
	..s ICDCodeRowid=$p(OneAddDiagItem,"^",11)
	..s SDSTermDR=$p(OneAddDiagItem,"^",12)
    ..s SDSDisplayIDStr=$p(OneAddDiagItem,"^",13)
    ..s SDSWordID=$p(OneAddDiagItem,"^",14)
    ..s SDSNote=$p(OneAddDiagItem,"^",15)
    ..s SyndromeCICDStr=$tr($p(OneAddDiagItem,"^",16),"$","^")
    ..s SyndromeCDescStr=$tr($p(OneAddDiagItem,"^",17),"$","^")
	..s DiagnosLeavel=$p(OneAddDiagItem,"^",18)
    ..i DiagnosDate'="" s DiagnosDate=..%ZDH(DiagnosDate)
    ..e  s DiagnosDate=..%SysDate()
	..s err=##class(web.DHCDocDiagnosEntryV8).UpdateMRDiagnosNote(MRDIARowId,MRDIADesc,DiagnosTypeRowId,MainDiagFlag,DiagnosStatusRowId,DiagnosOnsetDate,BodyPartRowId,DiagnosDate,LongDiagnosFlagRowId,CTLocRowId,UserRowId,MainPALongRowId,DiagnosPrefix,ICDCodeRowid,SDSTermDR,SDSDisplayIDStr,SDSWordID,SDSNote,SyndromeCICDStr,SyndromeCDescStr,"",DiagnosLeavel)
	..i +err=0 d
	...s MainPALongRowId=$p(err,"^",2)
	...i DiagRowIdStr="" s DiagRowIdStr=MRDIARowId_$c(1)_ICDCodeRowid_$c(1)_"U"
	...e  s DiagRowIdStr=DiagRowIdStr_"^"_MRDIARowId_$c(1)_ICDCodeRowid_$c(1)_"U"
	..//Q:err'=0
	.e  d //本次新增诊断
	..s MRDIADesc=$p(OneAddDiagItem,"^",2)
	..s ICDCodeRowid=$p(OneAddDiagItem,"^",3)
	..s MRDiagTypeId=$p(OneAddDiagItem,"^",4)
	..s MainDiaType=$p(OneAddDiagItem,"^",5)
    ..s DiagnosStatusRowId=$p(OneAddDiagItem,"^",6)
    ..s DiagnosOnsetDate=$p(OneAddDiagItem,"^",7)
    ..i DiagnosOnsetDate'="" s DiagnosOnsetDate=..%ZDH(DiagnosOnsetDate)
    ..i DiagnosOnsetDate="" s DiagnosOnsetDate=..%SysDate()
    ..s SyndromeCICDStr=$tr($p(OneAddDiagItem,"^",8),"$","^")
    ..s SyndromeCDescStr=$tr($p(OneAddDiagItem,"^",9),"$","^")
    ..s BodyPartRowId=$p(OneAddDiagItem,"^",10)
    ..s DiagnosDate=$p(OneAddDiagItem,"^",11)
    ..i DiagnosDate'="" s DiagnosDate=..%ZDH(DiagnosDate)
    ..e  s DiagnosDate=..%SysDate()
    ..s LongDiagnosFlagRowId=$p(OneAddDiagItem,"^",12)
    ..s DiagnosPrefix=$p(OneAddDiagItem,"^",13)
    ..s SDSTermDR=$p(OneAddDiagItem,"^",14)
    ..s SDSDisplayIDStr=$p(OneAddDiagItem,"^",15)
    ..s SDSWordID=$p(OneAddDiagItem,"^",16)
    ..s SDSNote=$p(OneAddDiagItem,"^",17)
    ..s DocUserId=$p(OneAddDiagItem,"^",18)
	..s DiagnosLeavel=$p(OneAddDiagItem,"^",19)
    ..s rtn=##class(web.DHCDocDiagnosEntryV8).InsertOneMRDiagnos(CTLocRowId, mradm,ICDCodeRowid,UserRowId,MRDIADesc,MRDiagTypeId,"","","","","",DiagnosStatusRowId,DiagnosLeavel,DocUserId,MainDiaType,SyndromeCICDStr,SyndromeCDescStr,"",DiagnosOnsetDate,BodyPartRowId,DiagnosDate,LongDiagnosFlagRowId,"",DiagnosPrefix,SDSTermDR,SDSDisplayIDStr,SDSWordID,SDSNote)
	..s err=$p(rtn,"^",1)
	..i err=0 d
	...for k=2:1:$l(rtn,"^") d
	....s RowId=$p(rtn,"^",k)
	....//插入证型信息
	....//i SyndIdStr'="" s err=##class(web.DHCDocDiagnosNew).InsertDiaSynd(Adm,RowId,$tr(SyndIdStr,$c(2),"^"),UserRowId,"")
	....i DiagRowIdStr="" s DiagRowIdStr=RowId_$c(1)_ICDCodeRowid_$c(1)_"A"
	....e  s DiagRowIdStr=DiagRowIdStr_"^"_RowId_$c(1)_ICDCodeRowid_$c(1)_"A"
	
	d:(AdmPara'="") ##class(web.DHCMRDiagnos).UpdatePAADM(Adm,AdmPara,"Hidden","Hidden",CTLocRowId)
	if (DiagRowIdStr'="") {
		//置患者达到状态
		s DocID=$P(^SSU("SSUSR",UserRowId),"^",14)
		d ##class(web.DHCDocOrderEntry).SetArrivedStatus(Adm,DocID,CTLocRowId,UserRowId)
		d ..UpdateAdmDiagSeq(mradm)
		//调用平台接口
		d ##class(web.DHCENS.EnsHISService).DHCHisInterface("S00000010",Adm)
		//DTS埋点
		s DTStype=##class(DHCDoc.Log.BizLogDTS).GetAdmType(Adm)
		s DiagLen = $l(DiagRowIdStr,"^")
		s UserCode=$p($g(^SSU("SSUSR",UserRowId)),"^",1)
		f i=1:1:DiagLen {
			s OneDiagstr=$P(DiagRowIdStr,"^",i)
			s OneRowid=$P(OneDiagstr,$c(1),1)
			if (DTStype="OR"){
				s rtn=##class(DHCDoc.Log.BizLogDTS).BizLogDTSInsert("1638467400108216320", Adm, OneRowid, "", UserCode, "", "")
			}elseif(DTStype="OA"){
				s rtn=##class(DHCDoc.Log.BizLogDTS).BizLogDTSInsert("1638466556776288256", Adm, OneRowid, "", UserCode, "", "")
			}elseif(DTStype="OT"){
				s rtn=##class(DHCDoc.Log.BizLogDTS).BizLogDTSInsert("1638465646083837952", Adm, OneRowid, "", UserCode, "", "")
			}elseif(DTStype="I"){
				s rtn=##class(DHCDoc.Log.BizLogDTS).BizLogDTSInsert("1640178069782269952", Adm, OneRowid, "", UserCode, "", "")
			}
		}
		Q "0^"_DiagRowIdStr
	}
	Q err
}

ClassMethod InsertOneMRDiagnos(LogDepRowid As %String, MRAdmRowid As %String, ICDCodeRowid As %String, UserRowid As %String, MRDIADesc As %String, MRDiagTypeId As %String = "", MRDIADiagStatDesc As %String = "", MRDIASignSymDesc As %String = "", MRDIADurationNum As %String = "", MRDIADurationUnit As %String = "", DHCMRDIASignSymDesc As %String = "", DiagnosStatus As %String = "", DiagnosLeavel As %String = "", DocUserId As %String = "", MainDiaType As %String = "", SyndromeCICDStr As %String = "", SyndromeDescStr As %String = "", DiagnosPropertyInfo As %String = "", DiagnosOnsetDate As %String = "", BodyPartRowId As %String = "", DiagnosDate As %String = "", LongDiagnosFlagRowId As %String = "", MainPALongRowId As %String = "", DiagnosPrefix As %String = "", SDSTermDR As %String = "", SDSDisplayIDStr As %String = "", SDSWordID As %String = "", SDSNote As %String = "", TCMTreatmentID As %String = "") As %String
{
	;w ##class(web.DHCMRDiagnos).InsertMRDiagnos(63,1358,24167,600,"",5,"","","","","",3,1,"","N",26312,"")
	n (LogDepRowid, MRAdmRowid, ICDCodeRowid, UserRowid, MRDIADesc, MRDiagTypeId, MRDIADiagStatDesc, MRDIASignSymDesc, MRDIADurationNum, MRDIADurationUnit, DHCMRDIASignSymDesc, DiagnosStatus, DiagnosLeavel, DocUserId, MainDiaType,SyndromeCICDStr, SyndromeDescStr,DiagnosPropertyInfo,DiagnosOnsetDate,BodyPartRowId,DiagnosDate,LongDiagnosFlagRowId,MainPALongRowId,DiagnosPrefix,SDSTermDR,SDSDisplayIDStr,SDSWordID,SDSNote,TCMTreatmentID,%session)
	 s ^zhou("InsertMRDiagnos")=LogDepRowid_","_MRAdmRowid_","_ICDCodeRowid_","_UserRowid_","_MRDIADesc_","_MRDiagTypeId_","_MRDIADiagStatDesc_","_MRDIASignSymDesc_","_MRDIADurationNum_","_MRDIADurationUnit_","_DHCMRDIASignSymDesc_","_DiagnosStatus_","_DiagnosLeavel_","_DocUserId_","_MainDiaType_","_SyndromeCICDStr_","_SyndromeDescStr_","_DiagnosPropertyInfo_","_BodyPartRowId_","_LongDiagnosFlagRowId_","_MainPALongRowId
	 s HosRowid=##Class(web.CTLoc).GetHospital(LogDepRowid) 
	 TS
	 Set object = ##class(User.MRDiagnos).%New(MRAdmRowid)
	 Do object.MRDIAMRADMParRefSetObjectId(MRAdmRowid)
	 Do object.MRDIAICDCodeDRSetObjectId(ICDCodeRowid)
	////非标准诊断类型0:西医，1：中医，2症性
	IF MRDIADesc'="" {
		s DescType=$P(MRDIADesc,"#",2)
		s MRDIADesc=$P(MRDIADesc,"#",1)
		
		Do object.MRDIADesc.Insert($replace(MRDIADesc,"\",""))
		if (DescType'=""){
			s object.MRDIAQuestionnaire=DescType
		}
	}
	 s object.MRDIADate=DiagnosDate //$p($h,",",1)
	 s object.MRDIATime=..%SysTime()
	 Do object.MRDIAUpdateUserDRSetObjectId(UserRowid)
	 Do object.MRDIAUpdateHospitalDRSetObjectId(HosRowid)
	 Do object.MRDIAUpdateLocDrSetObjectId(LogDepRowid)
	 Do object.MRDIAAddLocDrSetObjectId(LogDepRowid)
	 s object.MRDIAUpdateDate=..%SysDate()
	 s object.MRDIAUpdateTime=..%SysTime()
	 s object.MRDIAAddDate=..%SysDate()
	 s object.MRDIAAddTime=..%SysTime()
	 
	 Do object.MRDIAUserCreatedDRSetObjectId(UserRowid)
	 s object.MRDIAOnsetDate=DiagnosOnsetDate
	 i DocUserId'="" {
		 s CTPCPRowId=$P(^SSU("SSUSR",DocUserId),"^",14)
		 i CTPCPRowId'="" Do object.MRDIADocCodeDRSetObjectId(CTPCPRowId)
	 }elseif UserRowid'="" {
		 s CTPCPRowId=$P(^SSU("SSUSR",UserRowid),"^",14)
		 i CTPCPRowId'="" Do object.MRDIADocCodeDRSetObjectId(CTPCPRowId)
	 }
	 s MRDIADiagStatDR=""
	 s MRDIASignSymDR=""
	 if DiagnosStatus'="" d
	 .d object.MRDIADiagStatDRSetObjectId($g(DiagnosStatus)) 
	 s object.MRDIADurationNum=MRDIADurationNum
	 s object.MRDIADurationUnit=MRDIADurationUnit
	 s object.MRDIAActive="Y"
	 s object.MRDIAAliasDiagText=DHCMRDIASignSymDesc
	 s object.MRDIAMainDiagFlag=MainDiaType
	 if $D(^DHCEMRM.DicDiagnosPositionD(+BodyPartRowId)){
	 	s object.MRDIABodyPart=BodyPartRowId
	 }
	 s object.MRDIALongDiagnosFlag=LongDiagnosFlagRowId
	 s object.MRDIADiagnosPrefix=DiagnosPrefix
	 if +DiagnosLeavel=0 s DiagnosLeavel=1
	 s object.MRDIALevel=DiagnosLeavel	// 诊断级别
	 d object.MRDIATCMTreatDRSetObjectId(TCMTreatmentID)	//中医治法
	 Set sc = object.%Save()
	 If $$$ISERR(sc) {
		 b ;Do $System.Status.DisplayError()
		 TRO
		 Quit "-201^插入诊断表失败,错误信息:"_$ZE
	 }
	 Set Rowid=object.%Id()
	 s ChildSub=$P(Rowid,"||",2)
	 Do object.%Close()
	 Set object = ##class(User.DHCMRDiagnos).%OpenId(Rowid)
	 IF DHCMRDIASignSymDesc'="" Do object.MRDIASignSymDesc.Insert(DHCMRDIASignSymDesc)
	 Set sc = object.%Save()
	 If $$$ISERR(sc) {
		 b ;Do $System.Status.DisplayError()
		 Quit "-202^插入诊断表MRDIASignSymDesc字段失败,错误信息:"_$ZE
	 }
	 //诊断知识库
	 if (DiagnosPropertyInfo'=""){
		 s rtn=##class(web.DHCMRDiagnos).SaveDiagProperty(Rowid,DiagnosPropertyInfo,UserRowid)
		 if (rtn'=0){
			 TRO
		 	 Quit "-206^插入诊断属性表失败,错误信息:"_$ZE
		 }
	 }
	 //长效诊断表
	 s Adm=$p(^MR(MRAdmRowid,"PRO",1),"^",9)
	 s PatientID=$p(^PAADM(Adm),"^",1)
	 if (LongDiagnosFlagRowId'="")&&(ICDCodeRowid'=""){
		 s SDSInfo="^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_SDSNote
		 s rtn=..SavePAlongICD(PatientID,ICDCodeRowid,LongDiagnosFlagRowId,UserRowid,MainPALongRowId,LogDepRowid,SDSInfo)
		 s err=$p(rtn,"^",1)
		 s:MainPALongRowId="" MainPALongRowId=$p(rtn,"^",2)
		 if (err'=0){
			 TRO
		 	 Quit "-207^插入长效诊断表失败,错误信息:"_$ZE
		 }
	 }
	 s SQLCODE=0
	 if MRDiagTypeId'="" {
		 if ($D(^MRC("DTYP",MRDiagTypeId))){
			 s MRDiagTypeID=MRDiagTypeId
		 }else{
		 	s MRDiagTypeID=##Class(web.MRCDiagnosType).GetIdFromCodeOrDescription($g(MRDiagTypeId))
		 }
		 i $d(^MRC("DTYP",MRDiagTypeID)) {
		 	&SQL(insert into SQLUser.MR_Diagtype (typ_parref,typ_mrcdiagtyp) values(:Rowid,:MRDiagTypeID))
		 }else{
			  s MRDiagTypeID=""
			  ;诊断类型为空则返回为失败
		 	s SQLCODE="-203^插入失败,诊断类型为空"
		 }
	 }else{
		 s MRDiagTypeID=""
		 s EpisodeID=$P($g(^MR(MRAdmRowid,"PRO",1)),"^",9)
		 s admType=""
		 i EpisodeID'="" s admType=$P($g(^PAADM(EpisodeID)),"^",2)
		 i admType'="I" s MRDiagTypeID=$O(^MRC("DTYP",0,"Code","OP",0))
		 i MRDiagTypeID'="" {
		 	&SQL(insert into SQLUser.MR_Diagtype (typ_parref,typ_mrcdiagtyp) values(:Rowid,:MRDiagTypeID))
		 }else{
			 ;诊断类型为空则返回为失败
			 s SQLCODE="-203^插入失败,诊断类型为空"
		 }
	 }
	 i SQLCODE'=0 {
		 TRO
		 Quit "-204^插入诊断子表诊断类型表失败,请重新选择诊断类型,错误信息SQLCODE:"_SQLCODE
	 }
	 ;插入主诊断记录子表
	 i MainDiaType="Y" {
		 s InsertDate=..%SysDate()
		 s InsertTime=..%SysTime()
		 &SQL(insert into SQLUser.DHCMR_DiagnosMainDiag (DMD_ParRef,DMD_Date,DMD_Time,DMD_User_DR) values(:Rowid,:InsertDate,:InsertTime,:UserRowid))
		 i SQLCODE'=0 {
			 TRO
			 Quit "-205^插入诊断子表主诊断记录表失败,错误信息:"_$ZE
		 }
	 }
	 Do object.%Close()
	 i ICDCodeRowid'="" s ^MR("0","DateICD",+$h,ICDCodeRowid,MRAdmRowid,ChildSub)=""
	 s object=""
	 //保存结构化诊断保存
	 if (SDSTermDR'="") {
		s EpisodeID=$P($g(^MR(MRAdmRowid,"PRO",1)),"^",9)
		s PatientID=$p(^PAADM(EpisodeID),"^",1)
		s PatNo=$p(^PAPER(PatientID,"PAT",1),"^",1)
		s ADMNo=$p(^PAADM(EpisodeID),"^",81)
		if (MRDiagTypeId'="") s MRDiagTypeDesc=$p($g(^MRC("DTYP",MRDiagTypeId)),"^",2)
		if (DiagnosStatus'="") s DiagnosStatusDesc=$p(^MRC("DSTAT",DiagnosStatus),"^",2)
		s DiagnosDate=+$H
		s retJSON=##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).SaveStructDiagnos(Rowid,PatNo,ADMNo,SDSTermDR,SDSDisplayIDStr,$replace(SDSNote,"\",""),"",MainDiaType,$g(MRDiagTypeDesc),$g(DiagnosStatusDesc),DiagnosLeavel,$p(Rowid,"||",2),DiagnosDate,DiagnosOnsetDate,SDSWordID)
		s retObj={}.%FromJSON(retJSON)
		if retObj.success'="true"{
			TRO
			Quit "-206^保存结构化诊断失败:"_retObj.errorinfo
		}
	 }
	 ;保存代码表常用次数
	 s SessionStr=UserRowid_"^^"_LogDepRowid
	 d ##class(DHCDoc.Log.DHCDocCTUseCount).SaveNew("User.MRCICDDx",ICDCodeRowid,SessionStr)
	 ;医生站业务数据修改日志
	 set NewDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_Rowid)
	 set ret=##class(web.DHCDocDataChangeLog).SaveLog("MR_Diagnos","User.MRDiagnos","诊断信息","User.MRDiagnos_"_Rowid,Rowid,"A",NewDataJson,"",UserRowid)
	 TC
	 ///tanjishan 中医诊断的症性是主子关系
	 if ((SyndromeCICDStr'="")||(SyndromeDescStr'=""))&&(Rowid>0){
		for i=1:1:$L(SyndromeCICDStr,"^"){
			s SyndromeCICDRowidStr=$P(SyndromeCICDStr,"^",i)
			s SyndromeCICDRowid=$p(SyndromeCICDRowidStr,$C(2),1)
			s MRDiagTypeId=$p(SyndromeCICDRowidStr,$C(2),2)
			s MainDiaType=$p(SyndromeCICDRowidStr,$C(2),3)
			s DiagnosStatus=$p(SyndromeCICDRowidStr,$C(2),4)
			s SynDiagnosOnsetDate=$p(SyndromeCICDRowidStr,$C(2),5)
			i SynDiagnosOnsetDate'="" s SynDiagnosOnsetDate=..%ZDH(SynDiagnosOnsetDate)
     	    e  s SynDiagnosOnsetDate=..%SysDate()
			s SynDiagnosDiagnosDate=$p(SyndromeCICDRowidStr,$C(2),6)
			i SynDiagnosDiagnosDate'="" s SynDiagnosDiagnosDate=..%ZDH(SynDiagnosDiagnosDate)
     	    e  s SynDiagnosDiagnosDate=..%SysDate()
     	    s LongDiagnosFlagRowId=$p(SyndromeCICDRowidStr,$C(2),7)
     	    s SynDiagnosPrefix=$p(SyndromeCICDRowidStr,$C(2),8)
			s TCMTreatmentID=$p(SyndromeCICDRowidStr,$C(2),9)
			s SyndromeDesc=$P(SyndromeDescStr,"^",i)
			continue:(SyndromeCICDRowid="")&&((SyndromeDesc="#3")||(SyndromeDesc=""))
			s rtn=..InsertOneMRDiagnos(LogDepRowid,MRAdmRowid,SyndromeCICDRowid,UserRowid,SyndromeDesc,MRDiagTypeId,MRDIADiagStatDesc,MRDIASignSymDesc,MRDIADurationNum,MRDIADurationUnit,DHCMRDIASignSymDesc,DiagnosStatus,DiagnosLeavel+1,DocUserId,MainDiaType,"","","",SynDiagnosOnsetDate,"",SynDiagnosDiagnosDate,LongDiagnosFlagRowId,MainPALongRowId,SynDiagnosPrefix,"","","","",TCMTreatmentID)	
			s SyndromeRowid=$P(rtn,"^",2)
			if ((+rtn=0)&&(SyndromeRowid'="")){
				Set object = ##class(User.MRDiagnos).%OpenId(SyndromeRowid)
				d object.MRDIAMRDIADRSetObjectId($P(Rowid,"^",1))
				Set sc = object.%Save()
				Do object.%Close()
	
			}
			s Rowid=Rowid_"^"_SyndromeRowid
		}
	}
	Quit "0^"_Rowid
}

// 诊断其他信息 诊断相关信息取值

ClassMethod GetDiagOtherInfo(EpisodeID As %String) As %String
{
	n (EpisodeID)
	s PatientID=$p(^PAADM(EpisodeID),"^",1)
	s mradm=$p(^PAADM(EpisodeID),"^",61)
	s FirstAdm=0,ReAdmis=0,OutReAdm=0,TransAdm=0,ILIFlag=0
	s FirstOrReadmis=$p(^PAADM(EpisodeID),"^",72)
    s AdmReadm=$p(^PAADM(EpisodeID),"^",56)
    s TransFlag=$p($g(^PAADM(EpisodeID,"DHC")),"^",5)
    s ILIFlag=$p($g(^PAADM(EpisodeID,"DHC")),"^",13)
    //默认初诊
    s AdmDepID=$P(^PAADM(EpisodeID),"^",4)
    //医生站设置-》医生站设置菜单-》科室功能设置-》科室扩展设置
    s DefFirstAdm=$P($G(^CTLOC(AdmDepID,"DHC")),"^",30)
    s FirstAdm=0
    s:DefFirstAdm=1 FirstAdm=1
    s AdmWayID=$p($g(^PAADM(EpisodeID,2)),"^",47)
    s AdmWay=""
    I AdmWayID'="" S AdmWay=$P(^PAC("RTR",AdmWayID),"^",1)
    if (FirstOrReadmis="R")&&(AdmWay="CYFZ") s OutReAdm=1,FirstAdm=0
    if (FirstOrReadmis="F") s FirstAdm=1
    if (AdmReadm="R")&&(AdmWay="MZFZ") s ReAdmis=1,FirstAdm=0
    if (TransFlag="Y")&&(AdmWay="ZZ") s TransAdm=1,FirstAdm=0
    if (TransFlag="Y"){
	    if (AdmReadm="R") s ReAdmis=1,FirstAdm=0
	    if (FirstOrReadmis="R") s OutReAdm=1,FirstAdm=0
	    if (FirstOrReadmis="F") s FirstAdm=1
	}
    //流感样
    if ILIFlag="Y" s ILIFlag=1
    //血压
    s BPSystolic=$p($g(^MR(mradm,"PRO",1)),"^",4)
    s BPDiastolic=$p($g(^MR(mradm,"PRO",1)),"^",5)
    i (BPSystolic="")&&(BPDiastolic=""){
	    //护理系统配置-生命体征配置-生命体征项目维护
		s BPSystolic=##Class(Nur.CommonInterface.Temperature).getLastItemValue(EpisodeID,"sysPressure")
		s BPDiastolic=##Class(Nur.CommonInterface.Temperature).getLastItemValue(EpisodeID,"diaPressure")
	}
    //体重
    s Weight=$p($g(^MR(mradm,"PRO",1)),"^",27)
    if (Weight=""){
		s Weight=##Class(Nur.CommonInterface.Temperature).getLastItemValue(EpisodeID,"weight") 
	}
    //特殊人群
    s SpecialistStr=$p($G(^MR(mradm,"DHC")),"^",8) 
    s SpecialStrCreat=""
    if (SpecialistStr'=""){
      s LengSpec=$L(SpecialistStr,"!")
      for Sub=1:1:LengSpec {
	      s SubStr=$P(SpecialistStr,"!",Sub)
	      s Va=$P(SubStr,$C(1),1)
	      continue:Va=""
	      i SpecialStrCreat="" s SpecialStrCreat=Va
	      e  s SpecialStrCreat=SpecialStrCreat_"^"_Va
     }
   }
   //生理周期
   s PhysiologicalCycleId=$p($G(^MR(mradm,"DHC")),"^",9) 
   //身高
   s Height=$p($g(^MR(mradm,"PRO",1)),"^",20)
   if (Height=""){
		s Height=##Class(Nur.CommonInterface.Temperature).getLastItemValue(EpisodeID,"height") 
   }
   
   //s PregnancyLMP=$p($g(^MR(mradm,"PRO",1)),"^",160) ;妇科信息_末次月经
   s PregnancyLMP=..GetPatPregnancyLMP(EpisodeID)
   i PregnancyLMP'="" s PregnancyLMP=..%ZD(PregnancyLMP)
   s PregnancyG=$P($G(^PAPER(PatientID,"PER",4)),"^",26) ;妇科信息_孕次
   s PregnancyP=$P($G(^PAPER(PatientID,"PER",4)),"^",27) ;妇科信息_产次
   s PregnancyA=$P($G(^PAPER(PatientID,"PER",4)),"^",28) ;妇科信息_流次
   s PregnancyL=$P($G(^PAPER(PatientID,"PER",4)),"^",29) ;妇科信息_存活
   
   s OtherInfo=FirstAdm_$c(1)_ReAdmis_$c(1)_OutReAdm_$c(1)_TransAdm_$c(1)_ILIFlag_$c(1)_BPSystolic_$c(1)_BPDiastolic_$c(1)_Weight_$c(1)_SpecialStrCreat_$c(1)_PhysiologicalCycleId_$C(1)_Height
   s OtherInfo=OtherInfo_$c(1)_PregnancyLMP_$c(1)_PregnancyG_$c(1)_PregnancyP_$c(1)_PregnancyA_$c(1)_PregnancyL
   Q OtherInfo
}

ClassMethod GetICDInfoByICDDr(MRCICDDr As %String, EpisodeID = "") As %String
{
	n (MRCICDDr,EpisodeID,%session)
	Set langid=..%LanguageID()
	s MRCIDCode=$p(^MRC("ID",MRCICDDr),"^",4)
	s MRCIDDesc=$p(^MRC("ID",MRCICDDr),"^",2)
	s MRCIDDesc=##class(User.MRCICDDx).GetTranByDesc("MRCIDDesc",MRCIDDesc,langid)
	s DiagnosCatRowId=##class(DHCDoc.Diagnos.Common).GetICDCatID(MRCICDDr)-1
	s DiagnosCat=##class(DHCDoc.Diagnos.Common).GetDiagCatByID(DiagnosCatRowId+1)
	s InvalidInfo=##class(web.DHCMRDiagnos).CheckICDIsEnabled(MRCICDDr,EpisodeID)
	Q MRCIDCode_"^"_MRCIDDesc_"^"_DiagnosCatRowId_"^"_DiagnosCat_"^"_InvalidInfo
}

/// V8诊断录入所用方法
/// w ##Class(web.DHCDocDiagnosEntryV8).GetDataFromHistMRDiag("688")
/// @param 诊断表ID
/// 返回值 主诊断ICDRowid_$C(2)_主诊断备注_$C(1)_子诊断ICDRowid_$C(2)_子诊断备注
ClassMethod GetDataFromHistMRDiag(MRDIADr As %String) As %String
{
	s DiagRtn=""
	Set langid=..%LanguageID()
	s MainMRDIADr=$P($g(^MR(+MRDIADr,"DIA",$p(MRDIADr,"||",2))),"^",15)
	if (MainMRDIADr'="") s MRDIADr=MainMRDIADr
	
	s MradmRowid=$p(MRDIADr,"||",1)
	s MrICDSub=$p(MRDIADr,"||",2)
	s ICDRowid=$p(^MR(MradmRowid,"DIA",MrICDSub),"^",1)
	s MRDIADesc=$g(^MR(MradmRowid,"DIA",MrICDSub,"DES",1))
	Q:(MRDIADesc="")&&(ICDRowid="") ""
	s DiagnosPrefix=$P($G(^MR(MradmRowid,"DIA",MrICDSub,1)),"^",26)
	if (ICDRowid'="") {
		s DiagnosCatRowId=..GetICDInfoByICDDr(ICDRowid)
	}else{
		s Questionnaire=$P($G(^MR(MradmRowid,"DIA",MrICDSub)),"^",22)
		s DiagnosCatRowId=$case(Questionnaire,1:0,2:1,3:2)
	}
	s DiagRtn=ICDRowid_$C(2)_MRDIADesc_$C(2)_DiagnosCatRowId_$C(2)_DiagnosPrefix
	s sub=0
	for {
		s sub=$o(^MR(MradmRowid,"DIA",0,"Link",MRDIADr,sub))
		q:sub=""
		s ICDRowid=$p(^MR(MradmRowid,"DIA",sub),"^",1)
		s MRDIADesc=$g(^MR(MradmRowid,"DIA",sub,"DES",1))
		continue:(ICDRowid="")&&(MRDIADesc="")
		s SubDiagnosPrefix=$P($G(^MR(MradmRowid,"DIA",sub,1)),"^",26)
		s DiagRtn=DiagRtn_$C(1)_ICDRowid_$C(2)_MRDIADesc_$C(2)_2_$C(2)_SubDiagnosPrefix
	}
    q DiagRtn
}

ClassMethod GetHistoryMRDiagnoseClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetHistoryMRDiagnoseExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

ClassMethod GetHistoryMRDiagnoseExecute(ByRef qHandle As %Binary, PatientID As %String, ICDType As %String = "", CurDep As %String = "") As %Status
{
	s ^gry("GetHistoryMRDiagnose")=PatientID_","_ICDType_","_CurDep
	;d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","GetHistoryMRDiagnose",64,"All")
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	s desc="",rowid="",mrdesc=""
	if (PatientID=""){
		Set qHandle=$lb(0,repid,0)
		Quit $$$OK
	}
	k DiaList
	s InGroupStr=""
	s Paadmtype=0 
	for{
		s Paadmtype=$o(^PAPERdr(PatientID,"ADM",Paadmtype))
		q:Paadmtype=""
    	s PaadmRowid=0
    	for{
	    	s PaadmRowid=$o(^PAPERdr(PatientID,"ADM",Paadmtype,PaadmRowid))
	    	q:PaadmRowid=""
			s MradmRowid=$P(^PAADM(PaadmRowid),"^",61)
			s MrICDSub=0
			for{
				s MrICDSub=$o(^MR(MradmRowid,"DIA",MrICDSub))
				q:MrICDSub=""
				continue:$g(^MR(MradmRowid,"DIA",MrICDSub))=""
				s ICDRowid=$p(^MR(MradmRowid,"DIA",MrICDSub),"^",1)
				s MainMRDIADr=$P($g(^MR(MradmRowid,"DIA",MrICDSub)),"^",15)
				
				continue:(MainMRDIADr'="")
				//w "1:"_ICDRowid_","_MradmRowid_"||"_MrICDSub,!
				s desc="",BillFlag3="",mrdesc=""
				s ICDCommSub=0
				s ICDCommSub=$o(^MR(MradmRowid,"DIA",MrICDSub,"DES",ICDCommSub))
				if ICDCommSub'="" s mrdesc=$p(^MR(MradmRowid,"DIA",MrICDSub,"DES",ICDCommSub),"^",1)
				if ICDRowid'="" s BillFlag3=$p($g(^MRC("ID",ICDRowid)),"^",15)
				continue:(ICDType="1")&&(BillFlag3'="Y")&&(ICDType'="All")
				continue:(ICDType'="1")&&(BillFlag3="Y")&&(ICDType'="All")
				s GroupICDRowIDStr=..GetGroupICDRowIDStr(MradmRowid_"||"_MrICDSub)
				//w "2:"_ICDRowid_","_MradmRowid_"||"_MrICDSub_","_GroupICDRowIDStr,!
				continue:(GroupICDRowIDStr="")
				s Count=$I(DiaList(GroupICDRowIDStr))
				if $D(DiaList(GroupICDRowIDStr,"Detail")){
					s DiaList(GroupICDRowIDStr,"Detail")=DiaList(GroupICDRowIDStr,"Detail")_","_MradmRowid_"||"_MrICDSub
				}else{
					s DiaList(GroupICDRowIDStr,"Detail")=MradmRowid_"||"_MrICDSub
				}
				
			}
    	}
	}
	
	s GroupICDRowIDStr=""
	for {
		s GroupICDRowIDStr=$O(DiaList(GroupICDRowIDStr))
		q:(GroupICDRowIDStr="")
		s Count=DiaList(GroupICDRowIDStr)
		
		s Desc=""
		for i=1:1:$L(GroupICDRowIDStr,"!"){
			s ICDRowID=$P(GroupICDRowIDStr,"!",i)
			if $D(^MRC("ID",ICDRowID)){
				s ICDDesc=$p(^MRC("ID",ICDRowID),"^",2)
			}else{
				s ICDDesc=ICDRowID
			}
			if (Desc=""){
				s Desc=ICDDesc
			}else{
				s Desc=Desc_","_ICDDesc
			}
		}
		s MRAdmList=$G(DiaList(GroupICDRowIDStr,"Detail"))
		s Data=$lB(Desc,Count,MRAdmList)
		s ind=ind+1
		s ^CacheTemp(repid,ind)=Data
	}
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
}

ClassMethod GetHistoryMRDiagnoseFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetHistoryMRDiagnoseExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {			// if there are no more rows, finish fetching
	 Set AtEnd=1
	 Set Row=""
	}
	Else {				// fetch row
	 Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

Query GetHistoryMRDiagnose(PatientID As %String, ICDType As %String = "", CurDep As %String = "") As %Library.Query(CONTAINID = 0, ROWSPEC = "Desc:%String,Count:%String,MRAdmList:%String")
{
}

/// w ##Class(web.DHCDocDiagnosEntryV8).GetHistoryMRDiagnoseJson("737","O,E,P,H","半年",6)
ClassMethod GetHistoryMRDiagnoseJson(PatientID As %String, AdmType As %String, SearchYear As %String, LoginCTLOC As %String) As %String
{
	s ^tan("GetHistoryMRDiagnoseJson")=""""_PatientID_""","""_AdmType_""","""_SearchYear_""","""_LoginCTLOC
	//住院按照入院诊断->初步诊断->【其他类型诊断】->出院诊断显示,非住院按照诊断类型表(MRC_DiagnosType)ID先后顺序显示
	//各个诊断类型下的诊断按照诊断录入先后顺序显示
	k DiaTypeIndexList,DiaTypeList
	Set langid=..%LanguageID()
    s LogonHospDr=""
    if (LoginCTLOC'="") s LogonHospDr=$p(^CTLOC(LoginCTLOC),"^",22)
    s LogonHospDr=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(LogonHospDr)
	s DTYPRowId=0,OtherDTYPCount=3
	for {
		s DTYPRowId=$o(^MRC("DTYP",DTYPRowId))
		Q:DTYPRowId=""
		s DTYPCode=$p(^MRC("DTYP",DTYPRowId),"^",1)
		if (DTYPCode="C008") { //入院诊断
			s DiaTypeIndexList(DTYPCode)=1
			s DiaTypeList(1)=DTYPRowId
		}elseif (DTYPCode="PRE"){ //初步诊断
			s DiaTypeIndexList(DTYPCode)=2
			s DiaTypeList(2)=DTYPRowId
		}elseif (DTYPCode'="DIS"){ //其他类型(非入院、、出院、初步)
			s DiaTypeIndexList(DTYPCode)=OtherDTYPCount
			s DiaTypeList(OtherDTYPCount)=DTYPRowId
			s OtherDTYPCount=OtherDTYPCount+1
		}
	}
	s DiaTypeIndexList("DIS")=OtherDTYPCount
	s DiaTypeList(OtherDTYPCount)=$O(^MRC("DTYP",0,"Code","DIS",0))
	s YearStartDate=..%SysDate(),YearStartDate=YearStartDate-365,HalfYearStartDate=YearStartDate-(6*30)
	k DiaList,DiaRepeatList
	s InGroupStr=""
	s Paadmtype=0 
	for{
		s Paadmtype=$o(^PAPERdr(PatientID,"ADM",Paadmtype))
		q:Paadmtype=""
		if (AdmType'="")&&(AdmType'="ALL")&&(AdmType'[Paadmtype){
			continue	
		}
    	s PaadmRowid=0
    	for{
	    	s PaadmRowid=$o(^PAPERdr(PatientID,"ADM",Paadmtype,PaadmRowid))
	    	q:PaadmRowid=""
	    	s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(PaadmRowid)
 			continue:LogonHospDr'=AdmHospitalId
	    	s AdmLoc=$P(^PAADM(PaadmRowid),"^",4)
	    	if (AdmLoc=LoginCTLOC){ //历史诊断默认优先显示本科诊断,其次按照就诊日期倒叙排列
		    	s LocIndex=1
		    }else{
			    s LocIndex=2
			}
	    	s AdmDate=$P(^PAADM(PaadmRowid),"^",6)
			s Year=$P($ZD(AdmDate,3),"-")
			if (SearchYear="半年"){
				if (AdmDate<HalfYearStartDate) {continue}
			}elseif(SearchYear="一年"){
				if (AdmDate<YearStartDate) {continue}
			}else{
				if (SearchYear'="")&&(SearchYear'=Year){continue}
			}
			s MradmRowid=$P(^PAADM(PaadmRowid),"^",61)
			s MrICDSub=0
			for{
				s MrICDSub=$o(^MR(MradmRowid,"DIA",MrICDSub))
				q:MrICDSub=""
				continue:$g(^MR(MradmRowid,"DIA",MrICDSub))=""
				s ICDRowid=$p(^MR(MradmRowid,"DIA",MrICDSub),"^",1)
				s MainMRDIADr=$P($g(^MR(MradmRowid,"DIA",MrICDSub)),"^",15)
				continue:(MainMRDIADr'="")
				s GroupICDRowIDStr=..GetGroupICDRowIDStr(MradmRowid_"||"_MrICDSub)
				continue:(GroupICDRowIDStr="")
				s MRDiagnosTypeDesc="",MRDiagnosTypeDr="",MRDiagnosTypeCode=""
				S SubRowid=$G(^MR(MradmRowid,"DIA",MrICDSub,"TYP",0))
				if SubRowid'="" {
					s MRDiagnosTypeDr=$G(^MR(MradmRowid,"DIA",MrICDSub,"TYP",SubRowid))
					s MRDiagnosTypeCode=$p(^MRC("DTYP",MRDiagnosTypeDr),"^",1)
				}
				s MRDIAAddDate=$p(^MR(MradmRowid,"DIA",MrICDSub),"^",42)
				s MRDIAAddTime=$p(^MR(MradmRowid,"DIA",MrICDSub),"^",41)
				continue:$d(DiaRepeatList(PaadmRowid,MRDiagnosTypeDr,GroupICDRowIDStr))
				s DiaRepeatList(PaadmRowid,MRDiagnosTypeDr,GroupICDRowIDStr)=1
				if (Paadmtype="I") {
					s MRDiagnosTypeIndex=DiaTypeIndexList(MRDiagnosTypeCode)
					s DiaList(LocIndex,PaadmRowid,MRDiagnosTypeIndex_" ",MRDIAAddDate_MRDIAAddTime,GroupICDRowIDStr)=MradmRowid_"||"_MrICDSub
				}else{
					s DiaList(LocIndex,PaadmRowid,MRDiagnosTypeDr_" ",MRDIAAddDate_MRDIAAddTime,GroupICDRowIDStr)=MradmRowid_"||"_MrICDSub
				}
			}
    	}
	}
	s AdmDiagDataAll=[]
	s Index=0,MainIndex=0
	s LocIndex=0
	for {
		s LocIndex=$O(DiaList(LocIndex))
		Q:LocIndex=""
		s PaadmRowid=""
		for {
			s PaadmRowid=$O(DiaList(LocIndex,PaadmRowid),-1)
			q:PaadmRowid=""
			s AdmType=$P(^PAADM(PaadmRowid),"^",2)
			s AdmDate=$P(^PAADM(PaadmRowid),"^",6)
			s AdmDate=..%ZD(AdmDate)
			s AdmLocDr=$P(^PAADM(PaadmRowid),"^",4)
			s AdmLocDesc=$P(^CTLOC(AdmLocDr),"^",2)
			s AdmLocDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",AdmLocDesc,langid)
			i AdmLocDesc["-" s AdmLocDesc=$P(AdmLocDesc,"-",2)
			Set AdmDoctorDr=$P($g(^PAADM(PaadmRowid)),"^",9)
			If AdmDoctorDr'="" {
				Set AdmDoctor=$P($g(^CTPCP(AdmDoctorDr,1)),"^",2)
				Set AdmDoctor= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",AdmDoctor,langid)
			}else{
				s AdmDoctor=""
			}
			s text=AdmDate_" "_AdmLocDesc
			i AdmDoctor'="" s text=text_" "_AdmDoctor
			s text=##class(ext.util.String).EvalJSON(text)
			s Index=Index+1,MainIndex=MainIndex+1
			
			s oneAdmDiagData={} //单个就诊信息
			d oneAdmDiagData.%Set("id",Index)
			d oneAdmDiagData.%Set("text",text)
			d oneAdmDiagData.%Set("attributes",{"MRDIARowID":"","DiagnosType":""})
			
			s DiagTypeDataAll=[]
			s MRDiagnosTypeIndex=0,SubIndex=0
			for{
				s DiagDataAll=[]
				s MRDiagnosTypeIndex=$O(DiaList(LocIndex,PaadmRowid,MRDiagnosTypeIndex))
				q:MRDiagnosTypeIndex=""
				if (AdmType="I") {
					s MRDiagnosTypeDr=$G(DiaTypeList($TR(MRDiagnosTypeIndex," ","")))
				}else{
					s MRDiagnosTypeDr=MRDiagnosTypeIndex
				}
				s MRDiagnosTypeDesc=""
				s DiagnosType=+MRDiagnosTypeDr
				i DiagnosType=0 s DiagnosType=""
				i +DiagnosType'=0 d
				.Set MRDiagnosTypeDesc=$P($G(^MRC("DTYP",+DiagnosType)),"^",2)
				.Set MRDiagnosTypeDesc= ##class(User.MRCDiagnosType).GetTranByDesc("DTYPDesc",MRDiagnosTypeDesc,langid)
				s text=$TR(MRDiagnosTypeDesc," ","")
				s text=##class(ext.util.String).EvalJSON(text)
				if (text'=""){
					s Index=Index+1,SubIndex=SubIndex+1
					s oneDiagTypeData={}
					d oneDiagTypeData.%Set("id",Index)
					d oneDiagTypeData.%Set("text",text)
					
					s oneDiagTypeAttriData={}
					d oneDiagTypeAttriData.%Set("MRDIARowID","")
					d oneDiagTypeAttriData.%Set("DiagnosType",DiagnosType)
					d oneDiagTypeData.%Set("attributes",oneDiagTypeAttriData)
				}
				s datetime=0
				for {
					s datetime=$o(DiaList(LocIndex,PaadmRowid,MRDiagnosTypeIndex,datetime)) q:datetime=""
					
					s GroupICDRowIDStr=0,GroupICDIndex=0
					for {
						s GroupICDRowIDStr=$O(DiaList(LocIndex,PaadmRowid,MRDiagnosTypeIndex,datetime,GroupICDRowIDStr))
						q:GroupICDRowIDStr=""
						s Desc=""
						for i=1:1:$L(GroupICDRowIDStr,"!"){
							s ICDRowID=$P(GroupICDRowIDStr,"!",i)
							if $D(^MRC("ID",ICDRowID)){
								s ICDDesc=$p(^MRC("ID",ICDRowID),"^",2)
								s ICDDesc =##class(User.MRCICDDx).GetTranByDesc("MRCIDDesc",ICDDesc,langid)
							}else{
								s ICDDesc=$p(ICDRowID,"Desc:",2) //$TR(ICDRowID,"Desc:","") //$TR会把描述中含有s的字符替换为空
								if (ICDDesc="") s ICDDesc=ICDRowID
							}
							if (Desc=""){
								s Desc=ICDDesc
							}else{
								s Desc=Desc_","_ICDDesc
							}
						}
						s Desc=##class(ext.util.String).EvalJSON(Desc)
						s MRDIARowID=$G(DiaList(LocIndex,PaadmRowid,MRDiagnosTypeIndex,datetime,GroupICDRowIDStr))
						s Index=Index+1,GroupICDIndex=GroupICDIndex+1
						s oneDiagData={}
						d oneDiagData.%Set("Index",Index)
						d oneDiagData.%Set("text",Desc)
						
						s oneDiagDataAttriData={}
						d oneDiagDataAttriData.%Set("MRDIARowID",MRDIARowID)
						d oneDiagDataAttriData.%Set("DiagnosType","")
						d oneDiagData.%Set("attributes",oneDiagDataAttriData)
						d DiagDataAll.%Push(oneDiagData)
					}
					d oneDiagTypeData.%Set("children",DiagDataAll)
				}
				d DiagTypeDataAll.%Push(oneDiagTypeData)
			}
			d oneAdmDiagData.%Set("children",DiagTypeDataAll)	
			d AdmDiagDataAll.%Push(oneAdmDiagData)		
		}
	}
	w AdmDiagDataAll.%ToJSON()
	Q ""
}

/// w ##Class(web.DHCDocDiagnosEntryV8).GetHistoryMRDiagnoseDataJson(6736269)
ClassMethod GetHistoryMRDiagnoseDataJson(PatientID As %String) As %String
{
	k DiaList
	Set langid=..%LanguageID()
	s YearStartDate=..%SysDate()-365,HalfYearStartDate=..%SysDate()-(6*30)
	s YearFlag=0,HalfYearFlag=0
	s JsonData=""
	s Paadmtype=0 
	for{
		s Paadmtype=$o(^PAPERdr(PatientID,"ADM",Paadmtype))
		q:Paadmtype=""
    	s PaadmRowid=0
    	for{
	    	s PaadmRowid=$o(^PAPERdr(PatientID,"ADM",Paadmtype,PaadmRowid))
	    	q:PaadmRowid=""
			s AdmDate=$P(^PAADM(PaadmRowid),"^",6)
			s Year=$P($ZD(AdmDate,3),"-")
			s DiaList(Year)=""
			if (AdmDate>=HalfYearStartDate){
				s YearFlag=1,HalfYearFlag=1
			}
			if (AdmDate>=YearStartDate){
				s YearFlag=1
			}
    	}
	}
	s Index=0
	s JsonData="{"
	if (HalfYearFlag=1){
		s Year= "半年"
		s JsonData=JsonData_"""selected"":true,"
		s JsonData=JsonData_"""id"":"""_Year_""","
		s JsonData=JsonData_"""text"":"""_..%Translate("diagnosentry.v8.csp","半年")_""""
		s JsonData=JsonData_"}"
		
		s Year="一年"
		s JsonData=JsonData_",{"
		s JsonData=JsonData_"""id"":"""_Year_""","
		s JsonData=JsonData_"""text"":"""_..%Translate("diagnosentry.v8.csp","一年")_""""
		s JsonData=JsonData_"}"
		
		
	}elseif(YearFlag=1){
		s Year="一年"
		s JsonData=JsonData_"""selected"":true,"
		s JsonData=JsonData_"""id"":"""_Year_""","
		s JsonData=JsonData_"""text"":"""_..%Translate("diagnosentry.v8.csp","一年")_""""
		s JsonData=JsonData_"}"
	}
	s Year=""
	for {
		s Year=$O(DiaList(Year),-1)
		q:Year=""
		if (JsonData'="{"){
			s JsonData=JsonData_",{"
		}else{
			s JsonData=JsonData_"""selected"":true,"
		}
		s JsonData=JsonData_"""id"":"""_Year_""","
		s JsonData=JsonData_"""text"":"""_Year_""""
		s JsonData=JsonData_"}"
	}
	i JsonData="{" s JsonData=JsonData_"}"
	s JsonData="["_JsonData_"]"
	q JsonData
}

/// w ##Class(web.DHCDocDiagnosEntryV8).GetGroupICDRowIDStr("107||1")
ClassMethod GetGroupICDRowIDStr(MRDiagnosRowid As %String) As %String
{
	n (MRDiagnosRowid)
	k ICDRowIDList
	s MRADMRowId=+MRDiagnosRowid
	s MainDiagnosRowid=""
	s MainDiagnosRowid=$P($G(^MR(MRADMRowId,"DIA",$P(MRDiagnosRowid,"||",2))),"^",15)
	if (MainDiagnosRowid="") {
		s MainDiagnosRowid=MRDiagnosRowid
	}
	s MainICDRowid=$p(^MR(MRADMRowId,"DIA",$P(MainDiagnosRowid,"||",2)),"^",1)
	if (MainICDRowid=""){
		///描述信息作为ID使用
		s MainICDRowid="Desc:"_$G(^MR(MRADMRowId,"DIA",$P(MainDiagnosRowid,"||",2),"DES",1))
	}
	s OutPutStr=MainICDRowid
	s Sub=0
	for {
		s Sub=$O(^MR(MRADMRowId,"DIA",0,"Link",MainDiagnosRowid,Sub))
		q:Sub=""
		s SubRowID=MRADMRowId_"||"_Sub
		s ICDRowid=$p(^MR(MRADMRowId,"DIA",Sub),"^",1)
		if (ICDRowid=""){
			///描述信息作为ID使用
			;s ICDRowid=$G(^MR(MRADMRowId,"DIA",Sub,"DES",1))
			s ICDRowid="Desc:"_$G(^MR(MRADMRowId,"DIA",Sub,"DES",1))
		}
		s ICDRowIDList(Sub,ICDRowid)=""
	}
	s Sub=0
	for {
		s Sub=$o(ICDRowIDList(Sub)) Q:Sub=""
		s ICDRowid=0
		for {
			s ICDRowid=$O(ICDRowIDList(Sub,ICDRowid)) q:ICDRowid=""
			s OutPutStr=OutPutStr_"!"_ICDRowid
		}
	}
	k ICDRowIDList
	q OutPutStr
}

ClassMethod HisMRDiagRepClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = HisMRDiagRepExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

// 2075 9||6

// d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","HisMRDiagRep",64,"79||99,79||107")

ClassMethod HisMRDiagRepExecute(ByRef qHandle As %Binary, PatientID As %String, MRAdmList As %String) As %Status
{
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	s MrICDRowID=$p(MRAdmList,",")
	s ICDRowIDList=##Class(web.DHCDocDiagnosEntryV8).GetGroupICDRowIDStr(MrICDRowID)
	s ICDDescList=""
	for i=1:1:$L(ICDRowIDList,"!"){
		s ICDRowID=$P(ICDRowIDList,"!",i)
		if $D(^MRC("ID",ICDRowID)){
			s ICDDesc=$p(^MRC("ID",ICDRowID),"^",2)
		}else{
			s ICDDesc=ICDRowID
		}
		if (ICDDescList=""){
			s ICDDescList=ICDDesc
		}else{
			s ICDDescList=ICDDescList_","_ICDDesc
		}
	}
	
	
	k HisMRDiagRepList
	for i=1:1:$L(MRAdmList,",") {
		s MrICDRowID=$p(MRAdmList,",",i)
		s MradmRowid=$P(MrICDRowID,"||",1)
		s MrICDSub=$P(MrICDRowID,"||",2)
		
		s PAAdmRowID=$P(^MR(MradmRowid,"PRO",1),"^",9)
		s AdmDate=$P(^PAADM(PAAdmRowID),"^",6)
		s AdmDep=$P(^PAADM(PAAdmRowID),"^",4)
		i AdmDep'="" s AdmDep=$p($g(^CTLOC(AdmDep)),"^",2)
		s doctorRowid=$p(^MR(MradmRowid,"DIA",MrICDSub),"^",4)
		s DoctDesc=""
		i doctorRowid'="" S DoctDesc=$P($G(^CTPCP(doctorRowid,1)),"^",2)
		s MRDate=$p($g(^MR(MradmRowid,"DIA",MrICDSub)),"^",7)
		if MRDate'="" set MRDate=..%ZD(MRDate) //$zd(MRDate,3)
		s MRtime=$p($g(^MR(MradmRowid,"DIA",MrICDSub)),"^",8)
		if MRtime'="" Set MRtime=..%ZT(MRtime,3)
		s Data=$lb(MrICDRowID,ICDDescList,DoctDesc,MRDate,MRtime,AdmDep)
		s HisMRDiagRepList(PAAdmRowID,MrICDSub)=Data
	}
	s PAAdmRowID=""
	for {
		s PAAdmRowID=$O(HisMRDiagRepList(PAAdmRowID),-1)
		q:PAAdmRowID=""
		s loop=""
		for {
			s loop=$O(HisMRDiagRepList(PAAdmRowID,loop),-1)
			q:loop=""
			set Data=HisMRDiagRepList(PAAdmRowID,loop)
			d HisMRDiagRepOutPut
		}
	}
	
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
HisMRDiagRepOutPut
	
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	Quit
}

ClassMethod HisMRDiagRepFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = HisMRDiagRepExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	//
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {			// if there are no more rows, finish fetching
	 Set AtEnd=1
	 Set Row=""
	}
	Else {				// fetch row
	 Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

Query HisMRDiagRep(PatientID As %String, MRAdmList As %String) As %Library.Query(CONTAINID = 0, ROWSPEC = "Rowid:%String,Desc:%String,DoctDesc:%String,MRDate:%String,MRtime:%String,AdmDep:%String")
{
}

/// 复制诊断
ClassMethod CopyMulDiag(ADiagnosIDStr As %String, ALocId As %String, AUserId As %String, CopyToDiagTypeId As %String, AdmPara As %String) As %String
{
	n (ADiagnosIDStr,ALocId,AUserId,CopyToDiagTypeId,AdmPara,%session)
	;s ^tempscl("CopyMulDiag")=ADiagnosIDStr_","_ALocId_","_AUserId_","_CopyToDiagTypeId_","_AdmPara
	s HospID=##class(DHCDoc.Common.Hospital).GetLocHospitalId(ALocId)
	s MainDiagLimitStr="^"_..%GetConfig("MainDiagLimit",HospID)_"^"
	s MRAdmRowid=+ADiagnosIDStr
	s Adm=$p($G(^MR(MRAdmRowid,"PRO",1)),"^",9)
	s DiagTypeCode=$P(^MRC("DTYP",CopyToDiagTypeId),"^",1)
	s ExistMainDiagFlag=(##class(DHCDoc.Diagnos.Common).GetAdmDiagDesc(Adm,DiagTypeCode,"Y")'="")
	s RtnStr=""
	For i1=1:1:$l(ADiagnosIDStr,"^"){
		s ADiagnosID=$p(ADiagnosIDStr,"^",i1)
		s MRAdmRowid=+ADiagnosID
		s CopyDiagInfo=..GetCopyDiagInfo(ADiagnosID)
		s ICDCodeRowid=$p(CopyDiagInfo,"^",1)
		s MRDIADesc=$p(CopyDiagInfo,"^",2)
		s MRDiagTypeId=CopyToDiagTypeId
		s DiagnosStatus=$p(CopyDiagInfo,"^",3)
		s MRDIAOnsetDate=$p(CopyDiagInfo,"^",5)
		s MainDiaType=$p(CopyDiagInfo,"^",6)
		s DiagnosLeavel=$p(CopyDiagInfo,"^",7)
		s DiagnosPrefix=$p(CopyDiagInfo,"^",8)
		s MRDIAQuestionnaire=$p(CopyDiagInfo,"^",9)
		s SDSTermDR=$p(CopyDiagInfo,"^",10)
		s SDSDisplayIDStr=$p(CopyDiagInfo,"^",11)
		s SDSWordID=$p(CopyDiagInfo,"^",12)
		s Supplement=$p(CopyDiagInfo,"^",13)
		if (MRDIADesc'="") s MRDIADesc=MRDIADesc_"#"_MRDIAQuestionnaire
		
		if ExistMainDiagFlag&&(MainDiagLimitStr[("^"_CopyToDiagTypeId_"^"))&&(MainDiaType="Y"){
			s MainDiaType="N"
		}
		if 'ExistMainDiagFlag&&(MainDiaType="Y") s ExistMainDiagFlag=1

		s DiagItemStr=""_"^"_MRDIADesc_"^"_ICDCodeRowid_"^"_MRDiagTypeId_"^"_MainDiaType_"^"_DiagnosStatus_"^"_MRDIAOnsetDate
		s DiagItemStr=DiagItemStr_"^^^^^^"_DiagnosPrefix_"^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_Supplement
		s $p(DiagItemStr,"^",19)=DiagnosLeavel
		s rtn=..InsertMRDiagnos(MRAdmRowid,DiagItemStr,AdmPara,ALocId,AUserId)
		if (+rtn=0){
			s MainDiagRowid=$p($P(rtn,"^",2),$C(1),1)
			i RtnStr="" s RtnStr=$P(rtn,"^",2)
			e  s RtnStr=RtnStr_"^"_$P(rtn,"^",2)
			s SunDiagRowidStr=##class(web.DHCMRDiagnos).GetGroupMRDia(ADiagnosID)
			for m1=2:1:$Length(SunDiagRowidStr,"^") {
				s OneSubDiagRowid=$P(SunDiagRowidStr,"^",m1)
				continue:+OneSubDiagRowid=0
				s rtn=..CopySubMulDiag(OneSubDiagRowid,ALocId,AUserId,CopyToDiagTypeId,AdmPara)
				if (+rtn=0){ //MRDIA_MRDIA_DR
					s SubDiagRowid=$p($P(rtn,"^",2),$C(1),1)
					Set object = ##class(User.MRDiagnos).%OpenId(SubDiagRowid)
					d object.MRDIAMRDIADRSetObjectId(MainDiagRowid)
					Set sc = object.%Save()
					Do object.%Close()
					s $P(^MR(+SubDiagRowid,"DIA",$P(SubDiagRowid,"||",2),"EPR"),"^",1)=2
					;复制中医治法
					s TCMTreatmentID=$P($G(^MR(+OneSubDiagRowid,"DIA",$P(OneSubDiagRowid,"||",2),1)),"^",29)
					s $P(^MR(+SubDiagRowid,"DIA",$P(SubDiagRowid,"||",2),1),"^",29)=TCMTreatmentID
					s RtnStr=RtnStr_"^"_$P(rtn,"^",2)
				}
			}
		}
	}
	Q "0^"_RtnStr
}

ClassMethod CopySubMulDiag(ADiagnosID As %String, ALocId As %String, AUserId As %String, CopyToDiagTypeId As %String, AdmPara As %String) As %String
{
	n (ADiagnosID,ALocId,AUserId,CopyToDiagTypeId,AdmPara,%session)
	s MRAdmRowid=+ADiagnosID
	s CopyDiagInfo=..GetCopyDiagInfo(ADiagnosID)
	s ICDCodeRowid=$p(CopyDiagInfo,"^",1)
	s MRDIADesc=$p(CopyDiagInfo,"^",2)
	s MRDiagTypeId=CopyToDiagTypeId
	s DiagnosStatus=$p(CopyDiagInfo,"^",3)
	s MRDIAOnsetDate=$p(CopyDiagInfo,"^",5)
	s MainDiaType=$p(CopyDiagInfo,"^",6)
	s DiagnosLeavel=$p(CopyDiagInfo,"^",7)
	s DiagnosPrefix=$p(CopyDiagInfo,"^",8)
	s MRDIAQuestionnaire=$p(CopyDiagInfo,"^",9)
	s SDSTermDR=$p(CopyDiagInfo,"^",10)
	s SDSDisplayIDStr=$p(CopyDiagInfo,"^",11)
	s SDSWordID=$p(CopyDiagInfo,"^",12)
	if (MRDIADesc'="") s MRDIADesc=MRDIADesc_"#"_MRDIAQuestionnaire
	s DiagItemStr=""_"^"_MRDIADesc_"^"_ICDCodeRowid_"^"_MRDiagTypeId_"^"_MainDiaType_"^"_DiagnosStatus_"^"_MRDIAOnsetDate
	s DiagItemStr=DiagItemStr_"^^^^^^"_DiagnosPrefix_"^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID
	s $p(DiagItemStr,"^",19)=DiagnosLeavel
	s rtn=..InsertMRDiagnos(MRAdmRowid,DiagItemStr,AdmPara,ALocId,AUserId)
	Q rtn
}

ClassMethod GetCopyDiagInfo(ADiagnosID As %String) As %String
{
	n (ADiagnosID)
	s DiagInfo=""
	s MrAdm=+ADiagnosID
	s MRDIAChildsub=$p(ADiagnosID,"||",2)
	s MRDIAICDCodeDR=$p(^MR(MrAdm,"DIA",MRDIAChildsub),"^",1) 
	//MRDIA_DocCode_DR
	//MRDIA_Date MRDIA_Time
	s MRDIADesc=$g(^MR(MrAdm,"DIA",MRDIAChildsub,"DES",1))
	s MRDIADiagStatDR=$p(^MR(MrAdm,"DIA",MRDIAChildsub),"^",9)
	s MRDIASignSymDR=$p(^MR(MrAdm,"DIA",MRDIAChildsub),"^",10)
	//MRDIA_UpdateUser_DR
	//MRDIA_MRDIA_DR
	//MRDIA_UpdateHospital_DR
	//MRDIA_UpdateDate
	//MRDIA_UpdateTime
	//	MRDIA_UserCreated_DR
	//MRDIA_Active
	s MRDIAOnsetDate=$p(^MR(MrAdm,"DIA",MRDIAChildsub),"^",35)
	s MRDIAMainDiagFlag=$p(^MR(MrAdm,"DIA",MRDIAChildsub,1),"^",20)
	s DiagnosLeavel=$p(^MR(MrAdm,"DIA",MRDIAChildsub,"EPR"),"^",1)
	/*
	set ^MR(MrAdmID,"DIA",SubID,"EPR") = ALevel_"^"_SubID_"^"_AEvaluationID_"^"_AEffect
       set ^MR(MrAdmID,"DIA",SubID,"TYP",0) = 1
       set ^MR(MrAdmID,"DIA",SubID,"TYP",1) = AType
       set ^MR(MrAdmID,"DIA",SubID,"DES",1) = AMemo
	   set $p(^MR(MrAdmID,"DIA",SubID),"^",9) = AEvaluationID
	*/
	s DiagnosPrefix=$P($G(^MR(MrAdm,"DIA",MRDIAChildsub,1)),"^",26)
	s MRDIAQuestionnaire=$P($G(^MR(MrAdm,"DIA",MRDIAChildsub)),"^",22)
	s AdmID=$p($G(^MR(MrAdm,"PRO",1)),"^",9)
	s ADMNo=$p(^PAADM(AdmID),"^",81)
	;结构化诊断信息返回
	s (SDSTermDR,SDSDisplayIDStr,SDSWordID,Supplement)=""
    s SDSInfo=##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).GetStructDiagnos(ADMNo,ADiagnosID)
    if SDSInfo'=""{
	    s SDSTermDR=$P(SDSInfo,"^",2)
	    s SDSDisplayIDStr=$P(SDSInfo,"^",3)
	    s SDSWordID=$P(SDSInfo,"^",8)
	    s Supplement=$P(SDSInfo,"^",9)
	    s SDSInfo=SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_Supplement
    }
	s DiagInfo=MRDIAICDCodeDR_"^"_MRDIADesc_"^"_MRDIADiagStatDR_"^"_MRDIASignSymDR_"^"_MRDIAOnsetDate
	s DiagInfo=DiagInfo_"^"_MRDIAMainDiagFlag_"^"_DiagnosLeavel_"^"_DiagnosPrefix_"^"_MRDIAQuestionnaire
	s DiagInfo=DiagInfo_"^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_Supplement
	Q DiagInfo
}

/// 数据维护在电子病历
/// "0:;1:左;2:右;3:上;4:下"
ClassMethod GetBodyPart() As %String
{
	s result = ""
	s rowId = ""
	Set langid=..%LanguageID()
	for
	{
		s rowId = $o(^DHCEMRM.DicDiagnosPositionD(rowId))
		q:(rowId = "")
		s Desc=$List(^DHCEMRM.DicDiagnosPositionD(rowId),3)
		s Desc= ##class(EMRmeta.DicDiagnosPosition).GetTranByDesc("Description",Desc,langid)
		if (result=""){
			s result=rowId_":"_Desc
		}else{
			s result=result_";"_rowId_":"_Desc
		}
	}
	i result'="" s result="0:;"_result
	q result
}

/// 2017-12-15
Query GetExecuteCTLOC(LogonHospDr As %String = "") As %Query(ROWSPEC = "CTLOCRowid,CTLOCDesc,CTLOCCode")
{
}

ClassMethod GetExecuteCTLOCClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = DiagTemplateListExecute ]
{
	Set repid=$LIST(qHandle,2)
    Kill ^CacheTemp(repid)
    Quit $$$OK
}

ClassMethod GetExecuteCTLOCExecute(ByRef qHandle As %Binary, LogonHospDr As %String = "") As %Status
{
	;d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosNew","DiagTemplateList")
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	Set langid=..%LanguageID()
    s LogonHospDr=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(LogonHospDr)
	Set CTLOCRowid=""
	F  s CTLOCRowid=$O(^CTLOC(CTLOCRowid)) q:CTLOCRowid=""  d
	.Q:($p(^CTLOC(CTLOCRowid),"^",22)'=LogonHospDr)
	.s LocDateActiveFrom=$P($G(^CTLOC(CTLOCRowid)),"^",24)
	.Q:(LocDateActiveFrom'="")&&(LocDateActiveFrom>+$h)
	.s LocDateActiveTo=$P($G(^CTLOC(CTLOCRowid)),"^",25)
	.Q:(LocDateActiveTo'="")&&(LocDateActiveTo<+$h)
	.Set CTLOCType=$P($G(^CTLOC(CTLOCRowid)),"^",13)
	.Q:(CTLOCType'="E")&&(CTLOCType'="EM")
	.Set CTLOCDesc=$P($G(^CTLOC(CTLOCRowid)),"^",2)
	.s CTLOCDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",CTLOCDesc,langid)
	.Q:CTLOCDesc["停用"
	.Q:CTLOCDesc=""
	.Set CTLOCDescQuickCode=$P(CTLOCDesc,"-",1)
	.Set CTLOCCode=$P($G(^CTLOC(CTLOCRowid)),"^",43) //检索码
	.s CTLOCCode=$$ALPHAUP^SSUTIL4(CTLOCCode)
	.s SubID=0 
	.for  s SubID=$O(^User.BDPAliasI("DataRef","CT_Loc",CTLOCRowid,SubID)) Q:SubID=""  d
	..q:'$D(^User.BDPAliasD(SubID))
	..s SUbCode=$$ALPHAUP^SSUTIL4($list(^User.BDPAliasD(SubID),2))
	..i CTLOCCode'="" s CTLOCCode=SUbCode
	..e  s CTLOCCode=CTLOCCode_"^"_SUbCode
	.Do OutputRow22
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow22
	set Data=$lb(CTLOCRowid,CTLOCDesc,CTLOCCode)   //CTLOCCode_" "_
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	quit
}

ClassMethod GetExecuteCTLOCFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetExecuteCTLOCExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

// , CTLOCID As %String, INDEXNum As %String

ClassMethod AddPrivate(PrivateDesc As %String, USERID As %String, LogonHospDr As %String = "") As %String
{
	s LogonHospDr=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(LogonHospDr)
	if PrivateDesc="" Q "PrivateDesc Null"
	&sql(select count(MASTERRowid) into:count from SQLUSER.DHC_MRDiagnosMaster where DHCDIADESC=:PrivateDesc and DHCDIAUSER=:USERID and DHCDIAHospDr=:LogonHospDr)
	if (count>0){
		Q "记录重复!"
	}
	s MaxIndex=+$o(^DHCDIAMAS("USER",USERID,LogonHospDr,""),-1)+1
	&sql(Insert into SQLUSER.DHC_MRDiagnosMaster Set DHCDIADESC=:PrivateDesc,DHCDIAUSER=:USERID,DHCDIAINDEX=:MaxIndex,DHCDIAHospDr=:LogonHospDr)
    quit SQLCODE
}

Query GetCTLocTemplet(CTlocRowid As %String) As %Query(ROWSPEC = "DHCDIAMASRowid,DHCDIADESC,btn,CTlocRowid")
{
}

ClassMethod GetCTLocTempletClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetCTLocTempletExecute ]
{
	Set repid=$LIST(qHandle,2)
    Kill ^CacheTemp(repid)
    Quit $$$OK
}

ClassMethod GetCTLocTempletExecute(ByRef qHandle As %Binary, CTlocRowid As %String) As %Status
{
	s ^tempscl("GetCTLocTemplet")=CTlocRowid
	;d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","GetCTLocTemplet")
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	if CTlocRowid="" {  
	    d ResetVariables23
		Set qHandle=$lb(0,repid,0)
		Quit $$$OK
	}
	Set DHCDIAINDEX="" f  s DHCDIAINDEX=$O(^DHCDIAMAS("CTLOC",CTlocRowid,DHCDIAINDEX)) q:DHCDIAINDEX=""  d
	.Set DHCDIAMASRowid="" f  s DHCDIAMASRowid=$O(^DHCDIAMAS("CTLOC",CTlocRowid,DHCDIAINDEX,DHCDIAMASRowid)) q:DHCDIAMASRowid=""  d
	..Set DHCDIADESC=$P(^DHCDIAMAS(DHCDIAMASRowid),"^",2)
	..Do OutputRow23
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
OutputRow23
	set Data=$lb(DHCDIAMASRowid,DHCDIADESC,"",CTlocRowid)  
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	quit
ResetVariables23
	set (DHCDIAMASRowid,DHCDIADESC,btn)=""
	quit
}

ClassMethod GetCTLocTempletFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetCTLocTempletExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

// 个人模板保存至科室模板

ClassMethod AddToCTLocTemplet(MasterRowid As %String, CTLocRwoid As %String, LogonHospDr As %String = "") As %String
{
	  s LogonHospDr=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(LogonHospDr)
	  if MasterRowid="" Q "UserTempletRowid null"
	  Set DHCDIADESC=$P(^DHCDIAMAS(MasterRowid),"^",2)
	  If DHCDIADESC="" Q "UserTempletDesc null"
	  
	  &sql(select count(MASTERRowid) into:count from SQLUSER.DHC_MRDiagnosMaster where DHCDIADESC=:DHCDIADESC and DHCDIALOC=:CTLocRwoid)
	  if (count>0){
		  Q "记录重复!"
	  }
	  s MaxIndex=+$o(^DHCDIAMAS("CTLOC",CTLocRwoid,""),-1)+1
	  TStart
	  s object=##class(User.DHCMRDiagnosMaster).%New()
	  S object.DHCDIADESC=DHCDIADESC
	  s object.DHCDIAINDEX=MaxIndex
	  d object.DHCDIALOCSetObjectId(CTLocRwoid)
	  d object.DHCDIAHospDrSetObjectId(LogonHospDr)
	  Set sc = object.%Save()
	  If $$$ISERR(sc) {
			Do $System.Status.DisplayError()
			TRollback
			Q ""
	  }
	  d object.%Close()
	  Set DHCMRDiaICDNewRowid=object.%Id()
	  Set MasterRowid=MasterRowid
	  Set DHCMRDiaICDListNumrowid="" f  s DHCMRDiaICDListNumrowid=$O(^DHCDIAICD("MASTER",MasterRowid,DHCMRDiaICDListNumrowid)) q:DHCMRDiaICDListNumrowid=""  d
	  .Set DHCMRDiaICDListIndexRowid="" f  s DHCMRDiaICDListIndexRowid=$O(^DHCDIAICD("MASTER",MasterRowid,DHCMRDiaICDListNumrowid,DHCMRDiaICDListIndexRowid)) Q:DHCMRDiaICDListIndexRowid=""  d
	  ..Set DHCMRDiaICDRowid=""  s DHCMRDiaICDRowid=$O(^DHCDIAICD("MASTER",MasterRowid,DHCMRDiaICDListNumrowid,DHCMRDiaICDListIndexRowid,""))  
	  ..Set MASTERDR=$P($G(^DHCDIAICD(DHCMRDiaICDRowid)),"^",2)
	  ..Set DHCMRDiaICDICDDR=$P($G(^DHCDIAICD(DHCMRDiaICDRowid)),"^",3)
	  ..Set DHCMRDiaICDListNum=$P($G(^DHCDIAICD(DHCMRDiaICDRowid)),"^",4)
	  ..Set DHCMRDiaICDListIndex=$P($G(^DHCDIAICD(DHCMRDiaICDRowid)),"^",5)
	  ..Set DHCMRDiaICDDesc=$P($G(^DHCDIAICD(DHCMRDiaICDRowid)),"^",6)
	  ..Set DHCMRDiaICDSyndromeICDInfo=$P($G(^DHCDIAICD(DHCMRDiaICDRowid)),"^",7)
	  ..Set DHCMRDiaICDNotes=$P($G(^DHCDIAICD(DHCMRDiaICDRowid)),"^",8)
	  ..s DHCMRDiaICDICDType=$P($g(^DHCDIAICD(DHCMRDiaICDRowid)),"^",11)
	  ..if DHCMRDiaICDICDType="" d
	  ...s BillFlag1=$P($G(^MRC("ID",+DHCMRDiaICDICDDR)),"^",13)
	  ...s BillFlag3=$P($g(^MRC("ID",+DHCMRDiaICDICDDR)),"^",15)
	  ...s DHCMRDiaICDICDType=$SELECT((BillFlag1="Y")&&(BillFlag3="Y"):2,(BillFlag1'="Y")&&(BillFlag3="Y"):1,1:0)
	  ..if ((DHCMRDiaICDICDDR'="")||(DHCMRDiaICDDesc'=""))&(DHCMRDiaICDListNum'="")&(DHCMRDiaICDListIndex'="") Do Insert
	  TC
	  Q DHCMRDiaICDNewRowid
	 
Insert
	  s object=##class(User.DHCMRDiagnosICD).%New()
	  s object.DHCMRDiaICDListNum=DHCMRDiaICDListNum
	  s object.DHCMRDiaICDListIndex=DHCMRDiaICDListIndex
	  d object.DHCMRDiaICDMASTERDRSetObjectId(DHCMRDiaICDNewRowid)
	  if (DHCMRDiaICDICDDR'="") d object.DHCMRDiaICDICDDRSetObjectId(DHCMRDiaICDICDDR)
	  s object.DHCMRDiaICDDesc=DHCMRDiaICDDesc
	  s object.DHCMRDiaICDSyndromeICDInfo=DHCMRDiaICDSyndromeICDInfo
	  s object.DHCMRDiaICDNotes=DHCMRDiaICDNotes
	  s object.DHCMRDiaICDType=DHCMRDiaICDICDType
	  s sc=object.%Save()  
	  If $$$ISERR(sc) {
			Do $System.Status.DisplayError()
			TRollback
			Q "DHCMRDiaICDMASTERDR Error"
	  }
	 d object.%Close()
	 Quit
}

// 判断科室模板是否已经存在

// 大于等于1 存在 否则 不存在

ClassMethod CheckLocTempIsRepeat(DHCDIADESC As %String, CTLocRwoid As %String) As %String
{
	&sql(select count(MASTERRowid) into:Count  from SQLUSER.DHC_MRDiagnosMaster where DHCDIALOC=:CTLocRwoid and DHCDIADESC=:DHCDIADESC)
	Q Count
}

// 添加科室模板

ClassMethod AddLocTemplet(CTLocRowid As %String, Name As %String, LogonHospDr As %String = "") As %String
{
	s LogonHospDr=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(LogonHospDr)
	&sql(select count(MASTERRowid) into:count from SQLUSER.DHC_MRDiagnosMaster where DHCDIADESC=:Name and DHCDIALOC=:CTLocRowid and DHCDIAHospDr=:LogonHospDr)
	if (count>0){
		Q "记录重复!"
	}
	s count=+$o(^DHCDIAMAS("CTLOC",CTLocRowid,""),-1)+1
	&sql(insert into SQLUSER.DHC_MRDiagnosMaster Set DHCDIALOC=:CTLocRowid,DHCDIAUSER=null,DHCDIADESC=:Name,DHCDIAINDEX=:count,DHCDIAHospDr=:LogonHospDr)
	Q SQLCODE
}

// 删除科室模板

ClassMethod LocTemplateDel(PrivateorderRowid As %String) As %String
{
	&sql(delete from SQLUSER.DHC_MRDiagnosMaster where MASTERRowid=:PrivateorderRowid)
	&sql(delete from SQLUSER.DHC_MRDiagnosICD where DHCMRDiaICD_MASTERDR=:PrivateorderRowid)
	Q SQLCODE
}

// 修改科室模板名称

ClassMethod PrivateChangeName(PrivateorderRowid As %String, PrivateorderNewName As %String) As %String
{
	s CTLocRowid=$P(^DHCDIAMAS(PrivateorderRowid),"^",3)
	&sql(select count(MASTERRowid) into:count from SQLUSER.DHC_MRDiagnosMaster where DHCDIADESC=:PrivateorderNewName and DHCDIALOC=:CTLocRowid and MASTERRowid<>:PrivateorderRowid)
	if (count>0){
		Q "记录重复!"
	}
	&sql(Update SQLUSER.DHC_MRDiagnosMaster set DHCDIADESC=:PrivateorderNewName where MASTERRowid=:PrivateorderRowid)
	Q SQLCODE
}

// 模板顺序改变

ClassMethod PrivateorderSave(PrivateorderStr As %String) As %String
{
	f i=1:1:$l(PrivateorderStr,"^") d
	.Set MASTERRowid=$P(PrivateorderStr,"^",i) 
	.&sql(update SQLUSER.DHC_MRDiagnosMaster set DHCDIAINDEX=:i where MASTERRowid=:MASTERRowid)
	Q SQLCODE
}

// 删除单条模板数据

ClassMethod delOneDiagItem(id As %String) As %String
{
	&sql(delete SQLUSER.DHC_MRDiagnosICD where DHCMRDiaICD_Rowid=:id)
	Q SQLCODE
}

// 模板内容数据顺序改变

ClassMethod DiagItemOrdSave(PrivateorderStr As %String) As %String
{
	f i=1:1:$l(PrivateorderStr,"^") d
	.Set MASTERRowid=$p($P(PrivateorderStr,"^",i),",",1)
	.s index=$p($P(PrivateorderStr,"^",i),",",2)
	.&sql(update SQLUSER.DHC_MRDiagnosICD set DHCMRDiaICD_ListIndex=:index where DHCMRDiaICD_Rowid=:MASTERRowid)
	Q SQLCODE
}

/*ClassMethod GetLocMaxIndex(CTLocRwoid As %String) As %String
{
	&sql(select count(MASTERRowid) into:count from SQLUSER.DHC_MRDiagnosMaster where DHCDIALOC=:CTLocRwoid)
	Q count
}*/

// 获取用户所能登录科室id串

// w ##class(web.DHCDocDiagnosEntryV8).GetUserLogonLocList(12662,"JSON",28)

ClassMethod GetUserLogonLocList(UserID As %String, type As %String, LogLocId As %String = "") As %String
{
	kill LocListArr
	if LogLocId'="" s LogLocHospId=$p(^CTLOC(LogLocId),"^",22)
	s LogLocHospId=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId($g(LogLocHospId))
	s MenuName = "System.DiagFav.Save.SaveAsLoc"
	s LocIdStr="",count=1
	s objUser = ##class(User.SSUser).%OpenId(UserID)
	s WLocStr=""
	if ($IsObject(objUser)){
		s DefaultLoc=objUser.SSUSRDefaultDeptDR.%Id()
		s Valid=1
		s LocDateActiveFrom=$P($G(^CTLOC(DefaultLoc)),"^",24)
		i (LocDateActiveFrom'="")&&(LocDateActiveFrom>+$h) s Valid=0
		s LocDateActiveTo=$P($G(^CTLOC(DefaultLoc)),"^",25)
		i (LocDateActiveTo'="")&&(LocDateActiveTo<=..%SysDate()) s Valid=0
		s DefaultLocHospDr=$p(^CTLOC(DefaultLoc),"^",22)
		if (DefaultLoc'=LogLocId)&&('$d(LocListArr(DefaultLoc))&&(DefaultLocHospDr=LogLocHospId)&&(Valid=1)) {
			if ("^"_WLocStr_"^")'[("^"_DefaultLoc_"^"){
				s WLocStr=WLocStr_"^"_DefaultLoc
			s LocIdStr=DefaultLoc
			if (type="JSON"){
				s count=count+1
				s LocDesc=$p(^CTLOC(DefaultLoc),"^",2)
				s CTLOCCode=$P($G(^CTLOC(DefaultLoc)),"^",43) //检索码
				s CTLOCCode=$$ALPHAUP^SSUTIL4(CTLOCCode)
				w "["
				w "{"_"""id"":"""_DefaultLoc_""","""_"text"":"""_LocDesc_""","""_"CTLOCCode"":"""_CTLOCCode_"""}"
			}
			}
		}
		s myCount = objUser.ChildSSUserOtherLogonLoc.Count()
		f myIdx=1:1:myCount{
			s objUserLoc = objUser.ChildSSUserOtherLogonLoc.GetAt(myIdx)
			s DefaultLoc = objUserLoc.OTHLLCTLOCDR.%Id()
			s LocDateActiveFrom=$P($G(^CTLOC(DefaultLoc)),"^",24)
			continue:(LocDateActiveFrom'="")&&(LocDateActiveFrom>+$h)
			s LocDateActiveTo=$P($G(^CTLOC(DefaultLoc)),"^",25)
			continue:(LocDateActiveTo'="")&&(LocDateActiveTo<=..%SysDate())
			s DefaultLocHospDr=$p(^CTLOC(DefaultLoc),"^",22)
			continue:DefaultLocHospDr'=LogLocHospId
			continue:(DefaultLoc=LogLocId)||($d(LocListArr(DefaultLoc)))
			s GroupDr = objUserLoc.OTHLLUserGroupDR.%Id()
			;得到安全组是否有医嘱模板维护某一个保存菜单权限
			s IsHaveMenuAuthDiagFav=##class(web.DHCDocDiagnosNew).IsHaveMenuAuthDiagFav(GroupDr,MenuName)
			continue:IsHaveMenuAuthDiagFav'="1"
			if ("^"_WLocStr_"^")'[("^"_DefaultLoc_"^"){
				s WLocStr=WLocStr_"^"_DefaultLoc
				if (type="JSON"){
					s LocDesc=$p(^CTLOC(DefaultLoc),"^",2)
					s CTLOCCode=$P($G(^CTLOC(DefaultLoc)),"^",43) //检索码
					s CTLOCCode=$$ALPHAUP^SSUTIL4(CTLOCCode)
					s SubID=0 
					for  {
						s SubID=$O(^User.BDPAliasI("DataRef","CT_Loc",DefaultLoc,SubID)) Q:SubID=""  
						continue:'$D(^User.BDPAliasD(SubID))
						s SUbCode=$$ALPHAUP^SSUTIL4($list(^User.BDPAliasD(SubID),2))
						i CTLOCCode'="" s CTLOCCode=SUbCode
						e  s CTLOCCode=CTLOCCode_"^"_SUbCode
					}
					s LocListArr(DefaultLoc)=1
					if count=1 {
						w "["
						w "{"_"""id"":"""_DefaultLoc_""","""_"text"":"""_LocDesc_""","""_"CTLOCCode"":"""_CTLOCCode_"""}"
					}else{
						w ",{""id"":"""_DefaultLoc_""","""_"text"":"""_LocDesc_""","""_"CTLOCCode"":"""_CTLOCCode_"""}"
					}
					s count=count+1
				}else{
					s LocIdStr=LocIdStr_"^"_DefaultLoc
				}
			}
		}
	}
	kill LocListArr
	Q:(count="1")&&(type="JSON") "[]"
	Q:type="JSON" "]"
	Q LocIdStr
}

ClassMethod GetSpecialJson() As %String
{
	s rtn=""
	Set langid=..%LanguageID()
	s id=0
	f  s id=$o(^CT("CTSPECR",id)) q:id=""  d
	.s desc=$p($g(^CT("CTSPECR",id)),"^",2)
	.s desc= ##class(User.CTSpecialCrowd).GetTranByDesc("CTSPECRDesc",desc,langid)
	.s ActiveFlag=$p($g(^CT("CTSPECR",id)),"^",3)
	.q:ActiveFlag'="Y"
	.i rtn="" d
	..s rtn = "{"_"'id':'"_id_"',"_"'text':'"_desc_"'}"
	.e  d
	..s rtn = rtn_",{"_"'id':'"_id_"',"_"'text':'"_desc_"'}"
	Q "["_rtn_"]"
}

ClassMethod GetPhysiologicalCycleJson() As %String
{
	s rtn=""
	s id=0
	Set langid=..%LanguageID()
	f  s id=$o(^DHCPHYC(id)) q:id=""  d
	.s desc=$p($g(^DHCPHYC(id)),"^",2)
	.s desc= ##class(User.DHCPhysiologicalCycle).GetTranByDesc("PHYCDesc",desc,langid)
	.s ActiveFlag=$p($g(^DHCPHYC(id)),"^",3)
	.q:ActiveFlag'="Y"
	.i rtn="" d
	..s rtn = "{"_"'id':'"_id_"',"_"'text':'"_desc_"'}"
	.e  d
	..s rtn = rtn_",{"_"'id':'"_id_"',"_"'text':'"_desc_"'}"
	Q "["_rtn_"]"
}

/// 插入长效诊断标识
/// User.PALongICD
ClassMethod SavePAlongICD(PatientID As %String, ICDDr As %String, LongDiagnosFlagRowId As %String, UserID As %String, PALongRowId As %String, LocId As %String, SDSInfo As %String = "") As %String
{
	 n (PatientID, ICDDr, LongDiagnosFlagRowId, UserID, PALongRowId,LocId,SDSInfo)
	 s rtn=..CheckPAlongICDRepeat(PatientID, ICDDr, LongDiagnosFlagRowId,LocId,SDSInfo)
	 Q:rtn=1 0 //记录重复不插入
	 TS
	 Set object = ##class(User.PALongICD).%New()
	 Do object.LICDPAPMIDRSetObjectId(PatientID)
	 if (PALongRowId'=""){
	 	Do object.LICDLICDDRSetObjectId(PALongRowId)
	 }
	 Do object.LICDICDDRSetObjectId(ICDDr)
	 s object.LICDAddDate=..%SysDate()
	 s object.LICDAddTime=..%SysTime()
	 Do object.LICDAddUserDRSetObjectId(UserID)
	 s object.LICDUpdateDate=..%SysDate()
	 s object.LICDUpdateTime=..%SysTime()
	 Do object.LICDUpdateUserDRSetObjectId(UserID)
	 s object.LICDLongFlag=LongDiagnosFlagRowId
	 Do object.LICDLocDRSetObjectId(LocId)
	 s object.LICDSDSInfo=SDSInfo	
	 Set sc = object.%Save()
	 If $$$ISERR(sc) {
		 Do $System.Status.DisplayError()
		 TRO
		 Quit "-201^插入长效诊断表失败,错误信息:"_$ZE
	 }else{
		 TC
	 }
	 Set NewPALongRowId=object.%Id()
	 Q 0_"^"_NewPALongRowId
}

/// 判断长效诊断表中诊断是否重复 目前只判断西医是否重复,中医和证型不判断
/// 0 不重复 1 重复
/// w ##class(web.DHCDocDiagnosEntryV8).CheckPAlongICDRepeat(78,18949,"L",95)
ClassMethod CheckPAlongICDRepeat(PatientID As %String, ICDDr As %String, LongDiagnosFlagRowId As %String, LocId As %String, SDSInfo As %String = "") As %String
{
	n (PatientID, ICDDr, LongDiagnosFlagRowId,LocId,SDSInfo)
	s ^tempscl("CheckPAlongICDRepeat")=PatientID_","_ICDDr_","_LongDiagnosFlagRowId_","_LocId
	s ID=0,rtn=0
	for {
		s ID=$o(^User.PALongICDI("LICDPatICDDRIndex",PatientID,ICDDr,ID))
		Q:(ID="")||(rtn=1)
		s LICDLongFlag=$lg(^User.PALongICDD(ID),11)
		continue:LICDLongFlag'=LongDiagnosFlagRowId
		s LICDEndDate=$lg(^User.PALongICDD(ID),13)
	 	 continue:LICDEndDate'=""
		s AddLoc=$lg(^User.PALongICDD(ID),12)
		continue:(LongDiagnosFlagRowId="L")&&(AddLoc'=LocId)
		s LICDICDDr=$lg(^User.PALongICDD(ID),4)
		s ICDInfo=##Class(web.DHCDocDiagnosEntryV8).GetICDInfoByICDDr(LICDICDDr)
		continue:$p(ICDInfo,"^",4)'="西医"
		s LICDSDSInfo=$lg(^User.PALongICDD(ID),15)
		continue:LICDSDSInfo'=SDSInfo
		s rtn=1
	}
	Q rtn
}

/// 删除长效诊断记录
/// w ##class(web.DHCDocDiagnosEntryV8).DelPAlongICDRepeat()
ClassMethod DelPAlongICDRepeat(RowidStr As %String) As %String
{
	n (RowidStr)
	s curDate=..%SysDate()
	s curTime=..%SysTime()
	for i=1:1:$l(RowidStr,","){
		s PALongRowId=$p(RowidStr,",",i)
		continue:'$d(^User.PALongICDD(PALongRowId))
		s PatientID=$lg($g(^User.PALongICDD(PALongRowId)),2)
		s mainPALongRowId=$lg($g(^User.PALongICDD(PALongRowId)),3)
		if (mainPALongRowId'=""){
			s subId=0
			for {
				s subId=$o(^User.PALongICDI("LICDLICDDrIndex",mainPALongRowId,subId))
				Q:subId=""
				continue:'$d(^User.PALongICDD(subId))
				/*&SQL(Delete From SQLUser.PA_LongICD Where ID=:subId)*/
				&sql(update SQLUser.PA_LongICD set LICD_EndDate=:curDate,LICD_EndTime=:curTime Where ID=:subId)
			}
			/*&SQL(Delete From SQLUser.PA_LongICD Where ID=:mainPALongRowId)*/
			&sql(update SQLUser.PA_LongICD set LICD_EndDate=:curDate,LICD_EndTime=:curTime Where ID=:mainPALongRowId)
		}else{
			s subId=0
			for {
				s subId=$o(^User.PALongICDI("LICDLICDDrIndex",PALongRowId,subId))
				Q:subId=""
				continue:'$d(^User.PALongICDD(subId))
				/*&SQL(Delete From SQLUser.PA_LongICD Where ID=:subId)*/
				&sql(update SQLUser.PA_LongICD set LICD_EndDate=:curDate,LICD_EndTime=:curTime Where ID=:subId)
			}
			/*&SQL(Delete From SQLUser.PA_LongICD Where ID=:PALongRowId)*/
			&sql(update SQLUser.PA_LongICD set LICD_EndDate=:curDate,LICD_EndTime=:curTime Where ID=:PALongRowId)
		}
	}
	Q SQLCODE
}

/// 长效诊断列表
/// d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","GetPAlongICDList",78)
Query GetPAlongICDList(PatientID As %String, LogLocId As %String) As %Query(CONTAINID = 0, ROWSPEC = "PALongRowId:%String,DiagnosCat:%String,ICDDr:%String,ICDDesc:%String,mainPALongId:%String,AddDateStr:%String,AddUser:%String,LastUpdateDateStr:%String,LastUpdateUser:%String,LongType:%String,SDSInfo:%String") [ SqlProc ]
{
}

ClassMethod GetPAlongICDListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetPAlongICDListExecute ]
{
 Set repid=$LIST(qHandle,2)
 Kill ^CacheTemp(repid)
 Quit $$$OK
}

ClassMethod GetPAlongICDListExecute(ByRef qHandle As %Binary, PatientID As %String, LogLocId As %String) As %Status
{
 Set repid=$I(^CacheTemp)
 If $g(ind)="" Set ind=1
 s LogLocHospId=$p(^CTLOC(LogLocId),"^",22)
 Set langid=..%LanguageID()
 s id=0
 for {
	 s id=$o(^User.PALongICDI("LICDPAPMIDrIndex",PatientID,id))
	 Q:id=""
	 s mainPALongId=$lg(^User.PALongICDD(id),3)
	 s ICDDr=$lg(^User.PALongICDD(id),4)
	 continue:(ICDDr="")||('$d(^MRC("ID",ICDDr)))
	 s LICDEndDate=$lg(^User.PALongICDD(id),13)
	 continue:LICDEndDate'=""
	 s ICDDesc=$p($g(^MRC("ID",ICDDr)),"^",2)
	 s ICDDesc =##class(User.MRCICDDx).GetTranByDesc("MRCIDDesc",ICDDesc,langid)
	 i mainPALongId'="" s ICDDesc="&nbsp&nbsp"_ICDDesc
	 s LongType=$lg(^User.PALongICDD(id),11)
	 s AddLoc=$lg(^User.PALongICDD(id),12)
	 s AddLocHospId=$p(^CTLOC(AddLoc),"^",22)
	 continue:AddLocHospId'=LogLocHospId
	 continue:(LongType="L")&&(AddLoc'=LogLocId)
	 s ICDInfo=##Class(web.DHCDocDiagnosEntryV8).GetICDInfoByICDDr(ICDDr)
	 s DiagnosCat=$p(ICDInfo,"^",4)
	 s AddDate=$lg(^User.PALongICDD(id),5)
	 s AddTime=$lg(^User.PALongICDD(id),6)
	 s AddDateStr=..%ZD(AddDate)_" "_..%ZT(AddTime,1)
	 s AddUserDr=$lg(^User.PALongICDD(id),7)
	 s AddUser=$P($g(^SSU("SSUSR",AddUserDr)),"^",2)
	 s AddUser =##class(User.SSUser).GetTranByDesc("SSUSRName",AddUser,langid)
	 s LastUpdateDate=$lg(^User.PALongICDD(id),8)
	 s LastUpdateTime=$lg(^User.PALongICDD(id),9)
	 s LastUpdateDateStr=..%ZD(LastUpdateDate)_" "_..%ZT(LastUpdateTime,1)
	 s LastUpdateUserDr=$lg(^User.PALongICDD(id),10)
	 s LastUpdateUser=$P($g(^SSU("SSUSR",LastUpdateUserDr)),"^",2)
	 s LastUpdateUser =##class(User.SSUser).GetTranByDesc("SSUSRName",LastUpdateUser,langid)
	 s LongType=$case(LongType,"L":..%Translate("diagnosentry.v8.csp","本科"),"H":..%Translate("diagnosentry.v8.csp","全院"))
	 s PALongRowId=id
	 s SDSInfo=$lg(^User.PALongICDD(id),15)
	 s SDSTermDR=$P(SDSInfo,"^",2)
	 if SDSTermDR'=""{
	 	s SDSDisplayIDStr=$P(SDSInfo,"^",3)
	 	s Supplement=$P(SDSInfo,"^",5)
	 	s ICDDesc=##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).GetDisplayName(SDSTermDR,SDSDisplayIDStr,Supplement)
	 }
	 d OutputRowList
 }
 Set qHandle=$lb(0,repid,0)
 Quit $$$OK
OutputRowList
 set Data=$lb(PALongRowId,DiagnosCat,ICDDr,ICDDesc,mainPALongId,AddDateStr,AddUser,LastUpdateDateStr,LastUpdateUser,LongType,SDSInfo)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
	Quit
}

ClassMethod GetPAlongICDListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetPAlongICDListExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// 根据长效诊断自动插入有效诊断
/// w ##class(web.DHCDocDiagnosEntryV8).InsertPALongICD(849,10209)
ClassMethod InsertPALongICD(EpisodeID As %String, UserRowId As %String, AdmDoctorDr As %String = "") As %String
{
	s err=0
	s PatientID=$p(^PAADM(EpisodeID),"^",1)
	s mradm=$p(^PAADM(EpisodeID),"^",61)
	s AdmLoc=$p(^PAADM(EpisodeID),"^",4)
	if (AdmDoctorDr=""){
		s IPBook=$O(^DHCDocIPBK(0,"EpisodeIDTo",EpisodeID,""),-1)
		if (IPBook'=""){
			if (IPBook'="") {
				s IPBookCreateDocUser=$p(^DHCDocIPBK(IPBook),"^",7)
				if (IPBookCreateDocUser'=""){
					s AdmDoctorDr=$P($G(^SSU("SSUSR",IPBookCreateDocUser)),"^",14)
				}
			}
		}
		s:AdmDoctorDr="" AdmDoctorDr=$p(^PAADM(EpisodeID),"^",9)
	}
	s:AdmDoctorDr="" AdmDoctorDr=$p(^PAADM(EpisodeID),"^",9)
	s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s LongDiaInsert=..%GetConfig("LongDiaInsert",AdmHospitalId)
	if (LongDiaInsert="")||(LongDiaInsert="Non"){
		q 0
	}
	if (LongDiaInsert="BookDocFirst")&&(AdmDoctorDr=""){
		q 0
	}
	s DiagnosStatusStr=##class(DHCDoc.OPDoc.DiagnosEntryListCommon).GetDiagnosStatusStr()
	s DiagnosStatusRowId=$p($p(DiagnosStatusStr,";",1),":",1)
	s CurDate=..%ZD(+$h)
	s IPDedfaultDiagnosTypeID=$O(^MRC("DTYP",0,"Code","PRE",0))
	s id=0
	for {
		 s id=$o(^User.PALongICDI("LICDPAPMIDrIndex",PatientID,id))
		 Q:id=""
		 s mainPALongId=$lg(^User.PALongICDD(id),3)
		 s ICDDr=$lg(^User.PALongICDD(id),4)
		 continue:(ICDDr="")||('$d(^MRC("ID",ICDDr)))||(mainPALongId'="")
		 s LICDEndDate=$lg(^User.PALongICDD(id),13)
	 	 continue:LICDEndDate'=""
		 s LongType=$lg(^User.PALongICDD(id),11)
		 s AddLoc=$lg(^User.PALongICDD(id),12)
		 continue:(LongType="L")&&(AdmLoc'=AddLoc)
		 s LICDAddUserDR=$lg(^User.PALongICDD(id),7)

		 s SyndromeCICDStr="",subId=0
		 for {
			s subId=$o(^User.PALongICDI("LICDLICDDrIndex",id,subId))
			Q:subId=""
			s SynICDDr=$lg(^User.PALongICDD(subId),4)
			continue:(SynICDDr="")||('$d(^MRC("ID",SynICDDr)))
			s SyndromeCICDStr=SynICDDr_$C(2)_IPDedfaultDiagnosTypeID_$C(2)_"N"
			s SyndromeCICDStr=SyndromeCICDStr_$C(2)_DiagnosStatusRowId_$C(2)_CurDate_$C(2)_CurDate_$C(2)_""
		}
		if (LongDiaInsert="LongDiaDocFirst"){
			s DocUserId=LICDAddUserDR
		}elseif (LongDiaInsert="BookDocFirst"){
			s DocUserId=$o(^SSU("SSUSR",0,"CTPCP",AdmDoctorDr,0))
		}
		if (DocUserId=""){
			continue
		}
		s DiagItemStr=""_"^"_""_"^"_ICDDr_"^"_IPDedfaultDiagnosTypeID_"^"_"N"
		s DiagItemStr=DiagItemStr_"^"_DiagnosStatusRowId_"^"_CurDate_"^"_SyndromeCICDStr_"^"_""_"^"_""
		s DiagItemStr=DiagItemStr_"^"_CurDate_"^"_""_"^^^"
		s DiagItemStr=DiagItemStr_"^^^"_DocUserId_"^^^"
		s err=..InsertMRDiagnos(mradm,DiagItemStr,"","",UserRowId)
	}
	Q +err
}

/// 获取长效诊断数量
/// w ##class(web.DHCDocDiagnosEntryV8).GetPALongICDCount(849)
ClassMethod GetPALongICDCount(EpisodeID As %String) As %String
{
	s Count=0
	s PatientID=$p(^PAADM(EpisodeID),"^",1)
	s AdmLoc=$p(^PAADM(EpisodeID),"^",4)
	s AdmHospitalId=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s id=0
	for {
		 s id=$o(^User.PALongICDI("LICDPAPMIDrIndex",PatientID,id))
		 Q:(id="")||(Count'=0)
		 s mainPALongId=$lg(^User.PALongICDD(id),3)
		 s ICDDr=$lg(^User.PALongICDD(id),4)
		 continue:(ICDDr="")||('$d(^MRC("ID",ICDDr)))
		 s LICDEndDate=$lg(^User.PALongICDD(id),13)
	 	 continue:LICDEndDate'=""
		 s LongType=$lg(^User.PALongICDD(id),11)
		 s AddLoc=$lg(^User.PALongICDD(id),12)
		 continue:(LongType="L")&&(AdmLoc'=AddLoc)
		 continue:($P(^CTLOC(AddLoc),"^",22)'=AdmHospitalId)
		 s Count=Count+1
	}
	Q +Count
}

Query LookUpWithAlias(desc As %String, loc As %String, ver1 As %String, EpisodeID As %String, ICDType As %String, UserId As %String = "", LimitRows As %String = "", UseDKBFlag As %String = "0", LocID As %String, LogHospDr As %String = "") As %Library.Query(CONTAINID = 0, ROWSPEC = "desc:%String:诊断名称,HIDDEN:%String,code:%String:诊断编码,DiagInsuCode:%String:国家医保诊断编码,DiagInsuName:%String:国家医保诊断名称") [ SqlProc ]
{
}

/// d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","LookUpWithAlias","s","","",2659,0,"","",0,526)
ClassMethod LookUpWithAliasExecute(ByRef qHandle As %Binary, desc As %String, loc As %String, ver1 As %String, EpisodeID As %String = "", ICDType As %String = "", UserId As %String = "", LimitRows As %String = "", UseDKBFlag As %String = "0", LocID As %String, LogHospDr As %String = "") As %Status
{
	s ^guo("LookUpWithAlias")=desc_","_loc_","_ver1_","_EpisodeID_","_ICDType_","_UserId_","_LimitRows_","_UseDKBFlag_","_LocID
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	s len=$l(desc)
    s control=$e(desc,len)
    i (control="#"){s desc=$e(desc,1,len-1)}
    s desc=$ZCONVERT(desc,"U")
    i UserId="" s UserId=%session.Get("LOGON.USERID")
    if LogHospDr="" s LogHospDr=%session.Get("LOGON.HOSPID")
    s DefHospId=##class(DHCDoc.Common.Hospital).GetDefHospIdByTableName("MRC_ICDDx",LogHospDr)
	;获取表是公有G ，私有S，管控C，绝对私有A标识
	s ICDDxDataType=##class(DHCDoc.Common.Hospital).GetDataType("MRC_ICDDx")
    Set langid=..%LanguageID()
    kill ^||tmpDiagLookUpItem,^||tmpDiagItemArr
    s num=0
    s DiagOrderByUserFreq=+..%GetConfig("DiagOrderByUserFreq",LogHospDr)
    if (EpisodeID'="") {
	    s AdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
	}else{
		s AdmType=""
	}
    ;按使用频率排序
    if (DiagOrderByUserFreq){
		s Rowid=0
		if (ICDDxDataType="G"){
			for {
				s Rowid=$o(^MRC("ID",Rowid)) Q:Rowid=""
				s SortNumPre=0,SortNumAft=0
				do RecordSortTmpData
			} 
		}else{
			for {
				s Rowid=$o(^User.BDPMappingHospI("DataRef","MRC_ICDDx",DefHospId,Rowid)) q:Rowid=""
				s SortNumPre=0,SortNumAft=0
				do RecordSortTmpData
			} 
		}
	   
	    
		;代码表数据使用次数排序
		s RecordCount=""
		for {
			s RecordCount=$o(^||tmpDiagLookUpItem(RecordCount),-1) Quit:RecordCount=""
			s SortNumPre=""
			for {
				s SortNumPre=$o(^||tmpDiagLookUpItem(RecordCount,SortNumPre)) Quit:SortNumPre=""
				s SortNumAft=""
				for {
					s SortNumAft=$o(^||tmpDiagLookUpItem(RecordCount,SortNumPre,SortNumAft)) Quit:SortNumAft=""
					s id=0
					for {
						s id=$o(^||tmpDiagLookUpItem(RecordCount,SortNumPre,SortNumAft,id)) Quit:id=""
						s Data=^||tmpDiagLookUpItem(RecordCount,SortNumPre,SortNumAft,id)
						do OutputRow
					}
				}
			}
		}
	}else{
		;若配置为不按使用频率排序，则按照全匹配->个人模板部分匹配->科室模板部分匹配—>诊断代码部分匹配原则排序
		;其中部分匹配内部按照(左匹配>右匹配)原则排序
		
		
		s SortNumPre=0	//匹配字符串左边的字符数量
    	s SortNumAft=0	//匹配字符串右边的字符数量
		Set DHCDIAINDEX=0
		for {
			s DHCDIAINDEX=$O(^DHCDIAMAS("USER",UserId,LogHospDr,DHCDIAINDEX)) q:DHCDIAINDEX=""
			Set DHCDIAMASRowid=0
			for {
				s DHCDIAMASRowid=$O(^DHCDIAMAS("USER",UserId,LogHospDr,DHCDIAINDEX,DHCDIAMASRowid)) q:DHCDIAMASRowid=""
				s ListNum=0
				for {
					s ListNum=$O(^DHCDIAICD("MASTER",DHCDIAMASRowid,ListNum)) Q:ListNum=""
					s DHCMRDiaICDListIndex=0 
    				for{
	    				s DHCMRDiaICDListIndex=$O(^DHCDIAICD("MASTER",DHCDIAMASRowid,ListNum,DHCMRDiaICDListIndex)) Q:DHCMRDiaICDListIndex=""
	    				Set DHCMRDiaICDRowid=""
    					for {
	    					s DHCMRDiaICDRowid=$O(^DHCDIAICD("MASTER",DHCDIAMASRowid,ListNum,DHCMRDiaICDListIndex,DHCMRDiaICDRowid)) Q:DHCMRDiaICDRowid=""
	    					if (ICDType'="2"){
		    					Set Rowid=$P($g(^DHCDIAICD(DHCMRDiaICDRowid)),"^",3)
		    					continue:Rowid=""
		    					s SortNumPre=10,SortNumAft=10
		    					do RecordSortTmpData
	    					}else{
		    					Set SynICDInfo=$P($g(^DHCDIAICD(DHCMRDiaICDRowid)),"^",7)
		    					for i=1:1:$l(SynICDInfo,$C(2)){
			    					Set Rowid=$P(SynICDInfo,$C(2),i)
			    					s SortNumPre=10,SortNumAft=10
			    					do RecordSortTmpData
			    				}
		    				}
	    				}
	    			}
    			}
			}
		}
		Set DHCDIAINDEX=0 
		for  {
			s DHCDIAINDEX=$O(^DHCDIAMAS("CTLOC",LocID,DHCDIAINDEX)) Q:DHCDIAINDEX=""  
			Set DHCDIAMASRowid=0
			for  {
				s DHCDIAMASRowid=$O(^DHCDIAMAS("CTLOC",LocID,DHCDIAINDEX,DHCDIAMASRowid)) Q:DHCDIAMASRowid=""
				s ListNum=0
				for {
					s ListNum=$O(^DHCDIAICD("CTLOC",DHCDIAMASRowid,ListNum)) Q:ListNum=""
					s DHCMRDiaICDListIndex=0 
    				for{
	    				s DHCMRDiaICDListIndex=$O(^DHCDIAICD("CTLOC",DHCDIAMASRowid,ListNum,DHCMRDiaICDListIndex)) Q:DHCMRDiaICDListIndex=""
	    				Set DHCMRDiaICDRowid=""
    					for {
	    					s DHCMRDiaICDRowid=$O(^DHCDIAICD("CTLOC",DHCDIAMASRowid,ListNum,DHCMRDiaICDListIndex,DHCMRDiaICDRowid)) Q:DHCMRDiaICDRowid=""
	    					if (ICDType'="2"){
		    					Set Rowid=$P($g(^DHCDIAICD(DHCMRDiaICDRowid)),"^",3)
		    					continue:Rowid=""
		    					s SortNumPre=100,SortNumAft=100
		    					do RecordSortTmpData
	    					}else{
		    					Set SynICDInfo=$P($g(^DHCDIAICD(DHCMRDiaICDRowid)),"^",7)
		    					for i=1:1:$l(SynICDInfo,$C(2)){
			    					Set Rowid=$P(SynICDInfo,$C(2),i)
			    					s SortNumPre=100,SortNumAft=100
			    					do RecordSortTmpData
			    				}
		    				}	
	    				}
	    			}
    			}
			}
		}
		s Rowid=0
		if (ICDDxDataType="G"){
			for {
				s Rowid=$o(^MRC("ID",Rowid)) Q:Rowid=""
				s SortNumPre=1000,SortNumAft=1000
				do RecordSortTmpData
			} 
		}else{
			for {
				s Rowid=$o(^User.BDPMappingHospI("DataRef","MRC_ICDDx",DefHospId,Rowid)) q:Rowid=""
				s SortNumPre=1000,SortNumAft=1000
				do RecordSortTmpData
			} 
		}
		s SortNumPre=""
		for {
			s SortNumPre=$o(^||tmpDiagLookUpItem(SortNumPre)) Quit:SortNumPre=""
			s SortNumAft=""
			for {
				s SortNumAft=$o(^||tmpDiagLookUpItem(SortNumPre,SortNumAft)) Quit:SortNumAft=""
				s id=0
				for {
					s id=$o(^||tmpDiagLookUpItem(SortNumPre,SortNumAft,id)) Quit:id=""
					s Data=^||tmpDiagLookUpItem(SortNumPre,SortNumAft,id)
					do OutputRow
				}
			}
		}
	}
    Set qHandle=$lb(0,repid,0)
	Quit $$$OK
RecordSortTmpData
    Q:'$$validicd(Rowid)
    s ICDDesc=$p(^MRC("ID",Rowid),"^",2)
    ;s ICDDesc=$ZCONVERT($p(^MRC("ID",Rowid),"^",2),"U")
   
    Q:'$$fetch(Rowid,ICDDesc)
    //主入口已经做了多院区过滤,该方法可不再重复调用。该接口效率目前有问题
    //Q:##Class(DHCDoc.Common.Hospital).GetHospShowDataFlag("MRC_ICDDx",Rowid,DefHospId)="N" 0
	s ICDCode=$p(^MRC("ID",Rowid),"^",4)
    s RecordCount=##class(DHCDoc.Log.DHCDocCTUseCount).GetCount("User.MRCICDDx",Rowid,UserId,"U")
    s AdmReason=""
    if (EpisodeID'=""){
    	s AdmReason=$p($G(^PAADM(EpisodeID,1)),"^",7)
    }
    s NowDate=..%ZD(+$H)
    s ExpStr=""
    s DiagInsuInfo=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.diag.GetInsuInfo",Rowid,LogHospDr,AdmReason,NowDate,ExpStr)
    s DiagInsuCode=$P(DiagInsuInfo,"^",1)
    s DiagInsuName=$P(DiagInsuInfo,"^",2)
    if (DiagOrderByUserFreq){
       s ^||tmpDiagLookUpItem(RecordCount,SortNumPre,SortNumAft,Rowid)=$lb(ICDDesc,Rowid,ICDCode,DiagInsuCode,DiagInsuName)
    }else{
	   s ^||tmpDiagLookUpItem(SortNumPre,SortNumAft,Rowid)=$lb(ICDDesc,Rowid,ICDCode,DiagInsuCode,DiagInsuName) 
	}
	s ^||tmpDiagItemArr(Rowid)=1
	q
validicd(Rowid)
    Q:Rowid="" 0
    Q:'$d(^MRC("ID",Rowid)) 0
    Q:$d(^||tmpDiagItemArr(Rowid)) 0
    
	s MRCIDValid=$P($G(^MRC("ID",Rowid)),"^",27)
	Q:MRCIDValid="N" 0
	s BillFlag3=$P($G(^MRC("ID",Rowid)),"^",15)
	s BillFlag1=$P($G(^MRC("ID",Rowid)),"^",13)
	Q:(ICDType="0")&&(BillFlag3="Y") 0
	Q:(ICDType="1")&&((BillFlag3'="Y")||(BillFlag1="Y")) 0
	Q:(ICDType="2")&&((BillFlag3'="Y")||(BillFlag1'="Y")) 0
	s DateFrom=$P($G(^MRC("ID",Rowid)),"^",6)
	s DateTo=$P($G(^MRC("ID",Rowid)),"^",7)
	Q:(DateFrom'="")&&(DateFrom>+$H) 0
	Q:(DateTo'="")&&(DateTo<+$H) 0
	s MetastaticSite=$P($G(^MRC("ID",Rowid)),"^",40) ;Y 肿瘤形态学编码 医生不使用
	s IPCode=$P($G(^MRC("ID",Rowid)),"^",41)  ;Injury/Poisoning 损伤中毒外部原因 医生不使用
	Q:(MetastaticSite="Y")||(IPCode="Y") 0
	;ICD诊断限制就诊类型
	s AvailableType=$p($G(^MRC("ID",Rowid)),"^",47)
	Q:(AdmType'="")&&(AvailableType'="")&&((","_AvailableType_",")'[(","_AdmType_",")) 0
	Q 1
fetch(Rowid,ICDDesc)
    Q:desc="" 1
	;全匹配检索
	i (control="#"){ 
		if (ICDDesc=desc){
			s SortNumPre=0
			s SortNumAft=0
			Q 1
		}
	}else{
		;模糊匹配检索
		if (ICDDesc)[(desc){
			s SortNumPre=SortNumPre+$find(ICDDesc,desc)-$length(desc)
			s SortNumAft=SortNumAft+$ZABS($length(ICDDesc)-$find(ICDDesc,desc)+2)
			Q 1
		}
	}
	s length=$l(desc," ")
	s boolean=0
	for index=1:1:length {
		s indesc=$p(desc," ",index)
	    Q:(indesc="")||(boolean=1)
	    continue:(ICDDesc'[(indesc))
	    s boolean=1
	    s SortNumPre=SortNumPre+$find(ICDDesc,indesc)-$length(indesc)-1
    	s SortNumAft=SortNumAft+$ZABS($length(ICDDesc)-$find(ICDDesc,indesc)+1)
	}
	Q:boolean=1 1
	s findAlias=0
	s AliasRowid=0 
	for {
		s AliasRowid=$o(^MRC("ID",Rowid,"ALIAS",AliasRowid)) 
		q:(AliasRowid="")||(findAlias=1)
		s Alias=$g(^MRC("ID",Rowid,"ALIAS",AliasRowid))
		s Alias=$ZCONVERT(Alias,"U")
		if (control="#") s len1=$l(desc) s len2=$l(Alias) continue:len1'=len2
		i ((control="#")&&(Alias=desc)) {
			s findAlias=1 
			s SortNumPre=0
			s SortNumAft=0
			q
		}
		s length=$l(desc," ")
	    s boolean=0
	    f index=1:1:length {
		    Q:boolean=1
		    s indesc=$p(desc," ",index)
		    continue:indesc=""
		    continue:(Alias'[(indesc))
		    s boolean=1 
		    s SortNumPre=SortNumPre+$find(Alias,indesc)-$length(indesc)-1
		    s SortNumAft=SortNumAft+$ZABS($length(Alias)-$find(Alias,indesc)+1)
		}
		i (boolean="1") s findAlias=1
		i ((control'="#")&&(Alias[(desc))) {
			s findAlias=1
			if (Alias=desc){
				s SortNumPre=0
				s SortNumAft=0
			}else{
				s SortNumPre=SortNumPre+$find(Alias,desc)-$length(desc)-1
				s SortNumAft=SortNumAft+$ZABS($length(Alias)-$find(Alias,desc)+1)
			}
		}
	}
	Q findAlias
OutputRow
	s $list(Data,1) =##class(User.MRCICDDx).GetTranByDesc("MRCIDDesc",$list(Data,1),langid)
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	quit
}

ClassMethod LookUpWithAliasFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = LookUpWithAliasExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {			// if there are no more rows, finish fetching
	 Set AtEnd=1
	 Set Row=""
	}
	Else {				// fetch row
	 Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod LookUpWithAliasClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = LookUpWithAliasExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

/// 获取死亡诊断分类下的诊断列表
Query GetDeathTypeICDList(desc As %String, EpisodeID As %String = "", HospId As %String = "") As %Library.Query(CONTAINID = 0, ROWSPEC = "ICDDesc:%String:描述,ICDDr:%String,ICDCode:%String") [ SqlProc ]
{
}

/// d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","GetDeathTypeICDList","ck","","","","0",10209,"",0,95)
ClassMethod GetDeathTypeICDListExecute(ByRef qHandle As %Binary, desc As %String, EpisodeID As %String = "", HospId As %String = "") As %Status
{
	Set repid=$I(^CacheTemp)
	If $g(ind)="" Set ind=1
	s HospId=##Class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospId)
	s DefHospId=##class(DHCDoc.Common.Hospital).GetDefHospIdByTableName("MRC_ICDDx",HospId)
	Set langid=..%LanguageID()
	s len=$l(desc)
    s control=$e(desc,len)
    i (control="#"){s desc=$e(desc,1,len-1)}
    s desc=$ZCONVERT(desc,"U")
    kill ^||tmpDeathDiagLookUpItem,^||tmpDeathDiagItemArr
    s num=0,MRCIDTypeDr=0
    for {
	    s MRCIDTypeDr=$o(^MRC("ICDTYPE",MRCIDTypeDr)) Q:MRCIDTypeDr=""
	    continue:'$G(^DHCDocConfig("DeathICDType",MRCIDTypeDr))
	    s DateFrom=$p(^MRC("ICDTYPE",MRCIDTypeDr),"^",3)
	    continue:(DateFrom'="")&&(DateFrom>+$h)
	    s DateTo=$p(^MRC("ICDTYPE",MRCIDTypeDr),"^",4)
	    continue:(DateTo'="")&&(DateTo<=..%SysDate())
	    s Rowid=0   
	    for {
		    s Rowid=$o(^MRC("ID",0,"TypeDR",MRCIDTypeDr,Rowid)) Q:Rowid=""
		    do RecordDiagSortTmpData
		} 
	}
	;暂按icd诊断长度正序排列
	s len=0
	for {
		s len=$o(^||tmpDeathDiagLookUpItem(len)) Quit:len=""
		s Num=0
		for {
			s Num=$o(^||tmpDeathDiagLookUpItem(len,Num)) Quit:Num=""
			s Data=^||tmpDeathDiagLookUpItem(len,Num)
			do OutputRow3
		}
	}
    Set qHandle=$lb(0,repid,0)
	Quit $$$OK
RecordDiagSortTmpData
    Q:'$$validicd1(Rowid)
    s ICDDesc=$ZCONVERT($p(^MRC("ID",Rowid),"^",2),"U")
	s ICDDesc =##class(User.MRCICDDx).GetTranByDesc("MRCIDDesc",ICDDesc,langid)
    Q:'$$fetch1(Rowid,ICDDesc)
	s ICDCode=$p(^MRC("ID",Rowid),"^",4)
    s len2=$l(ICDDesc)
    s num=num+1
    s ^||tmpDeathDiagLookUpItem(len2,num)=$lb(ICDDesc,Rowid,ICDCode)
	s ^||tmpDeathDiagItemArr(Rowid)=1
validicd1(Rowid)
    Q:Rowid="" 0
    Q:##Class(DHCDoc.Common.Hospital).GetHospShowDataFlag("MRC_ICDDx",Rowid,DefHospId)="N" 0
    Q:'$d(^MRC("ID",Rowid)) 0
    Q:$d(^||tmpDeathDiagItemArr(Rowid)) 0
	s MRCIDValid=$P($G(^MRC("ID",Rowid)),"^",27)
	Q:MRCIDValid="N" 0
	s BillFlag3=$P($G(^MRC("ID",Rowid)),"^",15)
	s BillFlag1=$P($G(^MRC("ID",Rowid)),"^",13)
	Q:((BillFlag3="Y")&&(BillFlag1="Y")) 0
	s DateFrom=$P($G(^MRC("ID",Rowid)),"^",6)
	s DateTo=$P($G(^MRC("ID",Rowid)),"^",7)
	Q:(DateFrom'="")&&(DateFrom>+$H) 0
	Q:(DateTo'="")&&(DateTo<+$H) 0
	s MetastaticSite=$P($G(^MRC("ID",Rowid)),"^",40) ;Y 肿瘤形态学编码 医生不使用
	s IPCode=$P($G(^MRC("ID",Rowid)),"^",41)  ;Injury/Poisoning 损伤中毒外部原因 医生不使用
	Q:(MetastaticSite="Y")||(IPCode="Y") 0
	Q:(EpisodeID'="")&&(##class(web.DHCMRDiagnos).CheckICDIsEnabled(Rowid,EpisodeID)'="") 0
	Q 1
fetch1(Rowid,ICDDesc)
    Q:desc="" 1
	;全匹配检索
	i (control="#"){ 
		Q:(ICDDesc=desc) 1
	}else{
		;模糊匹配检索
		Q:(ICDDesc)[(desc) 1
	}
	s length=$l(desc," ")
	s boolean=0
	for index=1:1:length {
		s indesc=$p(desc," ",index)
	    Q:(indesc="")||(boolean=1)
	    continue:(ICDDesc'[(indesc))
	    s boolean=1
	}
	Q:boolean=1 boolean
	s findAlias=0
	s AliasRowid=0 
	for {
		s AliasRowid=$o(^MRC("ID",Rowid,"ALIAS",AliasRowid)) 
		q:(AliasRowid="")||(findAlias=1)
		s Alias=^MRC("ID",Rowid,"ALIAS",AliasRowid)
		s Alias=$ZCONVERT(Alias,"U")
		if (control="#") s len1=$l(desc) s len2=$l(Alias) continue:len1'=len2
		i ((control="#")&&(Alias=desc)) s findAlias=1 q
		s length=$l(desc," ")
	    s boolean=0
	    f index=1:1:length {
		    Q:boolean=1
		    s indesc=$p(desc," ",index)
		    continue:indesc=""
		    continue:(Alias'[(indesc))
		    s boolean=1 
		}
		i (boolean="1") s findAlias=1
		i ((control'="#")&&(Alias[(desc))) s findAlias=1
	}
	Q findAlias
OutputRow3
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	quit
}

ClassMethod GetDeathTypeICDListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetDeathTypeICDListExecute ]
{
	Set AtEnd=$LIST(qHandle,1)
	Set repid=$LIST(qHandle,2)
	Set ind=$LIST(qHandle,3)
	Set ind=$o(^CacheTemp(repid,ind))
	If ind="" {			// if there are no more rows, finish fetching
	 Set AtEnd=1
	 Set Row=""
	}
	Else {				// fetch row
	 Set Row=^CacheTemp(repid,ind)
	}
	// Save QHandle
	s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

ClassMethod GetDeathTypeICDListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetDeathTypeICDListExecute ]
{
	Set repid=$LIST(qHandle,2)
	Kill ^CacheTemp(repid)
	Quit $$$OK
}

/// 获取患者当前有效的末次月经时间
ClassMethod GetPatPregnancyLMP(EpisodeID As %String)
{
	Q:EpisodeID="" ""
	s PatientID=$P(^PAADM(EpisodeID),"^",1)
	s mradm=$p(^PAADM(EpisodeID),"^",61)
	Q:mradm="" ""
	s LMPDate=$p($g(^MR(mradm,"PRO",1)),"^",160)
	q:(LMPDate'="") LMPDate
	s StartDate=..%SysDate()-280
	s LoopAdmType=""
	for {
		s LoopAdmType=$O(^PAPERdr(PatientID,"ADM",LoopAdmType))
		q:(LoopAdmType="")||(LMPDate'="")
		s LoopAdmDr=""
		for {
			s LoopAdmDr=$O(^PAPERdr(PatientID,"ADM",LoopAdmType,LoopAdmDr),-1)
			q:(LoopAdmDr="")||(LMPDate'="")
			s LoopAdmDate=$P(^PAADM(LoopAdmDr),"^",6)
			continue:(LoopAdmDate<StartDate)
			s Loopmradm=$p(^PAADM(LoopAdmDr),"^",61)
			continue:Loopmradm=""
			s LMPDate=$p($g(^MR(Loopmradm,"PRO",1)),"^",160)
			if (LMPDate<StartDate){
				s LMPDate=""
			}
		}
	}
	q LMPDate
}

/// 根据患者末次月经时间计算对应孕周诊断及孕周诊断结果备注
/// w ##class(web.DHCDocDiagnosEntryV8).GetPatLMPResultByLMP(1)
ClassMethod GetPatLMPResultByLMP(EpisodeID As %String, LMPDate As %String) As %String
{
	Q:EpisodeID="" "-1^无效的就诊数据"
	s PatientID=$P(^PAADM(EpisodeID),"^",1)
	s mradm=$p(^PAADM(EpisodeID),"^",61)
	
	if (LMPDate'=""){
		s LMPDate=..%ZDH(LMPDate)
	}else{
		s LMPDate=$p($g(^MR(mradm,"PRO",1)),"^",160)
	}
	Q:LMPDate>+$h "-1^末次月经不能大于当天!"
	Q:LMPDate="" "-1^无效的末次月经数据"
	s Days = +$h-LMPDate
	s WeekNum=Days\7
	s MRCICDRowid=##class(DHCDoc.DHCDocConfig.ItmDiagnose).GetWeekDiagnose(WeekNum)
	Q:MRCICDRowid="" "-1^未维护对应的孕周诊断" // 未维护对应的孕周诊断
	s LeftDays=Days#7 //取余
	s FormatLMPDate=..%ZD(LMPDate)
	s DueDate=##class(DHCDoc.Util.Date).GetDueDate(LMPDate)
	if (WeekNum=0) s Info="孕"_LeftDays_"天,预产期:"_DueDate
	else  s Info="孕"_WeekNum_"周"_LeftDays_"天,预产期:"_DueDate
	Q 0_"^"_MRCICDRowid_"^"_Info_"^"_FormatLMPDate
}

/// 获取诊断删除历史
/// d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","DiagnosList",190)
Query GetDelDiagList(mradm As %String) As %Query(ROWSPEC = "index:%String,delDate:%String,delUserName:%String,DiagnosCat:%String,MRCIDDesc:%String,DiagNotes:%String,DiagStat:%String,MainDiagFlag:%String,DIAOnsetDate:%String,MRDIADate:%String,DiagnosDoctor:%String")
{
}

ClassMethod GetDelDiagListClose(ByRef qHandle As %Binary) As %Status [ PlaceAfter = GetDelDiagListExecute ]
{
	Set repid=$LIST(qHandle,2)
	 Kill ^CacheTemp(repid)
	 Quit $$$OK
}

ClassMethod GetDelDiagListExecute(ByRef qHandle As %Binary, mradm As %String) As %Status
{
	;d ##class(%ResultSet).RunQuery("web.DHCDocDiagnosEntryV8","GetDelDiagList","108")
	Set repid=$I(^CacheTemp)
	if mradm="" {  
		Set qHandle=$lb(0,repid,0)
		Quit $$$OK
	}
	Set langid=..%LanguageID()
	s AdmID=$p($G(^MR(+mradm,"PRO",1)),"^",9)
	s ADMNo=$p(^PAADM(AdmID),"^",81)
	s index=0,sub=""
	for {
		s sub=$o(^MRDelLog(mradm,"Sub",sub)) Q:sub=""
		s diagInfo=$g(^MRDelLog(mradm,"Sub",sub,"Data"))
		s delInfo=$g(^MRDelLog(mradm,"Sub",sub))
		continue:(delInfo="" || diagInfo="")
		s delUserDr=$p(delInfo,"^",1)
		s delDate=$p(delInfo,"^",2)
		s delTime=$p(delInfo,"^",3) 
		s DiagNotes=$p(delInfo,"^",4)
		s delUserName=$p($g(^SSU("SSUSR",delUserDr)),"^",2)
		 s delUserName =##class(User.SSUser).GetTranByDesc("SSUSRName",delUserName,langid)
		s delDateLogic=..%ZDH(delDate)
		s delTimeLogic=..%ZTH(delTime)
		s delDate=..%ZD(delDateLogic)
		s delTime=..%ZT(delTimeLogic)
		s delDate=delDate_" "_delTime
		s index=index+1
		s ICDDr=$p(diagInfo,"^",1)
		if (ICDDr'=""){
			s MRCIDDesc=$p($g(^MRC("ID",ICDDr)),"^",2)
			s MRCIDDesc =##class(User.MRCICDDx).GetTranByDesc("MRCIDDesc",MRCIDDesc,langid)
			s BillFlag1=$P($G(^MRC("ID",+ICDDr)),"^",13)
			s BillFlag3=$P($g(^MRC("ID",+ICDDr)),"^",15)
			i BillFlag3'="Y" {
				s DiagnosCat="西医"
			}elseif (BillFlag3="Y")&&(BillFlag1'="Y") {
				s DiagnosCat="中医"
			}else{
				s DiagnosCat="证型"
			}
		}else{
			s MRCIDDesc=""
			s Questionnaire=$p(diagInfo,"^",22)
			s DiagnosCat=$case(Questionnaire,1:"西医",2:"中医",3:"证型",:"西医")
		}
		s DiagnosCat=..%Translate("diagnosentry.v8.csp",DiagnosCat)
		//诊断类型
		s DiagStatDr=$p(diagInfo,"^",9)
		if DiagStatDr'="" s DiagStat=$p($g(^MRC("DSTAT",DiagStatDr)),"^",2)
		else  s DiagStat=""
		s DiagStat =##class(User.MRCDiagnosStatus).GetTranByDesc("DSTATDesc",DiagStat,langid)
		//主诊断
		s MainDiagFlag=$p($g(^MRDelLog(mradm,"Sub",sub,"Data",1)),"^",20)
		s MainDiagFlag=$case(MainDiagFlag,"Y":"是",:"否")
		s MainDiagFlag=..%Translate("diagnosentry.v8.csp",MainDiagFlag)
		//取发病日期
		s DIAOnsetDate=$p(diagInfo,"^",35) 
		s:DIAOnsetDate'="" DIAOnsetDate=..%ZD(DIAOnsetDate) 
		//诊断录入医生
		s DoctorDr=$p(diagInfo,"^",4)
	    i DoctorDr'="" s DiagnosDoctor=$P($G(^CTPCP(DoctorDr,1)),"^",2)
	    Set DiagnosDoctor= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",DiagnosDoctor,langid)
	    //诊断录入日期
	    s MRDIADate=$p(diagInfo,"^",7) 
		s:MRDIADate'="" MRDIADate=..%ZD(MRDIADate)
		;结构化诊断信息返回
	    s SDSInfo=$G(^MRDelLog(mradm,"Sub",sub,"Data","SDS"))
	    s SDSDesc=$P(SDSInfo,"^",4)
	    s:SDSDesc'="" MRCIDDesc=SDSDesc
		s OutList(+delDateLogic,+delTimeLogic,sub)=$lb(index,delDate,delUserName,DiagnosCat,MRCIDDesc,DiagNotes,DiagStat,MainDiagFlag,DIAOnsetDate,MRDIADate,DiagnosDoctor)
	}
	s date="" f  s date=$O(OutList(date)) Q:date=""  d
	.s time="" f  s time=$O(OutList(date,time)) Q:time=""  d
	..s sub=0 f  s sub=$O(OutList(date,time,sub)) Q:sub=""  d
	...s ^CacheTemp(repid,$I(ind))=OutList(date,time,sub)
	Set qHandle=$lb(0,repid,0)
	Quit $$$OK
}

ClassMethod GetDelDiagListFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = GetDelDiagListExecute ]
{
 Set AtEnd=$LIST(qHandle,1)
 Set repid=$LIST(qHandle,2)
 Set ind=$LIST(qHandle,3)
	//
 Set ind=$o(^CacheTemp(repid,ind))
 If ind="" {				// if there are no more rows, finish fetching
 Set AtEnd=1
 Set Row=""
 }
 Else      {				// fetch row
 Set Row=^CacheTemp(repid,ind)
 }
 // Save QHandle
 s qHandle=$lb(AtEnd,repid,ind)
	Quit $$$OK
}

/// w ##class(web.DHCDocDiagnosEntryV8).CreateCopyItem("333||2")
ClassMethod CreateCopyItem(MRDiagnosRowids As %String) As %String
{
	n (MRDiagnosRowids,%session)
	s retObj=[]
	s MRADMID=+MRDiagnosRowids
	s EpisodeID=$p($G(^MR(MRADMID,"PRO",1)),"^",9)
	Q:EpisodeID="" retObj.%ToJSON()
	s ADMNo=$p(^PAADM(EpisodeID),"^",81)
	for i=1:1:$L(MRDiagnosRowids,"^"){
		s DiagRowid=$P(MRDiagnosRowids,"^",i)
		s DiagSub=$P(DiagRowid,"||",2)
		continue:DiagSub=""
		continue:$G(^MR(MRADMID,"DIA",DiagSub))=""
		s obj={}
		s obj.ICDRowid=$P(^MR(MRADMID,"DIA",DiagSub),"^",1)
		s DESSub=$G(^MR(MRADMID,"DIA",DiagSub,"DES",0))
		s obj.Note=$CASE(+DESSub,0:"",:$G(^MR(MRADMID,"DIA",DiagSub,"DES",DESSub)))
		s obj.Prefix=$P($G(^MR(MRADMID,"DIA",DiagSub,1)),"^",26)
		s obj.TCMTreatmentID=$P($G(^MR(MRADMID,"DIA",DiagSub,1)),"^",29)
		s obj.TCMTreatment=$P($G(^MRC("TCMT",+obj.TCMTreatmentID)),"^",2)
		s DiagCatID=##class(DHCDoc.Diagnos.Common).GetDiagnosCatID(DiagRowid)
		s obj.CMFlag=$CASE(DiagCatID,3:"H",2:"Y",:"")
		s obj.Level=$p($G(^MR(MRADMID,"DIA",DiagSub,"EPR")),"^",1)
		s SDSInfo=##class(web.DHCBL.MKB.SDSDiagnosFuseInterface).GetStructDiagnos(ADMNo,DiagRowid)
		if SDSInfo'=""{
			s SDSRowId=$P(SDSInfo,"^",1)
			s SDSTermDR=$P(SDSInfo,"^",2)
			s SDSDisplayIDStr=$P(SDSInfo,"^",3)
			s SDSWordID=$P(SDSInfo,"^",8)
			s Supplement=$P(SDSInfo,"^",9)
			s SDSInfo=SDSRowId_"^"_SDSTermDR_"^"_SDSDisplayIDStr_"^"_SDSWordID_"^"_Supplement
		}
		s obj.SDSInfo=SDSInfo
		s ChildRowids=""
		;拼接子诊断(证型)
		s ChildSub=0 for{
			s ChildSub=$O(^MR(MRADMID,"DIA",0,"Link",DiagRowid,ChildSub)) Q:ChildSub=""
			if ChildRowids="" s ChildRowids=MRADMID_"||"_ChildSub
			else  s ChildRowids=ChildRowids_"^"_MRADMID_"||"_ChildSub
		}
		if ChildRowids'=""{
			s obj.children=[].%FromJSON(..CreateCopyItem(ChildRowids))
		}
		d retObj.%Push(obj)
	}
	Q retObj.%ToJSON()
}

ClassMethod CheckEntryNoICDDiagAuit(EpisodeID As %String, DiagnosStatusRowId As %String) As %String
{
	s AuitMsg=""
	s HospDr=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
	s AdmReasonDR=$p(^PAADM(EpisodeID,1),"^",7)
	Set langid=..%LanguageID()
	s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
	s rowid=0
    for {
	    s rowid=$o(^DHCDocConfig("HospDr_"_HospDr,"NOICDDiagEntryLimit",rowid)) Q:rowid=""
	    s data=$g(^DHCDocConfig("HospDr_"_HospDr,"NOICDDiagEntryLimit",rowid))
	    continue:data=""
	    s LimitAdmTypeStr=$p(data,"^",1)
	    continue:(LimitAdmTypeStr'="")&&((","_LimitAdmTypeStr_",")'[(","_PAAdmType_","))
	    s LimitBilltypeStr=$p(data,"^",2)
	    continue:(LimitBilltypeStr'="")&&((","_LimitBilltypeStr_",")'[(","_AdmReasonDR_","))
	    s LimitDiagnosStr=$p(data,"^",3)
	    continue:(LimitDiagnosStr'="")&&((","_LimitDiagnosStr_",")'[(","_DiagnosStatusRowId_","))
	    if (LimitAdmTypeStr'="") {
		    s AuitMsg=$case(PAAdmType,"O":"门诊","I":"住院","E":"急诊","H":"体检")
			s AuitMsg=..%Translate("diagnosentry.v8.csp",AuitMsg)
		}
		if (LimitBilltypeStr'="") {
			s AdmReason=$p($g(^PAC("ADMREA",AdmReasonDR)),"^",2)
			s AdmReason=##class(User.PACAdmReason).GetTranByDesc("READesc",AdmReason,langid)
		    s AuitMsg=AuitMsg_AdmReason_..%Translate("diagnosentry.v8.csp","患者")
		}
		if (LimitDiagnosStr'="") {
			s ICDDescStatus=$p($g(^MRC("DSTAT",DiagnosStatusRowId)),"^",2)
			s ICDDescStatus =##class(User.MRCDiagnosStatus).GetTranByDesc("DSTATDesc",ICDDescStatus,langid)
		    s AuitMsg=AuitMsg_..%Translate("diagnosentry.v8.csp","诊断状态为")_ICDDescStatus_..%Translate("diagnosentry.v8.csp","的")
		}
		s AuitMsg=AuitMsg_..%Translate("diagnosentry.v8.csp","不能录入非ICD诊断！")
	    Q
	}
	Q AuitMsg
}

/// 科室扩展设定:'使用结构化诊断录入',不同项目存储位置可能不一样
ClassMethod GetSDSDiagEntryFlag(LocID)
{
	Q +$P($G(^CTLOC(+LocID,"DHC")),"^",29)
}

ClassMethod UpdateDiagSeq(DiagnosStr As %String, UserID = "") As %String
{
	s rows=[].%FromJSON(DiagnosStr)
	s len=rows.%Size()
	s SQLCODE=0
	TS
	for i=1:1:len{
		s row=rows.%Get(i-1)
		s DiagRowid=row.DiagRowid
		s Sequence=row.Sequence
		s MainDiagRowid=$P($g(^MR(+DiagRowid,"DIA",$P(DiagRowid,"||",2))),"^",15)
		continue:MainDiagRowid'=""
		set OldDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_DiagRowid)
		&SQL(UPDATE SQLUser.MR_Diagnos SET MRDIA_Sequence=:Sequence WHERE MRDIA_RowId=:DiagRowid)
		Q:SQLCODE
		;医生站业务数据修改日志
		s NewDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_DiagRowid)
		s SQLCODE=##class(web.DHCDocDataChangeLog).SaveLog("MR_Diagnos","User.MRDiagnos","诊断信息","User.MRDiagnos_"_DiagRowid,DiagRowid,"U",NewDataJson,OldDataJson,UserID)
		Q:SQLCODE
		s sub=0 for {
			s sub=$O(^MR(+DiagRowid,"DIA",0,"Link",DiagRowid,sub)) Q:sub=""
			s ChildDiagRowid=+DiagRowid_"||"_sub
			&SQL(UPDATE SQLUser.MR_Diagnos SET MRDIA_Sequence=:Sequence WHERE MRDIA_RowId=:ChildDiagRowid)
			Q:SQLCODE
		}
	}
	if SQLCODE TRO
	else  TC
	Q SQLCODE
}

ClassMethod UpdateAdmDiagSeq(MRADMID)
{
	s SQLCODE=0
	TS
	s rs=##class(%ResultSet).%New("web.DHCDocDiagnosEntryV8:DiagnosList")
	d rs.Execute(MRADMID)
	s Sequence=0
	while rs.Next(){
		s DiagRowid=rs.GetDataByName("MRDIARowId")
		s MainDiagRowid=$P($g(^MR(+DiagRowid,"DIA",$P(DiagRowid,"||",2))),"^",15)
		continue:MainDiagRowid'=""
		s Sequence=Sequence+1
		&SQL(UPDATE SQLUser.MR_Diagnos SET MRDIA_Sequence=:Sequence WHERE MRDIA_RowId=:DiagRowid)
		Q:SQLCODE
		s sub=0 for {
			s sub=$O(^MR(+DiagRowid,"DIA",0,"Link",DiagRowid,sub)) Q:sub=""
			s ChildDiagRowid=+DiagRowid_"||"_sub
			&SQL(UPDATE SQLUser.MR_Diagnos SET MRDIA_Sequence=:Sequence WHERE MRDIA_RowId=:ChildDiagRowid)
			Q:SQLCODE
		}

	}
	if SQLCODE TRO
	else  TC
	Q SQLCODE
}

ClassMethod UpdateDiagLevel(DiagnosStr As %String, UserID = "") As %String
{
	s rows=[].%FromJSON(DiagnosStr)
	s len=rows.%Size()
	s SQLCODE=0
	TS
	for i=1:1:len{
		s row=rows.%Get(i-1)
		s DiagRowid=row.DiagRowid
		s Level=row.Level
		set OldDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_DiagRowid)
		&SQL(UPDATE SQLUser.MR_Diagnos SET MRDIA_Level=:Level WHERE MRDIA_RowId=:DiagRowid)
		Q:SQLCODE
		;医生站业务数据修改日志
		s NewDataJson=##class(web.DHCDocDataChangeLog).GetLogJsonData("User.MRDiagnos"_$c(2)_DiagRowid)
		s SQLCODE=##class(web.DHCDocDataChangeLog).SaveLog("MR_Diagnos","User.MRDiagnos","诊断信息","User.MRDiagnos_"_DiagRowid,DiagRowid,"U",NewDataJson,OldDataJson,UserID)
		Q:SQLCODE
	}
	if SQLCODE TRO
	else  TC
	Q SQLCODE
}

/// 判断是否有指定类型的诊断
/// 20220926 zhouc
/// para:
///     DiagType:[出院|入院|初步|门诊],
///     IDCFlag:是否[1|0]是ICD诊断,
///     MainFlag:是否[1|0]是主诊断;
///     诊断分类:[西医|中医|证型][1|2|3];ICDCodeID:
///     icd诊断id,用于判断是否有此诊断,多个间以","分割
/// 输出: 1:有;0:无
/// w ##class(web.DHCDocDiagnosEntryV8).CheckAdmHaveDiag() //判断是否有非icd的主诊断
ClassMethod CheckAdmHaveDiag(inPara) As %String
{
	s RetFlag="0"
    s $zt="CheckAdmDiagErr"
    if $ISOBJECT(inPara){
        s ParamArr("EpisodeID")=inPara.GetAt("EpisodeID")
        s ParamArr("DiagType")=inPara.GetAt("DiagType")
        s ParamArr("IDCFlag")=inPara.GetAt("IDCFlag")
        s ParamArr("MainFlag")=inPara.GetAt("MainFlag")
        s ParamArr("DiagCat")=inPara.GetAt("DiagCat")
        s ParamArr("ICDCodeID")=inPara.GetAt("ICDCodeID")
    }else{
        d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(inPara,.ParamArr)
    }
    s EpisodeID=$g(ParamArr("EpisodeID"))   ;必传
    //DiagType:[出院|入院|初步|门诊] 可空
    s DiagType =$g(ParamArr("DiagType"))

    //是否[1|0]是ICD诊断 为空时不判断
    s IDCFlag =$g(ParamArr("IDCFlag"))      ;可空

    //是否[1|0]是主诊断 默认 0 为空时不判断
    s MainFlag =$g(ParamArr("MainFlag"))

    //诊断分类:[西医|中医|证型][1|2|3] 
    s DiagCat=$g(ParamArr("DiagCat"))

    //ICD诊断串,用于判断是否包含对应ICD诊断
    s ICDCodeID=$g(ParamArr("ICDCodeID"))
    s:ICDCodeID'="" ICDCodeID=","_ICDCodeID_","
    
	q:(EpisodeID="") RetFlag
	s mrrowid=$p($G(^PAADM(EpisodeID)),"^",61)
	q:mrrowid="" RetFlag
	s subrowid=0
	f {
		s subrowid=$o(^MR(mrrowid,"DIA",subrowid)) q:(subrowid="")||(RetFlag="1")
		s SubItemMainFlag=$p(^MR(mrrowid,"DIA",subrowid,1),"^",20) 	//主诊断
		continue:(MainFlag=1)&&(SubItemMainFlag'="Y")
		continue:(MainFlag=0)&&(SubItemMainFlag="Y")
		s SubItemIDCCodeDr=$p(^MR(mrrowid,"DIA",subrowid),"^",1)	//ICD诊断
		continue:(IDCFlag=1)&&(SubItemIDCCodeDr="")
		continue:(IDCFlag=0)&&(SubItemIDCCodeDr'="")
        continue:(ICDCodeID'="")&&(ICDCodeID'[(","_SubItemIDCCodeDr_","))
		s SubItemDiagTypeDr=^MR(mrrowid,"DIA",subrowid,"TYP",0)		//诊断类型
		s DiagTypeDr=$p($g(^MR(mrrowid,"DIA",subrowid,"TYP",SubItemDiagTypeDr)),"^",1)
		s DiagTypeDesc=$p($g(^MRC("DTYP",DiagTypeDr)),"^",2)
		continue:(DiagType'="")&&(DiagTypeDesc'[DiagType)
        
		if (DiagCat'=""){
			s SubItemCat=0
			if (SubItemIDCCodeDr'=""){
				s BillFlag1=$P($G(^MRC("ID",+SubItemIDCCodeDr)),"^",13)
				s BillFlag3=$P($g(^MRC("ID",+SubItemIDCCodeDr)),"^",15)
				if (BillFlag3'="Y"){
					s SubItemCat=1		;西医
				}elseif((BillFlag3="Y")&&(BillFlag1'="Y")){
					s SubItemCat=2		;中医
				}else{
					s SubItemCat=3		;证型
				}
			}else{
				s SubItemCat=$P($G(^MR(mrrowid,"DIA",subrowid,1)),"^",22)
				
			}
			continue:SubItemCat'=DiagCat
		}
		s RetFlag="1"
	}
	q RetFlag
CheckAdmDiagErr
    s $zt=""
    q "0"
}

/// 判断某一诊断类型是否存在主诊断
ClassMethod CheckMainDiagFlag(mradm As %String, DiagnosTypeRowId As %String) As %Status
{
	///w ##class(web.DHCDocDiagnosEntryV8).CheckMainDiagFlag()
	s HaveMainDiagFlag=""
	q:mradm="" ""
	//诊断类型为空判断没意义
	q:DiagnosTypeRowId="" ""
	s subrowid=0 for {
		s subrowid=$o(^MR(mradm,"DIA",subrowid)) q:subrowid=""
		S TypeSubRowid=$G(^MR(mradm,"DIA",subrowid,"TYP",0))
		s MRDiagnosTypeDr=""
		if TypeSubRowid'="" s MRDiagnosTypeDr=$G(^MR(mradm,"DIA",subrowid,"TYP",TypeSubRowid))
		continue:DiagnosTypeRowId'=MRDiagnosTypeDr
		//主诊断
		s HaveMainDiagFlag=$p($g(^MR(mradm,"DIA",subrowid,1)),"^",20)
		Q:HaveMainDiagFlag="Y"
	}
	q HaveMainDiagFlag
}

}
