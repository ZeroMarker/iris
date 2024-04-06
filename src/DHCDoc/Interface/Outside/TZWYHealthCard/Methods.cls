Class DHCDoc.Interface.Outside.TZWYHealthCard.Methods Extends (%RegisteredObject, %XML.Adaptor) [ Not ProcedureBlock ]
{

/// 海阳市人民医院
/// 机构编码：493610244	
/// 地区编码：370687
/// 测试机构编码: 00450234X
/// 注册建卡	姓名^身份证^电话^1^"01"^住址
/// //// 鲁东
/// 终端编码：02-010210-9900-A333
/// appid：6f26f56w5f8giydo7q07
/// appsecret：b7512f90b2f642ecb6f693ed79284901
/// 城市编码：370100
/// 机构编码：00450234X
/// 测试环境地址：http://47.104.88.161:4431
/// 访问方式：外网 post方式  地址+接口名
Parameter deviceCode = "1925-200427000123";

Parameter useCityCode = 370611;

Parameter institutionCode = "MJE311444";

/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).Register("崔啸宇^370602199806022613^15265353235^1^1^山东省烟台市芝罘区")
/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).Register("111^37068119950713221X^17863804131^1^1^山东省龙口市桥上村")
ClassMethod Register(InfoStr As %String) As %String
{
	s ^temp("Register")=$lb(InfoStr)
	s RegistRqObj=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Entity.RegisterRt).%New()
	s RegistRqObj.name=$p(InfoStr,"^",1)
	s RegistRqObj.cardNo=$p(InfoStr,"^",2)
	s RegistRqObj.cardType="01"
	s RegistRqObj.phone=$p(InfoStr,"^",3)
	s RegistRqObj.sex=$p(InfoStr,"^",4)
	s RegistRqObj.institutionCode=..#institutionCode  // 发卡机构编码，9 位，由国家统一设定
	s RegistRqObj.appMode="3"
	s RegistRqObj.payAccType="0"
	s NationCode=$p($g(^CT("NAT",$p(InfoStr,"^",5))),"^",1)
	b   ;11
	s RegistRqObj.nation=NationCode
	
	s RegistRqObj.address=$p(InfoStr,"^",6)
	s RegistRqObj.domainCode=""
	s RegistRqObj.depositBank=""
	s RegistRqObj.bankCardNo=""
	s RegistRqObj.idPic=""
	s RegistRqObj.pcName=""
	s RegistRqObj.pcIp=""
	s RegistRqObj.macId=""
	s RegistRqObj.regChannel="31"
	set ArrayOBJ=##class(%ArrayOfDataTypes).%New()
	set ArrayOBJ=##class(web.INSUCacheJSON).GetAsArrayOfDataTypesFromOBJ(RegistRqObj)
	set JsonInput=##class(web.INSUCacheJSON).Encode(ArrayOBJ)
	b ;JsonInput
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/interfacepregetstaticscode",JsonInput)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/interfacepregetstaticscode",JsonInput)
	
	b ;className  set XML=$zcvt(XML,"I","UTF8")
	
	set Stream=##class(%GlobalCharacterStream).%New()
	set Rtn = Stream.Write(className)
	b ;a0
	d ##Class(ext.util.JsonObject).JSONStreamToObject(Stream,.OutputObj,"DHCDoc.Interface.Outside.TZWYHealthCard.Entity.RegisterRp")
	b ;a1
	s retcode=OutputObj.success
	s msg=OutputObj.msg
	s error=OutputObj.errcode
	s eId=OutputObj.eId
	s qrcode=OutputObj.barcode
	b   ;OutputObj
	;s qrcode=$p(qrcode,":",1)
	if (retcode="1"){
		q retcode_"^"_msg_"^"_eId_"^"_qrcode
	}else{
		q retcode_"^"_msg
	}
}

