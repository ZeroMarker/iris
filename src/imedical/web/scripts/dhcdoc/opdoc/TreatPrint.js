var treeData;
var rightSegmentPanel = null;
var OETableConfig = {
	"tableConfig" : {}
};
var menuItemValueMap = {};
var printDeviceCom=null;
var $paperSize=null;
var allOEArr=new Array;
var waitCancelOEArr=new Array;
var m_IDCredTypePlate="01"; //身份证代码字段
var OrderPrescNo=""
function Init(){
	rightSegmentPanel = $("#rightSegmentPanel");
	InitPrintItemTree();
	LoadPrintItemTree();
}
function InitPrintItemTree(){
	var tbox=$HUI.tree("#PrintItemTree",{
		onBeforeExpand:function(node){
			var targetId=node.id;
			var state="closed",defId="",attributes="";
			var treeDataArr=new Array();
			for (var i=0;i<treeData.length;i++){
				var oneJsonData=treeData[i];
				var pId=oneJsonData["pId"]; //父目录id
				if (pId!=targetId) continue;
				var id=oneJsonData["id"];
				var name=oneJsonData["name"];
				var nocheck=oneJsonData["nocheck"]; //有无复选框
				var checked=oneJsonData["checked"]; //是否选中
				if (checked=="1") checked=true;
				else checked=false;
				var urlStyle=oneJsonData["urlStyle"]; //链接类型
				var expandMethodForLoadingTable=oneJsonData["expandMethodForLoadingTable"]; //展开事件 
				var urlObject=oneJsonData["urlObject"]; //链接
				var value=oneJsonData["value"];
				var clickevent=oneJsonData["clickevent"]; //点击事件
				var previewxmlname=oneJsonData["previewxmlname"];
				var printmethod=oneJsonData["printmethod"];
				var state='open';
				treeDataArr.push({"id":id,"text":name,"state":state,"pId":pId,"checked":checked,"ischecked":checked,"nocheck":nocheck,
                   "expandMethodForLoadingTable":expandMethodForLoadingTable,"urlObject":urlObject,"clickevent":clickevent,
                   "value":value,"urlStyle":urlStyle,"previewxmlname":previewxmlname,"printmethod":printmethod
				});
			};
			RemoveChildTree(node);
			tbox.append({
				parent: node.target,
				data:treeDataArr
			});
			//节点加载完之后才能刷新右侧数据
			LoadRightPanelPage(node);
		},
		onClick:function(node){
			tbox.toggle(node.target);
			if (node["pId"]!="0"){	
				$(".childNode-selected").removeClass("childNode-selected");
				$("#"+node.target.id).removeClass("tree-node-selected").addClass("childNode-selected");			
				if (node["nocheck"]=="1"){
					/*var $checkId=$("#"+node["id"]+"_check");
					if ($checkId.is(":checked")){
						$checkId.attr("checked",false);
					}else{
						$checkId.attr("checked",true);
					}*/
				}else{
					LoadRightPanelPage(node);
				}
				
			}
		},
		formatter:function(node){
			if (node["nocheck"]=="1"){
				if (node["checked"]==true){
					return "<input id="+node["id"]+"_check"+" type='checkbox' checked=true>"+node.text;
				}else{
					return "<input id="+node["id"]+"_check"+" type='checkbox'>"+node.text;
				}
			}else{
				return node.text;
			}
		},
		onLoadSuccess:function(node, data){
			for (var i=0;i<data.length;i++){
				if (data[i]["pId"]=="0"){
					$("#"+data[i]["domId"]).addClass("RootsNodes");
				}
				if (data[i]["value"] && data[i]["value"] != ""){
					menuItemValueMap[data[i]["value"]] = data[i];
				}
			}
			if ($("input[id$='_check']").length>0){
				$("input[id$='_check']").click(TreeOnCheck);
			}
		}
	});
}
//左侧checkbox勾选/取消勾选
function TreeOnCheck(e,nodeid){
	var indexMap = OETableConfig["Index"];
	if (e!=""){
		var ckId=e.target.id;
	}else{
		var ckId=nodeid+"_check"
	}
	var $ck=$("#"+ckId);
	var node= $('#PrintItemTree').tree('find', ckId.split("_")[0]);
	var nodeV = node["value"];
	if (!nodeV) return true;
	if (!OETableConfig["Index2"][nodeV]) return;
	var checkFlag=$ck.is(":checked");
	if (checkFlag){
		node["ischecked"]=true;
	}else{
		node["ischecked"]=false;
	}
	for ( var oe in indexMap) {
		if (indexMap[oe][nodeV] == undefined) continue;
		//如果已经打印过了，则按照未勾选处理
		var tid=indexMap[oe]["tableId"];
		indexMap[oe][nodeV] = checkFlag ? 1 : 0;
		if ((OETableConfig["tableConfig"][tid]["menuOEConfig"][nodeV])&&(OETableConfig["tableConfig"][tid]["menuOEConfig"][nodeV][oe]>=1)){
			indexMap[oe][nodeV] = 0;
		}
	}
	for ( var oe in indexMap) {
		var oem = indexMap[oe];
		//var $tab=$HUI.datagrid("#"+oem["tableId"]);
		//var index=$tab.getRowIndex(oe);
		var $tab=$("#"+oem["tableId"]);
		var index=$tab.simplydatagrid("getRowIndex",oe);
		if (checkFlag) {
			if (oem[nodeV] == 1) {
				//$tab.checkRow(index);
				$tab.simplydatagrid("checkRow",index);
			}
		}else{
			var flag = true;
			for ( var mv in oem) {
				if (oem[mv] == 1) {
					flag = false;
					break;
				}
			}
			if (flag) {
				//$tab.uncheckRow(index);
				$tab.simplydatagrid("uncheckRow",index);
			}
		}
	}
}
function LoadRightPanelPage(node){
	if (node["urlStyle"] == "iframe") { //链接类型
		loadIframe(node, true);
	} else {
		loadHtmlSegment(node["urlObject"], true, function() {
			if (node["expandMethodForLoadingTable"]) {
				if (("#EMRInfo").length>0){
					LoadEMRInfo();
				}
				if (("#DiagnosInfo").length>0){
					LoadDiagnosInfo()
				}
				eval(node["expandMethodForLoadingTable"]+"('"+node.id+"')");
			}
		});
	}
}

