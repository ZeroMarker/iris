## 修改患者信息接口
DHCExternalService.RegInterface.Service.SelfRegService.cls

DHCExternalService.CardInterface.CardManager.cls

需求背景】:提供住院患者修改个人信息的接口，所需修改的字段已提供
民族（必填）
婚姻状况（必填）
身份证号
籍贯：省、市、县、地址（必填）
现住址：省、市、县、地址（必填）
户口：省、市、县、地址（必填）
联系人：（必填，不能是本人姓名，也不是“本人”俩字）
与患者关系（必填）
联系人电话（必填）
联系人证件类型
联系人证件号
联系人地址（必填）
电脑和小程序信息互通，如果在电脑上填了，手机上也会显示
【使用环境】:住院患者信息修改，接口，互联网医院住院患者信息修改
```objectscript
/// zw ##class(DHCExternalService.CardInterface.CardManager).UpdatePatInfoFromPat("<Request><PatientCard></PatientCard><PAPMINo>0000000001</PAPMINo><PatName>志明</PatName><PAPERMarital>22</PAPERMarital><NationDesc>2</NationDesc><IDNo>320721198708275413</IDNo><Address>山东省泰安市岱岳区泰山大街山一大二附院</Address><ProvinceInfo>四川省</ProvinceInfo><CityDesc>成都市</CityDesc><CityArea>金牛区</CityArea><ProvinceHome>1</ProvinceHome><CityHome>1</CityHome><RegisterPlace>户口地址</RegisterPlace><ProvinceHouse>1</ProvinceHouse><CityHouse>1</CityHouse><AreaHouse>1</AreaHouse><AddressBrith>出生地址</AddressBrith><ProvinceBrith>1</ProvinceBrith><CityBrith>1</CityBrith><AreaBrith>1</AreaBrith><ContactName>小明</ContactName><ContactAddress>山东省</ContactAddress><Relation>177</Relation><ContactTelNo>15233332222</ContactTelNo><ContactIDType>20</ContactIDType><ContactIDNo>320721198708275413</ContactIDNo></Request>")
/// desc: 修改患者信息
/// input: xml
/// output: outputobj
/// debug: zw ##class(DHCExternalService.CardInterface.CardManager).UpdatePatInfoFromPat("<Request><PatientCard></PatientCard><PAPMINo>0000000001</PAPMINo><PatName>志明</PatName><PAPERMarital>未婚</PAPERMarital><NationDesc>汉族</NationDesc><IDNo>320721198708275413</IDNo><Address>山东省泰安市岱岳区泰山大街山一大二附院</Address><ProvinceInfo>现住省份</ProvinceInfo><CityDesc>现住地市</CityDesc><CityArea>现住县区</CityArea><ProvinceHome>籍贯省份</ProvinceHome><CityHome>籍贯地市</CityHome><RegisterPlace>户口地址</RegisterPlace><ProvinceHouse>户口省份</ProvinceHouse><CityHouse>户口地市</CityHouse><AreaHouse>户口县区</AreaHouse><AddressBrith>出生地址</AddressBrith><ProvinceBrith>出生省份</ProvinceBrith><CityBrith>出生地市</CityBrith><AreaBrith>出生县区</AreaBrith><ContactName>小明</ContactName><ContactAddress>山东省</ContactAddress><Relation>174</Relation><ContactTelNo>15233332222</ContactTelNo><ContactIDType>居民身份证</ContactIDType><ContactIDNo>320721198708275413</ContactIDNo></Request>")
ClassMethod UpdatePatInfoFromPat(XMLRequest As %String) As DHCExternalService.CardInterface.Entity.UpdatePatMobileRp
{
        //table                field
        //PA_Adm PAADM_PAPMI_DR        PAADM_RowId
        //PA_Person        PAPMI_RowId        PAPER_PAPMI_DR PAPER_RowId
        
        Set $ZTRAP="UpdatePatInfoFromPatErr"
        s ^tmpnk("UpdatePatInfoFromPat")=XMLRequest
        Set InputObj=##class(DHCExternalService.CardInterface.Entity.UpdatePatRt).%New()
        d InputObj.XMLNodeDeserialize(.InputObj,"Request",XMLRequest)
        Set OutputObj=##class(DHCExternalService.CardInterface.Entity.UpdatePatMobileRp).%New()
        //Set CardTypeCode=InputObj.CardTypeCode
        Set PatientCard=InputObj.PatientCard
        Set PatientID=InputObj.PAPMINo
        Set PatName=InputObj.PatName
        Set NationDesc=InputObj.NationDesc
        Set PAPERMarital=InputObj.PAPERMarital
        Set IDNo=InputObj.IDNo
        //现住
        Set Address=InputObj.Address
        Set ProvinceInfo=InputObj.ProvinceInfo
        Set CityDesc=InputObj.CityDesc
        Set CityArea=InputObj.CityArea
        //籍贯
        Set ProvinceHome=InputObj.ProvinceHome
        Set CityHome=InputObj.CityHome
        //户口
        Set RegisterPlace=InputObj.RegisterPlace
        Set ProvinceHouse=InputObj.ProvinceHouse
        Set CityHouse=InputObj.CityHouse
        Set AreaHouse=InputObj.AreaHouse
        //出生
        Set AdressBrith=InputObj.AddressBrith
        Set ProvinceBrith=InputObj.ProvinceBrith
        Set CityBrith=InputObj.CityBrith
        Set AreaBrith=InputObj.AreaBrith
        //联系人
        set ContactName=InputObj.ContactName
        Set Relation=InputObj.Relation
        set ContactTelNo=InputObj.ContactTelNo
        set ContactIDNo=InputObj.ContactIDNo
        set ContactIDType=InputObj.ContactIDType
        set ContactAddress=InputObj.ContactAddress
        
        if (NationDesc=""){
                d ..SetOutputCode(.OutputObj,"-101","民族不能为空")
                q OutputObj
        }
        if (PAPERMarital=""){
                d ..SetOutputCode(.OutputObj,"-102","婚姻状况不能为空")
                q OutputObj
        }
        if (Address=""){
                d ..SetOutputCode(.OutputObj,"-103","现住址不能为空")
                q OutputObj
        }
        if (ProvinceInfo=""){
                d ..SetOutputCode(.OutputObj,"-1031","现住址省份不能为空")
                q OutputObj
        }
        if (CityDesc=""){
                d ..SetOutputCode(.OutputObj,"-1032","现住址地市不能为空")
                q OutputObj
        }
        if (CityArea=""){
                d ..SetOutputCode(.OutputObj,"-1033","现住址县区不能为空")
                q OutputObj
        }
        /*
        if (HomePlace=""){
                d ..SetOutputCode(.OutputObj,"-104","籍贯地址不能为空")
                q OutputObj
        }
        */
        if (ProvinceHome=""){
                d ..SetOutputCode(.OutputObj,"-1041","籍贯省份不能为空")
                q OutputObj
        }
        if (CityHome=""){
                d ..SetOutputCode(.OutputObj,"-1042","籍贯地市不能为空")
                q OutputObj
        }
        /*
        if (AreaHome=""){
                d ..SetOutputCode(.OutputObj,"-1043","籍贯县区不能为空")
                q OutputObj
        }
        */
        if (RegisterPlace=""){
                d ..SetOutputCode(.OutputObj,"-105","户口地址不能为空")
                q OutputObj
        }
        
        if (ProvinceHouse=""){
                d ..SetOutputCode(.OutputObj,"-1051","户口省份不能为空")
                q OutputObj
        }
        if (CityHouse=""){
                d ..SetOutputCode(.OutputObj,"-1052","户口地市不能为空")
                q OutputObj
        }
        if (AreaHouse=""){
                d ..SetOutputCode(.OutputObj,"-1053","户口县区不能为空")
                q OutputObj
        }
        if (AdressBrith=""){
                d ..SetOutputCode(.OutputObj,"-110","出生地址不能为空")
                q OutputObj
        }
        
        if (ProvinceBrith=""){
                d ..SetOutputCode(.OutputObj,"-1101","出生省份不能为空")
                q OutputObj
        }
        if (CityBrith=""){
                d ..SetOutputCode(.OutputObj,"-1102","出生地市不能为空")
                q OutputObj
        }
        if (AreaBrith=""){
                d ..SetOutputCode(.OutputObj,"-1103","出生县区不能为空")
                q OutputObj
        }
        if (ContactAddress=""){
                d ..SetOutputCode(.OutputObj,"-106","联系人地址不能为空")
                q OutputObj
        }
        if (ContactTelNo=""){
                d ..SetOutputCode(.OutputObj,"-107","联系人电话不能为空")
                q OutputObj
        }
        if (Relation=""){
                d ..SetOutputCode(.OutputObj,"-108","联系人与患者关系不能为空")
                q OutputObj
        }
        if (ContactName=""){
                d ..SetOutputCode(.OutputObj,"-109","联系人姓名不能为空")
                q OutputObj
        }
        if (ContactName=PatName){
                d ..SetOutputCode(.OutputObj,"-1091","联系人姓名不能为本人姓名")
                q OutputObj
        }
        if (ContactName="本人"){
                d ..SetOutputCode(.OutputObj,"-1092","联系人姓名不能为”本人“")
                q OutputObj
        }
        
        /*if (IDNo=""){
                ;s OutputObj.ResultCode="-1"
                ;s OutputObj.ResultContent="证件号不能为空"
                ;quit OutputObj
        }else{
                if (IDType=""){        
                        d ..SetOutputCode(.OutputObj,"-106","证件类型不能为空")
                        q OutputObj
                }
        }*/
        //s IDCardType=""
        s PatientRowId=$o(^PAPERi("PAPMI_PatNo",$ZCVT(PatientID,"U"),""))
        s person = ##class(User.PAPerson).%OpenId(PatientRowId)
        s dhcpersonid = $ORDER(^DHCPERSON(0,"PAPERSON",PatientRowId,0)) //^DHCPERSON(0,"PAPERSON",PatinentRowId,0)
        
        s dhcperson = ##class(User.DHCPerson).%OpenId(dhcpersonid)
        //s person.PAPMIRowID=myPatientID
        //s person.PAPMINo=PatientNo
        
        /// id=>row_id
        
        // HomePlace AreaHome
        // ProvinceHouse As %String
        if IDNo'="" {
                s person.PAPERID=IDNo
        }
        if Address'="" {
                Do person.PAPERStName.Clear()
                Do person.PAPERStName.Insert(Address)
        }
        if NationDesc'=""{
	        If '(+NationDesc=NationDesc) {
		        s NationDesc = ..GetDesc("Nation", NationDesc)
			}
                        d person.PAPERNationDRSetObjectId(NationDesc)
        }
        if PAPERMarital'=""{
	        If '(+PAPERMarital=PAPERMarital) {
    			s PAPERMarital = ..GetDesc("Marital", PAPERMarital)
			}
                        d person.PAPERMaritalDRSetObjectId(PAPERMarital)
        }
        if ProvinceInfo'=""{
	        If '(+ProvinceInfo=ProvinceInfo) {
    			s ProvinceInfo = ..GetDesc("Province", ProvinceInfo)
			}
                        d person.PAPERCTProvinceDRSetObjectId(ProvinceInfo)
        }
        if CityArea'=""{
	        If '(+CityArea=CityArea) {
    			s CityArea = ..GetDesc("Area",CityArea)
			}
                        d person.PAPERCityAreaDRSetObjectId(CityArea)
        }
        if CityDesc'=""{
	        If '(+CityDesc=CityDesc) {
    			s CityDesc = ..GetDesc("City",CityDesc)
			}
                        d person.PAPERCityCodeDRSetObjectId(CityDesc)
        }
        //籍贯
        if ProvinceHome'=""{
	        If '(+ProvinceHome=ProvinceHome) {
    			s ProvinceHome = ..GetDesc("Province",ProvinceHome)
			}
                        d person.PAPERProvinceBirthDRSetObjectId(ProvinceHome)
        }
        if CityHome'=""{
	        If '(+CityHome=CityHome) {
    			s CityHome = ..GetDesc("City", CityHome)
			}
                        d person.PAPERCityBirthDRSetObjectId(CityHome)
        }
        //户口
        if RegisterPlace'=""{
                        s dhcperson.PAPERHouseAddress=RegisterPlace
        }
        if ProvinceHouse'=""{
	        If '(+ProvinceHouse=ProvinceHouse) {
    			s ProvinceHouse = ..GetDesc("Province",ProvinceHouse)
			}
                        //d dhcperson.PAPERHouseProvinceDRSetObjectId(ProvinceHouse)
                        s dhcperson.PAPERHouseProvinceDR=ProvinceHome
        }
        if CityHouse'=""{
	        If '(+CityHouse=CityHouse) {
    			s CityHouse = ..GetDesc("City", CityHouse)
			}
                        //d dhcperson.PAPERHouseCityDRSetObjectId(CityHouse)
                        s dhcperson.PAPERHouseCityDR=CityHouse
        }
        if AreaHouse'=""{
	        If '(+AreaHouse=AreaHouse) {
    			s AreaHouse = ..GetDesc("Area",AreaHouse)
			}
                        //d dhcperson.PAPERHouseAreaDRSetObjectId(AreaHouse)
                        s dhcperson.PAPERHouseAreaDR=AreaHouse
        }
        //出生
        if AdressBrith'=""{
                        s dhcperson.PAPERBirthAddress=AdressBrith
        }
        if ProvinceBrith'=""{
	        If '(+ProvinceBrith=ProvinceHome) {
    			s ProvinceHome = ..GetDesc("Province",ProvinceHome)
			}
                        //d dhcperson.PAPERHouseProvinceDRSetObjectId(ProvinceHouse)
                        s dhcperson.PAPERBirthProvinceDR=ProvinceBrith
        }
        if CityBrith'=""{
	        If '(+CityBrith=CityBrith) {
    			s CityBrith = ..GetDesc("City", CityBrith)
			}
                        //d dhcperson.PAPERHouseCityDRSetObjectId(CityHouse)
                        s dhcperson.PAPERBirthCityDR=CityBrith
        }
        if AreaBrith'=""{
	        If '(+AreaBrith=AreaBrith) {
    			s AreaBrith = ..GetDesc("Area",AreaBrith)
			}
                        //d dhcperson.PAPERHouseAreaDRSetObjectId(AreaHouse)
                        s dhcperson.PAPERBirthAreadr=AreaBrith
        }
        //联系人
        if ContactIDType'=""{
	       	If '(+ContactIDType=ContactIDType) {
    			s ContactIDType = ..GetDesc("Card",ContactIDType)
			}
            d person.PAPERForeignCardTypeDRSetObjectId(ContactIDType)
        }
        if ContactIDNo'=""{
            s person.PAPERForeignCountry=ContactIDNo
        }
        if ContactName'=""{
            s person.PAPERForeignId=ContactName
        }
        if Relation'=""{
	        If '(+Relation=Relation) {
    			s Relation = ..GetDesc("Relation", Relation)
			}
            d person.PAPERCTRLTDRSetObjectId(Relation)
        }
        if ContactTelNo'=""{
            s person.PAPERForeignPhone=ContactTelNo
        }
        if ContactAddress'=""{
           	s person.PAPERForeignAddress=ContactAddress
        }
        
        //s:ContactIDNo'="" person.PAPERForeignId =ContactIDNo
        //s:ContactIDTypeID'="" person.PAPERForeignCardTypeDR=ContactIDTypeID
        //s:ContactName'="" person.ForeignName=ContactName
        //s:ContactAddress'="" person.ForeignAddress=ContactAddress
        //s:ContactTelNo'="" person.ForeignPhone=ContactTelNo
        Set sc = person.%Save()
        ;PersonSave
        If ($System.Status.IsError(sc))
        {
                Do $System.Status.DisplayError(sc)
                s OutputObj.ResultCode="-100"
                s OutputObj.ResultContent="更新失败"
        }
        else
        {
                s OutputObj.ResultCode="0"
                s OutputObj.ResultContent="更新成功"
        }
        Set sd = dhcperson.%Save()
        If ($System.Status.IsError(sc))
        {
                Do $System.Status.DisplayError(sc)
                s OutputObj.ResultCode="-100"
                s OutputObj.ResultContent="更新失败"
        }
        else
        {
                s OutputObj.ResultCode="0"
                s OutputObj.ResultContent="更新成功"
        }
        quit OutputObj
UpdatePatInfoFromPatErr
        if $TLEVEL>0{
            TRO
        }
        Set OutputObj=##class(DHCExternalService.CardInterface.Entity.UpdatePatMobileRp).%New()
        Set OutputObj.ResultCode="-1"
        Set OutputObj.ResultContent="更新失败:"_$ZError
        quit OutputObj
}

ClassMethod GetDesc(Target, DR)
{
	s DR = $zcvt(DR,"U")
	if Target = "Nation"{
		q $o(^CT("NAT",0,"Desc",DR,""))
	}
	if Target = "Card"{
		q $o(^PAC("CARD", 0, "Desc", DR, ""))
	}
	if Target = "Province"{
		q $o(^CT("PROV",0,"Desc",DR,""))
	}
	if Target = "City"{
		q $o(^CT("CIT",0,"Desc",DR,""))
	}
	if Target = "Area"{
		q $o(^CT("CITAREA",0,"Desc",DR,""))
	}
	if Target = "Marital"{
		q $o(^CT("MAR",0,"Desc",DR,""))
	}
	if Target = "Relation"{
		q $o(^CT("RLT",0,"Desc",DR,""))
	}
	;d @("case"_$g(^||addr(Target),"Default"))
}
```