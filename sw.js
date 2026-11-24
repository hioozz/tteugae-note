// 오프라인에서도 열리도록 앱 파일을 캐시합니다.
// 온라인일 땐 항상 최신 파일을 받아오고(네트워크 우선), 오프라인일 때만 캐시를 씁니다.
const CACHE = 'tteugae-note-v28';
const ASSETS = ['./', './index.html', './styles.css', './app.js', './manifest.webmanifest', './icon.svg', './Pretendard-Regular.woff2', './knit-cat.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)));
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
  );
  self.clients.claim();
});

const PDFJS_PREFIX = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/';

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  // PDF 보기 도구(pdf.js)는 한 번 받으면 캐시에서 꺼내 써요 (버전이 고정이라 바뀌지 않아요)
  if (e.request.url.startsWith(PDFJS_PREFIX)) {
    e.respondWith(
      caches.match(e.request).then((hit) => hit || fetch(e.request).then((res) => {
        if (res.ok) { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(e.request, copy)); }
        return res;
      }))
    );
    return;
  }
  if (new URL(e.request.url).origin !== location.origin) return;
  e.respondWith(
    // cache: 'no-cache' → 브라우저 HTTP 캐시를 건너뛰고 서버에 최신 파일인지 확인
    fetch(e.request, { cache: 'no-cache' })
      .then((res) => {
        const copy = res.clone();
        caches.open(CACHE).then((c) => c.put(e.request, copy));
        return res;
      })
      .catch(() => caches.match(e.request).then((r) => r || caches.match('./index.html')))
  );
});
