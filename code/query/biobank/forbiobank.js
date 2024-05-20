var PageLogicObj={
	m_PatListTabDataGrid:"",
	m_FindFlag:0,
	m_PAAdmRowId:"",
	m_ConflictCehckStr:"", //"cOutStatus^cInStatus^cDisInStatus", lxz 医院要求门诊住院同时一起查询
	m_EpisodeID:"",
	m_PatientID:""
}
$(function(){
	//初始化
	Init();
	//事件初始化
	InitEvent();
	//页面元素初始化
	PageHandle();
	///$("#CardNo").focus();
	$("#PatNo").focus();
})
function PageHandle(){
	
	
	$("#Enddate").datebox('setValue',ServerObj.NowDate);
	$("#Startdate").datebox('setValue',ServerObj.FromDateHtml);
	
	//科室
	LoadDept(); 
	//医生
	LoadDoc();
	//病区
	LoadWard();
	//姓名
	IntNameLookUp();
	//诊断
	IntDiagnosisLookUp();
	//OPDocLogTabDataGridLoad();
	if ((session['LOGON.GROUPDESC']=='手术护士')){
		$("#PatMed").focus();
	}
	var frm=dhcsys_getmenuform();
	if (frm){
		PageLogicObj.m_EpisodeID=frm.EpisodeID.value;
		PageLogicObj.m_PatientID=frm.PatientID.value;
	}
	//lxz 门诊输液护士默认勾选
	if ((session['LOGON.GROUPDESC']=='门诊输液护士')||(session['LOGON.GROUPDESC']=='急诊治疗护士')){
		$("#cOutStatus").checkbox('setValue',true)
	}else{
		$("#cOutStatus").checkbox('setValue',true);
		$("#cInStatus").checkbox('setValue',true);
		$("#cDisInStatus").checkbox('setValue',true);
	}
	
		
	
	
	
}
function Init(){
	PageLogicObj.m_PatListTabDataGrid=InitPatListTabDataGrid();
}
function InitEvent(){
	$("#BFind").click(SearchFunLib);
	//$("#BReadCard").click(ReadCardClickHandle);
	$("#BClear").click(ClearFunLib);
	//$("#BPrint").click(PrintClickHandle);
	//$("#CardNo").change(CardNoChange);
	$HUI.checkbox(".hisui-checkbox",{
        onChecked:function(e,value){
            var id=e.currentTarget.id;
            chekboxChange(id);
        }
    });
    /*
    $('#PatNo').keyup(function(event){
        if(event.keyCode == 13) {
	        if (PatNo.length<8) {
				for (var i=(8-PatNo.length-1); i>=0; i--) {
					PatNo="0"+PatNo;
				}
			}
			$('#PatNo').val(PatNo);
          	SearchFunLib();
        }
    });
    */
	document.onkeydown = DocumentOnKeyDown;
}
function InitPatListTabDataGrid(){
	
	var toolbar=[{
			iconCls:'icon-reload',
			text:"更新出院医疗结算日期时间",
			handler:function(){UpdateDisChargeUp()}
	}]
	if ((session['LOGON.USERID']!='21061')&&(ServerObj.CanChange!="Y")){
		toolbar= []
	}
		
	var Columns=[[ 
				{field:'PatNo',title:'登记号',width:180,sortable:true},
                  {field:'PatName',title:'姓名',width:180,sortable:true},  
                  {field:'ChangeDate',title:'修改日期',width:180,sortable:true},
                  {field:'ChangeTime',title:'修改时间',width:180,sortable:true},
                  {field:'OldValue',title:'旧值',width:180,sortable:true},
                  {field:'NewValue',title:'新值',width:180,sortable:true}, 
                  {field:'UserId',title:'工号',width:180,sortable:true},  
                  {field:'IP',title:'IP地址',width:180,sortable:true},
                  {field:'PAPMIRowId',title:'PAPMIRowId',hidden:true} 
    ]]
	var PatListTabDataGrid=$("#mygrid").datagrid({
		url: $URL,
        queryParams:{
            ClassName:"web.DHCExamPatList",
            QueryName:"GetBioBankFlagLog",
        },
		fit : true,
		border : false,
		striped : true,
		singleSelect : true,
		fitColumns : false,
		autoRowHeight : false,
		pagination : true,  
		pageSize: 20,
		pageList : [20,100,200],
		columns :Columns,
		toolbar:toolbar
	});
	//PatListTabDataGrid.datagrid('loadData',{ 'total':'0',rows:[] });
	return PatListTabDataGrid;
}
function LoadDept(){
	$.cm({
		ClassName:"web.DHCExamPatList",
		QueryName:"ctloclookup",
	   	desc:"",
		rows:99999
	},function(GridData){
		var cbox = $HUI.combobox("#CTLoc", {
				valueField: 'ctlocid',
				textField: 'ctloc', 
				editable:true,
				data: GridData["rows"],
				filter: function(q, row){
					return (row["ctloc"].toUpperCase().indexOf(q.toUpperCase()) >= 0) ||(row["Alias"].toUpperCase().indexOf(q.toUpperCase()) >= 0);
				},
				onSelect: function(rec){  
					LoadDoc(); 
					LoadWard(); 
				},
				onChange:function(newValue,oldValue){
					if (newValue==""){
						LoadDoc();
						LoadWard();
					}
				}
		 });
	});
}
function LoadDoc(){
	$.cm({
		ClassName:"web.DHCExamPatList",
		QueryName:"FindDoc",
	   	LocId:$("#CTLoc").combobox('getValue'), DocDesc:"",
		rows:99999
	},function(GridData){
		var cbox = $HUI.combobox("#AdmDoc", {
				valueField: 'DocId',
				textField: 'DocDesc', 
				editable:true,
				data: GridData["rows"],
				filter: function(q, row){
					return (row["DocDesc"].toUpperCase().indexOf(q.toUpperCase()) >= 0)||(row["Alias"].toUpperCase().indexOf(q.toUpperCase()) >= 0);
				}
		 });
	});
}
function LoadWard(){
	var OFlag = $("#cOutStatus").checkbox('getValue');
	var LocId=$("#CTLoc").combobox('getValue');
	$.cm({
		ClassName:"web.DHCExamPatList",
		QueryName:"GetWardMessage",
		desc:"", luloc:LocId,
		rows:99999
	},function(GridData){
		var cbox = $HUI.combobox("#WardDesc", {
				valueField: 'HIDDEN', 
				textField: 'Ward', 
				//editable:true,
				data: GridData["rows"],
				filter: function(q, row){
					return (row["Ward"].toUpperCase().indexOf(q.toUpperCase()) >= 0) ||(row["Alias"].toUpperCase().indexOf(q.toUpperCase()) >= 0);
				},
				onLoadSuccess:function(){
					var data=$(this).combobox('getData');
					if ((data.length>0)&&(LocId!="")&&(!OFlag)){
						$(this).combobox('select',data[0]['HIDDEN']);
					}else{
						//SetDefaultWard();
					}
					
				}
		 });
		 if (OFlag) {
			 //cbox.disable();
		 } else {/*cbox.enable();*/}
	});
}
function SetDefaultWard(){
	var LocId=$("#CTLoc").combobox('getValue');
	if (LocId!=""){
		$("#WardDesc").combobox('select','');
		return;
	}
	var rtn=$.cm({
		ClassName:"web.DHCExamPatList",
		MethodName:"GetDefaultWard",
		PatNo:"", WardID:"", Name:"",
		dataType:"text"
	},false);
	if (rtn!=""){
		$("#WardDesc").combobox('setValue',rtn.split("^")[1]);
	}
}
function IntNameLookUp(){
	$("#Name").lookup({
        url:$URL,
        mode:'remote',
        method:"Get",
        idField:'PAAdmRowId',
        textField:'PatName',
        columns:[[  
            {field:'PAAdmRowId',title:'就诊号',width:80},
			{field:'PatNo',title:'登记号',width:100},
			{field:'PatName',title:'患者姓名',width:100,sortable:true},
			{field:'AdmDate',title:'就诊日期',width:100,sortable:true},
			{field:'AdmLoc',title:'就诊科室',width:110,sortable:true},
			{field:'AdmDoc',title:'就诊医生',width:110,sortable:true},
			{field:'PatSex',title:'性别',width:50,sortable:true}
        ]], 
        pagination:true,
        panelWidth:500,
        isCombo:true,
        minQueryLen:2,
        delay:'500',
        queryOnSameQueryString:true,
        //lxz 积水潭更换为只按照姓名检索 patnamelookup
        queryParams:{ClassName: 'web.DHCExamPatList',QueryName: 'PatNameLookUpNew'}, 
        onBeforeLoad:function(param){
	        var desc=param['q'];
	        if (desc=="") return false;
	        var OutStatus=$("#cOutStatus").checkbox('getValue')?'1':'';
		    var InStatus=$("#cInStatus").checkbox('getValue')?'1':'';
		    var DisInStatus=$("#cDisInStatus").checkbox('getValue')?'1':'';
			param = $.extend(param,{PatName:desc,StartDate:$("#Startdate").datebox('getValue'),EndDate:$("#Enddate").datebox('getValue'),OutStatus:OutStatus,InStatus:InStatus,DisInStatus:DisInStatus});
	    },
	    onSelect:function(index, row){
		    var PatNo=row['PatNo'];
		    $("#PatNo").val(PatNo);
		    PageLogicObj.m_PAAdmRowId=row['PAAdmRowId'];
		    if (PatNo!=""){
			    var value=$.cm({
					ClassName:"web.DHCExamPatList",
					MethodName:"PatListBroker",
					itmjs:"1", itmjsex:"", val:PatNo,
					dataType:"text"
				},false)
				SetPatient_Sel(value);
			}
		}
    });
}
function IntDiagnosisLookUp() {
	$("#Diagnosis").lookup({
        url:$URL,
        mode:'remote',
        method:"Get",
        idField:'HIDDEN',
        textField:'desc',
        columns:[[  
            {field:'desc',title:'诊断名称',width:300,sortable:true},
			{field:'code',title:'code',width:120,sortable:true},
			{field:'HIDDEN',title:'HIDDEN',width:120,sortable:true,hidden:true}
        ]],
        pagination:true,
        panelWidth:500,
        panelHeight:410,
        isCombo:true,
        minQueryLen:2,
        delay:'500',
        queryOnSameQueryString:true,
        queryParams:{ClassName: 'web.DHCMRDiagnos',QueryName: 'LookUpWithAlias'},
        onBeforeLoad:function(param){
	        var desc=param['q'];
	        var DiaType=""	//$HUI.combobox("#catType").getValue();
			param = $.extend(param,{desc:desc,ICDType:DiaType});
	    },onSelect:function(ind,item){
			
		}
    });	
}
function DocumentOnKeyDown(e){
	if (window.event){
		var keyCode=window.event.keyCode;
		var type=window.event.type;
		var SrcObj=window.event.srcElement;
	}else{
		var keyCode=e.which;
		var type=e.type;
		var SrcObj=e.target;
	}
	if (keyCode==13) {
		if(SrcObj && SrcObj.id.indexOf("CardNo")>=0){
			var CardNo=$('#CardNo').val();
			if (CardNo=="") return;
			var myrtn=DHCACC_GetAccInfo("",CardNo,"","","CardNoKeyDownCallBack");
			return false;
		}
		if(SrcObj && SrcObj.id.indexOf("PatNo")>=0){
			var PatNo=$('#PatNo').val();
			if (PatNo=="") return;
			//renyx 登记号位数由10改为8
			if (PatNo.length<8) {
				for (var i=(8-PatNo.length-1); i>=0; i--) {
					PatNo="0"+PatNo;
				}
			}
			$('#PatNo').val(PatNo);
			//FindPatDetail();
			SearchFunLib();
			return false;
		}
		if(SrcObj && SrcObj.id.indexOf("PatMed")>=0){
			FindPatByMedicare();
			return false;
		}
		return true;
	}
}
function FindPatDetail(){
	var PatNo=$('#PatNo').val();
	if (PatNo!=""){
		
		var inoldHis=$.cm({
		    ClassName : "web.DHCOPAdmRegLocal",
		    MethodName : "GetNewSystemStayIn",
		    PatNo:PatNo,
		    dataType:"text"
		},false);
		if (inoldHis=="1"){
			 dhcsys_alert("当前患者正在旧系统中入院,如有需要请前往旧HIS系统进行处理!");
			 dhcsys_alert("当前患者正在旧系统中入院,如有需要请前往旧HIS系统进行处理!");
			 dhcsys_alert("当前患者正在旧系统中入院,如有需要请前往旧HIS系统进行处理!");
		}
		
		
		var value=$.cm({
		    ClassName : "web.DHCExamPatList",
		    MethodName : "PatListBroker",
		    itmjs:"1", itmjsex:"", val:PatNo,
		    dataType:"text"
		},false);
		SetPatient_Sel(value);
	}
}
function SetPatient_Sel(value){
	if (value=="0"){
		return;
	}
	var Split_Value=value.split("^");
	/*if (unescape(Split_Value[3])!="") {
		$("#Startdate").datebox('disable').datebox('setValue','');
		$("#Enddate").datebox('disable').datebox('setValue','');
	} else {
		$("#Startdate").datebox('enable').datebox('setValue',ServerObj.NowDate);
		$("#Enddate").datebox('enable').datebox('setValue',ServerObj.NowDate);
	}*/
	$("#Name").val(unescape(Split_Value[0]));
	$("#Birth").val(unescape(Split_Value[1]));
	$("#Sex").val(unescape(Split_Value[2]));
	$("#PatMed").val(unescape(Split_Value[5]));
	$("#PatNo").val(unescape(Split_Value[3]));
	$("#PapmiDr").val(unescape(Split_Value[23]));
	var PatMed=$("#PatMed").val();
	if ((PatNo=="")&&(PatMed!="")){
		FindPatByMedicare();
	} 
	//PageLogicObj.m_PAAdmRowId="";
	PatListTabDataGridLoad();
	PageLogicObj.m_FindFlag=1;
}
function FindPatByMedicare(){
	var PatMed=$("#PatMed").val();
	var PatNoStr=$.cm({
	    ClassName : "web.DHCExamPatList",
	    MethodName : "GetPatInfoByInMedNo",
	    InMedNO:PatMed,
	    dataType:"text"
	},false);
	if (PatNoStr!=""){
		var Str=PatNoStr.split("^");
		if (Str.length>1){
			var url="websys.default.csp?WEBSYS.TCOMPONENT=DHCDocExamGetPatList&PatNoStr="+PatNoStr; 
	        var PatNo=window.showModalDialog(url,"","dialogwidth:50em;dialogheight:30em;center:1");
		    $("#PatNo").val(PatNo);
		    FindPatDetail();
		}else{
			$("#PatNo").val(Str[0]);
			FindPatDetail();
		}
	}
}
function ReadCardClickHandle(){
	DHCACC_GetAccInfo7(CardNoKeyDownCallBack);
}
function CardNoKeyDownCallBack(myrtn){
	var myary=myrtn.split("^");
	var rtn=myary[0];
	switch (rtn){
		case "0": 
			var PatientID=myary[4];
			var PatientNo=myary[5];
			var CardNo=myary[1];
    		$("#CardNo").val(CardNo);
    		$("#PatNo").val(PatientNo);
    		FindPatDetail();
			break;
		case "-200": 
			$.messager.alert("提示","卡无效!","info",function(){
				$("#CardTypeNew,#PatNo").val("");
				$("#CardNo").focus();
			});
			break;
		case "-201": 
			var PatientID=myary[4];
			var PatientNo=myary[5];
			var CardNo=myary[1];
    		$("#CardNo").val(CardNo);
    		$("#PatNo").val(PatientNo);
    		FindPatDetail();
			break;
		default:
			break;
	}
}
function CardNoChange(){
	var CardNo=$('#CardNo').val();
	if (CardNo==""){
		$("#PatientID,#CardTypeNew").val("");
	}
}
function BClearClickHandle(){
	$(".textbox").val('');
	$(".hisui-combobox").combobox('select','');
	//lxz 积水潭 默认不清空
	//$("#Startdate,#Enddate").datebox('setValue',ServerObj.NowDate);
	//$("#cOutStatus,#cInStatus,#cDisInStatus").checkbox('setValue',false);
	$("#Name").lookup('setText','');
	$("#PatMed").removeAttr("disabled");
	//$("#WardDesc").combobox('enable');
	PageLogicObj.m_PAAdmRowId="";
	PageLogicObj.m_PatListTabDataGrid.datagrid('loadData', {"total":0,"rows":[]});
	//setTimeout(function(){PatListTabDataGridLoad();});
}
function PrintClickHandle(){
	try {   
	    if (PageLogicObj.m_FindFlag==0){
		    $.messager.alert("提示","请先点击查找后再打印!");
		    return false;
		}
		var TemplatePath=$.cm({
			ClassName:"web.UDHCJFCOMMON",
			MethodName:"getpath",
			dataType:"text"
		},false);
		var Template=TemplatePath+"DHCExamPatList1.xls";
        var xlApp,xlsheet,xlBook
		//左右边距
	    xlApp = new ActiveXObject("Excel.Application");
	    xlBook = xlApp.Workbooks.Add(Template);
	    xlsheet = xlBook.ActiveSheet;
	    xlsheet.PageSetup.LeftMargin=15;  
	    xlsheet.PageSetup.RightMargin=0;
		//获取页面数据
		var ReturnValue=$.cm({
			ClassName:"web.DHCExamPatList",
			MethodName:"GetDHCExamPatListMessage",
			UserID:session['LOGON.USERID'], Flag:1, Row:"",
			dataType:"text"
		},false);
	    if (+ReturnValue==0){
		    $.messager.alert("提示","没有需要打印的数据!");
		    return false;
		}
		var myRows=ReturnValue;
		$.messager.confirm('确认对话框', '确定要打印信息?', function(r){
			if (r){
				var xlsrow=2; //用来指定模板的开始行数位置
				var xlsCurcol=0;  //用来指定开始的列数位置
				var NO=myRows/48
			    NO=parseInt(NO)+1;
				var Flag=1
				for (var Row=1;Row<=myRows;Row++){   
				    if (xlsrow==(50*Flag)){
					     Flag=Flag+1;
				         if(ServerObj.HospName!=""){
					        xlsheet.cells(1,1)=ServerObj.HospName+"患者查找单";
					     }else{
						    xlsheet.cells(1,1)="患者查找单";
						 }
						 xlsheet.PrintOut;
						 var xlsrow=2;
					     var xlsCurcol=0;
					     xlApp = new ActiveXObject("Excel.Application");
					     xlBook = xlApp.Workbooks.Add(Template);
					     xlsheet = xlBook.ActiveSheet; 
					     xlsheet.PageSetup.LeftMargin=15;  
				    	 xlsheet.PageSetup.RightMargin=0;
				    	
					}
					xlsrow=xlsrow+1; //从第三行开始
					//获取页面数据
					var StrData=$.cm({
						ClassName:"web.DHCExamPatList",
						MethodName:"GetDHCExamPatListMessage",
						UserID:session['LOGON.USERID'], Flag:2, Row:Row,
						dataType:"text"
					},false);
		            var DataValue=StrData.split("^")
		            xlsheet.cells(xlsrow,xlsCurcol+1)=Row;
		            xlsheet.cells(xlsrow,xlsCurcol+8)=DataValue[0]; //AdmDate 就诊日期
		            xlsheet.cells(xlsrow,xlsCurcol+9)=DataValue[1];//AdmTime 就诊时间
		            xlsheet.cells(xlsrow,xlsCurcol+11)=DataValue[2];//AdmDoC 医生
		            xlsheet.cells(xlsrow,xlsCurcol+7)=DataValue[3];//AdmReasoc 费别
		            xlsheet.cells(xlsrow,xlsCurcol+6)=DataValue[4];//AdmType  就诊类型
		            xlsheet.cells(xlsrow,xlsCurcol+12)=DataValue[5];//PAAdmWard 病区
		            xlsheet.cells(xlsrow,xlsCurcol+13)=DataValue[6];//PAAdmBed 病床
		            xlsheet.cells(xlsrow,xlsCurcol+10)=DataValue[7];//AdmDept 就诊科室
		            xlsheet.cells(xlsrow,xlsCurcol+3)=DataValue[12]; //病人ID
		            xlsheet.cells(xlsrow,xlsCurcol+2)=DataValue[13];//病案号
		            xlsheet.cells(xlsrow,xlsCurcol+14)=DataValue[10];//AdmDischgDate 出院日期
		            xlsheet.cells(xlsrow,xlsCurcol+4)=DataValue[14];// 病人姓名
		            xlsheet.cells(xlsrow,xlsCurcol+5)=DataValue[15]// 病人性别
		        }
		        if(ServerObj.HospName!=""){
			        xlsheet.cells(1,1)=ServerObj.HospName+"患者查找单";
			    }else{
				    xlsheet.cells(1,1)="患者查找单";
				}
				var d=new Date();
				var h=d.getHours();
				var m=d.getMinutes();
				var s=d.getSeconds()
			    xlsheet.PrintOut;
			    xlBook.Close (savechanges=false);
			    xlApp=null;
			    xlApp.Quit();
			    xlsheet=null;
			}
		});		
	} catch(e) {
		//alert(e.message);
	};
}
/*function PatListTabDataGridLoad(){
	$.cm({
	    ClassName : "web.DHCExamPatList",
	    QueryName : "RegFind",
	    UserID:session['LOGON.USERID'],
	    PatNo:$("#PatNo").val(),
	    OutStatus:$("#cOutStatus").checkbox('getValue')?'on':'',
	    InStatus:$("#cInStatus").checkbox('getValue')?'on':'',
	    DisInStatus:$("#cDisInStatus").checkbox('getValue')?'on':'',
	    Startdate:$("#Startdate").datebox('getValue'),
	    Enddate:$("#Enddate").datebox('getValue'),
	    WardID:$("#WardDesc").combobox('getValue'),
	    FindbyDoc:"",
	    CTLoc:$("#CTLoc").combobox('getText'),
	    WardDesc:$("#WardDesc").combobox('getText'),
	    PAAdmRowId:"", //PageLogicObj.m_PAAdmRowId //lxz 积水潭医院查询全部
	    luloc:$("#CTLoc").combobox('getValue'),
	    AdmDocId:$("#AdmDoc").combobox('getValue'),
	    RequestName:$("#Name").lookup('getText'),
	    RequestPatMed:RequestPatMed,	//$("#PatMed").val(), 
	    Pagerows:PageLogicObj.m_PatListTabDataGrid.datagrid("options").pageSize,
	    rows:99999
	},function(GridData){
		PageLogicObj.m_PatListTabDataGrid.datagrid({loadFilter:DocToolsHUI.lib.pagerFilter}).datagrid('loadData',GridData);
	});
}*/
function chekboxChange(id){
	var ConflictCehckArr=PageLogicObj.m_ConflictCehckStr.split("^");
	for (var i=0;i<ConflictCehckArr.length;i++){
		var tmpId=ConflictCehckArr[i];
		if (tmpId!=id){
			$("#"+tmpId).checkbox('setValue',false);
		}
	}
	if (id == "cOutStatus") {
		//lxz
		//$("#PatMed").attr("disabled","disabled").val("");
		//$("#WardDesc").combobox('setValue','').combobox('disable');
		
	}
	if ((id == "cInStatus")||(id == "cDisInStatus")) {
		//lxz
		//$("#PatMed").removeAttr("disabled");
		//$("#WardDesc").combobox('enable');
		
	}
}
function BPatBaseInfo(EpisodeID){
	var src="dhc.nurse.vue.mainentry.csp?ViewName=PatInfo&EpisodeID="+EpisodeID;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Find","患者基本信息", PageLogicObj.dw, PageLogicObj.dh,"icon-w-card","",$code,"");
}
function BAddPilotProPat(EpisodeID,PatientID){
	var src="docpilotpro.patadd.hui.csp?EpisodeID="+EpisodeID+"&PatientID="+PatientID;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("Find","加入科研项目", 1340, 600,"icon-w-add","",$code,"");
}
function WriteTimeToTXT(i){
	var writeStr;
	var userId=session['LOGON.USERID'];
	var myDate = new Date();
	var mytime=myDate.toLocaleTimeString()+":"+myDate.getMilliseconds();
	writeStr="时间:"+mytime;
	/*    
	object.OpenTextFile(filename[, iomode[, create[, format]]])    
	参数object必选项。object 应为 FileSystemObject 的名称。    
	filename必选项。指明要打开文件的字符串表达式。    
	iomode可选项。可以是三个常数之一：ForReading 、 ForWriting 或 ForAppending 。    
	create可选项。Boolean 值，指明当指定的 filename 不存在时是否创建新文件。如果创建新文件则值为 True ，如果不创建则为 False 。如果忽略，则不创建新文件。    
	format可选项。使用三态值中的一个来指明打开文件的格式。如果忽略，那么文件将以 ASCII 格式打开。    
	设置iomode 参数可以是下列设置中的任一种：    
	常数      值  描述    
	ForReading 1 以只读方式打开文件。不能写这个文件。    
	ForWriting 2 以写方式打开文件    
	ForAppending 8 打开文件并从文件末尾开始写。    
	format 参数可以是下列设置中的任一种：    
	值              描述    
	TristateTrue 以 Unicode 格式打开文件。    
	TristateFalse 以 ASCII 格式打开文件。    
	TristateUseDefault 使用系统默认值打开文件。 
	-2系统默认、-1以Unicode 格式、0以ASCII 格式   
	*/     
	var filePath="c://"+userId+"searchLog.txt";
	var objFSO = new ActiveXObject("Scripting.FileSystemObject");
	var objStream;
	if (!objFSO.FileExists(filePath)){    // 检查文件是否存在
   		objStream=objFSO.CreateTextFile(filePath,8,true);
	}else{
		objStream=objFSO.OpenTextFile(filePath,8,false,-1);
	}
	objStream.Write(writeStr+"----"+i+"\r\n");
   	objStream.Close();  // 关闭文件
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

//更新出院日期和时间
function UpdateDisChargeUp()
{

	var objselect=PageLogicObj.m_PatListTabDataGrid.datagrid('getSelected')
	if (!objselect){alert("请先选择患者的就诊信息!")}
	var AdmID=objselect.EpisodeID
	var url = "dhcdoc.updischargedate.hui.csp?EpisodeID="+AdmID
	var winName='updis'; 
	var awidth=400; 
	var aheight=400; 
	var atop=(screen.availHeight - aheight)/2;
	var aleft=(screen.availWidth - awidth)/2;
	var param0='scrollbars=0,status=0,menubar=0,resizable=2,location=0'; 
	var params='top=' + atop + ',left=' + aleft + ',width=' + awidth + ',height=' + aheight + ',' + param0 ;
	win=window.open(url,winName,params); 
	win.focus(); 	
	return
	
	
}
//查询方法
function SearchFunLib(){
	var PatNo=$("#PatNo").val();
	//var name=$('#TextDesc').val();
	$('#mygrid').datagrid('load',  { 
		ClassName:"web.DHCExamPatList",
		QueryName:"GetBioBankFlagLog" ,  
		'PatNo':PatNo
	});
	$('#mygrid').datagrid('unselectAll');
}

//重置方法
function ClearFunLib()
{
	$("#PatNo").val("");
	$('#mygrid').datagrid('load',  { 
		ClassName:"web.DHCExamPatList.cls",
		QueryName:"GetBioBankLog"
	});
	$('#mygrid').datagrid('unselectAll');
}
/*var init = function(){  
    var columns =[[  
                  {field:'RegNo',title:'登记号',width:180,sortable:true},
                  {field:'PatName',title:'姓名',width:180,sortable:true},  
                  {field:'ChangeDate',title:'修改日期',width:180,sortable:true},
                  {field:'ChangeTime',title:'修改时间',width:180,sortable:true},
                  {field:'OldValue',title:'旧值',width:180,sortable:true},
                  {field:'NewValue',title:'新值',width:180,sortable:true},    
                  {field:'PAPMIRowId',title:'PAPMIRowId',hidden:true} 
           ]];
    var mygrid = $HUI.datagrid("#mygrid",{
        url: $URL,
        queryParams:{
            ClassName:"web.DHCExamPatList",
            QueryName:"GetBioBankFlagLog"
        }, 
        columns: columns,  
        pagination: true,   //pagination    boolean 设置为 true，则在数据网格（datagrid）底部显示分页工具栏。
        pageSize:20,
        pageList:[20,40,60,80,100,200], 
        singleSelect:true, 
        rownumbers:true,    //设置为 true，则显示带有行号的列。
        fitColumns:true, //设置为 true，则会自动扩大或缩小列的尺寸以适应网格的宽度并且防止水平滚动 
    });
  
   //搜索回车事件
    $('#PatNo').keyup(function(event){
        if(event.keyCode == 13) {
          SearchFunLib();
        }
    });  
    //查询按钮
    $("#btnSearch").click(function(e) { 
         SearchFunLib();
     })  
     
    //重置按钮
    $("#btnRefresh").click(function (e) { 
         ClearFunLib();
     })  
    
    
     //查询方法
    function SearchFunLib(){
        var PatNo=$("#PatNo").val();
        //var name=$('#TextDesc').val();
        $('#mygrid').datagrid('load',  { 
            ClassName:"web.DHCExamPatList",
            QueryName:"GetBioBankFlagLog" ,  
            'PatNo':PatNo,   
            //'Name':name
        });
        $('#mygrid').datagrid('unselectAll');
    }
    
    //重置方法
    function ClearFunLib()
    {
        $("#PatNo").val("");
        $('#mygrid').datagrid('load',  { 
            ClassName:"web.DHCExamPatList.cls",
            QueryName:"GetBioBankLog"
        });
        $('#mygrid').datagrid('unselectAll');
    }
};
$(init);*/
