"use strict";(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[170],{3170:function(e,n,r){r.d(n,{S:function(){return re},M:function(){return pe}});var t=r(5893),o=r(791),i=r(5537),l=r(4433),c=r(1496),a=r(7357),u=r(8333),s=r(5861),f=r(5152),d=r(7294),v=r(7971),m="0xffe3",h="0xffe9",p=[{keys:"Ctrl + Alt + Delete",scans:[]},{keys:"Ctrl + Alt + F1",scans:[m,h,"0xffbe"]},{keys:"Ctrl + Alt + F2",scans:[m,h,"0xffbf"]},{keys:"Ctrl + Alt + F3",scans:[m,h,"0xffc0"]},{keys:"Ctrl + Alt + F4",scans:[m,h,"0xffc1"]},{keys:"Ctrl + Alt + F5",scans:[m,h,"0xffc2"]},{keys:"Ctrl + Alt + F6",scans:[m,h,"0xffc3"]},{keys:"Ctrl + Alt + F7",scans:[m,h,"0xffc4"]},{keys:"Ctrl + Alt + F8",scans:[m,h,"0xffc5"]},{keys:"Ctrl + Alt + F9",scans:[m,h,"0xffc6"]}],y=r(4427),b=r(3679),x=r(1706),g=r(4390),j=r(4685),w=r(4825),C=r(5722);function S(e,n){(null==n||n>e.length)&&(n=e.length);for(var r=0,t=new Array(n);r<n;r++)t[r]=e[r];return t}function O(e,n,r){return n in e?Object.defineProperty(e,n,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[n]=r,e}function P(e,n){return function(e){if(Array.isArray(e))return e}(e)||function(e,n){var r=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=r){var t,o,i=[],l=!0,c=!1;try{for(r=r.call(e);!(l=(t=r.next()).done)&&(i.push(t.value),!n||i.length!==n);l=!0);}catch(a){c=!0,o=a}finally{try{l||null==r.return||r.return()}finally{if(c)throw o}}return i}}(e,n)||k(e,n)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function A(e){return function(e){if(Array.isArray(e))return S(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||k(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function k(e,n){if(e){if("string"===typeof e)return S(e,n);var r=Object.prototype.toString.call(e).slice(8,-1);return"Object"===r&&e.constructor&&(r=e.constructor.name),"Map"===r||"Set"===r?Array.from(r):"Arguments"===r||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r)?S(e,n):void 0}}var I=function(e){var n=e.getItemDisabled,r=e.items,o=void 0===r?{}:r,i=e.muiMenuProps,l=e.onItemClick,c=e.open,a=e.renderItem,s=(0,d.useMemo)((function(){return Object.entries(o)}),[o]),f=(0,d.useMemo)((function(){return s.map((function(e){var r=P(e,2),o=r[0],i=r[1];return(0,t.jsx)(y.Z,{disabled:null===n||void 0===n?void 0:n.call(null,o,i),onClick:function(){for(var e=arguments.length,n=new Array(e),r=0;r<e;r++)n[r]=arguments[r];var t;return null===l||void 0===l?void 0:(t=l).call.apply(t,[null,o,i].concat(A(n)))},children:null===a||void 0===a?void 0:a.call(null,o,i)},o)}))}),[n,l,s,a]);return(0,t.jsx)(u.Z,function(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{},t=Object.keys(r);"function"===typeof Object.getOwnPropertySymbols&&(t=t.concat(Object.getOwnPropertySymbols(r).filter((function(e){return Object.getOwnPropertyDescriptor(r,e).enumerable})))),t.forEach((function(n){O(e,n,r[n])}))}return e}({open:c},i,{children:f}))};function Z(e,n){(null==n||n>e.length)&&(n=e.length);for(var r=0,t=new Array(n);r<n;r++)t[r]=e[r];return t}function E(e,n,r){return n in e?Object.defineProperty(e,n,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[n]=r,e}function F(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{},t=Object.keys(r);"function"===typeof Object.getOwnPropertySymbols&&(t=t.concat(Object.getOwnPropertySymbols(r).filter((function(e){return Object.getOwnPropertyDescriptor(r,e).enumerable})))),t.forEach((function(n){E(e,n,r[n])}))}return e}function M(e,n){if(null==e)return{};var r,t,o=function(e,n){if(null==e)return{};var r,t,o={},i=Object.keys(e);for(t=0;t<i.length;t++)r=i[t],n.indexOf(r)>=0||(o[r]=e[r]);return o}(e,n);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(t=0;t<i.length;t++)r=i[t],n.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(o[r]=e[r])}return o}function D(e){return function(e){if(Array.isArray(e))return Z(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||function(e,n){if(!e)return;if("string"===typeof e)return Z(e,n);var r=Object.prototype.toString.call(e).slice(8,-1);"Object"===r&&e.constructor&&(r=e.constructor.name);if("Map"===r||"Set"===r)return Array.from(r);if("Arguments"===r||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r))return Z(e,n)}(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var T=function(e){var n=e.children,r=e.containedButtonProps,o=e.iconButtonProps,i=e.muiMenuProps,l=e.onButtonClick,c=e.onItemClick,u=e.variant,s=void 0===u?"icon":u,f=M(e,["children","containedButtonProps","iconButtonProps","muiMenuProps","onButtonClick","onItemClick","variant"]),v=(0,d.useState)(null),m=v[0],h=v[1],p=(0,d.useMemo)((function(){return Boolean(m)}),[m]),y=(0,d.useMemo)((function(){return n||("icon"===s?(0,t.jsx)(j.Z,{fontSize:null===o||void 0===o?void 0:o.size}):"Options")}),[n,null===o||void 0===o?void 0:o.size,s]),b=(0,d.useCallback)((function(){for(var e=arguments.length,n=new Array(e),r=0;r<e;r++)n[r]=arguments[r];var t,o=n[0].currentTarget;return h(o),null===l||void 0===l?void 0:(t=l).call.apply(t,[null].concat(D(n)))}),[l]),x=(0,d.useMemo)((function(){return"contained"===s?(0,t.jsx)(w.Z,F({onClick:b},r,{children:y})):(0,t.jsx)(C.Z,F({onClick:b},o,{children:y}))}),[b,y,r,o,s]),g=(0,d.useCallback)((function(e,n){for(var r=arguments.length,t=new Array(r>2?r-2:0),o=2;o<r;o++)t[o-2]=arguments[o];var i;return h(null),null===c||void 0===c?void 0:(i=c).call.apply(i,[null,e,n].concat(D(t)))}),[c]);return(0,t.jsxs)(a.Z,{children:[x,(0,t.jsx)(I,F({muiMenuProps:F({anchorEl:m,keepMounted:!0,onClose:function(){return h(null)}},i),onItemClick:g,open:p},f))]})},U=r(1770),B=r(7750),z=r(157),N=r(8187);function _(e,n,r){return n in e?Object.defineProperty(e,n,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[n]=r,e}function R(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{},t=Object.keys(r);"function"===typeof Object.getOwnPropertySymbols&&(t=t.concat(Object.getOwnPropertySymbols(r).filter((function(e){return Object.getOwnPropertyDescriptor(r,e).enumerable})))),t.forEach((function(n){_(e,n,r[n])}))}return e}var L=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.initial,r=void 0===n?{}:n,o=r.actionProceedText,i=void 0===o?"":o,l=r.content,c=void 0===l?"":l,a=r.titleText,u=void 0===a?"":a,s=(0,d.useRef)(null),f=(0,d.useState)({actionProceedText:i,content:c,titleText:u}),v=f[0],m=f[1],h=(0,d.useCallback)((function(e){var n,r;return null===s||void 0===s||null===(n=s.current)||void 0===n||null===(r=n.setOpen)||void 0===r?void 0:r.call(null,e)}),[]),p=(0,d.useCallback)((function(e,n){return m({actionProceedText:"",content:(0,t.jsx)(N.Z,R({},n)),showActionArea:!1,showClose:!0,titleText:e})}),[]),y=(0,d.useMemo)((function(){return(0,t.jsx)(z.Z,R({},v,{ref:s}))}),[v]);return{confirmDialog:y,confirmDialogRef:s,setConfirmDialogOpen:h,setConfirmDialogProps:m,finishConfirm:p}};function $(e,n,r){return n in e?Object.defineProperty(e,n,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[n]=r,e}function q(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{},t=Object.keys(r);"function"===typeof Object.getOwnPropertySymbols&&(t=t.concat(Object.getOwnPropertySymbols(r).filter((function(e){return Object.getOwnPropertyDescriptor(r,e).enumerable})))),t.forEach((function(n){$(e,n,r[n])}))}return e}function G(e,n){if(null==e)return{};var r,t,o=function(e,n){if(null==e)return{};var r,t,o={},i=Object.keys(e);for(t=0;t<i.length;t++)r=i[t],n.indexOf(r)>=0||(o[r]=e[r]);return o}(e,n);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(t=0;t<i.length;t++)r=i[t],n.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(o[r]=e[r])}return o}var J=function(e){e.getItemDisabled,e.items,e.onItemClick,e.renderItem;var n,r=e.serverName,o=e.serverState,i=e.serverUuid,l=G(e,["getItemDisabled","items","onItemClick","renderItem","serverName","serverState","serverUuid"]),c=L(),u=c.confirmDialog,s=c.setConfirmDialogOpen,f=c.setConfirmDialogProps,v=c.finishConfirm,m=(0,d.useMemo)((function(){return{"force-off":{colour:"red",description:(0,t.jsx)(t.Fragment,{children:"This is equal to pulling the power cord, which may cause data loss or system corruption."}),label:"Force off",path:"/command/stop-server/".concat(i,"?force=1")},"power-off":{description:(0,t.jsx)(t.Fragment,{children:"This is equal to pushing the power button. If the server doesn't respond to the corresponding signals, you may have to manually shut it down."}),label:"Power off",path:"/command/stop-server/".concat(i)},"power-on":{description:(0,t.jsx)(t.Fragment,{children:"This is equal to pushing the power button."}),label:"Power on",path:"/command/start-server/".concat(i)}}}),[i]);return(0,t.jsxs)(a.Z,{children:[(0,t.jsx)(T,q({getItemDisabled:function(e){var n=e.includes("on");return"running"===o===n},items:m,onItemClick:function(e,n){var o=n.colour,i=n.description,l=n.label,c=n.path,a=l.toLocaleLowerCase();f({actionProceedText:l,content:(0,t.jsx)(B.Ac,{children:i}),onProceedAppend:function(){f((function(e){return q({},e,{loading:!0})})),g.Z.put(c).then((function(){v("Success",{children:(0,t.jsxs)(t.Fragment,{children:["Successfully registered ",a," job on ",r,"."]})})})).catch((function(e){var n=(0,U.Z)(e);n.children=(0,t.jsxs)(t.Fragment,{children:["Failed to register ",a," job on ",r,"; CAUSE:"," ",n.children,"."]}),v("Error",n)}))},proceedColour:o,titleText:"".concat(l," server ").concat(r,"?")}),s(!0)},renderItem:function(e,n){var r,o=n.colour,i=n.label;return o&&(r=w.D[o]),(0,t.jsx)(B.Ac,{inheritColour:!0,color:r,children:i})}},l,{children:(0,t.jsx)(x.Z,{fontSize:null===l||void 0===l||null===(n=l.iconButtonProps)||void 0===n?void 0:n.size})})),u]})},K=r(2152),V=r(1081);function H(e,n){(null==n||n>e.length)&&(n=e.length);for(var r=0,t=new Array(n);r<n;r++)t[r]=e[r];return t}function Q(e,n,r){return n in e?Object.defineProperty(e,n,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[n]=r,e}function W(e){return function(e){if(Array.isArray(e))return H(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||function(e,n){if(!e)return;if("string"===typeof e)return H(e,n);var r=Object.prototype.toString.call(e).slice(8,-1);"Object"===r&&e.constructor&&(r=e.constructor.name);if("Map"===r||"Set"===r)return Array.from(r);if("Arguments"===r||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r))return H(e,n)}(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var X="FullSize",Y={displayBox:"".concat(X,"-displayBox"),spinnerBox:"".concat(X,"-spinnerBox")},ee=(0,c.ZP)("div")((function(){var e;return Q(e={},"& .".concat(Y.displayBox),{width:"75vw",height:"75vh"}),Q(e,"& .".concat(Y.spinnerBox),{flexDirection:"column",width:"75vw",height:"75vh",alignItems:"center",justifyContent:"center"}),e})),ne=(0,f.default)((function(){return Promise.all([r.e(460),r.e(665)]).then(r.bind(r,4665))}),{loadableGenerated:{webpack:function(){return[4665]}},ssr:!1}),re=function(e){var n=e.onClickCloseButton,r=e.serverUUID,c=e.serverName,f=e.vncReconnectTimerStart,m=void 0===f?5:f,h=(0,V.Z)(),x=(0,d.useState)(null),g=x[0],j=x[1],w=(0,d.useState)(void 0),C=w[0],S=w[1],O=(0,d.useState)(!1),P=O[0],A=O[1],k=(0,d.useState)(!1),I=k[0],Z=k[1],E=(0,d.useState)(m),F=E[0],M=E[1],D=(0,d.useRef)(null),T=(0,d.useRef)(null),U=function(e){j(e.currentTarget)},z=(0,d.useCallback)((function(){var e,n;A(!0),Z(!1),S({url:(e=window.location.host,n=r,"ws://".concat(e,"/ws/server/vnc/").concat(n))})}),[r]),N=(0,d.useCallback)((function(){(null===D||void 0===D?void 0:D.current)&&(D.current.disconnect(),D.current=null),S(void 0)}),[]),_=(0,d.useCallback)((function(){N(),z()}),[z,N]),R=(0,d.useCallback)((function(){var e=setInterval((function(){M((function(n){var r=n-1;return r<1&&clearInterval(e),r}))}),1e3)}),[]),L=(0,d.useCallback)((function(){A(!1)}),[]),$=(0,d.useCallback)((function(e){e.detail.clean||(A(!1),Z(!0),R())}),[R]),q=(0,d.useMemo)((function(){return!P&&!I}),[P,I]),G=(0,d.useMemo)((function(){return(0,t.jsxs)(a.Z,{children:[(0,t.jsx)(v.Z,{onClick:U,children:(0,t.jsx)(o.Z,{})}),(0,t.jsx)(u.Z,{anchorEl:g,keepMounted:!0,open:Boolean(g),onClose:function(){return j(null)},children:p.map((function(e){var n=e.keys,r=e.scans;return(0,t.jsx)(y.Z,{onClick:function(){return function(e){if(D.current){if(e.length){for(var n=0;n<=e.length-1;n+=1)D.current.sendKey(e[n],1);for(var r=e.length-1;r>=0;r-=1)D.current.sendKey(e[r],0)}else D.current.sendCtrlAltDel();j(null)}}(r)},children:(0,t.jsx)(s.Z,{variant:"subtitle1",children:n})},n)}))})]})}),[g]),H=(0,d.useMemo)((function(){return(0,t.jsx)(a.Z,{children:(0,t.jsx)(v.Z,{onClick:function(){for(var e=arguments.length,r=new Array(e),t=0;t<e;t++)r[t]=arguments[t];var o;N(),null===n||void 0===n||(o=n).call.apply(o,[null].concat(W(r)))},children:(0,t.jsx)(i.Z,{})})})}),[N,n]),Q=(0,d.useMemo)((function(){return(0,t.jsx)(a.Z,{children:(0,t.jsx)(v.Z,{onClick:function(){window&&(N(),window.location.assign("/"))},children:(0,t.jsx)(l.Z,{})})})}),[N]),X=(0,d.useMemo)((function(){return q&&(0,t.jsxs)(t.Fragment,{children:[G,(0,t.jsx)(J,{serverName:c,serverState:"running",serverUuid:r}),Q,H]})}),[G,Q,c,r,q,H]);return(0,d.useEffect)((function(){0===F&&(M(m),_())}),[_,F,m]),(0,d.useEffect)((function(){h&&z()}),[z,h]),(0,t.jsxs)(b.s_,{children:[(0,t.jsxs)(b.V9,{children:[(0,t.jsx)(B.z,{text:"Server: ".concat(c)}),X]}),(0,t.jsxs)(ee,{children:[(0,t.jsx)(a.Z,{display:q?"flex":"none",className:Y.displayBox,children:(0,t.jsx)(ne,{onConnect:L,onDisconnect:$,rfb:D,rfbConnectArgs:C,rfbScreen:T})}),!q&&(0,t.jsxs)(a.Z,{display:"flex",className:Y.spinnerBox,children:[P&&(0,t.jsxs)(t.Fragment,{children:[(0,t.jsxs)(B.z,{textAlign:"center",children:["Connecting to ",c,"."]}),(0,t.jsx)(K.Z,{})]}),I&&(0,t.jsxs)(t.Fragment,{children:[(0,t.jsx)(B.z,{textAlign:"center",children:"There was a problem connecting to the server."}),(0,t.jsxs)(B.z,{textAlign:"center",mt:"1em",children:["Retrying in ",F,"."]})]})]})]})]})},te=r(4051),oe=r.n(te),ie=r(5668),le=r(2787),ce=r(4799),ae=r(7169),ue=r(4690),se=r(9370);function fe(e,n,r,t,o,i,l){try{var c=e[i](l),a=c.value}catch(u){return void r(u)}c.done?n(a):Promise.resolve(a).then(t,o)}var de={externalPreview:"",externalTimestamp:0,headerEndAdornment:null,hrefPreview:void 0,isExternalLoading:!1,isExternalPreviewStale:!1,isFetchPreview:!0,isShowControls:!0,isUseInnerPanel:!1,onClickConnectButton:void 0,onClickPreview:void 0,serverName:"",serverState:""},ve=function(e){var n=e.children;return e.isUseInnerPanel?(0,t.jsx)(b.Lg,{children:n}):(0,t.jsx)(b.s_,{children:n})},me=function(e){var n=e.children,r=e.isUseInnerPanel,o=e.text;return r?(0,t.jsxs)(b.CH,{children:[o?(0,t.jsx)(B.Ac,{text:o}):(0,t.jsx)(t.Fragment,{}),n]}):(0,t.jsxs)(b.V9,{children:[o?(0,t.jsx)(B.z,{text:o}):(0,t.jsx)(t.Fragment,{}),n]})},he=function(e){var n=e.externalPreview,r=void 0===n?de.externalPreview:n,o=e.externalTimestamp,i=void 0===o?de.externalTimestamp:o,l=e.headerEndAdornment,c=e.hrefPreview,u=e.isExternalLoading,s=void 0===u?de.isExternalLoading:u,f=e.isExternalPreviewStale,m=void 0===f?de.isExternalPreviewStale:f,h=e.isFetchPreview,p=void 0===h?de.isFetchPreview:h,y=e.isShowControls,b=void 0===y?de.isShowControls:y,x=e.isUseInnerPanel,j=void 0===x?de.isUseInnerPanel:x,w=e.onClickPreview,C=e.serverName,S=void 0===C?de.serverName:C,O=e.serverState,P=void 0===O?de.serverState:O,A=e.serverUUID,k=e.onClickConnectButton,I=void 0===k?w:k,Z=(0,d.useState)(!0),E=Z[0],F=Z[1],M=(0,d.useState)(!1),D=M[0],T=M[1],U=(0,d.useState)(""),z=U[0],N=U[1],_=(0,d.useState)(0),R=_[0],L=_[1],$=(0,se.zO)(),q=(0,d.useMemo)((function(){return"running"===P?(0,t.jsxs)(t.Fragment,{children:[(0,t.jsx)(a.Z,{alt:"",component:"img",src:"data:image;base64,".concat(z),sx:{height:"100%",opacity:D?"0.4":"1",padding:j?".2em":0,width:"100%"}}),D&&function(e){var n=(0,se._J)($-e),r=n.unit,o=n.value;return(0,t.jsxs)(B.Ac,{position:"absolute",children:["Updated ~",o," ",r," ago"]})}(R)]}):(0,t.jsx)(ie.Z,{sx:{color:ae.UZ,height:"80%",width:"80%"}})}),[D,j,$,z,R,P]),G=(0,d.useMemo)((function(){if(E)return(0,t.jsx)(K.Z,{mb:"1em",mt:"1em"});var e=!z,n={borderRadius:ae.n_,color:ae.s7,padding:0};return c?(0,t.jsx)(ce.Z,{disabled:e,href:c,sx:n,children:q}):(0,t.jsx)(ce.Z,{component:"span",disabled:e,onClick:w,sx:n,children:q})}),[c,E,z,q,w]);return(0,d.useEffect)((function(){var e;p?(e=oe().mark((function e(){var n,r,t;return oe().wrap((function(e){for(;;)switch(e.prev=e.next){case 0:return e.prev=0,e.next=3,g.Z.get("/server/".concat(A,"?ss=1"));case 3:n=e.sent.data,r=n.screenshot,t=n.timestamp,N(r),L(t),T(!(0,se.Z$)(t,300)),e.next=13;break;case 10:e.prev=10,e.t0=e.catch(0),T(!0);case 13:return e.prev=13,F(!1),e.finish(13);case 16:case"end":return e.stop()}}),e,null,[[0,10,13,16]])})),function(){var n=this,r=arguments;return new Promise((function(t,o){var i=e.apply(n,r);function l(e){fe(i,t,o,l,c,"next",e)}function c(e){fe(i,t,o,l,c,"throw",e)}l(void 0)}))})():s||(N(r),L(i),T(m),F(!1))}),[r,i,s,m,p,A]),(0,t.jsxs)(ve,{isUseInnerPanel:j,children:[(0,t.jsxs)(me,{isUseInnerPanel:j,text:S,children:[l,(0,t.jsx)(J,{iconButtonProps:{size:j?"small":void 0},serverName:S,serverState:P,serverUuid:A})]}),(0,t.jsxs)(ue.Z,{row:!0,sx:{"& > :first-child":{flexGrow:1}},children:[(0,t.jsx)(a.Z,{textAlign:"center",children:G}),b&&z&&(0,t.jsx)(ue.Z,{spacing:".3em",children:(0,t.jsx)(v.Z,{onClick:I,children:(0,t.jsx)(le.Z,{})})})]})]})};he.defaultProps=de;var pe=he},9370:function(e,n,r){function t(e,n){(null==n||n>e.length)&&(n=e.length);for(var r=0,t=new Array(n);r<n;r++)t[r]=e[r];return t}function o(e,n,r){return n in e?Object.defineProperty(e,n,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[n]=r,e}function i(e,n){return function(e){if(Array.isArray(e))return e}(e)||function(e,n){var r=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=r){var t,o,i=[],l=!0,c=!1;try{for(r=r.call(e);!(l=(t=r.next()).done)&&(i.push(t.value),!n||i.length!==n);l=!0);}catch(a){c=!0,o=a}finally{try{l||null==r.return||r.return()}finally{if(c)throw o}}return i}}(e,n)||c(e,n)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function l(e){return function(e){if(Array.isArray(e))return t(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||c(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function c(e,n){if(e){if("string"===typeof e)return t(e,n);var r=Object.prototype.toString.call(e).slice(8,-1);return"Object"===r&&e.constructor&&(r=e.constructor.name),"Map"===r||"Set"===r?Array.from(r):"Arguments"===r||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(r)?t(e,n):void 0}}r.d(n,{_J:function(){return s},Z$:function(){return u},zO:function(){return a}});var a=function(e){var n=Date.now();return e||(n=Math.floor(n/1e3)),n},u=function(e,n){var r=(arguments.length>2&&void 0!==arguments[2]?arguments[2]:{}).ms,t=a(r)-e;return t<=n},s=function(e){var n,r=e,t=i(l([60,60].reduce((function(e,n){var t=r%n;return e.push(t),r=(r-t)/n,e}),[])).concat([r]),3),c=t[0],a=t[1],u=t[2],s=null!==(n=[{unit:"h",value:u},{unit:"m",value:a}].find((function(e){return e.value})))&&void 0!==n?n:{unit:"s",value:c};return function(e){for(var n=1;n<arguments.length;n++){var r=null!=arguments[n]?arguments[n]:{},t=Object.keys(r);"function"===typeof Object.getOwnPropertySymbols&&(t=t.concat(Object.getOwnPropertySymbols(r).filter((function(e){return Object.getOwnPropertyDescriptor(r,e).enumerable})))),t.forEach((function(n){o(e,n,r[n])}))}return e}({h:u,m:a,s:c},s)}}}]);