const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');
const { PDFDocument } = require('pdf-lib');

(async () => {
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const page = await browser.newPage();
  await page.setViewport({ width: 1920, height: 1080 });
  
  const htmlPath = 'file://' + path.resolve('presentation/argocd/index.html');
  console.log('Loading presentation from:', htmlPath);
  
  await page.goto(htmlPath, { 
    waitUntil: 'networkidle0',
    timeout: 30000
  });
  
  // Wait for impress.js to initialize
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  // Get total number of slides
  const slideCount = await page.evaluate(() => {
    return document.querySelectorAll('.step').length;
  });
  
  console.log(`Found ${slideCount} slides. Capturing each slide...`);
  
  const screenshots = [];
  
  // Navigate through each slide and capture
  for (let i = 0; i < slideCount; i++) {
    console.log(`Capturing slide ${i + 1}/${slideCount}`);
    
    // Navigate to next slide (except first)
    if (i > 0) {
      await page.keyboard.press('ArrowRight');
      await new Promise(resolve => setTimeout(resolve, 1500));
    } else {
      // Wait a bit for first slide
      await new Promise(resolve => setTimeout(resolve, 500));
    }
    
    // Take screenshot of the slide and store in memory
    const screenshot = await page.screenshot({
      type: 'png',
      fullPage: false
    });
    
    screenshots.push(screenshot);
  }
  
  await browser.close();
  
  console.log('Generating PDF from slides using pdf-lib...');
  
  // Create PDF document using pdf-lib
  const pdfDoc = await PDFDocument.create();
  
  // Process screenshots in batches to avoid memory issues
  const batchSize = 5;
  for (let i = 0; i < screenshots.length; i += batchSize) {
    const batch = screenshots.slice(i, Math.min(i + batchSize, screenshots.length));
    console.log(`Processing slides ${i + 1}-${Math.min(i + batchSize, screenshots.length)}...`);
    
    for (const screenshot of batch) {
      const pngImage = await pdfDoc.embedPng(screenshot);
      const page = pdfDoc.addPage([842, 595]); // A4 landscape in points
      
      const { width, height } = pngImage.scale(1);
      const pageWidth = page.getWidth();
      const pageHeight = page.getHeight();
      
      // Calculate scaling to fit image on page while maintaining aspect ratio
      const scale = Math.min(pageWidth / width, pageHeight / height);
      const scaledWidth = width * scale;
      const scaledHeight = height * scale;
      
      // Center the image
      const x = (pageWidth - scaledWidth) / 2;
      const y = (pageHeight - scaledHeight) / 2;
      
      page.drawImage(pngImage, {
        x: x,
        y: y,
        width: scaledWidth,
        height: scaledHeight,
      });
    }
  }
  
  const pdfBytes = await pdfDoc.save();
  fs.writeFileSync('argocd-presentation.pdf', pdfBytes);
  
  console.log('PDF generated successfully with', screenshots.length, 'slides');
})();
