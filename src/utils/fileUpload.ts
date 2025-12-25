/**
 * Upload image file to server
 * Saves file to src/assets/images/ and returns the filename
 */
export const uploadImage = async (file: File): Promise<string> => {
  // Validate file type
  if (!file.type.startsWith('image/')) {
    throw new Error('File must be an image');
  }

  // Create FormData
  const formData = new FormData();
  formData.append('file', file);

  try {
    // Upload to server
    const response = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ error: 'Upload failed' }));
      throw new Error(error.error || 'Upload failed');
    }

    const result = await response.json();
    
    if (!result.success || !result.filename) {
      throw new Error('Upload failed: Invalid response');
    }

    return result.filename;
  } catch (error) {
    console.error('Upload error:', error);
    throw error instanceof Error ? error : new Error('Upload failed');
  }
};

