'use strict';

/* =========================================================
   뜨개노트 — 단수 카운터 + 작품 기록
   데이터는 이 기기 브라우저(localStorage)에만 저장됩니다.
   ========================================================= */

const STORE_KEY = 'tteugae-note:v1';
const $app = document.getElementById('app');
const $toast = document.getElementById('toast');

/* ---------- 아이콘 ---------- */
const ICON = {
  back: '<path d="M15 18l-6-6 6-6"/>',
  edit: '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  undo: '<path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11"/>',
  trash: '<path d="M3 6h18"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/>',
  link: '<path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  more: '<circle cx="5" cy="12" r="1.3"/><circle cx="12" cy="12" r="1.3"/><circle cx="19" cy="12" r="1.3"/>',
  doc: '<path d="M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9z"/><path d="M14 3v6h6"/><path d="M8 13h8M8 17h5"/>',
  globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a14 14 0 0 1 0 18a14 14 0 0 1 0-18"/>',
  external: '<path d="M14 4h6v6"/><path d="M20 4l-9 9"/><path d="M19 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1h5"/>',
  marker: '<path d="M9 11l-5 5v4h4l5-5"/><path d="M14 6l4 4"/><path d="M9 11l6-6a2.8 2.8 0 0 1 4 4l-6 6z"/>',
  chev: '<path d="M9 6l6 6-6 6"/>',
  pause: '<path d="M9 5v14M15 5v14"/>',
  play: '<path d="M7 5l12 7-12 7z"/>',
  book: '<path d="M12 6.5C10 5 7 4.5 4 5v13c3-.5 6 0 8 1.5 2-1.5 5-2 8-1.5V5c-3-.5-6 0-8 1.5z"/><path d="M12 6.5v13"/>',
  pen: '<path d="M4 20l1-5L16 4l4 4L9 19z"/><path d="M14 6l4 4"/>',
  eraser: '<path d="M20 20H9l-5-5a2 2 0 0 1 0-3l8-8a2 2 0 0 1 3 0l5 5a2 2 0 0 1 0 3l-8 8"/><path d="M9 9l6 6"/>',
  box: '<path d="M21 8l-9-5-9 5v8l9 5 9-5z"/><path d="M3 8l9 5 9-5"/><path d="M12 13v8"/>',
  needle: '<path d="M5 19L19 5"/><circle cx="18" cy="6" r="1.2"/>',
  camera: '<path d="M4 8h3l2-3h6l2 3h3a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1z"/><circle cx="12" cy="13.5" r="3.5"/>',
  next: '<path d="M9 6l6 6-6 6"/>',
  prev: '<path d="M15 6l-6 6 6 6"/>',
  close: '<path d="M6 6l12 12M18 6L6 18"/>',
  ink: '<path d="M12 20h9"/><path d="M16.5 3.5a2.12 2.12 0 0 1 3 3L7 19l-4 1 1-4Z"/><path d="M15 5l4 4"/>',
};
const icon = (name, size = 20) =>
  `<svg viewBox="0 0 24 24" width="${size}" height="${size}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON[name]}</svg>`;

const yarnBall = (size) => `
<svg viewBox="0 0 48 48" width="${size}" height="${size}" aria-hidden="true">
  <path d="M36.09 26C36.1 26.87 36.07 27.77 35.9 28.63C35.73 29.48 35.45 30.34 35.08 31.12C34.71 31.91 34.11 32.57 33.69 33.33C33.26 34.08 33.02 34.96 32.53 35.67C32.04 36.39 31.43 37.08 30.74 37.61C30.05 38.13 29.18 38.42 28.4 38.82C27.63 39.23 26.91 39.71 26.11 40.03C25.31 40.35 24.45 40.6 23.6 40.76C22.75 40.93 21.87 41.01 21 41.01C20.13 41.01 19.25 40.91 18.4 40.75C17.55 40.59 16.71 40.34 15.88 40.07C15.05 39.8 14.2 39.53 13.42 39.13C12.65 38.72 11.95 38.17 11.24 37.63C10.54 37.09 9.77 36.57 9.2 35.9C8.62 35.24 8.14 34.43 7.8 33.62C7.47 32.81 7.44 31.86 7.19 31.03C6.94 30.19 6.51 29.43 6.32 28.59C6.12 27.75 6 26.86 6.03 26C6.06 25.14 6.32 24.29 6.5 23.44C6.68 22.6 6.83 21.75 7.1 20.94C7.37 20.13 7.73 19.33 8.13 18.57C8.53 17.8 8.96 17.02 9.49 16.35C10.03 15.67 10.69 15.06 11.36 14.51C12.03 13.96 12.76 13.47 13.51 13.03C14.26 12.59 15.05 12.18 15.86 11.88C16.68 11.59 17.55 11.48 18.4 11.27C19.26 11.06 20.12 10.69 21 10.62C21.88 10.55 22.82 10.62 23.67 10.86C24.52 11.09 25.28 11.66 26.09 12.02C26.89 12.38 27.74 12.6 28.5 13.01C29.26 13.43 30 13.92 30.65 14.5C31.3 15.07 31.85 15.76 32.39 16.44C32.93 17.12 33.43 17.83 33.87 18.57C34.3 19.32 34.65 20.11 34.99 20.91C35.32 21.71 35.68 22.53 35.87 23.38C36.05 24.23 36.09 25.13 36.09 26Z" fill="#eac9c9"/>
  <clipPath id="yarn-clip"><path d="M36.09 26C36.1 26.87 36.07 27.77 35.9 28.63C35.73 29.48 35.45 30.34 35.08 31.12C34.71 31.91 34.11 32.57 33.69 33.33C33.26 34.08 33.02 34.96 32.53 35.67C32.04 36.39 31.43 37.08 30.74 37.61C30.05 38.13 29.18 38.42 28.4 38.82C27.63 39.23 26.91 39.71 26.11 40.03C25.31 40.35 24.45 40.6 23.6 40.76C22.75 40.93 21.87 41.01 21 41.01C20.13 41.01 19.25 40.91 18.4 40.75C17.55 40.59 16.71 40.34 15.88 40.07C15.05 39.8 14.2 39.53 13.42 39.13C12.65 38.72 11.95 38.17 11.24 37.63C10.54 37.09 9.77 36.57 9.2 35.9C8.62 35.24 8.14 34.43 7.8 33.62C7.47 32.81 7.44 31.86 7.19 31.03C6.94 30.19 6.51 29.43 6.32 28.59C6.12 27.75 6 26.86 6.03 26C6.06 25.14 6.32 24.29 6.5 23.44C6.68 22.6 6.83 21.75 7.1 20.94C7.37 20.13 7.73 19.33 8.13 18.57C8.53 17.8 8.96 17.02 9.49 16.35C10.03 15.67 10.69 15.06 11.36 14.51C12.03 13.96 12.76 13.47 13.51 13.03C14.26 12.59 15.05 12.18 15.86 11.88C16.68 11.59 17.55 11.48 18.4 11.27C19.26 11.06 20.12 10.69 21 10.62C21.88 10.55 22.82 10.62 23.67 10.86C24.52 11.09 25.28 11.66 26.09 12.02C26.89 12.38 27.74 12.6 28.5 13.01C29.26 13.43 30 13.92 30.65 14.5C31.3 15.07 31.85 15.76 32.39 16.44C32.93 17.12 33.43 17.83 33.87 18.57C34.3 19.32 34.65 20.11 34.99 20.91C35.32 21.71 35.68 22.53 35.87 23.38C36.05 24.23 36.09 25.13 36.09 26Z"/></clipPath>
  <g clip-path="url(#yarn-clip)" fill="none" stroke="#d8a9a9" stroke-width="1.5" stroke-linecap="round">
    <path d="M8.5 20c7.5 2 17 9.5 20.5 19.5"/><path d="M6.5 28.5c8.5-1 17.5 3.5 22 9"/>
    <path d="M12.5 14c8 4 15.5 12 17 22"/><path d="M23 11.5c3 7.5 2 18.5-5.5 29"/>
  </g>
  <g stroke="#8a6f63" stroke-width="2" stroke-linecap="round"><path d="M31 7l12 14"/><path d="M42 6.5l-9 14"/></g>
</svg>`;

/** 비어 있는 화면: 로고 그림 + 제목 + 설명 + (선택) 버튼, 가운데 정렬 */
function emptyStateHTML({ title, message = '', note = '', button = '', cls = '' }) {
  return `<div class="empty ${cls}">
    <div class="knit-cat" aria-hidden="true"></div>
    <h2>${title}</h2>
    ${message ? `<p class="muted">${message}</p>` : ''}
    ${note ? `<p class="muted xsmall">${note}</p>` : ''}
    ${button}
  </div>`;
}

/* ---------- 유틸 ---------- */
const uid = () => Math.random().toString(36).slice(2, 9) + Date.now().toString(36).slice(-4);
const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const int = (v, min = 0) => Math.max(min, parseInt(v, 10) || 0);
const enc = encodeURIComponent;

function todayKey(d = new Date()) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}
function ago(ts) {
  const s = (Date.now() - ts) / 1000;
  if (s < 60) return '방금';
  if (s < 3600) return `${Math.floor(s / 60)}분 전`;
  if (s < 86400) return `${Math.floor(s / 3600)}시간 전`;
  const d = Math.floor(s / 86400);
  if (d < 7) return `${d}일 전`;
  const dt = new Date(ts);
  return `${dt.getMonth() + 1}월 ${dt.getDate()}일`;
}

/* ---------- 데이터 ---------- */
/* ---------- 제작 기록 (아이폰 앱과 같은 형식) ---------- */
function normGauge(g) {
  g = g && typeof g === 'object' ? g : {};
  return { stitches: int(g.stitches), rows: int(g.rows), needle: String(g.needle || '').trim().slice(0, 40) };
}
function normYarn(y) {
  if (!y || typeof y !== 'object') return null;
  const r = {
    id: String(y.id || uid()),
    name: String(y.name || '').trim().slice(0, 60),
    color: String(y.color || '').trim().slice(0, 40),
    amount: Math.max(0, Number(y.amount) || 0),
    unit: ['볼', 'g', 'm'].includes(y.unit) ? y.unit : '볼',
  };
  return r.name || r.color || r.amount ? r : null;
}
const gaugeText = (g) => [
  g.stitches || g.rows ? `10cm에 ${[g.stitches ? `${g.stitches}코` : '', g.rows ? `${g.rows}단` : ''].filter(Boolean).join(' × ')}` : '',
  g.needle,
].filter(Boolean).join(' · ');
const yarnText = (y) => [[y.name, y.color].filter(Boolean).join(' '), y.amount ? `${+y.amount.toFixed(1)}${y.unit}` : ''].filter(Boolean).join(' · ');
const hasRecord = (p) => !!(gaugeText(p.gauge) || p.yarnsUsed.length || p.sizeNote);

function recordCardHTML(p) {
  const rows = [];
  if (gaugeText(p.gauge)) rows.push(['게이지', [gaugeText(p.gauge)]]);
  if (p.yarnsUsed.length) rows.push(['사용한 실', p.yarnsUsed.map(yarnText)]);
  if (p.sizeNote) rows.push(['사이즈·수정', [p.sizeNote]]);
  return `<div class="card record-card">${rows.map(([t, lines]) => `
    <div class="record-row"><div class="muted xsmall">${t}</div>${lines.map((l) => `<div>${esc(l)}</div>`).join('')}</div>`).join('')}</div>`;
}

function yarnRowHTML(y = {}) {
  return `<div class="yarn-row">
    <input name="y-name" maxlength="60" placeholder="실 이름 (예: 메리노 울)" value="${esc(y.name || '')}" aria-label="실 이름">
    <div class="yarn-nums">
      <input name="y-color" maxlength="40" placeholder="색" value="${esc(y.color || '')}" aria-label="색">
      <input name="y-amount" type="number" inputmode="decimal" min="0" step="0.1" placeholder="양" value="${y.amount || ''}" aria-label="사용량">
      <select name="y-unit" aria-label="단위">${['볼', 'g', 'm'].map((u) => `<option ${(y.unit || '볼') === u ? 'selected' : ''}>${u}</option>`).join('')}</select>
      <button type="button" class="icon-btn sm" data-yarn-del aria-label="이 실 삭제">${icon('trash', 18)}</button>
    </div>
  </div>`;
}

function openRecordDialog(p) {
  const yarns = p.yarnsUsed.length ? p.yarnsUsed : [{ name: p.yarn }];
  openDialog({
    title: '제작 기록',
    body: `
      <fieldset><legend>게이지 (10cm 기준)</legend>
        <div class="grid2">
          <label class="field"><span>코 수</span><input name="g-st" type="number" inputmode="numeric" min="0" value="${p.gauge.stitches || ''}" placeholder="예: 22"></label>
          <label class="field"><span>단 수</span><input name="g-rows" type="number" inputmode="numeric" min="0" value="${p.gauge.rows || ''}" placeholder="예: 30"></label>
        </div>
        <input name="g-needle" maxlength="40" value="${esc(p.gauge.needle)}" placeholder="바늘 (예: 4mm 대바늘)" aria-label="게이지 바늘">
      </fieldset>
      <fieldset><legend>사용한 실과 실제 사용량</legend>
        <div class="yarn-list">${yarns.map(yarnRowHTML).join('')}</div>
        <button type="button" class="chip add-rem" data-yarn-add>${icon('plus', 16)} 실 추가</button>
      </fieldset>
      <label class="field"><span>사이즈·수정 사항</span>
        <textarea name="size" class="notes" rows="3" maxlength="500" placeholder="예: M사이즈, 몸판 4cm 길게">${esc(p.sizeNote)}</textarea></label>`,
    onAction(v, fd) {
      p.gauge = normGauge({ stitches: fd.get('g-st'), rows: fd.get('g-rows'), needle: fd.get('g-needle') });
      const names = fd.getAll('y-name'), colors = fd.getAll('y-color'), amounts = fd.getAll('y-amount'), units = fd.getAll('y-unit');
      p.yarnsUsed = names.map((n, i) => normYarn({ name: n, color: colors[i], amount: amounts[i], unit: units[i] })).filter(Boolean);
      p.sizeNote = String(fd.get('size') || '').trim().slice(0, 500);
      touch(p);
      save();
      renderCounter(p);
      toast('제작 기록을 저장했어요');
    },
  });
}

// 제작 기록 창: 실 줄 추가·삭제
document.addEventListener('click', (e) => {
  if (e.target.closest?.('[data-yarn-add]')) {
    const list = e.target.closest('form').querySelector('.yarn-list');
    list.insertAdjacentHTML('beforeend', yarnRowHTML());
    list.lastElementChild.querySelector('input').focus();
  } else if (e.target.closest?.('[data-yarn-del]')) {
    e.target.closest('.yarn-row').remove();
  }
});

/* ---------- 완성한 작품 (예전 '제작 기록 모아보기'를 합쳤어요) ---------- */
const doneDate = (p) => new Date(p.doneAt || p.updatedAt);
function daysTaken(p) {
  const d0 = new Date(p.createdAt); d0.setHours(0, 0, 0, 0);
  const d1 = doneDate(p); d1.setHours(0, 0, 0, 0);
  return Math.max(1, Math.round((d1 - d0) / 86400000) + 1);
}
function renderDone() {
  document.title = '완성한 작품 · 뜨개노트';
  const list = state.projects.filter((p) => p.status === 'done').sort((a, b) => doneDate(b) - doneDate(a));
  const year = new Date().getFullYear();
  const thisYear = list.filter((p) => doneDate(p).getFullYear() === year).length;
  const card = (p) => {
    const d = doneDate(p);
    const meta = [p.yarn, p.needle].filter(Boolean).join(' · ');
    const rec = [
      gaugeText(p.gauge) ? `<li>${icon('needle', 14)} 게이지 ${esc(gaugeText(p.gauge))}</li>` : '',
      p.yarnsUsed.length ? `<li>${icon('box', 14)} ${esc(p.yarnsUsed.map(yarnText).join(', '))}</li>` : '',
      p.sizeNote ? `<li>${icon('edit', 14)} ${esc(p.sizeNote)}</li>` : '',
    ].join('');
    return `<li><a class="card done-card" href="#/p/${enc(p.id)}">
      ${p.photos.length ? `<span class="done-photo"><img data-photo="${esc(p.photos[p.photos.length - 1].fileName)}" alt=""></span>` : ''}
      <div class="card-top"><h2>${esc(p.name)}</h2><span class="row-pill done-pill">${p.row}단</span></div>
      <p class="muted small">${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일 완성 · ${daysTaken(p)}일 걸림</p>
      ${meta ? `<p class="muted small">${esc(meta)}</p>` : ''}
      ${rec ? `<ul class="done-rec">${rec}</ul>` : ''}
    </a></li>`;
  };
  $app.innerHTML = `
  <header class="bar">
    <a class="icon-btn" href="#/" aria-label="목록으로">${icon('back', 24)}</a>
    <h1 class="bar-title">완성한 작품</h1>
    <span class="bar-spacer"></span>
  </header>
  ${list.length ? `
    <p class="muted small">지금까지 ${list.length}개 완성${thisYear && thisYear !== list.length ? ` · 올해 ${thisYear}개` : ''}</p>
    <ul class="cards">${list.map(card).join('')}</ul>`
    : emptyStateHTML({ title: '아직 완성한 작품이 없어요', message: '다 뜬 작품은 작품 화면 맨 아래<br>‘완성으로 표시’를 눌러 주세요.<br>사진과 제작 기록이 여기에 모여요.', cls: 'full-empty' })}`;
}

/* ---------- 실·바늘 보관함 (아이폰 앱과 같은 형식) ---------- */
const UNITS = ['볼', 'g', 'm'];
const NEEDLE_KINDS = ['대바늘', '줄바늘', '코바늘', '기타'];
const amt = (v) => String(+(+v || 0).toFixed(1));
function normStashYarn(y) {
  if (!y || typeof y !== 'object') return null;
  return {
    id: String(y.id || uid()),
    name: String(y.name || '').trim().slice(0, 60),
    color: String(y.color || '').trim().slice(0, 40),
    weight: String(y.weight || '').trim().slice(0, 40),
    amount: Math.max(0, Number(y.amount) || 0),
    unit: UNITS.includes(y.unit) ? y.unit : '볼',
    note: String(y.note || '').slice(0, 300),
    photo: String(y.photo || ''),
    needleSize: String(y.needleSize || '').trim().replace(/\s*(mm|호)$/i, '').slice(0, 12),
    needleUnit: y.needleUnit === '호' ? '호' : 'mm',
  };
}
const yarnNeedleText = (y) => (y.needleSize ? y.needleSize + y.needleUnit : '');
function openSinglePhoto(fileName, title = '') {
  const dlg = document.createElement('dialog');
  dlg.className = 'photo-viewer';
  dlg.innerHTML = `
    <div class="pv-top">
      <span class="pv-title">${esc(title)}</span>
      <button class="pv-btn" data-pv="close" aria-label="닫기">${icon('close', 22)}</button>
    </div>
    <div class="pv-stage"><img alt="${esc(title)}"></div>`;
  document.body.appendChild(dlg);
  photoURL(fileName).then((u) => { if (u) dlg.querySelector('img').src = u; });
  dlg.addEventListener('click', (e) => { if (e.target.closest('[data-pv=close]') || e.target.classList.contains('pv-stage')) dlg.close(); });
  dlg.addEventListener('close', () => dlg.remove());
  dlg.showModal();
}
function normStashNeedle(n) {
  if (!n || typeof n !== 'object') return null;
  return {
    id: String(n.id || uid()),
    kind: NEEDLE_KINDS.includes(n.kind) ? n.kind : '대바늘',
    size: String(n.size || '').trim().slice(0, 40),
    note: String(n.note || '').slice(0, 300),
  };
}
function normStash(s) {
  s = s && typeof s === 'object' ? s : {};
  return {
    yarns: Array.isArray(s.yarns) ? s.yarns.map(normStashYarn).filter(Boolean) : [],
    needles: Array.isArray(s.needles) ? s.needles.map(normStashNeedle).filter(Boolean) : [],
  };
}
const stashYarnTitle = (y) => [y.name, y.color].filter(Boolean).join(' ') || '실';
const needleTitle = (n) => [n.size, n.kind].filter(Boolean).join(' ');
const findYarn = (id) => state.stash.yarns.find((y) => y.id === id);
const findNeedle = (id) => state.stash.needles.find((n) => n.id === id);
// 완성한 작품의 실은 이미 가진 양에서 빠졌으니 세지 않아요
const reserved = (yarnID) => state.projects.filter((p) => p.status !== 'done').reduce((s, p) => s + p.yarnLinks.filter((l) => l.yarnID === yarnID).reduce((a, l) => a + l.amount, 0), 0);
const remaining = (y) => y.amount - reserved(y.id);
const usingYarn = (id) => state.projects.filter((p) => p.status !== 'done' && p.yarnLinks.some((l) => l.yarnID === id));
const doneYarn = (id) => state.projects.filter((p) => p.status === 'done' && p.deducted.some((l) => l.yarnID === id));
// 보관함에서 실을 빼요 (가진 양보다 많이는 못 빼요). 실제로 뺀 양을 돌려줘요.
function deductYarns(links) {
  return links.map((l) => {
    const y = findYarn(l.yarnID);
    const take = y ? Math.min(l.amount, y.amount) : 0;
    if (take <= 0) return null;
    y.amount = Math.round((y.amount - take) * 100) / 100;
    return { yarnID: l.yarnID, amount: take };
  }).filter(Boolean);
}
function restoreYarns(links) {
  links.forEach((l) => { const y = findYarn(l.yarnID); if (y) y.amount = Math.round((y.amount + l.amount) * 100) / 100; });
}
// 완성하면 연결한 실을 빼고, 되돌리면 다시 채워요
function setDone(p, done) {
  restoreYarns(p.deducted);
  p.deducted = done ? deductYarns(p.yarnLinks) : [];
  p.status = done ? 'done' : 'active';
  p.pausedAt = null;
  p.doneAt = done ? Date.now() : null;
  return p.deducted;
}
const usingNeedle = (id) => state.projects.filter((p) => p.needleIDs.includes(id));
const leftPill = (y) => {
  const left = remaining(y);
  return left < 0 ? `<span class="row-pill short-pill">부족 ${amt(-left)}${y.unit}</span>`
    : `<span class="row-pill ${left === 0 ? 'empty-pill' : 'done-pill'}">남은 ${amt(left)}${y.unit}</span>`;
};

