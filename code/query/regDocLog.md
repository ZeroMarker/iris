润乾报表
DHCFRegTotalCtLoc.raq
配置
参数，数据集
DHCFRegTotalCtLoc_arg.raq
报表属性
单元格：填报属性，变量名

```objectscript
// d ##class(%ResultSet).RunQuery("web.DHCFHQ.DHCFRegTotal","GetLocReg","2023-10-10","2023-11-20",5,"上午","")

/// 取科室挂号数据
ClassMethod GetLocReg(ByRef repid As %Integer = 0, StartDate As %String = "", EndDate As %String = "", USERID As %String, HOSPID As %String = "", TimeRange As %String = "") As %Integer
{
	s del="^",RetNum=0
	q:StartDate="" RetNum
	q:EndDate="" RetNum	
	s StartDate=$zdh(StartDate,3),EndDate=$zdh(EndDate,3)
	s:USERID="" USERID=1
	s AdmId=0
	
	// 上午 下午 全天 夜诊 下午(夏) 上午(专家) 上午(核酸) 夜诊2 DHC_TimeRange
	s TimeRangeDr = ""
	&sql(
    SELECT TR_RowId into :TimeRangeDr
    FROM SQLUser.DHC_TimeRange
    WHERE TR_ValidEndDate IS NULL
	    AND TR_Desc = :TimeRange
	)
	    
	s Date=StartDate-1
	f  s Date=$o(^PAADMi("PAADM_AdmDate",Date)) q:((Date>EndDate)!(Date=""))  d
	.s AdmId=0
	.f  s AdmId=$o(^PAADMi("PAADM_AdmDate",Date,AdmId)) q:AdmId=""  d
	..s regfee = ""
	..i $d(^User.DHCRegistrationFeeI("ADM"," "_AdmId)) d
	...s regfee = $o(^User.DHCRegistrationFeeI("ADM"," "_AdmId,regfee))
	...s range =  $lg($g(^User.DHCRegistrationFeeD(regfee)),21)
	..q:((range'=TimeRangeDr)&&(TimeRangeDr'=""))
	..;b ;00
	..s AdmInfo=##class(web.DHCFHQ.DHCFBPat).GetAdmInfoByAdm(AdmId)
	..q:(AdmInfo="")
	..s AdmType=$p(AdmInfo,del,16)
	..q:AdmType="I"
	..s admdepcode=$p(AdmInfo,del,2)
	..s depdr=$o(^CTLOC(0,"Code",admdepcode,""))
	..;s hosdr=""
	..i depdr'="" s hosdr=$P(^CTLOC(depdr),"^",22)
	..q:(HOSPID'="")&&(HOSPID'=hosdr)
	..s userinfo=$g(^SSU("SSUSR",USERID))
	..S userhosid=$p(userinfo,"^",98)	
	..q:((hosdr'=userhosid)&&(userhosid'=2))	
	..s SessionType=""
	..s CtLoc=$p(AdmInfo,del,3)
	..q:CtLoc=""
	..s Doc=$p(AdmInfo,del,12)
	..s VisitStatu=$p(AdmInfo,del,13)
	..s RegType="现场挂号"
	..if ('$d(^User.DHCRegistrationFeeI("ADM"," "_AdmId))) d
	...s SessionType="直接就诊"
	..else  d
	...s:$d(^RBAS("PAADM_DR",AdmId)) RegType="预约挂号"
	...s RegFeeId=$o(^User.DHCRegistrationFeeI("ADM"," "_AdmId,""))
	...s SessionTypeDr=$LIST(^User.DHCRegistrationFeeD(RegFeeId),19)
	...s SessionType=$p(^RBC("SESS",SessionTypeDr),del,2)
	..s:$d(^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType)) ^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType)=^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType)+1
	..s:'$d(^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType)) ^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType)=1
	..if VisitStatu="C" d
    ...;s RegType="退号"
    ...;s:$d(^RBAS("PAADM_DR",AdmId)) RegType="预约挂号"
	...s RegFeeId=$o(^User.DHCRegistrationFeeI("ADM"," "_AdmId,""))
	...s SessionTypeDr=$LIST(^User.DHCRegistrationFeeD(RegFeeId),19)
	...s SessionType=$p(^RBC("SESS",SessionTypeDr),del,2)
    ...s:$d(^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType,1)) ^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType,1)=^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType,1)+1
	...s:('$d(^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType,1))) ^CacheTempFHQ(repid,0,CtLoc,SessionType,RegType,1)=1
	;b
	s CtLoc="",SessionType=""
	f  s CtLoc=$o(^CacheTempFHQ(repid,0,CtLoc)) q:CtLoc=""  d
	.f  s SessionType=$o(^CacheTempFHQ(repid,0,CtLoc,SessionType)) q:SessionType=""  d
	..s AdmStatus=""
	..f  s AdmStatus=$o(^CacheTempFHQ(repid,0,CtLoc,SessionType,AdmStatus)) q:AdmStatus=""  d
	...s RetNum=RetNum+1
	...s RegNumRet=0,RegNum=0
	...s:AdmStatus'="退号" RegNum=^CacheTempFHQ(repid,0,CtLoc,SessionType,AdmStatus)
	...s:($d(^CacheTempFHQ(repid,0,CtLoc,SessionType,AdmStatus,1))) RegNumRet=^CacheTempFHQ(repid,0,CtLoc,SessionType,AdmStatus,1)
	...w RetNum_":"_CtLoc_del_AdmStatus_del_SessionType_del_(+$g(RegNum))_del_(+$g(RegNumRet)),!
	...s ^CacheTempFHQ(repid,RetNum)=$lb(CtLoc,AdmStatus,SessionType,(+$g(RegNum)),(+$g(RegNumRet)))
	.K ^CacheTempFHQ(repid,0,CtLoc)
	q RetNum
}
```
Adm -> regfee -> range