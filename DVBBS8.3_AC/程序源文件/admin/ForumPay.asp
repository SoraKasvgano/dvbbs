<!--#include file =../conn.asp-->
<!--#include file="inc/const.asp"-->
<!--#include file="../inc/dv_clsother.asp"-->
<%
Head()
Dim admin_flag
admin_flag=",9,"
CheckAdmin(admin_flag)
If Request("action")="readme" Then
	NetPay()
Else
	Main()
End If
If FoundErr Then Call Dvbbs_Error()
Footer()

Sub Main()
	Dim StartTime,EndTime,sType,KeyWord,IsSuc,MoneySize,PayMoney,SqlString
	StartTime = Request("StartTime")
	EndTime = Request("EndTime")
	sType = Request("sType")
	KeyWord = Replace(Request("keyword"),"'","''")
	MoneySize = Request("MoneySize")
	PayMoney = Request("PayMoney")
	IsSuc = Request("IsSuc")

	If IsSuc = "" Or Not IsNumeric(IsSuc) Then IsSuc = 0
	If IsSuc = 1 Then
		If SqlString = "" Then
			SqlString = " Where O_IsSuc = 1"
		Else
			SqlString = SqlString & " And O_IsSuc = 0"
		End If
	ElseIf IsSuc = 2 Then
	End If
	If StartTime <> "" And IsDate(StartTime) Then
		If SqlString = "" Then
			SqlString = " Where O_AddTime >= '"&StartTime&"'"
		Else
			SqlString = SqlString & " And O_AddTime >= '"&StartTime&"'"
		End If
	End If
	If EndTime <> "" And IsDate(EndTime) Then
		If SqlString = "" Then
			SqlString = " Where O_AddTime <= '"&EndTime&"'"
		Else
			SqlString = SqlString & " And O_AddTime <= '"&EndTime&"'"
		End If
	End If
	If sType = "" Or Not IsNumeric(sType) Then sType = 0
	If sType = 1 Then
		If SqlString = "" Then
			SqlString = " Where O_Type = 1"
		Else
			SqlString = SqlString & " And O_Type = 1"
		End If
	ElseIf sType = 2 Then
		If SqlString = "" Then
			SqlString = " Where O_Type = 2"
		Else
			SqlString = SqlString & " And O_Type = 2"
		End If
	End If
	If KeyWord <> "" Then
		If SqlString = "" Then
			SqlString = " Where (O_UserName Like '%"&keyword&"%' Or O_PayCode Like '%"&keyword&"%')"
		Else
			SqlString = SqlString & " And (O_UserName Like '%"&keyword&"%' Or O_PayCode Like '%"&keyword&"%')"
		End If
	End If
	If MoneySize = "" Or Not IsNumeric(MoneySize) Then MoneySize=0
	MoneySize = Cint(MoneySize)
	If PayMoney <> "" And IsNumeric(PayMoney) Then
		If MoneySize = 0 Then
			If SqlString = "" Then
				SqlString = " Where O_PayMoney > "&PayMoney&""
			Else
				SqlString = SqlString & " And O_PayMoney > "&PayMoney&""
			End If
		Else
			If SqlString = "" Then
				SqlString = " Where O_PayMoney < "&PayMoney&""
			Else
				SqlString = SqlString & " And O_PayMoney < "&PayMoney&""
			End If
		End If
	End If

	Dim Page,MaxRows,Endpage,CountNum,PageSearch
	PageSearch = "StartTime="&StartTime&"&EndTime="&EndTime&"&keyword="&KeyWord&"&sType="&sType&"&IsSuc="&IsSuc&"&MoneySize="&MoneySize&"&PayMoney="&PayMoney&""
	Endpage = 0
	MaxRows = 20
	Page = Request("Page")
	If IsNumeric(Page) = 0 or Page="" Then Page=1
	Page = Clng(Page)
	Response.Write "<script language=""JavaScript"" src=""../inc/Pagination.js""></script>"
