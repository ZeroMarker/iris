# The note

## 排班授权

操作员诊区对照

## 挂号科室搜索前缀匹配排序

web.DHCOPAdmReg.cls
[Code](./doc/code/opDeptList.md##挂号科室搜索前缀匹配排序)

## 医技执行同步护士

w ##class(appcom.OEOrdExec).DelaWithExecAll("531546||1",590) 
CheckUpdateStatus()

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

## 电子病历维护

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

## 诊间预约提前取号

OPAdm/Reg.hui.js
ClassName : "web.DHCRBAppointment",
MethodName : "GetAppInfo",
...//Quit:ASDate<+$h  不允许提前取号 刘亚提
...Quit:ASDate'=+$h

## 门诊传染病报卡

[Code](./doc/code/diagnosReport.md)

## 将医嘱停止时间后的所有未执行记录变为"停止执行"状态

[Code](./doc/code/ordExecStop.md)

## 回诊 复诊

web.DHCAlloc
PatAgain

[Code](./doc/code/regTitle.md)

## 分诊优先患者不能取消报到

Alloc.NurseTriage.hui.js

```js
function InitAllocListTabDataGrid()
if (row["Prior"]=="优先"){
 ChangeMenuDisable("CancleQueCheckin",true);
}
```

## 获取患者信息后光标跳转

[Code](./doc/code/regCursor.md)

## 医嘱氧气吸入数量显示

[Code](./doc/code/sumQty.md)

## 挂号速度慢

w ##class(web.DHCENS.BLL.Message.Method.public).SendMessageInfo("MES0072","44$#$17855606389,17631666188$#$1")
s soap=##class(web.DHCENS.BLL.Message.Soap.PUB0009Soap).%New()
;s stream=soap.HIPService(MessageCode,streams)
[Code](./doc/code/payInterface.md)

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

## 回龙观可以维护同医生、同时段、同开始时间、不同门诊的排班，且均可以生成排班记录，需在新增排班时增加提示

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

## 医嘱录入

GetItemCongeries()
CreatOrdNo()
SavaOrderItems()
InsertOrderItems()
w ##class(web.DHCDocOrderCommon).GetLabSpec("3950||1",2)

## 挂号条 挂号凭证

w ##class(web.DHCOPAdmReg).OPRegistBroker()
w ##class(DHCDoc.Common.pa).GetOPPrintData(RegfeeRowId)

## 草药录入

DHCDocCT
草药录入备注
web.DHCDocCTCommon
代码模块数据维护

## dip预分组接口

[Code](./doc/code/DIPCommon.md)

## 诊断删除控制

[Code](./doc/code/diagControl.md)

## 建档日期

```objectscript
s RowId = "" ;建档时间
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

诊断录入补丁包

## 处方类型 患者类别(费别) 收费类别

患者费别可以对应多种收费类别

处方类型可以对应多种患者费别

收费类别 处方类型 多对一

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
SELECT  * from  INSU_DicData where INDID_DicCode like "%Auto%"

## 检查部位

检查树维护 部位
医嘱项部位关联配置

## 草药审核后弹出处方

dhcdoc/opdoc/UDHCOEOrder.CHNMEDEntry.js

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

```objectscript
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
```

## 申请单自动打印

病理申请系统设置
检查检验系统设置

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

## 诊断 就诊

s MRAdmID=$p($g(^PAADM(AdmRowId)),"^",61)

## 住院证

/// w ##class(web.DHCDocIPBookNew).SaveBookMeth(^lxz1234)
IntBookMes();
IntPaMes();
Doc.IPBookCreate.hui.js

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

## 强制退号 权限

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
w ##class(Nur.NIS.Service.OrderExcute.OrderTask).GetDefaultSeeOrderNum

## 绑定来源

[Code](./doc/code/bindSource.md)

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

## 检查检验申请 体征 病历

病历统一标准接口：术语集接口

## 护士费用核对

nur.hisui.dhccostcheck.csp

## 检查检验退回

className:"web.DHCDocInPatPortalCommon",
queryName:"FindInPatOrder",

s rslistDetail = ..OrderInfo(OrdRowid)

s OrdItemCallback=##class(web.DHCDocMainOrderInterface).IsCallbackOrder(orderParref,orderId)
s BackText=..%Translate("ipdoc.patinfoview.csp","退回")

没走平台，走的任务，2分钟一次

## 医生站接口

## class(%Dictionary.MethodDefinition).%ExistsId("web.DHCARCOrdSets||CheckPresno")

## class(%Dictionary.CompiledMethod).%ExistsId("web.DHCDocInterfaceMethod||DHCDocHisInterface")

## 挂号成功 医保交易未确认通过

医保测试工具
医保回滚
发票表改成自费
退费

## 手术术前诊断

select * from CIS_An.OperSchedule

## 门诊诊断证明书

emr/js/bs.op.search.print.js

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

## 采血费

医生站设置菜单
检验绑定规则设定

## 建卡创建两个账户

卡类型配置
多院区

## 医保自负比例

s EPARCIMDetail=##Class(web.DHCDocOrderCommon).GetEPARCIMDetail
ArcimLinkInsu1

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

## 合理用药

dhcdoc/interface/MeiKang/HLYY.js

## 检验 标本 容器 绑定

SELECT * from dbo.BT_TestSetSpecimen where TestSetDR = 672

SELECT * from dbo.BT_TestSet WHERE RowID = 672

SELECT * from dbo.BT_Container

select * from dbo.BT_Specimen
项目组合套

w ##Class(DHCLIS.DHCCommon).GetTSContainer("JS011","SP004","ZZSZYYY002")

方案限定规则

## 检查申请单临床病历 分行截取

dhcdoc/dhcapp/MedRecordpanel.js
/// Creator：   bianshuai
/// CreatDate： 2016-08-15
/// Descript:   获取检查申请单打印数据
/// Table：     DHC_AppReport  
/// Input：     ExaReqID：申请单ID、ExaReqNo：申请单号
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

## 打开IE

```js
// csp
<ADDINS require="CmdShell"></ADDINS>
var Path = '"C:\\Program Files (x86)\\Internet Explorer\\iexplore.exe" "'+url+'"';
exec(Path);
```

## 出院诊断

SELECT * FORM MRC_DiagnosType
/// 根据住院证插入入院诊断
/// w ##class(web.DHCDocIPBookNew).InserDiagenoseBill(248,19182,19182)

## 平台服务代码路径

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

## 强制退号 返回退费

select PAADM_VisitStatus,* from pa_adm;
C => A;

## 治疗工作站 基础版本

zw ^DHCDocConfig("HospDr_2","DocCureUseBase")
医生站设置 -> 常规设置 -> 其他设置

## 抗菌药物 二次申请

抗菌药物功能设置 二次申请

## 读卡包自动部署

/dthealth/app/dthis/web/addins/plugin/

## 病理 共库 Soap 登录密码

d ..WSSecurityLogin("dhwebservice","password")

## 临时医嘱频次

执行记录数量
医嘱数量 / 频次系数
打包数量
医嘱数量 / 频次系数
w ##class(DHCDoc.Order.Exec).GetOrdExecQtyToList("2||718",.ExecList)
appcom.OEDispensing

## 检查申请单状态

w ##class(web.DHCENS.STBLL.RIS.METHOD.GetRisAppInfo).GetAppBillByStudyNoNew("6092||3^6092||4")
检查部位
特殊字符"^"

## 出院诊断 出院带药

s priStr=##class(PHA.COM.Order).OeoriPriority(oeori)
s priCode = $p(priStr,"^",2)

## 医嘱项获取收费项

```objectscript
s TariDrStr=##class(web.DHCINSUPortUse).GetTariDrByArcimRowid(ArcimRowid,"")
```

## 急诊 虚拟长期

s VirtualtLongFlag=##class(web.DHCDocOrderVirtualLong).GetVirtualtLongFlag(OEORIRowId)

## 临时医嘱 数量

Set PackQty=$p(OrdItem,"^",6)
Set DoseQtySum=$p(OrdItem,"^",14)

## 预停时间

&SQL(Update SQLUser.OE_OrdItem Set OEORI_EndDate=null,OEORI_EndTime=null,OEORI_UserUpdate=:UserRowId where OEORI_Rowid=:OrdItmRowId)

## 生成处方号

d ##class(DHCDoc.Interface.Inside.Service).GenPresno("6119",1,"")

## 病理申请单 发送

```objectscript
/// Creator：lipan
/// CreatDate：2016—06-17
/// Description:获取病理申请单信息
/// Table：
/// Input：医嘱号
/// w ##class(web.DHCENS.STBLL.PIS.METHOD.GetPisAppListInfo).illNew("48||2").Read()
s Obj.ClinicalDiagnosis=##class(web.DHCSTKUTIL).GetMRDiagnosDesc($p(^OEORD(+OrdID),"^",1),",") ;$p(APPString,"^",37)
```

## 诊断

w ##class(web.DHCSTKUTIL).GetMRDiagnosDesc()

## 静配中心导致数量不可以编辑

w ##Class(DHCDoc.DHCDocConfig.DocConfig).GetDosingRecLocStr(2)
s LocID=$O(^DHCDocConfig(HospCodeNode,"IPDosingRecLoc",LocID))
q:(LocID="")
q:^DHCDocConfig(HospCodeNode,"IPDosingRecLoc",LocID,"Active")=0

## 挂号限额

web.DHCRBAppointment
GetAPPSeqNo
GetAvailableNum

## 处方扩展表

s paque = $o(^PAQUE1(0,"DHCPAQue","LinkOrderItem",orditem,0))
s multiple = $p(^PAQUE1(paque,"DHC"),"^",38)

## 输液单

打印目录信息配置

## 虚拟长期

^DHCDocORDVL

## 配置菜单维护

菜单维护

## 医护人员职称对照

出诊级别
职称诊查费对照

## 检查申请备注

w ##Class(web.DHCAPPPrintCom).GetExaReqPrintData("240","")
.s Sub=0
.s Sub=$o(^DHCAPREP(arReqID,"AR",CH,"PA",Sub))
.s Notes=$p(^DHCAPREP(ExaReqID,"AR",CH,"PA",Sub),"^",8) /// 备注
.s:Notes'="" arItemDesc=arItemDesc_"("_Notes_")"

## 限制用药

;Set AdmReason=$P(^PAADM(EpisodeID,1),"^",7)
;i AdmReason=165 s AdmReason=177 //自费的费别也要能够显示
;s HospID=##class(DHCDoc.Common.Hospital).HospitalId(EpisodeId)
s limitFlag=##class(web.DHCDocInPatPortalCommon).GetArcimLinkInsuInfo(arcim,AdmReason,HospID,"",9)
;s limitinfo = ##class(web.DHCDocInPatPortalCommon).GetInsuLimitInfo(arcim,AdmReason,HospID)

## 药袋

d ##class(web.DHCENS.BLL.GetDrugBagInfo.Method.GetDrugBagInfo).AutoInertBagNum()
web.DHCENS.BLL.Drug.Method.Cmomon

## 不收挂号费

OPDocList

RegFee = 0

SelDr = FreeOrder

## 医保标志

ClassName : "web.DHCDocInPatPortalCommon",
MethodName : "ChangeOrdCovMainInsuFlag",
TableName : "OE_OrdItem",

## 医技执行发药

/// Description: 医技执行或者护士执行时执行发药, 所有判断逻辑于本组程序控制
/// Creator:     yunhaibao
/// CreateDate:  2021-12-08
/// Input:       oeori - 医嘱ID, exe - 如果按执行记录操作,请传第三个节点, loc - 登录科室, user - 操作人ssuserID
/// Return:      $$$OK - 成功, -1^错误信息 - 失败
/// Debug:       w ##class(PHA.FACE.OUT.Com).ExeDisp("27||1522","1","114","12177")

/// 1. 接收科室等于操作的登录科室, 调用时才处理库存

## string wrap

```js
{field:'LimitOrdInfo',title:'限制用药信息',align:'center',width:300,auto:false,
   formatter:function(value, row, index) {
             if (value.length > 20) {  // 如果内容长度超过20
                 return '<span title="' + value + '">' + value.substring(0, 40) + '...</span>';
             } else {
                 return '<span title="' + value + '">' + value + '</span>';
             }
         }
        },
```

## 挂号只有上午数据

web.DHCOPAdmReg
OPDocList
索引冲突
set ind=AdmDate_TimeRangeSort_SessSort_ScheduleStatusF_($E("0000000000",1,10-$L(RowId))_RowId)_($E("0000000000",1,10-$L(ClinicGroupDr))_ClinicGroupDr)_ASRowId

下标覆盖

## 只能开长期

OnlyLongItemCat

## 价格

web.UDHCJFPRICE.GetOrderPrice()

## 未发药 无法出院

打包表
打包子表

护士停止执行记录
撤销处理 医嘱
配置 护士处理后才能发药

## 获取年龄

w ##class(web.UDHCJFCOMMON).DispPatAge
s HospId = ##class(DHCDoc.Common.Hospital).GetAdmHospitalId(EpisodeID)
s age = ##class(web.DHCBillInterface).GetPapmiAge(id,"",HospId)

## 总览打印

护士执行单设置
/// w ##class(DHCDoc.OPDoc.TreatPrint).GetOrdMenuOEChkMap("2885||2","输液单")

## 护士 转科 患者

if ((PAAdmType="I")&&(LoginAdmLocFlag="Y"))||(VisitStatus="P"){
 ;医嘱单默认在北部 护士强制在北部
 s OrdListRegion=$SELECT(OrdListRegion'="":OrdListRegion,1:"north") ;isNurseLogin:"north",
 ;此时医嘱模板南北布局跟着医嘱单走
 if " north south "[(" "_TemplateRegion_" ") s TemplateRegion=OrdListRegion
 }else{
 ;其余时候不显示医嘱列表
 ;s OrdListRegion=""
 }
 dhcdoc/oeorder.oplistcustom.show.js

## 方法

费别处方垃圾数据
获取医嘱是否预停方法

## 病历 检验引用列表

url: '../EMRservice.Ajax.lisData.cls?Action=GetLisData&InterFace=' + encodeURI(encodeURI(interface)),
emr.ip.resource.lisdata.csp
<https://array-stars.decard.com/login?logout>
d ##class(EMRservice.Ajax.pacsData).GetPacsData("HSBToHis","40637,"","","","","1")

## bug zGetHourGenTimeList+9^DHCDoc.Order.Exec.1

s LinkTime=$O(LinkExecList(GenDate,""))
   s ind=""
   s:LinkTime'="" ind=$O(LinkExecList(GenDate,LinkTime,""))
   s:ind'="" LinkOrdExecID=LinkExecList(GenDate,LinkTime,ind).LinkOrdExecID

## bug 单独生成条码

i (LabItemSingleFlag=0){
      s keylab=keylab_"^"_Index ;row
     }

## bug 撤销会诊

/// CTOR: QP
/// DATE: 2018-05-14
/// DESC: 撤销会诊
/// IN  :
/// OUT : 0：成功，-102:失败
/// EXEC:  w ##class(DHCAnt.KSS.Extend.Undo).UndoConsult("")
ClassMethod UndoConsult(aaId As %String, user As %String, InHosp = "") As %String
{
 n (aaId,user,InHosp)
 s Err=0
 s admId=$p(^DHCDAA("ANT",aaId),"^",1)
 s consultNum=##class(DHCAnt.KSS.Common.Method).GetConsultDepNums(InHosp)
 s conId1=$p(^DHCDAA("ANT",aaId,1),"^",22)
 s conId2=$p(^DHCDAA("ANT",aaId,1),"^",26)
 s conId3=$p(^DHCDAA("ANT",aaId,1),"^",29)
 s conId="",cResult=0
 f i=1:1:consultNum {
  i i=1 s conId=conId1
  i i=2 s conId=conId2
  i i=3 s conId=conId3
  q:cResult'=0
  s cResult=##Class(web.DHCEMConsInterface).CancelCstNo(conId,user)
  //q:(cResult'="")&&(cResult'=0)
  //s cResult=##class(User.DHCConsultation).ChangeStatus(conId,"C","Y",user,admId)

 }
 q:cResult'=0 "-102"
  q Err
}

## 强制退号

挂号设置 授权管理

## 医嘱 到达 就诊科室

;下医嘱后将病人状态置为到达
 s CFSetArriveByOrder=..%GetConfig("SetArriveByOrder",AdmDepHospId)
 s LocType = $p($g(^CTLOC(Loc)),"^",13)
 if CFSetArriveByOrder=1,Doc'="",LocType="E" d ##class(web.DHCDocOrderEntry).SetArrivedStatus(Adm,Doc,Loc,User)

## 患者信息条码

var PatStr = $.cm({
            ClassName: "web.DHCDocOrderEntry",
            MethodName: "GetPatientByNo",
            dataType: "text",
            PapmiNo: RegNo
        }, false)

## 挂号小条

## 挂号

DHCOPReturn.js

## 挂号限制

专业组
排班模板 扩展
坐诊

## 加号限额

ClassMethod GetAvailableSeqNoStr(RBASId As %String, RegType As %String, APPMethodCode As %String = "", HospitalID As %String = "", StartTime As %String = "", EndTime As %String = "", AllowAddRegFlag As %String = "", ClinicGroupId As %String = "") As %String

## 您无权撤销

```objectscript
if ##class(web.UDHCStopOrderLook).IsPayCanStopOrder(oeorirowid)=1 {
 s cancelMsg=..%Translate("ipdoc.patinfoview.csp","您无权撤销 ")_OrderName_..%Translate("ipdoc.patinfoview.csp"," 医嘱！")_..%GetErrCodeMsg("-100071")
 s ErrMsg=cancelMsg
 Q
}
s IsOrdExecFlag=+##class(web.UDHCStopOrderLook).IsOrdExec(oeorirowid)
if (IsOrdExecFlag>0) {
 if (StopDealType="") {
  s cancelMsg=..%Translate("ipdoc.patinfoview.csp","您无权撤销 ")_OrderName_..%Translate("ipdoc.patinfoview.csp"," 医嘱！")_..%GetErrCodeMsg("-100071")
 }elseif (IsOrdExecFlag=2){
  s cancelMsg=..%Translate("ipdoc.patinfoview.csp","您无权撤销 ")_OrderName_..%Translate("ipdoc.patinfoview.csp"," 医嘱！执行记录已全部执行！")
 }     
 s ErrMsg=cancelMsg
 Q
}

