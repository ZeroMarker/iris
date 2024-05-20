## 读卡挂号建卡不重复读卡
```js

// s PatientNoReg=%request.Get("PatientNoReg")
function BRegExpClickHandle(PatientNo){
	if (typeof PatientNo ==undefined){PatientNo="";}
	if ((PatientNo=="undefined")||(PatientNo==undefined)) {PatientNo="";}
	try {
		$.parseXML(PatientNo);
		var src="reg.cardreg.hui.csp?CardInfoRead="+PatientNo;	// CardReadInfo
	}
	catch(e) {
		var src="reg.cardreg.hui.csp?PatientNoReg="+PatientNo;
	}
	var $code ="<iframe width='100%' height='100%' scrolling='auto' frameborder='0' src='"+src+"'></iframe>" ;
	createModalDialog("CardReg","建卡", PageLogicObj.dw+160, PageLogicObj.dh,"icon-w-edit","",$code,"");
}
function BReadIDCard_click(){
	//var CredNoRes = PublicReadPersonHX.ReadPersonID()
	var CredNoRes = PublicReadPerson.ReadPersonInfo()
	console.log(CredNoRes)
	var CredNoResult = CredNoRes.rtn.split("^")
	if (CredNoResult[0]==0) {
		var cardinfoxml =  CredNoResult[1]
		var CredNo = cardinfoxml.substring(cardinfoxml.indexOf("<CredNo>")+8,cardinfoxml.indexOf("</CredNo>"))
	    $.cm({
		    ClassName : "web.DHCBL.Patient.DHCPatient",
		    QueryName : "SelectByPAPERID",
		    SPAPERID:CredNo, SPAPERName:"", SPAPMINo:"", CardNo:"",
		    OutMedicareNo:"", 
		    InMedicareNo:"", 
		    EmMedicare:"", 
		},function(res){
			if (res.total>0){
				$("#PatientNo").val(res.rows[0].TPAPMINo)
				CheckPatientNo()
			}else{			
				$.messager.confirm("提示", "没有找到对应的卡记录，是否需要为患者新建卡？", function (r) {
					if (r) {
						// BRegExpClickHandle();
						// 处理读卡信息
						var xmlDoc = $.parseXML(cardinfoxml);
  						var $xml = $(xmlDoc);

  						var $nodeToDelete = $xml.find("PhotoInfo");

 						if ($nodeToDelete.length > 0) {
    						$nodeToDelete.remove();

    						var updatedXmlString = new XMLSerializer().serializeToString(xmlDoc);
    						console.log(updatedXmlString);
  						} else {
    						console.log("节点不存在");
  						}
  						cardinfoxml = updatedXmlString;
						BRegExpClickHandle(cardinfoxml);
					} else {
						$("#CardNo").focus();
					}
				});
			}
		})
	}

}
```