%>
<table width="100%" border="0" cellspacing="1" cellpadding="3" align="center">
<tr><th style="text-align:center;">????????????????</th></tr>
<tr><td class="td1" style="line-height : 18px ;">
<B>????</B>??<BR>
1????????????????????????????????????????????????????????<a href="Challenge.asp"><font color=red>??????????????????????????</font></a><BR>
2??????????????????VIP??????????????????????????????????????????<BR>
3????????????????????????????????????????????????????????????????????????????????????????????????<BR>
4??????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
</td>
</tr>
<FORM METHOD=POST ACTION="ForumPay.asp">
<tr>
<td class="td1" style="line-height : 18px ;">
<B>????</B>??????????????????????????????????????????????????????????????????????????????????????????????
</td>
</tr>
<tr>
<td class="td1" style="line-height : 18px ;">
????????
<input size=15 name="keyword" type=text value="<%=keyword%>">
??????????
<input size=15 name="StartTime" type=text value="<%=StartTime%>">
??????????
<input size=15 name="EndTime" type=text value="<%=EndTime%>">
??????yyyy-mm-dd
</td>
</tr>
<tr>
<td class="td1" style="line-height : 18px ;">
????????
<Select Size=1 Name="sType">
<Option value=0>????</Option>
<Option value=1 <%If sType = 1 Then Response.Write "Selected"%>>????????</Option>
<Option value=2 <%If sType = 2 Then Response.Write "Selected"%>>????????</Option>
</Select>
??????????
<Select Size=1 Name="IsSuc">
<Option value=0>????</Option>
<Option value=1 <%If IsSuc = 1 Then Response.Write "Selected"%>>????</Option>
<Option value=2 <%If IsSuc = 2 Then Response.Write "Selected"%>>????</Option>
</Select>
??????????
????
<input type=radio class="radio" value="0" name="MoneySize" <%If MoneySize = 0 Then Response.Write "Checked"%>>
????
<input type=radio class="radio" value="1" name="MoneySize" <%If MoneySize = 1 Then Response.Write "Checked"%>>
<input type=text size=10 name="PayMoney" value="<%=PayMoney%>">
<input name="submit" value="????????" type=Submit class="button">
</td>
</tr>
</FORM>
</table><br>
<table width="100%" border="0" cellspacing="1" cellpadding="3" align="center">
<tr>
<th width="150">??????</th>
<th>??????</th>
<th width="35">????</th>
<th width="70">????????</th>
<th width="35">????</th>
<th width="100">????????</th>
</tr>
<%
	'Response.Write SqlString
	Dim PageAmount,AllAmount,Rs,Sql,i
	PageAmount = 0
	AllAmount = 0
	Set Rs = Dvbbs.Execute("Select Sum(O_PayMoney) From Dv_ChanOrders "&SqlString&"")
	AllAmount = Rs(0)
	If IsNull(AllAmount) Then AllAmount = 0
	Set Rs = Dvbbs.iCreateObject ("adodb.recordset")
	Sql = "Select O_PayMoney,O_UserName,O_PayCode,O_Type,O_IsSuc,O_AddTime From Dv_ChanOrders "&SqlString&" Order By O_ID Desc"
	If Not IsObject(Conn) Then ConnectionDatabase
	Rs.Open Sql,conn,1,1
	If Rs.Eof And Rs.Bof Then
		Response.Write "<tr><td class=td1 height=23 colspan=6>??????????????????????</td></tr>"
	Else
		CountNum = Rs.RecordCount
		If CountNum Mod MaxRows=0 Then
			Endpage = CountNum \ MaxRows
		Else
			Endpage = CountNum \ MaxRows+1
		End If
		Rs.MoveFirst
		If Page > Endpage Then Page = Endpage
		If Page < 1 Then Page = 1
		If Page >1 Then 				
			Rs.Move (Page-1) * MaxRows
		End if
		SQL=Rs.GetRows(MaxRows)
		For i=0 To Ubound(SQL,2)
			PageAmount = PageAmount + SQL(0,i)
