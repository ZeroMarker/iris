var PageLogicObj={
	m_RegReturnListTabDataGrid:"",
	dw:$(window).width()-400,
	dh:$(window).height()-100,
	toolbar:"",
	m_CardNoFlag:0,
    m_ReturnReason:""
}
$(function(){
	//初始化
	Init();
	//事件初始化
	InitEvent();
	//页面元素初始化
	PageHandle();
	$("#CardNo").focus();
})
$(window).load(function() {
	$.DHCDoc.setKeyDesc()
	//InitCSPShortcutKey("opadm.return.hui.csp");
	//如不进行toolbar 按钮text描述修改,会在表格加载数据时清空toolbar里面快捷键
	ReSetGridToolBar();
})
function ReSetGridToolBar(){
	var opts = PageLogicObj.m_RegReturnListTabDataGrid.datagrid('options');
	for (var i=0;i<opts.toolbar.length;i++){
		var id=opts.toolbar[i].id;
		if ((id)&&($("#"+id).length>0)){
			opts.toolbar[i].text=$("#"+id+" .l-btn-text")[0].innerText;
		}
	}
}
function InitEvent(){
	$("#Find").click(RegReturnListTabDataGridLoad);
	$('#CardNo').change(CardNoChange);
	$('#CardNo').blur(CardNoOnBlur);
	$('#InvoiceNo').change(InvoiceNoChange);
	$("#nday").change(ndayChange);
	$(document.body).bind("keydown",BodykeydownHandler);
	$("#Accpinv").click(AccpinvClick)
}
function BodykeydownHandler(e){
	if (window.event){
		var keyCode=window.event.keyCode;
		var type=window.event.type;
		var SrcObj=window.event.srcElement;
	}else{
		var keyCode=e.which;
		var type=e.type;
		var SrcObj=e.target;
	}
	//回车事件或者
	if (keyCode==13) {
		if(SrcObj && SrcObj.id.indexOf("RegNo")>=0){
			RegNoKeydownHandler(e);
			return false;
		}else if(SrcObj && SrcObj.id.indexOf("CardNo")>=0){
			PageLogicObj.m_CardNoFlag=1;
			CardNoKeydownHandler(e);
			return false;
		}
		return true;
	}/*else if(keyCode==117){ //F6 换号
		SwichRegclickHandle();
	}else if(keyCode==118){ //F7 原号重打
		OldRegPrintClickHandler();
	}else if(keyCode==119){ //F8 作废重打
		ReprintClickHandler();
	}else if(keyCode==120){ //F9 退号
		UpdateclickHandler("");
	}*/
	window.onhelp = function() { return false };
	return true;
}
function ReturnMRClickHandler()
{
	var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
	if (row){
		//勾选改变事件推入堆栈,否则会出现先执行change事件，在改成checkbox的勾选属性
		setTimeout(function(){SetReturnSum(row);});
	}
}
function PageHandle(){
	//发票号流水号
	GetReceiptNo();
	//退号原因
	LoadReturnReason();
	if (ServerObj.EpisodeID!=""){
		var str=$.cm({
			ClassName:"web.DHCDocOrderItemList",
			MethodName:"GetPAADMInfo",
			dataType:"text",
			PaadmId:ServerObj.EpisodeID
		},false)
		var PatNo=str.split(" ")[1];
		$("#RegNo").val(PatNo);
		RegReturnListTabDataGridLoad();
	}else if (ServerObj.RegNo!=""){
        $("#RegNo").val(ServerObj.RegNo);
        RegReturnListTabDataGridLoad();
    }
	//支付方式
	LoadPayMode();
	//读卡按钮
	CardCommon_ControlObj.Init({
		id:"ReadCard",
		callBackFun:CardNoKeyDownCallBack
	});
}
function Init(){
	PageLogicObj.m_RegReturnListTabDataGrid=InitRegReturnListTabDataGrid();
}
function InitRegReturnListTabDataGrid(){
	PageLogicObj.toolbar=[{
		id:"Update",
		text:"退号", //(F9)
		iconCls: 'icon-exe-order',
		handler: function(){UpdateclickHandler("")}
	},{
		text:"退病历本",
		iconCls: 'icon-exe-order',
		handler: function(){CancelMedicalBookclickHandle()}
	},'-',{
		id:"SwichReg",
		text:"换号", //(F6)
		iconCls: 'icon-change-loc',
		handler: function(){SwichRegclickHandle()}
	},'-',{
		text:"修改患者类型及就诊费别",
		iconCls: 'icon-edit',
		handler: function(){UpdatePatAdmReasonClickHandle()}
	},'-',{
		id:"OldRegPrint",
		text:"原号重打", //(F7)
		iconCls: 'icon-print',
		handler: function(){OldRegPrintClickHandler()}
	},{
		id:"Reprint",
		text:"作废重打",
		iconCls: 'icon-print', //(F8)
		handler: function(){ReprintClickHandler()}
	},{
		id:"ReprintRegist",
		text:"挂号小条重打",
		iconCls: 'icon-print',
		handler: function(){ReprintRegist()}
	}]

	var Columns=[[ 
		{field:'AdmId',hidden:true,title:''},
		{field:'Dept',title:'科室',width:100},
		{field:'Doctor',title:'医生',width:100},
		{field:'Regno',title:'登记号',width:105},
		{field:'PatName',title:'患者姓名',width:100},
		{field:'Tph',title:'诊号',width:50},
		{field:'UserName',title:'挂号员',width:80},
		{field:'TabPrice',title:'金额',width:50},
		{field:'TabDate',title:'就诊日期',width:100},
		{field:'RegfeeDate',title:'挂号日期',width:90},
		{field:'RegfeeTime',title:'挂号时间',width:80},
		{field:'TabInvoiceNo',title:'发票号',width:100},
		{field:'TabEinvprtNo',title:'电子票号',width:100},
		{field:'TabReturnFlag',title:'退号标识',showTip:true,width:140,
			styler: function(value,row,index){
				if (value!="可退"){
					return 'background-color:red;color:#fff;';
				}
			}
		},
		{field:'TabTRDoc',title:'替诊医生',width:100},
		{field:'TabRBASStatus',title:'医生状态',width:80},
		{field:'TabRegType',title:'预约',width:50,align:'center',
			editor : {
                type : 'icheckbox',
                options : {
                    on : '1',
                    off : '0',
                    disabled:true
                }
           }
		},
		{field:'TabAppFee',title:'预约费',width:50},
		{field:'RBASStatusReason',title:'停替诊原因',width:100},
		{field:'INVPayMode',title:'支付方式',showTip:true,width:90},
		{field:'RegFee',title:'挂号费',width:50},
		{field:'CheckFee',title:'诊疗费',width:50},
		{field:'MRFee',title:'病历本费',width:50},
		{field:'ReCheckFee',title:'复诊费',width:50},
		{field:'HoliFee',title:'假日费',width:50},
		{field:'OtherFee',title:'其他费',width:50,hidden:true},
		{field:'TabTime',title:'',hidden:true},
		{field:'AdmReasonId',title:'',hidden:true},
		{field:'InsuAdmInfoDr',title:'',hidden:true},
		{field:'PatDr',title:'',hidden:true},
		{field:'ChangeSum',title:'',hidden:true},
		{field:'TRSum',title:'',hidden:true},
		{field:'TabRBASStatusCode',title:'',hidden:true},
		{field:'TabTRRBASRowId',title:'',hidden:true},
		{field:'TabRBASRowId',title:'',hidden:true},
		{field:'RegfeeRowId',title:'',hidden:true},
		{field:'InvoiceId',title:'',hidden:true},
		{field:'Arcdr',title:'',hidden:true},
		{field:'Doctorid',title:'',hidden:true},
		{field:'Deptid',title:'',hidden:true}
    ]]
	var RegReturnListTabDataGrid=$("#RegReturnListTab").datagrid({
		fit : true,
		border : false,
		striped : true,
		singleSelect : true,
		fitColumns : false,
		autoRowHeight : false,
		rownumbers:true,
		pagination : true,  
		rownumbers : true,  
		pageSize: 20,
		pageList : [20,100,200],
		idField:'AdmId',
		columns :Columns,
		toolbar:PageLogicObj.toolbar,
		onSelect:function(index, row){
			if (!row) return;
			SetReturnSum(row);
			$("#RegNo").val(row["Regno"]); 
			$("#PatientID").val(row["PatDr"]);
		},
		onLoadSuccess:function(data){
			//默认选中第一行
			if (data["total"]>0){
				var index=0;
				if (ServerObj.EpisodeID!=""){
					index=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getRowIndex",ServerObj.EpisodeID);
				}
				if (index<0) index=0;
				PageLogicObj.m_RegReturnListTabDataGrid.datagrid("checkRow",index);
			}
			for (var i=0;i<data.rows.length;i++){
				PageLogicObj.m_RegReturnListTabDataGrid.datagrid('beginEdit',i);
			}
		},
		onRowContextMenu:function(e, index, row){
			e.preventDefault(); //阻止浏览器捕获右键事件
			PageLogicObj.m_RegReturnListTabDataGrid.datagrid("selectRow",index);
			setTimeout(function(){ShowGridRightMenu(e,index, row);});
		}
	}).datagrid({loadFilter:DocToolsHUI.lib.pagerFilter})
	RegReturnListTabDataGrid.datagrid("load",{ });
	return RegReturnListTabDataGrid;
}
function ShowGridRightMenu(e,rowIndex, rowData){
	$("#RightKeyMenu").empty(); //	清空已有的菜单
	for (var i=0;i<PageLogicObj.toolbar.length;i++){
		if (PageLogicObj.toolbar[i]=="-") continue;
		var id=PageLogicObj.toolbar[i]["id"];
		var text=PageLogicObj.toolbar[i]["text"];
		var iconCls=PageLogicObj.toolbar[i]["iconCls"];
		var handler=PageLogicObj.toolbar[i]["handler"];
        $('#RightKeyMenu').menu('appendItem', {
            id:id,
			text:text,
			iconCls: iconCls, 
			onclick: eval(handler)
		});
    }
    $('#RightKeyMenu').menu('show', {  
        left: e.pageX,         //在鼠标点击处显示菜单
        top: e.pageY
    });
}