/// 无身份证建卡
/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).RegisterNoIDCard("王建杰^342901199508011218^18056678861^1^01^山东省威海市环翠区")
ClassMethod RegisterNoIDCard(InfoStr As %String) As %String
{
	s RegistRqObj=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Entity.RegisterNoIDCardRt).%New()
	s RegistRqObj.sex=$p(InfoStr,"^",4)
	s RegistRqObj.institutionCode=..#institutionCode
	s RegistRqObj.regChannel=31
	set ArrayOBJ=##class(%ArrayOfDataTypes).%New()
	set ArrayOBJ=##class(web.INSUCacheJSON).GetAsArrayOfDataTypesFromOBJ(RegistRqObj)
	set JsonInput=##class(web.INSUCacheJSON).Encode(ArrayOBJ)
	;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/createEidAndGetQrCode",JsonInput)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/createEidAndGetQrCode",JsonInput)
	set Stream=##class(%GlobalCharacterStream).%New()
	set Rtn = Stream.Write(className)
	
	d ##Class(ext.util.JsonObject).JSONStreamToObject(Stream,.OutputObj,"DHCDoc.Interface.Outside.TZWYHealthCard.Entity.RegisterNoIDCardRp")
	s retcode=OutputObj.success
	s msg=OutputObj.msg
	s error=OutputObj.errcode
	s eId=OutputObj.eId
	s qrcode=OutputObj.barcode
	b   ;11
	;s qrcode=$p(qrcode,":",1)
	if (retcode="1"){
		q retcode_"^"_msg_"^"_eId_"^"_qrcode
	}else{
		q retcode_"^"_msg
	}
}

/// 新生儿注册建卡
ClassMethod babyRegister(InfoStr As %String) As %String
{
	s RegistRqObj=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Entity.babyRegisterRt).%New()
	s RegistRqObj.motherName=$p(InfoStr,"^",1)
	s RegistRqObj.motherCardNo=$p(InfoStr,"^",2)
	s RegistRqObj.motherCardType=""
	s RegistRqObj.motherPhone=$p(InfoStr,"^",3)
	s RegistRqObj.neonateSex=$p(InfoStr,"^",4)
	s RegistRqObj.parity=""
	s RegistRqObj.institutionCode=..#institutionCode
	s RegistRqObj.appMode=""
	s RegistRqObj.payAccType=""
	s RegistRqObj.nation=$p(InfoStr,"^",5)
	s RegistRqObj.address=$p(InfoStr,"^",6)
	s RegistRqObj.domainCode=""
	s RegistRqObj.depositBank=""
	s RegistRqObj.bankCardNo=""
	s RegistRqObj.idPic=""
	s RegistRqObj.pcName=""
	s RegistRqObj.pcIp=""
	s RegistRqObj.macId=""
	s RegistRqObj.regChannel=""
	set ArrayOBJ=##class(%ArrayOfDataTypes).%New()
	set ArrayOBJ=##class(web.INSUCacheJSON).GetAsArrayOfDataTypesFromOBJ(RegistRqObj)
	set JsonInput=##class(web.INSUCacheJSON).Encode(ArrayOBJ)
	;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/regHealthCardToNeonate",JsonInput)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/regHealthCardToNeonate",JsonInput)
	
	s OutputObj=##class(ext.util.JsonObject).FromJSON(className)
	s retcode=OutputObj.success
	s retmessage=OutputObj.msg
	q json
}

/// 更新新生儿信息
ClassMethod replacebabyRegister(InfoStr As %String) As %String
{
	s RegistRqObj=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Entity.ReplacebabyinfoRt).%New()
	s RegistRqObj.provisionalCardNo=$p(InfoStr,"^",1)
	s RegistRqObj.neonateCardNo=$p(InfoStr,"^",2)
	s RegistRqObj.neonateCardType=""
	s RegistRqObj.neonateName=$p(InfoStr,"^",3)
	s RegistRqObj.motherPhone=""
	s RegistRqObj.neonateSex=$p(InfoStr,"^",4)
	s RegistRqObj.institutionCode=..#institutionCode
	s RegistRqObj.appMode=""
	s RegistRqObj.payAccType=""
	s RegistRqObj.neonateNation=$p(InfoStr,"^",5)
	s RegistRqObj.address=$p(InfoStr,"^",6)
	s RegistRqObj.domainCode=""
	s RegistRqObj.depositBank=""
	s RegistRqObj.bankCardNo=""
	s RegistRqObj.idPic=""
	s RegistRqObj.pcName=""
	s RegistRqObj.pcIp=""
	s RegistRqObj.macId=""
	s RegistRqObj.regChannel=""
	set ArrayOBJ=##class(%ArrayOfDataTypes).%New()
	set ArrayOBJ=##class(web.INSUCacheJSON).GetAsArrayOfDataTypesFromOBJ(RegistRqObj)
	set JsonInput=##class(web.INSUCacheJSON).Encode(ArrayOBJ)
	;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/regHealthCardAndUpdateNeonate",JsonInput)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/regHealthCardAndUpdateNeonate",JsonInput)

	s OutputObj=##class(ext.util.JsonObject).FromJSON(className)
	s retcode=OutputObj.success
	s retmessage=OutputObj.msg
	q json
}

