```objectscript
&sql(SELECT PAADM_RowID INTO :myvar FROM SQLUser.PA_Adm WHERE PAADM_ADMNo = :AdmNo)
IF SQLCODE<0 {QUIT "SQLCODE error "_SQLCODE_" "_%msg  }
ELSEIF SQLCODE=100 {QUIT "Query returns no results"}
s PAADMRowID=myvar
```

```objectscript
Set ADMNo = ... ; -- Assign a value to ADMNo parameter

&sql(DECLARE mycursor CURSOR FOR
      SELECT PAADM_RowID FROM PA_Adm WHERE PAADM_ADMNo = :ADMNo)

&sql(OPEN mycursor)

While mycursor.%Next() {
    Set PAADMRowID = mycursor.PAADM_RowID
    ; -- Process each PAADMRowID here
}

&sql(CLOSE mycursor)
```


```objectscript
&sql(
    SELECT * INTO :PLIST() FROM Course
    WHERE Crs_Id = :CrsId
)
s count=$o(PLIST(""),-1)
for i=1:1:count {
    w PLIST(i)
}
```

SQLCODE
0   successful
100 failed
%ROWID
%msg

## Transaction
multiple table
use transaction
