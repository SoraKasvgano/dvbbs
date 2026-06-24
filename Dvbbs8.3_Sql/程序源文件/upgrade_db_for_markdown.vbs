' =========================================================
' DVBBS 8.3 SQL Server版数据库升级脚本
' 功能: 添加Markdown支持字段和配置表
' 日期: 2024-06-24
' =========================================================

Option Explicit

Dim conn, connStr
Dim sqlCmd, recordsAffected
Dim dbServer, dbName, dbUser, dbPass

' ===== 配置区域 =====
' 请根据您的SQL Server配置修改以下参数
dbServer = "(local)"        ' SQL Server服务器名称或IP
dbName = "dvbbs"           ' 数据库名称
dbUser = "dvbbs"           ' 数据库用户名
dbPass = "dvbbs"           ' 数据库密码
' ==================

WScript.Echo "=========================================="
WScript.Echo "DVBBS 8.3 SQL Server版 - Markdown升级脚本"
WScript.Echo "=========================================="
WScript.Echo ""

' 创建连接字符串
connStr = "Provider=SQLOLEDB;Data Source=" & dbServer & ";" & _
          "Initial Catalog=" & dbName & ";" & _
          "User ID=" & dbUser & ";Password=" & dbPass & ";"

' 连接数据库
On Error Resume Next
Set conn = CreateObject("ADODB.Connection")
conn.Open connStr

If Err.Number <> 0 Then
    WScript.Echo "【错误】无法连接到数据库！"
    WScript.Echo "错误信息: " & Err.Description
    WScript.Echo ""
    WScript.Echo "请检查："
    WScript.Echo "1. SQL Server服务是否启动"
    WScript.Echo "2. 数据库名称、用户名、密码是否正确"
    WScript.Echo "3. 用户是否有足够的权限"
    WScript.Echo "4. 防火墙是否允许连接（端口1433）"
    WScript.Quit 1
End If

WScript.Echo "✓ 成功连接到数据库: " & dbName
WScript.Echo ""

' ===== 步骤1: 检查并添加IsMarkdown字段到Dv_topic表 =====
WScript.Echo "【步骤1】检查 Dv_topic 表..."

' 检查字段是否已存在
sqlCmd = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " & _
         "WHERE TABLE_NAME='Dv_topic' AND COLUMN_NAME='IsMarkdown'"

Dim rs
Set rs = conn.Execute(sqlCmd)
Dim fieldExists
fieldExists = (rs(0).Value > 0)
rs.Close
Set rs = Nothing

If fieldExists Then
    WScript.Echo "  → IsMarkdown 字段已存在，跳过"
Else
    ' 添加IsMarkdown字段
    sqlCmd = "ALTER TABLE Dv_topic ADD IsMarkdown INT DEFAULT 0"
    On Error Resume Next
    conn.Execute sqlCmd, recordsAffected

    If Err.Number <> 0 Then
        WScript.Echo "  ✗ 添加字段失败: " & Err.Description
        Err.Clear
    Else
        WScript.Echo "  ✓ 成功添加 IsMarkdown 字段"
    End If
End If

' ===== 步骤2: 为IsMarkdown字段添加注释 =====
WScript.Echo ""
WScript.Echo "【步骤2】添加字段说明..."

sqlCmd = "IF NOT EXISTS (SELECT * FROM ::fn_listextendedproperty(" & _
         "'MS_Description', 'SCHEMA', 'dbo', 'TABLE', 'Dv_topic', 'COLUMN', 'IsMarkdown')) " & _
         "EXEC sp_addextendedproperty " & _
         "'MS_Description', '是否为Markdown格式: 0=UBB, 1=Markdown', " & _
         "'SCHEMA', 'dbo', 'TABLE', 'Dv_topic', 'COLUMN', 'IsMarkdown'"

On Error Resume Next
conn.Execute sqlCmd
If Err.Number <> 0 Then
    WScript.Echo "  → 添加说明失败（非致命错误）: " & Err.Description
    Err.Clear
Else
    WScript.Echo "  ✓ 已添加字段说明"
End If

' ===== 步骤3: 创建索引（可选，提升查询性能） =====
WScript.Echo ""
WScript.Echo "【步骤3】创建索引..."

sqlCmd = "IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='IX_Dv_topic_IsMarkdown') " & _
         "CREATE INDEX IX_Dv_topic_IsMarkdown ON Dv_topic(IsMarkdown)"

On Error Resume Next
conn.Execute sqlCmd
If Err.Number <> 0 Then
    WScript.Echo "  → 索引创建失败（非致命错误）: " & Err.Description
    Err.Clear
Else
    WScript.Echo "  ✓ 已创建索引 IX_Dv_topic_IsMarkdown"
End If

' ===== 步骤4: 创建配置表 =====
WScript.Echo ""
WScript.Echo "【步骤4】创建配置表..."

' 检查表是否存在
sqlCmd = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Dv_Markdown_Config'"
Set rs = conn.Execute(sqlCmd)
Dim tableExists
tableExists = (rs(0).Value > 0)
rs.Close
Set rs = Nothing

If tableExists Then
    WScript.Echo "  → Dv_Markdown_Config 表已存在，跳过"
