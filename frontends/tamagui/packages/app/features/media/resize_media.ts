export function resizeImage(file: File, maxWidth: number, maxHeight: number): Promise<Blob | null> {
  return new Promise((resolve, reject) => {
    let image = new Image();
    image.src = URL.createObjectURL(file);
    image.onload = () => {
      let width = image.width;
      let height = image.height;

      if (width <= maxWidth && height <= maxHeight) {
        resolve(file);
      }

      let newWidth: number;
      let newHeight: number;

      if (width > height) {
        newHeight = height * (maxWidth / width);
        newWidth = maxWidth;
      } else {
        newWidth = width * (maxHeight / height);
        newHeight = maxHeight;
      }

      let canvas = document.createElement('canvas');
      canvas.width = newWidth;
      canvas.height = newHeight;

      let context = canvas.getContext('2d');

      context?.drawImage(image, 0, 0, newWidth, newHeight);

      canvas.toBlob(resolve, file.type);
    };
    image.onerror = reject;
  });
}
