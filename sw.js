var V='peta-v1',SHELL=['./','index.html','manifest.webmanifest','icon-192.png'];
self.addEventListener('install',function(e){e.waitUntil(caches.open(V).then(function(c){return c.addAll(SHELL)}).then(function(){return self.skipWaiting()}))});
self.addEventListener('activate',function(e){e.waitUntil(caches.keys().then(function(k){return Promise.all(k.filter(function(x){return x!==V}).map(function(x){return caches.delete(x)}))}).then(function(){return self.clients.claim()}))});
self.addEventListener('fetch',function(e){var r=e.request;if(r.method!=='GET')return;var u=new URL(r.url);
 if(!(u.origin===location.origin||u.hostname==='cdnjs.cloudflare.com'||u.hostname==='cdn.jsdelivr.net'))return;
 e.respondWith(fetch(r).then(function(res){if(res.ok||res.type==='opaque'){var cp=res.clone();caches.open(V).then(function(c){c.put(r,cp)})}return res})
  .catch(function(){return caches.match(r).then(function(m){return m||caches.match('index.html')})}))});
