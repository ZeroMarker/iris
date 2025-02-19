w ##class(web.DHCDocInPatPortalCommon).MulOrdDealWithCom("2657||78"_$c(1)_"2021-12-20 21:17:31","","","U","1","12178^114^23^1^","")
w ##class(appcom.OEOrdItem).StopMulti("531546||1",590,"")
if PAADMType'="I" {
	s OrdList=$tr(OrdList,"!","&")
	Q ##class(web.UDHCStopOrderLook).StopOrder("","",OrdList,UserID,PinNum,PWFlag,"",.ErrMsg)
}
s OrdListStr=..GetMulOrdGroup(OrdList,UserID)

关联医嘱

;重新组织停医嘱串,根据配置停主医嘱
s StopGroupOrder=..%GetConfig("StopGroupOrder",AdmHospDr)
;医生站设置菜单 停子医嘱同时停主医嘱 不勾选可以单独停子医嘱（仅支持门诊停医嘱界面）
;写死参数，让配置对住院不生效
s StopGroupOrder=1

签名	下医嘱 审核人
执行记录	跨天 时间差异