/// 修改信息
/// ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).ReplaceInfo
ClassMethod ReplaceInfo(InfoStr As %String) As %String
{
	s RegistRqObj=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Entity.ReplaceInfoRt).%New()
	s RegistRqObj.eleCardCode=$p(InfoStr,"^",1)
	s RegistRqObj.phone=$p(InfoStr,"^",2)
	s RegistRqObj.address=$p(InfoStr,"^",3)
	s RegistRqObj.depositBank=""
	s RegistRqObj.bankCardNo=""
	set ArrayOBJ=##class(%ArrayOfDataTypes).%New()
	set ArrayOBJ=##class(web.INSUCacheJSON).GetAsArrayOfDataTypesFromOBJ(RegistRqObj)
	set JsonInput=##class(web.INSUCacheJSON).Encode(ArrayOBJ)
	;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/updateEleHealthCard",JsonInput)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/updateEleHealthCard",JsonInput)

	s OutputObj=##class(ext.util.JsonObject).FromJSON(className)
	s retcode=OutputObj.success
	s retmessage=OutputObj.msg
	q json
}

/// 修改信息
/// ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).UpdatePlatPatInfo(PatientID)
ClassMethod UpdatePlatPatInfo(PatientID As %String) As %String
{
	s ^temp("UpdatePlatPatInfo",1)=$lb(PatientID)
	s eleCardCode=##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetCardNoByPAPMIRowID(PatientID)
	q:eleCardCode="" "-1^没有对应的电子就诊号"
	s RegistRqObj=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Entity.ReplaceInfoRt).%New()
	s RegistRqObj.eleCardCode=eleCardCode_":0"
	s RegistRqObj.phone=$P($G(^PAPER(PatientID,"PER",1)),"^",11)
	s RegistRqObj.address=$G(^PAPER(PatientID,"PER","ADD",1))
	s RegistRqObj.depositBank=""
	s RegistRqObj.bankCardNo=""
	set ArrayOBJ=##class(%ArrayOfDataTypes).%New()
	set ArrayOBJ=##class(web.INSUCacheJSON).GetAsArrayOfDataTypesFromOBJ(RegistRqObj)
	set JsonInput=##class(web.INSUCacheJSON).Encode(ArrayOBJ)
	;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/updateEleHealthCard",JsonInput)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/updateEleHealthCard",JsonInput)

	s OutputObj=##class(ext.util.JsonObject).FromJSON(className)
	s retcode=OutputObj.success
	s retmessage=OutputObj.msg
	s ^temp("retcode")=retcode_"^"_retmessage
	q retcode_"^"_retmessage
}

