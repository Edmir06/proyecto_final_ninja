# TECH NINJA - Captura de webcam con diagnostico y seguimiento por jugador.
# Compatible con el receptor UDP de Godot res://scripts/red_webcam.gd
# Para instalar: py -m pip install -r requirements_webcam.txt
import os
import time
import socket
import json
import itertools
import cv2
import mediapipe as mp

IP_GODOT = "127.0.0.1"
PUERTO_GODOT = 4242
PUERTO_MODO = 4243  # comandos del modo de juego enviados desde Godot
ANCHO, ALTO = 640, 480
MAX_SIN_VER = 0.65              # tiempo de tolerancia cuando una mano desaparece
DIST_MAX = 0.22                 # distancia normalizada maxima de asociación
ALFA = 0.80                    # 1.0 = sin suavizado; alto = menos retraso


def abrir_camara():
    # DSHOW suele funcionar en Windows, pero algunas webcams requieren MSMF/ANY.
    candidatos = []
    if os.name == 'nt':
        candidatos.extend([(0, cv2.CAP_DSHOW), (0, cv2.CAP_MSMF),
                           (1, cv2.CAP_DSHOW), (1, cv2.CAP_MSMF),
                           (2, cv2.CAP_DSHOW)])
    candidatos.extend([(0, cv2.CAP_ANY), (1, cv2.CAP_ANY), (2, cv2.CAP_ANY)])
    for indice, backend in candidatos:
        cam = None
        try:
            print(f"Probando camara {indice} (backend {backend})...", flush=True)
            cam = cv2.VideoCapture(indice, backend)
            if not cam.isOpened():
                cam.release()
                continue
            cam.set(cv2.CAP_PROP_FRAME_WIDTH, ANCHO)
            cam.set(cv2.CAP_PROP_FRAME_HEIGHT, ALTO)
            cam.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # algunos drivers ignoran esto
            for intento in range(4):
                ok, frame = cam.read()
                if ok and frame is not None:
                    print(f"CAMARA LISTA: numero {indice}, backend {backend}", flush=True)
                    return cam
                time.sleep(0.1)
        except cv2.error as e:
            print(f"Fallo al probar la camara: {e}", flush=True)
        if cam is not None:
            cam.release()
    return None


