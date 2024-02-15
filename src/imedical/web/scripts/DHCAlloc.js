var fso = new ActiveXObject("WScript.NetWork");
var fs = new ActiveXObject("Scripting.FileSystemObject");
var QueID=0
var QueDoc=""
var SelDocDr=0
var SelRoom=""
var CurrentRow=0
var PerState=""
var GSelectAdmRowId=""
var GSelectPatRowId=""
var m_CardNoLength=0;
var m_SelectCardTypeDR="";
var SelectedPatientID="";

function BodyLoadHandler() {
	websys_setTitleBar("OutPatient  Registeration");
	var Obj=document.getElementById('B_Confirm');
	if (Obj) Obj.onclick = QueryListInit;
	var Obj=document.getElementById('OrderInput');
	if (Obj) Obj.onclick = OrderInputHandler;
	var Obj=document.getElementById('C_All');
	if (Obj) Obj.onclick = C_Allclick;
	var Obj=document.getElementById('B_ReadMagCard');
	if (Obj) Obj.onclick = B_ReadCard;
	var Obj=document.getElementById('CardNo');
	if (Obj) Obj.onkeydown = CardNoclick;
	var Obj=document.getElementById('T_ID');
	if (Obj) Obj.onkeydown = TIDKeyDownClick;
	var Obj=document.getElementById('C_Again');
	if (Obj) Obj.onclick = C_Againclick;
	var Obj=document.getElementById('C_Wait');
	if (Obj) Obj.onclick = C_Waitclick;
	var Obj=document.getElementById('C_Pass');
	if (Obj) Obj.onclick =C_Passclick;
	var Obj=document.getElementById('C_Arrive');
	if (Obj) Obj.onclick =C_Arriveclick;
	var Obj=document.getElementById('C_Cancel');
	if (Obj) Obj.onclick =C_Cancelclick;
	var Obj=document.getElementById('C_Reg');
	if (Obj) Obj.onclick =C_Regclick;
	var Obj=document.getElementById('C_Consultation');
	if (Obj) Obj.onclick =C_Consultationclick;
	var Obj=document.getElementById('L_CarePrv');
	if (Obj) Obj.ondblclick =CarePrvdblclick;
	var Obj=document.getElementById('L_Doc');
	if (Obj) Obj.onchange =DocChange;
	var Obj=document.getElementById('L_Room');
	if (Obj) Obj.ondblclick =Roomdblclick;
	
	var Obj=document.getElementById('B_Prior');
	if (Obj) Obj.onclick =Priorclick;
	var Obj=document.getElementById('B_QueAgain');
	if (Obj) Obj.onclick =QueAgainclick;
	var Obj=document.getElementById('B_Reg');
	if (Obj) Obj.onclick =QueCheckinclick;
	var Obj=document.getElementById('B_AdjConfirm');
	if (Obj) Obj.onclick =AdjConfirmclick;
	var Obj=document.getElementById('B_Quit');
	if (Obj) Obj.onclick =Quitclick;
	var Obj=document.getElementById('B_clear');
	if (Obj) Obj.onclick =Clearclick;
	var Obj=document.getElementById('B_Call');
	if (Obj) Obj.onclick=CallClick;
	var Obj=document.getElementById('B_Consultation');
	if (Obj) Obj.onclick=ConsultationClick;
	var Obj=document.getElementById('B_ChangeDep');
	if (Obj) Obj.onclick =B_ChangeDepclick;
	var Obj=document.getElementById('C_AgainAndWait');
	if (Obj) Obj.onclick =C_AgainAndWaitOnclick;
	var Obj=document.getElementById('B_Sum');
	if (Obj) Obj.onclick = B_SumOnclick;

	FindCheckinStatus()
	var myobj=document.getElementById('CardTypeDefine');
	if (myobj){
		myobj.onchange=CardTypeDefine_OnChange;
		myobj.size=1;
		myobj.multiple=false;
	}
	
	var myobj=document.getElementById('T_Zone');
	if (myobj){
		myobj.onchange=Zone_OnChange;
		myobj.size=1;
		myobj.multiple=false;
	}
	
	var obj=document.getElementById("SARegister");
	if(obj){
	    //var RegNo=document.getElementById("T_ID").value;
		if(obj.addEventListener) {		   
			obj.addEventListener("click", function(){
			 
			 
			window.open("dhc.nurse.subscriberegister.csp?PatientID="+SelectedPatientID,'',"location=no,menubar=no,titlebar=no,toolbar=no,resizable=yes,channelmode")}, false);
			
		}else{		
			obj.onclick=function(){					  
			
			window.open("dhc.nurse.subscriberegister.csp?PatientID="+SelectedPatientID,'',"location=no,menubar=no,titlebar=no,toolbar=no,resizable=yes,channelmode");
		}
	   }
	}
	
	var Obj=document.getElementById("QueCount");
	if (Obj)  Obj.readOnly = true;

	loadCardType()
	CardTypeDefine_OnChange()
	//loadDepartment();
	SetTZone();
	QueryListInit(); //分诊员默认看到的是FindCheckinStatus取出来的状态对应的所有的挂号
	

}

function loadCardType(){
	
	DHCWebD_ClearAllListA("CardTypeDefine");
	var encmeth=DHCWebD_GetObjValue("CardTypeEncrypt");
	if (encmeth!=""){
		var rtn=cspRunServerMethod(encmeth,"DHCWeb_AddToListA","CardTypeDefine");
	}
}
function CardTypeDefine_OnChange()
{
	var myoptval=DHCWeb_GetListBoxValue("CardTypeDefine");
	var myary=myoptval.split("^");
	var myCardTypeDR=myary[0];
	m_SelectCardTypeDR = myCardTypeDR;
	if (myCardTypeDR=="")
	{
		return;
	}
	///Read Card Mode
	if (myary[16]=="Handle"){
		var myobj=document.getElementById("CardNo");
		if (myobj)
		{
			myobj.readOnly = false;
		}
		DHCWeb_DisBtnA("ReadCard");
	}
	else
	{
		var myobj=document.getElementById("CardNo");
		if (myobj)
		{
			myobj.readOnly = true;
		}
		var obj=document.getElementById("ReadCard");
		if (obj){
			obj.disabled=false;
			obj.onclick=ReadHFMagCard_Click;
		}
	}
	
	//Set Focus
	if (myary[16]=="Handle"){
		DHCWeb_setfocus("CardNo");
	}else{
		DHCWeb_setfocus("ReadCard");
	}
	
	m_CardNoLength=myary[17];
	
}

