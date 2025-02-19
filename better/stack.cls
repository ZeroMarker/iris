Class src.stack Extends %RegisteredObject
{
ClassMethod Stack()
{
	s PLACE="",MCODE=""
	kill tmpStackAry
	s levelDeep=$STACK(-1)
	FOR loop=0:1:levelDeep { 
		s tp=$STACK(loop)
		continue:(tp="")||(tp="XECUTE")
		s cp=$STACK(loop,"PLACE")
		continue:(cp="")||(cp["%SYS")||(cp["%CSP")
		s stackCls=$p($p(cp,"^",2)," ",1)
		continue:$p($p(cp,"^",2)," ",1)=$zn
		;s cs=$STACK(loop,"MCODE")
		i stackCls'="" {
			continue:$d(tmpStackAry(stackCls))
			s tmpStackAry(stackCls)=""
		}
		s ^tmpgry("stack",+$h,$i(^tmpgry))=tp_","_cp
    }
	
}
}