class Seguidor:
    """No identifica biometricamente la mano; mantiene P1/P2 por continuidad.
    Registro: P1 empieza a la izquierda, P2 a la derecha (imagen espejada).
    """
    def __init__(self):
        self.tracks = {}  # id -> {p:(x,y), anterior:(x,y), t: tiempo, tip:(x,y)}

    def actualizar_solo(self, detecciones, ahora):
        """Una unica mano es J1 en TODA la imagen (incluida mitad derecha)."""
        if not detecciones:
            return {}
        anterior = self.tracks.get(1)
        if anterior and ahora - anterior['t'] < MAX_SIN_VER:
            # Si entra otra mano, mantenemos la mas proxima al jugador actual.
            elegido = min(detecciones, key=lambda d:
                          (d[0][0]-anterior['p'][0])**2 + (d[0][1]-anterior['p'][1])**2)
        else:
            # Solo es relevante cuando aparecen dos manos antes de empezar.
            elegido = min(detecciones, key=lambda d: d[0][0])
        self._guardar(1, elegido, ahora)
        self.tracks.pop(2, None)
        return {1: elegido}

    def reset(self):
        self.tracks.clear()
        print("Registro reiniciado. Pon J1 a la izquierda y J2 a la derecha.")

    def actualizar(self, detecciones, ahora):
        # Cada deteccion: (centro_palmar_normalizado, punta_indice_normalizada, landmarks)
        visibles = {}
        # Intentar asociar tracks activos con manos detectadas por minima distancia.
        ids = [j for j in (1, 2) if j in self.tracks and ahora - self.tracks[j]['t'] < MAX_SIN_VER]
        usados = set()
        if ids and detecciones:
            candidatos = []
            for jid in ids:
                anterior = self.tracks[jid]
                dt = min(0.12, ahora - anterior['t'])
                # Predicción moderada; evita velocidades extremas al cruzar las manos.
                vel = anterior.get('v', (0.0, 0.0))
                pred = (anterior['p'][0] + vel[0]*dt, anterior['p'][1] + vel[1]*dt)
                for di, d in enumerate(detecciones):
                    p = d[0]
                    dist = ((p[0]-pred[0])**2 + (p[1]-pred[1])**2)**0.5
                    if dist <= DIST_MAX:
                        candidatos.append((dist, jid, di))
            # Prioriza una asociación global razonable para dos manos.
            mejores = []
            for n in range(min(len(ids), len(detecciones)), 0, -1):
                combinaciones = [tuple(c) for c in itertools.combinations(candidatos, n)]
                validas = [c for c in combinaciones if len({x[1] for x in c}) == n and len({x[2] for x in c}) == n]
                if validas:
                    mejores = min(validas, key=lambda c: sum(x[0] for x in c))
                    break
            # Detecciones casi coincidentes: mejor omitir las asignaciones que arriesgar un intercambio.
            for _, jid, di in mejores:
                if len(detecciones) == 2:
                    sep = ((detecciones[0][0][0]-detecciones[1][0][0])**2 + (detecciones[0][0][1]-detecciones[1][0][1])**2)**0.5
                    if sep < 0.065:
                        continue
                self._guardar(jid, detecciones[di], ahora)
                visibles[jid] = detecciones[di]
                usados.add(di)

        # Inicializar / recuperar SOLO cuando el jugador entra en su zona de origen.
        # No cambia de jugador a una mano ya asociada en este fotograma.
        for di, d in enumerate(detecciones):
            if di in usados:
                continue
            px = d[0][0]
            jid = 1 if px < 0.46 else (2 if px > 0.54 else None)
            if jid is None or jid in visibles:
                continue
            track = self.tracks.get(jid)
            if track is not None and ahora - track['t'] < MAX_SIN_VER:
                continue
            # No inicializar dos detecciones que sean la misma mano por accidente.
            self._guardar(jid, d, ahora)
            visibles[jid] = d
        return visibles

    def _guardar(self, jid, deteccion, ahora):
        p, tip, _ = deteccion
        old = self.tracks.get(jid)
        if old:
            dt = max(0.025, ahora - old['t'])
            vel = ((p[0]-old['p'][0])/dt, (p[1]-old['p'][1])/dt)
            tip = (ALFA*tip[0]+(1-ALFA)*old['tip'][0],
                   ALFA*tip[1]+(1-ALFA)*old['tip'][1])
        else:
            vel = (0.0, 0.0)
        self.tracks[jid] = {'p': p, 'v': vel, 'tip': tip, 't': ahora}


