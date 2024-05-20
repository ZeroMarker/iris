// chenhongliang
```js
function preview(message, event){
	$.ajax("opdoc.treatprintpreview.csp"+((typeof websys_getMWToken=='function')?("?MWToken="+websys_getMWToken()):""), {
		"type" : "GET",
		"dataType" : "html",
		"async": false,
		"success" : function(data, textStatus) {
			var $code = $(data);
			createModalDialog("PrintDataPreView",$g("处方预览"), 800, dh,"icon-w-print",message,$(data),event,true);
			prepareHandle(renderPrivewPanel,"PreView");

			// Get the element by its ID
			const toMove = document.getElementById(PageLogicObj.PanelId);
			// Check if the element exists
			if (toMove) {
			  // Get the previous sibling
			  const previousSibling = toMove.previousElementSibling;

			  // Check if there is a previous sibling
			  if (previousSibling) {
			    // Move the div with the specified ID inside the previous sibling
			    previousSibling.appendChild(toMove);
			  } else {
			    console.error('No previous sibling found');
			  }
			} else {
			  console.error('Element with ID ' + childIdToMove + ' not found');
			}
		},
		"error" : function(XMLHttpRequest, textStatus, errorThrown) {
			console.log(textStatus);
		}
	});
}
var needPrintConfig={};
function prepareHandle(callBack,type,printFlag){
	needPrintConfig=getNeedPrint();
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
	
	var ids = PageLogicObj.OrdItemIDs.split('*V^');
	ids = ids.filter(item => item != "");
	var out = [];
	ids.forEach(item => {
		const ele = item.split('*')[1];
		out.push(ele);
	});
	const ord = {};
	for (const value of out) {
    	ord[value] = true;
	}
	var PrescNo = tkMakeServerCall("web.DHCDocMain","GetPrescNoByOrdItem",out[0]);
	PrescNo = PrescNo + "CFZ";
	/*return {
		"menuNodes" : menuItems,
		"selectedOE" : selectedOE,
		"menuOEMap" : temp,
		"selectedListRowId" : !$.isEmptyObject(needPrintConfig["selectedListRowId"])?needPrintConfig["selectedListRowId"]:{}
	};*/
	return {
    "menuNodes": {
        "CFZ": {
            "id": "3",
            "text": "处方【正】",
            "state": "open",
            "pId": "1",
            "checked": false,
            "ischecked": true,
            "nocheck": true,
            "expandMethodForLoadingTable": "",
            "urlObject": "",
            "clickevent": "",
            "value": "CFZ",
            "urlStyle": "",
            "previewxmlname": "DHCOutPrescXYPrt",
            "printmethod": "DHCDoc.OPDoc.TreatPrint.PrescriptPrintData?prescriptPrintDataArgs",
            "domId": "_hisui_tree_2",
            "target": {}
        }
    },
    "selectedOE": ord,
    "menuOEMap": {
        "CFZ": ord
    },
    "selectedListRowId": {
        PrescNo: true
    }
}

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
		"Arg6":new Date,
		"Arg7":new Date
	};
}
function renderPrivewPanel(options){
	var $panel=$("#previewObjectTemplate");
	var $temp=$("#previewPanelTemp").clone();
	$temp.removeAttr("id");
	$temp.removeAttr("style");
	var PanelId=opdoc.util.genEleNewId(options["node"]["value"]+"_Panel");
	$temp.attr("id",PanelId);
	PageLogicObj.PanelId = PanelId;
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
	options["ReadyJson"]=options["ReadyJson"]["data"];
	opdoc.print.common.preview(options);
	//$HUI.checkbox("input.hisui-checkbox",{})
}
```