' =========================================================
' DVBBS 8.3 数据库升级脚本 - 添加Markdown支持
' 使用方法: 在命令行运行 cscript upgrade_db_for_markdown.vbs
' =========================================================

Option Explicit

Dim conn, sql, dbPath, fso

' 设置数据库路径
Set fso = CreateObject("Scripting.FileSystemObject")
dbPath = fso.GetAbsolutePathName("Data\Dvbbs83.mdb")

If Not fso.FileExists(dbPath) Then
    WScript.Echo "错误：找不到数据库文件 " & dbPath
    WScript.Quit 1
End If

' 连接数据库
Set conn = CreateObject("ADODB.Connection")
conn.Open "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" & dbPath

WScript.Echo "已连接到数据库: " & dbPath
WScript.Echo "开始升级数据库结构..."

' 检查并添加Markdown相关字段
On Error Resume Next

' 1. 在主题表(Dv_topic)中添加IsMarkdown字段
sql = "ALTER TABLE Dv_topic ADD COLUMN IsMarkdown BYTE DEFAULT 0"
conn.Execute sql
If Err.Number = 0 Then
    WScript.Echo "[成功] 已在Dv_topic表添加IsMarkdown字段"
ElseIf Err.Number = -2147217887 Then
    WScript.Echo "[跳过] Dv_topic表的IsMarkdown字段已存在"
    Err.Clear
Else
    WScript.Echo "[错误] 添加IsMarkdown字段失败: " & Err.Description
    Err.Clear
End If

' 2. 在回复表中也添加IsMarkdown字段（需要对所有bbs表操作）
' 由于动态表名，这里提供示例，实际需要遍历所有bbs表
Dim i
For i = 0 To 9
    sql = "ALTER TABLE bbs" & i & " ADD COLUMN IsMarkdown BYTE DEFAULT 0"
    conn.Execute sql
    If Err.Number = 0 Then
        WScript.Echo "[成功] 已在bbs" & i & "表添加IsMarkdown字段"
    ElseIf Err.Number = -2147217887 Then
        Err.Clear
    Else
        Err.Clear
    End If
Next

' 3. 添加Markdown配置表
sql = "CREATE TABLE Dv_MarkdownConfig (" & _
      "ConfigID AUTOINCREMENT PRIMARY KEY, " & _
      "ConfigName TEXT(50), " & _
      "ConfigValue MEMO, " & _
      "ConfigDesc TEXT(255), " & _
      "UpdateTime DATETIME)"
conn.Execute sql
If Err.Number = 0 Then
    WScript.Echo "[成功] 已创建Dv_MarkdownConfig配置表"

    ' 插入默认配置
    sql = "INSERT INTO Dv_MarkdownConfig (ConfigName, ConfigValue, ConfigDesc, UpdateTime) " & _
          "VALUES ('EnableMarkdown', '1', '是否启用Markdown功能(0=关闭,1=开启)', Now())"
    conn.Execute sql

    sql = "INSERT INTO Dv_MarkdownConfig (ConfigName, ConfigValue, ConfigDesc, UpdateTime) " & _
          "VALUES ('DefaultEditor', 'markdown', '默认编辑器(ubb/markdown)', Now())"
    conn.Execute sql

    WScript.Echo "[成功] 已插入Markdown默认配置"
ElseIf Err.Number = -2147217900 Then
    WScript.Echo "[跳过] Dv_MarkdownConfig表已存在"
    Err.Clear
Else
    WScript.Echo "[错误] 创建配置表失败: " & Err.Description
    Err.Clear
End If

' 4. 更新数据库版本信息
sql = "UPDATE Dv_Setup SET Forum_Version='8.3.0-MD' WHERE id=1"
conn.Execute sql
If Err.Number = 0 Then
    WScript.Echo "[成功] 已更新数据库版本标识"
Else
    WScript.Echo "[警告] 更新版本标识失败: " & Err.Description
    Err.Clear
End If

conn.Close
Set conn = Nothing
Set fso = Nothing

WScript.Echo ""
WScript.Echo "数据库升级完成！"
WScript.Echo "请备份原数据库后测试新功能。"