function Zone_OnChange(){
	
	var  myoptval=DHCWeb_GetListBoxValue("T_Zone");
	var myobj=document.getElementById('Zone');
	if(myobj)myobj.value=myoptval
		var li=window.location.href
		var arr=li.split("&")
		var link=arr[0]+"&"+arr[1]+"&"+arr[2]
		var lnk=link+"&Zone="+myoptval;
		QueryListInit()
		ReloadData()
		BorUserId=myobj.value
	parent.frames[0].document.location.href="dhcdocallocroomview.csp?&BorUserId="+BorUserId;
		//window.location.href=lnk;
	return;	
}
function ReloadData(){
	var obj=document.getElementById('L_Room');
	ClearAllList(obj);
	var myobj=document.getElementById('Zone');
	if(myobj)Zone=myobj.value
    var encmeth=DHCWebD_GetObjValue("RoomEncrypt");
	if (encmeth!=""){
		var rtn=cspRunServerMethod(encmeth,"DHCWeb_AddToListA","L_Room",session['LOGON.USERCODE'],Zone);
	}
	var obj=document.getElementById('L_CarePrv');
	ClearAllList(obj);
    var encmeth=DHCWebD_GetObjValue("CarePrvEncrypt");
	if (encmeth!=""){
		var rtn=cspRunServerMethod(encmeth,"DHCWeb_AddToListA","L_CarePrv",session['LOGON.USERCODE'],Zone);
	}
}
function SetTZone(){
	var myobj=document.getElementById('Zone');
	if(myobj){
		var Obj=document.getElementById('T_Zone');
		var Zone=myobj.value;
		for(var i=0;i<Obj.options.length;i++)
		{
			if(Obj.options[i].value==Zone){
				Obj.selectedIndex=i;
			}
		}
		var  myoptval=DHCWeb_GetListBoxValue("T_Zone");
	    var myobj=document.getElementById('Zone');
	    if(myobj)myobj.value=myoptval
	}
}
function loadDepartment(){
	var List=document.getElementById("T_Zone")
	var selectindex=List.selectedIndex;
	if(selectindex<=0)
    var T_Zone =List.options[0].text;
    else
     var T_Zone=List.options[selectindex].text;
	var encmeth=DHCWebD_GetObjValue("DepartmentEncrypt");
	if (encmeth!=""){
		var rtn=cspRunServerMethod(encmeth,"DHCWeb_AddToListA","Department",T_Zone);
	}
	
}
function SetCardNOLength(){
	var obj=document.getElementById('RCardNo');
		if (obj.value!='') {
			if ((obj.value.length<m_CardNoLength)&&(m_CardNoLength!=0)) {
				for (var i=(m_CardNoLength-obj.value.length-1); i>=0; i--) {
					obj.value="0"+obj.value
				}
			}
			var myCardobj=document.getElementById('CardNo');
			if (myCardobj){
				myCardobj.value=obj.value;
			}
		}
}
function B_ReadCard()
{
	var myEquipDR=DHCWeb_GetListBoxValue("CardTypeDefine");
	//var myEquipDR=combo_CardType.getActualValue();
    var CardInform=DHCACC_GetAccInfo(m_SelectCardTypeDR,myEquipDR)
    var CardSubInform=CardInform.split("^");
    var rtn=CardSubInform[0];
    //alert(CardInform)
    switch (rtn){
			case "-200": //卡无效
				alert("卡无效");
				PapmiNoObj=document.getElementById("PapmiNo");
    			PapmiNoObj.value="";
    			CleartTbl()
				break;
			default:
				//alert(myrtn)
				document.getElementById('T_ID').value=CardSubInform[5]
				//alert(document.getElementById('T_ID').value)
				//FindPatQueue()
				PapmiNo=CardSubInform[5];
				PapmiNoObj=document.getElementById("PapmiNo");
				
    			PapmiNoObj.value=PapmiNo;
    			QueryList();
				break;
		}
		
    
}

function OrderInputHandler(e) {
	//alert(GSelectAdmRowId+","+GSelectPatRowId)
	var lnk="udhcopbillforadmif.csp?ReloadFlag=1"+"&SelectAdmRowId="+GSelectAdmRowId+"&SelectPatRowId="+GSelectPatRowId;
    var NewWin=open(lnk,"udhcopbillif","scrollbars=no,resizable=no,top=6,left=6,width=1000,height=680");
	
}


