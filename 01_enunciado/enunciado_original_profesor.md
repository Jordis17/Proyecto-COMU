Las instrucciones de este documento contiene errores intencionales incluidos por el profesor, hay que detectarlos y siguiendo la materia del curso corregirlos nosotros para que el proyecto funcione adecuadamente 

1. Descripción general

En este proyecto se diseñará, modelará y analizará un sistema completo de telecomunicaciones pasobanda que permita la transmisión simultánea de múltiples señales de audio mediante multiplexación por división de frecuencia (FDM), modulación en frecuencia (FM) y recepción mediante un receptor superheterodino.

El desarrollo del proyecto se realizará exclusivamente en MATLAB/Simulink, con énfasis en el modelado matemático de sistemas de comunicaciones, la simulación y análisis temporal y espectral, el diseño modular del sistema y el desarrollo de una interfaz gráfica tipo radio que permita configurar parámetros del sistema y observar su efecto en el desempeño.

2. Objetivo general

Diseñar y modelar en MATLAB/Simulink un sistema de telecomunicaciones pasobanda basado en FDM y FM, con recepción superheterodina e interfaz gráfica, verificando su correcto funcionamiento mediante simulación y análisis.

3. Objetivos específicos

Modelar un sistema de telecomunicaciones pasobanda a nivel de señales.
Modelar e implementar moduladores y demoduladores FM.
Diseñar e implementar un esquema de multiplexación por división de frecuencia (FDM).
Modelar un transmisor FM pasobanda.
Modelar un receptor superheterodino, incluyendo conversión de frecuencia y filtrado.
Analizar señales en los dominios del tiempo y la frecuencia.
Aplicar criterios de diseño como el criterio de Carson.
Diseñar una interfaz gráfica amigable en MATLAB/Simulink, tipo radio.
Reforzar habilidades de trabajo en equipo y resolución estructurada de problemas de ingeniería.
4. Descripción del proyecto

Se deberá diseñar un sistema completo de comunicaciones que incluya transmisor y receptor, cumpliendo con las siguientes especificaciones.

4.1 Señales de información

Se transmitirán tres señales de audio independientes.
Cada señal tendrá un ancho de banda máximo de 15 kHz.
Las señales podrán ser sintéticas o señales de audio reales, debidamente normalizadas y justificadas.
Las señales deberán ser claramente identificables a la salida del receptor.
4.2 Multiplexación por división de frecuencia (FDM)

Las tres señales deberán multiplexarse en frecuencia.
Se dispone de un ancho de banda total máximo de 120 kHz para la señal multiplexada.
El diseño debe incluir la selección del plan de frecuencias, separación espectral entre canales y la justificación del uso del ancho de banda disponible.
Se deberá presentar el espectro de la señal multiplexada.
4.3 Modulación FM

La señal multiplexada deberá modularse en frecuencia utilizando una portadora configurable, cuyo valor nominal será 10 MHz.
El diseño deberá definir y justificar el índice de modulación.
Se deberá verificar el ancho de banda de la señal FM mediante el criterio de Carson.
La portadora deberá ser seleccionable desde la interfaz gráfica.
4.4 Canal de transmisión

Se asumirá un canal ideal.
El transmisor y el receptor estarán conectados directamente, sin considerar efectos del medio de transmisión.
Al final, deberá explorar lo que sucede con su sistema ante un canal ruidoso AWGN
4.5 Receptor superheterodino

Arquitectura superheterodina clásica.
Frecuencia intermedia (FI) nominal: 1.7 MHz.
La frecuencia del oscilador local deberá determinarse automáticamente en función de la portadora seleccionada.
El receptor deberá incluir conversión de frecuencia, filtrado en FI y demodulación FM.
Se deberá evidenciar la correcta selección del canal, la recuperación de la señal multiplexada y la separación de las tres señales originales.
Si la calidad de las señales demodulada es baja, debe considerar el uso de filtros de prénfasis/deénfasis.

5. Consideraciones de escalamiento de frecuencias (obligatorias)
Debido a limitaciones computacionales inherentes a la simulación digital, no se simularán directamente las frecuencias nominales RF. En su lugar, se deberá emplear un escalamiento de frecuencias, manteniendo las relaciones relativas entre anchos de banda, portadora y frecuencia intermedia.

Tabla de referencia para el escalamiento

Parámetro	Valor nominal	Valor simulado de referencia
Ancho de banda de audio	≤ 15 kHz	≤ 15 kHz
Ancho de banda FDM total	120 kHz	120 kHz
Frecuencia de portadora FM	10 MHz	100 kHz
Frecuencia intermedia (FI)	1.7 MHz	17 kHz
Los valores simulados pueden variar, siempre que se mantengan las proporciones relativas y que el escalamiento sea claramente documentado y justificado. El escalamiento debe ser transparente para el usuario de la interfaz gráfica.

6. Modelado, simulación y análisis en MATLAB/Simulink

El sistema deberá desarrollarse de forma modular, mediante diagramas de bloques.
Cada bloque deberá ser modelado matemáticamente e implementado en MATLAB/Simulink.
Se deberá presentar evidencia de señales en el dominio del tiempo, espectros de frecuencia y comparación entre señales originales y recuperadas.
Este apartado constituye el núcleo principal del proyecto.
7. Diseño de la interfaz gráfica (tipo radio)

La interfaz deberá permitir la selección de la frecuencia de la portadora.
Deberá visualizarse la frecuencia intermedia.
Se deberá permitir la selección del canal o señal de interés.
El sistema deberá actualizar automáticamente sus parámetros internos al modificar la portadora.

8. Recomendaciones técnicas para la simulación

Utilizar frecuencias de muestreo entre 5 y 10 veces el ancho de banda máximo simulado.
Emplear modelos discretos y evitar bloques continuos innecesarios.
Configurar Simulink con solver de paso fijo y modo discreto.
Limitar la duración de las simulaciones a intervalos cortos.
Centralizar los parámetros del sistema para facilitar su modificación desde la interfaz gráfica.
9. Evidencias del proceso de resolución del problema

Identificación del problema.
Análisis del contexto y variables relevantes.
Formulación del plan de solución.
Desarrollo y simulación del sistema.
Evaluación de la solución obtenida.

10. Entregable

Un video explicativo de aproximadamente 10 minutos, tipo informe técnico.
El video deberá incluir explicación del sistema, relación con la teoría, demostración funcional del modelo, uso de la interfaz gráfica y análisis de resultados.
Todos los integrantes del grupo deberán demostrar dominio de todos los aspectos del proyecto.





