r = audiorecorder(48000, 16, 1);        % 48 kHz, 16 bits, mono
disp('Grabando 3 s... ¡empiecen a hablar YA!');
recordblocking(r, 3);                   % graba 3 segundos
x = getaudiodata(r);
sound(x, 48000);                        % escuchar cómo quedó
audiowrite('audios/audio1.wav', x, 48000);