## 挂号优惠三天同科免费

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
// OPAdm.Reg.hui.js
function LoadDeptList(){
	$("#DeptList").lookup({
        url:$URL,
        mode:'remote',
        method:"Get",
        idField:'CTCode',
        textField:'CTDesc',
        columns:[[  
            {field:'CTCode',title:'',hidden:true},
			{field:'CTDesc',title:'科室名称',width:350}
        ]], 
        pagination:true,
        panelWidth:400,
        isCombo:true,
        minQueryLen:2,
        delay:'500',
        queryOnSameQueryString:false,
        queryParams:{ClassName: 'web.DHCOPAdmReg',QueryName: 'OPDeptList'},
        onBeforeLoad:function(param){
	        var desc=param['q'];
	        //if (desc=="") return false;
	        var OutStatus=$("#cOutStatus").checkbox('getValue')?'1':'';
		    var InStatus=$("#cInStatus").checkbox('getValue')?'1':'';
		    var DisInStatus=$("#cDisInStatus").checkbox('getValue')?'1':'';
			param = $.extend(param,{UserId:session['LOGON.USERCODE'], AdmType:"", paradesc:desc});
	    },
	    onSelect:function(index, rec){
		    setTimeout(function(){
				if (rec!=undefined){
					PageLogicObj.m_deptRowId=rec["CTCode"];
					$("#SelLoc").html(rec["CTDesc"]);
					PageLogicObj.m_DocRowId="";  
					$("#MarkCode").lookup('setText','');
					LoadClinicServiceGroup(rec["CTCode"]);
					//$("#ClinicServiceGroup").combobox('setValue','');
					PageLogicObj.m_ClinicServiceGroupRowId=""
					LoadMarkList();
					$("#DeptList").blur();
					var patientid = $("#PatientNo").val();
					var dept = $("#DeptList").lookup('getValue');
					var ret=cspRunServerMethod(ServerObj.GetRegFeeThreeDayFlagMethod,patientid,dept);
					if (ret == "Y") {
						PageLogicObj.threedayFlag = "Y"
						LoadRegConDisList();
					}
					else {
						PageLogicObj.threedayFlag = "N";
						LoadRegConDisList();
					}
				}else{
					//$("#ClinicServiceGroup").combobox('select',"");
					PageLogicObj.m_ClinicServiceGroupRowId=""
					PageLogicObj.m_DocRowId="";  
					$("#MarkCode").lookup('setText','');
				}
			});
		}
    });
}
```

---
```js
function LoadRegConDisList(){
	if($("#RegConDisList").length==0){
		return	
	}
	$.m({
		ClassName:"web.DHCRegConDisCount", 
		MethodName:"ReadDHCRegConDisCountBroker",
		JSFunName:"GetRegConToHUIJson",
		ListName:"",
		PatientID:$('#PatientID').val(),
		BillTypeID:$('#BillType').combobox('getValue')
	},function(Data){
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
				editable: true,
				disabled: flag,
				data: JSON.parse(Data),
				onSelect:function(rec){
					if (rec!=undefined){
						if (PageLogicObj.m_selectedMarkListDataGrid!=""){
							$("#selectedMarkList").datagrid("uncheckAll");
							var Data=$("#selectedMarkList").datagrid("getRows");
							for (var i=Data.length-1;i>=0;i--){
								$("#selectedMarkList").datagrid("selectRow",i);
								DelSelMarkListRow();
							}
							LoadMarkList();
							// 预约取号选择优惠类型会把预约信息清空
							var PatientID=$("#PatientID").val();
							var AppSerialNo=$("#AppSerialNo").val();
							if (AppSerialNo==undefined) AppSerialNo="";
							if (AppSerialNo!="") {
								AppSerialNoBlurHandler();
							}else{
								GetApptInfo(PatientID);
							}
							MedicalBookChange()
						}
					}
				},
				onChange:function(newValue,OldValue){
					if (newValue==""){
						$("#RegConDisList").combobox('select',"");
						if (PageLogicObj.m_selectedMarkListDataGrid!=""){
							$("#selectedMarkList").datagrid("uncheckAll");
							var Data=$("#selectedMarkList").datagrid("getRows");
							for (var i=Data.length-1;i>=0;i--){
								$("#selectedMarkList").datagrid("selectRow",i);
								DelSelMarkListRow();
							}
							LoadMarkList();
						}
					}
				}
		 });
		 if (PageLogicObj.threedayFlag == "Y") {
			$("#RegConDisList").combobox('setValue',3);
			LoadMarkList();
		 }
		 else {
			$("#RegConDisList").combobox('setValue','');
			LoadMarkList();
		}
	});
}

```objectscript
/// desc: 三日内是否有非零元挂号费
/// input: PatientId, CTLoc
/// output: flag
/// 			Y 三日内有非零元挂号费
/// 			N 三日内没有非零元挂号费
/// debug: w ##class(web.DHCOPAdmReg).GetRegFeeThreeDayFlag(575, 24)
ClassMethod GetRegFeeThreeDayFlag(PatientId, Dept)
{
	q:PatientId=""
	q:Dept=""
	s PatientId = +PatientId
	s RegfeeDepDr = Dept
	;s RegfeeDepDr = $o(^CTLOC(0,"Desc",Dept,RegfeeDepDr))
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
				and PAADM_VisitStatus = "A"
		) 
		and RegfeeDepDr = :RegfeeDepDr
		and RegfeeDate + 3 >= :RegfeeDate  
		and RegfeeArcPrice > 0
	)
	&sql(OPEN mycursor)
	
	for {
		&sql(FETCH mycursor)
    	QUIT:SQLCODE'=0
    	;发票ID
    	;s status = $p(^PAADM(adm),"^",20)
    	if (Regfeetemp1 '= "") {
	    	s flag = "Y"
	    }
	}
	&sql(CLOSE mycursor)
	/*
	s EpisodeId = 0
	for {
		s EpisodeId = $o(^PAPERdr(PatientId,"ADM","O",EpisodeId))
		q:EpisodeId=""
		s status=$p(^PAADM(EpisodeId),"^",20)
		continue:status'="A"
		s dept=$p(^PAADM(EpisodeId),"^",4)
		continue:dept'=Dept
		s date=$p(^PAADM(EpisodeId),"^",6)
		continue:date+3>RegfeeDate
		;s regCon=$p(^PAADM(EpisodeId,"DHC"),"^",25)
		s regfeeId = ^User.DHCRegistrationFeeI("ADM",EpisodeId)
		s temp1 = $lg(^User.DHCRegistrationFeeI,11)	;发票
		continue:temp1=""
		s price = $lg(^User.DHCRegistrationFeeI,4)
		s:price>0 flag="Y"
	}
	*/
	q flag
}

---
```js
// OPDoc.RepidRegist.hui.js
if(SrcObj && SrcObj.id.indexOf("CardNo")>=0){
	CardNoKeydownHandler(e);
	var patientid = $("#PatNo").val();
	var dept = $("#LocList").combobox('getValue');
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