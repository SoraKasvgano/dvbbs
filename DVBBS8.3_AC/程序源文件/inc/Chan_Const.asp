<%
Function Get_ChallengeWord()
	'??ս??????
	Dim MaxUserID,MaxLength
	Dim rs
	MaxLength=12
	set rs=Dvbbs.Execute("select Max(userid) from [Dv_user]")
	MaxUserID=rs(0)
	set rs=nothing

	Dim num1,rndnum
	Randomize
	Do While Len(rndnum)<4
		num1=CStr(Chr((57-48)*rnd+48))
		rndnum=rndnum&num1
	loop
	MaxUserID=rndnum & MaxUserID
	MaxLength=MaxLength-len(MaxUserID)

	select case MaxLength
	case 7
		MaxUserID="0000000" & MaxUserID
	case 6
		MaxUserID="000000" & MaxUserID
	case 5
		MaxUserID="00000" & MaxUserID
	case 4
		MaxUserID="0000" & MaxUserID
	case 3
		MaxUserID="000" & MaxUserID
	case 2
		MaxUserID="00" & MaxUserID
	case 1
		MaxUserID="0" & MaxUserID
	case 0
		MaxUserID=MaxUserID
	end select

	Session("challengeWord")="dv" & MaxUserID

	Session("challengeWord_key")=md5(Session("challengeWord") & ":" & Dvbbs.CacheData(21,0),32)

	Get_ChallengeWord=Session("challengeWord")

End Function

Function Emp_ChallengeWord()

	Session("challengeWord")=""
	Session("challengeWord_key")=""

End Function
%>