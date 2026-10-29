const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const GALLERY_DIR = path.join(__dirname, '..', 'public', 'images', 'gellery');
const MAX_WIDTH = 1200; // Limit width to a reasonable size
const WEB_QUALITY = 80; // Performance/Quality balance

/**
 * Recursively find all image files in a directory
 */
const getAllImages = (dir, files_ = []) => {
  const files = fs.readdirSync(dir);
  for (const i in files) {
    const name = path.join(dir, files[i]);
    if (fs.statSync(name).isDirectory()) {
      getAllImages(name, files_);
    } else {
      // Look for common image formats skip .webp for now (unless user wants re-compression)
      if (/\.(jpg|jpeg|png)$/i.test(name)) {
        files_.push(name);
      }
    }
  }
  return files_;
};

const optimizeImage = async (filePath) => {
  const fileExt = path.extname(filePath);
  const fileName = path.basename(filePath, fileExt);
  const fileDir = path.dirname(filePath);
  const outputPath = path.join(fileDir, `${fileName}.webp`);

  if (fs.existsSync(outputPath)) {
    // console.log(`Skipping: ${path.relative(GALLERY_DIR, filePath)} (WebP already exists)`);
    return;
  }

  // Check if original is huge. We already know they are 2-4MB.
  try {
    const metadata = await sharp(filePath).metadata();
    console.log(`Optimizing: ${path.relative(GALLERY_DIR, filePath)} (${Math.round(fs.statSync(filePath).size / 1024)} KB)`);

    const imageTransformer = sharp(filePath)
      .rotate(); // Preserve EXIF rotation

    // Resize if wider than MAX_WIDTH
    if (metadata.width > MAX_WIDTH) {
      imageTransformer.resize(MAX_WIDTH);
    }

    // Convert to webp with quality 80
    await imageTransformer
      .webp({ quality: WEB_QUALITY })
      .toFile(outputPath);

    const newSize = fs.statSync(outputPath).size;
    console.log(`  -> Saved to: ${path.basename(outputPath)} (${Math.round(newSize / 1024)} KB)`);

    // Optionally: If the user wants to DELETE the original, we could do:
    // fs.unlinkSync(filePath); 
    // But it's safer to keep it or let the user decide.
  } catch (err) {
    console.error(`Error processing ${filePath}:`, err);
  }
};

const run = async () => {
  if (!fs.existsSync(GALLERY_DIR)) {
    console.error(`Gallery directory not found: ${GALLERY_DIR}`);
    return;
  }

  const images = getAllImages(GALLERY_DIR);
  console.log(`Found ${images.length} images to optimize.`);

  for (const img of images) {
    await optimizeImage(img);
  }

  // Generate gallery-data.json
  const galleryData = [];
  const folders = fs.readdirSync(GALLERY_DIR).filter(f => fs.statSync(path.join(GALLERY_DIR, f)).isDirectory());

  for (const year of folders) {
    const yearDir = path.join(GALLERY_DIR, year);
    const webpFiles = fs.readdirSync(yearDir).filter(f => f.endsWith('.webp'));
    
    webpFiles.forEach(file => {
      galleryData.push({
        year: year,
        src: `/images/gellery/${year}/${file}`,
        alt: `${year} AGM Meeting`
      });
    });
  }

  fs.writeFileSync(
    path.join(GALLERY_DIR, 'gallery-data.json'),
    JSON.stringify(galleryData, null, 2)
  );

  console.log('\nOptimization complete and gallery-data.json generated!');
};

run();
