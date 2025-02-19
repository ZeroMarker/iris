## 病理申请推送地址
```objectscript
demo
医院信息平台
服务列表

医院院内服务总线 iBus

ClassName: web.DHCDocAPPBL
MethodName: InsertNewBLInformation

ClassName: web.DHCDocAPPBL
MethodName: InsSendFlag


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