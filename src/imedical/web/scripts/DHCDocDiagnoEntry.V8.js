var WScreenH=window.screen.height;
var DATE_FORMAT;
var PageLogicObj={
	m_version: 8,
	EntrySelRowFlag:0,
	FocusRowIndex: 0,
	fpArr:new Array(),
    AlertFstOrReAdmFlag:0,
    MainSreenFlag:websys_getAppScreenIndex()				//双屏标识
}
//入口函数
function InitDiagEntry(){
	if (ServerObj.SYSDateFormat=="4"){
		// DD/MM/YYYY
        DATE_FORMAT= new RegExp("(((0[1-9]|[12][0-9]|3[01])/((0[13578]|1[02]))|((0[1-9]|[12][0-9]|30)/(0[469]|11))|(0[1-9]|[1][0-9]|2[0-8])/(02))/([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3}))|(29/02/(([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00)))");
	}else if(ServerObj.SYSDateFormat=="3"){
		// YYYY-MM-DD
    	DATE_FORMAT= new RegExp("(([0-9]{3}[1-9]|[0-9]{2}[1-9][0-9]{1}|[0-9]{1}[1-9][0-9]{2}|[1-9][0-9]{3})-(((0[13578]|1[02])-(0[1-9]|[12][0-9]|3[01]))|((0[469]|11)-(0[1-9]|[12][0-9]|30))|(02-(0[1-9]|[1][0-9]|2[0-8]))))|((([0-9]{2})(0[48]|[2468][048]|[13579][26])|((0[48]|[2468][048]|[3579][26])00))-02-29)");
	}
    SetDiagOtherInfo();
    InittabDiagnosEntry();
    LoadHistoryDiag();
    InitFavLayout();
    InitEvent(); //按钮栏事件放在按钮栏初始化成功事件里
    ShowSecondeWin("onOpenDHCEMRbrowse");
}
window.onbeforeunload = DiagnosUnloadHandler;
function DiagnosUnloadHandler(e){
	 //未审核的诊断
	var GirdData = GetGirdData();
	if(GirdData!=""){
    	if(dhcsys_confirm("有未保存的诊断，是否要保存")){
    		InsertMutiMRDiagnos();
    	}else{
	    	return ;
	    }
	}
}
function InitButtonBar()
{
	$('#btnList').marybtnbar({
        queryParams:{url:'diagnosentry.v8.csp',EpisodeID:ServerObj.EpisodeID},
        loadFilter:function(data){
	        for(var i=data.length-1;i>=0;i--){
		        switch(data[i].id){
			        case 'AddToEMR_Diag_btn':
			        	if(ServerObj.Opener!="EMR") data.splice(i,1);
			        	break;
			        case 'DiagCertificate_btn':
			        	if(ServerObj.PAAdmType=='I') data.splice(i,1);
			        	break;
			    	default:break;
			    }
		    }
		    return data;
	    },
        onLoadSuccess:function(data){
			if(ServerObj.warning!=""){
				$.messager.alert('提示',ServerObj.warning,'warning',function(){
					$('#btnList').find('a.l-btn').linkbutton('disable');
				});
			}else{
				$('#btnList').find('a.l-btn').linkbutton('enable');
			}
	    }
    });
}
function SetDiagOtherInfo(){
	var DiagOtherInfoArr=ServerObj.DiagOtherInfo.split(String.fromCharCode(1));
	var FirstAdm=DiagOtherInfoArr[0];
	var ReAdmis=DiagOtherInfoArr[1];
	var OutReAdm=DiagOtherInfoArr[2];
	var TransAdm=DiagOtherInfoArr[3];
	var ILIFlag=DiagOtherInfoArr[4];
	var BPSystolic=DiagOtherInfoArr[5];
	var BPDiastolic=DiagOtherInfoArr[6];
	var Weight=DiagOtherInfoArr[7];
	var Height=DiagOtherInfoArr[10];
	$('#FirstAdm,#ReAdmis,#OutReAdm').radio('setValue',false);
	if(FirstAdm==1){
		var o=$HUI.radio("#FirstAdm");
		o.setValue(true);
	}
	if(ReAdmis==1){
		var o=$HUI.radio("#ReAdmis");
		o.setValue(true);
	}
	if(OutReAdm==1){
		var o=$HUI.radio("#OutReAdm");
		o.setValue(true);
	}
	if(TransAdm==1){
		var o=$HUI.checkbox("#TransAdm");
		o.setValue(true);
	}else{
		var o=$HUI.checkbox("#TransAdm");
		o.setValue(false);
	}
	if(ILIFlag==1){
		var o=$HUI.checkbox("#ILI");
		o.setValue(true);
	}else{
		var o=$HUI.checkbox("#ILI");
		o.setValue(false);
	}
	$("#BPSystolic").val(BPSystolic);
	$("#BPDiastolic").val(BPDiastolic);
	$("#Weight").val(Weight);
	$("#Height").val(Height);
	var cbox = $HUI.combobox("#Special", {
		valueField: 'id',
		textField: 'text', 
		editable:false,
		multiple:true,
		data: eval("("+ServerObj.SpecialJson+")"),
		onLoadSuccess:function(){
			var sbox = $HUI.combobox("#Special");
			var DiagOtherInfoArr=ServerObj.DiagOtherInfo.split(String.fromCharCode(1));
			for (i=0;i<DiagOtherInfoArr[8].split("^").length;i++){
				if (DiagOtherInfoArr[8].split("^")[i]!="")  sbox.select(DiagOtherInfoArr[8].split("^")[i]);
			}
		}
   });
}
function InitEvent(){
	$('input[name="HistoryRange"]').radio({
		onChecked:function(e){
			$(e.target).radio('disable');
			$('input[name="HistoryRange"]').not(e.target).radio('enable');
			LoadHistoryDiag();
		}
	});
	$(document.body).bind("keydown",BodykeydownHandler);
}
function AddToEMRClickhandler(){
	DiagDataToEMR();
	window.close();
}
function MouthDiaInputshow(){
	var url = "mouth.diagnos.csp";
	//websys_createWindow(url, true, "status=1,scrollbars=1,top=0,left=0,width=1200,height=700");
	var diastr=window.showModalDialog(url,"","dialogHeight: "+(700)+"px; dialogWidth: "+(900)+"px");
	if (diastr==""){return false;}
	if (!CheckIsDischarge()) return false;
	for (var k=0;k<diastr.split("^").length;k++){
		var id=diastr.split("^")[k].split("!")[0];
		var desc=diastr.split("^")[k].split("!")[1];
		if ((id=="")&&(desc=="")) continue;
		if (id!="") {
			AddDiagItemtoList(id,"");
		}
		else AddDiagItemtoList("",desc);
	}
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
		if (SrcObj && SrcObj.id=="BPDiastolic") {
			$("#Weight").focus();
			return false;
		}else if(SrcObj && SrcObj.id=="BPSystolic"){
			$("#BPDiastolic").focus();
			return false;
		}else if(SrcObj && SrcObj.id=="Weight"){
			$('#Special').next('span').find('input').focus();
			return false;
		}else if(SrcObj && SrcObj.id.indexOf("DiagnosICDDesc")>=0){
			return false;
		}
		return true;
	}
}
function InittabDiagnosEntry(){
	var url='DHCDoc.Util.QueryToJSON.cls?JSONTYPE=JQGRID&ClassName=web.DHCDocDiagnosEntryV8&QueryName=DiagnosList';
	if(typeof websys_writeMWToken=='function') url=websys_writeMWToken(url);
    $("#tabDiagnosEntry").jqGrid({
		datatype: "json",
        url:url,
		postData:{MRADMID:ServerObj.mradm},
		shrinkToFit: false,
		autoScroll: false,
		mtype:'GET',
		emptyrecords:$g('没有数据'),
		viewrecords:true,
		loadtext:$g('数据加载中...'),
		multiselect:true,
		multiboxonly:true,
		rowNum:false, 
		loadonce:false, 
		viewrecords: true,
		rownumbers:false,
		loadui:'enable',
		loadError:function(xhr,status,error){
			alert("diagnosentry.js-err:"+status+","+error);
		},
		colNames:ListConfigObj.colNames,			
		colModel:ListConfigObj.colModel,
		ondblClickRow:function(rowid,iRow,iCol,e){
			EditRow(rowid)				
		},
		beforeSelectRow:function(rowid, e){	
			if ($.isNumeric(rowid) == true) {
				PageLogicObj.FocusRowIndex=rowid;
			}else{
				PageLogicObj.FocusRowIndex=0;
			}
			return true;//false 禁止选择行操作
	    },
	    gridComplete:function(){
			//加载完成后 增加 删除 都会调用
			$("#tabDiagnosEntry td").removeAttr("title");
		},
		loadComplete:function(data){
			Add_Diag_row();
			//改变已经保存诊断的颜色
			var rowids=$('#tabDiagnosEntry').getDataIDs();
			for(var i=0;i<rowids.length;i++){
				var ICDDiagnosDesc=GetCellData(rowids[i],"DiagnosICDDesc");
				var tmpICDDiagnosDesc=ICDDiagnosDesc.replace(/\&nbsp;/g,"")
				var DiagnosNotes=GetCellData(rowids[i],"DiagnosNotes");
				var DiagnosPrefix=GetCellData(rowids[i],"DiagnosPrefix");
				if (tmpICDDiagnosDesc!=""){
					$('#tabDiagnosEntry').setCell(rowids[i],"DiagnosICDDesc",ICDDiagnosDesc,"DiagSaved","")
				}else if (DiagnosPrefix!=""){
					$('#tabDiagnosEntry').setCell(rowids[i],"DiagnosPrefix",DiagnosPrefix,"DiagSaved","")
				}else if (DiagnosNotes!=""){
					$('#tabDiagnosEntry').setCell(rowids[i],"DiagnosNotes",DiagnosNotes,"DiagSaved","")
				}
				InitRowBtn(rowids[i]);
			}
			$("#tabDiagnosEntry td").removeAttr("title");
			AddCopyDiagToList(ServerObj.CopyDiagnosStr);
			if(typeof CDSSObj=='object') CDSSObj.AddDiagToList(ServerObj.copyCDSSData);
			ServerObj.copyCDSSData=[];
			if(!data.rows.length&&ServerObj.PALongICDCount>=1){
				GetDiagDataOnAdd(function(DiagItemStr){
					//诊断为空且没有带入诊断才提示
					if(DiagItemStr==""){	
						$.messager.confirm('提示', '是否引用本患者的长效诊断?', function(r){
							if (r){
								LongDiagnosOpen();
							}
						});
					}
				});
			}
		},
		resizeStop:function(newwidth, index){
			var col=ListConfigObj.colModel[index-1];
			if(col.name=="OperatBtn"){
				$('#tabDiagnosEntry').find('td[aria-describedby=tabDiagnosEntry_OperatBtn]').find('.shortcutbar-list-x').panel('resize');
			}
		}
    });
	jQuery('#tabDiagnosEntry').closest('.ui-jqgrid-view').find('div.ui-jqgrid-hdiv').bind("dblclick",headerDblClick);
}
function Add_Diag_row(position,srcrowid,childFlag){
	if(!position){
		var rowid=GetEmptyRowid();
		if(rowid){
			SetFocusCell(rowid,"DiagnosICDDesc");
			HorizontalMove([rowid],0);
			return rowid;
		}
	}
	if(!position) position='last';
	var oldSrcrowid=srcrowid;
	if(srcrowid){
		if(IsEmptyRow(srcrowid)){
			SetFocusCell(srcrowid,"DiagnosICDDesc");
			HorizontalMove([srcrowid],0);
			return srcrowid;
		}
		if((position=='before')||(position=='after')){
			var GroupRowids=GetGroupRowids(srcrowid,true);
			srcrowid=position=='before'?GroupRowids[0]:GroupRowids[GroupRowids.length-1];
		}
	}
	var rowids=$('#tabDiagnosEntry').getDataIDs();
	for(var i=rowids.length-1;i>=0;i--){
		var rowid=rowids[i];
		if(IsEmptyRow(rowid)){
			if(((position=='last')&&(i==(rowids.length-1)))||((position=='first')&&(i==0))
				||((position=='after')&&(rowids[i-1]==srcrowid))||((position=='before')&&(rowids[i+1]==srcrowid))){
				SetFocusCell(rowid,"DiagnosICDDesc");
				if(childFlag){
					var defDiagnosLeavel=GetChildRowLevel(oldSrcrowid);
					SetCellData(rowid,'DiagnosLeavel',defDiagnosLeavel);
					var SrcDiagnosCatRowId=GetICDType(srcrowid);
					var DiagnosCatRowId=GetICDType(rowid);
					if(SrcDiagnosCatRowId>0 && DiagnosCatRowId==0){
						SetCellData(rowid,"DiagnosCatRowId",1); 
		    			SetCellData(rowid,"DiagnosCat",1); 
					}
				}
				HorizontalMove([rowid],0);
				return rowid;
			}
			DeleteRow(rowid);
		}
	}
	var rowid=GetNewRowid();
	if(!rowid) return null;
	var DefaultData=GetDefaultData(position,srcrowid,childFlag);	
	DefaultData['id']=rowid;
	$('#tabDiagnosEntry').addRowData(rowid,DefaultData,position,srcrowid);
	EditRowCommon(rowid);
	SetFocusCell(rowid,'DiagnosICDDesc');
	return rowid;	
}
function GetDefaultData(position,srcrowid,childFlag){
	var defRow={
		DiagnosOnsetDate:ServerObj.CurrentDate,
		DiagnosDate:ServerObj.CurrentDate,
		DiagnosLeavel:1,
		DiagnosCatRowId:0,
		DiagnosTypeRowId:ServerObj.DedfaultDiagnosTypeID,
		DiagnosStatusRowId:3,
		LongDiagnosFlagRowId:"",
		MainDiagFlag:ServerObj.defMainDiagFlag
	};
	var rowids=$('#tabDiagnosEntry').getDataIDs();
	if(!srcrowid){
		srcrowid=rowids[rowids.length-1];
	}
	for(var i=0;i<rowids.length;i++){
		//如果已经录入了一条主诊断医嘱，则后续默认非主诊断
		var MainDiagFlag=GetCellData(rowids[i],"MainDiagFlag"); 
		if (MainDiagFlag=="Y" || MainDiagFlag=="是"){
			defRow.MainDiagFlag="N";
		}
	}
	if(defRow.MainDiagFlag==""){
		defRow.MainDiagFlag="Y";
	}
	//中医科室默认中医诊断
	if ((ServerObj.ZYLocFlag==1)||(ServerObj.CMDisFlag==1)){
		defRow.DiagnosCatRowId=1;
		defRow.DiagnosCat=1;
	}
	if (srcrowid){
		if(IsEditingRow(srcrowid)){
			defRow.DiagnosTypeRowId=GetCellData(srcrowid,"DiagnosTypeRowId"); //诊断类型
		}
		defRow.DiagnosStatusRowId=GetCellData(srcrowid,"DiagnosStatusRowId");
		defRow.DiagnosOnsetDate=GetCellData(srcrowid,"DiagnosOnsetDate"); //发病日期
		if(childFlag){
			defRow.DiagnosLeavel=GetChildRowLevel(srcrowid);
			if(!CheckIsItem(srcrowid)){
				defRow.DiagnosCatRowId=GetCellData(srcrowid,"DiagnosCatRowId"); //诊断类型
			}
		}
		if(['after','last'].indexOf(position)>-1 && !CheckIsItem(srcrowid)){
			var DiagnosCatRowId=GetCellData(srcrowid,"DiagnosCatRowId"); //分类
			if((DiagnosCatRowId=="2")&&!CheckIsItem(srcrowid)){
				defRow.DiagnosCatRowId="2";
				defRow.DiagnosLeavel=GetCellData(srcrowid,"DiagnosLeavel");
			}else if(DiagnosCatRowId=="1"){
				defRow.DiagnosCatRowId="2";
				defRow.DiagnosLeavel=GetChildRowLevel(srcrowid);
			}else{
				if(!childFlag) defRow.DiagnosLeavel=GetCellData(srcrowid,"DiagnosLeavel");
			}
		}
	}else{
		defRow.MainDiagFlag="Y";
	}
	defRow.DiagnosCat=defRow.DiagnosCatRowId;
	defRow.DiagnosType=defRow.DiagnosTypeRowId;
	defRow.DiagnosStatus=defRow.DiagnosStatusRowId;
	defRow.LongDiagnosFlag=defRow.LongDiagnosFlagRowId;
	return defRow;
}
function GetChildRowLevel(rowid){
	var defDiagnosLeavel=1;
	if(rowid){
		defDiagnosLeavel=parseInt(GetCellData(rowid,"DiagnosLeavel"))+1;
	}
	return defDiagnosLeavel;
}
function EditRowCommon(rowid){
	if(!$.isNumeric(rowid)) return;
	var DiagnosType=GetCellData(rowid,"DiagnosType");
	var DiagnosTypeRowId=GetCellData(rowid,"DiagnosTypeRowId");
	$('#tabDiagnosEntry').editRow(rowid, false);
	//从电子病历打开的界面控制住诊断类型不允许修改
	if ((ServerObj.SearchDiagnosTypeStr!="")&&CheckIsItem(rowid)){
		StyleConfigObj.DiagnosType=false;
		SetColumnList(rowid,"DiagnosType",DiagnosTypeRowId+":"+DiagnosType+":Y");
	}
	var StyleConfigObj={
		MRCIDRowId:false,
		MRDIARowId:false,
		DiagnosCat:false,
		DiagnosType:true,
		DiagnosLeavel:false,
		DiagnosICDDesc:false,
		MainDiagFlag:true,
		DiagnosNotes:true,
		MRCIDCode:false,
		DiagnosStatus:true,
		DiagnosOnsetDate:true,
		DiagnosDate:true,
		DiagnosPrefix:true
	};
	if(!CheckIsItem(rowid)){
		$.extend(StyleConfigObj,{DiagnosCat:true,DiagnosICDDesc:true})
	}
	var DiagnosCatRowId=GetICDType(rowid)
	if(DiagnosCatRowId==2){
		$.extend(StyleConfigObj,{DiagnosType:false,MainDiagFlag:false,DiagnosStatus:false,DiagnosOnsetDate:false,DiagnosDate:false});
	}
	ChangeRowStyle(rowid,StyleConfigObj);
	if(StyleConfigObj.DiagnosICDDesc){
		if(ServerObj.SDSDiagEntry){
			InitDiagnosICDDescLookUpSDS(rowid);
		}else{
			InitDiagnosICDDescLookUpHUI(rowid);
		}
	}
	HorizontalMove([rowid],0);
	EditSDSExpProperty(rowid);
	InitDateFlatpickr(rowid);
	var TCMTreatment=GetCellData(rowid,"TCMTreatment");
	InitTCMTreat(rowid);
	SetCellData(rowid,"TCMTreatment",TCMTreatment);
	RecalcRowNum();
	if(!$('#tabDiagnosEntry').find('tr#'+rowid).find('.shortcutbar-list-x').size()){
		InitRowBtn(rowid);
	}
	$('#tabDiagnosEntry').find('tr#'+rowid).find('input[type=text]').tooltip({
		content:'',
		onShow:function(){
			var content=$(this).val();
			if(GetTextWidth(content)<$(this).innerWidth()){
				$(this).tooltip('tip').hide();
			}else{
				$(this).tooltip('tip').show();
				$(this).tooltip('update',content).tooltip('reposition');
			}
		}
	});
	$('#tabDiagnosEntry').find('tr#'+rowid).find('.DiagSaved').removeClass('DiagSaved');
	$('#tabDiagnosEntry').find('tr#'+rowid).children().attr('title', '');
}
function GetTextWidth(content){
	var $span=$("<span>"+content+"</span>").hide().appendTo('body');
	var width=$span.width()
	$span.remove();
	return width;
}
function SetFocusCell(rowid,colname){
	if($.isNumeric(rowid)==true){
		$('#'+rowid+"_"+colname).focus();
		PageLogicObj.FocusRowIndex=rowid;
	}else{
		$('#'+colname).focus();		
	}
}
function DiagnosCatChange(e){
	var rowId="";
	var obj=websys_getSrcElement(e);
	var rowId=GetEventRow(e);
	var DiagnosCatRowId=GetCellData(rowId,"DiagnosCatRowId");
	if ((obj.value=="1")||(obj.value=="2")){
		if ((ServerObj.ZYLocFlag!=1)&&(ServerObj.ChinaDiagLimit=="1")){
			$.messager.alert("提示",'科室非中医科室,不允许开立中医诊断'); 
			SetCellData(rowId,"DiagnosCatRowId",DiagnosCatRowId); 
		    SetCellData(rowId,"DiagnosCat",DiagnosCatRowId); 
			return false; 
		}
	}
	if (obj.value=="2"){ //如果修改分类为证型,则判断是否存在对应中医诊断,如果不存在,则不允许修改
	    var Flag=0;
		if (rowId=="1"){
			Flag=1;
		}else{
			var preId=parseInt(rowId)-1;
			if(CheckIsItem(preId)) Flag=1;
			else {
				var upDiagnosCatRowId=GetCellData(preId,"DiagnosCatRowId");
				if (upDiagnosCatRowId=="0"){
					Flag=1;
				}
			}
		}
		if (Flag=="1"){
			$.messager.alert("提示","请先录入中医诊断!","info",function (){
				SetFocusCell(rowId,"DiagnosICDDesc");
			}); 
			SetCellData(rowId,"DiagnosCatRowId",DiagnosCatRowId); 
		    SetCellData(rowId,"DiagnosCat",DiagnosCatRowId); 
			return false; 
		}
	}
	if(obj.value!=DiagnosCatRowId){
		ClearRow(rowId);
		SetCellData(rowId,"DiagnosCatRowId",obj.value);
		if(ServerObj.SDSDiagEntry){
			InitDiagnosICDDescLookUpSDS(rowId);
		}
		ControlTCMTreatStyle(rowId);
		var StyleConfigObj={DiagnosType:true,MainDiagFlag:true,DiagnosStatus:true,DiagnosOnsetDate:true,DiagnosDate:true};
		if(obj.value==2){
			$.extend(StyleConfigObj,{DiagnosType:false,MainDiagFlag:false,DiagnosStatus:false,DiagnosOnsetDate:false,DiagnosDate:false});
		}
		ChangeRowStyle(rowId,StyleConfigObj);
	}
}
function DiagnosTypeChange(e){
	var rowId="";
	var obj=websys_getSrcElement(e);
	var rowId=GetEventRow(e);
	SetCellData(rowId,"DiagnosTypeRowId",obj.value);
	SyncChildRow(rowId,"DiagnosTypeRowId",obj.value);
	SyncChildRow(rowId,"DiagnosType",obj.value);
	SetFocusCell(rowId,"DiagnosICDDesc")
}
function DiagnosBodyPartChange(e){
	var rowId="";
	var obj=websys_getSrcElement(e);
	var rowId=GetEventRow(e);
	SetCellData(rowId,"DiagnosBodyPartRowId",obj.value);
	SetFocusCell(rowId,"DiagnosBodyPart")
}
function DiagnosStatusChange(e){
	var rowId="";
	var obj=websys_getSrcElement(e);
	var rowId=GetEventRow(e);
	SetCellData(rowId,"DiagnosStatusRowId",obj.value);
	SyncChildRow(rowId,"DiagnosStatusRowId",obj.value);
	SyncChildRow(rowId,"DiagnosStatus",obj.value);
	SetFocusCell(rowId,"DiagnosICDDesc")
}
function DiagnosICDDesc_keydown(e){
	//处理删除诊断内容的情况
	var keyCode=e.keyCode;
	if((keyCode==8)||(keyCode==46)){
		var rowid=GetEventRow(e);
		var ICDDesc=GetCellData(rowid,"DiagnosICDDesc");
		var ICDRowid=GetCellData(rowid,"MRCIDRowId");
		if((ICDRowid)&&(ICDDesc=='')){
			ClearRow(rowid);
		}
	}
	//元素回车事件未添加逻辑处理,查询控件功能统一使用InitDiagnosICDDescLookUpHUI方法中lookup控件
	return false;
}
function Trim(str,is_global)
{
	var result;
	result = str.replace(/(^\s+)|(\s+$)/g,"");
	if(is_global.toLowerCase()=="g") {
		result = result.replace(/\s/g,"");
	}
	return result;
}
function DiagItemLookupSelect(text, rowid){
	PageLogicObj.EntrySelRowFlag=1;
	/*if (typeof rowid == "undefined") {
        var rowid = "";
    }
    if (this.id.indexOf("_") > 0) {
        rowid = this.id.split("_")[0];
    }*/ 
    var Split_Value = text.split("^");
    var idesc = Split_Value[0];
    var icode = Split_Value[1];
    if (window.event) window.event.keyCode = 0;
    if (!CheckDiagIsEnabled(icode,function(ret){
		if(!ret) ClearRow(rowid);
	})) {
    	return false;
	}
    SetCellData(rowid,"DiagnosICDDesc",idesc);
	HorizontalMove([rowid],0);
    SetCellData(rowid,"MRCIDRowId",icode);
    SetCellData(rowid,"MRCIDCode",Split_Value[2]);
    SetCellData(rowid,"DiagInsuCode",Split_Value[3]);
    SetCellData(rowid,"DiagInsuName",Split_Value[4]);
    var DiagnosCatRowId=GetCellData(rowid,"DiagnosCatRowId");
    if (DiagnosCatRowId=="2"){
		for (var k=parseInt(rowid)-1;k>=1;k--){
			var tmpDiagnosCatRowId=GetCellData(k,"DiagnosCatRowId"); 
			if (tmpDiagnosCatRowId=="1"){
				var defLongDiagnosFlagRowId=GetCellData(k,"LongDiagnosFlagRowId");
				SetCellData(rowid,"LongDiagnosFlagRowId",defLongDiagnosFlagRowId);
				SetCellData(rowid,"LongDiagnosFlag",defLongDiagnosFlagRowId);
				break;
			}
	    }
		Add_Diag_row('after',rowid);
		if($("#"+rowid+"_TCMTreatment").size()){
			SetFocusCell(rowid, "TCMTreatment");
		}
	}else{
		Add_Diag_row('after',rowid);
	}
}
function  ClearRow(rowid){
	SetCellData(rowid,"DiagnosICDDesc","");
	SetCellData(rowid,"MRCIDRowId","");
	SetCellData(rowid,"MRCIDCode","");
	SetCellData(rowid, "SDSDesc",'');
	SetCellData(rowid, "SDSInfo",'');
	SetFocusCell(rowid, "DiagnosICDDesc");
	SetCellData(rowid,"LongDiagnosFlagRowId","");
	SetCellData(rowid,"LongDiagnosFlag","");
	HorizontalMove([rowid],0);
}
function DiagnosNotes_keydown(e){
	var Row=GetEventRow(e);
	var key=websys_getKey(e);
	if (key==13){
		var MRCIDRowId=GetCellData(Row,"MRCIDRowId");
		var DiagnosNotes=GetCellData(Row,"DiagnosNotes");
		if (DiagnosNotes!="") DiagnosNotes=DiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
		if ((MRCIDRowId=="" || MRCIDRowId==null)&&(DiagnosNotes=="")){
			SetFocusCell(Row,"DiagnosNotes");
			return false;
		}else{
			var ICDType=GetICDType(Row);
			if(ICDType==1){
				SetFocusCell(Row,"SyndromeDesc");
			}else{
				Add_Diag_row();
			}
		}
	}
}
function DiagnosPrefix_keydown(e){
	var Row=GetEventRow(e);
	var key=websys_getKey(e);
	if (key==13){
		var MRCIDRowId=GetCellData(Row,"MRCIDRowId");
		var DiagnosNotes=GetCellData(Row,"DiagnosPrefix");
		if (DiagnosNotes!="") DiagnosNotes=DiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
		if ((MRCIDRowId=="" || MRCIDRowId==null)&&(DiagnosNotes=="")){
			SetFocusCell(Row,"DiagnosNotes");
			return false;
		}else{
			var ICDType=GetICDType(Row);
			if(ICDType==1){
				SetFocusCell(Row,"SyndromeDesc");
			}else{
				Add_Diag_row();
			}
		}
	}
}
//日期编辑器 
function InitDatePicker(cl) {
	return false;
}
//对日历设置QP
function SetWdateFoucus() {
	var WdateIframe = $dp.dd.getElementsByTagName("iframe");
	if (WdateIframe.length > 0) {
		WdateIframe = WdateIframe[0];
	} else {
		return;
	}
	var doc = WdateIframe.contentWindow.document;
	//当日历表格加载后才执行事件处理
	var _tables = doc.getElementsByTagName("table");
	if (_tables.length == 0) {
		setTimeout(SetWdateFoucus, 100);
		return;
	}
	
	var $domOBJ = $(doc).find('.tB,.tE');
	$domOBJ.eq(0).focus();
}

