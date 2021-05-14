import UIKit
import AVFoundation
import GPUImage

class ViewController: UIViewController {

    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var filterPicker: UIPickerView!
    @IBOutlet weak var contentSegmentControll: UISegmentedControl!
    
    let filerArray : [(String, ViewController.Filters)] = [
        ("none", .none),
        ("colorAdjustments", .colorAdjustments),
        ("lookUpTable", .lookUpTable),
        ("threeCombo", .threeCombo),
        ("visualEffects", .visualEffects),
        ("visualEffectsCombo", .visualEffectsCombo)
    ]
    
    var currentDataMode : DataMode = .photo {
        didSet {
            updateMediaView(currentDataMode)
        }
    }
    
    var currentFilter : Filters = .none {
        didSet {
            updateMediaView(currentDataMode)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpView()
    }
    
    func setUpView() {
        filterPicker.delegate = self
        filterPicker.dataSource = self
        updateMediaView(currentDataMode)
    }
    
    func updateMediaView(_ dataMode: DataMode) {
        switch dataMode {
        case .photo :
            cleanMediaView()
            let image = setUpImageView(imageName: "pexels-roberto-nickson-2559941")
            mediaView.addSubview(image)
        case .video :
            cleanMediaView()
            setUpVideoView(videoname: "video", ofType: "mp4")
        }
        mediaView.layoutIfNeeded()
    }
    
    func setUpImageView(imageName: String) -> UIImageView {
        mediaView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        let imageView = UIImageView()
        guard let image = UIImage(named: imageName) else {
            fatalError()
        }
        imageView.image = applyFilter(image: image, filter: currentFilter)
        imageView.frame = mediaView.frame
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    
    func setUpVideoView(videoname: String, ofType: String) {
        guard let path = Bundle.main.path(forResource: videoname, ofType: ofType) else {
            fatalError()
        }
        let url = URL(fileURLWithPath: path)
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = mediaView.frame
        playerLayer.videoGravity = .resizeAspectFill
        mediaView.layer.addSublayer(playerLayer)
        player.play()
    }
    
    func cleanMediaView() {
        mediaView.subviews.forEach { sub in
            sub.removeFromSuperview()
        }
        mediaView.layer.sublayers?.forEach({ sub in
            sub.removeFromSuperlayer()
        })
    }
    
    func applyFilter(image: UIImage, filter: Filters) -> UIImage {
        switch filter {
        case .threeCombo :
            guard let filteredImage = GPUImagePicture(image: image) else {
                fatalError()
            }
            
            let f1 = GPUImageToonFilter()
            let f2 = GPUImageSketchFilter()
            let f3 = GPUImageMosaicFilter()
            
            filteredImage.addTarget(f1)
            f1.addTarget(f2)
            f2.addTarget(f3)
            
            f3.useNextFrameForImageCapture()
            filteredImage.processImage()
            
            return filteredImage.imageFromCurrentFramebuffer()
            
        default :
            return image
        }
    }
    
    @IBAction func contentSegmentChanged(_ sender: Any) {
       currentDataMode = contentSegmentControll.selectedSegmentIndex == 0 ? .photo : .video
        print(currentDataMode)
    }
    
    enum DataMode {
        case video, photo
    }
    
    enum Filters {
        case colorAdjustments
        case threeCombo
        case visualEffects
        case visualEffectsCombo
        case lookUpTable
        case none
    }
}


extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filerArray.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filerArray[row].0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        currentFilter = filerArray[row].1
        updateMediaView(currentDataMode)
    }
}



