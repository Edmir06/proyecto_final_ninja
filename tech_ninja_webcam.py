import cv2
import mediapipe as mp
import socket
import json

# Envía la punta del dedo índice a Godot por UDP.
# Godot debe estar escuchando en el puerto 4242.
IP_GODOT = "127.0.0.1"
PUERTO_GODOT = 4242
ANCHO = 640
ALTO = 480

udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
camara = cv2.VideoCapture(0, cv2.CAP_DSHOW)
camara.set(cv2.CAP_PROP_FRAME_WIDTH, ANCHO)
camara.set(cv2.CAP_PROP_FRAME_HEIGHT, ALTO)

if not camara.isOpened():
    print("ERROR: No se pudo abrir la cámara. Cierra otras aplicaciones que la estén usando.")
    udp.close()
    raise SystemExit(1)

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils

print("Cámara activa. Muestra tu mano frente a la cámara.")
print("Enviando coordenadas a Godot en 127.0.0.1:4242.")
print("Pulsa Q en la ventana de la cámara para salir.")

try:
    with mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=2,
        model_complexity=0,
        min_detection_confidence=0.6,
        min_tracking_confidence=0.5,
    ) as hands:
        while True:
            ok, frame = camara.read()
            if not ok:
                print("No se pudo leer la imagen de la cámara.")
                break

            # Imagen espejada, como una cámara de selfie.
            frame = cv2.flip(frame, 1)
            frame = cv2.resize(frame, (ANCHO, ALTO))
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            resultado = hands.process(rgb)

            datos = {}

            if resultado.multi_hand_landmarks:
                for i, mano in enumerate(resultado.multi_hand_landmarks[:2]):
                    mp_drawing.draw_landmarks(
                        frame, mano, mp_hands.HAND_CONNECTIONS
                    )

                    # Landmark 8 = punta del dedo índice.
                    punta = mano.landmark[8]
                    x = max(0, min(ANCHO - 1, int(punta.x * ANCHO)))
                    y = max(0, min(ALTO - 1, int(punta.y * ALTO)))

                    datos[str(i + 1)] = {"x": x, "y": y}
                    cv2.circle(frame, (x, y), 12, (0, 255, 255), -1)
                    cv2.putText(
                        frame,
                        f"Jugador {i + 1}",
                        (x + 12, y - 12),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.6,
                        (0, 255, 255),
                        2,
                    )

            # Enviar también {} cuando no se detectan manos.
            paquete = json.dumps(datos).encode("utf-8")
            udp.sendto(paquete, (IP_GODOT, PUERTO_GODOT))

            cv2.putText(
                frame,
                "Q = salir | Manos detectadas: " + str(len(datos)),
                (10, 25),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.6,
                (255, 255, 255),
                2,
            )
            cv2.imshow("TECH NINJA - Camara de manos", frame)

            if cv2.waitKey(1) & 0xFF == ord("q"):
                break
finally:
    camara.release()
    cv2.destroyAllWindows()
    udp.close()
    print("Cámara cerrada.")