//对日历设置QP
function setWdatePickerStyle() {
	var WdateIframe = $dp.dd.getElementsByTagName("iframe");
	if (WdateIframe.length > 0) {
		WdateIframe = WdateIframe[0];
	} else {
		return;
	}
	var doc = WdateIframe.contentWindow.document;
	//当日历表格加载后才执行事件处理
	var _tables = doc.getElementsByTagName("table");
	if (_tables.length == 0) {
		setTimeout(setWdatePickerStyle, 100);
		return;
	}
	$(doc).find('#dpTimeUp,#dpTimeDown').each(function (index, element) {
		$(element).hide();
	});
	var $domOBJ = $(doc).find('.tB,.tE');
	var $okOBJ = $(doc).find("#dpOkInput");
	$domOBJ.each(function (index, element) {
		$(element).unbind();
		$(element).bind('keyup',function(e){
			e.stopPropagation()
			var curValue = $(this).val();
			if (curValue.length==2) {
				if (index != 2) {
				$domOBJ.eq(index+1).focus();
				} else {
					$domOBJ.eq(0).focus();
				}
			}
			if (e.keyCode == "39") {
				if (index != 2) {
					$domOBJ.eq(index+1).focus();
				} else {
					$domOBJ.eq(0).focus();
				}
				return false;
			}
			if (e.keyCode == "37") {
				if (index != 0) {
					$domOBJ.eq(index-1).focus();
				} else {
					$domOBJ.eq(2).focus();
				}
				return false;
			}
			if (e.keyCode == "13") {
				$okOBJ.trigger("click");
				$dp.hide();
			}

		})
	});
}
function GetCellData(rowid, colname) {
    var CellData = "";
    if ($.isNumeric(rowid) == true) {
        var obj = document.getElementById(rowid + "_" + colname);
        //如果为select 取 text
        if (obj) {
            if (obj.type == "select-one") {
                CellData = $("#" + rowid + "_" + colname + " option:selected").text();
            } else if (obj.type == "checkbox") {
                if ($("#" + rowid + "_" + colname).attr("checked") == "checked") {
                    CellData = "Y";
                } else {
                    CellData = "N";
                }
            } else {
                CellData = $("#" + rowid + "_" + colname).val();
            }
        } else {
            CellData = $("#tabDiagnosEntry").getCell(rowid, colname)||'';
        }
    } else {
        var obj = document.getElementById(colname);
        if (obj) {
            CellData = $("#" + colname).val();
        }
    }
    return CellData;
}
//单元格赋值  2014-03-24
function SetCellData(rowid, colname, data) {
    if ($.isNumeric(rowid) == true) {
        var obj = document.getElementById(rowid + "_" + colname);
        if (obj) {
            if (obj.type == "checkbox") {
                // data: true or  false
                var olddata = $("#" + rowid + "_" + colname).attr("checked");
                $("#" + rowid + "_" + colname).attr("checked", data);
            } else {
                var olddata = $("#" + rowid + "_" + colname).val();
                $("#" + rowid + "_" + colname).val(data);
            }
            //对于行上属性的数据修改,模拟onpropertychange事件的实现,在change事件中要同步调用
            //CellDataPropertyChange(rowid, colname, olddata, data);
        } else {
            //rowid,colname,nData,cssp,attrp, forceupd
            //forceupd:true 允许设空值
            $("#tabDiagnosEntry").setCell(rowid, colname, data, "", "", true);
        }
    } else {
        var obj = document.getElementById(colname);
        if (obj) {
            $("#" + colname).val(data);
        }
    }
}
function SetColumnList(rowid, ColumnName, str) {
    //ppppppp
    var Id = "";
    if ($.isNumeric(rowid) == true) {
        var Id = rowid + "_" + ColumnName;
    } else {
        var Id = ColumnName;
    }
    if (typeof str == "undefined") { return }
    var obj = document.getElementById(Id);
    if ((obj) && (obj.type == "select-one")) {
        ClearAllList(obj);
        //医嘱类型
        if (ColumnName == "DiagnosType") {
	        var DefaultDiagnosTypeRowid = "";
        	var DefaultDiagnosTypeDesc = "";
            var ArrData = str.split(";");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(":");
                if (((ArrData1[2] == "Y") && (DefaultDiagnosTypeRowid == "")) || (ArrData.length == 1)) {
                    var DefaultDiagnosTypeRowid = ArrData1[0];
                    var DefaultDiagnosTypeDesc = ArrData1[1];
                }
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            SetCellData(rowid, "DiagnosType", DefaultDiagnosTypeRowid);
       		SetCellData(rowid, "DiagnosTypeRowid", DefaultDiagnosTypeRowid);
        }
    }
}
function ClearAllList(obj) {
    for (var i = obj.options.length - 1; i >= 0; i--) obj.options[i] = null;
}
function GetPreRowId(rowid){
	var prerowid="";
	var rowids=$('#tabDiagnosEntry').getDataIDs();
	if($.isNumeric(rowid)==true){	
		for(var i=rowids.length;i>=0;i--){			
			if(rowids[i]==rowid){
				if(i==0){
					prerowid=rowids[i];
				}else{
					prerowid=rowids[i-1];
				}
				break;
			}
		}
	}
	if(prerowid==""){
		if(rowids.length==0){
			prerowid=""
		}else{
			prerowid=rowids[rowids.length-1];
		}
	}
	return prerowid;
}
function GetNewRowid(){
	var maxRowid=0;
	var rowids=$('#tabDiagnosEntry').getDataIDs();
	for(var i=0;i<rowids.length;i++){
		var rowid=parseInt(rowids[i].split(".")[0]);
		if(rowid>maxRowid) maxRowid=rowid;
	}	
	return maxRowid+1;
}
function IsEmptyRow(rowid)
{
	if(CheckIsItem(rowid)) return false;
	var MRCIDRowId=GetCellData(rowid,"MRCIDRowId");
	var DiagnosNotes=GetCellData(rowid,"DiagnosNotes");
	if (DiagnosNotes!="") DiagnosNotes=DiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
	if ((MRCIDRowId=="" || MRCIDRowId==null)&&(DiagnosNotes=="")){
		return true
	}
	return false;
}
function GetEmptyRowid()
{
	var rowids=$('#tabDiagnosEntry').getDataIDs();
	for(var i=rowids.length-1;i>=0;i--){
		if(IsEmptyRow(rowids[i])){
			return rowids[i];
		}
	}
	return '';
}
function RecalcRowNum()
{
	var rowids=$('#tabDiagnosEntry').getDataIDs();
	for(var i=0;i<rowids.length;i++){
		SetCellData(rowids[i],'id',i+1);
	}
}
function EditRow(rowid){
	if(ServerObj.warning!=""){
		$.messager.alert('提示',ServerObj.warning,'warning');
		return false;
	}
	var DiagnosCatRowId=parseInt(GetCellData(rowid,"DiagnosCatRowId"));
	if(DiagnosCatRowId==0){
		EditRowCommon(rowid);
	}else{
		var Find=false;
		var EditRowids=[];
		var rowids=$('#tabDiagnosEntry').getDataIDs();
		for(var i=0;i<rowids.length;i++){
			var tmpDiagnosCatRowId=parseInt(GetCellData(rowids[i],"DiagnosCatRowId"));
			if(tmpDiagnosCatRowId==0) continue;
			if(tmpDiagnosCatRowId==1){
				if(Find) break;
				EditRowids=[];
			}
			EditRowids.push(rowids[i]);
			if(rowids[i]==rowid) Find=true;
		}
		$.each(EditRowids,function(i,rowid){
			EditRowCommon(rowid);
		});
	}
	SetFocusCell(rowid,"DiagnosNotes");
}
function ChangeRowStyle(rowid,StyleConfigObj){
	for(var key in StyleConfigObj){
		var name=key;
		var value=StyleConfigObj[key];
		if(value==undefined){continue;}
		if($.isNumeric(rowid)==true){	
			if(value==false){
				if($("#"+rowid+"_"+name).hasClass("combogrid-f")){
					//销毁产生的dom对象
					$("#"+rowid+"_"+name).combogrid('destroy'); 
				}else{
					$("#"+rowid+"_"+name).addClass("disable");
				    $("#"+rowid+"_"+name).attr('disabled',true);
				}
				$("#"+rowid+"_"+name).addClass("text-dhcdoc-disabled");
			}else if(value == true){
                if($("#"+rowid+"_"+name).hasClass("combogrid-f")){
					$("#"+rowid+"_"+name).combogrid("enable");
				}else{				
					$("#"+rowid+"_"+name).removeClass("disable");
					$("#"+rowid+"_"+name).attr('disabled',false);
				}
				$("#"+rowid+"_"+name).removeClass("text-dhcdoc-disabled");
			}
		}else{
			if(value==false){
				$("#"+name).attr('disabled',true);
			}else if(value == true){
				$("#"+name).attr('disabled',false);
			}
		}		
	}
}
function GetEventRow(e){
    var rowid="";
    var obj=websys_getSrcElement(e);
	if(obj && obj.id.indexOf("_")>0){
		rowid=obj.id.split("_")[0];
	}
	return rowid
}
function IsEditingRow(rowid)
{
	return $('#tabDiagnosEntry').find('tr#'+rowid).find('input[type=text]').size()>0;
}
function GetICDType(rowid)
{
	var ICDType=GetCellData(rowid,"DiagnosCatRowId");
	if(ICDType==''){
		var DiagnosCat=GetCellData(rowid,"DiagnosCat");
		if(DiagnosCat=='证型') ICDType=2;
		else if(DiagnosCat=='中医') ICDType=1;
		else ICDType=0
	}
	return parseInt(ICDType);
}
function headerDblClick(){
	if(ServerObj.lookupListComponetId != ""){	
		$.m({
		    ClassName:"web.SSGroup",
		    MethodName:"GetAllowWebColumnManager",
		    Id:session['LOGON.GROUPID']
		},function(val){
			if (val==1){
				websys_lu('../csp/websys.component.customiselayout.csp?ID='+ServerObj.lookupListComponetId+'&CONTEXT=K'+ServerObj.ListColSetCls+'.'+ServerObj.ListColSetMth+'.'+ServerObj.XCONTEXT+"&GETCONFIG=1"+"&DHCICARE=2",false);
			}
        })
	}
 }