function TIDKeyDownClick(e){
	if (evtName=='CardNo') {
		window.clearTimeout(evtTimer);
		evtTimer='';
		evtName='';
	}
	var key=websys_getKey(e);
	if (key==13) {
		var T_ID=document.getElementById('T_ID').value
		if (T_ID=="") return;
		var T_IDLength=10;
		if ((T_ID.length<T_IDLength)&&(T_IDLength!=0)) {
			for (var i=(T_IDLength-T_ID.length-1); i>=0; i--) {
				T_ID="0"+T_ID;
		
	}
		}
		document.getElementById('T_ID').value=T_ID
		FindPatQueue("","")
	}
}
function GetCardNoLength(){
	var CardNoLength="";
	var myoptval=DHCWeb_GetListBoxValue("CardTypeDefine");
	var myary=myoptval.split("^");
	CardNoLength=myary[17];
	return CardNoLength;
}
function CardNoclick(e) {
	//这边要与卡处理一致
	if (evtName=='CardNo') {
		window.clearTimeout(evtTimer);
		evtTimer='';
		evtName='';
	}
	var key=websys_getKey(e);
	if (key==13) {
		var CardNo=document.getElementById('CardNo').value
		if (CardNo=="") return;
		var CardNoLength=GetCardNoLength();
		if ((CardNo.length<CardNoLength)&&(CardNoLength!=0)) {
			for (var i=(CardNoLength-CardNo.length-1); i>=0; i--) {
				CardNo="0"+CardNo;
				//alert(CardNo)
			}
		}
		document.getElementById('CardNo').value=CardNo
		//var myrtn=DHCACC_GetAccInfo(CardTypeRowId,CardNo,"","PatInfo");
		//var myrtn=DHCACC_GetAccInfo(CardTypeRowId,CardNo,"","");
		//var myrtn=DHCACC_GetAccInfo("",CardNo,"","PatInfo");
		var myrtn=DHCACC_GetAccInfo(m_SelectCardTypeDR,CardNo,"","PatInfo");
		var myary=myrtn.split("^");
		var rtn=myary[0];
		AccAmount=myary[3];
				//alert(myrtn)

		switch (rtn){
			case "-200": //卡无效
				alert("卡无效");
				document.getElementById('T_ID').value=""
				websys_setfocus('CardNo');
				break;
			default:
				document.getElementById('T_ID').value=myary[5]
				FindPatQueue("","")
				break;
		}
		
	}
}

function FindCheckinStatus()
{
	var GetDetail=document.getElementById('GetMethodCheckin');
	if (GetDetail) {var encmeth=GetDetail.value} else {var encmeth=''};
	Rtn=cspRunServerMethod(encmeth,'','',session['LOGON.USERCODE'])
	if (Rtn=="Y"){
		var Obj=document.getElementById('C_Reg');
    	Obj.checked=true;
	}else{
		var Obj=document.getElementById('C_Wait');
    	Obj.checked=true;
	}
		
}

function Clearclick()
{
	window.location.reload();
	//alert("dd")
	//return
	//var obj=document.getElementById('L_Doc');
	//ClearAllList(obj);
	//CleartTbl()
	//var obj=document.getElementById('QueryLable')
	//if(obj) obj.value=""
	//var obj=document.getElementById('QueryText')
	//if(obj) obj.value=""
	//var obj=document.getElementById('T_ID')
	//if(obj) obj.value=""
	
}


function Quitclick(){
	
	window.close()
}

function AdjConfirmclick(){
		 if (QueID==0) {
		//请选择病人
	        alert(t['7'])    
		    return
		}
		
        if (SelDocDr==0) {
		//请选择医生
	        alert(t['12'])    
		    return
		}
		if (SelRoom!="") {
		//请选择医生
	        alert(t['14'])    
		    return
		}
		
        //alert(QueID)
         if (!confirm(t['11'])) {
      		return
   		}
   		//return
   		var Usercode=session['LOGON.USERID']

  		var GetDetail=document.getElementById('ParAdjDoc');
			if (GetDetail) {var encmeth=GetDetail.value} else {var encmeth=''};
			if (cspRunServerMethod(encmeth,'AdjDocEvent','',QueID,SelDocDr,Usercode)=='0') {
		//obj.className='';
		}
	    FindPatQueue("","")

		
}

function AdjDocEvent(value) {
	try {
		if (value!=0){	
			// 发生错误
			alert(t['8'])			
		}
	} catch(e) {};
}



function DocChange(){
	var tmp=document.getElementById('L_Doc');
	var selItem=tmp.options[tmp.selectedIndex];	
	//if (selItem) {var p1=selItem.text}
	//alert(selItem.value)
	if (selItem) SelDocDr=selItem.value
}

function QueAgainclick() {
	 if (QueID==0) {
		//请选择病人
	        alert(t['7'])    
		    return
		}
        if ((QueDoc=="")||(PerState=="退号")){
   			alert(t['13'])    
		    return
   		}
         if (!confirm(t['10'])) {
      		return
   		}
  		var GetDetail=document.getElementById('ParAgain');
			if (GetDetail) {var encmeth=GetDetail.value} else {var encmeth=''};
			if (cspRunServerMethod(encmeth,'AgainEvent','',QueID)=='0') {
		//obj.className='';
		}
	    FindPatQueue("","")

}
function AgainEvent(value) {
	try {
		if (value!=0){	
			// 发生错误
			alert(t['8'])			
		}
	} catch(e) {};
}
function QueCheckinclick() {
	 if (QueID==0) {
		//请选择病人
	        alert(t['7'])    
		    return
		}
        if (PerState!=t['Checkin']) {
	        alert(t['CheckinFail'])    
		    return
		}
        // if (!confirm(t['10'])) {
      	//	return
   		//}
  		var GetDetail=document.getElementById('GetMethodArrive');
			if (GetDetail) {var encmeth=GetDetail.value} else {var encmeth=''};
			if (cspRunServerMethod(encmeth,'CheckinEvent','',QueID)=='0') {
		//obj.className='';
		}
	    FindPatQueue("","")

}

function CheckinEvent(value) {
	try {
		if (value!=0){	
			// 发生错误
			alert(t['CheckinError'])			
		}
	} catch(e) {};
}


function Priorclick() {
	 if (QueID==0) {
		//请选择病人
	        alert(t['7'])    
		    return
		}
        //alert(QueID)
        if (!confirm(t['9'])) {
      		return
   		}
  		var GetDetail=document.getElementById('ParPrior');
			if (GetDetail) {var encmeth=GetDetail.value} else {var encmeth=''};
			if (cspRunServerMethod(encmeth,'PriorEvent','',QueID)=='0') {
		//obj.className='';
		}
	    FindPatQueue("","")

}

function PriorEvent(value) {
	try {
		if (value!=0){	
			// 发生错误
			alert(t['8'])			
		}
	} catch(e) {};
}


function CarePrvdblclick(){
	var tmp=document.getElementById('L_CarePrv');
	var selItem=tmp.options[tmp.selectedIndex];	
	
	if (selItem) {
         var p1=selItem.text
         var CarePrvDr=selItem.value;
         var p1=CarePrvDr;   //xp modify,2008-05-04
    }
    var tmp=document.getElementById('QueryLable');
    if (tmp) tmp.value='Doc'
    var tmp=document.getElementById('QueryText');
    if (tmp) tmp.value=p1
    //alert(p1)
    FindPatQueue("",p1)
    
}

