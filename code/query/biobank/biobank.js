var PageLogicObj={
	m_PatListTabDataGrid:"",
	m_LogStr:"",
	m_IDCredTypePlate:"01",
	dw:$(window).width()-400,
	dh:$(window).height()-100,
	m_PAPMINOLength:8,
	m_PatMasFlag:"",
	m_CardRegMustFillInArr:[],
	m_CardRegJumpSeqArr:[]
}
$(function(){
	//初始化
	Init();
	//事件初始化
	InitEvent();
	//页面元素初始化
	PageHandle();
	//$("#CardNo").focus();
	$("#SPAPERNo").focus();
	
})
$(window).load(function() {
	for (var i=0;i<PageLogicObj.m_CardRegMustFillInArr.length;i++){
		var id=PageLogicObj.m_CardRegMustFillInArr[i]['id'];
		$("label[for="+id+"]").addClass("clsRequired");
	}
});
function Init(){
	PageLogicObj.m_PatListTabDataGrid=InitPatListTabDataGrid();
}
function InitEvent(){
	//查询
	$('#BFind').click(FindPatList);
	//更新
	$("#BUpdate").click(BUpdateClickHandle);
	$("#CardNo").keydown(CardNoKeydown);
	$("#PatYBCode").keydown(InsuranceNoKeydown);
	$("#BReadCard").click(BReadCardClickHandle);
	$("#CredNo").keypress(PAPERIDkeypress);
	$("#SPAPERID").keydown(SPAPERIDkeydown);
	$("#SPAPERNo").keydown(SPAPERNokeydown);
	$("#SPAPERName").keydown(SPAPERNamekeydown);
	$("#EMail").blur(PAPEREmailOnblur);
	$("#Birth").blur(PAPERDobOnblur);
	$("#BirthTime").blur(BirthTimeOnblur);
	$("#BOtherCredType").click(OtherCredTypeInput);
	$("#ReadRegInfo").click(ReadRegInfoOnClick);
	//读医保卡
	$("#ReadInsuCard").click(ReadInsuCard);
	//读京医通卡
	if (JYTCardObjMain){JYTCardObjMain.ReadCardMangeInt(ReadJYTCard)}
	
	
	
	
	//lxz 病案号查找患者信息
	$("#IPMRN").keydown(function(e){
		var keycode = e.which;			
		if(keycode==13){		
			IPMRN_Find();
		}
	});
	$("#Birth").keydown(function(e){
		var keycode = e.which;			
		if(keycode==13){		
			PAPERDobOnblur();
		}
	});
	$("#IPMRN").keyup(function(e){if ($("#IPMRN").val()==""){$('#SPAPERNo').val('')}})
	$("#SPAPERNo").keyup(function(e){if ($("#SPAPERNo").val()==""){$('#IPMRN').val('')}})
	$('#Clear').click(Clear);
	
	
	//DisableBtn("ReadRegInfo",true);
	document.onkeydown = DocumentOnKeyDown;
}

function Clear()
{
	window.location.reload();
}

function PageHandle(){
	//证件类型
	LoadCredType();
	//病人类型
	LoadPatType();
	//婚姻
	LoadMarital();
	//病人级别
	LoadPoliticalLevel();
	//病人密级
	LoadSecretLevel();
	//合同单位
	LoadHCPDR();
	//民族
	LoadCTNation();
	//关系
	LoadCTRelation();
	//职业
	LoadVocation();
	//性别
	LoadSex();
	//生物标本库
	LoadBioBankFlag();
	//籍贯
	LoadCountry();
	///省
	LoadProvince(1); //1代表中国
	//本市/外埠
	LoadLocalFlag();
	//设备类型
	LoadIEType();
	//在岗状态
	LoadEmploymentStatus()
	
	InitPatRegConfig();
}


function LoadEmploymentStatus(){
	
	var cbox = $HUI.combobox("#EmploymentStatus",{
				valueField: 'id',
				textField: 'text', 
				editable:false,
				blurValidValue:true,
				data: JSON.parse($("#EmploymentStatus_Val").val()),
				onSelect:function(rec){
					
				}
	});
	return 
}

function IPMRN_Find()
{
		var IPMRN=$('#IPMRN').val(); //住院病案号
		if (IPMRN==""){return}
		var PatStr= $cm({
		ClassName:"web.DHCOPAdmRegLocal",
		MethodName:"GetPatNoAndIDByMrNum",
		dataType:"text",
		MRNum:IPMRN,
		},false);
		if (PatStr==""){dhcsys_alert("未找到病案号对应患者信息，请确认病案号是否正确？");return}
		try{BClearHandle()}catch(e){}
		var PatStrArry=PatStr.split("^")
		
		$("#SPAPERNo").val(PatStrArry[0])	
		FindPatList()	
	
}