let stashTab = 'yarn';
function renderStash() {
  document.title = '실·바늘 보관함 · 뜨개노트';
  const { yarns, needles } = state.stash;
  const yarnCard = (y) => {
    const using = usingYarn(y.id), left = remaining(y);
    return `<li><button class="card stash-card" data-action="edit-yarn" data-id="${esc(y.id)}">
      <div class="card-body">
      <div class="card-top"><h2>${esc(stashYarnTitle(y))}${y.photo ? ` <span class="has-photo-icon" aria-label="사진 있음">${icon('camera', 15)}</span>` : ''}</h2>${leftPill(y)}</div>
      <p class="muted small">${esc([`가진 양 ${amt(y.amount)}${y.unit}`, y.weight, yarnNeedleText(y) ? `권장 바늘 ${yarnNeedleText(y)}` : ''].filter(Boolean).join(' · '))}</p>
      ${using.length ? `<p class="small">쓰는 작품: ${using.map((p) => esc(`${p.name} ${amt(p.yarnLinks.find((l) => l.yarnID === y.id).amount)}${y.unit}`)).join(', ')}</p>` : ''}
      ${doneYarn(y.id).length ? `<p class="muted small">완성한 작품: ${doneYarn(y.id).map((p) => esc(`${p.name} ${amt(p.deducted.find((l) => l.yarnID === y.id).amount)}${y.unit}`)).join(', ')}</p>` : ''}
      ${left < 0 ? `<p class="xsmall danger-text">가진 양보다 ${amt(-left)}${y.unit} 더 필요해요</p>` : ''}
      ${y.note ? `<p class="muted xsmall">${esc(y.note)}</p>` : ''}
      </div>
    </button></li>`;
  };
  const needleCard = (n) => {
    const using = usingNeedle(n.id);
    return `<li><button class="card stash-card" data-action="edit-needle" data-id="${esc(n.id)}">
      <div class="card-top"><h2>${esc(needleTitle(n))}</h2>
        ${using.length ? '<span class="row-pill paused-pill">사용 중</span>' : '<span class="row-pill done-pill">쉬는 중</span>'}</div>
      ${using.length ? `<p class="muted small">${using.map((p) => esc(p.name)).join(', ')}</p>` : ''}
      ${n.note ? `<p class="muted xsmall">${esc(n.note)}</p>` : ''}
    </button></li>`;
  };
  $app.innerHTML = `
  <header class="bar">
    <a class="icon-btn" href="#/" aria-label="목록으로">${icon('back', 24)}</a>
    <h1 class="bar-title">실·바늘 보관함</h1>
    <button class="icon-btn" data-action="${stashTab === 'yarn' ? 'add-yarn' : 'add-needle'}" aria-label="${stashTab === 'yarn' ? '실 추가' : '바늘 추가'}">${icon('plus', 22)}</button>
  </header>
  <div class="tabs" role="tablist">
    <button role="tab" aria-selected="${stashTab === 'yarn'}" data-action="stash-tab" data-tab="yarn">실 <span class="count">${yarns.length}</span></button>
    <button role="tab" aria-selected="${stashTab === 'needle'}" data-action="stash-tab" data-tab="needle">바늘 <span class="count">${needles.length}</span></button>
  </div>
  ${stashTab === 'yarn'
    ? (yarns.length ? `<ul class="cards">${yarns.map(yarnCard).join('')}</ul>` : emptyStateHTML({ title: '보관함에 실이 없어요', message: '가지고 있는 실을 넣어 두세요.<br>작품에 연결하면 남은 양을 알아서 계산해요.', button: `<button class="btn-primary wobbly" data-action="add-yarn">${icon('plus', 18)} 실 추가</button>`, cls: 'tab-empty' }))
    : (needles.length ? `<ul class="cards">${needles.map(needleCard).join('')}</ul>` : emptyStateHTML({ title: '보관함에 바늘이 없어요', message: '가지고 있는 바늘을 넣어 두세요.<br>어떤 바늘이 어느 작품에 쓰이는지 보여요.', button: `<button class="btn-primary wobbly" data-action="add-needle">${icon('plus', 18)} 바늘 추가</button>`, cls: 'tab-empty' }))}
  ${(stashTab === 'yarn' ? yarns : needles).length ? `<button class="btn-primary wobbly stash-add" data-action="${stashTab === 'yarn' ? 'add-yarn' : 'add-needle'}">${icon('plus', 18)} ${stashTab === 'yarn' ? '실 추가' : '바늘 추가'}</button>` : ''}`;
}

function rerenderAfterStash() {
  if (view === 'stash') renderStash();
  else if (view === 'counter' && current) renderCounter(current);
}

function openYarnDialog(y) {
  const isNew = !y;
  y = y || { unit: '볼' };
  let photo = y.photo || '';
  const newFiles = [];
  let saved = false;
  openDialog({
    title: isNew ? '실 추가' : '실 정보',
    body: `
      <div class="field yarn-photo-field">
        <div class="yarn-photo-head"><span>사진</span>
          <span class="yarn-photo-actions" ${y.photo ? '' : 'hidden'}>
            <label class="text-btn">바꾸기<input type="file" accept="image/*" hidden data-yarn-photo></label>
            <button type="button" class="text-btn danger-text" data-yarn-photo-remove>삭제</button>
          </span></div>
        <button type="button" class="yarn-photo-big" data-yarn-photo-view ${y.photo ? '' : 'hidden'} aria-label="사진 크게 보기"><img ${y.photo ? `data-photo="${esc(y.photo)}"` : ''} alt=""></button>
        <label class="chip yarn-photo-add" ${y.photo ? 'hidden' : ''}>${icon('camera', 16)} 사진 넣기<input type="file" accept="image/*" hidden data-yarn-photo></label>
      </div>
      <label class="field"><span>실 이름</span><input name="name" maxlength="60" value="${esc(y.name || '')}" placeholder="예: 메리노 울"></label>
      <div class="grid2">
        <label class="field"><span>색</span><input name="color" maxlength="40" value="${esc(y.color || '')}" placeholder="예: 그레이"></label>
        <label class="field"><span>굵기 (선택)</span><input name="weight" maxlength="40" value="${esc(y.weight || '')}" placeholder="예: DK, 합사"></label>
      </div>
      <label class="field"><span>가진 양</span>
        <div class="amount-row">
          <input name="amount" type="number" inputmode="decimal" min="0" step="0.1" value="${y.amount || ''}" placeholder="0">
          <select name="unit" aria-label="단위">${UNITS.map((u) => `<option ${y.unit === u ? 'selected' : ''}>${u}</option>`).join('')}</select>
        </div></label>
      <p class="muted xsmall" style="margin:0">작품에 연결한 양은 자동으로 빼서 ‘남은 양’으로 보여 줘요.</p>
      <label class="field"><span>권장 바늘 <em>(실 라벨에 적힌 굵기)</em></span>
        <div class="amount-row">
          <input name="needleSize" maxlength="12" inputmode="decimal" value="${esc(y.needleSize || '')}" placeholder="예: 4, 3.5~4">
          <select name="needleUnit" aria-label="바늘 단위">${['mm', '호'].map((u) => `<option ${(y.needleUnit || 'mm') === u ? 'selected' : ''}>${u}</option>`).join('')}</select>
        </div></label>
      <label class="field"><span>메모</span><input name="note" maxlength="300" value="${esc(y.note || '')}" placeholder="예: 세일 때 구매, 로트 번호"></label>`,
    extra: isNew ? '' : '<button value="delete" class="btn-danger-ghost" formnovalidate>삭제</button>',
    onAction(v, fd) {
      if (v === 'delete') {
        if (!confirm('이 실을 보관함에서 지울까요?\n작품에 연결된 것도 함께 풀려요.')) return false;
        if (y.photo) removePhotoFile(y.photo);
        newFiles.forEach(removePhotoFile);
        state.stash.yarns = state.stash.yarns.filter((x) => x.id !== y.id);
        state.projects.forEach((p) => { p.yarnLinks = p.yarnLinks.filter((l) => l.yarnID !== y.id); p.deducted = p.deducted.filter((l) => l.yarnID !== y.id); });
        save(); rerenderAfterStash(); toast('실을 지웠어요');
        return;
      }
      const next = normStashYarn({ ...y, name: fd.get('name'), color: fd.get('color'), weight: fd.get('weight'), amount: fd.get('amount'), unit: fd.get('unit'), note: fd.get('note'),
        needleSize: fd.get('needleSize'), needleUnit: fd.get('needleUnit'), photo });
      if (!next.name && !next.color) { toast('실 이름이나 색을 적어 주세요'); return false; }
      saved = true;
      newFiles.filter((f) => f !== photo).forEach(removePhotoFile);
      if (y.photo && y.photo !== photo) removePhotoFile(y.photo);
      const i = state.stash.yarns.findIndex((x) => x.id === next.id);
      if (i >= 0) state.stash.yarns[i] = next; else state.stash.yarns.push(next);
      save(); rerenderAfterStash(); toast(isNew ? '실을 넣어 두었어요' : '실 정보를 저장했어요');
    },
  });
  // 사진: 고르면 바로 저장해 두고, 저장하지 않고 닫으면 지워요
  const dlg = document.querySelector('dialog.sheet:last-of-type');
  const big = dlg.querySelector('.yarn-photo-big'), pimg = big.querySelector('img');
  const actions = dlg.querySelector('.yarn-photo-actions'), addBtn = dlg.querySelector('.yarn-photo-add');
  const removeBtn = dlg.querySelector('[data-yarn-photo-remove]');
  hydratePhotos(dlg);
  const sync = async () => {
    big.hidden = !photo; actions.hidden = !photo; addBtn.hidden = !!photo;
    pimg.removeAttribute('src');
    if (photo) pimg.src = await photoURL(photo);
  };
  big.addEventListener('click', () => { if (photo) openSinglePhoto(photo, stashYarnTitle(y) || '실'); });
  dlg.querySelectorAll('[data-yarn-photo]').forEach((inp) => inp.addEventListener('change', async (e) => {
    const f = e.target.files[0];
    e.target.value = '';
    if (!f) return;
    try {
      const blob = (await shrinkPhoto(f)) || f;
      const fileName = 'photo-' + uid();
      await idb.put(fileName, blob);
      newFiles.push(fileName);
      photo = fileName;
      sync();
    } catch { toast('사진을 불러오지 못했어요'); }
  }));
  removeBtn.addEventListener('click', () => { photo = ''; sync(); });
  dlg.addEventListener('close', () => { if (!saved) newFiles.forEach(removePhotoFile); });
}

function openNeedleDialog(n) {
  const isNew = !n;
  n = n || { kind: '대바늘' };
  openDialog({
    title: isNew ? '바늘 추가' : '바늘 정보',
    body: `
      <fieldset><legend>종류</legend>
        <div class="seg">${NEEDLE_KINDS.map((k) => `<label><input type="radio" name="kind" value="${k}" ${n.kind === k ? 'checked' : ''}><span>${k}</span></label>`).join('')}</div>
      </fieldset>
      <label class="field"><span>크기</span><input name="size" maxlength="40" required value="${esc(n.size || '')}" placeholder="예: 4.5mm, 80cm"></label>
      <label class="field"><span>메모</span><input name="note" maxlength="300" value="${esc(n.note || '')}" placeholder="예: 대나무, 2세트"></label>`,
    extra: isNew ? '' : '<button value="delete" class="btn-danger-ghost" formnovalidate>삭제</button>',
    onAction(v, fd) {
      if (v === 'delete') {
        if (!confirm('이 바늘을 보관함에서 지울까요?')) return false;
        state.stash.needles = state.stash.needles.filter((x) => x.id !== n.id);
        state.projects.forEach((p) => { p.needleIDs = p.needleIDs.filter((id) => id !== n.id); });
        save(); rerenderAfterStash(); toast('바늘을 지웠어요');
        return;
      }
      const next = normStashNeedle({ ...n, kind: fd.get('kind'), size: fd.get('size'), note: fd.get('note') });
      if (!next.size) return false;
      const i = state.stash.needles.findIndex((x) => x.id === next.id);
      if (i >= 0) state.stash.needles[i] = next; else state.stash.needles.push(next);
      save(); rerenderAfterStash(); toast(isNew ? '바늘을 넣어 두었어요' : '바늘 정보를 저장했어요');
    },
  });
}

function materialsSectionHTML(p) {
  const links = p.yarnLinks.map((l) => [l, findYarn(l.yarnID)]).filter(([, y]) => y);
  const needles = p.needleIDs.map(findNeedle).filter(Boolean);
  return `
  <section class="section">
    <div class="section-head">
      <h2>재료</h2>
      <button class="chip" data-action="materials">${icon('box', 16)} 보관함에서 고르기</button>
    </div>
    ${links.length || needles.length ? `<div class="card materials">
      ${links.map(([l, y]) => {
        const left = remaining(y);
        const took = p.deducted.find((d) => d.yarnID === y.id)?.amount || 0;
        const sub = p.status === 'done'
          ? `<div class="xsmall muted">${took > 0 ? `완성하면서 보관함에서 ${amt(took)}${y.unit} 뺐어요` : '보관함에 남은 양이 없어서 빼지 않았어요'}</div>`
          : `<div class="xsmall ${left < 0 ? 'danger-text' : 'muted'}">${left < 0 ? `보관함보다 ${amt(-left)}${y.unit} 부족해요` : `보관함 남은 ${amt(left)}${y.unit}`}</div>`;
        return `<div class="mat-row"><div><div>${esc(stashYarnTitle(y))}</div>
          ${sub}</div>
          <span class="row-pill">${amt(l.amount)}${y.unit}</span></div>`;
      }).join('')}
      ${needles.length ? `<div class="mat-needles">${icon('needle', 16)} ${needles.map((n) => esc(needleTitle(n))).join(', ')}</div>` : ''}
    </div>` : `<p class="muted small hint">보관함의 실과 바늘을 이 작품에 연결해 두면, 남은 양을 챙겨 주고, 완성하면 쓴 실을 보관함에서 알아서 빼 줘요.</p>`}
  </section>`;
}

function openMaterialsDialog(p) {
  const { yarns, needles } = state.stash;
  const linked = (id) => p.yarnLinks.find((l) => l.yarnID === id)?.amount || '';
  openDialog({
    title: '보관함에서 고르기',
    body: `
      <fieldset><legend>이 작품에 쓸 실 <span class="xsmall">· 쓸 양을 적으면 연결되고, 비우면 풀려요</span></legend>
        ${yarns.length ? yarns.map((y) => `
          <label class="mat-pick"><span><span>${esc(stashYarnTitle(y))}</span><span class="muted xsmall">가진 ${amt(y.amount)}${y.unit}</span></span>
            <span class="amount-row"><input name="link-${esc(y.id)}" type="number" inputmode="decimal" min="0" step="0.1" value="${linked(y.id)}" placeholder="0" aria-label="${esc(stashYarnTitle(y))} 쓸 양"><span class="muted">${y.unit}</span></span></label>`).join('')
          : '<p class="muted small" style="margin:0">보관함에 실이 없어요.</p>'}
      </fieldset>
      <fieldset><legend>이 작품에 쓸 바늘</legend>
        ${needles.length ? needles.map((n) => `
          <label class="check"><input type="checkbox" name="needle" value="${esc(n.id)}" ${p.needleIDs.includes(n.id) ? 'checked' : ''}><span>${esc(needleTitle(n))}</span></label>`).join('')
          : '<p class="muted small" style="margin:0">보관함에 바늘이 없어요.</p>'}
      </fieldset>
      <a class="link-btn" href="#/stash">${icon('box', 16)} 보관함 열기 (실·바늘 추가)</a>`,
    onAction(v, fd) {
      p.yarnLinks = yarns.map((y) => ({ yarnID: y.id, amount: Math.max(0, Number(fd.get('link-' + y.id)) || 0) })).filter((l) => l.amount > 0);
      if (p.status === 'done') { restoreYarns(p.deducted); p.deducted = deductYarns(p.yarnLinks); }
      const picked = fd.getAll('needle');
      p.needleIDs = needles.map((n) => n.id).filter((id) => picked.includes(id));
      touch(p); save(); renderCounter(p); toast('재료를 연결했어요');
    },
  });
}

const KIND_LABEL = { inc: '늘림', dec: '줄임' };
function normRem(r) {
  const every = int(r.every);
  if (every < 1) return null;
  const kind = ['inc', 'dec'].includes(r.kind) ? r.kind : 'note';
  const stitches = kind === 'note' ? 0 : int(r.stitches) || 2;
  return {
    id: String(r.id || uid()),
    label: String(r.label || '').trim().slice(0, 80) || (kind === 'note' ? `${every}단마다 할 일` : `${KIND_LABEL[kind]} ${stitches}코`),
    every,
    from: int(r.from) || every,
    times: int(r.times),
    kind,
    stitches,
  };
}
/** row 단까지 끝낸 횟수 */
function remDone(r, row) {
  if (row < r.from) return 0;
  const n = Math.floor((row - r.from) / r.every) + 1;
  return r.times ? Math.min(n, r.times) : n;
}
/** 늘림·줄임을 반영한 지금 코 수 (시작 코 수가 없으면 null) */
function stitchCount(p, row = p.row) {
  if (!p.castOn) return null;
  return p.castOn + p.reminders.reduce((sum, r) => sum + (r.kind === 'inc' ? 1 : r.kind === 'dec' ? -1 : 0) * r.stitches * remDone(r, row), 0);
}
function normCounter(c) {
  return {
    id: String(c.id || uid()),
    name: String(c.name || '카운터').slice(0, 30),
    value: int(c.value),
    max: int(c.max),
    linked: !!c.linked,
    offset: int(c.offset),
    ...normSteps(c),
  };
}
// 순서 카운터: 한 번 반복할 때 뜨는 순서
function normSteps(c) {
  const steps = (Array.isArray(c.steps) ? c.steps : []).map((x) => String(x).trim().slice(0, 40)).filter(Boolean);
  return { steps, step: steps.length ? Math.min(int(c.step), steps.length - 1) : 0, rowOnFinish: !!(steps.length && c.rowOnFinish) };
}
const isFinished = (c) => c.steps.length && c.max && c.value >= c.max;
function normalize(p) {
  return {
    id: String(p.id || uid()),
    name: String(p.name || '이름 없는 작품').slice(0, 60),
    yarn: String(p.yarn || '').slice(0, 80),
    needle: String(p.needle || '').slice(0, 40),
    targetRows: int(p.targetRows),
    castOn: int(p.castOn),
    row: int(p.row),
    notes: String(p.notes || ''),
    status: ['done', 'paused'].includes(p.status) ? p.status : 'active',
    pausedAt: Number(p.pausedAt) || null,
    doneAt: Number(p.doneAt) || null,
    resumeNote: String(p.resumeNote || '').slice(0, 200),
    changes: Array.isArray(p.changes)
      ? p.changes.filter((c) => c && c.text).map((c) => ({ id: String(c.id || uid()), date: Number(c.date) || Date.now(), row: int(c.row), text: String(c.text).slice(0, 300) }))
      : [],
    gauge: normGauge(p.gauge),
    yarnsUsed: Array.isArray(p.yarnsUsed) ? p.yarnsUsed.map(normYarn).filter(Boolean) : [],
    sizeNote: String(p.sizeNote || '').slice(0, 500),
    yarnLinks: Array.isArray(p.yarnLinks)
      ? p.yarnLinks.filter((l) => l && l.yarnID).map((l) => ({ yarnID: String(l.yarnID), amount: Math.max(0, Number(l.amount) || 0) })).filter((l) => l.amount > 0)
      : [],
    needleIDs: Array.isArray(p.needleIDs) ? p.needleIDs.map(String) : [],
    photos: Array.isArray(p.photos)
      ? p.photos.filter((x) => x && x.fileName).map((x) => ({ id: String(x.id || uid()), fileName: String(x.fileName), date: Number(x.date) || Date.now(), row: int(x.row), caption: String(x.caption || '').slice(0, 200) }))
      : [],
    deducted: Array.isArray(p.deducted)
      ? p.deducted.filter((l) => l && l.yarnID).map((l) => ({ yarnID: String(l.yarnID), amount: Math.max(0, Number(l.amount) || 0) })).filter((l) => l.amount > 0)
      : [],
    reminders: Array.isArray(p.reminders) ? p.reminders.map(normRem).filter(Boolean) : [],
    counters: Array.isArray(p.counters) ? p.counters.map(normCounter) : [],
    log: p.log && typeof p.log === 'object' && !Array.isArray(p.log) ? p.log : {},
    pattern: normPattern(p.pattern),
    guide: normGuide(p.guide),
    guidePart: String(p.guidePart || '').slice(0, 30),
    guideStep: int(p.guideStep),
    guideStepRow: int(p.guideStepRow),
    createdAt: Number(p.createdAt) || Date.now(),
    updatedAt: Number(p.updatedAt) || Date.now(),
  };
}

