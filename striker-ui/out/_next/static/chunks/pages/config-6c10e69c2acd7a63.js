(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[490],{2026:function(e,t,n){"use strict";var r=n(7892),o=n(5893);t.Z=(0,r.Z)((0,o.jsx)("path",{d:"M9 16.17 4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"}),"Check")},2852:function(e,t,n){"use strict";var r=n(3366),o=n(7462),i=n(7294),c=n(6010),l=n(7192),a=n(1796),s=n(8216),u=n(1964),d=n(3616),f=n(1496),h=n(9632),p=n(5893);const m=["className","color","edge","size","sx"],b=(0,f.ZP)("span",{name:"MuiSwitch",slot:"Root",overridesResolver:(e,t)=>{const{ownerState:n}=e;return[t.root,n.edge&&t[`edge${(0,s.Z)(n.edge)}`],t[`size${(0,s.Z)(n.size)}`]]}})((({ownerState:e})=>(0,o.Z)({display:"inline-flex",width:58,height:38,overflow:"hidden",padding:12,boxSizing:"border-box",position:"relative",flexShrink:0,zIndex:0,verticalAlign:"middle","@media print":{colorAdjust:"exact"}},"start"===e.edge&&{marginLeft:-8},"end"===e.edge&&{marginRight:-8},"small"===e.size&&{width:40,height:24,padding:7,[`& .${h.Z.thumb}`]:{width:16,height:16},[`& .${h.Z.switchBase}`]:{padding:4,[`&.${h.Z.checked}`]:{transform:"translateX(16px)"}}}))),y=(0,f.ZP)(u.Z,{name:"MuiSwitch",slot:"SwitchBase",overridesResolver:(e,t)=>{const{ownerState:n}=e;return[t.switchBase,{[`& .${h.Z.input}`]:t.input},"default"!==n.color&&t[`color${(0,s.Z)(n.color)}`]]}})((({theme:e})=>({position:"absolute",top:0,left:0,zIndex:1,color:"light"===e.palette.mode?e.palette.common.white:e.palette.grey[300],transition:e.transitions.create(["left","transform"],{duration:e.transitions.duration.shortest}),[`&.${h.Z.checked}`]:{transform:"translateX(20px)"},[`&.${h.Z.disabled}`]:{color:"light"===e.palette.mode?e.palette.grey[100]:e.palette.grey[600]},[`&.${h.Z.checked} + .${h.Z.track}`]:{opacity:.5},[`&.${h.Z.disabled} + .${h.Z.track}`]:{opacity:"light"===e.palette.mode?.12:.2},[`& .${h.Z.input}`]:{left:"-100%",width:"300%"}})),(({theme:e,ownerState:t})=>(0,o.Z)({"&:hover":{backgroundColor:(0,a.Fq)(e.palette.action.active,e.palette.action.hoverOpacity),"@media (hover: none)":{backgroundColor:"transparent"}}},"default"!==t.color&&{[`&.${h.Z.checked}`]:{color:e.palette[t.color].main,"&:hover":{backgroundColor:(0,a.Fq)(e.palette[t.color].main,e.palette.action.hoverOpacity),"@media (hover: none)":{backgroundColor:"transparent"}},[`&.${h.Z.disabled}`]:{color:"light"===e.palette.mode?(0,a.$n)(e.palette[t.color].main,.62):(0,a._j)(e.palette[t.color].main,.55)}},[`&.${h.Z.checked} + .${h.Z.track}`]:{backgroundColor:e.palette[t.color].main}}))),g=(0,f.ZP)("span",{name:"MuiSwitch",slot:"Track",overridesResolver:(e,t)=>t.track})((({theme:e})=>({height:"100%",width:"100%",borderRadius:7,zIndex:-1,transition:e.transitions.create(["opacity","background-color"],{duration:e.transitions.duration.shortest}),backgroundColor:"light"===e.palette.mode?e.palette.common.black:e.palette.common.white,opacity:"light"===e.palette.mode?.38:.3}))),v=(0,f.ZP)("span",{name:"MuiSwitch",slot:"Thumb",overridesResolver:(e,t)=>t.thumb})((({theme:e})=>({boxShadow:e.shadows[1],backgroundColor:"currentColor",width:20,height:20,borderRadius:"50%"}))),x=i.forwardRef((function(e,t){const n=(0,d.Z)({props:e,name:"MuiSwitch"}),{className:i,color:a="primary",edge:u=!1,size:f="medium",sx:x}=n,j=(0,r.Z)(n,m),w=(0,o.Z)({},n,{color:a,edge:u,size:f}),Z=(e=>{const{classes:t,edge:n,size:r,color:i,checked:c,disabled:a}=e,u={root:["root",n&&`edge${(0,s.Z)(n)}`,`size${(0,s.Z)(r)}`],switchBase:["switchBase",`color${(0,s.Z)(i)}`,c&&"checked",a&&"disabled"],thumb:["thumb"],track:["track"],input:["input"]},d=(0,l.Z)(u,h.H,t);return(0,o.Z)({},t,d)})(w),P=(0,p.jsx)(v,{className:Z.thumb,ownerState:w});return(0,p.jsxs)(b,{className:(0,c.Z)(Z.root,i),sx:x,ownerState:w,children:[(0,p.jsx)(y,(0,o.Z)({type:"checkbox",icon:P,checkedIcon:P,ref:t,ownerState:w},j,{classes:(0,o.Z)({},Z,{root:Z.switchBase})})),(0,p.jsx)(g,{className:Z.track,ownerState:w})]})}));t.Z=x},329:function(e,t,n){(window.__NEXT_P=window.__NEXT_P||[]).push(["/config",function(){return n(528)}])},528:function(e,t,n){"use strict";n.r(t),n.d(t,{default:function(){return Ge}});var r=n(5893),o=n(7357),i=n(6886),c=n(7294),l=n(2029),a=n(157),s=n(5716),u=n(1905),d={bcn:"Back-Channel Network",ifn:"Internet-Facing Network"},f=n(4188),h=n(4390);function p(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function m(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],c=!0,l=!1;try{for(n=n.call(e);!(c=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);c=!0);}catch(a){l=!0,o=a}finally{try{c||null==n.return||n.return()}finally{if(l)throw o}}return i}}(e,t)||function(e,t){if(!e)return;if("string"===typeof e)return p(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return p(e,t)}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var b=function(e,t){return Object.entries(e).reduce((function(e,n){var r=m(n,2),o=r[0],i=r[1];return e[o]=function(e){var n;null===(n=t.current.setMessage)||void 0===n||n.call(null,i,e)},e}),{})},y=n(6777),g=function(e){var t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:"parseInt";return"number"===typeof e?e:Number[t](String(e))};function v(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function x(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function j(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){x(e,t,n[t])}))}return e}function w(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}function Z(e){return function(e){if(Array.isArray(e))return v(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||function(e,t){if(!e)return;if("string"===typeof e)return v(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return v(e,t)}(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var P=function(e,t){var n=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},o=arguments.length>3?arguments[3]:void 0,i=arguments.length>4?arguments[4]:void 0,c=arguments.length>5?arguments[5]:void 0,l=n.onFinishBatch,a=w(n,["onFinishBatch"]),s=[];return o?s.push({onFailure:function(){for(var t=arguments.length,n=new Array(t),i=0;i<t;i++)n[i]=arguments[i];o.apply(void 0,[(0,r.jsxs)(r.Fragment,{children:[e," must be a valid integer."]})].concat(Z(n)))},test:function(e){var t=e.value;return Number.isSafeInteger(g(t))}}):i&&s.push({onFailure:function(){for(var t=arguments.length,n=new Array(t),o=0;o<t;o++)n[o]=arguments[o];i.apply(void 0,[(0,r.jsxs)(r.Fragment,{children:[e," must be a valid floating-point number."]})].concat(Z(n)))},test:function(e){var t=e.value;return Number.isFinite(g(t,"parseFloat"))}}),c&&s.push({onFailure:function(){for(var t=arguments.length,n=new Array(t),o=0;o<t;o++)n[o]=arguments[o];var i=n[0],l=i.displayMax,a=i.displayMin;c.apply(void 0,[(0,r.jsxs)(r.Fragment,{children:[e," is expected to be between ",a," and ",l,"."]})].concat(Z(n)))},test:y.Z}),{defaults:j({},a,{onSuccess:t}),onFinishBatch:l,tests:s}},O=n(480),S=n(2349),k=n(2416);function A(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function I(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){A(e,t,n[t])}))}return e}var C=function(e){var t=e.checkboxProps,n=e.checked,o=e.formControlLabelProps,i=e.label,l=e.onChange,a=(0,c.useMemo)((function(){return"string"===typeof i?(0,r.jsx)(k.Ac,{children:i}):i}),[i]);return(0,r.jsx)(O.Z,I({},o,{control:(0,r.jsx)(S.Z,I({},t,{checked:n,onChange:l})),label:a}))},T=n(4690),E=n(7504),M=n(1770),F=n(9434),R=n(7869),$=n(6284),N=n(9914),U=n(3144),D=n(2749);function B(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function _(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function z(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}function L(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],c=!0,l=!1;try{for(n=n.call(e);!(c=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);c=!0);}catch(a){l=!0,o=a}finally{try{c||null==n.return||n.return()}finally{if(l)throw o}}return i}}(e,t)||function(e,t){if(!e)return;if("string"===typeof e)return B(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return B(e,t)}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function H(e){var t=function(e,t){if("object"!==G(e)||null===e)return e;var n=e[Symbol.toPrimitive];if(void 0!==n){var r=n.call(e,t||"default");if("object"!==G(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===t?String:Number)(e)}(e,"string");return"symbol"===G(t)?t:String(t)}var G=function(e){return e&&"undefined"!==typeof Symbol&&e.constructor===Symbol?"symbol":typeof e};var W={dbPort:"dbPort",ipAddress:"ipAddress",password:"password",sshPort:"sshPort",user:"user"},V="DB port",q="IP address",K="Password",X="Ping",Y="SSH port",J="User",Q=(0,c.forwardRef)((function(e,t){var n=e.formGridColumns,o=void 0===n?2:n,i=(0,U.Z)().protect,l=(0,c.useRef)({}),s=(0,c.useRef)({}),u=(0,c.useRef)({}),d=(0,c.useRef)({}),p=(0,c.useRef)({}),m=(0,c.useRef)({}),y=(0,c.useState)({}),g=y[0],v=y[1],x=(0,c.useState)(!1),j=x[0],w=x[1],Z=L((0,D.Z)(!1,i),2),O=Z[0],S=Z[1],A=(0,c.useCallback)((function(e,t){return function(n){n[e];return function(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){_(e,t,n[t])}))}return e}({},z(n,[e].map(H)),_({},e,t))}}),[]),I=(0,c.useCallback)((function(e){return function(t){var n=t.isRequired;v(A(e,!n))}}),[A]),B=(0,c.useCallback)((function(e){return function(t){v(A(e,t))}}),[A]),G=(0,c.useCallback)((function(e){var t;null===(t=m.current.setMessage)||void 0===t||t.call(null,"api",e)}),[]),Q=(0,c.useMemo)((function(){return Object.values(g).some((function(e){return!e}))}),[g]),ee=(0,c.useMemo)((function(){return b(W,m)}),[]);return(0,r.jsx)(a.Z,{actionProceedText:"Add",content:(0,r.jsx)(E.Z,{columns:{xs:1,sm:o},layout:{"add-peer-user-and-ip-address":{children:(0,r.jsxs)(T.Z,{row:!0,spacing:".3em",children:[(0,r.jsx)(F.Z,{input:(0,r.jsx)($.Z,{formControlProps:{sx:{minWidth:"4.6em",width:"25%"}},id:"add-peer-user-input",inputProps:{placeholder:"admin"},label:J}),inputTestBatch:(0,N.Gn)(J,(function(){ee.user()}),{onFinishBatch:B(W.user)},(function(e){ee.user({children:e})})),onFirstRender:I(W.user),ref:p}),(0,r.jsx)(k.Ac,{children:"@"}),(0,r.jsx)(F.Z,{input:(0,r.jsx)($.Z,{id:"add-peer-ip-address-input",label:q}),inputTestBatch:(0,N._)(q,(function(){ee.ipAddress()}),{onFinishBatch:B(W.ipAddress)},(function(e){ee.ipAddress({children:e})})),onFirstRender:I(W.ipAddress),ref:s,required:!0})]})},"add-peer-password":{children:(0,r.jsx)(F.Z,{input:(0,r.jsx)($.Z,{fillRow:!0,id:"add-peer-password-input",label:K,type:f.Z.password}),inputTestBatch:(0,N.Gn)(K,(function(){ee.password()}),{onFinishBatch:B(W.password)},(function(e){ee.password({children:e})})),onFirstRender:I(W.password),ref:u,required:!0})},"add-peer-db-and-ssh-port":{children:(0,r.jsxs)(T.Z,{row:!0,children:[(0,r.jsx)(F.Z,{input:(0,r.jsx)($.Z,{id:"add-peer-db-port-input",inputProps:{placeholder:"5432"},label:V}),inputTestBatch:P(V,(function(){ee.dbPort()}),{onFinishBatch:B(W.dbPort)},(function(e){ee.dbPort({children:e})})),onFirstRender:I(W.dbPort),ref:l}),(0,r.jsx)(F.Z,{input:(0,r.jsx)($.Z,{id:"add-peer-ssh-port-input",inputProps:{placeholder:"22"},label:Y}),inputTestBatch:P(Y,(function(){ee.sshPort()}),{onFinishBatch:B(W.sshPort)},(function(e){ee.sshPort({children:e})})),onFirstRender:I(W.sshPort),ref:d})]})},"add-peer-is-ping":{children:(0,r.jsx)(C,{checked:j,label:X,onChange:function(e,t){w(t)}}),sx:{display:"flex"}},"add-peer-message-group":{children:(0,r.jsx)(R.Z,{count:1,defaultMessageType:"warning",ref:m}),sm:o}},spacing:"1em"}),dialogProps:{PaperProps:{sx:{minWidth:"16em"}}},loadingAction:O,onActionAppend:function(){G()},onProceedAppend:function(){var e,t,n,r,o;S(!0),h.Z.post("/host/connection",{ipAddress:null===(e=s.current.getValue)||void 0===e?void 0:e.call(null),isPing:j,password:null===(t=u.current.getValue)||void 0===t?void 0:t.call(null),port:null===(n=l.current.getValue)||void 0===n?void 0:n.call(null),sshPort:null===(r=d.current.getValue)||void 0===r?void 0:r.call(null),user:null===(o=p.current.getValue)||void 0===o?void 0:o.call(null)}).then((function(){G({children:"Successfully initiated the peer addition. You can continue to edit the field(s) to add another peer.",type:"info"})})).catch((function(e){var t=(0,M.Z)(e);t.children="Failed to add the given peer. ".concat(t.children),G(t)})).finally((function(){S(!1)}))},proceedButtonProps:{disabled:Q},ref:t,titleText:"Add a peer"})}));Q.displayName="AddPeerDialog";var ee=Q,te=n(6125),ne=n(8187),re=n(3679),oe=n(5537),ie=n(2026),ce=n(7169),le={small:k.KI,medium:k.Ac},ae={size:"small",stateMap:new Map([[!1,(0,r.jsx)(oe.Z,{sx:{color:ce.Wd}},"state-false")],[!0,(0,r.jsx)(ie.Z,{sx:{color:ce.Ej}},"state-true")]])},se=function(e){var t=e.label,n=e.size,o=void 0===n?ae.size:n,i=e.state,l=e.stateMap,a=(void 0===l?ae.stateMap:l).get(i);return(0,r.jsxs)(T.Z,{row:!0,spacing:".3em",children:[a&&(0,c.cloneElement)(a,{fontSize:o}),(0,c.createElement)(le[o],{},t)]})};se.defaultProps=ae;var ue=se;function de(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function fe(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function he(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){fe(e,t,n[t])}))}return e}function pe(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],c=!0,l=!1;try{for(n=n.call(e);!(c=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);c=!0);}catch(a){l=!0,o=a}finally{try{c||null==n.return||n.return()}finally{if(l)throw o}}return i}}(e,t)||function(e,t){if(!e)return;if("string"===typeof e)return de(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return de(e,t)}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var me=function(e){var t=e.refreshInterval,n=void 0===t?6e4:t,o=(0,U.Z)().protect,s=(0,c.useRef)({}),f=(0,c.useRef)({}),p=pe((0,D.Z)(void 0,o),2),m=p[0],b=p[1],y=(0,c.useState)({actionProceedText:"",content:"",titleText:""}),g=y[0],v=y[1],x=pe((0,D.Z)({},o),2),j=x[0],w=x[1],Z=(0,c.useState)(!1),P=Z[0],O=Z[1],S=pe((0,D.Z)({},o),2),A=S[0],I=S[1],C=(0,c.useMemo)((function(){return m&&(0,r.jsx)(i.ZP,{item:!0,sm:2,xs:1,children:(0,r.jsx)(ne.Z,he({},m))})}),[m]),E=(0,u.Z)("".concat(l.Z,"/host/connection"),{refreshInterval:n,onError:function(e){b({children:"Failed to get connection data. Error: ".concat(e),type:"error"})},onSuccess:function(e){var t=e.local,n=t.inbound,r=n.ipAddress,o=n.port,i=n.user,c=t.peer;w((function(e){return Object.entries(r).reduce((function(t,n){var r=pe(n,2),c=r[0],l=r[1],a=l.networkLinkNumber,s=l.networkNumber,u=l.networkType;return t[c]=he({},e[c],{dbPort:o,dbUser:i,ipAddress:c,networkLinkNumber:a,networkNumber:s,networkType:u}),t}),{})})),I((function(e){return Object.entries(c).reduce((function(t,n){var r=pe(n,2),o=r[0],i=r[1],c=i.hostUUID,l=i.isPing,a=i.port,s=i.user,u="".concat(s,"@").concat(o,":").concat(a);return t[u]=he({},e[u],{dbPort:a,dbUser:s,hostUUID:c,ipAddress:o,isPingTest:l}),t}),{})}))}}).isLoading;return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(re.TZ,{header:(0,r.jsx)(k.Ac,{children:"Configure striker peers"}),loading:E,children:(0,r.jsxs)(i.ZP,{columns:{xs:1,sm:2},container:!0,spacing:"1em",children:[(0,r.jsx)(i.ZP,{item:!0,xs:1,children:(0,r.jsx)(te.Z,{header:"Inbound connections",listEmpty:(0,r.jsx)(k.Ac,{align:"center",children:"No inbound connections found."}),listItemKeyPrefix:"config-peers-inbound-connection",listItems:j,renderListItem:function(e,t){var n=t.dbPort,o=t.dbUser,i=t.networkNumber,c=t.networkType;return(0,r.jsxs)(T.Z,{spacing:0,sx:{width:"100%"},children:[(0,r.jsx)(k.$_,{children:"".concat(o,"@").concat(e,":").concat(n)}),(0,r.jsx)(k.KI,{children:"".concat(d[c]," ").concat(i)})]})}})}),(0,r.jsx)(i.ZP,{item:!0,xs:1,children:(0,r.jsx)(te.Z,{header:"Peer connections",allowEdit:!0,edit:P,listEmpty:(0,r.jsx)(k.Ac,{align:"center",children:"No peer connections found."}),listItemKeyPrefix:"config-peers-peer-connection",listItems:A,onAdd:function(){var e;null===(e=s.current.setOpen)||void 0===e||e.call(null,!0)},onDelete:function(){var e,t=Object.entries(A).reduce((function(e,t){var n=pe(t,2)[1],r=n.hostUUID;return n.isChecked&&e.local.push(r),e}),{local:[]}),n=t.local.length;n>0&&(v({actionProceedText:"Delete",content:"The peer relationship between this striker and the selected ".concat(n," host(s) will terminate. The removed peer(s) can be re-added later."),onProceedAppend:function(){h.Z.delete("/host/connection",{data:t}).catch((function(e){var t=(0,M.Z)(e);t.children="Failed to delete peer connection(s). ".concat(t.children),b(t)}))},proceedColour:"red",titleText:"Delete ".concat(n," peer(s) from this striker?")}),null===(e=f.current.setOpen)||void 0===e||e.call(null,!0))},onEdit:function(){O((function(e){return!e}))},onItemCheckboxChange:function(e,t,n){A[e].isChecked=n,I((function(e){return he({},e)}))},renderListItem:function(e,t){var n=t.isPingTest,o=void 0!==n&&n;return(0,r.jsx)(T.Z,{row:!0,spacing:0,children:(0,r.jsxs)(T.Z,{spacing:0,children:[(0,r.jsx)(k.$_,{children:e}),(0,r.jsx)(ue,{label:"Ping",state:o})]})})}})}),C]})}),(0,r.jsx)(ee,{ref:s}),(0,r.jsx)(a.Z,he({closeOnProceed:!0},g,{ref:f}))]})},be=n(582),ye=n(5741);function ge(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function ve(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function xe(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){ve(e,t,n[t])}))}return e}function je(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],c=!0,l=!1;try{for(n=n.call(e);!(c=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);c=!0);}catch(a){l=!0,o=a}finally{try{c||null==n.return||n.return()}finally{if(l)throw o}}return i}}(e,t)||function(e,t){if(!e)return;if("string"===typeof e)return ge(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return ge(e,t)}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var we=function(e){var t=e.mitmExternalHref,n=void 0===t?"https://en.wikipedia.org/wiki/Man-in-the-middle_attack":t,o=e.refreshInterval,i=void 0===o?6e4:o,s=(0,U.Z)().protect,d=(0,c.useRef)({}),f=(0,c.useRef)({}),p=je((0,D.Z)(void 0,s),2),m=p[0],b=p[1],y=je((0,D.Z)({},s),2),g=y[0],v=y[1],x=je((0,D.Z)({actionProceedText:"",content:"",titleText:""},s),2),j=x[0],w=x[1],Z=(0,c.useMemo)((function(){return m&&(0,r.jsx)(ne.Z,xe({},m))}),[m]),P=(0,c.useMemo)((function(){return Object.keys(g).length>1}),[g]),O=(0,u.Z)("".concat(l.Z,"/ssh-key/conflict"),{onError:function(e){b({children:"Failed to fetch SSH key conflicts. Error: ".concat(e),type:"error"})},onSuccess:function(e){v((function(t){return Object.values(e).reduce((function(e,n){return Object.values(n).forEach((function(n){var r=n.hostName,o=n.hostUUID,i=n.ipAddress,c=n.stateUUID;e[c]=xe({},t[c],{hostName:r,hostUUID:o,ipAddress:i})})),e}),{})}))},refreshInterval:i}).isLoading;return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsxs)(re.TZ,{header:(0,r.jsx)(k.Ac,{children:"Manage changed SSH keys"}),loading:O,children:[(0,r.jsxs)(T.Z,{spacing:".2em",children:[(0,r.jsx)(k.Ac,{children:"The identity of the following targets have unexpectedly changed."}),(0,r.jsxs)(ne.Z,{type:"warning",isAllowClose:!0,children:["If you haven't rebuilt the listed targets, then you could be experiencing a"," ",(0,r.jsx)(ye.Z,{href:n,sx:{display:"inline-flex"},target:"_blank",children:'"Man In The Middle"'})," ","attack. Please verify the targets have changed for a known reason before proceeding to remove the broken keys."]}),(0,r.jsx)(te.Z,{header:(0,r.jsxs)(T.Z,{row:!0,spacing:".3em",sx:{width:"100%","& > :not(:last-child)":{display:{xs:"none",sm:"flex"}},"& > :last-child":{display:{xs:"initial",sm:"none"},marginLeft:0}},children:[(0,r.jsxs)(T.Z,{row:!0,spacing:".3em",sx:{flexBasis:"calc(50% + 1em)"},children:[(0,r.jsx)(k.Ac,{children:"Host name"}),(0,r.jsx)(be.Z,{sx:{flexGrow:1}})]}),(0,r.jsxs)(T.Z,{row:!0,spacing:".3em",sx:{flexGrow:1},children:[(0,r.jsx)(k.Ac,{children:"IP address"}),(0,r.jsx)(be.Z,{sx:{flexGrow:1}})]}),(0,r.jsx)(be.Z,{sx:{flexGrow:1}})]}),allowCheckAll:P,allowCheckItem:!0,allowDelete:!0,allowEdit:!1,edit:!0,listEmpty:(0,r.jsx)(k.Ac,{align:"center",children:"No conflicting keys found."}),listItems:g,onAllCheckboxChange:function(e,t){Object.keys(g).forEach((function(e){g[e].isChecked=t})),v((function(e){return xe({},e)}))},onDelete:function(){var e,t=0,n=Object.entries(g).reduce((function(e,n){var r=je(n,2),o=r[0],i=r[1],c=i.hostUUID;return i.isChecked&&(e[c]||(e[c]=[]),e[c].push(o),t+=1),e}),{});w({actionProceedText:"Delete",content:"Resolve ".concat(t," SSH key conflicts. Please make sure the identity change(s) are expected to avoid MITM attacks."),onProceedAppend:function(){h.Z.delete("/ssh-key/conflict",{data:n}).catch((function(e){var t=(0,M.Z)(e);t.children="Failed to delete selected SSH key conflicts. ".concat(t.children),b(t)}))},proceedColour:"red",titleText:"Delete ".concat(t," conflicting SSH keys?")}),null===(e=d.current.setOpen)||void 0===e||e.call(null,!0)},onItemCheckboxChange:function(e,t,n){var r;g[e].isChecked=n,null===(r=f.current.setCheckAll)||void 0===r||r.call(null,Object.values(g).every((function(e){return e.isChecked}))),v((function(e){return xe({},e)}))},renderListItem:function(e,t){var n=t.hostName,o=t.ipAddress;return(0,r.jsxs)(T.Z,{spacing:0,sm:"row",sx:{width:"100%","& > *":{flexBasis:"50%"}},xs:"column",children:[(0,r.jsx)(k.Ac,{children:n}),(0,r.jsx)(k.Ac,{children:o})]})},renderListItemCheckboxState:function(e,t){return!0===t.isChecked},ref:f})]}),Z]}),(0,r.jsx)(a.Z,xe({closeOnProceed:!0},j,{ref:d}))]})};function Ze(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function Pe(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Oe(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){Pe(e,t,n[t])}))}return e}function Se(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],c=!0,l=!1;try{for(n=n.call(e);!(c=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);c=!0);}catch(a){l=!0,o=a}finally{try{c||null==n.return||n.return()}finally{if(l)throw o}}return i}}(e,t)||function(e,t){if(!e)return;if("string"===typeof e)return Ze(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return Ze(e,t)}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var ke=function(){var e=(0,U.Z)().protect,t=Se((0,D.Z)({children:"No users found."},e),2),n=t[0],o=t[1],i=Se((0,D.Z)(void 0,e),2),l=i[0],a=i[1];return(0,c.useEffect)((function(){l||h.Z.get("/user").then((function(e){var t=e.data;a(t)})).catch((function(e){a({}),o((0,M.Z)(e))}))}),[o,a,l]),(0,r.jsx)(re.TZ,{header:(0,r.jsx)(k.Ac,{children:"Manage users"}),loading:!l,children:(0,r.jsx)(te.Z,{allowEdit:!1,listEmpty:(0,r.jsx)(ne.Z,Oe({},n)),listItems:l,renderListItem:function(e,t){var n=t.userName;return(0,r.jsx)(k.Ac,{children:n})}})})},Ae=function(){return(0,r.jsxs)(re.s_,{children:[(0,r.jsx)(me,{}),(0,r.jsx)(we,{}),(0,r.jsx)(ke,{})]})},Ie=n(2852),Ce=n(4825),Te=n(2152);function Ee(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function Me(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Fe(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){Me(e,t,n[t])}))}return e}function Re(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],c=!0,l=!1;try{for(n=n.call(e);!(c=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);c=!0);}catch(a){l=!0,o=a}finally{try{c||null==n.return||n.return()}finally{if(l)throw o}}return i}}(e,t)||function(e,t){if(!e)return;if("string"===typeof e)return Ee(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return Ee(e,t)}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var $e=function(e){return(0,r.jsx)(Ce.Z,Fe({},e,{sx:{width:"100%"}}))},Ne=function(e){var t=e.installTarget,n=void 0===t?"disabled":t,o=e.onSubmit,l=e.title,a=(0,U.Z)().protect,s=Re((0,D.Z)(void 0,a),2),u=s[0],d=s[1],f=(0,c.useMemo)((function(){return l?(0,r.jsx)(k.z,{sx:{textAlign:"center"},children:l}):(0,r.jsx)(Te.Z,{mt:0})}),[l]),p=(0,c.useMemo)((function(){return u&&(0,r.jsx)(i.ZP,{item:!0,sm:2,xs:1,children:(0,r.jsx)(ne.Z,Fe({},u,{onClose:function(){d(void 0)}}))})}),[u,d]);return(0,r.jsxs)(re.s_,{children:[(0,r.jsx)(re.V9,{children:f}),(0,r.jsxs)(i.ZP,{columns:{xs:1,sm:2},container:!0,spacing:"1em",children:[(0,r.jsx)(i.ZP,{item:!0,sm:2,xs:1,children:(0,r.jsxs)(T.Z,{row:!0,children:[(0,r.jsx)(k.Ac,{sx:{flexGrow:1},children:"Install target"}),(0,r.jsx)(Ie.Z,{checked:"enabled"===n,edge:"end",onChange:function(e,t){var n="disable",i="Disable";t&&(n="enable",i="Enable"),null===o||void 0===o||o.call(null,{actionProceedText:i,content:(0,r.jsxs)(k.Ac,{children:["Would you like to ",n,' "Install target" on this striker? It\'ll take a few moments to complete.']}),onProceedAppend:function(){h.Z.put("/host/local",{isEnableInstallTarget:t},{params:{handler:"install-target"}}).catch((function(e){var t=(0,M.Z)(e);t.children="Failed to ".concat(n,' "Install target". ').concat(t.children),d(t)}))},titleText:"".concat(i,' "Install target" on ').concat(l,"?")})}})]})}),(0,r.jsx)(i.ZP,{item:!0,sm:2,xs:1,children:(0,r.jsx)($e,{onClick:function(){null===o||void 0===o||o.call(null,{actionProceedText:"Update",content:(0,r.jsx)(k.Ac,{children:"Would you like to update the operating system on this striker? It'll be placed into maintenance mode until the update completes."}),onProceedAppend:function(){h.Z.put("/command/update-system").catch((function(e){var t=(0,M.Z)(e);t.children="Failed to initiate system update. ".concat(t.children),d(t)}))},titleText:"Update operating system on ".concat(l,"?")})},children:"Update system"})}),(0,r.jsx)(i.ZP,{item:!0,sm:2,xs:1,children:(0,r.jsx)($e,{children:"Reconfigure striker"})}),(0,r.jsx)(i.ZP,{item:!0,xs:1,children:(0,r.jsx)($e,{onClick:function(){null===o||void 0===o||o.call(null,{actionProceedText:"Reboot",content:(0,r.jsx)(k.Ac,{children:"Would you like to reboot this striker?"}),onProceedAppend:function(){h.Z.put("/command/reboot-host").catch((function(e){var t=(0,M.Z)(e);t.children="Failed to initiate system reboot. ".concat(t.children),d(t)}))},titleText:"Reboot ".concat(l,"?")})},children:"Reboot"})}),(0,r.jsx)(i.ZP,{item:!0,xs:1,children:(0,r.jsx)($e,{onClick:function(){null===o||void 0===o||o.call(null,{actionProceedText:"Shutdown",content:(0,r.jsx)(k.Ac,{children:"Would you like to shutdown this striker?"}),onProceedAppend:function(){h.Z.put("/command/poweroff-host").catch((function(e){var t=(0,M.Z)(e);t.children="Failed to initiate system shutdown. ".concat(t.children),d(t)}))},titleText:"Shutdown ".concat(l,"?")})},children:"Shutdown"})}),p]})]})};function Ue(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function De(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Be(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){De(e,t,n[t])}))}return e}function _e(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}function ze(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],c=!0,l=!1;try{for(n=n.call(e);!(c=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);c=!0);}catch(a){l=!0,o=a}finally{try{c||null==n.return||n.return()}finally{if(l)throw o}}return i}}(e,t)||He(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function Le(e){return function(e){if(Array.isArray(e))return Ue(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||He(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function He(e,t){if(e){if("string"===typeof e)return Ue(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);return"Object"===n&&e.constructor&&(n=e.constructor.name),"Map"===n||"Set"===n?Array.from(n):"Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)?Ue(e,t):void 0}}var Ge=function(e){var t=e.refreshInterval,n=void 0===t?6e4:t,d=(0,U.Z)().protect,f=(0,c.useState)(!1),h=f[0],p=f[1],m=(0,c.useState)({actionProceedText:"",closeOnProceed:!0,content:"",dialogProps:{open:h},onCancelAppend:function(){p(!1)},onProceedAppend:function(){p(!1)},titleText:""}),b=m[0],y=m[1],g=ze((0,D.Z)(void 0,d),2),v=g[0],x=g[1],j=ze((0,D.Z)("",d),2),w=j[0],Z=j[1];return(0,u.Z)("".concat(l.Z,"/host/local"),{onError:function(){Z("Unknown")},onSuccess:function(e){var t=e.installTarget,n=e.shortHostName;x(t),Z(n)},refreshInterval:n}),(0,r.jsxs)(r.Fragment,{children:[(0,r.jsxs)(o.Z,{sx:{display:"flex",flexDirection:"column"},children:[(0,r.jsx)(s.Z,{}),(0,r.jsxs)(i.ZP,{container:!0,columns:{xs:1,md:3,lg:4},children:[(0,r.jsx)(i.ZP,{item:!0,xs:1,children:(0,r.jsx)(Ne,{installTarget:v,onSubmit:function(e){var t=e.onProceedAppend,n=_e(e,["onProceedAppend"]);y((function(e){return Be({},e,n,{onProceedAppend:function(){for(var e=arguments.length,n=new Array(e),r=0;r<e;r++)n[r]=arguments[r];var o;null===t||void 0===t||(o=t).call.apply(o,[null].concat(Le(n))),p(!1)}})})),p(!0)},title:w})}),(0,r.jsx)(i.ZP,{item:!0,md:2,xs:1,children:(0,r.jsx)(Ae,{})})]})]}),(0,r.jsx)(a.Z,Be({},b,{dialogProps:{open:h}}))]})}}},function(e){e.O(0,[738,688,7,619,315,818,141,892,384,774,888,179],(function(){return t=329,e(e.s=t);var t}));var t=e.O();_N_E=t}]);