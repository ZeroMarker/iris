WSDL

Class Soap Extend %SOAP
{
Method GetName() As %String [WebMethod]
}

s obj=##class(Soap).%New()
obj.GetName()
