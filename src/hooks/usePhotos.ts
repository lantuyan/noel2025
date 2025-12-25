import { useState, useCallback, useEffect } from 'react';
import { uploadImage } from '../utils/fileUpload';

// Import preset images from assets/images
// This will automatically pick up new files after reload
const presetImages = import.meta.glob('../assets/images/*.(jpg|jpeg|png|gif|webp)', { eager: true, import: 'default' }) as Record<string, string>;

export const usePhotos = () => {
  const [photos, setPhotos] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Load all images from assets/images folder
  useEffect(() => {
    const loadAllImages = () => {
      try {
        // Get all images from assets folder (includes preset and uploaded)
        const imageUrls = Object.values(presetImages);
        setPhotos(imageUrls);
      } catch (error) {
        console.error('Error loading images:', error);
        setPhotos([]);
      } finally {
        setIsLoading(false);
      }
    };

    loadAllImages();
  }, []);

  const addPhoto = useCallback(async (file: File): Promise<string> => {
    try {
      // Upload file to server (saves to src/assets/images/)
      const filename = await uploadImage(file);
      
      // After successful upload, reload page so Vite can detect the new file
      // The new file will be loaded by import.meta.glob() on next render
      window.location.reload();
      
      // This won't execute, but needed for type safety
      return filename;
    } catch (error) {
      console.error('Error uploading photo:', error);
      throw error instanceof Error ? error : new Error('Failed to upload photo');
    }
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
    // Note: This only clears from state, not from filesystem
    // To actually delete files, they need to be removed manually from src/assets/images/
    // or implement a delete API endpoint
    setPhotos([]);
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

