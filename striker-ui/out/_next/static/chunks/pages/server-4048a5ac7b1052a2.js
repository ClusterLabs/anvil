(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[753],{41171:function(e,n,i){(window.__NEXT_P=window.__NEXT_P||[]).push(["/server",function(){return i(95319)}])},77583:function(e,n,i){"use strict";var o=i(85893),l=i(14440),r=i(67294),t=i(33544),c=i(56903),s=i(87006),a=i(59278);let d=(0,r.forwardRef)((e,n)=>{let{actionCancelText:i="Cancel",actionProceedText:d,children:u,closeOnProceed:h=!1,contentContainerProps:p,dialogProps:g,disableProceed:x,loading:f,loadingAction:m=!1,onActionAppend:j,onCancelAppend:v,onProceedAppend:w,openInitially:Z,preActionArea:b,proceedButtonProps:C,proceedColour:k="blue",scrollContent:_=!1,scrollBoxProps:N,showActionArea:P=!0,showCancel:y,showClose:B,titleText:S,wide:A,content:E=u}=e,I=(0,r.useRef)(null),R=(0,r.useMemo)(()=>(0,s.Z)(E,a.Ac),[E]),D=(0,r.useMemo)(()=>(0,r.createElement)(_?t.VZ:l.Z,N,R),[R,N,_]),O=(0,r.useMemo)(()=>P&&(0,o.jsx)(t.ux,{cancelProps:{children:i,onClick:function(){for(var e=arguments.length,n=Array(e),i=0;i<e;i++)n[i]=arguments[i];null==j||j.call(null,...n),null==v||v.call(null,...n)}},closeOnProceed:h,loading:m,proceedProps:{background:k,children:d,disabled:x,onClick:function(){for(var e=arguments.length,n=Array(e),i=0;i<e;i++)n[i]=arguments[i];null==j||j.call(null,...n),null==w||w.call(null,...n)},...C},showCancel:y}),[i,d,h,x,m,j,v,w,C,k,P,y]);return(0,r.useImperativeHandle)(n,()=>({setOpen:e=>{var n;return null===(n=I.current)||void 0===n?void 0:n.setOpen(e)}}),[]),(0,o.jsx)(t.Js,{dialogProps:g,header:S,loading:f,openInitially:Z,ref:I,showClose:B,wide:A,children:(0,o.jsxs)(c.Z,{...p,children:[D,b,O]})})});d.displayName="ConfirmDialog",n.Z=d},39937:function(e,n,i){"use strict";i.d(n,{Z:function(){return D}});var o=i(85893),l=i(19338),r=i(89262),t=i(32653),c=i(14440),s=i(34815),a=i(80594),d=i(67294),u=i(77831),h=i(55278),p=i(26076),g=i(8489),x=i(37969),f=i(54965),m=i(49520);let j=[{text:"Anvil",image:"/pngs/anvil_icon_on.png",uri:"/manage-element"},{text:"Files",image:"/pngs/files_on.png",uri:"/file-manager"},{text:"Configure",image:"/pngs/configure_icon_on.png",uri:"/config"},{text:"Mail",image:"/pngs/email_on.png",uri:"/mail-config"},{text:"Help",image:"/pngs/help_icon_on.png",uri:"https://alteeve.com/w/Support"}],v={width:"40em",height:"40em"};var w=i(98484),Z=i(29535),b=i(56903),C=i(97607),k=i(59278),_=i(6946);let N="AnvilDrawer",P={actionIcon:"".concat(N,"-actionIcon"),list:"".concat(N,"-list")},y=(0,r.ZP)(g.ZP)(()=>({["& .".concat(P.list)]:{width:"200px"},["& .".concat(P.actionIcon)]:{fontSize:"2.3em",color:u.of}}));var B=e=>{let{open:n,setOpen:i}=e,{getSessionUser:l}=(0,_.Z)(),r=l();return(0,o.jsx)(y,{BackdropProps:{invisible:!0},anchor:"left",open:n,onClose:()=>i(!n),children:(0,o.jsx)("div",{role:"presentation",children:(0,o.jsxs)(x.Z,{className:P.list,children:[(0,o.jsx)(f.ZP,{children:(0,o.jsx)(k.Ac,{children:r?(0,o.jsxs)(o.Fragment,{children:["Welcome, ",r.name]}):"Unregistered"})}),(0,o.jsx)(Z.Z,{}),(0,o.jsx)(m.Z,{component:"a",href:"/index.html",children:(0,o.jsxs)(b.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,o.jsx)(h.Z,{className:P.actionIcon}),(0,o.jsx)(k.Ac,{children:"Dashboard"})]})}),j.map(e=>(0,o.jsx)(m.Z,{component:"a",href:e.uri,children:(0,o.jsxs)(b.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,o.jsx)("img",{alt:e.text,src:e.image,...v}),(0,o.jsx)(k.Ac,{children:e.text})]})},"anvil-drawer-".concat(e.image))),(0,o.jsx)(m.Z,{onClick:()=>{w.Z.put("/auth/logout").then(()=>{window.location.replace("/login")}).catch(e=>{(0,C.Z)(e)})},children:(0,o.jsxs)(b.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,o.jsx)(p.Z,{className:P.actionIcon}),(0,o.jsx)(k.Ac,{children:"Logout"})]})})]})})})},S=i(85838),A=i(56399);let E="Header",I={input:"".concat(E,"-input"),barElement:"".concat(E,"-barElement"),iconBox:"".concat(E,"-iconBox"),searchBar:"".concat(E,"-searchBar"),icons:"".concat(E,"-icons")},R=(0,r.ZP)(t.Z)(e=>{let{theme:n}=e;return{paddingTop:n.spacing(.5),paddingBottom:n.spacing(.5),paddingLeft:n.spacing(3),paddingRight:n.spacing(3),borderBottom:"solid 1px",borderBottomColor:u.hM,position:"static",["& .".concat(I.input)]:{height:"2.8em",width:"30vw",backgroundColor:n.palette.secondary.main,borderRadius:u.n_},["& .".concat(I.barElement)]:{padding:0},["& .".concat(I.iconBox)]:{[n.breakpoints.down("sm")]:{display:"none"}},["& .".concat(I.searchBar)]:{[n.breakpoints.down("sm")]:{flexGrow:1,paddingLeft:"15vw"}},["& .".concat(I.icons)]:{paddingLeft:".1em",paddingRight:".1em"}}});var D=()=>{let e=(0,d.useRef)({}),n=(0,d.useRef)({}),[i,r]=(0,d.useState)(!1);return(0,o.jsxs)(o.Fragment,{children:[(0,o.jsx)(R,{children:(0,o.jsxs)(c.Z,{display:"flex",justifyContent:"space-between",flexDirection:"row",children:[(0,o.jsx)(b.Z,{row:!0,children:(0,o.jsx)(s.Z,{onClick:()=>r(!i),children:(0,o.jsx)("img",{alt:"",src:"/pngs/logo.png",width:"160",height:"40"})})}),(0,o.jsx)(b.Z,{className:I.iconBox,row:!0,spacing:0,children:(0,o.jsx)(c.Z,{children:(0,o.jsx)(a.Z,{onClick:e=>{var i,o;let{currentTarget:l}=e;null===(i=n.current.setAnchor)||void 0===i||i.call(null,l),null===(o=n.current.setOpen)||void 0===o||o.call(null,!0)},sx:{color:u.of,padding:"0 .1rem"},children:(0,o.jsx)(S.Z,{icon:l.Z,ref:e})})})})]})}),(0,o.jsx)(B,{open:i,setOpen:r}),(0,o.jsx)(A.Z,{onFetchSuccessAppend:n=>{var i;null===(i=e.current.indicate)||void 0===i||i.call(null,Object.keys(n).length>0)},ref:n})]})}},23833:function(e,n,i){"use strict";var o=i(85893),l=i(73970),r=i(85959),t=i(77831);n.Z=e=>{let{children:n,sx:i}=e,c={backgroundColor:t.lD,paddingRight:"3em",["&.".concat(l.Z.selected)]:{backgroundColor:t.s7,fontWeight:400,["&.".concat(l.Z.focusVisible)]:{backgroundColor:t.s7},"&:hover":{backgroundColor:t.s7}},["&.".concat(l.Z.focusVisible)]:{backgroundColor:t.s7},"&:hover":{backgroundColor:t.s7},...i};return(0,o.jsx)(r.Z,{...e,sx:c,children:n})}},95319:function(e,n,i){"use strict";i.r(n);var o=i(85893),l=i(89262),r=i(14440),t=i(9008),c=i.n(t),s=i(11163),a=i(67294),d=i(93016),u=i(39937);let h="Server",p={preview:"".concat(h,"-preview"),fullView:"".concat(h,"-fullView")},g=(0,l.ZP)("div")(e=>{let{theme:n}=e;return{["& .".concat(p.preview)]:{width:"25%",height:"100%",[n.breakpoints.down("md")]:{width:"100%"}},["& .".concat(p.fullView)]:{display:"flex",flexDirection:"row",width:"100%",justifyContent:"center"}}});n.default=()=>{let[e,n]=(0,a.useState)(!0),{server_name:i,server_state:l,uuid:t,vnc:h}=(0,s.useRouter)().query,x=((null==h?void 0:h.toString())||"").length>0,f=(null==i?void 0:i.toString())||"",m=(null==l?void 0:l.toString())||"",j=(null==t?void 0:t.toString())||"";return(0,a.useEffect)(()=>{x&&n(!1)},[x]),(0,o.jsxs)(g,{children:[(0,o.jsx)(c(),{children:(0,o.jsx)("title",{children:f})}),(0,o.jsx)(u.Z,{}),e?(0,o.jsx)(r.Z,{className:p.preview,children:(0,o.jsx)(d.M,{onClickPreview:()=>{n(!1)},serverName:f,serverState:m,serverUUID:j})}):(0,o.jsx)(r.Z,{className:p.fullView,children:(0,o.jsx)(d.S,{onClickCloseButton:()=>{n(!0)},serverUUID:j,serverName:f})})]})}}},function(e){e.O(0,[162,318,524,26,16,888,774,179],function(){return e(e.s=41171)}),_N_E=e.O()}]);