//
//  PhotosService.swift
//  OnboardingExercise
//
//  Created by Elad Musba on 07/04/2021.
//

import UIKit
import Photos

// Q: placement of this enum?
enum ImageSize {
    case max
    case min
    case iPad
    case iPhone
    
    var value: CGSize {
        switch self {
            case .max:
                return PHImageManagerMaximumSize
            case .min:
                return CGSize(width: 100, height: 100)
            case .iPad:
                return CGSize(width: 400, height: 400)
            case .iPhone:
                return CGSize(width: 200, height: 200)
        }
    }
}

protocol PhotosServiceProtocol {
    func fetchImageBy(indexPath: IndexPath, imageSize: ImageSize, completion: @escaping (UIImage) -> ())
    func fetchAllUserAssets(completion: @escaping () -> ())
    func getUserPhotosCount() -> Int
}

class PhotosService: PhotosServiceProtocol {
    
    private var userPhotoAssets: PHFetchResult<PHAsset>? = nil
    

    
    private let defaultImageSize = CGSize(width: 400, height: 400)
    
    func fetchAllUserAssets(completion: @escaping () -> ()) {
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
                case .authorized:
                    self.authorizedFetchFromPhotosLibrary(completion)
                case .denied, .restricted:
                    print("Not allowed")
                case .notDetermined:
                    print("Not determined yet")
                case .limited:
                    print("Limited access")
                @unknown default:
                    print("Default case in permissions")
            }
        }
    }
    
    private func authorizedFetchFromPhotosLibrary(_ completion: () -> ()) {
        print("fetch from library is called")
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = .typeUserLibrary // simulator
//        fetchOptions.includeAssetSourceTypes = .typeiTunesSynced // physical
        self.userPhotoAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        completion()
    }
    

    func fetchImageBy(indexPath: IndexPath, imageSize: ImageSize, completion: @escaping (UIImage) -> ()) {
        let options = getImageRequestOptions(isQualityImage: imageSize == .max)
        if let photoAsset = self.userPhotoAssets?.object(at: indexPath.row) {
            PHImageManager.default().requestImage(for: photoAsset,
                                                  targetSize: imageSize.value,
                                                  contentMode: .aspectFit,
                                                  options: options) {
                (uiImage, info) in
//                print("degraded? \(((info?[PHImageResultIsDegradedKey] as? Bool) ?? false))")
                guard let uiImage = uiImage else { return }
                completion(uiImage)
            }
        } else {
            print("📕", "Could not get photo asset from index")
        }
    }
    
    private func getImageRequestOptions(isQualityImage: Bool) -> PHImageRequestOptions{
        let options = PHImageRequestOptions()
        if isQualityImage {
            options.isSynchronous = true
            options.resizeMode = .none
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        } else {
            options.resizeMode = .fast
        }
        return options
    }
    
    func getUserPhotosCount() -> Int {
        return userPhotoAssets?.count ?? 0
    }
}
