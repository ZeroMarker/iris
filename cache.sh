DHC-APP > zw ^User.DHCStudentSFCD(1)
^User.DHCStudentSFCD(1)=$lb("","1","张",,66475,1)

DHC-APP > zw ^User.DHCStudentSFCD
^User.DHCStudentSFCD=1
^User.DHCStudentSFCD(1)=$lb("","1","张",,66475,1)

DHC-APP > d ##class(User.DHCStudentSFC).%BuildIndices()

DHC-APP > zw ^CT("ADD",0,"Code","110101007")  ///index CTADDCode 110101007
^CT("ADD",0,"Code",110101007,9)=""  ///CTADDRowID 9

DHC-APP > s CTADDRowID = $Order(^CT("ADD",0,"Code",110101007,0))
DHC-APP > w
CTADDRowID=9

DHC-APP > set obj=##class(User.DHCStudentSFC).%New()    
DHC-APP > w obj
1@User.DHCStudentSFC
DHC-APP > zw obj
obj=<OBJECT REFERENCE>[1@User.DHCStudentSFC]
+----------------- general information ---------------
|      oref value: 1
|      class name: User.DHCStudentSFC
| reference count: 2
+----------------- attribute values ------------------
|       %Concurrency = 1  <Set>
|           StActive = ""
|             StCode = ""
|              StDob = ""
|             StName = ""
+----------------- swizzled references ---------------
|          i%StSexDR = ""
|          r%StSexDR = ""
+-----------------------------------------------------
DHC-APP > s obj.StName="刘"  
DHC-APP > d obj.%Save()