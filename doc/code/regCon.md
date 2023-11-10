挂号优惠
三天同科免费

runClassMethod("web.DHCOPAdmReg","GetRegFeeThreeDayFlag",{'PatientId':PatientID},
	function(data){ 
		var RegFeeThreeDayFlag = data
	},"text",false)


// 三日内非零挂号记录
s GetRegFeeThreeDayFlagMethod=##Class(websys.Page).Encrypt($lb("web.DHCOPAdmReg.GetRegFeeThreeDayFlag"))
//全局请求后台服务对象
var ServerObj={
	GetRegFeeThreeDayFlagMethod:"#(GetRegFeeThreeDayFlagMethod)#"
};

---
```js
LoadDeptList() onSelect
var patientid = $("#PatientNo").val();
var dept = $("#DeptList").lookup('getText');
var ret=cspRunServerMethod(ServerObj.GetRegFeeThreeDayFlagMethod,patientid,dept);
if (ret == "Y") {
	PageLogicObj.threedayFlag = "Y"
	LoadRegConDisList();
}
else {
	PageLogicObj.threedayFlag = "N";
	LoadRegConDisList();
}
}
else {
	//$("#RegConDisList").combobox('select','三天同科免费');
	PageLogicObj.threedayFlag = "N";
	LoadRegConDisList();
	$("#RegConDisList").combobox('setValue','');
	$("#RegConDisList").removeClass('disable');
	$("#RegConDisList").next().find('input').removeAttr('disabled');
	$("#RegConDisList").next().find('span').css('display','');
	LoadMarkList();	
}
```

---
```js
LoadRegConDisList()
// 三天优惠
		if (PageLogicObj.threedayFlag != "Y") {
			var json = JSON.parse(Data);
			json = json.filter(item => item.id != 3);
			Data = JSON.stringify(json);
			var flag = false;
		}
		else {
			var flag = true;	
		}
if (PageLogicObj.threedayFlag == "Y") {
	$("#RegConDisList").combobox('setValue',3);
	LoadMarkList();
	}
	else {
	$("#RegConDisList").combobox('setValue','');
	LoadMarkList();
}

```

/// w ##class(web.DHCOPAdmReg).GetRegFeeThreeDayFlag(77, "呼吸内科门诊")

ClassMethod GetRegFeeThreeDayFlag(PatientId, Dept)
{
	q:PatientId=""
	q:Dept=""
	s PatientId = +PatientId
	s RegfeeDepDr = ""
	s RegfeeDepDr = $o(^CTLOC(0,"Desc",Dept,RegfeeDepDr))
	s flag = "N"
	s RegfeeDate = ..%SysDate()
	s RegfeeTime = ..%SysTime()
	&sql(DECLARE mycursor CURSOR FOR
		select Regfeetemp1 into Regfeetemp1
		from SQLUser.DHCRegistrationFee
		where RegfeeAdmDr in (
			select PAADM_RowID
			from SQLUser.PA_Adm
			where PAADM_PAPMI_DR =:PatientId
		) 
		and RegfeeDepDr = :RegfeeDepDr
		and RegfeeDate + 3 >= :RegfeeDate

	)
	&sql(OPEN mycursor)
	
	for {
		&sql(FETCH mycursor)
		;w Regfeetemp1
		;发票ID
    	QUIT:SQLCODE'=0
    	if Regfeetemp1 '= "" {
	    	s flag = "Y"
	    }
	}
	&sql(CLOSE mycursor)
	q flag
}

---
```js
// OPDoc.RepidRegist.hui.js
if(SrcObj && SrcObj.id.indexOf("CardNo")>=0){
	CardNoKeydownHandler(e);
	var patientid = $("#PatNo").val();
	var dept = $("#LocList").combobox('getText');
	var ret=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"GetRegFeeThreeDayFlag",
		dataType:"text",
		PatientId: patientid,
		Dept: dept
	},false);
	if(ret == "Y"){
		PageLogicObj.threedayFlag = "Y"
		LoadRegConDisList();
	}else{
		PageLogicObj.threedayFlag = "N";
		LoadRegConDisList();
	}
	return false;
}
```

```js
// 三天优惠
if (PageLogicObj.threedayFlag != "Y") {
	var json = JSON.parse(Data);
	json = json.filter(item => item.id != 3);
	Data = JSON.stringify(json);
	var flag = false;
}
else {
	var flag = true;
}
var cbox = $HUI.combobox("#RegConDisList", {
		valueField: 'id',
		textField: 'text', 
		panelHeight:'160',
		editable: true,
		disabled: flag,
		data: JSON.parse(Data),
});
if (PageLogicObj.threedayFlag == "Y") {
	$("#RegConDisList").combobox('setValue',3);
	}
	else {
	$("#RegConDisList").combobox('setValue','');
}
```