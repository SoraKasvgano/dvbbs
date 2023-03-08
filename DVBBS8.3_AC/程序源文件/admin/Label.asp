<!--#include file="../conn.asp"-->
<!--#include file="inc/const.asp"-->
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=gb2312" />
<script src="../inc/main82.js" type="text/javascript"></script>
<script src="inc/admin.js" type="text/javascript"></script>
<script language="javascript" src="../dv_edit/main.js"></script>
<link href="skins/css/main.css" rel="stylesheet" type="text/css" />
<TITLE>Label</TITLE>
<style type="text/css">
body  { margin:0px; background:#fff; margin:0px; padding:10px; font:normal 12px 宋体; 
SCROLLBAR-FACE-COLOR: #C9DEFA; SCROLLBAR-HIGHLIGHT-COLOR: #C9DEFA; 
SCROLLBAR-SHADOW-COLOR: #337ABB; SCROLLBAR-DARKSHADOW-COLOR: #C9DEFA; 
SCROLLBAR-3DLIGHT-COLOR: #C9DEFA; SCROLLBAR-ARROW-COLOR: #264580;
SCROLLBAR-TRACK-COLOR: #EEF7FD; 
}
a { color: #135294; text-decoration: none; }
a:hover { color: #ff6600; text-decoration: underline; }
td { height:24px; line-height:20px; background:#fff; font-size:12px; border:1px solid #fff; color:#444; padding:2px; }
table { background:#C4D8ED; }
.td_title { height:24px; line-height:24px; background:#EEF7FD; color:#135294; font-weight:bold; border:1px solid #fff; padding-left:20px;  }
input { border:1px solid #999;font-family:verdana; }
select { font-family:verdana; }
.button { color: #135294; border:1px solid #666; height:21px; line-height:21px; background:url("images/button_bg.gif")}
.radio { border:none; }
.checkbox { border:none; }

a.folder{
float:left;
color:#135294;
width:100px;height:100px;border:1px #C4D8ED solid;
padding:5px;margin:5px;
text-align:center;padding-top:30px;
font-size:14px;font-family:verdana;
cursor:pointer;
text-decoration: none;
overflow:hidden;
background-image:url(skins/images/label_folder.gif);
background-repeat:no-repeat;
background-position:center;
}
a:hover.folder{
border:2px #135294 solid;
text-decoration: none;
background-position:center;
}
a.folder em {
display:none;
}
a:hover.folder em {
font-style:normal;font-size:12px;
color:#666666;
font-family:verdana;
font-weight:lighter;
display:inline;
}

a.file{
float:left;
color:#135294;
width:100px;height:100px;border:1px #C4D8ED solid;
padding:5px;margin:5px;
text-align:center;padding-top:30px;
font-size:14px;font-family:verdana;font-weight:bold;
cursor:pointer;
text-decoration: none;
overflow:hidden;
background-image:url(skins/images/label_file.gif);
background-repeat:no-repeat;
}
a:hover.file{
border:2px #135294 solid;
text-decoration: none;
}
a.file em {
display:none;
}
a:hover.file em {
font-style:normal;font-size:12px;
color:#666666;
font-family:verdana;
font-weight:lighter;
display:inline;
}
</style>
<%
Dim admin_flag
admin_flag=",23,"
CheckAdmin(admin_flag)
%>
<body onload="$('format_time').innerHTML=Label_FormatTime($('label_intv').value)">
<%
Dvbbs.ScriptPath="../Resource/Label"
Dim G_CurrentFolder, G_ParentFolder, G_Msg, G_i, G_Do, G_Config

G_Do = request("do")

G_CurrentFolder = request("folder")
G_CurrentFolder = Replace(G_CurrentFolder, ".", "")
If ""=G_CurrentFolder Or "/"=G_CurrentFolder Then
	G_CurrentFolder = "/"
Else
	G_ParentFolder = InstrRev(G_CurrentFolder,"/",Len(G_CurrentFolder)-1)
	If G_ParentFolder>0 Then 
		G_ParentFolder = Left(G_CurrentFolder, G_ParentFolder)
	Else
		G_ParentFolder = ""
	End If 
End If 

Select Case G_Do
	Case "save_label" SaveLabel
	Case "del_label"  DelLabel
End Select 

Function CreateFSO()
	On Error Resume Next 
	Set CreateFSO = Dvbbs.iCreateObject("Scripting.FileSystemObject")
	If Err Then 
		Err.Clear
		response.write "您的空间不支持FSO，或者FSO对象名由于安全原因被更改过，请与空间商联系！<a href='javascript:history.go(-1)'>[返回上一次操作的页面]</a>"
		response.End 
	End If 
End Function 

Sub ListLabelFolder(sLabelPath)
	Dim Fso, Folder, File, SubFolder, sTemp, sRealPath
	On Error Resume Next 
	Set Fso	= CreateFSO() 
	sRealPath = Server.MapPath(Dvbbs.ScriptPath & sLabelPath)
	Set Folder = Fso.GetFolder(sRealPath) 
	If Err Then
		Err.Clear
		response.write "传递过来的标签目录有误，或者您的空间不支持获取目录操作，请与空间商联系！<a href='javascript:history.go(-1)'>[返回上一次操作的页面]</a>"
		response.End 
	End If 
	If "/"<>sLabelPath Then
		If ""<>G_ParentFolder And "/"<>G_ParentFolder Then response.write "<a href='?folder=' class=folder title='返回根目录'>/<br/><em>返回根目录</em></a>"
		response.write "<a href='?folder=" & G_ParentFolder & "' class=folder title='返回上一级目录'>../<br/><em>返回上一级目录</em></a>"
	End If 
	G_i = 0
	For Each SubFolder In Folder.Subfolders
		G_i = G_i + 1
		response.write "<a href='?folder=" & sLabelPath & SubFolder.name & "/' class=folder  title='标签目录：" & SubFolder.name & VBNewline & "点击打开该目录'>" & SubFolder.name & "<br/><em>有" & SubFolder.Subfolders.Count & "个目录</em><br/><em>有" & SubFolder.Files.Count & "个标签</em></a>"
	Next 
	For Each File In Folder.Files
		G_i = G_i + 1
		response.write "<a href='?do=edit_label&realdo=edit&file=" & File.name & "&folder=" & sLabelPath & "' class=file title='标签名：" & File.name & VBNewline & "点击编辑该标签'>" & File.name & "<br><em>" & File.DateLastModified & "</em></a>"
	Next 
	Set File = Nothing 
	Set Fso	= Nothing 
	If 0=G_i Then
		response.write "没有找到自定义标签。您可以在下面的表格中添加："
	End If 
End Sub 

Sub SaveLabel()
	Select Case request("label_type")
		Case "static"
			SaveStaticLabel
		Case "rss"
			SaveRssLabel
		Case "query"
			SaveQueryLabel
	End Select 
End Sub 

Sub DelLabel()
	Dim Fso, sLabelPath, sLabelName, sRealPath
	sLabelPath=request("folder")
	sLabelName=request("label_name")
	If IsSafeParam(sLabelPath,"^[a-zA-Z0-9_\/]+$") And IsSafeParam(sLabelName,"^[a-zA-Z0-9_]+$") Then 
		On Error Resume Next 
		sRealPath=Server.MapPath(Dvbbs.ScriptPath&sLabelPath&sLabelName&".tpl")
		If Err Then 
			G_Msg="<font color=red>传递过来的路径不规范。请到空间上手动删除该文件。</font>"
		Else 
			Set Fso=CreateFSO()
			If Fso.FileExists(sRealPath) Then
				Fso.DeleteFile sRealPath,True
				If Err Then
					Err.Clear
					G_Msg="<font color=red>在删除标签文件时发生错误，可能是没有足够的权限。请到空间上手动删除此标签文件。</font>"
				Else
					G_Msg="<font color=green>成功删除标签："&sLabelName&"</font>"
				End If 
			Else
				G_Msg="<font color=red>标签文件没有找到。可能已经被删除，或者没有足够的权限。</font>"
			End If 
			Set Fso=Nothing 
		End If 
	Else
		G_Msg="<font color=red>传递过来的路径因为安全原因被禁止。请到空间上手动删除该文件。</font>"
	End If 
End Sub 

Sub SaveStaticLabel()
	Dim sSave, iIntv
	iIntv=Dvbbs.CheckNumeric(request("label_intv"))
	If 0=iIntv Then iIntv=72000
	sSave="static|||" & (iIntv & "|||" & request("label_content"))
	SaveLabelToFile sSave
End Sub 

Sub SaveRssLabel()
	Dim sSave, iIntv, sXslt, oXml
	sXslt=request("label_xslt")
	iIntv=Dvbbs.CheckNumeric(request("label_intv"))
	If 0=iIntv Then iIntv=7200
	sSave="rss|||" & (iIntv & "|||" & request("label_rss") & "|||" & sXslt)
	Set oXml=Dvbbs.CreateXmlDoc("msxml2.FreeThreadedDOMDocument"&MsxmlVersion)
	If oXml.loadXml(sXslt) Then 
		SaveLabelToFile sSave
	Else
		G_Msg="<font color=red>解释模板内容不规范，请修改后重新提交。</font>"
		G_Config=Split(sSave,"|||")
	End If 
End Sub 

Sub SaveQueryLabel()
	Dim sSave, iIntv, sQuery, sQueryType, sConfig, arr, s, sOrderbyID, sPreT, sPreB, d, desc
	iIntv=Dvbbs.CheckNumeric(request("label_intv"))
	If 0=iIntv Then iIntv=120
	sConfig=request("label_query_config")
	sQueryType=request("label_query_type")
	If ""=sQueryType Then sQueryType="bbs"
	sConfig=Dvbbs.CheckStr(sConfig)
	arr=Split(sConfig,"$")
	sQuery="select top "&arr(0)&" "
	sQueryType=Replace(sQueryType,"|||","")
	Select Case sQueryType
		Case "bbs" '0-调用记录条数$1-排序方式$2-正倒序$3-版面列表$4-版面模式$5-贴子类型(0-不限1-固顶主题2-精华主题3-回复贴子)$6-时间限制
			sPreT="":sPreB=""
			If "3"=arr(5) Then
				sQuery=sQuery&" UserName,Topic,Rootid,Boardid,Dateandtime,Announceid,Body,Expression from "&Dvbbs.NowUseBBS
				sOrderbyID="announceid"
			ElseIf "2"=arr(5) Then 
				sQuery=sQuery&" B.PostUserName, B.Title, B.Rootid as topicid, B.Boardid, B.Dateandtime as topictime, B.Announceid as postid, B.Id as bestid, B.Expression From Dv_BestTopic B INNER JOIN Dv_Topic T ON B.RootID = T.TopicID"
				sOrderbyID="B.id"
				sPreT="T.":sPreB="B."
			Else 
				sQuery=sQuery&" PostUserName,Title,Topicid,Boardid,Dateandtime,Topicid as Topicid2,Hits,Expression,LastPost from [dv_topic]"
				If "1"=arr(5) Then sQuery=sQuery&" where istop>0"
				sOrderbyID="topicid"
			End If 
			If InStr(sQuery," where ")>0 Then 
				sQuery=sQuery&" and"
			Else
				sQuery=sQuery&" where"
			End If
			sQuery=sQuery&(" "&sPreB&"boardid")
			If ""<>arr(3) Then
				If InStr(arr(3),",")>0 Then
					If "1"=arr(4) Then
						sQuery=sQuery&" not in (444,777,"
					Else
						sQuery=sQuery&" in ("
					End If 
					sQuery=sQuery&arr(3) & ")"
				Else
					If "1"=arr(4) Then
						sQuery=sQuery&"<>"
					Else
						sQuery=sQuery&"="
					End If 
					sQuery=sQuery&arr(3)
				End If 
			Else
				sQuery=sQuery&" not in(444,777)"
			End If
			If "0"<>arr(6) Then 
				d=0
				Select Case arr(6)
					Case "1" d=7
					Case "2" d=30
					Case "3" d=3*30
					Case "4" d=6*30
					Case "5" d=12*30
				End Select 
				If d>0 Then 
					If InStr(sQuery," where ")>0 Then 
						sQuery=sQuery&" and"
					Else
						sQuery=sQuery&" where"
					End If 
					If IsSqlDataBase=1 Then
						sQuery=sQuery&" Datediff(day, "&sPreB&"DateAndTime, " & SqlNowString & ") <= " & d
					Else
						sQuery=sQuery&" Datediff('d', "&sPreB&"DateAndTime, " & SqlNowString & ") <= " & d
					End If
				End If 
			End If 
			Select Case arr(1)
				Case "1"
					sQuery=sQuery&(" order by "&sOrderbyID)
				Case "2"
					If "3"<>arr(5) Then sQuery=sQuery&(" order by "&sPreT&"LastPostTime")
				Case "3"
					If "3"<>arr(5) Then sQuery=sQuery&(" order by "&sPreT&"hits")
				Case "4"
					If "3"<>arr(5) Then sQuery=sQuery&(" order by "&sPreT&"Child")
			End Select 
			If InStr(sQuery, " order by")>0 Then
				If "1"=arr(2) Then sQuery=sQuery&" desc"
				If "1"<>arr(1) Then sQuery=sQuery&","&sOrderbyID&" desc"
			End If 
		Case "user"
			sQuery=sQuery&"UserID,UserName,UserTopic,UserPost,UserIsBest,UserWealth,UserCP,UserEP,UserDel,UserSex,JoinDate,UserLogins From [Dv_user]"
			Select Case arr(1)
				Case "1"
					sQuery=sQuery&" order by UserID"
				Case "2"
					sQuery=sQuery&" order by UserPost"
				Case "3"
					sQuery=sQuery&" order by UserTopic"
				Case "4"
					sQuery=sQuery&" order by UserIsBest"
				Case "5"
					sQuery=sQuery&" order by UserWealth"
				Case "6"
					sQuery=sQuery&" order by UserEP"
				Case "7"
					sQuery=sQuery&" order by UserCP"
				Case "8"
					sQuery=sQuery&" order by UserDel"
				Case "9"
					sQuery=sQuery&" order by UserLogins"
			End Select
			If InStr(sQuery, " order by")>0 And "1"=arr(2) Then sQuery=sQuery&" desc"
		Case "news"
			sQuery=sQuery&"ID,Boardid,Title,UserName,AddTime FROM [Dv_bbsnews]"
			If ""<>arr(3) Then
				If InStr(sQuery," where ")>0 Then 
					sQuery=sQuery&" and"
				Else
					sQuery=sQuery&" where"
				End If 
				sQuery=sQuery&" boardid"
				If InStr(arr(3),",")>0 Then
					If "1"=arr(4) Then sQuery=sQuery&" not"
					sQuery=sQuery&" in (" & arr(3) & ")"
				Else
					If "1"=arr(4) Then
						sQuery=sQuery&"<>"
					Else
						sQuery=sQuery&"="
					End If 
					sQuery=sQuery&arr(3)
				End If 
			End If
			If "1"=arr(1) Then 
				sQuery=sQuery&" order by ID"
				If "1"=arr(2) Then sQuery=sQuery&" desc"
			End If 
		Case "file"
			sQuery=sQuery&" F_ID,F_AnnounceID,F_BoardID,F_Username,F_Filename,F_Readme,F_Type,F_FileType,F_AddTime,F_Viewname,F_ViewNum,F_DownNum,F_FileSize FROM [DV_Upfile] WHERE F_Flag<>4"
			If ""<>arr(3) Then
				sQuery=sQuery&" and F_BoardID"
				If InStr(arr(3),",")>0 Then
					If "1"=arr(4) Then sQuery=sQuery&" not"
					sQuery=sQuery&" in (" & arr(3) & ")"
				Else
					If "1"=arr(4) Then
						sQuery=sQuery&"<>"
					Else
						sQuery=sQuery&"="
					End If 
					sQuery=sQuery&arr(3)
				End If 
			End If
			If "all"<>arr(5) Then
				sQuery=sQuery&(" and F_Type="&Dvbbs.CheckNumeric(arr(5)))
			End If 
			Select Case arr(1)
				Case "1"
					sQuery=sQuery&(" order by F_ID")
				Case "2"
					sQuery=sQuery&(" order by F_ViewNum")
				Case "3"
					sQuery=sQuery&(" order by F_DownNum")
				Case "4"
					sQuery=sQuery&(" order by F_FileSize")
			End Select
			If InStr(sQuery, " order by")>0 And "1"=arr(2) Then sQuery=sQuery&" desc"
		Case "group"
			sQuery=sQuery&"ID,GroupName,GroupInfo,AppUserID,AppUserName,UserNum,Stats,PostNum,TopicNum,TodayNum,YesterdayNum,LimitUser,PassDate,GroupLogo From [Dv_GroupName] Where Stats>0"
			Select Case arr(1)
				Case "1"
					sQuery=sQuery&(" order by ID")
				Case "2"
					sQuery=sQuery&(" order by PassDate")
				Case "3"
					sQuery=sQuery&(" order by UserNum")
				Case "4"
					sQuery=sQuery&(" order by TopicNum")
				Case "5"
					sQuery=sQuery&(" order by PostNum")
				Case "6"
					sQuery=sQuery&(" order by LimitUser")
			End Select
			If InStr(sQuery, " order by")>0 And "1"=arr(2) Then sQuery=sQuery&" desc"
	End Select 
	sSave="query|||" & (iIntv & "|||" & sQueryType & "|||" & sQuery & "|||" & request("label_template_start") & "|||" & request("label_template_loop") & "|||" & request("label_template_stop") & "|||" & sConfig & "|||" & request("label_mainshow_length") & "|||" & request("label_time_type"))
	'response.write "<pre>"&sSave&"</pre>"
	SaveLabelToFile sSave
End Sub 

Function FileIsExist(Path)
	Dim Fso:FileIsExist=False 
	On Error Resume Next 
	Set Fso=CreateFSO()
	If Fso.FileExists(Server.MapPath(Path)) Then FileIsExist=True 
	Set Fso=Nothing 
End Function 

Function FileReName(Path,NewName)
	Dim Fso,File
	FileReName=False 
	On Error Resume Next 
	Set Fso=CreateFSO()
	Set File=Fso.GetFile(Server.MapPath(Path))
	File.name=NewName
	Set File=Nothing 
	Set Fso=Nothing 
	FileReName=True 
End Function 

Function IsSafeParam(Path,Param)
	Dim re
	IsSafeParam=False 
	Set re=new RegExp
	re.IgnoreCase =True
	re.Global=True
	re.Pattern=Param
	IsSafeParam=re.Test(Path)
	Set Re=Nothing
End Function 

Sub SaveLabelToFile(Content)
	Dim sLabelPath, sLabelName, sLabelOldName, s
	sLabelPath=request("label_path")
	sLabelName=request("label_name")
	sLabelOldName=request("label_oldname")
	G_Msg=""
	If IsSafeParam(sLabelPath,"^[a-zA-Z0-9_\/]+$") Then 
		If IsSafeParam(sLabelName,"^[a-zA-Z0-9_]+$") Then
			If "add"=request("realdo") Then
				If FileIsExist(Dvbbs.ScriptPath&sLabelPath&sLabelName&".tpl") Then G_Msg="<font color=red>该标签名已存在，请修改标签名后重新提交。</font>"
			Else
				If sLabelOldName<>"" And sLabelOldName<>sLabelName Then 
					If FileIsExist(Dvbbs.ScriptPath&sLabelPath&sLabelName&".tpl") Then
						G_Msg="<font color=red>您试图修改标签名，但是该标签名已存在，请修改后重新提交。</font>"
					Else
						If IsSafeParam(sLabelOldName,"^[a-zA-Z0-9_]+$") Then 
							If Not FileReName(Dvbbs.ScriptPath&sLabelPath&sLabelOldName&".tpl", sLabelName&".tpl") Then 
								G_Msg="<font color=red>您试图修改标签名，但是没有成功。可能是权限不够。</font>"
							End If
						Else
							G_Msg="<font color=red>非法参数。请修改后重新提交。</font>"
						End If 
					End If 
				End If 
			End If 
			If ""=G_Msg Then 
				On Error Resume Next 
				Dvbbs.WriteToFile sLabelPath&sLabelName&".tpl", Content
				If Err Then 
					Err.Clear
					G_Msg="<font color=red>标签保存失败。可能您的标签文件夹（Resource/Label）及其子目录没有写入和修改权限。</font>"
				Else
					G_Msg="<font color=green>恭喜，标签保存成功！</font>"
					Application.Lock
					Application.Contents.Remove(Dvbbs.CacheName&"_label_"&LCase(Mid(sLabelPath,2)&sLabelName)&"_buffer")
					Application.unLock
				End If 
			End If 
		Else
			G_Msg="<font color=red>标签名不规范。标签名只能由字母、数字和下划线组成。请修改后重新提交。</font>"
		End If 
	Else
		G_Msg="<font color=red>保存目录名称不规范。目录名称只能由字母、数字和下划线组成。请到空间的相应文件夹中修改目录名。</font>"
	End If 
	G_Config=Split(Content,"|||")
End Sub 
%>

<SCRIPT LANGUAGE="JavaScript">
<!--
function $(i){return document.getElementById(i);}

function Label_Chk(o,restr){
	var re=new RegExp(restr);
	if (re.test(o.value)){
		$(o.name+"_chk").innerHTML="<font color=green><b>√</b></font>";
		return true;
	}else{
		$(o.name+"_chk").innerHTML="<font color=red><b>×</b></font>";
		return false;
	}
}
function Label_FormatTime(i){
	var t=0;
	if (i<60){t=i+'秒';}
	else if (i<3600){t=parseInt(i/60)+'分种';}
	else{t=parseInt(i/3600)+'小时';}
	return '当前缓存时间约'+t;
}
function Label_Submit(frm,e){
	var s,rtn=false; 
	if (Label_Chk(frm.label_name,/^[a-zA-Z0-9_\/]+$/gi)&&Label_Chk(frm.label_intv,/^[0-9]+$/gi)){rtn=true;}
	if (rtn){
		switch(frm.label_type.value){
			case 'static':
				s=label_content_edit.save();
				s=s.replace(/%7B/gi,'{'); s=s.replace(/%7D/gi,'}');
                s=s.replace(/http:.+?<%=replace(Dvbbs.CacheData(33,0),"/","\/")%>/gi,'');
				frm.label_content.value=s
				break;
			case 'rss':
				if (!Label_Chk(frm.label_rss,/^http:\/\//gi)){rtn=false;}
				break;
			case 'query':
				//frm.label_template_start.value=label_edit_template_start.save();
				s=label_edit_template_loop.save();
				s=s.replace(/%7B/gi,'{'); s=s.replace(/%7D/gi,'}');
                s=s.replace(/http:.+?<%=replace(Dvbbs.CacheData(33,0),"/","\/")%>/gi,'');
				frm.label_template_loop.value=s
				//frm.label_template_stop.value=label_edit_template_stop.save();
				frm.label_query_config.value=Label_Get_QueryConfig();
				break;
		}
	}
	if (rtn){
		frm.subtn.disabled=true;
		$("form_chk").innerHTML="<font color=green>检查通过，正在提交，请稍等..</font>";
	}else{
		frm.subtn.disabled=false;
		$("form_chk").innerHTML="<font color=red>检查未通过，请修改后重新提交。</font>";
		try{e.returnValue=false;}catch(er){e.preventDefault();}
	}
}
function Label_SelectMutiOption(selid,str){
	var s=','+str+',';
	for (var i=selid.length-1;i>=0;--i){
		if (-1!=s.indexOf(','+selid[i].value+',')){
			selid[i].selected=true;
		}
	}
}
function Label_GetSelectedValue(selid){
	var s='';
	for (var i=selid.length-1;i>=0;--i){
		if (''!=selid[i].value&&selid[i].selected){
			s+=','+selid[i].value;
		}
	}
	if (''!=s){s=s.substr(1,s.length-1);}
	return s;
}
function Label_Get_QueryConfig(){
	var a=[];
	a.push($('label_total').value);
	a.push(Label_GetSelectedValue($('label_order_by').options));
	a.push($('label_order_0').checked?0:1);
	switch(Label_GetSelectedValue($("label_query_type").options)){
		case 'bbs':
			a.push(Label_GetSelectedValue($('label_board').options));
			a.push($('label_board_0').checked?0:1);
			a.push($('label_bbstype_0').checked?0:($('label_bbstype_1').checked?1:($('label_bbstype_2').checked?2:3)));
			a.push(Label_GetSelectedValue($('label_time_limit').options));
			$('label_mainshow_length').value=$('label_title_length').value;
			break;
		case 'user':
			break;
		case 'news':
			a.push(Label_GetSelectedValue($('label_board').options));
			a.push($('label_board_0').checked?0:1);
			break;
		case 'file':
			a.push(Label_GetSelectedValue($('label_board').options));
			a.push($('label_board_0').checked?0:1);
			a.push(Label_GetSelectedValue($('label_file_type').options));
			$('label_mainshow_length').value=$('label_readme_length').value;
			break;
		case 'group':
			break;
	};
	return a.join('$');
}
function Label_Query_ChangeType(fromtype,totype,cfgstr,timetype){
	$('tr_board').style.display='none';
	$('tr_bbs').style.display='none';
	$('tr_file').style.display='none';
	$('label_order_by').length=null;
	$('label_order_by').options[0]=new Option('选择排序方式','0');
	var t=totype||'bbs',i=0;
	var c=cfgstr;
	var m=isNaN(timetype)?0:parseInt(timetype);
	var arr=c?c.split('$'):[];
	switch(t){
		case 'bbs':
			if(7!=arr.length||fromtype!=totype){c='10$1$1$$0$0$0';arr=c.split('$');}//0-调用记录条数$1-排序方式$2-正倒序$3-版面列表$4-版面模式$5-贴子类型$6-时间限制
			Label_SelectMutiOption($('label_board').options,arr[3]||'');
			$('label_board_0').checked=false;
			$('label_board_1').checked=false;
			$('label_board_'+arr[4]).checked=true;
			$('label_order_by').options[++i]=new Option('贴子ID（推荐）',i);
			$('label_order_by').options[++i]=new Option('最新回复时间',i);
			$('label_order_by').options[++i]=new Option('点击量',i);
			$('label_order_by').options[++i]=new Option('回复数',i);
			$('label_bbstype_0').checked=false;
			$('label_bbstype_1').checked=false;
			$('label_bbstype_2').checked=false;
			$('label_bbstype_'+arr[5]).checked=true;
			$('tr_board').style.display='';
			$('tr_bbs').style.display='';
			$('label_query_type').selectedIndex=1;
			$('label_time_limit').selectedIndex=arr[6]||0;
			break;
		case 'user':
			if(3!=arr.length||fromtype!=totype){c='10$1$1';arr=c.split('$');}//0-调用记录条数$1-排序方式$2-正倒序
			$('label_order_by').options[++i]=new Option('用户ID（推荐）',i);
			$('label_order_by').options[++i]=new Option('贴子数',i);
			$('label_order_by').options[++i]=new Option('主题数',i);
			$('label_order_by').options[++i]=new Option('精华数',i);
			$('label_order_by').options[++i]=new Option('金钱值',i);
			$('label_order_by').options[++i]=new Option('积分值',i);
			$('label_order_by').options[++i]=new Option('魅力值',i);
			$('label_order_by').options[++i]=new Option('被删贴数',i);
			$('label_order_by').options[++i]=new Option('登陆次数',i);
			$('label_query_type').selectedIndex=2;
			break;
		case 'news':
			if(5!=arr.length||fromtype!=totype){c='10$1$1$$0';arr=c.split('$');}//0-调用记录条数$1-排序方式$2-正倒序$3-版面列表$4-版面模式
			Label_SelectMutiOption($('label_board').options,arr[3]||'0');
			$('label_board_0').checked=false;
			$('label_board_1').checked=false;
			$('label_board_'+arr[4]).checked=true;
			$('label_order_by').options[++i]=new Option('公告ID',i);
			$('tr_board').style.display='';
			$('label_query_type').selectedIndex=3;
			break;
		case 'file':
			if(6!=arr.length||fromtype!=totype){c='10$1$1$$0$1';arr=c.split('$');}//0-调用记录条数$1-排序方式$2-正倒序$3-版面列表$4-版面模式$5-文件类型$6-后缀名
			Label_SelectMutiOption($('label_board').options,arr[3]||'0');
			$('label_board_0').checked=false;
			$('label_board_1').checked=false;
			$('label_board_'+arr[4]).checked=true;
			$('label_order_by').options[++i]=new Option('附件ID（推荐）',i);
			$('label_order_by').options[++i]=new Option('浏览次数',i);
			$('label_order_by').options[++i]=new Option('下载次数',i);
			$('label_order_by').options[++i]=new Option('文件大小',i);
			$('label_file_type').selectedIndex='all'==arr[5]?0:parseInt(arr[5])+1;
			$('tr_board').style.display='';
			$('tr_file').style.display='';
			$('label_query_type').selectedIndex=4;
			break;
	}
	$('label_total').value=arr[0];
	$('label_time_type').selectedIndex=m||0;
	$('label_order_by').selectedIndex=arr[1]||1;
	$('label_order_0').checked=false;
	$('label_order_1').checked=false;
	$('label_order_'+arr[2]).checked=true;
}
//-->
</SCRIPT>
<form name="form1" method="post" action="?do=save_label" onsubmit="Label_Submit(this,event)">
<table width="100%" border="0" cellspacing="1" cellpadding="0">
	<tr>
	<td width="170" class="td_title" style="border:0px;">自定义标签列表</td><td width="*" class="td_title" style="border:0px;"></td>
	</tr>
	<tr>
	<td align="left" colspan="2" valign="middle" style="height:140px;padding:10px;margin:10px;"><%ListLabelFolder G_CurrentFolder%></td>
	</tr>
	<tr>
	<td align="left" colspan="2" class="td_title">添加自定义标签[ <a href="?do=add&label_type=static&folder=<%=G_CurrentFolder%>" title="点这里添加一个静态标签">静态标签</a> - <a href="?do=add&label_type=rss&folder=<%=G_CurrentFolder%>" title="点这里添加一个RSS订阅标签">RSS订阅标签</a> - <a href="?do=add&label_type=query&folder=<%=G_CurrentFolder%>" title="点这里添加一个论坛内容调用标签">论坛内容调用标签</a> ]</td>
	</tr>
	<tr>
	<td align="right">三种标签的说明：</td>
	<td>① 静态标签：编辑之后，标签内容不会变化。适合于一些不常改动但多处使用的页面内容。 <br />
	② RSS订阅标签：订阅指定内容，定时更新内容。这些内容不限于本论坛。 <br />
	③ 论坛内容调用标签：可以调用论坛数据库中的内容，包括贴子、用户、版面等。<br />
	</td>
	</tr>
<%
Label_Form
Function GetDefaultSet(LabelType)
	Dim str
	Select Case LabelType
		Case "static"
			str="static|||72000|||这里是输出内容.."
		Case "rss"
			str="rss|||3600|||http://|||<?xml version=""1.0"" encoding=""gb2312""?>"&VBNewline&_
				"<xsl:stylesheet version=""1.0"" xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"">"&VBNewline&_
				"	<xsl:output method=""xml"" omit-xml-declaration = ""yes"" indent=""yes"" version=""4.0""/>"&VBNewline&_
				"	<xsl:template match=""/rss"">"&VBNewline&_
				"		<xsl:apply-templates select=""channel/item"" />"&VBNewline&_
				"	</xsl:template>"&VBNewline&_
				"	<xsl:template match=""item"">"&VBNewline&_
				"			<li><a href=""{link}"" target=""_blank"">"&VBNewline&_
				"				<a href=""{link}"" target=""_blank""><xsl:value-of select=""title"" /></a> <xsl:value-of select=""pubDate"" />"&VBNewline&_
				"			</a></li>"&VBNewline&_
				"	</xsl:template>"&VBNewline&_
				"</xsl:stylesheet>"
		Case "query"
			str="query|||100|||bbs||||||<ul>|||<li>&nbsp;</li>|||</ul>||||||20|||2"
	End Select 
	GetDefaultSet=str
End Function 

Sub Label_Form()
	Dim sLabelName,iLabelIntv,sRealDo,sLabelType,sLabelPath
	sRealDo=request("realdo")
	sLabelPath=G_CurrentFolder
	sLabelName="untitle_"&(G_i+1)
	If ""<>request("label_name") Then sLabelName=request("label_name")
	Select Case G_Do
		Case "edit_label"
			G_Msg=""
			sLabelName=Replace(request("file"),".tpl","")
			If IsSafeParam(sLabelPath,"^[a-zA-Z0-9_\/]+$") And IsSafeParam(sLabelName,"^[a-zA-Z0-9_]+$") Then
				If FileIsExist(Dvbbs.ScriptPath&sLabelPath&sLabelName&".tpl") Then
					On Error Resume Next 
					G_Config=Dvbbs.ReadTextFile(sLabelPath&sLabelName&".tpl")
					If Err Then 
						Err.Clear
						G_Msg="<font color=red>读取标签失败，可能是没有读取文件的权限。</font>"
						sRealDo="add"
					Else
						If InStr(G_Config,"|||")>0 Then 
							G_Config=Split(G_Config,"|||")
							Select Case G_Config(0)
								Case "static"
									If 2=UBound(G_Config) Then
										G_Msg="您正准备编辑一个静态标签。"
									Else
										G_Config=Split(GetDefaultSet("static"),"|||")
										G_Msg="<font color=red>标签格式不规范。您可以尝试填写下面的表格来替换它。</font>"
									End If 
								Case "rss"
									If 3=UBound(G_Config) Then
										G_Msg="您正准备编辑一个Rss订阅标签。"
									Else
										G_Config=Split(GetDefaultSet("rss"),"|||")
										G_Msg="<font color=red>标签格式不规范。您可以尝试填写下面的表格来替换它。</font>"
									End If 
								Case "query"
									If 9=UBound(G_Config) Then
										G_Msg="您正准备编辑一个论坛内容调用标签。"
									Else
										G_Config=Split(GetDefaultSet("query"),"|||")
										G_Msg="<font color=red>标签格式不规范。您可以尝试填写下面的表格来替换它。</font>"
									End If 
								Case Else 
									G_Config=Split(GetDefaultSet("static"),"|||")
									G_Msg="<font color=red>标签格式不规范。您可以尝试填写下面的表格来替换它。</font>"
							End Select 
						Else 
							G_Config=Split(GetDefaultSet("static"),"|||")
							G_Msg="<font color=red>标签格式不规范。您可以尝试填写下面的表格来替换它。</font>"
						End If 
						sRealDo="update"
						G_Msg=G_Msg&"   <a href='?do=del_label&label_name="&sLabelName&"&folder="&sLabelPath&"' onclick='return confirm(""您确定要删除"&sLabelName&"标签吗？删除之后不能恢复。"")'>您也可以点这里删除它。</a>"
					End If 
				Else
					G_Msg="<font color=red>找不到该标签，您可以尝试填写下面的表格来添加它。</font>"
					sRealDo="add"
				End If 
			Else
				G_Config=Split(GetDefaultSet("static"),"|||")
				G_Msg="<font color=red>传递过来的参数不规范。无法读取标签文件。您可以填写下面的表格添加标签。</font>"
				sLabelName="untitle_"&(G_i+1)
				sRealDo="add"
			End If 
		Case "save_label"
		Case "del_label"
			G_Config=Split(GetDefaultSet("static"),"|||")
			G_Msg=G_Msg&" 您现在可以添加一个静态标签。"
		Case Else 
			Select Case request("label_type")
				Case "static" 
					G_Config=Split(GetDefaultSet("static"),"|||")
					G_Msg="您现在可以添加一个静态标签。"
				Case "rss" 
					G_Config=Split(GetDefaultSet("rss" ),"|||")
					G_Msg="您现在可以添加一个RSS订阅标签。"
				Case "query" 
					G_Config=Split(GetDefaultSet("query" ),"|||")
					G_Msg="您现在可以添加一个论坛内容调用标签。"
				Case Else
					G_Config=Split(GetDefaultSet("static"),"|||")
					G_Msg="您现在可以添加一个静态标签。"
			End Select 
	End Select 
%>
	<tr>
	<td align="center" colspan="2" style="color:blue">操作提示：<%=G_Msg%></td>
	</tr>
	<tr>
	<td align="right">保存目录：</td>
	<td>
	../Resource/Label<%=G_CurrentFolder%>  
	</td>
	</tr>
	<tr>
	<td align="right">标签名称：</td>
	<td><input type="text" name="label_name" size="20" maxlength="255" value="<%=sLabelName%>" onblur="Label_Chk(this,/^[a-zA-Z0-9_\/]+$/gi)" />.tpl<span id="label_name_chk"></span> *只能由字母和下划线及数字组成。</td>
	</tr>
	<tr>
	<td align="right">缓存时间：</td>
	<td><input type="text" id="label_intv" name="label_intv" size="10" value="<%=G_Config(1)%>" onkeyup="this.value=this.value.replace(/[^0-9]/gi,'');$('format_time').innerHTML=Label_FormatTime(this.value);"  onblur="Label_Chk(this,/^[0-9]+$/gi)"><span id="label_intv_chk"></span> *单位：秒。只能填数字。<span id="format_time"></span></td>
	</tr>
<%
Select Case G_Config(0)
	Case "static"
%>
	<tr>
	<td align="right" valign="top">输出内容：</td>
	<td style="padding:0px;margin:0px;border:0px;">
		<span><textarea id="label_content" name="label_content" style="display:none;width:100%;height:300px;overflow:auto;padding:0px;margin:0px;border:none;"><%=G_Config(2)%></textarea></span>
		<div>
		<SCRIPT LANGUAGE="JavaScript">
		<!--
		var dveditconfig={
			textarea_id:'label_content',
			edit_height:'275px',
			edit_mode:'design',
			toolbar:['bold','italic','underline','separator','fontsize','fontfamily','fontcolor','fontbgcolor','separator','link','image','media','separator','justifyleft','justifycenter','justifyright','separator','insertorderedlist','insertunorderedlist','outdent','indent'],
			to_xhml:false
		};
		var label_content_edit=new DvEdit(dveditconfig);
		//-->
		</SCRIPT>
		</div>
	</td>
	</tr>
<%
	Case "rss"
%>
	<tr>
	<td align="right">订阅网址：</td>
	<td><input type="text" name="label_rss" size="70" maxlength="255" value="<%=G_Config(2)%>" onblur="Label_Chk(this,/^http:\/\//gi)" /><span id="label_rss_chk"></span> <br/>*以"http://"开头的完整网址。如百度的国内焦点新闻：http://news.baidu.com/n?cmd=1&class=civilnews&tn=rss&sub=0</td>
	</tr>
	<tr>
	<td align="right" valign="top">解释模板：<br/>(stylesheet)</td>
	<td><textarea name="label_xslt" style="width:100%;height:300px;border:0px;margin:0px;padding:0px;font-family:Courier New;color:#cc0000"><%=G_Config(3)%></textarea></td>
	</tr>
<%
	Case "query"
		response.write "<script language='javascript'>var FromQueryType='"&G_Config(2)&"',ToQueryType='"&G_Config(2)&"',Config='"&G_Config(7)&"',TimeType='"&G_Config(9)&"';</script>"
%>
	<tr>
	<td align="right">内容类型：</td>
	<td><select id="label_query_type" name="label_query_type" onchange="Label_Query_ChangeType(FromQueryType,this.value,Config,TimeType)">
	<option value="">选取调用类型</option>
	<option value="bbs">帖子调用</option>
	<option value="user">会员调用</option>
	<option value="news">公告调用</option>
	<option value="file">展区调用</option>
	</select></td>
	</tr>
	<tr>
	<td align="right">调用记录条数：</td>
	<td><input type="text" id="label_total" name="label_total" size="10" maxlength="6" value="" onkeyup="this.value=this.value.replace(/[^0-9]/gi,'');" onblur="Label_Chk(this,/^[0-9]+$/gi)" /><span id="label_total_chk"></span> *只能填数字。</td>
	</tr>
	<tr id="tr_board" style="display:none;">
	<td align="right" valign="top">版面查询设置：</td>
	<td>
		<select id="label_board" name="label_board" multiple="multiple" size="8"></select>
		<script language="javascript">
		<!--
		BoardJumpListSelect('0',"label_board","选取所有版面","",0);
		//-->
		</script> <label for="label_board_0"><input id="label_board_0" type="radio" name="select_board_mode" value="0" class="radio" checked />调用选中版面</label>  <label for="label_board_1"><input id="label_board_1" type="radio" name="select_board_mode" value="1" class="radio" />排除选中版面</label> *按住CTRL、SHIFT键或者在选择框内拖动鼠标可以选中多个版面。
	</td>
	</tr>
	<tr>
	<td align="right" valign="top">时间显示格式：</td>
	<td>
		<select id="label_time_type" name="label_time_type">
		<option value="0" SELECTED>YYYY-M-D H:M:S(长格式)</option>
		<option value="1">YYYY年M月D</option>
		<option value="2">YYYY-M-D</option>
		<option value="3">H:M:S</option>
		<option value="4">hh:mm</option>
	    </select>
		&nbsp;&nbsp;&nbsp;
	</td>
	</tr>
	<tr>
	<td align="right" valign="top">排序方式设置：</td>
	<td>
		<select id="label_order_by" name="label_order_by">
		<option value="0">选择排序方式</option>
		</select>  <label for="label_order_0"><input id="label_order_0" type="radio" name="select_order_mode" value="0" class="radio" checked />正序（小->大）</label>  <label for="label_order_1"><input id="label_order_1" type="radio" name="select_order_mode" value="1" class="radio" />倒序（大->小）</label>
	</td>
	</tr>

	<tr id="tr_bbs" style="display:none;">
	<td align="right" valign="top">其它调用限制：</td>
	<td>
		标题长度<input type="text" id="label_title_length" name="label_title_length" size="10" maxlength="6" value="<%=G_Config(8)%>" onblur="Label_Chk(this,/^[0-9]+$/gi)" onkeyup="this.value=this.value.replace(/[^0-9]/gi,'');" /><span id="label_title_length_chk"></span> *只能填数字。 贴子类型：<label for="label_bbstype_0"><input id="label_bbstype_0" type="radio" name="label_bbstype" value="0" class="radio" checked />不限</label> <label for="label_bbstype_1"><input id="label_bbstype_1" type="radio" name="label_bbstype" value="1" class="radio" />仅固顶主题</label> <label for="label_bbstype_2"><input id="label_bbstype_2" type="radio" name="label_bbstype" value="2" class="radio" />仅精华主题</label> <label for="label_bbstype_3"><input id="label_bbstype_3" type="radio" name="label_bbstype" value="3" class="radio" />仅回复贴子（如果选中此项，将只能按贴子ID排序）</label> <br/>时间范围：
		<select id="label_time_limit" name="label_time_limit">
		<option value="0" SELECTED>不限时间</option>
		<option value="1">1周内</option>
		<option value="2">1个月内</option>
		<option value="3">3个月内</option>
		<option value="4">半年内</option>
		<option value="5">1年内</option>
	    </select>
	</td>
	</tr>

	<tr id="tr_file" style="display:none;">
	<td align="right" valign="top">其它调用限制：</td>
	<td>
		文件说明长度<input type="text" id="label_readme_length" name="label_readme_length" size="10" maxlength="6" value="<%=G_Config(8)%>" onblur="Label_Chk(this,/^[0-9]+$/gi)" onkeyup="this.value=this.value.replace(/[^0-9]/gi,'');" /><span id="label_readme_length_chk"></span> *只能填数字。 
		调用文件类型： 
		<select name="label_file_type" id="label_file_type">
		<option value="all" selected>不限类型</option>
		<option value="0">文件集</option>
		<option value="1">图片集</option>
		<option value="2">flash集</option>
		<option value="3">音乐集</option>
		<option value="4">电影集</option>
		</select> </label> 
	</td>
	</tr>

	<tr>
	<td align="right" valign="top">解释模板（开始）：<br/>开始解释时输出</td>
	<td style="padding:0px;margin:0px;border:0px;">
		<textarea id="label_template_start" name="label_template_start" style="width:100%;height:100px;overflow:auto;padding:0px;margin:0px;border:none"><%=G_Config(4)%></textarea>
		<div>
		<SCRIPT LANGUAGE="JavaScript">
		<!--
		//var label_edit_template_start=new DvEdit('label_template_start','75px','text',['bold','italic','underline','separator','fontsize','fontfamily','fontcolor','fontbgcolor','separator','link','image','media','separator','justifyleft','justifycenter','justifyright','separator','insertorderedlist','insertunorderedlist','outdent','indent']);
		//-->
		</SCRIPT>
		</div>
	</td>
	</tr>
	<tr>
	<td align="right" valign="top">解释模板（循环）：<br/>循环解释内容输出
		<div id="tool_label_user" style="display:none;">
			<ul>
			<li>用户ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserID}</a></li>
			<li>用户名：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserName}</a></li>
			<li>用户主题数：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserTopic}</a></li>
			<li>用户帖子数：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserPost}</a></li>
			<li>用户精华数：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserBest}</a></li>
			<li>用户金钱：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserWealth}</a></li>
			<li>用户魅力：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserCP}</a></li>
			<li>用户积分：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserEP}</a></li>
			<li>用户被删帖数：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserDel}</a></li>
			<li>用户性别：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserSex}</a></li>
			<li>用户注册时间：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$JoinDate}</a></li>
			<li>用户登陆次数：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserLogins}</a></li>
			</ul>
		</div>
		<div id="tool_label_news" style="display:none;">
			<ul>
			<li>公告ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ID}</a></li>
			<li>标题：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Topic}</a></li>
			<li>作者：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserName}</a></li>
			<li>版块名称：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$BoardName}</a></li>
			<li>版块ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Boardid}</a></li>
			<li>时间：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$PostTime}</a></li>
			</ul>
		</div>
		<div id="tool_label_file" style="display:none;">
			<ul>
			<li>作者：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserName}</a></li>
			<li>版块名称：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$BoardName}</a></li>
			<li>版块ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Boardid}</a></li>
			<li>时间：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$AddTime}</a></li>
			<li>文件ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ID}</a></li>
			<li>文件名：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Filename}</a></li>
			<li>文件说明：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Readme}</a></li>
			<li>文件类型：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$FileType}</a></li>
			<li>文件预览文件名：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ViewFilename}</a></li>
			<li>浏览数：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ViewNum}</a></li>
			<li>下载数：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$DownNum}</a></li>
			<li>文件大小：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$FileSize}</a></li>
			<li>帖子主题ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$RootID}</a></li>
			<li>帖子对应ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ReplyID}</a></li>
			<li>交替颜色：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$TColor}</a></li>
			</ul>
		</div>
		<div id="tool_label_bbs" style="display:none;">
			<ul>
			<li>标题：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Topic}</a></li>
			<li>作者：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$UserName}</a></li>
			<li>发表时间：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$PostTime}</a></li>
			<li>回复者：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ReplyName}</a></li>
			<li>回复时间：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ReplyTime}</a></li>
			<li>版块名称：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$BoardName}</a></li>
			<li>版块说明：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$BoardInfo}</a></li>
			<li>心情图标：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Face}</a></li>
			<li>帖子ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ID}</a></li>
			<li>帖子ReplyID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$ReplyID}</a></li>
			<li>版面ID：<a href="javascript:;" onclick="label_edit_template_loop.insert(this.innerHTML);">{$Boardid}</a></li>
			</ul>
		</div>
		<div id="tool_label_group" style="display:none;">
			
		</div>
	</td>
	<td style="padding:0px;margin:0px;border:0px;">
		<textarea id="label_template_loop" name="label_template_loop" style="display:none;width:100%;height:300px;overflow:auto;padding:0px;margin:0px;border:none"><%=G_Config(5)%></textarea>
		<div>
		<SCRIPT LANGUAGE="JavaScript">
		<!--
		function strForSelectLabel(){
			var s=$('label_query_type').value||'bbs';
			return $('tool_label_'+s).innerHTML;
		}
		var dveditconfig={
			textarea_id:'label_template_loop',
			edit_height:'275px',
			edit_mode:'design',
			toolbar:['bold','italic','underline','separator','fontsize','fontfamily','fontcolor','fontbgcolor','separator','link','image','media','separator','justifyleft','justifycenter','justifyright','separator','insertorderedlist','insertunorderedlist','outdent','indent','<div style="float:left;position:relative;padding-top:4px;color:red" onclick="label_edit_template_loop.t.open(this,strForSelectLabel())">[插入调用标签]</div>'],
			to_xhml:false
		};
		var label_edit_template_loop=new DvEdit(dveditconfig);
		//-->
		</SCRIPT>
		</div>
	</td>
	</tr>
	<tr>
	<td align="right" valign="top">解释模板（结束）：<br/>结束解释时输出</td>
	<td style="padding:0px;margin:0px;border:0px;">
		<textarea id="label_template_stop" name="label_template_stop" style="width:100%;height:100px;overflow:auto;padding:0px;margin:0px;border:none"><%=G_Config(6)%></textarea>
		<div>
		<SCRIPT LANGUAGE="JavaScript">
		<!--
		//var label_edit_template_stop=new DvEdit('label_template_stop','75px','text',['bold','italic','underline','separator','fontsize','fontfamily','fontcolor','fontbgcolor','separator','link','image','media','separator','justifyleft','justifycenter','justifyright','separator','insertorderedlist','insertunorderedlist','outdent','indent']);
		//-->
		</SCRIPT>
		</div>
	</td>
	</tr>
	<input type="hidden" id="label_mainshow_length" name="label_mainshow_length" value="<%=G_Config(8)%>" />
	<input type="hidden" id="label_query_config" name="label_query_config" value="<%=G_Config(7)%>" />
	<script language="javascript">Label_Query_ChangeType(FromQueryType,ToQueryType,Config,TimeType);</script>
<%
End Select 
%>
	<tr>
	<td align="right">&nbsp;</td>
	<td>
	<input type="hidden" name="label_oldname" value="<%=sLabelName%>" />
	<input type="hidden" name="realdo" value="<%=sRealDo%>" />
	<input type="hidden" name="label_type" value="<%=G_Config(0)%>" />
	<input type="hidden" name="label_path" value="<%=sLabelPath%>" />
	<input type="hidden" name="folder" value="<%=sLabelPath%>" />
	<input type="submit" name="subtn" value="    提交保存   " class="button" /> <span id="form_chk"></span>
	</td>
	</tr>
<%
End Sub 
%>
</table>
</form>
</body>
</html>