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

## 毒麻疼痛评分
dhcdoccheckpoison.csp
[Code](doc/code/hurt.md)

## 就诊号到达时间
[Code](./doc/code/admNoArriveTime.md##就诊号到达时间)

## 修改患者信息接口
[Code](./doc/code/updatePatInfo.md##修改患者信息接口)

## 生物标本库查询修改日志
[Code](./doc/code/biobank/README.md)

## 草药代煎接受科室
opdoc.oeorder.cmlistcustom.csp
web.DHCDocOrderCommon

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

