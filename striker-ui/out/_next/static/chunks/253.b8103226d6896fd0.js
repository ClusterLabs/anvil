"use strict";(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[253],{24253:function(e,n,r){r.r(n);var t=r(85893),c=r(94460),u=r(67294);let rfbConnect=e=>{let{background:n="",clipViewport:r=!1,compressionLevel:t=2,dragViewport:u=!1,focusOnClick:l=!1,onConnect:i,onDisconnect:s,qualityLevel:o=6,resizeSession:a=!0,rfb:f,rfbScreen:d,scaleViewport:v=!0,showDotCursor:p=!1,url:E,viewOnly:b=!1}=e;(null==d?void 0:d.current)&&(null==f||!f.current)&&(d.current.innerHTML="",f.current=new c.Z(d.current,E),f.current.background=n,f.current.clipViewport=r,f.current.compressionLevel=t,f.current.dragViewport=u,f.current.focusOnClick=l,f.current.qualityLevel=o,f.current.resizeSession=a,f.current.scaleViewport=v,f.current.showDotCursor=p,f.current.viewOnly=b,i&&f.current.addEventListener("connect",i),s&&f.current.addEventListener("disconnect",s))},rfbDisconnect=e=>{(null==e?void 0:e.current)&&(e.current.disconnect(),e.current=null)},VncDisplay=e=>{let{onConnect:n,onDisconnect:r,rfb:c,rfbConnectArgs:l,rfbScreen:i,url:s}=e;return(0,u.useEffect)(()=>{if(l){let{url:e=s}=l;if(!e)return;let t={onConnect:n,onDisconnect:r,rfb:c,rfbScreen:i,url:e,...l};rfbConnect(t)}else rfbDisconnect(c)},[s,n,r,c,l,i]),(0,u.useEffect)(()=>()=>{rfbDisconnect(c)},[c]),(0,t.jsx)("div",{style:{width:"100%",height:"75vh"},ref:i,onMouseEnter:()=>{document.activeElement&&document.activeElement instanceof HTMLElement&&document.activeElement.blur(),(null==c?void 0:c.current)&&c.current.focus()}})};VncDisplay.displayName="VncDisplay",n.default=VncDisplay}}]);