function LoadPrintItemTree(){
	$.cm({
		ClassName:"DHCDoc.OPDoc.TreatPrintConfigQuery",
		QueryName:"TreatPrintConfig",
		ActiveOrNo:'1',
		EpisodeID:ServerObj.EpisodeID
	},function(jsonData){ 
		treeData=jsonData.rows;
		var defId="";
		var tbox=$HUI.tree("#PrintItemTree");
		var treeDataArr=new Array();
		for (var i=0;i<jsonData.rows.length;i++){
			var oneJsonData=jsonData.rows[i];
			var id=oneJsonData["id"];
			var name=oneJsonData["name"];
			var nocheck=oneJsonData["nocheck"]; //有无复选框
			var checked=oneJsonData["checked"]; //是否选中
			if (checked=="1") checked="true";
			else checked="false";
			var urlStyle=oneJsonData["urlStyle"]; //链接类型
			var pId=oneJsonData["pId"]; //父目录id
			var expandMethodForLoadingTable=oneJsonData["expandMethodForLoadingTable"]; //展开事件 
			var urlObject=oneJsonData["urlObject"]; //链接
			var value=oneJsonData["value"];
			var clickevent=oneJsonData["clickevent"]; //点击事件
			var open=oneJsonData["open"]; //是否展开
			if (open=="1") defId=id;
			var previewxmlname=oneJsonData["previewxmlname"];
			var printmethod=oneJsonData["printmethod"];
			if (pId==0){
				treeDataArr.push({"id":id,"text":name,"state":'closed',"pId":pId,"checked":checked,"nocheck":nocheck,
                   "expandMethodForLoadingTable":expandMethodForLoadingTable,"urlObject":urlObject,"clickevent":clickevent,
                   "value":value,"urlStyle":urlStyle,"previewxmlname":previewxmlname,"printmethod":printmethod
				 });
			}
		}
		tbox.append({
			parent: "",
			data:treeDataArr
		});
		var node =tbox.find(defId);
		tbox.expand(node.target);
		tbox.select(node.target);
	});
}
//展开事件 加载table数据
function loadOrdTableData(id) {
	var tbox=$HUI.tree("#PrintItemTree");
	var $checkbox=$("[id$='_check']");
	var selectedItems = [];
	for (var i = 0, len = $checkbox.length; i < len; ++i) {
		var ckId=$checkbox[i]["id"];
		var nodeId=ckId.split("_")[0];
		if ($("#"+ckId).is(":checked")){
			var tmpnode=tbox.find(nodeId);
			if (!tmpnode["value"] || tmpnode["value"] == "") continue;
			selectedItems.push(tmpnode["value"]);
		}
	}
	$("#previewBtn,#printBtn,#BFind,#BCancel").unbind('click');
	//预览事件
	$("#previewBtn").click(preview);
	//打印事件
	$("#printBtn").click(function(){print("Y")});
	// 撤销医嘱 
	$("#BCancel").click(CancelOrdClick); 
	$("#BFind").click(loadOrdTableData); //查询事件
	var selObj=$("#OrdComStatusKeyWord").keywords("getSelected");
	var OrdComStatus=selObj[0].id;
	var args = {
		"episodeID" : ServerObj.EpisodeID,
		"menuItems" : selectedItems.join(",")
	};
	$.cm({
		ClassName:"DHCDoc.OPDoc.TreatPrint",
		MethodName:"QueryOEForPrintJson",
		episodeID:args.episodeID,
		menuItems:args.menuItems,
		StDate:$("#StDate").datebox('getValue'),
		EndDate:$("#EndDate").datebox('getValue'),
		OrdComStatus:OrdComStatus
	},function(jsonData){
		removeTable();
		OETableConfig["Index"] = {};
		OETableConfig["Index2"] = {};
		OETableConfig["tableConfig"] = {};
		/*for (var i=0;i<jsonData.length;i++){
			buildTable(jsonData[i]);
		}
		tabledrawCallBack();
		indexOETableConfig();
		if ($(".ImageButton").length>=1){
			$(".ImageButton").click(imgpreview);
		}*/
		var len=jsonData.length;
		if (len>0) {
			var RanderTable=function (i){
					setTimeout(function(){
						buildTable(jsonData[i]);
						i++;
						if (i<len){
							RanderTable(i);
						}else{
							tabledrawCallBack();
							indexOETableConfig();
							if ($(".ImageButton").length>=1){
								$(".ImageButton").click(imgpreview);
							}
						}
					})
			}
			RanderTable(0);
		}		
	});
}
function loadIframe(node, isReplacePanelBody, callback) {
	if (isReplacePanelBody) {
		rightSegmentPanel.empty();
	}
	var lnk=replaceLinkParams(node["urlObject"]);
	if(typeof websys_writeMWToken=='function') lnk=websys_writeMWToken(lnk);
	var temp="<iframe id='"+node["id"] + "_printItemIframe"+"' width='100%' height='100%' scrolling='auto' frameborder='0' src='"+lnk+"'></iframe>"
	rightSegmentPanel.append(temp);
	if (callback) callback();
}
function replaceLinkParams(lnk){
	var ret = lnk.replace('@patientID', ServerObj.PatientID);
    ret = ret.replace('@episodeID', ServerObj.EpisodeID);
    ret = ret.replace('@mradm', ServerObj.mradm);
    return ret;
}
function loadHtmlSegment(url, isReplacePanelBody, callback) {
	if (url==""){
		if (isReplacePanelBody) {
			rightSegmentPanel.empty();
		}
		if (callback) callback();
		return false;
	}
	if(typeof websys_writeMWToken=='function') url=websys_writeMWToken(url);
	$.ajax(url, {
		"type" : "GET",
		"dataType" : "html",
		"success" : function(data, textStatus) {
			if (isReplacePanelBody) {
				rightSegmentPanel.empty();
			}
			rightSegmentPanel.append(data);
			$HUI.linkbutton(".hisui-linkbutton",{});
			$HUI.checkbox('#selAll',{
				onCheckChange:function(e,value){
					selAllChange(value);
				}
			});
			$HUI.datebox(".hisui-datebox",{
				formatter:myformatter,
				parser:myparser
			});
			var _$label = $("label[for=StDate]");
				if (_$label.length > 0){
				   domName = _$label[0].innerHTML;
				    _$label[0].innerHTML=$g(domName);
				}
			var _$label = $("label[for=EndDate]");
				if (_$label.length > 0){
				   domName = _$label[0].innerHTML;
				    _$label[0].innerHTML=$g(domName);
				}
			$("#StDate").datebox('setValue',ServerObj.StartDate);
			$("#OrdComStatusKeyWord").keywords({
			    singleSelect:true,
			    //labelCls:'red',
			    items:[
			        {text:'全部',id:'All'},
			        {text:'未收费',id:'UnPay',selected:true},
			        {text:'已收费',id:'Payed'}
			    ],
			    onClick:function(v){
					loadOrdTableData();
				}
			});
			if (callback) callback();
		}
	});
}
function RemoveChildTree(node){
	if (node.children!=undefined){
		var tbox=$HUI.tree("#PrintItemTree");
	    var roots=tbox.getChildren(node.target);
	    for (var i=roots.length-1;i>=0;i--){
		  var tmpnode = tbox.find(roots[i].id);
		  tbox.remove(tmpnode.target);
	    }
	}
}
var selRowIndex="";
function buildTable(data){
	var panel=$("#printItemIframeTemplate");
	var temp=$("#templtable-div");
	var tool=temp.clone();
	tool.removeAttr("style").removeAttr("id");
	tool.attr("id",data["id"]+"Panle");
	OETableConfig["tableConfig"][data["id"]] = data["config"];
	panel.append(tool);
	var oneHeight=57; 
	var dataLen=data["rows"].length;
	if (dataLen<=1){
		var PanelMaxHeight=oneHeight*3;
	}else{
		var PanelMaxHeight=oneHeight*(data["rows"].length-1)+100;  //oneHeight*(data["rows"].length+1);
	}
	var config=data["config"];
	if (data.titleClass.indexOf("cmpresc-head")>=0){
		/*if (config["IsDMPresc"]) {
			var PanelMaxHeight=145;
		}else{
			var PanelMaxHeight=105;
		}*/
		var PanelMaxHeight=105;
	}
	tool.height(PanelMaxHeight);
	var selectConsistent=config["selectConsistent"];
	var allOE = {};
	var flag = false;
	for ( var mv in config["menuOEConfig"]) {
		for ( var oeId in config["menuOEConfig"][mv]) {
			allOE[oeId] = true;
			flag = true;
		}
	}
	allOEArr[data["id"]]=allOE;
	var columns=new Array();
	var head=data["head"];	
	for(var i=0,len=head.length;i<len;++i){
		var field=data["rowCols"][i].data;
		var title=head[i];
		var isHidden=data["HiddenCols"][i][field];
		if (config["checkHeaders"] && config["checkHeaders"][i]){
			columns.push({"field":field,"title":title,"checkbox":true})
		}else{
			if (isHidden=="Y"){
				columns.push({"field":field,"title":title,"hidden":true});
			}else{
				if (field=="OEItemID"){
					columns.push({"field":field,"title":title,formatter:function(value,rec){
						var btn = '<a class="editcls" onclick="ordDetailInfoShow(\'' + rec.OEItemID + '\')">'+value+'</a>';
					    return btn;
					}});
				}else if(field=="OrdBilled"){
					columns.push({"field":field,"title":title,formatter:function(value,rec){
						if (rec.isCanCancelPermission==0){
                            var Class="editcls"
							if ((rec.OrderType=="R")&&(rec.PrescNo=="")){
								Class+=" waitbillccancel";
								waitCancelOEArr[rec.OEItemID]=value;
								value="待撤销";
							}
							var btn = '<a class="'+Class+'" id="'+data["id"]+"-"+rec.OEItemID.split("||")[1]+'"onclick="ordWaitCancel(\'' + data["id"]+'\',\''+rec.OEItemID + '\')">'+value+'</a>';
						    return btn;
					    }else{
						    return value;
						}
					}});
				}else if(field=="ReportLinkInfo"){
					columns.push({"field":field,"title":title,formatter:function(value,rec){
						if (value!=""){
							var btn = '<a class="editcls" onclick="OpenReportLink(\'' + rec.ReportLinkInfo + '\')">查看报告</a>';
						    return btn;
					    }else{
						    return "";
						}
					}});
				}else{
					columns.push({"field":field,"title":title});
				}
			}
		}
	}
	var newcolumns=new Array();
	newcolumns.push(columns);
	var content='<table class="simplydatagrid" data-options="headerCls:'+"'panel-header-gray'"+'" id="'+data["id"]+'"></table> ' //hisui-datagrid
	tool.append(content);
	if (data["titleClass"]=="") data["titleClass"]="panel-header-gray";
	var title=data["title"];
	var OrderPrescNo=data.rows[0].OrderPrescNo
	if (config["IsDMPresc"]) {
		title=title+'<a href="#" title ="'+OrderPrescNo+'" class="ImageButton">'+$g("患者及代理人信息")+'</a>';
	}
	if (data.titleClass.indexOf("cmpresc-head")>=0){
		title=title+'<a href="#" onClick=CMPrescDetailClick(\''+data["id"]+'\') class="toggle-btn">'+$g("处方明细")+'</a>';
	}
	var type=data["id"].split("_")[0];
	if ((type!="L")&&(type!="S")&&(type!="O")&&(config["IsNeedLinkDiagPresc"])){
		title=title+'<a href="#" onClick=PrescLinkDiagClick(\''+data["id"]+'\') class="toggle-btn">'+$g("关联诊断")+'</a>';
	}
    if (type=="处方号未生成"){
		title=title.replace("处方号未生成","<span style='color:red'>处方号未生成</span>")
	}
	var tableId=data["id"];
	$("#"+data["id"]).simplydatagrid({
	   title:title,
	   headerCls:data["titleClass"],
	   id:data["id"],
	   idField:'OEItemID',
	   columns: newcolumns,
	   data:data["rows"],
	   border:false,
       onClickRow:function(index, row){
		var OrderId=row.OEItemID;
		if (OrderId.indexOf("||")>-1){
			var MainSreenFlag=websys_getAppScreenIndex();
			if (MainSreenFlag==0){
				websys_emit("onSelectOrdInDoc",{OrderId:OrderId});
			}
		}	
     },
	   onCheck:function(index, row){
		   if (row['ReqID']!=""){
				var GridData=$("#"+data["id"]).simplydatagrid("getRows");
				for (var i=0;i<GridData.length;i++){
					if (i==index) continue;
					if (GridData[i]["ReqID"]==row['ReqID']){
						$("#"+data["id"]).simplydatagrid('checkRow',i)
					}
				}
			}
	   },
	   onUncheck: function(index, row){
			if (row['ReqID']!=""){
				var GridData=$("#"+data["id"]).simplydatagrid("getRows");
				for (var i=0;i<GridData.length;i++){
					if (i==index) continue;
					if (GridData[i]["ReqID"]==row['ReqID']){
						$("#"+data["id"]).simplydatagrid('uncheckRow',i)
					}
				}
			}
	   }
	 });
	/*$("#"+data["id"]).datagrid({
		title:data["title"],
		headerCls:data["titleClass"],
		fit : true,
		border : false,
		striped : false,
		singleSelect : false,
		fitColumns : false,
		autoRowHeight : false,
		autoSizeColumn : false,
		rownumbers:false,
		pagination : false,  
		idField:'OEItemID',
		columns :newcolumns,
		data:data["rows"],
		onCheck:function(index, row){
			if (row['ReqID']!=""){
				if (selRowIndex!="") return false;
				var GridData=$("#"+data["id"]).datagrid("getData");
				for (var i=index+1;i<GridData.rows.length;i++){
					if (GridData.rows[i]["ReqID"]==row['ReqID']){
						selRowIndex=i;
						$("#"+data["id"]).datagrid('checkRow',i)
					}
				}
				selRowIndex="";
			}
		},
		onUncheck: function(index, row){
			if (row['ReqID']!=""){
				if (selRowIndex!="") return false;
				var GridData=$("#"+data["id"]).datagrid("getData");
				for (var i=index+1;i<GridData.rows.length;i++){
					if (GridData.rows[i]["ReqID"]==row['ReqID']){
						selRowIndex=i;
						$("#"+data["id"]).datagrid('uncheckRow',i)
					}
				}
				selRowIndex="";
			}
		}
	});*/
}
function CMPrescDetailClick(tableId){
	//var db=$HUI.datagrid("#"+tableId); 
	//var rows=db.getRows();
	var opts=$("#"+tableId).simplydatagrid('options');
	var rows=$("#"+tableId).simplydatagrid('getRows');
	if (rows.length<=1){
		var PanelMaxHeight=105;
	}else{
		var oneHeight=47; 
		var PanelMaxHeight=oneHeight*(rows.length-1)+100;
	}
	destroyDialog("tabCMPrescDetailPanel");
	//var Content="<table id='tabCMPrescDetail' style='margin:5px;border:none;width:300px;'></table>";
	var Content=initDiagDivHtml("tabCMPrescDetail");
	var iconCls="icon-w-list";
	createModalDialog("tabCMPrescDetailPanel",tableId.split("_")[0]+$g("草药处方医嘱明细"), 800, 400,iconCls,"",Content,"",true);
	$("#tabCMPrescDetail").datagrid({  
		height:330,
		border : false,
		striped : false,
		singleSelect : false,
		fitColumns : true,
		autoRowHeight : true,
		autoSizeColumn : true,
		rownumbers:false,
		pagination : false, 
		idField:'OEItemID',
		columns:opts['columns'],
		data:rows
	});
	$("#tabCMPrescDetail").datagrid('hideColumn','PrintFlag');
	$("#tabCMPrescDetail").datagrid('hideColumn','OrdBilled');
	
}
function removeTable(){
	var $table=$("[id$='_TablePanle']");
		$table.remove();
}
function imgpreview(){
	OrderPrescNo=this.title
	$.ajax("opdoc.treatprintimage.csp"+((typeof websys_getMWToken=='function')?("?MWToken="+websys_getMWToken()):""), {
		"type" : "GET",
		"dataType" : "html",
		"success" : function(data, textStatus) {
			var $code = $(data);
			createModalDialog("PatSupplyInfo",$g("患者及代理人信息"), 615, 340,"icon-w-save","保存",$(data),"SaveSupplyInfo(OrderPrescNo)",true);
			InitTextFile(OrderPrescNo);
			//$('#Save').click(SaveSupplyInfo(OrderPrescNo))
			//var OrderPrescNo=""
			var domIdStr="PAPMICredType^PatCredNo^AgencyCredType^SupplyCredNo^SupplyName^AgencyTel^PatAddress^PatWeight"
			for (var i=0; i< domIdStr.split("^").length; i++){
				var domId = domIdStr.split("^")[i]
				if (domId == "") {
					continue;
				}
				var _$label = $("label[for="+domId+"]");
				if (_$label.length > 0){
				   domName = _$label[0].innerHTML;
				    _$label[0].innerHTML=$g(domName);
				}
			}
		},

		"error" : function(XMLHttpRequest, textStatus, errorThrown) {
			console.log(textStatus);
		}
	});
}
function SaveSupplyInfo(OrderPrescNo) {
	//alert(OrderPrescNo)
	var PatAddress = $("#PatAddress").val();
	var Weight=$("#PatWeight").val();
	var PatCredNo = $("#PatCredNo").val();
	var SupplyName = $("#SupplyName").val();
	var SupplyCredNo = $("#SupplyCredNo").val();
	var SupplyAgencyTel =  $("#AgencyTel").val();
	if((PatCredNo=="")&&((SupplyCredNo=="")||(SupplyName=="")||(SupplyAgencyTel==""))){
		/*if ((needPrintConfig)&&(needPrintConfig["menuNodes"])&&((needPrintConfig["menuNodes"]["CFD"])||(needPrintConfig["menuNodes"]["CFZ"]))){
			var printDMPrescFlag=0;
			var dangerTab=$(".danger-head");
			for (var m=0;m<dangerTab.length;m++){
				var tabId=$(dangerTab[m]).children("table")[0].id;
				var selData=$("#"+tabId).simplydatagrid('getChecked');
				if (selData.length>0){
					printDMPrescFlag=1;
					break;
				}
			}
			if (printDMPrescFlag==1){
				$.messager.alert("提示","信息不完整,请填写完整信息","info",function(){
					$("#PatCredNo").focus();
				});
				return false;
			}
		}*/
		$.messager.alert("提示","信息不完整,请填写完整信息","info",function(){
			$("#PatCredNo").focus();
		});
		return false;
	}
	
	var IsDPatCredNo=true,IsIdCardNo=true;
	if(PatCredNo!=""){
		var myrtn=IsCredTypeID("PAPMICredType");
		if (myrtn){
			IsIdCardNo=DHCWeb_IsIdCardNo(PatCredNo);
			if(!IsIdCardNo) return false;
			
			var IDNoInfoStr=DHCWeb_GetInfoFromId(PatCredNo)
			var IDBirthday=IDNoInfoStr[2]  
			if (ServerObj.PatDobDate!=IDBirthday){
				$.messager.alert("提示","出生日期与身份证信息不符!","info",function(){
					$("#SupplyCredNo").focus();
				});
	   		    return false;
			}
			var IDSex=IDNoInfoStr[3]
			if(ServerObj.PatSex!=IDSex){
				$.messager.alert("提示","身份证号:"+PatCredNo+"对应的性别是【"+IDSex+"】,与患者本人性别不同!","info",function(){
					$('#SupplyCredNo').next('span').find('input').focus();
				});
				return false;
			}
			
			var myage=getAge(PatCredNo);
			if ((!isNaN(myage))&&(myage!="")){
				if (parseInt(myage)>=parseInt(176)){
					$.messager.alert("提示","本人年龄不能超过176岁!","info",function(){
						$("#SupplyCredNo").focus();
					});
					return false;
				}
			}
		}
	}
	if(SupplyCredNo!=""){
		var myrtn=IsCredTypeID("AgencyCredType");
		if (myrtn){
			IsDPatCredNo=DHCWeb_IsIdCardNo(SupplyCredNo);
			if(!IsDPatCredNo) return false;
			var myage=getAge(SupplyCredNo);
			if ((!isNaN(myage))&&(myage!="")){
				if (parseInt(myage)>=parseInt(176)){
					$.messager.alert("提示","代办人年龄不能超过176岁!","info",function(){
						$("#SupplyCredNo").focus();
					});
					return false;
				}
			}
		}
	}
	if (SupplyAgencyTel!=""){
		if (!CheckTelOrMobile(SupplyAgencyTel,"AgencyTel","代办人联系电话")) return false;
	}
	if((IsIdCardNo)&&(IsDPatCredNo)){
		var PAPMICredType=$("#PAPMICredType").combobox('getValue');
		var PAPMICredTypeId=PAPMICredType.split("^")[0];
		var ret=tkMakeServerCall('web.DHCBL.CARD.UCardPaPatMasInfo','CheckCredNoValid',PatCredNo,PAPMICredTypeId);
		if (ret!=0){
			$.messager.alert("提示",$g("患者本人") +ret,"info")
			return ;
		}
		var AgencyCredType=$("#AgencyCredType").combobox('getValue');
		var AgencyCredTypeId=AgencyCredType.split("^")[0];
		var ret=tkMakeServerCall('web.DHCBL.CARD.UCardPaPatMasInfo','CheckCredNoValid',SupplyCredNo,AgencyCredTypeId);
		if (ret!=0){
			$.messager.alert("提示",$g("代办人") +ret,"info")
			return ;
		}

		var PatInfo = PatCredNo + "^" + SupplyName + "^" + SupplyCredNo + "^" + SupplyAgencyTel+"^"+PAPMICredTypeId+"^"+AgencyCredTypeId; 
	}
	var rtn=$.cm({
		ClassName:"web.DHCDocCheckPoison",
		MethodName:"UpdateAgencyInfo",
		dataType:"text",
		OrderPrescNo:OrderPrescNo,
		EpisodeID:ServerObj.EpisodeID,
		PatInfo:PatInfo
	},false);
	if (rtn!="0"){
		$.messager.alert("提示",rtn+"保存信息失败！","info",function(){});
		return false;
		
	}
	//if (PatAddress!=""){
		var rtn=$.cm({
			ClassName:"DHCDoc.OPDoc.AjaxPatientAgentInfor",
			MethodName:"SavePatAddress",
			dataType:"text",
			PatientID:ServerObj.PatientID,
			PatAddress:PatAddress
		},false);
	//}
	//if (Weight!=""){
		var rtn=$.cm({
			ClassName:"web.UDHCPrescript",
			MethodName:"SaveWeight",
			dataType:"text",
			MRAdmID:ServerObj.mradm,
			Weight:Weight
		},false);
	//}
	$.messager.popover({msg: '保存信息成功!',type:'success'});
	destroyDialog("PatSupplyInfo");
}
function InitTextFile(OrderPrescNo) {
	LoadCredType();
	$.cm({
		ClassName:"web.DHCDocCheckPoison",
		MethodName:"GetSupplyMethod",
		dataType:"text",
		OrderPrescNo:OrderPrescNo,
		EpisodeID:ServerObj.EpisodeID
	},function(PatSupplyInfo){ 
		var PatSupplyInfoArr = PatSupplyInfo.split("^")
		$("#PatCredNo").val(PatSupplyInfoArr[0]);
		$("#SupplyName").val(PatSupplyInfoArr[1]);
		$("#SupplyCredNo").val(PatSupplyInfoArr[2]);
		$("#AgencyTel").val(PatSupplyInfoArr[3]);
		var AgencyCredTypeDr=PatSupplyInfoArr[4];
		if (AgencyCredTypeDr!=""){
			$("#AgencyCredType").combobox('select',AgencyCredTypeDr.replace("$","^"));
		}
		var PAPMIDCredTypeDr=PatSupplyInfoArr[5];
		if ((PAPMIDCredTypeDr!="")&&(PatSupplyInfoArr[0]!="")){
			$("#PAPMICredType").combobox('select',PAPMIDCredTypeDr.replace("$","^"));
		}
	});
	$.cm({
		ClassName:"DHCDoc.OPDoc.AjaxPatientAgentInfor",
		MethodName:"GetPatientAgentInfor",
		dataType:"text",
		EpisodeID:ServerObj.EpisodeID
	},function(PatSupplyInfo){ 
		if(PatSupplyInfo!=""){
			var PatSupplyInfoArr = PatSupplyInfo.split("^")
			$("#PatAddress").val(PatSupplyInfoArr[4]);
			$("#PatWeight").val(PatSupplyInfoArr[5])
		}
	});
}
function IsCredTypeID(id){
	var myval=$("#"+id).combobox("getValue");
	var myary = myval.split("^");
	if (myary[1]==m_IDCredTypePlate){
		return true;
	}else{
		return false;
	}
}
function LoadCredType(){
	var Data=$.m({
		ClassName:"web.UDHCOPOtherLB",
		MethodName:"ReadCredTypeExp",
		JSFunName:"GetCredTypeToHUIJson",
		ListName:""
	},false);
	var Data=JSON.parse(Data);
	var cbox = $HUI.combobox("#PAPMICredType,#AgencyCredType", {
			valueField: 'id',
			textField: 'text',
			blurValidValue:true, 
			editable:false,
			data:Data 
	 });
	 //默认证件类型为身份证
	 var selData=$("#PAPMICredType").combobox('getValue');
	 if (selData){
		 var code=selData.split("^")[1];
		 if (code!=m_IDCredTypePlate){
			 for (var i=0;i<Data.length;i++){
				 var id=Data[i].id;
				 if (id.split("^")[1]==m_IDCredTypePlate){
					 $("#PAPMICredType,#AgencyCredType").combobox('setValue',id);
				 }
			 }
		 }
	 }
}
function markPrintHistMenue(allOE){
	var title="";
	var OEItemID=opdoc.util.joinJsonPro(allOE, "^");
	if (OEItemID.split("^").length==0) return title;
	var jsonData = $.cm({
		ClassName:"DHCDoc.OPDoc.PrintHistory",
		MethodName:"GetPrintMenue",
		OEItemID:OEItemID
	},false);
	//jsonData={"CFD":true,"CFZ":true,"SYD":true}
	for ( var mv in jsonData) {
		if (menuItemValueMap[mv]){
			title=title+'<span class="printted-menu-title ' + mv
					+ '-style">' + menuItemValueMap[mv]["text"]
					+ '</span>';
		}
	}
	return title;
}
function indexOETableConfig(){
	if (!OETableConfig["Index"]) OETableConfig["Index"] = {};
	if (!OETableConfig["Index2"]) OETableConfig["Index2"] = {};
	var indexMap = OETableConfig["Index"];
	var tableConfig = OETableConfig["tableConfig"];
	for ( var tid in tableConfig) {
		var mc = tableConfig[tid]["menuOEConfig"];
		if (!mc) continue;
		for ( var mv in mc) {
			var oel = mc[mv];
			for ( var oe in oel) {
				if (!indexMap[oe]) {
					indexMap[oe] = {};
				}
				var oeConfig = indexMap[oe];
				oeConfig["tableId"] = tid;
				if (!menuItemValueMap[mv]) continue;
				oeConfig[mv] = !menuItemValueMap[mv]["ischecked"] ? 0 : 1;
				//如果已经打印过了，则按照未勾选处理
				if ((OETableConfig["tableConfig"][tid]["menuOEConfig"][mv])&&(OETableConfig["tableConfig"][tid]["menuOEConfig"][mv][oe]>=1)){
					oeConfig[mv] = 0;
				}
			}
		}
	}
	var momi = OETableConfig["Index2"];
	for ( var oe in indexMap) {
		for ( var mv in indexMap[oe]) {
			if (mv == "tableId")
				continue;
			if (!momi[mv]) {
				momi[mv] = {};
			}
			var temp = momi[mv];
			temp[oe] = true;
		}
	}
	return;
}
function tabledrawCallBack(){
	var menuItems = {};
	var tbox=$HUI.tree("#PrintItemTree");
	var $checkbox=$("[id$='_check']");
	for (var i = 0, len = $checkbox.length; i < len; ++i) {
		var ckId=$checkbox[i]["id"];
		if ($("#"+ckId).is(":checked")){
			var nodeId=ckId.split("_")[0];
			var tmpnode=tbox.find(nodeId);
			if (tmpnode["pId"]=="0") continue;
			menuItems[tmpnode["value"]] = tmpnode; 
		}
	}
	var $table=$("[id$='_TablePanle']");
	for (var i=0;i<$table.length;i++){
		var tableId=$table[i].id.split("_")[0];
		var selectConsistent=OETableConfig["tableConfig"][tableId+"_Table"]["selectConsistent"];
		//var db=$HUI.datagrid("#"+tableId+"_Table");
		var _$tab=$("#"+tableId+"_Table");
		var _$tr=_$tab.find("tbody tr");
		var _$ck=_$tab.find("div.cell-check input[type=checkbox]");
		var opts=_$tab.simplydatagrid("options");
		var appentitle=markPrintHistMenue(allOEArr[tableId+"_Table"],tableId+"_Table");
		if (appentitle!=""){
			/*var oldTitle=db.options().title;
			db.getPanel().panel('setTitle',oldTitle+appentitle)*/
			var oldTitle=opts.title;
			_$tab.simplydatagrid("setTitle",oldTitle+appentitle);
		}
		var IsCMPresType=0;
		/*if ($(db.getPanel().panel('header')).hasClass("cmpresc-head")){
			IsCMPresType=1;
		}*/
		if (_$tab.siblings(".cmpresc-head").length>0) {
			IsCMPresType=1;
		}
		var checkedRowCount=0;
		var data=_$tab.simplydatagrid("getRows"); //db.getData();
		for (var j=0;j<data.length;j++){
			var checked=false;
			for(var ind in menuItems){
				if (!OETableConfig["tableConfig"][tableId+"_Table"]["menuOEConfig"][ind]) continue;
				if (OETableConfig["tableConfig"][tableId+"_Table"]["menuOEConfig"][ind][data[j]["OEItemID"]]==0){
					//db.selectRow(j);
					_$tab.simplydatagrid("checkRow",j);
					checked=true;
				}
			}
			if (checked) checkedRowCount=checkedRowCount+1;
			//if (data.rows[j]["PrintFlag"]) {
			if (data[j]["PrintFlag"]) {
				//db.getPanel().find('input[type="checkbox"]')[j+1].disabled=true;
				_$ck[j].disabled=true;
			}
			if ((IsCMPresType==1)&&(j>0)){
				//隐藏草药行
				//$(db.getPanel().find('tr')[j+1]).addClass('tr-hide');
				$(_$tr[j]).addClass('tr-hide');
			}
		}
		if (checkedRowCount==data.length) {
			var hck=_$tab.find(".datagrid-header-row input[type=checkbox]");
			hck._propAttr("checked", true);
		}
		if(selectConsistent) {
			opts.checkOnSelect=false; //控制选中行不进行勾选
			//db.options().checkOnSelect=false; //控制选中行不进行勾选
		}
	}
	$("#printItemIframeTemplate .panel-header").on({
		mouseenter:function(){
			var thisWidth = $(this).width(); // div 的宽度
			var wordWidth = $(this).children()[0].scrollWidth; // 先转为js对象; 文字的宽度
			if(wordWidth <= thisWidth){
				return;
			}
			$(this).webuiPopover({
				width:$(this).width(),
				content:function(){ 
					return $(this).children()[0].innerHTML;
				},
				trigger:'hover',
				placement:'bottom',
				cache:false
			});
			$(this).webuiPopover('show');
		}
	});
}
function preview(){
	$.ajax("opdoc.treatprintpreview.csp"+((typeof websys_getMWToken=='function')?("?MWToken="+websys_getMWToken()):""), {
		"type" : "GET",
		"dataType" : "html",
		"async": false,
		"success" : function(data, textStatus) {
			var $code = $(data);
			createModalDialog("PrintDataPreView",$g("打印数据预览"), 800, dh,"icon-w-print",$g("打印"),$(data),"print('Y')",true);
			prepareHandle(renderPrivewPanel,"PreView");
			$("input[id*='-CK']").click(function(e){
				var ckId=e.target.id;
				var $ck=$("#"+ckId);
				var listRowId=$ck.attr("listRowId");
				var checkFlag=$ck.is(':checked');
				if (checkFlag){
					needPrintConfig["selectedListRowId"][listRowId]=true;
				}else{
					delete needPrintConfig["selectedListRowId"][listRowId];
				}
				var type=ckId.split("-")[0];
				if ((type=="DZD")||(type=="SYDO")||(type=="ZSDO")||(type=="JYDO")){
					for (var i=0;i<$("input[id*='"+type+"-CK']").length;i++){
						var id=$("input[id*='"+type+"-CK']")[i].id;
						if (id!=ckId){
							if (checkFlag) {
								$("#"+id).prop("checked",true);
							}else{
								$("#"+id).prop("checked",false);
							}
						}
					}
				}else if(type=="BLDMZ"){
					for (var i=0;i<$("input[id*='"+type+"-CK']").length;i++){
						var id=$("input[id*='"+type+"-CK']")[i].id;
						var listrowid=$("#"+id).attr("listrowid");
						if (listRowId==$("#"+id).attr("listrowid")){
							if (checkFlag) {
								$("#"+id).prop("checked",true);
							}else{
								$("#"+id).prop("checked",false);
							}
						}
					}
				}
			});
			var printers=opdoc.print.common.getPrinterList();
			var arr=[];
			for(var ind in printers){
				if ((!printers[ind])||(printers[ind]=="")||($.type(printers[ind]) === "function")) continue;
				arr.push({"name":printers[ind].split(",")[0]});
			}
		},
		"error" : function(XMLHttpRequest, textStatus, errorThrown) {
			console.log(textStatus);
		}
	});
}
function checkLocType(){
	var CTLocPrintTypeID=$.cm({
		ClassName:"DHCDoc.OPDoc.TreatPrint",
		MethodName:"CheckLocType",
		dataType:"text",
		episodeID:ServerObj.EpisodeID
	},false);
	if (CTLocPrintTypeID==1){
		var PatWeight="";
		var PatSupplyInfo=$.cm({
			ClassName:"DHCDoc.OPDoc.AjaxPatientAgentInfor",
			MethodName:"GetPatientAgentInfor",
			dataType:"text",
			EpisodeID:ServerObj.EpisodeID
		},false);
		if(PatSupplyInfo!=""){
			var PatSupplyInfoArr = PatSupplyInfo.split("^");
			PatWeight=PatSupplyInfoArr[5];
		}
		if (PatWeight==""){
			$.messager.alert("提示","儿科必须填写体重!","info",function(){
				imgpreview();
			})
			return false;
		}
	}
	return true;
}
function print(printFlag){
	if (printFlag=="EMR"){
		$("#framePrintList")[0].contentWindow.printDocument();
		//window.frames["framePrintList"].printDocument();
		printFlag="Y";
	}else{
		var rtn=prepareHandle(function(options,isArray){
			if (options["node"]["value"]=="MZBL"){
				if ($("#PrintDataPreView").length==0){
					printFlag="N";
					onlyPreviewMZBL();
				}else{
					$("#framePrintList")[0].contentWindow.printDocument();
				    //window.frames["framePrintList"].printDocument();
				}
			}else{
				if(isArray){
					options["ReadyJson"]=options["ReadyJson"]["data"];
				}
				var pd=null;
				if(printDeviceCom && (pd=printDeviceCom.getSelected())){
					options["printDevice"]=pd["name"];
				}
				if($paperSize  && $paperSize.val()){
					options["paperSize"]=$paperSize.val()
				}
				//options["printCopies"]=$printCopies!=null?$printCopies.val()||1:1;
				options["printCopies"]=1;
				opdoc.print.common.print(options);
				var rtn=$.cm({
					ClassName:"DHCDoc.OPDoc.PrintHistory",
					MethodName:"Record",
					dataType:"text",
					oeList:opdoc.util.joinJsonPro(needPrintConfig["selectedOE"]),
					menuOERalation:opdoc.util.expandJsonHor(needPrintConfig["menuOEMap"]), 
					operator:"NULL",
					selectedListRows:opdoc.util.joinJsonPro(needPrintConfig["selectedListRowId"],"^")
				},false);
			}
			
		},"Print",printFlag);
	}
	if (printFlag=="Y"){
		if (rtn!=false){
			needPrintConfig={}; //打印之后清空需要打印配置
			destroyDialog('PrintDataPreView');
			loadOrdTableData();
			if (parent.window.CompleteRecAdm) {
				parent.window.CompleteRecAdm();
			}else if(parent.window.PrintAllAfterClick){
				parent.window.PrintAllAfterClick();
			}
		}
	}
}
var dw=$(window).width()-100,dh=$(window).height()-50;
function createModalDialog(id, _title, _width, _height, _icon,_btntext,_content,_event,closable){
	if(_btntext==""){
	   var buttons="";
   }else{
	   var buttons=[{
			text:_btntext,
			iconCls:_icon,
			handler:function(){
				if(_event!="") eval(_event);
			}
		}]
   }
   if(!$('#'+id).size()){
    	$("body").append("<div id='"+id+"' class='hisui-dialog'></div>");
   }
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
        collapsible: false,
        minimizable:false,
        maximizable: false,
        resizable: false,
        modal: true,
        closed: false,
        closable: closable,
        content:_content,
        buttons:buttons,
        onClose:function(){
	        destroyDialog(id);
	    }
    });
}
function destroyDialog(id){
	try{
		$("#"+id).dialog('close');
	}catch(e){
	}
	return
   $("body").remove("#"+id); //移除存在的Dialog
   $("#"+id).dialog('destroy');
}
var needPrintConfig={};
function prepareHandle(callBack,type,printFlag){
	needPrintConfig=getNeedPrint();
	if ($.isEmptyObject(needPrintConfig["selectedOE"])){
		if (!needPrintConfig["menuNodes"]["MZBL"]){
			$.messager.alert("提示","请选择医嘱!");
			if (type=="PreView") {
				$("#PrintDataPreView").dialog('close');
			}
			return false;
		}
	}
	if (type=="Print"){
		if ((needPrintConfig["menuNodes"]["CFD"])||(needPrintConfig["menuNodes"]["CFZ"])){
			if (!checkLocType()) {
				//needPrintConfig={}; 
				return false;
			}
		}
	}
	/*var CMtemplateId=$.cm({
		ClassName:"web.DHCDocPrescript",
		MethodName:"GetXMLTemplateId",
		dataType:"text",
		XMLTemplateName:"DHCOutPrescCY" //草药处方xml模板
	},false);*/
	for(var mv in needPrintConfig["menuNodes"]){
		var menuNode=needPrintConfig["menuNodes"][mv];
		var noeValue=menuNode['value'];
		var printmethod=menuNode['printmethod'];
		if (noeValue!="MZBL"){
				if ((type=="PreView")||(printFlag=="N")) { //printFlag 为N代表 是直接点击打印按钮弹出病历界面
					//needPrintConfig["selectedListRowId"]={};
					var printmethod=resolveConfigMethod(menuNode["printmethod"],menuNode,needPrintConfig["menuOEMap"][mv],{},type);
				}else{
					var printmethod=resolveConfigMethod(menuNode["printmethod"],menuNode,needPrintConfig["menuOEMap"][mv],needPrintConfig["selectedListRowId"],type);
				}
				if(printmethod==null) continue;
				var argN=0,a=0;
				for(var a in printmethod["args"]){
					argN=argN+1;
				}
				//配置xml对应ID
				var tempId=$.cm({
					ClassName:"web.DHCDocPrescript",
					MethodName:"GetXMLTemplateId",
					dataType:"text",
					XMLTemplateName:menuNode["previewxmlname"]
				},false);
				var options={
					node:menuNode,
					"templateId":tempId
				};
				$.ajax("opdoc.request.method.csp"+((typeof websys_getMWToken=='function')?("?MWToken="+websys_getMWToken()):""),{
					type : "POST",
					dataType:"JSON",
					async: false, //此处必须设置为同步，否则预览标题与正文不符
					data:opdoc.util.genQueryArg({
						ClassName : printmethod["class"],//"DHCDoc.OPDoc.TreatPrint",
						MethodName : printmethod["method"]//"PrintOrder"
					}, argN, printmethod["args"]),
					success:function(respData) {
						respData=respData["result"];
						if($.type(respData) === "array"){
							for(var i=0,len=respData.length;i<len;++i){
								if(respData[i]["listRowId"]==undefined){
									console.log("when return array each item must be set listRowId value!");
									return;
								}
								var Onepagenum=1;
								options["ReadyJson"]=respData[i];
							    //若后台返回的xml模板名不为空,则根据返回模板展示
								if ((respData[i]["templateId"]!="")&&(respData[i]["templateId"]!=undefined)){
									options["templateId"]=respData[i]["templateId"];
								}else if ((respData[i]["PrintTemp"]!="")&&(respData[i]["PrintTemp"]!=undefined)){
									var JsontempId=$.cm({
										ClassName:"web.DHCDocPrescript",
										MethodName:"GetXMLTemplateId",
										dataType:"text",
										XMLTemplateName:respData[i]["PrintTemp"]
									},false);
									options["templateId"]=JsontempId;
								}else{
									options["templateId"]=tempId;
								}
								if (options['node']['value'].indexOf("CF")>=0){
									if (respData[i]["PrintTemp"].indexOf("Ver")<0){
										var Onepagenum=12; //处方打印一页打印行数
									}else{
										var Onepagenum=16;
									}
								}
								
								options["printPageNums"]=Onepagenum;
								callBack(options,true); //renderPrivewPanel
							}
						}else{
							options["ReadyJson"]=respData;
							callBack(options,false);
						}
						
					},
					error:function(XMLHttpRequest, textStatus, errorThrown) {
						console.log(XMLHttpRequest);
					}
				});
		}else{
			var urlObject=menuNode['urlObject'];
			var urlStyle=menuNode['urlStyle'];
			if (urlStyle=="iframe"){
				var InstancePrintedStatus=GetInstancePrintedStatus();
				if (JSON.parse(InstancePrintedStatus).hasNoPrinted==0){
					if (Object.keys(needPrintConfig["menuNodes"]).length==1) {
						$.messager.alert("提示","没有需要打印的病历,请核实病历是否签名或已打印!");
						if (type=="PreView") {
							$("#PrintDataPreView").dialog('close');
						}
						return false;
					}
					continue;
				}
				var newurl=replaceLinkParams(urlObject);
				var options={
					node:menuNode,
					newurl:newurl,
					ReadyJson:{"listRowId":ServerObj.EpisodeID+"_"+menuNode['value'],"checkTitle":''}
				};
				callBack(options,true); 
			}
		}
		//
	}
}
function getNeedPrint() {
	var menuItems = {};
	var selectedOE = {};
	var temp = {};
	var tbox=$HUI.tree("#PrintItemTree");
	var $checkbox=$("[id$='_check']");
	for (var i = 0, len = $checkbox.length; i < len; ++i) {
		var ckId=$checkbox[i]["id"];
		if ($("#"+ckId).is(":checked")){
			var nodeId=ckId.split("_")[0];
			var tmpnode=tbox.find(nodeId);
			if (tmpnode["pId"]=="0") continue;
			menuItems[tmpnode["value"]] = tmpnode; 
			temp[tmpnode["value"]] = {};
		}
	}
	var tableConfig = OETableConfig["tableConfig"];
	for ( var tid in tableConfig) {
		if ($("#"+tid).length==0) continue;
		//var db=$HUI.datagrid("#"+tid);
		//var selData=db.getChecked();
		var _$tab=$("#"+tid);
		var selData=_$tab.simplydatagrid("getChecked");
		for (var i=0;i<selData.length;i++){
			var oeId=selData[i]["OEItemID"];
			for ( var mv in OETableConfig["Index"][oeId]) {
				if (mv == "tableId") continue;
				if (temp[mv]) {
					temp[mv][oeId] = true;
				}
			}
			selectedOE[oeId] = true;
		}
	}
	return {
		"menuNodes" : menuItems,
		"selectedOE" : selectedOE,
		"menuOEMap" : temp,
		"selectedListRowId" : !$.isEmptyObject(needPrintConfig["selectedListRowId"])?needPrintConfig["selectedListRowId"]:{}
	};
}
function resolveConfigMethod(configMethod,node,oeList,selectedListRows,type){
	if(!configMethod) return null;
	var i=configMethod.indexOf("?");
	var fullName=configMethod.substring(0,i==-1?configMethod.length:i);
	var paramMethod=i==-1?null:configMethod.substring(i+1);
	i=fullName.lastIndexOf(".");
	if(i==-1) return null;
	return {
		"class":fullName.substring(0,i),
		"method":fullName.substring(i+1),
		"args":paramMethod!=null?eval((paramMethod+"(node,oeList,selectedListRows,type)")):{}
	}
}
function prescriptPrintDataArgs(node,selectedOE,selectedListRows,type){
	return {
		"Arg1":ServerObj.EpisodeID,
		"Arg2":opdoc.util.joinJsonPro(selectedOE),
		"Arg3":opdoc.util.joinJsonPro(selectedListRows,"^"),
		"Arg4":node["value"],
		"Arg5":type,
		"Arg6":$("#StDate").datebox('getValue'),
		"Arg7":$("#EndDate").datebox('getValue')
	};
}
function renderPrivewPanel(options){
	var $panel=$("#previewObjectTemplate");
	var $temp=$("#previewPanelTemp").clone();
	$temp.removeAttr("id");
	$temp.removeAttr("style");
	var PanelId=opdoc.util.genEleNewId(options["node"]["value"]+"_Panel");
	$temp.attr("id",PanelId);
	$panel.append($temp);
	var ckId=opdoc.util.genEleNewId(options["node"]["value"]+"-CK");
	var PanelTitle="<input class='hisui-checkbox' listRowId='"+options["ReadyJson"]["listRowId"]+"' checked type='checkbox' id='"+ckId+"'>";
	PanelTitle=PanelTitle+options["node"]["text"]+(!options["ReadyJson"]["checkTitle"]?"":options["ReadyJson"]["checkTitle"]);
	var width=(HISUIStyleCode=="lite")?773:765		//极简和炫彩宽度医政，但效果不一样(应有基础平台统一)
	$('#'+PanelId).panel({
		width:width,
		title: PanelTitle,
		headerCls:'panel-header-gray',
		bodyCls:"preview-panel"
	});
	var PrescBgColor=!options["ReadyJson"]["PrescBgColor"]?"":options["ReadyJson"]["PrescBgColor"];
	if (PrescBgColor) {
		$('#'+PanelId).prev().css("background",PrescBgColor);
		$('#'+PanelId).css("background",PrescBgColor);
	}
	needPrintConfig["selectedListRowId"][options["ReadyJson"]["listRowId"]]=true;
	options["$targetPanel"]=$temp;
	if (options["node"]["value"]=="MZBL"){
		$("input[id^='MZBL-CK']").prop('disabled',true);
		$temp.height(790);
		var url=(typeof websys_writeMWToken=='function')?websys_writeMWToken(options["newurl"]):options["newurl"];
		$temp.append('<iframe id="framePrintList" src="'+url+'" width="100%" height="100%"'+
                     'marginheight="0" marginwidth="0" scrolling="no" align="middle" ></iframe>');
	}else{
		options["ReadyJson"]=options["ReadyJson"]["data"];
		opdoc.print.common.preview(options);
	}
	//$HUI.checkbox("input.hisui-checkbox",{})
}
function getAge(pId){
	var id=String(pId);
    if (id.length==18){
	    var myMM=(id.slice(10,12)).toString();
	    var myDD=id.slice(12,14).toString();
	    var myYY=id.slice(6,10).toString();
    }else{
	    var myMM=(id.slice(8,10)).toString();
	    var myDD=id.slice(10,12).toString();
	    var myYY=id.slice(6,8).toString();
		if(parseInt(myYY)<10)	{
			myYY = '20'+myYY;
		}else{
			myYY = '19'+myYY;
		}	    
    }
    var myMM=myMM.length==1?("0"+myMM):myMM;
    var myDD=myDD.length==1?("0"+myDD):myDD;
    var birthday=myYY+"-"+ myMM +"-"+myDD;
    var myAge="";
	var bage=birthday;
	bage=bage.substring(0,4);
	var now = new Date();
    var yy = now.getFullYear();
	var myAge=yy-bage;
	return myAge;
}
function CheckTelOrMobile(telephone,Name,Type){
	if (DHCC_IsTelOrMobile(telephone)) return true;
	if (telephone.indexOf('-')>=0){
		$.messager.alert("提示",Type+",固定电话长度错误,固定电话区号长度为【3】或【4】位,固定电话号码长度为【7】或【8】位,并以连接符【-】连接,请核实!","info",function(){
			$("#"+Name).focus();
		})
        return false;
	}else{
		if(telephone.length!=11){
			$.messager.alert("提示",Type+",长度应为【11】位,请核实!","info",function(){
				$("#"+Name).focus();
			})
	        return false;
		}else{
			$.messager.alert("提示",Type+",不存在该号段的手机号,请核实!","info",function(){
				$("#"+Name).focus();
			})
	        return false;
		}
	}
	return true;
}
function LoadEMRInfo(){
	$("#EMRInfo").empty();
    var EMRTabName=GetEMRTabName();
    if(!EMRTabName){
		$("#EMRInfo").hide();
		return;
	}
	$.cm({
		ClassName:"EMRservice.HISInterface.BOExternal",
		MethodName:"GetSavedInstanceByEpisodeID",
		AEpisodeID:ServerObj.EpisodeID
	},function(Data){
		if(!Data.length){
			$("#EMRInfo").html('<div class="emr-warn" onclick="GoEMRSignTab()">'+$g("未检索到病历信息,请先保存病历!")+'</div>');
			return;
		}
		$.each(Data,function(index,row){
			var $btn=$('<a></a>').css('width','75px').linkbutton({
				text:row.IsSigned=='1'?$g("已签名"):$g("签名"),
				disabled:row.IsSigned=='1',
				stopAllEventOnDisabled:true,
				onClick:function(){
					GoEMRSign(row.InstanceId,row.CategoryName);
				}
			});
			$('<div class="emr-item"></div>').append($btn).append('<span class="emr-title">'+row.Text+'</span>').appendTo('#EMRInfo');
		});
	})
}
function GetScatterData(InstanceId){
	var url="emr.browse.html.csp?actType=test&instanceId="+InstanceId;
	websys_showModal({
		iconCls:'icon-w-list',
		url:url,
		title:$g("病历预览"),
		width:950,
		height:800
	});
	return;
}

