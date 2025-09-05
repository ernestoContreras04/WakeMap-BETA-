import UIKit
import AVFoundation
import UserNotifications

class AlarmViewController: UIViewController {
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudio()
        requestNotificationPermissions()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.white
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowRadius = 8
        
        view.addSubview(containerView)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "¡Has llegado!"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center
        
        let stopButton = UIButton(type: .system)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.setTitle("Detener", for: .normal)
        stopButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        stopButton.backgroundColor = UIColor.systemBlue
        stopButton.setTitleColor(UIColor.white, for: .normal)
        stopButton.layer.cornerRadius = 24
        stopButton.addTarget(self, action: #selector(stopAlarm), for: .touchUpInside)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(stopButton)
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 280),
            containerView.heightAnchor.constraint(equalToConstant: 120),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            stopButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            stopButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            stopButton.widthAnchor.constraint(equalToConstant: 138),
            stopButton.heightAnchor.constraint(equalToConstant: 48),
            stopButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    private func setupAudio() {
        guard let audioPath = Bundle.main.path(forResource: "alarma", ofType: "mp3") else {
            print("No se encontró el archivo de audio")
            return
        }
        
        let audioURL = URL(fileURLWithPath: audioPath)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.numberOfLoops = -1 // Reproducción infinita
            audioPlayer?.volume = 1.0
            audioPlayer?.play()
        } catch {
            print("Error al reproducir audio: \(error)")
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error al solicitar permisos de notificación: \(error)")
            }
        }
    }
    
    @objc private func stopAlarm() {
        audioPlayer?.stop()
        audioPlayer = nil
        
        // Enviar notificación a Flutter
        NotificationCenter.default.post(name: NSNotification.Name("AlarmStopped"), object: nil)
        
        dismiss(animated: true) {
            // Cerrar la aplicación o volver a la pantalla principal
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    deinit {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}