```

## demo挂菜单

菜单维护
菜单授权

## 用法绑定 数量为空 跟随主医嘱

## 出院

DHCDoc.Interface.Inside.Invoke
doctorDischarge

## 执行数量

/// Others:       w ##class(DHCDoc.Interface.Inside.ServiceOrd).GetOrdExecQty("11619||725")
执行记录执行
医嘱未执行

## 数量

OEORE_PhQtyOrd,OEORE_QtyAdmin
剂量单位和整包装数量

## 小时

/// creater tanjishan
/// 获取医嘱缺失执行记录详情
/// Input OEOrdID 医嘱ID
/// OutPut 1 存在异常 0不存在异常
/// w ##class(web.DHCDocMain).CheckExecValidity("60266||93", .MissExecList)
/// WangQingyong 修改为新的执行记录生成方法统一判断
ClassMethod CheckExecValidity(OEOrdID As %String, ByRef MissExecList) [ ProcedureBlock = 0 ]
{
 n (OEOrdID,MissExecList)
 k MissExecList
 s TtemStat=$P($G(^OEORD(+OEOrdID,"I",$p(OEOrdID,"||",2),1)),"^",13)
 s statcode=$p($g(^OEC("OSTAT",TtemStat)),"^",1)
 ;医嘱无效和实习生审核的
 Q:(statcode="U")||(statcode="C")||(statcode="I") 0
 ;治疗项目预约时产生则不需要生成
 Q:##class(DHCDoc.Order.Exec).GetCureAppGenFlag(OEOrdID) 0
 ;PRN医嘱不需要产生
 Q:##class(appcom.OEOrdItem).ISPRNOrder(OEOrdID) 0
 ;s EndDate=$p($G(^OEORD(+OEOrdID,"I",$p(OEOrdID,"||",2),9)),"^",9)
 s SttDate=$P($G(^OEORD(+OEOrdID,"I",$p(OEOrdID,"||",2),1)),"^",9)
 s EndDate=$p($G(^OEORD(+OEOrdID,"I",$p(OEOrdID,"||",2),3)),"^",34)
 s GenDate=$CASE(EndDate,"":+$H,:EndDate)
 ;获取指定时间范围执行时间列表，有停止日期就按停止日期算,没有按今天
 ;临时 住院 小时
 s Adm = $p(^OEORD(+OEOrdID),"^",1)
 s AdmType = $p(^PAADM(Adm),"^",2)
 s Prior = $p(^OEORD(+OEOrdID,"I",$p(OEOrdID,"||",2),1),"^",8)
 if ##class(appcom.OEOrdItem).IsHourOrderItem(OEOrdID) {
  if ((AdmType="I")&&(Prior=3)) {s GenDate=SttDate}
 }
 d ##class(DHCDoc.Order.Exec).GetGenTimeList(OEOrdID,GenDate,.ExecList)
 b ;;;;;
 d ##class(DHCDoc.Order.Exec).GetOrdExecQtyToList(OEOrdID,.ExecList)
 s CheckRet=0
 s Date="" for{
  s Date=$O(ExecList(Date)) Q:Date=""
  s Time="" for{
   s Time=$O(ExecList(Date,Time)) Q:Time=""
   b ;kkk
   if '$D(^OEORDi(0,"Date",+OEOrdID,Date,Time,$p(OEOrdID,"||",2))){
    s CheckRet=1
    b ;zt1
    s MissExecList("ExecTime",Date,Time)=""
   }
  }
 }
 Q CheckRet
}

##

if ((ReAdmis=="")&&(FirstAdm=="")&&(OutReAdm=="")&&(ServerObj.PAAdmType!="I")) {
  $.messager.alert("提示","初诊、门诊复诊或出院复诊不能同时为空！","info")
  return false;
 }
 var Weight=$("#Weight").val();
 var LocDesc = session['LOGON.CTLOCDESC'];
 if ((Weight == "") && (LocDesc.indexOf('儿科')!=-1)) {
  $.messager.alert("提示","儿科体重不能为空！","info")
  return false;
 }

## 病理申请

w ##class(web.DHCENS.STBLL.PIS.METHOD.GetPisAppInfo).SendAppBill("2463||10")
w ##class(web.DHCENS.STBLL.PIS.METHOD.GetPisAppListInfo).SendAppBillNew("48||2").Read()
scripts/dhcdoc/dhcapp/InfectDispanel.js
传染病史

## restart

iris stop irishealth restart

## 治疗申请单

doccure.cureapplist.show.hui.csp

## 建卡 生日 性别

setBirthAndSex

## 检查

/// Descript:  获取检查申请XML串
/// w ##Class(web.DHCAPPInterface).GetExaReqNoXml("3029")

## 检查 调用接口

```objectscript
/// Debug:w ##class(web.DHCENS.STBLL.Method.ReturnSystemStatus).ReturnSystemStatusCircle().Read()

