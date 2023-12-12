<!--opdoc.recadmlog.hui.csp HISUI门诊日志--> 
OPDoc.RecAdmLog.hui.js
ClassName : "web.DHCOPDOCLog",
QueryName : "DHCOPLocLog",

ClassMethod DHCOPLocLogExecute(ByRef qHandle As %Binary, Gsearchmessage As %String, SearchConditions As %String, SPatientAge As %String, EPatientAge As %String, FindByDoc As %String, RLocID As %String, SerCon As %String, ResourceCon As %String, DocNo1 As %String, OpDate As %String, OpDate2 As %String, SearhLoc As %String, MRDiagnos As %String = "", MRDIAICDCodeID As %String = "", Time As %String, Time2 As %String, PatientID As %String = "") As %Status
{
	//d ##class(%ResultSet).RunQuery("web.DHCOPDOCLog","DHCOPLocLog","","","35","","","","","ys01","14/08/2018","16/08/2018","","","","","")
	k ^DHCOPDOCLogTEMP
	s DocNo=""
	s depid=%session.Get("LOGON.CTLOCID")
	//兼容组件版本
	if (SerCon=depid){
		s SerCon=%request.Get("SerCon")
	}
	s EastYard=%request.Get("EastYard")
	s WestYard=%request.Get("WestYard")
	i ((SearhLoc'="on")&&(RLocID="")&&(WestYard="")&&(EastYard="")) s DocNo=DocNo1   
	if (Time[":") s Time=..%ZTH(Time)
	if (Time2[":") s Time2=..%ZTH(Time2)
	Set langid=..%LanguageID()
	//EastYard As %String,WestYard As %String,AllYard As %String
	i ((SearchConditions=1)&&($g(Gsearchmessage)'="")) s Desc=$$ALPHAUP^SSUTIL4(Gsearchmessage)  s len=$l(Desc)
	Set repid=$I(^CacheTemp)
	Set ind=1
	if OpDate2<OpDate s OpDate2=OpDate
	if SPatientAge>EPatientAge,EPatientAge'="" s Age=SPatientAge s SPatientAge=EPatientAge s EPatientAge=Age
	s currctpcpdr=..GetCareProv(DocNo)
	s xuhao=0,sum=0,Zsum=0
	i OpDate'="" s OpDate=..%ZDH(OpDate)
    i OpDate2'="" s OpDate2=..%ZDH(OpDate2)
	f admdate=OpDate:1:OpDate2 d
	.s paadmrowid="" f  s paadmrowid=$o(^PAADMi("PAADM_AdmDate",admdate,paadmrowid)) q:paadmrowid=""  d
	     ..s depcodeid=$p(^PAADM(paadmrowid),"^",4)
	     ..s papmidr=$p(^PAADM(paadmrowid),"^",1)
	     ..q:(PatientID'="")&&(PatientID'=papmidr)
	     ..s CTLOCHospitalDR=$P(^CTLOC(depcodeid),"^",22)
	     ..s HOSPDesc=""
	     ..i (CTLOCHospitalDR'=""){s HOSPDesc=$P(^CT("HOSP",CTLOCHospitalDR),"^",2)}
	     ..//选择了科室则本科打沟也无效  当选择科室为空且本科不为空
	     ..q:((depcodeid'=depid)&&(RLocID="")&&(WestYard="")&&(EastYard=""))
	     ..//查询科室与条件科室不相同退出
	     ..q:((RLocID'="")&&(depcodeid'=RLocID))
	     ..q:((EastYard="on")&&(HOSPDesc="西院")&&(WestYard=""))
	     ..q:((WestYard="on")&&(HOSPDesc="东院")&&(EastYard=""))
	     ..s CTLOCDesc=$P(^CTLOC(depcodeid),"^",2)
	     ..s CTLOCDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",CTLOCDesc,langid)
	     ..//s CTLOCDesc=$P(CTLOCDesc,"-",2)
	     ..s admstatus=$p(^PAADM(paadmrowid),"^",20)
	     ..q:(admstatus'="A")
	     ..s date=$p(^PAADM(paadmrowid),"^",6)
	     ..s time=$p(^PAADM(paadmrowid),"^",7)
	     ..//发病日期 PAADM_TriageDate
	     ..s PAADMTriageDat=$P(^PAADM(paadmrowid,1),"^",30)
	     ..i (Time'="")&&(date=OpDate)   q:time<Time
	     ..i (Time2'="")&&(date=OpDate2) q:time>Time2
	     ..s time=..%ZT(time)
	     ..s AdmWay=""
	     ..s AdmWayID=$p($g(^PAADM(paadmrowid,2)),"^",47)
         ..I AdmWayID'="" S AdmWay=$P(^PAC("RTR",AdmWayID),"^",1)
	     ..s admfir=1,admre=0,jz="初诊"
	     ..s admre=$p($g(^PAADM(paadmrowid)),"^",56)
	     ..if (admre="R") s jz="门诊复诊",admfir=0,admre=1
	     ..s FirstAdm=$p($g(^PAADM(paadmrowid)),"^",72)
	     ..i FirstAdm="F" s jz="初诊",admfir=1,admre=0
	     ..e  i FirstAdm="R",AdmWay="CYFZ" s jz="出院复诊",admfir=0,admre=1
	     ..s TransAdm=$p($g(^PAADM(paadmrowid,"DHC")),"^",5)
	     ..i TransAdm="Y" s jz="转诊" //,admfir=0,admre=0
	     ..s jz=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",jz)
	     ..s regfeeid = $o(^User.DHCRegistrationFeeI("ADM"," "_paadmrowid,""))
	     ..s sessionTypeId = $lg(^User.DHCRegistrationFeeD(regfeeid),19) ;排班记录
	     ..s sessionDesc = $p(^RBC("SESS",sessionTypeId),"^",2)
	     ..;挂号职称是否包含复诊
	     ..s sessionFirstFlag = "初诊"
	     ..i sessionDesc["复诊" s sessionFirstFlag="复诊"
	     ..s QueueDr=$o(^User.DHCQueueI("QuePaadmDrIndex",paadmrowid,""))
	     ..;为适配应急系统,按应急系统规则判断患者队列状态,无需门诊日志查应急系统就诊记录项目使用以下注释行即可
	     ..s AdmQueStatInfo=##Class(DHCDoc.Interface.StandAlone.Service).GetCESAdmQueStatInfo(paadmrowid,QueueDr)
	     ..q:AdmQueStatInfo=""
	     ..s QueState=$p(AdmQueStatInfo,"^",3)
	     ..;q:QueueDr=""
	     ..s QueDocDr=$list(^User.DHCQueueD(QueueDr),5)
	     ..;s QueStateDr=$list(^User.DHCQueueD(QueueDr),14)
	     ..;s QueState=$list(^User.DHCPerStateD(QueStateDr),4)
	     ..s PAADMAdmDocCodeDR=$p($g(^PAADM(paadmrowid)),"^",9)
	     ..s ctpcpdr=PAADMAdmDocCodeDR
		 ..i QueDocDr'="" s ctpcpdr=QueDocDr
	     ..//if ($d(^SSU("SSUSR",0,"CTPCP",PAADMAdmDocCodeDR)))&&(PAADMAdmDocCodeDR'="") s ctpcpdr=PAADMAdmDocCodeDR
	     ..//e  s ctpcpdr=QueDocDr
	     ..//s ctpcpdr=QueDocDr
	     ..//根据下医嘱找医生，影响速度
	     ..s PAADMType=$p($g(^PAADM(paadmrowid)),"^",2)
	     ..if (PAADMType="E")||(ctpcpdr="") d
         ...q:'$d(^OEORD(0,"Adm",paadmrowid))
         ...s OrdId1=$o(^OEORD(0,"Adm",paadmrowid,0))
         ...s papmidr=$P(^PAADM(paadmrowid),"^",1)
         ...q:OrdId1=""
         ...s OrdId2=0
         ...s doctor=""
         ...f  s OrdId2=$o(^OEORD(OrdId1,"I",OrdId2)) q:(OrdId2="")||(doctor'="")  d
         ....s ordstr1=$g(^OEORD(OrdId1,"I",OrdId2,1))
         ....s doctor=$p(ordstr1,"^",11)
         ...i QueState="到达",ctpcpdr="" s ctpcpdr=doctor
         ...if ctpcpdr="" d
         ....s mrrowid=$p(^PAADM(paadmrowid),"^",61)
         ....s subrowid=""
         ....f  s subrowid=$o(^MR(mrrowid,"DIA",subrowid)) q:(subrowid="")||(ctpcpdr'="")  d //循环
         .....s ctpcpdr=$p(^MR(mrrowid,"DIA",subrowid),"^",4)	
	    ..Q:(currctpcpdr'="")&&(ctpcpdr'=currctpcpdr)
	    ..s ctdesc=""  s CTPCPId=""
	    ..Q:(FindByDoc'="")&&(ctpcpdr'=FindByDoc)
	    ..if ctpcpdr'=""  d
	    ...s ctdesc=$p(^CTPCP(ctpcpdr,1),"^",2) //医生姓名
	    ...Set ctdesc= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",ctdesc,langid)
	    ...s CTPCPId=$p(^CTPCP(ctpcpdr,1),"^",1)	//医生工号
	    ..s papmiCardNo=$p(^PAPER(papmidr,"PAT",1),"^",2)
	     
	    ..if (SearchConditions=2)&&(Gsearchmessage'=papmiCardNo)&&(Gsearchmessage'="") q   //添加对病人ID的判断。
	    ..s MedType=##class(web.DHCDocOrderEntry).GetPAAdmType(paadmrowid)
		..s ErrMsg=""
		..s Mdeicare=##Class(DHCWMR.IO.OutService).IGetMrNoByEpisodeID(paadmrowid,MedType,.ErrMsg)
	    ..if (SearchConditions=3)&&(Gsearchmessage'=Mdeicare&&(Gsearchmessage'="")) q //添加病案号查询并对病案号进行判断
	    ..s papminame=$p(^PAPER(papmidr,"ALL"),"^",1)   //取姓名
	    ..s admCount(papmidr)=$g(admCount(papmidr))+1		//就诊次数
	    ..s CTOCCDesc=""
	     ..s PAPEROccupationDR=$p($G(^PAPER(papmidr,"PER",2)),"^",6)  //职业PAPER_Occupation_D  "PER",2________  6_______  "^"_______PAADM_Occupation_D  1__  36______  "^"_______ 
	     ..i (PAPEROccupationDR'=""){ s CTOCCDesc=$P(^CT("OCC",PAPEROccupationDR),"^",2) }  //CT_Occupation CT_Occupation
	 	..Set CTOCCDesc= ##class(User.CTOccupation).GetTranByDesc("CTOCCDesc",CTOCCDesc,langid)
	    ..if (SearchConditions=1)&&(Gsearchmessage'="")  s desc1=$$ALPHAUP^SSUTIL4(papminame) s desc1=$e(desc1,1,len) q:desc1'=Desc   //加入对姓名条件的判断。 s desc1=$$ALPHAUP^SSUTIL4(papminame) s desc1=$e(desc1,1,len)  q:desc1'=Gsearchmessage
	    ..s papmidob=$p(^PAPER(papmidr,"ALL"),"^",6)    //取出生日期
	    ..s papmiage=($Horolog-papmidob)\365.25 
	    ..//添加对年龄条件的判断(EPatientAge'="")&&(SPatientAge<=EPatientAge)&&
	    ..if SPatientAge'="" q:papmiage<SPatientAge
	    ..if EPatientAge'="" q:papmiage>EPatientAge
		..s papmiage=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.reg.GetPapmiAge",papmidr,paadmrowid,CTLOCHospitalDR)
	    ..s papmisexid=$p(^PAPER(papmidr,"ALL"),"^",7) //取性别id
	    ..s papmigender=$p(^CT("SEX",papmisexid),"^",2) //取性别的描述
	    ..s papmigender=##class(User.CTSex).GetTranByDesc("CTSEXDesc",papmigender,langid) 
        ..s PapmiSocialStatus=$p($g(^PAPER(papmidr,"PER",1)),"^",10) //取医保类型 取值为2 为医保 取值为3 为公疗
	    ..s zfyb=0,zfgl=0,zfqt=1
	    ..i PapmiSocialStatus="2" s zfyb=1,zfgl=0,zfqt=0
	    ..i PapmiSocialStatus="3" s zfyb=0,zfgl=1,zfqt=0
	    ..q:PapmiSocialStatus=""
	    ..s SocialStatus=$p(^CT("SS",PapmiSocialStatus),"^",2) 		//社会属性
	    ..s papmiwork=$p($g(^PAPER(papmidr,"PER","ADD",1)),"^",1)   //地址
	    ..s subrowid=0 
	    ..s papmidiagnose=##class(DHCDoc.Diagnos.Common).GetAdmDiagDesc(paadmrowid)
	    ..s MRDIAICDCodeDR=""
	    ..s mrrowid=$p(^PAADM(paadmrowid),"^",61)
	    ..f  s subrowid=$o(^MR(mrrowid,"DIA",subrowid)) q:subrowid=""  d //循环	
       	...s MRDIAICDCodeDRSub=$P(^MR(mrrowid,"DIA",subrowid),"^",1) //ICD MR_Diagnos-> MRC_ICDDx
       	...i MRDIAICDCodeDRSub'="" d
       	....if MRDIAICDCodeDR="" s MRDIAICDCodeDR=$P(^MRC("ID",MRDIAICDCodeDRSub),"^",4)
       	....else  s MRDIAICDCodeDR=MRDIAICDCodeDR_";"_$P(^MRC("ID",MRDIAICDCodeDRSub),"^",4)
       	...if PAADMTriageDat="" d
       	....s PAADMTriageDat=$P(^MR(mrrowid,"DIA",subrowid),"^",35) 
       	....s PAADMTriageDat=..%ZD(PAADMTriageDat)
       ..q:(MRDiagnos'="")&&(papmidiagnose'[MRDiagnos)
	   ..s papmidiagnose=##class(ext.util.String).EvalJSON(papmidiagnose)
       ..s admdate2=..%ZD(admdate) //$zd(admdate,3)
       ..s IliFlag=$p($g(^PAADM(paadmrowid,"DHC")),"^",13)
       ..i IliFlag="Y"  s IliFlag="on"
       ..e  s IliFlag=""
       ..s InfectionStr=##class(DHCMed.EPDService.Service).GetEpdDiagFromCasesX(paadmrowid) //##Class(web.DHCMedEpidemicCtl).CheckPaadm(paadmrowid)  			;传染病相关信息
       ..s EpdFlag=##class(DHCMed.EPDService.Service).GetEpdRepDiagnosNew(paadmrowid)
       ..i +EpdFlag=0  s InfectFlag="否"
       ..e  s InfectFlag="是",sum=sum+1       //sum表示上报的总数
       ..//*************************************
       ..s LocalFlagDr=""
       ..s LocalFlagDesc=""
       ..s DHCPersonDr=$o(^DHCPERSON(0,"PAPERSON",papmidr,""))
       ..i DHCPersonDr'=""  d 
       ...i $d(^DHCPERSON(DHCPersonDr))  d 
       ....s LocalFlagDr=$p(^DHCPERSON(DHCPersonDr),"^",12)
       ....i LocalFlagDr=2  s LocalFlagDesc="外埠"
       ....e  s LocalFlagDesc="本市"
       ..s PAPERTelH=$p($g(^PAPER(papmidr,"PER",1)),"^",11)
       ..s DVANumber=$p($g(^PAPER(papmidr,"PAT",3)),"^",6)
       ..s Zsum=Zsum+1
       ..//加入状态条件控制  SerCon 与 FindInfoExecute 同步取值
       ..q:((SerCon=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",$g(^STUDENT(1))))&&(admfir'=1))
       ..q:((SerCon=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",$g(^STUDENT(2))))&&(admre'=1))
       ..q:(SerCon=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",$g(^STUDENT(3))))&&(InfectFlag'="是")
       ..q:((SerCon=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",$g(^STUDENT(4))))&&(IliFlag'="on")) 
       ..//号别状态
       ..;q:((ResourceCon=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",$g(^STUDENTS(1))))&&(sessionFirstFlag="初诊")&&(ResourceCon'=""))
       ..;q:((ResourceCon=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",$g(^STUDENTS(2))))&&(sessionFirstFlag="复诊")&&(ResourceCon'=""))
       ..q:(ResourceCon'=sessionFirstFlag)&&(ResourceCon'="")
       ..s TPAPMICardTypeDR=$p($g(^PAPER(papmidr,"PAT",3)),"^",7)
	   ..s TPAPMICardType=$s(+$p($g(^PAPER(papmidr,"PAT",3)),"^",7)'=0:$p($g(^PAC("CARD",$p($g(^PAPER(papmidr,"PAT",3)),"^",7))),"^",2),1:"")
	   ..Set TPAPMICardType= ##class(User.DHCCredType).GetTranByDesc("CRTDesc",TPAPMICardType,langid)
	   ..s AdmReason=##class(DHCDoc.OPDoc.AjaxInterface).GetAdmReason($g(paadmrowid))
       ..set data=$lb(paadmrowid,papmiCardNo,Mdeicare,papminame,papmiage,papmigender,papmiwork,papmidiagnose,xuhao,ctdesc,admfir,admre,admdate2,zfyb,zfgl,zfqt,SocialStatus,jz,InfectFlag,LocalFlagDesc,PAPERTelH,InfectionStr,IliFlag,time,CTLOCDesc,CTOCCDesc,PAADMTriageDat,MRDIAICDCodeDR,CTPCPId,papmidr,DVANumber,TPAPMICardType,AdmReason)
 	   ..;d OutputRow
 	   ..Set ^TMP($j,"DHCOPLocLog",CTPCPId,paadmrowid)=data
 	   //相同医生排序
	   Set CTPCPId="" For {
		Set CTPCPId=$ORDER(^TMP($j,"DHCOPLocLog",CTPCPId))
		Quit:CTPCPId=""
		Set paadmrowid="" For {
			Set paadmrowid=$ORDER(^TMP($j,"DHCOPLocLog",CTPCPId,paadmrowid))
			Quit:paadmrowid=""
			Set temp=^TMP($j,"DHCOPLocLog",CTPCPId,paadmrowid)
			set paadmrowid = $lg(temp, 1)
			set papmiCardNo = $lg(temp, 2)
			set Mdeicare = $lg(temp, 3)
			set papminame = $lg(temp, 4)
			set papmiage = $lg(temp, 5)
			set papmigender = $lg(temp, 6)
			set papmiwork = $lg(temp, 7)
			set papmidiagnose = $lg(temp, 8)
			;set xuhao = $lg(temp, 9)
			set xuhao = $lg(xuhao)
			set ctdesc = $lg(temp, 10)
			set admfir = $lg(temp, 11)
			set admre = $lg(temp, 12)
			set admdate2 = $lg(temp, 13)
			set zfyb = $lg(temp, 14)
			set zfgl = $lg(temp, 15)
			set zfqt = $lg(temp, 16)
			set SocialStatus = $lg(temp, 17)
			set jz = $lg(temp, 18)
			set InfectFlag = $lg(temp, 19)
			set LocalFlagDesc = $lg(temp, 20)
			set PAPERTelH = $lg(temp, 21)
			set InfectionStr = $lg(temp, 22)
			set IliFlag = $lg(temp, 23)
			set time = $lg(temp, 24)
			set CTLOCDesc = $lg(temp, 25)
			set CTOCCDesc = $lg(temp, 26)
			set PAADMTriageDat = $lg(temp, 27)
			set MRDIAICDCodeDR = $lg(temp, 28)
			set CTPCPId = $lg(temp, 29)
			set papmidr = $lg(temp, 30)
			set DVANumber = $lg(temp, 31)
			set TPAPMICardType = $lg(temp, 32)
			set AdmReason = $lg(temp, 33)
			s papmidr=$P(^PAADM(paadmrowid),"^",1)
			s AdmCount = admCount(papmidr)
			Do OutputRow		
		}
	}
    s ^DHCOPDOCLogTEMP("InfectSum")=sum_"^"_Zsum
    Set qHandle=$lb(0,repid,0)
    Quit $$$OK
  
OutputRow
 s xuhao=xuhao+1
 s admfir=$case(admfir,1:"是",:"否")
 s admre=$case(admre,1:"是",:"否")
 s InfectFlag=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",InfectFlag)
 s admfir=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",admfir)
 s admre=##class(websys.Translation).Get("opdoc.recadmlog.hui.csp",admre)
 set Data=$lb(paadmrowid,papmiCardNo,Mdeicare,papminame,papmiage,papmigender,papmiwork,papmidiagnose,xuhao,ctdesc,admfir,admre,admdate2,zfyb,zfgl,zfqt,SocialStatus,jz,InfectFlag,LocalFlagDesc,PAPERTelH,InfectionStr,IliFlag,time,CTLOCDesc,CTOCCDesc,PAADMTriageDat,MRDIAICDCodeDR,CTPCPId,papmidr,DVANumber,TPAPMICardType,AdmReason,AdmCount)
 Set ^CacheTemp(repid,ind)=Data
 Set ind=ind+1
 quit
}