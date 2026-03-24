const puppeteer = require('puppeteer');
const path = require('path');
const fs = require('fs');

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
  
  // Create temp directory for slides
  const tempDir = 'temp-slides';
  if (!fs.existsSync(tempDir)) {
    fs.mkdirSync(tempDir);
  }
  
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
    
    // Take screenshot of the slide
    await page.screenshot({
      path: `${tempDir}/slide-${String(i + 1).padStart(3, '0')}.png`,
      type: 'png',
      fullPage: false
    });
  }
  
  await browser.close();
  
  console.log('Generating PDF from slides...');
  
  // Create a new browser instance to generate PDF from images
  const pdfBrowser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });
  
  const pdfPage = await pdfBrowser.newPage();
  
  // Create HTML with all image file references
  const slideFiles = fs.readdirSync(tempDir).sort();
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { margin: 0; padding: 0; }
        .slide { 
          width: 100vw; 
          height: 100vh; 
          page-break-after: always;
          display: flex;
          align-items: center;
          justify-content: center;
          background: white;
        }
        .slide img {
          max-width: 100%;
          max-height: 100%;
          object-fit: contain;
        }
        .slide:last-child { page-break-after: auto; }
      </style>
    </head>
    <body>
      ${slideFiles.map(file => {
        const imgPath = path.resolve(tempDir, file);
        return `<div class="slide"><img src="file://${imgPath}" /></div>`;
      }).join('')}
    </body>
    </html>
  `;
  
  await pdfPage.setContent(htmlContent, { 
    waitUntil: 'networkidle0',
    timeout: 60000 
  });
  
  // Wait for images to load
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  await pdfPage.pdf({
    path: 'argocd-presentation.pdf',
    format: 'A4',
    landscape: true,
    printBackground: true,
    margin: {
      top: '0mm',
      right: '0mm',
      bottom: '0mm',
      left: '0mm'
    }
  });
  
  await pdfBrowser.close();
  
  // Cleanup temp files
  slideFiles.forEach(file => fs.unlinkSync(path.join(tempDir, file)));
  fs.rmdirSync(tempDir);
  
  console.log('PDF generated successfully with', slideFiles.length, 'slides');
})();