function RegReturnListTabDataGridLoad(){
	PageLogicObj.m_RegReturnListTabDataGrid.datagrid('unselectAll');
	var RegNo=$('#RegNo').val();
	var InvoiceNo=$('#InvoiceNo').val();
	if ((CardNo=='')&&(InvoiceNo=='')&&(RegNo=='')){
		$.messager.alert("提示","请输入查询条件!","info",function(){
			$('#CardNo').focus();
		});
		return false;
	}
	$.q({
	    ClassName : "web.DHCOPAdmReg",
	    QueryName : "DHCOPAdm",
	    RegNo:$("#RegNo").val(),
	    nday:$("#nday").val(),
	    InvoiceNo:$("#InvoiceNo").val(),
	    PatientID:$("#PatientID").val(),
	    UserRowId:session['LOGON.USERID'],
	    QueryCancel:"",
	    RegDate:$("#RegDate").datebox('getValue'),
	    Pagerows:PageLogicObj.m_RegReturnListTabDataGrid.datagrid("options").pageSize,rows:99999
	},function(GridData){
		if ((GridData['rows'].length>0)&&(GridData['rows'][0]['AdmId']=="")){
			RegReturnListTabDataGrid.datagrid("load",{ });
			//PageLogicObj.m_RegReturnListTabDataGrid.datagrid('loadData', {"total":0,"rows":[]});
		}else{
			PageLogicObj.m_RegReturnListTabDataGrid.datagrid('loadData',GridData);
		}
	}); 
}
function pagerFilter(data){
	if (typeof data.length == 'number' && typeof data.splice == 'function'){	// is array
		data = {
			total: data.length,
			rows: data
		}
	}
	var dg = $(this);
	var opts = dg.datagrid('options');
	var pager = dg.datagrid('getPager');
	pager.pagination({
		showRefresh:false,
		onSelectPage:function(pageNum, pageSize){
			opts.pageNumber = pageNum;
			opts.pageSize = pageSize;
			pager.pagination('refresh',{
				pageNumber:pageNum,
				pageSize:pageSize
			});
			dg.datagrid('loadData',data);
			dg.datagrid('scrollTo',0); //滚动到指定的行        
		}
	});
	if (!data.originalRows){
		data.originalRows = (data.rows);
	}
	var start = (opts.pageNumber-1)*parseInt(opts.pageSize);
	if ((start+1)>data.originalRows.length){
		//取现有行数最近的整页起始值
		start=Math.floor((data.originalRows.length-1)/opts.pageSize)*opts.pageSize;
		opts.pageNumber=opts.pageNumber-1;
	}
	var end = start + parseInt(opts.pageSize);
	data.rows = (data.originalRows.slice(start, end));
	return data;
}
function RegNoKeydownHandler(e){
	var key=websys_getKey(e);
	if (key==13) {
		var RegNo=$("#RegNo").val();
		var len = tkMakeServerCall("web.DHCCLCom","GetPatConfig");
		len = len.split("^")[0];
		if (RegNo!="") {
			if (RegNo.length<len){
				for (var i=(len-RegNo.length-1); i>=0; i--) {
					RegNo="0"+RegNo
				}
			}
		}
		$("#RegNo").val(RegNo);
		RegReturnListTabDataGridLoad();
	}
}
function InvoiceNoChange(){
	var InvoiceNo=$("#InvoiceNo").val();
	if (InvoiceNo==""){
		$("#CardNo,#CardTypeNew,#PatientID,#RegNo").val('');
	}
}
function CardNoChange(){
	var CardNo=$("#CardNo").val();
	if (CardNo=="") {
		$("#CardTypeNew").val("");
		PageLogicObj.m_CardNoFlag=0;
	}
}
function CardNoOnBlur(){
	var PatientID=$("#PatientID").val();
	if ((PatientID=="")&&(PageLogicObj.m_CardNoFlag==0)){
		CheckCardNo();
	}
}
function CardNoKeydownHandler(e){
	var key=websys_getKey(e);
	if (key==13) {
		CheckCardNo();
	}
}
function CheckCardNo(){
	var CardNo=$("#CardNo").val();
	if (CardNo=="") return false;
	//var myrtn=DHCACC_GetAccInfo("",CardNo,"","",CardNoKeyDownCallBack);
	CardCommon_ControlObj.GetAccInfo({
		CardNo:CardNo,
		CallBackFun:CardNoKeyDownCallBack
	})
}
function CardNoKeyDownCallBack(myrtn){
	var myary=myrtn.split("^");
   var rtn=myary[0];
	switch (rtn){
		case "0": //卡有效有帐户
			var PatientID=myary[4];
			var PatientNo=myary[5];
			var CardNo=myary[1]
			$("#CardNo").focus().val(CardNo);
			SetPatientInfo(PatientNo,CardNo,PatientID);
			RegReturnListTabDataGridLoad();	
			event.keyCode=13;			
			break;
		case "-200": //卡无效
			$.messager.alert("提示","卡无效","info",function(){$("#CardNo").focus();});
			break;
		case "-201": //卡有效无帐户
			var PatientID=myary[4];
			var PatientNo=myary[5];
			var CardNo=myary[1];
			$("#CardNo").focus().val(CardNo);
			SetPatientInfo(PatientNo,CardNo,PatientID);
			RegReturnListTabDataGridLoad();	
			event.keyCode=13;
			break;
		default:
	}
}
function SetPatientInfo(PatientNo,CardNo,PatientID){
	if (PatientNo!='') {
		$("#RegNo").val(PatientNo);
		$("#CardNo").val(CardNo);
		$("#PatientID").val(PatientID);
	}
}
function GetCardNoLength(){
	var CardNoLength="";
	var CardTypeValue=$("#CardType").combobox("getValue");
	if (CardTypeValue!=""){
		var CardTypeArr=CardTypeValue.split("^");
		CardNoLength=CardTypeArr[17];
	}
	return CardNoLength;
}

