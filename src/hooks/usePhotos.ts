import { useState, useCallback, useEffect } from 'react';
import { savePhoto, getAllPhotos, clearAllPhotos } from '../utils/imageStorage';

// Import preset images from assets/images
const presetImages = import.meta.glob('../assets/images/*.(jpg|jpeg|png|gif|webp)', { eager: true, import: 'default' }) as Record<string, string>;

export const usePhotos = () => {
  const [photos, setPhotos] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Load preset images and stored images on mount
  useEffect(() => {
    const loadAllImages = async () => {
      try {
        // Get preset images from assets
        const presetUrls = Object.values(presetImages);

        // Get stored images from IndexedDB
        const storedPhotos = await getAllPhotos();

        // Combine: preset first, then stored
        setPhotos([...presetUrls, ...storedPhotos]);
      } catch (error) {
        console.error('Error loading images:', error);
        // At least load preset images if IndexedDB fails
        setPhotos(Object.values(presetImages));
      } finally {
        setIsLoading(false);
      }
    };

    loadAllImages();
  }, []);

  const addPhoto = useCallback((file: File) => {
    return new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = async (e) => {
        const dataUrl = e.target?.result as string;
        try {
          // Save to IndexedDB for persistence
          await savePhoto(dataUrl);
          setPhotos((prev) => [...prev, dataUrl]);
          resolve(dataUrl);
        } catch (error) {
          console.error('Error saving photo:', error);
          // Still add to state even if IndexedDB fails
          setPhotos((prev) => [...prev, dataUrl]);
          resolve(dataUrl);
        }
      };
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }, []);

  const addPhotos = useCallback((files: FileList | File[]) => {
    const fileArray = Array.from(files);
    const promises = fileArray.map((file) => {
      if (!file.type.startsWith('image/')) {
        return Promise.reject(new Error(`${file.name} is not an image`));
      }
      return addPhoto(file);
    });
    return Promise.all(promises);
  }, [addPhoto]);

  const removePhoto = useCallback((index: number) => {
    setPhotos((prev) => prev.filter((_, i) => i !== index));
  }, []);

  const clearPhotos = useCallback(async () => {
    try {
      await clearAllPhotos();
    } catch (error) {
      console.error('Error clearing photos from storage:', error);
    }
    // Keep preset images, only clear stored ones
    setPhotos(Object.values(presetImages));
  }, []);

  return {
    photos,
    isLoading,
    addPhoto,
    addPhotos,
    removePhoto,
    clearPhotos
  };
};