/// Creator：ZhangXinying
/// CreatDate：2021—11-06
/// Description：HIS-API共库调用接口
/// Table：Ens_InterfaceMethod、Ens_ApiSysConfig Ens_SubApiSysConfig
/// Input：Input:方法代码,InputStream:入参字符流
/// Return：0:成功;-1:失败  
/// w ##class(web.DHCENS.STBLL.MANAGE.MergeInstance).SendMergeInfo()
```

## studio

debug target

envirument class track variable

## 多部位 单独登记

```objectscript
s flag = 1
   if $d(^Busi.ENS.EnsStatusI("IndexESOrdItemIDPartID"," "_OEOrdItemID," "_Position)) {
    s tmpPosition=""
    for
    {
     q:(tmpPosition="")
     s tmpPosition=$o(^Busi.ENS.EnsStatusI("IndexESOrdItemIDPartID"," "_OEOrdItemID,tmpPosition))
     s tmpESStatusID1=""
      s tmpESStatusID1=$o(^Busi.ENS.EnsStatusI("IndexESOrdItemIDPartID"," "_OEOrdItemID,tmpPosition,tmpESStatusID1),-1)
     for
     {
      q:tmpESStatusID1=""
      s Position1=$tr(tmpPosition," ","")
      s tmpESStatusStr=$g(^Busi.ENS.EnsStatusD(tmpESStatusID1))
      s Status=$listget(tmpESStatusStr,9)
      s EffectiveFlag=$listget(tmpESStatusStr,12)
      if (EffectiveFlag="Y") && ((Status="SC") || (Status="RP")) {
       s flag = 0 
      }
      ;q:EffectiveFlag="Y"
      ;s tmpESStatusID=tmpESStatusID1
     } 
    } 
   }
