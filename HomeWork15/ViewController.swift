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
    
    var player: AVPlayer! = nil
    var playerItem : AVPlayerItem! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpView()
    }
    
    
    func setUpView() {
        filterPicker.delegate = self
        filterPicker.dataSource = self
        updateMediaView(currentDataMode)
    }
    
    func updateMediaView(_ dataMode: DataMode) {
        cleanMediaView()
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
        imageView.image = applyFilterOnImage(image: image, filter: currentFilter)
        imageView.frame = mediaView.frame
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
    
    func setUpVideoView(videoname: String, ofType: String) {

        let path = Bundle.main.path(forResource: "video", ofType: "mp4")!
        player = AVPlayer()
        let pathURL = URL(fileURLWithPath: path)

        playerItem = AVPlayerItem(url: pathURL)
        player.replaceCurrentItem(with: playerItem)

        let gpuMovie = GPUImageMovie(playerItem: playerItem)!
        gpuMovie.playAtActualSpeed = true

        let filteredView: GPUImageView = GPUImageView();
        filteredView.frame = self.mediaView.frame
        self.mediaView.addSubview(filteredView)

        applyFilterOnVideo(gpuImageMovie: gpuMovie, onView: filteredView)

        gpuMovie.startProcessing()
        player.play()
    }
    
    func cleanMediaView() {
        mediaView.subviews.forEach { sub in
            sub.removeFromSuperview()
        }
        mediaView.layer.sublayers?.forEach({ sub in
            sub.removeFromSuperlayer()
        })
        if let player = player {
            player.pause()
        }
    }
    
    func applyFilterOnImage(image: UIImage, filter: Filters) -> UIImage {
        switch filter {
        case .threeCombo :
            var imageCopy = image
                let picture = GPUImagePicture(image: image)
                let filter1 = GPUImageContrastFilter()
                filter1.contrast = 2.0
                let filter2 = GPUImageSharpenFilter()
                let filter3 = GPUImageBoxBlurFilter()
                filter3.blurRadiusInPixels = 10
                picture?.addTarget(filter1)
                filter1.addTarget(filter2)
                filter2.addTarget(filter3)
                filter3.useNextFrameForImageCapture()
                picture?.processImage()
                imageCopy = filter3.imageFromCurrentFramebuffer(with: image.imageOrientation)
                return imageCopy
            
        default :
            return image
        }
    }
    
    func applyFilterOnVideo(gpuImageMovie: GPUImageMovie, onView: GPUImageView) {
        switch currentFilter {
        case .threeCombo :
            let f1 = GPUImageBoxBlurFilter()
            let f2 = GPUImageSepiaFilter()
            let f3 = GPUImageEmbossFilter()
            gpuImageMovie.addTarget(f1)
            f1.addTarget(f2)
            f2.addTarget(f3)
            f3.addTarget(onView)
            gpuImageMovie.startProcessing()
        default :
            gpuImageMovie.addTarget(onView)
            gpuImageMovie.startProcessing()
        }
    }
    
    @IBAction func contentSegmentChanged(_ sender: Any) {
        currentDataMode = contentSegmentControll.selectedSegmentIndex == 0 ? .photo : .video
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
        switch currentDataMode {
        case .photo :
            updateMediaView(.photo)
        case .video :
            updateMediaView(.video)
        }
    }
}



