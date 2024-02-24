"use strict";(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[302],{81302:function(e,n,t){t.d(n,{S:function(){return Display_FullSize},M:function(){return L}});var l=t(85893),r=t(50594),s=t(25709),i=t(31846),o=t(90948),c=t(5616),a=t(87627),u=t(15861),d=t(5152),h=t.n(d),x=t(67294),v=t(83221);let f="0xffe3",m="0xffe9";var p=[{keys:"Ctrl + Alt + Delete",scans:[]},{keys:"Ctrl + Alt + F1",scans:[f,m,"0xffbe"]},{keys:"Ctrl + Alt + F2",scans:[f,m,"0xffbf"]},{keys:"Ctrl + Alt + F3",scans:[f,m,"0xffc0"]},{keys:"Ctrl + Alt + F4",scans:[f,m,"0xffc1"]},{keys:"Ctrl + Alt + F5",scans:[f,m,"0xffc2"]},{keys:"Ctrl + Alt + F6",scans:[f,m,"0xffc3"]},{keys:"Ctrl + Alt + F7",scans:[f,m,"0xffc4"]},{keys:"Ctrl + Alt + F8",scans:[f,m,"0xffc5"]},{keys:"Ctrl + Alt + F9",scans:[f,m,"0xffc6"]}],j=t(65275),g=t(37260),C=t(39858),w=t(67645),k=t(57976),Z=t(19467),b=t(52621),components_Menu=e=>{let{getItemDisabled:n,items:t={},muiMenuProps:r,onItemClick:s,open:i,renderItem:o}=e,c=(0,x.useMemo)(()=>Object.entries(t),[t]),u=(0,x.useMemo)(()=>c.map(e=>{let[t,r]=e;return(0,l.jsx)(j.Z,{disabled:null==n?void 0:n.call(null,t,r),onClick:function(){for(var e=arguments.length,n=Array(e),l=0;l<e;l++)n[l]=arguments[l];return null==s?void 0:s.call(null,t,r,...n)},children:null==o?void 0:o.call(null,t,r)},t)}),[n,s,c,o]);return(0,l.jsx)(a.Z,{open:i,...r,children:u})},components_ButtonWithMenu=e=>{let{children:n,containedButtonProps:t,iconButtonProps:r,muiMenuProps:s,onButtonClick:i,onItemClick:o,variant:a="icon",...u}=e,[d,h]=(0,x.useState)(null),v=(0,x.useMemo)(()=>!!d,[d]),f=(0,x.useMemo)(()=>n||("icon"===a?(0,l.jsx)(k.Z,{fontSize:null==r?void 0:r.size}):"Options"),[n,null==r?void 0:r.size,a]),m=(0,x.useCallback)(function(){for(var e=arguments.length,n=Array(e),t=0;t<e;t++)n[t]=arguments[t];let{0:{currentTarget:l}}=n;return h(l),null==i?void 0:i.call(null,...n)},[i]),p=(0,x.useMemo)(()=>"contained"===a?(0,l.jsx)(Z.Z,{onClick:m,...t,children:f}):(0,l.jsx)(b.Z,{onClick:m,...r,children:f}),[m,f,t,r,a]),j=(0,x.useCallback)(function(e,n){for(var t=arguments.length,l=Array(t>2?t-2:0),r=2;r<t;r++)l[r-2]=arguments[r];return h(null),null==o?void 0:o.call(null,e,n,...l)},[o]);return(0,l.jsxs)(c.Z,{children:[p,(0,l.jsx)(components_Menu,{muiMenuProps:{anchorEl:d,keepMounted:!0,onClose:()=>h(null),...s},onItemClick:j,open:v,...u})]})},y=t(41247),S=t(84154),P=t(7576),components_ServerMenu=e=>{var n;let{getItemDisabled:t,items:r,onItemClick:s,renderItem:i,serverName:o,serverState:a,serverUuid:u,...d}=e,{confirmDialog:h,setConfirmDialogOpen:v,setConfirmDialogProps:f,finishConfirm:m}=(0,P.Z)(),p=(0,x.useMemo)(()=>({"force-off":{colour:"red",description:(0,l.jsx)(l.Fragment,{children:"This is equal to pulling the power cord, which may cause data loss or system corruption."}),label:"Force off",path:"/command/stop-server/".concat(u,"?force=1")},"power-off":{description:(0,l.jsx)(l.Fragment,{children:"This is equal to pushing the power button. If the server doesn't respond to the corresponding signals, you may have to manually shut it down."}),label:"Power off",path:"/command/stop-server/".concat(u)},"power-on":{description:(0,l.jsx)(l.Fragment,{children:"This is equal to pushing the power button."}),label:"Power on",path:"/command/start-server/".concat(u)}}),[u]);return(0,l.jsxs)(c.Z,{children:[(0,l.jsx)(components_ButtonWithMenu,{getItemDisabled:e=>{let n=e.includes("on");return"running"===a===n},items:p,onItemClick:(e,n)=>{let{colour:t,description:r,label:s,path:i}=n,c=s.toLocaleLowerCase();f({actionProceedText:s,content:(0,l.jsx)(S.Ac,{children:r}),onProceedAppend:()=>{f(e=>({...e,loading:!0})),w.Z.put(i).then(()=>{m("Success",{children:(0,l.jsxs)(l.Fragment,{children:["Successfully registered ",c," job on ",o,"."]})})}).catch(e=>{let n=(0,y.Z)(e);n.children=(0,l.jsxs)(l.Fragment,{children:["Failed to register ",c," job on ",o,"; CAUSE:"," ",n.children,"."]}),m("Error",n)})},proceedColour:t,titleText:"".concat(s," server ").concat(o,"?")}),v(!0)},renderItem:(e,n)=>{let t;let{colour:r,label:s}=n;return r&&(t=Z.D[r]),(0,l.jsx)(S.Ac,{inheritColour:!0,color:t,children:s})},...d,children:(0,l.jsx)(C.Z,{fontSize:null==d?void 0:null===(n=d.iconButtonProps)||void 0===n?void 0:n.size})}),h]})},A=t(81796),F=t(42702);let M="FullSize",_={displayBox:"".concat(M,"-displayBox"),spinnerBox:"".concat(M,"-spinnerBox")},z=(0,o.ZP)("div")(()=>({["& .".concat(_.displayBox)]:{width:"75vw",height:"75vh"},["& .".concat(_.spinnerBox)]:{flexDirection:"column",width:"75vw",height:"75vh",alignItems:"center",justifyContent:"center"}})),B=h()(()=>Promise.all([t.e(460),t.e(253)]).then(t.bind(t,24253)),{loadableGenerated:{webpack:()=>[24253]},ssr:!1}),buildServerVncUrl=(e,n)=>"ws://".concat(e,"/ws/server/vnc/").concat(n);var Display_FullSize=e=>{let{onClickCloseButton:n,serverUUID:t,serverName:o,vncReconnectTimerStart:d=5}=e,h=(0,F.Z)(),[f,m]=(0,x.useState)(null),[C,w]=(0,x.useState)(void 0),[k,Z]=(0,x.useState)(!1),[b,y]=(0,x.useState)(!1),[P,M]=(0,x.useState)(d),E=(0,x.useRef)(null),I=(0,x.useRef)(null),handleClickKeyboard=e=>{m(e.currentTarget)},handleSendKeys=e=>{if(E.current){if(e.length){for(let n=0;n<=e.length-1;n+=1)E.current.sendKey(e[n],1);for(let n=e.length-1;n>=0;n-=1)E.current.sendKey(e[n],0)}else E.current.sendCtrlAltDel();m(null)}},T=(0,x.useCallback)(()=>{Z(!0),y(!1),w({url:buildServerVncUrl(window.location.host,t)})},[t]),U=(0,x.useCallback)(()=>{(null==E?void 0:E.current)&&(E.current.disconnect(),E.current=null),w(void 0)},[]),D=(0,x.useCallback)(()=>{U(),T()},[T,U]),N=(0,x.useCallback)(()=>{let e=setInterval(()=>{M(n=>{let t=n-1;return t<1&&clearInterval(e),t})},1e3)},[]),K=(0,x.useCallback)(()=>{Z(!1)},[]),L=(0,x.useCallback)(e=>{let{detail:{clean:n}}=e;n||(Z(!1),y(!0),N())},[N]),O=(0,x.useMemo)(()=>!k&&!b,[k,b]),R=(0,x.useMemo)(()=>(0,l.jsxs)(c.Z,{children:[(0,l.jsx)(v.Z,{onClick:handleClickKeyboard,children:(0,l.jsx)(i.Z,{})}),(0,l.jsx)(a.Z,{anchorEl:f,keepMounted:!0,open:!!f,onClose:()=>m(null),children:p.map(e=>{let{keys:n,scans:t}=e;return(0,l.jsx)(j.Z,{onClick:()=>handleSendKeys(t),children:(0,l.jsx)(u.Z,{variant:"subtitle1",children:n})},n)})})]}),[f]),V=(0,x.useMemo)(()=>(0,l.jsx)(c.Z,{children:(0,l.jsx)(v.Z,{onClick:function(){for(var e=arguments.length,t=Array(e),l=0;l<e;l++)t[l]=arguments[l];U(),null==n||n.call(null,...t)},children:(0,l.jsx)(r.Z,{})})}),[U,n]),q=(0,x.useMemo)(()=>(0,l.jsx)(c.Z,{children:(0,l.jsx)(v.Z,{onClick:()=>{window&&(U(),window.location.assign("/"))},children:(0,l.jsx)(s.Z,{})})}),[U]),H=(0,x.useMemo)(()=>O&&(0,l.jsxs)(l.Fragment,{children:[R,(0,l.jsx)(components_ServerMenu,{serverName:o,serverState:"running",serverUuid:t}),q,V]}),[R,q,o,t,O,V]);return(0,x.useEffect)(()=>{0===P&&(M(d),D())},[D,P,d]),(0,x.useEffect)(()=>{h&&T()},[T,h]),(0,l.jsxs)(g.s_,{children:[(0,l.jsxs)(g.V9,{children:[(0,l.jsx)(S.z,{text:"Server: ".concat(o)}),H]}),(0,l.jsxs)(z,{children:[(0,l.jsx)(c.Z,{display:O?"flex":"none",className:_.displayBox,children:(0,l.jsx)(B,{onConnect:K,onDisconnect:L,rfb:E,rfbConnectArgs:C,rfbScreen:I})}),!O&&(0,l.jsxs)(c.Z,{display:"flex",className:_.spinnerBox,children:[k&&(0,l.jsxs)(l.Fragment,{children:[(0,l.jsxs)(S.z,{textAlign:"center",children:["Connecting to ",o,"."]}),(0,l.jsx)(A.Z,{})]}),b&&(0,l.jsxs)(l.Fragment,{children:[(0,l.jsx)(S.z,{textAlign:"center",children:"There was a problem connecting to the server."}),(0,l.jsxs)(S.z,{textAlign:"center",mt:"1em",children:["Retrying in ",P,"."]})]})]})]})]})},E=t(62675),I=t(74808),T=t(54799),U=t(6010),D=t(55238),N=t(87476);let K={externalPreview:"",externalTimestamp:0,headerEndAdornment:null,hrefPreview:void 0,isExternalLoading:!1,isExternalPreviewStale:!1,isFetchPreview:!0,isShowControls:!0,isUseInnerPanel:!1,onClickConnectButton:void 0,onClickPreview:void 0,serverName:"",serverState:""},PreviewPanel=e=>{let{children:n,isUseInnerPanel:t}=e;return t?(0,l.jsx)(g.Lg,{children:n}):(0,l.jsx)(g.s_,{children:n})},PreviewPanelHeader=e=>{let{children:n,isUseInnerPanel:t,text:r}=e;return t?(0,l.jsxs)(g.CH,{children:[r?(0,l.jsx)(S.Ac,{text:r}):(0,l.jsx)(l.Fragment,{}),n]}):(0,l.jsxs)(g.V9,{children:[r?(0,l.jsx)(S.z,{text:r}):(0,l.jsx)(l.Fragment,{}),n]})},Preview=e=>{let{externalPreview:n=K.externalPreview,externalTimestamp:t=K.externalTimestamp,headerEndAdornment:r,hrefPreview:s,isExternalLoading:i=K.isExternalLoading,isExternalPreviewStale:o=K.isExternalPreviewStale,isFetchPreview:a=K.isFetchPreview,isShowControls:u=K.isShowControls,isUseInnerPanel:d=K.isUseInnerPanel,onClickPreview:h,serverName:f=K.serverName,serverState:m=K.serverState,serverUUID:p,onClickConnectButton:j=h}=e,[g,C]=(0,x.useState)(!0),[k,Z]=(0,x.useState)(!1),[b,y]=(0,x.useState)(""),[P,F]=(0,x.useState)(0),M=(0,N.zO)(),_=(0,x.useMemo)(()=>"running"===m?(0,l.jsxs)(l.Fragment,{children:[(0,l.jsx)(c.Z,{alt:"",component:"img",src:"data:image;base64,".concat(b),sx:{height:"100%",opacity:k?"0.4":"1",padding:d?".2em":0,width:"100%"}}),k&&(e=>{let{unit:n,value:t}=(0,N._J)(M-e);return(0,l.jsxs)(S.Ac,{position:"absolute",children:["Updated ~",t," ",n," ago"]})})(P)]}):(0,l.jsx)(I.Z,{sx:{color:U.UZ,height:"80%",width:"80%"}}),[k,d,M,b,P,m]),z=(0,x.useMemo)(()=>{if(g)return(0,l.jsx)(A.Z,{mb:"1em",mt:"1em"});let e=!b,n={borderRadius:U.n_,color:U.s7,padding:0};return s?(0,l.jsx)(T.Z,{disabled:e,href:s,sx:n,children:_}):(0,l.jsx)(T.Z,{component:"span",disabled:e,onClick:h,sx:n,children:_})},[s,g,b,_,h]);return(0,x.useEffect)(()=>{a?(async()=>{try{let{data:e}=await w.Z.get("/server/".concat(p,"?ss=1")),{screenshot:n,timestamp:t}=e;y(n),F(t),Z(!(0,N.Z$)(t,300))}catch(e){Z(!0)}finally{C(!1)}})():i||(y(n),F(t),Z(o),C(!1))},[n,t,i,o,a,p]),(0,l.jsxs)(PreviewPanel,{isUseInnerPanel:d,children:[(0,l.jsxs)(PreviewPanelHeader,{isUseInnerPanel:d,text:f,children:[r,(0,l.jsx)(components_ServerMenu,{iconButtonProps:{size:d?"small":void 0},serverName:f,serverState:m,serverUuid:p})]}),(0,l.jsxs)(D.Z,{row:!0,sx:{"& > :first-child":{flexGrow:1}},children:[(0,l.jsx)(c.Z,{textAlign:"center",children:z}),u&&b&&(0,l.jsx)(D.Z,{spacing:".3em",children:(0,l.jsx)(v.Z,{onClick:j,children:(0,l.jsx)(E.Z,{})})})]})]})};Preview.defaultProps=K;var L=Preview},7576:function(e,n,t){var l=t(85893),r=t(67294),s=t(56597),i=t(68917);n.Z=function(){let e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},{initial:{actionProceedText:n="",content:t="",titleText:o="",...c}={}}=e,a=(0,r.useRef)(null),[u,d]=(0,r.useState)({actionProceedText:n,content:t,titleText:o}),h=(0,r.useCallback)(e=>d(n=>{let{loading:t,...l}=n;return{...l,loading:e}}),[]),x=(0,r.useCallback)(e=>{var n,t;return null==a?void 0:null===(t=a.current)||void 0===t?void 0:null===(n=t.setOpen)||void 0===n?void 0:n.call(null,e)},[]),v=(0,r.useCallback)((e,n)=>d({actionProceedText:"",content:(0,l.jsx)(i.Z,{...n}),showActionArea:!1,showClose:!0,titleText:e}),[]),f=(0,r.useMemo)(()=>(0,l.jsx)(s.Z,{...c,...u,ref:a}),[u,c]);return{confirmDialog:f,confirmDialogRef:a,setConfirmDialogLoading:h,setConfirmDialogOpen:x,setConfirmDialogProps:d,finishConfirm:v}}},87476:function(e,n,t){t.d(n,{Z$:function(){return last},_J:function(){return elapsed},zO:function(){return now}});let now=e=>{let n=Date.now();return e||(n=Math.floor(n/1e3)),n},last=function(e,n){let{ms:t}=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},l=now(t)-e;return l<=n},elapsed=e=>{var n;let t=e,l=[60,60].reduce((e,n)=>{let l=t%n;return e.push(l),t=(t-l)/n,e},[]),[r,s,i]=[...l,t],o=null!==(n=[{unit:"h",value:i},{unit:"m",value:s}].find(e=>{let{value:n}=e;return n}))&&void 0!==n?n:{unit:"s",value:r};return{h:i,m:s,s:r,...o}}}}]);