/// 根据二维码获取信息
/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetPatInfoByQrCode("CD8FB8FFEB8AF289C64E85F7690B5DB5D3503671573F5E5D2DA551CA862F5CA3:1::1,53A6AE7569DC69F23074D0D4EF529E0D","010107","0100")
/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetPatInfoByQrCode("992E191793F26E99A1BE1F88FB81F213C7903AF0F103FF61E1B76F1FA7C1848E:1::1,C7B162528C58627EDBF5C3B1D918A988","010101","0100")
/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetPatInfoByQrCode("CD8FB8FFEB8AF289C64E85F7690B5DB5D3503671573F5E5D2DA551CA862F5CA3:1::1,53A6AE7569DC69F23074D0D4EF529E0D","010101","0100")
ClassMethod GetPatInfoByQrCode(Qrcode As %String, medStepCode As %String, deptCode As %String) As %String
{
	s ^TEMP("GetPatInfoByQrCode")=$lb(Qrcode,medStepCode,deptCode)
	s OutputObj={}
	s useTime=$zd(+$h,3)_" "_$zt($p($h,",",2))
	s OutputObj.barCode=Qrcode   // 二維碼
	s OutputObj.deviceCode=..#deviceCode
	s OutputObj.useCityCode=..#useCityCode
	s OutputObj.idCard=""
	s OutputObj.hospitalCode=..#institutionCode // 493590351 正式庫
	s OutputObj.channelCode="01"
	s OutputObj.medStepCode=medStepCode  // 诊疗环节
	s OutputObj.deptCode=deptCode   // 科室代码
	s OutputObj.useTime=useTime
	s OutputObj.returnValueType=""
	set json=OutputObj.%ToJSON()
	;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/getInfoByQrCode",json)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/getInfoByQrCode",json)
	set Stream=##class(%GlobalCharacterStream).%New()
	set Rtn = Stream.Write(className)
	
	d ##Class(ext.util.JsonObject).JSONStreamToObject(Stream,.OutputObj,"DHCDoc.Interface.Outside.TZWYHealthCard.Entity.GetInfobyQrcodeRp")
	s retcode=OutputObj.success
	s retmessage=OutputObj.msg
	// {"phone":"18888888888","cardType":"01","name":"刘一昆","cardNo":"142422198609130016"}
	s name="",phone="",cardType="",cardNo="",eId=""
	if retcode=1 {
		s dataObj=OutputObj.data
		s eId=dataObj.eId // 电子健康卡 ID
		s phone=dataObj.phone // 手机号码
		s cardType=dataObj.cardType // 证件类型
		s name=dataObj.name // 姓名
		s cardNo=dataObj.cardNo // 证件号码
		b ;a1
	}
	// 姓名|性别|民族|出生日期|身份证|患者类型|电话|地址 name_"||||"_cardNo_"|||"_phone
	//q retcode_"^"_retmessage_"^"_name_"^"_phone_"^"_cardType_"^"_cardNo_"^"_eId
	// 姓名|手机号|证件类型|证件号码|电子健康卡卡号
	q retcode_"^"_retmessage_"^"_name_"|"_phone_"|"_cardType_"|"_cardNo_"|"_eId
}

/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetQrCodeByIdCard("142422198609130016")
/// 根据身份证获取二维码
ClassMethod GetQrCodeByIdCard(IDCardNo As %String) As %String
{
	s ^tempztw("GetQrCodeByIdCard")=IDCardNo
	s OutputObj={}
	s OutputObj.idcard=IDCardNo
	s OutputObj.codeType=1
	set json=OutputObj.%ToJSON()
	;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/getQRCodeByIDCard",json)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/getQRCodeByIDCard",json)
	b ;10
	set Stream=##class(%GlobalCharacterStream).%New()
	set Rtn = Stream.Write(className)
	
	d ##Class(ext.util.JsonObject).JSONStreamToObject(Stream,.OutputObj,"DHCDoc.Interface.Outside.TZWYHealthCard.Entity.GetQrCodeByIDCardNoRp")
	b ;11
	s success=OutputObj.success
	s msg=OutputObj.msg
	s eId=OutputObj.eId
	s barcode=OutputObj.barcode
	;s barcode=$p(barcode,":",1)
	if (success="1"){
		q success_"^"_msg_"^"_eId_"^"_barcode
	}else{
		q success_"^"_msg
	}
}

/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).Interfaceprequerycodebyvuid("734301")
/// 根据身份证获取二维码
ClassMethod Interfaceprequerycodebyvuid(PAPMIRowID As %String) As %String
{
	s OutputObj={}
	
	s eleCardCode=##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetCardNoByPAPMIRowID(PAPMIRowID)
	q:eleCardCode="" "-1^没有对应的电子就诊号"
	s OutputObj.eleCardCode=eleCardCode_":0"
	s OutputObj.CodeType=1
	set json=OutputObj.%ToJSON()
	b ;调用平台接口
	//set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	//set className=soap.DZJKMessager("/main/interfaceprequerycodebyvuid",json)
	s className="web.DHCENS.EnsWebService"
	s methodName="DZJKInterface"
	s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/main/interfaceprequerycodebyvuid",json)
	
	set Stream=##class(%GlobalCharacterStream).%New()
	set Rtn = Stream.Write(className)
	b ;-3
	d ##Class(ext.util.JsonObject).JSONStreamToObject(Stream,.OutputObj,"DHCDoc.Interface.Outside.TZWYHealthCard.Entity.GetQrCodeByIDCardNoRp")
	s success=OutputObj.success
	s msg=OutputObj.msg
	s eId=OutputObj.eId
	s barcode=OutputObj.barcode
	;s barcode=$p(barcode,":",1)
	if (success="1"){
		q success_"^"_msg_"^"_eId_"^"_barcode
	}else{
		q success_"^"_msg
	}
}