/* ---------- 도안 (PDF는 IndexedDB, 링크는 작품 데이터에) ---------- */
// 아이폰 앱과 같은 형식: { kind: 'pdf'|'web', title, fileName?, url?, page }
function normalizedWebURL(text) {
  let t = String(text || '').trim();
  if (!t || /\s/.test(t)) return null;
  const lower = t.toLowerCase();
  if (lower.startsWith('http://')) t = 'https://' + t.slice(7);
  else if (!lower.startsWith('https://')) t = 'https://' + t;
  try {
    const u = new URL(t);
    return u.hostname.includes('.') ? u.href : null;
  } catch { return null; }
}
function normPattern(x) {
  if (!x || typeof x !== 'object') return null;
  if (x.kind === 'pdf' && x.fileName) {
    const ref = { kind: 'pdf', title: String(x.title || 'PDF 도안').slice(0, 80), fileName: String(x.fileName), page: int(x.page) };
    if (x.image) ref.image = true;
    if (Number.isFinite(x.markerY)) ref.markerY = Math.max(0, x.markerY);
    return ref;
  }
  if (x.kind === 'web') {
    const url = normalizedWebURL(x.url);
    if (url) {
      const ref = { kind: 'web', title: String(x.title || new URL(url).hostname).slice(0, 80), url, page: 0 };
      if (Number.isFinite(x.markerY)) ref.markerY = Math.max(0, x.markerY);
      return ref;
    }
  }
  return null;
}

const idb = (() => {
  let dbp;
  const open = () => dbp || (dbp = new Promise((res, rej) => {
    const r = indexedDB.open('tteugae-note', 1);
    r.onupgradeneeded = () => r.result.createObjectStore('files');
    r.onsuccess = () => res(r.result);
    r.onerror = () => { dbp = null; rej(r.error); };
  }));
  const run = async (mode, fn) => {
    const db = await open();
    return new Promise((res, rej) => {
      const tx = db.transaction('files', mode);
      const req = fn(tx.objectStore('files'));
      tx.oncomplete = () => res(req?.result);
      tx.onerror = () => rej(tx.error);
      tx.onabort = () => rej(tx.error);
    });
  };
  return {
    put: (key, val) => run('readwrite', (st) => st.put(val, key)),
    get: (key) => run('readonly', (st) => st.get(key)),
    del: (key) => run('readwrite', (st) => st.delete(key)),
  };
})();

function setPattern(p, ref) {
  const old = p.pattern;
  p.pattern = ref;
  touch(p);
  save();
  if (old?.kind === 'pdf' && old.fileName !== ref?.fileName) removePatternFiles(old);
}
function removePatternFiles(ref) {
  idb.del(ref.fileName).catch(() => {});
  idb.del('ink-' + ref.fileName).catch(() => {});
}

/* ---------- 작품 사진 (IndexedDB에 JPEG로 저장) ---------- */
const photoURLs = new Map();
async function photoURL(fileName) {
  if (photoURLs.has(fileName)) return photoURLs.get(fileName);
  const blob = await idb.get(fileName).catch(() => null);
  const url = blob ? URL.createObjectURL(blob) : '';
  photoURLs.set(fileName, url);
  return url;
}
// 화면에 있는 <img data-photo>에 사진을 채워요
function hydratePhotos(root = document) {
  root.querySelectorAll('img[data-photo]:not([src])').forEach(async (img) => {
    const url = await photoURL(img.dataset.photo);
    if (url) img.src = url; else img.closest('.photo-thumb, .card-photo, .done-photo')?.classList.add('missing');
  });
}
// 회전을 반영하고 긴 변 2000px JPEG로 줄여요
async function shrinkPhoto(file) {
  const bmp = await createImageBitmap(file, { imageOrientation: 'from-image' });
  const scale = Math.min(1, 2000 / Math.max(bmp.width, bmp.height));
  const c = document.createElement('canvas');
  c.width = Math.round(bmp.width * scale);
  c.height = Math.round(bmp.height * scale);
  c.getContext('2d').drawImage(bmp, 0, 0, c.width, c.height);
  bmp.close?.();
  return new Promise((res) => c.toBlob(res, 'image/jpeg', 0.85));
}
async function addPhotos(p, files) {
  let added = 0;
  for (const f of [...files].slice(0, 10)) {
    if (!f.type.startsWith('image/') && !/\.(jpe?g|png|gif|webp|heic|heif)$/i.test(f.name)) continue;
    try {
      const blob = (await shrinkPhoto(f)) || f;
      const fileName = 'photo-' + uid();
      await idb.put(fileName, blob);
      p.photos.push({ id: uid(), fileName, date: Date.now(), row: p.row, caption: '' });
      added++;
    } catch { /* 못 읽는 사진은 건너뛰어요 */ }
  }
  if (added) { navigator.storage?.persist?.().catch(() => {}); touch(p); save(); }
  if (view === 'counter' && current === p) renderCounter(p);
  toast(added ? `사진 ${added}장을 붙였어요` : '사진을 불러오지 못했어요');
}
function removePhotoFile(fileName) {
  idb.del(fileName).catch(() => {});
  const url = photoURLs.get(fileName);
  if (url) URL.revokeObjectURL(url);
  photoURLs.delete(fileName);
}
function photosSectionHTML(p) {
  const list = [...p.photos].reverse();
  return `
  <section class="section">
    <div class="section-head">
      <h2>사진</h2>
      <label class="chip">${icon('camera', 16)} 추가<input type="file" accept="image/*" multiple data-action="add-photos" hidden></label>
    </div>
    ${list.length ? `<div class="photo-strip">${list.map((ph) => `
      <button class="photo-thumb" data-action="view-photo" data-id="${esc(ph.id)}" aria-label="${ph.row}단 사진${ph.caption ? ': ' + esc(ph.caption) : ''}">
        <img data-photo="${esc(ph.fileName)}" alt="">
        <span class="photo-row">${ph.row}단</span>
      </button>`).join('')}</div>`
      : `<p class="muted small hint">뜨는 중간중간, 그리고 완성했을 때 사진을 남겨 두세요. 찍은 단도 함께 기록돼요.</p>`}
  </section>`;
}
function openPhotoViewer(p, startID) {
  const list = () => [...p.photos].reverse();
  let idx = Math.max(0, list().findIndex((x) => x.id === startID));
  const dlg = document.createElement('dialog');
  dlg.className = 'photo-viewer';
  dlg.innerHTML = `
    <div class="pv-top">
      <button class="pv-btn" data-pv="close" aria-label="닫기">${icon('close', 22)}</button>
      <button class="pv-btn" data-pv="delete" aria-label="사진 삭제">${icon('trash', 20)}</button>
    </div>
    <div class="pv-stage">
      <button class="pv-btn pv-nav" data-pv="prev" aria-label="이전 사진">${icon('prev', 24)}</button>
      <img alt="">
      <button class="pv-btn pv-nav" data-pv="next" aria-label="다음 사진">${icon('next', 24)}</button>
    </div>
    <div class="pv-bottom">
      <div class="pv-meta"></div>
      <input class="pv-caption" maxlength="200" placeholder="한 줄 메모 (예: 앞판 완성!)" aria-label="사진 메모">
    </div>`;
  document.body.appendChild(dlg);
  const img = dlg.querySelector('img'), meta = dlg.querySelector('.pv-meta'), cap = dlg.querySelector('.pv-caption');
  const saveCaption = () => {
    const ph = list()[idx];
    const t = cap.value.trim().slice(0, 200);
    if (ph && ph.caption !== t) { ph.caption = t; touch(p); save(); }
  };
  const show = async () => {
    const all = list();
    if (!all.length) { dlg.close(); return; }
    idx = Math.min(Math.max(0, idx), all.length - 1);
    const ph = all[idx];
    const d = new Date(ph.date);
    meta.textContent = `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일 · ${ph.row}단${all.length > 1 ? ` · ${idx + 1}/${all.length}` : ''}`;
    cap.value = ph.caption;
    dlg.querySelector('[data-pv="prev"]').hidden = idx === 0;
    dlg.querySelector('[data-pv="next"]').hidden = idx >= all.length - 1;
    img.removeAttribute('src');
    const url = await photoURL(ph.fileName);
    if (list()[idx] === ph) img.src = url;
  };
  dlg.addEventListener('click', (e) => {
    const b = e.target.closest('[data-pv]');
    if (!b) return;
    const a = b.dataset.pv;
    if (a === 'close') { dlg.close(); return; }
    saveCaption();
    if (a === 'prev') { idx--; show(); }
    if (a === 'next') { idx++; show(); }
    if (a === 'delete') {
      if (!confirm('이 사진을 지울까요?')) return;
      const ph = list()[idx];
      p.photos = p.photos.filter((x) => x !== ph);
      removePhotoFile(ph.fileName);
      touch(p); save(); toast('사진을 지웠어요');
      show();
    }
  });
  cap.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); saveCaption(); cap.blur(); } });
  dlg.addEventListener('keydown', (e) => {
    if (e.target === cap) return;
    if (e.key === 'ArrowLeft' && idx > 0) { saveCaption(); idx--; show(); }
    if (e.key === 'ArrowRight' && idx < list().length - 1) { saveCaption(); idx++; show(); }
  });
  let sx = null;
  dlg.querySelector('.pv-stage').addEventListener('pointerdown', (e) => { sx = e.clientX; });
  dlg.querySelector('.pv-stage').addEventListener('pointerup', (e) => {
    if (sx === null) return;
    const dx = e.clientX - sx; sx = null;
    if (Math.abs(dx) < 50) return;
    saveCaption();
    if (dx < 0 && idx < list().length - 1) idx++; else if (dx > 0 && idx > 0) idx--;
    show();
  });
  dlg.addEventListener('close', () => {
    saveCaption();
    dlg.remove();
    if (view === 'counter' && current === p) renderCounter(p);
  });
  dlg.showModal();
  show();
}

async function importPatternPDF(p, file) {
  if (!file) return;
  const isImage = file.type.startsWith('image/') || /\.(jpe?g|png|gif|webp|heic|heif|bmp)$/i.test(file.name);
  const isPdf = file.type === 'application/pdf' || /\.pdf$/i.test(file.name);
  if (!isImage && !isPdf) { toast('PDF나 이미지 파일만 불러올 수 있어요'); return; }
  if (file.size > 80 * 1024 * 1024) { toast('80MB보다 큰 파일은 불러올 수 없어요'); return; }
  const key = 'pdf-' + uid();
  try {
    await idb.put(key, file);
  } catch {
    toast('PDF를 저장하지 못했어요. 저장 공간을 확인해 주세요.');
    return;
  }
  navigator.storage?.persist?.().catch(() => {});
  const ref = { kind: 'pdf', title: file.name.replace(/\.[a-z0-9]+$/i, '').slice(0, 80) || '도안', fileName: key, page: 0 };
  if (isImage) ref.image = true;
  setPattern(p, ref);
  go(`/p/${enc(p.id)}/pattern`);
  readGuide(p, { auto: true });
}

function pickPatternPDF(p) {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = 'application/pdf,.pdf,image/*';
  input.hidden = true;
  input.addEventListener('change', () => { importPatternPDF(p, input.files[0]); input.remove(); });
  document.body.appendChild(input);
  input.click();
}

const defaultState = () => ({ projects: [], stash: { yarns: [], needles: [] }, patterns: [], settings: { haptics: true, keepAwake: true } });
function load() {
  try {
    const s = JSON.parse(localStorage.getItem(STORE_KEY));
    if (s && Array.isArray(s.projects)) {
      return { projects: s.projects.map(normalize), stash: normStash(s.stash), patterns: (Array.isArray(s.patterns) ? s.patterns : []).map(normSavedPattern).filter(Boolean), settings: { ...defaultState().settings, ...(s.settings || {}) } };
    }
  } catch { /* 저장된 데이터가 없거나 깨졌으면 새로 시작 */ }
  return defaultState();
}
let state = load();

function save() {
  try {
    localStorage.setItem(STORE_KEY, JSON.stringify(state));
  } catch {
    toast('저장하지 못했어요. 저장 공간을 확인해 주세요.');
  }
}
const find = (id) => state.projects.find((p) => p.id === id);
const touch = (p) => { p.updatedAt = Date.now(); };

/* ---------- 반복 알림 계산 ---------- */
// r.from 단부터 r.every 단마다, r.times 회(0이면 무제한)
function remIndex(r, row) {
  if (row < r.from) return -1;
  const d = row - r.from;
  if (d % r.every) return -1;
  const i = d / r.every;
  return r.times && i >= r.times ? -1 : i;
}
const hitsAt = (p, row) => p.reminders.map((r) => ({ r, i: remIndex(r, row) })).filter((x) => x.i >= 0);
function nextHit(r, row) {
  const next = row < r.from ? r.from : r.from + (Math.floor((row - r.from) / r.every) + 1) * r.every;
  const i = (next - r.from) / r.every;
  return r.times && i >= r.times ? null : { row: next, i };
}

/* ---------- 보조 카운터 ---------- */
// 단과 연동된 카운터는 값을 저장하지 않고 현재 단에서 계산합니다 (되돌리기가 항상 맞게 동작)
function counterValue(c, row) {
  if (!c.linked) return c.value;
  const n = row - c.offset;
  if (n <= 0) return 0;
  return c.max ? ((n - 1) % c.max) + 1 : n;
}

/* ---------- 되돌리기 ---------- */
const undoStacks = new Map();
function pushUndo(p) {
  const k = todayKey();
  const stack = undoStacks.get(p.id) || [];
  stack.push({
    row: p.row,
    counters: p.counters.map((c) => ({ id: c.id, value: c.value, offset: c.offset, step: c.step })),
    logKey: k,
    logVal: p.log[k] || 0,
    guideStep: p.guideStep,
    guideStepRow: p.guideStepRow,
  });
  if (stack.length > 200) stack.shift();
  undoStacks.set(p.id, stack);
}
const canUndo = (p) => (undoStacks.get(p.id) || []).length > 0;
function undo(p) {
  const snap = undoStacks.get(p.id)?.pop();
  if (!snap) return false;
  p.row = snap.row;
  for (const sc of snap.counters) {
    const c = p.counters.find((x) => x.id === sc.id);
    if (c) { c.value = sc.value; c.offset = sc.offset; c.step = sc.step || 0; }
  }
  p.guideStep = snap.guideStep || 0;
  p.guideStepRow = snap.guideStepRow || 0;
  if (snap.logVal) p.log[snap.logKey] = snap.logVal;
  else delete p.log[snap.logKey];
  touch(p);
  save();
  return true;
}

/* ---------- 동작 ---------- */
function buzz(pattern) {
  if (state.settings.haptics && navigator.vibrate) navigator.vibrate(pattern);
}

let toastTimer;
function toast(msg) {
  $toast.textContent = msg;
  $toast.classList.add('show');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => $toast.classList.remove('show'), 2800);
}

function changeRow(p, d, { quietHits = false } = {}) {
  const next = Math.max(0, p.row + d);
  if (next === p.row) return;
  pushUndo(p);
  p.row = next;
  const k = todayKey();
  p.log[k] = Math.max(0, (p.log[k] || 0) + d);
  if (!p.log[k]) delete p.log[k];
  touch(p);
  save();

  if (d > 0) {
    const hits = hitsAt(p, p.row);
    if (hits.length) {
      buzz([40, 60, 40]);
      if (!quietHits) toast(`${p.row}단: ${hits.map((h) => h.r.label).join(', ')}`);
    } else {
      buzz(12);
    }
    if (p.targetRows && p.row === p.targetRows) toast(`목표 ${p.targetRows}단에 도착했어요!`);
  } else {
    buzz([8, 40, 8]);
  }
}

function changeCounter(p, c, d) {
  if (c.linked) return;
  let v = c.value + d;
  if (c.max && v > c.max) {
    v = 1;
    toast(`${c.name} ${c.max}회 한 바퀴 완료`);
  }
  v = Math.max(0, v);
  if (v === c.value) return;
  pushUndo(p);
  c.value = v;
  touch(p);
  save();
  buzz(10);
}

/* ---------- 화면 꺼짐 방지 ---------- */
let wakeLock = null;
let wantWake = false;
async function requestWake() {
  wantWake = true;
  if (!state.settings.keepAwake || !('wakeLock' in navigator) || wakeLock) return;
  try {
    const lock = await navigator.wakeLock.request('screen');
    if (!wantWake) { lock.release(); return; }
    wakeLock = lock;
    lock.addEventListener('release', () => { if (wakeLock === lock) wakeLock = null; });
  } catch { /* 지원하지 않거나 허용되지 않음 */ }
}
function releaseWake() {
  wantWake = false;
  wakeLock?.release().catch(() => {});
  wakeLock = null;
}
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible' && wantWake) requestWake();
});

/* ---------- 라우팅 ---------- */
let current = null;
let view = 'list';
let listTab = 'active';

function go(path, replace = false) {
  if (location.hash === '#' + path) { route(); return; } // 같은 주소면 화면만 다시 그리기
  if (replace) location.replace('#' + path);
  else location.hash = path;
}

function route() {
  const parts = (location.hash.slice(1) || '/').split('/').filter(Boolean).map((s) => {
    try { return decodeURIComponent(s); } catch { return s; }
  });
  current = null;
  releaseWake();
  closePdf();
  document.querySelectorAll('dialog').forEach((d) => d.close());
  window.scrollTo(0, 0);

  if (parts[0] === 'records' || parts[0] === 'done') { view = 'done'; renderDone(); return; }
  if (parts[0] === 'stash') { view = 'stash'; renderStash(); return; }
  if (parts[0] === 'patterns') { view = 'patterns'; renderPatterns(); return; }
  if (parts[0] === 'p') {
    if (parts[1] === 'new') { view = 'form'; renderForm(null); return; }
    const p = find(parts[1]);
    if (!p) { go('/', true); return; }
    current = p;
    if (parts[2] === 'edit') { view = 'form'; renderForm(p); return; }
    if (parts[2] === 'pattern' && p.pattern) {
      view = 'pattern';
      renderPattern(p);
      requestWake();
      return;
    }
    view = 'counter';
    renderCounter(p);
    requestWake();
    return;
  }
  view = 'list';
  renderList();
}

/* ---------- 화면: 목록 ---------- */
function cardHTML(p) {
  const meta = [p.yarn, p.needle].filter(Boolean).map(esc).join(' · ');
  const pct = p.targetRows ? Math.min(100, Math.round((p.row / p.targetRows) * 100)) : null;
  return `
  <li><a class="card ${p.photos.length ? 'has-photo' : ''}" href="#/p/${enc(p.id)}">
    ${p.photos.length ? `<span class="card-photo"><img data-photo="${esc(p.photos[p.photos.length - 1].fileName)}" alt=""></span>` : ''}
    <div class="card-body">
    <div class="card-top">
      <h2>${esc(p.name)}</h2>
      ${p.status === 'done' ? `<span class="row-pill done-pill">완성</span>`
        : p.status === 'paused' ? `<span class="row-pill paused-pill">${p.row}단에서 멈춤</span>`
        : `<span class="row-pill">${p.row}단</span>`}
    </div>
    ${meta ? `<p class="muted small">${meta}</p>` : ''}
    ${p.status === 'paused' && p.resumeNote ? `<p class="resume-note">“${esc(p.resumeNote)}”</p>` : ''}
    ${pct !== null ? `
      <div class="progress" role="progressbar" aria-valuenow="${pct}" aria-valuemin="0" aria-valuemax="100" aria-label="진행률"><span style="width:${pct}%"></span></div>
      <p class="muted small">${p.row} / ${p.targetRows}단 · ${pct}%</p>` : ''}
    <p class="muted xsmall">${ago(p.updatedAt)} 수정</p>
    </div>
  </a></li>`;
}

