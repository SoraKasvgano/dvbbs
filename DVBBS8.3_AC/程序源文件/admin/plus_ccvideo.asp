<!--#include File="../Conn.Asp"-->
<!-- #include File="Inc/Const.Asp" -->
<!-- #include File="../Inc/Md5.Asp" -->
<!-- #include File="../Inc/Chkinput.Asp" -->
<%
Dim Admin_flag,Forum_api,Ccvideo_api,Action,Ccvideo,Boardlist,Rs,Sql,ccvideoid,ccvideotype,Xmldoc,Ccid,Cclist,Iscclist,Ccvideobtn,Xmldom,Adslist
Admin_flag=",2,"
Checkadmin(Admin_flag)
ccvideotype="Dvbbs"

Chkforum_api()
Head()
If Request("T")="1" Then
	Cc_save()
Else
	Page_main()
End If
Footer()
Set Ccvideo = Nothing
Set Forum_api = Nothing
Set Ccvideo_api = Nothing
Set Adslist = Nothing

Sub Chkforum_api()
	Set Rs = Dvbbs.Execute("Select Top 1 Forum_apis From Dv_setup")
	Xmldoc = Rs(0)
	Rs.Close
	Set Rs = Nothing
	If Isnull(Xmldoc) Or Xmldoc = "" Then
		Creat_forum_api("Y")
	Else
		Set Forum_api = Server.Createobject("Msxml2.Freethreadeddomdocument"& Msxmlversion)
		Forum_api.Loadxml(Xmldoc)
		Set Ccvideo_api = Forum_api.Documentelement.Selectsinglenode("ccvideo")
		Testapi()
	End If
End Sub
Sub Testapi()
	On Error Resume Next
	Dim testcc
	testcc=Ccvideo_api.Getattribute("ccvideoid")
	If Err Then
		Creat_forum_api("")
	End If
End Sub
Sub Creat_forum_api(Str)
	If Str="Y" Then
		Set Forum_api = Server.Createobject("Msxml2.Freethreadeddomdocument"& Msxmlversion)
		Forum_api.Loadxml("<Forum_api/>")
	End If
	Set Ccvideo_api = Forum_api.Documentelement.Appendchild(Forum_api.Createnode(1,"ccvideo",""))
	Ccvideo_api.Setattribute "ccvideoid","97510"
	Ccvideo_api.Setattribute "ccvideobtn","Plugin_1"
	Ccvideo_api.Setattribute "ccvideotype",ccvideotype
	Ccvideo_api.Setattribute "boardlist",",0,"
	Update_forum_api()
End Sub
Sub Update_forum_api()
	Dvbbs.Execute("Update Dv_setup Set Forum_apis='"&Dvbbs.Checkstr(Forum_api.Xml)&"'")
End Sub
Sub Cc_save()
	Ccid=Dvbbs.Checkstr(Request("Ccid"))
	Ccvideobtn=Dvbbs.Checkstr(Request("Ccvideobtn"))
	Boardlist=Replace(Dvbbs.Checkstr(Request("Boardlist"))," ","")
	Ccvideo_api.Setattribute  "ccvideoid",Ccid
	Ccvideo_api.Setattribute  "ccvideobtn",Ccvideobtn
	Ccvideo_api.Setattribute  "ccvideotype",ccvideotype
	Ccvideo_api.Setattribute  "boardlist",","&Boardlist&","
	Update_forum_api()
	Dv_suc("??????????")
End Sub 
Sub Page_main()
ccvideoid=Ccvideo_api.Getattribute("ccvideoid")
Boardlist=Ccvideo_api.Getattribute("boardlist")
Ccvideobtn=Ccvideo_api.Getattribute("ccvideobtn")
%>
<table cellpadding="3" cellspacing="1" border="0" align="center" width="100%">
	<tr>
		<th colspan="2" style="text-align: center;">Cc????????????</th>
	</tr>
	<tr>
		<td width="20%" class="td1" align="center">
		<button style="width: 80; height: 50; border: 1px outset;" class="button">
		????????</button></td>
		<td width="80%" class="td2">
		<li>????CC????????,????????<a href="http://union.bokecc.com/signup.bo" target="_blank"><font color="red">????</font></a>????CC????????????</li>
		<li>????????????,????????????????,????????????????????CC??????</li>
		</td>
	</tr>