function Delete_Diag_btn(e){
	if(ServerObj.warning!=""){
		$.messager.alert('提示',ServerObj.warning,'warning');
		return false;
	}
	var IsExistVerifyFlag=false;
	var ids=$('#tabDiagnosEntry').jqGrid("getGridParam", "selarrrow"); 			
	if(ids==null || ids.length==0) {  
		if (PageLogicObj.FocusRowIndex > 0) {
            //如果有焦点行,则直接删除焦点行
            if ($("#jqg_tabDiagnosEntry_" + PageLogicObj.FocusRowIndex).attr("checked") != true) {
                $("#tabDiagnosEntry").setSelection(PageLogicObj.FocusRowIndex, true);
            }
        }
	} 
	var ids = $('#tabDiagnosEntry').jqGrid("getGridParam", "selarrrow");
    if (ids == null || ids.length == 0) {
        $.messager.alert("警告", "请选择需要删除的记录!");
        return;
    }
	var DelCNFlag=false;
	var MRDIARowIdArray = new Array();
	var AllIds = $('#tabDiagnosEntry').getDataIDs();
	for(var i=0;i<AllIds.length;i++){
		var rowid=AllIds[i];
		if(!CheckIsItem(rowid)){
			var DiagnosCatRowId=parseInt(GetICDType(rowid));
			if((ids.indexOf(rowid)>-1)||(DelCNFlag&&(DiagnosCatRowId==2))){
				DelCNFlag=(DiagnosCatRowId>0);
				DeleteRow(rowid);
			}else if(DelCNFlag&&(DiagnosCatRowId!=2)){
				DelCNFlag=false;
			}
		}else{
			if(ids.indexOf(rowid)>-1){
				var MRDIARowId=GetCellData(rowid,"MRDIARowId");
				MRDIARowIdArray.push(MRDIARowId);
			}
		}
	}
	if (MRDIARowIdArray.length>0){
		$.messager.confirm('提示','是否删除已保存的诊断?',function(r){
			if (r){ 
				var DiagItemRowStr=MRDIARowIdArray.join("^");
				DeleteMRDiagnos(DiagItemRowStr);
			}else{
				RecalcRowNum();
			}
		})
	}else{
		RecalcRowNum();
	}
	var records=$('#tabDiagnosEntry').getGridParam("records");
	if(records==0){
		Add_Diag_row();					
	}
	return websys_cancel();
}
function DeleteMRDiagnos(DiagItemRowStr) {
	var UpdateObj={
		EpisodeID:ServerObj.EpisodeID,
		PAAdmType:ServerObj.PAAdmType,
        DiagItemRowStr:DiagItemRowStr
	}
	new Promise(function(resolve,rejected){
		//电子签名
		var CAInputObj={
			callType:"DiagDelect",
			isHeaderMenuOpen:false
		}
		Common_ControlObj.BeforeUpdate("CASignCheck",CAInputObj,resolve);
	}).then(function(RtnObj){
		return new Promise(function(resolve,rejected){
	    	if (RtnObj == false || RtnObj.PassFlag == false) {
	    		return false;
	    	}
		    $.extend(UpdateObj, RtnObj.CAObj);
			resolve(true);
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
	    	Common_ControlObj.BeforeUpdate("DeleteCheck",UpdateObj,resolve);
		})
	}).then(function(Rtn){
		return new Promise(function(resolve,rejected){
	    	if (Rtn == false) {
	    		return false;
	    	}
			resolve(true);
		})
	}).then(function(){
	    var ret = cspRunServerMethod(ServerObj.DeleteMRDiagnosMethod, DiagItemRowStr,session['LOGON.USERID'],session['LOGON.CTLOCID']);
		var retCode=ret.split("^")[0];
		if (retCode != '0') {
			$.messager.alert("警告","删除失败:"+retCode);	
			return false;
		}else {
			$.extend(UpdateObj, {
				DiagItemIDs: ret,
				CACallType: "DeDiag"
			});
			AfterInsertOrDeleteDiag("Delete",UpdateObj);
		}
	})
}
function CheckIsItem(rowid){
	var id=parseInt(rowid);
	if($.isNumeric(id)==true){
		var MRDIARowId=GetCellData(id,"MRDIARowId");
		if(MRDIARowId != ""){
			return true;
		}else{
			return false;
		}
	}else{
		return false;
	}
}
function BMoveUpclickhandler(){
	if ($("#MoveUp_Diag_btn").hasClass('l-btn-disabled')){
		return false;
	}
	DisableBtn("MoveUp_Diag_btn",true);
	var rowids=GetCheckedRow("U");
	if(rowids.length){
		mysort(rowids[0], 'up');
	}
	DisableBtn("MoveUp_Diag_btn",false);
}
function BMoveDownclickhandler(){
	if ($("#MoveDown_Diag_btn").hasClass('l-btn-disabled')){
		return false;
	}
	DisableBtn("MoveDown_Diag_btn",true);
	var rowids=GetCheckedRow("D")
	if(rowids.length){
		mysort(rowids[0], 'down');
	}
	DisableBtn("MoveDown_Diag_btn",false);
}
function BMoveLeftclickhandler(){
	if ($("#MoveLeft_Diag_btn").hasClass('l-btn-disabled')){
		return false;
	}
	DisableBtn("MoveLeft_Diag_btn",true);
	var rowids=GetCheckedRow("L");
	if(rowids.length){
		if(HorizontalMove(rowids,-1)){
			UpdateDiagLevel();
		}
	}
	DisableBtn("MoveLeft_Diag_btn",false);
}  
function BMoveRightclickhandler(){
	if ($("#MoveRight_Diag_btn").hasClass('l-btn-disabled')){
		return false;
	}
	DisableBtn("MoveRight_Diag_btn",true);
	var rowids=GetCheckedRow("R");
	if(rowids.length){
		if(HorizontalMove(rowids,1)){
			UpdateDiagLevel();
		}
	}
	DisableBtn("MoveRight_Diag_btn",false);
}
function GetCheckedRow(type){
	var ids=$('#tabDiagnosEntry').jqGrid("getGridParam", "selarrrow");
	var FindRowid=[];
	for(var i=0;i<ids.length;i++){
		var MRDIARowId=GetCellData(ids[i],"MRDIARowId");
		if (["U","D"].indexOf(type)>-1){
			var MainMRDIADr=GetCellData(ids[i],"MRDIAMRDIADR");
			if(MainMRDIADr){
				if(FindRowid.indexOf(MainMRDIADr)==-1){
					$.messager.alert("提示","请选择对应的中医诊断移动!","info",function(){
						$("#tabDiagnosEntry").setSelection(ids[i],false);
					});
					return [];
				}
			}else{
				FindRowid.push(MRDIARowId);
			}
		}else{
			FindRowid.push(MRDIARowId);
		}
	}
	if(FindRowid.length==0) {  
		$.messager.alert("提示","请选择行!");  
		return [];  
	}else if((["U","D"].indexOf(type)>-1)&&(FindRowid.length>1)){
		$.messager.alert("提示","请勾选一条记录!");
		return [];  
	}
	return ids.sort();
}
function HorizontalMove(ids,Direction){
	if(!Direction) Direction=0;
	var rowids=new Array();
	for(var i=0;i<ids.length;i++){
		var GroupRowids=GetGroupRowids(ids[i]);
		for(var j=0;j<GroupRowids.length;j++){
			if(rowids.indexOf(GroupRowids[j])==-1){
				rowids.push(GroupRowids[j]);
			}
		}
	}
	rowids=rowids.sort();
	var SpaceHTML="&nbsp;&nbsp;&nbsp;&nbsp;"
	var flag=false;
	for(var i=0;i<rowids.length;i++){
		var rowid=rowids[i];
		var DiagnosLeavel=parseInt(GetCellData(rowid,"DiagnosLeavel"));
		DiagnosLeavel=DiagnosLeavel+parseInt(Direction);
		var DiagnosCatRowId=parseInt(GetICDType(rowid));
		if ((DiagnosCatRowId<2 && DiagnosLeavel<1)||(DiagnosCatRowId==2 && DiagnosLeavel<2)){
			continue;
		}
		var Space="";
		for(var j=1;j<DiagnosLeavel;j++){
			Space+=SpaceHTML;
		}
		if(!flag&&CheckIsItem(rowid)){
			flag=true;
		}
		var DiagnosICDDesc=GetCellData(rowid,"DiagnosICDDesc");
		DiagnosICDDesc=Space+$.trim(DiagnosICDDesc.replace(/&nbsp;/g,'').replace(/&nbsp/g,''))
		if (IsEditingRow(rowid)) {
			SetCellData(rowid,"DiagnosICDDesc",DiagnosICDDesc.replace(/&nbsp;/g,' '));
		}else{
			SetCellData(rowid,"DiagnosICDDesc",DiagnosICDDesc);
		}
		SetCellData(rowid,"DiagnosLeavel",DiagnosLeavel)
	}
	return flag;
}
function GetGroupRowids(rowid,validRowFlag)
{
	var GroupRowids=new Array();
	var MRDIARowId=GetCellData(rowid,"MRDIAMRDIADR")||GetCellData(rowid,"MRDIARowId"); 
	var rowids = $('#tabDiagnosEntry').getDataIDs();
	if(MRDIARowId){
		for(var i=0;i<rowids.length;i++){
			var TmpRowID=GetCellData(rowids[i],"MRDIARowId"); 
			var TmpMain=GetCellData(rowids[i],"MRDIAMRDIADR"); 
			if((TmpMain==MRDIARowId)||(TmpRowID==MRDIARowId)){
				GroupRowids.push(rowids[i]);
			}
		}
	}else{
		var DiagnosCatRowId=parseInt(GetICDType(rowid));
		var FindFlag=false;
		var tmpGroupRowids=[];
		for(var i=0;i<rowids.length;i++){
			if(CheckIsItem(rowids[i])) continue;
			if(validRowFlag&&IsEmptyRow(rowids[i])) continue;
			var tmpDiagnosCatRowId=parseInt(GetICDType(rowids[i]));
			if(tmpDiagnosCatRowId!=2){
				if(FindFlag) break;
				tmpGroupRowids=[];
			}
			if(((DiagnosCatRowId>0)&&(tmpDiagnosCatRowId>0))||(rowids[i]==rowid)){
				if(rowids[i]==rowid) FindFlag=true;
				tmpGroupRowids.push(rowids[i])
			}
		}
		if(FindFlag) GroupRowids=tmpGroupRowids;
	}
	return GroupRowids;
}
//和之前保持一致,只能交换已保存行
function mysort(rowid, type) {
	var rowids = $('#tabDiagnosEntry').getDataIDs();
	var SelIds=GetGroupRowids(rowid);
	var ChangeIndex=type=='up'?(rowids.indexOf(SelIds[0])-1):(rowids.indexOf(SelIds[SelIds.length-1])+1);
	var changeRowid=rowids[ChangeIndex];
	if(!changeRowid) return;
	var ChangeIds=GetGroupRowids(changeRowid);
	if(!ChangeIds.length) return;
	var NewSortRowids=type=='up'?SelIds.concat(ChangeIds):ChangeIds.concat(SelIds);
	/*for(var i=0;i<NewSortRowids.length;i++){
		var EditStatus=IsEditingRow(NewSortRowids[i]);
		if(!CheckIsItem(NewSortRowids[i])){
			$.messager.popover({msg:'移动目标行是未保存诊断,不能交换顺序',type:'alert'});
			return false;
		}
	}*/
	var OldSortRowids=NewSortRowids.slice(0).sort(function(a, b){ return a - b; });
	var NewSortData=new Array();
	for(var i=0;i<NewSortRowids.length;i++){
		var EditStatus=IsEditingRow(NewSortRowids[i]);
		if(EditStatus) $("#tabDiagnosEntry").saveRow(NewSortRowids[i]);
		var rowData=$("#tabDiagnosEntry").getRowData(NewSortRowids[i]);
		rowData.id=OldSortRowids[i];
		rowData.EditStatus=EditStatus;
		NewSortData.push(rowData);
	}
	for(var i=0;i<NewSortData.length;i++){
		var newRowid=NewSortData[i].id;
		$("#tabDiagnosEntry").jqGrid("setRowData",newRowid,NewSortData[i]);
		$('#tabDiagnosEntry').find('tr#'+newRowid).find('.DiagSaved').removeClass('DiagSaved');
		var DiagnosICDDesc=NewSortData[i].DiagnosICDDesc;
		var DiagnosPrefix=NewSortData[i].DiagnosPrefix;
		var DiagnosNotes=NewSortData[i].DiagnosNotes;
		if (DiagnosICDDesc!=""){
			$('#tabDiagnosEntry').setCell(newRowid,"DiagnosICDDesc",DiagnosICDDesc,"DiagSaved","")
		}else if (DiagnosPrefix){
			$('#tabDiagnosEntry').setCell(newRowid,"DiagnosPrefix",DiagnosPrefix,"DiagSaved","")
		}else if (DiagnosNotes){
			$('#tabDiagnosEntry').setCell(newRowid,"DiagnosNotes",DiagnosNotes,"DiagSaved","")
		}
		if(NewSortData[i].EditStatus){
			EditRowCommon(newRowid);
		}
		InitRowBtn(newRowid);
	}
	//重新选择行
	$("#tabDiagnosEntry").jqGrid('resetSelection');
	for(var i=0;i<SelIds.length;i++){
		var oldRowid=SelIds[i];
		var rowid=OldSortRowids[NewSortRowids.indexOf(oldRowid)];
		$("#tabDiagnosEntry").setSelection(rowid,true);
	}
	UpdateDiagSeq();
	return true;
}
function UpdateDiagSeq(SaveFlag)
{
	var DiagRows=new Array();
	var rowids=$('#tabDiagnosEntry').getDataIDs();
    for (var i=0;i<=rowids.length;i++) {
	    if(CheckIsItem(rowids[i])){
			var MRDIARowId=GetCellData(rowids[i],"MRDIARowId");
			DiagRows.push({DiagRowid:MRDIARowId,Sequence:i+1});
		}
	}
	if(!DiagRows.length) return;
	var ret=$.cm({
		ClassName:"web.DHCDocDiagnosEntryV8",
		MethodName:"UpdateDiagSeq",
		DiagnosStr:JSON.stringify(DiagRows),
		UserID:session['LOGON.USERID'],
		dataType:'text'
	},false)
	if(!SaveFlag){
		if(ret!=0){
			$.messager.alert("提示","顺序调整失败:"+ret); 
		}else{
			SaveMRDiagnosToEMR();
		}
	}
}
function UpdateDiagLevel()
{
	var DiagRows=new Array();
	var rowids=$('#tabDiagnosEntry').getDataIDs();
    for (var i=0;i<=rowids.length;i++) {
	    if(CheckIsItem(rowids[i])){
			var MRDIARowId=GetCellData(rowids[i],"MRDIARowId");
			var DiagnosLeavel=GetCellData(rowids[i],"DiagnosLeavel");
			DiagRows.push({DiagRowid:MRDIARowId,Level:DiagnosLeavel});
		}
	}
	if(!DiagRows.length) return;
	var ret=$.cm({
		ClassName:"web.DHCDocDiagnosEntryV8",
		MethodName:"UpdateDiagLevel",
		DiagnosStr:JSON.stringify(DiagRows),
		UserID:session['LOGON.USERID'],
		dataType:'text'
	},false)
	if(ret!=0){
		$.messager.alert("提示","级别调整失败:"+ret); 
	}
}
function CopyDiagshow(){
    if (!CheckIsDischarge()) return false;
    var ExistSavedDiagFlag=0;
    var ids=$('#tabDiagnosEntry').jqGrid("getGridParam", "selarrrow"); 			
	for (var i=0;i<ids.length;i++){
		var MRDIARowId=GetCellData(ids[i],"MRDIARowId");
		if (MRDIARowId!="") {
			ExistSavedDiagFlag=1;
			break;
		}
	}
	if (ExistSavedDiagFlag=="0"){
		$.messager.alert("提示","请选择需要复制的已保存诊断");  
		return; 
	}
	destroyDialog("CopyDiag");
    var Content=initDiagDivHtml("CopyDiag");
    var iconCls="icon-w-copy";
    DiagCreateModalDialog("CopyDiag",$g("复制诊断"), 300, 145,iconCls,$g("复制"),Content,"CopyDiag()");
    var cbox = $HUI.combobox("#combo_DiagType", {
		editable: false,
		multiple:false,
		mode:"local",
		method: "GET",
		selectOnNavigation:true,
	  	valueField:'id',
	  	textField:'text',
	  	data:ServerObj.DiagnosTypeJson,
	  	onLoadSuccess:function(){
			var sbox = $HUI.combobox("#combo_DiagType");
			sbox.select(ServerObj.DedfaultDiagnosTypeID);
		}
	});
}
function CopyDiag(){
	var idsArr=new Array();
	var ids=$('#tabDiagnosEntry').jqGrid("getGridParam", "selarrrow");
	var sbox = $HUI.combobox("#combo_DiagType");
	var CopyToDiagTypeId=sbox.getValue();
	var CopyToDiagType=sbox.getText();
	new Promise(function(resolve,rejected){
		var ParResolve=resolve;
		var LoopCallBackFun=function(i){
			if(i>=ids.length){
				ParResolve();
				return;
			}
			var rowid=ids[i];
			var MRDIARowId=GetCellData(rowid,"MRDIARowId");
			if(!MRDIARowId){
				ParResolve();
				return;
			}
			new Promise(function(resolve,rejected){
				var MRCIDRowId=GetCellData(rowid,"MRCIDRowId");
				if(!MRCIDRowId){
					var alertMsg=GetEntryNoICDDiagAuit(rowid);
					if(alertMsg!=""){
						$.messager.alert('提示',$g('第')+rowid+$g('条诊断不能复制,')+alertMsg,'info',function(){
							//resolve();
						});
						return;
					}
				}else{
					if(!CheckDiagIsEnabled(MRCIDRowId,function(ret){
						if(ret) resolve();
					})){
						return;
					}
				}
				resolve();
			}).then(function(){
				return new Promise(function(resolve,rejected){
					var DiagnosTypeRowId=GetCellData(rowid,"DiagnosTypeRowId");
					if(DiagnosTypeRowId==CopyToDiagTypeId){
						$.messager.confirm('提示',$g("第")+rowid+$g('条与复制诊断类型相同,均为【')+CopyToDiagType+$g('】,是否继续?'),function(r){
							if(r) resolve();
						});
					}else{
						resolve();
					}
				});
			}).then(function(){
				var MRDIAMRDIADR=GetCellData(rowid,"MRDIAMRDIADR");
				var DiagRowid=MRDIAMRDIADR||MRDIARowId;
				if(idsArr.indexOf(DiagRowid)==-1){
					idsArr.push(DiagRowid);
				}
				LoopCallBackFun(++i);
			});
		}
		LoopCallBackFun(0);
	}).then(function(){
		if(idsArr.length){
			CheckBeforeInsertMRDiag(function(){
				$.m({
					ClassName:"web.DHCDocDiagnosEntryV8",
					MethodName:"CopyMulDiag",
					ADiagnosIDStr:idsArr.join('^'),
					ALocId:session['LOGON.CTLOCID'],
					AUserId:session['LOGON.USERID'],
					CopyToDiagTypeId:CopyToDiagTypeId,
					AdmPara:GetAdmPara()
				},function(val){
					if (val.split("^")[0]=="0"){
						var UpdateObj={
							EpisodeID:ServerObj.EpisodeID,
							PAAdmType:ServerObj.PAAdmType,
							DiagItemIDs:val
						}
						AfterInsertOrDeleteDiag("Insert",UpdateObj);
					}else{
						$.messager.alert("提示","诊断复制失败!");  
						return; 
					}
				});
			});
		}
		destroyDialog("CopyDiag");
	});
}

