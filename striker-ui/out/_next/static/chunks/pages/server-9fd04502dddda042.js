(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[753],{41171:function(e,t,n){(window.__NEXT_P=window.__NEXT_P||[]).push(["/server",function(){return n(95319)}])},4845:function(e,t,n){"use strict";var l=n(85893),r=n(89262),o=n(67294),i=n(25934),s=n(99429),a=n(56903),c=n(25137);let u=(0,r.ZP)(a.Z)({justifyContent:"flex-end",width:"100%"});t.Z=e=>{let{actions:t=[],loading:n}=e,r=(0,o.useMemo)(()=>t.map(e=>(0,l.jsx)(s.Z,{...e,children:e.children},(0,i.Z)())),[t]);return n?(0,l.jsx)(c.Z,{mt:0}):(0,l.jsx)(u,{row:!0,spacing:".5em",children:r})}},77583:function(e,t,n){"use strict";var l=n(85893),r=n(14440),o=n(67294),i=n(33544),s=n(56903),a=n(87006),c=n(59278);let u=(0,o.forwardRef)((e,t)=>{let{actionCancelText:n="Cancel",actionProceedText:u,children:d,closeOnProceed:h=!1,contentContainerProps:p,dialogProps:f,disableProceed:m,loading:g,loadingAction:v=!1,onActionAppend:x,onCancelAppend:b,onProceedAppend:j,openInitially:_,preActionArea:w,proceedButtonProps:Z,proceedColour:y="blue",scrollContent:C=!1,scrollBoxProps:k,showActionArea:P=!0,showCancel:M,showClose:O,titleText:V,wide:z,content:A=d}=e,N=(0,o.useRef)(null),S=(0,o.useMemo)(()=>(0,a.Z)(A,c.Ac),[A]),E=(0,o.useMemo)(()=>(0,o.createElement)(C?i.VZ:r.Z,k,S),[S,k,C]),D=(0,o.useMemo)(()=>P&&(0,l.jsx)(i.ux,{cancelProps:{children:n,onClick:function(){for(var e=arguments.length,t=Array(e),n=0;n<e;n++)t[n]=arguments[n];null==x||x.call(null,...t),null==b||b.call(null,...t)}},closeOnProceed:h,loading:v,proceedProps:{background:y,children:u,disabled:m,onClick:function(){for(var e=arguments.length,t=Array(e),n=0;n<e;n++)t[n]=arguments[n];null==x||x.call(null,...t),null==j||j.call(null,...t)},...Z},showCancel:M}),[n,u,h,m,v,x,b,j,Z,y,P,M]);return(0,o.useImperativeHandle)(t,()=>({setOpen:e=>{var t;return null===(t=N.current)||void 0===t?void 0:t.setOpen(e)}}),[]),(0,l.jsx)(i.Js,{dialogProps:f,header:V,loading:g,openInitially:_,ref:N,showClose:O,wide:z,children:(0,l.jsxs)(s.Z,{...p,children:[E,w,D]})})});u.displayName="ConfirmDialog",t.Z=u},33544:function(e,t,n){"use strict";n.d(t,{ux:function(){return h},VZ:function(){return j},Js:function(){return w}});var l=n(85893),r=n(92309),o=n(67294),i=n(23930),s=n(25137);let a=(0,o.createContext)(void 0),c=(0,o.forwardRef)((e,t)=>{let{children:n,dialogProps:c={},loading:u,openInitially:d=!1,wide:h}=e,{open:p,PaperProps:f={},...m}=c,{sx:g,...v}=f,[x,b]=(0,o.useState)(d),j=(0,o.useMemo)(()=>null!=p?p:x,[x,p]),_=(0,o.useMemo)(()=>u?(0,l.jsx)(s.Z,{mt:0}):n,[n,u]),w=(0,o.useMemo)(()=>({minWidth:h?{xs:"calc(100%)",md:"50em"}:null,overflow:"visible",...g}),[g,h]);return(0,o.useImperativeHandle)(t,()=>({open:j,setOpen:b}),[j]),(0,l.jsx)(r.Z,{open:j,PaperComponent:i.s_,PaperProps:{...v,sx:w},...m,children:(0,l.jsx)(a.Provider,{value:{open:j,setOpen:b},children:_})})});c.displayName="Dialog";var u=n(4845);let d=function(e){let{handlers:{base:t,origin:n}}=e;for(var l=arguments.length,r=Array(l>1?l-1:0),o=1;o<l;o++)r[o-1]=arguments[o];null==t||t.call(null,...r),null==n||n.call(null,...r)};var h=e=>{let{cancelProps:t,closeOnProceed:n,loading:r=!1,onCancel:i=d,onProceed:s=d,proceedColour:c,proceedProps:h,showCancel:p=!0,cancelChildren:f=null==t?void 0:t.children,proceedChildren:m=null==h?void 0:h.children}=e,g=(0,o.useContext)(a),v=(0,o.useCallback)(function(){for(var e=arguments.length,n=Array(e),l=0;l<e;l++)n[l]=arguments[l];return i({handlers:{base:()=>{null==g||g.setOpen(!1)},origin:null==t?void 0:t.onClick}},...n)},[null==t?void 0:t.onClick,g,i]),x=(0,o.useCallback)(function(){for(var e=arguments.length,t=Array(e),l=0;l<e;l++)t[l]=arguments[l];return s({handlers:{base:()=>{n&&(null==g||g.setOpen(!1))},origin:null==h?void 0:h.onClick}},...t)},[n,g,s,null==h?void 0:h.onClick]);return(0,o.useMemo)(()=>{let e=[{background:c,...h,children:m,onClick:x}];return p&&e.unshift({...t,children:f,onClick:v}),(0,l.jsx)(u.Z,{actions:e,loading:r})},[f,v,t,r,m,c,x,h,p])},p=n(65895),f=n(87006),m=n(59278),g=e=>{let{children:t,onClose:n=function(e){let{handlers:{base:t}}=e;for(var n=arguments.length,l=Array(n>1?n-1:0),r=1;r<n;r++)l[r-1]=arguments[r];return null==t?void 0:t.call(null,...l)},showClose:r}=e,s=(0,o.useContext)(a),c=(0,o.useCallback)(function(){for(var e=arguments.length,t=Array(e),l=0;l<e;l++)t[l]=arguments[l];return n({handlers:{base:()=>{null==s||s.setOpen(!1)}}},...t)},[s,n]),u=(0,o.useMemo)(()=>(0,f.Z)(t,m.z),[t]),d=(0,o.useMemo)(()=>r&&(0,l.jsx)(p.Z,{mapPreset:"close",onClick:c,size:"small"}),[c,r]);return(0,l.jsxs)(i.V9,{children:[u,d]})},v=n(89262),x=n(14440);let b=(0,v.ZP)(x.Z)({overflowY:"scroll",paddingRight:".4em"});var j=(0,v.ZP)(b)({maxHeight:"60vh"});let _=(0,o.forwardRef)((e,t)=>{let{children:n,dialogProps:r,header:o,loading:i,onClose:s,openInitially:a,showClose:u,wide:d}=e;return(0,l.jsxs)(c,{dialogProps:r,loading:i,openInitially:a,ref:t,wide:d,children:[(0,l.jsx)(g,{onClose:s,showClose:u,children:o}),n]})});_.displayName="DialogWithHeader";var w=_},39937:function(e,t,n){"use strict";n.d(t,{Z:function(){return E}});var l=n(85893),r=n(19338),o=n(89262),i=n(32653),s=n(14440),a=n(34815),c=n(80594),u=n(67294),d=n(77831),h=n(55278),p=n(26076),f=n(8489),m=n(37969),g=n(54965),v=n(49520);let x=[{text:"Anvil",image:"/pngs/anvil_icon_on.png",uri:"/manage-element"},{text:"Files",image:"/pngs/files_on.png",uri:"/file-manager"},{text:"Configure",image:"/pngs/configure_icon_on.png",uri:"/config"},{text:"Mail",image:"/pngs/email_on.png",uri:"/mail-config"},{text:"Help",image:"/pngs/help_icon_on.png",uri:"https://alteeve.com/w/Support"}],b={width:"40em",height:"40em"};var j=n(98484),_=n(29535),w=n(56903),Z=n(97607),y=n(59278),C=n(6946);let k="AnvilDrawer",P={actionIcon:"".concat(k,"-actionIcon"),list:"".concat(k,"-list")},M=(0,o.ZP)(f.ZP)(()=>({["& .".concat(P.list)]:{width:"200px"},["& .".concat(P.actionIcon)]:{fontSize:"2.3em",color:d.of}}));var O=e=>{let{open:t,setOpen:n}=e,{getSessionUser:r}=(0,C.Z)(),o=r();return(0,l.jsx)(M,{BackdropProps:{invisible:!0},anchor:"left",open:t,onClose:()=>n(!t),children:(0,l.jsx)("div",{role:"presentation",children:(0,l.jsxs)(m.Z,{className:P.list,children:[(0,l.jsx)(g.ZP,{children:(0,l.jsx)(y.Ac,{children:o?(0,l.jsxs)(l.Fragment,{children:["Welcome, ",o.name]}):"Unregistered"})}),(0,l.jsx)(_.Z,{}),(0,l.jsx)(v.Z,{component:"a",href:"/index.html",children:(0,l.jsxs)(w.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,l.jsx)(h.Z,{className:P.actionIcon}),(0,l.jsx)(y.Ac,{children:"Dashboard"})]})}),x.map(e=>(0,l.jsx)(v.Z,{component:"a",href:e.uri,children:(0,l.jsxs)(w.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,l.jsx)("img",{alt:e.text,src:e.image,...b}),(0,l.jsx)(y.Ac,{children:e.text})]})},"anvil-drawer-".concat(e.image))),(0,l.jsx)(v.Z,{onClick:()=>{j.Z.put("/auth/logout").then(()=>{window.location.replace("/login")}).catch(e=>{(0,Z.Z)(e)})},children:(0,l.jsxs)(w.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,l.jsx)(p.Z,{className:P.actionIcon}),(0,l.jsx)(y.Ac,{children:"Logout"})]})})]})})})},V=n(85838),z=n(39333);let A="Header",N={input:"".concat(A,"-input"),barElement:"".concat(A,"-barElement"),iconBox:"".concat(A,"-iconBox"),searchBar:"".concat(A,"-searchBar"),icons:"".concat(A,"-icons")},S=(0,o.ZP)(i.Z)(e=>{let{theme:t}=e;return{paddingTop:t.spacing(.5),paddingBottom:t.spacing(.5),paddingLeft:t.spacing(3),paddingRight:t.spacing(3),borderBottom:"solid 1px",borderBottomColor:d.hM,position:"static",["& .".concat(N.input)]:{height:"2.8em",width:"30vw",backgroundColor:t.palette.secondary.main,borderRadius:d.n_},["& .".concat(N.barElement)]:{padding:0},["& .".concat(N.iconBox)]:{[t.breakpoints.down("sm")]:{display:"none"}},["& .".concat(N.searchBar)]:{[t.breakpoints.down("sm")]:{flexGrow:1,paddingLeft:"15vw"}},["& .".concat(N.icons)]:{paddingLeft:".1em",paddingRight:".1em"}}});var E=()=>{let e=(0,u.useRef)({}),t=(0,u.useRef)({}),[n,o]=(0,u.useState)(!1);return(0,l.jsxs)(l.Fragment,{children:[(0,l.jsx)(S,{children:(0,l.jsxs)(s.Z,{display:"flex",justifyContent:"space-between",flexDirection:"row",children:[(0,l.jsx)(w.Z,{row:!0,children:(0,l.jsx)(a.Z,{onClick:()=>o(!n),children:(0,l.jsx)("img",{alt:"",src:"/pngs/logo.png",width:"160",height:"40"})})}),(0,l.jsx)(w.Z,{className:N.iconBox,row:!0,spacing:0,children:(0,l.jsx)(s.Z,{children:(0,l.jsx)(c.Z,{onClick:e=>{var n,l;let{currentTarget:r}=e;null===(n=t.current.setAnchor)||void 0===n||n.call(null,r),null===(l=t.current.setOpen)||void 0===l||l.call(null,!0)},sx:{color:d.of,padding:"0 .1rem"},children:(0,l.jsx)(V.Z,{icon:r.Z,ref:e})})})})]})}),(0,l.jsx)(O,{open:n,setOpen:o}),(0,l.jsx)(z.Z,{onFetchSuccessAppend:t=>{var n;null===(n=e.current.indicate)||void 0===n||n.call(null,Object.keys(t).length>0)},ref:t})]})}},23833:function(e,t,n){"use strict";var l=n(85893),r=n(73970),o=n(85959),i=n(77831);t.Z=e=>{let{children:t,sx:n}=e,s={backgroundColor:i.lD,paddingRight:"3em",["&.".concat(r.Z.selected)]:{backgroundColor:i.s7,fontWeight:400,["&.".concat(r.Z.focusVisible)]:{backgroundColor:i.s7},"&:hover":{backgroundColor:i.s7}},["&.".concat(r.Z.focusVisible)]:{backgroundColor:i.s7},"&:hover":{backgroundColor:i.s7},...n};return(0,l.jsx)(o.Z,{...e,sx:s,children:t})}},87006:function(e,t,n){"use strict";var l=n(67294);t.Z=(e,t)=>"string"==typeof e?(0,l.createElement)(t,null,e):e},27095:function(e,t,n){"use strict";var l=n(74762),r=n(85893);t.Z=(0,l.Z)((0,r.jsx)("path",{d:"M20 3H4c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h6v2H8v2h8v-2h-2v-2h6c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2"}),"DesktopWindows")},53183:function(e,t,n){"use strict";var l=n(74762),r=n(85893);t.Z=(0,l.Z)((0,r.jsx)("path",{d:"M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"}),"Fullscreen")},24378:function(e,t,n){"use strict";var l=n(74762),r=n(85893);t.Z=(0,l.Z)((0,r.jsx)("path",{d:"M20 5H4c-1.1 0-1.99.9-1.99 2L2 17c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm-9 3h2v2h-2V8zm0 3h2v2h-2v-2zM8 8h2v2H8V8zm0 3h2v2H8v-2zm-1 2H5v-2h2v2zm0-3H5V8h2v2zm9 7H8v-2h8v2zm0-4h-2v-2h2v2zm0-3h-2V8h2v2zm3 3h-2v-2h2v2zm0-3h-2V8h2v2z"}),"Keyboard")},14789:function(e,t,n){"use strict";var l=n(74762),r=n(85893);t.Z=(0,l.Z)((0,r.jsx)("path",{d:"M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"}),"MoreVert")},5552:function(e,t,n){"use strict";var l=n(74762),r=n(85893);t.Z=(0,l.Z)((0,r.jsx)("path",{d:"M13 3h-2v10h2V3zm4.83 2.17-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z"}),"PowerSettingsNew")},59826:function(e,t,n){"use strict";var l=n(74762),r=n(85893);t.Z=(0,l.Z)((0,r.jsx)("path",{d:"M13 3h-2v10h2V3zm4.83 2.17-1.42 1.42C17.99 7.86 19 9.81 19 12c0 3.87-3.13 7-7 7s-7-3.13-7-7c0-2.19 1.01-4.14 2.58-5.42L6.17 5.17C4.23 6.82 3 9.26 3 12c0 4.97 4.03 9 9 9s9-4.03 9-9c0-2.74-1.23-5.18-3.17-6.83z"}),"PowerSettingsNewOutlined")},28864:function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),function(e,t){for(var n in t)Object.defineProperty(e,n,{enumerable:!0,get:t[n]})}(t,{default:function(){return s},noSSR:function(){return i}});let l=n(38754);n(85893),n(67294);let r=l._(n(56016));function o(e){return{default:(null==e?void 0:e.default)||e}}function i(e,t){return delete t.webpack,delete t.modules,e(t)}function s(e,t){let n=r.default,l={loading:e=>{let{error:t,isLoading:n,pastDelay:l}=e;return null}};e instanceof Promise?l.loader=()=>e:"function"==typeof e?l.loader=e:"object"==typeof e&&(l={...l,...e});let s=(l={...l,...t}).loader;return(l.loadableGenerated&&(l={...l,...l.loadableGenerated},delete l.loadableGenerated),"boolean"!=typeof l.ssr||l.ssr)?n({...l,loader:()=>null!=s?s().then(o):Promise.resolve(o(()=>null))}):(delete l.webpack,delete l.modules,i(n,l))}("function"==typeof t.default||"object"==typeof t.default&&null!==t.default)&&void 0===t.default.__esModule&&(Object.defineProperty(t.default,"__esModule",{value:!0}),Object.assign(t.default,t),e.exports=t.default)},60572:function(e,t,n){"use strict";Object.defineProperty(t,"__esModule",{value:!0}),Object.defineProperty(t,"LoadableContext",{enumerable:!0,get:function(){return l}});let l=n(38754)._(n(67294)).default.createContext(null)},56016:function(e,t,n){"use strict";/**
@copyright (c) 2017-present James Kyle <me@thejameskyle.com>
 MIT License
 Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
 The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
*/Object.defineProperty(t,"__esModule",{value:!0}),Object.defineProperty(t,"default",{enumerable:!0,get:function(){return h}});let l=n(38754)._(n(67294)),r=n(60572),o=[],i=[],s=!1;function a(e){let t=e(),n={loading:!0,loaded:null,error:null};return n.promise=t.then(e=>(n.loading=!1,n.loaded=e,e)).catch(e=>{throw n.loading=!1,n.error=e,e}),n}class c{promise(){return this._res.promise}retry(){this._clearTimeouts(),this._res=this._loadFn(this._opts.loader),this._state={pastDelay:!1,timedOut:!1};let{_res:e,_opts:t}=this;e.loading&&("number"==typeof t.delay&&(0===t.delay?this._state.pastDelay=!0:this._delay=setTimeout(()=>{this._update({pastDelay:!0})},t.delay)),"number"==typeof t.timeout&&(this._timeout=setTimeout(()=>{this._update({timedOut:!0})},t.timeout))),this._res.promise.then(()=>{this._update({}),this._clearTimeouts()}).catch(e=>{this._update({}),this._clearTimeouts()}),this._update({})}_update(e){this._state={...this._state,error:this._res.error,loaded:this._res.loaded,loading:this._res.loading,...e},this._callbacks.forEach(e=>e())}_clearTimeouts(){clearTimeout(this._delay),clearTimeout(this._timeout)}getCurrentValue(){return this._state}subscribe(e){return this._callbacks.add(e),()=>{this._callbacks.delete(e)}}constructor(e,t){this._loadFn=e,this._opts=t,this._callbacks=new Set,this._delay=null,this._timeout=null,this.retry()}}function u(e){return function(e,t){let n=Object.assign({loader:null,loading:null,delay:200,timeout:null,webpack:null,modules:null},t),o=null;function a(){if(!o){let t=new c(e,n);o={getCurrentValue:t.getCurrentValue.bind(t),subscribe:t.subscribe.bind(t),retry:t.retry.bind(t),promise:t.promise.bind(t)}}return o.promise()}if(!s){let e=n.webpack?n.webpack():n.modules;e&&i.push(t=>{for(let n of e)if(t.includes(n))return a()})}function u(e,t){!function(){a();let e=l.default.useContext(r.LoadableContext);e&&Array.isArray(n.modules)&&n.modules.forEach(t=>{e(t)})}();let i=l.default.useSyncExternalStore(o.subscribe,o.getCurrentValue,o.getCurrentValue);return l.default.useImperativeHandle(t,()=>({retry:o.retry}),[]),l.default.useMemo(()=>{var t;return i.loading||i.error?l.default.createElement(n.loading,{isLoading:i.loading,pastDelay:i.pastDelay,timedOut:i.timedOut,error:i.error,retry:o.retry}):i.loaded?l.default.createElement((t=i.loaded)&&t.default?t.default:t,e):null},[e,i])}return u.preload=()=>a(),u.displayName="LoadableComponent",l.default.forwardRef(u)}(a,e)}function d(e,t){let n=[];for(;e.length;){let l=e.pop();n.push(l(t))}return Promise.all(n).then(()=>{if(e.length)return d(e,t)})}u.preloadAll=()=>new Promise((e,t)=>{d(o).then(e,t)}),u.preloadReady=e=>(void 0===e&&(e=[]),new Promise(t=>{let n=()=>(s=!0,t());d(i,e).then(n,n)})),window.__NEXT_PRELOADREADY=u.preloadReady;let h=u},95319:function(e,t,n){"use strict";n.r(t);var l=n(85893),r=n(89262),o=n(14440),i=n(9008),s=n.n(i),a=n(11163),c=n(67294),u=n(93016),d=n(39937);let h="Server",p={preview:"".concat(h,"-preview"),fullView:"".concat(h,"-fullView")},f=(0,r.ZP)("div")(e=>{let{theme:t}=e;return{["& .".concat(p.preview)]:{width:"25%",height:"100%",[t.breakpoints.down("md")]:{width:"100%"}},["& .".concat(p.fullView)]:{display:"flex",flexDirection:"row",width:"100%",justifyContent:"center"}}});t.default=()=>{let[e,t]=(0,c.useState)(!0),{server_name:n,server_state:r,uuid:i,vnc:h}=(0,a.useRouter)().query,m=((null==h?void 0:h.toString())||"").length>0,g=(null==n?void 0:n.toString())||"",v=(null==r?void 0:r.toString())||"",x=(null==i?void 0:i.toString())||"";return(0,c.useEffect)(()=>{m&&t(!1)},[m]),(0,l.jsxs)(f,{children:[(0,l.jsx)(s(),{children:(0,l.jsx)("title",{children:g})}),(0,l.jsx)(d.Z,{}),e?(0,l.jsx)(o.Z,{className:p.preview,children:(0,l.jsx)(u.M,{onClickPreview:()=>{t(!1)},serverName:g,serverState:v,serverUUID:x})}):(0,l.jsx)(o.Z,{className:p.fullView,children:(0,l.jsx)(u.S,{onClickCloseButton:()=>{t(!0)},serverUUID:x,serverName:g})})]})}},5152:function(e,t,n){e.exports=n(28864)},11163:function(e,t,n){e.exports=n(9090)}},function(e){e.O(0,[572,318,341,616,16,888,774,179],function(){return e(e.s=41171)}),_N_E=e.O()}]);