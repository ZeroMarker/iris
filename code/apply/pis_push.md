## 病理申请推送地址
```objectscript
demo
医院信息平台
服务列表

医院院内服务总线 iBus

ClassName: web.DHCDocAPPBL
MethodName: InsertNewBLInformation
dataType: text
EpisodeID: 383
DocID: 18881
LocID: 1
Type: MOLN
OEOrdStr: 3116||1^45^
JsonStr: [{"ID":"TesItemDesc","Val":"脱氧核糖核酸（DNA）测序","Class":"text","Desc":"脱氧核糖核酸（DNA）测序"},{"ID":"recLoc","Val":"45","Class":"combobox","Desc":"病理科"},{"ID":"ApplyLoc","Val":"1","Class":"combobox","Desc":"呼吸内科门诊"},{"ID":"ApplyDocUser","Val":"18881","Class":"combobox","Desc":"YS01 医生01"},{"ID":"PreMedRecord","Val":"","Class":"text","Desc":""},{"ID":"Position","Val":"咽喉","Class":"text","Desc":"咽喉"},{"ID":"OtherInfo","Val":"{\"mPisTestItem\":\"[]\",\"PisReqSpec\":\"1\\u0001咽喉\\u0001\\u00011\\u0001\\u00011\\u0001\",\"mSpceType\":\"[]\",\"mSentOrder\":\"[\\\"127^\\\"]\"}","Class":"Data"},{"ID":"PrintInfo","Val":"{\"PisTestItem\":\"\",\"PisCutBasType\":\"\",\"SentOrder\":\"\"}","Class":"Data"}]
PisID: 
BillTypeID: 1
ChronicDiagCode: 
EmConsultItm: 

ClassName: web.DHCDocAPPBL
MethodName: InsSendFlag
dataType: text
PisID: 11
UserID: 18881
BillTypeID: 1
InsurFlag: N

s:(AdmType="I")!((AdmType="E")&((stay="STAY")!(stay="SALVAGE"))) rtn=##class(web.DHCENS.EnsHISService).DHCHisInterface("S00000042",Oeori)

d ##class(web.DHCENS.STBLL.MANAGE.MergeInstance).SendMergeInfo(KeyName,perStream)

^Config.ENS.EnsSubApiSysConfigD(1)=$lb("","PIS","DHSZHYYZY","Default","MES0048","发送病理申请单")

EnsSubApiSysConfig

/// Creator：ZhangXinying
/// CreatDate：2021—11-06
/// Description：HIS-API共库调用接口
/// Table：Ens_InterfaceMethod、Ens_ApiSysConfig Ens_SubApiSysConfig
/// Input：Input:方法代码,InputStream:入参字符流
/// Return：0:成功;-1:失败  
/// w ##class(web.DHCENS.STBLL.MANAGE.MergeInstance).SendMergeInfo()

SELECT * 
FROM Ens_InterfaceMethod
-- WHERE method_Code [ "MES0048"
WHERE method_Desc [ "病理"


SELECT * 
FROM Ens_InterfaceV8
WHERE method_Code [ "S00000042"

SELECT * 
FROM Ens_SubApiSysConfig
WHERE method_Code [ "S00000042"
^Config.ENS.EnsApiSysConfigD

SELECT * 
FROM Ens_ApiSysConfig
WHERE method_Code [ "S00000042"

SELECT * FROM OE_OrdItem
WHERE OEORI_OEORD_ParRef IN
(
	SELECT OEORD_RowId1 FROM OE_Order
	WHERE OEORD_Adm_DR IN
	(
		SELECT PAADM_RowID FROM PA_Adm
		WHERE PAADM_PAPMI_DR = 95
	)
)
```