function FormatCardNo(){
	var CardNo=$("#CardNo").val();
	if (CardNo!='') {
		var CardNoLength=GetCardNoLength();
		if ((CardNo.length<CardNoLength)&&(CardNoLength!=0)) {
			for (var i=(CardNoLength-CardNo.length-1); i>=0; i--) {
				CardNo="0"+CardNo;
			}
		}
	}
	return CardNo
}
function GetCardTypeRowId(){
	var CardTypeRowId="";
	var CardTypeValue=$("#CardType").combobox("getValue");
	if (CardTypeValue!=""){
		var CardTypeArr=CardTypeValue.split("^")
		CardTypeRowId=CardTypeArr[0];
	}
	return CardTypeRowId
}
function GetReceiptNo(){
	var insType = "";
	var p1=session['LOGON.USERID']+"^"+"^"+session['LOGON.GROUPID']+"^"+"R" + "^" + insType + "^" + session['LOGON.HOSPID'];
	if (cspRunServerMethod(ServerObj.GetreceipNO,'SetReceipNO','',p1)!='0') {
		$.messager.alert("提示","没有分配发票号,不能结算!");
		return false;
	}
}
function SetReceipNO(value) {
	var myary=value.split("^");
	var ls_ReceipNo=myary[0];
	var title = myary[4];
	var tipFlag = myary[5];
	var receiptNo = title + ls_ReceipNo;
	$('#ReceiptNo').val(receiptNo);
	//如果张数小于最小提示额change the Txt Color
	if (tipFlag == "1"){	
		$("#ReceiptNo").addClass("newclsInvalid"); 
	}
}
function LoadReturnReason(){
	var ReturnStr=$.cm({
	    ClassName : "web.DHCOPReturnReason",
	    MethodName : "FindReason",
	    dataType:"text"
	},false);
	var ArrData=new Array();
	var ReturnStrArry=ReturnStr.split("^");
	var LenR=ReturnStrArry.length
	for (var j=0;j<LenR;j++){
		var Desc=ReturnStrArry[j].split("!")[0];
		var RowID=ReturnStrArry[j].split("!")[1];
		ArrData.push({"id":RowID,"text":Desc});
        if (Desc=="其他") PageLogicObj.m_ReturnReason=RowID;
	}
	var cbox = $HUI.combobox("#ReturnReason", {
			valueField: 'id',
			textField: 'text', 
			editable:true,
			data: ArrData,
			onChange:function(newValue,oldValue){
				if (newValue==""){
					$(this).combobox("select","");
				}
			}
	 });
}
function SetReturnSum(row){
	var TotalFee=row['TabPrice'];
	var AppFee=row['TabAppFee']; 
	var ReturnFee=(+TotalFee)-(+AppFee);
	var InvoiceId=row['InvoiceId']; 
	var TabINVPayMode=row['INVPayMode'];  
	var CashPayMode=ServerObj.CashPayMode;
	var CashAmt=0,MRFee=0;
	if (InvoiceId!=""){
		for (var m=0;m<TabINVPayMode.split(",").length;m++){
			var OnePayModeStr=TabINVPayMode.split(",")[m];
			var OnePayMode=OnePayModeStr.split(":")[0];
			var OnePayModeAmt=OnePayModeStr.split(":")[1];
			if (OnePayMode==CashPayMode){
				var CashAmt=OnePayModeAmt;
				break;
			}
	    }
		CashAmt=parseFloat(CashAmt)-parseFloat(AppFee); //退号时不退预约费
	}else{
		CashAmt=TotalFee-AppFee;
	}
	if (InvoiceId!=""){
		var FeeTypeStr="MR";
		var MRFee=$.cm({
		    ClassName : "web.DHCOPAdmReg",
		    MethodName : "GetRegINVAppFee",
		    dataType:"text",
		    InvoiceRowId:InvoiceId,
		    RegFeeType:FeeTypeStr,
		    ExcludeFlag:0
		},false);
	}else{
		//var MRFee=row['MRFee']; 
	}
	var o=$HUI.checkbox("#ReturnMR");
	if (o.getValue()){
		$("#ReturnCash").val((+CashAmt).toFixed(2));
		$("#Mon").val((+ReturnFee).toFixed(2))
	}else{
		if ((+CashAmt)==0) var sum=+CashAmt 
		else  var sum=(+CashAmt)-(+MRFee);
		sum=sum.toFixed(2);
		$("#ReturnCash").val(sum);
		$("#Mon").val(((+ReturnFee)-(+MRFee)).toFixed(2))
	}
}
function UpdateclickHandler(type){
	var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
	if ((!row)||(row.length==0)){
		$.messager.alert("提示","请选择需要退号的记录!");
		return false;
	}
	DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAdmRegPrint");
	var RegRowId=row["RegfeeRowId"];
	var xPaadm=row['AdmId'];
	/*var CheckForPrint=$.cm({    ///退号如果没有打印发票，则需要先打印发票
	    ClassName : "web.DHCOPAdmReg",
	    MethodName : "CheckforCanclePrint",
	    dataType:"text",
	    adm:xPaadm
	},false);
	if (CheckForPrint!=""){
		$.messager.alert("提示",CheckForPrint);
		return false;
	}*/
	var groupid=session['LOGON.GROUPID'];
	var rtn=$.cm({
	    ClassName : "web.DHCOPAdmReg",
	    MethodName : "CheckCancelOPRegist",
	    dataType:"text",
	    adm:xPaadm,
	    GroupRowId:groupid
	},false);
	var rtnArray=rtn.split("^");
	if (rtnArray[0]==1){
		$.messager.alert("提示",rtnArray[1]);
		return false;
	}
	var CostSum=$("#Mon").val() //$("#ReturnCash").val();
	var PayModeStr=row['INVPayMode'];
	var PayModeName=$("#PayMode").combobox("getText");
	if ((PayModeName!="现金")&&(PayModeStr.indexOf(PayModeName)<0)){
		$.messager.alert("提示","不能退回除现金和原支付方式以外的其他支付方式");
		return false;
		}
	if (PayModeName=="") PayModeName="原支付方式"
	$.messager.confirm('确认对话框', '是否确定要退号?'+"<div>退回"+PayModeName+":<div style='color:#f16e57'>"+CostSum+"元</div></div>"+"<div>原支付方式:<div style='color:#2ab66a'>"+PayModeStr+"</div></div>", function(r){
		if (r){
			var ReturnMR="N"
			var o=$HUI.checkbox("#ReturnMR");
			if (o.getValue()){
				ReturnMR="Y";
			}
			if(ReturnMR=="Y"){
				$.messager.confirm('确认对话框', '是否退病历本费?', function(r){
					if (r){
						CancelOPRegist();
					}else{
						o.setValue(false);
						setTimeout(function(){
							ReturnMR="N";
							CancelOPRegist();
						});
					}
				});
			}else{
				var MRFee=row['MRFee'];
				if(+MRFee!=0){
					$.messager.confirm('确认对话框', '是否退病历本费?', function(r){
						if (r){
							o.setValue(true);
							setTimeout(function(){
								ReturnMR="Y";
								CancelOPRegist();
							});
						}else{
							o.setValue(false);
							setTimeout(function(){
								ReturnMR="N";
								CancelOPRegist();
							});
						}
					});
				}else{
					CancelOPRegist();
				}
			}
		}
	});
	function CancelOPRegist(){
		var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
		var RegRowId=row["RegfeeRowId"];
		RegRowId=RegRowId.replace(/(^\s*)|(\s*$)/g,'');
		var AdmId=row["AdmId"];
		var RBASRowId=row["TabRBASRowId"];
		var InsuAdmInfoDr=row['InsuAdmInfoDr'];
		var AdmReasonId=row['AdmReasonId'];
		var TabPayMode=row['TabPayMode'];
		var pno=$('#RegNo').val();
		var amount=$('#mon').val();
		var PatientNo=$('#RegNo').val();		
		var PatientID=$('#PatientID').val();
		var TabPrice=row['TabPrice'];
		var InvoiceId=row['InvoiceId'];
		var userid=session['LOGON.USERID'];	
		var groupid=session['LOGON.GROUPID'];	
		var ctlocid=session['LOGON.CTLOCID'];
		var ReturnMR="N"
		var o=$HUI.checkbox("#ReturnMR");
		if (o.getValue()){
			ReturnMR="Y";
		}
		//退号如果有打印发票提示收回发票
		var InvCheckrtn=$.cm({
				ClassName : "web.DHCOPAdmReg",
				MethodName : "CheckforCancleINvPrt",
				dataType:"text",
				EpisodeID:AdmId
		},false);
		//退号原因
		var ReturnReason=$("#ReturnReason").combobox("getText").replace(/^\s*|\s*$/g,"");
		var ReturnReasonDr=$("#ReturnReason").combobox("getValue");
		if ((ReturnReasonDr=="")&&(ReturnReason!="")){
			ReturnReasonDr=PageLogicObj.m_ReturnReason+"^"+ReturnReason;
		}else{
			ReturnReasonDr=CheckComboxSelData("ReturnReason",ReturnReasonDr)+"^";
		}
		
		var AlertMsg = "";
		try{
			new Promise(function(resolve,rejected){
				//医保结算退号,如果失败需要加入异常订单
				if (InsuAdmInfoDr!="") {
					var InsuRetValue=InsuOPRegStrike(0,userid,InsuAdmInfoDr,"",AdmReasonId,"");
					if(InsuRetValue!=0) {
						$.messager.alert("提示","医保退号失败,请重新退号!");
						//TODO 增加异常订单数据,退号不增加，因为退号已经为医保退在前，如果HIS不成功继续退号即可(医保退号方法可多次调用，医保已经做判断)
						// 医保退号失败，回退HIS挂号失败，存储异常订单
						//信息串：病人ID^就诊ID^医保指针^操作人^订单状态^排班ID^是否挂号							    
						var OPRegINABInfo=PatientID+"^"+xPaadm+"^"+InsuAdmInfoDr+"^"+userid+"^"+"N"+"^"+RegRowId+"^"+"N"+"^"+AdmReasonId;	
						var ret=tkMakeServerCall("web.DHCOPAdmReg","SaveDHCOPAdmINAB",OPRegINABInfo);
						return false;
					}
				}
				resolve();
			}).then(function(){
				return new Promise(function(resolve,rejected){
					var PayMode=$("#PayMode").combobox("getValue");
					var rtn=$.cm({
						ClassName : "web.DHCOPAdmReg",
						MethodName : "CancelOPRegistBroker",
						dataType:"text",
						itmjs:"",itmjsex:"",
						RegFeeRowId:RegRowId,
						UserRowId:userid, GroupRowId:groupid, LogonLocRowId:ctlocid,
						ReturnMR:ReturnMR,
						ReturnReasonDr:ReturnReasonDr,PayMode:PayMode
					},false)
					var retarr=rtn.split("$");	
					if (retarr[0]!="0"){
						SetPid(retarr[0]);
						return false;
					}else{
						var RetInfo=""
						if(TabPayMode=="CASH") RetInfo="请退还患者现金"+TabPrice+"元";
						if(TabPayMode=="CPP") RetInfo="所退金额已经退回到患者的卡账户中,无需退还现金";
						if (retarr[1]!="") {
							var PrintArr=retarr[1].split("^");
							var RegfeeRowID=PrintArr[42];
							var APIFlag=retarr[2];
							if (APIFlag=="Y"){
								PrintInvCPP(RegfeeRowID);
							}else{
								PrintInv(RegfeeRowID);
							}
						}
						
						AlertMsg="退号成功！"+RetInfo;
						resolve();
					}
				})
			}).then(function(){
				return new Promise(function(resolve,rejected){
					//lxz 调用第三方支付接口进行退费
					RegPayObj.RefundPay(RegRowId).then(rtn => {
						if (!rtn){
							AlertMsg=AlertMsg+",但Mispose退费失败！"	//需计费做一个针对这种异常账单的处理界面
						}
						
						//对外接口调用(电子发票)
						if (typeof Common_ControlObj == "object") {
							var argObj={
								RegfeeRowId:RegRowId,
								InvoiceId:InvoiceId,
								EpisodeID:AdmId
							}
							Common_ControlObj.AfterUpdate("Interface",argObj);
						}
						
						//var prtId = InvoiceId; //tkMakeServerCall("web.DHCDocMain","GetInvPrtId",RegfeeRowID);
						//chenhongliang
						var INVIdStr=tkMakeServerCall("web.DHCOPAdmRegPay","GetMisposINVIdStr",RegRowId);
						var ReceipRowid=INVIdStr.split('^')[0];
						var StrikeRowID=INVIdStr.split('^')[1];
						var sessionStr = session['LOGON.USERID']+"^"+session['LOGON.GROUPID']+"^"+session['LOGON.CTLOCID']+"^"+session['LOGON.HOSPID']+"^"+AdmReasonId;
						var einv = EInvalidService("OP",StrikeRowID,ReceipRowid,"",sessionStr);
						$.messager.alert("提示",AlertMsg,"info",function(){
							if (AdmId==ServerObj.EpisodeID){
								ServerObj.EpisodeID="";
							}
							if (ServerObj.PageFrom=="Reg"){
								//若是通过挂号界面进入的退号操作,需要刷新挂号界面当日已挂号记录
								window.parent.GetCurDateRegList();
							}
							if (InvCheckrtn==2){$.messager.alert("提示","患者已经打印发票,退号请收回。","info" , function (){
									if(type=="SwicthReg"){
										SwichReg();
										return false;
									}
								});
							}else if (InvCheckrtn==3){$.messager.alert("提示","患者已经集中打印发票,退号请收回。","info",function(){
								if(type=="SwicthReg"){
										SwichReg();
										return false;
									}
								});
							}else{
								if(type=="SwicthReg"){
										SwichReg();
										return false;
									}
								}
							//换号时需要先退号,再挂号
							GetReceiptNo();
							RegReturnListTabDataGridLoad();
						});
					})
				})
			})
		}catch(e){
			$.messager.alert("提示",e.message+","+e.name);
			return false;
		}
		return true;
	}

	function CancelOPRegistNew(){
		var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
		var RegRowId=row["RegfeeRowId"];
		RegRowId=RegRowId.replace(/(^\s*)|(\s*$)/g,'');
		var AdmId=row["AdmId"];
		var RBASRowId=row["TabRBASRowId"];
		var InsuAdmInfoDr=row['InsuAdmInfoDr'];
		var AdmReasonId=row['AdmReasonId'];
		var TabPayMode=row['TabPayMode'];
		var pno=$('#RegNo').val();
		var amount=$('#mon').val();
		var PatientNo=$('#RegNo').val();		
		var PatientID=$('#PatientID').val();
		var TabPrice=row['TabPrice'];
		var InvoiceId=row['InvoiceId'];
		var userid=session['LOGON.USERID'];	
		var groupid=session['LOGON.GROUPID'];	
		var ctlocid=session['LOGON.CTLOCID'];
		var ReturnMR="N"
		var o=$HUI.checkbox("#ReturnMR");
		if (o.getValue()){
			ReturnMR="Y";
		}
		//退号如果有打印发票提示收回发票
		var InvCheckrtn=$.cm({
			    ClassName : "web.DHCOPAdmReg",
			    MethodName : "CheckforCancleINvPrt",
			    dataType:"text",
			    EpisodeID:AdmId
		},false);
		//退号原因
		var ReturnReason=$("#ReturnReason").combobox("getText").replace(/^\s*|\s*$/g,"");
        var ReturnReasonDr=$("#ReturnReason").combobox("getValue");
        if ((ReturnReasonDr=="")&&(ReturnReason!="")){
            ReturnReasonDr=PageLogicObj.m_ReturnReason+"^"+ReturnReason;
        }else{
            ReturnReasonDr=CheckComboxSelData("ReturnReason",ReturnReasonDr)+"^";
        }
		//医保结算退号,如果失败需要加入异常订单
		if (InsuAdmInfoDr!="") {
			var InsuRetValue=InsuOPRegStrike(0,userid,InsuAdmInfoDr,"",AdmReasonId,"");
			if(InsuRetValue!=0) {
				$.messager.alert("提示","医保退号失败,请重新退号!");
				//TODO 增加异常订单数据,退号不增加，因为退号已经为医保退在前，如果HIS不成功继续退号即可(医保退号方法可多次调用，医保已经做判断)
				// 医保退号失败，回退HIS挂号失败，存储异常订单
				//信息串：病人ID^就诊ID^医保指针^操作人^订单状态^排班ID^是否挂号							    
				var OPRegINABInfo=PatientID+"^"+xPaadm+"^"+InsuAdmInfoDr+"^"+userid+"^"+"N"+"^"+RegRowId+"^"+"N"+"^"+AdmReasonId;	
				var ret=tkMakeServerCall("web.DHCOPAdmReg","SaveDHCOPAdmINAB",OPRegINABInfo);
				return false;
			}
		}
		var PayMode=$("#PayMode").combobox("getValue");
		var rtn=$.cm({
		    ClassName : "web.DHCOPAdmReg",
		    MethodName : "CancelOPRegistBroker",
		    dataType:"text",
		    itmjs:"",itmjsex:"",
		    RegFeeRowId:RegRowId,
		    UserRowId:userid, GroupRowId:groupid, LogonLocRowId:ctlocid,
		    ReturnMR:ReturnMR,
		    ReturnReasonDr:ReturnReasonDr,PayMode:PayMode
		},function(ret){
			var retarr=ret.split("$");	
			if (retarr[0]!="0"){
				SetPid(retarr[0]);
			}else{
				
				var RetInfo=""
				if(TabPayMode=="CASH") RetInfo="请退还患者现金"+TabPrice+"元";
				if(TabPayMode=="CPP") RetInfo="所退金额已经退回到患者的卡账户中,无需退还现金";
				if (retarr[1]!="") {
					var PrintArr=retarr[1].split("^");
					var RegfeeRowID=PrintArr[42];
					var APIFlag=retarr[2];
					if (APIFlag=="Y"){
						PrintInvCPP(RegfeeRowID);
					}else{
						PrintInv(RegfeeRowID);
					}
				}
				//对外接口调用(电子发票)
				if (typeof Common_ControlObj == "object") {
					var argObj={
						RegfeeRowId:RegRowId,
						InvoiceId:InvoiceId,
						EpisodeID:AdmId
					}
					Common_ControlObj.AfterUpdate("Interface",argObj);
				}
				
				var AlertMsg="退号成功！"+RetInfo
				//lxz 调用第三方支付接口进行退费
				var rtn=RegPayObj.RefundPay(RegRowId)
				if (!rtn){
					AlertMsg=AlertMsg+",但Mispose退费失败！"	//需计费做一个针对这种异常账单的处理界面
				}
				
				//var prtId = tkMakeServerCall("web.DHCDocMain","GetInvPrtId",RegfeeRowID);
				//chenhongliang
				//var sessionStr = session['LOGON.USERID']+"^"+session['LOGON.GROUPID']+"^"+session['LOGON.CTLOCID']+"^"+session['LOGON.HOSPID']+"^"+AdmReason;
				//var einv = EInvoieService("REG",prtId,"Invoice",sessionStr);
				$.messager.alert("提示",AlertMsg,"info",function(){
					if (AdmId==ServerObj.EpisodeID){
						ServerObj.EpisodeID="";
					}
					if (ServerObj.PageFrom=="Reg"){
						//若是通过挂号界面进入的退号操作,需要刷新挂号界面当日已挂号记录
						window.parent.GetCurDateRegList();
					}
					if (InvCheckrtn==2){$.messager.alert("提示","患者已经打印发票,退号请收回。","info" , function (){
							if(type=="SwicthReg"){
								SwichReg();
								return false;
							}
						});
					}else if (InvCheckrtn==3){$.messager.alert("提示","患者已经集中打印发票,退号请收回。","info",function(){
						if(type=="SwicthReg"){
								SwichReg();
								return false;
							}
						});
					}else{
						if(type=="SwicthReg"){
								SwichReg();
								return false;
							}
						}
					//换号时需要先退号,再挂号
					GetReceiptNo();
					RegReturnListTabDataGridLoad();
					return true;
				});
			}
		});
	}
}
function SetPid(value){
	if (value!="0") {
		if(value=="cancel") {
			$.messager.alert("提示",t['AdmIsCanceled']);
		}else if(value=="diagnos") {
			$.messager.alert("提示","此人已经有诊断或医嘱不能退号或换号!");
		}else if(value=="orditem") {
			$.messager.alert("提示","已经有过医嘱,不允许退换号!");
		}else if(value=="Invoice") {
			$.messager.alert("提示","已经打印过发票,不允许退换号!");
		}else if(value=="overtime") {
			$.messager.alert("提示","已经过了退号时间!");
		}else if(value=="NotSameHosp") {
			$.messager.alert("提示","不能跨院退号,请核实所退号所在医院!");
		}else if(value=="NeedReason") {
			$.messager.alert("提示","强制退号需要填写退号原因");
		}else if(value=="CESReg") {
			$.messager.alert("提示","此人为应急系统患者,且在应急系统中未收挂号费用,不允许退号!");
		}else {
			$.messager.alert("提示","退号失败:"+value);
		}
	}else{
	  	$.messager.popover({msg: '退号成功!',type:'success'});
	}
}
function CheckComboxSelData(id,selId){
	var Find=0;
	 var Data=$("#"+id).combobox('getData');
	 for(var i=0;i<Data.length;i++){
	      var CombValue=Data[i].id
	 	  var CombDesc=Data[i].text
		  if(selId==CombValue){
			  selId=CombValue;
			  Find=1;
			  break;
	      }
	  }
	  if (Find=="1") return selId
	  return "";
}
function ReprintClickHandler(){
	var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
	if ((!row)||(row.length==0)){
		$.messager.alert("提示","请选择需要进行作废重打的记录!");
		return false;
	}
	if (row['TabInvoiceNo']==""){
		$.messager.alert("提示","发票号为空的记录不能作废重打!");
		return false;
	}
	var RegRowId=row["RegfeeRowId"];
	RegRowId=RegRowId.replace(/(^\s*)|(\s*$)/g,'');
	DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAdmRegPrint");
	var userid=session['LOGON.USERID'];	
	var groupid=session['LOGON.GROUPID'];	
	var ctlocid=session['LOGON.CTLOCID'];
	var rtn=$.cm({
	    ClassName : "web.DHCOPAdmReg",
	    MethodName : "RePrintBroker",
	    dataType:"text",
	    itmjs:"",itmjsex:"",
	    RegFeeRowId:RegRowId,
	    UserRowId:userid, GroupRowId:groupid, LogonLocRowId:ctlocid
	},function(ret){
		var retarr=ret.split("$");	
		if (retarr[0]=="0"){
			//打印发票 --如果存在医保需要判断是调用医保接口打印发票还是调用HIS打印发票-医保修改按照项目上线自行修改
			var PrintArr=retarr[1].split("^");
			var RegfeeRowID=PrintArr[42];
			PrintInv(RegfeeRowID)
			$.messager.alert("提示","重打成功!","info",function(){
				GetReceiptNo();
				RegReturnListTabDataGridLoad();
			});
		}else{
			if (retarr[0]=="-200"){
				$.messager.alert("提示","只能重打自己的未结算发票");
			}else if (retarr[0]=="-300"){
				$.messager.alert("提示","发票号为空的挂号记录,不能作废重打!");
			}else if (retarr[0]=="-201"){
				$.messager.alert("提示","门诊收费确认完成失败!请在门诊收费异常处理界面重新结算!")
			}else if (retarr[0]=="-202"){
				$.messager.alert("提示","重打失败!此安全组没有权限打印发票!")
			}else{
				$.messager.alert("提示","重打失败!");
			}
		}
	});
}
//挂号发票打印
function PrintInv(RegFeeID)
{   
	var UserID=session['LOGON.USERID'];
	var Return=tkMakeServerCall("web.DHCOPAdmReg","GetPrintInvInfo","InvPrint","INVPrtFlag2007",RegFeeID, UserID, "","");
}
function PrintInvCPP(RegFeeID){
	var UserID=session['LOGON.USERID'];
	var Return=tkMakeServerCall("web.DHCOPAdmReg","GetPrintInvInfo","InvPrintNewCPP","INVPrtFlagCPP", RegFeeID, UserID, "","");
}
function InvPrintNewCPP(TxtInfo, ListInfo){
	DHCP_GetXMLConfig("InvPrintEncrypt","INVPrtFlagCPP");
	InvPrintNew(TxtInfo, ListInfo);
}
function InvPrint(TxtInfo, ListInfo){
	DHCP_GetXMLConfig("InvPrintEncrypt","INVPrtFlag2007");
	InvPrintNew(TxtInfo, ListInfo);
}
function InvPrintNew(TxtInfo, ListInfo)
{   
	//DHCP_GetXMLConfig("InvPrintEncrypt","INVPrtFlag2007");
	var myobj=document.getElementById("ClsBillPrint");
	//------和收费使用同模板，解决多打印出一张空白页的情况------
	var tmpListInfo="";
	var tmpListAry=ListInfo.split(String.fromCharCode(2));
	var ListLen=tmpListAry.length;
	for (var i = 0; i < ListLen; i++) {
		if (i>7) break;
		if (tmpListInfo=="") {
			tmpListInfo=tmpListAry[i];
		}else{
			tmpListInfo=tmpListInfo+String.fromCharCode(2)+tmpListAry[i];
		}	
	}
	ListInfo=tmpListInfo;
	//------
	//PrintFun(myobj,TxtInfo,ListInfo);	
	DHC_PrintByLodop(getLodop(),TxtInfo,ListInfo,"","");
}
function PrintFun(PObj,inpara,inlist){
	////DHCPrtComm.js
	try{
		var mystr="";
		for (var i= 0; i<PrtAryData.length;i++){
			mystr=mystr + PrtAryData[i];
		}
		inpara=DHCP_TextEncoder(inpara)
		inlist=DHCP_TextEncoder(inlist)
		var docobj=new ActiveXObject("MSXML2.DOMDocument.4.0");
		docobj.async = false;    //close
		var rtn=docobj.loadXML(mystr);
		if ((rtn)){
			////ToPrintDoc(ByVal inputdata As String, ByVal ListData As String, InDoc As MSXML2.DOMDocument40)			
			var rtn=PObj.ToPrintDocNew(inpara,inlist,docobj);
			////var rtn=PObj.ToPrintDoc(myinstr,myList,docobj);
		}
	}catch(e){
		alert(e.message);
		return;
	}
}

