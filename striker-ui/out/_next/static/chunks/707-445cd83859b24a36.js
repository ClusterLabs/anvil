"use strict";(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[707],{4594:function(e,n,t){var r=t(5893),i=t(6514),o=t(5113),a=t(4656),s=t(482),l=t(2994),u=t(7357),c=t(9890),d=t(7169),p=t(1363),f=t(6284);function v(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function m(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){v(e,n,t[n])}))}return e}function x(e,n){if(null==e)return{};var t,r,i=function(e,n){if(null==e)return{};var t,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(i[t]=e[t]);return i}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(i[t]=e[t])}return i}var g=function(e){return(0,r.jsx)(i.Z,{in:!0,children:(0,r.jsx)(o.Z,m({},e))})};n.Z=function(e){var n=e.componentsProps,t=e.extendRenderInput,i=e.label,o=e.messageBoxProps,h=e.renderInput,b=e.sx,y=x(e,["componentsProps","extendRenderInput","label","messageBoxProps","renderInput","sx"]),j=m({paper:{sx:{backgroundColor:d.lD}}},n),U=null!==h&&void 0!==h?h:function(e){var n=e.fullWidth,o=e.InputProps,a=e.InputLabelProps,s=e.inputProps,l={formControlProps:{fullWidth:n,ref:o.ref},inputLabelProps:a,inputProps:{className:o.className,endAdornment:o.endAdornment,inputProps:s,startAdornment:o.startAdornment},label:i};return null===t||void 0===t||t.call(null,l,e),(0,r.jsx)(f.Z,m({},l))},S=m(v({},"& .".concat(a.Z.root," .").concat(s.Z.endAdornment),v({right:"7px"},"& .".concat(l.Z.root),{color:d.s7})),b);return(0,r.jsxs)(u.Z,{sx:{display:"flex",flexDirection:"column"},children:[(0,r.jsx)(c.Z,m({PaperComponent:g},y,{componentsProps:j,renderInput:U,sx:S})),(0,r.jsx)(p.Z,m({},o))]})}},8750:function(e,n,t){t.d(n,{Z:function(){return F}});var r=t(5893),i=t(1113),o=t(1496),a=t(2293),s=t(7357),l=t(2992),u=t(4799),c=t(7294),d=t(7169),p=t(4433),f=t(9029),v=t(7533),m=t(8462),x=t(7212),g=t(8619),h=[{text:"Anvil",image:"/pngs/anvil_icon_on.png",uri:"/manage-element"},{text:"Files",image:"/pngs/files_on.png",uri:"/file-manager"},{text:"Configure",image:"/pngs/configure_icon_on.png",uri:"/config"},{text:"Help",image:"/pngs/help_icon_on.png",uri:"https://alteeve.com/w/Support"}],b={width:"40em",height:"40em"},y=t(4390),j=t(582),U=t(4690),S=t(1770),I=t(7750),P=t(1883);function D(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function O(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){D(e,n,t[n])}))}return e}var Z="AnvilDrawer",w={actionIcon:"".concat(Z,"-actionIcon"),list:"".concat(Z,"-list")},M=(0,o.ZP)(v.ZP)((function(){var e;return D(e={},"& .".concat(w.list),{width:"200px"}),D(e,"& .".concat(w.actionIcon),{fontSize:"2.3em",color:d.of}),e})),C=function(e){var n=e.open,t=e.setOpen,i=(0,(0,P.Z)().getSessionUser)();return(0,r.jsx)(M,{BackdropProps:{invisible:!0},anchor:"left",open:n,onClose:function(){return t(!n)},children:(0,r.jsx)("div",{role:"presentation",children:(0,r.jsxs)(m.Z,{className:w.list,children:[(0,r.jsx)(x.ZP,{children:(0,r.jsx)(I.Ac,{children:i?(0,r.jsxs)(r.Fragment,{children:["Welcome, ",i.name]}):"Unregistered"})}),(0,r.jsx)(j.Z,{}),(0,r.jsx)(g.Z,{component:"a",href:"/index.html",children:(0,r.jsxs)(U.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,r.jsx)(p.Z,{className:w.actionIcon}),(0,r.jsx)(I.Ac,{children:"Dashboard"})]})}),h.map((function(e){return(0,r.jsx)(g.Z,{component:"a",href:e.uri,children:(0,r.jsxs)(U.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,r.jsx)("img",O({alt:e.text,src:e.image},b)),(0,r.jsx)(I.Ac,{children:e.text})]})},"anvil-drawer-".concat(e.image))})),(0,r.jsx)(g.Z,{onClick:function(){y.Z.put("/auth/logout").then((function(){window.location.replace("/login")})).catch((function(e){(0,S.Z)(e)}))},children:(0,r.jsxs)(U.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,r.jsx)(f.Z,{className:w.actionIcon}),(0,r.jsx)(I.Ac,{children:"Logout"})]})})]})})})},k=t(3377),A=t(2444);function G(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}var B="Header",z={input:"".concat(B,"-input"),barElement:"".concat(B,"-barElement"),iconBox:"".concat(B,"-iconBox"),searchBar:"".concat(B,"-searchBar"),icons:"".concat(B,"-icons")},T=(0,o.ZP)(a.Z)((function(e){var n,t=e.theme;return G(n={paddingTop:t.spacing(.5),paddingBottom:t.spacing(.5),paddingLeft:t.spacing(3),paddingRight:t.spacing(3),borderBottom:"solid 1px",borderBottomColor:d.hM,position:"static"},"& .".concat(z.input),{height:"2.8em",width:"30vw",backgroundColor:t.palette.secondary.main,borderRadius:d.n_}),G(n,"& .".concat(z.barElement),{padding:0}),G(n,"& .".concat(z.iconBox),G({},t.breakpoints.down("sm"),{display:"none"})),G(n,"& .".concat(z.searchBar),G({},t.breakpoints.down("sm"),{flexGrow:1,paddingLeft:"15vw"})),G(n,"& .".concat(z.icons),{paddingLeft:".1em",paddingRight:".1em"}),n})),F=function(){var e=(0,c.useRef)({}),n=(0,c.useRef)({}),t=(0,c.useState)(!1),o=t[0],a=t[1];return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(T,{children:(0,r.jsxs)(s.Z,{display:"flex",justifyContent:"space-between",flexDirection:"row",children:[(0,r.jsx)(U.Z,{row:!0,children:(0,r.jsx)(l.Z,{onClick:function(){return a(!o)},children:(0,r.jsx)("img",{alt:"",src:"/pngs/logo.png",width:"160",height:"40"})})}),(0,r.jsx)(U.Z,{className:z.iconBox,row:!0,spacing:0,children:(0,r.jsx)(s.Z,{children:(0,r.jsx)(u.Z,{onClick:function(e){var t,r,i=e.currentTarget;null===(t=n.current.setAnchor)||void 0===t||t.call(null,i),null===(r=n.current.setOpen)||void 0===r||r.call(null,!0)},sx:{color:d.of,padding:"0 .1rem"},children:(0,r.jsx)(k.Z,{icon:i.Z,ref:e})})})})]})}),(0,r.jsx)(C,{open:o,setOpen:a}),(0,r.jsx)(A.Z,{onFetchSuccessAppend:function(n){var t;null===(t=e.current.indicate)||void 0===t||t.call(null,Object.keys(n).length>0)},ref:n})]})}},4427:function(e,n,t){var r=t(5893),i=t(2429),o=t(9309),a=t(7169);function s(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function l(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){s(e,n,t[n])}))}return e}n.Z=function(e){var n,t,u=e.children,c=e.sx,d=l((s(t={backgroundColor:a.lD,paddingRight:"3em"},"&.".concat(i.Z.selected),(s(n={backgroundColor:a.s7,fontWeight:400},"&.".concat(i.Z.focusVisible),{backgroundColor:a.s7}),s(n,"&:hover",{backgroundColor:a.s7}),n)),s(t,"&.".concat(i.Z.focusVisible),{backgroundColor:a.s7}),s(t,"&:hover",{backgroundColor:a.s7}),t),c);return(0,r.jsx)(o.Z,l({},e,{sx:d,children:u}))}},7698:function(e,n,t){t.d(n,{Z:function(){return re}});var r=t(5893),o=t(7294),a=t(7357),s=t(8263),l=t(8262),u=t(5537),c=t(5934),d=t(7169),p=t(4390),f=t(4594),v=t(157),m=t(4825),x=t(5737),g=t(1706),h=t(8187),b=t(6284),y=t(7120),j=t(4656),U=t(1363),S=t(2519);function I(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function P(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){I(e,n,t[n])}))}return e}var D={inputWithLabelProps:{},messageBoxProps:{},selectWithLabelProps:{}},O=function(e){var n=e.id,t=e.label,i=e.inputWithLabelProps,o=void 0===i?D.inputWithLabelProps:i,s=e.messageBoxProps,l=void 0===s?D.messageBoxProps:s,u=e.selectItems,c=e.selectWithLabelProps,p=void 0===c?D.selectWithLabelProps:c;return(0,r.jsxs)(a.Z,{children:[(0,r.jsxs)(a.Z,{sx:I({display:"flex",flexDirection:"row","& > :first-child":{flexGrow:1},"& > :not(:last-child)":{marginRight:".5em"}},"&:hover\n          .".concat(y.Z.root,"\n          .").concat(j.Z.root,"\n          .").concat(j.Z.notchedOutline),{borderColor:d.s7}),children:[(0,r.jsx)(b.Z,P({id:n,label:t},o)),(0,r.jsx)(S.Z,P({formControlProps:{fullWidth:!1,sx:{minWidth:"min-content"}},id:"".concat(n,"-nested-select"),selectItems:u},p))]}),(0,r.jsx)(U.Z,P({},l))]})};O.defaultProps=D;var Z=O,w=t(3679),M=t(2152),C=t(7987),k=t(7750);function A(e,n){(null==n||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function G(e){if(Array.isArray(e))return e}function B(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function z(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}function T(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}function F(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){B(e,n,t[n])}))}return e}function N(e,n){if(null==e)return{};var t,r,i=function(e,n){if(null==e)return{};var t,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(i[t]=e[t]);return i}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(i[t]=e[t])}return i}function L(e,n){return G(e)||function(e,n){var t=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=t){var r,i,o=[],a=!0,s=!1;try{for(t=t.call(e);!(a=(r=t.next()).done)&&(o.push(r.value),!n||o.length!==n);a=!0);}catch(l){s=!0,i=l}finally{try{a||null==t.return||t.return()}finally{if(s)throw i}}return o}}(e,n)||V(e,n)||T()}function E(e){return G(e)||z(e)||V(e,i)||T()}function R(e){return function(e){if(Array.isArray(e))return A(e)}(e)||z(e)||V(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function V(e,n){if(e){if("string"===typeof e)return A(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);return"Object"===t&&e.constructor&&(t=e.constructor.name),"Map"===t||"Set"===t?Array.from(t):"Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t)?A(e,n):void 0}}var W,q,Q=BigInt(0),_=[{value:"B"},{value:"KiB"},{value:"MiB"},{value:"GiB"},{value:"TiB"}],H="GiB",Y=BigInt(65536),J=BigInt(104857600),K={backgroundColor:d.Ej,color:d.lD,"&:hover":{backgroundColor:d.Ej}},X=function(e,n){var t=n.onButtonClick;return(0,r.jsx)(m.Z,{disabled:void 0===t,onClick:t,sx:{minWidth:"unset",whiteSpace:"nowrap"},children:"Max: ".concat(e)})},$=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.endAdornment,t=e.mainLabel,i=e.subLabel;return(0,r.jsxs)(a.Z,{sx:{alignItems:"center",display:"flex",flexDirection:"row",width:"100%","& > :first-child":{flexGrow:1}},children:[(0,r.jsxs)(a.Z,{sx:{display:"flex",flexDirection:"column"},children:[t&&(0,r.jsx)(k.Ac,{inverted:!0,text:t}),i&&(0,r.jsx)(k.Ac,{inverted:!0,text:i})]}),n]})},ee=function(e,n,t,r,i,o,a){var s=arguments.length>7&&void 0!==arguments[7]?arguments[7]:{},l=s.includeAnvilUUIDs,u=void 0===l?[]:l,c=s.includeFileUUIDs,d=void 0===c?[]:c,p=s.includeStorageGroupUUIDs,f=void 0===p?[]:p,v=function(){return!0},m=function(){return!0},x=function(){return!0};u.length>0&&(v=function(e){return u.includes(e)}),d.length>0&&(m=function(e){return d.includes(e)}),f.length>0&&(x=function(e){return f.includes(e)});var g={},h=o.reduce((function(e,n,t){var r,o=null!==(r=i[t])&&void 0!==r?r:Q;return e.all+=o,""===n||(void 0===e[n]&&(e[n]=Q),e[n]+=o),e}),{all:Q}),b=e.reduce((function(e,s){var l=s.anvilUUID;if(v(l)){var u,c=s.anvilTotalCPUCores,d=s.anvilTotalAvailableMemory,p=s.files,f=s.fileUUIDs,b=s.storageGroups,y=[],j=Q,U=Q;if(b.forEach((function(e){var n=e.storageGroupUUID,t=e.storageGroupFree;x(n)&&(y.push(n),U+=t,t>j&&(j=t))})),[function(){return b.length>0},function(){return t<=c},function(){return r<=d},function(){return o.every((function(e,t){var r,o=null!==(r=i[t])&&void 0!==r?r:Q,a=!0,s=o<=j;return""!==e&&(a=y.includes(e),s=o<=n[e].storageGroupFree),a&&s}))},function(){return Object.entries(h).every((function(e){var t=L(e,2),r=t[0],i=t[1];return"all"===r?i<=U:i<=n[r].storageGroupFree}))},function(){return a.every((function(e){return""===e||f.includes(e)}))}].every((function(e){return e()})))e.anvils.push(s),e.anvilUUIDs.push(l),e.maxCPUCores=Math.max(c,e.maxCPUCores),d>e.maxMemory&&(e.maxMemory=d),p.forEach((function(e){var n=e.fileUUID;m(n)&&(g[n]=!0)})),(u=e.storageGroupUUIDs).push.apply(u,R(y)),e.maxVirtualDiskSizes.fill(j)}return e}),{anvils:[],anvilUUIDs:[],fileUUIDs:[],maxCPUCores:0,maxMemory:Q,maxVirtualDiskSizes:o.map((function(){return Q})),storageGroupUUIDs:[]});return b.fileUUIDs=Object.keys(g),o.forEach((function(e,t){""!==e&&(b.maxVirtualDiskSizes[t]=n[e].storageGroupFree)})),b},ne=function(e){return e.filter((function(e){return""!==e}))},te=function(e){return{fromUnit:"B",onSuccess:{string:e},precision:0,toUnit:"ibyte"}};(0,x.Bh)(Y,te((function(e,n){W="".concat(e," ").concat(n)}))),(0,x.Bh)(J,te((function(e,n){q="".concat(e," ").concat(n)})));var re=function(e){var n=e.dialogProps.open,t=e.onClose,i=(0,o.useState)([]),y=i[0],j=i[1],U=(0,o.useState)({}),I=U[0],P=U[1],D=(0,o.useState)({}),O=D[0],A=D[1],G=(0,o.useState)({}),z=G[0],T=G[1],V=(0,o.useState)({}),te=V[0],re=V[1],ie=(0,o.useState)([]),oe=ie[0],ae=ie[1],se=(0,o.useState)([]),le=se[0],ue=se[1],ce=(0,o.useState)([]),de=ce[0],pe=ce[1],fe=(0,o.useState)([]),ve=fe[0],me=fe[1],xe=(0,o.useState)(""),ge=xe[0],he=xe[1],be=(0,o.useState)(),ye=be[0],je=be[1],Ue=(0,o.useState)(1),Se=Ue[0],Ie=Ue[1],Pe=(0,o.useState)(0),De=Pe[0],Oe=Pe[1],Ze=(0,o.useState)(),we=Ze[0],Me=Ze[1],Ce=(0,o.useState)(Q),ke=Ce[0],Ae=Ce[1],Ge=(0,o.useState)(Q),Be=Ge[0],ze=Ge[1],Te=(0,o.useState)(),Fe=Te[0],Ne=Te[1],Le=(0,o.useState)("0"),Ee=Le[0],Re=Le[1],Ve=(0,o.useState)(""),We=Ve[0],qe=Ve[1],Qe=(0,o.useState)(H),_e=Qe[0],He=Qe[1],Ye=(0,o.useState)(function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.existingVirtualDisks,t=void 0===n?{stateIds:[],inputMaxes:[],inputSizeMessages:[],inputSizes:[],inputStorageGroupUUIDMessages:[],inputStorageGroupUUIDs:[],inputUnits:[],maxes:[],sizes:[]}:n,r=e.stateId,i=void 0===r?(0,c.Z)():r,o=e.inputMax,a=void 0===o?"0":o,s=e.inputSize,l=void 0===s?"":s,u=e.inputSizeMessage,d=void 0===u?void 0:u,p=e.inputStorageGroupUUID,f=void 0===p?"":p,v=e.inputStorageGroupUUIDMessage,m=void 0===v?void 0:v,x=e.inputUnit,g=void 0===x?H:x,h=e.max,b=void 0===h?Q:h,y=e.setVirtualDisks,j=e.size,U=void 0===j?Q:j,S=t.stateIds,I=t.inputMaxes,P=t.inputSizeMessages,D=t.inputSizes,O=t.inputStorageGroupUUIDMessages,Z=t.inputStorageGroupUUIDs,w=t.inputUnits,M=t.maxes,C=t.sizes;return S.push(i),I.push(a),P.push(d),D.push(l),O.push(m),Z.push(f),w.push(g),M.push(b),C.push(U),null===y||void 0===y||y.call(null,F({},t)),t}()),Je=Ye[0],Ke=Ye[1],Xe=(0,o.useState)(""),$e=Xe[0],en=Xe[1],nn=(0,o.useState)(),tn=nn[0],rn=nn[1],on=(0,o.useState)(""),an=on[0],sn=on[1],ln=(0,o.useState)()[0],un=(0,o.useState)(""),cn=un[0],dn=un[1],pn=(0,o.useState)(),fn=pn[0],vn=pn[1],mn=(0,o.useState)(null),xn=mn[0],gn=mn[1],hn=(0,o.useState)(),bn=hn[0],yn=hn[1],jn=(0,o.useState)([]),Un=jn[0],Sn=jn[1],In=(0,o.useState)([]),Pn=In[0],Dn=In[1],On=(0,o.useState)([]),Zn=On[0],wn=On[1],Mn=(0,o.useState)(!1),Cn=Mn[0],kn=Mn[1],An=(0,o.useState)(!1),Gn=An[0],Bn=An[1],zn=(0,o.useState)(!1),Tn=zn[0],Fn=zn[1],Nn=(0,o.useState)(0),Ln=Nn[0],En=Nn[1],Rn=(0,o.useMemo)((function(){for(var e=[],n=1;n<=De;n+=1)e.push(n);return e}),[De]),Vn={serverName:{defaults:{onSuccess:function(){je(void 0)},value:ge},isRequired:!0,tests:[{onFailure:function(){je({text:"The server name length must be 1 to 16 characters.",type:"warning"})},test:function(e){var n=e.value.length;return n>=1&&n<=16}},{onFailure:function(){je({text:"The server name is expected to only contain alphanumeric, hyphen, or underscore characters.",type:"warning"})},test:function(e){var n=e.value;return/^[a-zA-Z0-9_-]+$/.test(n)}},{onFailure:function(){je({text:"This server name already exists, please choose another name.",type:"warning"})},test:function(e){var n=e.value;return void 0===z[n]}}]},cpuCores:{defaults:{max:De,min:1,onSuccess:function(){Me(void 0)},value:Se},isRequired:!0,tests:[{onFailure:function(){Me({text:"Non available.",type:"warning"})},test:C.X7},{onFailure:function(e){var n=e.displayMax,t=e.displayMin;Me({text:"The number of CPU cores is expected to be between ".concat(t," and ").concat(n,"."),type:"warning"})},test:C.SQ}]},memory:{defaults:{displayMax:"".concat(Ee," ").concat(_e),displayMin:W,max:Be,min:Y,onSuccess:function(){Ne(void 0)},value:ke},isRequired:!0,tests:[{onFailure:function(){Ne({text:"Non available.",type:"warning"})},test:C.X7},{onFailure:function(e){var n=e.displayMax,t=e.displayMin;Ne({text:"Memory is expected to be between ".concat(t," and ").concat(n,"."),type:"warning"})},test:C.SQ}]},installISO:{defaults:{onSuccess:function(){rn(void 0)},value:$e},isRequired:!0,tests:[{test:C.HJ}]},anvil:{defaults:{onSuccess:function(){vn(void 0)},value:cn},isRequired:!0,tests:[{test:C.HJ}]},optimizeForOS:{defaults:{onSuccess:function(){yn(void 0)},value:null===xn||void 0===xn?void 0:xn.key},isRequired:!0,tests:[{test:C.HJ}]}};Je.inputSizeMessages.forEach((function(e,n){Vn["vd".concat(n,"Size")]={defaults:{displayMax:"".concat(Je.inputMaxes[n]," ").concat(Je.inputUnits[n]),displayMin:q,max:Je.maxes[n],min:J,onSuccess:function(){Je.inputSizeMessages[n]=void 0},value:Je.sizes[n]},isRequired:!0,onFinishBatch:function(){Ke(F({},Je))},tests:[{onFailure:function(){Je.inputSizeMessages[n]={text:"Non available.",type:"warning"}},test:C.X7},{onFailure:function(e){var t=e.displayMax,r=e.displayMin;Je.inputSizeMessages[n]={text:"Virtual disk ".concat(n," size is expected to be between ").concat(r," and ").concat(t,"."),type:"warning"}},test:C.SQ}]},Vn["vd".concat(n,"StorageGroup")]={defaults:{onSuccess:function(){Je.inputStorageGroupUUIDMessages[n]=void 0},value:Je.inputStorageGroupUUIDs[n]},isRequired:!0,onFinishBatch:function(){Ke(F({},Je))},tests:[{test:C.HJ}]}}));var Wn=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.allAnvils,t=void 0===n?y:n,r=e.cpuCores,i=void 0===r?Se:r,o=e.fileUUIDs,a=void 0===o?[$e,an]:o,s=e.includeAnvilUUIDs,l=void 0===s?ne([cn]):s,u=e.includeFileUUIDs,c=e.includeStorageGroupUUIDs,d=e.inputMemoryUnit,p=void 0===d?_e:d,f=e.memory,v=void 0===f?ke:f,m=e.storageGroupUUIDMapToData,g=void 0===m?te:m,h=e.virtualDisks,b=void 0===h?Je:h,j=ee(t,g,i,v,b.sizes,b.inputStorageGroupUUIDs,a,{includeAnvilUUIDs:l,includeFileUUIDs:u,includeStorageGroupUUIDs:c}),U=j.anvilUUIDs,S=j.fileUUIDs,I=j.maxCPUCores,P=j.maxMemory,D=j.maxVirtualDiskSizes,O=j.storageGroupUUIDs;Oe(I),ze(P);var Z=[];b.maxes=D,b.maxes.forEach((function(e,n){(0,x.Bh)(e,{fromUnit:"B",onSuccess:{string:function(e,t){b.inputMaxes[n]=e,Z[n]="".concat(e," ").concat(t)}},toUnit:b.inputUnits[n]})})),Ke(F({},b)),Sn(U),Dn(S),wn(O);var w="";return(0,x.Bh)(P,{fromUnit:"B",onSuccess:{string:function(e,n){Re(e),w="".concat(e," ").concat(n)}},toUnit:p}),{formattedMaxMemory:w,formattedMaxVDSizes:Z,maxCPUCores:I,maxMemory:P,maxVirtualDiskSizes:D}},qn=(0,o.useCallback)(Wn,[]),Qn=function(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];var r=E(n),i=r[0],o=r.slice(1);return C.BD.apply(void 0,[F({tests:Vn},i)].concat(R(o)))},_n=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.cmValue,t=void 0===n?Q:n,r=e.cmUnit,i=void 0===r?_e:r;Ae(t);var o=Wn({inputMemoryUnit:i,memory:t}),a=o.formattedMaxMemory,s=o.maxMemory;Qn({inputs:{memory:{displayMax:a,max:s,value:t}}})},Hn=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.value,t=void 0===n?We:n,r=e.unit,i=void 0===r?_e:r;t!==We&&qe(t),i!==_e&&He(i),(0,x.KY)(t,i,(function(e){return _n({cmValue:e,cmUnit:i})}),(function(){return _n({cmUnit:i})}))},Yn=function(e){en(e),Wn({fileUUIDs:[e,an]})},Jn=function(e){sn(e),Wn({fileUUIDs:[$e,e]})},Kn=function(e){var n=ne([e]);dn(e),Wn({includeAnvilUUIDs:n})};return(0,o.useEffect)((function(){p.Z.get("/anvil",{params:{anvilUUIDs:"all",isForProvisionServer:!0}}).then((function(e){var n=e.data,t=function(e){var n={},t=e.reduce((function(e,t){var i=t.anvilUUID,o=t.anvilName,s=t.anvilTotalMemory,l=t.anvilTotalAllocatedMemory,u=t.anvilTotalAvailableMemory,c=t.hosts,d=t.servers,p=t.storageGroups,f=t.files,v=p.reduce((function(n,t){var a=F({},t,{anvilUUID:i,anvilName:o,storageGroupSize:BigInt(t.storageGroupSize),storageGroupFree:BigInt(t.storageGroupFree),humanizedStorageGroupFree:""});return(0,x.Bh)(t.storageGroupFree,{fromUnit:"B",onSuccess:{string:function(e,n){a.humanizedStorageGroupFree="".concat(e," ").concat(n)}},precision:0,toUnit:"ibyte"}),n.anvilStorageGroupUUIDs.push(t.storageGroupUUID),n.anvilStorageGroups.push(a),e.storageGroups.push(a),e.storageGroupSelectItems.push({displayValue:$({endAdornment:(0,r.jsx)(k.Ac,{inverted:!0,text:"~".concat(a.humanizedStorageGroupFree," free")}),mainLabel:t.storageGroupName,subLabel:o}),value:t.storageGroupUUID}),e.storageGroupUUIDMapToData[t.storageGroupUUID]=a,n}),{anvilStorageGroups:[],anvilStorageGroupUUIDs:[]}),m=v.anvilStorageGroups,g=v.anvilStorageGroupUUIDs,h=[];f.forEach((function(e){var t=e.fileUUID;h.push(t),n[t]=e}));var b=F({},t,{anvilTotalMemory:BigInt(s),anvilTotalAllocatedMemory:BigInt(l),anvilTotalAvailableMemory:BigInt(u),humanizedAnvilTotalAvailableMemory:"",hosts:c.map((function(e){return F({},e,{hostMemory:BigInt(e.hostMemory)})})),servers:d.map((function(n){var t=n.serverMemory,r=n.serverName,i=F({},N(n,["serverMemory","serverName"]),{serverMemory:BigInt(t),serverName:r});return e.serverNameMapToData[r]=i,i})),storageGroupUUIDs:g,storageGroups:m,fileUUIDs:h});return(0,x.Bh)(u,{fromUnit:"B",onSuccess:{string:function(e,n){b.humanizedAnvilTotalAvailableMemory="".concat(e," ").concat(n)}},precision:0,toUnit:"ibyte"}),e.anvils.push(b),e.anvilSelectItems.push({displayValue:$({endAdornment:(0,r.jsxs)(a.Z,{sx:{display:"flex",flexDirection:"column",width:"8rem"},children:[(0,r.jsx)(k.Ac,{inverted:!0,text:"CPU: ".concat(b.anvilTotalCPUCores," cores")}),(0,r.jsx)(k.Ac,{inverted:!0,text:"Memory: ~".concat(b.humanizedAnvilTotalAvailableMemory)})]}),mainLabel:b.anvilName,subLabel:b.anvilDescription}),value:i}),e.anvilUUIDMapToData[i]=b,e}),{anvils:[],anvilSelectItems:[],anvilUUIDMapToData:{},files:[],fileSelectItems:[],fileUUIDMapToData:{},serverNameMapToData:{},storageGroups:[],storageGroupSelectItems:[],storageGroupUUIDMapToData:{}});return Object.values(n).forEach((function(e){t.files.push(e),t.fileSelectItems.push({displayValue:e.fileName,value:e.fileUUID}),t.fileUUIDMapToData[e.fileUUID]=e})),t}(n.anvils),i=t.anvils,o=t.anvilSelectItems,s=t.anvilUUIDMapToData,l=t.fileSelectItems,u=t.fileUUIDMapToData,c=t.serverNameMapToData,d=t.storageGroupSelectItems,p=t.storageGroupUUIDMapToData;j(i),P(s),A(u),T(c),re(p),ae(o),ue(l),me(d);var f={allAnvils:i,storageGroupUUIDMapToData:p};if(1===o.length){var v=o[0].value;dn(v),f.includeAnvilUUIDs=[v]}if(1===l.length){var m=l[0].value;en(m),f.fileUUIDs=[m,""]}if(1===d.length){var g=d[0].value;Ke((function(e){var n=F({},e);return n.inputStorageGroupUUIDs[0]=g,f.virtualDisks=n,n}))}qn(f),pe(Object.entries(n.oses).map((function(e){var n=L(e,2);return{key:n[0],label:n[1]}}))),kn(!0)}))}),[qn]),(0,r.jsxs)(r.Fragment,{children:[(0,r.jsxs)(l.Z,{fullWidth:!0,maxWidth:"sm",open:n,PaperComponent:w.s_,PaperProps:{sx:{overflow:"visible"}},children:[(0,r.jsxs)(w.V9,{children:[(0,r.jsx)(k.z,{text:"Provision a Server"}),(0,r.jsx)(g.Z,{onClick:t,sx:{backgroundColor:d.hM,color:d.lD,"&:hover":{backgroundColor:d.hM}},children:(0,r.jsx)(u.Z,{})})]}),Cn?(0,r.jsxs)(a.Z,{sx:{display:"flex",flexDirection:"column",maxHeight:"50vh",overflowY:"scroll",paddingTop:".6em","& > :not(:first-child)":{marginTop:"1em"}},children:[(0,r.jsx)(a.Z,{sx:{display:"flex",flexDirection:"column"},children:(0,r.jsx)(b.Z,{id:"ps-server-name",label:"Server name",inputProps:{onChange:function(e){var n=e.target.value;he(n),Qn({inputs:{serverName:{value:n}}})},value:ge},inputLabelProps:{isNotifyRequired:0===ge.length},messageBoxProps:ye})}),(0,r.jsx)(f.Z,{id:"ps-cpu-cores",disableClearable:!0,extendRenderInput:function(e){var n=e.inputLabelProps;(void 0===n?{}:n).isNotifyRequired=Se<=0},getOptionLabel:function(e){return String(e)},label:"CPU cores",messageBoxProps:we,noOptionsText:"No available number of cores.",onChange:function(e,n){if(n&&n!==Se){Ie(n);var t=Wn({cpuCores:n}).maxCPUCores;Qn({inputs:{cpuCores:{max:t,value:n}}})}},openOnFocus:!0,options:Rn,renderOption:function(e,n){return(0,o.createElement)("li",F({},e,{key:"ps-cpu-cores-".concat(n),children:n}))},value:Se}),(0,r.jsx)(Z,{id:"ps-memory",label:"Memory",messageBoxProps:Fe,inputWithLabelProps:{inputProps:{endAdornment:X("".concat(Ee," ").concat(_e),{onButtonClick:function(){qe(Ee),_n({cmValue:Be})}}),onChange:function(e){var n=e.target.value;Hn({value:n})},type:"number",value:We},inputLabelProps:{isNotifyRequired:ke===Q}},selectItems:_,selectWithLabelProps:{selectProps:{onChange:function(e){var n=e.target.value;Hn({unit:n})},value:_e}}}),Je.stateIds.map((function(e,n){return function(e,n,t,i,o,s,l,u){var c=function(t){var r=arguments.length>1&&void 0!==arguments[1]?arguments[1]:n;return e[t][r]},d=function(r,i){var o=arguments.length>2&&void 0!==arguments[2]?arguments[2]:n;e[r][o]=i,t(F({},e))},p=function(){var t=arguments.length>0&&void 0!==arguments[0]?arguments[0]:Q;d("sizes",t);var r=s({virtualDisks:e}),i=r.formattedMaxVDSizes,o=r.maxVirtualDiskSizes;u({inputs:B({},"vd".concat(n,"Size"),{displayMax:"".concat(i[n]),max:o[n],value:t})})},f=function(e){var n=e.value,t=void 0===n?c("inputSizes"):n,r=e.unit,i=void 0===r?c("inputUnits"):r;t!==c("inputSizes")&&d("inputSizes",t),i!==c("inputUnits")&&d("inputUnits",i),(0,x.KY)(t,i,(function(e){return p(e)}),(function(){return p()}))},v=function(){var n=arguments.length>0&&void 0!==arguments[0]?arguments[0]:c("inputStorageGroupUUIDs");n!==c("inputStorageGroupUUIDs")&&d("inputStorageGroupUUIDs",n),s({virtualDisks:e})};return(0,r.jsxs)(a.Z,{sx:{display:"flex",flexDirection:"column","& > :not(:first-child)":{marginTop:"1em"}},children:[(0,r.jsx)(a.Z,{sx:{display:"flex",flexDirection:"column"},children:(0,r.jsx)(Z,{id:"ps-virtual-disk-size-".concat(n),label:"Disk size",messageBoxProps:c("inputSizeMessages"),inputWithLabelProps:{inputProps:{endAdornment:X("".concat(c("inputMaxes")," ").concat(c("inputUnits")),{onButtonClick:function(){d("inputSizes",c("inputMaxes")),p(c("maxes"))}}),onChange:function(e){var n=e.target.value;f({value:n})},type:"number",value:c("inputSizes")},inputLabelProps:{isNotifyRequired:c("sizes")===Q}},selectItems:_,selectWithLabelProps:{selectProps:{onChange:function(e){var n=e.target.value;f({unit:n})},value:c("inputUnits")}}})}),(0,r.jsx)(a.Z,{sx:{display:"flex",flexDirection:"column"},children:(0,r.jsx)(S.Z,{id:"ps-storage-group-".concat(n),label:"Storage group",disableItem:function(e){return!(o.includes(e)&&c("sizes")<=l[e].storageGroupFree)},inputLabelProps:{isNotifyRequired:0===c("inputStorageGroupUUIDs").length},messageBoxProps:c("inputStorageGroupUUIDMessages"),selectItems:i,selectProps:{onChange:function(e){var n=e.target.value;v(n)},onClearIndicatorClick:function(){return v("")},renderValue:function(e){var n,t=null!==(n=l[e])&&void 0!==n?n:{},r=t.anvilName,i=void 0===r?"?":r,o=t.storageGroupName,a=void 0===o?"Unknown (".concat(e,")"):o;return"".concat(a," (").concat(i,")")},value:c("inputStorageGroupUUIDs")}})})]},"ps-virtual-disk-".concat(c("stateIds")))}(Je,n,Ke,ve,Zn,Wn,te,Qn)})),(0,r.jsx)(S.Z,{disableItem:function(e){return e===an},hideItem:function(e){return!Pn.includes(e)},id:"ps-install-image",inputLabelProps:{isNotifyRequired:0===$e.length},label:"Install ISO",messageBoxProps:tn,selectItems:le,selectProps:{onChange:function(e){var n=e.target.value;Yn(n)},onClearIndicatorClick:function(){return Yn("")},value:$e}}),(0,r.jsx)(S.Z,{disableItem:function(e){return e===$e},hideItem:function(e){return!Pn.includes(e)},id:"ps-driver-image",label:"Driver ISO",messageBoxProps:ln,selectItems:le,selectProps:{onChange:function(e){var n=e.target.value;Jn(n)},onClearIndicatorClick:function(){return Jn("")},value:an}}),(0,r.jsx)(S.Z,{disableItem:function(e){return!Un.includes(e)},id:"ps-anvil",inputLabelProps:{isNotifyRequired:0===cn.length},label:"Anvil node",messageBoxProps:fn,selectItems:oe,selectProps:{onChange:function(e){var n=e.target.value;Kn(n)},onClearIndicatorClick:function(){return Kn("")},renderValue:function(e){var n,t=(null!==(n=I[e])&&void 0!==n?n:{}).anvilName;return void 0===t?"Unknown ".concat(e):t},value:cn}}),(0,r.jsx)(f.Z,{id:"ps-optimize-for-os",extendRenderInput:function(e){var n=e.inputLabelProps;(void 0===n?{}:n).isNotifyRequired=null===xn},isOptionEqualToValue:function(e,n){return e.key===n.key},label:"Optimize for OS",messageBoxProps:bn,noOptionsText:"No matching OS",onChange:function(e,n){gn(n)},openOnFocus:!0,options:de,renderOption:function(e,n){return(0,o.createElement)("li",F({},e,{key:"ps-optimize-for-os-".concat(n.key),children:[n.label," (",n.key,")"]}))},value:xn})]}):(0,r.jsx)(M.Z,{}),(0,r.jsxs)(a.Z,{sx:{display:"flex",flexDirection:"column",marginTop:"1em","& > :not(:first-child)":{marginTop:"1em"}},children:[Ln>0&&(0,r.jsx)(h.Z,{isAllowClose:!0,text:"Provision server job registered. You can provision another server, or exit; it won't affect the registered job."}),Tn?(0,r.jsx)(M.Z,{mt:0}):(0,r.jsx)(a.Z,{sx:{display:"flex",flexDirection:"row",justifyContent:"flex-end",width:"100%"},children:(0,r.jsx)(m.Z,{disabled:!Qn({isIgnoreOnCallbacks:!0}),onClick:function(){Bn(!0)},sx:K,children:"Provision"})})]})]}),Gn&&(0,r.jsx)(v.Z,{actionProceedText:"Provision",content:function(){var e=10;return(0,r.jsxs)(s.ZP,{container:!0,columns:e,direction:"column",children:[(0,r.jsx)(s.ZP,{item:!0,xs:e,children:(0,r.jsxs)(k.Ac,{children:["Server ",(0,r.jsx)(k.Q0,{text:ge})," will be created on anvil node"," ",(0,r.jsx)(k.Q0,{text:I[cn].anvilName})," ","with the following properties:"]})}),(0,r.jsxs)(s.ZP,{container:!0,direction:"row",item:!0,xs:e,children:[(0,r.jsx)(s.ZP,{item:!0,xs:2,children:(0,r.jsx)(k.Ac,{text:"CPU"})}),(0,r.jsx)(s.ZP,{item:!0,xs:5,children:(0,r.jsxs)(k.Ac,{children:[(0,r.jsx)(k.Q0,{edge:"start",children:Se})," ","core(s)"]})}),(0,r.jsx)(s.ZP,{item:!0,xs:3,children:(0,r.jsxs)(k.Ac,{children:[(0,r.jsx)(k.Q0,{edge:"start",children:De})," ","core(s) available"]})})]}),(0,r.jsxs)(s.ZP,{container:!0,direction:"row",item:!0,xs:e,children:[(0,r.jsx)(s.ZP,{item:!0,xs:2,children:(0,r.jsx)(k.Ac,{text:"Memory"})}),(0,r.jsx)(s.ZP,{item:!0,xs:5,children:(0,r.jsx)(k.Ac,{children:(0,r.jsxs)(k.Q0,{edge:"start",children:[We," ",_e]})})}),(0,r.jsx)(s.ZP,{item:!0,xs:3,children:(0,r.jsxs)(k.Ac,{children:[(0,r.jsxs)(k.Q0,{edge:"start",children:[Ee," ",_e]})," ","available"]})})]}),Je.stateIds.map((function(n,t){var i=Je.inputMaxes[t],o=Je.inputSizes[t],a=Je.inputUnits[t],l=te[Je.inputStorageGroupUUIDs[t]].storageGroupName;return(0,r.jsxs)(s.ZP,{container:!0,direction:"row",item:!0,xs:e,children:[(0,r.jsx)(s.ZP,{item:!0,xs:2,children:(0,r.jsxs)(k.Ac,{children:["Disk ",(0,r.jsx)(k.Q0,{text:t})]})}),(0,r.jsx)(s.ZP,{item:!0,xs:5,children:(0,r.jsxs)(k.Ac,{children:[(0,r.jsxs)(k.Q0,{edge:"start",children:[o," ",a]})," ","on ",(0,r.jsx)(k.Q0,{children:l})]})}),(0,r.jsx)(s.ZP,{item:!0,xs:3,children:(0,r.jsxs)(k.Ac,{children:[(0,r.jsxs)(k.Q0,{edge:"start",children:[i," ",a]})," ","available"]})})]},"ps-virtual-disk-".concat(n,"-summary"))})),(0,r.jsxs)(s.ZP,{container:!0,direction:"row",item:!0,xs:e,children:[(0,r.jsx)(s.ZP,{item:!0,xs:2,children:(0,r.jsx)(k.Ac,{text:"Install ISO"})}),(0,r.jsx)(s.ZP,{item:!0,xs:8,children:(0,r.jsx)(k.Ac,{children:(0,r.jsx)(k.Q0,{edge:"start",children:O[$e].fileName})})})]}),(0,r.jsxs)(s.ZP,{container:!0,direction:"row",item:!0,xs:e,children:[(0,r.jsx)(s.ZP,{item:!0,xs:2,children:(0,r.jsx)(k.Ac,{text:"Driver ISO"})}),(0,r.jsx)(s.ZP,{item:!0,xs:8,children:(0,r.jsx)(k.Ac,{children:O[an]?(0,r.jsx)(k.Q0,{edge:"start",children:O[an].fileName}):"none"})})]}),(0,r.jsxs)(s.ZP,{container:!0,direction:"row",item:!0,xs:e,children:[(0,r.jsx)(s.ZP,{item:!0,xs:2,children:(0,r.jsx)(k.Ac,{text:"Optimize for OS"})}),(0,r.jsx)(s.ZP,{item:!0,xs:8,children:(0,r.jsx)(k.Ac,{children:(0,r.jsx)(k.Q0,{edge:"start",children:"".concat(null===xn||void 0===xn?void 0:xn.label)})})})]})]})}(),dialogProps:{open:Gn},onCancelAppend:function(){Bn(!1)},onProceedAppend:function(){var e={serverName:ge,cpuCores:Se,memory:ke.toString(),virtualDisks:Je.stateIds.map((function(e,n){return{storageSize:Je.sizes[n].toString(),storageGroupUUID:Je.inputStorageGroupUUIDs[n]}})),installISOFileUUID:$e,driverISOFileUUID:an,anvilUUID:cn,optimizeForOS:null===xn||void 0===xn?void 0:xn.key};Fn(!0),p.Z.post("/server",e).then((function(){Fn(!1),En(Ln+1)})),Bn(!1)},proceedButtonProps:{sx:K},titleText:"Provision ".concat(ge,"?")})]})}},2519:function(e,n,t){t.d(n,{Z:function(){return O}});var r=t(5893),i=t(5603),o=t(8128),a=t(3640),s=t(7294),l=t(1363),u=t(4427),c=t(9),d=t(192),p=t(5537),f=t(9558),v=t(6239),m=t(7021),x=t(1057),g=t(4799),h=t(3213),b=t(7169);function y(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function j(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){y(e,n,t[n])}))}return e}function U(e,n){if(null==e)return{};var t,r,i=function(e,n){if(null==e)return{};var t,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(i[t]=e[t]);return i}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(i[t]=e[t])}return i}var S=function(e){var n=e.onClearIndicatorClick,t=U(e,["onClearIndicatorClick"]),o=t.sx,a=t.value,l=U(t,["sx","value"]),u=(0,s.useMemo)((function(){var e;return j((y(e={},"& .".concat(i.Z.icon),{color:b.s7}),y(e,"& .".concat(f.Z.root),{marginRight:".8em"}),y(e,"& .".concat(v.Z.root),{color:b.s7,visibility:"hidden"}),y(e,"&:hover .".concat(f.Z.root," .").concat(v.Z.root,",\n      &.").concat(m.Z.focused," .").concat(f.Z.root," .").concat(v.Z.root),{visibility:"visible"}),e),o)}),[o]),c=(0,s.useMemo)((function(){return String(a).length>0&&n&&(0,r.jsx)(x.Z,{position:"end",children:(0,r.jsx)(g.Z,{onClick:n,children:(0,r.jsx)(p.Z,{fontSize:"small"})})})}),[n,a]);return(0,r.jsx)(h.Z,j({endAdornment:c,value:a},l,{sx:u}))};function I(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function P(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){I(e,n,t[n])}))}return e}function D(e,n){if(null==e)return{};var t,r,i=function(e,n){if(null==e)return{};var t,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(i[t]=e[t]);return i}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(i[t]=e[t])}return i}var O=function(e){var n=e.id,t=e.label,p=e.selectItems,f=e.checkItem,v=e.disableItem,m=e.formControlProps,x=e.hideItem,g=e.inputLabelProps,h=void 0===g?{}:g,b=e.isReadOnly,y=void 0!==b&&b,j=e.messageBoxProps,U=void 0===j?{}:j,O=e.name,Z=e.onBlur,w=e.onChange,M=e.onFocus,C=e.required,k=e.selectProps,A=void 0===k?{}:k,G=A.multiple,B=A.sx,z=e.value,T=e.isCheckableItems,F=void 0===T?G:T,N=D(e.selectProps,["multiple","sx"]),L=(0,s.useMemo)((function(){return y?P(I({},"& .".concat(i.Z.icon),{visibility:"hidden"}),B):B}),[y,B]),E=(0,s.useCallback)((function(e){return F&&(0,r.jsx)(o.Z,{checked:null===f||void 0===f?void 0:f.call(null,e)})}),[f,F]),R=(0,s.useCallback)((function(e,t){return(0,r.jsxs)(u.Z,{disabled:null===v||void 0===v?void 0:v.call(null,e),sx:{display:(null===x||void 0===x?void 0:x.call(null,e))?"none":void 0},value:e,children:[E(e),t]},"".concat(n,"-").concat(e))}),[E,v,x,n]),V=(0,s.useMemo)((function(){return"".concat(n,"-select-element")}),[n]),W=(0,s.useMemo)((function(){return(0,r.jsx)(c.Z,{id:n,label:t})}),[n,t]),q=(0,s.useMemo)((function(){return t&&(0,r.jsx)(d.Z,P({htmlFor:V,isNotifyRequired:C},h,{children:t}))}),[h,C,t,V]),Q=(0,s.useMemo)((function(){return p.map((function(e){var n="string"===typeof e?{value:e}:e,t=n.value,r=n.displayValue;return R(t,void 0===r?t:r)}))}),[R,p]);return(0,r.jsxs)(a.Z,P({fullWidth:!0},m,{children:[q,(0,r.jsx)(S,P({id:V,input:W,multiple:G,name:O,onBlur:Z,onChange:w,onFocus:M,readOnly:y,value:z},N,{sx:L,children:Q})),(0,r.jsx)(l.Z,P({},U))]}))}},5737:function(e,n,t){t.d(n,{Bh:function(){return i},KY:function(){return o},MU:function(){return a}});var r=t(4490),i=function(e){var n=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{},t=n.fromUnit,i=n.onFailure,o=n.onSuccess,a=n.precision,s=n.toUnit,l=(0,r.gO)(e,{fromUnit:t,precision:a,toUnit:s});if(l){var u=l.value,c=l.unit;try{var d,p,f;null===o||void 0===o||null===(d=o.bigint)||void 0===d||d.call(null,BigInt(u),c),null===o||void 0===o||null===(p=o.number)||void 0===p||p.call(null,parseFloat(u),c),null===o||void 0===o||null===(f=o.string)||void 0===f||f.call(null,u,c)}catch(v){null===i||void 0===i||i.call(null,v,u,c)}}else null===i||void 0===i||i.call(null)},o=function(e,n,t,r){i(e,{fromUnit:n,onFailure:r,onSuccess:{bigint:t},precision:0,toUnit:"B"})},a=function(e){return(0,r._d)(e,{toUnit:"ibyte"})}}}]);