function InitPatListTabDataGrid(){
	var Columns=[[ 
		{field:'TID',title:'',hidden:'true'},
		{field:'TPAPERID',title:'',hidden:'true'},
		{field:'TPAPMINo',title:'登记号',width:100,align:'left'},
		{field:'TPAPERName',title:'姓名',width:100,align:'left'},
		{field:'TPAPERSex',title:'性别',width:50,align:'left'},
		{field:'TPAPERAge',title:'年龄',width:50},
		{field:'TPAPERDob',title:'出生日期',width:100},   
		{field:'TPAPERSocialStatus',title:'患者类型',width:80},  
		{field:'TPAPMICardType',title:'证件类型',width:100},    
		{field:'TPAPMIDVAnumber',title:'证件号码',width:170}
    ]]
	var PatListTabDataGrid=$("#PatListTab").datagrid({
		fit : true,
		height:'100',
		border : false,
		striped : true,
		singleSelect : true,
		fitColumns : false,
		autoRowHeight : false,
		rownumbers:true,
		pagination : true,  
		pageSize: 20,
		pageList : [20,100,200],
		idField:'TID',
		columns :Columns,
		onSelect:function(index, row){
			SetSelPatInfo(row);
			DisableBtn("ReadRegInfo",false);
		},onBeforeUncheck:function(index, row){
			var oldSelRow=$(this).datagrid('getSelected');
			var oldSelIndex=$(this).datagrid('getRowIndex',oldSelRow);
			if (oldSelIndex==index){
				$(this).datagrid('unselectRow',index);
				ClearSelPat();
				DisableBtn("ReadRegInfo",true);
				return false;
			}
		},onLoadSuccess:function(data){
			if (data['rows'].length>0){
				$(this).datagrid('selectRow',0);
			}
		}
	}); 
	PatListTabDataGrid.datagrid('loadData',{ 'total':'0',rows:[] });
	return PatListTabDataGrid;
}
function FindPatList(){
	$.cm({
	    ClassName : "web.DHCBL.Patient.DHCPatient",
	    QueryName : "SelectByPAPERID",
	    SPAPERID:$("#SPAPERID").val(), SPAPERName:$("#SPAPERName").val(), SPAPMINo:$("#SPAPERNo").val(), CardNo:$("#CardNo").val(),
	    Pagerows:PageLogicObj.m_PatListTabDataGrid.datagrid("options").pageSize,rows:99999
	},function(GridData){
		PageLogicObj.m_PatListTabDataGrid.datagrid({loadFilter:DocToolsHUI.lib.pagerFilter}).datagrid('loadData',GridData);
	})
}
function ClearSelPat(){
	var SPAPERID=$("#SPAPERID").val();
	var SPAPERName=$("#SPAPERName").val();
	var CardNo=$("#CardNo").val();
	$(":input:text").val("");
	$(".hisui-combobox").combobox('select','');
	$("#SPAPERID").val(SPAPERID);
	$("#SPAPERName").val(SPAPERName);
	$("#CardNo").val(CardNo);
}
function SetSelPatInfo(row){
	$("#Age").val(row['TPAPERAge']);
	$("#Birth").val(row['TPAPERDob']);
	$("#CredNo").val(row['TPAPERID']);
	$("#Name").val(row['TPAPERName']);
	$("#TelHome").val(row['TPAPERTelH']);
	$("#ForeignName").val(row['TPAPERForeignId']);
	$("#EMail").val(row['TPAPEREmail']);
	$("#Allergy").val(row['TPAPMIAllergy']);
	$("#PAPERUpdateDate").val(row['TPAPERUpdateDate']);
	$("#Address").val(row['TPAPERForeignAddress']);
	$("#EmployeeNo").val(row['TEmployeeNo']);
	$("#ForeignPhone").val(row['TForeignPhone']);
	$("#BirthTime").timespinner('setValue',row['BirthTime']);
	$("#Company").val(row['TPAPERCompany']);
	$("#NationDescLookUpRowID").combobox('select',row['TPAPERNationDR']);
	$("#Sex").combobox('select',row['TPAPERSexDR']);
	$("#PatType").combobox('select',row['TPAPERSocialStatusDR']);
	var PatOccupationDR=row['TPAPEROccupationDR'];
	if (PatOccupationDR==0) PatOccupationDR="";
	$("#Vocation").combobox('select',PatOccupationDR);
	var data=$("#CredType").combobox("getData");
	for (var i=0;i<data.length;i++){
		var id=data[i]["id"];
		if (id.split("^")[0]==row['TPAPMICardTypeDR']){
			$("#CredType").combobox("select",data[i]["id"]);
			break;
		}
	}
	$("#CountryDescLookUpRowID").combobox('select',row['TPAPERCountryDR']);
	$("#ProvinceInfoLookUpRowID").combobox('select',row['TPAPERCTProvinceDR']);
	LoadCity(row['TPAPERCTProvinceDR'])
	$("#CityDescLookUpRowID").combobox('select',row['TPAPERCityCodeDR']);
	$("#ZipLookUpRowID").combobox('select',row['TPAPERZipDR']);
	$("#PoliticalLevel").combobox('select',row['TPoliticalLevel']);
	$("#SecretLevel").combobox('select',row['TSecretLevel']);
	$("#HCPDR").combobox('select',row['TPAPERHCPDR']);
	$("#CTRelationDR").combobox('select',row['TPAPERCTRLTDR']);
	$("#Sex").combobox('select',row['TPAPERSexDR']);
	$("#PAPERMarital").combobox('select',row['TPAPERMarital']);
	$("#BioBankFlag").combobox('select',row['TBioBankFlag']);
	GetOtherInform(row);
	PageLogicObj.m_LogStr=GetFormerStr();
}
function GetOtherInform(row){
	// 获取病案号,医保号等信息
	var PapmiNo=row['TPAPMINo']; 
	var OtherInformStr=$.cm({
		ClassName:"web.DHCBL.Patient.DHCPatientBuilder",
		MethodName:"GetOtherInform",
		PapmiNo:PapmiNo,
		dataType:"text"
	},false);
	var tmp=OtherInformStr.split("^");
	//门诊病历号(东)
	$("#EastOPMedicareNo").val(tmp[0]);
	//住院病历号(东)
	$("#EastIPMedicareNo").val(tmp[1]);
	//门诊病历号(西)
	$("#WestOPMedicareNo").val(tmp[2]);
	//住院病历号(西)
	$("#WestIPMedicareNo").val(tmp[3]);
	//医保号
	$("#PatYBCode").val(tmp[4]);
	//急诊病历号
	$("#EmgMedicare").val(tmp[6]);
    //本市/外埠 
    var data=$("#LocalFlag").combobox("getData");
	for (var i=0;i<data.length;i++){
		var text=data[i]["text"];
		if (tmp[5]==text){
			$("#LocalFlag").combobox("select",data[i]["id"]);
			break;
		}
	} 
	//其他证件
	tmp[7]=tmp[7].replace(/@/g,"^");
	$("#OtherCardInfo").val(tmp[7]);
	
	
	//设置照片信息
	$('#PhotoInfo').val(tmp[8])
	var PhotoInfo=$("#PhotoInfo").val();
	if (PhotoInfo!=""){
		var src="data:image/png;base64,"+PhotoInfo;
	}else{
		var src="";
	}
	ShowPicBySrcNew(src,"imgPic");
	
	//在岗状态
	$("#EmploymentStatus").combobox('select',tmp[9]);
	
	
	
		
	
}
//更新病人基本信息前的病人信息串
function GetFormerStr(){
	//出生日期	
	var UPPSbor=$("#Birth").val();	
	//病人类型		
 	var UPPSlx=$("#PatType").combobox('getValue'); 
 	var UPPSname=$('#Name').val();		
 	//门诊病历号(东)	
 	var UPPSEastopno=$('#EastOPMedicareNo').val();
 	//住院病历号(东)
 	var UPPSEastipno=$('#EastIPMedicareNo').val();	
 	//门诊病历号(东)
 	var UPPSWestopno=$('#WestOPMedicareNo').val();	
 	//门诊病历号(东)
 	var UPPSWestipno=$('#WestIPMedicareNo').val();	
 	var UPPSsex=$('#Sex').combobox('getValue'); 
 	var UPPSInsuranceNo=$('#PatYBCode').val();
 	//身份证号			
 	var UPPSIDCardNo=$('#CredNo').val();					
 	var UPPSNation=$('#NationDescLookUpRowID').combobox('getValue'); 
 	var UPPSOccupation=$('#Vocation').combobox('getValue'); 
 	var UPPSCompany=$("#Company").val();	
 	var UPPSAddress=$('#Address').val();					
 	var UPPSRelation=$('#ForeignName').val();				
 	var UPPSRelationship=$('#CTRelationDR').combobox('getValue'); 		
 	var UPPSTelH=$('#TelHome').val();				
 	var LogStr=UPPSbor+"^"+UPPSlx+"^"+UPPSname+"^"+UPPSsex+"^"+UPPSEastopno;
 	LogStr=LogStr+"^"+UPPSEastipno+"^"+UPPSWestopno+"^"+UPPSWestipno;
 	LogStr=LogStr+"^"+UPPSInsuranceNo+"^"+UPPSIDCardNo+"^"+UPPSNation+"^"+UPPSOccupation+"^"+UPPSCompany
 	LogStr=LogStr+"^"+UPPSAddress+"^"+UPPSRelation+"^"+UPPSRelationship+"^"+UPPSTelH
 	return LogStr
}
function LoadCredType(){

	//从CSP中加载数据
	var cbox = $HUI.combobox("#CredType", {
			valueField: 'id',
			textField: 'text',
			width:155,  
			editable:false,
			blurValidValue:true,
			data: JSON.parse($("#CredType_Val").val())
	 });

	
	/*
	$.m({
		ClassName:"web.UDHCOPOtherLB",
		MethodName:"ReadCredTypeExp",
		JSFunName:"GetCredTypeToHUIJson",
		ListName:""
	},function(Data){
		var cbox = $HUI.combobox("#CredType", {
				valueField: 'id',
				textField: 'text', 
				editable:false,
				blurValidValue:true,
				data: JSON.parse(Data)
		 });
	});
	*/
}
function LoadPatType(){
	
	var cbox = $HUI.combobox("#PatType", {
				valueField: 'id',
				textField: 'text',
				width:155,  
				//editable:false,
				blurValidValue:true,
				data: JSON.parse($("#PatType_Val").val()),
				filter: function(q, row){
					if (q=="") return true;
					if (row["text"].indexOf(q.toUpperCase())>=0) return true;
					var find=0;
					if (row["AliasStr"]!=""){
						for (var i=0;i<row["AliasStr"].split("^").length;i++){
							if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
								find=1;
								break;
							}
						}
					}
					if (find==1) return true;
					return false;
				}
		 });
	return 
	
	/*
	$.m({
		ClassName:"web.UDHCOPOtherLB",
		MethodName:"ReadPatType",
		JSFunName:"GetPatTypeToHUIJson",
		ListName:""
	},function(Data){
		var cbox = $HUI.combobox("#PatType", {
				valueField: 'id',
				textField: 'text', 
				//editable:false,
				blurValidValue:true,
				data: JSON.parse(Data),
				filter: function(q, row){
					if (q=="") return true;
					if (row["text"].indexOf(q.toUpperCase())>=0) return true;
					var find=0;
					if (row["AliasStr"]!=""){
						for (var i=0;i<row["AliasStr"].split("^").length;i++){
							if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
								find=1;
								break;
							}
						}
					}
					if (find==1) return true;
					return false;
				}
		 });
	});
	*/
}
function LoadMarital(){
	
var cbox = $HUI.combobox("#PAPERMarital", {
			valueField: 'id',
			textField: 'text',
			width:155,   
			//editable:false,
			blurValidValue:true,
			data: JSON.parse($("#Marital_Val").val()),
			filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if (row["AliasStr"]!=""){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			}
	 });
	return
	
	
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"CTMarital",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#PAPERMarital", {
				valueField: 'id',
				textField: 'text',
				width:155,   
				//editable:false,
				blurValidValue:true,
				data: JSON.parse(Data),
				filter: function(q, row){
					if (q=="") return true;
					if (row["text"].indexOf(q.toUpperCase())>=0) return true;
					var find=0;
					if (row["AliasStr"]!=""){
						for (var i=0;i<row["AliasStr"].split("^").length;i++){
							if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
								find=1;
								break;
							}
						}
					}
					if (find==1) return true;
					return false;
				}
		 });
	});
}
function LoadPoliticalLevel(){
	 var cbox = $HUI.combobox("#PoliticalLevel", {
			valueField: 'id',
			textField: 'text', 
			width:155,  
			editable:true,
			blurValidValue:true,
			data: JSON.parse($("#PoliticalLevel_Val").val())
	 });
	 return
	/*
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"PoliticalLevel",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#PoliticalLevel", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				blurValidValue:true,
				data: JSON.parse(Data)
		 });
	});
	*/
}
function LoadSecretLevel(){
	
	var cbox = $HUI.combobox("#SecretLevel", {
		valueField: 'id',
		textField: 'text', 
		width:155,  
		editable:true,
		blurValidValue:true,
		data: JSON.parse($("#SecretLevel_Val").val())
	});
	return 
	/*
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"SecretLevel",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#SecretLevel", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				blurValidValue:true,
				data: JSON.parse(Data)
		 });
	});
	*/
}
function LoadHCPDR(){
	
	var cbox = $HUI.combobox("#HCPDR", {
				valueField: 'id',
				textField: 'text', 
				width:155,  
				editable:true,
				blurValidValue:true,
				data: JSON.parse($("#HCPDR_Val").val())
	});
	return
	/*
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"HCPDR",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#HCPDR", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				blurValidValue:true,
				data: JSON.parse(Data)
		 });
	});
	*/
}
function LoadCTNation(){
	
	var cbox = $HUI.combobox("#NationDescLookUpRowID", {
			valueField: 'id',
			textField: 'text', 
			width:155,  
			editable:true,
			blurValidValue:true,
			data: JSON.parse($("#CTNATION_Val").val()),
			filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if (row["AliasStr"]!=""){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			}
	 });
	 return 
	/*
	
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"CTNATION",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#NationDescLookUpRowID", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				blurValidValue:true,
				data: JSON.parse(Data),
				filter: function(q, row){
					if (q=="") return true;
					if (row["text"].indexOf(q.toUpperCase())>=0) return true;
					var find=0;
					if (row["AliasStr"]!=""){
						for (var i=0;i<row["AliasStr"].split("^").length;i++){
							if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
								find=1;
								break;
							}
						}
					}
					if (find==1) return true;
					return false;
				}
		 });
	});
	*/
}
function LoadCTRelation(){
	
	var cbox = $HUI.combobox("#CTRelationDR", {
			valueField: 'id',
			textField: 'text',
			width:155,   
			editable:true,
			blurValidValue:true,
			data: JSON.parse($("#CTRelation_Val").val())
	 });
	 return
	 /*
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"CTRelation",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#CTRelationDR", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				blurValidValue:true,
				data: JSON.parse(Data)
		 });
	});
	*/
}
function LoadVocation(){
	
	var cbox = $HUI.combobox("#Vocation", {
			valueField: 'id',
			textField: 'text', 
			width:155,  
			editable:true,
			blurValidValue:true,
			data: JSON.parse($("#CTOCCUPATION_Val").val()),
			filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if (row["AliasStr"]!=""){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			}
	 });
	 return 
		 /*
	
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"CTOCCUPATION",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#Vocation", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				blurValidValue:true,
				data: JSON.parse(Data),
				filter: function(q, row){
					if (q=="") return true;
					if (row["text"].indexOf(q.toUpperCase())>=0) return true;
					var find=0;
					if (row["AliasStr"]!=""){
						for (var i=0;i<row["AliasStr"].split("^").length;i++){
							if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
								find=1;
								break;
							}
						}
					}
					if (find==1) return true;
					return false;
				}
		 });
	});
	*/
}
function LoadBioBankFlag() {
	var data = '[{"id":"Y","text":"Y"},{"id":"N","text":"N"}]';
	var cbox = $HUI.combobox("#BioBankFlag", {
			valueField: 'id',
			textField: 'text', 
			width:155,  
			//editable:false,
			blurValidValue:true,
			data: JSON.parse(data),
			/*filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if ((row["AliasStr"])&&(row["AliasStr"]!="")){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			}*/
	 });
}
function LoadSex(){
	
	var cbox = $HUI.combobox("#Sex", {
			valueField: 'id',
			textField: 'text', 
			width:155,  
			//editable:false,
			blurValidValue:true,
			data: JSON.parse($("#Sex_Val").val()),
			filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if ((row["AliasStr"])&&(row["AliasStr"]!="")){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			}
	 });
	 return
	
	/*
	$.m({
		ClassName:"web.UDHCOPOtherLB",
		MethodName:"ReadSex",
		JSFunName:"GetSexToHUIJson",
		ListName:""
	},function(Data){
		var cbox = $HUI.combobox("#Sex", {
				valueField: 'id',
				textField: 'text', 
				//editable:false,
				blurValidValue:true,
				data: JSON.parse(Data),
				filter: function(q, row){
					if (q=="") return true;
					if (row["text"].indexOf(q.toUpperCase())>=0) return true;
					var find=0;
					if ((row["AliasStr"])&&(row["AliasStr"]!="")){
						for (var i=0;i<row["AliasStr"].split("^").length;i++){
							if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
								find=1;
								break;
							}
						}
					}
					if (find==1) return true;
					return false;
				}
		 });
	});
	*/
}
function LoadCountry(){
	
	var cbox = $HUI.combobox("#CountryDescLookUpRowID", {
			valueField: 'id',
			textField: 'text', 
			width:155,  
			editable:true,
			//blurValidValue:true,
			data: JSON.parse($("#CTCOUNTRY_Val").val()),
			filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if (row["AliasStr"]!=""){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			},
			onSelect:function(rec){
				if (!rec) return;
				var id=$(this).combobox("getValue");
				//LoadProvince(id);
				LoadZip();
			},onLoadSuccess:function(){
				$("#CountryDescLookUpRowID,#ZipLookUpRowID").combobox("select","");
			}
	 });
	 return 
	 
	
	/*
	
	$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		TabName:"CTCOUNTRY",
		QueryInfo:"^^^HUIJSON"
	},function(Data){
		var cbox = $HUI.combobox("#CountryDescLookUpRowID", {
				valueField: 'id',
				textField: 'text', 
				editable:true,
				//blurValidValue:true,
				data: JSON.parse(Data),
				filter: function(q, row){
					if (q=="") return true;
					if (row["text"].indexOf(q.toUpperCase())>=0) return true;
					var find=0;
					if (row["AliasStr"]!=""){
						for (var i=0;i<row["AliasStr"].split("^").length;i++){
							if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
								find=1;
								break;
							}
						}
					}
					if (find==1) return true;
					return false;
				},
				onSelect:function(rec){
					if (!rec) return;
					var id=$(this).combobox("getValue");
					LoadProvince(id);
					LoadZip();
				},onLoadSuccess:function(){
					$("#CountryDescLookUpRowID,#ZipLookUpRowID").combobox("select","");
				}
		 });
	});
	*/
}
function LoadProvince(CountryId){
	var Data=$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		dataType:"text",
		TabName:"CTProvince",
		QueryInfo:CountryId+"^^^HUIJSON"
	},false);
	var cbox = $HUI.combobox("#ProvinceInfoLookUpRowID", {
			valueField: 'id',
			textField: 'text', 
			editable:true,
			//blurValidValue:true,
			data: JSON.parse(Data),
			filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if (row["AliasStr"]!=""){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			},
			onSelect:function(rec){
				//加载市信息
				var id=$(this).combobox("getValue");
				LoadCity(id);
				LoadZip();
			}
	 });
}
function LoadCity(ProvinceId){
	var Data=$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		dataType:"text",
		TabName:"CTCITY",
		QueryInfo:ProvinceId+"^^^HUIJSON"
	},false);
	var cbox = $HUI.combobox("#CityDescLookUpRowID", {
			valueField: 'id',
			textField: 'text', 
			editable:true,
			//blurValidValue:true,
			data: JSON.parse(Data),
			filter: function(q, row){
				if (q=="") return true;
				if (row["text"].indexOf(q.toUpperCase())>=0) return true;
				var find=0;
				if (row["AliasStr"]!=""){
					for (var i=0;i<row["AliasStr"].split("^").length;i++){
						if (row["AliasStr"].split("^")[i].indexOf(q.toUpperCase()) >= 0){
							find=1;
							break;
						}
					}
				}
				if (find==1) return true;
				return false;
			},
			onSelect:function(rec){
				LoadZip();
			},onLoadSuccess:function(){
				$("#CityDescLookUpRowID").combobox('select','');
			}
	 });
}
function LoadZip(){
	var ProvinceId=getComValue("ProvinceInfoLookUpRowID");
	var CityDR=getComValue("CityDescLookUpRowID");
	if (CityDR!="") ProvinceId="";
	var CityAreaDR=""
	var Data=$.m({
		ClassName:"web.DHCBL.CTBASEIF.ICTCardRegLB",
		MethodName:"ReadBaseData",
		dataType:"text",
		TabName:"CTZIP",
		QueryInfo:ProvinceId+"^"+CityDR+"^"+CityAreaDR+"^HUIJSON"
	},false);
	var cbox = $HUI.combobox("#ZipLookUpRowID", {
			valueField: 'id',
			textField: 'text', 
			editable:false,
			blurValidValue:true,
			data: JSON.parse(Data),
			onSelect:function(rec){
				//LoadZip();
			}
	 });
}
function LoadLocalFlag(){
	var cbox = $HUI.combobox("#LocalFlag", {
			valueField: 'id',
			textField: 'text', 
			editable:true,
			blurValidValue:true,
			data: [{"id":"1","text":"本市"},{"id":"2","text":"外埠"}]
	 });
}
function BUpdateClickHandle(){
	/*
	var rtn=CheckNull();
    if (!rtn){return false;}
    var Rtn=CheckMedNo();              
    if (!Rtn){return false;}           
    var YBflag=checkPatYBCode();
	if(YBflag==false){return false;}
	var returnvalue=UpdateOtherInform();
	if (returnvalue!=0) {
		$.messager.alert("提示","更新失败");
		return false;
	}
	*/
	var row=PageLogicObj.m_PatListTabDataGrid.datagrid('getSelected');
	if(!row){
		$.messager.alert("提示","请选择一条记录!");
		return false;	
	}
	var BioBankFlag = $("#BioBankFlag").combobox("getValue");
	var row=PageLogicObj.m_PatListTabDataGrid.datagrid('getSelected');
	//构造服务端解析对象
	var ParseInfo=["PAPMIRowID="+row['TID'],
	                //"PAPERCityAreaDR=",
	                "CityDescLookUpRowID="+getComValue("CityDescLookUpRowID"),
	                "CountryDescLookUpRowID="+getComValue("CountryDescLookUpRowID"),
	                "ProvinceInfoLookUpRowID="+getComValue("ProvinceInfoLookUpRowID"),
	                "Birth="+$("#Birth").val(),
	                //"PAPEREducationDR=",
	                "EMail="+$("#EMail").val(),
	                "CredNo="+$('#CredNo').val(),
	                "Name="+$("#Name").val(),
	                "NationDescLookUpRowID="+getComValue("NationDescLookUpRowID"),
	                "Vocation="+getComValue("Vocation"),
	                "Sex="+getComValue("Sex"),
	                "PatType="+getComValue("PatType"),
	                ///"PAPERStName=",
	                "TelHome="+$("#TelHome").val(),
	                "ZipLookUpRowID="+getComValue("ZipLookUpRowID"),
	                "Allergy="+$("#Allergy").val(),
	                "TelHome="+$("#TelHome").val(),
	                "ForeignName="+$("#ForeignName").val(),
	                "CTRelationDR="+getComValue("CTRelationDR"),
	                "Address="+$("#Address").val(),
	                "CredType="+getComValue("CredType"),
	                "EmployeeNo="+$("#EmployeeNo").val(),
	                "PAPERMarital="+getComValue("PAPERMarital"),
					"PoliticalLevel="+getComValue("PoliticalLevel"),
	                "SecretLevel="+getComValue("SecretLevel"),
					"HCPDR="+getComValue("HCPDR"),
	                "OtherCardInfo="+$("#OtherCardInfo").val(),
	                "ForeignPhone="+$("#ForeignPhone").val(),       //联系人电话;
	                "PatYBCode="+$("#PatYBCode").val(),       //医保号
	                "Company="+$("#Company").val(),       //工作单位
	                "BirthTime="+$("#BirthTime").timespinner('getValue'),
	                "PhotoInfo="+$("#PhotoInfo").val(),       //照片信息
					"EmploymentStatus="+getComValue("EmploymentStatus"),       //在岗状态
					"BioBankFlag="+BioBankFlag
	                 ]       //工作单位
	var PAPerson=GetEntityClassInfoToXML(ParseInfo);
	
	var returnvalue=$.cm({
	    ClassName : "web.DHCBL.Patient.DHCPatientBuilder",
	    MethodName : "DHCPatientUpdate",
	    PAPersonInfo:PAPerson,
	    NullNotUpdate:"Y", //lxz 增加为空不进行保存标志
	    dataType:"text"
	},false);
	if(returnvalue=='0'){
		$.messager.alert("提示","更新成功!","info",function(){
			FindPatList();
			//如果是从挂号界面打开的则当更新完就关闭此界面
			var cardno=$("#CardNo").val();
			if (window.name=="QueryReg"){
				var Parobj=window.opener
				var objCardNo=Parobj.document.getElementById("CardNo")
				if (objCardNo) objCardNo.value=cardno;
				window.close();
				//Parobj.websys_setfocus('CardNo');
			}
		});
		
		//lxz 
		var rtnadmflag = $cm({
		ClassName:"web.DHCOPAdmRegLocal",
		MethodName:"CheckNowAdm",
		dataType:"text",
		PatDr:row['TID'],
		},false);
		if (rtnadmflag=="Y"){
			dhcsys_alert("请注意患者有当日的挂号就诊记录！")
		}
		
		
		
		//lxz 特病有效期
		OpenSpecil(row['TID'])
		
	}else{
		$.messager.alert("提示","更新失败!");
		return false;
	}
	
}
//验证必填字段
function CheckNull(){
	var row=PageLogicObj.m_PatListTabDataGrid.datagrid('getSelected');
	if(!row){
		$.messager.alert("提示","请选择一条记录!");
		return false;	
	}
	
	var myPatType= $("#PatType").combobox('getText');
	if (PageLogicObj.m_PatMasFlag=="Y"){
		var IsNullInfo="",FocusName="";
		//必填项目验证
		var myrtn=true;
		for (var i=0;i<PageLogicObj.m_CardRegMustFillInArr.length;i++){
			var id=PageLogicObj.m_CardRegMustFillInArr[i]['id'];
			var text=PageLogicObj.m_CardRegMustFillInArr[i]['text'];
			var val=getValue(id);
			if (id=="CardNo"){continue}
			if ((id=="TelHome")&&(myPatType.indexOf("本院")>=0)){continue}
			if (val==""){
				if (IsNullInfo=="") IsNullInfo=text,FocusName=id;
				else  IsNullInfo=IsNullInfo+" , "+text;
				
			}
		}
		if (IsNullInfo!=""){
			$.messager.alert("提示","请输入<font color=red>"+IsNullInfo+"</font> !","info",function(){
				setFocus(FocusName)
			});
			return false;
		}
	}
	
	//验证患者信息(姓名、性别、出生日期、联系电话)是否存在一致的患者
	if (!PatInfoUnique(row['TID'])) {
		return false;
	}
	var PAPERDob=$("#Birth").val();
	if (PAPERDob=="") {
		$.messager.alert("提示","请输入出生日期","info",function(){
			$("#Birth").focus();
		});
	 	return false;
	}
	if ($('#Name').val()==""){
		$.messager.alert("提示","患者姓名不能为空!","info",function(){
			$("#Name").focus();
		});
		return false;
	}	
    var sexDr=getComValue("Sex") //$("#LookPAPERSexDR").combobox('getValue');
	if (sexDr==""){
		$.messager.alert("提示","患者性别不能为空!","info",function(){
			$("#Sex").focus();
		});
		return false;
	}
	var PAPERID=$("#CredNo").val();
	if (PAPERID==""){	
		var PAPERAge=$('#Age').val();
		if (PAPERAge.indexOf("岁")!="-1"){
			PAPERAge=PAPERAge.split("岁")[0];
		}else{
			PAPERAge=0;
		}
		var AgeAllow=$.cm({
		    ClassName : "web.DHCDocConfig",
		    MethodName : "GetDHCDocCardConfig",
		    Node:"AllowAgeNoCreadCard",
		    dataType:"text"
		},false);
		/*var FlagNoCread=$.cm({
		    ClassName : "web.DHCDocConfig",
		    MethodName : "GetDHCDocCardConfig",
		    Node:"NOCREAD",
		    dataType:"text"
		},false);*/
		var myval=$("#CredType").combobox("getValue");
		var myCredTypeDR = myval.split("^")[0];
		var CredNoRequired=$.cm({
			ClassName:"web.DHCBL.CARD.UCardRefInfo",
			MethodName:"CheckCardNoRequired",
			dataType:"text",
			CredTypeDr:myCredTypeDR
		},false)
		if (CredNoRequired=="Y"){
		    if ((AgeAllow!="")&&(parseFloat(+PAPERAge)<=parseFloat(AgeAllow))){
			}else{
				$.messager.alert("提示","请填写证件号码","info",function(){
					$("#CredNo").focus();
				});
				return false;
			}
		}
		if (parseFloat(+PAPERAge) < ServerObj.ForeignInfoByAge) {
			    var ForeignName = $("#ForeignName").val();
				var ForeignPhone = $("#ForeignPhone").val();
				if (ForeignName == "") {
					$.messager.alert("提示","年龄小于"+ServerObj.ForeignInfoByAge+"岁,联系人不能为空","info",function(){
						$("#ForeignName").focus();
					});
					return false;
				}
				if (ForeignPhone==""){
					$.messager.alert("提示","年龄小于"+ServerObj.ForeignInfoByAge+"岁,联系人电话不能为空!","info",function(){
						$("#ForeignPhone").focus();
					});
					return false;
				}
				if (ForeignPhone!=""){
					if (!CheckTelOrMobile(ForeignPhone,"ForeignPhone","联系人")) return false;
			    }
		}
	}else{
		var PAPERID=$("#CredNo").val();
		var OtherCardInfo=$("#OtherCardInfo").val();
		if (OtherCardInfo!=""){
			var PAPMICardTypeDR="";
			var PAPMICardType=getComValue("CredType"); 
			if (PAPMICardType!=""){
				var PAPMICardTypeDR=PAPMICardType.split("^")[0];
			}
			var CredTypeDesc=$("#CredType").combobox('getText');
			for (var i=0;i<OtherCardInfo.split("!").length;i++){
				var tmpCardTypeRowid=OtherCardInfo.split("!")[i].split("^")[0];
				var tmpCredNo=OtherCardInfo.split("!")[i].split("^")[1];
				if (tmpCardTypeRowid==PAPMICardTypeDR){
					if ((tmpCredNo!=PAPERID)&&(tmpCredNo!="")){
						$.messager.alert("提示","证件类型:"+CredTypeDesc+"对应的证件号码和其他证件对应的号码不一致!","info",function(){
							$("#CredNo").focus();
						});
						return false;
					}
				}
			}
		}
	}	
	var myIDNo = $("#CredNo").val();
	myIDNo=myIDNo.toUpperCase();
	if (myIDNo!=""){
		var myIDrtn=IsCredTypeID();
		if (myIDrtn){
			var myExpstr=myIDNo;
			var myPatInfo=$.cm({
			    ClassName : "web.DHCBL.CARD.UCardPaPatMasInfo",
			    MethodName : "GetPatInfoByPANo",
			    PAPMINo:"", ExpStr:myExpstr,
			    dataType:"text"
			},false);
			var myary=myPatInfo.split("^");
			var myXMLStr=myary[1];
			var tmpPatientID=myXMLStr.split("<PAPMIRowID>")[1].split("</PAPMIRowID>")[0];
			/*
			if ((tmpPatientID!="")&&(tmpPatientID!=row["TID"])){
				$.messager.alert("提示","身份证号:"+myIDNo+"已被其他患者注册!请核实!","info",function(){
					$("#CredNo").focus();
				});
				//return false;
			}
			*/
			var myIsID=DHCWeb_IsIdCardNo(myIDNo);
			if (!myIsID){
				$("#CredNo").focus();
				return false;
			}
			var IDBirthday=DHCWeb_GetInfoFromId(myIDNo)[2];
			var myBirth=$("#Birth").val();
			if (myBirth!=IDBirthday){
				$.messager.alert("提示","出生日期与身份证号不符!","info",function(){
					$("#Birth").focus();
				});
	   		    return false;
			}
			//验证身份证中的性别
			var Sex=$("#Sex").combobox('getText'); //getComValue("LookPAPERSexDR");
			var IDNoInfoStr=DHCWeb_GetInfoFromId(myIDNo);
			var IDSex=IDNoInfoStr[3]
			if(Sex!=IDSex){
				$.messager.alert("提示","身份证号:"+myIDNo+"对应的性别是【"+IDSex+"】,请选择正确的性别!","info",function(){
					$('#Sex').next('span').find('input').focus();
				})
				return false;
			}
		}else{
			var PAPMICardTypeDR="";
			var PAPMICardType=getComValue("CredType"); 
			if (PAPMICardType!=""){
				var PAPMICardTypeDR=PAPMICardType.split("^")[0];
			}
			var mySameFind=$.cm({
			    ClassName : "web.DHCBL.CARD.UCardPaPatMasInfo",
			    MethodName : "CheckCredNoIDU",
			    PatientID:row["TID"], CredNo:myIDNo, CredTypeDR:PAPMICardTypeDR,
			    dataType:"text"
			},false);
			if (mySameFind=="1"){
				$.messager.alert("提示","此证件号码已经被使用!","info",function(){
					$("#CredNo").focus();
				})
				return false;
			}
		}
	}
	//对于病人类型为本院职工的对工号的判断
	var myPatType= $("#PatType").combobox('getText');
	if (myPatType.indexOf('本院')>=0){
		var EmployeeNo=$("#EmployeeNo").val();
		/*if (EmployeeNo==""){
			$.messager.alert("提示","请录入工号!","info",function(){
				$("#EmployeeNo").focus();
			});
			return false;
		}*/
		if (EmployeeNo==""){
			var rtn=dhcsys_confirm("本院职工工号为空，是否继续")
			if (rtn){
				return true;
				}else{
				return false;	
					}
							
		}			
		var curPAPMIRowID=$.cm({
		    ClassName : "web.DHCBL.CARDIF.ICardPaPatMasInfo",
		    MethodName : "GetPAPMIRowIDByEmployeeNo",
		    EmployeeNo:EmployeeNo,
		    dataType:"text"
		},false);
		var name=curPAPMIRowID.split("^")[1];
		var UserName=curPAPMIRowID.split("^")[2];
		curPAPMIRowID=curPAPMIRowID.split("^")[0];
		if (curPAPMIRowID=="0"){
			$.messager.alert("提示","工号不正确,请核实工号!","info",function(){
				$("#EmployeeNo").focus();
			});
			return false;
		}
		var Name=$("#Name").val();
		if ((EmployeeNo!="")&&(UserName!=Name)){
			$.messager.alert("提示","此工号对应姓名为'"+UserName+"'和所录入姓名不一致","info",function(){
				$("#Name").focus();
			});
			return false;
		}
		var PAPMIRowID=row["TID"];
		if ((EmployeeNo!="")&&((PAPMIRowID!=curPAPMIRowID)&&(curPAPMIRowID!=""))){
			$.messager.alert("提示","此工号已经被'"+name+"'所用,请首先核实工号","info",function(){
				$("#EmployeeNo").focus();
			});
			return false;
		}
	}else{
		var EmployeeNo=$("#EmployeeNo").val();
		if (EmployeeNo!=""){
			$.messager.alert("提示","非本院职工工号不可填写!","info",function(){
				$("#EmployeeNo").focus();
			});
			return false;
		}
	} 
	var myBirthTime=$("#BirthTime").timespinner('getValue');
	if (myBirthTime!=""){
		 var regTime = /^([0-2][0-9]):([0-5][0-9]):([0-5][0-9])$/;
		 if (!regTime.test(myBirthTime)) {
			$.messager.alert("提示","请输入正确的出生时间!","info",function(){
				$("#BirthTime").focus();
			});
			 return false;
		 }
	}
	if(CheckBirthAndBirthTime()){
		$.messager.alert("提示","出生日期是当天的,出生时间不能大于当前时间,请核实!","info",function(){
				$("#BirthTime").focus();
		});
		return false;
	}
	var myTelHome=$("#TelHome").val();
    if ((myTelHome=="")&&(myPatType.indexOf('本院')<0)){
		$.messager.alert("提示","联系电话不能为空!","info",function(){
			$("#TelHome").focus();
		});
		return false;
	}else{
		if (!CheckTelOrMobile(myTelHome,"TelHome","")) return false;
	}
	var MyForeignPhone=$("#ForeignPhone").val();
	if (MyForeignPhone!=""){
		if (!CheckTelOrMobile(MyForeignPhone,"ForeignPhone","联系人")) return false;
	}
	return true;
}
function IsCredTypeID(){
	var myval=$("#CredType").combobox("getValue");
	var myary = myval.split("^");
	if (myary[1]==PageLogicObj.m_IDCredTypePlate){
		return true;
	}else{
		return false;
	}
}
function CheckBirthAndBirthTime(){
	var Today=new Date();
	var mytime=Today.getHours(); 
	var CurMinutes= Today.getMinutes();
	if (CurMinutes<=9){
		CurMinutes="0"+CurMinutes;
	}
	mytime=mytime+":"+CurMinutes;
	var CurSeconds= Today.getSeconds();
	if (CurSeconds<=9){
		CurSeconds="0"+CurSeconds;
	}
	mytime=mytime+":"+CurSeconds;
	var Today=getNowFormatDate();
	var myBirth=$("#Birth").val();
	if(myBirth==Today){
		var BirthTime=$("#BirthTime").timespinner('getValue');
		if(BirthTime!=""){
			if(BirthTime.split(":").length==2){
				BirthTime=BirthTime+":00";
			}
		}
		BirthTime=BirthTime.replace(/:/g,"");
		mytime=mytime.replace(/:/g,"");
		if(parseInt(BirthTime)>parseInt(mytime)){
			return true;
		}else{
			return false;
		}
	}
    var myBirth=myparser(myBirth);
    var Today=myparser(Today); 
	if (myBirth>Today) return true;
	return false;
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
function CheckTelOrMobile(telephone,Name,Type){
	if (telephone.length==8) return true;
	if (DHCC_IsTelOrMobile(telephone)) return true;
	if (telephone.indexOf('-')>=0){
		$.messager.alert("提示",Type+"固定电话长度错误,固定电话区号长度为【3】或【4】位,固定电话号码长度为【7】或【8】位,并以连接符【-】连接,请核实!","info",function(){
			$("#"+Name).focus();
		});
        return false;
	}else{
		if(telephone.length!=11){
			$.messager.alert("提示",Type+"联系电话电话长度应为【11】位,请核实!","info",function(){
				$("#"+Name).focus();
			});
	        return false;
		}else{
			$.messager.alert("提示",Type+"不存在该号段的手机号,请核实!","info",function(){
				$("#"+Name).focus();
			});
	        return false;
		}
	}
	return true;
}
function CheckMedNo(){
	var row=PageLogicObj.m_PatListTabDataGrid.datagrid('getSelected');
	var PapmiDr=row['TID'];
	//医保手册号
	var InsuNo=$("#PatYBCode").val();
	if ((InsuNo!="")&&(InsuNo!="99999999999S")) {
		var Rtn=$.cm({
		    ClassName : "web.DHCBL.Patient.DHCPatient",
		    MethodName : "PatUniInfoQuery",
		    PatientDr:PapmiDr, Type:"InsuNo", NoStr:InsuNo,
		    dataType:"text"
		},false);
		if(Rtn>0){	
			$.messager.alert("提示","医保手册号重复,可在医保号处回车查看已使用此医保号患者!","info",function(){
				$("#PatYBCode").focus();
			})
			return false
		}
	}
	//西院住院病历号
	var WIPMedNo=$("#WestIPMedicareNo").val();
	if (WIPMedNo!=""){
		var Rtn=$.cm({
		    ClassName : "web.DHCBL.Patient.DHCPatient",
		    MethodName : "PatUniInfoQuery",
		    PatientDr:PapmiDr, Type:"WIP", NoStr:WIPMedNo,
		    dataType:"text"
		},false);
		if (Rtn>0) {
			$.messager.alert("提示","西院住院病历号重复!");
			return false
		}
	}
	//西院门诊病历号
	var WOPMedNo=$("#WestOPMedicareNo").val();
	if (WOPMedNo!=""){
		var Rtn=$.cm({
		    ClassName : "web.DHCBL.Patient.DHCPatient",
		    MethodName : "PatUniInfoQuery",
		    PatientDr:PapmiDr, Type:"WOP", NoStr:WOPMedNo,
		    dataType:"text"
		},false);
		if (Rtn>0) {
			$.messager.alert("提示","西院门诊病历号重复!");
			return false
		}
	}
	//东院住院病历号
	var EIPMedNo=$("#EastIPMedicareNo").val();
	if (EIPMedNo!=""){
		var Rtn=$.cm({
		    ClassName : "web.DHCBL.Patient.DHCPatient",
		    MethodName : "PatUniInfoQuery",
		    PatientDr:PapmiDr, Type:"EIP", NoStr:EIPMedNo,
		    dataType:"text"
		},false);
		if (Rtn>0) {
			$.messager.alert("提示","东院住院病历号重复!");
			return false
		}
	}	
	//东院门诊病历号
	var EOPMedNo=$("#EastOPMedicareNo").val();
	if (EOPMedNo!=""){
		var Rtn=$.cm({
		    ClassName : "web.DHCBL.Patient.DHCPatient",
		    MethodName : "PatUniInfoQuery",
		    PatientDr:PapmiDr, Type:"EOP", NoStr:EOPMedNo,
		    dataType:"text"
		},false);
		if (Rtn>0) {
			$.messager.alert("提示","东院门诊病历号重复!");
			return false
		}
	}	
	return true
}
function checkPatYBCode(){
	var PatYBCode=$('#PatYBCode').val();
    var myPatType=getComValue("PatType"); 
	if (myPatType=="") {
		$.messager.alert("提示","请选择病人类型!","info",function(){
			$('#PatType').next('span').find('input').focus();
		});
		return false;
	}
		
	var rtn=$.cm({
	    ClassName : "web.DHCBL.CARD.UCardRefInfo",
	    MethodName : "GetInsurFlag",
	    PatypeDr:myPatType,
	    dataType:"text"
	},false);
	if ((rtn==0)&&(PatYBCode!="")) {
		$.messager.alert("提示","非医保病人,医保卡号不可填!","info",function(){
			$('#PatYBCode').focus();
		});
		return false;
	}
	//lxz 加入本地化配置，医保患者可以没有医保号
	var NotInsuPat=tkMakeServerCall('DHCDoc.DHCDocConfig.LocalConfig','GetLocalConfigValue',"Reg","CanNotInsuNoPat")
	if((rtn!=0)&&(PatYBCode=="")) {
		if ((NotInsuPat!="")&&(NotInsuPat.indexOf("!"+myPatType+"!")>=0)){
			return true;
		}
		$.messager.alert("提示","医保病人,请填写正确的医保卡号!","info",function(){
			$('#PatYBCode').focus();
		});
		return false;
	}
	
	
	//lxz 验证医保号长度和医保号最后一位是否是S
	if((rtn!=0)&&(PatYBCode!="")){
		if (PatYBCode.length!=12){
				$.messager.alert("提示","医保病人,请填写正确的医保卡号位数12","info",function(){
				$("#PatYBCode").focus();
				})
			return false;
		}
		
		var lasstr=PatYBCode.substr(PatYBCode.length-1,1).toUpperCase();
		if (lasstr!="S"){
			$.messager.alert("提示","医保病人,医保号最后一位是S请注意是否填写正确","info",function(){
				$("#PatYBCode").focus();
			})
			return false;
		}
	}
	
	return true
}
function UpdateOtherInform(){  
    var LocalFlag=$("#LocalFlag").combobox('getText');
    // 更新病案号,医保号等信息
    var EastOPMedicareNo=$('#EastOPMedicareNo').val(); 		//门诊病历号(东)
    var EastIPMedicareNo=$('#EastIPMedicareNo').val();		//住院病历号(东)
    var WestOPMedicareNo=$('#WestOPMedicareNo').val();		//门诊病历号(西)
    var WestIPMedicareNo=$('#WestIPMedicareNo').val();		//住院病历号(西)
    var InsuranceNo=$('#PatYBCode').val();				//医保号
	var PAPERCompany=$('#Company').val(); 
	var OtherInformStr=EastOPMedicareNo+"^"+EastIPMedicareNo+"^"+WestOPMedicareNo;
	OtherInformStr=OtherInformStr+"^"+WestIPMedicareNo+"^"+InsuranceNo+"^"+LocalFlag;
	OtherInformStr=OtherInformStr+"^"+PAPERCompany;
	var row=PageLogicObj.m_PatListTabDataGrid.datagrid('getSelected');
	var PapmiNo=row['TPAPMINo'];
	var UpdateFlag=$.cm({
	    ClassName : "web.DHCBL.Patient.DHCPatientBuilder",
	    MethodName : "UpDateOtherInform",
	    OtherInformStr:OtherInformStr, PapmiNo:PapmiNo,
	    dataType:"text"
	},false);
	return UpdateFlag;
}
function GetEntityClassInfoToXML(ParseInfo){
	var myxmlstr="";
	try{
		var xmlobj=new XMLWriter();
		xmlobj.BeginNode("TransContent");
		for(var i=0;i<ParseInfo.length;i++){
			xmlobj.BeginNode(ParseInfo[i].split("=")[0]);
			xmlobj.WriteString(ParseInfo[i].split("=")[1]);
			xmlobj.EndNode();
		}
		xmlobj.EndNode();
		xmlobj.Close();
		myxmlstr = xmlobj.ToString();
	}catch(Err){
		$.messager.alert("提示","Error: " + Err.description);
	}
	return myxmlstr;
}
function getComValue(Item){
	var newValue="";
	var value=$("#"+Item).combobox('getValue');
	if (value!=""){
		var data=$("#"+Item).combobox('getData');
		for (var i=0;i<data.length;i++){
			var id=data[i]['id'];
			if (value==id){
				newValue=id.split("^")[0];
				break;
			}
		}
	}
	return newValue;
}
function CardNoKeydown(e){
	var key=websys_getKey(e);
	if (key==13) {
		var CardNo=$('#CardNo').val();
		if (CardNo=="") return;
		var myrtn=DHCACC_GetAccInfo("",CardNo,"","",CardNoKeyDownCallBack);
	}
}
function CardNoKeyDownCallBack(myrtn){
	var myary=myrtn.split("^");
	var rtn=myary[0];
	switch (rtn){
		case "-200": 
			$.messager.alert("提示","卡无效!","info",function(){
				$('#CardNo').focus();
			});
			break;
		default:
			var PatientID=myary[4];
			var PatientNo=myary[5];
			var CardNo=myary[1]
			$('#CardNo').val(CardNo);
			FindPatList();
			break;
	}
}
function BReadCardClickHandle(){
	DHCACC_GetAccInfo7(CardNoKeyDownCallBack);
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
	if (keyCode==13) { 
		if ((SrcObj) && ((SrcObj.id.indexOf("CardNo")>=0) ||(SrcObj.id.indexOf("PatYBCode")>=0) || (SrcObj.id.indexOf("SPAPERName")>=0) || (SrcObj.id.indexOf("SPAPERID")>=0))){  
			return false;
		}
		return true;
	}else if(keyCode==119){
		//F8
		FindPatList();
	}else if(keyCode==115){ 
		BReadCardClickHandle();
	}else if(keyCode==120){
		BUpdateClickHandle();
	}else if(keyCode==113){
		Clear();
	}
	
	
}
function InsuranceNoKeydown(e){
	var key=websys_getKey(e);
	if (key==13) {
		var row=PageLogicObj.m_PatListTabDataGrid.datagrid('getSelected');
		var PapmiDr=row['TID'];
		var InsuNo=$("#PatYBCode").val();
		if ((InsuNo=="")||(InsuNo=="99999999999S")) {return};
		var InsuFlag=PatYBCodekeydownClick();
		if (InsuFlag==false) {return;}
		var Rtn=$.cm({
		    ClassName : "web.DHCBL.Patient.DHCPatient",
		    MethodName : "PatUniInfoQuery",
		    PatientDr:PapmiDr, Type:"InsuNo", NoStr:InsuNo,
		    dataType:"text"
		},false);
		if(Rtn==""){
			$.messager.alert("提示","请选择患者!")
			return false;
		}
		if (Rtn>0) {
			var src="reg.cardsearchquery.hui.csp?InsuranceNo="+InsuNo;
			var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
			createModalDialog("OtherCredTypeManager","患者查询", PageLogicObj.dw, PageLogicObj.dh,"icon-w-find","",$code,"");
		}
	}
}
function PatYBCodekeydownClick(){
	if ((ServerObj.HospitalCode!="BJDTYY")&&(ServerObj.HospitalCode!="BJFCYY")) return true;
	var InsuNo=$("#PatYBCode").val();
	//医保号合法性的判断 getComValue
	var PAPERSocialStatus=$("#PatType").combobox('getText');
	if ((PAPERSocialStatus!="医保")&&(PAPERSocialStatuse!="医保特病")) {	
		if (InsuNo=='')  {
			return true;
		}else {	
			$.messager.alert("提示","病人类型与医保号不符");
			return false;
		}
	}else{
		if (InsuNo=="99999999999S") return true;
		var tmp=myobj.value;
		var length=tmp.length;
		if(length!=12){
			$.messager.alert("提示","医保号位数不对?");
			return false;
		}
		var numtmp=tmp.substring(0,length-1);
		var numflag=isNumber(numtmp);
		if ((numflag!=true)||((tmp.substring(length-1,length)!="s")&&(tmp.substring(length-1,length)!="S"))){
			$.messager.alert("提示","医保字符不对?");
			return false;
		}else{
			return true;
		}
	}
}
function PAPERIDkeypress(e){
	var e=window.event;
	var mykey=e.keyCode;
	if (mykey==13){
		var myrtn=IsCredTypeID();
		if (myrtn){
			var mypId = $("#CredNo").val();
			if (mypId!=""){
				var myary=DHCWeb_GetInfoFromId(mypId);
				if (myary[0]=="1"){
					$("#Birth").val(myary[2]);		////Birthday
					$("#Age").val(myary[4]);		////Age
				}else{
					$("#CredNo").focus();
					return;
				}
			}
		}
	}
}
function SPAPERIDkeydown(e){
	var e=window.event;
	var mykey=e.keyCode;
	if (mykey==13){
		FindPatList()
	}
}
function SPAPERNamekeydown(e){
	var e=window.event;
	var mykey=e.keyCode;
	if (mykey==13){
		FindPatList()
	}
}
function SPAPERNokeydown(e){
	var e=window.event;
	var mykey=e.keyCode;
	if (mykey==13){
		SetPAPMINoLenth()
		FindPatList()
	}
}
function SetPAPMINoLenth(){
	var PAPMINo=$("#SPAPERNo").val();
	if (PAPMINo!='') {
		if ((PAPMINo.length<PageLogicObj.m_PAPMINOLength)&&(PageLogicObj.m_PAPMINOLength!=0)) {
			for (var i=(PageLogicObj.m_PAPMINOLength-PAPMINo.length-1); i>=0; i--) {
				PAPMINo="0"+PAPMINo;
			}
		}
		$("#SPAPERNo").val(PAPMINo);	
	}
}
function PAPEREmailOnblur(){
	var PAPEREmail=$("#EMail").val();
	if (PAPEREmail!=""){
		var ret=DHCC_CheckEmailIsMatch(PAPEREmail);
		if (ret==false) $("#EMail").focus();
	}
	window.event.keyCode=0;
	return false;
}
function PAPERDobOnblur(){
	var PAPERDob=$("#Birth").val();
	if (PAPERDob=="") return false;
	if ((PAPERDob.indexOf("/")==-1)&&(PAPERDob.indexOf("-")==-1)){
		$("#Birth").val($("#Birth").val().toDate());
		if (ServerObj.sysDateFormat=="4"){
			var Date=$("#Birth").val();
			$("#Birth").val(Date.split("-")[2]+"/"+Date.split("-")[1]+"/"+Date.split("-")[0]);
		}
		if ($("#Birth").val()=="") return;
	}
	var mybirth=$("#Birth").val();
	if (ServerObj.sysDateFormat=="4"){
		var myrtn=DHCWeb_IsDate(mybirth,"/")
	}else{
		var myrtn=DHCWeb_IsDate(mybirth,"-")
	}
	if (!myrtn){
		$.messager.alert("提示","请输入正确的日期!","info",function(){
			$("#Birth").val('');
			$("#Birth").focus();
		});
		return false;
	}else{
		var mybirthTime=$("#BirthTime").timespinner('getValue');
		var ageStr=$.cm({
		    ClassName : "web.UDHCJFCOMMON",
		    MethodName : "DispPatAge",
		    birthDate:mybirth, admDate:"", birthTime:mybirthTime, admTime:"", controlFlag:"N",
		    dataType:"text"
		},false);
		var ageStr=ageStr.split("||")[0];
		$("#Age").val(ageStr);
	}
	var mybirth1=$("#Birth").val();
	var Checkrtn=CheckBirth(mybirth1);
	if(Checkrtn==false){
		$.messager.alert("提示","出生日期不能大于今天或者小于、等于1840年!","info",function(){
			$("#Birth").focus();
		});
		return false;
	}
}
function BirthTimeOnblur(){
	var mybirth=$("#Birth").val();
	if(mybirth=="") return false;
	var mybirthTime=$("#BirthTime").timespinner('getValue');
	if(mybirthTime=="") return false;
	var myage = $("#Age").val();
    var ageStr=$.cm({
	    ClassName : "web.UDHCJFCOMMON",
	    MethodName : "DispPatAge",
	    birthDate:mybirth, admDate:"", birthTime:mybirthTime, admTime:"", controlFlag:"N",
	    dataType:"text"
	},false);
	var ageStr=ageStr.split("||")[0];
	$("#Age").val(ageStr);
}
function CheckBirth(Birth){
	var Year,Mon,Day,Str;
	if (ServerObj.sysDateFormat=="4"){
		Str=Birth.split("/")
		Year=Str[2];
		Mon=Str[1];
		Day=Str[0];
	}else if(ServerObj.sysDateFormat=="3"){
		Str=Birth.split("-")
		Year=Str[0];
		Mon=Str[1];
		Day=Str[2];
	}	
	var Today,ToYear,ToMon,ToDay;
	Today=new Date();
	ToYear=Today.getFullYear();
	ToMon=(Today.getMonth()+1);
	ToDay=Today.getDate();
	if((Year > ToYear)||(Year<=1840)){
		return false;
	}else if((Year==ToYear)&&(Mon>ToMon)){
		return false;
	}else if((Year==ToYear)&&(Mon==ToMon)&&(Day>ToDay)){
		return false;
	}else {
		return true;
	}
}
function getNowFormatDate() {
    var date = new Date();
    var seperator1 = "-";
    var month = date.getMonth() + 1;
    var strDate = date.getDate();
    if (month >= 1 && month <= 9) {
        month = "0" + month;
    }
    if (strDate >= 0 && strDate <= 9) {
        strDate = "0" + strDate;
    }
    if (ServerObj.sysDateFormat=="3"){
	    var currentdate = date.getFullYear() + seperator1 + month + seperator1 + strDate;
	}else{
		var seperator1 = "/";
	    var currentdate = strDate + seperator1 + month + seperator1 + date.getFullYear();
	}
    return currentdate;
} 
function OtherCredTypeInput(){
 	var src="doc.othercredtype.hui.csp?OtherCardInfo="+$("#OtherCardInfo").val();;
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("OtherCredTypeManager","其他证件管理", "500", "350","icon-w-epr","",$code,"");	
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
function CardTypeSave(newData){
	$("#OtherCardInfo").val(newData);
}
function PatInfoUnique(PatientID){
	var Name=$("#Name").val();
	var Sex = $("#Sex").combobox("getValue");
	var Birth = $('#Birth').val();
	var Tel = $("#TelHome").val();
	var PAPMIRowID=$("#PAPMIRowID").val()
	var rtn=$.cm({
		ClassName:"web.DHCPATCardUnite",
		MethodName:"GetPatByInfo",
		CardType:"",
		Name:Name,
		Sex:Sex,
		Birth:Birth,
		Tel:Tel,
		PAPMIRowID:PatientID,
		dataType:"text"
	},false)
	var RtnArr=rtn.split("^")
	if (RtnArr[0]=="0"){
		return true;
	}else if(RtnArr[0]=="S"){
		//$.messager.alert('提示','此姓名、性别、出生日期、联系电话信息绑定已挂失卡'+RtnArr[1]);
		//return false;
	}else if(RtnArr[0]=="N"){
		//$.messager.alert('提示','此姓名、性别、出生日期、联系电话信息绑定卡'+RtnArr[1]);
		//return false;
	}
	return true;
}
function InitPatRegConfig()
{
	var myvalue=$.cm({
		ClassName:"web.DHCBL.CARD.UCardPATRegConfig",
		MethodName:"GetCardPatRegConfig",
		dataType:"text",
		SessionStr:""
	},false);
	if (myvalue==""){
		return;
	}
	var myRtnAry=myvalue.split(String.fromCharCode(2))
	var myary=myRtnAry[0].split("^");
	var mySetFocusElement=myary[2];
	PageLogicObj.m_PatMasFlag=myary[3];
	/*PageLogicObj.m_IsNotStructAddress=myary[17];
	if (PageLogicObj.m_IsNotStructAddress=="Y"){
		InitAddressCombo();
	}
	PageLogicObj.m_SetFocusElement = mySetFocusElement;
	PageLogicObj.m_CardRefFlag=myary[4];
	PageLogicObj.m_AccManagerFlag=myary[5];
	SetPatInfoByXML(myRtnAry[1]);
	SetPatInfoByXML(ServerObj.CardPatUIDefStr);
	if (mySetFocusElement!=""){
		$("#"+mySetFocusElement).focus();
	}
	PageLogicObj.m_CardSecrityNo="";*/
	PageLogicObj.m_CardRegMustFillInArr=JSON.parse(myary[19]);
	PageLogicObj.m_CardRegJumpSeqArr=JSON.parse(myary[20]);
}
///根据元素的classname获取元素值
function getValue(id){
	var className=$("#"+id).attr("class")
	var valgetf=$("#"+id).attr("valgetf")
	if(typeof className =="undefined"){
		return $("#"+id).val()
	}
	if(className.indexOf("hisui-lookup")>=0){
		var txt=$("#"+id).lookup("getText")
		//如果放大镜文本框的值为空,则返回空值
		if(txt!=""){ 
			var val=$("#"+id).val()
		}else{
			var val=""
			$("#"+id+"Id").val("")
		}
		return val
	}else if(className.indexOf("hisui-combobox")>=0){
		var val=$("#"+id).combobox("getValue")
		if(typeof val =="undefined") val=""
		return val
	}else if(valgetf=="comb"){
		var val=$("#"+id).combobox("getValue")
		if(typeof val =="undefined") val=""
		return val
	}else if(className.indexOf("hisui-datebox")>=0){
		return $("#"+id).datebox("getValue")
	}else{
		return $("#"+id).val()
	}
	return ""
}
function setFocus(id){
	var className=$("#"+id).attr("class")
	if(typeof className =="undefined"){
		$("#"+id).focus();
	}
	if (("^hisui-lookup^hisui-combobox^hisui-datebox").indexOf(("^"+className+"^"))>=0){
		$("#"+id).next('span').find('input').focus();
	}else{
		$("#"+id).focus();
	}
}
function ReadRegInfoOnClick(){
	var myHCTypeDR=$("#IEType").combobox("getValue");
	var myInfo=DHCWCOM_PersonInfoRead(myHCTypeDR);
	var myary=myInfo.split("^");
	if (myary[0]=="0"){
		SetPatInfoByXML(myary[1]);
		BirthOnBlur();
		//设置照片信息
		var PhotoInfo=$("#PhotoInfo").val();
		if (PhotoInfo!=""){
			var src="data:image/png;base64,"+PhotoInfo;
		}else{
			var src="";
		}
		ShowPicBySrcNew(src,"imgPic");
	}
}
function SetPatInfoByXML(XMLStr) {
	XMLStr = "<?xml version='1.0' encoding='gb2312'?>" + XMLStr
	var xmlDoc = DHCDOM_CreateXMLDOM();
    oldPersonMessage=[];
	xmlDoc.async = false;
	xmlDoc.loadXML(XMLStr);
	if (xmlDoc.parseError.errorCode != 0) {
		alert(xmlDoc.parseError.reason);
		return;
	}
	var nodes = xmlDoc.documentElement.childNodes;
	if (nodes.length<=0){return;}
	for (var i = 0; i < nodes.length; i++) {
		var myItemName = nodes(i).nodeName;
		var myItemValue = nodes(i).text;
		if ((myItemName=="OtherCardInfo")&&(myItemValue!="")) {
			myItemValue=myItemValue.replace(/@/g,"^");
		}
		if (myItemName=="Sex"){$("#Sex").combobox('select',myItemValue);}
		if (myItemName=="Age"){continue}
		var _$id=$("#"+myItemName);
		if (_$id.length>0){
			var oldinfo=_$id.val()
			if (myItemName=="Birth"){oldinfo=oldinfo.replace(/-/g,'')}
			if ((oldinfo!="")&&(oldinfo!=myItemValue)){
				lableName = $('label[for="'+ myItemName +'"]').text();
				var rtn=dhcsys_confirm(lableName+"和读取信息不一致，是否覆盖信息?")
				if(rtn){
					_$id.val(myItemValue);
				}
				/*
				$.messager.confirm('确认对话框',lableName+"和读取信息不一致，是否覆盖信息?", function(r){
						if (r){	
				        _$id.val(myItemValue);
						}
					});
				*/
			 }else if (oldinfo==""){
					_$id.val(myItemValue);
				}
			}
	}
	delete(xmlDoc);
}

function BirthOnBlur(){
	///清屏的时候不在处理
	//var Obj=GetEventElementObj()
	//if (Obj.name=="Clear"){return websys_cancel();}
	var mybirth=$("#Birth").val();
	if ((mybirth!="")&&((mybirth.length!=8)&&((mybirth.length!=10)))){
		$.messager.alert("提示","请输入正确的出生日期!","info",function(){
			$("#Birth").addClass("newclsInvalid"); 
			$("#Birth").focus();
		});
		return false;
	}
	$("#Birth").removeClass("newclsInvalid");
	if ((mybirth.length==8)){
		if (ServerObj.dtformat=="YMD"){
			var mybirth=mybirth.substring(0,4)+"-"+mybirth.substring(4,6)+"-"+mybirth.substring(6,8)
		}
		if (ServerObj.dtformat=="DMY"){
			var mybirth=mybirth.substring(6,8)+"/"+mybirth.substring(4,6)+"/"+mybirth.substring(0,4)
		}
		$("#Birth").val(mybirth);
	}
	if (mybirth!="") {
		if (ServerObj.dtformat=="YMD"){
			var reg=/^(([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3})-(((0[13578]|1[02])-(0[1-9]|[12][0-9]|3[01]))|((0[469]|11)-(0[1-9]|[12][0-9]|30))|(02-(0[1-9]|[1][0-9]|2[0-8]))))|((([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00))-02-29)$/;
		}
		if (ServerObj.dtformat=="DMY"){
			var reg=/^(((0[1-9]|[12][0-9]|3[01])\/((0[13578]|1[02]))|((0[1-9]|[12][0-9]|30)\/(0[469]|11))|(0[1-9]|[1][0-9]|2[0-8])\/(02))\/([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3}))|(29\/02\/(([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00)))$/;
		}
		var ret=mybirth.match(reg);
	    if(ret==null){
		    $.messager.alert("提示","请输入正确的出生日期!","info",function(){
				$("#Birth").addClass("newclsInvalid"); 
				$("#Birth").focus();
			});
			return false;
		}
	  	if (ServerObj.dtformat=="YMD"){
		  	var myrtn=DHCWeb_IsDate(mybirth,"-")
	  	}
	  	if (ServerObj.dtformat=="DMY"){
		  	var myrtn=DHCWeb_IsDate(mybirth,"/")
	  	}
		if (!myrtn){
			$.messager.alert("提示","请输入正确的出生日期!","info",function(){
				$("#Birth").addClass("newclsInvalid"); 
				$("#Birth").focus();
			});
			return false;
		}else{
			var mybirth1=$("#Birth").val();
			var Checkrtn=CheckBirth(mybirth1);
			if(Checkrtn==false){
				$.messager.alert("提示","出生日期不能大于今天或者小于、等于1840年!","info",function(){
					$("#Birth").addClass("newclsInvalid"); 
					$("#Birth").focus();
				});
				return false;
			}
			var myAge=DHCWeb_GetAgeFromBirthDay("Birth");
			$("#Age").val(myAge);
		}
	}else{
		$("#Birth").removeClass("newclsInvalid");
	}
}

function LoadIEType(){
	$.cm({
		ClassName:"web.UDHCCardCommLinkRegister",
		QueryName:"ReadHardComList",
		HardGroupType:"IE", 
		ExpStr:""
	},function(GridData){
		var cbox = $HUI.combobox("#IEType", {
				valueField: 'HGRowID',
				textField: 'HGDesc', 
				editable:false,
				blurValidValue:true,
				data: GridData["rows"],
				onLoadSuccess:function(){
					var Data=$(this).combobox("getData");
					if (Data.length>0){
						$(this).combobox("select",Data[0]["HGRowID"]);
					}
				}
				
		 });
	});
}
function DisableBtn(id,disabled){
	if (disabled){
		$HUI.linkbutton("#"+id).disable();
	}else{
		$HUI.linkbutton("#"+id).enable();
	}
}


//lxz 判断是否是特病患者
function OpenSpecil(PatID){	
	return
	var rtn = $cm({
	ClassName:"web.DHCOPSpecPatHis",
	MethodName:"IsSpecilPat",
	dataType:"text",
	PatientID:PatID,
	},false);
	if (rtn==1){
		var url='dhc.doc.opregspecilpat.csp?PatientID='+PatID
		var winName='specilpat'; 
		var awidth=screen.availWidth/6*5; 
		var aheight=screen.availHeight/5*4; 
		var atop=(screen.availHeight - aheight)/2;
		var aleft=(screen.availWidth - awidth)/2;
		var param0='scrollbars=0,status=0,menubar=0,resizable=2,location=0'; 
		var params='top=' + atop + ',left=' + aleft + ',width=' + awidth + ',height=' + aheight + ',' + param0 ;
		win=window.open(url,winName,params); 
		win.focus(); 
	}
}

function ReadInsuCard(){
	//读卡
	var rtn =DocBJYBObj.Punlic.InsuReadCard()
	//转为JSON
	var JsonData=DocBJYBObj.Punlic.CardToJson(rtn)
	//
	if (JsonData.ResultCode!=0){
		$.messager.alert("提示","医保卡读取错误,请重试!"+JsonData.ResultCode)
		return;
	}
	//患者基本信息解析
	var Common=JsonData.CommonMesage;
	var InsuCardNo =Common.InsuCardNo //医保卡号
	var ICNO=Common.InsuFundNo; //医保号
	var IDNo = Common.IDNo //证件号
	var IsAreaInsu=JsonData.IsAreaInsu
	var AreaCode=""
	if (IsAreaInsu=="Y"){
		//获取医保卡类型
		var CardType = $cm({
			ClassName:"web.DHCInsuCardLink",
			MethodName:"GetYDCardType",
			dataType:"text",
		},false);
		AreaCode=JsonData.AreaMesage.AreaCode			
	}else{
		//获取医保卡类型
		var CardType = $cm({
			ClassName:"DHCDoc.Insu.BJInus.InsuCommon",
			MethodName:"GetCardMesage",
			dataType:"text",
			code:"YBCardType",
		},false);
	}
	if (CardType==""){
		dhcsys_alert("未找到对应的卡类型!")
	}
	var CardTypeArry=CardType.split("^")
	if (InsuCardNo==""){$.messager.alert("提示","未读取到医保卡号,请重试！");return;}
	
	//通过医保卡获取患者信息
	var patmesage=DocBJYBObj.Punlic.GetPatByCard(InsuCardNo,CardTypeArry[0],AreaCode)
	if (patmesage==""){$.messager.alert("提示","未找到医保卡对应的患者信息!");return;}
	var Rtnarry=patmesage.split("!");
	if (Rtnarry.length>1){dhcsys_alert("医保卡关联了多个有效的患者信息,请先解除绑定:</p>"+patmesage);return}
	var onearry=Rtnarry[0].split("^")
	var PatientNo=onearry[0];
	var PatientID=onearry[2];
	
	$("#SPAPERNo").val(PatientNo)
	FindPatList()	
	$('#CardNo').val(InsuCardNo);
	$('#CardTypeNew').val(CardTypeArry[2]);	
			
	
}
function ReadJYTCard(RtnData){
	var RtnArry=RtnData.split("^")
	if (RtnArry[0]!=0){
		dhcsys_alert("获取信息失败:"+RtnData)
		return
	}
	$("#SPAPERNo").val(RtnArry[5])
	FindPatList()	
	$("#CardNo").val(RtnArry[1])
	$("#CardTypeNew").val(RtnArry[4])
}