function AfterInsertOrDeleteDiag(Type,UpdateObj){
	var DiagItemIDs=UpdateObj.DiagItemIDs;
	if (Type=="Insert") {	//保存诊断
		//存在中间插入情况，此处更新顺序
		var InsertDiagItemIDArr=new Array();
		var DiagItemIDArr=UpdateObj.DiagItemIDs.split("^");
		for(var i=0;i<DiagItemIDArr.length;i++){
			var tmpArr=DiagItemIDArr[i].split(String.fromCharCode(1));
			if(tmpArr[2]=='A'){
				InsertDiagItemIDArr.push(tmpArr[0]);
			}
		}
		var UpdateCnt=0;
		var rowids=$('#tabDiagnosEntry').getDataIDs();
		for(var i=0;i<rowids.length;i++){
			if(!IsEmptyRow(rowids[i])&&!CheckIsItem(rowids[i])&&InsertDiagItemIDArr[UpdateCnt]){
				var MRDIARowId=InsertDiagItemIDArr[UpdateCnt];
				SetCellData(rowids[i],'MRDIARowId',MRDIARowId);
				UpdateCnt++;
			}
		}
		if(UpdateCnt) UpdateDiagSeq(true);
		ServerObj.defMainDiagFlag="N";
		//刷新本次诊断
		ReloadDiagEntryGrid();
		//重组数据串
		var DiagItemIDsArr=DiagItemIDs.split("^");
		DiagItemIDsArr.splice(0,1);
		DiagItemIDs=DiagItemIDsArr.join("^");
	}else if (Type=="Delete") {	//删除诊断
		//刷新本次诊断
		//ReloadDiagEntryGrid();
		var delMRDiagnosStr=DiagItemIDs.split("^")[1];
		var rowids = $('#tabDiagnosEntry').getDataIDs();
		var len=rowids.length;
		for(var i =(len-1);i>=0;i--){
			var MRDIARowId=GetCellData(rowids[i],"MRDIARowId");
			if (("$"+delMRDiagnosStr+"$").indexOf("$"+MRDIARowId+"$")>=0) {
				DeleteRow(rowids[i]);
			}
		}
		DiagItemIDs=delMRDiagnosStr.replace(/\$/g,"^");
		RecalcRowNum();
	}
	//调用电子病历接口
	SaveMRDiagnosToEMR();
	//加载历史诊断
	LoadHistoryDiag();
	//刷新患者信息栏
	if (window.parent.refreshBar){
		window.parent.refreshBar();
	}
	$.extend(UpdateObj, { DiagItemIDs: DiagItemIDs});
	//入径检查
	if (Type=="Insert") Common_ControlObj.AfterUpdate("ShowCPW",UpdateObj);
	//数据同步【CA、CDSS】
	Common_ControlObj.AfterUpdate("SynData",UpdateObj);	
	//第三方接口调用
	Common_ControlObj.AfterUpdate("Interface",UpdateObj);
}
function DiagCreateModalDialog(id, _title, _width, _height, _icon,_btntext,_content,_event){
	var buttons=[{
		text:$g(_btntext),
		iconCls:_icon,
		handler:function(){
			if(_event!="") eval(_event);
		}
	}]
    $("body").append("<div id='"+id+"' class='hisui-dialog' style='overflow:hidden;'></div>");
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
        buttons:buttons
    });
}
function initDiagDivHtml(type){
	if(type="CopyDiag"){
		var html="<table style='margin:16px auto;'>" 
			html +="	 <tr>"
			
		       	html +="	 <td>"
		       		html +="	 "+$g("诊断类型")
		       	html +="	 </td>"
		       	html +="	 <td>"
		       		html +="	 <input id='combo_DiagType' class='textbox'/>"
		       	html +="	 </td>"
		       	
	       html +="	 </tr>"
	       
	       
		html += "</table>"
	}
	return html;
}
function destroyDialog(id){
   $("body").remove("#"+id); //移除存在的Dialog
   $("#"+id).dialog('destroy');
}
function GetAdmPara(){
    var DiagnosValue=1
	var Admway="",ILI="",ReAdmis="",FirstAdm="",OutReAdm="",TransAdm="";
	if (ServerObj.PAAdmType!="I"){
		var o=$HUI.radio("#ReAdmis")
		if (o.getValue()==true) { ReAdmis="R";Admway="MZFZ";}else{ReAdmis="";}
		var o=$HUI.radio("#FirstAdm")
		if (o.getValue()==true) {FirstAdm="F";Admway="CZ"}else{FirstAdm="";}
		var o=$HUI.radio("#OutReAdm")
		if (o.getValue()==true) {OutReAdm="R";Admway="CYFZ";}else{OutReAdm="";}
		var o=$HUI.checkbox("#TransAdm")
		if (o.getValue()==true) {TransAdm="Y";Admway="ZZ"}else{TransAdm="";}
		var o=$HUI.checkbox("#ILI")
		if (o.getValue()==true) {ILI="Y"}
	}
	
	
	var BPSystolic=$("#BPSystolic").val();
	var BPDiastolic=$("#BPDiastolic").val();
	var Weight=$("#Weight").val();
	var o=$HUI.combobox("#Special");
	var Specialist=o.getValues().join("!");
	var Subject=""
	var PhysiologicalCycle="";
	var Height=$("#Height").val();
	var AdmPara=ReAdmis+"^"+Specialist+"^"+Subject+"^"+Weight+"^"+FirstAdm+"^"+OutReAdm+"^"+TransAdm+"^"+ILI+"^"+DiagnosValue+"^"+Admway+"^"+BPSystolic+"^"+BPDiastolic+"^"+PhysiologicalCycle+"^"+Height;
	return AdmPara;
 }
function CheckBeforeInsertMRDiag(callBackFun){
    if (!CheckIsAdmissions(ServerObj.EpisodeID)) return false;
    if (!CheckAdmBlood()) return false;
	var Admway="",ILI="",ReAdmis="",FirstAdm="",OutReAdm="",TransAdm="";
	if (ServerObj.PAAdmType!="I"){
		var o=$HUI.radio("#ReAdmis")
		if (o.getValue()==true) { ReAdmis="R";Admway="MZFZ";}else{ReAdmis="";}
		var o=$HUI.radio("#FirstAdm")
		if (o.getValue()==true) {FirstAdm="F";Admway="CZ"}else{FirstAdm="";}
		var o=$HUI.radio("#OutReAdm")
		if (o.getValue()==true) {OutReAdm="R";Admway="CYFZ";}else{OutReAdm="";}
		var o=$HUI.checkbox("#TransAdm")
		if (o.getValue()==true) {TransAdm="Y";Admway="ZZ"}else{TransAdm="";}
		var o=$HUI.checkbox("#ILI")
		if (o.getValue()==true) {ILI="Y"}
	}
	if ((ReAdmis=="")&&(FirstAdm=="")&&(OutReAdm=="")&&(ServerObj.PAAdmType!="I")) {
		$.messager.alert("提示","初诊、门诊复诊或出院复诊不能同时为空！","info")
		return false;
	}
	
	var SeriousDiseaseICDStr="",DiagnosNotesStr="";
	var DiagTypeObj={};
	var PrevCatRowId='',ErrRowIndex='';
	//判断诊断是否重复 就放在前台本次所有诊断判断，提高效率 wqy 20210712
	var NewDiagObj={ICD:{},Note:{}},OldDiagObj={ICD:{},Note:{}};
	var rowids = $('#tabDiagnosEntry').getDataIDs();
	new Promise(function(resolve,rejected){
		(function(callBackFunExec){
			function loop(rowIndex){
				var MRDIARowId=GetCellData(rowids[rowIndex],"MRDIARowId");
				var MRCIDRowId=GetCellData(rowids[rowIndex],"MRCIDRowId");
				var DiagnosICDDesc=GetCellData(rowids[rowIndex],"DiagnosICDDesc"); 
				if (DiagnosICDDesc=="") MRCIDRowId="";
				var DiagnosNotes=GetCellData(rowids[rowIndex],"DiagnosNotes").replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
				var DiagnosDoctor=GetCellData(rowids[rowIndex],"DiagnosDoctor");
				var DiagnosOnsetDate=GetCellData(rowids[rowIndex],"DiagnosOnsetDate");
				var DiagnosDate=GetCellData(rowids[rowIndex],"DiagnosDate");
				var DiagnosType=GetCellData(rowids[rowIndex],"DiagnosTypeRowId");
				var DiagnosTypeDesc=GetCellData(rowids[rowIndex],"DiagnosType");
				var MainDiagFlag=GetCellData(rowids[rowIndex],"MainDiagFlag");
				var DiagnosCatRowId=GetCellData(rowids[rowIndex],"DiagnosCatRowId");
				var SDSDesc=GetCellData(rowids[rowIndex],"SDSDesc");
				var Desc=SDSDesc?SDSDesc:DiagnosICDDesc;
				var AddUserDr=GetCellData(rowids[rowIndex],"AddUserDr");
				var DiagnosUserDr=GetCellData(rowids[rowIndex],"DiagnosUserDr");
				var id=GetCellData(rowids[rowIndex],"id");
				new Promise(function(resolve,rejected){
					if ((MRCIDRowId=="")&&(DiagnosNotes=="")) {
						if (MRDIARowId!=""){
							$.messager.alert('提示',$g('第')+id+$g("条诊断,修改后的诊断备注不能为空!"),"info",function(){
								SetFocusCell(rowids[rowIndex],"DiagnosNotes");
							});
							return false;
						}else{
							//continue
							rowIndex++;
							if ( rowIndex < rowids.length ) {
								loop(rowIndex);
							}else{
								callBackFunExec();
							}
							return false
						}
					}
					if (!MRCIDRowId&&!MRDIARowId) {
						var AuitMsg=GetEntryNoICDDiagAuit(rowids[rowIndex]);
						if (AuitMsg!="") {
							$.messager.alert('提示',$g('第')+id+$g("条诊断【")+DiagnosNotes+"】"+$g(AuitMsg),"info",function(){
								SetFocusCell(rowids[rowIndex],"DiagnosNotes");
							});
							return false;
						}
					}
					if (DiagnosOnsetDate!=""){
						if (!DATE_FORMAT.test(DiagnosOnsetDate)){
							$.messager.alert('提示',$g('第')+id+$g("条诊断的发病日期格式不正确!"),"info",function(){
								SetFocusCell(rowids[rowIndex],"DiagnosOnsetDate");
							});
							return false;
						}else if(CompareDate(DiagnosOnsetDate,ServerObj.CurrentDate)){ //DiagOnsetDate>end
							$.messager.alert('提示',$g('第')+id+$g("条诊断的发病日期不能大于今天!"),"info",function(){
								SetFocusCell(rowids[rowIndex],"DiagnosOnsetDate");
							});
							return false;
						}
					}else{
						$.messager.alert("提示","发病日期不能为空","info",function(){
							SetFocusCell(rowids[rowIndex],"DiagnosOnsetDate");
						});
						return false;
					}
					if (DiagnosDate!=""){
						if (!DATE_FORMAT.test(DiagnosDate)){
							$.messager.alert('提示',$g('第')+id+$g("条诊断的诊断日期格式不正确!"),"info",function(){
								SetFocusCell(rowids[rowIndex],"DiagnosDate");
							});
							return false;
						}
						if(CompareDate(DiagnosDate,ServerObj.CurrentDate)){ // DiagDate>end
							$.messager.alert('提示',$g('第')+id+$g("条诊断的诊断日期不能大于今天!"),"info",function(){
								SetFocusCell(rowids[rowIndex],"DiagnosDate");
							});
							return false;
						}
						if ((DiagnosOnsetDate!="")&&(CompareDate(DiagnosOnsetDate,DiagnosDate))) { //DiagDate<DiagOnsetDate
							$.messager.alert('提示',$g('第')+id+$g("条诊断的诊断日期不能早于发病日期: ")+DiagnosOnsetDate,"info",function(){
								SetFocusCell(rowids[rowIndex],"DiagnosDate");
							});
							return false;
						}
					}
					resolve();
				}).then(function(){
					return new Promise(function(resolve,rejected){
						if (IsEditingRow(rowids[rowIndex])&&(DiagnosDate!="")&&(ServerObj.AdmBedDate!="")&&(CompareDate(ServerObj.AdmBedDate,DiagnosDate))){ //DiagDate<AdmBedDate
							//if (((MRDIARowId!="")&&(DiagnosDoctor==""))||(ServerObj.PAAdmType!="I")){
							//}else{
							//诊断录入人与下诊断人不一致，则认为是从住院证带入的诊断，该诊断可以进行修改
							if ((MRDIARowId=="")||((MRDIARowId!="")&&(AddUserDr==DiagnosUserDr))){
								$.messager.alert('提示',$g('第')+id+$g("条诊断的诊断日期不能早于分床日期: ")+ServerObj.AdmBedDate,"info",function(){
									SetFocusCell(rowids[rowIndex],"DiagnosDate");
								});
								return false;
							}else{
								$.messager.confirm('提示:'+$g("入院登记或其他渠道诊断"),$g('第')+id+$g("条诊断的诊断日期早于分床日期")+ServerObj.AdmBedDate+"，"+$g("请确认是否继续保存?"),function(r){
									if (!r){
										SetFocusCell(rowids[rowIndex],"DiagnosDate");
										return false;
									}else{
										resolve()
									}
								});
							}
						}else{
							resolve()
						}
					})
				}).then(function(){
					return new Promise(function(resolve,rejected){
						if ((MRDIARowId=="")&&(DiagnosType=="")){
							$.messager.alert("提示","诊断类型不能为空","info");
							return false;
						}
						if(DiagTypeObj[DiagnosType] == true) {
							if (MainDiagFlag==$g("是") && ("^"+ServerObj.MainDiagLimit+"^").indexOf("^"+DiagnosType+"^")>=0) {
								$.messager.alert("提示",$g("只能存在一条")+DiagnosTypeDesc+$g(" 诊断类型的主诊断，请返回修改!"),"info");
								return false;
							}
						}else {
							DiagTypeObj[DiagnosType]=(MainDiagFlag==$g("是"));
						}
						
						if (MRDIARowId==""){
							if ((MRCIDRowId!="")&&(MRCIDRowId!=null)){
								if (!CheckDiagIsEnabled(MRCIDRowId)) return false;
								var SeriousDisease=cspRunServerMethod(ServerObj.GetSeriousDiseaseByICDMethod,MRCIDRowId);
								if (SeriousDisease=="Y"){
									if (SeriousDiseaseICDStr=="") SeriousDiseaseICDStr=DiagnosICDDesc;
									else  SeriousDiseaseICDStr=SeriousDiseaseICDStr+","+DiagnosICDDesc;
								}
							}
							if((DiagnosCatRowId=='2')&&(PrevCatRowId!='1')&&(PrevCatRowId!='2')){
								$.messager.alert('提示',$g('第')+id+$g('条是中医证型,必须伴随中医诊断开具'));
								return false;
							}
							if(ServerObj.CNDiagWithSyndrome&&(PrevCatRowId=='1')&&(DiagnosCatRowId!='2')){
								//break;
								callBackFunExec();
								return;
							}
							ErrRowIndex=rowids[rowIndex];
							PrevCatRowId=DiagnosCatRowId;
						}
						//存入新增或修改诊断用于重复判断,不掉后台WQY
						if(IsEditingRow(rowids[rowIndex])){
							if ((MRCIDRowId!="")&&(MRCIDRowId!=null)){
								if(!NewDiagObj.ICD[MRCIDRowId]) NewDiagObj.ICD[MRCIDRowId]={Desc:Desc,Count:1,Seq:[rowIndex]};
								else {
									NewDiagObj.ICD[MRCIDRowId].Count++;
									NewDiagObj.ICD[MRCIDRowId].Seq.push(rowIndex);
								}
							}else{
								if(!NewDiagObj.Note[DiagnosNotes]) NewDiagObj.Note[DiagnosNotes]={Desc:DiagnosNotes,Count:1,Seq:[rowIndex]};
								else {
									NewDiagObj.Note[DiagnosNotes].Count++;
									NewDiagObj.Note[DiagnosNotes].Seq.push(rowIndex);
								}
								if(DiagnosNotesStr=="") DiagnosNotesStr=DiagnosNotes;
								else DiagnosNotesStr=DiagnosNotesStr+";"+DiagnosNotes;
							}
						}else{
							if ((MRCIDRowId!="")&&(MRCIDRowId!=null)){
								if(!OldDiagObj.ICD[MRCIDRowId]) OldDiagObj.ICD[MRCIDRowId]={Desc:Desc,Count:1};
								else OldDiagObj.ICD[MRCIDRowId].Count++;
							}else{
								if(!OldDiagObj.Note[DiagnosNotes]) OldDiagObj.Note[DiagnosNotes]={Desc:DiagnosNotes,Count:1};
								else OldDiagObj.Note[DiagnosNotes].Count++;
							}
						}
						resolve()
					})
				}).then(function(){
					rowIndex++;
					if ( rowIndex < rowids.length ) {
						loop(rowIndex);
					}else{
						callBackFunExec();
					}
				})
			}
			loop(0)
		})(resolve);
	}).then(function(){
    	return new Promise(function(resolve,rejected){
			if(ServerObj.CNDiagWithSyndrome&&(PrevCatRowId=='1')){
				$.messager.alert('提示',$g('第')+ErrRowIndex+$g('条是中医诊断,必须录入中医证型'));
				return false;
			}
			if (typeof DiagTypeObj[ServerObj.DISDiagnosTypeRowId]!="undefined" && DiagTypeObj[ServerObj.DISDiagnosTypeRowId]==false){
				$.messager.confirm('提示', "此次所开出院诊断列表中没有【主诊断】,请确认是否继续保存?", function(r){
					if (r) {
						resolve();
					}
				});
				return;
			}
			resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			if (typeof DiagTypeObj[ServerObj.InsDiagnosTypeRowId]!="undefined" && DiagTypeObj[ServerObj.InsDiagnosTypeRowId]==false){
			    $.messager.confirm('提示', "此次所开入院诊断列表中没有【主诊断】,请确认是否继续保存?", function(r){
				    if (r) {
						resolve();
					}
				});
				return;
			}
			resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			if(DiagnosNotesStr!=""){
			    $.messager.confirm('提示', "是否确定录入非标准ICD诊断?", function(r){
				    if (r) {
						resolve();
					}
				});
				return;
			}
			resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			var RepeatDiagStr='';
            var DelSeqNoArr=[];
			for(var type in NewDiagObj){
				for(var key in NewDiagObj[type]){
					if((NewDiagObj[type][key].Count>1)||(OldDiagObj[type][key])){
						if(RepeatDiagStr=='') RepeatDiagStr=NewDiagObj[type][key].Desc
						else RepeatDiagStr=RepeatDiagStr+','+NewDiagObj[type][key].Desc
                        var DelSeqArr=[];
                        if (OldDiagObj[type][key]){
							DelSeqArr=NewDiagObj[type][key].Seq;
						}else{
                            DelSeqArr=NewDiagObj[type][key].Seq.splice(0,1);
						}
                        DelSeqNoArr=DelSeqNoArr.concat(DelSeqArr);
					}
				}
			}
			if(RepeatDiagStr!=""){
			    $.messager.confirm('提示', RepeatDiagStr+$g(",所加诊断在本次诊断中已经存在,请确认是否重复增加?"), function(r){
				    if (r) {
						resolve();
					}else{
                        //自动删除重复行
                        if (ServerObj.AutoDeleteReDiag=="Y"){
                            for (var i=0; i<DelSeqNoArr.length; i++){
                                var Seq=DelSeqNoArr[i];
								DeleteRow(rowids[Seq]);
                            }
							RecalcRowNum();
                        }
                    }
				});
				return;
			}
			resolve();
		});
	}).then(function(){
		return new Promise(function(resolve,rejected){
			if(SeriousDiseaseICDStr!=""){
				$.messager.alert("提示",SeriousDiseaseICDStr+$g("诊断为传染病诊断,请注意及时上报."),"info",function(){
					resolve();
				});
				return;
			}
			resolve();
		});
	}).then(function(){
		callBackFun();
	})
 }
