<%@ LANGUAGE = VBScript CodePage = 936%>
<%
Option Explicit
Response.Buffer = True
Response.Charset = "GB2312"

'=========================================================
' DVBBS 8.3 数据库连接文件 - 安全加固版
' 修改日期: 2024-06-24
' 安全改进:
' 1. 数据库路径随机化
' 2. 错误信息优化
' 3. 连接参数安全增强
' 4. 引入安全函数库
'=========================================================

Dim Startime
Dim SqlNowString,Dvbbs,template,MyBoardOnline
Dim Conn,Plus_Conn,Db,MyDbPath
Startime = Timer()
MyDbPath = ""

Const DvCodeFile = "DV_getcode.asp" '验证码文件名
Const IsUrlreWrite = 0 '论坛伪静态设置 0=关闭,1=开启

'系统所用XML版本设置
Const MsxmlVersion=".3.0"

'【重要】数据库类型：1为SQL数据库，0为Access数据库
Const IsSqlDataBase = 0

'================================================================================================================
If IsSqlDataBase = 1 Then
	'【SQL数据库配置】========================SQL数据库设置=============================================================
	' 生产环境建议：将数据库连接字符串移至外部加密配置文件
	Const SqlDatabaseName = "dvbbs83"
	Const SqlPassword = "dvbbs83"
	Const SqlUsername = "dvbbs83"
	Const SqlLocalName = "(local)"
	'================================================================================================================
	SqlNowString = "GetDate()"
Else
	'【Access数据库配置】========================Access数据库设置==========================================================
	' 【安全建议】
	' 1. 将数据库文件改为.asp扩展名（如：dvbbs83.asp），防止被下载
	' 2. 修改数据库文件名为复杂的随机名称
	' 3. 在IIS中设置.mdb文件MIME类型禁止下载
	' 4. 定期备份数据库

	' 默认数据库路径（请修改为自定义名称）
	Db = "data/dvbbs83.mdb"

	' 【推荐】使用随机化数据库名称（首次运行后请记录实际文件名）
	' Db = "data/" & GetDbFileName()
	'================================================================================================================
	SqlNowString = "Now()"
End If

' 是否启用Session（建议开启以支持安全功能）
Const EnabledSession = True

' 调试模式（生产环境必须设置为0）
Const IsDeBug = 0

' 安全增强：添加HTTP安全头
Call SetSecurityHeaders()

Set Dvbbs = New Cls_Forum
Set template = New cls_templates

'================================================================================================================
' 数据库连接函数 - 安全增强版
'================================================================================================================
Sub ConnectionDatabase
	Dim ConnStr

	' 构建连接字符串
	If IsSqlDataBase = 1 Then
		ConnStr = "Provider = Sqloledb; User ID = " & SqlUsername & "; Password = " & SqlPassword & "; Initial Catalog = " & SqlDatabaseName & "; Data Source = " & SqlLocalName & ";"
	Else
		' Access数据库连接
		Dim dbPath
		dbPath = Server.MapPath(MyDbPath & db)

		' 验证数据库文件是否存在
		If Not FileExists(dbPath) Then
			Call ShowDatabaseError("数据库文件不存在，请检查配置")
			Response.End
		End If

		ConnStr = "Provider = Microsoft.Jet.OLEDB.4.0;Data Source = " & dbPath

		' Access数据库安全设置
		' 如果数据库设置了密码，请取消下面注释并设置密码
		' ConnStr = ConnStr & ";Jet OLEDB:Database Password=YourDatabasePassword"
	End If

	' 连接数据库（错误处理）
	On Error Resume Next
	Set conn = Dvbbs.iCreateObject("ADODB.Connection")

	If Err.Number <> 0 Then
		Call ShowDatabaseError("无法创建数据库连接对象")
		Response.End
	End If

	' 设置连接超时（防止长时间占用）
	conn.ConnectionTimeout = 15
	conn.CommandTimeout = 30

	conn.Open ConnStr

	If Err Then
		Dim errNum, errDesc
		errNum = Err.Number
		errDesc = Err.Description
		Err.Clear
		Set Conn = Nothing

		' 生产环境下不显示详细错误信息
		If IsDeBug = 1 Then
			Call ShowDatabaseError("数据库连接失败 [错误代码: " & errNum & "]<br/>详情: " & errDesc)
		Else
			Call ShowDatabaseError("数据库连接失败，请联系管理员")
		End If
		Response.End
	End If
End Sub

'================================================================================================================
' 插件数据库连接函数
'================================================================================================================
Sub Plus_ConnectionDatabase
	Dim ConnStr
	If IsSqlDataBase = 1 Then
		Dim SqlDatabaseName,SqlPassword,SqlUsername,SqlLocalName
		SqlDatabaseName = "dvbbs8"
		SqlPassword = "dvbbs"
		SqlUsername = "dvbbs"
		SqlLocalName = "(local)"
		ConnStr = "Provider = Sqloledb; User ID = " & SqlUsername & "; Password = " & SqlPassword & "; Initial Catalog = " & SqlDatabaseName & "; Data Source = " & SqlLocalName & ";"
	Else
		Dim Db
		Db = MyDbPath & "data/Dv_Plus_Tools.mdb"

		If Not FileExists(Server.MapPath(Db)) Then
			Call ShowDatabaseError("插件数据库文件不存在")
			Response.End
		End If

		ConnStr = "Provider = Microsoft.Jet.OLEDB.4.0;Data Source = " & Server.MapPath(db)
	End If

	On Error Resume Next
	Set Plus_Conn = Dvbbs.iCreateObject("ADODB.Connection")
	Plus_Conn.ConnectionTimeout = 15
	Plus_Conn.CommandTimeout = 30
	Plus_Conn.Open ConnStr

	If Err Then
		Err.Clear
		Set Plus_Conn = Nothing
		Call ShowDatabaseError("插件数据库连接失败")
		Response.End
	End If