%>
<tr align=center>
<td class="td1" height=23><a href="../dispuser.asp?name=<%=Server.HtmlEncode(SQL(1,i))%>" target=_blank><%=Server.HtmlEncode(SQL(1,i))%></a></td>
<td class="td1"><%=SQL(2,i)%></td>
<td width="35" class="td1"><%=SQL(0,i)%></td>
<td width="70" class="td1">
<%
Select Case SQL(3,i)
Case 1
	Response.Write "????????"
Case 2
	Response.Write "????????"
End Select
%>
</td>
<td width="35" class="td1">
<%
Select Case SQL(4,i)
Case 0
	Response.Write "<font color=gray>????</font>"
Case 1
	Response.Write "????"
End Select
%>
</td>
<td><%=FormatDateTime(SQL(5,i),2)%>&nbsp;<%=FormatDateTime(SQL(5,i),4)%></td>
</tr>
<%
		Next
	End If
	Rs.Close
	Set Rs=Nothing
	Response.Write "<tr><td class=td1 height=23 colspan=6><B>????????????</B>??<B>"&PageAmount&"</B> ??????????<B>??????????????????</B>??<B>"&AllAmount&"</B> ????????</td></tr>"
	Response.Write "</table>"
	PageSearch=Replace(Replace(PageSearch,"\","\\"),"""","\""")
	If CountNum > 0 Then Response.Write "<SCRIPT>PageList("&Page&",3,"&MaxRows&","&CountNum&","""&PageSearch&""",1);</SCRIPT>"
End Sub

Sub NetPay()
%>
<table width="100%" border="0" cellspacing="1" cellpadding="3" align="center">
<tr><th style="text-align:center;">????????????????????????</th></tr>
<tr>
<td class="td1" style="line-height : 18px ;">
<B>????????</B>??<BR>
1??????????????????????????????????????????????????????????????????????????????????????<BR>
2????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????<BR>
3???????????????????????????????????????????????????????????????????????????? <B>2%</B>???????????????????????????? <B>1</B> ????????<BR>
4??????????????????????????????????????????????????????????????????????????????????????????????????????????????????<BR>
5????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
<p></p>
<B>??????????????????????</B>??
<p></p>
<a href="http://www.dvbbs.net/netpay/pay.rar"><font color=red>??????????????????????????????????</font></a>
<p></p>
<B>??????????????????????????</B><BR>
??????????????????????????????????????????????????
<p></p>
<B>??????????????????????</B><BR>
1????????????????????????????02 + ????????ID + ????(yyyymmddhhMMss) + 5????????????????????????????????????????????????????020000000012005031513355519597??????000000001??????????ID??20050315133555????????????????????????????????????????????2??????????0??????????03????3??????19597????????<BR>
2??????????????????????????????????????????????????paycode??????????????????????username????????????????????????????returnurl????????????????????paymoney??<BR>
3??????????????????????????????????????????????????????????????????????????????????????????????????????<BR>
4??????????????post????????????http://server.dvbbs.net/alipay_t1.aspx?action=pay
<p></p>
<B>??????????????????????</B><BR>
1??Get????????????????????????????????success??????????????????paycode????????????????????sign??<BR>
2????????????<BR>
????A. success=1????????????0??????????<BR>
????B. ??????????????????????????????????????????????????????????????????????????????????????????????MD5????32??????????????????????:??????????????:????????:????????????????????????????????????key????????????????????????????????????????????????????????????????????????????(sign)????????????????????????<BR>
3????????????????????????????????????????????????????????
<p></p>
<B>??????????????????????</B><BR>
????????????????????????????????<BR>
????????????????????????????????????????????????????????????????????????????????????????????????<BR>
??????????????????post????????????http://server.dvbbs.net/alipay_t1.aspx?action=pay_1
</td>
</tr>
</table><P>
<%
End Sub
%>