function GoEMRSign(InstanceID,CategoryName){
	if(ServerObj.PAAdmType=='O') CategoryName="";
	return  GoEMRSignTab({InstanceID:InstanceID},CategoryName);

	var url="emr.interface.ip.main.csp?InstanceID="+InstanceID+"&EpisodeID="+ServerObj.EpisodeID;
	var width="95%"; //document.body.clientWidth;
	var height="95%"; //document.body.clientHeight;
	websys_showModal({
		iconCls:'icon-w-list',
		url:url,
		title:$g("病历浏览"),
		width:width,
		height:height,
		onClose:function(){
			LoadEMRInfo();
		}
	});
	return;
}

function GoEMRSignTab(cfg,EMRTabName){
	if(!EMRTabName){
		var EMRTabName=GetEMRTabName();
		if(!EMRTabName){
			$.messager.alert("提示",$g("未设置病历菜单!"))
			return;
		}
	}
	parent.switchTabByEMR(EMRTabName,cfg);
}

function GetEMRTabName(){
    var EMRTabName="";
    var EMRTabArr=['门诊病历','门急诊病历记录']; 
    var DefaultTab="";
    if(parent.$('#menuStep').length>0){
        var data=parent.$('#menuStep').marystep('getData');
        for(var i=0;i<data.length;i++){
            var menuTitle=data[i].text;
            if($.inArray(menuTitle,EMRTabArr)>-1){
                EMRTabName=menuTitle
                break;
            }
            if((DefaultTab=="")&&(menuTitle.indexOf('病历')>-1)){
                DefaultTab=menuTitle
            }
        }
    }else if(parent.$("#menuGroupReg").length>0){
        parent.$("#menuGroupReg ul.i-menugroup li a").each(function(){
            var menuItemHtml = $(this).html();
            var menuTitle = menuItemHtml.split("<span")[0];
            menuTitle=$.trim(menuTitle);
            if($.inArray(menuTitle,EMRTabArr)>-1){
                EMRTabName=menuTitle
                return false;
            }
            if((DefaultTab=="")&&(menuTitle.indexOf('病历')>-1)){
                DefaultTab=menuTitle
            }
        })
    }
    EMRTabName=EMRTabName?EMRTabName:DefaultTab;
    return EMRTabName;
}

