## 显示挂号职称
OPAdm/ScheduleAdjust.hui.js

//InitSingleCombo(id,valueField,textField,ClassName,Query,exp,multipleField)
//InitSingleCombo('DocSessionNew','ID','Desc','RBCSessionTypeQuery',false,"web.DHCBL.BaseReg.BaseDataQuery");
InitSingleCombo('DocSessionNew','ID','Desc','web.DHCBL.BaseReg.BaseDataQuery','RBCSessionTypeQuery',"&Arg1="+HospitalDr+"&ArgCnt=1");
// d ##class(%ResultSet).RunQuery("web.DHCBL.BaseReg.BaseDataQuery","RBCSessionTypeQuery",2)