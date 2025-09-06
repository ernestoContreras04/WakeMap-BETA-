import UIKit
import AVFoundation

class AlarmViewController: UIViewController {
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioPlayer()
        playAlarm()
    }
    
    func setupAudioPlayer() {
        guard let path = Bundle.main.path(forResource: "alarma", ofType: "mp3") else {
            print("No se pudo encontrar el archivo de audio")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Repetir infinitamente
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error al configurar el reproductor de audio: \(error)")
        }
    }
    
    func playAlarm() {
        audioPlayer?.play()
    }
    
    func stopAlarm() {
        audioPlayer?.stop()
    }
    
    @IBAction func stopButtonTapped(_ sender: UIButton) {
        stopAlarm()
        dismiss(animated: true, completion: nil)
    }
}