function Roomdblclick(){
	var tmp=document.getElementById('L_Room');
	var selItem=tmp.options[tmp.selectedIndex];	
	if (selItem) {
         var p1=selItem.text
    }
    //alert(p1)
    var tmp=document.getElementById('QueryLable');
    if (tmp) tmp.value='Room'
    var tmp=document.getElementById('QueryText');
    if (tmp) tmp.value=p1
    FindPatQueue(p1,"")
    
}

function C_Cancelclick() {
	ClearChecked();
	var CancelObj=document.getElementById('C_Cancel');
	if (CancelObj)CancelObj.checked=true;
	QueryListInit();
	/*
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
    var RegObj=document.getElementById('C_Reg');
    
    if (CancelObj.checked){
    	if (AllObj) AllObj.checked=false;
		if (AgainObj) AgainObj.checked=false;
		if (WaitObj) WaitObj.checked=false;
		if (ArriveObj) ArriveObj.checked=false;
		if (PassObj) PassObj.checked=false;
		if (RegObj) RegObj.checked=false;
    }
    */
}

function C_Regclick() {
	ClearChecked();
	var RegObj=document.getElementById('C_Reg');
	if (RegObj)RegObj.checked=true;
	QueryListInit();
	/*
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
	var RegObj=document.getElementById('C_Reg');
    
    if (RegObj.checked){
    	if (AllObj) AllObj.checked=false;
		if (AgainObj) AgainObj.checked=false;
		if (WaitObj) WaitObj.checked=false;
		if (ArriveObj) ArriveObj.checked=false;
		if (PassObj) PassObj.checked=false;
		if (CancelObj) CancelObj.checked=false;
    }
    */
}


function C_Arriveclick() {
	ClearChecked();
	var ArriveObj=document.getElementById('C_Arrive');
	if (ArriveObj)ArriveObj.checked=true;
	QueryListInit();
	/*
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
    var RegObj=document.getElementById('C_Reg');
    
    if (ArriveObj.checked){
    	if (AllObj) AllObj.checked=false;
		if (AgainObj) AgainObj.checked=false;
		if (PassObj) PassObj.checked=false;
		if (WaitObj) WaitObj.checked=false;
		if (CancelObj) CancelObj.checked=false;
		if (RegObj) RegObj.checked=false;
    }
    */
}

function C_Consultationclick() {
	ClearChecked();
	var ConsultationObj=document.getElementById('C_Consultation');
	if (ConsultationObj)ConsultationObj.checked=true;
}

function C_Passclick() {
	ClearChecked();
	var PassObj=document.getElementById('C_Pass');
	if (PassObj)PassObj.checked=true;
	QueryListInit();
	/*
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
    var RegObj=document.getElementById('C_Reg');
    
    if (PassObj.checked){
    	if (AllObj) AllObj.checked=false;
		if (AgainObj) AgainObj.checked=false;
		if (WaitObj) WaitObj.checked=false;
		if (ArriveObj) ArriveObj.checked=false;
		if (CancelObj) CancelObj.checked=false;
		if (RegObj) RegObj.checked=false;
    }
    */
}


function C_Waitclick() {
	ClearChecked();
	var WaitObj=document.getElementById('C_Wait');
	if (WaitObj)WaitObj.checked=true;
	QueryListInit();
	/*
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
    var RegObj=document.getElementById('C_Reg');
    if (WaitObj.checked){
    	if (AllObj) AllObj.checked=false;
		if (AgainObj) AgainObj.checked=false;
		if (PassObj) PassObj.checked=false;
		if (ArriveObj) ArriveObj.checked=false;
		if (CancelObj) CancelObj.checked=false;
		if (RegObj) RegObj.checked=false;
    }
    */
}
function C_AgainAndWaitOnclick(){
	ClearChecked();
	var AgainAndWaitObj=document.getElementById('C_AgainAndWait');
	if (AgainAndWaitObj) AgainAndWaitObj.checked=true;
	QueryListInit();
}
function C_Againclick() {
	ClearChecked();
	var AgainObj=document.getElementById('C_Again');
	if (AgainObj)AgainObj.checked=true;
	QueryListInit();
	/*
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
    var RegObj=document.getElementById('C_Reg');
         
    if (AgainObj.checked){
    	if (AllObj) AllObj.checked=false;
		if (WaitObj) WaitObj.checked=false;
		if (PassObj) PassObj.checked=false;
		if (ArriveObj) ArriveObj.checked=false;
		if (CancelObj) CancelObj.checked=false;
		if (RegObj) RegObj.checked=false;
    }*/
}
function C_Allclick() {
	ClearChecked();
	var AllObj=document.getElementById('C_All');
	if (AllObj)AllObj.checked=true;
	QueryListInit();
	/* gry
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
    var RegObj=document.getElementById('C_Reg');
   
    if (AllObj.checked){
    	if (AgainObj) AgainObj.checked=false;
		if (WaitObj) WaitObj.checked=false;
		if (PassObj) PassObj.checked=false;
		if (ArriveObj) ArriveObj.checked=false;
		if (CancelObj) CancelObj.checked=false;
		if (RegObj) RegObj.checked=false;
    }
    */
}

function QueryListInit()
{	
	PapmiNoObj=document.getElementById("PapmiNo");
    PapmiNoObj.value="";
    QueryList();
}

function QueryList() {
	RoomDr=""
	MarkDr=""
	var tmp=document.getElementById('QueryLable');
    if (tmp) Querylable=tmp.value
	var tmp=document.getElementById('QueryText');
    if (Querylable=='Doc') {
	    MarkDr=tmp.value
	    }else{
	    RoomDr=tmp.value
	    }
	RoomDr=""
	MarkDr=""
	//PapmiNoObj=document.getElementById("PapmiNo");
    //PapmiNoObj.value=PapmiNo;
	FindPatQueue(RoomDr,MarkDr)
	//var objtbl=document.getElementById('tDHCAlloc');
	//AddRowToList(objtbl)
}