function LoadDiagnosInfo(){
	$.cm({
		ClassName:"web.DHCMRDiagnos",
		MethodName:"GetMRDiagnosDesc",
		dataType:"text",
		MRAdmRowid:ServerObj.mradm, DelimStr:";"
	},function(diagnodesc){
		$("#DiagnosInfo").html($g("诊断: ")+diagnodesc);
	});
}
function ordDetailInfoShow(OrdRowID){
		websys_showModal({
			url:"dhc.orderdetailview.csp?ord=" + OrdRowID,
			title:'医嘱明细',
			iconCls:'icon-w-list',
			width:400,
			height:screen.availHeight-200
		});
}
function OpenReportLink(){
	var ReportLinkInfoArr=ReportLinkInfo.split("!");
	var ReportType=ReportLinkInfoArr[0];
	var Param=ReportLinkInfoArr[1];
	if (ReportType=="L"){
		var src="jquery.easyui.dhclabreport.csp?VisitNumberReportDR=" + Param;
		if(typeof websys_writeMWToken=='function') src=websys_writeMWToken(src);
		var $code ="<iframe width='99%' height='99%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
		createModalDialog("ReportLink",$g("检验报告结果"), $(window).width()-400, $(window).height()-100,"icon-write-order","",$code,"",true);
	}else if (ReportType=="Ris") {
			$.cm({
			ClassName:"web.DHCRisCommFunctionEx",
			MethodName:"GetReportUrl",
			oeorditemdr:ReportLinkInfoArr[1], StudyNo:ReportLinkInfoArr[2], UserID:session['LOGON.USERID']
		},function(RptParm){
			if (RptParm!=""){
				var Item=RptParm.split(":")
			    if (Item[0]=="http"){
					if(typeof websys_writeMWToken=='function') RptParm=websys_writeMWToken(RptParm);
				    var $code ="<iframe width='99%' height='99%' scrolling='auto' frameborder='0' src='"+RptParm+"'></iframe>" ;
					createModalDialog("ReportLink",$g("检查报告结果"), $(window).width()-400, $(window).height()-100,"icon-write-order","",$code,"",true);
			    }else{
				 	var curRptObject = new ActiveXObject("wscript.shell");
					curRptObject.run(RptParm);
			    }
			}
		})
	}
}
function ordWaitCancel(tabId,OrdRowID){
	var _$id=$("#"+tabId+"-"+OrdRowID.split("||")[1]);
	var text=_$id[0].innerHTML;
	var _$tab=$("#"+tabId);
	//var index=_$tab.datagrid('getRowIndex',OrdRowID);
	//var OrdBilled=_$tab.datagrid('getRows')[index]['OrdBilled'];
	var index=_$tab.simplydatagrid("getRowIndex",OrdRowID); 
	var OrdBilled=_$tab.simplydatagrid('getRows')[index]['OrdBilled'];
	if (text==$g("待撤销")){
		var newOrdBilled=waitCancelOEArr[OrdRowID];
		delete waitCancelOEArr[OrdRowID];
		_$id.removeClass("waitbillccancel");
	}else{
		var newOrdBilled=$g("待撤销");
		_$id.addClass("waitbillccancel");
		waitCancelOEArr[OrdRowID]=OrdBilled;
	}
	_$id[0].innerHTML=newOrdBilled;
}
function CancelOrdClick(){
	var OrdListArr=new Array();
	for ( var oe in waitCancelOEArr) {
		if (oe.indexOf("||")>=0){
			OrdListArr.push(oe);
		}
	}
	if (OrdListArr.length==0){
		$.messager.alert("提示","没有需要撤销的医嘱!");
		return false;
    }
    var OrdListStr=OrdListArr.join("^");
    var rtn=$.m({
	    ClassName:"web.DHCDocInPatPortalCommon",
	    MethodName:"CheckMulOrdDealPermission",
	    OrderItemStr:OrdListStr,
	    date:"",
	    time:"",
	    type:"C",
	    ExpStr:session['LOGON.USERID']+"^"+session['LOGON.CTLOCID']+"^"+session['LOGON.GROUPID']+"^^"
	},false);
    if (rtn!=0){
	   $.messager.alert("提示",rtn);
	   return false;
    }
    ShowInputPinNum();
    function ShowInputPinNum(){
	    $.messager.prompt('提示', '请输入密码', function(PinNum){
			if ((PinNum!="")&&(PinNum!=undefined)){
				var ExpStr=session['LOGON.USERID']+"^"+session['LOGON.CTLOCID']+"^"+session['LOGON.GROUPID']+"^^";
				$.m({
					ClassName:"web.DHCDocInPatPortalCommon",
				    MethodName:"MulOrdDealWithCom",
				    OrderItemStr:OrdListStr,
				    date:"",
				    time:"",
				    type:"C",
				    pinNum:PinNum,
				    ExpStr:ExpStr
				},function(rtn){ 
					var rtnCode=rtn.split("^")[0];
					if (rtnCode==0){
						$.messager.popover({msg: '撤销医嘱成功!',type:'success'});
						waitCancelOEArr=[];
						loadOrdTableData();
						SaveOrderToEMR();
					}else{
						if (rtn.indexOf("密码")>=0){
							$.messager.alert("提示","撤销医嘱失败!密码错误!","info",function(){
								ShowInputPinNum();
							});
						}else{
							$.messager.alert("提示","撤销医嘱失败!"+rtn);
						}
					}
				})
			}
			if (PinNum==""){
				$.messager.alert("提示","请输入密码!","info",function(){
					ShowInputPinNum();
				});
				return false;
			}
	    });
		$(".messager-input").focus();
		$(".messager-input")[0].type="password";
	}
}
function selAllChange(value){
	var indexMap = OETableConfig["Index"];
	for ( var oe in indexMap) {
		var $tab=$("#"+indexMap[oe]["tableId"]);
		if (value){
			$tab.simplydatagrid("checkAll");
		}else{
			$tab.simplydatagrid("uncheckAll");
		}
	}
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
function onlyPreviewMZBL(){
	$.ajax("opdoc.treatprintpreview.csp"+((typeof websys_getMWToken=='function')?("?MWToken="+websys_getMWToken()):""), {
		"type" : "GET",
		"dataType" : "html",
		"async": false,
		"success" : function(data, textStatus) {
			var $code = $(data);
			createModalDialog("PrintDataPreView","打印数据预览", 800, dh,"icon-w-print","打印",$(data),"print('EMR')",true);
			$("#PrintDataPreView").dialog('options').closable=false;
			var tbox=$HUI.tree("#PrintItemTree");
			var $checkbox=$("[id$='_check']");
			for (var i = 0, len = $checkbox.length; i < len; ++i) {
				var ckId=$checkbox[i]["id"];
				if ($("#"+ckId).is(":checked")){
					var nodeId=ckId.split("_")[0];
					var tmpnode=tbox.find(nodeId);
					if (tmpnode["pId"]=="0") continue;
					if (tmpnode["value"]=="MZBL"){
						var urlStyle=tmpnode['urlStyle'];
						var urlObject=tmpnode['urlObject'];
						if (urlStyle=="iframe"){
							var InstancePrintedStatus=GetInstancePrintedStatus();
							if (JSON.parse(InstancePrintedStatus).hasNoPrinted==0){
								if (Object.keys(needPrintConfig["menuNodes"]).length==1) {
									$.messager.alert("提示","没有需要打印的病历,请核实病历是否签名或已打印!");
									$("#PrintDataPreView").dialog('close');
									break;
								}
								break;
							}
							var newurl=replaceLinkParams(urlObject);
							var options={
								node:tmpnode,
								newurl:newurl,
								ReadyJson:{"listRowId":ServerObj.EpisodeID+"_"+tmpnode['value'],"checkTitle":''}
							};
							renderPrivewPanel(options,true); 
						}
						break;
					}
				}
			}
		},
		"error" : function(XMLHttpRequest, textStatus, errorThrown) {
			console.log(textStatus);
		}
	});
}
function GetInstancePrintedStatus(){
	var InstancePrintedStatus=$.cm({
		ClassName:"EMRservice.HISInterface.HisData",
		MethodName:"GetInstancePrintedStatus",
		dataType:"text",
		AEpisodeID:ServerObj.EpisodeID
	},false);
	return InstancePrintedStatus;
}
function SaveOrderToEMR(){
	var CMOrdList = tkMakeServerCall("EMRservice.BL.opInterface", "getOeordXH", ServerObj.EpisodeID,"CHMED")
	var OrdList = tkMakeServerCall("EMRservice.BL.opInterface", "getOeordXH", ServerObj.EpisodeID)
	if (typeof(parent.invokeChartFun) === 'function') {
	    parent.invokeChartFun('门诊病历', 'updateEMRInstanceData', "oeord", OrdList,function(){
		    
		    parent.invokeChartFun('门诊病历', 'updateEMRInstanceData', "oeordCN", CMOrdList,"",ServerObj.EpisodeID);
		},ServerObj.EpisodeID);
	    parent.invokeChartFun('门急诊病历记录', 'updateEMRInstanceData', "oeord", OrdList,"",ServerObj.EpisodeID);
	}
    return OrdList;
}
function PrescLinkDiagClick(tableId){
	var prescNo=tableId.split("_")[0];
	var url="dhcdocdiagnoseselect.hui.csp?EpisodeID="+ServerObj.EpisodeID+"&PrescNoStr="+prescNo+"&ExitFlag="+"Y";
	websys_showModal({
		iconCls:'icon-w-list',
		url:url,
		title:prescNo+$g("关联诊断"),
		width:"95%",    //$(window).width()-150,
		height:$(window).height()-50
	});
}
function ChangeTreeCheck(value) {
	var Childrens = $HUI.tree("#PrintItemTree").getChildren();
	for ( var i = 0; i < Childrens.length; i++) {  
		if (Childrens[i].children!=undefined) continue  //查找子节点
		var $checkId=$("#"+ Childrens[i].id+"_check");
		$checkId.prop("checked",value);	
		TreeOnCheck("",Childrens[i].id);
	} 
	return;
}
function initDiagDivHtml(ShowType){
	var html="";
	var Obj={"ShowType":ShowType};
		   	
	$.ajax("opdoc.treatprintpresc.csp"+((typeof websys_getMWToken=='function')?("?MWToken="+websys_getMWToken()):""),{
		type : "POST",
		dataType:"html",
		async: false, 
		data:Obj,
		success:function(data) {
			debugger
			html=data.replace(/\r\n/g,"");
		},
		"error" : function(XMLHttpRequest, textStatus, errorThrown) {
			console.log(textStatus);
		}
	})
	return html
}
