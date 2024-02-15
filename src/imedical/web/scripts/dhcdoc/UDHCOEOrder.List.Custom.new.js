var e = window.event;
var PageLogicObj = {
    m_version: 8.1,
    m_ObjectTypeS: "",
    //医嘱增加到页面的方式:别名录入(LookUp),医嘱套/复制医嘱(ARCOS),医嘱常用(Usage)
    m_AddItemToListMethod: "LookUp",
    defaultDataGridtop: 0,
    //医嘱开始日期的默认日期格式: "3" 代表YYYY-MM-DD 或者 "4" 代表DD/MM/YYYY;默认为:DD/MM/YYYY
    defaultDataCache:"",
    FocusRowIndex: 0,
    isComboEnable: true,
    DefaultPilotProRowid : "",
    DefaultPilotProDesc:"",
    NotEnoughStockFlag:0,
    //是否是在医嘱录入输入别名弹出的检索数据框里选择数据行
    EntrySelRowFlag:0,
    SearchName:"",
    IsStartOrdSeqLink:0, //0 结束关联 1 开始关联
    StartMasterOrdSeq:"",
    LayoutResizeTimeout:0,
    BarcodeEntry:0,
	LookupPanelIsShow:0,
	m_selArcimRowIdStr:"",
	fpArr:new Array(),
	BindTipTimerArr:new Array(),	//绑定医嘱延时
	SetPackQtyTimerArr:new Array(),	//SetPackQty延时
    MainSreenFlag:websys_getAppScreenIndex()				//双屏标识
}
if (websys_isIE==true) {
	 var script = document.createElement('script');
	 script.type = 'text/javaScript';
	 script.src = '../scripts/dhcdoc/tools/bluebird.min.js';  // bluebird 文件地址
	 document.getElementsByTagName('head')[0].appendChild(script);
}
function GetDefaultPilotPro(){
	PageLogicObj.DefaultPilotProRowid="";
	PageLogicObj.DefaultPilotProDesc="";
    var ArrData = GlobalObj.PilotProStr.split(String.fromCharCode(2));
    for (var i = 0; i < ArrData.length; i++) {
        var ArrData1 = ArrData[i].split(String.fromCharCode(1));
        if (ArrData1[2] == "Y") {
            PageLogicObj.DefaultPilotProRowid = ArrData1[0];
            PageLogicObj.DefaultPilotProDesc = ArrData1[1];
        }
    }
}
function StopOrd(rowids,callBackFun,StopOrdList) {
    var OrdList = ""
    for (var i = 0; i < rowids.length; i++) {
        var rowid = rowids[i]

        var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
        var OrderSeqNo = GetCellData(rowid, "id");
        var OrderStartDateStr = GetCellData(rowid, "OrderStartDate")
        if (OrdList == "") {
            OrdList = OrderItemRowid //+ "&" + OrderStartDateStr.split(" ")[0] + "&" + OrderStartDateStr.split(" ")[1];
        } else {
            OrdList = OrdList + "^" + OrderItemRowid //+ "&" + OrderStartDateStr.split(" ")[0] + "&" + OrderStartDateStr.split(" ")[1];
        }
    }
    if (typeof StopOrdList == "undefined") StopOrdList="";
    if ((OrdList=="")&&(StopOrdList!="")) OrdList=StopOrdList;
    if (OrdList == "") {
        $.messager.alert("提示","请选择需要停止的医嘱!");
        return false;
    }
    var ContainerName = "";
	var caIsPass = 0;
	UpdateObj={};
   	new Promise(function(resolve,rejected){
	   	//电子签名
		CASignObj.CASignLogin(resolve,"OrderStop",true)
	}).then(function(CAObj){
    	return new Promise(function(resolve,rejected){
	    	if (CAObj == false) {
		    	DisableBtn("Insert_Order_btn",false);
	    		return websys_cancel();
	    	} else{
	    	$.extend(UpdateObj, CAObj);
	    	resolve(true);
	    	}
		})
	}).then(function(){
		var OrdListStr = tkMakeServerCall("web.DHCOEOrdItem", "GetOrdList", OrdList);
	    var rtn=$.m({
		    ClassName:"web.DHCDocInPatPortalCommon",
		    MethodName:"CheckMulOrdDealPermission",
		    OrderItemStr:OrdListStr.replace(/&/g, String.fromCharCode(1)),
		    date:"",
		    time:"",
		    type:"C",
		    ExpStr:session['LOGON.USERID']+"^"+session['LOGON.CTLOCID']+"^"+session['LOGON.GROUPID']+"^^"
		},false);
	    if (rtn!=0){
		   $.messager.alert("提示",rtn);
		   return false;
	    }
	    var rtn = cspRunServerMethod(GlobalObj.StopOrderMethod, OrdListStr, session['LOGON.USERID'], "", "N");
	    var flag=rtn.split("^")[0];
	    if (flag!=0){
		   $.messager.alert("提示","停止失败！"+rtn.split("^")[1]);
		   return false;
	    }
	     if ((flag == "0") && (UpdateObj.caIsPass == 1)) var ret = CASignObj.SaveCASign(UpdateObj.CAObj, OrdList, "S");
	    if((flag == "0")&&(typeof CDSSObj=='object')) CDSSObj.SynOrder(GlobalObj.EpisodeID,OrdList);
	    //医保处方流转-撤销
	    Common_ControlObj.Interface("CheckPrescUndo",{
			EpisodeID:GlobalObj.EpisodeID,
			OrdList:OrdListStr
		});
	    callBackFun(OrdListStr);
	})
}
//快捷键设置
$(document).keydown(function(e) {
    //e = window.event || e || e.which;
    //屏蔽F1快捷键
    /*window.onhelp = function() { return false };
    
	//F1 添加
    if (e.which == 112) {
        if (!$("#Add_Order_btn").attr("disabled")) {
            Add_Order_row();
        }
    }
    //F2 删除
    if (e.which == 113) {
        if (!$("#Delete_Order_btn").attr("disabled")) {
            Delete_Order_row();
        }
    }
	*/
    e = window.event || e || e.which;
   	if (e){
        var ctrlKeyFlag=e.ctrlKey;
    }else{
        var ctrlKeyFlag=window.event.ctrlKey;
    }
    if (ctrlKeyFlag){
	    if (event.keyCode == 83){ 
            return false;
        }
	}
});
//审核医嘱后刷新医嘱单
function RefreshOderList(Type) {
	try {
		//var OrderPriorItem=$("#kwOrderPrior").keywords('getSelected')[0];
		if ($("#kwOrderPrior").hasClass('combo-f')){
			var OrderPriorID=$("#kwOrderPrior").combo("getValue");
		}else if ($("#kwOrderPrior").hasClass('keywords-labelred')){
			var OrderPriorID=$("#kwOrderPrior").keywords('getSelected')[0].rowid;
		}else{
			var OrderPriorID=GlobalObj.ShortOrderPriorRowid;
		}
		if (OrderPriorID==GlobalObj.ShortOrderPriorRowid){
			OrderPriorItem="ShortOrderPrior";
		}else if (OrderPriorID==GlobalObj.OutOrderPriorRowid){
			OrderPriorItem="OutOrderPrior";
		}else{
			OrderPriorItem="LongOrderPrior";
		}
    OrderPriorChangeFun({type:OrderPriorItem},true);
	} catch (e) {
		console.log("RefreshOderList方法失败:"+e)
	}
}
function ChangeOrderPriorContrl(item) {
    var PriorRowid = item.rowid;
    $("#HiddenOrderPrior").val(item.type);
    //配置
    var Updateflag = GlobalObj.CFSwithGlobalPriorUpdate;
    new Promise(function(resolve,rejected){
	    var UpdateObj={
		    "callBackFun":resolve
		}
		if (Updateflag==1){
			//检查是否有新开医嘱
	    	var RowIdArry = GetNewOrderIDS();
	    	if ((RowIdArry.length > 0)&&(GlobalObj.OrderPriorContrlConfig == 1)) {
		    	$.messager.confirm("确认对话框", "将要切换全局医嘱类型,是否审核未保存医嘱？", function (r) {
					if (r) {
						if (GlobalObj.warning != "") {
							$.messager.alert("警告",GlobalObj.warning);
	                		return false;
						}
						UpdateClickHandler(UpdateObj);
					}else{
						resolve();
					}
				});
			    return;
		    }
		}
		resolve();
	}).then(function(){
	    //设置当前最后一行
	    var rowid = GetPreRowId();
	    if (CheckIsClear(rowid) == true) {
	        //设置医嘱类型
	        SetOrderPrior(rowid, PriorRowid);
	    }
	    if(OrderPriorChangeFun){
	        OrderPriorChangeFun(item);
	    }
	})
}
//医嘱类型控制
function SetOrderPrior(rowid, OrderPriorRowid) {
    var HiddenOrderPrior = $("#HiddenOrderPrior").val()
        //如果登陆科室没有加入到访问位置中强制改变也只能录入临时医嘱
    if (GlobalObj.INAdmTypeLoc == "N") { HiddenOrderPrior = "ShortOrderPrior" }
    var Obj = "";
    if ($.isNumeric(rowid) == true) {
        Obj = document.getElementById(rowid + "_OrderPrior");
    } else {
        Obj = document.getElementById("OrderPrior");
    }
    if ((Obj) && (Obj.type == "select-one")) {
        //根据配置  医嘱类型是否可修改  可修改情况下只设置默认类型为当前选中类型
        //医嘱类型控制  1：强制改变  2：只设置默认
        if (GlobalObj.OrderPriorContrlConfig == 1) {
            if (HiddenOrderPrior == "ShortOrderPrior") {
                ClearAllList(Obj);
                //只有临时
                Obj.options[Obj.length] = new Option($g("临时医嘱"), GlobalObj.ShortOrderPriorRowid);
                SetCellData(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
                SetCellData(rowid, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
                SetCellData(rowid, "OrderPriorStr", GlobalObj.ShortOrderPriorRowid + ":" + $g("临时医嘱"));
            } else if (HiddenOrderPrior == "LongOrderPrior") {

                ClearAllList(Obj);
                //只有长期
                Obj.options[Obj.length] = new Option($g("长期医嘱"), GlobalObj.LongOrderPriorRowid);
                SetCellData(rowid, "OrderPrior", GlobalObj.LongOrderPriorRowid);
                SetCellData(rowid, "OrderPriorRowid", GlobalObj.LongOrderPriorRowid);
                SetCellData(rowid, "OrderPriorStr", GlobalObj.LongOrderPriorRowid + ":" + $g("长期医嘱"));
            } else if (HiddenOrderPrior == "OutOrderPrior") {

                ClearAllList(Obj);
                //出院带药
                Obj.options[Obj.length] = new Option($g("出院带药"), GlobalObj.OutOrderPriorRowid);
                SetCellData(rowid, "OrderPrior", GlobalObj.OutOrderPriorRowid);
                SetCellData(rowid, "OrderPriorRowid", GlobalObj.OutOrderPriorRowid);
                SetCellData(rowid, "OrderPriorStr", GlobalObj.OutOrderPriorRowid + ":" + $g("出院带药"));
            } else {
                ClearAllList(Obj);
                //默认类型
                var OrderPrior = cspRunServerMethod(GlobalObj.GetOrderPriorMethod, GlobalObj.DefaultOrderPriorRowid);
                Obj.options[Obj.length] = new Option(OrderPrior, GlobalObj.DefaultOrderPriorRowid);
                SetCellData(rowid, "OrderPrior", GlobalObj.DefaultOrderPriorRowid);
                SetCellData(rowid, "OrderPriorRowid", GlobalObj.DefaultOrderPriorRowid);
                SetCellData(rowid, "OrderPriorStr", GlobalObj.DefaultOrderPriorRowid + ":" + OrderPrior);
            }

        } else {
            //医嘱类型可选
            //设置默认
            if (HiddenOrderPrior == "ShortOrderPrior") {
                OrderPriorRowid = GlobalObj.ShortOrderPriorRowid;
            } else if (HiddenOrderPrior == "LongOrderPrior") {
                OrderPriorRowid = GlobalObj.LongOrderPriorRowid;
            } else if (HiddenOrderPrior == "OutOrderPrior") {
                OrderPriorRowid = GlobalObj.OutOrderPriorRowid;
            }

            ClearAllList(Obj);
            var ArrData = GlobalObj.OrderPriorStr.split(";");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(":");
                Obj.options[Obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            SetCellData(rowid, "OrderPriorStr", GlobalObj.OrderPriorStr);
            if (OrderPriorRowid == "" || OrderPriorRowid == undefined) {
                SetCellData(rowid, "OrderPrior", GlobalObj.DefaultOrderPriorRowid);
                SetCellData(rowid, "OrderPriorRowid", GlobalObj.DefaultOrderPriorRowid);
            } else {
                SetCellData(rowid, "OrderPrior", OrderPriorRowid);
                SetCellData(rowid, "OrderPriorRowid", OrderPriorRowid);
            }
        }
    }
}
function GetDefaultOrderPrior(OrderPrior) {
    var HiddenOrderPrior = $("#HiddenOrderPrior").val();
    var OrderPriorRowid = "";
    var OrderPriorStr = "";
    if (HiddenOrderPrior == "ShortOrderPrior" || OrderPrior == "ShortOrderPrior") {
        //只有临时
        OrderPriorRowid = GlobalObj.ShortOrderPriorRowid;
        OrderPriorStr = GlobalObj.ShortOrderPriorRowid + ":" + $g("临时医嘱");
    } else if (HiddenOrderPrior == "LongOrderPrior" || OrderPrior == "LongOrderPrior") {

        //只有长期  
        OrderPriorRowid = GlobalObj.LongOrderPriorRowid;
        OrderPriorStr = GlobalObj.LongOrderPriorRowid + ":" + $g("长期医嘱");
    } else if (HiddenOrderPrior == "OutOrderPrior" || OrderPrior == "OutOrderPrior") {

        //出院带药
        OrderPriorRowid = GlobalObj.OutOrderPriorRowid;
        OrderPriorStr = GlobalObj.OutOrderPriorRowid + ":" + $g("出院带药");
    } else {
        OrderPriorRowid = GlobalObj.DefaultOrderPriorRowid;
        //取名称
        OrderPrior = cspRunServerMethod(GlobalObj.GetOrderPriorMethod, OrderPriorRowid);
        OrderPriorStr = GlobalObj.DefaultOrderPriorRowid + ":" + OrderPrior;
    }
    return OrderPriorRowid + "^" + OrderPriorStr;
}
//删除一行
function DeleteRow(rowid,delType) {
	var DeleteRowSub=function(rowid){
		//抗生素3
		DeleteAntReason(rowid);
		$('#Order_DataGrid').delRowData(rowid);
	}
	if ($.isNumeric(rowid)){
		if (typeof delType!="undefined"){
			if (delType=="Group"){
				var RowArry = GetSeqNolist(rowid)
				RowArry.push(rowid);
				for (var i = 0; i < RowArry.length; i++) {
	    			DeleteRowSub(RowArry[i]);
				}
			}else{
				DeleteRowSub(rowid);
			}
		}else{
			DeleteRowSub(rowid);
		}
		//提示信息改变
		OrderMsgChange();
	}
	CheckMasterOrdStyle();
}
//清空一行数据
function ClearRow(rowid) {
    //删除当前行 再添加空白行  
    if ($.isNumeric(rowid) == true) {
        DeleteRow(rowid);
        Add_Order_row();
    }
    SetScreenSum();
}
//根据主医嘱ID获取子医嘱ID数组
function GetMasterSeqNo(rowid) {
    var rowids = new Array();
    var AllRowids = $('#Order_DataGrid').getDataIDs();
    for (var i = 0; i < AllRowids.length; i++) {
	    var OrderType = GetCellData(AllRowids[i], "OrderType");
	    // if (OrderType!="R") continue;
        var OrderMasterSeqNo = GetCellData(AllRowids[i], "OrderMasterSeqNo");
        if (OrderMasterSeqNo == rowid) {
            rowids[rowids.length] = AllRowids[i];
        }
    }
    return rowids;
}
//根据行号获取所有关联医嘱 
function GetSeqNolist(rowid) {
    var rowids = new Array();
    var OrderSeqNoMain = GetCellData(rowid, "id");
	if(OrderSeqNoMain==false) return rowids;
	OrderSeqNoMain=OrderSeqNoMain.replace(/(^\s*)|(\s*$)/g, '');
    var OrderMasterSeqNoMain = GetCellData(rowid, "OrderMasterSeqNo").replace(/(^\s*)|(\s*$)/g, '');
    var AllRowids = $('#Order_DataGrid').getDataIDs();
    for (var i = 0; i < AllRowids.length; i++) {
        if (CheckIsItem(rowids[i]) == true) { continue; }
        var OrderMasterSeqNo = GetCellData(AllRowids[i], "OrderMasterSeqNo");
        var Orderid = GetCellData(AllRowids[i], "id");
        if (OrderMasterSeqNoMain == "") {
            if (OrderSeqNoMain == OrderMasterSeqNo) { rowids[rowids.length] = AllRowids[i]; }
        } else {
            if ((OrderMasterSeqNoMain == Orderid) || (OrderMasterSeqNo == OrderMasterSeqNoMain)) { rowids[rowids.length] = AllRowids[i]; }
        }
    }
    return rowids;
}
//刷新表格数据
function ReloadGrid(reloadFlag,NotDisplayNoPayOrd) {
    //reload grid
    //防止本地数据不能刷新
    if (typeof reloadFlag == "undefined") {
        var reloadFlag = "";
    }
    if (typeof NotDisplayNoPayOrd == "undefined") {
        NotDisplayNoPayOrd = GlobalObj.NotDisplayNoPayOrd;
    }
    if (reloadFlag != "") {
        DocumentUnloadHandler()
    } else {
        ClearSessionData();
        $("#ScreenBillSum").val(0.00);
    }
    $("#Order_DataGrid").jqGrid("clearGridData");
    if (GlobalObj.PAAdmType!="I") {
		var OrderOpenForAllHosp=$("#OrderOpenForAllHosp").checkbox("getValue")?1:0;
	    var postData = { USERID: session['LOGON.USERID'], ADMID: GlobalObj.EpisodeID,NotDisplayNoPayOrd:NotDisplayNoPayOrd,OrderOpenForAllHosp:OrderOpenForAllHosp};
	    $("#Order_DataGrid").setGridParam({postData:postData}).trigger("reloadGrid");
    }
    if (reloadFlag != "") {
        GetSessionData()
    }
    Add_Order_row();
    ReLoadLabInfo()
}
///tanjishan 2016-03-09 更新界面上的医嘱费用信息
///门诊病历切换页签时会调用此方法
function ReLoadLabInfo() {}
//双击编辑行     5555
function EditRow(rowid, Flag) {
	if (typeof Flag == "undefined") {
        Flag = 0;
    }
    //检查行是否可编辑
    if (CheckCanEdit(rowid) == false) { return false; }
    //已经是编辑状态就退出if($.isNumeric(rowid)==true)
    if (GetEditStatus(rowid) == true || $.isNumeric(rowid) == false) { return false; }
    //1:先取该行样式配置
    var StyleConfigStr = GetCellData(rowid, "StyleConfigStr");
    //2014-04-24
    var StyleConfigObj = {};
    if (StyleConfigStr != "") {
        StyleConfigObj = eval("(" + StyleConfigStr + ")");
    }
    //重建行数据 对于下拉框 重新值
    //2:取数据串
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    var OrderType = GetCellData(rowid, "OrderType");
    var OrderPHPrescType = GetCellData(rowid, "OrderPHPrescType");
    //医嘱类型
    var OrderPriorStr = GetCellData(rowid, "OrderPriorStr");
    if (OrderPriorStr == "") {
        OrderPriorStr = GlobalObj.OrderPriorStr
    }
    //剂量单位
    var idoseqtystr = GetCellData(rowid, "idoseqtystr");
    //数量单位 000000 -协议单位
    var OrderPackUOMStr = GetCellData(rowid, "OrderPackUOMStr");
    //接收科室
    var CurrentRecLocStr = GetCellData(rowid, "CurrentRecLocStr");
    //标本
    var OrderLabSpecStr = GetCellData(rowid, "OrderLabSpecStr");
    //医保分类
    var OrderInsurCatHideen = GetCellData(rowid, "OrderInsurCatHideen");

    //$.messager.alert("警告",CurrentRecLocStr);
    //3:取上一次选择ID和关联数据 因为重置列表数据会有默认选项 所以在重置列表数据之前取值
    //var rowdata=GetRowData(rowid); //不用这个 因为如果行没有保存 会取到标签
    //医嘱类型
    var OrderPrior = GetCellData(rowid, "OrderPrior");
    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    //剂量单位
    var OrderDoseUOM = GetCellData(rowid, "OrderDoseUOM"); //显示值    
    var OrderDoseUOMRowid = GetCellData(rowid, "OrderDoseUOMRowid");
    var OrderDoseQty = GetCellData(rowid, "OrderDoseQty");
    //接收科室
    var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
    //var OrderPackUOM=GetCellData(rowid,"OrderPackUOM"); //显示值
    //数量单位
    var OrderPackUOMRowid = GetCellData(rowid, "OrderPackUOMRowid");
    //标本
    var OrderLabSpecRowid = GetCellData(rowid, "OrderLabSpecRowid");
    //费别
    var OrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
    //附加说明
    var OrderPriorRemarksRowId = GetCellData(rowid, "OrderPriorRemarksRowId");
    //医保分类
    var OrderInsurCatRowId = GetCellData(rowid, "OrderInsurCatRowId");
    //科研项目
    var OrderPilotProRowid = GetCellData(rowid, "OrderPilotProRowid");
    //诊断类别
    var idiagnoscatstr = GetCellData(rowid, "idiagnoscatstr");
    //采集部位
    var OrderLabSpecCollectionSiteStr = GetCellData(rowid, "OrderLabSpecCollectionSiteStr");
    var OrderLabSpecCollectionSiteRowid = GetCellData(rowid, "OrderLabSpecCollectionSiteRowid");
    var DefaultOrderDIACat = GetCellData(rowid, "OrderDIACat");
    var DefaultOrderDIACatRowId = GetCellData(rowid, "OrderDIACatRowId");
    var OrderName = GetCellData(rowid, "OrderName");
    var OrderPriorRemarksRowId = GetCellData(rowid, "OrderPriorRemarksRowId");
    var OrderOperationCode=GetCellData(rowid,"OrderOperationCode");
    var OrderHiddenPara=GetCellData(rowid,"OrderHiddenPara");
    var OrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
    var HourFlag = cspRunServerMethod(GlobalObj.IsHourItem, OrderARCIMRowid);
    var OrderOperationStr=GetCellData(rowid,"OrderOperationStr");
    var OrderDocStr=GetCellData(rowid,"OrderDocStr");
    var OrderFreqRowid=GetCellData(rowid,"OrderFreqRowid");
    var InsurCatStr=GetCellData(rowid, "OrderInsurCatHideen");
    var OrderChronicDiagStr=GetCellData(rowid, "OrderChronicDiagStr");
    var OrderChronicDiagCode=GetCellData(rowid, "OrderChronicDiagCode");
    var OrderFirstDayTimes = GetCellData(rowid, "OrderFirstDayTimes");
    var OrderFirstDayTimesStr = GetCellData(rowid, "OrderFirstDayTimesStr");
    //1:先取该行样式配置
    var StyleConfigObj = {};
    var StyleConfigStr = GetCellData(rowid, "StyleConfigStr");
    if (StyleConfigStr == "") {
	    var OrderRecDepRowid=GetCellData(rowid, "OrderRecDepRowid")
		var OrderMasterARCIMRowid="";
		var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
		if (OrderMasterSeqNo!=""){
			var rowids = GetAllRowId();
	        for (var i = 0; i < rowids.length; i++) {
				var OrderSeqNo = GetCellData(rowids[i], "id")
	            var OrderSeqNoMasterLink = GetCellData(rowids[i], "id");
	            if (OrderSeqNoMasterLink == OrderMasterSeqNo) {
	            	OrderMasterARCIMRowid=GetCellData(rowids[i], "OrderARCIMRowid");
	            	break;
	            }
	        }
		}
        var DefaultParamObj = {
            rowid: rowid,
            OrderARCIMRowid: OrderARCIMRowid,
            OrderType: OrderType,
            OrderPHPrescType: OrderPHPrescType,
            OrderPriorRowid: OrderPriorRowid,
            OrderPriorRemarksRowId: OrderPriorRemarksRowId,
            OrderHiddenPara:OrderHiddenPara,
            OrderItemCatRowid:OrderItemCatRowid,
            IsHourItem:HourFlag,
            OrderRecDepRowid:OrderRecDepRowid,
			OrderMasterARCIMRowid:OrderMasterARCIMRowid,
			OrderFreqRowid:OrderFreqRowid
        };
        StyleConfigObj = GetStyleConfigObj(DefaultParamObj);
    } else {
        StyleConfigObj = eval("(" + StyleConfigStr + ")");
    }
    StyleConfigObj.OrderName = true    
    //重建行数据 对于下拉框 重新值
    //var OrderItemRowid=GetCellData(rowid,"OrderItemRowid");
    var OrderType = GetCellData(rowid, "OrderType");
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    var OrderPrescNo = GetCellData(rowid, "OrderPrescNo");
    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    var SttIsCanCrossDay = mPiece(OrderHiddenPara, String.fromCharCode(1), 8);
    var OrdDateIsCanCrossDay= mPiece(OrderHiddenPara, String.fromCharCode(1), 22);
    if (GlobalObj.CurrentDischargeStatus == "B") {
	    $.extend(StyleConfigObj, {OrderStartDate:true,OrderDate:true});
	}else{
	    if (!CheckDateTimeModifyFlag(GlobalObj.ModifySttDateTimeAuthority,SttIsCanCrossDay)){
		    $.extend(StyleConfigObj, { OrderStartDate: false});
		}else{
			$.extend(StyleConfigObj, { OrderStartDate: true});
		}
		if (!CheckDateTimeModifyFlag(GlobalObj.ModifyDateTimeAuthority,OrdDateIsCanCrossDay)){
		    $.extend(StyleConfigObj, { OrderDate:false});
		}else{
			$.extend(StyleConfigObj, { OrderDate: true});
		}
	}
    var OrderFreqTimeDoseStr=GetCellData(rowid, "OrderFreqTimeDoseStr");
    if (OrderFreqTimeDoseStr!="") {
	    $.extend(StyleConfigObj, { OrderDoseQty: "readonly"});
	}
	//记录重建行之前的ConfigStr，方式双击后取消关联改变行状态
    var BeforeStyleConfigStr = JSON.stringify(StyleConfigObj);
    if ((OrderPrescNo != "")||(Flag=="1")) { 
        ///tanjishan 2015-09
        ///仅重建医嘱数量,单次计量,单次计量单位,频次,疗程,用法
        StyleConfigObj.OrderName = false
        //StyleConfigObj.OrderMasterSeqNo = false
        StyleConfigObj.OrderPrior = false
        //StyleConfigObj.OrderLabSpec = false
        //StyleConfigObj.OrderInsurCat = false
        StyleConfigObj.OrderAction = false
        StyleConfigObj.OrderSkinTest = false
        StyleConfigObj.OrderStartDate = false
        StyleConfigObj.OrderPackQty = true
        if (GlobalObj.PAAdmType!="I") {
		    var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
		    if ((OrderPriorRemarks=="OM")||(OrderPriorRemarks=="ZT")){
			    StyleConfigObj.OrderPackQty = false;
			}
		}
		var BeforeStyleConfigStr = JSON.stringify(StyleConfigObj);
        if (OrderMasterSeqNo != "") {
            StyleConfigObj.OrderDur = false;
            StyleConfigObj.OrderFreq = false;
            StyleConfigObj.OrderInstr = false;
            StyleConfigObj.OrderSpeedFlowRate = false;
            StyleConfigObj.OrderFlowRateUnit = false;
			StyleConfigObj.ExceedReason=false;
			StyleConfigObj.OrderLocalInfusionQty=false;
			if (GlobalObj.CFSameRecDepForGroup == 1){
				StyleConfigObj.OrderRecDep=false;
			}
			StyleConfigObj.OrderStage = false;
        }
    }
    //启动编辑
    EditRowCommon(rowid, StyleConfigObj.OrderName);
    InitRowLookUp(rowid);
	InitDoseQtyToolTip(rowid);
    //4:改变样式
    //设置某些字段disable
    var RowDisableStr = GetCellData(rowid, "RowDisableStr");
    var RowDisableObj = {};
    if (RowDisableStr != "") {
        RowDisableObj = eval("(" + RowDisableStr + ")");
    }
    ChangeCellDisable(rowid, RowDisableObj);	
    ChangeRowStyle(rowid, StyleConfigObj);
    SetCellData(rowid, "StyleConfigStr", BeforeStyleConfigStr);
    //5:重置列表数据
    SetColumnList(rowid, "OrderPrior", OrderPriorStr);
    SetColumnList(rowid, "OrderDoseUOM", idoseqtystr);
    SetColumnList(rowid, "OrderRecDep", CurrentRecLocStr);
    SetColumnList(rowid, "OrderPackUOM", OrderPackUOMStr);
    SetColumnList(rowid, "OrderLabSpec", OrderLabSpecStr);
    //SetColumnList(rowid, "OrderInsurCat", OrderInsurCatHideen);
    SetColumnList(rowid, "OrderPilotPro", GlobalObj.PilotProStr);
    SetColumnList(rowid, "OrderDIACat", idiagnoscatstr);
    SetColumnList(rowid, "OrderOperation", OrderOperationStr);
    SetColumnList(rowid, "OrderInsurCat", InsurCatStr);
    SetColumnList(rowid, "OrderChronicDiag", OrderChronicDiagStr);
    if (DefaultOrderDIACat != "") {
        SetCellData(rowid, "OrderDIACat", DefaultOrderDIACatRowId);
        SetCellData(rowid, "OrderDIACatRowId", DefaultOrderDIACatRowId);
    }
    //6:设置上一次选项和关联数据
    if (StyleConfigObj.OrderDoseUOM != undefined && StyleConfigObj.OrderDoseUOM != false && StyleConfigObj.OrderDoseUOM != true) {
        SetCellData(rowid, "OrderDoseUOM", OrderDoseUOM);
    } else if (StyleConfigObj.OrderDoseUOM == undefined || StyleConfigObj.OrderDoseUOM == true) {
        if (OrderDoseUOMRowid != "") {
            SetCellData(rowid, "OrderDoseUOM", OrderDoseUOMRowid);
            SetCellData(rowid, "OrderDoseUOMRowid", OrderDoseUOMRowid);
        } else {
            if (idoseqtystr != "") {
                var ArrData = idoseqtystr.split(String.fromCharCode(2));
                var ArrData1 = ArrData[0].split(String.fromCharCode(1));
                //DefaultDoseQty=ArrData1[0];
                var DefaultDoseQtyUOM = ArrData1[1];
                var DefaultDoseUOMRowid = ArrData1[2];
                SetCellData(rowid, "OrderDoseUOM", DefaultDoseUOMRowid);
                SetCellData(rowid, "OrderDoseUOMRowid", DefaultDoseUOMRowid);
            }
        }
    }
    SetCellData(rowid, "OrderPrior", OrderPriorRowid);
    SetCellData(rowid, "OrderPriorRowid", OrderPriorRowid);
    SetCellData(rowid, "OrderDoseQty", OrderDoseQty); //重建剂量单位下拉框的时候会设置默认值 所以需要还原 
    SetCellData(rowid, "OrderRecDepRowid", OrderRecDepRowid);  
    SetCellData(rowid, "OrderRecDep", OrderRecDepRowid);
    SetCellData(rowid, "OrderPrior", OrderPriorRowid);
    SetCellData(rowid, "OrderLabSpec", OrderLabSpecRowid);
    SetCellData(rowid, "OrderLabSpecRowid", OrderLabSpecRowid);
    SetCellData(rowid, "OrderBillType", OrderBillTypeRowid);
    SetCellData(rowid, "OrderPriorRemarks", OrderPriorRemarksRowId);
    SetCellData(rowid, "OrderPriorRemarksRowId", OrderPriorRemarksRowId);
    SetCellData(rowid, "OrderPackUOM", OrderPackUOMRowid); //协议单位
    SetCellData(rowid, "OrderInsurCat", OrderInsurCatRowId); //医保分类
    SetCellData(rowid, "OrderInsurCatRowId", OrderInsurCatRowId);
    SetCellData(rowid, "OrderPilotPro", OrderPilotProRowid);
    SetCellData(rowid, "OrderOperation",OrderOperationCode);
    SetCellData(rowid, "OrderChronicDiag",OrderChronicDiagCode);
    SetColumnList(rowid,"OrderFirstDayTimesCode",OrderFirstDayTimesStr);
	SetCellData(rowid,"OrderFirstDayTimesCode",OrderFirstDayTimes);

    GetCellData(rowid,"OrderHiddenPara",OrderHiddenPara);
    var OrderDocRowid=GetCellData(rowid, "OrderDocRowid");
    var ChangeFlag=1
    var LogonDocStrArry=GlobalObj.LogonDocStr.split("^")
    for (var i = 0; i < LogonDocStrArry.length; i++) {
	    var OneLogonDoc=LogonDocStrArry[i].split(String.fromCharCode(1))[1]
	    if (OneLogonDoc==OrderDocRowid){
		    ChangeFlag=0
		    }
	    }
    if (ChangeFlag==1){
	    SetColumnList(rowid,"OrderDoc",GlobalObj.LogonDocStr);
    	SetCellData(rowid, "OrderDoc", GlobalObj.LogonDoctorID);
    	SetCellData(rowid, "OrderDocRowid", GlobalObj.LogonDoctorID); 
	}else{
    	//开医嘱人
    	SetColumnList(rowid,"OrderDoc",OrderDocStr);
    	SetCellData(rowid, "OrderDoc", OrderDocRowid);
    	SetCellData(rowid, "OrderDocRowid", OrderDocRowid); 
    }   
    //SetOrderPrior(rowid,OrderPriorRowid);//医嘱类型控制
    SetColumnList(rowid,"OrderLabSpecCollectionSite",OrderLabSpecCollectionSiteStr);
    SetCellData(rowid, "OrderLabSpecCollectionSiteRowid", OrderLabSpecCollectionSiteRowid);
    SetCellData(rowid, "OrderLabSpecCollectionSite", OrderLabSpecCollectionSiteRowid);  
    
    //频次疗程关联事件
    FreqDurChange(rowid);
    OrdDoseQtyBindClick(rowid);
    initItemInstrDiv(rowid);
    //根据开医嘱时间用法,重新设置接收科室
    var ARCIMRowId = GetCellData(rowid, "OrderARCIMRowid");
    if (ARCIMRowId !="") {
		if ((OrderPrescNo != "")||(Flag=="1")) { 
			SetRecLocStr(rowid);
		}
	}
	if(OrderMasterSeqNo) OrderMasterHandler(rowid, "S");
    //知识库
    CheckLibPhaFunction("Q", rowid, "")
    XHZY_Click();
}
//获取所有数据 如果行处于编辑状态 这样得到的行数据包含标签
function GetGirdData(AllFlag) {
    //保存数据
    //Save_Order_row();
    var DataArry = new Array();
    var rowids = $('#Order_DataGrid').getDataIDs();
    for (var i = 0; i < rowids.length; i++) {
        //不取已经审核医嘱 和空白行
        //if(CheckIsItem(rowids[i])==true){continue;}
        var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
        var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
		var OrderARCOSRowid = GetCellData(rowids[i], "OrderARCOSRowid");
        if (!AllFlag&&(OrderItemRowid != "")) continue;
		if((OrderARCIMRowid == "")&&(OrderARCOSRowid == ""))continue;
        //保存行
        EndEditRow(rowids[i]);
        var curRowData = $("#Order_DataGrid").getRowData(rowids[i]);
        DataArry[DataArry.length] = curRowData;
    }
    return DataArry;
}
function GetScreenBillSum() {
    var Sum = 0;
    var rowids = GetAllRowId();
    for (var i = 0; i < rowids.length; i++) {
        if (CheckIsItem(rowids[i]) == true) { continue; }
        var OrderSum = GetCellData(rowids[i], "OrderSum");
        var OrderPriorRemarksRowId = GetCellData(rowids[i], "OrderPriorRemarksRowId");
        if ((OrderPriorRemarksRowId == "OM") || (OrderPriorRemarksRowId == "ZT")) { continue }
        if (OrderSum == "") { continue }
        Sum = parseFloat(Sum) + parseFloat(OrderSum);
    }
    Sum = Sum.toFixed(4);
    return Sum;
}
function GetScreenBillSumNew() {
    ///获取医嘱录入界面未审核和已审核医嘱的总金额
    var UnSavedSum = 0,SavedSum=0;
    var rowids = GetAllRowId();
    for (var i = 0; i < rowids.length; i++) {
        var OrderSum = GetCellData(rowids[i], "OrderSum");
        var OrderPriorRemarksRowId = GetCellData(rowids[i], "OrderPriorRemarksRowId");
        if ((OrderPriorRemarksRowId == "OM") || (OrderPriorRemarksRowId == "ZT")) { continue }
        if (OrderSum == "") { continue }
        if (CheckIsItem(rowids[i]) == true) { 
        	SavedSum = parseFloat(SavedSum) + parseFloat(OrderSum);
        }else{
	        UnSavedSum = parseFloat(UnSavedSum) + parseFloat(OrderSum);
	    }
    }
    UnSavedSum = fomatFloat(UnSavedSum,2); //UnSavedSum.toFixed(2);
    SavedSum = fomatFloat(SavedSum,2);//SavedSum.toFixed(2);
    return UnSavedSum+"^"+SavedSum;
}
//设置统计数据
function SetScreenSum() {
    var Sum = GetScreenBillSumNew();
    $("#ScreenBillSum").val(Sum.split("^")[0]); //未审金额
	$("#SavedScreenBillSum").val(Sum.split("^")[1]); //已审金额
}
//添加一行 空白行  返回rowid
function Add_Order_row(AddMethod) {
	if ($("#Add_Order_btn").hasClass('l-btn-disabled')){
		return false;
	}
    var rowid = "";
    //只能添加一行空行 
    var records = $('#Order_DataGrid').getGridParam("records");
    if (records >= 1) {
        //var rowids=$('#Order_DataGrid').getDataIDs();
        //获取当前最后一行ID  GetPreRowId() 不传参数 返回当前行ID
        var prerowid = GetPreRowId();
        //最后一行是否有数据
        var OrderARCIMRowid = GetCellData(prerowid, "OrderARCIMRowid");
		//快速医嘱套
		var OrderARCOSRowid = GetCellData(prerowid, "OrderARCOSRowid");
        //$.messager.alert("警告",OrderARCIMRowid);
        if ((OrderARCIMRowid == "" || OrderARCIMRowid == null)&&(OrderARCOSRowid == "" || OrderARCOSRowid == null)) {
			//设置焦点,如果是data方式添加的，不应该再聚焦，因为会影响添加医嘱的确认弹框聚焦问题
            if (AddMethod!="data"){
            	SetFocusCell(prerowid, "OrderName");
            }
            return prerowid;
        }
    }
    /*
    if(records==0){
        //防止添加医嘱套未成功
        RebuidRowId();
    }
    */
    rowid = GetNewrowid();
    if (rowid == "" || rowid == 0) { return; }
    //设置默认值     
    var DefaultData = GetDefaultData(rowid);
    DefaultData['id'] = rowid;
    $('#Order_DataGrid').addRowData(rowid, DefaultData);
    var OrdCateGoryRowId = GetCellData(prerowid, "OrdCateGoryRowId");
    var OrdCateGory = GetCellData(prerowid, "OrdCateGory");
    SetCellData(rowid, "OrdCateGoryRowId",OrdCateGoryRowId);
    SetCellData(rowid, "OrdCateGory",OrdCateGory);
    SetNewOrderClass(rowid);
    EditRowCommon(rowid);
    SetOrderPrior(rowid);
    InitRowLookUp(rowid);
	InitDoseQtyToolTip(rowid);
	InitRowBtn(rowid);
    var RowStyleObj={};
    if (GlobalObj.CurrentDischargeStatus == "B") {
	    $.extend(RowStyleObj, {OrderStartDate:true,OrderDate:true});
		
	}else{
	    if (!CheckDateTimeModifyFlag(GlobalObj.ModifySttDateTimeAuthority,"")) {
		    $.extend(RowStyleObj, { OrderStartDate:false});
	    }
	    if (!CheckDateTimeModifyFlag(GlobalObj.ModifyDateTimeAuthority,"")) {
		    $.extend(RowStyleObj, { OrderDate:false});
	    } 
    }  
    if (GlobalObj.UserEMVirtualtLong!="1"){
		 $.extend(RowStyleObj, { OrderVirtualtLong:false});   
	}   
    ChangeRowStyle(rowid, RowStyleObj); 
    if ($("#NurseOrd").checkbox('getValue')) {
	    $("tr.jqgrow").css("background","#FFCCCC");
	}   
    //设置焦点
	if (AddMethod!="data"){
		SetFocusCell(rowid, "OrderName")
	}
    return rowid;
}

//添加 带数据的一行  返回rowid
function Add_Order_row2(newDataObj) {
    var rowid = newDataObj["id"];
    $('#Order_DataGrid').addRowData(rowid, newDataObj);
    //
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    if (OrderMasterSeqNo != "") {
        $("#" + OrderMasterSeqNo).find("td").addClass("OrderMasterM");
        $("#" + rowid).find("td").addClass("OrderMasterS");
    }
    SetNewOrderClass(rowid);
	InitRowBtn(rowid);
	if ($("#NurseOrd").checkbox('getValue')) {
	    $("tr.jqgrow").css("background","#FFCCCC");
	}
    return rowid;
}
//设置新开医嘱的区别的列样式 
function SetNewOrderClass(rowid) {
    // setCell(rowid,colname, data, class, properties)
    if (CheckIsItem(rowid) == false) {
        $('#Order_DataGrid').setCell(rowid, "id", rowid, "NewOrder", "");
    }
}
//获取session数据添加到表格
function Add_Session_row(newDataObj) {
    //存在session数据 ID要还原为上一次
    var rowid = newDataObj["id"];
    $('#Order_DataGrid').addRowData(rowid, newDataObj);
    var OrderName=GetCellData(rowid,"OrderName");
    var OrderHiddenPara=GetCellData(rowid, "OrderHiddenPara");
    var PHCDFCriticalFlag=OrderHiddenPara.split(String.fromCharCode(1))[17];
    if (PHCDFCriticalFlag=="Y"){
    	$('#Order_DataGrid').setCell(rowid,"OrderName",OrderName,"OrderCritical","");
    }
    SetNewOrderClass(rowid);
	InitRowBtn(rowid);
    return rowid;
}
//设置默认数据
function GetDefaultData(rowid) {
    //滴速和单位默认值
    var OrderSpeedFlowRate = "";
    var OrderFlowRateUnit = "";
    var OrderFlowRateUnitRowId = ""
	var OrderPriorRowid = "";
	var OrderPriorStr = "";
    //默认医嘱类型
    if ($('#PriorType').length>0){
    	var CurrOrderPrior = $('#PriorType').text();
	    if ((CurrOrderPrior.indexOf("临时") != -1)||(GlobalObj.INAdmTypeLoc!="Y")) {
	        //只有临时
	        OrderPriorRowid = GlobalObj.ShortOrderPriorRowid;
	        OrderPriorStr = GlobalObj.ShortOrderPriorRowid + ":" + $g("临时医嘱");
	    } else if (CurrOrderPrior.indexOf("长期") != -1) {
	        //只有长期  
	        OrderPriorRowid = GlobalObj.LongOrderPriorRowid;
	        OrderPriorStr = GlobalObj.LongOrderPriorRowid + ":" + $g("长期医嘱");
	    } else if (CurrOrderPrior.indexOf("出院") != -1) {
	        //出院带药
	        OrderPriorRowid = GlobalObj.OutOrderPriorRowid;
	        OrderPriorStr = GlobalObj.OutOrderPriorRowid + ":" + $g("出院带药");
	    } else {
	        OrderPriorRowid = GlobalObj.DefaultOrderPriorRowid;
	        OrderPriorStr = GlobalObj.OrderPriorStr;
	    }
	}else{
		var DefaultOrderPrior=GetDefaultOrderPrior("");
		OrderPriorStr = mPiece(DefaultOrderPrior, "^", 1);
		OrderPriorRowid = mPiece(DefaultOrderPrior, "^", 0);
	}

    //获取上一行ID  因为当前行还没有添加或者删除 所以取当前最后一行
    var prerowid = GetPreRowId(rowid);
    //$.messager.alert("警告","prerowid:"+prerowid);
    //开始日期  OrderStartDate  2014-03-25 17:34:34
    var Currtime = GetCurr_time();
    var OrderStartDate = Currtime;
    var OrderEndDate = Currtime;
    //开医嘱日期  OrderDate  2014-03-25 17:34:34
    var OrderDate = Currtime;
    //开医嘱人
    var OrderDoc = session['LOGON.USERNAME'];
    //录入人
    var OrderUserAdd = session['LOGON.USERNAME'];
    //开医嘱科室
    var OrderUserDep = GlobalObj.CTLOC;
    //默认费别
    var OrderBillTypeRowid = "",
        OrderBillType = "";
    var PreOrderBillTypeRowid = GetCellData(prerowid, "OrderBillTypeRowid");
    var PreOrderBillType = GetCellData(prerowid, "OrderBillType");
    var response=$.cm({
		ClassName:"web.DHCDocOrderCommon",
		MethodName:"GetDefaultPrescriptType",
		dataType:"text",
		EpisodeID:GlobalObj.EpisodeID,
		PreBillTypeID:PreOrderBillTypeRowid,
		PreBillType:PreOrderBillType
	},false);
    response=response.replace(/(^\s*)|(\s*$)/g, '');
    var DefaultPrescriptType = response.split('^')[0];
    OrderBillTypeRowid = DefaultPrescriptType.split(':')[0];
    OrderBillType = DefaultPrescriptType.split(':')[1];
    var PreDIACatRowId = "";
    var PreOrderDIACat = "";
    var PreOrderOperationCode="";
    var PreOrderOperation="";
    //如果头菜单上已经做了默认手术列表选项，则不再跟随行进行操作
    var MenuOrderOperationCode=GetMenuPara("AnaestOperationID");
    //存在上一行 取上一行数据
    //$.messager.alert("警告",prerowid+"^"+rowid);
    if ($.isNumeric(prerowid) == true) {
        //OrderPriorRowid=GetCellData(prerowid,"OrderPriorRowid");
        //默认置上前一条的诊断类别
        PreOrderDIACat = GetCellData(prerowid, "OrderDIACat");
        PreDIACatRowId = GetCellData(prerowid, "OrderDIACatRowId");
        PreOrderOperationCode=GetCellData(prerowid,"OrderOperationCode");
        PreOrderOperation=GetCellData(prerowid,"OrderOperation");
    }
    if (MenuOrderOperationCode!=""){
		var PreOrderOperationCode="";
	    var PreOrderOperation="";
	}
    //封装数据对象
    var DfaultData = {
        OrderPriorStr: OrderPriorStr,
        OrderPriorRowid: OrderPriorRowid,
        OrderPrior: OrderPriorRowid,
        OrderStartDate: OrderStartDate,
        //OrderDoc: OrderDoc,
        OrderUserAdd: OrderUserAdd,
        OrderUserDep: OrderUserDep,
        OrderDate: OrderDate,
        OrderBillType: OrderBillType,
        OrderBillTypeRowid: OrderBillTypeRowid,
        OrderDIACat: PreOrderDIACat,
        OrderDIACatRowId: PreDIACatRowId,
        OrderSpeedFlowRate: OrderSpeedFlowRate,
        OrderFlowRateUnit: OrderFlowRateUnit,
        OrderFlowRateUnitRowId: OrderFlowRateUnitRowId,
        OrderOperationCode:PreOrderOperationCode,
        OrderOperation:PreOrderOperation,
        OrderLogDep:GlobalObj.LogLocDesc
    };
    return DfaultData;
}

//设置Session数据
//document.body.onunload = DocumentUnloadHandler;
//window.onunload=DocumentUnloadHandler;
window.onbeforeunload = DocumentUnloadHandler;
function onBeforeCloseTab(){
	DocumentUnloadHandler();
	return true;
}
function DocumentUnloadHandler(e) {
    //CreateEND();
    //如果医嘱保存成功就不用保留在session中(设置)
    //if (StoreUnSaveData!="1"){return}
	SetVerifiedOrder("");
    SaveSessionData();
    //护士补录医嘱刷新清除右侧选中，清除已经关联的关系
    try {
        var par_win = window.parent.parent.parent.left.RPbottom
        if (par_win) {
            par_win.ClearCheck();
            NurseAddMastOrde("^^^^^^", "");
        }
    } catch (e) {
    }
}
function SaveSessionData(){
    ClearSessionData();
    //未审核的医嘱
    var GridData = GetGirdData();
	if(!GridData.length) return;
	//转BASE64 基础平台可能过滤html
	var GridData=JSON.stringify(GridData);
	var data=btoa(unescape(encodeURIComponent(GridData)));	//strToUnicode(GridData);	//
	var len=data.length;
	var startIndex=0
	var count=0
	while(startIndex<len){
		var endIndex=startIndex+5000;
		if(endIndex>len) endIndex=len;
		var UnsaveData=data.substring(startIndex,endIndex);
		$.cm({
			ClassName:'web.DHCDocOrderEntry',
			MethodName:'SetUserUnSaveData',
			AdmId:GlobalObj.EpisodeID, UserId:session['LOGON.USERID'], CtlocId:session['LOGON.CTLOCID'],
			UnSaveInc:++count,
			UnsaveData:UnsaveData,	
			type:'BEACON'
		});
		startIndex=endIndex;
	}
}
//获取缓存数据  2014-04-22
function GetSessionData() {
    //获取session数据 
    var UserID = session['LOGON.USERID'];
    var CTLocId = session['LOGON.CTLOCID'];
	var UserUnSaveData="";
    var UnSaveCount = parseInt(cspRunServerMethod(GlobalObj.GetUserUnSaveCountMethod, GlobalObj.EpisodeID, UserID, CTLocId));
    for (var i = 1; i <= UnSaveCount; i++) {
        UserUnSaveData += cspRunServerMethod(GlobalObj.GetUserUnSaveDataMethod, GlobalObj.EpisodeID, UserID, CTLocId, i);
	}
	if(UnSaveCount && UserUnSaveData!=""){
        //未审核的医嘱需对序号进行处理,避免已经审核的医嘱数据行数变化,导致关联序号错误
        var ListOrderSeq = new Array();
        var prerowid = GetPreRowId();
		UserUnSaveData=decodeURIComponent(escape(atob(UserUnSaveData)));	//unicodeToStr(UserUnSaveData);	//
        var DataArry = JSON.parse(UserUnSaveData);
        for (var j = 0; j < DataArry.length; j++) {
            var obj = DataArry[j];
            var OrderMasterSeqNo=obj["OrderMasterSeqNo"];
            var records = $('#Order_DataGrid').getGridParam("records");
            if (records >= 1) {
                //var rowids=$('#Order_DataGrid').getDataIDs();
                //获取当前最后一行ID  GetPreRowId() 不传参数 返回当前行ID
                var prerowid = GetPreRowId();
                obj["id"] = parseInt(prerowid) + 1
            } else {
                obj["id"] = 1
            }
            if (OrderMasterSeqNo!="") {
                var NewOrderMasterSeqNo=ListOrderSeq[OrderMasterSeqNo];
                if (NewOrderMasterSeqNo){
                    obj["OrderMasterSeqNo"]=NewOrderMasterSeqNo;
                }
            }
            var rowid = Add_Session_row(obj);
        }
	}
}
//清除session数据
function ClearSessionData() {
    $.cm({
		ClassName:'web.DHCDocOrderEntry',
		MethodName:'ClearUserUnSaveData',
		AdmId:GlobalObj.EpisodeID, UserId:session['LOGON.USERID'], CtlocId:session['LOGON.CTLOCID'],
		type:'BEACON'
	});
    //解除患者锁
	$.cm({
		ClassName:'web.DHCDocOrderCommon',
		MethodName:'OrderEntryClearLock',
		SessionStr:GetSessionStr(),
		type:'BEACON'
	});
}
//保存 停止编辑 99999
function Save_Order_row() {
    var rowids = $('#Order_DataGrid').getDataIDs();
    for (var i = 0; i < rowids.length; i++) {
        //
        if (GetEditStatus(rowids[i]) == true) {
            EndEditRow(rowids[i]);
        }
    }
}
//删除多行
function Delete_Order_row() {
	if ($("#Delete_Order_btn").hasClass('l-btn-disabled')){
		return false;
	}
    var ids = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    if (ids == null || ids.length == 0) {
        if (PageLogicObj.FocusRowIndex > 0) {
            //如果有焦点行,则直接删除焦点行
            if ($("#jqg_Order_DataGrid_" + PageLogicObj.FocusRowIndex).prop("checked") != true) {
                $("#Order_DataGrid").setSelection(PageLogicObj.FocusRowIndex, true);
            }
        }
    }
    var ids = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    if (ids == null || ids.length == 0) {
        $.messager.alert("警告", "请选择要删除的记录");
        return;
    }
    $.messager.confirm('确认对话框', '确定删除选中的记录吗？', function(r){
		if (r){
    		DeleteRows(ids);
		}
    })
    return websys_cancel();
}
/// 删除指定行； 单独封装，兼容单独删除子医嘱
function DeleteRows(rows) {
	var OrdItemRowStr = "", IsExistVerifyFlag = false;

    // 退出操作;
    var len = rows.length;
    var DeleteCount = 0;
    for (var i = 0; i < len; i++) {
        //已审核医嘱不能删除
        if (CheckIsItem(rows[i - DeleteCount]) == false) {
            //抗生素4
            var OrdSeqNo=GetCellData(rows[i - DeleteCount], "id");
            if (PageLogicObj.StartMasterOrdSeq==OrdSeqNo) {
                PageLogicObj.StartMasterOrdSeq="";
            }
            DeleteAntReason(rows[i - DeleteCount]);
            $('#Order_DataGrid').delRowData(rows[i - DeleteCount]);
            DeleteCount = DeleteCount + 1;
        } else {
            IsExistVerifyFlag = true;
        }
    }
	if(DeleteCount){
		CheckMasterOrdStyle();
	}
    new Promise(function(resolve,rejected){
		if (IsExistVerifyFlag == true) {
			///删除行之后会rows会发生变化，所以要重写遍历一遍需要删除的医嘱
            var len = rows.length;
            for (var i = 0; i < len; i++) {
                if (CheckIsItem(rows[i]) == true) {
                    IsExistVerifyFlag = true;
                    if (OrdItemRowStr == "") { OrdItemRowStr = rows[i] } else { OrdItemRowStr = OrdItemRowStr + "^" + rows[i] }
                }
            }
            if (OrdItemRowStr != "") {
	            (function(callBackFun){
					new Promise(function(resolve,rejected){
						$.messager.confirm('确认对话框', "存在已审核的医嘱,是否确认停止?", function(r){
							if (r) {
								StopOrd(OrdItemRowStr.split("^"),resolve);
							}else{
								callBackFun();
							}
						});
					}).then(function(){
						ReloadGrid("StopOrd")
		                SaveOrderToEMR()
						callBackFun();
					});
					
				})(resolve);
	        }else{
		        resolve();
		    }
		}else{
			resolve();
		}
	}).then(function(){
		var records = $('#Order_DataGrid').getGridParam("records");
        if (records == 0) {
            $('#cb_Order_DataGrid').prop('checked', false);
            Add_Order_row();
        }
        //ReloadGrid();重新加载数据 审核之后已经加载
        SetScreenSum();
        //提示信息改变
        OrderMsgChange();
	})

	return websys_cancel();
}

//表单编辑
function FormEditRow() {
    //是否可开医嘱判断
    //判断诊断
    if ((GlobalObj.MRDiagnoseCount == 0)&&(GlobalObj.OrderLimit!=1)) {
        $.messager.alert("警告",t['NO_DIAGNOSE']);
        return false;
    }
    var ids = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    var rowids = $('#Order_DataGrid').getDataIDs();
    var Clen = ids.length;
    var Alen = rowids.length;
    var rowid = "";
    var newrowid = "";
    if (Clen == 1) {
        rowid = ids[0];
        //先保存行
        EndEditRow(rowid);
    } else if (Alen >= 1 && Clen == 0) {
        //判断当前最后一行是否有数据
        var lastRowid = GetPreRowId();
        var lastARCIMRowid = GetCellData(lastRowid, "OrderARCIMRowid");
        if (lastARCIMRowid == "") {
            rowid = rowids[Alen - 1]; //lastRowid
            //先保存行
            EndEditRow(rowid);
        } else {
            //添加一行 编辑这一行 
            rowid = Add_Order_row();
            EndEditRow(rowid);
            //rowid="new";
            //newrowid=GetNewrowid();
        }
    } else {
        $.messager.alert("警告", "请选择需要编辑行");
        return;
    }
    //检查行是否可编辑
    if (CheckCanEdit(rowid) == false) { return false; }
    //$.messager.alert("警告",rowid);
    //产生表单
    $("#Order_DataGrid").jqGrid('editGridRow', rowid, {
        top: 5,
        left: 5,
        height: 480,
        width: 1000,
        dataheight: 410,
        datawidth: 990,
        editCaption: '编辑表单',
        beforeShowForm: InitFormStyle(rowid),
        //afterShowForm:InitFormData(ids[0]), 
        //onInitializeForm:InitFormData(ids[0]),
        //modal:true,
        processing: false,
        reloadAfterSubmit: false,
        recreateForm: true,
        closeAfterEdit: true,
        closeOnEscape: true,
        onclickSubmit: GetFormData,
        addedrow: 'last',
        onClose: function() {
            var OrderARCIMRowid = GetCellData("", "OrderARCIMRowid");
            if (OrderARCIMRowid == "" || OrderARCIMRowid == undefined) {
                DeleteRow(rowid);
            } else {
                EditRow(rowid);
                SetScreenSum();
            }
        },
        drag: true,
        viewPagerButtons: false
    });
    //填充数据
    InitFormData(rowid);
    SetFocusCell("", "OrderName");
}

function GetFormData(e) {
    var OrderARCIMRowid = GetCellData("", "OrderARCIMRowid"); //200
    var idoseqtystr = GetCellData("", "idoseqtystr");
    var OrderName = GetCellData("", "OrderName");
    dhcsys_alert(OrderARCIMRowid + ":" + OrderName);
}
//控制表单样式
function InitFormStyle(rowid) {
    //$.messager.alert("警告","beforeShowForm");
    //1:先取该行样式配置
    if ($.isNumeric(rowid) == true) {
        var StyleConfigStr = GetCellData(rowid, "StyleConfigStr");
        if (StyleConfigStr != "") {
            var StyleConfigObj = eval("(" + StyleConfigStr + ")");
            ChangeRowStyle(rowid, StyleConfigObj);
        }
    }
}
//控制表单数据填充
function InitFormData(rowid) {
    if ($.isNumeric(rowid) == false) { return; }
    // 如果添加数据不成功  不要将数据添加到行
    /*
    var OrderARCIMRowid=GetCellData(rowid,"OrderARCIMRowid");
    if(OrderARCIMRowid == "" || OrderARCIMRowid == undefined){return;}
    */
    //$.messager.alert("警告","afterShowForm");
    //1:先取该行样式配置
    var StyleConfigStr = GetCellData(rowid, "StyleConfigStr");
    var StyleConfigObj = {};
    if (StyleConfigStr != "") {
        StyleConfigObj = eval("(" + StyleConfigStr + ")");
    }
    ChangeRowStyle("undefined", StyleConfigObj);
    //表单禁止录入关联医嘱  StyleConfigObj
    $("#OrderMasterSeqNo").attr('disabled', true);

    //重建行数据 对于下拉框 重新值
    //2:取数据串
    //医嘱类型
    var OrderPriorStr = GetCellData(rowid, "OrderPriorStr");
    //剂量单位
    var idoseqtystr = GetCellData(rowid, "idoseqtystr");
    //数量单位 000000
    var OrderPackUOMStr = GetCellData(rowid, "OrderPackUOMStr");
    //接收科室
    var CurrentRecLocStr = GetCellData(rowid, "CurrentRecLocStr");
    //标本
    var OrderLabSpecStr = GetCellData(rowid, "OrderLabSpecStr");
    //$.messager.alert("警告",CurrentRecLocStr);
    //3:取上一次选择ID和关联数据 因为重置列表数据会有默认选项 所以在重置列表数据之前取值
    //var rowdata=GetRowData(rowid); //不用这个 因为如果行没有保存 会取到标签
    //医嘱类型
    var OrderPrior = GetCellData(rowid, "OrderPrior");
    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    //剂量单位
    var OrderDoseUOM = GetCellData(rowid, "OrderDoseUOM"); //显示值    
    var OrderDoseUOMRowid = GetCellData(rowid, "OrderDoseUOMRowid");
    var OrderDoseQty = GetCellData(rowid, "OrderDoseQty");
    //接收科室
    var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
    //var OrderPackUOM=GetCellData(rowid,"OrderPackUOM"); //显示值
    //数量单位
    var OrderPackUOMRowid = GetCellData(rowid, "OrderPackUOMRowid");
    //标本
    var OrderLabSpecRowid = GetCellData(rowid, "OrderLabSpecRowid");
    //费别
    var OrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
    var OrderPriorRemarksRowId = GetCellData(rowid, "OrderPriorRemarksRowId");

    //5:重置列表数据
    SetColumnList("undefined", "OrderPrior", OrderPriorStr);
    SetColumnList("undefined", "OrderDoseUOM", idoseqtystr);
    SetColumnList("undefined", "OrderRecDep", CurrentRecLocStr);
    //SetColumnList(rowid,"OrderPackUOM",OrderPackUOMStr);
    SetColumnList("undefined", "OrderLabSpec", OrderLabSpecStr);

    //6:设置上一次选项和关联数据
    if (StyleConfigObj.OrderDoseUOM != undefined && StyleConfigObj.OrderDoseUOM != false && StyleConfigObj.OrderDoseUOM != true) {
        SetCellData("undefined", "OrderDoseUOM", OrderDoseUOM);
    } else if (StyleConfigObj.OrderDoseUOM == undefined || StyleConfigObj.OrderDoseUOM == true) {
        SetCellData("undefined", "OrderDoseUOM", OrderDoseUOMRowid);
    }
    SetCellData("undefined", "OrderDoseQty", OrderDoseQty); //重建剂量单位下拉框的时候会设置默认值 所以需要还原 
    SetCellData("undefined", "OrderRecDep", OrderRecDepRowid);
    //SetCellData("undefined","OrderPrior",OrderPriorRowid);
    SetCellData("undefined", "OrderLabSpec", OrderLabSpecRowid);
    SetCellData("undefined", "OrderBillType", OrderBillTypeRowid);
    SetCellData("undefined", "OrderPriorRemarks", OrderPriorRemarksRowId);
    SetCellData(rowid, "OrderRecDepRowid", OrderRecDepRowid);
    //医嘱类型控制
    SetOrderPrior("undefined", OrderPriorRowid);

    //设置某些字段disable
    var RowDisableStr = GetCellData(rowid, "RowDisableStr");
    var RowDisableObj = {};
    if (RowDisableStr != "") {
        RowDisableObj = eval("(" + RowDisableStr + ")");
    }
    ChangeCellDisable("undefined", RowDisableObj);
}
function CellDataPropertyChange(rowid, colname, olddata, newdata) {
	if (colname == "OrderFirstDayTimesCode") {
        SetCellData(rowid, "OrderFirstDayTimes", newdata);
    }
    if (olddata == newdata) return false;
    if (colname == "OrderRecDep") {
        //不能直接调用OrderRecDepchangehandler(),因为在函数方法中有调用赋值OrderRecDep,会导致死循环;
        CheckCureItemConfig(rowid);
    }
    return true
}
function CheckPoisonUserReason_Update(rowid) {
    //var OrderAntibApplyRowid=GetCellData(Row,"OrderAntibApplyRowid")
    var OrderAntibApplyRowid = GetCellData(rowid, "OrderAntibApplyRowid");
    var UserReasonId = GetCellData(rowid, "UserReasonId");
    var ShowTabStr = GetCellData(rowid, "ShowTabStr");

    var OrderName = GetCellData(rowid, "OrderName");
    if ((ShowTabStr == "UserReason") && (UserReasonId == "")) {
        $.messager.alert("警告",OrderName + "  请填写使用目的!","info",function(){
            SetFocusCell(rowid, "UserReason");
        })
        return false;
    }
    if (ShowTabStr == "Apply,UserReason") {
        if (UserReasonId == "") {
            $.messager.alert("警告",OrderName + "  请填写使用目的!","info",function(){
	            SetFocusCell(rowid, "UserReason");
	        })
            return false;
        }
        if (OrderAntibApplyRowid == "") {
            $.messager.alert("警告",OrderName + "  请填写登记表!","info",function(){
	            SetFocusCell(rowid, "UserReason");
	        })
            return false;
        }
    }
    return true;
}
function CheckOrderStartDate(OrderStartDate, CurrDate) {
    if (CurrDate == "") return true;
    if (OrderStartDate == "") return true;
    if (GlobalObj.CurrentDischargeStatus == "B") {
        CurrDate = GlobalObj.DischargeDate
    }
    OrderStartDate = tkMakeServerCall("web.DHCPAAdmSheets", "ConvertDateFormat", OrderStartDate, PageLogicObj.defaultDataCache);
    CurrDate = tkMakeServerCall("web.DHCPAAdmSheets", "ConvertDateFormat", CurrDate, PageLogicObj.defaultDataCache);
    if (OrderStartDate < CurrDate) return false;
    return true;
}
//弹出窗口增加备注
function AddRemarkClickhandler(Row,CallBackFun) {
	new Promise(function(resolve,rejected){
    	if (Row < 1) {
	    	resolve(false);
	 	}else{
		 	var OEOrderNotes = GetCellData(Row, "OrderDepProcNote");
			 var OrderName = GetCellData(Row, "OrderName");
		 	var lnk="doc.ordnotes.hui.csp?FocusRowIndex=" + Row + "&OEOrderNotes=" + unescape(OEOrderNotes);
		 	websys_showModal({
				iconCls:'icon-w-edit',
				url:lnk,
				title:OrderName+$g(' 超过限制使用天数,请填写备注'),
				width:410,height:270,
				closable:true,
				callBackRetVal:"",
				onBeforeClose:function(){
					var result=websys_showModal("options").callBackRetVal;
					if ((result == "") || (result == "undefined")||(result == null)) {
				        $.messager.alert("提示", "请填写医嘱备注!","info",function(){
					        resolve(false);
					    });
				    } else {
					    SetCellData(Row, "OrderDepProcNote", result);
				        resolve(true);
				    }
				},
				CallBackFunc:function(result){
					websys_showModal("options").callBackRetVal=unescape(result);
					websys_showModal("close");
				}
			})
			websys_showModal('header').find('.panel-title').css({
				'white-space': 'nowrap',
				'text-overflow': 'ellipsis',
				'width': 'calc(100% - 35px)',
				'overflow': 'hidden'
			});
		}
	}).then(function(rtnvalue){
		CallBackFun(rtnvalue);
	})
}
function CheckOrderDoseLimit(Row) {
    var OrderName = GetCellData(Row, "OrderName");
    var OrderHiddenPara = GetCellData(Row, "OrderHiddenPara");
    var OrderDepProcNote = GetCellData(Row, "OrderDepProcNote");
    var OrderMaxDoseQty = mPiece(OrderHiddenPara, String.fromCharCode(1), 3);
    var OrderMaxDoseQtyPerDay = mPiece(OrderHiddenPara, String.fromCharCode(1), 4);
    var OrderLimitDays = mPiece(OrderHiddenPara, String.fromCharCode(1), 5);
    var OrderMaxDoseQtyPerOrder = mPiece(OrderHiddenPara, String.fromCharCode(1), 6);
    //$.messager.alert("警告",OrderHiddenPara);
    //判断没有设置参数就不用走后面的处理
    if ((OrderMaxDoseQty == '') && (OrderMaxDoseQtyPerDay == '') && (OrderLimitDays == '') && (OrderMaxDoseQtyPerOrder == '')) return true;

    var DrugFormRowid = GetCellData(Row, "OrderDrugFormRowid");
    var OrderDoseQty = GetCellData(Row, "OrderDoseQty");
    var OrderDoseUOMRowid = GetCellData(Row, "OrderDoseUOMRowid");
    var freq = GetCellData(Row, "OrderFreqFactor");
    var dur = GetCellData(Row, "OrderDurFactor");
    var Interval = GetCellData(Row, "OrderFreqInterval");

    //取得以基本单位为标准的剂量单位数量
    if (GlobalObj.CalEqDoseMethod != '') {
        var BaseDoseQty = cspRunServerMethod(GlobalObj.CalEqDoseMethod, OrderDoseUOMRowid, DrugFormRowid, OrderDoseQty,"BaseUom");
        //$.messager.alert("警告","OrderDoseUOMRowid:"+OrderDoseUOMRowid+" DrugFormRowid:"+DrugFormRowid+" OrderDoseQty:"+OrderDoseQty);
        //$.messager.alert("警告","BaseDoseQty:"+BaseDoseQty+" OrderMaxDoseQty:"+OrderMaxDoseQty+" OrderMaxDoseQtyPerDay:"+OrderMaxDoseQtyPerDay+" OrderMaxDoseQtyPerOrder:"+OrderMaxDoseQtyPerOrder);
        if ((BaseDoseQty != '') && (BaseDoseQty != 0)) {
            var BaseUomDesc="";
            var idoseqtystr=GetCellData(Row, "idoseqtystr");
            var ArrData = idoseqtystr.split(String.fromCharCode(2));
            if (ArrData.length > 0) {
                var ArrData1 = ArrData[ArrData.length-1].split(String.fromCharCode(1));
                BaseUomDesc = ArrData1[1];
            }
            if ((OrderMaxDoseQty != '') && (OrderMaxDoseQty != 0)) {
                if (parseFloat(BaseDoseQty) > parseFloat(OrderMaxDoseQty)) {
                    $.messager.alert("警告",OrderName+t['ExceedPHDoseQtyLimit']+":"+OrderMaxDoseQty+BaseUomDesc,"info",function(){
	                    SetFocusCell(Row, "OrderDoseQty");
	                });
                    return false;
                }
            }
            if ((OrderMaxDoseQtyPerDay != '') && (OrderMaxDoseQtyPerDay != 0)) {
                var BaseDoseQtyPerDay = parseFloat(BaseDoseQty) * parseFloat(freq);
                if ((parseFloat(BaseDoseQtyPerDay) > parseFloat(OrderMaxDoseQtyPerDay))) {
                    $.messager.alert("警告",OrderName+t['ExceedPHDoseQtyPerDayLimit']+":"+OrderMaxDoseQtyPerDay+BaseUomDesc,"info",function(){
	                    SetFocusCell(Row, "OrderFreq");
	                });
                    return false;
                }
            }
            if ((OrderMaxDoseQtyPerOrder != '') && (OrderMaxDoseQtyPerOrder != 0)) {
                var BaseDoseQtyPerOrder = parseFloat(BaseDoseQty) * parseFloat(freq) * parseFloat(dur);
                if ((parseFloat(BaseDoseQtyPerOrder) > parseFloat(OrderMaxDoseQtyPerOrder))) {
                    $.messager.alert("警告",t['ExceedPHDoseQtyPerOrderLimit'],"info",function(){
	                     SetFocusCell(Row, "OrderDur");
	                });
                    return false;
                }
            }
        }
        if ((OrderLimitDays != '') && (OrderLimitDays != 0)) {
            if ((parseFloat(dur) > parseFloat(OrderLimitDays)) && (OrderDepProcNote == '')) {
                AddRemarkClickhandler(Row);
                //dhcsys_alert(t['ExceedPHDurationLimit']);
                //SetFocusCell(Row, "OrderDepProcNote");
                //return false;
            }
        }
    }
    return true;
    if ((Interval != "") && (Interval != null)) {
        var convert = Number(dur) / Number(Interval)
        var fact = (Number(dur)) % (Number(Interval));
        if (fact > 0) { fact = 1; } else { fact = 0; }
        dur = Math.floor(convert) + fact;
    }
    var NumTimes = parseFloat(freq) * parseFloat(dur);
}
function CheckDrug_Update(Row) {
    //设置焦点位置:SetFocusCell(rowid,colname)
    //单元格取值：GetCellData(rowid, colname)//id为数字取表格单元格值 否则取 表单
    //单元格赋值：SetCellData(rowid,colname,data) //对于combo data 传value
    var OrderName = GetCellData(Row, "OrderName");
    var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
    var OrderSeqNo = GetCellData(Row, "id");
    var OrderInstrRowid = GetCellData(Row, "OrderInstrRowid");
    var OrderDoseQty = GetCellData(Row, "OrderDoseQty");
    var OrderFreqRowid = GetCellData(Row, "OrderFreqRowid");
    var OrderFreq = GetCellData(Row, "OrderFreq");
    var OrderDoseUOMRowid = GetCellData(Row, "OrderDoseUOMRowid");
    var OrderDoseUOM = GetCellData(Row, "OrderDoseUOM");
    var OrderDurRowid = GetCellData(Row, "OrderDurRowid");
    var OrderDur = GetCellData(Row, "OrderDur");
    var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
    var OrderInstrRowid = GetCellData(Row, "OrderInstrRowid");
    var OrderInstr = GetCellData(Row, "OrderInstr");
    var OrderPackQty = GetCellData(Row, "OrderPackQty");
    var OrderPHForm = GetCellData(Row, "OrderPHForm");
    var PHPrescType = GetCellData(Row, "OrderPHPrescType");
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
    var OrderBillTypeRowid = GetCellData(Row, "OrderBillTypeRowid");
    var OrderType = GetCellData(Row, "OrderType");
    var OrderRecDepRowid = GetCellData(Row, "OrderRecDepRowid");
    var OrderUsableDays = GetCellData(Row, "OrderUsableDays");
    var OrderFirstDayTimes = GetCellData(Row, "OrderFirstDayTimes");
    var OrderPriorDesc = GetCellData(Row, "OrderPrior")

    var CNOrderDur = "";
    var OrderInstrGroupArr = new Array();
    if (OrderMasterSeqNo != "") {
        if (OrderMasterSeqNo == OrderSeqNo) {
			ClearOrderMasterSeqNo(Row);
        } else {
            var ret = CheckMasterSeqNo(OrderMasterSeqNo);
            if (!ret) {
                $.messager.alert("警告",OrderName + t['Err_SeqNo'],"info",function(){
	                SetFocusCell(Row, "OrderMasterSeqNo");
	            });
                //EditRow(Row);
                return false;
            }
        }
    }
    var CheckWYInstr = IsWYInstr(OrderInstrRowid);
    if (((OrderDoseQty == '') || (parseFloat(OrderDoseQty) == 0) || (isNumber(OrderDoseQty) == false)) && (!CheckWYInstr)) {
        $.messager.alert("警告",OrderName + t['NO_DoseQty'],"info",function(){
	        SetFocusCell(Row, "OrderDoseQty");
	    });
        //EditRow(Row);
        return false;
    }
	if((parseFloat(OrderDoseQty) < 0) && (!CheckWYInstr)) {
        $.messager.alert("警告",OrderName + "剂量不能为负数!","info",function(){
	        SetFocusCell(Row, "OrderDoseQty");
	    });
        //EditRow(Row);
        return false;
    }
    //$.messager.alert("警告","001");
    if ((OrderFreqRowid == '') || (OrderFreq == "")) {
        //EditRow(Row);
        $.messager.alert("提示信息", OrderName + t['NO_Frequence'], "warning", function() { SetFocusCell(Row, "OrderFreq"); });
            
        return false;
    }

    if (((OrderDoseUOMRowid == '') || (OrderDoseUOM == "")) && (!CheckWYInstr)) {
        //EditRow(Row);
        $.messager.alert("提示信息", OrderName + t['NO_DoseUOM'], "warning", function() { SetFocusCell(Row, "OrderDoseUOM"); });
          
        return false;
    }
    if (((OrderDurRowid == '') || (OrderDur == '')) && (!CheckWYInstr) && (OrderPriorRowid != GlobalObj.LongOrderPriorRowid)) {
        //EditRow(Row);
        $.messager.alert("提示信息", OrderName + t['NO_Duration'], "warning", function() { SetFocusCell(Row, "OrderDur"); });
         
        return false;
    }
    if ((OrderInstrRowid == '') || (OrderInstrRowid == '')) {
        //EditRow(Row);
        $.messager.alert("提示信息", OrderName + t['NO_Instr'], "warning", function() { SetFocusCell(Row, "OrderInstr"); });
         
        return false;
    }

    //判断药品剂量
    if (CheckOrderDoseLimit(Row) == false) {
        return false;
    }
    if (GlobalObj.PAAdmType != "I") {
		//按用法分处方
		if (GlobalObj.PrescByInstr == 1) {
			var InstrGroupCode = cspRunServerMethod(GlobalObj.GetInstrGroupCodeMethod, OrderInstrRowid);
			if (InstrGroupCode != "") {
				var PrescName = PHPrescType + '^' + OrderBillTypeRowid + '^' + InstrGroupCode + "^" + OrderInstr;
				var FindPresc = false;
				for (var j = 0; j <= OrderInstrGroupArr.length - 1; j++) {
					var TempName = mPiece(OrderInstrGroupArr[j], "!", 0)
					if (TempName == PrescName) {
						PrescCount = eval(mPiece(OrderInstrGroupArr[j], "!", 1)) + 1
						OrderInstrGroupArr[j] = PrescName + "!" + PrescCount;
						FindPresc = true;
					}
				}
				if (!FindPresc) {
					OrderInstrGroupArr[OrderInstrGroupArr.length] = PrescName + "!" + 1;
				}
			}
		}
		if (OrderType == "R") {
			var InsurFlag = cspRunServerMethod(GlobalObj.GetInsurFlagMethod, OrderBillTypeRowid, GlobalObj.PAAdmType);
			if (OrderUsableDays == "") OrderUsableDays = 0;
			if ((InsurFlag == 1) && (parseFloat(OrderUsableDays) > 200)) {
				$.messager.alert("提示信息", OrderName + t['InsurOPUsableDaysLimit'], "warning", function() { SetFocusCell(Row, "OrderName"); });
	 
				return false;
			}
		}
    }
    return { OrderInstrGroupArr: OrderInstrGroupArr };
}

function CheckMasterSeqNo(MasterSeqNo) {
    try {
        /*//09-04-17 郭荣勇 改成添加和删除拼串CheckMasterNoStr来加快审查速度
        var objtbl=document.getElementById('tUDHCOEOrder_List_Custom');
        var rows=objtbl.rows.length;
        for (var i=1; i<rows; i++){
            var Row=GetRow(i);
            var OrderName=GetCellData("OrderName",Row);
            var OrderItemRowid=GetCellData("OrderItemRowid",Row);
            var OrderARCIMRowid=GetCellData("OrderARCIMRowid",Row);
        var OrderSeqNo=GetCellData("OrderSeqNo",Row);
            if ((OrderARCIMRowid!="")&&(OrderItemRowid=="")){
                if (OrderSeqNo==MasterSeqNo){return true}
            }
        }
        var MasterSeqNo="!"+MasterSeqNo+"!";
        if (CheckMasterNoStr.indexOf(MasterSeqNo)!=-1) return true;
    */
    } catch (e) { $.messager.alert("警告", e.message); }
    return true;
}

function CheckNotDrug_Update(Row) {
    var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
    var OrderName = GetCellData(Row, "OrderName");
    if ((OrderPriorRowid == GlobalObj.OMOrderPriorRowid) || (OrderPriorRowid == GlobalObj.OMSOrderPriorRowid)) {
        $.messager.alert("提示信息", OrderName + t['OMOrderPriorNotAllow'], "warning", function() { SetFocusCell(Row, "OrderName"); });
          
        return false;
    }
    //自定价医嘱
    var OrderType = GetCellData(Row, "OrderType");
    if (OrderType == "P") {
        var OrderPrice = GetCellData(Row, "OrderPrice");
        OrderPrice = $.trim(OrderPrice);
        if (OrderPrice == '') {
            EditRow(Row);
            $.messager.alert("提示信息", OrderName + t['NO_OrderPrice'], "warning", function() { SetFocusCell(Row, "OrderPrice"); });
            var StyleConfigObj = { OrderPrice: true };
            ChangeRowStyle(Row, StyleConfigObj)
            PageLogicObj.FocusRowIndex = Row;
            return false;
        } else {
            if ((!isNumber(OrderPrice)) || (parseFloat(OrderPrice) == 0)) {
                $.messager.alert("提示信息", "自定义价格的医嘱【" + OrderName + "】价格不是有效数字", "warning", function() { SetFocusCell(Row, "OrderPrice"); });
        
                PageLogicObj.FocusRowIndex = Row;
                return false;
            }
        }
    }
    //检验医嘱
    if (OrderType == "L") {
        var OrderLabSpecRowid = GetCellData(Row, "OrderLabSpecRowid");
        if (OrderLabSpecRowid == '') {
            $.messager.alert("警告",OrderName + t['NeedLabSpec'],"info",function(){
	            SetFocusCell(Row, "OrderLabSpec");
	        });
            //$.messager.alert("提示信息", OrderName + t['NeedLabSpec'], "warning", function() { SetFocusCell(Row, "OrderLabSpec"); });
            return false;
        }
    }
	var OrderDoseQty=GetCellData(Row, "OrderDoseQty");
	if ((OrderDoseQty != '')&&(isNumber(OrderDoseQty) == false))  {
        $.messager.alert("警告",OrderName + t['NO_DoseQty'],"info",function(){
	         SetFocusCell(Row, "OrderDoseQty");
	    });
        //EditRow(Row);
       
        return false;
    }
    if ((OrderDoseQty!="")&&(parseFloat(OrderDoseQty) < 0) ) {
        $.messager.alert("警告",OrderName + "剂量不能为负数!","info",function(){
	        SetFocusCell(Row, "OrderDoseQty");
	    });
        //EditRow(Row);
        return false;
    }
    return true;
}
function CheckKSS_Update(Row) {
    var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
    var OrderPoisonCode = GetCellData(Row, "OrderPoisonCode");
    var OrderAntibApplyRowid = GetCellData(Row, "OrderAntibApplyRowid");

    if ((OrderPriorRowid == GlobalObj.ShortOrderPriorRowid) && (OrderPoisonCode.indexOf("KSS") > -1)) {
        //加一个条件（申请单为未审核给与提示）
        if ((OrderAntibApplyRowid != "") && (OrderAntibApplyRowid != "undefined")) {
            var AppStatusFlag = tkMakeServerCall("web.DHCDocAntiCommon", "GetAntibioSta", OrderAntibApplyRowid)
            if (AppStatusFlag == 0) {
                $.messager.alert("警告", "请上级医师24小时内审核", "warning", function() { SetFocusCell(Row, "OrderName"); });
            }
        }
    }
    return true;
}
//******************** 对于数据处理的函数  放后面 *****************//
//结束编辑  数据检查
//此处为医嘱审核时的检查,主要检查在录入过程中会随时变化,在录入无法监控的一些审查
function CheckBeforeUpdate() {
    //知识库
    var RtnStr = CheckLibPhaFunction("C", "", "Y")
    if (!RtnStr) { return false }
    return true;
}
//抗菌药物联合用药放在最后做检查QP
function CheckBeforeSaveToAnti(callBackFun) {
    var rowids = $('#Order_DataGrid').getDataIDs();
    new Promise(function(resolve,rejected){
		//抗菌药物联用控制
    	var combinedFlag=tkMakeServerCall("DHCAnt.Base.MainConfigExcute", "GetValueByMCGCode", "SCKJ", session['LOGON.HOSPID']);
    	if (combinedFlag=="1") {
	    	CheckAntCombined(rowids,resolve)
	    }else{
		    resolve(true);
		}
	}).then(function(rtn){
		if (!rtn) {
			callBackFun(false);
		}else{
			//抗菌越级使用消息提示 QP 20170814
	    	DHCANT.sendEmergencyMsg(rowids);
	    	//增加越级提示检查
		    var rowsLength = rowids.length;
		    for (var i = 0; i < rowsLength; i++) {
		        CheckKSS_Update(rowids[i]);
		    }
			callBackFun(true);
		}
	})
}
//临床路径检查，路径外医嘱填写变异
function CPWCheck(callBackFun) {
	new Promise(function(resolve,rejected){
		if (GlobalObj.SupplementMode==1){
		    resolve(true);
		}else{
			var EpisodeID = GlobalObj.EpisodeID;
		    var ArcimIDs = "";
		    var rowids = $('#Order_DataGrid').getDataIDs();
		    for (var i = 0; i < rowids.length; i++) {
		        var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
		        ArcimIDs = ArcimIDs + OrderARCIMRowid + "^";
		    }
		    if (!ArcimIDs) {
			    resolve(true);
			}else{
				//checkOrdItemToVar(EpisodeID,ArcimIDs,resolve);
				var CPWInputObj={
					EpisodeID:EpisodeID,
					ArcimIDs:ArcimIDs
				}
				Common_ControlObj.BeforeUpdate("CPWCheck",CPWInputObj,resolve);
			}
		}
	}).then(function(SuccessFlag){
		callBackFun(SuccessFlag);
	})
}
function xItem_lookuphandler(e) {
	return false;
}
//频次查询
function PHCFRDesc_lookuphandler(e) {
    var obj = websys_getSrcElement(e);
    var key = websys_getKey(e);
    var type = websys_getType(e);
    if (key != 13 && type != 'dblclick') {
        return;
    }
    var rowid = "";
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    var OrderPriorRowid=GetCellData(rowid, "OrderPriorRowid");
    var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
    if (OrderPriorRemarks=="ONE") {OrderPriorRowid=GlobalObj.LongOrderPriorRowid}
	return false;
}
//频次选择
function FrequencyLookUpSelect(value,rowid,callBackFun) {
	var type = "";
	if (window.event) type = websys_getType(window.event);
	if (typeof rowid=="undefined"){
		rowid = "";
	}
    if (rowid==""){
	    if (this.id.indexOf("_") > 0) {
	        rowid = this.id.split("_")[0];
	    }
	}
    var Id = "";
    if ($.isNumeric(rowid) == true) {
        Id = rowid + '_OrderFreq';
    } else {
        Id = 'OrderFreq';
    }
    $("#"+Id).removeClass("clsInvalid");
    var Split_Value = value.split("^");
    var OrderFreq = Split_Value[0];
    var OrderFreqFactor = Split_Value[2];
    var OrderFreqInterval = Split_Value[3];
    var OrderFreqRowid = Split_Value[4];
    var OrderFreqDispTimeStr = Split_Value[5];
    var WeekFlag = Split_Value[6];
    var NoDelayExe = Split_Value[7];
    var FreeTimeFreqFlag = Split_Value[8];
    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    var OldPriorRowid = OrderPriorRowid
    //原序号 现行ID
    var OrderSeqNo = GetCellData(rowid, "id");
    SetCellData(rowid, "OrderFreq", OrderFreq);
    SetCellData(rowid, "OrderFreqFactor", OrderFreqFactor);
    SetCellData(rowid, "OrderFreqInterval", OrderFreqInterval);
    SetCellData(rowid, "OrderFreqRowid", OrderFreqRowid);
    SetCellData(rowid, "OrderNurseExecLinkDispTimeStr", "");
    var DurChangeFlag=0;
    DHCDocUseCount(OrderFreqRowid, "User.PHCFreq");
    var OrderName=GetCellData(rowid, "OrderName");
    var LinkedMasterOrderRowid=GetCellData(rowid, "LinkedMasterOrderRowid");
    if (LinkedMasterOrderRowid) {
	    var oneItem = cspRunServerMethod(GlobalObj.GetVerifiedOrder, LinkedMasterOrderRowid);
	    var VerifiedOrderArr = oneItem.split("^");
		var OrderItemVerifiedObj=GetVerifiedOrderObjObj(VerifiedOrderArr);
	}
	var MasterOrderPriorRowid="",MasterOrderPrior="";
    new Promise(function(resolve,rejected){
	    var OrderFreqDispTimeStr="",FreqWeekDesc="";
	    if (WeekFlag=="Y"){
		    (function(callBackFunExec){
			    new Promise(function(resolve,rejected){
					GetOrderFreqWeekStr(OrderFreqRowid,OrderFreqDispTimeStr,OrderName,resolve);
				}).then(function(OrderFreqWeekInfo){
					var OrderFreqDispTimeStr=mPiece(OrderFreqWeekInfo, "^", 0);
					if (OrderFreqDispTimeStr==""){
						ClearOrderFreq(rowid);
			            $.messager.alert("提示","周频次请务必选择使用周数!");
			            return;
					}
					var OrderFreqWeekDesc=mPiece(OrderFreqWeekInfo, "^", 1);
					var CalOrderStartDateStr=mPiece(OrderFreqWeekInfo, "^", 2);
					SetCellData(rowid, "OrderFreqDispTimeStr", OrderFreqDispTimeStr);
					OrderFreq=OrderFreq+" "+OrderFreqWeekDesc;
					SetCellData(rowid,"OrderFreq",OrderFreq)
					//周频次不再修改医嘱开始日期
					//SetCellData(rowid,"OrderStartDate",CalOrderStartDateStr);
					callBackFunExec();
				})
			})(resolve);
		}else if (FreeTimeFreqFlag=="Y"){
			(function(callBackFunExec){
				//不规则分发时间
			    new Promise(function(resolve,rejected){
					GetOrderFreqFreeTimeStr(OrderFreqRowid,OrderFreqDispTimeStr,OrderName,resolve,OrderItemVerifiedObj);
				}).then(function(OrderFreqFreeTimeInfo){
					var OrderFreqDispTimeStr=mPiece(OrderFreqFreeTimeInfo, "^", 0);
					if (OrderFreqDispTimeStr==""){
						ClearOrderFreq(rowid);
			            $.messager.alert("提示","不规则分发时间频次请务必选择分发时间!");
			            return;
					}
					var OrderFreqFactor=OrderFreqDispTimeStr.split(String.fromCharCode(1)).length;
					var OrderFreqWeekDesc=mPiece(OrderFreqFreeTimeInfo, "^", 1);
					SetCellData(rowid, "OrderFreqDispTimeStr", OrderFreqDispTimeStr);
					OrderFreq=OrderFreq+" "+OrderFreqWeekDesc;
					SetCellData(rowid,"OrderFreq",OrderFreq);
					SetCellData(rowid, "OrderFreqFactor", OrderFreqFactor);
					callBackFunExec();
				})
			})(resolve);
		}else{
			SetCellData(rowid, "OrderFreqDispTimeStr", OrderFreqDispTimeStr);
			resolve();
		}
    }).then(function(){
	    return new Promise(function(resolve,rejected){
			//
		    if((OrderItemVerifiedObj)&&
				(OrderItemVerifiedObj.LinkedMasterOrderFreFactor>1)&&
				(OrderFreqRowid!="")&&
					((OrderItemVerifiedObj.LinkedMasterOrderFreqIntervalTimeFlag!='Y')||
					((OrderItemVerifiedObj.LinkedMasterOrderFreqIntervalTimeFlag=='Y')&&(OrderItemVerifiedObj.LinkedMasterOrderFreqIntervalUnit=="H")))
				){
			    (function(callBackFunExec){
					//护士补录医嘱关联主医嘱分发时间
				    new Promise(function(resolve,rejected){
					    var OrderFreqFactor=GetCellData(rowid, "OrderFreqFactor");
					    var OrderFreqDispTimeStr=GetCellData(rowid, "OrderFreqDispTimeStr");
					    if (parseFloat(OrderFreqFactor) > parseFloat(OrderItemVerifiedObj.LinkedMasterOrderFreFactor)) {
						    ClearOrderFreq(rowid);
				            $.messager.alert("提示",$g("补录医嘱频次分发次数")+" "+OrderFreqFactor+" "+$g("不能大于主医嘱频次分发次数")+"："+OrderItemVerifiedObj.LinkedMasterOrderFreFactor+" !");
				            return;
						}else if(OrderFreqFactor == OrderItemVerifiedObj.LinkedMasterOrderFreFactor){
							if (OrderItemVerifiedObj.LinkedMasterOrderFreqDispTimeStr) {
								var OrderNurseExecLinkDispTimeInfo=CalOrderFreqExpInfo(OrderItemVerifiedObj.LinkedMasterOrderFreqDispTimeStr);
								OrderNurseExecLinkDispTimeInfo=mPiece(OrderNurseExecLinkDispTimeInfo, "^", 1);
							}else{
								var OrderNurseExecLinkDispTimeInfo=tkMakeServerCall("web.DHCDocOrderCommon","GetIPFreqDispTimeStr",OrderItemVerifiedObj.LinkedMasterOrderFreRowId) 
								OrderNurseExecLinkDispTimeInfo=OrderNurseExecLinkDispTimeInfo.replace(/,/g, "|")
							}
							OrderNurseExecLinkDispTimeInfo=tkMakeServerCall("web.DHCOEOrdItem", "FormFreqFreeTimeHtmlToLogical",OrderNurseExecLinkDispTimeInfo);
							resolve(OrderNurseExecLinkDispTimeInfo);
						}else{
							var OrderNurseLinkOrderRowid = GetCellData(rowid, "LinkedMasterOrderRowid");
					    	GetOrderNurseExecLinkDispTimeStr(OrderName,OrderFreqRowid,OrderFreqDispTimeStr,OrderNurseLinkOrderRowid,resolve)
						}
					}).then(function(OrderNurseExecLinkDispTimeInfo){
						if (OrderNurseExecLinkDispTimeInfo==""){
							ClearOrderFreq(rowid);
				            $.messager.alert("提示","补录医嘱频次和主医嘱不一致请务必选择关联分发时间!");
				            return;
						}
						var OrderNurseExecLinkDispTimeStr=mPiece(OrderNurseExecLinkDispTimeInfo, "^", 0);
						SetCellData(rowid,"OrderNurseExecLinkDispTimeStr",OrderNurseExecLinkDispTimeStr);
						callBackFunExec();
					})
				})(resolve);
			}else{
				resolve();
			}
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
		    var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
		    if ((GlobalObj.PAAdmType == "I") && (OrderPriorRowid != GlobalObj.OutOrderPriorRowid)&&(OrderPriorRemarks!="ONE")) {
		        if ((OrderFreqRowid == GlobalObj.STFreqRowid) || (OrderFreqRowid == GlobalObj.ONCEFreqRowid)) {
		            //判断当前可以开医嘱
		            var check = CheckNowOrderPrior(rowid, GlobalObj.ShortOrderPriorRowid);
		            if (check == true) {
		                SetCellData(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
		                SetCellData(rowid, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
		                MasterOrderPriorRowid = GlobalObj.ShortOrderPriorRowid;
		                MasterOrderPrior = "临时医嘱";
		            } else {
		                ClearOrderFreq(rowid)
		                $.messager.alert("提示","当前医嘱类型不允许改变频次为" + OrderFreq);
		                return;
		            }

		        } else {
		            var check = CheckNowOrderPrior(rowid, GlobalObj.LongOrderPriorRowid);
		            if (check == true) {
		                SetCellData(rowid, "OrderPrior", GlobalObj.LongOrderPriorRowid);
		                SetCellData(rowid, "OrderPriorRowid", GlobalObj.LongOrderPriorRowid);
		                MasterOrderPriorRowid = GlobalObj.LongOrderPriorRowid;
		                MasterOrderPrior = "长期医嘱";
		            } else {
		                ClearOrderFreq(rowid);
						$.messager.alert("提示","当前医嘱类型不允许改变频次为" + OrderFreq)
		                return;
		            }
		        }
		    }

		    if ((OrderPriorRowid == GlobalObj.OMSOrderPriorRowid) && (OrderFreqRowid == GlobalObj.STFreqRowid)) {
		        var check = CheckNowOrderPrior(rowid, GlobalObj.OMOrderPriorRowid);
		        if (check == true) {
		            SetCellData(rowid, "OrderPrior", GlobalObj.OMOrderPriorRowid);
		            SetCellData(rowid, "OrderPriorRowid", GlobalObj.OMOrderPriorRowid);
		            MasterOrderPriorRowid = GlobalObj.OMOrderPriorRowid;
		            MasterOrderPrior = "临时医嘱";
		        } else {
		            ClearOrderFreq(rowid);
		            $.messager.alert("提示","当前医嘱类型不允许改变频次为" + OrderFreq);
		            return;
		        }
		    }

		    if ((GlobalObj.PAAdmType == "I") && (OrderFreqRowid != GlobalObj.STFreqRowid)) {
		        //即刻医嘱只有ST的用法?A非ST就改成临时医嘱?A因为在计费时即刻医嘱只算一次
		        if (OrderPriorRowid == GlobalObj.STATOrderPriorRowid) {
		            var check = CheckNowOrderPrior(rowid, GlobalObj.ShortOrderPriorRowid);
		            if (check == true) {
		                SetCellData(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
		                SetCellData(rowid, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
		                MasterOrderPriorRowid = GlobalObj.ShortOrderPriorRowid;
		                MasterOrderPrior = "临时医嘱";
		            } else {
		                ClearOrderFreq(rowid);
		                $.messager.alert("提示","当前医嘱类型不允许改变频次为" + OrderFreq);
		                return;
		            }
		        }
		    }
		    var OrderVirtualtLong=GetCellData(rowid, "OrderVirtualtLong");
			var OrderPriorRemarksRowId=GetCellData(rowid, "OrderPriorRemarksRowId");
		    if ((parseFloat(OrderFreqInterval)>0)&&((GlobalObj.PAAdmType != "I")||(OrderPriorRemarksRowId=='ONE'))&&(OrderVirtualtLong!="Y")){
		        var rtn=tkMakeServerCall("web.DHCDocOrderCommon", "GetFirstDurByWeekFreq", OrderFreqInterval,OrderFreqRowid);
		        var OrderDurRowid=rtn.split(",")[0];
		        var OrderDur=rtn.split(",")[1];
		        var OrderDurFactor=rtn.split(",")[3];
		        var CurrentOrderDurFactor=GetCellData(rowid, "OrderDurFactor");
		        if ((OrderDurRowid!="")&&((+CurrentOrderDurFactor)<(+OrderDurFactor))){
		            SetCellData(rowid, "OrderDur", OrderDur)
		            SetCellData(rowid, "OrderDurRowid", OrderDurRowid);
		            SetCellData(rowid, "OrderDurFactor", OrderDurFactor);
		            DurChangeFlag=1;
		        }
		    }
		    var PriorRowid = GetCellData(rowid, "OrderPriorRowid");
		    if (OldPriorRowid != PriorRowid) {
			    OrderPriorchangeCommon(rowid,OldPriorRowid,PriorRowid,resolve);
			}else{
				resolve();
			}
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			SetPackQty(rowid);
			var MasterOrderStartDateStr = GetCellData(rowid, "OrderStartDate");
			var OrderFreqRowid=GetCellData(rowid, "OrderFreqRowid");
			var OrderFreq=GetCellData(rowid, "OrderFreq");
			var OrderFreqFactor=GetCellData(rowid, "OrderFreqFactor");
			var OrderFreqInterval=GetCellData(rowid, "OrderFreqInterval");
			var OrderFreqDispTimeStr=GetCellData(rowid, "OrderFreqDispTimeStr");
		    ChangeLinkOrderFreq(OrderSeqNo,MasterOrderPriorRowid,MasterOrderPrior,OrderFreqRowid,OrderFreq,OrderFreqFactor,OrderFreqInterval,OrderFreqDispTimeStr,MasterOrderStartDateStr,resolve);
		});
	}).then(function(){
		return new Promise(function(resolve,rejected){
			var OrderFreqRowid=GetCellData(rowid, "OrderFreqRowid");
			var OrderFreq=GetCellData(rowid, "OrderFreq");
			var OrderFreqFactor=GetCellData(rowid, "OrderFreqFactor");
			var OrderFreqInterval=GetCellData(rowid, "OrderFreqInterval");
			var OrderFreqDispTimeStr=GetCellData(rowid, "OrderFreqDispTimeStr");
			var MasterOrderStartTime = "",
		        MasterOrderStartDate = "";
		    if (OrderFreqRowid == GlobalObj.STFreqRowid) {
		        var CurrDateTime = cspRunServerMethod(GlobalObj.GetCurrentDateTimeMethod, PageLogicObj.defaultDataCache, "1");
		        var CurrDateTimeArr = CurrDateTime.split("^");
                //tanjishan 20210712如果在凌晨接近跨天的时间去修改频次，容易造成开始时间提前一天的问题。
		        MasterOrderStartDate = CurrDateTimeArr[0];    //GetCellData(rowid, "OrderStartDate").split(" ")[0];
		        MasterOrderStartTime = CurrDateTimeArr[1];
		        var datetiem = MasterOrderStartDate + " " + MasterOrderStartTime;
		        SetCellData(rowid, "OrderStartDate", datetiem);
		    }
		    //频次->疗程监测
		    FreqDurChange(rowid);
		    
		    SetOrderFirstDayTimes(rowid);
			//同步首日次数
			ChangeFirstDayTimes(rowid,true,resolve);
		})
	}).then(function(){
		if (DurChangeFlag==1){
			var OrderDurRowid=GetCellData(rowid, "OrderDurRowid");
			var OrderDur=GetCellData(rowid, "OrderDur");
			var OrderDurFactor=GetCellData(rowid, "OrderDurFactor");
			ChangeLinkOrderDur(OrderSeqNo, OrderDurRowid, OrderDur, OrderDurFactor);
		}
		SetScreenSum();
		var type = "";
		if (window.event) type = websys_getType(window.event);
		if (type != 'change'){
			var IdOrderDur = rowid + "_" + "OrderDur";
			var objDur = document.getElementById(IdOrderDur);
			var IdOrderPackQty = rowid + "_" + "OrderPackQty";
			var objPackQty = document.getElementById(IdOrderPackQty);
			if ((objDur.disabled)&&(objPackQty.disabled)){
				setTimeout(function(){
					setTimeout(function(){
						$("#"+rowid+"_OrderFreq").lookup('hidePanel');
					})
					var RowNext = GetNextRowId(rowid);
					if (RowNext==rowid){
						Add_Order_row();
						RowNext=parseInt(RowNext)+1;
					}
					SetFocusCell(RowNext, "OrderName");
					return websys_cancel();
				})
			}else{
				setTimeout(function(){
					setTimeout(function(){
						$("#"+rowid+"_OrderFreq").lookup('hidePanel');
					})
					var OrderInstrRowid = GetCellData(rowid, "OrderInstrRowid");
					var OrderDoseQty=GetCellData(rowid, "OrderDoseQty");
					if ((OrderDoseQty=="")&&(!IsWYInstr(OrderInstrRowid))) {
						var JumpAry = ['OrderDoseQty','OrderDur', 'OrderPackQty'];
					}else{
						var JumpAry = ['OrderDur', 'OrderPackQty'];
					}
					var JumpCellName=CellFocusJump(rowid, JumpAry, true);
				})
			}
		}else{
			if (PageLogicObj.LookupPanelIsShow==1) {
				setTimeout(function(){
					$("#"+rowid+"_OrderFreq").lookup('hidePanel');
				})
			}
		}
	    XHZY_Click();
		GetBindOrdItemTip(rowid);
	    if (callBackFun) callBackFun();
	    else  return websys_cancel();
	})
}
function PHCINDesc_lookuphandler(e) {
    var obj = websys_getSrcElement(e);
    var key = websys_getKey(e);
    var type = websys_getType(e);
   
    if (key != 13 && type != 'dblclick') {
        return;
    }
    var rowid = "";
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
	return false;
}
//用法选择
function InstrLookUpSelect(value,rowid) {
    try {
	    if (typeof rowid=="undefined"){
			var rowid = "";
		}
		if (rowid==""){
	        if (this.id.indexOf("_") > 0) {
	            rowid = this.id.split("_")[0];
	        }
        }
        var Id = "";
        if ($.isNumeric(rowid) == true) {
            Id = rowid + '_OrderInstr';
        } else {
            Id = 'OrderInstr';
        }
        var obj = document.getElementById(Id);
        $(obj).removeClass("clsInvalid");
        //if (obj) obj.className = '';
        var Split_Value = value.split("^");
        var OrderInstrRowid = Split_Value[0];
        var OrderInstr = unescape(Split_Value[1]);
        var OrderInstrCode = Split_Value[2];
        if (Split_Value.length == 4) { rowid = Split_Value[3] }
        var Split_Value = value.split("^");
        var OrderSeqNo = GetCellData(rowid, "id");
        var OrderInstr = unescape(Split_Value[1]);
        var OrderInstrRowid = Split_Value[0];
        var OrderInstrCode = Split_Value[2];
        if ((GlobalObj.ForbidDosingInstr!="")&&(GlobalObj.ForbidDosingInstr.indexOf("^"+OrderInstrRowid+"^")>-1)) return false;
        var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
        //长期医嘱不能开皮试用法
        if (GlobalObj.SkinTestInstr != "") {
	        var Instr = "^" + OrderInstrRowid + "^"
            if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
				$(".messager-button a").click();
	            if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid){
		            $.messager.alert("提示","长期医嘱不能选皮试用法!","info",function(){
			            SetCellData(rowid, "OrderInstr", "");
		            	SetCellData(rowid, "OrderInstrRowid", "");
		            	SetFocusCell(rowid, "OrderInstr");
			        });
		            return false;
		        }
	        }
	    }
        var obj = document.getElementById('OrderInstrz' + rowid);
        if (obj) {
            obj.value = OrderInstr;
            $(obj).removeClass("clsInvalid");
            //obj.className = '';
        }
        SetCellData(rowid, "OrderInstr", OrderInstr);
        var OrderType = GetCellData(rowid, "OrderType");
        //SetCellData(rowid,"OrderInstrRowid",OrderInstrRowid); 
		var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    	var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
    	new Promise(function(resolve,rejected){
	        //如果有皮试用法自动选上皮试标志
	        if (GlobalObj.SkinTestInstr != "") {
	            var Instr = "^" + OrderInstrRowid + "^"
	            if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")&&(OrderType =="R")) { //&&(NeedSkinTestINCI=="Y")
	                /*var ActionRowid=GetCellData(rowid, "OrderActionRowid");
	                var ActionCode = GetOrderActionCode(ActionRowid);
	                if ((ActionCode=="YY")||(ActionCode=="")){
	                    SetCellData(rowid, "OrderSkinTest", true);
	                }*/
	                SetCellData(rowid, "OrderActionRowid","");
	                SetCellData(rowid, "OrderAction","");
	                //如果是成组医嘱置皮试用法，只把子医嘱的第一条置皮试勾选，剩余逻辑在ChangeLinkOrderInstr中处理
	                var RowArry = GetSeqNolist(rowid);
	                if (RowArry.length==0){
	               		SetCellData(rowid, "OrderSkinTest", true);
	                }else{
		            	SetCellData(rowid, "OrderSkinTest", false);   
		            }
		            if ((GlobalObj.DisableOrdSkinChange!="1")&&(NeedSkinTestINCI!="Y")){
		                //OrderSkinTest可以编辑,主要是成组医嘱需要医生手工选中溶媒的皮试标识
		                var styleConfigObj = { OrderSkinTest: true, OrderAction: false }
		                ChangeCellDisable(rowid, styleConfigObj);
	                }
	                if ((OrderPriorRowid != GlobalObj.ShortOrderPriorRowid)&&(GlobalObj.CFSkinTestPriorShort == 1)) {
	                    if (GlobalObj.OrderPriorContrlConfig == 1) {
	                        SetColumnList(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid + ":" + $g("临时医嘱"));
	                        SetCellData(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
	                        SetCellData(rowid, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
	                        SetCellData(rowid, "OrderPriorStr", GlobalObj.ShortOrderPriorRowid + ":" + $g("临时医嘱"));
	                    }
	                    SetCellData(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
	                    SetCellData(rowid, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
	                    (function(callBackFunExec){
		                    new Promise(function(resolve,rejected){
			                    OrderPriorchangeCommon(rowid,OrderPriorRowid,GlobalObj.ShortOrderPriorRowid,resolve);
			                }).then(function(){
			                    //调用OrderPriorchangeCommon方法会改变光标焦点到用法位置
			                    SetFocusCell(rowid, "OrderAction");
			                    callBackFunExec();
				            })
		                })(resolve);
	                }else{
		                resolve();
		            }
	            } else {
	                //修改用法 不改变皮试勾选状态--tanjishan手工切换用法的情况下，如果从皮试修改为治疗，皮试勾选去不掉的问题
	                /*SetCellData(rowid,"OrderSkinTest",false);*/
	                var ActionRowid=GetCellData(rowid, "OrderActionRowid");
	                var ActionCode = GetOrderActionCode(ActionRowid);
	                /*
	                if ((NeedSkinTestINCI=="Y")||(ActionCode!="")){
		                var styleConfigObj={OrderSkinTest:false,OrderAction:true}
		            }else{
			            var styleConfigObj={OrderSkinTest:true,OrderAction:true}
			        }*/
			        if ((GlobalObj.DisableOrdSkinChange=="1")||(NeedSkinTestINCI=="Y")){
				        var styleConfigObj={OrderSkinTest:false,OrderAction:false};
			        }else if (OrderType =="R"){
			        	var styleConfigObj={OrderSkinTest:true,OrderAction:true};
			        }
	                ChangeCellDisable(rowid,styleConfigObj);
	                resolve();
	            }
	        }else{
		        resolve();
		    }
    	}).then(function(){
	    	SetCellData(rowid, "OrderInstr", OrderInstr);
	        SetCellData(rowid, "OrderInstrRowid", OrderInstrRowid);
	        DHCDocUseCount(OrderInstrRowid, "User.PHCInstruc");
	        if ((GlobalObj.DrippingSpeedInstr).indexOf("^"+OrderInstrRowid+"^")>=0) {
		        //行流速单位为空则取医生站设置-用法设置—用法扩展设置输液用法默认流速单位
		        //var OrderFlowRateUnitRowId=GetCellData(rowid, "OrderFlowRateUnitRowId");
		        //if (OrderFlowRateUnitRowId=="") {
			        var InstrDefSpeedRateUnit=GetInstrDefSpeedRateUnit(OrderInstrRowid)
			        if((typeof InstrDefSpeedRateUnit=="object")&&(InstrDefSpeedRateUnit["id"])){
				        var OrderFlowRateUnitRowId=InstrDefSpeedRateUnit["id"];
				        SetCellData(rowid, "OrderFlowRateUnitRowId",OrderFlowRateUnitRowId);
		        		SetCellData(rowid, "OrderFlowRateUnit", OrderFlowRateUnitRowId);
				    	var RowOrderSeqNo = GetCellData(rowid, "id");
					    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
					    if (OrderMasterSeqNo != "") RowOrderSeqNo = OrderMasterSeqNo;
					    var OrderFlowRateUnit = GetCellData(rowid, "OrderFlowRateUnit");
				    	ChangeLinkOrderFlowRateUnit(RowOrderSeqNo, OrderFlowRateUnitRowId,OrderFlowRateUnit);
				    }
			        
			    //}
		    }
	        var OrderType = GetCellData(rowid, "OrderType");
	        if (OrderType!="R"){
		        if ((GlobalObj.DrippingSpeedInstr).indexOf("^"+OrderInstrRowid+"^")>=0) {
			        ChangeCellDisable(rowid,{OrderSpeedFlowRate:true,OrderFlowRateUnit:true});
			    }else{
				    ChangeCellDisable(rowid,{OrderSpeedFlowRate:false,OrderFlowRateUnit:false});
				    SetCellData(rowid, "OrderSpeedFlowRate", "");
	        		SetCellData(rowid, "OrderFlowRateUnit", "");
	        		SetCellData(rowid, "OrderFlowRateUnitRowId", "");
	        		SetCellData(rowid, "OrderLocalInfusionQty", "");
				}
		    }
	        if ((IsWYInstr(OrderInstrRowid)) && (GlobalObj.PAAdmType != "I")) {
	            /*SetCellData("OrderDur",rowid,"");
	            SetCellData("OrderDurRowid",rowid,"");
	            SetCellData("OrderDoseQty",rowid,"");*/
	            SetCellData(rowid, "OrderDur", "");
	            SetCellData(rowid, "OrderDurRowid", "");
	            SetCellData(rowid, "OrderDoseQty", "");
	            SetCellData(rowid, "OrderDurFactor", 1);
	            SetCellData(rowid, "OrderFreqTimeDoseStr", "");
	        }
	        InstrChange(rowid);
			ChangeLinkOrderInstr(OrderSeqNo, OrderInstrRowid, OrderInstr);

            //允许自定义自定义流速的子医嘱用法需要判断是否根据用法修改流速
            var OrderFlowRateUnit = GetCellData(rowid, "OrderFlowRateUnit");
            var OrderFlowRateUnitRowId = GetCellData(rowid, "OrderFlowRateUnitRowId");
            ChangeLinkOrderFlowRateUnit(OrderSeqNo, OrderFlowRateUnitRowId,OrderFlowRateUnit);
            var OrderSpeedFlowRate = GetCellData(rowid, "OrderSpeedFlowRate");
            ChangeOrderSpeedFlowRate(rowid);

			SetRecLocStr(rowid);
	        SetOrderLocalInfusionQty(rowid)
	        var type = "";
	        if (window.event) type = websys_getType(e);
		    if (type != 'change'){
	            var IdOrderFreq = rowid + "_" + "OrderFreq";
		        var objOrderFreq = document.getElementById(IdOrderFreq);
		        
	            var IdOrderDur = rowid + "_" + "OrderDur";
		        var objDur = document.getElementById(IdOrderDur);
		        var IdOrderPackQty = rowid + "_" + "OrderPackQty";
		        var objPackQty = document.getElementById(IdOrderPackQty);
		        if ((objOrderFreq.disabled)&&(objDur.disabled)&&(objPackQty.disabled)){
			        setTimeout(function(){
				        var RowNext = GetNextRowId(rowid);
				        if (RowNext==rowid){
					        Add_Order_row();
					        RowNext=parseInt(RowNext)+1;
					    }
				        SetFocusCell(RowNext, "OrderName");
			            return websys_cancel();
				    })
			    }else{
		        	setTimeout(function(){
				        var JumpAry = ['OrderFreq','OrderDur', 'OrderPackQty'];
	            		var JumpCellName=CellFocusJump(rowid, JumpAry, true);
				    })
				}
	        }
	        XHZY_Click();
			GetBindOrdItemTip(rowid);
	    })
    } catch (e) { alert(e.message) };
}
function InstrChange(rowid)
{
	var OrderInstrRowid=GetCellData(rowid, "OrderInstrRowid");
	var OrderFreqRowid=GetCellData(rowid, "OrderFreqRowid");
	if(!OrderInstrRowid||!OrderFreqRowid) return;
	var validFlag=$.cm({
		ClassName:"web.DHCDocOrderCommon",
		MethodName:"IsValidFreqDurat",
		InstrRowid:OrderInstrRowid,
		FreqRowid:OrderFreqRowid,
		dataType:"text"
	},false)
	if(validFlag=='0'){
		ClearOrderFreq(rowid);
	}

}
//用法改变
function InstrChangeHandler(e) {
    var rowid = "";
    var obj = websys_getSrcElement(e);
    var rowid = GetEventRow(e);
    PHCINDesc_lookuphandlerX(rowid);
    return websys_cancel();
}

function PHCINDesc_lookuphandlerX(rowid) {
	var OldOrderInstrRowid=GetCellData(rowid, "OrderInstrRowid");
    SetCellData(rowid, "OrderInstrRowid", "");
    var Id = "";
    if ($.isNumeric(rowid) == true) {
        Id = rowid + '_OrderInstr';
    } else {
        Id = 'OrderInstr';
    }
    var OrderSkinTest=GetCellData(rowid, "OrderSkinTest");
    var OrderActionRowid=GetCellData(rowid, "OrderActionRowid");
    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    var OrderInstrRowid=GetCellData(rowid, "OrderInstrRowid");
    var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
    if ((NeedSkinTestINCI!="Y")&&$("#" + rowid).find("td").hasClass("OrderMasterM")){
		var RowArry = GetSeqNolist(rowid)
        for (var i = 0; i < RowArry.length; i++) {
            var OrderHiddenPara = GetCellData(RowArry[i], "OrderHiddenPara");
            NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
            if (NeedSkinTestINCI=="Y"){
	            OrderSkinTest=GetCellData(RowArry[i], "OrderSkinTest");
    			OrderActionRowid=GetCellData(RowArry[i], "OrderActionRowid");
    			OrderInstrRowid=GetCellData(RowArry[i], "OrderInstrRowid");
	        	break;   
	        }
        }
	}
	
    var SeachSkinInstrFlag="";
    var Instr="^"+OrderInstrRowid+"^";
	//治疗类的医嘱，不再允许选中皮试用法
	if (NeedSkinTestINCI=="Y"){
		if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
			SeachSkinInstrFlag="OnlySkin";
		}else if ((OrderSkinTest=="Y")||(OrderActionRowid!="")){
			SeachSkinInstrFlag="Remove";
		}
	}else if (GlobalObj.DisableOrdSkinChange=="1"){
		SeachSkinInstrFlag="Remove";
		if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
			SeachSkinInstrFlag="OnlySkin";
		}
	}
	
    var obj = document.getElementById(Id);
    if (obj.value != '') {
        var tmp = document.getElementById(Id);
        if (tmp) { var p1 = tmp.value } else { var p1 = '' };
        var encmeth = GlobalObj.GetOneInstrStrMethod
        var ret = cspRunServerMethod(encmeth, p1,GlobalObj.PAAdmType,session['LOGON.CTLOCID'])
        if ((GlobalObj.SkinTestInstr != "")) {
        	var InstrRowid=mPiece(ret,"^",0);
        	var isSkinInstr=(GlobalObj.SkinTestInstr.indexOf("^"+InstrRowid+"^") != "-1");
        	if ((SeachSkinInstrFlag=="Remove")&&(isSkinInstr==true)){
	        	ret='0';
	        }else if ((SeachSkinInstrFlag=="OnlySkin")&&(isSkinInstr==false)){
	        	ret='0';	
	        }
        }
        if (ret == '0') {
	        $(obj).addClass("clsInvalid");
            SetCellData("OrderInstrRowid", rowid, "");
            websys_setfocus(Id);
            XHZY_Click();
			GetBindOrdItemTip(rowid);
            return "";
        } else {
	        $(obj).removeClass("clsInvalid");

			//找合适的频次，尽量和当前行上的用法一致，如果找不到一致的再切换
			var InstrArr=ret.split(String.fromCharCode(2));
			var InstrStr="";
			for (var i = 0; i < InstrArr.length; i++) {
				var LoopInstrStr=InstrArr[i];
				var LoopOrderInstrRowid=mPiece(LoopInstrStr, "^", 0);
				if (LoopOrderInstrRowid==OldOrderInstrRowid){
					InstrStr=LoopInstrStr;
					break;
				}
			}
			if (InstrStr!=""){
				var OrderInstrRowid = mPiece(InstrStr, "^", 0);
				var OrderInstr = unescape(mPiece(InstrStr, "^", 1));
				var OrderInstrCode = mPiece(InstrStr, "^", 2);
				SetCellData(rowid, "OrderInstr", OrderInstr);
				SetCellData(rowid, "OrderInstrRowid", OrderInstrRowid);
				//resolve();
			}else if(InstrArr.length==1){
				InstrLookUpSelect(mPiece(ret, String.fromCharCode(2), 0) + "^" + rowid,rowid);
			}
        }
    } else {
        //调用这个干嘛
        //ChangeLinkOrderInstr(rowid,"","");
    }
}
function PHCDUDesc_lookuphandler(e) {
    var obj = websys_getSrcElement(e);
    var key = websys_getKey(e);
    var type = websys_getType(e);

    if (key != 13 && type != 'dblclick') {
        return;
    }
    var rowid = "";
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    return ;
}
//疗程改变
function DurationChangeHandler(e) {
    var rowid = GetEventRow(e)
    PHCDUDesc_changehandlerX(rowid)
    return;
}
function PHCDUDesc_changehandlerX(rowid) {
    SetCellData(rowid, "OrderDurRowid", "");
    var Id = "";
    if ($.isNumeric(rowid) == true) {
        Id = rowid + '_OrderDur';
    } else {
        Id = 'OrderDur';
    }
    var obj = document.getElementById(Id);
    if (obj.value != '') {
        var tmp = document.getElementById(Id);
        if (tmp) { var p1 = tmp.value } else { var p1 = '' };
        var encmeth = GlobalObj.GetOneDurationStrMethod
        var ret = cspRunServerMethod(encmeth, p1)
        if (ret == '0') {
	        $(obj).addClass("clsInvalid");
            SetFocusCell(rowid, "OrderDur");
            return "";
        } else {
	        $(obj).removeClass("clsInvalid");
            DurationLookUpSelect(ret + "^" + rowid,rowid);
        }
    } else {
        //var OrderSeqNo=GetCellData(rowid,"id");
        //ChangeLinkOrderDur(OrderSeqNo,OrderDurRowid,OrderDur,OrderDurFactor)
        ChangeLinkOrderDur(rowid, "", "", "");
    }
    XHZY_Click();
	GetBindOrdItemTip(rowid);
}
function DurationLookUpSelect(value,rowid) {
    var Split_Value = value.split("^");
    //var rowid = "";
    if (typeof rowid == "undefined") { 
    	rowid = "";
    }
    if (rowid == "") {
	    if ((this.id)&&(this.id.indexOf("_") > 0)) {
	        rowid = this.id.split("_")[0];
	    }
    }
    try {
        var OrderDur = unescape(Split_Value[1]);
        var OrderDurRowid = Split_Value[0];
        var OrderDurFactor = Split_Value[3];
        if (Split_Value.length == 5) { rowid = Split_Value[4] }
        var OrderSeqNo = GetCellData(rowid, "id");
        SetCellData(rowid, "OrderDur", OrderDur)
        SetCellData(rowid, "OrderDurRowid", OrderDurRowid);
        SetCellData(rowid, "OrderDurFactor", OrderDurFactor);
        var SetPackQtyConfig={
			///是否不需要重置整包装数
			IsNotNeedChangeFlag:undefined,
			///是否不需要重置首日次数
			IsNotChangeFirstDayTimeFlag:undefined
		};
        var OrderFirstDayTimes=GetCellData(rowid, "OrderFirstDayTimes");
        if (OrderFirstDayTimes!=""){
	        SetPackQtyConfig.IsNotChangeFirstDayTimeFlag="Y";
	    }
        SetPackQty(rowid,SetPackQtyConfig);
        ChangeLinkOrderDur(OrderSeqNo, OrderDurRowid, OrderDur, OrderDurFactor);
        SetScreenSum();
        var OrderPackQty = GetCellData(rowid, "OrderPackQty");
        var OrderType = GetCellData(rowid, "OrderType");
        
        var type = "";
        if (window.event) type = websys_getType(e);
        if (type != 'change') { 
            setTimeout(function (){
                var JumpAry = ['OrderPackQty'];
                var JumpCellName=CellFocusJump(rowid, JumpAry, true);
            },10);
            return true;
        }

    } catch (e) {};
    return websys_cancel();
}
function ChangeLinkOrderDur(OrderSeqNo, OrderDurRowid, OrderDur, OrderDurFactor) {
    try {
        var rows = $('#Order_DataGrid').getDataIDs();
        for (var i = 0; i < rows.length; i++) {
            var rowid = rows[i];
            var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
            var OrderType = GetCellData(rowid, "OrderType");
            if ((OrderMasterSeqNo != OrderSeqNo) || (OrderARCIMRowid == "") || (OrderItemRowid != "")) { continue; }
            SetCellData(rowid, "OrderDur", OrderDur);
            SetCellData(rowid, "OrderDurRowid", OrderDurRowid);
            SetCellData(rowid, "OrderDurFactor", OrderDurFactor);
            var SetPackQtyConfig={
				///是否不需要重置整包装数
				IsNotNeedChangeFlag:undefined,
				///是否不需要重置首日次数
				IsNotChangeFirstDayTimeFlag:undefined
			};
            var OrderFirstDayTimes=GetCellData(rowid, "OrderFirstDayTimes");
	        if (OrderFirstDayTimes!=""){
		        SetPackQtyConfig.IsNotChangeFirstDayTimeFlag="Y";
		    }
            SetPackQty(rowid,SetPackQtyConfig);
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function PHCFRDesc_changehandlerX(rowid,callBackFun) {
	var OldOrderFreqRowid=GetCellData(rowid, "OrderFreqRowid");
    SetCellData(rowid, "OrderFreqRowid", "");
    var encmeth = GlobalObj.GetOneFrequencyStrMethod
    var Id = "";
    if ($.isNumeric(rowid) == true) {
        Id = rowid + '_OrderFreq';
    } else {
        Id = 'OrderFreq';
    }
    new Promise(function(resolve,rejected){
	    var obj = document.getElementById(Id);
	    if (obj && obj.value != '') {
	        var tmp = document.getElementById(Id);
	        if (tmp) { var p1 = tmp.value } else { var p1 = '' };
	        var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
	        var ret = cspRunServerMethod(encmeth, p1,GlobalObj.PAAdmType,OrderPriorRowid);
	        if (ret == '0') {
		        $(obj).addClass("clsInvalid");
	            websys_setfocus(Id);
	            if (callBackFun) callBackFun();
	        } else if(ret==1){
				//目前没有逻辑会走到这个逻辑判断里-tanjishan2019.10.29
				$(obj).removeClass("clsInvalid");
	            FrequencyLookUpSelect(ret,rowid,resolve);
	            $(obj).removeClass("clsInvalid");
	        }else if (ret!=""){
				//找合适的频次，尽量和当前行上的频次一直，如果找不到一致的再切换
				var FreqArr=ret.split(String.fromCharCode(2));
				var FreqStr="";
				for (var i = 0; i < FreqArr.length; i++) {
					var LoopFreqStr=FreqArr[i];
					var LoopOrderFreqRowid=mPiece(LoopFreqStr, "^", 4);
					if (LoopOrderFreqRowid==OldOrderFreqRowid){
						FreqStr=LoopFreqStr;
					}
				}
				if (FreqStr!=""){
					var OrderFreq = mPiece(FreqStr, "^", 0);
					var OrderFreqFactor = mPiece(FreqStr, "^", 2);
					var OrderFreqInterval = mPiece(FreqStr, "^", 3);
					var OrderFreqRowid = mPiece(FreqStr, "^", 4);
					var WeekFlag = mPiece(FreqStr, "^", 6);
					var FreeTimeFreqFlag = mPiece(FreqStr, "^", 8);
					if ((WeekFlag!="Y")&&(FreeTimeFreqFlag!="Y")) {
						SetCellData(rowid, "OrderFreq", OrderFreq);
					}
					SetCellData(rowid, "OrderFreqRowid", OrderFreqRowid);
					SetCellData(rowid, "OrderFreqFactor", OrderFreqFactor);
					SetCellData(rowid, "OrderFreqInterval", OrderFreqInterval);
					resolve();
				}else if(FreqArr.length==1){
		            FrequencyLookUpSelect(mPiece(ret, String.fromCharCode(2), 0),rowid,resolve);
				}
			}
	    } else {
	        var MasterOrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
	        var MasterOrderPrior = GetCellData(rowid, "MasterOrderPrior");
	        var OrderFreqRowid = "";
	        var OrderFreq = "";
	        var OrderFreqFactor = "";
	        var OrderFreqInterval = "";
	        SetCellData(rowid, "OrderFreq", OrderFreq);
	        SetCellData(rowid, "OrderFreqRowid", OrderFreqRowid);
	        SetCellData(rowid, "OrderFreqFactor", OrderFreqFactor);
	        SetCellData(rowid, "OrderFreqInterval", OrderFreqInterval);
	        //频次->疗程监测
	        FreqDurChange(rowid)
	        
	        var OrderFreqDispTimeStr = GetCellData(rowid, "OrderFreqDispTimeStr");
	        var MasterOrderStartDateStr = GetCellData(rowid, "OrderStartDate");
	        SetPackQty(rowid);
	        ChangeLinkOrderFreq(rowid,MasterOrderPriorRowid,MasterOrderPrior,OrderFreqRowid,OrderFreq,OrderFreqFactor,OrderFreqInterval,OrderFreqDispTimeStr,MasterOrderStartDateStr,resolve);
	    }
	}).then(function(){
		return new Promise(function(resolve,rejected){
			SetScreenSum();
			SetOrderFirstDayTimes(rowid);
			//同步首日次数
			ChangeFirstDayTimes(rowid,true,resolve);
		});
	}).then(function(){
		XHZY_Click();
		GetBindOrdItemTip(rowid);
		if (callBackFun) callBackFun();
	});
}

function GetOrderSeqArr(rowid) {
    if ($.isNumeric(rowid) == false) { return rowid }
    var rowidArr = {};
    rowidArr[rowid] = rowid;
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    //可能为主医嘱
    if (OrderMasterSeqNo == "") {
        var rowids = GetAllRowId();
        for (var i = 0; i < rowids.length; i++) {
            var MasterSeqNo = GetCellData(rowids[i], "OrderMasterSeqNo");
            if (MasterSeqNo == rowid) {
                rowidArr[rowids[i]] = rowids[i];
            }
        }
    } else {
        //子医嘱
        var rowids = GetAllRowId();
        //主医嘱id:OrderMasterSeqNo
        rowidArr[OrderMasterSeqNo] = OrderMasterSeqNo;
        for (var i = 0; i < rowids.length; i++) {
            var MasterSeqNo = GetCellData(rowids[i], "OrderMasterSeqNo");
            if (MasterSeqNo == OrderMasterSeqNo) {
                rowidArr[rowids[i]] = rowids[i];
            }
        }
    }
    return rowidArr;
}
//选择控制
function SelectContrl(rowid) {
    if ($.isNumeric(rowid) == false) { return rowid }
    var stutas = $("#jqg_Order_DataGrid_" + rowid).prop("checked");
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    var rowids = GetAllRowId();
    //根据配置 选择子医嘱是否选中全部 1：全选
    var configValue = GlobalObj.SelectContrlConfig;
    //---------------已审核医嘱判断 主子医嘱始终联动
    if (CheckIsItem(rowid) == true) {
        var FitNum = ""
        FitNum = rowid.split(".")[0]
        for (var i = 0; i < rowids.length; i++) {
            if (CheckIsItem(rowids[i]) != true) { continue; }
            if (rowids[i] == rowid) { continue }
            var subFitNum = rowids[i].split(".")[0]
            if (subFitNum == FitNum) {
                $("#Order_DataGrid").setSelection(rowids[i], false);
            }
        }
    }
    //-----------------未审核医嘱判断
    var OrderSeqNo=GetCellData(rowid, "id");
    //可能为主医嘱
    if (OrderMasterSeqNo == "") {
        var OrderMasterFlag=0;
        for (var i = 0; i < rowids.length; i++) {
	        
            //取子医嘱
            var MasterSeqNo = GetCellData(rowids[i], "OrderMasterSeqNo");
            if (MasterSeqNo != "" && MasterSeqNo == OrderSeqNo) {
                //选中子医嘱 rowids[i]
                //获取选中状态
                if ($("#jqg_Order_DataGrid_" + rowids[i]).prop("checked") != stutas) {
                    $("#Order_DataGrid").setSelection(rowids[i], false);
                }
                if ($("#ChangeOrderSeq_Btn .l-btn-text")[0]){
	                if (stutas){
		                $("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("结束关联(R)");
		            }else{
			            $("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("开始关联(R)");
			            PageLogicObj.StartMasterOrdSeq="";
			        }
                }
                OrderMasterFlag=OrderMasterFlag+1;
            }
        }
        if (OrderMasterFlag==0){
	        //$("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("开始关联(R)");
	       //PageLogicObj.StartMasterOrdSeq="";
        }
    } else if (configValue == 1) {
        //全选
        //主医嘱ID
        var mainRowid = OrderMasterSeqNo;
        var mainRowData=$('#Order_DataGrid').jqGrid("getRowData",OrderMasterSeqNo);
        if ($.isEmptyObject(mainRowData)) {
	        var mainRowid=GetRowIdByOrdSeqNo(mainRowid);
	    }
        //主医嘱选择状态
        if ($("#jqg_Order_DataGrid_" + mainRowid).prop("checked") != stutas) {
            $("#Order_DataGrid").setSelection(mainRowid, false);
        }
        for (var i = 0; i < rowids.length; i++) {
            //取子医嘱
            var MasterSeqNo = GetCellData(rowids[i], "OrderMasterSeqNo");
            if (MasterSeqNo != "" && MasterSeqNo == mainRowid) {
                //获取选中状态
                if ($("#jqg_Order_DataGrid_" + rowids[i]).prop("checked") != stutas) {
                    $("#Order_DataGrid").setSelection(rowids[i], false);
                }
                if ($("#ChangeOrderSeq_Btn .l-btn-text")[0]){
	                if (stutas){
		                $("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("结束关联(R)");
		            }else{
			            $("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("开始关联(R)");
			            PageLogicObj.StartMasterOrdSeq="";
			        }
                }
            }
        }
    }
    if (stutas) {
        if ((VerifiedOrderObj) && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "undefined") && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "")) return false;
        if (GlobalObj.CFOrderMsgAlert != 1) return false;

        var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid")
        var OrderName = GetCellData(rowid, "OrderName")
        var OrderMsg = cspRunServerMethod(GlobalObj.GetOrderMsgMethod, GlobalObj.EpisodeID, OrderARCIMRowid)
        if (OrderMsg != "") {
            $("#Prompt").html($g("提示信息:") + OrderName + $g(OrderMsg));
        }else{
	        $("#Prompt").html($g("提示信息:"));
	    }
    }
}
function ChangeOrderSeqhandler(e){
    var BtnText=$("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText;
    if (BtnText.indexOf($g('结束关联')) != -1){
        if (!ClearSeqNohandler()) return false;
        PageLogicObj.IsStartOrdSeqLink=0;
        PageLogicObj.StartMasterOrdSeq="";
        $("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("开始关联(R)");
    }else{
        if (!SetSeqNohandler()) {
	        PageLogicObj.IsStartOrdSeqLink="";
	        return false;
	    }
        PageLogicObj.IsStartOrdSeqLink=1;
        $("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("结束关联(R)");
    }
}
function checkOrdMasSeqNoIsEdit(row){
	var StyleConfigStr = GetCellData(row, "StyleConfigStr");
    var StyleConfigObj = {};
    if (StyleConfigStr != "") {
        StyleConfigObj = eval("(" + StyleConfigStr + ")");
    }
    if (StyleConfigObj.OrderMasterSeqNo==false){
	    return false;
	}
	return true;
}
////关联控制  2014-04-17(提供给按钮的控制)
function SetSeqNohandler() {
    //获取选择行ID: GetSelRowId()
    //获取所有行ID  包含已审核  根据CheckIsItem(rowid)判断
    //此处SelTableRowAry是选中的数组,如果在后面的程序中改变选中状态也会影响数组数据,引用地址传递,所以使用重新赋值
    var SelTableRowAry = GetSelRowId();
    var Selrowids = SelTableRowAry.join(',').split(',');
    if (Selrowids.length <= 1) {
        return true;
    }
    var MainID = Selrowids[0];
    PageLogicObj.IsStartOrdSeqLink=MainID;
    //设置关联
    var change=false;
    //校验滴速是否允许关联
    var MainSpeedFlowRate=GetCellData(MainID, "OrderSpeedFlowRate").replace(/(^\s*)|(\s*$)/g, '');
    var MainOrderType = GetCellData(MainID, "OrderType");
    if(MainOrderType=="R"&&MainSpeedFlowRate==""){
        var SubSpeedFlowRateStr="";
        for (var j = 1; j < Selrowids.length; j++) {
            var index=Selrowids[j];
            if ( index== "") continue;
            if (index == MainID) continue;

            var SelOrderType = GetCellData(index, "OrderType");
            if(SelOrderType!="R") continue;
            var SelSpeedFlowRate=GetCellData(index, "OrderSpeedFlowRate").replace(/(^\s*)|(\s*$)/g, '');
            if(SelSpeedFlowRate=="") continue;
            if((","+SubSpeedFlowRateStr+",").indexOf(","+SelSpeedFlowRate+",")>-1) continue;

            var SelInstrRowId = GetCellData(index, "OrderInstrRowid");
            if(IsSpeedRateSeparateInstr(SelInstrRowId)) continue;
            SubSpeedFlowRateStr=SubSpeedFlowRateStr==""?SelSpeedFlowRate:(SubSpeedFlowRateStr+","+SelSpeedFlowRate)
        }
        if(SubSpeedFlowRateStr.indexOf(",")>-1){
            $.messager.alert("提示", "关联医嘱存在两个（或多个）不同的滴速，请手动修改","info");
            return false;
        }
    }
    

    for (var i = 1; i < Selrowids.length; i++) {
        if (Selrowids[i] == "") continue;
        // 验证是否可关联
		var rtn=CheckIsCanSetOrdMasSeqNo(MainID,Selrowids[i],function(){
			$("#Order_DataGrid").setSelection(Selrowids[i], false);
		})
		if (rtn) {
			//设置关联
	        var SubID = Selrowids[i];
	        var change = SetMasterSeqNo(MainID, SubID, "S");
		}else{
			return false;
		}
    }
    return change;
}
//拆关联(提供给按钮的控制)
function ClearSeqNohandler() {
    //获取选择行ID: GetSelRowId()
    //获取所有行ID  包含已审核  根据CheckIsItem(rowid)判断
    //GetAllRowId()
    var Selrowids = GetSelRowId();
    //$.messager.alert("警告",Selrowids);
    if (Selrowids.length < 1) {
        //$.messager.alert("警告", "请选择关联医嘱");
        return true;
    }
    //检查是否选择有主医嘱  var OrderMasterSeqNo=GetCellData(MainID,"OrderMasterSeqNo");
    for (var i = 0; i < Selrowids.length; i++) {
        if (CheckIsItem(Selrowids[i]) == false) {
            var OrderMasterSeqNo = GetCellData(Selrowids[i], "OrderMasterSeqNo");
            //var OrderType = GetCellData(Selrowids[i], "OrderType");
            //if (OrderType!="R") continue;
            //一拆全拆,不管选择的是主医嘱还是子医嘱
            if (OrderMasterSeqNo == "") {
                //选择了主医嘱  拆除全部子医嘱       
                SetMasterSeqNo(Selrowids[i], "", "C");
            } else {
                SetMasterSeqNo(OrderMasterSeqNo, "", "C");
            }
        }
    }
    return true;
}
//设置关联 传入 主医嘱ID  子医嘱ID type："S"(关联) "C"(拆关联) 2014-04-18
function SetMasterSeqNo(MainID, SubID, type) {
    if (MainID != "") {
        if (($.isNumeric(MainID) == false)) { return false; }
        //判断主医嘱存不存在     
    }
    if (SubID != "") {
        if (($.isNumeric(SubID) == false)) { return false; }
    }
    if (type == "S") {
	    // 验证是否可关联
	    var rtn=CheckIsCanSetOrdMasSeqNo(MainID,SubID,function(){
			ClearOrderMasterSeqNo(SubID);
            CheckMasterOrdStyle();
		});
		if (rtn) {
			EditRow(MainID);
			EditRow(SubID);
			var SubOrdInstrRowid = GetCellData(SubID, "OrderInstrRowid");
			var SubOrdInstr = GetCellData(SubID, "OrderInstr");
			var MainOrdInstrRowid = GetCellData(MainID, "OrderInstrRowid");
			var SubOldOrderRecDepRowid=GetCellData(SubID, "OrderRecDepRowid");
			var SubOrderRecDep=GetCellData(SubID, "OrderRecDep");
			var SubOrderRecLocStr=GetCellData(SubID, "OrderRecLocStr");
			//数据检查
	        var ret = CheckLinkOrderRecDep(MainID, SubID);
	        if (ret == true) {
	            SetCellData(SubID, "OrderMasterSeqNo", MainID);
	            $("#" + MainID).find("td").addClass("OrderMasterM");
	            $("#" + SubID).find("td").addClass("OrderMasterS");
	            OrderMasterHandler(SubID, "S");
	        }else{
		        //还原子医嘱用法
				if ((!IsNotFollowInstr(SubOrdInstrRowid))&&(SubOrdInstrRowid!=MainOrdInstrRowid)) {
					 SetCellData(SubID, "OrderInstrRowid", SubOrdInstrRowid);
					 SetCellData(SubID, "OrderInstr", SubOrdInstr);
					 SetColumnList(SubID, "OrderRecDep", SubOrderRecLocStr);
					 SetCellData(SubID, "OrderRecDepRowid", SubOldOrderRecDepRowid);
					 var EditStatus = GetEditStatus(SubID);
					 if (EditStatus){
					    SetCellData(SubID, "OrderRecDep", SubOldOrderRecDepRowid);
					 }else{
					    SetCellData(SubID, "OrderRecDep", SubOrderRecDep);
					 }
				}
				ClearOrderMasterSeqNo(SubID);
				
            	CheckMasterOrdStyle();
		    }
		}else{
			return false;
		}
    } else if (type == "C") {
        //拆关联
        if (MainID != "") {
            //传入主医嘱拆除全部子医嘱
            $("#" + MainID).find("td").removeClass("OrderMasterM");
			//传入主医嘱也需要恢复之前状态
			OrderMasterHandler(MainID, "C");
            var Allrowids = GetAllRowId();
			var LinkSubRowidArr= new Array();
            for (var i = 0; i < Allrowids.length; i++) {
                if (CheckIsItem(Allrowids[i]) == true) { continue; }
                var SMasterSeqNo = GetCellData(Allrowids[i], "OrderMasterSeqNo");
                if (SMasterSeqNo == MainID) {
					LinkSubRowidArr.push(Allrowids[i]);
                }
            }
			ClearOrderMasterSeqNo(LinkSubRowidArr.join("^"));
			LinkSubRowidArr.forEach(function(LinkSubRowid){
				if (LinkSubRowid==""){return true;}
				$("#" + LinkSubRowid).find("td").removeClass("OrderMasterS");
                OrderMasterHandler(LinkSubRowid, "C");
			})
			
			SetRecLocStr(MainID);
        } else {
            //不传主医嘱 拆除单个子医嘱 
			ClearOrderMasterSeqNo(SubID);
			$("#" + SubID).find("td").removeClass("OrderMasterM");
            OrderMasterHandler(SubID, "C");
        }
    }
    return true;
}
//用于清空关联号，并重置该行的接受科室数据
function ClearOrderMasterSeqNo(rowids){
	var rowidArr=rowids.toString().split("^");
	var MainArr = new Array();
	rowidArr.forEach(function(rowid){
		if ($.isNumeric(rowid)==false){return true;}
		var MainID=GetCellData(rowid, "OrderMasterSeqNo");
		if (MainID==""){return true;}
		if (($.inArray(MainID,MainArr)==false)&&($.isNumeric(MainID)==true)){
			MainArr.push(MainID);
		}
		SetCellData(rowid, "OrderMasterSeqNo", '');
		$("#" + rowid).find("td").removeClass("OrderMasterS");
        
		SetRecLocStr(rowid);
	});
	MainArr.forEach(function(rowid){
		SetRecLocStr(rowid);
	});
}
//设置关联和拆关联对行样式和数据的控制
function OrderMasterHandler(rowid, type) {
    /* 
    //主医嘱实际上不需要做处理
    if($.isNumeric(MainID)==true){
        //还原
        ChangeCellsDisabledStyle(MainID,true);
    }
    */
    var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
	var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
	if ((OrderItemRowid=="")&&(OrderARCIMRowid=="")){
		return;
	}
    var StyleConfigStr = GetCellData(rowid, "StyleConfigStr");
    var StyleConfigObj = {};
    if (StyleConfigStr != "") {
        StyleConfigObj = eval("(" + StyleConfigStr + ")");
    }
    if (GlobalObj.PAAdmType == "I") {
	    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
	    if (OrderPriorRowid != GlobalObj.OutOrderPriorRowid) {
		    StyleConfigObj.OrderDur=false;
		}
	}
	var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
	//皮试用法，皮试备注和标志不可编辑
    if (GlobalObj.SkinTestInstr != "") {
	    var InstrRowId = GetCellData(rowid, "OrderInstrRowid");
        var Instr = "^" + InstrRowId + "^";
        if (GlobalObj.SkinTestInstr.indexOf(Instr) != "-1") {
	        StyleConfigObj.OrderAction=false;
	    }
	}
	if (NeedSkinTestINCI=="Y"){
		StyleConfigObj.OrderSkinTest=false;
		StyleConfigObj.OrderAction=false;
	}
    //重建行数据 对于下拉框 重新值
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    var OrderPrescNo = GetCellData(rowid, "OrderPrescNo");
    if ((OrderPrescNo != "") && (type == "C")) {
        ///仅重建医嘱数量,单次计量,单次计量单位,频次,疗程,用法
        StyleConfigObj.OrderDur = true;
        StyleConfigObj.OrderFreq = true;
        StyleConfigObj.OrderInstr = true;
        if ((!StyleConfigObj.OrderRecDep)&&(OrderMasterSeqNo=="")){
	        StyleConfigObj.OrderRecDep = true;
	        StyleConfigObj.OrderFlowRateUnit = true;
	        StyleConfigObj.OrderSpeedFlowRate = true;
	        StyleConfigObj.OrderLocalInfusionQty = true;
	        StyleConfigObj.ExceedReason = true;
	    }
    }
    //越级使用的抗菌药物不可操作。 update by shp 20150721
    var SpelAction = GetCellData(rowid, "SpecialAction");
    var SpecialAction = "";
    if (SpelAction.toString().indexOf('||') != -1) SpecialAction = SpelAction.split("||")[0];

    //设置子医嘱的数据和disable  设置关联
    if ($.isNumeric(rowid) == true && type == "S") {
        //子医嘱数据改变
        var MainID = GetCellData(rowid, "OrderMasterSeqNo");
        // update by shp 20150721
        //tanjishan 普通药品和皮试引导药品关联，以皮试引导药品的为准
        var MainOrdNumStr=GetMainOrdNumStrInGroup(MainID,rowid);
		var MainDataRow=mPiece(MainOrdNumStr, "^", 1);
		
        if ((SpecialAction != "isEmergency")&&(MainDataRow==MainID)) {
            SyncOrderData(MainID, rowid);
            //子医嘱样式改变
            ChangeCellsDisabledStyle(rowid, false);
            //ChangeRowStyle(rowid,StyleConfigObj);
        } else {
			//主医嘱样式改变
            var rowids = GetAllRowId();
            for (var i = 0; i < rowids.length; i++) {
                var Eid = GetCellData(rowids[i], "OrderMasterSeqNo"); //已经关联的子医嘱关联id
                if (Eid == MainID) {
                    SyncOrderData(rowid, rowids[i])
                }
            }
            SyncOrderData(rowid, MainID) //主医嘱数据跟催越级抗菌药物数据相统一
            //ChangeCellsDisabledStyle(MainID, false);
            ChangeCellsDisabledStyle(rowid, false);
            if (SpecialAction!=""){
	            //越级抗菌药物为子医嘱时,主医嘱控制医嘱类型不可编辑
				var styleConfigObj = { OrderPrior: false, OrderFreq:false }
				ChangeCellDisable(MainID, styleConfigObj);
	        }
            SetCellData(rowid, "SpecialAction", SpecialAction + "||" + MainID);
        }
    }
    //拆关联
    if ($.isNumeric(rowid) == true && type == "C") {
        //子医嘱样式改变
        var MainID = SpelAction.toString().split("||")[1]; //此代码取到为空，应取改变前的值，需修改。
        if ((SpecialAction != "isEmergency")) {
            ChangeCellsDisabledStyle(rowid, true);
            //因为设置关联时可能对同一个字段有重复 需要还原样式
            ChangeRowStyle(rowid, StyleConfigObj);
			FreqDurChange(rowid);
            RestoreOrderData(rowid)
            //还原在SyncOrderData处理的用法样式
            var MainIDStyleConfigStr = GetCellData(MainID, "StyleConfigStr");
		    var MainIDStyleConfigObj = {};
		    if (MainIDStyleConfigStr != "") {
		        MainIDStyleConfigObj = eval("(" + MainIDStyleConfigStr + ")");
		    }
		    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
		    
		    var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
		    if (NeedSkinTestINCI!="Y"){
				if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
					 SetCellData(rowid, "OrderInstrRowid", "");
					 SetCellData(rowid, "OrderInstr", "");
				}
		    }
            //var RowStyleObj = { OrderInstr: MainIDStyleConfigObj.OrderInstr };
            var RowStyleObj = MainIDStyleConfigObj;
            ChangeCellDisable(MainID, RowStyleObj);
        } else {
            ChangeCellsDisabledStyle(rowid, true);
            //因为设置关联时可能对同一个字段有重复 需要还原样式
            //ChangeRowStyle(MainID,StyleConfigObj);

            RestoreOrderData(MainID)
			var styleConfigObj = { OrderPrior: true }
            ChangeCellDisable(MainID, styleConfigObj);
            var styleConfigObj = { OrderPrior: false }
            ChangeCellDisable(rowid, styleConfigObj);
            var rowids = GetAllRowId();
            for (var i = 0; i < rowids.length; i++) {
                var Eid = GetCellData(rowids[i], "OrderMasterSeqNo"); //已经关联的子医嘱关联id
                if ((Eid == MainID)&&(Eid!="")) {
                    SyncOrderData(MainID, rowids[i])
                }
            }
            SetCellData(rowid, "SpecialAction", "isEmergency||");
        }
    }
    var OrderType = GetCellData(rowid, "OrderType");
    var OrderPHPrescType = GetCellData(rowid, "OrderPHPrescType");
    var OrderPriorRowid=GetCellData(rowid,"OrderPriorRowid");
    if ((OrderType!="R")&&(OrderPHPrescType!="4")){
	    var styleConfigObj={};
	    if (type=="S"){
		    if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid){
			    var MainStyleConfigStr = GetCellData(MainID, "StyleConfigStr");
			    var MainStyleConfigObj = {};
			    if (MainStyleConfigStr != "") {
			        MainStyleConfigObj = eval("(" + MainStyleConfigStr + ")");
			    }
		        if (MainStyleConfigObj.OrderFreq){
		            var styleConfigObj = { OrderPackQty: false, OrderDoseQty:true };
		        }else{
			        var styleConfigObj = { OrderDoseQty:false };
			    }
			    var OrderPackUOMStr=GetCellData(rowid, "OrderPackUOMStr");
			    var OrderPackUOMStrArr=OrderPackUOMStr.split(String.fromCharCode(1));
			    OrderPackUOMStr=""+String.fromCharCode(1)+OrderPackUOMStrArr[1]+String.fromCharCode(1)+OrderPackUOMStrArr[0];
			    SetColumnList(rowid, "OrderDoseUOM", OrderPackUOMStr)
			    SetCellData(rowid, "OrderPackQty","");
		    }else{
			    var styleConfigObj = { OrderDoseQty:false }; 
			    }
	    }else{
		    var styleConfigObj = { OrderPackQty: true, OrderDoseQty:false };
		    ClearOrderFreq(rowid);
		   if ((IsLongPrior(OrderPriorRowid))||(StyleConfigObj.OrderDur==false)) {
			    ClearOrderDur(rowid);
			}
		    SetCellData(rowid, "OrderDoseQty","");
		    SetCellData(rowid, "OrderFirstDayTimesCode",0);
		    SetColumnList(rowid, "OrderDoseUOM", "");
		}
		ChangeCellDisable(rowid, styleConfigObj);
    }
    if ((OrderPHPrescType=="4")&&(OrderType!="R")&&(OrderPriorRowid != GlobalObj.LongOrderPriorRowid)){
	    var SubStyleConfigStr = GetCellData(rowid, "StyleConfigStr");
	    var SubStyleConfigObj = {};
	    if (SubStyleConfigStr != "") {
	        SubStyleConfigObj = eval("(" + SubStyleConfigStr + ")");
	    }
        if (!SubStyleConfigObj.OrderDoseQty){
            ChangeCellDisable(rowid, {OrderPackQty: true,OrderDoseQty:false});
        }
	}
    var Selrowids = GetSelRowId();
    for (var i = Selrowids.length-1; i >=0; i--) {
        if (CheckIsItem(Selrowids[i]) == false) {
	        var Status=$("#jqg_Order_DataGrid_" + Selrowids[i]).prop("checked");
	        if (Status){
            	$("#Order_DataGrid").setSelection(Selrowids[i], false);
            }
        }
    }
    GetBindOrdItemTip(rowid);
}
//提供给手动改变关联的控制
function OrderMasterChangeHandler(e,rowid) {
	if(typeof rowid=='undefined'){
		rowid = GetEventRow(e);
	}
    if ($.isNumeric(rowid) == false) { return; }
    var RowIdArry = new Array();
    var MasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    if (MasterSeqNo == "") {
        //取消关联
        SetMasterSeqNo("", rowid, "C");
		
		SetRecLocStr(rowid);
        //是否可封装
        var allrowids = GetAllRowId();
        for (var i = 0; i < allrowids.length; i++) {
            var id1 = allrowids[i];
            var ItemRowid1 = GetCellData(id1, "OrderItemRowid");
            if (ItemRowid1 != "") { continue };
            var MasterSeqNo1 = GetCellData(id1, "OrderMasterSeqNo");
            if (MasterSeqNo1!=""){
	             $("#" + id1).find("td").addClass("OrderMasterS");
	             $("#" + MasterSeqNo1).find("td").addClass("OrderMasterM");
	        }else{
		        $("#" + id1).find("td").removeClass("OrderMasterS");
				if ($("#" + id1).find("td").hasClass("OrderMasterM")){
               		$("#" + id1).find("td").removeClass("OrderMasterM");
					SetRecLocStr(id1);
					//主医嘱如果不是皮试，需要撤销时改变皮试用法
					var OrderHiddenPara = GetCellData(id1, "OrderHiddenPara")
					var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
					if (NeedSkinTestINCI!="Y"){
						var InstrRowId = GetCellData(id1, "OrderInstrRowid");
						var Instr = "^" + InstrRowId + "^";
						if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
							SetCellData(id1, "OrderInstrRowid", "");
							SetCellData(id1, "OrderInstr", "");
							ChangeRowStyle(id1, {OrderInstr:true});
						}
					}
					GetBindOrdItemTip(id1);
				}
		    }
        }
    } else {
	    	// 验证是否可关联
	    var rtn=CheckIsCanSetOrdMasSeqNo(MasterSeqNo,rowid,function(){
			SetMasterSeqNo("", rowid, "C");
			$("#" + rowid).find("td").removeClass("OrderMasterS");
			CheckMasterOrdStyle();
		});
		if (rtn) {
		    //设置关联
	        SetMasterSeqNo(MasterSeqNo, rowid, "S");
        }else {
	        return;
	    }
    }
    CheckMasterOrdStyle();
	GetBindOrdItemTip(rowid);
}
//还原子医嘱数据(有些数据需要从新计算)
function RestoreOrderData(SubID) {
    //配液标记
    //SetCellData(SubID,"OrderNeedPIVAFlag",false);
    SetPackQty(SubID);
	var OrderType = GetCellData(SubID, "OrderType");
    if (OrderType!="R") {
	    SetCellData(SubID, "OrderInstrRowid","");
	    SetCellData(SubID, "OrderInstr","");
	    SetCellData(SubID, "OrderSpeedFlowRate","");
	    SetCellData(SubID, "OrderFlowRateUnit","")
    	SetCellData(SubID, "OrderFlowRateUnitRowId","")
    	SetCellData(SubID, "OrderLocalInfusionQty","")
	}
    var OrderPackQtyStyleObj = ContrlOrderPackQty(SubID);
    ChangeCellDisable(SubID, OrderPackQtyStyleObj);
}
//同步子医嘱数据(有些数据需要从新计算)--对标 web.DHCOEOrdItemView下的SyncOrderData
function SyncOrderData(MainID, SubID) {
	var RowStyleObj={};
    //判断行是否在编辑状态
    var EditStatus = GetEditStatus(SubID);
    //1.医嘱类型
    var OldPriorRowid=GetCellData(SubID, "OrderPriorRowid");
    var OrderPriorRowid = GetCellData(MainID, "OrderPriorRowid");
    var OrderPrior = GetCellData(MainID, "OrderPrior");
    /*var OrderPriorRowid = GetCellData(SubID, "OrderPriorRowid");
    var OrderPriorRemarks = GetCellData(SubID, "OrderPriorRemarks");*/
    if (EditStatus == true) {
        SetCellData(SubID, "OrderPrior", OrderPriorRowid);
    } else {
        SetCellData(SubID, "OrderPrior", OrderPrior);
    }
    SetCellData(SubID, "OrderPriorRowid", OrderPriorRowid);
    if (GlobalObj.OrderPriorContrlConfig == 1) {
        var Obj = "";
        if ($.isNumeric(SubID) == true) {
            Obj = document.getElementById(SubID + "_OrderPrior");
        } else {
            Obj = document.getElementById("OrderPrior");
        }
        var HiddenOrderPrior = $("#HiddenOrderPrior").val();
        if ((OrderPriorRowid == GlobalObj.LongOrderPriorRowid)) {
            //只有长期
            var tempOrderPrior = $g("长期医嘱");
            var tempOrderPriorRowid = GlobalObj.LongOrderPriorRowid;
        }
        if ((OrderPriorRowid == GlobalObj.ShortOrderPriorRowid)) {
            //只有临时
            var tempOrderPrior = $g("临时医嘱");
            var tempOrderPriorRowid = GlobalObj.ShortOrderPriorRowid;
        }
        if ((OrderPriorRowid == GlobalObj.OutOrderPriorRowid)) {
            //出院带药
            var tempOrderPrior = $g("出院带药");
            var tempOrderPriorRowid = GlobalObj.OutOrderPriorRowid;
        }
        if (Obj) {
            ClearAllList(Obj);
            Obj.options[Obj.length] = new Option(tempOrderPrior, tempOrderPriorRowid);
        }
        SetCellData(SubID, "OrderPriorStr", tempOrderPriorRowid + ":" + tempOrderPrior);
    }
    //若主医嘱为长期/出院带药医嘱,子医嘱附加说明为取药医嘱,则清空子医嘱附加说明
    var OrderPriorRemarks = GetCellData(SubID, "OrderPriorRemarksRowId");
    if (((OrderPriorRowid == GlobalObj.LongOrderPriorRowid)||(OrderPriorRowid==GlobalObj.OutOrderPriorRowid))&&(OrderPriorRemarks=="ONE")) {
	    SetCellData(SubID, "OrderPriorRemarks","");
	    SetCellData(SubID, "OrderPriorRemarksRowId","");
	}
    var OrderStartDate = GetCellData(MainID, "OrderStartDate");
    SetCellData(SubID, "OrderStartDate", OrderStartDate);
	OrderPriorchangeCommon(SubID,OldPriorRowid,OrderPriorRowid)
    //2.频次
    var OrderFreqRowid = GetCellData(MainID, "OrderFreqRowid");
    var OrderFreq = GetCellData(MainID, "OrderFreq");
    var OrderFreqFactor = GetCellData(MainID, "OrderFreqFactor");
    var OrderFreqInterval = GetCellData(MainID, "OrderFreqInterval");
    var OrderFreqDispTimeStr = GetCellData(MainID, "OrderFreqDispTimeStr");
    var SubOrderFreqRowid= GetCellData(SubID, "OrderFreqRowid");
    SetCellData(SubID, "OrderFreq", OrderFreq);
    SetCellData(SubID, "OrderFreqRowid", OrderFreqRowid);
    SetCellData(SubID, "OrderFreqFactor", OrderFreqFactor);
    SetCellData(SubID, "OrderFreqInterval", OrderFreqInterval);
    SetCellData(SubID, "OrderFreqDispTimeStr", OrderFreqDispTimeStr);
    var obj = document.getElementById(SubID + '_OrderFreq');
    if (obj) {
	    $(obj).removeClass("clsInvalid");
	}
    if (SubOrderFreqRowid!=OrderFreqRowid){
	    ChangeOrderFreqTimeDoseStr(SubID);
	}
	if ((OrderFreqRowid == GlobalObj.STFreqRowid) || (OrderFreqRowid == GlobalObj.ONCEFreqRowid) || (OrderFreqRowid==GlobalObj.PRNFreqRowid)) {
		//因为频次发生变化，这里直接修改行样式，不能仅修改关联样式
		ChangeRowStyle(SubID,{OrderFirstDayTimes:false,OrderFirstDayTimesCode:false});
	}
    //3.疗程
    var OrderDurRowid = GetCellData(MainID, "OrderDurRowid");
    var OrderDurFactor = GetCellData(MainID, "OrderDurFactor");
    var OrderDur = GetCellData(MainID, "OrderDur");
    /*SetCellData(SubID,"OrderDur",OrderDur);   
    SetCellData(SubID,"OrderDurRowid",OrderDurRowid);
    SetCellData(SubID,"OrderDurFactor",OrderDurFactor);*/
    //4.用法
    var OrderInstrRowid = GetCellData(MainID, "OrderInstrRowid");
    var OrderInstr = GetCellData(MainID, "OrderInstr");
    var InstrRowId = GetCellData(SubID, "OrderInstrRowid");
    if (!IsNotFollowInstr(InstrRowId)) {
        SetCellData(SubID, "OrderInstr", OrderInstr);
        SetCellData(SubID, "OrderInstrRowid", OrderInstrRowid);
    }
    //外用用法 单次剂量和疗程应为空
    var OrderInstrRowid = GetCellData(MainID, "OrderInstrRowid")
    if ((IsWYInstr(OrderInstrRowid)) && (GlobalObj.PAAdmType != "I")) {
        SetCellData(SubID, "OrderDoseQty", "");
    }
    var obj = document.getElementById(SubID + '_OrderInstr');
    if (obj) {
	    $(obj).removeClass("clsInvalid");
	}
    var InstrRowId = GetCellData(SubID, "OrderInstrRowid");
    if (IsWYInstr(InstrRowId)) {
        if (GlobalObj.PAAdmType != "I") {
            SetCellData(SubID, "OrderDur", "");
            SetCellData(SubID, "OrderDurRowid", "");
            SetCellData(SubID, "OrderDurFactor", "");
        }
    } else {
        if (!IsWYInstr(OrderInstrRowid)) {
            SetCellData(SubID, "OrderDur", OrderDur);
            SetCellData(SubID, "OrderDurRowid", OrderDurRowid);
            SetCellData(SubID, "OrderDurFactor", OrderDurFactor);
        }
    }
	var obj = document.getElementById(SubID + '_OrderDur');
    if (obj) {
	    $(obj).removeClass("clsInvalid");
	}
    //5.皮试(根据用法)
    if ((OrderPriorRowid == GlobalObj.LongOrderPriorRowid)&&(GlobalObj.CFSkinTestPriorShort=="1")) {
        SetCellChecked(SubID, "OrderSkinTest", false)
        SetCellData(SubID, "OrderActionRowid", "");
        SetCellData(SubID, "OrderAction", "");
    }
    //皮试用法,子医嘱皮试标识取消勾选
    //---现版本修改为皮试用法需勾选皮试标志-20200416
    //---成组用法为皮试时，注意判断溶媒不需要进行变化
    var OrderHiddenPara = GetCellData(SubID, "OrderHiddenPara");
    var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
    var MainIDOrderHiddenPara = GetCellData(MainID, "OrderHiddenPara");
    var MainIDNeedSkinTestINCI = mPiece(MainIDOrderHiddenPara, String.fromCharCode(1), 7);
    if (GlobalObj.SkinTestInstr != "") {
	    var InstrRowId=GetCellData(SubID, "OrderInstrRowid");
        var Instr = "^" + InstrRowId + "^";
        if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")&&(NeedSkinTestINCI=="Y")) {
	        //SetCellChecked(SubID, "OrderSkinTest", false);
	        SetCellChecked(SubID, "OrderSkinTest", true);
	    }
	    //如果关联的医嘱是皮试引导产生的皮试医嘱，要禁用用法切换
		if (((NeedSkinTestINCI=="Y")||(MainIDNeedSkinTestINCI=="Y"))&&(GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")){
			///
			$.extend(RowStyleObj, {OrderInstr:false});
			
		}
	}
    //6.开始日期
    var OrderStartDate = GetCellData(MainID, "OrderStartDate");
    SetCellData(SubID, "OrderStartDate", OrderStartDate);
    //7.结束日期
    var OrderEndDate = GetCellData(MainID, "OrderEndDate");
    SetCellData(SubID, "OrderEndDate", OrderEndDate);
    //8.开医嘱日期
    var OrderDate = GetCellData(MainID, "OrderDate");
    SetCellData(SubID, "OrderDate", OrderDate);
    //9.首日次数
    var OrderFirstDayTimes = GetCellData(MainID, "OrderFirstDayTimes");
    var OrderFirstDayTimesStr = GetCellData(MainID, "OrderFirstDayTimesStr");
    SetColumnList(SubID, "OrderFirstDayTimesCode", OrderFirstDayTimesStr);
    SetCellData(SubID, "OrderFirstDayTimesCode", OrderFirstDayTimes);
    //10.重新计算数据  会更新首日次数.首日次数和主医嘱保持一致即可
    var SetPackQtyConfig={
		///是否不需要重置首日次数
		IsNotChangeFirstDayTimeFlag:"Y"
	};
    SetPackQty(SubID,SetPackQtyConfig);
    //11.接收科室
    //12.同步滴速和滴速单位
    
    var OrderType = GetCellData(SubID, "OrderType");
    SyncGroupFlowInfo(SubID);
    
    //13.同步输液次数
    var OrderLocalInfusionQty=GetCellData(MainID, "OrderLocalInfusionQty");
    SetCellData(SubID, "OrderLocalInfusionQty", OrderLocalInfusionQty);
    //虚拟长期
    var OrderVirtualtLong = GetCellData(MainID, "OrderVirtualtLong");
    if (EditStatus == true) {
        if (OrderVirtualtLong == "Y") { 
        	OrderVirtualtLong = true; 
        } else { 
        	OrderVirtualtLong = false; 
        }
    }
    SetCellChecked(SubID, "OrderVirtualtLong", OrderVirtualtLong);
    ChangeLinkOrderVirtualtLong(SubID,OrderVirtualtLong);
    // SetCellData(SubID, "OrderVirtualtLong", OrderVirtualtLong);
	if (OrderType=="R"){
	    //配液标记
	    var OrderNeedPIVAFlag = GetCellData(MainID, "OrderNeedPIVAFlag");
	    if (EditStatus == true) {
	        if (OrderNeedPIVAFlag == "Y") { OrderNeedPIVAFlag = true; } else { OrderNeedPIVAFlag = false; }
	        SetCellChecked(SubID, "OrderNeedPIVAFlag", OrderNeedPIVAFlag);
	    }else{
		    if (OrderNeedPIVAFlag=="false") {
			    SetCellData(SubID, "OrderNeedPIVAFlag", "N");
			}else if (OrderNeedPIVAFlag=="true") {
			    SetCellData(SubID, "OrderNeedPIVAFlag", "Y");
			}else{
				SetCellData(SubID, "OrderNeedPIVAFlag", OrderNeedPIVAFlag);
			}
		}
	    //根据配液标记控制是否可以录入整包装数量
	    if ((OrderNeedPIVAFlag) && (OrderNeedPIVAFlag != "N")) {
	        var OrderPackQtyStyleObj = {};
	        var RowDisableStr = GetCellData(MainID, "RowDisableStr");
			if (RowDisableStr!=""){
				var StyleConfigObj = eval("(" + RowDisableStr + ")");
				if (StyleConfigObj) OrderPackQtyStyleObj = { OrderPackQty: StyleConfigObj.OrderPackQty, OrderPackUOM: StyleConfigObj.OrderPackQty }
				SetCellData(SubID, "OrderPackQty", "");
			}
	    } else {
	        var OrderPackQtyStyleObj = ContrlOrderPackQty(SubID);
	    }
	    $.extend(RowStyleObj, OrderPackQtyStyleObj);
    }
    //部位说明 医嘱阶段
    var OrderBodyPartID = GetCellData(MainID, "OrderBodyPartID");
    var OrderBodyPart = GetCellData(MainID, "OrderBodyPart");
    var OrderStageCode = GetCellData(MainID, "OrderStageCode");
    var OrderStage= GetCellData(MainID, "OrderStage");
    SetCellData(SubID, "OrderBodyPart", OrderBodyPartID);
    SetCellData(SubID, "OrderBodyPartID", OrderBodyPartID);
    //医嘱阶段
    SetCellData(SubID, "OrderStageCode", OrderStageCode);
    var EditStatus = GetEditStatus(SubID);
	if (EditStatus){
        SetCellData(SubID, "OrderStage", OrderStageCode);
    }else{
        SetCellData(SubID, "OrderStage", OrderStage);
    }
    //超量原因
    var ExceedReasonID = GetCellData(MainID, "ExceedReasonID");
    var ExceedReason = GetCellData(MainID, "ExceedReason");
    SetCellData(SubID, "ExceedReasonID", ExceedReasonID);
	if (EditStatus){
        SetCellData(SubID, "ExceedReason", ExceedReasonID);
    }else{
        SetCellData(SubID, "ExceedReason", ExceedReason);
    }
	//开医嘱人
    var OrderDoc=GetCellData(MainID, "OrderDoc");
    var OrderDocRowid=GetCellData(MainID, "OrderDocRowid");
    if (EditStatus){
        SetCellData(SubID, "OrderDoc", OrderDocRowid);
    }else{
        SetCellData(SubID, "OrderDoc", OrderDoc);
    }
    SetCellData(SubID, "OrderDocRowid",OrderDocRowid);
    //手术列表
    var OrderOperation=GetCellData(MainID, "OrderOperation");
    var OrderOperationCode=GetCellData(MainID, "OrderOperationCode");
    if (EditStatus){
        SetCellData(SubID, "OrderOperation", OrderOperationCode);
    }else{
        SetCellData(SubID, "OrderOperation", OrderOperation);
    }
    SetCellData(SubID, "OrderOperationCode",OrderOperationCode);
    ChangeCellDisable(SubID, RowStyleObj);
}
//行费别改变事件
function OrderBillTypechangehandler(e) {
    var rowid = GetEventRow(e);
    var oldOrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    var OrderBillTypeRowid = websys_getSrcElement(e).value;
    var PrescCheck = SelectPrescriptItem(OrderARCIMRowid, OrderBillTypeRowid);
    var OrderName = GetCellData(rowid, "OrderName");
    if (PrescCheck == "") {
        $.messager.alert("警告",OrderName + $g(t['LIMIT_PRESCITEM']),"info",function(){
	         SetCellData(rowid, "OrderBillType", oldOrderBillTypeRowid);
	        // 修改费别之后需要从新加载医保类别
	        CreaterOrderInsurCat(rowid);
	        // 重新加载慢病病种
    		CreaterOrderChronicDiag(rowid);
    		// 重新加载诊断分类
		    if (GlobalObj.PAAdmType !="I") {
			    CreaterOrderDIACat(rowid);
			}
	    });
        return false;
    } else {
        // 默认费别改变
        SetCellData(rowid, "OrderBillType", PrescCheck);
        SetCellData(rowid, "OrderBillTypeRowid", PrescCheck);
    }
    // 修改费别之后需要从新加载医保类别
    CreaterOrderInsurCat(rowid);
    // 重新加载慢病病种
    CreaterOrderChronicDiag(rowid);
    // 重新加载诊断分类
    if (GlobalObj.PAAdmType !="I") {
	    CreaterOrderDIACat(rowid);
	}
}
function CreaterOrderDIACat(rowid){
	var OrderDIACat =GetCellData(rowid, "OrderDIACat");
	var OrderDIACatRowId = GetCellData(rowid, "OrderDIACatRowId");
	var OrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
	var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
	var OrderOrderDIACatStr=$.m({
	    ClassName:"web.DHCOEOrdItemView",
	    MethodName:"GetOrderOrderDIACatStr",
	    EpisodeID:GlobalObj.EpisodeID,
	    ArcimRowid:OrderARCIMRowid,
	    OrderBillTypeRowid:OrderBillTypeRowid
	},false);
	SetColumnList(rowid, "OrderDIACat", OrderOrderDIACatStr);
	SetCellData(rowid, "idiagnoscatstr", OrderOrderDIACatStr);
	if (OrderDIACatRowId !=""){
		var  FindFlag="N"
		for (var i=0;i<OrderOrderDIACatStr.split(String.fromCharCode(2));i++){
			var OneOrderDIACatStr = OrderOrderDIACatStr.split(String.fromCharCode(2))[i];
			var OneOrderDIACatRowId = OneOrderDIACatStr.split(String.fromCharCode(1))[0];
			if (OrderDIACatRowId == OneOrderDIACatRowId){
				FindFlag="Y"
			}
		}
		if (FindFlag == "Y") {
			 SetCellData(rowid, "OrderDIACat",OrderDIACat);
			 SetCellData(rowid, "OrderDIACatRowId",OrderDIACatRowId);
		}else{
			SetCellData(rowid, "OrderDIACat","");
			SetCellData(rowid, "OrderDIACatRowId","");
		
		}
	}
}
function CreaterOrderChronicDiag(rowid){
	var OrderChronicDiagCode = GetCellData(rowid, "OrderChronicDiagCode");
	var OrderChronicDiag = GetCellData(rowid, "OrderChronicDiag");
	var OrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
	var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
	var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
	var OrderARCIMCode=OrderHiddenPara.split(String.fromCharCode(1))[11];
	var OrderChronicDiagStr=$.m({
	    ClassName:"web.DHCOEOrdItemView",
	    MethodName:"GetOrderChronicDiagStr",
	    Adm:GlobalObj.EpisodeID,
	    ArcimCode:OrderARCIMCode,
	    OrderBillTypeRowid:OrderBillTypeRowid
	},false);
	SetColumnList(rowid, "OrderChronicDiag", OrderChronicDiagStr);
	SetCellData(rowid, "OrderChronicDiagStr",OrderChronicDiagStr);
	if (OrderChronicDiagCode !="") {
		var  FindFlag="N"
		for (var i=0;i<OrderChronicDiagStr.split(String.fromCharCode(2));i++){
			var OneChronicDiagStr = OrderChronicDiagStr.split(String.fromCharCode(2))[i];
			var OneChronicDiagCode = OneChronicDiagStr.split(String.fromCharCode(1))[0];
			if (OrderChronicDiagCode == OneChronicDiagCode){
				FindFlag="Y"
			}
		}
		if (FindFlag == "Y") {
			 SetCellData(rowid, "OrderChronicDiagCode",OrderChronicDiagCode);
			 SetCellData(rowid, "OrderChronicDiag",OrderChronicDiag);
		}else{
			SetCellData(rowid, "OrderChronicDiagCode","");
			SetCellData(rowid, "OrderChronicDiag","");
		}
	}
}
//频次改变
function FrequencyChangeHandler(e) {
    try {
	    //为了防止在chrome下，鼠标点击lookup的焦点转移事件触发本方法，导致重复弹出week选择框事件
        if (PageLogicObj.LookupPanelIsShow==1) {
            return
        }
    } catch (e) {}
    
    var rowid = GetEventRow(e);
    PHCFRDesc_changehandlerX(rowid);
    return;
}

//医嘱类型改变控制  change
function OrderPriorChange(e) {
    //$.messager.alert("警告",this.id);
    var rowid = "";
    var obj = websys_getSrcElement(e);
    var rowid = GetEventRow(e);
    //改变关联数据  OrderPriorId
    var OldPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    var PriorRowid = obj.value;
    /*
    //判断已经下了出院医嘱或者已经医疗结算的不能开出出院带药以外的医嘱
    if ((GlobalObj.PAADMMedDischarged=="1")&&(PriorRowid!=GlobalObj.OutOrderPriorRowid)){
        dhcsys_alert(t['IsEstimDischarge']);
        DeleteRow(rowid);
        return false;
    }
    */
    if (GlobalObj.SkinTestInstr != "") {
	    var OrderInstrRowid=GetCellData(rowid, "OrderInstrRowid");
        var Instr = "^" + OrderInstrRowid + "^"
        if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
            if (PriorRowid == GlobalObj.LongOrderPriorRowid){
	            $.messager.alert("提示","皮试用法不能选长期医嘱!","info",function(){
		            SetCellData(rowid, "OrderPriorRowid", OldPriorRowid);
		            SetCellData(rowid, "OrderPrior", OldPriorRowid);
		        });
	            return false;
	        }
        }
    }
    var OrderPriorRemarksRowId=GetCellData(rowid, "OrderPriorRemarksRowId")
    if (OrderPriorRemarksRowId==""){
	    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
        var PHCDFCQZTFlag = mPiece(OrderHiddenPara, String.fromCharCode(1), 12);
        var PHCDFONEFlag = mPiece(OrderHiddenPara, String.fromCharCode(1), 13);
        if ((PriorRowid==GlobalObj.LongOrderPriorRowid)&&(PHCDFCQZTFlag=="Y")){
	        SetCellData(rowid, "OrderPriorRemarksRowId", "ZT");
	        SetCellData(rowid, "OrderPriorRemarks", "ZT");
	    }
	    if ((PriorRowid==GlobalObj.ShortOrderPriorRowid)&&(PHCDFONEFlag=="Y")&&(GlobalObj.PAAdmType=="I")){
	        SetCellData(rowid, "OrderPriorRemarksRowId", "ONE");
	        SetCellData(rowid, "OrderPriorRemarks", "ONE");
		}
	}
    OrderPriorchangeCommon(rowid,OldPriorRowid,PriorRowid);
}
//TODO 方法逻辑较多,允许速度慢,待优化
//此方法为医嘱优先级改变方法，如果优先级无变化，则直接退出;
function OrderPriorchangeCommon(Row,OldPriorRowid,PriorRowid,callBackFun) {
    if (OldPriorRowid==PriorRowid) {
	    if (callBackFun) callBackFun();
	    return;
	}
    var ParaPriorRowid=PriorRowid;
    var OrderItemRowid = GetCellData(Row, "OrderItemRowid");
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
    if ((OrderItemRowid != "")) return; //(OrderARCIMRowid == "") || 

    var RowStyleObj = {};
    SetCellData(Row, "OrderPriorRowid", PriorRowid);
    
	//出院带药清空附加说明
    if (PriorRowid == GlobalObj.OutOrderPriorRowid) {
        SetCellData(Row, "OrderPriorRemarksRowId", "");
        SetCellData(Row, "OrderPriorRemarks", "");
    }
	if (PriorRowid != GlobalObj.ShortOrderPriorRowid) {
        var OrderPriorRemarks = GetCellData(Row, "OrderPriorRemarksRowId");
        if (OrderPriorRemarks == "ONE") {
            var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
            var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
            SetCellData(Row, "OrderPriorRemarks", "");
            SetCellData(Row, "OrderPriorRemarksRowId", "");
        }
        // 非临时医嘱加急不可勾选
        SetCellChecked(Row, "Urgent", false);
        var obj = { Urgent: false };
        $.extend(RowStyleObj, obj);
    }else{
	    var OrderHiddenPara=GetCellData(Row,"OrderHiddenPara");
	    var EmergencyFlag = mPiece(OrderHiddenPara, String.fromCharCode(1), 25);
	    var ARCIMDefSensitive = mPiece(OrderHiddenPara, String.fromCharCode(1), 26);
	    if (EmergencyFlag =="Y") {
		    var obj = { Urgent: true };
        	$.extend(RowStyleObj, obj);
		}
		if (ARCIMDefSensitive =="Y") SetCellChecked(Row, "Urgent", true);
	}
	var OrderPriorRemarks = GetCellData(Row, "OrderPriorRemarksRowId");
	var OrderPHPrescType = GetCellData(Row, "OrderPHPrescType");
	var OrderType = GetCellData(Row, "OrderType");
    var OrderFreqRowid = GetCellData(Row, "OrderFreqRowid")
	//非长期医嘱不能开PRN
	if ((PriorRowid != GlobalObj.LongOrderPriorRowid)&&(OrderFreqRowid==GlobalObj.PRNFreqRowid)) {
		ClearOrderFreq(Row);
	}
    if ((PriorRowid == GlobalObj.LongOrderPriorRowid) && ((OrderFreqRowid == GlobalObj.STFreqRowid) || (OrderFreqRowid == GlobalObj.ONCEFreqRowid))) {
        ClearOrderFreq(Row);
    }
    if (GlobalObj.PAAdmType == "I") {
        if ((PriorRowid != GlobalObj.LongOrderPriorRowid) && (PriorRowid != GlobalObj.OutOrderPriorRowid) && ((OrderFreqRowid != GlobalObj.STFreqRowid) || (OrderFreqRowid == GlobalObj.ONCEFreqRowid))) {
            SetCellData(Row, "OrderFreqRowid", GlobalObj.IPShortOrderPriorDefFreqRowId);
            SetCellData(Row, "OrderFreq", GlobalObj.IPShortOrderPriorDefFreq);
        }
    }

    if (
    	(GlobalObj.PAAdmType == "I")&&
    	((PriorRowid == GlobalObj.ShortOrderPriorRowid) || (PriorRowid == GlobalObj.OMOrderPriorRowid))
    	) {
        if ((OrderFreqRowid != GlobalObj.STFreqRowid) && (OrderFreqRowid != GlobalObj.ONCEFreqRowid)&&
        	((OrderPHPrescType == 4) || (OrderType == "R"))&&(GlobalObj.IPShortOrderPriorDefFreqRowId != "")
        	){
		    SetCellData(Row, "OrderFreqRowid", GlobalObj.IPShortOrderPriorDefFreqRowId);
            SetCellData(Row, "OrderFreq", GlobalObj.IPShortOrderPriorDefFreq);
	    }else{
		    if ((OrderFreqRowid != GlobalObj.STFreqRowid) && (OrderFreqRowid != GlobalObj.ONCEFreqRowid)) {
				ClearOrderFreq(Row);
			}
		}
        
    }else if ((PriorRowid == GlobalObj.STATOrderPriorRowid) && (GlobalObj.PAAdmType == "I")) {
	    if (OrderFreqRowid != GlobalObj.STFreqRowid){
		    ClearOrderFreq(Row);
	        SetCellData(Row, "OrderFreqRowid", GlobalObj.STFreqRowid);
	        SetCellData(Row, "OrderFreq", GlobalObj.STFreq);
	    }
    }
    if ((!IsLongPrior(PriorRowid))&&(PriorRowid != GlobalObj.OutOrderPriorRowid)){
    	SetCellData(Row, "OrderFreqTimeDoseStr","");
    	var DoseQtyStr=GetCellData(Row, "OrderDoseQty");
    	if (DoseQtyStr.split("-").length>1){
	    	SetCellData(Row, "OrderDoseQty",mPiece(DoseQtyStr,"-",0));
	    }
    }
    
    var VerifiedOrderFlag=0;
    //护士补录医嘱进行关联设置
    if ((OrderARCIMRowid!="")&&(VerifiedOrderObj) && (VerifiedOrderObj.LinkedMasterOrderFreRowId != "undefined") && (VerifiedOrderObj.LinkedMasterOrderFreRowId != "")) {
        SetCellData(Row, "OrderFreqRowid", VerifiedOrderObj.LinkedMasterOrderFreRowId);
        SetCellData(Row, "OrderFreq", VerifiedOrderObj.LinkedMasterOrderFreDesc);
        SetCellData(Row, "OrderFreqFactor", VerifiedOrderObj.LinkedMasterOrderFreFactor);
        SetCellData(Row, "OrderFreqInterval", VerifiedOrderObj.LinkedMasterOrderFreInterval);
        VerifiedOrderFlag=1;
    }
    SetRecLocStr(Row, PriorRowid, OrderPriorRemarks);

    if ((PriorRowid == GlobalObj.OutOrderPriorRowid) || (OrderPriorRemarks == "ONE") || (PriorRowid == GlobalObj.OneOrderPriorRowid)) {
        //SetPackQty(Row);
    }
    var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo")
    var OrderSeqNo = GetCellData(Row, "id");
    var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
    var OrderMasterPHPrescType="";
    var OrderMasterOrderType="";
    if (OrderMasterSeqNo!=""){
		var rowids = GetAllRowId();
		for (var i = 0; i < rowids.length; i++) {
		    var OrderSeqNoMasterLink = GetCellData(rowids[i], "id");
		    if (OrderSeqNoMasterLink == OrderMasterSeqNo) {
		    	OrderMasterPHPrescType=GetCellData(rowids[i], "OrderPHPrescType");
				OrderMasterOrderType= GetCellData(rowids[i], "OrderType");
		    	break;
		    }
		}
	}
    //疗程列如果为长期医嘱不允许修改疗程,其他可以
    if ((OrderARCIMRowid != "") && (OrderItemRowid == "")) {
        
        if (OrderType == "R") {
            var Id = Row + "_OrderFirstDayTimes";
            var obj = document.getElementById(Id);
            if ((PriorRowid == GlobalObj.LongOrderPriorRowid) || (PriorRowid == GlobalObj.OMSOrderPriorRowid)) {
                var obj = { OrderFirstDayTimes: true };
                $.extend(RowStyleObj, obj);
            } else {
                //清空首日次数
                var obj = { OrderFirstDayTimes: true }; //false
                SetCellData(Row, "OrderFirstDayTimesCode", "");
                $.extend(RowStyleObj, obj);
            }
        }else{
	        if (IsLongPrior(PriorRowid)) {
		        var StyleConfigStr = GetCellData(Row, "StyleConfigStr");
			    var StyleConfigObj = {};
			    if (StyleConfigStr != "") {
			        StyleConfigObj = eval("(" + StyleConfigStr + ")");
			    }
			    var OrderPHPrescType = GetCellData(Row, "OrderPHPrescType");
		        if ((OrderPHPrescType=="4")||(OrderMasterPHPrescType=="4")||(OrderMasterOrderType=="R")){
			        var obj = { OrderDoseQty: true };
	            }else{
		            SetCellData(Row, "OrderDoseQty", "");
	                var obj = { OrderDoseQty: false };
	            }
	            $.extend(RowStyleObj, obj);
		    }else{
			    SetCellData(Row, "OrderDoseQty", "");
				$.extend(RowStyleObj, { OrderDoseQty: false });
			}
	    }
	    var CureItemStyleObj=CheckCureItemConfig(Row);
		$.extend(RowStyleObj, CureItemStyleObj);
        var Id = Row + "_OrderDur";
        var OrderPriorRemarks = GetCellData(Row, "OrderPriorRemarksRowId");
		if (GlobalObj.PAAdmType == "I"){
			var obj = { OrderDur: false };
			if (IsLongPrior(PriorRowid)){
				ClearOrderDur(Row);
			}else if ((PriorRowid==GlobalObj.OutOrderPriorRowid)&&((OrderFreqRowid != GlobalObj.STFreqRowid) && (OrderFreqRowid != GlobalObj.ONCEFreqRowid))){
				var obj = { OrderDur: true };
			}else{
				var OrderDur = GlobalObj.IPDefaultDur;
	            var OrderDurRowid = GlobalObj.IPDefaultDurRowId;
	            var OrderDurFactor = GlobalObj.IPDefaultDurFactor;
	            SetCellData(Row, "OrderDur", OrderDur);
	            SetCellData(Row, "OrderDurRowid", OrderDurRowid);
	            SetCellData(Row, "OrderDurFactor", OrderDurFactor);
			}
			$.extend(RowStyleObj, obj);
		}
       
		var OrderType = GetCellData(Row, "OrderType");
		var OrderHiddenPara = GetCellData(Row, "OrderHiddenPara");
        var OrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
		var RecDepRowid = GetCellData(Row, "OrderRecDepRowid");
		///设置医嘱开始时间
		//SetDosingDateTime(Row,{OrderPriorRowid:PriorRowid,OrderType:OrderType,OrderItemCatRowid:OrderItemCatRowid},RecDepRowid);
		//和数量相关的控制集中写在这里和ContrlOrderPackQty里，tanjishan2019.10.29
        //算数量-
        SetPackQty(Row);
        //数量控制放到最后
        var OrderPackQtyObj = ContrlOrderPackQty(Row);
        //$.messager.alert("警告",OrderPackQtyObj.OrderPackQty);
        $.extend(RowStyleObj, OrderPackQtyObj);
    }
    if (PriorRowid != GlobalObj.ShortOrderPriorRowid) {
        if (GlobalObj.CFSkinTestPriorShort == 1) {
            if (GetEditStatus(Row) == true) {
                SetCellData(Row, "OrderSkinTest", false);
            }else{
                SetCellData(Row, "OrderSkinTest", "N");
            }
            var ActionRowid = GetCellData(Row, "OrderActionRowid");
            var ActionCode = GetOrderActionCode(ActionRowid);
            if (ActionCode == "YY") {
                SetCellData(Row, "OrderActionRowid", "");
                SetCellData(Row, "OrderAction", "");
            }
        }
    }
    /*OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
    if (OrderMasterSeqNo != "") {
	     var obj = { OrderFirstDayTimes: false };
         $.extend(RowStyleObj, obj);
        ChangeCellsDisabledStyle(Row, false);
    }*/
    var OrderPrior = GetCellData(Row, "OrderPrior");
    var OrderStartDateStr = GetCellData(Row, "OrderStartDate");
    if (OrderStartDateStr != "") {
        OrderStartDate = OrderStartDateStr.split(" ")[0];
        OrderStartTime = OrderStartDateStr.split(" ")[1];
    }
    //改变单元格是否可编辑
    ChangeRowStyle(Row, RowStyleObj);
    SetFocusCell(Row, "OrderName");
    ChangeLinkOrderPrior(OrderSeqNo, OrderPriorRowid, OrderStartDate, OrderStartTime, OrderPrior);
    new Promise(function(resolve,rejected){
	    //频次改变
	    if ((VerifiedOrderFlag==0)&&(ParaPriorRowid!=OldPriorRowid)){
	        PHCFRDesc_changehandlerX(Row,resolve);
	    }else{
	        //同步首日次数
	       SetOrderFirstDayTimes(Row);
	       resolve();
	    }
	}).then(function(){
		var OrderSeqNo = GetCellData(Row, "id");
		var MasterOrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
	    var MasterOrderPrior = GetCellData(Row, "OrderPrior");
	    var OrderFreqRowid = GetCellData(Row, "OrderFreqRowid");
	    var OrderFreq = GetCellData(Row, "OrderFreq");
	    var OrderFreqFactor = GetCellData(Row, "OrderFreqFactor");
	    var OrderFreqDispTimeStr = GetCellData(Row, "OrderFreqDispTimeStr");
	    var OrderFreqInterval = GetCellData(Row, "OrderFreqInterval");
	    //关联频次改变
	    ChangeLinkOrderFreq(OrderSeqNo,MasterOrderPriorRowid,MasterOrderPrior,OrderFreqRowid,OrderFreq,OrderFreqFactor,OrderFreqInterval,OrderFreqDispTimeStr,OrderStartDateStr,callBackFun);
		//这里没必要再重复调用静配change，可能会导致重复调用SetPackQty-tanjishan2019.10.29
	    //CancelNeedPIVA(Row)
	})
}
//单次剂量改变控制
function OrderDoseQtychangehandler(e) {
    try {
        var rowid = "";
        var obj = websys_getSrcElement(e);
        if (obj.id.indexOf("_") > 0) {
            rowid = obj.id.split("_")[0];
        }
        var OrderType = GetCellData(rowid, "OrderType");
        var OrderDoseQty = GetCellData(rowid, "OrderDoseQty");
        OrderDoseQty=eval(OrderDoseQty);
        if (typeof(OrderDoseQty)=="undefined"){
	    	OrderDoseQty="";    
	    }
        SetCellData(rowid,"OrderDoseQty",OrderDoseQty);
        var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
		var OrderName=GetCellData(rowid, "OrderName");
		if ((OrderDoseQty != '')&&(isNumber(OrderDoseQty) == false))  {
        	$.messager.alert("警告",OrderName + t['NO_DoseQty'],"info",function(){
	        	SetFocusCell(rowid, "OrderDoseQty");
	        });
       	 	//EditRow(Row);
        	return false;
    	}
		if ((OrderDoseQty!="")&&(parseFloat(OrderDoseQty) < 0) ) {
			$.messager.alert("警告",OrderName + "剂量不能为负数","info",function(){
	        	SetFocusCell(rowid, "OrderDoseQty");
	        });
        	return false;
    	}
        //存在非药品的治疗项目
        //if ((OrderDoseQty != "") && (OrderARCIMRowid != "")) {
	    //20210826 Modify by nk
	    //非药品治疗项目,若填写了单次数量计算出数量后又把单次清空，会导致执行数量不正确的问题,因此需计算数量
	    if (OrderARCIMRowid != "") {
	        var SetPackQtyConfig={
				///是否不需要重置整包装数
				IsNotNeedChangeFlag:undefined,
				///是否不需要重置首日次数
				IsNotChangeFirstDayTimeFlag:undefined
			};
			
			var OrderFirstDayTimes=GetCellData(rowid, "OrderFirstDayTimes");
			if (OrderFirstDayTimes!=""){
				SetPackQtyConfig.IsNotChangeFirstDayTimeFlag="Y";
			}
            SetPackQty(rowid,SetPackQtyConfig);
            //websys_setfocus("OrderMasterSeqNoz"+Row);
        } else {
            //websys_setfocus("OrderPackQtyz"+Row);
        }
        XHZY_Click();
    } catch (e) {}
}
function OrderDoseQtykeyuphandler(e){
	try { keycode = websys_getKey(e); } catch (e) { keycode = websys_getKey(); }
	try { 
		if([38,40].indexOf(keycode)>-1){
			var rowid = GetEventRow(e);
			var OrderDoseQty = GetCellData(rowid, "OrderDoseQty");
			var OrderDoseQtyNew=GetDoseEqQty(rowid);
            if(!OrderDoseQty||!OrderDoseQtyNew) return websys_cancel()
            if(keycode==40) OrderDoseQtyNew=0-OrderDoseQtyNew;
            if (OrderDoseQty.indexOf("-")>=0) {
				var NewOrderFreqTimeDoseStr="";
	            var OrderFreqTimeDoseStr=GetCellData(rowid, "OrderFreqTimeDoseStr");
				var strArr=OrderFreqTimeDoseStr.split('@');
				for(var i=0;i<strArr.length;i++){
					var OneDoseQtyStr="";
					var FreqTimeDoseStrArr=strArr[i].split('!');
					for(var j=0;j<FreqTimeDoseStrArr.length;j++){
						var DoseQty=FreqTimeDoseStrArr[j].split("$")[1];
						if(DoseQty=="") continue;
						var tmpOrderDoseQty=NumberAdd(DoseQty,OrderDoseQtyNew);
						if(tmpOrderDoseQty<=0){
							$.messager.alert("提示","单次剂量不得小于等于0!","info",function(){
								SetFocusCell(rowid, "OrderDoseQty");
							});
							return false;
						}
						var DispID=FreqTimeDoseStrArr[j].split("$")[0];
						if (OneDoseQtyStr=="") OneDoseQtyStr=DispID+'$'+tmpOrderDoseQty;
						else  OneDoseQtyStr=OneDoseQtyStr+"!"+DispID+'$'+tmpOrderDoseQty;
					}
					if(NewOrderFreqTimeDoseStr=='') NewOrderFreqTimeDoseStr=OneDoseQtyStr;
					else  NewOrderFreqTimeDoseStr=NewOrderFreqTimeDoseStr+'@'+OneDoseQtyStr;
				}
				var NewOrderDoseQtyStr=GetDoseQty(NewOrderFreqTimeDoseStr);
		        SetCellData(rowid, "OrderDoseQty",NewOrderDoseQtyStr);
		        SetCellData(rowid, "OrderFreqTimeDoseStr",NewOrderFreqTimeDoseStr);
	        }else{
		        var tmpOrderDoseQty=NumberAdd(OrderDoseQty,OrderDoseQtyNew);
		        if(tmpOrderDoseQty<=0){
		            $.messager.alert("提示","单次剂量不得小于等于0！","info",function(){
						SetFocusCell(rowid, "OrderDoseQty");
					});
		            return false;
	            }
				SetCellData(rowid, "OrderDoseQty",tmpOrderDoseQty);
				OrderDoseQtychangehandler();
			}
			return websys_cancel();
		}
	} catch (e) {}
	function NumberAdd(){
		var Result=0;
		var MaxDecimalPlace=0;	//加数最大小数位数
		for(var i=0;i<arguments.length;i++){
			var Num=parseFloat(arguments[i]);
			Result+=Num;
			var Decimal=Num.toString().split(".")[1];
			var DecimalPlace=Decimal?Decimal.length:0;
			if(DecimalPlace>MaxDecimalPlace) MaxDecimalPlace=DecimalPlace;
		}
		return parseFloat(Result.toFixed(MaxDecimalPlace));
	}
	function GetDoseEqQty(rowid){
		var OrderDoseUOMRowid=GetCellData(rowid, "OrderDoseUOMRowid")
		if(!OrderDoseUOMRowid) return "";
		var OrderDoseQtyNew ="";
		var idoseqtystr=GetCellData(rowid, "idoseqtystr");	//.split(String.fromCharCode(2))
		var ArrData = idoseqtystr.split(String.fromCharCode(2));
        for (var i = 0; i < ArrData.length; i++) {
            var ArrData1 = ArrData[i].split(String.fromCharCode(1));
            var DefaultDoseUOMRowid = ArrData1[2];
			if(DefaultDoseUOMRowid==OrderDoseUOMRowid){
				OrderDoseQtyNew=ArrData1[4]?ArrData1[4]:ArrData1[0];
			}
		}
		if(OrderDoseQtyNew==""){
			var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
			var OrderDoseQtyNew = parseFloat(mPiece(OrderHiddenPara, String.fromCharCode(1), 16));
		}
		return OrderDoseQtyNew;
	}
}
function OrderDoseQtykeydownhandler(e) {
    try { keycode = websys_getKey(e); } catch (e) { keycode = websys_getKey(); }
    try {
        if ((keycode == 13) || (keycode == 9)) {
            var rowid = GetEventRow(e);
            var OrderType = GetCellData(rowid, "OrderType");
            var OrderDoseQty = GetCellData(rowid, "OrderDoseQty");
            var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
            if (OrderARCIMRowid != "") {
                if (OrderType == "R") {
                    XHZY_Click();
                    SetFocusCell(rowid, "OrderMasterSeqNo")
                } else {
                    var OrderPHPrescType = GetCellData(rowid, "OrderPHPrescType");
                    if (OrderPHPrescType != "4") {
                        //长期医嘱数量不可录入,所有需要考虑跳转到下一行
                        var type = "";
                        if (window.event) type = websys_getType(e);
                        if (type != 'change') {
                            var JumpAry = ['OrderPackQty'];
                            CellFocusJump(rowid, JumpAry, true);
                        }
                    } else {
                        SetFocusCell(rowid, "OrderFreq")
                    }
                }
            }
            return websys_cancel();
        }else{
            if (((keycode >= 46) && (keycode < 58))||(keycode==42)||(keycode==106)) {} else {
                window.event.keyCode = 0;
                return websys_cancel();
            }
        }
    } catch (e) {}
}

function OrderPricechangehandler(e) {
	var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
	var OrderPrice=GetCellData(rowid,"OrderPrice");
	if ($.isNumeric(OrderPrice) == true) {
		OrderPackQtychangehandler(e)
	}else{
		$.messager.alert("提示","单价为非数字,请修改!","info",function(){
			SetFocusCell(rowid, "OrderPrice")
		});
		return false;
	}
}
//数量改变控制
function OrderPackQtychangehandler(e) {
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    OrderPackQtychangeCommon(rowid);
}
function OrderPackQtychangeCommon(rowid) {
    try {
        var OrderPackQty = GetCellData(rowid, "OrderPackQty");
        var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
        var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
        var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");

        if (OrderPackQty == "") { OrderPackQty = 0 }
        if(isNaN(OrderPackQty)){
	        OrderPackQty=0;
	    }
        if ((OrderARCIMRowid != "") && (OrderItemRowid == "")) {
            var OrderPrice = GetCellData(rowid, "OrderPrice");
            var OrderSum = parseFloat(OrderPrice) * parseFloat(OrderPackQty);
            if (OrderPackQty == 0) {
                var BaseDoseQtySum = GetCellData(rowid, "OrderBaseQtySum");
                var OrderConFac = GetCellData(rowid, "OrderConFac");
                var OrderSum = (parseFloat(OrderPrice) / parseFloat(OrderConFac)) * parseFloat(BaseDoseQtySum);
            }
            OrderSum = OrderSum.toFixed(4);
            //可用天数
            SetOrderUsableDays(rowid)
                //如果是自备药医嘱则不用再计算金额
                //$.messager.alert("警告",OrderPriorRowid+","+GlobalObj.OMOrderPriorRowid+","+GlobalObj.OMSOrderPriorRowid);
            if ((OrderPriorRowid != GlobalObj.OMOrderPriorRowid) && (OrderPriorRowid != GlobalObj.OMSOrderPriorRowid)) {
                SetCellData(rowid, "OrderSum", OrderSum);
				GetBindOrdItemTip(rowid);
                SetScreenSum();
                //SetFooterData();
            }
        }
        XHZY_Click();
    } catch (e) {}
}
function OrderPackQtykeydownhandler(e) {
    try { keycode = websys_getKey(e); } catch (e) { keycode = websys_getKey(); }
    if ((keycode == 8) || (keycode == 9) || (keycode == 46) || (keycode == 13) || ((keycode > 47) && (keycode < 58)) || ((keycode > 95) && (keycode < 106))) {
        var rowid = "";
        var obj = websys_getSrcElement(e);
        if (obj.id.indexOf("_") > 0) {
            rowid = obj.id.split("_")[0];
        }
        if (keycode==46){
	       var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
	       if (OrderARCIMRowid!=""){
		       var SubCatID = cspRunServerMethod(GlobalObj.GetARCItemSubCatID, '', '', OrderARCIMRowid);
		       var AllowEntryDecimalItemCatStr = "^" + GlobalObj.AllowEntryDecimalItemCat + "^";
			   if ((AllowEntryDecimalItemCatStr.indexOf("^" + SubCatID + "^")) == -1) {
				   return websys_cancel();
			   }
		    } 
	    }
		try {
            if ((keycode == 13) || (keycode == 9)) {
                var OrderARCOSRowId = GetCellData(rowid, "OrderARCOSRowId");
                var rowsobj = $('#Order_DataGrid').getDataIDs();
                var rows = rowsobj.length;
                var RowNext = GetNextRowId();
                if ((GlobalObj.FindARCOSInputByLogonLoc == 1) && (OrderARCOSRowId != '') && (rows != RowNext)) {
                    SetFocusCell(RowNext, "OrderPackQty");
                    return websys_cancel();
                } else {
                    window.event.keyCode = 0;
                    var OrderInstrRowid = GetCellData(rowid, "OrderInstrRowid");
                    var OrderPackQty = GetCellData(rowid, "OrderPackQty");
                    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
                    var OrderType = GetCellData(rowid, "OrderType");
                    if (OrderARCIMRowid != "") {
                        if ((GlobalObj.DrippingSpeedInstr).indexOf("^"+OrderInstrRowid+"^")>=0) {
	                         SetFocusCell(rowid, "OrderSpeedFlowRate");
                    		 return websys_cancel();
	                    }
                        if ((GlobalObj.PAAdmType == "I") || ((GlobalObj.PAAdmType != "I") && (OrderPackQty != ""))) {
                            window.setTimeout("Add_Order_row()", 200);
                        }
                    }
                }
                return websys_cancel();
            }
        } catch (e) {}
    } else {
        return websys_cancel();
    }
}
//剂量单位改变控制
function OrderDoseUOMchangehandler(e) {
    //$.messager.alert("警告",this.id);
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    //改变关联数据  OrderPriorId
    SetCellData(rowid, "OrderDoseUOMRowid", obj.value);
    SetCellData(rowid, "OrderDoseUOM", obj.value);
    var SetPackQtyConfig={
		///是否不需要重置整包装数
		IsNotNeedChangeFlag:undefined,
		///是否不需要重置首日次数
		IsNotChangeFirstDayTimeFlag:undefined
	};
	var OrderFirstDayTimes=GetCellData(rowid, "OrderFirstDayTimes");
	if (OrderFirstDayTimes!=""){
		SetPackQtyConfig.IsNotChangeFirstDayTimeFlag="Y";
	}
    SetPackQty(rowid,SetPackQtyConfig);
    var idoseqtystr=GetCellData(rowid, "idoseqtystr");
    if (idoseqtystr!=""){
	    var ArrData = idoseqtystr.split(String.fromCharCode(2));
        for (var i = 0; i < ArrData.length; i++) {
            var ArrData1 = ArrData[i].split(String.fromCharCode(1));
            var DefaultDoseQty = ArrData1[0];
            var DefaultDoseUOMRowid = ArrData1[2];
            if (DefaultDoseUOMRowid==obj.value){
	            var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara"); 
	            var Arr=OrderHiddenPara.split(String.fromCharCode(1));
	            Arr.splice(16,1,DefaultDoseQty);
	            SetCellData(rowid, "OrderHiddenPara",Arr.join(String.fromCharCode(1)));
	            break;
	        }
        }
	}
	SetFocusCell(rowid, "OrderDoseQty");
}
//附加说明改变控制
function OrderPriorRemarkschangehandler(e) {
    //$.messager.alert("警告",this.id);
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    var OldOrderPriorRemarksRowId=GetCellData(rowid, "OrderPriorRemarksRowId");
    var OrderPriorRemarksRowId = obj.value;
	new Promise(function(resolve,rejected){
		if (OrderPriorRemarksRowId=="ONE"){
			var rowids=GetSeqNolist(rowid);
			if (rowids.length){
				$.messager.confirm('确认对话框', "取药医嘱不能是成组医嘱，是否需要结束关联 ?", function(r){
					if (r) {
						for(var i=0;i<rowids.length;i++){
							$("#Order_DataGrid").setSelection(rowids[i], false);
						}
						if (!ClearSeqNohandler()) return false;
						PageLogicObj.IsStartOrdSeqLink=0;
						PageLogicObj.StartMasterOrdSeq="";
						$("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("开始关联(R)");
					}else{
						SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
						SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
						return false;
					}
					resolve();
				});
			}else{
				resolve();
			}
		}else{
			resolve();
		}
	}).then(function(){
		OrderPriorRemarkschangeCommon(rowid,OldOrderPriorRemarksRowId,OrderPriorRemarksRowId);
	});
}
function OrderPriorRemarkschangeCommon(rowid,OldOrderPriorRemarksRowId,OrderPriorRemarksRowId){
    if (OrderPriorRemarksRowId=="ONE"){
	    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
	    if ((OrderMasterSeqNo != "")||($("#" + rowid).find("td").hasClass("OrderMasterM"))){
		    $.messager.alert("提示","成组医嘱不能为取药医嘱!","info",function(){
			     SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
    			 SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
			})
		    return false;
		}
	}
	var OrderVirtualtLong=GetCellData(rowid, "OrderVirtualtLong");
	var OrderHiddenPara=GetCellData(rowid,"OrderHiddenPara");
	//可拆分发药的接受科室串
	var NormSplitPackQtyPHRecLocList = mPiece(OrderHiddenPara, String.fromCharCode(1), 24);
	var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
	var NormSplitPackQty=0
	if ((NormSplitPackQtyPHRecLocList!="")&&(("!"+NormSplitPackQtyPHRecLocList+"!").indexOf("!"+OrderRecDepRowid+"!")!=-1)){
    	NormSplitPackQty=1;
    }
    if ((NormSplitPackQty==0)&&(OrderVirtualtLong=="Y")){
		if (OrderPriorRemarksRowId==""){
			$.messager.alert("提示","该医嘱为虚拟长期且不可拆包装发药，附加说明必填!","info",function(){
			     SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
    			 SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
			})
		    return false;
		}   
	}
    SetCellData(rowid, "OrderPriorRemarksRowId", OrderPriorRemarksRowId);
    SetCellData(rowid, "OrderPriorRemarks", OrderPriorRemarksRowId);
    var OrderSum=GetCellData(rowid, "OrderSum");
    if (+OrderSum==0){
	    SetPackQty(rowid);
	}
    var ret=CheckOrderPriorRemarks(rowid,OldOrderPriorRemarksRowId);
    if (!ret){
        SetScreenSum();
        return;
    }
    if (GlobalObj.PAAdmType == "I") {
	    var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
	    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
		var OrderPriorRemarks = GetCellData(rowid,"OrderPriorRemarksRowId");
		if ((OrderPriorRowid == GlobalObj.ShortOrderPriorRowid)) {
			if((OrderPriorRemarks != "ONE")&&(OrderFreqRowid != GlobalObj.STFreqRowid)&&(OrderFreqRowid != GlobalObj.ONCEFreqRowid)){
				ClearOrderFreq(rowid);
				SetCellData(rowid, "OrderFreqRowid", GlobalObj.IPShortOrderPriorDefFreqRowId);
            	SetCellData(rowid, "OrderFreq", GlobalObj.IPShortOrderPriorDefFreq);
            	SetCellData(rowid, "OrderFreqFactor",1);
				SetOrderFirstDayTimes(rowid);
				PHCFRDesc_changehandlerX(rowid);
			}
		}
    }
	
    ///取药医嘱开放频次疗程
    FreqDurChange(rowid)
}
function CheckOrderPriorRemarksLegal(rowid,OldOrderPriorRemarksRowId){
	if (typeof OldOrderPriorRemarksRowId == "undefined") {
    	OldOrderPriorRemarksRowId = "";
    }
	///和 web.DHCOEOrdItemView中的CheckOrderPriorRemarks重复，暂时不考虑合并
	var rows = $('#Order_DataGrid').getDataIDs();
	var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
	var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    if (OrderPriorRemarks != "OM") { SetCellChecked(rowid, "OrderSelfOMFlag", false); }
    if (OrderPriorRemarks == "ONE") {
        var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
        if (OrderPriorRowid != GlobalObj.ShortOrderPriorRowid) {
            $.messager.alert("提示", "取药医嘱只能是临时医嘱","info",function(){
	        });
			SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
			SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
            return false;
        }
        if ((OrderMasterSeqNo != "") && (OrderPriorRowid != GlobalObj.ShortOrderPriorRowid)) {
            $.messager.alert("提示", "关联医嘱,不允许选择取药医嘱","info",function(){
	        });
			SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
			SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
            return false;

            //取药医嘱暂时不给予关联。
            var OrderSeqNo = GetCellData(rowid, "OrderSeqNo");
            for (i = 0; i < rows.length; i++) {
                var RowGet = rows[i];
                var MasterOrderSeqNo = GetCellData(RowGet, "OrderMasterSeqNo");
                if ((MasterOrderSeqNo != "") && (OrderSeqNo == MasterOrderSeqNo)) {
                    $.messager.alert("提示", "关联医嘱,不允许选择取药医嘱","info",function(){
			        });
					SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
					SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
                    return false;
                }
            }
        }
        //取药医嘱暂时不给予关联。
        for (i = 0; i < rows.length; i++) {
            var RowGet = rows[i];
            var MasterOrderSeqNo = GetCellData(RowGet, "OrderMasterSeqNo");
            if ((MasterOrderSeqNo != "") && (rowid == MasterOrderSeqNo) && (OrderPriorRowid != GlobalObj.ShortOrderPriorRowid)) {
                $.messager.alert("提示", "关联医嘱,不允许选择取药医嘱","info",function(){
	        	});
				SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
				SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
                return false;
            }
        }
        //非药品医嘱不能选择取药医嘱
        var OrderType = GetCellData(rowid, "OrderType");
        if ((OrderType != "R")&& (OrderARCIMRowid != "")) {
            $.messager.alert("提示", "非药品医嘱,不允许选择取药医嘱","info",function(){
	        });
			SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
			SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
            return false;
        }
    }
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    if ((OrderPriorRemarks == "OM") && (OrderARCIMRowid != "")) {
        //SetCellChecked(rowid,"OrderSelfOMFlag",true)
        var OrderType = GetCellData(rowid, "OrderType");
        if (OrderType != "R") {
            $.messager.alert("提示", "非药品医嘱,不允许选择自备药","info",function(){
	        });
			SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
			SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
			SetCellChecked(rowid, "OrderSelfOMFlag", false)
            return false;
        }
    }
    if ((OrderPriorRemarks == "ZT") && (GlobalObj.PAAdmType == "I")) {
        var OrderPrice = GetCellData(rowid, "OrderPrice");
        var OrderType = GetCellData(rowid, "OrderType");
        if ((OrderType != "R") && (+OrderPrice != 0)) {
            $.messager.alert("提示", "住院患者只有药品或0费用医嘱才能选择嘱托","info",function(){
	        });
			SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
			SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
            return false;
        }
    }
	if((OrderPriorRowid==GlobalObj.OutOrderPriorRowid)&&(OrderPriorRemarks!="")){
		$.messager.alert("提示", "出院带药不允许选择附加说明","info",function(){
	   });
	   SetCellData(rowid, "OrderPriorRemarksRowId", OldOrderPriorRemarksRowId);
	   SetCellData(rowid, "OrderPriorRemarks", OldOrderPriorRemarksRowId);
	   return false;
	}
	return true;
}
function CheckOrderPriorRemarks(rowid,OldOrderPriorRemarksRowId) {
	if (typeof OldOrderPriorRemarksRowId == "undefined") {
    	OldOrderPriorRemarksRowId = "";
    }
    var PriorRowid = "";
    //----------------------6-9---------------------------
    if (!CheckOrderPriorRemarksLegal(rowid,OldOrderPriorRemarksRowId)){
		return false;
	}
	var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
    var SetPackQtyConfig={
		///是否不需要重置整包装数
		IsNotNeedChangeFlag:undefined,
		///是否不需要重置首日次数
		IsNotChangeFirstDayTimeFlag:undefined
	};
    switch (OrderPriorRemarks) {
        case "ONE":
            PriorRowid = GlobalObj.ShortOrderPriorRowid;
            var SetPackQtyConfig={
				///是否不需要重置整包装数
				IsNotNeedChangeFlag:"N",
				///是否不需要重置首日次数
				IsNotChangeFirstDayTimeFlag:undefined
			};
			//临时切换到取药医嘱先清空数量 否则‘取药/出院带药可发基本单位’无效(因为已有整包装数量)
			SetCellData(rowid, "OrderPackQty", '');
		 	break;
        default:
        	$.extend(SetPackQtyConfig, {IsNotChangeFirstDayTimeFlag:"Y"});
        	break;
    }
	var OrderFirstDayTimes=GetCellData(rowid, "OrderFirstDayTimes");
    var OldPriorRowid = GetCellData(rowid, "OrderPriorRowid");
	var OrderNotifyClinician = GetCellData(rowid, "Urgent");
    if (PriorRowid == "") {
        PriorRowid = OldPriorRowid;
        //if((OrderPriorRemarks=="OM")||(OrderPriorRemarks=="ZT")) SetScreenSum();
    } else {
        if (GlobalObj.isEditCopyItem=='Y') {
            SetCellData(rowid, "OrderPrior", PriorRowid);
        }
        //SetCellData(rowid,"OrderPrior",PriorRowid);
        //TODO 此处调用此方法正确,但此方法逻辑较多,速度慢,待优化
        //OrderPriorchangeCommon(rowid, OldPriorRowid, PriorRowid);
    }
	//目前不会存在主动切换医嘱类型的情况，if逻辑仅为了方便查看-tanjishan2019.10.29
	if (OldPriorRowid!=PriorRowid){
		OrderPriorchangeCommon(rowid,OldPriorRowid,PriorRowid);
	}else{
		SetRecLocStr(rowid, PriorRowid, OrderPriorRemarks);
		if (SetPackQtyConfig.IsNotChangeFirstDayTimeFlag=="Y"){
			SetCellData(rowid, "OrderFirstDayTimesCode", OrderFirstDayTimes);
		}
        var OrderPackQtyStyleObj = ContrlOrderPackQty(rowid);
        ChangeCellDisable(rowid, OrderPackQtyStyleObj);
        SetPackQty(rowid,SetPackQtyConfig);
    }
	GetBindOrdItemTip(rowid);
    SetScreenSum();
    return true;
}
//接收科室改变控制
function OrderRecDepchangehandler(e) {
    //$.messager.alert("警告",this.id);
    var rowid = GetEventRow(e);
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    SetCellData(rowid, "OrderRecDepRowid", obj.value);
    SetCellData(rowid, "OrderRecDep", obj.value);
	OrderRecDepchange(rowid);
}
function OrderRecDepchange(rowid){
    var OrderType = GetCellData(rowid, "OrderType");
    
    var OrderType=GetCellData(rowid, "OrderType");
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
	var MainID=GetRowIdByOrdSeqNo(OrderMasterSeqNo);
    var OrderRecDepRowid=GetCellData(rowid, "OrderRecDepRowid");
    if ((OrderType=="R")&&(GlobalObj.CFSameRecDepForGroup!=1)&&(OrderMasterSeqNo!="")) { //未成组医嘱接收科室一致，若修改子医嘱接收科室科室为静配科室需同步主医嘱
		if ((GlobalObj.IPDosingRecLocStr!="")&&(("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + OrderRecDepRowid + "^") >= 0)){ 

			var FindMainRecDep = false;
			var MainOrderName= GetCellData(MainID, "OrderName");
		    var MainCurrentRecLocStr = GetCellData(MainID, "CurrentRecLocStr")
            var ArrData = MainCurrentRecLocStr.split(String.fromCharCode(2));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                if (ArrData1[0] == OrderRecDepRowid) { FindMainRecDep = true };
            }
            if (FindMainRecDep == false) {
                $.messager.alert("警告",$g("主医嘱")+MainOrderName+$g("未找到与子医嘱一致的静配接收科室!"),"info",function(){
	                //清空关联
					ClearOrderMasterSeqNo(rowid);
					OrderMasterHandler(rowid, "C");
					CheckMasterOrdStyle();
	            });
                return false;
            }
		    var OrderRecDep=GetCellData(rowid, "OrderRecDep");
		    
		    var EditStatus = GetEditStatus(MainID);
            SetCellData(MainID, "OrderRecDepRowid", OrderRecDepRowid);
            if (EditStatus == true) {
                SetCellData(MainID, "OrderRecDep", OrderRecDepRowid);
            } else {
                SetCellData(MainID, "OrderRecDep", OrderRecDep);
            }
            
			OrderRecDepChangeCom(MainID);
		}else{
			OrderRecDepChangeCom(rowid);
		}
	}else{
    	OrderRecDepChangeCom(rowid);
    }
    SetVirtualtLongRemark(rowid)
}
function OrderRecDepChangeCom(rowid) {
    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    var OrderStartDate = "";
    var OrderType = GetCellData(rowid, "OrderType");
    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    var OrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
    var RecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
	///设置医嘱开始时间
	//SetDosingDateTime(rowid,{OrderPriorRowid:OrderPriorRowid,OrderType:OrderType,OrderItemCatRowid:OrderItemCatRowid},RecDepRowid);
	OrderStartDateStr = GetCellData(rowid, "OrderStartDate"); //OrderStartDateStr
    //协议单位切换
    GetBillUOMStr(rowid);
    CellDataPropertyChange(rowid, "OrderRecDep", "olddata", "newdata");
    ChangeLinkOrderRecDep(rowid, RecDepRowid, OrderStartDateStr)
    var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid")
    if ((GlobalObj.IPDosingRecLocStr != "")&&(OrderType == "R")) {
        if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + OrderRecDepRowid + "^") >= 0) {
            SetCellChecked(rowid, "OrderNeedPIVAFlag", true);
        } else {
            SetCellChecked(rowid, "OrderNeedPIVAFlag", false);
        }
        CancelNeedPIVA(rowid);
    }
}
//标本改变控制
function OrderLabSpecchangehandler(e) {
    //$.messager.alert("警告",this.id);
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    //$.messager.alert("警告",this.value);
    SetCellData(rowid, "OrderLabSpecRowid", obj.value);
    OrderLabSpecCollectionSiteChange(rowid);
    initItemInstrDiv(rowid);
    GetBindOrdItemTip(rowid);
}
//皮试备注改变控制
function OrderActionchangehandler(e) {
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    var OldOrderActionRowid=GetCellData(rowid, "OrderActionRowid");
    //$.messager.alert("警告",this.value);
    var ActionRowid = obj.value;
    SetCellData(rowid, "OrderActionRowid", ActionRowid);
    SetCellData(rowid, "OrderAction", ActionRowid);
    //$.messager.alert("警告",ActionRowid);
    var OrderName=GetCellData(rowid,"OrderName");
    var ActionCode = GetOrderActionCode(ActionRowid);
    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    var SkinTestYY = mPiece(OrderHiddenPara, String.fromCharCode(1), 0);
    if ((SkinTestYY=="1")&&(ActionCode=="PSJ")){
		$.messager.alert("提示",OrderName + $g("该医嘱配置了门诊皮试用原液或住院皮试用原液,皮试配置不能选择皮试剂!"),"info"
			,function(){
				SetCellData(rowid, "OrderAction", OldOrderActionRowid);
				SetCellData(rowid, "OrderActionRowid", OldOrderActionRowid);
		});
       
    	return false;
	}
    var styleConfigObj = { OrderSkinTest: false };
	new Promise(function(resolve,rejected){
		if (ActionCode == "XZ"){
			var OrderARCIMRowid = GetCellData(rowid,"OrderARCIMRowid");
			var Ret = tkMakeServerCall("web.DHCDocOrderCommon", "OrdSkinTestRule", OrderARCIMRowid,GlobalObj.EpisodeID);
			if (Ret==""){
				$.messager.confirm('确认对话框', OrderName + $g("患者72小时内无皮试结果,是否继续？"), function(r){
					if (!r) {
						SetCellData(rowid, "OrderActionRowid", "");
						SetCellData(rowid, "OrderAction", "");
						var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
						var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
						if (NeedSkinTestINCI=="Y"){
							styleConfigObj = { OrderSkinTest: false }
						}else{
							styleConfigObj = { OrderSkinTest: true }
						}
						ChangeCellDisable(rowid, styleConfigObj);
						return false;
					}
					SetCellChecked(rowid, "OrderSkinTest", false)
					resolve();
				});
				return false
			}else if(Ret=="1"){
				$.messager.confirm('确认对话框', OrderName + $g("患者72小时内有皮试结果为【阳性】,是否继续？"), function(r){
					if (!r) {
						SetCellData(rowid, "OrderActionRowid", "");
						SetCellData(rowid, "OrderAction", "");
						var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
						var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
						if (NeedSkinTestINCI=="Y"){
							styleConfigObj = { OrderSkinTest: false }
						}else{
							styleConfigObj = { OrderSkinTest: true }
						}
						ChangeCellDisable(rowid, styleConfigObj);
						return false;
					}
					resolve();
				});
				return false
			}
			SetCellChecked(rowid, "OrderSkinTest", false)
			resolve();
			return false;
		} else if ((ActionCode == "MS") || (ActionCode == "XZ") || (ActionCode == "TM")) {
			SetCellChecked(rowid, "OrderSkinTest", false)
		} else if ((ActionCode == "YY")||(ActionCode == "PSJ")) {
			SetCellChecked(rowid, "OrderSkinTest", true)
		} else if (ActionCode == "YX") {
			//皮试阴性
			SetCellChecked(rowid, "OrderSkinTest", false)
			styleConfigObj = { OrderSkinTest: false }
		} else {
			//如果选择为空按照药学项上标志设置皮试勾选
			var NeedSkinTestINCI="N"
			if (ActionRowid==""){
				var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
				NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
			}
			if (NeedSkinTestINCI=="Y"){
				SetCellChecked(rowid, "OrderSkinTest", true)
			}else{
				styleConfigObj = { OrderSkinTest: true }
			}
		}
		resolve();
	}).then(function(){
		return new Promise(function(resolve,rejected){
			var StyleConfigStr=GetCellData(rowid, "StyleConfigStr");
			var oldStyleConfigobj = eval("(" + StyleConfigStr + ")");
			$.extend(oldStyleConfigobj, styleConfigObj);
			var StyleConfigStr = JSON.stringify(oldStyleConfigobj);
			SetCellData(rowid, "StyleConfigStr", StyleConfigStr);
			ChangeCellDisable(rowid, styleConfigObj);
			//根据配置和页面是否强制医嘱类型,来决定是否切换到临时
			var OldPriorRowid = GetCellData(rowid, "OrderPriorRowid")
			var OrderSkinTest = GetCellData(rowid, "OrderSkinTest")
			if ((GlobalObj.CFSkinTestPriorShort == 1) && (OrderSkinTest == "Y")) { //&&(GlobalObj.OrderPriorContrlConfig!=1)
				if (GlobalObj.OrderPriorContrlConfig == 1) {
					SetColumnList(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid + ":" + "临时医嘱");
					SetCellData(rowid, "OrderPriorStr", GlobalObj.ShortOrderPriorRowid + ":" + "临时医嘱");
				}
				SetCellData(rowid, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
				SetCellData(rowid, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
				OrderPriorchangeCommon(rowid,OldPriorRowid,GlobalObj.ShortOrderPriorRowid);
			}
			GetBindOrdItemTip(rowid);
		});
	});
}
function GetOrderActionCode(OrderActionRowid) {
    if (GlobalObj.OrderActionStr == "") { return "" }
    var OrderPriorArray = GlobalObj.OrderActionStr.split("^");
    for (var i = 0; i < OrderPriorArray.length; i++) {
        var OrderPrior = OrderPriorArray[i].split(String.fromCharCode(1));
        if (OrderPrior[0] == OrderActionRowid) {
            return OrderPrior[1];
        }
    }
    return "";
}
//诊断类别改变控制
function OrderDIACatchangehandler(e) {
    //$.messager.alert("警告",this.id);
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    //$.messager.alert("警告",this.value);
    SetCellData(rowid, "OrderDIACatRowId", obj.value);
    SetCellData(rowid, "OrderDIACat", obj.value);
}
function ChangeLinkOrderSpeedFlowRate(OrderSeqNo, OrderSpeedFlowRate) {
    try {
        var rows = GetAllRowId();
        for (var i = 1; i < rows; i++) {
            var Row = rows[i];
            var OrderMasterSeqNo = GetColumnData("OrderMasterSeqNo", Row);
            var OrderItemRowid = GetColumnData("OrderItemRowid", Row);
            var OrderARCIMRowid = GetColumnData("OrderARCIMRowid", Row);

            if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && (OrderMasterSeqNo == OrderSeqNo)) {
	            var OrderType = GetCellData(Row, "OrderType");
    			if (OrderType!="R") continue;
                SetColumnData("OrderSpeedFlowRate", Row, OrderSpeedFlowRate);
            }
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function OrderSpeedFlowRate_changehandler(e) {
    var Row = GetEventRow(e);
    var eSrc = websys_getSrcElement(e);
    var OrderSeqNo = GetColumnData("OrderSeqNo", Row);
    var OrderMasterSeqNo = GetColumnData("OrderMasterSeqNo", Row);
    if (OrderMasterSeqNo != "") OrderSeqNo = OrderMasterSeqNo;
    var OrderSpeedFlowRate = GetColumnData("OrderSpeedFlowRate", Row);
    ChangeLinkOrderSpeedFlowRate(OrderSeqNo, OrderSpeedFlowRate);
}
//输液流速单位改变控制
function OrderFlowRateUnitchangehandler(e) {
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    //$.messager.alert("警告",this.value);
    var OrderSeqNo = GetCellData(rowid, "id");
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    if (OrderMasterSeqNo != "") OrderSeqNo = OrderMasterSeqNo;
    var OrderFlowRateUnit = GetCellData(rowid, "OrderFlowRateUnit");
    SetCellData(rowid, "OrderFlowRateUnitRowId", this.value);
    //SetCellData(rowid,"OrderSpeedFlowRate","");
    ChangeLinkOrderFlowRateUnit(OrderSeqNo, this.value,OrderFlowRateUnit);
}
function ChangeLinkOrderFlowRateUnit(OrderSeqNo, OrderFlowRateUnit,OrderFlowRateUnitDesc) {
    try {
        var rowids = GetAllRowId();
        for (var i = 0; i < rowids.length; i++) {
            var rowid = rowids[i];
            if (CheckIsItem(rowids[i]) == true) { continue; }

            var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");

            var OrderType = GetCellData(rowid, "OrderType");
            if (OrderType !="R") continue;
            
            var OrderInstrRowid=GetCellData(rowid, "OrderInstrRowid");
            var SpeedRateSeparateInstrFlag=IsSpeedRateSeparateInstr(OrderInstrRowid);

            var OrderSeqNoMasterLink = GetCellData(rowid, "id");
            if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && ((OrderMasterSeqNo == OrderSeqNo) || (OrderSeqNoMasterLink == OrderSeqNo))) {
                var EditStatus = GetEditStatus(rowid);
                var OldOrderFlowRateUnitRowId=GetCellData(rowid, "OrderFlowRateUnitRowId");
                //非自定义流速用法 需要同步主医嘱的流速
                if(!SpeedRateSeparateInstrFlag){                
	                SetCellData(rowid, "OrderFlowRateUnitRowId", OrderFlowRateUnit);
				    if (EditStatus == true) {
				        SetCellData(rowid, "OrderFlowRateUnit", OrderFlowRateUnit);
				    } else {
				        SetCellData(rowid, "OrderFlowRateUnit", OrderFlowRateUnitDesc);
				    }
			    }else if (((GlobalObj.DrippingSpeedInstr).indexOf("^"+OrderInstrRowid+"^")>=0)&&(!OldOrderFlowRateUnitRowId)&&(OrderFlowRateUnit)) {
		        	//行流速单位为空则取医生站设置-用法设置—用法扩展设置输液用法默认流速单位
		        	
		        	var InstrDefSpeedRateUnit=GetInstrDefSpeedRateUnit(OrderInstrRowid)
			        if((typeof InstrDefSpeedRateUnit=="object")&&(InstrDefSpeedRateUnit["id"])){
				       	var DefInstrDefSpeedRateUnitId=InstrDefSpeedRateUnit["id"];
						var DefInstrDefSpeedRateUnitDesc=InstrDefSpeedRateUnit["desc"];
						SetCellData(rowid, "OrderFlowRateUnitRowId", DefInstrDefSpeedRateUnitId);
					    if (EditStatus == true) {
					        SetCellData(rowid, "OrderFlowRateUnit", DefInstrDefSpeedRateUnitId);
					    } else {
					        SetCellData(rowid, "OrderFlowRateUnit", DefInstrDefSpeedRateUnitDesc);
					    }
				    }
		   		}
            }
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function ChangeLinkOrderOrderSpeedFlowRate(OrderSeqNo, OrderSpeedFlowRate) {
    try {
        var rowids = GetAllRowId();
        for (var i = 1; i < rowids.length; i++) {
            var rowid = rowids[i];
            if (CheckIsItem(rowids[i]) == true) { continue; }

            var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");

            var OrderSeqNoMasterLink = GetCellData(rowid, "id");
            if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && ((OrderMasterSeqNo == OrderSeqNo) || (OrderSeqNoMasterLink == OrderSeqNo))) {
                SetCellData(rowid, "OrderSpeedFlowRate", OrderSpeedFlowRate)
            }
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function OrderItemLookupSelect(text,rowid) {
	if (typeof rowid == "undefined") {
    	rowid = "";
    }
    if (rowid==""){
	    if (this.id.indexOf("_") > 0) {
	        rowid = this.id.split("_")[0];
	    }
    }
	new Promise(function(resolve,rejected){
		var Split_Value = text.split("^");
		var iordertype = Split_Value[3];
		if (iordertype == "ARCIM") {
			CheckDiagnose(Split_Value[1],resolve);
		}else{
			resolve(true);
		}
	}).then(function(rtn){
		return new Promise(function(resolve,rejected){
			if (!rtn) {
				var itemobj = document.getElementById(rowid + "_OrderName");
		        if (itemobj) {
		            itemobj.value = "";
		            SetFocusCell(rowid, "OrderName")
		            return false;
		        }
			}else{
				resolve();
			}
		});
	    
	}).then(function(){
		return new Promise(function(resolve,rejected){
			var Split_Value = text.split("^");
			var icode = Split_Value[1];
			var iordertype = Split_Value[3];
			if (iordertype == "ARCIM") {
				GetItemDefaultRowId(icode,resolve);
			}else{
				resolve();
			}
		});
	}).then(function(ItemDefaultRowId){
		var Split_Value = text.split("^");
	    var idesc = Split_Value[0];
	    var icode = Split_Value[1];
	    var ifreq = Split_Value[2];
	    var iordertype = Split_Value[3];
	    var ialias = Split_Value[4];
	    var isubcatcode = Split_Value[5];
	    var iorderCatID = Split_Value[6];
	    var iSetID = Split_Value[7];
	    var mes = Split_Value[8];
	    var irangefrom = Split_Value[9];
	    var irangeto = Split_Value[10]
	    var iuom = Split_Value[11];
	    var idur = Split_Value[12];
	    var igeneric = Split_Value[13];
	    var match = "notfound";
	    var SetRef = 1;
	    var OSItemIDs = Split_Value[15];
	    var iorderSubCatID = Split_Value[16];
	    var StockQty = Split_Value[20];
	    var PackedQty = Split_Value[21];
		var OrderMasterSeqNo=GetCellData(rowid, "OrderMasterSeqNo");
		if (OrderMasterSeqNo!=""){
			SetMasterSeqNo("", rowid, "C");
		}else{
			SetMasterSeqNo(rowid, rowid, "C");
		}
		CheckMasterOrdStyle();
	    if (iordertype == "ARCIM") iSetID = "";
	    var Itemids = "";
	    if (OSItemIDs == "") {
	        Itemids = icode;
	    } else {
	        Itemids = icode + String.fromCharCode(12) + OSItemIDs;
	    }
	    var OSItemIDArr = OSItemIDs.split(String.fromCharCode(12))
	    for (var i = 0; i < OSItemIDArr.length; i++) {
	        if (OSItemIDArr[i].split(String.fromCharCode(14)).length > 1) OSItemIDArr[i] = OSItemIDArr[i].split(String.fromCharCode(14))[1];
	    }
	    OSItemIDs = OSItemIDArr.join(String.fromCharCode(12));

	    if (iordertype == "ARCIM") {
	        var ret = "";
	        if ($.isNumeric(rowid) == true) {
				SetCellChecked(rowid, "OrderSkinTest", false);
	        }
			var OrdParamsArr=new Array();
			OrdParamsArr[OrdParamsArr.length]={
				OrderARCIMRowid:icode,
				ItemDefaultRowId:ItemDefaultRowId
			};
			PageLogicObj.EntrySelRowFlag=1;
			new Promise(function(resolve,rejected){
				AddItemToList(rowid,OrdParamsArr,"data","",resolve);
			}).then(function(RtnObj){
				var rowid=RtnObj.rowid;
				var returnValue=RtnObj.returnValue;
		        if (returnValue == false) {
		            //清空当前行
		            //ClearRow(rowid);
		            if (PageLogicObj.NotEnoughStockFlag==1){
		                SetCellData(rowid, "OrderName",PageLogicObj.SearchName);
		                SetFocusCell(rowid, "OrderName");
		                $("#"+rowid+"_OrderName").lookup('showPanel');
		                return false;
		            }else{
			            ClearRow(rowid);
			            SetFocusCell(rowid, "OrderName");
			            return true;
			        }
		        }
		        var OrderType = GetCellData(rowid, "OrderType");
		        var OrderPHPrescType = GetCellData(rowid, "OrderPHPrescType");
		        var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
		        DHCDocUseCount(icode, "User.ARCItmMast");
				CellFocusJumpAfterOrderName(rowid, OrderType);
				//PageLogicObj.EntrySelRowFlag=0;
		        //添加数据成功后 设置Footer数据
				SetScreenSum();
			    return true;
			})
	    } else {
	        //医嘱套
	        if ($.isNumeric(rowid) == false) { return; }
	        OSItemListOpen(icode, idesc, "YES", "", "");
	        DHCDocUseCount(icode, "User.ARCOrdSets");
	        //添加数据成功后 设置Footer数据
			SetScreenSum();
		    return true;
	    }
	    //1、取数据 先决定编辑器类型
	    //2、改变编辑器类型
	    //3、启动编辑
	    //EditRowCommon(rowid);
	    //4、放入数据
	    //document.getElementById(rowid+"_OrderName").value=idesc;  
	    //5、还原编辑器
	    //Change_Row_Editor2();
	})
}
//打开医嘱套界面
function OSItemListOpen(ARCOSRowid, OSdesc, del, itemtext, OrdRowIdString,callBackFun) {
    var Patient = GlobalObj.PatientID
    var nowOrderPrior = $("#HiddenOrderPrior").val();
    if(nowOrderPrior=="LongOrderPrior"){
        nowOrderPrior="1"   
    }else{
        nowOrderPrior="0"   
    }
    if (ARCOSRowid != "") {
	    if (GlobalObj.MedNotOpenARCOS=="1"){
		    var CopyData=cspRunServerMethod(GlobalObj.SetARCOSItemDirectMethod,'',ARCOSRowid,session['LOGON.HOSPID'],GlobalObj.EpisodeID);	//AddCopyItemToList
			if(CopyData!=""){
				AddCopyItemToList(CopyData.split('###'),callBackFun);
			}else{
				if(callBackFun) callBackFun();
			}
		}else{
        	websys_showModal({
				iconCls:'icon-w-file-open',
				url:"doc.arcositemlist.hui.csp?EpisodeID=" + GlobalObj.EpisodeID + "&ARCOSRowid=" + ARCOSRowid +"&nowOrderPrior=" +nowOrderPrior,
				title:"<font color='#FF9933'>"+OSdesc+'</font>'+$g(' 医嘱套录入'),
				width:1160,height:592,
				AddCopyItemToList:function(Copyary){
					AddCopyItemToList(Copyary,callBackFun);
				}
			});
		}
    }
}
//添加医嘱套
function AddCopyItemToList(ParaArr,OSCallBackFun) {
	PageLogicObj.m_selArcimRowIdStr="";
    if (typeof(history.pushState) === 'function') {
        //防止右键刷新后医嘱重复复制
        var Url=window.location.href;
        var NewUrl=rewriteUrl(Url, {copyOeoris:"",copyTo:""});
        history.pushState("", "", NewUrl);
    }
    if (GlobalObj.warning != "") {
        $.messager.alert("警告",GlobalObj.warning);
        return false;
    }
    //删除当前最后一行空白行
    var CruRow = GetPreRowId();
    if (CheckIsClear(CruRow) == true) {
        DeleteRow(CruRow);
    }
    GlobalObj.AuditFlag = 0;
	//ParaArr在这里丢失了数组的成员属性，奇怪
	var OrdArr = new Array();
	/*for (var i = 0,ArrLength = ParaArr.length; i < ArrLength; i++){
		if (!ParaArr.hasOwnProperty(i)) continue;
		OrdArr.push(ParaArr[i]);
	}*/
	//
	for(var key in ParaArr) { 
		OrdArr.push(ParaArr[key]); 
	}
	window.setTimeout(function(){
		AddCopyItemToListSub(OrdArr);
	}, 100);
	function AddCopyItemToListSub(OrdArr){
		SetTimeLog("AddCopyItemToList", "Start");
		var OrdParamsArr=new Array();
		var OrderARCOSRowid="";
		new Promise(function(resolve,rejected){
			(function(callBackFun){
				function loop(i){
					new Promise(function(resolve,rejected){
						var Para1Str=OrdArr[i];
						if (!Para1Str) resolve(false);
						var para1Arr = Para1Str.split("!");
						var ItemOrderType = para1Arr[3];
						CheckDiagnose(para1Arr[0],resolve);
					}).then(function(rtn){
						if (rtn) {
							var Para1Str=OrdArr[i];
							if (Para1Str) {
								var para1Arr = Para1Str.split("!");
								var icode = para1Arr[0];
								var seqno = para1Arr[1];
								var Para = para1Arr[2];
								var ItemOrderType = para1Arr[3];
								var CopyBillTypeRowId = para1Arr[4];
								//update by zf 2012-05-14
								var CopyType = para1Arr[5];
								var CPWStepItemRowId = para1Arr[6];
								if ((typeof CPWStepItemRowId == "undefined") || (CPWStepItemRowId == "undefined")) {
									CPWStepItemRowId="";
								}
								//抗菌药物申请通过的医嘱项保存，不需要再次进行抗菌药审核
								var KSSCopyFlag = para1Arr[7];
								if ((typeof KSSCopyFlag == "undefined")||(KSSCopyFlag == "undefined")){
									KSSCopyFlag="";
								}
								if ((KSSCopyFlag == "KSS")) {
									GlobalObj.AuditFlag = 1;
								}
								var OrderBodyPartLabel="";
								if (Para != "") {
									var OrderBodyPartLabel=mPiece(Para, "^", 17);
									if (typeof OrderBodyPartLabel=="undefined") OrderBodyPartLabel="";
								}
								OrderARCOSRowid = para1Arr[8];
								if ((typeof OrderARCOSRowid == "undefined") || (OrderARCOSRowid == "undefined")) {
									OrderARCOSRowid="";
								}
								//治疗申请信息,治疗申请单ID+String.fromCharCode(3)+接收科室ID+String.fromCharCode(3)+首日次数+String.fromCharCode(3)+周频次选择执行信息+String.fromCharCode(3)+医嘱开始日期
								//+String.fromCharCode(3)+医嘱结束日期+String.fromCharCode(3)+医保标记+String.fromCharCode(3)+实习生？+String.fromCharCode(3)+跨院标识
								var DCAInfoStr = para1Arr[9];
								if ((typeof DCAInfoStr == "undefined") || (DCAInfoStr == "undefined")) {
									DCAInfoStr="";
								}else{
									//var DCAInfoArr=DCAInfoStr.split(String.fromCharCode(1))
								}
								var ITMRowId=mPiece(Para, "^", 13);
								//seqno用于传值计算成组关系，与行上的SeqNo没有实际关系
								OrdParamsArr[OrdParamsArr.length]={
									OrderARCIMRowid:icode,
									ParamS:Para,
									OrderBillTypeRowid:CopyBillTypeRowId,
									OrderCPWStepItemRowId:CPWStepItemRowId,
									CopyType:CopyType,
									CalSeqNo:seqno,
									OrderBodyPartLabel:OrderBodyPartLabel,
									ITMRowId:ITMRowId,
									DCAInfoStr:DCAInfoStr,
									KSSCopyFlag:KSSCopyFlag
								};
							}
						}
						i++;
						if ( i < OrdArr.length ) {
							 loop(i);
						}else{
							var paraObj={
								OrdParamsArr:OrdParamsArr,
								Para:Para,
								OrderARCOSRowid:OrderARCOSRowid,
								CopyType:CopyType
							}
							callBackFun(paraObj);
						}
					})
				}
				loop(0)
			})(resolve);			
		}).then(function(paraObj){
			return new Promise(function(resolve,rejected){
				var OrderARCOSRowid=paraObj.OrderARCOSRowid;
				var OrdParamsArr=paraObj.OrdParamsArr;
				var CopyType=paraObj.CopyType;
				if (OrderARCOSRowid==""){
					var Para=paraObj.Para;
					var OrderARCOSRowid=mPiece(Para, "^", 6);
				}
				var FastEntryMode=0;
				var	FastEntryName="";
				///判断是否属于快速医嘱套
				if (OrderARCOSRowid!=""){
					var ARCOSInfo=cspRunServerMethod(GlobalObj.GetARCOSInfoMethod,OrderARCOSRowid);
					FastEntryName=mPiece(ARCOSInfo,"^",0)
					if (mPiece(ARCOSInfo,"^",1)=="Y"){
						FastEntryMode=1;
					}
				}
				var ExpStr=CopyType+"^"+FastEntryMode+"^"+FastEntryName+"^"+OrderARCOSRowid;
				AddItemToList("",OrdParamsArr,"obj",ExpStr,resolve);
			})
			
		}).then(function(RtnObj){
			var rowid=RtnObj.rowid;
			var returnValue=RtnObj.returnValue;
			if (returnValue==false){
				var rowids = $('#Order_DataGrid').getDataIDs();
				if (rowids.length == 0) Add_Order_row();
			}else{
				var OrderType = GetCellData(rowid, "OrderType");
				if (OrderType == "R") {
					SetFocusCell(rowid, "OrderDoseQty");
				} else {
					if (OrderType == "P") {
						SetFocusCell(rowid, "OrderPrice");
					} else {
						SetFocusCell(rowid, "OrderPackQty");
					}
				}
				SetScreenSum();
			}
		    PageLogicObj.m_AddItemToListMethod = "LookUp";
			SetTimeLog("AddCopyItemToList", "Over");
			if (PageLogicObj.m_selArcimRowIdStr.split("^").length>=2){
				OrdNotesDetailOpen(PageLogicObj.m_selArcimRowIdStr);
			}
			if(typeof OSCallBackFun=='function') OSCallBackFun();
		})
	}
}
function addOEORIByCPW(StepItemIDS) {
    if (StepItemIDS != '') {
        var ret = cspRunServerMethod(GlobalObj.AddMRCPWItemToListMethod, 'AddCopyItemToList', '', StepItemIDS,session['LOGON.HOSPID'],GlobalObj.EpisodeID);
    }
}
function CheckDiagnose(OrderARCIMRowid,callBackFun) {
	var OrdNeedMMDiag=0;
	var ItemCatRowid=tkMakeServerCall("web.DHCDocOrderCommon", "GetOrderSubCat", OrderARCIMRowid);
	if (GlobalObj.OrdNeedMMDiagCat.indexOf("^"+ItemCatRowid+"^") >=0) {
		OrdNeedMMDiag=1;
	}
	new Promise(function(resolve,rejected){
		if ((GlobalObj.OrderLimit==1)||(GlobalObj.PAADMMotherAdmId!="")||(GlobalObj.PAAdmType=="H")||(GlobalObj.CareProvType != "DOCTOR")) {
			resolve(true);
			return;
		}
		
		var NeedDiagnosFlag = 1,NoDiagnosMsg="";
		if (OrdNeedMMDiag == 1){
		    var Ret=tkMakeServerCall("web.DHCDocOrderEntry", "GetMMDiagnoseCount", GlobalObj.mradm);
		    GlobalObj.MRDiagnoseCount = Ret;
		    NoDiagnosMsg="没有西医诊断,请先录入!";
		}else{
			//新门诊病历界面,录入诊断或删除诊断后未刷新医嘱录入界面,导致诊断数据取的错误
	    	var Ret = tkMakeServerCall("web.DHCDocOrderEntry", "GetMRDiagnoseCount", GlobalObj.mradm);
	    	GlobalObj.MRDiagnoseCount = Ret;
	    	NoDiagnosMsg="没有诊断,请先录入!";
		}
    	if ((GlobalObj.MRDiagnoseCount == 0) && (NeedDiagnosFlag == 1)) {
	    	if ((t['NO_DIAGNOSE']) && (t['NO_DIAGNOSE'] != "")) {
		    	var iframeName = window.name
	            if (iframeName == "") {
	                iframeName = window.parent.frames["oeordFrame"]?window.parent.frames["oeordFrame"].name:'';
	            }
	            if (iframeName == "oeordFrame") {
	                resolve(true);
	            }else{
			    	(function(callBackFunExec){
					    new Promise(function(resolve,rejected){
							$.messager.alert("提示",NoDiagnosMsg,"info",function(){
								websys_showModal({
									url:"diagnosentry.v8.csp?PatientID=" + GlobalObj.PatientID + "&EpisodeID=" + GlobalObj.EpisodeID + "&mradm=" + GlobalObj.mradm,
									title:'诊断录入',
									//width:((websys_getTop().screen.width - 100)),height:(websys_getTop().screen.height - 120),
                                    width:"95%",height:(websys_getTop().screen.height - 120),
									invokeChartFun:parent.invokeChartFun||parent.parent.invokeChartFun,
									onClose:function(){
										if (OrdNeedMMDiag == 1){
										    var Ret = tkMakeServerCall("web.DHCDocOrderEntry", "GetMMDiagnoseCount", GlobalObj.mradm);
										}else{
									    	var Ret = tkMakeServerCall("web.DHCDocOrderEntry", "GetMRDiagnoseCount", GlobalObj.mradm);
										}
							            GlobalObj.MRDiagnoseCount = Ret;
							            if (Ret == 0) { Ret = false; } else { Ret = true; }
										resolve(Ret);
									}
								})
					    	})
						}).then(function(rtn){
							callBackFunExec(rtn);
						});
				    })(resolve);
	            }
		    }else{
			    resolve(false);  
			}
	    }else{
		    //存在诊断
		    resolve(true);
		}
	}).then(function(rtn){
		callBackFun(rtn);
	})
}
function GetItemDefaultRowId(icode,callBackFun){
	new Promise(function(resolve,rejected){
		var userid = session["LOGON.USERID"];
    	var LogonLocDr=session['LOGON.CTLOCID'];
    	//选择医嘱自定义常用用法
	    var ItemDefaultRowId = "";
	    var OrderPriorRowid = "";
	    if (GlobalObj.OrderPriorContrlConfig==1){
	        var DefaultOrderPrior = GetDefaultOrderPrior("");
	        OrderPriorRowid = DefaultOrderPrior.split('^')[0];
	    }
	    if (GlobalObj.GetUserItemDefaultSingleMethod != "") {
		    var ItemDefaultRowIds = cspRunServerMethod(GlobalObj.GetUserItemDefaultSingleMethod, icode, userid, GlobalObj.PAAdmType,OrderPriorRowid,LogonLocDr);
	        if (ItemDefaultRowIds != "") {
	            var arr = ItemDefaultRowIds.split("^");
	            if (arr.length > 1) {
		            var IsCallBacked=false;
	                websys_showModal({
						iconCls:'icon-w-switch',
						url:"doc.orditemdefault.hui.csp?OrderRowid=" + icode + "&UserID=" + userid + "&LogonLocDr=" + LogonLocDr+"&OrderPriorRowid="+OrderPriorRowid,
						title:$g('常用用法选择'),
						width:1000,height:500,
						CallBackFunc:function(ItemDefaultRowId){
							IsCallBacked=true;
							websys_showModal("close");
							if (typeof ItemDefaultRowId=="undefined"){
								ItemDefaultRowId="";
							}
							resolve(ItemDefaultRowId);
						},
						onClose:function(){
							if (!IsCallBacked) resolve("");
						}
					})
	            } else {
	                ItemDefaultRowId = arr[0];
	                resolve(ItemDefaultRowId);
	            }
	        }else{
		        resolve(ItemDefaultRowId);
		    }
		}else{
			resolve(ItemDefaultRowId);
		}
	}).then(function(ItemDefaultRowId){
		callBackFun(ItemDefaultRowId);
	})
}
function CheckAllowOnlyOnceRepeat(icode){
	var rowids = $('#Order_DataGrid').getDataIDs();
	for (var i = 0; i < rowids.length; i++) {
		var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
        var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
        if ((OrderItemRowid!="")||(OrderARCIMRowid=="")) continue;
        if (OrderARCIMRowid==icode) {
	        return true;
	    }
	}
	return false;
}
function CheckDateDupOrderItem(CurrentRow, ARCIMRowid, StartDate) {
    if ((GlobalObj.PAAdmType == "I") || (GlobalObj.PAAdmType == "E")) { return false }
    var rowids = $('#Order_DataGrid').getDataIDs();
    for (var i = 0; i < rowids.length; i++) {

        var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
        var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
        var OrderStartDateStr = GetCellData(rowids[i], "OrderStartDate");
        var OrderStartDate = OrderStartDateStr.split(" ")[0];
        if ((OrderARCIMRowid != "") && (OrderItemRowid == "")) {
            if ((ARCIMRowid == OrderARCIMRowid) && (rowids[i] != CurrentRow) && (OrderStartDate == StartDate)) return true;
        }
    }
    return false;
}
//-------------2014-05-13 需要修改的检查函数 start-----------------------//
function SelectPrescriptItem(ArcimRowid, BillTypeRowid) {
    if (GlobalObj.PAAdmType == "I") { return true }
    var SubCatID = cspRunServerMethod(GlobalObj.GetARCItemSubCatID, '', '', ArcimRowid)
    if (SubCatID != "") SubCatID = "^" + SubCatID + "^";
    var PrescriptTypes = GlobalObj.PrescriptTypes;
    var PrescriptTypeArr = PrescriptTypes.split("||");
    var BillTypeObj = {};
    for (var i = 0; i < PrescriptTypeArr.length; i++) {
        var BillTypeID2 = PrescriptTypeArr[i].split("!")[4];
        var MainSubID = PrescriptTypeArr[i].split("!")[3];
        if (MainSubID != "") { BillTypeObj[BillTypeID2] = "^" + MainSubID + "^"; } else { BillTypeObj[BillTypeID2] = "" }
    }
    var BillTypeID = "";
    for (var key in BillTypeObj) {
        //提供给选择费别的判断  为空的可以开所有
        if (key == BillTypeRowid) {
            if ((BillTypeObj[key].indexOf(SubCatID) != -1) || (BillTypeObj[key] == "")) {
                BillTypeID = key;
                break;
            }
        }
    }
    return BillTypeID;
}
//-------------2014-05-13 需要修改的检查函数 end-----------------------//

function GetConFacByUom(OrderPackQty,ParamObj,OrderRecDepRowid){
    var SpecOrderPackUOMRowid=ParamObj.SpecOrderPackUOMRowid;
    if (SpecOrderPackUOMRowid==undefined) { SpecOrderPackUOMRowid="" }
    var BillUOMStr = cspRunServerMethod(GlobalObj.GetBillUOMStrMethod, ParamObj.OrderARCIMRowid, OrderRecDepRowid, "OrderEntry");
    var DefaultOrderPackUOM = "";
    var FirstOrderPackUOM="";
    var ArrData = BillUOMStr.split(String.fromCharCode(2));
    for (var i = 0; i < ArrData.length; i++) {
        var ArrData1 = ArrData[i].split(String.fromCharCode(1));
        if (SpecOrderPackUOMRowid!=""){
           if (ArrData1[0]==SpecOrderPackUOMRowid){
             var DefaultOrderPackUOM = ArrData1[0];
           }
        }else{
           if (ArrData1[2] == "Y"){
             var DefaultOrderPackUOM = ArrData1[0];
           }
        }
        if (i==0) FirstOrderPackUOM=ArrData1[0];
    }
    if (DefaultOrderPackUOM=="") DefaultOrderPackUOM=FirstOrderPackUOM
    if (DefaultOrderPackUOM != "") {
        if (ParamObj.OrderPackUOMRowid!=DefaultOrderPackUOM){
            OrderPackQty=tkMakeServerCall("web.DHCDocOrderEntry", "GetConFac",ParamObj.OrderARCIMRowid,ParamObj.InciRowid,DefaultOrderPackUOM)
        }
    }
    return OrderPackQty;
}
/// V8.5.3 tanjishan
/// --静配规则全部以修改打包表接受科室实现，该方法调用位置已弃用，方法本身可暂不删除，防止出现本地化修改
/// --web.DHCOEOrdItemView-GetDosingDateTime已同步屏蔽
function SetDosingDateTime(rowid, ParamObj, OrderRecDepRowid) {
    if ((GlobalObj.IPDosingRecLoc == "") || (OrderRecDepRowid == "")) return;
    var OrderPriorRowid = ParamObj.OrderPriorRowid;
    var OrderType = ParamObj.OrderType;
    var OrderItemCatRowid = ParamObj.OrderItemCatRowid;
    SetSttDateEditble();
    if ((OrderPriorRowid == GlobalObj.LongOrderPriorRowid || (OrderPriorRowid == GlobalObj.OMSOrderPriorRowid)) && (OrderType == "R")) {
        var OrderRecDepRowid=GetCellData(rowid, "OrderRecDepRowid");
		if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + OrderRecDepRowid + "^") < 0){
			SetOrderFirstDayTimes(rowid);
			return;
		}
        var ret = CheckDosingRecLoc(OrderRecDepRowid);
        if (ret) {
	        var OrderARCIMRowid = GetCellData(rowid,"OrderARCIMRowid");
            var ret = cspRunServerMethod(GlobalObj.GetDosingDateTimeMethod, OrderARCIMRowid,OrderRecDepRowid,OrderPriorRowid,session['LOGON.HOSPID']);
			if (ret!="") {
				var retArr = ret.split("^");
				var OrderStartDate = retArr[0];
				var OrderStartTime = retArr[1];
				var OrderStartDateStr = OrderStartDate + " " + OrderStartTime;
				SetCellData(rowid, "OrderStartDate", OrderStartDateStr);
				var ModifyFlag= retArr[2];
				if(ModifyFlag=='N'){
					ChangeRowStyle(rowid, {OrderStartDate:false});
				}
			}
        } else {
            //重置医嘱开始时间
            var CurrDateTime = cspRunServerMethod(GlobalObj.GetCurrentDateTimeMethod, PageLogicObj.defaultDataCache, "1");
            var CurrDateTimeArr = CurrDateTime.split("^");
            var OrderStartDateStr = CurrDateTimeArr[0] + " " + CurrDateTimeArr[1]
            SetCellData(rowid, "OrderStartDate", OrderStartDateStr);
        }
    }
    SetOrderFirstDayTimes(rowid);
   	function SetSttDateEditble(){
	   	var OrderMasterSeqNo=GetCellData(rowid, "OrderMasterSeqNo");
	   	if(OrderMasterSeqNo!=""){
		   	ChangeRowStyle(rowid, { OrderStartDate: false});
			return;
		}
		var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
	    var SttIsCanCrossDay = mPiece(OrderHiddenPara, String.fromCharCode(1), 8);
	    if (GlobalObj.CurrentDischargeStatus == "B") {
		    ChangeRowStyle(rowid, {OrderStartDate:true,OrderDate:true});
		}else{
		    if (!CheckDateTimeModifyFlag(GlobalObj.ModifySttDateTimeAuthority,SttIsCanCrossDay)){
			    ChangeRowStyle(rowid, { OrderStartDate: false});
			}else{
				ChangeRowStyle(rowid, { OrderStartDate: true});
			}
		}
	}
}
//住院急诊流管押金控制
function CheckDeposit(amount, arcim,arcimDesc,callBackFun) {
	if ((+amount==0)||(GlobalObj.VisitStatus=="P")||(GlobalObj.NotDoCheckDeposit==1)||(GlobalObj.SupplementMode==1)){
		if(callBackFun) callBackFun(true);
		return true;
	}
    if ((GlobalObj.PAAdmType != "I") && (GlobalObj.GetStayStatusFlag != 1) && (GlobalObj.GetStayStatusFlag != 2)) { 
		if(callBackFun) callBackFun(true);
		return true 
	}
    if (GlobalObj.CheckIPDepositMethod != "") {
        var retDetail = cspRunServerMethod(GlobalObj.CheckIPDepositMethod, GlobalObj.EpisodeID, amount, "OE");
        if (retDetail != 0) {
            var retArray = retDetail.split("^");
            if (retArray[4] == 'C') {
				var AlertAmount=retArray[0];
				if (AlertAmount<0) {
					AlertAmount="-"+FormateNumber(AlertAmount.split("-")[1]);
				}else{
					AlertAmount=FormateNumber(AlertAmount);
				}
				var tipMsg=$g(t['ExceedDeposit']);
				if(arcimDesc) tipMsg=$g('无法开具【')+arcimDesc+$g('】,开后押金剩余:')+ AlertAmount;
                if (retArray[5] == 'N') {
                    $.messager.alert("欠费控制",tipMsg,"info",function(){
						if(callBackFun) callBackFun(false);
					});
                    return false;
                } else {
                    if (arcim != "") {
                        var retDetail = cspRunServerMethod(GlobalObj.CheckDepositOrderMethod, GlobalObj.EpisodeID,retArray[2], arcim);
                        if (retDetail == 0) {
                            $.messager.alert("欠费控制",tipMsg,"info",function(){
								if(callBackFun) callBackFun(false);
							});
                            return false;
                        }
                    }
                }
            }
        }
    }
	if(callBackFun) callBackFun(true);
    return true;
}
function CheckPrescriptSum(AddSum, Arcim,ArcimDesc,callBackFun) {
    var ScreenBillSum = GetScreenBillSum();
    var amount = parseFloat(ScreenBillSum) + parseFloat(AddSum);
    var ret = CheckDeposit(amount, Arcim,ArcimDesc,callBackFun);
    return ret;
}
/*************************************
 *说明：2014-08-15
 *设置添加行数据时 单元格是否可编辑
 *DefaultStyleConfigObj中的属性必须和表格列index相同
 *返回StyleConfigObj
 *如果考虑非强制模式的话，应该是需要在prior的change事件中重算style-tanjishan
 *************************************/
function GetStyleConfigObj(ParamObj) {
    var DefaultStyleConfigObj = {
        OrderDur: true,
        OrderFreq: true,
        OrderPackQty: true,
        OrderPackUOM: true,
        OrderDoseQty: true,
        OrderDoseUOM: true,
        OrderInstr: true,
        OrderPrice: false,
        OrderAction: true,
        OrderMasterSeqNo: false,
        OrderLabSpec: true,
        OrderNotifyClinician: true,
        OrderInsurCat: true,
        OrderSpeedFlowRate: true,
        OrderFlowRateUnit: true,
        OrderNeedPIVAFlag: true,
        AntUseReason: true,
        OrderLabEpisodeNo: false,
        Urgent: false,
        OrderPrior: true,
        IsHourItem: ParamObj.IsHourItem,
        OrderSkinTest: true,
        OrderFirstDayTimes: false,
        OrderLocalInfusionQty:true,
        OrderVirtualtLong:false
    }
    var rowid = ParamObj.rowid;
    var icode = ParamObj.OrderARCIMRowid;
    var OrderType = ParamObj.OrderType;
    var OrderPHPrescType = ParamObj.OrderPHPrescType;
    var OrderPriorRowid = ParamObj.OrderPriorRowid;
    var OrderPriorRemarks = ParamObj.OrderPriorRemarksRowId;
    var OrderFreqRowid = ParamObj.OrderFreqRowid;
	var OrderItemCatRowid=ParamObj.OrderItemCatRowid;
	var OrderRecDepRowid=ParamObj.OrderRecDepRowid;
	var OrderCureItemFlag=ParamObj.OrderCureItemFlag;
	var IsNotChangeFirstDayTimeFlag=ParamObj.IsNotChangeFirstDayTimeFlag;
    //加急控制      20141127
    var EmergencyFlag = ParamObj.EmergencyFlag;
    if ((EmergencyFlag == "Y")&&(OrderPriorRowid ==GlobalObj.ShortOrderPriorRowid)) {
        DefaultStyleConfigObj.Urgent = true;
    }
    //********** end
    var OrderHiddenPara=ParamObj.OrderHiddenPara;
    var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
	var IncItmHighValueFlag = mPiece(OrderHiddenPara, String.fromCharCode(1), 9);
	var DCARowIDStr = mPiece(OrderHiddenPara, String.fromCharCode(1), 20);
    var StyleConfigObj = {};
    //$.extend(StyleConfigObj,DefaultStyleConfigObj);
    var StyleConfigObj = DefaultStyleConfigObj;
    StyleConfigObj.OrderDur = false;
    StyleConfigObj.OrderFreq = false;
    //不能关联的医嘱子类
    if (("^" + GlobalObj.NotLinkItemCat + "^").indexOf("^" + ParamObj.OrderItemCatRowid + "^") == -1) {
        StyleConfigObj.OrderMasterSeqNo = true;
    } 
    //仅可开临时医嘱的限制
    if (GlobalObj.UserEMVirtualtLong=="1"){
	    StyleConfigObj.OrderVirtualtLong = true;
		if (GlobalObj.NORMLimitInfo!=""){
			var NORMLimitItemCatStr=mPiece(GlobalObj.NORMLimitInfo, String.fromCharCode(1), 0);
			var NORMLimitArcItemStr=mPiece(GlobalObj.NORMLimitInfo, String.fromCharCode(1), 1);
			
			if ((NORMLimitItemCatStr!="")&&(("^"+NORMLimitItemCatStr+"^").indexOf("^"+OrderItemCatRowid+"^")>=0)){
				StyleConfigObj.OrderVirtualtLong = false;
			}
			if ((NORMLimitArcItemStr!="")&&(("^"+NORMLimitArcItemStr+"^").indexOf("^"+icode+"^")>=0)){
				StyleConfigObj.OrderVirtualtLong = false;
			}
		}   
	}
    if (OrderType != "R") {
        StyleConfigObj.OrderDoseUOM = false;
        /*
        非药品长期医嘱，如果没有单次剂量单位允许填写单次剂量
        非药品长期医嘱，无论有无频次，都能录入单次剂量
        ---tanjishan 20191217
        非药品长期医嘱,如果关联药品,或者本身就是可以录入频次的子类,允许录入单次剂量
        非药品临时医嘱,统一按照数量录入
        */
        if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid){
            
        }else{
           //if (ParamObj.idoseqtystr == "") {
            
            //不在此处赋空,治疗医嘱也会有对单次是否可填的判断,放到治疗医嘱判断之后
			//StyleConfigObj.OrderDoseQty = false;
            //ParamObj.OrderDoseQty="";
           //}
        }
        /*if (ParamObj.idoseqtystr == "") {
            StyleConfigObj.OrderDoseQty = false;
        }*/
        if (("^" + GlobalObj.SelectInstrNotDrugCat + "^").indexOf("^" + ParamObj.OrderItemCatRowid + "^") == -1) {
            StyleConfigObj.OrderInstr = false;
        }
        //StyleConfigObj.OrderInstr=false;
        StyleConfigObj.OrderDur = false;
        StyleConfigObj.OrderSkinTest = false;
        StyleConfigObj.OrderAction = false;
        //StyleConfigObj.OrderInsurCat = false;
        StyleConfigObj.OrderSpeedFlowRate = false;
        StyleConfigObj.OrderFlowRateUnit = false;
        StyleConfigObj.OrderNeedPIVAFlag = false;
        StyleConfigObj.AntUseReason = false;
        StyleConfigObj.OrderPackQty = false;
        StyleConfigObj.OrderPackUOM = false;
        StyleConfigObj.OrderLocalInfusionQty = false;
        if (OrderType == "L") {
            StyleConfigObj.OrderLabEpisodeNo = true;
        } else {
            StyleConfigObj.OrderLabEpisodeNo = false;
        }
        //控制 非药品频次
        //在MedTrak的医生站配置中的【子类控制】->【录入频次非药品子类】中设定的医嘱子类

        if (OrderPHPrescType == "4") {
	        if (GlobalObj.PAAdmType!="I"){
		        StyleConfigObj.OrderDur = true;
		    }
            /*if ((OrderPriorRowid != GlobalObj.LongOrderPriorRowid) && (OrderPriorRowid != GlobalObj.OMSOrderPriorRowid)) {
                StyleConfigObj.OrderDur = true;
            }*/
            StyleConfigObj.OrderFreq = true;
            StyleConfigObj.OrderFirstDayTimes=true;
        }
        //非药品长期医嘱，有频次不能录入数量，无频次可以录入数量
        //非药品长期医嘱无频次不能录入单次剂量
        if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid){
            if ((StyleConfigObj.OrderFreq==false)&&(ParamObj.OrderFreqRowid=="")){
                StyleConfigObj.OrderPackQty = true;
				//CheckCureItemConfig去处理OrderDoseQty的值
                //StyleConfigObj.OrderDoseQty = false;
            }else{
	            StyleConfigObj.OrderFirstDayTimes=true;
                //StyleConfigObj.OrderDoseQty = true;
                ParamObj["OrderPackQty"]="";
            }
        }

    } else {
		StyleConfigObj.OrderFirstDayTimes=true;
        //药品 频次
        StyleConfigObj.OrderFreq = true;
        //StyleConfigObj.OrderMasterSeqNo = true;
        //住院的草药还需要录入疗程,开即刻医嘱
        if (GlobalObj.PAAdmType != "I") {
            StyleConfigObj.OrderDur = true;
        } else {
            if (OrderPHPrescType == "3") {
                StyleConfigObj.OrderDur = true;
            } else {
                if ((((OrderPriorRowid == GlobalObj.LongOrderPriorRowid) || (OrderPriorRowid == GlobalObj.OMSOrderPriorRowid)) || ((OrderPriorRowid == GlobalObj.ShortOrderPriorRowid) && (GlobalObj.PAAdmType == "I")))) {

                    StyleConfigObj.OrderDur = false;
                }
                //出院带药
                if (OrderPriorRowid == GlobalObj.OutOrderPriorRowid) {
                    StyleConfigObj.OrderDur = true;
                }
            }
        }
        if ((NeedSkinTestINCI=="Y")||(GlobalObj.DisableOrdSkinChange=="1")) {
            StyleConfigObj.OrderSkinTest=false;
            StyleConfigObj.OrderAction=false;
        }
        
        if (ParamObj.OrderActionRowid!=""){
	        StyleConfigObj.OrderSkinTest=false;
	        //StyleConfigObj.OrderAction=false;
	    }
	    //皮试用法，皮试备注和标志不可编辑
	    if (GlobalObj.SkinTestInstr != "") {
		    var InstrRowId=ParamObj.OrderInstrRowid;
	        var Instr = "^" + InstrRowId + "^";
	        if (GlobalObj.SkinTestInstr.indexOf(Instr) != "-1") {
		        StyleConfigObj.OrderAction=false;
		        //有可能是关联的溶媒，只需要控制需皮试药品的状态
		        if (NeedSkinTestINCI=="Y"){
					StyleConfigObj.OrderSkinTest=false;
				}
				if ((GlobalObj.DisableOrdSkinChange=="1")){
		        	StyleConfigObj.OrderInstr=false;
		        }
		    }
		}
		var SameFreqDifferentDosesFlag=ParamObj.OrderHiddenPara.split(String.fromCharCode(1))[19];
		if ((SameFreqDifferentDosesFlag=="Y")&&(ParamObj.OrderFreqTimeDoseStr!="")){
			//StyleConfigObj.OrderDoseQty=false;
			StyleConfigObj.OrderDoseQty="readonly";
		}
		if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid){
			StyleConfigObj.OrderPackQty = false;
		}
    }
    //护士补录医嘱进行关联设置,频次不可编辑
    if ((VerifiedOrderObj) && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "undefined") && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "")) { //&& (VerifiedOrderObj.LinkedMasterOrderFreRowId != "undefined") && (VerifiedOrderObj.LinkedMasterOrderFreRowId != "")
        StyleConfigObj.OrderPrior = false;
        StyleConfigObj.OrderFreq = false;
        StyleConfigObj.OrderDur = false;
        StyleConfigObj.OrderInstr = false;
        //若护士补录临时医嘱到长期医嘱上，且补录的医嘱频次为空,则频次可编辑 为什么要编辑?
        if ((OrderFreqRowid=="")&&(OrderPHPrescType=="4")&&(VerifiedOrderObj.LinkedMasterOrderPriorRowid==GlobalObj.LongOrderPriorRowid)&&(OrderPriorRowid==GlobalObj.ShortOrderPriorRowid)){
	        StyleConfigObj.OrderFreq = true;
	    }
	    //若主医嘱频次分发次数大于1，且主子医嘱均为长期医嘱，且子医嘱属于"录入频次疗程的非药品子类"，则可编辑
	    //使用场景示例:雾化吸入一天两天，但只收一次材料费
	    if ((VerifiedOrderObj.LinkedMasterOrderFreFactor>1)&&(VerifiedOrderObj.LinkedMasterOrderPriorRowid==GlobalObj.LongOrderPriorRowid)&&(OrderPriorRowid==GlobalObj.LongOrderPriorRowid)) {
		    StyleConfigObj.OrderFreq = true;
		}
		if ((OrderPriorRowid != GlobalObj.LongOrderPriorRowid)&&(OrderType!="R")) {
	        StyleConfigObj.OrderPackQty = true;
	    }
	    //非药品长期医嘱无频次可以录入数量
	    if ((OrderPriorRowid == GlobalObj.LongOrderPriorRowid)&&(OrderType!="R")&&(ParamObj.OrderFreqRowid=="")){
		    StyleConfigObj.OrderPackQty = true;
            StyleConfigObj.OrderDoseQty = false;
		}
    }else{
	    //数量控制
		var ContrlOrderPackQtArg={
			OrderPriorRowid:OrderPriorRowid,
			OrderPriorRemarks:OrderPriorRemarks,
			OrderARCIMRowid:icode,
			OrderFreqRowid:OrderFreqRowid,
			OrderRecDepRowid:ParamObj.OrderRecDepRowid,
			OrderMasterARCIMRowid:ParamObj.OrderMasterARCIMRowid,
			OrderVirtualtLong:(typeof ParamObj.OrderVirtualtLong!="undefined")?ParamObj.OrderVirtualtLong:"N"
		}
	    var OrderPackQtyObj = ContrlOrderPackQty(rowid, ContrlOrderPackQtArg);
	    if (ParamObj.OrderNeedPIVAFlag == "Y") {
	        OrderPackQtyObj = { OrderPackQty: false, OrderPackUOM: false };
	    }
	    $.extend(StyleConfigObj, OrderPackQtyObj);
    }
    //自定价医嘱  价格可以编辑
    if (OrderType == "P") {
        StyleConfigObj.OrderPrice = true;
    }
    if (ParamObj.IsHourItem == "1") {
	    if (GlobalObj.AllowHourOrdUsePrn ==1) {
		    StyleConfigObj.OrderFreq = true;
		    if ((ParamObj["OrderFreqRowid"])&&(ParamObj["OrderFreqRowid"]!=GlobalObj.PRNFreqRowid)){
			    //去掉默认值
	    		ParamObj["OrderFreq"] = "";
	    		ParamObj["OrderFreqRowid"] = "";
	    		ParamObj["OrderFreqInterval"] = "";
	    		ParamObj["OrderFreqFactor"] = 1;
	    		ParamObj["OrderFreqDispTimeStr"] = "";
			}
		}else{
			StyleConfigObj.OrderFreq = false;
			ParamObj["OrderFreq"] = "";
			ParamObj["OrderFreqRowid"] = "";
			ParamObj["OrderFreqInterval"] = "";
	    	ParamObj["OrderFreqFactor"] = 1;
	    	ParamObj["OrderFreqDispTimeStr"] = "";
		}			
        StyleConfigObj.OrderDur = false;
        StyleConfigObj.OrderInstr = false;
        //去掉默认值
        ParamObj["OrderDur"] = "";
        ParamObj["OrderInstr"] = "";
        if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid) {
	        StyleConfigObj.OrderPackQty = false;
	    }
    }
    var OrderFirstDayTimesEditable=ParamObj.OrderHiddenPara.split(String.fromCharCode(1))[29];
    if(OrderFirstDayTimesEditable=='N') StyleConfigObj.OrderFirstDayTimes=false;
    StyleConfigObj.OrderFirstDayTimesCode=StyleConfigObj.OrderFirstDayTimes;
    
    var CureItemConfigArg={
		OrderPriorRowid:OrderPriorRowid,
		OrderPriorRemarks:OrderPriorRemarks,
		OrderARCIMRowid:icode,
		OrderFreqRowid:OrderFreqRowid,
		OrderRecDepRowid:ParamObj.OrderRecDepRowid,
		OrderMasterARCIMRowid:ParamObj.OrderMasterARCIMRowid,
		NotChangeCellFlag:"Y",
		NotResetPackQtyFlag:"Y",
		OrderPHPrescType:OrderPHPrescType,
		OrderType:OrderType,
		OrderHiddenPara:OrderHiddenPara,
		OrderFreqStyle:StyleConfigObj.OrderFreq,
		OrderCureItemFlag:OrderCureItemFlag,
		IsNotChangeFirstDayTimeFlag:IsNotChangeFirstDayTimeFlag,
		DCARowIDStr:DCARowIDStr
	}
	var CureItemStyleObj=CheckCureItemConfig(rowid,CureItemConfigArg);
	$.extend(StyleConfigObj, CureItemStyleObj);
	if(!StyleConfigObj.OrderDoseQty){
		ParamObj.OrderDoseQty="";	
	}
    //设置单元格不可编辑 可能有值  2014-05-16
    //行样式控制改为只控制是否可编辑  不控制内容
    /*
    for(var key in StyleConfigObj){
        var name=key;
        var value=StyleConfigObj[key];
        if(value==false){
            var val=ParamObj[name];
            if(val != undefined && val != ""){
                //$.messager.alert("警告",name+":"+val);
                StyleConfigObj[name]=value+"^"+val;
            }
        }
    }
    */
    return StyleConfigObj
}
function SetCalculateValue(ParamObj){
    var OrderARCIMRowid = ParamObj.OrderARCIMRowid;
	var OrderDoseQty = ParamObj.OrderDoseQty;
    var OrderDoseUOMRowid = ParamObj.OrderDoseUOMRowid;
    var OrderFreqRowid = ParamObj.OrderFreqRowid;
    var OrderDurRowid = ParamObj.OrderDurRowid;
    var OrderFreqDispTimeStr = ParamObj.OrderFreqDispTimeStr;
    var OrderPackQty = ParamObj.OrderPackQty;
    var OrderPackUOMRowid = ParamObj.OrderPackUOMRowid;
	var OrderPrice=ParamObj.OrderPrice;
	var OrderPriorRowid=ParamObj.OrderPriorRowid;
	var OrderPriorRemarksRowId=ParamObj.OrderPriorRemarksRowId;
	var OrderConFac=ParamObj.OrderConFac;
	var OrderType=ParamObj.OrderType;
	var Qty=ParamObj.Qty;
	var OrderFreqTimeDoseStr=ParamObj.OrderFreqTimeDoseStr;
	///可用天数
	if ((OrderPackQty!="")&&(GlobalObj.CalcDurByArcimMethod!="")){
		var UsableDays = cspRunServerMethod(GlobalObj.CalcDurByArcimMethod, OrderARCIMRowid, OrderFreqRowid, OrderDurRowid, OrderPackQty, OrderDoseQty, OrderDoseUOMRowid, OrderPackUOMRowid,OrderFreqDispTimeStr,OrderFreqTimeDoseStr);
		if ((OrderType != "R") && (UsableDays == "0")) {
			UsableDays = ""
		}
		$.extend(ParamObj, { OrderUsableDays: UsableDays});
	}
	///--计算医嘱金额
	var Sum=0;
    if (GlobalObj.PAAdmType != "I") {
		Sum = parseFloat(OrderPackQty) * parseFloat(OrderPrice);
        Sum = Sum.toFixed(2);
	}else{
		var Sum = 0;
		if ((OrderPriorRemarksRowId!="OM")&&(OrderPriorRemarksRowId!="ZT")){
			Sum = (parseFloat(OrderPrice)/parseFloat(OrderConFac)) * parseFloat(Qty);
		}
		Sum = Sum.toFixed(4);
	}
	$.extend(ParamObj, { Sum: Sum});
}
///校验能否将该条医嘱添加到行上
function CheckItemCongeries(ItemToListDetailObj){
	var CheckBeforeAddObj={
		SuccessFlag:true,				//是否需要继续审核医嘱
		StartDateEnbale:true,
		OrderDateEnbale:true,
		UserOptionObj:new Array()
	}
	new Promise(function(resolve,rejected){
		///ItemToListDetailObj.ItemCongeriesObj 上次前后台交互的返回数组
		///执行回调方法
		if (typeof ItemToListDetailObj.CallBakFunS=="object"){
			///先进行判断是否有需要递归的后处理
			(function(callBackExecFun){
				function loop(i){
					new Promise(function(resolve,rejected){
						var FunCode=ItemToListDetailObj.CallBakFunS[i].CallBakFunCode;
						var FunCodeParams=ItemToListDetailObj.CallBakFunS[i].CallBakFunParams;
						ExeItemCongeriesUserOption(FunCode,FunCodeParams,resolve);
					}).then(function(UserOptionObj){
						if (!$.isEmptyObject(UserOptionObj)){
							CheckBeforeAddObj.UserOptionObj.push(UserOptionObj);
						}						
						i++;
						if ( i < ItemToListDetailObj.CallBakFunS.length ) {
							 loop(i);
						}else{
							callBackExecFun();
						}
					})
				}
				loop(0);
			})(resolve);
		}else{
			resolve();
		}
	}).then(function(){
		return new Promise(function(resolve,rejected){
			if ((CheckBeforeAddObj.UserOptionObj.length>0)||(ItemToListDetailObj.UserOptionCount>0)){
				resolve();
			}else{
				//医嘱的ErrCode不等于0，代表医嘱不能被录入到页面，那其他的提示就没有必须要显示
				if (ItemToListDetailObj.ErrCode=="-100"){
					$.extend(CheckBeforeAddObj, {SuccessFlag:false});
					resolve();
				}else if (ItemToListDetailObj.ErrCode!="0"){
					$.messager.alert("提示",ItemToListDetailObj.ErrMsg,"info",function(){
						$.extend(CheckBeforeAddObj, {SuccessFlag:false});
						resolve();
					});
				}else{
					if (typeof ItemToListDetailObj.CallBakFunS=="object"){
						///再进行判断是否需要继续进行普通的后处理
						(function(callBackExecFun){
							function loop(i){
								new Promise(function(resolve,rejected){
									var FunCode=ItemToListDetailObj.CallBakFunS[i].CallBakFunCode;
									var FunCodeParams=ItemToListDetailObj.CallBakFunS[i].CallBakFunParams;
									ExeItemCongeriesCallBackFun(FunCode,FunCodeParams,resolve);
								}).then(function(ReturnObj){
									if (ReturnObj.SuccessFlag==false){
										CheckBeforeAddObj.SuccessFlag=false;
										callBackExecFun();
									}else{
										var ParamObj=ItemToListDetailObj.OrdListInfo;
										if (ReturnObj.StartDateEnbale==false) {
											$.extend(CheckBeforeAddObj, {StartDateEnbale:false});
										}
										if (ReturnObj.OrderDateEnbale==false) {
											$.extend(CheckBeforeAddObj, {OrderDateEnbale:false});
										}	
										if ($.isEmptyObject(ParamObj) == false){
											if (ReturnObj.OrderCoverMainIns===true){
												$.extend(ParamObj, { OrderCoverMainIns: "Y"});
											}else if (ReturnObj.OrderCoverMainIns===false){
												$.extend(ParamObj, { OrderCoverMainIns: "N"});
											}
											if (ReturnObj.OrderSkinTest===true){
												$.extend(ParamObj, { OrderSkinTest: "Y"});
											}else if (ReturnObj.OrderSkinTest===false){
												$.extend(ParamObj, { OrderSkinTest: "N"});
												var ActionRowid=ParamObj.OrderActionRowid;
												if (ActionRowid!=""){
								                	var ActionCode = GetOrderActionCode(ActionRowid);
								                	if ((ActionCode=="YY")||(ActionCode=="PSJ")){
									                	$.extend(ParamObj, { OrderActionRowid: "",OrderAction:""});
									                }
								                }
											}
											if (ReturnObj.OrderInsurCatRowId!=""){
												$.extend(ParamObj, { OrderInsurCatRowId: ReturnObj.OrderInsurCatRowId});
											}
											//重算数量
											if ($.isEmptyObject(ReturnObj.CalPackQtyObj) == false) {
												$.extend(ParamObj, ReturnObj.CalPackQtyObj);
											}
											$.extend(ItemToListDetailObj.OrdListInfo, ParamObj);
										}
															
										i++;
										if ( i < ItemToListDetailObj.CallBakFunS.length ) {
											 loop(i);
										}else{
											callBackExecFun();
										}
									}
								})
							}
							loop(0);
						})(resolve);
					}else{
						resolve();
					}
				}
			}
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			if ((CheckBeforeAddObj.SuccessFlag==false)||(ItemToListDetailObj.UserOptionCount>0)){
				resolve();
			}else{
				///给纯计算值赋值-可用天数、总价
				SetCalculateValue(ItemToListDetailObj.OrdListInfo);
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						CheckDiagnose(ItemToListDetailObj.OrdListInfo.OrderARCIMRowid,resolve);
					}).then(function(rtn){
						if (!rtn) {
					        $.extend(CheckBeforeAddObj, {SuccessFlag:false});
						}
						callBackFunExec();
					});
				})(resolve);
			}
		})
	}).then(function(){
		ItemToListDetailObj.callBackFun(CheckBeforeAddObj)
	})
	///-------
	//被设计用来反插后台查询方法，用于对后续计算有影响的confirm计算，
	//每次对这个值进行新属性的赋值，都需要在后台计算中加上对应的处理
	//UserOptionOb应至少包含两个固定属性{Type:"",Value:""},用于后台方法识别
	function ExeItemCongeriesUserOption(FunCode ,FunCodeParams, CallBackFun){
		var UserOptionObj={};
		new Promise(function(resolve,rejected){
			var ParamsArr=FunCodeParams.split(";");
			switch(FunCode)
			{
				case "SetOrderFreqDispTimeStr":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							if (ParamsArr[3]=="Week"){
								GetOrderFreqWeekStr(ParamsArr[0],ParamsArr[1],ParamsArr[2],resolve);
							}else if (ParamsArr[3]=="FreeTime"){
								GetOrderFreqFreeTimeStr(ParamsArr[0],ParamsArr[1],ParamsArr[2],resolve);
							}
						}).then(function(OrderFreqWeekInfo){
							var OrderFreqDispTimeStr=mPiece(OrderFreqWeekInfo, "^", 0);
							$.extend(UserOptionObj,{Type:"SetOrderFreqDispTimeStr",Value:OrderFreqDispTimeStr});
							callBackFunExec();
						})
					})(resolve); //此处的resolve指的是FunObj.CallBackFun(UserOptionObj);
					break;
				case "SetMulDoses": //同频次不同剂量,弹出剂量填写界面
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							ShowFreqQty(ParamsArr[0],ParamsArr[1],ParamsArr[2],ParamsArr[3],ParamsArr[4],resolve);
						}).then(function(OrderFreqTimeDoseStr){
							$.extend(UserOptionObj,{Type:"SetMulDoses",Value:OrderFreqTimeDoseStr});
							callBackFunExec();
						})
					})(resolve); //此处的resolve指的是FunObj.CallBackFun(UserOptionObj);
					break;
				case "GuideAllergy": //皮试导航窗口
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							ShowGuideAllergy(ParamsArr[0],ParamsArr[1],resolve);
						}).then(function(GuideAllergyInfo){
							$.extend(UserOptionObj,{Type:"GuideAllergy",Value:GuideAllergyInfo});
							callBackFunExec();
						})
					})(resolve); //此处的resolve指的是FunObj.CallBackFun(UserOptionObj);
					break;
				case "AppendAllergyOrder": //皮试附加医嘱选择窗口
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							ShowAppendAllergyOrder(ParamsArr[0],ParamsArr[1],ParamsArr[2],resolve);
						}).then(function(AppendAllergyOrderInfo){
							$.extend(UserOptionObj,{Type:"AppendAllergyOrder",Value:AppendAllergyOrderInfo});
							callBackFunExec();
						})
					})(resolve); //此处的resolve指的是FunObj.CallBackFun(UserOptionObj);
					break;
				default:
					resolve();
					break;
			}
		}).then(function(){
			CallBackFun(UserOptionObj);
		})
	}
	/*
	tanjishan
	用于additemtolist方法的回调，注意：
	为兼容快速医嘱套录入模式，此方法中不能直接对行数据进行操作，如需对数据操作，请使用返回对象，操作ParamObj
	*/
	function ExeItemCongeriesCallBackFun(FunCode ,FunCodeParams, CallBackFun){
		var ReturnObj={
			SuccessFlag:true,
			StartDateEnbale:true,
			OrderDateEnbale:true,
			//医保适应症涉及修改的内容--
			OrderCoverMainIns:"",	//医保勾选
			OrderInsurCatRowId:"",
			CalPackQtyObj:{}
		}
		var ParamsArr=FunCodeParams.split(";");
		new Promise(function(resolve,rejected){
			switch(FunCode)
			{
				case "Alert":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							$.messager.alert("提示",ParamsArr.join(";"),"info",function(){
								callBackFunExec();
							});
						})
					})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
					break;
				case "Confirm" :
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							$.messager.confirm('确认对话框', FunCodeParams, function(r){
								if (!r) {
									ReturnObj.SuccessFlag=false;
								}
								callBackFunExec();
							});
						})
					})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
					break;
				case "CheckPoison":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							websys_showModal({
								iconCls:'icon-w-stamp',
								url:"dhcdoccheckpoison.csp?PatID=" + GlobalObj.EpisodeID,
								title:$g('本次医嘱存在精一或麻醉类药品,请验证以下信息'), //本次医嘱存在精1或精2或麻醉类药品,请验证以下信息
								width:600,height:240,
								closable:true,
								callBackRetVal:"",
								onBeforeClose:function(){
									/*
									//直接关闭窗口应该是代表取消这次录入操作
									var PatInfoArr=websys_showModal("options").callBackRetVal.split("^");
									var hasAllIdentityFlag=1;
									$.each(PatInfoArr, function(key, val) {
										if (val==""){
											hasAllIdentityFlag=0;
											return false;
										}
									});
									*/
									if (websys_showModal("options").callBackRetVal!="") {
										resolve();
									}else{
										$.messager.alert("提示",FunCodeParams + $g(t['POISON_ALERT']),"info",function(){
											ReturnObj.SuccessFlag=false;
											resolve();
										});
									}
								},
								CallBackFunc:function(retval){
									if (typeof retval=="undefined") retval="";
									websys_showModal("options").callBackRetVal=retval;
									websys_showModal("close");
								}
							})
						}).then(function(){
							callBackFunExec();
						})
					})(resolve);
					break;
				case "SetEnoughStock":
					PageLogicObj.NotEnoughStockFlag=1;
					resolve();
					break;
				case "SetPrompt":
					$("#Prompt").html(FunCodeParams);
					resolve();
					break;
				case "SetStartDateEnbale":
					if (FunCodeParams=="1"){
						ReturnObj.StartDateEnbale=true;
					}else{
						ReturnObj.StartDateEnbale=false;
					}
					resolve();
					break;
				case "SetOrdDateEnbale":
					if (FunCodeParams=="1"){
						ReturnObj.OrderDateEnbale=true;
					}else{
						ReturnObj.OrderDateEnbale=false;
					}
					resolve();
					break;
				case "SetCoverMainIns":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							$.messager.confirm('确认对话框', FunCodeParams, function(r){
								if (!r) {
									ReturnObj.OrderCoverMainIns=false;
								}else{
									ReturnObj.OrderCoverMainIns=true;
								}
								callBackFunExec();
							});
						})
					})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
					break;
				case "SetInsuContrast":
                    (function(callBackFunExec){
                        new Promise(function(resolve,rejected){
                            $.messager.alert('提示信息', FunCodeParams, "info",function(){
                                var SuccessFlag=(GlobalObj.AllowNoInsuContrast==1)?true:false;
                                ReturnObj.SuccessFlag=SuccessFlag;
                                callBackFunExec();
                            });
                        })
                    })(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
                    break;
				case "SetOrderSkinTest":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							$.messager.confirm('确认对话框', FunCodeParams, function(r){
								if (!r) {
									ReturnObj.OrderSkinTest=false;
								}else{
									ReturnObj.OrderSkinTest=true;
								}
								callBackFunExec();
							});
						})
					})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
					break;
				case "SetInsurCat":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							var obj = new Object();
				            obj.name = "Para";
				            obj.value = FunCodeParams;
				            var url =  "../csp/dhcdocindicationschoose.hui.csp";//"websys.default.csp?WEBSYS.TCOMPONENT=DHCDocIndicationsChoose";
				            //原来是将InsuConType放到OrderHiddenPara中第4位?A其实应该赋值到OrderInsurCatRowId隐藏列中
							websys_showModal({
								iconCls:'icon-w-list',
								url:url,
								title:$g('请选择医保适应症'),
								width:800,height:600,
								InsurAlertStr:FunCodeParams,
								closable:false,
								CallBackFunc:function(OrderInsurCatRowId){
									websys_showModal("close");
									if (typeof OrderInsurCatRowId=="undefined"){
										OrderInsurCatRowId="";
										ReturnObj.SuccessFlag=false;
									}
									ReturnObj.OrderInsurCatRowId=OrderInsurCatRowId;
									resolve();
								}
							})
						}).then(function(){
							callBackFunExec();
						})
					})(resolve);
					break;
				case "ReSetPackQty1":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							$.messager.confirm('确认对话框', ParamsArr[0], function(r){
								if (r) {
									var PackQty=ParamsArr[1];
									var OrderSum=ParamsArr[2];
									$.extend(ReturnObj.CalPackQtyObj, { OrderPackQty: PackQty,OrderSum:OrderSum});
								}
								callBackFunExec();
							});
						})
					})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
					break;
				case "ReSetPackQty2":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							$.messager.confirm('确认对话框', ParamsArr[0], function(r){
								if (r) {
									var PackQty=ParamsArr[1];
									var OrderSum=ParamsArr[2];
									var BaseDoseQty=ParamsArr[3];
									var BaseDoseQtySum=ParamsArr[4];
									$.extend(ReturnObj.CalPackQtyObj, { OrderPackQty: PackQty,OrderSum:OrderSum,OrderBaseQty:BaseDoseQty,OrderBaseQtySum:BaseDoseQtySum});
								}
								callBackFunExec();
							});
						})
					})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
					break;
				case "SpecDiagForm":
					///关联转科表单填写界面
					var SerialNum=ParamsArr[0];
					var SpecLocDiagCatCode=ParamsArr[1];
					var SpecLocDiagCatName=ParamsArr[2];
					var ArcimDesc=ParamsArr[3];
					ShowSpecDiagForm(function(SuccessFlag){
						ReturnObj.SuccessFlag=SuccessFlag;
						resolve();
					},SerialNum,SpecLocDiagCatCode,SpecLocDiagCatName,ArcimDesc);
					break;
				case "MulDosesAlert":
					(function(callBackFunExec){
						new Promise(function(resolve,rejected){
							$.messager.alert("提示",ParamsArr.join(";"),"info",function(){
								callBackFunExec();
							});
						})
					})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
					break;
				default:
					resolve();
					break;
			}
		}).then(function(){
			CallBackFun(ReturnObj);
		})
	}
}

function AddItemDataToRow(ParamObj,RowDataObj,AddMethod,callBackFun){
    //3.数据整理
    //保存当前行配置样式
    //获取行样式
	var rowid=ParamObj.rowid;
    var StyleConfigObj = GetStyleConfigObj(ParamObj);
    $.extend(StyleConfigObj, { OrderStartDate: ParamObj.StartDateEnbale,OrderDate:ParamObj.OrderDateEnbale});
    var ActionCode = GetOrderActionCode(RowDataObj.OrderActionRowid);
    if (ActionCode=="TM"){
	    $.extend(StyleConfigObj, { OrderAction: false});
    }
    var StyleConfigStr = JSON.stringify(StyleConfigObj);
    $.extend(ParamObj, { StyleConfigStr: StyleConfigStr });
    ChangeRowStyle(rowid, StyleConfigObj)
	//整理行数据对象	
    RowDataObj = SetRowDataObj(ParamObj.rowid, RowDataObj, ParamObj);
    //4.添加数据
    //AddMethod obj 的统一采用非编辑模式插入
    new Promise(function(resolve,rejected){
	    if (AddMethod == "obj") {
	        //设置科研项目
			rowid = Add_Order_row2(RowDataObj);
	        //SetColumnList(rowid, "OrderPilotPro", GlobalObj.PilotProStr);
			///GetBillUOMStr中已经调用了OrderPackUOMchangeCommon
	        ///OrderPackUOMchangeCommon(rowid);
	        //医嘱套录入 是否启动编辑 用户UI设置
	        //初始化医保分类
			CreaterOrderInsurCat(rowid,"N");
	        if (GlobalObj.isEditCopyItem=='Y') {
	            EditRow(rowid);
	            //设置焦点位置
	            SetFocusCell(rowid, "OrderName");
	            //设置科研项目
	            SetColumnList(rowid, "OrderPilotPro", GlobalObj.PilotProStr);
	            //开医嘱医生
		        SetColumnList(rowid,"OrderDoc",RowDataObj.OrderDocStr);
		        //初始化协议单位
		        SetColumnList(rowid, "OrderPackUOM", RowDataObj.OrderPackUOMStr);
		        //初始化采集部位
		        SetColumnList(rowid, "OrderLabSpecCollectionSite", RowDataObj.OrderLabSpecCollectionSiteStr);
	        } else {
	            if (RowDataObj.OrderInsurCatRowId) {
					var OrderInsurCat=GetOrderInsurCat(rowid,RowDataObj.OrderInsurCatRowId);
					SetCellData(rowid, "OrderInsurCat", OrderInsurCat);
				}
	        }
	        CheckOrderPriorRemarksLegal(rowid);
	        SetCellData(rowid, "OrderPackQty", RowDataObj.OrderPackQty);
			SetCellData(rowid, "OrderInsurCatRowId", RowDataObj.OrderInsurCatRowId);
			//OrderPackQtychangeCommon(rowid);
	        //SetTimeLog("AddItemDataToRow", "按对象的方式赋值行数据之后");
	        //SetTimeLog("AddItemDataToRow", "按对象的方式赋值行数据调用抗菌药物分级管理之前");
	        //*******************抗生素12 此处为更换位置*******************************/
	        //抗菌药物分级管理
	        (function(callBackExecFun){
		        new Promise(function(resolve,rejected){
			        if (ParamObj.OrderType == "R") {
				        ICheckDoctorTypePoison(ParamObj.OrderPoisonRowid, ParamObj.OrderARCIMRowid, rowid, ParamObj.OrderPoisonCode,resolve);
				    }else{
					    resolve(true);
					}
			    }).then(function(Ret){
				    if (Ret == false) {
					    CheckMasterOrdStyle();
					    callBackFun(false);
					    return;
					}else{
						
						if (GlobalObj.isEditCopyItem=='Y') {
					        setTimeout(function(){
						        var OrderType= GetCellData(rowid, "OrderType");
								var OrderPHPrescType = GetCellData(rowid, "OrderPHPrescType");
						        var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
						        if (((OrderPHPrescType == "4")||(OrderType == "R")) && (OrderFreqRowid == "")) {
						            SetFocusCell(rowid, "OrderFreq");
						        }
							})
						}
						callBackExecFun();
					}
				})
		    })(resolve);
	        //**************************************************/
	    } else {
	        //SetTimeLog("AddItemDataToRow", "按单列数据赋值行数据之前");
	        //保存当前行配置样式
	        SetCellData(rowid, "StyleConfigStr", RowDataObj.StyleConfigStr);
			SetCellData(rowid, "OrderMasterSeqNo", RowDataObj.OrderMasterSeqNo);
				        //医嘱类型
			if (RowDataObj.ReSetPriorStr!=""){
				SetColumnList(rowid, "OrderPrior", RowDataObj.ReSetPriorStr);
			}
	        SetCellData(rowid, "OrderPrior", RowDataObj.OrderPriorRowid);
	        SetCellData(rowid, "OrderPriorRowid", RowDataObj.OrderPriorRowid);
	        SetCellData(rowid, "OrderPriorStr", RowDataObj.OrderPriorStr);
	        //剂量单位
	        SetColumnList(rowid, "OrderDoseUOM", RowDataObj.idoseqtystr)
	        SetCellData(rowid, "OrderDoseQty", RowDataObj.OrderDoseQty);
	        SetCellData(rowid, "OrderDoseUOM", RowDataObj.OrderDoseUOMRowid);
	        SetCellData(rowid, "OrderDoseUOMRowid", RowDataObj.OrderDoseUOMRowid);
	        //存储下拉框数据
	        SetCellData(rowid, "idoseqtystr", RowDataObj.idoseqtystr)

	        //特病病种
	        SetColumnList(rowid, "OrderDIACat", RowDataObj.idiagnoscatstr);
	        SetCellData(rowid, "idiagnoscatstr", RowDataObj.idiagnoscatstr)
	            //默认置上前一条的诊断类别  
	        SetCellData(rowid, "OrderDIACat", RowDataObj.OrderDIACat);
	        SetCellData(rowid, "OrderDIACatRowId", RowDataObj.DIACatRowId);

	        //把前面的得到可用接收科室串用来置接收科室List
	        SetColumnList(rowid, "OrderRecDep", RowDataObj.CurrentRecLocStr);
	        //存储下拉框数据
	        SetCellData(rowid, "CurrentRecLocStr", RowDataObj.CurrentRecLocStr)

	        //记录下非出院带药的接收科室和出院带药的接收科室?当切换医嘱类型时需要这两个串
	        SetCellData(rowid, "OrderRecLocStr", RowDataObj.OrderRecLocStr);
	        SetCellData(rowid, "OrderOutPriorRecLocStr", RowDataObj.OrderOutPriorRecLocStr);
	        SetCellData(rowid, "OrderOnePriorRecLocStr", RowDataObj.OrderOnePriorRecLocStr);
			SetCellData(rowid, "OrderHolidayRecLocStr", RowDataObj.OrderHolidayRecLocStr);
	        //设定前面给定的有库存接受科室
	        if (RowDataObj.OrderRecDepRowid) {
	            SetCellData(rowid, "OrderRecDep", RowDataObj.OrderRecDepRowid);
	            SetCellData(rowid, "OrderRecDepRowid", RowDataObj.OrderRecDepRowid);
	        }

	        //设标本选择下拉框 标本
	        SetColumnList(rowid, "OrderLabSpec", RowDataObj.OrderLabSpecStr);
	        SetCellData(rowid, "OrderLabSpec", RowDataObj.OrderLabSpecRowid);
	        SetCellData(rowid, "OrderLabSpecRowid", RowDataObj.OrderLabSpecRowid);
	        SetCellData(rowid, "OrderLabSpecStr", RowDataObj.OrderLabSpecStr);
	        //初始化采集部位
		    SetColumnList(rowid, "OrderLabSpecCollectionSite", RowDataObj.OrderLabSpecCollectionSiteStr);
	        //设置科研项目
	        SetColumnList(rowid, "OrderPilotPro", GlobalObj.PilotProStr);

	        //频次
	        SetCellData(rowid, "OrderFreq", RowDataObj.OrderFreq);
	        //$.messager.alert("警告",OrderFreq);
	        SetCellData(rowid, "OrderFreqRowid", RowDataObj.OrderFreqRowid);
	        SetCellData(rowid, "OrderFreqFactor", RowDataObj.OrderFreqFactor);
	        SetCellData(rowid, "OrderFreqInterval", RowDataObj.OrderFreqInterval);
	        SetCellData(rowid, "OrderFreqDispTimeStr", RowDataObj.OrderFreqDispTimeStr);
	        //用法
	        SetCellData(rowid, "OrderInstr", RowDataObj.OrderInstr);
	        SetCellData(rowid, "OrderInstrRowid", RowDataObj.OrderInstrRowid);
	        SetCellData(rowid, "OrderHiddenPara", RowDataObj.OrderHiddenPara);
	        SetCellData(rowid, "OrderSerialNum", RowDataObj.OrderSerialNum);
	        //*******************抗生素12 此处为更换位置*******************************/
	        //抗菌药物分级管理
	        //抗菌药物分级管理
	        (function(callBackExecFun){
		        new Promise(function(resolve,rejected){
			        if (ParamObj.OrderType == "R") {
				        ICheckDoctorTypePoison(ParamObj.OrderPoisonRowid, ParamObj.OrderARCIMRowid, rowid, ParamObj.OrderPoisonCode,resolve);
				    }else{
					    resolve(true);
					}
			    }).then(function(Ret){
				    if (Ret == false) {
					    callBackFun(false);
					    return;
					}else{
						var OrderPriorRowid=GetCellData(rowid, "OrderPriorRowid");
						if ((GlobalObj.PAAdmType=="I")&&(OrderPriorRowid==GlobalObj.ShortOrderPriorRowid)&&(RowDataObj.OrderDurRowid=="")){
							SetCellData(rowid, "OrderDur", GlobalObj.IPDefaultDur);
					        SetCellData(rowid, "OrderDurRowid", GlobalObj.IPDefaultDurRowId);
					        SetCellData(rowid, "OrderDurFactor", GlobalObj.IPDefaultDurFactor);
						}else{
							//疗程
					        SetCellData(rowid, "OrderDur", RowDataObj.OrderDur);
					        SetCellData(rowid, "OrderDurRowid", RowDataObj.OrderDurRowid);
					        SetCellData(rowid, "OrderDurFactor", RowDataObj.OrderDurFactor);
						}
				        SetCellData(rowid, "OrderConFac", RowDataObj.OrderConFac);
				        SetCellData(rowid, "OrderPHForm", RowDataObj.OrderPHForm);
				        SetCellData(rowid, "OrderPHPrescType", RowDataObj.OrderPHPrescType);

				        //医嘱项ID
				        SetCellData(rowid, "OrderARCIMRowid", RowDataObj.OrderARCIMRowid);

				        SetCellData(rowid, "OrderDrugFormRowid", RowDataObj.OrderDrugFormRowid);
				        SetCellData(rowid, "OrderName", RowDataObj.OrderName);

				        //数量
				        SetCellData(rowid, "OrderPackQty", RowDataObj.OrderPackQty);
						
						SetColumnList(rowid, "OrderPackUOM", RowDataObj.OrderPackUOMStr);
						SetCellData(rowid, "OrderPackUOMStr", RowDataObj.OrderPackUOMStr);
				        SetCellData(rowid, "OrderPackUOM", RowDataObj.OrderPackUOMRowid); //OrderPackUOM
				        SetCellData(rowid, "OrderPackUOMRowid", RowDataObj.OrderPackUOMRowid);
				        SetCellData(rowid, "OrderDepProcNote", RowDataObj.OrderDepProcNote);
				        //流速
				        SetCellData(rowid, "OrderSpeedFlowRate", RowDataObj.OrderSpeedFlowRate);
				        SetCellData(rowid, "OrderFlowRateUnit", RowDataObj.OrderFlowRateUnitRowId);
				        SetCellData(rowid, "OrderFlowRateUnitRowId", RowDataObj.OrderFlowRateUnitRowId);
				        SetCellData(rowid, "ExceedReasonID", RowDataObj.DIDExceedReasonDR);
				        SetCellData(rowid, "ExceedReason", RowDataObj.DIDExceedReasonDR);
				        //价格
				        SetCellData(rowid, "OrderPrice", RowDataObj.OrderPrice);
				        //金额
				        SetCellData(rowid, "OrderSum", RowDataObj.OrderSum);
				        //医嘱分类
				        SetCellData(rowid, "OrderType", RowDataObj.OrderType);
				        //费别
				        //SetCellData(rowid,"OrderBillType",RowDataObj.OrderBillType);
				        SetCellData(rowid, "OrderBillType", RowDataObj.OrderBillTypeRowid);
				        SetCellData(rowid, "OrderBillTypeRowid", RowDataObj.OrderBillTypeRowid);
				        //附加说明
				        SetCellData(rowid, "OrderPriorRemarks", RowDataObj.OrderPriorRemarksRowId);
				        SetCellData(rowid, "OrderPriorRemarksRowId", RowDataObj.OrderPriorRemarksRowId);
				        //开始日期
				        SetCellData(rowid, "OrderStartDate", RowDataObj.OrderStartDate);
						//结束时间
						SetCellData(rowid, "OrderEndDate", RowDataObj.OrderEndDate);
						SetCellData(rowid, "OrderDate", RowDataObj.OrderDate);
						
				        SetCellData(rowid, "OrderBaseQty", RowDataObj.OrderBaseQty);
				        SetCellData(rowid, "OrderARCOSRowid", RowDataObj.OrderARCOSRowid);
				        SetCellData(rowid, "OrderMaxDurFactor", RowDataObj.OrderMaxDurFactor);
				        SetCellData(rowid, "OrderMaxQty", RowDataObj.OrderMaxQty);
				        SetCellData(rowid, "OrderBaseQtySum", RowDataObj.Qty);
				        SetCellData(rowid, "OrderFile1", RowDataObj.OrderFile1);
				        SetCellData(rowid, "OrderFile2", RowDataObj.OrderFile2);
				        SetCellData(rowid, "OrderFile3", RowDataObj.OrderFile3);
				        SetCellData(rowid, "OrderLabExCode", RowDataObj.OrderLabExCode);
				        SetCellData(rowid, "OrderAlertStockQty", RowDataObj.OrderAlertStockQty);
				        SetCellData(rowid, "OrderPoisonCode", RowDataObj.OrderPoisonCode);
				        SetCellData(rowid, "OrderPoisonRowid", RowDataObj.OrderPoisonRowid);
				        SetCellData(rowid, "LinkedMasterOrderRowid", RowDataObj.LinkedMasterOrderRowid);
				        SetCellData(rowid, "LinkedMasterOrderSeqNo", RowDataObj.LinkedMasterOrderSeqNo);
						SetCellData(rowid, "OrderNurseLinkOrderRowid", RowDataObj.OrderNurseLinkOrderRowid);
						SetCellData(rowid, "OrderCPWStepItemRowId", RowDataObj.OrderCPWStepItemRowId);
						SetCellData(rowid, "OrderMaterialBarcode", RowDataObj.OrderMaterialBarcode);
						SetCellData(rowid, "OrderMaterialBarcodeHiden", RowDataObj.OrderMaterialBarcodeHiden);
						if (RowDataObj.OrderFreqRowid==(GetCellData(rowid, "OrderFreqRowid"))) {
							SetColumnList(rowid,"OrderFirstDayTimesCode",RowDataObj.OrderFirstDayTimesStr);
							SetCellData(rowid,"OrderFirstDayTimesStr",RowDataObj.OrderFirstDayTimesStr);
							SetCellData(rowid, "OrderFirstDayTimesCode",RowDataObj.OrderFirstDayTimes);// 首日次数
						}
				        //手术列表 
				        SetColumnList(rowid,"OrderOperation",RowDataObj.OrderOperationStr);
				        SetCellData(rowid,"OrderOperation",RowDataObj.OrderOperationCode);
				        SetCellData(rowid,"OrderOperationCode",RowDataObj.OrderOperationCode);
				        SetCellData(rowid,"OrderOperationStr",RowDataObj.OrderOperationStr);
				        SetCellData(rowid,"AnaesthesiaID",RowDataObj.AnaesthesiaID);
				        //开医嘱医生
				        SetColumnList(rowid,"OrderDoc",RowDataObj.OrderDocStr);
				        SetCellData(rowid,"OrderDocStr",RowDataObj.OrderDocStr);
				        SetCellData(rowid,"OrderDoc",RowDataObj.OrderDocRowid);
				        SetCellData(rowid,"OrderDocRowid",RowDataObj.OrderDocRowid);
				        //****************抗生素8********************************/
				        var AntibApplyRowid = GetCellData(rowid, "OrderAntibApplyRowid")
				        if ((AntibApplyRowid == "") && (typeof(OrderAntibApplyRowid) != "undefined")) {
				            SetCellData(rowid, "OrderAntibApplyRowid", RowDataObj.OrderAntibApplyRowid);
				        }
				        var ReasonID = GetCellData(rowid, "UserReasonId")
				        if ((ReasonID == "") && (typeof(UserReasonID) != "undefined")) {
				            SetCellData(rowid, "UserReasonId", RowDataObj.UserReasonId);
				        }
				        //************************************************/
				        //只有备注是原液或空可以置皮试标志
				        if (RowDataObj.OrderSkinTest == "Y") {
				            SetCellChecked(rowid, "OrderSkinTest", true);
				        }else{
							SetCellChecked(rowid, "OrderSkinTest", false);
						}
				        SetCellData(rowid, "OrderActionRowid", RowDataObj.OrderActionRowid);
				        SetCellData(rowid, "OrderAction", RowDataObj.OrderActionRowid);
				        /*
				        按照三大项中的皮试标志，在GetStyleConfigObj里处理
				        var ActionRowid=GetCellData(rowid, "OrderActionRowid");
				        var ActionCode = GetOrderActionCode(ActionRowid);
				        if ((ActionCode == "MS") || (ActionCode == "XZ") || (ActionCode == "TM")) {
				            var styleConfigObj = { OrderSkinTest: false }
				            ChangeCellDisable(rowid, styleConfigObj);
				        }*/
				        if (RowDataObj.OrderCoverMainIns == "N") {
				            //医保
				            SetCellChecked(rowid, "OrderCoverMainIns", false);
				        } else {
				            SetCellChecked(rowid, "OrderCoverMainIns", true);
				        }
				        SetCellData(rowid, "OrderHiddenPara", RowDataObj.OrderHiddenPara);
				        if (ParamObj.OrderType == "R") {
				            SetCellData(rowid, "OrderGenericName", RowDataObj.OrderGenericName);
				        }
				        if (RowDataObj.OrderNeedPIVAFlag == "N") {
				            SetCellChecked(rowid, "OrderNeedPIVAFlag", false);
				        } else {
				            SetCellChecked(rowid, "OrderNeedPIVAFlag", true);
				        }
						SetCellData(rowid, "OrderBodyPartID", RowDataObj.OrderBodyPartID);
						SetCellData(rowid, "OrderBodyPart", RowDataObj.OrderBodyPart);
						SetCellData(rowid, "ExceedReasonID", RowDataObj.ExceedReasonID);
						SetCellData(rowid, "ExceedReason", RowDataObj.ExceedReasonID);
						SetCellData(rowid, "OrderMaterialBarcode", RowDataObj.OrderMaterialBarcode);
						SetCellData(rowid, "OrderMaterialBarcodeHiden", RowDataObj.OrderMaterialBarcodeHiden);
				        SetCellData(rowid, "OrderBodyPartLabel", RowDataObj.OrderBodyPartLabel);
						SetCellData(rowid, "OrderUsableDays", RowDataObj.OrderUsableDays);
						SetCellData(rowid, "OrderLocalInfusionQty", RowDataObj.OrderLocalInfusionQty);
						SetCellData(rowid, "OrderFreqTimeDoseStr", RowDataObj.OrderFreqTimeDoseStr);
						SetCellData(rowid, "OrderPkgOrderNo", RowDataObj.OrderPkgOrderNo);
						if (RowDataObj.OrderVirtualtLong == "Y") {
				            SetCellChecked(rowid, "OrderVirtualtLong", true);
				        }else{
							SetCellChecked(rowid, "OrderVirtualtLong", false);
                        }
                        SetColumnList(rowid, "OrderChronicDiag", RowDataObj.OrderChronicDiagStr);
                        SetCellData(rowid, "OrderChronicDiagStr", RowDataObj.OrderChronicDiagStr);
                        SetCellData(rowid, "OrderChronicDiag", RowDataObj.OrderChronicDiagCode);
                        SetCellData(rowid, "OrderChronicDiagCode", RowDataObj.OrderChronicDiagCode);
				        //初始化协议单位---tanjishan,改造至后台
				        //GetBillUOMStr(rowid);
				        //初始化医保分类
				        CreaterOrderInsurCat(rowid,"N");
				        //医保子分类
				        SetCellData(rowid, "OrderInsurCat", RowDataObj.OrderInsurCatRowId); //OrderInsurCat
				        SetCellData(rowid, "OrderInsurCatRowId", RowDataObj.OrderInsurCatRowId);
				        //对有频次的非药品医嘱根据开始时间计算首日次数---tanjishan,改造至后台
				        //SetOrderFirstDayTimes(rowid);
				        //加急勾选框默认灰
				        //$("#" + rowid + "_Urgent").prop("checked", false);
				        //if ((RowDataObj.ARCIMDefSensitive == "N")||(RowDataObj.OrderPriorRowid !=GlobalObj.ShortOrderPriorRowid)) {
						if (RowDataObj.Urgent == "N") {
							SetCellChecked(rowid, "Urgent", false);
				        } else {
							SetCellChecked(rowid, "Urgent", true);
				        }
				        //放在最后保证医嘱套中关联关系加载完后再检验
				        CheckOrderPriorRemarksLegal(rowid)
				        //检测可用性
				        //CheckFreqAndPackQty(rowid)--tanjishan,改造至后台
				        //添加空白行,按门诊住院业务跳转到指定焦点后再增加行
				        //Add_Order_row();
				        //设置焦点位置
				        //SetFocusCell(rowid,"OrderName")
				        //SetTimeLog("AddItemDataToRow", "按单列数据赋值行数据之后");
						callBackExecFun();
					}
				})
		    })(resolve);
	    }
	}).then(function(){
		var OrderFreqTimeDoseStr=RowDataObj.OrderFreqTimeDoseStr;
	    if (OrderFreqTimeDoseStr!=""){
		    var DoseQtyStr=GetDoseQty(OrderFreqTimeDoseStr);
			SetCellData(rowid, "OrderDoseQty",DoseQtyStr);
		}
	    //高危药高亮显示
	    var OrderName=GetCellData(rowid,"OrderName");
	    var OrderHiddenPara=GetCellData(rowid, "OrderHiddenPara");
	    var PHCDFCriticalFlag=OrderHiddenPara.split(String.fromCharCode(1))[17];
	    if (PHCDFCriticalFlag=="Y"){
		    if (GetEditStatus(rowid) == true) {
		    	$("#"+rowid+"_OrderName").parent().parent().addClass('OrderCritical');
		    }else{
			    $('#Order_DataGrid').setCell(rowid,"OrderName",RowDataObj.OrderName,"OrderCritical","");
			}
		}
	    var OrderPriorRemarksRowId=GetCellData(rowid, "OrderPriorRemarksRowId");
	    if (OrderPriorRemarksRowId=="ONE"){
	        var obj = { OrderDur: true };
	        ChangeRowStyle(rowid, obj);
		}
		var OrderFreqTimeDoseStr=GetCellData(rowid,"OrderFreqTimeDoseStr");
	    if (OrderFreqTimeDoseStr!=""){
		     ChangeRowStyle(rowid, {OrderDoseQty:"readonly"});
		}
		SetPoisonOrderStyle(RowDataObj.OrderPoisonCode, RowDataObj.OrderPoisonRowid, rowid);
	    
	    //频次->疗程监测
	    FreqDurChange(rowid)
	    var OrdSeqNo=GetCellData(rowid, "id"); //(ParamObj.OrderType == "R")&&
	    if ((StyleConfigObj.OrderMasterSeqNo==true)&&(OrdSeqNo!=PageLogicObj.StartMasterOrdSeq)){
			if ((PageLogicObj.IsStartOrdSeqLink==1)&&(RowDataObj.LinkedMasterOrderRowid=="")&&(RowDataObj.OrderBindSource=="")){
				if (PageLogicObj.StartMasterOrdSeq==""){
					PageLogicObj.StartMasterOrdSeq=rowid; //如果开始关联但没有设置关联开始序号，则默认开始关联后的第一条为主医嘱
				}else{
					var CanLink=1; //是否可关联
					var subOrderType = GetCellData(rowid, "OrderType");
					var OrderInstrRowid=GetCellData(rowid, "OrderInstrRowid");
					var MainEditStatus=GetEditStatus(PageLogicObj.StartMasterOrdSeq);
					var EditStatus=GetEditStatus(rowid);
					if ((MainEditStatus)&&(EditStatus)) {
						var IdOrderFreq = PageLogicObj.StartMasterOrdSeq + "_" + "OrderFreq";
			            var objFreq = document.getElementById(IdOrderFreq);
					    var subIdOrderFreq = rowid + "_" + "OrderFreq";
		            	var subobjFreq = document.getElementById(subIdOrderFreq);
		            	// 主医嘱频次不可编辑,子医嘱可编辑则不可关联
		            	// 设置不可关联的子类,不可关联
		            	if (((objFreq.disabled)&&((!subobjFreq.disabled)||(subOrderType=="R")))||(!StyleConfigObj.OrderMasterSeqNo)){ 
			            	CanLink=0;
			            }
			            // 主医嘱用法不可编辑,子医嘱可编辑则不可关联
			            var objOrderInstr = document.getElementById(PageLogicObj.StartMasterOrdSeq + "_" + "OrderInstr");
			            var subOrderInstr = document.getElementById(rowid + "_" + "OrderInstr");
			            //if (((objOrderInstr.disabled)&&((!subOrderInstr.disabled)||(subOrderType=="R")))||(!StyleConfigObj.OrderMasterSeqNo)){ 
			            if ((objOrderInstr.disabled)&&(!subOrderInstr.disabled)&&(OrderInstrRowid =="")){ 
			            	CanLink=0;
			            }
		            }else{
			            var MainStyleConfigStr = GetCellData(PageLogicObj.StartMasterOrdSeq, "StyleConfigStr");
			            var MainStyleConfigObj = {};
					    if (MainStyleConfigStr != "") {
					        MainStyleConfigObj = eval("(" + MainStyleConfigStr + ")");
					    }
			            if (((!MainStyleConfigObj.OrderFreq)&&((StyleConfigObj.OrderFreq)||(subOrderType=="R")))||(!StyleConfigObj.OrderMasterSeqNo)){ 
			            	CanLink=0;
			            }
			            if ((!MainStyleConfigObj.OrderInstr)&&(StyleConfigObj.OrderInstr)&&(OrderInstrRowid =="")){ 
			            	CanLink=0;
			            }
			        }
		            if (!StyleConfigObj.OrderMasterSeqNo) {
			            CanLink=0;
			        }
		            // 子医嘱非药品,主医嘱是出院带药,不可关联
		            var MainOrderPriorRowid=GetCellData(PageLogicObj.StartMasterOrdSeq,"OrderPriorRowid");
			        if ((MainOrderPriorRowid==GlobalObj.OutOrderPriorRowid)&&(subOrderType!="R")){
				        CanLink=0;
				    }
					var OrderPriorRowid=GetCellData(rowid,"OrderPriorRowid");
					if(MainOrderPriorRowid!=OrderPriorRowid){
						CanLink=0;
					}
				    var MasOrderPriorRemarksRowId=GetCellData(PageLogicObj.StartMasterOrdSeq, "OrderPriorRemarksRowId");
				    var SubOrderPriorRemarksRowId=GetCellData(rowid, "OrderPriorRemarksRowId");
				    if ((MasOrderPriorRemarksRowId=="ONE")||(SubOrderPriorRemarksRowId=="ONE")){
				        CanLink=0;
				    }
		            if (CanLink=="1"){
						SetCellData(rowid, "OrderMasterSeqNo", PageLogicObj.StartMasterOrdSeq);
						var Status=$("#jqg_Order_DataGrid_" + rowid).prop("checked");
				        if (Status){
			            	$("#Order_DataGrid").setSelection(rowid, false);
			            }
		            }
				}
			}
		}
		//设置关联
	    var MasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
	    if (MasterSeqNo!=""){
		    var Selrowids = GetSelRowId();
	        var selRowLen=Selrowids.length
		    for (var tmpi = selRowLen-1; tmpi >=0; tmpi--) {
		        if (CheckIsItem(Selrowids[tmpi]) == false) {
			        var tmpMasterSeqNo=GetCellData(Selrowids[tmpi], "OrderMasterSeqNo");
			        var Status=$("#jqg_Order_DataGrid_" + Selrowids[tmpi]).prop("checked");
			        if (Status){
		            	$("#Order_DataGrid").setSelection(Selrowids[tmpi], false);
		            }
		        }
		    }
			$("#" + rowid).find("td").addClass("OrderMasterS");
			CheckMasterOrdStyle();
			if ((AddMethod == "obj")&&(GlobalObj.isEditCopyItem!='Y')){
				//todo 待优化,处理非直接录入,从外部带入数据(参数:Para),对于combo的列需要显示描述,现在是显示的数字
			    //EditRow(rowid);
			    //SetMasterSeqNo(MasterSeqNo, rowid, "S");
			    //EndEditRow(rowid);
			}else{
	        	//SetMasterSeqNo(MasterSeqNo, rowid, "S");
	        	if (AddMethod == "obj") {
	        		SetCellData(rowid, "OrderPackQty", RowDataObj.OrderPackQty);
	        	}
	        }
			ChangeCellsDisabledStyle(rowid, false);
	     }else{
		    var Status=$("#jqg_Order_DataGrid_" + rowid).prop("checked");
	        if (Status){
	        	$("#Order_DataGrid").setSelection(rowid, false);
	        }
		 }
		OrdDoseQtyBindClick(rowid);
	    //知识库
	    CheckLibPhaFunction("Q", rowid, "")
	    if ((RowDataObj.LinkedMasterOrderRowid!="")||(RowDataObj.OrderNurseLinkOrderRowid!="")) {
		    initItemInstrDiv(rowid);
		}
	    //OrderPackUOMchangeCommon 中已调用合理用药,此处调用重复
	    if (AddMethod != "obj") {
	        //XHZY_Click();
	    }
	    callBackFun(true);
	})
}

//添加到表格  2014-04-23  新
/*
rowid:行号
OrdParams:需要录入的医嘱项目的集合（增加单个医嘱项属性需修新增此子对象属性）
ExpStr:扩展信息（全局、非单个医嘱项目属性，本方法内值不变）
*/
//
function AddItemToList(rowid,OrdParams, AddMethod,ExpStr,callBackFun){
	//第3个参数："data"方式不试用添加行对象方式，"obj"方式试用添加行对象方式
    if (AddMethod == "obj") {
		PageLogicObj.m_AddItemToListMethod = "ARCOS";
    }
	
	var RtnObj={
		returnValue:false,
		rowid:rowid
	};
	var CopyType=mPiece(ExpStr, "^", 0);
	var FastEntryMode=mPiece(ExpStr, "^", 1);
	var FastEntryName=mPiece(ExpStr, "^", 2);
	var OrderARCOSRowid=mPiece(ExpStr, "^", 3);
	if (FastEntryMode==1){
		rowid=GetAddRowid(rowid,"data");
	}else{
		rowid=GetAddRowid(rowid,AddMethod);
	}
	var prerowid = GetPreRowId(rowid);
    PageLogicObj.NotEnoughStockFlag=0;
    SetTimeLog("AddItemToList", "start");
	if (typeof ItemExpInfo=="undefined"){
		ItemExpInfo="";
	}
	
    var RowDataObj = {};
    for (var k = 0; k < colModelAry.length; k++) {
        var key = colModelAry[k].name;
        $.extend(RowDataObj, { key: '' });
    }
    //取默认数据
    var DefaultParamObj = GetDefaultData(rowid);
    //封装行对象
    $.extend(RowDataObj, DefaultParamObj);
	var OrderPriorRemarks=OrderPriorRemarksRowId=RowOrderBillTypeRowid="";
	//if (document.getElementById(rowid + "_OrderARCIMRowid")){
	if (AddMethod == "data") {
		//在外层加，防止新增默认行的时候带出附加说明
		OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarks");
		OrderPriorRemarksRowId = GetCellData(rowid, "OrderPriorRemarksRowId");
		RowOrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
	}
	$.extend(RowDataObj, { OrderPriorRemarks: OrderPriorRemarks, OrderPriorRemarksRowId:OrderPriorRemarksRowId });
    
    var OrderBillTypeRowid = !isNaN(DefaultParamObj.OrderBillTypeRowid)?parseInt(DefaultParamObj.OrderBillTypeRowid):"";
    if (RowOrderBillTypeRowid != "") {
        RowOrderBillTypeRowid = RowOrderBillTypeRowid.replace(String.fromCharCode(10), "")
        OrderBillTypeRowid = RowOrderBillTypeRowid
    }
    var OrderActionRowid=GetCellData(rowid, "OrderActionRowid")
    $.extend(RowDataObj, { OrderActionRowid: OrderActionRowid});
    
    //如果按登录科室取接收科室?就把登录科室传进去 session['LOGON.CTLOCID']
    var LogonDep = GetLogonLocByFlag();
    //跨院
	var OrderOpenForAllHosp=$("#OrderOpenForAllHosp").checkbox("getValue")?1:0;
    var SessionStr = GetSessionStr();
    var OrderARCIMRowid=GetCellData(rowid, "OrderARCIMRowid");
    if (OrderARCIMRowid!=""){
	    var GlobalDefaultOrderPriorRowid=GetCellData(rowid, "OrderPriorRowid");
	    var OrderPrior=GetCellData(rowid, "OrderPrior");
	    var PageDefaultOrderPriorStr=GlobalDefaultOrderPriorRowid + "^" + GlobalDefaultOrderPriorRowid+ ":" +OrderPrior;
	}else{
		var PageDefaultOrderPriorStr=GetDefaultOrderPrior("");
		var GlobalDefaultOrderPriorRowid=GlobalObj.DefaultOrderPriorRowid;
	}
    var BaseParam = {
		///单条医嘱信息-后台会重置这部分数据
		OrderARCIMRowid:"",
		ItemDefaultRowId:"",
		OrderBillTypeRowid:OrderBillTypeRowid,
		RelocRowID:"",
		MaterialBarcode:"",
		ITMRowId:"",
		OrderBodyPartLabel:"",
		MasterSeqNo:PageLogicObj.StartMasterOrdSeq==rowid?"":PageLogicObj.StartMasterOrdSeq,
		///rowid需要在后台修改,和前台的实际行号不一定能对照起来，原因参考快速医嘱套录入功能
		rowid:rowid,
		///全局变量
		Adm:GlobalObj.EpisodeID,
		CopyType:CopyType,
		LogonDep:LogonDep,
		OrderOpenForAllHosp:OrderOpenForAllHosp, 
		SessionStr:SessionStr,
		AddMethod:AddMethod,
		PPRowId:GlobalObj.PPRowId,
		OrderPriorContrlConfig:GlobalObj.OrderPriorContrlConfig,
		PageDefaultOrderPriorStr:PageDefaultOrderPriorStr,
		GlobalDefaultOrderPriorRowid:GlobalDefaultOrderPriorRowid,
		VerifiedOrderObj:VerifiedOrderObj,
		isEditCopyItem:GlobalObj.isEditCopyItem=='Y'?1:0,
		AnaesthesiaID:GetMenuPara("AnaesthesiaID"),
		OrderOperationCode:GetMenuPara("AnaestOperationID"),
        OrderARCOSRowid:OrderARCOSRowid,
        OrderChronicDiagCode:GetChronicDiagCode()
    };
    if (($.isNumeric(prerowid) == true)&&(!BaseParam.OrderOperationCode)) {
	    var PreOrderOperationCode=GetCellData(prerowid,"OrderOperationCode");
	    BaseParam.OrderOperationCode=PreOrderOperationCode;
	}
    if (FastEntryMode==1) BaseParam.MasterSeqNo="";
    var ItemOrdsJson=GetItemOrds();
	//需要绑定到行上的医嘱
	var UserOptionsArr=new Array();
	var NeedAddItemCongeriesArr=new Array();
	/*
	对于快速医嘱套中的单条项目的判断或处理，需要抗菌药物处理，是否能够上医嘱录入行，如果能，就设置成独立行录入（）；如果不能录入，直接callback处理
	TODO:
	*/
	new Promise(function(resolve,rejected){
		GetItemCongeries(OrdParams,BaseParam,ItemOrdsJson,RowDataObj,UserOptionsArr,resolve);
	}).then(function(NeedAddItemCongeriesObj){
		return new Promise(function(resolve,rejected){
			NeedAddItemCongeriesObjArr=NeedAddItemCongeriesObj;
			if (NeedAddItemCongeriesObj.length==0){
				$.extend(RtnObj, {returnValue:false});
				if (callBackFun) callBackFun(RtnObj);
				return;
			}
			PageLogicObj.NotEnoughStockFlag=0;
			if (FastEntryMode==1){
				//医嘱套快速录入
				var StyleConfigObj={
					OrderDur: false,
					OrderFreq: false,
					OrderPackQty: false,
					OrderPackUOM: false,
					OrderDoseQty: false,
					OrderDoseUOM: false,
					OrderInstr: false,
					OrderPrice: false,
					OrderAction: false,
					OrderMasterSeqNo: false,
					OrderLabSpec: false,
					OrderNotifyClinician: false,
					OrderInsurCat: false,
					OrderSpeedFlowRate: false,
					OrderFlowRateUnit: false,
					OrderNeedPIVAFlag: false,
					AntUseReason: false,
					OrderLabEpisodeNo: false,
					Urgent: false,
					OrderPrior: false,
					OrderSkinTest: false,
					OrderFirstDayTimes: false,
					OrderStartDate:true
				}
				//快速医嘱套开始时间判断,只判断科室权限
				StyleConfigObj.OrderStartDate=CheckDateTimeModifyFlag(GlobalObj.ModifySttDateTimeAuthority,"") 

				var StyleConfigStr = JSON.stringify(StyleConfigObj);
				var ItemCongeriesSum=0;
				var NeedAddSingleRowItem=[];
				var Len=NeedAddItemCongeriesObj.length;
				for (var i=0;i<NeedAddItemCongeriesObj.length;i++) {
					/*
					对于快速医嘱套中的单条项目的判断或处理，在此处处理；
					（抗菌药管理）、医嘱套明细维护快速例外
					*/
					if (NeedAddItemCongeriesObj[i].SingleRowFlag=="Y"){
						NeedAddSingleRowItem.push(NeedAddItemCongeriesObj[i]);
						NeedAddItemCongeriesObj.splice(i,1);
						i=i-1;
						continue;
					}
					ItemCongeriesSum=parseFloat(ItemCongeriesSum)+parseFloat(NeedAddItemCongeriesObj[i].OrderSum);
				}
				rowid=GetAddRowid(rowid,"data");
		    	ChangeRowStyle(rowid, StyleConfigObj);
		    	if (NeedAddSingleRowItem.length<Len){
					SetCellData(rowid, "OrderName", FastEntryName);
					SetCellData(rowid, "OrderARCOSRowid", OrderARCOSRowid);
					SetCellData(rowid, "OrderSum", ItemCongeriesSum);
					var OrderItemCongeriesJson=JSON.stringify(NeedAddItemCongeriesObj);
					//替换掉json中的HTML标签，防止存储到dom后，字符串被强制转换为html，导致再取数据时，数据发生变化
					OrderItemCongeriesJson=OrderItemCongeriesJson.replace(/<[\/\!]*[^<>]*>/ig,"");
			    	SetCellData(rowid, "OrderItemCongeries", OrderItemCongeriesJson);
			    	//var OrderCoverMainIns=NeedAddItemCongeriesObj[i].OrderCoverMainIns;
			    	if (NeedAddItemCongeriesObj[0].OrderCoverMainIns == "N") {
			            //医保
			            SetCellChecked(rowid, "OrderCoverMainIns", false);
			        } else {
			            SetCellChecked(rowid, "OrderCoverMainIns", true);
			        }
			        //手术列表 
					SetColumnList(rowid,"OrderOperation",NeedAddItemCongeriesObj[0].OrderOperationStr);
					SetCellData(rowid,"OrderOperation",NeedAddItemCongeriesObj[0].OrderOperationCode);
					SetCellData(rowid,"OrderOperationCode",NeedAddItemCongeriesObj[0].OrderOperationCode);
					SetCellData(rowid,"OrderOperationStr",NeedAddItemCongeriesObj[0].OrderOperationStr);
					SetCellData(rowid,"AnaesthesiaID",NeedAddItemCongeriesObj[0].AnaesthesiaID);
					 //开医嘱医生
					SetColumnList(rowid,"OrderDoc",NeedAddItemCongeriesObj[0].OrderDocStr);
					SetCellData(rowid,"OrderDocStr",NeedAddItemCongeriesObj[0].OrderDocStr);
					SetCellData(rowid,"OrderDoc",NeedAddItemCongeriesObj[0].OrderDocRowid);
					SetCellData(rowid,"OrderDocRowid",NeedAddItemCongeriesObj[0].OrderDocRowid);
		    	}
				if (NeedAddSingleRowItem.length>0){
					rowid=GetAddRowid("",AddMethod);
					AddItemCongeriesToRow(rowid,AddMethod,NeedAddSingleRowItem,resolve);
				}else{
					resolve();
				}
			}else{
				AddItemCongeriesToRow(rowid,AddMethod,NeedAddItemCongeriesObj,resolve);
			}
			
		})
	}).then(function(){
		//因为如果调到抗菌药物，有可能又会删除行，在这里再获取一遍最后的行号
		rowid = GetPreRowId();
		if (PageLogicObj.m_AddItemToListMethod != "ARCOS") SetScreenSum();
		XHZY_Click();
		GetBindOrdItemTip(rowid);
		SetTimeLog("AddItemToList", "end");
		if ((rowid!="")&&(NeedAddItemCongeriesObjArr.length>0)){
			$.extend(RtnObj, {returnValue:true,rowid:rowid});
		}else{
			$.extend(RtnObj, {returnValue:false});
		}
		if (callBackFun) callBackFun(RtnObj);
	})
	//将对象集合添加到行上
	function AddItemCongeriesToRow(rowid,AddMethod,NeedAddItemCongeriesObj,callBackFun){
		var seqnoarr = new Array(),GroupSeqNoArr = new Array(),tempseqnoarr= new Array();
		var SuccessCount=0;
		var ParamObj={},CopyRowDataObj={};
		var Startrowid="",CalSeqNo="";
		function loop(i){
			new Promise(function(resolve,rejected){
				ParamObj={};
				ParamObj=NeedAddItemCongeriesObj[i];
				rowid=GetAddRowid(rowid,AddMethod);
				ParamObj.rowid=rowid;
				if (Startrowid==""){Startrowid=ParamObj.rowid;}
				CalSeqNo=ParamObj.CalSeqNo;
				//记录关联关系
				var MasterSeqNo="";
				tempseqnoarr = CalSeqNo.split(".");
				if (tempseqnoarr.length > 1) {
					var masterseqno = tempseqnoarr[0];
					if (seqnoarr[masterseqno]) {
						MasterSeqNo = seqnoarr[masterseqno];
					}
				}
				ParamObj.OrderMasterSeqNo=MasterSeqNo;
				if (MasterSeqNo!=""){
					GroupSeqNoArr[rowid]=MasterSeqNo;
				}
				CopyRowDataObj={};
				CopyRowDataObj=DeepCopyObject(RowDataObj);
				//保存行数据
				AddItemDataToRow(ParamObj,CopyRowDataObj,AddMethod,resolve);
			}).then(function(returnValue){
				if (returnValue == true) {
					if (tempseqnoarr.length =1) {
						newseqno = CopyRowDataObj.id;
						seqnoarr[CalSeqNo] = newseqno;
					}
					if (PageLogicObj.m_selArcimRowIdStr=="") PageLogicObj.m_selArcimRowIdStr=ParamObj.OrderARCIMRowid;
					else  PageLogicObj.m_selArcimRowIdStr=PageLogicObj.m_selArcimRowIdStr+"^"+ParamObj.OrderARCIMRowid;
				}
				if ((i+1)<NeedAddItemCongeriesObj.length){
					rowid="";
				}
				SuccessCount++;
				i++;
				if ( i < NeedAddItemCongeriesObj.length ) {
					 loop(i);
				}else{
					callBackFun(rowid);
				}
			})
		}
		loop(0);
	}
	function GetItemOrds(){
		var ItemOrdsObj={
			Length:0,
			ItemOrds:[]	//行对象集合
		}
		var rowids = $('#Order_DataGrid').getDataIDs();
		for (var i = 0; i < rowids.length; i++) {
			var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
			var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
			var OrderARCOSRowid = GetCellData(rowids[i], "OrderARCOSRowid");
			if ((OrderItemRowid!="")||((OrderARCIMRowid=="")&&(OrderARCOSRowid==""))) continue;
			var OrderSeqNo = GetCellData(rowids[i], "id").replace(/(^\s*)|(\s*$)/g, '');
			var OrderMasterSeqNo = GetCellData(rowids[i], "OrderMasterSeqNo").replace(/(^\s*)|(\s*$)/g, '');
			var OrderItemCongeriesJson = GetCellData(rowids[i], "OrderItemCongeries");
			if (OrderItemCongeriesJson!=""){
				var OrderItemCongeriesObj=eval("("+OrderItemCongeriesJson+")")
				for (var j=0;j<OrderItemCongeriesObj.length;j++) {
					var OrderARCIMRowid=OrderItemCongeriesObj[j].OrderARCIMRowid;
					var OrderPriorRowid=OrderItemCongeriesObj[j].SpecOrderPriorRowid;
					var OrderBillTypeRowid=OrderItemCongeriesObj[j].OrderBillTypeRowid;
					var OrderFreqDispTimeStr = OrderItemCongeriesObj[j]["OrderFreqDispTimeStr"]; 
					if (OrderFreqDispTimeStr!="") {
						var OrderStartDate = OrderItemCongeriesObj[j]["OrderStartDate"];
					}else{
						var OrderStartDate=GetCellData(rowids[i],"OrderStartDate");
					}
					var OrderEndDate="";
					var OrderDate = GetCellData(rowids[i], "OrderDate");
					var OrderLabSpecRowid=OrderItemCongeriesObj[j].OrderLabSpecRowid;
					var OrderFreqRowid=OrderItemCongeriesObj[j].OrderFreqRowid;
					var OrderFreq=OrderItemCongeriesObj[j].OrderFreq;
					var OrderDurRowid=OrderItemCongeriesObj[j].OrderDurRowid;
					var OrderInstrRowid=OrderItemCongeriesObj[j].OrderInstrRowid;
					var OrderRecDepRowid=OrderItemCongeriesObj[j].OrderRecDepRowid;
					var OrderFirstDayTimes=OrderItemCongeriesObj[j].OrderFirstDayTimes;
					var OrderNeedPIVAFlag=OrderItemCongeriesObj[j].OrderNeedPIVAFlag;
					var OrderSpeedFlowRate=OrderItemCongeriesObj[j].OrderSpeedFlowRate;
					var OrderFlowRateUnitRowId=OrderItemCongeriesObj[j].OrderFlowRateUnitRowId;
					var OrderBodyPartID="";
					var OrderStageCode = GetCellData(rowids[i], "OrderStageCode");
					var ExceedReasonID="",OrderMaterialBarcode="";
					var OrderSkinTest=OrderItemCongeriesObj[j].OrderSkinTest;
					var OrderActionRowid=OrderItemCongeriesObj[j].OrderActionRowid;
					var OrderLocalInfusionQty=OrderItemCongeriesObj[j].OrderLocalInfusionQty;
					var ItemOrd={
						OrderItemRowid:'',
						rowid:rowids[i],
						OrderSeqNo:OrderSeqNo,
						OrderMasterSeqNo:OrderMasterSeqNo,
						OrderPriorRowid:OrderPriorRowid,
						OrderARCIMRowid:OrderARCIMRowid,
						OrderBillTypeRowid:OrderBillTypeRowid,
						OrderStartDate:OrderStartDate,
						OrderEndDate:OrderEndDate,
						OrderDate:OrderDate,
						OrderLabSpecRowid:OrderLabSpecRowid,
						OrderFreqRowid:OrderFreqRowid,
						OrderFreq:OrderFreq,
						OrderDurRowid:OrderDurRowid,
						OrderInstrRowid:OrderInstrRowid,
						OrderRecDepRowid:OrderRecDepRowid,
						OrderFirstDayTimes:OrderFirstDayTimes,
						OrderNeedPIVAFlag:OrderNeedPIVAFlag,
						OrderSpeedFlowRate:OrderSpeedFlowRate,
						OrderFlowRateUnitRowId:OrderFlowRateUnitRowId,
						OrderBodyPartID:OrderBodyPartID,
						OrderStageCode:OrderStageCode,
						ExceedReasonID:ExceedReasonID,
						OrderMaterialBarcode:OrderMaterialBarcode,
						OrderSkinTest:OrderSkinTest,
						OrderActionRowid:OrderActionRowid,
						OrderFreqDispTimeStr:OrderFreqDispTimeStr,
						OrderLocalInfusionQty:OrderLocalInfusionQty
					};
					ItemOrdsObj.ItemOrds.push(ItemOrd);
					ItemOrdsObj.Length=ItemOrdsObj.Length+1;
				}
				continue;
			}
			var OrderPriorRowid = GetCellData(rowids[i], "OrderPriorRowid");
			var OrderPriorRemarks = GetCellData(rowids[i], "OrderPriorRemarksRowId");
            OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
			var OrderBillTypeRowid=GetCellData(rowids[i], "OrderBillTypeRowid");
			var OrderStartDate=GetCellData(rowids[i], "OrderStartDate");
			var OrderEndDate=GetCellData(rowids[i], "OrderEndDate");
			var OrderDate=GetCellData(rowids[i], "OrderDate");
			
			var OrderLabSpecRowid=GetCellData(rowids[i], "OrderLabSpecRowid");
			var OrderFreqRowid=GetCellData(rowids[i], "OrderFreqRowid");
			var OrderFreq=GetCellData(rowids[i], "OrderFreq");
			var OrderDurRowid=GetCellData(rowids[i], "OrderDurRowid");
			var OrderInstrRowid=GetCellData(rowids[i], "OrderInstrRowid");
			var OrderRecDepRowid=GetCellData(rowids[i], "OrderRecDepRowid");
			var OrderFirstDayTimes=GetCellData(rowids[i], "OrderFirstDayTimes");
			var OrderNeedPIVAFlag=GetCellData(rowids[i], "OrderNeedPIVAFlag");
			var OrderSpeedFlowRate=GetCellData(rowids[i], "OrderSpeedFlowRate");
			var OrderFlowRateUnitRowId=GetCellData(rowids[i], "OrderFlowRateUnitRowId");
			var OrderBodyPartID=GetCellData(rowids[i], "OrderBodyPartID");
			var OrderStageCode=GetCellData(rowids[i], "OrderStageCode");
			var ExceedReasonID=GetCellData(rowids[i], "ExceedReasonID");
			var OrderMaterialBarcode=GetCellData(rowids[i], "OrderMaterialBarcodeHiden");
			var OrderSkinTest=GetCellData(rowids[i], "OrderSkinTest");
			var OrderActionRowid=GetCellData(rowids[i], "OrderActionRowid");
			var OrderFreqDispTimeStr=GetCellData(rowids[i], "OrderFreqDispTimeStr");
			var OrderLocalInfusionQty=GetCellData(rowids[i], "OrderLocalInfusionQty");
			
			var ItemOrd={
				OrderItemRowid:'',
				rowid:rowids[i],
				OrderSeqNo:OrderSeqNo,
				OrderMasterSeqNo:OrderMasterSeqNo,
				OrderPriorRowid:OrderPriorRowid,
				OrderARCIMRowid:OrderARCIMRowid,
				OrderBillTypeRowid:OrderBillTypeRowid,
				OrderStartDate:OrderStartDate,
				OrderEndDate:OrderEndDate,
				OrderDate:OrderDate,
				OrderLabSpecRowid:OrderLabSpecRowid,
				OrderFreqRowid:OrderFreqRowid,
				OrderFreq:OrderFreq,
				OrderDurRowid:OrderDurRowid,
				OrderInstrRowid:OrderInstrRowid,
				OrderRecDepRowid:OrderRecDepRowid,
				OrderFirstDayTimes:OrderFirstDayTimes,
				OrderNeedPIVAFlag:OrderNeedPIVAFlag,
				OrderSpeedFlowRate:OrderSpeedFlowRate,
				OrderFlowRateUnitRowId:OrderFlowRateUnitRowId,
				OrderBodyPartID:OrderBodyPartID,
				OrderStageCode:OrderStageCode,
				ExceedReasonID:ExceedReasonID,
				OrderMaterialBarcode:OrderMaterialBarcode,
				OrderSkinTest:OrderSkinTest,
				OrderActionRowid:OrderActionRowid,
				OrderFreqDispTimeStr:OrderFreqDispTimeStr,
				OrderLocalInfusionQty:OrderLocalInfusionQty
			};
			ItemOrdsObj.ItemOrds.push(ItemOrd);
			ItemOrdsObj.Length=ItemOrdsObj.Length+1;
		}
		var ItemOrdsJson=JSON.stringify(ItemOrdsObj);
		return ItemOrdsJson;
	}
	//获取行,简拼录入、高值会传入rowid
	function GetAddRowid(rowid,AddMethod){
		if (rowid==""){
			var CruRow = GetPreRowId();
			if ((CruRow!="")&&(CheckIsClear(CruRow) == true)) {
				if (AddMethod=="obj"){
					DeleteRow(CruRow);
					var rowid = GetNewrowid();
				}else{
					var rowid = CruRow;
				}
			}else{
				if (AddMethod=="obj"){
					var rowid = GetNewrowid();
				}else{
					var rowid = Add_Order_row(AddMethod);
				}
			}
		}
		return rowid;
	}
	/*
	OrdCongeriesObj:医嘱信息\若是医嘱复制或医嘱套，则是医嘱信息集合
	BaseParamObj:界面基本变量信息
	ItemOrdsJson:界面已添加到行上但未审核的医嘱部分信息
	RowDataObj：当前行上的信息（未操作时为默认信息）
	UserOptionsArr：基于需要用户判断选择的信息，比如confirm选项、周频次，该参数的值在与用户交互后如果发生变化，则会触发递归操作，重新调用后台方法获取新的医嘱数据串
	*/
	//ItemCongeriesParamObj
	function GetItemCongeries(OrdCongeriesObj,BaseParamObj,ItemOrdsJson,RowDataObj,UserOptionsArr,callBackFun){
		var NeedAddItemCongeriesObj=new Array();
		var OrdCongeriesJson=JSON.stringify(OrdCongeriesObj);
		var BaseParamJson=JSON.stringify(BaseParamObj);
		var RowDataJson=JSON.stringify(RowDataObj);
		var UserOptionsJson=JSON.stringify(UserOptionsArr);
		
		var ItemCongeries = cspRunServerMethod(GlobalObj.GetItemCongeriesToListMethod, OrdCongeriesJson,BaseParamJson,ItemOrdsJson,RowDataJson,UserOptionsJson);
		var ItemCongeriesObj=eval("("+ItemCongeries+")");
		/***
		  UserOptionCount 需要进行二次前后台交互的callbacks数量,对于医嘱套/医嘱复制等一次录入多条的,
		  第一次只进行需要交互的提示，第二次进行全部医嘱的callbacks交互提示，防止提示重复。
		***/
		var UserOptionCount=0;
		for (var i=0;i<ItemCongeriesObj.length;i++){
			if (typeof ItemCongeriesObj[i].CallBakFunS=="object"){
				var ItemToListDetailObj=ItemCongeriesObj[i];
				if (!$.isEmptyObject(ItemToListDetailObj)) {
					for (var j=0;j<ItemToListDetailObj.CallBakFunS.length;j++){
						var FunCode=ItemToListDetailObj.CallBakFunS[j].CallBakFunCode;
						if ((FunCode=="SetOrderFreqDispTimeStr")||(FunCode=="SetMulDoses")||(FunCode=="GuideAllergy")||(FunCode=="AppendAllergyOrder")) {
							UserOptionCount++;
						}
					}
				}				
			}
		}
		var RecursionFlag=false,Sum=0;
		new Promise(function(resolve,rejected){
			(function(callBackExecFun){
				function loop(i){
					var ItemToListDetailObj=ItemCongeriesObj[i];
					new Promise(function(resolve,rejected){
						if ($.isEmptyObject(ItemToListDetailObj)) {
							resolve();
						}
						///注意:js中对象都是指针型
						///校验后台获取的行数据是否可用或是否需要修改
						$.extend(ItemToListDetailObj, {ItemCongeriesObj:ItemCongeriesObj,UserOptionCount:UserOptionCount,callBackFun:resolve});
						CheckItemCongeries(ItemToListDetailObj);
					}).then(function(CheckBeforeAddObj){
						return new Promise(function(resolve,rejected){
							if (typeof CheckBeforeAddObj!="undefined"){
								if (CheckBeforeAddObj.UserOptionObj.length>0){
									UserOptionsArr.push({rowid:ItemToListDetailObj.OrdListInfo.rowid,UserOption:CheckBeforeAddObj.UserOptionObj});
									RecursionFlag=true;
								}
								if (!RecursionFlag) {
									//费用控制
									var OrderPriorRowid=ItemToListDetailObj.OrdListInfo.OrderPriorRowid;
									var OrderPriorRemarksRowId=ItemToListDetailObj.OrdListInfo.OrderPriorRemarksRowId;
									var OrderPrice=ItemToListDetailObj.OrdListInfo.OrderPrice;
									if ((OrderPriorRowid != GlobalObj.OMOrderPriorRowid) && (OrderPriorRowid != GlobalObj.OMSOrderPriorRowid) && (OrderPrice != 0) && (OrderPriorRemarksRowId != "OM") && (OrderPriorRemarksRowId != "ZT")) {
										Sum=parseFloat(Sum)+parseFloat(ItemToListDetailObj.OrdListInfo.OrderSum);
										CheckPrescriptSum(Sum, ItemToListDetailObj.OrdListInfo.OrderARCIMRowid,ItemToListDetailObj.OrdListInfo.OrderName,function(PrescCheck){
											if (PrescCheck == false) {
												$.extend(CheckBeforeAddObj, {SuccessFlag:false});
											}
											resolve(CheckBeforeAddObj);
										});
										return;
									}
								}
							}
							resolve(CheckBeforeAddObj);
						});
					}).then(function(CheckBeforeAddObj){
						if ((typeof CheckBeforeAddObj!="undefined")&&(CheckBeforeAddObj.SuccessFlag==true)&&($.isEmptyObject(ItemToListDetailObj.OrdListInfo)==false)){
							$.extend(ItemToListDetailObj.OrdListInfo, {StartDateEnbale:CheckBeforeAddObj.StartDateEnbale,OrderDateEnbale:CheckBeforeAddObj.OrderDateEnbale});
							NeedAddItemCongeriesObj[NeedAddItemCongeriesObj.length]=ItemToListDetailObj.OrdListInfo;
						}
						i++;
						if ( i < ItemCongeriesObj.length ) {
							 loop(i);
						}else{
							if (RecursionFlag==true){
								GetItemCongeries(OrdCongeriesObj,BaseParamObj,ItemOrdsJson,RowDataObj,UserOptionsArr,callBackFun);
								return;
							}else{
								callBackExecFun();
							}
						}
					})
				}
				loop(0)
			})(resolve); //此处的resolve是指callBackFun(NeedAddItemCongeriesObj)
		}).then(function(){
			SetTimeLog("AddItemToList", "GetItemCongeries over");
			callBackFun(NeedAddItemCongeriesObj);
		});
	}
}
function SetRecLocStr(Row, PriorRowid, OrderPriorRemarks) {
	if (CheckIsItem(Row) == true) { return; }
	if(!PriorRowid) PriorRowid=GetCellData(Row, "OrderPriorRowid");
	var obj = document.getElementById("FindByLogDep");
	var FindRecLocByLogonLoc=obj&&obj.checked?1:0;
	var OrderOpenForAllHosp=$("#OrderOpenForAllHosp").checkbox("getValue")?1:0;
	var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
	if (OrderARCIMRowid=="") { return; }
	if(!OrderPriorRemarks) OrderPriorRemarks = GetCellData(Row, "OrderPriorRemarksRowId");
	var OrderNotifyClinician = GetCellData(Row, "Urgent");
	var DefaultReclocRowid=GetCellData(Row, "OrderRecDepRowid");
	var OrderInstrRowid=GetCellData(Row, "OrderInstrRowid");
	var OrderDateStr=GetCellData(Row,"OrderDate");
	var LinkOrderARCIMList="";
	var RowArry = GetSeqNolist(Row);
	for (var i = 0; i < RowArry.length; i++) {
		if (Row==RowArry[i]){
			continue;
		}
		var LinkOrderARCIMRowid = GetCellData(RowArry[i], "OrderARCIMRowid");
		if (LinkOrderARCIMRowid==""){
			continue;
		}
		if (LinkOrderARCIMList==""){
			LinkOrderARCIMList=LinkOrderARCIMRowid;
		}else{
			LinkOrderARCIMList=LinkOrderARCIMList+"^"+LinkOrderARCIMRowid;
		}
	}

	var RecLocInputObj={
		EpisodeID:GlobalObj.EpisodeID,
		SessionStr:GetSessionStr(),
		OpenForAllHosp:OrderOpenForAllHosp,
		FindRecLocByLogonLoc:FindRecLocByLogonLoc,
		DefaultReclocRowid:DefaultReclocRowid,
		OrderARCIMRowid:OrderARCIMRowid,
		OrderInstrRowid:OrderInstrRowid,
		OrderDateStr:OrderDateStr,
		OrderPriorRowid:PriorRowid,
		OrderPriorRemarksRowId:OrderPriorRemarks,
		NotifyClinician:OrderNotifyClinician,
		LinkOrderARCIMList:LinkOrderARCIMList
	};
	var RetLocJson=$.cm({
		ClassName:'web.DHCDocOrderCommon',
		MethodName:'GetRecLocInfo',
		OrdParamJson:JSON.stringify(RecLocInputObj),
		dataType:'text'
	},false);
	var RecLocRetObj=eval("(" + RetLocJson + ")");
	SetCellData(Row, "CurrentRecLocStr", RecLocRetObj.CurrentRecLocStr);
	SetCellData(Row, "OrderRecLocStr", RecLocRetObj.OrderNormalRecLocStr);
	SetColumnList(Row, "OrderRecDep", RecLocRetObj.CurrentRecLocStr);
	var OrderReclocRowid=GetCellData(Row, "OrderRecDepRowid");
	//防止在置关联时，子医嘱接收科室还未重置时出现接受科室不一致校验的问题
	if (OrderReclocRowid!=DefaultReclocRowid){
		var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
		if (OrderMasterSeqNo==""){
			var RowArry = GetSeqNolist(Row);
			RowArry.forEach(function(rowid){
				SetRecLocStr(rowid, PriorRowid, OrderPriorRemarks);
			})
		}
		OrderRecDepChangeCom(Row);
	}
	
    var retPrice = GetRecPrice(Row)
    if (retPrice==undefined) retPrice="0^0^0^0^0";
    var ArrPrice = retPrice.split("^");
    var Price = ArrPrice[0];
    var OrderConFac = ArrPrice[4];
    if (Price < 0) {
        var Price = ""
    }
    SetCellData(Row, "OrderPrice", Price);
    SetCellData(Row, "OrderConFac", OrderConFac)
}
//设置添加行数据对象
function SetRowDataObj(rowid, RowDataObj, ParamObj) {
    var dataObj = RowDataObj;
    //OrderPriorRemarks:OrderPriorRemarks,OrderPriorRemarksRowId:OrderPriorRemarksRowId
    $.extend(dataObj, {
        //行ID
        id: rowid,
        //行样式
        StyleConfigStr: ParamObj.StyleConfigStr,
        OrderItemRowid: '',
		OrderMasterSeqNo: ParamObj.OrderMasterSeqNo,
        OrderItemCatRowid: ParamObj.OrderItemCatRowid,
        OrderARCIMRowid: ParamObj.OrderARCIMRowid,
        OrderName: ParamObj.OrderName,
        //医保子分类
        OrderInsurCat: ParamObj.OrderInsurCat,
        OrderInsurCatRowId: ParamObj.OrderInsurCatRowId,
        //医嘱类型
        OrderPrior: ParamObj.OrderPrior,
        OrderPriorRowid: ParamObj.OrderPriorRowid,
        OrderPriorStr: ParamObj.OrderPriorStr,
		//重置医嘱类型
		ReSetPriorStr:ParamObj.ReSetPriorStr,
        //单次剂量
        OrderDoseQty: ParamObj.OrderDoseQty,
        //剂量单位
        OrderDoseUOM: ParamObj.OrderDoseUOM,
        OrderDoseUOMRowid: ParamObj.OrderDoseUOMRowid,
        //存储下拉框数据
        idoseqtystr: ParamObj.idoseqtystr,
        //特病病种
        idiagnoscatstr: ParamObj.idiagnoscatstr,
        //默认置上前一条的诊断类别  
        OrderDIACat: ParamObj.OrderDIACat,
        OrderDIACatRowId: ParamObj.OrderDIACatRowId,
        //记录下非出院带药的接收科室和出院带药的接收科室?当切换医嘱类型时需要这两个串
        OrderRecLocStr: ParamObj.OrderRecLocStr,
        OrderOutPriorRecLocStr: ParamObj.OrderOutPriorRecLocStr,
        OrderOnePriorRecLocStr: ParamObj.OrderOnePriorRecLocStr,
        OrderHolidayRecLocStr: ParamObj.OrderHolidayRecLocStr,
        //设定前面给定的有库存接受科室
        OrderRecDep: ParamObj.OrderRecDep,
        OrderRecDepRowid: ParamObj.OrderRecDepRowid,
        //存储下拉框数据
        CurrentRecLocStr: ParamObj.CurrentRecLocStr,
        //标本
        OrderLabSpec: ParamObj.OrderLabSpec,
        OrderLabSpecRowid: ParamObj.OrderLabSpecRowid,
        OrderLabSpecStr: ParamObj.OrderLabSpecStr,
        //频次
        OrderFreq: ParamObj.OrderFreq,
        OrderFreqRowid: ParamObj.OrderFreqRowid,
        OrderFreqFactor: ParamObj.OrderFreqFactor,
        OrderFreqInterval: ParamObj.OrderFreqInterval,
        OrderFreqDispTimeStr: ParamObj.OrderFreqDispTimeStr,
        //用法
        OrderInstr: ParamObj.OrderInstr,
        OrderInstrRowid: ParamObj.OrderInstrRowid,
        //疗程
        OrderDur: ParamObj.OrderDur,
        OrderDurRowid: ParamObj.OrderDurRowid,
        OrderDurFactor: ParamObj.OrderDurFactor,

        OrderConFac: ParamObj.OrderConFac,
        OrderPHForm: ParamObj.OrderPHForm,
        OrderPHPrescType: ParamObj.OrderPHPrescType,
        OrderDrugFormRowid: ParamObj.OrderDrugFormRowid,
        //数量
        OrderPackQty: ParamObj.OrderPackQty,
        OrderPackUOM: ParamObj.OrderPackUOM,
        OrderPackUOMRowid: ParamObj.OrderPackUOMRowid,
        SpecOrderPackUOMRowid:ParamObj.SpecOrderPackUOMRowid,
        //附加说明
        OrderPriorRemarks: ParamObj.OrderPriorRemarks,
        OrderPriorRemarksRowId: ParamObj.OrderPriorRemarksRowId,
        //价格
        OrderPrice: ParamObj.OrderPrice,
        //金额
        OrderSum: ParamObj.OrderSum,
        //医嘱分类
        OrderType: ParamObj.OrderType,
        //费别
        OrderBillType: ParamObj.OrderBillType,
        OrderBillTypeRowid: ParamObj.OrderBillTypeRowid,
        OrderStartDate: ParamObj.OrderStartDate,
		OrderEndDate: ParamObj.OrderEndDate,
		OrderDate: ParamObj.OrderDate,
        OrderBaseQty: ParamObj.OrderBaseQty,
        OrderARCOSRowid: ParamObj.OrderARCOSRowid,
        OrderMaxDurFactor: ParamObj.OrderMaxDurFactor,
        OrderMaxQty: ParamObj.OrderMaxQty,
        
        OrderFile1: ParamObj.OrderFile1,
        OrderFile2: ParamObj.OrderFile2,
        OrderFile3: ParamObj.OrderFile3,
        OrderLabExCode: ParamObj.OrderLabExCode,
        OrderAlertStockQty: ParamObj.OrderAlertStockQty,
        OrderPoisonCode: ParamObj.OrderPoisonCode,
        OrderPoisonRowid: ParamObj.OrderPoisonRowid,
		OrderMaterialBarcode: ParamObj.OrderMaterialBarcode,
        OrderMaterialBarcodeHiden: ParamObj.OrderMaterialBarcodeHiden,
        // 皮试标志 
        OrderSkinTest: ParamObj.OrderSkinTest,
        //皮试原液
        skintestyy: ParamObj.skintestyy,
        // 皮试备注
        OrderActionRowid: ParamObj.OrderActionRowid,
        OrderAction: ParamObj.OrderAction,
        //加急
        Urgent: ParamObj.Urgent,
        //医保
        OrderCoverMainIns: ParamObj.OrderCoverMainIns,
        OrderHiddenPara: ParamObj.OrderHiddenPara,
        OrderGenericName: ParamObj.OrderGenericName,
        LinkedMasterOrderRowid: ParamObj.LinkedMasterOrderRowid,
        LinkedMasterOrderSeqNo: ParamObj.LinkedMasterOrderSeqNo,
		OrderNurseLinkOrderRowid: ParamObj.OrderNurseLinkOrderRowid,
        OrderNeedPIVAFlag: ParamObj.OrderNeedPIVAFlag,
        OrderStage: ParamObj.OrderStage,
        OrderStageCode: ParamObj.OrderStageCode,
		//-
		OrderBodyPartID: ParamObj.OrderBodyPartID,
		OrderBodyPart: ParamObj.OrderBodyPart,
		ExceedReasonID: ParamObj.ExceedReasonID,
		ExceedReason: ParamObj.ExceedReason,
        //****************抗生素9********上一行添加一个,************************/
        OrderAntibApplyRowid: ParamObj.OrderAntibApplyRowid,
        UserReasonId: ParamObj.UserReasonId,
        SpecialAction: ParamObj.SpecialAction, //update by shp 20150714
        OrderDepProcNote: ParamObj.OrderDepProcNote,
        OrderSpeedFlowRate: ParamObj.OrderSpeedFlowRate,
        OrderFlowRateUnit: ParamObj.OrderFlowRateUnit,
        OrderFlowRateUnitRowId: ParamObj.OrderFlowRateUnitRowId,
        DIDExceedReasonDR:ParamObj.DIDExceedReasonDR,
        OrderPilotPro: PageLogicObj.DefaultPilotProDesc,
        OrderPilotProRowid:PageLogicObj.DefaultPilotProRowid,
        OrderPackUOMStr: ParamObj.OrderPackUOMStr,
		OrderBaseQtySum: ParamObj.Qty,
		BaseDoseQty:ParamObj.BaseDoseQty,
		Qty:ParamObj.Qty,
		OrderBodyPartLabel:ParamObj.OrderBodyPartLabel,
		OrderUsableDays:ParamObj.OrderUsableDays,
		//临床路径实施记录
		OrderCPWStepItemRowId:ParamObj.OrderCPWStepItemRowId,
		OrderFirstDayTimes:ParamObj.OrderFirstDayTimes,
		OrderFirstDayTimesStr:ParamObj.OrderFirstDayTimesStr,
		OrderFirstDayTimesCode:ParamObj.OrderFirstDayTimesCode,
		///手术排班及台次
		AnaesthesiaID:ParamObj.AnaesthesiaID,
		OrderOperationStr:ParamObj.OrderOperationStr,
		OrderOperation:ParamObj.OrderOperation,
		OrderOperationCode:ParamObj.OrderOperationCode,
		OrderLocalInfusionQty:ParamObj.OrderLocalInfusionQty,
		ARCIMDefSensitive:ParamObj.ARCIMDefSensitive,
		OrderFreqTimeDoseStr:ParamObj.OrderFreqTimeDoseStr,
		OrderPkgOrderNo:ParamObj.OrderPkgOrderNo,
		OrderDoc:ParamObj.OrderDoc,
		OrderDocRowid:ParamObj.OrderDocRowid,
		OrderDocStr:ParamObj.OrderDocStr,
        OrderVirtualtLong:ParamObj.OrderVirtualtLong,
        OrderChronicDiagStr: ParamObj.OrderChronicDiagStr,
        OrderChronicDiagCode: ParamObj.OrderChronicDiagCode,
        OrderLabSpecCollectionSiteStr: ParamObj.OrderLabSpecCollectionSiteStr,
        OrderSerialNum:ParamObj.OrderSerialNum,
		OrderBindSource:ParamObj.ViewBindSource
    });
    return dataObj;
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
	if (!obj){
		return;
	}
	if ($(obj).hasClass("combobox-f")){
		if (ColumnName == "OrderRecDep") {
            var DefaultRecLocRowid = "";
            var DefaultRecLocDesc = "";
            var ArrData = str.split(String.fromCharCode(2));
			var OrderRecDepData=new Array();
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                if (((ArrData1[2] == "Y") && (DefaultRecLocRowid == "")) || (ArrData.length == 1)) {
                    var DefaultRecLocRowid = ArrData1[0];
                    var DefaultRecLocDesc = ArrData1[1];
                }
				OrderRecDepData.push({id:ArrData1[0],text:ArrData1[1]});
            }
            if (DefaultRecLocRowid=="") {
	            var ArrData1=ArrData[0].split(String.fromCharCode(1));
	            DefaultRecLocRowid=ArrData1[0];
	            DefaultRecLocDesc=ArrData1[1];
	        }
            //SetCellData(rowid, "OrderRecDep", DefaultRecLocRowid);
			$("#"+rowid+"_OrderRecDep").combobox("loadData",OrderRecDepData).combobox("setValue",DefaultRecLocRowid)
            SetCellData(rowid, "OrderRecDepRowid", DefaultRecLocRowid);
            SetCellData(rowid, "CurrentRecLocStr", str);
        }
	}else if (obj.type == "select-one") {
        ClearAllList(obj);
        if (ColumnName == "OrderRecDep") {
            var DefaultRecLocRowid = "";
            var DefaultRecLocDesc = "";
            var ArrData = str.split(String.fromCharCode(2));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                if (((ArrData1[2] == "Y") && (DefaultRecLocRowid == "")) || (ArrData.length == 1)) {
                    var DefaultRecLocRowid = ArrData1[0];
                    var DefaultRecLocDesc = ArrData1[1];
                }
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            if (DefaultRecLocRowid=="") {
	            var ArrData1=ArrData[0].split(String.fromCharCode(1));
	            DefaultRecLocRowid=ArrData1[0];
	            DefaultRecLocDesc=ArrData1[1];
	        }
            SetCellData(rowid, "OrderRecDep", DefaultRecLocRowid);
            SetCellData(rowid, "OrderRecDepRowid", DefaultRecLocRowid);
            SetCellData(rowid, "CurrentRecLocStr", str);
        }
        if (ColumnName == "OrderDoseUOM") {

            var DefaultDoseQty = "";
            var DefaultDoseQtyUOM = ""
            var DefaultDoseUOMRowid = "";
            if (str != "") {

                var ArrData = str.split(String.fromCharCode(2));
                for (var i = 0; i < ArrData.length; i++) {
                    var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                    obj.options[obj.length] = new Option(ArrData1[1], ArrData1[2]);
                    if (i == 0) {
                        var DefaultDoseQty = ArrData1[0];
                        var DefaultDoseQtyUOM = RowidData = ArrData1[1];
                        var DefaultDoseUOMRowid = RowidData = ArrData1[2];
                    }
                }
            }
            SetCellData(rowid, "OrderDoseQty", DefaultDoseQty);
            SetCellData(rowid, "OrderDoseUOM", DefaultDoseUOMRowid);
            SetCellData(rowid, "OrderDoseUOMRowid", DefaultDoseUOMRowid);
            SetCellData(rowid, "idoseqtystr", str);
        }
        if (ColumnName == "OrderLabSpec") {
            var DefaultSpecRowid = "";
            var DefaultSpecDesc = "";
            var ArrData = str.split(String.fromCharCode(2));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(3));
                if ((ArrData1[4] == "Y") || (ArrData.length == 1)) {
                    var DefaultSpecRowid = ArrData1[0];
                    var DefaultSpecDesc = ArrData1[1];
                }
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            SetCellData(rowid, "OrderLabSpec", DefaultSpecRowid);
            SetCellData(rowid, "OrderLabSpecRowid", DefaultSpecRowid);
            SetCellData(rowid, "OrderLabSpecStr", str);
        }
        if ((ColumnName == "OrderDIACat")&&(str !="")) {
            var DefaultDIACatRowId = "";
            var DefaultDIACatDesc = "";
            var ArrData = str.split(String.fromCharCode(2));
            obj.options[obj.length] = new Option("", "");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            SetCellData(rowid, "OrderDIACat", DefaultDIACatRowId);
            SetCellData(rowid, "OrderDIACatRowId", DefaultDIACatRowId);
            SetCellData(rowid, "idiagnoscatstr", str)
        }
        //身体部位
        if (ColumnName == "OrderBodyPart") {
            var ArrData = str.split(String.fromCharCode(2));
            obj.options[obj.length] = new Option("", "");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                obj.options[obj.length] = new Option(ArrData1[2], ArrData1[2]);
            }
        }
        //医嘱类型
        if (ColumnName == "OrderPrior") {
            var ArrData = str.split(";");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(":");
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
        }
        //临床药理
        if (ColumnName == "OrderPilotPro") {
            var DefaultPilotProRowid = "";
            var DefaultPilotProDesc = "";

            var ArrData = str.split(String.fromCharCode(2));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                if (ArrData1[2] == "Y") {
                    var DefaultPilotProRowid = ArrData1[0];
                    var DefaultPilotProDesc = ArrData1[1];
                }
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            if (DefaultPilotProRowid != "") {
                SetCellData(rowid, "OrderPilotProRowid", DefaultPilotProRowid);
                SetCellData(rowid, "OrderPilotPro", DefaultPilotProRowid);
            }
        }
        //手术列表 
         if (ColumnName=="OrderOperation"){
		   if ((str==false)||(str=="")) return;
           var ArrData=str.split("^");
           for (var i=0;i<ArrData.length;i++) {
                var ArrData1=ArrData[i].split(String.fromCharCode(1));
                obj.options[obj.length] = new Option(ArrData1[0],ArrData1[1]);
           }
         }
        //协议单位
        if (ColumnName == "OrderPackUOM") {
            var DefaultOrderPackUOM = "";
            var DefaultOrderPackUOMDesc = "";
            var ArrData = str.split(String.fromCharCode(2));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                if (ArrData1[2] == "Y") {
                    var DefaultOrderPackUOM = ArrData1[0];
                    var DefaultOrderPackUOMDesc = ArrData1[1];
                }
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            if (DefaultOrderPackUOM != "") {

                SetCellData(rowid, "OrderPackUOMRowid", DefaultOrderPackUOM);
                SetCellData(rowid, "OrderPackUOM", DefaultOrderPackUOM);
            }
        }
        //医保分类
        if (ColumnName == "OrderInsurCat") {
            var ArrData = str.split(String.fromCharCode(2));
            //obj.options[obj.length] = new Option("", "");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
        }
        //开医嘱医生
        if (ColumnName == "OrderDoc") {
	        var DefaultDocRowId = "";
            var DefaultDoc = "";
            var ArrData = str.split("^");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                if (ArrData1[2] == "Y") {
                    var DefaultDoc = ArrData1[0];
                    var DefaultDocRowId = ArrData1[1];
                }
                obj.options[obj.length] = new Option(ArrData1[0], ArrData1[1]);
            }
            if (DefaultDocRowId != "") {
                SetCellData(rowid, "OrderDocRowid", DefaultDocRowId);
                SetCellData(rowid, "OrderDoc", DefaultDocRowId);
            }
	    }
	    //医保分类
        if (ColumnName == "OrderChronicDiag") {
            var ArrData = str.split(String.fromCharCode(2));
            //obj.options[obj.length] = new Option("", "");
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
        }
        //标本采集部位
        if (ColumnName == "OrderLabSpecCollectionSite") {
            var DefaultSpecCSiteRowid = "";
            var DefaultSpecCSiteDesc = "";
            var ArrData = str.split(String.fromCharCode(3));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(2));
                if ((ArrData.length == 1)||(i == 0)){
                    var DefaultSpecCSiteRowid = ArrData1[0];
                    var DefaultSpecCSiteDesc = ArrData1[1];
                }
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
            SetCellData(rowid, "OrderLabSpecCollectionSite", DefaultSpecCSiteRowid);
            SetCellData(rowid, "OrderLabSpecCollectionSiteRowid", DefaultSpecCSiteRowid);
            SetCellData(rowid, "OrderLabSpecCollectionSiteStr", str);
        }
        //首日次数
        if (ColumnName == "OrderFirstDayTimesCode") {
            var ArrData = str.split(String.fromCharCode(2));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                obj.options[obj.length] = new Option(ArrData1[1], ArrData1[0]);
            }
        }
    }
}
function GetPrescBillTypeID() {
    //添加影藏 input 存入 PrescBillTypeID
    var obj_PrescBillTypeID = document.getElementById('PrescBillTypeID');
    if (obj_PrescBillTypeID) { return obj_PrescBillTypeID.value; } else { return ""; }
}
function SetOrderFirstDayTimes(rowid) {
	var OrderMasterSeqNo=GetCellData(rowid, "OrderMasterSeqNo");
	if(OrderMasterSeqNo!='') return;
	var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
	var OrderStartDate = GetCellData(rowid, "OrderStartDate");
	var OrderFreqDispTimeStr = GetCellData(rowid, "OrderFreqDispTimeStr");
	var OrderHiddenParaArr = GetCellData(rowid, "OrderHiddenPara").split(String.fromCharCode(1));
	var LinkedMasterOrderPriorRowid="";
	if ((VerifiedOrderObj) && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "undefined") && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "")){
		LinkedMasterOrderPriorRowid=VerifiedOrderObj.LinkedMasterOrderPriorRowid;
	}
	var OrderRecDepRowid=GetCellData(rowid, "OrderRecDepRowid");
	var ret=cspRunServerMethod(GlobalObj.GetOrderFirstDayTimesMethod,GlobalObj.EpisodeID, OrderARCIMRowid, OrderFreqRowid, OrderPriorRowid, OrderStartDate, LinkedMasterOrderPriorRowid,OrderFreqDispTimeStr,session['LOGON.HOSPID'],OrderRecDepRowid);
	var OrderFirstDayTimes=ret.split("^")[0];
	var Editable=ret.split("^")[1];
	var OrderFirstDayTimesStr=ret.split("^")[2];
	SetCellData(rowid,"OrderFirstDayTimesStr",OrderFirstDayTimesStr);
	SetColumnList(rowid,"OrderFirstDayTimesCode",OrderFirstDayTimesStr);
	SetCellData(rowid,"OrderFirstDayTimesCode",OrderFirstDayTimes);
	OrderHiddenParaArr[29]=Editable;	//重置OrderFirstDayTimesEditable
	SetCellData(rowid, "OrderHiddenPara",OrderHiddenParaArr.join(String.fromCharCode(1)))
	if((Editable=='N')||(OrderMasterSeqNo!="")){
		ChangeRowStyle(rowid, {OrderFirstDayTimes:false,OrderFirstDayTimesCode:false});
	}else{
		ChangeRowStyle(rowid, {OrderFirstDayTimes:true,OrderFirstDayTimesCode:true});
	}
}
//医嘱复制
function FindClickHandler(e) {
    if (GlobalObj.EpisodeID) {
        var sttdate = "";
        var enddate = "";
        var prior = "";
        if (GlobalObj.PAAdmType == "I") {
            var CurrDateTime = cspRunServerMethod(GlobalObj.GetCurrentDateTimeMethod, PageLogicObj.defaultDataCache, "1");
            var CurrDateTimeArr = CurrDateTime.split("^");
            sttdate = CurrDateTimeArr[0];
            enddate = CurrDateTimeArr[0];
            var retprior = tkMakeServerCall("web.DHCDocOrderItemList", "GetOrderPrior", "S");
            prior = retprior.split("^")[0];
        } else {
            var retprior = tkMakeServerCall("web.DHCDocOrderItemList", "GetOrderPrior", "NORM");
            prior = retprior.split("^")[0];
        }
        if (GlobalObj.HospitalCode != 'ZJQZRMYY') {
            var posn = "height=" + (screen.availHeight - 40) + ",width=" + (screen.availWidth - 10) + ",top=0,left=0,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes";
        } else {
            var posn = "height=" + (screen.availHeight - 340) + ",width=" + (screen.availWidth - 180) + ",top=0,left=0,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes";
        }
        websys_showModal({
			iconCls:'icon-w-copy',
			url:"doc.ordcopy.hui.csp?EpisodeID=" + GlobalObj.EpisodeID + "&SttDate=" + sttdate + "&EndDate=" + enddate + "&PriorID=" + prior,
			title:'医嘱复制',
			//width:screen.availWidth-50,height:screen.availHeight-200,
            width:"97%",height:screen.availHeight-200,
			AddCopyItemToList:AddCopyItemToList
		});
    }

}
//检验检查申请页
function LnkLabPage_Click() {
    //调用新产品研发组的检验检查申请
    //CloseFlag=1 关闭时调用刷新界面方法
    var SendFlag="";
    var lnk = "dhcapp.mainframe.csp?PatientID=" + GlobalObj.PatientID + "&EpisodeID=" + GlobalObj.EpisodeID + "&mradm=" + GlobalObj.mradm+"&CloseFlag=1&PPRowId="+GlobalObj.PPRowId+"&EmConsultItm="+GlobalObj.EmConsultItm;
    websys_showModal({
		url:lnk,
		title:'检验检查申请',
		iconCls:'icon-w-paper',
		width:'95%',height:'100%',
		CallBackFunc:function(rtn){
			SendFlag=rtn;
		},
		onClose:function(){
			if (SendFlag=="1"){
				ReloadGrid("Ord");
				SaveOrderToEMR();
			}
		}
	})   
}
//提供给检查选择窗口回调函数
function PACSArcimFun(itemArr,OrdParamsArr) {
	websys_showModal("close");
	if (GlobalObj.warning != "") {
        $.messager.alert("警告",GlobalObj.warning);
        return false;
    }
    var str=itemArr;
    if (str == '') return;
    if (typeof str == 'undefined') return;
    if (typeof str != 'string') return;
    if (str.indexOf("||")<0) {
	    var Arr = str.split('^')[0].split(String.fromCharCode(1))
		var icode = Arr[0];
		var itext = Arr[1];
	    OSItemListOpen(icode, itext, "YES", "", "");
	    return;
	}
	var OrdParamsArr=new Array();
    var strArray = str.split('^');
    var AddSuss = "N"
	new Promise(function(resolve,rejected){
		(function(callBackFun){
			function loop(i){
				new Promise(function(resolve,rejected){
					var Arr = strArray[i].split(String.fromCharCode(1))
					var icode = Arr[0];
					GetItemDefaultRowId(icode,resolve);
				}).then(function(ItemDefaultRowId){
					var OrderLabSpecRowid = "";
					var Arr = strArray[i].split(String.fromCharCode(1))
					var icode = Arr[0];
					if (Arr.length == 2) OrderLabSpecRowid = Arr[1];
					OrdParamsArr[OrdParamsArr.length]={
						OrderARCIMRowid:icode,
						ItemDefaultRowId:ItemDefaultRowId
					};
					i++;
					if ( i < strArray.length ) {
						 loop(i);
					}else{
						callBackFun();
					}
				})
				
			}
			loop(0);
		})(resolve);
	}).then(function(){
		return new Promise(function(resolve,rejected){
			AddItemToList("",OrdParamsArr,"obj","",resolve);
		})
	}).then(function(RtnObj){
		if (RtnObj.returnValue==false){
			var rowids = $('#Order_DataGrid').getDataIDs();
	        if (rowids.length == 0) Add_Order_row();
		}else{
			XHZY_Click();
			SetScreenSum();
		}
	})
}
//查看，模糊查询医嘱项目
function BtnViewArcItemInfoHandler() {
    var iWidth=1200;                          //弹出窗口的宽度; 
    var iHeight=680;                         //弹出窗口的高度; 
    //获得窗口的垂直位置 
    var iTop = (window.screen.availHeight - 30 - iHeight) / 2; 
    //获得窗口的水平位置 
    var iLeft = (window.screen.availWidth - 10 - iWidth) / 2; 
    var lnk = "doc.arcimquery.hui.csp";
	websys_showModal({
		iconCls:'icon-w-find',
		url:lnk,
		title:'医嘱字典查询',
		//width:screen.availWidth-200,height:screen.availHeight-200,
		width:"97%",height:screen.availHeight-200,
        PACSArcimFun:PACSArcimFun,
		OSItemListOpen:OSItemListOpen
	});
}
//诊间预约
function DoctorAppoint_Click() {
	websys_showModal({
		url:"dhcdoc.appointment.hui.csp?PatientID="+GlobalObj.PatientID+"&EpisodeID="+GlobalObj.EpisodeID, //"dhcdoc.appointment.app.hui.csp?AppMethCodeStr=DOC&PatientID="+GlobalObj.PatientID,
		title:'诊间预约',
		iconCls:'icon-w-edit',
		//width:screen.availWidth-50,height:screen.availHeight-100
        width:"97%",height:screen.availHeight-100
	});
}
//卡消费
function CardBillClick() {
    var EpisodeID = GlobalObj.EpisodeID;
    var PatientID = GlobalObj.PatientID;
    if (EpisodeID == "") { $.messager.alert("提示", "缺少患者信息!"); return; }
    DHCACC_GetCardBillInfo(PatientID,function(CardInfo){
		var CardNo=CardInfo.split("^")[0];
		var CardTypeRowId=CardInfo.split("^")[1];
		if (CardNo==""){
			$.messager.alert("提示", "无效的卡信息!"); return; 
		}
		if (GlobalObj.CheckOutMode == 1) {
		    $.messager.confirm('提示', '是否确认扣费?', function(r){
				if (r){
					var CardTypeDefine = tkMakeServerCall("web.UDHCOPOtherLB","ReadCardTypeDefineListBroker1",CardTypeRowId);
					$("#CardBillCardTypeValue").val(CardTypeDefine);
				    var insType = GetPrescBillTypeID();
			        var oeoriIDStr = "";
			        var guser = session['LOGON.USERID'];
			        var groupDR = session['LOGON.GROUPID'];
			        var locDR = session['LOGON.CTLOCID'];
			        var hospDR = session['LOGON.HOSPID'];
			        var rtn = checkOut(CardNo, PatientID, EpisodeID, insType, oeoriIDStr, guser, groupDR, locDR, hospDR,CardBillAfterReload);
			        //CardBillAfterReload();
				}
			});
	    }else{
		 	var url = "dhcbill.opbill.charge.main.csp?ReloadFlag=3&CardNo=" + CardNo + "&SelectAdmRowId=" +  GlobalObj.EpisodeID + "&SelectPatRowId=" + GlobalObj.PatientID + "&CardTypeRowId=" + CardTypeRowId;
			websys_showModal({
				url: url,
				title: '预扣费',
				iconCls: 'icon-w-inv',
				width: '100%',
				height: '85%',
				onClose: function() {
					CardBillAfterReload();
				}
			});
		}
	});
    return;
}
function CardBillAfterReload(){
    ReloadGrid("Bill");
    if (GlobalObj.PAAdmType!="I"){
	    if (parent.refreshBar){
        	parent.refreshBar();
        }else if(parent.parent.refreshBar){
	        parent.parent.refreshBar();
	    }else{
        	parent.parent.opdoc.patinfobar.view.InitPatInfo(GlobalObj.EpisodeID);
        }
    }
}
function CASignUpdate(BtnId) {
    var caIsPass = 0;
    var ContainerName = "";
    if (GlobalObj.CAInit == 1) {
        if (GlobalObj.IsCAWin == "") {
            $.messager.alert("警告", "请先插入KEY!","info",function(){
	            DisableBtn(BtnId,false);
	        });
            return false;
        }
        //判断当前key是否是登陆时候的key
        var resultObj = dhcsys_getcacert();
        result = resultObj.ContainerName;
        if ((result == "") || (result == "undefined") || (result == null)) {
           DisableBtn(BtnId,false);
            return false;
        }
        ContainerName = result;
        caIsPass = 1;
    }
    return { caIsPass: caIsPass, ContainerName: ContainerName }
}
function CheckBeforeSaveToServer(OrderItemStr,callBackFun) {
    var UserAddRowid = session['LOGON.USERID'];
    var UserAddDepRowid = session['LOGON.CTLOCID'];
    var DoctorRowid = GetEntryDoctorId();
    var LogonDep = ""
    var obj = document.getElementById("FindByLogDep");
    if (obj) {
        if (obj.checked) { FindRecLocByLogonLoc = 1 } else { FindRecLocByLogonLoc = 0 }
    }
    if (FindRecLocByLogonLoc == "1") { LogonDep = session['LOGON.CTLOCID'] }
    var OrderOpenForAllHosp = $("#OrderOpenForAllHosp").val();
    var ExpStr = GlobalObj.PPRowId +"^"+LogonDep+"^"+OrderOpenForAllHosp;
    
    var ret = cspRunServerMethod(GlobalObj.CheckBeforeSaveMethod, GlobalObj.EpisodeID, OrderItemStr, UserAddRowid, UserAddDepRowid, DoctorRowid, ExpStr,1)
    var CheckResultObj=jQuery.parseJSON(ret);
    
	/*var ErrCode=CheckResultObj.ErrCode; //1
	var ErrMsg=CheckResultObj.ErrMsg;	//2
    var ErrRowID=CheckResultObj.OrdRowIndex;	//3
    var FocusCol=CheckResultObj.FocusCol;//4
    var NeedCheckDeposit=CheckResultObj.NeedCheckDeposit;//4*/
	var CheckBeforeSaveObj={
		StopConflictFlag:"0",			//是否需要自动停止互斥医嘱
		isAfterCheckLoadDataFlag:false,	//前台是否需要重载数据
		SuccessFlag:true,				//是否需要继续审核医嘱
		UpdateOrderItemStr:OrderItemStr
	}
	new Promise(function(resolve,rejected){
		//执行回调方法
		var CallBakFunS=CheckResultObj.CallBakFunS;
		if (typeof CallBakFunS=="object"){
			(function(callBackExecFun){
				function loop(i){
					new Promise(function(resolve,rejected){
						var FunCode=CallBakFunS[i].CallBakFunCode;
						var FunCodeParams=CallBakFunS[i].CallBakFunParams;
						//tanjishan 2022年10月12日
						//callback的行为与ErrCode的行为可能不一致，有时只是界面操作(通过CallBakFunOrdRowIndex)，有时需要拦截(通过SetPageLogicFocusRow等)
						//这里推荐使用CallBakFunOrdRowIndex,尽量与ErrCode的功能区分开
						if (CallBakFunS[i].CallBakFunOrdRowIndex && $.isNumeric(CallBakFunS[i].CallBakFunOrdRowIndex)){
							var Row=CallBakFunS[i].CallBakFunOrdRowIndex;
						}else{
							var Row=CheckResultObj.ErrCode;
						}
						CheckAfterCheckMethod(FunCode,FunCodeParams,Row,resolve);
					}).then(function(ReturnObj){
						if (ReturnObj.isAfterCheckLoadDataFlag){
							CheckBeforeSaveObj.isAfterCheckLoadDataFlag=true;
						}
						if (ReturnObj.SuccessFlag==false){
							CheckBeforeSaveObj.SuccessFlag=false;
							callBackExecFun();
							return;
						}
						if (ReturnObj.StopConflictFlag=="1"){
							CheckBeforeSaveObj.StopConflictFlag="1";
							callBackExecFun();
							return;
						}
						if ((ReturnObj.LongOrdStopDateTimeStr!="")||(ReturnObj.TransType)) {
							var UpdateOrderItemStr="";
							var LongOrdStopDateTimeArr=ReturnObj.LongOrdStopDateTimeStr.split(" ");
							var updateIndex=CallBakFunS[i].CallBakFunParams.split(",")[0];
							var OrderItemAry=OrderItemStr.split(String.fromCharCode(1));
				            for (var itemIndex=0;itemIndex<OrderItemAry.length;itemIndex++) {
				                var oneOrderItemAry=OrderItemAry[itemIndex].split('^');
				                if (oneOrderItemAry[65]==updateIndex) {
									if(ReturnObj.LongOrdStopDateTimeStr!=""){
										oneOrderItemAry[3]=LongOrdStopDateTimeArr[0];
										oneOrderItemAry[4]=LongOrdStopDateTimeArr[1];
									}
									if(ReturnObj.TransType){
										oneOrderItemAry[93]=ReturnObj.TransType;
									}
					            }
				                var oneOrderItemStr=oneOrderItemAry.join('^');
				                if (UpdateOrderItemStr=="") {UpdateOrderItemStr=oneOrderItemStr;}else{UpdateOrderItemStr=UpdateOrderItemStr+String.fromCharCode(1)+oneOrderItemStr}
				            }
				            $.extend(CheckBeforeSaveObj, { UpdateOrderItemStr: UpdateOrderItemStr});
						}
						i++;
						if ( i < CheckResultObj.CallBakFunS.length ) {
							 loop(i);
						}else{
							callBackExecFun();
						}
					})
				}
				loop(0);
			})(resolve);
		}else{
			resolve();
		}
	}).then(function(){
		return new Promise(function(resolve,rejected){
			var ErrMsg=CheckResultObj.ErrMsg;
			var ErrRowID=CheckResultObj.OrdRowIndex;
			var FocusCol=CheckResultObj.FocusCol;
			if (ErrMsg!=""){
				$.messager.alert("提示", ErrMsg, "info", function() {
					if ((ErrRowID!="")&&(FocusCol!="")){
						//EditRow 里有调用合理用药程序,增加容错处理
						try{
							var rowidArr=GetOrderSeqArr(ErrRowID);
							for(var key in rowidArr){
								EditRow(rowidArr[key]);
							}
							SetFocusCell(ErrRowID, FocusCol);
							if (FocusCol == "OrderDoseQty") {
								$("#"+ErrRowID+"_OrderDoseQty").click();
							}
						}catch(e){
							SetFocusCell(ErrRowID, FocusCol);
						}
					}
					resolve();
				})
		    }else{
			    resolve();
			}
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			var ErrCode=CheckResultObj.ErrCode;
			if ((parseInt(ErrCode)<0)){
				CheckBeforeSaveObj.SuccessFlag=false;
			}
			if (CheckResultObj.NeedCheckDeposit) {
		        var amount = $("#ScreenBillSum").val();
		        if (!CheckDeposit(amount, "")) {
		            CheckBeforeSaveObj.SuccessFlag=false;
		        }
		    }
		    resolve();
	    })
	}).then(function(){
		callBackFun(CheckBeforeSaveObj);
	})
}
function CheckAfterCheckMethod(FunCode,FunCodeParams,Row,CallBackFun){
	var ReturnObj={
		StopConflictFlag:"0",
		isAfterCheckLoadDataFlag:false,
		LongOrdStopDateTimeStr:"",
		SuccessFlag:true,
	}
	var ParamsArr=FunCodeParams.split(",");
	new Promise(function(resolve,rejected){
		switch(FunCode)
		{
			case "NeedDischgCond":
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						OpenDischgCond(FunCodeParams,resolve);
					}).then(function(returnObj){
						//ReturnObj.SuccessFlag=SuccessFlag;
						$.extend(ReturnObj, returnObj);
						callBackFunExec();
					})
				})(resolve);
				break;
			case "NeedDeathDate":
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						OpenDeathDate(FunCodeParams,resolve);
					}).then(function(returnObj){
						//ReturnObj.SuccessFlag=SuccessFlag;
						$.extend(ReturnObj, returnObj);
						callBackFunExec();
					})
				})(resolve);
				break;
			case "NeedTransDate":
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						OpenStopAfterLongOrder("转科医嘱开始日期","NeedTransDate",FunCodeParams,resolve);
					}).then(function(returnObj){
						//ReturnObj.SuccessFlag=SuccessFlag;
						$.extend(ReturnObj, returnObj);
						callBackFunExec();
					})
				})(resolve);
				break;
			case "NeedDischgDiagnos":
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						OpenDischgDiagnos(ParamsArr,resolve);
					}).then(function(SuccessFlag){
						ReturnObj.SuccessFlag=SuccessFlag;
						callBackFunExec();
					})
				})(resolve);
				break;
			case "NeedDiagnose":
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						OpenDiagnose(ParamsArr,resolve);
					}).then(function(SuccessFlag){
						ReturnObj.SuccessFlag=SuccessFlag;
						callBackFunExec();
					})
				})(resolve);
				break;
			case"SetPageLogicFocusRow": 
				PageLogicObj.FocusRowIndex = Row;
				resolve();
				break;
			case "Confirm" :
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						$.messager.confirm('确认对话框', FunCodeParams, function(r){
							if (r) {
								ReturnObj.SuccessFlag=true;
							}else{
								ReturnObj.SuccessFlag=false;
							}
							callBackFunExec();
						});
					})
				})(resolve); //此处的resolve指的是CheckAfterCheckObj.CallBackFun(FunObj.ReturnObj);
				break;
			case "ReSetMasterSeqNo" :
				SetCellData(Row, "OrderMasterSeqNo", "");
				ReturnObj.isAfterCheckLoadDataFlag=true;
				resolve();
				break;
			case "AddRemarkClickhandler" :
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						AddRemarkClickhandler(ParamsArr[0],resolve);
					}).then(function(SuccessFlag){
						ReturnObj.SuccessFlag=SuccessFlag;
						ReturnObj.isAfterCheckLoadDataFlag=true;
						callBackFunExec();
					})
				})(resolve);
				break;
			case "NeedInputOrderPrice" :
				EditRow(Row);
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						$.messager.alert('提示信息', OrderName + t['NO_OrderPrice'], "info",function(){
							SetFocusCell(Row, "OrderPrice");
							var StyleConfigObj = { OrderPrice: true };
				            ChangeRowStyle(Row, StyleConfigObj)
				            PageLogicObj.FocusRowIndex = Row;
				            ReturnObj.SuccessFlag=false;
							callBackFunExec();
						});
					})
				})(resolve); //此处的resolve指的是CheckAfterCheckObj.CallBackFun(FunObj.ReturnObj);
				break;
			case "EmptyPackQty" :
				SetCellData(Row, "OrderPackQty", "");
	            ReturnObj.SuccessFlag=true;
	            resolve();
				break;
			case "StopConflict" :
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						/*$.messager.confirm('确认对话框', "存在以下互斥医嘱：" + ParamsArr + " 请确认是否自动停止互斥医嘱?", function(r){
							if (r) {
								ReturnObj.StopConflictFlag = "1";
							}
							callBackFunExec();
						});*/
						$.messager.alert('提示信息', "存在以下互斥医嘱：" + ParamsArr + " 审核后将自动停止互斥医嘱！", "info",function(){
							ReturnObj.StopConflictFlag = "1";
							callBackFunExec();
						});
					})
				})(resolve);
				break;
			case "ExceedReasonConfirm" :
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						$.messager.confirm('确认对话框', ParamsArr.slice(0, ParamsArr.length-3), function(r){
							Row=ParamsArr[ParamsArr.length-3];
							if (r) {
								ReturnObj.SuccessFlag = true;
								var LastExceedReasonID=ParamsArr[ParamsArr.length-2];
								var LastExceedReason=ParamsArr[ParamsArr.length-1];
								SetCellData(Row, "ExceedReasonID", LastExceedReasonID);
								SetCellData(Row, "ExceedReason", LastExceedReason);
								ChangeLinkOrderExceedReason(Row);
								ReturnObj.isAfterCheckLoadDataFlag=true;	
							}else{
								ReturnObj.SuccessFlag = false;
								PageLogicObj.FocusRowIndex = Row;
								EditRow(Row);
								SetFocusCell(Row, "ExceedReason");
							}
							callBackFunExec();
						});
					})
				})(resolve);
				break;
			case "NeedCareOrd":
				(function(callBackFunExec){
					var TypeCode=ParamsArr[ParamsArr.length-1];
					new Promise(function(resolve,rejected){
						$.messager.confirm('确认对话框', ParamsArr.slice(0, ParamsArr.length-1), function(r){
							ReturnObj.SuccessFlag=true;
							if (r) {
								var url="../csp/nur.hisui.orderNeedCare.csp?EpisodeID="+GlobalObj.EpisodeID+"&defaultTypeCode="+TypeCode;
								websys_showModal({
									iconCls:'icon-w-list',
									url:url,
									title:'需关注医嘱',
									width:'99%',height:'85%',
									onClose:function(retval){
										callBackFunExec();
									}
								})
							}else{
								callBackFunExec();
							}
						});
					})
				})(resolve);
				break;
			case "NeedFirstDelWithCareOrd":
				var TypeCode=ParamsArr[ParamsArr.length-1];
				(function(callBackFunExec){
					$.messager.alert("提示",ParamsArr.slice(0, ParamsArr.length-1),"info",function(){
						var url="../csp/nur.hisui.orderNeedCare.csp?EpisodeID="+GlobalObj.EpisodeID+"&defaultTypeCode="+TypeCode;
						websys_showModal({
							iconCls:'icon-w-list',
							url:url,
							title:'需关注医嘱',
							width:'97%',height:'85%',
							onClose:function(retval){
								//var Rtn=tkMakeServerCall("Nur.HISUI.NeedCareOrder", "getAbnormalOrder", GlobalObj.EpisodeID,GlobalObj.LogonDoctorType,TypeCode);
							    //var Rtn=tkMakeServerCall("Nur.Interface.OutSide.Order", "GetAbnormalOrder", GlobalObj.EpisodeID,GlobalObj.LogonDoctorType,TypeCode);
								var Rtn=tkMakeServerCall("web.DHCOEOrdItem", "GetAbnormalOrder", GlobalObj.EpisodeID,session['LOGON.USERID'],TypeCode);
							    if ((Rtn!="")&&(mPiece(Rtn,"^",2)=="Y")) ReturnObj.SuccessFlag=false;
							    else ReturnObj.SuccessFlag=true;
							    callBackFunExec();
							}
						})
					})
				})(resolve);	
				break;
			case "NeedDeathTypeDiagnos":
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						$.messager.alert("提示",ParamsArr,"info",function(){
							new Promise(function(resolve,rejected){
								OpenDeathTypeDiagnos(resolve);
							}).then(function(SuccessFlag){
								ReturnObj.SuccessFlag=SuccessFlag;
								callBackFunExec();
							})
						});
					})
				})(resolve); //此处的resolve指的是FunObj.CallBackFun(FunObj.ReturnObj);
				break;
			case "CheckPatCount":
				ReturnObj.SuccessFlag=true;
				resolve();
				break;
			case "Alert":
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						$.messager.alert("提示",ParamsArr,"info",function(){
							ReturnObj.SuccessFlag=true;
							callBackFunExec();
						});
					})
				})(resolve); //此处的resolve指的是CallBackFun(ReturnObj);
				break;
			case "ReSetPackQty" :
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						if ($.messager){
							$.messager.defaults.ok = '是';
							$.messager.defaults.cancel = '否';
						} 
						$.messager.confirm('提示信息', ParamsArr[0],function(r){
							if (r) {
								if ($.messager){
									$.messager.defaults.ok = '确认';
									$.messager.defaults.cancel = '取消';
								}
								SetCellData(Row, "OrderPackQty", ParamsArr[1]);
								SetCellData(Row, "OrderSum", ParamsArr[2]);
								ReturnObj.isAfterCheckLoadDataFlag=true;    
							}
							ReturnObj.SuccessFlag=true;
							callBackFunExec();
						});
					})
				})(resolve);
				break;
			case "SetTransType":
				(function(callBackFunExec){
					var TransType=ParamsArr[1];
					if(TransType.indexOf("|")>-1){
						var defOk=$.messager.defaults.ok;
						var defCancel=$.messager.defaults.cancel;
						$.messager.defaults.ok='转科室';
						$.messager.defaults.cancel='转病区';
						$.messager.confirm('提示信息', '请确认患者转科室还是转病区?',function(r){
							ReturnObj.SuccessFlag=true;
							ReturnObj.TransType=r?TransType.split("|")[0]:TransType.split("|")[1];
							callBackFunExec();
						});
						$.messager.defaults.ok=defOk;
						$.messager.defaults.cancel=defCancel;
					}else{
						ReturnObj.SuccessFlag=true;
						ReturnObj.TransType=TransType;
						callBackFunExec();
					}
				})(resolve);
				break
			case 'SpecDiagForm':
				///关联转科表单填写界面
				var SerialNum=ParamsArr[0];
				var SpecLocDiagCatCode=ParamsArr[1];
				var SpecLocDiagCatName=ParamsArr[2];
				var ArcimDesc=ParamsArr[3];
				ShowSpecDiagForm(function(SuccessFlag){
					ReturnObj.SuccessFlag=SuccessFlag;
					resolve();
				},SerialNum,SpecLocDiagCatCode,SpecLocDiagCatName,ArcimDesc);
				break;
			default:
				resolve();
				break;
		}
	}).then(function(){
		CallBackFun(ReturnObj);
	})
}
function OpenDiagnose(ParamsArr,CallBackFun){
	$.messager.alert("提示", ParamsArr[0],"info",function(){
	    var DiagnosURL = "diagnosentry.v8.csp?PatientID=" + GlobalObj.PatientID + "&EpisodeID=" + GlobalObj.EpisodeID + "&mradm=" + GlobalObj.mradm +"&OutDisFlag=1";
	    websys_showModal({
			url:DiagnosURL,
			title:'诊断录入',
			//width:websys_getTop().screen.width - 100,height:websys_getTop().screen.height - 130,
			width:"95%",height:websys_getTop().screen.height - 130,
            invokeChartFun:parent.invokeChartFun||parent.parent.invokeChartFun,
			onClose:function(){
				if (ParamsArr[ParamsArr.length-1] == 1){
				    var Ret = tkMakeServerCall("web.DHCDocOrderEntry", "GetMMDiagnoseCount", GlobalObj.mradm);
				}else{
			    	var Ret = tkMakeServerCall("web.DHCDocOrderEntry", "GetMRDiagnoseCount", GlobalObj.mradm);
				}
	            if (Ret == 0) { Ret = false; } else { Ret = true; }
				CallBackFun(Ret);
			}
		})
	});
}
function OpenDischgDiagnos(ParamsArr,CallBackFun){
    var iframeName = window.name
    if (iframeName == "") {
        iframeName = window.parent.frames["oeordFrame"]?window.parent.frames["oeordFrame"].name:'';
    }
	var defMainDiagFlag="";
	if (ParamsArr.length>1){
		defMainDiagFlag=ParamsArr[1];
	}
    if (iframeName == "oeordFrame") {
	    CallBackFun(false);
    } else {
        if (GlobalObj.CareProvType == "DOCTOR") {
	        $.messager.alert("提示", ParamsArr[0],"info",function(){
			    var DiagnosURL = "diagnosentry.v8.csp?PatientID=" + GlobalObj.PatientID + "&EpisodeID=" + GlobalObj.EpisodeID + "&mradm=" + GlobalObj.mradm +"&OutDisFlag=1&defMainDiagFlag="+defMainDiagFlag;
			    websys_showModal({
					url:DiagnosURL,
					title:'诊断录入',
					//width:websys_getTop().screen.width - 100,height:websys_getTop().screen.height - 130,
					width:"95%",height:websys_getTop().screen.height - 130,
                    onClose:function(){
						var checkNeedDiagTypeRtn=tkMakeServerCall("web.DHCOEOrdItem", "checkNeedDiagType", GlobalObj.EpisodeID,session['LOGON.USERID'],ParamsArr[2],ParamsArr[3]);
			            if (+checkNeedDiagTypeRtn!=0){
			                CallBackFun(false);
			            }else{
			                CallBackFun(true);
			            }
					}
				})
			});
        }else{
	        CallBackFun(true);
	    }
    }
}
function OpenStopAfterLongOrder(title,type,rowIndex,CallBackFun){
	var rowid=(+rowIndex)-1;
	var oneOrdItemArr=[];
	var DataArry = GetGirdData(true);
	var OrderARCIMRowid = DataArry[rowid]["OrderARCIMRowid"];
	var OrderPriorRowid = DataArry[rowid]["OrderPriorRowid"];
	var OrderPriorRemarks = DataArry[rowid]["OrderPriorRemarksRowId"];
	OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
	var OrderStartDateStr = DataArry[rowid]["OrderStartDate"];
	var OrderStartDate = "";
    var OrderStartTime = "";
    if (OrderStartDateStr != "") {
        OrderStartDate = OrderStartDateStr.split(" ")[0];
        OrderStartTime = OrderStartDateStr.split(" ")[1];
    }
	var OrderEndDateStr = DataArry[rowid]["OrderEndDate"];
	var OrderEndDate = "";
    var OrderEndTime = "";
    if (OrderEndDateStr != "") {
        OrderEndDate = OrderEndDateStr.split(" ")[0];
        OrderEndTime = OrderEndDateStr.split(" ")[1];
    }
    var VerifiedOrderMasterRowid="";
    var OrderDate ="",OrderTime = "";
    var OrderDateStr = DataArry[rowid]["OrderDate"];
    if (OrderDateStr != "") {
        OrderDate = OrderDateStr.split(" ")[0];
        OrderTime = OrderDateStr.split(" ")[1];
    }
    var VerifiedOrderMasterRowid="",OrderNurseLinkOrderRowid="",OrderNurseBatchAdd="";
    oneOrdItemArr[0]=OrderARCIMRowid;
    oneOrdItemArr[2]=OrderPriorRowid;
    oneOrdItemArr[3]=OrderStartDate;
    oneOrdItemArr[4]=OrderStartTime;
    oneOrdItemArr[25]=OrderEndDate;
    oneOrdItemArr[26]=OrderEndTime;
    oneOrdItemArr[38]=VerifiedOrderMasterRowid;
    oneOrdItemArr[45]=OrderDate;
    oneOrdItemArr[46]=OrderTime;
    oneOrdItemArr[62]=OrderNurseLinkOrderRowid;
    oneOrdItemArr[70]=OrderNurseBatchAdd;
    var StyleConfigStr = DataArry[rowid]["StyleConfigStr"];
	var StyleConfigObj = {};
	if (StyleConfigStr != "") {
		StyleConfigObj = eval("(" + StyleConfigStr + ")");
	}
	if ((type=="NeedTransDate")&&(!StyleConfigObj.OrderStartDate)) {
		var returnObj={
			SuccessFlag:true,
			LongOrdStopDateTimeStr:""
		}
		$.messager.confirm('确认对话框', DataArry[rowid]["OrderName"]+" 将把所有长嘱停止至"+OrderStartDate+" "+OrderStartTime+",是否继续?", function(r){
			if (!r){
				returnObj.SuccessFlag=false;
			}
			CallBackFun(returnObj);
		})
		return;
	}
    var paraObj={
	    OrdItemArr:oneOrdItemArr,
	    EpisodeID:GlobalObj.EpisodeID,
	    StartDateEnbale: StyleConfigObj.OrderStartDate
	}
	websys_showModal({
		iconCls:'icon-w-edit',
		url:"../csp/dhcdoc.stopafterlongordcondition.csp?type="+type,
		title:title,
		width:400,height:310,
		paraObj:paraObj,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			var returnObj={
				SuccessFlag:false,
				LongOrdStopDateTimeStr:""
			}
			if ((result == "") || (result == "undefined")||(result == null)) {
			    CallBackFun(returnObj);
		    } else {
			    var resultArr=result.split("^");
			    if (type == "NeedDischgCond") {
		        	GlobalObj.DischargeConditionRowId = resultArr[0].split('!')[0];
					GlobalObj.DischargeMethodID=resultArr[0].split('!')[1]||'';
		        }else if (type == "NeedDeathDate"){
			        GlobalObj.DeceasedDateTimeStr = resultArr[0];
					GlobalObj.DischargeConditionRowId="";
					GlobalObj.DischargeMethodID="";
			    }
			    $.extend(returnObj, { SuccessFlag: true,LongOrdStopDateTimeStr:resultArr[1]});
		        CallBackFun(returnObj);
		    }
		}
	})
}
function OpenDischgCond(rowIndex,CallBackFun){
	OpenStopAfterLongOrder("请选择出院条件","NeedDischgCond",rowIndex,CallBackFun);
	/*websys_showModal({
		url:"../csp/dhcdoc.dischargecondition.csp",
		title:'请选择出院条件',
		width:400,height:330,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			if ((result == "") || (result == "undefined")||(result == null)) {
		        $.messager.alert("提示", "请选择出院条件!","info",function(){
			        CallBackFun(false);
			    });
		    } else {
		        GlobalObj.DischargeConditionRowId = result;
		        CallBackFun(true);
		    }
		}
	})*/
}
function OpenDeathDate(rowIndex,CallBackFun){
	OpenStopAfterLongOrder("请填写死亡日期","NeedDeathDate",rowIndex,CallBackFun);
	/*websys_showModal({
		url:"../csp/dhcdoc.deathdatetime.csp",
		title:'请填写死亡日期',
		width:400,height:300,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			if ((result == "") || (result == "undefined")||(result == null)) {
		        $.messager.alert("提示", "请填写死亡日期和时间!","info",function(){
			        CallBackFun(false);
			    });
		    } else {
		        GlobalObj.DeceasedDateTimeStr = result;
				GlobalObj.DischargeConditionRowId="";
		        CallBackFun(true);
		    }
		}
	})*/
}
function UpdateClickHandler(UpdateObj){
	 SetTimeLog("UpdateClickHandler", "start");
	 if ($("#Insert_Order_btn").hasClass('l-btn-disabled')){
		return false;
	 }
	 $("#itro_win").hide().remove();
	 if (typeof UpdateObj=="undefined"){
		 UpdateObj={};
     }
	 $.extend(UpdateObj, { SUCCESS: false});
	 DisableBtn("Insert_Order_btn",true);
     //医保用药控制
     //if (!CheckInsuCostControl()){
        //return false
     //}
	new Promise(function(resolve,rejected){
		//检查医嘱锁
		var SessionStr=GetSessionStr();
		var InputObj={
			orderRow:GlobalObj.orderrow,
			EpisodeID:GlobalObj.EpisodeID,
			EmConsultItm:GlobalObj.EmConsultItm,
			SessionStr:SessionStr
		}
		Common_ControlObj.BeforeUpdate("checkOrderLock",InputObj,resolve);
	}).then(function(ret){
		return new Promise(function(resolve,rejected){
	    	if (!ret) {
		    	UpdateClickHandlerFinish();
	    		return websys_cancel();
	    	}
		    //电子签名
			var CAInputObj={
				callType:"OrderSave",
				isHeaderMenuOpen:true
			}
			Common_ControlObj.BeforeUpdate("CASignCheck",CAInputObj,resolve);
		})
	}).then(function(RtnObj){
		return new Promise(function(resolve,rejected){
	    	if (RtnObj.PassFlag == false || RtnObj == false) {
		    	UpdateClickHandlerFinish();
	    		return websys_cancel();
	    	}
	    	
	    	$.extend(UpdateObj, RtnObj.CAObj);
			var ret = CheckBeforeUpdate();
			if (ret == false) {
				UpdateClickHandlerFinish();
				return websys_cancel();
			}else{
				resolve();	
			}
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			GetOrderDataOnAdd(resolve);
		})
	}).then(function(OrderItemStr){
		return new Promise(function(resolve,rejected){
			if (OrderItemStr === "") {
			    $.messager.alert("提示", t['NO_NewOrders'],"info",function(){
				    UpdateClickHandlerFinish();
				});
			    return websys_cancel();
		    }
			if (OrderItemStr==false) {
				UpdateClickHandlerFinish();
				return websys_cancel();
			}
		    $.extend(UpdateObj, { OrderItemStr: OrderItemStr});
			//保存前的后台审核,对于医嘱录入非必须前端处理的判断逻辑可以在此处理
			CheckBeforeSaveToServer(UpdateObj.OrderItemStr,resolve);
		})
	}).then(function(ret){
		 return new Promise(function(resolve,rejected){
			if (ret.SuccessFlag == false) {
				UpdateClickHandlerFinish();
				return websys_cancel();
			}
			$.extend(UpdateObj, { StopConflictFlag: ret.StopConflictFlag,OrderItemStr:ret.UpdateOrderItemStr});
			if (ret.isAfterCheckLoadDataFlag== true){
				(function(callBackFunExec){
					new Promise(function(resolve,rejected){
						GetOrderDataOnAdd(resolve);
					}).then(function(OrderItemStr){
						if (OrderItemStr==false) {
							UpdateClickHandlerFinish();
							return websys_cancel();
						}
						if (OrderItemStr == "") {
							$.messager.alert("提示", t['NO_NewOrders'],"info",function(){
								UpdateClickHandlerFinish();
							});
							return websys_cancel();
						}
						$.extend(UpdateObj, { OrderItemStr: OrderItemStr});
						callBackFunExec();
					})
				})(resolve)
			}else{
				resolve();
			}
		 })
	}).then(function(){
		return new Promise(function(resolve,rejected){
			/*if (GlobalObj.HLYYInterface==1){
				GlobalObj.DHCHLYYInfo="";
				var HLYYInputObj={
					OrderItemStr:UpdateObj.OrderItemStr,
					Type:"Check"
				}
				Common_ControlObj.BeforeUpdate("HYLLUpdateCheck",HLYYInputObj,resolve);
			}else{
				resolve(true);
			}*/
			//统一第三方接口调用,参照医生站配置->外部接口测试->对外接口接入管理下的关联开启数据
			var myInputObj={
				EpisodeID:GlobalObj.EpisodeID,
				PAAdmType:GlobalObj.PAAdmType,
				OrderItemStr:UpdateObj.OrderItemStr,
				CallBackFunc:resolve
			}
			Common_ControlObj.BeforeUpdate("Interface",myInputObj,resolve);
		})
	}).then(function(ret){
		return new Promise(function(resolve,rejected){
			if (ret==false || ret.SuccessFlag==false) {
				UpdateClickHandlerFinish();
				return websys_cancel();
			}else{
				if(ret.UpdateFlag){
					$.extend(UpdateObj, { OrderItemStr: ret.UpdateOrderItemStr});	
				}
			}
			var CDSSInputObj={
				OrderItemStr:UpdateObj.OrderItemStr,
				EpisodeID:GlobalObj.EpisodeID
			}
			//CDSS事前预警
			Common_ControlObj.BeforeUpdate("CDSSCheck",CDSSInputObj,resolve);
		})
	}).then(function(ret){
		return new Promise(function(resolve,rejected){
			if (!ret) {
				UpdateClickHandlerFinish();
		        return websys_cancel();
			}
			
			//抗菌联用放于后面检查
			(function(callBackFunExec){
				new Promise(function(resolve,rejected){
					CheckBeforeSaveToAnti(resolve);
				}).then(function(mResult){
					if (mResult == false) {
					    UpdateClickHandlerFinish();
				        return websys_cancel();
				    }
				    callBackFunExec();
				})
			})(resolve)
	    })
	}).then(function(){
		return new Promise(function(resolve,rejected){
			(function(callBackFunExec){
				new Promise(function(resolve,rejected){
					//临床路径审查放在所有审查之后
					CPWCheck(resolve);
				}).then(function(CPWCheckRtn){
					if (CPWCheckRtn !== true) {
						UpdateClickHandlerFinish();
					    return false;
					}
					callBackFunExec();
				});
			})(resolve)
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
	    	// 实习生审核医嘱
		    if (GlobalObj.practiceFlag=="1"){
			    var UpdatePracticeRtn=InsertPriceAdd();
			    if (UpdatePracticeRtn){
				    AfterInsertOrd();
				    UpdateClickHandlerFinish();
		    		ReloadGridData("Update");
		    		return true;
				}else{
					UpdateClickHandlerFinish();
				    return websys_cancel();
				}
			}
			resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			//调用检查申请单申请页面
			$.extend(UpdateObj, { NeedMatchAry: new Array()});
		    ApplyReport(UpdateObj.OrderItemStr,UpdateObj.NeedMatchAry,resolve);
	    })
	}).then(function(UpdateOrderItemStr){
		return new Promise(function(resolve,rejected){
			if (UpdateOrderItemStr!="") {
		        $.extend(UpdateObj, { OrderItemStr: UpdateOrderItemStr});
		    }else{
			    UpdateClickHandlerFinish();
		        return websys_cancel();
		    }
		    resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			//调用治疗申请单申请页面
		    var CureNeedMatchAry=new Array();
		    //DHCDocCure_Service.CureApplyReport(UpdateObj.OrderItemStr,CureNeedMatchAry,resolve)
		    var CureInputObj={
			    EpisodeID:GlobalObj.EpisodeID,
			    OrderItemStr:UpdateObj.OrderItemStr,
			    PPRowId:GlobalObj.PPRowId
			}
			Common_ControlObj.BeforeUpdate("CureApplyReport",CureInputObj,CureNeedMatchAry,resolve);
	    })
	}).then(function(UpdateOrderItemStr){
		return new Promise(function(resolve,rejected){
			if (UpdateOrderItemStr!="") {
		        $.extend(UpdateObj, { OrderItemStr: UpdateOrderItemStr});
		    }else{
			    UpdateClickHandlerFinish();
		        return websys_cancel();
		    }
		    resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			//调用医保控费
		    var argObj={
			    EpisodeID:GlobalObj.EpisodeID,
			    OrderItemStr:UpdateObj.OrderItemStr,
			    UserID:session['LOGON.USERID'],
			    LocID:session['LOGON.CTLOCID'],
			    InsuOrderRulesFlag:GlobalObj.InsuOrderRulesFlag,
			    PAAdmType:GlobalObj.PAAdmType
			}
			Common_ControlObj.BeforeUpdate("InsuOrderRules",argObj,resolve);
	    })
	}).then(function(UpdateOrderItemStr){
		return new Promise(function(resolve,rejected){
			if (UpdateOrderItemStr!="") {
		        $.extend(UpdateObj, { OrderItemStr: UpdateOrderItemStr});
		    }else{
			    UpdateClickHandlerFinish();
		        return websys_cancel();
		    }
		    resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			SetTimeLog("UpdateClickHandler", "调用SaveOrderItems之前");
			var ExpStr = UpdateObj.StopConflictFlag + '^' + GlobalObj.DischargeConditionRowId +"!"+GlobalObj.DischargeMethodID+ '^' + GlobalObj.DeceasedDateTimeStr + '^^^^^' + GlobalObj.LongOrdStopDateTime;
			if (GlobalObj.DirectSave != "1") {
		        if (UpdateObj.OrderItemStr != "") {
		            var OEOrdItemIDs = InsertOrderItem(UpdateObj.OrderItemStr, ExpStr);
		            if (OEOrdItemIDs == "0") {
		                $.messager.alert("提示",t['Fail_SaveOrder'],"info",function(){
			                UpdateClickHandlerFinish();
			            });
		                return websys_cancel();
		            } else {
		                $.extend(UpdateObj, { SUCCESS: true,OEOrdItemIDs:OEOrdItemIDs});
		            }
		        }
		    } else {
		        var PinNumberobj = document.getElementById("PinNumber");
		        if (PinNumberobj) {
		            var PinNumber = PinNumberobj.value;
		            if (PinNumber == "") {
		                $.messager.alert("提示",t['Input_PinNumber'],"info",function(){
			                UpdateClickHandlerFinish();
			                websys_setfocus('PinNumber');
			            });
		                return websys_cancel();
		            } else {
		                var ret = cspRunServerMethod(GlobalObj.PinNumberMethod, session['LOGON.USERID'], PinNumber)
		                if (ret == "-4") {
		                    $.messager.alert("提示",t['Wrong_PinNumber'],"info",function(){
			                    UpdateClickHandlerFinish();
			                    websys_setfocus('PinNumber');
			                });
		                    return websys_cancel();
		                }
		            }
		        }
		        var OEOrdItemIDs = SaveOrderItems(UpdateObj.OrderItemStr, XHZYRetCode, ExpStr);
		        if (OEOrdItemIDs == "100") {
		            $.messager.alert("提示",t['Fail_SaveOrder'],"info",function(){
		                UpdateClickHandlerFinish();
		                websys_setfocus('PinNumber');
		            });
		        } else {
		            $.extend(UpdateObj, { SUCCESS: true,OEOrdItemIDs: OEOrdItemIDs});
		        }
		    }
		    SetTimeLog("UpdateClickHandler", "调用SaveOrderItems之后");
		    resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			//审核医嘱是否自动弹出一键打印窗口,医生站安全组配置中配置
		    if (GlobalObj.OnePrintFlag == 1) {
		        BtnPrtClickHandler();
		    }
		    resolve();
	    })
	}).then(function(){
		return new Promise(function(resolve,rejected){
			GlobalObj.UnloadUpdateFlag = true;
			$.extend(UpdateObj,{
				EpisodeID:GlobalObj.EpisodeID,
				PAAdmType:GlobalObj.PAAdmType,
				LogonDoctorID:GlobalObj.LogonDoctorID,
				SetArriveByOrder:GlobalObj.SetArriveByOrder,
				HospitalCode:GlobalObj.HospitalCode
			})
			Common_ControlObj.AfterUpdate("SynData",UpdateObj);		//数据同步【CA、CDSS、置到达】
			Common_ControlObj.AfterUpdate("PrintData",UpdateObj);	//数据单据打印【检查、病理单据】
			Common_ControlObj.AfterUpdate("Interface",UpdateObj);	//第三方接口调用
		    Common_ControlObj.AfterUpdate("DoOther",UpdateObj);		//其他方法调用
			resolve();
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			UpdateClickHandlerFinish();
			//刷新医嘱列表、医嘱单
		    ReloadGridData("Update");
		    //审核成功后刷新医嘱单
		    if (UpdateObj.SUCCESS == true) {
			    AfterInsertOrd();
		    }
		    SetTimeLog("UpdateClickHandler", "end");
		    if (UpdateObj.callBackFun) UpdateObj.callBackFun();
		    resolve();	
	    })	
	}).then(function(){
		return new Promise(function(resolve,rejected){
			//检查资源预约界面、处方关联诊断页面和下方同步医嘱信息可异步进行.但两页面不能同时弹出
			(function(callBackFunExec){
				new Promise(function(resolve,rejected){
					Common_ControlObj.AfterUpdate("ExamAutoBook",UpdateObj,resolve);
				    callBackFunExec();
				}).then(function(){
					//选择诊断处方关联信息
					Common_ControlObj.AfterUpdate("OpenSelectDia",UpdateObj);
				}).then(function(){
					//医保控费调用医保接口
					if (GlobalObj.InsuOrderRulesFlag=="Y"){
						Common_ControlObj.AfterUpdate("UpdateInsuRules",UpdateObj);
					}
				})
			})(resolve);
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			///如果左侧患者列表存在刷新左侧的患者信息
		    var FlagBF=HavZFOrderStr(UpdateObj.OrderItemStr)
		    if ((GlobalObj.PAAdmType=="I")&&(FlagBF=="Y")) {
			    if (window.parent.patientTreePanel) {
				    window.parent.patientTreePanel.store.load();
				}
				if (window.parent.GetGridData) {
					window.parent.GetGridData();
				}
			}
			SaveOrderToEMR();
		})
	})
 }
function AfterInsertOrd(){
    $('#PinNumber').val('');
    $("#Prompt").html($g("提示信息:"));
    var EpisPatInfo = tkMakeServerCall("web.DHCDocViewDataInit", "InitPatOrderViewGlobal", GlobalObj.EpisodeID,"",GlobalObj.EmConsultItm);
    InitPatOrderViewGlobal(EpisPatInfo,"AfterInsert");
    var warning=GetPromptHtml();
	$("#Prompt").html(warning);
    PageLogicObj.IsStartOrdSeqLink=0; //0 结束关联 1 开始关联
    PageLogicObj.StartMasterOrdSeq="";
    //放到ReloadGridData去清空，防止打开控件后审核医嘱，无法再次打开控件的问题
    //PageLogicObj.fpArr=[];
    $("#ChangeOrderSeq_Btn .l-btn-text")[0].innerText=$g("开始关联(R)");
}

function UpdateClickHandlerFinish() {
	DisableBtn("Insert_Order_btn",false);
	tkMakeServerCall("web.DHCDocOrderCommon","OrderEntryClearLock",GetSessionStr(),"User.OEOrder");
    /*var Url=window.location.href
    var HeadUrl=Url.split("?")[0]
    var BackUrl=Url.split("?")[1]
    var strArr=BackUrl.split("&")
    var strArrNew=strArr.slice(0,strArr.length-2)
    ////解决通过医嘱单医生复制医嘱审核之后，医嘱重复问题
    var NewStr=strArrNew.join("&")+"&copyOeoris=&copyTo="; 
    var Url=HeadUrl+"?"+NewStr
    window.location.href=Url*/
    //window.location.href = window.location.href;
}
 function ApplyReport(OrderItemStr,NeedMatchAry,callBackFun) {
    var LocID=session['LOGON.CTLOCID']; 
    var DoctorID=session['LOGON.USERID'];
    var argObj={
	    EpisodeID:GlobalObj.EpisodeID,
	    OrderItemStr:OrderItemStr,
	    DoctorID:DoctorID,
	    LocID:LocID
	}
	Common_ControlObj.BeforeUpdate("ApplyReport",argObj,NeedMatchAry,callBackFun);
}
function GetEntryDoctorId() {
    var DoctorRowid = "";
    //如果登陆人为医生?就加入医生?如果登陆人为护士?并替医生录入?还是加入医生
    //如果登陆人为护士?而且没有选择医生?就加入护士
    if (GlobalObj.LogonDoctorType == "DOCTOR") {
        DoctorRowid = GlobalObj.LogonDoctorID;
    } else {
        var obj = document.getElementById('DoctorID');
        if (obj) DoctorRowid = obj.value;
        if (DoctorRowid == "") { DoctorRowid = GlobalObj.LogonDoctorID; }
    }
    return DoctorRowid;
}
function SaveOrderItems(OrderItemStr, XHZYRetCode, ExpStr) {
    var UserAddRowid = "";
    var UserAddDepRowid = "";
    UserAddRowid = session['LOGON.USERID'];
    UserAddDepRowid = session['LOGON.CTLOCID'];
    var DoctorRowid = GetEntryDoctorId();
	var SessionStr=GetSessionStr();
    var ret = cspRunServerMethod(GlobalObj.SaveOrderItemsMethod, GlobalObj.EpisodeID, OrderItemStr, UserAddRowid, UserAddDepRowid, DoctorRowid, XHZYRetCode, ExpStr,"",SessionStr)
    return ret;
}
function InsertOrderItem(OrderItemStr, ExpStr) {
    var UserAddRowid = "";
    var UserAddDepRowid = "";
    UserAddRowid = session['LOGON.USERID'];
    UserAddDepRowid = session['LOGON.CTLOCID'];
    var DoctorRowid = GetEntryDoctorId();
	var SessionStr=GetSessionStr();
    //$.messager.alert("警告",OrderItemStr+"----"+UserAddRowid+"^"+UserAddDepRowid+"^"+DoctorRowid);
    var ret = cspRunServerMethod(GlobalObj.InsertOrderItemMethod, GlobalObj.EpisodeID, OrderItemStr, UserAddRowid, UserAddDepRowid, DoctorRowid, ExpStr,"",SessionStr)
    return ret;
}
//获取录入医嘱信息 组织提交字符串
function GetOrderDataOnAdd(callBackFun) {
    var OrderItemStr = "";
    var OrderItem = "";
    var OneOrderItem = "";
	//快速医嘱套中包含的医嘱数量
	var OrderItemCongeriesNum=0;
    //try {
	var EmConsultItm=GlobalObj.EmConsultItm;	///会诊子表ID
	var DataArry = GetGirdData();
    if (DataArry.length==0) {
	    callBackFun("");
	    return;
	}
    var SessionStr = GetSessionStr();
	var OrderSeqNoArr = new Array();
    new Promise(function(resolve,rejected){
	    (function(callBackFunExec){
		    function loop(i){
			    new Promise(function(resolve,rejected){
				    var OrderARCIMRowid = DataArry[i]["OrderARCIMRowid"];
					var OrderARCOSRowid = DataArry[i]["OrderARCOSRowid"];
					if ((OrderARCIMRowid != "")||(OrderARCOSRowid!="")) {
						var OrderName=DataArry[i]["OrderName"];
						var OrderDepProcNotes = DataArry[i]["OrderDepProcNote"];
					    if ((OrderDepProcNotes!="")&&(OrderDepProcNotes.indexOf("^")>=0)) {
						    $.messager.confirm('确认对话框', OrderName+" 医嘱备注含有系统保留字符^,请确认是否替换成字符~?", function(r){
								if (r) {
									EditRow(DataArry[i]["id"]);
									SetCellData(DataArry[i]["id"], "OrderDepProcNote",OrderDepProcNotes.replace(/\^/g, "~"));
									DataArry = GetGirdData();
									resolve();
								}else{
									callBackFun(false);
								}
							})
							return;
						}
					}
					resolve();
				}).then(function(){
					return new Promise(function(resolve,rejected){
						var OrderItemRowid = DataArry[i]["OrderItemRowid"];
				        var OrderARCIMRowid = DataArry[i]["OrderARCIMRowid"];
						var OrderARCOSRowid = DataArry[i]["OrderARCOSRowid"];
				        ///tanjishan 2015-09    
				        //if ((OrderARCIMRowid!="")&&(OrderItemRowid=="")){
				        var StyleConfigStr = DataArry[i]["StyleConfigStr"];
				        var StyleConfigObj = {};
				        if (StyleConfigStr != "") {
				            StyleConfigObj = eval("(" + StyleConfigStr + ")");
				        }
				        if ((GlobalObj.PAAdmType != "I") && (StyleConfigObj.OrderPackQty != true) && (OrderItemRowid != "")) { 
				        	resolve(); 
				        	return; 
				        }
				        if ((OrderARCIMRowid == "")&&(OrderARCOSRowid=="")) { 
				        	resolve(); 
				        	return;
				        }
						//原序号  现行ID
				        var OrderSeqNo = DataArry[i]["id"];
						var OrderItemCongeriesJson = DataArry[i]["OrderItemCongeries"];
						if (OrderItemCongeriesJson!=""){
							var OrderItemObj=GetOrderItemByItemCongeries(OrderSeqNo,OrderItemCongeriesJson);
							if (OrderItemObj.OrderItemStr!=""){
								if (OrderItemStr == "") {
									OrderItemStr = OrderItemObj.OrderItemStr;
								} else {
									OrderItemStr = OrderItemStr + String.fromCharCode(1) + OrderItemObj.OrderItemStr;
								}
							}
							if (parseFloat(OrderItemObj.OrderItemCount)==0){
								OrderItemObj.OrderItemCount=1;
							}
							OrderItemCongeriesNum=parseFloat(OrderItemCongeriesNum)+parseFloat(OrderItemObj.OrderItemCount);
							resolve(); 
				        	return;
						}
						var OldOrderSeqNo=OrderSeqNo;
						if (parseFloat(OrderItemCongeriesNum)>0){
							OrderSeqNo=parseFloat(OrderItemCongeriesNum)+parseFloat(OrderSeqNo);
						}
						OrderSeqNoArr[OldOrderSeqNo]=OrderSeqNo;
				        var OrderName = DataArry[i]["OrderName"];
				        var OrderType = DataArry[i]["OrderType"];
				        var OrderPriorRowid = DataArry[i]["OrderPriorRowid"];
				        var OrderRecDepRowid = DataArry[i]["OrderRecDepRowid"];
				        var OrderFreqRowid = DataArry[i]["OrderFreqRowid"];
				        var OrderDurRowid = DataArry[i]["OrderDurRowid"];
				        var OrderInstrRowid = DataArry[i]["OrderInstrRowid"];
				        var OrderDoseQty = DataArry[i]["OrderDoseQty"];
				        var OrderDoseQty = FormateNumber(OrderDoseQty);
				        var OrderDoseUOMRowid = DataArry[i]["OrderDoseUOMRowid"];
				        var OrderPackQty = DataArry[i]["OrderPackQty"];
				        var OrderPrice = DataArry[i]["OrderPrice"];
				        var PHPrescType = DataArry[i]["OrderPHPrescType"];
				        var BillTypeRowid = DataArry[i]["OrderBillTypeRowid"];
				        var OrderSkinTest = DataArry[i]["OrderSkinTest"];
				        var OrderARCOSRowid = DataArry[i]["OrderARCOSRowid"];
				        var OrderDrugFormRowid = DataArry[i]["OrderDrugFormRowid"];
				        var OrderStartDateStr = DataArry[i]["OrderStartDate"];
				        var OrderStartDate = "";
				        var OrderStartTime = "";
				        if (OrderStartDateStr != "") {
				            OrderStartDate = OrderStartDateStr.split(" ")[0];
				            OrderStartTime = OrderStartDateStr.split(" ")[1];
				        }
				        //关联
				        var OrderMasterSeqNo = DataArry[i]["OrderMasterSeqNo"];
						if ((parseFloat(OrderItemCongeriesNum)>0)&&(OrderMasterSeqNo!="")){
							if (OrderSeqNoArr[OrderMasterSeqNo]) {
								OrderMasterSeqNo=OrderSeqNoArr[OrderMasterSeqNo];
							}else{
								OrderMasterSeqNo=parseFloat(OrderItemCongeriesNum)+parseFloat(OrderMasterSeqNo);
							}
						}
				        var OrderDepProcNotes = DataArry[i]["OrderDepProcNote"];
				        var OrderPhSpecInstr = ""; //DataArry[i]["OrderPhSpecInstr"];
				        var OrderCoverMainIns = DataArry[i]["OrderCoverMainIns"];
				        var OrderActionRowid = DataArry[i]["OrderActionRowid"];
				        var OrderEndDateStr = DataArry[i]["OrderEndDate"];
				        var OrderEndDate = "";
				        var OrderEndTime = "";
				        if (OrderEndDateStr != "") {
				            OrderEndDate = OrderEndDateStr.split(" ")[0];
				            OrderEndTime = OrderEndDateStr.split(" ")[1];
				        }
				        var OrderLabSpecRowid = DataArry[i]["OrderLabSpecRowid"];
				        var OrderMultiDate = ""; //DataArry[i]["OrderMultiDate"];
				        var OrderNotifyClinician = ""; //DataArry[i]["OrderNotifyClinician"];
				        //if (OrderNotifyClinician==true){OrderNotifyClinician="Y"}else{OrderNotifyClinician="N"}
				        var OrderDIACatRowId = DataArry[i]["OrderDIACatRowId"];
				        //医保类别
				        var OrderInsurCatRowId = DataArry[i]["OrderInsurCatRowId"];
				        //医嘱首日次数
				        var OrderFirstDayTimes = DataArry[i]["OrderFirstDayTimes"];
				        //如果是生成取药医嘱,自备药长嘱只生成执行记录,如果是自备药即刻
				        if (((OrderPriorRowid == GlobalObj.LongOrderPriorRowid) || (OrderPriorRowid == GlobalObj.OMSOrderPriorRowid)) && (GlobalObj.PAAdmType == "I")) OrderFirstDayTimes = DataArry[i]["OrderFirstDayTimes"];
				        //医保适应症
				        var OrderInsurSignSymptomCode = ""; //DataArry[i]["OrderInsurSignSymptomCode"];
				        //身体部位
				        var OrderBodyPart = DataArry[i]["OrderBodyPart"];
				        if (OrderBodyPart != "") {
				            if (OrderDepProcNotes != "") {
				                OrderDepProcNotes = OrderDepProcNotes + "," + OrderBodyPart;
				            } else {
				                OrderDepProcNotes = OrderBodyPart;
				            }
				        }
				        //医嘱阶段
				        var OrderStageCode = DataArry[i]["OrderStageCode"];
				        //输液滴速
				        var OrderSpeedFlowRate = DataArry[i]["OrderSpeedFlowRate"];
				        OrderSpeedFlowRate = FormateNumber(OrderSpeedFlowRate);
				        //GetMenuPara("AnaesthesiaID");
				        var AnaesthesiaID = DataArry[i]["AnaesthesiaID"];
				        var OrderLabEpisodeNo = DataArry[i]["OrderLabEpisodeNo"];

				        var VerifiedOrderMasterRowid = "";
				        //营养药标志
				        var OrderNutritionDrugFlag = ""; //DataArry[i]["OrderNutritionDrugFlag"];
				        //补录关联主医嘱信息 
				        var LinkedMasterOrderRowid = DataArry[i]["LinkedMasterOrderRowid"];
				        var LinkedMasterOrderSeqNo = DataArry[i]["LinkedMasterOrderSeqNo"];
				        if ((LinkedMasterOrderSeqNo != "") && (OrderMasterSeqNo == "")) {
				            OrderMasterSeqNo = DataArry[i]["LinkedMasterOrderSeqNo"];
				        }
				        //if ((VerifiedOrderMasterRowid!="")&&(LinkedMasterOrderRowid=="")) LinkedMasterOrderRowid=VerifiedOrderMasterRowid;
				        //审批类型
				        var OrderInsurApproveType = ""; //DataArry[i]["OrderInsurApproveType"];
				        //临床路径步骤
				        var OrderCPWStepItemRowId = DataArry[i]["OrderCPWStepItemRowId"];
				        //高值材料条码
				        var OrderMaterialBarCode = DataArry[i]["OrderMaterialBarcodeHiden"];
				        //输液滴速单位
				        var OrderFlowRateUnit = DataArry[i]["OrderFlowRateUnit"];
				        var OrderFlowRateUnitRowId = DataArry[i]["OrderFlowRateUnitRowId"];
				        //开医嘱日期
				        var OrderDate = "";
				        var OrderTime = "";
				        var OrderDateStr = DataArry[i]["OrderDate"];
				        if (OrderDateStr != "") {
				            OrderDate = OrderDateStr.split(" ")[0];
				            OrderTime = OrderDateStr.split(" ")[1];
				        }
				        //需要配液
				        var OrderNeedPIVAFlag = DataArry[i]["OrderNeedPIVAFlag"];
				        //****************抗生素10********************************/
				        // 管制药品申请
				        var OrderAntibApplyRowid = DataArry[i]["OrderAntibApplyRowid"];
				        //抗生素使用原因
				        var AntUseReason = DataArry[i]["AntUseReason"];
				        //使用目的
				        var UserReasonId = DataArry[i]["UserReasonId"];
				        var ShowTabStr = DataArry[i]["ShowTabStr"];
				        //************************************************/
				        //输液次数
				        var OrderLocalInfusionQty = DataArry[i]["OrderLocalInfusionQty"];
				        //个人自备
				        var OrderBySelfOMFlag = "";
				        if (DataArry[i]["OrderSelfOMFlag"]) OrderBySelfOMFlag = DataArry[i]["OrderSelfOMFlag"];
				        var OrderOutsourcingFlag = "";
				        if (DataArry[i]["OrderOutsourcingFlag"]) OrderOutsourcingFlag = DataArry[i]["OrderOutsourcingFlag"];
				        //超量疗程原因
				        var ExceedReasonID = DataArry[i]["ExceedReasonID"];
				        //是否加急
				        var OrderNotifyClinician = DataArry[i]["Urgent"];
				        //整包装单位
				        var OrderPackUOMRowid = DataArry[i]["OrderPackUOMRowid"];
				        var OrderOperationCode=DataArry[i]["OrderOperationCode"];
						var OrderFreqDispTimeStr = DataArry[i]["OrderFreqDispTimeStr"]; 
						var OrderFreqInfo=DataArry[i]["OrderFreqFactor"]+"^"+DataArry[i]["OrderFreqInterval"]+"^"+OrderFreqDispTimeStr;
						var OrderDurFactor=DataArry[i]["OrderDurFactor"];
						var OrderHiddenPara=DataArry[i]["OrderHiddenPara"];
						var OrderQtyInfo=GetOrderQtyInfo(OrderType,OrderDoseQty,OrderFreqInfo,OrderDurFactor,OrderStartDateStr,OrderFirstDayTimes,OrderPackQty,OrderHiddenPara);
						var OrderQtySum=mPiece(OrderQtyInfo, "^", 0)
						var OrderPackQty=mPiece(OrderQtyInfo, "^",1)
				        
				        var OrderPriorRemarks = DataArry[i]["OrderPriorRemarksRowId"];
				        OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
				        //药理项目
				        var OrderPilotProRowid = DataArry[i]["OrderPilotProRowid"];
						if (OrderPilotProRowid!="") {
							if (GlobalObj.PAAdmType == "I") {
								if (GlobalObj.CFIPPilotPatAdmReason != "") BillTypeRowid = GlobalObj.CFIPPilotPatAdmReason;
							} else {
								if (GlobalObj.CFPilotPatAdmReason != "") BillTypeRowid = GlobalObj.CFPilotPatAdmReason;
							}
						}
				        if (OrderDoseQty == "") { OrderDoseUOMRowid = "" }
				        //检查申请子表记录Id
				        var ApplyArcId="";
				        //治疗申请预约ID
				        var DCAARowId= mPiece(OrderHiddenPara, String.fromCharCode(1), 20); //GlobalObj.DCAARowId
				        //临床知识库检测表id
				        var OrderMonitorId=DataArry[i]["OrderMonitorId"];
				        var OrderNurseLinkOrderRowid=DataArry[i]["OrderNurseLinkOrderRowid"];;
						var OrderBodyPartLabel=DataArry[i]["OrderBodyPartLabel"];
						if (typeof OrderBodyPartLabel=="undefined"){OrderBodyPartLabel="";}
						var CelerType="N";	//快速医嘱套标识
						var OrdRowIndex=DataArry[i]["id"];
						var OrderFreqExpInfo=CalOrderFreqExpInfo(OrderFreqDispTimeStr);
						var OrderFreqWeekStr=mPiece(OrderFreqExpInfo, "^", 0);
						var OrderFreqFreeTimeStr=mPiece(OrderFreqExpInfo, "^", 1);
						
						var OrderHiddenPara=DataArry[i]["OrderHiddenPara"];
				    	var FindRecLocByLogonLoc=OrderHiddenPara.split(String.fromCharCode(1))[18];
				    	var OrderOpenForAllHosp=OrderHiddenPara.split(String.fromCharCode(1))[28];
				    	var OrderFreqTimeDoseStr=DataArry[i]["OrderFreqTimeDoseStr"];
				    	if (OrderFreqTimeDoseStr!="") OrderDoseQty="";
				    	var OrderNurseBatchAdd=""; //护士批量补录标志,批量补录医嘱界面传入
				    	var OrderSum = DataArry[i]["OrderSum"];
				    	var AntCVID=GlobalObj.AntCVID; //危急值ID
				    	var OrderPkgOrderNo = DataArry[i]["OrderPkgOrderNo"];
				    	var OrderDocRowid=DataArry[i]["OrderDocRowid"];
				    	///
				    	var OrderPracticePreRowid=OrderHiddenPara.split(String.fromCharCode(1))[23];
						var PGIID=OrderHiddenPara.split(String.fromCharCode(1))[27]; 
				    	///虚拟长期标志
				    	var OrderVirtualtLong=DataArry[i]["OrderVirtualtLong"];
				    	var OrderFillterNo="";
                        var OrderChronicDiagCode = DataArry[i]["OrderChronicDiagCode"];
				    	if (("^"+GlobalObj.InsurBillStr+"^").indexOf("^"+BillTypeRowid+"^")==-1){
					    	OrderChronicDiagCode="";
					    }
					    /// 采集部位
					    var OrderLabSpecCollectionSiteRowid = DataArry[i]["OrderLabSpecCollectionSiteRowid"];
					    //护士补录医嘱关联主医嘱分发时间
					    var OrderNurseExecLinkDispTimeStr = DataArry[i]["OrderNurseExecLinkDispTimeStr"];
					    if (!OrderNurseExecLinkDispTimeStr) OrderNurseExecLinkDispTimeStr="";
					    var OrderSerialNum= DataArry[i]["OrderSerialNum"];
					    //计算值，在这里占位-tanjishan
            			var CalPrescNo=CalPrescSeqNo=LabEpisodeNoStr=BindSourceSerialNumStr="";
            			var OrderMedHLYYInfo=""; //医为合理用药审方信息,调用医为合理用药后更新
						var TransType=""; //转科类型
						var PrescAuditFlag=""; //审方审核标记,调用审方系统后更新
						var InsuRulesID="" //医保控费ID
				        OrderItem = OrderARCIMRowid + "^" + OrderType + "^" + OrderPriorRowid + "^" + OrderStartDate + "^" + OrderStartTime + "^" + OrderPackQty + "^" + OrderPrice;
				        OrderItem = OrderItem + "^" + OrderRecDepRowid + "^" + BillTypeRowid + "^" + OrderDrugFormRowid + "^" + OrderDepProcNotes;
				        OrderItem = OrderItem + "^" + OrderDoseQty + "^" + OrderDoseUOMRowid + "^" + OrderQtySum + "^" + OrderFreqRowid + "^" + OrderDurRowid + "^" + OrderInstrRowid;
				        OrderItem = OrderItem + "^" + PHPrescType + "^" + OrderMasterSeqNo + "^" + OrderSeqNo + "^" + OrderSkinTest + "^" + OrderPhSpecInstr + "^" + OrderCoverMainIns;
				        OrderItem = OrderItem + "^" + OrderActionRowid + "^" + OrderARCOSRowid + "^" + OrderEndDate + "^" + OrderEndTime + "^" + OrderLabSpecRowid + "^" + OrderMultiDate;
				        OrderItem = OrderItem + "^" + OrderNotifyClinician + "^" + OrderDIACatRowId + "^" + OrderInsurCatRowId + "^" + OrderFirstDayTimes + "^" + OrderInsurSignSymptomCode;
				        OrderItem = OrderItem + "^" + OrderStageCode + "^" + OrderSpeedFlowRate + "^" + AnaesthesiaID + "^" + OrderLabEpisodeNo;
				        OrderItem = OrderItem + "^" + LinkedMasterOrderRowid + "^" + OrderNutritionDrugFlag;
				        OrderItem = OrderItem + "^" + OrderMaterialBarCode + "^^" + OrderCPWStepItemRowId + "^" + OrderInsurApproveType;
				        OrderItem = OrderItem + "^" + OrderFlowRateUnitRowId + "^" + OrderDate + "^" + OrderTime + "^" + OrderNeedPIVAFlag + "^" + OrderAntibApplyRowid + "^" + AntUseReason + "^" + UserReasonId;
				        OrderItem = OrderItem + "^" + OrderLocalInfusionQty + "^" + OrderBySelfOMFlag + "^" + ExceedReasonID + "^" + OrderPackUOMRowid + "^" + OrderPilotProRowid + "^" + OrderOutsourcingFlag;
				        OrderItem = OrderItem + "^" + OrderItemRowid + "^" + ApplyArcId + "^" + DCAARowId + "^" + OrderOperationCode;
				        OrderItem = OrderItem + "^" + OrderMonitorId + "^" + OrderNurseLinkOrderRowid + "^" + OrderBodyPartLabel + "^" + CelerType + "^" + OrdRowIndex + "^" + OrderFreqWeekStr +"^"+ FindRecLocByLogonLoc+"^"+OrderPracticePreRowid;
				        OrderItem = OrderItem + "^" + OrderFreqTimeDoseStr+ "^"+OrderNurseBatchAdd+"^" +OrderSum+"^"+AntCVID+"^"+OrderPkgOrderNo+"^^^^"+OrderDocRowid+"^"+OrderVirtualtLong+"^"+OrderFillterNo;
				        OrderItem = OrderItem + "^" + EmConsultItm + "^" + OrderChronicDiagCode + "^" + OrderFreqFreeTimeStr+"^"+OrderLabSpecCollectionSiteRowid +"^"+ OrderNurseExecLinkDispTimeStr;
				        OrderItem = OrderItem + "^" + PGIID+ "^" + OrderSerialNum+ "^" + CalPrescNo + "^" + CalPrescSeqNo+ "^" + LabEpisodeNoStr+ "^" + BindSourceSerialNumStr+ "^" + OrderOpenForAllHosp;
				        OrderItem = OrderItem + "^" + OrderMedHLYYInfo+"^"+TransType+"^"+PrescAuditFlag+"^"+InsuRulesID;
						if (OrderItemStr == "") { OrderItemStr = OrderItem } else { OrderItemStr = OrderItemStr + String.fromCharCode(1) + OrderItem }
				        resolve();
					})
				}).then(function(){
					i++;
					if ( i < DataArry.length ) {
						 loop(i);
					}else{
						callBackFunExec();
					}
				})
			}
		    loop(0)
		})(resolve);
	}).then(function(){
		//提前生成处方号、检验号；
		//计算绑定的检验材料医嘱时，需要提前生产检验号，并且因为材料与检验医嘱是通过检验号码关联的，这里的检验号也必须直接保存到OE_OrdItem中
		//因为Check存在回调GetOrderDataOnAdd的可能性，所以这个只能和GetOrderDataOnAdd封装在一起
		return new Promise(function(resolve,rejected){
			if (OrderItemStr=="") {
				callBackFun(OrderItemStr);
				return ;
			}
			$.cm({
				ClassName:"web.DHCDocPrescript",
				MethodName:"CreatOrdNo",
				EpisodeID:GlobalObj.EpisodeID,
				OrdItemStr:OrderItemStr,
				SessionStr:SessionStr,
				LabEpisArray:"",
				PrescType:"Ord",
				dataType:"text"
			},function(NewOrderItemStr){
				if (NewOrderItemStr==""){
					OrderItemStr=false;
					$.messager.alert('提醒', "预生成处方\检验号失败","warning", function(r){
						callBackFun(OrderItemStr);
						return ;
					});
					return;
				}
				OrderItemStr=NewOrderItemStr;
				resolve();
			});
		})
	}).then(function(){
		return new Promise(function(resolve,rejected){
			if (OrderItemStr=="") {
				callBackFun(OrderItemStr);
				return ;
			}
			$.cm({
				ClassName:"web.DHCOEOrdAppendItem",
				MethodName:"GetAppendOrdItemArr",
				Adm:GlobalObj.EpisodeID,
				OrdItemStr:OrderItemStr,
				Loc:session['LOGON.CTLOCID'],
				OrdAddCongeriesArr:"[]",
				SessionStr:SessionStr
			},function(OrdAddCongeriesObj){
				for (var k=0;k<OrdAddCongeriesObj.length;k++){
					var OrderItem=OrdAddCongeriesObj[k].OrdListInfo;
					OrderItemStr = OrderItemStr + String.fromCharCode(1) + OrderItem;
				}
				resolve();
			});
		})
	}).then(function(){
		console.log("GetOrderDataOnAdd 执行流程执行完毕")
		callBackFun(OrderItemStr)
	});
	function GetOrderItemByItemCongeries(Startid,OrderItemCongeriesJson){
		var OrderItemCongeriesObj=eval("("+OrderItemCongeriesJson+")");
		var seqnoarr = new Array();
		var id=Startid;
		var OrderItemCount=0;
		//先计算成组标志
		for (var i=0,Length=OrderItemCongeriesObj.length;i<Length;i++) {
			OrderItemCongeriesObj[i].id=id;
			var CalSeqNo=OrderItemCongeriesObj[i].CalSeqNo;
			//记录关联关系
			var MasterSeqNo="";
			var tempseqnoarr = CalSeqNo.split(".");
			if (tempseqnoarr.length > 1) {
				var masterseqno = tempseqnoarr[0];
				if (seqnoarr[masterseqno]) {
					MasterSeqNo = seqnoarr[masterseqno];
				}
			}
			OrderItemCongeriesObj[i].OrderMasterSeqNo=MasterSeqNo;
			
			if (tempseqnoarr.length =1) {
				seqnoarr[CalSeqNo] = id;
			}
			OrderItemCount++;
			id++;
		}
		/*
		获取医嘱列表信息,数据对应的后台
		##Class(web.DHCOEOrdItemView).GetItemToList的InitParamArr
		*/
    	var EmConsultItm=GlobalObj.EmConsultItm;	///会诊子表ID
    	
		
		var OrderItemStr="";
		for (var i=0,Length=OrderItemCongeriesObj.length;i<Length;i++) {
			var OrderARCIMRowid=OrderItemCongeriesObj[i].OrderARCIMRowid;
			var OrderType=OrderItemCongeriesObj[i].OrderType;
			var OrderPriorRowid=OrderItemCongeriesObj[i].SpecOrderPriorRowid;
			var OrderFreqDispTimeStr = OrderItemCongeriesObj[i]["OrderFreqDispTimeStr"]; 
			if (OrderFreqDispTimeStr!="") {
				var OrderStartDateStr = OrderItemCongeriesObj[i]["OrderStartDate"];
			}else{
				var OrderStartDateStr=GetCellData(Startid,"OrderStartDate");
			}
			var OrderStartDate = OrderStartDateStr.split(" ")[0];
            var OrderStartTime = OrderStartDateStr.split(" ")[1];
			
			var OrderPackQty=OrderItemCongeriesObj[i].OrderPackQty;
			var OrderPrice=OrderItemCongeriesObj[i].OrderPrice;
			var OrderRecDepRowid=OrderItemCongeriesObj[i].OrderRecDepRowid;
			var BillTypeRowid=OrderItemCongeriesObj[i].OrderBillTypeRowid;
			var OrderDrugFormRowid=OrderItemCongeriesObj[i].OrderDrugFormRowid;
			var OrderDepProcNote=OrderItemCongeriesObj[i].OrderDepProcNote;
			
			var OrderDoseQty=OrderItemCongeriesObj[i].OrderDoseQty;
			var OrderDoseUOMRowid=OrderItemCongeriesObj[i].OrderDoseUOMRowid;
			var OrderFreqFactor=OrderItemCongeriesObj[i].OrderFreqFactor;
			var OrderFreqInterval=OrderItemCongeriesObj[i].OrderFreqInterval;
			var OrderFreqDispTimeStr=OrderItemCongeriesObj[i].OrderFreqDispTimeStr;
			var OrderDurFactor=OrderItemCongeriesObj[i].OrderDurFactor;
			var OrderFirstDayTimes=OrderItemCongeriesObj[i].OrderFirstDayTimes;
			var OrderFreqRowid=OrderItemCongeriesObj[i].OrderFreqRowid;
			var OrderDurRowid=OrderItemCongeriesObj[i].OrderDurRowid;
			var OrderInstrRowid=OrderItemCongeriesObj[i].OrderInstrRowid;
			var OrderPHPrescType=OrderItemCongeriesObj[i].OrderPHPrescType;
			var OrderMasterSeqNo=OrderItemCongeriesObj[i].OrderMasterSeqNo;
			var OrderSeqNo=OrderItemCongeriesObj[i].id;
			var OrderSkinTest=OrderItemCongeriesObj[i].OrderSkinTest;
			var OrderPhSpecInstr = "";
			var OrderCoverMainIns = GetCellData(Startid, "OrderCoverMainIns");
			var OrderActionRowid=OrderItemCongeriesObj[i].OrderActionRowid;
			var OrderARCOSRowid=OrderItemCongeriesObj[i].OrderARCOSRowid;
			var OrderHiddenPara = OrderItemCongeriesObj[i].OrderHiddenPara;
			var OrderEndDate="",OrderEndTime="";
			var OrderLabSpecRowid=OrderItemCongeriesObj[i].OrderLabSpecRowid;
			var OrderMultiDate="";
			var OrderNotifyClinician=OrderItemCongeriesObj[i].Urgent;//是否加急
			var OrderDIACatRowId=GetCellData(Startid, "OrderDIACatRowId");
			var OrderInsurCatRowId=OrderItemCongeriesObj[i].OrderInsurCatRowId;
			var OrderInsurSignSymptomCode="";
			var OrderStageCode = OrderItemCongeriesObj[i].OrderStageCode; //GetCellData(Startid, "OrderStageCode");
			var OrderSpeedFlowRate=OrderItemCongeriesObj[i].OrderSpeedFlowRate;
			//var AnaesthesiaID = GetMenuPara("AnaesthesiaID");
			var AnaesthesiaID = OrderItemCongeriesObj[i].AnaesthesiaID;
			var OrderLabEpisodeNo="";
			var LinkedMasterOrderRowid=OrderItemCongeriesObj[i].LinkedMasterOrderRowid;
			var OrderNutritionDrugFlag = "";
			var OrderMaterialBarCode="";
			var OrderCPWStepItemRowId=OrderItemCongeriesObj[i].OrderCPWStepItemRowId;
			var OrderInsurApproveType="";
			var OrderFlowRateUnitRowId=OrderItemCongeriesObj[i].OrderFlowRateUnitRowId;
			
			var OrderDate = "";
            var OrderTime = "";
            var OrderDateStr = GetCellData(Startid, "OrderDate");
            if (OrderDateStr != "") {
                OrderDate = OrderDateStr.split(" ")[0];
                OrderTime = OrderDateStr.split(" ")[1];
            }
			var OrderNeedPIVAFlag=OrderItemCongeriesObj[i].OrderNeedPIVAFlag;
			//****************抗生素********************************/
			// 管制药品申请-TODO：当前快速医嘱套还不支持抗生素
            var OrderAntibApplyRowid = "";
            //抗生素使用原因
            var AntUseReason = "";
            //使用目的
            var UserReasonId = GetCellData(Startid, "UserReasonId");
            //************************************************/
			var OrderLocalInfusionQty="";//输液次数           
			var OrderBySelfOMFlag=""; //个人自备
            var ExceedReasonID = "";//超量疗程原因
			var OrderPackUOMRowid=OrderItemCongeriesObj[i].OrderPackUOMRowid;
			//药理项目
            var OrderPilotProRowid = GlobalObj.PPRowId||"";		//GetCellData(Startid, "OrderPilotProRowid");
            if (GlobalObj.PAAdmType == "I") {
                if (GlobalObj.CFIPPilotPatAdmReason != "") BillTypeRowid = GlobalObj.CFIPPilotPatAdmReason;
            } else {
                if (GlobalObj.CFPilotPatAdmReason != "") BillTypeRowid = GlobalObj.CFPilotPatAdmReason;
            }			
			var OrderOutsourcingFlag="N";	//外购
			var OrderItemRowid="";
            var ApplyArcId="";	//检查申请子表记录Id
            var DCAARowId=mPiece(OrderHiddenPara, String.fromCharCode(1), 20); //GlobalObj.DCAARowId;	//治疗申请预约ID
			var OrderOperationCode=GetCellData(Startid, "OrderOperationCode");	//手术列表
            var OrderMonitorId="";	//临床知识库检测表id TODO:快速医嘱套没有和临床知识库对接
            var OrderNurseLinkOrderRowid=OrderItemCongeriesObj[i].OrderNurseLinkOrderRowid;
			var OrderBodyPartLabel=OrderItemCongeriesObj[i].OrderBodyPartLabel;
			if (typeof OrderBodyPartLabel=="undefined"){OrderBodyPartLabel="";}
			var OrderFreqInfo=OrderFreqFactor+"^"+OrderFreqInterval+"^"+OrderFreqDispTimeStr;
			var OrderQtyInfo=GetOrderQtyInfo(OrderType,OrderDoseQty,OrderFreqInfo,OrderDurFactor,OrderStartDateStr,OrderFirstDayTimes,OrderPackQty,OrderHiddenPara)
			var OrderQtySum=mPiece(OrderQtyInfo, "^", 0)
			var OrderPackQty=mPiece(OrderQtyInfo, "^",1)
			var CelerType="Y";
			var OrdRowIndex=Startid;
			var OrderFreqExpInfo=CalOrderFreqExpInfo(OrderFreqDispTimeStr);
			var OrderFreqWeekStr=mPiece(OrderFreqExpInfo, "^", 0);
			var OrderFreqFreeTimeStr=mPiece(OrderFreqExpInfo, "^", 1);
			
	    	//var OrderOpenForAllHosp=OrderHiddenPara.split(String.fromCharCode(1))[18];
	    	var FindRecLocByLogonLoc=OrderHiddenPara.split(String.fromCharCode(1))[18];
			var OrderOpenForAllHosp=OrderHiddenPara.split(String.fromCharCode(1))[28];
	    	var OrderPracticePreRowid=OrderHiddenPara.split(String.fromCharCode(1))[23];
			var OrderFreqTimeDoseStr=OrderItemCongeriesObj[i].OrderFreqTimeDoseStr;
	    	if (OrderFreqTimeDoseStr!="") OrderDoseQty="";
	    	var OrderNurseBatchAdd=""; //护士批量补录标志,批量补录医嘱界面传入
	    	var OrderSum = OrderItemCongeriesObj[i].OrderSum;
	    	var AntCVID=GlobalObj.AntCVID; //危急值ID
	    	var OrderPkgOrderNo=OrderItemCongeriesObj[i].OrderPkgOrderNo;
	    	var OrderDocRowid=OrderItemCongeriesObj[i].OrderDocRowid;
			var OrderVirtualtLong="";
	    	var OrderFillterNo="";
            var OrderChronicDiagCode = OrderItemCongeriesObj[i].OrderChronicDiagCode;
			if (("^"+GlobalObj.InsurBillStr+"^").indexOf("^"+BillTypeRowid+"^")==-1){
		    	OrderChronicDiagCode="";
	    	}
	    	var OrderLabSpecCollectionSiteRowid = OrderItemCongeriesObj[i].OrderLabSpecCollectionSiteRowid;
	    	//护士补录医嘱关联主医嘱分发时间
			var OrderNurseExecLinkDispTimeStr = OrderItemCongeriesObj[i]["OrderNurseExecLinkDispTimeStr"];
			if (!OrderNurseExecLinkDispTimeStr) OrderNurseExecLinkDispTimeStr="";
			var PGIID=OrderHiddenPara.split(String.fromCharCode(1))[27]; 
			var OrderSerialNum=OrderItemCongeriesObj[i]["OrderSerialNum"];
			//计算值，在这里占位-tanjishan
            var CalPrescNo=CalPrescSeqNo=LabEpisodeNoStr=BindSourceSerialNumStr="";
            var OrderMedHLYYInfo=""; //医为合理用药审核信息,调用医为合理用药后更新
            var TransType=""; //转科类型
            var PrescAuditFlag=""; //审方审核标记,调用审方系统后更新
            var InsuRulesID="" //医保控费ID
			OrderItem = OrderARCIMRowid + "^" + OrderType + "^" + OrderPriorRowid + "^" + OrderStartDate + "^" + OrderStartTime + "^" + OrderPackQty + "^" + OrderPrice;
            OrderItem = OrderItem + "^" + OrderRecDepRowid + "^" + BillTypeRowid + "^" + OrderDrugFormRowid + "^" + OrderDepProcNote;
            OrderItem = OrderItem + "^" + OrderDoseQty + "^" + OrderDoseUOMRowid + "^" + OrderQtySum + "^" + OrderFreqRowid + "^" + OrderDurRowid + "^" + OrderInstrRowid;
            OrderItem = OrderItem + "^" + OrderPHPrescType + "^" + OrderMasterSeqNo + "^" + OrderSeqNo + "^" + OrderSkinTest + "^" + OrderPhSpecInstr + "^" + OrderCoverMainIns;
            OrderItem = OrderItem + "^" + OrderActionRowid + "^" + OrderARCOSRowid + "^" + OrderEndDate + "^" + OrderEndTime + "^" + OrderLabSpecRowid + "^" + OrderMultiDate;
            OrderItem = OrderItem + "^" + OrderNotifyClinician + "^" + OrderDIACatRowId + "^" + OrderInsurCatRowId + "^" + OrderFirstDayTimes + "^" + OrderInsurSignSymptomCode;
            OrderItem = OrderItem + "^" + OrderStageCode + "^" + OrderSpeedFlowRate + "^" + AnaesthesiaID + "^" + OrderLabEpisodeNo;
            OrderItem = OrderItem + "^" + LinkedMasterOrderRowid + "^" + OrderNutritionDrugFlag;
            OrderItem = OrderItem + "^" + OrderMaterialBarCode + "^^" + OrderCPWStepItemRowId + "^" + OrderInsurApproveType;
            OrderItem = OrderItem + "^" + OrderFlowRateUnitRowId + "^" + OrderDate + "^" + OrderTime + "^" + OrderNeedPIVAFlag + "^" + OrderAntibApplyRowid + "^" + AntUseReason + "^" + UserReasonId;
            OrderItem = OrderItem + "^" + OrderLocalInfusionQty + "^" + OrderBySelfOMFlag + "^" + ExceedReasonID + "^" + OrderPackUOMRowid + "^" + OrderPilotProRowid + "^" + OrderOutsourcingFlag;
            OrderItem = OrderItem + "^" + OrderItemRowid + "^" + ApplyArcId + "^" + DCAARowId + "^" + OrderOperationCode;
            OrderItem = OrderItem + "^" + OrderMonitorId + "^" + OrderNurseLinkOrderRowid + "^" + OrderBodyPartLabel + "^" + CelerType + "^" + OrdRowIndex + "^" + OrderFreqWeekStr;
            OrderItem = OrderItem + "^" + FindRecLocByLogonLoc+"^"+OrderPracticePreRowid;
            OrderItem = OrderItem + "^" + OrderFreqTimeDoseStr+ "^"+OrderNurseBatchAdd+"^" +OrderSum+"^"+AntCVID+"^"+OrderPkgOrderNo+"^^^^"+OrderDocRowid+"^"+OrderVirtualtLong+"^"+OrderFillterNo;
            OrderItem = OrderItem + "^" + EmConsultItm + "^" + OrderChronicDiagCode+ "^" + OrderFreqFreeTimeStr +"^"+OrderLabSpecCollectionSiteRowid +"^"+ OrderNurseExecLinkDispTimeStr;
            OrderItem = OrderItem + "^" + PGIID+ "^" + OrderSerialNum+ "^" + CalPrescNo + "^" + CalPrescSeqNo+ "^" + LabEpisodeNoStr+ "^" + BindSourceSerialNumStr+ "^" + OrderOpenForAllHosp;
            OrderItem = OrderItem + "^" + OrderMedHLYYInfo + "^" + TransType + "^" +PrescAuditFlag+"^"+InsuRulesID;
            if (OrderItemStr == "") { OrderItemStr = OrderItem } else { OrderItemStr = OrderItemStr + String.fromCharCode(1) + OrderItem }
		}
		
		return {
			OrderItemStr:OrderItemStr,
			OrderItemCount:OrderItemCount
		};
		
	}
}
///计算OrderQtySum
function GetOrderQtyInfo(OrderType,OrderDoseQty,OrderFreqInfo,OrderDurFactor,OrderStartDateStr,OrderFirstDayTimes,OrderPackQty,OrderHiddenPara){
	var OrderFreqFactor=mPiece(OrderFreqInfo, "^", 0);
	if (OrderFreqFactor == "") OrderFreqFactor = 1;
	var OrderFreqInterval=mPiece(OrderFreqInfo, "^", 1);
	var OrderFreqDispTimeStr=mPiece(OrderFreqInfo, "^", 2);
	var OrderQtySum = "";
	if (OrderType == "R") {
		OrderDoseQty=OrderDoseQty.toString();
		var MulOrderDoseQty=0;
		if (OrderDoseQty.indexOf("-")>=0) {
			MulOrderDoseQty=1;
			var OneDayDoseQtySum=0;
			var OrdDoseQtyArry = new Array();
			for (var OrdDoseQtyIndex=0;OrdDoseQtyIndex<OrderDoseQty.split("-").length;OrdDoseQtyIndex++){
				var oneOrdDoseQty=OrderDoseQty.split("-")[OrdDoseQtyIndex];
				OrdDoseQtyArry[OrdDoseQtyIndex]=oneOrdDoseQty;
				OneDayDoseQtySum=parseFloat(OneDayDoseQtySum)+parseFloat(oneOrdDoseQty);
			}
			var FirstDayDoseQtySum=0;
			if (+OrderFirstDayTimes>0) {
				for (var FirstDayIndex=0;FirstDayIndex<OrderFirstDayTimes;FirstDayIndex++){
					var tmpindex=OrdDoseQtyArry.length-OrderFirstDayTimes+FirstDayIndex;
					FirstDayDoseQtySum=parseFloat(FirstDayDoseQtySum)+parseFloat(OrdDoseQtyArry[tmpindex]);
				}
			}else{
				FirstDayDoseQtySum=OneDayDoseQtySum;
			}
		}
		if (OrderFreqDispTimeStr!=""){
			var NumTimes = cspRunServerMethod(GlobalObj.GetCountByFreqDispTimeMethod, OrderFreqDispTimeStr, OrderStartDateStr, OrderDurFactor,OrderFirstDayTimes);
			OrderQtySum = parseFloat(OrderDoseQty) * parseFloat(NumTimes);
		}else{
			if ((OrderFreqInterval != "") && (OrderFreqInterval != null)) {
				var convert = Number(OrderDurFactor) / Number(OrderFreqInterval)
				var fact = (Number(OrderDurFactor)) % (Number(OrderFreqInterval));
				if (fact > 0) {
					fact = 1;
				} else {
					fact = 0;
				}
				OrderDurFactor = Math.floor(convert) + fact;
				//周频次OrderFreqFactor应该都是1
				//OrderFreqFactor=1;
			}
			if (MulOrderDoseQty==1) {
				OrderQtySum=parseFloat(FirstDayDoseQtySum)+(parseFloat(OneDayDoseQtySum)*(parseFloat(OrderDurFactor)-1))
			}else{
				if((OrderFirstDayTimes>0)&&(GlobalObj.PAAdmType != "I")){
					NumTimes=parseFloat(OrderFreqFactor) * (parseFloat(OrderDurFactor)-1)+parseFloat(OrderFirstDayTimes);
				}else{
					NumTimes=parseFloat(OrderFreqFactor) * parseFloat(OrderDurFactor);
				}
				OrderQtySum = parseFloat(OrderDoseQty) * NumTimes;
			}
		}
		OrderQtySum = OrderQtySum.toFixed(4);
	} else {
		if ((OrderType == "L") && (OrderPackQty == "")) { OrderPackQty = 1 }
		OrderQtySum = OrderPackQty;
		if(OrderQtySum=="") OrderQtySum=OrderDoseQty;
		var InciRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 10);
		if ((InciRowid=="")||(GlobalObj.PAAdmType == "I"))OrderPackQty = "";
	}
	return OrderQtySum+"^"+OrderPackQty;
}
/*******************************************
 *说明:
 *修改一行的元素属性是否可操作
 *只用于关联医嘱的样式控制
 * 
 ********************************************/

function ChangeCellsDisabledStyle(Row, Disabled) {
    /*var OrderPrior=GetCellData(Row,"OrderPrior");
    var OrderFreq=GetCellData(Row,"OrderFreq");
    var OrderDur=GetCellData(Row,"OrderDur");
    var OrderInstr=GetCellData(Row,"OrderInstr");
    var OrderStartDate=GetCellData(Row,"OrderStartDate");
    var OrderStartTime=GetCellData(Row,"OrderStartTime");
    var OrderEndDate=GetCellData(Row,"OrderEndDate");
    var OrderEndTime=GetCellData(Row,"OrderEndTime");
    var OrderMultiDate=GetCellData(Row,"OrderMultiDate");
    var OrderFirstDayTimes=GetCellData(Row,"OrderFirstDayTimes");
    var OrderBodyPart=GetCellData(Row,"OrderBodyPart");
    var OrderStage=GetCellData(Row,"OrderStage");
    var OrderSpeedFlowRate=GetCellData(Row,"OrderSpeedFlowRate");
    var OrderFlowRateUnit=GetCellData(Row,"OrderFlowRateUnit");
    var OrderDate=GetCellData(Row,"OrderDate");
    var OrderTime=GetCellData(Row,"OrderTime");
    var OrderNeedPIVAFlag=GetCellData(Row,"OrderNeedPIVAFlag");*/
    var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
    var OrderSkinTest=GetCellData(Row,"OrderSkinTest");
    var OrderSkinTestabled = "";
    var OrderActiontabled = ""
    var OrderHiddenPara = GetCellData(Row, "OrderHiddenPara");
    var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
    if ((OrderPriorRowid == GlobalObj.ShortOrderPriorRowid)||((OrderPriorRowid == GlobalObj.LongOrderPriorRowid)&&(GlobalObj.CFSkinTestPriorShort == 0))) {
        var OrderActiontabled = true;
        if ((NeedSkinTestINCI=="Y")||(GlobalObj.DisableOrdSkinChange=="1")){
	        var OrderActiontabled = false
        	var OrderSkinTestabled = false;
        }else{
	    	var OrderSkinTestabled = true;
	    }
        
    } else {
        var OrderSkinTestabled = false;
        var OrderActiontabled = false;
    }
    var OrderActionRowid=GetCellData(Row, "OrderActionRowid"); 
    if (OrderActionRowid!=""){
	    var OrderSkinTestabled = false;
	}
	if (GlobalObj.SkinTestInstr != "") {
	    var OrderInstrRowid = GetCellData(Row, "OrderInstrRowid");
	    var Instr = "^" + OrderInstrRowid + "^";
	    if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {  
	    	var OrderActiontabled = false;
	    }
    }
    //先选择"脱敏"后录入的医嘱皮试备注不可编辑
    var OrderActionRowid=GetCellData(Row, "OrderActionRowid");
    var StyleConfigStr = GetCellData(Row, "StyleConfigStr");
    var StyleConfigObj = {};
    if (StyleConfigStr != "") {
        StyleConfigObj = eval("(" + StyleConfigStr + ")");
    }
    var OrderActionCode = GetOrderActionCode(OrderActionRowid);
	if ((OrderActionCode=="TM")&&(!StyleConfigObj.OrderAction)) {
		var OrderActiontabled = false;
	}
	var OrderType = GetCellData(Row, "OrderType");
	if (OrderType !="R") {
		OrderSkinTestabled=false;
		OrderActiontabled = false;
	}
    var OrderRecDeptabled = true;
    if ((GlobalObj.CFSameRecDepForGroup == 1) && (Disabled == false)) {
        OrderRecDeptabled = Disabled;
    }
    //子医嘱是静配接收科室,主子医嘱的接收科室一致
    var SubOrderRecDepRowid=GetCellData(Row, "OrderRecDepRowid");
    var OrderType=GetCellData(Row, "OrderType");
    if ((Disabled == false)&&(GlobalObj.IPDosingRecLocStr != "")&&(OrderType == "R")) {
	    if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + SubOrderRecDepRowid + "^") >= 0) {
		    OrderRecDeptabled = Disabled;
		}
	}  
    var OrderDurabled=Disabled;
    if (GlobalObj.PAAdmType == "I") {
	    if ((OrderPriorRowid != GlobalObj.OutOrderPriorRowid)&&(Disabled==true)) {
		    OrderDurabled=false;
		}
	}
	//主医嘱用法不存在的时候子医嘱不控制用法，允许录入
	var OrderInstrDisabled=Disabled;
	if ((typeof MainID!='undefined')&&(MainID!="")) {
		var OrderInstrRowid=GetCellData(MainID,"OrderInstrRowid");
		var OrderInstr=GetCellData(MainID,"OrderInstr");
		if ((OrderInstrRowid=='')&&(OrderInstr=='')) {
			OrderInstrDisabled=true;
		}
	}

    var OrderFlowRateUnitable=Disabled;
    var OrderSpeedFlowRateable=Disabled;
    var OrderInstrRowid=GetCellData(Row,"OrderInstrRowid");
    if(IsSpeedRateSeparateInstr(OrderInstrRowid)&&(OrderType=="R")){
        OrderFlowRateUnitable=true;
        OrderSpeedFlowRateable=true;
    }

    var obj = {
        OrderPrior: Disabled,
        OrderFreq: Disabled,
        OrderDur: OrderDurabled,
        OrderInstr: Disabled,
        OrderSkinTest: OrderSkinTestabled,
        OrderStartDate: Disabled,
        OrderEndDate: Disabled,
        OrderMultiDate: Disabled,
        OrderFirstDayTimesCode: Disabled,
        OrderBodyPart: Disabled,
        OrderStage: Disabled,
        OrderDate: Disabled,
        OrderTime: Disabled,
        OrderNeedPIVAFlag: Disabled,
        OrderFlowRateUnit: OrderFlowRateUnitable,
        OrderSpeedFlowRate: OrderSpeedFlowRateable,
        OrderAction: OrderActiontabled,
        OrderRecDep: OrderRecDeptabled,
        ExceedReason:Disabled,
        OrderLocalInfusionQty: Disabled,
        OrderDoc:Disabled,
        OrderOperation:Disabled
    }
    if (OrderPriorRowid != GlobalObj.ShortOrderPriorRowid) {
		// 非临时医嘱加急不可勾选
        SetCellChecked(Row, "Urgent", false);
        $.extend(obj, { Urgent: false });
	}else{
		var OrderHiddenPara=GetCellData(Row,"OrderHiddenPara");
	    var EmergencyFlag = mPiece(OrderHiddenPara, String.fromCharCode(1), 25);
	    var ARCIMDefSensitive = mPiece(OrderHiddenPara, String.fromCharCode(1), 26);
	    if (EmergencyFlag =="Y") {
        	$.extend(obj, { Urgent: true });
		}
		if (ARCIMDefSensitive =="Y") SetCellChecked(Row, "Urgent", true);
	}
    ChangeCellDisable(Row, obj);
    /*
    var oldRowDisableStr=GetCellData(Row,"RowDisableStr");
    if(oldRowDisableStr !=""){
        var oldObj=eval("("+oldRowDisableStr+")");
        $.extend(oldObj,obj);
        var RowDisableStr = JSON.stringify(oldObj);
        SetCellData(Row,"RowDisableStr",RowDisableStr);
    }else{
        var RowDisableStr = JSON.stringify(obj);
        SetCellData(Row,"RowDisableStr",RowDisableStr); 
    }
    */
}
//WangQingyong 把SetPackQty放入异步延时处理,减少重复调用
function SetPackQty(Row,SetPackQtyConfig)
{
	clearTimeout(PageLogicObj.SetPackQtyTimerArr[Row]);
	PageLogicObj.SetPackQtyTimerArr[Row]=setTimeout(function(){
		SetPackQtyOrigin(Row,SetPackQtyConfig)
	},400);
}
function SetPackQtyOrigin(Row,SetPackQtyConfig) {
	var SetPackQtyConfigObj=$.extend({
			IsNotChangeFirstDayTimeFlag:"",
			IsNotNeedChangeFlag:""
	},SetPackQtyConfig);
	var OrderType = GetCellData(Row, "OrderType");
	var OrderNeedPIVAFlag = GetCellData(Row, "OrderNeedPIVAFlag");
	var OrderRecDepRowid = GetCellData(Row, "OrderRecDepRowid")
	/*
    if ((GlobalObj.IPDosingRecLocStr != "")&&(OrderType == "R")&&(OrderNeedPIVAFlag=="Y")) {
	    if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + OrderRecDepRowid + "^") >= 0) {
			return true;
		}
	}
	*/
	var OrderPackQty = GetCellData(Row, "OrderPackQty");
	//tanjishan 考虑需配液、临时医嘱拆分整包装发药等规则
	if (($("#" + Row + "_OrderPackQty").attr("disabled")=="disabled")&&(OrderPackQty=="")){
		///2020.03.12虽然不需要计算数量，但是单次剂量的改变还是需要计算金额
		//return true;
		$.extend(SetPackQtyConfigObj, { IsNotNeedChangeFlag: "Y"});
	}	
	/*if ((GlobalObj.PAAdmType!="I")&&(PageLogicObj.m_AddItemToListMethod == "ARCOS")){ 
		$.extend(SetPackQtyConfigObj, { IsNotNeedChangeFlag: "Y"});
	}*/
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
    if (OrderARCIMRowid == "") return true;
    
    var OrderType = GetCellData(Row, "OrderType");
    var OrderConFac = GetCellData(Row, "OrderConFac");
    var OrderPrice = GetCellData(Row, "OrderPrice");
    OrderPrice = OrderPrice.replace(/(^\s*)|(\s*$)/g, '');
    //if (OrderPrice=="") OrderPrice=0;
    var retPrice = GetRecPrice(Row)
    if (retPrice==undefined) retPrice="0^0^0^0^0";
    var ArrPrice = retPrice.split("^");
    var Price = ArrPrice[0];
    if ((OrderPrice == "") && ((Price = "") || (Price >= 0))) OrderPrice = 0;
    
    if(SetPackQtyConfigObj.IsNotChangeFirstDayTimeFlag!="Y") SetOrderFirstDayTimes(Row);
    var OrderFirstDayTimes=GetCellData(Row,"OrderFirstDayTimes");
	//if(OrderFirstDayTimes=="")OrderFirstDayTimes=0; //2021-02-22会导致数量计算错误
	//OrderFirstDayTimes=parseFloat(OrderFirstDayTimes);
	
    var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
	var OrderDoseQty = GetCellData(Row, "OrderDoseQty");
	var OrderDoseUOMRowid = GetCellData(Row, "OrderDoseUOMRowid");
	var OrderFreqRowid = GetCellData(Row, "OrderFreqRowid");
	var OrderDurRowid = GetCellData(Row, "OrderDurRowid");
	var OrderPackQty = GetCellData(Row, "OrderPackQty");
	var OrderPackUOMRowid = GetCellData(Row, "OrderPackUOMRowid");
    var OrderStartDate = GetCellData(Row, "OrderStartDate");
    var OrderMultiDate = GetCellData(Row, "OrderMultiDate");
    var OrderPriorRemarks = GetCellData(Row, "OrderPriorRemarksRowId");
	var PriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
	var LinkedMasterOrderPriorRowid="";
	if ((VerifiedOrderObj) && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "undefined") && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "")) {
		LinkedMasterOrderPriorRowid=VerifiedOrderObj.LinkedMasterOrderPriorRowid;
	}
	var OrderFreqDispTimeStr= GetCellData(Row, "OrderFreqDispTimeStr");
	var OrderARCOSRowid= GetCellData(Row, "OrderARCOSRowid");
	/*
	//pb by tanjishan 20200514为什么医嘱套开立的医嘱数量不做调整，暂时屏蔽
	if ((OrderARCOSRowid!="")&&(+OrderPackQty!=0)){
		$.extend(SetPackQtyConfigObj, { IsNotNeedChangeFlag: "Y"});
	}
	*/
	var OrderFreqTimeDoseStr= GetCellData(Row, "OrderFreqTimeDoseStr");
	var OrderRecDepRowid= GetCellData(Row, "OrderRecDepRowid");
	var SessionStr = GetSessionStr();
	var OrderMasterARCIMRowid="";
	var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
	if (OrderMasterSeqNo!=""){
		var rowids = GetAllRowId();
        for (var i = 0; i < rowids.length; i++) {
			var OrderSeqNo = GetCellData(rowids[i], "id")
            var OrderSeqNoMasterLink = GetCellData(rowids[i], "id");
            if (OrderSeqNoMasterLink == OrderMasterSeqNo) {
            	OrderMasterARCIMRowid=GetCellData(rowids[i], "OrderARCIMRowid");
            	break;
            }
        }
	}
    /*后台获取数量、基本数量总数等计算值*/
	var OrdParamObj={
		EpisodeID:GlobalObj.EpisodeID,
		OrderPriorRowid:PriorRowid,
		OrderARCIMRowid:OrderARCIMRowid,
		OrderDoseQty:OrderDoseQty,
		OrderDoseUOMRowid:OrderDoseUOMRowid,
		OrderFreqRowid:OrderFreqRowid,
		OrderDurRowid:OrderDurRowid,
		OrderPackQty:OrderPackQty,
		OrderPackUOMRowid:OrderPackUOMRowid,
		OrderStartDate:OrderStartDate,
		OrderMultiDate:OrderMultiDate,
		OrderPrice:OrderPrice,
		LinkedMasterOrderPriorRowid:LinkedMasterOrderPriorRowid,
		OrderFreqDispTimeStr:OrderFreqDispTimeStr,
		OrderFirstDayTimes:OrderFirstDayTimes,
		IsNotChangeFirstDayTimeFlag:SetPackQtyConfigObj.IsNotChangeFirstDayTimeFlag,
		IsNotNeedChangeFlag:SetPackQtyConfigObj.IsNotNeedChangeFlag,
		OrderFreqTimeDoseStr:OrderFreqTimeDoseStr,
		
		OrderRecDepRowid:OrderRecDepRowid,
		SessionStr:SessionStr,
		OrderMasterARCIMRowid:OrderMasterARCIMRowid
	};
	
	var OrdParamJson=JSON.stringify(OrdParamObj);
	var CalPackQtyJson = cspRunServerMethod(GlobalObj.CalPackQtyMethod,OrdParamJson);
	var CalPackQtyObj=jQuery.parseJSON(CalPackQtyJson);
	//计算数量后进行前台脚本运行
	//WangQingyong 换成Promise处理,解决IE下window.confirm弹出后，疗程下拉框不关闭的问题
	new Promise(function(resolve,rejected){
		var ParResolve=resolve;
		if ((typeof CalPackQtyObj.CallBackFunStr !="undefined")&&(CalPackQtyObj.CallBackFunStr !="")){
			var CallBackFunArr=CalPackQtyObj.CallBackFunStr.split(String.fromCharCode(2));
			var LoopCallBackFun=function(i){
				if(i>=CallBackFunArr.length){
					ParResolve();
					return;
				}
				var SingleCallBackFun=CallBackFunArr[i];
				new Promise(function(resolve){
					var singleResolve=resolve;
					if(SingleCallBackFun){
						new Promise(function(resolve){
							var CallBakFunCode=mPiece(SingleCallBackFun,"^",0)
							var CallBakFunParams=mPiece(SingleCallBackFun,"^",1)
							if (CallBakFunCode=="ReSetPackQty1"){
								var CallBakFunParamsArr=CallBakFunParams.split(";");
								var ReSetPackQty1Msg=$.messager.confirm('确认对话框',CallBakFunParamsArr[0],function(r){
									if(r){
										var PackQty=CallBakFunParamsArr[1];
										var OrderSum=CallBakFunParamsArr[2];
										$.extend(CalPackQtyObj, { OrderPackQty: PackQty,OrderSum:OrderSum});
									}
									resolve();
								}).children("div.messager-button");
								if (PriorRowid == GlobalObj.OutOrderPriorRowid) {ReSetPackQty1Msg.children("a:eq(1)").focus()};
							}else if (CallBakFunCode=="ReSetPackQty2"){
								var CallBakFunParamsArr=CallBakFunParams.split(";");
								var ReSetPackQty2Msg=$.messager.confirm('确认对话框',CallBakFunParamsArr[0],function(r){
									if(r){
										var PackQty=CallBakFunParamsArr[1];
										var OrderSum=CallBakFunParamsArr[2];
										var BaseDoseQty=CallBakFunParamsArr[3];
										var BaseDoseQtySum=CallBakFunParamsArr[4];
										$.extend(CalPackQtyObj, { OrderPackQty: PackQty,OrderSum:OrderSum,OrderBaseQty:BaseDoseQty,OrderBaseQtySum:BaseDoseQtySum});
									}
									resolve();
								}).children("div.messager-button");
								//ReSetPackQty1Msg.children("a:eq(1)").focus();
							}else{
								resolve();
							}
						}).then(function(){
							singleResolve();
						})
					}else{
						singleResolve();
					}
				}).then(function(){
					LoopCallBackFun(++i);
				});
			}
			LoopCallBackFun(0);
		}else{
			ParResolve();
		}	
	}).then(function(){
		if (typeof CalPackQtyObj.OrderPackQty !="undefined"){
			SetCellData(Row, "OrderPackQty", CalPackQtyObj.OrderPackQty);
		}
		if (typeof CalPackQtyObj.OrderBaseQty !="undefined"){
			SetCellData(Row, "OrderBaseQty", CalPackQtyObj.OrderBaseQty);
		}
		if (typeof CalPackQtyObj.OrderBaseQtySum !="undefined"){
			SetCellData(Row, "OrderBaseQtySum", CalPackQtyObj.OrderBaseQtySum);
		}
		if (typeof CalPackQtyObj.OrderSum !="undefined"){
			SetCellData(Row, "OrderSum", CalPackQtyObj.OrderSum);
		}
	    //门诊输液次数
	    SetOrderLocalInfusionQty(Row);
		//计算可用天数
		SetOrderUsableDays(Row);
	    CheckFreqAndPackQty(Row);
		GetBindOrdItemTip(Row);
	    if (PageLogicObj.m_AddItemToListMethod != "ARCOS") SetScreenSum();
		//不要在此处加,一定要判断医嘱套，否则将会导致数据行越多越慢
		//SetScreenSum();
	});
    return true;
}
function SetOrderLocalInfusionQty(Row) {
	//需要判断主医嘱输液次数
	var MainID = GetCellData(Row, "OrderMasterSeqNo");
	if(MainID!=""){
		var InfusionQty=GetCellData(MainID, "OrderLocalInfusionQty");
	}else{
		var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
	    var OrderFreqRowid = GetCellData(Row, "OrderFreqRowid");
	    var OrderDurRowid = GetCellData(Row, "OrderDurRowid");
	    var OrderInstrRowid = GetCellData(Row, "OrderInstrRowid");
		var OrderFirstDayTimes=GetCellData(Row, "OrderFirstDayTimes");
		var OrderFreqDispTimeStr=GetCellData(Row, "OrderFreqDispTimeStr");
		var OrderStartDateStr = GetCellData(Row, "OrderStartDate");
	    var OrderStartDate = "";
	    if (OrderStartDateStr != "") {
	        OrderStartDate = OrderStartDateStr.split(" ")[0];
	    }
		var InfusionQty = cspRunServerMethod(GlobalObj.GetOrderLocalInfusionQtyMethod,OrderARCIMRowid, OrderFreqRowid, OrderInstrRowid, OrderDurRowid,OrderFirstDayTimes,OrderFreqDispTimeStr,OrderStartDate);
	}
	SetCellData(Row, "OrderLocalInfusionQty", InfusionQty);
	GetBindOrdItemTip(Row);
}
function SetOrderUsableDays(Row) {
	var OrderVirtualtLong=GetCellData(Row, "OrderVirtualtLong");
	if (OrderVirtualtLong=="Y"){
		SetCellData(Row, "OrderUsableDays", "");
		return;
	}
	var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
	if (GlobalObj.PAAdmType=="I"){
        if (OrderPriorRowid != GlobalObj.OutOrderPriorRowid) {
            SetCellData(Row, "OrderUsableDays", "");
			return;
        }
	}
    if (GlobalObj.CalcDurByArcimMethod == "") return;
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
    var OrderFreqRowid = GetCellData(Row, "OrderFreqRowid");
    var OrderDurRowid = GetCellData(Row, "OrderDurRowid");
    var OrderPackQty = GetCellData(Row, "OrderPackQty");
    if (OrderPackQty == "") return;
    var OrderDoseQty = GetCellData(Row, "OrderDoseQty");
    var OrderDoseUOMRowid = GetCellData(Row, "OrderDoseUOMRowid");
    var OrderPackUOMRowid = GetCellData(Row, "OrderPackUOMRowid");
    var OrderFreqDispTimeStr = GetCellData(Row, "OrderFreqDispTimeStr");
	var OrderFreqTimeDoseStr= GetCellData(Row, "OrderFreqTimeDoseStr");
    var OrderHiddenPara=GetCellData(Row, "OrderHiddenPara");
    var SameFreqDifferentDosesFlag=OrderHiddenPara.split(String.fromCharCode(1))[19];
    if ((OrderFreqTimeDoseStr!="")&&(SameFreqDifferentDosesFlag=="Y")) OrderDoseQty="";
    var UsableDays = cspRunServerMethod(GlobalObj.CalcDurByArcimMethod, OrderARCIMRowid, OrderFreqRowid, OrderDurRowid, OrderPackQty, OrderDoseQty, OrderDoseUOMRowid, OrderPackUOMRowid, OrderFreqDispTimeStr,OrderFreqTimeDoseStr);
    var OrderType = GetCellData(Row, "OrderType");
    if ((OrderType != "R") && (UsableDays == "0")) {
        UsableDays = ""
    }
    SetCellData(Row, "OrderUsableDays", UsableDays);
}
//检查频次和整包装数量是否应该是可用的
function CheckFreqAndPackQty(Row) {
    var RowStyleObj = {};
    var OrderType = GetCellData(Row, "OrderType");
    var IdPackQty = Row + "_" + "OrderPackQty"
    var objPackQty = document.getElementById(IdPackQty);
    var IdOrderFreq = Row + "_" + "OrderFreq"
    var objFreq = document.getElementById(IdOrderFreq);
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
    var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
    /*
    if (OrderPriorRowid==GlobalObj.LongOrderPriorRowid){
        if (objFreq){
            var obj={OrderPackQty:false}
            $.extend(RowStyleObj,obj);
        }   
    }
    */
    //小时医嘱
    var HourFlag = cspRunServerMethod(GlobalObj.IsHourItem, OrderARCIMRowid);
    if (HourFlag == "1") {
	    if (GlobalObj.AllowHourOrdUsePrn !=1) {
	        //小时医嘱不能录入频次
	        var obj = { OrderFreq: false }
	        $.extend(RowStyleObj, obj);
	        ClearOrderFreq(Row);
        }
        if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid) {
            //小时医嘱，长期的也不能录入数量
            var obj = { OrderPackQty: false }
            $.extend(RowStyleObj, obj);
        }
    }
    //高值材料
    if (GlobalObj.HighValueControl == 1) {
        //var IncItmHighValueFlag = cspRunServerMethod(GlobalObj.GetIncItmHighValueFlag, OrderARCIMRowid)
        var OrderHiddenPara = GetCellData(Row, "OrderHiddenPara");
        var IncItmHighValueFlag = mPiece(OrderHiddenPara, String.fromCharCode(1), 9);
        var OrderMaterialBarCode = GetCellData(Row, "OrderMaterialBarcodeHiden");
        if (IncItmHighValueFlag == "Y") {
            //高值数量为1不可改
            SetCellData(Row, "OrderPackQty", 1);
            //高值医嘱不能录入频次
            SetCellData(Row, "OrderFreq", "");
            SetCellData(Row, "OrderFreqRowid", "");
            SetCellData(Row, "OrderFreqFactor", 1);
            //单次计量
            SetCellData(Row, "OrderDoseQty", "");
            //疗程
            SetCellData(Row, "OrderDur", "");
            SetCellData(Row, "OrderDurRowid", "");
            SetCellData(Row, "OrderDurFactor", 1);
            var obj = { OrderPackQty: false, OrderFreq: false, OrderDoseQty: false, OrderDur: false }
            $.extend(RowStyleObj, obj);
        }
    }
    //检查检验单次计量不可填写
    var ItemServiceFlag = cspRunServerMethod(GlobalObj.GetItemServiceFlagMethod, OrderARCIMRowid);
    if ((ItemServiceFlag == "1") || (OrderType == "L")) {
        var obj = { OrderDoseQty: false }
        $.extend(RowStyleObj, obj);

    }
    //ChangeCellDisable(Row,RowStyleObj);
    ChangeRowStyle(Row, RowStyleObj);
}
function ChangeLinkOrderPrior(OrderSeqNo, OrderPriorRowid, OrderStartDate, OrderStartTime, OrderPrior) {
    try {
        var rows = $('#Order_DataGrid').getDataIDs();
        for (var i = 0; i < rows.length; i++) {
            var Row = rows[i];
            var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(Row, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
            var OrderType = GetCellData(Row, "OrderType");
            if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && (OrderMasterSeqNo == OrderSeqNo)) {
                var OldOrderPriorRowid = GetCellData("OrderPriorRowid", Row)
                var obj = document.getElementById(Row + "_OrderPrior");
                if (GlobalObj.OrderPriorContrlConfig == 1) {
                    var Obj = "";
                    if ($.isNumeric(Row) == true) {
                        Obj = document.getElementById(Row + "_OrderPrior");
                    } else {
                        Obj = document.getElementById("OrderPrior");
                    }
                    ClearAllList(Obj);
                    if ((OrderPriorRowid == GlobalObj.LongOrderPriorRowid)) {
                        //只有长期
                        Obj.options[Obj.length] = new Option("长期医嘱", GlobalObj.LongOrderPriorRowid);
                        SetCellData(Row, "OrderPriorStr", GlobalObj.LongOrderPriorRowid + ":" + "长期医嘱");
                    }
                    if ((OrderPriorRowid == GlobalObj.ShortOrderPriorRowid)) {
                        //只有临时
                        Obj.options[Obj.length] = new Option("临时医嘱", GlobalObj.ShortOrderPriorRowid);
                        SetCellData(Row, "OrderPriorStr", GlobalObj.ShortOrderPriorRowid + ":" + "临时医嘱");
                    }
                    if ((OrderPriorRowid == GlobalObj.OutOrderPriorRowid)) {
                        //出院带药
                        Obj.options[Obj.length] = new Option("出院带药", GlobalObj.OutOrderPriorRowid);
                        SetCellData(Row, "OrderPriorStr", GlobalObj.OutOrderPriorRowid + ":" + "出院带药");
                    }

                }
                if (obj) {
                    //可编辑状态
                    SetCellData(Row, "OrderPrior", OrderPriorRowid);
                    SetCellData(Row, "OrderPriorRowid", OrderPriorRowid);
                } else {
                    SetCellData(Row, "OrderPrior", OrderPrior);
                    SetCellData(Row, "OrderPriorRowid", OrderPriorRowid);
                }
                OrderPriorchangeCommon(Row,OldOrderPriorRowid,OrderPriorRowid);
                if (OrderStartDate != "" && OrderStartTime != "") {
                    SetCellData(Row, "OrderStartDate", OrderStartDate + " " + OrderStartTime);
                }
            }
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function ChangeLinkOrderFreq(OrderSeqNo,OrderPriorRowid,OrderPrior,OrderFreqRowid,OrderFreq,OrderFreqFactor,OrderFreqInterval,OrderFreqDispTimeStr,OrderStartDateStr,callBackFun) {
	var rows = $('#Order_DataGrid').getDataIDs();
	new Promise(function(resolve,rejected){
		(function(callBackFun){
			function loop(i){
				new Promise(function(resolve,rejected){
					var Row = rows[i];
		            var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
		            var OrderItemRowid = GetCellData(Row, "OrderItemRowid");
		            var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
		            var OrderType = GetCellData(Row, "OrderType");
		            if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && (OrderMasterSeqNo == OrderSeqNo) && (OrderMasterSeqNo != "")) {
			        	var OldOrderFreqRowid=GetCellData(Row, "OrderFreqRowid");
		                SetCellData(Row, "OrderFreq", OrderFreq);
		                SetCellData(Row, "OrderFreqRowid", OrderFreqRowid);
		                SetCellData(Row, "OrderFreqFactor", OrderFreqFactor);
		                SetCellData(Row, "OrderFreqInterval", OrderFreqInterval);
		                SetCellData(Row, "OrderFreqDispTimeStr", OrderFreqDispTimeStr);
		                var OldOrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
		                if (OrderPriorRowid != "") {
		                    var obj = document.getElementById(Row + "_OrderPrior");
		                    if (obj) {
		                        //可编辑状态
		                        SetCellData(Row, "OrderPrior", OrderPriorRowid);
		                        SetCellData(Row, "OrderPriorRowid", OrderPriorRowid);
		                    } else {
		                        SetCellData(Row, "OrderPrior", OrderPrior);
		                        SetCellData(Row, "OrderPriorRowid", OrderPriorRowid);
		                    }
		                }
		                OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
				        (function(callBackFunExec){
					        new Promise(function(resolve,rejected){
						        if (OldOrderPriorRowid != OrderPriorRowid) {
							        OrderPriorchangeCommon(Row,OldOrderPriorRowid,OrderPriorRowid,resolve);
							    }else {
								    resolve();
								}
						    }).then(function(){
							    return new Promise(function(resolve,rejected){
								    var Row = rows[i];
								    if (OrderStartDateStr != "") {
					                    SetCellData(Row, "OrderStartDate", OrderStartDateStr);
					                }
									resolve();
						        })
							}).then(function(){
								var Row = rows[i];
						        //频次->疗程监测
				                FreqDurChange(Row)
				                SetPackQty(Row);
				                callBackFunExec();
							})
					        
					    })(resolve);
			        }else{
				        resolve();
				    }
				}).then(function(){
					i++;
					if ( i < rows.length ) {
						 loop(i);
					}else{
						callBackFun();
					}
				})
			}
			loop(0)
		})(resolve);
	}).then(function(){
		if (callBackFun) callBackFun();
	})
}

function ChangeLinkOrderInstr(OrderSeqNo, OrderInstrRowid, OrderInstr) {
    try {
	    var Count=0;
        var rows = $('#Order_DataGrid').getDataIDs();
        for (var i = 0; i < rows.length; i++) {
            var Row = rows[i];
            var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(Row, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
            var OrderType = GetCellData(Row, "OrderType");
            if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && (OrderMasterSeqNo != "") && (OrderMasterSeqNo == OrderSeqNo)) {
                var InstrRowId = GetCellData(Row, "OrderInstrRowid");
                Count=Count+1;
                if (!IsNotFollowInstr(InstrRowId)) {
                    SetCellData(Row, "OrderInstr", OrderInstr);
                    SetCellData(Row, "OrderInstrRowid", OrderInstrRowid);
                    SetRecLocStr(Row);             
                    //调用这个干嘛？ 
                    //PHCINDesc_lookuphandlerX(Row); 
                    SetPackQty(Row);
                }
                var InstrRowId = GetCellData(Row, "OrderInstrRowid");
                if (IsWYInstr(InstrRowId)) {
                    if (GlobalObj.PAAdmType != "I") {
                        SetCellData(Row, "OrderDoseQty", "");
                        SetCellData(Row, "OrderDur", "");
                        SetCellData(Row, "OrderDurRowid", "");
                        SetCellData(Row, "OrderDurFactor", "");
                    }
                }
                var OrderType = GetCellData(Row, "OrderType");
                if(OrderType=="R"){
	                var SubOrderInstrRowid=GetCellData(Row, "OrderInstrRowid");
	                if(IsSpeedRateSeparateInstr(SubOrderInstrRowid)){
	                    ChangeCellDisable(Row,{OrderSpeedFlowRate:true,OrderFlowRateUnit:true});
	                }else{
	                    ChangeCellDisable(Row,{OrderSpeedFlowRate:false,OrderFlowRateUnit:false});
	                }
                }
                //子医嘱用法为皮试用法
                var OrderHiddenPara = GetCellData(Row, "OrderHiddenPara");
    			var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
                if (GlobalObj.SkinTestInstr != "") {
	                var Instr = "^" + InstrRowId + "^";
	                if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")&&(OrderType =="R")) {  //&&(NeedSkinTestINCI=="Y")
		                /*var ActionRowid=GetCellData(Row, "OrderActionRowid");
		                var ActionCode = GetOrderActionCode(ActionRowid);
		                if ((ActionCode=="YY")||(ActionCode=="")){
		                    SetCellData(Row, "OrderSkinTest", true);
		                }
		                var styleConfigObj = { OrderSkinTest: false, OrderAction: true }
		                ChangeCellDisable(Row, styleConfigObj);*/
		                SetCellData(Row, "OrderActionRowid","");
		                SetCellData(Row, "OrderAction","");
		                //如果是成组医嘱置皮试用法，只把子医嘱的第一条置皮试勾选
		                if (Count==1){
							SetCellChecked(Row, "OrderSkinTest", true);
		                	//SetCellData(Row, "OrderSkinTest", true);
		                }else{
							SetCellChecked(Row, "OrderSkinTest", false);
		                	//SetCellData(Row, "OrderSkinTest", false);   
		                }
	                	//OrderSkinTest可以编辑,主要是成组医嘱需要医生手工选中溶媒的皮试标识
		                var styleConfigObj = { OrderSkinTest: true, OrderAction: false }
		                ChangeCellDisable(Row, styleConfigObj);
		            }else {
		                var ActionRowid=GetCellData(Row, "OrderActionRowid");
		                var ActionCode = GetOrderActionCode(ActionRowid);
		                if ((NeedSkinTestINCI=="Y")||(ActionCode!="")){
			                var styleConfigObj={OrderSkinTest:false,OrderAction:true}
			            }else if (OrderType =="R"){
				            var styleConfigObj={OrderSkinTest:true,OrderAction:true}
				        }
		                ChangeCellDisable(Row,styleConfigObj);
		            }
	            }
            }
			InstrChange(Row);
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
//开始日期时间改变
function OEORISttDatchangehandler(e) {
    var Row = GetEventRow(e)
    var OrderStartDateStr = GetCellData(Row, "OrderStartDate");
    OEORISttDat_lookupSelect(Row, OrderStartDateStr);
    SetOrderFirstDayTimes(Row);
    $("#"+Row+"_OrderStartDate").parent()[0].title=OrderStartDateStr;
	//修改开始日期计算数量
	var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
	if (IsLongPrior(OrderPriorRowid)){
		SetPackQty(Row);
	}
}
function OEORISttDat_lookupSelect(Row, OrderStartDateStr) {
    var OrderSeqNo = GetCellData(Row, "id");
    ChangeLinkOrderStartDate(OrderSeqNo, OrderStartDateStr)
}
function ChangeLinkOrderStartDate(OrderSeqNo, OrderStartDateStr) {
    var rows = $('#Order_DataGrid').getDataIDs();
    for (var i = 0; i < rows.length; i++) {
        var Row = rows[i];
        var OrderMasterSeqNo = GetCellData(Row, "OrderMasterSeqNo");
        var OrderItemRowid = GetCellData(Row, "OrderItemRowid");
        var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
        if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && (OrderMasterSeqNo == OrderSeqNo)) {
            SetCellData(Row, "OrderStartDate", OrderStartDateStr);
            SetOrderFirstDayTimes(Row);
            if (GetEditStatus(Row) == true) {
            	$("#"+Row+"_OrderStartDate").parent()[0].title=OrderStartDateStr;
            }
			//修改开始日期计算数量
			var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
			if (IsLongPrior(PriorRowId)){
				SetPackQty(Row);
			}
        }
    }
}
//皮试改变事件
function OrderSkinTestChangehandler(e) {
    var ActionRowid = "";
    var Row = GetEventRow(e);
    var OrderHiddenPara = GetCellData(Row, "OrderHiddenPara");
    var eSrc = websys_getSrcElement(e);
    var SkinTestYY = mPiece(OrderHiddenPara, String.fromCharCode(1), 0);
    if (eSrc.checked) {
        if (SkinTestYY == 1) {
            var OrderPriorArray = GlobalObj.OrderActionStr.split("^");
            for (var i = 0; i < OrderPriorArray.length; i++) {
                var OrderPrior = OrderPriorArray[i].split(String.fromCharCode(1));
                if (OrderPrior[1] == "YY") { ActionRowid = OrderPrior[0]; }
            }
            SetCellData(Row, "OrderAction", ActionRowid);
            SetCellData(Row, "OrderActionRowid", ActionRowid);
        }
        var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
        if ((OrderPriorRowid != GlobalObj.ShortOrderPriorRowid)&&(GlobalObj.CFSkinTestPriorShort == 1)) {
            if (GlobalObj.OrderPriorContrlConfig == 1) {
                SetColumnList(Row, "OrderPrior", GlobalObj.ShortOrderPriorRowid + ":" + "临时医嘱");
                SetCellData(Row, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
                SetCellData(Row, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
                SetCellData(Row, "OrderPriorStr", GlobalObj.ShortOrderPriorRowid + ":" + "临时医嘱");
            }
            SetCellData(Row, "OrderPrior", GlobalObj.ShortOrderPriorRowid);
            SetCellData(Row, "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
			OrderPriorchangeCommon(Row,OrderPriorRowid,GlobalObj.ShortOrderPriorRowid);
            //调用OrderPriorchangeCommon方法会改变光标焦点到用法位置
            SetFocusCell(Row, "OrderAction");
        }
    } else {
        SetCellData(Row, "OrderAction", "");
        SetCellData(Row, "OrderActionRowid", "");
    }
}

//加急标志改变事件
function OrderUrgentchangehandler(e) {
    var Row = GetEventRow(e);
	SetRecLocStr(Row);
}
function OrderSeqNokeydownhandler(e) {
    var rowid = GetEventRow(e);
    try { keycode = websys_getKey(e); } catch (e) { keycode = websys_getKey(); }
    try {
        if ((keycode == 13) || (keycode == 9)) {
            var OrderPackQty = GetCellData(rowid, "OrderPackQty");
            var obj = websys_getSrcElement(e);
            if (obj.value == "") {
                //SetFocusCell(rowid, "OrderInstr");
                var JumpAry = ['OrderInstr','OrderFreq','OrderDur','OrderPackQty'];
                CellFocusJump(rowid, JumpAry, true);
            } else {
                if ((GlobalObj.PAAdmType == "I") || ((GlobalObj.PAAdmType != "I") && (OrderPackQty != ""))) {
                    window.setTimeout("Add_Order_row()", 200);
                } else {
                    var JumpAry = ['OrderPackQty'];
                    CellFocusJump(rowid, JumpAry, true);
                }
            }
        }
    } catch (e) {}
}
function ChangeLinkOrderRecDep(OrderSeqNo, OrderRecDepRowid, OrderStartDateStr) {
	//if (GlobalObj.CFSameRecDepForGroup != 1) return false;
    try {
	    var FindSubOrd=false;
        var rows = $('#Order_DataGrid').getDataIDs();
        for (var i = 0; i < rows.length; i++) {
            var rowid = rows[i];
            var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
            var OrderType = GetCellData(rowid, "OrderType");
            var OrderName = GetCellData(rowid, "OrderName");
            if ((OrderARCIMRowid != "") && (OrderItemRowid == "") && (OrderMasterSeqNo == OrderSeqNo)) {
	            //子医嘱是静配接收科室,主子医嘱的接收科室一致
	            var CFSameRecDepForGroup=GlobalObj.CFSameRecDepForGroup;
	            if (CFSameRecDepForGroup!=1) {
		            var SubOrderRecDepRowid=GetCellData(rowid, "OrderRecDepRowid");
				    if ((GlobalObj.IPDosingRecLocStr != "")&&(OrderType == "R")) {
					    if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + SubOrderRecDepRowid + "^") >= 0) {
						    CFSameRecDepForGroup=1;
						}
						if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + OrderRecDepRowid + "^") >= 0) {
							CFSameRecDepForGroup=1;
						}
					}
				}else{
					ChangeCellDisable(rowid, { OrderRecDep: false });
				}
				if (CFSameRecDepForGroup != 1) {
					FindSubOrd=true;
					ChangeCellDisable(rowid, { OrderRecDep: true });
					continue;
				}
                //验证子医嘱接受科室串中是否存在主医嘱接收科室
                var FindSubRecDep = false;
                var CurrentRecLocStr = GetCellData(rowid, "CurrentRecLocStr")
                var ArrData = CurrentRecLocStr.split(String.fromCharCode(2));
                for (var m = 0; m < ArrData.length; m++) {
                    var ArrData1 = ArrData[m].split(String.fromCharCode(1));
                    if (ArrData1[0] == OrderRecDepRowid) { FindSubRecDep = true };
                }
                if (FindSubRecDep == false) {
                    $.messager.alert("警告",OrderName+$g(t['SubOrderRecDepNotDefine']));
                    //清空关联
					ClearOrderMasterSeqNo(rowid);
                    OrderMasterHandler(rowid, "C");
                    //return false;
                }else{
	                var EditStatus = GetEditStatus(rowid);
	                if (EditStatus == true) {
		                SetCellData(rowid, "OrderRecDep", OrderRecDepRowid);
		            }else{
			            var OrderRecDepDesc = GetCellData(OrderMasterSeqNo, "OrderRecDep");
			            SetCellData(rowid, "OrderRecDep", OrderRecDepDesc);
			        }
	                SetCellData(rowid, "OrderRecDepRowid", OrderRecDepRowid);
	                //协议单位切换
					GetBillUOMStr(rowid);
	                FindSubOrd=true;
	                if (GlobalObj.CFSameRecDepForGroup!=1) {
		                if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + OrderRecDepRowid + "^") >= 0) {
						    ChangeCellDisable(rowid, { OrderRecDep: false });
						}else{
							ChangeCellDisable(rowid, { OrderRecDep: true });
						}
	                }
                }
                if (OrderStartDateStr != "") {
                    SetCellData(rowid, "OrderStartDate", OrderStartDateStr);
                    SetOrderFirstDayTimes(rowid);
                }
            }
        }
        if (FindSubOrd==false){
	        $("#" + OrderSeqNo).find("td").removeClass("OrderMasterM");
	    }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function CheckLinkOrderRecDep(MainID, SubID) {
	//判断主子医嘱的用法是否一致,如果不一致,则先改变子医嘱的用法,并同时修改接收科室
	var MainOrdInstr = GetCellData(MainID, "OrderInstr");
	var MainOrdInstrRowid = GetCellData(MainID, "OrderInstrRowid");
	var SubOrdInstr = GetCellData(SubID, "OrderInstr");
	var SubOrdInstrRowid = GetCellData(SubID, "OrderInstrRowid");
	var NeedChangeRow="";
	if ((!IsNotFollowInstr(SubOrdInstrRowid))){   ///&&(SubOrdInstrRowid!=MainOrdInstrRowid)) {
		//如果子医嘱是经过皮试引导选择窗口确定的用法，则需要以子医嘱用法为准
		var MainOrdNumStr=GetMainOrdNumStrInGroup(MainID,SubID);
		var MainDataRow=mPiece(MainOrdNumStr, "^", 1);
		var NeedChangeRow=mPiece(MainOrdNumStr, "^", 2);
		var NeedChangeInstr=GetCellData(MainDataRow, "OrderInstr");
		var NeedChangeInstrRowid=GetCellData(MainDataRow, "OrderInstrRowid");
		
		SetCellData(NeedChangeRow, "OrderInstr", NeedChangeInstr);
        SetCellData(NeedChangeRow, "OrderInstrRowid", NeedChangeInstrRowid);
        //SetRecLocStr(NeedChangeRow);
	}
	SetRecLocStr(MainID);
	if (($.isNumeric(NeedChangeRow))&&(NeedChangeRow!=MainID)){
		SetRecLocStr(NeedChangeRow);
	}
	var OrderName = GetCellData(SubID, "OrderName");
	var MainOrderName = GetCellData(MainID, "OrderName");
    var OrderType = GetCellData(SubID, "OrderType");
    var MasterOrderRecDepRowid = GetCellData(MainID, "OrderRecDepRowid");
    var SubOrderRecDepRowid = GetCellData(SubID, "OrderRecDepRowid");
	if(MasterOrderRecDepRowid==SubOrderRecDepRowid) return true;
    var OrderPriorRemarks = GetCellData(SubID, "OrderPriorRemarksRowId");
    var OrderPriorRowid = GetCellData(SubID, "OrderPriorRowid");
    var ExpStr=GlobalObj.EpisodeID+"^"+session['LOGON.CTLOCID']+"^0";
    var CFSameRecDepForGroup=GlobalObj.CFSameRecDepForGroup;
	//子医嘱是静配接收科室,主子医嘱的接收科室一致且主医嘱按照子医嘱接收科室走
	var SubOrdIPDosingRecLoc=0,MasterOrdIPDosingRecLoc=0;
    if ((GlobalObj.IPDosingRecLocStr != "")&&(OrderType == "R")) {
	    if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + SubOrderRecDepRowid + "^") >= 0) {
		    SubOrdIPDosingRecLoc=1;
		}
		if (("^" + GlobalObj.IPDosingRecLocStr + "^").indexOf("^" + MasterOrderRecDepRowid + "^") >= 0) {
			CFSameRecDepForGroup=1;
			var FindSubRecDep = false;
		    var CurrentRecLocStr = GetCellData(SubID, "CurrentRecLocStr")
            var ArrData = CurrentRecLocStr.split(String.fromCharCode(2));
            for (var i = 0; i < ArrData.length; i++) {
                var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                if (ArrData1[0] == MasterOrderRecDepRowid) { FindSubRecDep = true };
            }
            if (FindSubRecDep == false) {
                $.messager.alert("警告",$g("子医嘱")+OrderName+$g("未找到与主医嘱一致的静配接收科室!"),"info",function(){
	                //清空关联
					ClearOrderMasterSeqNo(SubID);
	            });
                return false;
            }
		}
	}
	if (SubOrdIPDosingRecLoc == 1){
		 if ((OrderPriorRowid != GlobalObj.OMOrderPriorRowid) && (OrderPriorRowid != GlobalObj.OMSOrderPriorRowid) && (OrderPriorRemarks != "OM") && (OrderPriorRemarks != "ZT")) {
		 	var MainOrderARCIMRowid = GetCellData(MainID, "OrderARCIMRowid");
            var SubOrderRecDepDesc = GetCellData(SubID, "OrderRecDep",true);
            var Check = cspRunServerMethod(GlobalObj.CheckStockEnoughMethod, MainOrderARCIMRowid, 1, SubOrderRecDepRowid, GlobalObj.PAAdmType,ExpStr);
            var CheckArr=Check.split("^");
            if (Check == '0') {
	            $.messager.alert("警告",MainOrderName + SubOrderRecDepDesc + $g(t['QTY_NOTENOUGH']));
				ClearOrderMasterSeqNo(SubID);
                return false;
	        }else if (Check == '-1') {
                $.messager.alert("警告",MainOrderName + SubOrderRecDepDesc + $g(t['QTY_INCItemLocked']));
                return false;
            } else {
                if (Check == "-2"){
                    $.messager.alert("警告",MainOrderName + $g("通过医嘱或子类绑定的")+CheckArr[1] + $g(t['QTY_INCItemLocked']));
                    return false;
                    
                } else if (Check == "-3"){
                    $.messager.alert("警告",MainOrderName + $g("通过医嘱或子类绑定的")+CheckArr[1] + $g(t['QTY_NOTENOUGH']));
                    return false;
                }

                var FindMainRecDep = false;
                var CurrentRecLocStr = GetCellData(MainID, "CurrentRecLocStr")
                var ArrData = CurrentRecLocStr.split(String.fromCharCode(2));
                for (var i = 0; i < ArrData.length; i++) {
                    var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                    if (ArrData1[0] == SubOrderRecDepRowid) { FindMainRecDep = true };
                }
                if (FindMainRecDep == false) {
                    $.messager.alert("警告",$g("主医嘱")+MainOrderName+$g("未找到与子医嘱一致的静配接收科室!"),"info",function(){
	                    //清空关联
						ClearOrderMasterSeqNo(SubID);
	                });
                    return false;
                }
                if (FindMainRecDep != false) {
                    var EditStatus = GetEditStatus(MainID);
                    SetCellData(MainID, "OrderRecDepRowid", SubOrderRecDepRowid);
                    if (EditStatus == true) {
                        SetCellData(MainID, "OrderRecDep", SubOrderRecDepRowid);
                    } else {
                        SetCellData(MainID, "OrderRecDep", SubOrderRecDepDesc);
                    }
                    OrderRecDepChangeCom(MainID);
                }
            }
		 }
		 return true;
	}
	
    if (CFSameRecDepForGroup == 1) { //&& (OrderType == 'R')
        if ((OrderPriorRowid != GlobalObj.OMOrderPriorRowid) && (OrderPriorRowid != GlobalObj.OMSOrderPriorRowid) && (OrderPriorRemarks != "OM") && (OrderPriorRemarks != "ZT")) {
            var OrderARCIMRowid = GetCellData(SubID, "OrderARCIMRowid");
            var OrderName = GetCellData(SubID, "OrderName");
            var OrderRecDepDesc = GetCellData(MainID, "OrderRecDep",true);
            var Check = cspRunServerMethod(GlobalObj.CheckStockEnoughMethod, OrderARCIMRowid, 1, MasterOrderRecDepRowid, GlobalObj.PAAdmType,ExpStr);
            var CheckArr=Check.split("^");
            Check=CheckArr[0];
            if (Check == '0') {
                $.messager.alert("警告",OrderName + OrderRecDepDesc + $g(t['QTY_NOTENOUGH']));
				ClearOrderMasterSeqNo(SubID);
                return false;
            } else if (Check == '-1') {
                $.messager.alert("警告",OrderName + OrderRecDepDesc + $g(t['QTY_INCItemLocked']));
                return false;
            } else {
                if (Check == "-2"){
                    $.messager.alert("警告",OrderName + $g("通过医嘱或子类绑定的")+CheckArr[1] + $g(t['QTY_INCItemLocked']));
                    return false;
                    
                } else if (Check == "-3"){
                    $.messager.alert("警告",OrderName + $g("通过医嘱或子类绑定的")+CheckArr[1] + $g(t['QTY_NOTENOUGH']));
                    return false;
                }
                var OrderType = GetCellData(MainID, "OrderType");
                // if (OrderType != "R") return false;
                var FindSubRecDep = false;
                var CurrentRecLocStr = GetCellData(SubID, "CurrentRecLocStr")
                var ArrData = CurrentRecLocStr.split(String.fromCharCode(2));
                for (var i = 0; i < ArrData.length; i++) {
                    var ArrData1 = ArrData[i].split(String.fromCharCode(1));
                    if (ArrData1[0] == MasterOrderRecDepRowid) { FindSubRecDep = true };
                }
                if (FindSubRecDep == false) {
                    $.messager.alert("警告",OrderName + OrderRecDepDesc + $g(t['SubOrderRecDepNotDefine']));
                    //清空关联
					ClearOrderMasterSeqNo(SubID);
                    return false;
                }
                if (FindSubRecDep != false) {
                    var EditStatus = GetEditStatus(SubID);
                    SetCellData(SubID, "OrderRecDepRowid", MasterOrderRecDepRowid);
                    if (EditStatus == true) {
                        SetCellData(SubID, "OrderRecDep", MasterOrderRecDepRowid);
                    } else {
                        SetCellData(SubID, "OrderRecDep", OrderRecDepDesc);
                    }
                }
            }
        }
    }
    return true;
}
///当主子医嘱中包含有皮试引导窗选项结果的内容时，以皮试引导窗口那一行的数据为准
function GetMainOrdNumStrInGroup(MainID,SubID){
	//判断主子医嘱的用法是否一致,如果不一致,则先改变子医嘱的用法,并同时修改接收科室
	var MainOrdInstr = GetCellData(MainID, "OrderInstr");
	var MainOrdInstrRowid = GetCellData(MainID, "OrderInstrRowid");
	var MainOrderPriorRowid = GetCellData(MainID, "OrderPriorRowid");
	var MainIDOrderHiddenPara = GetCellData(MainID, "OrderHiddenPara");
	var SubOrdInstr = GetCellData(SubID, "OrderInstr");
	var SubOrdInstrRowid = GetCellData(SubID, "OrderInstrRowid");
	var SubOrderHiddenPara = GetCellData(SubID, "OrderHiddenPara");
	var SubOrderPriorRowid = GetCellData(SubID, "OrderPriorRowid");
	
	var MainNeedSkinTestINCI = mPiece(MainIDOrderHiddenPara, String.fromCharCode(1), 7);
	var SubNeedSkinTestINCI = mPiece(SubOrderHiddenPara, String.fromCharCode(1), 7);
	var MainOrderPriorFlag = IsLongPrior(MainOrderPriorRowid);
	var SubOrderPriorFlag = IsLongPrior(SubOrderPriorRowid);
	var MainSkinFlag="N";
	var SubSkinFlag="N";
	if ((GlobalObj.SkinTestInstr != "")&&(GlobalObj.SkinTestInstr.indexOf("^" + MainOrdInstrRowid + "^") != "-1")&&(!MainOrderPriorFlag)){
		MainSkinFlag="Y";
	}
	if ((GlobalObj.SkinTestInstr != "")&&(GlobalObj.SkinTestInstr.indexOf("^" + SubOrdInstrRowid + "^") != "-1")&&(!SubOrderPriorFlag)){
		SubSkinFlag="Y";
	}
	var Flag="0";
	if ((MainNeedSkinTestINCI=="Y")&&(SubNeedSkinTestINCI=="Y")&&(MainSkinFlag!=SubSkinFlag)){
		Flag="-100";
	}
	//成组医嘱是先同步的数据？这里注释应该不会有问题
	//if (MainSkinFlag==SubSkinFlag){
	//	return Flag+"^"+MainID+"^"+SubID;
	//}else{
		if (MainNeedSkinTestINCI=="Y"){
			return Flag+"^"+MainID+"^"+SubID;
		}else if(SubNeedSkinTestINCI=="Y"){
			return Flag+"^"+SubID+"^"+MainID;
		}else{
			return Flag+"^"+MainID+"^"+SubID;
		}
	//}
	
}
//-------------高值更新
//高值条码
function OrderMaterialBarcodeContrl(rowid,callBackFun) {
    var label = GetCellData(rowid, "OrderMaterialBarcode");
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    if ((label == "")||(OrderARCIMRowid!="")) { 
    	return false; 
    }
    var AricmStr = cspRunServerMethod(GlobalObj.GetArcimByLabel, label)
    var ArcimArr = AricmStr.split("^")
    var arcimRowid = ArcimArr[0];
    if (arcimRowid == "") {
        $.messager.alert("提示","该条码对应的医嘱项目不存在,请核实!")
        return false;
    }
    if (ArcimArr[1] == "Enable") {
        var IncItmHighValueFlag = ArcimArr[7]
        if (IncItmHighValueFlag == "N") {
			
			var OrdParamsArr=new Array();
			OrdParamsArr[OrdParamsArr.length]={
				OrderARCIMRowid:arcimRowid,
				MaterialBarcode:label
			};
			new Promise(function(resolve,rejected){
				AddItemToList(rowid,OrdParamsArr,"data","",resolve);
			}).then(function(RtnObj){
				var rowid=RtnObj.rowid;
				var returnValue=RtnObj.returnValue;
				
	            if (!returnValue) {
	                ClearRow(rowid);
	            }else{
		             Add_Order_row();
		             setTimeout(function(){ 
		             	SetFocusCell(parseInt(rowid)+1, "OrderMaterialBarcode");
				     },100); 
		        }
			})
        } else {
	        var OriginalStatusFlag=ArcimArr[9]
	        if (OriginalStatusFlag="Y"){
		        var ReLocIdFlag = "N";
                
				var OrdParamsArr=new Array();
				OrdParamsArr[OrdParamsArr.length]={
					OrderARCIMRowid:arcimRowid,
					MaterialBarcode:label
				};
				new Promise(function(resolve,rejected){
					AddItemToList(rowid,OrdParamsArr,"data","",resolve);
				}).then(function(RtnObj){
					var rowid=RtnObj.rowid;
					var returnValue=RtnObj.returnValue;
					
	                if (returnValue == true) {
	                        SetCellData(rowid, "OrderMaterialBarcodeHiden", label); //把条码放到一个隐藏的列里面
	                        SetCellData(rowid, "OrderMaterialBarcode", label);
	                        Add_Order_row();
	                        setTimeout(function(){ 
				             	SetFocusCell(parseInt(rowid)+1, "OrderMaterialBarcode");
						     },100); 
	                    
	                } else {
	                    ClearRow(rowid);
	                }
		        })
		        }else{
            if (GlobalObj.HighValueControl != 1) {
                $.messager.alert("提示","您所登录的科室没有录入高值材料的权限,请联系信息科确认!")
                return false;
            }
            //返回的是实库存数量。其实可以走统一的库存判断不用在这做判断

            var avaQty = ArcimArr[4]
            if (avaQty <= 0) {
                $.messager.alert("提示","该条码对应的医嘱库存不足.")
                return false;
            }
            var ReLocId = ArcimArr[5] //材料可用接收科室
            if (arcimRowid != "") {
                var ReLocIdFlag = "N";
                
				var OrdParamsArr=new Array();
				OrdParamsArr[OrdParamsArr.length]={
					OrderARCIMRowid:arcimRowid,
					MaterialBarcode:label
				};
				new Promise(function(resolve,rejected){
					AddItemToList(rowid,OrdParamsArr,"data","",resolve);
				}).then(function(RtnObj){
					var rowid=RtnObj.rowid;
					var returnValue=RtnObj.returnValue;
					
	                if (returnValue == true) {
	                    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
	                    if (OrderARCIMRowid != "") {
	                        var OrderRecLocStr = GetCellData(rowid, "CurrentRecLocStr");
	                        var ArrData = OrderRecLocStr.split(String.fromCharCode(2));
	                        for (var i = 0; i < ArrData.length; i++) {
	                            var ArrData1 = ArrData[i].split(String.fromCharCode(1));
	                            if ((ArrData1[0] == ReLocId) && (ReLocIdFlag != "Y")) { ReLocIdFlag = "Y" };
	                        }
	                        if (ReLocIdFlag == "N") {
	                            $.messager.alert("提示","该条码不能在该科室使用!","info",function(){
		                            ClearRow(rowid);
		                        })
	                            return false;
	                        }
	                        SetCellData(rowid, "OrderMaterialBarcodeHiden", label); //把条码放到一个隐藏的列里面
	                        SetCellData(rowid, "OrderMaterialBarcode", label);
	                        Add_Order_row();
	                        setTimeout(function(){ 
				             	SetFocusCell(parseInt(rowid)+1, "OrderMaterialBarcode");
						     },100); 
	                    }
	                } else {
	                    ClearRow(rowid);
	                }
				})
            }
	        }
        }

    } else {
        $.messager.alert("提示","该条码不存在或者已被使用!","info",function(){
	        if (callBackFun) callBackFun();
        })
        return false;
    }
}

function OrderMaterialBarcode_changehandler(e) {
    var rowid = GetEventRow(e);
    if (PageLogicObj.BarcodeEntry==0) {
    	OrderMaterialBarcodeContrl(rowid);
    }
}
function OrderMaterialBarcode_Keypresshandler(e) {
    var type = websys_getType(e);
    var key = websys_getKey(e);
    var rowid = GetEventRow(e);
    if (key == 13) {
	    PageLogicObj.BarcodeEntry=1;
        OrderMaterialBarcodeContrl(rowid,function(){
			    PageLogicObj.BarcodeEntry=0;
		});
    }
}
//疗程超量原因
function ExceedReasonChange(e) {
    var rowid = "";
    var obj = websys_getSrcElement(e);
    var rowid = GetEventRow(e);
    SetCellData(rowid, "ExceedReasonID", obj.value);
    ChangeLinkOrderExceedReason(rowid);
}
function ChangeLinkOrderExceedReason(Row) {
    try {
        var ExceedReasonID = GetCellData(Row, "ExceedReasonID");
        var ExceedReason = GetCellData(Row, "ExceedReason");
        var RowArry = GetSeqNolist(Row)
        for (var i = 0; i < RowArry.length; i++) {
	        var obj = document.getElementById(RowArry[i] + "_ExceedReason");
            if (obj) {
                //可编辑状态
                SetCellData(RowArry[i], "ExceedReason", ExceedReasonID);
            } else {
                SetCellData(RowArry[i], "ExceedReason", ExceedReason);
            }
            SetCellData(RowArry[i], "ExceedReasonID", ExceedReasonID);
        }
    } catch (e) { dhcsys_alert(e.message) }
}
//打印门诊导诊单
function BtnPrtGuidPatHandler(RepeatFlag) {
    var url = "websys.default.csp?WEBSYS.TCOMPONENT=DHCDocPatGuideDocumentsPrt&EpisodeID=" + GlobalObj.EpisodeID + "&mradm=" + GlobalObj.mradm + "&PatientID=" + GlobalObj.PatientID;
    var ConfirmPrintAll = dhcsys_confirm("是否打印全部导诊单项目?");
    if (ConfirmPrintAll) {
		if(typeof websys_writeMWToken=='function') url=websys_writeMWToken(url);
        window.open(url, "DHCDocPatGuideDocumentsPrtPrintAll", "top=0,left=0,width=1,height=1,alwaysLowered=yes");
    } else {
        websys_createWindow(url, "DHCDocPatGuideDocumentsPrt", "top=100,left=200,width=1000,height=600,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes");
    }
}
//重新打印门诊导诊单
function BtnRePrtGuidPat_Click() {
    //补打导诊单 全部打印
    var RepeatFlag = 1;
    BtnPrtGuidPatHandler(RepeatFlag);
}
//保存为医嘱套
function SaveToArcos_Click() {
    var SelIds = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    if (SelIds == null || SelIds.length == 0) {
        $.messager.alert("提示", "请选择要保存到医嘱套的记录");
        return;
    }
    var ValidCount=0;
    for (var i = 0; i < SelIds.length; i++) {
        var OrderItemRowid = GetCellData(SelIds[i], "OrderItemRowid");
        var OrderARCIMRowid = GetCellData(SelIds[i], "OrderARCIMRowid");
        if (OrderARCIMRowid!="") ValidCount=ValidCount+1;
    }
    if (ValidCount==0){
	    $.messager.alert("提示", "请选择要保存到医嘱套的有效记录");
        return false;
	}
    UDHCOEOrderDescSetLink(function(RtnStr){
	    var ArcosRowid = RtnStr.split("^")[0];
	    if (ArcosRowid != "") { 
	    	AddTOArcosARCIM(ArcosRowid, SelIds); 
	    } else { 
	    	$.messager.alert("警告", "保存失败!"); 
	    	return websys_cancel(); 
	    }
	});
}
//插入医嘱套名称
function UDHCOEOrderDescSetLink(callback) {
    var lnk = "udhcfavitem.edit.hui.csp?TDis=1&CMFlag=N";  //&CMFlag=N&HospARCOSAuthority=1"; //udhcfavitem.edit.new.csp
    websys_showModal({
		iconCls:'icon-w-pen-paper',
		url:lnk,
		title:$g('医嘱套维护 ')+"<span style='color:"+(HISUIStyleCode=="lite"?"#FF9933":"#FFB746")+"'>"+$g('提示：需新增医嘱套请右键点击【新增】;需保存到已存在的医嘱套中,请双击对应行')+'</span>',
		width:760,height:(websys_getTop().screen.height - 300),
		CallBackFunc:function(rtn){
			if (callback) callback(rtn);
		}
	})
}
//对应的医嘱套医嘱保存
var OrderMasterSeqNoArr =new Array();
var OrderSubSeqNoArr =new Array();
function AddTOArcosARCIM(Arcosrowid, rowids) {
    if (Arcosrowid == "") { return websys_cancel(); }
    var confirmflag=0
	for(var i=0;i<rowids.length;i++){ 
	  	var OrderItemRowid=GetCellData(rowids[i],"OrderItemRowid");
        var OrderARCIMRowid=GetCellData(rowids[i],"OrderARCIMRowid");
        if (OrderARCIMRowid=="") continue;
        if (OrderItemRowid!=""){
	         var OrderBindSource = GetCellData(rowids[i], "OrderBindSource")
	         if (OrderBindSource!="") {
		         confirmflag=1
	         	break
	         } 
	        }
	 }
	 if (confirmflag==1){
		$.messager.confirm('确认对话框',"当前保存的医嘱中存在系统自动带出的医嘱项目，是否仅保存开立的医嘱?",function(r){
			if(r){
				retstring= GetAddTOArcosARCIMBindSource(Arcosrowid,rowids,"1")
			}else{
				retstring= GetAddTOArcosARCIMBindSource(Arcosrowid,rowids,"0")
			}
			
		});
	}else{
		retstring= GetAddTOArcosARCIMBindSource(Arcosrowid,rowids,"0")
	}
	function GetAddTOArcosARCIMBindSource(Arcosrowid,rowids,BindFlag){
		    OrderSubSeqNoArr = new Array();
			OrderMasterSeqNoArr = new Array();
		    var len = rowids.length;
		    for (var i = 0; i < rowids.length; i++) {
		        //门诊的已经审核但未收费不会在录入的医嘱套中
		        var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
		        var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
		        if (OrderARCIMRowid=="") continue;
		        if (OrderItemRowid!=""){
	         		var OrderBindSource = GetCellData(rowids[i], "OrderBindSource")
	         		if ((OrderBindSource!="")&&(BindFlag=="1")) {continue;}
		         }
			        var OrderType = GetCellData(rowids[i], "OrderType");
		            var OrderMasterSeqNo = GetCellData(rowids[i], "OrderMasterSeqNo");
		            //if ((OrderType!="R")&&(OrderMasterSeqNo!="")) continue;
		            var OrderSeqNo = GetCellData(rowids[i], "id");
		            var OrderPriorRowid = GetCellData(rowids[i], "OrderPriorRowid");
		            OrderMasterSeqNo=GetLinkMasterNoForArcos(rowids[i], Arcosrowid)
		            var OrderDoseQty = GetCellData(rowids[i], "OrderDoseQty"); //剂量
		            if ((OrderDoseQty!="")&&(OrderDoseQty.indexOf("-")>=0)) {
			            OrderDoseQty=OrderDoseQty.split("-")[0];
			        }
		            var OrderDoseUOM = GetCellData(rowids[i], "OrderDoseUOMRowid"); //剂量单位
		            var OrderFreqRowID = GetCellData(rowids[i], "OrderFreqRowid"); //频次
		            var OrderInstrRowID = GetCellData(rowids[i], "OrderInstrRowid"); //用法
		            var OrderDurRowid = GetCellData(rowids[i], "OrderDurRowid"); //疗程
		            var OrderPackQty = GetCellData(rowids[i], "OrderPackQty"); //整包装
		            var OrderPackUOM = GetCellData(rowids[i], "OrderPackUOMRowid"); //整包装单位
		            var OrderRecDepRowid = GetCellData(rowids[i], "OrderRecDepRowid");
		            var FindFlag=0;
		            var BillUOMStr=GetCellData(rowids[i], "OrderPackUOMStr");
		            var ArrData = BillUOMStr.split(String.fromCharCode(2));
		            if (ArrData.length<=1){
			            OrderRecDepRowid="";
			        }else{
				        for (var m = 0; m < ArrData.length-1; m++) {
					        var ArrData1 = ArrData[m].split(String.fromCharCode(1));
					        if ((ArrData1[0] == OrderPackUOM)&&(OrderPackUOM!="")&&(OrderPackUOM!=undefined)) {
					            FindFlag=1;
					        }
					    }
					    if (FindFlag==0) OrderRecDepRowid="";
				    }
		            var OrderDepProcNote = GetCellData(rowids[i], "OrderDepProcNote"); //医嘱备注
		            var OrderPriorRemarks = GetCellData(rowids[i], "OrderPriorRemarksRowId"); //附加说明
		            if (OrderPriorRemarks == "false") OrderPriorRemarks = "";
		            var SampleId = GetCellData(rowids[i], "OrderLabSpecRowid");
		            //SampleId 标本ID,ARCOSItemNO  插入指定位置(医嘱录入不用), OrderPriorRemarksDR As %String
		            var OrderStageCode = GetCellData(rowids[i], "OrderStageCode");
		            var OrderSpeedFlowRate=GetCellData(rowids[i],"OrderSpeedFlowRate");//输液流速
		            var OrderFlowRateUnitRowId=GetCellData(rowids[i],"OrderFlowRateUnitRowId"); //流速单位
		            var OrderBodyPartLabel=GetCellData(rowids[i], "OrderBodyPartLabel");
		            var Urgent=GetCellData(rowids[i], "Urgent");
		            var MustEnter="N";
		            var OrderSkinTest=GetCellData(rowids[i], "OrderSkinTest");
		            var OrderActionRowid=GetCellData(rowids[i], "OrderActionRowid");
		            var OrderFreqTimeDoseStr=GetCellData(rowids[i], "OrderFreqTimeDoseStr");//同频次不同剂量
		            var OrderFreqWeekStr=GetCellData(rowids[i], "OrderFreqDispTimeStr"); //周频次
		            
		            var ExpStr=OrderStageCode+"^"+MustEnter+"^"+OrderPackUOM;
			        ExpStr=ExpStr+"^"+OrderSpeedFlowRate+"^"+OrderFlowRateUnitRowId+"^"+OrderBodyPartLabel+"^"+OrderSkinTest+"^"+OrderActionRowid+"^"+Urgent;
			        ExpStr=ExpStr+"^"; //计费组套餐明细编号
					ExpStr=ExpStr+"^"+OrderFreqTimeDoseStr+"^"+OrderFreqWeekStr; //同频次不同剂量、周频次
			        
		            var ret = tkMakeServerCall('web.DHCARCOrdSets', 'InsertItem', Arcosrowid, OrderARCIMRowid, OrderPackQty, OrderDoseQty, OrderDoseUOM, OrderFreqRowID, OrderDurRowid, OrderInstrRowID, OrderMasterSeqNo, OrderDepProcNote, OrderPriorRowid, SampleId, "", OrderPriorRemarks,OrderRecDepRowid,ExpStr);
		        
		    }
	}
    return websys_cancel();
}
function SetSaveForUserClickHandler() {
    var rowids = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    if (rowids == null || rowids.length == 0) {
        $.messager.alert("警告", "请选择行");
        return;
    }
    var SuccessCount = 0;
    var len = rowids.length;
    for (var i = 0; i < len; i++) {
        var OrderType = GetCellData(rowids[i], "OrderType");
        var OrderName = GetCellData(rowids[i], "OrderName");
        if (OrderType != "R") {
            $.messager.alert("警告", $g("医嘱项:[") + OrderName + $g("]不是药品,不允许添加!"));
            continue;
        }
        var ret = OtherMenuUpdate("User", session["LOGON.USERID"], rowids[i]);
        if (parseFloat(ret) > 0) {
            SuccessCount = SuccessCount + 1
        }
    }
    if (parseFloat(SuccessCount) > 0) {
        $.messager.alert("提示", $g("有") + SuccessCount + $g("条记录保存成功."));
    }
    return websys_cancel();
}
function OtherMenuUpdate(ContralType, ContralKey, rowid) {
    try {
        var SeccessCount = 0;
        var ContralStr = "";
        ContralStr = GetContralStr(ContralType, ContralKey, rowid);
        if (ContralStr == "") return "";
        var OrderName = GetCellData(rowid, "OrderName");
        var UserID = session["LOGON.USERID"];
        var ret = cspRunServerMethod(GlobalObj.SaveItemDefaultMethod, ContralStr, UserID);
        var TempArr = ret.split("^");
        if (TempArr[0] == '0') { SeccessCount = SeccessCount + 1; 
        } else if (TempArr[0] == '-100') {
            $.messager.alert("警告", $g("医嘱项:[") + OrderName + $g("],保存失败,错误代码:-100!")) 
        } else if (TempArr[0] == '-101') {
            $.messager.alert("警告", $g("医嘱项:[") + OrderName + $g("],保存失败,存在相同的记录")) 
        } else {}

    } catch (e) { $.messager.alert("警告", e.message) }
    return SeccessCount;
}

function GetContralStr(ContralType, ContralKey, rowid) {
    var OrderName = GetCellData(rowid, "OrderName");
    var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    var OrderType = GetCellData(rowid, "OrderType");
    var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
    var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
    OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
    var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
    var OrderFreq = GetCellData(rowid, "OrderFreq");
    var OrderFreqFactor = GetCellData(rowid, "OrderFreqFactor");
    var OrderDurRowid = GetCellData(rowid, "OrderDurRowid");
    var OrderDur = GetCellData(rowid, "OrderDur");
    var OrderDurFactor = GetCellData(rowid, "OrderDurFactor");
    var OrderInstrRowid = GetCellData(rowid, "OrderInstrRowid");
    var OrderInstr = GetCellData(rowid, "OrderInstr");
    var OrderDoseQty = GetCellData(rowid, "OrderDoseQty");
    var OrderDoseUOMRowid = GetCellData(rowid, "OrderDoseUOMRowid");
    var OrderDoseUOM = GetCellData(rowid, "OrderDoseUOM");

    var OrderPackQty = GetCellData(rowid, "OrderPackQty");
    var OrderPackUOMRowid = GetCellData(rowid, "OrderPackUOMRowid");
    var OrderSeqNo = GetCellData(rowid, "id");
    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
    var PHPrescType = GetCellData(rowid, "OrderPHPrescType");
    var OrderConFac = GetCellData(rowid, "OrderConFac");
    var OrderBaseQty = GetCellData(rowid, "OrderBaseQty");
    var OrderPrice = GetCellData(rowid, "OrderPrice");
    var OrderStartDateStr = GetCellData(rowid, "OrderStartDate");
    var OrderStartDate = "";
    if (OrderStartDateStr != "") {
        OrderStartDate = OrderStartDateStr.split(" ")[0];
    }
    var OrderPHForm = GetCellData(rowid, "OrderPHForm");
    var OrderItemSum = GetCellData(rowid, "OrderSum");
    var OrderEndDateStr = GetCellData(rowid, "OrderEndDate");
    var OrderEndDate = "";
    if (OrderStartDateStr != "") {
        OrderEndDate = OrderEndDateStr.split(" ")[0];
    }
    var OrderAlertStockQty = GetCellData(rowid, "OrderAlertStockQty");
    var OrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    var OrderPackUOM = GetCellData(rowid, "OrderPackUOMRowid");
    var OrderFirstDayTimes = GetCellData(rowid, "OrderFirstDayTimes");
    var OrderSkinTest = GetCellData(rowid, "OrderSkinTest");
    var OrderActionRowid = GetCellData(rowid, "OrderActionRowid");
    var OrderAction = GetCellData(rowid, "OrderAction");
    var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    var OrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
    var Notes = GetCellData(rowid, "OrderDepProcNote");
    var OrderSpeedFlowRate = GetCellData(rowid, "OrderSpeedFlowRate");
    var OrderFlowRateUnit = GetCellData(rowid, "OrderFlowRateUnitRowId");
    var ExceedReasonID = GetCellData(rowid, "ExceedReasonID");
    var OrderFreqTimeDoseStr= GetCellData(rowid, "OrderFreqTimeDoseStr");
    if (OrderFreqTimeDoseStr!="") OrderDoseQty="";
    var OrderFreqDispTimeStr= GetCellData(rowid, "OrderFreqDispTimeStr");
    
    //审查判断
    if (OrderARCIMRowid == "") {
        $.messager.alert("提示",t["NoItem"]);
        return "";
    }
    if (ContralKey == "") {
        $.messager.alert("提示",t["NoContralType"]);
        return "";
    }

    var ContralStr = OrderARCIMRowid + "^" + ContralType + "^" + ContralKey + "^" + OrderPriorRowid + "^" + OrderDoseQty + "^" + OrderDoseUOMRowid;
    ContralStr = ContralStr + "^" + OrderInstrRowid + "^" + OrderFreqRowid + "^" + OrderDurRowid + "^" + OrderPackQty + "^" + OrderSkinTest;
    ContralStr = ContralStr + "^" + OrderActionRowid + "^" + OrderMasterSeqNo + "^" + OrderSeqNo + "^" + Notes + "^" + GlobalObj.PAAdmType;
    ContralStr = ContralStr + "^" + ExceedReasonID +"^"+ OrderSpeedFlowRate + "^" + OrderFlowRateUnit;
    ContralStr = ContralStr + "^" + OrderFreqTimeDoseStr +"^"+ OrderFreqDispTimeStr +"^"+ OrderPackUOMRowid;
    return ContralStr;
}
//同步子医嘱首日次数
function OrderFirstDayTimeschangehandler(e) {
    var rowid = GetEventRow(e);
    var OrderFirstDayTimesCode=GetCellData(rowid, "OrderFirstDayTimesCode");
    var OrderFirstDayTimes=GetCellData(rowid, "OrderFirstDayTimes");
    if (OrderFirstDayTimesCode!=OrderFirstDayTimes){
    	SetCellData(rowid, "OrderFirstDayTimes", OrderFirstDayTimesCode);
		SetPackQty(rowid,{IsNotChangeFirstDayTimeFlag:"Y"});
		ChangeFirstDayTimes(rowid,false,function(){});
    }
}
function ChangeFirstDayTimes(rowid,CalFreqTimeDoseStrFlag,callBackFun) {
	new Promise(function(resolve,rejected){
		var OrderFreqTimeDoseStr = GetCellData(rowid, "OrderFreqTimeDoseStr");
		if(CalFreqTimeDoseStrFlag||(OrderFreqTimeDoseStr.indexOf("@")>-1)){
			ChangeOrderFreqTimeDoseStr(rowid,resolve);
		}else{
			resolve();
		}
	}).then(function(){
		return new Promise(function(ParResolve,rejected){
			var OrderFirstDayTimes = GetCellData(rowid, "OrderFirstDayTimes");
			var OrderFirstDayTimesStr = GetCellData(rowid, "OrderFirstDayTimesStr");
			var rowids = GetMasterSeqNo(rowid);
			var LoopChildRow=function(i){
				if(i>=rowids.length){
					ParResolve();
					return;
				}
				SetColumnList(rowids[i],"OrderFirstDayTimesCode",OrderFirstDayTimesStr);
				SetCellData(rowids[i], "OrderFirstDayTimesCode", OrderFirstDayTimes);
				SetCellData(rowids[i], "OrderFirstDayTimes", OrderFirstDayTimes);
				new Promise(function(resolve){
					var OrderFreqTimeDoseStr = GetCellData(rowids[i], "OrderFreqTimeDoseStr");
					if(CalFreqTimeDoseStrFlag||(OrderFreqTimeDoseStr.indexOf("@")>-1)){
						ChangeOrderFreqTimeDoseStr(rowids[i],resolve);
					}else{
						resolve();
					}
				}).then(function(){
					SetPackQty(rowids[i],{IsNotChangeFirstDayTimeFlag:"Y"});
					LoopChildRow(++i);
				});
			}
			LoopChildRow(0);
		});
	}).then(function(){
		if(callBackFun) callBackFun();
	});
}
function OrderFirstDayTimeskeypresshandler(e) {
    try { keycode = websys_getKey(e); } catch (e) { keycode = websys_getKey(); }
    if (keycode == 45) { window.event.keyCode = 0; return websys_cancel(); }

    if ((keycode > 47) && (keycode < 58)) {} else if (keycode == 13) {
        OrderFirstDayTimeschangehandler(e);
    } else {
        window.event.keyCode = 0;
        return websys_cancel();
    }
}
//需要配液
function OrderNeedPIVAFlagChangehandler(e) {
    try {
        var rowid = GetEventRow(e);
        CancelNeedPIVA(rowid)
    } catch (e) { $.messager.alert("警告", e.message) }
}
//部位说明改变
function OrderBodyPartchangehandler(e) {
    try {
        var rowid = GetEventRow(e);
        var obj = websys_getSrcElement(e);
        var OrderBodyPartID = obj.value;

        SetCellData(rowid, "OrderBodyPartID", OrderBodyPartID);

        ChangeLinkOrderBodyPart(rowid);
    } catch (e) { $.messager.alert("警告", e.message) }
}

function CancelNeedPIVA(rowid) {
    var OrderNeedPIVAFlag = GetCellData(rowid, "OrderNeedPIVAFlag");
    var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
    if (OrderNeedPIVAFlag == "Y") {
        OrderNeedPIVAFlag = true;
        var OrderPackQtyStyleObj = { OrderPackQty: false, OrderPackUOM: false }
    } else {
        OrderNeedPIVAFlag = false;
        var OrderPackQtyStyleObj = ContrlOrderPackQty(rowid);
    }
    if (OrderNeedPIVAFlag) { 
    	SetPackQty(rowid,{IsNotChangeFirstDayTimeFlag:'Y'});
    	SetCellData(rowid, "OrderPackQty", ""); } else { 
        var OrderPackQty = GetCellData(rowid, "OrderPackQty");
        if ((OrderPackQtyStyleObj.OrderPackQty)&&(OrderPackQty!="")){
	    }else{
		    SetPackQty(rowid,{IsNotChangeFirstDayTimeFlag:'Y'});
		}
    }
    ChangeCellDisable(rowid, OrderPackQtyStyleObj);
    var RowArry = GetSeqNolist(rowid);
    
    for (var i = 0; i < RowArry.length; i++) {
	    var OrderType = GetCellData(RowArry[i], "OrderType");
    	if (OrderType!="R") continue;
    	var EditStatus = GetEditStatus(RowArry[i]);
		if (EditStatus){
			var OrderNeedPIVAFlagVal=OrderNeedPIVAFlag;
		}else{
			var OrderNeedPIVAFlagVal=OrderNeedPIVAFlag?"Y":"N";
		}
        SetCellData(RowArry[i], "OrderNeedPIVAFlag", OrderNeedPIVAFlagVal);
        if (OrderNeedPIVAFlag) { 
        	SetCellData(RowArry[i], "OrderPackQty", ""); 
        } else { 
        	SetPackQty(RowArry[i],{IsNotChangeFirstDayTimeFlag:'Y'}); 
        	var OrderPackQtyStyleObj = ContrlOrderPackQty(RowArry[i]);
        }
        ChangeCellDisable(RowArry[i], OrderPackQtyStyleObj);
    }
}
function ChangeLinkOrderBodyPart(Row) {
    try {
        var OrderBodyPart = GetCellData(Row, "OrderBodyPart");
        var OrderBodyPartID = GetCellData(Row, "OrderBodyPartID");
        var RowArry = GetSeqNolist(Row);
        for (var i = 0; i < RowArry.length; i++) {
            SetCellData(RowArry[i], "OrderBodyPart", OrderBodyPartID);
            SetCellData(RowArry[i], "OrderBodyPartID", OrderBodyPartID);
        }
    } catch (e) { dhcsys_alert(e.message) }
}
//医嘱阶段改变
function OrderStagechangehandler(e) {
    try {
        var rowid = GetEventRow(e);
        var obj = websys_getSrcElement(e);
        var OrderStageCode = obj.value;

        SetCellData(rowid, "OrderStageCode", OrderStageCode);

        ChangeLinkOrderStage(rowid);
    } catch (e) { $.messager.alert("警告", e.message) }
}
function ChangeLinkOrderStage(Row) {
    try {
        var OrderStage = GetCellData(Row, "OrderStage");
        var OrderStageCode = GetCellData(Row, "OrderStageCode");
        var RowArry = GetSeqNolist(Row)
        for (var i = 0; i < RowArry.length; i++) {
	        var EditStatus = GetEditStatus(RowArry[i]);
            if (EditStatus == true) {
                SetCellData(RowArry[i], "OrderStage", OrderStageCode);
            }else{
	            var OrderStage = GetCellData(Row, "OrderStage");
	            SetCellData(RowArry[i], "OrderStage", OrderStage);
	        }
            //SetCellData(RowArry[i], "OrderStage", OrderStageCode);
            SetCellData(RowArry[i], "OrderStageCode", OrderStageCode);
        }
    } catch (e) { dhcsys_alert(e.message) }
}
function AntUseReasonchangehandler(e) {
    try {
        var rowid = GetEventRow(e);
        var obj = websys_getSrcElement(e);
        var AntUseReasonRowid = obj.value;
        SetCellData(rowid, "AntUseReasonRowid", AntUseReasonRowid);
    } catch (e) { $.messager.alert("警告", e.message) }
}
// 数量控制  返回 OrderPackQty{} 
function ContrlOrderPackQty(rowid,ContrlOrderPackQtArg) {
	var OrderMasterARCIMRowid="";
	if (typeof ContrlOrderPackQtArg=="object"){
		var PriorRowid=ContrlOrderPackQtArg.OrderPriorRowid;
		var OrderPriorRemarks = ContrlOrderPackQtArg.OrderPriorRemarks;
		var OrderFreqRowid = ContrlOrderPackQtArg.OrderFreqRowid;
		var OrderARCIMRowid = ContrlOrderPackQtArg.OrderARCIMRowid;
		var OrderRecDepRowid = ContrlOrderPackQtArg.OrderRecDepRowid;
		var OrderMasterARCIMRowid=ContrlOrderPackQtArg.OrderMasterARCIMRowid;
		var OrderVirtualtLong=(typeof ContrlOrderPackQtArg.OrderVirtualtLong!="undefined")?ContrlOrderPackQtArg.OrderVirtualtLong:"N";
		var ContrlOrderPackQtArg=null;
	}else{
		var PriorRowid = GetCellData(rowid, "OrderPriorRowid");
		var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId"); //OrderPriorRemarks
		var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
		var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
		var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
		var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
		if (OrderMasterSeqNo!=""){
			var rowids = GetAllRowId();
	        for (var i = 0; i < rowids.length; i++) {
				var OrderSeqNo = GetCellData(rowids[i], "id")
	            var OrderSeqNoMasterLink = GetCellData(rowids[i], "id");
	            if (OrderSeqNoMasterLink == OrderMasterSeqNo) {
	            	OrderMasterARCIMRowid=GetCellData(rowids[i], "OrderARCIMRowid");
	            	break;
	            }
	        }
		}
		var OrderVirtualtLong=GetCellData(rowid, "OrderVirtualtLong");
	}
	if (OrderARCIMRowid==""){
		return {};
	}
    var OrderPackQtyObj = { OrderPackQty: true, OrderPackUOM: true };
	var EpisodeID=GlobalObj.EpisodeID;
    var OrderPriorRowid = ReSetOrderPriorRowid(PriorRowid, OrderPriorRemarks);
	
	var ret = cspRunServerMethod(GlobalObj.ContrlOrderPackQtyMethod, EpisodeID, OrderPriorRowid, session['LOGON.CTLOCID'], OrderARCIMRowid, OrderMasterARCIMRowid, OrderRecDepRowid,OrderVirtualtLong);
	var OrderPackQtyStyle = mPiece(ret, "^", 0);
	var OrderPackUOMStyle = mPiece(ret, "^", 1);
	var SetOrderPackQtyValue = mPiece(ret, "^", 2);
	if (OrderPackQtyStyle=="0"){
		OrderPackQtyObj.OrderPackQty = false;
	}
	if (OrderPackUOMStyle=="0"){
		OrderPackQtyObj.OrderPackUOM = false;
	}
	if ((SetOrderPackQtyValue!="false")&&(SetOrderPackQtyValue!="true")){
		SetCellData(rowid, "OrderPackQty", SetOrderPackQtyValue)
	}
    return OrderPackQtyObj
}
//相互作用
function XHZY_Click() {
	if (GlobalObj.HLYYInterface==1){
		//XHZYClickHandler_HLYY();
		Common_ControlObj.Interface("XHZY",{
			EpisodeID:GlobalObj.EpisodeID
		});
	}else{
	   //知识库
       var rtnZSK =CheckLibPhaFunction("C", "", "")
	}
}
// 药品说明书
function YDTS_Click(rowid) {
	if(!rowid){
		var ids =$('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
		//没有选择医嘱弹出基础数据平台知识库
		/*if(!ids.length){
			websys_showModal({
				url:"dhc.bdp.kb.dhchisinstructions.csp",
				title:'说明书',
				width:screen.availWidth-200,height:screen.availHeight-200
			});
		}
		*/
		rowid=ids[0];
	}
	if(CheckIsClear(rowid)){
		$.messager.alert("警告", "请选择有效医嘱","warning");
		return;
	}
	var OrderType = GetCellData(rowid, "OrderType");
	var ARCIMRowid = GetCellData(rowid,"OrderARCIMRowid");
	//只有药品才走合理用药
	if((GlobalObj.HLYYInterface==1)&&(OrderType=='R')){
		//HLYYYDTS_Click(rowid);
		Common_ControlObj.Interface("YDTS",{
			ARCIMRowid:ARCIMRowid
		});
	}else if(Common_ControlObj.LibPhaFunc.ZSKOpenFlag=="Y"){
		//知识库
	    LinkMesageZSQ(rowid)
	}else{
		$.messager.alert("提示", "未启用或未维护相应说明书","warning");	
	}
}
//补录关联医嘱
function SetVerifiedOrder(itemids) {
    $("#Prompt").html("");
    if (!VerifiedOrderObj) return;
    if ((VerifiedOrderObj.LinkedMasterOrderRowid==itemids)&&(itemids=="")){
		return;
	}
	var LinkMastStr = "^^^^^^";
	// "护嘱"勾选,则清空已进行补录的医嘱
	if ($("#NurseOrd").checkbox('getValue')) {
		for (key in VerifiedOrderObj) {
	        VerifiedOrderObj[key] = "";
	    }
		// 置空关联
    	NurseAddMastOrde(LinkMastStr);
    	LoadLinkedMasterOrdInfo();
    	window.setTimeout(function(){
            $("tr.jqgrow").css("background","#FFCCCC");
        }, 0);
    	return;
	}else{
		if (itemids=="") {
			for (key in VerifiedOrderObj) {
		        VerifiedOrderObj[key] = "";
		    }
			// 置空关联
			NurseAddMastOrde(LinkMastStr);
			return;
		}
		var itemArr = itemids.split("^");
		// 取第一条 主医嘱
	    var itemid = itemArr[0];
	    var oneItem = cspRunServerMethod(GlobalObj.GetVerifiedOrder, itemid);
	    var VerifiedOrderArr = oneItem.split("^");
	    var Flag = VerifiedOrderArr[0];
	    if (Flag != "0") {
	        $("#Prompt").html($g("提示信息:") + $g(Flag));
	        for (key in VerifiedOrderObj) {
		        VerifiedOrderObj[key] = "";
		    }
	        // 置空关联
			NurseAddMastOrde(LinkMastStr);
	        return;
	    }
	    if (VerifiedOrderArr.length==1){
		    for (key in VerifiedOrderObj) {
		        VerifiedOrderObj[key] = "";
		    }
		    // 置空关联
    		NurseAddMastOrde(LinkMastStr);
    		return;
		}
		var OrderObj=GetVerifiedOrderObjObj(VerifiedOrderArr);
	    /*var OrderObj = {
            LinkedMasterOrderName: "",
            LinkedMasterOrderRowid: "",
            LinkedMasterOrderSeqNo: "",
            LinkedMasterOrderPriorRowid: "",
            LinkedMasterOrderFreRowId: "",
            LinkedMasterOrderFreFactor: "",
            LinkedMasterOrderFreInterval: "",
            LinkedMasterOrderFreDesc: "",
            LinkedMasterOrderFreqDispTimeStr:""
        }
        OrderObj.LinkedMasterOrderName = VerifiedOrderArr[1];
	    OrderObj.LinkedMasterOrderRowid = VerifiedOrderArr[2];
	    OrderObj.LinkedMasterOrderSeqNo = VerifiedOrderArr[3];
	    OrderObj.LinkedMasterOrderPriorRowid = VerifiedOrderArr[4];
	    var OrderFreStr = VerifiedOrderArr[5];
	    OrderObj.LinkedMasterOrderFreRowId = mPiece(OrderFreStr, String.fromCharCode(1), 0);
	    OrderObj.LinkedMasterOrderFreFactor = mPiece(OrderFreStr, String.fromCharCode(1), 1);
	    OrderObj.LinkedMasterOrderFreInterval = mPiece(OrderFreStr, String.fromCharCode(1), 2);
	    OrderObj.LinkedMasterOrderFreDesc = mPiece(OrderFreStr, String.fromCharCode(1), 3);
	    OrderObj.LinkedMasterOrderFreqDispTimeStr = mPiece(OrderFreStr, String.fromCharCode(1), 4);
	    OrderObj.LinkedMasterOrderFreqDispTimeStr=OrderObj.LinkedMasterOrderFreqDispTimeStr.split(String.fromCharCode(13)).join(String.fromCharCode(1));
	    OrderObj.LinkedMasterOrderSttDate = VerifiedOrderArr[6];*/
	    var OrderFreStr = VerifiedOrderArr[5];
	    var LessCurDateMsg="";
	    var SttDateLessCurDateFlag=VerifiedOrderArr[7];
	    if (SttDateLessCurDateFlag =="Y") {
		    LessCurDateMsg=$g("非今日长嘱，注意手工补录")+OrderObj.LinkedMasterOrderSttDate.split(" ")[0]+$g("前的临时医嘱！");
		}
	    LinkMastStr = OrderObj.LinkedMasterOrderRowid + "^" + OrderObj.LinkedMasterOrderSeqNo + "^" + OrderObj.LinkedMasterOrderPriorRowid + "^" + OrderFreStr+ "^"+ OrderObj.LinkedMasterOrderSttDate;
	    LinkMastStr = LinkMastStr+ "^" + OrderObj.LinkedMasterOrderInstr+ "^" + OrderObj.LinkedMasterOrderInstrRowid;
	    $("#Prompt").html("<font COLOR=RED>"+$g("当前主医嘱: ") + OrderObj.LinkedMasterOrderName + "   "+$g("医嘱ID:") + OrderObj.LinkedMasterOrderRowid + " "+LessCurDateMsg + "</font>"); //"   医嘱ID:" + OrderObj.LinkedMasterOrderRowid +
		$.extend(VerifiedOrderObj, OrderObj);
	    //验证已经录入到界面的医嘱进行关联
	    NurseAddMastOrde(LinkMastStr);
	    Add_Order_row();
	    var rowidsSub = $('#Order_DataGrid').getDataIDs();
        for (var Sub = 0; Sub < rowidsSub.length; Sub++) {
            var OrderARCIMRowid = GetCellData(rowidsSub[Sub], "OrderARCIMRowid");
            var OrderPriorRowid=GetCellData(rowidsSub[Sub], "OrderPriorRowid");
            if (OrderARCIMRowid =="") {
	            var LinkedMasterOrderPriorLongFlag=IsLongPrior(VerifiedOrderObj.LinkedMasterOrderPriorRowid);
	            // 主医嘱是长期医嘱,补录的子医嘱可以是长期
	            if ((LinkedMasterOrderPriorLongFlag)&&(!IsLongPrior(OrderPriorRowid))&&(OrderPriorRowid!=GlobalObj.OutOrderPriorRowid)) continue;
	        	var EditStatus = GetEditStatus(rowidsSub[Sub]);
	        	//强制模式
                if (GlobalObj.OrderPriorContrlConfig == 1) {
	                if (LinkedMasterOrderPriorLongFlag) {
		                SetCellData(rowidsSub[Sub], "OrderPriorRowid", GlobalObj.LongOrderPriorRowid);
		                var OrderPriorStr = GlobalObj.LongOrderPriorRowid + ":" + $g("长期医嘱");
	                    SetColumnList(rowidsSub[Sub], "OrderPrior", OrderPriorStr);
	                    SetCellData(rowidsSub[Sub], "OrderPriorStr", OrderPriorStr);
		                if (EditStatus) {
			                SetCellData(rowidsSub[Sub], "OrderPrior", GlobalObj.LongOrderPriorRowid);
			            }else{
				            SetCellData(rowidsSub[Sub], "OrderPrior", $g("长期医嘱"));
				        }
		            }else{
			            SetCellData(rowidsSub[Sub], "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
		                var OrderPriorStr = GlobalObj.ShortOrderPriorRowid + ":" + $g("临时医嘱");
	                    SetColumnList(rowidsSub[Sub], "OrderPrior", OrderPriorStr);
	                    SetCellData(rowidsSub[Sub], "OrderPriorStr", OrderPriorStr);
		                if (EditStatus) {
			                SetCellData(rowidsSub[Sub], "OrderPrior", GlobalObj.ShortOrderPriorRowid);
			            }else{
				            SetCellData(rowidsSub[Sub], "OrderPrior", $g("临时医嘱"));
				        }
			        }
	            }else{
		            if (LinkedMasterOrderPriorLongFlag) {
			            SetCellData(rowidsSub[Sub], "OrderPrior", GlobalObj.LongOrderPriorRowid);
			            SetCellData(rowidsSub[Sub], "OrderPriorRowid", GlobalObj.LongOrderPriorRowid);
			        }else{
				        SetCellData(rowidsSub[Sub], "OrderPrior", GlobalObj.ShortOrderPriorRowid);
				        SetCellData(rowidsSub[Sub], "OrderPriorRowid", GlobalObj.ShortOrderPriorRowid);
				    }
		        }
		        
	        }
         }
	}
}
function NurseOrdClickHandler(value){
    if (value) {
        SetVerifiedOrder("");
        window.setTimeout(function(){
            $("tr.jqgrow").css("background","#FFCCCC");
        }, 0);
    }else{
        // $("#orderListShow")[0].contentWindow.ipdoc.patord.view.SetVerifiedOrder(true);
         window.setTimeout(function(){
            $("tr.jqgrow").css("background","");
        }, 0);
    }
}
function ShowNotPayOrdClickHandler(){
	ReloadGrid("update","");
}
function LoadLinkedMasterOrdInfo(){
    ReloadGrid("LoadLinked");
}
/// 护士审核完医嘱后，自动选中医嘱列表中的下一组医嘱列表
function ReloadGridData(Progress){
	/*
	ExaReport:检查检验申请界面关闭时回调
	Update:审核医嘱后回调
	*/
	PageLogicObj.fpArr=[];
    var LinkedMasterOrderRowid=VerifiedOrderObj?VerifiedOrderObj.LinkedMasterOrderRowid:'';
    if(LinkedMasterOrderRowid!=""){
        if (Progress=="Update"){
            ClearSessionData();
            var rowids = $('#Order_DataGrid').getDataIDs();
            for (var i = 0; i < rowids.length; i++) {
                var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
                var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
                if ((OrderItemRowid == "") || (OrderARCIMRowid != "")) {
                    $('#Order_DataGrid').delRowData(rowids[i]);
                }
            }
			$("#ScreenBillSum").val(0.00);
        }
		Add_Order_row();
        RefreshOderList("Next");
    }else{
        ReloadGrid();
        RefreshOderList();
    }
}

function ClearVerifiedOrder() {
    $("#Prompt").html("");
    for (key in VerifiedOrderObj) {
        VerifiedOrderObj[key] = "";
    }
    //护士补录医嘱刷新清除右侧选中，清除已经关联的关系
    try {
        var par_win = window.parent.parent.parent.left.RPbottom
        if (par_win) {
            par_win.ClearCheck();
            NurseAddMastOrde("^^^^^^", "");
        }
    } catch (e) {

    }
}
//抗菌药物审查接口入口
function ICheckDoctorTypePoison(OrderPoisonRowid, icode, Row, OrderPoisonCode, callBackFun) {
	new Promise(function(resolve,rejected){
		CheckDoctorTypePoison_7(OrderPoisonRowid, icode, Row, OrderPoisonCode,resolve);
	}).then(function(PrescCheck){
		callBackFun(PrescCheck);
	})
    /*var PrescCheck = CheckDoctorTypePoison_7(OrderPoisonRowid, icode, Row, OrderPoisonCode);
    if (PrescCheck == false) { return false; }*/
}
function DeleteAntReason(CurrentRow) {
    var UserReasonId = GetCellData(CurrentRow, "UserReasonId");
    if ((UserReasonId != "") && (GlobalObj.ReasonCanBeDeletedMethod != "")) {
        var rtn = cspRunServerMethod(GlobalObj.ReasonCanBeDeletedMethod, UserReasonId);
        if ((rtn == 1) && (GlobalObj.DeleteAntReasonMethod != "")) {
            var ret = cspRunServerMethod(GlobalObj.DeleteAntReasonMethod, UserReasonId);
        }
    }
}
//添加 抗菌药物检查方法。
function CheckAuditItem() {
    if (GlobalObj.AuditFlag == 1) { GlobalObj.AuditFlag = ""; return true; } else { return false; }
}
function CheckSuscept(episodeid, arcim) {
    var ret = 0;
    if (GlobalObj.CheckSusceptMethod != "") {
        var ret = cspRunServerMethod(GlobalObj.CheckSusceptMethod, episodeid, arcim);
        return ret;
    }
    return ret
}
function CheckInDurSameIM(ImRowid, Row) {
    var EpisodeID = GlobalObj.EpisodeID
    var flag = false;
    if (GlobalObj.CheckInDurSameIMMethod != "") {
        var ret = cspRunServerMethod(GlobalObj.CheckInDurSameIMMethod, EpisodeID, ImRowid);
        var retArr = ret.split("^")
        var ret1 = retArr[0];
        if (ret1 == 2) {
            var UserReasonID = retArr[1];
            SetCellData(Row, "UserReasonId", UserReasonID)
            flag = true
        }
    }
    return flag;
}
function CheckCMMRDiagnos(itemCatRowID) {
    //$.messager.alert("警告",itemCatRowID);
    var flag = false;
    var ret = tkMakeServerCall("web.DHCDocIPBookingCtl", "GetCMMRDiagnosByEpisode", GlobalObj.EpisodeID);
    //没有中医诊断
    if (ret == "N") {
        var MedItemCat = MedItemCatStr.split("^")
        for (var i = 0; i < MedItemCat.length; i++) {
            if (MedItemCat[i] == itemCatRowID) {
                flag = true;
            }
        }
    } else {
        flag = true;
    }
    return flag;
}

//打开处方打印界面--20150108--lrf
function PrescriptList() {
    var posn = "height=" + (screen.availHeight - 40) + ",width=" + (screen.availWidth - 10) + ",top=0,left=0,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes";
    var path = "websys.default.csp?WEBSYS.TCOMPONENT=UDHCPrescript.Print&PatientID=" + GlobalObj.PatientID + "&EpisodeID=" + GlobalObj.EpisodeID + "&mradm=" + GlobalObj.mradm + "&WardID=";
    websys_createWindow(path, false, posn);
}
//打开治疗单界面--20150108--lrf
function LabPrintList() {
    var posn = "height=" + (screen.availHeight - 40) + ",width=" + (screen.availWidth - 10) + ",top=0,left=0,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,resizable=yes";
    var path = "websys.default.csp?WEBSYS.TCOMPONENT=UDHCOrderItem.Lab.Print&PatientID=" + GlobalObj.PatientID + "&EpisodeID=" + GlobalObj.EpisodeID + "&mradm=" + GlobalObj.mradm + "&WardID=";
    websys_createWindow(path, false, posn);
}
function CheckPermissionByARC(icode, OrderDesc) {
    return true;
    try {
        var ret = tkMakeServerCall("web.DHCST.Common.DrugInfoCommon", "GetMangerDrugByARC", icode);
        if ((ret == "") || (ret == null)) return true;
        ret = ret.split("^");
        var UserID = session['LOGON.USERID'];

        var MangerDrug = MangerDrugStr.split("^");

        for (var i = 0; i < MangerDrugStr.length; i++) {
            if (ret[1] == MangerDrug[i]) {
                var flag = tkMakeServerCall("web.DHCDocCommon", "GetPermissionsByUserID", UserID);
                if (flag != 1) {
                    $.messager.alert("警告",OrderDesc + ",无权限开此药")
                    return false;
                }
            }
        }
    } catch (e) {}
    return true;
}

function StopOrderItem() {
    var OrdList = "";
    var MastRowId = "";
    var NeedStopOrdArr = new Array();
    var rowids = GetAllRowId();
    for (var i = 0; i < rowids.length; i++) {
        //取子医嘱
        if ((document.getElementById("jqg_Order_DataGrid_" + rowids[i]).checked != true))
            continue;
        if (CheckIsItem(rowids[i]) == false) { continue; }
        var OEORIRowId = GetCellData(rowids[i], "OrderItemRowid");
        if (OEORIRowId==""){continue;}
        NeedStopOrdArr.push(rowids[i]);
    }

    if (NeedStopOrdArr.length>0) {
	    new Promise(function(resolve,rejected){
			StopOrd(NeedStopOrdArr,resolve);
		}).then(function(){
			ReloadGrid("StopOrd");
		    OrderMsgChange();
		    SaveOrderToEMR();
		})
    } else {
        $.messager.alert("警告", "请在已审核项目上勾选要停止的项目");
        return true;
    }
}
//仅控制使用tab键跳转用,回车键因为焦点的不确定性(比如有弹出框)在相应的触发事件中处理跳转
function Doc_OnKeyDown(e) {
    if (GlobalObj.warning != "") {
	    $(".messager-button a").click(); //自动关闭上一个alert弹框
        $.messager.alert("警告",GlobalObj.warning);
        return false;
    }
	//防止在空白处敲退格键，界面自动回退到上一个界面
	if (!websys_cancelBackspace(e)) return false;
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
    var rowid = GetEventRow(e);
    var nextRowid = parseInt(rowid) + 1;
    var obj = websys_getSrcElement(e);
    var name = obj.name;
    var keycode = websys_getKey(e);
    if (keycode == 9) {
	    var OrderFreqObj = document.getElementById(rowid + "_OrderFreq");
        var OrderDurObj = document.getElementById(rowid + "_OrderDur");
        var OrderPackQtyObj = document.getElementById(rowid + "_OrderPackQty");
        if (obj.id == (rowid + "_OrderInstr")) {
            if (OrderFreqObj && (OrderFreqObj.disabled == false)) {
                SetFocusCell(rowid, "OrderFreq");
            } else if (OrderDurObj && (OrderDurObj.disabled == false)) {
                SetFocusCell(rowid, "OrderDur");
            } else if (OrderPackQtyObj && (OrderPackQtyObj.disabled == false)) {
                SetFocusCell(rowid, "OrderPackQty");
            } else {
                window.setTimeout("Add_Order_row()", 200);
            }
        }
        if (obj.id == (rowid + "_OrderDoseUOM")) {
            var OrderInstrObj = document.getElementById(rowid + "_OrderInstr");
            if (OrderInstrObj && (OrderInstrObj.disabled == false)) {
                SetFocusCell(rowid, "OrderInstr");
            } else {
                SetFocusCell(rowid, "OrderFreq");
            }
        }
        if (obj.id == (rowid + "_OrderDepProcNote")) {
            window.setTimeout("Add_Order_row()", 200);
        }
        if (obj.id == (rowid + "_OrderFreq")) {
	        if (OrderDurObj && (OrderDurObj.disabled == false)) {
                SetFocusCell(rowid, "OrderDur");
            } else if (OrderPackQtyObj && (OrderPackQtyObj.disabled == false)) {
                SetFocusCell(rowid, "OrderPackQty");
            } else {
                window.setTimeout("Add_Order_row()", 200);
            }
        }
        
    }
    if ((((e.target)&&(e.target.id.indexOf("OrderDoseQty")>=0))||(PageLogicObj.LookupPanelIsShow==1))&&((keycode==40)||(keycode==38))) return;
    if(keycode==40){    //向下方向键
		JumpColCell(e.target,'down');
	}else if(keycode==38){    //向上方向键	
		JumpColCell(e.target,'up');
	}
	if ((e.keyCode==13)&&($(".window-mask").is(":visible"))){
	    return false;   
    }
}
function JumpColCell(target,type)
{
	var name=$(target).attr('name');
	if(['OrderPackQty','OrderFirstDayTimesCode','OrderDepProcNote'].indexOf(name)==-1) return false;
	var $tr=$(target).closest('tr.jqgrow');
	if(!$tr.length) return false;
	var $row=(type=='up'?$tr.prev():$tr.next());
	if(!$row.length) return false;
	var rowid=$row.attr('id');
	if(CheckIsItem(rowid)) return false;
	if(!GetEditStatus(rowid)){
		EditRow(rowid);
	}
	var $elm=$row.children().children('[name="'+name+'"]');
	if($elm.attr('disabled')=='disabled'||$elm.hasClass('disable')) 
		return JumpColCell($elm[0],type);
	$elm.select();
	return false;
}
//输液次数change事件
function OrderLocalInfusionQty_changehandler(e) {
    var Row = GetEventRow(e);
	GetBindOrdItemTip(Row);
    ChangeLinkOrderLocalInfusionQty(Row);
}
//输液次数同步  
function ChangeLinkOrderLocalInfusionQty(Row) {
    try {
        var OrderLocalInfusionQtyMain = GetCellData(Row, "OrderLocalInfusionQty").replace(/(^\s*)|(\s*$)/g, '');
        var RowArry = GetSeqNolist(Row)
        for (var i = 0; i < RowArry.length; i++) {
	        var OrderType = GetCellData(RowArry[i], "OrderType");
    		if (OrderType!="R") continue;
            SetCellData(RowArry[i], "OrderLocalInfusionQty", OrderLocalInfusionQtyMain);
			GetBindOrdItemTip(RowArry[i]);
        }
    } catch (e) { dhcsys_alert(e.message) }
}
//输液流速
function OrderSpeedFlowRate_changehandler(e) {
    var Row = GetEventRow(e);
    ChangeOrderSpeedFlowRate(Row)
}
//输液流速同步  
function ChangeOrderSpeedFlowRate(Row) {
    try {
        var OrderSpeedFlowRatemain = GetCellData(Row, "OrderSpeedFlowRate").replace(/(^\s*)|(\s*$)/g, '');
        var RowArry = GetSeqNolist(Row)
        for (var i = 0; i < RowArry.length; i++) {
            var OrderInstrRowid=GetCellData(RowArry[i], "OrderInstrRowid");
            if(IsSpeedRateSeparateInstr(OrderInstrRowid)) continue;
	        var OrderType = GetCellData(RowArry[i], "OrderType");
    		if (OrderType!="R") continue;
            SetCellData(RowArry[i], "OrderSpeedFlowRate", OrderSpeedFlowRatemain)
        }
    } catch (e) { dhcsys_alert(e.message) }
}

function OrderEndDate_changehandler(e) {
    var Row = GetEventRow(e);
    ChangeLinkOrderEndDate(Row)
}

function ChangeLinkOrderEndDate(Row) {
    try {
        var OrderEndDate = GetCellData(Row, "OrderEndDate")
        var RowArry = GetSeqNolist(Row)
        for (var i = 0; i < RowArry.length; i++) {
            SetCellData(RowArry[i], "OrderEndDate", OrderEndDate)
        }
    } catch (e) { dhcsys_alert(e.message) }
}

function OrderDate_changehandler(e) {
    var Row = GetEventRow(e);
    ChangeLinkOrderDate(Row);
    //var OrderStartDate=GetCellData(Row, "OrderDate");
    var OrderDate = GetCellData(Row, "OrderDate");
    if (OrderDate!="") {
	    var CurDate=new Date();
	    var tmpOrderDate=OrderDate.split(" ")[0];
	    if (PageLogicObj.defaultDataCache=="4"){
		    var tmpOrderDate=tmpOrderDate.split("/")[2]+"/"+tmpOrderDate.split("/")[1]+"/"+tmpOrderDate.split("/")[0]
		    var tmpOrderDate = new Date(tmpOrderDate+" "+OrderDate.split(" ")[1]);
		}else{
			var tmpOrderDate = new Date(tmpOrderDate.replace(/-/g, "/")+" "+OrderDate.split(" ")[1]);
		}
		if (tmpOrderDate>CurDate) {
			SetCellData(Row, "OrderStartDate",OrderDate);
			OEORISttDatchangehandler(e);
		}
	}
    $("#"+Row+"_OrderDate").parent()[0].title=OrderDate;
    //根据开医嘱日期切换接收科室
    var ARCIMRowId = GetCellData(Row, "OrderARCIMRowid");
    if (ARCIMRowId !="") {
	    SetRecLocStr(Row);
	}
}
function ChangeLinkOrderDate(Row) {
    try {
        var OrderDate = GetCellData(Row, "OrderDate")
        var RowArry = GetSeqNolist(Row)
        for (var i = 0; i < RowArry.length; i++) {
            SetCellData(RowArry[i], "OrderDate", OrderDate);
            var obj = document.getElementById(RowArry[i]+"_OrderDate");
            if (obj) {
	            $("#"+RowArry[i]+"_OrderDate").parent()[0].title=OrderDate;
	        }else{
		        $("#"+RowArry[i]+"_OrderDate")[0].title=OrderDate;
		    }
        }
    } catch (e) { dhcsys_alert(e.message) }
}

//一键打印
function BtnPrtClickHandler() {
    var PatientID = GlobalObj.PatientID;
    var MRADMID = GlobalObj.mradm;
    var EpisodeID = GlobalObj.EpisodeID;
    var userid = session['LOGON.USERID'];
    var ctlocid = session['LOGON.CTLOCID'];
    //var PrtClick=new PrtClickInfo(EpisodeID,PatientID,MRADMID,ctlocid,userid)
    var lnk = "oeorder.printall.csp?PatientID=" + PatientID + "&EpisodeID=" + EpisodeID;
	if(typeof websys_writeMWToken=='function') lnk=websys_writeMWToken(lnk);
    window.open(lnk, true, "status=1,scrollbars=1,top=20,left=10,width=1300,height=690");

}
//判断日期是否有修改权限
//1 科室设置不允许修改日期时间,医嘱项扩展设定允许跨日，需判断
//2 科室扩展允许修改，医嘱项允许修改 需判断
//3 科室设置允许修改，医嘱项扩展不允许，不需要判断
//4 科室设置不允许修改，医嘱项扩展不允许，不需要判断
//5 医嘱项扩展设定未维护，走科室权限
// true 需要判断 不需要判断
function CheckDateTimeModifyFlag(ModifyDateTimeAuthority,IsCanCrossDay){
	if (IsCanCrossDay=="N") {
		return false;
	}else if (IsCanCrossDay=="Y") {
		return true;
	}else{
		//未进行医嘱项扩展设定,走科室权限
		if (ModifyDateTimeAuthority!="1") return false;
	}
	return true;
}
//按用法手动补录医嘱方法
function AddLinkItemToList(ParaArr, MasterOrderItemRowId, MasterOrderSeqNo, MasterOrderPriorRowid, MasterOrderFreqStr, MasterOrderStartDate, MasterOrderStartTime) {
	
	var OrdParamsArr=new Array();
	for (var i = 0,length = ParaArr.length; i < length; i++) {
		var para1 = ParaArr[i].split("!")
        var icode = para1[0];
        var seqno = para1[1];
        var ItemOrderType = para1[2];
        var linkqty = para1[4];
		if (CheckDiagnose(icode)) {
			OrdParamsArr[OrdParamsArr.length]={
				OrderARCIMRowid:icode
			};
		}
	}
	var RtnObj = AddItemToList("",OrdParamsArr, "obj", "");
	var rowid=RtnObj.rowid;
	var returnValue=RtnObj.returnValue;
	if (returnValue == true) { Add_Order_row() }
    SetVerifiedOrder(MasterOrderItemRowId);
}

//协议包装,2014-05-30,by xp,Start
//初始化需要接收科室还有医嘱项ID,注意初始化位置在前边两项之后进行附值
function GetBillUOMStr(rowid,SpecOrderPackUOMRowid) {
    if (typeof SpecOrderPackUOMRowid == "undefined") { SpecOrderPackUOMRowid="" }
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
    //取协议包装单位
    if (OrderRecDepRowid != "") {
        var BillUOMStr = cspRunServerMethod(GlobalObj.GetBillUOMStrMethod, OrderARCIMRowid, OrderRecDepRowid, "OrderEntry","",GlobalObj.PAAdmType);
        if (SpecOrderPackUOMRowid==""){
            SetColumnList(rowid, "OrderPackUOM", BillUOMStr);
            SetCellData(rowid, "OrderPackUOMStr", BillUOMStr);
        }else{
            ReSetBillUomBySpecPackUOM(rowid,BillUOMStr,SpecOrderPackUOMRowid);
            SetCellData(rowid, "OrderPackUOMStr", BillUOMStr);
        }
        OrderPackUOMchangeCommon(rowid);
    }
}
function ReSetBillUomBySpecPackUOM(rowid,BillUOMStr,SpecOrderPackUOMRowid){
    var DefaultOrderPackUOM = "";
    var DefaultOrderPackUOMDesc = "";
    var ArrData = BillUOMStr.split(String.fromCharCode(2));
    for (var i = 0; i < ArrData.length; i++) {
        var ArrData1 = ArrData[i].split(String.fromCharCode(1));
        if ((ArrData1[0] == SpecOrderPackUOMRowid)&&(SpecOrderPackUOMRowid!="")&&(SpecOrderPackUOMRowid!=undefined)) {
            var DefaultOrderPackUOM = ArrData1[0];
            var DefaultOrderPackUOMDesc = ArrData1[1];
        }
    }
    if (DefaultOrderPackUOM != "") {
        SetCellData(rowid, "OrderPackUOMRowid", DefaultOrderPackUOM);
        if (GlobalObj.isEditCopyItem=='Y') {
            SetCellData(rowid, "OrderPackUOM", DefaultOrderPackUOM);
        }else{
            SetCellData(rowid, "OrderPackUOM", DefaultOrderPackUOMDesc);
        }
        
    }
}
function OrderPackUOMchangehandler(e) {
    var Row = GetEventRow(e);
    OrderPackUOMchangeCommon(Row);
    SetPackQty(Row);
    SetScreenSum();
}
function OrderPackUOMchangeCommon(Row) {
    var Id = Row + "_" + "OrderPackUOM";
    var obj = document.getElementById(Id);
    if ((obj) && (obj.type == "select-one")) {
        var selIndex = obj.selectedIndex;
        var PackUOMRowid = ""
        if (selIndex != -1) { PackUOMRowid = obj.options[selIndex].value; }
        SetCellData(Row, "OrderPackUOMRowid", PackUOMRowid);
        SetCellData(Row, "OrderPackUOM", PackUOMRowid);
    }
    GetOrderPriceConUom(Row);
    XHZY_Click();
}
// 根据单位变化,取医嘱整包装价格-----重新计算每行和总价格
function GetOrderPriceConUom(Row) {
    var LogonDep = GetLogonLocByFlag();
    if (GlobalObj.PAAdmType != "I") {
        OrderBillTypeRowid = GetPrescBillTypeID();
    } else {
        OrderBillTypeRowid = GlobalObj.BillTypeID;
    }
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
    if ($("#OrderOpenForAllHosp").checkbox("getValue")){
	    var OrderOpenForAllHosp="1";
	}else{
		var OrderOpenForAllHosp="0";
	}
    var OrderPackUOMRowid = GetCellData(Row, "OrderPackUOMRowid");
    if (OrderPackUOMRowid == "") return;
    var OrderRecDepRowid = GetCellData(Row, "OrderRecDepRowid");
    var OrderMaterialBarCode = GetCellData(Row, "OrderMaterialBarcodeHiden");
    var ExpStr = OrderMaterialBarCode
    var retPrice = cspRunServerMethod(GlobalObj.GetOrderPriceConUomMethod, GlobalObj.EpisodeID, OrderBillTypeRowid, LogonDep, OrderARCIMRowid, OrderOpenForAllHosp, OrderPackUOMRowid, OrderRecDepRowid, ExpStr);
    var ArrPrice = retPrice.split("^");
    var Price = ArrPrice[0];
    var OrderConFac = ArrPrice[4];
    if (Price < 0) {
        $.messager.alert("警告","此接收科室下无有效医嘱项,请切换接收科室或联系相关人员处理")
        websys_setfocus('OrderRecDep');
        var Price = ""
    }
    SetCellData(Row, "OrderPrice", Price);
    SetCellData(Row, "OrderConFac", OrderConFac);
    //------------修改协议单位，改变每行价格和总价
    var OrderPackQty = GetCellData(Row, "OrderPackQty");
    OrderPackQty = OrderPackQty.replace(/(^\s*)|(\s*$)/g, '');
    if (!isNumber(OrderPackQty) || (OrderPackQty == "")) {
        OrderPackQty = 1
    }
    var OrderSum = parseFloat(Price) * OrderPackQty;
    SetCellData(Row, "OrderSum", OrderSum);
    SetScreenSum();
    //可用天数从新计算
    SetOrderUsableDays(Row)
    //转换单位和整包装数量无关
    //SetPackQty(Row);
}
//协议包装-----------end---------

//-------------医保分类 begin------------
function CreaterOrderInsurCat(rowid,ReSetInsurCatFlag) {
	if (typeof ReSetInsurCatFlag=="undefined"){
		ReSetInsurCatFlag="Y";
	}
    //医嘱项
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    //费别
    var OrderBillTypeRowid = GetCellData(rowid, "OrderBillTypeRowid");
    //医保分类
    var InsurCatStr = cspRunServerMethod(GlobalObj.GetArcimInsurCat, OrderARCIMRowid, OrderBillTypeRowid,session['LOGON.HOSPID']);
    if (InsurCatStr!=""){
	    if ((InsurCatStr.split(String.fromCharCode(2)).length>1)&&(ReSetInsurCatFlag=="Y")) {
		    SetColumnList(rowid, "OrderInsurCat", InsurCatStr);
		    SetCellData(rowid, "OrderInsurCatHideen", InsurCatStr);
		    var InsurAlertStr=tkMakeServerCall("web.DHCINSUPort","ArcimLinkTarStr",OrderARCIMRowid,OrderBillTypeRowid,session['LOGON.HOSPID']);
			websys_showModal({
				url:"../csp/dhcdocindicationschoose.hui.csp",
				title:$g('请选择医保适应症'),
				width:800,height:600,
				InsurAlertStr:InsurAlertStr.split("^").join("!"),
				showCancelBtnFlag:"N",
				closable:false,
				CallBackFunc:function(OrderInsurCatRowId){
					websys_showModal("close");
					if (typeof OrderInsurCatRowId=="undefined"){
						OrderInsurCatRowId="";
					}
					SetCellData(rowid, "OrderInsurCat", OrderInsurCatRowId);
        			SetCellData(rowid, "OrderInsurCatRowId", OrderInsurCatRowId);
        			OrderInsurCatchangeCommon(rowid);
				}
			})
		}else{
		    SetColumnList(rowid, "OrderInsurCat", InsurCatStr);
		    SetCellData(rowid, "OrderInsurCatHideen", InsurCatStr);
		    OrderInsurCatchangeCommon(rowid);
	    }
    }
}
function OrderInsurchangehandler(e) {
    var Row = GetEventRow(e);
    OrderInsurCatchangeCommon(Row)
}
function OrderInsurCatchangeCommon(Row) {
    var Id = Row + "_" + "OrderInsurCat";
    var obj = document.getElementById(Id);
    if ((obj) && (obj.type == "select-one")) {
        var selIndex = obj.selectedIndex;
        var OrderInsurCatRowId = ""
        if (selIndex != -1) { OrderInsurCatRowId = obj.options[selIndex].value; }
        SetCellData(Row, "OrderInsurCat", OrderInsurCatRowId);
        SetCellData(Row, "OrderInsurCatRowId", OrderInsurCatRowId);
    }
}
//-------------医保分类  end--------------

//-----------------------知识库接口  begin-----------------------------
//知识库接口
//Active C 较验 Q 查询  A 医嘱建议
//RowIn  具体行(初始化备注) Update审核医嘱标志
//RowIn 插叙某一行药品信息
function CheckLibPhaFunction(Active, RowIn, Update) {
    //是否开启知识库
    //if (GlobalObj.ZSKOpen != 1) { return true }
    if(Common_ControlObj.LibPhaFunc.ZSKOpenFlag!="Y"){
	    if(Active=="A"){
		    $.messager.alert("提示","未发现建议医嘱系统","warning");
	    }
	    return true;
	}
    var Type = ""
    var OrderMesage = GetCheckLibPhaOrder(RowIn)
    if ((OrderMesage == "") && (Active != "A")) { return true; }
    
    var argObj={
	    RowIn:RowIn,
	    Active:Active,
	    Update:Update,
	    EpisodeID:GlobalObj.EpisodeID,
	    dialogName:"dd",
	    OrderMesage:OrderMesage
	}
    var CheckRtn=Common_ControlObj.LibPhaFunc.CheckLibPhaFunction(argObj,CreaterTooltip);
    return CheckRtn;
}
//展示提示建议医嘱信息
function AdviceOrder(Mesage) {
	CheckLibPhaFunction("A", "", "");
}
///获取知识库医嘱信息
function GetCheckLibPhaOrder(RowIn) {
    var OrdMesage = ""
    var OrdMesageSub = ""
        ///获取一行信息
    if (RowIn != "") {
        var OrderItemRowid = GetCellData(RowIn, "OrderItemRowid");
        var OrderARCIMRowid = GetCellData(RowIn, "OrderARCIMRowid");
        var OrderType = GetCellData(RowIn, "OrderType");
        if ((OrderARCIMRowid != "") && (OrderItemRowid == "")) {
            OrdMesage = GetRowMesage(RowIn)
        }
    } else {
        ///检查所有要开医嘱冲突情况
        var rowidsSub = $('#Order_DataGrid').getDataIDs();
        for (var Sub = 0; Sub < rowidsSub.length; Sub++) {
            //过滤已审核
            var OrderItemRowid = GetCellData(rowidsSub[Sub], "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowidsSub[Sub], "OrderARCIMRowid");
            if ((OrderItemRowid != "") || (OrderARCIMRowid == "")) { continue; }

            var OrderName = GetCellData(rowidsSub[Sub], "OrderName");
            var OrderType = GetCellData(rowidsSub[Sub], "OrderType");
            OrdMesageSub = ""
            if ((OrderARCIMRowid != "") && (OrderItemRowid == "")) { //药品、检查、检验
                //var ItemServiceFlag = cspRunServerMethod(GlobalObj.GetItemServiceFlagMethod, OrderARCIMRowid);
                //if ((OrderType == "R") || (OrderType == "L") || (ItemServiceFlag == 1)) {
                    OrdMesageSub = GetRowMesage(rowidsSub[Sub])
                //}
                if (OrdMesageSub != "") {
                    if (OrdMesage == "") OrdMesage = OrdMesageSub;
                    else OrdMesage = OrdMesage + String.fromCharCode(2) + OrdMesageSub;
                }
            }
        }
    }
    return OrdMesage;
}
///获取一行医嘱信息
function GetRowMesage(RowSub) {
    var RowMesgaeGte = ""
    var OrderItemRowid = GetCellData(RowSub, "OrderItemRowid");
    var OrderARCIMRowid = GetCellData(RowSub, "OrderARCIMRowid");
    if (OrderARCIMRowid == "") { return "" }
    var OrderDurRowid = GetCellData(RowSub, "OrderDurRowid");
    var OrderFreqRowid = GetCellData(RowSub, "OrderFreqRowid");
    var OrderInstrRowid = GetCellData(RowSub, "OrderInstrRowid");
    var OrderDoseQty = GetCellData(RowSub, "OrderDoseQty");
    var OrderDoseUOMRowid = GetCellData(RowSub, "OrderDoseUOMRowid");
    var OrderDrugFormRowid = GetCellData(RowSub, "OrderDrugFormRowid");
    var OrderPHPrescType = GetCellData(RowSub, "OrderPHPrescType");

    var OrderStartDate = "";
    var OrderStartTime = "";
    var OrderStartDateStr = GetCellData(RowSub, "OrderStartDate");
    if (OrderStartDateStr != "") {
        OrderStartDate = OrderStartDateStr.split(" ")[0];
        OrderStartTime = OrderStartDateStr.split(" ")[1];
    }
    var OrderPriorRowid = GetCellData(RowSub, "OrderPriorRowid");
    var OrderPackQty = GetCellData(RowSub, "OrderPackQty");
    var OrderPackUOMDr = GetCellData(RowSub, "OrderPackUOMRowid");
    var OrderLabSpecRowid = GetCellData(RowSub, "OrderLabSpecRowid"); //标本
    var OrderOrderBodyPart = GetCellData(RowSub, "OrderBodyPartID");
    var OrderRecDepRowid = GetCellData(RowSub, "OrderRecDepRowid"); //接收科室ID
    var MasterSeqNo = ""; //关联号
    var OrderSeqNo = GetCellData(RowSub, "id"); //GetCellData(RowSub, "OrderSeqNo");
    var OrderMasterSeqNo = GetCellData(RowSub, "OrderMasterSeqNo");
    if (OrderMasterSeqNo==""){
        //如果存在子医嘱则赋值,不存在则不赋值
        var SubRowidsAry = GetMasterSeqNo(RowSub);
        if (SubRowidsAry.length > 0) {
            MasterSeqNo = "1"+String.fromCharCode(1)+OrderSeqNo;
        }else{
            MasterSeqNo = "0"+String.fromCharCode(1)+OrderSeqNo;
        }
    }else{
        MasterSeqNo="1"+String.fromCharCode(1)+OrderMasterSeqNo+"."+OrderSeqNo;
    }
    //if (OrderMasterSeqNo != "") { MasterSeqNo = "1"+String.fromCharCode(1)+OrderMasterSeqNo; } else { MasterSeqNo = OrderSeqNo; }
    RowMesgaeGte = OrderARCIMRowid + "^" + OrderInstrRowid + "^" + OrderFreqRowid + "^" + OrderDoseQty + "^" + OrderDoseUOMRowid + "^" + OrderPackQty + "^" + OrderPackUOMDr + "^" + OrderDurRowid + "^" + MasterSeqNo + "^" + OrderLabSpecRowid + "^" + OrderOrderBodyPart + "^" + OrderRecDepRowid
    return RowMesgaeGte
}
function LinkMesageZSQ(Row) {
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
   
    if (OrderARCIMRowid != "") {
	    var OrderItemRowid = GetCellData(Row, "OrderItemRowid");
	    var OrderLabSpecRowid = GetCellData(Row, "OrderLabSpecRowid"); //标本
	    var OrderBodyPartID = GetCellData(Row, "OrderBodyPartID");
	    var argObj={
		    OrderARCIMRowid:OrderARCIMRowid,
		    OrderItemRowid:OrderItemRowid,
		    OrderLabSpecRowid:OrderLabSpecRowid,
		    OrderBodyPartID:OrderBodyPartID
		}
		Common_ControlObj.LibPhaFunc.LinkMesageZSQ(argObj);
    }
}
///显示信息
/// Row 行
/// ContenStr信息
/// timeOut 停留时间
/// Type 显示模式
function CreaterTooltip(Row, ContenStr, timeOut, Type) {
    if (Type == 1) {
        //集成到了OEOrder.Common.Control.js
    } else if (Type == 2) {
        if (ContenStr == "") return;
        //初始化显示个医嘱的注释信息。提示禁忌用药信息---注释信息
        //ContenStr="适应证@头孢拉定/胶囊/$敏感菌感染!禁忌证@头孢拉定/胶囊/$对头孢类抗生素过敏者禁用!不良反应@头孢拉定/胶囊/$长期用药可致菌群失调，维生素B族。维生素K缺乏，二重感染等不良反应!注意事项@头孢拉定/胶囊/$对青霉素过敏或有过敏体质及肾功能不全者慎用/n儿童患者应用本品应谨慎并在检测下用药!!"
        //ContenStr可能超长导致url无效,将ContenStr暂存到后台获取临时ID
        var Len = Math.ceil(ContenStr.length / 1000);
        var tempContentIndex = Math.random();
        for (var i = 0; i < Len; i++) {
            var SplitItemStr = ContenStr.substr(i * 1000, 1000)
            var ret = tkMakeServerCall('web.DHCDocService', 'SettempContentIndex', tempContentIndex, session['LOGON.USERID'], i + 1, SplitItemStr);
        }
        tempContentIndex = session['LOGON.USERID'] + "^" + tempContentIndex;
        var url = "dhcdoczsk.csp?Mesage=" + "" + "&MesageType=2" + "&tempContentIndex=" + tempContentIndex;
        initItemInstrDiv(Row,url);
    } else if (Type == 3) {
        //集成到了OEOrder.Common.Control.js
    } else if (Type == 4) {
        try {
            $("#" + Row + "_" + "OrderName").tooltip("destroy");
        } catch (e) { alert(e) }
    }
}
function initDivHtml(){
	var html  = "<div id='itro_win'  class='div-notes' style='border-radius:3px; display:none; border:2px solid #20A0FF; background:#FFF; position:absolute; width:700px; height:315px;'>";
	    /// 标题栏
		html += "	<div id='itro_title_bar' style='width:100%; height:35px; background:#20A0FF;color:#fff;font-weight:bold;'>";
		html += "		<div id='itro_title' style='padding:8px;text-align:center'></span></div>";
		html += "	</div>"
		/// 内容区
		html += "	<div id='itro_content' style='width:100%; height:275px; overflow:auto;'>";
		html += "	</div>"
		html += "</div>"
	$('body').append(html);
}
/// 检查项目说明书
function initItemInstrDiv(Row){
	if(Common_ControlObj.LibPhaFunc.ZSKOpenFlag!="Y"){
		return
	}
	if ($("#itro_win").length==0) initDivHtml();
    $("#" + Row + "_" + "OrderName").on('mousemove',function(){ //移入
	    $("#"+Row+"_OrderName").removeClass("hover1");
	    var OrderName = GetCellData(Row, "OrderName");
	    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
	    var OrderNurseLinkOrderRowid = GetCellData(Row, "LinkedMasterOrderRowid");
	    if (OrderNurseLinkOrderRowid=="") {
		    //护士临时绑定长期主医嘱
	    	var OrderNurseLinkOrderRowid= GetCellData(Row, "OrderNurseLinkOrderRowid");
	    }
	    var itemPartID="";
	    var dh=$(window).height();
		var nameTop=$(this).parent().offset().top;
	    if (OrderNurseLinkOrderRowid!=""){
		    $("#itro_title").text(OrderName+" - "+ $g("对应主医嘱信息"));  /// div层 标题
		    $("#itro_win").css('width',400);
		    $("#itro_win").css('height',100);
		    if (nameTop<100){
			    var top=nameTop + $(this).outerHeight() - 10;
			}else{
				var top=nameTop - 100;
			}
		}else{
			$("#itro_title").text(OrderName+" - "+ $g("说明书"));  /// div层 标题
		    if (nameTop<315){
			    var top=nameTop + $(this).outerHeight() - 10;
			}else{
				var top=nameTop - 315;
			}
		}
		var OrderLabSpecRowid = GetCellData(Row, "OrderLabSpecRowid"); //标本
	    var itemHtml = GetItemInstr(OrderARCIMRowid, itemPartID, OrderNurseLinkOrderRowid,OrderLabSpecRowid);
	    if (itemHtml == "") return;
		
		$("#itro_content").html(itemHtml); 		   /// div层 内容
		$(".div-notes").css({
			top : top + 'px',
			left : (event.clientX + 10) + 'px',
			'z-index' : 99999
		}).show();
	})
    $("#" + Row + "_" + "OrderName").on('mouseleave',function(){ 
		var divThis = $(".div-notes"); 
		setTimeout(function(){ 
			if (divThis.hasClass("hover0")) {//说明没有从按钮进入div
				divThis.hide(); 
			}
	     }, 100); 
		$("#"+Row+"_OrderName").addClass("hover1");	
	});
	/// div 变量样式添加
	$(".div-notes").hover(function(){//div
		$(this).removeClass("hover0");
	},function(){
		$(this).addClass("hover0"); 
		var anniu = $("#"+Row+"_OrderName")//$('td[field="ItemLabel"]'); 
		var tthis = $(this); 
		setTimeout(function(){ 
			if(anniu.hasClass("hover1")){//说明没有从div回到按钮
				tthis.hide(); 
			}
		},100); 
	})
}
/// 提取检查项目说明书
function GetItemInstr(itmmastid, itemPartID, OrderNurseLinkOrderRowid,OrderLabSpecRowid){
	var html = '';
	if (OrderNurseLinkOrderRowid!="") {
		var rtn=tkMakeServerCall("web.DHCDocOrderCommon","GetVerifiedOrder",OrderNurseLinkOrderRowid);
		var VerifiedOrdInfo=rtn.split("^")[1]+","+$g("医嘱ID")+":"+rtn.split("^")[2];
		html = html + "<table  cellpadding='0' cellspacing='0' class='itro_content'>";
		html = html + "<tr><td style='border-right:solid #E3E3E3 1px; font-size:14px; padding-left: 10px;'>"+VerifiedOrdInfo+"</td></tr>";
		html = html + "</table>";
	}else{
		// 获取显示数据
		runClassMethod("web.DHCAPPExaReportQuery","GetItemInstr",{"itmmastid":itmmastid, "itemPartID":itemPartID,"OrderLabSpecRowid":OrderLabSpecRowid},function(jsonString){

			if (jsonString != ""){
				var jsonObject = jsonString;
				html = initMedIntrTip(jsonObject);
			}else{
				html = "";
			}
		},'json',false)
	}
	return html;
}
/// 初始化知识库信息描述
function initMedIntrTip(itmArr){
	var htmlstr = '';
	for(var i=0; i<itmArr.length; i++){
		htmlstr = htmlstr + "<table  cellpadding='0' cellspacing='0' class='itro_content'>" //<tr><td style='background-color:#F6F6F6;width:120px' >〖检查项目〗</td><td colspan='2'  style='border-right:solid #E3E3E3 1px'>"+itmArr[i].geneDesc+"["+itmArr[i].pointer+"]</td></tr>";
		htmlstr = htmlstr + "<tr><td style='background-color:#F6F6F6;font-weight:bold; font-size:14px;'>"+itmArr[i].itemTile+"</td></tr>";
		htmlstr = htmlstr + "<tr><td style='border-right:solid #E3E3E3 1px; font-size:14px; padding-left: 10px;'>"+itmArr[i].itemContent+"</td></tr>";
		htmlstr = htmlstr + "</table>";
	}
   return htmlstr;
}
///-----------------------知识库接口  end-----------------------------
//护士补录医嘱--勾选的时候设置关联主医嘱
function NurseAddMastOrde(MastLinkStr) {
    try {
        var MastLinkStrArry = MastLinkStr.split("^")
        var LinkedMasterOrderRowid = MastLinkStrArry[0];
        var LinkedMasterOrderSeqNo = MastLinkStrArry[1];
        var LinkedMasterOrderPriorRowid = MastLinkStrArry[2];
        var OrderFreStr = MastLinkStrArry[3];
        var LinkedMasterOrderSttDate=MastLinkStrArry[4];
        var LinkedMasterOrderInstr=MastLinkStrArry[5];
        var LinkedMasterOrderInstrRowid=MastLinkStrArry[6];
        var LinkedMasterOrderFreRowId = "";
        var LinkedMasterOrderFreFactor = "";
        var LinkedMasterOrderFreInterval = ""
        var LinkedMasterOrderFreDesc = "";
        var LinkedMasterOrderFreqDispTimeStr="";
        if (OrderFreStr != "") {
            LinkedMasterOrderFreRowId = mPiece(OrderFreStr, String.fromCharCode(1), 0);
            LinkedMasterOrderFreFactor = mPiece(OrderFreStr, String.fromCharCode(1), 1);
            LinkedMasterOrderFreInterval = mPiece(OrderFreStr, String.fromCharCode(1), 2);
            LinkedMasterOrderFreDesc = mPiece(OrderFreStr, String.fromCharCode(1), 3);
            LinkedMasterOrderFreqDispTimeStr = mPiece(OrderFreStr, String.fromCharCode(1),4);
            LinkedMasterOrderFreqDispTimeStr=LinkedMasterOrderFreqDispTimeStr.split(String.fromCharCode(13)).join(String.fromCharCode(1));
        }
        //检查所有要开医嘱
        var rowidsSub = $('#Order_DataGrid').getDataIDs();
        for (var Sub = 0; Sub < rowidsSub.length; Sub++) {
            //过滤已审核
            var OrderItemRowid = GetCellData(rowidsSub[Sub], "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowidsSub[Sub], "OrderARCIMRowid");
            if ((OrderItemRowid != "") || (OrderARCIMRowid == "")) { continue; }
            var OrderPHPrescType = GetCellData(rowidsSub[Sub], "OrderPHPrescType");
            var OrderType = GetCellData(rowidsSub[Sub], "OrderType");
            var OrderDate = GetCellData(rowidsSub[Sub], "OrderDate");
            //若是已补录医嘱则不做处理
            var OldLinkedMasterOrderRowid=GetCellData(rowidsSub[Sub], "LinkedMasterOrderRowid");
            if ((OldLinkedMasterOrderRowid!="")&&(LinkedMasterOrderRowid!="")) {
	            continue;
	        }
            //补录关联主医嘱信息
            SetCellData(rowidsSub[Sub], "LinkedMasterOrderRowid", LinkedMasterOrderRowid);
            SetCellData(rowidsSub[Sub], "LinkedMasterOrderSeqNo", LinkedMasterOrderSeqNo);
            var StyleConfigObj={};
            var StyleConfigStr=GetCellData(rowidsSub[Sub], "StyleConfigStr");
		    var oldStyleConfigobj = eval("(" + StyleConfigStr + ")");
            //在这里删除原有样式表，EditRow时重新计算样式
            SetCellData(rowidsSub[Sub], "StyleConfigStr", "");
            if(LinkedMasterOrderSttDate!=""){
	            if (OrderDate!="") {
		            if (tkMakeServerCall("web.DHCOEOrdItem","CompareDateTime",LinkedMasterOrderSttDate.split(" ")[0],LinkedMasterOrderSttDate.split(" ")[1],OrderDate.split(" ")[0],OrderDate.split(" ")[1])==1) {
			        	SetCellData(rowidsSub[Sub], "OrderStartDate", LinkedMasterOrderSttDate);
			        }
		        }else{
			        SetCellData(rowidsSub[Sub], "OrderStartDate", LinkedMasterOrderSttDate);
			    }
            }
            if (LinkedMasterOrderPriorRowid != "") {
	            var CurRowOrderPriorRowid=GetCellData(rowidsSub[Sub], "OrderPriorRowid");
	            var SubOrderInstr=GetCellData(rowidsSub[Sub], "OrderInstr");
	            var SubOrderInstrRowid=GetCellData(rowidsSub[Sub], "OrderInstrRowid");
	            if (OrderType =="R") {
		            if ((!IsNotFollowInstr(SubOrderInstrRowid))||(SubOrderInstrRowid=="")) {
			            SetCellData(rowidsSub[Sub], "OrderInstr", LinkedMasterOrderInstr);
	        			SetCellData(rowidsSub[Sub], "OrderInstrRowid", LinkedMasterOrderInstrRowid);
			        }
		        }else{
		            SetCellData(rowidsSub[Sub], "OrderInstr", "");
	        		SetCellData(rowidsSub[Sub], "OrderInstrRowid", "");
        		}
	            var NurseLinkFlag=tkMakeServerCall("web.DHCOEOrdItem","CheckNurseLinkFlag",LinkedMasterOrderRowid,CurRowOrderPriorRowid);
	            if (NurseLinkFlag=="1"){
		            SetCellData(rowidsSub[Sub], "OrderFreq", "");
	                SetCellData(rowidsSub[Sub], "OrderFreqRowid", "");
	                SetCellData(rowidsSub[Sub], "OrderFreqFactor", 1);
					SetCellData(rowidsSub[Sub], "OrderFreqDispTimeStr", "");
		            var HourFlag = cspRunServerMethod(GlobalObj.IsHourItem, OrderARCIMRowid);
		            if ((LinkedMasterOrderFreRowId != "")&&(HourFlag!=1)) {
		                SetCellData(rowidsSub[Sub], "OrderFreq", LinkedMasterOrderFreDesc);
		                SetCellData(rowidsSub[Sub], "OrderFreqRowid", LinkedMasterOrderFreRowId);
		                SetCellData(rowidsSub[Sub], "OrderFreqFactor", LinkedMasterOrderFreFactor);
						SetCellData(rowidsSub[Sub], "OrderFreqDispTimeStr", LinkedMasterOrderFreqDispTimeStr);
		            }
	                var PriorStr = cspRunServerMethod(GlobalObj.GetPrioCodeAndDesc, LinkedMasterOrderPriorRowid)
	                var LinkedMasterOrderPriorDesc = PriorStr.split("^")[1];
	                //强制模式
	                if (GlobalObj.OrderPriorContrlConfig == 1) {
	                    if ((LinkedMasterOrderPriorRowid == GlobalObj.OMSOrderPriorRowid) || (LinkedMasterOrderPriorRowid == GlobalObj.LongOrderPriorRowid)) {
	                        var OrderPriorStr = GlobalObj.LongOrderPriorRowid + ":" + "长期医嘱";
	                        SetColumnList(rowidsSub[Sub], "OrderPrior", OrderPriorStr);
	                        SetCellData(rowidsSub[Sub], "OrderPriorStr", OrderPriorStr);
	                    }
	                    if ((LinkedMasterOrderPriorRowid == GlobalObj.OMOrderPriorRowid) || (LinkedMasterOrderPriorRowid == GlobalObj.ShortOrderPriorRowid)) {
	                        var OrderPriorStr = GlobalObj.ShortOrderPriorRowid + ":" + "临时医嘱";
	                        SetColumnList(rowidsSub[Sub], "OrderPrior", OrderPriorStr);
	                         SetCellData(rowidsSub[Sub], "OrderPriorStr", OrderPriorStr);
	                    }
	                }
	                var obj = document.getElementById(rowidsSub[Sub] + "_OrderPrior");
	                if (obj) {
	                    //可编辑状态
	                    SetCellData(rowidsSub[Sub], "OrderPrior", LinkedMasterOrderPriorRowid);
	                } else {
	                    SetCellData(rowidsSub[Sub], "OrderPrior", LinkedMasterOrderPriorDesc);
	                }
	                
	                SetCellData(rowidsSub[Sub], "OrderPriorRowid", LinkedMasterOrderPriorRowid);
					SetOrderFirstDayTimes(rowidsSub[Sub]);
					StyleConfigObj.OrderFreq=false;
					//非药品长期医嘱，有频次不能录入数量，无频次可以录入数量
			        //非药品长期医嘱无频次不能录入单次剂量
			        var OrderFreqRowid=GetCellData(rowidsSub[Sub], "OrderFreqRowid");
			        if (LinkedMasterOrderPriorRowid == GlobalObj.LongOrderPriorRowid){
			            if (OrderFreqRowid==""){
				            if (HourFlag!="1") {
			                	StyleConfigObj.OrderPackQty = true;
			                }
			                StyleConfigObj.OrderDoseQty = false;
			                SetCellData(rowidsSub[Sub], "OrderDoseQty", "");
			            }else{
				            StyleConfigObj.OrderFirstDayTimes=true;
			                StyleConfigObj.OrderDoseQty = true;
			                StyleConfigObj.OrderPackQty = false;
			                SetCellData(rowidsSub[Sub], "OrderPackQty","");
			            }
			            if (VerifiedOrderObj.LinkedMasterOrderFreFactor>1) {
				            StyleConfigObj.OrderFreq = true;
				        }
			        }
			        var OrderPriorRowid=GetCellData(rowidsSub[Sub], "OrderPriorRowid");
			        var OrderPHPrescType = GetCellData(rowidsSub[Sub], "OrderPHPrescType");
			        //若护士补录临时医嘱到长期医嘱上，且补录的医嘱频次为空,则频次可编辑 为什么要编辑?
			        if ((OrderFreqRowid=="")&&(OrderPHPrescType=="4")&&(LinkedMasterOrderPriorRowid==GlobalObj.LongOrderPriorRowid)&&(OrderPriorRowid==GlobalObj.ShortOrderPriorRowid)){
				        StyleConfigObj.OrderFreq = true;
				    }
			        StyleConfigObj.OrderInstr = false;
			        StyleConfigObj.OrderPrior = false;
			        ChangeCellDisable(rowidsSub[Sub],StyleConfigObj)
                }else{
	                SetCellData(rowidsSub[Sub],"LinkedMasterOrderRowid","");
					SetCellData(rowidsSub[Sub],"LinkedMasterOrderSeqNo","");
			        SetCellData(rowidsSub[Sub],"OrderNurseLinkOrderRowid",VerifiedOrderObj.LinkedMasterOrderRowid);
			        StyleConfigObj.OrderPrior = false;
			        StyleConfigObj.OrderFreq=false;
			        StyleConfigObj.OrderInstr = false;
			        var OrderFreqRowid=GetCellData(rowidsSub[Sub], "OrderFreqRowid");
			        var OrderPriorRowid=GetCellData(rowidsSub[Sub], "OrderPriorRowid");
			        var OrderPHPrescType = GetCellData(rowidsSub[Sub], "OrderPHPrescType");
			        //若护士补录临时医嘱到长期医嘱上，且补录的医嘱频次为空,则频次可编辑 为什么要编辑?
			        if ((OrderFreqRowid=="")&&(OrderPHPrescType=="4")&&(LinkedMasterOrderPriorRowid==GlobalObj.LongOrderPriorRowid)&&(OrderPriorRowid==GlobalObj.ShortOrderPriorRowid)){
				        StyleConfigObj.OrderFreq = true;
				    }
			        ChangeCellDisable(rowidsSub[Sub],StyleConfigObj)
	            }
            }else{
	            var StyleConfigObj={OrderFreq:true,OrderDoseQty:true,OrderInstr:true};
	            if ((OrderType!="R")&&(OrderPHPrescType != "4")) {
	            	SetCellData(rowidsSub[Sub], "OrderFreq", "");
		            SetCellData(rowidsSub[Sub], "OrderFreqRowid", "");
		            SetCellData(rowidsSub[Sub], "OrderFreqFactor", "1");
					SetCellData(rowidsSub[Sub], "OrderFreqDispTimeStr", "");
					SetCellData(rowidsSub[Sub], "OrderDoseQty", "");
					SetOrderFirstDayTimes(rowidsSub[Sub]);
					$.extend(StyleConfigObj, {OrderFreq:false,OrderDoseQty:false,OrderPackQty:true});
	            }
	            var OrderPriorRowid=GetCellData(rowidsSub[Sub], "OrderPriorRowid");
				if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid){
		            StyleConfigObj.OrderPackQty = false;
		        }else{
			         StyleConfigObj.OrderPackQty = true;
			        }
	            if ((OrderType!="R")&&(OrderPHPrescType=="4")) {
		            StyleConfigObj.OrderFreq = true;
		            if (OrderPriorRowid == GlobalObj.LongOrderPriorRowid){
			            StyleConfigObj.OrderDoseQty = true;
			            StyleConfigObj.OrderPackQty = false;
			        }else{
				        StyleConfigObj.OrderDoseQty = false;
			            StyleConfigObj.OrderPackQty = true;
				    }
		        }  
	            var OrderHiddenPara = GetCellData(rowidsSub[Sub], "OrderHiddenPara");
    			var OrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
	            if ((OrderType!="R")&&(("^" + GlobalObj.SelectInstrNotDrugCat + "^").indexOf("^" + OrderItemCatRowid + "^")==-1)) {
		            StyleConfigObj.OrderInstr = false;
		        }
	            $.extend(StyleConfigObj, {OrderPrior:true});
			    ChangeCellDisable(rowidsSub[Sub],StyleConfigObj)
            }
            $.extend(oldStyleConfigobj, StyleConfigObj);
            var StyleConfigStr = JSON.stringify(oldStyleConfigobj);
    		SetCellData(rowidsSub[Sub], "StyleConfigStr", StyleConfigStr);
            initItemInstrDiv(rowidsSub[Sub]);
            CheckFreqAndPackQty(rowidsSub[Sub]);
        }
    } catch (e) {}
}
//患者自备
function OrderSelfOMFlagChangehandler(e) {
    var Row = GetEventRow(e);
    var OrderSelfOMFlag = GetCellData(Row, "OrderSelfOMFlag");
    if (OrderSelfOMFlag == "Y") {
        SetCellData(Row, "OrderPriorRemarks", "OM");
        SetCellData(Row, "OrderPriorRemarksRowId", "OM");
        CheckOrderPriorRemarks(Row);
    }
}
//OperationType="A" 下医嘱,OrdList 格式：arcimID*oeitmID*status^arcimID*oeitmID*status
//OperationType="S" 停医嘱,OrdList 格式：oeitmID^oeitmID
function SaveCASign(ContainerName, OrdList, OperationType) {
    try {
        if (ContainerName == "") return false;
        //1.批量认证
        var CASignOrdStr = "";
        var TempIDs = OrdList.split("^");
        var IDsLen = TempIDs.length;
        for (var k = 0; k < IDsLen; k++) {
	        if (OperationType=="A") {
		        var TempNewOrdDR = TempIDs[k].split("*");
                if (TempNewOrdDR.length < 2) continue;
                var newOrdIdDR = TempNewOrdDR[1];
	        }
	        if (OperationType=="S") {
		        var newOrdIdDR = TempIDs[k];
	        }
            
            if (CASignOrdStr == "") CASignOrdStr = newOrdIdDR;
            else CASignOrdStr = CASignOrdStr + "^" + newOrdIdDR;
        }
        var SignOrdHashStr = "",
            SignedOrdStr = "",
            CASignOrdValStr = "";
        var CASignOrdArr = CASignOrdStr.split("^");
        for (var count = 0; count < CASignOrdArr.length; count++) {
            var CASignOrdId = CASignOrdArr[count];
            var OEORIItemXML = cspRunServerMethod(GlobalObj.GetOEORIItemXMLMethod, CASignOrdId, OperationType);
            var OEORIItemXMLArr = OEORIItemXML.split(String.fromCharCode(2));
            for (var ordcount = 0; ordcount < OEORIItemXMLArr.length; ordcount++) {
                if (OEORIItemXMLArr[ordcount] == "") continue;
                var OEORIItemXML = OEORIItemXMLArr[ordcount].split(String.fromCharCode(1))[1];
                var OEORIOperationType = OEORIItemXMLArr[ordcount].split(String.fromCharCode(1))[0];
                //$.messager.alert("警告","OEORIItemXML:"+OEORIItemXML);
                var OEORIItemXMLHash = HashData(OEORIItemXML);
                //$.messager.alert("警告","HashOEORIItemXML:"+OEORIItemXMLHash);
                if (SignOrdHashStr == "") SignOrdHashStr = OEORIItemXMLHash;
                else SignOrdHashStr = SignOrdHashStr + "&&&&&&&&&&" + OEORIItemXMLHash;
                //$.messager.alert("警告",ContainerName);
                var SignedData = SignedOrdData(OEORIItemXMLHash, ContainerName);
                if (SignedOrdStr == "") SignedOrdStr = SignedData;
                else SignedOrdStr = SignedOrdStr + "&&&&&&&&&&" + SignedData;


                if (CASignOrdValStr == "") CASignOrdValStr = OEORIOperationType + String.fromCharCode(1) + CASignOrdId;
                else CASignOrdValStr = CASignOrdValStr + "^" + OEORIOperationType + String.fromCharCode(1) + CASignOrdId;
            }

        }
        if (SignOrdHashStr != "") SignOrdHashStr = SignOrdHashStr + "&&&&&&&&&&";
        if (SignedOrdStr != "") SignedOrdStr = SignedOrdStr + "&&&&&&&&&&";
        //获取客户端证书
        var varCert = GetSignCert(ContainerName);
        var varCertCode = GetUniqueID(varCert);
        /*
        alert("CASignOrdStr:"+CASignOrdStr);
        alert("SignOrdHashStr:"+SignOrdHashStr);
        alert("varCert:"+varCert);
        alert("SignedData:"+SignedOrdStr);
      */
        if ((CASignOrdValStr != "") && (SignOrdHashStr != "") && (varCert != "") && (SignedOrdStr != "")) {
            //3.保存签名信息记录
            ////                                                                                                                CASignOrdValStr,session['LOGON.USERID'],"A",                    SignOrdHashStr,varCertCode,SignedOrdStr,""
            var ret = cspRunServerMethod(GlobalObj.InsertCASignInfoMethod, CASignOrdValStr, session['LOGON.USERID'], OperationType, SignOrdHashStr, varCertCode, SignedOrdStr, "");
            if (ret != "0") { $.messager.alert("警告","数字签名没成功"); return false; }
        } else {
            $.messager.alert("警告","数字签名错误");
            return false;
        }
        return true;
    } catch (e) { alert(e.message); return false; }
}
function OrderMsgChange() {
    if (GlobalObj.CFOrderMsgAlert != 1) return false;
    if ((VerifiedOrderObj) && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "undefined") && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "")) return false;

    var Find = 0
    try {
        var rowid = "";
        var rowids = $('#Order_DataGrid').getDataIDs();
        if (rowids == "") {
            $("#Prompt").html($g("提示信息:"))
            //return false;
        }
        if (rowids.length > 0) {
            for (var i = rowids.length; i >= 0; i--) {
                if (Find == 1) continue;
                var rowid = rowids[i];
                var OrderItemRowid = GetCellData(rowid, "OrderItemRowid")
                var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid")
                var OrderName = GetCellData(rowid, "OrderName")
                if ((rowids.length == 1) && (OrderARCIMRowid == "")) $("#Prompt").html($g("提示信息:"))
                if ((OrderARCIMRowid != "") && (OrderItemRowid == "")) {
                    var OrderMsg = cspRunServerMethod(GlobalObj.GetOrderMsgMethod, GlobalObj.EpisodeID, OrderARCIMRowid)
                    if (OrderMsg != "") {
                        $("#Prompt").html($g("提示信息:") + OrderName + $g(OrderMsg))
                        Find = 1
                    } else {
                        $("#Prompt").html($g("提示信息:"))
                    }
                } else {
                    $("#Prompt").html($g("提示信息:"))
                }
            }

        }
        if (Find==0){
	        var IPNecessaryCatMsg=tkMakeServerCall("web.DHCDocOrderCommon", "GetIPNecessaryCat", GlobalObj.EpisodeID);
	        if (IPNecessaryCatMsg!=""){
	            $("#Prompt").html($g("提示信息:该患者尚未录入")+IPNecessaryCatMsg +$g("类医嘱."));
	        }
            if (GlobalObj.PPRowId != "") {
                GlobalObj.PilotProWarning=tkMakeServerCall("web.PilotProject.DHCDocPilotProject","ifWarning",GlobalObj.PPRowId,session['LOGON.USERID']);
                $("#Prompt").html($g(GlobalObj.PilotProWarning));
            }
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function CheckCureItemConfig(rowid,CureItemConfigArg) {
	return DHCDocCure_Service.CheckCureItemConfig(rowid,CureItemConfigArg);
}
//选择行在提示信息区域显示医嘱项的提示信息
function OrderDataGirdclick(e) {
    if ((VerifiedOrderObj) && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "undefined") && (VerifiedOrderObj.LinkedMasterOrderPriorRowid != "")) return false;
    if (GlobalObj.CFOrderMsgAlert != 1) return false;
    var rowid = GetEventRow(e)
    if (rowid == "") return false;
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid")
    var OrderName = GetCellData(rowid, "OrderName")
    var OrderMsg = cspRunServerMethod(GlobalObj.GetOrderMsgMethod, GlobalObj.EpisodeID, OrderARCIMRowid)
    if (OrderMsg != "") {
        $("#Prompt").html($g("提示信息:") + OrderName + $g(OrderMsg));
    }
}
function OpenChangeOrderClick() {
    DiaUpdateClick()
}
function DiaUpdateClick() {
    var rowids = GetSelRowId();
    new Promise(function(resolve,rejected){
		StopOrd(rowids,resolve);
	}).then(function(OrdList){
	    var rowids = $('#Order_DataGrid').getDataIDs();
	    var NewOrdList = "";
	    for (var i = 0; i < OrdList.split("^").length; i++) {
	        if (NewOrdList == "") NewOrdList = OrdList.split("^")[i].split("&")[0];
	        else NewOrdList = NewOrdList + "^" + OrdList.split("^")[i].split("&")[0];
	    }
		var rowids = $('#Order_DataGrid').getDataIDs();
		var OrderSerialNumS=$.cm({
			ClassName:"web.DHCDocPrescript",
			MethodName:"GetOrderSerialNum",
			dataType:"text",
			PAADMDr:GlobalObj.EpisodeID,
			Count:NewOrdList.split("^").length
		},false);
		var OrderSerialNumArr=OrderSerialNumS.split("^");
		
	    NewOrdList = "^" + NewOrdList + "^";
	    for (var k = 0; k < rowids.length; k++) {
	        //过滤已审核
	        var OrderItemRowid = GetCellData(rowids[k], "OrderItemRowid");
	        //if(OrdList.indexOf(OrderItemRowid+"&")==-1){continue}
			var key=NewOrdList.indexOf("^" + OrderItemRowid + "^")
	        if (key == -1) { continue }
			if (key<=(OrderSerialNumArr.length-1)){
				SetCellData(rowids[k], "OrderSerialNum", OrderSerialNumArr[key]);
			}else{
				SetCellData(rowids[k], "OrderSerialNum", "");
			}
	        SetCellData(rowids[k], "OrderItemRowid", "");
	        SetCellData(rowids[k], "OrderLabEpisodeNo", "");
	        var OrderBindSource = GetCellData(rowids[k], "OrderBindSource")
	        if (OrderBindSource != "") {
	            DeleteAntReason(rowids[k]);
	            $('#Order_DataGrid').delRowData(rowids[k]);
	        }
	        var OrderName = GetCellData(rowids[k], "OrderItemRowid");
			var OrderARCIMRowid = GetCellData(rowids[k], "OrderARCIMRowid");
	        if (OrderARCIMRowid=="") continue;
	        SetNewOrderClass(rowids[k]);
	        EditRow(rowids[k], "1");
	        //设定毒麻处方背景色
	        var OrderPoisonCode=GetCellData(rowids[k], "OrderPoisonCode");
	        var OrderPoisonRowid=GetCellData(rowids[k], "OrderPoisonRowid");
	        SetPoisonOrderStyle(OrderPoisonCode, OrderPoisonRowid, rowids[k])
	        //设定关联医嘱的背景色
	        var OrderMasterSeqNo = GetCellData(rowids[k], "OrderMasterSeqNo");
	        if (OrderMasterSeqNo!=""){
		        $("#" + OrderMasterSeqNo).find("td").addClass("OrderMasterM");
				$("#" + rowids[k]).find("td").addClass("OrderMasterS");
		    }
	        $('#Order_DataGrid').setCell(rowids[k],"OrderName",OrderName,"OrderUnSaved","");
	        var CureItemStyleObj=CheckCureItemConfig(rowids[k]);
			ChangeRowStyle(rowids[k], CureItemStyleObj)
			GetBindOrdItemTip(rowids[k]);
	    }
	    SetScreenSum();
	    CheckMasterOrdStyle();
	})
}
//对医嘱录入输入完别名选择医嘱后的焦点跳转
function CellFocusJumpAfterOrderName(rowid, OrderType) {
    if (OrderType == "R") {
        SetFocusCell(rowid, "OrderDoseQty");
    } else {
        if (OrderType == "P") {
            SetFocusCell(rowid, "OrderPrice");
        } else {
			var StyleConfigStr = GetCellData(rowid, "StyleConfigStr");
			var StyleConfigObj = {};
			if (StyleConfigStr != "") {
				StyleConfigObj = eval("(" + StyleConfigStr + ")");
			}
	        var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    		var OrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
    		var RequireNote = mPiece(OrderHiddenPara, String.fromCharCode(1), 21);
    		var SelectInstrNotDrugCatFlag=0;
	        if (("^" + GlobalObj.SelectInstrNotDrugCat + "^").indexOf("^" + OrderItemCatRowid + "^") >=0) {
	            SelectInstrNotDrugCatFlag=1;
	        }
	        var OrderInstrRowid = GetCellData(rowid, "OrderInstrRowid");
            var OrderPHPrescType = GetCellData(rowid, "OrderPHPrescType");
            var OrderFreqRowid = GetCellData(rowid, "OrderFreqRowid");
            if (OrderType == "P") {
                SetFocusCell(rowid, "OrderPrice");
            } else if ((OrderPHPrescType == "4") && (OrderFreqRowid == "")) {
                SetFocusCell(rowid, "OrderFreq");
            } else if ((SelectInstrNotDrugCatFlag==1)&&(OrderInstrRowid == "")){
	            //可选择用法的非药品子分类，若用法为空,先跳转到用法列
				if (StyleConfigObj.OrderInstr==true){
					SetFocusCell(rowid, "OrderInstr");
				}else if(StyleConfigObj.OrderDoseQty==true){
					//护士关联主医嘱时，用法列禁用
					SetFocusCell(rowid, "OrderDoseQty");
				}else if(StyleConfigObj.OrderFreq==true){
					SetFocusCell(rowid, "OrderFreq");
				}

	        } else if (RequireNote == "Y") {
		        //自定义描述医嘱
                SetFocusCell(rowid, "OrderDepProcNote");
	        }else {
                var OrderPackQtyObj = document.getElementById(rowid + "_OrderPackQty");
                if (OrderPackQtyObj && (OrderPackQtyObj.disabled == false)) {
                    SetFocusCell(rowid, "OrderPackQty");
                } else {
                    //判断如果整包装数量是空,跳转到单次剂量
                    var OrderPackQty = GetCellData(rowid, "OrderPackQty");
                    if (OrderPackQty != "") { window.setTimeout("Add_Order_row()", 200); } else {
                        SetFocusCell(rowid, "OrderDoseQty");
                    }

                }
            }
        }
    }
}
function CheckInsuCostControl() {
    try {
        var InputOrderInfo = ""
        var rowids = $('#Order_DataGrid').getDataIDs();
        for (var i = 0; i < rowids.length; i++) {
            var Row = rowids[i]
            var OrderItemRowid = GetCellData(Row, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
            var StyleConfigStr = GetCellData(Row, "StyleConfigStr");
            var StyleConfigObj = {};
            if (StyleConfigStr != "") {
                StyleConfigObj = eval("(" + StyleConfigStr + ")");
            }
            if ((GlobalObj.PAAdmType != "I") && (StyleConfigObj.OrderPackQty != true) && (OrderItemRowid != "")) { continue }
            if (OrderARCIMRowid == "") { continue; }

            var OrderName = GetCellData(Row, "OrderName");
            ///1医嘱项编码
            var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
            ///2下医嘱科室
            var OrderDepCode = session['LOGON.CTLOCID'];
            var OrderStartDate = "";
            var OrderStartTime = "";
            var OrderStartDateStr = GetCellData(Row, "OrderStartDate");
            if (OrderStartDateStr != "") {
                //3医嘱日期
                OrderStartDate = OrderStartDateStr.split(" ")[0];
                //4医嘱时间
                OrderStartTime = OrderStartDateStr.split(" ")[1];
            }
            //5医嘱医生编码
            var OrderDocCode = GlobalObj.LogonDoctorID;
            //6医嘱医生职称CTPCP_CarPrvTp_DR->CTCPT_Desc
            var OrderCarPrvTp = ""
                //7婴儿出生日期
            var BabyBrithDay = ""
                //8婴儿出生时间
            var BabyBrithTime = ""
                //9婴儿费标志    1:婴儿费 0：其他费
            var BabyFeeFlag = ""
                //10是否药品 Y:药品 N:非药品
            var OrderType = GetCellData(Row, "OrderType");
            var DurgFlag = "Y"
            if (OrderType != "R") var DurgFlag = "N"
                //11单方复方标志  1：单方 0：复方
            var SDFlag = ""
                //12中药贴数
            var CMQty = ""
                //13中药用量
            var CMDoseQty = ""
                //14医嘱优先级编码
            var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
            var OrderPriorRemarks = GetCellData(Row, "OrderPriorRemarks");
            OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
            //15用药途径    
            var OrderInstrRowid = GetCellData(Row, "OrderInstrRowid");
            //16频次
            var OrderFreqRowid = GetCellData(Row, "OrderFreqRowid");
            //17疗程
            var OrderDurRowid = GetCellData(Row, "OrderDurRowid");
            var OrderFreqFactor = GetCellData(Row, "OrderFreqFactor");
            //18单次用量
            var OrderDoseQty = GetCellData(Row, "OrderDoseQty");
            //19每日用量
            var OrderPDQty = parseFloat(OrderDoseQty) * parseFloat(OrderFreqFactor)
                //20首次服药量
                //var OrderFirstDayTimes=GetColumnData("OrderFirstDayTimes",Row);
            var OrderFirstDayTimes = OrderDoseQty
                //21用量对应的单位
            var OrderDoseUOM = GetCellData(Row, "OrderDoseUOM");
            var OrderDoseUOMRowid = GetCellData(Row, "OrderDoseUOMRowid");
            //22数量单位
            var OrderPackUOMRowid = GetCellData(Row, "OrderPackUOMRowid");
            //23数量单位与用量单位关系
            var CalDose = ""
                //24数量
            var OrderPackQty = GetCellData(Row, "OrderPackQty");
            //25单价
            var OrderPrice = GetCellData(Row, "OrderPrice");
            //26金额
            var OrderSum = GetCellData(Row, "OrderSum");
            //27用户ID
            var UserID = session['LOGON.USERID'];
            //28接受科室
            var OrderRecDepRowid = GetCellData(Row, "OrderRecDepRowid");
            var OrdStr = OrderARCIMRowid + "^" + OrderDepCode + "^" + OrderStartDate + "^" + OrderStartTime + "^" + OrderDocCode
                //6
            var OrdStr = OrdStr + "^" + OrderCarPrvTp + "^" + BabyBrithDay + "^" + BabyBrithTime + "^" + BabyFeeFlag + "^" + DurgFlag
                //11
            var OrdStr = OrdStr + "^" + SDFlag + "^" + CMQty + "^" + CMDoseQty + "^" + OrderPriorRowid + "^" + OrderInstrRowid
                //16
            var OrdStr = OrdStr + "^" + OrderFreqRowid + "^" + OrderDurRowid + "^" + OrderDoseQty + "^" + OrderPDQty + "^" + OrderFirstDayTimes
                //21
            var OrdStr = OrdStr + "^" + OrderDoseUOMRowid + "^" + OrderPackUOMRowid + "^" + CalDose + "^" + OrderPackQty + "^" + OrderPrice
                //26
            var OrdStr = OrdStr + "^" + OrderSum + "^" + UserID + "^" + OrderRecDepRowid

            if (InputOrderInfo == "") {
                InputOrderInfo = OrdStr
            } else {
                InputOrderInfo = InputOrderInfo + String.fromCharCode(2) + OrdStr
            }

        }
        //alert(GlobalObj.EpisodeID+"!!!"+InputOrderInfo)
        var Rtn = cspRunServerMethod(GlobalObj.CheckInsuCostControlMethod, GlobalObj.EpisodeID, InputOrderInfo)

        if (Rtn != "") {
            var ErrType = Rtn.split("^")[0]
            var ErrMsg = Rtn.split("^")[1]
            if (ErrType == "0") {
                $.messager.alert("根据医保控费政策", ErrMsg)
            } else if (ErrType == "1") {
                return dhcsys_confirm("根据医保控费政策:" + ErrMsg + "，是否继续?")
            } else if (ErrType == "2") {
                $.messager.alert("根据医保控费政策", ErrMsg + ".不允许审核！")
                return false
            }
        }
        return true
    } catch (e) {
        alert(e.message);
    }
    return true
}
function GetRecPrice(Row) {
    if (GlobalObj.PAAdmType != "I") {
        OrderBillTypeRowid = GetPrescBillTypeID();
    } else {
        OrderBillTypeRowid = GlobalObj.BillTypeID;
    }
    var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
    var OrderOpenForAllHosp = ""; //$("#OrderOpenForAllHosp").val();
    var OrderPackUOMRowid = GetCellData(Row, "OrderPackUOMRowid");
    if (OrderPackUOMRowid == "") return;
    var OrderRecDepRowid = GetCellData(Row, "OrderRecDepRowid");
    var LogonDep = GetLogonLocByFlag();
    var retPrice = cspRunServerMethod(GlobalObj.GetOrderPriceConUomMethod, GlobalObj.EpisodeID, OrderBillTypeRowid, LogonDep, OrderARCIMRowid, OrderOpenForAllHosp, OrderPackUOMRowid, OrderRecDepRowid);
    if (retPrice==undefined) retPrice="0^0^0^0^0";
    var ArrPrice = retPrice.split("^");
    var Price = ArrPrice[0];
    if (Price < 0) {
        $.messager.alert("警告","此接收下无有效医嘱项,请切换接收科室或者联系相关人员处理")
        websys_setfocus('OrderRecDep');
    }
    return retPrice
}
function SaveOrderToEMR() {
	var argObj={
		PAAdmType:GlobalObj.PAAdmType,
		EpisodeID:GlobalObj.EpisodeID
	}
	var OrdList=Common_ControlObj.AfterUpdate("SaveOrderToEMR",argObj);
	return OrdList;
}
function InstrFocusHandler(e) {
	//$(this).select();
	if (typeof e.bubbles != "undefined") {
		$(this).select();
	}
	return false;
}
function OrdDoseQtyFocusHandler(e){
	$(this).select();
	var obj = websys_getSrcElement(e);
    var rowid = "";
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
	return false;
}
function OrderFirstDayTimesFocusHandler(e){
	$(this).select();
	return false;
}
function OrderPackQtyFocusHandler(e){
	$(this).select();
	return false;
}
function FrequencyFocusHandler(e) {
	if (typeof e.bubbles != "undefined") {
		$(this).select();
	}
	return false;
}
function DurationFocusHandler(e) {
	if (typeof e.bubbles != "undefined") {
		$(this).select();
	}
	return;
}
function OrdCateGoryChange(e) {
    var rowid = "";
    var obj = websys_getSrcElement(e);
    var rowid = GetEventRow(e);
    var OrdCateGoryid = obj.value;
    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
    if (OrderARCIMRowid != "") {
	    var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
	    if (OrderMasterSeqNo!=""){
		    SetMasterSeqNo("", rowid, "C");
		}else{
			var SubRowidsAry=GetMasterSeqNo(rowid);
			var len=SubRowidsAry.length;
			if (len>0){
				for (var i=0;i<len;i++){
					SetMasterSeqNo("", SubRowidsAry[i], "C");
				}
			}
		}
        DeleteAntReason(rowid);
        $('#Order_DataGrid').delRowData(rowid);
        var rowid = Add_Order_row();
        SetCellData(rowid, "OrdCateGory", OrdCateGoryid);
    }
    SetCellData(rowid, "OrdCateGoryRowId", OrdCateGoryid);
    SetCellData(rowid, "OrderName", "");
    SetFocusCell(rowid, "OrderName");
}
function SortRowClick(type){
    var SelIds=$('#Order_DataGrid').jqGrid("getGridParam", "selarrrow"); 
	//没有Check行那么取焦点行
    if (SelIds == null || SelIds.length == 0) {
        if (PageLogicObj.FocusRowIndex > 0) {
            if ($("#jqg_Order_DataGrid_" + PageLogicObj.FocusRowIndex).prop("checked") != true) {
                $("#Order_DataGrid").setSelection(PageLogicObj.FocusRowIndex, true);
            }
        }
        SelIds = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
    }
    RemoveInvalidRow(SelIds);
    if(!SelIds.length){
		return false;   
	}
	SelIds=SelIds.slice(0).sort(function(a, b){ return a - b; });
	var rowids = $('#Order_DataGrid').getDataIDs();
	RemoveInvalidRow(rowids);
	var ChangeRowids=new Array();
	var ContainStartFlag=false;
	for (var i = 0; i<rowids.length; i++){
		var LoopIndex=SelIds.indexOf(rowids[i]);
		if (LoopIndex>-1) ContainStartFlag=true;
		if(ContainStartFlag&&(LoopIndex==-1)&&(parseInt(SelIds[SelIds.length-1])>parseInt(rowids[i]))){
			$.messager.alert("警告","请选择相邻的医嘱进行移动!");
			return false;
		}
		//已经找到选择行,获取待交换行
		if(ContainStartFlag&&(!ChangeRowids.length)){
			if(type=='up'){
				RecurChangeRow(i-1,-1);
				break;
			}else{
				if(LoopIndex==-1){
					RecurChangeRow(i,1);
					break;
				}
			}
		}
	}
	if(!ChangeRowids.length) return;
	var NewSortRowids=type=='up'?SelIds.concat(ChangeRowids):ChangeRowids.concat(SelIds);
	var OldSortRowids=NewSortRowids.slice(0).sort(function(a, b){ return a - b; });
	//获取交换行数据,需要重新计算关联序号
	var NewSortData=new Array();
	for(var i=0;i<NewSortRowids.length;i++){
		var rowid=NewSortRowids[i];
		EndEditRow(rowid);
		var curRowData = $("#Order_DataGrid").getRowData(rowid);
		var OrderMasterSeqNo=curRowData["OrderMasterSeqNo"];
		curRowData["id"]=OldSortRowids[i];
		if(OrderMasterSeqNo!=""){
			var index=NewSortRowids.indexOf(OrderMasterSeqNo);
			if(index>-1){
				curRowData['OrderMasterSeqNo']=OldSortRowids[index];
			}
		}
		NewSortData.push(curRowData);
	}
	//赋值数据
	for(var i=0;i<NewSortData.length;i++){
		var rowid=NewSortData[i]['id'];
		var rowData=NewSortData[i];
        SetRowData(rowid,rowData,"");
        EditRow(rowid);
		InitRowBtn(rowid);
        //高危药高亮显示
	    var OrderName=GetCellData(rowid,"OrderName");
	    var OrderHiddenPara=GetCellData(rowid, "OrderHiddenPara");
	    var PHCDFCriticalFlag=OrderHiddenPara.split(String.fromCharCode(1))[17];
	    if (PHCDFCriticalFlag=="Y"){
		    $("#"+rowid+"_OrderName").parent().parent().addClass('OrderCritical');
		}else{
			$("#"+rowid+"_OrderName").parent().parent().removeClass('OrderCritical');
		}
        var OrderPoisonCode=GetCellData(rowid, "OrderPoisonCode");
        var OrderPoisonRowid=GetCellData(rowid, "OrderPoisonRowid");
        $("#" + rowid).find("td").removeClass("SkinTest");
        SetPoisonOrderStyle(OrderPoisonCode, OrderPoisonRowid, rowid)
		var LinkedMasterOrderRowid = GetCellData(rowid, "LinkedMasterOrderRowid");
		var OrderNurseLinkOrderRowid=GetCellData(rowid, "OrderNurseLinkOrderRowid");
		if ((LinkedMasterOrderRowid!="")||(OrderNurseLinkOrderRowid!="")) {
		    initItemInstrDiv(rowid);
		}
	}
	//重新选择行
	$("#Order_DataGrid").jqGrid('resetSelection');
	for(var i=0;i<SelIds.length;i++){
		var oldRowid=SelIds[i];
		var rowid=OldSortRowids[NewSortRowids.indexOf(oldRowid)];
		var OrderMasterSeqNo=GetCellData(rowid, "OrderMasterSeqNo");
		if(OrderMasterSeqNo==""){
			$("#Order_DataGrid").setSelection(rowid,true);
		}
	}
	ReSetLinkOrdClass();
	return;
	//相邻成组数据获取(成组存在不相邻的情况)
	function RecurChangeRow(index,DirectFlag){
		var ChangeRowid=rowids[index];
		var ChangeMasterSeqNo=GetCellData(ChangeRowid,'OrderMasterSeqNo');
		while(rowids[index]){
			var rowid=rowids[index];
			var OrderMasterSeqNo=GetCellData(rowid,'OrderMasterSeqNo');
			if((rowid==ChangeRowid)||(rowid==ChangeMasterSeqNo)||(OrderMasterSeqNo&&((OrderMasterSeqNo==ChangeRowid)||(OrderMasterSeqNo==ChangeMasterSeqNo)))){
				ChangeRowids.push(rowid);
			}else{
				break;
			}
			index+=DirectFlag;
		}
		ChangeRowids.sort(function(a, b){ return a - b; });
	}
}
function RemoveInvalidRow(rowids){
	for (var i=rowids.length-1; i>=0; i--) {
		var OrderMasterSeqNo = GetCellData(rowids[i], "OrderMasterSeqNo");
		var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
		var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
		var OrderARCOSRowid = GetCellData(rowids[i], "OrderARCOSRowid");
		var OrderType = GetCellData(rowids[i], "OrderType");
		if (((OrderARCIMRowid == "")&&(OrderARCOSRowid=="")) || (OrderItemRowid != "")) {
			rowids.splice(i,1);
		}
	}
    return rowids;
}
function SetUpToRowClickHandler(){
	SortRowClick("up");
}
function ReSetLinkOrdClass(){
	var MaterOrderSeqNo=new Array();
	var rowids = $('#Order_DataGrid').getDataIDs();
    for (var k = 0; k < rowids.length; k++) {
	    $("#" + rowids[k]).find("td").removeClass("OrderMasterM OrderMasterS");
	    var OrderItemRowid = GetCellData(rowids[k], "OrderItemRowid");
	    var OrderARCIMRowid = GetCellData(rowids[k], "OrderARCIMRowid");
	    if ((OrderARCIMRowid != "") && (OrderItemRowid == "")) {
		    var OrderMasterSeqNo = GetCellData(rowids[k], "OrderMasterSeqNo");
		    var OrderSeqNo=GetCellData(rowids[k],"id");
		    if (OrderMasterSeqNo!=""){
		        var mainRowData=$('#Order_DataGrid').jqGrid("getRowData",OrderMasterSeqNo);
		        if ($.isEmptyObject(mainRowData)) {
			        var OrderMasterSeqNo=GetRowIdByOrdSeqNo(OrderMasterSeqNo);
			    }
				MaterOrderSeqNo[OrderMasterSeqNo]=OrderMasterSeqNo;
			    $("#" + OrderMasterSeqNo).find("td").addClass("OrderMasterM");
			    $("#" + rowids[k]).find("td").addClass("OrderMasterS");
			}else if(MaterOrderSeqNo[OrderSeqNo]){
				$("#" + OrderSeqNo).find("td").addClass("OrderMasterM");
			}
		}
	}
}
function SetDownToRowClickHandler(){
	SortRowClick("down");
}
//保存到模板
function SaveToTemplate_Click()
{ 
    var SelIds=$('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");            
    if(SelIds==null || SelIds.length==0) {  
        $.messager.alert("警告","请选择要保存到医嘱的记录");  
        return;  
    }
    var ItemArr=new Array()
    for(var i=0;i<SelIds.length;i++){
        var OrderARCIMRowid=GetCellData(SelIds[i],"OrderARCIMRowid");
        var OrderDepProcNote=GetCellData(SelIds[i],"OrderDepProcNote");
        var OrderBodyPartLabel=GetCellData(SelIds[i],"OrderBodyPartLabel");
        if(OrderARCIMRowid) 
        	ItemArr.push({
	        	itemid:OrderARCIMRowid,
	        	note:OrderDepProcNote,
	        	partInfo:OrderBodyPartLabel
        	});
    }
    if(!ItemArr.length){
        $.messager.alert("警告","请选择非空白记录进行保存!")
         return;
    }
    return InsertMultFavItem(ItemArr);
}
function GetAddTOArcosARCIMDatas(rowids){
	var ArcosMaxLinkSeqNo=1;
	OrderSubSeqNoArr = new Array();
	OrderMasterSeqNoArr = new Array();
    var retstring=""
    var len=rowids.length;
     for(var i=0;i<rowids.length;i++){ 
        //门诊的已经审核但未收费不会在录入的医嘱套中
        var OrderItemRowid=GetCellData(rowids[i],"OrderItemRowid");
        var OrderARCIMRowid=GetCellData(rowids[i],"OrderARCIMRowid");
        if (OrderARCIMRowid=="") continue;
        var OrderMasterSeqNo=GetCellData(rowids[i],"OrderMasterSeqNo");
        var OrderSeqNo=GetCellData(rowids[i],"id");
        var OrderPriorRowid=GetCellData(rowids[i],"OrderPriorRowid");
        //存在关联号为空,也赋值了关联号到医嘱套维护界面,在AddCopyItemToList有判断不影响使用
        if(OrderMasterSeqNo=="") {
			//如果存在子医嘱则赋值,不存在则不赋值
			var SubRowidsAry = GetMasterSeqNo(rowids[i]);
			if (SubRowidsAry.length > 0) {
				if (OrderMasterSeqNoArr[OrderSeqNo]) {
					OrderMasterSeqNo = OrderMasterSeqNoArr[OrderSeqNo];
				} else {
					OrderMasterSeqNo =ArcosMaxLinkSeqNo;
					OrderMasterSeqNoArr[OrderSeqNo]=ArcosMaxLinkSeqNo
				}
				ArcosMaxLinkSeqNo=ArcosMaxLinkSeqNo+1;
			}
		}else {
			if (OrderMasterSeqNoArr[OrderMasterSeqNo]) {
				var OrderMasterSeqNo=GetSubSeqNoForArcos(OrderMasterSeqNoArr[OrderMasterSeqNo])
			}else {
				OrderMasterSeqNoArr[OrderMasterSeqNo]=ArcosMaxLinkSeqNo
				var OrderMasterSeqNo=GetSubSeqNoForArcos(OrderMasterSeqNoArr[OrderMasterSeqNo])
			}
		}
        var OrderDoseQty=GetCellData(rowids[i],"OrderDoseQty");//剂量
        if ((OrderDoseQty!="")&&(OrderDoseQty.indexOf("-")>=0)) {
            OrderDoseQty=OrderDoseQty.split("-")[0];
        }
        var OrderDoseUOM=GetCellData(rowids[i],"OrderDoseUOMRowid");//剂量单位
        var OrderFreqRowID=GetCellData(rowids[i],"OrderFreqRowid"); //频次
        var OrderInstrRowID=GetCellData(rowids[i],"OrderInstrRowid"); //用法
        var OrderDurRowid=GetCellData(rowids[i],"OrderDurRowid");     //疗程
        var OrderPackQty=GetCellData(rowids[i],"OrderPackQty"); //整包装
        var OrderPackUOM=GetCellData(rowids[i],"OrderPackUOMRowid"); //整包装单位
        var OrderRecDepRowid = GetCellData(rowids[i], "OrderRecDepRowid");
        var FindFlag=0;
        var BillUOMStr=GetCellData(rowids[i], "OrderPackUOMStr");
        var ArrData = BillUOMStr.split(String.fromCharCode(2));
        if (ArrData.length<=1){
            OrderRecDepRowid="";
        }else{
	        for (var k = 0; k < ArrData.length-1; k++) {
		        var ArrData1 = ArrData[k].split(String.fromCharCode(1));
		        if ((ArrData1[0] == OrderPackUOM)&&(OrderPackUOM!="")&&(OrderPackUOM!=undefined)) {
		            FindFlag=1;
		        }
		    }
		    if (FindFlag==0) OrderRecDepRowid="";
	    }
        var OrderDepProcNote=GetCellData(rowids[i],"OrderDepProcNote"); //医嘱备注
        var OrderPriorRemarks=GetCellData(rowids[i],"OrderPriorRemarksRowId"); //附加说明
        if (OrderPriorRemarks=="false") OrderPriorRemarks="";
        var SampleId=GetCellData(rowids[i],"OrderLabSpecRowid");
        var OrderStageCode = GetCellData(rowids[i], "OrderStageCode");
        
        var OrderSpeedFlowRate=GetCellData(rowids[i],"OrderSpeedFlowRate");//输液流速
        var OrderFlowRateUnitRowId=GetCellData(rowids[i],"OrderFlowRateUnitRowId"); //流速单位
        var OrderBodyPartLabel=GetCellData(rowids[i], "OrderBodyPartLabel");
        var OrderFreqTimeDoseStr=GetCellData(rowids[i], "OrderFreqTimeDoseStr");//同频次不同剂量
        var OrderFreqWeekStr=GetCellData(rowids[i], "OrderFreqDispTimeStr"); //周频次
        var OrderSkinTest=GetCellData(rowids[i], "OrderSkinTest");
        var OrderActionRowid=GetCellData(rowids[i], "OrderActionRowid");
        var Urgent=GetCellData(rowids[i], "Urgent");
        //SampleId 标本ID,ARCOSItemNO  插入指定位置(医嘱录入不用), OrderPriorRemarksDR As %String
        if (retstring==""){
            retstring=OrderARCIMRowid+"^"+OrderPackQty+"^"+OrderDoseQty+"^"+OrderDoseUOM+"^"+OrderFreqRowID+"^"+OrderDurRowid+"^"+OrderInstrRowID+"^"+OrderMasterSeqNo+"^"+OrderDepProcNote+"^"+OrderPriorRowid+"^"+SampleId+"^"+""+"^"+OrderPriorRemarks+"^"+OrderStageCode+"^"+OrderSpeedFlowRate+"^"+OrderFlowRateUnitRowId+"^"+OrderPackUOM+"^"+OrderRecDepRowid+"^"+OrderBodyPartLabel+"^"+OrderFreqTimeDoseStr+"^"+OrderFreqWeekStr+"^"+OrderSkinTest+"^"+OrderActionRowid+"^"+Urgent;
        }else{
            retstring=retstring+String.fromCharCode(3)+OrderARCIMRowid+"^"+OrderPackQty+"^"+OrderDoseQty+"^"+OrderDoseUOM+"^"+OrderFreqRowID+"^"+OrderDurRowid+"^"+OrderInstrRowID+"^"+OrderMasterSeqNo+"^"+OrderDepProcNote+"^"+OrderPriorRowid+"^"+SampleId+"^"+""+"^"+OrderPriorRemarks+"^"+OrderStageCode+"^"+OrderSpeedFlowRate+"^"+OrderFlowRateUnitRowId+"^"+OrderPackUOM+"^"+OrderRecDepRowid+"^"+OrderBodyPartLabel+"^"+OrderFreqTimeDoseStr+"^"+OrderFreqWeekStr+"^"+OrderSkinTest+"^"+OrderActionRowid+"^"+Urgent;
        }
    }
    return retstring
}
function OrderOperationchangehandler(e){
    try{
        var rowid=GetEventRow(e);
        var obj=websys_getSrcElement(e);
        var OrderOperationCode=obj.value;
        SetCellData(rowid,"OrderOperationCode",OrderOperationCode);
        var OrderOperation=GetCellData(rowid, "OrderOperation");
    	var OrderOperationCode=GetCellData(rowid, "OrderOperationCode");
        var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
        if (OrderMasterSeqNo!="") {
		    rowid=OrderMasterSeqNo;
		    if (GetEditStatus(rowid) == true) {
            	SetCellData(rowid, "OrderOperation", OrderOperationCode);
            }else{
	            SetCellData(rowid, "OrderOperation", OrderOperation);
	        }
            SetCellData(rowid, "OrderOperationCode", OrderOperationCode);
	    }
        ChangeLinkOrderOperation(rowid,OrderOperation,OrderOperationCode);
    }catch(e){$.messager.alert("警告",e.message)}
}

function ChangeLinkOrderOperation(Row,OrderOperation,OrderOperationCode){
    var OrderSeqNo=GetCellData(Row, "id");
    try {
        var rows = $('#Order_DataGrid').getDataIDs();
        for (var i = 0; i < rows.length; i++) {
            var rowid = rows[i];
            var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
            var OrderType = GetCellData(rowid, "OrderType");
            if ((OrderMasterSeqNo != OrderSeqNo) || (OrderARCIMRowid == "") || (OrderItemRowid != "")) { continue; }
            if (GetEditStatus(rowid) == true) {
            	SetCellData(rowid, "OrderOperation", OrderOperationCode);
            }else{
	            SetCellData(rowid, "OrderOperation", OrderOperation);
	        }
            SetCellData(rowid, "OrderOperationCode", OrderOperationCode);
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}
function GetOperationStr(){
    var AnaesthesiaID=GetMenuPara("AnaesthesiaID");
    var OperationStr = cspRunServerMethod(GlobalObj.GetOperInfoMethod,AnaesthesiaID);
    $.extend(GlobalObj,{OperationStr:OperationStr});
    return true
}
///频次疗程关联事件
function FreqDurChange(rowid)
{
	var OrderFreqRowid=GetCellData(rowid,"OrderFreqRowid");
	var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
	var OrderPriorRemarks = GetCellData(rowid,"OrderPriorRemarksRowId");
	OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
	//OrderPriorRowid=ReBulidOrderPrior(OrderPriorRowid).OrderPriorRowid;
	var OrderType = GetCellData(rowid, "OrderType");
	var OrderPHPrescType =GetCellData(rowid,"OrderPHPrescType");
    var OrderVirtualtLong=GetCellData(rowid, "OrderVirtualtLong");
	var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
	var OrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
	var DCARowIDStr = mPiece(OrderHiddenPara, String.fromCharCode(1), 20);
	var	DCAAssScaleID=DCARowIDStr.split("#")[1]||'';
	var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
	var styleConfigObj={OrderDur:true};
	if ((OrderType=="R")||(OrderPHPrescType=='4')||(('^'+GlobalObj.FrequencedItemCat+'^').indexOf('^'+OrderItemCatRowid+'^')>-1)){
		if((OrderPriorRowid!=GlobalObj.OutOrderPriorRowid)&&(OrderPriorRowid!=GlobalObj.OneOrderPriorRowid)&&(GlobalObj.PAAdmType=='I')){
			CheckDurat();
			styleConfigObj={OrderDur:false};
		}else if(OrderMasterSeqNo){
			styleConfigObj={OrderDur:false};
		}else if ((OrderFreqRowid == GlobalObj.STFreqRowid) || (OrderFreqRowid == GlobalObj.ONCEFreqRowid)) {
			CheckDurat();
			styleConfigObj.OrderDur=false;
		}else if((OrderVirtualtLong=="Y")||(DCAAssScaleID!="")){
			styleConfigObj.OrderDur=false;
		}
	}else{
		styleConfigObj.OrderDur=false;
	}
	//ChangeCellDisable(rowid, styleConfigObj);
	ChangeRowStyle(rowid, styleConfigObj);
	function CheckDurat(){
		//ST即刻医嘱不允许录入其他疗程只能是1天
		var OrderDurFactor=parseFloat(GetCellData(rowid, "OrderDurFactor"));
		var OrderDurRowid=GetCellData(rowid, "OrderDurRowid")
		if(!IsLongPrior(OrderPriorRowid)&&((OrderDurFactor!=1)||(OrderDurRowid==''))){
			var rtn=tkMakeServerCall("web.DHCDocOrderCommon", "GetFirstDurByWeekFreq",1);
			if (rtn!=""){
				var OrderDurRowid=rtn.split(",")[0];
				var OrderDur=rtn.split(",")[1];
				var OrderDurFactor=rtn.split(",")[3];
				SetCellData(rowid, "OrderDur", OrderDur)
				SetCellData(rowid, "OrderDurRowid", OrderDurRowid);
				SetCellData(rowid, "OrderDurFactor", OrderDurFactor);
				var OrderSeqNo = GetCellData(rowid, "id");
				ChangeLinkOrderDur(OrderSeqNo, OrderDurRowid, OrderDur, OrderDurFactor);
			}
		}
	}
}
///显示【警示灯】列
function OrderMKLightShow(value,rowData,rowIndex){
	var str="<label id=\""+"_"+rowIndex.id+"_"+"OrderMKLight"+"\" name=\""+"_"+rowIndex.id+"_"+"OrderMKLight"+ "\"><div id=\"McRecipeScreenLight_" + rowIndex.id + "\"  class=\"mcScreenLight_null\" onclick = \"MDC_ShowWarningHint("+rowIndex.id+")\" WIDTH=80></div></label>";
	return str;
}
function OpenOrdCASign(){
	var lnk = "docorder.casign.hui.csp?EpisodeID=" + GlobalObj.EpisodeID + "&ViewAll=ALL";
	if(typeof websys_writeMWToken=='function') lnk=websys_writeMWToken(lnk);
    window.open(lnk, true, "status=1,scrollbars=1,top=20,left=10,width=1300,height=690");
}
/**
* @description: 让用户选择周频次执行周数并返回用户的选择
* @param {String} 
* @return: {String} 
*/
function GetOrderFreqWeekStr(OrderFreqRowid,OrderFreqDispTimeStr,OrderName,callBackFun){
	var OrderFreqDispTimeStr=OrderFreqDispTimeStr.split(String.fromCharCode(1)).join("A");
	OrderFreqDispTimeStr=OrderFreqDispTimeStr.split(String.fromCharCode(2)).join("B");
	OrderFreqDispTimeStr=OrderFreqDispTimeStr.replace(/:/g,"C");
	websys_showModal({
		iconCls:'icon-w-ok',
		url:"doc.weekfreqselector.csp?OrderFreqDispTimeStr=" + OrderFreqDispTimeStr+"&OrderFreqRowid="+OrderFreqRowid,
		title:OrderName+$g(' 周频次选择'),
		width:300,height:410,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			if (typeof result=="undefined"){
				result="";
			}
			callBackFun(result);
		}
	})
}
/// 将频次扩展字符串转换为存储在医嘱表的数据串
function CalOrderFreqExpInfo(OrderFreqDispTimeStr)
{
	var OrderFreqWeekStr="",OrderFreqFreeTimeStr="";
	if (OrderFreqDispTimeStr==""){
		return OrderFreqWeekStr+"^"+OrderFreqFreeTimeStr;
	}
	var ArrData = OrderFreqDispTimeStr.split(String.fromCharCode(1));
    for (var i = 0; i < ArrData.length; i++) {
        var ArrData1 = ArrData[i].split(String.fromCharCode(2));
        var DispTime = ArrData1[0];
        var DispWeek = ArrData1[1];
        var PHCDTRowID = ArrData1[2];
		if(typeof(DispWeek)=='undefined') DispWeek="";
		if(typeof(PHCDTRowID)=='undefined') PHCDTRowID="";
        if (DispWeek!=""){
	        //周频次
	        if (OrderFreqWeekStr.indexOf(DispWeek)>=0){
		    	continue;
		    }
	        if (OrderFreqWeekStr==""){
		    	OrderFreqWeekStr=DispWeek; 
		    }else{
				OrderFreqWeekStr=OrderFreqWeekStr+"|"+DispWeek; 
			}
        }else if ((DispTime!="")){		//&&(PHCDTRowID!="") 应该没必要判断id，间隔时间频次没有id，护士绑定医嘱时修改频次会返回空
	    	//不规则分发时间频次
	    	if (OrderFreqFreeTimeStr.indexOf(DispTime)>=0){
		    	continue;
		    }
			if (OrderFreqFreeTimeStr==""){
		    	OrderFreqFreeTimeStr=DispTime; 
		    }else{
				OrderFreqFreeTimeStr=OrderFreqFreeTimeStr+"|"+DispTime; 
			}
	    }
    }
    return OrderFreqWeekStr+"^"+OrderFreqFreeTimeStr;
}
/**
* @description: 让用户选择不规则分发时间频次的分发时间并返回
* @param {String} 
* @return: {String} 
*/
function GetOrderFreqFreeTimeStr(OrderFreqRowid,OrderFreqDispTimeStr,OrderName,callBackFun,OrderItemVerifiedObj){
	var OrderFreqDispTimeStr=OrderFreqDispTimeStr.split(String.fromCharCode(1)).join("A");
	OrderFreqDispTimeStr=OrderFreqDispTimeStr.split(String.fromCharCode(2)).join("B");
	OrderFreqDispTimeStr=OrderFreqDispTimeStr.replace(/:/g,"C");
	var LinkedMasterOrderFreFactor="";
	if (OrderItemVerifiedObj) {
		LinkedMasterOrderFreFactor=OrderItemVerifiedObj.LinkedMasterOrderFreFactor;
	}
	websys_showModal({
		iconCls:'icon-w-ok',
		url:"dhcdoc.freq.disptime.csp?OrderFreqDispTimeStr=" + OrderFreqDispTimeStr+"&OrderFreqRowid="+OrderFreqRowid+"&LinkedMasterOrderFreFactor="+LinkedMasterOrderFreFactor,
		title:OrderName+$g(' 分发时间选择'),
		width:370,height:410,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			if (typeof result=="undefined"){
				result="";
			}
			callBackFun(result);
		}
	})
	
}

function AddCPWOrdClickHandler(){
	// \scripts\DHCMA\SS\interface\ToDoctor.js 医政组接口
	addOrdItemToDoc(GlobalObj.EpisodeID,"W",addOEORIByCPW,GlobalObj.PAAdmType);
	return 0;
}
function CheckMasterOrdStyle()
{
    var allrowids = GetAllRowId();
    for (var i = 0; i < allrowids.length; i++) {
        var id1 = allrowids[i];
        var ItemRowid1 = GetCellData(id1, "OrderItemRowid");
        if (ItemRowid1 != "") continue;
        var MasterSeqNo1 = GetCellData(id1, "OrderMasterSeqNo");
        if (MasterSeqNo1!="") continue;
		var RowArry = GetSeqNolist(id1);
	    if (!RowArry.length){
			if ($("#"+ id1).find("td").hasClass("OrderMasterM")){
				$("#" + id1).find("td").removeClass("OrderMasterM");
			}
		}else{
			$("#" + id1).find("td").addClass("OrderMasterM");
		}
    }
}
//使用局部刷新,这样除第一次渲染较慢重复使用较快
function xhrRefresh(Args){
	$(".messager-button a").click(); //自动关闭上一个患者的alert弹框
	//有可能是诊疗界面没有配置CheckLinkDetails,会在这个地方切换失败，在这不能局部刷新了，要重置url
	if (typeof GlobalObj=="undefined"){
		ReloadUrl(Args.adm,Args.papmi,Args.madm)
		return;
	}
	CopyOeoriDataArr = new Array();
	if ((typeof Args.copyOeoris !="undefined")&&(typeof Args.copyTo !="undefined")&&(Args.copyOeoris !="")){
		var copyOeorisArr=Args.copyOeoris.split("^");
		var CopyPriorCodeRowid = cspRunServerMethod(GlobalObj.GetOrderPriorByCodeMethod, Args.copyTo);
		for (var i = 0; i < copyOeorisArr.length; i++) {
			var dataItem = tkMakeServerCall("web.DHCDocMain", "CreateCopyItem", copyOeorisArr[i],CopyPriorCodeRowid,session['LOGON.USERID']);
			if (dataItem=="") continue
			CopyOeoriDataArr.push(dataItem);
		}
	}
	//CDSS回写医嘱局部刷新时处理
	var copyCDSSData=Args.copyCDSSData;
	var papmi=GetMenuPara("PatientID");
	var adm=GetMenuPara("EpisodeID");
	var EpisPatObj={EpisodeID:Args.adm};
	var FixedEpisodeID=GetFixedEpisodeID(EpisPatObj);
	if (FixedEpisodeID!="") adm=FixedEpisodeID;
	if ((adm==GlobalObj.EpisodeID)||(adm=="")){
		if (CopyOeoriDataArr.length>0){
			var EpisPatInfo = tkMakeServerCall("web.DHCDocViewDataInit", "InitPatOrderViewGlobal", adm,"",GlobalObj.EmConsultItm);
			var EpisPatObj=eval("("+EpisPatInfo+")");
			InitPatOrderViewGlobal(EpisPatInfo);
			AddCopyItemToList(CopyOeoriDataArr);
			CopyOeoriDataArr=undefined;
		}
		if(typeof CDSSObj=='object') CDSSObj.AddOrdToList(copyCDSSData);
		var LockMessage = tkMakeServerCall("web.DHCDocViewDataInit", "GetLock", adm, session['LOGON.USERID']);
		ShowSecondeWin("onOpenDHCEMRbrowse");
        //HideWindowMask();
		return
	}
	DocumentUnloadHandler(); //此方法内的ClearSessionData会删除锁表数据，需放在后台加锁程序之前，防止最新切换的患者的加锁记录被清除
	var EpisPatInfo = tkMakeServerCall("web.DHCDocViewDataInit", "InitPatOrderViewGlobal", adm,"",GlobalObj.EmConsultItm);
	var EpisPatObj=eval("("+EpisPatInfo+")");
	///以下情况务必走强制刷新，保证界面样式正确变化
	if (
		(EpisPatObj.OnlyShortPrior!=GlobalObj.OnlyShortPrior)||
		(EpisPatObj.LoginAdmLocFlag!=GlobalObj.LoginAdmLocFlag)||
		(EpisPatObj.PAAdmType!=GlobalObj.PAAdmType)||
		(EpisPatObj.INAdmTypeLoc!=GlobalObj.INAdmTypeLoc)||
		((GlobalObj.DoctorType=="DOCTOR")&&(EpisPatObj.CPWOrdFlag!=GlobalObj.CPWOrdFlag))
	){
		ReloadUrl(EpisPatObj.EpisodeID,EpisPatObj.PatientID,EpisPatObj.mradm);
		return;
	}
	$(".window-mask.alldom").show();
	
	InitPatOrderViewGlobal(EpisPatInfo);
	//推到堆栈，保证遮罩优先展示--PB by tanjishan 担心出现多个患者伪并发到这步
	//window.requestAnimationFrame(function(){
		
		$('#Order_DataGrid').jqGrid('clearGridData');
		var postData=$('#Order_DataGrid').jqGrid("getGridParam", "postData");
		$.extend(postData,{ADMID:GlobalObj.EpisodeID});
		///刷新行上的病人相关内容，比如费别
		var colModel=$('#Order_DataGrid').jqGrid("getGridParam", "colModel");
		colModel=colModel.slice(0,1).concat(ListConfigObj.colModel)
		$('#Order_DataGrid').jqGrid("setGridParam", {colModel:colModel,postData:postData}).trigger('reloadGrid');
		if (CopyOeoriDataArr.length>0){
			AddCopyItemToList(CopyOeoriDataArr);
			CopyOeoriDataArr=undefined;
		}
		if ($("#ChronicDiag").length>0){
			$("#ChronicDiag").lookup("setValue","").lookup("setText","");
		}
        xhrRefreshFrame({EpisodeID:EpisPatObj.EpisodeID,PatientID:EpisPatObj.PatientID,maradm:EpisPatObj.mradm});
        HideWindowMask();
	//});
	function ReloadUrl(EpisodeID,PatientID,mradm){
		if (typeof(history.pushState) === 'function') {
	        var Url=window.location.href;
	        Url=rewriteUrl(Url, {
		        EpisodeID:EpisodeID,
	        	PatientID:PatientID,
	        	mradm:mradm,
	        	EpisodeIDs:"",
	        	copyOeoris:"",
	        	copyTo:""});
	        history.pushState("", "", Url);
	        window.location.reload();
	        return;
	    }
		return;
	}
}
function GetFixedEpisodeID(EpisPatObj){
	var FixedEpisodeID="";
	if ((parent)&&((parent.FixedEpisodeID)&&(typeof parent.FixedEpisodeID!="undefined"))){
		FixedEpisodeID=parent.FixedEpisodeID;
	}
	if ((parent.parent.FixedEpisodeID)&&(typeof parent.parent.FixedEpisodeID!="undefined")){
		FixedEpisodeID=parent.parent.FixedEpisodeID;
	}
	// 若标识switchSysPat为N,用的是request内的病人,且不能切换病人
	if ((parent.switchSysPat)&&(parent.switchSysPat=="N")) {
		FixedEpisodeID=EpisPatObj.EpisodeID;
	}
	return FixedEpisodeID;
}
function InitPatOrderViewGlobal(EpisPatInfo,CallTime){
	try {
		var EpisPatObj=eval("("+EpisPatInfo+")");
		var AnaesthesiaID=GetMenuPara("AnaesthesiaID");
		var PPRowId=GetMenuPara("PPRowId");
		
		$.extend(EpisPatObj,{
			AnaesthesiaID:AnaesthesiaID,
			PPRowId:PPRowId
		});
		var adm=GetMenuPara("EpisodeID");
		var FixedEpisodeID=GetFixedEpisodeID(EpisPatObj);
		if ((adm!="")&&(adm!=EpisPatObj.EpisodeID)&&(FixedEpisodeID!=EpisPatObj.EpisodeID)){
			xhrRefresh({adm:adm});
			return;
		}
		$.extend(GlobalObj,EpisPatObj);
		for (key in VerifiedOrderObj) {
			VerifiedOrderObj[key] = "";
		}
		//f12调试模式下有可能会让alert变成只在本frame最前，其他frame下的菜单还是可以切换（尤其是病人列表）,这里一定不能有阻塞弹窗
		if (GlobalObj.PilotProCareFlag=="-1") {
			if (GlobalObj.PilotProCareTel!="") {
				$.messager.alert("警告",$g("该患者正在参与临床试验:")+GlobalObj.PilotProName+$g("，如需了解详细信息，请与研究医生:")+GlobalObj.PilotProCare+"，"+$g("电话")+"："+GlobalObj.PilotProCareTel+$g(" 联系。"),"info");
			}else {
				$.messager.alert("警告",$g("该患者正在参与临床试验:")+GlobalObj.PilotProName+$g("，如需了解详细信息，请与研究医生:")+GlobalObj.PilotProCare+$g(" 联系。"),"info");
			}
			
		}
		if ((GlobalObj.PatInIPAdmission==1)&&(GlobalObj.PAAdmType!="I")){
			$.messager.alert("警告",'患者正在住院!');
		}
		if (GlobalObj.IsDeceased=="Y"){
			 $.messager.alert("警告",'患者已故!')
		}
		
		var warning=GetPromptHtml();
		$("#Prompt").html(warning);
		///解析内部产品组复制过来的医嘱信息
		if (GlobalObj.CopyItemJson!=""){
			var CopyItemObj=eval("("+GlobalObj.CopyItemJson+")");
			if (CopyItemObj.length>0){
				if (typeof CopyOeoriDataArr=="undefined"){
					CopyOeoriDataArr=new Array();
				}
				for (var i = 0; i < CopyItemObj.length; i++) {
					CopyOeoriDataArr.push(CopyItemObj[i].Data);
				}
			}
		}
		var Index=$.inArray($g("费别"),ListConfigObj.colNames);
		if (Index>=0){
			ListConfigObj.colModel[Index].editoptions.value=GlobalObj.PrescriptTypeStr;
		}
		if ($("#Order_DataGrid").jqGrid('getGridParam','colNames')) {
			var Index=$.inArray("费别",$("#Order_DataGrid").jqGrid('getGridParam','colNames'))
			if (Index>=0){
				$("#Order_DataGrid").jqGrid('getGridParam',"colModel")[Index].editoptions.value=GlobalObj.PrescriptTypeStr;
			}
		}
		GetDefaultPilotPro();
		 if ((EpisPatObj.PracticeShowFlag>0)&&(GlobalObj.warning == "")){
			ShowPracticeOrder();
		}
		InitOrderPrior();
    	InitButtonBar();
    	//对外接口初始化
    	if (CallTime != "AfterInsert") {
	    	var argObj={
				EpisodeID:GlobalObj.EpisodeID,
			    PAAdmType:GlobalObj.PAAdmType
			};
	    	Common_ControlObj.xhrRefresh(argObj);
    	}
	}catch(e) {
		//此方法局部刷新和页面初始化时会调用,如果报错可能导致错误难排查,需加错误提示性信息
		$.messager.alert("提示信息","调用InitPatOrderViewGlobal函数异常,错误信息："+e.message); 
		return false;
	}
}
function ReSetPilotDefaultData(){
	GlobalObj.PilotProStr="";
	GlobalObj.CFPilotPatAdmReason="";
	GlobalObj.CFIPPilotPatAdmReason="";
	GlobalObj.PilotProWarning="";
}
function InitRowLookUp(rowid){
	InitOrderNameLookup(rowid);
	InitOrderInstrLookup(rowid);
	InitOrderFreqLookup(rowid);
	InitOrderDurLookup(rowid);
	InitDateFlatpickr(rowid);
	InitOrderRecDep(rowid);
}
function InitOrderNameLookup(rowid){ 
	$("#"+rowid+"_OrderName").lookup({
        url:$URL,
        mode:'remote',
        method:"Get",
        idField:'HIDDEN',
        textField:'ARCIMDesc',
        /*columns:[[  
           {field:'ARCIMDesc',title:'医嘱名称',width:250,sortable:false},
           {field:'subcatdesc',title:'子类',width:100,sortable:false},
           {field:'ItemPrice',title:'价格',width:80,sortable:false},
           {field:'InsuNationCode',title:'医保国家编码',width:100,sortable:false},
           {field:'InsuNationName',title:'医保国家名称',width:100,sortable:false},
           {field:'BasicDrugFlag',title:'基本药物',width:90,sortable:false},
           {field:'billuom',title:'计价单位',width:90,sortable:false},
           {field:'StockQty',title:'库存数',width:80,sortable:false},
           {field:'PackedQty',title:'打包数',width:80,sortable:false},
           {field:'GenericName',title:'通用名',width:120,sortable:false},
           {field:'FormDesc',title:'剂型',width:90,sortable:false},
           {field:'ResQty',title:'在途数',width:80,sortable:false},
           {field:'DerFeeRules',title:'收费规定',width:90,sortable:false},
           {field:'InsurClass',title:'医保类别',width:90,sortable:false},
           {field:'InsurSelfPay',title:'自付比例',width:90,sortable:false},
           {field:'Recloc',title:'接收科室',width:100,sortable:false},
           {field:'arcimcode',title:'代码',width:90,sortable:false}
        ]],*/
        className:"web.DHCDocOrderEntry",
		queryName:"LookUpItem", 
		enableNumberEvent:true,
        pagination:true,
        rownumbers:true,
        panelWidth:1000,
        panelHeight:500,
		//panelMinHeight:350,
		panelHeightFix:true,	//	是否自适应高度。在可见区域内最大化显示放大镜高度。	false	配置了selectRowRender时,值自动为true
		panelMaxHeight:500,		//	解决临界行弹出lookup不自动变更为top位置显示(因为lookup是基于iframe创建的)，导致lookup下边缘被遮罩问题
		panelMinHeight:350,		//	但是会产生lookup整体大小闪烁的问题
        isCombo:GlobalObj.OEORIRealTimeQuery==1?true:false,
        minQueryLen:2,
        delay:'200',
        queryOnSameQueryString:true,
        queryParams:{ClassName: 'web.DHCDocOrderEntry',QueryName: 'LookUpItem'},
        rowStyler: function(index,row){
	        var ArcimID=row["HIDDEN"];
            var Type=row["HIDDEN2"];
            var OrderType=row["HIDDEN4"];
            var HaveStock=row["HIDDEN16"];
            var INCIItemLocked=row["INCIItemLocked"];
            if (INCIItemLocked=="Y") {
	            return 'background-color:#FF8C00;';
	        }
            if ((OrderType=="R")&&(Type="ARCIM")&&(HaveStock!="Y")){
	            return 'background-color:#DDA0DD;';
            }
	    },
		onColumnsLoad:function(columns){
		},
		onLoadSuccess:function(Data){
            //加载药品图标样式
            PHA_COM.Drug.Tips();
        },
        onBeforeLoad:function(param){
	        var desc=param['q'];
	        if (desc=="") return false;
	        PageLogicObj.SearchName=desc;
		    var CurLogonDep = session['LOGON.CTLOCID'];
		    var GroupID = session['LOGON.GROUPID'];
		    var catID = "",subCatID="",OrdCatGrp="";
		    var LogonDep = GetLogonLocByFlag();
		    var P5 = "",P9 = "",P10 = "";
		    var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
		    var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
		    OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
		    // 医嘱类型非强制模式时检索医嘱不判断医嘱类型
		    if (GlobalObj.OrderPriorContrlConfig=="2"){
			    OrderPriorRowid="";
			}
		    var OrdCateGoryRowId = GetCellData(rowid, "OrdCateGoryRowId")
		    var OrdCateGoryObj = document.getElementById(rowid + "_OrdCateGory");
		    if (OrdCateGoryObj){
		       if (+OrdCateGoryObj.scrollWidth != "0") OrdCatGrp = OrdCateGoryRowId
		    }
			var OrderOpenForAllHosp=$("#OrderOpenForAllHosp").checkbox("getValue")?1:0;
			param = $.extend(param,
				{Item:desc,GroupID:GroupID,Category:"",SubCategory:"",TYPE:P5,
				 OrderDepRowId:LogonDep,OrderPriorRowId:OrderPriorRowid,
				 EpisodeID:GlobalObj.EpisodeID,BillingGrp:P9,BillingSubGrp:P10,UserRowId:session["LOGON.USERID"],
				 OrdCatGrp:OrdCatGrp,NonFormulary:"",Form:CurLogonDep,Strength:"",Route:"^^"+OrderOpenForAllHosp
       	   });
	    },onSelect:function(ind,item){
			if (!item) return;
		    var ItemArr=new Array();
		    $.each(item, function(key, val) {
				ItemArr.push(val);
			});
			$("#"+rowid+"_OrderName").parent().parent().removeClass('OrderCritical');
			$("#" + rowid).find("td").removeClass("SkinTest");
			SetCellData(rowid, "OrderARCIMRowid","");
    		SetCellData(rowid, "OrderARCOSRowid","");
			OrderItemLookupSelect(ItemArr.join("^"),rowid);
		},onHidePanel:function(){
			PageLogicObj.LookupPanelIsShow=0;
		},onShowPanel:function(){
			PageLogicObj.LookupPanelIsShow=1;
		},onBeforeShowPanel:function(){
			if ($(".window-mask").is(":visible")){
				//$(".messager-button a").click();
				return false;
			}
			$(this).lookup('panel').panel('resize',{width:1000});
		},selectRowRender:function(row){
			var OrderMsg="";
			if ((row)&&(row['Recloc'])) {
				var INCIItemLocked=row["INCIItemLocked"];
				var CFNotAutoChangeRecloc=GlobalObj.CFNotAutoChangeRecloc;
				if ((row['Recloc'].split("/").length==1)&&(INCIItemLocked!="Y")&&(CFNotAutoChangeRecloc==1)){
					OrderMsg=row['Recloc']+":"+row['StockQty'];
				}else{
					var OrderDepRowId= "";
					if ($("#FindByLogDep").checkbox("getValue")){
						OrderDepRowId= session['LOGON.CTLOCID'];
					}
					OrderMsg = tkMakeServerCall("web.DHCDocOrderCommon", "GetOrderStockMsg", GlobalObj.EpisodeID,row['HIDDEN'],row['Recloc'],OrderDepRowId);
				}
			}
			if(OrderMsg=='') return '';
            var innerHTML="<div style='height:50px;background:#FFFFFF'>";
            innerHTML=innerHTML+"<div style='width:1000px;color:red;font-size:18px;'>";
            innerHTML=innerHTML+OrderMsg;
            innerHTML=innerHTML+"</div>";
            innerHTML=innerHTML+"</div>";
            return innerHTML;
		}
    });
    $("#"+rowid+"_OrderName").change(OrderNameChangeHandle);
}
function OrderNameChangeHandle(e){
	var id=e.currentTarget.id;
	var Row=id.split("_")[0];
	var OrderName = GetCellData(Row, "OrderName");
	if (OrderName=="") {
		var OrderARCIMRowid = GetCellData(Row, "OrderARCIMRowid");
		var OrderARCOSRowid = GetCellData(Row, "OrderARCOSRowid");
		if ((OrderARCIMRowid!="")||(OrderARCOSRowid!="")){
			$.messager.confirm("确认对话框", "医嘱名称已清空，是否删除此行？", function (r) {
				if (r) {
					DeleteRows([Row]);
					var records = $('#Order_DataGrid').getGridParam("records");
			        if (records == 0) {
			            $('#cb_Order_DataGrid').prop('checked', false);
			            Add_Order_row();
			        }
				}else{
					if (OrderARCIMRowid!="") {
						$.cm({
						    ClassName:"web.DHCDocOrderCommon",
						    MethodName:"GetFormateOrderName",
						    ArcimRowid:OrderARCIMRowid,
						    CurLogonHosp:session['LOGON.HOSPID'],
						    dataType:"text"
						},function(OrderName){
							SetCellData(Row, "OrderName",OrderName);
						})
					}else{
						$.cm({
						    ClassName:"web.DHCDocOrderCommon",
						    MethodName:"GetARCOSName",
						    ARCOSRowid:OrderARCOSRowid,
						    dataType:"text"
						},function(ARCOSName){
							SetCellData(Row, "OrderName",ARCOSName);
						})
					}
				}
			});
		}
	}
}
function InitDateFlatpickr(rowid){
	var dateFormate="d/m/Y H:i:S"; //d-m-Y H:i:S
    if (PageLogicObj.defaultDataCache==3){
        dateFormate="Y-m-d H:i:S"
    }
    PageLogicObj.fpArr.push({"rowid":rowid});
    var index=$.hisui.indexOfArray(PageLogicObj.fpArr,"rowid",rowid);
	PageLogicObj.fpArr[index].OrderStartDate=$("#"+rowid+"_OrderStartDate").flatpickr({
    	enableTime: true,
    	enableSeconds:true,
    	dateFormat: dateFormate,
    	time_24hr: true,
    	onOpen:function(pa1,ap2){
	    	var index=$.hisui.indexOfArray(PageLogicObj.fpArr,"rowid",rowid);
	        PageLogicObj.fpArr[index]["OrderStartDate"].setDate(ap2,true);
	    }
    })
    PageLogicObj.fpArr[index].OrderDate=$("#"+rowid+"_OrderDate").flatpickr({
    	enableTime: true,
    	enableSeconds:true,
    	dateFormat: dateFormate,
    	time_24hr: true,
    	onOpen:function(pa1,ap2){
	    	var index=$.hisui.indexOfArray(PageLogicObj.fpArr,"rowid",rowid);
	        PageLogicObj.fpArr[index]["OrderDate"].setDate(ap2,true);
	    }
 
    })
    PageLogicObj.fpArr[index].OrderEndDate=$("#"+rowid+"_OrderEndDate").flatpickr({
    	enableTime: true,
    	enableSeconds:true,
    	dateFormat: dateFormate,
    	time_24hr: true,
    	onOpen:function(pa1,ap2){
	    	var index=$.hisui.indexOfArray(PageLogicObj.fpArr,"rowid",rowid);
	        PageLogicObj.fpArr[index]["OrderEndDate"].setDate(ap2,true);
	    }
 
    })
}
/// 把接受科室初始化，可以做检索
function InitOrderRecDep(rowid) {
	var obj = document.getElementById(rowid + "_OrderRecDep");
	if (obj.type == "select-one"){
		return;
	}
	// 删掉上层的span标签，防止在拖拽列宽时影响combobox的宽度计算
	if (($(obj).parent("span"))&&($(obj).parent("span").attr("class").indexOf("editable")>=0)){
		var $objClone=$(obj.cloneNode());
		$objClone.css({width:'98%'})
		var $TR=$(obj).parent().parent();
		$TR.empty();
		$TR.append($objClone);
		$obj=$objClone;
	}else{
		$obj=$(obj);
	}
	var $OrderRecDep=$("#"+rowid+"_OrderRecDep");
	//console.log("InitOrderRecDep:"+rowid)
	$OrderRecDep.combobox({
		valueField:'id',
		textField:'text',
		panelHeight:"auto",
		defaultFilter:6,
		//required:true,
		//hasDownArrow:false,
		//editable:false,
		width:$obj.width(),
		onHidePanel:function(){
			var rowid = this.id.split("_")[0];
			var OrderRecDepRowid=GetCellData(rowid, "OrderRecDep");
			if (OrderRecDepRowid==GetCellData(rowid, "OrderRecDepRowid")){
				return;
			}
			SetCellData(rowid, "OrderRecDepRowid",OrderRecDepRowid);
			if (OrderRecDepRowid==""){
				//$(this).next().find(".combo-text:not(:disabled)").addClass("validatebox-invalid");
				$(this).combobox("textbox").addClass("validatebox-invalid");
				SetFocusCell(rowid, "OrderRecDep");
				return;
			}else{
				//$(this).next().find(".combo-text:not(:disabled)").removeClass("validatebox-invalid");
				$(this).combobox("textbox").removeClass("validatebox-invalid");
			}
			OrderRecDepchange(rowid);
		},
		onChange:function(newValue, oldValue){
			//console.log(newValue, oldValue);
		},
		onSelect:function(record){
			//console.table(record);
			//该事件会在使用键盘选择Panel选项时，依次触发onselect，有可能会在切换过程中清空数量等内容
			// var rowid = this.id.split("_")[0];
			// SetCellData(rowid, "OrderRecDepRowid",record.id);
			// SetCellData(rowid, "OrderRecDep", record.id);
			// OrderRecDepchange(rowid);
		}
	});
	$OrderRecDep.combobox("textbox").bind("click.combo",function(){
		////点击输入框时弹出Pannel
		var options=$OrderRecDep.combobox("options");
		if (options.editable){
			$OrderRecDep.combobox("showPanel");
		}
	});
}
function InitOrderInstrLookup(rowid){
	$("#"+rowid+"_OrderInstr").lookup({
        url:$URL,
		fitColumns:true,
        mode:'remote',
        method:"Get",
        idField:'HIDDEN',
        textField:'Desc',
        columns:[[  
           {field:'Desc',title:'用法名称',width:130,sortable:false},
           {field:'Code',title:'用法编码',width:130,sortable:false}
        ]],
        pagination:true,
		panelHeightFix:true,
        panelWidth:400,
        panelHeight:300,
        isCombo:true,
        minQueryLen:0,
        delay:'200',
        queryOnSameQueryString:true,
        queryParams:{ClassName: 'web.DHCDocOrderCommon',QueryName: 'LookUpInstr'},
        onBeforeLoad:function(param){
	        var desc=param['q'];
		    var ARCIMRowId = GetCellData(rowid, "OrderARCIMRowid");
		    var OrderSkinTest=GetCellData(rowid, "OrderSkinTest");
    		var OrderActionRowid=GetCellData(rowid, "OrderActionRowid");
    		var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara");
    		var OrderInstrRowid=GetCellData(rowid, "OrderInstrRowid");
    		
    		var NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
    		if ((NeedSkinTestINCI!="Y")&&$("#" + rowid).find("td").hasClass("OrderMasterM")){
				var RowArry = GetSeqNolist(rowid)
		        for (var i = 0; i < RowArry.length; i++) {
		            var OrderHiddenPara = GetCellData(RowArry[i], "OrderHiddenPara");
		            NeedSkinTestINCI = mPiece(OrderHiddenPara, String.fromCharCode(1), 7);
		            if (NeedSkinTestINCI=="Y"){
			            OrderSkinTest=GetCellData(RowArry[i], "OrderSkinTest");
    					OrderActionRowid=GetCellData(RowArry[i], "OrderActionRowid");
    					OrderInstrRowid=GetCellData(RowArry[i], "OrderInstrRowid");
			        	break;   
			        }
		        }
			}
		    var SeachSkinInstrFlag="";
		    var Instr="^"+OrderInstrRowid+"^";
			//治疗类的医嘱，不再允许选中皮试用法
			if (NeedSkinTestINCI=="Y"){
				if (GlobalObj.DisableOrdSkinChange=="1"){
					if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
						SeachSkinInstrFlag="OnlySkin";
					}else if ((OrderSkinTest=="Y")||(OrderActionRowid!="")){
						SeachSkinInstrFlag="Remove";
					}
				}
			}else if (GlobalObj.DisableOrdSkinChange=="1"){
				SeachSkinInstrFlag="Remove";
				if ((GlobalObj.SkinTestInstr.indexOf(Instr) != "-1")) {
					SeachSkinInstrFlag="OnlySkin";
				}
			}
			
			var ExtInfo=SeachSkinInstrFlag;
			param = $.extend(param,{instrdesc:desc,paadmtype:GlobalObj.PAAdmType,arcimrowid:ARCIMRowId,LocRowId:session['LOGON.CTLOCID'],UserID:session["LOGON.USERID"],ExtInfo:ExtInfo});
	    },onSelect:function(ind,item){
		    var DataLen=$("#"+rowid+"_OrderInstr").lookup("grid").datagrid("getRows").length;
		    //if (DataLen>1) {
			    //查询结果只有一条记录时,会自动调用PHCINDesc_lookuphandlerX里的InstrLookUpSelect,导致重复调用
			    var ItemArr=new Array();
			    $.each(item, function(key, val) {
					ItemArr.push(val);
				});
				InstrLookUpSelect(ItemArr.join("^"),rowid);
			//}
		},onHidePanel:function(){
			PageLogicObj.LookupPanelIsShow=0;
		},onShowPanel:function(){
			PageLogicObj.LookupPanelIsShow=1;
		},onBeforeShowPanel:function(){
			if ($(".window-mask").is(":visible")){
				//$(".messager-button a").click();
				return false;
			}
			$(this).lookup('panel').panel('resize',{width:300});
		}
    });
}
function InitOrderFreqLookup(rowid){
	$("#"+rowid+"_OrderFreq").lookup({
        url:$URL,
		fitColumns:true,
        mode:'remote',
        method:"Get",
        idField:'HIDDEN',
        textField:'Desc',
        columns:[[  
           {field:'Desc',title:'频次名称',width:130,sortable:false},
           {field:'Code',title:'频次编码',width:130,sortable:false}
        ]],
        pagination:true,
		panelHeightFix:true,
        panelWidth:400,
        panelHeight:300,
        isCombo:true,
        minQueryLen:0,
        delay:'200',
        queryOnSameQueryString:true,
        queryParams:{ClassName: 'web.DHCDocOrderCommon',QueryName: 'LookUpFrequency'},
        onBeforeLoad:function(param){
	        var desc=param['q'];
		    var OrderPriorRowid=GetCellData(rowid, "OrderPriorRowid");
		    var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
			var OrderVirtualtLong=GetCellData(rowid, "OrderVirtualtLong");
			OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
		    if ((OrderVirtualtLong=='Y')||(OrderVirtualtLong==true)) {OrderPriorRowid=GlobalObj.LongOrderPriorRowid};
		    var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
		    var InstrucID=GetCellData(rowid, "OrderInstrRowid");
			param = $.extend(param,{desc:desc,PAAdmType:GlobalObj.PAAdmType,UserID:session["LOGON.USERID"],OrderPriorRowid:OrderPriorRowid,OrderARCIMRowid:OrderARCIMRowid,LocID:session['LOGON.CTLOCID'],InstrucID:InstrucID});
	    },onSelect:function(ind,item){
		    if (websys_getTop().$(".window-mask").is(":visible")&&(!websys_showModal("options"))){
				return false;
			}
		    var ItemArr=new Array();
		    $.each(item, function(key, val) {
				ItemArr.push(val);
			});
			FrequencyLookUpSelect(ItemArr.join("^"),rowid);
		},onHidePanel:function(){
			PageLogicObj.LookupPanelIsShow=0;
		},onShowPanel:function(){
			PageLogicObj.LookupPanelIsShow=1;
		},onBeforeShowPanel:function(){
			if ($(".window-mask").is(":visible")){
				//$(".messager-button a").click();
				return false;
			}
			$(this).lookup('panel').panel('resize',{width:300});
		}
    });
}
function InitOrderDurLookup(rowid){
	$("#"+rowid+"_OrderDur").lookup({
        url:$URL,
		fitColumns:true,
        mode:'remote',
        method:"Get",
        idField:'HIDDEN',
        textField:'CTPCPDesc',
        columns:[[  
           {field:'CTPCPDesc',title:'疗程',width:130,sortable:false},
           {field:'CTPCPCode',title:'编码',width:130,sortable:false}
        ]],
        width:80,
        pagination:true,
		panelHeightFix:true,
        panelWidth:400,
        panelHeight:300,
        isCombo:true,
        minQueryLen:0,
        delay:'200',
        queryOnSameQueryString:true,
        queryParams:{ClassName: 'web.DHCDocOrderCommon',QueryName: 'LookUpDuration'},
        onBeforeLoad:function(param){
	        var desc=param['q'];
			param = $.extend(param,{desc:desc});
	    },onSelect:function(ind,item){
		    var ItemArr=new Array();
		    $.each(item, function(key, val) {
				ItemArr.push(val);
			});
			DurationLookUpSelect(ItemArr.join("^"),rowid);
		},onHidePanel:function(){
			PageLogicObj.LookupPanelIsShow=0;
		},onShowPanel:function(){
			PageLogicObj.LookupPanelIsShow=1;
		},onBeforeShowPanel:function(){
			if ($(".window-mask").is(":visible")){
				//$(".messager-button a").click();
				return false;
			}
			$(this).lookup('panel').panel('resize',{width:300});
		}
    });
}
function RestoreChangeRecLoc(rowid,OldRecLocRowid,RecLocStr){
    var ArrData = RecLocStr.split(String.fromCharCode(2));
    for (var i = 0; i < ArrData.length; i++) {
        var ArrData1 = ArrData[i].split(String.fromCharCode(1));
        if (ArrData1[0]==OldRecLocRowid){  //&&(ArrData1[2] != "Y")){
	        SetCellData(rowid, "OrderRecDep", OldRecLocRowid);
    		SetCellData(rowid, "OrderRecDepRowid", OldRecLocRowid);
    		break;
	    }
    }
}
// 验证主子是否可关联
function CheckIsCanSetOrdMasSeqNo(MasterItemSeqNo,SubItemSeqNo,callback)
{
	var OrderARCIMRowid=GetCellData(SubItemSeqNo, "OrderARCIMRowid");
	if (OrderARCIMRowid=="") {
		$.messager.alert("提示", "空医嘱不能关联","info",function(){
	    });
		if (callback) callback();
        return false;
	}
	var MasOrderName=GetCellData(MasterItemSeqNo, "OrderName");
	var SubOrderName=GetCellData(SubItemSeqNo, "OrderName");
    //验证是否未审核
    if ((CheckIsItem(MasterItemSeqNo) == true) || (CheckIsItem(SubItemSeqNo) == true)) {
        $.messager.alert("提示", "已审核医嘱不能关联","info",function(){
	    });
		if (callback) callback();
        return false;
    }
    //验证关联主医嘱是否存在
    var MasOrderARCIMRowid = GetCellData(MasterItemSeqNo, "OrderARCIMRowid");
    if (MasOrderARCIMRowid == "") {
	   $.messager.alert("提示", "关联主医嘱不存在!","info",function(){
	    });
		if (callback) callback();
        return false; 
    }
    //验证主医嘱是否关联本身、主医嘱是否已被关联
    if ($.isNumeric(MasterItemSeqNo) == true) {
        var MasterSeqNo = GetCellData(MasterItemSeqNo, "OrderMasterSeqNo");
        if (MasterSeqNo == MasterItemSeqNo) {
            $.messager.alert("警告", "医嘱不能关联本身","info",function(){
		    });
			if (callback) callback();
            return false;
        }
        if (MasterSeqNo != "") {
            $.messager.alert("警告", "选择主医嘱已经关联其他医嘱","info",function(){
		    });
			if (callback) callback();
            return false;
        }
    }
    //验证主子医嘱附加说明是否有取药医嘱
    var MasOrderPriorRemarksRowId=GetCellData(MasterItemSeqNo, "OrderPriorRemarksRowId");
    var SubOrderPriorRemarksRowId=GetCellData(SubItemSeqNo, "OrderPriorRemarksRowId");
    if ((MasOrderPriorRemarksRowId=="ONE")||(SubOrderPriorRemarksRowId=="ONE")){
        $.messager.alert("警告", "取药医嘱不能关联!","info",function(){
	    });
		if (callback) callback();
    	return false;
    }
    //验证主医嘱是出院带药,子医嘱医嘱类型
    var MainOrderPriorRowid=GetCellData(MasterItemSeqNo,"OrderPriorRowid");
    var subOrderType = GetCellData(SubItemSeqNo, "OrderType");
    if ((MainOrderPriorRowid==GlobalObj.OutOrderPriorRowid)&&(subOrderType!="R")){
        $.messager.alert("提示", SubOrderName+$g(" 子医嘱非药品医嘱,不能和出院带药医嘱关联!"),"info",function(){
	    });
		if (callback) callback();
        return false;
    }
    //如果子医嘱是经过皮试引导选择窗口确定的用法，则需要以子医嘱用法为准
	var MainOrdNumStr=GetMainOrdNumStrInGroup(MasterItemSeqNo,SubItemSeqNo);
	var MainOrdNumErrCode=mPiece(MainOrdNumStr, "^", 0);
    
	//如果是经过皮试引导选择窗口确定的用法，两种用法的使用目的不相同，不允许关联
	if (MainOrdNumErrCode!="0") {
		 $.messager.alert("提示", SubOrderName+$g(" 子医嘱皮试使用目的与主医嘱不同，不允许关联!"),"info",function(){
	    });
		if (callback) callback();
        return false;
	}
    
    /*var SpelAction = GetCellData(SubItemSeqNo, "SpecialAction");
    var SpecialAction = "";
    if (SpelAction.toString().indexOf('||') != -1) SpecialAction = SpelAction.split("||")[0];
	if (SpecialAction != "isEmergency") {*/
	    //验证主医嘱是非药品且不能录入频次疗程,子医嘱是否是药品/允许录入频次疗程的非药品子类
	    var MainStyleConfigStr = GetCellData(MasterItemSeqNo, "StyleConfigStr");
	    var MainStyleConfigObj = {};
	    if (MainStyleConfigStr != "") {
	        MainStyleConfigObj = eval("(" + MainStyleConfigStr + ")");
	    }
	    var MainOrderFreqRowid=GetCellData(MasterItemSeqNo, "OrderFreqRowid");
	    var subOrderPHPrescType = GetCellData(SubItemSeqNo, "OrderPHPrescType");
	    if ((subOrderPHPrescType=="4")||(subOrderType=="R")) {
	        if ((!MainStyleConfigObj.OrderFreq)&&(MainOrderFreqRowid=="")){
	            $.messager.alert("提示", SubOrderName+$g(" 子医嘱必须有频次和疗程,不能关联!"),"info",function(){
			    });
				if (callback) callback();
	            return false;
	        }
	    }
	    var MainOrderInstrRowid=GetCellData(MasterItemSeqNo, "OrderInstrRowid");
	    //验证主医嘱是非药品且不能录入用法,子医嘱是药品/允许录入用法的非药品子类
	    var OrderHiddenPara = GetCellData(SubItemSeqNo, "OrderHiddenPara");
	    var SubOrderItemCatRowid = mPiece(OrderHiddenPara, String.fromCharCode(1), 2);
		//((("^" + GlobalObj.SelectInstrNotDrugCat + "^").indexOf("^" + SubOrderItemCatRowid + "^") >= 0))||
	    if ((subOrderType=="R")) {
		    if ((!MainStyleConfigObj.OrderInstr)&&(MainOrderInstrRowid=="")){
	            $.messager.alert("提示", SubOrderName+$g(" 子医嘱必须录入用法,不能关联!"),"info",function(){
			    });
				if (callback) callback();
	            return false;
	        }
		}
	//}
    //验证主医嘱关联列是否可编辑
    if (!checkOrdMasSeqNoIsEdit(MasterItemSeqNo)){
        $.messager.alert("提示", MasOrderName+$g(" 医嘱不能关联!"),"info",function(){
	    });
		if (callback) callback();
        return false;
    }
    //验证子医嘱关联列是否可编辑
    if (!checkOrdMasSeqNoIsEdit(SubItemSeqNo)){
         var OrderName=GetCellData(SubItemSeqNo, "OrderName");
        $.messager.alert("提示", SubOrderName+$g(" 医嘱不能关联!"),"info",function(){
	    });
		if (callback) callback();
        return false;
    }
    //验证关联的序号所对应的医嘱是否是子医嘱,验证自身是否是主医嘱
    var IsOtherMasOrd = 0; //是否是其它医嘱的主医嘱
    var LinkMasOrdIsOtherSubOrd = 0; //所关联的主医嘱是否是其它医嘱的子医嘱
    var IsSelfLink=0;
    var CurrentOrderSeqNo = GetCellData(SubItemSeqNo, "id");
    var allrowids = GetAllRowId();
    for (var i = 0; i < allrowids.length; i++) {
        var id1 = allrowids[i];
        var ItemRowid1 = GetCellData(id1, "OrderItemRowid");
        if (ItemRowid1 != "") { continue }
        var OrderSeqNo1 = GetCellData(id1, "id");
        var MasterSeqNo1 = GetCellData(id1, "OrderMasterSeqNo");
        if (MasterSeqNo1==OrderSeqNo1){
            IsSelfLink=1;
            break;
        }
        if ((MasterItemSeqNo == OrderSeqNo1) && (MasterSeqNo1 != "")) {
            LinkMasOrdIsOtherSubOrd = 1;
            break;
        }
        if (MasterSeqNo1 == CurrentOrderSeqNo) {
            IsOtherMasOrd = 1;
            break;
        }
    }
    if (IsSelfLink==1){
        $.messager.alert("提示","医嘱不能关联本身!","info",function(){
	    });
		if (callback) callback();
        return false;
    }
    if (IsOtherMasOrd == 1) {
        $.messager.alert("提示","此医嘱是其它医嘱的主医嘱,不能关联!请核实!","info",function(){
	    });
		if (callback) callback();
        return false;
    }
    if (LinkMasOrdIsOtherSubOrd == 1) {
        $.messager.alert("提示","此医嘱所关联的医嘱是其它医嘱的子医嘱,不能关联!请核实!","info",function(){
	    });
		if (callback) callback();
        return false;
    }
	//滴速不一致不能关联
    var MasterSpeedFlowRate =GetCellData(MasterItemSeqNo,"OrderSpeedFlowRate");
    var MasterFlowRateUnit =GetCellData(MasterItemSeqNo,"OrderFlowRateUnit");
    var SubSpeedFlowRate =GetCellData(SubItemSeqNo,"OrderSpeedFlowRate");
    var SubFlowRateUnit =GetCellData(SubItemSeqNo,"OrderFlowRateUnit");
    if (((MasterSpeedFlowRate!="")&&(SubSpeedFlowRate!="")&&(MasterSpeedFlowRate!=SubSpeedFlowRate))||((MasterSpeedFlowRate!="")&&(SubSpeedFlowRate!="")&&(MasterFlowRateUnit!=SubFlowRateUnit))){
	    $.messager.alert("提示","关联医嘱存在两个（多个）不同滴速，请手动修改!","info",function(){
	    });
		if (callback) callback();
        return false;
	}
    return true;
}
function OpenDeathTypeDiagnos(CallBackFun){
    websys_showModal({
		iconCls:'icon-w-list',
		url:"../csp/dhcdoc.deathtypediag.csp?EpisodeID="+GlobalObj.EpisodeID,
		title:$g('请选择死亡诊断'),
		width:500,height:500,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			if ((result == "") || (result == "undefined")||(result == null)) {
		        $.messager.alert("提示", "请选择死亡诊断!","info",function(){
			        CallBackFun(false);
			    });
		    } else {
		        CallBackFun(true);
		    }
		}
	})
}
///实习生审核医嘱
function InsertPriceAdd() {
    var OrderItemStr = "";
    var OrderItem = "";
    var OneOrderItem = "";
	var OrderItemCongeriesNum=0;
	var DataArry = GetGirdData();
	var Count=0; 
	var NeedDelPara=["OrderOperatBtn","StyleConfigStr","OrderMKMsg"]
	for (var i = 0; i < DataArry.length; i++) {
		var OrderItemRowid = DataArry[i]["OrderItemRowid"];
		var OrderARCIMRowid = DataArry[i]["OrderARCIMRowid"];
		var OrderARCOSRowid = DataArry[i]["OrderARCOSRowid"];
		var StyleConfigStr = DataArry[i]["StyleConfigStr"];
		var StyleConfigObj = {};
		if (StyleConfigStr != "") {
			StyleConfigObj = eval("(" + StyleConfigStr + ")");
		}
		if ((GlobalObj.PAAdmType != "I") && (StyleConfigObj.OrderPackQty != true) && (OrderItemRowid != "")) { continue }
		if ((OrderARCIMRowid == "")&&(OrderARCOSRowid=="")) { continue; }
		for(var j=0; j<NeedDelPara.length; j++) {
			delete DataArry[i][NeedDelPara[j]];	//删除一些无用字段，减少长度，以及处理请求中有这些关键词的冲突	--yuanlei
		}
		var RowDataJson=JSON.stringify(DataArry[i]);
		if (OrderItemStr == "") { OrderItemStr = RowDataJson } else { OrderItemStr = OrderItemStr + String.fromCharCode(1) + RowDataJson }
		//存在一次录入20-30条数据时，数据存贮就会变为流，每次插入10条
		if (Count>10){
			var Rtn = cspRunServerMethod(GlobalObj.InsertPrcaticeDocMethod,GlobalObj.EpisodeID,OrderItemStr,session["LOGON.USERID"]);
			OrderItemStr="";
			Count=0;
		}
		Count=Count+1;
	}
	if (OrderItemStr!=""){
		var Rtn = cspRunServerMethod(GlobalObj.InsertPrcaticeDocMethod,GlobalObj.EpisodeID,OrderItemStr,session["LOGON.USERID"])
	}
	return true;
}
//展示实习生页面
function ShowPracticeOrder() {
    if (GlobalObj.EpisodeID) {
	    var mTitle="实习生/建议医嘱处理";
	    if(GlobalObj.PAAdmType != "I"){
		    mTitle="建议医嘱处理";
		}
        websys_showModal({
			iconCls:'icon-w-list',
			url:"ipdoc.practicedocpreorder.hui.csp?EpisodeID=" + GlobalObj.EpisodeID+"&PPRowId="+GlobalObj.PPRowId ,
			title:mTitle,
			width:'98%',height:'95%',
			AddPracticeOrder:AddPracticeOrder,
			GetPreRowId:GetPreRowId,
			CheckIsClear:CheckIsClear
		});
    }
}
//审核实习生医嘱
function AddPracticeOrder(PracticePreary,RowidStr){
	var RowidStrAry=RowidStr.split("^")
	//删除当前最后一行空白行
    var CruRow = GetPreRowId();
    if (CheckIsClear(CruRow) == true) {
        DeleteRow(CruRow);
		CruRow=parseFloat(CruRow)-1;
    }
    function loop(i){
	    new Promise(function(resolve,rejected){
		    var ArrStr=new Array();
			ArrStr=PracticePreary[i]
			$.extend(ArrStr, { "rowid": parseFloat(CruRow)+i+1});
			AddItemDataToRow(ArrStr,ArrStr,"obj",resolve);
		}).then(function(){
			var rowid = GetPreRowId();
			var OrderHiddenPara = GetCellData(rowid, "OrderHiddenPara"); 
	        var Arr=OrderHiddenPara.split(String.fromCharCode(1));
	        Arr.splice(23,1,RowidStrAry[i]);
	        SetCellData(rowid, "OrderHiddenPara",Arr.join(String.fromCharCode(1)));
	        i++;
			if ( i < PracticePreary.length ) {
				 loop(i);
			}else{
				Add_Order_row();
			}
		})
	}
    loop(0);
}
function OrdNotesDetailOpen(ArcimRowIdStr){
	if(typeof ArcimRowIdStr!='string') ArcimRowIdStr='';
	var autoHide=10000;
	if (ArcimRowIdStr==""){
		var Selrowids = GetSelRowId();
        var selRowLen=Selrowids.length
	    for (var i = 0; i <Selrowids.length; i++) {
	        //if (CheckIsItem(Selrowids[i]) == false) {
		        var OrderARCIMRowid=GetCellData(Selrowids[i], "OrderARCIMRowid");
		        if (OrderARCIMRowid=="") continue;
		        if (ArcimRowIdStr=="") ArcimRowIdStr=OrderARCIMRowid;
		        else  ArcimRowIdStr=ArcimRowIdStr+"^"+OrderARCIMRowid;
	        //}
	    }
	    if (ArcimRowIdStr=="") {
		    $.messager.alert("提示","请勾选需要查询备注的医嘱项目!");
	        return false;
		}
		autoHide=0;
	}
	PageLogicObj.m_selArcimRowIdStr=ArcimRowIdStr;
	var HTML=GetPannelHTML("OrdNotestDetail");
	if (HTML.innerHTML==""){return;}
	var maxHeight=ArcimRowIdStr.split("^").length*35+40;
	if (maxHeight>400){
		maxHeight=400;
	}
	$("body").append( '<a id="manualpp"></a>');
	$("#manualpp").popover({
		trigger:'manual',
		placement:'horizontal',
		title:HTML.Title,
		width:HTML.width,
		//height:ArcimRowIdStr.split("^").length*35+40,
		content:HTML.innerHTML,
		autoHide:autoHide,
		closeable:true,
		animated:'fade',
		arrow:false,
		//offsetTop:$(window).height()-933,
		//offsetLeft:($(window).width()-500)/2-10,
		style:'inverse-opacity',
		onShow:function(e,value){
			//if (HTML.CallFunction!="") eval(HTML.CallFunction)();
		},
		onHide:function(e,value){
			$("#manualpp").popover('destroy');
			$("body").remove("#manualpp"); 
			PageLogicObj.m_selArcimRowIdStr="";
		}
	});
	$("#manualpp").popover('show');
}
///获取动态写入的HTML代码
function GetPannelHTML(LinkID){
	var innerHTML="";
	var CallFunction={};
	var Title="";
	var width=200,height=150;
	if (LinkID=="OrdNotestDetail"){
		//innerHTML+='<table id="OrdNotestDetailGrid"></table>'
		innerHTML=LoadOrdNotestDetailGrid();
		width=500,height=300;
		Title="医嘱项提示详情";
	}
	return {
		"innerHTML":innerHTML,
		//"CallFunction":CallFunction,
		"Title":Title,
		"width":width,
		"height":height
	}
}
function LoadOrdNotestDetailGrid(){
	var Columns=[[    
        {title:$g('医嘱项名称'),field:'ArcimDesc',width:200},
        {title:$g('提示信息'),field:'OrderMsg',width:250}
    ]];
    var GridData=$.cm({
	    ClassName:"web.DHCDocOrderEntry",
	    QueryName:"GetArcimNotesList",
	    ArcimRowIdStr:PageLogicObj.m_selArcimRowIdStr,
	    rows:99999
	},false);
	if (GridData['rows'].length==0) return "";
	var innerHTML='<table id="HisAdmGrid" class="norm-table">';
	innerHTML=innerHTML+'<thead><tr><th class="td-norm">'+$g('医嘱项名称')+'</th><th class="td-norm">'+$g('提示信息')+'</th></tr></thead>';
	innerHTML=innerHTML+'<tbody>';
	for (var i=0;i<GridData['rows'].length;i++){
		innerHTML=innerHTML+'<tr><td class="td-norm">'+GridData['rows'][i]['ArcimDesc']+'</td><td class="td-norm">'+GridData['rows'][i]['OrderMsg']+'</td></tr>';
	}
	innerHTML=innerHTML+'</tbody></table>';
	return innerHTML;
}

function ShowFreqQty(FreqDispTimeStr,OrderName,FreqDispTimeDoseQtyStr,OrderDoseUOM,OrderFirstDayTimes,callBackFun) {
	if (FreqDispTimeDoseQtyStr!=""){
		FreqDispTimeDoseQtyStr=FreqDispTimeDoseQtyStr.replace("/||/g","_");	
	}
	var lnk = "dhcdocshowfreq.csp?FreqDispTimeStr=" + FreqDispTimeStr+"&FreqDispTimeDoseQtyStr="+FreqDispTimeDoseQtyStr+"&OrderDoseUOM="+OrderDoseUOM+"&OrderFirstDayTimes="+OrderFirstDayTimes;
	websys_showModal({
		iconCls:'icon-w-edit',
		url:lnk,
		title:OrderName+$g(' 剂量填写'),
		width:300,
		height:350,
		closable:true,
		callBackRetVal:'',
		onBeforeClose:function(){
			callBackFun(websys_showModal("options").callBackRetVal);
		},
		CallBackFunc:function(result){
			if (typeof result=="undefined") result="";
			websys_showModal("options").callBackRetVal=result;
			websys_showModal("close");
		}
	})
	websys_showModal('header').find('.panel-title').css({
		'white-space': 'nowrap',
    	'text-overflow': 'ellipsis',
    	'width': 'calc(100% - 35px)',
   		'overflow': 'hidden'
	});
 }
 function ChangeOrderFreqTimeDoseStr(rowid,callBackFun){
	var OrderInstrRowid = GetCellData(rowid, "OrderInstrRowid");
	if (IsWYInstr(OrderInstrRowid)) {
		SetCellData(rowid, "OrderFreqTimeDoseStr","");
		var StyleConfigObj={};
		$.extend(StyleConfigObj, { OrderDoseQty: true});
		ChangeRowStyle(rowid, StyleConfigObj);
		if (callBackFun) callBackFun();
		return;
	}
	var OrderFreqRowid=GetCellData(rowid, "OrderFreqRowid");
	var OrderHiddenPara=GetCellData(rowid, "OrderHiddenPara");
	var OrderFreqDispTimeStr=GetCellData(rowid, "OrderFreqDispTimeStr");
    var SameFreqDifferentDosesFlag=OrderHiddenPara.split(String.fromCharCode(1))[19];
    if (SameFreqDifferentDosesFlag=="Y"){
	    var FreqDispTimeDoseQtyStr=GetCellData(rowid, "OrderFreqTimeDoseStr");
	    var FreqDispTimeStr=$.m({
		    ClassName:"web.DHCOEOrdItemView",
		    MethodName:"GetFreqFreqDispTimeStr",
		    OrderFreqRowid:OrderFreqRowid,
		    OrderFreqDispTimeStr:OrderFreqDispTimeStr,
		    type:"text"
		},false);
		//if ((FreqDispTimeStr=="")||((FreqDispTimeDoseQtyStr=="")&&(FreqDispTimeStr.split("!").length==1))) {
		if (FreqDispTimeStr.split("!").length==1) {
			SetCellData(rowid, "OrderFreqTimeDoseStr","");
			var OrderDoseQty=GetCellData(rowid, "OrderDoseQty");
			if (OrderDoseQty!="") {
				SetCellData(rowid, "OrderDoseQty",OrderDoseQty.split("-")[0]);
			}
			var StyleConfigObj={};
			$.extend(StyleConfigObj, { OrderDoseQty: true});
			ChangeRowStyle(rowid, StyleConfigObj);
			if (callBackFun) callBackFun();
			return;
		}
		var OrderARCIMRowid=GetCellData(rowid, "OrderARCIMRowid");
		var OrderName=GetCellData(rowid, "OrderName");
		var OrderDoseUOM=GetCellData(rowid, "OrderDoseUOM");
		var OrderFirstDayTimes=GetCellData(rowid, "OrderFirstDayTimes");
		new Promise(function(resolve,rejected){
		    ShowFreqQty(FreqDispTimeStr,OrderName,FreqDispTimeDoseQtyStr,OrderDoseUOM,OrderFirstDayTimes,resolve);
		}).then(function(OrderFreqTimeDoseStr){
			if (OrderFreqTimeDoseStr!=""){
			    SetCellData(rowid, "OrderFreqTimeDoseStr",OrderFreqTimeDoseStr);
			    var DoseQtyStr=GetDoseQty(OrderFreqTimeDoseStr);
			    SetCellData(rowid, "OrderDoseQty",DoseQtyStr);
			    var StyleConfigObj={};
			    //$.extend(StyleConfigObj, { OrderDoseQty: false});
			    $.extend(StyleConfigObj, { OrderDoseQty: "readonly"});
			    ChangeRowStyle(rowid, StyleConfigObj);
			}else{
				SetCellData(rowid, "OrderFreqTimeDoseStr","");
				SetCellData(rowid, "OrderDoseQty","");
				var OrderName=GetCellData(rowid, "OrderName");
				$.messager.alert("提示"," 同频次不同剂量医嘱请务必按照分发时间填写剂量!","info",function(){
					var StyleConfigObj={};
				    $.extend(StyleConfigObj, { OrderDoseQty: true});
				    ChangeRowStyle(rowid, StyleConfigObj);
				})
			}
			if (callBackFun) callBackFun();
		})
	}else{
		if (callBackFun) callBackFun();
	}
}
function GetDoseQty(OrderFreqTimeDoseStr){
	var DoseQtyStr="";
	if (OrderFreqTimeDoseStr=="") return DoseQtyStr;
	var strArr=OrderFreqTimeDoseStr.split('@');
	for(var i=0;i<strArr.length;i++){
		var OneDoseQtyStr="";
		var FreqTimeDoseStrArr=strArr[i].split('!');
		for(var j=0;j<FreqTimeDoseStrArr.length;j++){
			var DoseQty=FreqTimeDoseStrArr[j].split("$")[1];
			if(DoseQty=="") continue;
			if (OneDoseQtyStr=="") OneDoseQtyStr=DoseQty;
			else  OneDoseQtyStr=OneDoseQtyStr+"-"+DoseQty;
		}
		if(DoseQtyStr=='') DoseQtyStr=OneDoseQtyStr;
		else  DoseQtyStr=DoseQtyStr+'|'+OneDoseQtyStr;
	}
	return DoseQtyStr;
}
function DocCure_Click(){
    DHCDocCure_Service.DocCureTreeShow();
}

function GetLinkMasterNoForArcos(row, Arcosrowid) {
	var OrderSeqNo =GetCellData(row, "id");
	var OrderMasterSeqNo = GetCellData(row, "OrderMasterSeqNo");
	var ArcosMaxLinkSeqNo=tkMakeServerCall("web.DHCARCOrdSets", "GetArcosMaxLinkSeqNo", Arcosrowid) //获取不重复的LinkNo
	if (ArcosMaxLinkSeqNo<0) {
		ArcosMaxLinkSeqNo=1
	}else {
		ArcosMaxLinkSeqNo++
	}
	if(OrderMasterSeqNo=="") {
		//如果存在子医嘱则赋值,不存在则不赋值
		var SubRowidsAry = GetMasterSeqNo(row);
		if (SubRowidsAry.length > 0) {
			if (OrderMasterSeqNoArr[OrderSeqNo]) {
				OrderMasterSeqNo = OrderMasterSeqNoArr[OrderSeqNo];
			} else {
				OrderMasterSeqNo =ArcosMaxLinkSeqNo;
				OrderMasterSeqNoArr[OrderSeqNo]=ArcosMaxLinkSeqNo
			}
		}
	}else {
		if (OrderMasterSeqNoArr[OrderMasterSeqNo]) {
			var OrderMasterSeqNo=GetSubSeqNoForArcos(OrderMasterSeqNoArr[OrderMasterSeqNo])
		}else {
			OrderMasterSeqNoArr[OrderMasterSeqNo]=ArcosMaxLinkSeqNo
			var OrderMasterSeqNo=GetSubSeqNoForArcos(OrderMasterSeqNoArr[OrderMasterSeqNo])
		}
	}
	return OrderMasterSeqNo
}
function GetSubSeqNoForArcos(OrderMasterSeqNo){
	var StSubSeqNo=1
	var SubSeqNo=OrderMasterSeqNo+"."+StSubSeqNo
	if(OrderSubSeqNoArr[SubSeqNo]) {
		while (OrderSubSeqNoArr[SubSeqNo]) {
			StSubSeqNo=StSubSeqNo+1
			SubSeqNo=OrderMasterSeqNo+"."+StSubSeqNo
		}
	}
	OrderSubSeqNoArr[SubSeqNo]=SubSeqNo
	return SubSeqNo
}
function OrdDoseQtyBindClick(rowid){
	//先解除绑定方式click防止重复绑
	$("#"+rowid+"_OrderDoseQty").unbind('click');
	$("#"+rowid+"_OrderDoseQty").click(function(){
		new Promise(function(resolve,rejected){
			ChangeOrderFreqTimeDoseStr(rowid,resolve);
		}).then(function(){
			var OrderHiddenPara=GetCellData(rowid, "OrderHiddenPara");
			var SameFreqDifferentDosesFlag=OrderHiddenPara.split(String.fromCharCode(1))[19];
   			 if (SameFreqDifferentDosesFlag=="Y"){
				SetPackQty(rowid,{
					IsNotChangeFirstDayTimeFlag:"Y"
				});
			}
		})
	});
}
 // 套餐录入按钮点击事件
function PkgOrdEntry_Click() {
	var arcimId = "";
	if (!CheckPatPkg(arcimId)) {
		$.messager.alert('提示', '患者没有购买套餐', 'info');
		return false;
	}
	return PkgOrdEntry(arcimId);
}
/**
 * 套餐医嘱录入
 * @method PkgOrdEntry
 * @param {String} 通过"套餐录入"按钮录时，不需要传参数; 检索医嘱时，需要传医嘱项ID
 * PkgOrdEntry("111||2")
 */
function PkgOrdEntry(arcimId) {
	var hospitalId = session['LOGON.HOSPID'];
	var episodeId = GlobalObj.EpisodeID;
	var patientId = GlobalObj.PatientID;
	var lnk = 'dhcbill.pkg.patpkg.csp?PatientID=' + patientId + '&ARCIMID=' + arcimId;
	websys_showModal({
		url:URL,
		title:'套餐选择',
		width:900,height:550,
		CallBackFunc:function(rtnValue){
			AddCopyItemToList(rtnValue.split(','));
		}
	})
}

/**
 * 判断是否有购买套餐
 * @method CheckPatPkg
 * @param {String} 医嘱项ID
 * CheckPatPkg("111||2")
 */
function CheckPatPkg(arcimId) {
	var hospitalId = session['LOGON.HOSPID'];
	var episodeId = GlobalObj.EpisodeID;
	if (!episodeId) {
    	return false;
    }
	var pkgList = $.m({
		ClassName: 'BILL.PKG.BL.PkgPackage',
		MethodName: 'IsDeductPkg',
		episodeId: episodeId,
		arcimId: arcimId,
		useDate: "",
		hospitalId: hospitalId
	}, false);
	var myAry = pkgList.split('^');
	if (myAry[0] == '0') {
		return false;
	}
	return true;
}
function GetPromptHtml(){
	if (GlobalObj.PPRowId=="") {
		ReSetPilotDefaultData();
	}else{
		//判断药理患者是否在组
		var PPPatStatus=tkMakeServerCall("web.PilotProject.DHCDocPilotProject","isNormalStatus",GlobalObj.PatientID,GlobalObj.PPRowId)
		if (PPPatStatus!="N"){
			GlobalObj.PPRowId="";
			ReSetPilotDefaultData();
		}else{
			GlobalObj.PilotProWarning=tkMakeServerCall("web.PilotProject.DHCDocPilotProject","ifWarning",GlobalObj.PPRowId,session['LOGON.USERID']);
		}
	}
	var warning="";
	if (GlobalObj.warning != ""){
		warning=GlobalObj.warning;
	}
	if ((GlobalObj.AnaesthesiaID!="")&&(GlobalObj.AnaesthesiaID.split("||")[0]!=GlobalObj.EpisodeID)){
		var AnaesthesiaErrMsg="手术列表对应患者就诊ID和本页面就诊ID不同,请通过手术列表重新选择!"
		if (warning!=""){
			warning=warning+";"+AnaesthesiaErrMsg;
		}else{
			warning=AnaesthesiaErrMsg;
		}
	}
	if (GlobalObj.IPNecessaryCatMsg!=""){
		if (warning!=""){
			warning=warning+";"+GlobalObj.IPNecessaryCatMsg;
		}else{
			warning=GlobalObj.IPNecessaryCatMsg;
		}
	}
	if (GlobalObj.PilotProWarning!=""){
		if (warning!=""){
			warning=warning+";"+GlobalObj.PilotProWarning;
		}else{
			warning=GlobalObj.PilotProWarning;
		}
	}
	if (GlobalObj.LogonDoctorID==""){
		if (warning!=""){
			warning=warning+";";
		}
		warning=warning+"该用户未对照有效的医护人员,不允许操作";
		GlobalObj.EnableButton=0;
	}
	return warning;
}
function OrderDocchangehandler(e){
    var rowid = GetEventRow(e);
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    SetCellData(rowid, "OrderDocRowid", obj.value);
    SetCellData(rowid, "OrderDoc", obj.value);
    ChangeLinkOrderDoc(rowid);
}
function ChangeLinkOrderDoc(OrderSeqNo) {
	var OrderDocRowid=GetCellData(OrderSeqNo, "OrderDocRowid");
	var OrderDoc=GetCellData(OrderSeqNo, "OrderDoc");
    try {
        var rows = $('#Order_DataGrid').getDataIDs();
        for (var i = 0; i < rows.length; i++) {
            var rowid = rows[i];
            var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
            var OrderItemRowid = GetCellData(rowid, "OrderItemRowid");
            var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
            var OrderType = GetCellData(rowid, "OrderType");
            if ((OrderMasterSeqNo != OrderSeqNo) || (OrderARCIMRowid == "") || (OrderItemRowid != "")) { continue; }
            var EditStatus = GetEditStatus(rowid);
            if (EditStatus) {
	            SetCellData(rowid, "OrderDoc", OrderDocRowid);
	        }else{
		        SetCellData(rowid, "OrderDoc", OrderDoc);
		    }
            SetCellData(rowid, "OrderDocRowid", OrderDocRowid);
        }
    } catch (e) { $.messager.alert("警告", e.message) }
}

///虚拟长期勾选点击事件
function OrderVirtualtLongClickhandler(e){
	var rowid = GetEventRow(e);
	var OrderVirtualtLong=GetCellData(rowid, "OrderVirtualtLong");
	//if (OrderVirtualtLong==false){SetOrderItemPrior(Row,OMLSZTOrderPriorRowid);}else{SetOrderItemPrior(Row,ShortOrderPriorRowid);}
	ChangeLinkOrderVirtualtLong(rowid,OrderVirtualtLong);
}
///虚拟长期医嘱修改关联事件
function ChangeLinkOrderVirtualtLong(Row){
	try {
		if (GlobalObj.UserEMVirtualtLong!="1"){
			return true;
		}
		var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
		if (IsLongPrior(OrderPriorRowid)){
			return true;
		}
		var OrderPriorRowid = GetCellData(Row, "OrderPriorRowid");
		var OrderPriorRemarks = GetCellData(Row, "OrderPriorRemarksRowId");
		var OldPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
		var OrderType = GetCellData(Row, "OrderType");
		var OrderVirtualtLong=GetCellData(Row, "OrderVirtualtLong");
		if (OrderVirtualtLong == "Y") {
		    SetCellData(Row, "OrderDur", GlobalObj.IPDefaultDur);
			SetCellData(Row, "OrderDurRowid", GlobalObj.IPDefaultDurRowId);
			SetCellData(Row, "OrderDurFactor", GlobalObj.IPDefaultDurFactor);
			var OrderFreqRowid=GetCellData(Row, "OrderFreqRowid");
			if (((OrderFreqRowid == GlobalObj.STFreqRowid) || (OrderFreqRowid == GlobalObj.ONCEFreqRowid))) {
				ClearOrderFreq(Row);
			}
	    }
		if (OrderVirtualtLong == "Y") {
	        OrderVirtualtLong = true;
	    } else {
	        OrderVirtualtLong = false;
	    }
		SetVirtualtLongRemark(Row);
		var OrderPackQtyStyleObj = ContrlOrderPackQty(Row);
    	var RowStyleObj=$.extend({}, OrderPackQtyStyleObj);
		if (OrderVirtualtLong){
			$.extend(RowStyleObj, { OrderDur: false});
		}else{
			$.extend(RowStyleObj, { OrderDur: true});
		}
	    ChangeRowStyle(Row, RowStyleObj);
	    ChangeCellDisable(Row, RowStyleObj);
		SetOrderUsableDays(Row);
		//门诊输液次数
    	SetOrderLocalInfusionQty(Row);
        var RowArry = GetSeqNolist(Row)
        for (var i = 0; i < RowArry.length; i++) {
	        var EditStatus = GetEditStatus(RowArry[i]);
			if (EditStatus){
				var OrderVirtualtLongValue=OrderVirtualtLong;
			}else{
				var OrderVirtualtLongValue=OrderVirtualtLong?"Y":"N";
			}
	        var SubRowStyleObj={};
            SetCellData(RowArry[i], "OrderVirtualtLong", OrderVirtualtLongValue);
            if (OrderVirtualtLong) {
				SetCellData(RowArry[i], "OrderDur", GlobalObj.IPDefaultDur);
				SetCellData(RowArry[i], "OrderDurRowid", GlobalObj.IPDefaultDurRowId);
				SetCellData(RowArry[i], "OrderDurFactor", GlobalObj.IPDefaultDurFactor);
				var OrderFreqRowid=GetCellData(RowArry[i], "OrderFreqRowid");
				if (((OrderFreqRowid == GlobalObj.STFreqRowid) || (OrderFreqRowid == GlobalObj.ONCEFreqRowid))) {
					ClearOrderFreq(RowArry[i]);
				}
			}
			var SubPriorRowid = GetCellData(RowArry[i], "OrderPriorRowid");
			var SubPriorRemarks = GetCellData(RowArry[i], "OrderPriorRemarksRowId");
			var OldPriorRowid = ReSetOrderPriorRowid(SubPriorRowid, SubPriorRemarks);
			SetVirtualtLongRemark(RowArry[i]);
			var OrderMasterSeqNo=GetCellData(RowArry[i], "OrderMasterSeqNo");
			var RowStyleObj = {};
			if (OrderVirtualtLong){
				$.extend(RowStyleObj, { OrderDur: false});
			}else{
				if(OrderMasterSeqNo == "") {
					$.extend(RowStyleObj, { OrderDur: true});
				}else{
					$.extend(RowStyleObj, { OrderDur: false});
				}
			}
			var OrderPackQtyStyleObj = ContrlOrderPackQty(RowArry[i]);
			$.extend(RowStyleObj, OrderPackQtyStyleObj);
    		ChangeCellDisable(RowArry[i], RowStyleObj);
			SetOrderUsableDays(RowArry[i]);
			//门诊输液次数
    		SetOrderLocalInfusionQty(RowArry[i]);
        }
    } catch (e) { alert( e.message) }
}

function InitChronicDiagLookUp(){
	if ($("#ChronicDiag").length==0){return}
	$("#ChronicDiag").lookup({
        url:$URL,
        mode:'remote',
        method:"Get",
        idField:'Code',
        textField:'Desc',
        columns:[[  
       		{field:'Desc',title:'描述',width:130,sortable:false}
        	,{field:'Code',title:'编码',hidden:false}
        	,{field:'Type',title:'类型',width:80,sortable:false}
        ]],
        width:95,
        pagination:true,
        panelWidth:300,
        panelHeight:300,
        isCombo:true,
        minQueryLen:0,
        delay:'200',
        queryOnSameQueryString:true,
        queryParams:{ClassName: 'web.DHCDocQryOEOrder',QueryName: 'LookUpChronicDiag'},
        onBeforeLoad:function(param){
	        var desc=param['q'];
			param = $.extend(param,{desc:desc,EpisodeID:GlobalObj.EpisodeID});
	    },onSelect:function(ind,item){
		},onHidePanel:function(){
			PageLogicObj.LookupPanelIsShow=0;
		},onShowPanel:function(){
			PageLogicObj.LookupPanelIsShow=1;
		},onBeforeShowPanel:function(){
			$(this).lookup('panel').panel('resize',{width:300});
		}
	});
	$("#ChronicDiag").keyup(function(){
		if ($(this).val()==""){
			$(this).lookup("setValue","").lookup("setText","");
		}
	});
}
function GetChronicDiagCode(){
	var ChronicDiagCode="";
	if ($("#ChronicDiag").length>0){
		if ($("#ChronicDiag").lookup("getText")!=""){
			ChronicDiagCode=$("#ChronicDiag").lookup("getValue")
		}
	}
	if (typeof ChronicDiagCode=="undefined"){
		ChronicDiagCode="";
	}
	return ChronicDiagCode;
}
function ShowGuideAllergy(ArcimRowid,OrderName,callBackFun){
	var lnk = "oeorder.guideallergy.csp?EpisodeID="+GlobalObj.EpisodeID+"&ArcimRowId="+ArcimRowid+"&GuideAllergyType=Guide";
	websys_showModal({
		iconCls:'icon-w-predrug',
		url:lnk,
		title:OrderName+$g(' 皮试医嘱引导'),
		width:800,height:560,
		closable:true,
		callBackRetVal:'',
		onBeforeClose:function(){
			callBackFun(websys_showModal("options").callBackRetVal);
		},
		CallBackFunc:function(result){
			if (typeof result=="undefined") result="Exit";
			websys_showModal("options").callBackRetVal=result;
			websys_showModal("close");
		}
	})
}
function ShowAppendAllergyOrder(ArcimRowid,OrderName,OrderStartDate,callBackFun){
	var lnk = "oeorder.guideallergy.csp?EpisodeID="+GlobalObj.EpisodeID+"&ArcimRowId="+ArcimRowid+"&OrderStartDate="+OrderStartDate+"&GuideAllergyType=Append";
	websys_showModal({
		iconCls:'icon-w-switch',
		url:lnk,
		title:OrderName+' 皮试医嘱选择',
		width:700,height:300,
		closable:false,
		closable:true,
		callBackRetVal:'',
		onBeforeClose:function(){
			callBackFun(websys_showModal("options").callBackRetVal);
		},
		CallBackFunc:function(result){
			if (typeof result=="undefined") result="";
			websys_showModal("options").callBackRetVal=result;
			websys_showModal("close");
		}
	})
}
function ResizePromptWidth(){
	var northDIVMax = $("#layout_main_center_north").innerWidth();
	var northRightDivMax=$("#north-right-div").innerWidth();
	if (northRightDivMax==0) northRightDivMax=305;
	if (GlobalObj.INAdmTypeLoc!="Y"){
		$("#Prompt").css("width",parseInt(northDIVMax)-parseInt(northRightDivMax)-60); //580
	}else{
		if (GlobalObj.Priorlayout=="Dropdown"){
			$("#Prompt").css("width",parseInt(northDIVMax)-northRightDivMax-173); //474
		}else{
			//医嘱类型横向展示
			$("#Prompt").css("width",parseInt(northDIVMax)-northRightDivMax-300); //610
		}
	}
	$('#OrdNotesDetail_Btn').css('right',$(window).width()-($("#Prompt").offset().left+$("#Prompt").width())-5);
}
function RefreshOrderList(){
	SaveSessionData();
    $("#Order_DataGrid").jqGrid("clearGridData");
    var postData = { USERID: session['LOGON.USERID'], ADMID: GlobalObj.EpisodeID,NotDisplayNoPayOrd:GlobalObj.NotDisplayNoPayOrd };
    $("#Order_DataGrid").setGridParam({postData:postData}).trigger("reloadGrid");
    ReLoadLabInfo()
	var EpisPatInfo = tkMakeServerCall("web.DHCDocViewDataInit", "InitPatOrderViewGlobal", GlobalObj.EpisodeID,"",GlobalObj.EmConsultItm);
}
function SetOrdNurseBindOrd(){
	var winlocation=websys_getTop().window.location;		            
    var VerfiOeordID=GetUrlParam(winlocation,"OeordID");
    if (VerfiOeordID){
        $.m({
		    ClassName:"web.DHCDocOrderCommon",
		    MethodName:"GetVerifiedOrder",
		    itemid:VerfiOeordID
		},function(LinkOrderStr){
			var VerifiedOrderArr = LinkOrderStr.split("^");
			var LinkedMasterOrderPriorRowid=VerifiedOrderArr[4];
			var HiddenOrderPrior = $("#HiddenOrderPrior").val();
			if (((HiddenOrderPrior=="ShortOrderPrior")&&IsLongPrior(LinkedMasterOrderPriorRowid))
                ||((HiddenOrderPrior=="LongOrderPrior")&&!IsLongPrior(LinkedMasterOrderPriorRowid))) {
                $("#kwOrderPrior").keywords('switchById',HiddenOrderPrior);
			}
			SetVerifiedOrder(VerfiOeordID);
		});
    }
}
function GetOrderInsurCat(rowid,OrderInsurCatRowId){
	var InsurCatStr=GetCellData(rowid, "OrderInsurCatHideen");
	var ArrData = InsurCatStr.split(String.fromCharCode(2));
	for (var i = 0; i < ArrData.length; i++) {
        var ArrData1 = ArrData[i].split(String.fromCharCode(1));
        if (ArrData1[0]==OrderInsurCatRowId) return ArrData1[1];
    }
    return "";
}

function OrderChronicDiagchangehandler(e){
	try{
		var rowid=GetEventRow(e);
		var obj=websys_getSrcElement(e);
        var OrderChronicDiagCode=obj.value;
        SetCellData(rowid, "OrderChronicDiagCode", OrderChronicDiagCode);
	}catch(e){
        alert(e.message);
	}
}
function PriceDetail(rowid){
	var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
	if (OrderARCIMRowid!=""){
		websys_showModal({
			iconCls:'icon-w-inv',
			url:"dhcdoc.arcimlinktar.hui.csp?ARCIMRowId=" + OrderARCIMRowid,
			title:'收费明细',
			width:1005,height:520
		});
	}
}
function OrderLabSpecCollectionSitechangehandler(e){
    var rowid = "";
    var obj = websys_getSrcElement(e);
    if (obj.id.indexOf("_") > 0) {
        rowid = obj.id.split("_")[0];
    }
    SetCellData(rowid, "OrderLabSpecCollectionSiteRowid", obj.value);
}
function OrderLabSpecCollectionSiteChange(rowid){
	var OldOrderLabSpecCollectionSiteRowid=GetCellData(rowid, "OrderLabSpecCollectionSiteRowid");
	var OrderLabSpecRowid=GetCellData(rowid, "OrderLabSpecRowid");
	var OrderARCIMRowid=GetCellData(rowid, "OrderARCIMRowid");
	$.m({
	    ClassName:"web.DHCDocOrderCommon",
	    MethodName:"GetExCode",
	    ArcimRowid:OrderARCIMRowid
	},function(excode){
		if (excode) {
			var OrderLabSpecCollectionSiteStr=$.m({
			    ClassName:"DHCLIS.DHCCommon",
			    MethodName:"GetTestSetSpecimenSite",
			    TSCode:excode, 
			    SpecimenCode:OrderLabSpecRowid, 
			    HospitalCode:tkMakeServerCall("web.DHCDocOrderCommon", "GetCurrentSYSHospitalCode", session['LOGON.HOSPID'])
			},false);
			SetColumnList(rowid, "OrderLabSpecCollectionSite", OrderLabSpecCollectionSiteStr);
			if ((OrderLabSpecCollectionSiteStr!="")&&(OldOrderLabSpecCollectionSiteRowid!="")){
	            var ArrData = OrderLabSpecCollectionSiteStr.split(String.fromCharCode(3));
	            for (var i = 0; i < ArrData.length; i++) {
	                var ArrData1 = ArrData[i].split(String.fromCharCode(2));
	                if (ArrData1[0] == OldOrderLabSpecCollectionSiteRowid){
		                SetCellData(rowid, "OrderLabSpecCollectionSite", OldOrderLabSpecCollectionSiteRowid);
           				SetCellData(rowid, "OrderLabSpecCollectionSiteRowid", OldOrderLabSpecCollectionSiteRowid);
	                    break;
	                }
	            }
			}
		}
	});
}
/**
* @description: 让护士选择补录频次关联的主医嘱执行记录分发时间
* @param {String} 
* @return: {String} 
*/
function GetOrderNurseExecLinkDispTimeStr(OrderName,OrderFreqRowid,OrderFreqDispTimeStr,OrderNurseLinkOrderRowid,callBackFun){
	websys_showModal({
		url:encodeURI("dhcdoc.ordernursexeclinkdisptime.csp?OrderNurseLinkOrderRowid=" + OrderNurseLinkOrderRowid+"&OrderFreqRowid="+OrderFreqRowid+"&OrderFreqDispTimeStr="+OrderFreqDispTimeStr),
		title:OrderName+' '+$g('关联主医嘱分发时间选择'),
		width:370,height:410,
		closable:false,
		CallBackFunc:function(result){
			websys_showModal("close");
			if (typeof result=="undefined"){
				result="";
			}
			callBackFun(result);
		}
	})
}
function GetVerifiedOrderObjObj(VerifiedOrderArr){
	var OrderObj = {
        LinkedMasterOrderName: "",
        LinkedMasterOrderRowid: "",
        LinkedMasterOrderSeqNo: "",
        LinkedMasterOrderPriorRowid: "",
        LinkedMasterOrderFreRowId: "",
        LinkedMasterOrderFreFactor: "",
        LinkedMasterOrderFreInterval: "",
        LinkedMasterOrderFreDesc: "",
        LinkedMasterOrderFreqDispTimeStr:"",
        LinkedMasterOrderFreqIntervalTimeFlag:"",
		LinkedMasterOrderFreqIntervalUnit:"",
        LinkedMasterOrderInstr:"",
        LinkedMasterOrderInstrRowid:""
    }
    OrderObj.LinkedMasterOrderName = VerifiedOrderArr[1];
    OrderObj.LinkedMasterOrderRowid = VerifiedOrderArr[2];
    OrderObj.LinkedMasterOrderSeqNo = VerifiedOrderArr[3];
    OrderObj.LinkedMasterOrderPriorRowid = VerifiedOrderArr[4];
    var OrderFreStr = VerifiedOrderArr[5];
    OrderObj.LinkedMasterOrderFreRowId = mPiece(OrderFreStr, String.fromCharCode(1), 0);
    OrderObj.LinkedMasterOrderFreFactor = mPiece(OrderFreStr, String.fromCharCode(1), 1);
    OrderObj.LinkedMasterOrderFreInterval = mPiece(OrderFreStr, String.fromCharCode(1), 2);
    OrderObj.LinkedMasterOrderFreDesc = mPiece(OrderFreStr, String.fromCharCode(1), 3);
    OrderObj.LinkedMasterOrderFreqDispTimeStr = mPiece(OrderFreStr, String.fromCharCode(1), 4);
    OrderObj.LinkedMasterOrderFreqDispTimeStr=OrderObj.LinkedMasterOrderFreqDispTimeStr.split(String.fromCharCode(13)).join(String.fromCharCode(1));
    OrderObj.LinkedMasterOrderFreqIntervalTimeFlag=mPiece(OrderFreStr, String.fromCharCode(1), 5);	//间隔时间频次
	OrderObj.LinkedMasterOrderFreqIntervalUnit=mPiece(OrderFreStr, String.fromCharCode(1), 6);		//间隔时间单位(H\D)
    OrderObj.LinkedMasterOrderSttDate = VerifiedOrderArr[6]; 
    OrderObj.LinkedMasterOrderInstr=VerifiedOrderArr[8];
    OrderObj.LinkedMasterOrderInstrRowid=VerifiedOrderArr[9];
    return OrderObj;
}
function InitLogonDocStr(){
	$.m({
        ClassName:"web.DHCOEOrdItemView",
        MethodName:"GetOPSurgeonDocStr",
        AnaesthesiaID:GetMenuPara("AnaesthesiaID"),
        OrderOperationCode:GetMenuPara("AnaestOperationID"),
        UserID:session['LOGON.USERID']
    },function(data){
        GlobalObj.LogonDocStr=data
    });
}

function Chemo_ShowApply () {
	var PW = "95%"; //$(window.parent.window).width();
	var PH = $(window.parent.window).height();	//$(window).height()
	var PTH = $(websys_getTop()).height();
	var PatientID = GlobalObj.PatientID,
	EpisodeID = GlobalObj.EpisodeID,
	PAAdmType = GlobalObj.PAAdmType;
	var HasAcitve = Chemo_GetActiveFlag();
	var URL = "chemo.bs.apply.csp?PatientID="+PatientID+"&EpisodeID="+EpisodeID+"&PAAdmType="+PAAdmType+"&HasAcitve="+HasAcitve;
	websys_showModal({
		url:URL,
		//id:"i-chemo",
		iconCls: 'icon-w-add',
		title:'化疗单',
		//maximizable:true,
		//maximized:true,
		width:PW,height:PTH,
		CallBackFunc:Chemo_ShowApply_Callback,
		DelChemoOrder:Chmeo_Del,
		onClose:function () {
			//ReloadGridData("Update");
			OrderMsgChange();
		}
	})
}

function Chmeo_Del(PLID) {
	
	var DataArry = GetChemoGirdData();
    for (var i = 0; i < DataArry.length; i++) {	
        var OrderItemRowid = DataArry[i]["OrderItemRowid"];
        var OrderARCIMRowid = DataArry[i]["OrderARCIMRowid"];
		var OrderARCOSRowid = DataArry[i]["OrderARCOSRowid"];
        var StyleConfigStr = DataArry[i]["StyleConfigStr"];
        var StyleConfigObj = {};
        if (StyleConfigStr != "") {
            StyleConfigObj = eval("(" + StyleConfigStr + ")");
        }
        if ((GlobalObj.PAAdmType != "I") && (StyleConfigObj.OrderPackQty != true) && (OrderItemRowid != "")) { continue }
        if ((OrderARCIMRowid == "")&&(OrderARCOSRowid=="")) { continue; }
        var OrderSeqNo = DataArry[i]["id"];
        var OrderHiddenPara=DataArry[i]["OrderHiddenPara"];
		var PGIID=OrderHiddenPara.split(String.fromCharCode(1))[25];
	
		if (PGIID!="") {
			var CPLID=PGIID.split("||")[0];
			if (PLID == CPLID) {
				DeleteRow(OrderSeqNo)
			}
		}
		
    }
}

function Chemo_ShowApply_Callback(PSID,PlanDate) {
	//console.log(PSID,": ",PlanDate,": ",'AddCopyItemToList',": ",GlobalObj.PAAdmType)
	ClearUnSaveRow();
	var SessionStr=GetSessionStr();
	var Sperate=String.fromCharCode(1);
	var ExtPara="0"+Sperate+GlobalObj.EpisodeID+Sperate+session['LOGON.CTLOCID']+Sperate+SessionStr;
	var ret=cspRunServerMethod(GlobalObj.ChemoItemToListMethod,PSID,PlanDate,'AddCopyItemToList',GlobalObj.PAAdmType,ExtPara);
	if (ret==0) {
		
	} else if(ret==-1) {
		//$.messager.alert("提示","超过终身剂量！","warning");
		//return false;
	} else {
		$.messager.alert("提示","加载失败！","warning");
		return false;
	}
}

function GetChemoGirdData() {
    var DataArry = new Array();
    var rowids = $('#Order_DataGrid').getDataIDs();
    for (var i = 0; i < rowids.length; i++) {
        var OrderItemRowid = GetCellData(rowids[i], "OrderItemRowid");
        var OrderARCIMRowid = GetCellData(rowids[i], "OrderARCIMRowid");
var OrderARCOSRowid = GetCellData(rowids[i], "OrderARCOSRowid");
        if (OrderItemRowid != "" || ((OrderARCIMRowid == "")&&(OrderARCOSRowid == ""))) { continue; }
        //EndEditRow(rowids[i]);
        var curRowData = $("#Order_DataGrid").getRowData(rowids[i]);
        DataArry[DataArry.length] = curRowData;
    }
    return DataArry;
}

function Chemo_SetOrderStyle() {
	var DataArry = GetChemoGirdData();
	    for (var i = 0; i < DataArry.length; i++) {
	        var OrderItemRowid = DataArry[i]["OrderItemRowid"];
	        var OrderARCIMRowid = DataArry[i]["OrderARCIMRowid"];
	var OrderARCOSRowid = DataArry[i]["OrderARCOSRowid"];
	        var StyleConfigStr = DataArry[i]["StyleConfigStr"];
	        var StyleConfigObj = {};
	        if (StyleConfigStr != "") {
	            StyleConfigObj = eval("(" + StyleConfigStr + ")");
	        }
	        if ((GlobalObj.PAAdmType != "I") && (StyleConfigObj.OrderPackQty != true) && (OrderItemRowid != "")) { continue }
	        if ((OrderARCIMRowid == "")&&(OrderARCOSRowid=="")) { continue; }
	        var OrderSeqNo = DataArry[i]["id"];
	        var OrderHiddenPara=DataArry[i]["OrderHiddenPara"];
	var PGIID=OrderHiddenPara.split(String.fromCharCode(1))[25];

	var obj={
	OrderPrior:false,
	OrderFreq:false,
	OrderInstr:false,
	OrderDoseUOM:false,
	OrderDoseQty:false,
	OrderName:false,
	OrderMasterSeqNo:false,
	OrderPackQty:false,
	OrderPackUOM:false,
	OrderDur:false
	};
	if (PGIID!="") {
		ChangeRowStyle(OrderSeqNo,obj)
	}

	}
}

function Chemo_GetActiveFlag() {
	var mRtn=0
	var DataArry = GetChemoGirdData();
	    for (var i = 0; i < DataArry.length; i++) {
	        var OrderItemRowid = DataArry[i]["OrderItemRowid"];
	        var OrderARCIMRowid = DataArry[i]["OrderARCIMRowid"];
	var OrderARCOSRowid = DataArry[i]["OrderARCOSRowid"];
	        var StyleConfigStr = DataArry[i]["StyleConfigStr"];
	        var StyleConfigObj = {};
	        if (StyleConfigStr != "") {
	            StyleConfigObj = eval("(" + StyleConfigStr + ")");
	        }
	        if ((GlobalObj.PAAdmType != "I") && (StyleConfigObj.OrderPackQty != true) && (OrderItemRowid != "")) { continue }
	        if ((OrderARCIMRowid == "")&&(OrderARCOSRowid=="")) { continue; }
	        var OrderSeqNo = DataArry[i]["id"];
	        var OrderHiddenPara=DataArry[i]["OrderHiddenPara"];
	var PGIID=OrderHiddenPara.split(String.fromCharCode(1))[25];


	if (PGIID!="") {
	mRtn=1
	break;
	}
	}

	return mRtn
}

function GCP_Vist_Click () {
	if (GlobalObj.PPRowId == "") {
		$.messager.alert("提示","请从受试者列表中进入！","warning")
		return false;
	}
	var PW = "95%"; //$(window).width()-300;
	var PH = "95%"; //$(window).height()-200;
	var PatientID = GlobalObj.PatientID,
		EpisodeID = GlobalObj.EpisodeID,
		PAAdmType = GlobalObj.PAAdmType,
		PPRowId = GlobalObj.PPRowId;
	
	var URL = "docpilotpro.bs.visit.csp?PatientID="+PatientID+"&EpisodeID="+EpisodeID+"&PAAdmType="+PAAdmType+"&PPRowId="+PPRowId;
	websys_showModal({
		url:URL,
		//id:"i-chemo",
		iconCls: 'icon-w-add',
		title:'GCP免费医嘱',
		maximizable:true,
		//maximized:true,
		width:PW,height:PH,
		CallBackFunc:GCP_Visit_Callback
	})
	
}

function GCP_Visit_Callback(ArcimList) {
	var ret=cspRunServerMethod(GlobalObj.GCPVisitItemToListMethod,GlobalObj.EpisodeID,ArcimList,'AddCopyItemToList',session['LOGON.HOSPID']);
	if (ret==0) {
	} else {
		$.messager.alert("提示","加载失败！","warning");
		return false;
	}
}
function PreviewLabNoBtnClickHandler(){
	new Promise(function(resolve,rejected){
		GetOrderDataOnAdd(resolve);
		
	}).then(function(OrderItemStr){
		return new Promise(function(resolve,rejected){
            if (OrderItemStr === "") {
                $.messager.alert("提示", t['NO_NewOrders'],"info",function(){
                    rejected();
                });
                return websys_cancel();
            }
            if (OrderItemStr===false) {
                return rejected('');
            }
            resolve(OrderItemStr);
            
         })
	}).then(function(OrderItemStr){
		var LabNoInfo="";
		var OrderItemArr=OrderItemStr.split(String.fromCharCode(1));
		for (var i = 0; i < OrderItemArr.length; i++) {
			var OneOrdItemArr=OrderItemArr[i].split("^");
			var ArcimRowID=OneOrdItemArr[0];
			var OrderType=OneOrdItemArr[1];
			if ((ArcimRowID=="")||(OrderType!="L")){
				continue
			}
			var LabEpisodeNo=OneOrdItemArr[37];
			if (LabEpisodeNo==""){
				continue
			}
			var SpecimenCode=OneOrdItemArr[27];
			if (LabNoInfo==""){
				LabNoInfo=ArcimRowID+"^"+LabEpisodeNo+"^"+SpecimenCode;
			}else{
				LabNoInfo=LabNoInfo+"@"+ArcimRowID+"^"+LabEpisodeNo+"^"+SpecimenCode;
			}
		}
		if (LabNoInfo==""){
			$.messager.alert("提示", "未找到有效的检验医嘱","info",function(){});
			return websys_cancel();
		}
		websys_showModal({
			iconCls:'icon-w-filter',
			url:"dhcdoc.labord.preview.csp?EpisodeID="+GlobalObj.EpisodeID+"&LabNoInfo="+LabNoInfo,
			title:$g('检验条码预览'),
			width:800,height:600,
			closable:true,
			CallBackFunc:function(result){
				websys_showModal("close");
				if (typeof result=="undefined"){
					result="";
				}
				CallBackFunc(result);
			}
		})
	})
}
function GetBindOrdItemTip(rowid)
{
	clearTimeout(PageLogicObj.BindTipTimerArr[rowid]);
	PageLogicObj.BindTipTimerArr[rowid]=setTimeout(function(){
		var RowArry = GetSeqNolist(rowid);
		var MainRowid="";
		RowArry.push(rowid);
		RowArry.sort(function(a, b){ return a - b; });
		$.unique(RowArry);
		var OrderItemStr="";
        for (var i = 0; i < RowArry.length; i++) {
			rowid=RowArry[i];
			var $html=$(GetCellData(rowid, "OrderAppendInfo"));
			if ($html.length==1){
				$("#"+$html.attr('id')).tooltip('destroy');
				SetCellData(rowid, "OrderAppendInfo","");
			}
			//关联
			var OrderMasterSeqNo =GetCellData(rowid,"OrderMasterSeqNo");
			//if(OrderMasterSeqNo!="") return;	//子医嘱不判断?
			if (OrderMasterSeqNo==""){
				MainRowid=rowid;
			}
			var EmConsultItm=GlobalObj.EmConsultItm;	///会诊子表ID
			var OrderItemRowid =GetCellData(rowid,"OrderItemRowid");
			var OrderARCIMRowid =GetCellData(rowid,"OrderARCIMRowid");
			var OrderARCOSRowid =GetCellData(rowid,"OrderARCOSRowid");
			if ((OrderARCIMRowid == "")&&(OrderARCOSRowid=="")) { 
				continue;
			}
			//原序号  现行ID
			var OrderSeqNo =GetCellData(rowid,"id");
			var OrderName =GetCellData(rowid,"OrderName");
			var OrderType =GetCellData(rowid,"OrderType");
			var OrderPriorRowid =GetCellData(rowid,"OrderPriorRowid");
			var OrderRecDepRowid =GetCellData(rowid,"OrderRecDepRowid");
			var OrderFreqRowid =GetCellData(rowid,"OrderFreqRowid");
			var OrderDurRowid =GetCellData(rowid,"OrderDurRowid");
			var OrderInstrRowid =GetCellData(rowid,"OrderInstrRowid");
			var OrderDoseQty =GetCellData(rowid,"OrderDoseQty");
			var OrderDoseQty = FormateNumber(OrderDoseQty);
			var OrderDoseUOMRowid =GetCellData(rowid,"OrderDoseUOMRowid");
			var OrderPackQty =GetCellData(rowid,"OrderPackQty");
			var OrderPrice =GetCellData(rowid,"OrderPrice");
			var PHPrescType =GetCellData(rowid,"OrderPHPrescType");
			var BillTypeRowid =GetCellData(rowid,"OrderBillTypeRowid");
			var OrderSkinTest =GetCellData(rowid,"OrderSkinTest");
			var OrderARCOSRowid =GetCellData(rowid,"OrderARCOSRowid");
			var OrderDrugFormRowid =GetCellData(rowid,"OrderDrugFormRowid");
			var OrderStartDateStr =GetCellData(rowid,"OrderStartDate");
			var OrderStartDate = "";
			var OrderStartTime = "";
			if (OrderStartDateStr != "") {
				OrderStartDate = OrderStartDateStr.split(" ")[0];
				OrderStartTime = OrderStartDateStr.split(" ")[1];
			}
			var OrderDepProcNotes =GetCellData(rowid,"OrderDepProcNote");
			var OrderPhSpecInstr = ""; //GetCellData(rowid,"OrderPhSpecInstr");
			var OrderCoverMainIns =GetCellData(rowid,"OrderCoverMainIns");
			var OrderActionRowid =GetCellData(rowid,"OrderActionRowid");
			var OrderEndDateStr =GetCellData(rowid,"OrderEndDate");
			var OrderEndDate = "";
			var OrderEndTime = "";
			if (OrderEndDateStr != "") {
				OrderEndDate = OrderEndDateStr.split(" ")[0];
				OrderEndTime = OrderEndDateStr.split(" ")[1];
			}
			var OrderLabSpecRowid =GetCellData(rowid,"OrderLabSpecRowid");
			var OrderMultiDate = ""; //GetCellData(rowid,"OrderMultiDate");
			var OrderNotifyClinician = ""; //GetCellData(rowid,"Urgent");
			//if (OrderNotifyClinician==true){OrderNotifyClinician="Y"}else{OrderNotifyClinician="N"}
			var OrderDIACatRowId =GetCellData(rowid,"OrderDIACatRowId");
			//医保类别
			var OrderInsurCatRowId =GetCellData(rowid,"OrderInsurCatRowId");
			//医嘱首日次数
			var OrderFirstDayTimes =GetCellData(rowid,"OrderFirstDayTimes");
			//如果是生成取药医嘱,自备药长嘱只生成执行记录,如果是自备药即刻
			if (((OrderPriorRowid == GlobalObj.LongOrderPriorRowid) || (OrderPriorRowid == GlobalObj.OMSOrderPriorRowid)) && (GlobalObj.PAAdmType == "I")) OrderFirstDayTimes =GetCellData(rowid,"OrderFirstDayTimes");
			//医保适应症
			var OrderInsurSignSymptomCode = ""; //GetCellData(rowid,"OrderInsurSignSymptomCode");
			//身体部位
			var OrderBodyPart =GetCellData(rowid,"OrderBodyPart");
			if (OrderBodyPart != "") {
				if (OrderDepProcNotes != "") {
					OrderDepProcNotes = OrderDepProcNotes + "," + OrderBodyPart;
				} else {
					OrderDepProcNotes = OrderBodyPart;
				}
			}
			//医嘱阶段
			var OrderStageCode =GetCellData(rowid,"OrderStageCode");
			//输液滴速
			var OrderSpeedFlowRate =GetCellData(rowid,"OrderSpeedFlowRate");
			OrderSpeedFlowRate = FormateNumber(OrderSpeedFlowRate);
			//GetMenuPara("AnaesthesiaID");
			var AnaesthesiaID =GetCellData(rowid,"AnaesthesiaID");
			var OrderLabEpisodeNo =GetCellData(rowid,"OrderLabEpisodeNo");

			var VerifiedOrderMasterRowid = "";
			//营养药标志
			var OrderNutritionDrugFlag = ""; //GetCellData(rowid,"OrderNutritionDrugFlag");
			//补录关联主医嘱信息 
			var LinkedMasterOrderRowid =GetCellData(rowid,"LinkedMasterOrderRowid");
			var LinkedMasterOrderSeqNo =GetCellData(rowid,"LinkedMasterOrderSeqNo");
			if ((LinkedMasterOrderSeqNo != "") && (OrderMasterSeqNo == "")) {
				OrderMasterSeqNo =GetCellData(rowid,"LinkedMasterOrderSeqNo");
			}
			//if ((VerifiedOrderMasterRowid!="")&&(LinkedMasterOrderRowid=="")) LinkedMasterOrderRowid=VerifiedOrderMasterRowid;
			//审批类型
			var OrderInsurApproveType = ""; //GetCellData(rowid,"OrderInsurApproveType");
			//临床路径步骤
			var OrderCPWStepItemRowId =GetCellData(rowid,"OrderCPWStepItemRowId");
			//高值材料条码
			var OrderMaterialBarCode =GetCellData(rowid,"OrderMaterialBarcodeHiden");
			//输液滴速单位
			var OrderFlowRateUnit =GetCellData(rowid,"OrderFlowRateUnit");
			var OrderFlowRateUnitRowId =GetCellData(rowid,"OrderFlowRateUnitRowId");
			//开医嘱日期
			var OrderDate = "";
			var OrderTime = "";
			var OrderDateStr =GetCellData(rowid,"OrderDate");
			if (OrderDateStr != "") {
				OrderDate = OrderDateStr.split(" ")[0];
				OrderTime = OrderDateStr.split(" ")[1];
			}
			//需要配液
			var OrderNeedPIVAFlag =GetCellData(rowid,"OrderNeedPIVAFlag");
			//****************抗生素10********************************/
			// 管制药品申请
			var OrderAntibApplyRowid =GetCellData(rowid,"OrderAntibApplyRowid");
			//抗生素使用原因
			var AntUseReason =GetCellData(rowid,"AntUseReason");
			//使用目的
			var UserReasonId =GetCellData(rowid,"UserReasonId");
			var ShowTabStr =GetCellData(rowid,"ShowTabStr");
			//************************************************/
			//输液次数
			var OrderLocalInfusionQty =GetCellData(rowid,"OrderLocalInfusionQty");
			//个人自备
			var OrderBySelfOMFlag = "";
			if (GetCellData(rowid,"OrderSelfOMFlag")) OrderBySelfOMFlag =GetCellData(rowid,"OrderSelfOMFlag");
			var OrderOutsourcingFlag = "";
			if (GetCellData(rowid,"OrderOutsourcingFlag")) OrderOutsourcingFlag =GetCellData(rowid,"OrderOutsourcingFlag");
			//超量疗程原因
			var ExceedReasonID =GetCellData(rowid,"ExceedReasonID");
			//是否加急
			var OrderNotifyClinician =GetCellData(rowid,"Urgent");
			//整包装单位
			var OrderPackUOMRowid =GetCellData(rowid,"OrderPackUOMRowid");
			var OrderOperationCode=GetCellData(rowid,"OrderOperationCode");
			var OrderFreqDispTimeStr =GetCellData(rowid,"OrderFreqDispTimeStr"); 
			var OrderFreqInfo=GetCellData(rowid,"OrderFreqFactor")+"^"+GetCellData(rowid,"OrderFreqInterval")+"^"+OrderFreqDispTimeStr;
			var OrderDurFactor=GetCellData(rowid,"OrderDurFactor");
			var OrderHiddenPara=GetCellData(rowid,"OrderHiddenPara");
			var OrderQtyInfo=GetOrderQtyInfo(OrderType,OrderDoseQty,OrderFreqInfo,OrderDurFactor,OrderStartDateStr,OrderFirstDayTimes,OrderPackQty,OrderHiddenPara);
			var OrderQtySum=mPiece(OrderQtyInfo, "^", 0)
			var OrderPackQty=mPiece(OrderQtyInfo, "^",1)
			
			var OrderPriorRemarks =GetCellData(rowid,"OrderPriorRemarksRowId");
			OrderPriorRowid = ReSetOrderPriorRowid(OrderPriorRowid, OrderPriorRemarks);
			//药理项目
			var OrderPilotProRowid = GetCellData(rowid,"OrderPilotProRowid");
			if (OrderPilotProRowid!="") {
				if (GlobalObj.PAAdmType == "I") {
					if (GlobalObj.CFIPPilotPatAdmReason != "") BillTypeRowid = GlobalObj.CFIPPilotPatAdmReason;
				} else {
					if (GlobalObj.CFPilotPatAdmReason != "") BillTypeRowid = GlobalObj.CFPilotPatAdmReason;
				}
			}
			if (OrderDoseQty == "") { OrderDoseUOMRowid = "" }
			//检查申请子表记录Id
			var ApplyArcId="";
			//治疗申请预约ID
			var DCAARowId= mPiece(OrderHiddenPara, String.fromCharCode(1), 20); //GlobalObj.DCAARowId
			//临床知识库检测表id
			var OrderMonitorId=GetCellData(rowid,"OrderMonitorId");
			var OrderNurseLinkOrderRowid=GetCellData(rowid,"OrderNurseLinkOrderRowid");;
			var OrderBodyPartLabel=GetCellData(rowid,"OrderBodyPartLabel");
			if (typeof OrderBodyPartLabel=="undefined"){OrderBodyPartLabel="";}
			var CelerType="N";	//快速医嘱套标识
			var OrdRowIndex=GetCellData(rowid,"id");
			var OrderFreqExpInfo=CalOrderFreqExpInfo(OrderFreqDispTimeStr);
			var OrderFreqWeekStr=mPiece(OrderFreqExpInfo, "^", 0);
			var OrderFreqFreeTimeStr=mPiece(OrderFreqExpInfo, "^", 1);
			
			var OrderHiddenPara=GetCellData(rowid,"OrderHiddenPara");
			var FindRecLocByLogonLocFlag=OrderHiddenPara.split(String.fromCharCode(1))[18];
			var OrderOpenForAllHosp=OrderHiddenPara.split(String.fromCharCode(1))[28];
			var OrderFreqTimeDoseStr=GetCellData(rowid,"OrderFreqTimeDoseStr");
			if (OrderFreqTimeDoseStr!="") OrderDoseQty="";
			var OrderNurseBatchAdd=""; //护士批量补录标志,批量补录医嘱界面传入
			var OrderSum = GetCellData(rowid,"OrderSum");
			var AntCVID=GlobalObj.AntCVID; //危急值ID
			var OrderPkgOrderNo = GetCellData(rowid,"OrderPkgOrderNo");
			var OrderDocRowid=GetCellData(rowid,"OrderDocRowid");
			///
			var OrderPracticePreRowid=OrderHiddenPara.split(String.fromCharCode(1))[23];
			var PGIID=OrderHiddenPara.split(String.fromCharCode(1))[27]; 
			///虚拟长期标志
			var OrderVirtualtLong=GetCellData(rowid,"OrderVirtualtLong");
			var OrderFillterNo="";
			var OrderChronicDiagCode = GetCellData(rowid,"OrderChronicDiagCode");
			if (("^"+GlobalObj.InsurBillStr+"^").indexOf("^"+BillTypeRowid+"^")==-1){
				OrderChronicDiagCode="";
			}
			/// 采集部位
			var OrderLabSpecCollectionSiteRowid = GetCellData(rowid,"OrderLabSpecCollectionSiteRowid");
			//护士补录医嘱关联主医嘱分发时间
			var OrderNurseExecLinkDispTimeStr = GetCellData(rowid,"OrderNurseExecLinkDispTimeStr");
			if (!OrderNurseExecLinkDispTimeStr) OrderNurseExecLinkDispTimeStr="";
			var OrderSerialNum= GetCellData(rowid,"OrderSerialNum");
			//计算值，在这里占位-tanjishan
			var CalPrescNo=CalPrescSeqNo=LabEpisodeNoStr=BindSourceSerialNumStr="";
			var OrderItem = OrderARCIMRowid + "^" + OrderType + "^" + OrderPriorRowid + "^" + OrderStartDate + "^" + OrderStartTime + "^" + OrderPackQty + "^" + OrderPrice;
			OrderItem = OrderItem + "^" + OrderRecDepRowid + "^" + BillTypeRowid + "^" + OrderDrugFormRowid + "^" + OrderDepProcNotes;
			OrderItem = OrderItem + "^" + OrderDoseQty + "^" + OrderDoseUOMRowid + "^" + OrderQtySum + "^" + OrderFreqRowid + "^" + OrderDurRowid + "^" + OrderInstrRowid;
			OrderItem = OrderItem + "^" + PHPrescType + "^" + OrderMasterSeqNo + "^" + OrderSeqNo + "^" + OrderSkinTest + "^" + OrderPhSpecInstr + "^" + OrderCoverMainIns;
			OrderItem = OrderItem + "^" + OrderActionRowid + "^" + OrderARCOSRowid + "^" + OrderEndDate + "^" + OrderEndTime + "^" + OrderLabSpecRowid + "^" + OrderMultiDate;
			OrderItem = OrderItem + "^" + OrderNotifyClinician + "^" + OrderDIACatRowId + "^" + OrderInsurCatRowId + "^" + OrderFirstDayTimes + "^" + OrderInsurSignSymptomCode;
			OrderItem = OrderItem + "^" + OrderStageCode + "^" + OrderSpeedFlowRate + "^" + AnaesthesiaID + "^" + OrderLabEpisodeNo;
			OrderItem = OrderItem + "^" + LinkedMasterOrderRowid + "^" + OrderNutritionDrugFlag;
			OrderItem = OrderItem + "^" + OrderMaterialBarCode + "^^" + OrderCPWStepItemRowId + "^" + OrderInsurApproveType;
			OrderItem = OrderItem + "^" + OrderFlowRateUnitRowId + "^" + OrderDate + "^" + OrderTime + "^" + OrderNeedPIVAFlag + "^" + OrderAntibApplyRowid + "^" + AntUseReason + "^" + UserReasonId;
			OrderItem = OrderItem + "^" + OrderLocalInfusionQty + "^" + OrderBySelfOMFlag + "^" + ExceedReasonID + "^" + OrderPackUOMRowid + "^" + OrderPilotProRowid + "^" + OrderOutsourcingFlag;
			OrderItem = OrderItem + "^" + OrderItemRowid + "^" + ApplyArcId + "^" + DCAARowId + "^" + OrderOperationCode;
			OrderItem = OrderItem + "^" + OrderMonitorId + "^" + OrderNurseLinkOrderRowid + "^" + OrderBodyPartLabel + "^" + CelerType + "^" + OrdRowIndex + "^" + OrderFreqWeekStr +"^"+ FindRecLocByLogonLocFlag+"^"+OrderPracticePreRowid;
			OrderItem = OrderItem + "^" + OrderFreqTimeDoseStr+ "^"+OrderNurseBatchAdd+"^" +OrderSum+"^"+AntCVID+"^"+OrderPkgOrderNo+"^^^^"+OrderDocRowid+"^"+OrderVirtualtLong+"^"+OrderFillterNo;
			OrderItem = OrderItem + "^" + EmConsultItm + "^" + OrderChronicDiagCode + "^" + OrderFreqFreeTimeStr+"^"+OrderLabSpecCollectionSiteRowid +"^"+ OrderNurseExecLinkDispTimeStr;
			OrderItem = OrderItem + "^" + PGIID+ "^" + OrderSerialNum+ "^" + CalPrescNo + "^" + CalPrescSeqNo + "^" + LabEpisodeNoStr+ "^" + BindSourceSerialNumStr+ "^" + OrderOpenForAllHosp;
			if (OrderItemStr == "") { OrderItemStr = OrderItem } else { OrderItemStr = OrderItemStr + String.fromCharCode(1) + OrderItem }
		}
		$.cm({
			ClassName:"web.DHCOEOrdAppendItem",
			MethodName:"GetOneOrdItemAppendTipInfo",
			Adm:GlobalObj.EpisodeID, OrdItemStr:OrderItemStr, SessionStr:GetSessionStr()
		},function(AppendItems){
			if(AppendItems.length){
				var AppendItemsStr=JSON.stringify(AppendItems);
				AppendItemsStr=AppendItemsStr.replace(/\"/g,"'");
				var $html=$('<a id="'+MainRowid+'_OrderAppendInfo_tooltip"></a>').addClass('append-item-tip').text(AppendItems.length).attr("OverInfo",AppendItemsStr).attr('onmouseover',"OrderAppendInfoMouseOver()").attr('onmouseout',"OrderAppendInfoMouseOut()");
				SetCellData(MainRowid, "OrderAppendInfo", $html.prop('outerHTML'));
			}
		});
	},500);
}
function OrderAppendInfoMouseOver()
{
	var obj=websys_getSrcElement();
	var AppendItemsStr=$(obj).attr("overinfo")
	if (typeof AppendItemsStr =="undefined" || AppendItemsStr==""){
		return;
	}
	AppendItemsStr=AppendItemsStr.replace(/\'/g,"\"");
	var AppendItems=$.parseJSON(AppendItemsStr);
	var content="";
	$.each(AppendItems,function(){
		var text=this.ARCIMDesc+' x'+this.Qty;
		if(content=='') content=text;
		else content+='<br/>'+text;
	});
	$(event.target).tooltip({content:content}).tooltip('show');
}
function OrderAppendInfoMouseOut()
{
	$(event.target).tooltip('hide');
}
///国家医保编码查看
function InsuNationShowClick(rowid){
	var OrderARCIMRowid=GetCellData(rowid,"OrderARCIMRowid");
	if (OrderARCIMRowid!=""){
		websys_showModal({
			iconCls:'icon-w-find',
			url:"dhc.orderinsudetail.csp?ArcimDr=" + OrderARCIMRowid+"&EpisodeID="+GlobalObj.EpisodeID,
			title:$g('国家医保查看'),
			width:640,height:250
		});
	}
}
function SetVirtualtLongRemark(rowid)
{
	if (GlobalObj.UserEMVirtualtLong!="1"){
		return true;
	}
	var OrderPriorRowid = GetCellData(rowid, "OrderPriorRowid");
	if (IsLongPrior(OrderPriorRowid)){
		return true;
	}
	var OrderPriorRemarks = GetCellData(rowid, "OrderPriorRemarksRowId");
	var OrderType = GetCellData(rowid, "OrderType");
	var OrderHiddenPara=GetCellData(rowid,"OrderHiddenPara");
	//可拆分发药的接受科室串
	var NormSplitPackQtyPHRecLocList = mPiece(OrderHiddenPara, String.fromCharCode(1), 24);
	var OrderRecDepRowid = GetCellData(rowid, "OrderRecDepRowid");
	var NormSplitPackQty=0;
	if ((NormSplitPackQtyPHRecLocList!="")&&(("!"+NormSplitPackQtyPHRecLocList+"!").indexOf("!"+OrderRecDepRowid+"!")!=-1)){
    	NormSplitPackQty=1;
    }
	if ((NormSplitPackQty=="0")&&(OrderType=="R")){
		var OrderVirtualtLong=GetCellData(rowid, "OrderVirtualtLong");
		if (OrderVirtualtLong=="Y"){
			OrderPriorRemarkschangeCommon(rowid,"","ZT");
		}else{
			if (OrderPriorRemarks=="ZT"){
				OrderPriorRemarkschangeCommon(rowid,"ZT","");
			}
		}
	}
}
function InitRowBtn(rowid)
{
	SetCellData(rowid, "OrderOperatBtn", '<div style="width:100%;height:100%"></div>');
	$('#Order_DataGrid').find('tr#'+rowid).find('td[aria-describedby="Order_DataGrid_OrderOperatBtn"]').css('position','relative').children().marybtnbar({
		barCls:'background:none;padding-top:5px;',
		url:'',
		moreBtnText:'',
		data:GlobalObj.RowBtnData,
		onClick:function(jq,cfg){
			jq.tooltip('hide');
			if(CheckIsClear(rowid)&&(cfg.id!='Delete_Row')){
				return;
			}
			/// 删除的单独处理
			if(cfg.id != "Delete_Row") $("#Order_DataGrid").jqGrid('resetSelection').setSelection(rowid,true);
			switch(cfg.id){
				case 'Delete_Row':
					if (CheckIsClear(rowid) ) {
						DeleteRow(rowid,"Group");
					}else{
						if(GlobalObj.StopGroupOrder!="1") {
							//可单独停止子医嘱
							var Row=$('#Order_DataGrid').jqGrid("getRowData",rowid);
							$.messager.confirm('确认对话框', '确定删除该条的记录吗？', function(r){
								if (r){
									var OrderMasterSeqNo = GetCellData(rowid, "OrderMasterSeqNo");
									if(OrderMasterSeqNo == "") { 
										SetMasterSeqNo(rowid, "", "C");
									}else{
										SetMasterSeqNo("", rowid, "C");
									}
									DeleteRows([rowid]);
								}
							})
						}else {
							$("#Order_DataGrid").jqGrid('resetSelection').setSelection(rowid,true);
							Delete_Order_row();
						}
					}
					break;
				case 'Move_Up_Row':
					SetUpToRowClickHandler();
					break;
				case 'Move_Down_Row':
					SetDownToRowClickHandler();
					break;
				case 'Help_Tip_Row':
					YDTS_Click(rowid);
					break;
				case 'LookOrdPrice_Row':
					PriceDetail(rowid);
					break;
				case 'InsuNationShow_Row':
					InsuNationShowClick(rowid);
					break;
				case 'Historyarcimdose_Row':
					ArcimHistoryShowClick(rowid);
					break;
				default:break;
			}
		}
    });
}
function IsSpeedRateSeparateInstr(InstrRowId){
    if(!InstrRowId) return false;
    if(GlobalObj.SpeedRateSeparateInstr=="") return false;
    var Instr = "^" + InstrRowId + "^";
    //非滴速用法 不是滴速自定义用法
    //if ((GlobalObj.DrippingSpeedInstr).indexOf(Instr)<0) return false;
    if (GlobalObj.SpeedRateSeparateInstr.indexOf(Instr) != "-1") {
        return true;
    }
    return false;
}
function ArcimHistoryShowClick(rowid){
	var OrderARCIMRowid=GetCellData(rowid,"OrderARCIMRowid");
	var OrderType = GetCellData(rowid, "OrderType");
	if (OrderType!="R"){
		$.messager.alert("提示","请选择药品医嘱进行查看!");
        return false;
		}
	if (OrderARCIMRowid!=""){
		websys_showModal({
				url:"dhcdoc.admhistoryarcimdoseline.csp?ARCIMDR=" + OrderARCIMRowid+"&EpisodeID="+GlobalObj.EpisodeID,
				title:$g('用药剂量变化图'),
				width:750,height:660
			});
	}
}
function InitDoseQtyToolTip(rowid)
{
	var $target=$('tr#'+rowid).find('td[aria-describedby=Order_DataGrid_OrderDoseQty]');
	if($('#'+rowid+'_OrderDoseQty').size()){
		if($target.hasClass('tooltip-f')){
			$target.tooltip('destroy');
		}
		$target=$('#'+rowid+'_OrderDoseQty');
	}
	$target.tooltip({
		content:'',
		onShow:function(){
			var DoseQtyStr=GetCellData(rowid,'OrderDoseQty');
			if(DoseQtyStr.indexOf('-')<=0){
				$(this).tooltip('tip').hide();
			}else{
				var OrderDoseUOM = GetCellData(rowid, "OrderDoseUOM");
				var DoseQtyArr=DoseQtyStr.split('|');
				var NormalDoseQtyStr=DoseQtyArr[0].split('-').join(OrderDoseUOM+'、')+OrderDoseUOM;
				var content=$g('每日剂量: ')+NormalDoseQtyStr;
				if(DoseQtyArr[1]){
					content=$g('首日剂量: ')+DoseQtyArr[1].split('-').join(OrderDoseUOM+'、')+OrderDoseUOM+'<br/>'+content;
				}
				$(this).tooltip('tip').show();
				$(this).tooltip('update',content).tooltip('reposition');
			}
		}
	});
}

/**
 * 同步成组医嘱的流速信息 
 * 当对已录入的医嘱进行关联时，判断是否已经录入滴速：
 * 1）若都没有录入滴速，则正常关联，当医生录入一个滴速后需要同步到关联医嘱的每一条医嘱；
 * 2）若只有一条医嘱录入了滴速，则同步关联医嘱的每一条医嘱的滴速；
 * @param {*} rowid 
 * @returns 
 */
function SyncGroupFlowInfo(rowid){
    if ($.isNumeric(rowid)==false){return true;}
    var MainID=GetCellData(rowid, "OrderMasterSeqNo");
    if (MainID==""){return true;}
    var SubOrderType = GetCellData(rowid, "OrderType");
    if(SubOrderType!="R"){return true;}
    
    var MainSpeedFlowRate=GetCellData(MainID, "OrderSpeedFlowRate").replace(/(^\s*)|(\s*$)/g, '');
    var SubSpeedFlowRate=GetCellData(rowid, "OrderSpeedFlowRate").replace(/(^\s*)|(\s*$)/g, '');
    var SubSpeedFlowRateUnitRowId=GetCellData(rowid, "OrderFlowRateUnitRowId")

    var SyncRowId=MainID;
    if((MainSpeedFlowRate=="")&&(SubSpeedFlowRate!="")&&(SubSpeedFlowRateUnitRowId!="")){
        SyncRowId=rowid;
    }

    var SpeedFlowRate=GetCellData(SyncRowId, "OrderSpeedFlowRate").replace(/(^\s*)|(\s*$)/g, '');
    var FlowRateUnitRowId=GetCellData(SyncRowId, "OrderFlowRateUnitRowId")
    var FlowRateUnit=GetCellData(SyncRowId, "OrderFlowRateUnit")
    var SyncInfo={
        SpeedFlowRate:SpeedFlowRate,
        FlowRateUnitRowId:FlowRateUnitRowId,
        FlowRateUnit:FlowRateUnit
    }
   
    //1.主医嘱流速不为空,需将主医嘱的流速同步到子医嘱
    if (SyncRowId==MainID){
        //1.1 子医嘱 不是滴速自定义用法 或 滴速为空 的强制同步滴速 
        var SubEditStatus=GetEditStatus(rowid)
        var SubInstrRowId = GetCellData(rowid, "OrderInstrRowid");
        if((!IsSpeedRateSeparateInstr(SubInstrRowId))||(SubSpeedFlowRate=="")){
            SetCellData(rowid, "OrderSpeedFlowRate", SyncInfo.SpeedFlowRate);
            if (SubEditStatus == true) {
                SetCellData(rowid, "OrderFlowRateUnit", SyncInfo.FlowRateUnitRowId);
            } else {
                SetCellData(rowid, "OrderFlowRateUnit", SyncInfo.FlowRateUnit);
            }
            SetCellData(rowid, "OrderFlowRateUnitRowId", SyncInfo.FlowRateUnitRowId);    
        }
    }

    //2.子医嘱流速不为空,主医嘱流速为空 需将子医嘱主数据同步到主医嘱和其他子医嘱
    if(SyncRowId==rowid){
        var MainEditStatus=GetEditStatus(MainID);
        if(MainSpeedFlowRate==""){
            SetCellData(MainID, "OrderSpeedFlowRate", SyncInfo.SpeedFlowRate);
            if (MainEditStatus == true) {
                SetCellData(MainID, "OrderFlowRateUnit", SyncInfo.FlowRateUnitRowId);
            } else {
                SetCellData(MainID, "OrderFlowRateUnit", SyncInfo.FlowRateUnit);
            }
            SetCellData(MainID, "OrderFlowRateUnitRowId", SyncInfo.FlowRateUnitRowId); 
            ChangeOrderSpeedFlowRate(MainID)  
            ChangeLinkOrderFlowRateUnit(MainID,SyncInfo.FlowRateUnitRowId,SyncInfo.FlowRateUnit)
        }
    }
}
//以选中的第一条医嘱为准。 同步选中医嘱时间日期
function SynBtnClickHandler() {
	SynColumnData('OrderDate','');
	SynColumnData('OrderStartDate','',SetOrderFirstDayTimes);
}
function SynchroOrdNotesClickHandler(){
	SynColumnData('OrderDepProcNote');
}
function SynExceedReasonClickHandler(){
	SynColumnData('ExceedReasonID','ExceedReason');
}
function SynStageClickHandler()
{
	SynColumnData('OrderStageCode','OrderStage');
}
///同步列数据
function SynColumnData(idField,textField,rowCallBackFun)
{
	var rowids=new Array();
	var ids = $('#Order_DataGrid').jqGrid("getGridParam", "selarrrow");
	ids = ids.sort(OrdComm_SortNumberAsc);
	$.each(ids,function(index,rowid){
		var OrderARCIMRowid = GetCellData(rowid, "OrderARCIMRowid");
		if((CheckIsItem(rowid) == false)&&OrderARCIMRowid){
			rowids.push(rowid);
		}
	});
	if (rowids.length <= 1) {
		$.messager.popover({msg:"请选择需要同步的多行记录",type:'alert'});
		return false;
	}
	var rowid=rowids.shift();
	var value=idField?GetCellData(rowid,idField):'';
	var text=textField?GetCellData(rowid,textField):'';
	$.each(rowids,function(index,rowid){
		if(idField) SetCellData(rowid,idField,value);
		if(textField){
			if(GetEditStatus(rowid)&&idField){
				SetCellData(rowid,textField,value);
			}else{
				SetCellData(rowid,textField,text);
			}
		}
		if(rowCallBackFun) rowCallBackFun(rowid);
	});
	$.messager.popover({msg:"同步完成",type:'success'});
	return true;
}

/// 展示第二副屏
function ShowSecondeWin(Flag){
    if (PageLogicObj.MainSreenFlag==0){
	    var Obj={PatientID:GlobalObj.PatientID,EpisodeID:GlobalObj.EpisodeID,mradm:GlobalObj.mradm};
	    if (Flag=="onOpenIPTab"){
		    //信息总览
		}
		if (Flag=="onOpenDHCEMRbrowse"){
			//病历浏览
			/*var MenuCode="DHC.inpatient.Doctor.DHCEMRbrowse";
			if (GlobalObj.PAAdmType=="O"){
				MenuCode="DHC.Outpatient.Doctor.DHCEMRbrowse";
			}  
			if (GlobalObj.isNurseLogin == "1") {
				//护士病历浏览
				var MenuCode="DHC.inpatient.Nurse.DHCEMRbrowse";
			}*/
			var JsonStr=$.m({
				ClassName:"DHCDoc.Util.Base",
				MethodName:"GetMenuInfoByName",
				MenuCode:"DHC.Seconde.DHCEMRbrowse"		//使用最新统一维护的菜单
				/*
				MethodName:"GetMenuInfoByGroupId",
				GroupId:session["LOGON.GROUPID"],		//23, //护士站安全组 29 
				MenuDesc:"病历浏览新"
				*/
			},false)
			if (JsonStr=="{}") return false;
			var JsonObj=JSON.parse(JsonStr);
			$.extend(Obj,JsonObj);
		}
		websys_emit(Flag,Obj);
	}
}

/// 人脸移动
function FaceMoveClick(){
	FaceMove.notReturn=1;
	FaceMove.cmd("demo.exe")
	//FaceMove.cmd("FaceMove.bat")
	//FaceMove.cmd("FaceVBS.vbs")
	return
}
function GetInstrDefSpeedRateUnit(OrderInstrRowid){
	if ((GlobalObj.DrippingSpeedInstr).indexOf("^"+OrderInstrRowid+"^")<0) return "";
	if(!GlobalObj.InstrDefSpeedRateUnit){
		return "";
	}
    OrderInstrRowid="Z"+OrderInstrRowid;
	return GlobalObj.InstrDefSpeedRateUnit[OrderInstrRowid]?GlobalObj.InstrDefSpeedRateUnit[OrderInstrRowid]:"";
}
function ShowSpecDiagForm(callBackFun,SerialNum,SpecLocDiagCatCode,SpecLocDiagCatName,ArcimDesc)
{
	var url="opdoc.specloc.diag.csp?EpisodeID="+GlobalObj.EpisodeID+"&PatientID="+GlobalObj.PatientID+"&SpecLocDiagCatCode="+SpecLocDiagCatCode+"&SerialNum="+SerialNum;
	websys_showModal({
		iconCls:'icon-w-edit',
		url:url,
		title:SpecLocDiagCatName+$g(' 填写'),
		width:SpecLocDiagCatCode=='KQMB'?1200:400,
		height:700,
		closable:true,
		callBackRetVal:"",
		onBeforeClose:function(){
			if (parseInt(websys_showModal("options").callBackRetVal)>0) {
				callBackFun(true);
			}else{
				$.messager.alert("提示",ArcimDesc + $g("未填写专科表单,取消录入"),"info",function(){
					callBackFun(false);
				});
			}
		},
		CallBackFunc:function(retval){
			if (typeof retval=="undefined") retval="";
			websys_showModal("options").callBackRetVal=retval;
			websys_showModal("close");
		}
	});
}