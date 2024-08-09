// 医嘱项
ClassName: DHCDoc.DHCDocConfig.IPRecLocSubCatNeedPackQty
MethodName: SaveOrdNeedPackQtyLimit
Node: IPRecLocArcItemNeedPackQty
LocId: 37 // 西药房
ARCIMRowid: 3775||1
rowid: 
dataType: text

// 子类
ClassName:"web.DHCDocConfig",
MethodName:"SaveConfig1",
Node:"IPRecLocSubCatNeedPackQty",
Node1:LocId, 37,
NodeValue:CatStr, 51^52^53^54,
HospId: 2

// rowid = count
^DHCDocConfig("IPRecLocArcItemNeedPackQty",LocId,"Item",rowid)=ARCIMRowid

s HospCodeNode="HospDr_"_HospId
s ^DHCDocConfig(HospCodeNode,Node,Node1)=NodeValue
^DHCDocConfig(HospCodeNode,Node,Node1)=NodeValue
^DHCDocConfig("HospDr_2", "IPRecLocSubCatNeedPackQty", 37)

ClassMethod InsertOrderItem(Adm As %String, OrdItemStr As %String, User As %String, Loc As %String, Doc As %String, ExpStr As %String = "", ByRef ErrMsg As %String = "") As %Status
if IsCheckOrdItemStr="Y" {
	s CheckExpStr=PilotPRowId_"^"_LogonDep_"^"_OrderOpenForAllHosp_"^"_NotAdmTypeLimit
	s DisplayTypeFlag=""
	s OutPutDataJson=..CheckBeforeSave(Adm,OrdItemStr,User,Loc,Doc,CheckExpStr,DisplayTypeFlag)
	d ##class(DHCDoc.Util.FromJSON).FromJSONToArr(OutPutDataJson,.OutPutDataArr)
	if $d(OutPutDataArr) {
	s ErrCode=OutPutDataArr("ErrCode")
	s ErrMsg=ErrCode_$C(1)_OutPutDataArr("ErrMsg")
	i +ErrCode'=0 s Ret=100 QUIT Ret
}

ClassMethod CheckOrdBasicInfo
;整包装发药限制限制
if OrderType="R" {
    s msg=..CheckOrderNeedPackQty(ARCIMRowid,RecDepRowid,PriorCode)
    if (msg'=0) {
        s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp", msg)
        s FocusCol="OrderPriorRemarks"
        q ErrCode_"^"_ErrMsg_"^^"_FocusCol
    }
}

ErrCode: "-1"
ErrMsg: "维生素B1片(仁和堂)[10mg*100] 没有录入频次"
FocusCol: "OrderFreq"
NeedCheckDeposit: ""
OrdRowIndex: "1"

OrderPriorRemarks
/// creator:		郭荣勇
/// date:		2015-11-25
/// desc:		对于医嘱录入非必须前端处理的判断逻辑可以在此处理
/// input:		OrdItemStr:医嘱录入需要审核的医嘱项目拼接字符串 
/// 				DisplayTypeFlag 表示输入界面类型 1 输出EasyUI匹配得换行符号<br>
/// output:		空 或 标志位^受控描述^... 标志位:0或1 1标识受控,不可以录入
/// w ##class(web.DHCOEOrdItem).CheckBeforeSave(16,"16134||1^N^3^2022-10-26^16:56:48^^0.8000^39^1^^^^^1^^1^^^7^1^N^^N^^^^^^^N^^^^^^^^^17||253^^^^^^^2022-10-26^16:56:48^N^^^^^N^^91^^N^^^^^^^^N^1^^0^^^^0.8000^^^^^^2020^N^^^^^^^^221026000626^^",21201,39,2020,"^^on","1")

/// creator ChHL
/// 限制整包装发药子类医嘱项开立特定医嘱
/// input 医嘱项，接收科室，医嘱类型
/// output errmsg
/// debug: w ##class(web.DHCOEOrdItem).NeedPackQtyOrder("", 37, 1)
ClassMethod CheckOrderNeedPackQty(ARCIMRowId, LocId, PriorCode)
{
	;;整包装发药限制限制
	q:PriorCode=""
	q:ARCIMRowid=""
	q:LocId=""
	
	s flag = 0
	
	s i = ""
	for {
		s i=$o(^DHCDocConfig("IPRecLocArcItemNeedPackQty",LocId,"Item",i))
		q:i=""
		s ArcimRowId=$g(^DHCDocConfig("IPRecLocArcItemNeedPackQty",LocId,"Item",i))
		if (ArcimRowId=ARCIMRowId) {
			s flag=1 
			q
		}
	}
	if (flag = 0) {
		s subcat = $p(^ARCIM(+ARCIMRowId,$p(ARCIMRowId,"||",2),1),"^",10)
		s SubCat=$g(^DHCDocConfig("HospDr_2", "IPRecLocSubCatNeedPackQty", LocId))
		s:SubCat[subcat flag = 1
	}
	
	s msg = 0
	// 取药医嘱，出院带药，长期嘱托和长期自备药
	if (flag = 1) {
		if (PriorCode '= "OUT") && (PriorCode '= "ONE") && (PriorCode '= "OMCQST") && (PriorCode '= "OMST") {
			s RecDepDesc=$p(^CTLOC(LocId),"^",2)
			s ARCIMDesc=$p(^ARCIM($p(ARCIMRowId,"||",1),$p(ARCIMRowId,"||",2),1),"^",2)
			s msg = "在"_RecDepDesc_"为整包装发药，请按需开具取药医嘱、出院带药、长期嘱托和长期自备药"
		}
		else {
			s msg = 0	
		}	
	}
	q msg
}