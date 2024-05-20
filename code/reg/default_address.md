```js
///dhcbill.ipbill.reg.js
//默认现住地址信息
	var regDefObj = new X2JS().xml_str2json(CV.PatUIDefXMLStr).DHCCardRegInfoDefault;
	var url = $URL + "?ClassName=web.DHCIPBillReg&QueryName=FindCountry&ResultSetType=array&type=GET&desc=";
	$("#Country").combobox("reload", url).combobox("setValue", regDefObj.CountryDescLookUpRowID);
	$.cm({
		ClassName: "web.DHCIPBillReg",
		QueryName: "FindProvince",
		ResultSetType: "array",
		type: "GET",
		desc: "",
		countryId: regDefObj.CountryDescLookUpRowID
	}, function(data) {
		$("#Province, #BirthProv, #HouseProv").combobox("loadData", data);
		if ($.hisui.indexOfArray(data, "id", regDefObj.ProvinceInfoLookUpRowID) != -1) {
			$("#Province").combobox("setValue", regDefObj.ProvinceInfoLookUpRowID);
			$("#BirthProv").combobox("setValue", regDefObj.ProvinceInfoLookUpRowID);	//zfb-add 2023.2.7 增加出生地 省市
		}		
	});
	
	url = $URL + "?ClassName=web.DHCIPBillReg&QueryName=FindCity&ResultSetType=array&type=GET&desc=&provId=" + regDefObj.ProvinceInfoLookUpRowID;
	$("#City").combobox("reload", url).combobox("setValue", regDefObj.CityDescLookUpRowID);
	$("#BirthCity").combobox("reload", url).combobox("setValue", regDefObj.CityDescLookUpRowID);	//zfb-add 2023.2.7 增加出生地 省市
	url = $URL + "?ClassName=web.DHCIPBillReg&QueryName=FindCityArea&ResultSetType=array&type=GET&desc=&cityId=" + regDefObj.CityDescLookUpRowID;
	$("#CityArea").combobox("reload", url);
	$("#BirthArea").combobox("reload", url);


$HUI.combobox("input[id$='Area']", {
		panelHeight: 150,
		method: 'GET',
		valueField: 'id',
		textField: 'text',
		blurValidValue: true,
		defaultFilter: 5,
		onSelect: function (rec) {
			//取邮编
			if ($(this)[0].id == "CityArea") {
				setPostCode("", "", rec.id, "PostCode");
			}else if ($(this)[0].id == "HouseArea") {
				setPostCode("", "", rec.id, "HousePostCode");
			}else if ($(this)[0].id == "BirthArea") {
				setPostCode("", "", rec.id, "CompanyPostCode");
			}
		}
	});
```