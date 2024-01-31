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