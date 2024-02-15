/// 名称:     web.DHCOEOrdItemView
/// 描述:     医嘱录入界面视图交互及控制
/// 编写者:  谭吉善
/// 编写日期: 2018.06.02
Class web.DHCOEOrdItemView Extends DHCDoc.Util.RegisteredObject [ ClassType = "", ProcedureBlock ]
{

/// d ##Class(web.DHCOEOrdItemView).GetItemCongeriesToListTest()
/// 调试功能
ClassMethod GetItemCongeriesToListTest() As %String [ ProcedureBlock = 0 ]
{
    s ItemInfo=""
    s Time0=$P($now(),",",2)
    s ItemInfo=##Class(web.DHCOEOrdItemView).GetItemCongeriesToList($list(^tan("GetItemCongeriesToList"),1),$list(^tan("GetItemCongeriesToList"),2),$list(^tan("GetItemCongeriesToList"),3),$list(^tan("GetItemCongeriesToList"),4),$list(^tan("GetItemCongeriesToList"),5))
    s Time1=$P($now(),",",2)
    w "main time:"_(Time1-Time0),!
    //s ItemInfo=@ItemInfo
    Set FromJSON=##Class(DHCDoc.Util.FromJSON).%FromJSON(ItemInfo)
    d ##Class(DHCDoc.Util.FromJSON).WriteJsonLine(FromJSON,"-")
    s Time2=$P($now(),",",2)
    w "Export time:"_(Time2-Time1),!
    q ItemInfo
}

/// creator:	谭吉善
/// date:		2018-6-2
/// desc:		批量获取医嘱录入新增行对象的默认值
/// input:		OrdCongeriesJson:需要添加的医嘱项及附加信息（医嘱套或复制医嘱）的集合
/// 			BaseParamJson:基本参数键值对
/// 			ItemOrdsJson:已新增到行上的医嘱
/// 			RowDataJson:行默认数据
/// 
/// output:		JSON:
/// {
/// 	ErrCode:非0-停止新增,
/// 	ErrMsg:错误描述,
/// 	CallBakFunS:[{
/// 		CallBakFunCode:回调代码
/// 		CallBakFunParams:回调方法参数
/// 	},...,...}],
/// 	ParamData:[{
/// 		OrderType:"",
/// 		....
/// 	}]
/// }
/// w ##Class(web.DHCOEOrdItemView).GetItemCongeriesToList($list(^TMPtan("GetItemCongeriesToList"),1),$list(^TMPtan("GetItemCongeriesToList"),2),$list(^TMPtan("GetItemCongeriesToList"),3),$list(^TMPtan("GetItemCongeriesToList"),4),$list(^TMPtan("GetItemCongeriesToList"),5))
ClassMethod GetItemCongeriesToList(OrdCongeriesJson As %String, BaseParamJson As %String, ItemOrdsJson As %String, RowDataJson As %String, UserOptionsJson As %String) As %String [ ProcedureBlock = 0 ]
{
    //初始化需要添加到行上的医嘱明细信息
    k OrdCongeriesArr
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(OrdCongeriesJson,.OrdCongeriesArr)
    k BaseParamArr
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(BaseParamJson,.BaseParamArr)
    k ItemOrdsArr
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(ItemOrdsJson,.ItemOrdsArr)
    k RowDataArr
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(RowDataJson,.RowDataArr)
    k UserOptionsJsonArr
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(UserOptionsJson,.UserOptionsJsonArr)
    k UserOptionsArr
    d SetUserOptionsArr(.UserOptionsJsonArr,.UserOptionsArr)
    s EpisodeID=BaseParamArr("Adm")
    if (EpisodeID=940){
        ;s ^TMPtan("GetItemCongeriesToList")=$lb(OrdCongeriesJson,BaseParamJson,ItemOrdsJson,RowDataJson,UserOptionsJson)
    }
    s AddNo=0
    ///需要增加到行上的医嘱列表
    k ItemCongeriesArr
    s OrdCounter=""
    for {
        s OrdCounter=$O(OrdCongeriesArr(OrdCounter))
        q:(OrdCounter="")
        
        k OneItemInfoArr
        d ##Class(web.DHCOEOrdItemView).GetItemToList(
            .BaseParamArr,.OrdCongeriesArr,OrdCounter, .ItemOrdsArr,
            .RowDataArr,.OneItemInfoArr,.UserOptionsArr,.ItemCongeriesArr,AddNo)
        ///将新增的行信息添加到ItemOrdsArr数组中，用于后续添加行的逻辑判断
        s Index=$I(ItemCongeriesArr)
        m ItemCongeriesArr(Index)=OneItemInfoArr
        d AddItemToRowArr(.AddNo,.ItemOrdsArr,.OneItemInfoArr,.BaseParamArr)
    }
    d SynGroupOrdData(.ItemCongeriesArr)
    s ItemCongeriesJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.ItemCongeriesArr)
    q ItemCongeriesJson
SynGroupOrdData(ItemCongeriesArr)
    n (ItemCongeriesArr)
    //给成组的医嘱设置同步设置是否呈独立行显示在界面上
    s i=0
    for {
        s i=$O(ItemCongeriesArr(i))
        q:(i="")
        s SingleRowFlag=$G(ItemCongeriesArr(i,"OrdListInfo","SingleRowFlag"))
        if (SingleRowFlag'="Y"){
            continue
        }
        s CalSeqNo=$G(ItemCongeriesArr(i,"OrdListInfo","CalSeqNo"))
        s j=0
        for {
            s j=$O(ItemCongeriesArr(j))
            q:(j="")
            if (j=i){
                continue
            }
            s SubCalSeqNo=$G(ItemCongeriesArr(j,"OrdListInfo","CalSeqNo"))
            if ($P(SubCalSeqNo,".")=$P(CalSeqNo,"."))&&(CalSeqNo'=""){
                s ItemCongeriesArr(j,"OrdListInfo","SingleRowFlag")=SingleRowFlag
            }
        }
    }
    q
    ///将新获取的行数据添加到行数组记录里面
AddItemToRowArr(AddNo,ItemOrdsArr,OneItemInfoArr,BaseParamArr)
    n (AddNo,ItemOrdsArr,OneItemInfoArr,BaseParamArr)
    q:+$G(OneItemInfoArr("ErrCode"))<0
    s AddNo=AddNo+1
    s i=1+$O(ItemOrdsArr("ItemOrds",""),-1)
    m ItemOrdsArr("ItemOrds",i)=OneItemInfoArr("OrdListInfo")
    s ItemOrdsArr("ItemOrds",i,"OrderItemRowid")=""
    s ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")=ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
    //后台不计算关联，这部分数据不用保证正确   --现在后台的行号并未与前台的行号进行严格的对照，AddNo的功能暂未实现
    s ItemOrdsArr("ItemOrds",i,"rowid")=BaseParamArr("rowid")+AddNo
    s ItemOrdsArr("ItemOrds",i,"OrderSeqNo")=1+$G(ItemOrdsArr("ItemOrds",i-1,"OrderSeqNo"))
    s ItemOrdsArr("ItemOrds",i,"OrderMasterSeqNo")=""
    s ItemOrdsArr("ItemOrds",i,"AddNo")=AddNo
    q
    
SetUserOptionsArr(UserOptionsJsonArr,UserOptionsArr)
    n (UserOptionsJsonArr,UserOptionsArr)
    s i=""
    for {
        s i=$o(UserOptionsJsonArr(i))
        q:(i="")
        s rowid=$G(UserOptionsJsonArr(i,"rowid"))
        continue:(rowid="")
        s j=""
        for {
            s j=$o(UserOptionsJsonArr(i,"UserOption",j))
            q:(j="")
            s Type=$G(UserOptionsJsonArr(i,"UserOption",j,"Type"))
            continue:(Type="")
            s Index=$o(UserOptionsArr(rowid,Type,""),-1)+1
            m UserOptionsArr(rowid,Type,Index)=UserOptionsJsonArr(i,"UserOption",j)
        }
    }
    q
}

/// creator:	谭吉善
/// date:		2018-6-2
/// desc:		获取医嘱录入新增行单个对象的默认值
/// input:		MainBaseParamArr:基本参数键值对,主要用于获取BaseParamArr
/// 			MainOrdCongeriesArr:需要添加的医嘱项及附加信息（医嘱套或复制医嘱）的集合
/// 			OrdCongeriesIndex:MainOrdCongeriesArr集合的计数器,用于本次方法获取的主要医嘱项明细
/// 			ItemOrdsArr:已新增到行上的医嘱
/// 			RowDataArr:行默认数据
/// 			UserOptionsArr:用户选项信息的集合，一般用于confirm前台的递归调用后台方法，一定要处理,否则会导致死循环
/// 			ItemCongeriesArr:根据之前的运算已确定需要输出的医嘱集合，一般情况下使用ItemOrdsArr即可，仅在修改子医嘱信息同步修改主医嘱信息等极其特殊的场景下会使用（子医嘱需皮试，需修改主医嘱用法）。
/// 			AddNo:行号的计数器
/// output:		JSON:
/// {
/// 	ErrCode:非0-停止新增,
/// 	ErrMsg:错误描述,
/// 	CallBakFunS:[{
/// 		CallBakFunCode:回调代码
/// 		CallBakFunParams:回调方法参数
/// 	},...,...}],
/// 	ParamData:{
/// 		OrderType:"",
/// 		....
/// 	}
/// }
/// w ##Class(web.DHCOEOrdItemView).GetItemToList("")
ClassMethod GetItemToList(ByRef MainBaseParamArr, ByRef MainOrdCongeriesArr, OrdCongeriesIndex As %String, ByRef ItemOrdsArr, ByRef RowDataArr, ByRef ItemRowDataArr, ByRef UserOptionsArr, ByRef ItemCongeriesArr, AddNo As %String) As %String [ ProcedureBlock = 0 ]
{
    n (MainBaseParamArr,MainOrdCongeriesArr,OrdCongeriesIndex, ItemOrdsArr, RowDataArr, ItemRowDataArr, UserOptionsArr,ItemCongeriesArr, AddNo)
    k OrdCongeriesArr
    m OrdCongeriesArr=MainOrdCongeriesArr(OrdCongeriesIndex)
    //ArcosArr:复制或医嘱套带出的医嘱默认信息
    k ArcosArr
    d ..InitARCOSArr(.ArcosArr,.MainBaseParamArr,.OrdCongeriesArr)					//初始化前台传入的医嘱明细,
    //BaseParamArr:基本参数键值对 Json结构
    k BaseParamArr
    d ..InitBaseParamArr(.BaseParamArr,.MainBaseParamArr,.OrdCongeriesArr,AddNo)	//初始化基本参数
    ///UserOptionArr:用户选项信息，一般用于confirm前台的递归调用后台方法，一定要处理,否则会导致死循环
    k UserOptionArr
    m UserOptionArr=UserOptionsArr(BaseParamArr("rowid"))
    
    s CallBackFunStr=""
    s OutInfo="0^^^^"
    s Adm=$G(BaseParamArr("Adm"))
    s OrderBillTypeRowid=$G(BaseParamArr("OrderBillTypeRowid"))
    s LogonDep=$G(BaseParamArr("LogonDep"))
    s OrderARCIMRowid=$G(BaseParamArr("OrderARCIMRowid"))
    s OrderOpenForAllHosp=$G(BaseParamArr("OrderOpenForAllHosp"))
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s ItemDefaultRowId=$G(BaseParamArr("ItemDefaultRowId"))
    s RelocRowID=$G(BaseParamArr("RelocRowID"))
    s MaterialBarcode=$G(BaseParamArr("MaterialBarcode"))
    s ITMRowId=$G(BaseParamArr("ITMRowId"))
    s PPRowId=$G(BaseParamArr("PPRowId"))
    s OrderBodyPartLabel=$G(BaseParamArr("OrderBodyPartLabel"))
    s DCAInfoStr=$G(BaseParamArr("DCAInfoStr"))
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s OriginalArcimRowID=OrderARCIMRowid
    //查找是否有替换的项目
    s ReplaceArcimRowId=##class(DHCDoc.DHCDocConfig.ItemOrderQtyLimit).GetReplaceItm(Adm,OrderARCIMRowid)
    if (ReplaceArcimRowId'="") {
        s OrderARCIMRowid=ReplaceArcimRowId
        s BaseParamArr("OrderARCIMRowid")=OrderARCIMRowid
        s ITMRowId="",ItemDefaultRowId=""
    }
    s ExpStr = MaterialBarcode_"^"_ITMRowId_"^"_PPRowId_"^^"_OrderBodyPartLabel_"^"_DCAInfoStr_"^"_OriginalArcimRowID_"^Y"
    ///医嘱项明细信息
    s EPARCIMDetail=##Class(web.DHCDocOrderCommon).GetEPARCIMDetail(
    Adm, OrderBillTypeRowid, LogonDep, OrderARCIMRowid, OrderOpenForAllHosp, 
    SessionStr, ItemDefaultRowId, RelocRowID, ExpStr)
    //--初始化默认数据
    k ParamArr
    d InitParamArr(.ParamArr,.ItemOrdsArr,.BaseParamArr,.ArcosArr,EPARCIMDetail)
    //--录入限制或提示
    s OutInfo=$$BaseValidCheck(.ParamArr,.ItemOrdsArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--互斥医嘱提示
    s OutInfo=$$CheckConflict(.ParamArr,.ItemOrdsArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--重复子类的提醒
    s OutInfo=$$CheckDupOrderItemCat(.ParamArr,.ItemOrdsArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--第一批默认值，含基础频次-标本
    d SetBaseDefaultInfo(.ParamArr,.RowDataArr,.BaseParamArr,.CallBackFunStr,.ArcosArr)
    //--引导皮试录入
    s OutInfo=$$GuideAllergy(.ParamArr,.BaseParamArr,.ArcosArr,.UserOptionArr,.ItemCongeriesArr,.ItemOrdsArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--计算BillType默认值并校验BillType
    s OutInfo=$$SetDefautBillType(.ParamArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--设置是否呈独立行显示在界面上（是否独立在行上显示由前台决定，这里只打标记）
    d SetSingleRowFlag(.ParamArr,.BaseParamArr)
    //--重算医嘱套数据。若存在ReplaceArcimRowId的问题，需在ResArcosArr内做一次统一的数据验证
    d ResArcosArr(.ArcosArr,.BaseParamArr,EPARCIMDetail)
    m ParamArr=ArcosArr
    //--得到基本单位数量
    d SetBaseDoseQty(.ParamArr,.BaseParamArr)
    //--★得到医嘱类型*********
    s NurseLinkFlag="1"
    s OutInfo=$$SetOrderPrior(.ParamArr,.BaseParamArr,.ArcosArr,.RowDataArr,.CallBackFunStr,.NurseLinkFlag)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--全排斥医嘱和长期医嘱不能同时开立验证
    s OutInfo=$$CheckStopAllLongOrd(.ParamArr,.ItemOrdsArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--得到皮试备注信息
    d SetOrderAction(.ParamArr,.BaseParamArr,.ArcosArr,.RowDataArr)
    /*
    //--过敏检查
    s OutInfo=$$CheckItemAllergy(.ParamArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    */
    //--判断重复提示及药品处方的一些控制
    s OutInfo=$$CheckPrescAndDupOrder(.ParamArr,.BaseParamArr,.ItemOrdsArr,.UserOptionArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--根据优先级得到医嘱的频次
    d SetFreqByPrior(.ParamArr,.BaseParamArr)
    //--设置医嘱附加说明
    d SetOrdPriorRemarks(.ParamArr,.BaseParamArr,.RowDataArr)
    //--得到当前接收科室串
    s OutInfo=$$SetCurrentRecLocStr(.ParamArr,.BaseParamArr,.MainOrdCongeriesArr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--判断库存，置默认接收科室
    s OutInfo=$$SetDefaultRecLoc(.ParamArr,.BaseParamArr,.RowDataArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //---设置默认数量及数量单位-new
    d SetBillUOMStr(.ParamArr,.BaseParamArr,.CallBackFunStr)
    //--获取批次价
    s OutInfo=$$SetOrdPrice(.ParamArr,.BaseParamArr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
   
    //--设置静配标志
    d SetOrdNeedPIVAFlag(.ParamArr,.BaseParamArr)
    //--设置医嘱附加说明
    //d SetOrdPriorRemarks(.ParamArr,.BaseParamArr,.RowDataArr)
    //--医嘱信息弹窗的回调
    d SetOrderMsgAlert(.ParamArr,.BaseParamArr,.CallBackFunStr)
    //--医保基本限制审查
    s OutInfo=$$CheckItemInsurLimit(.ParamArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--医保相关业务审查(是否自费,适应症,医保接口,其他医保业务控制)
    s OutInfo=$$CheckItemInsur(.ParamArr,.BaseParamArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //--补录关联医嘱  设置关联信息
    d SetLinkedMaster(.ParamArr,.BaseParamArr,NurseLinkFlag)
    //--强制修改不合法单次剂量、频次、疗程和数量-部分复用前台逻辑CheckFreqAndPackQty
    d ReSetOrderAndPackQty(.ParamArr,.BaseParamArr)
    //--处理特殊频次相关逻辑、前台选择星期、分发时间相关的问题,同步修改医嘱开始时间
    d SetOrderFreqDispTimeStr(.ParamArr,.UserOptionArr,.ItemOrdsArr,.CallBackFunStr,.BaseParamArr)
    //--处理不规则单次剂量医嘱-要放到SetOrderFreqDispTimeStr之后，适配不规则分发时间频次 
    //----wqy 放在SetPackQty首日计算后调用,为了解决首日不同剂量的问题
    ;d CheckItemSameFreqDifferentDoses(.ParamArr,.BaseParamArr,.ItemOrdsArr,.UserOptionArr,.CallBackFunStr)
    //--计算数量+首日次数
    d SetPackQty(.ParamArr,.BaseParamArr,.ArcosArr,.CallBackFunStr,.ItemOrdsArr,.UserOptionArr)
    //--强制修改不合法数量-复用前台逻辑--在SetPackQty里已经调用无须重复调用
    ;d ReSetOrderPackQty(.ParamArr,.BaseParamArr,.ArcosArr)
    //--最后计算所有(计算类型的值,但是涉及到整包装数的计算放到前台，比如OrdSum等), OrderUsableDays\OrderLocalInfusionQty
    //--因为数量的值可能会受前台confirm选项的影响，无法完全后台计算;涉及金额计算，要放到ReSetOrderPackQty之后
    d SetCalculateValue(.ParamArr,.BaseParamArr)
    //--计算成组医嘱关系(复制或医嘱套会走这段程序)-放到最后应该没问题
    d SetMasterSeqNo(.ParamArr,.BaseParamArr,.ItemOrdsArr,.ArcosArr,.CallBackFunStr,.UserOptionArr)
    //--带入皮试附加医嘱,因为内部验证的是ParamArr的属性且有可能会有医嘱套的情况，必须放到ResArcosArr、SetMasterSeqNo后面，对ParamArr的原始属性没有修改，可以放在最后
    s OutInfo=$$AppendAllergyOrder(.ParamArr,.BaseParamArr,.ArcosArr,.UserOptionArr,.MainOrdCongeriesArr,OrdCongeriesIndex,.ItemOrdsArr,.CallBackFunStr)
    q:(+OutInfo)<0 $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
    //---配置附加列信息
    d SetOrdOtherInfo(.ParamArr,.BaseParamArr)
    //--翻译
    d TranByParamArr(.ParamArr,.BaseParamArr)
    q $$GetItemRowDataJsonObj(OutInfo,CallBackFunStr,.ParamArr,.ItemRowDataArr)
GuideAllergy(ParamArr,BaseParamArr,ArcosArr,UserOptionArr,ItemCongeriesArr,ItemOrdsArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,ArcosArr,UserOptionArr,ItemCongeriesArr,ItemOrdsArr,CallBackFunStr)
    
    s EpisodeID=BaseParamArr("Adm")
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderName =ParamArr("OrderName")
    s OrderStartDate=ParamArr("OrderStartDate")
    s OrderHiddenPara=ParamArr("OrderHiddenPara")
    s OrderDirectEntryAuth=ParamArr("OrderDirectEntryAuth")
    s OrderDirectEntryDetails=ParamArr("OrderDirectEntryDetails")
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    s ARCOSInstrRowid=$G(ArcosArr("OrderInstrRowid"))
    s ARCOSActionRowid=$G(ArcosArr("OrderActionRowid"))
    s ARCOSSkinTest=$G(ArcosArr("OrderSkinTest"))
    s ViewBindSource=$G(ArcosArr("ViewBindSource"))
    s OrderAntibApplyRowid=$G(ArcosArr("OrderAntibApplyRowid"))
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s STFreqRowid=$O(^PHCFR(0,"Desc1","ST",0))
    s ONCEFreqRowid=$O(^PHCFR(0,"Code","ONCE",0))
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s OutInfo="0^^^^^"
    i OrderDirectEntryDetails'="" s OrderDirectEntryDetails=","_OrderDirectEntryDetails_","
    ;皮试用法
    s SkinTestInstr=..%GetConfig("SkinTestInstr",HOSPID)
    s (FormInstrRowid,FormInstrDesc)=""
    s DrgformRowid=##class(web.DHCDocOrderEntry).GetDrgForm(OrderARCIMRowid)
    if (DrgformRowid'=""){
        s FormInstrRowid=$p($g(^PHCD(+DrgformRowid,"DF",$P(DrgformRowid,"||",2),1)),"^",5)
        if (FormInstrRowid'=""){
          s Active=$P($g(^PHCIN(FormInstrRowid)),"^",4)
          s AvailableType=$P($g(^PHCIN(FormInstrRowid)),"^",5)
          if ((AvailableType'="")&&(AvailableType'[PAAdmType))||(Active="N"){
              s FormInstrRowid=""
          }
          /*
          if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_FormInstrRowid_"^")){
              s FormInstrRowid=""
          }
          */
        }
        if (FormInstrRowid'=""){
            s FormInstrDesc=$P($g(^PHCIN(FormInstrRowid)),"^",2)
        }
    }
    
    ;皮试医嘱需要走申请流程
    s SkinTestNeedApply=..%GetConfig("SkinTestNeedApply",HOSPID)
    if (OrderDirectEntryAuth="N"){
        //如果仅受抗菌药物权限控制，且配置为皮试医嘱也需要申请时，不再弹窗。在抗菌药物申请通过后，统一弹窗
        if ((SkinTestNeedApply="1")&&((OrderDirectEntryDetails'[",AntAuthAdopt,")))
            ||(OrderDirectEntryDetails[",AntNoAuth,"){
            //没有权限录入的时候走申请流程，防止抗菌药物在前台误进入了皮试用法的处理流程中
            if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_ARCOSInstrRowid_"^")){
                k ArcosArr("OrderInstr")
                   k ArcosArr("OrderInstrRowid")
            }
            if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_OrderInstrRowid_"^")){
                
                if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_FormInstrRowid_"^")){
                    s ParamArr("OrderInstr")=""
                    s ParamArr("OrderInstrRowid")=""
                }else{
                    s ParamArr("OrderInstr")=FormInstrDesc
                    s ParamArr("OrderInstrRowid")=FormInstrRowid
                }
            }
            q OutInfo
        }
    }
    ;按照默认皮试及皮试备注审核,不允许修改
    s DisableOrdSkinChange=..%GetConfig("DisableOrdSkinChange",HOSPID)
    if (DisableOrdSkinChange="1")&&(ViewBindSource'="AutoAppendAllergy"){
        //不允许用户通过常用用法、医嘱套等设置皮试用法及皮试备注信息
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_ARCOSInstrRowid_"^")){
            k ArcosArr("OrderInstr")
            k ArcosArr("OrderInstrRowid")
        }
        k ArcosArr("OrderActionRowid")
        k ArcosArr("OrderSkinTest")
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")'[("^"_FormInstrRowid_"^")){
            if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_OrderInstrRowid_"^")){
                s ParamArr("OrderInstr")=""
                s ParamArr("OrderInstrRowid")=""
            }
            s ParamArr("OrderSkinTest")="N"
            s ParamArr("OrderActionRowid")=""
            s ParamArr("OrderAction")=""
            s ParamArr("ItemDefSkinAction")=""
        }
    }
    ;皮试医嘱类型控制为临时
    s CFSkinTestPriorShort=..%GetConfig("SkinTestPriorShort",HOSPID)
    
    s SkinInfo=""
    s AllergyTableJson=##Class(web.DHCOEOrderGuideAllergy).GetGuideAllergyTableJson(EpisodeID,OrderARCIMRowid,OrderStartDate,.SkinInfo)
    /*
    Type:(PositiveSkin:皮试阳性,NegativeSkin:皮试阴性,NoResultSkin:皮试未出结果,TMTreat:存在脱敏治疗记录,Treat:存在治疗记录,
    PAAllergy:存在过敏记录,PHAClassTypePAAllergy:存在同药学分类过敏记录,NotSkinOrd:无皮试医嘱)
    */
    ;GuideAllergy
    s SkinType=$P(SkinInfo,"^",1)
    s SkinMsg=$P(SkinInfo,"^",2)
    s SkinDesensitFlag=$P(SkinInfo,"^",3)	;允许脱敏
    s SkinNoTestFlag=$P(SkinInfo,"^",4)		;允许免试
    s SkinExceptionFlag=$P(SkinInfo,"^",5)	;控制例外
    s DefNoTest=$P(SkinInfo,"^",8)			;默认免试

    if (SkinType=""){
        //如果基础数据维护的就是皮试，则默认置皮试勾选
        if (SkinTestInstr'="")&&(
            ("^"_SkinTestInstr_"^")[("^"_FormInstrRowid_"^")
            &&(FormInstrRowid=ParamArr("OrderInstrRowid"))
            ){
            s ParamArr("OrderSkinTest")="Y"
            s ParamArr("OrderActionRowid")=""
            s ParamArr("OrderAction")=""
        }
        q OutInfo
    }
    ;00000
    s NeedSkinTestINCI="Y"
    s $P(OrderHiddenPara,$C(1),8)=NeedSkinTestINCI
    s ParamArr("OrderHiddenPara")=OrderHiddenPara
    s ParamArr("GuideSkinInfo")=SkinInfo
    //如果复制\医嘱套带有典型的皮试、治疗属性，则不需要再进行皮试引导
    /*
    if (ARCOSSkinTest="Y")||(ARCOSActionRowid'="")||((SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_ARCOSInstrRowid_"^"))){
        //如果是需要绑定皮试医嘱，还需要弹窗处理
        q OutInfo
    }
    */
    //当前皮试阳性且无法脱敏的情况，复制、医嘱套无法处理，这个对所有医嘱进行皮试引导
    if (ViewBindSource="AutoAppendAllergy"){
        q OutInfo
    }
    
    //如果待审核列表中存在用法为皮试的医嘱，再录入同类医嘱直接认定为治疗，不再弹窗
    s HaveSkinRecord="N"
    //如果待审核列表中存在治疗的医嘱，再录入同类医嘱直接认定为皮试，不再弹窗
    s HaveTreatRecord="N"
    ;获取关联皮试的医嘱列表
    k AppendArcimList
    d ##Class(web.DHCOEOrderGuideAllergy).BuildAppendAllergyOrder(EpisodeID,OrderARCIMRowid,OrderStartDate,.AppendArcimList)
    if ($D(AppendArcimList)){
        s i =""
        for{
            s i=$O(ItemOrdsArr("ItemOrds",i))
            q:(i="")
            s iOrderARCIMRowid=ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
            if ('$D(AppendArcimList("Drug",iOrderARCIMRowid)))&&(iOrderARCIMRowid'=OrderARCIMRowid){
                continue   
            }
            s OrderActionRowid=ItemOrdsArr("ItemOrds",i,"OrderActionRowid")
            s OrderSkinTest=ItemOrdsArr("ItemOrds",i,"OrderSkinTest")
            s iOrderInstrRowid=ItemOrdsArr("ItemOrds",i,"OrderInstrRowid")
            if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_iOrderInstrRowid_"^")){
                s HaveSkinRecord="Y"
            }elseif (OrderSkinTest="Y")||(OrderActionRowid'=""){
                s HaveTreatRecord="Y"
                
            }
        }
    }
    if (OrderDirectEntryDetails[",AntAuthAdopt,")&&(SkinTestNeedApply=0){
        //抗菌药物已审核通过，且皮试用药不需要走申请流程,则默认按照治疗处理
        s GuideAllergyInfo="Treat^^^"
    }elseif (HaveSkinRecord="Y")&&(HaveTreatRecord="Y"){
        //默认按照治疗处理
        s GuideAllergyInfo="Treat^^^"
    }elseif (HaveSkinRecord="Y"){
        //默认按照治疗处理
        s GuideAllergyInfo="Treat^^^"
    }elseif (HaveSkinRecord="Y"){
        //默认按照皮试处理
        s GuideAllergyInfo="SkinTest^^^"
    }else{
        s i=$O(UserOptionArr("GuideAllergy",0))
        if (i=""){
            s CallBackFunParams=OrderARCIMRowid_";"_OrderName
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"GuideAllergy",CallBackFunParams)
            q CallBackFunStr
        }
        s GuideAllergyInfo=$G(UserOptionArr("GuideAllergy",i,"Value"))
        if (GuideAllergyInfo=""){
            s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 请选择皮试引导选项",langid)_"^^^^^^^"
            q OutInfo
        }
    }
    //根据用户选择的开立目，通过修改ArcosArr去影响后续的计算逻辑
    s GuideAllergyType=$P(GuideAllergyInfo,"^",1)
    s MSCheck=$P(GuideAllergyInfo,"^",2)
    if (GuideAllergyType="Exit"){
        s OutInfo="-100^^^^^^^^"
        q OutInfo
    }
    s ArcosNoTestFlag="N"
    if (SkinNoTestFlag="Y")&&(MSCheck="Y"){
        s ArcosNoTestFlag="Y"
    }
    if (GuideAllergyType="SkinTest"){
        //选择皮试时,修改用法及皮试标志,同时需要判断是否需要修改关联医嘱的用法数据
        //if (CFSkinTestPriorShort=1) {
            if ($G(ParamArr("SpecOrderPriorRowid"))="")||(##class(appcom.OEOrdItem).ISLongOrderPrior($G(ParamArr("SpecOrderPriorRowid")))){
                s ParamArr("SpecOrderPriorRowid")=$O(^OECPR(0,"Code","NORM",0))
            }
        //}
        if (SkinTestInstr=""){
            s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 未维护有效的皮试用法,请联系系统管理员",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
            q
        }
        k ArcosArr("SpecOrderPrior")
        k ArcosArr("SpecOrderPriorRowid")
        k ArcosArr("OrderPriorRemarks")
        k ArcosArr("OrderPriorRemarksRowId")
        k ArcosArr("OrderAction")
        k ArcosArr("OrderActionRowid")
        s ArcosArr("OrderInstr")=$P($g(^PHCIN(+SkinTestInstr)),"^",2)
        s ArcosArr("OrderInstrRowid")=+SkinTestInstr
        if (ONCEFreqRowid'=""){
            s ArcosArr("OrderFreq")=$P($g(^PHCFR(ONCEFreqRowid)),"^",3)
            s ArcosArr("OrderFreqRowid")=ONCEFreqRowid
            s ArcosArr("OrderFreqFactor")=$P($g(^PHCFR(ONCEFreqRowid)),"^",2)
            s ArcosArr("OrderFreqInterval")=$P($g(^PHCFR(ONCEFreqRowid)),"^",5)
        }else{
           s ArcosArr("OrderFreq")=""
            s ArcosArr("OrderFreqRowid")=""
            s ArcosArr("OrderFreqFactor")=1
            s ArcosArr("OrderFreqInterval")=1
        }
        s ArcosArr("OrderSkinTest")="Y"
        ;----
        //TPDO:处理关联主医嘱的数据
    }elseif (GuideAllergyType="Treat"){
        //选择治疗时,修改用法及皮试标志,同时需要判断是否需要修改关联医嘱的用法数据
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_ARCOSInstrRowid_"^")){
            k ArcosArr("OrderInstr")
            k ArcosArr("OrderInstrRowid")
        }
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_OrderInstrRowid_"^")){
            s ParamArr("OrderInstr")=FormInstrDesc
            s ParamArr("OrderInstrRowid")=FormInstrRowid
        }
        
        //皮试阳性
        if (SkinType="PositiveSkin"){
            if (SkinDesensitFlag="Y"){
                s ArcosArr("OrderSkinTest")="N"
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","TM",0))
                if (OrderActionRowid'=""){
                    s ArcosArr("OrderActionRowid")=OrderActionRowid
                    s ArcosArr("OrderAction")=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
                }
            }else{
                s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 皮试阳性，且不允许进行脱敏治疗，不允许进行治疗使用",langid)_"^^^^^^^"
                   q OutInfo
            }
        }elseif (SkinType="TMTreat"){
            //存在脱敏治疗记录
            s ArcosArr("OrderSkinTest")="N"
            if (ArcosNoTestFlag="Y"){
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","MS",0))
            }else{
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","TM",0))
            }
            if (OrderActionRowid'=""){
                s ArcosArr("OrderActionRowid")=OrderActionRowid
                s ArcosArr("OrderAction")=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
            }
        }elseif (SkinType="NegativeSkin"){
            //皮试阴性
            s ArcosArr("OrderSkinTest")="N"
            if (ArcosNoTestFlag="Y"){
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","MS",0))
            }else{
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","YX",0))
            }
            if (OrderActionRowid'=""){
                s ArcosArr("OrderActionRowid")=OrderActionRowid
                s ArcosArr("OrderAction")=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
            }
        }elseif (SkinType="NoResultSkin"){
            //皮试未出结果
            s ArcosArr("OrderSkinTest")="Y"
            s ArcosArr("OrderActionRowid")=""
            s ArcosArr("OrderAction")=""
        }elseif (SkinType="Treat"){
            //存在治疗记录
            s ArcosArr("OrderSkinTest")="N"
            if (ArcosNoTestFlag="Y"){
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","MS",0))
            }else{
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","XZ",0))
            }
            if (OrderActionRowid'=""){
                s ArcosArr("OrderActionRowid")=OrderActionRowid
                s ArcosArr("OrderAction")=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
            }
        }elseif (SkinType="NotSkinOrd"){
            //无皮试医嘱
            if (ArcosNoTestFlag="Y"){
                s ArcosArr("OrderSkinTest")="N"
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","MS",0))
                if (OrderActionRowid'=""){
                    s ArcosArr("OrderActionRowid")=OrderActionRowid
                    s ArcosArr("OrderAction")=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
                }
            }else{
                s ArcosArr("OrderSkinTest")="Y"
                s ArcosArr("OrderActionRowid")=""
                s ArcosArr("OrderAction")=""
            }
        }elseif (SkinType["PAAllergy"){
            //存在过敏记录
            if (ArcosNoTestFlag="Y"){
                s ArcosArr("OrderSkinTest")="N"
                s OrderActionRowid=$O(^OEC("ACT",0,"Code","MS",0))
                if (OrderActionRowid'=""){
                    s ArcosArr("OrderActionRowid")=OrderActionRowid
                    s ArcosArr("OrderAction")=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
                }
            }else{
                s ArcosArr("OrderSkinTest")="Y"
                s ArcosArr("OrderActionRowid")=""
                s ArcosArr("OrderAction")=""
            }
        }
    }
    
    ;GuideAllergy Over------
    s OutInfo="0^^^^^^"
    q OutInfo
AppendAllergyOrder(ParamArr,BaseParamArr,ArcosArr,UserOptionArr,MainOrdCongeriesArr,OrdCongeriesIndex,ItemOrdsArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,ArcosArr,UserOptionArr,MainOrdCongeriesArr,OrdCongeriesIndex,ItemOrdsArr,CallBackFunStr)
    ;AppendAllergyOrder
    
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderName =ParamArr("OrderName")
    s OrderStartDate=ParamArr("OrderStartDate")
    s OrderActionRowid=$G(ParamArr("OrderActionRowid"))
    s OrderSkinTest=$G(ParamArr("OrderSkinTest"))
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    s ViewBindSource=$G(ParamArr("ViewBindSource"))
    s OrderDirectEntryAuth=ParamArr("OrderDirectEntryAuth")
    s HOSPID=$P(SessionStr,"^",4)
    s OutInfo="0^^^^^"
    if (OrderDirectEntryAuth="N"){
        q OutInfo
    }
    ;皮试用法
    s SkinTestInstr=..%GetConfig("SkinTestInstr",HOSPID)
    //仅针对治疗记录进行自动绑定
    if ((SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_OrderInstrRowid_"^"))){
        q OutInfo
    }
    //只有需要皮试的情况下，才插入皮试医嘱
    if (OrderSkinTest'="Y")||((OrderActionRowid'="")&&("^TM^XZ^YX^MS^"[OrderActionRowid)){
        q OutInfo
    }
    
    if (ViewBindSource="AutoAppendAllergy"){
        q OutInfo
    }
    //皮试引导窗口未完成时,不能定位当前医嘱是否属于皮试，先退出
    if (CallBackFunStr["GuideAllergy"){
        q OutInfo
    }
    ;获取待关联医嘱列表
    k AppendArcimList
    d ##Class(web.DHCOEOrderGuideAllergy).BuildAppendAllergyOrder(EpisodeID,OrderARCIMRowid,OrderStartDate,.AppendArcimList)
    if '$D(AppendArcimList){
        q OutInfo
    }
    //如果已生成列表中包含了对应的皮试医嘱，则可以认定为不在需要自动添加
    s HaveSkinRecord="N"
    s i =""
    for{
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        s iOrderARCIMRowid=ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
        if '$D(AppendArcimList("Drug",iOrderARCIMRowid)){
            continue   
        }
        s iOrderInstrRowid=ItemOrdsArr("ItemOrds",i,"OrderInstrRowid")
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_iOrderInstrRowid_"^")){
            s HaveSkinRecord="Y"
        }
    }
    if (HaveSkinRecord="Y"){
        q OutInfo
    }
    //如果待生成列表中包含了对应的皮试医嘱，则也可以认定为不在需要自动添加
    s i =OrdCongeriesIndex
    for{
        s i=$O(MainOrdCongeriesArr(i))
        q:(i="")
        s iOrderARCIMRowid=MainOrdCongeriesArr(i,"OrderARCIMRowid")
        if '$D(AppendArcimList("Drug",iOrderARCIMRowid)){
            continue   
        }
        //一次性下多条医嘱的情况下，目前只有复制、医嘱套，ParamS必然有值且值最终有效
        s iItemDefaultRowId=$G(MainOrdCongeriesArr(i,"ItemDefaultRowId"))	;用法常用
        s iParamS=$G(MainOrdCongeriesArr(i,"ParamS"))
        if (iParamS=""){
            continue
        }
        s ispecinstructionstr = $P(iParamS, "^", 3)
        s SpecOrderInstr = $P(ispecinstructionstr, $C(1), 1) //用法
        s SpecOrderInstrRowid = $P(ispecinstructionstr, $C(1), 2)
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_SpecOrderInstrRowid_"^")){
            s HaveSkinRecord="Y"
        }
    }
    if (HaveSkinRecord="Y"){
        q OutInfo
    }
    s AppendAllergySeqNo=""
    //如果是维护了多组皮试用药，则需要与前台交互，让用户选择录入
    if $O(AppendArcimList("All",0))'=$O(AppendArcimList("All",""),-1) {
        s i=$O(UserOptionArr("AppendAllergyOrder",0))
        if (i=""){
            s CallBackFunParams=OrderARCIMRowid_";"_OrderName_";"_OrderStartDate
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"AppendAllergyOrder",CallBackFunParams)
            q CallBackFunStr
        }
        s GuideAllergyInfo=$G(UserOptionArr("AppendAllergyOrder",i,"Value"))
        if (GuideAllergyInfo=""){
            //s OutInfo="-1^"_OrderName_" 请选择皮试药品记录^^^^^^^"
            //这里先认定为如果客户不选择，则认为该治疗药品不需要自动带入皮试皮试药品
            q OutInfo
        }
        s AppendAllergySeqNo=$P(GuideAllergyInfo,"^",1)
    }else{
        s AppendAllergySeqNo=$O(AppendArcimList("All",0))
    }
    if (AppendAllergySeqNo=""){
        q OutInfo
    }
    s ViewBindSource="AutoAppendAllergy"
    s MaxOrdCongeries=$O(MainOrdCongeriesArr(""),-1)
    s AppendOrdDetails=AppendArcimList("All",AppendAllergySeqNo)
    s CalSeqNo=MaxOrdCongeries+1
    d AppendOrdCongeries
    s SubNo=0
    s IndexAppend=0
    for {
        s IndexAppend=$O(AppendArcimList("All",AppendAllergySeqNo,"Sub",IndexAppend))
        q:(IndexAppend="")
        s SubNo=SubNo+1
        s AppendOrdDetails=$G(AppendArcimList("All",AppendAllergySeqNo,"Sub",IndexAppend))
        s CalSeqNo=$P(CalSeqNo,".")_"."_SubNo
        d AppendOrdCongeries
    }
    ;AllergyAppend over
    s OutInfo="0^^^^^^"
    q OutInfo
AppendOrdCongeries
    q:(AppendOrdDetails="")
    q:($G(CalSeqNo)="")	;上层逻辑计算CalSeqNo
    s ViewBindSource=$G(ViewBindSource)

    s IPDefaultDurRowId=..%GetConfig("IPDefaultDuration",HOSPID)
    s AppendOrderDurRowId=IPDefaultDurRowId
    s MaxOrdCongeries=$O(MainOrdCongeriesArr(""),-1)
    s MaxOrdCongeries=MaxOrdCongeries+1
    s AppendARCIMRowid=$P(AppendOrdDetails,"^",1)
    s AppendPriorRowID=$P(AppendOrdDetails,"^",2)
    s AppendDoseQty=$P(AppendOrdDetails,"^",3)
    s AppendDoseUnitDr=$P(AppendOrdDetails,"^",4)
    s AppendInstrDr=$P(AppendOrdDetails,"^",5)
    s AppendFreqDr=$P(AppendOrdDetails,"^",6)
    s AppendSkinTest=$P(AppendOrdDetails,"^",7)
    q:(AppendARCIMRowid="")
    //以下代码参考##Class(web.DHCDocMain).CreateCopyItem或InitARCOSArr
    s (AppendOrderFreqFactor,AppendOrderDurFactor)=1
    s (AppendDoseUnit,AppendOrderFreq,AppendOrderFreqInterval,AppendOrderInstr,AppendOrderDur)=""
    s (AppendPriorRowid,AppendPrior,AppendRemarksRowid,AppendRemarks)=""
    s (AppendActionRowid,AppendAction)=""
    s:+AppendDoseUnitDr'=0 AppendDoseUnit=$p($g(^CT("UOM",AppendDoseUnitDr)),"^")
    if AppendFreqDr'="" {
        s AppendOrderFreq=$P($g(^PHCFR(AppendFreqDr)),"^",3)
        s AppendOrderFreqFactor=$P($g(^PHCFR(AppendFreqDr)),"^",2)
        s AppendOrderFreqInterval=$P($g(^PHCFR(AppendFreqDr)),"^",5)
     }
     s:+AppendInstrDr'=0 AppendOrderInstr=$p(^PHCIN(AppendInstrDr),"^",2)
     if AppendOrderDurRowId'="" {
        s AppendOrderDur=$P($g(^PHCDU(AppendOrderDurRowId)),"^",3)
        s AppendOrderDurFactor=$P($g(^PHCDU(AppendOrderDurRowId)),"^",2)
     }
     if (AppendPriorRowID'=""){
         
        s AppendPriorStr=..SplitOrderPriorRowid(AppendPriorRowID)
        s AppendPriorRowid=$P(AppendPriorStr,"^",1)
        s AppendPrior=$P(AppendPriorStr,"^",2)
        s AppendRemarksRowid=$P(AppendPriorStr,"^",3)
        s AppendRemarks=$P(AppendPriorStr,"^",4)
        
        //s AppendPrior=$p($g(^OECPR(AppendPriorRowID)),"^")
    }
     s AppendSkinTest=$CASE(AppendSkinTest,"Y":"Y",:"N")
     s ch1=$C(1)
     ;AppendOrdCongeries
    s ParamS=AppendDoseQty_ch1_AppendDoseUnit_ch1_AppendDoseUnitDr
    s ParamS = ParamS_"^"_AppendOrderFreq_ch1_AppendFreqDr_ch1_AppendOrderFreqFactor_ch1_AppendOrderFreqInterval
    s ParamS = ParamS_"^"_AppendOrderInstr_ch1_AppendInstrDr
    s ParamS = ParamS_"^"_AppendOrderDur_ch1_AppendOrderDurRowId_ch1_AppendOrderDurFactor
    s ParamS = ParamS_"^"
    s ParamS = ParamS_"^"_AppendPrior_ch1_AppendPriorRowid
    s ParamS = ParamS_"^^^"
    s ParamS = ParamS_"^"	//备注
    s ParamS = ParamS_"^"_AppendRemarksRowid	//附加说明
    
    s ParamS = ParamS_"^"	//抗生素
    s ParamS = ParamS_"^"	//紧急标志
    s ParamS = ParamS_"^" //医嘱套项目id
    s ParamS = ParamS_"^"	//标本	
    s ParamS = ParamS_"^"	//医嘱阶段
    s ParamS = ParamS_"^" //输液流速、流速单位
    s ParamS = ParamS_"^"
    s ParamS = ParamS_"^"_AppendActionRowid_"^"_AppendAction_"^"_AppendSkinTest
    s ParamS = ParamS_"^^^^^^^^^"_ViewBindSource
    
    s MainOrdCongeriesArr(MaxOrdCongeries,"OrderARCIMRowid")=AppendARCIMRowid
    s MainOrdCongeriesArr(MaxOrdCongeries,"ParamS")=ParamS
    s MainOrdCongeriesArr(MaxOrdCongeries,"CalSeqNo")=CalSeqNo
    
    /*
    s MainOrdCongeriesArr(MaxOrdCongeries,"OrderBillTypeRowid")=""
    s MainOrdCongeriesArr(MaxOrdCongeries,"OrderCPWStepItemRowId")=""
    s MainOrdCongeriesArr(MaxOrdCongeries,"CopyType")
    s MainOrdCongeriesArr(MaxOrdCongeries,"OrderBodyPartLabel")=""
    s MainOrdCongeriesArr(MaxOrdCongeries,"ITMRowId")=""
    s MainOrdCongeriesArr(MaxOrdCongeries,"DCAInfoStr")=""
    */
    q

SetOrdOtherInfo(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s USERID=$P(SessionStr,"^",1)
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    //手术列表附加信息
    s AnaesthesiaID=$G(BaseParamArr("AnaesthesiaID"))
    s OrderOperationCode=$G(BaseParamArr("OrderOperationCode"))
    s EpisodeID=BaseParamArr("Adm")
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    if (AnaesthesiaID'=""){
        s OperationStr=##Class(web.DHCANAdaptor).GetOperInfoByAnaId(AnaesthesiaID,langid)
        //添加一项空数据供用户选择
        s OperationStr=""_$C(1)_"^"_OperationStr
        s OrderOperation=""
        if (OrderOperationCode'=""){
            for i=1:1:$L(OperationStr,"^"){
                s OneOperation=$P(OperationStr,"^",i)
                if ($P(OneOperation,$C(1),2)=OrderOperationCode){
                    s OrderOperation=$P(OneOperation,$C(1),1)
                }
            }
        }
        if (OrderOperation=""){
            s OrderOperation=$P($P(OperationStr,"^",1),$C(1),1)
            s OrderOperationCode=$P($P(OperationStr,"^",1),$C(1),2)
        }
        s LinkedMasterOrderRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderRowid"))
        if (LinkedMasterOrderRowid'=""){
            s OrderOperationCode=$p($g(^OEORD(+LinkedMasterOrderRowid,"I",$p(LinkedMasterOrderRowid,"||",2),4)),"^",10)
            if (OrderOperationCode'="") {
                s curOperId=$P(^OR(EpisodeID,"ANA",$p(OrderOperationCode,"||",2),"OP",$p(OrderOperationCode,"||",3)),"^",6)       ;ANAOP_Type_DR；手术名称
                if $D(^ORC("OPER",curOperId)) s OrderOperation=$P(^ORC("OPER",curOperId),"^",2)
            }
            }
        s ParamArr("AnaesthesiaID")=AnaesthesiaID
        s ParamArr("OrderOperationStr")=OperationStr
        //如果用户已在上一行置了默认，则不再覆盖
        if (ParamArr("OrderOperation")="")&&(ParamArr("OrderOperationCode")=""){
            s ParamArr("OrderOperation")=OrderOperation
            s ParamArr("OrderOperationCode")=OrderOperationCode
        }
    }
    //获取开医嘱医生列
    s OrderDocStr=..GetOPSurgeonDocStr(AnaesthesiaID,OrderOperationCode,USERID,langid)
    s DefOrderDoc="",DefOrderDocRowid=""
    if (OrderDocStr'="") {
        for i=1:1:$L(OrderDocStr,"^"){
            s OneOrderDoc=$P(OrderDocStr,"^",i)
            s Default=$P(OneOrderDoc,$C(1),3)
            if (Default="Y") {
                s DefOrderDoc=$P(OneOrderDoc,$C(1),1)
                s DefOrderDocRowid=$P(OneOrderDoc,$C(1),2)
                Q
            }
        }
        if (DefOrderDoc="") {
            s OneOrderDoc=$P(OrderDocStr,"^",1)
            s DefOrderDoc=$P(OneOrderDoc,$C(1),1)
            s DefOrderDocRowid=$P(OneOrderDoc,$C(1),2)
        }
    }
    s ParamArr("OrderDocStr")=OrderDocStr
    s ParamArr("OrderDoc")=DefOrderDoc
    s ParamArr("OrderDocRowid")=DefOrderDocRowid
    //获取默认滴速用法
    s OrderInstrRowid=$g(ParamArr("OrderInstrRowid"))
    s OrderFlowRateUnitRowId=ParamArr("OrderFlowRateUnitRowId")
    if (OrderFlowRateUnitRowId="")&&(ParamArr("OrderType")="R") {
        s OrderFlowRateUnitRowId=..GetInstrDefSpeedRateUnit(OrderInstrRowid,HOSPID)
        if (OrderFlowRateUnitRowId'="") {
            s ParamArr("OrderFlowRateUnitRowId")=OrderFlowRateUnitRowId
            s OrderFlowRateUnit=$P($G(^OEC("SFR",OrderFlowRateUnitRowId)),"^",2)
            s ParamArr("OrderFlowRateUnit")=OrderFlowRateUnit
        }
    }
	s DCARowID=ParamArr("DCARowID")
	;DCARowID:ChildDCA & MainDCA
	;			ChildDCA ChildDCA#AssScaleID 包含当前(绑定关联的)医嘱的治疗申请ID(DCARowID)#治疗评定申请ID
	; 	     	MainDCA  MainDCA#AssScaleID  被关联的治疗申请ID(MainDCARowID,绑定的医嘱可能不会生成治疗申请)#治疗评定申请ID
	s:DCARowID'="" DCARowID=$p($p(DCARowID,"&"),"#")
	if DCARowID'=""{
	    s CureItemFlag="1"
	}else{
	    s CureItemFlag = ##Class(DHCDoc.DHCDocCure.Service).CheckItem(OrderARCIMRowid,ParamArr("OrderRecDepRowid"),HOSPID)
	}
	s ParamArr("OrderCureItemFlag")=CureItemFlag
	q
SetSingleRowFlag(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s ParamArr("SingleRowFlag")="N"
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s LogonHosp=$p(SessionStr,"^",4)
    s EpisodeID=BaseParamArr("Adm")
     s PHPoisonCode=ParamArr("OrderPoisonCode")
     s OrderPoisonRowid=ParamArr("OrderPoisonRowid")
     s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
     //抗生素独立显示
     //抗菌药物功能配置-管制分类设置,有可能OrderPoisonCode非KSS的也维护了此配置,故走抗菌药物接口判断是否维护
    //if (PHPoisonCode [ "KSS") {
    if (##class(DHCAnt.KSS.Config.PoisonSet).InControl(LogonHosp,OrderPoisonRowid)) {
        s isExit = ##Class(DHCAnt.KSS.Common.Method).GetKJSwitchFlag(PAAdmType,LogonHosp)
        if (isExit'=1){
            s ParamArr("SingleRowFlag")="Y"
        }
    }
    //医嘱套明细维护快速例外
    s ITMRowId=$G(BaseParamArr("ITMRowId"))
    if ((+ITMRowId'="0")){
        //医嘱套嵌套按例外处理
        s BaseOrderARCOSRowid=BaseParamArr("OrderARCOSRowid")
        if (BaseOrderARCOSRowid'="")&&($p(ITMRowId,"||",1)'=BaseOrderARCOSRowid){
             s ParamArr("SingleRowFlag")="Y"
        }else{
            s RemoveCeler=$p($G(^ARCOS($p(ITMRowId,"||",1),"DATE",$p(ITMRowId,"||",2),"ITM",$p(ITMRowId,"||",3),"DHC")),"^",9)
            if (RemoveCeler="Y"){
                s ParamArr("SingleRowFlag")="Y"
            }
        }
    }
    q
SetOrderFreqDispTimeStr(ParamArr,UserOptionArr,ItemOrdsArr,CallBackFunStr,BaseParamArr)
    n (ParamArr,UserOptionArr,ItemOrdsArr,CallBackFunStr,BaseParamArr)
    s OrderFreq=ParamArr("OrderFreq")
    s OrderFreqRowid=ParamArr("OrderFreqRowid")
    s OrderName = ParamArr("OrderName")
    s DCAFreqDispTimeStr=ParamArr("DCAFreqDispTimeStr")
    s OrderDirectEntryAuth=ParamArr("OrderDirectEntryAuth")
    if (DCAFreqDispTimeStr'=""){
        s ParamArr("OrderFreqDispTimeStr")=DCAFreqDispTimeStr
    }
    k MasterItemArr
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s langid=$P(SessionStr,"^",6)
    s OrderMasterSeqNo=ParamArr("OrderMasterSeqNo")
    s OrderMasterCalSeqNo=ParamArr("CalSeqNo")
    if (OrderMasterSeqNo'="")||($p(OrderMasterCalSeqNo,".",2)'="") {
        //找到主医嘱那行数据
        s i =""
        for{
            s i=$O(ItemOrdsArr("ItemOrds",i))
            q:(i="")
            s ListSeqNo = ItemOrdsArr("ItemOrds",i,"OrderSeqNo")
            s CalSeqNo = $g(ItemOrdsArr("ItemOrds",i,"CalSeqNo"))
            continue:CalSeqNo=""
            if (OrderMasterSeqNo=ListSeqNo)||(($p(OrderMasterCalSeqNo,"."))=CalSeqNo){
                m MasterItemArr=ItemOrdsArr("ItemOrds",i)
            }
        }
        if ($d(MasterItemArr)) {
            s MasterOrderFreq=MasterItemArr("OrderFreq")
            s MasterOrderFreqRowid=MasterItemArr("OrderFreqRowid")
            s MasterOrderFreqFactor=MasterItemArr("OrderFreqFactor")
            s MasterOrderFreqInterval=MasterItemArr("OrderFreqInterval")
            s MasterOrderFreqDispTimeStr=MasterItemArr("OrderFreqDispTimeStr")
            s ParamArr("OrderFreq")=MasterOrderFreq
            s ParamArr("OrderFreqRowid")=MasterOrderFreqRowid
            s ParamArr("OrderFreqDispTimeStr")=MasterOrderFreqDispTimeStr
            s ParamArr("OrderFreqFactor")=MasterOrderFreqFactor
            s ParamArr("OrderFreqInterval")=MasterOrderFreqDispTimeStr
            Q
        }
    }
    s OrderFreqDispTimeStr=ParamArr("OrderFreqDispTimeStr")
    if (OrderFreqRowid=""){
        s ParamArr("OrderFreqDispTimeStr")=""
        q
    }
    
    s WeekFlag=$P(^PHCFR(OrderFreqRowid),"^",9)
    s FreeTimeFreqFlag=$P(^PHCFR(OrderFreqRowid),"^",13)
    //目前不支持这种数据的频次
    if (WeekFlag="Y")&&(FreeTimeFreqFlag="Y"){
        s ParamArr("OrderFreq")=""
        s ParamArr("OrderFreqRowid")=""
        s ParamArr("OrderFreqFactor")=1
        s ParamArr("OrderFreqInterval")=""
        s ParamArr("OrderFreqDispTimeStr")="" 
        q
    }
    if (WeekFlag="Y"){
        //周频次
        d SetWeekDispTimeStr
    }elseif (FreeTimeFreqFlag="Y"){
        //不规则分发时间频次
        d SetFreeTimeFreqStr
    }else{
        s ParamArr("OrderFreqDispTimeStr")=""
        q
    }
    q
SetFreeTimeFreqStr
    if (OrderFreqDispTimeStr'=""){
        s OrderFreqFreeTimeInfo=##Class(web.DHCOEOrdItem).GetOrderFreqFreeTimeInfo(OrderFreqRowid,OrderFreqDispTimeStr)
        s OrderFreqFreeTimeStr=$P(OrderFreqFreeTimeInfo,"^",1)
        s OrderFreqFreeTimeDesc=$P(OrderFreqFreeTimeInfo,"^",2)
        //防止复制医嘱时，带入的描述附加有周信息，这个重新加一遍
        s OrderFreq=$P($g(^PHCFR(OrderFreqRowid)),"^",3)
        s OrderFreq=OrderFreq_" "_OrderFreqFreeTimeDesc
        s ParamArr("OrderFreq")=OrderFreq
        s ParamArr("OrderFreqFactor")=$L(OrderFreqFreeTimeStr,"|")
        q
    }
    s FindType=0
    if (OrderDirectEntryAuth="Y"){
        s i=$O(UserOptionArr("SetOrderFreqDispTimeStr",0))
        if (i=""){
            s OrderName=ParamArr("OrderName")
            s CallBackFunParams=OrderFreqRowid_";;"_OrderName_";FreeTime"
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetOrderFreqDispTimeStr",CallBackFunParams)
            q
        }
        s OrderFreqDispTimeStr=$G(UserOptionArr("SetOrderFreqDispTimeStr",i,"Value"))
        if (OrderFreqDispTimeStr=""){
            s ParamArr("OrderFreq")=""
            s ParamArr("OrderFreqRowid")=""
            s ParamArr("OrderFreqFactor")=1
            s ParamArr("OrderFreqInterval")=""
            s ParamArr("OrderFreqDispTimeStr")="" 
            s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 不规则分发时间频次请务必选择分发时间",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
            q
        }
    }else{
        s OrderFreqDispTimeStr=""
        s DTSubID=$O(^PHCFR(OrderFreqRowid,"DT",0))
        s OrderFreqDispTimeStr="08:00:00"_$C(2)_$C(2)_OrderFreq_"_"_DTSubID
    }
    
    s ParamArr("OrderFreqDispTimeStr")=OrderFreqDispTimeStr
    s OrderFreqFreeTimeInfo=##Class(web.DHCOEOrdItem).GetOrderFreqFreeTimeInfo(OrderFreqRowid,OrderFreqDispTimeStr)
    s OrderFreqFreeTimeStr=$P(OrderFreqFreeTimeInfo,"^",1)
    s OrderFreqFreeTimeDesc=$P(OrderFreqFreeTimeInfo,"^",2)
    //防止复制医嘱时，带入的描述附加有描述信息，这个重新加一遍
    s OrderFreq=$P($g(^PHCFR(OrderFreqRowid)),"^",3)
    s OrderFreq=OrderFreq_" "_$TR(OrderFreqFreeTimeDesc,"|","")
    s ParamArr("OrderFreq")=OrderFreq
    s ParamArr("OrderFreqFactor")=$L(OrderFreqFreeTimeStr,"|")
    q	
    
SetWeekDispTimeStr
    if (OrderFreqDispTimeStr'=""){
        s OrderFreqWeekStr=##Class(web.DHCOEOrdItem).GetOrderFreqWeekStr(OrderFreqDispTimeStr)
        //防止复制医嘱时，带入的描述附加有周信息，这个重新加一遍
        s OrderFreq=$P($g(^PHCFR(OrderFreqRowid)),"^",3)
        s OrderFreq=OrderFreq_" "_$TR(OrderFreqWeekStr,"|","")
        s ParamArr("OrderFreq")=OrderFreq
        ///计算医嘱开始时间
        s OrderStartDateStr = ParamArr("OrderStartDate")
        s OrderStartDateStr=..GetWeekFreqStartDate(OrderStartDateStr,OrderFreqDispTimeStr)   
        s ParamArr("OrderStartDate") = OrderStartDateStr
        q
    }
    s FindType=0
    //{Type:"",Value:""}
    if (OrderDirectEntryAuth="Y"){
        s i=$O(UserOptionArr("SetOrderFreqDispTimeStr",0))
        if (i=""){
            s OrderName=ParamArr("OrderName")
            s CallBackFunParams=OrderFreqRowid_";;"_OrderName_";Week"
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetOrderFreqDispTimeStr",CallBackFunParams)
            q
        }
        s OrderFreqDispTimeStr=$G(UserOptionArr("SetOrderFreqDispTimeStr",i,"Value"))
        if (OrderFreqDispTimeStr=""){
            s ParamArr("OrderFreq")=""
            s ParamArr("OrderFreqRowid")=""
            s ParamArr("OrderFreqFactor")=1
            s ParamArr("OrderFreqInterval")=""
            s ParamArr("OrderFreqDispTimeStr")="" 
            s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 周频次请务必选择使用周数",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
            q
        }
    }else{
        s OrderFreqDispTimeStr=""
        s CurrWeek=$ZD(+$H,10)
        i CurrWeek=0 s CurrWeek=7
        s OrderFreqDispTimeStr="08:00:00"_$C(2)_CurrWeek
    }
    
    s ParamArr("OrderFreqDispTimeStr")=OrderFreqDispTimeStr
    s OrderFreqWeekStr=##Class(web.DHCOEOrdItem).GetOrderFreqWeekStr(OrderFreqDispTimeStr)
    //防止复制医嘱时，带入的描述附加有周信息，这个重新加一遍
    s OrderFreq=$P($g(^PHCFR(OrderFreqRowid)),"^",3)
    s OrderFreq=OrderFreq_" "_$TR(OrderFreqWeekStr,"|","")
    s ParamArr("OrderFreq")=OrderFreq
    ///计算医嘱开始时间
    s OrderStartDateStr = ParamArr("OrderStartDate")
    s OrderStartDateStr=..GetWeekFreqStartDate(OrderStartDateStr,OrderFreqDispTimeStr)   
    s ParamArr("OrderStartDate") = OrderStartDateStr
    
    q

SetMasterSeqNo(ParamArr,BaseParamArr,ItemOrdsArr,ArcosArr,CallBackFunStr,UserOptionArr)
    n (ParamArr,BaseParamArr,ItemOrdsArr,ArcosArr,CallBackFunStr,UserOptionArr)
    s OrderMasterSeqNo=ParamArr("OrderMasterSeqNo")
    q:(OrderMasterSeqNo="")
    s StartMasterOrdSeq=$g(BaseParamArr("MasterSeqNo"))
    s OrderName=ParamArr("OrderName")
    s OrderType=ParamArr("OrderType")
    //找到主医嘱那行数据
    k MasterItemArr
    s i =""
    for{
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        s ListSeqNo = ItemOrdsArr("ItemOrds",i,"OrderSeqNo")
        if (OrderMasterSeqNo=ListSeqNo){
            m MasterItemArr=ItemOrdsArr("ItemOrds",i)
        }
    }
    
    //关联医嘱基本控制
    s Rtn=$$CheckLinkOrder(.ParamArr,.MasterItemArr,.BaseParamArr)
    if (+Rtn<0){
        s CallBackFunParams=$P(Rtn,"^",2)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        s ParamArr("OrderMasterSeqNo")=""
        s ParamArr("CalSeqNo")=""
        q
    }
    //接收科室相关转变控制
    s Rtn=$$CheckLinkOrderRecDep(.ParamArr,.BaseParamArr,.MasterItemArr)
    if (+Rtn>=0){
        //style控制-改到前台去做,这里仅同步数据
        d SyncOrderData(.ParamArr,.BaseParamArr,.MasterItemArr,.ArcosArr,.CallBackFunStr,.ItemOrdsArr,.UserOptionArr)
    }else{
        if (StartMasterOrdSeq="") {
            s CallBackFunParams=$P(Rtn,"^",2)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        }
        s ParamArr("OrderMasterSeqNo")=""
        q
    }
    q
    //子医嘱同步主医嘱数据
SyncOrderData(ParamArr,BaseParamArr,MasterItemArr,ArcosArr,CallBackFunStr,ItemOrdsArr,UserOptionArr)
    n (ParamArr,BaseParamArr,MasterItemArr,ArcosArr,CallBackFunStr,ItemOrdsArr,UserOptionArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s USERID=$P(SessionStr,"^",1)
    s HOSPID=$P(SessionStr,"^",4)
    
    s EpisodeID=BaseParamArr("Adm")
    s MOrderPriorRowid = MasterItemArr("OrderPriorRowid")
    
    s SpecOrderPriorRowid=ParamArr("SpecOrderPriorRowid")	;真正的医嘱类型
    s OrderPriorRowid=ParamArr("OrderPriorRowid")			;医嘱类型列
    s OrderPriorRemarksRowId=ParamArr("OrderPriorRemarksRowId")	;附加说明代码
    s OrderPriorContrlConfig=BaseParamArr("OrderPriorContrlConfig")
    
    s MSpecOrderPriorRowid=MOrderPriorRowid
    s MOrderPriorStr=..SplitOrderPriorRowid(MOrderPriorRowid)
    s MOrderPriorRowid=$P(MOrderPriorStr,"^",1)
    s MPriorRemarksRowid=$P(MOrderPriorStr,"^",3)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    ;不随主医嘱变化的用法
    s NotFollowInstr=..%GetConfig("NotFollowInstr",CurLogonHosp)
    ;外用用法
     s WYInstr=..%GetConfig("WYInstr",CurLogonHosp)
     ;皮试医嘱类型控制为临时
    s CFSkinTestPriorShort=..%GetConfig("SkinTestPriorShort",CurLogonHosp)
     s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    //1.医嘱类型 应该只需要同步医嘱类型，附加说明不需要同步
    if (MOrderPriorRowid'=OrderPriorRowid){
        s OrderPriorRowid=MOrderPriorRowid
        s ParamArr("OrderPriorRowid")=OrderPriorRowid
        s ParamArr("OrderPrior")=$P(^OECPR(MOrderPriorRowid),"^",2)
        //同步医嘱类型
        if (OrderPriorContrlConfig="1"){
            
        }
        s OrderPriorCode=$P(^OECPR(MOrderPriorRowid),"^",1)
        //若主医嘱为长期/出院带药医嘱,子医嘱附加说明为取药医嘱,则清空子医嘱附加说明
        if ((OrderPriorCode="S")||(OrderPriorCode="OUT"))&&(OrderPriorRemarksRowId="ONE"){
            s OrderPriorRemarksRowId=""
        }
        s ParamArr("OrderPriorRemarksRowId")=OrderPriorRemarksRowId
        s SpecOrderPriorRowid=..ReSetOrderPriorRowid(OrderPriorRowid,OrderPriorRemarksRowId)
        s ParamArr("SpecOrderPriorRowid")=SpecOrderPriorRowid
    }
    //2.频次
    s ParamArr("OrderFreq")=$G(MasterItemArr("OrderFreq"))
    s ParamArr("OrderFreqRowid")=$G(MasterItemArr("OrderFreqRowid"))
    s ParamArr("OrderFreqFactor")=$G(MasterItemArr("OrderFreqFactor"))
    s ParamArr("OrderFreqInterval")=$G(MasterItemArr("OrderFreqInterval"))
    if (ParamArr("OrderFreqRowid")'=""){
        s:ParamArr("OrderFreq")="" ParamArr("OrderFreq")=$P($g(^PHCFR(ParamArr("OrderFreqRowid"))),"^",3)
        s:ParamArr("OrderFreqFactor")="" ParamArr("OrderFreqFactor")=$P($g(^PHCFR(ParamArr("OrderFreqRowid"))),"^",2)
        s:ParamArr("OrderFreqInterval")="" ParamArr("OrderFreqInterval")=$P($g(^PHCFR(ParamArr("OrderFreqRowid"))),"^",5)
    }
    s ParamArr("OrderFreqDispTimeStr")=$G(MasterItemArr("OrderFreqDispTimeStr"))
    //3.用法
    s MOrderInstrRowid=MasterItemArr("OrderInstrRowid")
    s OrderInstr=""
    if (MOrderInstrRowid'=""){
        s OrderInstr=$P($g(^PHCIN(MOrderInstrRowid)),"^",2)
    }
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    
    if ((("^"_NotFollowInstr_"^")'[("^"_OrderInstrRowid_"^"))&&(OrderInstrRowid'=MOrderInstrRowid)) {
        s ParamArr("OrderInstrRowid")=MOrderInstrRowid
        s ParamArr("OrderInstr")=OrderInstr
        if (("^"_WYInstr_"^")[("^"_OrderInstrRowid_"^"))&&(PAAdmType'="I"){
            s ParamArr("OrderDoseQty")=""
        }
    }
    s OrderInstrRowid = ParamArr("OrderInstrRowid")
    //4.疗程
    s MOrderDurRowid=MasterItemArr("OrderDurRowid")
    s OrderDur="",OrderDurFactor=1
    if (MOrderDurRowid'=""){
        s OrderDur=$P($g(^PHCDU(MOrderDurRowid)),"^",3)
        s OrderDurFactor=$P($g(^PHCDU(MOrderDurRowid)),"^",2)
    }
    
    if (("^"_WYInstr_"^")[("^"_OrderInstrRowid_"^")){
        if (PAAdmType'= "I") {
            s ParamArr("OrderDur")=""
            s ParamArr("OrderDurRowid")=""
            s ParamArr("OrderDurFactor")=""
        }
    } else {
        s ParamArr("OrderDur")=OrderDur
        s ParamArr("OrderDurRowid")=MOrderDurRowid
        s ParamArr("OrderDurFactor")=OrderDurFactor
    }
    //5.皮试(根据用法)
    s SpecOrderPriorRowid=ParamArr("SpecOrderPriorRowid")
    s PriorFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(SpecOrderPriorRowid)
    if ((PriorFlag=1)&&(CFSkinTestPriorShort="1")) {
        s ParamArr("OrderSkinTest")="N"
        s ParamArr("OrderActionRowid")=""
        s ParamArr("OrderAction")=""
    }
    //6.开始日期
    s OrderStartDate=MasterItemArr("OrderStartDate")
    s ParamArr("OrderStartDate")=OrderStartDate
    //7.结束日期
    s OrderEndDate = MasterItemArr("OrderEndDate")
    s ParamArr("OrderEndDate")=OrderEndDate
    //8.开医嘱日期
    s OrderDate = MasterItemArr("OrderDate")
    s ParamArr("OrderDate")=OrderDate
    //9.重新计算数据  会更新首日次数.首日次数和主医嘱保持一致即可
    if ($D(ArcosArr)'=""){
        d SetPackQty(.ParamArr,.BaseParamArr,.ArcosArr,.CallBackFunStr,.ItemOrdsArr,.UserOptionArr)
    }
    //10.首日次数
    s OrderFirstDayTimes=MasterItemArr("OrderFirstDayTimes")
    s ParamArr("OrderFirstDayTimes")=OrderFirstDayTimes
    //11.接收科室
    //12.同步滴速和滴速单位
	s IsSpeedRateSeparateInstr=##class(web.DHCDocOrderCommon).GetIsSpeedRateSeparateInstr(OrderInstrRowid,HOSPID)
	if ((IsSpeedRateSeparateInstr'="1")||(ParamArr("OrderSpeedFlowRate")=""))&&($G(ParamArr("OrderType"))="R"){
	    s OrderSpeedFlowRate=MasterItemArr("OrderSpeedFlowRate")
	    s ParamArr("OrderSpeedFlowRate")=OrderSpeedFlowRate
	    s OrderFlowRateUnitRowId=MasterItemArr("OrderFlowRateUnitRowId")
	    s ParamArr("OrderFlowRateUnitRowId")=OrderFlowRateUnitRowId
	    s OrderFlowRateUnit=""
	    i (OrderFlowRateUnitRowId'=""){
	        s OrderFlowRateUnit=$P($G(^OEC("SFR",OrderFlowRateUnitRowId)),"^",2)
	    }
	    s ParamArr("OrderFlowRateUnit")=OrderFlowRateUnit
    }
    //13.配液标记
    s OrderNeedPIVAFlag=MasterItemArr("OrderNeedPIVAFlag")
    s ParamArr("OrderNeedPIVAFlag")=OrderNeedPIVAFlag
    d ReSetOrderAndPackQty(.ParamArr,.BaseParamArr)
    //14.部位
    s OrderBodyPartID=MasterItemArr("OrderBodyPartID")
     s MRCBodyPartStr=##class(web.DHCDocOrderCommon).GetMRCBodyPart("JSON")
    s OrderBodyPart=""
    for i=1:1:$L(MRCBodyPartStr,";") {
        s ArrData=$P(MRCBodyPartStr,";",i)
        if ($P(ArrData,":",1)=OrderBodyPartID) {
            s OrderBodyPart=$P(ArrData,":",2)
            q
        }
    }
    s ParamArr("OrderBodyPartID")=OrderBodyPartID
    s ParamArr("OrderBodyPart")=OrderBodyPart
    //15.医嘱阶段
    s OrderStageCode=MasterItemArr("OrderStageCode")
    s OrderStageStr=##class(web.DHCDocOrderCommon).GetOrderStage("JSON")
    s OrderStage=""
    for i=1:1:$L(OrderStageStr,";") {
        s ArrData=$P(OrderStageStr,";",i)
        if ($P(ArrData,":",1)=OrderStageCode) {
            s OrderStage=$P(ArrData,":",2)
            q
        }
    }
    s ParamArr("OrderStageCode")=OrderStageCode
    s ParamArr("OrderStage")=OrderStage
    //16.疗程超量原因
    s ExceedReasonID=MasterItemArr("ExceedReasonID")
    s ExceedStr=##Class(web.DHCDocExceedReason).GetExceedStr("","json",HOSPID)
    s ExceedReason=""
    for i=1:1:$L(ExceedStr,";") {
        s ArrData=$P(ExceedStr,";",i)
        if ($P(ArrData,":",1)=ExceedReasonID) {
            s ExceedReason=$P(ArrData,":",2)
            q
        }
    }
    s ParamArr("ExceedReasonID")=ExceedReasonID
    s ParamArr("ExceedReason")=ExceedReason
    //17.输液次数
    s MOrderLocalInfusionQty=MasterItemArr("OrderLocalInfusionQty")
	if (MOrderLocalInfusionQty'=""){
		s ParamArr("OrderLocalInfusionQty")=MOrderLocalInfusionQty
	}

    q
CheckLinkOrderRecDep(ParamArr,BaseParamArr,MasterItemArr)
    n (ParamArr,BaseParamArr,MasterItemArr)
    //判断主子医嘱的用法是否一致,如果不一致,则先改变子医嘱的用法,并同时修改接收科室
    s MOrderARCIMRowid = MasterItemArr("OrderARCIMRowid")
    s MOrderInstrRowid = MasterItemArr("OrderInstrRowid")
    s MOrderRecDepRowid = MasterItemArr("OrderRecDepRowid")
    
    s EpisodeID=BaseParamArr("Adm")
    s LogonDep=BaseParamArr("LogonDep")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderName=ParamArr("OrderName")
    s OrderInstrRowid = ParamArr("OrderInstrRowid")
    //s OrderInstr = ParamArr("OrderInstr")
    s OrderItemCatRowid=ParamArr("OrderItemCatRowid")
    s OrderPriorRowid = ParamArr("OrderPriorRowid")
    s SpecOrderPriorRowid = ParamArr("SpecOrderPriorRowid")
    s OrderRecLocStr = ParamArr("OrderRecLocStr")
    s OrderType=ParamArr("OrderType")
    s OrderPriorRemarksRowId =ParamArr("OrderPriorRemarksRowId")
    s OrderConFac=ParamArr("OrderConFac")
    s OrderPackQty=ParamArr("OrderPackQty")
    s SpecOrderPackUOMRowid=$G(ParamArr("SpecOrderPackUOMRowid"))
    s OrderPackUOMRowid=ParamArr("OrderPackUOMRowid")
    s NotifyClinician=ParamArr("Urgent")
    s MItemCatDR=$p(^ARCIM(+MOrderARCIMRowid,$p(MOrderARCIMRowid,"||",2),1),"^",10)
    s MOrderType=$P(^ARC("IC",MItemCatDR),"^",7)
    s MOrderRecDep=$P(^CTLOC(MOrderRecDepRowid),"^",2)
    s MOrderInstr=""
    i MOrderInstrRowid'="" s MOrderInstr=$P($g(^PHCIN(MOrderInstrRowid)),"^",2)
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s CurLogonDep=$p(SessionStr,"^",3)
    s HOSPID=$P(SessionStr,"^",4)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    ;不随主医嘱变化的用法
    s NotFollowInstr=..%GetConfig("NotFollowInstr",HOSPID)
    ;启用用法接收科室设置
    s ReclocByInstr=..%GetConfig("ReclocByInstr",HOSPID)
    ;成组医嘱接收科室一致
     s CFSameRecDepForGroup=..%GetConfig("SameRecDepForGroup",HOSPID)
    if ((("^"_NotFollowInstr_"^")'[("^"_OrderInstrRowid_"^"))&&(OrderInstrRowid'=MOrderInstrRowid)) {
        if (MOrderInstrRowid'=""){
            s ParamArr("OrderInstrRowid")=MOrderInstrRowid
            s ParamArr("OrderInstr")=MOrderInstr
        }
        if (ReclocByInstr="1")&&(ParamArr("OrderInstrRowid")'=""){
            //改GetReclocByInstr
            s RecLocStr=##Class(web.DHCDocOrderCommon).GetInstrRecLocStr(
            EpisodeID,ParamArr("OrderInstrRowid"),LogonDep,OrderItemCatRowid,OrderPriorRowid,OrderRecLocStr,HOSPID)
            if (RecLocStr'=""){
                //改GetRecLocStrByPrior
                s RecLocParams=##Class(DHCDoc.Util.ArrayData).%New()
                d RecLocParams.SetAt(SpecOrderPriorRowid,"PriorRowId")
                d RecLocParams.SetAt(NotifyClinician,"NotifyClinician")
                d RecLocParams.SetAt(HOSPID,"HospID")
                s RecLocStr=..GetRecLocStrByParams(RecLocStr,RecLocParams.%ToJSON().Read())
                s DefaultRecLocStr=$$GetDefaultRecLocStr(RecLocStr)
                s DefaultRecLocRowid=$P(DefaultRecLocStr,"^",1)
                s DefaultRecLocDesc=$P(DefaultRecLocStr,"^",2)
                if (DefaultRecLocRowid'=""){
                    s ParamArr("CurrentRecLocStr")=RecLocStr
                    s ParamArr("OrderRecDep")=DefaultRecLocDesc
                    s ParamArr("OrderRecDepRowid")=DefaultRecLocRowid
                }
            }
        }
        //检验子医嘱对应的主医嘱接收科室，库存情况
        if ((CFSameRecDepForGroup="1") ) { //&& (OrderType="R")
            if (OrderPriorRemarksRowId'="ZT")&&(OrderPriorRemarksRowId'="OM")
                &&(OrderPriorCode'=""){
                s BaseDoseQtySum=1	
                if (PAAdmType '= "I"){
                    s BaseDoseQtySum=..GetConFacByUom(OrderARCIMRowid,OrderPackQty,MOrderRecDepRowid,OrderPackUOMRowid,PAAdmType)
                    if (BaseDoseQtySum = "") { 
                        s BaseDoseQtySum=1
                       }
                }
                s ExpStr=EpisodeID_"^"_CurLogonDep_"^0"
                s Check =##Class(web.DHCDocOrderCommon).CheckStockEnough(OrderARCIMRowid, BaseDoseQtySum, MOrderRecDepRowid,PAAdmType,ExpStr)
                s CheckFlag=$P(Check,"^",1)
                if (CheckFlag = "0") {
                    s ErrMsg=OrderName_MOrderRecDep_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
                    q "-1^"_ErrMsg
                } elseif (Check = "-1") {
                       s ErrMsg=OrderName_MOrderRecDep_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员",langid)
                    q "-1^"_ErrMsg
                } else {
                    if (Check = "-2"){
                        ;s ErrMsg=OrderName_MOrderRecDep_"通过医嘱或子类绑定的"_$P(Check,"^",2)_"被锁定，如需要请联系药房工作人员"
                        s ErrMsg=OrderName_MOrderRecDep_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员",langid)
                        q "-1^"_ErrMsg
                    } elseif (Check = "-3")&&(OrderPriorCode'="OUT")&&(OrderPriorCode'="ONE"){
                        s ErrMsg=OrderName_MOrderRecDep_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类绑定的",langid)_$P(Check,"^",2)_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
                        q "-1^"_ErrMsg
                    }

                    s FindSubRecDep = 0
                    s CurrentRecLocStr=ParamArr("CurrentRecLocStr")
                    for i=1:1:$L(CurrentRecLocStr,$C(2)) {
                        s ArrData=$p(CurrentRecLocStr,$C(2),i)
                        if ($P(ArrData,$C(1),1) = MOrderRecDepRowid) {
                            s FindSubRecDep = 1
                        }
                    }
                    if (FindSubRecDep=0) {
                        s ErrMsg=OrderName_MOrderRecDep_..%Translate("oeorder.oplistcustom.new.csp"," 子医嘱未找到与主医嘱一致的接收科室.",langid)
                        q "-1^"_ErrMsg
                    }
                    if (FindSubRecDep = 1) {
                        s ParamArr("OrderRecDep")=MOrderRecDep
                        s ParamArr("OrderRecDepRowid")=MOrderRecDepRowid
                    }
                }
            }	
        }
    }
    q 0
CheckLinkOrder(ParamArr,MasterItemArr,BaseParamArr)
    n (ParamArr,MasterItemArr,BaseParamArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s ErrCode=0
    s ErrMsg=""
    s OrderName=ParamArr("OrderName")
    s OrderType=ParamArr("OrderType")
    if ('$D(MasterItemArr))||($G(MasterItemArr("OrderARCIMRowid"))=""){
        s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 主医嘱不存在,无法关联",langid)
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg
    }
    if (MasterItemArr("OrderMasterSeqNo")'=""){
        s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 选择主医嘱已经关联其他医嘱",langid)
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg
    }
    if (MasterItemArr("OrderItemRowid")'=""){
        s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 已审核医嘱不能关联",langid)
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg 
    }
    //验证主子医嘱附加说明是否有取药医嘱
    s MasOrderPriorRemarksRowId=$G(MasterItemArr("OrderPriorRemarksRowId"))
    if (MasOrderPriorRemarksRowId=""){
        s OrderPriorStr= ..SplitOrderPriorRowid($G(MasterItemArr("OrderPriorRowid")))
        s MasOrderPriorRemarksRowId=$P(OrderPriorStr,"^",3)
    }
    s SubOrderPriorRemarksRowId=$G(ParamArr("OrderPriorRemarksRowId"))
    if ((MasOrderPriorRemarksRowId="ONE")||(SubOrderPriorRemarksRowId="ONE")){
        s MasterOrderARCIMName=$P(^ARCIM(+MasterItemArr("OrderARCIMRowid"),1,1),"^",2)
        s MasterOrderARCIMName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",MasterOrderARCIMName,langid)
        s tempOrderName=$SELECT(MasOrderPriorRemarksRowId="ONE":MasterOrderARCIMName,1:OrderName)
        s ErrMsg=tempOrderName_..%Translate("oeorder.oplistcustom.new.csp"," 取药医嘱不能关联!",langid)
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg 
    }
    //验证主医嘱是出院带药,子医嘱医嘱类型
    s MainOrderPriorRowid=$G(MasterItemArr("OrderPriorRowid"))
    s SubOrderType = $G(ParamArr("OrderType"))
     s OutOrderPriorRowid=$O(^OECPR(0,"Code","OUT",0))
    if ((MainOrderPriorRowid=OutOrderPriorRowid)&&(SubOrderType'="R")){
        s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 子医嘱非药品医嘱,不能和出院带药医嘱关联!",langid)
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg 
    }
    //验证主医嘱是非药品且不能录入频次疗程,子医嘱是否是药品/允许录入频次疗程的非药品子类
    s MainOrderFreqRowid= $G(MasterItemArr("OrderFreqRowid"))
    s SubOrderPHPrescType = $G(ParamArr("OrderPHPrescType"))
    s MainOrderARCIMRowid=$G(MasterItemArr("OrderARCIMRowid"))
    s MainOrderItemCatRowid=$p(^ARCIM(+MainOrderARCIMRowid,$p(MainOrderARCIMRowid,"||",2),1),"^",10) //$G(MasterItemArr("OrderItemCatRowid"))
    if ((SubOrderPHPrescType="4")||(SubOrderType="R")) {
        s FreqItemCat=..%GetConfig("FrequencedItemCat",HOSPID)
        if (MainOrderFreqRowid="")&&(("^"_FreqItemCat_"^"[("^"_MainOrderItemCatRowid_"^"))){
            s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 子医嘱必须有频次和疗程,不能关联!",langid)
            s ErrCode="-1"
            q ErrCode_"^"_ErrMsg 
        }
    }
    //验证主医嘱是非药品且不能录入用法,子医嘱是药品/允许录入用法的非药品子类
    s SubOrderItemCatRowid = $G(ParamArr("OrderItemCatRowid"))
    ;可选择用法的非药品子分类
     s SelectInstrNotDrugCat=..%GetConfig("SelectInstrNotDrugCat",HOSPID)
     s SelectInstrNotDrugCat="^"_SelectInstrNotDrugCat_"^"
    if ((((SelectInstrNotDrugCat)[("^" _SubOrderItemCatRowid_ "^")))||(SubOrderType="R")) {
         s MainOrderInstr=$G(MasterItemArr("OrderInstrRowid"))
         s MainOrderType=$P(^ARC("IC",MainOrderItemCatRowid),"^",7)
         s MainOrderPHPrescType = ##class(web.DHCDocOrderCommon).GetPHPrescType(MainOrderItemCatRowid,HOSPID)
         if ((((SelectInstrNotDrugCat)'[("^" _SubOrderItemCatRowid_ "^")))&&(MainOrderInstr="")&&(MainOrderType'="R")&&(MainOrderPHPrescType'="4")) {
             s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 子医嘱必须录入用法,不能关联!",langid)
             s ErrCode="-1"
             q ErrCode_"^"_ErrMsg 
         }
    }
    ;不能关联的医嘱子类
     s NotLinkItemCat=..%GetConfig("NotLinkItemCat",HOSPID)
     if (("^"_NotLinkItemCat_"^"[("^"_MainOrderItemCatRowid_"^"))){
         s MasOrderName=$G(MasterItemArr("OrderName"))
         s ErrMsg=MasOrderName_..%Translate("oeorder.oplistcustom.new.csp"," 主医嘱不能关联!",langid)
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg 
    }
    if (("^"_NotLinkItemCat_"^"[("^"_SubOrderItemCatRowid_"^"))){
         s ErrMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 子医嘱不能关联!",langid)
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg 
    }
    /*s MARCIMRowid=MasterItemArr("OrderARCIMRowid")
    s MItemCatDR=$p(^ARCIM(+MARCIMRowid,$p(MARCIMRowid,"||",2),1),"^",10)
    s MOrderType=$P(^ARC("IC",MItemCatDR),"^",7)
    if (OrderType'="R")||(MOrderType'="R"){
        s ErrMsg=OrderName_" 非药品医嘱不能关联"
        s ErrCode="-1"
        q ErrCode_"^"_ErrMsg
    }*/
    q ErrCode_"^"_ErrMsg
SetPackQty(ParamArr,BaseParamArr,ArcosArr,CallBackFunStr,ItemOrdsArr,UserOptionArr)
    n (ParamArr,BaseParamArr,ArcosArr,CallBackFunStr,ItemOrdsArr,UserOptionArr)
    s ItemDefaultRowId=BaseParamArr("ItemDefaultRowId")
    s OrderPackQty=ParamArr("OrderPackQty")
    s (IsNotNeedChangeFlag,IsNotChangeFirstDayTimeFlag)="N"
    if (($D(ArcosArr("OrderPackQty")) && (ArcosArr("OrderPackQty")'= "")) || ((ItemDefaultRowId '= "") && (OrderPackQty '= ""))) {
        s IsNotNeedChangeFlag = "Y"
    }
    //治疗申请单RowID
    s DCAInfoStr=$G(BaseParamArr("DCAInfoStr"))
    s DCARowID=$p(DCAInfoStr,$c(3),1)
    s DCAFirstTimes=$p(DCAInfoStr,$c(3),3)
    if (DCAFirstTimes'=""){
        s IsNotChangeFirstDayTimeFlag="Y"
        s ParamArr("OrderFirstDayTimes")=DCAFirstTimes
    }
    if (($D(ArcosArr("OrderFirstDayTimes")) && (ArcosArr("OrderFirstDayTimes")'=""))) {
        s IsNotChangeFirstDayTimeFlag="Y"
    }
    s ParamArr("IsNotChangeFirstDayTimeFlag")=IsNotChangeFirstDayTimeFlag
    //--计算首日执行次数,及是否可编辑
    //--Modify 20230130 将IsNotChangeFirstDayTimeFlag的判断移至SetFirstDayTimes内部
    ;if (IsNotChangeFirstDayTimeFlag'="Y"){
        d SetFirstDayTimes(.ParamArr,.BaseParamArr)
    ;}
    d SetFirstDayTimesStr(.ParamArr,.BaseParamArr)
    //--处理不规则单次剂量医嘱
    d CheckItemSameFreqDifferentDoses(.ParamArr,.BaseParamArr,.ItemOrdsArr,.UserOptionArr,.CallBackFunStr)

    k OrdParamArr
    s LinkedMasterOrderPriorRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderPriorRowid"))
    s OrdParamArr("EpisodeID")=BaseParamArr("Adm")
    s OrdParamArr("OrderPriorRowid")=ParamArr("SpecOrderPriorRowid")
    s OrdParamArr("OrderARCIMRowid")=ParamArr("OrderARCIMRowid")
    s OrdParamArr("OrderDoseQty")=ParamArr("OrderDoseQty")
    s OrdParamArr("OrderDoseUOMRowid")=ParamArr("OrderDoseUOMRowid")
    s OrdParamArr("OrderFreqRowid")=ParamArr("OrderFreqRowid")
    s OrdParamArr("OrderDurRowid")=ParamArr("OrderDurRowid")
    s OrdParamArr("OrderPackQty")=ParamArr("OrderPackQty")
    s OrdParamArr("OrderPackUOMRowid")=ParamArr("OrderPackUOMRowid")
    s OrdParamArr("OrderStartDate")=ParamArr("OrderStartDate")
    s OrdParamArr("OrderMultiDate")=""
    s OrdParamArr("OrderPrice")=ParamArr("OrderPrice")
    s OrdParamArr("LinkedMasterOrderPriorRowid")=LinkedMasterOrderPriorRowid
    s OrdParamArr("OrderFreqDispTimeStr")=ParamArr("OrderFreqDispTimeStr")
    s OrdParamArr("OrderFirstDayTimes")=ParamArr("OrderFirstDayTimes")
    s OrdParamArr("IsNotChangeFirstDayTimeFlag")=IsNotChangeFirstDayTimeFlag
    s OrdParamArr("IsNotNeedChangeFlag")=IsNotNeedChangeFlag
    s OrdParamArr("OrderFreqTimeDoseStr")=ParamArr("OrderFreqTimeDoseStr")
    s OrdParamArr("OrderRecDepRowid")=ParamArr("OrderRecDepRowid")
    s OrdParamArr("SessionStr")=BaseParamArr("SessionStr")
    s OrderMasterSeqNo=ParamArr("OrderMasterSeqNo")
    s OrdParamArr("OrderMasterARCIMRowid")=$G(ParamArr("OrderMasterARCIMRowid"))
    s OrdParamArr("OrderVirtualtLong")=$G(ParamArr("OrderVirtualtLong"))
    s OrdParamJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.OrdParamArr)
    s CalPackQtyJson=##Class(web.DHCOEOrdItemView).CalPackQty(OrdParamJson)
    k CalPackQtyArr
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(CalPackQtyJson,.CalPackQtyArr)
    d CheckFreqAndPackQty
    s CalPackQtyCallBackFunStr=$G(CalPackQtyArr("CallBackFunStr"))
    if (CalPackQtyCallBackFunStr'=""){
        if (CallBackFunStr'=""){
            s CallBackFunStr=CallBackFunStr_$C(2)_CalPackQtyCallBackFunStr
        }else{
            s CallBackFunStr=CalPackQtyCallBackFunStr
        }
    }
    k CalPackQtyArr("CallBackFunStr") 
    m ParamArr=CalPackQtyArr
    if $G(ParamArr("OrderPackQty"))'=""{
        s ParamArr("OrderSum") = $FN($G(ParamArr("OrderPrice")) * ParamArr("OrderPackQty"),"",4)
    }
    q
CheckFreqAndPackQty()
    ;改造CheckFreqAndPackQty
    q
SetFirstDayTimes(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    //对有频次的非药品医嘱根据开始时间计算首日次数
    s EpisodeID=BaseParamArr("Adm")
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderFreqRowid=ParamArr("OrderFreqRowid")
    s OrderPriorRowid=ParamArr("SpecOrderPriorRowid")
    s OrderStartDateStr=ParamArr("OrderStartDate")
    s OrderFreqDispTimeStr=ParamArr("OrderFreqDispTimeStr")
    s IsNotChangeFirstDayTimeFlag=ParamArr("IsNotChangeFirstDayTimeFlag")
    s OrderHiddenPara=ParamArr("OrderHiddenPara")
    s LinkedMasterOrderPriorRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderPriorRowid"))
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    s OrderFirstDayTimes=$G(ParamArr("OrderFirstDayTimes"))
    s FDRet=##Class(web.DHCOEOrdItemView).GetOrderFirstDayTimes(EpisodeID, OrderARCIMRowid, OrderFreqRowid, OrderPriorRowid, OrderStartDateStr, LinkedMasterOrderPriorRowid,OrderFreqDispTimeStr,CurLogonHosp,OrderFirstDayTimes)
    s OrderFirstDayTimesEditable=$P(FDRet,"^",2)
    s $P(OrderHiddenPara,$C(1),30)=OrderFirstDayTimesEditable
    s ParamArr("OrderHiddenPara")=OrderHiddenPara
    ;s ParamArr("OrderFirstDayTimesEditable")=$P(FDRet,"^",2)
    if (IsNotChangeFirstDayTimeFlag'="Y"){
	    s ParamArr("OrderFirstDayTimes")=$P(FDRet,"^",1)
	    s ParamArr("OrderFirstDayTimesStr")=$P(FDRet,"^",3)
	    s ParamArr("OrderFirstDayTimesCode")=$P(FDRet,"^",1)
    }
    q

SetFirstDayTimesStr(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    //对有频次的非药品医嘱根据开始时间计算首日次数
    s EpisodeID=BaseParamArr("Adm")
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderFreqRowid=ParamArr("OrderFreqRowid")
    s OrderPriorRowid=ParamArr("SpecOrderPriorRowid")
    s OrderStartDateStr=ParamArr("OrderStartDate")
    s OrderFreqDispTimeStr=ParamArr("OrderFreqDispTimeStr")
    s LinkedMasterOrderPriorRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderPriorRowid"))
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    s OrderFirstDayTimes=$G(ParamArr("OrderFirstDayTimes"))
    s FDRet=##Class(web.DHCOEOrdItemView).GetOrderFirstDayTimes(EpisodeID, OrderARCIMRowid, OrderFreqRowid, OrderPriorRowid, OrderStartDateStr, LinkedMasterOrderPriorRowid,OrderFreqDispTimeStr,CurLogonHosp,OrderFirstDayTimes)
    s ParamArr("OrderFirstDayTimesCode")=$g(ParamArr("OrderFirstDayTimes"))
    s ParamArr("OrderFirstDayTimesStr")=$P(FDRet,"^",3)
    q
SetCalculateValue(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    ///可用天数
    //d SetOrderUsableDays(.ParamArr)
    //--计算医嘱金额
    d SetOrdSum(.ParamArr,.BaseParamArr)
    //--输液次数
    d SetOrderLocalInfusionQty(.ParamArr,.BaseParamArr)
    q
SetOrderLocalInfusionQty(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$p(SessionStr,"^",4)
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderFreqRowid=ParamArr("OrderFreqRowid")
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    s OrderDurRowid=ParamArr("OrderDurRowid")
    s OrderFirstDayTimes=ParamArr("OrderFirstDayTimes")
    s OrderFreqDispTimeStr=ParamArr("OrderFreqDispTimeStr")
    s StartDateStr = ParamArr("OrderStartDate")
    s StartDate = $P(StartDateStr," ",1)
    s OrderLocalInfusionQty=##Class(web.DHCOEOrdItemView).GetOrderLocalInfusionQty(OrderARCIMRowid, OrderFreqRowid, OrderInstrRowid, OrderDurRowid,OrderFirstDayTimes,OrderFreqDispTimeStr,StartDate,CurLogonHosp)
    s ParamArr("OrderLocalInfusionQty")=OrderLocalInfusionQty
    q
SetOrderUsableDays(ParamArr)
    n (ParamArr)
    s OrderARCIMRowid = ParamArr("OrderARCIMRowid")
    s OrderFreqRowid = ParamArr("OrderFreqRowid")
    s OrderDurRowid = ParamArr("OrderDurRowid")
    s OrderPackQty = ParamArr("OrderPackQty")
    if (OrderPackQty = "") {
        q
    }
    s OrderDoseQty = ParamArr("OrderDoseQty")
    s OrderDoseUOMRowid = ParamArr("OrderDoseUOMRowid")
    s OrderPackUOMRowid = ParamArr("OrderPackUOMRowid")
    s OrderType = ParamArr("OrderType")
    s UsableDays =##Class(web.DHCDocOrderEntry).CalcDurByArcim(OrderARCIMRowid, OrderFreqRowid, OrderDurRowid, OrderPackQty, OrderDoseQty, OrderDoseUOMRowid, OrderPackUOMRowid)
    if ((OrderType '= "R") && (UsableDays = "0")) {
        s UsableDays = ""
    }
    s ParamArr("OrderUsableDays")=UsableDays
    q
    
SetBillUOMStr(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s Adm=$G(BaseParamArr("Adm"))
    s isEditCopyItem=BaseParamArr("isEditCopyItem")
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderRecDepRowid=ParamArr("OrderRecDepRowid")
    s SpecOrderPackUOMRowid=ParamArr("SpecOrderPackUOMRowid")
    s OrderPackQty = ParamArr("OrderPackQty")
    s InciRowid=ParamArr("InciRowid")
    s SessionStr = BaseParamArr("SessionStr")
    s langid=$P(SessionStr,"^",6)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    
    //取协议包装单位
    s BillUOMStr = ##Class(web.DHCDocOrderCommon).GetBillUOMStr(OrderARCIMRowid,OrderRecDepRowid,"OrderEntry","",PAAdmType,SessionStr)
    if (SpecOrderPackUOMRowid=""){
        s OrderPackUOMStr=BillUOMStr
    }else{
        //重置默认整包装数量
        s BillUOMStr=$$ReSetBillUomBySpecPackUOM(BillUOMStr,SpecOrderPackUOMRowid)
        s OrderPackUOMStr=BillUOMStr
    }
    s DefaultOrderPackUOM = ""
    s DefaultOrderPackUOMDesc = ""
    s SpecFind=0
    for i = 1:1:$L(BillUOMStr,$C(2)) {
        s ArrData = $P(BillUOMStr,$C(2),i)
        if ($P(ArrData,$C(1),3)="Y") {
            s DefaultOrderPackUOM = $P(ArrData,$C(1),1)
            s DefaultOrderPackUOMDesc = $P(ArrData,$C(1),2)
        }
        if 'SpecFind&&(SpecOrderPackUOMRowid'="")&&(SpecOrderPackUOMRowid=$P(ArrData,$C(1),1)){
            s SpecFind=1
        }
    }
    if (DefaultOrderPackUOM=""){
        s ArrData = $P(BillUOMStr,$C(2),1)
        s DefaultOrderPackUOM = $P(ArrData,$C(1),1)
        s DefaultOrderPackUOMDesc = $P(ArrData,$C(1),2)
    }
    if (SpecOrderPackUOMRowid'=""){
        if 'SpecFind{
            s OrderName=ParamArr("OrderName")
            s CallBackFunParams=..%Translate("oeorder.oplistcustom.new.csp","请注意【",langid)_OrderName_..%Translate("oeorder.oplistcustom.new.csp","】包装单位已经发生变化",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        }
        if (DefaultOrderPackUOM'=SpecOrderPackUOMRowid){
            //如果最终的单位和医嘱套、复制医嘱的原单位不同，尝试做一步单位系数装换，最大程度的保留原数据内容
            s SpecConFac=##class(web.DHCDocOrderEntry).GetConFac(OrderARCIMRowid,InciRowid,SpecOrderPackUOMRowid)
            s DefConFac=##class(web.DHCDocOrderEntry).GetConFac(OrderARCIMRowid,InciRowid,DefaultOrderPackUOM)
            //s ConFac=(SpecConFac\DefConFac)+$Case(SpecConFac#DefConFac,0:0,:1)
            s OrderPackQty=OrderPackQty*SpecConFac/DefConFac
            s OrderPackQty=(OrderPackQty\1)+$Case(OrderPackQty#1,0:0,:1)
            s ParamArr("OrderPackQty")=OrderPackQty
        }
    }
    if (isEditCopyItem = "1") {
        s ParamArr("OrderPackUOM")=DefaultOrderPackUOM
    }else{
        s ParamArr("OrderPackUOM")=DefaultOrderPackUOMDesc
    }
    s ParamArr("OrderPackUOMRowid")=DefaultOrderPackUOM
    s ParamArr("OrderPackUOMStr")=OrderPackUOMStr
    q

ReSetBillUomBySpecPackUOM(BillUOMStr,DefaultOrderPackUOMRowid)
    n (BillUOMStr,DefaultOrderPackUOMRowid)
    s FindDefault=0
    for i = 1:1:$L(BillUOMStr,$C(2)) {
        s ArrData = $P(BillUOMStr,$C(2),i)
        if (($P(ArrData,$C(1),1) = DefaultOrderPackUOMRowid)&&(DefaultOrderPackUOMRowid'="")) {
            s FindDefault=1
        }
    }
    if (FindDefault=1){
        for i = 1:1:$L(BillUOMStr,$C(2)) {
            s ArrData = $P(BillUOMStr,$C(2),i)
            if (($P(ArrData,$C(1),1)=DefaultOrderPackUOMRowid)&&(DefaultOrderPackUOMRowid'="")) {
                s $P(ArrData,$C(1),3)="Y"
            }else{
                s $P(ArrData,$C(1),3)="N"  
            }
            s $P(BillUOMStr,$C(2),i)=ArrData
        }
    }
    q BillUOMStr
ReSetOrderPackQty(ParamArr,BaseParamArr,ArcosArr)
    n (ParamArr,BaseParamArr,ArcosArr)
    s ItemDefaultRowId=BaseParamArr("ItemDefaultRowId")
    //合法性验证
    if (($D(ArcosArr)'=11)&&(ItemDefaultRowId="")){
        //q
    }
        
    s EpisodeID = BaseParamArr("Adm")
    s SessionStr = BaseParamArr("SessionStr")
    s OrderPriorRowid = ParamArr("SpecOrderPriorRowid")
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderType = ParamArr("OrderType")
    s OrderFreqRowid = ParamArr("OrderFreqRowid")
    s OrderPHPrescType = ParamArr("OrderPHPrescType")
    s OrderRecDepRowid=ParamArr("OrderRecDepRowid")
    s OrderNeedPIVAFlag = ParamArr("OrderNeedPIVAFlag")
    s CTLOCID=$P(SessionStr,"^",3)
    s OrderMasterSeqNo=ParamArr("OrderMasterSeqNo")
    s OrderMasterARCIMRowid=$G(ParamArr("OrderMasterARCIMRowid"))
    s OrderVirtualtLong=$G(ParamArr("OrderVirtualtLong"))
    s OrderPackQtyStr=..ContrlOrderPackQty(EpisodeID, OrderPriorRowid, CTLOCID, OrderARCIMRowid, OrderMasterARCIMRowid, OrderRecDepRowid,OrderVirtualtLong)
    s OrderPackQtyStyle=$P(OrderPackQtyStr,"^",1)
    s OrderPackUOMStyle=$P(OrderPackQtyStr,"^",2)
    s SetOrderPackQtyValue=$P(OrderPackQtyStr,"^",3)
    if (SetOrderPackQtyValue'="false"){
        if (SetOrderPackQtyValue="true"){
            s OrderPackQty = ParamArr("OrderPackQty")
        }else{
            s OrderPackQty=SetOrderPackQtyValue
        }
    }else{
        s OrderPackQty = ParamArr("OrderPackQty")
    }
    
    s ParamArr("OrderPackQty")=OrderPackQty
    q
ReSetOrderAndPackQty(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    Set langid=..%LanguageID()

    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderFreqRowid = ParamArr("OrderFreqRowid")
    s OrderPriorRowid = ParamArr("SpecOrderPriorRowid")
    s OrderPriorRemarksRowId = ParamArr("OrderPriorRemarksRowId")
    s OrderPHPrescType = ParamArr("OrderPHPrescType")
    s OrderNeedPIVAFlag=ParamArr("OrderNeedPIVAFlag")
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    s OrderType=ParamArr("OrderType")
    s Adm=$G(BaseParamArr("Adm"))
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s OrderPriorContrlConfig=$G(BaseParamArr("OrderPriorContrlConfig"))
     s OrderPriorContrlConfig=$CASE(OrderPriorContrlConfig,"1":1,:2)
    s LinkedMasterOrderFreRowId=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderFreRowId"))
    s DCAssScaleID=""
    s DCAInfoStr=$G(BaseParamArr("DCAInfoStr"))
    if (DCAInfoStr'="") {
        s DCARowIdStr=$p(DCAInfoStr,$c(3),1)
        ;DCARowIdStr:ChildDCA & MainDCA
		;ChildDCA ChildDCA#AssScaleID 包含当前(绑定关联的)医嘱的治疗申请ID(DCARowID)#治疗评定申请ID
		;MainDCA  MainDCA#AssScaleID  被关联的治疗申请ID(MainDCARowID,绑定的医嘱可能不会生成治疗申请)#治疗评定申请ID
        s DCARowIdStr=$p(DCARowIdStr,"&",1)
		if DCARowIdStr'=""{
			s DCAssScaleID=$p(DCARowIdStr,"#",2)
		}
    }
    s STFreqRowid=$O(^PHCFR(0,"Desc1","ST",0))
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s PriorFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid)
    s OutOrderPriorRowid=$O(^OECPR(0,"Code","OUT",0))
    s IPDefaultDurRowId=..%GetConfig("IPDefaultDuration",CurLogonHosp)
    s IPDefaultDur="",IPDefaultDurFactor=0
    if IPDefaultDurRowId'="" {
        s IPDefaultDur=$P($g(^PHCDU(IPDefaultDurRowId)),"^",3)
        s IPDefaultDurFactor=$P($g(^PHCDU(IPDefaultDurRowId)),"^",2)
    }
    ;外用用法
     s WYInstr=..%GetConfig("WYInstr",CurLogonHosp)
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    if ((OrderPriorCode="STAT") && (OrderFreqRowid'=STFreqRowid)&&(PAAdmType= "I")) {
        s ParamArr("OrderFreq")=$P($g(^PHCFR(STFreqRowid)),"^",3) //"ST"
        s ParamArr("OrderFreqRowid")=STFreqRowid
    }
    
    s (FreqCheckFlag,DurCheckFlag)=1
    ;小时医嘱允许选择录入prn频次
     s AllowHourOrdUsePrn=+..%GetConfig("AllowHourOrdUsePrn",CurLogonHosp)
    ;判断是否是小时医嘱
    s IsHourItem=##Class(web.DHCDocOrderCommon).IsHourItem(OrderARCIMRowid)
    if (IsHourItem="1"){
        if (AllowHourOrdUsePrn'=1)||((AllowHourOrdUsePrn=1)&&(ParamArr("OrderFreqRowid"))&&(ParamArr("OrderFreqRowid")'=$o(^PHCFR(0,"Code","PRN",0)))) {
            s FreqCheckFlag=0
        }
    }
    ;检查用法关联频次是否存在
    if '##class(web.DHCDocOrderCommon).IsValidFreqDurat(ParamArr("OrderInstrRowid"),ParamArr("OrderFreqRowid")){
        s FreqCheckFlag=0
    }
    ;高值标志
    s IncItmHighValueFlag=##Class(web.DHCDocOrderCommon).GetIncItmHighValueFlag(OrderARCIMRowid)
    if (IncItmHighValueFlag = "Y") {
        //高值数量为1不可改
        s ParamArr("OrderPackQty")=1
        //单次计量
        s ParamArr("OrderDoseQty")=""
        //高值医嘱不能录入频次
        s FreqCheckFlag=0
        //疗程
        s DurCheckFlag=0
    }
    //长期可以录入频次的子类，按照执行记录数量计费
    if (OrderPHPrescType = "4") {
        if (PriorFlag="1") {
            s ParamArr("OrderPackQty")=""
        }
    }
    //配液不填整包装
    if (OrderNeedPIVAFlag = "Y") {
        s ParamArr("OrderPackQty")=""
    }
    
    //外用用法 单次剂量和疗程应为空
    if ((("^"_WYInstr_"^")[("^"_OrderInstrRowid_"^")) && (PAAdmType '= "I")) {
        s DurCheckFlag=0
        s ParamArr("OrderDoseQty")=""
    }
    if (PriorFlag="1"){
        s DurCheckFlag=0
    }
    //---
    ///这一段是复写的前台的GetStyleConfigObj，后续可以考虑转移整个GetStyleConfigObj方法
    s OrderDoseQtyStyle=1
    s OrderFreqStyle=0
    if (OrderType'="R"){
        if (OrderPHPrescType="4"){
            s OrderFreqStyle=1
        }
        if (OrderPriorCode'= "S")&&(OrderPriorContrlConfig=1){
            if (ParamArr("idoseqtystr") = "") {
                s OrderDoseQtyStyle = 0
            }
            //非长期治疗医嘱不能填写单次剂量
            s CureItemFlag = ##Class(DHCDoc.DHCDocCure.Service).CheckItem(OrderARCIMRowid,ParamArr("OrderRecDepRowid"),CurLogonHosp)
            if (CureItemFlag="1")&&(OrderFreqStyle=1){
                s OrderDoseQtyStyle = 1
            }
        }else{
            //非药品长期医嘱，有频次不能录入数量，无频次可以录入数量
            //非药品长期医嘱无频次不能录入单次剂量
            if (OrderFreqStyle=0){
                s OrderDoseQtyStyle = 0
            }else{
                s OrderDoseQtyStyle = 1
            }
        }
        //检查检验单次计量不可填写
        s ItemServiceFlag =##Class(web.DHCDocOrderCommon).GetItemServiceFlag(OrderARCIMRowid)
        if ((ItemServiceFlag = "1") || (OrderType = "L")) {
            s OrderDoseQtyStyle = 0
        }
    }else{
        s OrderFreqStyle=1
    }
    if (IncItmHighValueFlag= "Y") {
        s OrderFreqStyle=0
        s OrderDoseQtyStyle=0
    }
    if (IsHourItem="1"){
        s OrderFreqStyle=0
    }
    if (($D(BaseParamArr("VerifiedOrderObj")))&&(LinkedMasterOrderFreRowId'="")) {
        s OrderFreqStyle = 0
    }
    if DCAssScaleID'=""{
        s OrderDoseQtyStyle=0
        s OrderFreqStyle = 0
    }
    ///------
    if (FreqCheckFlag=0){
        s ParamArr("OrderFreq")=""
        s ParamArr("OrderFreqFactor")=1
        s ParamArr("OrderFreqInterval")=""
        s ParamArr("OrderFreqRowid")=""
        s ParamArr("OrderFreqDispTimeStr")="" 
    }
    if (DurCheckFlag=0){
        s ParamArr("OrderDur")=""
        s ParamArr("OrderDurRowid")=""
        s ParamArr("OrderDurFactor")="1"
    }
    if (PAAdmType="I"){
        if (PriorFlag'="1")&&(OutOrderPriorRowid'=OrderPriorRowid)&&(OrderPriorRemarksRowId'="ONE"){
            s ParamArr("OrderDur")=IPDefaultDur
            s ParamArr("OrderDurRowid")=IPDefaultDurRowId
            s ParamArr("OrderDurFactor")=IPDefaultDurFactor
        }
    }
    if $G(ParamArr("OrderVirtualtLong"))="Y"{
        s ParamArr("OrderDur")=IPDefaultDur
        s ParamArr("OrderDurRowid")=IPDefaultDurRowId
        s ParamArr("OrderDurFactor")=IPDefaultDurFactor
    }else{
        if ((PAAdmType'="I")&&(OrderFreqStyle=1)&&(+ParamArr("OrderFreqInterval")'=0)&&(DurCheckFlag'=0)){
            s rtn=##Class(web.DHCDocOrderCommon).GetFirstDurByWeekFreq(ParamArr("OrderFreqInterval"),ParamArr("OrderFreqRowid"),SessionStr)
            s OrderDurRowid=$P(rtn,",",1)
            s OrderDur=$P(rtn,",",2)
            s OrderDurFactor=$P(rtn,",",4)
            if ((OrderDurRowid'="")&&(ParamArr("OrderDurFactor")<OrderDurFactor)){
                s ParamArr("OrderDur")=OrderDur
                s ParamArr("OrderDurRowid")=OrderDurRowid
                s ParamArr("OrderDurFactor")=OrderDurFactor
            }
        }
    }
    if ((OrderDoseQtyStyle=1)&&(ParamArr("OrderPackUOMRowid")'="")&&(OrderType'="R")){
        s PackDesc=##class(web.DHCDocOrderCommon).GetUOMDesc(ParamArr("OrderPackUOMRowid"),langid)
        s idoseqtystr=ParamArr("OrderDoseQty")_$C(1)_PackDesc_$C(1)_ParamArr("OrderPackUOMRowid") //ParamArr("OrderPackUOM")
        if $G(ParamArr("idoseqtystr"))=""{
            s ParamArr("idoseqtystr")=idoseqtystr
        }
        if ($G(ParamArr("OrderDoseUOMRowid"))=""){
            s ParamArr("OrderDoseUOM")=ParamArr("OrderPackUOM")
            s ParamArr("OrderDoseUOMRowid")=ParamArr("OrderPackUOMRowid")
        }
    }
    if (ParamArr("OrderDoseUOMRowid")="")&&($g(ParamArr("idoseqtystr"))'="") {
        s FirstDoseQtyStr=$p(ParamArr("idoseqtystr"),$C(2),1)
        s OrderDoseUOMRowid=$p(FirstDoseQtyStr,$C(1),3)
        s ParamArr("OrderDoseUOMRowid")=OrderDoseUOMRowid
    }
    q
SetLinkedMaster(ParamArr,BaseParamArr,NurseLinkFlag)
    n (ParamArr,BaseParamArr,NurseLinkFlag)
    s LinkedMasterOrderPriorRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderPriorRowid"))
    if (NurseLinkFlag="1"){
        //补录关联医嘱  设置关联信息
        s ParamArr("LinkedMasterOrderRowid")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderRowid"))
        s ParamArr("LinkedMasterOrderSeqNo")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderSeqNo"))
        if (($D(BaseParamArr("VerifiedOrderObj"))>=10)&&(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderRowid")'= "")) {
            s ParamArr("OrderFreq")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderFreDesc"))
            s ParamArr("OrderFreqRowid")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderFreRowId"))
            s ParamArr("OrderFreqFactor")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderFreFactor"))
            s ParamArr("OrderFreqInterval")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderFreInterval"))
            s ParamArr("OrderFreqDispTimeStr")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderFreqDispTimeStr"))
        }
    }
    
    q
CheckItemInsur(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s Adm=$G(BaseParamArr("Adm"))
    s OrderName=ParamArr("OrderName")
    s iinsurinfo=ParamArr("iinsurinfo")
    s GROUPID=$P(SessionStr,"^",2)
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    ;补录模式
     s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
    if (SupplementMode=1){
        q OutInfo
    }
    s HOSPCode=$P(^CT("HOSP",HOSPID),"^",1)
    //入参使用变量定义
    s iinsurinfo = ParamArr("iinsurinfo")
    s iinsurinfo=$replace(iinsurinfo,$c(10),"</br>")
	s iinsurinfo=$replace(iinsurinfo,$c(13),"</br>")
    s OrderARCIMRowid = ParamArr("OrderARCIMRowid")
    s OrderName = ParamArr("OrderName")
    s OrderBillTypeRowid = ParamArr("OrderBillTypeRowid")
    s OrderType = ParamArr("OrderType")
    s Price = ParamArr("OrderPrice")
    //出参定义
    s ParamArr("OrderCoverMainIns")="Y"
    //因为医保串里新增了$C(2)的分割符,所以取值要先处理一下
    s iinsurinfo1 = $P(iinsurinfo, $C(2), 1)
    s limitFlag = $P(iinsurinfo1, $C(1), 5)
    s InsurAdmAllowFlag = $P(iinsurinfo1, $C(1), 6)
    s InsurFlag = $P(iinsurinfo1, $C(1), 7)
    ;非医保提示适应症.,决定是否所有类型的病人都判断
    s CFAllConfirmInsurSYMM=..%GetConfig("AllConfirmInsurSYMM",HOSPID)
    ;确认适应症,提示限制用药
    s CFConfirmInsurSYMM=..%GetConfig("ConfirmInsurSYMM",HOSPID)
    if ((InsurFlag '= "0") || (CFAllConfirmInsurSYMM = 1)) {
        s ParamArr("OrderCoverMainIns")="Y"
        if ((limitFlag) && (CFConfirmInsurSYMM = "1")) {
	        ;s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 此药为限制用药,[限制类型]适应症,[限制内容]",langid)_InsurAdmAllowFlag_..%Translate("oeorder.oplistcustom.new.csp","(必须有临床体征,实验室辅助检查证据和临床诊断依据),请医生根据限制内容判断是否列入医保",langid)
	        s CallBackFunParams="【"_OrderName_"】"_..%Translate("oeorder.oplistcustom.new.csp"," 此药为医保限制用药,[限制类型]适应症,[限制内容]",langid)_InsurAdmAllowFlag_..%Translate("oeorder.oplistcustom.new.csp","(必须有临床体征,实验室辅助检查证据和临床诊断依据)。",langid)_"<br>"_..%Translate("oeorder.oplistcustom.new.csp","请确定该项目是否医保报销！",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetCoverMainIns",CallBackFunParams)
        }
    } else {
        s ParamArr("OrderCoverMainIns")="N"
    }
    ///其他医院的医保适应症控制没有迁移，因为代码里涉及到后台方法医保没有更新
    if ("^YY^BJZYY^BJDTYY^BJFCYY^YKYZLYY^")[("^"_HOSPCode_"^"){
        s ret=$$CheckItemInsurBJ(.ParamArr,.BaseParamArr,.CallBackFunStr)
    }else{
        //北京地区医保适应症提示
        s OrderCoverMainIns=$$CheckItemInsurBJ(.ParamArr,.BaseParamArr,.CallBackFunStr)
        if (OrderCoverMainIns'=""){
            s ParamArr("OrderCoverMainIns")=$case(OrderCoverMainIns,1:"Y",:"N")
        }
    }
	//医保目录是否对照
    if '##class(DHCDoc.Order.Filter).IsContrastInsu(OrderARCIMRowid,OrderBillTypeRowid,HOSPID){
		s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 此医嘱医保目录未对照",langid)
        s AllowNoInsuContrast=..%GetConfig("AllowNoInsuContrast",HOSPID)
        if AllowNoInsuContrast=1{
		    s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        }else{
            s CallBackFunParams=CallBackFunParams_..%Translate("oeorder.oplistcustom.new.csp",",不允许录入",langid)
            s OutInfo="-1^"_CallBackFunParams
            Q OutInfo
        }
	}
    //医保慢特病
    d InsurChronicDiag(.ParamArr,.BaseParamArr,.CallBackFunStr)
    q OutInfo
InsurChronicDiag(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s Adm=$G(BaseParamArr("Adm"))
    s OrderChronicDiagCode=$G(BaseParamArr("OrderChronicDiagCode"))
    s ArcimCode=ParamArr("ArcimCode")
    s ArcimDesc=ParamArr("OrderName")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s langid=$P(SessionStr,"^",6)
    s OrderBillTypeRowid = ParamArr("OrderBillTypeRowid")
    s OrderChronicDiagStr=..GetOrderChronicDiagStr(Adm,ArcimCode,OrderBillTypeRowid,langid)
    if (OrderChronicDiagCode'=""){
        s FindFlag="N"
        for i=1:1:$L(OrderChronicDiagStr,$C(2)){
            s OneChronicDiagStr=$P(OrderChronicDiagStr,$C(2),i)
            s OneChronicDiagCode=$P(OneChronicDiagStr,$C(1),1)
            if (OrderChronicDiagCode=OneChronicDiagCode){
                s FindFlag="Y"
            }
        }
        if (FindFlag="N"){
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 当前病种不可使用该医嘱项，是否确认开立?",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
            s OrderChronicDiagCode=""
        }
    }
    
    s ParamArr("OrderChronicDiagStr")=OrderChronicDiagStr
    s ParamArr("OrderChronicDiagCode")=OrderChronicDiagCode
    
    q
CheckItemInsurBJ(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s OrderCoverMainIns=""
    s DCAInfoStr=$G(BaseParamArr("DCAInfoStr"))
    if (DCAInfoStr'="") {
        s OrderCoverMainIns=$p(DCAInfoStr,$c(3),7)
        ;治疗申请传进来的是Y 
        s OrderCoverMainIns=$case(OrderCoverMainIns,"Y":1,"1":1,:"0")
    }
    s OrderName = ParamArr("OrderName")
    s iinsurinfo = ParamArr("iinsurinfo")
    s InsurAlertStr = $P(iinsurinfo, $C(2), 2)
    if (InsurAlertStr = "") {
    } elseif (InsurAlertStr = "-1") {
    } elseif (InsurAlertStr = "-2") {
    } elseif (InsurAlertStr = "-3") {
    } else {
        s OrderCoverMainIns = 1
        if ($L(InsurAlertStr,"!") = 1) {
            s TarConCode = $P($P(InsurAlertStr,"!",1),$C(1),1)
            s TarConDesc = $P($P(InsurAlertStr,"!",1),$C(1),2)
            s Contype = $P($P(InsurAlertStr,"!",1),$C(1),3)
            s bz = $P($P(InsurAlertStr,"!",1),$C(1),4)
            s CallBackFunParams=OrderName_" 此药为限制用药,[限制类型]适应症,[限制内容]"_bz_"(必须有临床体征,实验室辅助检查证据和临床诊断依据),请医生根据限制内容判断是否列入医保"
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetCoverMainIns",CallBackFunParams)
        }
        if ($L(InsurAlertStr,"!") > 1) {
            s CallBackFunParams=InsurAlertStr //_"&"_Row
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetInsurCat",CallBackFunParams)
        }
    }
    q OrderCoverMainIns
CheckItemInsurLimit(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s Adm=$G(BaseParamArr("Adm"))
    s OrderName=ParamArr("OrderName")
    s iinsurinfo=ParamArr("iinsurinfo")
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    s OrderHiddenPara=ParamArr("OrderHiddenPara")
    s NeedSkinTestINCI=$P(OrderHiddenPara,$C(1),8)
    s GROUPID=$P(SessionStr,"^",2)
    s CurLogonHosp=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    ;补录模式
     s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
    if (SupplementMode=1){
        q OutInfo
    }
    ;皮试用法
    s SkinTestInstr=..%GetConfig("SkinTestInstr",CurLogonHosp)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s InsurAdmFlag = $P(iinsurinfo,$C(1),1)
    s DiagnosCatArcimPass = $P(iinsurinfo,$C(1),2)
    s PreOrderDateStr = $P(iinsurinfo,$C(1),3)
    s PreOrderDate = $P(PreOrderDateStr,$C(3),1)
    s PreOrderIntervalDur = $P(PreOrderDateStr,$C(3),2)
    s IsADMInsTypeDCArcim = $P(iinsurinfo,$C(1),4)
    if ((InsurAdmFlag = "1") && (PAAdmType= "I")) {
        s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 此项目只限在门诊使用",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        q OutInfo
    }
    if ((InsurAdmFlag = "2") && (PAAdmType = "I")) {
        s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 医保限制用药",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        q OutInfo
    }
    s OrderBillTypeRowid=ParamArr("OrderBillTypeRowid")
    s AdmReasonDeac=$p($g(^PAC("ADMREA",OrderBillTypeRowid)),"^",2)
	s AdmReasonDeac=##class(User.PACAdmReason).GetTranByDesc("READesc",AdmReasonDeac,langid)
    if ((DiagnosCatArcimPass = "0") && (PAAdmType'= "I")) {
        s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 受病种诊断限制,不允许开 ",langid)_AdmReasonDeac_..%Translate("oeorder.oplistcustom.new.csp"," 处方,请修改费别!",langid)
        q OutInfo
    }
    if ((PreOrderDate '= "") && (PAAdmType = "O")) {
        //&&(NeedSkinTestINCI="Y")
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_OrderInstrRowid_"^")){
            s CallBackFunParams=PreOrderDate_OrderName_..%Translate("oeorder.oplistcustom.new.csp","已经开过相同的医嘱且在疗程内,不允许再开治疗用药.还剩余",langid)_PreOrderIntervalDur_..%Translate("oeorder.oplistcustom.new.csp","天,是否确认要增加?",langid)
            s CallBackFunStr=##Class(web.DHCOEOrdItemView).GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
        }else{
            s OutInfo="-1^"_PreOrderDate_OrderName_..%Translate("oeorder.oplistcustom.new.csp","已经开过相同的医嘱且在疗程内,不允许再开治疗用药.还剩余",langid)_PreOrderIntervalDur_..%Translate("oeorder.oplistcustom.new.csp","天",langid)
            q OutInfo
        }
    }
    

    if (IsADMInsTypeDCArcim = "1") {
        s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","此为特病项目,请在特病处方内开医嘱",langid)
        q OutInfo
    }
    q OutInfo
SetOrderMsgAlert(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s OrderMsg = ParamArr("OrderMsg")
    s OrderName = ParamArr("OrderName")
    s ARCIMShowOEMessageFlag = ParamArr("ARCIMShowOEMessageFlag")
    //一次录入多条医嘱提示是否弹出对话框,默认弹出
    s EntryMulAlert = 1
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s GROUPID=$P(SessionStr,"^",2)
    s CurLogonHosp=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    ;补录模式
     s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
    ;医嘱项提示是否弹出窗口
    s CFOrderMsgAlert=..%GetConfig("OrderMsgAlert",CurLogonHosp)
    if (SupplementMode=1){
        s CFOrderMsgAlert=1
    }
    if (OrderMsg '= "") {
        if (ARCIMShowOEMessageFlag = "Y") {
            s CallBackFunParams=OrderName_" "_..%Translate("oeorder.oplistcustom.new.csp",OrderMsg,langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        } else {
            if (CFOrderMsgAlert= "1") {
                s CallBackFunParams=..%Translate("oeorder.oplistcustom.new.csp","提示信息:",langid)_OrderName_" "_..%Translate("oeorder.oplistcustom.new.csp",OrderMsg,langid)
                s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetPrompt",CallBackFunParams)
            } else {
                s CallBackFunParams=OrderName_" "_..%Translate("oeorder.oplistcustom.new.csp",OrderMsg,langid)
                s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
            }
        }
    }else{
        /*if (CFOrderMsgAlert= "1") {
            s CallBackFunParams="提示信息:"
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetPrompt",CallBackFunParams)
        }*/
    }
    q
SetOrdPriorRemarks(ParamArr,BaseParamArr,RowDataArr)
    n (ParamArr,BaseParamArr,RowDataArr)
    s Adm=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s OrderPriorRemarksRowId = ParamArr("OrderPriorRemarksRowId")
    s OrderPriorRowid = ParamArr("OrderPriorRowid")
    //药学项上的嘱托或取药或自备药标志
    s PHCDFCQZTFlag = ParamArr("PHCDFCQZTFlag")
    s PHCDFONEFlag = ParamArr("PHCDFONEFlag")
    s PHCDFCHKOMFlag = ParamArr("PHCDFCHKOMFlag")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    if (OrderPriorRemarksRowId="") {
        s OrderPriorRemarksRowId = RowDataArr("OrderPriorRemarksRowId")
    }
    if PAAdmType="I"{
        //长期默认嘱托的药品不允许修改附加说明
        s DefCQZTNotAllowChange=..%GetConfig("DefCQZTNotAllowChange",HOSPID)
        //临时默认取药的药品不允许修改附加说明
        s DefONENotAllowChange=..%GetConfig("DefONENotAllowChange",HOSPID)
        if (OrderPriorCode="S")&&(DefCQZTNotAllowChange=1)&&(PHCDFCQZTFlag="Y"){
            s OrderPriorRemarksRowId="ZT"
        }
        if (OrderPriorCode="NORM")&&(DefONENotAllowChange=1)&&(PHCDFONEFlag="Y"){
            s OrderPriorRemarksRowId="ONE"
        }
    }
    if (OrderPriorRemarksRowId'="") {
        s OrderPriorRemarks = $CASE(OrderPriorRemarksRowId,"OM":"自备药","ZT":"嘱托","ONE":"取药医嘱",:"")
        s ParamArr("OrderPriorRemarks")=OrderPriorRemarks
        s ParamArr("OrderPriorRemarksRowId")=OrderPriorRemarksRowId
    } else {
        s DefaultOrdRemarkFlag=0
        if ((OrderPriorCode="S")&&(PHCDFCQZTFlag="Y")){
            s OrderPriorRemarks="嘱托"
            s OrderPriorRemarksRowId="ZT"
            s DefaultOrdRemarkFlag=1
        }
        if ((OrderPriorCode="NORM")&&(PHCDFONEFlag="Y")&&(PAAdmType="I")){
            s OrderPriorRemarks="取药医嘱"
            s OrderPriorRemarksRowId="ONE"
            s DefaultOrdRemarkFlag=1
        }
        if (PHCDFCHKOMFlag="Y"){
            s OrderPriorRemarks="自备药"
            s OrderPriorRemarksRowId="OM"
            s DefaultOrdRemarkFlag=1
        }
        if (DefaultOrdRemarkFlag=1){
            s ParamArr("OrderPriorRemarks")=OrderPriorRemarks
            s ParamArr("OrderPriorRemarksRowId")=OrderPriorRemarksRowId
        }
    }
    if ((OrderPriorCode="S")||(OrderPriorCode="OUT"))&&(OrderPriorRemarksRowId="ONE") {
        s OrderPriorRemarks="",OrderPriorRemarksRowId=""
        s ParamArr("OrderPriorRemarks")=OrderPriorRemarks
        s ParamArr("OrderPriorRemarksRowId")=OrderPriorRemarksRowId
    }
    s SpecOrderPriorRowid=..ReSetOrderPriorRowid(ParamArr("OrderPriorRowid"),ParamArr("OrderPriorRemarksRowId"))
    s ParamArr("SpecOrderPriorRowid")=SpecOrderPriorRowid
    q
SetOrdNeedPIVAFlag(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    ;静脉配液中心接收可是ID串
     s IPDosingRecLocStr=##Class(DHCDoc.DHCDocConfig.DocConfig).GetDosingRecLocStr(CurLogonHosp)
    s OrderRecDepRowid = ParamArr("OrderRecDepRowid")
    s OrderType=ParamArr("OrderType")
    if (IPDosingRecLocStr '= "") {
        if ((("^"_IPDosingRecLocStr_"^")[("^"_OrderRecDepRowid_"^"))&&(OrderType="R")) {
            s ParamArr("OrderNeedPIVAFlag")="Y"
        } else {
            s ParamArr("OrderNeedPIVAFlag")="N"
        }
    } else {
        s ParamArr("OrderNeedPIVAFlag")="N"
    }
    q
SetOrdSum(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s Adm=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s Sum=$G(ParamArr("OrderSum"))
    if (Sum'=""){
        if (PAAdmType '= "I") {
            s Sum = $FN(Sum,"",2)
        }else{
            s Sum = $FN(Sum,"",4)
        }
        s ParamArr("OrderSum")=Sum
        Q
    }
    s Price = ParamArr("OrderPrice")
    s OrderPackQty = ParamArr("OrderPackQty")
    s OrderPriorRowid = ParamArr("OrderPriorRowid")
    s OrderBaseQtySum = $g(ParamArr("OrderBaseQtySum"))
    
    s OrderConFac = ParamArr("OrderConFac")
    s Qty = ParamArr("Qty")
    s OrderPriorRowid=ParamArr("OrderPriorRowid")
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s Price =$FN(Price,"",4)
    ;SetOrdSum
    if (PAAdmType '= "I") {
        if (+OrderPackQty=0){
           s Sum = (OrderBaseQtySum/OrderConFac) * Price
        }else{
        
            s Sum = OrderPackQty * Price
        }
        s Sum = $FN(Sum,"",2)
    } else {
        //自备药医嘱不计入总金额
        s Sum = 0
        if ((OrderPriorCode '= "OM") && (OrderPriorCode '= "OMST")) {
            if (OrderPackQty'=""){
                s Sum = OrderPackQty * Price
            }else{
                s Sum = (Price/OrderConFac) * Qty
            }
        }
        s Sum = $FN(Sum,"",4)
    }
    s ParamArr("OrderSum")=Sum
    q
SetOrdPrice(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s Adm=BaseParamArr("Adm")
    s OrderName =ParamArr("OrderName")
    s OrderBillTypeRowid=ParamArr("OrderBillTypeRowid")
    s LogonDep=$G(BaseParamArr("LogonDep"))
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderOpenForAllHosp=""
    s OrderPackUOMRowid=ParamArr("OrderPackUOMRowid")
    s OrderRecDepRowid=ParamArr("OrderRecDepRowid")
    s OrderMaterialBarCode = BaseParamArr("MaterialBarcode")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s ExpStr = OrderMaterialBarCode_"^"_HOSPID
    
    s retPrice =##Class(web.DHCDocOrderCommon).GetOrderPriceConUom(Adm, OrderBillTypeRowid, LogonDep, OrderARCIMRowid, OrderOpenForAllHosp, OrderPackUOMRowid, OrderRecDepRowid,ExpStr)
    s Price = $P(retPrice,"^",1)
    s OrderConFac=$P(retPrice,"^",5)
    if (Price < 0) {
        s ParamArr("OrderPrice")=""
        q "-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","此接收科室下无有效医嘱项,请切换接收科室或联系相关人员处理",langid)
    } else {
        s ParamArr("OrderPrice")=Price
        s ParamArr("OrderConFac")=OrderConFac
    }
    q "0^^^^^"
SetDefaultRecLoc(ParamArr,BaseParamArr,RowDataArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,RowDataArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s OrderPriorRemarksRowId=RowDataArr("OrderPriorRemarksRowId")
    if ($g(ParamArr("OrderPriorRemarksRowId"))'=""){
        s OrderPriorRemarksRowId=$g(ParamArr("OrderPriorRemarksRowId"))
    }
    if ((OrderPriorRemarksRowId '= "OM") && (OrderPriorRemarksRowId '= "ZT")) {
        s OrderRecDepStr = $$CheckStock(.ParamArr,.BaseParamArr,.CallBackFunStr)
        if (+OrderRecDepStr'=0) {
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetEnoughStock","")
            s OutInfo="-1^"_$P(OrderRecDepStr,"^",2)
        } else {
            s OrderRecDepRowid=$P(OrderRecDepStr,"^",2)
            s OrderRecDep=$P(OrderRecDepStr,"^",3)
            s ParamArr("CurrentRecLocStr") = $$ResetDefaultCurrLocStr(ParamArr("CurrentRecLocStr"), OrderRecDepRowid)
            s ParamArr("OrderRecLocStr") = $$ResetDefaultCurrLocStr(ParamArr("OrderRecLocStr"), OrderRecDepRowid)
            s ParamArr("OrderRecDep")=OrderRecDep
            s ParamArr("OrderRecDepRowid")=OrderRecDepRowid
        }
        q:(+OutInfo<0) OutInfo
        //医生站配液中心设置业务代码
        /*
        //没有必要把时间修改成配液开始时间，当天的时间已经过了，改也不会发
        s DosingDateTimeStr=..GetDosingDateTime(ParamArr("OrderARCIMRowid"),ParamArr("OrderRecDepRowid"),ParamArr("OrderPriorRowid"))
        if (DosingDateTimeStr'=""){
            s ParamArr("OrderStartDate")=$P(DosingDateTimeStr,"^",1)_" "_$P(DosingDateTimeStr,"^",2)
        }
        */
    }else{
        s CurrentRecLocStr=ParamArr("CurrentRecLocStr")
        s DefaultRecLocStr=$$GetDefaultRecLocStr(CurrentRecLocStr)
        s DefaultRecLocRowid=$P(DefaultRecLocStr,"^",1)
        s DefaultRecLocDesc=$P(DefaultRecLocStr,"^",2)
        s ParamArr("OrderRecDep")=DefaultRecLocDesc
        s ParamArr("OrderRecDepRowid")=DefaultRecLocRowid
    }
    q OutInfo
GetDefaultRecLocStr(RecLocStr)
    n (RecLocStr)
    s DefaultRecLocRowid = ""
    s DefaultRecLocDesc = ""
    for i=1:1:$L(RecLocStr,$C(2)) {
        s ArrData = $P(RecLocStr,$C(2),i)
        if (($P(ArrData,$C(1),3)="Y") && (DefaultRecLocRowid="")) {
            s DefaultRecLocRowid = $P(ArrData,$C(1),1)
            s DefaultRecLocDesc = $P(ArrData,$C(1),2)
        }
    }
    if (DefaultRecLocRowid = "") {
        s ArrData = $P(RecLocStr,$C(2),1)
        s DefaultRecLocRowid = $P(ArrData,$C(1),1)
        s DefaultRecLocDesc = $P(ArrData,$C(1),2)
    }
    q DefaultRecLocRowid_"^"_DefaultRecLocDesc
ResetDefaultCurrLocStr(CurrentRecLocStr,ReDefaultRecLocRowID)
    n (CurrentRecLocStr,ReDefaultRecLocRowID)
    s findDefaultRecLocFlag = 0
    s BeforeDefaultRecLocIndex = -1
    s AfterDefaultRecLocIndex = -1
    for i=1:1:$L(CurrentRecLocStr,$C(2)) {
        s ArrData =$P(CurrentRecLocStr,$C(2),i)
        if (($P(ArrData,$C(1),3)="Y")) {
            s BeforeDefaultRecLocIndex = i
        }
        if ($P(ArrData,$C(1),1)= ReDefaultRecLocRowID) {
            s findDefaultRecLocFlag = 1
            s AfterDefaultRecLocIndex = i
        }
    }
    if (findDefaultRecLocFlag = 1) {
        if (BeforeDefaultRecLocIndex >= 0) {
            s ArrData=$P(CurrentRecLocStr,$C(2),BeforeDefaultRecLocIndex)
            s $P(ArrData,$C(1),3)="N"
            s $P(CurrentRecLocStr,$C(2),BeforeDefaultRecLocIndex)=ArrData
        }
        if (AfterDefaultRecLocIndex >= 0) {
            s ArrData=$P(CurrentRecLocStr,$C(2),AfterDefaultRecLocIndex)
            s $P(ArrData,$C(1),3)="Y"
            s $P(CurrentRecLocStr,$C(2),AfterDefaultRecLocIndex)=ArrData
        }
    }
    q CurrentRecLocStr
CheckStock(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s Adm=$G(BaseParamArr("Adm"))
    s SessionStr=BaseParamArr("SessionStr")
    s CurLogonDep=$p(SessionStr,"^",3)
    s HOSPID=$p(SessionStr,"^",4)
    s langid=$p(SessionStr,"^",6)
    s InciRowid =ParamArr("InciRowid")
    s OrderPriorRowid =ParamArr("OrderPriorRowid")
    s OrderPriorRemarks =$g(ParamArr("OrderPriorRemarksRowId"))
    s OrderConFac =ParamArr("OrderConFac")
    s OrderName =ParamArr("OrderName")
    s OrderARCIMRowid =ParamArr("OrderARCIMRowid")
    s CurrentRecLocStr =ParamArr("CurrentRecLocStr")
    s SpecOrderPackUOMRowid=$G(ParamArr("SpecOrderPackUOMRowid"))
    s OrderItemCatRowid=ParamArr("OrderItemCatRowid")
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    ;可以录入小数的子类
    s AllowEntryDecimalItemCat=##Class(web.DHCDocOrderCommon).GetAllowEntryDecimalItemCat(Adm,HOSPID)
    s OrderRecDepRowid = ""
    s OrderRecDep = ""
    //如果为非库存项,将不会进入这个判断
    //if (InciRowid != "") { //20170310 不需要此判断条件，因为非库存项医嘱有可能绑定有库存项医嘱项目
        if ((OrderPriorCode'="OM")&&(OrderPriorCode'="OMST")&&(OrderPriorRemarks'="OM")) {
            if (("^"_AllowEntryDecimalItemCat_"^")[("^"_OrderItemCatRowid_"^")){
                s CheckQty = 0.001
            }else{
                s CheckQty = 1
            }
            if (PAAdmType'="I") {
               // s CheckQty = OrderConFac
               s CheckQty = ParamArr("OrderPackQty")
               i CheckQty="" s CheckQty=1
            }
            s ret = ..CheckStockEnough(Adm,OrderARCIMRowid,CheckQty,CurrentRecLocStr,CurLogonDep,SpecOrderPackUOMRowid,OrderPriorRowid,.CallBackFunStr,langid)
            //返回库存医嘱的可用库存的科室,
            if ($P(ret,"^",1)="") {
                q "-1^"_$P(ret,"^",2)
            } else {
                s OrderRecDepRowid = $P(ret, $C(1), 1)
                s OrderRecDep = $P(ret, $C(1), 2)
            }
        } else {
            //自备取默认第一个接收科室
            //如果OrderRecDepRowid为空会导致 SetRowDataObj 里的OrderPackUOMStr:GetBillUOMStrMethod 报错
            s OrderRecDepRowid = $P($P(CurrentRecLocStr,$C(2),1),$C(1),1)
               s OrderRecDep = $P($P(CurrentRecLocStr,$C(2),1),$C(1),2)
        }
    //}
    q "0^"_OrderRecDepRowid_"^"_OrderRecDep

SetCurrentRecLocStr(ParamArr,BaseParamArr,MainOrdCongeriesArr)
    n (ParamArr,BaseParamArr,MainOrdCongeriesArr)
    //因为出院带药有可能指定接收科室?所以会存在两个接收科室串
    //注：  出院带药、取药医嘱：接收科室定义优先级高于节假日接收科室
    //      非长期药品医嘱：节假日接收科室优先级高于用法接收科室
    //      用法接收科室
    //      接受科室设置（医嘱项>子类>大类）

    //----
	k ParamJson,OrderParamArr
	s ITMRowId=$G(BaseParamArr("ITMRowId"))
	s ItemDefaultRowId=$G(BaseParamArr("ItemDefaultRowId"))
	s DCAInfoStr=$G(BaseParamArr("DCAInfoStr"))
	s DCARecLocRowId=+$p(DCAInfoStr,$c(3),2)
	s DCAOpenForAllHosp=$p(DCAInfoStr,$c(3),9)
	s DCAFindLocByLog=$p(DCAInfoStr,$c(3),10)
	s SessionStr=$G(BaseParamArr("SessionStr"))
    s langid=$P(SessionStr,"^",6)
	s DefaultRecLoc=""
	//增加对医嘱套维护接收科室设置
    if ((+ITMRowId'="0")&&($l(ITMRowId,"||")=3)){
	    s DefaultRecLoc=$p($g(^ARCOS(+ITMRowId,"DATE",$p(ITMRowId,"||",2),"ITM",$p(ITMRowId,"||",3))),"^",21)
	}
    //常用用法维护接收科室设置
    if (ItemDefaultRowId'=""){
	    s DIDLocDr=$P($g(^DHCDID(ItemDefaultRowId)),"^",27)
		s:DIDLocDr'="" DefaultRecLoc=DIDLocDr
	}
	//治疗申请传入接收科室
	if DCARecLocRowId>0{
		s DefaultRecLoc=DCARecLocRowId
	}
	s OpenForAllHospFlag=""
	if DCAOpenForAllHosp'=""{
		s OpenForAllHospFlag=DCAOpenForAllHosp	
	}else{
		s OpenForAllHospFlag=$G(BaseParamArr("OrderOpenForAllHosp"))		
	}
	s FindRecLocByLogonLoc=""
	if DCAFindLocByLog'=""{
		s FindRecLocByLogonLoc=DCAFindLocByLog	
	}else{
		s FindRecLocByLogonLoc=$CASE($G(BaseParamArr("LogonDep")),"":0,:1)
	}
	s OrderParamArr("EpisodeID")=$G(BaseParamArr("Adm"))
    s OrderParamArr("SessionStr")=$G(BaseParamArr("SessionStr"))
    s OrderParamArr("OpenForAllHosp")=OpenForAllHospFlag
    s OrderParamArr("FindRecLocByLogonLoc")=FindRecLocByLogonLoc
	s OrderParamArr("DefaultReclocRowid")=DefaultRecLoc
    s OrderParamArr("OrderARCIMRowid")=ParamArr("OrderARCIMRowid")
    s OrderParamArr("OrderInstrRowid")=ParamArr("OrderInstrRowid")
    s OrderParamArr("OrderDateStr")=""
    s OrderParamArr("OrderPriorRowid")=ParamArr("OrderPriorRowid")
    s OrderParamArr("OrderPriorRemarksRowId")=$g(ParamArr("OrderPriorRemarksRowId"))
    s OrderParamArr("NotifyClinician")=$g(ParamArr("Urgent"))

    s LinkOrderARCIMList=""
    s OrderCalSeqNo=BaseParamArr("CalSeqNo")
    //找到所有的成组医嘱数据
    /*
        tanjishan 2022年9月16日
        这里的计算关联有可能不准确，未添加到行上的数据在实际计算过后可能还会清除关联，导致主医嘱计算接受科室有误。
        但是如果子医嘱清除关联之后，剩余组医嘱的再重新计算比较困难。
        ---现在去除关联应该只有【不能关联的子类】设置，与药品医嘱的匹配程度不高。
    */
    s i =""
    for{
        s i=$O(MainOrdCongeriesArr(i))
        q:(i="")
        s CalSeqNo = $g(MainOrdCongeriesArr(i,"CalSeqNo"))
        continue:CalSeqNo=""
        if ($p(OrderCalSeqNo,".")=$p(CalSeqNo,"."))&&(CalSeqNo'=OrderCalSeqNo){
            if (LinkOrderARCIMList=""){
                s LinkOrderARCIMList=$g(MainOrdCongeriesArr(i,"OrderARCIMRowid"))
            }else{
                s LinkOrderARCIMList=LinkOrderARCIMList_"^"_$g(MainOrdCongeriesArr(i,"OrderARCIMRowid"))
            }
        }
    }
    s OrderParamArr("LinkOrderARCIMList")=LinkOrderARCIMList
	s ParamJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.OrderParamArr)
    
	s RecLocJson=##CLass(web.DHCDocOrderCommon).GetRecLocInfo(ParamJson)
	d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(RecLocJson,.RecLocArr)

	s CurrentRecLocStr=$G(RecLocArr("CurrentRecLocStr"))
	s OrderOutPriorRecLocStr=$G(RecLocArr("OrderOutPriorRecLocStr"))
    s OrderOnePriorRecLocStr=$G(RecLocArr("OrderOnePriorRecLocStr"))
    s OrderHolidayRecLocStr=$G(RecLocArr("OrderHolidayRecLocStr"))
    s OrderNormalRecLocStr=$G(RecLocArr("OrderNormalRecLocStr"))
    if (CurrentRecLocStr'=""){
        s ParamArr("CurrentRecLocStr")=CurrentRecLocStr
        s ParamArr("OrderOutPriorRecLocStr")=OrderOutPriorRecLocStr
        s ParamArr("OrderOnePriorRecLocStr")=OrderOnePriorRecLocStr
        s ParamArr("OrderHolidayRecLocStr")=OrderHolidayRecLocStr
        //理论上此时的OrderRecLocStr才是最准确的，但是OrderRecLocStr发生变化是否会对该调用之前的逻辑有影响，待验证
        s ParamArr("OrderRecLocStr")=OrderNormalRecLocStr
        q "0^^^^^^"
    }else{
        s ArcimDesc=ParamArr("OrderName")
        q "-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 接收科室串为空,请联系信息中心!",langid)_"^^^^^"
    }
    
SetFreqByPrior(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s OrderPHPrescType = ParamArr("OrderPHPrescType")
    s OrderType=ParamArr("OrderType")
    s Adm=$G(BaseParamArr("Adm"))
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s OrderPriorRowid=ParamArr("OrderPriorRowid")
    s OrderPriorRemarksRowId=ParamArr("OrderPriorRemarksRowId")
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s STFreqRowid=$O(^PHCFR(0,"Desc1","ST",0))
    s ONCEFreqRowid=$O(^PHCFR(0,"Code","ONCE",0))
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s OrderFreqRowid = ""
    s OrderFreq = ""
    s OrderFreqFactor = 1
    s OrderFreqInterval = 1
    ;住院临时医嘱默认频次
     //s IPShortOrderPriorST=..%GetConfig("IPShortOrderPriorST")
     s IPShortOrderPriorDefFreq=..%GetConfig("IPShortOrderPriorDefFreq",HOSPID)
     if ('$d(^PHCFR(IPShortOrderPriorDefFreq))) s IPShortOrderPriorDefFreq=""
    if ((PAAdmType = "I") && (OrderPriorCode="NORM")) {
        if ((ParamArr("OrderFreqRowid")'=STFreqRowid)&&(ParamArr("OrderFreqRowid")'=ONCEFreqRowid)) {
            /*s ItemServiceFlag =##Class(web.DHCDocOrderCommon).GetItemServiceFlag(ParamArr("OrderARCIMRowid"))
            //检验、检查项目 住院临时医嘱默认频次为空
            if ((OrderType'="L")&&(ItemServiceFlag'="1")){
                s OrderFreq = "ST"
                s OrderFreqRowid = STFreqRowid
                s OrderFreqFactor = 1
                s OrderFreqInterval = 1
            }*/
            //if (IPShortOrderPriorST'="1"){
            if (IPShortOrderPriorDefFreq=""){
                s ParamArr("OrderFreq")=""
                s ParamArr("OrderFreqRowid")=""
                s ParamArr("OrderFreqFactor")=1
                s ParamArr("OrderFreqInterval")=1
            }
        }
    }
    if (((OrderPriorCode="NORM")||(OrderPriorCode="OM"))&&(OrderPriorRemarksRowId'="ONE") &&
        (ParamArr("OrderFreqRowid")'=STFreqRowid)&&(ParamArr("OrderFreqRowid")'=ONCEFreqRowid)&&((OrderType="R")||(OrderPHPrescType="4"))&&(PAAdmType="I")&&
        (IPShortOrderPriorDefFreq'="")) {
        s OrderFreq = $P($g(^PHCFR(IPShortOrderPriorDefFreq)),"^",3) //"ST"
        s OrderFreqRowid = IPShortOrderPriorDefFreq
        s OrderFreqFactor = 1
        s OrderFreqInterval = 1
    }
    /*if (((OrderPriorCode="NORM")||(OrderPriorCode="OM")) &&
        (ParamArr("OrderFreqRowid")'=STFreqRowid)&&((OrderType="R")||(OrderPHPrescType="4"))&&(PAAdmType="I")&&
        (IPShortOrderPriorST="1")) {
        s OrderFreq = $P($g(^PHCFR(STFreqRowid)),"^",3) //"ST"
        s OrderFreqRowid = STFreqRowid
        s OrderFreqFactor = 1
        s OrderFreqInterval = 1
    }*/

    if ((OrderPriorCode="STAT")&&(ParamArr("OrderFreqRowid")'=STFreqRowid)&&(PAAdmType'="I")) {
        s OrderFreq = $P($g(^PHCFR(STFreqRowid)),"^",3) //"ST"
        s OrderFreqRowid = STFreqRowid
        s OrderFreqFactor = 1
        s OrderFreqInterval = 1
    }
    if ((OrderPriorCode="S") && ((ParamArr("OrderFreqRowid")=STFreqRowid) || (ParamArr("OrderFreqRowid")=ONCEFreqRowid))) {
        s ParamArr("OrderFreq")=OrderFreq
        s ParamArr("OrderFreqRowid")=OrderFreqRowid
        s ParamArr("OrderFreqFactor")=OrderFreqFactor
        s ParamArr("OrderFreqInterval")=OrderFreqInterval
    }
    ;取可用频次串
     s ValidFreqStr=##Class(web.DHCDocOrderCommon).CheckDataValidByAdmType("Freq",PAAdmType)
    s IsValidFreq = 1
    if (OrderFreqRowid '= "") {
        if (("^"_ValidFreqStr_"^")'[("^"_OrderFreqRowid_"^")) {
            s IsValidFreq = 0
        }
    } else {
        if (("^"_ValidFreqStr_"^")'[("^"_ParamArr("OrderFreqRowid")_"^")) {
            s IsValidFreq = 0
        }
    }
    if (IsValidFreq = 0) {
        s ParamArr("OrderFreq")=""
        s ParamArr("OrderFreqRowid")=""
        s ParamArr("OrderFreqFactor")=1
        s ParamArr("OrderFreqInterval")=1
    }else{
        if (OrderFreqRowid '= "") {
            s ParamArr("OrderFreq")=OrderFreq
            s ParamArr("OrderFreqRowid")=OrderFreqRowid
            s ParamArr("OrderFreqFactor")=OrderFreqFactor
            s ParamArr("OrderFreqInterval")=OrderFreqInterval
        }
    }
    //--重新得到基本单位数量
    d SetBaseDoseQty(.ParamArr,.BaseParamArr)
    q
CheckPrescAndDupOrder(ParamArr, BaseParamArr,ItemOrdsArr,UserOptionArr,CallBackFunStr)
    n (ParamArr, BaseParamArr,ItemOrdsArr,UserOptionArr,CallBackFunStr) 
    s OrderType=ParamArr("OrderType")
    s ArcimDesc=ParamArr("OrderName")
    s OrderItemCatRowid=ParamArr("OrderItemCatRowid")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s langid=$P(SessionStr,"^",6)
    s Adm=$G(BaseParamArr("Adm"))
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s USERID=$P(SessionStr,"^",1)
    s GROUPID=$P(SessionStr,"^",2)
    s CurLogonHosp=$p(SessionStr,"^",4)
    s langid=$p(SessionStr,"^",6)
    ;补录模式
     s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
    if (OrderType="R") {
        s PrescCheck = $$CheckPrescItemAndCount(.ParamArr,.BaseParamArr,.ItemOrdsArr,.UserOptionArr,.CallBackFunStr)
        if (+PrescCheck<0) {
            q PrescCheck
        }
    }elseif (SupplementMode'=1){
        if (PAAdmType="I"){
            //住院患者判断出院医嘱是否重复开立
            if (##class(web.DHCDocOrderEntry).IsDischargeOrd(ParamArr("OrderARCIMRowid"),CurLogonHosp)'=0) {
                s PrescCheck = $$CheckDupOrderItem(.ParamArr,.BaseParamArr,.ItemOrdsArr)
                if (+PrescCheck=1) {
                    s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 已存在出院医嘱,不允许再开!",langid)_"^^^^"
                    q OutInfo
                }
            }
        }
        //非药物、死亡、高值医嘱也要判断重复
        s IncItmHighValueFlag=##Class(web.DHCDocOrderCommon).GetIncItmHighValueFlag(ParamArr("OrderARCIMRowid"))
        s NotAlertRepeatItemCat=..%GetConfig("NotAlertRepeatItemCat",CurLogonHosp)
        if (("^"_NotAlertRepeatItemCat_"^")'[("^"_OrderItemCatRowid_"^"))||(IncItmHighValueFlag="Y") {
            s PrescCheck = $$CheckDupOrderItem(.ParamArr,.BaseParamArr,.ItemOrdsArr)
            if (+PrescCheck=1) {
                s PrescCheckPriorType=$P(PrescCheck,"^",2)
                s PrescCheckPriorType=##class(User.OECPriority).GetTranByDesc("OECPRDesc",PrescCheckPriorType,langid)
                s FindSttDateTime=$P(PrescCheck,"^",3)
                if (IncItmHighValueFlag="Y"){
                    s OutInfo="-1^"_BaseParamArr("MaterialBarcode")_..%Translate("oeorder.oplistcustom.new.csp"," 条码已被使用!",langid)_"^^^^"
                    q OutInfo
                }else{
                    s CallBackFunParams=PrescCheckPriorType_ArcimDesc_" "_FindSttDateTime_..%Translate("oeorder.oplistcustom.new.csp","已存在相同的医嘱,是否确认要增加?",langid)
                    s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
                }
            }
        }
        
        if (OrderType="L") {
            //判断是否有样本指标重复
            s ret = $$CheckDupLabSpecItem(.ParamArr,.ItemOrdsArr,.BaseParamArr,.CallBackFunStr)
            if (+ret<0) {
                q ret
            }
        }
    }
    //不同就诊当天是否已经开了此医嘱提示    集成到重复医嘱提示中去
    /*if ((PAAdmType'="I")&&(SupplementMode'="1")){
        s ret=##Class(web.DHCDocOrderEntry).CheckSameItem(Adm,ParamArr("OrderARCIMRowid"),CurLogonHosp)
        if (ret'=""){
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 该病人今天已经在 ")_ret_..%Translate("oeorder.oplistcustom.new.csp"," 开过,是否继续录入?")
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
        }
    }*/
    q "1"
CheckDupLabSpecItem(ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    s OrderLabExCode=ParamArr("OrderLabExCode")
    if (OrderLabExCode=""){
        q "1"
    }
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s ArcimDesc=ParamArr("OrderName")
    s LabExCode =ParamArr("OrderLabExCode")
    s LabSpecStr =ParamArr("OrderLabSpec")
    s OrderLabExCodeStr = ""
    s OrderRowStr = ""
    //SetBaseDefaultInfo中已经置过默认值，不需要重新再取
    s LabSpecRowid=ParamArr("OrderLabSpecRowid")
    s i=""
    for {
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        s OrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
        s OrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
        continue:((OrderARCIMRowid="")||(OrderItemRowid'=""))
        s OrderRowid = ItemOrdsArr("ItemOrds",i,"rowid")
        s OrderLabSpecRowid=ItemOrdsArr("ItemOrds",i,"OrderLabSpecRowid")
        s OrderType=""
        s OrderItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
        s:OrderItemCatDr'="" OrderType=$P(^ARC("IC",OrderItemCatDr),"^",7)
        s OrderLabExCode=##Class(web.DHCDocOrderCommon).GetExCode(OrderARCIMRowid)
        if ((OrderLabExCode'="") && (OrderLabSpecRowid = LabSpecRowid)) {
            if (OrderLabExCodeStr = "") {
                s OrderLabExCodeStr = OrderLabExCode
                s OrderRowStr = OrderRowid
            } else {
                s OrderLabExCodeStr = OrderLabExCodeStr_"^"_OrderLabExCode
                s OrderRowStr = OrderRowStr_"^"_OrderRowid
            }
        }
    }
    /*;使用按医院区分检验设置(全局)
    s UseHospSepLabConfig=..%GetConfig("UseHospSepLabConfig")
    if (UseHospSepLabConfig="1"){
        s SessionStr=$G(BaseParamArr("SessionStr"))
        s HOSPID=$P(SessionStr,"^",4)
        s CFNotCheckSameSpecItem=##Class(DHCDoc.DHCDocConfig.DocConfig).GetLabOtherCheck("NotCheckSameLabSpecItem",HOSPID)
    }else{*/
        ;<常规设置>不允许重复的检验项
        s CFNotCheckSameSpecItem=..%GetConfig("NotCheckSameLabSpecItem",HOSPID)
    //}
    if (OrderLabExCodeStr'="")&&(CFNotCheckSameSpecItem'="1"){
        s ret =##Class(web.DHCDocOrderCommon).CheckRepeatLabSpec(OrderLabExCodeStr, LabExCode,HOSPID)
        if ($P(ret,"^",1)="1") {
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 本医嘱包含的检验项目与前面已开医嘱的检验项目重复,是否继续开出？")
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
        }
    }
    q "1"
CheckPrescItemAndCount(ParamArr,BaseParamArr,ItemOrdsArr,UserOptionArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,ItemOrdsArr,UserOptionArr,CallBackFunStr) 
    s OutInfo="^^"
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s ItemDesc =ParamArr("OrderName")
    s ArcimRowid =ParamArr("OrderARCIMRowid")
    s BillGrpDesc = ParamArr("OrderPHPrescType")
    s FormDesc = ParamArr("OrderPHForm")
    s PHPoisonCode = ParamArr("OrderPoisonCode")
    s OrderGenericName = ParamArr("OrderGenericName")
    s LimitDetail = ParamArr("ilimitstr")
    s OrderItemCatRowid=ParamArr("OrderItemCatRowid")
    s OrderMaxDoseQtyPerDay = $P(LimitDetail, $C(1), 6)
    s OutInfo=$$CheckItemPoison(.ParamArr,.BaseParamArr,.CallBackFunStr)
    Q:(+OutInfo)<0 OutInfo
    
    //非自动分方下的审核医嘱控制-1
    s PrescCheck = $$CheckPrescriptCount(.ParamArr,.BaseParamArr,.ItemOrdsArr)
    if (PrescCheck = "0") {
        s OutInfo="-1^"_ItemDesc_..%Translate("oeorder.oplistcustom.new.csp","超过处方项目数量限定",langid)_"^^^^^^^"
        q OutInfo
    }
    //非自动分方下的审核医嘱控制-2
    s PrescCheck = $$CheckPrescriptPoisonCount(.ParamArr,.BaseParamArr,.ItemOrdsArr)
    if (PrescCheck ="0") {
        s OutInfo="-1^"_ItemDesc_..%Translate("oeorder.oplistcustom.new.csp","超过抗菌药物处方项目数量限定",langid)_"^^^^^^^"
        q OutInfo
    }
    ;重复通用名
    s PrescCheck = $$CheckPrescSameGenericNameItem(.ParamArr,.BaseParamArr,.ItemOrdsArr)
    if (PrescCheck = "0") {
        s OutInfo="-1^"_ItemDesc_..%Translate("oeorder.oplistcustom.new.csp"," 通用名相同的药品不允许重复",langid)_"^^^^^^^"
        q OutInfo
    }
    ;重复医嘱
    s PrescCheck = $$CheckDupOrderItem(.ParamArr,.BaseParamArr,.ItemOrdsArr)
    if (+PrescCheck=1) {
        s NotAlertRepeatItemCat=..%GetConfig("NotAlertRepeatItemCat",CurLogonHosp)
        if (("^"_NotAlertRepeatItemCat_"^")'[("^"_OrderItemCatRowid_"^")) {
            s PrescCheckPriorType=$P(PrescCheck,"^",2)
            s PrescCheckPriorType=##class(User.OECPriority).GetTranByDesc("OECPRDesc",PrescCheckPriorType,langid)
            s FindSttDateTime=$P(PrescCheck,"^",3)
            s CallBackFunParams=PrescCheckPriorType_ItemDesc_" "_FindSttDateTime_..%Translate("oeorder.oplistcustom.new.csp","已存在相同的医嘱,是否确认要增加?",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
        }
    }
    //$.messager.alert("警告","009");
    s ItemDiagnosCheck = $$CheckItemDiagnos(.BaseParamArr)
    if (+ItemDiagnosCheck="0") {
        s OutInfo="-1^"_ItemDesc_..%Translate("oeorder.oplistcustom.new.csp","医嘱不符合诊断,",langid)_$p(ItemDiagnosCheck,"^",2)_"^^^^^^^"
        q OutInfo
    }
    q OutInfo
CheckItemDiagnos(BaseParamArr)
    n (BaseParamArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s OrderARCIMRowid=BaseParamArr("OrderARCIMRowid")
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    if (PAAdmType = "I") {q "1"}
    s PatientID=$P(^PAADM(EpisodeID),"^",1)
    s SocialStatusDr=$P(^PAPER(PatientID,"PER",1),"^",10)
    s mradm=##Class(web.DHCPAADM).GetMRAdmID(EpisodeID)
    s retDetail =##Class(web.DHCDocOrderEntry).CheckItemDiagnos(SocialStatusDr, OrderARCIMRowid, mradm, HOSPID, langid)
    if (+retDetail= 1){
        s SocialStatus=$p($g(^CT("SS",SocialStatusDr)),"^",2)
		s SocialStatus=##class(User.CTSocialStatus).GetTranByDesc("SSDesc",SocialStatus,langid)
        q "0"_"^【"_SocialStatus_..%Translate("oeorder.oplistcustom.new.csp","】患者要求诊断为: 【",langid)_$p(retDetail,"^",2)_"】"
    }
    q "1"

CheckDupOrderItem(ParamArr,BaseParamArr,ItemOrdsArr)
    n (ParamArr,BaseParamArr,ItemOrdsArr)
    s OrderPriorType=""
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    s ARCIMRowid=ParamArr("OrderARCIMRowid")
    
    s CheckOrderPriorRowid=ParamArr("OrderPriorRowid")
    s EpisodeID=BaseParamArr("Adm")
    s USERID=$P(SessionStr,"^",1)
    s GROUPID=$P(SessionStr,"^",2)
    s CurLogonHosp=$p(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s DischargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(ARCIMRowid,CurLogonHosp)
    s IncItmHighValueFlag=##Class(web.DHCDocOrderCommon).GetIncItmHighValueFlag(ParamArr("OrderARCIMRowid"))
    ;补录模式
     s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
    if (SupplementMode=1){q "0^"_OrderPriorType}
    s StartDateStr = ParamArr("OrderStartDate")
    ;用法是皮试的药品，不再提示重复用药；仅当待审核列表中存在相同用法是皮试的药品时，才提示重复用药；
    s SkinTestInstr=..%GetConfig("SkinTestInstr",CurLogonHosp)
    if SkinTestInstr'="" s SkinTestInstr="^"_SkinTestInstr_"^"
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    s CurrOrdIsSkinInstrFlag="N"
    if (SkinTestInstr'="")&&(SkinTestInstr[("^"_OrderInstrRowid_"^")){
        s CurrOrdIsSkinInstrFlag="Y"
    }
    
    s StartDate = $P(StartDateStr," ",1)
    s NotSamePriorNeedAlertItemCat=..%GetConfig("NotSamePriorNeedAlertItemCat",CurLogonHosp)
    i NotSamePriorNeedAlertItemCat'="" s NotSamePriorNeedAlertItemCat="^"_NotSamePriorNeedAlertItemCat_"^"
    s tmpAricmStr=##class(web.DHCSTMHUI.PCHCOLLSM).GetArcimByLabel(BaseParamArr("MaterialBarcode"))
    s ret=""
    s i=""
    for {
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        s OrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
        s OrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
        continue:((OrderARCIMRowid="")||(OrderItemRowid'=""))
        s OrderRowid = ItemOrdsArr("ItemOrds",i,"rowid")
        s OrderType=""
        s OrderItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
        s:OrderItemCatDr'="" OrderType=$P(^ARC("IC",OrderItemCatDr),"^",7)
        s OrderStartDateStr = ItemOrdsArr("ItemOrds",i,"OrderStartDate")
        s OrderStartDate = $P(OrderStartDateStr," ",1)
        s OrderPriorRowid =ItemOrdsArr("ItemOrds",i,"OrderPriorRowid")
        continue:(OrderItemCatDr'="")&&(NotSamePriorNeedAlertItemCat'[("^"_OrderItemCatDr_"^"))&&(CheckOrderPriorRowid'=OrderPriorRowid)
        s OrderInstrRowid=ItemOrdsArr("ItemOrds",i,"OrderInstrRowid")
        s OrdIsSkinInstrFlag="N"
        if (SkinTestInstr'="")&&(SkinTestInstr[("^"_OrderInstrRowid_"^")){
            s OrdIsSkinInstrFlag="Y"
        }
        if (OrdIsSkinInstrFlag'=CurrOrdIsSkinInstrFlag){
            continue
        }
        
        s OrderDischargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(OrderARCIMRowid,CurLogonHosp)
        if ((ARCIMRowid=OrderARCIMRowid)&&(OrderStartDate=StartDate))||((OrderDischargeOrdFlag'=0)&&(DischargeOrdFlag'=0)) {
            if (IncItmHighValueFlag="Y"){
                //有可能是通过自带条码录入的医嘱,需要转成对应的高值条码判断
                s tmpOrderAricmStr=##class(web.DHCSTMHUI.PCHCOLLSM).GetArcimByLabel(ItemOrdsArr("ItemOrds",i,"OrderMaterialBarcode"))
                //if (ItemOrdsArr("ItemOrds",i,"OrderMaterialBarcode")=BaseParamArr("MaterialBarcode")) {
                if ($p(tmpOrderAricmStr,"^",9)=$p(tmpAricmStr,"^",9)) {
                    s OrderPriorType=$P(^OECPR(OrderPriorRowid),"^",2)

                    s ret="1^"_OrderPriorType
                    q
                }
            }else{
                s OrderPriorType=$P(^OECPR(OrderPriorRowid),"^",2)
                s ret="1^"_OrderPriorType
                q
            }
         }
    }
    if (+ret=1){
        q ret 
    }
    
    //高值材料无须验证已审核医嘱，因为高值材料开立后条码不可用
    if (IncItmHighValueFlag'="Y")&&(CurrOrdIsSkinInstrFlag="N"){
        s retDetail =##Class(web.DHCDocOrderEntry).FindSameOrderItemFlagMethod(EpisodeID,ARCIMRowid,CheckOrderPriorRowid,CurLogonHosp,langid)
           if (+retDetail=1){
            q retDetail
        }
    }
    s ret="0^"_OrderPriorType
    q ret
CheckPrescSameGenericNameItem(ParamArr,BaseParamArr,ItemOrdsArr)
    n (ParamArr,BaseParamArr,ItemOrdsArr)
    s GenericName=ParamArr("OrderGenericName")
    if (GenericName=""){q "1"}
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s USERID=$P(SessionStr,"^",1)
    s GROUPID=$P(SessionStr,"^",2)
    s HOSPID=$P(SessionStr,"^",4)
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    ;通用名相同的药品不允许重复
     s CFOPNotRepeatGenericName=..%GetConfig("OPNotRepeatGenericName",HOSPID)
    if (CFOPNotRepeatGenericName'= 1){q "1"}
    ;补录模式
     s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
    if (SupplementMode=1){q "1"}
    if (PAAdmType = "I"){q "1"}
    s SkinTestInstr=..%GetConfig("SkinTestInstr",HOSPID)
    if SkinTestInstr'="" s SkinTestInstr="^"_SkinTestInstr_"^"
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    ;皮试用法不判断重复
    if (SkinTestInstr'="")&&(SkinTestInstr[("^"_OrderInstrRowid_"^")){
        q "1"
    }
    
    s limitNum = 2
    s count = 0
    s i=""
    for {
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        s OrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
        s OrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
        continue:((OrderARCIMRowid="")||(OrderItemRowid'=""))
        s OrderRowid = ItemOrdsArr("ItemOrds",i,"rowid")
        s iOrderInstrRowid=ItemOrdsArr("ItemOrds",i,"OrderInstrRowid")
        if (SkinTestInstr'="")&&(("^"_SkinTestInstr_"^")[("^"_iOrderInstrRowid_"^")){
            continue
        }
        s OrderType=""
        s OrderItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
        s:OrderItemCatDr'="" OrderType=$P(^ARC("IC",OrderItemCatDr),"^",7)
        s OrderGenericName=##class(web.UDHCPrescript).GetDrugCommonNameByArcimId(OrderARCIMRowid)
        if (OrderType="R") {
            if ((GenericName=OrderGenericName)){
                 s count = count + 1
            }
        }
    }
    if (count>=1){
        q "0"
    }
    s ret=##Class(web.DHCDocOrderEntry).FindSameGenericNameOrderItem(EpisodeID,GenericName)
    if (ret = 1) {
        q "0"
    }
    q "1"
    
CheckPrescriptPoisonCount(ParamArr,BaseParamArr,ItemOrdsArr)
    n (ParamArr,BaseParamArr,ItemOrdsArr)
    s EpisodeID=BaseParamArr("Adm")
    s PHPoisonCode=ParamArr("OrderPoisonCode")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    Set PrescByAuto=..%GetConfig("PrescByAuto",HOSPID)
    if (PAAdmType = "I") {q "1"}
    if (PHPoisonCode '[ "KSS") {q "1"}
    if (PrescByAuto = 1) {q "1"}
    s PHPrescType=ParamArr("OrderPHPrescType")
    s PrescBillTypeRowid = BaseParamArr("OrderBillTypeRowid")
    s PrescCount = 0
    s i=""
    for {
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        s OrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
        s OrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
        continue:((OrderARCIMRowid="")||(OrderItemRowid'=""))
        s OrderMasterSeqNo =ItemOrdsArr("ItemOrds",i,"OrderMasterSeqNo")
        s OrderType=""
        s OrderItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
        s:OrderItemCatDr'="" OrderType=$P(^ARC("IC",OrderItemCatDr),"^",7)
        s OrderPHPrescType=##Class(web.DHCDocOrderCommon).GetPHPrescType(OrderItemCatDr,HOSPID,OrderARCIMRowid)
        s OrderBillTypeRowid = ItemOrdsArr("ItemOrds",i,"OrderBillTypeRowid")
        if ((OrderType="R") && (OrderPHPrescType=PHPrescType) && (OrderBillTypeRowid=PrescBillTypeRowid)) {
            s PrescCount = PrescCount + 1
        }
    }
    s PrescLimitCount = 3
    if (PrescLimitCount <= PrescCount) { q "0"}
    q "1"

CheckPrescriptCount(ParamArr,BaseParamArr,ItemOrdsArr)
    n (ParamArr,BaseParamArr,ItemOrdsArr)
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s BillTypeID=$p($g(^PAADM(EpisodeID,1)),"^",7)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    ;按用法分处方
     s PrescByInstr=..%GetConfig("PrescByInstr",HOSPID)
     Set PrescByAuto=..%GetConfig("PrescByAuto",HOSPID)
    if (PAAdmType="I"){
        q "1"
    }
    //如果按用法分方?A就只能在保存时判断?A因为在录入过程中有可能改变用法
    if (PrescByInstr = 1) {q "1"}
    if (PrescByAuto = 1) {q "1"}
    s PrescBillTypeRowid = BaseParamArr("OrderBillTypeRowid")
    s PHPrescType=ParamArr("OrderPHPrescType")
    s PrescCount = 0
    s i=""
    for {
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        s OrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
        s OrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
        s OrderBillTypeRowid = ItemOrdsArr("ItemOrds",i,"OrderBillTypeRowid")
        s OrderType=""
        s OrderItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
        s:OrderItemCatDr'="" OrderType=$P(^ARC("IC",OrderItemCatDr),"^",7)
        s OrderPHPrescType=##Class(web.DHCDocOrderCommon).GetPHPrescType(OrderItemCatDr,HOSPID,OrderARCIMRowid)
        s OrderMasterSeqNo = ItemOrdsArr("ItemOrds",i,"OrderMasterSeqNo")
        s OrderSeqNo = ItemOrdsArr("ItemOrds",i,"OrderSeqNo")
        continue:((OrderARCIMRowid="")||(OrderItemRowid'=""))
        if ((OrderType="R") && (OrderPHPrescType=PHPrescType)&&(OrderBillTypeRowid=PrescBillTypeRowid)) {
            if (OrderMasterSeqNo="") {
                s PrescCount = PrescCount + 1
            }
        }
    }
    s PrescLimitCount = 0
    if (PHPrescType="1") s PrescLimitCount = 5
    if (PHPrescType="2") {
        s PrescLimitCount = 5
    }
    if ((PrescLimitCount'=0)&&(PrescLimitCount'="")) {
        if (PrescLimitCount <= PrescCount){
            q "0"
        }
    }
    q "1"

CheckItemPoison(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s USERID=$P(SessionStr,"^",1)
    s HOSPID=$P(SessionStr,"^",4)
    s UserIDCardNo=$p(^SSU("SSUSR",USERID),"^",122) //开医嘱人的身份证号
    ;常规设置-允许开医嘱人给自己开毒麻药品
    s AllowUserEnrtyOwnDMDrug=..%GetConfig("AllowUserEnrtyOwnDMDrug",HOSPID)
    ;常规设置-每次开立毒麻药品时都需要核对患者身份信息
    s AlwaysShowAgencyInfoWhenDMDrug=..%GetConfig("AlwaysShowAgencyInfoWhenDMDrug",HOSPID)
    ;常规设置-开立毒麻药品时办人信息必填
	s RequiredAgencyInfoWhenDMDrug=..%GetConfig("RequiredAgencyInfoWhenDMDrug",HOSPID)
    ;精麻毒性必须录入身份证号
    s ItemDesc =ParamArr("OrderName")
    s PHPoisonCode=ParamArr("OrderPoisonCode")
    s EpisodeID=BaseParamArr("Adm")
    s PatientID = $P(^PAADM(EpisodeID),"^",1)	
	s langid=$P(SessionStr,"^",6)
    ;获取身份证信息
     s IDCardNo=##Class(web.DHCDocOrderEntry).FindPAPMIID(PatientID)
    if ((PHPoisonCode="J1")||(PHPoisonCode="DX")||(PHPoisonCode="MZ")||(PHPoisonCode="DM")){
        if (UserIDCardNo=IDCardNo)&&(IDCardNo'="")&&(AllowUserEnrtyOwnDMDrug'=1) {
              s OutInfo="-1^"_ItemDesc_..%Translate("oeorder.oplistcustom.new.csp","是"_$case(PHPoisonCode,"J1":"精一",:"毒麻")_"类处方,不能自己为自己开立!",langid)_"^^^^^^^"
             q OutInfo
        }
        s RelationFlag=0
        if (RequiredAgencyInfoWhenDMDrug="1"){
            Set AgencyName=$P($G(^PAADM(EpisodeID,"DHC")),"^",36)
            Set AgencyCredNo=$P($G(^PAADM(EpisodeID,"DHC")),"^",35)
            Set AgencyTel=$P($G(^PAADM(EpisodeID,"DHC")),"^",37)
            Set AgencyCredDr=$P($G(^PAADM(EpisodeID,"DHC")),"^",55)
            if (AgencyName'="")&&(AgencyTel'="")&&(AgencyCredNo'="")&&(AgencyCredDr'="") s RelationFlag=1
        }
        if (IDCardNo="")||(AlwaysShowAgencyInfoWhenDMDrug=1)||((RequiredAgencyInfoWhenDMDrug=1)&&(RelationFlag=0)){
            s CallBackFunParams=ItemDesc
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"CheckPoison",CallBackFunParams)
        }
    }
    
    if ((PHPoisonCode = "DBTHZJ") || (PHPoisonCode = "TLJS")) {
        s CallBackFunParams=ItemDesc_..%Translate("oeorder.oplistcustom.new.csp","POISON_SPORT_ALERT",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
    }
    q OutInfo
CheckItemSameFreqDifferentDoses(ParamArr,BaseParamArr,ItemOrdsArr,UserOptionArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,ItemOrdsArr,UserOptionArr,CallBackFunStr)
    Q:$g(ParamArr("SameFreqDifferentDosesFlag"))'="Y"
    s OrderMasterSeqNo=$g(ParamArr("OrderMasterSeqNo"))
    s OrderFreqRowid=$g(ParamArr("OrderFreqRowid"))
    s OrderFreqFactor = $G(ParamArr("OrderFreqFactor"))
    s OrderFreqDispTimeStr=$G(ParamArr("OrderFreqDispTimeStr"))
    s OrderPriorRowid=ParamArr("OrderPriorRowid")
    s OrderDirectEntryAuth=ParamArr("OrderDirectEntryAuth")
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s LongPriorFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid)
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
	s langid=$P(SessionStr,"^",6)
    s OrderPriorRemarksRowId=ParamArr("OrderPriorRemarksRowId")
    if ('LongPriorFlag)&&(PAAdmType="I")&&(OrderPriorCode'="OUT")&&(OrderPriorRemarksRowId'="ONE") {
        if (ParamArr("OrderDoseQty")["-") s ParamArr("OrderDoseQty")=""
        s FirstOrderDoseQty=$p($p($g(ParamArr("OrderFreqTimeDoseStr")),"!",1),"$",2)
        if (FirstOrderDoseQty'="") s ParamArr("OrderDoseQty")=FirstOrderDoseQty
        s ParamArr("OrderFreqTimeDoseStr")=""
        Q
    }
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    if (CallBackFunStr["FreeTime")&&(CallBackFunStr["SetOrderFreqDispTimeStr"){
        //先处理完不规则分发时间
        q
    }
    s WYInstr=..%GetConfig("WYInstr",CurLogonHosp)
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    if ((("^"_WYInstr_"^")[("^"_OrderInstrRowid_"^")) && (PAAdmType '= "I")) {
        s ParamArr("OrderFreqTimeDoseStr")=""
        q 
    }
    s i=""
    for {
        s i=$O(ItemOrdsArr("ItemOrds",i))
        q:(i="")
        continue:(ItemOrdsArr("ItemOrds",i,"OrderItemRowid")'="")
        //continue:(ItemOrdsArr("ItemOrds",i,"rowid")=BaseParamArr("rowid"))
        s tmpOrderSeqNo=ItemOrdsArr("ItemOrds",i,"OrderSeqNo")
        s tmpOrderFreqRowid=ItemOrdsArr("ItemOrds",i,"OrderFreqRowid")
        if (OrderMasterSeqNo=tmpOrderSeqNo)&&(tmpOrderFreqRowid'="")&&(tmpOrderFreqRowid'=OrderFreqRowid){
            s OrderFreqRowid=tmpOrderFreqRowid
            s OrderFreqFactor=$G(ItemOrdsArr("ItemOrds",i,"OrderFreqFactor"))
            s OrderFreqDispTimeStr=$G(ItemOrdsArr("ItemOrds",i,"OrderFreqDispTimeStr")) //$G(ParamArr("OrderFreqDispTimeStr"))
            Q
        }
    }
    ;频次不为空且FreqFactor大于1,弹出剂量填写界面
    if +OrderFreqFactor<=1 {
        if (ParamArr("OrderDoseQty")["-") s ParamArr("OrderDoseQty")=""
        s FirstOrderDoseQty=$p($p($g(ParamArr("OrderFreqTimeDoseStr")),"!",1),"$",2)
        if (FirstOrderDoseQty'="") s ParamArr("OrderDoseQty")=FirstOrderDoseQty
        s ParamArr("OrderFreqTimeDoseStr")=""
    }
    s OrderFreqTimeDoseStr=$g(ParamArr("OrderFreqTimeDoseStr"))
    s LongPriorFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid)
    s FreqFreqDispTimeStr=..GetFreqFreqDispTimeStr(OrderFreqRowid,OrderFreqDispTimeStr)
    if (FreqFreqDispTimeStr'="")&&($l(FreqFreqDispTimeStr,"!")>1)&&((LongPriorFlag=1)||(OrderPriorCode="OUT")||(OrderPriorRemarksRowId="ONE")||(PAAdmType'="I")){
        if (OrderFreqTimeDoseStr="")||'..CompareDispTimeAndDoseQty(OrderFreqTimeDoseStr,FreqFreqDispTimeStr){
            //tanjishan 2020.5.6 目前没找到更好的办法去处理，当同时存在皮试引导与多频次、周频次的情况下，皮试引导的优先级别应最高
            if (CallBackFunStr'["GuideAllergy")&&(OrderDirectEntryAuth="Y"){
                s i=$O(UserOptionArr("SetMulDoses",0))
                if (i=""){
                    s OrderARCIMRowid=$g(ParamArr("OrderARCIMRowid"))
                    s OrderName =ParamArr("OrderName")
                    s OrderDoseUOM=$g(ParamArr("OrderDoseUOM"))
                    s OrderDoseQty=$g(ParamArr("OrderDoseQty"))
                    s OrderFirstDayTimes=$g(ParamArr("OrderFirstDayTimes"))
                    s FreqDispTimeDoseQtyStr=""
                    if OrderDoseQty'=""{
                        for i=1:1:$L(FreqFreqDispTimeStr,"!"){
                            s PHCDTRowID=$P($P(FreqFreqDispTimeStr,"!",i),"$")
                            i FreqDispTimeDoseQtyStr="" s FreqDispTimeDoseQtyStr=PHCDTRowID_"$"_OrderDoseQty
                            e  s FreqDispTimeDoseQtyStr=FreqDispTimeDoseQtyStr_"!"_PHCDTRowID_"$"_OrderDoseQty
                        }
                    }
                    s CallBackFunParams=FreqFreqDispTimeStr_";"_OrderName_";"_FreqDispTimeDoseQtyStr_";"_OrderDoseUOM_";"_OrderFirstDayTimes
                    s CallBackFunStr=..DelCallBackFunStr(CallBackFunStr,"SetMulDoses")
                    s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetMulDoses",CallBackFunParams)
                    q
                }
                s OrderFreqTimeDoseStr=$G(UserOptionArr("SetMulDoses",i,"Value"))
                if (OrderFreqTimeDoseStr=""){
                    s ParamArr("OrderFreq")=""
                    s ParamArr("OrderFreqRowid")=""
                    s ParamArr("OrderFreqFactor")=1
                    s ParamArr("OrderFreqInterval")=""
                    s ParamArr("OrderFreqDispTimeStr")="" 
                    s ParamArr("OrderDoseQty")="" 
                    s ParamArr("OrderFreqTimeDoseStr")=""
                    s OrderName =ParamArr("OrderName")
                    s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 同频次不同剂量医嘱请务必按照分发时间填写剂量",langid)
                    s CallBackFunStr=..DelCallBackFunStr(CallBackFunStr,"MulDosesAlert")
                    s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"MulDosesAlert",CallBackFunParams)
                    q
                }
                s ParamArr("OrderFreqTimeDoseStr")=OrderFreqTimeDoseStr
            }
        }
    }else{
        s ParamArr("OrderFreqTimeDoseStr")=""
    }
    Q
    
SetOrderPrior(ParamArr,BaseParamArr,ArcosArr,RowDataArr,CallBackFunStr,NurseLinkFlag)
    n (ParamArr,BaseParamArr,ArcosArr,RowDataArr,CallBackFunStr,NurseLinkFlag)
    /*
    该方法输出后，得到的结果应该有3个
    ParamArr("SpecOrderPriorRowid") 真正的医嘱类型
    ParamArr("OrderPriorRowid")医嘱类型列
    ParamArr("OrderPriorRemarksRowId")附加说明代码
    */
    s OutInfo="0^^^^^^^"
    s Adm=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(Adm)
    s EpisodeID=BaseParamArr("Adm")
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s ArcimDesc=ParamArr("OrderName")
    s OrderItemCatRowid=ParamArr("OrderItemCatRowid")
    s ARCIMDefSensitive=ParamArr("ARCIMDefSensitive")
    s SessionStr=BaseParamArr("SessionStr")
    s USERID=$P(SessionStr,"^",1)
    s GROUPID=$P(SessionStr,"^",2)
    s CurLogonDep=$p(SessionStr,"^",3)
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s OrderPriorContrlConfig=BaseParamArr("OrderPriorContrlConfig")
    s PageDefaultOrderPriorStr=BaseParamArr("PageDefaultOrderPriorStr")
    s GlobalDefaultOrderPriorRowid=BaseParamArr("GlobalDefaultOrderPriorRowid")
    s AdmOrderPriorStr=##Class(web.DHCDocOrderCommon).GetOrderPrior(Adm,"JSON",CurLogonDep,langid,USERID,GROUPID)
    //获取医嘱类型 
    s (OrderPriorRowid,OrderPrior,OrderPriorStr) = ""
    ///
    s SpecOrderPriorRowid=$G(ParamArr("SpecOrderPriorRowid"))
    s SpecOrderPriorCode=""
    s:SpecOrderPriorRowid'="" SpecOrderPriorCode=$P(^OECPR(SpecOrderPriorRowid),"^",1)
    //优先考虑传入的Para中已经指定了医嘱类型的情况(医嘱套,医嘱复制等)
    if ($G(ParamArr("SpecOrderPriorRowid"))'="") {
        /*if ((ParamArr("skintestyy")="1") && (SpecOrderPriorCode'="NORM")) {
            s ShortOrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
            s ParamArr("SpecOrderPriorRowid")=ShortOrderPriorRowid
        }*/
        //如果护士类型复制开出院带药则转为临时
        s DoctorType=##class(web.SSUser).GetDefaultCareProviderType(USERID)
        if DoctorType'="DOCTOR"{
            s OutOrderPriorRowid=$O(^OECPR(0,"Code","OUT",0))
            if (ParamArr("SpecOrderPriorRowid")=OutOrderPriorRowid){
                s ShortOrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
                s ParamArr("SpecOrderPriorRowid")=ShortOrderPriorRowid
                }
        }
        s SpecOrderPrior=##Class(web.DHCDocOrderCommon).GetOrderPriorByID($G(ParamArr("SpecOrderPriorRowid")))
				s SpecOrderPrior=##class(User.OECPriority).GetTranByDesc("OECPRDesc",SpecOrderPrior,langid)
        s OrderPriorStr=ParamArr("SpecOrderPriorRowid")_":"_SpecOrderPrior
        //如果在全局的医嘱类型中包含则可赋值否则走强制默认的医嘱类型,门诊,医技可能只有临时
        if (AdmOrderPriorStr[OrderPriorStr) {
            s OrderPriorRowid = ParamArr("SpecOrderPriorRowid")
        }
        /*
        //使用皮试引导时，若选择皮试与界面强制医嘱类型不符，需reset---与前台强制医嘱类型不符的情况，由该方法最后统一处理
        if (OrderPriorContrlConfig=1) {
            s ParamArr("ReSetPriorStr")=OrderPriorStr
        }
        */
    }
    if (OrderPriorContrlConfig= 1) {
        if (OrderPriorRowid="") {
            s OrderPriorRowid=$P(PageDefaultOrderPriorStr,"^",1)
            s OrderPriorStr=$P(PageDefaultOrderPriorStr,"^",2)
        }
    } else {
        if (ParamArr("OrderDefPriorRowid")'="") {
            if ##Class(web.DHCDocOrderCommon).CheckPriorAllowRange(EpisodeID,ParamArr("OrderDefPriorRowid"),OrderARCIMRowid,HOSPID,CurLogonDep,"","","",1)>0{
                s ParamArr("OrderDefPriorRowid")=""
            }
        }
        //如果医嘱项上没有维护默认频次
        if (OrderPriorRowid= "") {
            //常用用法的医嘱类型
            if (ParamArr("OrderDefPriorRowid")'=""){
                s ParamArr("OrderPriorRowid")=ParamArr("OrderDefPriorRowid")
            }elseif (RowDataArr("OrderPriorRowid")'=""){
                //取前台行上的默认级别
                //注意：RowDataArr("OrderPriorRowid")是前台计算值，其规则可参考前台js中的GetDefaultOrderPrior方法
                s ParamArr("OrderPriorRowid")=RowDataArr("OrderPriorRowid")
            }else{
                //默认医嘱类型 
                s ParamArr("OrderPriorRowid")=GlobalDefaultOrderPriorRowid
            }
            s ParamArr("OrderPriorStr")=AdmOrderPriorStr
            s OrderPriorRowid = $$GetInitPriorRowid(.ParamArr, .ArcosArr,AdmOrderPriorStr)
        }
        s OrderPriorStr=AdmOrderPriorStr
    }
    ///护士绑定医嘱时，判断要不要跟着主医嘱走
    s LinkedMasterOrderRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderRowid"))
    s LinkedMasterOrderPriorRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderPriorRowid"))
    if (LinkedMasterOrderPriorRowid'="")&&($D(^OECPR(LinkedMasterOrderPriorRowid))){
        //s CurRowOrderPriorRowid=OrderPriorRowid //$P(PageDefaultOrderPriorStr,"^",1) //RowDataArr("OrderPriorRowid")
        //还是优先使用医嘱优先级标签，如果直接使用OrderPriorRowid，有可能就直接取到了医嘱项上维护的默认优先级，导致补录出来的医嘱无法切换优先级
        //s CurRowOrderPriorRowid=$P(PageDefaultOrderPriorStr,"^",1) //RowDataArr("OrderPriorRowid")
        //tanjishan 直接取上方根据优先级顺序计算好的医嘱类型
        if ($G(OrderPriorRowid)'=""){
            s CurRowOrderPriorRowid=OrderPriorRowid
        }else{
            s CurRowOrderPriorRowid=$P(PageDefaultOrderPriorStr,"^",1)
        }
        
        s NurseLinkFlag=##Class(web.DHCOEOrdItem).CheckNurseLinkFlag(LinkedMasterOrderRowid,CurRowOrderPriorRowid)
        if (NurseLinkFlag="1"){ //不满足绑定条件
            //护士补录医嘱，医嘱类型默认取主医嘱类型
            s ParamArr("OrderPriorRowid")=LinkedMasterOrderPriorRowid
            s ParamArr("OrderPriorStr")=AdmOrderPriorStr
            if ##class(appcom.OEOrdItem).ISLongOrderPrior(LinkedMasterOrderPriorRowid){
                s LongOrderPriorRowid=$O(^OECPR(0,"Code","S",0))
                s OrderPriorRowid = LongOrderPriorRowid
                if (OrderPriorContrlConfig=1) {
					s LongOrderPrior=##class(User.OECPriority).GetTranByDesc("OECPRDesc",$p($g(^OECPR(LongOrderPriorRowid)),"^",2),langid)
                    s OrderPriorStr = LongOrderPriorRowid_":"_LongOrderPrior
                    s ParamArr("ReSetPriorStr")=OrderPriorStr
                }
            }else{
                s ShortOrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
                s OrderPriorRowid=ShortOrderPriorRowid
                if (OrderPriorContrlConfig=1) {
					s ShortOrderPrior=##class(User.OECPriority).GetTranByDesc("OECPRDesc",$p($g(^OECPR(ShortOrderPriorRowid)),"^",2),langid)
                    s OrderPriorStr=ShortOrderPriorRowid_":"_ShortOrderPrior
                    s ParamArr("ReSetPriorStr")=OrderPriorStr
                }
            }
        }else{
            s ParamArr("LinkedMasterOrderRowid")=""
            s ParamArr("LinkedMasterOrderSeqNo")=""
            s ParamArr("OrderNurseLinkOrderRowid")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderRowid"))
            s ParamArr("OrderPriorRowid")=CurRowOrderPriorRowid
        }
        s LinkedMasterOrderSttDate=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderSttDate"))
        if (LinkedMasterOrderSttDate'="") {
            s OrderDate=ParamArr("OrderDate")
            if (OrderDate'=""){
                s OrderTime=..%ZTH($p(OrderDate," ",2))
                s OrderDate=..%ZDH($p(OrderDate," ",1))
                s LinkedMasterOrderSttTime=..%ZTH($p(LinkedMasterOrderSttDate," ",2))
                s LinkedMasterOrderSttDate=..%ZDH($p(LinkedMasterOrderSttDate," ",1))
                if (LinkedMasterOrderSttDate>OrderDate)||((OrderDate=LinkedMasterOrderSttDate)&&(OrderTime<LinkedMasterOrderSttTime)){
                    s ParamArr("OrderStartDate")=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderSttDate"))
                }
            }
        }
        
    }
    //最终医嘱类型
    if (OrderPriorRowid '= "") {
        //根据皮试标志,检查医嘱类型
        s OrderPriorRowid=$$CheckOrderPriorBySkinFlag(OrderPriorRowid,.ParamArr,.BaseParamArr,.ArcosArr)
        s OrderPrior=$$GetOrderPriorByPriorStr(OrderPriorStr, OrderPriorRowid)
        s ParamArr("OrderPriorRowid")=OrderPriorRowid
        s ParamArr("OrderPrior")=OrderPrior
        s ParamArr("OrderPriorStr")=OrderPriorStr
        s SpecOrderPriorRowid=..ReSetOrderPriorRowid(ParamArr("OrderPriorRowid"),ParamArr("OrderPriorRemarksRowId"))
        s ParamArr("SpecOrderPriorRowid")=SpecOrderPriorRowid
        ;出院带药不能下的子类和管制分类控制
        s ret=##Class(web.DHCOEOrdItem).CheckPriorAllow(Adm,SpecOrderPriorRowid,OrderARCIMRowid,CurLogonDep,"",langid,1)
        if (+ret<0){
            //s OutInfo="-1^"_$P(ret,"^",2)_"^^^^^^"
            if (($p(ret,"^",3)'="")&&(PAAdmType="I")){ 
                s CallBackFunParams=$p(ret,"^",2)
                s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
                s ParamArr("OrderPriorRowid")=$p(ret,"^",3)
                s ParamArr("OrderPrior")=##Class(web.DHCDocOrderCommon).GetOrderPriorByID(ParamArr("OrderPriorRowid"))
				s ParamArr("OrderPrior")=##class(User.OECPriority).GetTranByDesc("OECPRDesc",ParamArr("OrderPrior"),langid)
                if (OrderPriorContrlConfig= 1) {
                    s ParamArr("ReSetPriorStr")=ParamArr("OrderPriorRowid")_":"_ParamArr("OrderPrior")
                    s ParamArr("OrderPriorStr")=ParamArr("ReSetPriorStr")
                }
                //Q CallBackFunStr
            }else{
                s OutInfo="-1^"_$P(ret,"^",2)_"^^^^^^"
            }
        }else{
            if (OrderPriorContrlConfig= 1) {
				s ParamArr("OrderPrior")=##class(User.OECPriority).GetTranByDesc("OECPRDesc",ParamArr("OrderPrior"),langid)
                s ParamArr("ReSetPriorStr")=ParamArr("OrderPriorRowid")_":"_ParamArr("OrderPrior")
                s ParamArr("OrderPriorStr")=ParamArr("ReSetPriorStr")
            }
            if PAAdmType="I"{
                s PriorCheckRet=##Class(DHCDoc.DHCDocConfig.ItemPrior).CheckItemPriorAllow(OrderARCIMRowid,OrderPriorRowid,HOSPID,.TipMsg,langid)
                if PriorCheckRet=0{
                    s CallBackFunParams=ArcimDesc_" "_TipMsg
                    s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
                }
            }
        }
    }else{
        s OutInfo="-1^"_..%Translate("oeorder.oplistcustom.new.csp","系统错误，无法确定医嘱类型",langid)_"^^^^^"
    }
    ;医生开出院医嘱后,不允许护士开长期医嘱
    s PAADMMedDischarged=##class(web.DHCDocOrderCommon).GetIsMidDischarged(Adm)
    if ((PAADMMedDischarged=1)||(PAADMMedDischarged=2))&&(ParamArr("OrderPriorRowid")=$O(^OECPR(0,"Code","S",0))){
        s ShortOrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
        s OrderPriorRowid=ShortOrderPriorRowid
        //s OrderPriorStr=ShortOrderPriorRowid_":"_"临时医嘱"
        //s ParamArr("ReSetPriorStr")=OrderPriorStr
    }
    //长期医嘱不能选择皮试用法
    s LongPriorFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid)
    if (LongPriorFlag="1"){
        s OrderInstrRowid=ParamArr("OrderInstrRowid")
        ;皮试用法
        s SkinTestInstr=..%GetConfig("SkinTestInstr",HOSPID)
        if SkinTestInstr'="" s SkinTestInstr="^"_SkinTestInstr_"^"
        if (SkinTestInstr'="")&&(SkinTestInstr[("^"_OrderInstrRowid_"^")){
            s ParamArr("OrderInstr")=""
            s ParamArr("OrderInstrRowid")=""
        }
    }
    if ($O(^OECPR(0,"Code","NORM",0))'=OrderPriorRowid){
        s ParamArr("Urgent")="N"
    }elseif '$D(ArcosArr("Urgent")){
        s ParamArr("Urgent")=ARCIMDefSensitive
    }
    
    
    if (OrderPriorContrlConfig=1){
        if ($P(PageDefaultOrderPriorStr,"^",1))'=$G(ParamArr("OrderPriorRowid")){
            s SpecOrderPrior=##Class(web.DHCDocOrderCommon).GetOrderPriorByID($G(ParamArr("OrderPriorRowid")))
						s SpecOrderPrior=##class(User.OECPriority).GetTranByDesc("OECPRDesc",SpecOrderPrior,langid)
            s ParamArr("ReSetPriorStr")=ParamArr("OrderPriorRowid")_":"_SpecOrderPrior
        }
    }
    /*
    s ArcosArr("OrderInstr")=""
            s ArcosArr("OrderInstrRowid")=""
    */
    
    q OutInfo
GetOrderPriorByPriorStr(OrderPriorStr, OrderPriorRowid)
    n (OrderPriorStr, OrderPriorRowid)
    s OrderPriorDesc=""
    for i=1:1:$L(OrderPriorStr,";") {
        s OneOrderPriorStr=$p(OrderPriorStr,";",i)
        if (OneOrderPriorStr'[":"){continue}
        if (OrderPriorRowid=$P(OneOrderPriorStr,":",1)){
            s OrderPriorDesc=$P(OneOrderPriorStr,":",2)
            q
        }
    }
    if ((OrderPriorDesc="")&&(OrderPriorRowid'="")){
        s OrderPriorDesc=$P(^OECPR(OrderPriorRowid),"^",2)
        }
    q OrderPriorDesc

CheckOrderPriorBySkinFlag(OrderPriorRowid,ParamArr,BaseParamArr,ArcosArr)
    n (OrderPriorRowid,ParamArr,BaseParamArr,ArcosArr)
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
    s OrderPriorContrlConfig=BaseParamArr("OrderPriorContrlConfig")
    s BillTypeID=$p($g(^PAADM(EpisodeID,1)),"^",7)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s OrderSkinTest=$G(ParamArr("OrderSkinTest"))
    ;皮试用法
    s SkinTestInstr=..%GetConfig("SkinTestInstr",CurLogonHosp)
    if (ParamArr("GuideSkinInfo")=""){
        q OrderPriorRowid
    }
    
    if ((PAAdmType'="I")){
        q OrderPriorRowid
    }
    //根据配置和页面是否强制医嘱类型,来决定是否切换到临时
    s OldPriorRowid = OrderPriorRowid
    s OldPriorCode=""
    s:OldPriorRowid'="" OldPriorCode=$P(^OECPR(OldPriorRowid),"^",1)
    ;皮试医嘱类型控制为临时
    s CFSkinTestPriorShort=..%GetConfig("SkinTestPriorShort",CurLogonHosp)
    if (CFSkinTestPriorShort=1) { 
        if (OldPriorCode="S"){
            //医嘱类型强制模式--该配置为强制配置，与界面类型模式无关 tanjishan20200420
            //if (OrderPriorContrlConfig'= 1) {
                s ShortOrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
                q ShortOrderPriorRowid
            //}
        }
    }
    q OrderPriorRowid
GetInitPriorRowid(ParamArr,ArcosArr,OrderPriorStr)
    n (ParamArr,ArcosArr,OrderPriorStr)
    s OrderType=ParamArr("OrderType")
    //当前添加行的默认医嘱类型
    s OrderPriorRowid = ParamArr("OrderPriorRowid")
    s OrderDefPriorRowid=$G(ParamArr("OrderDefPriorRowid"))
    if (OrderPriorStr = "") q OrderPriorRowid
    //医嘱类型控制为强制改变,则不初始化医嘱类型
    //if (GlobalObj.OrderPriorContrlConfig==1) q OrderPriorRowid;

    //非药品没有长期医嘱?如果是非药品就用这个医嘱项默认类型
    k TempOrderPriorAry
    for i=1:1:$L(OrderPriorStr,";") {
        s OneOrderPrior=$P(OrderPriorStr,";",i)
        if (OneOrderPrior=""){
            continue
        }
        s TempOrderPriorAry($P(OneOrderPrior,":",1))=""
    }
    if (OrderType'="R")&&(OrderDefPriorRowid'=""){
        if $D(TempOrderPriorAry(OrderDefPriorRowid)) {
            s OrderPriorRowid = OrderDefPriorRowid
        }
    }
    //如果是复制医嘱或开医嘱套的就优先取传入的医嘱类型,按门诊,住院区分
    if $D(ArcosArr)&&($G(ArcosArr("SpecOrderPriorRowid"))'="") {
        if $D(TempOrderPriorAry(ArcosArr("SpecOrderPriorRowid"))) {
            s OrderPriorRowid = ArcosArr("SpecOrderPriorRowid")
        }
    }
    //如果是st医嘱就改为临时医嘱
    s OrderPriorCode=""
    s:OrderPriorRowid'="" OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s STFreqRowid=$O(^PHCFR(0,"Desc1","ST",0))
    s ONCEFreqRowid=$O(^PHCFR(0,"Code","ONCE",0))
    s ShortOrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
    if ((OrderPriorCode="S") && ((ParamArr("OrderFreqRowid")=STFreqRowid)||(ParamArr("OrderFreqRowid")=ONCEFreqRowid))) {
        if $D(TempOrderPriorAry(ShortOrderPriorRowid)) {
            s OrderPriorRowid=ShortOrderPriorRowid
        }
    }
    q OrderPriorRowid
SetOrderAction(ParamArr,BaseParamArr,ArcosArr,RowDataArr)
    n (ParamArr,BaseParamArr,ArcosArr,RowDataArr)
    s OrderPriorRowid = $G(ParamArr("SpecOrderPriorRowid"))
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s OrderSkinTest=ParamArr("OrderSkinTest")
    s OrderHiddenPara=ParamArr("OrderHiddenPara")
    s ItemDefaultRowId=$G(BaseParamArr("ItemDefaultRowId"))
    s ITMRowId=$G(BaseParamArr("ITMRowId"))
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$P(SessionStr,"^",4)
	s langid=$P(SessionStr,"^",6)
    s (OrderActionRowid,OrderAction) = ""
    s NeedSkinTestINCI=$P(OrderHiddenPara,$C(1),8)
    if ($d(ArcosArr("OrderActionRowid")))&&($g(ArcosArr("OrderActionRowid"))'="NULL") {
        s OrderAction=$g(ArcosArr("OrderAction"))
        s OrderActionRowid=$g(ArcosArr("OrderActionRowid"))
        s OrderSkinTest=$g(ArcosArr("OrderSkinTest"))
        s OrderActionCode=""
        if (OrderActionRowid'=""){
            s OrderActionCode=$p($g(^OEC("ACT",OrderActionRowid)),"^",1)
        }
        if ((OrderActionCode="YY")||(OrderActionCode="PSJ")||((NeedSkinTestINCI="Y")&&(OrderActionCode="")))&&(OrderSkinTest'="Y") s OrderSkinTest="Y"
    }else{
        s OrderActionJSON=##Class(web.DHCDocOrderCommon).GetOrderAction("JSON",langid)
        for i=1:1:$L(OrderActionJSON,";") {
            s OneActionStr=$P(OrderActionJSON,";",i)
            if (($P(OneActionStr,":",1)=ParamArr("ItemDefSkinAction"))||($P(OneActionStr,":",1)=ParamArr("skintestyy"))) { //ParamArr("skintestyy")
                s OrderActionRowid=$P(OneActionStr,":",1)
                s OrderAction=$P(OneActionStr,":",2)
                q
            }
        }
        s OrderActionCode=""
        if (OrderActionRowid'=""){
            s OrderActionCode=$p($g(^OEC("ACT",OrderActionRowid)),"^",1)
        }
        if ((OrderActionCode="YY")||(OrderActionCode="PSJ")||((NeedSkinTestINCI="Y")&&(OrderActionCode="")))&&(OrderSkinTest'="Y") s OrderSkinTest="Y"
    }
    s PriorFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid)
    ;皮试医嘱类型控制为临时
    s CFSkinTestPriorShort=..%GetConfig("SkinTestPriorShort",CurLogonHosp)
    if (CFSkinTestPriorShort=1) {
        if (PriorFlag="1"){
            if (OrderActionRowid="1"){
                s OrderActionRowid=""
                s OrderAction=""
            }
            s OrderSkinTest="N"
        }
    }
    s OrderActionCode=""
    if (OrderActionRowid'=""){
        s OrderActionCode=$p($g(^OEC("ACT",OrderActionRowid)),"^",1)
    }
    //只有备注是原液或空或皮试剂可以置皮试标志
    if (OrderActionCode'="YY")&&(OrderActionCode'="PSJ")&&(OrderActionCode'=""){
        s OrderSkinTest="N"
    }
    //配置了“门诊皮试用原液”或“住院皮试用原液”,皮试备注不能为皮试剂
    if (ParamArr("skintestyy")="1") && (OrderActionCode="PSJ") && (OrderSkinTest="Y"){
        s OrderActionRowid="",OrderAction=""
    }
    ;皮试用法，皮试标志、皮试备注为空且不可编辑
    s OrderInstrRowid=ParamArr("OrderInstrRowid")
    s SkinTestInstr=..%GetConfig("SkinTestInstr",CurLogonHosp)
    if SkinTestInstr'="" s SkinTestInstr="^"_SkinTestInstr_"^"
    if (SkinTestInstr'="")&&(SkinTestInstr[("^"_OrderInstrRowid_"^")){
        s OrderActionRowid="",OrderAction=""
        //仅当该药品属于关联的皮试用药且需置皮试结果时才置Y，其他都是N，这个会在GuideAllergy计算，这里不再处理
        //此处要防止用户维护了常用用法为皮试，但是却不勾选皮试标志--（如果该药品不需要置皮试，为什么单独维护皮试用法）
        if (ItemDefaultRowId'="")&&(ITMRowId=""){
            s OrderSkinTest="Y"
        }
    }
    /*
    //医嘱录入行上选择的皮试备注,只有脱敏才起作用且优先级最高
    s RowOrderActionRowid=$g(RowDataArr("OrderActionRowid"))
    if (RowOrderActionRowid'=""){
        s RowOrderActionCode=$p($g(^OEC("ACT",RowOrderActionRowid)),"^",1)
        i RowOrderActionCode="TM" {
            s OrderSkinTest="N",OrderActionRowid=RowOrderActionRowid,OrderAction=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
        }
    }
    */
    i OrderSkinTest="NULL" s OrderSkinTest="N"
    s ParamArr("OrderActionRowid")=OrderActionRowid
    s ParamArr("OrderAction")=OrderAction
    s ParamArr("OrderSkinTest")=OrderSkinTest
    q
SetBaseDoseQty(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s InciRowid = $G(ParamArr("InciRowid"))
    s OrderPriorRowid = $G(ParamArr("SpecOrderPriorRowid"))
    s OrderPackQty = $G(ParamArr("OrderPackQty"))
    s idoseqtystr = $G(ParamArr("idoseqtystr"))
    s OrderDrugFormRowid = $G(ParamArr("OrderDrugFormRowid"))
    s OrderFreqFactor = $G(ParamArr("OrderFreqFactor"))
    s OrderDurFactor = $G(ParamArr("OrderDurFactor"))
    s OrderConFac = $G(ParamArr("OrderConFac"))
    s ParamArr("BaseDoseQty")=1
    s ParamArr("Qty")=1
    s SpecOrderPriorRowid=$G(ParamArr("SpecOrderPriorRowid"))
    s OrderPriorCode=""
    s:OrderPriorRowid'="" OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s OrderRecDepRowid=$G(ParamArr("OrderRecDepRowid"))
    
    //如果为非库存项,将不会进入这个判断
    if (InciRowid '= "") {
        ;取药和出院带药默认按整包装开
        s CFOutAndOneDefaultPackQty=##Class(PHA.FACE.OUT.Com).GetIncilInPhUom(OrderRecDepRowid, InciRowid).outPhPack
        s CFOutAndOneDefaultPackQty=$CASE(CFOutAndOneDefaultPackQty,"":..%GetConfig("OutAndOneDefaultPackQty",HOSPID),"N":1,"Y":0,:1)
        //根据设置取药和出院带药默认按整包装开
        if (((OrderPriorCode="OUT")||(OrderPriorCode="ONE")) && (CFOutAndOneDefaultPackQty=1)){
            s OrderPackQty = 1
        }
        s BaseDoseQty = 1
        if (OrderPackQty '= "") {
            s Qty = (+OrderConFac)*(+OrderPackQty)
        } else {
            s DefaultDoseQty = ParamArr("OrderDoseQty")
            s DefaultDoseUOMRowid = ParamArr("OrderDoseUOMRowid")
            if (DefaultDoseUOMRowid '= "") {
                s BaseDoseQty = ##Class(web.DHCDocOrderEntry).CalDose(DefaultDoseUOMRowid, OrderDrugFormRowid, DefaultDoseQty)
                if (BaseDoseQty="") s BaseDoseQty = 1
            } else {
                s BaseDoseQty = 1
            }
            s Qty = (+OrderFreqFactor) * (+OrderDurFactor) * (+BaseDoseQty)
        }
        s ParamArr("BaseDoseQty")=BaseDoseQty
        s ParamArr("Qty")=Qty
    }
    q
SetBaseDefaultInfo(ParamArr,RowDataArr,BaseParamArr,CallBackFunStr,ArcosArr)
    n (ParamArr,RowDataArr,BaseParamArr,CallBackFunStr,ArcosArr)
    s Adm=BaseParamArr("Adm")
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=BaseParamArr("SessionStr")
    s CurLogonDep=$p(SessionStr,"^",3)
    s CurLogonHosp=$P(SessionStr,"^",4)
    s USERID=$P(SessionStr,"^",1)
    s CareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(USERID)
    //治疗申请单RowID
    s DCAInfoStr=$G(BaseParamArr("DCAInfoStr"))
    s DCAStartDateStr=$p(DCAInfoStr,$c(3),5)
    s DCAEndDateStr=$p(DCAInfoStr,$c(3),6)
    ;获取病人当前出院状态
    s CurrentDischargeStatus=##class(web.DHCDischargeHistory).GetCurrentDischargeStatus(Adm)
    ;获取出院日期和时间
    if CareProvType="DOCTOR"{
        s DischargeDateTime=##class(web.DHCDocOrderCommon).GetMidDischargedDateTime(EpisodeID)   
    }else{
        s DischargeDateTime=##class(web.DHCDocInterfaceMethod).DHCDocHisInterface("doc.doc.GetDischargeDateTime",EpisodeID)
    }
    s DischargeDate=$p(DischargeDateTime,"^",1)
    s DischargeTime=$p(DischargeDateTime,"^",2)
    ;本科室修改医嘱开始日期时间权限
     s ModifySttDateTimeAuthority=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(CurLogonDep,9)
     ;本科室修改开医嘱日期时间权限
     s ModifyDateTimeAuthority=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(CurLogonDep,25)
     s ARCIMRowid=$G(ParamArr("OrderARCIMRowid"))
    ;默认数据 
    s idoseqtystr=ParamArr("idoseqtystr")
    if (idoseqtystr'= ""){
        s defaultFind=0
        for i=1:1:$L(idoseqtystr,$C(2)){
            s ArrData=$P(idoseqtystr,$C(2),i)
            continue:(ArrData="")
            s defaultFlag=$P(ArrData,$C(1),4)
            if defaultFlag="Y"{
                s defaultFind=1
                s ParamArr("OrderDoseQty")=$P(ArrData,$C(1),1)
                s ParamArr("OrderDoseUOM")=$P(ArrData,$C(1),2)
                s ParamArr("OrderDoseUOMRowid")=$P(ArrData,$C(1),3)
            }
        }
        if 'defaultFind{
            s ArrData = $P(idoseqtystr,$C(2),1)
            s ParamArr("OrderDoseQty")=$P(ArrData,$C(1),1)
            s ParamArr("OrderDoseUOM")=$P(ArrData,$C(1),2)
            s ParamArr("OrderDoseUOMRowid")=$P(ArrData,$C(1),3)
        }
    }
    s DefaultSpecRowid = ""
    s DefaultSpecDesc = ""
    s OrderLabSpec=ParamArr("OrderLabSpec")
    s ParaItemSpecCode=$G(ArcosArr("ParaItemSpecCode"))
    if (OrderLabSpec '= "") {
        if (ParaItemSpecCode'=""){
            for i=1:1:$L(OrderLabSpec,$C(2)){
                s ArrData=$p(OrderLabSpec,$C(2),i)
                if ($p(ArrData,$C(3),1)=ParaItemSpecCode){
                    s DefaultSpecRowid = $p(ArrData,$C(3),1)
                    s DefaultSpecDesc = $p(ArrData,$C(3),2)
                    q
                }
            }
        }
        if (DefaultSpecRowid=""){
            for i=1:1:$L(OrderLabSpec,$C(2)){
                s ArrData=$p(OrderLabSpec,$C(2),i)
                if ($P(ArrData,$C(3),5)= "Y") {
                    s DefaultSpecRowid = $P(ArrData,$C(3),1)
                    s DefaultSpecDesc = $P(ArrData,$C(3),2)
                    q
                }
            }
            if (DefaultSpecRowid=""){
                s OrderLabSpec = ""_$C(3)_" "_$C(3)_" "_$C(3)_" "_$C(3)_" "_$C(2)_OrderLabSpec
            }
        }
    }
    //获取标本采集部位
    s ParamArr("OrderLabSpecCollectionSite")=""
    s ParamArr("OrderLabSpecCollectionSiteRowid")=""
    s ParamArr("OrderLabSpecCollectionSiteStr")=""
    if (DefaultSpecRowid'="") {
        s excode=##class(web.DHCDocOrderCommon).GetExCode(ARCIMRowid)
        s HospitalCode=##class(web.DHCDocOrderCommon).GetCurrentSYSHospitalCode(CurLogonHosp)
        s OrderLabSpecCollectionSiteStr=##Class(DHCLIS.DHCCommon).GetTestSetSpecimenSite(excode,DefaultSpecRowid,HospitalCode)
        s ParamArr("OrderLabSpecCollectionSiteStr")=OrderLabSpecCollectionSiteStr
    }
    s ParamArr("OrderLabSpec")=DefaultSpecDesc
    s ParamArr("OrderLabSpecRowid")=DefaultSpecRowid
    s ParamArr("OrderLabSpecStr")=OrderLabSpec
    //"费用调整"的医嘱开始日期时间、下医嘱日期时间默认为出院时间(提前1秒)，且都可以修改但不允许大于出院日期时间
    s StartDateEnbale = 1,OrderDateEnable =1 
    //if (CurrentDischargeStatus="B") {
    if (DischargeDate'="")&&(..%ZDH(DischargeDate)<=..%SysDate()) {
        s LeadOrdTime=..%GetConfig("LeadOrdTime",CurLogonHosp)
        if LeadOrdTime>0{
            s LeadOrdTime=LeadOrdTime*$CASE(..%GetConfig("LeadOrdTimeMinute",CurLogonHosp),1:60,:1)
        }else{
            s LeadOrdTime=1
        }
        s NewOrdDate=DischargeDate
        s NewOrdTime=DischargeTime-LeadOrdTime
        while(NewOrdTime<0){
            s NewOrdTime=$ZTH("23:59:59")+NewOrdTime+1
            s NewOrdDate=NewOrdDate-1
        }
        s NewOrdDate=..%ZD(NewOrdDate)
        s NewOrdTime=..%ZT(NewOrdTime,1)
        s ParamArr("OrderStartDate")=NewOrdDate_" "_NewOrdTime
        s ParamArr("OrderDate")=NewOrdDate_" "_NewOrdTime
    } else {
        s ParamArr("OrderDate")=$G(RowDataArr("OrderDate"))
        s ParamArr("OrderStartDate")=RowDataArr("OrderStartDate")
        s ARCIMExtInfo=##class(DHCDoc.DHCDocConfig.ARCIMExt).getARCIMConfig(ARCIMRowid)
		s StopAfterLongOrder=$P(ARCIMExtInfo,"^",3)
        s DefSttDateDay=$p(ARCIMExtInfo,"^",4)
        s DefSttTime=$p(ARCIMExtInfo,"^",5)
        if ((+DefSttDateDay > 0)&&(StopAfterLongOrder =1)) {
            if (DefSttTime="") s DefSttTime=$p(ParamArr("OrderStartDate")," ",2)
            s ParamArr("OrderStartDate")=..%ZD(+$h+(+DefSttDateDay))_" "_DefSttTime
        }
        if (DCAStartDateStr'=""){
            s ParamArr("OrderStartDate")=DCAStartDateStr
            s OrderDate=ParamArr("OrderDate")
            s OrderTime=..%ZTH($p(OrderDate," ",2))
            s OrderDate=..%ZDH($p(OrderDate," ",1))
            s DCAOrderSttTime=..%ZTH($p(DCAStartDateStr," ",2))
            s DCAOrderSttDate=..%ZDH($p(DCAStartDateStr," ",1))
            if (DCAOrderSttDate<OrderDate)||((OrderDate=DCAOrderSttDate)&&(DCAOrderSttTime<OrderTime)){
                s ParamArr("OrderDate")=DCAStartDateStr
            }
        }
    }
    if (..CheckDateTimeModifyFlag(ModifySttDateTimeAuthority,ParamArr("SttIsCanCrossDay"))=0){
        s StartDateEnbale = 0
    }
    if (..CheckDateTimeModifyFlag(ModifyDateTimeAuthority,ParamArr("OrdDateIsCanCrossDay"))=0){
        s OrderDateEnable = 0
    }
    
    s CallBackFunParams=StartDateEnbale
    s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetStartDateEnbale",CallBackFunParams)
    s CallBackFunParams=OrderDateEnable
    s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetOrdDateEnbale",CallBackFunParams)
    
    s ParamArr("OrderEndDate")=$G(RowDataArr("OrderEndDate"))
    if (DCAEndDateStr'=""){
        s ParamArr("OrderEndDate")=DCAEndDateStr
    }
    ;如果界面有选择附加说明 用界面附加说明
    if '$D(ArcosArr("OrderPriorRemarksRowId"))&&($G(RowDataArr("OrderPriorRemarksRowId"))'=""){
        s ParamArr("OrderPriorRemarksRowId")=RowDataArr("OrderPriorRemarksRowId")
        s ParamArr("OrderPriorRemarks")=RowDataArr("OrderPriorRemarks")
    }
    q
SetDefautBillType(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    //先置默认值
    s ArcimDesc=ParamArr("OrderName")
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s OrderItemCatRowid=ParamArr("OrderItemCatRowid")
    s BillTypeID=$p($g(^PAADM(EpisodeID,1)),"^",7)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s PrescriptTypeStr=##class(web.DHCDocOrderCommon).GetPrescriptTypeInfo(BillTypeID,PAAdmType,langid,SessionStr)
    s DefaultOrderBillTypeRowid=""
    s DefaultPrescType=""
    s DefaultPrescTypeStr=$P(PrescriptTypeStr,"^",1)
    s PrescriptTypeStr=$P(PrescriptTypeStr,"^",1)
    i DefaultPrescTypeStr'="" s PrescriptTypeStr=DefaultPrescTypeStr
    for i=1:1:$L(PrescriptTypeStr,";"){
        s OnePrescriptType=$P(PrescriptTypeStr,";",i)
        s presctypebilltypeid=$P(OnePrescriptType,":",1)
        if (presctypebilltypeid=BaseParamArr("OrderBillTypeRowid")){
            s DefaultOrderBillTypeRowid=presctypebilltypeid
            s DefaultPrescType=$P(OnePrescriptType,":",2)
        }
    }
    if (DefaultOrderBillTypeRowid=""){
        s DefaultOrderBillTypeRowid=BillTypeID
        s DefaultPrescType=$P($G(^PAC("ADMREA",+DefaultOrderBillTypeRowid)),"^",2)
    }
    s ParamArr("OrderBillType")=DefaultPrescType
    s ParamArr("OrderBillTypeRowid")=DefaultOrderBillTypeRowid
    //判断默认值是否可用
    if (PAAdmType="I"){
        q OutInfo
    }
    k BillTypeArr
    s PrescriptTypes=##Class(web.DHCPAADMPrescType).GetPrescTypeByPAADM("O",BillTypeID,HOSPID)
    for i=1:1:$L(PrescriptTypes,"||") {
        s PrescriptType=$P(PrescriptTypes,"||",i)
        s BillTypeID2=$P(PrescriptType,"!",5)
        continue:BillTypeID2=""
        s SubCatIDs=$P(PrescriptType,"!",4)
        if (SubCatIDs=""){
            s BillTypeArr(BillTypeID2) = ""
        }else{
            s BillTypeArr(BillTypeID2) = "^"_SubCatIDs_"^"
        }
    }
    s PrescCheck=""
    s SubCatIDs=$G(BillTypeArr(+ParamArr("OrderBillTypeRowid")))
    if (SubCatIDs'[("^"_OrderItemCatRowid_"^"))&&(SubCatIDs'=""){
        s BillTypeID2=""
        for {
            s BillTypeID2=$O(BillTypeArr(BillTypeID2))
            q:(BillTypeID2="")
            s SubCatIDs=$G(BillTypeArr(BillTypeID2))
            if (SubCatIDs[("^"_OrderItemCatRowid_"^"))||(SubCatIDs=""){
                s PrescCheck=BillTypeID2
            }
        }
    }else{
        s PrescCheck=ParamArr("OrderBillTypeRowid")
    }
    if (PrescCheck=""){
        s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","此医嘱不符合处方类型",langid)_"^^^^^^"
    }elseif (PrescCheck'=ParamArr("OrderBillTypeRowid")){
        s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 默认费别不可以开此子类药品，将换成其他费别！",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        s ParamArr("OrderBillType")=PrescCheck
        s ParamArr("OrderBillTypeRowid")=PrescCheck
    }
    q OutInfo
ResArcosArr(ArcosArr,BaseParamArr,EPARCIMDetail)
    n (ArcosArr,BaseParamArr,EPARCIMDetail)
    s OrderType=$P(EPARCIMDetail,"^",2)
    s OrderPHPrescType=$P(EPARCIMDetail,"^",6)
    s OrderRecLocStr=$P(EPARCIMDetail,"^",10)
    s idoseqtystr=$P(EPARCIMDetail,"^",12)
    s OrderFreqRowid=$G(ArcosArr("OrderFreqRowid"))
    s OrderDoseUOMRowid=$G(ArcosArr("OrderDoseUOMRowid"))
    s OrderPackUOMRowid=$G(ArcosArr("OrderPackUOMRowid"))
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s OrderARCIMRowid=$G(BaseParamArr("OrderARCIMRowid"))
    s LogonUserID=$P(SessionStr,"^",1)
    s CurLogonDep=$p(SessionStr,"^",3)
    s HOSPID=$P(SessionStr,"^",4)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s ItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
    s UserEMVirtualtLong=##Class(web.DHCDocOrderVirtualLong).GetUserEMVirtualtLong(EpisodeID)
    //因为有可能配置过【医嘱项替换】,所以要对一些基本属性做校验-单次剂量单位、数量单位
    if (OrderDoseUOMRowid'="")&&(idoseqtystr'=""){
        s FindDoseUOMRowidFlag="N"
        for i=1:1:$L(idoseqtystr,$C(2)){
            s OneData=$P(idoseqtystr,$C(2),i)
            continue:(OneData="")
            s FormDoseUOMRowid=$P(OneData,$C(1),3)
            if (FormDoseUOMRowid=OrderDoseUOMRowid){
                s FindDoseUOMRowidFlag="Y"
            }
        }
        if (FindDoseUOMRowidFlag="N"){
            k ArcosArr("OrderDoseQty")
            k ArcosArr("OrderDoseUOM")
            k ArcosArr("OrderDoseUOMRowid")
            s OrderDoseUOMRowid=""
        }
    }
    if (OrderPackUOMRowid'=""){
        //数量单位会在SetBillUOMStr中做统一验证，即验证SpecOrderPackUOMRowid
    }
    
    
    if (OrderFreqRowid'=""){
        s ValidFlag=##Class(web.DHCDocOrderCommon).CheckDataValid("PHCFreq",EpisodeID,OrderFreqRowid,CurLogonDep)
        if (ValidFlag="0"){
            s ArcosArr("OrderFreq")=""
            s ArcosArr("OrderFreqRowid")=""
            s ArcosArr("OrderFreqFactor")=""
            s ArcosArr("OrderFreqInterval")=""
        }
    }
    s OrderInstrRowid=$G(ArcosArr("OrderInstrRowid"))
    if (OrderInstrRowid'=""){
        s ValidFlag=##Class(web.DHCDocOrderCommon).CheckDataValid("PHCInstruc",EpisodeID,OrderInstrRowid,CurLogonDep)
        if (ValidFlag="0"){
            s ArcosArr("OrderInstr")=""
            s ArcosArr("OrderInstrRowid")=""
        }
    }
    
    s SpecOrderPriorRowid=$G(ArcosArr("SpecOrderPriorRowid"))
    s SpecOrderPriorCode=""
    s:SpecOrderPriorRowid'="" SpecOrderPriorCode=$P(^OECPR(SpecOrderPriorRowid),"^",1)
    s IPDefaultDurRowId=..%GetConfig("IPDefaultDuration",HOSPID)
    s IPDefaultDur="",IPDefaultDurFactor=0
    if IPDefaultDurRowId'="" {
        s IPDefaultDur=$P($g(^PHCDU(IPDefaultDurRowId)),"^",3)
        s IPDefaultDurFactor=$P($g(^PHCDU(IPDefaultDurRowId)),"^",2)
    }
    s OrderDur=$G(ArcosArr("OrderDur"))
    //住院非出院带药医嘱，疗程默认为一天
    //tanjishan 2019-01-09 这时的医嘱类型还不确定，无法判断疗程该怎么处理
    if ((PAAdmType = "I") && (SpecOrderPriorCode '= "OUT")) {
        /*
        if (OrderType = "R") {
            s ArcosArr("OrderDur") = IPDefaultDur
            s ArcosArr("OrderDurRowid") = IPDefaultDurRowId
            s ArcosArr("OrderDurFactor") = 1
        } else {
            if (OrderPHPrescType = "4") {
                //if ((SpecOrderPriorCode '= "S") && (SpecOrderPriorCode '= "OMST")) {
                    s ArcosArr("OrderDur") = IPDefaultDur
                    s ArcosArr("OrderDurRowid") = IPDefaultDurRowId
                    s ArcosArr("OrderDurFactor") = 1
                //}
            } else {
                s ArcosArr("OrderDur") = ""
                s ArcosArr("OrderDurRowid") = ""
                s ArcosArr("OrderDurFactor") = 1
            }
        }
        */
    }
    /*
    //非药品医嘱套也可能维护了数量
    if ((OrderType'="R")&&((OrderPackQty=0)||(OrderPackQty=""))){
        if ((OrderFreqFactor="")||(OrderFreqFactor=0)) s OrderFreqFactor=1
        if ((OrderDurFactor="")||(OrderDurFactor=0)) s OrderDurFactor=1
        if (PAAdmType'="I") s OrderDurFactor=1
        s OrderPackQty=OrderDurFactor*OrderFreqFactor
    }
    */
    s ArcosArr("OrderBodyPartLabel")=$g(BaseParamArr("OrderBodyPartLabel"))
    
    if (UserEMVirtualtLong="0"){
        s ArcosArr("OrderVirtualtLong")="N"
    }
    
    
    
    if ("Y"=$G(ArcosArr("OrderVirtualtLong"))){
        s ret=##Class(web.DHCOEOrdItem).CheckVirtualtLongAllow(EpisodeID,OrderARCIMRowid,CurLogonDep)
        if (+ret'=0){
            s ArcosArr("OrderVirtualtLong")="N"
        }
    }
    
    if ($g(ArcosArr("OrderVirtualtLong"))="Y"){
        //实际此时的默认接受科室计算值不准确，暂时没发现问题
        s DefaultRecLocStr=$$GetDefaultRecLocStr(OrderRecLocStr)
        s DefaultRecLocRowid=$P(DefaultRecLocStr,"^",1)
        ;医生站设置-药房设置-临时医嘱拆分整包装发药(仅在急诊留观押金的虚拟长期模式下有效)
        s NormSplitPackQty=##Class(web.DHCDocOrderVirtualLong).GetNormSplitPackQtyFlag(EpisodeID,DefaultRecLocRowid,ItemCatDr)
        if (NormSplitPackQty=0)&&(ArcosArr("OrderPriorRemarksRowId")="")&&(OrderType="R"){
            s OrderPriorRemarksRowID="ZT"
            s OrderPriorRemarks=$CASE(OrderPriorRemarksRowID,"OM":"自备药","ZT":"嘱托","ONE":"取药医嘱",:"")
            s ArcosArr("OrderPriorRemarksRowId")=OrderPriorRemarksRowID
            s ArcosArr("OrderPriorRemarks")=OrderPriorRemarks
        }
    }
    q
InitParamArr(ParamArr,ItemOrdsArr,BaseParamArr,ArcosArr,EPARCIMDetail)
    n (ParamArr,ItemOrdsArr,BaseParamArr,ArcosArr,EPARCIMDetail)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s LogonUserID=$P(SessionStr,"^",1)
    s CurLogonHosp=$P(SessionStr,"^",4)
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s ParamArr("rowid")=$G(BaseParamArr("rowid"))
    s ParamArr("OrderARCIMRowid")=$G(BaseParamArr("OrderARCIMRowid"))
    s ParamArr("OrderDepProcNote")=$G(BaseParamArr("OrderDepProcNote"))
    s ItemExpInfo=$G(BaseParamArr("ItemExpInfo"))
    //新产品组提供的部位数据
    s OrderBodyPartLabel=$G(BaseParamArr("OrderBodyPartLabel"))
    s ParamArr("OrderBodyPartLabel")=OrderBodyPartLabel
    //治疗申请单RowID
    s DCAInfoStr=$G(BaseParamArr("DCAInfoStr"))
    s DCARowID=$p(DCAInfoStr,$c(3),1)
    s DCAFreqDispTimeStr=$p(DCAInfoStr,$c(3),4)
    s DCAPracticePreRowid=$p(DCAInfoStr,$c(3),8)
    s ParamArr("DCARowID")=DCARowID
    s ParamArr("DCAFreqDispTimeStr")=DCAFreqDispTimeStr
    //临床路径传入的执行步骤
    s OrderCPWStepItemRowId=$G(BaseParamArr("OrderCPWStepItemRowId"))
    s ParamArr("OrderCPWStepItemRowId")=OrderCPWStepItemRowId
    s CopyType=$G(BaseParamArr("CopyType"))
    s MasterSeqNo=$G(BaseParamArr("MasterSeqNo"))
    //界面点击开始关联时初始化该属性
    s ParamArr("OrderMasterSeqNo")=MasterSeqNo
    s ParamArr("OrderMasterARCIMRowid")=""
    s ParamArr("OrderName")=$P(EPARCIMDetail,"^",1)
    s ParamArr("OrderType")=$P(EPARCIMDetail,"^",2)
    s ParamArr("OrderItemCatRowid")=$P(EPARCIMDetail,"^",3)
    ;不能关联的医嘱子类
    s NotLinkItemCat=..%GetConfig("NotLinkItemCat",CurLogonHosp)
     if ("^"_NotLinkItemCat_"^")'[("^"_ParamArr("OrderItemCatRowid")_"^"){
         s ParamArr("CalSeqNo")=$G(BaseParamArr("CalSeqNo"))
    }else{
        s ParamArr("CalSeqNo")=""
    }
    if (MasterSeqNo'="")||($p(ParamArr("CalSeqNo"),".",2)'="") {
        //找到主医嘱那行数据
        s i =""
        for{
            s i=$O(ItemOrdsArr("ItemOrds",i))
            q:(i="")
            s ListSeqNo = ItemOrdsArr("ItemOrds",i,"OrderSeqNo")
            s CalSeqNo = $G(ItemOrdsArr("ItemOrds",i,"CalSeqNo"))
            continue:CalSeqNo=""
            if (MasterSeqNo=ListSeqNo)||(($p(ParamArr("CalSeqNo"),"."))=CalSeqNo){
                s ParamArr("OrderMasterARCIMRowid")=ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
                s ParamArr("OrderMasterSeqNo")=ListSeqNo
            }
        }
    }
    if ($G(ParamArr("CalSeqNo"))'="")&&($G(ParamArr("CalSeqNo"))'["."){
        s ParamArr("OrderMasterSeqNo")=""
    }
    s ParamArr("ItemRowid")=$P(EPARCIMDetail,"^",4)
    s ParamArr("InciRowid")=$P(EPARCIMDetail,"^",5)
    s ParamArr("OrderPHPrescType")=$P(EPARCIMDetail,"^",6)
    //此处的OrderRecLocStr仅作参考使用，最终会在SetCurrentRecLocStr被重置
    s ParamArr("OrderRecLocStr")=$P(EPARCIMDetail,"^",10)
    s ParamArr("idoseqtystr")=$P(EPARCIMDetail,"^",12)
    s ParamArr("realstockqty")=$P(EPARCIMDetail,"^",18)
    s ParamArr("iinsurinfo")=$P(EPARCIMDetail,"^",21)
    s ParamArr("ilimitstr")=$P(EPARCIMDetail,"^",22)
    //s ParamArr("OrderOutPriorRecLocStr")=$P(EPARCIMDetail,"^",23)
    s ParamArr("iallergy")=$P(EPARCIMDetail,"^",24)
    //s ParamArr("OrderOnePriorRecLocStr")=$P(EPARCIMDetail,"^",25)
    s ParamArr("idiagnoscatstr")=$P(EPARCIMDetail,"^",26)
    s PHCDoseStr=$P(EPARCIMDetail,"^",28)
    //s ParamArr("OrderHolidayRecLocStr")=$P(EPARCIMDetail,"^",29) //节假日接收科室串
    s OrderFreqTimeDoseStr=$P(EPARCIMDetail,"^",30)
    s OrderFreqDispTimeStr=$P(EPARCIMDetail,"^",31)
    s ItemEqualDefQty=""
    if (PHCDoseStr'=""){
        s ItemEqualDefQty=$p(PHCDoseStr,$C(1),1)
    }
    //iretPrice医嘱价格
    s iretPrice = $P(EPARCIMDetail,"^",8)
    s ParamArr("OrderPrice")=$P(iretPrice,$C(1),1)
    s ParamArr("DiscPrice")=$P(iretPrice,$C(1),2)
    s ParamArr("InsPrice")=$P(iretPrice,$C(1),3)
    s ParamArr("PatPrice")=$P(iretPrice,$C(1),4)
    //ipackqtystr医嘱数量
    s ipackqtystr = $P(EPARCIMDetail,"^",9)
    s ParamArr("OrderPackQty")=$P(ipackqtystr,$C(1),1)
    s ParamArr("OrderPackUOM")=$P(ipackqtystr,$C(1),2)
    s ParamArr("OrderPackUOMRowid")=$P(ipackqtystr,$C(1),3)
    s ParamArr("SpecOrderPackUOMRowid")=$P(ipackqtystr,$C(1),4)
    
     s ParamArr("OrderDoseQty")=""
    s ParamArr("OrderDoseUOM")=""
    s ParamArr("OrderDoseUOMRowid")=""
    //iformstr剂型
    s iformstr = $P(EPARCIMDetail,"^",11)
    s ParamArr("OrderPHForm")=$P(iformstr,$C(1),1)
    s ParamArr("OrderDrugFormRowid")=$P(iformstr,$C(1),2)
    s ParamArr("OrderConFac")=$P(iformstr,$C(1),3)
    s ParamArr("OrderPoisonRowid")=$P(iformstr,$C(1),4)
    s ParamArr("OrderPoisonCode")=$P(iformstr,$C(1),5)
    //ifrequencestr频次
    s ifrequencestr = $P(EPARCIMDetail,"^",13)
    s ParamArr("OrderFreq")=$P(ifrequencestr,$C(1),1)
    s ParamArr("OrderFreqRowid")=$P(ifrequencestr,$C(1),2)
    s ParamArr("OrderFreqFactor")=$P(ifrequencestr,$C(1),3)
    s ParamArr("OrderFreqInterval")=$P(ifrequencestr,$C(1),4)
    s ParamArr("OrderFreqDispTimeStr")=OrderFreqDispTimeStr 
    //iinstructionstr用法
    s iinstructionstr = $P(EPARCIMDetail,"^",14)
    s ParamArr("OrderInstr")=$P(iinstructionstr,$C(1),1)
    s ParamArr("OrderInstrRowid")=$P(iinstructionstr,$C(1),2)
    //idurationstr疗程
    s idurationstr = $P(EPARCIMDetail,"^",15)
    s ParamArr("OrderDur")=$P(idurationstr,$C(1),1)
    s ParamArr("OrderDurRowid")=$P(idurationstr,$C(1),2)
    s ParamArr("OrderDurFactor")=$P(idurationstr,$C(1),3)
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
		; renyx 提高常用用法在疗程中的优先级
    if (PAAdmType'="I")&&(ParamArr("OrderDurRowid")=""){
        // 门急诊需要带入上一条疗程的子类
        s OPAutoDurCat=..%GetConfig("OPAutoDurCat",CurLogonHosp)
        if (("^"_OPAutoDurCat_"^")[("^"_ParamArr("OrderItemCatRowid")_"^")){
            s PreOrderDur="",PreOrderDurRowid="",PreOrderDurFactor=""
            s i=""
            for {
                s i=$O(ItemOrdsArr("ItemOrds",i))
                q:(i="")||(PreOrderDurRowid'="")
                s OrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
                s OrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
                continue:((OrderARCIMRowid="")||(OrderItemRowid'=""))
                s PreOrderDurRowid = ItemOrdsArr("ItemOrds",i,"OrderDurRowid")
                continue:PreOrderDurRowid=""
                if (PreOrderDurRowid'=""){
                    s PreOrderDur=$P($g(^PHCDU(PreOrderDurRowid)),"^",3)
                    s PreOrderDurFactor=$P($g(^PHCDU(PreOrderDurRowid)),"^",2)
                }
            }
            if (PreOrderDurRowid'=""){
                s ParamArr("OrderDur")=PreOrderDur
                s ParamArr("OrderDurRowid")=PreOrderDurRowid
                s ParamArr("OrderDurFactor")=PreOrderDurFactor
            }
        }
    }
    //idefpriorstr医嘱优先级
    s idefpriorstr = $P(EPARCIMDetail,"^",16)
    s ParamArr("OrderDefPrior")=$P(idefpriorstr,$C(1),1)
    s ParamArr("OrderDefPriorRowid")=$P(idefpriorstr,$C(1),2)
    s ParamArr("OrderPriorRemarks")=$P(idefpriorstr,$C(1),3)
    s ParamArr("OrderPriorRemarksRowId")=$P(idefpriorstr,$C(1),4)
    //iordermsg提示信息
    s iordermsg = $P(EPARCIMDetail, "^", 17)
    s ParamArr("OrderMsg")=$P(iordermsg,$C(1),1)
    s ParamArr("OrderFile1")=$P(iordermsg,$C(1),2)
    s ParamArr("OrderFile2")=$P(iordermsg,$C(1),3)
    s ParamArr("OrderFile3")=$P(iordermsg,$C(1),4)
    //ilab检验,标本
    s ilab = $P(EPARCIMDetail,"^",19)
    s ParamArr("OrderLabSpec")=$P(ilab,$C(1),1)
    s ParamArr("OrderLabExCode")=$P(ilab,$C(1),2)
    s ParamArr("OrderLabItemActive")=$P(ilab,$C(1),3)
    //iskintest皮试
    s iskintest = $P(EPARCIMDetail, "^", 20)
    s ParamArr("OrderSkinTest")=$P(iskintest,$C(1),1)
    s ParamArr("skintestyy")=$P(iskintest,$C(1),2)
    s ParamArr("IPNeedBillQty")=$P(iskintest,$C(1),3)
    //加急标志
    s ParamArr("EmergencyFlag")=$P(iskintest,$C(1),4)
    s ParamArr("SttIsCanCrossDay")=$P(iskintest,$C(1),6)
    s ParamArr("OrdDateIsCanCrossDay")=$P(iskintest,$C(1),9)
    //
    s ParamArr("ItemDefSkinAction")=$P(iskintest,$C(1),7)
    s ParamArr("ARCIMDefSensitive")=$case($P(iskintest,$C(1),8),"Y":"Y",:"N")
    //ilimitstr医嘱控制相关
    s ilimitstr = $P(EPARCIMDetail, "^", 22)
    s ParamArr("OrderMaxDurFactor")=$P(ilimitstr,$C(1),1)
    s ParamArr("OrderMaxQty")=$P(ilimitstr,$C(1),2)
    s ParamArr("OrderAlertStockQty")=$P(ilimitstr,$C(1),3)
    s ParamArr("OrderMaxDoseQty")=$P(ilimitstr,$C(1),4)
    s ParamArr("OrderMaxDoseQtyPerDay")=$P(ilimitstr,$C(1),6)
    s ParamArr("OrderLimitDays")=$P(ilimitstr,$C(1),7)
    s ParamArr("OrderMaxDoseQtyPerOrder")=$P(ilimitstr,$C(1),8)
    s ParamArr("PHCDFCQZTFlag")= $P(ilimitstr,$C(1),9) //长期默认嘱托
    s ParamArr("PHCDFONEFlag")= $P(ilimitstr,$C(1),10) //临时默认取药
    s ParamArr("AllowOnlyOnce")=$P(ilimitstr,$C(1),11)		;一个患者只允许开一次
    s ParamArr("PHCDFCHKOMFlag")=$P(ilimitstr,$C(1),13) //附加说明默认自备
    s ParamArr("SameFreqDifferentDosesFlag")=$P(ilimitstr,$C(1),14) //同频次不同剂量医嘱标志
    s ParamArr("AdmAllowOnlyOnce")=$P(ilimitstr,$C(1),15)	;一次就诊只允许开一次
    //iother分割
    s iother=$P(EPARCIMDetail,"^",27)
    //医嘱项无效验证
    s ParamArr("OrderItemInValid")=$P(iother,$C(1),1)
    s ParamArr("OrderGenericName")=$P(iother,$C(1),2)
    s ParamArr("iSpecCheckCode")=$P(iother,$C(1),3)
    s ParamArr("AlertAuditSpecialItem")=$P(iother,$C(1),4)
    s ParamArr("ArcimCode")=$P(iother,$C(1),5)
    s ParamArr("OrderAuthInValid")=$P(iother,$C(1),6)
    s ParamArr("AllergyChildNotice")=$P(iother,$C(1),11)
    s ParamArr("ARCIMShowOEMessageFlag") = $P(iother,$C(1),12)
    //s ParamArr("OrderDepProcNote")=$P(iother,$C(1),13)
    s OrderDepProcNote=$P(iother,$C(1),13)
    if (OrderDepProcNote'="") {
        s ParamArr("OrderDepProcNote")=OrderDepProcNote
    }
    
    s ParamArr("OrderSpeedFlowRate")=$P(iother,$C(1),14)
    s ParamArr("OrderFlowRateUnitRowId")=$P(iother,$C(1),15)
    s ParamArr("OrderFlowRateUnit")=$P(iother,$C(1),16)
    
    s ParamArr("TransFlag")=$P(iother,$C(1),21)
    s ParamArr("AllowOnlyOnceRepeatFlag")=$P(iother,$C(1),22)
    s ParamArr("PHCDFCriticalFlag")=$P(iother,$C(1),24)
    s ParamArr("AuthInValidMsg")=$P(iother,$C(1),25)
    s ASCheckStr = $P(iother, $C(1), 7)
    
    //医嘱性别年龄验证
    s ParamArr("ASCheckFlag")=$P(ASCheckStr,$C(2),1)
    s ParamArr("ASCheckSex")=$P(ASCheckStr,$C(2),2)
    s ParamArr("ASCheckAgeRange")=$P(ASCheckStr,$C(2),3)
    s ParamArr("PilotCatFlag")=$P(iother,$C(1),8)
    s ParamArr("IsHourItem")=$P(iother,$C(1),9)
    s ParamArr("CheckArcimTypeStr")=$P(iother,$C(1),10)
    //s ParamArr("DIDExceedReasonDR")=$P(iother,$C(1),17)	;超量原因
    s ExceedReasonID=$P(iother,$C(1),17)
    s ParamArr("ExceedReasonID")=ExceedReasonID
    if (ExceedReasonID'=""){
        s ExceedReason=$p($G(^DHCDocExceedReason(ExceedReasonID)),"^",2)
        s ParamArr("ExceedReason")=ExceedReason
    }else{
        s ParamArr("ExceedReason")=""
    }
    s ParamArr("MidDischargedFlag")=$P(iother,$C(1),18)
    s ParamArr("IncItmHighValueFlag")=$P(iother,$C(1),19)
    
    s ParamArr("OrderEndDate")=""
    s ParamArr("OrderDate")=""
    s ParamArr("OrderMaterialBarcode")=$G(BaseParamArr("MaterialBarcode"))
    s ParamArr("OrderMaterialBarcodeHiden")=$G(BaseParamArr("MaterialBarcode"))
    
    
    
    s ParamArr("OrderStage")=""
    s ParamArr("OrderStageCode")=""
        
    s ParamArr("LinkedMasterOrderRowid")=""
    s ParamArr("LinkedMasterOrderSeqNo")=""
    s ParamArr("OrderNurseLinkOrderRowid")=""
    
    s ParamArr("OrderInsurSignSymptomCode")=""
    s ParamArr("OrderInsurSignSymptom")=""
    //s ParamArr("OrderPriorRemarksRowId")=""
    //s ParamArr("OrderUsableDays")=""
    
    s ParamArr("OrderBodyPartID")=""
    s ParamArr("OrderBodyPart")=""
    //s ParamArr("ExceedReasonID")=""
    //s ParamArr("ExceedReason")=""
    s ParamArr("OrderStageCode")=""
    s ParamArr("OrderStage")=""
    s ParamArr("ReSetPriorStr")=""
    s ParamArr("OrderInsurCatRowId")=""
    s ParamArr("AnaesthesiaID")=""
    s ParamArr("OrderOperationStr")=""
    s ParamArr("OrderOperation")=""
    s ParamArr("OrderOperationCode")=""
    s ParamArr("OrderFreqTimeDoseStr")=OrderFreqTimeDoseStr
    s ParamArr("GuideSkinInfo")=""
    s NeedSkinTestINCI= $P(iskintest, $c(1), 5)
    //8.4去掉了皮试标识，没有维护过皮试引导的任何医嘱都可以手工修改皮试标志
    s NeedSkinTestINCI="N"
    s NewInciRowid = ##Class(web.DHCDocOrderEntry).GetINCI(+ParamArr("OrderARCIMRowid"))
    s StopAfterLongOrderFlag=$P(iother, $C(1), 23)
    //按登录科室取接收科室
    s LogonDep=$G(BaseParamArr("LogonDep"))
    if (LogonDep'="") s FindRecLocByLogonLocFlag=1
    else  s FindRecLocByLogonLocFlag=0
    s OrderOpenForAllHosp=$G(BaseParamArr("OrderOpenForAllHosp"))
    s (RequireNote)="N"
    s DARCIMRowid=$o(^DHCItmMast("0","ARCIM",ParamArr("OrderARCIMRowid"),""))
    if (DARCIMRowid'=""){
        s RequireNote=$P(^DHCItmMast(DARCIMRowid),"^",5)
    }
    s OrderPracticePreRowid="" //实习医嘱表ID
    s OrderFirstDayTimesEditable="Y"
    s:DCAPracticePreRowid'="" OrderPracticePreRowid=DCAPracticePreRowid
    ;医生站设置-药房设置-临时医嘱拆分整包装发药(仅在急诊留观押金的虚拟长期模式下有效),可拆分发药的接受科室串
    s NormSplitPackQtyPHRecLocList=##Class(web.DHCDocOrderVirtualLong).GetNormSplitPackQtyPHRecLocList(EpisodeID,ParamArr("OrderItemCatRowid"))
    ;有多个可拆分发药科室串以^分割，实习医生开立审核后会和实习医嘱表DHC_PracticeDocPreOrder的系统分割符冲突
    s NormSplitPackQtyPHRecLocList=$replace(NormSplitPackQtyPHRecLocList,"^","!")
    s InputObj={"ctLocId":($P(SessionStr,"^",3)),"arcim":(ParamArr("OrderARCIMRowid")),"hospId":(CurLogonHosp)}
	s NotLimitDeposit=##class(BILL.Interface.Inside.Service).IIsCtrlArrears(InputObj.%ToJSON())
    ;重要：OrderHiddenPara串内不能含有^
    s OrderHiddenPara =ParamArr("skintestyy")_$C(1)_ParamArr("IPNeedBillQty")
    _$C(1)_ParamArr("OrderItemCatRowid")_$C(1)_ParamArr("OrderMaxDoseQty")
    _$C(1)_ParamArr("OrderMaxDoseQtyPerDay")_$C(1)_ParamArr("OrderLimitDays")
    _$C(1)_ParamArr("OrderMaxDoseQtyPerOrder")_$C(1)_NeedSkinTestINCI
    _$C(1)_ParamArr("SttIsCanCrossDay")_$C(1)_ParamArr("IncItmHighValueFlag")	//9-10
    _$C(1)_NewInciRowid_$C(1)_ParamArr("ArcimCode")		//11-12
    _$C(1)_ParamArr("PHCDFCQZTFlag")_$C(1)_ParamArr("PHCDFONEFlag")
    _$C(1)_StopAfterLongOrderFlag_$C(1)_ParamArr("PHCDFCHKOMFlag")
    _$C(1)_ItemEqualDefQty_$C(1)_ParamArr("PHCDFCriticalFlag")
    _$C(1)_FindRecLocByLogonLocFlag_$C(1)_ParamArr("SameFreqDifferentDosesFlag")	//19-20
    _$C(1)_ParamArr("DCARowID")_$C(1)_RequireNote
    _$C(1)_ParamArr("OrdDateIsCanCrossDay")_$C(1)_OrderPracticePreRowid
    _$C(1)_NormSplitPackQtyPHRecLocList_$C(1)_ParamArr("EmergencyFlag")
    _$C(1)_ParamArr("ARCIMDefSensitive")_$C(1)_$G(ArcosArr("PGIID")) //27-28
    _$C(1)_OrderOpenForAllHosp_$c(1)_OrderFirstDayTimesEditable //29-30
    _$C(1)_NotLimitDeposit  //31
    s ParamArr("OrderHiddenPara")=OrderHiddenPara
 
    s ParamArr("KSSCopyFlag")=$G(BaseParamArr("KSSCopyFlag"))
    s OrderAntibApplyRowid=$G(ArcosArr("OrderAntibApplyRowid"))
    s EntryAuthExpStr=OrderAntibApplyRowid_"^"_ParamArr("KSSCopyFlag")
    s OrderDirectEntryAuthStr=..GetOrderDirectEntryAuth(.ParamArr,.BaseParamArr,EntryAuthExpStr)
    //直接审核权限标志，用于控制是否需要弹出用户交互的窗口
    s ParamArr("OrderDirectEntryAuth")=$P(OrderDirectEntryAuthStr,"^",1)
    //直接审核权限明细
    s ParamArr("OrderDirectEntryDetails")=$P(OrderDirectEntryAuthStr,"^",2)
    
    s ParamArr("OrderVirtualtLong")="N"
    s ParamArr("OrderChronicDiagStr")=""
    s ParamArr("OrderChronicDiagCode")=""
    s OrderSerialNum=##class(web.DHCDocPrescript).GetOrderSerialNum(EpisodeID)
    s ParamArr("OrderSerialNum")=OrderSerialNum
    s ParamArr("ViewBindSource")=""
    q
CheckItemAllergy(ParamArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s HOSPID=$P(SessionStr,"^",4)
    s ArcimDesc=ParamArr("OrderName")
    //脱敏提示 本医嘱为脱敏治疗使用，请注意近期过敏药物的使用情况 confirm提示
    s OrderActionRowid=$g(ParamArr("OrderActionRowid"))
    if (OrderActionRowid'=""){
        s OrderActionCode=$p($g(^OEC("ACT",OrderActionRowid)),"^",1)
        if (OrderActionCode="TM"){
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","医嘱为脱敏治疗使用,请注意近期过敏药物的使用情况,是否继续录入?")
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
            Q OutInfo
        }
    }
    s iallergy=ParamArr("iallergy")
    s OrderType=ParamArr("OrderType")
    //有过敏记录阳性的药物强制不能开?A也不合适?A有时阳性了还需再做皮试?A希望提示但不强制限制?C
    s allergycode = $P(iallergy,$C(1),1)
    s allergymsg = $P(iallergy,$C(1),2)
    s status = $P(iallergy,$C(1),3)
    if (allergycode="01"){
        if (status="Y"){
            s OutInfo="-1^"_ArcimDesc_" "_allergymsg_..%Translate("oeorder.oplistcustom.new.csp"," 患者对此医嘱有过敏反应!")
            q OutInfo
        }else{
            s CallBackFunParams=ArcimDesc_" "_allergymsg_..%Translate("oeorder.oplistcustom.new.csp"," 患者对此医嘱有过敏反应,请确定是否继续录入?")
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
        }
    }elseif (allergycode = "02") {
        if (status="Y"){
            s OutInfo="-1^"_ArcimDesc_" 患者对药学项【"_allergymsg_"】皮试阳性!"
            q OutInfo
        }else{
            s CallBackFunParams=ArcimDesc_" 患者对药学项【"_allergymsg_"】皮试阳性,请确定是否继续录入?"
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)	
        }
    }elseif (allergycode = "03") { 
        if (status="Y"){
            s OutInfo="-1^"_ArcimDesc_" 患者对通用名【"_allergymsg_"】皮试阳性!"
            q OutInfo
        }else{
            s CallBackFunParams=ArcimDesc_" 患者对通用名【"_allergymsg_"】皮试阳性,请确定是否继续录入?"
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
        }
    }
    /*if (allergycode="01") {
        s CallBackFunParams=ArcimDesc_" 患者对此医嘱有过敏反应,请确定是否继续录入医嘱?"
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
    }elseif (allergycode = "02") {
        s CallBackFunParams=ArcimDesc_" 此医嘱患者皮试阳性,请确定是否继续录入医嘱?"
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
    }*/
    if (ParamArr("OrderSkinTest")="Y"){
        s ret=##class(web.DHCDocOrderCommon).OrdSkinTestRule($G(ParamArr("OrderARCIMRowid")),BaseParamArr("Adm"))
        if (ret=""){
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 此医嘱患者72小时内没有皮试记录,请确定是否皮试?")
        }elseif(ret=1){
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 此医嘱患者72小时内有皮试记录,结果【阳性】,是否皮试？")
        }else{
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 此医嘱患者72小时内有皮试记录,结果：【阴性】,是否皮试？")
        }
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SetOrderSkinTest",CallBackFunParams)
    }
    ;过敏记录药学子类需提示
    s AllergyChildNoticeStr=ParamArr("AllergyChildNotice")
     s AllergyChildNotice=..%GetConfig("AllergyChildNotice",HOSPID)
    if ((AllergyChildNotice=1)&&(OrderType="R")) {
        s ret=+$P(AllergyChildNoticeStr,$C(2),1)
        s Message=$P(AllergyChildNoticeStr,$C(2),2)
        if (ret'=0) {
            s CallBackFunParams=ArcimDesc_"药学子类和过敏记录的药品【"_Message_"】的药学子类相同"
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        }
    }
    
    q OutInfo
CheckDupOrderItemCat(ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s USERID=$P(SessionStr,"^",1)
    s GROUPID=$P(SessionStr,"^",2)
    s CurLogonHosp=$p(SessionStr,"^",4)
    s EpisodeID=BaseParamArr("Adm")
    s ArcimDesc=ParamArr("OrderName")
	s langid=$P(SessionStr,"^",6)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    ;不允许重复录入的子类
    s OPUnRepeatItemCat=..%GetConfig("OPUnRepeatItemCat",CurLogonHosp)
    ;补录模式
     s SupplementMode=##class(DHCDoc.DHCDocConfig.Group).GetGroupCfgData("SupplementMode",SessionStr)
    if (SupplementMode=1){q OutInfo}
    s ItemCatRowId=ParamArr("OrderItemCatRowid")
    //查找是否有不允许重复录入的相同子类医嘱
    if ((PAAdmType="O") && (OPUnRepeatItemCat'= "")) {
        if ("^"_OPUnRepeatItemCat_"^")[("^"_ItemCatRowId_"^") {
            s i=""
            for {
                s i=$O(ItemOrdsArr("ItemOrds",i))
                q:(i="")
                continue:(ItemOrdsArr("ItemOrds",i,"OrderItemRowid")'="")
                continue:(ItemOrdsArr("ItemOrds",i,"rowid")=BaseParamArr("rowid"))
                s OrderARCIMRowid=ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
                continue:(OrderARCIMRowid="")
                s TItemCatRowid=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)
                s rowid=ItemOrdsArr("ItemOrds",i,"rowid")
                if (ItemCatRowId=TItemCatRowid){
                    s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 子类重复",langid)_"^^^^"
                    q
                }
            }
            s retDetail=##Class(web.DHCDocOrderCommon).FindSameOrderItemCat(EpisodeID, ItemCatRowId, CurLogonHosp)
            if (retDetail = 1){
                s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 子类重复",langid)_"^^^^"
                //q  
            }
        }
    }
    
    q OutInfo
CheckConflict(ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s ARCIMRowid=$G(ParamArr("OrderARCIMRowid"))
    s OrderName=$G(ParamArr("OrderName"))
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s CurLogonHosp=$p(SessionStr,"^",4)
    s langid=$p(SessionStr,"^",6)
    ;s ConflictItems = ##Class(web.DHCDocConfig).GetConflict(ARCIMRowid,CurLogonHosp)
    d ##class(DHCDoc.DHCDocConfig.ARCIMExt).GetConflict(ARCIMRowid,CurLogonHosp,.ConflictItemList)
    if $D(ConflictItemList){	;同次审核的医嘱先不判断互斥类型 直接不允许同时开
        s i="" for {
            s i=$O(ItemOrdsArr("ItemOrds",i)) q:(i="")
            continue:(ItemOrdsArr("ItemOrds",i,"OrderItemRowid")'="")
            continue:(ItemOrdsArr("ItemOrds",i,"rowid")=ARCIMRowid) //BaseParamArr("rowid")
            s OrderARCIMRowid=ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
            continue:OrderARCIMRowid=""
            continue:'$D(ConflictItemList(OrderARCIMRowid))
            s OrderItemRowid=ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
            continue:OrderItemRowid'=""
            s OrderARCIMName=$P(^ARCIM(+OrderARCIMRowid,1,1),"^",2)
            s OrderARCIMName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderARCIMName,langid)
            ;s OrderPriorRowid=ItemOrdsArr("ItemOrds",i,"OrderPriorRowid")
	        s OutInfo="-1^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 存在互斥医嘱",langid)_OrderARCIMName_"^^^^"
	        Q
        }
        if ($p(OutInfo,"^",1)=0){
            ;s ret=##Class(web.DHCDocOrderEntry).CheckConflict(EpisodeID, ARCIMRowid, CurLogonHosp)
            s OrderStartDate=$G(ParamArr("OrderStartDate"))
            s PriorRowid=$G(ParamArr("OrderPriorRowid"))
            s ret=##class(DHCDoc.DHCDocConfig.ARCIMExt).CheckConflict(EpisodeID,ARCIMRowid,$P(OrderStartDate," ",1),$P(OrderStartDate," ",2),PriorRowid,CurLogonHosp,langid)
            s ConflictFlag = $P(ret, "^", 1)
            if (ConflictFlag = "Y") {
	            s CallBackFunParams = $P(ret, "^", 2)
	            s ConflictType=$P(ret, "^", 3)
	            if " AF "[(" "_ConflictType_" "){
		            s OutInfo="-1^"_CallBackFunParams
	            }else{
                	s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
	            }
            }
        }
    }
    q OutInfo
BaseValidCheck(ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    
    s MaterialBarcode=BaseParamArr("MaterialBarcode")
    s PageDefaultOrderPriorStr=$G(BaseParamArr("PageDefaultOrderPriorStr"))
    s PriorRowid=$p(PageDefaultOrderPriorStr,"^",1)
    s PPRowId=$G(BaseParamArr("PPRowId"))
    s ArcimDesc=ParamArr("OrderName")
    s OrderType=ParamArr("OrderType")
    s OrderItemCatRowid=ParamArr("OrderItemCatRowid")
    s PHCDFCriticalFlag=ParamArr("PHCDFCriticalFlag")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s USERID=$P(SessionStr,"^",1)
    s CareProvType=##class(web.DHCDocOrderCommon).GetCareProvType(USERID)
    s CareProvType=$zcvt(CareProvType,"U")
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s CurrentDischargeStatus=##class(web.DHCDischargeHistory).GetCurrentDischargeStatus(EpisodeID)
    s CTLOCID=$P(SessionStr,"^",3)
    s GROUPID=$P(SessionStr,"^",2)
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s OEOrderRowID=$o(^OEORD(0,"Adm",EpisodeID,""))
     ///护士绑定医嘱时，判断要不要跟着主医嘱走
    s LinkedMasterOrderRowid=$G(BaseParamArr("VerifiedOrderObj","LinkedMasterOrderRowid"))
    if (LinkedMasterOrderRowid'="")&&(OEOrderRowID'=$P(LinkedMasterOrderRowid,"||")){
       k BaseParamArr("VerifiedOrderObj")
       s LinkedMasterOrderRowid=""
    }
    s TransFlag=ParamArr("TransFlag")
    if (TransFlag="1"){
        s CallBackFunParams=..%Translate("oeorder.oplistcustom.new.csp","患者已转科！录入【",langid)_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","】医嘱审核后将停止本科室所有长期医嘱!",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
    }
    s OrderBodyPartLabel=ParamArr("OrderBodyPartLabel")
    if (OrderBodyPartLabel'=""){
        s VerifyPartFlag=##class(web.DHCAPPInterface).VerifyPartInArci(OrderARCIMRowid,$TR(OrderBodyPartLabel,"*","^"))
        if (VerifyPartFlag="N"){
            s PartInfo=##Class(web.DHCAPPExaReportQuery).GetPartLabel($TR(OrderBodyPartLabel,"*","^"))
            s OrderBodyPartLabel=""
            s ArcimDesc=$p(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1),"^",2) //$TR(ArcimDesc,PartInfo,"")
            s ParamArr("OrderName")=ArcimDesc
            s BaseParamArr("OrderBodyPartLabel")=""
            s ParamArr("OrderBodyPartLabel")=""
            s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","对应的检查部位",langid)_PartInfo_..%Translate("oeorder.oplistcustom.new.csp","数据已失效，请重新选择部位!",langid)
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
        }
    }
    
    s AllowOnlyOnceRepeatFlag=ParamArr("AllowOnlyOnceRepeatFlag")
    if (AllowOnlyOnceRepeatFlag>0){
	    if AllowOnlyOnceRepeatFlag=1{
        	s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一次就诊只允许开一次,此患者在本次就诊中已开过此医嘱,不允许在开!",langid)_"^^^^"
	    }else{
        	s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一个患者只允许开一次,此患者在历次或本次就诊中已开过此医嘱,不允许在开!",langid)_"^^^^"
		}
    }
    s AllowOnlyOnce= ParamArr("AllowOnlyOnce")
    s AdmAllowOnlyOnce=ParamArr("AdmAllowOnlyOnce")
    if (AllowOnlyOnce="Y")||(AdmAllowOnlyOnce="Y"){
        s i=""
        for {
            s i=$O(ItemOrdsArr("ItemOrds",i)) q:(i="")
            continue:(ItemOrdsArr("ItemOrds",i,"OrderItemRowid")'="")
            if (ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")=BaseParamArr("OrderARCIMRowid")){
	            if AdmAllowOnlyOnce="Y"{
                	s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一次就诊只允许开一次,不允许在开!",langid)_"^^^^"
	            }else{
		        	s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 已设置一个患者只允许开一次,不允许在开!",langid)_"^^^^"
		        }
                q
            }
        }
    }
    //这个判断还有用吗？
    if (OrderType'="R")&&(BaseParamArr("AddMethod")'="obj"){
        s IsGroupOrd=0
        s (OrderSeqNoMain,OrderMasterSeqNoMain)=""
        s i=""
        for {
            s i=$O(ItemOrdsArr("ItemOrds",i))
            q:(i="")
            if (ItemOrdsArr("ItemOrds",i,"rowid")=BaseParamArr("rowid")) {
                s OrderSeqNoMain=ItemOrdsArr("ItemOrds",i,"OrderSeqNo")
                s OrderMasterSeqNoMain=ItemOrdsArr("ItemOrds",i,"OrderMasterSeqNo")
            }
        }
        s i=""
        for {
            s i=$O(ItemOrdsArr("ItemOrds",i))
            q:(i="")
            continue:(ItemOrdsArr("ItemOrds",i,"OrderItemRowid")'="")
            continue:(ItemOrdsArr("ItemOrds",i,"rowid")=BaseParamArr("rowid"))
            s OrderSeqNo=ItemOrdsArr("ItemOrds",i,"OrderSeqNo")
            s OrderMasterSeqNo=ItemOrdsArr("ItemOrds",i,"OrderMasterSeqNo")
            if (OrderMasterSeqNoMain = "") {
                if (OrderSeqNoMain = OrderMasterSeqNo)&&(OrderMasterSeqNo'="") {
                    s IsGroupOrd=1
                }
            } else {
                if ((OrderMasterSeqNoMain = OrderSeqNo) || (OrderMasterSeqNo = OrderMasterSeqNoMain)) {
                    s IsGroupOrd=1
                }
            }
        }
        if (IsGroupOrd=1){
            s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 非药品医嘱不能关联!",langid)_"^^^^"
        }
    }
    if (PPRowId'=""){

    	s ProWarning=##class(web.PilotProject.DHCDocPilotProject).GetProWarning(PPRowId,langid)
    	s:ProWarning'="" OutInfo="-1^"_ArcimDesc_" "_ProWarning_"^^^^"
    }
    
    //0单价医嘱提示
    s OrderPrice=ParamArr("OrderPrice")
    if (+OrderPrice=0)&&(OrderPrice'="") {
        ;不提示零价格医嘱
         s CFNotAlertZeroPrice=..%GetConfig("NotAlertZeroPrice",HOSPID)
        if (CFNotAlertZeroPrice'= 1) {
            s AlertZero = 1
            s NotAlertZeroItemCatStr=..%GetConfig("NotAlertZeroItemCat",HOSPID)
            if (NotAlertZeroItemCatStr '= "") {
                if (("^"_NotAlertZeroItemCatStr_"^")[("^"_OrderItemCatRowid_"^")) {
                    s AlertZero = 0
                }
            }
            if (AlertZero=1) {
                s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","此医嘱单价为0,您确定要开吗?",langid)
                s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
            }
        }
    }
    if (OrderType = "P") {
        s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","自定义价格医嘱需要填写价格!",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
    }
    if (1=ParamArr("OrderItemInValid")){
        s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 医嘱项目无效!",langid)_"^^^^"
    }
    if (0=ParamArr("OrderAuthInValid")){
        if $G(ParamArr("AuthInValidMsg"))'=""{
            s OutInfo="-1^"_ArcimDesc_" "_$G(ParamArr("AuthInValidMsg"))_"^^^^"
        }else{
            s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 没有权限录入该医嘱!",langid)_"^^^^"
        }
    }
    if (""=ParamArr("OrderRecLocStr")){
        s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 该医嘱没有接收科室,请与信息中心联系!",langid)_"^^^^"
    }
    if (0'=ParamArr("AlertAuditSpecialItem")){
        s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","需要医保办审批，否则按自费结算处理!",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Confirm",CallBackFunParams)
    }
    if (PHCDFCriticalFlag="Y"){
        s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","为高危药请慎重使用!",langid)
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
    }
    if ("3"=ParamArr("OrderPHPrescType")){
        s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 西药录入界面不允许录入草药医嘱,请使用草药录入界面",langid)_"^^^^"
    }
    if ("1"=ParamArr("ASCheckFlag")){
        if (ParamArr("ASCheckAgeRange")'=""){
            s OutInfo="-1^"_..%Translate("oeorder.oplistcustom.new.csp","项目[",langid)_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","]被限制使用：",langid)_ParamArr("ASCheckAgeRange")_"^^^^"
        }else{
            s OutInfo="-1^"_..%Translate("oeorder.oplistcustom.new.csp","项目[",langid)_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","]被限制使用：",langid)_ParamArr("ASCheckSex")_"^^^^"
        }
    }
    if ("L"=ParamArr("OrderType")){
        if (ParamArr("OrderLabItemActive") '= "Y") {
            s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","已经被检验部门设置为暂不可用",langid)_"^^^^"
        }
        if (($g(ParamArr("OrderLabSpec")) = "")&&($g(ParamArr("OrderLabSpecStr"))="")) {
            s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","检验标本没有维护正确",langid)_"^^^^"
        }
    }
    s DurgMsg=##class(DHCDoc.GCPSW.CFG.Warning).GetGCPBanDrugMsg(BaseParamArr("PPRowId"),OrderARCIMRowid,"",EpisodeID,"",langid)
     if (DurgMsg '= "") {
        s OutInfo="-1^"_DurgMsg_"^^^^"
        q OutInfo
    }
        
    if (BaseParamArr("PPRowId")=""){
        if ("Y"'=ParamArr("PilotCatFlag")){
            s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","此医嘱为药理项目医嘱,只能在有药理项目的情况下才可下.",langid)_"^^^^"
        }
    }else{
        ;GCP判断规则修改：优先判断免费医嘱，后子类 2021-11-30 QP
        s PilotCatStr=$G(^DHCDocPilotSeting(HOSPID,"PilotProSubCatStr"))
        s ItemCatDr=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",10) 
        s PPOpenOrdEntryLimit=$p($g(^DHCDocPP(BaseParamArr("PPRowId"))),"^",117)
        if (PPOpenOrdEntryLimit="Y"){
            ;开启医嘱录入限制
            ;s FreeStr=##class(web.PilotProject.DHCDocPilotProject).CheckArcim(BaseParamArr("PPRowId"),OrderARCIMRowid)
            s FreeStr=##class(web.PilotProject.CFG.FindGCP).CheckArcim(BaseParamArr("PPRowId"),OrderARCIMRowid,EpisodeID)
            s FreeFlag=$p(FreeStr,"^",1)
            if (FreeFlag="Y") {
                s PPFreeNum=$p(FreeStr,"^",2) ;项目免费次数
                s PPFLimitEntryAfterNoFreeNum=$p(FreeStr,"^",3) ;免费次数用完是否限制录入
                ;已免费的数量
                s PPPARowId=##class(web.PilotProject.DHCDocPilotProject).GetPilotProPatAdmRowId(BaseParamArr("PPRowId"),OrderARCIMRowid,EpisodeID)
                s InStage=##class(web.PilotProject.Extend.PatAdd).GetStageByAdm(BaseParamArr("PPRowId"),EpisodeID,"")
                s PilotProHasFreeNum=##class(web.PilotProject.DHCDocPilotProject).GetPilotProFreeSum(PPPARowId,OrderARCIMRowid,InStage)
                s RepeatNum=0
                s i=""
                for {
                    s i=$O(ItemOrdsArr("ItemOrds",i))
                    q:(i="")
                    s tmpOrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
                    s tmpOrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
                    ;OrderSeqNo
                    continue:(tmpOrderARCIMRowid="")||(tmpOrderItemRowid'="")||(tmpOrderARCIMRowid'=OrderARCIMRowid)
                    s RepeatNum=RepeatNum+1
                }
                ;m ^tmpscl("ItemOrdsArr")=ItemOrdsArr("ItemOrds")
                s LeftFreeNum=PPFreeNum-PilotProHasFreeNum-RepeatNum
                if (LeftFreeNum<=0){
                    if (PPFLimitEntryAfterNoFreeNum="Y"){
                        s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","药理项目维护的医嘱免费次数已用完!",langid)_"^^^^"
                    }else{
                        s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","药理项目维护的医嘱免费次数已用完!请谨慎使用!",langid)
                        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
                    }
                }
            } elseif (FreeFlag="N"){
                ;维护了该医嘱，只是过期了，再判断子类
                if (("!"_PilotCatStr_"!")'[("!"_ItemCatDr_"!")){
                    s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","药理项目维护的免费医嘱已过期！",langid)_"^^^^"
                }else{
                    ;在子类中，免费开具
                }
            } else {
                ;没有维护该医嘱,判断子类，不在子类中的不允许开具
                if (("!"_PilotCatStr_"!")'[("!"_ItemCatDr_"!")){
                    ;提示的内容可以根据项目要求进行自行更改
                    ;s OutInfo="-1^"_ArcimDesc_"此医嘱为非药理项目医嘱,不能在有药理项目的情况下开.^^^^"
                    s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","在有药理项目的情况下,药理项目开启医嘱录入限制时只有项目维护免费医嘱的才可开立.",langid)_"^^^^"	
                }else{
                    ;在子类中，免费开具
                }
            }
        }else{
            ;没开启限制，则判断子类，并且非药理子类的非药品可无限制录入且全部免费
            if (("!"_PilotCatStr_"!")'[("!"_ItemCatDr_"!")){
                ;不在子类中，非药品可无限制录入且全部免费
                if (OrderType="R"){
                    s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","此药品医嘱为非药理项目药品医嘱,不能在有药理项目的情况下开.",langid)_"^^^^"
                } 
            }else{
                ;在子类中，免费开具
            }
        }
    }
    /*if ((CareProvType="DOCTOR") && (PAAdmType="I")&&(ParamArr("MidDischargedFlag")="1")&&(CurrentDischargeStatus'="B")) {
         s OutInfo="-1^此病人已做医疗结算,不允许医生再开医嘱.^^^^"
    }*/
    s IncItmHighValueFlag=##Class(web.DHCDocOrderCommon).GetIncItmHighValueFlag(OrderARCIMRowid)
    if (IncItmHighValueFlag="Y"){
        s HighValueControl=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(CTLOCID,13)
        s PriorCode=$p($g(^OECPR(PriorRowid)),"^",1)
        if (HighValueControl'=1){
            s OutInfo="-1^您所登录的科室没有录入高值材料的权限,请联系信息科确认!^^^^"
        }else{
            if (MaterialBarcode=""){
                s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","属于高值耗材,只能通过扫条码下医嘱!",langid)
            }
            if (PriorCode '= "NORM") {
                s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","高值材料请开临时医嘱使用!",langid)
                q OutInfo
            }
        }
        if (+OrderPrice=0)&&(OrderPrice'=""){
            s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","高值材料单价为0,请核对项目维护是否正确!",langid)
            q OutInfo
        }
    }
    
    /*if ((HighValueControl'=1)&&(ParamArr("IncItmHighValueFlag")="Y")) {
        s OutInfo="-1^您所登录的科室没有录入高值材料的权限,请联系信息科确认!^^^^"
    }*/
    ;按照医嘱项上的门诊用药、急诊用药、住院用药标志来检测医嘱项是否可用
    if (ParamArr("CheckArcimTypeStr")'=""){
        s OutInfo="-1^"_ArcimDesc_" "_..%Translate("oeorder.oplistcustom.new.csp",ParamArr("CheckArcimTypeStr"),langid)_"^^^^"
    }
    ;判断是否有医嘱分类管控权限
    s DoctorID=##class(web.SSUser).GetDefaultCareProvider(USERID)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s LogonUserID=$P(SessionStr,"^",1)
    s CurLogonDep=$p(SessionStr,"^",3)
    s AdmDepId=$p($g(^PAADM(EpisodeID)),"^",4)
    s AdmReason=$p($G(^PAADM(EpisodeID,1)),"^",7)
    s EpisodeType=$P($G(^PAADM(EpisodeID)),"^",2)
    s PAADMRegConDisDR=$P($G(^PAADM(EpisodeID,"DHC")),"^",25)
    s PatientID=$P(^PAADM(EpisodeID),"^",1)
    s PatientNo=$P($g(^PAPER(PatientID,"PAT",1)),"^",1)
    s PACWardID=$P($g(^PAADM(EpisodeID)),"^",70)
    s:(PACWardID'="") PACWardLocId=$P($g(^PAWARD(PACWardID)),"^",5)
    s CareProvTP=$P($G(^CTPCP(+DoctorID,1)),"^",4)
    s SessTypeID=$P(##class(DHCDoc.Interface.Inside.ServiceOPAdm).GetRegSessType(EpisodeID),"^",1)
    s ItemAuth=##Class(PHA.FACE.OUT.Com).GetCombCtrlLevel(OrderARCIMRowid,HOSPID,"",CurLogonDep,$g(AdmDepId),$G(PACWardLocId),$g(CareProvTP),USERID,EpisodeType,$g(AdmReason),PatientNo,"","",SessTypeID)
    if (ItemAuth.CtrlLevel="BAN"){
        s OutInfo="-1^该"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","已做用药限制，没有权限开立！",langid)_"^^^^"
        q OutInfo
    }elseif (ItemAuth.CtrlLevel="PROMPT"){
        s CallBackFunParams=ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp","已做用药限制,",langid)_ItemAuth.Remarks
        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)	
    }
    ///是否需要关联录入专科表单信息
    s SpecLocDiagStr=##class(DHCDoc.Diagnos.SpecLoc).GetArcimLinkSpecLocDiag(OrderARCIMRowid,EpisodeID,SessionStr)
    s SpecLocDiagCatID=$P(SpecLocDiagStr,"^",1)
    s SpecLocDiagCatCode=$P(SpecLocDiagStr,"^",2)
    s SpecLocDiagCatName=$P(SpecLocDiagStr,"^",3)
    if (SpecLocDiagCatID'="") {
        //s SpecLocDiagCatCode="YKMB" //眼科模板
        s OrderSerialNum="ord|"_ParamArr("OrderSerialNum")
        s Count=0
        //排除一下是否有重复的专科表单
        &SQL(SELECT COUNT(ID) into :Count from SQLUser.MR_SpecLocDiag where CustomSerialNum=:OrderSerialNum and AdmDR=:EpisodeID and Active<>'N')
        if (Count=0){
            s CallBackFunParams=OrderSerialNum_";"_SpecLocDiagCatCode_";"_SpecLocDiagCatName_";"_ArcimDesc
            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"SpecDiagForm",CallBackFunParams)
        }
    }
    q OutInfo
TranByParamArr(ParamArr,BaseParamArr)
    n (ParamArr,BaseParamArr)
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s langid=$P(SessionStr,"^",6)
    s ParamArr("OrderDur")=##class(User.PHCDuration).GetTranByDesc("PHCDUDesc1",ParamArr("OrderDur"),langid)
    s ParamArr("OrderInstr")=##class(User.PHCInstruc).GetTranByDesc("PHCINDesc1",ParamArr("OrderInstr"),langid)
    s ParamArr("OrderFreq")=##class(User.PHCFreq).GetTranByDesc("PHCFRDesc1",ParamArr("OrderFreq"),langid)
    s ParamArr("OrderPackUOM")=##class(User.CTUOM).GetTranByDesc("CTUOMDesc",ParamArr("OrderPackUOM"),langid)
	s ParamArr("OrderAction")=##class(User.OECAction).GetTranByDesc("ACTDesc",ParamArr("OrderAction"),langid)
	s ParamArr("OrderPrior")=##class(User.OECPriority).GetTranByDesc("OECPRDesc",ParamArr("OrderPrior"),langid)
	s ParamArr("OrderBillType")=##class(User.DHCPrescriptType).GetTranByDesc("PTDescription",ParamArr("OrderBillType"),langid)
	s ParamArr("OrderPriorRemarks")=..%Translate("oeorder.oplistcustom.new.csp",ParamArr("OrderPriorRemarks"),langid)
	s OrderFlowRateUnit=ParamArr("OrderFlowRateUnit")
	s OrderFlowRateUnitRowId=ParamArr("OrderFlowRateUnitRowId")
	if OrderFlowRateUnitRowId'="" s OrderFlowRateUnit=$P($G(^OEC("SFR",OrderFlowRateUnitRowId)),"^",2)
    s ParamArr("OrderFlowRateUnit")=##class(User.OECSpeedFlowRate).GetTranByDesc("SFRDesc",OrderFlowRateUnit,langid)
	s ParamArr("ExceedReason")=##class(User.DHCDocExceedReason).GetTranByDesc("DHCExceedDesc",ParamArr("ExceedReason"),langid)
    q 
CheckStopAllLongOrd(ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    n (ParamArr,ItemOrdsArr,BaseParamArr,CallBackFunStr)
    s OutInfo="0^^^^^^"
    s EpisodeID=BaseParamArr("Adm")
    s VisitStatus=$p($g(^PAADM(EpisodeID)),"^",20)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s ItemCatDR=$p(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1),"^",10)
    s PriorRowid=ParamArr("OrderPriorRowid")
    s ArcimDesc=ParamArr("OrderName")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s USERID=$P(SessionStr,"^",1)
    s CurLogonHosp=$p(SessionStr,"^",4)
    s langid=$p(SessionStr,"^",6)
    ///是否为实习生
    s DoctorID=##class(web.SSUser).GetDefaultCareProvider(USERID)
    s PracticeFlag=##class(web.DHCOEOrdItem).practice(DoctorID)
    s TransType=##Class(DHCDoc.Interface.Inside.Invoke).GetArcimTransType(OrderARCIMRowid,CurLogonHosp)
    if (PAAdmType="I"){
        //若本次录入的医嘱是长期或出院医嘱,判断未审核医嘱是否有长期医嘱
        s LongOrdFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
        s DisChargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(OrderARCIMRowid,CurLogonHosp)
        s ARCIMExtInfo=##class(DHCDoc.DHCDocConfig.ARCIMExt).getARCIMConfig(OrderARCIMRowid)
		s StopAfterLongOrder=$P(ARCIMExtInfo,"^",3)
        if ((DisChargeOrdFlag'=0)||(TransType'="")||(StopAfterLongOrder=1)) {
            if (PracticeFlag=1) {
                s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 实习医生不允许开立出院/转科/死亡类医嘱!",langid)_"^^^^"
                q OutInfo
            }elseif (VisitStatus ="P") {
                s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 预住院患者不允许开立出院/转科/死亡类医嘱!",langid)_"^^^^"
                q OutInfo
            }
        }
        if (LongOrdFlag=1)||(DisChargeOrdFlag'=0)||(TransType'="")||(StopAfterLongOrder=1){
            s i=""
            for {
                s i=$O(ItemOrdsArr("ItemOrds",i))
                q:(i="")
                s iOrderItemRowid = ItemOrdsArr("ItemOrds",i,"OrderItemRowid")
                s iOrderARCIMRowid = ItemOrdsArr("ItemOrds",i,"OrderARCIMRowid")
                continue:((iOrderARCIMRowid="")||(iOrderItemRowid'=""))
                s iOrderPriorRowid = ItemOrdsArr("ItemOrds",i,"OrderPriorRowid")
                s ARCIMExtInfo=##class(DHCDoc.DHCDocConfig.ARCIMExt).getARCIMConfig(iOrderARCIMRowid)
				s iStopAfterLongOrder=$P(ARCIMExtInfo,"^",3)
                if (LongOrdFlag=1){
                    s iDisChargeOrdFlag=##class(web.DHCDocOrderEntry).IsDischargeOrd(iOrderARCIMRowid,CurLogonHosp)
                    if (iDisChargeOrdFlag'=0)||(iStopAfterLongOrder=1){
                        s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 长期医嘱不允许和出院(转科)医嘱一起开立开!",langid)_"^^^^"
                        q
                    }
                }else{
                    s iLongOrdFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(iOrderPriorRowid)
                    if (iLongOrdFlag){
                        s OutInfo="-1^"_ArcimDesc_..%Translate("oeorder.oplistcustom.new.csp"," 出院(转科)医嘱不允许和长期医嘱一起开立开!",langid)_"^^^^"
                        q
                    }
                }
            }
        } 
    }
    q OutInfo
GetItemRowDataJsonObj(OutPutInfo,CallBackFunStr,ParamArr,ItemRowDataArr)
    n (OutPutInfo,CallBackFunStr,ParamArr,ItemRowDataArr)
    k ItemRowDataArr
    s ErrCode=$P(OutPutInfo,"^",1)
    s ErrMsg=$P(OutPutInfo,"^",2)
    s ItemRowDataArr("ErrCode")=ErrCode
    s ItemRowDataArr("ErrMsg")=ErrMsg
    
    s SubNodeNum=0
    for i=1:1:$Length(CallBackFunStr,$C(2)){
        s SingleCallBackFun=$P(CallBackFunStr,$C(2),i)
        if (SingleCallBackFun=""){continue}
        s CallBakFunCode=$P(SingleCallBackFun,"^",1)
        s CallBakFunParams=$P(SingleCallBackFun,"^",2)
        s SubNodeNum=SubNodeNum+1
        s ItemRowDataArr("CallBakFunS",SubNodeNum,"CallBakFunCode")=CallBakFunCode
        s ItemRowDataArr("CallBakFunS",SubNodeNum,"CallBakFunParams")=CallBakFunParams
    }
    m ItemRowDataArr("OrdListInfo")=ParamArr
    q 0
}

/*判断日期是否有修改权限
1 科室设置不允许修改日期时间,医嘱项扩展设定允许跨日，需判断
2 科室扩展允许修改，医嘱项允许修改 需判断
3 科室设置允许修改，医嘱项扩展不允许，不需要判断
4 科室设置不允许修改，医嘱项扩展不允许，不需要判断
5 医嘱项扩展设定未维护，走科室权限
true 需要判断 不需要判断
*/
ClassMethod CheckDateTimeModifyFlag(ModifyDateTimeAuthority As %String, IsCanCrossDay As %String)
{
    if (IsCanCrossDay="N") {
        q 0
    }elseif (IsCanCrossDay="Y") {
        q 1
    }else{
        //未进行医嘱项扩展设定,走科室权限
        if (ModifyDateTimeAuthority'="1") q 0
    }
    q 1
}

ClassMethod GetRecLocStrByParams(str, ParamsJson As %String) As %String
{
    s Params=##Class(DHCDoc.Util.ArrayData).%New().%FromJSON(ParamsJson)
    s PriorRowId=Params.GetAt("PriorRowId")
    s NotifyClinician=Params.GetAt("NotifyClinician")
    s HospID=Params.GetAt("HospID")
    s StrictHolRecLoc=##class(web.DHCDocConfig).GetConfigNode("StrictHolRecLoc",HospID)
    
    s RecLocStr=""
    k RecLocList
    s Find = 0
    for i = 1:1:$L(str,$C(2)) {
        s ArrData =$p(str,$C(2),i)
        s RecNotifyClinician=$P(ArrData,$C(1),6)
        if ((RecNotifyClinician'="") && (NotifyClinician'="") && (RecNotifyClinician'= NotifyClinician)) {
            continue
        }

        s RecLocList(i)=ArrData
        if ($P(ArrData,$C(1),4)= PriorRowId) {
            s Find = 1
        }
    }
    s DefaultReclocRowid=""
    s i=0
    for {
        s i = $O(RecLocList(i))
        q:(i="")
        s ArrData =$G(RecLocList(i))
        s RecLocId=$P(ArrData,$C(1),1)
        s RecPriorRowId=$P(ArrData,$C(1),4)
        s RecIsHolidayLocFlag=$P(ArrData,$C(1),5)
        s RecNotifyClinician=$P(ArrData,$C(1),6)
        //控制长期医嘱不走节假日接收科室设置--pb by tanjishan 2022-05 节假日已支持医嘱优先级维护
        //带有医嘱类型的接受科室设置，有次高优先级且具有排它的性质。但是节假日接受科室设置也可以选。
        //continue:(PriorRowId'="")&&(##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowId))&&(RecIsHolidayLocFlag=1)
        
        if (RecPriorRowId = "")  {
            //医嘱类型是强控制条件，需要在这里重置优先级
            if (Find = 0)||(RecIsHolidayLocFlag=1)||(StrictHolRecLoc'=1){
                if (RecIsHolidayLocFlag=1)&&(DefaultReclocRowid="") {
                    s DefaultReclocRowid=RecLocId
                }
                if (RecLocStr=""){
                    s RecLocStr=ArrData
                }else{
                    s RecLocStr=RecLocStr_$C(2)_ArrData
                }
            }
        }elseif ($P(ArrData,$C(1),4)= PriorRowId){
            if (RecLocStr=""){
                s RecLocStr=ArrData
            }else{
                s RecLocStr=RecLocStr_$C(2)_ArrData
            }
        }else{
            //优先级不匹配
            continue
        }
        //匹配加急选项的优先级最高
        if ((RecNotifyClinician'="") && (NotifyClinician'="") && (RecNotifyClinician= NotifyClinician)) {
            s DefaultReclocRowid=RecLocId
        }
    }
    if (DefaultReclocRowid'=""){
		s RecLocStr=##class(web.DHCARCOrdSets).CheckARCOSItemRecLoc(RecLocStr,DefaultReclocRowid)
    }
    q RecLocStr
}

/// w ##class(web.DHCOEOrdItemView).CheckStockEnough(3136,"2393||1",1,"255"_$c(1)_"煎药室[口腔]"_$c(1)_"Y"_$c(1,1)_"1"_$c(2)_"243"_$c(1)_"门诊药房"_$c(1)_"Y"_$c(1)_"",6,"")
ClassMethod CheckStockEnough(EpisodeID As %String, OrderARCIMRowid As %String, OrderPackQty As %String, CurrentRecLocStr As %String, SessCTLOCID As %String, SpecOrderPackUOMRowid As %String, OrderPriorRowid As %String = "", ByRef CallBackFunStr As %String = "", langid As %String = "") As %String
{
    s ^Tempscl("CheckStockEnough")=EpisodeID_","_OrderARCIMRowid_","_OrderPackQty_","_CurrentRecLocStr_","_SessCTLOCID_","_SpecOrderPackUOMRowid
    s OrderName=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",2)
    if (OrderPackQty = "") { q "-1" }
    s CurLogonHosp =$p($g(^CTLOC(SessCTLOCID)),"^",22)
    s ItemCatRowid=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)
    if (langid=""){
    	Set langid=..%LanguageID()
    }
    s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
    s OrderType=""
    i ItemCatRowid'="" s OrderType=$P(^ARC("IC",ItemCatRowid),"^",7)
    ;常规设置-药品库存不足不自动切换药房
    if (OrderType="R"){
        s CFNotAutoChangeRecloc=..%GetConfig("NotAutoChangeRecloc",CurLogonHosp)
        if (CFNotAutoChangeRecloc=0){
            ;科室扩展设定-药品库存不足不自动切换药房
            s CFNotAutoChangeRecloc=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(SessCTLOCID,17)
        }
    }else{
        ;常规设置-非药品库存不足不自动切换药房
        //s CFNotAutoChangeRecloc=1
        s CFNotAutoChangeRecloc=..%GetConfig("NotDrugNotAutoChangeRecloc",CurLogonHosp)
    }
    s ExpStr=EpisodeID_"^"_SessCTLOCID_"^0^^^^^"
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    i OrderPriorRowid'="" s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    e  s OrderPriorCode=""
    if ($L(CurrentRecLocStr,$C(2))=1) {
        s ArrData =$P(CurrentRecLocStr,$C(2),1)
        s OrderRecDepRowid = $P(ArrData,$C(1),1)
        s OrderRecDepDesc = $P(ArrData,$C(1),2)
        if (PAAdmType'= "I"){
            s BaseDoseQtySum=..GetConFacByUom(OrderARCIMRowid,OrderPackQty,OrderRecDepRowid,SpecOrderPackUOMRowid,PAAdmType)
            if (BaseDoseQtySum = "") { q "-1" }
        }else{
            s BaseDoseQtySum=OrderPackQty
        }
        s Check =##Class(web.DHCDocOrderCommon).CheckStockEnough(OrderARCIMRowid, BaseDoseQtySum, OrderRecDepRowid,PAAdmType,ExpStr)
        s OrderRecDepDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderRecDepDesc,langid)
        if (+Check = 0) {
            q "^"_OrderName_OrderRecDepDesc_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
        } elseif (+Check = -1) {
            q "^"_OrderName_OrderRecDepDesc_..%Translate("oeorder.oplistcustom.new.csp"," 被锁定，如需要请联系药房工作人员",langid)
        } elseif (+Check = -2){
            ;q "^"_OrderName_OrderRecDepDesc_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类绑定的)_$P(Check,"^",2)_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员")
            q "^"_OrderName_OrderRecDepDesc_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员",langid)
        } elseif (+Check = -3)&&(OrderPriorCode'="OUT")&&(OrderPriorCode'="ONE"){
            q "^"_OrderName_OrderRecDepDesc_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类绑定的",langid)_$P(Check,"^",2)_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
        } else {
            q CurrentRecLocStr
        }
    } else {
        s DefaultRecLocRowid = ""
        s DefaultRecLocDesc = ""
        s DefaultRecLocMsg=""
        for i=1:1:$L(CurrentRecLocStr,$C(2)) {
            s ArrData =$P(CurrentRecLocStr,$C(2),i)
            if (($P(ArrData,$C(1),3)="Y") && (DefaultRecLocRowid="")) {
                s DefaultRecLocRowid = $P(ArrData,$C(1),1)
                s DefaultRecLocDesc = $P(ArrData,$C(1),2)
            }
        }
        if (DefaultRecLocRowid=""){
            s DefaultRecLocRowid = $P($P(CurrentRecLocStr,$C(2),1),$C(1),1)
            s DefaultRecLocDesc = $P($P(CurrentRecLocStr,$C(2),1),$C(1),2)
        }
        if (DefaultRecLocRowid '= "") {
            if (PAAdmType '= "I"){
                s BaseDoseQtySum=..GetConFacByUom(OrderARCIMRowid,OrderPackQty,DefaultRecLocRowid,SpecOrderPackUOMRowid,PAAdmType)
                if (BaseDoseQtySum = "") { q "-1" }
            }else{
                s BaseDoseQtySum=OrderPackQty
            }
            s Check =##Class(web.DHCDocOrderCommon).CheckStockEnough(OrderARCIMRowid, BaseDoseQtySum, DefaultRecLocRowid,PAAdmType,ExpStr)
            s CheckFlag=$P(Check,"^",1)
            /*if ((CheckFlag '="0") && (CheckFlag'="-1") && (CheckFlag'="-2") && (CheckFlag'="-3")) {
                q DefaultRecLocRowid_$C(1)_DefaultRecLocDesc
            }*/
            s DefaultRecLocDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",DefaultRecLocDesc,langid)
            if (CheckFlag = "0") {
                s DefaultRecLocMsg=OrderName_DefaultRecLocDesc_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
            } elseif (CheckFlag = "-1") {
                s DefaultRecLocMsg=OrderName_DefaultRecLocDesc_..%Translate("oeorder.oplistcustom.new.csp"," 被锁定，如需要请联系药房工作人员",langid)
            } elseif (CheckFlag = "-2"){
                ;s DefaultRecLocMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类绑定的")_$P(Check,"^",2)_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员")
                s DefaultRecLocMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员",langid)
            } elseif (CheckFlag = "-3")&&(OrderPriorCode'="OUT")&&(OrderPriorCode'="ONE"){
                s DefaultRecLocMsg=OrderName_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类绑定的",langid)_$P(Check,"^",2)_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
            } else {
                q DefaultRecLocRowid_$C(1)_DefaultRecLocDesc
            }
        }
        s ret=1
        for i=1:1:$L(CurrentRecLocStr,$C(2)) {
            s ArrData =$P(CurrentRecLocStr,$C(2),i)
            if (($P(ArrData,$C(1),1)'=DefaultRecLocRowid)) {
                s OrderRecDepRowid = $P(ArrData,$C(1),1)
                s OrderRecLocDesc = $P(ArrData,$C(1),2)
                if (PAAdmType '= "I"){
                    s BaseDoseQtySum=..GetConFacByUom(OrderARCIMRowid,OrderPackQty,OrderRecDepRowid,SpecOrderPackUOMRowid,PAAdmType)
                    if (BaseDoseQtySum = "") { 
                        s ret="-1"
                        q
                       }
                }
                s Check =##Class(web.DHCDocOrderCommon).CheckStockEnough(OrderARCIMRowid, BaseDoseQtySum, OrderRecDepRowid,PAAdmType,ExpStr)
                s CheckFlag=$P(Check,"^",1)
                if ((CheckFlag '= "0") && (Check '= "-1")) {
                    if (CheckFlag = "-2"){
                       ; s ret="^"_OrderName_"通过医嘱或子类绑定的"_$P(Check,"^",2)_"被锁定，如需要请联系药房工作人员"
                        s ret="^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","被锁定，如需要请联系药房工作人员",langid)
                        q
                    }
                    if (CheckFlag = "-3")&&(OrderPriorCode'="OUT")&&(OrderPriorCode'="ONE"){
                        s ret="^"_OrderName_..%Translate("oeorder.oplistcustom.new.csp","通过医嘱或子类绑定的",langid)_$P(Check,"^",2)_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
                        q
                    }
                    //由设置决定是否切换药房
                    s OrderRecLocDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",OrderRecLocDesc,langid)
                    if (CFNotAutoChangeRecloc = "1") {
                        if (Check = "0") {
                            s ret="^"_OrderName_OrderRecLocDesc_..%Translate("oeorder.oplistcustom.new.csp","库存不足",langid)
                        } elseif (Check = "-1") {
                            s ret="^"_OrderName_OrderRecLocDesc_..%Translate("oeorder.oplistcustom.new.csp"," 被锁定，如需要请联系药房工作人员",langid)
                        } 
                        q
                    }
                    s DefaultRecLocDesc=##class(User.CTLoc).GetTranByDesc("CTLOCDesc",DefaultRecLocDesc,langid)
                    s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp","默认接收科室【",langid)_DefaultRecLocDesc_..%Translate("oeorder.oplistcustom.new.csp","】库存不足,将切换成【",langid)_$P(ArrData,$C(1),2)_"】" 
                      s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)
                    s ret=ArrData_"^默认接收科室库存不足,将换成其他接收科室"
                    Q
                } 
            }
        }
        q:(+ret'=1) ret
        s ret="^"_DefaultRecLocMsg
        q ret
    }
}

/// 获取基本单位总数
ClassMethod GetConFacByUom(ArcimRowID As %String, OrderPackQty As %String, OrderRecDepRowid As %String, SpecOrderPackUOMRowid As %String, AdmType As %String) As %String
{
    //此时传入的SpecOrderPackUOMRowid是医嘱套中维护的整包装数，
    //并不一定是最终使用的整包装单位，故需要检验SpecOrderPackUOMRowid的有效性
    if (SpecOrderPackUOMRowid="undefined") { s SpecOrderPackUOMRowid="" }
    
    ;协议包装
     s BillUOMStr=##Class(web.DHCDocOrderCommon).GetBillUOMStr(ArcimRowID, OrderRecDepRowid, "OrderEntry","",AdmType)
    s DefaultOrderPackUOM = ""
    s FirstOrderPackUOM=""
    for i = 1:1:$L(BillUOMStr,$C(2)) {
        s ArrData=$P(BillUOMStr,$C(2),i)
        if (SpecOrderPackUOMRowid'=""){
           if ($P(ArrData,$C(1),1)=SpecOrderPackUOMRowid){
             s DefaultOrderPackUOM = $P(ArrData,$C(1),1)
           }
        }else{
           if ($P(ArrData,$C(1),3)= "Y"){
             s DefaultOrderPackUOM =$P(ArrData,$C(1),1)
           }
        }
        if (i=1) s FirstOrderPackUOM=$P(ArrData,$C(1),1)
    }
    s BaseDoseQtySum=OrderPackQty
    //s BillUOMRowid=##Class(web.DHCDocOrderCommon).GetBillUOMRowID(ArcimRowID,AdmType)
    s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ArcimRowID)
    if (DefaultOrderPackUOM="") s DefaultOrderPackUOM=FirstOrderPackUOM
    if (DefaultOrderPackUOM '= "")&&(INCIRowid'="") {
        //跟计价单位没有任何关系,屏蔽
        //if (BillUOMRowid'=DefaultOrderPackUOM){
            s ConFac=##Class(web.DHCDocOrderEntry).GetConFac(ArcimRowID,INCIRowid,DefaultOrderPackUOM)
            s BaseDoseQtySum=OrderPackQty*ConFac
        //}
    }
    q BaseDoseQtySum
}

/// 初始化医嘱套或复制医嘱对象，注意不能随便初始化ARCOSArr，后面计算会判断$D(ARCOSArr)
ClassMethod InitARCOSArr(ByRef ARCOSArr, ByRef BaseParamArr, ByRef SubOrdCongeriesArr) As %String
{
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=BaseParamArr("SessionStr")
    
    s OrderARCIMRowid=SubOrdCongeriesArr("OrderARCIMRowid")
    s ParamS=$G(SubOrdCongeriesArr("ParamS"))
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s USERID=$P(SessionStr,"^",1)
    s GROUPID=$P(SessionStr,"^",2)
    s CTLOCID=$P(SessionStr,"^",3)
    s HOSPID=$P(SessionStr,"^",4)
    s langid=$P(SessionStr,"^",6)
    s OrderPriorStr=##Class(web.DHCDocOrderCommon).GetOrderPrior(EpisodeID,"JSON",CTLOCID,langid,USERID,GROUPID)
    ;出院带药医嘱
    s OutOrderPriorRowid=$O(^OECPR(0,"Code","OUT",0))
    s OneOrderPriorRowid=$O(^OECPR(0,"Code","ONE",0))
    s ItemCatRowid=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)
    s PHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(ItemCatRowid,HOSPID,OrderARCIMRowid)
    s OrderType=$P(^ARC("IC",ItemCatRowid),"^",7)
    s IPDefaultDurRowId=..%GetConfig("IPDefaultDuration",HOSPID)
    s IPDefaultDur="",IPDefaultDurFactor=0
    if IPDefaultDurRowId'="" {
        s IPDefaultDur=$P($g(^PHCDU(IPDefaultDurRowId)),"^",3)
        s IPDefaultDurFactor=$P($g(^PHCDU(IPDefaultDurRowId)),"^",2)
    }
    s (OrderARCOSRowid,ARCOSSubCatRowid)= ""
    s (OrderFreq,OrderFreqRowid,OrderFreqFactor,OrderFreqInterval)=""
    s (OrderInstr,OrderInstrRowid,OrderAntibApplyRowid,UserReasonId)=""
    s (PkgOrderNo)=""
    s (OrderFreqTimeDoseStr,OrderFreqDispTimeStr)=""
    s (ExceedReasonID,ExceedReason,OrderFirstDayTimes)=""
    //从医嘱套里传入的参数,取医嘱套信息
    if (ParamS '= "") {
        //$.messager.alert("警告",ParamS);
        s ispecdoseqtystr = $P(ParamS, "^", 1)

        s ispecfrequencestr = $P(ParamS, "^", 2)
        s ispecinstructionstr = $P(ParamS, "^", 3)
        s ispecdurationstr = $P(ParamS, "^", 4)
        s ispecpackqtystr = $P(ParamS, "^", 5)
        s ispecpriorstr = $P(ParamS, "^", 6)

        s ispecordersetstr = $P(ParamS, "^", 7)
        s ispecordersetsubcatstr = $P(ParamS, "^", 9)
        s ispecOrderDepProcNote = ##class(DHCDoc.Util.Base).Trim($P(ParamS, "^", 10))
        //附加说明
        s OrderPriorRemarksRowId = $P(ParamS, "^", 11)
        //抗生素6
        s antiapplyinfostr = $P(ParamS, "^", 12)
        s Urgent = $P(ParamS, "^", 13)
        s ParaItemSpecCode = $P(ParamS, "^", 15)
        s OrderStageStr = $P(ParamS, "^", 16)
        s SpeedFlowRateStr=$P(ParamS, "^", 17)
        //新产品组提供的部位数据
        s OrderBodyPartLabel=$P(ParamS, "^", 18)
        s OrderActionRowid="NULL",OrderAction="NULL",OrderSkinTest="NULL"
        if ($l(ParamS,"^")>18) {
           s OrderActionRowid=$P(ParamS, "^", 19)
           s OrderAction=$P(ParamS, "^", 20)
            if (OrderAction="")&&(OrderActionRowid'="") s OrderAction=$p($g(^OEC("ACT",OrderActionRowid)),"^",2)
           s OrderSkinTest=$P(ParamS, "^", 21)
           //计费组套餐明细编号
           s PkgOrderNo=$P(ParamS, "^", 22)
           //同频次不同剂量
           s OrderFreqTimeDoseStr=$P(ParamS, "^", 23)
           s OrderFreqTimeDoseStr=$replace(OrderFreqTimeDoseStr,$C(2),"!")
           //周频次
           s OrderFreqDispTimeStr=$P(ParamS, "^", 24)
           //疗程超量原因
           s ExceedReasonStr=$P(ParamS, "^", 25)
           if (ExceedReasonStr'="") {
               s ExceedReasonID=$p(ExceedReasonStr,$C(1),1)
               s ExceedReason=$p(ExceedReasonStr,$C(1),2)
           }
           s OrderFirstDayTimes=$P(ParamS, "^", 26)
        }
        s OrderVirtualtLong=$P(ParamS, "^", 27)
        //化疗管理
        s OrderStartDate=$P(ParamS, "^", 28)
        s PGIID=$P(ParamS, "^", 29)
        //增加原因，用于AppendOrdCongeries中标记自增医嘱项目
        s ViewBindSource=$P(ParamS, "^", 30)
        
        if (OrderBodyPartLabel="undefined") s OrderBodyPartLabel=""
        if (Urgent = "true")||((Urgent = "Y")) {
            s Urgent = "Y"
        } else {
            s Urgent = "N"
        }
        if (antiapplyinfostr '= "undefined") {
            s OrderAntibApplyRowid = $P(antiapplyinfostr, $C(1), 1)
            s UserReasonId = $P(antiapplyinfostr, $C(1), 2)
        }
        s SpecOrderDoseQty = $P(ispecdoseqtystr, $C(1), 1) //单次剂量
        if (OrderFreqTimeDoseStr'="") s SpecOrderDoseQty=""
        s SpecOrderDoseUOM = $P(ispecdoseqtystr, $C(1), 2)
        s SpecOrderDoseUOMRowid = $P(ispecdoseqtystr, $C(1), 3)
        
        s SpecOrderFreq = $P(ispecfrequencestr, $C(1), 1) //频次
        s SpecOrderFreqRowid = $P(ispecfrequencestr, $C(1), 2)
        s SpecOrderFreqFactor = $P(ispecfrequencestr, $C(1), 3)
        s SpecOrderFreqInterval = $P(ispecfrequencestr, $C(1), 4)
        s ValidFlag = ##Class(web.DHCDocOrderCommon).CheckDataValid("PHCFreq",EpisodeID,SpecOrderFreqRowid,CTLOCID)
        if (ValidFlag="0"){
            s SpecOrderFreq=""
            s SpecOrderFreqRowid=""
            s SpecOrderFreqFactor=""
            s SpecOrderFreqInterval=""
        }
        s SpecOrderInstr = $P(ispecinstructionstr, $C(1), 1) //用法
        s SpecOrderInstrRowid = $P(ispecinstructionstr, $C(1), 2)
        s ValidFlag = ##Class(web.DHCDocOrderCommon).CheckDataValid("PHCInstruc",EpisodeID,SpecOrderInstrRowid,CTLOCID)
        if (ValidFlag="0"){
            s SpecOrderInstr=""
            s SpecOrderInstrRowid=""
        }
        s SpecOrderDur=$P(ispecdurationstr,$C(1),1)
        s SpecOrderDurRowid=$P(ispecdurationstr,$C(1),2)
        s SpecOrderDurFactor=$P(ispecdurationstr,$C(1),3)
        s SpecOrderPackQty = $P(ispecpackqtystr, $C(1), 1)
        s:$e(SpecOrderPackQty,1)="." SpecOrderPackQty="0"_SpecOrderPackQty
        s SpecOrderPackUOM = $P(ispecpackqtystr, $C(1), 2)
        s SpecOrderPackUOMRowid = $P(ispecpackqtystr, $C(1), 3)
        ;医嘱套有数量才复制单位,解决长嘱医嘱套单位不一致导致价格不一致的情况
        s:SpecOrderPackQty'="" SpecOrderPackUOMRowid=""
        s SpecOrderPrior = $P(ispecpriorstr, $C(1), 1) //医嘱类型
        s SpecOrderPriorRowid = $P(ispecpriorstr, $C(1), 2)
        
        //临床路径复用的这个节点，传入医嘱备注
        s CPWResume = $P(ispecpriorstr,$C(1),3)
        if (CPWResume '= "") {
            if (ispecOrderDepProcNote'=""){
                s ispecOrderDepProcNote=ispecOrderDepProcNote_";"_CPWResume
            }else{
                s ispecOrderDepProcNote=CPWResume
            }
        }
        //住院非出院带药医嘱，疗程默认为一天
        s ParaSpecOrderDur = $P(ispecdurationstr, $C(1), 1)
        if ((PAAdmType = "I") && (SpecOrderPriorRowid '= OutOrderPriorRowid)&&(SpecOrderPriorRowid'=OneOrderPriorRowid)&&(OrderPriorRemarksRowId'="ONE")) {
            if (OrderType = "R") {
                s SpecOrderDur = IPDefaultDur
                s SpecOrderDurRowid = IPDefaultDurRowId
                s SpecOrderDurFactor = 1
            } else {
                if (PHPrescType = "4")&&(SpecOrderPriorRowid'="") {
                    s ISLongOrderPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(SpecOrderPriorRowid)
                    if (ISLongOrderPrior=0) {
                        s SpecOrderDur = IPDefaultDur
                        s SpecOrderDurRowid = IPDefaultDurRowId
                        s SpecOrderDurFactor = 1
                    }
                } else {
                    s SpecOrderDur = ""
                    s SpecOrderDurRowid = ""
                    s SpecOrderDurFactor = 1
                }
            }
        } else {
            s SpecOrderDur = $P(ispecdurationstr, $C(1), 1)
            s SpecOrderDurRowid = $P(ispecdurationstr, $C(1), 2)
            s SpecOrderDurFactor = $P(ispecdurationstr, $C(1), 3)
        }
        s OrderStage="",OrderStageCode=""
        if (OrderStageStr '= "") {
            s OrderStageCode=$P(OrderStageStr, $C(1), 1)
            s OrderStage=$P(OrderStageStr, $C(1), 2)
        }
        s OrderSpeedFlowRate="",OrderFlowRateUnit="",OrderFlowRateUnitRowId=""
        if (SpeedFlowRateStr'="") {
            s OrderSpeedFlowRate=$P(SpeedFlowRateStr, $C(1), 1)
            s OrderFlowRateUnit=$P(SpeedFlowRateStr, $C(1), 2)
            s OrderFlowRateUnitRowId=$P(SpeedFlowRateStr, $C(1), 3)
        }
        
        //GlobalObj.OrderPriorRemarksStr
        //传过来的医嘱类型有可能是实际的医嘱类型，需转化成医嘱类型+附加说明的格式
        if (OrderPriorRemarksRowId="")&&(SpecOrderPriorRowid'=""){
            s OrderPriorStr= ..SplitOrderPriorRowid(SpecOrderPriorRowid)
            s ReOrderPriorRemarksRowId=$P(OrderPriorStr,"^",3)
            s ReOrderPrior=$P(OrderPriorStr,"^",1)
            if (ReOrderPrior'=SpecOrderPriorRowid){
                s SpecOrderPrior=""
                s SpecOrderPriorRowid=ReOrderPrior
                s SpecOrderPrior=$P(^OECPR(SpecOrderPriorRowid),"^",1)
                s OrderPriorRemarksRowId=ReOrderPriorRemarksRowId
            }
        }
        s OrderPriorRemarksStr=##Class(web.DHCDocOrderCommon).GetOrderPriorRemarks(PAAdmType,"JSON")
        s OrderPriorRemarks = ""
        if ((OrderPriorRemarksStr '= "") && (OrderPriorRemarksRowId '= "")) {
            for i=1:1:$l(OrderPriorRemarksStr,";"){
                s ArrData =$p(OrderPriorRemarksStr,";",i)
                if (OrderPriorRemarksRowId = $P(ArrData,":",1)) {
                    s OrderPriorRemarks = $P(ArrData,":",2)
                    q
                }
            }
        }
        if (OrderPriorRemarks="") s OrderPriorRemarksRowId=""
        if (SpecOrderFreq '= "") {
            s OrderFreq = SpecOrderFreq
            s OrderFreqRowid = SpecOrderFreqRowid
            s OrderFreqFactor = SpecOrderFreqFactor
            s OrderFreqInterval = SpecOrderFreqInterval
            s ARCOSArr("OrderFreq")=OrderFreq
            s ARCOSArr("OrderFreqRowid")=OrderFreqRowid
            s ARCOSArr("OrderFreqFactor")=OrderFreqFactor
            s ARCOSArr("OrderFreqInterval")=OrderFreqInterval
        }
        //北海人民医院  临床路径医嘱返回信息 没有用法
        if (SpecOrderInstr '= "") {
            s OrderInstr = SpecOrderInstr //用法
            s OrderInstrRowid = SpecOrderInstrRowid
            s ARCOSArr("OrderInstr")=OrderInstr
            s ARCOSArr("OrderInstrRowid")=OrderInstrRowid
        }
        s OrderDur = SpecOrderDur //疗程
        s OrderDurRowid = SpecOrderDurRowid
        s OrderDurFactor = SpecOrderDurFactor
        s OrderPackQty = SpecOrderPackQty
        s OrderARCOSRowid = ispecordersetstr
        s ARCOSSubCatRowid = ispecordersetsubcatstr
        s POrderRecDepRowid = ""
        s ARCOSArr("OrderDur")=OrderDur
        s ARCOSArr("OrderDurRowid")=OrderDurRowid
        s ARCOSArr("OrderDurFactor")=OrderDurFactor
        s ARCOSArr("OrderPackQty")=OrderPackQty
        s ARCOSArr("OrderARCOSRowid")=OrderARCOSRowid
        s ARCOSArr("ARCOSSubCatRowid")=ARCOSSubCatRowid
        s ARCOSArr("OrderDoseQty")=SpecOrderDoseQty
        s ARCOSArr("OrderDoseUOM")=SpecOrderDoseUOM
        s ARCOSArr("OrderDoseUOMRowid")=SpecOrderDoseUOMRowid
        s ARCOSArr("SpecOrderDoseUOMRowid")=SpecOrderDoseUOMRowid
        s ARCOSArr("SpecOrderPriorRowid")=SpecOrderPriorRowid
        s ARCOSArr("SpecOrderPrior")=SpecOrderPrior
        s ARCOSArr("OrderPriorRemarks")=OrderPriorRemarks
        s ARCOSArr("OrderPriorRemarksRowId")=OrderPriorRemarksRowId
        s ARCOSArr("POrderRecDepRowid")=POrderRecDepRowid
        s ARCOSArr("OrderAntibApplyRowid")=OrderAntibApplyRowid
        s ARCOSArr("UserReasonId")=UserReasonId
        s ARCOSArr("SpecOrderPackUOM")=SpecOrderPackUOM
        s ARCOSArr("SpecOrderPackUOMRowid")=SpecOrderPackUOMRowid
        s ARCOSArr("OrderStage")=OrderStage
        s ARCOSArr("OrderStageCode")=OrderStageCode
        s ARCOSArr("Urgent")=Urgent
        s ARCOSArr("OrderSpeedFlowRate")=OrderSpeedFlowRate
        s ARCOSArr("OrderFlowRateUnit")=OrderFlowRateUnit
        s ARCOSArr("OrderFlowRateUnitRowId")=OrderFlowRateUnitRowId
        s ARCOSArr("ParaItemSpecCode")=ParaItemSpecCode
        s ARCOSArr("OrderDepProcNote")=ispecOrderDepProcNote
        s ARCOSArr("OrderBodyPartLabel")=OrderBodyPartLabel
        s ARCOSArr("OrderActionRowid")=OrderActionRowid
        s ARCOSArr("OrderAction")=OrderAction
        s ARCOSArr("OrderSkinTest")=OrderSkinTest
        s ARCOSArr("OrderPkgOrderNo")=PkgOrderNo
        s ARCOSArr("OrderFreqTimeDoseStr")=OrderFreqTimeDoseStr
        s ARCOSArr("OrderFreqDispTimeStr")=OrderFreqDispTimeStr
        s ARCOSArr("ExceedReasonID")=ExceedReasonID
        s ARCOSArr("ExceedReason")=ExceedReason
        s ARCOSArr("ViewBindSource")=ViewBindSource
        s ARCOSArr("OrderVirtualtLong")=OrderVirtualtLong
        s:OrderStartDate'="" ARCOSArr("OrderStartDate")=OrderStartDate
        s ARCOSArr("PGIID")=PGIID
        s ARCOSArr("OrderFirstDayTimes")=OrderFirstDayTimes
    }
    q
}

/// 初始化基本参数对象
ClassMethod InitBaseParamArr(ByRef SubBaseParamArr, ByRef BaseParamArr, ByRef SubOrdCongeriesArr, AddNo As %String) As %String
{
    s EpisodeID=BaseParamArr("Adm")
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    
    
    s OrderARCIMRowid=SubOrdCongeriesArr("OrderARCIMRowid")
    s ItemDefaultRowId=$G(SubOrdCongeriesArr("ItemDefaultRowId"))	;用法常用
    s OrderBillTypeRowid=$G(SubOrdCongeriesArr("OrderBillTypeRowid"))
    s RelocRowID=$G(SubOrdCongeriesArr("RelocRowID"))
    s MaterialBarcode=$G(SubOrdCongeriesArr("MaterialBarcode"))
    s ITMRowId=$G(SubOrdCongeriesArr("ITMRowId"))	;医嘱套明细ID
    s OrderBodyPartLabel=$G(SubOrdCongeriesArr("OrderBodyPartLabel"))	;新产品组身体部位
    s OrderCPWStepItemRowId=$G(SubOrdCongeriesArr("OrderCPWStepItemRowId"))	;临床路径传入的执行步骤
    s MasterSeqNo=$G(SubOrdCongeriesArr("MasterSeqNo"))	;成组医嘱的行号
    ///都是传成组关系，应该没有业务会直接传入关联医嘱的行号
    s CalSeqNo=$G(SubOrdCongeriesArr("CalSeqNo"))	;成组医嘱的计算关联号
    s DCAInfoStr=$G(SubOrdCongeriesArr("DCAInfoStr"))	;治疗申请单ID+$c(3)+接收科室ID+$c(3)+首日次数
    s OrderDepProcNote=$G(SubOrdCongeriesArr("OrderDepProcNote"))
    s KSSCopyFlag=$G(SubOrdCongeriesArr("KSSCopyFlag"))
    
    m SubBaseParamArr=BaseParamArr
    s SubBaseParamArr("OrderARCIMRowid")=OrderARCIMRowid
    s SubBaseParamArr("ItemDefaultRowId")=ItemDefaultRowId
    if (OrderBillTypeRowid'="")&&(PAAdmType'="I"){
        s SubBaseParamArr("OrderBillTypeRowid")=OrderBillTypeRowid
    }
    s SubBaseParamArr("RelocRowID")=RelocRowID
    s SubBaseParamArr("MaterialBarcode")=MaterialBarcode
    s SubBaseParamArr("ITMRowId")=ITMRowId
    s SubBaseParamArr("OrderBodyPartLabel")=OrderBodyPartLabel
    s SubBaseParamArr("OrderCPWStepItemRowId")=OrderCPWStepItemRowId
    s SubBaseParamArr("MasterSeqNo")=$g(BaseParamArr("MasterSeqNo")) //MasterSeqNo
    s SubBaseParamArr("CalSeqNo")=CalSeqNo
    s SubBaseParamArr("rowid")=BaseParamArr("rowid")+AddNo
    s SubBaseParamArr("DCAInfoStr")=DCAInfoStr
    s SubBaseParamArr("OrderDepProcNote")=OrderDepProcNote
    s SubBaseParamArr("KSSCopyFlag")=KSSCopyFlag
    s SubBaseParamArr("AddNo")=AddNo
    q
}

/// 配液中心开始接受时间
/// 增加返回:"开始日期^开始时间^是否可以修改开始日期(Y可以修改)^是否可以修改首日(Y可以修改)" 
/// w ##class(web.DHCOEOrdItemView).GetDosingDateTime("2640||1","186",5,2)
ClassMethod GetDosingDateTime(ArcimRowID As %String, OrderRecDepRowid As %String, OrderPriorRowid As %String, HospId As %String = "") As %String
{
    //V8.5.3 pb by tanjishan 目前所有的配液规则均以修改打包表接收科室实现，无需再修改开始时间或首日次数等逻辑
    //该方法仍然保留，防止各项目出现本地化修改,js中已同步屏蔽SetDosingDateTime的调用
    Q ""

    s HospId=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospId)
    s IPDosingRecLoc=##Class(DHCDoc.DHCDocConfig.DocConfig).GetDosingRecLocStr(HospId)
    Q:((IPDosingRecLoc= "") || (OrderRecDepRowid = "")) ""
    Q:("^"_IPDosingRecLoc_"^")'[("^"_OrderRecDepRowid_"^") ""
    Q:'##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid) ""
    s OrderType=##class(web.DHCDocOrderCommon).GetOrderType(ArcimRowID)
    Q:OrderType'="R" ""
    ;配液医嘱录入开始时间点
    s DosingTime=##Class(web.DHCDocConfig).GetConfigNode3("IPDosingRecLoc",OrderRecDepRowid,"DosingStartTime",HospId)   
    ;隔日配液
    s IPDosingNextDay=##Class(web.DHCDocConfig).GetConfigNode3("IPDosingRecLoc",OrderRecDepRowid,"IPDosingNextDay",HospId)
    ;按上下班时间修改静配接受科室
    s IPDosingTodayRecLoc=##Class(web.DHCDocConfig).GetConfigNode3("IPDosingRecLoc",OrderRecDepRowid,"IPDosingTodayRecLoc",HospId)
    s SttDate=..%SysDate(),SttTime=..%SysTime(),ModifyFlag="Y",FirstDayTimeModifyFlag="Y"
    if (+IPDosingNextDay=0)&&(+IPDosingTodayRecLoc=0){	
        ;全不勾选，则默认所有执行记录均可以接收到静配
    }elseif IPDosingNextDay=1{
        ;只勾选隔日配液
        s SttDate=SttDate+1
        s SttTime=DosingTime
        s ModifyFlag="N"
    }elseif IPDosingTodayRecLoc=1{
        ;只勾选“启用长期当日配液接收科室修改(按默认接收科室修改)”
    }else{
        ;都没勾选
        if DosingTime<SttTime{
            s SttDate=SttDate+1
            s SttTime=..%ZTH("00:01:00")
        }else{
            s SttTime=DosingTime
        }
        s FirstDayTimeModifyFlag="N"
    }
    s SttDate=..%ZD(SttDate),SttTime=..%ZT(SttTime)
    Q SttDate_"^"_SttTime_"^"_ModifyFlag_"^"_FirstDayTimeModifyFlag
}

/// 获取数量输入框的显示规则,同时在某些情况下强制清空数量输入框
/// w ##Class(web.DHCOEOrdItemView).ContrlOrderPackQty(118,30,203,"5837||1","",214,"Y")
ClassMethod ContrlOrderPackQty(EpisodeID, PriorRowid, CTLOCID, ARCIMRowid, OrderMasterARCIMRowid, OrderRecDepRowid, OrderVirtualtLong = "") As %String
{
    s OrderPackQtyStyle=1
    s OrderPackUOMStyle=1
    s SetOrderPackQtyValue="false"
    if EpisodeID=""{
        q OrderPackQtyStyle_"^"_OrderPackUOMStyle_"^"_SetOrderPackQtyValue
    }
    s AdmDepDr=$p($g(^PAADM(EpisodeID)),"^",4)
    s AdmDepHospId=$p(^CTLOC(AdmDepDr),"^",22)
    s CurLogonHosp =$p($g(^CTLOC(CTLOCID)),"^",22)
    Set ItemCatDR=$p(^ARCIM(+ARCIMRowid,$p(ARCIMRowid,"||",2),1),"^",10)
    Set OrderType=$P(^ARC("IC",ItemCatDR),"^",7)
    s isLongPrior=##class(appcom.OEOrdItem).ISLongOrderPrior(PriorRowid)
    s OrderPHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescType(ItemCatDR,CurLogonHosp,ARCIMRowid)
    //i OrderPHPrescType="" s OrderPHPrescType="1"
    s OrderMasterType=""
    s OrderMasterPHPrescType=""
    if (OrderMasterARCIMRowid'=""){
        s OrderMasterPHPrescType=##class(web.DHCDocOrderCommon).GetPHPrescTypeByItem(OrderMasterARCIMRowid,CurLogonHosp)
        Set OrderMasterItemCatDR=$p(^ARCIM(+OrderMasterARCIMRowid,$p(OrderMasterARCIMRowid,"||",2),1),"^",10)
        Set OrderMasterType=$P(^ARC("IC",OrderMasterItemCatDR),"^",7)
    }
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s PriorCode=$P(^OECPR(PriorRowid),"^",1)
    ;基本设置-》长期医嘱不允许录入整数量
     s CFLongOrderNotAllowPackQty=..%GetConfig("LongOrderNotAllowPackQty",CurLogonHosp)
    ;住院临时药品医嘱不允许录入整数量
     s ShortDrugOrdNotAllowPackQty=..%GetConfig("ShortDrugOrdNotAllowPackQty",CurLogonHosp)
    ;本科室不允许录入整包装数量(未启用)
     //s LocNotPackQty=##class(web.DHCDocConfig).GetDHCCTLOCFieldValue(CTLOCID,4)
     ;医嘱项扩展设定-住院是否需要录入整包装数量 
    s IPNeedBillQty=##Class(web.DHCDocOrderCommon).GetARCIMIPNeedBillQty(ARCIMRowid)
    s VisitStatus=$p($g(^PAADM(EpisodeID)),"^",20)
    s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+ARCIMRowid)
    s IPNeedPackQtyFlag=##Class(PHA.FACE.OUT.Com).GetIncilInPhUom(OrderRecDepRowid, INCIRowid).inPhPack ///住院发整包装
    s IPNeedPackQtyFlag=$CASE(IPNeedPackQtyFlag,"Y":1,:"0")
    ;静脉配液中心接收可是ID串
     s IPDosingRecLocStr=##Class(DHCDoc.DHCDocConfig.DocConfig).GetDosingRecLocStr(CurLogonHosp)
    if (IPDosingRecLocStr '= "") {
        if ((("^"_IPDosingRecLocStr_"^")[("^"_OrderRecDepRowid_"^"))&&(OrderType="R")) {
            s OrderNeedPIVAFlag="Y"
        } else {
            s OrderNeedPIVAFlag="N"
        }
    } else {
        s OrderNeedPIVAFlag="N"
    }
    ;判断是否是小时医嘱
    s IsHourItem=##Class(web.DHCDocOrderCommon).IsHourItem(ARCIMRowid)
    ;医生站设置-药房设置-临时医嘱拆分整包装发药(仅在急诊留观押金的虚拟长期模式下有效)
    s NormSplitPackQty=##Class(web.DHCDocOrderVirtualLong).GetNormSplitPackQtyFlag(EpisodeID,OrderRecDepRowid,ItemCatDR)

    //门诊住院 区分
    if (PAAdmType = "I") {
        //药品
        if (OrderType = "R") {
            //长期医嘱、长期自备药要医嘱不允许修改总量；
            if (((PriorCode = "S")||(PriorCode = "OMST")||(PriorCode = "OMCQZT")) && ((CFLongOrderNotAllowPackQty = 1))) {
                s OrderPackQtyStyle = 0
                s OrderPackUOMStyle = 0
            }
            
            if (NormSplitPackQty=1)&&(PriorCode="NORM"){
                ;医生站设置-药房设置-临时医嘱拆分整包装发药
                s OrderPackQtyStyle = 0
                s OrderPackUOMStyle = 0
                
            }
            if ((ShortDrugOrdNotAllowPackQty = 1)
                &&(PriorCode'="ONE")&&(PriorCode '= "OUT")&&(VisitStatus'="P")
                &&(IPNeedBillQty'="Y")&&(IPNeedPackQtyFlag'=1)) {
                //基本设置-》住院临时药品医嘱不允许录入整数量 预住院患者允许录入且不能为空
                s OrderPackQtyStyle = 0
                s OrderPackUOMStyle = 0
            }
            //科室扩展设置-》不允许录入整包装数量
            /*if (LocNotPackQty = 1) {
                //出院带药和取药医嘱
                if ((PriorCode'="OUT")&&(PriorCode'="ONE")){
                    s OrderPackQtyStyle = 0
                    s OrderPackUOMStyle = 0
                }
            }*/
            if (OrderPackQtyStyle = 0) { s SetOrderPackQtyValue=""}
        } else {
            //非药品带频次项目对于长期不能录入整数量的情况是一样的. 
            //因为都是按执行记录数量字段计费,无频次可以修改数量
            //--tanjishan 2019.11.29 无频次医嘱却有频次的情况，目前仅发现当有频次医嘱为主医嘱，关联无频次医嘱时，会发生
            //这种情况应该按照主医嘱的规则，清空数量，按单次剂量+频次计费
            //---tanjishan 2019.12.13之前判断的是该行是否有频次,修改为直接判断主医嘱的PHPrescType
            if (((OrderMasterPHPrescType = "4")||(OrderMasterType="R")||(OrderPHPrescType="4"))
                && (isLongPrior="1") 
                && (CFLongOrderNotAllowPackQty = 1)
                ) {
                //&& (NormSplitPackQty=0)
                s OrderPackQtyStyle = 0
                 s OrderPackUOMStyle = 0
                 s SetOrderPackQtyValue=""
            }elseif(isLongPrior=1)&&(IsHourItem=1){
                s OrderPackQtyStyle=0
                s SetOrderPackQtyValue=""
            }
            /*
            if (PriorCode = "S")&&(OrderPHPrescType="4"){
                s OrderPackQtyStyle = 0
                s SetOrderPackQtyValue=""
            }*/
        }
    } else {
        //门诊数量允许修改
        s OrderPackQtyStyle = 1
        s OrderPackUOMStyle = 1
        /*if ((OrderType = "R") && (LocNotPackQty = 1)) {
            s OrderPackQtyStyle = 0
            s OrderPackUOMStyle = 0
        }*/
        if ((OrderRecDepRowid '= "")&& (ARCIMRowid '= "")) {
            s CureItemFlag = ##Class(DHCDoc.DHCDocCure.Service).CheckItem(ARCIMRowid, OrderRecDepRowid,CurLogonHosp)
            
            if ((CureItemFlag = "1")&&((OrderPHPrescType="4")||(OrderMasterPHPrescType = "4"))) {
                s OrderPackQtyStyle = 0
                s OrderPackUOMStyle = 0
                s SetOrderPackQtyValue="true"
            }elseif ((PriorCode["OM")){
                ///将自备药、取药医嘱控制为不能录入整包装数量
                s OrderPackQtyStyle = 0
                s OrderPackUOMStyle = 0
                s SetOrderPackQtyValue=""
            }
            if (OrderType = "R"){
                if (NormSplitPackQty=1){
                    //临时医嘱拆分整包装发药时，数量可以选填，不自动计算。
                    s SetOrderPackQtyValue=""
                    if (OrderVirtualtLong="Y"){
                        s OrderPackQtyStyle = 0
                        s OrderPackUOMStyle = 0
                    }
                }else{
                    if (OrderVirtualtLong="Y"){
                        s OrderPackQtyStyle = 0
                        s OrderPackUOMStyle = 0
                        s SetOrderPackQtyValue=""
                    }
                }
            }
        }
    }
    //标版控制非药品医嘱,数量单位不允许修改,解决数量单位和基本单位不一致时,收费异常
    if (OrderType '= "R") {
        s OrderPackUOMStyle = 0
    }
    if (OrderNeedPIVAFlag="Y"){
        s OrderPackQtyStyle = 0
        s OrderPackUOMStyle = 0
        s SetOrderPackQtyValue=""
    }
    
    q OrderPackQtyStyle_"^"_OrderPackUOMStyle_"^"_SetOrderPackQtyValue
}

/// 计算医嘱使用数量，对标js中的SetPackQty方法
/// js中的SetPackQty方法也要保留，但是AddItemToList中的SetPackQty调用要整合到GetItemToList中，
/// 这两部分要想办法做复用
/// w ##Class(web.DHCOEOrdItemView).CalPackQty(^tan("web.DHCOEOrdItemView","CalPackQty"))
/// w ##Class(web.DHCOEOrdItemView).CalPackQty({"EpisodeID":3129,"OrderPriorRowid":3,"OrderARCIMRowid":"3834||1","OrderFreqRowid":51,"OrderDurRowid":2,"OrderStartDate":"2022-05-18 11:18:31","OrderFirstDayTimes":4,"OrderFirstDayTimes":"","SessionStr":"^^60^2"}.%ToJSON())
ClassMethod CalPackQty(OrdParamJson As %String) As %String
{
    ;s ^tan("web.DHCOEOrdItemView","CalPackQty")=OrdParamJson
    k CalPackArr
    s CallBackFunStr=""
    
    k OrdParamArr
    d ##Class(DHCDoc.Util.FromJSON).FromJSONToArr(OrdParamJson,.OrdParamArr)
    s EpisodeID=$G(OrdParamArr("EpisodeID"))
    s OrderPriorRowid=$G(OrdParamArr("OrderPriorRowid"))
    s OrderARCIMRowid=$G(OrdParamArr("OrderARCIMRowid"))
    s OrderDoseQty = $G(OrdParamArr("OrderDoseQty"))
    s OrderDoseUOMRowid = $G(OrdParamArr("OrderDoseUOMRowid"))
    s OrderFreqRowid=$G(OrdParamArr("OrderFreqRowid"))
    s OrderDurRowid = $G(OrdParamArr("OrderDurRowid"))
    s OldOrderPackQty = $G(OrdParamArr("OrderPackQty"))
    s OrderPackUOMRowid=$G(OrdParamArr("OrderPackUOMRowid"))
    s OrderStartDateStr=$G(OrdParamArr("OrderStartDate"))
    s OrderMultiDate=$G(OrdParamArr("OrderMultiDate"))
    s OrderPrice=$G(OrdParamArr("OrderPrice"))
    s LinkedMasterOrderPriorRowid=$G(OrdParamArr("LinkedMasterOrderPriorRowid"))
    s OrderFreqDispTimeStr=$G(OrdParamArr("OrderFreqDispTimeStr"))
    s OrderFirstDayTimes=$G(OrdParamArr("OrderFirstDayTimes"))
    s IsNotChangeFirstDayTimeFlag=$G(OrdParamArr("IsNotChangeFirstDayTimeFlag"))
    s IsNotNeedChangeFlag=$G(OrdParamArr("IsNotNeedChangeFlag"))
    s OrderFreqTimeDoseStr=$G(OrdParamArr("OrderFreqTimeDoseStr"))
    s OrderMasterARCIMRowid=$G(OrdParamArr("OrderMasterARCIMRowid"))
    s OrderRecDepRowid=$g(OrdParamArr("OrderRecDepRowid"))
    s OrderVirtualtLong=$G(OrdParamArr("OrderVirtualtLong"))
    s SessionStr=$G(OrdParamArr("SessionStr"))
    s CTLOCID=$P(SessionStr,"^",3)
    s HOSPID=$P(SessionStr,"^",4)
	s langid=$P(SessionStr,"^",6)
    s OrderName=$P(^ARCIM(+OrderARCIMRowid,$P(OrderARCIMRowid,"||",2),1),"^",2)
	s OrderName=##class(User.ARCItmMast).GetTranByDesc("ARCIMDesc",OrderName,langid)
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s INCIRowid=##class(web.DHCDocOrderEntry).GetINCI(+OrderARCIMRowid)
    s ConFac=1
    if (INCIRowid'=""){
        s ConFac=##class(web.DHCDocOrderEntry).GetConFac(OrderARCIMRowid,INCIRowid,OrderPackUOMRowid)
    }
    s CureItemFlag = ##Class(DHCDoc.DHCDocCure.Service).CheckItem(OrderARCIMRowid, OrderRecDepRowid,HOSPID)
    if (OrderStartDateStr = "") {
        s OrderStartDate=..%SysDate()
        s OrderStartTime=..%SysTime()
    }else{
        s OrderStartDate=..%ZDH($P(OrderStartDateStr," ",1))
        s OrderStartTime=..%ZTH($P(OrderStartDateStr," ",2))
    }
    s:OrderPriorRowid="" OrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    
    s ItemCatRowid=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)
    s OrderType=$P(^ARC("IC",ItemCatRowid),"^",7)
    ;可以录入小数的子类
    s AllowEntryDecimalItemCat=##Class(web.DHCDocOrderCommon).GetAllowEntryDecimalItemCat(EpisodeID,HOSPID)
    s OrderDurFactor=$P($g(^PHCDU(+OrderDurRowid)),"^",2)
    i (+OrderDurFactor=0) s OrderDurFactor=1
    if (OrderType="R")&&(OrderDoseQty="")&&(OrderFreqTimeDoseStr=""){
	    ;药品单次剂量为空 不做计算
		d SetDefQty
	}else{
	    ;分离自定义时间与周信息
	    s OrderFreqWeekStr="",OrderFreqFreeTimeStr=""
	    for i=1:1:$L(OrderFreqDispTimeStr,$C(1)){
	        s ArrData=$P(OrderFreqDispTimeStr,$C(1),i)
	        continue:ArrData=""
	        s DispTime=..%ZTH($P(ArrData,$C(2),1))
	        s DispWeek=$P(ArrData,$C(2),2)
	        s OrderFreqWeekStr=OrderFreqWeekStr_DispWeek
	        i OrderFreqFreeTimeStr="" s OrderFreqFreeTimeStr=DispTime
	        e  s OrderFreqFreeTimeStr=OrderFreqFreeTimeStr_"|"_DispTime 
	    }
	    d ##class(DHCDoc.Order.Exec).GetExecTime(.ExecList,OrderFreqRowid,OrderDurFactor,OrderStartDate,OrderStartTime,OrderFirstDayTimes,OrderFreqWeekStr,OrderFreqFreeTimeStr,HOSPID,OrderARCIMRowid,OrderPriorRowid)
	    if $D(ExecList){
	        d ##class(DHCDoc.Order.Exec).GetExecQtyToList(.ExecList,OrderPriorRowid,OrderARCIMRowid,OrderStartDate,OrderStartTime,OrderDoseQty,OrderDoseUOMRowid,"","",OrderPackUOMRowid,OrderFreqTimeDoseStr,"", PAAdmType, HOSPID)
	        s BaseDoseQtySum=0
	        s Date="" for{
	            s Date=$O(ExecList(Date)) Q:Date=""
	            s Time="" for{
	                s Time=$O(ExecList(Date,Time)) Q:Time=""
	                s ind=0 for{
	                    s ind=$O(ExecList(Date,Time,ind)) Q:ind=""
	                    s BaseDoseQty=ExecList(Date,Time,ind).AdminQty
	                    s BaseDoseQtySum=BaseDoseQtySum+BaseDoseQty
	                }
	            }
	        }
	    }else{
		    d SetDefQty
	    }
	}
    s PackQty=$FN($J(BaseDoseQtySum/ConFac,"",3),"N")
    ;s ActualComputePackQty=PackQty
    ;用户常用或医嘱套的数量大于计算数量？取传入数量 Wqy 20211221
    ;if OldOrderPackQty>PackQty s PackQty=OldOrderPackQty
    if (("^"_AllowEntryDecimalItemCat_"^")'[("^"_ItemCatRowid_"^"))&&(PackQty#1>0){
        s PackQty = (PackQty\1)+1
    }
    s OrderPackQtyStr=..ContrlOrderPackQty(EpisodeID, OrderPriorRowid, CTLOCID, OrderARCIMRowid, OrderMasterARCIMRowid, OrderRecDepRowid,OrderVirtualtLong)
    s OrderPackQtyStyle=$P(OrderPackQtyStr,"^",1)
    s SetOrderPackQtyValue=$P(OrderPackQtyStr,"^",3)
    //不允许录入数量的情况
    if (SetOrderPackQtyValue=""){
        s PackQty=""
        s OldOrderPackQty=""
        s CalPackArr("OrderPackQty")=""
    }
    
    s CFOutAndOneDefaultPackQty=##Class(PHA.FACE.OUT.Com).GetIncilInPhUom(OrderRecDepRowid, INCIRowid).outPhPack
    ;取药和出院带药默认按整包装开
    s CFOutAndOneDefaultPackQty=$CASE(CFOutAndOneDefaultPackQty,"":..%GetConfig("OutAndOneDefaultPackQty",HOSPID),"N":1,"Y":0,:1)
    if (PAAdmType = "I") {
        s IPNeedBillQty=##Class(web.DHCDocOrderCommon).GetARCIMIPNeedBillQty(OrderARCIMRowid)
        if ((OrderPriorCode="OUT") || (OrderPriorCode="ONE")) {
            if (CFOutAndOneDefaultPackQty=1)||(IPNeedBillQty="Y"){
                s OrderSum = OrderPrice * PackQty
                if ((OldOrderPackQty'="")&&(OrderPriorCode="OUT")){
                    if (OldOrderPackQty'=PackQty){
                        s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 当前医嘱用量",langid)_OldOrderPackQty_..%Translate("oeorder.oplistcustom.new.csp",$S((OldOrderPackQty<PackQty):"小于",1:"大于")_"实际计算用量",langid)_PackQty_..%Translate("oeorder.oplistcustom.new.csp",",是否自动修正？",langid)
                        s CallBackFunParams=CallBackFunParams_";"_PackQty_";"_OrderSum
                        s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"ReSetPackQty1",CallBackFunParams)
                    }
                }else{
                    s NeedChange=1
                    if (IsNotNeedChangeFlag= "Y"){
                        s NeedChange=0
                        if (OldOrderPackQty'=PackQty)&&(OldOrderPackQty'=""){
                            //s NeedChange=1
                            //放到前台去做赋值操作
                            s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 当前医嘱用量",langid)_OldOrderPackQty_..%Translate("oeorder.oplistcustom.new.csp",$S((OldOrderPackQty<PackQty):"小于",1:"大于")_"实际计算用量",langid)_PackQty_..%Translate("oeorder.oplistcustom.new.csp",",是否自动修正？",langid)
                            s CallBackFunParams=CallBackFunParams_";"_PackQty_";"_OrderSum
                            s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"ReSetPackQty1",CallBackFunParams)
                        }
                    }
                    if (NeedChange=1){
                        s CalPackArr("OrderPackQty")=PackQty
                        s CalPackArr("OrderSum")=$FN(OrderSum,"",4)
                    }
                }
            }else{
                if ($G(BaseDoseQtySum)="") s BaseDoseQtySum=1
                s OrderSum = (OrderPrice/ConFac) * BaseDoseQtySum
                s OrderSum = $FN(OrderSum,"",4)
                s CalPackArr("OrderBaseQty")=BaseDoseQty
                s CalPackArr("OrderBaseQtySum")=BaseDoseQtySum
                s CalPackArr("OrderSum")=$FN(OrderSum,"",4)
                ;取药和出院带药默认不按整包装开时，如果用户还是录入了数量，之后再修改频次或单次剂量，数量是否需要继续调整
                if (OldOrderPackQty=""){
                    s PackQty=""
                }
                s CalPackArr("OrderPackQty")=PackQty
            }
        }elseif (OrderPriorCode="NORM"){  //(CureItemFlag=1)&&
            ;住院临时也允许录入单次剂量，所以这里需要计算数量
            /*if (+OldOrderPackQty>0)&&(OrderPackQtyStyle =1){
	        	s PackQty=OldOrderPackQty    
	        }*/
            s OrderSum = OrderPrice * PackQty
            s CalPackArr("OrderBaseQty")=BaseDoseQty
            s CalPackArr("OrderBaseQtySum")=BaseDoseQtySum
            if ((OrderType '= "R")||(OrderPackQtyStyle =1))&&(IsNotNeedChangeFlag'= "Y"){
                s CalPackArr("OrderPackQty")=PackQty
                s CalPackArr("OrderSum")=$FN(OrderSum,"",4)
            }else{
		        //自备药医嘱不计入总金额
		        if ((OrderPriorCode '= "OM") && (OrderPriorCode '= "OMST")) {
			        s OrderSum=$CASE(+PackQty,0:(OrderPrice/ConFac) * BaseDoseQtySum,: PackQty*OrderPrice)
			        s CalPackArr("OrderSum")=$FN(OrderSum,"",4)
		        }
	        }
        }elseif ((OrderPriorCode="OM")||(OrderPriorCode="OMST")) { //&&(OrderType="R") //(OldOrderPackQty'="")||
            //如果已经有整包装或者是自备药医嘱则不用去计算金额
        }else {
            if ($G(BaseDoseQtySum)="") s BaseDoseQtySum=1
            s OrderSum = (OrderPrice/ConFac) * BaseDoseQtySum
            s OrderSum = $FN(OrderSum,"",4)
            s CalPackArr("OrderBaseQty")=BaseDoseQty
            s CalPackArr("OrderBaseQtySum")=BaseDoseQtySum
            //非药品长期医嘱且非长嘱才改变数量
            if ((OrderType '= "R")||(OrderPackQtyStyle =1))&&(IsNotNeedChangeFlag'= "Y"){
                s CalPackArr("OrderPackQty")=PackQty
                s CalPackArr("OrderSum")=$FN(OrderSum,"",4)
            }
        }
    } else {
        if (PackQty <= 0)&&(SetOrderPackQtyValue'="") { s PackQty = 1 }
        if (SetOrderPackQtyValue="")&&(PackQty="")&&(BaseDoseQtySum'=""){
            //门诊静配的医嘱，按照总剂量计算金额
            s OrderSum = (OrderPrice/ConFac) * BaseDoseQtySum
        }else{
            s OrderSum = OrderPrice * PackQty
        }
        s OrderSum = $FN(OrderSum,"",4)
        s NeedChange=1
        if (IsNotNeedChangeFlag = "Y"){
            s NeedChange=0
            if (OldOrderPackQty'=PackQty)&&(OldOrderPackQty'=""){
                //s NeedChange=1
                s CallBackFunParams=OrderName_..%Translate("oeorder.oplistcustom.new.csp"," 当前医嘱用量",langid)_OldOrderPackQty_..%Translate("oeorder.oplistcustom.new.csp",$S((OldOrderPackQty<PackQty):"小于",1:"大于")_"实际计算用量",langid)_PackQty_..%Translate("oeorder.oplistcustom.new.csp",",是否自动修正？",langid)
                s CallBackFunParams=CallBackFunParams_";"_PackQty_";"_OrderSum_";"_BaseDoseQty_";"_BaseDoseQtySum
                s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"ReSetPackQty2",CallBackFunParams)
                ;计算原来的价格
                if OldOrderPackQty'=""{
                    s OrderSum=OrderPrice * OldOrderPackQty
                }
            }
        }
        if (NeedChange=1){
            s CalPackArr("OrderPackQty")=PackQty
        }
        s CalPackArr("OrderBaseQty")=BaseDoseQty
        s CalPackArr("OrderBaseQtySum")=BaseDoseQtySum
        s CalPackArr("OrderSum")=$FN(OrderSum,"",2)
    }
    if ($G(CalPackArr("OrderBaseQty"))'=""){
        s CalPackArr("OrderBaseQty")=$FN(CalPackArr("OrderBaseQty"),"N")
    }
    if ($G(CalPackArr("OrderBaseQtySum"))'=""){
        s CalPackArr("OrderBaseQtySum")=$FN(CalPackArr("OrderBaseQtySum"),"N")
    }
    if ($G(CalPackArr("OrderPackQty"))'=""){
        s CalPackArr("OrderPackQty")=$FN(CalPackArr("OrderPackQty"),"N")
    }

    s CalPackArr("CallBackFunStr")=CallBackFunStr
    
    s CalPackJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.CalPackArr)
    q CalPackJson
SetDefQty
    s PackQty=OldOrderPackQty
    if (PackQty = "")&&(OrderDoseQty'=""){
        s convFac=##class(appcom.OEDispensing).convFac(OrderARCIMRowid,OrderDoseUOMRowid)
        s PackQty=OrderDoseQty*convFac
    }
    if (PackQty = "") s PackQty = 1
    s BaseDoseQtySum=PackQty
    s BaseDoseQty=""
	Q
}

/// w ##class(web.DHCOEOrdItemView).GetOrderLocalInfusionQty("3087||1",28,17,"",2,"","2019-05-22")
/// 门诊输液次数
ClassMethod GetOrderLocalInfusionQty(OrderARCIMRowid, OrderFreqRowid, OrderInstrRowid, OrderDurRowid, OrderFirstDayTimes, OrderFreqDispTimeStr, OrderStartDate, CurLogonHosp As %String = "") As %String
{
    s ^tempscl("GetOrderLocalInfusionQty")=OrderARCIMRowid_","_OrderFreqRowid_","_OrderInstrRowid_","_OrderDurRowid_","_OrderFirstDayTimes_","_OrderFreqDispTimeStr_","_OrderStartDate_","_CurLogonHosp
    q:(OrderFreqRowid="")||(OrderARCIMRowid'["||") ""   ;||(OrderDurRowid="")
    s ItemCatRowid=$p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)
    s OrderType=$P(^ARC("IC",ItemCatRowid),"^",7)
    s OrderFreqFactor=$P($g(^PHCFR(OrderFreqRowid)),"^",2)
    i (+OrderFreqFactor=0) s OrderFreqFactor=1
    s WeekFlag=$P(^PHCFR(OrderFreqRowid),"^",9)
    s OrderFreqInterval=$P($g(^PHCFR(OrderFreqRowid)),"^",5)
    i (+OrderFreqInterval=0) s OrderFreqInterval=1
    s IntervalUnit=$P($g(^PHCFR(OrderFreqRowid)),"^",14)	;间隔单位
    i IntervalUnit="H"{
        s OrderFreqFactor=24/OrderFreqInterval
        s:OrderFreqFactor#1>0 OrderFreqFactor=OrderFreqFactor\1+1
        s OrderFreqInterval=OrderFreqInterval\24
        i (+OrderFreqInterval=0) s OrderFreqInterval=1
    }
    s OrderDurFactor=+$P($g(^PHCDU(+OrderDurRowid)),"^",2)
    i (+OrderDurFactor=0) s OrderDurFactor=1
    s OrderLocalInfusionQty=""
    if (OrderType = "R") {
        s CFLocalInfusionInstrStr = ##Class(web.DHCDocOrderCommon).GetLocalInfusionInstr(CurLogonHosp)
        if (("^"_CFLocalInfusionInstrStr_"^")[("^"_OrderInstrRowid_"^")) {
            if (WeekFlag="Y"){
                s OrderDurFactor = OrderDurFactor
            }else{
                s convert = OrderDurFactor\OrderFreqInterval
                s fact = OrderDurFactor#OrderFreqInterval
                if (fact > 0) {
                    s fact = 1
                } else {
                    s fact = 0
                }
                s OrderDurFactor = convert+fact
            }
            if (OrderFreqDispTimeStr '= "") {
                s OrderLocalInfusionQty = ..GetCountByFreqDispTime(OrderFreqDispTimeStr, OrderStartDate, OrderDurFactor,OrderFirstDayTimes)
            } else {
                if (OrderFirstDayTimes'=""){
                    s OrderLocalInfusionQty = OrderFreqFactor* (OrderDurFactor-1)+(OrderFirstDayTimes)
                }else{
                   s OrderLocalInfusionQty = OrderFreqFactor * OrderDurFactor
                }
            }
        }
    }
    q OrderLocalInfusionQty
}

/// 根据频次 疗程 开始时间，计算用药次数
ClassMethod GetCountByFreqDispTime(FreqDispTimeStr, StartDateStr, DurFactor, OrderFirstDayTimes) As %String
{
    s count = 0
    
    s StartDate=..%ZDH($P(StartDateStr," ",1))
    //s StartTime=$P(StartDateStr," ",2)
    //s StartTime=..%ZTH(StartTime)
    for j = 0:1:(DurFactor-1){
        s TempDate = StartDate+j
        s TempDateWeek = $ZD(TempDate,10)
        if ((OrderFirstDayTimes>=0)&&(TempDate=StartDate)&&(OrderFirstDayTimes'="")){
        //if (TempDate=StartDate){
            s count = count + OrderFirstDayTimes
        }else{
            for i=1:1:$L(FreqDispTimeStr,$C(1)) {
                s ArrData = $P(FreqDispTimeStr,$C(1),i)
                s DispTime = $P(ArrData,$C(2),1)
                s DispWeek = $P(ArrData,$C(2),2)
                /*
                if (TempDate=StartDate)&&(StartTime<..%ZTH(DispTime)){
                    continue
                }
                */
                if (DispWeek'=""){
                    //周频次医嘱
                    if (DispWeek = TempDateWeek) { s count = count + 1 }
                    if ((DispWeek = 7) && (TempDateWeek = 0)) { s count = count + 1 }
                }else{
                       //不规则分发时间医嘱
                       s count = count + 1
                }
            }
        }
    }

    q count
}

ClassMethod SplitOrderPriorRowid(OrderPriorRowid) As %String
{
    Q:OrderPriorRowid="" ""
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    s PriorFlag=##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid)
    s OrderPriorRemarksRowID=""
    if (OrderPriorCode="OM")||(OrderPriorCode="OMST"){
        s OrderPriorRemarksRowID="OM"
        i (PriorFlag=1){
            s OrderPriorRowid=$O(^OECPR(0,"Code","S",0))
        }else{
            s OrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
        }
    }elseif (OrderPriorCode="OMLSZT")||(OrderPriorCode="OMCQZT"){
        s OrderPriorRemarksRowID="ZT"
        i (PriorFlag=1){
            s OrderPriorRowid=$O(^OECPR(0,"Code","S",0))
        }else{
            s OrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
        }
    }elseif (OrderPriorCode="ONE"){
        s OrderPriorRemarksRowID="ONE"
        i (PriorFlag=1){
            s OrderPriorRowid=$O(^OECPR(0,"Code","S",0))
        }else{
            s OrderPriorRowid=$O(^OECPR(0,"Code","NORM",0))
        }
    }
    s OrderPriorRemarks=$CASE(OrderPriorRemarksRowID,"OM":"自备药","ZT":"嘱托","ONE":"取药医嘱",:"")
    s OrderPrior=$P(^OECPR(OrderPriorRowid),"^",2)
    
    q OrderPriorRowid_"^"_OrderPrior_"^"_OrderPriorRemarksRowID_"^"_OrderPriorRemarks
}

ClassMethod ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks)
{
    Q:OrderPriorRowid="" ""
    s OrderPriorCode=$P(^OECPR(OrderPriorRowid),"^",1)
    if (OrderPriorRemarks="PRN") {
        s OrderPriorRowid=$O(^OECPR(0,"Code","PRN",0))
    }elseif (OrderPriorRemarks="ONE"){
        s OrderPriorRowid=$O(^OECPR(0,"Code","ONE",0))
    }elseif (OrderPriorRemarks="OM"){
        if (OrderPriorCode'="S"){
            s OrderPriorRowid=$O(^OECPR(0,"Code","OM",0))
        }else{
            s OrderPriorRowid=$O(^OECPR(0,"Code","OMST",0))
        }
    }elseif (OrderPriorRemarks="ZT"){
        if (OrderPriorCode'="S"){
            s OrderPriorRowid=$O(^OECPR(0,"Code","OMLSZT",0))
        }else{
            s OrderPriorRowid=$O(^OECPR(0,"Code","OMCQZT",0))
        }
    }elseif (OrderPriorRemarks="OUT"){
        s OrderPriorRowid=$O(^OECPR(0,"Code","OUT",0))
    }
   
    q OrderPriorRowid
}

/// 目前前台只有CheckAfterCheckMethod识别了OrdRowIndex
ClassMethod GetCallBackFunStr(CallBackFunStr As %String, ExpandCallBackFun As %String, ExpandCallBackParams As %String, OrdRowIndex As %String = "") As %String
{
    if (CallBackFunStr'=""){
        s CallBackFunStr=CallBackFunStr_$C(2)_$Replace(ExpandCallBackFun,$C(2),$C(1))_"^"_$Replace(ExpandCallBackParams,$C(2),$C(1))_"^"_$Replace(OrdRowIndex,$C(2),$C(1))
    }else{
        s CallBackFunStr=$Replace(ExpandCallBackFun,$C(2),$C(1))_"^"_$Replace(ExpandCallBackParams,$C(2),$C(1))_"^"_$Replace(OrdRowIndex,$C(2),$C(1))
    }
    q CallBackFunStr
}

/// 去除CallBackFunStr里面的单个方法
ClassMethod DelCallBackFunStr(CallBackFunStr As %String, ExpandCallBackFun As %String)
{
    s NewCallBackFunStr=""
    s len=$L(CallBackFunStr,$C(2))
    for i=1:1:len{
        s oneCallBackFun=$P(CallBackFunStr,$C(2))
        continue:oneCallBackFun=""
        s FunName=$P(oneCallBackFun,"^",1)
        if FunName'=ExpandCallBackFun{
            if NewCallBackFunStr="" s NewCallBackFunStr=oneCallBackFun
            else  s NewCallBackFunStr=NewCallBackFunStr_$C(2)_oneCallBackFun
        }
    }
    s CallBackFunStr=NewCallBackFunStr
    Q NewCallBackFunStr
}

/// 计算首日次数
/// 增加返回:"首日次数^是否可以修改(Y可以修改)^可用首日次数串" 
/// w ##class(web.DHCOEOrdItemView).GetOrderFirstDayTimes("781","2323||1","29","5","2021-12-29 20:30:51","","12:00"_$c(2,2)_"29_2"_$c(1)_"16:00"_$c(2,2)_"29_3")
ClassMethod GetOrderFirstDayTimes(EpisodeID As %String, OrderARCIMRowid As %String, OrderFreqRowid As %String, OrderPriorRowid As %String, OrderStartDate As %String, LinkedMasterOrderPriorRowid As %String, OrderFreqDispTimeStr As %String = "", CurLogonHosp As %String = "", OrderRecDepRowid As %String = "", OldOrderFirstDayTimes As %String = "") As %String
{
    s:EpisodeID=243 ^tempscl("GetOrderFirstDayTimes")=$LB(EpisodeID,OrderARCIMRowid,OrderFreqRowid,OrderPriorRowid,OrderStartDate,LinkedMasterOrderPriorRowid,OrderFreqDispTimeStr,CurLogonHosp,OrderRecDepRowid,OldOrderFirstDayTimes)
    Q:(OrderFreqRowid="") "^Y^"
    s FreqCode=$ZCVT($p(^PHCFR(OrderFreqRowid),"^",1),"U")
    ;ONCE ST PRN 首日默认为空不能修改
    if (FreqCode="ST")||(FreqCode="ONCE")||(FreqCode="PRN"){	
        Q "^N^"
    }
    s WeekFlag=$P(^PHCFR(OrderFreqRowid),"^",9)
    s OPNoDelayExe=$P(^PHCFR(OrderFreqRowid),"^",8)
    s IPNoDelayExe=$P(^PHCFR(OrderFreqRowid),"^",10)
    s FreeTimeFreqFlag=$P(^PHCFR(OrderFreqRowid),"^",13)
    s IntervalTime=$p(^PHCFR(OrderFreqRowid),"^",5) ;频次间隔时间	$p(FreqStr,"^",12)
    s IntervalUnit=$P(^PHCFR(OrderFreqRowid),"^",14)	;间隔单位
    s:IntervalUnit="" IntervalUnit="D"
    s PAAdmType=$CASE(EpisodeID,"":"I",:##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID))
    s NoDelayExe=$CASE(PAAdmType,"I":IPNoDelayExe,:OPNoDelayExe)
    s CurLogonHosp=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(CurLogonHosp)
    s OrderStartTime =..%ZTH($P(OrderStartDate," ",2))
    s:OrderStartTime="" OrderStartTime=..%SysTime()
    s OrderStartDate =..%ZDH($P(OrderStartDate," ",1))
    s:OrderStartDate="" OrderStartDate=..%SysDate()
    ;分离自定义时间与周信息
    s OrderFreqWeekStr="",OrderFreqFreeTimeStr=""
    for i=1:1:$L(OrderFreqDispTimeStr,$C(1)){
        s ArrData=$P(OrderFreqDispTimeStr,$C(1),i)
        continue:ArrData=""
        s ArrData=$ZCVT(ArrData,"I","HTML")
        s DispTime=..%ZTH($P(ArrData,$C(2),1))
        s DispWeek=$P(ArrData,$C(2),2)
        s OrderFreqWeekStr=OrderFreqWeekStr_DispWeek
        i OrderFreqFreeTimeStr="" s OrderFreqFreeTimeStr=DispTime
        e  s OrderFreqFreeTimeStr=OrderFreqFreeTimeStr_"|"_DispTime 
    }
    if (##class(appcom.OEOrdItem).ISLongOrderPrior(OrderPriorRowid)){
        s FirstTimesType=..%GetConfig("FirstTimes",CurLogonHosp)
    }else{
        s FirstTimesType=..%GetConfig("OPFirstTimes",CurLogonHosp)
    }
    
    ;取分发时间列表
    d ##class(DHCDoc.Order.Exec).GetFreqDispTimeList(OrderFreqRowid,OrderFreqFreeTimeStr,CurLogonHosp,OrderARCIMRowid,.ExecTimeList)
    ;固定间隔时间的频次 不考虑配置 直接根据开始时间计算 不可修改
    if (IntervalTime>0)&&((IntervalUnit'="D")||((IntervalUnit="D")&&'$D(ExecTimeList))){
        d ##class(DHCDoc.Order.Exec).GetIntervalDTList(OrderStartDate,OrderStartTime,IntervalTime,IntervalUnit,1,.ExecList)
        s FirstTimeStr=..GetOrdFirstTimeStr(+$G(ExecList),+$G(ExecList))
        Q +$G(ExecList)_"^N^"_FirstTimeStr
    }
    ;周频次如果不包含开始日期 则首日为0 不可修改
    if (WeekFlag="Y"){
        s DateWeek=$ZD(OrderStartDate,10)
        s:DateWeek=0 DateWeek=7
        if OrderFreqWeekStr'[DateWeek {
	        s FirstTimeStr=..GetOrdFirstTimeStr(0,0)
        	Q "0^N^"_FirstTimeStr
        }
    }
    s CalCount=0
    ;静配医嘱 首日不可修改判断
    s DosingRet=..GetDosingDateTime(OrderARCIMRowid,OrderRecDepRowid,OrderPriorRowid,CurLogonHosp)
    s EditFlag=$P(DosingRet,"^",4)
    s:EditFlag="" EditFlag="Y"
    s AllCount=$G(ExecTimeList)
    if (OldOrderFirstDayTimes'="")&&(OldOrderFirstDayTimes<AllCount){
        s CalCount=OldOrderFirstDayTimes
    }elseif (NoDelayExe="Y")||(FirstTimesType="All")||(EpisodeID=""){
        s CalCount=AllCount
    }elseif (FirstTimesType="Non"){
        s CalCount=0
    }elseif (FirstTimesType="CalcBySttTime"){
        for i=1:1:$G(ExecTimeList){
            s Time=ExecTimeList(i)
            if Time>=OrderStartTime{
                s CalCount=CalCount+1
            }
        }
    }
    if 'CalCount&&(EditFlag="Y")&&##class(DHCDoc.Order.Common).IsCNFreq(OrderFreqRowid){
	    s CalCount=1	;草药如果首日为0,计算为1
    }
    s FirstTimeStr=..GetOrdFirstTimeStr(AllCount,CalCount)
    Q CalCount_"^"_EditFlag_"^"_FirstTimeStr
}

ClassMethod GetOrdFirstTimeStr(AllCount, CalCount) As %String
{
	s FirstTimeStr=""
	Q:AllCount="" FirstTimeStr
	for len=0:1:AllCount{
		s Selected="N"
		s:len=CalCount Selected="Y"
		s OneFirstTimeStr=len_$c(1)_len_$c(1)_Selected
		i FirstTimeStr'="" s FirstTimeStr=FirstTimeStr_$c(2)_OneFirstTimeStr
		e  s FirstTimeStr=OneFirstTimeStr
	}
	Q FirstTimeStr
}

ClassMethod GetWeekFreqStartDate(OrderStartDateStr As %String, OrderFreqDispTimeStr As %String) As %String
{
    s ^Tempscl("GetWeekFreqStartDate")=OrderStartDateStr_","_OrderFreqDispTimeStr
    s OrderFreqWeekStr=##Class(web.DHCOEOrdItem).GetOrderFreqWeekStr(OrderFreqDispTimeStr)
    if (OrderFreqWeekStr=""){
        q OrderStartDateStr
    }
    s OrderStartDate = $P(OrderStartDateStr," ",1)
    if $l(OrderStartDate,"-")>1 s StartDate=$zdh(OrderStartDate,3)
    if $l(OrderStartDate,"/")>1 s StartDate=$zdh(OrderStartDate,4)
    if OrderStartDate="" s StartDate=..%SysDate()
    s StartTime = $P(OrderStartDateStr," ",2)
    s:StartTime[":" StartTime=..%ZTH(StartTime)
    if StartTime="" s StartTime=..%SysTime()
    
    Set CurrWeek=$ZD(StartDate,10)
    If CurrWeek=0 Set CurrWeek=7
    Set nextweek="",minweek="",inter=0
    for i=1:1:$L(OrderFreqWeekStr,"|"){
        Set week=$P(OrderFreqWeekStr,"|",i)
        continue:(week="")
        if minweek="" s minweek=week
        else  if minweek>week Set minweek=week 
        continue:week<CurrWeek
        i nextweek="" s nextweek=week
        e  i nextweek>week s nextweek=week
    }
    
    if nextweek="" s nextweek=minweek
    if nextweek>CurrWeek Set inter=nextweek-CurrWeek
    if nextweek<CurrWeek Set inter=(7-CurrWeek)+nextweek
    s StartDate=StartDate+inter	
    
    s MinTime=""
    for i=1:1:$L(OrderFreqDispTimeStr,$C(1)){
        s ArrData=$P(OrderFreqDispTimeStr,$C(1),i)
        s Time=$P(ArrData,$C(2),1)
        if (Time=""){
            continue
        }
        s Time=..%ZTH(Time)
        if (MinTime>Time)||(MinTime=""){
            s MinTime=Time
        }
    }
    if (inter>0){
        if (StartTime>MinTime)&&(MinTime'=""){
            s StartTime=..%ZT(MinTime)
        }
    }
    
    
    if $l(OrderStartDate,"-")>1 {
        s OrderStartDate=$zd(StartDate,3)
    }elseif $l(OrderStartDate,"/")>1 {
        s OrderStartDate=$zd(StartDate,4)
    }else{
        s DateFormat=##Class(websys.Conversions).DateFormat()
        s OrderStartDate=$zd(StartDate,DateFormat)
    }
    
    i StartTime'[":" s StartTime=..%ZT(StartTime)
    s $P(OrderStartDateStr," ",1)=OrderStartDate
    s $P(OrderStartDateStr," ",2)=StartTime
    q OrderStartDateStr
}

/// 获取频次的分发时间列表
ClassMethod GetFreqFreqDispTimeStr(OrderFreqRowid As %String, OrderFreqDispTimeStr As %String = "") As %String
{
    s ret=""
    Q:OrderFreqRowid="" ret
    k FreqDispTimeArr($j)
    s FreeTimeFreqFlag=$P(^PHCFR(OrderFreqRowid),"^",13)
    if (FreeTimeFreqFlag="Y"){
        for i=1:1:$L(OrderFreqDispTimeStr,$C(1)){
            s ArrData=$P(OrderFreqDispTimeStr,$C(1),i)
            s ArrData=$ZCVT(ArrData,"I","HTML")
            s DispTime=$P(ArrData,$C(2),1)
            s PHCDTRowID=$P(ArrData,$C(2),3)
            s PHCDTTime=..%ZTH(DispTime)
            s DispTime=..%ZT(PHCDTTime,1)
            continue:PHCDTTime=""
            s FreqDispTimeArr($j,PHCDTTime)=PHCDTRowID_"$"_DispTime
        }
    }else{
        s PHCDTChildSub=0
        for {
            s PHCDTChildSub=$o(^PHCFR(+OrderFreqRowid,"DT",PHCDTChildSub)) Q:PHCDTChildSub=""
            s PHCDTTime=$p(^PHCFR(+OrderFreqRowid,"DT",PHCDTChildSub),"^",1)
            s DispTime=..%ZT(PHCDTTime,1)
            s FreqDispTimeArr($j,PHCDTTime)=OrderFreqRowid_"_"_PHCDTChildSub_"$"_DispTime
        }
    }
    s DispTime="" 
    for {
        s DispTime=$O(FreqDispTimeArr($j,DispTime))
        Q:DispTime=""
        i ret="" s ret=FreqDispTimeArr($j,DispTime)
        e  s ret=ret_"!"_FreqDispTimeArr($j,DispTime)
    }
    Q ret
}

ClassMethod GetInstrDefSpeedRateUnit(InstrRowId As %String, CurLogonHosp As %String = "") As %String
{
    Q:InstrRowId="" ""
    ;滴速用法
    s DrippingSpeedInstr=..%GetConfig("DrippingSpeedInstr",CurLogonHosp)
    if (("^"_DrippingSpeedInstr_"^")[("^"_InstrRowId_"^")) {
        Set CFUseHospSepInstrArcim=1 //$$getconfignode^DHCDocConfig("UseHospSepInstrArcim")
        if CFUseHospSepInstrArcim=1 {
            if (CurLogonHosp'=""){
                s HospitalRowid=CurLogonHosp
            }else{
                s HospitalRowid=%session.Get("LOGON.HOSPID")
            }
            s CFInstrRowId=InstrRowId_"||"_HospitalRowid
        }else{
            s CFInstrRowId=InstrRowId
        }
        s InstrDefSpeedRateUnit=$g(^DHCDocConfig("InstrDefSpeedRateUnit",CFInstrRowId))
        if (InstrDefSpeedRateUnit'="")&&('$d(^OEC("SFR",InstrDefSpeedRateUnit))) s InstrDefSpeedRateUnit=""
        Q InstrDefSpeedRateUnit
    }
    Q ""
}

/// 获取全部用法默认滴速的json格式
/// w ##class(web.DHCOEOrdItemView).GetAllInstrDefSpeedRateUnit(3)
ClassMethod GetAllInstrDefSpeedRateUnit(HospID As %String = "")
{
    s HospID=##class(DHCDoc.Common.Hospital).GetCurrentSYSHospitalId(HospID)
    s CFInstrNode=""
    f {
        s CFInstrNode=$o(^DHCDocConfig("InstrDefSpeedRateUnit",CFInstrNode))
        q:CFInstrNode=""
        s CFInstrRowId=$p(CFInstrNode,"||",1)
        s CFInstrHospId=$p(CFInstrNode,"||",2)
        continue:(HospID'="")&&(HospID'=CFInstrHospId)
        s InstrDefSpeedRateUnit=$g(^DHCDocConfig("InstrDefSpeedRateUnit",CFInstrNode))
        continue:(InstrDefSpeedRateUnit="")||('$d(^OEC("SFR",InstrDefSpeedRateUnit)))
        s InstrDefSpeedRateUnit("Z"_CFInstrRowId,"id")=InstrDefSpeedRateUnit
        s InstrDefSpeedRateUnit("Z"_CFInstrRowId,"desc")=$p(^OEC("SFR",InstrDefSpeedRateUnit),"^",2)
    }
    s ItemCongeriesJson=##Class(DHCDoc.Util.FromJSON).GetArrJson(.InstrDefSpeedRateUnit)
    q ItemCongeriesJson
}

/// 获取手术列表对应手术医生列表
/// w ##class(web.DHCOEOrdItemView).GetOPSurgeonDocStr("214||4","214||4||1",12177)
ClassMethod GetOPSurgeonDocStr(AnaesthesiaID As %String, OrderOperationCode As %String, UserID As %String, langid As %String = "") As %String
{
    k OPSurgeonDocArr
    if langid="" Set langid=..%LanguageID()
    s OPSurgeonDocStr="",DefaultDocId=""
    s DoctorName=""
    s DoctorID=##class(web.SSUser).GetDefaultCareProvider(UserID)
    if (DoctorID'="")  s DoctorName=$p($g(^CTPCP(+DoctorID,1)),"^",2)
    Set DoctorName= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",DoctorName,langid)
    if (AnaesthesiaID="") {
        if (DoctorID'="") Q DoctorName_$C(1)_DoctorID_$C(1)_"Y"
        Q ""
    }
    s admId=$p(AnaesthesiaID,"||",1)
    s anaSub=$p(AnaesthesiaID,"||",2)
    s anaopSub=""
    for {
        s anaopSub=$O(^OR(admId,"ANA",anaSub,"OP",anaopSub)) q:(anaopSub="") 
        s docdr=$P(^OR(admId,"ANA",anaSub,"OP",anaopSub),"^",8)      		;ANAOP_Surgeon_DR   手术医师
        i docdr'="" {
            s surgeonDesc=##class(web.DHCANOPCom).GetNameById(docdr)
            Set surgeonDesc= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",surgeonDesc,langid)
            s Default="N"
            /*if (OrderOperationCode'="")&&(OrderOperationCode=(AnaesthesiaID_"||"_anaopSub)) {
                s DefaultDocId=docdr
                s Default="Y"
            }*/
            continue:(DoctorID'="")&&(docdr=DoctorID)
            if ('$d(OPSurgeonDocArr(docdr))) {
                s OPSurgeonDocArr(docdr)=surgeonDesc_$C(1)_docdr_$C(1)_Default
            }
        }
        s as=0 
        for{
            s as=$O(^OR(admId,"ANA",anaSub,"OP",anaopSub,"ASS",as)) q:(as="")
            s asdr=$P(^OR(admId,"ANA",anaSub,"OP",anaopSub,"ASS",as),"^",1)
            continue:asdr=""
            continue:(DoctorID'="")&&(asdr=DoctorID)
            s asname=##class(web.DHCANOPCom).GetNameById(asdr)
            Set asname= ##class(User.CTCareProv).GetTranByDesc("CTPCPDesc",asname,langid)
            if ('$d(OPSurgeonDocArr(asdr))) {
                s OPSurgeonDocArr(asdr)=asname_$C(1)_asdr_$C(1)_"N"
            }
        }
    }
    if (DoctorID'="") s OPSurgeonDocStr=DoctorName_$C(1)_DoctorID_$C(1)_"Y"
    if ($d(OPSurgeonDocArr)) {
        s docdr=0
        for {
            s docdr=$o(OPSurgeonDocArr(docdr)) Q:docdr=""
            if (OPSurgeonDocStr="") {
                s OPSurgeonDocStr=$g(OPSurgeonDocArr(docdr))
            }else{
                s OPSurgeonDocStr=OPSurgeonDocStr_"^"_$g(OPSurgeonDocArr(docdr))
            }
        }
    }
    Q OPSurgeonDocStr
}

/// 判断用户是否有直接审核权限
ClassMethod GetOrderDirectEntryAuth(ByRef ParamArr, ByRef BaseParamArr, ExpStr As %String) As %String
{
    s EpisodeID=BaseParamArr("Adm")
    s SessionStr=$G(BaseParamArr("SessionStr"))
    s OrderARCIMRowid=ParamArr("OrderARCIMRowid")
    s OrderAntibApplyRowid=$P(ExpStr,"^",1)
    s KSSCopyFlag=$P(ExpStr,"^",2)
    s KSSAuditFlag=$CASE(KSSCopyFlag,"KSS":"1",:"0")
    s USERID=$P(SessionStr,"^",1)
    s HOSPID=$P(SessionStr,"^",4)
    s AuthDetails=""
    s Auth="Y"
    s PAAdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    //获取抗菌药物授权信息
    s ret=##class(DHCAnt.KSS.MainBusiness).HasAntAuth(USERID, OrderARCIMRowid, PAAdmType, HOSPID, EpisodeID,KSSAuditFlag)
    //0:没有权限，1：有权限，2：没有权限但已完申请流程，且申请流程在有效时间内，3：权限为越级，4：权限为申请单
    s AntAuth=$P(ret,$C(1))
    if (AntAuth="0")||(AntAuth="4"){
        s Auth="N"
        if (AntAuth="0"){
            if (AuthDetails=""){
                s AuthDetails="AntNoAuth"
            }else{
                s AuthDetails=AuthDetails_","_"AntNoAuth"
            }
        }elseif (AntAuth="4"){
            if (AuthDetails=""){
                s AuthDetails="AntAuth"
            }else{
                s AuthDetails=AuthDetails_","_"AntAuth"
            }
        }
    }elseif (AntAuth="1")||(AntAuth="3"){
        s Auth="Y"
    }elseif (AntAuth="2"){
        s Auth="Y"
        //抗菌药物已走完审核流程
        if (AuthDetails=""){
            s AuthDetails="AntAuthAdopt"
        }else{
            s AuthDetails=AuthDetails_","_"AntAuthAdopt"
        }
    }
    
    q Auth_"^"_AuthDetails
}

ClassMethod GetOrderChronicDiagStr(Adm As %String, ArcimCode As %String, OrderBillTypeRowid As %String, langid As %String = "") As %String
{
    s $ZT="GetOrderChronicDiagStrErr"
    Q:'##class(DHCDoc.Util.Class).IsValidMethodName("insuqc.service.ServicePort","GetPatDiagsByArcItm") ""
    //获取医嘱项慢病信息列表
    ///慢特病信息1|慢特病信息2|慢特病信息3....
    ///病种编码^病种描述^病种类型
    s:langid="" langid=..%LanguageID()
    s PatDiagsStr=##class(insuqc.service.ServicePort).GetPatDiagsByArcItm(Adm,ArcimCode,OrderBillTypeRowid,"",langid)
    
    if (PatDiagsStr=""){
        q ""
    }
    s OrderChronicDiagStr=""_$C(1)_""
    for i=1:1:$L(PatDiagsStr,"|"){
        s OnePatDiagsStr=$P(PatDiagsStr,"|",i)
        s OneChronicDiagCode=$P(OnePatDiagsStr,"^",1)
        s OneChronicDiagDesc=$P(OnePatDiagsStr,"^",2)
        s OrderChronicDiagStr=OrderChronicDiagStr_$C(2)_OneChronicDiagCode_$C(1)_OneChronicDiagDesc
    }
    q OrderChronicDiagStr
GetOrderChronicDiagStrErr
    Q ""
}

ClassMethod GetOrderOrderDIACatStr(EpisodeID As %String, ArcimRowid As %String, OrderBillTypeRowid As %String) As %String
{
    s MatchingDiagnosCatStr=""
	Set langid=..%LanguageID()
    s HospitalID=##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
    s AdmType=##class(web.DHCDocOrderEntry).GetPAAdmType(EpisodeID)
    s MrAdmRowid=$p($g(^PAADM(EpisodeID)),"^",61)
    s EPDiagnosCat=##class(web.DHCDocOrderCommon).GetEPDiagnosCat(AdmType,OrderBillTypeRowid,MrAdmRowid,HospitalID)
    i EPDiagnosCat'="" {
        s TempStr=##class(web.DHCDocOrderCommon).GetDiagnosCatArcim(EPDiagnosCat,ArcimRowid)
        s EPDurationInfo=$p(TempStr,$c(1),1)
        if (EPDurationInfo'="") s MatchingDiagnosCatStr=$p(TempStr,$c(1),2)
    }
    s EPDiagnosCatStr=""
    for i=1:1:$l(MatchingDiagnosCatStr,"^") {
        s DiagnosCatRowid=$p(MatchingDiagnosCatStr,"^",i)
        continue:DiagnosCatRowid=""
        s DCDesc=$P(^DHCDiagnosCat(DiagnosCatRowid),"^",1)
		Set DCDesc= ##class(User.DHCDiagnosCat).GetTranByDesc("DCDesc",DCDesc,langid)
        i EPDiagnosCatStr="" s EPDiagnosCatStr=DiagnosCatRowid_$C(1)_DCDesc
        e  s EPDiagnosCatStr=EPDiagnosCatStr_$C(2)_DiagnosCatRowid_$C(1)_DCDesc
    }
    Q EPDiagnosCatStr
}

/// 比较单次剂量串与不规则分发时间是否匹配
ClassMethod CompareDispTimeAndDoseQty(FreqTimeDoseStr, FreqDispTimeStr) As %Boolean
{
    s len1=$L(FreqTimeDoseStr,"!")
    s len2=$L(FreqDispTimeStr,"!")
    Q:len1'=len2 0
    s flag=1
    for i=1:1:len1{
        s oneDoseStr=$P(FreqTimeDoseStr,"!",i)
        s oneTimeStr=$P(FreqDispTimeStr,"!",i)
        s flag=$P(oneDoseStr,"$",1)=$P(oneTimeStr,"$",1)
        Q:'flag
    }
    Q flag
}

}
