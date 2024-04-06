var MedRecordPanel=(function(){
	function Init(){
		LoadPatClinicalRec()
	}
	function LoadPatClinicalRec(){
		runClassMethod("web.DHCAppPisMasterQuery","GetPatClinicalRec",{"EpisodeID":EpisodeID},function(jsonString){

			if (jsonString != null){
				var jsonObjArr = jsonString;
			
				$("#MedRecord").val( jsonObjArr.arExaReqSym +""+ jsonObjArr.arExaReqHis +""+ jsonObjArr.arExaReqSig);  /// 主诉+现病史+体征
				
			}
		},'json',false)
	}
	function OtherInfo(){
		return ""
	}
	function PrintInfo(){
		var rtnObj = {}	
		var MedRecord=$("#MedRecord").val()
		MedRecord = MedRecord.replace(/[\r\n]+/g, " ");
		var Stringlength=MedRecord.length
		
		var Number=0,StartLeng=0,MaxLength=40,Listrecord=""
		for (var j=0; j <= MedRecord.length; j++){
			if ((j-StartLeng)>=MaxLength){
				Number++
				rtnObj["MedRecord"+Number] = MedRecord.substring(StartLeng,j);
				StartLeng=j
				Listrecord=""
				}else{
				Listrecord = MedRecord.substring(StartLeng,j);
					}
			}
		if (Listrecord!=""){
			Number++
			rtnObj["MedRecord"+Number]=Listrecord}
		return rtnObj
	}
	return {
		"Init":Init,
		"OtherInfo":OtherInfo,
		"PrintInfo":PrintInfo,
	}
	   
})();