function FindPatQueue(RoomDr,MarkDr) {
	QueID=0
	SelDocDr=0
	
	CleartTbl()
	var AllObj=document.getElementById('C_All');
	var AgainObj=document.getElementById('C_Again');
	var WaitObj=document.getElementById('C_Wait');
	var PassObj=document.getElementById('C_Pass');
	var ArriveObj=document.getElementById('C_Arrive');
	var CancelObj=document.getElementById('C_Cancel');
  var CheckinObj=document.getElementById('C_Reg');
  //var ConsultationObj=document.getElementById('C_Consultation');
  
  var PapmiNoObj=document.getElementById('PapmiNo');  //Read Card,xp add,2008-04-17
  PapmiNo=PapmiNoObj.value
  //alert(PapmiNo);
  var AgainAndWaitObj=document.getElementById('C_AgainAndWait');
    
    var QueryST=""
    if (AllObj.checked) QueryST=t['1'];
    if (AgainObj.checked) QueryST=t['2'];
    if (WaitObj.checked) QueryST=t['3'];
    if (PassObj.checked) QueryST=t['4'];
    if (ArriveObj.checked) QueryST=t['5'];
    if (CancelObj.checked) QueryST=t['6'];
    if (CheckinObj.checked) QueryST=t['Checkin'];
	if (AgainAndWaitObj.checked) QueryST="复诊与等候";
    //if (ConsultationObj.checked) QueryST=t['Consultation'];
	//alert(QueryST)

    var PatID=""
     var CardNoObj=document.getElementById('CardNo');
    if (CardNoObj){
    	if (CardNoObj.value=="") {PatID="";}
    }
	var T_IDObj=document.getElementById('T_ID');
    if (T_IDObj) var PatID=T_IDObj.value
	var UserCode=session['LOGON.USERCODE']
	var CompName=""
	//var RoomDr=""
	//var MarkDr=""
	//UserCode,CompName,QueryST,RoomDr,MarkDr
	var Zone="";
	var ZoneObj=document.getElementById('Zone');
	if (ZoneObj) Zone=ZoneObj.value;
		var GetDetail=document.getElementById('ParQuery');
			if (GetDetail) {var encmeth=GetDetail.value;} else {var encmeth=''};
			//alert(UserCode+"^"+CompName+"^"+QueryST+"^"+RoomDr+"^"+MarkDr+"^"+PatID+"^"+PapmiNo);
			var QueCount=cspRunServerMethod(encmeth,'QueryDetail','',UserCode,CompName,QueryST,RoomDr,MarkDr,PatID,PapmiNo,Zone)
			if(QueCount=='0'){
				 var QueCountNo=QueryST+ "人数:  "+QueCount
				 var obj=document.getElementById('QueCount');
				 if (obj){
					 obj.value=QueCountNo;
				 }
			     obj.className='';
			}else{
				var QueCountNo=QueryST+ "人数:  "+QueCount
				var obj=document.getElementById('QueCount');
				if (obj){
					obj.value=QueCountNo;
				}
			}
			
			/*if (cspRunServerMethod(encmeth,'QueryDetail','',UserCode,CompName,QueryST,RoomDr,MarkDr,PatID,PapmiNo,Zone)=='0') {
		     obj.className='';
		}*/
		//var objtbl=document.getElementById('tDHCOPPatList');
		
}

function QueryDetail(value) {
	try {
		if (value!="N"){
		//	alert(value)	
		//return
		var objtbl=document.getElementById('tDHCAlloc');
		//AddRowToList(objtbl)

		var rows=objtbl.rows.length;
		var LastRow=rows - 1;
		var eSrc=objtbl.rows[LastRow];
		var RowObj=getRow(eSrc);
		var rowitems=RowObj.all;
		if (!rowitems) rowitems=RowObj.getElementsByTagName("label");
		for (var j=0;j<rowitems.length;j++) {
			if (rowitems[j].id) {
				var Id=rowitems[j].id;
				var arrId=Id.split("z");
				var Row=arrId[arrId.length-1];
			}
		}
		//alert(Row);
		var Split_Value=value.split("^")
		var Tbl_Que=document.getElementById("Tbl_Quez"+Row);
		var Tbl_CarePrv=document.getElementById("Tbl_CarePrvz"+Row);
		var Tbl_ID=document.getElementById("Tbl_IDz"+Row);
		var Tbl_Name=document.getElementById("Tbl_Namez"+Row);
		var Tbl_Sex=document.getElementById("Tbl_Sexz"+Row);
		var Tbl_Age=document.getElementById("Tbl_Agez"+Row);
		var Tbl_Doc=document.getElementById("Tbl_Docz"+Row);
		var Tbl_Status=document.getElementById("Tbl_Statusz"+Row);
		var Tbl_Prior=document.getElementById("Tbl_Priorz"+Row);
		var Tbl_No=document.getElementById("Tbl_Noz"+Row);
		var Tbl_ComputerIP=document.getElementById("Tbl_ComputerIPz"+Row);
		var ID=document.getElementById("IDz"+Row);
		var Tbl_Dep=document.getElementById("Tbl_Depz"+Row);
		var PatientID=document.getElementById("PatientIDz"+Row);
		var EpisodeID=document.getElementById("EpisodeIDz"+Row);
		var mradm=document.getElementById("mradmz"+Row);
		var ReloadFlag=document.getElementById("ReloadFlagz"+Row);
		var SelectPatRowId=document.getElementById("SelectPatRowIdz"+Row);
		var SelectAdmRowId=document.getElementById("SelectAdmRowIdz"+Row);
		var ConsultatFlage=document.getElementById("ConsultatFlagez"+Row);
		
 		// desc=PatNo_"^"_PatName_"^"_Prior_"^"_status_"^"_SeqNo_"^"_RoomName_"^"_MarkName_"^"_DocName_"^"_QueID

   	 	if (Tbl_Que) Tbl_Que.innerText=unescape(Split_Value[5])
    	if (Tbl_CarePrv) Tbl_CarePrv.innerText=unescape(Split_Value[6])
    	if (Tbl_ID) Tbl_ID.innerText=unescape(Split_Value[0])
    	if (Tbl_Name) Tbl_Name.innerText=unescape(Split_Value[1])
    	if (Tbl_Sex) Tbl_Sex.innerText=unescape(Split_Value[10])
    	if (Tbl_Age) Tbl_Age.innerText=unescape(Split_Value[9])
    	if (Tbl_Doc) Tbl_Doc.innerText=unescape(Split_Value[7])
    	if (Tbl_Status) Tbl_Status.innerText=unescape(Split_Value[3])
   		if (Tbl_Prior) Tbl_Prior.innerText=unescape(Split_Value[2])
   		if (Tbl_No) Tbl_No.innerText=unescape(Split_Value[4])
  		if (Tbl_ComputerIP)Tbl_ComputerIP.innerText=""
   		if (ID) ID.innerText=unescape(Split_Value[8])
		if (Tbl_Dep) Tbl_Dep.innerText=unescape(Split_Value[11])
		if (PatientID) PatientID.value=unescape(Split_Value[12])
		if (EpisodeID) EpisodeID.value=unescape(Split_Value[13])
		if (mradm) mradm.value=unescape(Split_Value[14])
		if (ReloadFlag) ReloadFlag.value="1"
		if (SelectPatRowId) SelectPatRowId.value=unescape(Split_Value[12])
		if (SelectAdmRowId) SelectAdmRowId.value=unescape(Split_Value[13])
		if (ConsultatFlage) ConsultatFlage.innerText=unescape(Split_Value[15])
	
		
		/*
		ReloadFlag
		SelectPatRowId
		SelectAdmRowId
		*/
		AddRowToList(objtbl)
		}
		
		
	} catch(e) {};
}

