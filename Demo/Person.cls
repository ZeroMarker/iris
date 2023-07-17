Class Demo.Person Extends (%Persistent, %Library.Populate)
{

// a person's name

Property Name As %String [ Required ];

// phone number

Property Phone As %String;

// age

Property Age As %Integer;

/// sum of two integer
ClassMethod Sum(A As %Integer = 0, B As %Integer = 0) As %Integer
{
    Set result = A + B
    Return result
}

// instance method, print

Method Print() As %Status
{
    write !, "This prerson is named ", ..Name, "."
    write !, ..Name, "'s phone number is ", ..Phone, "."
    write !, ..Name, "'s age is ", ..Age, "."
}

/// Planet
Parameter PLANET = "Earth";

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Phone</Value>
</Value>
<Value name="4">
<Value>Age</Value>
</Value>
</Data>
<DataLocation>^Demo.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^Demo.PersonD</IdLocation>
<IndexLocation>^Demo.PersonI</IndexLocation>
<StreamLocation>^Demo.PersonS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}
