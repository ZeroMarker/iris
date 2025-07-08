# 病理申请单Not Found

dhcapp.docpopwin.csp

```objectscript
i mListDataDoc'="" D
.D ##Class(web.DHCAPPPisInterface).GetExaItemListDoc(mListDataDoc, .itemTmpArr)

.s Type=##Class(web.DHCAPPExaReportQuery).GetTraType(arcimid)
.i Type="P" D
..s LinkUrl=..GetLinkUrl(arcimid

s PisType=..GetPisType(arcimid) 	             /// 取病理类型
Q:PisType="" "-1"

n (arcimid)
Q:arcimid="" ""
b ;xz--001
s TraID=$o(^DHCAPARCCA(0,"Arc",arcimid,""))
Q:TraID="" ""
s PisType=$p(^DHCAPARCCA(TraID),"^",1)
Q PisType
```

SELECT *
FROM DHC_AppCatLinkArcItm

检查分类维护

检查树维护
