```objectscript
; cursor
    &sql(DECLARE mycursor CURSOR FOR
		select OEORI_OEORD_ParRef ,OEORI_Childsub into :Par, :Sub 
        from SQLUser.OE_OrdItem 
		where 
	)
	&sql(OPEN mycursor)
	
	for {
		&sql(FETCH mycursor)
    	QUIT:SQLCODE'=0
    	
	}
	&sql(CLOSE mycursor)
```

```objectscript
; array
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
```

```objectscript
; plist
&sql(
    SELECT * INTO :PLIST() FROM Course
    WHERE Crs_Id = :CrsId
)
s count=$o(PLIST(""),-1)
for i=1:1:count {
    w PLIST(i)
}
```


