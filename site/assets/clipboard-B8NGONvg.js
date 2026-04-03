import{h as c}from"./index-CjZGWwHJ.js";/**
 * @license lucide-react v0.487.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */const r=[["rect",{width:"14",height:"14",x:"8",y:"8",rx:"2",ry:"2",key:"17jyea"}],["path",{d:"M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2",key:"zix9uf"}]],n=c("copy",r);async function i(t){if(navigator.clipboard&&window.isSecureContext)try{return await navigator.clipboard.writeText(t),!0}catch{console.warn("Clipboard API failed, using fallback method")}try{const e=document.createElement("textarea");e.value=t,e.style.position="fixed",e.style.left="-999999px",e.style.top="-999999px",e.style.opacity="0",document.body.appendChild(e),e.focus(),e.select();const o=document.execCommand("copy");return document.body.removeChild(e),o}catch(e){return console.error("Failed to copy text:",e),!1}}export{n as C,i as c};