function AddRowToList(objtbl) {
	var row=objtbl.rows.length;
	var objlastrow=objtbl.rows[row-1];
	//make sure objtbl is the tbody element
	objtbl=tk_getTBody(objlastrow);
	var objnewrow=objlastrow.cloneNode(true);
	var rowitems=objnewrow.all; //IE only
	if (!rowitems) rowitems=objnewrow.getElementsByTagName("*"); //N6
	for (var j=0;j<rowitems.length;j++) {
		if (rowitems[j].id) {
			var Id=rowitems[j].id;
			var arrId=Id.split("z");
			arrId[arrId.length-1]=eval(arrId[arrId.length-1])+1;
			rowitems[j].id=arrId.join("z");
			rowitems[j].name=arrId.join("z");
			rowitems[j].value="";
			rowitems[j].innerText="";
		}
	}
	objnewrow=objtbl.appendChild(objnewrow);
	{if ((objnewrow.rowIndex)%2==0) {objnewrow.className="RowEven";} else {objnewrow.className="RowOdd";}}
}

function CleartTbl()
{
	var objtbl=document.getElementById('tDHCAlloc');
	var rows=objtbl.rows.length;
	var lastrowindex=rows-1;
	for (var j=1;j<lastrowindex;j++) {
		objtbl.deleteRow(1);
	//alert(j)
	}
	var objlastrow=objtbl.rows[1];
	var rowitems=objlastrow.all; //IE only
	if (!rowitems) rowitems=objlastrow.getElementsByTagName("*"); //N6
	for (var j=0;j<rowitems.length;j++) {
		if (rowitems[j].id) {
			var Id=rowitems[j].id;
			var arrId=Id.split("z");
			arrId[arrId.length-1]="1";
			rowitems[j].id=arrId.join("z");
			rowitems[j].name=arrId.join("z");
			rowitems[j].innerText="";
		}
	}

}


function SelectRowHandler() {
    var eSrc=window.event.srcElement;
	if (eSrc.tagName=="IMG") eSrc=window.event.srcElement.parentElement;
	var objtbl=document.getElementById('tDHCAlloc');
	var rows=objtbl.rows.length;
	var lastrowindex=rows - 1;
	var rowObj=getRow(eSrc);
	var selectrow=rowObj.rowIndex;
	if (!selectrow) return;
	if (lastrowindex==selectrow) return;
	if (selectrow !=0) {
		var eSrc1=objtbl.rows[selectrow];
		var RowObj1=getRow(eSrc1);
		var rowitems1=RowObj1.all;
		if (!rowitems1) rowitems1=RowObj1.getElementsByTagName("label");
		for (var j=0;j<rowitems1.length;j++) {
			if (rowitems1[j].id) {
			var Id=rowitems1[j].id;
			var arrId1=Id.split("z");
			var Row1=arrId1[arrId1.length-1];
			}
		}
		CurrentRow=Row1
		//alert(Row1)
		var obj=document.getElementById('L_Doc');
		ClearAllList(obj);

		var ID=document.getElementById("IDz"+Row1);
		var Tbl_Doc=document.getElementById("Tbl_Docz"+Row1);
        var Tbl_Que=document.getElementById("Tbl_Quez"+Row1);
        var Tbl_Status=document.getElementById("Tbl_Statusz"+Row1);
        var PatientID=document.getElementById("PatientIDz"+Row1);
        SelectedPatientID=PatientID.value;
        var EpisodeID=document.getElementById("EpisodeIDz"+Row1);
        var mradm=document.getElementById("mradmz"+Row1);
        var ReloadFlag=document.getElementById("ReloadFlagz"+Row1);
        var SelectPatRowId=document.getElementById("SelectPatRowIdz"+Row1);
        var SelectAdmRowId=document.getElementById("SelectAdmRowIdz"+Row1);
        
        GSelectAdmRowId=SelectAdmRowId.value
		GSelectPatRowId=SelectPatRowId.value
        
        //alert(EpisodeID.value+","+PatientID.value+","+mradm.value)
		if (ID) QueID=ID.value;
		if (Tbl_Doc) QueDoc=Tbl_Doc.innerText
		if (Tbl_Que) SelRoom=Tbl_Que.innerText
		if (Tbl_Status) PerState=Tbl_Status.innerText
		if (QueID!=0) {
			var GetDetail=document.getElementById('ParSelDoc');
			if (GetDetail) {var encmeth=GetDetail.value;} else {var encmeth=''};
			if (cspRunServerMethod(encmeth,'SelDocEvent','',QueID)=='0') {
		//obj.className='';
		}
		}
	}
}


