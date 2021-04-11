//
//  PhotosService.swift
//  OnboardingExercise
//
//  Created by Elad Musba on 07/04/2021.
//

import UIKit
import Photos

class PhotosService {
    
    static let shared = PhotosService()
    
    private init(){}
    
    private var userPhotoAssets: PHFetchResult<PHAsset>? = nil
    private let defaultImageSize = CGSize(width: 300, height: 300)
    
    func fetchAllUserAssets(completion: @escaping () -> ()){
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
                case .authorized:
                    print("Authorized")
                    self.authorizedFetchFromPhotosLibrary(completion)
                case .denied, .restricted:
                    print("Not allowed")
                case .notDetermined:
                    print("Not determined yet")
                case .limited:
                    print("Limited access")
                @unknown default:
                    print("default case in permissions")
            }
        }
    }
    
    private func authorizedFetchFromPhotosLibrary(_ completion: () -> ()) {
        print("fetch from library is called")
        let fetchOptions = PHFetchOptions()
        fetchOptions.includeAssetSourceTypes = .typeUserLibrary
        self.userPhotoAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        completion()
    }
    

    func fetchImageBy(indexPath: IndexPath, isOriginalSize: Bool, completion: @escaping (UIImage) -> ()) {
        let options = PHImageRequestOptions()
        options.resizeMode = isOriginalSize ? .none : .fast
        if let photoAsset = userPhotoAssets?.object(at: indexPath.row) {
            PHImageManager.default().requestImage(for: photoAsset,
                                                  targetSize: defaultImageSize,
                                                  contentMode: .aspectFit,
                                                  options: options) {
                (uiImage, info) in
                if isOriginalSize {
                    // reaquestImage call the resultHandler twice, but here we want only the better quality (second call)
                    guard ((info?[PHImageResultIsDegradedKey] as? Bool) ?? false) else { return }
                }
                guard let uiImage = uiImage else { return }
                completion(uiImage)
            }
        } else {
            print("📕", "Could not get photo asset from index")
        }
    }
    
    func getUserPhotosCount() -> Int{
        return userPhotoAssets?.count ?? 0
    }
}