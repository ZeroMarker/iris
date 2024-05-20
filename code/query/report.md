## 一个报告对应不同人的检验项目
dhcapp.seepatlis.csp
url:LINK_CSP+"?ClassName=web.DHCAPPSeePatLis&MethodName=JsonQryOrdListNew&Params="+Params
w ##class(web.DHCAPPSeePatLis).JsonQryOrdListNew(1,60,"","","274^46^2023-10-08^2023-11-07^^0^^^18881^0^^^^Y^^^^")
Set result1=##class(%Library.ResultSet).%New("web.DHCAPPSeePatLis:QueryOrderList")
d ##Class(%ResultSet).RunQuery("web.DHCAPPSeePatLis","QueryOrderList","274","46","2023-10-08","2023-11-07","","0","","","18881","0","","","","Y","","")

s OutPutReportDR=##class(web.DHCENS.EnsHISService).DHCHisInterface("QryLISRptIDByLabNo",LabEpisode)

s OrdRowIds=##class(web.DHCENS.EnsHISService).DHCHisInterface("QryLISOrdIDByRpt",oneReportDR)

/// Creator：ZhangXinying
/// CreatDate：2019—09-06
/// Description：根据检验号获取报告ID，针对部分报告，逗号分割多个报告ID
/// Table：Ens_LISSpecimenReport
/// Input：检验号
/// Return：报告ID，逗号分割
/// Debug:w ##class(web.DHCENS.STBLL.Method.PostReportInfo).QryLISRptIDByLabNo("323110600040")

/// Creator：ZhangXinying
/// CreatDate：2019—09-06
/// Description：根据报告ID获取医嘱rowid，针对拆报告的，逗号分割多个医嘱rowid
/// Table：Ens_LISSpecimenReport
/// Input：报告ID
/// Return：医嘱ID，逗号分割
/// Debug:w ##class(web.DHCENS.STBLL.Method.PostReportInfo).QryLISOrdIDByRpt("20231106-7-2")
set myquery = "SELECT * FROM SqlUser.Ens_LisSpecimenReport where LISSR_ReportID= "_"'"_rptID_"'"

瑞美报告问题