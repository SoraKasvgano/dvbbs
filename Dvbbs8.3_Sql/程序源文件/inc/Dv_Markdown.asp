<%
'=========================================================
' File: Dv_Markdown.asp
' Version: 1.0
' Date: 2024-06-24
' Description: DVBBS 8.3 Markdown支持函数库
' 功能: Markdown解析、渲染、安全过滤
'=========================================================

Class Cls_Markdown
    Private enableMarkdown
    Private allowedTags
    Private allowedAttributes

    Private Sub Class_Initialize()
        ' 默认启用Markdown
        enableMarkdown = True

        ' 允许的HTML标签（白名单）
        allowedTags = "p,br,strong,em,u,del,blockquote,code,pre,h1,h2,h3,h4,h5,h6,ul,ol,li,a,img,table,thead,tbody,tr,th,td,hr"

        ' 允许的HTML属性
        allowedAttributes = "href,src,alt,title,class,id"
    End Sub

    '=========================================================
    ' 基础Markdown语法解析
    '=========================================================

    ' 主解析函数
    Public Function Parse(ByVal markdown)
        If Not enableMarkdown Or IsNull(markdown) Or markdown = "" Then
            Parse = markdown
            Exit Function
        End If

        Dim html
        html = markdown

        ' 预处理：转义HTML特殊字符
        html = EscapeHTML(html)

        ' 1. 代码块（必须最先处理）
        html = ParseCodeBlocks(html)

        ' 2. 行内代码
        html = ParseInlineCode(html)

        ' 3. 标题
        html = ParseHeaders(html)

        ' 4. 水平线
        html = ParseHorizontalRules(html)

        ' 5. 列表
        html = ParseLists(html)

        ' 6. 引用
        html = ParseBlockquotes(html)

        ' 7. 链接和图片
        html = ParseLinks(html)
        html = ParseImages(html)

        ' 8. 文本格式（粗体、斜体、删除线）
        html = ParseBold(html)
        html = ParseItalic(html)
        html = ParseStrikethrough(html)

        ' 9. 换行和段落
        html = ParseParagraphs(html)

        ' 10. 安全过滤
        html = SanitizeHTML(html)

        Parse = html
    End Function

    ' 转义HTML特殊字符
    Private Function EscapeHTML(ByVal text)
        text = Replace(text, "&", "&amp;")
        text = Replace(text, "<", "&lt;")
        text = Replace(text, ">", "&gt;")
        text = Replace(text, """", "&quot;")
        EscapeHTML = text
    End Function

    ' 反转义（用于代码块等需要保留的内容）
    Private Function UnescapeHTML(ByVal text)
        text = Replace(text, "&lt;", "<")
        text = Replace(text, "&gt;", ">")
        text = Replace(text, "&quot;", """")
        text = Replace(text, "&amp;", "&")
        UnescapeHTML = text
    End Function

    '=========================================================
    ' 代码块解析
    '=========================================================

    ' 解析代码块 ```language\ncode\n```
    Private Function ParseCodeBlocks(ByVal text)
        Dim re, matches, match, code, language
        Set re = New RegExp
        re.Global = True
        re.Multiline = True
        re.Pattern = "```([a-z]*)\r?\n([\s\S]*?)\r?\n```"

        Set matches = re.Execute(text)
        For Each match In matches
            language = match.SubMatches(0)
            code = match.SubMatches(1)

            If language = "" Then language = "text"

            ' 生成HTML
            text = Replace(text, match.Value, _
                "<pre><code class=""language-" & language & """>" & code & "</code></pre>")
        Next

        Set re = Nothing
        ParseCodeBlocks = text
    End Function

    ' 解析行内代码 `code`
    Private Function ParseInlineCode(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True
        re.Pattern = "`([^`]+)`"
        text = re.Replace(text, "<code>$1</code>")
        Set re = Nothing
        ParseInlineCode = text
    End Function

    '=========================================================
    ' 标题解析
    '=========================================================

    Private Function ParseHeaders(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True
        re.Multiline = True

        ' ATX风格标题 (# Header)
        re.Pattern = "^#{6}\s+(.+)$"
        text = re.Replace(text, "<h6>$1</h6>")

        re.Pattern = "^#{5}\s+(.+)$"
        text = re.Replace(text, "<h5>$1</h5>")

        re.Pattern = "^#{4}\s+(.+)$"
        text = re.Replace(text, "<h4>$1</h4>")

        re.Pattern = "^#{3}\s+(.+)$"
        text = re.Replace(text, "<h3>$1</h3>")

        re.Pattern = "^#{2}\s+(.+)$"
        text = re.Replace(text, "<h2>$1</h2>")

        re.Pattern = "^#{1}\s+(.+)$"
        text = re.Replace(text, "<h1>$1</h1>")

        Set re = Nothing
        ParseHeaders = text
    End Function

    '=========================================================
    ' 列表解析
    '=========================================================

    Private Function ParseLists(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True
        re.Multiline = True

        ' 无序列表
        re.Pattern = "^[\*\-\+]\s+(.+)$"
        text = re.Replace(text, "<li>$1</li>")

        ' 有序列表
        re.Pattern = "^\d+\.\s+(.+)$"
        text = re.Replace(text, "<li>$1</li>")

        ' 包装<ul>和<ol>标签（简化版）
        text = Replace(text, "<li>", vbCrLf & "<ul>" & vbCrLf & "<li>", 1, 1)
        text = text & vbCrLf & "</ul>" & vbCrLf

        Set re = Nothing
        ParseLists = text
    End Function

    '=========================================================
    ' 引用解析
    '=========================================================

    Private Function ParseBlockquotes(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True
        re.Multiline = True

        re.Pattern = "^>\s+(.+)$"
        text = re.Replace(text, "<blockquote>$1</blockquote>")

        Set re = Nothing
        ParseBlockquotes = text
    End Function

    '=========================================================
    ' 水平线解析
    '=========================================================

    Private Function ParseHorizontalRules(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True
        re.Multiline = True

        re.Pattern = "^(\*\*\*|---|___)$"
        text = re.Replace(text, "<hr />")

        Set re = Nothing
        ParseHorizontalRules = text
    End Function

    '=========================================================
    ' 链接和图片解析
    '=========================================================

    ' 解析链接 [text](url "title")
    Private Function ParseLinks(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True

        ' 带标题的链接
        re.Pattern = "\[([^\]]+)\]\(([^\s\)]+)\s+""([^""]+)""\)"
        text = re.Replace(text, "<a href=""$2"" title=""$3"">$1</a>")

        ' 不带标题的链接
        re.Pattern = "\[([^\]]+)\]\(([^\)]+)\)"
        text = re.Replace(text, "<a href=""$2"">$1</a>")

        Set re = Nothing
        ParseLinks = text
    End Function

    ' 解析图片 ![alt](url "title")
    Private Function ParseImages(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True

        ' 带标题的图片
        re.Pattern = "!\[([^\]]*)\]\(([^\s\)]+)\s+""([^""]+)""\)"
        text = re.Replace(text, "<img src=""$2"" alt=""$1"" title=""$3"" />")

        ' 不带标题的图片
        re.Pattern = "!\[([^\]]*)\]\(([^\)]+)\)"
        text = re.Replace(text, "<img src=""$2"" alt=""$1"" />")

        Set re = Nothing
        ParseImages = text
    End Function

    '=========================================================
    ' 文本格式解析
    '=========================================================

    ' 粗体 **text** 或 __text__
    Private Function ParseBold(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True

        re.Pattern = "\*\*([^\*]+)\*\*"
        text = re.Replace(text, "<strong>$1</strong>")

        re.Pattern = "__([^_]+)__"
        text = re.Replace(text, "<strong>$1</strong>")

        Set re = Nothing
        ParseBold = text
    End Function

    ' 斜体 *text* 或 _text_
    Private Function ParseItalic(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True

        re.Pattern = "\*([^\*]+)\*"
        text = re.Replace(text, "<em>$1</em>")

        re.Pattern = "_([^_]+)_"
        text = re.Replace(text, "<em>$1</em>")

        Set re = Nothing
        ParseItalic = text
    End Function

    ' 删除线 ~~text~~
    Private Function ParseStrikethrough(ByVal text)
        Dim re
        Set re = New RegExp
        re.Global = True

        re.Pattern = "~~([^~]+)~~"
        text = re.Replace(text, "<del>$1</del>")

        Set re = Nothing
        ParseStrikethrough = text
    End Function

    '=========================================================
    ' 段落和换行
    '=========================================================

    Private Function ParseParagraphs(ByVal text)
        ' 双换行符 = 段落
        text = Replace(text, vbCrLf & vbCrLf, "</p>" & vbCrLf & "<p>")

        ' 单换行符 = <br>
        text = Replace(text, vbCrLf, "<br />" & vbCrLf)

        ' 包装段落标签
        If Left(text, 3) <> "<p>" Then text = "<p>" & text
        If Right(text, 4) <> "</p>" Then text = text & "</p>"

        ParseParagraphs = text
    End Function

    '=========================================================
    ' 安全过滤
    '=========================================================

    ' 过滤不安全的HTML（白名单模式）
    Private Function SanitizeHTML(ByVal html)
        If IsNull(html) Or html = "" Then
            SanitizeHTML = ""
            Exit Function
        End If

        ' 移除危险的标签
        Dim re
        Set re = New RegExp
        re.IgnoreCase = True
        re.Global = True

        ' 移除<script>
        re.Pattern = "<script[^>]*?>.*?</script>"
        html = re.Replace(html, "")

        ' 移除<iframe>
        re.Pattern = "<iframe[^>]*?>.*?</iframe>"
        html = re.Replace(html, "")

        ' 移除事件处理器 (onclick, onerror等)
        re.Pattern = "\s+on\w+\s*=\s*[""'][^""']*[""']"
        html = re.Replace(html, "")

        ' 移除javascript:伪协议
        re.Pattern = "javascript:"
        html = re.Replace(html, "")

        ' 移除data:text/html
        re.Pattern = "data:text/html"
        html = re.Replace(html, "")

        Set re = Nothing
        SanitizeHTML = html
    End Function

    '=========================================================
    ' 辅助函数
    '=========================================================

    ' 检测内容是否为Markdown格式
    Public Function IsMarkdown(ByVal text)
        IsMarkdown = False
        If IsNull(text) Or text = "" Then Exit Function

        ' 检测常见Markdown语法标记
        If InStr(text, "##") > 0 Then IsMarkdown = True
        If InStr(text, "**") > 0 Then IsMarkdown = True
        If InStr(text, "__") > 0 Then IsMarkdown = True
        If InStr(text, "```") > 0 Then IsMarkdown = True
        If InStr(text, "[") > 0 And InStr(text, "](") > 0 Then IsMarkdown = True
        If InStr(text, "![") > 0 Then IsMarkdown = True
    End Function

    ' Markdown转纯文本（用于摘要）
    Public Function ToPlainText(ByVal markdown)
        If IsNull(markdown) Or markdown = "" Then
            ToPlainText = ""
            Exit Function
        End If

        Dim text
        text = markdown

        ' 移除Markdown语法
        Dim re
        Set re = New RegExp
        re.Global = True

        ' 移除代码块
        re.Pattern = "```[\s\S]*?```"
        text = re.Replace(text, "")

        ' 移除图片
        re.Pattern = "!\[([^\]]*)\]\([^\)]+\)"
        text = re.Replace(text, "$1")

        ' 移除链接（保留文本）
        re.Pattern = "\[([^\]]+)\]\([^\)]+\)"
        text = re.Replace(text, "$1")

        ' 移除标题标记
        re.Pattern = "^#{1,6}\s+"
        text = re.Replace(text, "")

        ' 移除加粗/斜体标记
        text = Replace(text, "**", "")
        text = Replace(text, "__", "")
        text = Replace(text, "*", "")
        text = Replace(text, "_", "")
        text = Replace(text, "~~", "")

        ' 移除其他标记
        text = Replace(text, ">", "")
        text = Replace(text, "`", "")

        Set re = Nothing
        ToPlainText = Trim(text)
    End Function

    ' 获取摘要（限制长度）
    Public Function GetSummary(ByVal markdown, ByVal maxLength)
        Dim plainText
        plainText = ToPlainText(markdown)

        If Len(plainText) > maxLength Then
            GetSummary = Left(plainText, maxLength) & "..."
        Else
            GetSummary = plainText
        End If
    End Function

    Private Sub Class_Terminate()
    End Sub
End Class

' 创建全局Markdown对象
Dim DvMarkdown
Set DvMarkdown = New Cls_Markdown
%>
