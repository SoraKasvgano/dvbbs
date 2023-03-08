<!--#include file="Conn.asp"-->
<!-- #include file="inc/const.asp" -->
<!--#include file="inc/chkinput.asp"-->
<%
Response.CharSet="gb2312"
Response.ContentType="text/html"
Dim XMLDom
Dim CheckType,CheckValue
CheckType = Request("rs")
If Request("rsargs[]")<>"" Then
	CheckValue = Request("rsargs[]")
	CheckValue = Split(CheckValue,",")
Else
	CheckValue = Array()
End If

If CheckType<>"" Then
	Select Case LCase(CheckType)
	Case "checkusername" : CheckUserName()
	Case "checke_mail" : CheckUserEmail()
	'o start 08.1.18
	'Case "checke_regcode" : CheckRegCode()
	Case "checke_dvcode" : CheckDvCode()
	'o end
	End Select
End If
Dvbbs.PageEnd()
Set Dvbbs = Nothing


Function ErrCode(Str)
	ErrCode = "<img src=""skins/Default/note_error.gif"" border=""0""/>&nbsp;<font class=""redfont"">"&Str&"</font>"
End Function

Function SucCode(Str)
	SucCode = "<img src=""skins/Default/note_ok.gif"" border=""0""/>&nbsp;<font class=""bluefont"">"&Str&"</font>"
End Function

Sub LoadRegSetting()
	Dim Node
	Set XMLDom=Dvbbs.CreateXmlDoc("Msxml2.FreeThreadedDOMDocument"& MsxmlVersion)
	If XMLDom.loadxml(Dvbbs.CacheData(27,0)) Then
		If XMLDom.documentElement.nodeName<>"regsetting" Then
			ToDefaultsetting()
		End If
	End If
End Sub

Sub ToDefaultsetting()
	Dim Node
	Set XMLDom=Dvbbs.CreateXmlDoc("Msxml2.FreeThreadedDOMDocument"& MsxmlVersion)
	XMLDom.appendChild(XMLDom.createElement("regsetting"))
	Set Node=XMLDom.documentElement.appendChild(XMLDom.createNode(1,"checkip",""))
	Node.attributes.setNamedItem(XMLDom.createNode(2,"use","")).text="0"
	Node.appendChild(XMLDom.createElement("iplist1"))
	Node.appendChild(XMLDom.createElement("iplist2"))
	XMLDom.documentElement.attributes.setNamedItem(XMLDom.createNode(2,"postipinfo","")).text="0"
	XMLDom.documentElement.attributes.setNamedItem(XMLDom.createNode(2,"checknumeric","")).text="0"
	XMLDom.documentElement.attributes.setNamedItem(XMLDom.createNode(2,"checktime","")).text="0"
	XMLDom.documentElement.attributes.setNamedItem(XMLDom.createNode(2,"usevarform","")).text="0"
	XMLDom.documentElement.attributes.setNamedItem(XMLDom.createNode(2,"checkregcount","")).text="0"
	Dvbbs.Execute("update dv_setup set Forum_Boards='"&Dvbbs.checkstr(XMLDom.XML)&"'")
	Dvbbs.loadSetup()
End Sub

Sub CheckUserName()
	Dim FormValue,TempLateStr
	FormValue = CheckValue(Ubound(CheckValue))

	Dvbbs.LoadTemplates("login")
	LoadRegSetting()
	If FormValue="" Then
		Exit Sub
	Else
		FormValue=Dvbbs.CheckStr(Trim(FormValue))
		If Trim(FormValue) = "" Then
			Response.Write ErrCode(Template.Strings(6))'请输入您的用户名。login
			Exit Sub
		End If

		If strLength(FormValue)>Cint(Dvbbs.Forum_Setting(41)) or strLength(FormValue)<Cint(Dvbbs.Forum_Setting(40)) Then
			TempLateStr=template.Strings(28)
			TempLateStr=Replace(TempLateStr,"{$RegMaxLength}",Dvbbs.Forum_Setting(41))
			TempLateStr=Replace(TempLateStr,"{$RegLimLength}",Dvbbs.Forum_Setting(40))
			Response.Write ErrCode(TempLateStr)
			Exit Sub
		Else
			If XMLDom.documentElement.selectSingleNode("@checknumeric").text = "1" and IsNumeric(FormValue) Then
				Response.Write ErrCode("本论坛不接受全数字的用户名注册.")
				Exit Sub
			End If
		End If

		If Instr(FormValue,"=")>0 or Instr(FormValue,"%")>0 or Instr(FormValue,chr(32))>0 or Instr(FormValue,"?")>0 or Instr(FormValue,"&")>0 or Instr(FormValue,";")>0 or Instr(FormValue,",")>0 or Instr(FormValue,"'")>0 or Instr(FormValue,",")>0 or Instr(FormValue,chr(34))>0 or Instr(FormValue,chr(9))>0 or Instr(FormValue,"")>0 or Instr(FormValue,"$")>0 or Instr(FormValue,"|")>0 Then
			Response.Write ErrCode(Template.Strings(46)) '用户名含有非法字符!
			Exit Sub
		End If

		Dim Rs
		Set Rs = Dvbbs.Execute("Select top 1 UserName From Dv_User Where UserName='"&Dvbbs.Checkstr(FormValue)&"'")
		If Not Rs.Eof And Not Rs.Bof Then
			Response.Write ErrCode(Template.Strings(44)) '对不起，您输入的用户名已经被注册。
			Exit Sub
		Else
		
		End If
		Set Rs = Nothing
		Response.Write SucCode("可以使用!")
	End If
End Sub

Sub CheckUserEmail()
	Dim FormValue,TempLateStr
	FormValue = CheckValue(Ubound(CheckValue))

	Dvbbs.LoadTemplates("login")
	LoadRegSetting()
	If Trim(FormValue) = "" Then
		Response.Write ErrCode(Template.Strings(30))
		Exit Sub
	End If
	If IsValidEmail(Trim(FormValue)) = False then
		Response.Write ErrCode(Template.Strings(30))
		Exit Sub
	End If
	If Cint(Dvbbs.Forum_Setting(24))=1 Then

		Dim Rs
		'Set Rs = Dvbbs.Execute("Select top 1 UserName From Dv_User Where UserEmail='"&Dvbbs.Checkstr(FormValue)&"'")
		Set Rs = Dvbbs.Execute("Select top 1 UserEmail From Dv_User Where UserEmail='"&Dvbbs.Checkstr(Trim(FormValue))&"'")'o 08.01.18
		If Not Rs.Eof And Not Rs.Bof Then
			Response.Write ErrCode(Template.Strings(43))
			Exit Sub
		Else
			Response.Write SucCode("可以使用!")
			Exit Sub
		End If
		Set Rs = Nothing
	End If
	'Response.Write SucCode("可以使用!")
End Sub

Sub CheckDvCode()
	Dim CodeStr
	CodeStr = LCase(Trim(CheckValue(Ubound(CheckValue))))
	If CStr(Session("GetCode"))=CStr(CodeStr) And CodeStr<>""  Then
		Response.Write SucCode("")
	Else
		Response.Write ErrCode("")
	End If
End Sub
%>