function CheckIsAdmissions(EpisodeID) {
	if (ServerObj.EpisodeID=="") return false;
	if(ServerObj.warning!=""){
		$.messager.alert('提示',ServerObj.warning,'warning');
		return false;
	}
	return true;
 }
 function CheckAdmBlood(){
	 var BPSystolic=$("#BPSystolic").val().replace(/(^\s*)|(\s*$)/g,'');	
	 var BPDiastolic=$("#BPDiastolic").val().replace(/(^\s*)|(\s*$)/g,'');
	 if (ServerObj.NeedStolicMast==1){
		if ((BPSystolic=="")||(BPDiastolic=="")){
			$.messager.alert("提示","请录入完整的血压值","",function(){
				$("#BPSystolic").focus();
				//$("#BPDiastolic").focus();
			});
			
			return false;
		}
	 }
	 //var r = /^[0-9]*[1-9][0-9]*$/ 
	 var r = /^(([0-9]+\.[0-9]*[1-9][0-9]*)|([0-9]*[0-9][0-9]*))$/
	 if ((BPSystolic!="")&&(!r.test(BPSystolic))){
		 $.messager.alert("提示","收缩压只能录入数字!","",function(){
			 $("#BPSystolic").focus();
		 });
		 return false;
	 }
	 if ((BPDiastolic!="")&&(!r.test(BPDiastolic))){
		 $.messager.alert("提示","舒张压只能录入数字!","",function(){
			 $("#BPDiastolic").focus();
	     });
		 return false;
	 }
	 return true;
 }
 function CheckAddDiag(EpisodeID){
    var CheckAddret=cspRunServerMethod(ServerObj.CheckAdd,EpisodeID);
	if (CheckAddret!=""){
	   if(CheckAddret=='Discharged'){
		   $.messager.alert("提示","由于患者已出院,不能增加新诊断", "info");
	       return false;
	   }else if(CheckAddret=='Cancel'){
		   $.messager.alert("提示","由于患者已经退院，不能增加新诊断", "info");
	       return false;
  	   }else if(CheckAddret=="OPCancel"){
	  	   $.messager.alert("提示","由于患者已经退号，不能增加新诊断", "info");
	       return false;
	  }
	}
	return true;
 }
//判断所录入诊断是否有效
function CheckDiagIsEnabled(MRCICDRowidStr,callback){
	if(MRCICDRowidStr=="") return true;
	var MRCICDRowidStr=MRCICDRowidStr.replace(String.fromCharCode(2),"!")
	var reg=/(\*)|(\^)|(\:)|(\!)|(\-)|(\String.fromCharCode(2))/g;
	var MRCICDRowidStrArr=MRCICDRowidStr.replace(reg,"!").split("!")
	for (var i=0;i<MRCICDRowidStrArr.length;i++) {
		var MRCICDRowid=MRCICDRowidStrArr[i];
		if (MRCICDRowid=="") {
			continue
		}
		var ret=tkMakeServerCall("web.DHCMRDiagnos","CheckICDIsEnabled",MRCICDRowid,ServerObj.EpisodeID) 
		if(ret!=""){
			$.messager.alert("提示",ret,"info",function(){
				if(callback) callback(false);
			}); 
			return false;
		}
	}
	if(callback) callback(true);
	return true;
}
function GetSyndromeListInfo(index){
     var SyndromeCICDStr="";
	 var SyndromeCDescStr="";
     //var rowCount=$('#tabDiagnosEntry').jqGrid("getGridParam", "records");
     var rowids = $('#tabDiagnosEntry').getDataIDs();
	 index=parseInt(index)
     for (var k=index+1;k<rowids.length;k++){
	     var SynDiagnosCatRowId=GetCellData(rowids[k],"DiagnosCatRowId"); 
	     if (SynDiagnosCatRowId=="2") { //证型
			var SynMRDIARowId=GetCellData(rowids[k],"MRDIARowId");
	     	var SynMRCIDRowId=GetCellData(rowids[k],"MRCIDRowId");
	     	var SynMRCIDDesc=GetCellData(rowids[k],"DiagnosICDDesc");
	     	if (SynMRCIDDesc=="") SynMRCIDRowId="";
	     	var SynDiagnosNotes=GetCellData(rowids[k],"DiagnosNotes");
	     	if (SynDiagnosNotes!="") SynDiagnosNotes=SynDiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
	     	if ((SynMRCIDRowId=="")&&(SynDiagnosNotes=="")) continue;

	        var SynDiagnosTypeRowId=GetCellData(rowids[k],"DiagnosTypeRowId");
	        var SynMainDiagFlag=GetCellData(rowids[k],"MainDiagFlag");
	        if (SynMainDiagFlag=="是") SynMainDiagFlag="Y";
            else SynMainDiagFlag="N";
	        var SynDiagnosStatusRowId=GetCellData(rowids[k],"DiagnosStatusRowId");
	        var SynDiagnosOnsetDate=GetCellData(rowids[k],"DiagnosOnsetDate");
	     	var SynDiagnosDiagnosDate=GetCellData(rowids[k],"DiagnosDate");
	     	
	     	if ((SynDiagnosNotes!="")){ //(SynMRCIDRowId=="")&&
				SynDiagnosNotes=SynDiagnosNotes+"#3";
			}else{
				SynDiagnosNotes="";
			}
			var LongDiagnosFlagRowId=GetCellData(rowids[k],"LongDiagnosFlagRowId");
			var DiagnosPrefix=GetCellData(rowids[k],"DiagnosPrefix");
		    if (DiagnosPrefix!="") DiagnosPrefix=DiagnosPrefix.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
			if (SynMRCIDRowId=="") LongDiagnosFlagRowId="";
			//中医治法ID
			var TCMTreatment=GetCellData(rowids[k],"TCMTreatment");
			var TCMTreatmentID=(TCMTreatment=="")?"":GetCellData(rowids[k],"TCMTreatmentID");
			SynMRCIDRowId=SynMRCIDRowId+String.fromCharCode(2)+SynDiagnosTypeRowId+String.fromCharCode(2)+SynMainDiagFlag;
			SynMRCIDRowId=SynMRCIDRowId+String.fromCharCode(2)+SynDiagnosStatusRowId+String.fromCharCode(2)+SynDiagnosOnsetDate;
			SynMRCIDRowId=SynMRCIDRowId+String.fromCharCode(2)+SynDiagnosDiagnosDate+String.fromCharCode(2)+LongDiagnosFlagRowId;
			SynMRCIDRowId=SynMRCIDRowId+String.fromCharCode(2)+DiagnosPrefix+String.fromCharCode(2)+TCMTreatmentID;
			SynMRCIDRowId=SynMRCIDRowId+String.fromCharCode(2)+SynMRDIARowId;
			if ((SyndromeCICDStr=="")&&(SyndromeCDescStr=="")){
				SyndromeCICDStr=SynMRCIDRowId;
				SyndromeCDescStr=SynDiagnosNotes;
			}else{
				SyndromeCICDStr=SyndromeCICDStr+"$"+SynMRCIDRowId;
				SyndromeCDescStr=SyndromeCDescStr+"$"+SynDiagnosNotes;
			}
		 }else{
			 break;
	     }
	 }
	 return SyndromeCICDStr+String.fromCharCode(1)+SyndromeCDescStr;
}
//双击模板或历史记录添加到录入框
function AddDiagItemtoList(MRCICDRowId,MRCICDNotes,CMFlag,DiagnosPrefix,SDSInfo,TCMTreatmentID,TCMTreatment,LongDiagnosFlagRowId,DiagnosLeavel){
	if(ServerObj.warning!=""){
		$.messager.alert('提示',ServerObj.warning,'warning');
		return false;
	}
	if(!ServerObj.SDSDiagEntry&&SDSInfo&&SDSInfo.split("^")[1]){
		$.messager.alert("提示",'科室未开启结构化诊断录入,不能录入结构化诊断'); 
		return false;
	}
	if ((CMFlag=="Y")||(CMFlag=="H")){
		if ((ServerObj.ZYLocFlag!=1)&&(ServerObj.ChinaDiagLimit=="1")){
			$.messager.alert("提示",'科室非中医科室,不允许开立中医诊断'); 
			return false;
		}
	}
	var CruRow=Add_Diag_row();
	if(DiagnosLeavel){
		SetCellData(CruRow,"DiagnosLeavel",DiagnosLeavel);
	}
	var oldDiagnosCatRowId=GetCellData(CruRow,"DiagnosCatRowId");
	if(MRCICDRowId!=""){
		var ret = cspRunServerMethod(ServerObj.GetICDInfoByICDDrMethod,MRCICDRowId,ServerObj.EpisodeID);
		var RetArr=ret.split("^");
		var InvalidInfo=RetArr[4];
		if(InvalidInfo!=''){
			$.messager.alert("提示",InvalidInfo); 
			return false;
		}
		var DiagnosCatRowId=RetArr[2];
		var OldDiagnosCatRowId=GetCellData(CruRow,"DiagnosCatRowId");
		if(OldDiagnosCatRowId!=DiagnosCatRowId){
			if(OldDiagnosCatRowId==2){
				var tmpDiagnosLeavel=parseInt(GetCellData(CruRow,"DiagnosLeavel"));
				if(tmpDiagnosLeavel>1) SetCellData(CruRow,"DiagnosLeavel",tmpDiagnosLeavel-1);
			}
			SetCellData(CruRow,"DiagnosCat",RetArr[2]);
			SetCellData(CruRow,"DiagnosCatRowId",RetArr[2]);
		}
		SetCellData(CruRow,"DiagnosICDDesc",RetArr[1]);
		SetCellData(CruRow,"MRCIDRowId",MRCICDRowId);
		SetCellData(CruRow,"MRCIDCode",RetArr[0]);
	}else{
		if (CMFlag=="Y"){
			SetCellData(CruRow,"DiagnosCat",1);
	   		SetCellData(CruRow,"DiagnosCatRowId",1);
		}else if (CMFlag=="H"){
			SetCellData(CruRow,"DiagnosCat",2);
	   		SetCellData(CruRow,"DiagnosCatRowId",2);
		}else{
			SetCellData(CruRow,"DiagnosCat",0);
	   		SetCellData(CruRow,"DiagnosCatRowId",0);	
		}
	}
	var DiagnosCatRowId=GetCellData(CruRow,"DiagnosCatRowId");
	if(ServerObj.SDSDiagEntry&&(oldDiagnosCatRowId!=DiagnosCatRowId)){
		InitDiagnosICDDescLookUpSDS(CruRow);
	}
	if (MRCICDNotes!=""){
       SetCellData(CruRow,"DiagnosNotes",MRCICDNotes);
	}
	if (DiagnosPrefix!="") {
	   SetCellData(CruRow,"DiagnosPrefix",DiagnosPrefix);
	}
	if(TCMTreatmentID){
		SetCellData(CruRow,"TCMTreatmentID",TCMTreatmentID);
	}
	if(TCMTreatment){
		SetCellData(CruRow,"TCMTreatment",TCMTreatment);
	}
	var DiagnosCatRowId=GetICDType(CruRow);
	if (DiagnosCatRowId=="2"){
		var GroupRowids=GetGroupRowids(CruRow);
		var parRowid=GroupRowids[0];
		LongDiagnosFlagRowId=GetCellData(parRowid,"LongDiagnosFlagRowId");
	}
	if(LongDiagnosFlagRowId){
		SetCellData(CruRow,"LongDiagnosFlag",LongDiagnosFlagRowId);
		SetCellData(CruRow,"LongDiagnosFlagRowId",LongDiagnosFlagRowId);
	}
   	if(SDSInfo){
		SetCellData(CruRow,"SDSInfo",SDSInfo);
		var SDSInfoArr=SDSInfo.split("^");
		var SDSTermDR=SDSInfoArr[1];
		var SDSValue=SDSInfoArr[2];
		var SDSWordID=SDSInfoArr[3];
		var SDSSupplement=SDSInfoArr[4];
		var SDSDesc=$.cm({
			ClassName:'web.DHCBL.MKB.SDSDiagnosFuseInterface',
			MethodName:'GetDisplayName',
			SDSTermDR:SDSTermDR,SDSValue:SDSValue,SDSWordID:SDSWordID,SDSSupplement:SDSSupplement,
			dataType:'text'
		},false);
		SetCellData(CruRow,"SDSDesc",SDSDesc);
   	}
	ControlTCMTreatStyle(CruRow);
	Add_Diag_row('after',CruRow);
	if((DiagnosCatRowId==2)&&$("#"+CruRow+"_TCMTreatment").size()){
		SetFocusCell(CruRow, "TCMTreatment");
	}
	HorizontalMove([CruRow],0);
	return true;
}
//检查行是否空白行
function CheckIsClear(rowid){
	var MRCIDRowId=GetCellData(rowid,"MRCIDRowId");
	var DiagnosNotes=GetCellData(rowid,"DiagnosNotes");
	if (DiagnosNotes!="") DiagnosNotes=DiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
	if ((MRCIDRowId != "" )||(DiagnosNotes!="")){
		return false;
	}else{
		return true;
	}
}
//删除一行
function DeleteRow(rowid){
	$('#tabDiagnosEntry').delRowData(rowid);
}
function ReloadDiagEntryGrid(reloadFlag){
    $("#tabDiagnosEntry").jqGrid("clearGridData");
	$("#tabDiagnosEntry").jqGrid('setGridParam',{
			url:'DHCDoc.Util.QueryToJSON.cls?JSONTYPE=JQGRID&ClassName=web.DHCDocDiagnosEntryV8&QueryName=DiagnosList',
			postData:{MRADMID:ServerObj.mradm},
	}).trigger("reloadGrid", [{ current: true }]);
}
function CheckMainDiagCount(){
	var MainDiagCount=0;
	var MainDiagCount=CheckSaveDiagCount(MainDiagCount);
	if(MainDiagCount>1){
		alert($g("出院主诊断不能超过两个"));
		return false;
	}
	return true;
}
 function CheckSaveDiagCount(MainDiagCount){
   var rowids = $('#tabDiagnosEntry').getDataIDs();
   for(var i=0;i<rowids.length;i++){
	   var rowid = rowids[i];
	   var DiagnosTypeRowId=GetCellData(rowid,"DiagnosTypeRowId");
	   var MainDiagFlag=GetCellData(rowid,"MainDiagFlag");
	   //alert("DiagnosTypeRowId:"+DiagnosTypeRowId+"**"+"MainDiagFlag:"+MainDiagFlag);
	   //var DiagnosICDDesc=GetCellData(rowid,"DiagnosICDDesc")
	       if((DiagnosTypeRowId==4)&&(MainDiagFlag=="是")){
		       MainDiagCount=MainDiagCount+1; 
		   }
     }
   return MainDiagCount
}
//获取所有数据 如果行处于编辑状态 这样得到的行数据包含标签
function GetGirdData() {
   //保存数据
  //Save_Order_row();
  var DataArry = new Array();
  var rowids = $('#tabDiagnosEntry').getDataIDs();
  for (var i = 0; i < rowids.length; i++) {
       //不取已经审核诊断 和空白行
       //if(CheckIsItem(rowids[i])==true){continue;}
       var MRDIARowId=GetCellData(rowids[i],"MRDIARowId");
	   var MRCIDRowId=GetCellData(rowids[i],"MRCIDRowId");
       if (MRDIARowId != "" || MRCIDRowId == "") { continue; }
       var curRowData = $("#tabDiagnosEntry").getRowData(rowids[i]);
       DataArry[DataArry.length] = curRowData;
 }
     return DataArry;
}
function DiagDataToEMR(){
	///引用到病历
	var DiaDataList = new Array();
	var DiaObj = new Object();
	var DiagnosType=DiagnosICDDesc=DiagnosICDDesc=DiagnosNotes=MRCIDCode=DiagnosStatus=DiagnosDoctor=DiagnosDate=DiagnosTime=DiagnosDate=MRDIAMRDIADR=DiagnosCatFlag=DiagnosCat=SelRowFlag="";
	var rowids=$('#tabDiagnosEntry').getDataIDs();
	for(var i=0;i<rowids.length;i++){
		var ChildObjList = new Array();
		var ChildObj = new Object();
		var MRDIARowId=GetCellData(rowids[i],"MRDIARowId");
		if (MRDIARowId=="") continue;
		MRDIAMRDIADR=GetCellData(rowids[i],"MRDIAMRDIADR"); 
		//if (MRDIAMRDIADR!="") continue;
		DiagnosType=GetCellData(rowids[i],"DiagnosType");
		if (ServerObj.DiagnosTypeStr.indexOf(":"+DiagnosType)<0) continue;
		DiagnosICDDesc=GetCellData(rowids[i],"DiagnosICDDesc");
		DiagnosICDDesc=DiagnosICDDesc.replace(/\&nbsp;/g,"")
		DiagnosNotes=GetCellData(rowids[i],"DiagnosNotes");
		MRCIDCode=GetCellData(rowids[i],"MRCIDCode");
		DiagnosStatus=GetCellData(rowids[i],"DiagnosStatus");
		DiagnosDoctor=GetCellData(rowids[i],"DiagnosDoctor");
		DiagnosDate=GetCellData(rowids[i],"DiagnosDate");
		DiagnosTime=DiagnosDate.split(" ")[1];
		DiagnosDate=DiagnosDate.split(" ")[0];
		DiagnosCat=GetCellData(rowids[i],"DiagnosCat");
		if (DiagnosCat==$g("西医")) {DiagnosCatFlag=0 }else{DiagnosCatFlag=1}
		DiagnosLeavel=GetCellData(rowids[i],"DiagnosLeavel");
		SelRowFlag=0;
		if ($("#jqg_tabDiagnosEntry_" + rowids[i]).prop("checked") == true) {
			SelRowFlag=1;
		}
		var DiagnosPrefix=GetCellData(rowids[i],"DiagnosPrefix");
		DiaObj={TypeDesc:DiagnosType,ICDDesc:DiagnosICDDesc,MemoDesc:DiagnosNotes,ICDCode:MRCIDCode,EvaluationDesc:DiagnosStatus,UserName:DiagnosDoctor,Date:DiagnosDate,Time:DiagnosTime,BillFlagDesc:DiagnosCat,BillFlag:DiagnosCatFlag,Level:DiagnosLeavel,SelRowFlag:SelRowFlag,DiagnosPrefix:DiagnosPrefix};
		DiaDataList.push(DiaObj);
	}
	var DiaDataList=diagnosesBtQuote(DiaDataList)
	window.returnValue=$.extend(window.returnValue,{"DiaDataList":DiaDataList});
}