def main():
    print("TECH NINJA - Webcam (Windows). Q = cerrar; R = reiniciar registro")
    print("1 Player: mueve una sola mano por toda la camara, SIN division.")
    print("2 Players: J1 comienza a la izquierda; J2 a la derecha.")
    camara = abrir_camara()
    if camara is None:
        print("\nERROR: No se pudo abrir ninguna webcam (indices 0, 1, 2).")
        print("1. Prueba la aplicacion Camara de Windows.")
        print("2. Permite el acceso de aplicaciones de escritorio a la camara.")
        print("3. Cierra Meet, Zoom, OBS y otros programas que ocupen la webcam.")
        print("4. Revisa si la camara esta conectada y activada en el Administrador de dispositivos.")
        raise SystemExit(1)

    try:
        mp_hands = mp.solutions.hands
    except AttributeError:
        camara.release()
        print("ERROR: esta version de mediapipe no incluye mp.solutions.")
        print("Instala las versiones del archivo requirements_webcam.txt.")
        raise SystemExit(1)

    udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    control = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        control.bind((IP_GODOT, PUERTO_MODO))
    except OSError as exc:
        camara.release()
        udp.close()
        control.close()
        raise RuntimeError(f"No se pudo abrir el puerto {PUERTO_MODO} para el modo: {exc}") from exc
    control.setblocking(False)
    modo = "solo"  # arranque seguro hasta recibir la seleccion de Godot
    tracker = Seguidor()
    print("Modo inicial: 1 PLAYER. Godot cambia automaticamente a 2 PLAYERS.")
    t_prev = time.monotonic()
    fps_filtrados = 0.0
    ultima_lectura = 0.0
    errores = 0
    try:
        with mp_hands.Hands(static_image_mode=False, max_num_hands=2,
                            model_complexity=0, min_detection_confidence=0.60,
                            min_tracking_confidence=0.50) as hands:
            while True:
                # La opcion del menu de Godot cambia la deteccion SIN reiniciar Python.
                while True:
                    try:
                        mensaje, _ = control.recvfrom(128)
                    except BlockingIOError:
                        break
                    except OSError:
                        break
                    nuevo = mensaje.decode('utf-8', errors='ignore').strip().lower()
                    if nuevo in ("solo", "versus") and nuevo != modo:
                        modo = nuevo
                        tracker.reset()
                        print("Modo activo:", "1 PLAYER (pantalla completa)" if modo == "solo" else "2 PLAYERS (zonas separadas)")
                ok, frame = camara.read()
                if not ok or frame is None:
                    errores += 1
                    if errores > 12:
                        print("ERROR: La webcam dejo de enviar imagenes.")
                        break
                    time.sleep(0.04)
                    continue
                errores = 0
                frame = cv2.flip(cv2.resize(frame, (ANCHO, ALTO)), 1)
                rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                rgb.flags.writeable = False
                resultado = hands.process(rgb)
                ahora = time.monotonic()
                detecciones = []
                if resultado.multi_hand_landmarks:
                    for mano in resultado.multi_hand_landmarks[:2]:
                        lm = mano.landmark
                        # Centro de palma: muñeca + bases de dedos, robusto a doblar el indice.
                        puntos = [lm[k] for k in (0, 5, 9, 13, 17)]
                        cx = sum(p.x for p in puntos)/len(puntos)
                        cy = sum(p.y for p in puntos)/len(puntos)
                        detecciones.append(((cx,cy), (lm[8].x,lm[8].y), mano))
                visibles = (tracker.actualizar_solo(detecciones, ahora)
                            if modo == "solo" else tracker.actualizar(detecciones, ahora))
                datos = {}
                for jid, (_, _, mano) in visibles.items():
                    mp.solutions.drawing_utils.draw_landmarks(frame, mano, mp_hands.HAND_CONNECTIONS)
                    px, py = tracker.tracks[jid]['tip']
                    x = int(max(0, min(ANCHO-1, px*ANCHO)))
                    y = int(max(0, min(ALTO-1, py*ALTO)))
                    datos[str(jid)] = {'x': x, 'y': y}
                    color = (255, 90, 30) if jid == 1 else (45, 70, 255)
                    cv2.circle(frame, (x,y), 10, color, -1)
                    cv2.putText(frame, f'Jugador {jid}', (max(0,x-40), max(40,y-16)),
                                cv2.FONT_HERSHEY_SIMPLEX, 0.65, color, 2)
                # Protocolo original para Godot: JSON con claves '1' y '2', en pixeles.
                udp.sendto(json.dumps(datos).encode('utf-8'), (IP_GODOT, PUERTO_GODOT))
                dt = ahora - t_prev
                t_prev = ahora
                if dt > 0:
                    instant = 1.0/dt
                    fps_filtrados = (0.85*fps_filtrados+0.15*instant) if fps_filtrados else instant
                cv2.putText(frame, f'FPS {fps_filtrados:.1f} | Q salir | R recalibrar',
                            (10, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.56, (250,250,250), 2)
                if modo == "versus":
                    cv2.line(frame, (ANCHO//2,0), (ANCHO//2,ALTO), (100,100,100), 1)
                cv2.putText(frame, "1 PLAYER" if modo == "solo" else "2 PLAYERS",
                            (ANCHO-150, 24), cv2.FONT_HERSHEY_SIMPLEX, 0.56, (70,255,140), 2)
                cv2.imshow('TECH NINJA - Camara de manos', frame)
                k = cv2.waitKey(1) & 0xFF
                if k in (ord('q'), 27):
                    break
                if k == ord('r'):
                    tracker.reset()
    except Exception as exc:
        print(f"ERROR DURANTE LA DETECCION: {type(exc).__name__}: {exc}")
        raise
    finally:
        # Avisar a Godot que ambos jugadores han desaparecido.
        try: udp.sendto(b'{}', (IP_GODOT, PUERTO_GODOT))
        except OSError: pass
        camara.release()
        cv2.destroyAllWindows()
        udp.close()
        control.close()
        print('Webcam cerrada')

if __name__ == '__main__':
    main()
