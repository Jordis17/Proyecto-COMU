const pptxgen = require("pptxgenjs");
const fs = require("fs");
const path = require("path");
const { applyTheme } = require("/root/.claude/skills/synced/e60b93c2-02be-49ca-8b31-28d01982395d_96ac6c89-13ac-471a-98ba-0469de375a8a/pptx/scripts/apply_theme.js");
const sizeOf = (p) => {
  // ancho y alto de un PNG (cabecera IHDR)
  const b = fs.readFileSync(p);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
};

const REPO = path.join(__dirname, "..");
const OUT = path.join(REPO, "02_diseno", "presentacion_video.pptx");
// notas del presentador: texto del guion por sección (presentacion_notas.json)
const N = JSON.parse(fs.readFileSync(path.join(__dirname, "presentacion_notas.json"), "utf8"));
const notas = (k, extra) => {
  const t = (N[k] || []).join("\n\n");
  return extra ? `${extra}\n\n${t}` : t;
};

const THEME = {
  name: "FDM FM",
  headFontFace: "Cambria",
  bodyFontFace: "Calibri",
  colors: {
    dk1: "1F2933", lt1: "FFFFFF", dk2: "16324F", lt2: "EEF2F6",
    accent1: "1B5E9E", accent2: "D95F02", accent3: "6A3D9A", accent4: "2E8B57",
    accent5: "7A8794", accent6: "B23A48", hlink: "1B5E9E", folHlink: "6A3D9A",
  },
};

const pres = new pptxgen();
pres.layout = "LAYOUT_16x9";              // 10 x 5.625 in
pres.title = "Sistema FDM + FM con receptor superheterodino";
pres.author = "Jordi y Abner";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
const C = pres.SchemeColor;

// ---------- layouts ----------
pres.defineSlideMaster({
  title: "PORTADA",
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.7, y: 1.45, w: 8.6, h: 1.4,
      fontSize: 36, bold: true, color: C.background1, valign: "bottom", align: "left" }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.7, y: 3.05, w: 8.6, h: 1.4,
      fontSize: 18, color: C.background2, valign: "top", align: "left" }, text: "" } },
  ],
});
pres.defineSlideMaster({
  title: "DIVISOR",
  background: { color: C.text2 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.7, y: 1.7, w: 8.6, h: 1.0,
      fontSize: 34, bold: true, color: C.background1, valign: "bottom", align: "left" }, text: "" } },
    { placeholder: { options: { name: "body", type: "body", x: 0.7, y: 2.85, w: 8.6, h: 1.4,
      fontSize: 18, color: C.background2, valign: "top", align: "left" }, text: "" } },
  ],
  slideNumber: { x: 9.2, y: 5.2, w: 0.5, h: 0.3, fontSize: 10, color: C.background2, align: "right" },
});
pres.defineSlideMaster({
  title: "CONTENIDO",
  background: { color: C.background1 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.5, y: 0.25, w: 9.0, h: 0.6,
      fontSize: 28, bold: true, color: C.text2, valign: "middle", align: "left" }, text: "" } },
    { text: { text: "Sistema FDM + FM · receptor superheterodino", options: {
      x: 0.5, y: 5.2, w: 6.0, h: 0.3, fontSize: 10, color: C.accent5, align: "left", margin: 0 } } },
  ],
  slideNumber: { x: 9.2, y: 5.2, w: 0.5, h: 0.3, fontSize: 10, color: C.accent5, align: "right" },
});

// imagen ajustada dentro de una caja, centrada
function imagen(slide, archivo, caja, nombre) {
  const { w, h } = sizeOf(archivo);
  const k = Math.min(caja.w / w, caja.h / h);
  const W = w * k, Hh = h * k;
  slide.addImage({ path: archivo, x: caja.x + (caja.w - W) / 2, y: caja.y + (caja.h - Hh) / 2,
    w: W, h: Hh, altText: nombre, objectName: nombre });
}
function idea(slide, texto) {
  slide.addText(texto, { x: 0.5, y: 4.62, w: 9.0, h: 0.45, fontSize: 15, italic: true,
    color: C.text1, align: "left", valign: "middle", margin: 0, isTextBox: true, objectName: "Idea" });
}
function contenido(sec, titulo, archivo, texto, nota, cajaAlta) {
  const s = pres.addSlide({ masterName: "CONTENIDO", sectionTitle: sec });
  s.addText(titulo, { placeholder: "title" });
  const caja = cajaAlta ? { x: 0.5, y: 1.0, w: 9.0, h: 3.5 } : { x: 0.5, y: 1.0, w: 9.0, h: 3.5 };
  imagen(s, archivo, caja, titulo);
  if (texto) idea(s, texto);
  s.addNotes(nota);
  return s;
}
const F = (p) => path.join(REPO, p);

// ---------- 1. Inicio ----------
pres.addSection({ title: "Inicio" });
let s = pres.addSlide({ masterName: "PORTADA", sectionTitle: "Inicio" });
s.addText("Sistema FDM + FM con receptor superheterodino", { placeholder: "title" });
s.addText([
  { text: "Comunicaciones Eléctricas I · Proyecto", options: { breakLine: true } },
  { text: "Jordi y Abner" },
], { placeholder: "body" });
s.addNotes("Diapositiva de inicio. Empezar a hablar en la siguiente.");

