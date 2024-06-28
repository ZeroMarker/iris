## 挂号科室搜索前缀匹配排序
demo
科室排序定义排序
```objectscript
/// d ##class(%ResultSet).RunQuery("web.DHCOPAdmReg","OPDeptList","reg","","",2)
ClassMethod OPDeptListExecute(ByRef qHandle As %Binary, UserId As %String, AdmType As %String = "", paradesc As %String = "", HospitalID As %String = "") As %Status
{
	Set repid=$INCREMENT(^CacheTemp)
	If $GET(ind)="" Set ind=1
	Kill OPDeptListArr
	Kill ^TMP($JOB,"RegCTLocLookup")
	Set UserId=$ZCONVERT(UserId,"U")
	If AdmType="" Set AdmType="O^E"
	Set Len=$LENGTH(AdmType,"^")
	Set HospitalID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospitalID)
	Set SortType=##class(web.DHCOPRegConfig).GetSpecConfigNode("RegistLocSort",HospitalID)
	For i=1:1:Len  {
		Set AdmTypePut=$PIECE(AdmType,"^",i)
		Set RowId=0 For  Set RowId=$ORDER(^PAC("ADMLOC",0,"AdmType",AdmTypePut,RowId)) Quit:RowId=""  Do
		.Quit:$DATA(OPDeptListArr(RowId))
		.Quit:'$DATA(^RB("RES",0,"CTLOC",RowId))
		.Quit:..CheckLocDesc(RowId,paradesc)'=1
		.Set LocDateTo=$PIECE($GET(^CTLOC(RowId)),"^",25)
		.Quit:(LocDateTo'="")&&(LocDateTo<+$HOROLOG)
		.Set LocHospitalID=$PIECE($GET(^CTLOC(RowId)),"^",22)
		.;Q:LocHospitalID'=HospitalID
		.Quit:"N"=##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("CT_Loc",RowId,HospitalID)
		.Set CTDesc=$PIECE($GET(^CTLOC(RowId)),"^",2)
		.Set CTAliasTem=""
		.If $LENGTH(CTDesc,"-")>1 Set CTAliasTem=$PIECE(CTDesc,"-",1)
		.Set CTAlias=$PIECE(^CTLOC(RowId),"^",43)
		.If CTAlias="" Set CTAlias=CTAliasTem
		.Set CTRowId=RowId
		.Set CTCode=CTRowId
		.Set CTLOCMarkNO=""
		.If SortType'="" Set CTLOCMarkNO=##class(web.DHCBL.BDP.BDPSort).GetSortNum("User.CTLoc",SortType,RowId)
		.Set CTLOCMarkNO=$CASE($LENGTH(CTLOCMarkNO),0:"999",1:"00"_CTLOCMarkNO,2:"0"_CTLOCMarkNO,:CTLOCMarkNO)
		.If $E(CTAlias, 1, $L(paradesc))=paradesc Set CTLOCMarkNO="001"
	    .Set ^TMP($JOB,"RegCTLocLookup"," "_CTLOCMarkNO,CTRowId)=CTDesc_"^"_CTAlias   //建立临时Globle
	    .Set OPDeptListArr(CTRowId)=1
		.//Do OutputRow1
	}
	//按照序号排序
	Set seq="" For {
		Set seq=$ORDER(^TMP($JOB,"RegCTLocLookup",seq))
		Quit:seq=""
		Set seq1="" For {
			Set seq1=$ORDER(^TMP($JOB,"RegCTLocLookup",seq,seq1))
			Quit:seq1=""
			Set temp=^TMP($JOB,"RegCTLocLookup",seq,seq1)
			Set CTRowId=seq1
			Set CTDesc=$PIECE(temp,"^",1)
			Set CTAlias=$PIECE(temp,"^",2)
			Do OutputRow1		
		}
	}
	
	Kill ^TMP($JOB,"RegCTLocLookup")
	Kill OPDeptListArr
 Set qHandle=$LISTBUILD(0,repid,0)
	Quit $$$OK
OutputRow1
	Set Data=$LISTBUILD(CTRowId,CTDesc,CTAlias)
	Set ^CacheTemp(repid,ind)=Data
	Set ind=ind+1
	Quit
ResetVariables1
	///set (repid)=0
	Set (CTRowId,CTCode,CTDesc,CTType)=""
	Quit
}
```
```objectscript
/// d ##class(%ResultSet).RunQuery("web.DHCRBResSession","GetClinicGroupByLocNew","","2","ck")
ClassMethod GetClinicGroupByLocNewExecute(ByRef qHandle As %Binary, LocRowId As %String = "", HospID = "", ParaDesc = "") As %Status
{
	s ^temp("GetClinicGroupByLocNew")=$lb(LocRowId, HospID, ParaDesc)
	;Q:LocRowId="" $$$OK
	If $g(ind)="" Set ind=1
	k ^TMP($J,"RegCTLocLookup")
	
	s HospID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospID)
	s ID=0 for{
		s ID=$O(^DHCLocSubject(ID)) Q:ID=""
		s CLGRPRowId=$P(^DHCLocSubject(ID),"^",2)
		s CLGRPLoc=$P(^DHCLocSubject(ID),"^",1)
		continue:($p($g(^CTLOC(CLGRPLoc)),"^",22)'=HospID)
		continue:$d(ClinicGroupList(CLGRPRowId))
		continue:((LocRowId'="")&&(LocRowId'=CLGRPLoc))
		continue:(HospID'="")&&("N"=##class(DHCDoc.Common.Hospital).GetHospShowDataFlag("RBC_ClinicGroup",CLGRPRowId,HospID))
		s DateTo=$P(^RBC("CLGRP",CLGRPRowId),"^",4)
		continue:(DateTo'="")&&(DateTo<=..%SysDate())
		s DateFrom=$P(^RBC("CLGRP",CLGRPRowId),"^",3)
		continue:(DateFrom="")||(DateTo>+$H)
		s CLGRPDesc=$P(^RBC("CLGRP",CLGRPRowId),"^",2)
		s CLGRPCode=$P(^RBC("CLGRP",CLGRPRowId),"^",1)
		s ClinicGroupList(CLGRPRowId)=""
		//s CLGRPDescNew=##class(ext.util.String).ToChineseSpell(CLGRPDesc)
		s CLGRPCodeNew=$ZCVT(CLGRPCode,"U") 
        i ParaDesc'="" s ParaDesc=$ZCVT(ParaDesc,"U")
		continue:(ParaDesc'="")&&(CLGRPDesc'[ParaDesc)&&(CLGRPCodeNew'[ParaDesc)
		
		//*匹配ParaDesc前缀排序
		s CTLOCMarkNO=""
		s CTLOCMarkNO=$case($l(CTLOCMarkNO),0:"999",1:"00"_CTLOCMarkNO,2:"0"_CTLOCMarkNO,:CTLOCMarkNO)
		s:($e(CLGRPCodeNew, 1, $L(ParaDesc))=ParaDesc) CTLOCMarkNO="000"
	    s ^TMP($J,"RegCTLocLookup"," "_CTLOCMarkNO,CLGRPRowId)=CLGRPDesc_"^"_CLGRPCode   //建立临时Globle
	    //*
	    
	    //*原来代码
		//s qHandle($I(ind))=$LB(CLGRPRowId,CLGRPDesc,CLGRPCode)
	}
	//Quit $$$OK
	//*
	
	
	//*添加排序的代码
	//按照序号排序
	s seq="" for {
		s seq=$O(^TMP($J,"RegCTLocLookup",seq))
		Quit:seq=""
		s seq1="" for {
			s seq1=$O(^TMP($J,"RegCTLocLookup",seq,seq1))
			Quit:seq1=""
			s temp=^TMP($J,"RegCTLocLookup",seq,seq1)
			s CLGRPRowId=seq1
			s CLGRPDesc=$P(temp,"^",1)
			s CLGRPCode=$P(temp,"^",2)
			//b ;01
			s qHandle($I(ind))=$LB(CLGRPRowId,CLGRPDesc,CLGRPCode)		
		}
	}
	K ^TMP($J,"RegCTLocLookup")
	Quit $$$OK
	//*
}
```