///  w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetHealthCardInfoByCardNo("62F44E5D0F36B85FBD0A3C4ABD92C19281459AA96AA63C7AD02F3AC94F194107")
ClassMethod GetHealthCardInfoByCardNo(CardNo As %String) As %String
{
	s OutputObj={}
	s OutputObj.eid=CardNo
	set json=OutputObj.%ToJSON()
	
	s className = ##class(web.DHCENS.EnsWebService).DZJKService("/healthService/eleHealthAcc/getHealthAccInfoByEid",json).Read()
	
	b ;zw className
	;set soap=##class(DHCDoc.Interface.Outside.TZWYHealthCard.SOAP.DZJKWebserviceSoap).%New()
	;set className=soap.DZJKMessager("/identityApi/identityVerify",json)
	;s className="web.DHCENS.EnsWebService"
	;s methodName="DZJKInterface"
	;s flag=##class(%Dictionary.MethodDefinition).%ExistsId(className_"||"_methodName)
	;q:flag'=1 "-1^"_className_"."_methodName_"方法不存在,请找数据中心技术支持部署相关接口"
	;set className=##class(web.DHCENS.EnsWebService).DZJKInterface("/healthService/eleHealthAcc/getHealthAccInfoByEid",json)

	;set Stream=##class(%GlobalCharacterStream).%New()
	;set Rtn = Stream.Write(className)
	s OutputObj = {}.%FromJSON(className)
	s success=OutputObj.success
	s errcode=OutputObj.errCode
	b ;;;
	if success=1 {
		s electronicHealthCard = OutputObj.data.electronicHealthCard
		s name=OutputObj.data.name
		s idCardNo=OutputObj.data.idCardNo
		s sexCode=OutputObj.data.sexCode
		s nationCode=OutputObj.data.nationCode
		s hraAddress=OutputObj.data.hraAddress
		s bornDate = OutputObj.data.bornDate
		s bornDate = $zd($zdh(bornDate,8),3)
		;s tel=OutputObj.data.tel
		;s nationName=OutputObj.data.nationName
		s mobilePhone=OutputObj.data.mobilePhone
		b ;;
		s age = ##class(web.UDHCJFCOMMON).DispPatAge($zdh(bornDate,8),"","","",2)
		s age = $p($g(age),"||",1)
		s xml = "<IDRoot>"
		s xml = xml_"<CardNo>"_ electronicHealthCard _"</CardNo>"
		s xml = xml_"<Name>"_ name _"</Name>"
		s xml = xml_"<CredNo>"_ idCardNo _"</CredNo>"
		s xml = xml_"<SexCode>"_ sexCode _"</SexCode>"
		s xml = xml_"<NationDescLookUpID>"_ nationCode _"</NationDescLookUpID>"
		s xml = xml_"<Address>"_ hraAddress _"</Address>"
		s xml = xml_"<Birth>"_ bornDate _"</Birth>"
		s xml = xml_"<TelHome>"_ mobilePhone _"</TelHome>"
		s xml = xml_"<Age>"_ age _"</Age>"
		s xml = xml_"</IDRoot>"
		;q success_"^"_errcode_"^"_electronicHealthCard_"^"_name_"^"_idCardNo_"^"_sexCode_"^"_nationCode_"^"_hraAddress_"^"_bornDate_"^"_mobilePhone
		q "0^"_xml
	}else{
		s errcode=OutputObj.errCode
		s errmsg=OutputObj.errMsg
		q success_"^"_errcode
	}
}

