(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[464],{593:function(e,n,t){(window.__NEXT_P=window.__NEXT_P||[]).push(["/init",function(){return t(8616)}])},4069:function(e,n,t){"use strict";t.d(n,{Z:function(){return y}});var r=t(6486),i=t(7294),o=t(3675),l=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.postSet,t=e.preSet,r=e.set,i=e.setType,l=void 0===i?"string":i,u=e.valueKey,a=void 0===u?"value":u;return function(e){var i=e.target[a],u=o.Z[l](i);null===t||void 0===t||t.call(null,e),null===r||void 0===r||r.call(null,u),null===n||void 0===n||n.call(null,e)}},u=t(2027);function a(e,n){(null==n||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function c(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function s(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){c(e,n,t[n])}))}return e}function d(e,n){if(null==e)return{};var t,r,i=function(e,n){if(null==e)return{};var t,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(i[t]=e[t]);return i}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(i[t]=e[t])}return i}function f(e){return function(e){if(Array.isArray(e))return a(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||function(e,n){if(!e)return;if("string"===typeof e)return a(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);"Object"===t&&e.constructor&&(t=e.constructor.name);if("Map"===t||"Set"===t)return Array.from(t);if("Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return a(e,n)}(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function v(e){var n=function(e,n){if("object"!==p(e)||null===e)return e;var t=e[Symbol.toPrimitive];if(void 0!==t){var r=t.call(e,n||"default");if("object"!==p(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===n?String:Number)(e)}(e,"string");return"symbol"===p(n)?n:String(n)}var p=function(e){return e&&"undefined"!==typeof Symbol&&e.constructor===Symbol?"symbol":typeof e};var m="input",h={boolean:!1,number:0,string:""},g={createInputOnChangeHandlerOptions:{},debounceWait:500,required:!1,valueType:"string"},b=(0,i.forwardRef)((function(e,n){var t=e.debounceWait,o=void 0===t?g.debounceWait:t,a=e.input,p=e.inputTestBatch,b=e.onBlurAppend,y=e.onFirstRender,x=e.onFocusAppend,j=e.onUnmount,w=e.required,P=void 0===w?g.required:w,O=e.valueKey,S=e.valueType,k=void 0===S?g.valueType:S,Z=e.createInputOnChangeHandlerOptions,C=void 0===Z?g.createInputOnChangeHandlerOptions:Z,A=C.postSet,I=C.valueKey,N=void 0===I?O:I,V=d(e.createInputOnChangeHandlerOptions,["postSet","valueKey"]),H=a.props,M=(0,i.useMemo)((function(){return null!==N&&void 0!==N?N:"checked"in H?"checked":"value"}),[H,N]),R=H.onBlur,F=H.onChange,E=H.onFocus,T=H[M],z=void 0===T?h[k]:T,B=d(H,["onBlur","onChange","onFocus",M].map(v)),D=(0,i.useState)(z),_=D[0],L=D[1],q=(0,i.useState)(!1),U=q[0],$=q[1],Q=(0,i.useState)(!1),J=Q[0],G=Q[1],W=(0,i.useCallback)((function(e){L(e)}),[]),K=(0,i.useMemo)((function(){var e;return p&&(p.isRequired=P,e=(0,u.LT)(c({},m,p))),e}),[p,P]),X=(0,i.useCallback)((function(e){var n,t=null!==(n=null===K||void 0===K?void 0:K.call(null,{inputs:c({},m,{value:e}),isIgnoreOnCallbacks:!0}))&&void 0!==n&&n;null===y||void 0===y||y.call(null,{isValid:t}),G(t)}),[y,K]),Y=(0,i.useMemo)((function(){return(0,r.debounce)(X,o)}),[o,X]),ee=(0,i.useMemo)((function(){return null!==R&&void 0!==R?R:K&&function(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];var r,i=n[0],o=i.target.value,l=K({inputs:c({},m,{value:o})});G(l),null===b||void 0===b||(r=b).call.apply(r,[null].concat(f(n)))}}),[R,b,K]),ne=(0,i.useMemo)((function(){return l(s({postSet:function(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];var r,i;$(!0),null===F||void 0===F||(r=F).call.apply(r,[null].concat(f(n))),null===A||void 0===A||(i=A).call.apply(i,[null].concat(f(n)))},set:function(e){W(e),Y(e)},setType:k,valueKey:M},V))}),[Y,F,A,V,W,M,k]),te=(0,i.useMemo)((function(){return null!==E&&void 0!==E?E:p&&function(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];var r,i,o;null===(i=p.defaults)||void 0===i||null===(o=i.onSuccess)||void 0===o||o.call(null,{append:{}}),null===x||void 0===x||(r=x).call.apply(r,[null].concat(f(n)))}}),[E,p,x]);return(0,i.useEffect)((function(){return X(_),j}),[]),(0,i.useEffect)((function(){!U&&_!==z&&z&&(X(z),L(z))}),[X,z,_,U]),(0,i.useImperativeHandle)(n,(function(){return{getIsChangedByUser:function(){return U},getValue:function(){return _},isValid:function(){return J},setValue:W}}),[_,U,J,W]),(0,i.cloneElement)(a,s({},B,c({onBlur:ee,onChange:ne,onFocus:te,required:P},M,_)))}));b.defaultProps=g,b.displayName="InputWithRef";var y=b},7869:function(e,n,t){"use strict";var r=t(5893),i=t(7294),o=t(8187);function l(e,n){(null==n||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function u(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function a(e,n){if(null==e)return{};var t,r,i=function(e,n){if(null==e)return{};var t,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(i[t]=e[t]);return i}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(i[t]=e[t])}return i}function c(e,n){return function(e){if(Array.isArray(e))return e}(e)||function(e,n){var t=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=t){var r,i,o=[],l=!0,u=!1;try{for(t=t.call(e);!(l=(r=t.next()).done)&&(o.push(r.value),!n||o.length!==n);l=!0);}catch(a){u=!0,i=a}finally{try{l||null==t.return||t.return()}finally{if(u)throw i}}return o}}(e,n)||function(e,n){if(!e)return;if("string"===typeof e)return l(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);"Object"===t&&e.constructor&&(t=e.constructor.name);if("Map"===t||"Set"===t)return Array.from(t);if("Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return l(e,n)}(e,n)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function s(e){var n=function(e,n){if("object"!==d(e)||null===e)return e;var t=e[Symbol.toPrimitive];if(void 0!==t){var r=t.call(e,n||"default");if("object"!==d(r))return r;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===n?String:Number)(e)}(e,"string");return"symbol"===d(n)?n:String(n)}var d=function(e){return e&&"undefined"!==typeof Symbol&&e.constructor===Symbol?"symbol":typeof e};var f={count:0,defaultMessageType:"info",messages:void 0,onSet:void 0,usePlaceholder:!0},v=(0,i.forwardRef)((function(e,n){var t=e.count,l=void 0===t?f.count:t,d=e.defaultMessageType,v=void 0===d?f.defaultMessageType:d,p=e.messages,m=e.onSet,h=e.usePlaceholder,g=void 0===h?f.usePlaceholder:h,b=(0,i.useState)({}),y=b[0],x=b[1],j=(0,i.useMemo)((function(){return function(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){u(e,n,t[n])}))}return e}({},p,y)}),[p,y]),w=(0,i.useCallback)((function(e){return void 0!==j[e]}),[j]),P=(0,i.useCallback)((function(e,n){var t=0;x((function(r){r[e];var i=a(r,[e].map(s));return n&&(i[e]=n),t=Object.keys(i).length,i})),null===m||void 0===m||m.call(null,t)}),[m]),O=(0,i.useCallback)((function(e,n){var t=0,r=n?function(e,r){e[r]=n,t+=1}:void 0;x((function(n){var i={};return Object.keys(n).forEach((function(o){e.test(o)?null===r||void 0===r||r.call(null,i,o):(i[o]=n[o],t+=1)})),i})),null===m||void 0===m||m.call(null,t)}),[m]),S=(0,i.useMemo)((function(){var e=Object.entries(j),n=l>0,t=n?l:e.length,i=[];if(e.every((function(e){var n=c(e,2),l=n[0],u=n[1],a=u.children,s=u.type,d=void 0===s?v:s;return i.push((0,r.jsx)(o.Z,{type:d,children:a},"message-".concat(l))),i.length<t})),g&&n&&0===i.length)for(var u=l-i.length,a=0;a<u;a+=1)i.push((0,r.jsx)(o.Z,{sx:{visibility:"hidden"},text:"Placeholder"},"message-placeholder-".concat(a)));return i}),[l,v,g,j]);return(0,i.useImperativeHandle)(n,(function(){return{exists:w,setMessage:P,setMessageRe:O}}),[w,P,O]),(0,r.jsx)(r.Fragment,{children:S})}));v.defaultProps=f,v.displayName="MessageGroup",n.Z=v},3675:function(e,n){"use strict";var t={boolean:function(e){return Boolean(e)},number:function(e){return parseInt(String(e),10)||0},string:function(e){return String(e)}};n.Z=t},8616:function(e,n,t){"use strict";t.r(n),t.d(n,{default:function(){return ae}});var r=t(5893),i=t(7357),o=t(1113),l=t(8263),u=t(1163),a=t(7294),c=t(2029),s=t(7169),d=t(4390),f=t(157),v=t(4825),p=t(4690),m=t(8128),h=t(4188),g=t(1250),b=t(4069),y=t(8187),x=t(7869),j=t(6284),w=function(e){var n=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{},t=n.fillString,r=void 0===t?"0":t,i=n.maxLength,o=void 0===i?2:i,l=n.which,u=void 0===l?"Start":l;return String(e)["pad".concat(u)](o,r)};function P(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function O(e,n){if(null==e)return{};var t,r,i=function(e,n){if(null==e)return{};var t,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(i[t]=e[t]);return i}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(i[t]=e[t])}return i}var S={show:!0},k=function(e){var n=e.onClick,t=e.show,i=void 0===t?S.show:t,o=O(e,["onClick","show"]);return i?(0,r.jsx)(v.Z,function(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){P(e,n,t[n])}))}return e}({onClick:n,tabIndex:-1},o,{children:"Suggest"})):(0,r.jsx)(r.Fragment,{})};k.defaultProps=S;var Z=k,C=t(2027),A=t(7750);function I(e,n){(null==n||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function N(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function V(e,n){return function(e){if(Array.isArray(e))return e}(e)||function(e,n){var t=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=t){var r,i,o=[],l=!0,u=!1;try{for(t=t.call(e);!(l=(r=t.next()).done)&&(o.push(r.value),!n||o.length!==n);l=!0);}catch(a){u=!0,i=a}finally{try{l||null==t.return||t.return()}finally{if(u)throw i}}return o}}(e,n)||M(e,n)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function H(e){return function(e){if(Array.isArray(e))return I(e)}(e)||function(e){if("undefined"!==typeof Symbol&&null!=e[Symbol.iterator]||null!=e["@@iterator"])return Array.from(e)}(e)||M(e)||function(){throw new TypeError("Invalid attempt to spread non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}function M(e,n){if(e){if("string"===typeof e)return I(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);return"Object"===t&&e.constructor&&(t=e.constructor.name),"Map"===t||"Set"===t?Array.from(t):"Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t)?I(e,n):void 0}}var R="adminPassword",F="confirmAdminPassword",E="domainName",T="hostName",z="hostNumber",B="organizationName",D="organizationPrefix",_={0:function(){return""},1:function(e){return V(e,1)[0].substring(0,1).toLocaleLowerCase()},2:function(e){return e.map((function(e){return e.substring(0,1).toLocaleLowerCase()})).join("")}},L=function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:"",n=e.split(/\s/).filter((function(e){return!/and|of/.test(e)})).slice(0,5),t=n.length>1?2:n.length;return _[t](n)},q=function(e){var n=e.organizationPrefix,t=e.hostNumber,r=e.domainName;return[n,t,r].every((function(e){return Boolean(e)}))?"".concat(n,"-striker").concat(w(t),".").concat(r):""},U=(0,a.forwardRef)((function(e,n){var t,i,o,u,c=e.expectHostDetail,s=void 0!==c&&c,d=e.hostDetail,f=e.onHostNumberBlurAppend,v=e.toggleSubmitDisabled,w=(0,a.useState)(),P=w[0],O=w[1],S=(0,a.useState)(!1),k=S[0],I=S[1],M=(0,a.useState)(!1),_=M[0],U=M[1],$=(0,a.useState)(!0),Q=$[0],J=$[1],G=(0,a.useState)(!0),W=G[0],K=G[1],X=(0,a.useRef)(!0),Y=(0,a.useRef)({}),ee=(0,a.useRef)({}),ne=(0,a.useRef)({}),te=(0,a.useRef)({}),re=(0,a.useRef)({}),ie=(0,a.useRef)({}),oe=(0,a.useRef)({}),le=(0,a.useRef)({}),ue=(0,a.useCallback)((function(e){var n;return null===(n=le.current.setMessage)||void 0===n?void 0:n.call(null,D,e)}),[]),ae=(0,a.useCallback)((function(e){var n;return null===(n=le.current.setMessage)||void 0===n?void 0:n.call(null,z,e)}),[]),ce=(0,a.useCallback)((function(e){var n;return null===(n=le.current.setMessage)||void 0===n?void 0:n.call(null,E,e)}),[]),se=(0,a.useCallback)((function(e){var n;return null===(n=le.current.setMessage)||void 0===n?void 0:n.call(null,T,e)}),[]),de=(0,a.useCallback)((function(e){var n;return null===(n=le.current.setMessage)||void 0===n?void 0:n.call(null,R,e)}),[]),fe=(0,a.useCallback)((function(e){var n;return null===(n=le.current.setMessage)||void 0===n?void 0:n.call(null,F,e)}),[]),ve=(0,a.useMemo)((function(){var e;return N(e={},R,{defaults:{getValue:function(){var e;return null===(e=Y.current.getValue)||void 0===e?void 0:e.call(null)},onSuccess:function(){de(void 0)}},tests:[{onFailure:function(){de({children:(0,r.jsxs)(r.Fragment,{children:["Admin password cannot contain single-quote (",(0,r.jsx)(A.Q0,{text:"'"}),"), double-quote (",(0,r.jsx)(A.Q0,{text:'"'}),"), slash (",(0,r.jsx)(A.Q0,{text:"/"}),"), backslash (",(0,r.jsx)(A.Q0,{text:"\\"}),"), angle brackets (",(0,r.jsx)(A.Q0,{text:"<>"}),"), curly brackets (",(0,r.jsx)(A.Q0,{text:"{}"}),")."]})})},test:function(e){var n=e.value;return!/['"/\\><}{]/g.test(n)}},{test:C.HJ}]}),N(e,F,{defaults:{getValue:function(){var e,n;return null===(e=ee.current)||void 0===e||null===(n=e.getValue)||void 0===n?void 0:n.call(null)},onSuccess:function(){fe(void 0)}},tests:[{onFailure:function(){fe({children:"Confirmation doesn't match admin password."})},test:function(e){var n;return e.value===(null===(n=Y.current.getValue)||void 0===n?void 0:n.call(null))}},{test:C.HJ}]}),N(e,E,{defaults:{compare:[!W],getValue:function(){var e;return null===(e=re.current.getValue)||void 0===e?void 0:e.call(null)},onSuccess:function(){ce(void 0)}},tests:[{onFailure:function(){ce({children:(0,r.jsxs)(r.Fragment,{children:["Domain name can only contain lowercase alphanumeric, hyphen (",(0,r.jsx)(A.Q0,{text:"-"}),"), and dot (",(0,r.jsx)(A.Q0,{text:"."}),") characters."]})})},test:function(e){var n=e.compare,t=e.value;return n[0]||g.FZ.test(t)}},{test:C.HJ}]}),N(e,T,{defaults:{compare:[!W],getValue:function(){var e;return null===(e=oe.current.getValue)||void 0===e?void 0:e.call(null)},onSuccess:function(){se(void 0)}},tests:[{onFailure:function(){se({children:(0,r.jsxs)(r.Fragment,{children:["Host name can only contain lowercase alphanumeric, hyphen (",(0,r.jsx)(A.Q0,{text:"-"}),"), and dot (",(0,r.jsx)(A.Q0,{text:"."}),") characters."]})})},test:function(e){var n=e.compare,t=e.value;return n[0]||g.FZ.test(t)}},{test:C.HJ}]}),N(e,z,{defaults:{getValue:function(){var e;return null===(e=ie.current.getValue)||void 0===e?void 0:e.call(null)},onSuccess:function(){ae(void 0)}},tests:[{onFailure:function(){ae({children:"Striker number can only contain digits."})},test:function(e){var n=e.value;return/^\d+$/.test(n)}},{test:C.HJ}]}),N(e,B,{defaults:{getValue:function(){var e;return null===(e=ne.current.getValue)||void 0===e?void 0:e.call(null)}},tests:[{test:C.HJ}]}),N(e,D,{defaults:{getValue:function(){var e;return null===(e=te.current.getValue)||void 0===e?void 0:e.call(null)},max:5,min:1,onSuccess:function(){ue(void 0)}},tests:[{onFailure:function(e){var n=e.max,t=e.min;ue({children:"Organization prefix must be ".concat(t," to ").concat(n," lowercase alphanumeric characters.")})},test:function(e){var n=e.max,t=e.min,r=e.value;return RegExp("^[a-z0-9]{".concat(t,",").concat(n,"}$")).test(r)}}]}),e}),[W,de,fe,ce,se,ae,ue]),pe=(0,a.useMemo)((function(){return(0,C.LT)(ve)}),[ve]),me=(0,a.useCallback)((function(){var e=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},n=e.excludeTestIds,t=void 0===n?[]:n,r=e.inputs,i=e.isContinueOnFailure,o=e.isExcludeConfirmAdminPassword,l=void 0===o?!Q:o;l&&t.push(F),null===v||void 0===v||v.call(null,pe({excludeTestIds:t,inputs:r,isContinueOnFailure:i,isIgnoreOnCallbacks:!0,isTestAll:!0}))}),[Q,pe,v]),he=(0,a.useCallback)((function(){var e,n=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},r=n.organizationName,i=void 0===r?null===(t=ne.current.getValue)||void 0===t?void 0:t.call(null):r,o=L(i);return null===(e=te.current.setValue)||void 0===e||e.call(null,o),me({inputs:N({},D,{isIgnoreOnCallbacks:!1,value:o}),isContinueOnFailure:!0}),o}),[me]),ge=(0,a.useCallback)((function(){var e,n=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},t=n.organizationPrefix,r=void 0===t?null===(i=te.current.getValue)||void 0===i?void 0:i.call(null):t,l=n.hostNumber,a=void 0===l?null===(o=ie.current.getValue)||void 0===o?void 0:o.call(null):l,c=n.domainName,s=void 0===c?null===(u=re.current.getValue)||void 0===u?void 0:u.call(null):c,d=q({organizationPrefix:r,hostNumber:a,domainName:s});return null===(e=oe.current.setValue)||void 0===e||e.call(null,d),me({inputs:N({},T,{isIgnoreOnCallbacks:!1,value:d}),isContinueOnFailure:!0}),d}),[me]),be=(0,a.useCallback)((function(){var e;return Boolean(null===(e=ne.current.getValue)||void 0===e?void 0:e.call(null))}),[]),ye=(0,a.useCallback)((function(){var e,n,t;return[null===(e=te.current.getValue)||void 0===e?void 0:e.call(null),null===(n=ie.current.getValue)||void 0===n?void 0:n.call(null),null===(t=re.current.getValue)||void 0===t?void 0:t.call(null)].every((function(e){return Boolean(e)}))}),[]),xe=(0,a.useCallback)((function(){var e;(null===(e=te.current.getIsChangedByUser)||void 0===e?void 0:e.call(null))?I(be()):he()}),[be,he]),je=(0,a.useCallback)((function(){var e;(null===(e=oe.current.getIsChangedByUser)||void 0===e?void 0:e.call(null))?U(ye()):ge()}),[ye,ge]),we=(0,a.useCallback)((function(){var e,n=he();(null===(e=oe.current.getIsChangedByUser)||void 0===e?void 0:e.call(null))||ge({organizationPrefix:n})}),[ge,he]),Pe=(0,a.useCallback)((function(){ge()}),[ge]),Oe=(0,a.useCallback)((function(e){return function(n){return n===e?void 0:e}}),[]),Se=(0,a.useMemo)((function(){return(0,r.jsx)(m.Z,{checked:W,onChange:function(e,n){var t;K(n),me({inputs:(t={},N(t,E,{compare:[!n],isIgnoreOnCallbacks:!1}),N(t,T,{compare:[!n],isIgnoreOnCallbacks:!1}),t),isContinueOnFailure:!0})},sx:{padding:".2em"}})}),[W,me]);return(0,a.useEffect)((function(){if([s,d,X.current,re.current,oe.current,ie.current,ne.current,te.current].every((function(e){return Boolean(e)}))){var e,n,t,r,i;X.current=!1;var o=d.domain,l=d.hostName,u=d.organization,a=d.prefix,c=d.sequence;null===(e=re.current.setValue)||void 0===e||e.call(null,o),null===(n=oe.current.setValue)||void 0===n||n.call(null,l),null===(t=ie.current.setValue)||void 0===t||t.call(null,c),null===(r=ne.current.setValue)||void 0===r||r.call(null,u),null===(i=te.current.setValue)||void 0===i||i.call(null,a),me()}}),[s,d,me]),(0,a.useImperativeHandle)(n,(function(){return{get:function(){var e,n,t,r,i,o;return{adminPassword:null===(e=Y.current.getValue)||void 0===e?void 0:e.call(null),organizationName:null===(n=ne.current.getValue)||void 0===n?void 0:n.call(null),organizationPrefix:null===(t=te.current.getValue)||void 0===t?void 0:t.call(null),domainName:null===(r=re.current.getValue)||void 0===r?void 0:r.call(null),hostNumber:null===(i=ie.current.getValue)||void 0===i?void 0:i.call(null),hostName:null===(o=oe.current.getValue)||void 0===o?void 0:o.call(null)}}}})),(0,r.jsxs)(p.Z,{children:[(0,r.jsxs)(l.ZP,{columns:{xs:1,sm:2,md:3},container:!0,spacing:"1em",children:[(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsxs)(p.Z,{children:[(0,r.jsx)(b.Z,{input:(0,r.jsx)(j.Z,{id:"striker-init-general-organization-name",inputProps:{onBlur:xe},inputLabelProps:{isNotifyRequired:!0},label:"Organization name",onChange:function(){me()},onHelp:function(){O(Oe("Name of the organization that maintains this Anvil! system. You can enter anything that makes sense to you."))}}),ref:ne}),(0,r.jsxs)(p.Z,{row:!0,sx:{"& > :first-child":{flexGrow:1}},children:[(0,r.jsx)(b.Z,{input:(0,r.jsx)(j.Z,{id:"striker-init-general-organization-prefix",inputProps:{endAdornment:(0,r.jsx)(Z,{show:k,onClick:we}),inputProps:{maxLength:5,sx:{minWidth:"2.5em"}},onBlur:function(e){for(var n=arguments.length,t=new Array(n>1?n-1:0),r=1;r<n;r++)t[r-1]=arguments[r];var i=e.target.value;pe({inputs:N({},D,{value:i})}),je.apply(void 0,[e].concat(H(t)))}},inputLabelProps:{isNotifyRequired:!0},label:"Prefix",onChange:function(e){var n=e.target.value;me({inputs:N({},D,{value:n})}),ue(),I(be())},onHelp:function(){O(Oe("Alphanumberic short-form of the organization name. It's used as the prefix for host names."))}}),ref:te}),(0,r.jsx)(b.Z,{input:(0,r.jsx)(j.Z,{id:"striker-init-general-host-number",inputProps:{inputProps:{maxLength:2,sx:{minWidth:"2em"}},onBlur:function(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];var r,i=V(n,1),o=i[0],l=o.target.value;pe({inputs:N({},z,{value:l})}),je.apply(void 0,H(n)),null===f||void 0===f||(r=f).call.apply(r,[null].concat(H(n)))}},inputLabelProps:{isNotifyRequired:!0},label:"Striker #",onChange:function(e){var n=e.target.value;me({inputs:N({},z,{value:n})}),ae()},onHelp:function(){O(Oe("Number or count of this striker; this should be '1' for the first striker, '2' for the second striker, and such."))}}),ref:ie,valueType:"number"})]})]})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsxs)(p.Z,{children:[(0,r.jsx)(b.Z,{input:(0,r.jsx)(j.Z,{id:"striker-init-general-domain-name",inputProps:{onBlur:function(e){for(var n=arguments.length,t=new Array(n>1?n-1:0),r=1;r<n;r++)t[r-1]=arguments[r];var i=e.target.value;pe({inputs:N({},E,{value:i})}),je.apply(void 0,[e].concat(H(t)))}},inputLabelProps:{isNotifyRequired:!0},label:"Domain name",onChange:function(e){var n=e.target.value;me({inputs:N({},E,{value:n})}),ce()},onHelp:function(){O(Oe("Domain name for this striker. It's also the default domain used when creating new install manifests."))}}),ref:re}),(0,r.jsx)(b.Z,{input:(0,r.jsx)(j.Z,{id:"striker-init-general-host-name",inputProps:{endAdornment:(0,r.jsx)(Z,{show:_,onClick:Pe}),onBlur:function(e){var n=e.target.value;pe({inputs:N({},T,{value:n})})}},inputLabelProps:{isNotifyRequired:!0},label:"Host name",onChange:function(e){var n=e.target.value;me({inputs:N({},T,{value:n})}),se(),U(ye())},onHelp:function(){O(Oe("Host name for this striker. It's usually a good idea to use the auto-generated value."))}}),ref:oe})]})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,sm:2,md:1,children:(0,r.jsxs)(l.ZP,{columns:{xs:1,sm:2,md:1},container:!0,spacing:"1em",sx:{"& > * > *":{width:"100%"}},children:[(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(b.Z,{input:(0,r.jsx)(j.Z,{id:"striker-init-general-admin-password",inputProps:{inputProps:{type:h.Z.password},onBlur:function(e){var n=e.target.value;pe({inputs:N({},R,{value:n})})},onPasswordVisibilityAppend:function(e){var n=e===h.Z.password;me({isExcludeConfirmAdminPassword:!n}),J(n),fe()}},inputLabelProps:{isNotifyRequired:!0},label:"Admin password",onChange:function(e){var n=e.target.value;me({inputs:N({},R,{value:n})}),de()},onHelp:function(){O(Oe("Password use to login to this Striker and connect to its database. Don't provide an used password here because it'll be stored as plaintext."))}}),ref:Y})}),Q&&(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(b.Z,{input:(0,r.jsx)(j.Z,{id:"striker-init-general-confirm-admin-password",inputProps:{inputProps:{type:h.Z.password},onBlur:function(e){var n=e.target.value;pe({inputs:N({},F,{value:n})})}},inputLabelProps:{isNotifyRequired:Q},label:"Confirm password",onChange:function(e){var n=e.target.value;me({inputs:N({},F,{value:n})}),fe()}}),ref:ee})})]})})]}),(0,r.jsx)(x.Z,{count:1,defaultMessageType:"warning",ref:le}),(0,r.jsx)(y.Z,{children:(0,r.jsxs)(p.Z,{row:!0,sx:{"& > :last-child":{flexGrow:1}},children:[Se,(0,r.jsx)(A.Ac,{inverted:!0,children:W?"Uncheck to skip domain and host name pattern validation.":"Check to re-enable domain and host name pattern validation."})]})}),P&&(0,r.jsx)(y.Z,{onClose:function(){O(void 0)},children:P})]})}));U.defaultProps={expectHostDetail:!1,hostDetail:void 0,onHostNumberBlurAppend:void 0,toggleSubmitDisabled:void 0},U.displayName="GeneralInitForm";var $=U,Q=t(1770),J=t(7971),G=t(3377),W=t(2444),K=t(5741),X=t(4596),Y=t(3679),ee=t(634),ne=t(2152),te=t(2749);function re(e,n){(null==n||n>e.length)&&(n=e.length);for(var t=0,r=new Array(n);t<n;t++)r[t]=e[t];return r}function ie(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function oe(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{},r=Object.keys(t);"function"===typeof Object.getOwnPropertySymbols&&(r=r.concat(Object.getOwnPropertySymbols(t).filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable})))),r.forEach((function(n){ie(e,n,t[n])}))}return e}function le(e,n){return function(e){if(Array.isArray(e))return e}(e)||function(e,n){var t=null==e?null:"undefined"!==typeof Symbol&&e[Symbol.iterator]||e["@@iterator"];if(null!=t){var r,i,o=[],l=!0,u=!1;try{for(t=t.call(e);!(l=(r=t.next()).done)&&(o.push(r.value),!n||o.length!==n);l=!0);}catch(a){u=!0,i=a}finally{try{l||null==t.return||t.return()}finally{if(u)throw i}}return o}}(e,n)||function(e,n){if(!e)return;if("string"===typeof e)return re(e,n);var t=Object.prototype.toString.call(e).slice(8,-1);"Object"===t&&e.constructor&&(t=e.constructor.name);if("Map"===t||"Set"===t)return Array.from(t);if("Arguments"===t||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(t))return re(e,n)}(e,n)||function(){throw new TypeError("Invalid attempt to destructure non-iterable instance.\\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}()}var ue=function(){var e,n=(0,u.useRouter)(),t=n.isReady,i=n.query.re,m=(0,a.useState)(),h=m[0],g=m[1],b=(0,a.useState)(),x=b[0],j=b[1],w=(0,a.useState)(!1),P=w[0],O=w[1],S=(0,a.useState)(!0),k=S[0],Z=S[1],C=(0,a.useState)(!1),I=C[0],N=C[1],V=(0,a.useState)(!1),H=V[0],M=V[1],R=(0,a.useState)(!1),F=R[0],E=R[1],T=(0,a.useState)(),z=T[0],B=T[1],D=le((0,te.Z)(void 0),2),_=D[0],L=D[1],q=(0,a.useRef)(!0),U=(0,a.useRef)({}),re=(0,a.useRef)({}),ie=(0,a.useRef)({}),ue=(0,a.useRef)({}),ae=(0,a.useMemo)((function(){return Boolean(i)}),[i]),ce=(0,a.useMemo)((function(){return F?(0,r.jsx)(ne.Z,{}):(0,r.jsx)(p.Z,{row:!0,sx:{flexDirection:"row-reverse"},children:(0,r.jsx)(v.Z,{disabled:k,onClick:function(){var e,n,t,r;j(oe({},null!==(t=null===(e=U.current.get)||void 0===e?void 0:e.call(null))&&void 0!==t?t:{},null!==(r=null===(n=re.current.get)||void 0===n?void 0:n.call(null))&&void 0!==r?r:{networks:[]})),O(!0)},children:"Initialize"})})}),[k,F]),se=(0,a.useMemo)((function(){var e,n="Loading...";t&&(n=ae?"Reconfigure ".concat(null!==(e=null===_||void 0===_?void 0:_.shortHostName)&&void 0!==e?e:"striker"):"Initialize striker");return n}),[null===_||void 0===_?void 0:_.shortHostName,t,ae]),de=(0,a.useCallback)((function(){for(var e=arguments.length,n=new Array(e),t=0;t<e;t++)n[t]=arguments[t];Z(!n.every((function(e){return e})))}),[]);return(0,a.useEffect)((function(){t&&ae&&q.current&&(q.current=!1,d.Z.get("/host/local").then((function(e){var n=e.data;L(n)})).catch((function(e){var n=(0,Q.Z)(e);n.children=(0,r.jsxs)(r.Fragment,{children:["Failed to get host detail data. ",n.children]}),g(n)})))}),[t,ae,L]),(0,r.jsxs)(r.Fragment,{children:[(0,r.jsxs)(Y.s_,{children:[(0,r.jsxs)(Y.V9,{children:[(0,r.jsx)(A.z,{children:se}),(0,r.jsx)(J.Z,{onClick:function(e){var n,t,r=e.currentTarget;null===(n=ue.current.setAnchor)||void 0===n||n.call(null,r),null===(t=ue.current.setOpen)||void 0===t||t.call(null,!0)},variant:"normal",children:(0,r.jsx)(G.Z,{icon:o.Z,ref:ie})})]}),(0,r.jsxs)(p.Z,{children:[(0,r.jsx)($,{expectHostDetail:ae,hostDetail:_,onHostNumberBlurAppend:function(e){var n=e.target.value;B(n)},ref:U,toggleSubmitDisabled:function(e){e!==I&&(N(e),de(e,H))}}),(0,r.jsx)(X.Z,{expectHostDetail:ae,hostDetail:_,hostSequence:z,ref:re,toggleSubmitDisabled:function(e){e!==H&&(M(e),de(I,e))}}),h&&(0,r.jsx)(y.Z,oe({},h,{onClose:function(){return g(void 0)}})),ce]})]}),(0,r.jsx)(f.Z,{actionProceedText:"Initialize",content:(0,r.jsxs)(l.ZP,{container:!0,spacing:".6em",columns:{xs:2},children:[(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Organization name"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x?void 0:x.organizationName})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Organization prefix"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x?void 0:x.organizationPrefix})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Striker number"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x?void 0:x.hostNumber})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Domain name"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x?void 0:x.domainName})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Host name"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x?void 0:x.hostName})}),(0,r.jsx)(l.ZP,{item:!0,sx:{marginTop:"1.4em"},xs:2,children:(0,r.jsx)(A.Ac,{children:"Networks"})}),null===x||void 0===x?void 0:x.networks.map((function(e){var n=e.inputUUID,t=e.interfaces,i=e.ipAddress,o=e.name,u=e.subnetMask,a=e.type,c=e.typeCount;return(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsxs)(l.ZP,{container:!0,spacing:".6em",columns:{xs:2},children:[(0,r.jsx)(l.ZP,{item:!0,xs:2,children:(0,r.jsxs)(A.Ac,{children:[o," (",(0,r.jsx)(A.Q0,{children:"".concat(a.toUpperCase()).concat(c)}),")"]})}),t.map((function(e,t){var i="network-confirm-".concat(n,"-interface").concat(t),o="none";if(e){var u=e.networkInterfaceName,a=e.networkInterfaceUUID;i="".concat(i,"-").concat(a),o=u}return(0,r.jsxs)(l.ZP,{container:!0,item:!0,children:[(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Link ".concat(t+1)})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:o})})]},i)})),(0,r.jsx)(l.ZP,{item:!0,xs:2,children:(0,r.jsx)(A.$_,{children:"".concat(i,"/").concat(u)})})]})},"network-confirm-".concat(n))})),(0,r.jsx)(l.ZP,{item:!0,sx:{marginBottom:"1.4em"},xs:2}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Gateway"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x?void 0:x.gateway})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Gateway network"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x||null===(e=x.gatewayInterface)||void 0===e?void 0:e.toUpperCase()})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.Ac,{children:"Domain name server(s)"})}),(0,r.jsx)(l.ZP,{item:!0,xs:1,children:(0,r.jsx)(A.$_,{children:null===x||void 0===x?void 0:x.dns})})]}),dialogProps:{open:P},onCancelAppend:function(){O(!1)},onProceedAppend:function(){g(void 0),E(!0),O(!1),d.Z.put("/init",x).then((function(){(0,ee.Z)(0),E(!1),g({children:ae?(0,r.jsx)(r.Fragment,{children:"Successfully initiated reconfiguration."}):(0,r.jsxs)(r.Fragment,{children:["Successfully registered the configuration job! You can check the progress at the top right icon. Once the job completes, you can access the"," ",(0,r.jsx)(K.Z,{href:"/login",sx:{color:s.E5,display:"inline-flex"},children:"login page"}),"."]}),type:"info"})})).catch((function(e){var n=(0,Q.Z)(e);g(n),E(!1)}))},titleText:"Confirm striker initialization"}),(0,r.jsx)(W.Z,{getJobUrl:function(e){return"".concat(c.Z,"/init/job?start=").concat(e)},onFetchSuccessAppend:function(e){var n;null===(n=ie.current.indicate)||void 0===n||n.call(null,Object.keys(e).length>0)},ref:ue})]})},ae=function(){return(0,r.jsx)(i.Z,{sx:{display:"flex",flexDirection:"column"},children:(0,r.jsx)(ue,{})})}}},function(e){e.O(0,[662,498,910,839,213,209,644,404,668,284,157,27,86,774,888,179],(function(){return n=593,e(e.s=n);var n}));var n=e.O();_N_E=n}]);