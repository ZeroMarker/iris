var PageLogicObj={
	m_selectedMarkListDataGrid:"",
	m_curDayRegListDataGrid:"",
	m_curDayAppListDataGrid:"",
	m_MarkListDataGrid:"",
	m_PreCardNo:"",
	m_PreCardType:"",
	m_PreCardLeaving:"",
	m_deptRowId:"",
	m_DocRowId:"",
	CommonCardrow:"",
	m_IDCredTypePlate:"01", //身份证代码字段
	dw:$(window).width()-200,
	dh:$(window).height()-80,
	m_TrShowFlag: 1,			// 1 显示所有时段；0 显示可用时段
	m_ApptTypeCode:"WIN", 		// 预约渠道
	m_MouseoverId: "",			// 当前 show popover 的 mouseover id
	m_MarkPopoverTrigger:"click",			//分时段浮动窗口展示模式,click:点击弹出，hover:鼠标移入时弹出（使用效果不太好）
	m_PopoverId: "",				// 当前 show popover 的 id
	m_RegJumpFlag:""			//挂号跳转标志
};
if (websys_isIE==true) {
	 var script = document.createElement('script');
	 script.type = 'text/javaScript';
	 script.src = '../scripts/dhcdoc/tools/bluebird.min.js';  // bluebird 文件地址
	 document.getElementsByTagName('head')[0].appendChild(script);
}
$(function(){
	//页面元素初始化
	PageHandle();
	//页面数据初始化
	//Init();
	//事件初始化
	InitEvent();
});
function Init(){
	PageLogicObj.m_selectedMarkListDataGrid=InitselectedMarkListDataGrid();
	if (ServerObj.ParaRegType=="APP"){
		//已预约记录
		PageLogicObj.m_curDayAppListDataGrid=curDayAppListDataGrid();
	}else{
		//当日已挂号记录
		PageLogicObj.m_curDayRegListDataGrid=curDayRegListDataGrid();
	}
}
function PageHandle(){
	//按钮栏初始化
	InitBtnBar();
	//时段列表
	LoadTimeRange();
	//科室
	LoadDeptList();
	//医生
	LoadMarkCode();
	//支付方式
	LoadPayMode();
	//优惠类型
	LoadRegConDisList();
	//发票流水号
	GetReceiptNo();
	InitReceiptCount();
	//服务组
	LoadClinicServiceGroup("");
	//预约类型
	InitAppPatType();
	//证件类型
	LoadCredType()
	setTimeout(function() { 
    	if (ServerObj.ParaRegType=="APP"){
			$("#SelDate").html(ServerObj.DefaultAppDate);
			$("#WeekDesc").html($g(ServerObj.DefaultAppWeek));
			$("#AppDate").datebox('setValue',ServerObj.DefaultAppDate);
			if (ServerObj.ChangePatientNo!=""){
				$("#PatientNo").val(ServerObj.ChangePatientNo);
				CheckPatientNo();
			}
			if (ServerObj.ChangeOtherInfo!=""){
				var OtherInfoAry=ServerObj.ChangeOtherInfo.split("^")
				$('#AppPatCredNo').val(OtherInfoAry[1]);
				$('#AppPatName').val(OtherInfoAry[0]);
				$('#AppPatTel').val(OtherInfoAry[2]);
				$('#AppPatAddress').val(OtherInfoAry[3]);
				if (OtherInfoAry[4]!="") $('#AppPatType').combobox('setValue',OtherInfoAry[4]);
				if (OtherInfoAry[5]!="") $('#AppPatCredType').combobox('setValue',OtherInfoAry[5].replace("$","^"));
			}
		}else{
			$("#SelDate").html(ServerObj.CurDate);
			$("#WeekDesc").html($g(ServerObj.CurWeek));
		}
    },600);
	setTimeout(function() { 
		var frm = dhcsys_getmenuform();
		if (frm) {	
	    	var PatientID = frm.PatientID.value;
			frm.PatientID.value="";
	    	if ((typeof PatientID != "undefined") && (PatientID != "")) {
		    	PageLogicObj.m_RegJumpFlag="Y"
				var RegNo=$.cm({
					ClassName:"web.DHCOPAdmReg",
					MethodName:"GetPatNoByID",
					dataType:"text",
					PAPMIDR:PatientID
				},false);
		    	$("#PatientNo").val(RegNo);
				CheckPatientNo();
	    	}else {
		    	PageLogicObj.m_RegJumpFlag=""	
	    	}
	    }
    },600);
	$('#CardNo').focus();
	var $btntext=$("#MarkListShowMode .l-btn-text")[0];
	if (ServerObj.OPRegListDefault==1){
		$btntext.innerText=$g("视图模式");
		var url="opadm.reg.marktable.hui.csp";
	}else{
		$btntext.innerText=$g("列表模式");
		var url="opadm.reg.markcard.hui.csp";
		$("#MarkListPanel").removeClass('panel-noscroll');
	}
    url=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(url):url;
	$.ajax(url, {
		"type" : "GET",
		"async" : false,
		"dataType" : "html",
		"success" : function(data, textStatus) {
			$("#MarkListPanel").empty().append(data);
		}
	});
	//读卡按钮初始化
	CardCommon_ControlObj.Init({
		id:"ReadCard",
		callBackFun:CardNoKeyDownCallBack
	});
}
function InitBtnBar()
{
	$('#btnList').marybtnbar({
        btnCls:'big',
        queryParams:{url:'opadm.reg.hui.csp'},
		loadFilter:function(data){
			for(var i=data.length-1;i>=0;i--){
				if(data[i].id=='BCacelReg' && ServerObj.ParaRegType=='APP'){
					data.splice(i,1);
				}
				if(data[i].id=='BCancelApp' && ServerObj.ParaRegType!='APP'){
					data.splice(i,1);
				}
			}
		}
    });
}
function InitEvent(){
	//患者基本信息展开/收缩
	$("#BPatInfoCollaps").click(BPatInfoCollapsHandle);
	//实收
	$("#PaySum").keydown(PaySumKeydown);
	$("#PaySum").keypress(PaySumKeyPress);
	$("#PaySum").blur(ReCalculateAmount);
	//挂号
	$("#Update").click(UpdateClickHandler);
	$("#Find").click(function(){LoadMarkList()});
	$("#CloseDeptTreeDiv").click(function(){
		$("#DeptTreeList-div").hide();
	});
	//预约
	$("#Appoint").click(AppointClickHandler);
	$("#PreAppDay").click(PreAppDayClickHandler);
	$("#NextAppDay").click(NextAppDayClickHandler);
	$("#AllAppDays").click(AllAppDaysClickHandler);
	$("#BeforeWeekAppDay").click(function(){ChangeWeekAppDayClickHandler("Before");});
	$("#ThisWeekAppDay").click(function(){ChangeWeekAppDayClickHandler("Now");});
	$("#NextWeekAppDay").click(function(){ChangeWeekAppDayClickHandler("Next");});
	$("#DeptTreeList").click(DeptTreeListClickHandle);
	$("#MarkListShowMode").click(MarkListShowModeClickHandle);
	$("#DeptList").change(DeptListChangeHanlde);
	/*$("#AppDate").prev().prev().blur(function(){
		debugger;
	})*/
	$(document.body).bind("keydown",BodykeydownHandler);
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
	//浏览器中Backspace不可用  
   var keyEvent;   
   if(e.keyCode==8){   
       var d=e.srcElement||e.target;
        if(d.tagName.toUpperCase()=='INPUT'||d.tagName.toUpperCase()=='TEXTAREA'){   
            keyEvent=d.readOnly||d.disabled;   
        }else{   
            keyEvent=true;   
        }   
    }else{   
        keyEvent=false;   
    }   
    if(keyEvent){   
        e.preventDefault();   
    }  
    if(keyCode==120) { 
		if ($("#Update").length>0){
			UpdateClickHandler();
		}
		if ($("#Appoint").length>0){
			AppointClickHandler();
		}
	}
	if (document.activeElement.parentElement.id=="MarkListPanel"){
		var FroceRow=""
		if ((keyCode==49)||(keyCode==97)) FroceRow=0
		if ((keyCode==50)||(keyCode==98)) FroceRow=1
		if ((keyCode==51)||(keyCode==99)) FroceRow=2
		if ((keyCode==52)||(keyCode==100)) FroceRow=3
		if ((keyCode==53)||(keyCode==101)) FroceRow=4
		if ((keyCode==54)||(keyCode==102)) FroceRow=5
		if ((keyCode==55)||(keyCode==103)) FroceRow=6
		if ((keyCode==56)||(keyCode==104)) FroceRow=7
		if ((keyCode==57)||(keyCode==105)) FroceRow=8
		if (FroceRow!==""){
			var $btntext=$("#MarkListShowMode .l-btn-text")[0];
			var text=$btntext.innerText;
			if (text.indexOf($g("视图"))>=0){
				var gridData=PageLogicObj.m_MarkListDataGrid.datagrid('getRows');
				if (FroceRow < gridData.length){
					PageLogicObj.m_MarkListDataGrid.datagrid('selectRow', FroceRow);
				}
			}
		}
	}
	var selCardIndex="";
	var $markcard=$(".markcard-select");
	if ($markcard.length>0){
		selCardIndex=$markcard[0]["id"].split("-")[0];
	}
	if (keyCode==37){
		//左
		var nextIndex=parseInt(selCardIndex)-1;
		if (isNaN(nextIndex)||(nextIndex<0)) return true
		if (selCardIndex!=""){
			$(".markcard-select").removeClass("markcard-select");
			$("#"+nextIndex+"-marklist-card").addClass("markcard-select");
			SetMarkCardFocus(nextIndex+"-marklist-card");
		}
	}else if(keyCode==38){
		if (document.activeElement.tagName=="INPUT"){
			return false;
		}
		//上
		var width=$("#MarkListPanel").width();
		var RowNumber=Math.floor(width/200);
		var nextIndex=parseInt(selCardIndex)-parseInt(RowNumber);
		if (isNaN(nextIndex)||(nextIndex<0)) return true;
		$(".markcard-select").removeClass("markcard-select");
		$("#"+nextIndex+"-marklist-card").addClass("markcard-select");
		SetMarkCardFocus(nextIndex+"-marklist-card");
	}else if(keyCode==39){
		//右
		var nextIndex=parseInt(selCardIndex)+1;
		if (isNaN(nextIndex)||(nextIndex<0)) return true
		if (nextIndex>=($(".marklist-card").length)-1) return true;
		$(".markcard-select").removeClass("markcard-select");
		$("#"+nextIndex+"-marklist-card").addClass("markcard-select");
		SetMarkCardFocus(nextIndex+"-marklist-card");
		
	}else if(keyCode==40){
		if (document.activeElement.tagName=="INPUT"){
			return false;
		}
		//下
		var width=$("#MarkListPanel").width();
		var RowNumber=Math.floor(width/200);
		var nextIndex=parseInt(selCardIndex)+parseInt(RowNumber);
		if (isNaN(nextIndex)||(nextIndex<0)) return true
		if (nextIndex>=($(".marklist-card").length)-1) return true;
		$(".markcard-select").removeClass("markcard-select");
		$("#"+nextIndex+"-marklist-card").addClass("markcard-select");
		SetMarkCardFocus(nextIndex+"-marklist-card");
	}
	//回车事件或者
	if (keyCode==13) {
		if ((SrcObj.tagName=="A")||(SrcObj.tagName=="INPUT")) {
			if (SrcObj.id=="CardNo"){
				CardNoKeydownHandler(e);
				return false;
			}else if(SrcObj.id=="PatientNo"){
				PatientNoKeydownHandler(e);
				return false;
			}
			if (SrcObj.className.indexOf("seltimerange")<0){
				return true;
			}
		}
		var $id=$(".markcard-select");
		if ($id.length>0){
			var id=$id[0]["id"];
			var dataStr=$($("#"+id).find("div")[8]).html();
			var jsonData=JSON.parse(dataStr);
			MarkListDBClick(jsonData);
		}else{
			if (PageLogicObj.m_MarkListDataGrid!=""){
				var row=PageLogicObj.m_MarkListDataGrid.datagrid('getSelected');
				if (row){
					MarkListDBClick(row);
				}
			}
		}
		if (SrcObj.className.indexOf("seltimerange")>=0){
			return false;
		}
		return true;
	}
	window.onhelp = function() { return false };
	return true;
}
function curDayAppListDataGrid(){
	var Columns=[[ 
		{field:'Operation',title:'操作',width:50,
			formatter: function(value,row,index){
				var btn = '<a class="editcls" onclick="CancelApp(\'' + row["TAPPTRowID"] + '\')"><img src="../scripts_lib/hisui-0.1.0/dist/css/icons/cancel.png"/></a>';
				return btn;
			}
		},
		{field:'TabDeptDesc',title:'科室',width:140},
		{field:'TabMarkDesc',title:'号别',width:140},
		{field:'TabSeqNo',title:'诊号',width:50},
		{field:'TabPrice',title:'价格',width:50},
		{field:'TabAppDate',title:'就诊日期',width:100},
		{field:'TAPPTRowID',title:'',hidden:true},
    ]]
	var curDayAppListDataGrid=$("#curDayAppList").datagrid({
		fit : true,
		border : false,
		striped : true,
		singleSelect : true,
		fitColumns : false,
		autoRowHeight : false,
		rownumbers:false,
		pagination : false,  
		idField:'TAPPTRowID',
		columns :Columns,
		onDblClickRow:function(index, row){
			//DelSelMarkListRow(row);
		}
	}); 
	return curDayAppListDataGrid;
}
function InitselectedMarkListDataGrid(){
	var Columns=[[ 
		{field:'Operation',title:'操作',width:50,
			formatter: function(value,row,index){
				var btn = '<a class="editcls" onclick="DelSelMarkListRowByABRS(\'' + row['TabASRowId'] + '\')"><img src="../scripts_lib/hisui-0.1.0/dist/css/icons/cancel.png"/></a>';
				return btn;
			}
		},
		{field:'TabASRowId',hidden:true,title:''},
		{field:'TabDeptDesc',title:'科室',width:140,styler:function(value,row,index){
			return "font-weight:bold;"
		}},
		{field:'TabMarkDesc',title:'医生',width:140,
			formatter: function(value,row,index){
				var btn = value
				if ((row.TabClinicGroupDesc!="")&&(row.TabClinicGroupDr!="")&&(btn.indexOf(row.TabClinicGroupDesc)<0)) btn=btn+"<span style='color:red'>("+row.TabClinicGroupDesc+")</span>"
				return btn;
			},
			styler:function(value,row,index){
			return "font-weight:bold;"
		}},
		{field:'TabTimeRange',title:'时段',width:100,styler:function(value,row,index){
			return "font-weight:bold;"
		}},
		{field:'TabAppDate',title:'就诊日期',width:100},
		{field:'TabPrice',title:'价格',width:50},
		{field:'TabSeqNo',title:'诊号',width:50},
		{field:'TabClinicGroupDesc',title:'专业组',width:80},
		{field:'TabClinicGroupDr',title:'ClinicGroupDr',width:80,hidden:true},
		{field:'TabDeptRowId',title:'',hidden:true},
		{field:'TabPCLRowID',title:'',hidden:true},
		{field:'TAPPTRowID',title:'',hidden:true},
		{field:'TabFreeRegFlag',title:'',hidden:true},
		{field:'TabFreeCheckFlag',title:'',hidden:true},
		{field:'TabReAdmFeeFlag',title:'',hidden:true},
		{field:'TabHoliFee',title:'',hidden:true},
		{field:'TabAppFee',title:'',hidden:true},
		{field:'TabExamFee',title:'',hidden:true}
    ]]
	var selectedMarkListDataGrid=$("#selectedMarkList").datagrid({
		fit : true,
		border : false,
		striped : true,
		singleSelect : true,
		fitColumns : false,
		autoRowHeight : false,
		rownumbers:false,
		pagination : false,  
		idField:'TabASRowId',
		columns :Columns,
		onDblClickRow:function(index, row){
			DelSelMarkListRow(row);
		}
	}); 
	return selectedMarkListDataGrid;
}
function DelSelMarkListRow(){
	var row=PageLogicObj.m_selectedMarkListDataGrid.datagrid('getSelected');
	var BillAmount=$("#BillAmount").val();
	if (BillAmount!="") {
		BillAmount=parseFloat(BillAmount)-parseFloat(row["TabPrice"]);
		BillAmount=BillAmount.toFixed(2);
		var index=PageLogicObj.m_selectedMarkListDataGrid.datagrid('getRowIndex',row);
		PageLogicObj.m_selectedMarkListDataGrid.datagrid('deleteRow',index);
		$("#BillAmount").val(BillAmount);
		ReCalculateAmount();
	}
}
function DelSelMarkListRowByABRS(ASRowId){
	var index=PageLogicObj.m_selectedMarkListDataGrid.datagrid('getRowIndex',ASRowId);
	PageLogicObj.m_selectedMarkListDataGrid.datagrid('selectRow',index);
	DelSelMarkListRow();
}
function curDayRegListDataGrid(){
	var Columns=[[ 
		{field:'PatDr',title:'操作',width:50,
			formatter: function(value,row,index){
				var btn = '<a class="editcls" onclick="BCacelRegHandle(\'' + row["AdmId"] + '\')"><img src="../scripts_lib/hisui-0.1.0/dist/css/icons/cancel.png"/></a>';
				return btn;
			}
		},
		{field:'AdmId',hidden:true,title:''},
		{field:'Dept',title:'科室',width:140},
		{field:'Doctor',title:'号别',width:100},
		{field:'Tph',title:'诊号',width:80},
		{field:'RegfeeDate',title:'挂号日期',width:120},
		{field:'UserName',title:'操作员',width:80}
    ]]
	var curDayRegListDataGrid=$("#curDayRegList").datagrid({
		fit : true,
		border : false,
		striped : true,
		singleSelect : true,
		fitColumns : false,
		autoRowHeight : false,
		rownumbers:false,
		pagination : false,  
		idField:'AdmId',
		columns :Columns
	}); 
	return curDayRegListDataGrid;
}
/*
字体规则
医生字体绿色 			便捷排班
医生字体黑色 			正常排班
医生字体红色、斜体 		正常排班且号已挂完
行背景色红色 			已停诊
*/
function MarkListDataGrid(){
	var Columns=[[ 
		{field:'ASRowId',hidden:true,title:''},
		{field:'ClinicGroupDr',hidden:true,title:''},
		{field:'MarkDesc',title:'医生',width:210,
			formatter: function(value,row,index){
				var btn = value
				if ((row.ClinicGroupDr!="")&&(row.ClinicGroupDesc!="")) {btn=value+"<span style='color:red'>("+row.ClinicGroupDesc+")</span>"}
				if ((row.ClinicGroupDr!="")&&(row.ClinicGroupDesc!="")&&(row.ScheduleStatus=="停诊")) {btn=value+"<span style='color:#ffffff'>("+row.ClinicGroupDesc+")</span>"}
				return btn;
			},
			styler: function(value,row,index){
				if ((+row["AvailSeqNoStr"]==0)&&(+row["AvailAddSeqNoStr"]==0)&&(ServerObj.SeqNoMode=='')){
					return 'color: red;';
				}else if(row["NoLimitLoadFlag"]=="Y"){
					return 'color: green;';
				}
			}
		},
		{field:'DepDesc',title:'科室',width:120},
		{field:'SessionTypeDesc',title:'挂号职称',width:80},
		{field:'AvailSeqNoStr',title:'剩号',width:80},
		{field:'RegedCount',title:'已挂号数',width:80},
		{field:'AppedCount',title:'已预约数',width:80},
		{field:'ScheduleDate',title:'日期',width:100},
		{field:'TimeRange',title:'时段',width:70},
		{field:'RegFee',title:'挂号费',width:70},
		{field:'ExamFee',title:'诊查费',width:70},
		{field:'Load',title:'正号限额',width:80},
		{field:'AppLoad',title:'预约限额',width:80},
		{field:'AddedCount',title:'已加号数',width:80},
		{field:'AddLoad',title:'加号限额',width:80},
		{field:'AppFee',title:'预约费',width:70},
		{field:'AvailAddSeqNoStr',title:'加号',width:80},
		{field:'AppedArriveCount',title:'已取号数',width:80},
		{field:'AvailNorSeqNoStr',title:'现场剩号',width:80},
		{field:'ClinicGroupDesc',title:'专业组',width:80},
		{field:'HoliFee',title:'假日费',width:70},
		{field:'AppFeeDr',title:'其他费',width:70,hidden:true}, //OtherFee原先取的字段是AppFeeDr？
		{field:'ReCheckFee',title:'复诊费',width:70},
		{field:'BorghAlertInfo',title:'提示信息',width:80,showTip:true}, //RoomCode
		{field:'RoomDesc',title:'诊室',width:80},
		{field:'ScheduleDateWeek',title:'星期',width:80},
		{field:'ScheduleStatus',title:'排班状态',width:80},
		{field:'AdmWaitSum',title:'当前待诊人数',width:95},
		{field:'NoLimitLoadFlag',title:'便捷排班标识',hidden:true},
		{field:'DepDr',hidden:true,title:''},
		{field:'MarkDr',hidden:true,title:''},
		{field:'RegFeeDr',hidden:true,title:''}
    ]]
	var MarkListDataGrid=$("#MarkList").datagrid({
		fit : true,
		border : false,
		striped : true,
		singleSelect : true,
		fitColumns : false,
		autoRowHeight : false,
		pagination : false,  
		idField:'ID',
		rownumbers:true,
		columns :Columns,
		rowStyler: function(index,row){
			if (row["ScheduleStatus"]=="停诊"){
				return 'background-color:red;'
			}
			var AvailSeqNoStr=+row["AvailSeqNoStr"];
			var AvailAddSeqNoStr=+row["AvailAddSeqNoStr"];
			var AvailNorSeqNoStr=+row["AvailNorSeqNoStr"]
			if ((AvailSeqNoStr==0)&&(AvailAddSeqNoStr==0)&&(ServerObj.SeqNoMode=='')){
				return 'font-style: italic;';
			}
			if ((AvailSeqNoStr==0)&&(ServerObj.ParaRegType=="APP")&&(ServerObj.SeqNoMode=='')){
				return 'font-style: italic;';
			}
			if ((AvailNorSeqNoStr==0)&&(ServerObj.SeqNoMode=='1')){
				return 'font-style: italic;';
			}
		},
		onDblClickRow:function(index, row){
			MarkListDBClick(row);
		},
		onSelect:function(index, row){
			if (ServerObj.ParaRegType=="APP"){
				$("#SelDate").html(row.ScheduleDate);
				$("#WeekDesc").html($g(row.ScheduleDateWeek));
			}
			if (PageLogicObj.m_MarkPopoverTrigger=="click"){
				DestoryPannelPopover();
				try{
					InitMarkListRowPopover({rowIndex:index,markCardID:"",Show:true})
				}catch(e){}
			}
			
		},
		onLoadSuccess:function(data){
			if(data["rows"].length>0){
				//默认选中第一行
				$(this).datagrid('selectRow', 0);  
				//设置焦点,否则在选中第一行后监听不到上下键事件
				$("#MarkList").datagrid('getPanel').panel('panel').focus();
			}
			if (PageLogicObj.m_MarkPopoverTrigger=="hover"){
				//鼠标滑动触发浮动窗
				InitMarkListRowMouseHandle();
			}
		}
	}).datagrid("keyCtr"); 
	return MarkListDataGrid;
}
// 初始化行的鼠标浮动事件，用于展示分时段或挂号详情信息
function InitMarkListRowMouseHandle() {
	if ((ServerObj.ParaRegType!="APP")&&(ServerObj.OPRegistShowTimeRange!="1")){
		return false;
	}
	
	var _datagridRow=$("#MarkList").datagrid("options").finder.getTr($("#MarkList")[0],"","allbody",2)
	_datagridRow.mouseover(function(e,value){
		DestoryPannelPopover();
		var _rowIndex=parseInt($(this).attr("datagrid-row-index"));
		InitMarkListRowPopover({rowIndex:_rowIndex,markCardID:"",Show:true});
	}).mouseout(function(value){
		//对鼠标所在行数据的获取与mouseover的实现类似
		//$(this).popover('hide');
	});
	if (PageLogicObj.m_MouseoverId != "") {
		// 切换 popover switch 按钮时，手动触发 mouseover
		$("#" + PageLogicObj.m_MouseoverId).mouseover()
	}
	
}
/// 销毁列表\卡片模式浮动出来的所有弹窗
function DestoryPannelPopover(){
	try{$("#switch-btn").tooltip("destroy");}catch(e){}
	//列表模式下的弹窗
	try{
		var _datagridRow=$("#MarkList").datagrid("options").finder.getTr($("#MarkList")[0],"","allbody",2);
		_datagridRow.each(function(index,obj){
			var popoverID=$(obj).attr("id");
			try{
				//$("#"+popoverID).popover("hide");
				$("#"+popoverID).popover("destroy");
			}catch(e){}
		})
	}catch(e){}
	try{
		$("[id$=-marklist-card]").each(function(index,obj){
			var popoverID=$(obj).attr("id");
			try{
				//$("#"+popoverID).popover("hide");
				$("#"+popoverID).popover("destroy");
			}catch(e){}
		})
	}catch(e){}
}
// 初始化列表\卡片模式的浮动窗
function InitMarkListRowPopover(param) {
	var rowIndex=param.rowIndex;
	var markCardID=param.markCardID;
	var Show=param.Show;		//立即显示
	if ((rowIndex!=="")){
		//列表模式
		var popoverID=$("#MarkList").datagrid("options").finder.getTr($("#MarkList")[0],rowIndex,"body",2).attr("id");
		var jsonData=$("#MarkList").datagrid("options").finder.getRow($("#MarkList")[0], rowIndex);
		if (!jsonData){ return false; }
		var MarkListShowMode=$g("列表");
		$("#MarkList").datagrid('getPanel').panel('panel').focus();	//防止丢失表格焦点
	}else if (markCardID!=""){
		//卡片模式
		var popoverID=markCardID;
		var dataStr=$($("#"+markCardID).find("div")[8]).html();
		var jsonData=JSON.parse(dataStr);
		var MarkListShowMode= $g("视图");
		$("#"+markCardID).parent().focus();
	}else{
		return false;
	}
	//进行针对该行数据的其他处理
	var HTML=GetPannelHTML(jsonData,popoverID);
	if (HTML.innerHTML==""){return;}
	
	$("#"+popoverID).popover({
		width:HTML.width,
		height:HTML.height,
		title:HTML.Title,
		content:HTML.innerHTML,
		closeable:HTML.closeable,
		trigger:'manual',
		placement:'auto', 
		container:MarkListShowMode==$g("视图")?$("body"):$("#MarkInfoPanel"),
		cache:false,
		onShow:function(){
			if (MarkListShowMode==$g("列表")){
				if (HTML.closeable) {
					$(".webui-popover").css({
						'left':'250px'
					});
				}else{
					$(".webui-popover").css({
						//'left':'700px'
						'left':'470px'
					});
				}
			}
			if (typeof HTML.CallFunction == "function"){
				HTML.CallFunction.call();
			}
			var curPopoverId = $("#"+this.id).attr("data-target")
			$.parser.parse($("#switch-btn").parent())
			
			PageLogicObj.m_PopoverId = curPopoverId
			PageLogicObj.m_MouseoverId = this.id
		},
		onHide: function(e, value) {
			PageLogicObj.m_MouseoverId = ""
		}
	});
	if (Show){
		$("#"+popoverID).popover("show");
	}
}
function MarkListDBClick(row){
	var dataObj=new Object();
	var MarkDesc=row["MarkDesc"]
	if (row["ClinicGroupDesc"]!="" && row["ClinicGroupDr"]!=""){var MarkDesc=row["MarkDesc"]+"<span style='color:red'>("+row["ClinicGroupDesc"]+")</span>"}
	dataObj={
		TabASRowId:row["ASRowId"],
		DeptDesc:row["DepDesc"],
		MarkDesc:MarkDesc,
		SeqNo:row['SeqNo'],
		Price:"",
		AdmDate:row["ScheduleDate"],
		DeptRowId:row["DepDr"],
		TabPCLRowID:"",
		TAPPTRowID:"",
		AvailSeqNoStr:row["AvailSeqNoStr"],
		AvailAddSeqNoStr:row["AvailAddSeqNoStr"],
		HoliFee:row["HoliFee"],
		ExamFee:row["ExamFee"],
		RegFee:row["RegFee"],
		AppFee:row["AppFee"],
		OtherFee:row["AppFeeDr"],
		ReCheckFee:row["ReCheckFee"],
		TabFreeRegFlag:"",
		TabFreeCheckFlag:"",
		TabReAdmFeeFlag:"",
		TabTimeRange:row["TimeRange"],
		StopRegFlag:row["StopRegFlag"],
		TabClinicGroupDesc:row["ClinicGroupDesc"],
		TabClinicGroupDr:row["ClinicGroupDr"],
		CurrentMarkDesc:row["MarkDesc"]
	}
	PageLogicObj.CommonCardrow=row
	AddBeforeUpdate(dataObj)  ///AddToSelectedMarkList放到AddBeforeUpdate里面
	
	//if (AddBeforeUpdate(dataObj)==false) return false;
	//AddToSelectedMarkList(dataObj,true);
}
function AddToSelectedMarkList(dataObj,alertFlag){
	if ((ServerObj.ParaRegType!="APP")||(dataObj["TAPPTRowID"]=="")){
		var $tab=PageLogicObj.m_selectedMarkListDataGrid;
	}else{
		var $tab=PageLogicObj.m_curDayAppListDataGrid;
	}
	$tab.datagrid('appendRow',{
		Operation:"",
		TabASRowId: dataObj["TabASRowId"],
		TabDeptDesc:dataObj["DeptDesc"],
		TabMarkDesc: dataObj["MarkDesc"],
		TabSeqNo: dataObj["SeqNo"],
		TabPrice: dataObj["Price"],
		TabAppDate:dataObj["AdmDate"],
		TabDeptRowId: dataObj["DeptRowId"],
		TabPCLRowID:dataObj["TabPCLRowID"],
		TAPPTRowID: dataObj["TAPPTRowID"],
		TabFreeRegFlag: dataObj["TabFreeRegFlag"],
		TabFreeCheckFlag: dataObj["TabFreeCheckFlag"],
		TabReAdmFeeFlag: dataObj["TabReAdmFeeFlag"],
		TabHoliFee: dataObj["HoliFee"],
		TabAppFee: dataObj["AppFee"],
		TabExamFee: dataObj["ExamFee"],
		TabTimeRange:dataObj["TabTimeRange"],
		TabClinicGroupDesc:dataObj["TabClinicGroupDesc"],
		TabClinicGroupDr:dataObj["TabClinicGroupDr"]
	});
	if (alertFlag) {
		$.messager.popover({msg: '已添加到号别列表!',type:'success',timeout: 2000});
	}
	// DTS埋点门诊-选择号源
	DTSLog.AddOnelog("1635895983521009664",PatientID,PatientID,"",session['LOGON.USERCODE'])
}
var m_ReadCardMode="";
var m_CCMRowID="";
function UpdateClickHandler(){
	// 防止快速点击重复挂号
	if ($("#Update").hasClass('l-btn-disabled')){
		return false;
	}
	$("#Update").addClass('l-btn-disabled')
	//初始化打印模板--如果打印发票不刷新模板重新初始化
	if (ServerObj.ParaRegType!="APP"){
		DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAdmRegPrint");
	}
	if (PageLogicObj.m_selectedMarkListDataGrid==""){
		$.messager.alert("提示","没有选择挂号信息!");
		$("#Update").removeClass('l-btn-disabled')
		return false;
		}
	var NeedDelIndexArr=new Array();
	var Data=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
	if (Data["rows"].length==0){
		$.messager.alert("提示","没有选择挂号信息!");
		$("#Update").removeClass('l-btn-disabled')
		return false;
	}
	var BillAmount=$('#BillAmount').val(); 
	var CardTypeRowID=$("#CardTypeRowID").val();
	var CardNo=$('#CardNo').val(); 
	//帐户RowId
	var AccRowId=""; 
	var PayModeCode=GetPayModeCode();
	if (PayModeCode=="") {
		$.messager.alert("提示","请选择支付方式!");
		$("#Update").removeClass('l-btn-disabled')
		return false;
	}
	//办理预约是否要预先分配号,取号的处理在同一界面吗
	var PatientID=$('#PatientID').val();
	var UserID=session['LOGON.USERID'];
	var GroupID=session['LOGON.GROUPID'];
	var LocID=session['LOGON.CTLOCID'];
	var AdmReason=$('#BillType').combobox('getValue');
	if (AdmReason=="") {
		$.messager.alert("提示","费别为空,请选择患者费别!");
		$("#Update").removeClass('l-btn-disabled')
		return false;
	}
	var AdmType="" //DHCC_GetElementData('AdmType');
	var RegConDisId=$("#RegConDisList").combobox('getValue');
	var DiagnosCatRowId="";
	var RemoveRows=""
	var UseInsuFlag="N",InsuReadCardInfo=""
	var LoopDataObj={};
	var ETPRowID="";
	var RegExpStr=CardTypeRowID+"^"+CardNo
	//var EnableInsuBillFlag=IsEnableInsuBill(PatientID,Data["rows"][0].TabASRowId,UseInsuFlag,AdmReason,InsuReadCardInfo);
	try{
		new Promise(function(resolve,rejected){
			if (PayModeCode=="CPP") {
				var CardTypeRowID=$("#CardTypeRowID").val();
				if (CardTypeRowID!=""){
					var myoptval=$.cm({
						ClassName:"web.UDHCOPOtherLB",
						MethodName:"ReadCardTypeDefineListBroker1",
						dataType:"text",
						myTypeID:CardTypeRowID
					},false);
					m_ReadCardMode=myoptval.split("^")[16];
					m_CCMRowID=myoptval.split("^")[14];
				}
				(function(callBackFun){
					new Promise(function(resolve,rejected){
						//DHCACC_CheckMCFPay(BillAmount,CardNo,"",CardTypeRowID,"",resolve);
						CardCommon_ControlObj.CheckMCFPay({
							PatSum:BillAmount,
							CardNo:CardNo,
							CardTypeDR:CardTypeRowID,
							CallBackFun:resolve
						});
					}).then(function(ren){
						var myary=ren.split("^");
						if (myary[0]!='0'){
							if (myary[0]=='-204'){
								$.messager.alert("提示","此用户的账户被冻结,不能办理支付,请找管理员处理!")
								$("#Update").removeClass('l-btn-disabled')
								return false;
							}else if (myary[0]=='-205'){
								var ret=ChangePayMode();
								if(!ret){
									$("#Update").removeClass('l-btn-disabled')
									return false;	
								}
								PayModeCode=GetPayModeCode();
							}else if (myary[0]=='-206'){
								$.messager.alert("提示","卡号码不一致,请使用原卡!")
								$("#Update").removeClass('l-btn-disabled')
								return false;
							}else if(myary[0]=='-201'){
								$.messager.alert("提示","该患者不存在有效账户，不能使用预交金支付!")
								$("#Update").removeClass('l-btn-disabled')
								return false;
							}else{
								$.messager.alert("提示","卡校验失败，请重试")
								$("#Update").removeClass('l-btn-disabled')
								return false;
							}
						}else{
							AccRowId=myary[1];
							var AccAmount=$('#AccAmount').val();
							if ((AccRowId!="")&&(AccAmount=="")){
								var AccmLeftBalance=$.cm({
									ClassName:"web.DHCOPAdmReg",
									MethodName:"GetAccmLeftBalance",
									dataType:"text",
									AccRowId:AccRowId
								},false);
								$('#AccAmount').val(AccmLeftBalance);
							}
						}
						callBackFun();
					})
				})(resolve);
			}else{
				resolve();
			}
		}).then(function(){
			return new Promise(function(resolve,rejected){
				//当实收金额小于应收金额不允许挂号,走配置
				var CFNotNullRealAmount=GetDHCOPRegConfig("NotNullRealAmount");
				if (CFNotNullRealAmount==1) {
					var EnableInsuBillFlag=false;
					for (var j=0;j<Data["rows"].length;j++) {
						EnableInsuBillFlag=IsEnableInsuBill(PatientID,Data["rows"][j].TabASRowId,UseInsuFlag,AdmReason,InsuReadCardInfo);
						if (EnableInsuBillFlag==true) break;
					}
					if (EnableInsuBillFlag==false) {
						var GetAmountPrice=$('#PaySum').val();
						if (GetAmountPrice==""){GetAmountPrice=0} 
						if ((PayModeCode=='CASH')&((parseFloat(GetAmountPrice))<BillAmount)){
							$.messager.alert("提示","实收金额小于应收金额!","info",function(){
								$('#PaySum').focus();
							});
							$("#Update").removeClass('l-btn-disabled')
							return false;
						}
						if ((parseFloat(GetAmountPrice)=="0")&(PayModeCode=="CASH")){
							$.messager.confirm('确认对话框', "实收金额为零是否继续挂此号?", function(r){
								if (!r) {
									$("#GetAmount").focus(); 
									$("#Update").removeClass('l-btn-disabled')
									return false;
								}
								resolve();
							});
							return;
						}
					}
				}
				resolve();
			})
		}).then(function(){
			return new Promise(function(resolve,rejected){
				(function(callBackFun){
					function loop(j){
						new Promise(function(resolve,rejected){
							var TabPrice=Data["rows"][j]["TabPrice"];
							var TabExamFee=Data["rows"][j]["TabExamFee"]; 
							var TabHoliFee=Data["rows"][j]["TabHoliFee"]; 
							var TabAppFee=Data["rows"][j]["TabAppFee"];  
							var TabQueueNo=Data["rows"][j]["TabSeqNo"];
							if (!TabQueueNo) TabQueueNo="";
							var TabReAdmFeeFlag=Data["rows"][j]["TabReAdmFeeFlag"];
							RegExpStr=CardTypeRowID+"^"+CardNo+"^"+Data["rows"][j]["TabClinicGroupDr"]+"^"+PageLogicObj.m_ApptTypeCode +"^"+LocID;
							//是否传病历号
							var TabMRFee="0";
							//病历本费置收取1份
							var o=$HUI.checkbox('#MedicalBook');
							if ((o.getValue())&&(j==0)){
								TabMRFee="1";
								TabPrice=parseFloat(TabPrice)+parseFloat(ServerObj.MRNoteFee);
							}
							//var TabCardFee=$("#NeedCardFee").checkbox('getValue')?1:0;
							var TabCardFee=0;
							var o=$HUI.checkbox('#NeedCardFee');
							if ((o.getValue())&&(j==0)){
								TabCardFee="1";
								TabPrice=parseFloat(TabPrice)+parseFloat(ServerObj.CardFee);
							}
							//如果为复诊,且有诊查费,则重新设置穿入参数值
							var TabReCheckFee=0;
							if ((TabReAdmFeeFlag==1)&&((TabExamFee!="")&&(TabExamFee!=0))){		
								TabReCheckFee=TabExamFee;
								TabExamFee=0;
							}
							var TimeRangeStr=Data["rows"][j]["TabTimeRange"];
							LoopDataObj={
								TabPrice:TabPrice,
								TabASRowId:Data["rows"][j]["TabASRowId"], 
								//此时的诊查费可能是复诊诊查费
								TabExamFee:TabExamFee,
								TabHoliFee:TabHoliFee,
								TabAppFee:TabAppFee, 
								TabQueueNo:TabQueueNo,
								AppDate:Data["rows"][j]["TabAppDate"],
								TabReAdmFeeFlag:Data["rows"][j]["TabReAdmFeeFlag"],
								//界面上传过来的免挂号费和免诊查费标记
								TabFreeRegFlag:Data["rows"][j]["TabFreeRegFlag"],
								TabFreeCheckFlag:Data["rows"][j]["TabFreeCheckFlag"],
								//预约ID
								TAPPTRowID:Data["rows"][j]["TAPPTRowID"],
								//急诊分级表
								TabPCLRowID:Data["rows"][j]["TabPCLRowID"],
								TabMRFee:TabMRFee,
								TabCardFee:TabCardFee,
							    BLNo:0,     //是否传病历号标志?0不传病历号?1传病历号
								FeeStr:TabPrice+"||"+TabExamFee+"||"+TabHoliFee+"||"+TabAppFee+"||"+TabMRFee+"||"+TabReCheckFee+"||"+TabCardFee,
								TimeRangeStr:TimeRangeStr
							}
							//医保实时结算
							var InsuJoinStr="";
							var InsuAdmInfoDr="",InsuDivDr="";
							var InsuPayFeeStr="";
							var UseInsuFlag="N",UPatientName="",RegType="",FreeRegFeeFlag="",InsuReadCardInfo="",RetInsuGSInfo="";
							$.extend(LoopDataObj, { InsuJoinStr: InsuJoinStr,InsuAdmInfoDr:InsuAdmInfoDr});
							//开始挂号前进行锁号操作，暂不判断是否存在异常订单
							//锁号
							var PatientNo=$('#PatientNo').val();
							var OPRegLockInfo=LoopDataObj.TabASRowId+"^"+LoopDataObj.TabQueueNo+"^"+UserID+"^"+"Y"+"^"+PatientNo;
							/*var CTLSRowId=$.cm({
								ClassName:"web.DHCOPAdmReg",
								MethodName:"OPRegLockSepNo",
								dataType:"text",
								LockSepNoInfo:OPRegLockInfo
							},false);
							if (CTLSRowId<0){
								$.messager.alert("提示","锁号失败!");
								return false;
							}*/
							var EnableInsuBillFlag=IsEnableInsuBill(PatientID,LoopDataObj.TabASRowId,UseInsuFlag,AdmReason,InsuReadCardInfo)
							if (EnableInsuBillFlag==true) {
								var InsuBillParamsObj={};
								InsuBillParamsObj.PatientID=PatientID;
								InsuBillParamsObj.UPatientName=UPatientName;
								InsuBillParamsObj.UserID=UserID;
								InsuBillParamsObj.ASRowId=LoopDataObj.TabASRowId;
								InsuBillParamsObj.AdmReasonId=AdmReason;
								//[可选]挂号组织的费用串，默认为"1||1||||||||"
								InsuBillParamsObj.FeeStr=LoopDataObj.FeeStr;
								//[可选]挂号类别，默认为空
								InsuBillParamsObj.RegType=RegType;
								//[可选]挂号费免费标识，默认为空
								InsuBillParamsObj.FreeRegFeeFlag=LoopDataObj.FreeRegFeeFlag;
								//[可选]读医保卡返回信息，默认为空
								InsuBillParamsObj.InsuReadCardInfo=InsuReadCardInfo;
								//[可选]工商医保信息，默认为空
								InsuBillParamsObj.RetInsuGSInfo=RetInsuGSInfo;
								//账户ID
								InsuBillParamsObj.AccRowId=AccRowId;
								//个人自付支付方式代码
								InsuBillParamsObj.PayModeCode=PayModeCode;
								InsuJoinStr=CallInsuBill(InsuBillParamsObj);
								$.extend(LoopDataObj, { InsuJoinStr: InsuJoinStr});
								if (InsuJoinStr!="") {
									var myAry=InsuJoinStr.split("^");
									var ConFlag=myAry[0];
									if (ConFlag==0){
										InsuAdmInfoDr=myAry[1];
										InsuDivDr=myAry[2];
										InsuPayFeeStr=InsuJoinStr.split("!")[1];
										$.extend(LoopDataObj, { InsuAdmInfoDr: InsuAdmInfoDr});
									}else{
										//医保挂号失败解锁
										/*var ret=$.cm({
											ClassName:"web.DHCOPAdmReg",
											MethodName:"OPRegUnLockSepNo",
											dataType:"text",
											CTLSRowId:CTLSRowId
										},false);*/
										var row=PageLogicObj.m_selectedMarkListDataGrid.datagrid('getRows')[j];
										var delTabPrice=row["TabPrice"];
										PageLogicObj.m_selectedMarkListDataGrid.datagrid('deleteRow',j);
										// 删除后重新计算合计金额
										var BillAmount=$("#BillAmount").val();
										BillAmount=parseFloat(BillAmount)-parseFloat(delTabPrice);
										BillAmount=BillAmount.toFixed(2);
										$("#BillAmount").val(BillAmount);
										ReCalculateAmount();
										$("#Update").removeClass('l-btn-disabled')
										return false;
									}
						
									if (InsuPayFeeStr!=""){
										var InsuTotalAmount=GetInsuTotalAmount(InsuPayFeeStr);
										var TotalAmount=InsuTotalAmount.split("^")[0];
										var CashFee=InsuTotalAmount.split("^")[1];
										if(parseFloat(TotalAmount)!=parseFloat(TabPrice)){
											//$.messager.alert("提示","当前价格与实时结算上传总价格不一致?请确认医嘱价格!");
											//return false;
										}
									}
								}
							}
							//第三方交易接口部署
							RegPayObj.RegPay(TabPrice,PatientID,"",LoopDataObj.InsuJoinStr,"","","","","","","OP",resolve)
						}).then(function(rtnPay){
							return new Promise(function(resolve,rejected){
								PayModeCode=RegPayObj.PayModeCode;
								if (!rtnPay){
									//交易失败如果是医保的需要回退
									ReturnInsuOPReg(PatientID,LoopDataObj.InsuAdmInfoDr,LoopDataObj.TabASRowId,AdmReason)
									$("#Update").removeClass('l-btn-disabled')
									return false;
								}
								if ((typeof RegPayObj.PayRtnJsonObj!="undefined")&&(typeof RegPayObj.PayRtnJsonObj.ETPRowID!="undefined")&&(RegPayObj.PayRtnJsonObj.ETPRowID!="")) {
									ETPRowID=RegPayObj.PayRtnJsonObj.ETPRowID;
								}
								resolve();
							})
						}).then(function(){
							return new Promise(function(resolve,rejected){
								var ret=$.cm({
									ClassName:"web.DHCOPAdmReg",
									MethodName:"OPRegistBroker",
									dataType:"text",
									PatientID:PatientID, ASRowId:LoopDataObj.TabASRowId, AdmReason:AdmReason, QueueNo:LoopDataObj.TabQueueNo, FeeStr:LoopDataObj.FeeStr,
									PayModeCode:PayModeCode, AccRowId:AccRowId, user:UserID, group:GroupID,
									AdmType:AdmType, DiagnosCatRowId:DiagnosCatRowId, 
									FreeRegFlag:LoopDataObj.TabFreeRegFlag,FreeCheckFlag:LoopDataObj.TabFreeCheckFlag,RegfeeRowId:"", InsuJoinStr:LoopDataObj.InsuJoinStr,
									DiscountFactor:"", TAPPTRowID:LoopDataObj.TAPPTRowID, 
									UnBillFlag:"", TabPCLRowID:LoopDataObj.TabPCLRowID, ApptMethodCode:"", SourceType:"", RegConDisId:RegConDisId,
									ETPRowID:ETPRowID,TimeRangeStr:LoopDataObj.TimeRangeStr,RegExpStr:RegExpStr
								},false);
								var retarr=ret.split("$");	
								if (retarr[0]=="0"){
									var PrintArr=retarr[1].split("^");
									var EpisodeID="";
									var TabASRowId="";
									var RegfeeRowID="";
									var AdmType="";
									var PrintDataArySum=eval(retarr[1])
									var PrintDataAry=PrintDataArySum[0]
									for (Element in PrintDataAry){
										if (Element=="AdmNo"){EpisodeID=PrintDataAry[Element]}
										if (Element=="RBASDr"){TabASRowId=PrintDataAry[Element]}
										if (Element=="RegfeeRowId"){RegfeeRowID=PrintDataAry[Element]}								
										if (Element=="AdmType"){AdmType=PrintDataAry[Element]}								
									}
									//lxz 第三方交易接口信息关联--tanjishan 20210712放到OPBillCharge去处理
									//RegPayObj.Relation(RegfeeRowID);
									//对外接口调用(医保智能审核、电子发票)
									if (typeof Common_ControlObj == "object") {
										var argObj={
											EpisodeID:EpisodeID,
											PAAdmType:AdmType,
											RegfeeRowId:RegfeeRowID
										}
										Common_ControlObj.AfterUpdate("Interface",argObj)
									}
									//票据合计增加 
									var ReceiptCount=+$('#ReceiptCount').val();
									ReceiptCount=parseInt(ReceiptCount)+1;
									$('#ReceiptCount').val(ReceiptCount);
									//打印挂号小条
									PrintOut(j,retarr[1]);
									//打印发票 --如果存在医保需要判断是调用医保接口打印发票还是调用HIS打印发票-医保修改按照项目上线自行修改
									PrintInv(RegfeeRowID)
									//日志保存 原方法方法不存在,暂时隐藏
									//SavePrescEventLog(EpisodeID);
									NeedDelIndexArr.push(j);
									//DTS埋点提交
									DTSLog.Submitlog();
									//调用回调函数
									resolve();
								}else{
									//HIS挂号失败解锁
									/*var ret=$.cm({
										ClassName:"web.DHCOPAdmReg",
										MethodName:"OPRegUnLockSepNo",
										dataType:"text",
										CTLSRowId:CTLSRowId
									},false);*/
									//撤销医保挂号结算,如果失败则进入异常订单
									ReturnInsuOPReg(PatientID,LoopDataObj.InsuAdmInfoDr,LoopDataObj.TabASRowId,AdmReason)
									//lxz 第三方支付交易接口退回
									RegPayObj.ErrReg();
									var errmsg=GetErrMsg(retarr[0]);
									if(errmsg=="") errmsg=retarr[0];
									var TabDepDesc=Data["rows"][j]["TabDeptDesc"];
									var TabMarkDesc=Data["rows"][j]["TabMarkDesc"];
									var ErrInfo=$g("挂号记录科室") + ":【"+TabDepDesc+"】,"+$g("号别")+":【"+TabMarkDesc+"】,"+$g("就诊日期")+":【"+LoopDataObj.AppDate+"】,"+$g("序号")+":【"+LoopDataObj.TabQueueNo+"】"
									$.messager.alert("提示",ErrInfo + $g("挂号失败") + "！" + $g(errmsg),"info",function(){
										NeedDelIndexArr.push(j);
										if (NeedDelIndexArr.length>0){
											for (var m=NeedDelIndexArr.length-1;m>=0;m--){
												var row=PageLogicObj.m_selectedMarkListDataGrid.datagrid('getRows')[NeedDelIndexArr[m]];
												var delTabPrice=row["TabPrice"];
												PageLogicObj.m_selectedMarkListDataGrid.datagrid('deleteRow',NeedDelIndexArr[m]);
												// 删除后重新计算合计金额
												var BillAmount=$("#BillAmount").val();
												BillAmount=parseFloat(BillAmount)-parseFloat(delTabPrice);
												BillAmount=BillAmount.toFixed(2);
												$("#BillAmount").val(BillAmount);
												ReCalculateAmount();
											}
										}
										$('#CardNo').focus();
									})
									$("#Update").removeClass('l-btn-disabled')
									return false;
								}
							})
						}).then(function(){
							j++;
							if ( j < Data["rows"].length ) {
								 loop(j);
							}else{
								callBackFun();
							}
						})
					}
					loop(0)
				})(resolve);
			})
		}).then(function(){
			if (NeedDelIndexArr.length>0){
				for (var m=NeedDelIndexArr.length-1;m>=0;m--){
					PageLogicObj.m_selectedMarkListDataGrid.datagrid('deleteRow',NeedDelIndexArr[m]);
				}
			}
			$.messager.popover({msg: '挂号成功!',type:'success',timeout: 1000});		
			BClearHandle();
			$("#Update").removeClass('l-btn-disabled')
			if (ServerObj.ParaRegType!="APP"){
			   SetDefaultTimeRange();
		    }
		})
	}catch(e){
		$.messager.alert("提示",e.message+","+e.name);
	}
}
function PrintOut(RegTblRow,PrintData) {
	//修改 同时挂多个号时，加载的xml模板会变成发票模板
	try {
		DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAdmRegPrint");
		var GridData=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
		var ASRowId=GridData["rows"][RegTblRow]["TabASRowId"];
		if (ASRowId==''){
			$.messager.alert("提示","没有选择挂号信息!");
			return false;
		}
		var PrintDataArySum=eval(PrintData)
		var PrintDataAry=PrintDataArySum[0]
		var MyPara = "" + String.fromCharCode(2);
		var PersonPay="",Regitems="",InvoiceId="";
		for (Element in PrintDataAry){
			if (Element=="InvoiceId"){
				InvoiceId=PrintDataAry[Element];
			}
			if (Element=="PersonPay"){
				PersonPay=PrintDataAry[Element];
				if (PersonPay!="") {
					PersonPay=PersonPay.replace("元","");
				}
			}
			if (Element=="AppFee"){
				if (PrintDataAry[Element]!=0){PrintDataAry[Element]="预约费:"+PrintDataAry[Element]+$g("元")}else{PrintDataAry[Element]=""}
			}
			if (Element=="OtherFee"){
				if (PrintDataAry[Element]!=0) {PrintDataAry[Element]=PrintDataAry[Element]+$g("元")}else{PrintDataAry[Element]=""}
			}
			if (Element=="RegFee"){
				if (PrintDataAry[Element]!=0){PrintDataAry[Element]=PrintDataAry[Element]+$g("元")}else{PrintDataAry[Element]=""}
			}
			MyPara=MyPara +"^"+ Element + String.fromCharCode(2) + PrintDataAry[Element];
		}
		var o=$HUI.checkbox('#NeedCardFee');
		if (o.getValue()){
			var CardFee="工本费 "+parseFloat(ServerObj.CardFee)+$g("元");
		}else{
			var CardFee="";
		}
		AccAmount=$('#CardLeaving').val();
		if (GetPayModeCode()=="CPP"){
			var AccTotal=parseFloat(AccAmount)- parseFloat((+PersonPay)) //parseFloat(Total);
		}else {
			var AccTotal=parseFloat(AccAmount);
		}
		$('#CardLeaving').val(AccTotal);
		//消费后金额
		AccTotal=SaveNumbleFaxed(AccTotal);
		//消费前金额
		AccAmount=SaveNumbleFaxed(AccAmount);
		var DYOPMRN=$('#OPMRN').val(); //门诊病案号
		var DYIPMRN=$('#IPMRN').val(); //住院病案号
		MyPara=MyPara +"^"+ "CardFee" + String.fromCharCode(2) +CardFee;
		MyPara=MyPara +"^"+ "CardFee" + String.fromCharCode(2) +CardFee;
		MyPara=MyPara +"^"+ "AccAmount" + String.fromCharCode(2) +AccAmount;
		MyPara=MyPara +"^"+ "AccTotal" + String.fromCharCode(2) +AccTotal;
		MyPara=MyPara +"^"+ "DYOPMRN" + String.fromCharCode(2) +DYOPMRN;
		MyPara=MyPara +"^"+ "DYIPMRN" + String.fromCharCode(2) +DYIPMRN;
		//电子发票相关
		var EInvInfo=$.cm({
			ClassName: "BILL.EINV.BL.COM.InvUpDetailsCtl",
			MethodName: "GetEInvInfoByHisInvDr",
			dataType: "text",
			PayAdmType: "REG", HisInvprtDr: InvoiceId, ExtStr: ""
		}, false);
		if (EInvInfo!="") {
			var EInvUrl=EInvInfo.split("^")[12];
			if (EInvUrl!="") {
				MyPara=MyPara +"^"+ "EInvUrl" + String.fromCharCode(2) +EInvUrl;
			}
		}
		DHC_PrintByLodop(getLodop(),MyPara,"","","");
	} catch(e) {alert(e.message)};
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
		var PoliticalLevel=PrintArr[43];
		var HospName=PrintArr[38];
		var PersonPay=$.trim(PrintArr[39]," ","");
		if (PersonPay!="") {
			PersonPay=PersonPay.replace("元","");
		}
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
		if (ServerObj.HospitalCode=="SCSFY"){
			Room=Room+"就诊";
		}
		//病人自负比例的备注
		var ProportionNote="";
		var ProportionNote1="";
		var ProportionNote2="";
		if ((ServerObj.HospitalCode=="SHSDFYY")&&((InsuCardType=='0')||(InsuCardType=='1'))){
			InsuPayCash="现金支付:"+InsuPayCash;
			InsuPayCount="帐户支付:"+InsuPayCount;
			InsuPayOverallPlanning="统筹支付:"+InsuPayOverallPlanning;
			InsuPayOther="附加支付:"+InsuPayOther;
			ProportionNote="(现金支付中,"+RegFee+"元"+"不属于医保报销范围)";
			ProportionNote1="医疗记录册";
			ProportionNote2="当年帐户余额:  "+ThisYearAmt+"      历年帐户余额:  "+CalendarAmt;
		}else{
			InsuPayCash="";
			InsuPayCount="";
			InsuPayOverallPlanning="";
			InsuPayOther="";
			ProportionNote="本收据中,"+RegFee+"元"+"不属于医保报销范围";
			ProportionNote1="";
			ProportionNote2="";
		}
		var o=$HUI.checkbox('#NeedCardFee');
		if (o.getValue()){
			var CardFee="工本费 "+parseFloat(ServerObj.CardFee)+"元";
		}else{
			var CardFee="";
		}
		RegTime=RegDateYear+"-"+RegDateMonth+"-"+RegDateDay+" "+RegTime;
		AccAmount=$('#CardLeaving').val();
		if (GetPayModeCode()=="CPP"){
			var AccTotal=parseFloat(AccAmount)- parseFloat((+PersonPay)) //parseFloat(Total);
		}else {
			var AccTotal=parseFloat(AccAmount);
		}
		$('#CardLeaving').val(AccTotal);
    	//消费后金额
		AccTotal=SaveNumbleFaxed(AccTotal);
		//消费前金额
    	AccAmount=SaveNumbleFaxed(AccAmount);
		var DYOPMRN=$('#OPMRN').val(); //门诊病案号
		var DYIPMRN=$('#IPMRN').val(); //住院病案号
		var cardnoprint=$("#CardNo").val();//界面卡号		
		if(cardnoprint==""){	
		    var cardnoprint=CardNo ; //后台卡号
		}
		var GridData=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
		var ASRowId=GridData["rows"][RegTblRow]["TabASRowId"];
		if (ASRowId==''){
			$.messager.alert("提示","没有选择挂号信息!");
			return false;
		}
		var TimeD=TimeRange //$(".seltimerange")[0].id.split("-")[1];
		if (AppFee!=0){AppFee="预约费:"+AppFee+"元"}else{AppFee=""}
		if (OtherFee!=0) {OtherFee=OtherFee+"元"}else{OtherFee=""}
		if (RegFee!=0){RegFee=RegFee+"元"}else{RegFee=""}
		if (Total==0){Total=""}
		var PDlime=String.fromCharCode(2);
		var MyPara="AdmNo"+PDlime+AdmNo+"^"+"PatName"+PDlime+PatName+"^"+"TransactionNo"+PDlime+TransactionNo+"^"+"AccTotal"+PDlime+AccTotal+"^"+"AccAmount"+PDlime+AccAmount+"^"+"DYOPMRN"+PDlime+DYOPMRN+"^DYIPMRN"+PDlime+DYIPMRN;
		var MyPara=MyPara+"^"+"MarkDesc"+PDlime+MarkDesc+"^"+"AdmDate"+PDlime+AdmDateStr+"^"+"SeqNo"+PDlime+SeqNo+"^RegDep"+PDlime+RegDep;
		var MyPara=MyPara+"^"+"RoomFloor"+PDlime+RoomFloor+"^"+"UserCode"+PDlime+UserCode;
		var MyPara=MyPara+"^"+"RegDateYear"+PDlime+RegDateYear+"^RegDateMonth"+PDlime+RegDateMonth+"^RegDateDay"+PDlime+RegDateDay;
		var MyPara=MyPara+"^"+"Total"+PDlime+Total+"^RegFee"+PDlime+RegFee+"^AppFee"+PDlime+AppFee+"^OtherFee"+PDlime+OtherFee+"^CardFee"+PDlime+CardFee;
		var MyPara=MyPara+"^"+"RoomNo"+PDlime+RoomNo+"^"+"ClinicGroup"+PDlime+ClinicGroup+"^"+"SessionType"+PDlime+SessionType+"^"+"TimeD"+PDlime+TimeD+"^"+"RegTime"+PDlime+RegTime+"^"+"cardnoprint"+PDlime+cardnoprint;
		var MyPara=MyPara+"^"+"ExabMemo"+PDlime+ExabMemo;
		var MyPara=MyPara+"^"+"InsuPayCash"+PDlime+InsuPayCash+"^"+"InsuPayCount"+PDlime+InsuPayCount+"^"+"InsuPayFund"+PDlime+InsuPayFund+"^"+"InsuPayOverallPlanning"+PDlime+InsuPayOverallPlanning+"^"+"InsuPayOther"+PDlime+InsuPayOther;
		var MyPara=MyPara+"^"+"ProportionNote1"+PDlime+ProportionNote1+"^"+"ProportionNote2"+PDlime+ProportionNote2;
		var MyPara=MyPara+"^"+"TotalRMBDX"+PDlime+TotalRMBDX+"^"+"INVPRTNo"+PDlime+INVPRTNo+"^"+"CardNo"+PDlime+CardNo+"^"+"Room"+PDlime+Room;
		var MyPara=MyPara+"^"+"AdmReason"+PDlime+AdmReason+"^"+"PoliticalLevel"+PDlime+PoliticalLevel;;
		var MyPara=MyPara+"^"+"PatNo"+PDlime+PatNo;       //打印登记号
		var MyPara=MyPara+"^"+"HospName"+PDlime+HospName+"^"+"paymoderstr1"+PDlime+PayModeStr1+"^"+"paymoderstr2"+PDlime+PayModeStr2;
		//var myobj=document.getElementById("ClsBillPrint");
		//PrintFun(myobj,MyPara,"");
		DHC_PrintByLodop(getLodop(),MyPara,"","","");
		$('#AccAmount').val(AccTotal);	
	} catch(e) {alert(e.message)};*/
}
//DHCPrtComm.js
function PrintFun(PObj,inpara,inlist){
	try{
		var mystr="";
		for (var i= 0; i<PrtAryData.length;i++){
			mystr=mystr + PrtAryData[i];
		}
		inpara=DHCP_TextEncoder(inpara)
		inlist=DHCP_TextEncoder(inlist)
		var docobj=new ActiveXObject("MSXML2.DOMDocument.4.0");
		docobj.async = false;   
		var rtn=docobj.loadXML(mystr);
		if (rtn){
			var rtn=PObj.ToPrintDocNew(inpara,inlist,docobj);
		}
	}catch(e){
		$.messager.alert("提示",e.message);
		return false;
	}
}
function SaveNumbleFaxed(str)
{
	var len,StrTemp;
	if((str=="")||(!str)) return 0;
	if(parseInt(str)==str){
		str=str+".00";
	}else{
		StrTemp=str.toString().split(".")[1];
		len=StrTemp.length;
		if(len==1){
			str=str+"0";
		}else{
			var myAry=str.toString().split(".");
			str=myAry[0]+"."+myAry[1].substring(0,2);
		}
	}
	return str;	
}
//挂号发票打印
function PrintInv(RegFeeID)
{   
	var UserID=session['LOGON.USERID'];
	var Return=tkMakeServerCall("web.DHCOPAdmReg","GetPrintInvInfo","InvPrintNew","INVPrtFlag2007",RegFeeID, UserID, "","");
}
function InvPrintNew(TxtInfo,ListInfo)
{   
	DHCP_GetXMLConfig("InvPrintEncrypt","INVPrtFlag2007");
	var myobj=document.getElementById("ClsBillPrint");
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
	DHC_PrintByLodop(getLodop(),TxtInfo,ListInfo,"","");
	//PrintFun(myobj,TxtInfo,ListInfo);	
}

