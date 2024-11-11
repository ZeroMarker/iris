Class better.string Extends %RegisteredObject
{
ClassMethod StringOut() {
    s list = $lb(
        1, 2, 43, 4
    )
    s list = $lts(list, "^")
    q list
} 
}