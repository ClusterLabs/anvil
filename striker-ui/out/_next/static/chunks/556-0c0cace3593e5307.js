"use strict";(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[556],{92917:function(e,t,n){n.d(t,{Z:function(){return h}});var l=n(23279),u=n.n(l),r=n(67294),s=n(591),lib_createInputOnChangeHandler=function(){let{postSet:e,preSet:t,set:n,setType:l="string",valueKey:u="value"}=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};return r=>{let{target:{[u]:a}}=r,i=s.Z[l](a);null==t||t.call(null,r),null==n||n.call(null,i),null==e||e.call(null,r)}},a=n(50233);let i="input",o={boolean:!1,number:0,string:""},c={createInputOnChangeHandlerOptions:{},debounceWait:500,required:!1,valueType:"string"},d=(0,r.forwardRef)((e,t)=>{let{debounceWait:n=c.debounceWait,input:l,inputTestBatch:s,onBlurAppend:d,onFirstRender:h,onFocusAppend:g,onUnmount:p,required:f=c.required,valueKey:b,valueType:v=c.valueType,createInputOnChangeHandlerOptions:{postSet:_,valueKey:m=b,...y}=c.createInputOnChangeHandlerOptions}=e,{props:x}=l,k=(0,r.useMemo)(()=>null!=m?m:"checked"in x?"checked":"value",[x,m]),{onBlur:I,onChange:C,onFocus:S,[k]:T=o[v],...j}=x,[O,F]=(0,r.useState)(T),[B,N]=(0,r.useState)(!1),[E,M]=(0,r.useState)(!1),P=(0,r.useCallback)(e=>{F(e)},[]),A=(0,r.useMemo)(()=>{let e;return s&&(s.isRequired=f,e=(0,a.LT)({[i]:s})),e},[s,f]),R=(0,r.useCallback)(e=>{var t;let n=null!==(t=null==A?void 0:A.call(null,{inputs:{[i]:{value:e}},isIgnoreOnCallbacks:!0}))&&void 0!==t&&t;null==h||h.call(null,{isValid:n}),M(n)},[h,A]),w=(0,r.useMemo)(()=>u()(R,n),[n,R]),q=(0,r.useMemo)(()=>null!=I?I:A&&function(){for(var e=arguments.length,t=Array(e),n=0;n<e;n++)t[n]=arguments[n];let{0:{target:{value:l}}}=t,u=A({inputs:{[i]:{value:l}}});M(u),null==d||d.call(null,...t)},[I,d,A]),H=(0,r.useMemo)(()=>lib_createInputOnChangeHandler({postSet:function(){for(var e=arguments.length,t=Array(e),n=0;n<e;n++)t[n]=arguments[n];N(!0),null==C||C.call(null,...t),null==_||_.call(null,...t)},set:e=>{P(e),w(e)},setType:v,valueKey:k,...y}),[w,C,_,y,P,k,v]),Q=(0,r.useMemo)(()=>null!=S?S:s&&function(){for(var e,t,n=arguments.length,l=Array(n),u=0;u<n;u++)l[u]=arguments[u];null===(t=s.defaults)||void 0===t||null===(e=t.onSuccess)||void 0===e||e.call(null,{append:{}}),null==g||g.call(null,...l)},[S,s,g]);return(0,r.useEffect)(()=>(R(O),p),[]),(0,r.useEffect)(()=>{!B&&O!==T&&T&&(R(T),F(T))},[R,T,O,B]),(0,r.useImperativeHandle)(t,()=>({getIsChangedByUser:()=>B,getValue:()=>O,isValid:()=>E,setValue:P}),[O,B,E,P]),(0,r.cloneElement)(l,{...j,onBlur:q,onChange:H,onFocus:Q,required:f,[k]:O})});d.defaultProps=c,d.displayName="InputWithRef";var h=d},21642:function(e,t,n){var l=n(85893),u=n(67294),r=n(68917);let s={count:0,defaultMessageType:"info",messages:void 0,onSet:void 0,usePlaceholder:!0},a=(0,u.forwardRef)((e,t)=>{let{count:n=s.count,defaultMessageType:a=s.defaultMessageType,messages:i,onSet:o,usePlaceholder:c=s.usePlaceholder}=e,[d,h]=(0,u.useState)({}),g=(0,u.useMemo)(()=>({...i,...d}),[i,d]),p=(0,u.useCallback)(e=>void 0!==g[e],[g]),f=(0,u.useCallback)((e,t)=>{let n=0;h(l=>{let{[e]:u,...r}=l;return t&&(r[e]=t),n=Object.keys(r).length,r}),null==o||o.call(null,n)},[o]),b=(0,u.useCallback)((e,t)=>{let n=0,l=t?(e,l)=>{e[l]=t,n+=1}:void 0;h(t=>{let u={};return Object.keys(t).forEach(r=>{e.test(r)?null==l||l.call(null,u,r):(u[r]=t[r],n+=1)}),u}),null==o||o.call(null,n)},[o]),v=(0,u.useMemo)(()=>{let e=Object.entries(g),t=n>0,u=t?n:e.length,s=[];if(e.every(e=>{let[t,n]=e,{children:i,type:o=a}=n;return s.push((0,l.jsx)(r.Z,{type:o,children:i},"message-".concat(t))),s.length<u}),c&&t&&0===s.length){let e=n-s.length;for(let t=0;t<e;t+=1)s.push((0,l.jsx)(r.Z,{sx:{visibility:"hidden"},text:"Placeholder"},"message-placeholder-".concat(t)))}return s},[n,a,c,g]);return(0,u.useImperativeHandle)(t,()=>({exists:p,setMessage:f,setMessageRe:b}),[p,f,b]),(0,l.jsx)(l.Fragment,{children:v})});a.defaultProps=s,a.displayName="MessageGroup",t.Z=a},591:function(e,t){t.Z={boolean:e=>!!e,number:e=>parseInt(String(e),10)||0,string:e=>String(e)}},65939:function(e,t,n){n.d(t,{FZ:function(){return o},OU:function(){return h},ah:function(){return d},tf:function(){return c}});let l="[a-z0-9]",u="[a-z0-9-]",r="[0-9a-f]",s="(?:25[0-5]|(?:2[0-4]|1[0-9]|[1-9]|)[0-9])",a="(?:".concat(s,"[.]){3}").concat(s),i="".concat(r,"{8}-(?:").concat(r,"{4}-){3}").concat(r,"{12}"),o=new RegExp("^(?:".concat(l,"(?:").concat(u,"{0,61}").concat(l,")?[.])+").concat(l).concat(u,"{0,61}").concat(l,"$")),c=new RegExp("^".concat(a,"$")),d=new RegExp("^(?:".concat(a,"\\s*,\\s*)*").concat(a,"$")),h=/^[^'"/\\><}{]*$/;RegExp("^".concat(i,"$"),"i")},50233:function(e,t,n){n.d(t,{_:function(){return test_input_buildIPAddressTestBatch},dg:function(){return test_input_buildIpCsvTestBatch},qY:function(){return test_input_buildNumberTestBatch},Gn:function(){return test_input_buildPeacefulStringTestBatch},LT:function(){return test_input_createTestInputFunction},BD:function(){return test_input_testInput},X7:function(){return test_input_testMax},HJ:function(){return test_input_testNotBlank},SQ:function(){return test_input_testRange}});var l=n(85893),u=n(65939),r=n(84154),test_input_testNotBlank=e=>{let{value:t}=e;return!!t&&String(t).length>0},test_input_buildIPAddressTestBatch=function(e,t){let{isRequired:n,onFinishBatch:r,...s}=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},a=arguments.length>3?arguments[3]:void 0;return{defaults:{...s,onSuccess:t},isRequired:n,onFinishBatch:r,tests:[{test:test_input_testNotBlank},{onFailure:function(){for(var t=arguments.length,n=Array(t),u=0;u<t;u++)n[u]=arguments[u];a((0,l.jsxs)(l.Fragment,{children:[e," should be a valid IPv4 address."]}),...n)},test:e=>{let{value:t}=e;return u.tf.test(t)}}]}},test_input_buildIpCsvTestBatch=function(e,t){let{isRequired:n,onFinishBatch:r,...s}=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},a=arguments.length>3?arguments[3]:void 0;return{defaults:{...s,onSuccess:t},isRequired:n,onFinishBatch:r,tests:[{test:test_input_testNotBlank},{onFailure:function(){for(var t=arguments.length,n=Array(t),u=0;u<t;u++)n[u]=arguments[u];a((0,l.jsxs)(l.Fragment,{children:[e," must be one or more valid IPv4 addresses separated by comma(s); without trailing comma."]}),...n)},test:e=>{let{value:t}=e;return u.ah.test(t)}}]}},test_input_testRange=e=>{let{max:t,min:n,value:l}=e;return!!l&&l>=n&&l<=t},lib_toNumber=function(e){let t=arguments.length>1&&void 0!==arguments[1]?arguments[1]:"parseInt";return"number"==typeof e?e:Number[t](String(e))},test_input_buildNumberTestBatch=function(e,t){let{isRequired:n,onFinishBatch:u,...r}=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},s=arguments.length>3?arguments[3]:void 0,a=arguments.length>4?arguments[4]:void 0,i=arguments.length>5?arguments[5]:void 0,o=[];return s?o.push({onFailure:function(){for(var t=arguments.length,n=Array(t),u=0;u<t;u++)n[u]=arguments[u];s((0,l.jsxs)(l.Fragment,{children:[e," must be a valid integer."]}),...n)},test:e=>{let{value:t}=e;return Number.isSafeInteger(lib_toNumber(t))}}):a&&o.push({onFailure:function(){for(var t=arguments.length,n=Array(t),u=0;u<t;u++)n[u]=arguments[u];a((0,l.jsxs)(l.Fragment,{children:[e," must be a valid floating-point number."]}),...n)},test:e=>{let{value:t}=e;return Number.isFinite(lib_toNumber(t,"parseFloat"))}}),i&&o.push({onFailure:function(){for(var t=arguments.length,n=Array(t),u=0;u<t;u++)n[u]=arguments[u];let{displayMax:r,displayMin:s}=n[0];i((0,l.jsxs)(l.Fragment,{children:[e," is expected to be between ",s," and ",r,"."]}),...n)},test:test_input_testRange}),{defaults:{...r,onSuccess:t},isRequired:n,onFinishBatch:u,tests:o}},test_input_buildPeacefulStringTestBatch=function(e,t){let{isRequired:n,onFinishBatch:s,...a}=arguments.length>2&&void 0!==arguments[2]?arguments[2]:{},i=arguments.length>3?arguments[3]:void 0;return{defaults:{...a,onSuccess:t},isRequired:n,onFinishBatch:s,tests:[{test:test_input_testNotBlank},{onFailure:function(){for(var t=arguments.length,n=Array(t),u=0;u<t;u++)n[u]=arguments[u];i((0,l.jsxs)(l.Fragment,{children:[e," cannot contain single-quote (",(0,l.jsx)(r.Q0,{inheritColour:!0,text:"'"}),"), double-quote (",(0,l.jsx)(r.Q0,{inheritColour:!0,text:'"'}),"), slash (",(0,l.jsx)(r.Q0,{inheritColour:!0,text:"/"}),"), backslash (",(0,l.jsx)(r.Q0,{inheritColour:!0,text:"\\"}),"), angle brackets (",(0,l.jsx)(r.Q0,{inheritColour:!0,text:"<>"}),"), curly brackets (",(0,l.jsx)(r.Q0,{inheritColour:!0,text:"{}"}),")."]}),...n)},test:e=>{let{value:t}=e;return u.OU.test(t)}}]}};let cbEmptySetter=()=>({}),cbSetter=e=>{let{onFailure:t,onSuccess:n}=e;return{cbFailure:t,cbSuccess:n}},evalIsIgnoreOnCallbacks=e=>{let{isIgnoreOnCallbacks:t,onFinishBatch:n}=e;return t?{setTestCallbacks:cbEmptySetter}:{cbFinishBatch:n,setTestCallbacks:cbSetter}},nullishSet=(e,t)=>null!=e?e:t,orSet=(e,t)=>e||t;var test_input_testInput=function(){let{excludeTestIds:e=[],excludeTestIdsRe:t,inputs:n={},isContinueOnFailure:l,isIgnoreOnCallbacks:u,isTestAll:r=0===Object.keys(n).length,tests:s={}}=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{},a=[...e],i={},o=!0;return r&&Object.keys(s).forEach(e=>{i[e]={}}),i={...i,...n},t&&Object.keys(i).forEach(e=>{t.test(e)&&a.push(e)}),a.forEach(e=>{delete i[e]}),Object.keys(i).every(e=>{let{defaults:{compare:t=[],displayMax:n,displayMin:r,getCompare:a,getValue:c,isIgnoreOnCallbacks:d=u,max:h=0,min:g=0,onSuccess:p,value:f=null}={},isRequired:b=!1,onFinishBatch:v,optionalTests:_,tests:m}=s[e],{getCompare:y=a,getValue:x=c,isIgnoreOnCallbacks:k=d,max:I=h,min:C=g,compare:S=nullishSet(null==y?void 0:y.call(null),t),value:T=nullishSet(null==x?void 0:x.call(null),f),displayMax:j=orSet(n,String(I)),displayMin:O=orSet(r,String(C))}=i[e],{cbFinishBatch:F,setTestCallbacks:B}=evalIsIgnoreOnCallbacks({isIgnoreOnCallbacks:k,onFinishBatch:v});if(!T&&!b)return null==F||F.call(null,!0,e),!0;let runTest=e=>{let{onFailure:t,onSuccess:n=p,test:l}=e,u={},r=l({append:u,compare:S,max:I,min:C,value:T}),{cbFailure:s,cbSuccess:a}=B({onFailure:t,onSuccess:n});return r?null==a||a.call(null,{append:u}):(o=r,null==s||s.call(null,{append:u,compare:S,displayMax:j,displayMin:O,max:I,min:C,value:T})),r};null==_||_.forEach(runTest);let N=m.every(runTest);return null==F||F.call(null,N,e),N||l}),o},test_input_createTestInputFunction=function(e){let{excludeTestIds:t=[],...n}=arguments.length>1&&void 0!==arguments[1]?arguments[1]:{};return function(){let{excludeTestIds:l=[],...u}=arguments.length>0&&void 0!==arguments[0]?arguments[0]:{};return test_input_testInput({tests:e,excludeTestIds:[...t,...l],...n,...u})}},test_input_testMax=e=>{let{max:t,min:n}=e;return t>=n}}}]);