function GetDHCOPRegConfig(NodeName){
	return $.cm({
		ClassName:"web.DHCOPRegConfig",
		MethodName:"GetSpecConfigNode",
		dataType:"text",
		NodeName:NodeName
	},false);
}
function DuplReg(ASRowId)	{
	var RepeatFlag=0;
	var Data=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
	for (var i=0;i<Data["rows"].length;i++){
		if (Data["rows"][i]["TabASRowId"]==ASRowId){
			RepeatFlag=1;
			break;
		}
	}
	if (RepeatFlag==1) return true;
	return false;
}
function AddBeforeUpdate(dataObj){
	var ASRowId=dataObj["TabASRowId"];
	if (ASRowId=="") return false;
	var PatientID=$('#PatientID').val();
	
	if (PatientID==""){
		if (ServerObj.ParaRegType!="APP"){
			$.messager.alert("提示","请先通过卡号确定患者!","info",function(){
				$('#CardNo').focus();
			});
		   	return false;
	   	}else{
            new Promise(function (resolve, reject) {
                if (dhcsys_confirm("是否选择无卡预约继续预约?")) {
					resolve(true);
				} else {
					resolve(false)
				}
            }).then(function (value) {
                if (value) {
                    if ((ServerObj.CommonCardNoStr.split("&").length)>1){
                       $('#CommonCardWin').window('open');  
                       InitCommonCardWin();
                       return false;
                    }else{
                        var PatientNomyrtn=$.cm({
                            ClassName:"web.DHCOPAdmReg",
                            MethodName:"GetCommonCardNoandPatientNo",
                            dataType:"text",
                            ChoseCommonCardNo:ServerObj.CommonCardNoStr
                        },false);
                        if (PatientNomyrtn==""){
                            $.messager.alert("提示","请维护公共卡.");                       
                            return false;
                        }else{
                            var CardNo=PatientNomyrtn.split("^")[0]
                            var PatientNo=PatientNomyrtn.split("^")[1];
                            var CardTypeNew=PatientNomyrtn.split("^")[2];
                            var PatInfoStr=$.cm({
                                ClassName : "web.DHCOPAdmReg",
                                MethodName : "GetPatDetailBroker",
                                dataType:"text",
                                itmjs:"",
                                itmjsex:"GetPatDetailToHUI",
                                val:PatientNo,
                            },false);
                            var Patdetail=PatInfoStr.split("^");
                            $("#CardNo").val(CardNo);
                            $("#CardTypeNew").val(CardTypeNew);
                            $("#Name").val(Patdetail[0]);
                            $("#Age").val(Patdetail[1]);
                            $("#Sex").val(Patdetail[2]);
                            //门诊病历号和住院病历号
                            $("#OPMRN").val(Patdetail[3]);
                            $("#IPMRN").val(Patdetail[4]);
                            //医保号
                            $("#PatYBCode").val(Patdetail[11]);
                            //医保类型
                            //$("YBType",Patdetail[12]);
                            $("#PoliticalLevel").val(Patdetail[19]);
                            $("#SecretLevel").val(Patdetail[20]);
                            $("#TelH").val(Patdetail[21]);
                            $("#PAPERCountry").val(Patdetail[22]);
                            $("#Address").val(Patdetail[23]);
                            var PatCat=Patdetail[5];
                            $("#PatCat").val(PatCat);
                            $("#PatientID").val(Patdetail[6]);
                            $("#IDCardNo").val(Patdetail[7]);
                            $("#PatientNo").val(Patdetail[9]);
                            $("#AppBreakCount").val(Patdetail[10]);
                            PatientID=Patdetail[6]
                            if (PageLogicObj.m_curDayAppListDataGrid==""){
                                PageLogicObj.m_curDayAppListDataGrid=curDayAppListDataGrid();
                            }else{
                                ClearAllTableData("curDayAppList");
                            }
                            PageLogicObj.m_selectedMarkListDataGrid=InitselectedMarkListDataGrid();
                        }
                        AddBeforeUpdateCallback(dataObj)
                    }
                } else {
                    $('#CardNo').focus();
                    return false;
                }
            })
		}
	}else{
		if (dataObj["TAPPTRowID"]==""){
			var myoptval=$.cm({
				ClassName:"web.DHCOPAdmReg",
				MethodName:"CheckPatientAppionment",
				dataType:"text",
				ASRowId:dataObj["TabASRowId"],
				PatientID:PatientID
			},false);
			if (myoptval==1){
				new Promise(function (resolve, reject) {
                    $.messager.confirm('提示', $g("患者在")+dataObj["CurrentMarkDesc"]+$g("有未取号预约记录,是否继续增加"), function (r) {
                        if (r) {
                            resolve(true);
                        } else {
                            resolve(false)
                        }
                    })
                }).then(function (value) {
                    if (!value) {
                        return false
                    }
                    AddBeforeUpdateCallback(dataObj)
                })
			}else {
				AddBeforeUpdateCallback(dataObj)
			}
		}
	}
}
function AddBeforeUpdateCallback(dataObj){
	///未选择患者，判断以下信息没有意义
	var ASRowId=dataObj["TabASRowId"];
	if (ASRowId=="") return false;
	var PatientID=$('#PatientID').val();
	if (PatientID=="") return false;
	if (DuplReg(ASRowId)){
		$.messager.alert("提示","所挂号重复,请重新选择!");
		return false;
	}
	if ((dataObj["StopRegFlag"]=="Y")&&(ServerObj.ParaRegType!="APP")) {
		$.messager.alert("提示","该号别已停止挂号！");       				
		return false;
	}
	//移至CheckBeforeReg方法中判断
	//if (!AddBeforeUpdateByASRowId(ASRowId)) return false;
	if (ServerObj.ParaRegType!="APP"){
		if (((+dataObj["AvailSeqNoStr"])==0)&&((+dataObj["AvailAddSeqNoStr"])==0)){
			$.messager.alert("提示","该号别已挂完!");       				
			return false;
		}
		/*if (dataObj["AvailSeqNoStr"]=="0"){
			$.messager.alert("提示","该号别已挂完!");       				
			return false;
		}*/
	}
	
	//添加到行记录前进行检测
	var ASRowIDStr=ASRowId
	var Data=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
	for (var j=0;j<Data["rows"].length;j++) {
		var TabASRowId=Data["rows"][j]["TabASRowId"]; 
		var TAPPTRowID=Data["rows"][j]["TAPPTRowID"];
		if (TAPPTRowID==""){
			ASRowIDStr=ASRowIDStr+"^"+TabASRowId
		} 
	}
	var SessionStr = session['LOGON.USERID'];
	    SessionStr += "^" + session['LOGON.GROUPID'];
	    SessionStr += "^" + session['LOGON.CTLOCID'];
	    SessionStr += "^" + session['LOGON.HOSPID'];
	    SessionStr += "^" + session['LOGON.WARDID'];
	    SessionStr += "^" + session['LOGON.LANGID'];
	var Rtn=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"CheckBeforeReg",
		dataType:"text",
		ResRowId:ASRowId, PatientID:PatientID, APPTRowId:"",
		CardTypeDr:$("#CardTypeRowID").val(),CardNo:$("#CardNo").val(),ASRowIdStr:ASRowIDStr,
		SessionStr:SessionStr
	},false);
	var RtnArry=Rtn.split("^")
	if (RtnArry[0]!=0){
		$.messager.alert("提示",RtnArry[1],"warning");
		return false;
	}
	//判断是否为复诊,如果是复诊价格可能会不同
	var ReAdmFeeFlag=GetReAdmFeeFlag(PatientID,ASRowId);
	dataObj["TabReAdmFeeFlag"]=ReAdmFeeFlag;
	if ((ReAdmFeeFlag==1)&&((dataObj["ReCheckFee"]!="")&&(dataObj["ReCheckFee"]!=0))){dataObj["ExamFee"]=dataObj["ReCheckFee"]}
	var MRNoteFee=0;CardFee=0;
	//是否是免挂号费或者诊查诊 界面checkbox选择?自动改变诊金金额 
	var o=$HUI.checkbox('FreeCheck');
	if(o.getValue()) {
		dataObj["ExamFee"]=0;
		dataObj["TabFreeCheckFlag"]="Y";
	}
	var o=$HUI.checkbox('FreeReg');
	if(o.getValue()) {
		dataObj["RegFee"]=0;
		dataObj["TabFreeRegFlag"]="Y";
	}
	var TotalFee=parseFloat(dataObj["HoliFee"])+parseFloat(dataObj["ExamFee"])+parseFloat(dataObj["RegFee"])+parseFloat(dataObj["AppFee"])+parseFloat(dataObj["OtherFee"])+parseFloat(MRNoteFee);
	if (TotalFee==0){
		$.messager.confirm("提示", "此号没有定义价格,你确认继续挂号吗?", function (r) {
				if (r) {
					if (ServerObj.OPRegInsertOrder=="1"){
						dataObj["HoliFee"].HoliFee=0
						dataObj["ExamFee"].ExamFee=0
						dataObj["RegFee"].RegFee=0
						dataObj["AppFee"].AppFee=0
						dataObj["OtherFee"].OtherFee=0
						TotalFee=0
						}
					TotalFee=parseFloat(TotalFee).toFixed(2); 
					dataObj["Price"]=TotalFee;
					var BillAmount=$("#BillAmount").val();
					var ToBillAmount=parseFloat((parseFloat(+BillAmount)+parseFloat(TotalFee))).toFixed(2);
					AccAmount=$('#AccAmount').val();
					//如果采用帐户支付要判断是否帐户余额足够
					var PayModeCode=GetPayModeCode();
					if (PayModeCode=="CPP") {
				 		if (ToBillAmount>parseFloat(AccAmount)) {
					   		//$.messager.alert("提示","帐户余额不足");
					   		//return false;
					   		var ret=ChangePayMode();
							if(!ret){
								return false;	
							}
				 		}
				 	} 	
					$("#BillAmount").val(ToBillAmount);
					var PayModeCode=GetPayModeCode()
					if(PayModeCode!="CPP") ReCalculateAmount();
					AddToSelectedMarkList(dataObj,true);
				} else {
					
				}
			});
		return false;
		
	}else{
		if (ServerObj.OPRegInsertOrder=="1"){
			dataObj["HoliFee"].HoliFee=0
			dataObj["ExamFee"].ExamFee=0
			dataObj["RegFee"].RegFee=0
			dataObj["AppFee"].AppFee=0
			dataObj["OtherFee"].OtherFee=0
			TotalFee=0
			}
		TotalFee=parseFloat(TotalFee).toFixed(2); 
		dataObj["Price"]=TotalFee;
		var BillAmount=$("#BillAmount").val();
		var ToBillAmount=parseFloat((parseFloat(+BillAmount)+parseFloat(TotalFee))).toFixed(2);
		AccAmount=$('#AccAmount').val();
		//如果采用帐户支付要判断是否帐户余额足够
		var PayModeCode=GetPayModeCode();
		if (PayModeCode=="CPP") {
	 		if (ToBillAmount>parseFloat(AccAmount)) {
		   		//$.messager.alert("提示","帐户余额不足");
		   		//return false;
		   		var ret=ChangePayMode();
				if(!ret){
					return false;	
				}
	 		}
	 	} 	
		$("#BillAmount").val(ToBillAmount);
		var PayModeCode=GetPayModeCode()
		if(PayModeCode!="CPP") ReCalculateAmount();
		//return dataObj;
	}
	AddToSelectedMarkList(dataObj,true);
}
function AddBeforeUpdateByASRowId(ASRowId){
	var PatientID=$('#PatientID').val();
	var myrtn=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"CheckRegDeptAgeSex",
		dataType:"text",
		ASRowId:ASRowId,
		PatientID:PatientID
	},false);
	var Flag=myrtn.split(String.fromCharCode(2))[0];
	if (Flag!="0") {
		var msg="";
		var AllowSexDesc=myrtn.split(String.fromCharCode(2))[1];
		if (AllowSexDesc!="") msg=$g("此科室支持性别")+"【"+AllowSexDesc+"】";
		var AgeRange=myrtn.split(String.fromCharCode(2))[2];
		if (AgeRange!="") {
			if (msg=="") {
				msg=$g("此科室支持年龄段")+":"+AgeRange;
			}else{
				msg=msg+","+$g("此科室支持年龄段")+"【"+AgeRange+"】";
			}
		}
		$.messager.alert("提示",$g("不允许挂此科室")+","+msg,"info");
		return false;
	}
	var myrtn=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"CheckScheduleStatus",
		dataType:"text",
		ASRowId:ASRowId
	},false);
	if (myrtn=="S") {
		$.messager.alert("提示","不允许挂此排班,该排班已停诊.");
		return false;
	}
	return true;
}
function GetReAdmFeeFlag(PatientID,ASRowId){
	var ret=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"GetReAdmFeeFlag",
		dataType:"text",
		PatientID:PatientID, ASRowId:ASRowId
	},false);
	return ret;
}
function ReCalculateAmount(){
	var BillAmount=$('#BillAmount').val();
	var GetAmount=$('#PaySum').val();
	if ((GetAmount!="")&&(GetAmount!='0.00')){
		var ReturnAmount=parseFloat(GetAmount)-BillAmount;
		var ReturnAmount=ReturnAmount.toFixed(2)
		$("#ReturnAmount").val(ReturnAmount);
		if (ReturnAmount<0){
			$("#ReturnAmount").addClass("newclsInvalid"); 
		}else{
			$("#ReturnAmount").removeClass("newclsInvalid"); 
		}
	}
}
function GetPayModeCode(){
	if (ServerObj.ParaRegType!="APP"){
		var PayModeValue=$("#PayMode").combobox("getValue");
		if (PayModeValue!="") {
			var PayModeData=$("#PayMode").combobox('getData');
			var index=$.hisui.indexOfArray(PayModeData,"CTPMRowID",PayModeValue);
			var PayModeCode= PayModeData[index].CTPMCode;
			return PayModeCode;
		}
	}
	return "";
}
function DeptListChangeHanlde(){
	var desc=$("#DeptList").lookup('getText');
	if (desc==""){
		PageLogicObj.m_deptRowId="";
		PageLogicObj.m_DocRowId="";
		DestoryPannelPopover();
		$("#SelLoc").html("");
		$("#MarkCode").lookup('setText','');
		LoadClinicServiceGroup("");
		var $card=$("div[id*='-marklist-card']");
		if ($card.length>0) $card.parent().remove();
		
		if (PageLogicObj.m_selectedMarkListDataGrid!=""){
			ClearAllTableData("selectedMarkList");
		}
		$("#BillAmount").val('');
	}
}
function LoadDeptList(){
	$("#DeptList").lookup({
        url:$URL,
        mode:'remote',
        method:"Get",
        idField:'CTCode',
        textField:'CTDesc',
        columns:[[  
            {field:'CTCode',title:'',hidden:true},
			{field:'CTDesc',title:'科室名称',width:410}
        ]], 
        pagination:true,
        panelWidth:460,
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
					$("#ClinicServiceGroup").combobox('setValue','');
					LoadMarkList();
					$("#DeptList").blur();
				}else{
					$("#ClinicServiceGroup").combobox('select',"");
					PageLogicObj.m_DocRowId="";  
					$("#MarkCode").lookup('setText','');
				}
			});
		}
    });
}
function LoadMarkCode(){
	$("#MarkCode").lookup({
        url:$URL,
        mode:'remote',
        method:"Get",
        idField:'Hidden1',
        textField:'Desc',
        columns:[[  
            {field:'Hidden1',title:'',hidden:true},
			{field:'Desc',title:'名称',width:410}
        ]], 
        pagination:true,
        panelWidth:460,
        isCombo:true,
        //minQueryLen:2,
        delay:'500',
        queryOnSameQueryString:true,
        queryParams:{ClassName: 'web.DHCRBResSession',QueryName: 'FindResDoc'},
        onBeforeLoad:function(param){
	        var desc=param['q'];
			param = $.extend(param,{DepID:PageLogicObj.m_deptRowId, Type:"", UserID:"", Group:"", MarkCodeName:desc});
	    },
	    onSelect:function(index, rec){
		    setTimeout(function(){
				if (rec!=undefined){
					PageLogicObj.m_DocRowId=rec['Hidden1'];
					LoadMarkList();
					$("#MarkCode").blur();
				}
			});
		}
    });
	/*$.cm({ 
		ClassName:"web.DHCRBResSession", 
		QueryName:"FindResDoc",
		DepID:DepID,
		Type:"",UserID:"",Group:"",MarkCodeName:"",
		rows:99999
	},function(GridData){
		var cbox = $HUI.combobox("#MarkCode", {
				valueField: 'Hidden1',
				textField: 'Desc', 
				editable:true,
				data: GridData["rows"],
				filter: function(q, row){
					q=q.toUpperCase();
					return (row["Desc"].toUpperCase().indexOf(q) >= 0)||(row["Code"].toUpperCase().indexOf(q) >= 0);
				},
				onSelect:function(rec){
					if (rec!=undefined){
						LoadMarkList();
					}
				},onChange:function(newValue,OldValue){
					if (newValue==""){
						$("#MarkCode").combobox('select',"");
						LoadMarkList();
					}
				}
		 });
	})*/
}
function LoadClinicServiceGroup(DepID){
	if(ServerObj.QryScheduleByClinicGroup=="1"){
		$.cm({ 
			ClassName:"web.DHCRBResSession", 
			QueryName:"GetClinicGroupByLocNew",
			LocRowId:DepID,
			rows:99999 
		},function(GridData){
			var cbox = $HUI.combobox("#ClinicServiceGroup", {
					valueField: 'CLGRPRowId',
					textField: 'CLGRPDesc', 
					editable:true,
					data: GridData["rows"],
					filter: function(q, row){
						q=q.toUpperCase();
						return (row["CLGRPDesc"].toUpperCase().indexOf(q) >= 0);
					},
					onSelect:function(rec){
						if (rec!=undefined){
							LoadMarkList();
						}
					},onChange:function(newValue,OldValue){
						if (newValue==""){
							$("#ClinicServiceGroup").combobox('select',"");
							LoadMarkList();
						}
					}
			 });
		})
	}else{
		$.cm({ 
			ClassName:"web.DHCRBResSession", 
			QueryName:"GetClinicServiceGroupByLocNew",
			LocRowId:DepID,
			rows:99999 
		},function(GridData){
			var cbox = $HUI.combobox("#ClinicServiceGroup", {
					valueField: 'CLSGRPRowId',
					textField: 'CLSGRPDesc', 
					editable:true,
					data: GridData["rows"],
					filter: function(q, row){
						q=q.toUpperCase();
						return (row["CLSGRPDesc"].toUpperCase().indexOf(q) >= 0);
					},
					onSelect:function(rec){
						if (rec!=undefined){
							LoadMarkList();
						}
					},onChange:function(newValue,OldValue){
						if (newValue==""){
							$("#ClinicServiceGroup").combobox('select',"");
							LoadMarkList();
						}
					}
			 });
		})
	}
}
function SearchAppNoClickHandler(){
	setTimeout(function(){SearchAppNoChange();});
}
function SearchAppNoChange(){
	var o=$HUI.checkbox("#SearchAppNo");
	if (o.getValue()){
		var AppSerialNo=$("#AppSerialNo").val();
		if (AppSerialNo!=""){
			AppSerialNoBlurHandler();
		}else{
			var PatientID=$("#PatientID").val();
			if (PatientID!="") {
				GetApptInfo(PatientID);
			}
		}
	}else{
		ClearAllTableData("selectedMarkList");
	}
}
function AppSerialNoBlurHandler(e){
	//得到无卡预约记录
	GetApptInfo("");
	return true;
}
function GetApptInfo(PatientID){
	var o=$HUI.checkbox("#SearchAppNo");
	if ((o.getValue())||(ServerObj.ParaRegType=="APP")){
		if (ServerObj.ParaRegType=="APP"){
			if (PageLogicObj.m_curDayAppListDataGrid==""){
				PageLogicObj.m_curDayAppListDataGrid=curDayAppListDataGrid();
			}else{
				ClearAllTableData("curDayAppList");
			}
		}/*else{
			if (PageLogicObj.m_curDayRegListDataGrid===""){
				PageLogicObj.m_curDayRegListDataGrid=curDayRegListDataGrid();
			}else{
				ClearAllTableData("curDayRegList");
			}
		}*/
		//取病人的预约信息
		$("#BillAmount").val("0.00")
		var AdmReason=$('#BillType').combobox('getValue');
		var GetAppFlag=1;
		var rtn="";
		ClearAllTableData("selectedMarkList");
		var BillAmount=+$("#BillAmount").val();
		var RegConDisId="";
		if(ServerObj.ParaRegType!="APP"){
			RegConDisId=$("#RegConDisList").combobox("getValue");
		}
		if (PatientID=="") {
			var AppSerialNo=$("#AppSerialNo").val();
			var rtn=$.cm({
			    ClassName : "web.DHCRBAppointment",
			    MethodName : "GetAppInfoNoCard",
			    dataType:"text",
			    SystemSess:AppSerialNo, AdmReason:AdmReason,
			    LogonHospID:session['LOGON.HOSPID'],RegConDisId:RegConDisId,
			},false);
		}else{
			var rtn=$.cm({
			    ClassName : "web.DHCRBAppointment",
			    MethodName : "GetAppInfo",
			    dataType:"text",
			    PatientId:PatientID, AdmReason:AdmReason, LogonHospID:session['LOGON.HOSPID'],
			    RegConDisId:RegConDisId,RegType:ServerObj.ParaRegType
			},false);
		}
		if(rtn!=""){
		   //没有权限提示科室和医生信息
		    if(rtn.indexOf("NoAuthority")!=-1){
			  var tipSplit=rtn.split("NoAuthority");
			  if(tipSplit.length==2){
				  var tip=rtn.split("NoAuthority")[1];
				  if(tip=="CheckCardAssociation"){
					 $.messager.alert("提示","请患者出示社保卡，否则本次就诊费用无法医保结算!");
				  }else{
					$.messager.alert("提示","没有取号权限:"+tip);
				  }
				  rtn=rtn.split("NoAuthority")[0];
			  }
			  if(tipSplit.length==3){
				  var tip=rtn.split("NoAuthority")[1];
				  $.messager.alert("提示","没有取号权限:"+tip);
				  //alert("请患者出示社保卡，否则本次就诊费用无法医保结算");
				  rtn=rtn.split("NoAuthority")[0];
			  }
			}
			if(rtn){
				var AppInfos=rtn.split(",")
				for(var i=0;i<AppInfos.length;i++){
					var AppInfo=AppInfos[i]
					var AppInfo1=AppInfo.split("^")
					var BillAmount=parseFloat(BillAmount)+parseFloat(AppInfo1[2]);
					var TAPPTRowID="";
					if (AppInfo1.length>=15){
						TAPPTRowID=AppInfo1[14];
					}
					if(ServerObj.ParaRegType!="APP"){
						var RepeatFlag=CheckRowDataRepeat("TAPPTRowID",TAPPTRowID);
						if (RepeatFlag==1) continue;
					}else{
						var RepeatFlag=CheckAppRowDataRepeat("TAPPTRowID",TAPPTRowID);
						if (RepeatFlag==1) continue;
					}
					AddRegToTable(AppInfo);
				}
			}
			$("#BillAmount").val(BillAmount);
		}
	}
}
function AddRegToTable(val) {
	try {
		var valueAry=val.split("^");
		var TabASRowId=valueAry[0];
		var TabMarkDesc=valueAry[1];
		var TabPrice=valueAry[2];
		var TabExamFee=valueAry[3];
		var TabHoliFee=valueAry[4];
		var TabAppFee=valueAry[5];
		var TabDepDesc=valueAry[6];
		var TabAppDate=valueAry[7];
		var TabSeqNo=valueAry[8];
		var TabReAdmFeeFlag=valueAry[9];
        //界面选择复诊或义诊  +20100629  guo
		var TabFreeRegFlag=valueAry[10];
		var TabFreeCheckFlag=valueAry[11];
		var TabTimeRange=valueAry[12];
		var TAPPTRowID=""
		if (valueAry.length>=15){
			TAPPTRowID=valueAry[14];
		}
		var PCLRowID=""
		if (valueAry.length>=16){
			PCLRowID=valueAry[15];
		}
		var TabClinicGroupDr=valueAry[16];
		var TabClinicGroupDesc=valueAry[17];
		var dataObj=new Object();
		dataObj={
			TabASRowId:TabASRowId,
			DeptDesc:TabDepDesc,
			MarkDesc:TabMarkDesc,
			SeqNo:TabSeqNo,
			Price:TabPrice,
			AdmDate:TabAppDate,
			DeptRowId:"",
			TabPCLRowID:PCLRowID,
			TAPPTRowID:TAPPTRowID,
			AvailSeqNoStr:"",
			AvailAddSeqNoStr:"",
			HoliFee:TabHoliFee,
			ExamFee:TabExamFee,
			RegFee:"",
			AppFee:TabAppFee,
			OtherFee:"",
			ReCheckFee:"",
			TabFreeRegFlag:TabFreeRegFlag,
			TabFreeCheckFlag:TabFreeCheckFlag,
			TabReAdmFeeFlag:TabReAdmFeeFlag,
			TabTimeRange:TabTimeRange,
			TabClinicGroupDesc:TabClinicGroupDesc,
			TabClinicGroupDr:TabClinicGroupDr
		}
		if (ServerObj.OPRegInsertOrder=="1"){
			dataObj["Price"]=0
			dataObj["HoliFee"]=0
			dataObj["ExamFee"]=0
			dataObj["RegFee"]=0
			dataObj["AppFee"]=0
			dataObj["OtherFee"]=0
		}
		AddToSelectedMarkList(dataObj,false);
	} catch(e) {$.messager.alert("提示",e.message)};
}
function CheckRowDataRepeat(CellName,ChecKValue) {
	var RepeatFlag=0;
	if (ChecKValue=="") return RepeatFlag;
	//判断重复情况不增加
	var Data=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
	for (var i = 0; i < Data["rows"].length; i++) { 
		var CellNameVal=Data["rows"][i][CellName];
		if (CellNameVal=="") continue;
		if (CellNameVal==ChecKValue) {
			RepeatFlag=1;
			break;
		}
	}
	return RepeatFlag;
}
function CheckAppRowDataRepeat(CellName,ChecKValue){
	var RepeatFlag=0;
	if (ChecKValue=="") return RepeatFlag;
	//判断重复情况不增加
	var Data=PageLogicObj.m_curDayAppListDataGrid.datagrid("getData");
	for (var i = 0; i < Data["rows"].length; i++) { 
		var CellNameVal=Data["rows"][i][CellName];
		if (CellNameVal=="") continue;
		if (CellNameVal==ChecKValue) RepeatFlag=1;break;
	}
	return RepeatFlag;
}
function AppDateonSelect(date){
	date=myformatter(date);
	AppDateChange(date);
}
function AppDateChange(date){
	$("#SelDate").html(date);
	if ((ServerObj.ParaRegType !="APP")){
		if (date !=ServerObj.CurDate) {
			$("#WeekDesc").prev().html($g("预约日期") + " : ");
		}else{
			$("#WeekDesc").prev().html($g("今天是") + " : ");
		}
	}
	$.cm({
		ClassName:"web.DHCOPAdmReg", 
		MethodName:"ConvertToWeek",
		dataType:"text",
		DateStr:date
	},function(Week){
		$("#WeekDesc").html($g(Week));
	})
	LoadMarkList();
}
function PreAppDayClickHandler(){
	var date=$("#AppDate").datebox('getValue');
	var date=addDay(-1,myparser(date));
	date=myformatter(date);
	$("#AppDate").datebox('setValue',date);
	AppDateChange(date);
}
function NextAppDayClickHandler(){
	var date=$("#AppDate").datebox('getValue');
	var date=addDay(1,myparser(date));
	date=myformatter(date);
	$("#AppDate").datebox('setValue',date);
	AppDateChange(date);
}
function AllAppDaysClickHandler(){
	LoadMarkList(0);
}
function ChangeWeekAppDayClickHandler(Type){
	var date=$("#AppDate").datebox('getValue');
	$.cm({
		ClassName:"web.DHCOPAdmReg", 
		MethodName:"GetnextWeekDate",
		dataType:"text",
		AppDate:date,
		Type:Type
	},function(Str){
		var NowDate=Str.split("^")[0]
		$("#AppDate").datebox('setValue',NowDate);
		$("#SelDate").html(NowDate);
		var strdate=Str.split("^")[1]+"||"+Str.split("^")[2];
		LoadMarkList(NowDate);
	})
}
function addDay(dayNumber, date) {
    date = date ? date : new Date();
    var ms = dayNumber * (1000 * 60 * 60 * 24)
    var newDate = new Date(date.getTime() + ms);
    return newDate;
}
function DeptTreeListClickHandle(){
	//$("#DeptList").lookup('hidePanel');
	if ($("#DeptTreeList-div").css("display")=="none"){
		$("#SearhDeptTree").searchbox('setValue','');
		$("#DeptTreeList-div").show();
		$('#SearhDeptTree').next('span').find('input').focus();
		$.cm({ 
			ClassName:"web.DHCOPAdmReg", 
			MethodName:"GetDeptTreeList"
		},function(Data){
			var tree=$("#DeptTree").tree({
				lines:true,
				multiple:false,
				data:Data,
				onSelect:function(node){
					if ($(this).tree('isLeaf', node.target)){
						PageLogicObj.m_deptRowId=node["id"];
						$("#SelLoc").html(node['text']);
						$("#DeptList").lookup('setText',node['text']);
						$("#DeptTreeList-div").hide();
						PageLogicObj.m_DocRowId="";  
						$("#MarkCode").lookup('setText','');
						$("#ClinicServiceGroup").combobox('setValue','');
						LoadClinicServiceGroup(PageLogicObj.m_deptRowId);
						LoadMarkList();
					}

				}
			})
		})
	}else{
		return false;
	}
}
function SearchDeptTree(value,name){
	value=value.toUpperCase();
	var roots=$HUI.tree("#DeptTree").getRoots();
	for (var i=0;i<roots.length;i++){
		var id=roots[i]["id"];
		var text=roots[i]["text"].toUpperCase();
		var code=roots[i]["attributes"]["code"].toUpperCase();
		var rootNode=$('#DeptTree').tree('find', id);
		var chiddata=roots[i]["children"];
		var childFindFlag=0;
		for (var j=0;j<chiddata.length;j++){
			var childid=chiddata[j]["id"];
			var childText=chiddata[j]["text"].toUpperCase();
			var childCode=chiddata[j]["attributes"]["code"].toUpperCase();
			var childNode=$('#DeptTree').tree('find', childid);
			if ((childCode.indexOf(value)>=0)||(childText.indexOf(value)>=0)){
				childFindFlag=1;
				$(childNode.target).show();
			}else{
				$(childNode.target).hide();
			}
		}
		if ((code.indexOf(value)>=0)||(text.indexOf(value)>=0)){
			$(rootNode.target).show();
		}else{
			if (childFindFlag==0){
				$(rootNode.target).hide();
			}else{
				$(rootNode.target).show();
			}
		}
	}
}
function MarkListShowModeClickHandle(e){
	DestoryPannelPopover()
	$("#MarkListShowMode").blur();
	//切换视图模式时html会清空，需重现初始化表格
	PageLogicObj.m_MarkListDataGrid="";
	var $btntext=$("#MarkListShowMode .l-btn-text")[0];
	var text=$btntext.innerText;
	if (text.indexOf($g("视图"))>=0){
		$btntext.innerText=$g("列表模式");
		var url="opadm.reg.markcard.hui.csp";
		$("#MarkListPanel").removeClass('panel-noscroll');
	}else{
		$btntext.innerText=$g("视图模式");
		var url="opadm.reg.marktable.hui.csp";
	}
    url=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(url):url;
	$.ajax(url, {
		"type" : "GET",
		"async" : false,
		"dataType" : "html",
		"success" : function(data, textStatus) {
			$("#MarkListPanel").empty().append(data);
		}
	});
	LoadMarkList();
}
function LoadMarkList(AppDate){
	var DepRowId=GetDeptRowId();
	if (typeof AppDate =="undefined"){
		var AppDate=$('#AppDate').datebox('getValue');
	}
	
	var PatientID=$("#PatientID").val();
	var TimeRangeRowId=$(".seltimerange")[0].id.split("-")[0];
	if (TimeRangeRowId=="ALL") TimeRangeRowId="";
	var DocRowId=PageLogicObj.m_DocRowId; //$("#MarkCode").combobox("getValue");
	if ($("#MarkCode").lookup("getText")==""){
		PageLogicObj.m_DocRowId="";
		DocRowId="";
	}
	//if (DocRowId==undefined) DocRowId="";
	var ClinicServiceGroupRowId=$("#ClinicServiceGroup").combobox('getValue') //亚专业
	if (ClinicServiceGroupRowId==undefined) ClinicServiceGroupRowId="";
	var ShowStopScheFlag=""; //包含已停诊
	var RegConDisId="";
	if(ServerObj.ParaRegType!="APP"){
		if (AppDate) {
			if (!CheckOrderStartDate(AppDate,ServerObj.CurDate)){
				$.messager.alert("提示","预约日期应该大于等于本日!","info",function(){
					$('#AppDate').next('span').find('input').focus();
				});
				return false;
			}
		}
		var o=$HUI.checkbox("#ShowStopSche");
		if (o.getValue()){
			ShowStopScheFlag=1;
		}
		RegConDisId=$("#RegConDisList").combobox("getValue");
		if (!RegConDisId) RegConDisId="";
	}else{
		if (AppDate=="") {
			AppDate="0";
		}else{
			if (!CheckOrderStartDate(AppDate,ServerObj.DefaultAppDate)){
				$.messager.alert("提示","预约日期应该大于本日!","info",function(){
					SetDefaultAppDate();
					//$('#AppDate').datebox();
				});
				return false;
			}
		}
	}
	var AdmReason=$("#BillType").combobox('getValue');
	var p1=DepRowId+"^"+session['LOGON.USERID']+"^"+AppDate+"^"+PatientID+"^"+TimeRangeRowId+"^"+DocRowId+"^"+session['LOGON.GROUPID']+"^"+AdmReason+"^^"+TimeRangeRowId+"^"+ClinicServiceGroupRowId+"^"+ShowStopScheFlag+"^"+RegConDisId+"^"+session['LOGON.HOSPID'];
	$.cm({
		ClassName:"web.DHCOPAdmReg", 
		QueryName:"OPDocList",
		Dept:p1,
		rows:99999
	},function(GridData){
		$("#MarkListPanel").removeClass('marklist-card-panel');
		DestoryPannelPopover();
		var $btntext=$("#MarkListShowMode .l-btn-text")[0];
		var text=$btntext.innerText;
		if (text.indexOf($g("视图"))>=0){
			if (PageLogicObj.m_MarkListDataGrid==""){
				PageLogicObj.m_MarkListDataGrid=MarkListDataGrid();
			}
			LoadMarkListTabData(GridData);
		}else{
			$("#MarkListPanel").addClass('marklist-card-panel');
			var $card=$("div[id*='-marklist-card']");
			if ($card.length>0) $card.parent().remove();
			LoadMarkListCardData(GridData);
		}
	})
}
function LoadMarkListCardData(GridData){
	var colorIndex=1,timeRangeDesc="";
	var templ=$("#marklist-card-temp");
	var panel=$("#MarkListPanel");
	for(var i=0,len=GridData["total"];i<len;++i){
	    var oneData=GridData["rows"][i];
	    if (oneData["ASRowId"]=="") continue;
		var tool=templ.clone();
		 tool.removeAttr("style");
		 tool.removeAttr("id");
		 var id=i+"-marklist-card"
		 tool.attr("id",id);
		 panel.append(tool);
		 $($(tool).find("div")[0]).html(oneData["MarkDesc"]+"("+oneData["SessionTypeDesc"]+")");
		 $($(tool).find("div")[1]).html(oneData["ScheduleStatus"]+" "+oneData["ScheduleDate"]);
		 var TotalFee=parseFloat(oneData["HoliFee"])+parseFloat(oneData["ExamFee"])+parseFloat(oneData["RegFee"])+parseFloat(oneData["AppFee"])+parseFloat(oneData["AppFeeDr"]);
		 $($(tool).find("div")[2]).html(oneData["ClinicGroupDesc"]+" "+TotalFee+$g("元")); //
		 $($(tool).find("div")[4]).html(+oneData["RegedCount"]); //已挂号数
		 $($(tool).find("div")[5]).html(+oneData["AppedCount"]); //已预约数
		 $($(tool).find("div")[6]).html(+oneData["AppedArriveCount"]); //已取号数
		 $($(tool).find("div")[7]).html(+oneData["AddedCount"]); //加号数
		 $($(tool).find("div")[8]).html(JSON.stringify(oneData));
		 if ((i>=1)&&(oneData["TimeRange"]!=GridData["rows"][i-1]["TimeRange"])){
			 colorIndex=colorIndex+1;
			 if (colorIndex>4) colorIndex=1;
		 }
		 $($(tool).find("span")[0]).addClass("timerange-span-solid-"+colorIndex);
		 $($(tool).find("span")[1]).html(oneData["TimeRange"]).addClass("timerange-span-dotted-"+colorIndex);
		 if (i==0){
			(function (id) {
				$("#"+id).addClass("markcard-select");
				setTimeout(function(){
					SetMarkCardFocus(id);
				});
			})(id);
		 }
		/*
		字体规则
		医生字体绿色 			便捷排班
		医生字体黑色 			正常排班
		医生字体红色、斜体 		正常排班且号已挂完
		卡片背景色红色 			已停诊
		*/
		var className="marklist-card";
		if(oneData["NoLimitLoadFlag"]=="Y"){
			className="marklist-card-fastsche";
			if ((+oneData["AvailSeqNoStr"]==0)&&(+oneData["AvailAddSeqNoStr"]==0)&&(ServerObj.SeqNoMode=='')){
				className="marklist-card-invalid";
			}
		}else{
			if ((+oneData["AvailSeqNoStr"]==0)&&(+oneData["AvailAddSeqNoStr"]==0)&&(ServerObj.SeqNoMode=='')){
				className="marklist-card-invalid";
			}
		}
		if (oneData["ScheduleStatus"]=="停诊"){
			className="marklist-card-stop";
		}
		var valbox = $HUI.panel("#"+id,{
			width:200,
			height:137,
			//style:{"border":"1px solid red"},
			bodyCls:className,
			noheader:true
		});
	}
	
	var $card=$("div[id*='-marklist-card']");
	$card.mouseenter(function(e){
		var id=e.currentTarget.id;
		$(".markcard-hover").removeClass("markcard-hover");
		$("#"+id).addClass("markcard-hover");
		if (PageLogicObj.m_MarkPopoverTrigger=="hover"){
			DestoryPannelPopover();
			try{
				InitMarkListRowPopover({rowIndex:"",markCardID:id,Show:true})
			}catch(e){}
		}
	}).mouseleave(function(e){
		$(".markcard-hover").removeClass("markcard-hover");
	}).dblclick(function(e){
		var id=e.currentTarget.id;
		var dataStr=$($("#"+id).find("div")[8]).html();
		var jsonData=JSON.parse(dataStr);
		MarkListDBClick(jsonData);
	}).click(function(e){
		var id=e.currentTarget.id;
		$(".markcard-select").removeClass("markcard-select");
		$("#"+id).addClass("markcard-select");
		SetMarkCardFocus(id);
	})
	if (PageLogicObj.m_MouseoverId != "") {
		// 切换 popover switch 按钮时，手动触发 mouseover
		$("#" + PageLogicObj.m_MouseoverId).mouseover()
	}
}
///获取动态写入的HTML代码
function GetPannelHTML(jsonData,LinkID){
	var Len=0;
	if ((ServerObj.ParaRegType=="APP")||(ServerObj.OPRegistShowTimeRange=="1")){
		var ASRowId=jsonData["ASRowId"];
		var ClinicGroupDr=jsonData["ClinicGroupDr"];
		var width=628,height=250;
		var CallFunction={};
		var innerHTML="<table border='1' class='diytable' cellspacing='1' cellpadding='0'>";
		var Title = "<font style='font-weight:bold'>" + jsonData["MarkDesc"] + "(" + jsonData['SessionTypeDesc'] + ") " + jsonData["TimeRange"] + "</font>"
		Title = Title + "<font style='margin-left:10px;'>"+ $g("挂号") +": " + jsonData['RegedCount'] + "</font><font style='margin-left:10px;'>"+ $g("预约") +": " + jsonData['AppedCount'] + "</font><font style='margin-left:10px;'>"+ $g("取号") +": " + jsonData['AppedArriveCount'] + "</font><font style='margin-left:10px;'>"+ $g("加号") +": " + jsonData['AddedCount'] + "</font>"
		var RegType="APP"
		if (ServerObj.ParaRegType != "APP") { RegType="NOR" }
		var curtDate = new Date()
		var schdDate = new Date(jsonData["ScheduleDate"])
		if (schdDate > curtDate) { RegType = "APP" }
		if (RegType=="APP") {
			Title = Title + "<font style='margin-left:10px;'>"+ $g("可预约") +": " + jsonData["AvailSeqNoStr"] + "</font>"
		} else {
			Title = Title + "<font style='margin-left:10px;'>"+ $g("剩号") +": " + jsonData["AvailSeqNoStr"] + "</font>"
		}
		//预约挂号界面都显示当前待诊人数
		Title = Title + "<font style='margin-left:10px;'>"+ $g("当前待诊") +": " + jsonData['AdmWaitSum'] + "</font>"
		var warning = $.cm({
			ClassName:"web.DHCOPAdmReg",
			MethodName:"GetTimeRangeStrApp",
		    ASRowid:ASRowId,
		    AppMedthod:"WIN",
		    RegType :RegType,
			TRShowFlag: PageLogicObj.m_TrShowFlag,
			ClinicGroupDr:ClinicGroupDr,
			dataType:"text"
		},false);
		warning=eval('(' + warning + ')');
		// 最大5列适配现有宽度
		var MaxRow = 5; MaxCol = 5; colNum = 0; colCnt = 0;
		Len = warning['row'].length;
		if (Math.ceil(Len / MaxRow) > MaxCol) {
			colCnt = Math.ceil(Len / MaxRow)
		} else {
			colCnt = MaxCol
		}
		var col = warning['row']
		for (var j = 0; j < Len; j++) {
			if (j % colCnt == 0) {
				innerHTML = innerHTML + "<tr>";
			}
			var SeqNo = col[j]['SeqNo'];
			var Time = col[j]['Time'];
			var Status = col[j]['Status'];
			if (Status == 0) {
				innerHTML = innerHTML + "<td class='td-seqno-invalid'>" + "<span class='td-seqno'>"+ $g("可用") + ":" + $g("无") + "</span><br><span class='td-time'>" + Time + "</span></td>";
			} else {
				innerHTML = innerHTML + "<td onmouseover=mouserover(this) onmouseout=mouserout(this) onclick=tdclick(this) ondblclick=dbtdclick(this) id='" + LinkID + "_table_" + Time + "'>" + "<span class='td-seqno'>"+ $g("可用") + ":" + $g("有") + "</span><br><span class='td-time'>" + Time + "</span></td>";
			}
			innerHTML = innerHTML + "</td>";
			colNum = colNum + 1;
			if (colNum == colCnt) {
				innerHTML = innerHTML + "</tr>";
				colNum = 0;
			}
		}
		if (colNum != 0) innerHTML = innerHTML + "</tr>";
		innerHTML = innerHTML + "</table>";
		if (Len == 0) {
			innerHTML = "";
		}
		// 超过5列调整宽度
		if (colCnt > MaxCol) {
			var ShowMaxCol=8 ///视图模式超过8个就展示不下了
			var text=$("#MarkListShowMode .l-btn-text")[0].innerText;
			if (text.indexOf($g("视图"))>=0){
				///列表模式超过6个就展示不下了
				ShowMaxCol=6
			}
			if (colCnt>=ShowMaxCol){
				width = width + ((ShowMaxCol - MaxCol) * 121)
			}else {
				
				width = width + ((colCnt - MaxCol) * 121)
			}
		}
		var closeable=true
	}
	if ((Len==0)||((ServerObj.ParaRegType!="APP")&&(ServerObj.OPRegistShowTimeRange!="1"))){
		var Title="";
        var innerHTML = ""
		if (ServerObj.OPRegSchedTipPopover == "1") {
            innerHTML="<table border='1' class='diytable' cellspacing='1' cellpadding='0'>";
            innerHTML=innerHTML+"<tr><td style='width:70px'>"+ $g("挂号数") +"</td><td style='width:55px'>"+jsonData['RegedCount']+"</td></tr>";
            innerHTML=innerHTML+"<tr><td>"+ $g("预约数") +"</td><td>"+jsonData['AppedCount']+"</td></tr>";
            innerHTML=innerHTML+"<tr><td>"+ $g("取号数") +"</td><td>"+jsonData['AppedArriveCount']+"</td></tr>";
            innerHTML=innerHTML+"<tr><td>"+ $g("加号数") +"</td><td>"+jsonData['AddedCount']+"</td></tr>"; 
            innerHTML=innerHTML+"<tr><td>"+ $g("当前待诊人数") +"</td><td>"+jsonData['AdmWaitSum']+"</td></tr>";
        }
		var width=180,height=151;
		var CallFunction="";
		var closeable=false;
	}
	// 创建 switchbox
	if (Title != "") {
		Title = "<span>" + Title + "</span>"
		Title += "<div id=\"switch-btn\" class=\"hisui-switchbox hisui-tooltip\""
		Title += 		"style=\"float:right;margin-left:5px;margin-right:5px;padding:0.5px 0px;\""
		Title += 		'title="可用不显示无号时段"'
		Title += 		"data-options=\"onText:'" + $g("全部") + "',offText:'" + $g("可用") + "',size:'mini',animated:true,"
		if (PageLogicObj.m_TrShowFlag == 1) {
			Title += "checked:true,"
		} else {
			Title += "checked:false,"
		}
		Title += 			"onClass:'primary',offClass:'success'," //position:'right',
		// Title +=			"onSwitchChange:function(event,obj){"
		// Title +=			"	if (obj.value) {"
		// Title +=			"		PageLogicObj.m_TrShowFlag = 1;"
		// Title +=			"	} else {"
		// Title +=			"		PageLogicObj.m_TrShowFlag = 0;"
		// Title +=			"	}"
		// Title +=			"	LoadMarkList() "
		// Title +=			"}"

		var RowIndex="",markCardID="";
		var text=$("#MarkListShowMode .l-btn-text")[0].innerText;
		if (text.indexOf($g("视图"))>=0){
			RowIndex=PageLogicObj.m_MarkListDataGrid.datagrid('getRowIndex',jsonData);
		}else{
			markCardID=LinkID;
		}
		//var param={rowIndex:RowIndex,markCardID:markCardID};
		
		Title +=			"onSwitchChange:(function(param){"
		Title +=			"	return function(event,obj){"
		Title +=			"		if (obj.value) {"
		Title +=			"			PageLogicObj.m_TrShowFlag = 1;"
		Title +=			"		} else {"
		Title +=			"			PageLogicObj.m_TrShowFlag = 0;"
		Title +=			"		}"
		Title +=			"		DestoryPannelPopover();"
		Title +=			"		InitMarkListRowPopover(param);"
		Title +=			"	}"
		Title +=			"})({rowIndex:'"+RowIndex+"',markCardID:'"+markCardID+"',Show:true})"
		Title +=			"\">"
		Title += "</div>"
		Title += "<div style=\"clear:both;\"></div>"
	}
	return {
		"innerHTML":innerHTML,
		"CallFunction":CallFunction,
		"Title":Title,
		"width":width,
		"height":height,
		"closeable":closeable
	}
}
function mouserover(){
}
function mouserout(){
}
function tdclick(){
}
function dbtdclick(obj){
	var id=obj.id;
	var $btntext=$("#MarkListShowMode .l-btn-text")[0];
	var MarkCardID=id.split("_table_")[0];
	var text=$btntext.innerText;
	if (text.indexOf($g("视图"))>=0){
		var tabTRId=id.split("_table_")[0];
		var index=tabTRId.split("-")[tabTRId.split("-").length-1];
		var jsonData=$.extend({},$("#MarkList").datagrid('getRows')[index]);
		var Time=id.split("_table_")[1];
		jsonData['TimeRange']=Time;
	}else{
		//var SeqNo=id.split("_table_")[1];
		var dataStr=$($("#"+MarkCardID).find("div")[8]).html();
		var jsonData=JSON.parse(dataStr);
		var Time=id.split("_table_")[1];
		jsonData['TimeRange']=Time;
	}
	//jsonData['SeqNo']=SeqNo;
	MarkListDBClick(jsonData);
	$("#"+MarkCardID).popover('hide');
}
function SetMarkCardFocus(id){
	//$("#"+id).panel().focus();
	DestoryPannelPopover();
	$("#"+id).parent().focus();
	if (ServerObj.ParaRegType=="APP"){
		var MarkCardID=id.split("_table_")[0];
		var dataStr=$($("#"+MarkCardID).find("div")[8]).html();
		var jsonData=JSON.parse(dataStr);
		$("#SelDate").html(jsonData.ScheduleDate);
		$("#WeekDesc").html($g(jsonData.ScheduleDateWeek));
	}
	InitMarkListRowPopover({rowIndex:"",markCardID:id,Show:true});
}
function LoadMarkListTabData(GridData){
	PageLogicObj.m_MarkListDataGrid.datagrid('uncheckAll');
	if ((GridData["total"]==1)&&(GridData["rows"][0]["ASRowId"]=="")){
		PageLogicObj.m_MarkListDataGrid.datagrid('loadData', {"total":0,"rows":[]});
	}else{
		PageLogicObj.m_MarkListDataGrid.datagrid('loadData',GridData);
	}
	// DTS埋点门诊-选择日期
	var PatientID=$("#PatientID").val();
	if (PatientID!=""){
		DTSLog.AddOnelog("1634038234952634368",PatientID,PatientID,"",session['LOGON.USERCODE'])
	}
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
				editable:false,
				data: Data.rows
		 });
	});
}
function InitAppPatType(){
	var Patdata=[{"id":"1","text":$g("本人")},{"id":"2","text":$g("父母或子女")},{"id":"3","text":$g("其他关系")}]
	var cbox = $HUI.combobox("#AppPatType", {
				valueField: 'id',
				textField: 'text', 
				editable:false,
				data: Patdata,
				onLoadSuccess:function(data){
					$HUI.combobox("#AppPatType").setValue(1);
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
		var cbox = $HUI.combobox("#RegConDisList", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				data: JSON.parse(Data),
				onSelect:function(rec){
					if (rec!=undefined){
						if (PageLogicObj.m_selectedMarkListDataGrid!=""){
							RefreshSelMarkFee();
							LoadMarkList();
							MedicalBookChange()
						}
					}
				},
				onChange:function(newValue,OldValue){
					if (newValue==""){
						$("#RegConDisList").combobox('select',"");
						if (PageLogicObj.m_selectedMarkListDataGrid!=""){
							RefreshSelMarkFee();
							LoadMarkList();
							MedicalBookChange();
						}
					}
				}
		 });
	});
}
function BRegExpClickHandle(PatientNo){
	if (typeof PatientNo ==undefined){PatientNo="";}
	if ((PatientNo=="undefined")||(PatientNo==undefined)) {PatientNo="";}
	var src="reg.cardreg.hui.csp?PatientNoReg="+PatientNo;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("CardReg","建卡", PageLogicObj.dw+180, PageLogicObj.dh+80,"icon-w-edit","",$code,"");
}
function BCardRechargeHandle(){
	var src="dhcbill.opbill.accdep.pay.csp";
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Project","预交金充值", PageLogicObj.dw, PageLogicObj.dh,"icon-w-inv","",$code,"");
}
function BCacelRegHandle(EpisodeID){
	if (typeof EpisodeID == "undefined"){EpisodeID="";}
	var CardNo=$("#CardNo").val()
    var RegNo=$("#PatientNo").val()
	var src="opadm.return.hui.csp?EpisodeID="+EpisodeID+"&PageFrom=Reg&CardNo="+CardNo+"&RegNo="+RegNo;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Project","退号", 1250, 620,"icon-w-back","",$code,"");
}
function BCacelAppHandle(){
	var CardNo=$("#CardNo").val()
	var src="opadm.appcancel.hui.csp?PageFrom=Reg&CardNo="+CardNo;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Project","取消预约", 1350, 650,"icon-w-back","",$code,"");
}
function BUpdatePatInfoHandle(){
	var src="doc.patientinfoupdate.hui.csp";   
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Project","修改患者信息", PageLogicObj.dw+200, PageLogicObj.dh,"icon-w-edit","",$code,"");
}
function BFindPatHandle(){
	var src="reg.cardsearchquery.hui.csp"; 
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("FindPatReg","患者查询", PageLogicObj.dw, PageLogicObj.dh,"icon-w-find","",$code,"");
}
function ClearAllTableData(id){
	var Data=$("#"+id).datagrid("getData");
	for (var i=Data["rows"].length-1;i>=0;i--){
		$("#"+id).datagrid('deleteRow',i);
	} 
}
function BClearHandle(){
	ClearPatInfo();
	SetDefaultTimeRange();
	$('#AppPatType').combobox('select',1);
	$("#SearhDeptTree").searchbox('setValue','');
	$("#DeptTreeList-div").hide();
	$(".newclsInvalid").removeClass('newclsInvalid');
	$("#WeekDesc,#SelLoc").html("");
	
	$("#MedicalBook,#ShowStopSche").checkbox('setValue',false); 
	$("#SearchAppNo").checkbox('setValue',true); 
	$('#CardNo,#DeptList').val("");
	PageLogicObj.m_PreCardNo="";
	PageLogicObj.m_PreCardType="";
	PageLogicObj.m_PreCardLeaving="";
	PageLogicObj.m_DocRowId="";  
	PageLogicObj.m_deptRowId=""; 
	$("#RegConDisList,#ClinicServiceGroupRowId").combobox('select',"");
	$("#MarkCode").lookup('setText','');
	var o=$HUI.checkbox("#FreeReg,#FreeCheck,#MedicalBook").setValue(false);
	if(ServerObj.ParaRegType!="APP"){
		$("#BillType").combobox('select',"");
		$("#BillType").combobox("loadData",[])
		$("#AppDate").datebox("setValue","");
		$("#SelDate").html(ServerObj.CurDate);
		$("#WeekDesc").html($g(ServerObj.CurWeek));
		$("#WeekDesc").prev().html($g("今天是") + " : ");
		if (PageLogicObj.m_curDayRegListDataGrid!=""){
			ClearAllTableData("curDayRegList");
		}
		GetReceiptNo();
		LoadPayMode();
		InitReceiptCount();
		$("#AccAmount").val("");
	}else{
		$("#AppDate").datebox("setValue",ServerObj.DefaultAppDate);
		$("#WeekDesc").html($g(ServerObj.DefaultAppWeek));
		if (PageLogicObj.m_curDayAppListDataGrid!=""){
			ClearAllTableData("curDayAppList");
		}
		LoadCredType();
	}
	if (PageLogicObj.m_selectedMarkListDataGrid!=""){
		ClearAllTableData("selectedMarkList");
	}
	var $btntext=$("#MarkListShowMode .l-btn-text")[0];
	var text=$btntext.innerText;
	DestoryPannelPopover();
	if (text.indexOf($g("视图"))>=0){
		if (PageLogicObj.m_MarkListDataGrid !=""){
			setTimeout(function(){
				 ClearAllTableData("MarkList");
			});	
		}
	}else{
		var $card=$("div[id*='-marklist-card']");
		if ($card.length>0) $card.parent().remove();
	}
	LoadClinicServiceGroup("");
	$("#CardNo").focus();
}
function MedicalBookClickHandler(){
	setTimeout(function(){
		MedicalBookChange();
	});
}
function MedicalBookChange(){
	var Amount=0;
	if (!PageLogicObj.m_selectedMarkListDataGrid.datagrid) return;
	var Data=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
	for (var j=0;j<Data["rows"].length;j++) {
		var TabPrice=Data["rows"][j]["TabPrice"]; 
		Amount=Amount+(+TabPrice);
	}
	$('#BillAmount').val(Amount);
	var MRFee=ServerObj.MRNoteFee;
	var o=$HUI.checkbox("#MedicalBook");
	if (o.getValue()){
		var BillAmount=$('#BillAmount').val();
		if (BillAmount==""){BillAmount=0}
		BillAmount=(parseFloat(BillAmount)+parseFloat(MRFee)).toFixed(2);
		$("#BillAmount").val(BillAmount);
	}
	var BillAmount=$("#BillAmount").val();
	var PaySum=$("#PaySum").val();
	if (+PaySum>0){
		var ReturnAmount=parseFloat((+PaySum)-BillAmount).toFixed(2); 
		$("#ReturnAmount").val(ReturnAmount);
	}
}
function BPatInfoCollapsHandle(){
	if ($(".extendinfo").css("display")=="none"){
		$(".patinfo-div").removeClass("min-patinfo").addClass("max-patinfo");
		$(".extendinfo").show();
		$("#BPatInfoCollaps .l-btn-text")[0].innerText=$g("隐藏全部");
	}else{
		$(".patinfo-div").removeClass("max-patinfo").addClass("min-patinfo");
		$(".extendinfo").hide();
		$("#BPatInfoCollaps .l-btn-text")[0].innerText=$g("展开全部");
	}
}
function PaySumKeydown(e){
	var key=websys_getKey(e);
	if (key==13) {
		ReCalculateAmount();
	}
}
function PaySumKeyPress(){
	try {keycode=websys_getKey(e);} catch(e) {keycode=websys_getKey();}
	if (keycode==45){window.event.keyCode=0;return websys_cancel();}
	if (((keycode>47)&&(keycode<58))||(keycode==46)){
		//如果输入金额过长导致溢出计算有误
		if ($("#PaySum").val().length>11) {
			window.event.keyCode=0;
			return websys_cancel();
		}
	}else{
		window.event.keyCode=0;return websys_cancel();
	}
}
function ReCalculateAmount(){
	var BillAmount=$('#BillAmount').val();
	var GetAmount=$('#PaySum').val();
	if ((GetAmount!="")&&(GetAmount!='0.00')){
		var ReturnAmount=parseFloat(GetAmount)-BillAmount;
		var ReturnAmount=ReturnAmount.toFixed(2)
		$("#ReturnAmount").val(ReturnAmount);
		if (ReturnAmount<0){
			$("#ReturnAmount").addClass("newclsInvalid"); 
		}else{
			$("#ReturnAmount").removeClass("newclsInvalid"); 
		}
	}
}
function LoadTimeRange(){
	$.cm({
		ClassName:"web.DHCOPAdmReg", 
		MethodName:"GetTimeRangeStr",
		dataType:"text",
		Flag:1
	},function(Data){
	    var templ=$("#timerange-tmp");
	    var panel=$(".timerange-div");
	     var tool=templ.clone();
		 tool.removeAttr("style");
		 tool.removeAttr("id");
		 var a=$("a",tool).prevObject.attr("id","CUR-TimeRange");
		 $("a",tool).prevObject.find("span").eq(1).text($g("当前"));
		 panel.append(tool); 
		 var tool=templ.clone();
		 tool.removeAttr("style");
		 tool.removeAttr("id");
		 var a=$("a",tool).prevObject.attr("id","ALL-TimeRange");
		 $("a",tool).prevObject.find("span").eq(1).text($g("全部"));
		 panel.append(tool); 
		for(var i=0,len=Data.split("^").length;i<len;++i){
			 var onedata=Data.split("^")[i];
			 var id=onedata.split(String.fromCharCode(1))[0];
			 id=id+"-TimeRange"
			 var text=onedata.split(String.fromCharCode(1))[1].split(String.fromCharCode(2))[0];
			 var tool=templ.clone();
			 tool.removeAttr("style");
			 tool.removeAttr("id");
			 var a=$("a",tool).prevObject.attr("id",id);
			 $("a",tool).prevObject.find("span").eq(1).text(text);
			 panel.append(tool);
	   }
	   SetDefaultTimeRange();
	});
}
function SetDefaultTimeRange(){
	var defaultTimeRange="CUR"; //默认当前,挂号开始时间和结束时间包含“当前”时间的排班记录都需要查询出来
	/*if (ServerObj.ParaRegType!="APP"){
		defaultTimeRange=$.cm({
			ClassName:"web.DHCOPAdmReg", 
			MethodName:"GetCurrentTimeRange",
			dataType:"text"
		},false);
	}*/
	$(".seltimerange").removeClass("seltimerange");
	$("#"+defaultTimeRange+"-TimeRange").addClass("seltimerange");
	$("a[id$='TimeRange']").click(TimeRangeChange);
}
function InitReceiptCount(){
	$.cm({
		ClassName:"web.DHCOPAdmReg", 
		MethodName:"GetReceiptStr",
		RegDate:"", UserRowId:session['LOGON.USERID'],
		dataType:"text"
	},function(ReceiptStr){
		var arr=ReceiptStr.split('^');
		$('#ReceiptCount').val(arr[0]);
	})
}
function GetReceiptNo(){
	var insType = "";
	var p1 = session['LOGON.USERID'] + "^" + "^" + session['LOGON.GROUPID'] + "^" + "R" + "^" + insType + "^" + session['LOGON.HOSPID'];
	var rtn=cspRunServerMethod(ServerObj.GetreceipNO,'SetReceipNO','',p1);
	if (rtn!='0') {
		$.messager.alert("提示","没有分配发票号,不能结算!");
		return false;
	}
}
function SetReceipNO(value) {
	var myAry = value.split("^");
	var currNo = myAry[0];
	var title = myAry[4];
	var tipFlag = myAry[5];
	var receiptNo = title + currNo;
	$('#ReceiptNo').val(receiptNo);
	///如果张数小于最小提示额change the Txt Color
	if (tipFlag == "1"){	
		$("#ReceiptNo").addClass("newclsInvalid"); 
	}
}
function CardSearchCallBack(CardNo){
	$("#CardNo").val(CardNo);
	CheckCardNo();
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

function CardNoKeyDownCallBack(myrtn, errMsg){
	if (typeof errMsg == "undefined") errMsg="卡无效";
	$(".newclsInvalid").removeClass('newclsInvalid');
	var myary=myrtn.split("^");
    var rtn=myary[0];
	switch (rtn){
		case "0": //卡有效有帐户
			var PatientID=myary[4];
			var PatientNo=myary[5];
			var CardNo=myary[1];
			$("#CardNo").val(CardNo);
			$("#CardTypeRowID").val(myary[8]);
		    var CardLeaving=myary[3];
		    $("#CardLeaving").val(parseFloat(CardLeaving).toFixed(2));
		    $("#AccAmount").val(parseFloat(CardLeaving).toFixed(2));
			//以配置为准
			//if (ServerObj.ParaRegType!="APP"){
			//	if(CardLeaving<=0){
			//		DHCC_SelectOptionByCode("PayMode","CASH");
			//	}else{
			//		DHCC_SelectOptionByCode("PayMode","CPP");
			//	}
			//}
			
				SetPatientInfo(PatientNo,CardNo);
			event.keyCode=13;			
			break;
		case "-200": //卡无效
			$.messager.confirm("提示", errMsg+"是否需要为患者新建卡？", function (r) {
				if (r) {
					BRegExpClickHandle();
				} else {
					$("#CardNo").focus();
				}
			});
			return false;
			break;
		case "-201": //卡有效无帐户
			var PatientID=myary[4];
			var PatientNo=myary[5];
			var CardNo=myary[1];
			$("#CardNo").focus().val(CardNo);
			$("#CardTypeRowID").val(myary[8]);
		    var CardLeaving=myary[3];
		    $("#CardLeaving").val(parseFloat(CardLeaving).toFixed(2));
		    $("#AccAmount").val(parseFloat(CardLeaving).toFixed(2));
			//if (ServerObj.ParaRegType!="APP"){
			//	DHCC_SelectOptionByCode("PayMode","CASH");
			//}
				SetPatientInfo(PatientNo,CardNo);
			event.keyCode=13;
			break;
		default:
	}
}

function AfterReadCardCheck(){
	var CardTypeNew=$("#CardTypeNew").val();
	if (CardTypeNew.indexOf("身份证")>=0){
		//var myInfo=DHCWCOM_PersonInfoRead("1");
		var myInfo=CardCommon_ControlObj.ReadPersonInfo({ReadType:"Hard"});
		var myary=myInfo.split("^");
		if (myary[0]=="0"){
			var ReadName=myary[1].split("<Name>")[1].split("</Name>")[0]
			var Name=$("#Name").val();
			if (ReadName!=Name){
				$.messager.alert("提示","证件姓名<font style='color:red'>"+ReadName+"</font>与系统姓名<font style='color:blue'>"+Name+"</font>不符!","info",function(){
					var CardNo=$("#CardNo").val();
					BClearHandle();
					var lnk = "doc.patientinfoupdate.hui.csp?CardNo="+CardNo;
	                lnk=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(lnk):lnk;
					var $code ="<iframe width='99%' height='99%' scrolling='auto' frameborder='0' src='"+lnk+"'></iframe>" ;
					createModalDialog("Project","修改患者信息", PageLogicObj.dw+200, PageLogicObj.dh,"icon-write-order","",$code,"");
					$('#CardNo').focus();	
				});
			}
		}
	}
}
function DHCC_SelectOptionByCode(id,Val){
	if (id=="PayMode") {
		var PayModeData=$("#PayMode").combobox('getData');
		var index=$.hisui.indexOfArray(PayModeData,"CTPMCode",Val);
		if (index>=0){
			$("#PayMode").combobox("select",PayModeData[index].CTPMRowID);
		}
	}else{
		var opts=$("#"+id).combobox("options");
		var ComboData=$("#"+id).combobox('getData');
		for (var i=0;i<ComboData.length;i++){
			var scode=ComboData[i][opts.valueField];
			var pmod=scode.split("^");	
			if (pmod[2]==Val) {
				$("#"+id).combobox('select',scode);
			}
		}
	}
	
}
function PatientNoKeydownHandler(e){
	var key=websys_getKey(e);
	if (key==13) {
		var PatientNo=$("#PatientNo").val();
		if (PatientNo!='') {
			if (PatientNo.length<10) {
				for (var i=(10-PatientNo.length-1); i>=0; i--) {
					PatientNo="0"+PatientNo;
				}
			}
		}
		$("#PatientNo").val(PatientNo);
		CheckPatientNo();
	}
}
function CheckPatientNo(){
	if (!CheckBeforeCardNoChange()) return false;
    var PatientNo=$("#PatientNo").val();
	
	//判断登记号是否存在有效卡,如果无有效卡则给出提示
    var CardNoStr=$.cm({
	    ClassName : "web.DHCOPAdmReg",
	    MethodName : "GetCardNoByPatientNo",
	    dataType:"text",
	    PatientNo:PatientNo,
	    HospId:session['LOGON.HOSPID']
    },false);
    var CardNo=CardNoStr.split("^")[0];
	if (CardNo=="") {
		var PatientID=CardNoStr.split("^")[3];
		if (PatientID=="") {
			$.messager.alert("提示",PatientNo+" " + $g("该登记号无对应患者!"),"info",function(){
				$("#PatientNo").val("").focus();
			})
		}else{
			var UnitRegNo=$.cm({
			    ClassName : "web.DHCOPAdmReg",
			    MethodName : "GetUnitedRegNo",
			    dataType:"text",
			    PatientID:PatientID,
		    },false);
			if (UnitRegNo!=""){
				$.messager.alert("提示",PatientNo+" " + $g("该登记号已被合并，保留登记号为") + "<font style='color:red'>"+UnitRegNo+"</font>!","info",function(){
					$("#PatientNo").val("").focus();
				})
				return false;
			}
			$.messager.confirm("确认弹出框",PatientNo+" " + $g("该登记号无对应卡号信息,是否新建卡?"),function(r){
				if (r) {
					$("#PatientNo").val(PatientNo);
					$("#CardNo,#Name,#Sex,#Age").val(""); 
					BRegExpClickHandle(PatientNo);
				}else{
					$("#PatientNo").focus();
				}
			});
		}
		return false;
	}
	var NewCardTypeRowId=CardNoStr.split("^")[1];
	$("#CardTypeNew").val(CardNoStr.split("^")[2]);
	$("#CardTypeRowID").val(NewCardTypeRowId);
	$("#CardNo").val(CardNo);
	$("#CardLeaving").val(CardNoStr.split("^")[8]);
	SetPatientInfo(PatientNo,CardNo);
	//$("#BillAmount,#PaySum,#ReturnAmount").val("0.00");
	if ((PageLogicObj.m_RegJumpFlag=="")||(CardNo=="")) return true;
	//建卡跳转到挂号界面时校验一下卡信息，无需重复赋值患者信息
	//var myrtn=DHCACC_GetAccInfo("",CardNo,"","",CardNoKeyDownNotSetPatientInfoCallBack);
	CardCommon_ControlObj.GetAccInfo({
		CardNo:CardNo,
		CallBackFun:CardNoKeyDownNotSetPatientInfoCallBack
	})
	return true;
}
function CardNoKeyDownNotSetPatientInfoCallBack(myrtn, errMsg){
	if (typeof errMsg == "undefined") errMsg="卡无效";
	$(".newclsInvalid").removeClass('newclsInvalid');
	var myary=myrtn.split("^");
    var rtn=myary[0];
	switch (rtn){
		case "0": //卡有效有帐户
		    var CardLeaving=myary[3];
		    $("#CardLeaving").val(parseFloat(CardLeaving).toFixed(2));
		    $("#AccAmount").val(parseFloat(CardLeaving).toFixed(2));
			//以配置为准
			//if (ServerObj.ParaRegType!="APP"){
			//	if(CardLeaving<=0){
			//		DHCC_SelectOptionByCode("PayMode","CASH");
			//	}else{
			//		DHCC_SelectOptionByCode("PayMode","CPP");
			//	}
			//}
			//SetPatientInfo(PatientNo,CardNo);
			event.keyCode=13;			
			break;
		case "-200": //卡无效
			$.messager.confirm("提示", errMsg+"是否需要为患者新建卡？", function (r) {
				if (r) {
					BRegExpClickHandle();
				} else {
					$("#CardNo").focus();
				}
			});
			return false;
			break;
		case "-201": //卡有效无帐户
		    var CardLeaving=myary[3];
		    $("#CardLeaving").val(parseFloat(CardLeaving).toFixed(2));
		    $("#AccAmount").val(parseFloat(CardLeaving).toFixed(2));
			//if (ServerObj.ParaRegType!="APP"){
			//	DHCC_SelectOptionByCode("PayMode","CASH");
			//}
			//SetPatientInfo(PatientNo,CardNo);
			event.keyCode=13;
			break;
		default:
	}
}
function TimeRangeChange(e){
	$(".seltimerange").removeClass("seltimerange");
	var id=e.currentTarget.id;
	$("#"+id).addClass("seltimerange");
	LoadMarkList();
}
///判断卡是否是临时卡
function CheckTemporaryCard(CardNo, CardTypeDr) {
	var TemporaryCardFlag=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"CheckTempCardEffe",
		CardTypeId:CardTypeDr,
		CardNo:CardNo,
		dataType:"text"
	},false)
	return TemporaryCardFlag
}
function SetPatientInfo(PatientNo,CardNo){
	if (!CheckBeforeCardNoChange()) return false;
	if (PatientNo!='') {
		var AccAmount= $("#AccAmount").val();
		var CardTypeNew=$("#CardTypeNew").val();
		var CardTypeRowID=$("#CardTypeRowID").val();
		var CardLeaving=$("#CardLeaving").val();
		var ReceiptNo=$("#ReceiptNo").val();
		var ReceiptCount=$("#ReceiptCount").val();
		var PatientID=$("#PatientID").val();
		ClearPatInfo();
		$("#SelLoc").html("");
		var TemporaryCardFlag=CheckTemporaryCard(CardNo, CardTypeRowID);
		var IsTempCard=TemporaryCardFlag.split("^")[0];
		var DiscDate=TemporaryCardFlag.split("^")[1];
		if (IsTempCard=="Y"){
			if (ServerObj.ParaRegType=="APP") {
				$.messager.alert("提示","临时卡不能进行预约!")
				return false;
			}
			if (DiscDate>0){
				$.messager.alert("提示","临时卡已过能挂号有效天数!","info",function(){
					$("#CardNo").focus();
				})
				return false;
			}
			if (ServerObj.ParaRegType=="Reg") {
				$.messager.alert("提示","临时卡只能挂急诊号!")
			}
		}
		/*var IsDeceased=$.cm({
		    ClassName : "web.PAPerson",
		    MethodName : "CheckDeceased",
		    dataType:"text",
		    PatientID:PatientID,
	    },false);
	    if (IsDeceased=="Y"){
		    $.messager.alert("提示","患者已故,不允许挂号!")
			return false;
		}*/
		$("#PatientNo").val(PatientNo);
		$("#CardNo").val(CardNo);
		$("#AccAmount").val(AccAmount);
		$("#CardTypeNew").val(CardTypeNew);
		$("#CardTypeRowID").val(CardTypeRowID);
		$("#CardLeaving").val(CardLeaving);
		$("#ReceiptNo").val(ReceiptNo);
		$("#ReceiptCount").val(ReceiptCount);
		$("#PatientID").val(PatientID);
		var PatInfoStr=$.cm({
		    ClassName : "web.DHCOPAdmReg",
		    MethodName : "GetPatDetailBroker",
		    dataType:"text",
		    itmjs:"",
		    itmjsex:"GetPatDetailToHUI",
		    val:PatientNo,
	    },false);
	    if (PatInfoStr!=""){
		    SetPatient_Sel(PatInfoStr);
		}else{
			$("#CardNo").addClass("newclsInvalid").focus(); 
			return false();
		}
		setTimeout(function(){
			AfterReadCardCheck();
		},500);
	} else {
		$('#CardNo').focus();
		return false();
	}
}
function SetPatient_Sel(value){
	try {  
		var Patdetail=value.split("^");
		var NeedAddPatInfo=Patdetail[32]
		if (NeedAddPatInfo!=""){
			$.messager.alert("提示",$g("患者")+"<font style='color:red'>"+NeedAddPatInfo+"</font>"+$g("需完善！"),"info",function(){
				var CardNo=$("#CardNo").val();
				BClearHandle();
				var lnk = "doc.patientinfoupdate.hui.csp?CardNo="+CardNo;
                lnk=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(lnk):lnk;
				var $code ="<iframe width='99%' height='99%' scrolling='auto' frameborder='0' src='"+lnk+"'></iframe>" ;
				createModalDialog("Project",$g("修改患者信息"), PageLogicObj.dw+200, PageLogicObj.dh,"icon-write-order","",$code,"");
				$('#CardNo').focus();
			})
			return false;
		}
		$("#Name").val(Patdetail[0]);
		$("#Age").val(Patdetail[1]);
		$("#Sex").val(Patdetail[2]);
		//门诊病历号和住院病历号
		$("#OPMRN").val(Patdetail[3]);
		$("#IPMRN").val(Patdetail[4]);
		$("#PatCat").val(Patdetail[5]);
		$("#PatientID").val(Patdetail[6]);
		$("#IDCardNo").val(Patdetail[7]);
		$("#PatientNo").val(Patdetail[9]);
		$("#AppBreakCount").val(Patdetail[10]);
		//医保号
		$("#PatYBCode").val(Patdetail[11]);
		//医保类型
		//$("YBType",Patdetail[12]);
		$("#PoliticalLevel").val(Patdetail[19]);
		$("#SecretLevel").val(Patdetail[20]);		
		$("#TelH").val(Patdetail[21]);
		$("#PAPERCountry").val(Patdetail[22]);
		$("#Address").val(Patdetail[23]);
		$("#CredType").val(Patdetail[24]);
		$("#CredNo").val(Patdetail[25]);
		var PatInIPAdmission=Patdetail[26];
		var IsDeceased=Patdetail[27];
		if (IsDeceased =="Y") {
			$.messager.alert("提示","患者已故!","info",function(){
				ClearPatInfo();
				$("#CardNo").focus();
			})
			return false;
		}
		var AgeLimitInfo=Patdetail[28];
		var CheckObj={"TelNo":Patdetail[21],"IDTypeID":Patdetail[30],"IDCardNo":Patdetail[25]};
		var RetObj=DHCWeb_IsTelOrMobile(CheckObj);
		if ((AgeLimitInfo!="")||(RetObj.Flag!="0")){
			AgeLimitInfo=AgeLimitInfo||RetObj.Desc;
			$.messager.alert("提示",AgeLimitInfo,"info",function(){
				var CardNo=$("#CardNo").val();
				BClearHandle();
				var lnk = "doc.patientinfoupdate.hui.csp?CardNo="+CardNo;
                lnk=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(lnk):lnk;
				var $code ="<iframe width='99%' height='99%' scrolling='auto' frameborder='0' src='"+lnk+"'></iframe>" ;
				createModalDialog("Project","修改患者信息", PageLogicObj.dw+200, PageLogicObj.dh,"icon-write-order","",$code,"");
				$('#CardNo').focus();
			})
			return false;
		}
		var HasPendPayOrdFlag=Patdetail[29];
		new Promise(function(resolve,rejected){
			if (PatInIPAdmission==1){
				$.messager.alert("提示","患者正在住院!","",function(){
					resolve();
				});
			}else {
				resolve();
			}
		}).then(function(){
			return new Promise(function(resolve,rejected){
	            if (HasPendPayOrdFlag==1){
		            $.messager.alert("提示","该患者有未补交的先诊疗后付费费用，存在漏费风险!","",function(){
			            resolve();
		            })
		        }else {
			        resolve();
		        }
			})
		}).then(function(){		
			PageLogicObj.m_PreCardNo=$("#CardNo").val();
			PageLogicObj.m_PreCardType=$("#CardTypeNew").val();
			PageLogicObj.m_PreCardLeaving=$("#CardLeaving").val();
			//if (PageLogicObj.m_PreCardNo==""){PageLogicObj.m_PreCardNo=$("#CardNo").val();}
			var PatientID=Patdetail[6];
			var BillTypeData=$.cm({
				ClassName:"web.DHCOPAdmReg",
				MethodName:"GetBillTypeListBroker",
				dataType:"text",
				JSFunName:"GetBillTypeToHUIJson",
				ListName:"",
				PatientID:PatientID
			},false);
			var cbox = $HUI.combobox("#BillType", {
					valueField: 'id',
					textField: 'text', 
					editable:true,
					data: JSON.parse(BillTypeData),
					onSelect:function(record){
						LoadRegConDisList();
						RefreshSelMarkFee();
						LoadMarkList();
						MedicalBookClickHandler();
					}
			 });
			if (ServerObj.ParaRegType=="APP"){
				var BlackFlag=$.cm({
					ClassName:"web.DHCRBAppointment",
					MethodName:"GetLimitAppFlag",
					dataType:"text",
					PatientId:PatientID,
					IDCardNo:""
				},false);
				var BlackFlag=BlackFlag.split("^")[0];
				//var PBTypeExeResult=BlackFlag.split("^")[2]; //管控代码执行结果
				if (BlackFlag==1){
				      $.messager.alert("提示","存在有效黑名单记录,不允许预约","info",function(){
					      $("#Name").addClass("blackname");
					  })
				      return false;
				}else{
					$("#Name").removeClass("blackname");
				}
			}
			/*
			//特殊患者管理 返回值包含管控代码执行结果
			var SpecPatType=$.cm({
				ClassName:"web.DHCSpecPat",
				MethodName:"GetSpecPatTypeByCredNo",
				dataType:"text",
				PatientId:PatientID
			},false);*/
			//爽约提醒
			if (ServerObj.ParaRegType!="APP"){
				var AppBreakInfo=$.cm({
					ClassName:"web.DHCRBAppointment",
					MethodName:"GetAppBreakInfo",
					dataType:"text",
					PatientID:PatientID,
				},false);
				if (AppBreakInfo!=""){
					$.messager.alert("提示",AppBreakInfo);
				}
			}
			//预约增加
			var AppSerialNo=$("#AppSerialNo").val();
			if (AppSerialNo==undefined) AppSerialNo="";
			if (AppSerialNo!="") {
				AppSerialNoBlurHandler();
			}else{
				GetApptInfo(PatientID);
			}
			if (ServerObj.ParaRegType!="APP"){
				if (PageLogicObj.m_selectedMarkListDataGrid==""){
					PageLogicObj.m_selectedMarkListDataGrid=InitselectedMarkListDataGrid();
				}
				if (PageLogicObj.m_curDayRegListDataGrid==""){
					PageLogicObj.m_curDayRegListDataGrid=curDayRegListDataGrid();
				}else{
					ClearAllTableData("curDayRegList");
				}
				//增加急诊分级
				GetEmChkInfo(PatientID);
				//增加当日已挂号记录查询
				GetCurDateRegList();
			}
			var rtn=$.cm({
			    ClassName : "web.DHCOPAdmReg",
			    MethodName : "GetAdmRecord",
			    dataType:"text",
			    PatientID:PatientID
		    },false);
		    var o=$HUI.checkbox("#MedicalBook");
			if(rtn==0){
				if (!o.getValue()){
					o.setValue(true);
				}else{
					MedicalBookChange();
				}
				$HUI.checkbox("#NeedCardFee").setValue(true);
			}else{
				if (o.getValue()){
					o.setValue(false);
				}else{
					MedicalBookChange();
				}
				$HUI.checkbox("#NeedCardFee").setValue(false);
			}
			LoadMarkList();
			if(PatientID!=""){
				LoadRegConDisList()
			}
			$("#DeptList").focus();
			///dts埋点
			DTSLog.ClearDTSLog();
			DTSLog.AddOnelog("1633642142285041664",PatientID,PatientID,"",session['LOGON.USERCODE'])
		})
	} catch(e) {
		$.messager.alert("提示",e.message);
	};
}
function GetCurDateRegList(){
	$.cm({
		ClassName:"web.DHCOPAdmReg",
		QueryName:"DHCOPAdm",
		RegNo:"", nday:"", InvoiceNo:"", PatientID:$("#PatientID").val(), 
		UserRowId:"", QueryCancel:""
	},function(GridData){
		PageLogicObj.m_curDayRegListDataGrid.datagrid('loadData',GridData);
	});
}
function GetEmChkInfo(PatientID){
	var TimeRangeRowId=$(".seltimerange")[0].id.split("-")[0];
	if (TimeRangeRowId=="ALL") TimeRangeRowId="";
	var AdmReason=$('#BillType').combobox('getValue');
	var RegConDisId="";
	if(ServerObj.ParaRegType!="APP"){
		RegConDisId=$("#RegConDisList").combobox("getValue");
	}
	var EmChkInfoRtn=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"GetEmChkInfo",
		dataType:"text",
		PatientID:PatientID, TimeRangeRowId:TimeRangeRowId, AdmReason:AdmReason, GroupRowId:session['LOGON.GROUPID'],
		RegConDisId:RegConDisId,
		dataType:"text"
	},false);
	if (EmChkInfoRtn!=""){
		var BillAmount=$("#BillAmount").val();
		var InfoArr=EmChkInfoRtn.split("#")
		for(var i=0;i<InfoArr.length;i++){
			var OneListInfo=InfoArr[i];
			var InfoArr1=OneListInfo.split("^")
			var BillAmount=parseFloat(BillAmount)+parseFloat(InfoArr1[2]);
			var PCLRowID="";
			if (OneListInfo.split('^').length>=16){
				PCLRowID=OneListInfo.split('^')[15];
			}
			var RepeatFlag=CheckRowDataRepeat("TabPCLRowID",PCLRowID);
			if (RepeatFlag==1) continue;
			AddRegToTable(OneListInfo)
		}
		$("#BillAmount").val(BillAmount);
	}
}
function NeedCardFeeCheck(){
	var o=$HUI.checkbox("#NeedCardFee");
	if (o.getValue()){
		var BillAmount=$('#BillAmount').val();
		if (BillAmount==""){BillAmount=0}
		BillAmount=(parseFloat(BillAmount,10)+parseFloat(ServerObj.CardFee,10)).toFixed(2); 
		$("#BillAmount").val(BillAmount);
	}else{
		var BillAmount=$('#BillAmount').val();
		if (BillAmount==""){BillAmount=0}
		BillAmount=(parseFloat(BillAmount,10)-parseFloat(ServerObj.CardFee,10)).toFixed(2); 
		$("#BillAmount").val(BillAmount);
	}
}
function CheckBeforeCardNoChange(){
	if (PageLogicObj.m_selectedMarkListDataGrid==""){
		PageLogicObj.m_selectedMarkListDataGrid=InitselectedMarkListDataGrid();
	}
	//验证是否有未完成的挂号
	var Data=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
	if (Data["rows"].length>=1){
		$.messager.alert("提示","请先完成上一个患者的挂号!","info",function(){
			$("#CardNo").val(PageLogicObj.m_PreCardNo);
			$("#CardTypeNew").val(PageLogicObj.m_PreCardType);
			$("#CardLeaving").val(PageLogicObj.m_PreCardLeaving);
		});
		return false;
	}
	return true;
}
function ClearPatInfo(){
	var $input=$(":input:text");
	for (var i=0;i<$input.length;i++){
		$("#"+$input[i]["id"]).val("");
	}
	$("#PatientID,#CardTypeRowID").val('');
	$("#Name").removeClass("blackname");
	SetDefaultAppDate();
}
function SetDefaultAppDate(){
	if ((ServerObj.DefaultAppDate!="")&&(ServerObj.ParaRegType=="APP")){
		$('#AppDate').datebox('setValue',ServerObj.DefaultAppDate);
		$("#SelDate").html(ServerObj.DefaultAppDate);
		$("#WeekDesc").html($g(ServerObj.DefaultAppWeek));
	}	
}
function AppointClickHandler(){
	var AppStFlag=ChekAppSatrtTime();
	if (AppStFlag!="Y") return;
	var Data=PageLogicObj.m_selectedMarkListDataGrid.datagrid("getData");
	if (Data["rows"].length==0){
		$.messager.alert("提示","没有选择挂号信息!");
		return false;
	}
	//办理预约是否要预先分配号,取号的处理在同一界面吗
	var PatientID=$('#PatientID').val();
	var AdmReason="";
	var UserID=session['LOGON.USERID'];
	var GroupID=session['LOGON.GROUPID'];
	//判断是否存在有效的黑名单记录
	if(!CheckHaveBlack(PatientID,"")) return false;
	var AppPatCredNo=$('#AppPatCredNo').val();
	var AppPatName=$('#AppPatName').val();
	var AppPatTel=$('#AppPatTel').val();
	var AppPatAddress=$('#AppPatAddress').val();
	var AppPatInfo="";
	var AppPatType=$('#AppPatType').combobox('getValue');
	var AppPatCredType=$('#AppPatCredType').combobox('getValue').split("^")[0];
	var ValidInfo=CheckCredNoValid(AppPatCredNo,AppPatCredType)
	if (ValidInfo!=0){
		$.messager.alert("提示",ValidInfo,"info");
		return false;
	}
	var CommonPatientID=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"GetCommonPatientID",
		dataType:"text"
	},false);
	var CommonPatientID="^"+CommonPatientID+"^"
	if(CommonPatientID.indexOf("^"+PatientID+"^")!="-1"){
		if((AppPatName=="")||(AppPatCredNo=="")||(AppPatTel=="")){
		  	$.messager.alert("提示","无卡预约的病人必须填写完整预约信息!");
		  	return false;
	  	}else{
		  	if(!CheckHaveBlack("",AppPatCredNo)) return false;
		  	if(AppPatCredNo!=""){
			  	var myIDrtn=IsCredTypeID();
				if (myIDrtn){
				    var myIsID=DHCWeb_IsIdCardNo(AppPatCredNo);
					if (!myIsID){
						$("#AppPatCredNo").focus();
						return false;
					}
				}
		  	}
		  	if (!CheckTelOrMobile(AppPatTel,"AppPatTel","预约人")) return false;
		  	AppPatInfo=AppPatName+"$"+AppPatCredNo+"$"+AppPatTel+"$"+AppPatAddress+"$"+AppPatType+"$"+AppPatCredType
	    }
  	}else{
	  	AppPatInfo=AppPatName+"$"+AppPatCredNo+"$"+AppPatTel+"$"+AppPatAddress+"$"+AppPatType+"$"+AppPatCredType
	}
	var ExpStr=PageLogicObj.m_ApptTypeCode;
	try {
		for (var loop=0;loop<Data["rows"].length;loop++) {
			var TabASRowId=Data["rows"][loop]["TabASRowId"];
			var TabQueueNo=Data["rows"][loop]["TabSeqNo"];
			var TimeRangeStr=Data["rows"][loop]["TabTimeRange"];
			var TabClinicGroupDr=Data["rows"][loop]["TabClinicGroupDr"];
			var retstr=$.cm({
				ClassName:"web.DHCOPAdmReg",
				MethodName:"OPAppBroker", 
				dataType:"text",
				itmjs:"", itmjsex:"", PatientID:PatientID,ASRowId:TabASRowId,
				QueueNo:TabQueueNo, UserRowId:UserID, AppPatInfo:AppPatInfo, MethodCode:"",TimeRangeStr:TimeRangeStr,
				HospitalID:session['LOGON.HOSPID'],ClinicGroupId:TabClinicGroupDr,ExpStr:ExpStr
			},false);
			var retArr=retstr.split("^")
			var ret=retArr[0]
			var AppARowid=retArr[1]
			if (ret=="0"){
				var AppRowid=retArr[1];
                AppPrintOut(AppRowid);
			}else{
				if(ret=="-201"){ret="，此号已预约完"}
				else if(ret=="-202"){ret="，此号没有排班记录"}
				else if(ret=="-203"){ret="，此号已停止或者被替诊"}
				else if(ret=="-204"){ret="，预约渠道信息不能为空!"}
				else if(ret=="-301"){ret="，此病人超过每天挂号限额"}
				else if(ret=="-302"){ret="，此病人超过每天挂一个医生的限额"}
				else if(ret=="-303"){ret="，此病人超过每人每天挂相同科室限额"}	
				$.messager.alert("提示","预约失败!"+ret,"info",function(){
					PageLogicObj.m_selectedMarkListDataGrid.datagrid('deleteRow',loop);
					$('#CardNo').focus();
				});
				return false;
			}
		}
		$.messager.popover({msg: '预约成功!',type:'success',timeout: 1000});
		BClearHandle();
		$('#CardNo').focus();
	}catch(e){$.messager.alert("提示",e.message)}			
}
function CheckTelOrMobile(telephone,Name,Type){
	if (DHCC_IsTelOrMobile(telephone)) return true;
	if (telephone.indexOf('-')>=0){
			$.messager.alert("提示",Type+"固定电话长度错误,固定电话区号长度为【3】或【4】位,固定电话号码长度为【7】或【8】位,并以连接符【-】连接,请核实!","info",function(){
				$("#"+Name).focus();
			})
			websys_setfocus(Name);
	        return false;
	}else{
		if(telephone.length!=11){
			$.messager.alert("提示",Type+"联系电话电话长度应为【11】位,请核实!","info",function(){
				$("#"+Name).focus();
			})
	        return false;
		}else{
			$.messager.alert("提示",Type+"不存在该号段的手机号,请核实!","info",function(){
				$("#"+Name).focus();
			})
	        return false;
		}
	}
	return true;
}
function CancelApp(APPTRowId){
	if (APPTRowId==''){return false();}
	var UserRowId=session['LOGON.USERID']
	var ret=$.cm({ 
		ClassName:"web.DHCRBAppointment",
		MethodName:"CancelAppointment", 
		dataType:"text",
		APPTRowId:APPTRowId, UserRowId:UserRowId
	},false);	
	if (ret=="0"){
		$.messager.alert("提示","取消预约成功!","info",function(){
			var index=PageLogicObj.m_curDayAppListDataGrid.datagrid('getRowIndex',APPTRowId);
			PageLogicObj.m_curDayAppListDataGrid.datagrid('deleteRow',index);
		});
	}else{
		if (ret=="-201") {
			$.messager.alert("提示","此预约已取号!");
			return false;
		}
		if (ret=="-202") {
			$.messager.alert("提示","此预约已取消!");
			return false;
		}
		$.messager.alert("提示","取消预约失败!"+"ErrCode:"+ret);
		return false;
	}
}
function ChekAppSatrtTime(){
	var RtnAppFlag=$.cm({ 
		ClassName:"web.DHCOPAdmReg",
		MethodName:"CheckAppRegTime", 
		dataType:"text"
	},false);	
	if (RtnAppFlag=="N"){
		$.messager.alert("提示","还未到预约开始时间!");
	}
	return RtnAppFlag
}
function SetPassCardNo(CardNo,CardType){
	$("#CardNo").val(CardNo);
	$("#CardTypeNew").val(CardType);
	//combo_CardType.setComboValue(CardType);
	CheckCardNo();
}
///日志保存
function SavePrescEventLog(EpisodeID){
	try{
		var EventLogData=$.cm({ 
			ClassName:"web.DHCDocPrescript",
			MethodName:"GetPrescEventLogInfo", 
			dataType:"text",
			EpisodeID:EpisodeID
		},false);
		var infoarr=EventLogData.split("^");
		var ModelName="DHCOPADMREG";
		var Condition="{RegNo:"+infoarr[0]+"}";
    	var Content="{EpisodeId:"+infoarr[1]+"}";
		var SecretCode=infoarr[2];
		if (SecretCode!="") {
			var EventLogRowId=$.cm({ 
				ClassName:"web.DHCEventLog",
				MethodName:"EventLog", 
				dataType:"text",
				ModelName:ModelName, Condition:Condition, Content:Content, SecretCode:SecretCode
			},false);
		}
	} catch (e) { $.messager.alert("提示",e.message);}
    return 0;
}
function myformatter(date){
	var y = date.getFullYear();
	var m = date.getMonth()+1;
	var d = date.getDate();
	if (ServerObj.sysDateFormat=="3") return y+'-'+(m<10?('0'+m):m)+'-'+(d<10?('0'+d):d);
	else if (ServerObj.sysDateFormat=="4") return (d<10?('0'+d):d)+"/"+(m<10?('0'+m):m)+"/"+y
	else return y+'-'+(m<10?('0'+m):m)+'-'+(d<10?('0'+d):d);
}
function myparser(s){
    if (!s) return new Date();
    if(ServerObj.sysDateFormat=="4"){
		var ss = s.split('/');
		var y = parseInt(ss[2],10);
		var m = parseInt(ss[1],10);
		var d = parseInt(ss[0],10);
	}else{
		var ss = s.split('-');
		var y = parseInt(ss[0],10);
		var m = parseInt(ss[1],10);
		var d = parseInt(ss[2],10);
	}
	if (!isNaN(y) && !isNaN(m) && !isNaN(d)){
		return new Date(y,m-1,d);
	} else {
		return new Date();
	}
}
function RemClickHandle(){
	var row=PageLogicObj.m_PilotProListTabDataGrid.datagrid('getSelected');
	if ((!row)||(row.length==0)){
		$.messager.alert("提示","请选择项目!");
		return false;
	}
	var PPRowId=row["TPPRowId"];
	var PPDesc=row["TPPDesc"];
	var src="docpilotpro.rem.hui.csp?PPRowId="+PPRowId;
    src=('undefined'!==typeof websys_writeMWToken)?websys_writeMWToken(src):src;
	var $code ="<iframe width='99%' height='99%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Project","药理项目:"+PPDesc, PageLogicObj.dw, PageLogicObj.dh,"icon-write-order","",$code,"");
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
	        if (_title=="预交金充值"){
		        PatientNo=$("#PatientNo").val();
		        if (PatientNo!=""){
					CheckPatientNo();
					PageLogicObj.m_PreCardNo=$("#CardNo").val();
					PageLogicObj.m_PreCardType=$("#CardTypeNew").val();
					PageLogicObj.m_PreCardLeaving=$("#CardLeaving").val();
		        }
		    }
	    }
    });
}
function GetDeptRowId(){
	var id=PageLogicObj.m_deptRowId;;
	if ($("#DeptList").lookup('getText')==""){
		return "";
	}
	if (id==undefined) id="";
	return id;
}
function destroyDialog(id){
   //移除存在的Dialog
   $("body").remove("#"+id); 
   $("#"+id).dialog('destroy');
}
$.extend($.fn.datagrid.methods,{
	keyCtr : function (jq) {
	    return jq.each(function () {
	        var grid = $(this);
	        grid.datagrid('getPanel').panel('panel').attr('tabindex', 1).bind('keydown', function (e) {
		    	switch (e.keyCode) {
		            case 38: // up
		                var Selections = grid.datagrid('getSelections');
		                var rows = grid.datagrid('getRows');
		                if (Selections.length>0) {
			                var MaxSelection=null,MinSelection=null;
			                var opts=grid.datagrid('options');
				            $.each(Selections,function(Index,RowData){
				            	if (RowData==null){return true;}
				            	if (RowData[opts.idField]==""){return true;}
				            	if (MaxSelection==null){
				            		MaxSelection=RowData;
				            	}
				            	if (MinSelection==null){
				            		MinSelection=RowData;
				            	}
								var RowIndex=grid.datagrid('getRowIndex',RowData.OrderId);
								var Maxindex=grid.datagrid('getRowIndex',MaxSelection.OrderId);
								var Minindex=grid.datagrid('getRowIndex',MinSelection.OrderId);
								if (Maxindex<RowIndex){
									MaxSelection=RowData;
								}
								if (Minindex>RowIndex){
									MinSelection=RowData;
								}
							});
							if (MinSelection==null){
								var Rows=grid.datagrid('getRows');
								for (var i=Rows.length-1;i>=0;i--) {
									if (Rows[i][opts.idField]!=""){
										MinSelection=Rows[i];
										break;
									}
								}
								var NextIndex=grid.datagrid('getRowIndex', MinSelection);
								var index=NextIndex+1;
							}else{
								var index = grid.datagrid('getRowIndex', MinSelection);
		                    	var NextIndex=index-1;
							}
		                    if (NextIndex<0){
			                	NextIndex=rows.length - 1;
			                }
		                    grid.datagrid('unselectRow',index).datagrid('selectRow', NextIndex);
		                } else {
		                    grid.datagrid('selectRow', rows.length - 1);
		                }
		                break;
		            case 40: // down
		                var Selections = grid.datagrid('getSelections');
		                var rows = grid.datagrid('getRows');
		                if (Selections.length>0) {
		                	var MaxSelection=null,MinSelection=null;
			                var opts=grid.datagrid('options')
				            $.each(Selections,function(Index,RowData){
				            	if (RowData==null){return true;}
				            	if (RowData[opts.idField]==""){return true;}
				            	if (MaxSelection==null){
				            		MaxSelection=RowData;
				            	}
				            	if (MinSelection==null){
				            		MinSelection=RowData;
				            	}
								var RowIndex=grid.datagrid('getRowIndex',RowData.OrderId);
								var Maxindex=grid.datagrid('getRowIndex',MaxSelection.OrderId);
								var Minindex=grid.datagrid('getRowIndex',MinSelection.OrderId);
								if (Maxindex<RowIndex){
									MaxSelection=RowData;
								}
								if (Minindex>RowIndex){
									MinSelection=RowData;
								}
							});
							if (MaxSelection==null){
								grid.datagrid('uncheckAll');
								grid.datagrid('selectRow', 0);
							}else{
			                    var index = grid.datagrid('getRowIndex', MaxSelection);
			                    var NextIndex=index+1;
			                    if (NextIndex>=rows.length){
				                	NextIndex=0;
				                }
				                grid.datagrid('unselectRow',index).datagrid('selectRow', NextIndex);
			                }
		                    
		                } else {
		                    grid.datagrid('selectRow', 0);
		                }
		                break;
		    	}
	    	});
		});
	}
});
function ChangePayMode(){
	var PayModeData=$("#PayMode").combobox('getData');
	var index=$.hisui.indexOfArray(PayModeData,"CTPMRowID",ServerObj.CashPayModeID);
	if (index>=0){
        // 改为使用 promise
		new Promise(function (resolve, reject) {
			$.messager.confirm("提示", "帐户余额不足,是否切换到现金支付方式并继续操作?", function (r) {
				if (r) {
					$("#PayMode").combobox("select",ServerObj.CashPayModeID)
					resolve(true)
				} else{
					resolve(false)
				}
			})
		}).then(function (boolean) {
			if (boolean) {
				return true
			} else {
				return false
			}
		})
	}else{
		$.messager.alert("提示","帐户余额不足,请选择其他支付方式!");
		return false;
	}
}
function AppPrintOut(AppRowid)
{
	try{
		var AppPrintData=tkMakeServerCall('DHCDoc.Common.pa','GetAppPrintData',AppRowid)
		DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAppointPrint");
		var PrintDataArySum=eval(AppPrintData)
		var PrintDataAry=PrintDataArySum[0]
		var MyPara = "" + String.fromCharCode(2);
		for (Element in PrintDataAry){
			MyPara=MyPara +"^"+ Element + String.fromCharCode(2) + PrintDataAry[Element];
		}
		DHC_PrintByLodop(getLodop(),MyPara,"","","");	
	}catch(e){alert(e.message);}
	/*try{
        var AppPrintData=tkMakeServerCall('web.DHCOPAdmReg','GetAppPrintData',AppRowid)
		DHCP_GetXMLConfig("InvPrintEncrypt","DHCOPAppointPrint");
		var AppPrintArr=AppPrintData.split("^");
		var CardNo=AppPrintArr[0];
		var PapmiDr=AppPrintArr[1];
		var PapmiName=AppPrintArr[2];
		var PapmiNo=AppPrintArr[13];
		//var PapmiDOB=AppPrintArr[3];
		var PamiSex=AppPrintArr[3];
		var QueueNo=AppPrintArr[4];
		var Locdesc=AppPrintArr[6];
		var Docdesc=AppPrintArr[7];
		var AppDate=AppPrintArr[8];
		var AppTime=AppPrintArr[9];
		AppTime=AppDate+" "+AppTime
		var AdmDate=AppPrintArr[10];
		var TimeRangeInfo=AppPrintArr[14];
		var UserSS=AppPrintArr[15];
		var Price=AppPrintArr[17];
		var SessionTypeDesc=AppPrintArr[18];
		var ASDateWeek=AppPrintArr[19];
        var ArriveEndDate=AppPrintArr[20];
        var ArriveEndTime=AppPrintArr[21];
        var listitem1=AppPrintArr[22];
		var PDlime=String.fromCharCode(2);
		var MyPara="CardNo"+PDlime+CardNo+"^"+"PatNo"+PDlime+PapmiNo+"^"+"PatName"+PDlime+PapmiName+"^"+"RegDep"+PDlime+Locdesc;
		var MyPara=MyPara+"^"+"MarkDesc"+PDlime+Docdesc+"^"+"PatSex"+PDlime+PamiSex+"^"+"SeqNo"+PDlime+QueueNo+"^"+"APPDate"+PDlime+AppTime;
		var MyPara=MyPara+"^"+"AdmDate"+PDlime+AdmDate+"^"+"UserCode"+PDlime+UserSS+"^"+"AdmTimeRange"+PDlime+TimeRangeInfo;
		var MyPara=MyPara+"^"+"APPCompDate"+PDlime+AppTime+"^"+"SessionType"+PDlime+SessionTypeDesc+"^Total"+PDlime+Price+"^ArriveEndDateTime"+PDlime+ArriveEndDate+" "+ArriveEndTime;
		var MyPara=MyPara+"^"+"listitem2"+PDlime+listitem1
		//var myobj=document.getElementById("ClsBillPrint");
		//PrintFun(myobj,MyPara,"");
		DHC_PrintByLodop(getLodop(),MyPara,"","","");	
	}catch(e){alert(e.message);}*/
}
function GetErrMsg(ErrCode){
	var errmsg="";
	if (ErrCode=="-201")  errmsg="生成就诊记录失败!";
	else if (ErrCode=="-202")  errmsg="取号不成功!";
	else if (ErrCode=="-204")  errmsg="预约渠道信息不能为空!";
	else if (ErrCode=="-2121") errmsg="更新预约状态失败!";
	else if (ErrCode=="-2122") errmsg="系统忙,请稍后重试!";
	else if (ErrCode=="-206")  errmsg="插入挂号费医嘱失败!";
	else if (ErrCode=="-207")  errmsg="插入诊查费医嘱失败!";
	else if (ErrCode=="-208")  errmsg="插入假日费医嘱失败!";
	else if (ErrCode=="-209")  errmsg="插入预约费医嘱失败!";
	else if (ErrCode=="-210")  errmsg="计费失败!";
	else if (ErrCode=="-211")  errmsg="插入挂号记录失败!";
	else if (ErrCode=="-212")  errmsg="插入叫号队列失败!";
	else if (ErrCode=="-301")  errmsg="超过每人每天可挂限额,不能再挂号或预约!";
	else if (ErrCode=="-302")  errmsg="超过每人每天可挂相同号的限额!";
	else if (ErrCode=="-303")  errmsg="超过每人每天可挂相同科室号的限额!";
	else if (ErrCode=="-401")  errmsg="还没有到挂号时间!";
	else if (ErrCode=="-402")  errmsg="还未到预约时间!";
	else if (ErrCode=="-403")  errmsg="还未到加号时间!";
	else if (ErrCode=="-404")  errmsg="已经过了此排班记录出诊时间点!";
	else if (ErrCode=="-2010") errmsg="更新医保挂号信息失败!";
	else if (ErrCode=="-304")  errmsg="超过每人每天相同时段同科室同医生限额!";
	else if (ErrCode=="-405")  errmsg="请去挂号设置界面维护免费医嘱!";
	else if (ErrCode=="-406")  errmsg="已过挂号结束时间!";
	else if (ErrCode=="-213")  errmsg="已经开启停止挂号,不予许挂号及取号";
	else if (ErrCode=="-214")  errmsg="没有需要结算的医嘱，请核实是否关联级别费用或维护挂号免费医嘱";
	return errmsg;
}
function LoadCredType(){
	$.m({
		ClassName:"web.UDHCOPOtherLB",
		MethodName:"ReadCredTypeExp",
		JSFunName:"GetCredTypeToHUIJson",
		ListName:""
	},function(Data){
		var cbox = $HUI.combobox("#AppPatCredType", {
				valueField: 'id',
				textField: 'text', 
				editable:false,
				blurValidValue:true,
				data: JSON.parse(Data)
		 });
	});
}
function IsCredTypeID()
{
	var myval=$("#AppPatCredType").combobox("getValue");
	var myary = myval.split("^");
	if (myary[1]==PageLogicObj.m_IDCredTypePlate){
		return true;
	}else{
		return false;
	}
}
function InitCommonCardWin(){
	$("#CommonCardChoose").empty();
	retArry=ServerObj.CommonCardNoStr.split("&");
	htmlstr='<table class="search-table">';
	for (var i=0; i<retArry.length; i++){
		var CommoncardCardNo="'"+retArry[i]+"'"
		htmlstr=htmlstr+'<tr><td colSpan="" style="padding-left:10px;" ><a class="hisui-linkbutton" id="Commoncard'+retArry[i]+'" onclick="CommonCardclickRadio('+CommoncardCardNo+')" data-options="iconCls:\'icon-w-card\'" group="">'+retArry[i]+'</a></td></tr>'
	}
	htmlstr=htmlstr+'</table>';
	$("#CommonCardChoose").append(htmlstr);
	for (var i=0; i<retArry.length; i++) {
		$.parser.parse($("#Commoncard"+retArry[i]).parent())
	}
}
function CommonCardclickRadio(ChoseCommonCardNo){
	$('#CommonCardWin').window('close');	
	//如果存在一个卡号对应多个卡类型的情况,此处先选择卡类型
	var list=$.cm({
		ClassName:"DHCDoc.OPDoc.PatientList",
		MethodName:"GessCardType",
		//dataType:"text",
		cardValue:ChoseCommonCardNo
	},false)
	if ((!list)||(list.length==0)){
		$.messager.alert("提示","请维护公共卡.");       				
		return false;
	}
	if(list.length==1){
		CommonCardSetPatInfo(ChoseCommonCardNo, "");
		return false;
	}
	var id="CardTypeDialog";
	$("body").append("<div id='"+id+"' class='hisui-dialog'></div><span id='selCardTypeInfo'></span>");
	var tmplist="";
	for(var i=0,len=list.length;i<len;++i){
		var CardTypeId=list[i]["cardTypeId"];
		var cardDesc=list[i]["cardDesc"];
		var CardNo=list[i]["checkdValue"];
		var papmiNo=list[i]["papmiNo"];
		var SecurityNo=list[i]["SecurityNo"];
		if (tmplist=="") tmplist=CardTypeId+"^"+cardDesc+"^"+CardNo+"^"+papmiNo+"^"+SecurityNo;
		else  tmplist=tmplist+"!"+CardTypeId+"^"+cardDesc+"^"+CardNo+"^"+papmiNo+"^"+SecurityNo;
	}
	var src='opdoc.cardtypelist.csp?CardTypeList='+tmplist;
	if(typeof websys_writeMWToken=='function') src=websys_writeMWToken(src);
	$("#"+id).dialog({
		autoOpen : true,   // 是否自动弹出窗口
		title: "请选择卡类型",
		width: 400,
		height: 320,
		cache: false,
		iconCls: "icon-add-note",
		collapsible: false,
		minimizable:false,
		maximizable: false,
		resizable: false,
		modal: true,
		closed: true,
		closable: true,
		content:"<iframe id='CardTypeFrame' width='100%' height='98.7%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>",
		onClose:function(){
			var selCardInfo=$("#selCardTypeInfo").val();
			if (selCardInfo==""){
				return false;
			}
			var selCardInfoArr=selCardInfo.split("-"); //卡类型id-卡号-卡类型
			var SelectedCardType=selCardInfoArr[0];
			var SelectedCardNo=selCardInfoArr[1];
			var SecurityNo=selCardInfoArr[3];
			CommonCardSetPatInfo(SelectedCardNo, SelectedCardType);
		}
	});
	$("#"+id).dialog("open");
}