function OldRegPrintClickHandler(){
	var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
	if ((!row)||(row.length==0)){
		$.messager.alert("提示","请选择需要进行原号重打的记录!");
		return false;
	}
	if (row['TabInvoiceNo']==""){
		$.messager.alert("提示","发票号为空的记录不能原号重打!");
		return false;
	}
	var RegRowId=row["RegfeeRowId"];
	RegRowId=RegRowId.replace(/(^\s*)|(\s*$)/g,'');
	DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAdmRegPrint");
	var userid=session['LOGON.USERID'];	
	var groupid=session['LOGON.GROUPID'];	
	var ctlocid=session['LOGON.CTLOCID'];
	$.cm({
	    ClassName : "web.DHCOPAdmReg",
	    MethodName : "OldRegRePrintBroker",
	    dataType:"text",
	    itmjs:"",itmjsex:"",
	    RegFeeRowId:RegRowId,
	    UserRowId:userid, GroupRowId:groupid, LogonLocRowId:ctlocid
	},function(ret){
		var retarr=ret.split("$");	
		if (retarr[0]=="0"){
			//打印发票 --如果存在医保需要判断是调用医保接口打印发票还是调用HIS打印发票-医保修改按照项目上线自行修改
			var PrintArr=retarr[1].split("^");
			var RegfeeRowID=PrintArr[42];
			PrintInv(RegfeeRowID)
			$.messager.alert("提示","重打成功!","info",function(){
				GetReceiptNo();
				RegReturnListTabDataGridLoad();
			});
		}else{
			if (retarr[0]=="-200"){
				$.messager.alert("提示","只能重打自己的未结算发票!");
			}else if (retarr[0]=="-300"){
				$.messager.alert("提示","发票号为空的挂号记录,不能作废重打!");
			}else if (retarr[0]=="-202"){
				$.messager.alert("提示","重打失败!此安全组没有权限打印发票!")
			}else{
				$.messager.alert("提示","重打失败!");
			}
		}
	});
}
function ReprintRegist() {
	var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
	if ((!row)||(row.length==0)){
		$.messager.alert("提示","请选择需要进行挂号小条重打的记录!");
		return false;
	}
	DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAdmRegPrint");
	var RegRowId=row["RegfeeRowId"];
	var userid=session['LOGON.USERID'];	
	var groupid=session['LOGON.GROUPID'];	
	var ctlocid=session['LOGON.CTLOCID'];
	var ret=$.cm({
		ClassName:"DHCDoc.Common.pa",
		MethodName:"GetOPPrintData",
		dataType:"text",
		RegfeeRowId:RegRowId, AppFlag:"", RePrintFlag:"Y"
	},false);
	PrintOut(ret);
	var admid=row["AdmId"];
	var ret=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"SavePrintRecode",
		dataType:"text",
		Adm:admid, UserID:userid
	},false);
	$.messager.popover({msg: '重打成功!',type:'success'});
}
function PrintOut(PrintData) {
	try {
		var PrintDataArySum=eval(PrintData)
		var PrintDataAry=PrintDataArySum[0]
		var MyPara = "" + String.fromCharCode(2);
		var PersonPay="",RegFee="",InvoiceId="";
		for (Element in PrintDataAry){
			if (Element=="PersonPay"){PersonPay=PrintDataAry[Element]}
			if (Element=="InvoiceId"){
				InvoiceId=PrintDataAry[Element];
			}
			if (Element=="AppFee"){
				if (PrintDataAry[Element]!=0){PrintDataAry[Element]="预约费:"+PrintDataAry[Element]+"元"}else{PrintDataAry[Element]=""}
			}
			if (Element=="OtherFee"){
				if (PrintDataAry[Element]!=0) {PrintDataAry[Element]=PrintDataAry[Element]+"元"}else{PrintDataAry[Element]=""}
			}
			/*if (Element=="RegFee"){   //by zhangtong 2024-01-18 医院要求为0也要打印出来
				RegFee=PrintDataAry[Element]
				if (PrintDataAry[Element]!=0){PrintDataAry[Element]=PrintDataAry[Element]+"元"}else{PrintDataAry[Element]="0"}
			}*/
			MyPara=MyPara +"^"+ Element + String.fromCharCode(2) + PrintDataAry[Element];
		}
		var EInvInfo=$.cm({
			ClassName: "BILL.EINV.BL.COM.InvUpDetailsCtl",
			MethodName: "GetEInvInfoByHisInvDr",
			dataType: "text",
			PayAdmType: "REG", HisInvprtDr: InvoiceId, ExtStr: ""
		}, false);
		if (EInvInfo!="") {
			var EInvUrl=EInvInfo.split("^")[12];
			var IUDBillNo=EInvInfo.split("^")[0];
			if (EInvUrl!="") {
				//MyPara=MyPara +"^"+ "EInvUrl" + String.fromCharCode(2) +EInvUrl;
				MyPara=MyPara +"^"+ "IUDBillNo" + String.fromCharCode(2) +IUDBillNo;
			}
		}
		
		var EInvUrl=$.cm({
			ClassName: "BILL.EINV.BL.COM.InvUpDetailsCtl",
			MethodName: "GetZZEinvQrCode",
			dataType: "text",
			PayAdmType: "REG", HISPrtRowID: InvoiceId
		}, false);
		if (EInvUrl!=""){
			MyPara=MyPara +"^"+ "EInvUrl" + String.fromCharCode(2) +"data:image/png;base64,"+EInvUrl;
		}
		
		
		ProportionNote="本收据中,"+RegFee+"元"+"不属于医保报销范围";
		MyPara=MyPara +"^"+ "ProportionNote" + String.fromCharCode(2) +ProportionNote;
		DHC_PrintByLodop(getLodop(),MyPara,"","","");	
	} catch(e) {$.messager.alert("提示",e.message)};
	/*try {
		if (PrintData=="") return;
		var PrintArr=PrintData.split("^");
		var AdmNo=PrintArr[0];
		var PatName=PrintArr[1];
		var RegDep=PrintArr[2];
		var DocDesc=PrintArr[3];
		var SessionType=PrintArr[4];
		var MarkDesc=DocDesc
		var AdmDateStr=PrintArr[5];
		var TimeRange=PrintArr[6];
		var AdmDateStr=AdmDateStr+" "+TimeRange;
		var SeqNo=PrintArr[7];
		var RoomNo=PrintArr[8];
		var RoomFloor=PrintArr[9];
		var UserCode=PrintArr[10];
		var RegDateYear=PrintArr[12];
		var RegDateMonth=PrintArr[13];
		var RegDateDay=PrintArr[14];
		var TransactionNo=PrintArr[15];
		var Total=PrintArr[16];
		var RegFee=PrintArr[17];
		var AppFee=PrintArr[18];
		var OtherFee=PrintArr[19];
		var ClinicGroup=PrintArr[20];
		var RegTime=PrintArr[21];
		var ExabMemo=PrintArr[23];
		var InsuPayCash=PrintArr[24];
		var InsuPayCount=PrintArr[25];
		var InsuPayFund=PrintArr[26];
		var InsuPayOverallPlanning=PrintArr[27];
		var InsuPayOther=PrintArr[28];
		var TotalRMBDX=PrintArr[29];
		var INVPRTNo=PrintArr[30];
		var CardNo=PrintArr[31];
		var Room=PrintArr[32];
		var AdmReason=PrintArr[33];
		var Regitems=PrintArr[34];
		var AccBalance=PrintArr[35];
		var PatNo=PrintArr[36];
		var TimeRangeInfo=PrintArr[37];
		var HospitalDesc=PrintArr[38];
		var PersonPay=PrintArr[39];
		var YBPay=PrintArr[40];
		var DYIPMRN=PrintArr[41];
		var RowID=PrintArr[42];
		var PayModeStr1=PrintArr[46];
		var PayModeStr2=PrintArr[47];
		var MyList="";
		for (var i=0;i<Regitems.split("!").length-1;i++){
			var tempBillStr=Regitems.split("!")[i];
			if (tempBillStr=="") continue;
			var tempBillDesc=tempBillStr.split("[")[0];
			var tempBillAmount=tempBillStr.split("[")[1];
			if (MyList=="") MyList=tempBillDesc+"   "+tempBillAmount;
			else  MyList = MyList + String.fromCharCode(2)+tempBillDesc+"   "+tempBillAmount;
		}

		//病人自负比例的备注
		var ProportionNote="";
		var ProportionNote1="";
		var ProportionNote2="";
		InsuPayCash="";
		InsuPayCount="";
		InsuPayOverallPlanning="";
		InsuPayOther="";
		ProportionNote="本收据中,"+RegFee+"元"+"不属于医保报销范围";
		ProportionNote1="";
		ProportionNote2="";
		var NeedCardFee=false;
		var CardFee=0;
 		if (NeedCardFee==true){
 			var CardFee="工本费 "+parseFloat(CardFee)+"元";
 		}else{
 			var CardFee="";
 		}
		RegTime=RegDateYear+"-"+RegDateMonth+"-"+RegDateDay+" "+RegTime
		if (AccBalance=="") AccBalance=0;
		//重打不显示消费金额。
		//消费后金额
		AccTotal="" //SaveNumbleFaxed(AccBalance);
		//消费前金额
    	AccAmount="" //SaveNumbleFaxed(parseFloat(AccBalance)+parseFloat(Total));
		var cardnoprint=$('#CardNo').val();
		if (cardnoprint=="") {
			cardnoprint=CardNo
		}
		var TimeD=TimeRange;
		if (AppFee!=0){AppFee="预约费:"+AppFee}else{AppFee=""}
		if (OtherFee!=0) {OtherFee="治疗费:"+OtherFee}else{OtherFee=""}
		var PDlime=String.fromCharCode(2);
		var MyPara="AdmNo"+PDlime+AdmNo+"^"+"PatName"+PDlime+PatName+"^"+"TransactionNo"+PDlime+TransactionNo+"^"+"AccTotal"+PDlime+AccTotal+"^"+"AccAmount"+PDlime+AccAmount;
		var MyPara=MyPara+"^"+"MarkDesc"+PDlime+MarkDesc+"^"+"AdmDate"+PDlime+AdmDateStr+"^"+"SeqNo"+PDlime+SeqNo+"^RegDep"+PDlime+RegDep;
		var MyPara=MyPara+"^"+"RoomFloor"+PDlime+RoomFloor+"^"+"UserCode"+PDlime+UserCode;
		var MyPara=MyPara+"^"+"RegDateYear"+PDlime+RegDateYear+"^RegDateMonth"+PDlime+RegDateMonth+"^RegDateDay"+PDlime+RegDateDay;
		var MyPara=MyPara+"^"+"Total"+PDlime+Total+"^RegFee"+PDlime+RegFee+"^AppFee"+PDlime+AppFee+"^OtherFee"+PDlime+OtherFee;
		var MyPara=MyPara+"^"+"RoomNo"+PDlime+RoomNo+"^"+"ClinicGroup"+PDlime+ClinicGroup+"^"+"SessionType"+PDlime+SessionType+"^"+"TimeD"+PDlime+TimeD+"^"+"RegTime"+PDlime+RegTime+"^"+"cardnoprint"+PDlime+cardnoprint;
		var MyPara=MyPara+"^"+"INVPRTNo"+PDlime+INVPRTNo;
		var MyPara=MyPara+"^"+"TimeRangeInfo"+PDlime+TimeRangeInfo;
		var MyPara=MyPara+"^"+"YBPay"+PDlime+YBPay;
		var MyPara=MyPara+"^"+"PersonPay"+PDlime+PersonPay;
		var MyPara=MyPara+"^"+"RowID"+PDlime+RowID;
		var MyPara=MyPara+"^"+"DYIPMRN"+PDlime+Trim(DYIPMRN);
		var MyPara=MyPara+"^"+"ExabMemo"+PDlime+ExabMemo;
		var MyPara=MyPara+"^"+"PatNo"+PDlime+PatNo;       //打印登记号
		var MyPara=MyPara+"^"+"HospName"+PDlime+HospitalDesc+"^"+"paymoderstr1"+PDlime+PayModeStr1+"^"+"paymoderstr2"+PDlime+PayModeStr2;
		var myobj=document.getElementById("ClsBillPrint");
		//PrintFun(myobj,MyPara,"");
		DHC_PrintByLodop(getLodop(),MyPara,"","","");	
	} catch(e) {$.messager.alert("提示",e.message)};*/
}
function Trim(str){
	return str.replace(/[\t\n\r ]/g, "");
}
function SwichRegclickHandle(){
	UpdateclickHandler("SwicthReg");
}
function SwichReg(){
	var userid=session['LOGON.USERID'];	
	var groupid=session['LOGON.GROUPID'];	
	var ctlocid=session['LOGON.CTLOCID'];
	var kname=session['LOGON.USERNAME'];
	var Pid=$('#PatientID').val();
	var m_CardNo=$('#CardNo').val();
    var amount=$('#Mon').val();
    var rtn=$.cm({
	    ClassName : "web.DHCOPRegTime",
	    MethodName : "GetPInfo",
	    dataType:"text",
	    PatId:Pid,
	},false);
    var Str=rtn.split("^");
	var PatName=Str[0];
	var PatSex=Str[1];
	var PatAge=Str[2];
	var Parobj=window.parent;
	if (window.parent){  //(window.name=="CacelReg"){   
		var CardNo=$("#CardNo").val();
		var CardTypeNew=$("#CardTypeNew").val();
		var RegNo=$("#RegNo").val();
		$("#PatientNo" , parent.document).val(RegNo);
		Parobj.destroyDialog("Project");
		if (CardNo!=""){
			Parobj.SetPassCardNo(CardNo,CardTypeNew);
		}else if(RegNo!=""){
			Parobj.CheckPatientNo();
		}
	}
}
function CancelMedicalBookclickHandle(){
	var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
	if ((!row)||(row.length==0)){
		$.messager.alert("提示","请选择需要退病历本费的记录!");
		return false;
	}
	var GroupID=session['LOGON.GROUPID'];
	var UserID=session['LOGON.USERID'];
	var LocID=session['LOGON.CTLOCID'];
	var NewInvoiceId="";
	var RegRowId=row["RegfeeRowId"];
	RegRowId=RegRowId.replace(/(^\s*)|(\s*$)/g,'');
	$.cm({
	    ClassName : "web.DHCOPAdmReg",  
	    MethodName : "CancelMedicalBookBroker",
	    dataType:"text",
	    RegFeeRowId:RegRowId, UserRowId:UserID, GroupRowId:GroupID, LogonLocRowId:LocID,
	    dataType:"text"
	},function(ret){
		if (ret.split('^')[0]!="0") {
			$.messager.alert("提示","退病历本费失败:"+ret.split('^')[1]);
			return false;
		}else{
			NewInvoiceId=ret.split('^')[1];
		}
		if (NewInvoiceId!=""){
			var APIFlag=ret.split('^')[2];
			if (APIFlag=="Y"){
				PrintInvCPP(RegRowId);
			}else{
				PrintInv(RegRowId);
			}
			//BillPrintNew('0^'+NewInvoiceId);
			$.messager.alert("提示","退病历本费成功!","info",function(){
				GetReceiptNo();
				RegReturnListTabDataGridLoad();
			})
		}else{
			$.messager.alert("提示","退病历本费成功!","info",function(){
				GetReceiptNo();
				RegReturnListTabDataGridLoad();
			})
		}
	});
}
function BillPrintNew(INVstr){
	var myrtn=$.cm({
	    ClassName : "web.UDHCOPGSConfig",  
	    MethodName : "ReadCFByGRowID",
	    dataType:"text",
	    GPRowID:session['LOGON.GROUPID']
	},false);
    var myary=myrtn.split("^");
	if (myary[0]==0){
		var BillPrtXMLName=myary[10];
	}else{
		return false;
	}
	DHCP_GetXMLConfig("InvPrintEncrypt",BillPrtXMLName);
	var INVtmp=INVstr.split("^");
	for (var invi=1;invi<INVtmp.length;invi++)
	{
		if (INVtmp[invi]!=""){
			var PayMode="";
			var Guser=session['LOGON.USERID'];
			var sUserCode=session['LOGON.USERCODE'];
			var myExpStr="";
			var myPreDep="";
			var myCharge="";
			var myCurGroupDR=session['LOGON.GROUPID'];
			var myExpStr=myPreDep+"^"+myCharge+"^"+myCurGroupDR;
			//s val=##Class(%CSP.Page).Encrypt($lb("web.UDHCOPINVPrtIF.GetOPPrtData"))
			var Return=tkMakeServerCall("web.UDHCOPINVPrtIF","GetOPPrtData","InvPrintNew",BillPrtXMLName,INVtmp[invi], sUserCode, PayMode, myExpStr);
		}
	}
}

