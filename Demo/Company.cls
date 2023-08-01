Class Demo.Company Extends (%Persistent, %Populate) [ SqlTableName = DHC_Country ]
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
<DataLocation>^Demo.CompanyD</DataLocation>
<DefaultData>CompanyDefaultData</DefaultData>
<IdLocation>^Demo.CompanyD</IdLocation>
<IndexLocation>^Demo.CompanyI</IndexLocation>
<StreamLocation>^Demo.CompanyS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