// w ##class(web.DHCENS.STBLL.Method.SystemStatusInfo).QuerySystemStatus("[{""OEOrdItemID"":""123||3"",""ExamID"":""456""}]")

;elseif '$d(^Busi.ENS.EnsStatusI("IndexESOrdItemIDPartID"," "_OEOrdItemID," "_Position))&&(Position'["@@"){ //兼容多部位登记时，按多部位中某一部位查询能正常输出检查号的情况
   elseif flag&&(Position'["@@"){ //兼容多部位登记时，按多部位中某一部位查询能正常输出检查号的情况
```

## 撤销停诊

// w ##class(web.DHCRBApptSchedule).GetRBApptScheduleStatus()

## 病理

/// Creator：王博
/// CreatDate： 20190412
/// Description： 临床下申请单后，推送申请单信息到病理数据表
/// Table：
/// Input： 医嘱号
/// Output：
/// Return：0：推送成功  -1：失败
/// Others：w ##class(PISService.PISApply).SendPISApply("46835||45")

## 代办人
<!--pha.in.v1.narcpoison.csp 毒麻代理信息填写-->
<!--dhcdoccheckpoison.csp 毒麻代理信息填写-->
## 检查状态回传

/// Creator：ZhangXinying
/// CreatDate：2021—04-30
/// Description：状态变更回传HIS
/// Table：Ens_Status、Ens_StatusLog
/// Input：请求xml串
/// Return：应答xml串
/// Debug:w ##class(web.DHCENS.STBLL.Method.SystemStatusInfo).ReturnSystemStatusCircle().Read()

## 空医嘱 治疗单

/// 返回执行记录状态更新为配置里维护的
/// w ##class(web.DHCEMNurExe).updateDisposeStatCode(1147,74,1)

## 病理 传染病史 阴性+

dhcdoc/dhcapp/InfectDispanel.js

## 报错

```js
"<OBJECT DISPATCH>zFindLocDocCurrentAdmExecute+388^web.DHCDocOutPatientList.1 *Property 'QueNo' in class 'User.DHCQueue' must be MultiDimensional "
```

## 多部位 子医嘱

医技执行 同步 护士执行

## 挂号费用显示

/// 得到单个预约记录
/// w ##Class(DHCExternalService.RegInterface.SelfRegMethods).GetApptObjByRBASObj("688||64||1",18341)

## 结算状态

// 结算状态
 ;s FSStatus=##Class(web.DHCWMRBasePaadm).GetFSStatus(EpisodeID) ;潍坊人民医院增加结算状态
 ;s FSStatusDesc=""
 ;s:FSStatus'="N" FSStatusDesc="未结算"
    ;s auditUser=$P($G(^PAADM(EpisodeID,2)),"^",92)
    ;i auditUser'="" s FSStatusDesc="财务审核"
    ;s billFlag=$P($G(^PAADM(EpisodeID)),"^",45)
    ;i billFlag="Y" s FSStatusDesc="财务结算"
s flag=##class(web.DHCDocMainOrderInterface).HiddenMenuFlag(EpisodeID)
 if (flag=0)||(flag=5){
  q ""
 }
 s Msg=$case(flag,2:"已医疗结算",2.5:"费用调整中",3:"已护士结算",4:"已财务结算")

## JS 调用栈

// Create a new Error object
var err = new Error();

// Capture the stack trace
var stackTrace = err.stack;

// Print or process the stack trace as needed
//console.log(stackTrace);
const regex = /scripts\/.*\.js/g;
stackTrace = stackTrace.match(regex);
stackTrace = stackTrace.join(',');

## 医嘱缓存

xhrRefresh()
GetSessionData()

## 抗菌药审核

dhcdocant/kss_hui/audit.js 抗菌药物审核界面

## 电子病历获取医嘱明细

d ##class(%ResultSet).RunQuery("DHCDoc.Interface.Inside.Service","FindEMROPItems","84698","","SaveOrder")

## 出院诊断重复

/// Creator:      songchunli
/// CreateDate:   2022.10.14
/// Description:  更新出院前需开诊断类型行数据
/// Input:
/// Return:
/// Other:        ##Class(Nur.HISUI.NeedCareOrderSet).updateDiagBeforeDisch()

## 切换病人 信息总览 病历质控

dhc.emr.quality.qualityinfoshow.csp

## 过敏

scripts/dhcdoc/OEOrder.GuideAllergy.js
w ##Class(web.DHCOEOrderGuideAllergy).GetGuideAllergyTableJson
BuildRelatedAllergyList

## 医嘱套 关联序号

```objectscript
d ##class(%ResultSet).RunQuery("web.DHCDocOrderCommon","FindOSItems","1738","2",5716)
.s ItemLinkDoctor=$p(s,"^",14)
.i ItemLinkDoctor'="" d
..s tempMaster=$p(ItemLinkDoctor,".",1)
..s tempSubSeqNo=$p(ItemLinkDoctor,".",2)
..//i (tempSubSeqNo'="")&&($d(^||TempARCOSSeqNoArr($j,ItemLinkDoctor))) s tempMaster=$g(^||TempARCOSSeqNoArr($j,tempMaster))+1,ItemLinkDoctor=tempMaster_"."_tempSubSeqNo
..//s ^||TempARCOSSeqNoArr($j,ItemLinkDoctor)=tempMaster
..if tempSubSeqNo'="" d
...s ItemLinkDoctor=tempMaster_"."_tempSubSeqNo
...; ARCOSCount
..e  d
...;if ($d(^||TempARCOSSeqNoArr($j,ARCOSCount))) s ARCOSCount=ARCOSCount+1
...s ItemLinkDoctor=tempMaster
...; ARCOSCount
...s ^||TempARCOSSeqNoArr($j,tempMaster)=1
...; ARCOSCount
```

## 总览打印 第一次 无法单独取消勾选

```js
// scripts/dhcdoc/opdoc/TreatPrint.js
if (data[j]["PrintFlag"]) {
 //db.getPanel().find['input[type="checkbox"]'](j+1).disabled=true;
 //_$ck[j].disabled=true;
}
```

## 未作治疗

/// CreateDate:   2022.09.23
/// Description:  是否未做治疗
/// Input:        
/// Return:       1：未做；0：已做
/// Other:        w ##class(Nur.HISUI.NeedCareOrder).ifUnTreatOrder("423113||85")