function renderList() {
  document.title = '뜨개노트';
  // 뜨는 중인 작품만 (잠시 멈춘 작품은 아래쪽에), 완성작은 ‘완성작’ 화면에
  const items = state.projects.filter((p) => p.status !== 'done')
    .sort((a, b) => (a.status === 'paused') - (b.status === 'paused') || b.updatedAt - a.updatedAt);
  const done = state.projects.filter((p) => p.status === 'done');
  const totalToday = state.projects.reduce((s, p) => s + (p.log[todayKey()] || 0), 0);

  $app.innerHTML = `
  <header class="home-head">
    <div class="brand">
      ${yarnBall(44)}
      <div>
        <h1>뜨개노트</h1>
        <p class="muted">${totalToday ? `오늘 ${totalToday}단 떴어요` : '오늘도 한 단씩'}</p>
      </div>
    </div>
    ${state.projects.length ? `<a class="btn-primary sm wobbly" href="#/p/new">${icon('plus', 18)} 새 작품</a>` : ''}
  </header>
  <nav class="home-chips">
    <a class="chip" href="#/patterns">${icon('book', 16)} 도안함</a>
    <a class="chip" href="#/stash">${icon('box', 16)} 보관함</a>
    <a class="chip" href="#/done">${icon('check', 16)} 완성작 ${done.length}</a>
  </nav>

  ${state.projects.length ? `
    <ul class="cards">
      ${items.map(cardHTML).join('') || `<li>${emptyStateHTML({ title: '지금 뜨는 작품이 없어요', message: '새 작품을 시작하거나<br>도안함에 저장해 둔 도안으로 바로 시작해 보세요.', button: `<a class="btn-primary wobbly" href="#/p/new">${icon('plus', 18)} 새 작품 만들기</a>${done.length ? `<a class="chip" href="#/done">${icon('check', 16)} 완성한 작품 보기</a>` : ''}`, cls: 'tab-empty' })}</li>`}
    </ul>
  ` : `
    ${emptyStateHTML({ title: '첫 작품을 시작해 보세요', message: '단수를 세고, 반복 작업을 알려주고,<br>실과 바늘 정보도 함께 기억해 둘게요.', button: `<a class="btn-primary wobbly" href="#/p/new">${icon('plus', 18)} 새 작품 만들기</a><a class="chip" href="#/patterns">${icon('book', 16)} 도안함</a>` })}
  `}

  <footer class="foot">
    <button class="link-btn" data-action="export">백업 내보내기</button>
    <span aria-hidden="true">·</span>
    <label class="link-btn">백업 가져오기<input type="file" accept="application/json,.json" data-action="import" hidden></label>
    <span aria-hidden="true">·</span>
    <a class="link-btn" href="#/stash">실·바늘 보관함</a>
    <span aria-hidden="true">·</span>
    <a class="link-btn" href="#/done">완성한 작품</a>
    <span aria-hidden="true">·</span>
    <button class="link-btn" data-action="settings">설정</button>
  </footer>`;
}

/* ---------- 화면: 카운터 ---------- */
// 순서 카운터 한 칸 움직이기: d=1 다음, -1 이전. whole이면 이번 반복을 바로 끝내요
function moveStep(p, c, d, whole = false) {
  const n = c.steps.length;
  let msg = null, roundDone = false, allDone = false, rowUp = false;
  if (d < 0) {
    if (c.step === 0 && c.value === 0) return;
    pushUndo(p);
    if (c.step > 0) c.step--; else { c.value--; c.step = n - 1; }
  } else {
    pushUndo(p);
    if (isFinished(c)) { c.value = 0; c.step = 0; msg = `${c.name} 처음부터 다시 세요`; }
    else {
      c.step = whole ? n : c.step + 1;
      if (c.step >= n) {
        c.step = 0; c.value++; roundDone = true;
        if (c.max && c.value >= c.max) {
          allDone = true;
          if (c.rowOnFinish) { c.value = 0; rowUp = true; msg = `${c.name} ${c.max}번 끝! ${p.row + 1}단으로 넘어가요`; }
          else msg = `${c.name} ${c.max}번 반복 완료!`;
        } else msg = c.max ? `${c.value}번째 끝 · ${c.value + 1}/${c.max}번째 시작` : `${c.value}번째 끝`;
      }
    }
  }
  if (rowUp) {
    p.row++;
    const k = todayKey();
    p.log[k] = (p.log[k] || 0) + 1;
    const hits = hitsAt(p, p.row);
    if (hits.length) msg += `\n${p.row}단: ` + hits.map((h) => h.r.label).join(', ');
  }
  touch(p); save();
  buzz(allDone ? [30, 50, 30, 50, 80] : roundDone ? [40, 40, 40] : 12);
  if (msg) toast(msg);
}

function stepCounterHTML(p, c) {
  const id = esc(c.id), name = esc(c.name), n = c.steps.length, cur = Math.min(c.step, n - 1);
  const done = isFinished(c);
  const now = done ? c.max : c.value + 1;
  let next;
  if (cur + 1 < n) next = c.steps[cur + 1];
  else if (c.max && c.value + 2 > c.max) next = c.rowOnFinish ? '반복 끝 · 다음 단으로' : '반복 끝';
  else next = `${c.steps[0]} (${c.value + 2}번째)`;
  return `
  <li class="sub seq">
    <div class="seq-head">
      <div class="sub-name">${name}</div>
      <button class="seq-round" data-action="step-round" data-id="${id}" ${done ? 'disabled' : ''} title="남은 단계를 건너뛰고 이번 반복 끝내기"><b>${now}</b><span>${c.max ? ` / ${c.max}번째` : '번째'}</span></button>
      <button class="icon-btn sm" data-action="counter-menu" data-id="${id}" aria-label="${name} 설정">${icon('more')}</button>
    </div>
    ${done ? `<div class="seq-done">${icon('check', 18)} ${c.max}번 반복 완료<div class="muted xsmall">다음을 누르면 처음부터 다시 세요</div></div>` : `
    <div class="seq-now" aria-live="polite"><span class="muted xsmall">지금</span><b>${esc(c.steps[cur])}</b></div>
    <div class="seq-next"><span class="muted xsmall">다음</span><span class="muted">${esc(next)}</span></div>
    <div class="seq-dots" aria-hidden="true">${c.steps.map((_, i) => `<i class="${i < cur ? 'past' : i === cur ? 'cur' : ''}"></i>`).join('')}</div>`}
    <div class="seq-btns">
      <button class="seq-back" data-action="step" data-id="${id}" data-d="-1" aria-label="한 단계 뒤로" ${c.value === 0 && c.step === 0 ? 'disabled' : ''}>${icon('undo', 20)}</button>
      <button class="seq-go" data-action="step" data-id="${id}" data-d="1">${done ? '처음부터' : `다음 단계 ${icon('chev', 18)}`}</button>
    </div>
  </li>`;
}

function subCounterHTML(p, c) {
  if (c.steps.length) return stepCounterHTML(p, c);
  const v = counterValue(c, p.row);
  const id = esc(c.id);
  const name = esc(c.name);
  return `
  <li class="sub">
    <div class="sub-info">
      <div class="sub-name">${name} ${c.linked ? `<span class="badge">${icon('link', 12)} 단 연동</span>` : ''}</div>
      <div class="sub-val"><b>${v}</b>${c.max ? `<span class="muted"> / ${c.max}</span>` : ''}</div>
    </div>
    <div class="sub-btns">
      ${c.linked ? '' : `
        <button class="round" data-action="cnt" data-id="${id}" data-d="-1" aria-label="${name} 1 빼기">−</button>
        <button class="round accent" data-action="cnt" data-id="${id}" data-d="1" aria-label="${name} 1 더하기">+</button>`}
      <button class="icon-btn sm" data-action="counter-menu" data-id="${id}" aria-label="${name} 설정">${icon('more')}</button>
    </div>
  </li>`;
}

// 오늘 뜬 단 수와 지금 코 수를 한 줄로 (색 없이)
// 늘림·줄임 횟수는 그 단이 되면 "N단에서 할 일" 카드에 나오므로 여기선 빼요
function statusLineHTML(p, today) {
  const st = stitchCount(p);
  return `<div class="today">오늘 ${today}단 떴어요${st != null ? ` · 지금 ${st}코` : ''}</div>`;
}

function reminderHTML(p, r) {
  const idx = remIndex(r, p.row);
  const n = nextHit(r, p.row);
  const rule = [KIND_LABEL[r.kind] ? `${KIND_LABEL[r.kind]} ${r.stitches}코씩` : '', `${r.every}단마다`, r.from !== r.every ? `${r.from}단부터` : '', r.times ? `총 ${r.times}회` : '']
    .filter(Boolean).join(' · ');
  let right;
  if (idx >= 0) right = `<b>이번 단</b>${r.times ? `<div class="xsmall">${idx + 1}/${r.times}회</div>` : ''}`;
  else if (n) right = `${n.row}단<div class="muted xsmall">${n.row - p.row}단 후</div>`;
  else right = `<span class="muted">완료</span>`;
  return `
  <li class="rem ${idx >= 0 ? 'hit' : ''}">
    <div><div class="rem-label">${esc(r.label)}</div><div class="muted xsmall">${rule}</div></div>
    <div class="rem-next">${right}</div>
  </li>`;
}

function renderCounter(p, bump = false) {
  document.title = `${p.name} · 뜨개노트`;
  const hits = hitsAt(p, p.row);
  const pct = p.targetRows ? Math.min(100, (p.row / p.targetRows) * 100) : null;
  const today = p.log[todayKey()] || 0;
  const meta = [p.yarn, p.needle].filter(Boolean).map(esc).join(' · ');

  $app.innerHTML = `
  <header class="bar">
    <a class="icon-btn" href="#/" aria-label="목록으로">${icon('back', 24)}</a>
    <h1 class="bar-title">${esc(p.name)}</h1>
    <a class="icon-btn" href="#/p/${enc(p.id)}/edit" aria-label="작품 정보 수정">${icon('edit')}</a>
  </header>
  ${p.status === 'paused' ? pausedBannerHTML(p) : ''}
  ${meta ? `<p class="muted small" style="text-align:center;margin:0">${meta}</p>` : ''}

  ${p.guide.length ? `
  <section class="main-counter compact" aria-live="polite">
    <div class="row-num ${bump ? 'bump' : ''}">${guideRowNo(p)}<small>${p.targetRows ? `/ ${p.targetRows}단` : '단째'}</small>${p.status === 'done' ? ` <span class="badge">${icon('check', 12)} 완성</span>` : ''}</div>
    ${pct !== null ? `<div class="progress"><span style="width:${pct}%"></span></div>` : ''}
    ${statusLineHTML(p, today)}
  </section>` : `
  <section class="main-counter" aria-live="polite">
    <div class="row-label">현재 단 ${p.status === 'done' ? `<span class="badge">${icon('check', 12)} 완성</span>` : ''}</div>
    <div class="row-num ${bump ? 'bump' : ''}">${p.row}<small>단</small></div>
    ${pct !== null ? `
      <div class="target">목표 ${p.targetRows}단 · ${Math.round(pct)}%${p.row < p.targetRows ? ` · ${p.targetRows - p.row}단 남음` : ''}</div>
      <div class="progress"><span style="width:${pct}%"></span></div>` : ''}
    ${statusLineHTML(p, today)}
  </section>

  <div class="tap-row">
    <button class="btn-minus" data-action="row" data-d="-1" aria-label="1단 빼기">−</button>
    <button class="btn-plus" data-action="row" data-d="1" aria-label="1단 더하기">+1단</button>
  </div>
  <div class="sub-actions">
    <button class="chip" data-action="undo" ${canUndo(p) ? '' : 'disabled'}>${icon('undo', 16)} 되돌리기</button>
    <button class="chip" data-action="set-row">단 직접 입력</button>
  </div>`}

  ${hits.length ? `
  <div class="alert" role="alert">
    ${icon('bell')}
    <div>
      <b>${p.row}단에서 할 일</b>
      <ul>${hits.map((h) => `<li>${esc(h.r.label)}${h.r.times ? ` (${h.i + 1}/${h.r.times}회)` : ''}</li>`).join('')}</ul>
    </div>
  </div>` : ''}

  ${guideCardHTML(p)}
  ${p.guide.length ? `
  <div class="tap-row small">
    <button class="btn-minus" data-action="row" data-d="-1" aria-label="1단 빼기">−</button>
    <button class="btn-plus" data-action="guide-row" aria-label="1단 더하기">+1단 · 단계 없이 이 단 끝</button>
  </div>
  <div class="sub-actions">
    <button class="chip" data-action="undo" ${canUndo(p) ? '' : 'disabled'}>${icon('undo', 16)} 되돌리기</button>
    <button class="chip" data-action="set-row">단 직접 입력</button>
  </div>` : ''}

  ${patternSectionHTML(p)}

  ${materialsSectionHTML(p)}

  <section class="section">
    <div class="section-head">
      <h2>반복 알림</h2>
      <a class="chip" href="#/p/${enc(p.id)}/edit">${p.reminders.length ? '편집' : `${icon('plus', 16)} 추가`}</a>
    </div>
    ${p.reminders.length
      ? `<ul class="rems">${p.reminders.map((r) => reminderHTML(p, r)).join('')}</ul>`
      : `<p class="muted small hint">“6단마다 양쪽 1코 늘리기 × 8회”처럼 정해 두면 그 단에 도착했을 때 알려 드려요.</p>`}
  </section>

  <section class="section">
    <div class="section-head">
      <h2>보조 카운터</h2>
      <button class="chip" data-action="add-counter">${icon('plus', 16)} 추가</button>
    </div>
    ${p.counters.length
      ? `<ul class="sub-counters">${p.counters.map((c) => subCounterHTML(p, c)).join('')}</ul>`
      : `<p class="muted small hint">무늬 반복, 코 수처럼 따로 셀 것을 추가하세요. ‘단과 연동’을 켜면 단을 올릴 때 함께 올라가요. 뜨는 순서를 적어 두면 지금 몇 번째 반복의 어느 단계인지도 알려 줘요.</p>`}
  </section>

  <section class="section">
    <div class="section-head">
      <h2>변경 기록</h2>
      <button class="chip" data-action="add-change">${icon('plus', 16)} 추가</button>
    </div>
    ${p.changes.length
      ? `<ul class="changes">${p.changes.map((c) => `
        <li class="sub">
          <div class="sub-info"><div>${esc(c.text)}</div><div class="muted xsmall">${c.row}단 · ${new Date(c.date).getMonth() + 1}월 ${new Date(c.date).getDate()}일</div></div>
          <button class="icon-btn sm" data-action="del-change" data-id="${esc(c.id)}" aria-label="이 변경 기록 삭제">${icon('trash', 18)}</button>
        </li>`).join('')}</ul>`
      : `<p class="muted small hint">도안과 다르게 바꾼 점을 남겨 두세요. 몇 단에서 바꿨는지도 함께 기록돼요.</p>`}
  </section>

  <section class="section">
    <div class="section-head">
      <h2>제작 기록</h2>
      <button class="chip" data-action="record">${hasRecord(p) ? '편집' : `${icon('plus', 16)} 기록하기`}</button>
    </div>
    ${hasRecord(p) ? recordCardHTML(p) : `<p class="muted small hint">사용한 실, 게이지, 사이즈 수정, 실제 사용량을 남겨 두면 다음 작품에서 그대로 참고할 수 있어요.</p>`}
  </section>

  ${photosSectionHTML(p)}

  <section class="section">
    <div class="section-head"><h2><label for="notes">메모</label></h2></div>
    <textarea id="notes" class="notes" data-action="notes" placeholder="도안 페이지, 바꾼 부분, 기억할 점…">${esc(p.notes)}</textarea>
  </section>

  ${p.status === 'active' ? `<button class="btn-pause wobbly" data-action="pause">${icon('pause', 18)} 잠시 멈춤</button>` : ''}
  <button class="btn-done ${p.status === 'done' ? 'is-done' : ''}" data-action="toggle-done">
    ${p.status === 'done' ? '진행 중으로 되돌리기' : `${icon('check', 18)} 완성으로 표시`}
  </button>`;
}

function patternSectionHTML(p) {
  const ref = p.pattern;
  if (!ref) {
    return `
  <section class="section">
    <div class="section-head"><h2>도안</h2></div>
    <div class="hint pattern-empty">
      <p class="muted small">PDF·이미지 도안이나 웹 링크를 붙여 두면, 도안을 보면서 단을 세고 도안 위에 바로 필기할 수 있어요.</p>
      <div class="pattern-actions">
        <button class="chip" data-action="pattern-pdf">${icon('doc', 16)} PDF·이미지 불러오기</button>
        <button class="chip" data-action="pattern-web">${icon('link', 16)} 웹 링크</button>
        ${p.guide.length ? '' : `<button class="chip" data-action="guide-paste">${icon('edit', 16)} 단별 안내 직접 입력</button>`}
      </div>
    </div>
  </section>`;
  }
  const sub = ref.kind === 'pdf' ? (ref.image ? '이미지 도안' : `PDF · ${ref.page + 1}쪽부터`) : esc(ref.url);
  return `
  <section class="section">
    <div class="section-head">
      <h2>도안</h2>
      <button class="chip" data-action="pattern-menu">변경</button>
    </div>
    <a class="pattern-card" href="#/p/${enc(p.id)}/pattern">
      <span class="pattern-icon">${icon(ref.kind === 'pdf' ? 'doc' : 'globe', 22)}</span>
      <span class="pattern-info"><b>${esc(ref.title)}</b><small>${sub}</small></span>
      <span class="pattern-go">보면서 뜨기 ${icon('chev', 14)}</span>
    </a>
    ${p.guide.length ? '' : `<div class="pattern-actions guide-read">
      ${ref.kind === 'pdf' ? `<button class="chip" data-action="guide-read" ${readingGuide ? 'disabled' : ''}>${icon('doc', 16)} ${readingGuide ? '도안 읽는 중…' : '도안에서 단 읽기'}</button>` : ''}
      <button class="chip" data-action="guide-paste">${icon('edit', 16)} 단별 안내 직접 입력</button>
    </div>`}
  </section>`;
}

/* ---------- 화면: 도안 보면서 뜨기 (위: 도안 / 아래: 작은 카운터) ---------- */
let markerOn = false;
let markerY = 120;

function miniBarHTML(p, bump = false) {
  const hits = hitsAt(p, p.row);
  return `
    ${hits.length ? `<div class="mini-alert" role="status">${icon('bell', 16)} ${hits.map((h) => esc(h.r.label)).join(', ')}</div>` : ''}
    <div class="mini-row">
      <button class="mini-minus" data-action="row" data-d="-1" aria-label="1단 빼기">−</button>
      <div class="mini-num" aria-live="polite"><b class="${bump ? 'bump' : ''}">${p.row}</b><span>${p.targetRows ? `/ ${p.targetRows}단` : '단'}</span></div>
      <button class="btn-primary wobbly mini-plus" data-action="row" data-d="1" aria-label="1단 더하기">+1단</button>
    </div>`;
}

function renderPattern(p) {
  const ref = p.pattern;
  document.title = `${ref.title} · 뜨개노트`;
  const isWeb = ref.kind === 'web';
  markerOn = ref.markerY != null;
  markerY = ref.markerY ?? 120;
  inkMode = false;
  $app.innerHTML = `
  <div class="pattern-page">
    <header class="bar pattern-top">
      <a class="icon-btn" href="#/p/${enc(p.id)}" aria-label="작품 화면으로">${icon('back', 24)}</a>
      <h1 class="bar-title">${esc(ref.title)}</h1>
      ${isWeb ? `<a class="icon-btn" href="${esc(ref.url)}" target="_blank" rel="noopener noreferrer" aria-label="새 탭에서 열기">${icon('external')}</a>` : ''}
      ${isWeb ? '' : `<button class="icon-btn" data-action="ink" aria-pressed="false" aria-label="도안에 필기하기">${icon('ink')}</button>`}
      <button class="icon-btn ${markerOn ? 'on' : ''}" data-action="marker" aria-pressed="${markerOn}" aria-label="줄 표시">${icon('marker')}</button>
    </header>
    ${isWeb ? `<p class="pattern-note">페이지가 안 보이면 <a href="${esc(ref.url)}" target="_blank" rel="noopener noreferrer">새 탭에서 열기</a> — 많은 도안 사이트가 다른 화면 안에 띄우는 걸 막아 두었어요.</p>` : ''}
    <div class="pattern-stage">
      <div class="pattern-scroll" id="patternScroll">
        ${isWeb ? `<iframe src="${esc(ref.url)}" title="웹 도안" referrerpolicy="no-referrer"></iframe>` : `<div class="pattern-msg">도안을 불러오는 중…</div>`}
      </div>
      <div class="marker" style="top:${markerY}px" ${markerOn ? '' : 'hidden'} role="slider" aria-label="줄 표시 막대, 끌어서 옮겨요" aria-valuenow="${Math.round(markerY)}"><span>${icon('more', 16)}</span></div>
      ${isWeb ? '' : `<div class="zoom-ctrl"><button data-action="zoom" data-z="-1" aria-label="축소">−</button><span id="zoomLabel">100%</span><button data-action="zoom" data-z="1" aria-label="확대">+</button></div>`}
    </div>
    <div class="mini-bar" id="miniBar">${miniBarHTML(p)}</div>
  </div>`;
  if (!isWeb) mountPdf(p);
}

function updatePatternBar(p, bump) {
  const bar = document.getElementById('miniBar');
  if (bar) bar.innerHTML = inkMode ? inkBarHTML() : miniBarHTML(p, bump);
}

