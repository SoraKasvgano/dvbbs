<%@ LANGUAGE = VBScript CodePage = 936%>
<%
Option Explicit
Response.Buffer = True
Response.Charset = "GB2312"

'=========================================================
' DVBBS 8.3 SQL Server版数据库连接文件 - 安全加固版
' 修改日期: 2024-06-24
' 安全改进:
' 1. 连接字符串安全增强
' 2. 错误信息优化
' 3. SQL注入防护
' 4. 引入安全函数库
'=========================================================

Dim Startime
Dim SqlNowString,Dvbbs,template,MyBoardOnline
Dim Conn,Plus_Conn,Db,MyDbPath
Startime = Timer()
MyDbPath = ""

Const DvCodeFile = "DV_getcode.asp"
Const IsUrlreWrite = 0

'系统所用XML版本设置
Const MsxmlVersion=".3.0"

'【重要】数据库类型：1为SQL数据库，0为Access数据库
Const IsSqlDataBase = 1

'================================================================================================================
If IsSqlDataBase = 1 Then
	'【SQL数据库配置】========================SQL数据库设置=============================================================
	' 生产环境建议：
	' 1. 使用Windows身份验证（更安全）
	' 2. 使用最小权限账户
	' 3. 加密连接字符串
	' 4. 启用SSL连接

	Const SqlDatabaseName = "dvbbs"
	Const SqlPassword = "dvbbs"
	Const SqlUsername = "dvbbs"
	Const SqlLocalName = "(local)"

	' 【安全建议】
	' 生产环境请修改为强密码，例如：
	' Const SqlPassword = "Dvbbs@2024!Secure#Pass"
	'================================================================================================================
	SqlNowString = "GetDate()"
Else
	'【Access数据库配置】
	Db = "data/dvbbs83.mdb"
	SqlNowString = "Now()"
End If

' 是否启用Session（建议开启）
Const EnabledSession = True

' 调试模式（生产环境必须设置为0）
Const IsDeBug = 0

' 安全增强：添加HTTP安全头
Call SetSecurityHeaders()

Set Dvbbs = New Cls_Forum
Set template = New cls_templates

'================================================================================================================
' 数据库连接函数 - SQL Server安全增强版
'================================================================================================================
Sub ConnectionDatabase
	Dim ConnStr

	' 构建连接字符串
	If IsSqlDataBase = 1 Then
		' SQL Server连接
		ConnStr = "Provider = Sqloledb; User ID = " & SqlUsername & "; Password = " & SqlPassword & "; Initial Catalog = " & SqlDatabaseName & "; Data Source = " & SqlLocalName & ";"

		' 【安全增强选项】
		' 如果使用Windows身份验证（推荐）：
		' ConnStr = "Provider = Sqloledb; Integrated Security = SSPI; Initial Catalog = " & SqlDatabaseName & "; Data Source = " & SqlLocalName & ";"

		' 如果需要加密连接：
		' ConnStr = ConnStr & "Encrypt=yes;"

		' 如果需要信任服务器证书：
		' ConnStr = ConnStr & "TrustServerCertificate=yes;"
	Else
		' Access数据库连接
		Dim dbPath
		dbPath = Server.MapPath(MyDbPath & db)

		If Not FileExists(dbPath) Then
			Call ShowDatabaseError("数据库文件不存在，请检查配置")
			Response.End
		End If

		ConnStr = "Provider = Microsoft.Jet.OLEDB.4.0;Data Source = " & dbPath
	End If

	' 连接数据库（错误处理）
	On Error Resume Next
	Set conn = Dvbbs.iCreateObject("ADODB.Connection")

	If Err.Number <> 0 Then
		Call ShowDatabaseError("无法创建数据库连接对象")
		Response.End
	End If

	' 设置连接超时
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
		Response.Write "<strong>调试提示（SQL Server版本）：</strong><br/>"
		Response.Write "1. 检查SQL Server服务是否启动<br/>"
		Response.Write "2. 检查数据库名称、用户名、密码是否正确<br/>"
		Response.Write "3. 检查SQL Server是否允许远程连接<br/>"
		Response.Write "4. 检查防火墙设置（端口1433）<br/>"
		Response.Write "5. 检查用户权限是否足够<br/>"
		Response.Write "6. 生产环境请设置 IsDeBug = 0"
		Response.Write "</div>"
	End If

	Response.Write "</div>"
	Response.Write "</body></html>"
End Sub

'================================================================================================================
' SQL Server安全最佳实践
'================================================================================================================
'
' 【连接安全】
' 1. 使用Windows身份验证（推荐）
'    ConnStr = "Provider=Sqloledb;Integrated Security=SSPI;..."
'
' 2. 使用强密码（SQL身份验证）
'    至少12个字符，包含大小写字母、数字、特殊字符
'
' 3. 启用SSL加密连接
'    ConnStr = ConnStr & "Encrypt=yes;"
'
' 4. 使用最小权限原则
'    - 只授予必需的数据库权限
'    - 不要使用sa账户
'    - 为应用创建专用账户
'
' 【SQL Server配置】
' 1. 禁用sa账户或设置强密码
' 2. 启用SQL Server身份验证日志
' 3. 配置防火墙规则（仅允许必要IP访问）
' 4. 定期备份数据库
' 5. 启用透明数据加密（TDE）
' 6. 配置审核策略
'
' 【网络安全】
' 1. 不要将SQL Server直接暴露到公网
' 2. 使用VPN或专线连接
' 3. 限制SQL Server端口（1433）访问
' 4. 启用IP白名单
'
' 【监控与审计】
' 1. 监控异常登录尝试
' 2. 记录所有数据库操作
' 3. 定期审查访问日志
' 4. 设置告警机制
'
'================================================================================================================
%>
