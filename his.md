## 修改建卡
[Code](doc/code/createCard.md)

## 医嘱录入搜索提示添加集采字段
[Code](./doc/code/orderInput.md)

## 读卡挂号建卡不重复读卡
[Code](doc/code/reg.md)

## 挂号科室搜索前缀匹配排序
web.DHCOPAdmReg.cls
[Code](./doc/code/opDeptList.md##挂号科室搜索前缀匹配排序)

## 病历浏览没有治疗记录
dhcdoc/dhcdoccure/dhcdoc.cure.applylist
查询科室和就诊科室不一致

## 卡管理卡操作查询排序
Reg.CardManagement.hui.js

[Code](./doc/code/cardListSort.md##卡管理卡操作查询排序)

## 建卡入院来源下拉框
医生站配置 -> 本地化参数设置

## 毒麻处方打印总量
oeorder.printall.js

ClassName : "web.DHCDocPrescript",
MethodName : "GetPrescInfoByOrd",

用法 1片

频率 Q12h, bid, tid

疗程 1天

BDP 医生站设置菜单 常规设置 长期医嘱首日

## 毒麻疼痛评分
dhcdoccheckpoison.csp
[Code](doc/code/hurt.md)

## 就诊号到达时间
[Code](./doc/code/admNoArriveTime.md##就诊号到达时间)

## 修改患者信息接口
[Code](./doc/code/updatePatInfo.md##修改患者信息接口)

## 生物标本库查询修改日志
[Code](./doc/code/biobank/README.md)

## 患者信息修改接口
dhcbill.ipbill.reg.csp

## 患者列表转出记录链接
d ##class(%ResultSet).RunQuery("web.DHCDocInPatientListNew", "GetChangeDeptPatList",16,18881,"currentLoc",66739,66745)

-- 电子病历维护
code null

## 医嘱备注保存医嘱套
WARG_1:web.DHCUserFavItems
WARG_2:InsertUserARCOS

WARG_1:web.DHCARCOrdSets
WARG_2:InsertItem
开始空格保存为空

## 停医嘱提示已经停止
[Code](./doc/code/stopOrder.md)


## 关联医嘱主医嘱不显示深绿色
UDHCOEOrder.List.Custom.New.js
function OrderMasterChangeHandler

[Code](./doc/code/bindOrder.md)

## 门诊诊断证明书打印
xml模板参数图片地址

## 首日回车换行
UDHCOEOrder.List.Custom.New.js
function FrequencyLookUpSelect

[Code](./doc/code/orderJump.md)

## 阿帕奇评分死亡转科出院医嘱
oeorder.oplistcustom.new.csp
UDHCOEOrder.List.Custom.New.js
[Code](./doc/code/apache.md)

## 手麻接受科室医嘱库存
##class(web.DHCOEOrdItem).SaveOrderItems(EpisodeID, oeoriStr, userId, locId, careprovId)
;是否在插入医嘱之前调用审查方法,如果在插入医嘱之前未调用CheckBeforeSave,需传入此参数(例如以此方法作为接口调用)
s IsCheckOrdItemStr=$p(ExpStr,"^",4)
s retStr=##class(web.DHCOEOrdItem).SaveOrderItems(EpisodeID,oeoriStr,userId,locId,docId,"","^^^Y")

## 诊间预约提前取号
OPAdm/Reg.hui.js
ClassName : "web.DHCRBAppointment",
MethodName : "GetAppInfo",
...//Quit:ASDate<+$h  不允许提前取号 刘亚提
...Quit:ASDate'=+$h

## 病理申请推送地址
[Code](./doc/code/pisApply.md)

## 门诊传染病报卡
[Code](./doc/code/diagnosReport.md)

## 将医嘱停止时间后的所有未执行记录变为"停止执行"状态
[Code](./doc/code/ordExecStop.md)

## 回诊 复诊
web.DHCAlloc
PatAgain

## 显示挂号职称
[Code](./doc/code/regTitle.md)

## 分诊优先患者不能取消报到
Alloc.NurseTriage.hui.js
function InitAllocListTabDataGrid()
if (row["Prior"]=="优先"){
	ChangeMenuDisable("CancleQueCheckin",true);
}

## 获取患者信息后光标跳转
[Code](./doc/code/regCursor.md)

## 医嘱氧气吸入数量显示
[Code](./doc/code/sumQty.md)

## 挂号速度慢
w ##class(web.DHCENS.BLL.Message.Method.public).SendMessageInfo("MES0072","44$#$17855606389,17631666188$#$1")
s soap=##class(web.DHCENS.BLL.Message.Soap.PUB0009Soap).%New()
;s stream=soap.HIPService(MessageCode,streams)

## 挂号调用支付接口
[Code](./doc/code/payInterface.md)

## 病理申请单Not Found
[Code](./doc/code/pisApp.md)

## 费用明细默认分页行数

安全组 安全组设置 列编辑器

## 医生预停医嘱护士补录关联医嘱同步预停时间
[Code](./doc/code/syncStopTime.md)

## 病理申请标本类型表单显示
[Code](./doc/code/pisSample.md)

## 导诊单合管打印
[Code](./doc/code/docPrint.md)

## 挂号一次三天优惠，做强制控制，三天内有非0元费用挂号，强制挂0元号
[Code](./doc/code/regCon.md)

## 	回龙观可以维护同医生、同时段、同开始时间、不同门诊的排班，且均可以生成排班记录，需在新增排班时增加提示
[Code](./doc/code/checkSchedule.md)

## PACS回传报告地址
[Code](./doc/code/pacsAdd.md)

## 住院登记加载县区
[Code](./doc/code/defaultArea.md)

## 挂号弹窗可用开关立即生效
Reg.hui.js
[Code](./doc/code/switchbox.md)

## 勾选无库存医嘱依然提示库存不足
[Code](./doc/code/checkStock.md)

## 撤销检验医嘱
web.UDHCStopOrderLook.cls
[Code](./doc/code/cancelOrder.md)

## 挂号统计增加出诊时段筛选
[Code](./doc/code/regDocLog.md)

## 整包装发药不能开长期医嘱
[Code](./doc/code/needPackQty.md)

## 检验结果显示其他人检验项目
[Code](./doc/code/report.md)

## 0元挂号计费出错
[Code](./doc/code/freeReg.md)

## 门诊日志 初诊复诊筛选条件
## 就诊次数
## 相同医生排序
[Code](./doc/code/opLocLog.md)

## 挂号筛选便民号
web.DHCOPAdmReg.cls
..S resDesc = $p(^RB("RES",RowId),"^",17)
..S groupDesc = $p(^SSU("SSGRP",GroupRowId),"^",1)
..Q:(groupDesc'["收费")&&(resDesc["便民号")

## 自助机筛选便民号
/// DHCExternalService.RegInterface.Service.SelfRegService

## 就诊登记便民号
OPDoc.RapidRegist.hui.js
w ##class(web.DHCDoc.OP.PatConfigQuery).FindDocMarkStr(22005,1)

## 滚床位费
[Code](./doc/code/bedFee.md)
d first^CHQTASKNEW(2)
床位类型 费别 全自费
床位 费用设置 附加费

## 日志
DHCDoc_Log.Common

## 医生叫号 已就诊患者叫号提示"11^队列信息不存在不能呼叫!"
[Code](./doc/code/patCall.md)

## 医嘱套明细添加医嘱lookup添加字段
<!--udhcfavitem.edit.newedit.csp HUI医嘱套明细维护-->

## 医嘱选择用法后不能填数量
特殊用法设置
外用用法: 没有疗程和单次剂量，只应用于门急诊（即选择该用法后，自动清空疗程和单次剂量）

## 医技录入医嘱提示过滤其他子类
[Code](./doc/code/subcatFilter.md)

## 调整挂号病人信息模块比例
opadm.cashierreg.show.csp
opadm.app.show.csp

## 打印病理条码问题排查
scripts/nurse/nis/HandleMethod/OrderExcute.js
scripts/dhcdoc/dhcapp/PrintBarCode.js
web.DHCDocAPPBL.cls

## 病理申请单标本信息必填
dhcdoc.dhcapp.blmapshow.js
dhcdoc.dhcapp.TCTBBPanelNew.js

#TCTSpecListNew
[Code](./doc/code/TCTBBPanelNew.js.md)

病理菜单 -> HPV申请单 -> 模板维护 -> 元素维护

## 建卡登记号作为卡号报错
scripts/UDHCCardPatInfoRegExp.js
NewEmrCard()

w ##Class(DHCDoc.Interface.Outside.ElecHealthCardService.ElecHealthCardMethods).createVmcardQRcode(^temp("createVmcardQRcode"))

## 作废医嘱
/// 作废医嘱 
/// w ##Class(LISAPP.Common.BLL.HISOrderItem).UnUseMulti("402||77","22064")

## 中药审核医嘱 中药调配费
[Code](./doc/code/CMCheck.md)

## 挂号跳转报错
[Code](./doc/code/regJump.md)

## 检查检验不控制数量的子类
[Code](./doc/code/subcatAmt.md)

## 检查核实状态
[Code](./doc/code/ekgStatus.md)

## 诊断删除日志增加诊断类型
[Code](./doc/code/diagnosLog.md)

## 结算界面上方患者信息栏增加：参保类型，参保单位
[Code](doc/code/insuType.md)

## 打印住院证
组件编辑器右键 
Component Layouts
View -> Tool Box

## 输血退费报错
[Code](./doc/code/bloodErr.md)

## 开住院证更新预约日期
/// w ##class(web.DHCDocIPBookNew).UpdateBook(^lxz("UpdateBook"))

## 门诊日志挂号日期查询，导出数据
<!--opadm.regquery.hui.csp HISUI挂号查询-->
OPAdm/RegQuery.hui.js

## 测试组 多部位医嘱计费
<!--住院患者总览csp,csp:ipdoc.patinfoview.csp-->
dhcdoc/ipdoc/InPatOrderView.js
[Code](doc/code/multiPosition.md)

## 医嘱库存不足
医嘱套单位数量维护 && 药房
s GetItemCongeriesToListMethod=##Class(websys.Page).Encrypt($lb("web.DHCOEOrdItemView.GetItemCongeriesToList"))

## 诊查费不能撤销
[Code](./doc/code/errMsg.md)

## 门诊日志
[Code](./doc/code/OPDocLog.md)

## 过敏记录
<!--过敏记录csp,csp:dhcdoc.allergyenter.csp--> 
scripts/dhcdoc/allergyenter.js
web.DHCDocAllergyEnter

## 检查申请单特殊字符
```js
let item = "%^&&<>   	' ' '";
item = item.replace(/\s/g,''); //whitespace

console.log(item);
item = item.replace(/&/g, '&amp;').replace(/\^/g, '&Hat;').replace(/'/g,'&apos;');

console.log(item);
```

## 医嘱录入
GetItemCongeries()
CreatOrdNo()
SavaOrderItems()
InsertOrderItems()
w ##class(web.DHCDocOrderCommon).GetLabSpec("3950||1",2)

## 导诊单
DHCDoc.OPDoc.TreatPrint.cls
LoadPrintItemTree()
// 门诊系统参数 是否打印导诊单
prepareHandle()
ClassName:"web.DHCDocPrescript",
MethodName:"GetXMLTemplateId",
ClassName : printmethod["class"],//"DHCDoc.OPDoc.TreatPrint",
MethodName : printmethod["method"]//"PrintOrder"
DHCDoc.OPDoc.TreatPrint.cls
GetDZDPrintData()
// 删除最后的分隔线
for i=1:1:($l(OrdItemInfo,$c(2))-2)
<txtdatapara name="PANoBarCode" xcol="1.587" yrow="0.794" defaultvalue="" printvalue="" fontbold="false" fontname="C39P36DmTt" fontsize="26" />

## 挂号条
w ##class(web.DHCOPAdmReg).OPRegistBroker()
##class(DHCDoc.Common.pa).GetOPPrintData(RegfeeRowId)

## 草药录入
DHCDocCT
草药录入备注
web.DHCDocCTCommon
代码模块数据维护

## xml打印机
xml设计打印机名称

## dip预分组接口
[Code](./doc/code/DIPCommon.md)


## 诊查费撤销控制
[Code](./doc/code/CheckFeeCancelFlag.md)

## 诊断删除控制
[Code](./doc/code/diagControl.md)

## 建档日期
```
s RowId = ""	;建档时间
f  s RowId=$o(^DHCCARDi("CF",0,"PAPMIDR",PersonRowId,RowId)) q:RowId=""  d
.s Flag=$P(^DHCCARD("CF",RowId),"^",10) 
.q:Flag'="N"
.s CreatCardDate=$p(^DHCCARD("CF",RowId),"^",7)
.s:CreatCardDate'="" CreatCardDate=$zd(CreatCardDate,3)
.s:$g(TCreateDate)'="" TCreateDate=TCreateDate_","
.s TCreateDate = $g(TCreateDate)_CreatCardDate
```

## 病历浏览按钮
[Code](./doc/code/EMRBrowse.md)

## 修改建卡
新版js不需要根据字段保存取数据，回传设置数据
```js
var myparseinfo = $("#InitPatMasEntity").val();
SetPatInfoByXML(myXMLStr);
```

## 病历医嘱同步
SaveOrderToEMR();

## 诊断录入
WToken: 
909E13EA00B8D2813A1A9D9E7298CBCD
paramdata: 
{"action":"QUALITY_CHECK","params":{"episodeID":"1404","documentID":["1276"],"eventType":"Save^28^233","langID":"20"},"product":"OP"}
_: 

MWToken: 
909E13EA00B8D2813A1A9D9E7298CBCD
paramdata: 
{"action":"QUALITY_CHECK","params":{"episodeID":"1404","documentID":["1276"],"eventType":"Save^28^233","langID":"20"},"product":"OP"}
_: 

诊断录入补丁包

## 处方类型 患者类别(费别) 收费类别

患者费别可以对应多种收费类别

处方类型可以对应多种患者费别

收费类别 处方类型 多对一

## 是否存在已收费特定接受科室医嘱
```

```

## 同步医嘱疗程超量原因
ClassName: 
DHCDoc.OPDoc.MainFrame
MethodName: 
GetBtnCfgData
SELECT * FROM DocCFTreatStatusInfo
门诊框架显示信息配置
```JS
function SynchroOrdExceedReasonClickHandler(){
	var ids = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    if (ids == null || ids.length == 0 || ids.length == 1) {
        $.messager.alert("警告", "请选择需要同步疗程超量原因的多行记录！");
        return;
    }
    debugger;
    var Find=0;
    //ids = ids.sort();
    // 下拉框文本
    var FirstExceedReason=GetCellData(ids[0], "ExceedReason");
    // 下拉框ID值
    var FirstExceedReasonValue= $("#" + ids[0] + "_" + "ExceedReason").val();
    debugger;
    var len = ids.length;
    for (var i = 1; i < len; i++) {
	    var OrderARCIMRowid = GetCellData(ids[i], "OrderARCIMRowid");
	    //空白行和已审核的不能同步
	    if ((OrderARCIMRowid!="")&&(CheckIsItem(ids[i]) == false)) {
		    //SetCellData(ids[i], "ExceedReason", FirstExceedReason);
		    debugger;
		    var obj = document.getElementById(ids[i] + "_" + "ExceedReason");
		    if (obj) {
				// 可编辑
				if (!FirstExceedReasonValue) {
					var FirstExceedReasonValue = $("#" + ids[i] + "_" + "ExceedReason" + " option:contains('" + FirstExceedReason + "')").val();
				}
				$("#" + ids[i] + "_" + "ExceedReason").val(FirstExceedReasonValue);
			}
			else {
				// 不可编辑
				$("#Order_DataGrid").setCell(ids[i], "ExceedReason", FirstExceedReason, "", "", true);
			}
			debugger;
		    Find=1;
		}
	}
	if (Find=="0"){
		$.messager.alert("警告", "没有需要同步的记录!");
        return;
	}
}
```

## 检查检验树
User.DHCAppTreeAdd
User.DHCAppTreeLink
User.DHCAppPart

## 检查报告时间
^DHCRBStudy("Report",{DRPT_RowID})
DRPTVerifyDate

## 日期转化
```js
// Get the current date
let currentDate = new Date();

// Subtract 100 days
currentDate.setDate(currentDate.getDate() - 100);

// Format the result as a string (optional)
let formattedDate = currentDate.toISOString().split('T')[0];

console.log(formattedDate);
```

## 健康卡读卡接口
UDHCCardPatInfoRegExp.js
udhcOPPatinfo.js
ReadRegInfo
ReadMagCard
ReadPCSC

## 是否自动启动中间件
医保系统配置（实施用）
SELECT  * from 	INSU_DicData where INDID_DicCode like "%Auto%"

## 检查部位
检查树维护 部位
医嘱项部位关联配置

## 草药审核后弹出处方
dhcdoc/opdoc/UDHCOEOrder.CHNMEDEntry.js

## 自定义嘱托
门诊框架显示信息配置
```
//自定义嘱托
function CustomAdvice_Click() {
	var Selrowids = GetSelRowId();
	if (Selrowids == "") {
		createModalDialog("Custom_Advice",$g("自定义嘱托"), 600, 400,"icon-edit",$g("确定"),"","医嘱嘱托备注","CustomAdviceBtn","AddCustomAdvice()",true);
	}
	else {
		var OrderNote = GetCellData(Selrowids[0],"OrderDepProcNote")
		createModalDialog("Custom_Advice",$g("自定义嘱托"), 600, 400,"icon-edit",$g("同步备注"),OrderNote,"医嘱备注","CustomAdviceBtn","SyncOrderNote()",true);
	}
}
function AddCustomAdvice() {
	// chen
	var OrderNote = $('#Custom_Advice_textarea').val();
    if (OrderNote != "") {
	    var result=$.cm({
	        ClassName:"DHCDoc.Order.Common",
	        QueryName:"LookUpItem",
	        desc:"嘱托",
	        ResultSetType:"array"
    	},false)
    	var item = result.filter(item => item.ItemID == "7435||1")
   		var rowsobj = $('#Order_DataGrid').getDataIDs();
        var rows = rowsobj.length;
        const greatestItem = Math.max(...rowsobj.map(Number));
		if($("#"+greatestItem+"_OrderName").val() != "") {
			Add_Order_row();
			var rowid = parseInt(greatestItem) + 1;
		}
		else {
			var rowid = greatestItem;
		}
		$("#"+rowid+"_OrderName").parent().parent().removeClass('OrderCritical');
		$("#" + rowid).find("td").removeClass("SkinTest");
		SetCellData(rowid, "OrderARCIMRowid","");
		SetCellData(rowid, "OrderARCOSRowid","");
		OrderItemLookupSelect(item[0],rowid);
		PageLogicObj.OrderNote = OrderNote;
		SetCellData(rowid,"OrderDepProcNote",OrderNote);
		destroyDialog('Custom_Advice');
    }
    else {
	    $('#Custom_Advice_textarea').focus();
	}
}
function SyncOrderNote() {
	// chen
	var ids = GetSelRowId();
	var OrderNote = $('#Custom_Advice_textarea').val();
	ids.forEach(id => {
		SetCellData(id,"OrderDepProcNote",OrderNote);
	});
	destroyDialog('Custom_Advice');
}
function createModalDialog(id, _title, _width, _height, _icon,_btntext,_content,_placeholder,_btnid,_event,closable){
	// chen
	if(_btntext==""){
	   var buttons="";
   }else{
	   var buttons=[{
			text:_btntext,
			iconCls:_icon,
			handler:function(){
				if(_event!="") eval(_event);
			},
			id: _btnid
		}]
   }
   if(!$('#'+id).size()){
    	$("body").append("<div id='"+id+"' class='hisui-dialog'></div>");
   }
    if (_width == null)
        _width = 800;
    if (_height == null)
        _height = 500;

    $("#"+id).dialog({
        title: _title,
        width: _width,
        height: _height,
        cache: false,
        iconCls: _icon,
        collapsible: false,
        minimizable:false,
        maximizable: false,
        resizable: false,
        modal: true,
        closed: false,
        closable: closable,
        //content:_content,
        content:"<textarea id='" + id + "_textarea' placeholder='"+_placeholder+"' style='width:99%; height:90%;'></textarea>",
        buttons:buttons,
        onClose:function(){
	        destroyDialog(id);
	    }
    });
    if (_content != "") {
		$("#"+id+"_textarea").val(_content);
	}
}
function destroyDialog(id){
	try{
		$("#"+id).dialog('close');
	}catch(e){
	}
	return
   $("body").remove("#"+id); //移除存在的Dialog
   $("#"+id).dialog('destroy');
}
```
## 医嘱模版默认收缩
<!--oeorder.entry.template.csp--> 
scripts/dhcdoc/entry.template.y.js
```js
$('#tFav').tree({
		url:'websys.Broker.cls',
		singleSelect:false,
		animate:true,	
		checkbox:false,
		cascadeCheck:false,		
		lines:true,
		dnd:true,
		formatter:formatTreeNode,
		onLoadSuccess:function(){
			var tree = $('#tFav');
            // Collapse all nodes
            tree.tree('collapseAll');
		},
});
```

## 医嘱执行记录不能撤销
护士执行通用配置
非药品医嘱医技执行后不允许撤销

w ##class(web.DHCDocInPatPortalCommon).IsCanCancelExecOrdArrear($lg(^tempchl,1),$lg(^tempchl,2))
w ##class(Nur.NIS.Service.Base.OrderHandle).IfCanUpdateOrdGroup()

## 皮试用法屏蔽
;按照默认皮试及皮试备注审核,不允许修改
s DisableOrdSkinChange=..%GetConfig("DisableOrdSkinChange",%session.Get("LOGON.HOSPID"))
## 首日次数
w ##class(web.DHCOEOrdItemView).GetOrderFirstDayTimes("70","2108||1","30","5","2024-01-21 20:46:17","","","2","1","")
..%GetConfig("OPFirstTimes",CurLogonHosp)
s IPNoDelayExe=$P(^PHCFR(OrderFreqRowid),"^",10)
住院默认按分发次数全执行 节点位置10 chenying add@2018-08-22

## 出院未签名提示
w ##Class(web.DHCOEOrdItemView).GetItemToList("")
s ret = ##Class(EMRservice.BOPrivAssist).GetOPSigninfo(EpisodeID)
	s ^tempchl = OrderARCIMRowid
	if (ret="0") {
		s arcic = $p($g(^ARCIM(+OrderARCIMRowid,$p(OrderARCIMRowid,"||",2),1)),"^",10)
		//s ^tempchl = arcic
		if ((arcic=246)||(arcic=247)) {
			//转科 出院
			s ^tempchl = arcic
			s CallBackFunParams="患者病历未签名!"
			s CallBackFunStr=..GetCallBackFunStr(CallBackFunStr,"Alert",CallBackFunParams)	
		}
	}
	
## paymode
function GetPayModeCode(){
	if (ServerObj.ParaRegType!="APP"){
		var PayModeValue=$("#PayMode").combobox("getValue");
		if (PayModeValue!="") {
			var PayModeData=$("#PayMode").combobox('getData');
			var index=$.hisui.indexOfArray(PayModeData,"CTPMRowID",PayModeValue);
			var PayModeCode= PayModeData[index].CTPMCode;
			return PayModeCode;
		}
	}
	return "";
}
安全组功能授权-支付方式授权

## 申请单自动打印
病理申请系统设置
检查检验系统设置

## 联系电话不必填
//必填项目验证

var Patdetail=value.split("^");
var NeedAddPatInfo=Patdetail[32];
var CredType=Patdetail[24];
if (CredType == "三无人员") {
	if (NeedAddPatInfo.includes("联系电话")) {
		var info = NeedAddPatInfo.split("、");
		info = info.filter(item => item != "联系电话");
		NeedAddPatInfo = info.join("、");
	}
}

## 特抗
没有Once频次

## 病理申请单

/// 统一草药接收科室获取(涉及：处方类型、煎药方式、医嘱类型、跨院、开始时间)
/// w ##class(web.DHCDocOrderCommon).GetCMRecLocStr(^Tempsclk("GetCMRecLocStr"))

## 草药录入卡顿 医保
scripts/DHCInsuPort.js

## 会诊护士撤销
w ##class(web.DHCDocInPatPortalCommon).IsCanCancelExecOrdArrear($lg(^tempchl,1),$lg(^tempchl,2))
w ##class(Nur.NIS.Service.Base.OrderHandle).IfCanUpdateOrdGroup()

## 固定间隔首日次数

/*
		s FreqRowid = PLIST(25)
		//s FreqIntervalUOM = $p($g(^PHCFR(FreqRowid)),"^",14)
		//s FirstDayTimes = PLIST(50)
		// chen
		s:($g(FirstDayTimes)=0)&&($g(FreqIntervalUOM)="H") GenSttDate=GenSttDate+1
		*/
		for GenDate=GenSttDate:1:GenEndDate{
			d ##class(DHCDoc.Order.Exec).Generate(rowid,GenDate)
		}
		
w ##class(appcom.OEOrdItem).Insert() 

## 诊断 就诊
s MRAdmID=$p($g(^PAADM(AdmRowId)),"^",61)

## 住院证
/// w ##class(web.DHCDocIPBookNew).SaveBookMeth(^lxz1234)
IntBookMes(); 
IntPaMes();
Doc.IPBookCreate.hui.js

///切换患者
function CreatNew(){
	//var src="doc.patlistquery.hui.csp?FromPage=IPBookCreate"; //"websys.default.csp?WEBSYS.TCOMPONENT=DHCExamPatList";
	var src="opdoc.patient.list.csp?NotShowBtnBar=Y";
	if(ServerObj.PAAdmType=='E'){
		src="dhcem.patlist.csp";
	}
	if(typeof websys_writeMWToken=='function') src=websys_writeMWToken(src);
	var $code ="<iframe width='100%' height='99%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("BookCreat","患者切换", 1300, 600,"icon-change-loc","",$code,"");
}

## 管制药品
AddItemDataToRow
SetPoisonOrderStyle(RowDataObj.OrderPoisonCode, RowDataObj.OrderPoisonRowid, rowid);
FZ 辅助用药
SELECT * from PHC_Poison 

## 护士医嘱信息总览显示行数
scripts/dhcdoc/ipdoc/InPatOrderViewNurse.js

## 医嘱执行绑定

## 医生界面缺少按钮
门诊框架显示信息配置

## 检查检验退费审核撤销执行
门诊系统参数配置

## 草药审核后打印
[Code](./doc/code/cmPrint.md)

## 强制退号
session As %String = ""
groupid => 安全组权限

## 诊断录入表格列宽度
页面表格列设置
select * FROM DHC_DocOrderListSet

## 诊断复制自动填充诊断备注
w ##class(web.DHCMRDiagnos).InsertMRDiagnos

## 护士医嘱患者列表
<!--ipdoc.nursepatlist.panel.csp 护士患者列表-->
[Code](./doc/code/nursePatList.md)
w ##class(Nur.NIS.Service.Base.Ward).getPatsAdditionalInfo
##class(Nur.NIS.Service.OrderExcute.OrderTask).GetDefaultSeeOrderNum

## 绑定来源
[Code](./doc/code/bindSource.md)

## 踢人
锁表

## 父类隐藏
/// 项目个性化修改方法写在此类覆盖父类的方法
Class EMRservice.BL.opInterface Extends EMRservice.BL.opInterfaceBase
{

}

## 发卡按钮
CardReg.hui.js
if (PageLogicObj.m_UsePANoToCardNO == "Y") {
	$('#btnList').marybtnbar('disable',['BReadCard','BReadInsuCard']);
	$("#CardNo").attr("disabled", true);
	DisableBtn("NewCard", false);
	PageLogicObj.m_CardNoLength = 0;
	$('#Name').focus();
}
else {
	DisableBtn("NewCard", true);
}
if (PageLogicObj.m_AllowNoCardNoFlag=="Y") {
	DisableBtn("NewCard",false);
}

## 报告外键
```objectscript
/// 标本报告关联表
Class User.EnsLISSpecimenReport Extends %Persistent [ ClassType = persistent, DdlAllowed, Owner = {UnknownUser}, ProcedureBlock, SqlTableName = Ens_LISSpecimenReport ]
{

ForeignKey FKSPECIDREFERENCESPECREPORT(LISSRReportID) References User.EnsLISReportResult(LISREPORTRESULTPKey) [ SqlName = FK_SPECID_REFERENCE_SPECREPORT ];

/// DDL Primary Key Specification
Index LISSPECIMENREPORTPKey On (LISSRReportID, LISSRSpecimenID, LISSROrderItemID);

Index RELORDERSPECIMENHOSCODE On LISSRSpecimenID;

/// 报告ID 
Property LISSRReportID As %Library.String [ SqlColumnNumber = 2, SqlFieldName = LISSR_ReportID ];

/// 标本号 
Property LISSRSpecimenID As %Library.String [ SqlColumnNumber = 3, SqlFieldName = LISSR_SpecimenID ];

/// 医嘱号
Property LISSROrderItemID As User.OEOrdItem [ SqlColumnNumber = 4, SqlFieldName = LISSR_OrderItemID ];

/// 患者ID
Property LISSRPatientID As User.PAPatMas [ SqlColumnNumber = 5, SqlFieldName = LISSR_PatientID ];

/// 就诊号
Property LISSRVisitNumber As User.PAAdm [ SqlColumnNumber = 6, SqlFieldName = LISSR_VisitNumber ];

/// 时间戳 
Property LISSRUpdateDate As %Library.Date [ InitialExpression = {$P($H,",")}, Required, SqlColumnNumber = 7, SqlFieldName = LISSR_UpdateDate ];

/// 时间戳
Property LISSRUpdateTime As %Library.Time [ InitialExpression = {$P($H,",",2)}, Required, SqlColumnNumber = 8, SqlFieldName = LISSR_UpdateTime ];

/// 报告状态 
Property LISSRStatus As %Library.String [ InitialExpression = "1", SqlColumnNumber = 9, SqlFieldName = LISSR_Status ];

}
```

## 检查检验申请 体征 病历
病历统一标准接口：术语集接口

## 护士费用核对
nur.hisui.dhccostcheck.csp

## 住院证
doc.ipbookcreate.hui.csp

## 慢病 病种 挂号 医嘱 医保


## 检查检验退回
className:"web.DHCDocInPatPortalCommon",
queryName:"FindInPatOrder",

s rslistDetail = ..OrderInfo(OrdRowid)

s OrdItemCallback=##class(web.DHCDocMainOrderInterface).IsCallbackOrder(orderParref,orderId)
s BackText=..%Translate("ipdoc.patinfoview.csp","退回")

没走平台，走的任务，2分钟一次

## 医生站接口
##class(%Dictionary.MethodDefinition).%ExistsId("web.DHCARCOrdSets||CheckPresno")

##class(%Dictionary.CompiledMethod).%ExistsId("web.DHCDocInterfaceMethod||DHCDocHisInterface")
## 挂号成功 医保交易未确认通过
医保测试工具
医保回滚
发票表改成自费
退费
## 手术术前诊断
select * from CIS_An.OperSchedule 
## wsdl
```objectscript
Include %SOAP.WebClient

Set client = ##class(%SOAP.WebClient).%New()
Set client.Endpoint = "http://example.com/YourWebService?wsdl"

Set params("param1") = "value1"
Set params("param2") = "value2"

Set response = client.InvokeMethod("YourWebServiceMethod", .params)

If $$$ISERR(response) {
    Write "Error: ", $System.Status.GetErrorText(response), !
} else {
    Write "Response: ", response, !
}
```

## 叫号
web.DHCVISQueueManager.cls
s insertFlag=##Class(DHCDoc.Interface.Outside.SYDEFY.DHCDocVISService.MainMethods).SendAdmCallInfo(EpisodeID, LocID, UserID, IPAddress, WaitList,LoginFlag,GHList)
诊室计算机
服务器设置
服务器设置

-- 诊室
SELECT * from DHCExaBorough

SELECT * from SQLUser.CT_LOC WHERE CTLOC_desc like "%诊室%"

SELECT * from DHCBorExaRoom

SELECT * from DHCRoomComp

## 出院弹窗
```js
websys_showModal({
		iconCls:'icon-w-edit',
		url:"../csp/dhcdoc.stopafterlongordcondition.csp?type="+type,
		title:title,
		width:400,height:370,
		paraObj:paraObj,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			var returnObj={
				SuccessFlag:false,
				LongOrdStopDateTimeStr:""
			}
			if ((result == "") || (result == "undefined")||(result == null)) {
			    CallBackFun(returnObj);
		    } else {
			    var resultArr=result.split("^");
			    if (type == "NeedDischgCond") {
		        	GlobalObj.DischargeConditionRowId = resultArr[0].split('!')[0];
					GlobalObj.DischargeMethodID=resultArr[0].split('!')[1]||'';
		        }else if (type == "NeedDeathDate"){
			        GlobalObj.DeceasedDateTimeStr = resultArr[0];
					GlobalObj.DischargeConditionRowId="";
					GlobalObj.DischargeMethodID="";
			    }
			    $.extend(returnObj, { SuccessFlag: true,LongOrdStopDateTimeStr:resultArr[1]});
		        CallBackFun(returnObj);
		    }
		}
	})
```
CheckBeforeSaveToServer
CheckAfterCheckMethod
OpenDeathDate
OpenStopAfterLongOrder()
```objectscript
/// w ##class(web.DHCDocOrderEntry).GetDischargePayMethod()
ClassMethod GetDischargePayMethod(langid = "")
{
 	s:langid="" langid=..%LanguageID()
	// Create an array to hold JSON objects
    Set jsonArray = []
	
    // Split the input data by comma to get individual name:code pairs
    s data = ##class(DHCDoc.DHCDocConfig.LocalConfig).GetLocalConfigValue("IPDoc","DischargePayMethod",2)
    // 普通住院:ptzy,日间手术结算:rjss,单病种结算:dbz,意外伤害结算:ywsh,中医优势病种:zyysbz,按床日:acr,日间病房:rjbf
    
    Set pairs = $LISTFROMSTRING(data, ",")

    // Iterate through each name:code pair
    For i=1:1:$LISTLENGTH(pairs) {
        // Split the name:code pair by colon to extract name and code
        Set pair = $LISTFROMSTRING($LISTGET(pairs, i), ":")
		break:$d(pair)=0
		
        // Extract name and code
        Set name = $LISTGET(pair, 1)
        Set code = $LISTGET(pair, 2)

		Set obj = {}
        Do obj.%Set("Name", name)
        Do obj.%Set("Code", code)
        
        // Create a JSON object with name and code fields and push it to the array
        Do jsonArray.%Push(obj)
    }
    // Convert the array to a JSON string
    Set jsonString = jsonArray.%ToJSON()
	Q jsonString
}
```

## 门诊诊断证明书
emr/js/bs.op.search.print.js

## 诊断 诊断备注
```objectscript
;头痛(头痛);风湿(风湿)
s DiagStr = ""
f i=1:1:$l(Diagnosis,";"){
	s diag = $p($g(Diagnosis),";",i)
	set start = $FIND(diag, "(")  // Find the position of the opening parenthesis
	set end = $FIND(diag, ")", start)  // Find the position of the closing parenthesis starting from the position of the opening parenthesis

	if (start > 0) && (end > start) {  // Ensure both the opening and closing parentheses are found
		set Diag = $EXTRACT(diag, start, end-2)  // Extract the content between the parentheses
	}
	s:($g(Diag)'="")&&(DiagStr'="") DiagStr = DiagStr_";"_$g(Diag)
	s:($g(Diag)'="")&&(DiagStr="") DiagStr = $g(Diag)
}
s Diagnosis = DiagStr
	;chenhongliang
```
## 工会
web.DHCOPAdmReg.GetAppPrintData
OPAppArrive

## 总览打印底部按钮
opdoc.treatprintorder.csp

## 医生页面设置
epr.frame.js
showConfig
dhcdoc.opdoc.mainframework.js
getConfigUrl
websys.menugroup.js
getConfigUrl

## 退号退费
RegPayObj
OPAdm.MisPose.MisPosePublic.js
DHCBillPayService.js
```js
var RegObj = {
	RegPay:function() {
		
	}
}
var rtn = RegObj.RegPay()
```

## 护士医嘱模板权限
页面设置

## 取消预约
```objectscript
s object = ##class(User.RBAppointment).%OpenId(uniqueRecordNumber)
s PatientID = object.APPTPAPMIDR
s PatientID = PatientID.%Id()
```

## 叫号
```js
/// /desc:推送诊区患者信息
/// w ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo(7)
ClassMethod SendDeptScreenInfo(QueRowId As %String = "", BorId As %String = "") As %String
{
	s $ZTrap = "SendAdmCallInfoET"
	//s ^Temp("SendAdmCallInfo")=$lb(EpisodeID, LocID, UserID, IPAddress, WaitEpisodeID,LoginFlag,GHList,$h)
	q:BorId=""
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
		/*
		1	01		复诊
		2	02	等候	等候
		3	03	 	过号
		4	04		到达
		5	05		退号
		6	06	 	未分配
		7	07	报到	报到
		*/
		// 向 screenInfo 数组中添加元素
		
		set screenInfoItem = {}
		set screenInfoItem.waitPatientInfo = []
		
		if Mark = $lg($g(^User.DHCQueueD(QueRowId)),8) {
			set waitPatientInfo = {}
			set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(QueRowId)),10)
			set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(QueRowId)),9)
			set waitPatientInfo.sort=0 ;$lg($g(^User.DHCQueueD(QueRowId)),10) - 1
			do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
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
			b ;;state
			if state = 2 {
				set waitPatientInfo = {}
				set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				set waitPatientInfo.sort=$lg($g(^User.DHCQueueD(Que)),10)
				do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
			}
			
			;复诊
			if state = 1 {
				set waitPatientInfo = {}
				set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(Que)),10)
				set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(Que)),9)
				set waitPatientInfo.sort=$lg($g(^User.DHCQueueD(Que)),10)
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
	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	
  	set obj.Timeout=5
  	s className=obj.HIPMessageShow(json).Read()
	
	s json = {}.%FromJSON(className)
  	s status = json.status
	q status
SendAdmCallInfoET
    q "-1^叫号异常:"_$ze
}
/// w ##Class(web.DHCVISQueueManage).RunNextButton("1","4783","192.168.41.234)
```

```objectscript
Class web.DHCENS.BLL.Call.Soap.PUB0004Soap Extends %SOAP.WebClient [ ProcedureBlock ]
{

/// This is the URL used to access the web service.
Parameter LOCATION = "https://10.1.143.50:1443/csp/hsb/DHC.Published.PUB0004.BS.PUB0004.cls";

/// This is the namespace used by the Service
Parameter NAMESPACE = "http://www.dhcc.com.cn";

/// Use xsi:type attribute for literal types.
Parameter OUTPUTTYPEATTRIBUTE = 1;

/// Determines handling of Security header.
Parameter SECURITYIN = "ALLOW";

/// This is the name of the Service
Parameter SERVICENAME = "PUB0004";

/// This is the SOAP version supported by the service.
Parameter SOAPVERSION = 1.1;

Method HIPMessageServer(entityBody As %String) As %Stream.GlobalCharacter [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 s ..SSLCheckServerIdentity=0
 s ..SSLConfiguration="SSLECP"
 b ;;;
 Quit ..WebMethod("HIPMessageServer").Invoke($this,"http://www.dhcc.com.cn/DHC.Published.PUB0004.BS.PUB0004.call",.entityBody)
}

Method HIPMessageShow(entityBody As %String) As %Stream.GlobalCharacter [ Final, ProcedureBlock = 1, SoapBindingStyle = document, SoapBodyUse = literal, WebMethod ]
{
 s ..SSLCheckServerIdentity=0
 s ..SSLConfiguration="SSLECP"
 b ;;;
 Quit ..WebMethod("HIPMessageServer").Invoke($this,"http://www.dhcc.com.cn/DHC.Published.PUB0004.BS.PUB0004.oneShow",.entityBody)
}

}

```

```js
function callPatientHandler(event){
	var row=$("#tabPatList").datagrid('getSelected');
	var QueId = "";
   	if(row) {
		WalkStatus=row["WalkStatus"];
		if(WalkStatus == "过号") {
			QueId=row["QueRowId"];
		}
	}
	var ret=tkMakeServerCall("web.DHCVISQueueManage","RunNextButton","","",GetCacheIPAddress(),"",QueId);
	return CalledAfter(ret);
}
```

```objectscript
/****************************************陈杨重新整理修改****************************************/
/// cy20190605
/// 门诊呼叫按钮
/// w ##Class(web.DHCVISQueueManage).RunNextButton("1","4783","192.168.41.234)
/// "0^正在呼叫""1^未配置客户端","2^未关联服务器","3^服务器未激活""4^请处理完绿色背景患者,再呼叫新患者!""5^更新队列状态失败!""7^超出最多呼叫人数!""8^获取呼叫队列失败""9^就诊信息不存在,请重新呼叫!""10^用户非医护人员不能呼叫!""11^队列信息不存在不能呼叫!""12^该病人已被其他医生呼叫,请重新呼叫!"
ClassMethod RunNextButton(LocID As %String = "", UserID As %String = "", IPAddress As %String = "", MarkID As %String = "", QueId As %String = "") As %String
{
	s retStr="8^获取呼叫队列失败",retValue=""
	i LocID="" s LocID=%session.Get("LOGON.CTLOCID")
    i UserID="" s UserID=%session.Get("LOGON.USERID")
    //i IPAddress="" s IPAddress=$ZUTIL(67,15,$JOB)
    s IPAddress = "192.168.137.1"
    i IPAddress="" s IPAddress=%session.Data("REMOTE_ADDR")
    s IPAddress=$$upper^SSUTIL4(IPAddress)
    i MarkID="" s MarkID=%session.Get("MarkSelectDr")
    s activeFlag=..GetActiveFlag(IPAddress)
    q:activeFlag'=0 activeFlag
    //d ..InsertClientInfo(IPAddress)
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s Consultation="on"
    s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))  //呼叫的人数
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))  //获取等候人数
    s patIndex=0
    s insertFlag=0
    s WaitNo=1,waitEndAdm=""
    //LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,
    //ArrivedQue,RegQue,Consultation,MarkID,CheckName
    s WaitList="",WaitListNo="",CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!!"
    s LoginFlag = "", GHList=""
    if QueId '= "" {
	    s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdm")
		i rs.QueryIsValid() {
			//s waitPersons=waitPersons-1
			Set Status=rs.Execute(LocID,UserID,IPAddress,"","","",+$h,+$h,"","on","",MarkID,"")
			Set columns = rs.GetColumnCount()
			If 'Status Quit
			While rs.Next() {
				s patIndex=patIndex+1
				//呼叫+等候
				i (patIndex>admPersons)&&(retStr="") s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
				q:((patIndex>admPersons)&&((waitPersons+admPersons)-patIndex<0))
				s WalkStatus=rs.GetDataByName("WalkStatus")
				continue:(WalkStatus="到达")||(WalkStatus="退号")
	            //q:(patIndex>AdmWaitPersons) 
	            s calledFlag=rs.GetDataByName("Called")
				i calledFlag=1  s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
				q:calledFlag=1
			}
		}
		q:calledFlag=1 retStr
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
		s rtn = ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo(QueId,BorDr,UserID)
	  	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
	  	set obj.Timeout=5
	  	s className=obj.HIPMessageServer(json).Read()
	  	s json = {}.%FromJSON(className)
	  	s status = json.status
		q status_"^"
	}
	q:$g(calledFlag)=1 retStr
    /*
    i activeFlag'=0 d
    .s retValue="alert('"_$ZCVT(activeFlag,"O","JS")_"')" 
    .&javascript<#(retValue)#>
    */
    q:activeFlag'=0 activeFlag
    //d ..InsertClientInfo(IPAddress)
    s StartDate=+$H
    s EndDate=+$H
    s RegQue="on"
    s Consultation="on"
    s AllPatient="",PatientNo="",SurName="",ArrivedQue=""
    s admPersons=+$G(^DHCVISSet("DHCVISAdm"))  //呼叫的人数
    i admPersons=0 s admPersons=1
    s waitPersons=+$G(^DHCVISSet("DHCVISWaiting"))  //获取等候人数
    s patIndex=0
    s insertFlag=0
    s WaitNo=1,waitEndAdm=""
    //LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,
    //ArrivedQue,RegQue,Consultation,MarkID,CheckName
    s WaitList="",WaitListNo="",CKScreenStr="!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!",DocInfoStr="!!!!!!!!!!!"
    s LoginFlag = "", GHList=""
    s rs=##Class(%ResultSet).%New("web.DHCDocOutPatientList:FindLocDocCurrentAdm")
	i rs.QueryIsValid() {
		//s waitPersons=waitPersons-1
		Set Status=rs.Execute(LocID,UserID,IPAddress,AllPatient,PatientNo,SurName,StartDate,EndDate,ArrivedQue,RegQue,"",MarkID,"")
		Set columns = rs.GetColumnCount()
		If 'Status Quit
		While rs.Next() {
			s patIndex=patIndex+1
			//呼叫+等候
			i (patIndex>admPersons)&&(retStr="") s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
			q:((patIndex>admPersons)&&((waitPersons+admPersons)-patIndex<0))
			s WalkStatus=rs.GetDataByName("WalkStatus")
			continue:(WalkStatus="到达")||(WalkStatus="退号")
            //q:(patIndex>AdmWaitPersons) 
            s calledFlag=rs.GetDataByName("Called")
			i calledFlag=1  s retStr="4^请处理完绿色背景患者,再呼叫新患者!"
			q:calledFlag=1 
			q:(insertFlag=1)
			i patIndex=admPersons d
			.s EpisodeID=rs.GetDataByName("EpisodeID")
			.s patName=rs.GetDataByName("PAPMIName")      
			.s PAAdmDepCodeDR=rs.GetDataByName("PAAdmDepCodeDR")
			.i $P(PAAdmDepCodeDR,"-",2)'="" s PAAdmDepCodeDR=$P(PAAdmDepCodeDR,"-",2)        
			.s docDr=##Class(web.SSUser).GetDefaultCareProvider(UserID)
			.s docDesc=""   //号别
			.i docDr'="" s docDesc=$P($G(^CTPCP(docDr,1)),"^",2) 
			.s DocHisID=""  //医生工号 
			.i docDr'="" s DocHisID=$P($G(^CTPCP(docDr,1)),"^",1)
			.s PAAdmRoom=..GetRoom(IPAddress)
			.i PAAdmRoom="" s retStr="1^未配置客户端"
			.q:PAAdmRoom=""
			.s PAAdmPriority=rs.GetDataByName("PAAdmPriority")
			.s Priority="平诊"
			.i PAAdmPriority="优先" s Priority="优诊"
			.i WalkStatus="复诊" s Priority="复诊"
			.i WalkStatus="到达" s Priority="复诊"
			.i $d(^RBAS("PAADM_DR",EpisodeID)) s Priority="预约"
			.s locSeqNo=rs.GetDataByName("LocSeqNo")
            .i locSeqNo'["号" s locSeqNo=locSeqNo_"号"
			.i (+locSeqNo)=0 s voiceContent="请 "_patName_" 到 "_PAAdmRoom_" 就诊"
			.e  s voiceContent="请 "_locSeqNo_" "_patName_" 到 "_PAAdmRoom_" 就诊"
			.s Note=PAAdmRoom_"   "_docDesc_"   "_locSeqNo_"-"_patName_"  "_PAAdmDepCodeDR
			.s regDocDesc=rs.GetDataByName("RegDoctor") //号别
			.i $G(regDocDesc)="" s regDocDesc=docDesc
			.s QueRowId=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeID,""))
			.q:QueRowId=""
			.s oref=##Class(User.DHCQueue).%OpenId(QueRowId)
			.s QueMarkDr=oref.QueMarkDrGetObjectId()   
			.i QueMarkDr'="" s ctpcpDesc=$P($g(^CTPCP(QueMarkDr,1)),"^",2)   //号别描述
	        .i ctpcpDesc'="" s ctpcpDesc=$P(ctpcpDesc,"(")   
	        .d oref.%Close()
			.s $P(DocInfoStr,"!",1)=$$upper^SSUTIL4(ctpcpDesc)
			.s $P(DocInfoStr,"!",2)=$$upper^SSUTIL4(DocHisID)
			.s $P(DocInfoStr,"!",3)=$$upper^SSUTIL4(UserID)
			.s $P(DocInfoStr,"!",4)=$$upper^SSUTIL4(LocID)
			.s $P(DocInfoStr,"!",5)=$$upper^SSUTIL4(MarkID)
			.s ZHScreenStr=PAAdmRoom_" "_PAAdmDepCodeDR_" "_regDocDesc_" "_locSeqNo_" "_patName_" "_Priority  //不在走FromatZHStr
			.s ZHScreenStr=QueRowId_"*"_ZHScreenStr
			.s DocTypeDesc=..GetDocTypeDesc(UserID)
			.s $P(CKScreenStr,"!",1)=$$upper^SSUTIL4(PAAdmDepCodeDR)
			.s $P(CKScreenStr,"!",2)=$$upper^SSUTIL4(PAAdmRoom)
			.s $P(CKScreenStr,"!",3)=$$upper^SSUTIL4(docDesc)
			.s $P(CKScreenStr,"!",4)=$$upper^SSUTIL4(DocTypeDesc)
			.s $P(CKScreenStr,"!",5)=$$upper^SSUTIL4(locSeqNo)
			.s $P(CKScreenStr,"!",6)=$$upper^SSUTIL4(patName)
			e  d
			.s locSeqNoT=rs.GetDataByName("LocSeqNo")
			.s EpisodeIDT=rs.GetDataByName("EpisodeID")
			.s patNameT=rs.GetDataByName("PAPMIName")  
			.s QueRowIdT=$O(^User.DHCQueueI("QuePaadmDrIndex",EpisodeIDT,""))
			.q:QueRowIdT="" 
			.s QueDocDr=$List(^User.DHCQueueD(QueRowIdT),5)
			.q:(QueDocDr'="")&&(QueDocDr'=docDr)
			.S QueStateDr = $LG(^User.DHCQueueD(QueRowIdT),14)	;队列状态
		    .s PersName = $LG(^User.DHCPerStateD(QueStateDr),4)
			.s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			.;i WaitListNo="" s WaitListNo=locSeqNoTS
			.;e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.s UnSplitFlag=..GetUnSplitFlag(EpisodeIDT,LocID)
			.i UnSplitFlag=0 d
			..i WaitListNo="" s WaitListNo=locSeqNoTS
			..e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.i PersName="过号" d
			..s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			..i GHList="" s GHList=locSeqNoTS
			..e  s GHList=GHList_","_locSeqNoTS
			.s locSeqNoTS=QueRowIdT_"*"_locSeqNoT
			.i WaitListNo="" s WaitListNo=locSeqNoTS
			.e  s WaitListNo=WaitListNo_","_locSeqNoTS
			.s WaitIndex=$L(WaitListNo,",")
			.s $P(CKScreenStr,"!",WaitIndex+6)=$$upper^SSUTIL4(locSeqNoT_"号-"_patNameT)
			.s TwoWaiterPersons=+$G(^DHCVISSet("TwoWaiter"))
			.i (TwoWaiterPersons'=0) d
			..q:(WaitNo>TwoWaiterPersons)
			..i voiceContent'="" s voiceContent=voiceContent_",请 "_patNameT_" 等候"
			..s updateWaitStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeIDT,docDr,2,IPAddress,WaitNo)
			..//i updateWaitStatusFlag'=1 s retValue="更新队列状态失败!"
			..s WaitNo=WaitNo+1
			..s waitEndAdm=EpisodeIDT
	
		} 
    }
    i waitEndAdm'="" s ^DHCDocSetArrive(UserID,+$H,"Call")=$G(^DHCDocOutPatientList("WartInd",waitEndAdm))
	i (($G(EpisodeID)'="")&&($P($G(voiceContent),",",1)'="")) d
	.// 先改状态在插表
	.s updateCallStatusFlag = ##Class(web.DHCDocOutPatientList).SetCallStatus(EpisodeID,docDr,"",IPAddress)
	.i updateCallStatusFlag'=1 s retStr="5^更新队列状态失败!"
	.q:updateCallStatusFlag'=1
   	.i waitEndAdm="" s ^DHCDocSetArrive(UserID,+$H,"Call")=$G(^DHCDocOutPatientList("WartInd",EpisodeID))
	.s WaitList=WaitListNo
	.s insertFlag=##Class(web.DHCVISVoiceCall).InsertVoiceQueue(voiceContent,UserID,IPAddress,"A","LR","N",ZHScreenStr,CKScreenStr,WaitList,Note,DocInfoStr,EpisodeID)
    .s insertFlag=##Class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendAdmCallInfo(EpisodeID, LocID, UserID, IPAddress, WaitList,LoginFlag,GHList)
    .i insertFlag'=0 s retStr="6^"_insertFlag
    .q:insertFlag'=0
    .s retStr="0^正在呼叫"_" "_locSeqNo_" "_patName_"..."
    .s insertFlag=1
    /*
    i retStr'="" s retValue="alert('"_$ZCVT(retStr,"O","JS")_"');findPatientTree();"
    i retStr="" s retValue="findPatientTree();"
    &javascript<#(retValue)#>
    */
    q retStr
}
/// /desc:推送诊区患者信息
/// w ##class(DHCDoc.Interface.Outside.YH.DHCDocVISService.MainMethods).SendDeptScreenInfo("429",7,"21333")
ClassMethod SendDeptScreenInfo(QueRowId As %String = "", BorId As %String = "", UserID As %String = "") As %String
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
		/*
		1	01		复诊
		2	02	等候	等候
		3	03	 	过号
		4	04		到达
		5	05		退号
		6	06	 	未分配
		7	07	报到	报到
		*/
		// 向 screenInfo 数组中添加元素
		
		set screenInfoItem = {}
		set screenInfoItem.waitPatientInfo = []
		
		if Mark = $lg($g(^User.DHCQueueD(QueRowId)),8) {
			set waitPatientInfo = {}
			set waitPatientInfo.registerId=$lg($g(^User.DHCQueueD(QueRowId)),10)
			set waitPatientInfo.patientName=$lg($g(^User.DHCQueueD(QueRowId)),9)
			set waitPatientInfo.sort=0 ;$lg($g(^User.DHCQueueD(QueRowId)),10) - 1
			do screenInfoItem.waitPatientInfo.%Push(waitPatientInfo)
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
	s obj=##Class(web.DHCENS.BLL.Call.Soap.PUB0004Soap).%New()
  	
  	set obj.Timeout=5
  	s className=obj.HIPMessageShow(json).Read()
	
	s json = {}.%FromJSON(className)
  	s status = json.status
  	q status
SendAdmCallInfoET
    q "-1^叫号异常:"_$ze
}
```

## 采血费

医生站设置菜单
检验绑定规则设定

## 建卡创建两个账户

卡类型配置
多院区

## 医保自负比例
s EPARCIMDetail=##Class(web.DHCDocOrderCommon).GetEPARCIMDetail

## 医保电子凭证

```
// d ##class(DHCDoc.OPDoc.PatientList).CheckCardValue("1","1")

ClassMethod CheckCardValue(cardTypeId As %String, cardNo As %String) As %String [ Private ]
{
	q:( (cardTypeId="") || ('$d(^DHCCARDTYPEDef(cardTypeId))) ) ""
	s ^tempchen("111")=cardNo
	s temp = cardNo
	s ls=^DHCCARDTYPEDef(cardTypeId)
	s len=$p(ls,"^",17)
	for i=$l(cardNo)+1:1:(+len) {
		s cardNo="0"_cardNo
	}
	if '$d(^DHCCARDi("CF",0,"CardNo",cardNo)) s cardNo=""
	if cardNo'="",'$d(^DHCCARDi("CF",0,"CardTypeNo",cardTypeId,cardNo)) s cardNo=""
	
	if ((($l(temp,":") = 5) || ($l(temp) = 101))&& (cardTypeId = 30)){
		s temp = $p(temp,":",1)	
		s rtn = ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetHealthCardInfoByCardNo(temp)
		s cardNo = $p(rtn,"^",3)
	}
	
	if (($l(temp) = 28) && (cardTypeId = 30)) {
		if ($d(^temp("card",temp)) = 0) {
			s rtn = ##class(web.DHCDocMain).GetInsuInfoByCardNo(temp)
			s card = $p(rtn,"^",3)
			s:card'="" ^temp("card",temp) = card
		}
		else {
			s card = ^temp("card",temp)
			k ^temp("card",temp)
		}
		;s ^tempzt("rtn11",$zdt($h,3),$j)=temp_"^"_cardTypeId_"^"_rtn
		s cardNo = card
	}
	
	q cardNo
}
```


## 登记号长度
系统计数类型
var len = tkMakeServerCall("web.DHCCLCom","GetPatConfig");
len = len.split("^")[0];

## 排班科室权限
操作员诊区对照
诊区科室对照

ClassMethod InsertExaBoroughGroupUser(Str As %String, HospID = "")
{
	;q:Str="" ""
	s ret=##class(web.DHCDocConfig).SaveConfig2("ExaBoroughGroupUser",Str,HospID)
	q ret
}
操作员

## 没有新开医嘱
合理用药
药品信息
回车换行
ItemCongeries = ItemCongeries.replace(/[\n\r]/g, " ");

## 数据库保存
特殊字符#
MaxLen

## 绑定
```
/// creator: 宋春莉
/// date: 2020-07-03
/// desc: 根据医嘱录入需要审核的医嘱项目获取绑定的医嘱列表并重新整合需要插入的串
/// input:	Adm：就诊ID OrdItemStr:医嘱录入需要审核的医嘱项目拼接字符串 
/// 		Loc 录入科室ID
/// 		SessionStr:	websys.js->GetSessionStr\websys_getSessionStr;DHCDoc.Util.RegisteredObject->%SessionStr;部分通过接口传入，可能无完整数据
/// 		BaseParamJson:基本参数列表，可自行扩展
/// 			DisBindTypeList:不需要计算的绑定类型，关键字参照BindSource，逗号分隔
/// output:	包含绑定医嘱的新医嘱录入串
/// w ##class(web.DHCOEOrdAppendItem).GetAppendOrdItemArr()

/// Others: w ##class(DHCDoc.Interface.Inside.ServiceOrd).SaveOrderItems()
```

## 合理用药
dhcdoc/interface/MeiKang/HLYY.js

## 检验 标本 容器 绑定
SELECT * from dbo.BT_TestSetSpecimen where TestSetDR = 672

SELECT * from dbo.BT_TestSet WHERE RowID = 672

SELECT * from dbo.BT_Container

select * from dbo.BT_Specimen 
项目组合套

w ##Class(DHCLIS.DHCCommon).GetTSContainer("JS011","SP004","ZZSZYYY002")


## 检查申请单临床病历

dhcdoc/dhcapp/MedRecordpanel.js
/// Creator：   bianshuai
/// CreatDate： 2016-08-15
/// Descript:   获取检查申请单打印数据
/// Table：     DHC_AppReport  
/// Input：	    ExaReqID：申请单ID、ExaReqNo：申请单号   
/// Return：    申请单json串
/// w ##Class(web.DHCAPPPrintCom).GetExaReqPrintData("3620","")、

## 抗菌药物多科会诊
抗菌药物-功能配置
	常规设置
		会诊设置
	系统设置
		系统参数
			申请单高度



抗菌药物申请弹窗
dhcdocant/kss_hui/apply.js


## 医嘱模板提示医嘱套未授权
个人组套和科室组套同一名称
添加个人组套


## 医嘱表格局部刷新
opdoc.main.framework.js
--
function xhrRefresh()
RefreshOrderList();

## 电子发票
w ##class(BILL.EINV.BL.EInvoiceLogic).InvocieBill
select * from BILL_EINV_PO.InvLogicPath

## 住院诊断
SELECT * FORM MRC_DiagnosType

/// 根据住院证插入入院诊断
/// w ##class(web.DHCDocIPBookNew).InserDiagenoseBill(248,19182,19182)

## iframe
iframe 父界面方法
window.parent.frames.GetName()

## 折扣系数
绝对私有
院区组

## 出院医嘱

请求参数签名错误
字段超长

打开IE
csp
<ADDINS require="CmdShell"></ADDINS>
var Path = '"C:\\Program Files (x86)\\Internet Explorer\\iexplore.exe" "'+url+'"';
exec(Path);   

SELECT * FORM MRC_DiagnosType
/// 根据住院证插入入院诊断
/// w ##class(web.DHCDocIPBookNew).InserDiagenoseBill(248,19182,19182)

服务总线
服务注册
文件路径

## 两个院区一套优惠 枣庄中医
w ##class(web.DHCRegDisConDisCount).CheckDHCRegDisConDisCount()

## 登录
Logon.csp

websys.SessionLogon.cls

## 用法绑定医嘱
DHCDoc.DHCDocConfig.InstrArcim
病区绑定医嘱
执行绑定

## 读卡手输卡号
SELECT CTD_ReadCardMode ,* from DHC_CardTypeDef;

## 住院证打印
模板问题

- 病理申请单 临床病历 换行
- 病历申请单 医嘱号


## 强制退号 退费
select PAADM_VisitStatus,* from pa_adm;
C => A;


## 治疗工作站 基础版本
zw ^DHCDocConfig("HospDr_2","DocCureUseBase")
医生站设置 -> 常规设置 -> 其他设置


## 抗菌药物 二次申请
抗菌药物功能设置 二次申请


## 读卡包自动部署
