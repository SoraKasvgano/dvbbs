<!--#Include File="Dv_ClsMain.asp"-->
<!--#Include File="Dv_Security.asp"-->
<!--#Include File="Dv_Markdown.asp"-->
<%
'=========================================================
' DVBBS 8.3 常量和初始化文件 - 安全加固版
' 修改日期: 2024-06-24
' 改进内容:
' 1. 集成安全函数库
' 2. 集成Markdown支持
' 3. 增强XSS过滤
' 4. 改进输入验证
'=========================================================

Set MyBoardOnline = New Cls_UserOnlne
Dvbbs.GetForum_Setting
Dvbbs.CheckUserLogin

'=========================================================
' 增强的XHTML安全检查函数
'=========================================================
Function checkXHTML(XMLstr)
	' 使用安全类进行检查
	If DvSecurity.ContainsDangerousCode(XMLstr) Then
		checkXHTML = "内容包含不安全的代码，已被系统拦截"
		Exit Function
	End If

	Dim XML, node
	Set xml = Dvbbs.iCreateObject("msxml2.DOMDocument" & MsxmlVersion)

	' 转义&字符以支持XML解析
	If xml.loadxml("<div>" & Replace(XMLstr, "&", "&amp;") & "</div>") Then
		checkXHTML = ""

		' 检查禁止的标签
		Dim dangerousTags, tag
		dangerousTags = Array("link", "iframe", "meta", "script", "object", "embed", "applet", "base", "form", "input", "button")

		For Each tag In dangerousTags
			If xml.documentElement.getElementsByTagName(tag).length > 0 Then
				checkXHTML = "内容包含前台禁止提交的标签 """ & tag & """"
				Exit Function
			End If
		Next

		' 检查href属性中的脚本
		For Each Node in xml.documentElement.selectNodes("//a[@href]")
			Dim hrefValue
			hrefValue = LCase(Node.selectSingleNode("@href").text)
			If InStr(hrefValue, "script:") > 0 Or InStr(hrefValue, "javascript:") > 0 Or InStr(hrefValue, "vbscript:") > 0 Or InStr(hrefValue, "data:") > 0 Then
				checkXHTML = "链接中包含非法的脚本协议"
				Exit For
			End If
		Next

		If checkXHTML <> "" Then Exit Function

		' 检查src属性中的脚本
		For Each Node in xml.documentElement.selectNodes("//*[@src]")
			Dim srcValue
			srcValue = LCase(Node.selectSingleNode("@src").text)
			If InStr(srcValue, "script:") > 0 Or InStr(srcValue, "javascript:") > 0 Or InStr(srcValue, "vbscript:") > 0 Or InStr(srcValue, "data:text/html") > 0 Then
				checkXHTML = "图片/资源地址包含脚本协议"
				Exit For
			End If
		Next

		If checkXHTML <> "" Then Exit Function

		' 检查事件处理器属性
		Dim eventHandlers, handler
		eventHandlers = Array("onclick", "onload", "onerror", "onmouseover", "onmouseout", "onkeydown", "onkeyup", "onfocus", "onblur", "onchange", "onsubmit")

		For Each handler In eventHandlers
			For Each Node in xml.documentElement.selectNodes("//*[@" & handler & "]")
				checkXHTML = "内容包含事件处理器属性 """ & handler & """"
				Exit Function
			Next
		Next
	Else
		' XML解析失败，可能包含格式错误或恶意代码
		checkXHTML = "内容格式不正确，无法通过安全验证"
	End If

	Set xml = Nothing
End Function

'=========================================================
' 安全的用户输入过滤函数
'=========================================================

' 过滤用户标题（防止XSS和SQL注入）
Function FilterTitle(ByVal title)
	If IsNull(title) Or title = "" Then
		FilterTitle = ""
		Exit Function
	End If

	' 长度限制
	If Len(title) > 100 Then
		title = Left(title, 100)
	End If

	' SQL注入防护
	title = DvSecurity.SafeSQL(title)

	' XSS防护
	title = DvSecurity.HTMLEncode(title)

	' 移除特殊字符
	title = Replace(title, Chr(0), "")
	title = Replace(title, vbTab, " ")

	FilterTitle = Trim(title)
End Function

' 过滤用户内容（支持Markdown和UBB）
Function FilterContent(ByVal content, ByVal isMarkdown)
	If IsNull(content) Or content = "" Then
		FilterContent = ""
		Exit Function
	End If

	' 长度限制（根据实际需求调整）
	If Len(content) > 50000 Then
		content = Left(content, 50000)
	End If

	' SQL注入防护
	content = DvSecurity.SafeSQL(content)

	' 如果是Markdown格式，进行Markdown解析和安全过滤
	If isMarkdown = 1 Then
		content = DvMarkdown.Parse(content)
	Else
		' UBB格式，使用原有的checkXHTML检查
		Dim xhtmlCheck
		xhtmlCheck = checkXHTML(content)
		If xhtmlCheck <> "" Then
			' 存在安全问题，返回空或进行HTML编码
			content = DvSecurity.HTMLEncode(content)
		End If
	End If

	FilterContent = content
End Function

' 过滤用户名
Function FilterUsername(ByVal username)
	If IsNull(username) Or username = "" Then
		FilterUsername = ""
		Exit Function
	End If

	' 长度限制
	If Len(username) > 20 Then
		username = Left(username, 20)
	End If

	' SQL注入防护
	username = DvSecurity.SafeSQL(username)

	' 移除特殊字符
	username = Replace(username, "<", "")
	username = Replace(username, ">", "")
	username = Replace(username, """", "")
	username = Replace(username, "'", "")
	username = Replace(username, Chr(0), "")

	FilterUsername = Trim(username)
