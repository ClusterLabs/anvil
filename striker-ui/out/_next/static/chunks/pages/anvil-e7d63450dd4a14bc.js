(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[817],{2026:function(e,t,n){"use strict";var r=n(7892),o=n(5893);t.Z=(0,r.Z)((0,o.jsx)("path",{d:"M9 16.17 4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"}),"Check")},2852:function(e,t,n){"use strict";var r=n(3366),o=n(7462),i=n(7294),a=n(6010),c=n(7192),s=n(1796),l=n(8216),d=n(1964),u=n(3616),h=n(1496),f=n(9632),x=n(5893);const g=["className","color","edge","size","sx"],m=(0,h.ZP)("span",{name:"MuiSwitch",slot:"Root",overridesResolver:(e,t)=>{const{ownerState:n}=e;return[t.root,n.edge&&t[`edge${(0,l.Z)(n.edge)}`],t[`size${(0,l.Z)(n.size)}`]]}})((({ownerState:e})=>(0,o.Z)({display:"inline-flex",width:58,height:38,overflow:"hidden",padding:12,boxSizing:"border-box",position:"relative",flexShrink:0,zIndex:0,verticalAlign:"middle","@media print":{colorAdjust:"exact"}},"start"===e.edge&&{marginLeft:-8},"end"===e.edge&&{marginRight:-8},"small"===e.size&&{width:40,height:24,padding:7,[`& .${f.Z.thumb}`]:{width:16,height:16},[`& .${f.Z.switchBase}`]:{padding:4,[`&.${f.Z.checked}`]:{transform:"translateX(16px)"}}}))),v=(0,h.ZP)(d.Z,{name:"MuiSwitch",slot:"SwitchBase",overridesResolver:(e,t)=>{const{ownerState:n}=e;return[t.switchBase,{[`& .${f.Z.input}`]:t.input},"default"!==n.color&&t[`color${(0,l.Z)(n.color)}`]]}})((({theme:e})=>({position:"absolute",top:0,left:0,zIndex:1,color:"light"===e.palette.mode?e.palette.common.white:e.palette.grey[300],transition:e.transitions.create(["left","transform"],{duration:e.transitions.duration.shortest}),[`&.${f.Z.checked}`]:{transform:"translateX(20px)"},[`&.${f.Z.disabled}`]:{color:"light"===e.palette.mode?e.palette.grey[100]:e.palette.grey[600]},[`&.${f.Z.checked} + .${f.Z.track}`]:{opacity:.5},[`&.${f.Z.disabled} + .${f.Z.track}`]:{opacity:"light"===e.palette.mode?.12:.2},[`& .${f.Z.input}`]:{left:"-100%",width:"300%"}})),(({theme:e,ownerState:t})=>(0,o.Z)({"&:hover":{backgroundColor:(0,s.Fq)(e.palette.action.active,e.palette.action.hoverOpacity),"@media (hover: none)":{backgroundColor:"transparent"}}},"default"!==t.color&&{[`&.${f.Z.checked}`]:{color:e.palette[t.color].main,"&:hover":{backgroundColor:(0,s.Fq)(e.palette[t.color].main,e.palette.action.hoverOpacity),"@media (hover: none)":{backgroundColor:"transparent"}},[`&.${f.Z.disabled}`]:{color:"light"===e.palette.mode?(0,s.$n)(e.palette[t.color].main,.62):(0,s._j)(e.palette[t.color].main,.55)}},[`&.${f.Z.checked} + .${f.Z.track}`]:{backgroundColor:e.palette[t.color].main}}))),p=(0,h.ZP)("span",{name:"MuiSwitch",slot:"Track",overridesResolver:(e,t)=>t.track})((({theme:e})=>({height:"100%",width:"100%",borderRadius:7,zIndex:-1,transition:e.transitions.create(["opacity","background-color"],{duration:e.transitions.duration.shortest}),backgroundColor:"light"===e.palette.mode?e.palette.common.black:e.palette.common.white,opacity:"light"===e.palette.mode?.38:.3}))),b=(0,h.ZP)("span",{name:"MuiSwitch",slot:"Thumb",overridesResolver:(e,t)=>t.thumb})((({theme:e})=>({boxShadow:e.shadows[1],backgroundColor:"currentColor",width:20,height:20,borderRadius:"50%"}))),j=i.forwardRef((function(e,t){const n=(0,u.Z)({props:e,name:"MuiSwitch"}),{className:i,color:s="primary",edge:d=!1,size:h="medium",sx:j}=n,Z=(0,r.Z)(n,g),w=(0,o.Z)({},n,{color:s,edge:d,size:h}),_=(e=>{const{classes:t,edge:n,size:r,color:i,checked:a,disabled:s}=e,d={root:["root",n&&`edge${(0,l.Z)(n)}`,`size${(0,l.Z)(r)}`],switchBase:["switchBase",`color${(0,l.Z)(i)}`,a&&"checked",s&&"disabled"],thumb:["thumb"],track:["track"],input:["input"]},u=(0,c.Z)(d,f.H,t);return(0,o.Z)({},t,u)})(w),y=(0,x.jsx)(b,{className:_.thumb,ownerState:w});return(0,x.jsxs)(m,{className:(0,a.Z)(_.root,i),sx:j,ownerState:w,children:[(0,x.jsx)(v,(0,o.Z)({type:"checkbox",icon:y,checkedIcon:y,ref:t,ownerState:w},Z,{classes:(0,o.Z)({},_,{root:_.switchBase})})),(0,x.jsx)(p,{className:_.track,ownerState:w})]})}));t.Z=j},6069:function(e,t,n){(window.__NEXT_P=window.__NEXT_P||[]).push(["/anvil",function(){return n(1692)}])},1939:function(e,t,n){"use strict";var r=n(5893),o=n(7357),i=n(7169);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function c(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){a(e,t,n[t])}))}return e}function s(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var l="Decorator",d={ok:"".concat(l,"-ok"),warning:"".concat(l,"-warning"),error:"".concat(l,"-error"),off:"".concat(l,"-off")};t.Z=function(e){var t,n=e.colour,l=e.sx,u=s(e,["colour","sx"]);return(0,r.jsx)(o.Z,c({},u,{className:d[n],sx:c((t={borderRadius:i.n_,height:"100%",width:"1.4em"},a(t,"&.".concat(d.ok),{backgroundColor:i.Ej}),a(t,"&.".concat(d.warning),{backgroundColor:i.Wd}),a(t,"&.".concat(d.error),{backgroundColor:i.hM}),a(t,"&.".concat(d.off),{backgroundColor:i.s7}),t),l)}))}},1692:function(e,t,n){"use strict";n.r(t),n.d(t,{default:function(){return Je}});var r=n(5893),o=n(1496),i=n(7357),a=n(9008),c=n(1163),s=n(7294),l=n(7169),d={uuid:"",setAnvilUuid:function(){return null}},u=(0,s.createContext)(d),h=function(e){var t=e.children,n=(0,s.useState)(""),o=n[0],i=n[1];return(0,r.jsx)(u.Provider,{value:{uuid:o,setAnvilUuid:function(e){i(e)}},children:t})},f=n(3679),x=n(1905),g=n(2852),m=n(2416),v=new Map([["optimal","Optimal"],["not_ready","Not Ready"],["degraded","Degraded"]]),p=n(1939),b=n(8336);var j={anvilName:"".concat("SelectedAnvil","-anvilName")},Z=(0,o.ZP)(i.Z)((function(){return e={display:"flex",flexDirection:"row",width:"100%"},t="& .".concat(j.anvilName),n={paddingLeft:0},t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e;var e,t,n})),w=function(e){switch(e){case"optimal":return"ok";case"not_ready":return"warning";default:return"error"}},_=function(e){return!(-1===e.hosts.findIndex((function(e){return"offline"!==e.state})))},y=function(e){var t=e.list,n=(0,s.useContext)(u).uuid,o=t.findIndex((function(e){return e.anvil_uuid===n}));return(0,r.jsx)(Z,{children:""!==n&&(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(i.Z,{p:1,children:(0,r.jsx)(p.Z,{colour:w(t[o].anvil_state)})}),(0,r.jsxs)(i.Z,{p:1,flexGrow:1,className:j.anvilName,children:[(0,r.jsx)(m.z,{text:t[o].anvil_name}),(0,r.jsx)(m.z,{text:v.get(t[o].anvil_state)||"State unavailable"})]}),(0,r.jsx)(i.Z,{p:1,children:(0,r.jsx)(g.Z,{checked:_(t[o]),onChange:function(){return(0,b.Z)("".concat("/cgi-bin","/set_power"),{anvil_uuid:t[o].anvil_uuid,is_on:!_(t[o])})}})})]})})},k=n(8462),A=n(7720),N=n(891),S=function(e){var t=e.anvil;return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(m.Ac,{text:t.anvil_name}),(0,r.jsx)(m.Ac,{text:v.get(t.anvil_state)||"State unavailable"})]})};function C(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function P(e){return function(e){if(Array.isArray(e))return C(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||function(e,t){if(!e)return;if("string"===typeof e)return C(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return C(e,t)}(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var B=function(e){var t=[],n=[],r=[];return e.forEach((function(e){"optimal"===e.anvil_state?t.push(e):"not_ready"===e.anvil_state?n.push(e):r.push(e)})),P(r).concat(P(n),P(t))};function O(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var T="AnvilList",E={root:"".concat(T,"-root"),divider:"".concat(T,"-divider"),button:"".concat(T,"-button"),anvil:"".concat(T,"-anvil")},L=(0,o.ZP)("div")((function(e){var t,n=e.theme;return O(t={},"& .".concat(E.root),O({width:"100%",overflow:"auto",height:"30vh",paddingRight:".3em"},n.breakpoints.down(l.li),{height:"100%",overflow:"hidden"})),O(t,"& .".concat(E.divider),{backgroundColor:l.d}),O(t,"& .".concat(E.button),{"&:hover":{backgroundColor:l.$T},paddingLeft:0}),O(t,"& .".concat(E.anvil),{paddingLeft:0}),t})),M=function(e){switch(e){case"optimal":return"ok";case"not_ready":return"warning";case"degraded":return"error";default:return"off"}},$=function(e){var t=e.list,n=(0,s.useContext)(u),o=n.uuid,a=n.setAnvilUuid;return(0,s.useEffect)((function(){""===o&&a(B(t)[0].anvil_uuid)}),[o,t,a]),(0,r.jsx)(L,{children:(0,r.jsx)(k.Z,{component:"nav",className:E.root,"aria-label":"mailbox folders",children:B(t).map((function(e){return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(A.Z,{className:E.divider}),(0,r.jsx)(N.ZP,{button:!0,className:E.button,onClick:function(){return a(e.anvil_uuid)},children:(0,r.jsxs)(i.Z,{display:"flex",flexDirection:"row",width:"100%",children:[(0,r.jsx)(i.Z,{p:1,children:(0,r.jsx)(p.Z,{colour:M(e.anvil_state)})}),(0,r.jsx)(i.Z,{p:1,flexGrow:1,className:E.anvil,children:(0,r.jsx)(S,{anvil:e})})]})},e.anvil_uuid)]})}))})})};function z(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var R=function(e){var t=e.list,n=[];return null===t||void 0===t||t.anvils.forEach((function(e){var t=(0,x.Z)("".concat("/cgi-bin","/get_status?anvil_uuid=").concat(e.anvil_uuid)).data;n.push(function(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{},r=Object.keys(n);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(n).filter((function(e){return Object.getOwnPropertyDescriptor(n,e).enumerable})))),r.forEach((function(t){z(e,t,n[t])}))}return e}({},e,t))})),(0,r.jsxs)(f.s_,{children:[(0,r.jsx)(y,{list:n}),(0,r.jsx)($,{list:B(n)})]})},D=n(4690),F=n(2152),I=function(){var e=(0,s.useContext)(u).uuid,t=(0,x.Z)("".concat("/cgi-bin","/get_cpu?anvil_uuid=").concat(e)),n=t.data,o=void 0===n?{}:n,i=o.allocated,a=void 0===i?0:i,c=o.cores,l=void 0===c?0:c,d=o.threads,h=void 0===d?0:d,g=t.isLoading,v=(0,s.useMemo)((function(){return g?(0,r.jsx)(F.Z,{}):(0,r.jsxs)(D.Z,{spacing:0,children:[(0,r.jsx)(m.Ac,{text:"Total Cores: ".concat(l)}),(0,r.jsx)(m.Ac,{text:"Total Threads: ".concat(h)}),(0,r.jsx)(m.Ac,{text:"Allocated Cores: ".concat(a)})]})}),[a,l,g,h]);return(0,r.jsxs)(f.s_,{children:[(0,r.jsx)(f.V9,{children:(0,r.jsx)(m.z,{text:"CPU"})}),v]})},G=n(5716),U=n(9297),H=new Map([["message_0222","The node is in an unknown state."],["message_0223","The node is a full cluster member."],["message_0224","The node is coming online; the cluster resource manager is running (step 2/3)."],["message_0225","The node is coming online; the node is a consensus cluster member (step 1/3)."],["message_0226","The node has booted, but it is not (yet) joining the cluster."]]);function V(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var W="AnvilHost",X={state:"".concat(W,"-state"),bar:"".concat(W,"-bar"),label:"".concat(W,"-label"),decoratorBox:"".concat(W,"-decoratorBox")},Y=(0,o.ZP)(i.Z)((function(e){var t;return V(t={overflow:"auto",height:"28vh",paddingLeft:".3em",paddingRight:".3em"},e.theme.breakpoints.down(l.li),{height:"100%",overflow:"hidden"}),V(t,"& .".concat(X.state),{paddingLeft:".7em",paddingRight:".7em"}),V(t,"& .".concat(X.bar),{paddingLeft:".7em",paddingRight:".7em"}),V(t,"& .".concat(X.label),{paddingTop:".3em"}),V(t,"& .".concat(X.decoratorBox),{alignSelf:"stretch",paddingRight:".3em"}),t})),q=function(e,t){var n=e.exec(t);return n?H.get(n[0])||"Error code not recognized":"Error code not found"},J=function(e){switch(e){case"online":return"ok";case"offline":return"off";default:return"warning"}},K=function(e){var t=e.hosts,n=/^[a-zA-Z]/,o=/^(message_[0-9]+)/;return(0,r.jsx)(Y,{children:t&&t.map((function(e){var t;return e?(0,r.jsxs)(f.Lg,{children:[(0,r.jsxs)(f.CH,{children:[(0,r.jsx)(i.Z,{flexGrow:1,children:(0,r.jsx)(m.Ac,{text:e.host_name})}),(0,r.jsx)(i.Z,{className:X.decoratorBox,children:(0,r.jsx)(p.Z,{colour:J(e.state)})}),(0,r.jsx)(i.Z,{children:(0,r.jsx)(m.Ac,{text:(null===e||void 0===e||null===(t=e.state)||void 0===t?void 0:t.replace(n,(function(e){return e.toUpperCase()})))||"Not Available"})})]}),(0,r.jsxs)(i.Z,{display:"flex",className:X.state,children:[(0,r.jsx)(i.Z,{className:X.label,children:(0,r.jsx)(m.Ac,{text:"Power: "})}),(0,r.jsx)(i.Z,{flexGrow:1,children:(0,r.jsx)(g.Z,{checked:"online"===e.state,onChange:function(){return(0,b.Z)("".concat("/cgi-bin","/set_power"),{host_uuid:e.host_uuid,is_on:!("online"===e.state)})}})}),(0,r.jsx)(i.Z,{className:X.label,children:(0,r.jsx)(m.Ac,{text:"Member: "})}),(0,r.jsx)(i.Z,{children:(0,r.jsx)(g.Z,{checked:"online"===e.state,disabled:!("online"===e.state),onChange:function(){return(0,b.Z)("".concat("/cgi-bin","/set_membership"),{host_uuid:e.host_uuid,is_member:!("online"===e.state)})}})})]}),"online"!==e.state&&"offline"!==e.state&&(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(i.Z,{display:"flex",width:"100%",className:X.state,children:(0,r.jsx)(i.Z,{children:(0,r.jsx)(m.Ac,{text:q(o,e.state_message)})})}),(0,r.jsx)(i.Z,{display:"flex",width:"100%",className:X.bar,children:(0,r.jsx)(i.Z,{flexGrow:1,children:(0,r.jsx)(U.k,{progressPercentage:e.state_percent})})})]})]},e.host_uuid):(0,r.jsx)(r.Fragment,{})}))})},Q=function(e){return null===e||void 0===e?void 0:e.filter((function(e){return e.host_uuid}))},ee=function(e){var t=e.anvil,n=(0,s.useContext)(u).uuid,o=(0,x.Z)("".concat("/cgi-bin","/get_status?anvil_uuid=").concat(n)),i=o.data,a=o.isLoading,c=t.findIndex((function(e){return e.anvil_uuid===n}));return(0,r.jsxs)(f.s_,{children:[(0,r.jsx)(m.z,{text:"Nodes"}),a?(0,r.jsx)(F.Z,{}):(0,r.jsx)(r.Fragment,{children:-1!==c&&i&&(0,r.jsx)(K,{hosts:Q(t[c].hosts).reduce((function(e,t,n){var r=i.hosts[n];return r&&e.push(r),e}),[])})})]})},te=n(8600),ne=n.n(te),re=function(){var e=(0,s.useContext)(u).uuid,t=(0,x.Z)("".concat("/cgi-bin","/get_memory?anvil_uuid=").concat(e)),n=t.data,o=void 0===n?{}:n,a=o.allocated,c=void 0===a?0:a,l=o.reserved,d=void 0===l?0:l,h=o.total,g=void 0===h?0:h,v=t.isLoading;return(0,r.jsxs)(f.s_,{children:[(0,r.jsx)(f.V9,{children:(0,r.jsx)(m.z,{text:"Memory"})}),v?(0,r.jsx)(F.Z,{}):(0,r.jsxs)(r.Fragment,{children:[(0,r.jsxs)(i.Z,{display:"flex",width:"100%",children:[(0,r.jsx)(i.Z,{flexGrow:1,children:(0,r.jsx)(m.Ac,{text:"Allocated: ".concat(ne()(c,{binary:!0}))})}),(0,r.jsx)(i.Z,{children:(0,r.jsx)(m.Ac,{text:"Free: ".concat(ne()(g-c,{binary:!0}))})})]}),(0,r.jsx)(i.Z,{display:"flex",width:"100%",children:(0,r.jsx)(i.Z,{flexGrow:1,children:(0,r.jsx)(U.C,{allocated:c/g*100})})}),(0,r.jsx)(i.Z,{display:"flex",justifyContent:"center",width:"100%",children:(0,r.jsx)(m.Ac,{text:"Total: ".concat(ne()(g,{binary:!0})," | Reserved: ").concat(ne()(d,{binary:!0}))})})]})]})},oe=function(e){var t=[],n={bonds:[]};return e.hosts.forEach((function(e){e.bonds.forEach((function(r){var o=t.findIndex((function(e){return e===r.bond_name}));-1===o?(t.push(r.bond_name),n.bonds.push({bond_name:r.bond_name,bond_uuid:r.bond_uuid,bond_speed:0,bond_state:"degraded",hosts:[{host_name:e.host_name,host_uuid:e.host_uuid,link:r.links[0].is_active?r.links[0]:r.links[1]}]})):n.bonds[o].hosts.push({host_name:e.host_name,host_uuid:e.host_uuid,link:r.links[0].is_active?r.links[0]:r.links[1]})}))})),n.bonds.forEach((function(e){var t=e.hosts[0].link.link_speed>e.hosts[1].link.link_speed?1:0;e.bond_speed=e.hosts[t].link.link_speed,e.bond_state=e.hosts[t].link.link_state})),n},ie=n(3144),ae=n(2749);function ce(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function se(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function le(e,t){return function(e){if(Array.isArray(e))return e}(e)||function(e,t){var n=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=n){var r,o,i=[],a=!0,c=!1;try{for(n=n.call(e);!(a=(r=n.next()).done)&&(i.push(r.value),!t||i.length!==t);a=!0);}catch(s){c=!0,o=s}finally{try{a||null==n.return||n.return()}finally{if(c)throw o}}return i}}(e,t)||function(e,t){if(!e)return;if("string"===typeof e)return ce(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return ce(e,t)}(e,t)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var de="Network",ue={container:"".concat(de,"-container"),root:"".concat(de,"-root"),noPaddingLeft:"".concat(de,"-noPaddingLeft"),divider:"".concat(de,"-divider"),verticalDivider:"".concat(de,"-verticalDivider")},he=(0,o.ZP)("div")((function(e){var t,n=e.theme;return se(t={},"& .".concat(ue.container),se({width:"100%",overflow:"auto",height:"32vh",paddingRight:".3em"},n.breakpoints.down(l.li),{height:"100%",overflow:"hidden"})),se(t,"& .".concat(ue.root),{paddingTop:".7em",paddingBottom:".7em"}),se(t,"& .".concat(ue.noPaddingLeft),{paddingLeft:0}),se(t,"& .".concat(ue.divider),{backgroundColor:l.d}),se(t,"& .".concat(ue.verticalDivider),{height:"3.5em"}),t})),fe=function(e){switch(e){case"optimal":return"ok";case"degraded":default:return"warning";case"down":return"error"}},xe=function(){var e=(0,s.useContext)(u).uuid,t=(0,ie.Z)().protect,n=le((0,ae.Z)(void 0,t),2),o=n[0],a=n[1],c=(0,x.Z)("".concat("/cgi-bin","/get_networks?anvil_uuid=").concat(e),{onSuccess:function(e){a(oe(e))}}).isLoading;return(0,r.jsx)(f.s_,{children:(0,r.jsxs)(he,{children:[(0,r.jsx)(m.z,{text:"Network"}),c?(0,r.jsx)(F.Z,{}):(0,r.jsx)(i.Z,{className:ue.container,children:o&&o.bonds.map((function(e){return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsxs)(i.Z,{className:ue.root,display:"flex",flexDirection:"row",width:"100%",children:[(0,r.jsx)(i.Z,{p:1,className:ue.noPaddingLeft,children:(0,r.jsx)(p.Z,{colour:fe(e.bond_state)})}),(0,r.jsxs)(i.Z,{p:1,flexGrow:1,className:ue.noPaddingLeft,children:[(0,r.jsx)(m.Ac,{text:e.bond_name}),(0,r.jsx)(m.Ac,{text:"".concat(e.bond_speed,"Mbps")})]}),(0,r.jsx)(i.Z,{display:"flex",style:{paddingTop:".5em"},children:e.hosts.map((function(t,n){return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(i.Z,{p:1,style:{paddingTop:0,paddingBottom:0},children:(0,r.jsxs)(i.Z,{children:[(0,r.jsx)(m.Ac,{text:t.host_name,selected:!1}),(0,r.jsx)(m.Ac,{text:t.link.link_name})]})},t.host_name),n!==e.hosts.length-1&&(0,r.jsx)(A.Z,{className:"".concat(ue.divider," ").concat(ue.verticalDivider),orientation:"vertical",flexItem:!0})]})}))})]}),(0,r.jsx)(A.Z,{className:ue.divider})]})}))})]})})},ge=n(5861),me=n(3321),ve=n(8333),pe=n(8128),be=n(2428),je=n(2026),Ze=n(1797),we=(0,n(7892).Z)((0,r.jsx)("path",{d:"M12 8c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zm0 2c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2zm0 6c-1.1 0-2 .9-2 2s.9 2 2 2 2-.9 2-2-.9-2-2-2z"}),"MoreVert"),_e=new Map([["running","Running"],["idle","Idle"],["paused","Paused"],["in shutdown","Shutting Down"],["shut off","Off"],["crashed","Crashed"],["pmsuspended","PM Suspended"],["migrating","Migrating"]]),ye=n(1706),ke=n(4427),Ae=n(6350);function Ne(e,t){(null==t||t>e.length)&&(t=e.length);for(var n=0,r=new Array(t);n<t;n++)r[n]=e[n];return r}function Se(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function Ce(e){return function(e){if(Array.isArray(e))return Ne(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||function(e,t){if(!e)return;if("string"===typeof e)return Ne(e,t);var n=Object.prototype.toString.call(e).slice(8,-1);"Object"===n&&e.constructor&&(n=e.constructor.name);if("Map"===n||"Set"===n)return Array.from(n);if("Arguments"===n||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n))return Ne(e,t)}(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var Pe,Be="Servers",Oe={root:"".concat(Be,"-root"),divider:"".concat(Be,"-divider"),verticalDivider:"".concat(Be,"-verticalDivider"),button:"".concat(Be,"-button"),headerPadding:"".concat(Be,"-headerPadding"),hostsBox:"".concat(Be,"-hostsBox"),hostBox:"".concat(Be,"-hostBox"),checkbox:"".concat(Be,"-checkbox"),serverActionButton:"".concat(Be,"-serverActionButton"),editButtonBox:"".concat(Be,"-editButtonBox"),dropdown:"".concat(Be,"-dropdown"),power:"".concat(Be,"-power"),on:"".concat(Be,"-on"),off:"".concat(Be,"-off"),all:"".concat(Be,"-all")},Te=(0,o.ZP)("div")((function(e){var t,n=e.theme;return Se(t={},"& .".concat(Oe.root),Se({width:"100%",overflow:"auto",height:"78vh",paddingRight:".3em"},n.breakpoints.down(l.li),{height:"100%",overflow:"hidden"})),Se(t,"& .".concat(Oe.divider),{backgroundColor:l.d}),Se(t,"& .".concat(Oe.verticalDivider),{height:"75%",paddingTop:"1em"}),Se(t,"& .".concat(Oe.button),{"&:hover":{backgroundColor:l.$T},paddingLeft:0}),Se(t,"& .".concat(Oe.headerPadding),{paddingLeft:".3em"}),Se(t,"& .".concat(Oe.hostsBox),{padding:"1em",paddingRight:0}),Se(t,"& .".concat(Oe.hostBox),{paddingTop:0}),Se(t,"& .".concat(Oe.checkbox),{paddingTop:".8em"}),Se(t,"& .".concat(Oe.serverActionButton),{backgroundColor:l.lD,color:l.E5,textTransform:"none","&:hover":{backgroundColor:l.s7}}),Se(t,"& .".concat(Oe.editButtonBox),{paddingTop:".3em"}),Se(t,"& .".concat(Oe.dropdown),{paddingTop:".8em",paddingBottom:".8em"}),Se(t,"& .".concat(Oe.power),{color:l.E5}),Se(t,"& .".concat(Oe.all),{paddingTop:".5em",paddingLeft:".3em"}),t})),Ee=function(e){switch(e){case"running":return"ok";case"shut off":return"off";case"crashed":return"error";default:return"warning"}},Le=(0,o.ZP)(ge.Z)((Se(Pe={},"&.".concat(Oe.on),{color:l.Ej}),Se(Pe,"&.".concat(Oe.off),{color:l.hM}),Pe)),Me=function(e){var t,n=e.anvil,o=(0,s.useState)(null),a=o[0],c=o[1],d=(0,s.useState)(!1),h=d[0],g=d[1],v=(0,s.useState)(!1),j=v[0],Z=v[1],w=(0,s.useState)([]),_=w[0],y=w[1],S=(0,s.useState)(!1),C=S[0],P=S[1],B=(0,s.useContext)(u).uuid,O=(0,s.useRef)([]),T=(0,x.Z)("".concat("/cgi-bin","/get_servers?anvil_uuid=").concat(B)),E=T.data,L=(void 0===E?{}:E).servers,M=void 0===L?[]:L,$=T.isLoading,z=function(e){O.current=[],e.filter((function(e){return"running"===e.server_state})).length&&O.current.push("off"),e.filter((function(e){return"shut off"===e.server_state})).length&&O.current.push("on")},R=n.findIndex((function(e){return e.anvil_uuid===B})),D=Q(null===(t=n[R])||void 0===t?void 0:t.hosts);return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(f.s_,{children:(0,r.jsxs)(Te,{children:[(0,r.jsxs)(f.V9,{className:Oe.headerPadding,sx:{marginBottom:0},children:[(0,r.jsx)(m.z,{text:"Servers"}),(0,r.jsx)(ye.Z,{onClick:function(){return P(!0)},children:(0,r.jsx)(be.Z,{})}),(0,r.jsx)(ye.Z,{onClick:function(){return g(!h)},children:h?(0,r.jsx)(je.Z,{sx:{color:l.Ej}}):(0,r.jsx)(Ze.Z,{})})]}),h&&(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(i.Z,{className:Oe.headerPadding,display:"flex",children:(0,r.jsxs)(i.Z,{flexGrow:1,className:Oe.dropdown,children:[(0,r.jsx)(me.Z,{variant:"contained",startIcon:(0,r.jsx)(we,{}),onClick:function(e){c(e.currentTarget)},className:Oe.serverActionButton,children:(0,r.jsx)(ge.Z,{className:Oe.power,variant:"subtitle1",children:"Power"})}),(0,r.jsx)(ve.Z,{anchorEl:a,keepMounted:!0,open:Boolean(a),onClose:function(){return c(null)},children:O.current.map((function(e){return(0,r.jsx)(ke.Z,{onClick:function(){return function(e){c(null),_.length&&(0,b.Z)("".concat("/cgi-bin","/set_power"),{server_uuid_list:_,is_on:"on"===e})}(e)},children:(0,r.jsx)(Le,{className:Oe[e],variant:"subtitle1",children:e.replace(/^[a-z]/,(function(e){return e.toUpperCase()}))})},e)}))})]})}),(0,r.jsxs)(i.Z,{display:"flex",children:[(0,r.jsx)(i.Z,{children:(0,r.jsx)(pe.Z,{style:{color:l.lD},color:"secondary",checked:j,onChange:function(){j?(z([]),y([])):(z(M),y(M.map((function(e){return e.server_uuid})))),Z(!j)}})}),(0,r.jsx)(i.Z,{className:Oe.all,children:(0,r.jsx)(m.Ac,{text:"All"})})]})]}),$?(0,r.jsx)(F.Z,{}):(0,r.jsx)(i.Z,{className:Oe.root,children:(0,r.jsx)(k.Z,{component:"nav",children:M.map((function(e){return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(N.ZP,{button:!0,className:Oe.button,component:h?"div":"a",href:"/server?uuid=".concat(e.server_uuid,"&server_name=").concat(e.server_name),onClick:function(){return function(e){var t=_.indexOf(e);-1===t?_.push(e):_.splice(t,1);var n=M.filter((function(e){return-1!==_.indexOf(e.server_uuid)}));z(n),y(Ce(_))}(e.server_uuid)},children:(0,r.jsxs)(i.Z,{display:"flex",flexDirection:"row",width:"100%",children:[h&&(0,r.jsx)(i.Z,{className:Oe.checkbox,children:(0,r.jsx)(pe.Z,{style:{color:l.lD},color:"secondary",checked:void 0!==_.find((function(t){return t===e.server_uuid}))})}),(0,r.jsx)(i.Z,{p:1,children:(0,r.jsx)(p.Z,{colour:Ee(e.server_state)})}),(0,r.jsxs)(i.Z,{p:1,flexGrow:1,children:[(0,r.jsx)(m.Ac,{text:e.server_name}),(0,r.jsx)(m.Ac,{text:_e.get(e.server_state)||"Not Available"})]}),(0,r.jsx)(i.Z,{display:"flex",className:Oe.hostsBox,children:"shut off"!==e.server_state&&"crashed"!==e.server_state&&D.map((function(t,n){return(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)(i.Z,{p:1,className:Oe.hostBox,children:(0,r.jsx)(m.Ac,{text:t.host_name,selected:e.server_host_uuid===t.host_uuid})},t.host_uuid),n!==D.length-1&&(0,r.jsx)(A.Z,{className:"".concat(Oe.divider," ").concat(Oe.verticalDivider),orientation:"vertical"})]})}))})]})},e.server_uuid),(0,r.jsx)(A.Z,{className:Oe.divider})]})}))})})]})}),(0,r.jsx)(Ae.Z,{dialogProps:{open:C},onClose:function(){P(!1)}})]})};function $e(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var ze="SharedStorageHost",Re={fs:"".concat(ze,"-fs"),bar:"".concat(ze,"-bar"),decoratorBox:"".concat(ze,"-decoratorBox")},De=(0,o.ZP)("div")((function(){var e;return $e(e={},"& .".concat(Re.fs),{paddingLeft:".7em",paddingRight:".7em"}),$e(e,"& .".concat(Re.bar),{paddingLeft:".7em",paddingRight:".7em"}),$e(e,"& .".concat(Re.decoratorBox),{paddingRight:".3em"}),e})),Fe=function(e){var t=e.group;return(0,r.jsxs)(De,{children:[(0,r.jsxs)(i.Z,{display:"flex",width:"100%",className:Re.fs,children:[(0,r.jsx)(i.Z,{flexGrow:1,children:(0,r.jsx)(m.Ac,{text:"Used: ".concat(ne()(t.storage_group_total-t.storage_group_free,{binary:!0}))})}),(0,r.jsx)(i.Z,{children:(0,r.jsx)(m.Ac,{text:"Free: ".concat(ne()(t.storage_group_free,{binary:!0}))})})]}),(0,r.jsx)(i.Z,{display:"flex",width:"100%",className:Re.bar,children:(0,r.jsx)(i.Z,{flexGrow:1,children:(0,r.jsx)(U.C,{allocated:(t.storage_group_total-t.storage_group_free)/t.storage_group_total*100})})}),(0,r.jsx)(i.Z,{display:"flex",justifyContent:"center",width:"100%",children:(0,r.jsx)(m.Ac,{text:"Total Storage: ".concat(ne()(t.storage_group_total,{binary:!0}))})})]})};function Ie(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var Ge={root:"".concat("SharedStorage","-root")},Ue=(0,o.ZP)("div")((function(e){var t=e.theme;return Ie({},"& .".concat(Ge.root),Ie({overflow:"auto",height:"78vh",paddingLeft:".3em",paddingRight:".3em"},t.breakpoints.down(l.li),{height:"100%"}))})),He=function(){var e=(0,s.useContext)(u).uuid,t=(0,x.Z)("".concat("/cgi-bin","/get_shared_storage?anvil_uuid=").concat(e)),n=t.data,o=t.isLoading;return(0,r.jsx)(f.s_,{children:(0,r.jsxs)(Ue,{children:[(0,r.jsx)(m.z,{text:"Shared Storage"}),o?(0,r.jsx)(F.Z,{}):(0,r.jsx)(i.Z,{className:Ge.root,children:(null===n||void 0===n?void 0:n.storage_groups)&&n.storage_groups.map((function(e){return(0,r.jsxs)(f.Lg,{children:[(0,r.jsx)(f.CH,{children:(0,r.jsx)(m.Ac,{text:e.storage_group_name})}),(0,r.jsx)(Fe,{group:e},e.storage_group_uuid)]},e.storage_group_uuid)}))})]})})},Ve=function(){var e=(0,s.useState)(void 0),t=e[0],n=e[1];return(0,s.useEffect)((function(){var e=function(){n(window.innerWidth)};return e(),window.addEventListener("resize",e),function(){return window.removeEventListener("resize",e)}}),[]),t};function We(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}var Xe="Anvil",Ye={child:"".concat(Xe,"-child"),server:"".concat(Xe,"-server"),container:"".concat(Xe,"-container")},qe=(0,o.ZP)("div")((function(e){var t,n,r=e.theme;return We(n={},"& .".concat(Ye.child),(We(t={width:"22%",height:"100%"},r.breakpoints.down(l.li),{width:"50%"}),We(t,r.breakpoints.down("md"),{width:"100%"}),t)),We(n,"& .".concat(Ye.server),We({width:"35%",height:"100%"},r.breakpoints.down("md"),{width:"100%"})),We(n,"& .".concat(Ye.container),We({display:"flex",flexDirection:"row",width:"100%",justifyContent:"space-between"},r.breakpoints.down("md"),{display:"block"})),n})),Je=function(){var e=(0,c.useRouter)(),t=Ve(),n=e.query.anvil_uuid,o=(0,s.useContext)(u),d=o.uuid,g=o.setAnvilUuid,m=(0,x.Z)("".concat("/cgi-bin","/get_anvils")),v=m.data,p=m.isLoading,b=(0,s.useMemo)((function(){var e;return v&&t&&(e=t>l.li?(0,r.jsxs)(i.Z,{className:Ye.container,children:[(0,r.jsxs)(i.Z,{className:Ye.child,children:[(0,r.jsx)(R,{list:v}),(0,r.jsx)(ee,{anvil:v.anvils})]}),(0,r.jsx)(i.Z,{className:Ye.server,children:(0,r.jsx)(Me,{anvil:v.anvils})}),(0,r.jsx)(i.Z,{className:Ye.child,children:(0,r.jsx)(He,{})}),(0,r.jsxs)(i.Z,{className:Ye.child,children:[(0,r.jsx)(xe,{}),(0,r.jsx)(I,{}),(0,r.jsx)(re,{})]})]}):(0,r.jsxs)(i.Z,{className:Ye.container,children:[(0,r.jsxs)(i.Z,{className:Ye.child,children:[(0,r.jsx)(Me,{anvil:v.anvils}),(0,r.jsx)(R,{list:v}),(0,r.jsx)(ee,{anvil:v.anvils})]}),(0,r.jsxs)(i.Z,{className:Ye.child,children:[(0,r.jsx)(xe,{}),(0,r.jsx)(He,{}),(0,r.jsx)(I,{}),(0,r.jsx)(re,{})]})]})),e}),[v,t]),j=(0,s.useMemo)((function(){return p?(0,r.jsx)(f.s_,{sx:{marginLeft:{xs:"1em",sm:"auto"},marginRight:{xs:"1em",sm:"auto"},marginTop:"calc(50vh - 10em)",maxWidth:{xs:void 0,sm:"60%",md:"50%",lg:"40%"},minWidth:"fit-content"},children:(0,r.jsx)(F.Z,{sx:{margin:"2em 2.4em"}})}):b}),[b,p]);return(0,s.useEffect)((function(){""===d&&g((null===n||void 0===n?void 0:n.toString())||"")}),[d,n,g]),(0,r.jsxs)(qe,{children:[(0,r.jsx)(a.default,{children:(0,r.jsx)("title",{children:"Anvil"})}),(0,r.jsxs)(h,{children:[(0,r.jsx)(G.Z,{}),j]})]})}},8600:function(e){"use strict";const t=["B","kB","MB","GB","TB","PB","EB","ZB","YB"],n=["B","kiB","MiB","GiB","TiB","PiB","EiB","ZiB","YiB"],r=["b","kbit","Mbit","Gbit","Tbit","Pbit","Ebit","Zbit","Ybit"],o=["b","kibit","Mibit","Gibit","Tibit","Pibit","Eibit","Zibit","Yibit"],i=(e,t,n)=>{let r=e;return"string"===typeof t||Array.isArray(t)?r=e.toLocaleString(t,n):!0!==t&&void 0===n||(r=e.toLocaleString(void 0,n)),r};e.exports=(e,a)=>{if(!Number.isFinite(e))throw new TypeError(`Expected a finite number, got ${typeof e}: ${e}`);const c=(a=Object.assign({bits:!1,binary:!1},a)).bits?a.binary?o:r:a.binary?n:t;if(a.signed&&0===e)return` 0 ${c[0]}`;const s=e<0,l=s?"-":a.signed?"+":"";let d;if(s&&(e=-e),void 0!==a.minimumFractionDigits&&(d={minimumFractionDigits:a.minimumFractionDigits}),void 0!==a.maximumFractionDigits&&(d=Object.assign({maximumFractionDigits:a.maximumFractionDigits},d)),e<1){return l+i(e,a.locale,d)+" "+c[0]}const u=Math.min(Math.floor(a.binary?Math.log(e)/Math.log(1024):Math.log10(e)/3),c.length-1);e/=Math.pow(a.binary?1024:1e3,u),d||(e=e.toPrecision(3));return l+i(Number(e),a.locale,d)+" "+c[u]}}},function(e){e.O(0,[738,688,7,643,536,369,315,818,141,892,149,774,888,179],(function(){return t=6069,e(e.s=t);var t}));var t=e.O();_N_E=t}]);