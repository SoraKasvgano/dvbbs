<%
'=========================================================
' File: Dv_Security.asp
' Version: 1.0
' Date: 2024-06-24
' Description: DVBBS 8.3 安全增强函数库
' 功能: SQL注入防护、XSS防护、CSRF防护、输入验证
'=========================================================

Class Cls_Security
    Private rsaKey, csrfTokens

    Private Sub Class_Initialize()
        ' 初始化CSRF令牌集合
        If IsEmpty(Session("DV_CSRF_Tokens")) Then
            Set Session("DV_CSRF_Tokens") = Server.CreateObject("Scripting.Dictionary")
        End If
    End Sub

    '=========================================================
    ' SQL注入防护 - 参数化查询辅助函数
    '=========================================================

    ' 安全的数字参数验证
    Public Function SafeNumber(ByVal value, ByVal defaultValue)
        If IsNumeric(value) And value <> "" Then
            SafeNumber = CLng(value)
        Else
            SafeNumber = defaultValue
        End If
    End Function

    ' 安全的字符串参数（用于SQL查询）
    Public Function SafeSQL(ByVal str)
        If IsNull(str) Or str = "" Then
            SafeSQL = ""
            Exit Function
        End If

        ' 移除危险字符
        str = Replace(str, Chr(0), "")
        str = Replace(str, Chr(9), "")
        str = Replace(str, Chr(10), "")
        str = Replace(str, Chr(13), "")

        ' SQL单引号转义（双倍单引号）
        str = Replace(str, "'", "''")

        ' 移除SQL注释符
        str = Replace(str, "--", "")
        str = Replace(str, "/*", "")
        str = Replace(str, "*/", "")

        ' 移除危险的SQL关键字组合
        Dim dangerousPatterns
        dangerousPatterns = Array("exec(", "execute(", "xp_", "sp_", "0x", "@@")
        Dim pattern
        For Each pattern In dangerousPatterns
            str = Replace(str, pattern, "", 1, -1, vbTextCompare)
        Next

        SafeSQL = str
    End Function

    ' 创建参数化查询的Command对象（推荐方式）
    Public Function CreateCommand(ByVal sql, ByVal conn)
        Dim cmd
        Set cmd = Server.CreateObject("ADODB.Command")
        cmd.ActiveConnection = conn
        cmd.CommandText = sql
        cmd.CommandType = 1 ' adCmdText
        cmd.Prepared = True
        Set CreateCommand = cmd
    End Function

    ' 添加参数到Command对象
    Public Sub AddParameter(ByRef cmd, ByVal name, ByVal dataType, ByVal size, ByVal value)
        Dim param
        Set param = cmd.CreateParameter(name, dataType, 1, size, value) ' 1 = adParamInput
        cmd.Parameters.Append param
    End Sub

    '=========================================================
    ' XSS跨站脚本防护
    '=========================================================

    ' HTML实体编码（增强版）
    Public Function HTMLEncode(ByVal str)
        If IsNull(str) Or str = "" Then
            HTMLEncode = ""
            Exit Function
        End If

        ' 基础HTML实体转义
        str = Replace(str, "&", "&amp;")
        str = Replace(str, "<", "&lt;")
        str = Replace(str, ">", "&gt;")
        str = Replace(str, Chr(34), "&quot;")
        str = Replace(str, "'", "&#39;")
        str = Replace(str, "/", "&#x2F;")

        ' 移除NULL字节
        str = Replace(str, Chr(0), "")

        HTMLEncode = str
    End Function

    ' JavaScript字符串编码
    Public Function JSEncode(ByVal str)
        If IsNull(str) Or str = "" Then
            JSEncode = ""
            Exit Function
        End If

        str = Replace(str, "\", "\\")
        str = Replace(str, "'", "\'")
        str = Replace(str, Chr(34), "\""")
        str = Replace(str, vbCrLf, "\n")
        str = Replace(str, vbCr, "\n")
        str = Replace(str, vbLf, "\n")
        str = Replace(str, "<", "\x3C")
        str = Replace(str, ">", "\x3E")

        JSEncode = str
    End Function

    ' URL编码
    Public Function URLEncode(ByVal str)
        If IsNull(str) Or str = "" Then
            URLEncode = ""
            Exit Function
        End If

        URLEncode = Server.URLEncode(str)
    End Function

    ' 移除所有HTML标签
    Public Function StripHTML(ByVal str)
        If IsNull(str) Or str = "" Then
            StripHTML = ""
            Exit Function
        End If

        Dim re
        Set re = New RegExp
        re.IgnoreCase = True
        re.Global = True

        ' 移除<script>标签及内容
        re.Pattern = "<script[^>]*?>.*?</script>"
        str = re.Replace(str, "")

        ' 移除<style>标签及内容
        re.Pattern = "<style[^>]*?>.*?</style>"
        str = re.Replace(str, "")

        ' 移除所有HTML标签
        re.Pattern = "<[^>]+>"
        str = re.Replace(str, "")

        ' 移除HTML实体
        re.Pattern = "&[a-zA-Z]+;"
        str = re.Replace(str, "")

        Set re = Nothing
        StripHTML = Trim(str)
    End Function

    ' 检查是否包含危险的HTML/JS代码
    Public Function ContainsDangerousCode(ByVal str)
        ContainsDangerousCode = False
        If IsNull(str) Or str = "" Then Exit Function

        Dim lowerStr
        lowerStr = LCase(str)

        ' 检查危险标签
        Dim dangerousTags
        dangerousTags = Array("script", "iframe", "object", "embed", "applet", "meta", "link", "base", "form")
        Dim tag
        For Each tag In dangerousTags
            If InStr(lowerStr, "<" & tag) > 0 Then
                ContainsDangerousCode = True
                Exit Function
            End If
        Next

        ' 检查事件处理器
        Dim eventHandlers
        eventHandlers = Array("onclick", "onload", "onerror", "onmouseover", "onmouseout", "onkeydown", "onkeyup", "onfocus", "onblur")
        For Each tag In eventHandlers
            If InStr(lowerStr, tag & "=") > 0 Then
                ContainsDangerousCode = True
                Exit Function
            End If
        Next

        ' 检查javascript伪协议
        If InStr(lowerStr, "javascript:") > 0 Then
            ContainsDangerousCode = True
            Exit Function
        End If

        ' 检查vbscript伪协议
        If InStr(lowerStr, "vbscript:") > 0 Then
            ContainsDangerousCode = True
            Exit Function
        End If

        ' 检查data URL
        If InStr(lowerStr, "data:text/html") > 0 Then
            ContainsDangerousCode = True
            Exit Function
        End If
    End Function

    '=========================================================
    ' CSRF跨站请求伪造防护
    '=========================================================

    ' 生成CSRF令牌
    Public Function GenerateCSRFToken(ByVal formName)
        Randomize
        Dim token, i
        token = ""
        For i = 1 To 32
            token = token & Chr(Int(Rnd() * 26) + 65)
        Next

        ' 存储到Session
        Session("DV_CSRF_" & formName) = token
        Session("DV_CSRF_" & formName & "_Time") = Now()

        GenerateCSRFToken = token
    End Function

    ' 验证CSRF令牌
    Public Function ValidateCSRFToken(ByVal formName, ByVal token)
        ValidateCSRFToken = False

        ' 检查令牌是否存在
        If IsEmpty(Session("DV_CSRF_" & formName)) Then Exit Function

        ' 检查令牌是否匹配
        If Session("DV_CSRF_" & formName) <> token Then Exit Function

        ' 检查令牌是否过期（30分钟）
        If Not IsDate(Session("DV_CSRF_" & formName & "_Time")) Then Exit Function
        If DateDiff("n", Session("DV_CSRF_" & formName & "_Time"), Now()) > 30 Then Exit Function

        ' 验证成功，清除令牌（一次性使用）
        Session("DV_CSRF_" & formName) = ""

        ValidateCSRFToken = True
    End Function

    ' 生成CSRF隐藏字段HTML
    Public Function GetCSRFField(ByVal formName)
        Dim token
        token = GenerateCSRFToken(formName)
        GetCSRFField = "<input type=""hidden"" name=""csrf_token"" value=""" & token & """ />"
    End Function

    '=========================================================
    ' 文件上传安全
    '=========================================================

    ' 验证文件扩展名（白名单）
    Public Function ValidateFileExtension(ByVal filename, ByVal allowedExts)
        ValidateFileExtension = False
        If filename = "" Then Exit Function

        Dim ext, extList, allowedExt
        ext = LCase(Mid(filename, InStrRev(filename, ".") + 1))
        extList = Split(LCase(allowedExts), ",")

        For Each allowedExt In extList
            If Trim(allowedExt) = ext Then
                ValidateFileExtension = True
                Exit Function
            End If
        Next
    End Function

    ' 生成安全的文件名
    Public Function SafeFileName(ByVal filename)
        If filename = "" Then
            SafeFileName = ""
            Exit Function
        End If

        ' 移除路径遍历字符
        filename = Replace(filename, "..", "")
        filename = Replace(filename, "/", "")
        filename = Replace(filename, "\", "")
        filename = Replace(filename, ":", "")
        filename = Replace(filename, "*", "")
        filename = Replace(filename, "?", "")
        filename = Replace(filename, """", "")
        filename = Replace(filename, "<", "")
        filename = Replace(filename, ">", "")
        filename = Replace(filename, "|", "")
        filename = Replace(filename, Chr(0), "")

        ' 生成新文件名：时间戳_随机数_原文件名
        Dim newName, ext, baseName
        ext = Mid(filename, InStrRev(filename, "."))
        baseName = Left(filename, InStrRev(filename, ".") - 1)

        Randomize
        newName = Year(Now()) & Month(Now()) & Day(Now()) & Hour(Now()) & Minute(Now()) & Second(Now()) & "_"
        newName = newName & Int(Rnd() * 10000) & "_" & Left(baseName, 20) & ext

        SafeFileName = newName
    End Function

    '=========================================================
    ' IP和Referer验证
    '=========================================================

    ' 验证HTTP Referer
    Public Function ValidateReferer()
        ValidateReferer = False

        Dim referer, serverName
        referer = Request.ServerVariables("HTTP_REFERER")
        serverName = Request.ServerVariables("SERVER_NAME")

        If referer = "" Then Exit Function
        If InStr(1, referer, serverName, vbTextCompare) > 0 Then
            ValidateReferer = True
        End If
    End Function

    ' 获取真实IP地址
    Public Function GetRealIP()
        Dim ip
        ip = Request.ServerVariables("HTTP_X_FORWARDED_FOR")

        If ip = "" Or InStr(ip, "unknown") > 0 Then
            ip = Request.ServerVariables("REMOTE_ADDR")
        ElseIf InStr(ip, ",") > 0 Then
            ip = Trim(Split(ip, ",")(0))
        ElseIf InStr(ip, ";") > 0 Then
            ip = Trim(Split(ip, ";")(0))
        End If

        ' 验证IP格式
        If Not IsValidIP(ip) Then
            ip = Request.ServerVariables("REMOTE_ADDR")
        End If

        GetRealIP = Left(ip, 30)
    End Function

    ' 验证IP地址格式
    Private Function IsValidIP(ByVal ip)
        IsValidIP = False
        If ip = "" Then Exit Function

        Dim parts, part
        parts = Split(ip, ".")
        If UBound(parts) <> 3 Then Exit Function

        For Each part In parts
            If Not IsNumeric(part) Then Exit Function
            If CLng(part) < 0 Or CLng(part) > 255 Then Exit Function
        Next

        IsValidIP = True
    End Function

    '=========================================================
    ' 密码安全
    '=========================================================

    ' SHA256哈希（需要配合MD5.asp使用，这里提供接口）
    Public Function HashPassword(ByVal password, ByVal salt)
        ' 使用盐值+密码进行多次哈希
        Dim hash
        hash = MD5(salt & password)
        hash = MD5(hash & salt)
        HashPassword = hash
    End Function

    ' 生成随机盐值
    Public Function GenerateSalt()
        Randomize
        Dim salt, i
        salt = ""
        For i = 1 To 16
            salt = salt & Chr(Int(Rnd() * 74) + 48)
        Next
        GenerateSalt = salt
    End Function

    ' 验证密码强度
    Public Function ValidatePasswordStrength(ByVal password)
        ValidatePasswordStrength = True

        ' 长度检查
        If Len(password) < 6 Then
            ValidatePasswordStrength = False
            Exit Function
        End If

        ' 可选：要求包含数字和字母
        ' Dim hasLetter, hasNumber
        ' hasLetter = (password Like "*[A-Za-z]*")
        ' hasNumber = (password Like "*[0-9]*")
        ' If Not (hasLetter And hasNumber) Then ValidatePasswordStrength = False
    End Function

    '=========================================================
    ' 输入长度和格式验证
    '=========================================================

    ' 验证字符串长度
    Public Function ValidateLength(ByVal str, ByVal minLen, ByVal maxLen)
        ValidateLength = False
        If IsNull(str) Then Exit Function

        Dim length
        length = Len(str)
        If length >= minLen And length <= maxLen Then
            ValidateLength = True
        End If
    End Function

    ' 验证邮箱格式
    Public Function ValidateEmail(ByVal email)
        ValidateEmail = False
        If email = "" Then Exit Function

        Dim re
        Set re = New RegExp
        re.Pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        ValidateEmail = re.Test(email)
        Set re = Nothing
    End Function

    ' 验证URL格式
    Public Function ValidateURL(ByVal url)
        ValidateURL = False
        If url = "" Then Exit Function

        Dim re
        Set re = New RegExp
        re.IgnoreCase = True
        re.Pattern = "^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$"
        ValidateURL = re.Test(url)
        Set re = Nothing
    End Function

    Private Sub Class_Terminate()
    End Sub
End Class

' 创建全局安全对象
Dim DvSecurity
Set DvSecurity = New Cls_Security
%>
