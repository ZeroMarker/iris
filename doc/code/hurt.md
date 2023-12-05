```js
var lnk="dhcdoccheckpoison.csp?PatID="+PatientID+"&EpisodeID="+EpisodeID;
var retval=window.showModalDialog(lnk,"","dialogwidth:575px;dialogheight:180px;status:no;center:1;resizable:no");
if(retval){
	//web.DHCDocCheckPoison.UpdateAgencyInfo
	var encmeth=GlobalObj.UpdateAgencyInfoMethod;
	if (encmeth!=""){
		var rtn=cspRunServerMethod(encmeth,PatientID,retval,EpisodeID);
		if(rtn=="-100"){
			dhcsys_alert(ItemDesc+t['POISONSAVE_FAILED'])
			return false;   
		}
	}               
}
```