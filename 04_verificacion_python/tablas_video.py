"""Tablas del guion como imágenes para el video (mismos valores de decisiones_cuantitativas.md).

Uso:  python3 tablas_video.py   -> guarda los PNG en 02_diseno/figuras_video/
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SALIDA = os.path.join(os.path.dirname(__file__), "..", "02_diseno", "figuras_video")
os.makedirs(SALIDA, exist_ok=True)
AZUL = "#dce8f6"
GRIS = "#f2f2f2"


def tabla(nombre, titulo, columnas, filas, resaltar=(), nota="", anchos=None):
    alto = 0.45 * (len(filas) + 1) + (0.4 if nota else 0.1)
    fig, ax = plt.subplots(figsize=(10, alto))
    ax.axis("off")
    t = ax.table(cellText=filas, colLabels=columnas, loc="upper center", cellLoc="center",
                 colWidths=anchos)
    t.auto_set_font_size(False)
    t.set_fontsize(13)
    t.scale(1, 2.0)
    for (r, c), celda in t.get_celld().items():
        celda.set_edgecolor("#bbbbbb")
        if r == 0:
            celda.set_facecolor(GRIS)
            celda.set_text_props(weight="bold")
        elif r - 1 in resaltar:
            celda.set_facecolor(AZUL)
            celda.set_text_props(weight="bold")
    # el título va en la diapositiva; aquí solo la tabla
    if nota:
        fig.text(0.5, 0.0, nota, ha="center", va="top", fontsize=12, color="#444444")
    fig.tight_layout()
    fig.savefig(os.path.join(SALIDA, nombre), dpi=150, bbox_inches="tight")
    plt.close(fig)


# 1) Escalamiento: tabla del enunciado frente a la nuestra
tabla("tabla_escalamiento.png", "Escalamiento de frecuencias",
      ["Parámetro", "Valor real", "Tabla del enunciado", "Nuestro escalamiento (÷100)"],
      [["Audio", "15 kHz", "15 kHz", "150 Hz"],
       ["Multiplex FDM", "120 kHz", "120 kHz", "1.2 kHz"],
       ["Ancho de la FM (Carson)", "530 kHz", "530 kHz", "5.3 kHz"],
       ["Portadora", "10 MHz", "100 kHz", "100 kHz"],
       ["FI", "1.7 MHz", "17 kHz", "17 kHz"],
       ["Ancho de la FM / portadora", "0.053", "5.3", "0.053"]],
      resaltar=(5,),
      nota="Con la tabla del enunciado, la FM ocuparía 100 ± 265 kHz: cruza 0 Hz. Dividiendo todo entre 100, la proporción es la real.",
      anchos=[0.3, 0.18, 0.24, 0.28])

# 2) Muestreo por etapa
tabla("tabla_muestreo.png", "Frecuencia de muestreo de cada etapa (valores reales)",
      ["Etapa", "Frecuencia más alta", "Muestreo usado"],
      [["Audio", "15 kHz", "48 kHz"],
       ["Multiplex", "120 kHz", "480 kHz"],
       ["FI", "2.25 MHz", "4.8 MHz"],
       ["RF y mezclador", "20.65 MHz (producto suma)", "48 MHz"]],
      resaltar=(3,),
      nota="Regla del enunciado: 5 a 10 veces el ancho de banda (530 kHz) = 2.65 a 5.3 MHz. No alcanza para el producto suma.",
      anchos=[0.3, 0.4, 0.3])

# 3) Desviación de frecuencia
tabla("tabla_desviacion.png", "Elección de la desviación de frecuencia",
      ["Desviación Δf", "Carson 2(Δf + 115 kHz)", "Margen en la FI de 700 kHz", "SNR frente a 75 kHz"],
      [["75 kHz", "380 kHz", "320 kHz", "referencia"],
       ["150 kHz", "530 kHz", "170 kHz", "+6 dB"],
       ["200 kHz", "630 kHz", "70 kHz (al borde)", "+8.5 dB"]],
      resaltar=(1,),
      nota="La SNR de salida crece con Δf², pero también el ancho de banda. 150 kHz es lo más alto que cabe con margen.",
      anchos=[0.2, 0.3, 0.28, 0.22])

# 4) Resumen de decisiones
tabla("tabla_resumen.png", "Resumen de decisiones",
      ["Decisión", "Elegido", "Por qué"],
      [["Escalamiento", "Todo ÷100", "Mantiene las proporciones reales"],
       ["Muestreo RF", "48 MHz, cada etapa a su tasa", "El producto suma llega a 20.65 MHz"],
       ["Multiplex", "DSB-SC en 20, 60 y 100 kHz", "Cabe en el 75 % de los 120 kHz"],
       ["Desviación", "150 kHz", "+6 dB y cabe en la FI"],
       ["Oscilador local", "f_c − 1.7 MHz", "La suma cabe en 48 MHz"],
       ["Sección de RF", "Sí", "Sin ella, −3 dB con ruido"],
       ["Demodulador", "Discriminador", "Es el del curso; ≥ 43 dB sin ruido"],
       ["Prénfasis", "f₀ = 30 kHz", "Diferencia entre audios de 14 a 6 dB"]],
      anchos=[0.2, 0.36, 0.44])
print("Tablas guardadas en", os.path.abspath(SALIDA))