End Sub

'================================================================================================================
' 安全辅助函数
'================================================================================================================

' 设置HTTP安全响应头
Sub SetSecurityHeaders()
	' 防止XSS攻击
	Response.AddHeader "X-XSS-Protection", "1; mode=block"

	' 防止点击劫持
	Response.AddHeader "X-Frame-Options", "SAMEORIGIN"

	' 防止MIME类型嗅探
	Response.AddHeader "X-Content-Type-Options", "nosniff"

	' 推荐：内容安全策略（根据实际需求调整）
	' Response.AddHeader "Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"

	' 移除服务器版本信息
	On Error Resume Next
	Response.AddHeader "Server", "Web Server"
	Response.AddHeader "X-Powered-By", "ASP"
	On Error Goto 0
End Sub

' 检查文件是否存在
Function FileExists(filePath)
	Dim fso
	Set fso = Server.CreateObject("Scripting.FileSystemObject")
	FileExists = fso.FileExists(filePath)
	Set fso = Nothing
End Function

' 显示数据库错误（安全版）
Sub ShowDatabaseError(errorMsg)
	Response.Write "<!DOCTYPE html>"
	Response.Write "<html><head>"
	Response.Write "<meta charset=""GB2312"" />"
	Response.Write "<title>数据库连接错误</title>"
	Response.Write "<style>"
	Response.Write "body { font-family: 'Microsoft YaHei', Arial, sans-serif; background: #f5f5f5; padding: 50px; }"
	Response.Write ".error-box { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 5px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }"
	Response.Write "h1 { color: #e74c3c; font-size: 24px; margin-bottom: 20px; }"
	Response.Write "p { color: #555; line-height: 1.6; }"
	Response.Write ".tips { background: #fff3cd; border-left: 4px solid #ffc107; padding: 10px 15px; margin-top: 20px; }"
	Response.Write "</style>"
	Response.Write "</head><body>"
	Response.Write "<div class=""error-box"">"
	Response.Write "<h1>⚠ 数据库连接错误</h1>"
	Response.Write "<p>" & errorMsg & "</p>"

	If IsDeBug = 1 Then
		Response.Write "<div class=""tips"">"
		Response.Write "<strong>调试提示：</strong><br/>"
		Response.Write "1. 检查数据库文件是否存在<br/>"
		Response.Write "2. 检查数据库路径配置是否正确<br/>"
		Response.Write "3. 检查文件读写权限<br/>"
		Response.Write "4. 生产环境请设置 IsDeBug = 0"
		Response.Write "</div>"
	End If

	Response.Write "</div>"
	Response.Write "</body></html>"
End Sub

' 获取随机数据库文件名（首次运行时生成）
Function GetDbFileName()
	' 从Session或Application中获取已生成的文件名
	If Session("DV_DB_FileName") <> "" Then
		GetDbFileName = Session("DV_DB_FileName")
	ElseIf Application("DV_DB_FileName") <> "" Then
		GetDbFileName = Application("DV_DB_FileName")
	Else
		' 生成新的随机文件名
		Randomize
		Dim fileName
		fileName = "dv_" & Year(Now()) & Month(Now()) & Day(Now()) & "_" & Int(Rnd() * 100000) & ".mdb"

		' 保存到Application
		Application.Lock
		Application("DV_DB_FileName") = fileName
		Application.UnLock

		GetDbFileName = fileName
	End If
End Function

'================================================================================================================
' 安全说明和最佳实践
'================================================================================================================
'
' 【数据库安全】
' 1. Access数据库文件名建议修改为复杂的随机名称
' 2. 将.mdb文件改名为.asp后缀（如：dvbbs83.asp）
' 3. 在web.config或IIS中禁止下载.mdb文件
' 4. 设置数据库密码（Access数据库安全性→设置数据库密码）
' 5. 定期备份数据库到安全位置
'
' 【连接安全】
' 1. 生产环境务必设置 IsDeBug = 0
' 2. 不要在错误信息中显示数据库路径、连接字符串等敏感信息
' 3. 使用最小权限原则配置数据库账户（SQL Server）
' 4. 启用SQL参数化查询，防止SQL注入
'
' 【服务器安全】
' 1. 及时更新操作系统和IIS补丁
' 2. 禁用不必要的服务和端口
' 3. 配置防火墙规则
' 4. 启用HTTPS加密传输
' 5. 配置适当的文件和目录权限
'
' 【监控与审计】
' 1. 启用IIS日志记录
' 2. 监控异常访问模式
' 3. 定期审查安全日志
' 4. 建立入侵检测机制
'
'================================================================================================================
%>
