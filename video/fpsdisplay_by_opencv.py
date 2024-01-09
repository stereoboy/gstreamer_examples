import cv2
import time

def display_webcam_with_fps():
    # Open the webcam (0 represents the default camera, you can change it based on your setup)
    cap = cv2.VideoCapture(4)

    actual_rate = cap.get(cv2.CAP_PROP_FPS)
    print("actual_rate={}".format(actual_rate))
    target_frame_rate=10
    cap.set(cv2.CAP_PROP_FPS, target_frame_rate)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return

    # Initialize variables for FPS calculation
    start_time = time.time()
    frame_count = 0

    while True:
        # Capture frame-by-frame
        ret, frame = cap.read()

        if not ret:
            print("Error: Failed to capture frame.")
            break

        # Calculate FPS
        frame_count += 1
        elapsed_time = time.time() - start_time
        fps = frame_count / elapsed_time

        # Display FPS in the frame
        cv2.putText(frame, f"FPS: {fps:.2f}", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

        if elapsed_time > 4.0:
            print(f"FPS: {fps:.2f}")
            start_time= time.time()
            frame_count = 0
        # Display the frame
        cv2.imshow('Webcam with FPS', frame)

        # Exit on 'q' key press
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    # Release the webcam and close the window
    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    display_webcam_with_fps()
