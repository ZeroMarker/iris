- 患者信息添加是否生物标本库信息
- 修改生物标本库信息生成日志
```objectscript
/*
doc.patientinfoupdate.hui.csp
doc.patientinfoupdateforbiobank.hui.csp
doc.patientinfoupdatebiobank.hui.csp
doc.patlistquerybiobank.hui.csp
*/


s IPAddress=##class(%SYSTEM.Process).ClientIPAddress()    ;获取IP地址
s:$d(%session) IPAddress=$p(##class(User.DHCClientLogin).GetInfo(),"^",1) //$Get(%session.Data("REMOTE_ADDR"))

s %session.Data("LOGON.USERID")=UserID
s %session.Data("LOGON.CTLOCID")=LocID
s %session.Data("LOGON.GROUPID")=GroupID
s %session.Data("LOGON.HOSPID")=HospID
s %session.Data("LOGON.WARDID")=WARDID
s %session.Data("LOGON.LANGID")=LANGID
s %session.Data("LOGON.SSUSERLOGINID")=SSUSERLOGINID
```