doc.patientinfoupdate.hui.csp
doc.patientinfoupdateforbiobank.hui.csp
doc.patientinfoupdatebiobank.hui.csp
doc.patlistquerybiobank.hui.csp

s IPAddress=##class(%SYSTEM.Process).ClientIPAddress()    ;获取IP地址

s %session.Data("LOGON.USERID")=UserID
s %session.Data("LOGON.CTLOCID")=LocID
s %session.Data("LOGON.GROUPID")=GroupID
s %session.Data("LOGON.HOSPID")=HospID
s %session.Data("LOGON.WARDID")=WARDID
s %session.Data("LOGON.LANGID")=LANGID
s %session.Data("LOGON.SSUSERLOGINID")=SSUSERLOGINID