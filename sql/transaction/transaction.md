variable & process global don't support transaction

multiple table
use transaction

tstart
tcommit
trollback

s sc=obj.%Save()
$$$ISOK(sc)
$$$ISERR(sc)

sc=1