function CommonCardSetPatInfo(ChoseCommonCardNo, CardTypeDR) {
	if (!CardTypeDR) CardTypeDR="";
	var PatientNomyrtn=$.cm({
		ClassName:"web.DHCOPAdmReg",
		MethodName:"GetCommonCardNoandPatientNo",
		dataType:"text",
		ChoseCommonCardNo:ChoseCommonCardNo,
		CardTypeDR:CardTypeDR
	},false);
	if (PatientNomyrtn==""){
		$.messager.alert("提示","请维护公共卡.");       				
		return false;
	}else{
		var CardNo=PatientNomyrtn.split("^")[0]
		var PatientNo=PatientNomyrtn.split("^")[1];
		var CardTypeNew=PatientNomyrtn.split("^")[2];
		var PatInfoStr=$.cm({
			ClassName : "web.DHCOPAdmReg",
			MethodName : "GetPatDetailBroker",
			dataType:"text",
			itmjs:"",
			itmjsex:"GetPatDetailToHUI",
			val:PatientNo,
		},false);
		var Patdetail=PatInfoStr.split("^");
		$("#CardNo").val(CardNo);
		$("#CardTypeNew").val(CardTypeNew);
		$("#Name").val(Patdetail[0]);
		$("#Age").val(Patdetail[1]);
		$("#Sex").val(Patdetail[2]);
		//门诊病历号和住院病历号
		$("#OPMRN").val(Patdetail[3]);
		$("#IPMRN").val(Patdetail[4]);
		//医保号
		$("#PatYBCode").val(Patdetail[11]);
		//医保类型
		//$("YBType",Patdetail[12]);
		$("#PoliticalLevel").val(Patdetail[19]);
		$("#SecretLevel").val(Patdetail[20]);
		$("#TelH").val(Patdetail[21]);
		$("#PAPERCountry").val(Patdetail[22]);
		$("#Address").val(Patdetail[23]);
		var PatCat=Patdetail[5];
		$("#PatCat").val(PatCat);
		$("#PatientID").val(Patdetail[6]);
		$("#IDCardNo").val(Patdetail[7]);
		$("#PatientNo").val(Patdetail[9]);
		$("#AppBreakCount").val(Patdetail[10]);
		PatientID=Patdetail[6]
		if (PageLogicObj.m_curDayAppListDataGrid==""){
			PageLogicObj.m_curDayAppListDataGrid=curDayAppListDataGrid();
		}else{
			ClearAllTableData("curDayAppList");
		}
		PageLogicObj.m_PreCardNo=$("#CardNo").val();
		PageLogicObj.m_PreCardType=$("#CardTypeNew").val();
		PageLogicObj.m_PreCardLeaving=$("#CardLeaving").val();
		PageLogicObj.m_selectedMarkListDataGrid=InitselectedMarkListDataGrid();
		MarkListDBClick(PageLogicObj.CommonCardrow)
	}
}