End Function

' 过滤URL
Function FilterURL(ByVal url)
	If IsNull(url) Or url = "" Then
		FilterURL = ""
		Exit Function
	End If

	' 长度限制
	If Len(url) > 500 Then
		url = Left(url, 500)
	End If

	' URL格式验证
	If Not DvSecurity.ValidateURL(url) Then
		FilterURL = ""
		Exit Function
	End If

	' 检查协议（只允许http和https）
	If Left(LCase(url), 7) <> "http://" And Left(LCase(url), 8) <> "https://" Then
		FilterURL = ""
		Exit Function
	End If

	FilterURL = url
End Function

'=========================================================
' Markdown配置函数
'=========================================================

' 检查Markdown功能是否启用
Function IsMarkdownEnabled()
	' 从数据库或配置中读取
	' 默认返回True
	IsMarkdownEnabled = True

	' 可以从数据库读取配置
	' Dim Rs
	' Set Rs = Dvbbs.Execute("SELECT ConfigValue FROM Dv_MarkdownConfig WHERE ConfigName='EnableMarkdown'")
	' If Not Rs.EOF Then
	'     IsMarkdownEnabled = (Rs(0) = "1")
	' End If
	' Rs.Close
	' Set Rs = Nothing
End Function

' 获取用户的默认编辑器类型
Function GetDefaultEditor(ByVal userId)
	' 可以从用户配置中读取，默认返回"markdown"
	GetDefaultEditor = "markdown"

	' 从数据库读取用户配置示例：
	' If userId > 0 Then
	'     Dim Rs
	'     Set Rs = Dvbbs.Execute("SELECT DefaultEditor FROM Dv_User WHERE UserID=" & userId)
	'     If Not Rs.EOF And Not IsNull(Rs(0)) Then
	'         GetDefaultEditor = Rs(0)
	'     End If
	'     Rs.Close
	'     Set Rs = Nothing
	' End If
End Function

'=========================================================
' 兼容性函数 - 保持原有功能
'=========================================================

' 原有的HTML编码函数（保持向后兼容）
Function HTMLEncode_Legacy(ByVal str)
	HTMLEncode_Legacy = DvSecurity.HTMLEncode(str)
End Function

' 原有的字符串检查函数（保持向后兼容）
Function CheckStr_Legacy(ByVal str)
	CheckStr_Legacy = DvSecurity.SafeSQL(str)
End Function

'=========================================================
' 安全日志记录函数
'=========================================================

' 记录安全事件（可选功能）
Sub LogSecurityEvent(ByVal eventType, ByVal description, ByVal severity)
	If Not Dvbbs.Forum_Setting(30) = "1" Then Exit Sub ' 检查是否启用日志

	On Error Resume Next
	Dim sql
	sql = "INSERT INTO Dv_SecurityLog (EventType, Description, Severity, UserID, IP, CreateTime) " & _
	      "VALUES ('" & DvSecurity.SafeSQL(eventType) & "', '" & DvSecurity.SafeSQL(description) & "', " & _
	      severity & ", " & Dvbbs.UserID & ", '" & DvSecurity.GetRealIP() & "', " & SqlNowString & ")"

	' 注意：需要先在数据库中创建Dv_SecurityLog表
	' Dvbbs.Execute(sql)
	On Error Goto 0
End Sub

'=========================================================
' 使用说明
'=========================================================
'
' 1. 在需要过滤用户输入的地方调用相应的Filter函数
' 2. 发帖时检查IsMarkdownEnabled()确定是否启用Markdown
' 3. 使用DvSecurity对象进行各类安全检查
' 4. 使用DvMarkdown对象进行Markdown解析
'
' 示例：
' Dim title, content
' title = FilterTitle(Request.Form("title"))
' content = FilterContent(Request.Form("content"), Request.Form("isMarkdown"))
'
'=========================================================
%>