/* ---------- 도안 위 필기 (쪽마다, 쪽 크기에 대한 비율 좌표로 IndexedDB에 저장) ---------- */
const INK_TOOLS = {
  pen: { label: '펜', icon: 'pen', color: '#2b2420', width: 0.004, alpha: 1 },
  red: { label: '빨간 펜', icon: 'pen', color: '#c4553c', width: 0.004, alpha: 1 },
  hl: { label: '형광펜', icon: 'marker', color: '#f2cf4a', width: 0.024, alpha: 0.42 },
  eraser: { label: '지우개', icon: 'eraser', color: '#7a6b60' },
};
let inkMode = false;
let inkTool = 'pen';
let inkData = null;   // { key, pages: { [쪽 번호]: [{ tool, pts: [[x, y], …] }] } }
let inkUndo = [];

function inkBarHTML() {
  return `
    <div class="ink-row">
      ${Object.entries(INK_TOOLS).map(([k, t]) => `<button class="ink-tool ${inkTool === k ? 'on' : ''}" data-action="ink-tool" data-tool="${k}" aria-label="${t.label}" aria-pressed="${inkTool === k}" style="color:${t.color}">${icon(t.icon, 22)}</button>`).join('')}
      <button class="ink-tool" data-action="ink-undo" aria-label="필기 되돌리기" ${inkUndo.length ? '' : 'disabled'}>${icon('undo', 20)}</button>
      <button class="btn-primary wobbly ink-done" data-action="ink">완료</button>
    </div>`;
}

async function loadInk(fileName) {
  const key = 'ink-' + fileName;
  let pages = {};
  try { pages = (await idb.get(key)) || {}; } catch { /* 없으면 빈 필기 */ }
  inkData = { key, pages };
  inkUndo = [];
}
function saveInk() {
  if (!inkData) return;
  const { key, pages } = inkData;
  clearTimeout(saveInk.timer);
  saveInk.timer = setTimeout(() => idb.put(key, pages).catch(() => toast('필기를 저장하지 못했어요')), 300);
}
function drawStroke(ctx, st, w, h) {
  const t = INK_TOOLS[st.tool] || INK_TOOLS.pen;
  ctx.save();
  ctx.globalAlpha = t.alpha;
  ctx.strokeStyle = t.color;
  ctx.lineWidth = t.width * w;
  ctx.lineCap = st.tool === 'hl' ? 'butt' : 'round';
  ctx.lineJoin = 'round';
  ctx.beginPath();
  st.pts.forEach(([x, y], k) => (k ? ctx.lineTo(x * w, y * h) : ctx.moveTo(x * w, y * h)));
  if (st.pts.length === 1) ctx.lineTo(st.pts[0][0] * w + 0.5, st.pts[0][1] * h);
  ctx.stroke();
  ctx.restore();
}
function drawInk(canvas) {
  const i = Number(canvas.parentElement?.dataset.i);
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  for (const st of inkData?.pages[i] || []) drawStroke(ctx, st, canvas.width, canvas.height);
}
function redrawInkPage(i) {
  const c = document.querySelector(`.pdf-page[data-i="${i}"] canvas.ink`);
  if (c) drawInk(c);
}
function setInkMode(on) {
  inkMode = on;
  document.querySelector('.pattern-page')?.classList.toggle('inking', on);
  const btn = document.querySelector('[data-action="ink"].icon-btn');
  if (btn) { btn.classList.toggle('on', on); btn.setAttribute('aria-pressed', on); }
  if (current) updatePatternBar(current);
}
function undoInk() {
  const a = inkUndo.pop();
  if (!a || !inkData) return;
  const list = inkData.pages[a.page] || (inkData.pages[a.page] = []);
  if (a.type === 'add') {
    const k = list.indexOf(a.stroke);
    if (k >= 0) list.splice(k, 1);
  } else {
    list.push(...a.strokes);
  }
  redrawInkPage(a.page);
  saveInk();
  if (current) updatePatternBar(current);
}

// 필기: 손가락·펜·마우스로 그리기 (필기 모드일 때만)
document.addEventListener('pointerdown', (e) => {
  const c = e.target.closest?.('canvas.ink');
  if (!c || !inkMode || !inkData) return;
  e.preventDefault();
  try { c.setPointerCapture(e.pointerId); } catch { /* 계속 */ }
  const i = Number(c.parentElement.dataset.i);
  const r = c.getBoundingClientRect();
  const pt = (ev) => [+((ev.clientX - r.left) / r.width).toFixed(4), +((ev.clientY - r.top) / r.height).toFixed(4)];
  const list = inkData.pages[i] || (inkData.pages[i] = []);
  let move;
  let done;
  if (inkTool === 'eraser') {
    const erased = [];
    const eraseAt = (ev) => {
      const [x, y] = pt(ev);
      for (let k = list.length - 1; k >= 0; k--) {
        if (list[k].pts.some(([px, py]) => Math.hypot(px - x, (py - y) * (r.height / r.width)) < 0.025)) erased.push(...list.splice(k, 1));
      }
      drawInk(c);
    };
    eraseAt(e);
    move = eraseAt;
    done = () => { if (erased.length) inkUndo.push({ type: 'erase', page: i, strokes: erased }); };
  } else {
    const stroke = { tool: inkTool, pts: [pt(e)] };
    list.push(stroke);
    drawInk(c);
    move = (ev) => {
      const evs = ev.getCoalescedEvents?.();
      for (const ce of evs && evs.length ? evs : [ev]) stroke.pts.push(pt(ce));
      drawInk(c);
    };
    done = () => inkUndo.push({ type: 'add', page: i, stroke });
  }
  const up = () => {
    c.removeEventListener('pointermove', move);
    c.removeEventListener('pointerup', up);
    c.removeEventListener('pointercancel', up);
    done();
    saveInk();
    if (current) updatePatternBar(current);
  };
  c.addEventListener('pointermove', move);
  c.addEventListener('pointerup', up);
  c.addEventListener('pointercancel', up);
});

/** 화면에 맞춰 다시 그리기: 도안 화면이면 아래 카운터만 */
function refresh(p, bump = false) {
  if (view === 'pattern') updatePatternBar(p, bump);
  else renderCounter(p, bump);
}

// 줄 표시 막대 끌기
document.addEventListener('pointerdown', (e) => {
  const m = e.target.closest?.('.marker');
  if (!m) return;
  e.preventDefault();
  try { m.setPointerCapture(e.pointerId); } catch { /* 일부 환경에서 실패해도 끌기는 계속 */ }
  const startY = e.clientY;
  const startTop = markerY;
  const stage = m.parentElement;
  const move = (ev) => {
    markerY = Math.min(Math.max(0, startTop + ev.clientY - startY), stage.clientHeight - m.offsetHeight);
    m.style.top = `${markerY}px`;
    m.setAttribute('aria-valuenow', Math.round(markerY));
  };
  const up = () => {
    m.removeEventListener('pointermove', move);
    m.removeEventListener('pointerup', up);
    m.removeEventListener('pointercancel', up);
    if (current?.pattern) { current.pattern.markerY = Math.round(markerY); save(); }
  };
  m.addEventListener('pointermove', move);
  m.addEventListener('pointerup', up);
  m.addEventListener('pointercancel', up);
});

/* ---------- PDF 보기 (pdf.js, 처음 쓸 때만 불러와요) ---------- */
const PDFJS = 'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174';
let pdfjsPromise = null;
function loadPdfJs() {
  if (window.pdfjsLib) return Promise.resolve(window.pdfjsLib);
  return pdfjsPromise || (pdfjsPromise = new Promise((res, rej) => {
    const s = document.createElement('script');
    s.src = `${PDFJS}/pdf.min.js`;
    s.onload = () => {
      window.pdfjsLib.GlobalWorkerOptions.workerSrc = `${PDFJS}/pdf.worker.min.js`;
      res(window.pdfjsLib);
    };
    s.onerror = () => { pdfjsPromise = null; s.remove(); rej(new Error('pdf.js')); };
    document.head.appendChild(s);
  }));
}

const ZOOMS = [1, 1.5, 2, 3];
let pdfSession = null;

function closePdf() {
  if (!pdfSession) return;
  pdfSession.observer?.disconnect();
  pdfSession.doc?.destroy();
  pdfSession = null;
}

/** 이미지 한 장을 pdf.js 문서처럼 다뤄요 (쪽 1개) */
async function imageDoc(blob) {
  const url = URL.createObjectURL(blob);
  const img = new Image();
  img.src = url;
  await img.decode();
  const w = img.naturalWidth, h = img.naturalHeight;
  const viewport = (scale) => ({ width: w * scale, height: h * scale });
  return {
    numPages: 1,
    ratio: h / w,
    destroy: () => URL.revokeObjectURL(url),
    getPage: async () => ({
      getViewport: ({ scale }) => viewport(scale),
      render: ({ canvasContext, viewport: vp }) => ({ promise: Promise.resolve(canvasContext.drawImage(img, 0, 0, vp.width, vp.height)) }),
    }),
  };
}

async function mountPdf(p) {
  const scroll = document.getElementById('patternScroll');
  const ref = p.pattern;
  const showMsg = (html) => { if (scroll.isConnected) scroll.innerHTML = `<div class="pattern-msg">${html}</div>`; };
  let blob;
  try { blob = await idb.get(ref.fileName); } catch { /* 아래에서 안내 */ }
  if (!blob) {
    showMsg(`이 기기에서 도안 파일을 찾을 수 없어요.<br>백업으로 옮겨 왔다면 파일을 다시 불러와 주세요.<br><button class="chip" data-action="pattern-pdf">${icon('doc', 16)} 다시 불러오기</button>`);
    return;
  }
  await loadInk(ref.fileName);
  if (blob.type.startsWith('image/') || ref.image) {
    const doc = await imageDoc(blob).catch(() => null);
    if (!doc) { showMsg('이미지를 열 수 없어요. 파일이 손상됐을 수 있어요.'); return; }
    if (view !== 'pattern' || current !== p || !scroll.isConnected) { doc.destroy(); return; }
    closePdf();
    pdfSession = { doc, pid: p.id, ratio: doc.ratio, zoomIdx: 0, lastPage: 0 };
    layoutPdf(0);
    return;
  }
  let lib;
  try { lib = await loadPdfJs(); } catch {
    showMsg('PDF 보기 도구를 불러오지 못했어요.<br>인터넷 연결을 확인하고 다시 열어 주세요.');
    return;
  }
  let doc;
  try {
    doc = await lib.getDocument({ data: new Uint8Array(await blob.arrayBuffer()) }).promise;
  } catch {
    showMsg('PDF를 열 수 없어요. 파일이 손상됐을 수 있어요.');
    return;
  }
  if (view !== 'pattern' || current !== p || !scroll.isConnected) { doc.destroy(); return; }
  const first = await doc.getPage(1);
  const vp = first.getViewport({ scale: 1 });
  closePdf();
  pdfSession = { doc, pid: p.id, ratio: vp.height / vp.width, zoomIdx: 0, lastPage: ref.page };
  layoutPdf(ref.page);
}

function layoutPdf(startPage, anchor = null) {
  const s = pdfSession;
  const scroll = document.getElementById('patternScroll');
  if (!s || !scroll) return;
  const zoom = ZOOMS[s.zoomIdx];
  const width = Math.floor((scroll.clientWidth - 16) * zoom);
  s.width = width;
  s.gap = 8;
  s.height = Math.round(width * s.ratio);
  s.observer?.disconnect();
  scroll.innerHTML = Array.from({ length: s.doc.numPages }, (_, i) =>
    `<div class="pdf-page" data-i="${i}" style="width:${width}px;height:${s.height}px" aria-label="${i + 1}쪽"><canvas class="ink"></canvas></div>`).join('');
  const dprInk = Math.min(window.devicePixelRatio || 1, 2.5);
  scroll.querySelectorAll('canvas.ink').forEach((c) => {
    c.width = Math.round(width * dprInk);
    c.height = Math.round(s.height * dprInk);
    drawInk(c);
  });
  s.observer = new IntersectionObserver((entries) => {
    for (const en of entries) if (en.isIntersecting) renderPdfPage(en.target, s);
  }, { root: scroll, rootMargin: '800px 0px' });
  scroll.querySelectorAll('.pdf-page').forEach((el) => s.observer.observe(el));
  const label = document.getElementById('zoomLabel');
  if (label) label.textContent = `${Math.round(zoom * 100)}%`;
  if (anchor) {
    // 확대·축소해도 보던 쪽의 같은 위치를 유지
    scroll.scrollTop = (anchor.idx + anchor.within) * (s.height + s.gap) - scroll.clientHeight * 0.3;
  } else {
    const target = scroll.querySelector(`.pdf-page[data-i="${Math.min(startPage, s.doc.numPages - 1)}"]`);
    if (target) scroll.scrollTop = target.offsetTop - s.gap;
  }
  scroll.onscroll = () => {
    if (s.tick) return;
    s.tick = requestAnimationFrame(() => {
      s.tick = 0;
      const i = Math.min(s.doc.numPages - 1, Math.floor((scroll.scrollTop + scroll.clientHeight * 0.3) / (s.height + s.gap)));
      if (i === s.lastPage) return;
      s.lastPage = i;
      const proj = find(s.pid);
      if (proj?.pattern?.kind === 'pdf') { proj.pattern.page = i; clearTimeout(s.saveTimer); s.saveTimer = setTimeout(save, 500); }
    });
  };
}

async function renderPdfPage(el, s) {
  if (el.dataset.rendered || pdfSession !== s) return;
  el.dataset.rendered = '1';
  try {
    const page = await s.doc.getPage(Number(el.dataset.i) + 1);
    const scale = s.width / page.getViewport({ scale: 1 }).width;
    const dpr = Math.min(window.devicePixelRatio || 1, 2.5);
    const vp = page.getViewport({ scale: scale * dpr });
    const canvas = document.createElement('canvas');
    canvas.width = Math.floor(vp.width);
    canvas.height = Math.floor(vp.height);
    await page.render({ canvasContext: canvas.getContext('2d'), viewport: vp }).promise;
    canvas.className = 'page';
    if (pdfSession === s && el.isConnected) el.prepend(canvas);
  } catch {
    el.dataset.rendered = '';
  }
}

function changeZoom(d) {
  const s = pdfSession;
  const scroll = document.getElementById('patternScroll');
  if (!s || !scroll) return;
  const idx = Math.min(ZOOMS.length - 1, Math.max(0, s.zoomIdx + d));
  if (idx === s.zoomIdx) return;
  const unit = s.height + s.gap;
  const pos = (scroll.scrollTop + scroll.clientHeight * 0.3) / unit; // ‘보는 쪽’ 판단과 같은 기준선
  const anchor = { idx: Math.floor(pos), within: pos - Math.floor(pos) };
  s.zoomIdx = idx;
  layoutPdf(s.lastPage, anchor);
}

function openPatternMenu(p) {
  openDialog({
    title: '도안 바꾸기',
    body: `
      <div class="menu-list">
        <button value="pdf" class="menu-item" formnovalidate>${icon('doc')} PDF로 바꾸기</button>
        <button value="web" class="menu-item" formnovalidate>${icon('link')} 웹 링크로 바꾸기</button>
        <button value="library" class="menu-item" formnovalidate>${icon('book')} 도안함에 저장</button>
        <button value="remove" class="menu-item danger" formnovalidate>${icon('trash')} 도안 빼기</button>
      </div>`,
    submitLabel: '닫기',
    onAction(v) {
      if (v === 'pdf') pickPatternPDF(p);
      else if (v === 'web') setTimeout(() => openWebPatternDialog(p), 0);
      else if (v === 'library') savePatternFromProject(p);
      else if (v === 'remove') {
        if (!confirm('이 작품에서 도안을 뺄까요?')) return false;
        setPattern(p, null);
        renderCounter(p);
        toast('도안을 뺐어요');
      }
    },
  });
}

function openWebPatternDialog(p) {
  openDialog({
    title: '웹 도안 링크',
    body: `
      <label class="field"><span>도안이 있는 웹 페이지 주소</span>
        <input name="url" type="text" inputmode="url" autocomplete="off" autocapitalize="off" spellcheck="false" required placeholder="https://" value="${esc(p.pattern?.url || '')}"></label>
      <p class="muted xsmall" style="margin:0">많은 도안 사이트는 다른 화면 안에 페이지를 띄우는 걸 막아 두었어요. 그럴 땐 ‘새 탭에서 열기’로 보고, 단은 이 화면 아래 카운터로 세면 돼요.</p>`,
    submitLabel: '추가',
    onAction(v, fd) {
      const url = normalizedWebURL(fd.get('url'));
      if (!url) { toast('링크 주소를 확인해 주세요'); return false; }
      setPattern(p, { kind: 'web', title: new URL(url).hostname.replace(/^www\./, ''), url, page: 0 });
      go(`/p/${enc(p.id)}/pattern`);
    },
  });
}

function pausedBannerHTML(p) {
  const when = p.pausedAt ? `${new Date(p.pausedAt).getMonth() + 1}월 ${new Date(p.pausedAt).getDate()}일` : '';
  const where = [`${p.row}단`, p.needle ? esc(p.needle) : '', p.pattern?.kind === 'pdf' && !p.pattern.image ? `도안 ${p.pattern.page + 1}쪽` : ''].filter(Boolean).join(' · ');
  return `
  <div class="alert paused-banner" role="status">
    ${icon('pause')}
    <div>
      <b>잠시 멈춘 작품이에요</b> <span class="xsmall">${when}</span>
      ${p.resumeNote ? `<p class="resume-text">“${esc(p.resumeNote)}”</p>` : ''}
      <p class="xsmall" style="margin:4px 0 10px">${where}</p>
      <button class="btn-primary wobbly sm" data-action="resume">${icon('play', 16)} 다시 시작</button>
    </div>
  </div>`;
}

function openPauseDialog(p) {
  openDialog({
    title: '잠시 멈출까요?',
    body: `<label class="field"><span>어디까지 했는지 <em>(선택)</em></span>
      <input name="note" maxlength="200" value="${esc(p.resumeNote)}" placeholder="예: 왼쪽 소매 12단, 바늘에 걸어 둠"></label>
      <p class="muted xsmall" style="margin:0">다시 시작할 때 이 메모와 단수·바늘이 함께 보여요.</p>`,
    submitLabel: '멈춤',
    onAction(v, fd) {
      p.status = 'paused';
      p.pausedAt = Date.now();
      p.resumeNote = String(fd.get('note') || '').trim().slice(0, 200);
      touch(p);
      save();
      renderCounter(p);
      toast('잠시 멈췄어요. 목록의 ‘멈춤’에 있어요');
    },
  });
}

function openChangeDialog(p) {
  openDialog({
    title: '변경 기록 추가',
    body: `<label class="field"><span>바꾼 내용</span>
      <input name="text" required maxlength="300" placeholder="예: 소매 5단 더 길게"></label>
      <p class="muted xsmall" style="margin:0">지금 ${p.row}단으로 함께 기록돼요.</p>`,
    submitLabel: '추가',
    onAction(v, fd) {
      const text = String(fd.get('text') || '').trim();
      if (!text) return false;
      p.changes.unshift({ id: uid(), date: Date.now(), row: p.row, text });
      touch(p);
      save();
      renderCounter(p);
    },
  });
}

/* ---------- 화면: 작품 만들기 / 수정 ---------- */
function remRowHTML(r = {}) {
  const group = `r-kind-${esc(r.id || uid())}`; // 한 줄의 종류 버튼은 같은 그룹이어야 하나만 골라져요
  return `
  <div class="rem-row" data-id="${esc(r.id || '')}" data-kind="${r.kind || 'note'}">
    <div class="seg" role="radiogroup" aria-label="종류">
      ${[['note', '기타'], ['inc', '늘림'], ['dec', '줄임']].map(([k, l]) => `<label><input type="radio" name="${group}" data-kind value="${k}" ${(r.kind || 'note') === k ? 'checked' : ''}><span>${l}</span></label>`).join('')}
    </div>
    <input name="r-label" maxlength="80" placeholder="할 일 (예: 양쪽 1코씩 늘리기)" value="${esc(r.label || '')}" aria-label="할 일">
    <label class="rem-stitches"><span>한 번에</span><input name="r-stitches" type="number" inputmode="numeric" min="0" value="${r.stitches || ''}" placeholder="2" aria-label="한 번에 바뀌는 코 수"><span>코씩</span></label>
    <div class="rem-nums">
      <label><input name="r-every" type="number" inputmode="numeric" min="1" value="${r.every || ''}" placeholder="6" aria-label="몇 단마다">단마다</label>
      <label><input name="r-from" type="number" inputmode="numeric" min="1" value="${r.from && r.from !== r.every ? r.from : ''}" placeholder="–" aria-label="시작 단">단부터</label>
      <label><input name="r-times" type="number" inputmode="numeric" min="0" value="${r.times || ''}" placeholder="∞" aria-label="반복 횟수">회</label>
      <button type="button" class="icon-btn sm" data-action="del-rem" aria-label="이 알림 삭제">${icon('trash', 18)}</button>
    </div>
  </div>`;
}

