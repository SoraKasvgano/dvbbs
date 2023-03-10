<%
Const BASE_64_MAP_INIT = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
' zero based arrays
Dim Base64EncMap(63)
Dim Base64DecMap(127)

'must be called before using anything else
Public Sub initCodecs()
	' setup base 64
	Dim max, idx
	max = len(BASE_64_MAP_INIT)
	For idx = 0 To max - 1
		' one based string
		Base64EncMap(idx) = mid(BASE_64_MAP_INIT, idx + 1, 1)
	Next
	For idx = 0 To max - 1
		Base64DecMap(ASC(Base64EncMap(idx))) = idx
	Next
End Sub

Call initCodecs
%>
<%

' encode base 64 encoded string
Public Function base64Encode(plain)
	If len(plain) = 0 Then
		base64Encode = ""
		Exit Function
	End If
	Dim ret, ndx, by3, first, second, third
	by3 = (len(plain) \ 3) * 3
	ndx = 1
	Do While ndx <= by3
		first  = ascw(mid(plain, ndx+0, 1))
		second = ascw(mid(plain, ndx+1, 1))
		third  = ascw(mid(plain, ndx+2, 1))
		ret = ret & Base64EncMap(  (first \ 4) And 63 )
		ret = ret & Base64EncMap( ((first * 16) And 48) + ((second \ 16) And 15 ) )
		ret = ret & Base64EncMap( ((second * 4) And 60) + ((third \ 64) And 3 ) )
		ret = ret & Base64EncMap( third And 63)
		ndx = ndx + 3
	Loop
	' check for stragglers
	If by3 < len(plain) Then
		first  = ascw(mid(plain, ndx+0, 1))
		ret = ret & Base64EncMap(  (first \ 4) And 63 )
		If (len(plain) Mod 3 ) = 2 Then
			second = ascw(mid(plain, ndx+1, 1))
			ret = ret & Base64EncMap( ((first * 16) And 48) + ((second \ 16) And 15 ) )
			ret = ret & Base64EncMap( ((second * 4) And 60) )
		Else
			ret = ret & Base64EncMap( (first * 16) And 48)
			ret = ret & "="
		End If
		ret = ret & "="
	End If
	base64Encode = ret
End Function

' decode base 64 encoded string
Public Function base64Decode(scrambled)
	If Len(scrambled) = 0 Then
		base64Decode = ""
		Exit Function
	End If
	' ignore padding
	Dim realLen
	realLen = len(scrambled)
	Do While mid(scrambled, realLen, 1) = "="
		realLen = realLen - 1
	Loop
	Dim ret, ndx, by4, first, Second, third, fourth
	ret = ""
	by4 = (realLen \ 4) * 4
	ndx = 1
	Do While ndx <= by4
		first  = Base64DecMap(Ascw(Mid(scrambled, ndx+0, 1)))
		Second = Base64DecMap(Ascw(Mid(scrambled, ndx+1, 1)))
		third  = Base64DecMap(Ascw(Mid(scrambled, ndx+2, 1)))
		fourth = Base64DecMap(Ascw(Mid(scrambled, ndx+3, 1)))
		ret = ret & Chrw( ((first * 4) And 255) +   ((Second \ 16) And 3))
		ret = ret & Chrw( ((Second * 16) And 255) + ((third \ 4) And 15) )
		ret = ret & Chrw( ((third * 64) And 255) +  (fourth And 63) )
		ndx = ndx + 4
	Loop
	' check for stragglers, will be 2 or 3 characters
	If ndx < realLen Then
		first  = Base64DecMap(Ascw(Mid(scrambled, ndx+0, 1)))
		Second = Base64DecMap(Ascw(Mid(scrambled, ndx+1, 1)))
		ret = ret & Chrw( ((first * 4) And 255) +   ((Second \ 16) And 3))
		If realLen Mod 4 = 3 then
			third = Base64DecMap(Ascw(Mid(scrambled,ndx+2,1)))
			ret = ret & Chrw( ((Second * 16) And 255) + ((third \ 4) And 15) )
		End If
	End If
	base64Decode = ret
End Function

Function AuthCode(str, operation, key)
	If key <> "" Then
		key = md5(key, 32)
	Else 
		key = md5("dvbbs", 32)
	End If 

	Dim key_length
	key_length = Len(key)

	If operation = "DECODE" Then 
		str = Base64decode(str)
	Else 
		str = Mid(md5(str & key, 32), 1, 8) & str
	End If 

	Dim string_length, i, k
	string_length = Len(str)

	Dim rndKey(256),Box(256),Result
	result = ""

	'??????????
	'i??key_length????????????????????ASCII
	'????????????rndkey????????????key??i
	'?? i ??????box????????????key??i
	For i = 0 To 255 Step 1
		rndKey(i) = Asc(Mid(key, (i Mod key_length) + 1, 1))
		box(i) = i
	Next 

	'??????????
	'j + key=i??box???? + key=i??rndkey????????????256???????????????? j
	'key=i??box?????????? tmp
	'key=j??box?????????? key=i??box????
	'tmp ?????? key=j??box????
	'????????????????????????????
	Dim j, tmp
	j = 0
	For i = 0 To 255 Step 1
		j = (j + Box(i) + rndKey(i)) Mod 256
		tmp = Box(i)
		Box(i) = Box(j)
		box(j) = tmp
	Next 

	'??????????ord($string[$i]) ^ ($box[($box[$a] + $box[$j]) % 256])??
	'^ ????????key=i??????string????ord
	' ^ ?????? $box[$a] + $box[$j] ??????????256????????????????????????????box??key
	' ^ ????????????????????
	'??????????$result .= chr(
	'??????????chr??????????????result????
	Dim a
	a = 0
	j = 0
	For i = 0 To string_length - 1 Step 1
		a = (a + 1) Mod 256
		j = (j + box(a)) Mod 256
		'response.write(a & "==&gt;" & j & "<br />")
		tmp = box(a)
		box(a) = box(j)
		box(j) = tmp
		result = result & Chrw(Ascw(Mid(str, i + 1, 1)) Xor (box((box(a) + box(j)) Mod 256)))
	Next 

	string_length = Len(result)
	'response.write(Asc(Chr(129)))
	For i = 0 To string_length - 1 Step 1
		'response.write(Ascw(Mid(result, i+1, 1)) & " ")
	Next
	'response.write(Base64encode(result))

	'DECODE????????????
	'???? result????8?????? ???? result??8??????????????????????key??MD5??????????8???????????? result??8??????????????????
	'???? ??????????
	'ENCODE?????? result base64???????????????? = ?????? ??????
	If "DECODE" = operation Then
		If Mid(result, 1, 8) = Mid(md5(Mid(result, 9) & key, 32), 1, 8) Then 
			AuthCode = Mid(result, 9)
			Exit Function 
		Else
			AuthCode = ""
			Exit Function 
		End If 
	Else 
		AuthCode = Replace(Base64encode(result), "=", "")
		Exit Function 
	End If 
End Function

%>