function SelDocEvent(value) {
	try {
		//alert(value)
		
		var valueAry=value.split("^");
		//var arytxt=new Array();
		//var aryval=new Array();
		var obj=document.getElementById('L_Doc');

		var lstlen=obj.length;
		obj.options[lstlen] = new Option(valueAry[1],valueAry[0]); 
		lstlen++;		

	} catch(e) {};
}

function ClearAllList(obj) {
	if (obj.options.length>0) {
	for (var i=obj.options.length-1; i>=0; i--) obj.options[i] = null;
	}
}
function CallClick() {
	if (CurrentRow==0){
	}else{
		var Row1=CurrentRow;
		var ID=document.getElementById("IDz"+Row1);
		var Tbl_Doc=document.getElementById("Tbl_Docz"+Row1);
        var Tbl_Que=document.getElementById("Tbl_Quez"+Row1);
        var Tbl_PatNo=document.getElementById("Tbl_IDz"+Row1);
        var Tbl_RegDoc=document.getElementById("Tbl_CarePrvz"+Row1);
        var Tbl_RegDoc=document.getElementById("Tbl_CarePrvz"+Row1);
        var Tbl_SeqNo=document.getElementById("Tbl_Noz"+Row1);
        var Tbl_Name=document.getElementById("Tbl_Namez"+Row1);
        var Tbl_Status=document.getElementById("Tbl_Statusz"+Row1);
        var Tbl_Dep=document.getElementById("Tbl_Depz"+Row1);
        var AdmDate=document.getElementById("Today").value; 

		if (ID) QueID=ID.value;
		if (Tbl_Doc) var QueDoctor=Tbl_Doc.innerText;
		if (Tbl_Que) var Room=Tbl_Que.innerText;
		if (Tbl_PatNo) var PatNo=Tbl_PatNo.innerText;
		if (Tbl_RegDoc) var RegDoctor=Tbl_RegDoc.innerText;
		if (Tbl_SeqNo) var SeqNo=Tbl_SeqNo.innerText;
		if (Tbl_Name) var PatName=Tbl_Name.innerText;
		if (Tbl_Status) var Status=Tbl_Status.innerText;
		if (Tbl_Dep) var AdmDep=Tbl_Dep.innerText;
		if (Room==""){
			var tmp=document.getElementById('L_Room');
			if (tmp.selectedIndex!=-1) {
				var selItem=tmp.options[tmp.selectedIndex];	
				if (selItem) {Room=selItem.text}
			}
		}
		var PatString=QueID+','+PatNo+','+SeqNo+','+PatName+','+Room+','+RegDoctor+','+AdmDep+","+AdmDate+","+QueDoctor+","+Status;
		//alert(PatString)
		if (QueID!=0) {
			var FilePath=document.getElementById('FilePath').value;
			//alert(FilePath);
			InsertDisplay(FilePath,PatString);
		}
	}
}
///update by guorongyong 20100813
///desc:门诊会诊号直接在护士分诊的时候插入队列表,现在只徐州中心医院走此流程
function ConsultationClick(){
	if (CurrentRow==0){
		alert("请选择行!");
		return;
	}
  if (QueID==0) {
		//请选择病人
    alert(t['7'])    
	  return
	}


	var EpisodeID="",RoomID="",SeqNo="";
	var Tbl_EpisodeID=document.getElementById("EpisodeIDz"+CurrentRow);
  var Tbl_RoomID=document.getElementById("Tbl_RoomIDz"+CurrentRow);
  var Tbl_SeqNo=document.getElementById("Tbl_Noz"+CurrentRow);
  if (Tbl_EpisodeID)EpisodeID=Tbl_EpisodeID.value;
  if (Tbl_RoomID)RoomID=Tbl_RoomID.value;
  if (Tbl_SeqNo)SeqNo=Tbl_SeqNo.innerText;
  var myobj=document.getElementById('Zone');
  var RoomID=myobj.value
  var Para=EpisodeID+"^"+RoomID+"^"+SeqNo;
  var lnk = "websys.default.csp?WEBSYS.TCOMPONENT=DHCDoc.Consultation&Para="+Para;
	win=open(lnk,"DHCAlloc","status=1,scrollbars=1,top=100,left=100,width=860,height=520");
	
}
function InsertDisplay(filepath,txt) {
    //alert(filepath);
	//var PatString=QueID+','+PatNo+','+SeqNo+','+PatName+','+Room+','+RegDoctor+','+AdmDep+","+AdmDate+","+QueDoctor+","+Status;
    if (filepath=="") {
	    alert(t['NoFilePath']);
	    return;
    }
    //filepath="192.168.10.199"
    str=txt.split(',');
    var QueRowid=str[0];
    var PatNo=str[1];
    var SeqNo=str[2];
    var PatName=str[3];
    var Room=str[4];
    var RegDoctor=str[5];
    var AdmDep=str[6];
    var AdmDate=str[7];
    var CallDoctor=str[8];
    var Status=str[9];
    var Area="";
    var ReAdm="0";
    var TempArr =new Array();
    var RoomArr=new Array();
	if (Status=="复诊") {ReAdm="1";}
	if (QueRowid=="") {QueRowid="1";}
    RoomArr=Room.split("-");
    if (RoomArr.length==2) {
	    Area=RoomArr[0];
	    Room=RoomArr[1];
	}
	var RegType="0";
	if ((RegDoctor.indexOf("普通")>0)||(RegDoctor.indexOf("普老")>0)){
		RegType="0"
	}else{RegType="1"}
	//rowid,登记号?排队号,姓名,科室,大夫,号别,标志为(1:专家 0:其他),区域,诊室,复诊标志
    var context=QueRowid+"-"+PatNo+"-"+SeqNo+"-"+PatName+"-"+AdmDep+"-"+CallDoctor+"-"+RegDoctor+"-"+RegType+"-"+Area+"-"+Room+"-"+ReAdm;

	var RoomCode=document.getElementById('RoomCode').value;
	var FileStr=filepath+'\\'+RoomCode+'.TXT';
  	var PatString="'"+context+"',"+"1"+","+"0"+","+AdmDate+","+AdmDate;
  	//alert(FileStr)
	try
	{
  		fw=fs.CreateTextFile(FileStr, true);
  		fw.WriteLine(PatString);
  		fw.Close();
	}catch(e)
	{
  		alert("生成叫号文件失败");
  	}
	return;
  	var sql="INSERT INTO tab_jiaohao(context,zs,bz,updatetime,createtime) VALUES ('"+context+"','"+"1"+"','"+"0"+"','"+AdmDate+"','"+AdmDate+"')"
	
	try{
		var SetSessionDataMethod=document.getElementById('SetSessionData');
		if (SetSessionDataMethod) {var encmeth=SetSessionDataMethod.value} else {var encmeth=''};
		var err=cspRunServerMethod(encmeth,filepath,sql)
	}
	catch(e){alert(e.message)}
	return;
	
	try{
		var ip=filepath;
		var usercode="cydf"
		var userpass="cydf"
		var objdbConn = new ActiveXObject("ADODB.Connection");
		//var strdsn = "Driver={SQL Server};SERVER="+ip+";UID="+usercode+";PWD="+userpass+";DATABASE=MZHisTransDB";
        //var strdsn="dsn=AHHF;uid=cydf;pwd=cydf;DATABASE=ahsl_jiaohao";
		var strdsn = "Driver={MySQL ODBC 3.51 Driver};SERVER="+ip+";UID="+usercode+";PWD="+userpass+";DATABASE=ahsl_jiaohao";
	    objdbConn.Open(strdsn);
	    /*
	    var sql="Select Max(sn)  from tab_jiaohao";
		var rs=objdbConn.Execute(sql);
		var Maxid=rs.Fields(0);
		Maxid=Maxid+1;
		rs.Close();
        rs = null;
		alert(context);
		*/
        //sn ,context,zs, bz , updatetime, datetime, createtime                     datetime,   
  		//alert(sql);
  		objdbConn.Execute(sql);
		objdbConn.Close();
		//objdbConn=null;
	}
	catch(e){alert(e.message)}

}
///update by guorongyong 20100812
///common
function ClearChecked(){
	var inputs=document.getElementsByTagName("input");
	for (var i=0;i<inputs.length;i++){ 
		if (inputs[i].type=="checkbox") inputs[i].checked=false;
	}
}

