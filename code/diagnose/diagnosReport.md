dhcdoc.DHCDocDiagnoEntry.V8.js
function CheckBeforeInsertMRDiag(callBackFun)
if ((MRCIDRowId!="")&&(MRCIDRowId!=null)){
	if (!CheckDiagIsEnabled(MRCIDRowId)) return false;
	var SeriousDisease=cspRunServerMethod(ServerObj.GetSeriousDiseaseByICDMethod,MRCIDRowId);
	if (SeriousDisease=="Y"){
		if (SeriousDiseaseICDStr=="") SeriousDiseaseICDStr=DiagnosICDDesc;
		else  SeriousDiseaseICDStr=SeriousDiseaseICDStr+","+DiagnosICDDesc;
	}
}
select *
from MRC_ICDDx