function renderForm(p) {
  const isNew = !p;
  const d = p || { name: '', yarn: '', needle: '', targetRows: 0, notes: '', reminders: [] };
  document.title = `${isNew ? '새 작품' : '작품 정보'} · 뜨개노트`;
  const back = isNew ? '#/' : `#/p/${enc(p.id)}`;

  $app.innerHTML = `
  <header class="bar">
    <a class="icon-btn" href="${back}" aria-label="뒤로">${icon('back', 24)}</a>
    <h1 class="bar-title">${isNew ? '새 작품' : '작품 정보'}</h1>
    <span class="bar-spacer"></span>
  </header>

  <form id="projForm" class="form" novalidate>
    ${isNew && state.projects.some(hasRecord) ? `
    <label class="field"><span>이전 작품 기록 가져오기 <em>(실·바늘·게이지)</em></span>
      <select data-action="copy-record">
        <option value="">고르지 않음</option>
        ${state.projects.filter(hasRecord).sort((a, b) => b.updatedAt - a.updatedAt).map((o) => `<option value="${esc(o.id)}">${esc(o.name)}</option>`).join('')}
      </select>
    </label>` : ''}
    <input type="hidden" name="gauge" value="">
    <label class="field"><span>작품 이름</span>
      <input name="name" maxlength="60" required value="${esc(d.name)}" placeholder="예: 겨울 목도리" autocomplete="off">
    </label>
    <div class="grid2">
      <label class="field"><span>실</span><input name="yarn" maxlength="80" value="${esc(d.yarn)}" placeholder="예: 메리노 울 그레이"></label>
      <label class="field"><span>바늘</span><input name="needle" maxlength="40" value="${esc(d.needle)}" placeholder="예: 4.5mm 대바늘"></label>
    </div>
    <div class="grid2">
      <label class="field"><span>목표 단수 <em>(선택)</em></span>
        <input name="targetRows" type="number" inputmode="numeric" min="0" value="${d.targetRows || ''}" placeholder="예: 120">
      </label>
      <label class="field"><span>시작 코 수 <em>(선택)</em></span>
        <input name="castOn" type="number" inputmode="numeric" min="0" value="${d.castOn || ''}" placeholder="예: 40">
      </label>
    </div>

    <fieldset>
      <legend>반복 알림</legend>
      <p class="muted xsmall legend-hint">시작 단을 비우면 첫 알림은 ‘몇 단마다’와 같은 단에서, 횟수를 비우면 끝없이 반복해요.</p>
      <div id="remList" style="display:grid;gap:10px">${d.reminders.map(remRowHTML).join('')}</div>
      <button type="button" class="chip add-rem" data-action="add-rem">${icon('plus', 16)} 알림 추가</button>
    </fieldset>

    <label class="field"><span>메모</span>
      <textarea name="notes" class="notes" placeholder="도안 출처, 게이지, 사이즈 등">${esc(d.notes)}</textarea>
    </label>

    <div class="form-actions">
      <button type="submit" class="btn-primary block">${isNew ? '작품 시작하기' : '저장'}</button>
      ${isNew ? '' : `<button type="button" class="danger-link" data-action="delete-project">이 작품 삭제</button>`}
    </div>
  </form>`;

  if (isNew) $app.querySelector('[name=name]').focus();
}

function submitForm(form) {
  const fd = new FormData(form);
  const name = String(fd.get('name') || '').trim();
  if (!name) {
    toast('작품 이름을 입력해 주세요');
    form.querySelector('[name=name]').focus();
    return;
  }
  const reminders = [...form.querySelectorAll('.rem-row')].map((row) => normRem({
    id: row.dataset.id,
    label: row.querySelector('[name=r-label]').value,
    every: row.querySelector('[name=r-every]').value,
    from: row.querySelector('[name=r-from]').value,
    times: row.querySelector('[name=r-times]').value,
    kind: row.querySelector('[data-kind]:checked')?.value,
    stitches: row.querySelector('[name=r-stitches]').value,
  })).filter(Boolean);

  const data = {
    name,
    yarn: String(fd.get('yarn') || '').trim(),
    needle: String(fd.get('needle') || '').trim(),
    targetRows: int(fd.get('targetRows')),
    castOn: int(fd.get('castOn')),
    notes: String(fd.get('notes') || ''),
    reminders,
  };
  if (!current && fd.get('gauge')) {
    try { data.gauge = normGauge(JSON.parse(fd.get('gauge'))); } catch { /* 무시 */ }
  }

  if (current) {
    Object.assign(current, data);
    touch(current);
    save();
    toast('저장했어요');
    go(`/p/${enc(current.id)}`, true);
  } else {
    const np = normalize({ ...data, id: uid(), createdAt: Date.now() });
    state.projects.push(np);
    listTab = 'active';
    save();
    go(`/p/${enc(np.id)}`, true);
  }
}

/* ---------- 다이얼로그 ---------- */
function openDialog({ title, body, submitLabel = '저장', extra = '', onAction }) {
  const dlg = document.createElement('dialog');
  dlg.className = 'sheet';
  dlg.innerHTML = `
    <form method="dialog" class="sheet-form">
      <h2>${title}</h2>
      ${body}
      <div class="sheet-actions">
        ${extra}
        <button value="cancel" class="btn-ghost" formnovalidate>취소</button>
        <button value="ok" class="btn-primary">${submitLabel}</button>
      </div>
    </form>`;
  document.body.appendChild(dlg);
  const form = dlg.querySelector('form');
  form.addEventListener('submit', (e) => {
    const v = e.submitter?.value || 'ok';
    if (v === 'cancel') return;
    if (onAction(v, new FormData(form)) === false) e.preventDefault();
  });
  dlg.addEventListener('close', () => dlg.remove());
  dlg.addEventListener('click', (e) => { if (e.target === dlg) dlg.close(); });
  dlg.showModal();
  const first = dlg.querySelector('input:not([type=checkbox]):not([type=file])');
  if (first) { first.focus(); first.select?.(); }
}

function openSetRow(p) {
  openDialog({
    title: '현재 단 입력',
    body: `<label class="field"><span>몇 단째인가요?</span>
      <input name="row" type="number" inputmode="numeric" min="0" max="99999" required value="${p.row}"></label>`,
    submitLabel: '적용',
    onAction(v, fd) {
      const n = Math.min(99999, int(fd.get('row')));
      if (n === p.row) return;
      pushUndo(p);
      p.row = n;
      touch(p);
      save();
      renderCounter(p, true);
    },
  });
}

function openCounterDialog(p, c) {
  const isNew = !c;
  openDialog({
    title: isNew ? '보조 카운터 추가' : '카운터 설정',
    body: `
      ${isNew ? `<div class="pattern-actions">
        <button type="button" class="chip" data-preset="무늬 반복" data-linked="1">무늬 반복</button>
        <button type="button" class="chip" data-preset="코 수">코 수</button>
        <button type="button" class="chip" data-preset="모티브">모티브</button>
        <button type="button" class="chip" data-preset="순서 반복" data-seq="1">순서 반복</button>
      </div>` : ''}
      <label class="field"><span>이름</span>
        <input name="name" required maxlength="30" value="${esc(c?.name || '')}" placeholder="예: 무늬 반복, 코 수"></label>
      <label class="field"><span class="max-label">${c?.steps.length ? '반복 횟수 <em>(예: 4번 반복이면 4)</em>' : '최대값 <em>(선택 · 넘으면 1로 돌아가요)</em>'}</span>
        <input name="max" type="number" inputmode="numeric" min="0" max="9999" value="${c?.max || ''}" placeholder="예: 8"></label>
      <label class="field"><span>뜨는 순서 <em>(선택 · 한 줄에 한 단계)</em></span>
        <textarea name="steps" rows="4" data-steps placeholder="짧은뜨기 1&#10;한길긴뜨기 1&#10;사슬뜨기 2&#10;한길긴뜨기 1">${esc((c?.steps || []).join('\n'))}</textarea></label>
      <label class="check seq-only" ${c?.steps.length ? '' : 'hidden'}><input type="checkbox" name="rowOnFinish" ${c?.rowOnFinish ? 'checked' : ''}>
        <span><b>반복을 다 끝내면 단 +1</b><br><span class="muted small">정한 횟수를 다 뜨면 단을 올리고 처음부터 다시 세요</span></span></label>
      <label class="check plain-only" ${c?.steps.length ? 'hidden' : ''}><input type="checkbox" name="linked" ${c?.linked ? 'checked' : ''}>
        <span><b>단과 연동</b><br><span class="muted small">단을 올리거나 내리면 이 카운터도 함께 움직여요</span></span></label>`,
    submitLabel: isNew ? '추가' : '저장',
    extra: isNew ? '' : `
      <button value="delete" class="btn-danger-ghost" formnovalidate>삭제</button>
      <button value="reset" class="btn-ghost" formnovalidate>${c?.steps.length ? '처음부터' : '0으로'}</button>`,
    onAction(v, fd) {
      if (v === 'delete') {
        if (!confirm(`‘${c.name}’ 카운터를 삭제할까요?`)) return false;
        p.counters = p.counters.filter((x) => x !== c);
      } else if (v === 'reset') {
        pushUndo(p);
        if (c.linked) c.offset = p.row;
        else { c.value = 0; c.step = 0; }
      } else {
        const name = String(fd.get('name') || '').trim();
        if (!name) { toast('이름을 입력해 주세요'); return false; }
        const max = Math.min(9999, int(fd.get('max')));
        const seq = normSteps({ steps: String(fd.get('steps') || '').split(/\n|→|->/), rowOnFinish: fd.get('rowOnFinish') === 'on' });
        const linked = !seq.steps.length && fd.get('linked') === 'on';
        if (isNew) {
          p.counters.push(normCounter({ name, max, linked, value: 0, offset: p.row, ...seq }));
        } else {
          if (seq.steps.join('\n') !== c.steps.join('\n')) c.step = 0;
          c.steps = seq.steps;
          c.rowOnFinish = seq.rowOnFinish;
          const curVal = counterValue(c, p.row);
          if (linked && !c.linked) c.offset = Math.max(0, p.row - curVal); // 지금 값에서 이어서 셈
          if (!linked && c.linked) c.value = curVal;
          Object.assign(c, { name, max, linked });
          if (!c.linked && c.max && c.value > c.max) c.value = c.max;
        }
      }
      touch(p);
      save();
      renderCounter(p);
    },
  });
}

function openSettings() {
  const s = state.settings;
  openDialog({
    title: '설정',
    body: `
      <label class="check"><input type="checkbox" name="haptics" ${s.haptics ? 'checked' : ''}>
        <span><b>진동</b><br><span class="muted small">단을 셀 때 짧게 진동해요 (지원하는 기기만)</span></span></label>
      <label class="check"><input type="checkbox" name="keepAwake" ${s.keepAwake ? 'checked' : ''}>
        <span><b>화면 켜두기</b><br><span class="muted small">카운터 화면에서는 화면이 꺼지지 않아요</span></span></label>
      <p class="muted xsmall" style="margin:0">작품 기록은 이 기기의 브라우저에만 저장돼요. 기기를 바꾸거나 브라우저 데이터를 지우기 전에 ‘백업 내보내기’를 해 두세요.</p>`,
    onAction(v, fd) {
      s.haptics = fd.get('haptics') === 'on';
      s.keepAwake = fd.get('keepAwake') === 'on';
      save();
      toast('설정을 저장했어요');
    },
  });
}

// 보조 카운터 빠른 추가: 이름과 ‘단과 연동’을 한 번에 채워요
document.addEventListener('click', (e) => {
  const b = e.target.closest?.('dialog [data-preset]');
  if (!b) return;
  const form = b.closest('form');
  form.elements.name.value = b.dataset.preset;
  form.elements.linked.checked = !!b.dataset.linked;
  if (b.dataset.seq) { form.elements.steps.focus(); }
});
// 순서를 적으면 ‘단과 연동’ 대신 ‘반복을 다 끝내면 단 +1’을 보여 줘요
document.addEventListener('input', (e) => {
  if (!e.target.matches?.('[data-steps]')) return;
  const form = e.target.closest('form');
  const has = e.target.value.trim() !== '';
  form.querySelector('.seq-only').hidden = !has;
  form.querySelector('.plain-only').hidden = has;
  form.querySelector('.max-label').innerHTML = has ? '반복 횟수 <em>(예: 4번 반복이면 4)</em>' : '최대값 <em>(선택 · 넘으면 1로 돌아가요)</em>';
});

// 반복 알림 종류가 ‘기타’면 코 수 칸을 숨겨요
document.addEventListener('change', (e) => {
  if (e.target.matches?.('[data-kind]')) e.target.closest('.rem-row').dataset.kind = e.target.value;
});

/* ---------- 백업 ---------- */
function exportData() {
  const payload = { app: 'tteugae-note', version: 1, exportedAt: new Date().toISOString(), ...state };
  const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `뜨개노트-백업-${todayKey()}.json`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  toast('백업 파일을 저장했어요');
}

async function importData(file) {
  if (!file) return;
  try {
    const data = JSON.parse(await file.text());
    if (!Array.isArray(data.projects)) throw new Error('bad');
    const incoming = data.projects.map(normalize);
    const inStash = normStash(data.stash);
    const extra = inStash.yarns.length + inStash.needles.length ? `, 실·바늘 ${inStash.yarns.length + inStash.needles.length}개` : '';
    if (!confirm(`작품 ${incoming.length}개${extra}를 가져올까요?\n이미 있는 같은 항목은 백업 내용으로 바뀌어요.`)) return;
    const map = new Map(state.projects.map((p) => [p.id, p]));
    incoming.forEach((p) => map.set(p.id, p));
    state.projects = [...map.values()];
    const mergeBy = (mine, theirs) => { const m = new Map(mine.map((x) => [x.id, x])); theirs.forEach((x) => m.set(x.id, x)); return [...m.values()]; };
    state.stash = { yarns: mergeBy(state.stash.yarns, inStash.yarns), needles: mergeBy(state.stash.needles, inStash.needles) };
    state.patterns = mergeBy(state.patterns, (Array.isArray(data.patterns) ? data.patterns : []).map(normSavedPattern).filter(Boolean));
    save();
    renderList();
    toast(`${incoming.length}개 작품을 가져왔어요`);
  } catch {
    toast('백업 파일을 읽을 수 없어요');
  }
}

/* ---------- 도안 단별 안내: 도안 글에서 "1단: …" 줄을 찾아요 (아이폰 앱 GuideParser와 같은 규칙) ---------- */
const GUIDE_STITCH = ['사슬', '짧은', '긴뜨기', '빼뜨기', '뜨기', '기둥', '늘려', '늘리', '모아', '줄여', '코', '겉', '안', '바늘',
  'ch', 'sc', 'dc', 'hdc', 'tr', 'sl', 'inc', 'dec', 'k', 'p'];
const GUIDE_WORDS = ['한길긴뜨기', '두길긴뜨기', '긴뜨기', '짧은뜨기', '빼뜨기', '사슬뜨기', '사슬', '기둥코', '늘려', '모아', '늘리기', '줄이기', '첫번째', '갈색실로'];
const looksLikeStitches = (s) => { const l = s.toLowerCase(); return l.includes(',') || GUIDE_STITCH.some((w) => l.includes(w)); };
const hasHangul = (s) => /[가-힣]/.test(s);

function guideNormalize(s) {
  let t = String(s || '');
  const pairs = [['：', ':'], ['～', '~'], ['〜', '~'], ['–', '-'], ['—', '-'], ['－', '-'], ['−', '-'], ['‐', '-'], ['‑', '-'], ['ㅡ', '-'], ['ー', '-'],
    ['＊', '*'], ['×', '*'], ['，', ','], ['（', '('], ['）', ')']];
  for (const [a, b] of pairs) t = t.split(a).join(b);
  t = t.replace(/(\d)\s*[xX]\s*(\d)/g, '$1*$2');
  // 글자 인식이 뜨기 이름 사이에 넣은 띄어쓰기를 지워요 (예: 짧 은 뜨 기 → 짧은뜨기)
  for (const w of GUIDE_WORDS) t = t.replace(new RegExp(w.split('').join('\\s*'), 'g'), w);
  return t.trim();
}

function guideRowHead(line) {
  const m = /^\s*(?:(R|Rnd|Row|Round)\s*)?(\d{1,3})\s*(단)?\s*(?:[-~]\s*(\d{1,3})\s*(단)?)?\s*[:：.)\]]?\s*/i.exec(line);
  if (!m) return null;
  if (!m[1] && !m[3] && !m[5]) return null;
  const a = +m[2];
  let b = m[4] ? +m[4] : a;
  if (a <= 0 || b < a || b - a >= 500) return null;
  let rest = line.slice(m[0].length).trim();
  if (b === a) {
    const r = /^\D{0,2}\s*(\d{1,3})\s*단\s*[:.)]?\s*/.exec(rest);
    if (r && +r[1] > a && +r[1] - a < 500) { b = +r[1]; rest = rest.slice(r[0].length); }
  }
  if (!/[:.)\]]/.test(m[0]) && rest && !(rest.includes(',') || (/\d/.test(rest) && looksLikeStitches(rest)))) return null;
  return { from: a, to: b, rest };
}

function guideTidy(s) {
  return String(s || '').replace(/\s+/g, ' ').replace(/\s*,\s*/g, ', ').replace(/\(\s+/g, '(').replace(/\s+\)/g, ')').replace(/^[\s,]+|[\s,]+$/g, '');
}

/** 한 단의 글을 쉼표마다 단계로 나눠요 (괄호 안은 한 단계) */
function guideSteps(text) {
  const out = [];
  let cur = '', depth = 0;
  for (const ch of String(text || '')) {
    if (ch === '(') depth++;
    if (ch === ')') depth = Math.max(0, depth - 1);
    if (!depth && (ch === ',' || ch === '→')) { out.push(cur); cur = ''; } else cur += ch;
  }
  out.push(cur);
  return out.map((s) => s.trim().replace(/([가-힣])(\d)/g, '$1 $2').replace(/\s*\*\s*/g, ' × ').replace(/\s+/g, ' ')).filter(Boolean).map((s) => s.slice(0, 60));
}

