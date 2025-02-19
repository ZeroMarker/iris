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