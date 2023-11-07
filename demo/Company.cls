Class demo.Company Extends (%Persistent, %Populate) [ SqlTableName = Company ]
{

Property Name As %String [ Required ];

Property YearActived As %Integer;

Property Industry As %String;

Parameter COUNTRY = "USA";

ClassMethod QuarterlyProfits(Earning As %Integer, Expenses As %Integer) As %Integer
{
    set profit = Earning - Expenses
    return profit
}

ClassMethod FindCompanyByName(companyName As %String) As %List
{
    set query = "SELECT ID, Name, YearActived, Industry FROM demo.Company WHERE Name = "_"'"_companyName_"'"
    
    set statement = ##class(%SQL.Statement).%New()
    set status = statement.%Prepare(query)
    
    if $$$ISERR(status) {
        return $$$NULLOREF
    }
    
    set result = statement.%Execute(companyName)
    set companies = ##class(%ListOfObjects).%New()
    
    while (result.%Next()) {
        set company = ##class(demo.Company).%OpenId(result.ID)
        d companies.InsertObject(company)
    }
    
    return companies
}

/// Description
Method PrintCompany() As %Status
{
    write !, "The company is named ", ..Name , "."
    write !, ..Name, " has actived in ", ..Industry, " for ", ..YearActived, " years."
    return $$$OK
}

Storage Default
{
<Data name="CompanyDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>YearActived</Value>
</Value>
<Value name="4">
<Value>Industry</Value>
</Value>
</Data>
<DataLocation>^demo.CompanyD</DataLocation>
<DefaultData>CompanyDefaultData</DefaultData>
<IdLocation>^demo.CompanyD</IdLocation>
<IndexLocation>^demo.CompanyI</IndexLocation>
<StreamLocation>^demo.CompanyS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