function CheckHaveBlack(PatientID,IDCardNo){
	var BlackFlag=$.cm({
		ClassName:"web.DHCRBAppointment",
		MethodName:"GetLimitAppFlag",
		dataType:"text",
		PatientId:PatientID, IDCardNo:IDCardNo
	},false);
	var BlackFlag=BlackFlag.split("^")[0] //BlackFlag.split("^")[1]为有效日期 如有维护有效日期 可在此增加提示信息
	if (BlackFlag==1){
		 if (IDCardNo!="") $.messager.alert("提示","该证件号码存在违约记录,已被记入黑名单中。不允许预约!")
		 else $.messager.alert("提示","存在有效黑名单记录,不允许预约!")
		 return false
	}
	return true	
}
function RefreshSelMarkFee()
{
	var AdmReason=$('#BillType').combobox('getValue');
	var PatientID=$('#PatientID').val();
	var RegConDisId=$("#RegConDisList").combobox('getValue');
	var GroupID=session['LOGON.GROUPID'];

	var rows=$("#selectedMarkList").datagrid("getRows");
	for (var i=0;i<rows.length;i++){
		var row=rows[i];
		var ret=$.cm({
			ClassName:'web.DHCOPAdmReg',
			MethodName:'GetMarkRegFee',
			ASRowId:row.TabASRowId,
			BillTypeDR:AdmReason,
			PatientID:PatientID,
			AppMethodCode:'',
			RegConDisId:RegConDisId,
			GroupID:GroupID,
			ClinicGroupId:row.TabClinicGroupDr,
			dataType:'text'
		},false);
		var retArr=ret.split('^');
		var RegFee=row.TabFreeRegFlag=="Y"?0:retArr[11];
		var CheckFee=row.TabFreeCheckFlag=="Y"?0:retArr[13];
		var HoliFee=retArr[15];
		var AppFee=retArr[17];
		var ReCheckFee=retArr[14];
		var OtherFee=retArr[19];
		var TotalFee=parseFloat(HoliFee)+parseFloat(CheckFee)+parseFloat(RegFee)+parseFloat(AppFee)+parseFloat(OtherFee);
		$("#selectedMarkList").datagrid('updateRow',{
			index: i,
			row: {
				TabPrice:TotalFee,
				TabHoliFee:HoliFee,
				TabAppFee:AppFee,
				TabExamFee:CheckFee
			}
		});
	}
}
