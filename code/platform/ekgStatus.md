select OEORI_ItemStat_DR->ostat_desc,*
from OE_OrdItem
WHERE OEORI_RowId = "2||304";

SELECT *
FROM Ens_InterfaceMethod
WHERE method_code like "%UpdateSystemStatus%";
SELECT ES_PreStatusCode, ES_StatusCode,*
FROM SqlUser.Ens_Statuslog
where ES_ExamID like "%EKG1041%";

SELECT *
from Ens_StatusCode;

SELECT *
FROM Ens_Status
WHERE ES_ExamID like "EKG1041%";