Else
    ' 创建配置表
    sqlCmd = "CREATE TABLE Dv_Markdown_Config (" & _
             "ConfigKey NVARCHAR(50) NOT NULL PRIMARY KEY, " & _
             "ConfigValue NVARCHAR(500), " & _
             "ConfigDesc NVARCHAR(200), " & _
             "UpdateTime DATETIME DEFAULT GETDATE())"

    On Error Resume Next
    conn.Execute sqlCmd

    If Err.Number <> 0 Then
        WScript.Echo "  ✗ 创建表失败: " & Err.Description
        Err.Clear
    Else
        WScript.Echo "  ✓ 成功创建 Dv_Markdown_Config 表"

        ' 插入默认配置
        WScript.Echo ""
        WScript.Echo "【步骤5】插入默认配置..."

        Dim configs(3, 2)
        configs(0, 0) = "EnableMarkdown"
        configs(0, 1) = "1"
        configs(0, 2) = "是否启用Markdown功能: 0=禁用, 1=启用"

        configs(1, 0) = "DefaultEditor"
        configs(1, 1) = "markdown"
        configs(1, 2) = "默认编辑器: ubb=UBB编辑器, markdown=Markdown编辑器"

        configs(2, 0) = "EnableCodeHighlight"
        configs(2, 1) = "1"
        configs(2, 2) = "是否启用代码高亮: 0=禁用, 1=启用"

        configs(3, 0) = "MarkdownVersion"
        configs(3, 1) = "1.0"
        configs(3, 2) = "Markdown功能版本号"

        Dim i
        For i = 0 To 3
            sqlCmd = "INSERT INTO Dv_Markdown_Config (ConfigKey, ConfigValue, ConfigDesc, UpdateTime) " & _
                     "VALUES ('" & configs(i, 0) & "', '" & configs(i, 1) & "', '" & configs(i, 2) & "', GETDATE())"

            On Error Resume Next
            conn.Execute sqlCmd

            If Err.Number <> 0 Then
                WScript.Echo "  → 插入配置 " & configs(i, 0) & " 失败: " & Err.Description
                Err.Clear
            Else
                WScript.Echo "  ✓ 已插入配置: " & configs(i, 0)
            End If
        Next
    End If
End If

' ===== 步骤6: 创建视图（可选） =====
WScript.Echo ""
WScript.Echo "【步骤6】创建统计视图..."

sqlCmd = "IF NOT EXISTS (SELECT * FROM sys.views WHERE name='Dv_Markdown_Stats') " & _
         "EXEC('CREATE VIEW Dv_Markdown_Stats AS " & _
         "SELECT " & _
         "  (SELECT COUNT(*) FROM Dv_topic WHERE IsMarkdown=1) AS MarkdownCount, " & _
         "  (SELECT COUNT(*) FROM Dv_topic WHERE IsMarkdown=0) AS UBBCount, " & _
         "  (SELECT COUNT(*) FROM Dv_topic) AS TotalCount, " & _
         "  CAST((SELECT COUNT(*) FROM Dv_topic WHERE IsMarkdown=1) * 100.0 / " & _
         "       NULLIF((SELECT COUNT(*) FROM Dv_topic), 0) AS DECIMAL(5,2)) AS MarkdownPercentage')"

On Error Resume Next
conn.Execute sqlCmd
If Err.Number <> 0 Then
    WScript.Echo "  → 视图创建失败（非致命错误）: " & Err.Description
    Err.Clear
Else
    WScript.Echo "  ✓ 已创建统计视图 Dv_Markdown_Stats"
End If

' ===== 步骤7: 验证升级结果 =====
WScript.Echo ""
WScript.Echo "【步骤7】验证升级结果..."

' 验证字段
sqlCmd = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " & _
         "WHERE TABLE_NAME='Dv_topic' AND COLUMN_NAME='IsMarkdown'"
Set rs = conn.Execute(sqlCmd)
If rs(0).Value > 0 Then
    WScript.Echo "  ✓ Dv_topic.IsMarkdown 字段验证成功"
Else
    WScript.Echo "  ✗ Dv_topic.IsMarkdown 字段验证失败"
End If
rs.Close

' 验证配置表
sqlCmd = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Dv_Markdown_Config'"
Set rs = conn.Execute(sqlCmd)
If rs(0).Value > 0 Then
    WScript.Echo "  ✓ Dv_Markdown_Config 表验证成功"

    ' 显示配置
    sqlCmd = "SELECT ConfigKey, ConfigValue FROM Dv_Markdown_Config"
    Set rs = conn.Execute(sqlCmd)
    If Not rs.EOF Then
        WScript.Echo ""
        WScript.Echo "  当前配置:"
        Do While Not rs.EOF
            WScript.Echo "    " & rs("ConfigKey") & " = " & rs("ConfigValue")
            rs.MoveNext
        Loop
    End If
Else
    WScript.Echo "  ✗ Dv_Markdown_Config 表验证失败"
End If
rs.Close
Set rs = Nothing

' ===== 完成 =====
WScript.Echo ""
WScript.Echo "=========================================="
WScript.Echo "✓ 数据库升级完成！"
WScript.Echo "=========================================="
WScript.Echo ""
WScript.Echo "【下一步】"
WScript.Echo "1. 将新文件复制到论坛目录"
WScript.Echo "2. 在发帖页面引入Markdown编辑器"
WScript.Echo "3. 在显示页面引入Markdown渲染"
WScript.Echo "4. 打开 markdown-demo.html 测试功能"
WScript.Echo ""
WScript.Echo "【查询统计】"
WScript.Echo "执行以下SQL查看统计信息："
WScript.Echo "  SELECT * FROM Dv_Markdown_Stats"
WScript.Echo ""

' 关闭连接
conn.Close
Set conn = Nothing

WScript.Echo "按任意键退出..."
WScript.StdIn.ReadLine