/** lines: [{ text, x?, y }] → { parts: [{ name, rows }], yarn, needle } */
function parseGuide(raw) {
  let lines = raw.map((l) => ({ text: guideNormalize(l.text), x: l.x, y: l.y })).filter((l) => l.text);
  const rowXs = lines.filter((l) => l.x != null && guideRowHead(l.text)).map((l) => l.x).sort((a, b) => a - b);
  if (rowXs.length) {
    const cols = [];
    for (const x of rowXs) if (!cols.length || x - cols[cols.length - 1] > 0.06) cols.push(x);
    lines = lines.map((l) => {
      if (l.x == null) return { l, c: 0 };
      let best = 0;
      cols.forEach((c, i) => { if (Math.abs(c - l.x) < Math.abs(cols[best] - l.x)) best = i; });
      return Math.abs(cols[best] - l.x) <= 0.05 ? { l, c: best } : null;
    }).filter(Boolean).sort((a, b) => a.c - b.c || a.l.y - b.l.y).map((x) => x.l);
  }

  const res = { parts: [], yarn: '', needle: '' };
  const parts = [];
  let current = { name: '', rows: [] };
  let free = [];
  let canContinue = false;
  const flush = () => {
    if (!current.rows.length && free.length) current.rows = [{ from: 1, to: 1, text: free.join(' ') }];
    if (current.rows.length) parts.push(current);
    free = [];
  };

  for (const { text: t } of lines) {
    const h = guideRowHead(t);
    if (h) {
      if (free.length && !current.rows.length) free = [];
      current.rows.push({ from: h.from, to: h.to, text: h.rest });
      canContinue = true;
      continue;
    }
    const colon = t.indexOf(':');
    if (colon > 0) {
      const key = t.slice(0, colon).toLowerCase();
      const value = t.slice(colon + 1).trim();
      if (value && key.length <= 12) {
        if (key.includes('실') || key.includes('yarn')) { res.yarn ||= value.slice(0, 60); canContinue = false; continue; }
        if (key.includes('바늘') || key.includes('needle') || key.includes('hook')) { res.needle ||= value.slice(0, 40); canContinue = false; continue; }
      }
    }
    if ('-•·*※▶►'.includes(t[0])) { canContinue = false; continue; }
    const last = current.rows.length ? current.rows[current.rows.length - 1].text : (free[free.length - 1] || '');
    const endsOpen = /[,(→]$/.test(last) || (last.split('(').length > last.split(')').length);
    if (canContinue && (endsOpen || t[0] === '(' || (!/^\d/.test(t) && looksLikeStitches(t) && t.includes(',')))) {
      if (current.rows.length) current.rows[current.rows.length - 1].text += ' ' + t;
      else free[free.length - 1] += ' ' + t;
      continue;
    }
    if (t.length <= 14 && !t.includes(',') && (hasHangul(t) || /[a-z]/i.test(t)) && !(/\d/.test(t) && looksLikeStitches(t))) {
      flush();
      current = { name: t, rows: [] };
      canContinue = false;
      continue;
    }
    if (current.name && !current.rows.length && looksLikeStitches(t)) { free.push(t); canContinue = true; continue; }
    canContinue = false;
  }
  flush();

  for (const part of parts) {
    part.rows = part.rows.map((r) => {
      let total = 0;
      const text = r.text.replace(/[(（]?\s*총\s*(\d{1,4})\s*코?\s*[)）]?/, (_, n) => { total = +n; return ''; });
      return { id: uid(), from: r.from, to: r.to, text: guideTidy(text), total };
    }).filter((r) => r.text);
    if (!part.name) part.name = '도안';
  }
  res.parts = parts.filter((x) => x.rows.length);
  return res;
}

function normGuide(list) {
  return (Array.isArray(list) ? list : []).filter((g) => g && g.text && int(g.from) > 0)
    .map((g) => ({ id: String(g.id || uid()), from: int(g.from, 1), to: Math.max(int(g.from, 1), int(g.to)), text: String(g.text).slice(0, 400), total: int(g.total) }))
    .sort((a, b) => a.from - b.from);
}
const guideLabel = (g) => g.from === g.to ? `${g.from}단` : `${g.from}~${g.to}단`;
const guideRowNo = (p) => Math.max(1, p.row);
const guideAt = (p, row) => p.guide.find((g) => g.from <= row && row <= g.to);
const guideMax = (p) => p.guide.reduce((m, g) => Math.max(m, g.to), 0);
function guideStepNow(p) {
  const r = guideRowNo(p), g = guideAt(p, r);
  if (!g || p.guideStepRow !== r) return 0;
  return Math.min(p.guideStep, Math.max(0, guideSteps(g.text).length - 1));
}

function moveGuide(p, d, wholeRow = false) {
  const r = guideRowNo(p), g = guideAt(p, r);
  if (!g) return;
  const n = Math.max(1, guideSteps(g.text).length);
  const s = guideStepNow(p);
  if (d < 0) {
    if (!s) return;
    pushUndo(p);
    p.guideStep = s - 1; p.guideStepRow = r;
    buzz(8);
  } else if (!wholeRow && s + 1 < n) {
    pushUndo(p);
    p.guideStep = s + 1; p.guideStepRow = r;
    buzz(12);
  } else {
    pushUndo(p);
    const next = r + 1;
    p.row = next; p.guideStep = 0; p.guideStepRow = next;
    const k = todayKey();
    p.log[k] = (p.log[k] || 0) + 1;
    let msg = [`${r}단 끝! ${next}단으로 넘어가요`];
    const hits = hitsAt(p, next);
    if (hits.length) msg.push(`${next}단: ` + hits.map((h) => h.r.label).join(', '));
    let big = false;
    if (p.targetRows && next === p.targetRows) { msg.push(`목표 ${p.targetRows}단에 도착했어요!`); big = true; }
    else if (r === guideMax(p)) { msg = [`도안의 마지막 ${r}단까지 끝냈어요!`]; big = true; }
    buzz(big ? [30, 50, 30, 50, 80] : [40, 40, 40]);
    toast(msg.join('\n'));
  }
  touch(p); save();
}

function guideCardHTML(p) {
  if (!p.guide.length) return '';
  const r = guideRowNo(p), g = guideAt(p, r);
  let body;
  if (g) {
    const steps = guideSteps(g.text), cur = guideStepNow(p), last = cur + 1 >= steps.length;
    body = `
    <ol class="guide-steps" aria-live="polite">${steps.map((s, i) => `
      <li class="${i < cur ? 'past' : i === cur ? 'cur' : ''}"><i>${i < cur ? icon('check', 12) : i + 1}</i><span>${esc(s)}</span></li>`).join('')}</ol>
    <div class="seq-btns">
      <button class="seq-back" data-action="guide" data-d="-1" aria-label="한 단계 뒤로" ${cur ? '' : 'disabled'}>${icon('undo', 20)}</button>
      <button class="seq-go" data-action="guide" data-d="1">${last ? `${r}단 끝 · 다음 단으로 ${icon('check', 18)}` : `다음 단계 ${icon('chev', 18)}`}</button>
    </div>`;
  } else {
    body = `<p class="muted small" style="margin:0">${r > guideMax(p) ? `도안 안내는 ${guideMax(p)}단까지예요. 다 떴어요!` : `${r}단은 도안에 안내가 없어요.`}</p>`;
  }
  return `
  <section class="card guide-card">
    <div class="seq-head">
      <div class="sub-name">${r}단 도안 ${g && g.from !== g.to ? `<span class="muted xsmall">${guideLabel(g)} 같은 내용</span>` : ''}</div>
      ${g?.total ? `<span class="pill now">총 ${g.total}코</span>` : ''}
      <button class="icon-btn sm" data-action="guide-menu" aria-label="도안 안내 설정">${icon('more')}</button>
    </div>
    ${body}
    <details class="guide-all">
      <summary class="muted small">${p.guidePart ? `${esc(p.guidePart)} 전체 보기` : '전체 단 보기'}</summary>
      <ul>${p.guide.map((x) => `<li class="${x === g ? 'now' : ''}"><b>${guideLabel(x)}</b><span>${esc(x.text)}${x.total ? ` (총 ${x.total}코)` : ''}</span></li>`).join('')}</ul>
    </details>
  </section>`;
}

/* 도안 파일에서 글자 읽기: 글자가 든 PDF는 그대로, 그림이면 글자 인식(OCR) */
const TESSERACT = 'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js';
let tessPromise = null;
function loadTesseract() {
  if (window.Tesseract) return Promise.resolve(window.Tesseract);
  return tessPromise || (tessPromise = new Promise((res, rej) => {
    const s = document.createElement('script');
    s.src = TESSERACT;
    s.onload = () => res(window.Tesseract);
    s.onerror = () => { tessPromise = null; s.remove(); rej(new Error('tesseract')); };
    document.head.appendChild(s);
  }));
}

async function ocrCanvas(canvas, pageIndex) {
  const T = await loadTesseract();
  const worker = await T.createWorker(['kor', 'eng']);
  try {
    const { data } = await worker.recognize(canvas);
    const W = canvas.width, H = canvas.height;
    // 한 줄 안에서도 띄어진 간격이 크면 다른 칸(그림 옆 글 등)이라 따로 나눠요
    const out = [];
    for (const l of data.lines || []) {
      let seg = null;
      for (const w of l.words || []) {
        const gap = seg ? w.bbox.x0 - seg.x1 : 0;
        if (!seg || gap > W * 0.035) {
          if (seg) out.push(seg);
          seg = { words: [], x0: w.bbox.x0, x1: w.bbox.x1, y0: w.bbox.y0 };
        } else if (gap > (w.bbox.y1 - w.bbox.y0) * 0.25) {
          seg.words.push(' ');  // 글자 높이에 비해 충분히 띄어져 있을 때만 띄어쓰기
        }
        seg.words.push(w.text);
        seg.x1 = w.bbox.x1;
        seg.y0 = Math.min(seg.y0, w.bbox.y0);
      }
      if (seg) out.push(seg);
    }
    return out.map((g) => ({ text: g.words.join('').trim(), x: g.x0 / W + pageIndex * 10, y: pageIndex + g.y0 / H }));
  } finally {
    worker.terminate();
  }
}

async function readGuideLines(ref) {
  const blob = await idb.get(ref.fileName);
  if (!blob) throw new Error('nofile');
  if (blob.type.startsWith('image/') || ref.image) {
    const img = new Image();
    const url = URL.createObjectURL(blob);
    try {
      img.src = url; await img.decode();
      const scale = Math.min(1, 2400 / Math.max(img.naturalWidth, img.naturalHeight));
      const c = document.createElement('canvas');
      c.width = Math.round(img.naturalWidth * scale); c.height = Math.round(img.naturalHeight * scale);
      c.getContext('2d').drawImage(img, 0, 0, c.width, c.height);
      return await ocrCanvas(c, 0);
    } finally { URL.revokeObjectURL(url); }
  }
  const lib = await loadPdfJs();
  const doc = await lib.getDocument({ data: await blob.arrayBuffer() }).promise;
  try {
    const lines = [];
    for (let i = 0; i < Math.min(doc.numPages, 8); i++) {
      const page = await doc.getPage(i + 1);
      const vp = page.getViewport({ scale: 1 });
      const tc = await page.getTextContent();
      const text = tc.items.map((it) => it.str).join('');
      if (/단|\b(R|Rnd|Row)\s*\d/.test(text)) {
        // 같은 높이의 글자 조각을 한 줄로 묶어요
        const rows = [];
        for (const it of tc.items) {
          if (!it.str.trim()) continue;
          const x = it.transform[4] / vp.width, y = 1 - it.transform[5] / vp.height;
          let row = rows.find((r) => Math.abs(r.y - y) < 0.006 && Math.abs(r.x - x) < 0.45);
          if (!row) { row = { x, y, parts: [] }; rows.push(row); }
          row.x = Math.min(row.x, x);
          row.parts.push({ x, s: it.str });
        }
        for (const r of rows) lines.push({ text: r.parts.sort((a, b) => a.x - b.x).map((q) => q.s).join(''), x: r.x + i * 10, y: i + r.y });
      } else {
        const scale = Math.min(3, 2400 / Math.max(vp.width, vp.height));
        const v2 = page.getViewport({ scale });
        const c = document.createElement('canvas');
        c.width = Math.floor(v2.width); c.height = Math.floor(v2.height);
        await page.render({ canvasContext: c.getContext('2d'), viewport: v2 }).promise;
        lines.push(...await ocrCanvas(c, i));
      }
    }
    return lines;
  } finally { doc.destroy(); }
}

let readingGuide = false;
async function readGuide(p, { auto = false } = {}) {
  if (readingGuide || p.pattern?.kind !== 'pdf') return;
  readingGuide = true;
  if (view === 'counter' && current === p) renderCounter(p);
  toast('도안에서 단을 읽고 있어요… 처음엔 글자 인식 도구를 받느라 조금 걸려요');
  let result = null;
  try {
    result = parseGuide(await readGuideLines(p.pattern));
  } catch {
    if (!auto) toast('도안을 읽지 못했어요. 인터넷 연결을 확인하거나 직접 입력해 주세요.');
  }
  readingGuide = false;
  if (view === 'counter' && current === p) renderCounter(p);
  if (!result) return;
  if (!result.parts.length) {
    toast('도안에서 ‘1단:’ 같은 단 번호를 찾지 못했어요');
    if (!auto) openGuideDialog(p, null, { paste: true });
    return;
  }
  $toast.classList.remove('show');
  openGuideDialog(p, result);
}

function guideRowsText(rows) {
  return rows.map((r) => `${guideLabel(r)}: ${r.text}${r.total ? ` (총 ${r.total}코)` : ''}`).join('\n');
}

/** 읽은 안내 확인·고치기. 한 줄에 한 단씩 "3~10단: 사슬2, 짧은뜨기1*5" 형식으로 고쳐요 */
function openGuideDialog(p, result, { paste = false } = {}) {
  const editing = !result && !paste;
  const parts = result?.parts || [];
  let idx = 0;
  const rowsOf = (i) => (editing ? p.guide : parts[i]?.rows || []);
  const others = () => parts.filter((_, i) => i !== idx);
  const canFill = result && ((result.yarn && !p.yarn) || (result.needle && !p.needle));
  openDialog({
    title: editing ? '도안 안내 고치기' : paste ? '도안 직접 입력' : '도안 단 읽기',
    body: `
      ${parts.length > 1 ? `<label class="field"><span>셀 부분</span>
        <select name="part">${parts.map((x, i) => `<option value="${i}">${esc(x.name)} (${x.rows.reduce((m, r) => Math.max(m, r.to), 0)}단)</option>`).join('')}</select></label>` : ''}
      <label class="field"><span>단별 안내 <em>(한 줄에 한 단 · 예: 3~10단: 사슬2, 짧은뜨기1*5)</em></span>
        <textarea name="rows" rows="9" data-guide-rows placeholder="1단: 사슬5, 기둥코2, 짧은뜨기1*4 (총5)&#10;2단: 사슬2, 짧은뜨기1, 짧은뜨기 늘려">${esc(guideRowsText(rowsOf(0)))}</textarea></label>
      ${result ? `<p class="muted xsmall" style="margin:0">글자를 잘못 읽었을 수 있어요. 도안과 한 번 비교해 보고 고쳐 주세요. 쉼표(,)마다 한 단계로 나눠서 보여 줘요.</p>` : ''}
      <label class="check"><input type="checkbox" name="target" ${editing ? '' : 'checked'}><span><b>목표 단수를 마지막 단으로</b></span></label>
      ${canFill ? `<label class="check"><input type="checkbox" name="fill" checked><span><b>실·바늘 칸 채우기</b><br><span class="muted small">${esc([result.yarn, result.needle].filter(Boolean).join(' · '))}</span></span></label>` : ''}
      ${parts.length > 1 ? `<label class="check"><input type="checkbox" name="others" checked><span><b>나머지 부분은 메모에 붙이기</b><br><span class="muted small" data-others>${esc(others().map((x) => x.name).join(', '))}</span></span></label>` : ''}`,
    submitLabel: editing ? '저장' : '적용',
    onAction(v, fd) {
      const text = String(fd.get('rows') || '');
      const parsed = parseGuide(text.split('\n').map((t, i) => ({ text: t, y: i })));
      const rows = parsed.parts.flatMap((x) => x.rows);
      if (!rows.length) { toast('‘1단: 사슬2, 짧은뜨기1*5’처럼 단 번호를 붙여 적어 주세요'); return false; }
      p.guide = normGuide(rows);
      if (!editing) p.guidePart = (parts[idx]?.name || parsed.parts[0]?.name || '').replace(/^도안$/, '').slice(0, 30);
      p.guideStep = 0; p.guideStepRow = 0;
      if (fd.get('target') === 'on') p.targetRows = guideMax(p);
      if (fd.get('fill') === 'on') { p.yarn ||= result.yarn; p.needle ||= result.needle; }
      if (fd.get('others') === 'on') {
        const note = others().map((o) => `[${o.name}]\n` + (o.rows.length === 1 && o.rows[0].from === 1 ? o.rows[0].text : guideRowsText(o.rows))).join('\n\n');
        if (note && !p.notes.includes(note)) p.notes = p.notes ? `${p.notes}\n\n${note}` : note;
      }
      touch(p); save();
      buzz([30, 50, 30]);
      toast(editing ? '도안 안내를 고쳤어요' : `${p.guidePart ? p.guidePart + ' ' : ''}${guideMax(p)}단 안내를 넣었어요`);
      if (view === 'counter' && current === p) renderCounter(p);
    },
  });
  const dlg = document.querySelector('dialog.sheet:last-of-type');
  const sel = dlg?.querySelector('select[name=part]');
  sel?.addEventListener('change', () => {
    idx = +sel.value;
    dlg.querySelector('[data-guide-rows]').value = guideRowsText(rowsOf(idx));
    const o = dlg.querySelector('[data-others]');
    if (o) o.textContent = others().map((x) => x.name).join(', ');
  });
}

function openGuideMenu(p) {
  openDialog({
    title: '도안 안내',
    body: `
      <div class="menu-list">
        <button value="edit" class="menu-item" formnovalidate>${icon('edit')} 안내 고치기</button>
        ${p.pattern?.kind === 'pdf' ? `<button value="reread" class="menu-item" formnovalidate>${icon('doc')} 도안에서 다시 읽기</button>` : ''}
        <button value="library" class="menu-item" formnovalidate>${icon('book')} 도안함에 저장</button>
        <button value="clear" class="menu-item danger" formnovalidate>${icon('trash')} 안내 지우기</button>
      </div>`,
    submitLabel: '닫기',
    onAction(v) {
      if (v === 'edit') setTimeout(() => openGuideDialog(p, null), 0);
      else if (v === 'reread') setTimeout(() => readGuide(p), 0);
      else if (v === 'library') savePatternFromProject(p);
      else if (v === 'clear') {
        if (!confirm('도안 안내를 지울까요?')) return false;
        p.guide = []; p.guidePart = ''; p.guideStep = 0; p.guideStepRow = 0;
        touch(p); save(); renderCounter(p);
        toast('도안 안내를 지웠어요');
      }
    },
  });
}

/* ---------- 도안함: 도안 파일·단별 안내·재료를 저장해 두고 바로 작품 시작 ---------- */
function normSavedPattern(x) {
  if (!x || typeof x !== 'object') return null;
  return {
    id: String(x.id || uid()),
    name: String(x.name || '').trim().slice(0, 60),
    file: normPattern(x.file),
    guide: normGuide(x.guide),
    guidePart: String(x.guidePart || '').slice(0, 30),
    yarn: String(x.yarn || '').slice(0, 80),
    needle: String(x.needle || '').slice(0, 40),
    targetRows: int(x.targetRows),
    notes: String(x.notes || '').slice(0, 2000),
    createdAt: Number(x.createdAt) || Date.now(),
  };
}
const spMax = (sp) => sp.guide.reduce((m, g) => Math.max(m, g.to), 0);

/** 도안 파일을 새 이름으로 복사해요 (작품과 도안함이 서로의 파일을 지우지 않게) */
async function copyPatternRef(ref) {
  if (!ref) return null;
  const r = { ...ref, page: 0 };
  delete r.markerY;
  if (r.kind !== 'pdf') return r;
  const blob = await idb.get(ref.fileName).catch(() => null);
  if (!blob) return null;
  r.fileName = 'pdf-' + uid();
  await idb.put(r.fileName, blob);
  return r;
}

async function savePatternFromProject(p) {
  const sp = normSavedPattern({ name: p.name, file: await copyPatternRef(p.pattern), guide: p.guide, guidePart: p.guidePart, yarn: p.yarn, needle: p.needle, targetRows: p.targetRows });
  state.patterns.unshift(sp);
  save();
  toast(`‘${sp.name}’을 도안함에 저장했어요. 다음엔 도안함에서 바로 시작할 수 있어요`);
}

async function startFromPattern(sp) {
  const p = normalize({
    name: sp.name || '도안', yarn: sp.yarn, needle: sp.needle, notes: sp.notes,
    targetRows: sp.targetRows || spMax(sp), guide: sp.guide.map((g) => ({ ...g, id: uid() })), guidePart: sp.guidePart,
  });
  p.pattern = await copyPatternRef(sp.file);
  state.projects.push(p);
  save();
  toast(`‘${p.name}’ 작품을 시작했어요`);
  go(`/p/${enc(p.id)}`);
}

function deleteSavedPattern(sp) {
  if (sp.file?.kind === 'pdf') removePatternFiles(sp.file);
  state.patterns = state.patterns.filter((x) => x.id !== sp.id);
  save();
}

function renderPatterns() {
  document.title = '도안함 · 뜨개노트';
  const card = (sp) => {
    const meta = [sp.file ? (sp.file.kind === 'pdf' ? (sp.file.image ? '이미지' : 'PDF') : '웹 링크') : '', sp.guide.length ? `${spMax(sp)}단 안내` : ''].filter(Boolean).join(' · ');
    const mat = [sp.yarn, sp.needle].filter(Boolean).join(' · ');
    return `<li class="card sp-card">
      <button class="sp-open" data-action="edit-saved" data-id="${esc(sp.id)}">
        <span class="pattern-icon">${icon(sp.file?.kind === 'web' ? 'globe' : 'doc', 22)}</span>
        <span class="pattern-info"><b>${esc(sp.name || '도안')}</b>${meta ? `<small>${esc(meta)}</small>` : ''}${mat ? `<small>${esc(mat)}</small>` : ''}</span>
      </button>
      <button class="seq-go" data-action="start-saved" data-id="${esc(sp.id)}">이 도안으로 작품 시작 ${icon('play', 16)}</button>
    </li>`;
  };
  $app.innerHTML = `
  <header class="bar">
    <a class="icon-btn" href="#/" aria-label="목록으로">${icon('back', 24)}</a>
    <h1 class="bar-title">도안함</h1>
    <button class="icon-btn" data-action="add-saved" aria-label="도안 추가">${icon('plus', 22)}</button>
  </header>
  ${state.patterns.length
    ? `<ul class="cards">${state.patterns.map(card).join('')}</ul>
  <button class="btn-primary wobbly stash-add" data-action="add-saved">${icon('plus', 18)} 도안 추가</button>`
    : emptyStateHTML({ title: '아직 저장한 도안이 없어요', message: '자주 뜨는 도안을 넣어 두면<br>도안 파일, 단별 안내, 실·바늘까지 담긴 채로<br>바로 작품을 시작할 수 있어요.', note: '뜨던 작품의 도안 메뉴에서 ‘도안함에 저장’으로도 넣을 수 있어요.', button: `<button class="btn-primary wobbly" data-action="add-saved">${icon('plus', 18)} 도안 추가</button>`, cls: 'full-empty' })}`;
}

function openSavedPatternDialog(sp) {
  const isNew = !sp;
  sp = sp || normSavedPattern({});
  let file = sp.file;
  const newFiles = [];
  let saved = false;
  const fileLabel = () => (file ? `${esc(file.title)} <small class="muted">${file.kind === 'pdf' ? (file.image ? '이미지 도안' : 'PDF 도안') : esc(file.url)}</small>` : '');
  openDialog({
    title: isNew ? '도안 추가' : '도안',
    body: `
      <div class="field">
        <div class="yarn-photo-head"><span>도안 파일</span>
          <span class="yarn-photo-actions" data-file-actions ${file ? '' : 'hidden'}>
            <label class="text-btn">바꾸기<input type="file" accept="application/pdf,.pdf,image/*" hidden data-sp-file></label>
            <button type="button" class="text-btn" data-sp-web>링크</button>
            <button type="button" class="text-btn danger-text" data-sp-remove>삭제</button>
          </span></div>
        <div class="sp-file" data-file-row ${file ? '' : 'hidden'}>${icon('doc', 18)} <span data-file-label>${fileLabel()}</span></div>
        <div class="pattern-actions" data-file-add ${file ? 'hidden' : ''}>
          <label class="chip">${icon('doc', 16)} PDF·이미지<input type="file" accept="application/pdf,.pdf,image/*" hidden data-sp-file></label>
          <button type="button" class="chip" data-sp-web>${icon('link', 16)} 웹 링크</button>
        </div>
      </div>
      <label class="field"><span>도안 이름</span><input name="name" maxlength="60" value="${esc(sp.name)}" placeholder="예: 푸딩 줄 감개"></label>
      <div class="grid2">
        <label class="field"><span>실 (선택)</span><input name="yarn" maxlength="80" value="${esc(sp.yarn)}"></label>
        <label class="field"><span>바늘 (선택)</span><input name="needle" maxlength="40" value="${esc(sp.needle)}" placeholder="예: 6호"></label>
      </div>
      <label class="field"><span>단별 안내 <em>(선택 · 한 줄에 한 단)</em></span>
        <textarea name="rows" rows="7" data-guide-rows placeholder="1단: 사슬5, 기둥코2, 짧은뜨기1*4 (총5)&#10;3~10단: 사슬2, 짧은뜨기1*5">${esc(guideRowsText(sp.guide))}</textarea></label>
      <div class="sp-read-row"><button type="button" class="chip" data-sp-read ${file?.kind === 'pdf' ? '' : 'hidden'}>${icon('doc', 16)} 도안에서 단 읽기</button><span class="muted xsmall" data-sp-msg></span></div>
      <label class="field"><span>메모</span><textarea name="notes" rows="2" placeholder="작품을 시작할 때 메모로 들어가요">${esc(sp.notes)}</textarea></label>`,
    extra: isNew ? '' : `<button value="delete" class="btn-danger-ghost" formnovalidate>삭제</button><button value="start" class="btn-ghost" formnovalidate>작품 시작</button>`,
    onAction(v, fd) {
      if (v === 'delete') {
        if (!confirm('이 도안을 도안함에서 지울까요?\n이 도안으로 시작한 작품은 그대로 남아요.')) return false;
        newFiles.forEach((f) => removePatternFiles({ fileName: f }));
        deleteSavedPattern(sp);
        saved = true;
        renderPatterns();
        return;
      }
      const parsed = parseGuide(String(fd.get('rows') || '').split('\n').map((t, i) => ({ text: t, y: i })));
      const next = normSavedPattern({
        ...sp, file, name: fd.get('name') || file?.title || '', yarn: fd.get('yarn'), needle: fd.get('needle'), notes: fd.get('notes'),
        guide: parsed.parts.flatMap((x) => x.rows),
        guidePart: sp.guidePart || (parsed.parts[0]?.name !== '도안' ? parsed.parts[0]?.name : '') || '',
      });
      if (!next.name && !next.file && !next.guide.length) { toast('도안 이름이나 파일, 단별 안내 중 하나는 넣어 주세요'); return false; }
      if (!next.name) next.name = '도안';
      saved = true;
      newFiles.filter((f) => f !== file?.fileName).forEach((f) => removePatternFiles({ fileName: f }));
      if (sp.file?.kind === 'pdf' && sp.file.fileName !== file?.fileName) removePatternFiles(sp.file);
      const i = state.patterns.findIndex((x) => x.id === next.id);
      if (i >= 0) state.patterns[i] = next; else state.patterns.unshift(next);
      save();
      if (v === 'start') { startFromPattern(next); return; }
      toast('도안함에 저장했어요');
      if (view === 'patterns') renderPatterns();
    },
  });
  const dlg = document.querySelector('dialog.sheet:last-of-type');
  const msg = dlg.querySelector('[data-sp-msg]'), rowsTA = dlg.querySelector('[data-guide-rows]');
  const sync = () => {
    dlg.querySelector('[data-file-actions]').hidden = !file;
    dlg.querySelector('[data-file-row]').hidden = !file;
    dlg.querySelector('[data-file-add]').hidden = !!file;
    dlg.querySelector('[data-file-label]').innerHTML = fileLabel();
    dlg.querySelector('[data-sp-read]').hidden = file?.kind !== 'pdf';
  };
  const readFile = async () => {
    if (file?.kind !== 'pdf') return;
    msg.textContent = '도안에서 단을 읽고 있어요… 처음엔 조금 걸려요';
    try {
      const r = parseGuide(await readGuideLines(file));
      const part = r.parts[0];
      if (!part) { msg.textContent = '도안에서 ‘1단:’ 같은 단 번호를 찾지 못했어요. 직접 적어 주세요.'; return; }
      rowsTA.value = guideRowsText(part.rows);
      if (part.name !== '도안') sp.guidePart = part.name;
      const yarnIn = dlg.querySelector('[name=yarn]'), needleIn = dlg.querySelector('[name=needle]'), notesIn = dlg.querySelector('[name=notes]');
      if (!yarnIn.value) yarnIn.value = r.yarn;
      if (!needleIn.value) needleIn.value = r.needle;
      const others = r.parts.slice(1);
      if (others.length && !notesIn.value) notesIn.value = others.map((o) => `[${o.name}]\n` + guideRowsText(o.rows)).join('\n\n');
      msg.textContent = `${part.rows.length}줄을 읽었어요 (${part.rows.reduce((m, g) => Math.max(m, g.to), 0)}단까지). 글자를 잘못 읽었을 수 있으니 도안과 비교해 보세요.`;
    } catch { msg.textContent = '도안을 읽지 못했어요. 인터넷 연결을 확인하거나 직접 적어 주세요.'; }
  };
  dlg.querySelectorAll('[data-sp-file]').forEach((inp) => inp.addEventListener('change', async (e) => {
    const f = e.target.files[0];
    e.target.value = '';
    if (!f) return;
    const isImage = f.type.startsWith('image/') || /\.(jpe?g|png|gif|webp|heic|heif|bmp)$/i.test(f.name);
    const isPdf = f.type === 'application/pdf' || /\.pdf$/i.test(f.name);
    if (!isImage && !isPdf) { toast('PDF나 이미지 파일만 불러올 수 있어요'); return; }
    const key = 'pdf-' + uid();
    try { await idb.put(key, f); } catch { toast('파일을 저장하지 못했어요'); return; }
    newFiles.push(key);
    file = { kind: 'pdf', title: f.name.replace(/\.[a-z0-9]+$/i, '').slice(0, 80) || '도안', fileName: key, page: 0 };
    if (isImage) file.image = true;
    const nameIn = dlg.querySelector('[name=name]');
    if (!nameIn.value) nameIn.value = file.title;
    sync();
    if (!rowsTA.value.trim()) readFile();
  }));
  dlg.querySelectorAll('[data-sp-web]').forEach((b) => b.addEventListener('click', () => {
    const url = normalizedWebURL(prompt('도안이 있는 웹 페이지 주소', file?.url || 'https://') || '');
    if (!url) return;
    file = { kind: 'web', title: new URL(url).hostname.replace(/^www\./, ''), url, page: 0 };
    sync();
  }));
  dlg.querySelector('[data-sp-remove]').addEventListener('click', () => { file = null; sync(); });
  dlg.querySelector('[data-sp-read]').addEventListener('click', readFile);
  dlg.addEventListener('close', () => { if (!saved) newFiles.forEach((f) => removePatternFiles({ fileName: f })); });
}

/* ---------- 이벤트 ---------- */
$app.addEventListener('click', (e) => {
  const el = e.target.closest('[data-action]');
  if (!el) return;
  const p = current;
  switch (el.dataset.action) {
    case 'tab':
      listTab = el.dataset.tab;
      renderList();
      break;
    case 'stash-tab':
      stashTab = el.dataset.tab;
      renderStash();
      break;
    case 'add-yarn': openYarnDialog(null); break;
    case 'add-needle': openNeedleDialog(null); break;
    case 'edit-yarn': openYarnDialog(findYarn(el.dataset.id)); break;
    case 'edit-needle': openNeedleDialog(findNeedle(el.dataset.id)); break;
    case 'materials': openMaterialsDialog(p); break;
    case 'row':
      changeRow(p, Number(el.dataset.d), { quietHits: view === 'pattern' });
      refresh(p, true);
      break;
    case 'undo':
      if (undo(p)) { refresh(p, true); toast('되돌렸어요'); }
      break;
    case 'pattern-pdf':
      pickPatternPDF(p);
      break;
    case 'pattern-web':
      openWebPatternDialog(p);
      break;
    case 'pattern-menu':
      openPatternMenu(p);
      break;
    case 'marker': {
      markerOn = !markerOn;
      el.classList.toggle('on', markerOn);
      el.setAttribute('aria-pressed', markerOn);
      const m = document.querySelector('.marker');
      if (m) m.hidden = !markerOn;
      if (p?.pattern) {
        if (markerOn) p.pattern.markerY = Math.round(markerY); else delete p.pattern.markerY;
        save();
      }
      break;
    }
    case 'ink':
      setInkMode(!inkMode);
      break;
    case 'ink-tool':
      inkTool = el.dataset.tool;
      updatePatternBar(p);
      break;
    case 'ink-undo':
      undoInk();
      break;
    case 'zoom':
      changeZoom(Number(el.dataset.z));
      break;
    case 'set-row':
      openSetRow(p);
      break;
    case 'cnt': {
      const c = p.counters.find((x) => x.id === el.dataset.id);
      if (c) { changeCounter(p, c, Number(el.dataset.d)); renderCounter(p); }
      break;
    }
    case 'step':
    case 'step-round': {
      const c = p.counters.find((x) => x.id === el.dataset.id);
      if (c) { moveStep(p, c, el.dataset.action === 'step-round' ? 1 : Number(el.dataset.d), el.dataset.action === 'step-round'); renderCounter(p); }
      break;
    }
    case 'add-counter':
      openCounterDialog(p, null);
      break;
    case 'guide':
      moveGuide(p, Number(el.dataset.d));
      renderCounter(p, Number(el.dataset.d) > 0 && p.guideStep === 0);
      break;
    case 'add-saved': openSavedPatternDialog(null); break;
    case 'edit-saved': openSavedPatternDialog(state.patterns.find((x) => x.id === el.dataset.id)); break;
    case 'start-saved': { const sp = state.patterns.find((x) => x.id === el.dataset.id); if (sp) startFromPattern(sp); break; }
    case 'guide-row':
      if (guideAt(p, guideRowNo(p))) moveGuide(p, 1, true); else changeRow(p, 1);
      renderCounter(p, true);
      break;
    case 'guide-menu':
      openGuideMenu(p);
      break;
    case 'guide-read':
      readGuide(p);
      break;
    case 'guide-paste':
      openGuideDialog(p, null, { paste: true });
      break;
    case 'counter-menu': {
      const c = p.counters.find((x) => x.id === el.dataset.id);
      if (c) openCounterDialog(p, c);
      break;
    }
    case 'pause':
      openPauseDialog(p);
      break;
    case 'resume':
      p.status = 'active';
      p.pausedAt = null;
      touch(p);
      save();
      buzz(20);
      renderCounter(p);
      toast('다시 시작해요!');
      break;
    case 'add-change':
      openChangeDialog(p);
      break;
    case 'del-change':
      p.changes = p.changes.filter((c) => c.id !== el.dataset.id);
      touch(p);
      save();
      renderCounter(p);
      break;
    case 'toggle-done':
    {
      const had = p.deducted.length;
      const taken = setDone(p, p.status !== 'done');
      touch(p);
      save();
      if (p.status === 'done') {
        buzz([30, 50, 30, 50, 80]);
        const used = taken.map((l) => { const y = findYarn(l.yarnID); return y ? `${stashYarnTitle(y)} ${amt(l.amount)}${y.unit}` : null; }).filter(Boolean);
        toast(used.length ? `완성을 축하해요! 보관함에서 ${used.join(', ')}를 뺐어요` : '완성을 축하해요! 홈의 ‘완성작’에 모아 둘게요');
      } else if (had) toast('진행 중으로 돌렸어요. 뺐던 실을 보관함에 다시 채웠어요');
    }
      renderCounter(p);
      break;
    case 'add-rem': {
      const list = document.getElementById('remList');
      list.insertAdjacentHTML('beforeend', remRowHTML());
      list.lastElementChild.querySelector('input').focus();
      break;
    }
    case 'del-rem':
      el.closest('.rem-row').remove();
      break;
    case 'delete-project':
      if (!confirm(`‘${p.name}’ 작품을 삭제할까요?\n삭제하면 되돌릴 수 없어요.`)) return;
      if (p.pattern?.kind === 'pdf') removePatternFiles(p.pattern);
      p.photos.forEach((ph) => removePhotoFile(ph.fileName));
      state.projects = state.projects.filter((x) => x !== p);
      save();
      go('/', true);
      toast('작품을 삭제했어요');
      break;
    case 'record':
      openRecordDialog(p);
      break;
    case 'view-photo':
      openPhotoViewer(p, el.dataset.id);
      break;
    case 'export':
      exportData();
      break;
    case 'settings':
      openSettings();
      break;
  }
});

$app.addEventListener('change', (e) => {
  if (e.target.dataset.action === 'copy-record') {
    const old = find(e.target.value);
    const form = e.target.closest('form');
    if (old) {
      const y = old.yarnsUsed[0];
      form.elements.yarn.value = (y && [y.name, y.color].filter(Boolean).join(' ')) || old.yarn;
      form.elements.needle.value = old.gauge.needle || old.needle;
      form.elements.gauge.value = JSON.stringify(old.gauge);
      toast(`‘${old.name}’의 실·바늘·게이지를 가져왔어요`);
    } else {
      form.elements.gauge.value = '';
    }
    return;
  }
  if (e.target.dataset.action === 'import') importData(e.target.files[0]);
  if (e.target.dataset.action === 'add-photos' && current) { addPhotos(current, e.target.files); e.target.value = ''; }
});

let notesTimer;
$app.addEventListener('input', (e) => {
  if (e.target.dataset.action === 'notes' && current) {
    current.notes = e.target.value;
    touch(current);
    clearTimeout(notesTimer);
    notesTimer = setTimeout(save, 400);
  }
});
window.addEventListener('pagehide', save);

$app.addEventListener('submit', (e) => {
  if (e.target.id === 'projForm') {
    e.preventDefault();
    submitForm(e.target);
  }
});

// 키보드: 스페이스·↑ = +1단, ↓ = −1단, ⌘/Ctrl+Z = 되돌리기
document.addEventListener('keydown', (e) => {
  if ((view !== 'counter' && view !== 'pattern') || !current) return;
  if (document.querySelector('dialog[open]')) return;
  if (e.target.closest?.('input, textarea, select, button, a')) return;
  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'z') {
    e.preventDefault();
    if (undo(current)) { refresh(current, true); toast('되돌렸어요'); }
  } else if (e.key === ' ' || e.key === 'ArrowUp' || e.key === '+' || e.key === '=') {
    e.preventDefault();
    changeRow(current, 1, { quietHits: view === 'pattern' });
    refresh(current, true);
  } else if (e.key === 'ArrowDown' || e.key === '-') {
    e.preventDefault();
    changeRow(current, -1);
    refresh(current, true);
  }
});