///lxz 保存诊断到电子病历
function SaveMRDiagnosToEMR(){
	var argObj={
		PAAdmType:ServerObj.PAAdmType,
		EpisodeID:ServerObj.EpisodeID
	}
	Common_ControlObj.AfterUpdate("SaveMRDiagnosToEMR",argObj);
}

//lxz  到达
function UpdateArriveStatus() {
    var LogonUserID = session['LOGON.USERID']
    if (cspRunServerMethod(ServerObj.SetArrivedStatus, ServerObj.EpisodeID, ServerObj.DocID, session['LOGON.CTLOCID'], session['LOGON.USERID']) != '1') {}
}

function InitPatDiagViewGlobal(EpisPatObj){
	try {
		if ((";"+ServerObj.DiagnosTypeStr).indexOf((";"+EpisPatObj.DedfaultDiagnosTypeID+":"))==-1){
		 	EpisPatObj.DedfaultDiagnosTypeID=ServerObj.DiagnosTypeStr.split(":")[0];
		 	EpisPatObj.DedfaultDiagnosTypeCode=ServerObj.DiagnosTypeStr.split(";")[0].split(":")[1];
		}
		$.extend(ServerObj,EpisPatObj);
		//初始化
    	var argObj={
			EpisodeID:ServerObj.EpisodeID,
		    PAAdmType:ServerObj.PAAdmType
		};
    	Common_ControlObj.xhrRefresh(argObj);
		InitButtonBar();	//按钮栏配置布局初始化
		InitSpecLocForm();
	}catch(e) {
		//此方法局部刷新和页面初始化时会调用,如果报错可能导致错误难排查,需加错误提示性信息
		$.messager.alert("提示信息",$g("调用InitPatDiagViewGlobal函数异常,错误信息：")+e.message); 
		return false;
	}
}
function xhrRefresh(refreshArgs){
	$(".messager-body").window('destroy'); //自动关闭上一个患者的alert弹框
	$('.hisui-dialog:visible').dialog('destroy');
	var CopyDiagnosStr=[];
	if (refreshArgs.copyOeoris){
		CopyDiagnosStr=$.cm({ClassName:"web.DHCDocDiagnosEntryV8",MethodName:'CreateCopyItem',MRDiagnosRowids:refreshArgs.copyOeoris},false);
	}
	$.extend(ServerObj, {CopyDiagnosStr:CopyDiagnosStr});
	//CDSS回写诊断局部刷新时处理
	ServerObj.copyCDSSData=refreshArgs.copyCDSSData;
	if((refreshArgs.adm==ServerObj.EpisodeID)&&((ServerObj.CopyDiagnosStr!="")||(ServerObj.copyCDSSData&&ServerObj.copyCDSSData.length))){
		AddCopyDiagToList(ServerObj.CopyDiagnosStr);
		if(typeof CDSSObj=='object') CDSSObj.AddDiagToList(ServerObj.copyCDSSData);
		return;
	}
	var EpisPatInfo = $.cm({
		ClassName:"web.DHCDocViewDataInit",
		MethodName:"InitPatDiagViewGlobal",
		EpisodeID:refreshArgs.adm,OutDisFlag:"",SearchDiagnosTypeStr:"",Opener:""
	},false);
	InitPatDiagViewGlobal(EpisPatInfo);
	ReloadDiagEntryGrid();
    LoadHistoryDiag();
	SetDiagOtherInfo();
	$("#EpisodeID").val(refreshArgs.adm);
	$("#PatientID").val(refreshArgs.papmi);
	//修改url
	if (typeof(history.pushState) === 'function') {
		var Url=window.location.href;
        Url=rewriteUrl(Url, {
	        EpisodeID:refreshArgs.adm,
        	PatientID:refreshArgs.papmi,
        	mradm:refreshArgs.mradm,
        	EpisodeIDs:"",
        	CopyDiagnosStr:"",
        	copyTo:""});
        history.pushState("", "", Url);
    }
    ShowSecondeWin("onOpenDHCEMRbrowse");
	//return websys_cancel();
}
function overrrideUrl(arg,argVal) {
    var url = window.location.href;
    var  newUrl=  changeURLArg(url, arg, argVal); 
    history.replaceState({}, "", newUrl); //pushState
} 
function changeURLArg(url, arg, arg_val) {
    var pattern = arg + '=([^&]*)';
    var replaceText = arg + '=' + arg_val;
    if (url.match(pattern)) {
        var tmp = '/(' + arg + '=)([^&]*)/gi';
        tmp = url.replace(eval(tmp), replaceText);
        return tmp;
    } 
    return url;
}
function CheckIsDischarge(){
    if (ServerObj.PAAdmType=="I"){
		var ret = $.cm({
			ClassName:"web.DHCMRDiagnos",
			MethodName:"CheckDelete",
			dataType:"text",
			MRDiagnosRowid:ServerObj.mradm
		},false);
		if (ret=="Discharged"){
			$.messager.alert("警告", "患者已出院,不能增加诊断");
        	return false;
		}
	}
	if (!CheckAddDiag(ServerObj.EpisodeID)) return false;
	return true;	    
}
 function InitDiagnosICDDescLookUpHUI(rowid){
	 $("#"+rowid+"_DiagnosICDDesc").lookup({
	        url:$URL,
	        mode:'remote',
	        method:"Get",
	        idField:'Rowid',
	        textField:'ICDDesc',
	        /*columns:[[  
	           {field:'desc',title:'诊断名称',width:350,sortable:true},
	           {field:'code',title:'编码',width:120,sortable:true},
	           {field:'DiagInsuCode',title:'国家医保诊断编码',width:120,sortable:true},
	           {field:'DiagInsuName',title:'国家医保诊断名称',width:120,sortable:true}
	        ]],*/
	        className:"DHCDoc.Diagnos.Common",
			queryName:"QueryICD",
	        pagination:true,
	        panelWidth:500,
	        panelHeight:300,
	        isCombo:true,
	        minQueryLen:2,
	        delay:'500',
	        queryOnSameQueryString:true, //web.DHCMRDiagnos
	        queryParams:{ClassName: 'DHCDoc.Diagnos.Common',QueryName: 'QueryICD'},
	        onBeforeLoad:function(param){
		        var desc=$.trim(param['q']);
				var ICDType=GetICDType(rowid);
				$.extend(param,{desc:desc,EpisodeID:ServerObj.EpisodeID,ICDType:ICDType});
		        if (desc=="") return false;
		    },
			onSelect:function(ind,item){
			    var ItemArr=new Array();
			    $.each(item, function(key, val) {
					ItemArr.push(val);
				});
				DiagItemLookupSelect(ItemArr.join("^"),rowid);
			}
    });
 }
 function LongDiagnosFlagChange(e){
	var rowId="";
	var obj=websys_getSrcElement(e);
	var rowId=GetEventRow(e);
	var DiagnosICDDesc=GetCellData(rowId,"DiagnosICDDesc");
	var MRCIDRowId=GetCellData(rowId,"MRCIDRowId");
	if (rowId!=""){
		if ((MRCIDRowId=="")||(DiagnosICDDesc=="")){
			$.messager.alert("提示","非ICD诊断不能选择长效标识!","info",function(){
				ClearLongDiagnosFlag(rowId);
			});
			return false;
		}
		var DiagnosCat=GetCellData(rowId,"DiagnosCat");
		var DiagnosCatRowId=GetCellData(rowId,"DiagnosCatRowId");
		if ((DiagnosCatRowId=="1")||(DiagnosCat=="中医")){ //"0:西医;1:中医;2:证型"
			ChangeLinkSynLongDiagnosFlag(rowId,obj.value);
		}else if((DiagnosCatRowId=="2")||(DiagnosCat=="证型")){
			var MainRowId="";
			for (var k=parseInt(rowId)-1;k>=1;k--){
				var tmpDiagnosCatRowId=GetCellData(k,"DiagnosCatRowId"); 
				if ((DiagnosCatRowId!="0")||(DiagnosCat!="西医")){
					var DiagnosICDDesc=GetCellData(k,"DiagnosICDDesc");
					var MRCIDRowId=GetCellData(k,"MRCIDRowId");
					var DiagnosCat=GetCellData(k,"DiagnosCat");
					if ((MRCIDRowId!="")&&(DiagnosICDDesc!="")&&((tmpDiagnosCatRowId=="1")||(DiagnosCat=="中医"))){
						MainRowId=k;
						break;
					}
					if (((tmpDiagnosCatRowId=="1")||(DiagnosCat=="中医"))){
						break;
						}
				}
		    }
		    if (MainRowId==""){
			    $.messager.alert("提示","该证型对应的中医对应是非ICD诊断,不能设置长效诊断标识!","info",function(){
					ClearLongDiagnosFlag(rowId);
				});
				return false;
			}
			ChangeLinkSynLongDiagnosFlag(MainRowId,obj.value);
		}
	}
	SetCellData(rowId,"LongDiagnosFlagRowId",obj.value);
	SetFocusCell(rowId,"DiagnosICDDesc");
 }
 function ChangeLinkSynLongDiagnosFlag(rowId,LongDiagnosFlagRowId){
	var AllIds = $('#tabDiagnosEntry').getDataIDs();
	for (var k = 0; k < AllIds.length; k++) {
		 if (parseInt(AllIds[k]) < parseInt(rowId)) continue;
	     var DiagnosCatRowId=GetCellData(AllIds[k],"DiagnosCatRowId");
	     var DiagnosCat=GetCellData(AllIds[k],"DiagnosCat");
	     if ((parseInt(AllIds[k]) == parseInt(rowId))||(DiagnosCatRowId=="2")||(DiagnosCat=="证型")) { //
	     	var DiagnosICDDesc=GetCellData(AllIds[k],"DiagnosICDDesc");
			var MRCIDRowId=GetCellData(AllIds[k],"MRCIDRowId");
			if ((MRCIDRowId!="")&&(DiagnosICDDesc!="")){
				if (DiagnosCatRowId==""){
					EditRow(AllIds[k]);
				}
				SetCellData(AllIds[k],"LongDiagnosFlagRowId",LongDiagnosFlagRowId);
				SetCellData(AllIds[k],"LongDiagnosFlag",LongDiagnosFlagRowId);
			}
	     }else{
		     break;
		 }
	 }
 }
 function ClearLongDiagnosFlag(rowId){
	 SetCellData(rowId,"LongDiagnosFlagRowId","");
	 SetCellData(rowId,"LongDiagnosFlag","");
 }
 function LongDiagnosOpen(){
	  websys_showModal({
		iconCls:'icon-w-trigger-box',
		url:"dhcdoc.palongicdlist.csp?PatientID=" + ServerObj.PatientID,
		title:$g('长效诊断列表'),
		width:800,height:500,
		AddItemToList:AddItemToList,
		AddCopyItemToList:AddCopyItemToList
	  });
 }
function AddItemToList(str){
	 for (var i=0;i<str.split(",").length;i++){
		 var id=str.split(",")[i];
		 if (!CheckDiagIsEnabled(id)) return false;
		 AddDiagItemtoList(id,"");
	 }
}
function AddCopyItemToList(str,Type){
	 for (var i=0;i<str.split(String.fromCharCode(2)).length;i++){
		 var onestr=str.split(String.fromCharCode(2))[i];
		 var ids=onestr.split(String.fromCharCode(1))[0];
		 var descstr=onestr.split(String.fromCharCode(1))[1];
		 var DiagnosPrefixStr=onestr.split(String.fromCharCode(1))[2];
		 var DiagnosCatRowId=onestr.split(String.fromCharCode(1))[3];
		 var SDSInfo=onestr.split(String.fromCharCode(1))[4];
		 for (var j=0;j<ids.split("!").length;j++){
			 var id=ids.split("!")[j];
			 var desc=descstr.split(String.fromCharCode(4))[j];
			 var DiagnosPrefix=DiagnosPrefixStr.split(String.fromCharCode(3))[j];
			 var CMFlag="N";
			 if ((j==0)&&(ids.split("!").length>=2)) {
				 CMFlag="Y";
			 }
			 if (DiagnosCatRowId=="1"){
				 CMFlag="Y";
			 }
			 if ((id==desc)||(id.indexOf("Desc:")>=0)) {
				 var AuitMsg=GetEntryNoICDDiagAuit(GetCurRowid());
				 if (AuitMsg!=""){
					 $.messager.alert("提示",desc+AuitMsg);
					 if (j==0) {
					 	return;
					 }else{
						 continue;
					 }
				 }
				 AddDiagItemtoList("",desc,CMFlag,DiagnosPrefix,SDSInfo);
				 if (j>=1) {
				 	var CruRow=GetPreRowId();
					SetCellData(CruRow,"DiagnosCat",2);
					SetCellData(CruRow,"DiagnosCatRowId",2);
				}
			 }else{
				 if (!CheckDiagIsEnabled(id)) continue;
				 //if (Type=="CopyFromAllDiag") desc=""; 
				 AddDiagItemtoList(id,desc,CMFlag,DiagnosPrefix,SDSInfo);
			 }
		 }
		 
	 }
 }
function DiagnosDelList(){
	 websys_showModal({
		iconCls:'icon-w-list',
		url:"dhcdoc.deldiaglist.csp?mradm=" + ServerObj.mradm,
		title:$g('诊断删除日志'),
		width:900,height:500
	  });
 }
 function DisableBtn(id,disabled){
	if ($("#"+id).hasClass("menu-item")==false){
		if (disabled){
			$HUI.linkbutton("#"+id).disable();
		}else{
			$HUI.linkbutton("#"+id).enable();
		}
	}
}
function InsertMutiMRDiagnos(MRCICDRowid,MRCDiagNote){
	var UpdateObj={
		EpisodeID:ServerObj.EpisodeID,
		PAAdmType:ServerObj.PAAdmType,
	}
	new Promise(function(resolve,rejected){
		//电子签名
		var CAInputObj={
			callType:"DiagSave",
			isHeaderMenuOpen:false
		}
		Common_ControlObj.BeforeUpdate("CASignCheck",CAInputObj,resolve);
	}).then(function(RtnObj){
		return new Promise(function(resolve,rejected){
	    	if (RtnObj == false || RtnObj.PassFlag == false) {
	    		return false;
	    	}
		    $.extend(UpdateObj, RtnObj.CAObj);
		    //
		    if (!CheckIsDischarge()) return false;
			resolve();
		})
	}).then(function(){
        return new Promise(function(resolve,rejected){
            CheckFirOrReAdm(resolve);
        })
    }).then(function(){
		return new Promise(function(resolve,rejected){
			CheckBeforeInsertMRDiag(resolve)
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			GetDiagDataOnAdd(resolve);
		})
	}).then(function(DiagItemStr){
		return new Promise(function(resolve,rejected){
			$.extend(UpdateObj, { DiagItemStr: DiagItemStr});
			//CDSS事前预警
			if (UpdateObj.DiagItemStr!="") {
				Common_ControlObj.BeforeUpdate("CDSSCheck",UpdateObj,resolve);
			}else{
				resolve(true);
			}
		})
	}).then(function(ret){
		return new Promise(function(resolve,rejected){
			if (!ret) return false;
			//统一第三方接口调用,参照医生站配置->外部接口测试->对外接口接入管理下的关联开启数据
			var myInputObj={
				CallBackFunc:resolve
			}
			$.extend(myInputObj, UpdateObj);
			Common_ControlObj.BeforeUpdate("Interface",myInputObj,resolve);
		})
	}).then(function(ret){
		return new Promise(function(resolve,rejected){
			if (ret==false || ret.SuccessFlag==false) {
				return false;
			}
			//调用医政组接口判断诊断报告
			if (UpdateObj.DiagItemStr!="") {
				Common_ControlObj.BeforeUpdate("CheckReportBeforeInsert",UpdateObj,resolve);
			}else{
				resolve(UpdateObj.DiagItemStr);
			}
		})
	}).then(function(DiagItemStr){
		if (DiagItemStr === false) {
			$.messager.alert("警告", "先保存对应的报告，否则不允许保存诊断！", 'info');
			return false;
		}
		var AdmPara=GetAdmPara();
		var LogDepRowid = session['LOGON.CTLOCID'];
		var LogUserRowid = session['LOGON.USERID'];
		var ret = cspRunServerMethod(ServerObj.InsertMRDiagnosMethod, ServerObj.mradm,DiagItemStr,AdmPara,LogDepRowid, LogUserRowid);
		var SeccessFlag=ret.split('^')[0];
		if (SeccessFlag=='0') {
			UpdateArriveStatus();
			//
			$.extend(UpdateObj, {
				DiagItemIDs: ret,
				CACallType: "Diag"
			});
			AfterInsertOrDeleteDiag("Insert",UpdateObj);
		}else{
			var ErrorMsg=ret.split('^')[1];
			$.messager.alert("error","插入诊断失败,"+ErrorMsg,"error");
			return false;
		}
	})
 }
