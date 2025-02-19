## 联系电话不必填
//必填项目验证

var Patdetail=value.split("^");
var NeedAddPatInfo=Patdetail[32];
var CredType=Patdetail[24];
if (CredType == "三无人员") {
	if (NeedAddPatInfo.includes("联系电话")) {
		var info = NeedAddPatInfo.split("、");
		info = info.filter(item => item != "联系电话");
		NeedAddPatInfo = info.join("、");
	}
}