document.body.onload = BodyLoadHandler;

function B_ChangeDepclick(){
		 if (QueID==0) {
	        alert(t['7'])    
		    return
		}
		
		var GetDetail=document.getElementById('GetMethodChangeMark');
		if (GetDetail) {var encmeth=GetDetail.value} else {var encmeth=''};
		var RetCode=cspRunServerMethod(encmeth,QueID)
		if (RetCode=="A") {
	        alert(t['16'])    
		    return 
		}
		if (RetCode=="D") {
	        alert(t['23'])    
		    //return
		}
		if (RetCode=="E") {
	        alert(t['NeedCheckin']);    
		    	return;
		}
		if (RetCode=="F") {
	        alert(t['Canceled'+" "+t['CannotChangeDep']]);    
		    	return;
		}
		if ((RetCode=="C")||(RetCode=="D")) {
	      if (confirm(t['17'])) {
		        var GetDetail=document.getElementById('GetMethodResume');
				if (GetDetail) {var encmeth=GetDetail.value} else {var encmeth=''};
				var RetCode=cspRunServerMethod(encmeth,QueID)
				if(RetCode==0){
					alert(t["20"])
					FindPatQueue("","")
				}else{
					alert(t["21"])
				}
		 
	      }
		    return
		}
		
		//Clearclick()
		var lnk = "websys.default.csp?WEBSYS.TCOMPONENT=DHCOPQueueChangeDep&QueID="+QueID;
			win=open(lnk,"DHCOPQueueChangeDep","top=240,left=300,width=560,height=308,status=Yes");
		//alert(QueID)
}

function B_SumOnclick(){
	var T_ID=document.getElementById('T_ID').value
	if(T_ID==""){
		alert("登记号为空")	
	}else{
		var PerStateFlag=tkMakeServerCall("web.DHCAlloc","GetDHCPerStateFlag",T_ID)
		if(PerStateFlag!=""){
			alert(PerStateFlag)	
			return ;
		}
		
		var PatSum=tkMakeServerCall("web.DHCAlloc","GetPatSum",T_ID)
		var PatSumArr=PatSum.split("^")
		if((PatSumArr[0]=="-1")||(PatSumArr[0]=="")){
			//alert("该患者没有复诊，或报到")
			alert("没有输入登记号")
			return ;
		}
		var Str=""
		if(PatSumArr.length<1){
			alert("没有数据")
			return ;	
		}
		 
		for(i=0;i<PatSumArr.length;i++){
			var PatSumStr=PatSumArr[i].split("$")
			var DocName=PatSumStr[0]
			var QuePatNo=PatSumStr[1]
			var Sum=PatSumStr[2]
			var FZSum=PatSumStr[3]
			var DHSum=PatSumStr[4]
			if(Str==""){
				Str=DocName+"， 前面有 "+Sum+" 人。其中复诊为 "+FZSum+" 人，等待为 "+DHSum+" 人"
			}else{
				Str=Str+"\n"+DocName+"， 前面有"+Sum+"人。其中复诊为"+FZSum+"人，等待为 "+DHSum+" 人"
			}
		}
		if(Str!=""){
			alert(Str)	
		}else{
			alert("没有查询到数据")	
		}
		
	}
}