/* ---------- 손으로 오린 듯한 테두리 (아이폰 앱 WobblyShape.swift와 같은 계산) ---------- */
function wobblyPath(w, h, r, amp = 1.1, step = 3) {
  const x0 = amp, y0 = amp, x1 = w - amp, y1 = h - amp;
  r = Math.max(0, Math.min(r, (x1 - x0) / 2, (y1 - y0) / 2));
  const segs = [];
  const line = (ax, ay, bx, by, nx, ny) =>
    segs.push([Math.hypot(bx - ax, by - ay), (t) => [ax + (bx - ax) * t, ay + (by - ay) * t, nx, ny]]);
  const arc = (cx, cy, a0) => segs.push([Math.PI / 2 * r, (t) => {
    const a = a0 + t * Math.PI / 2;
    return [cx + r * Math.cos(a), cy + r * Math.sin(a), Math.cos(a), Math.sin(a)];
  }]);
  line(x0 + r, y0, x1 - r, y0, 0, -1); arc(x1 - r, y0 + r, -Math.PI / 2);
  line(x1, y0 + r, x1, y1 - r, 1, 0); arc(x1 - r, y1 - r, 0);
  line(x1 - r, y1, x0 + r, y1, 0, 1); arc(x0 + r, y1 - r, Math.PI / 2);
  line(x0, y1 - r, x0, y0 + r, -1, 0); arc(x0 + r, y0 + r, Math.PI);
  const total = segs.reduce((sum, [L]) => sum + L, 0);
  const n = Math.max(12, Math.floor(total / step));
  const f2 = Math.max(3, Math.round(total / 34));
  const f3 = Math.max(5, Math.round(total / 15));
  const pts = [];
  for (let i = 0; i < n; i++) {
    let s = (total * i) / n;
    const u = (2 * Math.PI * s) / total;
    let p = segs[segs.length - 1][1](1);
    for (const [L, at] of segs) {
      if (s <= L) { p = at(L ? s / L : 0); break; }
      s -= L;
    }
    const k = (amp * (0.35 * Math.sin(2 * u + 1.3) + 0.45 * Math.sin(f2 * u + 0.4) + 0.35 * Math.sin(f3 * u + 2.2))) / 1.15;
    pts.push([p[0] + p[2] * k, p[1] + p[3] * k]);
  }
  const f = (v) => +v.toFixed(1);
  let d = `M${f(pts[0][0])} ${f(pts[0][1])}`;
  for (let i = 0; i < n; i++) {
    const p0 = pts[(i - 1 + n) % n], p1 = pts[i], p2 = pts[(i + 1) % n], p3 = pts[(i + 2) % n];
    d += `C${f(p1[0] + (p2[0] - p0[0]) / 6)} ${f(p1[1] + (p2[1] - p0[1]) / 6)} ${f(p2[0] - (p3[0] - p1[0]) / 6)} ${f(p2[1] - (p3[1] - p1[1]) / 6)} ${f(p2[0])} ${f(p2[1])}`;
  }
  return d + 'Z';
}

const WOB_SELECTOR = '.wobbly, .card, .pattern-card, .sub, .rem, .alert, .hint, .tabs, .tabs button[aria-selected="true"]';
function wobSVG(w, h, d, fill, stroke, dash) {
  const line = stroke && stroke !== 'transparent'
    ? ` stroke="${stroke}" stroke-width="1"${dash ? ` stroke-dasharray="${dash}"` : ''}` : '';
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}"><path d="${d}" fill="${fill}"${line}/></svg>`;
  return `url("data:image/svg+xml,${encodeURIComponent(svg)}")`;
}
function paintWobbly(el) {
  const w = el.offsetWidth, h = el.offsetHeight;
  if (!w || !h) return;
  const cs = getComputedStyle(el);
  const v = (name) => cs.getPropertyValue(name).trim();
  const fill = v('--wob-fill') || 'transparent';
  const press = v('--wob-press');
  const stroke = v('--wob-stroke');
  const dash = v('--wob-dash');
  const r = parseFloat(v('--wob-r')) || 16;
  const key = [w, h, fill, press, stroke, dash, r].join('|');
  if (el.dataset.wob === key) return;
  const d = wobblyPath(w, h, r);
  el.style.setProperty('--wob-img', wobSVG(w, h, d, fill, stroke, dash));
  if (press) el.style.setProperty('--wob-img-press', wobSVG(w, h, d, press, stroke, dash));
  el.dataset.wob = key;
}
const wobWatched = new Set();
const wobResize = new ResizeObserver((entries) => entries.forEach((e) => paintWobbly(e.target)));
function scanWobbly() {
  for (const el of wobWatched) {
    if (!el.isConnected) { wobResize.unobserve(el); wobWatched.delete(el); }
  }
  document.querySelectorAll(WOB_SELECTOR).forEach((el) => {
    if (!wobWatched.has(el)) { wobWatched.add(el); wobResize.observe(el); }
    paintWobbly(el);
  });
}
let wobQueued = false;
new MutationObserver(() => {
  if (wobQueued) return;
  wobQueued = true;
  requestAnimationFrame(() => { wobQueued = false; scanWobbly(); });
}).observe(document.body, { childList: true, subtree: true });
matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
  document.querySelectorAll('[data-wob]').forEach((el) => { delete el.dataset.wob; paintWobbly(el); });
});
document.fonts?.ready.then(scanWobbly);

window.addEventListener('hashchange', route);
new MutationObserver(() => hydratePhotos($app)).observe($app, { childList: true, subtree: true });
route();

if ('serviceWorker' in navigator && location.protocol.startsWith('http')) {
  window.addEventListener('load', () => navigator.serviceWorker.register('sw.js').catch(() => {}));
}