function UpdatePatAdmReasonClickHandle(){
	var row=PageLogicObj.m_RegReturnListTabDataGrid.datagrid("getSelected");
	if (!row){
		$.messager.alert("提示","请选择挂号记录!");
		return false;
	}
	var admid=row["AdmId"];
	var src="opadm.chgadmreason.hui.csp?EpisodeID="+admid;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("ChgAdmReason","修改患者类型及就诊费别", "700", PageLogicObj.dh,"icon-w-edit","",$code,"");
}
function createModalDialog(id, _title, _width, _height, _icon,_btntext,_content,_event){
    $("body").append("<div id='"+id+"' class='hisui-dialog'></div>");
    if (_width == null)
        _width = 800;
    if (_height == null)
        _height = 500;
    $("#"+id).dialog({
        title: _title,
        width: _width,
        height: _height,
        cache: false,
        iconCls: _icon,
        //href: _url,
        collapsible: false,
        minimizable:false,
        maximizable: false,
        resizable: false,
        modal: true,
        closed: false,
        closable: true,
        content:_content,
        onClose:function(){
	        destroyDialog(id);
	    }
    });
}
function destroyDialog(id){
   //移除存在的Dialog
   $("body").remove("#"+id); 
   $("#"+id).dialog('destroy');
}
function RegDateonSelect(){
	$("#nday").val("");
}
function ndayChange(){
	var NDay=$("#nday").val();
	if (NDay!=""){
		//$("#RegDate").text("");
		$HUI.datebox("#RegDate").setValue("");
	}
}
function AccpinvClick() {
	websys_showModal({
		url:"dhcbill.opbill.accpinv.csp",
		title:'集中打印',
		width:'95%',height:'95%'
	})
}
function LoadPayMode(){
	$.cm({ 
		ClassName:"web.UDHCOPGSConfig", 
		QueryName:"ReadGSINSPMList",
		GPRowID:session['LOGON.GROUPID'],
		HospID:session['LOGON.HOSPID'],
		TypeFlag:"REG",
		rows:9999
	},function(Data){
		var cbox = $HUI.combobox("#PayMode", {
				valueField: 'CTPMRowID',
				textField: 'CTPMDesc', 
				editable:true,
				data: Data.rows
		 });
		 $("#PayMode").combobox("setValue","");
	});
}
