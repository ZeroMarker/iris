SELECT * FROM 
MR_Diagnos;
SELECT *
from MR_DiagType;
SELECT *
from MRC_DiagnosType;
<!--dhcdoc.deldiaglist.csp 诊断删除记录-->
url:$URL+"?ClassName=web.DHCDocDiagnosEntryV8&QueryName=GetDelDiagList&mradm="+mradm, 
//诊断类型
s DiagTypeDr=$g(^MRDelLog(mradm,"Sub",sub,"Data","TYP",1))
s DiagType=##class(User.MRCDiagnosType).%OpenId(DiagTypeDr).DTYPDesc