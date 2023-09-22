"use strict";(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[248],{5521:function(n,e,t){t.d(e,{Z:function(){return W}});var r=t(5893),o=t(1113),i=t(1496),c=t(2293),a=t(7357),u=t(2992),l=t(4799),s=t(7294),f=t(7169),d=t(4433),p=t(9029),g=t(7533),m=t(8462),y=t(7212),v=t(8619),b=[{text:"Anvil",image:"/pngs/anvil_icon_on.png",uri:"/manage-element"},{text:"Files",image:"/pngs/files_on.png",uri:"/file-manager"},{text:"Configure",image:"/pngs/configure_icon_on.png",uri:"/config"},{text:"Help",image:"/pngs/help_icon_on.png",uri:"https://alteeve.com/w/Support"}],h={width:"40em",height:"40em"},j=t(4390),x=t(582),w=t(4690),O=t(1770),S=t(7750),Z=t(1081);function P(n,e){(null==e||e>n.length)&&(e=n.length);for(var t=0,r=new Array(e);t<e;t++)r[t]=n[t];return r}function k(n,e){return function(n){if(Array.isArray(n))return n}(n)||function(n,e){var t=null==n?null:"undefined"!==typeof Symbol&&n[Symbol.iterator]||n["@@iterator"];if(null!=t){var r,o,i=[],c=!0,a=!1;try{for(t=t.call(n);!(c=(r=t.next()).done)&&(i.push(r.value),!e||i.length!==e);c=!0);}catch(u){a=!0,o=u}finally{try{c||null==t.return||t.return()}finally{if(a)throw o}}return i}}(n,e)||function(n,e){if(!n)return;if("string"===typeof n)return P(n,e);var t=Object.prototype.toString.call(n).slice(8,-1);"Object"===t&&n.constructor&&(t=n.constructor.name);if("Map"===t||"Set"===t)return Array.from(t);if("Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return P(n,e)}(n,e)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var A=function(){var n=(0,Z.Z)(),e=(0,s.useState)({}),t=e[0],r=e[1],o=(0,s.useCallback)((function(n){var e=arguments.length>1&&void 0!==arguments[1]?arguments[1]:"suiapi.";return t["".concat(e).concat(n)]}),[t]),i=(0,s.useCallback)((function(){return o("user")}),[o]);return(0,s.useEffect)((function(){if(n){var e=document.cookie.split(/\s*;\s*/);r(e.reduce((function(n,e){var t,r=k(e.split("=",2),2),o=r[0],i=r[1],c=decodeURIComponent(i);if(c.startsWith("j:"))try{t=JSON.parse(c.substring(2))}catch(a){t=i}else t=i;return n[o]=t,n}),{}))}}),[n]),{cookieJar:t,getCookie:o,getSessionUser:i}};function C(n,e,t){return e in n?Object.defineProperty(n,e,{value:t,enumerable:!0,configurable:!0,writable:!0}):n[e]=t,n}function I(n){for(var e=1;e<arguments.length;e++){var t=null!=arguments[e]?arguments[e]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(n){return Object.getOwnPropertyDescriptor(t,n).enumerable})))),r.forEach((function(e){C(n,e,t[e])}))}return n}var E="AnvilDrawer",B={actionIcon:"".concat(E,"-actionIcon"),list:"".concat(E,"-list")},M=(0,i.ZP)(g.ZP)((function(){var n;return C(n={},"& .".concat(B.list),{width:"200px"}),C(n,"& .".concat(B.actionIcon),{fontSize:"2.3em",color:f.of}),n})),_=function(n){var e=n.open,t=n.setOpen,o=(0,A().getSessionUser)();return(0,r.jsx)(M,{BackdropProps:{invisible:!0},anchor:"left",open:e,onClose:function(){return t(!e)},children:(0,r.jsx)("div",{role:"presentation",children:(0,r.jsxs)(m.Z,{className:B.list,children:[(0,r.jsx)(y.ZP,{children:(0,r.jsx)(S.Ac,{children:o?(0,r.jsxs)(r.Fragment,{children:["Welcome, ",o.name]}):"Unregistered"})}),(0,r.jsx)(x.Z,{}),(0,r.jsx)(v.Z,{component:"a",href:"/index.html",children:(0,r.jsxs)(w.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,r.jsx)(d.Z,{className:B.actionIcon}),(0,r.jsx)(S.Ac,{children:"Dashboard"})]})}),b.map((function(n){return(0,r.jsx)(v.Z,{component:"a",href:n.uri,children:(0,r.jsxs)(w.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,r.jsx)("img",I({alt:n.text,src:n.image},h)),(0,r.jsx)(S.Ac,{children:n.text})]})},"anvil-drawer-".concat(n.image))})),(0,r.jsx)(v.Z,{onClick:function(){j.Z.put("/auth/logout").then((function(){window.location.replace("/login")})).catch((function(n){(0,O.Z)(n)}))},children:(0,r.jsxs)(w.Z,{fullWidth:!0,row:!0,spacing:"2em",children:[(0,r.jsx)(p.Z,{className:B.actionIcon}),(0,r.jsx)(S.Ac,{children:"Logout"})]})})]})})})},N=t(3377),T=t(2444);function R(n,e,t){return e in n?Object.defineProperty(n,e,{value:t,enumerable:!0,configurable:!0,writable:!0}):n[e]=t,n}var U="Header",D={input:"".concat(U,"-input"),barElement:"".concat(U,"-barElement"),iconBox:"".concat(U,"-iconBox"),searchBar:"".concat(U,"-searchBar"),icons:"".concat(U,"-icons")},F=(0,i.ZP)(c.Z)((function(n){var e,t=n.theme;return R(e={paddingTop:t.spacing(.5),paddingBottom:t.spacing(.5),paddingLeft:t.spacing(3),paddingRight:t.spacing(3),borderBottom:"solid 1px",borderBottomColor:f.hM,position:"static"},"& .".concat(D.input),{height:"2.8em",width:"30vw",backgroundColor:t.palette.secondary.main,borderRadius:f.n_}),R(e,"& .".concat(D.barElement),{padding:0}),R(e,"& .".concat(D.iconBox),R({},t.breakpoints.down("sm"),{display:"none"})),R(e,"& .".concat(D.searchBar),R({},t.breakpoints.down("sm"),{flexGrow:1,paddingLeft:"15vw"})),R(e,"& .".concat(D.icons),{paddingLeft:".1em",paddingRight:".1em"}),e})),W=function(){var n=(0,s.useRef)({}),e=(0,s.useRef)({}),t=(0,s.useState)(!1),i=t[0],c=t[1];return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(F,{children:(0,r.jsxs)(a.Z,{display:"flex",justifyContent:"space-between",flexDirection:"row",children:[(0,r.jsx)(w.Z,{row:!0,children:(0,r.jsx)(u.Z,{onClick:function(){return c(!i)},children:(0,r.jsx)("img",{alt:"",src:"/pngs/logo.png",width:"160",height:"40"})})}),(0,r.jsx)(w.Z,{className:D.iconBox,row:!0,spacing:0,children:(0,r.jsx)(a.Z,{children:(0,r.jsx)(l.Z,{onClick:function(n){var t,r,o=n.currentTarget;null===(t=e.current.setAnchor)||void 0===t||t.call(null,o),null===(r=e.current.setOpen)||void 0===r||r.call(null,!0)},sx:{color:f.of,padding:"0 .1rem"},children:(0,r.jsx)(N.Z,{icon:o.Z,ref:n})})})})]})}),(0,r.jsx)(_,{open:i,setOpen:c}),(0,r.jsx)(T.Z,{onFetchSuccessAppend:function(e){var t;null===(t=n.current.indicate)||void 0===t||t.call(null,Object.keys(e).length>0)},ref:e})]})}},7869:function(n,e,t){var r=t(5893),o=t(7294),i=t(8187);function c(n,e){(null==e||e>n.length)&&(e=n.length);for(var t=0,r=new Array(e);t<e;t++)r[t]=n[t];return r}function a(n,e,t){return e in n?Object.defineProperty(n,e,{value:t,enumerable:!0,configurable:!0,writable:!0}):n[e]=t,n}function u(n,e){if(null==n)return{};var t,r,o=function(n,e){if(null==n)return{};var t,r,o={},i=Object.keys(n);for(r=0;r<i.length;r++)t=i[r],e.indexOf(t)>=0||(o[t]=n[t]);return o}(n,e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(n);for(r=0;r<i.length;r++)t=i[r],e.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(n,t)&&(o[t]=n[t])}return o}function l(n,e){return function(n){if(Array.isArray(n))return n}(n)||function(n,e){var t=null==n?null:"undefined"!==typeof Symbol&&n[Symbol.iterator]||n["@@iterator"];if(null!=t){var r,o,i=[],c=!0,a=!1;try{for(t=t.call(n);!(c=(r=t.next()).done)&&(i.push(r.value),!e||i.length!==e);c=!0);}catch(u){a=!0,o=u}finally{try{c||null==t.return||t.return()}finally{if(a)throw o}}return i}}(n,e)||function(n,e){if(!n)return;if("string"===typeof n)return c(n,e);var t=Object.prototype.toString.call(n).slice(8,-1);"Object"===t&&n.constructor&&(t=n.constructor.name);if("Map"===t||"Set"===t)return Array.from(t);if("Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return c(n,e)}(n,e)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function s(n){var e=function(n,e){if("object"!==f(n)||null===n)return n;var t=n[Symbol.toPrimitive];if(void 0!==t){var r=t.call(n,e||"default");if("object"!==f(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(n)}(n,"string");return"symbol"===f(e)?e:String(e)}var f=function(n){return n&&"undefined"!==typeof Symbol&&n.constructor===Symbol?"symbol":typeof n};var d={count:0,defaultMessageType:"info",messages:void 0,onSet:void 0,usePlaceholder:!0},p=(0,o.forwardRef)((function(n,e){var t=n.count,c=void 0===t?d.count:t,f=n.defaultMessageType,p=void 0===f?d.defaultMessageType:f,g=n.messages,m=n.onSet,y=n.usePlaceholder,v=void 0===y?d.usePlaceholder:y,b=(0,o.useState)({}),h=b[0],j=b[1],x=(0,o.useMemo)((function(){return function(n){for(var e=1;e<arguments.length;e++){var t=null!=arguments[e]?arguments[e]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(n){return Object.getOwnPropertyDescriptor(t,n).enumerable})))),r.forEach((function(e){a(n,e,t[e])}))}return n}({},g,h)}),[g,h]),w=(0,o.useCallback)((function(n){return void 0!==x[n]}),[x]),O=(0,o.useCallback)((function(n,e){var t=0;j((function(r){r[n];var o=u(r,[n].map(s));return e&&(o[n]=e),t=Object.keys(o).length,o})),null===m||void 0===m||m.call(null,t)}),[m]),S=(0,o.useCallback)((function(n,e){var t=0,r=e?function(n,r){n[r]=e,t+=1}:void 0;j((function(e){var o={};return Object.keys(e).forEach((function(i){n.test(i)?null===r||void 0===r||r.call(null,o,i):(o[i]=e[i],t+=1)})),o})),null===m||void 0===m||m.call(null,t)}),[m]),Z=(0,o.useMemo)((function(){var n=Object.entries(x),e=c>0,t=e?c:n.length,o=[];if(n.every((function(n){var e=l(n,2),c=e[0],a=e[1],u=a.children,s=a.type,f=void 0===s?p:s;return o.push((0,r.jsx)(i.Z,{type:f,children:u},"message-".concat(c))),o.length<t})),v&&e&&0===o.length)for(var a=c-o.length,u=0;u<a;u+=1)o.push((0,r.jsx)(i.Z,{sx:{visibility:"hidden"},text:"Placeholder"},"message-placeholder-".concat(u)));return o}),[c,p,v,x]);return(0,o.useImperativeHandle)(e,(function(){return{exists:w,setMessage:O,setMessageRe:S}}),[w,O,S]),(0,r.jsx)(r.Fragment,{children:Z})}));p.defaultProps=d,p.displayName="MessageGroup",e.Z=p},1081:function(n,e,t){var r=t(7294);e.Z=function(){var n=(0,r.useRef)(!0);return n.current?(n.current=!1,!0):n.current}},6607:function(n,e,t){function r(n,e){(null==e||e>n.length)&&(e=n.length);for(var t=0,r=new Array(e);t<e;t++)r[t]=n[t];return r}function o(n,e,t){return e in n?Object.defineProperty(n,e,{value:t,enumerable:!0,configurable:!0,writable:!0}):n[e]=t,n}function i(n){for(var e=1;e<arguments.length;e++){var t=null!=arguments[e]?arguments[e]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(n){return Object.getOwnPropertyDescriptor(t,n).enumerable})))),r.forEach((function(e){o(n,e,t[e])}))}return n}function c(n,e){if(null==n)return{};var t,r,o=function(n,e){if(null==n)return{};var t,r,o={},i=Object.keys(n);for(r=0;r<i.length;r++)t=i[r],e.indexOf(t)>=0||(o[t]=n[t]);return o}(n,e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(n);for(r=0;r<i.length;r++)t=i[r],e.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(n,t)&&(o[t]=n[t])}return o}function a(n,e){return function(n){if(Array.isArray(n))return n}(n)||function(n,e){var t=null==n?null:"undefined"!==typeof Symbol&&n[Symbol.iterator]||n["@@iterator"];if(null!=t){var r,o,i=[],c=!0,a=!1;try{for(t=t.call(n);!(c=(r=t.next()).done)&&(i.push(r.value),!e||i.length!==e);c=!0);}catch(u){a=!0,o=u}finally{try{c||null==t.return||t.return()}finally{if(a)throw o}}return i}}(n,e)||function(n,e){if(!n)return;if("string"===typeof n)return r(n,e);var t=Object.prototype.toString.call(n).slice(8,-1);"Object"===t&&n.constructor&&(t=n.constructor.name);if("Map"===t||"Set"===t)return Array.from(t);if("Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return r(n,e)}(n,e)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function u(n){var e=function(n,e){if("object"!==l(n)||null===n)return n;var t=n[Symbol.toPrimitive];if(void 0!==t){var r=t.call(n,e||"default");if("object"!==l(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(n)}(n,"string");return"symbol"===l(e)?e:String(e)}t.d(e,{Um:function(){return d}});var l=function(n){return n&&"undefined"!==typeof Symbol&&n.constructor===Symbol?"symbol":typeof n};var s=function(){for(var n=arguments.length,e=new Array(n),t=0;t<n;t++)e[t]=arguments[t];var r=a(e,4),o=r[1],i=r[2],c=r[3];void 0!==c&&(o[i]=c)},f=function(n,e){var t=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},r=t.guard,o=void 0===r?function(){return!0}:r,a=t.set,l=void 0===a?s:a;return function(t){t[n];var r=i({},c(t,[n].map(u)));return o(t,n,e)&&l(t,r,n,e),r}},d=function(n,e){var t=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},r=t.set,o=void 0===r?s:r;return function(t){var r={};return Object.keys(t).forEach((function(i){var c=i;n.test(i)?o(t,r,c,e):r[c]=t[c]})),r}};e.ZP=f},3675:function(n,e){var t={boolean:function(n){return Boolean(n)},number:function(n){return parseInt(String(n),10)||0},string:function(n){return String(n)}};e.Z=t}}]);