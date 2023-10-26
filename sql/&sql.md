https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=RSQL_declare
   SET name="John Doe",state="##"
   &sql(DECLARE EmpCursor CURSOR FOR 
        SELECT Name, Home_State
        INTO :name,:state FROM Sample.Person
        WHERE Home_State %STARTSWITH 'A'
        FOR READ ONLY)
     WRITE !,"BEFORE: Name=",name," State=",state 
   &sql(OPEN EmpCursor)
      IF SQLCODE<0 {WRITE "SQL Open Cursor Error:",SQLCODE," ",%msg  QUIT}
      NEW %ROWCOUNT,%ROWID
   FOR { &sql(FETCH EmpCursor)
        QUIT:SQLCODE  
        WRITE !,"DURING: Name=",name," State=",state }
   WRITE !,"FETCH status SQLCODE=",SQLCODE
   WRITE !,"Number of rows fetched=",%ROWCOUNT
   &sql(CLOSE EmpCursor)
       IF SQLCODE<0 {WRITE "SQL Close Cursor Error:",SQLCODE," ",%msg  QUIT} 
   WRITE !,"AFTER: Name=",name," State=",state

      NEW SQLCODE,%ROWCOUNT,%ROWID
   SET EmpZipLow="10000"
   SET EmpZipHigh="19999"
    &sql(DECLARE EmpCursor CURSOR FOR
     SELECT Name,Home_Zip
     INTO :name,:zip
     FROM Sample.Employee WHERE Home_Zip BETWEEN :EmpZipLow AND :EmpZipHigh)
   &sql(OPEN EmpCursor)
     IF SQLCODE<0 {WRITE "SQL Open Cursor Error:",SQLCODE," ",%msg  QUIT}
   FOR { &sql(FETCH EmpCursor)
        QUIT:SQLCODE  
        WRITE !,name," ",zip }
  &sql(CLOSE EmpCursor)
    IF SQLCODE<0 {WRITE "SQL Close Cursor Error:",SQLCODE," ",%msg  QUIT}


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
set resultArray = []
&sql(DECLARE myCursor CURSOR FOR
    SELECT Column1, Column2
    FROM YourTable
)

&sql(OPEN myCursor)

while &sql(FETCH myCursor INTO :column1, :column2) {
    set row = {
        "Column1": column1,
        "Column2": column2
    }
    do resultArray.%push(row)
}

&sql(CLOSE myCursor)
&sql(CLOSE myCursor)


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

s flag = "N"
&sql(DECLARE mycursor CURSOR FOR
    select RegfeeLookPrice into RegfeeLookPrice
    from SQLUser.DHCRegistrationFee
    where RegfeeAdmDr in (
        select PAADM_RowID
        from SQLUser.PA_Adm
        where PAADM_PAPMI_DR =:PatientId
    )
)
&sql(OPEN mycursor)

//s RegfeeLookPrice = ""
for {
    &sql(FETCH mycursor)
    QUIT:SQLCODE
    w RegfeeLookPrice
    if RegfeeLookPrice > 0 {
        s flag = "Y"
    }
}
&sql(CLOSE mycursor)
q flag
## Transaction
multiple table
use transaction
