(()=>{"use strict";
const API=(window.SHUTTLE_CONFIG?.API_BASE_URL||"").replace(/\/$/,"");
const $=s=>document.querySelector(s);
const state={token:sessionStorage.getItem("driver_trip_token")||"",jobs:[],watchId:null,pollTimer:null,gpsStarting:false};
const STATUS={confirmed:"Reservación confirmada",assigned:"Unidad asignada",driver_on_way:"Conductor en camino",driver_arrived:"Conductor llegó",passenger_onboard:"Pasajero abordó",in_transit:"En trayecto",completed:"Servicio completado",incident:"Incidencia reportada",cancelled:"Servicio cancelado"};
const NEXT={confirmed:["assigned","cancelled"],assigned:["driver_on_way","cancelled","confirmed"],driver_on_way:["driver_arrived","incident"],driver_arrived:["passenger_onboard","incident"],passenger_onboard:["in_transit","incident"],in_transit:["completed","incident"],incident:["driver_on_way","driver_arrived","passenger_onboard","in_transit","completed"]};
const esc=v=>String(v??"").replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
async function api(path,opts={}){const res=await fetch(API+path,{...opts,headers:{"Content-Type":"application/json",...(state.token?{Authorization:"Bearer "+state.token}:{}),...(opts.headers||{})}});const data=await res.json().catch(()=>({detail:"Respuesta no válida del servidor"}));if(!res.ok)throw Error(data.detail||"Error de API ("+res.status+")");return data}
function msg(id,text,error=false){const el=$(id);if(!el)return;el.textContent=text;el.className="message"+(error?" error":"")}
function show(){$("#login").classList.toggle("hidden",!!state.token);$("#workspace").classList.toggle("hidden",!state.token)}
function render(){$("#jobs").innerHTML=state.jobs.length?state.jobs.map(t=>'<article class="job"><p class="eyebrow">'+esc(t.folio)+' · VUELO '+esc(t.flight_number)+'</p><h3>'+esc(t.destination)+'</h3><p><b>'+esc(t.passenger_name)+'</b> · '+Number(t.passengers)+' pasajero(s)<br>Recogida: '+esc(t.pickup)+'<br>Hora: '+esc(t.scheduled_at)+'</p><span class="pill">'+esc(STATUS[t.status]||t.status)+'</span><div class="field"><label>ACTUALIZAR ESTADO<select id="status-'+t.id+'">'+Object.entries(STATUS).filter(([k])=>k===t.status||(NEXT[t.status]||[]).includes(k)).map(([k,v])=>'<option value="'+k+'" '+(k===t.status?"selected":"")+'>'+esc(v)+'</option>').join("")+'</select></label></div><div class="field"><label>ETA EN MINUTOS<input id="eta-'+t.id+'" type="number" min="0" max="600" value="'+(t.eta_minutes??"")+'"></label></div><div class="actions"><button class="button primary" data-save="'+t.id+'">Guardar actualización</button></div></article>').join(""):'<article class="job"><h3>No tienes servicios activos</h3><p>Cuando operaciones te asigne un traslado, aparecerá aquí. La ubicación se compartirá automáticamente cuando haya un servicio asignado.</p></article>'}
function stopGps(){if(state.watchId!==null&&navigator.geolocation)navigator.geolocation.clearWatch(state.watchId);state.watchId=null;state.gpsStarting=false}
function startGps(){
 if(!state.token||!state.jobs.length||state.watchId!==null||state.gpsStarting)return;
 if(!navigator.geolocation){msg("#gps-message","Este dispositivo no permite geolocalización.",true);return}
 if(!window.isSecureContext){msg("#gps-message","El GPS requiere una conexión HTTPS segura.",true);return}
 state.gpsStarting=true;
 msg("#gps-message","Solicitando autorización de ubicación. Autorízala para compartir automáticamente la ubicación con tus servicios asignados.");
 try{
  state.watchId=navigator.geolocation.watchPosition(async pos=>{
   try{const result=await api("/api/driver/location",{method:"POST",body:JSON.stringify({latitude:pos.coords.latitude,longitude:pos.coords.longitude,accuracy:pos.coords.accuracy})});msg("#gps-message","Ubicación compartida automáticamente con "+result.updated_services+" servicio(s) · "+new Date().toLocaleTimeString())}
   catch(err){msg("#gps-message",err.message,true)}
  },err=>{
   state.gpsStarting=false;
   const messages={1:"Permiso de ubicación denegado. Actívalo en los ajustes del dispositivo para compartir tu ubicación.",2:"No se pudo obtener la ubicación. Comprueba el GPS y la señal.",3:"La solicitud de ubicación agotó el tiempo. Se volverá a intentar al reabrir Driver Trip."};
   msg("#gps-message",messages[err.code]||err.message,true);
   if(state.watchId!==null){navigator.geolocation.clearWatch(state.watchId);state.watchId=null}
  },{enableHighAccuracy:true,maximumAge:10000,timeout:20000});
  state.gpsStarting=false;
 }catch(err){state.gpsStarting=false;msg("#gps-message","No fue posible iniciar la ubicación: "+err.message,true)}
}
async function load(){state.jobs=await api("/api/driver/trips");render();if(state.jobs.length)startGps();else stopGps()}
function live(){if(state.pollTimer)clearInterval(state.pollTimer);state.pollTimer=setInterval(()=>{if(state.token)load().catch(err=>console.warn("API refresh:",err))},15000);$("#connection").textContent="Actualización automática activa"}
async function login(e){e.preventDefault();const d=Object.fromEntries(new FormData(e.target));try{const res=await api("/api/driver/login",{method:"POST",body:JSON.stringify(d)});state.token=res.access_token;sessionStorage.setItem("driver_trip_token",state.token);show();await load();live()}catch(err){msg("#login-message",err.message,true)}}
$("#login-form").addEventListener("submit",login);
$("#logout").addEventListener("click",async()=>{try{await api("/api/driver/logout",{method:"POST"})}catch{}stopGps();if(state.pollTimer)clearInterval(state.pollTimer);state.token="";sessionStorage.removeItem("driver_trip_token");show();$("#connection").textContent="Desconectado";msg("#gps-message","Sesión cerrada. El uso de ubicación se ha detenido.")});
$("#jobs").addEventListener("click",async e=>{const id=e.target.dataset.save;if(!id)return;try{await api("/api/trips/"+id+"/status",{method:"PATCH",body:JSON.stringify({status:$("#status-"+id).value,eta_minutes:$("#eta-"+id).value===""?null:Number($("#eta-"+id).value)})});msg("#gps-message","Estado del servicio actualizado.");await load()}catch(err){msg("#gps-message",err.message,true)}});
document.addEventListener("visibilitychange",()=>{if(document.visibilityState==="visible"&&state.token){if(state.watchId===null)startGps();load().catch(()=>{})}});
window.addEventListener("pageshow",()=>{if(state.token&&state.watchId===null)startGps()});
show();
if(state.token){load().then(live).catch(e=>{state.token="";sessionStorage.removeItem("driver_trip_token");show();msg("#login-message",e.message,true)})}
})();