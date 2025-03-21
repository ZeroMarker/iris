function AllergyHandler() {
    var url = "websys.default.csp?WEBSYS.TCOMPONENT=PAAllergy.ListEMR&EpisodeID=" + EpisodeID + "&mradm=" + mradm + "&PatientID=" + GlobalObj.PatientID;
    window.open(url, "DHCDocPatGuideDocumentsPrtPrintAll", "top=0,left=0,width=1,height=1,alwaysLowered=yes");
}