function GetDiagDataOnAdd(callBackFun){
	 var DiagItemStr="";
	 var rowids = $('#tabDiagnosEntry').getDataIDs();
	 for(var i=0;i<rowids.length;i++){
		//不是编辑状态的行不获取 wqy 2021-07-12
		if(!IsEditingRow(rowids[i])) continue;
		var MRDIARowId=GetCellData(rowids[i],"MRDIARowId");
		var MRCIDRowId=GetCellData(rowids[i],"MRCIDRowId");
		var DiagnosTypeRowId=GetCellData(rowids[i],"DiagnosTypeRowId");
		var DiagnosOnsetDate=GetCellData(rowids[i],"DiagnosOnsetDate");
		var DiagnosNotes=GetCellData(rowids[i],"DiagnosNotes");
		if(DiagnosNotes!="") DiagnosNotes=DiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
		var DiagnosICDDesc=GetCellData(rowids[i],"DiagnosICDDesc");
		if(DiagnosICDDesc=="") MRCIDRowId="";
		var MainDiagFlag=GetCellData(rowids[i],"MainDiagFlag");
		if(MainDiagFlag==$g("是")) MainDiagFlag="Y";
		else MainDiagFlag="N";
		var DiagnosStatusRowId=GetCellData(rowids[i],"DiagnosStatusRowId");
		var DiagnosCatRowId=GetCellData(rowids[i],"DiagnosCatRowId"); //分类
		var DiagnosDate=GetCellData(rowids[i],"DiagnosDate");
		var LongDiagnosFlagRowId=GetCellData(rowids[i],"LongDiagnosFlagRowId");
		if (MRCIDRowId=="") LongDiagnosFlagRowId="";
		var DiagnosPrefix=GetCellData(rowids[i],"DiagnosPrefix");
		if (DiagnosPrefix!="") DiagnosPrefix=DiagnosPrefix.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
		var DiagnosLeavel=GetCellData(rowids[i],'DiagnosLeavel');
		
		if(((MRCIDRowId!="")||(DiagnosNotes!=""))&&(DiagnosCatRowId!="2")){
			var SyndromeInfo="";
			 if ((DiagnosCatRowId=="1")){ 	//&&(MRDIARowId=="")
				SyndromeInfo=GetSyndromeListInfo(i);
			}
			if ((DiagnosNotes!="")&&(MRDIARowId=="")) DiagnosNotes=DiagnosNotes+"#"+(parseInt(DiagnosCatRowId)+1);
			var SyndromeCICDStr="",SyndromeCDescStr=""
			if (SyndromeInfo!=""){
				SyndromeCICDStr=SyndromeInfo.split(String.fromCharCode(1))[0];
				SyndromeCDescStr=SyndromeInfo.split(String.fromCharCode(1))[1];
			}
			var DiagnosBodyPartId=GetCellData(i,"DiagnosBodyPartRowId");
			// 结构化诊断RowId^结构化诊断中心词DR^结构化诊断表达式ID串^是否本次就诊诊断
			var SDSInfo=GetCellData(rowids[i],"SDSInfo");
			var SDSTermDR=SDSInfo.split("^")[1]||'';
			var SDSDisplayIDStr=SDSInfo.split("^")[2]||'';
			var SDSWordID=SDSInfo.split("^")[3]||'';
			var SDSNote=SDSInfo.split("^")[4]||'';
			if(MRDIARowId!=""){ //已保存过的诊断修改
				var OneDiagItemStr=MRDIARowId+"^"+DiagnosNotes+"^"+DiagnosTypeRowId+"^"+MainDiagFlag+"^"+DiagnosStatusRowId+"^"+DiagnosOnsetDate+"^"+DiagnosBodyPartId+"^"+DiagnosDate+"^"+LongDiagnosFlagRowId+"^"+DiagnosPrefix+"^"+MRCIDRowId+"^"+SDSTermDR+"^"+SDSDisplayIDStr+"^"+SDSWordID+'^'+SDSNote+"^"+SyndromeCICDStr+"^"+SyndromeCDescStr+"^"+DiagnosLeavel;
			}else{
				var OneDiagItemStr=""+"^"+DiagnosNotes+"^"+MRCIDRowId+"^"+DiagnosTypeRowId+"^"+MainDiagFlag
				OneDiagItemStr=OneDiagItemStr+"^"+DiagnosStatusRowId+"^"+DiagnosOnsetDate+"^"+SyndromeCICDStr+"^"+SyndromeCDescStr+"^"+DiagnosBodyPartId;
				OneDiagItemStr=OneDiagItemStr+"^"+DiagnosDate+"^"+LongDiagnosFlagRowId+"^"+DiagnosPrefix+"^"+SDSTermDR+"^"+SDSDisplayIDStr+"^"+SDSWordID+'^'+SDSNote+"^"+""+"^"+DiagnosLeavel;
			}
			if (DiagItemStr==""){DiagItemStr=OneDiagItemStr}else{DiagItemStr=DiagItemStr+String.fromCharCode(1)+OneDiagItemStr}
		}
	}
	callBackFun(DiagItemStr);
}
function myformatter(date){
	var y = date.getFullYear();
	var m = date.getMonth()+1;
	var d = date.getDate();
	if (ServerObj.SYSDateFormat=="3") return y+'-'+(m<10?('0'+m):m)+'-'+(d<10?('0'+d):d);
	else if (ServerObj.SYSDateFormat=="4") return (d<10?('0'+d):d)+"/"+(m<10?('0'+m):m)+"/"+y
	else return y+'-'+(m<10?('0'+m):m)+'-'+(d<10?('0'+d):d);
}
function CompareDate(date1,date2){
	var date1 = myparser(date1);
	var date2 = myparser(date2); 
	if(date2<date1){  
		return true;  
	} 
	return false;
}
function myparser(s){
    if (!s) return new Date();
    if(ServerObj.SYSDateFormat=="4"){
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
function chartOnBlur() {
	var UnSaveDiag=0;
	var rowids = $('#tabDiagnosEntry').getDataIDs();
	for (var i=0;i<rowids.length;i++){
		var MRDIARowId=GetCellData(rowids[i],"MRDIARowId");
		if (MRDIARowId !="") continue;
	    var MRCIDRowId=GetCellData(rowids[i],"MRCIDRowId");
	    var DiagnosNotes=GetCellData(rowids[i],"DiagnosNotes");
	    if (DiagnosNotes!="") DiagnosNotes=DiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"");
	    if ((MRCIDRowId =="")&&(DiagnosNotes =="")) continue;
	    UnSaveDiag=1;
	    break;
	}
	if (UnSaveDiag == "1"){
		if (!dhcsys_confirm($g("存在未保存的诊断,是否继续？"))) {
			return false;
		}
	}
	return true;
}
function GetEntryNoICDDiagAuit(rowid)
{
	var ICDType=parseInt(GetICDType(rowid));
	if (ICDType>0){
		if ((ServerObj.ZYLocFlag!=1)&&(ServerObj.ChinaDiagLimit=="1")){
			return $g('科室非中医科室,不允许开立中医诊断');
		}
	}
	var DiagnosStatusRowId=GetCellData(rowid,"DiagnosStatusRowId");
	var alertMsg=$.m({
	    ClassName:"web.DHCDocDiagnosEntryV8",
	    MethodName:"CheckEntryNoICDDiagAuit",
	    DiagnosStatusRowId:DiagnosStatusRowId,
	    EpisodeID:ServerObj.EpisodeID
	},false);
	return alertMsg;
}
function GetCurRowid()
{
	var CruRow=GetPreRowId();
	if(CheckIsClear(CruRow)==true){
		DeleteRow(CruRow);
	}
	return Add_Diag_row();
}
function DiagCertificateClickhandler(){
	websys_showModal({
		iconCls:'icon-w-paper',
		url:"dhcdoc.diagnoscertificate.csp?EpisodeID="+ServerObj.EpisodeID,
		title:$g('诊断证明书'),
		width:'1000px',height:'500px'
	})
}
function DiagnosOpertions(cellvalue, options, rowdata){
	return "";
}
function LoadHistoryDiag()
{
	$('#pHistory').empty();
	$.cm({
		ClassName:'DHCDoc.Diagnos.Common',
		MethodName:'GetHistoryDiag',
		PatientID:ServerObj.PatientID,
		LocID:session['LOGON.CTLOCID'],
		LocRange:$('input[name="HistoryRange"]:checked').attr('id'),
		HospID:session['LOGON.HOSPID']
	},function(Data){
		$.each(Data,function(index,dateObj){
			var Date=dateObj.Date;
			$.each(dateObj.LocList,function(index,LocObj){
				var Loc=LocObj.Loc;
				var $container=$('<div></div>').addClass('history-container').appendTo('#pHistory');
				$('<div></div>').addClass('history-title').append('<input type="checkbox"/>').append('<div>'+Date+' '+Loc+'</div>').appendTo($container);
				var $table=$('<table></table>').addClass('history-diagnos').appendTo($container);
				$.each(LocObj.Diagnos,function(index,DiagObj){
					var $tr=$('<tr></tr>').data('DiagObj',DiagObj).appendTo($table);
					$tr.append('<td name="Check"><input type="checkbox"/></td>');
					$tr.append('<td name="DiagRowid">'+DiagObj.DiagRowid+'</td>');
					$tr.append('<td name="ICDRowid">'+DiagObj.ICDRowid+'</td>');
					$tr.append('<td name="DiagType">'+'['+DiagObj.DiagType+']'+'</td>');
					$tr.append('<td name="DiagDesc">'+DiagObj.text+'</td>');
					$tr.append('<td name="ICDCode">'+DiagObj.ICDCode+'</td>');
					$tr.append('<td name="DiagStat">'+DiagObj.DiagStat+'</td>');
					$tr.append('<td name="AddDoc">'+DiagObj.AddDoc+'</td>');
					if(GetTextWidth(DiagObj.text)>$tr.find('td[name=DiagDesc]').innerWidth()){
						$tr.find('td[name=DiagDesc]').tooltip({
							content:DiagObj.text,
							trackMouse:true
						});
					}
					$tr.append('<td name="EditLog"></td>');
					$('<a></a>').linkbutton({
						plain:true,
						iconCls:'icon-clock-record',
						onClick:function(){
							DiagnosEditLog(DiagObj);
						}
					}).tooltip({content:'查看操作记录'}).appendTo($tr.find('td[name=EditLog]'));
					$('<td name="DiagRowids"></td>').html('<a href="#">'+$g('重复')+DiagObj.DiagRowids.length+$g('条')+'</a>').appendTo($tr).click(function(){
						websys_showModal({
							iconCls:'icon-w-list',
							url:"dhcdocpatrepeatdiag.csp?PatientID="+ServerObj.PatientID+"&DiagRowids="+DiagObj.DiagRowids.join('^'),
							title:"【"+DiagObj.text+$g("】诊断重复列表"),
							width:'80%',height:'80%'
						 });
					});
					$tr.dblclick(function(){
						var CMFlag='';
						if(DiagObj.DiagType==$g('中医')) CMFlag='Y';
						else if(DiagObj.DiagType==$g('证型')) CMFlag='H';
						AddDiagItemtoList(DiagObj.ICDRowid,DiagObj.Note,CMFlag,DiagObj.PrefixDesc,DiagObj.SDSInfo,DiagObj.TCMTreatmentID,DiagObj.TCMTreatment,DiagObj.LongDiagnosFlagRowId);
						if (ServerObj.DiagFromTempOrHisAutoSave==1){
							InsertMutiMRDiagnos();
						}
					})
					$tr.children('td:not(td[name=Check])').click(function(){
						var checked=$(this).parent().find('td[name=Check]').children().prop('checked');
						$(this).parent().find('td[name=Check]').children().prop('checked',!checked);
						$(this).parent().find('td[name=Check]').children().change();
					});
				});
				$container.on('change','input:checkbox',function(){
					if('DIV'==$(this).parent().prop('tagName')){
						$container.find('td[name=Check]').children().prop('checked',$(this).prop('checked'));
					}else{
						if($container.find('td[name=Check]').children(':not(:checked)').size()){
							$container.find('.history-title').children('input:checkbox').prop('checked',false);
						}else{
							$container.find('.history-title').children('input:checkbox').prop('checked',true);
						}
					}
				});
			});
		});
	});
}
function DiagnosEditLog(DiagObj)
{
	var DiagRowids=typeof DiagObj.DiagRowids=='object'?JSON.stringify(DiagObj.DiagRowids):DiagObj.DiagRowids;
	websys_showModal({
		iconCls:'icon-w-find',
		url:"diagnosentry.log.csp?DiagRowids="+encodeURIComponent(DiagRowids),
		title:DiagObj.text+$g(' 操作记录'),
		width:320,
		height:550	
	});
}
function InitFavLayout()
{
	PageLogicObj.TempHeight=ServerObj.TempHeightScale?($('#layoutMain').height()*ServerObj.TempHeightScale/100):350;
	PageLogicObj.TempWidth=ServerObj.TempWidthScale?($('#layoutMain').width()*ServerObj.TempWidthScale/100):350;
	var url='diagnos.template.entry.csp?CONTEXT='+ServerObj.XCONTEXT+"&TemplateRegion="+ServerObj.DiagTemplateRegion;
	if(typeof websys_writeMWToken=='function') url=websys_writeMWToken(url);
	var favFrame='<iframe id="diagTempFrame" name="diagTempFrame" width="100%" height="100%" src="'+url+'" frameborder="no" framespacing="0" marginwidth="0" marginheight="0" scrolling="auto"></iframe>'
	if(ServerObj.DiagTemplateRegion=='window'){
		var $win=$('<div id="TemplateWin"></div>').appendTo('body').window({
			title:$g('诊断模板'),
			iconCls:'icon-w-list',
			minimizable:false,
			maximizable:false,
			closable:false,
			closed:false,
			modal:false,
			width:PageLogicObj.TempWidth,
			height:$(window).height()-80,
			content:favFrame,
			onCollapse:function(){
				$(this).window('resize',{
					width: 135
				}).window('move',{
					top:$(window).height()-60,
					left:$(window).width()-150
				});
				$(this).parent().addClass("boxshadow");
			},
			onExpand:function(){
				$(this).window('resize',{
					height: $(window).height()-80,
					width: PageLogicObj.TempWidth
				}).window('move',{
					top:40,
					left:$(window).width()-PageLogicObj.TempWidth-15
				});
				$(this).parent().removeClass("boxshadow");
				if($('#diagTempFrame')[0].contentWindow&&$('#diagTempFrame')[0].contentWindow.ReloadFavDataList){
					setTimeout(function(){
						$('#diagTempFrame')[0].contentWindow.ReloadFavDataList();
					},300);
				}
			},
			onResize:function(width,height){
				if(!$(this).window('options').collapsed){
					ResetOrdListScale(height,width);
				}
			}
		});
		if(ServerObj.DefCollapseTemp=='Y') $win.window('collapse');
		else $win.window('options').onExpand.call($('#TemplateWin')[0]);
	}else{
		var layoutId=(['north','south'].indexOf(ServerObj.DiagTemplateRegion)>-1)?'layoutBaseInfo':'layoutMain';
		$('#'+layoutId).layout('add',{
            region:ServerObj.DiagTemplateRegion,
            border:false,
            collapsible:false,
            split:true,
            width:PageLogicObj.TempWidth,
			height:PageLogicObj.TempHeight,
            content:favFrame,
            onResize:function(){
	        	ResetOrdListScale($(this).parent().outerHeight(),$(this).outerWidth());
	        }
        });
	}
}
function ResetOrdListScale(height,width)
{
	if(!window.event) return false;
	if(window.event.type.indexOf('mouse')==-1) return false;
	if(!width&&(['north','south'].indexOf(ServerObj.DiagTemplateRegion)==-1)) return false;
	if(!PageLogicObj.resizeTimer) PageLogicObj.resizeTimer={};
	clearTimeout(PageLogicObj.resizeTimer[ServerObj.DiagTemplateRegion]);
	PageLogicObj.resizeTimer[ServerObj.DiagTemplateRegion]=setTimeout(function(){
		if(['north','south'].indexOf(ServerObj.DiagTemplateRegion)>-1){
			var ConfigNode='TempHeightScale';
			var scale=Math.round(height/$('#layoutMain').height()*100);
		}else{
			var ConfigNode='TempWidthScale';
			var scale=Math.round(width/$('#layoutMain').width()*100);
		}
		$.cm({
			ClassName:"web.DHCDocConfig",
			MethodName:"SetUserPageScale",
			PageCode:"DiagnosEntry",Property:ConfigNode,Value:scale,
			dataType:'text'
		},function(){
			$.messager.popover({msg:'布局调整成功!',type:'success'});
			if(height) PageLogicObj.TempHeight=height;
			if(width) PageLogicObj.TempWidth=width;
		});
	},1000);
	return true;
}
function AddToTemplateclickhandler()
{
	var ids=$('#tabDiagnosEntry').jqGrid("getGridParam", "selarrrow"); 			
	if(ids==null || ids.length==0) {  
		$.messager.alert("提示","请选择需要添加到模板的诊断");  
		return;  
	}
	ids=ids.sort();
	var DiagArr=new Array();
	for (var i=0;i<ids.length;i++){
		var DiagnosCatRowId=GetCellData(ids[i],"DiagnosCatRowId");
		var MRCIDRowId=GetCellData(ids[i],"MRCIDRowId");
		var DiagnosNotes=GetCellData(ids[i],"DiagnosNotes");
		if (DiagnosNotes!="") DiagnosNotes=DiagnosNotes.replace(/[\\\@\#\$\^\&\*\{\}\:\"\<\>\?]/g,"")
		if ((MRCIDRowId=="")&&(DiagnosNotes=="")) continue;
		var Prefix=GetCellData(ids[i],"DiagnosPrefix");
		var SDSInfo=GetCellData(ids[i],"SDSInfo");
		if(DiagnosCatRowId!=2){
			DiagArr.push({ICDRowid:MRCIDRowId,Note:DiagnosNotes,Type:DiagnosCatRowId,Prefix:Prefix,SDSInfo:SDSInfo,SyndData:[]});
		}else{
			if(!DiagArr.length||(DiagArr[DiagArr.length-1].Type!=1)){
				$.messager.alert("提示","证型必须伴随着中医诊断添加<br>请遵循顺序:中医诊断1(证型1,证型2,..),中医诊断2(证型1,证型2,..),...");
				return;
			}
			DiagArr[DiagArr.length-1].SyndData.push({SyndromeID:MRCIDRowId,Note:DiagnosNotes});
		}
	}
	if(!DiagArr.length){
		$.messager.popover({msg:'请选择有效的诊断记录',type:'alert'});
		return;
	}
	websys_showModal({
		iconCls:'icon-w-copy',
		url:"diagnos.template.maintain.csp?CopyItemFlag=Y",
		title:$g('添加到模板'),
		width:385,height:'60%',
		ItemData:DiagArr,
		callBackFun:function(){
			$.messager.popover({msg:'保存成功',type:'success'});
			frames["diagTempFrame"].InitFavType();
		}		
	});
}
function ShowAllDiagList()
{
	websys_showModal({
		iconCls:'icon-w-list',
		url:"dhcdocpatalldiagnos.csp?PatientID=" + ServerObj.PatientID,
		title:$g('全部诊断列表'),
		width:'95%',height:'95%',
		AddCopyDiagToList:AddCopyDiagToList
	});
}
function AddSelHistoryDiag()
{
	var $sel=$('#pHistory').find('td[name=Check]').children(':checked');
	if(!$sel.size()){
		$.messager.popover({msg:'请勾选需要添加的历史诊断',type:'alert'});
		return;
	}
	$sel.each(function(){
		var DiagObj=$(this).closest('tr').data('DiagObj');
		var CMFlag='';
		if(DiagObj.DiagType==$g('中医')) CMFlag='Y';
		else if(DiagObj.DiagType==$g('证型')) CMFlag='H';
		AddDiagItemtoList(DiagObj.ICDRowid,DiagObj.Note,CMFlag,DiagObj.PrefixDesc,DiagObj.SDSInfo,DiagObj.TCMTreatmentID,DiagObj.TCMTreatment,DiagObj.LongDiagnosFlagRowId);
	});
	$('#pHistory').find('input:checkbox').prop('checked',false);
	if (ServerObj.DiagFromTempOrHisAutoSave==1){
		InsertMutiMRDiagnos();
	}
}
function InitDiagnosICDDescLookUpSDS(rowid)
{
	var ICDType=GetICDType(rowid);
	InitDiagnosICDDescLookUp(rowid+"_DiagnosICDDesc",ICDType+'^'+ServerObj.PAAdmType);
}
//CDSS诊断选择回调
function CDSSPropertyConfirmCallBack(resWordICD,DomID){
	var SDSSArr=resWordICD.split("^");
	var ICDCode=SDSSArr[6];
	var ICDDesc=SDSSArr[7];
	var ICDRowid=SDSSArr[8];
	if(ICDRowid==''){
		$.messager.alert('添加失败',ICDDesc+' 未对照ICD诊断');
		return
	}
	var rowid=DomID.split("_")[0];
	var ItemStr=ICDDesc+"^"+ICDRowid+"^"+ICDCode;
	var rtn=DiagItemLookupSelect(ItemStr,rowid);
	if (rtn !==false){
		var SDSInfo="^"+SDSSArr[0]+"^"+SDSSArr[2]+"^"+SDSSArr[4]+"^"+SDSSArr[3];
		var SDSDesc=SDSSArr[1];
		//SetCellData(rowid,"DiagnosNotes",Note);
		SetCellData(rowid,"SDSInfo",SDSInfo);
		SetCellData(rowid,"SDSDesc",SDSDesc);
	}
}
//CDSS诊断取消选择回调
function CDSSPropertyCcancelfirmCallBack(DomID){
}
function EditSDSExpProperty(rowid)
{
   if(!ServerObj.SDSDiagEntry) return;
   $("#tabDiagnosEntry").closest('.ui-jqgrid-bdiv').scrollLeft(0);
   //var MRDIARowId=GetCellData(rowid,"MRDIARowId");
   //if(!MRDIARowId) return;
   var SDSInfo=GetCellData(rowid,"SDSInfo");
   if(!SDSInfo) return;
   var SDSInfoArr=SDSInfo.split("^");
   var SDSRowId=SDSInfoArr[0];
   var SDSTermDR=SDSInfoArr[1];
   var SDSValue=SDSInfoArr[2];
   var SDSWordID=SDSInfoArr[3];
   var SDSSupplement=SDSInfoArr[4];
   var ICDType=GetICDType(rowid);
   InSDSExpProperty(SDSRowId,SDSTermDR,SDSSupplement,$('#'+rowid+'_DiagnosICDDesc'),SDSValue,SDSWordID,ICDType+'^'+ServerObj.PAAdmType);
}
function InitDateFlatpickr(rowid){
	var dateFormate="d/m/Y"; //d-m-Y H:i:S
    if (ServerObj.defaultDataCache==3){
        dateFormate="Y-m-d"
    }
    PageLogicObj.fpArr.push({"rowid":rowid});
    var index=$.hisui.indexOfArray(PageLogicObj.fpArr,"rowid",rowid);
	PageLogicObj.fpArr[index].DiagnosOnsetDate=$("#"+rowid+"_DiagnosOnsetDate").flatpickr({
    	enableTime: false,
    	enableSeconds:false,
    	dateFormat: dateFormate,
    	time_24hr: false,
    	onOpen:function(pa1,ap2){
	    	var index=$.hisui.indexOfArray(PageLogicObj.fpArr,"rowid",rowid);
	        PageLogicObj.fpArr[index]["DiagnosOnsetDate"].setDate(ap2,true);
	    },
		onClose:function(){
			SyncChildRow(rowid,'DiagnosOnsetDate');
		}
    })
    PageLogicObj.fpArr[index].DiagnosDate=$("#"+rowid+"_DiagnosDate").flatpickr({
    	enableTime: false,
    	enableSeconds:false,
    	dateFormat: dateFormate,
    	time_24hr: false,
    	onOpen:function(pa1,ap2){
	    	var index=$.hisui.indexOfArray(PageLogicObj.fpArr,"rowid",rowid);
	        PageLogicObj.fpArr[index]["DiagnosDate"].setDate(ap2,true);
	    },
		onClose:function(){
			SyncChildRow(rowid,'DiagnosDate');
		}
    })
}

///检查初复诊规则
function CheckFirOrReAdm(callBackFun){
    if(PageLogicObj.AlertFstOrReAdmFlag!=0){
        callBackFun();
        return;
    }
    if(ServerObj.ReAdmRuleByCode!="DIA") {
        callBackFun();
        return;
    }
    if(ServerObj.PAAdmType=="I"){
        callBackFun();
        return;
    }

    var FstOrReAdm="0"
    var o=$HUI.radio("#ReAdmis")
    if (o.getValue()==true) { FstOrReAdm="1" }
    var o=$HUI.radio("#FirstAdm")
    if (o.getValue()==true) { FstOrReAdm="0" }
    var o=$HUI.radio("#OutReAdm")
    if (o.getValue()==true) { FstOrReAdm="1" }

    var DiaArr=[];
    var rowids = $('#tabDiagnosEntry').getDataIDs();
    for(var i=0;i<rowids.length;i++){
        var MRCIDRowId=GetCellData(rowids[i],"MRCIDRowId");
        if(MRCIDRowId=="") continue;

        var MainDiagFlag=GetCellData(rowids[i],"MainDiagFlag");
        var MainFlag=(MainDiagFlag=="Y" || MainDiagFlag=="是")?"1":"0";
        var Item=MRCIDRowId+"!"+MainFlag;
        DiaArr.push(Item)
    }
    if(DiaArr.length==0){
		callBackFun();
		return;
	}
    var DiaArrICDs=DiaArr.join(",")
    var ParaObj={
        EpisodeID:ServerObj.EpisodeID,
        LocID:session['LOGON.CTLOCID'],
        DIAICDr:DiaArrICDs,
        HospID:session['LOGON.HOSPID']
    }
    var ParaStr=JSON.stringify(ParaObj)
    var ReAdmFlag=tkMakeServerCall("DHCDoc.DHCDocConfig.ReAdmRules", "GetReAdmFlag", ParaStr);
    if(FstOrReAdm!=ReAdmFlag){
        var FrtOrReAdmDesc=ReAdmFlag==1?"复诊":"初诊";
        $.messager.confirm("提示",'根据当前诊断数据及复诊规则判断,此患者为 【'+FrtOrReAdmDesc+'】 患者,是否变更患者初/复诊信息?',function(r){
            if(r){
                if(ReAdmFlag=="1"){
                    $HUI.radio("#ReAdmis").setValue(true);
                }else{
                    $HUI.radio("#FirstAdm").setValue(true);
                }
            }else{
                PageLogicObj.AlertFstOrReAdmFlag=1
            }
            callBackFun()
        })
    }else{
        callBackFun()
    }
}
function InitTCMTreat(rowid){
	$("#"+rowid+"_TCMTreatment").lookup({
		url:$URL,
		mode:'remote',
		method:"Get",
		idField:'TCMTRowId',
		textField:'TCMTDesc',
		columns:[[  
			{field:'TCMTDesc',title:'诊断名称',width:350,sortable:true},
			{field:'TCMTCode',title:'编码',width:120,sortable:true},
			{field:'TCMTRowId',hidden:true}
		]],
		pagination:true,
		panelWidth:500,
		panelHeight:300,
		isCombo:true,
		minQueryLen:2,
		delay:'500',
		queryOnSameQueryString:true,
		queryParams:{ClassName: 'DHCDoc.Diagnos.Common',QueryName:'QueryCMTreatment'},
		onBeforeLoad:function(param){
			var desc=param['q'];
			if (desc=="") return false;
			param.desc=desc;
			param.SessionStr = GetSessionStr();
		},
		onSelect:function(ind,item){
			if(!item){
				SetCellData(rowid,"TCMTreatmentID",''); 
				return;
			}
			SetCellData(rowid,"TCMTreatmentID",item.TCMTRowId);
			Add_Diag_row();
		}
   });
   ControlTCMTreatStyle(rowid);
}
function ControlTCMTreatStyle(rowid)
{
	var DiagnosCatRowId=GetCellData(rowid,"DiagnosCatRowId");
	if(DiagnosCatRowId!=2){
		SetCellData(rowid,"TCMTreatmentID",'');
		SetCellData(rowid,"TCMTreatment",'');
		$("#"+rowid+"_TCMTreatment").lookup('disable');
	}else{
		$("#"+rowid+"_TCMTreatment").lookup('enable');
	}
}
function AddCopyDiagToList(data)
{
	for(var i=0;i<data.length;i++){
		var diagObj=data[i];
		AddDiagItemtoList(diagObj.ICDRowid,diagObj.Note,diagObj.CMFlag,diagObj.Prefix,diagObj.SDSInfo,"","","",diagObj.Level);
		if(diagObj.children){
			for(var j=0;j<diagObj.children.length;j++){
				var chidObj=diagObj.children[j];
				AddDiagItemtoList(chidObj.ICDRowid,chidObj.Note,chidObj.CMFlag,chidObj.Prefix,chidObj.SDSInfo,chidObj.TCMTreatmentID,chidObj.TCMTreatment,"","","",chidObj.Level);
			}
		}
	}
	//从病历浏览界面复制,只提醒一次
	$.extend(ServerObj, {CopyDiagnosStr:[]});
	if (typeof(history.pushState) === 'function') {
		overrrideUrl("copyOeoris","");
	}
}

/// 展示第二副屏
function ShowSecondeWin(Flag){
    //展示信息总览
    if (PageLogicObj.MainSreenFlag==0){
	    var Obj={PatientID:ServerObj.PatientID,EpisodeID:ServerObj.EpisodeID,mradm:ServerObj.mradm};
	    if (Flag=="onOpenIPTab"){
		    //信息总览
		}
		if (Flag=="onOpenDHCEMRbrowse"){
			var JsonStr=$.m({
				ClassName:"DHCDoc.Util.Base",
				MethodName:"GetMenuInfoByName",
				MenuCode:"DHC.Seconde.DHCEMRbrowse"		//使用最新统一维护的菜单
			},false)
			if (JsonStr=="{}") return false;
			var JsonObj=JSON.parse(JsonStr);
			$.extend(Obj,JsonObj);
		}
		websys_emit(Flag,Obj);
	}
}
function InitRowBtn(rowid)
{
	SetCellData(rowid, "OperatBtn", '<div style="width:100%;height:100%"></div>');
	$('#tabDiagnosEntry').find('tr#'+rowid).find('td[aria-describedby="tabDiagnosEntry_OperatBtn"]').css('position','relative').children().marybtnbar({
		barCls:'background:none;padding-top:5px;',
		url:'',
		moreBtnText:'',
		data:ServerObj.RowBtnData,
		onClick:function(jq,cfg){
			jq.tooltip('hide');
			switch(cfg.id){
				case 'Edit_Row':
					EditRow(rowid);
					break;
				case 'Delete_Row':
					$("#tabDiagnosEntry").jqGrid('resetSelection').setSelection(rowid,true);
					Delete_Diag_btn();
					break;
				case 'Move_Up_Row':
					$("#tabDiagnosEntry").jqGrid('resetSelection').setSelection(rowid,true);
					BMoveUpclickhandler();
					break;
				case 'Move_Down_Row':
					$("#tabDiagnosEntry").jqGrid('resetSelection').setSelection(rowid,true);
					BMoveDownclickhandler();
					break;
				case 'Move_Left_Row':
					$("#tabDiagnosEntry").jqGrid('resetSelection').setSelection(rowid,true);
					BMoveLeftclickhandler();
					break;
				case 'Move_Right_Row':
					$("#tabDiagnosEntry").jqGrid('resetSelection').setSelection(rowid,true);
					BMoveRightclickhandler();
					break;
				case 'Prev_Add_Row':
					Add_Diag_row('before',rowid);
					break;
				case 'Next_Add_Row':
					Add_Diag_row('after',rowid);
					break;
				case 'Child_Add_Row':
					Add_Diag_row('after',rowid,true);
					break;
				default:break;
			}
		}
    });
}
function InitSpecLocForm()
{
	var region=ServerObj.SpecLocFormRegion;
	if(region=='window'){
		if(!ServerObj.SpecLocCatData.length){
			$('#btnShowSpecLoc').parent().remove();
			return
		}
		if(!$('#btnShowSpecLoc').size()){
			$('#pBaseInfo').append('<div><a id="btnShowSpecLoc">专科表单</a><div id="mShowSpecLoc" style="width:150px;"></div></div>');
			$('#btnShowSpecLoc').menubutton({menu:'#mShowSpecLoc'});
		}
		$('#mShowSpecLoc').empty();
		$.each(ServerObj.SpecLocCatData,function(index,row){
			$('#mShowSpecLoc').menu('appendItem',{
				text:row.text,
				onclick:function(){
					SpecLocDiagOpen(row.id,row.text);
				}
			})
		});
		return;
	}
	var layoutId=(['north','south'].indexOf(ServerObj.SpecLocFormRegion)>-1)?'layoutBaseInfo':'layoutMain';
	if(!ServerObj.SpecLocCatData.length){
		if($('#'+layoutId).layout('panel',region).size()){
			$('#'+layoutId).layout('remove',region);
		}
		return;
	}
	if(!$('#'+layoutId).layout('panel',region).size()){
		$('#'+layoutId).layout('add',{
            region:region,
            border:false,
            collapsible:false,
            split:true,
			height:400,
			width:350,
            content:'<div class="pSpecLocCat">'
						+'<div><div id="kwSpecLocCat"></div></div>'
						+'<div><iframe id="SpecLocFrame" name="SpecLocFrame" width="100%" height="100%" src="" frameborder="no" framespacing="0" marginwidth="0" marginheight="0" scrolling="auto"></iframe></div>'
					+'</div>'
        });
	}
	$('#kwSpecLocCat').keywords({
		singleSelect:true,
		items:ServerObj.SpecLocCatData,
		onSelect:function(item){
			var src='opdoc.specloc.diag.csp?PageFrom=DiagEntry&region='+region+'&SpecLocDiagCatCode='+item.id+'&EpisodeID='+ServerObj.EpisodeID+'&PatientID='+ServerObj.PatientID;
			if(typeof websys_writeMWToken=='function') src=websys_writeMWToken(src);
			$('#SpecLocFrame').attr('src',src);
		}
	}).keywords('select',ServerObj.SpecLocCatData[0].id);
}
function SpecLocDiagOpen(Code,Name)
{   
	websys_showModal({
		iconCls:'icon-w-edit',
		url:'opdoc.specloc.diag.csp?PageFrom=DiagEntry&region=window&SpecLocDiagCatCode='+Code+'&EpisodeID='+ServerObj.EpisodeID+'&PatientID='+ServerObj.PatientID,
		title:Name+$g(' 填写'),
		width:Code=='KQMB'?"95%":400,
		height:800,
		InsertLMPDiaClickhandler:InsertLMPDiaClickhandler
	});
}
function InsertLMPDiaClickhandler(PregnancyLMP){

	if (PregnancyLMP=="") return $g("末次月经时间为空");
	var ret = $.cm({
			ClassName:"web.DHCDocDiagnosEntryV8",
			MethodName:"GetPatLMPResultByLMP",
			dataType:"text",
			EpisodeID:ServerObj.EpisodeID,
			LMPDate:PregnancyLMP
		},false);
	var retArr=ret.split("^");
	if (retArr[0]!="0") return retArr[1]; 
	var MRCICDRowid=retArr[1];
	var MRCDiagNote=retArr[2];
	var ret=AddDiagItemtoList(MRCICDRowid,MRCDiagNote,"","");
	if(ret && ServerObj.DiagFromTempOrHisAutoSave==1){
		InsertMutiMRDiagnos();
	}
	return "";
}
function SyncChildRow(rowid,field,value)
{
	if(typeof value=='undefined'){
		value=GetCellData(rowid,field);
	}
	var GroupRowids=GetGroupRowids(rowid);
	for(var i=1;i<GroupRowids.length;i++){
		SetCellData(GroupRowids[i],field,value);
	}
}
