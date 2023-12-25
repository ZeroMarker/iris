USER > set company = ##class(Demo.Company).%New()
USER > set company.Name = “InterSystems”
USER > set company.YearsActive = 40
USER > set company.Industry = “Technology”
USER > do company.PrintCompany()
USER > write ##class(Demo.Company).QuarterlyProfits(34, 5)
USER > do $system.OBJ.Dump(company)
USER > zwrite company
USER > set status = company.%Save()
USER > write company.%Id()
USER > kill company
USER > set company = ##class(Demo.Company).%OpenId(1)
USER > do ##class(Demo.Company).%DeleteId(1)
USER > do ##class(Demo.Company).%DeleteExtent() // delete all

DHC-APP > zw ^User.StudentD(1)
^User.DHCStudentSFCD(1)=$lb("","1","张",,66475,1)

DHC-APP > zw ^User.StudentD
^User.DHCStudentSFCD=1
^User.DHCStudentSFCD(1)=$lb("","1","张",,66475,1)

DHC-APP > d ##class(User.DHCStudentSFC).%BuildIndices()

DHC-APP > zw ^CT("ADD",0,"Code","110101007")  ///index CTADDCode 110101007
^CT("ADD",0,"Code",110101007,9)=""  ///CTADDRowID 9

DHC-APP > s CTADDRowID = $Order(^CT("ADD",0,"Code",110101007,0))
DHC-APP > w
CTADDRowID=9

DHC-APP > set obj=##class(User.Student).%New()    
DHC-APP > w obj
1@User.Student
DHC-APP > zw obj
obj=<OBJECT REFERENCE>[1@User.Student]
+----------------- general information ---------------
|      oref value: 1
|      class name: User.Student
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

set sqlquery = "SELECT * FROM ICO.inventory ORDER BY vendor_id"
set rs = ##class(%SQL.Statement).%ExecDirect(,sqlquery)
while rs.%Next() { Write !, rs.%Get("vendor_id") }