s = pres.addSlide({ masterName: "CONTENIDO", sectionTitle: "Inicio" });
s.addText("El sistema", { placeholder: "title" });
s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 0.5, y: 1.0, w: 9.0, h: 3.5, rectRadius: 0.1,
  fill: { color: C.background2 }, line: { color: C.accent5, width: 1, dashType: "dash" }, objectName: "Espacio para la captura" });
s.addText("Pegar aquí una captura del nivel principal de sistema_fdm_fm.slx", {
  x: 0.5, y: 2.4, w: 9.0, h: 0.6, fontSize: 16, color: C.accent5, align: "center", valign: "middle",
  isTextBox: true, objectName: "Indicación de la captura" });
idea(s, "Tres audios → multiplex FDM → FM a 10 MHz → receptor superheterodino (FI 1.7 MHz) → tres audios");
s.addNotes(notas("1. Sistema (0:00–0:40) · Jordi"));

// ---------- 2. Escalamiento y muestreo ----------
pres.addSection({ title: "Escalamiento y muestreo" });
contenido("Escalamiento y muestreo", "Escalamiento de frecuencias", F("02_diseno/figuras_video/tabla_escalamiento.png"),
  "Con la tabla del enunciado la FM cruza 0 Hz; dividiendo todo entre 100 se mantienen las proporciones",
  notas("Escalamiento · Abner"));
contenido("Escalamiento y muestreo", "Frecuencia de muestreo", F("02_diseno/figuras_video/tabla_muestreo.png"),
  "El muestreo lo fija la frecuencia más alta: el producto suma del mezclador",
  notas("Muestreo · Jordi", "[Antes de esta diapositiva: mostrar la salida del mezclador en la radio]"));

// ---------- 3. Transmisor ----------
pres.addSection({ title: "Transmisor" });
const tx = N["3. Transmisor (2:00–3:15) · Abner"] || [];
contenido("Transmisor", "Multiplex FDM", F("03_codigo_matlab/figuras/fig2_multiplex.png"),
  "Tres canales DSB-SC en 20, 60 y 100 kHz, con guardas de 10 kHz", tx[0] || "");
contenido("Transmisor", "Desviación de frecuencia", F("02_diseno/figuras_video/tabla_desviacion.png"),
  "150 kHz: unos 6 dB más que con 75 kHz, y la señal cabe en la FI", tx[1] || "");

// ---------- 4. Receptor ----------
pres.addSection({ title: "Receptor" });
s = pres.addSlide({ masterName: "DIVISOR", sectionTitle: "Receptor" });
s.addText("Receptor superheterodino", { placeholder: "title" });
s.addText("Demostración en la radio: plan de frecuencias, espectro de RF, mezclador y FI", { placeholder: "body" });
s.addNotes(notas("4. Receptor (3:15–4:30) · Jordi", "[Cambiar a la radio, pestaña «Receptor superheterodino»]"));

// ---------- 5. Demodulador ----------
pres.addSection({ title: "Demodulador" });
contenido("Demodulador", "Tres demoduladores comparados", F("02_diseno/figuras_video/comparacion_demoduladores.png"),
  "Con ruido moderado dan lo mismo; usamos el discriminador, que es el del curso",
  notas("5. Demodulador (4:30–6:00) · Abner", "[Después de esta diapositiva: abrir «Demodulador FM» en el .slx]"));

// ---------- 6. Radio ----------
pres.addSection({ title: "Radio" });
s = pres.addSlide({ masterName: "DIVISOR", sectionTitle: "Radio" });
s.addText("La radio", { placeholder: "title" });
s.addText("Sintonía, elección del audio y desintonía", { placeholder: "body" });
s.addNotes(notas("6. Radio (6:00–7:45) · Jordi", "[Cambiar a la radio, con las simulaciones ya hechas]"));

// ---------- 7. Ruido y prénfasis ----------
pres.addSection({ title: "Ruido y prénfasis" });
const rp = N["7. Ruido y prénfasis (7:45–9:30) · Abner"] || [];
contenido("Ruido y prénfasis", "Canal con ruido (AWGN)", F("03_codigo_matlab/fig_awgn.png"),
  "El audio 3 sale unos 14 dB peor: el ruido crece con f² a la salida del discriminador",
  rp.slice(0, 2).join("\n\n"));
contenido("Ruido y prénfasis", "Prénfasis y deénfasis", F("02_diseno/figuras_video/prenfasis_f0.png"),
  "Con f₀ = 30 kHz la diferencia entre el mejor y el peor audio baja de 14 a 6 dB",
  rp.slice(2).join("\n\n"));

// ---------- 8. Cierre ----------
pres.addSection({ title: "Cierre" });
const ci = N["8. Cierre (9:30–10:00) · Jordi"] || [];
contenido("Cierre", "Resumen de decisiones", F("02_diseno/figuras_video/tabla_resumen.png"), "", ci[0] || "");
s = pres.addSlide({ masterName: "DIVISOR", sectionTitle: "Cierre" });
s.addText("Limitaciones", { placeholder: "title" });
s.addText([
  { text: "La simulación no funciona en tiempo real", options: { bullet: true, breakLine: true } },
  { text: "La fase de la subportadora se corrige con un retardo conocido, no con un tono piloto", options: { bullet: true, breakLine: true } },
  { text: "El canal solo tiene ruido blanco", options: { bullet: true } },
], { placeholder: "body" });
s.addNotes(ci[1] || "");

pres.writeFile({ fileName: OUT }).then(async () => {
  await applyTheme(OUT, THEME);
  console.log("ok", OUT);
});
