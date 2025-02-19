## 登记号长度
系统计数类型
var len = tkMakeServerCall("web.DHCCLCom","GetPatConfig");
len = len.split("^")[0];