</table>
<br />
<table border="0" cellspacing="1" cellpadding="3" align="center" width="100%">
	<tr>
		<th colspan="3" style="text-align: center;">Cc????????????</th>
	</tr>
	<form method="post" action="">
		<input type="hidden" name="t" value="1" />
		<tr>
			<td align="right" width="25%">????Cc????ID??</td>
			<td colspan="2">
			<input type="text" name="CCID" size="30" value="<%=ccvideoid%>" id="ccvideouserid" />&nbsp;&nbsp;
			<font class="font1">??????????CC????????????ID,????????,??????<a href="http://union.bokecc.com/signup.bo" target="_blank"><font color="red">????</font></a>????</font></td>
		</tr>
		<tr>
			<td align="right" width="25%">????????????????</td>
			<td width="6%">
			<select id="ccvideobtn" onchange="showbtnpre()" name="ccvideobtn">
<script language="javascript">
<!--
var plgnamelist=[
	["????????","plugin"],
	["????????","plugin_2"],
	["????????","plugin_3"],
	["????????","plugin_4"],
	["????????","plugin_5"],
	["????????","plugin_6"],
	["????????","plugin_7"],
	["????????","plugin_8"],
	["????????","plugin_9"],
	["????????","plugin_10"],
	["????????","plugin_11"],
	["????????","plugin_12"],
	["????????","plugin_13"],
	["????????","plugin_14"],
	["????????","plugin_15"],
	["????????","plugin_16"]
];
for (var i in plgnamelist){
	document.writeln('<option value="'+plgnamelist[i][1]+'"');
	if ('<%=Ccvideobtn%>'==plgnamelist[i][1]) document.writeln(' selected');
	document.writeln('>'+plgnamelist[i][0]);
	document.writeln('</option>');
}
//-->
</script>
			</select> </td>
			<td id="ccvideobtnpre" width="67%">
			<object height="22" width="86">
				<param name="wmode" value="transparent" />
				<param name="allowScriptAccess" value="always" />
				<param name="movie" value="http://union.bokecc.com/flash/<%=Ccvideobtn%>.swf?userID=97510&amp;type=<%=ccvideotype%>" />
				<embed src="http://union.bokecc.com/flash/<%=Ccvideobtn%>.swf?userID=97510&amp;type=<%=ccvideotype%>" type="application/x-shockwave-flash" width="86" height="22" allowfullscreen="true" />
			</object>
			</td>
		</tr>
		<script language="javascript">
    function showbtnpre(){
    	btn=document.getElementById("ccvideobtn").value;
    	userid=document.getElementById("ccvideouserid").value
    	btnurl="http://union.bokecc.com/flash/"+btn+".swf?userID="+userid+"&type=<%=ccvideotype%>";
    	cchtml="<param name='wmode' value='transparent' /><param name='allowScriptAccess' value='always' /><param name='movie' value='"+btnurl+"' /><embed src='"+btnurl+"' type='application/x-shockwave-flash' width='86' height='22' allowFullscreen=true ></embed></object>";
    	document.getElementById("ccvideobtnpre").innerHTML=cchtml;
    }
   </script>
		<tr>
			<td align="right" width="25%">??????????????<br />
			???? Ctrl ???? Shift ??????<br />
			????????????</td>
			<td colspan="2">
			<select name="boardlist" size="20" style="width: 270px" multiple>
			<option value="0" style="color: #FF0000; background-color: #FFFFCC;" <%if Instr(boardlist,",0,")>0 Then Response.Write " selected"%>="">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; 
			????????????????????????</option>
			<%
		Dim ii
		set rs=Dvbbs.Execute("select boardid,boardtype,depth from dv_board order by rootid,orders")
		do while not rs.eof
			Response.Write "<option "
			if Instr(boardlist,","&rs(0)&",")>0 then
				Response.Write " selected"
			end if
			Response.Write " value="&rs(0)&">"
			Select Case rs(2)
				Case 0
					Response.Write "??"
				Case 1
					Response.Write "&nbsp;&nbsp;??"
			End Select
			If rs(2)>1 Then
				For ii=2 To rs(2)
					Response.Write "&nbsp;&nbsp;??"
				Next
				Response.Write "&nbsp;&nbsp;??"
			End If
			Response.Write rs(1)
			Response.Write "</option>"
			rs.movenext
		loop
		rs.close
		set rs=nothing
		%></select> </td>
		</tr>
		<tr>
			<td class="td2" colspan="3" align="center">
			<input type="submit" name="submit" value="????????" /> </td>
		</tr>
	</form>
</table>
<%
End sub
%>