/// 获取电子健康ID
/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetDZJKKCardID()
ClassMethod GetDZJKKCardID() As %String
{
	//q 2
	s CTDRowID=0,DZJKKCardID=""
	f {
		s CTDRowID=$o(^DHCCARDTYPEDef(CTDRowID))
		q:(CTDRowID="")||(DZJKKCardID'="")
		s CTDDesc=$p($g(^DHCCARDTYPEDef(CTDRowID)),"^",2)
		continue:CTDDesc'["电子健康卡"
		s DZJKKCardID=CTDRowID
	}
	q DZJKKCardID
}

/// w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetCardNoByPAPMIRowID("734301")
ClassMethod GetCardNoByPAPMIRowID(PAPMIRowID) As %String
{
	s rtn=""
	q:PAPMIRowID="" rtn
	//s DZJJKCardID=##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetDZJJKCardID()
	s DZJJKCardID=##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).GetDZJKKCardID()
	s CFRowID="" f  s CFRowID=$o(^DHCCARDi("CF",0,"PAPMIDR",PAPMIRowID,CFRowID)) q:CFRowID=""  d
	.s CFActiveFlag=$p(^DHCCARD("CF",CFRowID),"^",10)
	.q:CFActiveFlag'="N"
	.s CFCardTypeID=$p(^DHCCARD("CF",CFRowID),"^",16)
	.q:DZJJKCardID'=CFCardTypeID
	.s rtn=$p(^DHCCARD("CF",CFRowID),"^",2)
	q rtn
}

ClassMethod GetPatientByNo(PAPMIRowID) As %String
{
	s rtn=""
	q:PAPMIRowID="" rtn
	s Name=$p(^PAPER(PAPMIRowID,"ALL"),"^",1)
	s SexDesc=""
	s SexID=$p(^PAPER(PAPMIRowID,"ALL"),"^",7)
	i SexID'="" d
	.s SexDesc=$p(^CT("SEX",SexID),"^",2)
	s rtn=Name_"^"_SexDesc
	q rtn
}

// 根据科室ID 转换为对应的科室代码

ClassMethod GetDeptCode(CTLocID) As %String
{
	s rtn=""
	i CTLocID=1 d
	.s rtn=1
	e  i CTLocID=2 d
	.s rtn=2
	e  i CTLocID=3 d
	.s rtn=3
	e  d
	.s rtn="0100"
	q rtn
}

/// 获取身份证证件类型
ClassMethod GetIDCardDR() As %String
{
    s CredType=""
    s CARDRowId = ""
    f {
        s CARDRowId = $ORDER(^PAC("CARD",CARDRowId)) q:CARDRowId=""
        s CARDDesc=$p($g(^PAC("CARD",CARDRowId)),"^",2)
        i CARDDesc'["身份证" s CredType=CARDRowId
        q:(CredType'="")
    }
    q CredType
}

/// Creator: 
/// Date: 2023-01-31 17:37:23
/// Description:  调用第三方发卡
/// Table: 
/// Input: 
/// Output: 非0^Msg: 失败^报错信息  
///         0^CardNo: 成功^卡号
/// Others: w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).SaveOtherCardInfo(myPatObj, myCardObj)
ClassMethod SaveCardInfo(myPatObj As web.DHCEntity.PCA.PATMAS, myCardObj As web.DHCEntity.PCA.CardRef) As %String
{
	b //---电子健康卡
	s TaticQrcodePhoto=""   //二维码图片
    s ExecHealthCardNo=""
	s myCardTypeDR= myCardObj.CardTypeDefine
		
	if ($g(^DHCDocConfig("RegHealthCardByInterface"))="Y") {
		s PatRowID=myPatObj.PAPMIRowID  //    PAPMIRowID
		//已注册过电子健康卡的患者取历史信息
		s Name=myPatObj.Name
		s SexId=myPatObj.Sex
		s IDCredTypeDr=myPatObj.CredType
		//s IDNo=myPatObj.CredNo
		s TelHome=myPatObj.TelHome
		s Birth=myPatObj.Birth
		s Address=myPatObj.Address
		s ForeignName=myPatObj.ForeignName
		s ForeignPhone=myPatObj.ForeignPhone
		s Nation=myPatObj.NationDescLookUpRowID
		s CardNo=myCardObj.CardNo
		i (CardNo=""){
			;这里增加判断是否为身份证
			s CredTypeDesc=""
			S:myPatObj.CredType'="" CredTypeDesc=$P($G(^PAC("CARD",myPatObj.CredType)),"^",2)
			s:(CredTypeDesc[("身份证")) IDNo=myPatObj.CredNo
			
			b ;生成卡 
			//调用区域数字中心接口获取患者电子健康卡信息
			s PatInfo=Name_"^"_IDNo_"^"_TelHome_"^"_SexId_"^"_Nation_"^"_Address
			if IDNo'="" {
				s ^tempw("PatHealthInfo",1)=PatInfo
				s HealthCardInfo=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).Register(PatInfo)  //去卡管生成电子健康卡
				b ;a2
			}else{
				q "-10001^电子健康卡只能建实名卡"
				//s HealthCardInfo=##Class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).RegisterNoIDCard(PatInfo)  //去卡管生成电子健康卡
			}
			b ;a11
			s ^tempw("PatHealthInfo",2)=HealthCardInfo
			s ReturnCode=$p(HealthCardInfo,"^",1)
			s ErrMsg=$p(HealthCardInfo,"^",2)
			s RhcvId=$p(HealthCardInfo,"^",3)
			s TaticQrcodePhoto=$p(HealthCardInfo,"^",4)
			q:ReturnCode'=1 "-1002^注册患者电子健康卡信息失败"_ErrMsg
			q:RhcvId="" "-1003^获取电子健康卡ID失败"
			// 给卡号赋值为电子健康卡ID
            s ExecHealthCardNo=RhcvId
		}

	}else {
		q "-10001^创建电子健康卡权限关闭，不能建卡"
	}
	s rtn="0"_"^"_ExecHealthCardNo
	b ;a4444
    q rtn
}

/// Creator: 
/// Date: 2023-01-31 17:37:23
/// Description:  根据身份证号生成其他类型his卡
/// Table: 
/// Input: 
/// Output: 非0^Msg: 失败^报错信息  
///         0^CardRowID: 成功^卡号
/// Others: w ##class(DHCDoc.Interface.Outside.TZWYHealthCard.Methods).SaveOtherCardInfo(myPatObj, myCardObj)
ClassMethod SaveOtherCardInfo(myPatObj As web.DHCEntity.PCA.PATMAS, myCardObj As web.DHCEntity.PCA.CardRef) As %String
{
	b ;a1  SaveOtherCardInfo
    ;这里增加判断是否为身份证
    s myrtn=0
    s CredTypeDesc=""
    S:myPatObj.CredType'="" CredTypeDesc=$P($G(^PAC("CARD",myPatObj.CredType)),"^",2)
    s:(CredTypeDesc[("身份证")) IDNo=myPatObj.CredNo
    // 判断患者是否有身份证卡 myPAPMIRowID
    s myPAPMIRowID=myCardObj.PAPMIRowID
    s ExistFlag=0
    s CFRowID=0
    f {
	   s CFRowID=$o(^DHCCARDi("CF",0,"PAPMICTDR",myPAPMIRowID,17,CFRowID)) q:(CFRowID="")
	   s ActiveFlag=$p($g(^DHCCARD("CF",CFRowID)),"^",10)
	   continue:(ActiveFlag'="N")
	   s ExistFlag=1
	}
    
    b ;a1
    i ((IDNo'="")&&(ExistFlag'=1)){
        b  ;保存卡信息ing
        //保存卡信息
        s myCardNewINVRowID=""
        s myGroupRegFlag="PR"

        s myCardObj.CardTypeDefine=17  // 身份证
        s myCardObj.SecurityNo=""
        s myCardObj.CardNo=IDNo
        ;NP,PC,CC
        i myCardNewINVRowID="" d
        .s myCardObj.FareType="NP"
        e  d
        .s myCardObj.FareType="PC"
        ;集团注册
        i (myGroupRegFlag="GR") d
        .s myCardObj.FareType="CC"
        s myCardObj.ActiveFlag="N"		;正常状态

        s myrtn=##class(web.DHCBL.CARD.UCardRefInfo).SaveCardInfo(myCardObj)
        s myCardRowID=$p(myrtn, "^", 2)
        b ;a3
        // s myrtn=+myrtn
    }
    q myrtn
}

}
